/**
 * activity-sync (standing consent) — the real `Common.SyncActivities` action on a Tagged connection that
 * also names a consent source: `Settings = {"Consent":{"Mode":"Tagged","Tag":"AIDP","SkipTag":"No AIDP",
 * "Sources":["Sandbox.OwnedAccounts"]}}`, over the `standing`, `standing-late` and `standing-noexpand`
 * fixtures. Needs the same sandbox host as the rest of the bundle.
 *
 * THE SOURCE HERE IS THE SANDBOX'S OWN (`owned-accounts.source.json`), not a consumer app's. These checks
 * prove what Common does with a source's answer; that an app's source returns the right accounts is that
 * app's to prove.
 *
 * THE EXPECTED DECISIONS ARE RESTATED HERE, not read from `build-fixtures.mjs`: a check that reads its
 * expectations from the fixture passes whatever it says.
 *
 * What a person would expect, and what each check pins:
 * - SC1: a dry run captures mail and meetings with an owned account with no tag and says which account;
 *   it does not capture another owner's account, a school, a Private item, personal Gmail (a free-mail
 *   domain on an account is dropped and reported), an automatic reply, a never-log address, or an item
 *   tagged "No AIDP"; and the tag still captures mail from someone with no account.
 * - SC2: a live run writes exactly those, and a reply from a personal address to an automatically captured
 *   item is proven by it.
 * - SC3: the owner then tags an automatically captured email and meeting "No AIDP": both are withdrawn
 *   (content purged, row kept), with the reply the email proved; a third run changes nothing.
 * - SC4: MJ 6.2.1 returns mail with no extended properties. Then no mail is captured automatically (its
 *   Private mark cannot be read) and no reply is proven; the tag and meetings still work; the run says so.
 * - SC5: a source that grants nothing and says why: reported, and the connection is tag-only.
 * - SC6: a source that throws: the run fails, nothing is decided or withdrawn, the watermark stays.
 * - SC7: a source key nobody registered: the run stops before the mailbox is read.
 * - SC8: the same mailbox with no Sources and no SkipTag is a plain Tagged connection.
 */
import { Assert, AssertEqual, IntegrationCheckRegistry, type NamedCheck } from '@memberjunction/testing-integration/registry';
import type { IntegrationCheckContext } from '@memberjunction/testing-integration/registry';

import { GetOrLoadWorld } from '../world/load-world.js';
import {
    CreateSandboxRuleSet,
    HR_ADDRESS,
    NewStamp,
    ReadConnectionSettings,
    SANDBOX_INTERNAL_DOMAIN,
    SetConnectionScenario,
    SetConnectionSettings,
    SyncAndRead,
    SyncLive,
    Untag,
    WithSandboxConnection,
    type SyncSnapshot,
} from '../sandbox-sync.js';

const consent = (sources: string[]): Record<string, unknown> => ({
    Consent: { Mode: 'Tagged', Tag: 'AIDP', SkipTag: 'No AIDP', WithdrawWindowDays: 3650, Sources: sources },
});
const OWNED = consent(['Sandbox.OwnedAccounts']);
const WITHDRAWN_PREFIX = 'withdrawn:';
const STANDING_REASON = 'Standing consent: acme-owned.test (Acme Owned Corp)';

const MAIL_INCLUDED = ['sbx-s1-owned', 'sbx-s6-tag-fallback', 'sbx-s8-auto-then-skip', 'sbx-s9-reply-to-s8', 'sbx-s10-reply-to-s1'];
const CALENDAR_INCLUDED = ['sbx-se1-owned', 'sbx-se4-auto-then-skip'];
/** Every item that must NOT be captured, with the stage that decides it. */
const EXCLUDED_BY: Record<string, string> = {
    'sbx-s2-other-owner': 'Consent',
    'sbx-s3-school': 'Consent',
    'sbx-s4-owned-private': 'Consent',
    'sbx-s5-gmail': 'Consent',
    'sbx-s7-skip': 'ConsentBlock',
    'sbx-s11-internal': 'Rules',
    'sbx-s12-out-of-office': 'ConsentBlock',
    'sbx-s13-hr': 'Exclusions',
    'sbx-se2-owned-private': 'Consent',
    'sbx-se3-school': 'Consent',
};
const WITHDRAWN = ['sbx-s8-auto-then-skip', 'sbx-s9-reply-to-s8', 'sbx-se4-auto-then-skip'];
const KEPT_AFTER_LATE = ['sbx-s1-owned', 'sbx-s6-tag-fallback', 'sbx-s10-reply-to-s1', 'sbx-se1-owned'];

