/**
 * ActivitySyncEngine — fetch, qualify, resolve, write.
 *
 * No model call inside a transaction. No model call before the deterministic filter.
 * Dry run never advances the watermark (CK_ActivitySyncRun_DryRunNoWatermark).
 * Synced activities are Visibility=Private. Unmatched addresses stay unresolved links.
 */
import {
    LogError,
    RunView,
    type IMetadataProvider,
    type UserInfo,
} from '@memberjunction/core';
import { MJGlobal } from '@memberjunction/global';
import type {
    mjBizAppsCommonActivitySyncConnectionEntity,
    mjBizAppsCommonActivitySyncRunDetailEntity,
    mjBizAppsCommonActivitySyncRunEntity,
} from '@mj-biz-apps/common-entities';

import { BaseActivitySyncExtension } from './BaseActivitySyncExtension.js';
import { BaseActivitySyncProvider } from './BaseActivitySyncProvider.js';
import { ACTIVITY_SYNC_ENTITIES } from './entity-names.js';
import { IdentityResolver } from './identity.js';
import {
    DefaultDeterministicStages,
    type EngineQualificationContext,
    type ExclusionRow,
    type RuleRow,
} from './stages.js';
import { FixtureActivitySyncProvider } from './providers/FixtureActivitySyncProvider.js';
import { MSGraphActivitySyncProvider } from './providers/MSGraphActivitySyncProvider.js';
import {
    DefaultPolicyFromProviderType,
    RunQualificationCascade,
    type IQualificationStage,
    type QualificationPolicy,
} from './qualification.js';
import {
    AsDryRunDecision,
    IsConnectionActive,
    type SyncDecision,
    type SyncRunOptions,
} from './run.js';
import { RequireUUID, UuidInList } from './sql.js';
import type { NormalizedItem } from './types.js';
import { CanAdvanceWatermark, NextWatermark, type RunOutcome } from './watermark.js';
import { ActivityWriter, StoreBodyFromSettings } from './writer.js';

export interface SyncEngineResult {
    Success: boolean;
    RunID: string | null;
    Fetched: number;
    Included: number;
    Excluded: number;
    Duplicates: number;
    Failed: number;
    ExtensionErrors: number;
    WatermarkAdvancedTo: Date | null;
    Issues: string[];
}

interface ConnectionRow {
    ID: string;
    Status: string;
    Mailbox: string | null;
    StartAt: Date | string | null;
    EndAt: Date | string | null;
    LastSyncAt: Date | string | null;
    ActivitySyncProviderTypeID: string | null;
    SkippedContentPolicy: string | null;
    Settings: string | null;
}

interface ProviderTypeRow {
    ID: string;
    Code: string;
    DriverClass: string;
    DefaultQualificationPolicy: QualificationPolicy;
}

export class ActivitySyncEngine {
    public constructor(
        private readonly resolver: IdentityResolver = new IdentityResolver(),
        private readonly writer: ActivityWriter = new ActivityWriter(),
        private readonly stages: IQualificationStage[] = DefaultDeterministicStages(),
    ) {}

