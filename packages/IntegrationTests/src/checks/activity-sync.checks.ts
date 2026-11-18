/**
 * activity-sync — the real `Common.SyncActivities` action over GraphQL, against sandbox connections
 * whose mail and calendar replay fixture files (`packages/IntegrationTests/sandbox/`).
 *
 * REQUIRES A SANDBOX HOST: MJAPI started with ACTIVITY_SYNC_SANDBOX_DIR pointing at that directory.
 * See the package README.
 *
 * THE EXPECTED DECISIONS BELOW ARE A SECOND OPINION on the case table in `sandbox/build-fixtures.mjs`.
 * They are restated here on purpose: a check that read its expectations from the fixture would pass
 * whatever the fixture said.
 *
 * THE RULE SET IS A BASELINE, not the production one (which is not defined yet): internal domain
 * sandbox-internal.test, Exclude + AllInternal, an exclusion on hr@, no Include rules, so a message is
 * captured only through the known-participant stage (a COM-WORLD person) and anything else fails closed.
 */
import { Assert, AssertEqual, IntegrationCheckRegistry, type NamedCheck } from '@memberjunction/testing-integration/registry';
import type { IntegrationCheckContext } from '@memberjunction/testing-integration/registry';
import { UUIDSet, UUIDsEqual } from '@memberjunction/global';

import { GetOrLoadWorld } from '../world/load-world.js';
import { World } from '../world/world.js';
import {
    CreateSandboxRuleSet,
    HR_ADDRESS,
    ReadSnapshot,
    RunSync,
    SANDBOX_INTERNAL_DOMAIN,
    SetConnectionScenario,
    SetConnectionStatus,
    SyncAndRead,
    WaitPastTopOfHour,
    WithCleanup,
    WithSandboxConnection,
    NewStamp,
    type DetailRow,
    type RunRow,
    type SandboxRuleSet,
    type SyncSnapshot,
} from '../sandbox-sync.js';

const MAIL_INCLUDED = ['sbx-m1-customer', 'sbx-m3-mixed'];
const MAIL_EXCLUDED = ['sbx-m2-internal', 'sbx-m4-hr', 'sbx-m5-stranger', 'sbx-m6-malformed', 'sbx-m7-subdomain'];
const CALENDAR_INCLUDED = ['sbx-e1-external', 'sbx-e2-occurrence', 'sbx-e3-cancelled'];
const CALENDAR_EXCLUDED = ['sbx-e4-internal'];
/** Never mapped: naive local time with a named zone. */
const CALENDAR_SKIPPED = 'sbx-e5-naive-tz';
const BASELINE_INCLUDED = [...MAIL_INCLUDED, ...CALENDAR_INCLUDED].sort();

const NORA = 'nora.calhoun@com-world.test';

function baselineRuleSet(ctx: IntegrationCheckContext, stamp: string, internalDomains?: string): Promise<SandboxRuleSet> {
    return CreateSandboxRuleSet(ctx, stamp, {
        InternalDomains: internalDomains ?? JSON.stringify([SANDBOX_INTERNAL_DOMAIN]),
        Exclusions: [{ Kind: 'Email', Value: HR_ADDRESS }],
    });
}

function decisionOf(decisions: Map<string, DetailRow>, externalId: string): DetailRow {
    const d = decisions.get(externalId);
    Assert(d !== undefined, `no run detail for ${externalId}; got ${[...decisions.keys()].join(', ') || '(none)'}`);
    return d;
}

function expectDecisions(decisions: Map<string, DetailRow>, ids: string[], decision: DetailRow['Decision']): void {
    for (const id of ids) AssertEqual(decisionOf(decisions, id).Decision, decision, `${id} decision`);
}

function writtenIds(snapshot: SyncSnapshot): string[] {
    return snapshot.Activities.map((a) => a.ExternalID ?? '').sort();
}