async function withStanding<T>(
    ctx: IntegrationCheckContext,
    prefix: string,
    settings: Record<string, unknown>,
    fn: (id: string) => Promise<T>,
    scenario = 'standing',
): Promise<T> {
    await GetOrLoadWorld(ctx);
    const stamp = NewStamp(prefix);
    const ruleSet = await CreateSandboxRuleSet(ctx, stamp, {
        InternalDomains: JSON.stringify([SANDBOX_INTERNAL_DOMAIN]),
        Exclusions: [{ Kind: 'Email', Value: HR_ADDRESS }],
    });
    return WithSandboxConnection(ctx, stamp, scenario, [ruleSet.RuleSetID], async (id) => {
        await SetConnectionSettings(ctx, id, settings);
        return fn(id);
    });
}

function live(snapshot: SyncSnapshot): string[] {
    return snapshot.Activities.filter((a) => !(a.ExternalID ?? '').startsWith(WITHDRAWN_PREFIX)).map((a) => Untag(a.ExternalID) ?? '').sort();
}

function sameSet(actual: string[], expected: string[], what: string): void {
    AssertEqual([...actual].sort().join(', '), [...expected].sort().join(', '), what);
}

const checks: NamedCheck[] = [
    {
        Id: 'activity-sync.AS-SC1',
        Name: 'AS-SC1 — standing consent dry run: owned-account items captured with no tag and a reason that names the account; nothing else is',
        RequiresMutation: true,
        Fn: (ctx) =>
            withStanding(ctx, 'as-s1', OWNED, async (id) => {
                const run = await SyncAndRead(ctx, id, { DryRun: true });
                Assert(run.Result.Success, `dry run failed: ${run.Result.Message}`);
                for (const x of [...MAIL_INCLUDED, ...CALENDAR_INCLUDED]) AssertEqual(run.Decisions.get(x)?.Decision, 'WouldInclude', `${x} decision`);
                for (const [x, stage] of Object.entries(EXCLUDED_BY)) {
                    AssertEqual(run.Decisions.get(x)?.Decision, 'WouldExclude', `${x} decision`);
                    AssertEqual(run.Decisions.get(x)?.DecidedByStage, stage, `${x} decided by`);
                }
                for (const x of ['sbx-s1-owned', 'sbx-s8-auto-then-skip', 'sbx-se1-owned']) AssertEqual(run.Decisions.get(x)?.Reason, STANDING_REASON, `${x} reason`);
                Assert((run.Decisions.get('sbx-s6-tag-fallback')?.Reason ?? '').startsWith('Tagged "AIDP"'), 'the tag is still the reason for a tagged item');
                Assert((run.Decisions.get('sbx-s10-reply-to-s1')?.Reason ?? '').startsWith('Proven reply to'), 'a reply to a standing capture is proven by it');
                Assert((run.Decisions.get('sbx-s4-owned-private')?.Reason ?? '').includes('Personal/Private/Confidential'), 'the Private exclusion says why');
                const message = run.Result.Message ?? '';
                Assert(message.includes('"gmail.com" (Jo Sole Trader)') && message.includes('free-mail'), `the dropped free-mail domain is reported: ${message}`);
                Assert(message.includes(`"${SANDBOX_INTERNAL_DOMAIN}"`) && message.includes('own domains'), `the dropped internal domain is reported: ${message}`);
                AssertEqual(run.Snapshot.Activities.length, 0, 'a dry run writes no Activity');
            }),
    },
    {
        Id: 'activity-sync.AS-SC2',
        Name: 'AS-SC2 — standing consent live run writes exactly the consented items',
        RequiresMutation: true,
        Fn: (ctx) =>
            withStanding(ctx, 'as-s2', OWNED, async (id) => {
                const run = await SyncLive(ctx, id);
                Assert(run.Result.Success, `live run failed: ${run.Result.Message}`);
                sameSet(live(run.Snapshot), [...MAIL_INCLUDED, ...CALENDAR_INCLUDED], 'written items');
                AssertEqual(run.Decisions.get('sbx-s1-owned')?.Decision, 'Included', 'the owned-account email is filed');
                AssertEqual(run.Decisions.get('sbx-s1-owned')?.DecidedByStage, 'Consent', 'and counts as consent, so a reply can be proven from it');
            }),
    },
    {
        Id: 'activity-sync.AS-SC3',
        Name: 'AS-SC3 — "No AIDP" on an automatically captured email and meeting withdraws them and the reply the email proved; a re-run changes nothing',
        RequiresMutation: true,
        Fn: (ctx) =>
            withStanding(ctx, 'as-s3', OWNED, async (id) => {
                const first = await SyncLive(ctx, id);
                Assert(first.Result.Success, `first run failed: ${first.Result.Message}`);
                await SetConnectionScenario(ctx, id, 'standing-late');

                const second = await SyncLive(ctx, id);
                Assert(second.Result.Success, `second run failed: ${second.Result.Message}`);
                sameSet(live(second.Snapshot), KEPT_AFTER_LATE, 'items still filed');
                const withdrawn = second.Snapshot.Activities.filter((a) => (a.ExternalID ?? '').startsWith(WITHDRAWN_PREFIX));
                const firstIds = new Map(first.Snapshot.Activities.map((a) => [a.ID.toLowerCase(), Untag(a.ExternalID) ?? '']));
                sameSet(withdrawn.map((a) => firstIds.get(a.ID.toLowerCase()) ?? '?'), WITHDRAWN, `which rows were withdrawn: ${second.Result.Message}`);
                Assert(withdrawn.every((a) => a.Visibility === 'Private'), 'withdrawn rows are Private');
                const withdrawnIds = new Set(withdrawn.map((a) => a.ID.toLowerCase()));
                Assert(!second.Snapshot.Links.some((l) => withdrawnIds.has(l.ActivityID.toLowerCase())), 'withdrawn rows keep no participant link');
                Assert((second.Decisions.get('sbx-s8-auto-then-skip')?.Reason ?? '').includes('"No AIDP"'), 'the withdrawal says the skip tag caused it');

                const third = await SyncLive(ctx, id);
                Assert(third.Result.Success, `third run failed: ${third.Result.Message}`);
                AssertEqual(third.Snapshot.Activities.length, second.Snapshot.Activities.length, 'a re-run adds nothing');
                sameSet(live(third.Snapshot), KEPT_AFTER_LATE, 'a re-run withdraws nothing more and re-captures nothing');
            }),
    },
    {
        Id: 'activity-sync.AS-SC4',
        Name: 'AS-SC4 — mail read with no extended properties (MJ 6.2.1): no automatic mail capture, no proven reply; the tag and meetings still work',
        RequiresMutation: true,
        Fn: (ctx) =>
            withStanding(
                ctx,
                'as-s4',
                OWNED,
                async (id) => {
                    const run = await SyncLive(ctx, id);
                    Assert(run.Result.Success, `live run failed: ${run.Result.Message}`);
                    sameSet(live(run.Snapshot), ['sbx-s6-tag-fallback', ...CALENDAR_INCLUDED], 'written items');
                    const owned = run.Decisions.get('sbx-s1-owned');
                    AssertEqual(owned?.Decision, 'Excluded', 'owned-account mail is not captured when its Private mark cannot be read');
                    Assert((owned?.Reason ?? '').includes('acme-owned.test') && (owned?.Reason ?? '').includes('could not be read'), `and the reason says so: ${owned?.Reason}`);
                    AssertEqual(run.Decisions.get('sbx-s4-owned-private')?.Decision, 'Excluded', 'the Private email is not captured');
                    AssertEqual(run.Decisions.get('sbx-s12-out-of-office')?.Decision, 'Excluded', 'the automatic reply is not captured');
                    AssertEqual(run.Decisions.get('sbx-s10-reply-to-s1')?.Decision, 'Excluded', 'a reply cannot be proven without reply headers');
                    Assert((run.Result.Message ?? '').includes('No reply headers came back'), `the run reports the missing properties: ${run.Result.Message}`);
                },
                'standing-noexpand',
            ),
    },
    {
        Id: 'activity-sync.AS-SC5',
        Name: 'AS-SC5 — a source that grants nothing and says why: the reason is reported and only tagged items are captured',
        RequiresMutation: true,
        Fn: (ctx) =>
            withStanding(ctx, 'as-s5', consent(['Sandbox.NoEmployee']), async (id) => {
                const run = await SyncLive(ctx, id);
                Assert(run.Result.Success, `live run failed: ${run.Result.Message}`);
                sameSet(live(run.Snapshot), ['sbx-s6-tag-fallback'], 'written items');
                Assert((run.Result.Message ?? '').includes('Consent source "Sandbox.NoEmployee"') && (run.Result.Message ?? '').includes('not linked to an employee'), `the source's issue is reported: ${run.Result.Message}`);
            }),
    },
    {
        Id: 'activity-sync.AS-SC6',
        Name: 'AS-SC6 — a source that throws fails the run: nothing decided, nothing withdrawn, the watermark and sweep position unchanged',
        RequiresMutation: true,
        Fn: (ctx) =>
            withStanding(ctx, 'as-s6', OWNED, async (id) => {
                const first = await SyncLive(ctx, id);
                Assert(first.Result.Success, `first run failed: ${first.Result.Message}`);
                const swept = (await ReadConnectionSettings(ctx, id))['Consent'] as { SweptThrough?: string };
                await SetConnectionSettings(ctx, id, { ...(await ReadConnectionSettings(ctx, id)), Consent: { ...swept, Sources: ['Sandbox.Unreadable'] } });
                await SetConnectionScenario(ctx, id, 'standing-late');
                const before = await ReadConnectionSettings(ctx, id);

                const failed = await SyncLive(ctx, id);
                Assert(!failed.Result.Success, 'a run whose source throws must not succeed');
                const error = failed.Result.Message ?? '';
                Assert(error.includes('Sandbox.Unreadable') && error.toLowerCase().includes(id.toLowerCase()), `the error names the source and the connection: ${error}`);
                AssertEqual(failed.Decisions.size, 0, 'nothing was decided');
                Assert(failed.NewRuns.length > 0 && failed.NewRuns.every((r) => r.Failed > 0 && r.WatermarkAfter === null), 'the failed runs are recorded, with no watermark');
                AssertEqual(String(failed.Snapshot.Connection.LastSyncAt), String(first.Snapshot.Connection.LastSyncAt), 'the watermark did not move');
                AssertEqual(JSON.stringify(await ReadConnectionSettings(ctx, id)), JSON.stringify(before), 'surface watermarks and the sweep position did not move');
                sameSet(live(failed.Snapshot), live(first.Snapshot), 'nothing was withdrawn or added');
            }),
    },
    {
        Id: 'activity-sync.AS-SC7',
        Name: 'AS-SC7 — a source key nobody registered stops the run before the mailbox is read',
        RequiresMutation: true,
        Fn: (ctx) =>
            withStanding(ctx, 'as-s7', consent(['Sandbox.OwnedAcounts']), async (id) => {
                const run = await SyncAndRead(ctx, id, { DryRun: true });
                Assert(!run.Result.Success, 'an unknown source key must not succeed');
                Assert((run.Result.Message ?? '').includes('Sandbox.OwnedAcounts'), `the issue names the bad key: ${run.Result.Message}`);
                AssertEqual(run.Decisions.size, 0, 'nothing was decided');
                AssertEqual(run.NewRuns.length, 0, 'no run was recorded: the mailbox was never read');
            }),
    },
    {
        Id: 'activity-sync.AS-SC8',
        Name: 'AS-SC8 — the same mailbox with no Sources and no SkipTag is a plain Tagged connection: only the tagged item is captured',
        RequiresMutation: true,
        Fn: (ctx) =>
            withStanding(ctx, 'as-s8', { Consent: { Mode: 'Tagged', Tag: 'AIDP', WithdrawWindowDays: 3650 } }, async (id) => {
                const run = await SyncLive(ctx, id);
                Assert(run.Result.Success, `live run failed: ${run.Result.Message}`);
                sameSet(live(run.Snapshot), ['sbx-s6-tag-fallback'], 'written items');
                AssertEqual(run.Decisions.get('sbx-s1-owned')?.Reason, 'Not tagged', 'owned-account mail is plainly untagged here');
                AssertEqual(run.Decisions.get('sbx-s7-skip')?.DecidedByStage, 'Consent', 'with no SkipTag configured, "No AIDP" is just another category');
                Assert(!(run.Result.Message ?? '').includes('Standing consent'), `nothing about standing consent is reported: ${run.Result.Message}`);
            }),
    },
];

for (const check of checks) {
    IntegrationCheckRegistry.Instance.Register(check);
}
