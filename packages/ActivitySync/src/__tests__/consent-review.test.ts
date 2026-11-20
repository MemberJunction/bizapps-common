/**
 * Reproductions of code-review findings against the Tagged consent chain. Each test asserts the
 * CORRECT behaviour, so it is red while the finding stands.
 */
import { describe, expect, it } from 'vitest';

import { PROP_IN_REPLY_TO, PROP_REFERENCES, PROP_SENSITIVITY, ResolveConsent, type ConsentGrant } from '../consent.js';
import { ConsentEligible, ConsentStages, type ConsentQualificationContext } from '../consent-stages.js';
import { RunQualificationCascade } from '../qualification.js';
import type { ItemParticipant, NormalizedItem } from '../types.js';

const BOX = 'rep@internal.test';
const CUSTOMER = 'nora@customer.test';
const ADA = 'ada@customer.test';

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
    thread?: string;
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
        ExternalThreadID: spec.thread ?? 'conv-1',
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

function ctx(grants: ReadonlyMap<string, ConsentGrant>): ConsentQualificationContext {
    return {
        ConnectionID: 'c',
        ProviderTypeCode: 'Microsoft365',
        Exclusions: [],
        Rules: [],
        InternalDomains: ['internal.test'],
        KnownAddresses: new Map(),
        Consent: grants,
        Kind: 'Message',
        Tag: 'AIDP',
    };
}

describe('code-review reproductions', () => {
    it('F3a: a reply to a tagged DRAFT (blocked by ConsentBlock) is not captured', async () => {
        const draft = mail({ id: 'm1', from: BOX, to: [CUSTOMER], tags: ['AIDP'], extra: { isDraft: true } });
        const reply = mail({ id: 'm2', from: CUSTOMER, to: [BOX], replyTo: '<m1@x>', at: '2026-11-10T10:00:00Z' });
        const eligible = await ConsentEligible([draft, reply], ctx(new Map()));
        const grants = ResolveConsent([draft, reply], new Map(), 'AIDP', 'Message', eligible);
        const verdict = await RunQualificationCascade(ConsentStages(), reply, ctx(grants), 'Exclude');
        expect(verdict.Decision).toBe('Exclude');
    });

    it('F3b: a reply only to a Private proven reply (excluded by ConsentStage) is not captured', async () => {
        const m1 = mail({ id: 'm1', from: BOX, to: [CUSTOMER], tags: ['AIDP'] });
        const m2 = mail({ id: 'm2', from: CUSTOMER, to: [BOX], replyTo: '<m1@x>', at: '2026-11-10T10:00:00Z', props: [{ id: PROP_SENSITIVITY, value: '2' }] });
        const m3 = mail({ id: 'm3', from: CUSTOMER, to: [BOX], replyTo: '<m2@x>', at: '2026-11-10T11:00:00Z' });
        const grants = ResolveConsent([m1, m2, m3], new Map(), 'AIDP', 'Message');
        expect((await RunQualificationCascade(ConsentStages(), m2, ctx(grants), 'Exclude')).Decision).toBe('Exclude');
        const verdict = await RunQualificationCascade(ConsentStages(), m3, ctx(grants), 'Exclude');
        expect(verdict.Decision).toBe('Exclude');
    });

    it('F6: the direct parent (In-Reply-To) is followed even behind a 25-message References chain', () => {
        const parent = mail({ id: 'p', from: BOX, to: [CUSTOMER] });
        const chain = Array.from({ length: 24 }, (_, i) => `<r${i}@x>`);
        const tagged = mail({ id: 't', from: CUSTOMER, to: [BOX], tags: ['AIDP'], replyTo: '<p@x>', references: [...chain, '<p@x>'], at: '2026-11-10T10:00:00Z' });
        const grants = ResolveConsent([parent, tagged], new Map(), 'AIDP', 'Message');
        expect(grants.get('<p@x>')).toEqual({ Kind: 'Ancestor', Via: '<t@x>' });
    });

    it('F9: a later consented reference that ContinuesThread satisfies is used when the first does not', () => {
        const m1 = mail({ id: 'm1', from: BOX, to: [CUSTOMER], tags: ['AIDP'] });
        const m2 = mail({ id: 'm2', from: CUSTOMER, to: [BOX, ADA], tags: ['AIDP'], at: '2026-11-10T10:00:00Z' });
        const m3 = mail({ id: 'm3', from: BOX, to: [CUSTOMER, ADA], references: ['<m1@x>', '<m2@x>'], at: '2026-11-10T11:00:00Z' });
        const grants = ResolveConsent([m1, m2, m3], new Map(), 'AIDP', 'Message');
        expect(grants.get('<m3@x>')?.Kind).toBe('Reply');
    });

    it('F10a: same-batch half - a reply in a DIFFERENT conversation is granted off its In-Reply-To', () => {
        // Documents current behaviour (green). The cross-run half (loadPrior filters by ExternalThreadID,
        // consent-intake.ts) would not find the same parent, so the same reply is excluded in a later run.
        const m1 = mail({ id: 'm1', from: BOX, to: [CUSTOMER], tags: ['AIDP'] });
        const m2 = mail({ id: 'm2', from: CUSTOMER, to: [BOX], replyTo: '<m1@x>', thread: 'conv-2', at: '2026-11-10T10:00:00Z' });
        const grants = ResolveConsent([m1, m2], new Map(), 'AIDP', 'Message');
        expect(grants.get('<m2@x>')).toEqual({ Kind: 'Reply', Via: '<m1@x>' });
    });
});
