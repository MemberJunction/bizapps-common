/**
 * Standing consent: capture without a tag, because an external participant's domain belongs to an
 * account a named source says the mailbox owner owns.
 *
 * The failures worth pinning are the ones that capture what nobody consented to: a free-mail domain on
 * an account, the deployment's own domain, an item marked Private, mail whose Private mark could not be
 * read at all (MJ 6.2.1 returns no extended properties), and an item the owner said never to log.
 */
import { describe, expect, it } from 'vitest';

import { StandingGrantDomains } from '../BaseActivityConsentSource.js';
import { ConsentPolicyFromSettings, PreferTaggedCopy, PROP_IN_REPLY_TO, PROP_MESSAGE_CLASS, PROP_SENSITIVITY, ResolveConsent, type ConsentGrant, type StandingDomains } from '../consent.js';
import { ChooseWithdrawals } from '../consent-intake.js';
import { ConsentEligible, ConsentStages, type ConsentQualificationContext } from '../consent-stages.js';
import type { ConsentRecord } from '../consent-store.js';
import { RunQualificationCascade } from '../qualification.js';
import type { RuleRow } from '../stages.js';
import type { ActivitySourceKind, ItemParticipant, NormalizedItem } from '../types.js';

const BOX = 'rep@internal.test';
const BUYER = 'buyer@acme.test';
const TAG = 'AIDP';
const SKIP = 'No AIDP';
const OWNED: StandingDomains = new Map([['acme.test', 'Acme Corp']]);

function who(address: string, role: ItemParticipant['Role']): ItemParticipant {
    return { Address: address, Name: null, Role: role, IdentityKind: 'Email' };
}

interface MailSpec {
    id: string;
    from: string;
    to: string[];
    tags?: string[];
    replyTo?: string;
    at?: string;
    /** `null` = the provider returned no extended properties at all (MJ 6.2.1). */
    props?: Array<{ id: string; value: string }> | null;
}

function mail(spec: MailSpec): NormalizedItem {
    const raw: Record<string, unknown> = { id: `graph-${spec.id}`, internetMessageId: `<${spec.id}@x>`, subject: 'Quote', categories: spec.tags ?? [] };
    if (spec.props !== null) {
        const given = spec.props ?? [];
        const props = given.some((g) => g.id === PROP_MESSAGE_CLASS) ? [...given] : [{ id: PROP_MESSAGE_CLASS, value: 'IPM.Note' }, ...given];
        if (spec.replyTo) props.push({ id: PROP_IN_REPLY_TO, value: spec.replyTo });
        raw['singleValueExtendedProperties'] = props;
    }
    return {
        ExternalID: `<${spec.id}@x>`,
        ExternalThreadID: 'conv-1',
        TypeCode: 'Email',
        Subject: 'Quote',
        Body: null,
        StartedAt: new Date(spec.at ?? '2026-11-10T09:00:00Z'),
        EndedAt: null,
        Location: null,
        HasAttachments: false,
        Direction: spec.from === BOX ? 'Outbound' : 'Inbound',
        Participants: [who(spec.from, 'From'), ...spec.to.map((t) => who(t, 'To'))],
        Cancelled: false,
        Raw: raw,
    };
}

function meeting(id: string, attendee: string, extra: Record<string, unknown> = {}): NormalizedItem {
    return {
        ...mail({ id, from: BOX, to: [attendee], props: null }),
        ExternalID: `ical-${id}`,
        TypeCode: 'Meeting',
        Raw: { id: `graph-${id}`, iCalUId: `ical-${id}`, categories: [], sensitivity: 'normal', ...extra },
    };
}

function ctx(grants: ReadonlyMap<string, ConsentGrant>, kind: ActivitySourceKind = 'Message', rules: RuleRow[] = []): ConsentQualificationContext {
    return {
        ConnectionID: 'c',
        ProviderTypeCode: 'Microsoft365',
        Exclusions: [],
        Rules: rules,
        InternalDomains: ['internal.test'],
        KnownAddresses: new Map(),
        Consent: grants,
        Kind: kind,
        Tag: TAG,
        SkipTag: SKIP,
    };
}

