/**
 * One Activity plus N ActivityLink rows, atomically.
 *
 * ONE writer, TWO entry points (plans/mj-entity-action-workflow-adoption.md §3.2):
 * - `Write` — the sync engine's path. Synced rows set Visibility = 'Private' explicitly and dispatch
 *   registered extensions inside the write transaction.
 * - `WriteManual` — the manual / declarative path (`Common.LogActivity`, UI logging). Visibility
 *   defaults to the column's own 'Internal', no connection is stamped, and sync extensions do NOT
 *   run — those fire on ingest, not on a record being logged (see §8 of the same plan).
 *
 * Both share the same transactional core, dedupe, link writing and type resolution, so the
 * declarative path and the ingest path cannot drift.
 *
 * Unmatched participants become unresolved links — never a new Person.
 */
import {
    LogError,
    RunView,
    type DatabaseProviderBase,
    type IMetadataProvider,
    type UserInfo,
} from '@memberjunction/core';
import type {
    mjBizAppsCommonActivityEntity,
    mjBizAppsCommonActivityLinkEntity,
} from '@mj-biz-apps/common-entities';

import type { ResolvedParty, UnresolvedParty, ActivityWriteContext } from './BaseActivitySyncExtension.js';
import { ACTIVITY_SYNC_ENTITIES } from './entity-names.js';
import { EscapeText } from './sql.js';
import type { ActivityDirection, ActivityIdentityKind, ActivityLinkRole, NormalizedItem } from './types.js';

function isDatabaseProvider(provider: IMetadataProvider): provider is DatabaseProviderBase {
    return (
        'BeginEntityTransaction' in provider &&
        typeof (provider as DatabaseProviderBase).BeginEntityTransaction === 'function'
    );
}

export type ActivitySourceValue = 'Manual' | 'System' | 'Integration';

/** Mirrors `CK_Activity_Status`. */
export type ActivityStatusValue = 'Logged' | 'Scheduled' | 'Completed' | 'Cancelled' | 'Failed';

/** Mirrors `CK_Activity_Visibility`. */
export type ActivityVisibilityValue = 'Internal' | 'Private';

/** How much of an included body to persist. Default Snippet — Full is a per-connection opt-in. */
export type StoreBodyPolicy = 'None' | 'Snippet' | 'Full';

export const BODY_SNIPPET_CHARS = 500;

/** Read StoreBody from ActivitySyncConnection.Settings. Missing / invalid / unparseable → Snippet. */
export function StoreBodyFromSettings(settings: string | null | undefined): StoreBodyPolicy {
    if (!settings) return 'Snippet';
    try {
        const parsed: unknown = JSON.parse(settings);
        if (parsed !== null && typeof parsed === 'object' && 'StoreBody' in parsed) {
            const value = (parsed as { StoreBody: unknown }).StoreBody;
            if (value === 'None' || value === 'Full' || value === 'Snippet') return value;
        }
    } catch {
        // ignore
    }
    return 'Snippet';
}

export function BodyForStorage(
    body: string | null | undefined,
    policy: StoreBodyPolicy = 'Snippet',
): string | null {
    const text = body ?? '';
    if (policy === 'None') return null;
    if (policy === 'Full') return text.length > 0 ? text : null;
    if (!text) return null;
    return text.length <= BODY_SNIPPET_CHARS ? text : text.slice(0, BODY_SNIPPET_CHARS);
}

/**
 * One link on an activity: either a resolved link to any entity's record (EntityName + RecordID)
 * or an unresolved identity (IdentityKind + IdentityValue). Exactly one of the two shapes.
 */
export interface ActivityLinkSpec {
    Role: ActivityLinkRole;
    EntityName?: string;
    RecordID?: string;
    IdentityKind?: ActivityIdentityKind;
    IdentityValue?: string;
}

export interface WriteActivityInput {
    Item: NormalizedItem;
    ConnectionID: string;
    SourceSystem: string;
    /** Integration for a live provider; System for a fixture — never Integration from a non-live source. */
    Source: ActivitySourceValue;
    Resolved: ResolvedParty[];
    Unresolved: UnresolvedParty[];
    /** Default Snippet. Independent of SkippedContentPolicy. */
    StoreBody?: StoreBodyPolicy;
}

/**
 * A manually or declaratively logged activity — no sync connection, no ingest item.
 *
 * Defaults follow the column defaults for a manual log: Visibility 'Internal' (the sync path's
 * 'Private' is for mail nobody chose to share), Status 'Logged', Direction 'Internal',
 * Source 'Manual'. 'Integration' is deliberately not accepted here — that word belongs to the
 * sync engine's entry point.
 */
