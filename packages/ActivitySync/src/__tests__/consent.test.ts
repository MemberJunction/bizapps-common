/**
 * Consent: the Tagged mode's rules, each pinned against the failure it exists to prevent.
 *
 * The dangerous failures are the ones that capture without consent: a mistyped Settings block that
 * falls back to the broadest mode, a conversationId treated as proof, a forward or an outbound reply
 * to a new person riding a tagged thread, a meeting invite filed as mail, an automatic reply.
 */
import { describe, expect, it } from 'vitest';

import {
    BlockReason,
    ConsentPolicyFromSettings,
    ContinuesThread,
    HasTag,
    IsSensitive,
    MergeConsentSweptThrough,
    PROP_IN_REPLY_TO,
    PROP_MESSAGE_CLASS,
    PROP_REFERENCES,
    PROP_SENSITIVITY,
    ReplyReferences,
    ResolveConsent,
    SameExtendedPropertyId,
    StableExternalId,
    ExtendedProperty,
    type ConsentedMessage,
} from '../consent.js';
import { ConsentStages, REASON_UNTAGGED, REASON_UNTAGGED_KNOWN, type ConsentQualificationContext } from '../consent-stages.js';
import { RunQualificationCascade } from '../qualification.js';
import type { ItemParticipant, NormalizedItem } from '../types.js';

const BOX = 'rep@internal.test';
const CUSTOMER = 'nora@customer.test';

function who(address: string, role: ItemParticipant['Role']): ItemParticipant {
    return { Address: address, Name: null, Role: role, IdentityKind: 'Email' };
}

interface MailSpec {
    id: string;
    from: string;
    to: string[];
    tags?: string[];
    replyTo?: string;
    references?: string[];
    subject?: string;
    at?: string;
    extra?: Record<string, unknown>;
    props?: Array<{ id: string; value: string }>;
}

function mail(spec: MailSpec): NormalizedItem {
    const props = [...(spec.props ?? [])];
    if (spec.replyTo) props.push({ id: PROP_IN_REPLY_TO, value: spec.replyTo });
    if (spec.references) props.push({ id: PROP_REFERENCES, value: spec.references.join(' ') });
    const participants = [who(spec.from, 'From'), ...spec.to.map((t) => who(t, 'To'))];
    return {
        ExternalID: `<${spec.id}@x>`,
        ExternalThreadID: 'conv-1',
        TypeCode: 'Email',
        Subject: spec.subject ?? 'Quote',
        Body: null,
        StartedAt: new Date(spec.at ?? '2026-11-10T09:00:00Z'),
        EndedAt: null,
        Location: null,
        HasAttachments: false,
        Direction: spec.from === BOX ? 'Outbound' : 'Inbound',
        Participants: participants,
        Cancelled: false,
        Raw: {
            id: `graph-${spec.id}`,
            internetMessageId: `<${spec.id}@x>`,
            subject: spec.subject ?? 'Quote',
            categories: spec.tags ?? [],
            singleValueExtendedProperties: props,
            ...spec.extra,
        },
    };
}

describe('ConsentPolicyFromSettings', () => {
    it('no Consent block means KnownContact, the behaviour before this existed', () => {
        expect(ConsentPolicyFromSettings(null).Policy?.Mode).toBe('KnownContact');
        expect(ConsentPolicyFromSettings('{"StoreBody":"Full"}').Policy?.Mode).toBe('KnownContact');
    });

    it('reads a Tagged block, defaulting the tag to AIDP', () => {
        const read = ConsentPolicyFromSettings('{"Consent":{"Mode":"Tagged"}}');
        expect(read.Policy).toMatchObject({ Mode: 'Tagged', Tag: 'AIDP', WithdrawWindowDays: 30 });
    });

    it.each([
        ['not JSON', '{ nope'],
        ['an array', '[]'],
        ['an unknown mode', '{"Consent":{"Mode":"Tagd"}}'],
        ['a blank tag', '{"Consent":{"Mode":"Tagged","Tag":"  "}}'],
        ['a non-object block', '{"Consent":"Tagged"}'],
        ['a bad window', '{"Consent":{"Mode":"Tagged","WithdrawWindowDays":-1}}'],
    ])('fails closed on %s instead of falling back to KnownContact', (_label, settings) => {
        const read = ConsentPolicyFromSettings(settings);
        expect(read.Policy).toBeUndefined();
        expect(read.Error).toBeTruthy();
    });

    it('MergeConsentSweptThrough keeps every other key', () => {
        const merged = JSON.parse(MergeConsentSweptThrough('{"StoreBody":"Full","Consent":{"Mode":"Tagged"}}', new Date('2026-11-10T00:00:00Z')));
        expect(merged).toEqual({ StoreBody: 'Full', Consent: { Mode: 'Tagged', SweptThrough: '2026-11-10T00:00:00.000Z' } });
    });
});