async function decide(items: NormalizedItem[], target: NormalizedItem, kind: ActivitySourceKind = 'Message', standing: StandingDomains = OWNED) {
    const eligible = await ConsentEligible(items, ctx(new Map(), kind));
    const grants = ResolveConsent(items, new Map(), TAG, kind, eligible, standing);
    return RunQualificationCascade(ConsentStages(), target, ctx(grants, kind), 'Exclude');
}

describe('Settings.Consent.Sources and SkipTag', () => {
    it('reads Sources and SkipTag from a Tagged block', () => {
        const read = ConsentPolicyFromSettings('{"Consent":{"Mode":"Tagged","Tag":"AIDP","SkipTag":" No AIDP ","Sources":["Sales.OwnedAccounts"]}}');
        expect(read.Policy).toMatchObject({ Mode: 'Tagged', Tag: 'AIDP', SkipTag: 'No AIDP', Sources: ['Sales.OwnedAccounts'] });
    });

    it('a block without them is exactly the Tagged policy of before: no sources, no skip tag', () => {
        expect(ConsentPolicyFromSettings('{"Consent":{"Mode":"Tagged"}}').Policy).toMatchObject({ SkipTag: null, Sources: [] });
        expect(ConsentPolicyFromSettings(null).Policy).toMatchObject({ Mode: 'KnownContact', SkipTag: null, Sources: [] });
    });

    it.each([
        ['Sources that is not a list', '{"Consent":{"Mode":"Tagged","Sources":"Sales.OwnedAccounts"}}'],
        ['a blank source key', '{"Consent":{"Mode":"Tagged","Sources":["  "]}}'],
        ['a source key that is not text', '{"Consent":{"Mode":"Tagged","Sources":[7]}}'],
        ['Sources on a KnownContact connection', '{"Consent":{"Mode":"KnownContact","Sources":["Sales.OwnedAccounts"]}}'],
        ['a blank skip tag', '{"Consent":{"Mode":"Tagged","SkipTag":" "}}'],
        ['a skip tag that is not text', '{"Consent":{"Mode":"Tagged","SkipTag":true}}'],
        ['a skip tag equal to the tag', '{"Consent":{"Mode":"Tagged","Tag":"AIDP","SkipTag":"aidp"}}'],
    ])('fails closed on %s', (_label, settings) => {
        const read = ConsentPolicyFromSettings(settings);
        expect(read.Policy).toBeUndefined();
        expect(read.Error).toBeTruthy();
    });
});

describe('StandingGrantDomains: what a source may grant', () => {
    it('normalises domains and keeps the label', () => {
        const cleaned = StandingGrantDomains([{ Domain: ' @ACME.test ', Label: 'Acme Corp' }], ['internal.test']);
        expect([...cleaned.Granting]).toEqual([['acme.test', 'Acme Corp']]);
        expect(cleaned.Issues).toEqual([]);
    });

    it('drops a free-mail domain and says which account carried it', () => {
        const cleaned = StandingGrantDomains([{ Domain: 'gmail.com', Label: 'Jo Sole Trader' }, { Domain: 'acme.test', Label: 'Acme Corp' }], []);
        expect([...cleaned.Granting.keys()]).toEqual(['acme.test']);
        expect(cleaned.Issues.join(' ')).toMatch(/gmail\.com.*Jo Sole Trader/);
    });

    it('drops the deployment\'s own domains: our own company as an account must not capture internal mail', () => {
        const cleaned = StandingGrantDomains([{ Domain: 'Internal.test', Label: 'Us' }], ['internal.test']);
        expect(cleaned.Granting.size).toBe(0);
        expect(cleaned.Issues.join(' ')).toMatch(/internal\.test/);
    });

    it('drops what is not a domain at all', () => {
        const cleaned = StandingGrantDomains([{ Domain: '', Label: 'Blank' }, { Domain: 'buyer@acme.test', Label: 'An address' }, { Domain: 'localhost', Label: 'No dot' }], []);
        expect(cleaned.Granting.size).toBe(0);
        expect(cleaned.Issues).toHaveLength(3);
    });

    it('two accounts on one domain grant once, and the reason names both', () => {
        const cleaned = StandingGrantDomains([{ Domain: 'acme.test', Label: 'Acme US' }, { Domain: 'acme.test', Label: 'Acme EU' }], []);
        expect([...cleaned.Granting]).toEqual([['acme.test', 'Acme US; Acme EU']]);
    });
});