export interface WriteManualActivityInput {
    /** `ActivityType.Code` — resolved by CODE so renaming a type never breaks callers. */
    TypeCode: string;
    Title: string;
    StartedAt: Date;
    EndedAt?: Date | null;
    Description?: string | null;
    Direction?: ActivityDirection;
    Status?: ActivityStatusValue;
    Visibility?: ActivityVisibilityValue;
    Source?: Exclude<ActivitySourceValue, 'Integration'>;
    Location?: string | null;
    /** JSON extras that are not query predicates. Stringified into `Activity.Details`. */
    Details?: Record<string, unknown> | null;
    /**
     * Optional idempotency pair. When BOTH are set, a second write with the same pair is a no-op
     * that reports `AlreadyPresent` — the same dedupe the sync path uses. SourceSystem is required
     * whenever ExternalID is set (the column contract).
     */
    SourceSystem?: string | null;
    ExternalID?: string | null;
    Links?: ActivityLinkSpec[];
}

export interface WriteActivityResult {
    Success: boolean;
    ActivityID: string | null;
    AlreadyPresent: boolean;
    Links: mjBizAppsCommonActivityLinkEntity[];
    Activity: mjBizAppsCommonActivityEntity | null;
    Issues: string[];
}

export interface WriteOptions {
    ProviderTypeCode: string;
    /**
     * Runs inside the open write transaction, after the activity and its party
     * links are saved and before commit. This is where registered extensions
     * add app-specific links. Throwing rolls the write back.
     */
    OnWritten?: (context: ActivityWriteContext) => Promise<void>;
}

/**
 * Guard-clause validation for the manual entry point. Returns problems rather than throwing so the
 * writer can report them on the result like every other failure.
 */
export function ValidateManualActivityInput(input: WriteManualActivityInput): string[] {
    const issues: string[] = [];
    if (!input.TypeCode?.trim()) issues.push('TypeCode is required.');
    if (!input.Title?.trim()) issues.push('Title is required.');
    if (!(input.StartedAt instanceof Date) || Number.isNaN(input.StartedAt.getTime())) {
        issues.push('StartedAt must be a valid date.');
    } else if (input.EndedAt instanceof Date && input.EndedAt.getTime() < input.StartedAt.getTime()) {
        issues.push('EndedAt must be on or after StartedAt.');
    }
    if (input.ExternalID && !input.SourceSystem) {
        issues.push('SourceSystem is required when ExternalID is set.');
    }
    for (const [index, link] of (input.Links ?? []).entries()) {
        const resolved = Boolean(link.EntityName && link.RecordID);
        const identity = Boolean(link.IdentityKind && link.IdentityValue);
        if (resolved === identity) {
            issues.push(`Link ${index + 1} must carry either EntityName + RecordID or IdentityKind + IdentityValue.`);
        }
    }
    return issues;
}

export class ActivityWriter {
    /** The sync engine's entry point: connection-stamped, Visibility 'Private', extensions dispatched. */
    public async Write(
        input: WriteActivityInput,
        provider: IMetadataProvider,
        contextUser: UserInfo,
        options?: WriteOptions,
    ): Promise<WriteActivityResult> {
        const result = this.emptyResult();

        const typeID = await this.resolveTypeByCode(input.Item.TypeCode, contextUser);
        if (!typeID) {
            result.Issues.push(`No ActivityType with Code '${input.Item.TypeCode}' is seeded.`);
            return result;
        }

        const existing = await this.findByExternalKey(input.SourceSystem, input.Item.ExternalID, contextUser);
        if (existing) {
            result.Success = true;
            result.ActivityID = existing;
            result.AlreadyPresent = true;
            return result;
        }

        if (!isDatabaseProvider(provider)) {
            result.Issues.push('This provider cannot open a transaction; ActivityWriter is server-only.');
            return result;
        }

        const onWritten = options?.OnWritten;
        const afterLinks = onWritten
            ? async (
                  activity: mjBizAppsCommonActivityEntity,
                  links: mjBizAppsCommonActivityLinkEntity[],
              ): Promise<mjBizAppsCommonActivityLinkEntity[]> => {
                  const writeContext = this.BuildWriteContext(
                      { ...result, Activity: activity, ActivityID: activity.ID, Success: true, Links: links },
                      input,
                      contextUser,
                      provider,
                      options.ProviderTypeCode,
                  );
                  if (!writeContext) return links;
                  await onWritten(writeContext);
                  return writeContext.Links;
              }
            : undefined;

        return this.writeWithLinks(
            provider,
            contextUser,
            result,
            (activity) => this.fillSyncFields(activity, input, typeID, contextUser),
            this.planLinks(input),
            afterLinks,
        );
    }

