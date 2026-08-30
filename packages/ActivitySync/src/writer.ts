/**
 * One Activity plus N ActivityLink rows, atomically.
 *
 * Synced rows set Visibility = 'Private' explicitly (column default Internal is for manual logging).
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
import type { NormalizedItem } from './types.js';

function isDatabaseProvider(provider: IMetadataProvider): provider is DatabaseProviderBase {
    return (
        'BeginEntityTransaction' in provider &&
        typeof (provider as DatabaseProviderBase).BeginEntityTransaction === 'function'
    );
}

export type ActivitySourceValue = 'Manual' | 'System' | 'Integration';

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

export class ActivityWriter {
    public async Write(
        input: WriteActivityInput,
        provider: IMetadataProvider,
        contextUser: UserInfo,
        options?: WriteOptions,
    ): Promise<WriteActivityResult> {
        const result: WriteActivityResult = {
            Success: false,
            ActivityID: null,
            AlreadyPresent: false,
            Links: [],
            Activity: null,
            Issues: [],
        };

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

        const scope = await provider.BeginEntityTransaction();
        try {
            const activity = await provider.GetEntityObject<mjBizAppsCommonActivityEntity>(
                ACTIVITY_SYNC_ENTITIES.Activities,
                contextUser,
            );
            activity.NewRecord();
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

            if (!(await activity.Save())) {
                await scope.Rollback();
                result.Issues.push(activity.LatestResult?.CompleteMessage ?? 'Activity.Save failed.');
                return result;
            }

            const pending = this.planLinks(input);
            let sequence = 0;
            for (const link of pending) {
                const row = await this.writeLink(link, activity.ID, ++sequence, provider, contextUser);
                if (!row) {
                    await scope.Rollback();
                    result.Issues.push(`Link could not be written (role ${link.Role}).`);
                    return result;
                }
                result.Links.push(row);
            }

            if (options?.OnWritten) {
                const writeContext = this.BuildWriteContext(
                    { ...result, Activity: activity, ActivityID: activity.ID, Success: true },
                    input,
                    contextUser,
                    provider,
                    options.ProviderTypeCode,
                );
                if (writeContext) {
                    await options.OnWritten(writeContext);
                    result.Links = writeContext.Links;
                }
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

    private planLinks(input: WriteActivityInput): Array<{
        Role: ResolvedParty['Role'];
        EntityName?: string;
        RecordID?: string;
        IdentityKind?: UnresolvedParty['Kind'];
        IdentityValue?: string;
    }> {
        const links: Array<{
            Role: ResolvedParty['Role'];
            EntityName?: string;
            RecordID?: string;
            IdentityKind?: UnresolvedParty['Kind'];
            IdentityValue?: string;
        }> = [];
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
        const seen = new Set<string>();
        const out = [];
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

    private async writeLink(
        link: {
            Role: ResolvedParty['Role'];
            EntityName?: string;
            RecordID?: string;
            IdentityKind?: UnresolvedParty['Kind'];
            IdentityValue?: string;
        },
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