describe('ResolveConsent with standing domains', () => {
    it('grants an untagged mail with an external participant on an owned-account domain', () => {
        const m = mail({ id: 'm1', from: BUYER, to: [BOX] });
        expect(ResolveConsent([m], new Map(), TAG, 'Message', undefined, OWNED).get(m.ExternalID)).toEqual({ Kind: 'Standing', Domain: 'acme.test', Label: 'Acme Corp' });
    });

    it('grants a meeting the same way', () => {
        const e = meeting('e1', BUYER);
        expect(ResolveConsent([e], new Map(), TAG, 'Calendar', undefined, OWNED).get(e.ExternalID)?.Kind).toBe('Standing');
    });

    it('grants nothing for a domain no source listed (a school, a doctor)', () => {
        const m = mail({ id: 'm1', from: 'office@school.test', to: [BOX] });
        expect(ResolveConsent([m], new Map(), TAG, 'Message', undefined, OWNED).size).toBe(0);
    });

    it('a subdomain of an owned domain is not that domain', () => {
        const m = mail({ id: 'm1', from: 'bot@mail.acme.test', to: [BOX] });
        expect(ResolveConsent([m], new Map(), TAG, 'Message', undefined, OWNED).size).toBe(0);
    });

    it('the owner\'s tag is still the tag: it is recorded as Tag, not Standing', () => {
        const m = mail({ id: 'm1', from: BUYER, to: [BOX], tags: [TAG] });
        expect(ResolveConsent([m], new Map(), TAG, 'Message', undefined, OWNED).get(m.ExternalID)).toEqual({ Kind: 'Tag' });
    });

    it('without standing domains nothing changes', () => {
        const m = mail({ id: 'm1', from: BUYER, to: [BOX] });
        expect(ResolveConsent([m], new Map(), TAG, 'Message').size).toBe(0);
    });

    it('a reply to a standing capture is proven by it, even from a new address', () => {
        const first = mail({ id: 'm1', from: BOX, to: [BUYER] });
        const reply = mail({ id: 'm2', from: 'buyer.phone@elsewhere.test', to: [BOX], replyTo: '<m1@x>', at: '2026-11-10T10:00:00Z' });
        expect(ResolveConsent([first, reply], new Map(), TAG, 'Message', undefined, OWNED).get(reply.ExternalID)).toEqual({ Kind: 'Reply', Via: '<m1@x>' });
    });

    it('a Private standing item proves no reply', () => {
        const first = mail({ id: 'm1', from: BOX, to: [BUYER], props: [{ id: PROP_SENSITIVITY, value: '2' }] });
        const reply = mail({ id: 'm2', from: 'buyer.phone@elsewhere.test', to: [BOX], replyTo: '<m1@x>', at: '2026-11-10T10:00:00Z' });
        expect(ResolveConsent([first, reply], new Map(), TAG, 'Message', undefined, OWNED).has(reply.ExternalID)).toBe(false);
    });
});