describe('Graph signals', () => {
    it('reads properties under the ids Graph actually returns (0x36, 0x1a), not only the ids requested', () => {
        // Verbatim from an Exchange Online response, 2026-11-17.
        const live = { singleValueExtendedProperties: [{ id: 'Integer 0x36', value: '2' }, { id: 'String 0x1a', value: 'IPM.Note.Rules.OofTemplate.Microsoft' }] };
        expect(ExtendedProperty(live, PROP_SENSITIVITY)).toBe('2');
        expect(IsSensitive(live, 'Message')).toBe(true);
        expect(BlockReason(live, 'Message')).toBe('an automatic reply');
        expect(SameExtendedPropertyId('String 0x1042', 'string 0X1042')).toBe(true);
        expect(SameExtendedPropertyId('Integer 0x36', 'String 0x36')).toBe(false);
    });

    it('HasTag is case- and space-insensitive and ignores other categories', () => {
        expect(HasTag({ categories: ['Personal', ' aidp '] }, 'AIDP')).toBe(true);
        expect(HasTag({ categories: ['Personal'] }, 'AIDP')).toBe(false);
        expect(HasTag({}, 'AIDP')).toBe(false);
    });

    it('ReplyReferences reads In-Reply-To and References, deduplicated', () => {
        const raw = mail({ id: 'b', from: CUSTOMER, to: [BOX], replyTo: '<a@x>', references: ['<root@x>', '<a@x>'] }).Raw;
        expect(ReplyReferences(raw)).toEqual(['<a@x>', '<root@x>']);
    });

    it.each([
        ['a draft', { isDraft: true }],
        ['a meeting invitation', { '@odata.type': '#microsoft.graph.eventMessageRequest' }],
        ['an out-of-office reply', { singleValueExtendedProperties: [{ id: PROP_MESSAGE_CLASS, value: 'IPM.Note.Rules.OofTemplate.Microsoft' }] }],
    ])('BlockReason blocks %s', (_label, raw) => {
        expect(BlockReason(raw, 'Message')).toBeTruthy();
    });

    it('BlockReason passes ordinary mail and never blocks a calendar item', () => {
        expect(BlockReason({ isDraft: false }, 'Message')).toBeNull();
        expect(BlockReason({ isDraft: true }, 'Calendar')).toBeNull();
    });

    it('IsSensitive reads event sensitivity and mail PidTagSensitivity', () => {
        expect(IsSensitive({ sensitivity: 'private' }, 'Calendar')).toBe(true);
        expect(IsSensitive({ sensitivity: 'normal' }, 'Calendar')).toBe(false);
        expect(IsSensitive({ singleValueExtendedProperties: [{ id: PROP_SENSITIVITY, value: '2' }] }, 'Message')).toBe(true);
        expect(IsSensitive({ singleValueExtendedProperties: [{ id: PROP_SENSITIVITY, value: '0' }] }, 'Message')).toBe(false);
    });

    it('StableExternalId prefers Message-ID / iCalUId over the per-mailbox Graph id', () => {
        const m = mail({ id: 'a', from: BOX, to: [CUSTOMER] });
        expect(StableExternalId({ ...m, ExternalID: 'graph-a' }, 'Message')).toBe('<a@x>');
        expect(StableExternalId({ ...m, ExternalID: 'graph-e', Raw: { iCalUId: 'ical-1' } }, 'Calendar')).toBe('ical-1');
        expect(StableExternalId({ ...m, ExternalID: 'graph-e', Raw: {} }, 'Calendar')).toBe('graph-e');
    });
});