    public async Run(
        connectionID: string,
        options: SyncRunOptions,
        provider: IMetadataProvider,
        contextUser: UserInfo,
        source?: BaseActivitySyncProvider,
    ): Promise<SyncEngineResult> {
        const result: SyncEngineResult = {
            Success: false,
            RunID: null,
            Fetched: 0,
            Included: 0,
            Excluded: 0,
            Duplicates: 0,
            Failed: 0,
            ExtensionErrors: 0,
            WatermarkAdvancedTo: null,
            Issues: [],
        };

        const connection = await this.loadConnection(connectionID, contextUser);
        if (!connection) {
            result.Issues.push(`No ActivitySyncConnection '${connectionID}'.`);
            return result;
        }
        const now = new Date();
        if (
            !IsConnectionActive(
                connection.Status as 'Active' | 'Paused' | 'Error' | 'Disabled',
                connection.StartAt ? new Date(connection.StartAt) : null,
                connection.EndAt ? new Date(connection.EndAt) : null,
                now,
            )
        ) {
            result.Issues.push(`Connection ${connectionID} is not in its Active window.`);
            return result;
        }

        const typeRow = connection.ActivitySyncProviderTypeID
            ? await this.loadProviderType(connection.ActivitySyncProviderTypeID, contextUser)
            : null;
        // Missing type row: hosts currently get zero provider-type seeds (Metadata_Sync
        // is release-engineer, not this PR). The cascade still needs a default, and
        // that default is Exclude — never `?? 'Include'`.
        const defaultPolicy = DefaultPolicyFromProviderType(typeRow?.DefaultQualificationPolicy);

        const plugin = source ?? (typeRow ? this.resolvePlugin(typeRow.DriverClass) : null);
        if (!plugin) {
            result.Issues.push(
                typeRow
                    ? `No BaseActivitySyncProvider registered for DriverClass '${typeRow.DriverClass}'.`
                    : 'Provider type is missing and no provider was injected.',
            );
            return result;
        }
        const sourceSystem = typeRow?.Code ?? plugin.ProviderTypeCode;

        const since = connection.LastSyncAt ? new Date(connection.LastSyncAt) : null;
        const batch = await plugin.Fetch({
            Mailbox: connection.Mailbox ?? '',
            Since: since,
            Limit: options.Limit,
        });
        result.Fetched = batch.Items.length;
        result.Issues.push(...batch.Issues);

        const exclusions = await this.loadExclusions(connectionID, contextUser);
        const rules = await this.loadRules(connectionID, contextUser);

        const allParticipants = batch.Items.flatMap((i) => i.Participants);
        const identities = await this.resolver.Resolve(allParticipants, contextUser);
        if (identities.LookupFailed) {
            result.Failed += batch.Items.length;
            result.Issues.push('ContactMethod lookup failed — watermark will not advance.');
            await this.persistRun(connection, options, result, since, null, provider, contextUser, []);
            return result;
        }

        const details: Array<{
            Item: NormalizedItem;
            Decision: SyncDecision;
            Stage: string;
            Reason: string;
            RuleID?: string;
            ExclusionID?: string;
            ActivityID?: string | null;
        }> = [];

        for (const item of batch.Items) {
            const ctx: EngineQualificationContext = {
                ConnectionID: connection.ID,
                ProviderTypeCode: sourceSystem,
                Exclusions: exclusions,
                Rules: rules,
                InternalDomains: [],
                KnownAddresses: identities.Known,
            };
            let verdict;
            try {
                verdict = await RunQualificationCascade(
                    this.stages,
                    item,
                    ctx,
                    defaultPolicy,
                );
            } catch (err) {
                result.Failed++;
                result.Issues.push(String(err));
                details.push({
                    Item: item,
                    Decision: 'Failed',
                    Stage: 'Qualification',
                    Reason: String(err),
                });
                continue;
            }

            if (verdict.Decision === 'Exclude') {
                result.Excluded++;
                details.push({
                    Item: item,
                    Decision: options.DryRun ? 'WouldExclude' : 'Excluded',
                    Stage: verdict.StageName,
                    Reason: verdict.Reason,
                    RuleID: verdict.ActivitySyncRuleID,
                    ExclusionID: verdict.ActivitySyncExclusionID,
                });
                continue;
            }

            if (verdict.Decision !== 'Include') {
                result.Excluded++;
                details.push({
                    Item: item,
                    Decision: options.DryRun ? 'WouldExclude' : 'Excluded',
                    Stage: verdict.StageName,
                    Reason: verdict.Reason,
                });
                continue;
            }

            if (options.DryRun) {
                result.Included++;
                details.push({
                    Item: item,
                    Decision: 'WouldInclude',
                    Stage: verdict.StageName,
                    Reason: verdict.Reason,
                    RuleID: verdict.ActivitySyncRuleID,
                });
                continue;
            }

            const itemIdentities = await this.resolver.Resolve(item.Participants, contextUser);
            if (itemIdentities.LookupFailed) {
                result.Failed++;
                details.push({
                    Item: item,
                    Decision: 'Failed',
                    Stage: 'Resolve',
                    Reason: 'ContactMethod lookup failed',
                });
                continue;
            }

            const sourceValue = plugin.IsLive ? 'Integration' : 'System';
            const written = await this.writer.Write(
                {
                    Item: item,
                    ConnectionID: connection.ID,
                    SourceSystem: sourceSystem,
                    Source: sourceValue,
                    Resolved: itemIdentities.Resolved,
                    Unresolved: itemIdentities.Unresolved,
                    StoreBody: StoreBodyFromSettings(connection.Settings),
                },
                provider,
                contextUser,
            );
            if (!written.Success) {
                result.Failed++;
                details.push({
                    Item: item,
                    Decision: 'Failed',
                    Stage: 'Write',
                    Reason: written.Issues.join('; ') || 'write failed',
                });
                continue;
            }
            if (written.AlreadyPresent) {
                result.Duplicates++;
                details.push({
                    Item: item,
                    Decision: 'Duplicate',
                    Stage: 'Write',
                    Reason: 'SourceSystem+ExternalID already present',
                    ActivityID: written.ActivityID,
                });
                continue;
            }
            result.Included++;
            details.push({
                Item: item,
                Decision: 'Included',
                Stage: verdict.StageName,
                Reason: verdict.Reason,
                RuleID: verdict.ActivitySyncRuleID,
                ActivityID: written.ActivityID,
            });
        }

        const outcome: RunOutcome = {
            Settled: result.Included + result.Duplicates,
            Discarded: result.Excluded,
            Failed: result.Failed,
        };
        const candidate = batch.HighWatermark;
        const next = options.DryRun ? since : NextWatermark(since, candidate, outcome);
        if (!options.DryRun && next && CanAdvanceWatermark(outcome) && candidate) {
            result.WatermarkAdvancedTo = next;
            await this.stampConnectionWatermark(connectionID, next, contextUser, provider);
        }

        await this.persistRun(connection, options, result, since, options.DryRun ? null : result.WatermarkAdvancedTo, provider, contextUser, details);
        result.Success = result.Failed === 0;
        return result;
    }

