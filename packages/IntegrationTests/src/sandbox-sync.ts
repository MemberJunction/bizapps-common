/**
 * Helpers for the `activity-sync` bundle: build a rule set and a sandbox connection, run the real
 * `Common.SyncActivities` action over GraphQL, and read back what it did.
 *
 * THE HOST MUST BE A SANDBOX. These checks need an MJAPI started with ACTIVITY_SYNC_SANDBOX_DIR
 * pointing at `packages/IntegrationTests/sandbox`; a `sandbox:` connection on any other host is
 * refused by design (see common-server `activity-sync-sandbox.ts`).
 *
 * LIFECYCLE. The seeded hourly job runs every Active or Error connection, so a sandbox connection
 * is created Paused, made Active only for a live run, and set Disabled in a `finally` — a failing
 * check never leaves a connection the scheduler will pick up.
 */
import { RunView, type IMetadataProvider, type RunViewParams } from '@memberjunction/core';
import type { ActionParam, ActionResult } from '@memberjunction/actions-base';
import { GraphQLActionClient, GraphQLDataProvider } from '@memberjunction/graphql-dataprovider';
import { EscapeSQLString, UUIDSet } from '@memberjunction/global';
import type {
    mjBizAppsCommonActivityEntity,
    mjBizAppsCommonActivityLinkEntity,
    mjBizAppsCommonActivitySyncConnectionEntity,
    mjBizAppsCommonActivitySyncConnectionRuleSetEntity,
    mjBizAppsCommonActivitySyncExclusionEntity,
    mjBizAppsCommonActivitySyncRuleEntity,
    mjBizAppsCommonActivitySyncRuleSetEntity,
    mjBizAppsCommonActivitySyncRunDetailEntity,
    mjBizAppsCommonActivitySyncRunEntity,
} from '@mj-biz-apps/common-entities';
import { Assert } from '@memberjunction/testing-integration/registry';
import type { IntegrationCheckContext } from '@memberjunction/testing-integration/registry';

import { COMMON_ENTITIES } from './entity-names.js';
import { FindId, RequireSave } from './wire.js';

/** `Sync Activities` in metadata/actions/.common-actions.json. */
export const SYNC_ACTION_ID = 'B2CAEFB7-60FD-41FF-8B12-DB908A7BEF0E';
export const SANDBOX_MAILBOX = 'rep@sandbox-internal.test';
export const SANDBOX_INTERNAL_DOMAIN = 'sandbox-internal.test';
export const HR_ADDRESS = 'hr@sandbox-internal.test';

/** The hourly job fires at minute 0; never start a check inside it. */
const MAX_WAIT_MS = 70_000;

export interface SandboxRuleSetOptions {
    /** Written verbatim to `InternalDomains`, so a check can store malformed JSON on purpose. */
    InternalDomains: string | null;
    Exclusions?: Array<{ Kind: mjBizAppsCommonActivitySyncExclusionEntity['IdentityKind']; Value: string }>;
    /** The Exclude + AllInternal rule. Default true. */
    ExcludeAllInternal?: boolean;
}

export interface SandboxRuleSet {
    RuleSetID: string;
    AllInternalRuleID: string | null;
    ExclusionIDs: string[];
}

export type RunRow = Pick<
    mjBizAppsCommonActivitySyncRunEntity,
    'ID' | 'Status' | 'IsDryRun' | 'Fetched' | 'Included' | 'Excluded' | 'Duplicates' | 'Failed' | 'ErrorMessage'
> & { StartedAt: string; WatermarkAfter: string | null };

export type DetailRow = Pick<
    mjBizAppsCommonActivitySyncRunDetailEntity,
    'ExternalID' | 'Decision' | 'DecidedByStage' | 'ActivitySyncRuleID' | 'ActivitySyncExclusionID' | 'ActivityID'
> & { ActivitySyncRunID: string };

export type ActivityRow = Pick<
    mjBizAppsCommonActivityEntity,
    'ID' | 'ExternalID' | 'ExternalThreadID' | 'Source' | 'Status'
> & { StartedAt: string };

export type LinkRow = Pick<mjBizAppsCommonActivityLinkEntity, 'ActivityID' | 'RecordID' | 'IdentityValue' | 'Role'>;

export interface SyncSnapshot {
    Connection: Pick<mjBizAppsCommonActivitySyncConnectionEntity, 'ID' | 'Status'> & { LastSyncAt: string | null };
    /** Newest first. */
    Runs: RunRow[];
    /** Details of every run on the connection. */
    Details: DetailRow[];
    Activities: ActivityRow[];
    Links: LinkRow[];
}

/** Lower-case run stamp that keeps one check's rows apart from every other run's. */
export function NewStamp(prefix: string): string {
    return `${prefix}-${Date.now()}-${Math.floor(Math.random() * 1e6)}`;
}

