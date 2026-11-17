/**
 * ConsentIntake: the gather and withdraw passes of a Tagged connection, against an in-memory consent
 * store with the same meaning as the SQL one (per connection, per surface, latest decision wins).
 *
 * Each block pins one code-review finding on PR #446; the finding number is in the test name. All of
 * them were first reproduced red against the previous implementation.
 */
import { describe, expect, it } from 'vitest';

import { BaseActivitySyncProvider } from '../BaseActivitySyncProvider.js';
import { MergeConsentSweptThrough, PROP_IN_REPLY_TO, type ConsentPolicy } from '../consent.js';
import { ChooseWithdrawals, ConsentIntake, ParticipantsFromDetails, SWEEP_OVERLAP_MS, ViaOf } from '../consent-intake.js';
import type { ConsentQuery, ConsentRecord, ConsentStore, StoreResult } from '../consent-store.js';
import { RecordedMessageTransport } from '../providers/RecordedMessageTransport.js';
import type { ActivitySourceKind, ActivitySourceQuery, NormalizedItem, RawBatch } from '../types.js';

const TAG = 'AIDP';
const BOX = 'rep@internal.test';
const CONN1 = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';
const CONN2 = '3f2504e0-4f89-41d3-9a0c-0305e82c3302';
const NOW = new Date('2026-11-17T12:00:00Z');
const policy: ConsentPolicy & { Tag: string } = { Mode: 'Tagged', Tag: TAG, SweptThrough: null, WithdrawWindowDays: 30 };
const query: ActivitySourceQuery = { Mailbox: BOX, Since: null, Limit: 50 };
const daysAgo = (n: number): Date => new Date(NOW.getTime() - n * 86_400_000);

type Payload = Record<string, unknown>;

/** A provider over a recorded mailbox: the real lookup semantics, through the real base template. */
class Mailbox extends BaseActivitySyncProvider {
    public readonly ProviderTypeCode = 'Microsoft365';
    public readonly IsLive = false;
    public readonly Calls: ActivitySourceQuery[] = [];
    private readonly transport: RecordedMessageTransport;
    public constructor(
        public readonly Kind: ActivitySourceKind,
        payloads: Payload[],
        private readonly forceCapped = false,
    ) {
        super();
        this.transport = new RecordedMessageTransport([{ Mailbox: BOX, Payloads: payloads, Provenance: 'test' }]);
    }
    protected async FetchRaw(q: ActivitySourceQuery): Promise<RawBatch> {
        this.Calls.push(q);
        const raw = await this.transport.Fetch(q);
        return this.forceCapped && q.Lookup ? { ...raw, Capped: true } : raw;
    }
    protected Normalize(raw: RawBatch): NormalizedItem[] {
        return raw.Payloads.map(toItem);
    }
}

function toItem(p: Payload): NormalizedItem {
    return {
        ExternalID: String(p['id']),
        ExternalThreadID: typeof p['conversationId'] === 'string' ? p['conversationId'] : null,
        TypeCode: 'Email',
        Subject: 's',
        Body: null,
        StartedAt: NOW,
        EndedAt: null,
        Location: null,
        HasAttachments: false,
        Direction: 'Inbound',
        Participants: [],
        Cancelled: false,
        Raw: p,
    };
}

function msg(id: string, opts: { tagged?: boolean; thread?: string; modified?: string; replyTo?: string; copy?: string } = {}): Payload {
    return {
        id: `graph-${id}${opts.copy ?? ''}`,
        internetMessageId: id,
        conversationId: opts.thread ?? 'T',
        categories: opts.tagged ? [TAG] : [],
        lastModifiedDateTime: opts.modified ?? '2026-11-01T00:00:00Z',
        singleValueExtendedProperties: opts.replyTo ? [{ id: PROP_IN_REPLY_TO, value: opts.replyTo }] : [],
    };
}

interface StoredConsent extends ConsentRecord {
    ConnectionID: string;
    TypeCode: string;
    /** The Consent stage's decision: Included / Duplicate grant, Excluded ends it. */
    Decision: 'Included' | 'Duplicate' | 'Excluded';
}

