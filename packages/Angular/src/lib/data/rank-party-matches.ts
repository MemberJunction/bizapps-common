import { FormatFKCell, type FKLookupRow } from '@memberjunction/ng-base-forms';
import type { PartyRosterEntry } from '@mj-biz-apps/common-entities';

/** Looks up a party in the session roster; null when the party is nobody's customer. */
export type RosterLookup = (partyID: string) => PartyRosterEntry | null;

interface Ranked {
    Row: FKLookupRow;
    Tier: number;
    IsCustomer: number;
    Recency: number;
    Name: string;
}

/**
 * Order party rows for a picker: prefix before contains, customers before strangers, recent
 * before dormant, then alphabetical.
 *
 * The first tier is deliberately the same rule as the platform's `RankByPrefix` — a starts-with
 * match on the name, compared through `FormatFKCell` so a value normalizes identically — because
 * a field using the stock strategy and a field using this one must agree about what typing a
 * prefix means. It is restated here rather than composed because `RankByPrefix` returns a sorted
 * array with no tier attached, and sorting that result again by customer would silently discard
 * the prefix ordering it exists to impose. If the platform rule ever changes, this must follow;
 * the tests below pin the shared behaviour so the divergence would fail loudly.
 *
 * What this adds is the part only the parties know. Within a tier, someone we already do business
 * with outranks someone we do not, and among customers the most recently active outranks the
 * dormant. That ordering is the feature: a picker that puts a prospect nobody recognizes above
 * the customer whose order is open in the next tab is the behaviour being replaced.
 *
 * Pure, so the ordering can be argued with in a test rather than in a browser.
 */
export function RankPartyMatches(
    rows: ReadonlyArray<FKLookupRow>,
    query: string,
    nameField: string,
    rosterOf: RosterLookup,
    pkField = 'ID',
): FKLookupRow[] {
    const typed = query.trim().toLowerCase();
    const ranked = rows.map<Ranked>((row) => {
        const name = FormatFKCell(row.Values[nameField]).toLowerCase();
        const entry = rosterOf(String(row.Values[pkField] ?? ''));
        return {
            Row: row,
            Tier: !typed || name.startsWith(typed) ? 0 : 1,
            IsCustomer: entry ? 0 : 1,
            Recency: -(entry?.LastActivityAt?.getTime() ?? 0),
            Name: name,
        };
    });

    return ranked
        .sort(
            (a, b) =>
                a.Tier - b.Tier ||
                a.IsCustomer - b.IsCustomer ||
                a.Recency - b.Recency ||
                a.Name.localeCompare(b.Name),
        )
        .map((entry) => entry.Row);
}