export async function CreateSandboxRuleSet(
    ctx: IntegrationCheckContext,
    stamp: string,
    opts: SandboxRuleSetOptions,
): Promise<SandboxRuleSet> {
    const ruleSet = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivitySyncRuleSetEntity>(
        COMMON_ENTITIES.ActivitySyncRuleSet,
        ctx.User,
    );
    ruleSet.NewRecord();
    ruleSet.Name = `COM-TEST sandbox ${stamp}`;
    ruleSet.InternalDomains = opts.InternalDomains;
    ruleSet.Sequence = 10;
    ruleSet.IsEnabled = true;
    ruleSet.IsSystem = false;
    await RequireSave(ruleSet, `rule set ${stamp}`);

    const allInternal = opts.ExcludeAllInternal === false ? null : await createAllInternalRule(ctx, ruleSet.ID);
    const exclusionIds: string[] = [];
    for (const ex of opts.Exclusions ?? []) {
        exclusionIds.push(await createExclusion(ctx, ruleSet.ID, ex.Kind, ex.Value));
    }
    return { RuleSetID: ruleSet.ID, AllInternalRuleID: allInternal, ExclusionIDs: exclusionIds };
}

async function createAllInternalRule(ctx: IntegrationCheckContext, ruleSetId: string): Promise<string> {
    const rule = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivitySyncRuleEntity>(
        COMMON_ENTITIES.ActivitySyncRule,
        ctx.User,
    );
    rule.NewRecord();
    rule.ActivitySyncRuleSetID = ruleSetId;
    rule.Name = 'Exclude internal-only';
    rule.IsEnabled = true;
    rule.Sequence = 10;
    rule.Action = 'Exclude';
    rule.ParticipantScope = 'AllInternal';
    rule.IncludeAttachments = false;
    await RequireSave(rule, 'AllInternal rule');
    return rule.ID;
}

async function createExclusion(
    ctx: IntegrationCheckContext,
    ruleSetId: string,
    kind: mjBizAppsCommonActivitySyncExclusionEntity['IdentityKind'],
    value: string,
): Promise<string> {
    const exclusion = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivitySyncExclusionEntity>(
        COMMON_ENTITIES.ActivitySyncExclusion,
        ctx.User,
    );
    exclusion.NewRecord();
    exclusion.ActivitySyncRuleSetID = ruleSetId;
    exclusion.IdentityKind = kind;
    exclusion.IdentityValue = value;
    exclusion.Reason = 'Sandbox check';
    exclusion.IsEnabled = true;
    await RequireSave(exclusion, `exclusion ${value}`);
    return exclusion.ID;
}

/**
 * Create a Paused sandbox connection bound to `ruleSetIds`, run `fn`, then set it Disabled whatever
 * happened. A failure to disable is thrown with the connection id, never swallowed.
 */
export async function WithSandboxConnection<T>(
    ctx: IntegrationCheckContext,
    stamp: string,
    scenario: string,
    ruleSetIds: string[],
    fn: (connectionId: string) => Promise<T>,
): Promise<T> {
    const connectionId = await createConnection(ctx, stamp, scenario);
    return WithCleanup(
        async () => {
            for (const [i, ruleSetId] of ruleSetIds.entries()) {
                await bindRuleSet(ctx, connectionId, ruleSetId, (i + 1) * 10);
            }
            return fn(connectionId);
        },
        () => SetConnectionStatus(ctx, connectionId, 'Disabled'),
        `disable sandbox connection ${connectionId}`,
    );
}

/**
 * Run `body`, then `cleanup` whatever happened. A plain `finally` would let a failing cleanup REPLACE
 * the body's error, hiding the check's real failure; here both survive in one error.
 */
export async function WithCleanup<T>(body: () => Promise<T>, cleanup: () => Promise<void>, what: string): Promise<T> {
    let result: T;
    try {
        result = await body();
    } catch (bodyError) {
        try {
            await cleanup();
        } catch (cleanupError) {
            throw new Error(
                `${(bodyError as Error).message} — and then could not ${what}: ${(cleanupError as Error).message}`,
            );
        }
        throw bodyError;
    }
    await cleanup();
    return result;
}