/** The SQL store's meaning, in memory: each mailbox's LATEST Consent decision per message decides. */
class MemoryStore implements ConsentStore {
    public readonly Withdrawn: string[] = [];
    public constructor(private readonly rows: StoredConsent[]) {}
    private latest(connectionID: string, typeCode?: string): StoredConsent[] {
        const newest = new Map<string, StoredConsent>();
        const mine = this.rows
            .filter((r) => r.ConnectionID === connectionID && (!typeCode || r.TypeCode === typeCode))
            .sort((a, b) => b.ConsentedAt.getTime() - a.ConsentedAt.getTime());
        for (const r of mine) if (!newest.has(r.ExternalID)) newest.set(r.ExternalID, r);
        return [...newest.values()].filter((r) => r.Decision !== 'Excluded');
    }
    public async ConsentedActivities(q: ConsentQuery): Promise<StoreResult<ConsentRecord[]>> {
        const hits = this.latest(q.ConnectionID, q.TypeCode)
            .filter((r) => !q.ExternalIDs || q.ExternalIDs.includes(r.ExternalID))
            .filter((r) => !q.ConsentedSince || r.ConsentedAt.getTime() >= q.ConsentedSince.getTime());
        return { Failed: false, Value: hits.slice(0, q.MaxRows) };
    }
    public async ConsentedElsewhere(externalIDs: readonly string[], connectionID: string): Promise<StoreResult<Set<string>>> {
        const others = [...new Set(this.rows.map((r) => r.ConnectionID))].filter((c) => c !== connectionID);
        const found = new Set(others.flatMap((c) => this.latest(c).map((r) => r.ExternalID)).filter((x) => externalIDs.includes(x)));
        return { Failed: false, Value: found };
    }
    public async Withdraw(id: string): Promise<string | null> {
        this.Withdrawn.push(id);
        return null;
    }
}

let n = 0;
function consent(ExternalID: string, Reason: string, opts: { conn?: string; type?: string; at?: Date; activity?: string; details?: Payload; decision?: StoredConsent['Decision'] } = {}): StoredConsent {
    n++;
    return {
        ActivityID: opts.activity ?? `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`,
        ExternalID,
        ExternalThreadID: 'T',
        Details: opts.details ? JSON.stringify(opts.details) : null,
        Reason,
        ConsentedAt: opts.at ?? daysAgo(1),
        ConnectionID: opts.conn ?? CONN1,
        TypeCode: opts.type ?? 'Email',
        Decision: opts.decision ?? 'Included',
    };
}
const TAGGED = `Tagged "${TAG}" by the mailbox owner`;
const provenBy = (id: string): string => `Proven reply to ${id}`;
const intake = new ConsentIntake(() => NOW);