describe('The Consent stage with a standing grant', () => {
    it('captures, and the reason names the domain and the account', async () => {
        const m = mail({ id: 'm1', from: BUYER, to: [BOX] });
        const verdict = await decide([m], m);
        expect(verdict).toMatchObject({ Decision: 'Include', StageName: 'Consent', Reason: 'Standing consent: acme.test (Acme Corp)' });
    });

    it('does not capture a mail marked Private; only the owner\'s tag overrides that', async () => {
        const priv = mail({ id: 'm1', from: BUYER, to: [BOX], props: [{ id: PROP_SENSITIVITY, value: '2' }] });
        const verdict = await decide([priv], priv);
        expect(verdict.Decision).toBe('Exclude');
        expect(verdict.Reason).toMatch(/acme\.test.*Personal\/Private\/Confidential/);
        const tagged = mail({ id: 'm2', from: BUYER, to: [BOX], tags: [TAG], props: [{ id: PROP_SENSITIVITY, value: '2' }] });
        expect((await decide([tagged], tagged)).Decision).toBe('Include');
    });

    it('does not capture a Private meeting', async () => {
        const e = meeting('e1', BUYER, { sensitivity: 'private' });
        expect((await decide([e], e, 'Calendar')).Decision).toBe('Exclude');
    });

    it('MJ 6.2.1: mail that came back with no extended properties is not captured, because its Private mark is unknown', async () => {
        const m = mail({ id: 'm1', from: BUYER, to: [BOX], props: null });
        const verdict = await decide([m], m);
        expect(verdict.Decision).toBe('Exclude');
        expect(verdict.Reason).toMatch(/acme\.test.*could not be read/);
    });

    it('MJ 6.2.1: the tag still captures such mail, and a meeting needs no extended properties', async () => {
        const tagged = mail({ id: 'm1', from: BUYER, to: [BOX], tags: [TAG], props: null });
        expect((await decide([tagged], tagged)).Decision).toBe('Include');
        const e = meeting('e1', BUYER);
        expect((await decide([e], e, 'Calendar')).Reason).toBe('Standing consent: acme.test (Acme Corp)');
    });

    it('an automatic reply from an owned-account domain is still blocked', async () => {
        const oof = mail({ id: 'm1', from: BUYER, to: [BOX], props: [{ id: PROP_MESSAGE_CLASS, value: 'IPM.Note.Rules.OofTemplate.Microsoft' }] });
        expect(await decide([oof], oof)).toMatchObject({ Decision: 'Exclude', StageName: 'ConsentBlock' });
    });

    it('an Exclude rule still wins over a standing grant', async () => {
        const m = mail({ id: 'm1', from: BUYER, to: [BOX] });
        const rule: RuleRow = { ID: 'r1', Sequence: 1, IsEnabled: true, Action: 'Exclude', Direction: null, DateFrom: null, DateTo: null, ParticipantScope: 'Any', ActivitySyncRuleSetID: null, IncludeAttachments: false, MaxAttachmentBytes: null };
        const grants = ResolveConsent([m], new Map(), TAG, 'Message', undefined, OWNED);
        expect(await RunQualificationCascade(ConsentStages(), m, ctx(grants, 'Message', [rule]), 'Exclude')).toMatchObject({ Decision: 'Exclude', StageName: 'Rules' });
    });
});

describe('A meeting whose sensitivity was not returned', () => {
    // Graph sends `sensitivity` on every event, so a payload without it is one where the mark could not
    // be read (a transport that trimmed the fields, say). Same rule as mail: unreadable is not "normal".
    it('is not captured by a standing grant', async () => {
        const e = meeting('e1', BUYER, { sensitivity: undefined });
        const verdict = await decide([e], e, 'Calendar');
        expect(verdict.Decision).toBe('Exclude');
        expect(verdict.Reason).toMatch(/acme\.test.*could not be read/);
    });

    it('is still captured when the owner tagged it', async () => {
        const e = meeting('e1', BUYER, { sensitivity: undefined, categories: [TAG] });
        expect((await decide([e], e, 'Calendar')).Decision).toBe('Include');
    });
});

describe('SkipTag: the owner said never to log this', () => {
    it('blocks an item on an owned-account domain', async () => {
        const m = mail({ id: 'm1', from: BUYER, to: [BOX], tags: ['no aidp'] });
        expect(await decide([m], m)).toMatchObject({ Decision: 'Exclude', StageName: 'ConsentBlock' });
    });

    it('wins over the tag on the same item', async () => {
        const m = mail({ id: 'm1', from: BUYER, to: [BOX], tags: [TAG, SKIP] });
        expect((await decide([m], m)).Decision).toBe('Exclude');
    });

    it('blocks a meeting too', async () => {
        const e = meeting('e1', BUYER, { categories: [SKIP] });
        expect(await decide([e], e, 'Calendar')).toMatchObject({ Decision: 'Exclude', StageName: 'ConsentBlock' });
    });

    it('one message, two copies: the copy carrying the skip tag decides, whichever is read first', () => {
        const inbox = mail({ id: 'm1', from: BUYER, to: [BOX], tags: [TAG] });
        const sent = mail({ id: 'm1', from: BUYER, to: [BOX], tags: [SKIP] });
        expect(PreferTaggedCopy(inbox, sent, TAG, SKIP)).toBe(sent);
        expect(PreferTaggedCopy(sent, inbox, TAG, SKIP)).toBe(sent);
        expect(PreferTaggedCopy(sent, inbox, TAG)).toBe(inbox);
    });

    it('a skip-tagged item proves no reply', async () => {
        const first = mail({ id: 'm1', from: BOX, to: [BUYER], tags: [SKIP] });
        const reply = mail({ id: 'm2', from: 'buyer.phone@elsewhere.test', to: [BOX], replyTo: '<m1@x>', at: '2026-11-10T10:00:00Z' });
        expect((await decide([first, reply], reply)).Decision).toBe('Exclude');
    });
});

