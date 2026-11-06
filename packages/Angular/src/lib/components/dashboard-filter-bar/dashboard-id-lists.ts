/**
 * @fileoverview The ID lists behind a dashboard's multi-select filters (companies and any list an app
 * adds). Pure, so the rules can be tested without a provider.
 *
 * An empty list is "All". Callers leave it out of a query rather than sending it empty, because an
 * empty `IN ()` matches nothing. IDs are compared ignoring case and surrounding whitespace: they
 * round-trip through JSON and SQL in different cases.
 *
 * @module @mj-biz-apps/common-ng
 */

/** One choice in a filter list. */
export interface FilterOption {
    ID: string;
    Name: string;
}

const idKey = (id: string): string => id.trim().toLowerCase();

/** A list without blanks or repeats, in the order it was given. */
export function CleanIDs(ids: readonly (string | null | undefined)[]): string[] {
    const seen = new Set<string>();
    const out: string[] = [];
    for (const raw of ids) {
        const id = String(raw ?? '').trim();
        if (id && !seen.has(idKey(id))) {
            seen.add(idKey(id));
            out.push(id);
        }
    }
    return out;
}

/** True when `id` is in `ids`, ignoring case. */
export function HasID(ids: readonly string[], id: string | null | undefined): boolean {
    return !!id && ids.some((x) => idKey(x) === idKey(id));
}

/** `ids` with `id` added, or removed when it is already there. */
export function ToggleID(ids: readonly string[], id: string): string[] {
    return HasID(ids, id) ? ids.filter((x) => idKey(x) !== idKey(id)) : [...ids, id];
}

/** True when two lists select the same IDs. Order, case and repeats do not matter. */
export function SameIDs(a: readonly string[], b: readonly string[]): boolean {
    const x = new Set(CleanIDs(a).map(idKey));
    const y = new Set(CleanIDs(b).map(idKey));
    return x.size === y.size && [...x].every((id) => y.has(id));
}

/** Options with duplicates removed, sorted by name, so each list reads the same way every load. */
export function SortedOptions(options: readonly FilterOption[]): FilterOption[] {
    const byID = new Map<string, FilterOption>();
    for (const o of options) {
        if (o.ID && !byID.has(idKey(o.ID))) {
            byID.set(idKey(o.ID), o);
        }
    }
    return [...byID.values()].sort((a, b) => a.Name.localeCompare(b.Name, undefined, { sensitivity: 'base' }));
}

/** "Acme" for one, "Acme +2" for three, "All" for none: a filter button's label. */
export function SelectionLabel(ids: readonly string[], options: readonly FilterOption[]): string {
    if (!ids.length) {
        return 'All';
    }
    const first = options.find((o) => HasID([o.ID], ids[0]))?.Name ?? '1 selected';
    return ids.length === 1 ? first : `${first} +${ids.length - 1}`;
}