/**
 * A live run needs the connection Active, and Active is the only state the hourly job also runs —
 * so this is the one place that waits out minute 0, and the connection goes back to Paused straight
 * after, pass or fail.
 */
async function syncLive(ctx: IntegrationCheckContext, connectionId: string, limit?: number): ReturnType<typeof SyncAndRead> {
    await WaitPastTopOfHour();
    await SetConnectionStatus(ctx, connectionId, 'Active');
    return WithCleanup(
        () => SyncAndRead(ctx, connectionId, { DryRun: false, Limit: limit }),
        () => SetConnectionStatus(ctx, connectionId, 'Paused'),
        `pause sandbox connection ${connectionId}`,
    );
}

/** The mail pass among a call's runs: the one whose details are mail fixture ids (`sbx-m…`). */
function mailRunOf(run: Awaited<ReturnType<typeof SyncAndRead>>): RunRow {
    const mailRunIds = new UUIDSet(
        run.Snapshot.Details.filter((d) => d.ExternalID.startsWith('sbx-m')).map((d) => d.ActivitySyncRunID),
    );
    const mail = run.NewRuns.filter((r) => mailRunIds.Has(r.ID));
    AssertEqual(mail.length, 1, `exactly one new mail run: ${JSON.stringify(run.NewRuns)}`);
    return mail[0];
}

/** One connection on one rule set with the given InternalDomains, dry-run once, the m2 decision. */
async function m2DecisionWith(ctx: IntegrationCheckContext, prefix: string, internalDomains: string) {
    const stamp = NewStamp(prefix);
    const rules = await baselineRuleSet(ctx, stamp, internalDomains);
    return WithSandboxConnection(ctx, stamp, 'baseline', [rules.RuleSetID], async (connectionId) => {
        const run = await SyncAndRead(ctx, connectionId, { DryRun: true });
        return { Rules: rules, Run: run, M2: decisionOf(run.Decisions, 'sbx-m2-internal') };
    });
}