describe('ChooseWithdrawals with standing captures and a skip tag', () => {
    const record = (id: string, reason: string): ConsentRecord => ({
        ActivityID: `act-${id}`, ExternalID: `<${id}@x>`, ExternalThreadID: 'conv-1', Details: null, Reason: reason, ConsentedAt: new Date('2026-11-10T09:00:00Z'),
    });
    const STANDING = 'Standing consent: acme.test (Acme Corp)';
    const seenOf = (...items: NormalizedItem[]) => new Map(items.map((i) => [i.ExternalID, i] as const));
    const ids = (rows: ConsentRecord[]) => rows.map((r) => r.ExternalID);

    it('a standing capture that was read, untagged, is kept: it never needed a tag', () => {
        const chosen = ChooseWithdrawals([record('m1', STANDING)], seenOf(mail({ id: 'm1', from: BUYER, to: [BOX] })), TAG, { SkipTag: SKIP, Standing: new Map() });
        expect(chosen).toEqual({ Rows: [], Unknown: 0 });
    });

    it('a standing capture that could not be read is kept and is not an unknown tagged item', () => {
        expect(ChooseWithdrawals([record('m1', STANDING)], new Map(), TAG, { SkipTag: SKIP, Standing: new Map() })).toEqual({ Rows: [], Unknown: 0 });
    });

    it('a standing capture now carrying the skip tag is withdrawn, with the replies it proved', () => {
        const candidates = [record('m1', STANDING), record('m2', 'Proven reply to <m1@x>')];
        const seen = seenOf(mail({ id: 'm1', from: BUYER, to: [BOX], tags: [SKIP] }), mail({ id: 'm2', from: 'buyer.phone@elsewhere.test', to: [BOX] }));
        expect(ids(ChooseWithdrawals(candidates, seen, TAG, { SkipTag: SKIP, Standing: OWNED }).Rows)).toEqual(['<m1@x>', '<m2@x>']);
    });

    it('the skip tag is per item: another message on the owned-account domain keeps its own standing consent', () => {
        const candidates = [record('m1', STANDING), record('m2', STANDING)];
        const seen = seenOf(mail({ id: 'm1', from: BUYER, to: [BOX], tags: [SKIP] }), mail({ id: 'm2', from: BUYER, to: [BOX] }));
        expect(ids(ChooseWithdrawals(candidates, seen, TAG, { SkipTag: SKIP, Standing: OWNED }).Rows)).toEqual(['<m1@x>']);
    });

    it('a tagged capture that now also carries the skip tag is withdrawn', () => {
        const seen = seenOf(mail({ id: 'm1', from: 'pat@other.test', to: [BOX], tags: [TAG, SKIP] }));
        expect(ids(ChooseWithdrawals([record('m1', `Tagged "${TAG}" by the mailbox owner`)], seen, TAG, { SkipTag: SKIP, Standing: new Map() }).Rows)).toEqual(['<m1@x>']);
    });

    it('removing the tag from an item on an owned-account domain does not withdraw it: standing consent still holds', () => {
        const seen = seenOf(mail({ id: 'm1', from: BUYER, to: [BOX] }));
        expect(ChooseWithdrawals([record('m1', `Tagged "${TAG}" by the mailbox owner`)], seen, TAG, { SkipTag: SKIP, Standing: OWNED }).Rows).toEqual([]);
    });

    it('removing the tag from any other item still withdraws it', () => {
        const seen = seenOf(mail({ id: 'm1', from: 'pat@other.test', to: [BOX] }));
        expect(ids(ChooseWithdrawals([record('m1', `Tagged "${TAG}" by the mailbox owner`)], seen, TAG, { SkipTag: SKIP, Standing: OWNED }).Rows)).toEqual(['<m1@x>']);
    });

    it('with no options it decides exactly as before', () => {
        const seen = seenOf(mail({ id: 'm1', from: BUYER, to: [BOX] }));
        expect(ids(ChooseWithdrawals([record('m1', `Tagged "${TAG}" by the mailbox owner`)], seen, TAG).Rows)).toEqual(['<m1@x>']);
    });
});
