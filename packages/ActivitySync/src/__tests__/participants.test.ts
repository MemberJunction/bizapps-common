import { describe, expect, it } from 'vitest';

import { ClassifyParticipants, DomainOf, MatchesParticipantScope } from '../participants.js';
import type { ItemParticipant } from '../types.js';

const INTERNAL = ['bluecypress.io', 'memberjunction.com'];

function p(address: string): ItemParticipant {
    return { Address: address, Name: null, Role: 'To', IdentityKind: 'Email' };
}

describe('DomainOf', () => {
    it('lower-cases and extracts the domain', () => {
        expect(DomainOf('Amith@BlueCypress.IO')).toBe('bluecypress.io');
    });

    it('returns null for anything without a usable domain', () => {
        expect(DomainOf('not-an-address')).toBeNull();
        expect(DomainOf('trailing@')).toBeNull();
        expect(DomainOf('')).toBeNull();
    });

    it('uses the LAST @, so a quoted local part does not fool it', () => {
        expect(DomainOf('"weird@local"@example.com')).toBe('example.com');
    });
});

describe('ClassifyParticipants', () => {
    it('splits internal from external, case-insensitively', () => {
        const c = ClassifyParticipants([p('a@BLUECYPRESS.io'), p('b@customer.com')], INTERNAL);
        expect(c).toEqual({ Internal: 1, External: 1, Unknown: 0 });
    });

    it('tolerates internal domains written with a leading @', () => {
        const c = ClassifyParticipants([p('a@bluecypress.io')], ['@bluecypress.io']);
        expect(c.Internal).toBe(1);
    });

    it('counts an unparseable address as Unknown — never as internal', () => {
        const c = ClassifyParticipants([p('a@bluecypress.io'), p('garbage')], INTERNAL);
        expect(c).toEqual({ Internal: 1, External: 0, Unknown: 1 });
    });

    it('treats everything as external when no internal domains are configured', () => {
        const c = ClassifyParticipants([p('a@bluecypress.io')], []);
        expect(c).toEqual({ Internal: 0, External: 1, Unknown: 0 });
    });
});

describe('MatchesParticipantScope', () => {
    const allInternal = { Internal: 3, External: 0, Unknown: 0 };
    const allExternal = { Internal: 0, External: 2, Unknown: 0 };
    const mixed = { Internal: 2, External: 1, Unknown: 0 };
    const empty = { Internal: 0, External: 0, Unknown: 0 };

    it('Any always matches, including an empty participant list', () => {
        expect(MatchesParticipantScope('Any', empty)).toBe(true);
        expect(MatchesParticipantScope('Any', mixed)).toBe(true);
    });

    it('AllInternal requires at least one internal and no external', () => {
        expect(MatchesParticipantScope('AllInternal', allInternal)).toBe(true);
        expect(MatchesParticipantScope('AllInternal', mixed)).toBe(false);
        expect(MatchesParticipantScope('AllInternal', empty)).toBe(false);
    });

    it('AllExternal requires at least one external and no internal', () => {
        expect(MatchesParticipantScope('AllExternal', allExternal)).toBe(true);
        expect(MatchesParticipantScope('AllExternal', mixed)).toBe(false);
    });

    it('HasExternal / HasInternal are presence tests', () => {
        expect(MatchesParticipantScope('HasExternal', mixed)).toBe(true);
        expect(MatchesParticipantScope('HasExternal', allInternal)).toBe(false);
        expect(MatchesParticipantScope('HasInternal', mixed)).toBe(true);
        expect(MatchesParticipantScope('HasInternal', allExternal)).toBe(false);
    });

    it('Mixed requires both sides present — the case an all-or-nothing rule gets wrong', () => {
        expect(MatchesParticipantScope('Mixed', mixed)).toBe(true);
        expect(MatchesParticipantScope('Mixed', allInternal)).toBe(false);
        expect(MatchesParticipantScope('Mixed', allExternal)).toBe(false);
    });

    it('an UNKNOWN participant breaks AllInternal — it never counts as one of us', () => {
        // The scenario that matters: an internal-only EXCLUDE rule must not fire on a thread
        // containing an address we could not classify, or a real customer conversation is
        // silently dropped.
        const withUnknown = { Internal: 3, External: 0, Unknown: 1 };
        expect(MatchesParticipantScope('AllInternal', withUnknown)).toBe(false);
        expect(MatchesParticipantScope('HasExternal', withUnknown)).toBe(true);
        expect(MatchesParticipantScope('Mixed', withUnknown)).toBe(true);
    });
});