const decisionChecks: NamedCheck[] = [
    {
        Id: 'activity-sync.AS-D1',
        Name: 'AS-D1 — dry run over the baseline: every mail and calendar case decided, nothing written',
        RequiresMutation: true,
        Fn: async (ctx) => {
            await GetOrLoadWorld(ctx);
            const stamp = NewStamp('as-d1');
            const rules = await baselineRuleSet(ctx, stamp);
            await WithSandboxConnection(ctx, stamp, 'baseline', [rules.RuleSetID], async (connectionId) => {
                const { Result, Snapshot, NewRuns, Decisions } = await SyncAndRead(ctx, connectionId, { DryRun: true });
                Assert(Result.Success, `dry run failed: ${Result.Message}`);
                AssertEqual(NewRuns.length, 2, 'one call runs the mail pass and the calendar pass');

                expectDecisions(Decisions, [...MAIL_INCLUDED, ...CALENDAR_INCLUDED], 'WouldInclude');
                expectDecisions(Decisions, [...MAIL_EXCLUDED, ...CALENDAR_EXCLUDED], 'WouldExclude');
                Assert(UUIDsEqual(decisionOf(Decisions, 'sbx-m2-internal').ActivitySyncRuleID, rules.AllInternalRuleID), 'm2 is excluded BY the AllInternal rule');
                Assert(UUIDsEqual(decisionOf(Decisions, 'sbx-m6-malformed').ActivitySyncRuleID, rules.AllInternalRuleID), 'm6: the domain-less address is dropped, so the AllInternal rule excludes it');
                Assert(UUIDsEqual(decisionOf(Decisions, 'sbx-e4-internal').ActivitySyncRuleID, rules.AllInternalRuleID), 'e4 is excluded BY the AllInternal rule');
                Assert(UUIDsEqual(decisionOf(Decisions, 'sbx-m4-hr').ActivitySyncExclusionID, rules.ExclusionIDs[0]), 'm4 is excluded BY the hr@ exclusion, though a customer is on it');
                Assert(!UUIDsEqual(decisionOf(Decisions, 'sbx-m7-subdomain').ActivitySyncRuleID, rules.AllInternalRuleID), 'a subdomain is not internal');
                Assert(!UUIDsEqual(decisionOf(Decisions, 'sbx-m5-stranger').ActivitySyncRuleID, rules.AllInternalRuleID), 'a stranger fails closed, not by the rule');
                Assert(!Decisions.has(CALENDAR_SKIPPED), 'a naive local time is never mapped');
                Assert((Result.Message ?? '').includes(CALENDAR_SKIPPED), `the skip is reported: ${Result.Message}`);

                AssertEqual(Snapshot.Activities.length, 0, 'a dry run writes no Activity');
                AssertEqual(Snapshot.Connection.LastSyncAt, null, 'a dry run moves no watermark');
                Assert(NewRuns.every((r) => r.IsDryRun), 'every run is marked dry');
            });
        },
    },
    {
        Id: 'activity-sync.AS-D2',
        Name: 'AS-D2 — InternalDomains matches case-insensitively and tolerates a leading @',
        RequiresMutation: true,
        Fn: async (ctx) => {
            for (const domains of ['["SANDBOX-INTERNAL.TEST"]', '["@sandbox-internal.test"]']) {
                const { Rules, M2 } = await m2DecisionWith(ctx, 'as-d2', domains);
                AssertEqual(M2.Decision, 'WouldExclude', `m2 with ${domains}`);
                Assert(UUIDsEqual(M2.ActivitySyncRuleID, Rules.AllInternalRuleID), `m2 excluded by the rule with ${domains}`);
            }
        },
    },
    {
        Id: 'activity-sync.AS-D3',
        Name: 'AS-D3 — empty InternalDomains: the AllInternal rule never matches',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const { Rules, M2 } = await m2DecisionWith(ctx, 'as-d3', '[]');
            Assert(!UUIDsEqual(M2.ActivitySyncRuleID, Rules.AllInternalRuleID), 'with no internal domains, nothing is internal');
            AssertEqual(M2.Decision, 'WouldExclude', 'm2 still fails closed (no known person on it)');
        },
    },
    {
        Id: 'activity-sync.AS-D4',
        Name: 'AS-D4 — unparseable InternalDomains fails the run instead of meaning "no domains"',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const stamp = NewStamp('as-d4');
            const rules = await baselineRuleSet(ctx, stamp, 'not json');
            await WithSandboxConnection(ctx, stamp, 'baseline', [rules.RuleSetID], async (connectionId) => {
                const { Result, Decisions } = await SyncAndRead(ctx, connectionId, { DryRun: true });
                Assert(!Result.Success, `a broken InternalDomains must not succeed: ${Result.Message}`);
                Assert((Result.Message ?? '').includes(stamp), `the issue names the rule set: ${Result.Message}`);
                AssertEqual(Decisions.size, 0, 'no item is decided under a broken rule set');
            });
        },
    },
];