describe('ResolveConsent', () => {
    const quote = mail({ id: 'q', from: BOX, to: [CUSTOMER], tags: ['AIDP'] });

    it('grants the tagged item and a proven reply to it', () => {
        const reply = mail({ id: 'r', from: CUSTOMER, to: [BOX], replyTo: '<q@x>', at: '2026-11-10T10:00:00Z' });
        const grants = ResolveConsent([quote, reply], new Map(), 'AIDP', 'Message');
        expect(grants.get('<q@x>')).toEqual({ Kind: 'Tag' });
        expect(grants.get('<r@x>')).toEqual({ Kind: 'Reply', Via: '<q@x>' });
    });

    it('a reply from the customer\'s personal Gmail is still proven (inbound may come from a new address)', () => {
        const fromPhone = mail({ id: 'g', from: 'nora.home@gmail.test', to: [BOX], replyTo: '<q@x>' });
        expect(ResolveConsent([quote, fromPhone], new Map(), 'AIDP', 'Message').get('<g@x>')?.Kind).toBe('Reply');
    });

    it('a shared conversationId alone proves nothing', () => {
        const sameThread = mail({ id: 'lunch', from: CUSTOMER, to: [BOX], subject: 'Re: Lunch' });
        expect(ResolveConsent([quote, sameThread], new Map(), 'AIDP', 'Message').has('<lunch@x>')).toBe(false);
    });

    it('a chain of replies settles in rounds, whatever order they arrive in', () => {
        const r2 = mail({ id: 'r2', from: BOX, to: [CUSTOMER], replyTo: '<r1@x>', at: '2026-11-10T11:00:00Z' });
        const r1 = mail({ id: 'r1', from: CUSTOMER, to: [BOX], replyTo: '<q@x>', at: '2026-11-10T10:00:00Z' });
        const grants = ResolveConsent([r2, quote, r1], new Map(), 'AIDP', 'Message');
        expect(grants.get('<r2@x>')).toEqual({ Kind: 'Reply', Via: '<r1@x>' });
    });

    it('tagging a reply captures the earlier messages it names in References', () => {
        const original = mail({ id: 'o', from: BOX, to: [CUSTOMER] });
        const taggedReply = mail({ id: 't', from: CUSTOMER, to: [BOX], tags: ['AIDP'], replyTo: '<o@x>', references: ['<o@x>'] });
        expect(ResolveConsent([original, taggedReply], new Map(), 'AIDP', 'Message').get('<o@x>')).toEqual({ Kind: 'Ancestor', Via: '<t@x>' });
    });

    it('a reply proven by an earlier run\'s capture', () => {
        const prior = new Map<string, ConsentedMessage>([['<q@x>', { MessageId: '<q@x>', Participants: [BOX, CUSTOMER] }]]);
        const reply = mail({ id: 'r', from: BOX, to: [CUSTOMER], replyTo: '<q@x>' });
        expect(ResolveConsent([reply], prior, 'AIDP', 'Message').get('<r@x>')?.Kind).toBe('Reply');
    });

    it('calendar consent is the tag alone', () => {
        const event = { ...quote, Raw: { ...quote.Raw, categories: [] } };
        expect(ResolveConsent([event], new Map(), 'AIDP', 'Calendar').size).toBe(0);
    });
});

describe('ContinuesThread', () => {
    const parent: ConsentedMessage = { MessageId: '<q@x>', Participants: [BOX, CUSTOMER] };

    it('refuses a forward', () => {
        expect(ContinuesThread(mail({ id: 'f', from: BOX, to: [CUSTOMER], subject: 'FW: Quote' }), parent)).toBe(false);
    });

    it('refuses an outbound reply that adds a recipient', () => {
        expect(ContinuesThread(mail({ id: 'x', from: BOX, to: [CUSTOMER, 'recruiter@else.test'] }), parent)).toBe(false);
    });

    it('accepts an outbound reply to the same people', () => {
        expect(ContinuesThread(mail({ id: 'y', from: BOX, to: [CUSTOMER] }), parent)).toBe(true);
    });
});