    /**
     * The manual / declarative entry point (`Common.LogActivity`, UI logging).
     *
     * Same transactional core, dedupe and link writing as `Write`; different defaults (Visibility
     * 'Internal', no connection) and NO extension dispatch — sync extensions enrich an item being
     * ingested, and a manually logged activity is not one.
     */
    public async WriteManual(
        input: WriteManualActivityInput,
        provider: IMetadataProvider,
        contextUser: UserInfo,
    ): Promise<WriteActivityResult> {
        const result = this.emptyResult();

        const problems = ValidateManualActivityInput(input);
        if (problems.length > 0) {
            result.Issues.push(...problems);
            return result;
        }

        const typeID = await this.resolveTypeByCode(input.TypeCode, contextUser);
        if (!typeID) {
            result.Issues.push(`No ActivityType with Code '${input.TypeCode}' is seeded.`);
            return result;
        }

        if (input.SourceSystem && input.ExternalID) {
            const existing = await this.findByExternalKey(input.SourceSystem, input.ExternalID, contextUser);
            if (existing) {
                result.Success = true;
                result.ActivityID = existing;
                result.AlreadyPresent = true;
                return result;
            }
        }

        if (!isDatabaseProvider(provider)) {
            result.Issues.push('This provider cannot open a transaction; ActivityWriter is server-only.');
            return result;
        }

        return this.writeWithLinks(
            provider,
            contextUser,
            result,
            (activity) => this.fillManualFields(activity, input, typeID, contextUser),
            this.dedupeLinks(input.Links ?? []),
        );
    }

    public BuildWriteContext(
        result: WriteActivityResult,
        input: WriteActivityInput,
        contextUser: UserInfo,
        provider: IMetadataProvider,
        providerTypeCode: string,
    ): ActivityWriteContext | null {
        if (!result.Activity || !result.ActivityID) return null;
        return {
            Activity: result.Activity,
            Links: result.Links,
            Item: input.Item,
            ResolvedParties: input.Resolved,
            UnresolvedParties: input.Unresolved,
            ConnectionID: input.ConnectionID,
            ProviderTypeCode: providerTypeCode,
            ContextUser: contextUser,
            Provider: provider,
        };
    }

    /**
     * The shared transactional core: save the activity, write its links in sequence, run the
     * optional in-transaction callback, commit. Any failure rolls the whole write back.
     */
    private async writeWithLinks(
        provider: DatabaseProviderBase,
        contextUser: UserInfo,
        result: WriteActivityResult,
        fill: (activity: mjBizAppsCommonActivityEntity) => void,
        links: ActivityLinkSpec[],
        afterLinks?: (
            activity: mjBizAppsCommonActivityEntity,
            links: mjBizAppsCommonActivityLinkEntity[],
        ) => Promise<mjBizAppsCommonActivityLinkEntity[]>,
    ): Promise<WriteActivityResult> {
        const scope = await provider.BeginEntityTransaction();
        try {
            const activity = await provider.GetEntityObject<mjBizAppsCommonActivityEntity>(
                ACTIVITY_SYNC_ENTITIES.Activities,
                contextUser,
            );
            activity.NewRecord();
            fill(activity);

            if (!(await activity.Save())) {
                await scope.Rollback();
                result.Issues.push(activity.LatestResult?.CompleteMessage ?? 'Activity.Save failed.');
                return result;
            }

            let sequence = 0;
            for (const link of links) {
                const row = await this.writeLink(link, activity.ID, ++sequence, provider, contextUser);
                if (!row) {
                    await scope.Rollback();
                    result.Issues.push(`Link could not be written (role ${link.Role}).`);
                    return result;
                }
                result.Links.push(row);
            }

            if (afterLinks) {
                result.Links = await afterLinks(activity, result.Links);
            }

            await scope.Commit();
            result.Success = true;
            result.ActivityID = activity.ID;
            result.Activity = activity;
            return result;
        } catch (err) {
            LogError(`ActivityWriter.Write failed: ${err}`);
            try {
                await scope.Rollback();
            } catch {
                /* already failed */
            }
            result.Issues.push(String(err));
            return result;
        }
    }

    private fillSyncFields(
        activity: mjBizAppsCommonActivityEntity,
        input: WriteActivityInput,
        typeID: string,
        contextUser: UserInfo,
    ): void {
        activity.ActivityTypeID = typeID;
        activity.Title = (input.Item.Subject || '(no subject)').slice(0, 200);
        activity.StartedAt = input.Item.StartedAt;
        activity.EndedAt = input.Item.EndedAt;
        activity.Description = BodyForStorage(input.Item.Body, input.StoreBody ?? 'Snippet');
        activity.Direction = input.Item.Direction;
        activity.Status = input.Item.Cancelled ? 'Cancelled' : 'Logged';
        activity.Visibility = 'Private';
        activity.Source = input.Source;
        activity.Location = input.Item.Location;
        activity.Details = JSON.stringify(input.Item.Raw);
        activity.ExternalThreadID = input.Item.ExternalThreadID;
        activity.ActivitySyncConnectionID = input.ConnectionID;
        activity.SourceSystem = input.SourceSystem;
        activity.ExternalID = input.Item.ExternalID;
        activity.LoggedByUserID = contextUser.ID;
    }