const runChecks: NamedCheck[] = [
    {
        Id: 'activity-sync.AS-R1',
        Name: 'AS-R1 — Paused runs only dry; a live run writes the included items as System, linked to the person',
        RequiresMutation: true,
        Fn: async (ctx) => {
            await GetOrLoadWorld(ctx);
            const stamp = NewStamp('as-r1');
            const rules = await baselineRuleSet(ctx, stamp);
            const connectionId = await WithSandboxConnection(ctx, stamp, 'baseline', [rules.RuleSetID], async (id) => {
                const paused = await SyncAndRead(ctx, id, { DryRun: false });
                AssertEqual(paused.NewRuns.length, 0, 'a live run skips a Paused connection');
                const dry = await SyncAndRead(ctx, id, { DryRun: true });
                AssertEqual(dry.NewRuns.length, 2, 'a dry run includes a Paused connection');

                const live = await syncLive(ctx, id);
                Assert(live.Result.Success, `live run failed: ${live.Result.Message}`);
                AssertEqual(writtenIds(live.Snapshot).join(','), BASELINE_INCLUDED.join(','), 'exactly the included items are written');
                Assert(live.Snapshot.Activities.every((a) => a.Source === 'System'), 'sandbox rows are System, never Integration');
                const m1 = live.Snapshot.Activities.find((a) => a.ExternalID === 'sbx-m1-customer');
                const nora = World().People[NORA];
                Assert(m1 !== undefined && nora !== undefined, 'm1 and Nora exist');
                Assert(live.Snapshot.Links.some((l) => UUIDsEqual(l.ActivityID, m1.ID) && UUIDsEqual(l.RecordID, nora.ID)), 'm1 is linked to Nora');
                const cancelled = live.Snapshot.Activities.find((a) => a.ExternalID === 'sbx-e3-cancelled');
                AssertEqual(cancelled?.Status, 'Cancelled', 'a cancelled meeting is written Cancelled');
                const occurrence = live.Snapshot.Activities.find((a) => a.ExternalID === 'sbx-e2-occurrence');
                AssertEqual(occurrence?.ExternalThreadID, 'sbx-e2-occurrence-series', 'an occurrence threads to its series');
                return id;
            });
            const after = await ReadSnapshot(ctx, connectionId);
            AssertEqual(after.Connection.Status, 'Disabled', 'the connection is Disabled after the check');
        },
    },
    {
        Id: 'activity-sync.AS-R2',
        Name: 'AS-R2 — the same sync twice writes nothing new',
        RequiresMutation: true,
        Fn: async (ctx) => {
            await GetOrLoadWorld(ctx);
            const stamp = NewStamp('as-r2');
            const rules = await baselineRuleSet(ctx, stamp);
            await WithSandboxConnection(ctx, stamp, 'baseline', [rules.RuleSetID], async (id) => {
                const first = await syncLive(ctx, id);
                Assert(first.Result.Success, `first run failed: ${first.Result.Message}`);
                AssertEqual(writtenIds(first.Snapshot).join(','), BASELINE_INCLUDED.join(','), 'the first run wrote the included items');
                const second = await syncLive(ctx, id);
                Assert(second.Result.Success, `re-run failed: ${second.Result.Message}`);
                AssertEqual(second.Snapshot.Activities.length, first.Snapshot.Activities.length, 'no duplicate Activity');
                const reincluded = [...second.Decisions.values()].filter((d) => d.Decision === 'Included');
                AssertEqual(reincluded.length, 0, `nothing is Included again: ${reincluded.map((d) => d.ExternalID).join(', ')}`);
            });
        },
    },
    {
        Id: 'activity-sync.AS-R3',
        Name: 'AS-R3 — after the watermark, only the newer message is added',
        RequiresMutation: true,
        Fn: async (ctx) => {
            await GetOrLoadWorld(ctx);
            const stamp = NewStamp('as-r3');
            const rules = await baselineRuleSet(ctx, stamp);
            await WithSandboxConnection(ctx, stamp, 'baseline', [rules.RuleSetID], async (id) => {
                const first = await syncLive(ctx, id);
                Assert(first.Snapshot.Connection.LastSyncAt !== null, 'a live run moves the watermark');
                await SetConnectionScenario(ctx, id, 'newer');
                const second = await syncLive(ctx, id);
                const added = writtenIds(second.Snapshot).filter((x) => !writtenIds(first.Snapshot).includes(x));
                AssertEqual(added.join(','), 'sbx-m8-newer', 'only the newer message is added');
            });
        },
    },
    {
        Id: 'activity-sync.AS-R4',
        Name: 'AS-R4 — ConnectionIDs runs only the named connection and reports one it could not find',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const stamp = NewStamp('as-r4');
            const rules = await baselineRuleSet(ctx, stamp);
            const missing = '9f1c2d3e-0000-4000-8000-00000000a504'; // a valid UUID no connection has
            await WithSandboxConnection(ctx, `${stamp}-a`, 'baseline', [rules.RuleSetID], async (a) => {
                await WithSandboxConnection(ctx, `${stamp}-b`, 'baseline', [rules.RuleSetID], async (b) => {
                    const result = await RunSync(ctx, [a, missing], { DryRun: true });
                    const [sa, sb] = [await ReadSnapshot(ctx, a), await ReadSnapshot(ctx, b)];
                    AssertEqual(sa.Runs.length, 2, 'the named connection ran both passes');
                    AssertEqual(sb.Runs.length, 0, 'the unnamed connection did not run');
                    Assert((result.Message ?? '').toLowerCase().includes(missing), `the missing id is reported: ${result.Message}`);
                });
            });
        },
    },
    {
        Id: 'activity-sync.AS-R5',
        Name: 'AS-R5 — a Limit that binds is reported and does not advance the mail watermark',
        RequiresMutation: true,
        Fn: async (ctx) => {
            await GetOrLoadWorld(ctx);
            const stamp = NewStamp('as-r5');
            const rules = await baselineRuleSet(ctx, stamp);
            await WithSandboxConnection(ctx, stamp, 'baseline', [rules.RuleSetID], async (id) => {
                const capped = await syncLive(ctx, id, 2);
                Assert((capped.Result.Message ?? '').includes('were not returned'), `the cap is reported: ${capped.Result.Message}`);
                const mailRun = mailRunOf(capped);
                AssertEqual(mailRun.Fetched, 2, 'the mail pass fetched exactly Limit items');
                AssertEqual(mailRun.WatermarkAfter, null, 'a capped mail pass withholds its watermark');
            });
        },
    },
];