async function createConnection(ctx: IntegrationCheckContext, stamp: string, scenario: string): Promise<string> {
    const typeId = await FindId(ctx, COMMON_ENTITIES.ActivitySyncProviderType, `Code = 'Microsoft365'`);
    Assert(typeId !== null, 'the seeded Microsoft365 provider type is missing');
    const connection = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivitySyncConnectionEntity>(
        COMMON_ENTITIES.ActivitySyncConnection,
        ctx.User,
    );
    connection.NewRecord();
    connection.Name = `COM-TEST sandbox ${stamp}`;
    connection.Provider = 'Microsoft365';
    connection.ActivitySyncProviderTypeID = typeId;
    connection.CredentialsRef = SandboxRef(scenario, stamp);
    connection.Mailbox = SANDBOX_MAILBOX;
    connection.Status = 'Paused';
    connection.Direction = 'Inbound';
    connection.OwnerUserID = ctx.User.ID;
    await RequireSave(connection, `sandbox connection ${stamp}`);
    return connection.ID;
}

async function bindRuleSet(
    ctx: IntegrationCheckContext,
    connectionId: string,
    ruleSetId: string,
    sequence: number,
): Promise<void> {
    const binding = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivitySyncConnectionRuleSetEntity>(
        COMMON_ENTITIES.ActivitySyncConnectionRuleSet,
        ctx.User,
    );
    binding.NewRecord();
    binding.ActivitySyncConnectionID = connectionId;
    binding.ActivitySyncRuleSetID = ruleSetId;
    binding.Sequence = sequence;
    binding.IsEnabled = true;
    await RequireSave(binding, `binding ${ruleSetId}`);
}

async function loadConnection(
    ctx: IntegrationCheckContext,
    connectionId: string,
): Promise<mjBizAppsCommonActivitySyncConnectionEntity> {
    const connection = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivitySyncConnectionEntity>(
        COMMON_ENTITIES.ActivitySyncConnection,
        ctx.User,
    );
    Assert(await connection.Load(connectionId), `cannot load connection ${connectionId}`);
    return connection;
}

export async function SetConnectionStatus(
    ctx: IntegrationCheckContext,
    connectionId: string,
    status: mjBizAppsCommonActivitySyncConnectionEntity['Status'],
): Promise<void> {
    const connection = await loadConnection(ctx, connectionId);
    connection.Status = status;
    await RequireSave(connection, `set connection ${connectionId} to ${status}`);
}

/**
 * `sandbox:<scenario>:<tag>`. The tag (the check's stamp) makes the sandbox suffix every item id with
 * `.<tag>`, so this connection's Activities never dedupe against another run's replay of the same
 * fixture: the engine's dedupe key is SourceSystem + ExternalID, shared by every mailbox.
 */
export function SandboxRef(scenario: string, tag: string): string {
    return `sandbox:${scenario}:${tag}`;
}

/** The fixture id behind a run-tagged one: everything before the first '.' (fixture ids have none). */
export function Untag(id: string | null): string | null {
    return id === null ? null : id.split('.')[0];
}

/** Point an existing connection at another scenario, keeping its run tag (the watermark check). */
export async function SetConnectionScenario(
    ctx: IntegrationCheckContext,
    connectionId: string,
    scenario: string,
): Promise<void> {
    const connection = await loadConnection(ctx, connectionId);
    const tag = (connection.CredentialsRef ?? '').split(':')[2];
    Assert(tag !== undefined && tag.length > 0, `connection ${connectionId} has no run tag: ${connection.CredentialsRef}`);
    connection.CredentialsRef = SandboxRef(scenario, tag);
    await RequireSave(connection, `set connection ${connectionId} to ${connection.CredentialsRef}`);
}

/**
 * Run `Common.SyncActivities` through the GraphQL action client — the same path a person running it
 * from Explorer takes. The result's Message carries the run totals and every issue.
 */
export async function RunSync(
    ctx: IntegrationCheckContext,
    connectionIds: string[],
    opts: { DryRun: boolean; Limit?: number },
): Promise<ActionResult> {
    const provider = ctx.Provider;
    if (!(provider instanceof GraphQLDataProvider)) {
        throw new Error('the activity-sync bundle runs on the GraphQL client only (ctx.Provider is not a GraphQLDataProvider)');
    }
    // Strings on purpose: the RunAction mutation types every param Value as String, so a boolean is
    // refused by GraphQL before it reaches the action. The action parses 'true' and numbers itself.
    const params: ActionParam[] = [
        { Name: 'DryRun', Value: String(opts.DryRun), Type: 'Input' },
        { Name: 'ConnectionIDs', Value: connectionIds.join(','), Type: 'Input' },
    ];
    if (opts.Limit !== undefined) {
        params.push({ Name: 'Limit', Value: String(opts.Limit), Type: 'Input' });
    }
    const result = await new GraphQLActionClient(provider).RunAction(SYNC_ACTION_ID, params);
    Assert(result.Message !== undefined && result.Message !== null, `the action returned no message: ${JSON.stringify(result)}`);
    return result;
}