    private fillManualFields(
        activity: mjBizAppsCommonActivityEntity,
        input: WriteManualActivityInput,
        typeID: string,
        contextUser: UserInfo,
    ): void {
        activity.ActivityTypeID = typeID;
        activity.Title = input.Title.slice(0, 500);
        activity.StartedAt = input.StartedAt;
        activity.EndedAt = input.EndedAt ?? null;
        activity.Description = input.Description ?? null;
        activity.Direction = input.Direction ?? 'Internal';
        activity.Status = input.Status ?? 'Logged';
        activity.Visibility = input.Visibility ?? 'Internal';
        activity.Source = input.Source ?? 'Manual';
        activity.Location = input.Location ?? null;
        activity.Details = input.Details ? JSON.stringify(input.Details) : null;
        activity.SourceSystem = input.SourceSystem ?? null;
        activity.ExternalID = input.ExternalID ?? null;
        activity.LoggedByUserID = contextUser.ID;
    }

    private planLinks(input: WriteActivityInput): ActivityLinkSpec[] {
        const links: ActivityLinkSpec[] = [];
        for (const party of input.Resolved) {
            links.push({
                Role: party.Role,
                EntityName: party.Kind === 'Person' ? ACTIVITY_SYNC_ENTITIES.People : ACTIVITY_SYNC_ENTITIES.Organizations,
                RecordID: party.RecordID,
            });
        }
        for (const party of input.Unresolved) {
            links.push({
                Role: party.Role,
                IdentityKind: party.Kind,
                IdentityValue: party.Value,
            });
        }
        return this.dedupeLinks(links);
    }

    private dedupeLinks(links: ActivityLinkSpec[]): ActivityLinkSpec[] {
        const seen = new Set<string>();
        const out: ActivityLinkSpec[] = [];
        for (const link of links) {
            const key = link.RecordID
                ? `r:${link.EntityName}:${link.RecordID.toLowerCase()}`
                : `i:${link.IdentityKind}:${(link.IdentityValue ?? '').toLowerCase()}`;
            if (seen.has(key)) continue;
            seen.add(key);
            out.push(link);
        }
        return out;
    }

    private emptyResult(): WriteActivityResult {
        return {
            Success: false,
            ActivityID: null,
            AlreadyPresent: false,
            Links: [],
            Activity: null,
            Issues: [],
        };
    }

    private async writeLink(
        link: ActivityLinkSpec,
        activityID: string,
        sequence: number,
        provider: IMetadataProvider,
        contextUser: UserInfo,
    ): Promise<mjBizAppsCommonActivityLinkEntity | null> {
        const entityID = link.EntityName
            ? provider.Entities.find((e) => e.Name === link.EntityName)?.ID
            : undefined;
        if (link.EntityName && !entityID) return null;

        const row = await provider.GetEntityObject<mjBizAppsCommonActivityLinkEntity>(
            ACTIVITY_SYNC_ENTITIES.ActivityLinks,
            contextUser,
        );
        row.NewRecord();
        row.ActivityID = activityID;
        row.Role = link.Role;
        row.Sequence = sequence;
        if (link.RecordID && entityID) {
            row.EntityID = entityID;
            row.RecordID = link.RecordID;
        } else {
            row.IdentityKind = link.IdentityKind ?? 'Email';
            row.IdentityValue = link.IdentityValue ?? '';
        }
        if (!(await row.Save())) return null;
        return row;
    }

    private async resolveTypeByCode(code: string, contextUser: UserInfo): Promise<string | null> {
        const rv = new RunView();
        const res = await rv.RunView<{ ID: string }>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.ActivityTypes,
                ExtraFilter: `Code = '${EscapeText(code)}'`,
                MaxRows: 1,
                ResultType: 'simple',
            },
            contextUser,
        );
        return res.Success ? (res.Results?.[0]?.ID ?? null) : null;
    }

    private async findByExternalKey(
        sourceSystem: string,
        externalID: string,
        contextUser: UserInfo,
    ): Promise<string | null> {
        const rv = new RunView();
        const res = await rv.RunView<{ ID: string }>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.Activities,
                ExtraFilter:
                    `SourceSystem = '${EscapeText(sourceSystem)}' AND ExternalID = '${EscapeText(externalID)}'`,
                MaxRows: 1,
                ResultType: 'simple',
            },
            contextUser,
        );
        return res.Success ? (res.Results?.[0]?.ID ?? null) : null;
    }
}
