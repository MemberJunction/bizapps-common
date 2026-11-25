import { describe, expect, it, vi } from 'vitest';

// The workspace's platform build predates the lookup seam, so the module is stubbed with the one
// helper this file uses. FormatFKCell's real contract is "render a cell value as a string".
vi.mock('@memberjunction/ng-base-forms', () => ({
    FormatFKCell: (value: unknown) => (value === null || value === undefined ? '' : String(value)),
}));

import type { PartyRosterEntry } from '@mj-biz-apps/common-entities';
import { RankPartyMatches } from '../rank-party-matches';

function customer(id: string, lastActivity: string | null): PartyRosterEntry {
    return {
        PartyID: id,
        Kind: 'organization',
        Signals: [],
        TotalCount: 1,
        LastActivityAt: lastActivity ? new Date(lastActivity) : null,
    };
}

function row(id: string, name: string): { Values: Record<string, unknown> } {
    return { Values: { ID: id, Name: name } };
}

const roster = new Map<string, PartyRosterEntry>([
    ['recent-customer', customer('recent-customer', '2026-09-01')],
    ['old-customer', customer('old-customer', '2026-01-01')],
    ['undated-customer', customer('undated-customer', null)],
]);

const rosterOf = (id: string): PartyRosterEntry | null => roster.get(id) ?? null;

function order(rows: ReadonlyArray<{ Values: Record<string, unknown> }>, query: string): string[] {
    return RankPartyMatches(rows, query, 'Name', rosterOf).map((r) => String(r.Values['ID']));
}

describe('RankPartyMatches', () => {
    it('puts a prefix match above a contains match', () => {
        const rows = [row('contains', 'Association of Energy Engineers'), row('prefix', 'Energy Partners')];
        expect(order(rows, 'energy')).toEqual(['prefix', 'contains']);
    });

    it('keeps the prefix tier above the customer rule, so a stranger who matches better still wins', () => {
        // The tier is the platform's rule and must not be overridden by ours: someone typing a
        // prefix is naming a record, not asking for their customer list.
        const rows = [row('old-customer', 'Northwind Energy'), row('stranger', 'Energy Systems')];
        expect(order(rows, 'energy')).toEqual(['stranger', 'old-customer']);
    });

    it('puts a customer above a stranger within the same tier', () => {
        const rows = [row('stranger', 'Energy Alpha'), row('old-customer', 'Energy Beta')];
        expect(order(rows, 'energy')).toEqual(['old-customer', 'stranger']);
    });

    it('orders customers by most recent activity, not alphabetically', () => {
        const rows = [row('old-customer', 'Energy Alpha'), row('recent-customer', 'Energy Zulu')];
        expect(order(rows, 'energy')).toEqual(['recent-customer', 'old-customer']);
    });

    it('puts a customer with no recorded activity last among customers, but above a stranger', () => {
        const rows = [row('undated-customer', 'Energy Alpha'), row('recent-customer', 'Energy Beta'), row('stranger', 'Energy Gamma')];
        expect(order(rows, 'energy')).toEqual(['recent-customer', 'undated-customer', 'stranger']);
    });

    it('falls back to alphabetical between two strangers in the same tier', () => {
        const rows = [row('b', 'Energy Zulu'), row('a', 'Energy Alpha')];
        expect(order(rows, 'energy')).toEqual(['a', 'b']);
    });

    it('treats an empty query as one tier: customers by recency, then everyone alphabetically', () => {
        const rows = [row('stranger', 'Alpha'), row('old-customer', 'Zulu'), row('recent-customer', 'Mike')];
        expect(order(rows, '')).toEqual(['recent-customer', 'old-customer', 'stranger']);
    });

    it('ignores case and surrounding whitespace in the typed query', () => {
        const rows = [row('contains', 'The Energy Council'), row('prefix', 'Energy Council')];
        expect(order(rows, '  ENERGY ')).toEqual(['prefix', 'contains']);
    });

    it('does not mutate the array it was given', () => {
        const rows = [row('b', 'Zulu'), row('a', 'Alpha')];
        const before = rows.map((r) => r.Values['ID']);
        RankPartyMatches(rows, '', 'Name', rosterOf);
        expect(rows.map((r) => r.Values['ID'])).toEqual(before);
    });

    it('tolerates a missing or null name rather than throwing', () => {
        const rows = [{ Values: { ID: 'no-name' } }, row('named', 'Alpha')];
        expect(order(rows, '')).toEqual(['no-name', 'named']);
    });

    it('reads the primary key from the field the caller names', () => {
        const rows = [{ Values: { PersonID: 'recent-customer', Name: 'Zulu' } }, { Values: { PersonID: 'stranger', Name: 'Alpha' } }];
        const ranked = RankPartyMatches(rows, '', 'Name', rosterOf, 'PersonID');
        expect(ranked.map((r) => String(r.Values['PersonID']))).toEqual(['recent-customer', 'stranger']);
    });
});