describe('Withdraw', () => {
    it('F1: a calendar pass never considers email captures (and a mail pass never looks up meetings)', async () => {
        const store = new MemoryStore([consent('<m1@x>', TAGGED), consent('ical-1', TAGGED, { type: 'Meeting' })]);
        const calendar = await intake.Withdraw(new Mailbox('Calendar', []), query, [toItem({ id: 'ical-1', iCalUId: 'ical-1', categories: [TAG] })], policy, CONN1, true, store);
        expect(calendar.Unknown).toBe(0);
        const mail = new Mailbox('Message', [msg('<m1@x>', { tagged: true })]);
        await intake.Withdraw(mail, query, [], policy, CONN1, true, store);
        const asked = mail.Calls.flatMap((c) => (c.Lookup?.Kind === 'MessageIds' ? c.Lookup.MessageIds : []));
        expect(asked).toEqual(['<m1@x>']);
    });

    it('F4: an item consented recently is re-checked whatever the date of the message itself', async () => {
        const store = new MemoryStore([consent('<old@x>', TAGGED, { at: daysAgo(1) })]);
        const res = await intake.Withdraw(new Mailbox('Message', [msg('<old@x>')]), query, [], policy, CONN1, true, store);
        expect(res.Withdrawn).toBe(1);
    });

    it('F5: a proven reply that is tagged now is kept when its parent loses the tag', async () => {
        const store = new MemoryStore([consent('<m1@x>', TAGGED), consent('<m2@x>', provenBy('<m1@x>'))]);
        const res = await intake.Withdraw(new Mailbox('Message', [msg('<m1@x>'), msg('<m2@x>', { tagged: true })]), query, [], policy, CONN1, true, store);
        expect(res.Withdrawn).toBe(1);
        expect(store.Withdrawn).toEqual([]);
    });

    it('F7: a cut-off re-read withdraws nothing', async () => {
        const store = new MemoryStore([consent('<m1@x>', TAGGED)]);
        const mailbox = new Mailbox('Message', [msg('<m1@x>', { copy: '-sent' }), msg('<m1@x>', { tagged: true })], true);
        const res = await intake.Withdraw(mailbox, query, [], policy, CONN1, false, store);
        expect(res.Withdrawn).toBe(0);
        expect(res.Issues.join(' ')).toContain('cut off');
    });

    it('F7: the tagged copy wins over an untagged copy of the same message', async () => {
        const store = new MemoryStore([consent('<m1@x>', TAGGED)]);
        const res = await intake.Withdraw(new Mailbox('Message', [msg('<m1@x>', { copy: '-sent' }), msg('<m1@x>', { tagged: true })]), query, [], policy, CONN1, false, store);
        expect(res.Withdrawn).toBe(0);
    });

    it('F8b: an activity another mailbox also consented to is kept and reported', async () => {
        const shared = '11111111-0000-4000-8000-000000000001';
        const store = new MemoryStore([consent('<m1@x>', TAGGED, { activity: shared }), consent('<m1@x>', TAGGED, { activity: shared, conn: CONN2 })]);
        const res = await intake.Withdraw(new Mailbox('Message', [msg('<m1@x>')]), query, [], policy, CONN1, false, store);
        expect(store.Withdrawn).toEqual([]);
        expect(res.Issues.join(' ')).toContain('another mailbox');
    });

    it('F8b: a mailbox whose latest decision ended its consent no longer keeps the shared activity alive', async () => {
        const shared = '11111111-0000-4000-8000-000000000002';
        const store = new MemoryStore([
            consent('<m1@x>', TAGGED, { activity: shared, conn: CONN1, at: daysAgo(3) }),
            consent('<m1@x>', 'Consent withdrawn: the tag was removed', { activity: shared, conn: CONN1, at: daysAgo(1), decision: 'Excluded' }),
            consent('<m1@x>', TAGGED, { activity: shared, conn: CONN2, at: daysAgo(2), decision: 'Duplicate' }),
        ]);
        const res = await intake.Withdraw(new Mailbox('Message', [msg('<m1@x>')]), query, [], policy, CONN2, false, store);
        expect(store.Withdrawn).toEqual([shared]);
        expect(res.Revoked.map((i) => i.ExternalID)).toEqual(['<m1@x>']);
    });

    it('F8b: consent ending is reported for the run to record, even when the row is kept for another mailbox', async () => {
        const shared = '11111111-0000-4000-8000-000000000003';
        const store = new MemoryStore([consent('<m1@x>', TAGGED, { activity: shared }), consent('<m1@x>', TAGGED, { activity: shared, conn: CONN2, decision: 'Duplicate' })]);
        const res = await intake.Withdraw(new Mailbox('Message', [msg('<m1@x>')]), query, [], policy, CONN1, false, store);
        expect(store.Withdrawn).toEqual([]);
        expect(res.Revoked.map((i) => i.ExternalID)).toEqual(['<m1@x>']);
    });

    it('F10b: a proven reply follows its own chain, not the conversation', async () => {
        const store = new MemoryStore([consent('<a@x>', TAGGED), consent('<b@x>', TAGGED), consent('<r@x>', provenBy('<a@x>'))]);
        const res = await intake.Withdraw(new Mailbox('Message', [msg('<a@x>'), msg('<b@x>', { tagged: true }), msg('<r@x>')]), query, [], policy, CONN1, true, store);
        expect(res.Withdrawn).toBe(2);
    });
});

describe('ChooseWithdrawals / ViaOf', () => {
    it('a chain of proven replies is withdrawn with its root, and an unreadable tagged item is Unknown', () => {
        const rows = [consent('<a@x>', TAGGED), consent('<r1@x>', provenBy('<a@x>')), consent('<r2@x>', provenBy('<r1@x>')), consent('<lost@x>', TAGGED)];
        const seen = new Map(['<a@x>', '<r1@x>', '<r2@x>'].map((id) => [id, toItem(msg(id))] as const));
        const chosen = ChooseWithdrawals(rows, seen, TAG);
        expect(chosen.Rows.map((r) => r.ExternalID)).toEqual(['<a@x>', '<r1@x>', '<r2@x>']);
        expect(chosen.Unknown).toBe(1);
        expect(ViaOf('Proven earlier message in the chain of <t@x>')).toBe('<t@x>');
    });
});

