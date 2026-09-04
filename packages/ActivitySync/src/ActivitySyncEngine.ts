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
    mjBizAppsCommonActivitySyncExtensionEntity,
    mjBizAppsCommonActivitySyncRunDetailEntity,
    mjBizAppsCommonActivitySyncRunEntity,
} from '@mj-biz-apps/common-entities';

import { BaseActivitySyncExtension } from './BaseActivitySyncExtension.js';
import { BaseActivitySyncProvider } from './BaseActivitySyncProvider.js';
import { ACTIVITY_SYNC_ENTITIES } from './entity-names.js';
import {
    ExtensionsExtraFilter,
    RunRegisteredExtensions,
    type ExtensionRegistration,
    type ExtensionStamp,
} from './extensions.js';
import { IdentityResolver } from './identity.js';
import { ParseInternalDomains, ParticipantScopeWarning } from './participants.js';
import { AttachmentPolicyFor, type ActivityFileSink } from './attachments.js';
import {
    DefaultDeterministicStages,
    type EngineQualificationContext,
    type ExclusionRow,
    type RuleRow,
} from './stages.js';
import { FixtureActivitySyncProvider } from './providers/FixtureActivitySyncProvider.js';
import { MSGraphActivitySyncProvider } from './providers/MSGraphActivitySyncProvider.js';
import { MSGraphCalendarSyncProvider } from './providers/MSGraphCalendarSyncProvider.js';
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
import type { ActivitySourceKind, NormalizedItem } from './types.js';
import {
    CanAdvanceWatermark,
    MergeCalendarWatermark,
    NextWatermark,
    SurfaceWatermark,
    type RunOutcome,
} from './watermark.js';
import { ExclusionsExtraFilter, FromRunView, RulesExtraFilter, type ViewLoad } from './load.js';
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

export interface FleetRunResult {
    Success: boolean;
    ConnectionsAttempted: number;
    Results: Array<{ ConnectionID: string; Surface: string; Result: SyncEngineResult }>;
    Issues: string[];
}

/** Hard cap on the fleet query. Unbounded RunView is how a tenant with a burst of mailboxes stalls the hourly job. */
export const MAX_RUNNABLE_CONNECTIONS = 500;

interface ConnectionRow {
    ID: string;
    Status: string;
    Provider: string | null;
    Mailbox: string | null;
    /** MJ Credentials engine KEY, never a secret. Read by `BaseActivitySyncProvider.Configure`. */
    CredentialsRef: string | null;
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
    /** Companion calendar ClassFactory key. Null = this type has no second surface. */
    CalendarDriverClass: string | null;
}

interface RunSurfaceOptions {
    /** Injected provider (tests). When omitted, resolved from the type row. */
    source?: BaseActivitySyncProvider;
    /**
     * Connection health is per-connection, not per-surface. RunConnections stamps once
     * from the combined outcome so a refused calendar pass cannot clear a message failure.
     */
    stampHealth: boolean;
    /** Skip the ID reload when the fleet already has the row. */
    connection?: ConnectionRow;
    /** Skip the type reload when the fleet already loaded it. */
    typeRow?: ProviderTypeRow | null;
}

/**
 * LastError must name the failure, not whatever happened to be Issues[0].
 * Mapping warnings ("Event X had no usable start time") sort ahead of the actual miss.
 */
export function healthErrorFromResults(results: readonly SyncEngineResult[]): string | null {
    const failed = results.filter((r) => !r.Success);
    if (failed.length === 0) return null;
    const issues = failed.flatMap((r) => r.Issues).filter((m) => m.trim().length > 0);
    return (issues.join(' | ') || 'Activity sync run failed.').slice(0, 4000);
}

/**
 * One Load+Save per extension row after the batch — not N items × M extensions.
 *
 * An error is sticky within the batch on purpose: a later success on a different item must
 * not clear LastError for a Skip that already happened in this run. Only a later run that
 * is clean for that row writes null.
 */
export function collapseExtensionStamps(stamps: readonly ExtensionStamp[]): ExtensionStamp[] {
    const byId = new Map<string, string | null>();
    for (const stamp of stamps) {
        const prev = byId.get(stamp.ID);
        if (stamp.LastError) {
            byId.set(stamp.ID, stamp.LastError);
        } else if (prev === undefined) {
            byId.set(stamp.ID, null);
        }
    }
    return [...byId.entries()].map(([ID, LastError]) => ({ ID, LastError }));
}

