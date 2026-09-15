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
import { AttachmentPolicyFor, HostActivityFileSink, type ActivityFileSink } from './attachments.js';
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
    ResolveCapturePlan,
    ResolvePolicy,
    type SkippedContentPolicy,
    type SyncDecision,
    type SyncRunOptions,
} from './run.js';
import {
    ContentToCapture,
    HostActivityContentCipher,
    type ActivityContentCipher,
} from './content-capture.js';
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
    /** Overrides the provider type's default. Null means "use the type's". */
    SkippedContentPolicy: string | null;
    /** Overrides the provider type's default key. Null means "use the type's". */
    EncryptionKeyID: string | null;
    Settings: string | null;
}

interface ProviderTypeRow {
    ID: string;
    Code: string;
    DriverClass: string;
    DefaultQualificationPolicy: QualificationPolicy;
    /** Companion calendar ClassFactory key. Null = this type has no second surface. */
    CalendarDriverClass: string | null;
    /**
     * The administrator's switch for the whole connector type. Every field here must also appear in
     * `loadProviderType`'s `Fields` list — declaring one without listing it yields `undefined` at
     * runtime and any check against it quietly never fires.
     */
    IsActive: boolean;
    /**
     * Audit retention for messages this connector declines to ingest, and the key that protects it.
     *
     * Both are the TYPE-level default; a connection overrides either. Neither had a reader before
     * this change, so "Overridable per connection" described a fallback chain that did not exist.
     */
    DefaultSkippedContentPolicy: string | null;
    DefaultEncryptionKeyID: string | null;
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


/**
 * The driver class of the SURFACE being run, which is not always the connection's.
 *
 * `RunConnections` drives a second, calendar surface from the same connection and the same type row,
 * passing the calendar plugin as `source`. Handing `typeRow.DriverClass` to both told a host factory
 * "Microsoft365" on the calendar pass too, so a factory serving both surfaces could not tell them
 * apart: it built a MAIL transport for the calendar, fed Graph message payloads to the event mapper,
 * and every one was dropped for having no start time. That reads as an empty calendar, not as a
 * wiring fault — which is why it survived until a calendar fixture ran end to end.
 *
 * Pure and exported so the mapping can be pinned without standing up a fleet run.
 */
export function SurfaceDriverClass(
    kind: ActivitySourceKind,
    typeRow: { DriverClass?: string | null; CalendarDriverClass?: string | null } | null | undefined,
    fallback: string,
): string {
    const declared = kind === 'Calendar' ? typeRow?.CalendarDriverClass : typeRow?.DriverClass;
    // A blank column is not a driver. Falling through to the plugin's own code keeps a
    // half-configured provider type working as it did rather than serving an empty string.
    return declared?.trim() ? declared.trim() : fallback;
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
         *
         * DEFAULTS TO THE HOST REGISTRY, because the only production construction of this class is
         * `new ActivitySyncEngine()` inside an Action, where nothing can pass one. Without that
         * default a host could implement the interface and still never be called.
         */
        private readonly fileSink: ActivityFileSink | null = HostActivityFileSink(),
        /**
         * How captured content is protected, when a policy says to keep any.
         *
         * Same shape and same reason as `fileSink`: this package implements no crypto, and the only
         * production construction of this class passes no arguments, so the default has to come from
         * the host registry or the seam is unreachable. `common-server` fills it at bootstrap.
         */
        private readonly cipher: ActivityContentCipher | null = HostActivityContentCipher(),
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
        // Switched off by an administrator. Refusing loudly rather than skipping quietly: a connection
        // that stops syncing while still reporting success is the failure this whole subsystem exists
        // to make impossible. `=== false` so that a row loaded without the field — an injected test row,
        // or a Fields list someone trims later — keeps running rather than halting every sync silently.
        if (typeRow?.IsActive === false) {
            result.Issues.push(`Provider type '${typeRow.Code}' is not active.`);
            return result;
        }
        /**
         * AUDIT RETENTION IS SETTLED BEFORE ANYTHING IS READ, not at persist time.
         *
         * `ResolveCapturePlan` refuses a policy above `None` with no key, and refusing AFTER a
         * mailbox has been read is the wrong order: it costs a fetch, and the run then has content it
         * has been told it may not keep. Deciding here means a misconfigured connection stops before
         * it touches anyone's mail.
         *
         * Failing the run rather than reporting and carrying on is what the policy asks for. An
         * operator who set this asked for the record to exist; producing runs that look successful
         * while retaining nothing is the failure this subsystem is written against, and it is exactly
         * what happened before this was wired at all.
         */
        let capture: { Capture: 'None' | 'Subject' | 'Full'; EncryptionKeyID: string | null };
        try {
            capture = ResolveCapturePlan(
                ResolvePolicy<SkippedContentPolicy>(
                    (typeRow?.DefaultSkippedContentPolicy as SkippedContentPolicy | null) ?? 'None',
                    connection.SkippedContentPolicy as SkippedContentPolicy | null,
                ),
                connection.EncryptionKeyID ?? typeRow?.DefaultEncryptionKeyID ?? null,
            );
        } catch (err) {
            result.Issues.push(String(err instanceof Error ? err.message : err));
            return result;
        }
        if (capture.Capture !== 'None' && !this.cipher) {
            // The ActivityFileSink lesson, applied. A host that asked for retention and cannot
            // encrypt must not quietly proceed: plaintext is forbidden outright, and writing nothing
            // would leave the operator believing an audit trail exists.
            result.Issues.push(
                `SkippedContentPolicy is "${capture.Capture === 'Subject' ? 'SubjectEncrypted' : 'FullEncrypted'}" ` +
                    'but this host registered no content cipher, so captured content could not be encrypted. ' +
                    'Call RegisterActivityContentCipher() at bootstrap, or set the policy to "None".',
            );
            return result;
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
        // THE DRIVER CLASS OF THE SURFACE BEING RUN, not of the connection.
        //
        // `RunConnections` drives a second, CALENDAR surface from the same connection and the same
        // type row, passing the calendar plugin as `source`. Handing `typeRow.DriverClass` to both
        // told a host factory "Microsoft365" for the calendar pass as well, so a factory serving both
        // surfaces could not tell them apart and built a MAIL transport for the calendar — which then
        // fed Graph message payloads to the event mapper, and every one was dropped for having no
        // start time. It read as an empty calendar rather than as a wiring fault.
        //
        // The plugin already knows which surface it is; that is what `Kind` is for.
        const surfaceDriver = SurfaceDriverClass(plugin.Kind, typeRow, plugin.ProviderTypeCode);
        plugin.Configure({
            CredentialsRef: connection.CredentialsRef ?? null,
            Mailbox: connection.Mailbox ?? null,
            DriverClass: surfaceDriver,
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
            await this.persistRun(connection, options, result, since, null, provider, contextUser, capture, []);
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
            } else if (attachmentPolicy.Fetch) {
                // A sink IS registered, and `ActivityFileSink.Store` still has no caller: selection and
                // transfer are written (`SelectAttachments`, `AttachmentSkipReport`) but not yet wired to
                // it. Saying so is the entire point of the branch above — leaving this case silent would
                // reward a host for filling the seam correctly with exactly the quiet nothing that the
                // rest of this work exists to remove, and it is the more misleading of the two, because
                // everything on the host's side is right.
                result.Issues.push(
                    `Item ${item.ExternalID}: its rule asks for attachments and a sink is registered, but ` +
                        'attachment transfer is not implemented yet, so none were stored. This is a gap in ' +
                        'Activity Sync, not in the host configuration.',
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

        await this.persistRun(
            connection,
            options,
            result,
            since,
            options.DryRun ? null : result.WatermarkAdvancedTo,
            provider,
            contextUser,
            capture,
            details,
        );
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
            // Issues travel whether or not the surface succeeded; only `Success` keys on failure. The
            // previous shape meant a caller inspecting `fleet.Issues` saw nothing from a run that
            // completed with warnings, which is most of what this engine has to say.
            fleet.Issues.push(...primary.Issues);
            if (!primary.Success) {
                fleet.Success = false;
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
                    // Same as the primary surface above: issues travel regardless of success.
                    fleet.Issues.push(...calendar.Issues);
                    if (!calendar.Success) {
                        fleet.Success = false;
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
        // No capture plan, and none needed: this path writes ZERO run details, so there is no row for
        // content to land on. Reaching for the connection's real policy here would be a decision
        // dressed up as caution — this method exists to record a run that never got as far as
        // deciding anything about a message.
        const noCapture = { Capture: 'None' as const, EncryptionKeyID: null };
        await this.persistRun(connection, options, result, since, null, provider, contextUser, noCapture, []);
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
                // Every name here must match ProviderTypeRow exactly, both ways round. The docblock
                // there is not decoration: a field declared and not listed reads `undefined`, and a
                // capture policy that reads undefined silently means "None". A test pins the two
                // lists against each other, and it parses this array literally -- keep comments out
                // of it.
                Fields: [
                    'ID',
                    'Code',
                    'DriverClass',
                    'DefaultQualificationPolicy',
                    'CalendarDriverClass',
                    'IsActive',
                    'DefaultSkippedContentPolicy',
                    'DefaultEncryptionKeyID',
                ],
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
        capture: { Capture: 'None' | 'Subject' | 'Full'; EncryptionKeyID: string | null },
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
            /**
             * EVERY ISSUE IS RECORDED, INCLUDING ON A RUN THAT SUCCEEDED.
             *
             * This row used to keep none of them. `healthErrorFromResults` filters to `!r.Success` and
             * the fleet collected issues only from failed surfaces, so a warning raised by a run that
             * completed existed in an in-memory array and nowhere else. That silently discarded the
             * ENTIRE delivery mechanism for several deliberate reports: the attachment gap a rule asked
             * for and no sink could fill, the participant-scope warning, the capped-read notice, and the
             * calendar's first-run lookback bound. Each was written to be seen, and none could be.
             *
             * The column is named ErrorMessage and these are not all errors. Recording them here is
             * still right: it is the run's only free-text column, it is NVARCHAR(MAX), and a warning
             * nobody can read is worth less than one filed under an imperfect name. Connection HEALTH
             * stays keyed on failure — a warned run must not make a working connection look broken.
             */
            run.ErrorMessage = result.Issues.length > 0 ? result.Issues.join(' | ').slice(0, 4000) : null;
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
                /**
                 * CAPTURED CONTENT, for messages this run declined to file.
                 *
                 * Only on a real skip. `Included` has an Activity carrying the content already, and a
                 * DRY RUN decided nothing — `WouldExclude` is a preview, and writing ciphertext for a
                 * message the engine has not actually declined would put real content behind a
                 * retention policy on the strength of a rehearsal.
                 *
                 * `Failed` is deliberately included: a message that could not be written is exactly
                 * the one an auditor asks about, and it is the case where nothing else holds a copy.
                 *
                 * Ciphertext and key are written together or not at all, mirroring
                 * CK_ActivitySyncRunDetail_ContentKey. Encryption failing is reported and the row is
                 * still saved without content: losing the whole run record because one message could
                 * not be encrypted would be a worse trade than an audit gap that says so.
                 */
                const skipped = detail.Decision === 'Excluded' || detail.Decision === 'Duplicate' || detail.Decision === 'Failed';
                if (capture.Capture !== 'None' && skipped && !options.DryRun && this.cipher && capture.EncryptionKeyID) {
                    const plaintext = ContentToCapture(capture.Capture, detail.Item);
                    if (plaintext !== null) {
                        try {
                            row.CapturedContent = await this.cipher.Encrypt(plaintext, capture.EncryptionKeyID);
                            row.EncryptionKeyID = capture.EncryptionKeyID;
                        } catch (err) {
                            result.Issues.push(
                                `Could not encrypt captured content for ${detail.Item.ExternalID}: ` +
                                    `${err instanceof Error ? err.message : String(err)}. The decision was recorded; ` +
                                    'the content was not.',
                            );
                        }
                    }
                }
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