describe('Gather', () => {
    it('F2: a capped sweep narrows its window and never claims a window it did not read whole', async () => {
        const tagged = ['2026-11-02T00:00:00Z', '2026-11-09T00:00:00Z', '2026-11-10T00:00:00Z'].map((m, i) => msg(`<t${i}@x>`, { tagged: true, modified: m }));
        const swept = { ...policy, SweptThrough: new Date('2026-11-01T00:00:00Z') };
        const res = await intake.Gather(new Mailbox('Message', tagged), { ...query, Limit: 2 }, [], swept, CONN1, new MemoryStore([]));
        expect(res.Items.map((i) => i.ExternalID).sort()).toEqual(['<t0@x>', '<t1@x>', '<t2@x>']);
        expect(res.SweptThrough?.toISOString()).toBe(NOW.toISOString());
        expect(SWEEP_OVERLAP_MS).toBeGreaterThanOrEqual(5 * 60_000);
    });

    it('each sweep starts a margin before its recorded position, so a clock ahead of Exchange loses nothing', async () => {
        const mailbox = new Mailbox('Message', [msg('<t@x>', { tagged: true, modified: '2026-11-09T23:55:00Z' })]);
        const res = await intake.Gather(mailbox, query, [], { ...policy, SweptThrough: new Date('2026-11-10T00:00:00Z') }, CONN1, new MemoryStore([]));
        expect(res.Items.map((i) => i.ExternalID)).toEqual(['<t@x>']);
    });

    it('a first run sweeps nothing (the window read covers every message) and records the newest change it read', async () => {
        const mailbox = new Mailbox('Message', [msg('<t@x>', { tagged: true })]);
        const read = [toItem(msg('<a@x>', { modified: '2026-11-03T13:00:00Z' })), toItem(msg('<b@x>', { modified: '2026-11-02T09:00:00Z' }))];
        const res = await intake.Gather(mailbox, query, read, policy, CONN1, new MemoryStore([]));
        expect(mailbox.Calls.some((c) => c.Lookup?.Kind === 'Tagged')).toBe(false);
        expect(res.SweptThrough?.toISOString()).toBe('2026-11-03T13:00:00.000Z');
    });

    it('a first run over an empty mailbox records nothing, so the next run sweeps from its watermark', async () => {
        const res = await intake.Gather(new Mailbox('Message', []), query, [], policy, CONN1, new MemoryStore([]));
        expect(res.SweptThrough).toBeNull();
    });

    it('F2: a sweep that cannot finish keeps its position behind every unread item and says so', async () => {
        const swept = { ...policy, SweptThrough: new Date('2026-11-01T00:00:00Z') };
        const res = await intake.Gather(new Mailbox('Message', [msg('<t@x>', { tagged: true })], true), query, [], swept, CONN1, new MemoryStore([]));
        expect(res.SweptThrough).toBeNull();
        expect(res.Issues.join(' ')).toContain('did not reach the present');
    });

    it('F2b: the stored sweep position never moves backwards', () => {
        const stored = JSON.stringify({ Consent: { Mode: 'Tagged', SweptThrough: '2026-11-10T00:00:00.000Z' } });
        expect(JSON.parse(MergeConsentSweptThrough(stored, new Date('2026-11-01T00:00:00Z'))).Consent.SweptThrough).toBe('2026-11-10T00:00:00.000Z');
    });

    it('F12: a late tag on a thread root brings in the replies already behind the watermark', async () => {
        const mailbox = new Mailbox('Message', [msg('<m1@x>', { tagged: true, modified: '2026-11-10T00:00:00Z' }), msg('<m2@x>', { replyTo: '<m1@x>' })]);
        const res = await intake.Gather(mailbox, { ...query, Since: new Date('2026-11-05T00:00:00Z') }, [], policy, CONN1, new MemoryStore([]));
        expect(res.Items.map((i) => i.ExternalID).sort()).toEqual(['<m1@x>', '<m2@x>']);
    });

    it('F8a / F10a: prior consent is this connection\'s, found by the Message-IDs the batch names', async () => {
        const store = new MemoryStore([consent('<root@x>', TAGGED, { conn: CONN2 }), consent('<other@x>', TAGGED, { conn: CONN1 })]);
        const reply = msg('<r@x>', { replyTo: '<root@x>', thread: 'a-different-conversation' });
        const res = await intake.Gather(new Mailbox('Message', []), query, [toItem(reply)], policy, CONN2, store);
        expect([...res.Prior.keys()]).toEqual(['<root@x>']);
    });

    it('F13: a stored payload with only `sender` still names its sender', () => {
        expect(ParticipantsFromDetails(JSON.stringify({ sender: { emailAddress: { address: 'Sender@Cust.test' } } }))).toEqual(['sender@cust.test']);
    });
});
