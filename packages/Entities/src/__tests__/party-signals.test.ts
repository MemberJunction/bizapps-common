import { describe, expect, it } from 'vitest';

import { ChipText, MergePartySignalRows, ParseSignalNouns } from '../party-signals.js';

describe('ParseSignalNouns', () => {
    it('reads the marker from a query description', () => {
        expect(ParseSignalNouns('Bill-to parties. [signal: order|orders]')).toEqual({
            NounSingular: 'order',
            NounPlural: 'orders',
        });
    });

    it('tolerates spacing and case in the marker', () => {
        expect(ParseSignalNouns('[SIGNAL:  won deal | won deals ]')).toEqual({
            NounSingular: 'won deal',
            NounPlural: 'won deals',
        });
    });

    it('falls back to record/records when a query carries no marker', () => {
        expect(ParseSignalNouns('no marker')).toEqual({ NounSingular: 'record', NounPlural: 'records' });
        expect(ParseSignalNouns(null)).toEqual({ NounSingular: 'record', NounPlural: 'records' });
    });
});

describe('ChipText', () => {
    it('pluralizes by count', () => {
        const signal = { QueryKey: 'o', NounSingular: 'order', NounPlural: 'orders', LastActivityAt: null };
        expect(ChipText({ ...signal, Count: 1 })).toBe('1 order');
        expect(ChipText({ ...signal, Count: 4 })).toBe('4 orders');
        expect(ChipText({ ...signal, Count: 0 })).toBe('0 orders');
    });
});

describe('MergePartySignalRows', () => {
    it('unions sources per party, keeps one signal per query, and takes the latest date', () => {
        const roster = MergePartySignalRows([
            {
                QueryKey: 'orders',
                NounSingular: 'order',
                NounPlural: 'orders',
                Rows: [
                    { PartyKind: 'organization', PartyID: 'A', Count: 4, LastActivityAt: '2026-08-01' },
                    { PartyKind: 'person', PartyID: 'P', Count: 1, LastActivityAt: null },
                ],
            },
            {
                QueryKey: 'contracts',
                NounSingular: 'contract',
                NounPlural: 'contracts',
                Rows: [{ PartyKind: 'organization', PartyID: 'a', Count: 1, LastActivityAt: '2026-09-01' }],
            },
        ]);

        const a = roster.find((entry) => entry.PartyID.toLowerCase() === 'a');
        expect(a?.Kind).toBe('organization');
        expect(a?.Signals.map((signal) => signal.QueryKey)).toEqual(['orders', 'contracts']);
        expect(a?.LastActivityAt?.toISOString().slice(0, 10)).toBe('2026-09-01');
        expect(a?.TotalCount).toBe(5);
        expect(roster.find((entry) => entry.PartyID === 'P')?.LastActivityAt).toBeNull();
    });

    it('keeps the id as first spelled while matching case-insensitively', () => {
        const roster = MergePartySignalRows([
            { QueryKey: 'a', NounSingular: 'x', NounPlural: 'xs', Rows: [{ PartyKind: 'person', PartyID: 'Bob', Count: 1, LastActivityAt: null }] },
            { QueryKey: 'b', NounSingular: 'y', NounPlural: 'ys', Rows: [{ PartyKind: 'person', PartyID: 'bob', Count: 2, LastActivityAt: null }] },
        ]);
        expect(roster).toHaveLength(1);
        expect(roster[0].PartyID).toBe('Bob');
        expect(roster[0].TotalCount).toBe(3);
    });

    it('drops rows with a blank id or a kind outside the contract', () => {
        const roster = MergePartySignalRows([
            {
                QueryKey: 'x',
                NounSingular: 'x',
                NounPlural: 'xs',
                Rows: [
                    { PartyKind: 'widget', PartyID: 'Z', Count: 1, LastActivityAt: null },
                    { PartyKind: 'person', PartyID: '   ', Count: 1, LastActivityAt: null },
                ],
            },
        ]);
        expect(roster).toEqual([]);
    });

    it('reads a Date or a driver string, and ignores an unparseable date rather than poisoning the entry', () => {
        const roster = MergePartySignalRows([
            {
                QueryKey: 'x',
                NounSingular: 'x',
                NounPlural: 'xs',
                Rows: [
                    { PartyKind: 'organization', PartyID: 'A', Count: 1, LastActivityAt: new Date('2026-03-04T00:00:00Z') },
                    { PartyKind: 'organization', PartyID: 'A', Count: 1, LastActivityAt: 'not a date' },
                ],
            },
        ]);
        expect(roster[0].LastActivityAt?.toISOString().slice(0, 10)).toBe('2026-03-04');
    });

    it('treats a missing or non-numeric count as zero rather than NaN', () => {
        const roster = MergePartySignalRows([
            {
                QueryKey: 'x',
                NounSingular: 'x',
                NounPlural: 'xs',
                Rows: [{ PartyKind: 'organization', PartyID: 'A', Count: Number.NaN, LastActivityAt: null }],
            },
        ]);
        expect(roster[0].TotalCount).toBe(0);
        expect(roster[0].Signals[0].Count).toBe(0);
    });

    it('returns an empty roster for no sources', () => {
        expect(MergePartySignalRows([])).toEqual([]);
    });
});
