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
import { EscapeSql } from './sql.js';
import type { NormalizedItem } from './types.js';

export type ActivitySourceValue = 'Manual' | 'System' | 'Integration';

export interface WriteActivityInput {
    Item: NormalizedItem;
    ConnectionID: string;
    SourceSystem: string;
    /** Integration for a live provider; System for a fixture — never Integration from a non-live source. */
    Source: ActivitySourceValue;
    Resolved: ResolvedParty[];
    Unresolved: UnresolvedParty[];
}

export interface WriteActivityResult {
    Success: boolean;
    ActivityID: string | null;
    AlreadyPresent: boolean;
    Links: mjBizAppsCommonActivityLinkEntity[];
    Activity: mjBizAppsCommonActivityEntity | null;
    Issues: string[];
}

export class ActivityWriter {
    public async Write(
        input: WriteActivityInput,
        provider: IMetadataProvider,
        contextUser: UserInfo,
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

        const db = provider as unknown as DatabaseProviderBase;
        if (!db?.BeginEntityTransaction) {
            result.Issues.push('This provider cannot open a transaction; ActivityWriter is server-only.');
            return result;
        }

        const scope = await db.BeginEntityTransaction();
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
            activity.Description = input.Item.Body;
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
                ExtraFilter: `Code = '${EscapeSql(code)}'`,
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
                    `SourceSystem = '${EscapeSql(sourceSystem)}' AND ExternalID = '${EscapeSql(externalID)}'`,
                MaxRows: 1,
                ResultType: 'simple',
            },
            contextUser,
        );
        return res.Success ? (res.Results?.[0]?.ID ?? null) : null;
    }
}
