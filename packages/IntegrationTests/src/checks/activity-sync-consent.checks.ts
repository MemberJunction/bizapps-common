/**
 * activity-sync (consent) — the real `Common.SyncActivities` action on a TAGGED connection:
 * `Settings = {"Consent":{"Mode":"Tagged","Tag":"AIDP"}}`, over the `consent` and `consent-late`
 * fixtures. Needs the same sandbox host as the rest of the bundle.
 *
 * THE EXPECTED DECISIONS ARE RESTATED HERE, not read from `build-fixtures.mjs`, for the reason the
 * other checks give: a check that reads its expectations from the fixture passes whatever it says.
 *
 * What a person would expect, and what each check pins:
 * - C1: a dry run decides every case with the right reason and writes nothing.
 * - C2: a live run writes exactly the consented items (tagged, proven replies, the ancestor), never the
 *   friend's dinner, the forward, the new-recipient reply, the draft, the invite, the auto-reply, the
 *   Private reply or the internal thread; and records no blind copy.
 * - C3: the owner then tags an old email and untags another and a meeting: the sweep finds the late tag,
 *   the untagged items and the replies that depended on them are withdrawn (content purged, row kept),
 *   and a third run changes nothing.
 * - C4: the same mailbox on a KnownContact connection still captures the dinner — the behaviour the
 *   default keeps, shown side by side with the fix.
 * - C5: a mistyped consent mode fails the run before the mailbox is read.
 * - C6: a connection switched from KnownContact to Tagged does not let what KnownContact filed prove a
 *   reply. Today that also holds because KnownContact rows are keyed on Graph's per-mailbox id, which a
 *   reply's headers never name; the run-detail check in `loadPrior` is the guard that keeps it true if
 *   that ever changes, and this check pins the outcome either way.
 */
import { Assert, AssertEqual, IntegrationCheckRegistry, type NamedCheck } from '@memberjunction/testing-integration/registry';
import type { IntegrationCheckContext } from '@memberjunction/testing-integration/registry';

import { GetOrLoadWorld } from '../world/load-world.js';
import {
    CreateSandboxRuleSet,
    HR_ADDRESS,
    NewStamp,
    ReadActivityDetails,
    ReadConnectionSettings,
    SANDBOX_INTERNAL_DOMAIN,
    SetConnectionScenario,
    SetConnectionSettings,
    SyncAndRead,
    SyncLive,
    Untag,
    WithSandboxConnection,
    type SandboxRuleSet,
    type SyncSnapshot,
} from '../sandbox-sync.js';

const TAGGED = { Consent: { Mode: 'Tagged', Tag: 'AIDP', WithdrawWindowDays: 3650 } };
const WITHDRAWN_PREFIX = 'withdrawn:';
const WITHDRAWN_TITLE = '(withdrawn by the mailbox owner)';

const MAIL_INCLUDED = ['sbx-c1-tagged-quote', 'sbx-c2-reply', 'sbx-c4-phone-reply', 'sbx-c13a-original', 'sbx-c13b-tagged-reply', 'sbx-c14-bcc'];
const MAIL_EXCLUDED = [
    'sbx-c3-friend', 'sbx-c5-forward', 'sbx-c6-new-recipient', 'sbx-c7-same-conversation', 'sbx-c8-draft',
    'sbx-c9-internal-tagged', 'sbx-c10-private-reply', 'sbx-c11-out-of-office', 'sbx-c12-invite', 'sbx-c15-tagged-late',
];
const CALENDAR_INCLUDED = ['sbx-ce1-tagged'];
const CALENDAR_EXCLUDED = ['sbx-ce2-lunch', 'sbx-ce3-private'];
/** Why each exclusion happened: the stage that decided it. */
const EXCLUDED_BY: Record<string, string> = {
    'sbx-c3-friend': 'Consent',
    'sbx-c5-forward': 'Consent',
    'sbx-c6-new-recipient': 'Consent',
    'sbx-c7-same-conversation': 'Consent',
    'sbx-c8-draft': 'ConsentBlock',
    'sbx-c9-internal-tagged': 'Rules',
    'sbx-c10-private-reply': 'Consent',
    'sbx-c11-out-of-office': 'ConsentBlock',
    'sbx-c12-invite': 'ConsentBlock',
    'sbx-c15-tagged-late': 'Consent',
    'sbx-ce2-lunch': 'Consent',
    'sbx-ce3-private': 'Consent',
};
/** After consent-late: untagged, plus the replies that only the untagged quote proved. */
const WITHDRAWN = ['sbx-c1-tagged-quote', 'sbx-c2-reply', 'sbx-c4-phone-reply', 'sbx-ce1-tagged'];
const KEPT_AFTER_LATE = ['sbx-c13a-original', 'sbx-c13b-tagged-reply', 'sbx-c14-bcc', 'sbx-c15-tagged-late'];