    private resolvePlugin(driverClass: string): BaseActivitySyncProvider | null {
        try {
            const created = MJGlobal.Instance.ClassFactory.TryCreateInstance<BaseActivitySyncProvider>(
                BaseActivitySyncProvider,
                driverClass,
            );
            if (created.Resolved && created.Instance) return created.Instance;
            return null;
        } catch {
            if (driverClass === 'Generic') {
                return new FixtureActivitySyncProvider();
            }
            return null;
        }
    }

    private async loadConnection(id: string, user: UserInfo): Promise<ConnectionRow | null> {
        const rv = new RunView();
        const res = await rv.RunView<ConnectionRow>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.Connections,
                ExtraFilter: `ID = '${RequireUUID(id, 'ActivitySyncConnectionID')}'`,
                MaxRows: 1,
                ResultType: 'simple',
            },
            user,
        );
        return res.Success ? (res.Results?.[0] ?? null) : null;
    }

    private async loadProviderType(id: string | null | undefined, user: UserInfo): Promise<ProviderTypeRow | null> {
        if (!id) return null;
        const rv = new RunView();
        const res = await rv.RunView<ProviderTypeRow>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.ProviderTypes,
                ExtraFilter: `ID = '${RequireUUID(id, 'ActivitySyncProviderTypeID')}'`,
                MaxRows: 1,
                ResultType: 'simple',
            },
            user,
        );
        return res.Success ? (res.Results?.[0] ?? null) : null;
    }

    private async loadExclusions(connectionID: string, user: UserInfo): Promise<ExclusionRow[]> {
        const rv = new RunView();
        const res = await rv.RunView<ExclusionRow>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.Exclusions,
                ResultType: 'simple',
            },
            user,
        );
        if (!res.Success) return [];
        return res.Results ?? [];
    }

    private async loadRules(connectionID: string, user: UserInfo): Promise<RuleRow[]> {
        const rv = new RunView();
        const bound = await rv.RunView<{ ActivitySyncRuleSetID: string }>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.ConnectionRuleSets,
                ExtraFilter: `ActivitySyncConnectionID = '${RequireUUID(connectionID, 'ActivitySyncConnectionID')}'`,
                ResultType: 'simple',
            },
            user,
        );
        const setIds = (bound.Results ?? []).map((r) => r.ActivitySyncRuleSetID);
        const res = await rv.RunView<RuleRow>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.Rules,
                ExtraFilter: setIds.length
                    ? `ActivitySyncRuleSetID IN (${UuidInList(setIds, 'ActivitySyncRuleSetID')})`
                    : `ActivitySyncConnectionID = '${RequireUUID(connectionID, 'ActivitySyncConnectionID')}'`,
                ResultType: 'simple',
            },
            user,
        );
        return res.Success ? (res.Results ?? []) : [];
    }

    private async stampConnectionWatermark(
        connectionID: string,
        at: Date,
        user: UserInfo,
        provider: IMetadataProvider,
    ): Promise<void> {
        const row = await provider.GetEntityObject<mjBizAppsCommonActivitySyncConnectionEntity>(
            ACTIVITY_SYNC_ENTITIES.Connections,
            user,
        );
        if (!(await row.Load(connectionID))) return;
        row.LastSyncAt = at;
        row.LastError = null;
        if (row.Status === 'Error') row.Status = 'Active';
        await row.Save();
    }

    private async persistRun(
        connection: ConnectionRow,
        options: SyncRunOptions,
        result: SyncEngineResult,
        watermarkBefore: Date | null,
        watermarkAfter: Date | null,
        provider: IMetadataProvider,
        user: UserInfo,
        details: Array<{
            Item: NormalizedItem;
            Decision: SyncDecision;
            Stage: string;
            Reason: string;
            RuleID?: string;
            ExclusionID?: string;
            ActivityID?: string | null;
        }>,
    ): Promise<void> {
        try {
            const run = await provider.GetEntityObject<mjBizAppsCommonActivitySyncRunEntity>(
                ACTIVITY_SYNC_ENTITIES.Runs,
                user,
            );
            run.NewRecord();
            run.ActivitySyncConnectionID = connection.ID;
            run.TriggerType = options.TriggerType;
            run.IsDryRun = options.DryRun;
            run.Fetched = result.Fetched;
            run.Included = result.Included;
            run.Excluded = result.Excluded;
            run.Duplicates = result.Duplicates;
            run.Failed = result.Failed;
            run.ExtensionErrors = result.ExtensionErrors;
            run.WatermarkBefore = watermarkBefore;
            run.WatermarkAfter = options.DryRun ? null : watermarkAfter;
            run.StartedAt = new Date();
            run.EndedAt = new Date();
            run.Status = result.Failed > 0 ? 'Failed' : 'Completed';
            if (!(await run.Save())) {
                result.Issues.push(run.LatestResult?.CompleteMessage ?? 'ActivitySyncRun.Save failed.');
                return;
            }
            result.RunID = run.ID;
            for (const detail of details) {
                const row = await provider.GetEntityObject<mjBizAppsCommonActivitySyncRunDetailEntity>(
                    ACTIVITY_SYNC_ENTITIES.RunDetails,
                    user,
                );
                row.NewRecord();
                row.ActivitySyncRunID = run.ID;
                row.ExternalID = detail.Item.ExternalID;
                row.ExternalThreadID = detail.Item.ExternalThreadID;
                row.OccurredAt = detail.Item.StartedAt;
                row.Decision = options.DryRun ? AsDryRunDecision(detail.Decision) : detail.Decision;
                row.DecidedByStage = detail.Stage;
                row.Reason = detail.Reason.slice(0, 500);
                row.ActivitySyncRuleID = detail.RuleID ?? null;
                row.ActivitySyncExclusionID = detail.ExclusionID ?? null;
                row.ActivityID = detail.Decision === 'Included' ? (detail.ActivityID ?? null) : null;
                if (!(await row.Save())) {
                    result.Issues.push(
                        row.LatestResult?.CompleteMessage ??
                            `ActivitySyncRunDetail.Save failed for ${detail.Item.ExternalID}.`,
                    );
                }
            }
        } catch (err) {
            LogError(`ActivitySyncEngine.persistRun failed: ${err}`);
            result.Issues.push(String(err));
        }
    }
}

export function LoadActivitySyncEngine(): void {
    void ActivitySyncEngine;
    void BaseActivitySyncExtension;
    void FixtureActivitySyncProvider;
    void MSGraphActivitySyncProvider;
}