function failedSurfaceResult(issues: readonly string[]): SyncEngineResult {
    return {
        Success: false,
        RunID: null,
        Fetched: 0,
        Included: 0,
        Excluded: 0,
        Duplicates: 0,
        Failed: 1,
        ExtensionErrors: 0,
        WatermarkAdvancedTo: null,
        Issues: [...issues],
    };
}

export class ActivitySyncEngine {
    public constructor(
        private readonly resolver: IdentityResolver = new IdentityResolver(),
        private readonly writer: ActivityWriter = new ActivityWriter(),
        private readonly stages: IQualificationStage[] = DefaultDeterministicStages(),
        /**
         * Where attachment BYTES go, when a rule asks for them.
         *
         * Optional and injected rather than imported: storing a file needs MJ's FileStorageEngine and
         * a configured FileStorageAccount, and a host that syncs only metadata should not have to
         * have either. Absent, an item whose rule wants attachments is reported rather than quietly
         * filed without them — the distinction this package exists to keep.
         */
        private readonly fileSink?: ActivityFileSink,
    ) {}

    public async Run(
        connectionID: string,
        options: SyncRunOptions,
        provider: IMetadataProvider,
        contextUser: UserInfo,
        source?: BaseActivitySyncProvider,
        surface?: RunSurfaceOptions,
    ): Promise<SyncEngineResult> {
        const stampHealth = surface?.stampHealth ?? true;
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

        let connection = surface?.connection;
        if (!connection || connection.ID !== connectionID) {
            const loadedConnection = await this.loadConnection(connectionID, contextUser);
            if (loadedConnection.Failed) {
                result.Issues.push(loadedConnection.Issue);
                return result;
            }
            connection = loadedConnection.Rows[0];
        }
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

        let typeRow: ProviderTypeRow | null = null;
        if (surface && Object.prototype.hasOwnProperty.call(surface, 'typeRow')) {
            typeRow = surface.typeRow ?? null;
        } else if (connection.ActivitySyncProviderTypeID) {
            const loadedType = await this.loadProviderType(connection.ActivitySyncProviderTypeID, contextUser);
            if (loadedType.Failed) {
                result.Issues.push(loadedType.Issue);
                return result;
            }
            typeRow = loadedType.Rows[0] ?? null;
        }
        // Missing type row: the cascade still needs a default, and that default is
        // Exclude — never `?? 'Include'`.
        const defaultPolicy = DefaultPolicyFromProviderType(typeRow?.DefaultQualificationPolicy);

        const plugin = (surface?.source ?? source) ?? (typeRow ? this.resolvePlugin(typeRow.DriverClass) : null);
        if (!plugin) {
            result.Issues.push(
                typeRow
                    ? `No BaseActivitySyncProvider registered for DriverClass '${typeRow.DriverClass}'.`
                    : 'Provider type is missing and no provider was injected.',
            );
            return result;
        }
        // Tell the plugin which connection this run is for BEFORE it fetches. This is the only
        // moment it can learn which credential the connection named: ClassFactory builds plugins
        // with no arguments, so nothing is injectable at construction.
        plugin.Configure({
            CredentialsRef: connection.CredentialsRef ?? null,
            Mailbox: connection.Mailbox ?? null,
            DriverClass: typeRow?.DriverClass ?? plugin.ProviderTypeCode,
            ContextUser: contextUser,
        });

        const sourceSystem = typeRow?.Code ?? plugin.ProviderTypeCode;
        const since = SurfaceWatermark(plugin.Kind, connection.LastSyncAt, connection.Settings);

        const extensions = await this.loadExtensions(connection.ID, typeRow?.ID ?? null, contextUser);
        if (extensions.Failed) {
            return this.failClosed(connection, options, result, since, provider, contextUser, extensions.Issue, stampHealth);
        }
        const batch = await plugin.Fetch({
            Mailbox: connection.Mailbox ?? '',
            Since: since,
            Limit: options.Limit,
        });
        result.Fetched = batch.Items.length;
        result.Issues.push(...batch.Issues);
        if (batch.Failed) {
            return this.failClosed(
                connection,
                options,
                result,
                since,
                provider,
                contextUser,
                batch.Issues.join(' | ') || 'Provider fetch failed.',
                stampHealth,
            );
        }

        const bound = await this.loadBoundSetIds(connectionID, contextUser);
        if (bound.Failed) {
            return this.failClosed(connection, options, result, since, provider, contextUser, bound.Issue, stampHealth);
        }
        const exclusions = await this.loadExclusions(bound.Rows, contextUser);
        if (exclusions.Failed) {
            return this.failClosed(connection, options, result, since, provider, contextUser, exclusions.Issue, stampHealth);
        }
        const rules = await this.loadRules(connectionID, bound.Rows, contextUser);
        if (rules.Failed) {
            return this.failClosed(connection, options, result, since, provider, contextUser, rules.Issue, stampHealth);
        }

        const internalDomains = await this.loadInternalDomains(bound.Rows, contextUser);
        if (internalDomains.Failed) {
            return this.failClosed(
                connection,
                options,
                result,
                since,
                provider,
                contextUser,
                internalDomains.Issue,
                stampHealth,
            );
        }
        // A rule that tests participants against NO domain list does not filter — it INVERTS.
        // `ClassifyParticipants` counts an address as Internal only when its domain is in the list,
        // so an empty list makes every participant External: `HasExternal` matches everything,
        // including the purely internal chatter it exists to keep out, and `AllInternal` matches
        // nothing. That reads as a working filter and is the opposite of one, so it is reported
        // rather than left to look like a quiet pass.
        const scopeWarning = ParticipantScopeWarning(rules.Rows, internalDomains.Rows);
        if (scopeWarning) {
            result.Issues.push(scopeWarning);
        }

        const allParticipants = batch.Items.flatMap((i) => i.Participants);
        const extensionStamps: ExtensionStamp[] = [];
        const identities = await this.resolver.Resolve(allParticipants, contextUser);
        if (identities.LookupFailed) {
            result.Failed += batch.Items.length;
            result.Issues.push('ContactMethod lookup failed — watermark will not advance.');
            await this.persistRun(connection, options, result, since, null, provider, contextUser, []);
            if (!options.DryRun && stampHealth) {
                await this.stampConnectionHealth(
                    connection.ID,
                    false,
                    'ContactMethod lookup failed — watermark will not advance.',
                    contextUser,
                    provider,
                );
            }
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
                Exclusions: exclusions.Rows,
                Rules: rules.Rows,
                InternalDomains: internalDomains.Rows,
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

            // ATTACHMENTS, decided from the rule that actually decided this item.
            //
            // `ActivitySyncRule.IncludeAttachments` and `MaxAttachmentBytes` had no reader at all:
            // a rule that asked for attachments got none and said nothing. The decision is made
            // here, where both the winning rule and the item are in scope for the first time.
            //
            // The BYTES are not moved yet — that needs a file sink, and this host has no
            // FileStorageAccount configured, so there is nowhere to put them. What changed is that
            // the request is now honoured or REPORTED, instead of silently discarded.
            const decidingRule = verdict.ActivitySyncRuleID
                ? rules.Rows.find((r) => r.ID === verdict.ActivitySyncRuleID)
                : null;
            const attachmentPolicy = AttachmentPolicyFor(decidingRule, item);
            if (attachmentPolicy.Fetch && !this.fileSink) {
                result.Issues.push(
                    `Item ${item.ExternalID}: its rule asks for attachments, but no ActivityFile sink is ` +
                        'registered in this host, so none were stored. Register one at bootstrap, or turn ' +
                        'IncludeAttachments off so the rule stops claiming something that is not happening.',
                );
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
                {
                    ProviderTypeCode: sourceSystem,
                    OnWritten: async (writeCtx) => {
                        const ext = await RunRegisteredExtensions(
                            writeCtx,
                            extensions.Rows,
                            (driverClass) => this.resolveExtension(driverClass),
                        );
                        result.ExtensionErrors += ext.Errors;
                        extensionStamps.push(...ext.Stamps);
                        if (ext.Aborted) {
                            const last = ext.Stamps[ext.Stamps.length - 1];
                            throw new Error(last?.LastError ?? 'An ActivitySyncExtension aborted the write.');
                        }
                    },
                },
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

        if (!options.DryRun) {
            await this.stampExtensions(collapseExtensionStamps(extensionStamps), provider, contextUser);
        }

        const outcome: RunOutcome = {
            Settled: result.Included + result.Duplicates,
            Discarded: result.Excluded,
            Failed: result.Failed,
        };
        const candidate = batch.HighWatermark;
        const next = options.DryRun ? since : NextWatermark(since, candidate, outcome);
        if (!options.DryRun && next && CanAdvanceWatermark(outcome) && candidate) {
            const stamped = await this.stampSurfaceWatermark(
                connectionID,
                next,
                plugin.Kind,
                contextUser,
                provider,
            );
            if (stamped) {
                result.WatermarkAdvancedTo = next;
            } else {
                result.Issues.push('Failed to persist the surface watermark — it will not advance.');
            }
        }

        await this.persistRun(connection, options, result, since, options.DryRun ? null : result.WatermarkAdvancedTo, provider, contextUser, details);
        result.Success = result.Failed === 0;
        if (!options.DryRun && stampHealth) {
            await this.stampConnectionHealth(
                connectionID,
                result.Success,
                healthErrorFromResults([result]),
                contextUser,
                provider,
            );
        }
        return result;
    }

    /**
     * Every Active-or-Error connection, once per surface. This is what a scheduled
     * Action calls. Downstream apps do not wrap this — they register an extension.
     *
     * A companion calendar pass is data: ActivitySyncProviderType.CalendarDriverClass.
     * The engine never keys on the deprecated Connection.Provider column. Calendar Graph
     * still refuses live fetch. Health is stamped once from the combined outcome so a
     * refused calendar pass cannot clear a message failure.
     */
    public async RunConnections(
        options: SyncRunOptions,
        provider: IMetadataProvider,
        contextUser: UserInfo,
    ): Promise<FleetRunResult> {
        const fleet: FleetRunResult = { Success: true, ConnectionsAttempted: 0, Results: [], Issues: [] };
        const loaded = await this.loadRunnableConnections(contextUser);
        if (loaded.Failed) {
            fleet.Success = false;
            fleet.Issues.push(loaded.Issue);
            return fleet;
        }
        if (loaded.Rows.length === 0) {
            return fleet;
        }
        let rows = loaded.Rows;
        if (rows.length > MAX_RUNNABLE_CONNECTIONS) {
            fleet.Success = false;
            fleet.Issues.push(
                `Runnable connection load exceeded MaxRows=${MAX_RUNNABLE_CONNECTIONS}; remaining connections were not attempted.`,
            );
            rows = rows.slice(0, MAX_RUNNABLE_CONNECTIONS);
        }
        for (const connection of rows) {
            fleet.ConnectionsAttempted++;
            let typeRow: ProviderTypeRow | null = null;
            if (connection.ActivitySyncProviderTypeID) {
                const loadedType = await this.loadProviderType(connection.ActivitySyncProviderTypeID, contextUser);
                if (loadedType.Failed) {
                    const failed = failedSurfaceResult([loadedType.Issue]);
                    fleet.Results.push({ ConnectionID: connection.ID, Surface: 'primary', Result: failed });
                    fleet.Success = false;
                    fleet.Issues.push(...failed.Issues);
                    if (!options.DryRun) {
                        await this.stampConnectionHealth(
                            connection.ID,
                            false,
                            healthErrorFromResults([failed]),
                            contextUser,
                            provider,
                        );
                    }
                    continue;
                }
                typeRow = loadedType.Rows[0] ?? null;
            }
            const primary = await this.Run(connection.ID, options, provider, contextUser, undefined, {
                stampHealth: false,
                connection,
                typeRow,
            });
            fleet.Results.push({ ConnectionID: connection.ID, Surface: 'primary', Result: primary });
            if (!primary.Success) {
                fleet.Success = false;
                fleet.Issues.push(...primary.Issues);
            }
            const surfaces: SyncEngineResult[] = [primary];
            const calendarDriver = typeRow?.CalendarDriverClass?.trim();
            if (calendarDriver) {
                const calendarPlugin = this.resolvePlugin(calendarDriver);
                if (!calendarPlugin) {
                    const missing = failedSurfaceResult([
                        `No BaseActivitySyncProvider registered for CalendarDriverClass '${calendarDriver}'.`,
                    ]);
                    fleet.Results.push({ ConnectionID: connection.ID, Surface: 'Calendar', Result: missing });
                    fleet.Success = false;
                    fleet.Issues.push(...missing.Issues);
                    surfaces.push(missing);
                } else {
                    const calendar = await this.Run(connection.ID, options, provider, contextUser, undefined, {
                        stampHealth: false,
                        connection,
                        typeRow,
                        source: calendarPlugin,
                    });
                    fleet.Results.push({ ConnectionID: connection.ID, Surface: 'Calendar', Result: calendar });
                    if (!calendar.Success) {
                        fleet.Success = false;
                        fleet.Issues.push(...calendar.Issues);
                    }
                    surfaces.push(calendar);
                }
            }
            if (!options.DryRun) {
                const combinedSuccess = surfaces.every((s) => s.Success);
                await this.stampConnectionHealth(
                    connection.ID,
                    combinedSuccess,
                    healthErrorFromResults(surfaces),
                    contextUser,
                    provider,
                );
            }
        }
        return fleet;
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

    private async failClosed(
        connection: ConnectionRow,
        options: SyncRunOptions,
        result: SyncEngineResult,
        since: Date | null,
        provider: IMetadataProvider,
        contextUser: UserInfo,
        issue: string,
        stampHealth: boolean,
    ): Promise<SyncEngineResult> {
        result.Issues.push(issue);
        result.Failed += result.Fetched;
        if (result.Failed < 1) result.Failed = 1;
        await this.persistRun(connection, options, result, since, null, provider, contextUser, []);
        if (!options.DryRun && stampHealth) {
            await this.stampConnectionHealth(connection.ID, false, issue, contextUser, provider);
        }
        return result;
    }

    private resolveExtension(driverClass: string): BaseActivitySyncExtension | null {
        try {
            const created = MJGlobal.Instance.ClassFactory.TryCreateInstance<BaseActivitySyncExtension>(
                BaseActivitySyncExtension,
                driverClass,
            );
            if (created.Resolved && created.Instance) return created.Instance;
            return null;
        } catch {
            return null;
        }
    }

    private async loadExtensions(
        connectionID: string,
        providerTypeID: string | null,
        user: UserInfo,
    ): Promise<ViewLoad<ExtensionRegistration>> {
        const rv = new RunView();
        const res = await rv.RunView<ExtensionRegistration>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.Extensions,
                ExtraFilter: ExtensionsExtraFilter(connectionID, providerTypeID),
                OrderBy: 'Sequence ASC',
                ResultType: 'simple',
            },
            user,
        );
        return FromRunView(res.Success, res.Results, 'ActivitySyncExtension');
    }

    private async stampExtensions(
        stamps: readonly ExtensionStamp[],
        provider: IMetadataProvider,
        user: UserInfo,
    ): Promise<void> {
        const now = new Date();
        for (const stamp of stamps) {
            try {
                const row = await provider.GetEntityObject<mjBizAppsCommonActivitySyncExtensionEntity>(
                    ACTIVITY_SYNC_ENTITIES.Extensions,
                    user,
                );
                if (!(await row.Load(stamp.ID))) continue;
                row.LastRunAt = now;
                row.LastError = stamp.LastError;
                await row.Save();
            } catch (err) {
                LogError(`ActivitySyncEngine.stampExtensions failed for ${stamp.ID}: ${err}`);
            }
        }
    }

    private async stampConnectionHealth(
        connectionID: string,
        success: boolean,
        error: string | null,
        user: UserInfo,
        provider: IMetadataProvider,
    ): Promise<void> {
        try {
            const row = await provider.GetEntityObject<mjBizAppsCommonActivitySyncConnectionEntity>(
                ACTIVITY_SYNC_ENTITIES.Connections,
                user,
            );
            if (!(await row.Load(connectionID))) return;
            if (success) {
                row.LastError = null;
                if (row.Status === 'Error') row.Status = 'Active';
            } else {
                row.Status = 'Error';
                row.LastError = (error ?? 'Activity sync run failed.').slice(0, 4000);
            }
            await row.Save();
        } catch (err) {
            LogError(`ActivitySyncEngine.stampConnectionHealth failed: ${err}`);
        }
    }

    private async loadConnection(id: string, user: UserInfo): Promise<ViewLoad<ConnectionRow>> {
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
        return FromRunView(res.Success, res.Results, 'ActivitySyncConnection');
    }

    private async loadRunnableConnections(user: UserInfo): Promise<ViewLoad<ConnectionRow>> {
        const rv = new RunView();
        const res = await rv.RunView<ConnectionRow>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.Connections,
                ExtraFilter: `Status = 'Active' OR Status = 'Error'`,
                MaxRows: MAX_RUNNABLE_CONNECTIONS + 1,
                ResultType: 'simple',
            },
            user,
        );
        return FromRunView(res.Success, res.Results, 'ActivitySyncConnection');
    }

    private async loadProviderType(id: string, user: UserInfo): Promise<ViewLoad<ProviderTypeRow>> {
        const rv = new RunView();
        const res = await rv.RunView<ProviderTypeRow>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.ProviderTypes,
                ExtraFilter: `ID = '${RequireUUID(id, 'ActivitySyncProviderTypeID')}'`,
                Fields: ['ID', 'Code', 'DriverClass', 'DefaultQualificationPolicy', 'CalendarDriverClass'],
                MaxRows: 1,
                ResultType: 'simple',
            },
            user,
        );
        return FromRunView(res.Success, res.Results, 'ActivitySyncProviderType');
    }

    private async loadBoundSetIds(connectionID: string, user: UserInfo): Promise<ViewLoad<string>> {
        const rv = new RunView();
        const bound = await rv.RunView<{ ActivitySyncRuleSetID: string }>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.ConnectionRuleSets,
                ExtraFilter: `ActivitySyncConnectionID = '${RequireUUID(connectionID, 'ActivitySyncConnectionID')}'`,
                ResultType: 'simple',
            },
            user,
        );
        if (!bound.Success) {
            return { Failed: true, Issue: 'ActivitySyncConnectionRuleSet lookup failed.' };
        }
        return {
            Failed: false,
            Rows: (bound.Results ?? []).map((r) => r.ActivitySyncRuleSetID),
        };
    }

    /**
     * The domains this deployment calls INTERNAL, merged across every rule set bound to the
     * connection.
     *
     * WHY THIS EXISTS. `ActivitySyncRuleSet.InternalDomains` describes itself as "Required for any
     * rule using ParticipantScope", `participants.ts` names it as where the list lives, and the
     * engine passed a hard-coded `[]` — so nothing ever read the column. Same shape as the
     * `CredentialsRef` gap: a column that documents its own purpose, with no reader.
     *
     * MALFORMED IS NOT EMPTY. A list that fails to parse fails the run rather than degrading to
     * `[]`, because `[]` silently inverts every participant rule (see the caller). Parsing itself
     * lives in {@link ParseInternalDomains} so it is testable without standing up a RunView.
     */
    private async loadInternalDomains(setIds: readonly string[], user: UserInfo): Promise<ViewLoad<string>> {
        if (setIds.length === 0) {
            return { Failed: false, Rows: [] };
        }
        const rv = new RunView();
        const res = await rv.RunView<{ ID: string; Name: string; InternalDomains: string | null }>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.RuleSets,
                ExtraFilter: `ID IN (${UuidInList(setIds, 'ActivitySyncRuleSetID')})`,
                Fields: ['ID', 'Name', 'InternalDomains'],
                ResultType: 'simple',
            },
            user,
        );
        if (!res.Success) {
            return { Failed: true, Issue: 'ActivitySyncRuleSet lookup failed.' };
        }

        const domains = new Set<string>();
        for (const row of res.Results ?? []) {
            const parsed = ParseInternalDomains(row.InternalDomains, row.Name);
            if (!parsed.Ok) {
                return { Failed: true, Issue: parsed.Issue };
            }
            for (const d of parsed.Domains) domains.add(d);
        }
        return { Failed: false, Rows: [...domains] };
    }

    private async loadExclusions(setIds: readonly string[], user: UserInfo): Promise<ViewLoad<ExclusionRow>> {
        const rv = new RunView();
        const res = await rv.RunView<ExclusionRow>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.Exclusions,
                ExtraFilter: ExclusionsExtraFilter(setIds),
                ResultType: 'simple',
            },
            user,
        );
        return FromRunView(res.Success, res.Results, 'ActivitySyncExclusion');
    }

    private async loadRules(
        connectionID: string,
        setIds: readonly string[],
        user: UserInfo,
    ): Promise<ViewLoad<RuleRow>> {
        const rv = new RunView();
        const res = await rv.RunView<RuleRow>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.Rules,
                ExtraFilter: RulesExtraFilter(setIds, connectionID),
                ResultType: 'simple',
            },
            user,
        );
        return FromRunView(res.Success, res.Results, 'ActivitySyncRule');
    }

    private async stampSurfaceWatermark(
        connectionID: string,
        at: Date,
        kind: ActivitySourceKind,
        user: UserInfo,
        provider: IMetadataProvider,
    ): Promise<boolean> {
        const row = await provider.GetEntityObject<mjBizAppsCommonActivitySyncConnectionEntity>(
            ACTIVITY_SYNC_ENTITIES.Connections,
            user,
        );
        if (!(await row.Load(connectionID))) return false;
        if (kind === 'Calendar') {
            row.Settings = MergeCalendarWatermark(row.Settings, at);
        } else {
            row.LastSyncAt = at;
        }
        return row.Save();
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
    void MSGraphCalendarSyncProvider;
}