/** A run that must fail, with a message containing `expected`, and be recorded as Failed. */
async function expectFailedScenario(ctx: IntegrationCheckContext, prefix: string, scenario: string, expected: string): Promise<void> {
    const stamp = NewStamp(prefix);
    const rules = await baselineRuleSet(ctx, stamp);
    await WithSandboxConnection(ctx, stamp, scenario, [rules.RuleSetID], async (connectionId) => {
        const { Result, NewRuns } = await SyncAndRead(ctx, connectionId, { DryRun: true });
        Assert(!Result.Success, `scenario "${scenario}" must not report success`);
        Assert((Result.Message ?? '').includes(expected), `message contains "${expected}": ${Result.Message}`);
        Assert(NewRuns.some((r) => r.Status === 'Failed'), `a run is recorded Failed: ${JSON.stringify(NewRuns)}`);
    });
}

const safetyChecks: NamedCheck[] = [
    {
        Id: 'activity-sync.AS-S1',
        Name: 'AS-S1 — an unknown scenario fails the run loudly, naming the expected file',
        RequiresMutation: true,
        Fn: (ctx) => expectFailedScenario(ctx, 'as-s1', 'does-not-exist', 'does-not-exist.mail.json'),
    },
    {
        Id: 'activity-sync.AS-S2',
        Name: 'AS-S2 — a scenario name that tries to leave the directory is refused',
        RequiresMutation: true,
        Fn: (ctx) => expectFailedScenario(ctx, 'as-s2', '../etc', 'not a valid name'),
    },
    {
        Id: 'activity-sync.AS-S3',
        Name: 'AS-S3 — a fixture recorded for another mailbox fails instead of syncing nothing',
        RequiresMutation: true,
        Fn: (ctx) => expectFailedScenario(ctx, 'as-s3', 'mismatch', 'No recorded payloads'),
    },
];

for (const check of [...decisionChecks, ...runChecks, ...safetyChecks]) {
    IntegrationCheckRegistry.Instance.Register(check);
}

IntegrationCheckRegistry.Instance.RegisterLifecycle('activity-sync', {
    Setup: async () => {},
    Teardown: async () => {},
});