describe('ConsentStages', () => {
    function ctx(grants: ConsentQualificationContext['Consent'], known: string[] = []): ConsentQualificationContext {
        return {
            ConnectionID: 'c',
            ProviderTypeCode: 'Microsoft365',
            Exclusions: [],
            Rules: [],
            InternalDomains: ['internal.test'],
            KnownAddresses: new Map(known.map((a) => [a, { Address: a }])),
            Consent: grants,
            Kind: 'Message',
            Tag: 'AIDP',
        };
    }

    it('an untagged mail to a known contact is excluded, and says a known contact was on it', async () => {
        const friend = mail({ id: 'dinner', from: BOX, to: [CUSTOMER], subject: 'Dinner Saturday?' });
        const verdict = await RunQualificationCascade(ConsentStages(), friend, ctx(new Map(), [CUSTOMER]), 'Exclude');
        expect(verdict).toMatchObject({ Decision: 'Exclude', StageName: 'Consent', Reason: REASON_UNTAGGED_KNOWN });
    });

    it('an untagged mail to nobody we know is excluded as plainly untagged', async () => {
        const verdict = await RunQualificationCascade(ConsentStages(), mail({ id: 'z', from: BOX, to: ['a@b.test'] }), ctx(new Map()), 'Exclude');
        expect(verdict.Reason).toBe(REASON_UNTAGGED);
    });

    it('a tagged draft is still blocked', async () => {
        const draft = mail({ id: 'd', from: BOX, to: [CUSTOMER], tags: ['AIDP'], extra: { isDraft: true } });
        const verdict = await RunQualificationCascade(ConsentStages(), draft, ctx(new Map([['<d@x>', { Kind: 'Tag' }]])), 'Exclude');
        expect(verdict).toMatchObject({ Decision: 'Exclude', StageName: 'ConsentBlock' });
    });

    it('a proven reply marked Private is excluded; a tagged Private one is the owner\'s call', async () => {
        const privateProps = [{ id: PROP_SENSITIVITY, value: '2' }];
        const reply = mail({ id: 'p', from: CUSTOMER, to: [BOX], replyTo: '<q@x>', props: privateProps });
        const asReply = await RunQualificationCascade(ConsentStages(), reply, ctx(new Map([['<p@x>', { Kind: 'Reply', Via: '<q@x>' }]])), 'Exclude');
        expect(asReply.Decision).toBe('Exclude');
        const asTag = await RunQualificationCascade(ConsentStages(), reply, ctx(new Map([['<p@x>', { Kind: 'Tag' }]])), 'Exclude');
        expect(asTag.Decision).toBe('Include');
    });

    it('an internal-only Exclude rule still wins over a tag', async () => {
        const internal = mail({ id: 'i', from: BOX, to: ['colleague@internal.test'], tags: ['AIDP'] });
        const context = ctx(new Map([['<i@x>', { Kind: 'Tag' }]]));
        context.Rules = [
            { ID: 'r1', Sequence: 1, IsEnabled: true, Action: 'Exclude', Direction: null, DateFrom: null, DateTo: null, ParticipantScope: 'AllInternal', ActivitySyncRuleSetID: null, IncludeAttachments: false, MaxAttachmentBytes: null },
        ];
        expect((await RunQualificationCascade(ConsentStages(), internal, context, 'Exclude')).StageName).toBe('Rules');
    });

    it('an Include rule is not consent', async () => {
        const untagged = mail({ id: 'u', from: BOX, to: [CUSTOMER] });
        const context = ctx(new Map());
        context.Rules = [
            { ID: 'inc', Sequence: 1, IsEnabled: true, Action: 'Include', Direction: null, DateFrom: null, DateTo: null, ParticipantScope: null, ActivitySyncRuleSetID: null, IncludeAttachments: false, MaxAttachmentBytes: null },
        ];
        expect((await RunQualificationCascade(ConsentStages(), untagged, context, 'Exclude')).Decision).toBe('Exclude');
    });
});