function rules(ctx: IntegrationCheckContext, stamp: string): Promise<SandboxRuleSet> {
    return CreateSandboxRuleSet(ctx, stamp, {
        InternalDomains: JSON.stringify([SANDBOX_INTERNAL_DOMAIN]),
        Exclusions: [{ Kind: 'Email', Value: HR_ADDRESS }],
    });
}

/** A Tagged sandbox connection on `scenario`, bound to the baseline rule set. */
async function withTagged<T>(ctx: IntegrationCheckContext, prefix: string, fn: (id: string) => Promise<T>, settings: Record<string, unknown> = TAGGED): Promise<T> {
    await GetOrLoadWorld(ctx);
    const stamp = NewStamp(prefix);
    const ruleSet = await rules(ctx, stamp);
    return WithSandboxConnection(ctx, stamp, 'consent', [ruleSet.RuleSetID], async (id) => {
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
        Id: 'activity-sync.AS-C1',
        Name: 'AS-C1 — Tagged dry run: every case decided with its reason, nothing written',
        RequiresMutation: true,
        Fn: (ctx) =>
            withTagged(ctx, 'as-c1', async (id) => {
                const run = await SyncAndRead(ctx, id, { DryRun: true });
                Assert(run.Result.Success, `dry run failed: ${run.Result.Message}`);
                for (const x of [...MAIL_INCLUDED, ...CALENDAR_INCLUDED]) AssertEqual(run.Decisions.get(x)?.Decision, 'WouldInclude', `${x} decision`);
                for (const x of [...MAIL_EXCLUDED, ...CALENDAR_EXCLUDED]) {
                    const d = run.Decisions.get(x);
                    AssertEqual(d?.Decision, 'WouldExclude', `${x} decision`);
                    AssertEqual(d?.DecidedByStage, EXCLUDED_BY[x], `${x} decided by`);
                }
                AssertEqual(run.Snapshot.Activities.length, 0, 'a dry run writes no Activity');
            }),
    },
    {
        Id: 'activity-sync.AS-C2',
        Name: 'AS-C2 — Tagged live run writes only consented items, with no blind copy (links or Details)',
        RequiresMutation: true,
        Fn: (ctx) =>
            withTagged(ctx, 'as-c2', async (id) => {
                const run = await SyncLive(ctx, id);
                Assert(run.Result.Success, `live run failed: ${run.Result.Message}`);
                sameSet(live(run.Snapshot), [...MAIL_INCLUDED, ...CALENDAR_INCLUDED], 'written items');
                Assert(run.Snapshot.Links.every((l) => l.Role !== 'Bcc'), 'no Bcc link is ever written');
                const details = await ReadActivityDetails(ctx, id);
                Assert(details.length > 0 && details.every((d) => !d.includes('bccRecipients') && !d.includes('colleague@')), 'no blind copy in the stored payloads');
                Assert(run.Snapshot.Activities.every((a) => a.Source === 'System' && a.Visibility === 'Private'), 'System and Private');
                const settings = await ReadConnectionSettings(ctx, id);
                Assert(typeof (settings['Consent'] as { SweptThrough?: unknown }).SweptThrough === 'string', 'the sweep position is recorded');
            }),
    },
    {
        Id: 'activity-sync.AS-C3',
        Name: 'AS-C3 — a late tag is swept in; removed tags are withdrawn (row kept, content gone); a re-run changes nothing',
        RequiresMutation: true,
        Fn: (ctx) =>
            withTagged(ctx, 'as-c3', async (id) => {
                const first = await SyncLive(ctx, id);
                Assert(first.Result.Success, `first run failed: ${first.Result.Message}`);
                await SetConnectionScenario(ctx, id, 'consent-late');

                const second = await SyncLive(ctx, id);
                Assert(second.Result.Success, `second run failed: ${second.Result.Message}`);
                sameSet(live(second.Snapshot), KEPT_AFTER_LATE, 'items still filed');
                const withdrawn = second.Snapshot.Activities.filter((a) => (a.ExternalID ?? '').startsWith(WITHDRAWN_PREFIX));
                AssertEqual(withdrawn.length, WITHDRAWN.length, `withdrawn count: ${second.Result.Message}`);
                const firstIds = new Map(first.Snapshot.Activities.map((a) => [a.ID.toLowerCase(), Untag(a.ExternalID) ?? '']));
                sameSet(withdrawn.map((a) => firstIds.get(a.ID.toLowerCase()) ?? '?'), WITHDRAWN, 'which rows were withdrawn');
                Assert(withdrawn.every((a) => a.Title === WITHDRAWN_TITLE && a.Visibility === 'Private'), 'withdrawn rows are purged and Private');
                const withdrawnIds = new Set(withdrawn.map((a) => a.ID.toLowerCase()));
                Assert(!second.Snapshot.Links.some((l) => withdrawnIds.has(l.ActivityID.toLowerCase())), 'withdrawn rows keep no participant link');

                const third = await SyncLive(ctx, id);
                Assert(third.Result.Success, `third run failed: ${third.Result.Message}`);
                AssertEqual(third.Snapshot.Activities.length, second.Snapshot.Activities.length, 'a re-run adds nothing');
                sameSet(live(third.Snapshot), KEPT_AFTER_LATE, 'a re-run withdraws nothing more');
            }),
    },
    {
        Id: 'activity-sync.AS-C4',
        Name: 'AS-C4 — the same mailbox on a KnownContact connection still files the dinner (the default is unchanged)',
        RequiresMutation: true,
        Fn: (ctx) =>
            withTagged(
                ctx,
                'as-c4',
                async (id) => {
                    const run = await SyncAndRead(ctx, id, { DryRun: true });
                    AssertEqual(run.Decisions.get('sbx-c3-friend')?.Decision, 'WouldInclude', 'KnownContact files a personal note to a known contact');
                    AssertEqual(run.Decisions.get('sbx-c3-friend')?.DecidedByStage, 'KnownParticipant', 'decided by the known contact');
                },
                {},
            ),
    },
    {
        Id: 'activity-sync.AS-C6',
        Name: 'AS-C6 — switched from KnownContact to Tagged: an old unconsented capture proves no reply',
        RequiresMutation: true,
        Fn: (ctx) =>
            withTagged(
                ctx,
                'as-c6',
                async (id) => {
                    const known = await SyncLive(ctx, id);
                    Assert(live(known.Snapshot).includes('sbx-c3-friend'), 'KnownContact filed the dinner email');
                    await SetConnectionSettings(ctx, id, TAGGED);
                    await SetConnectionScenario(ctx, id, 'consent-late');
                    const tagged = await SyncLive(ctx, id);
                    Assert(tagged.Result.Success, `tagged run failed: ${tagged.Result.Message}`);
                    const reply = tagged.Decisions.get('sbx-c17-reply-to-friend');
                    AssertEqual(reply?.Decision, 'Excluded', 'the friend\'s reply is not proven by an unconsented capture');
                    AssertEqual(reply?.DecidedByStage, 'Consent', 'decided by Consent');
                },
                {},
            ),
    },
    {
        Id: 'activity-sync.AS-C5',
        Name: 'AS-C5 — a mistyped consent mode fails the run before the mailbox is read',
        RequiresMutation: true,
        Fn: (ctx) =>
            withTagged(
                ctx,
                'as-c5',
                async (id) => {
                    const run = await SyncAndRead(ctx, id, { DryRun: true });
                    Assert(!run.Result.Success, 'a mistyped mode must not succeed');
                    Assert((run.Result.Message ?? '').includes('Tagd'), `the issue names the bad value: ${run.Result.Message}`);
                    AssertEqual(run.Decisions.size, 0, 'nothing was decided');
                },
                { Consent: { Mode: 'Tagd' } },
            ),
    },
];

for (const check of checks) {
    IntegrationCheckRegistry.Instance.Register(check);
}