/** One RunViews round trip: the connection, its runs, their details, its activities and their links. */
export async function ReadSnapshot(ctx: IntegrationCheckContext, connectionId: string): Promise<SyncSnapshot> {
    const id = EscapeSQLString(connectionId);
    // RunView accepts a subquery only over an entity's base view, not its table.
    const runsOf = `ActivitySyncRunID IN (SELECT ID FROM [__mj_BizAppsCommon].[vwActivitySyncRuns] WHERE ActivitySyncConnectionID = '${id}')`;
    const activitiesOf = `ActivityID IN (SELECT ID FROM [__mj_BizAppsCommon].[vwActivities] WHERE ActivitySyncConnectionID = '${id}')`;
    const views: RunViewParams[] = [
        simple(COMMON_ENTITIES.ActivitySyncConnection, `ID = '${id}'`, ['ID', 'Status', 'LastSyncAt']),
        simple(COMMON_ENTITIES.ActivitySyncRun, `ActivitySyncConnectionID = '${id}'`, [
            'ID', 'Status', 'IsDryRun', 'Fetched', 'Included', 'Excluded', 'Duplicates', 'Failed', 'ErrorMessage',
            'StartedAt', 'WatermarkAfter',
        ], 'StartedAt DESC'),
        simple(COMMON_ENTITIES.ActivitySyncRunDetail, runsOf, [
            'ActivitySyncRunID', 'ExternalID', 'Decision', 'DecidedByStage', 'ActivitySyncRuleID',
            'ActivitySyncExclusionID', 'ActivityID',
        ]),
        simple(COMMON_ENTITIES.Activity, `ActivitySyncConnectionID = '${id}'`, [
            'ID', 'ExternalID', 'ExternalThreadID', 'Source', 'Status', 'StartedAt',
        ]),
        simple(COMMON_ENTITIES.ActivityLink, activitiesOf, ['ActivityID', 'RecordID', 'IdentityValue', 'Role']),
    ];
    const results = await RunView.FromMetadataProvider(ctx.Provider as IMetadataProvider).RunViews(views, ctx.User);
    results.forEach((r, i) => Assert(r.Success, `snapshot view ${views[i].EntityName} failed: ${r.ErrorMessage}`));
    const [connections, runs, details, activities, links] = results;
    Assert(connections.Results.length === 1, `connection ${connectionId} not found`);
    // Ids come back run-tagged; checks compare against the fixture ids.
    return {
        Connection: connections.Results[0] as SyncSnapshot['Connection'],
        Runs: runs.Results as RunRow[],
        Details: (details.Results as DetailRow[]).map((d) => ({ ...d, ExternalID: Untag(d.ExternalID) ?? '' })),
        Activities: (activities.Results as ActivityRow[]).map((a) => ({
            ...a,
            ExternalID: Untag(a.ExternalID),
            ExternalThreadID: Untag(a.ExternalThreadID),
        })),
        Links: links.Results as LinkRow[],
    };
}

function simple(EntityName: string, ExtraFilter: string, Fields: string[], OrderBy?: string): RunViewParams {
    return { EntityName, ExtraFilter, Fields, OrderBy, ResultType: 'simple', BypassCache: true };
}

/**
 * Run the action and return what that one call recorded. One call writes TWO runs per Microsoft365
 * connection — the mail pass and the calendar pass — so "the newest run" would see only one surface.
 */
export async function SyncAndRead(
    ctx: IntegrationCheckContext,
    connectionId: string,
    opts: { DryRun: boolean; Limit?: number },
): Promise<{ Result: ActionResult; Snapshot: SyncSnapshot; NewRuns: RunRow[]; Decisions: Map<string, DetailRow> }> {
    const before = new UUIDSet((await ReadSnapshot(ctx, connectionId)).Runs.map((r) => r.ID));
    const result = await RunSync(ctx, [connectionId], opts);
    const snapshot = await ReadSnapshot(ctx, connectionId);
    const newRuns = snapshot.Runs.filter((r) => !before.Has(r.ID));
    const newRunIds = new UUIDSet(newRuns.map((r) => r.ID));
    const decisions = new Map(
        snapshot.Details.filter((d) => newRunIds.Has(d.ActivitySyncRunID)).map((d) => [d.ExternalID, d]),
    );
    return { Result: result, Snapshot: snapshot, NewRuns: newRuns, Decisions: decisions };
}

/** If the UTC minute is 0 (the hourly job's slot), wait until minute 1. Bounded by MAX_WAIT_MS. */
export async function WaitPastTopOfHour(): Promise<void> {
    const now = new Date();
    if (now.getUTCMinutes() !== 0) return;
    const wait = (60 - now.getUTCSeconds()) * 1000 + 1000;
    Assert(wait <= MAX_WAIT_MS, `computed a ${wait}ms wait, over the ${MAX_WAIT_MS}ms cap`);
    await new Promise<void>((resolve) => setTimeout(resolve, wait));
}
