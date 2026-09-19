/**
 * The Party Signals contract — how an app tells the shared party pickers who its customers are.
 *
 * Common owns Organizations and People but cannot see the orders, contracts or sales schemas, and
 * neither party carries a customer flag or a last-activity date. Rather than teach Common about
 * every app, each app ships ONE MJ Query in the `Party Signals` category returning:
 *
 *   PartyKind       'organization' | 'person'
 *   PartyID         the Common Organization or Person ID
 *   Count           how many of the app's records name this party (orders, contracts, won deals)
 *   LastActivityAt  the most recent date among them, or null
 *
 * and carrying `[signal: order|orders]` in its `Description` so a picker row can be labelled
 * "4 orders" without knowing what an order is. The category IS the registry: nothing imports an
 * app, and every client — Explorer, Skip, agents, MCP, reports — discovers the same queries
 * through metadata and gets the same answer to "is this party a customer".
 *
 * This module is the contract plus the pure union of the rows. It has no MJ dependency at all, so
 * the ranking it feeds can be tested without a database, a provider or Angular.
 */

export const PARTY_SIGNALS_CATEGORY = 'Party Signals';

export type PartyKind = 'organization' | 'person';

/** One row as a signal query returns it. Loosely typed on purpose: it crosses a SQL boundary. */
export interface PartySignalRow {
    PartyKind: string;
    PartyID: string;
    Count: number;
    LastActivityAt: string | Date | null;
}

/** One query's contribution: its rows plus the nouns its description declared. */
export interface PartySignalSource {
    QueryKey: string;
    NounSingular: string;
    NounPlural: string;
    Rows: PartySignalRow[];
}

/** What one app says about one party. */
export interface PartySignal {
    QueryKey: string;
    NounSingular: string;
    NounPlural: string;
    Count: number;
    LastActivityAt: Date | null;
}

/** What every app together says about one party. */
export interface PartyRosterEntry {
    PartyID: string;
    Kind: PartyKind;
    Signals: PartySignal[];
    TotalCount: number;
    LastActivityAt: Date | null;
}

export interface SignalNouns {
    NounSingular: string;
    NounPlural: string;
}

const SIGNAL_MARKER = /\[signal:\s*([^|\]]+)\|([^\]]+)\]/i;

const DEFAULT_NOUNS: SignalNouns = { NounSingular: 'record', NounPlural: 'records' };

/**
 * Pull the chip nouns out of a query description. A query that forgets the marker still works;
 * its rows are simply labelled "4 records", which is honest rather than wrong.
 */
export function ParseSignalNouns(description: string | null | undefined): SignalNouns {
    const match = SIGNAL_MARKER.exec(description ?? '');
    if (!match) {
        return { ...DEFAULT_NOUNS };
    }
    return { NounSingular: match[1].trim(), NounPlural: match[2].trim() };
}

/** "4 orders", "1 order" — the text of one picker chip. */
export function ChipText(signal: Pick<PartySignal, 'Count' | 'NounSingular' | 'NounPlural'>): string {
    return `${signal.Count} ${signal.Count === 1 ? signal.NounSingular : signal.NounPlural}`;
}

function toDate(value: string | Date | null | undefined): Date | null {
    if (!value) {
        return null;
    }
    const date = value instanceof Date ? value : new Date(value);
    return Number.isNaN(date.getTime()) ? null : date;
}

function toKind(value: string): PartyKind | null {
    const kind = (value ?? '').trim().toLowerCase();
    return kind === 'organization' || kind === 'person' ? kind : null;
}

function toCount(value: number): number {
    const count = Number(value);
    return Number.isFinite(count) ? count : 0;
}

function addRow(entry: PartyRosterEntry, source: PartySignalSource, row: PartySignalRow): void {
    const at = toDate(row.LastActivityAt);
    entry.Signals.push({
        QueryKey: source.QueryKey,
        NounSingular: source.NounSingular,
        NounPlural: source.NounPlural,
        Count: toCount(row.Count),
        LastActivityAt: at,
    });
    entry.TotalCount += toCount(row.Count);
    if (at && (!entry.LastActivityAt || at > entry.LastActivityAt)) {
        entry.LastActivityAt = at;
    }
}

/**
 * Union every source into one entry per party.
 *
 * Party IDs are matched case-insensitively because GUIDs arrive in whichever case the provider
 * and the query happened to produce, and two spellings of one organization would otherwise read
 * as two customers — the exact defect this whole feature exists to stop showing people. The first
 * spelling seen is the one kept, so it still matches the record it came from. Rows whose kind is
 * outside the contract, or whose ID is blank, are dropped rather than trusted.
 */
export function MergePartySignalRows(sources: ReadonlyArray<PartySignalSource>): PartyRosterEntry[] {
    const byID = new Map<string, PartyRosterEntry>();
    for (const source of sources) {
        for (const row of source.Rows) {
            const kind = toKind(row.PartyKind);
            const id = (row.PartyID ?? '').trim();
            if (!kind || !id) {
                continue;
            }
            const key = id.toLowerCase();
            const entry = byID.get(key) ?? { PartyID: id, Kind: kind, Signals: [], TotalCount: 0, LastActivityAt: null };
            addRow(entry, source, row);
            byID.set(key, entry);
        }
    }
    return [...byID.values()];
}
