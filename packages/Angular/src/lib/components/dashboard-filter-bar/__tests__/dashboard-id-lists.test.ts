/**
 * The ID-list rules behind a dashboard's multi-select filters. An empty list is "All", and IDs
 * compare ignoring case, because they round-trip through JSON and SQL in different cases.
 */
import { describe, expect, it } from 'vitest';

import { CleanIDs, HasID, SameIDs, SelectionLabel, SortedOptions, ToggleID } from '../dashboard-id-lists';

describe('the lists', () => {
    it('drop blanks and repeats, ignoring case', () => {
        expect(CleanIDs(['a', 'A', '', null, undefined, ' b '])).toEqual(['a', 'b']);
    });

    it('find an ID ignoring case, and never a blank one', () => {
        expect(HasID(['ABC'], 'abc')).toBe(true);
        expect(HasID(['ABC'], null)).toBe(false);
        expect(HasID([], 'abc')).toBe(false);
    });

    it('toggle a choice on and off', () => {
        expect(ToggleID(['a'], 'b')).toEqual(['a', 'b']);
        expect(ToggleID(['a', 'b'], 'A')).toEqual(['b']);
    });

    it('compare as sets', () => {
        expect(SameIDs(['e1', 'e2'], ['E2', 'e1'])).toBe(true);
        expect(SameIDs(['e1', 'e1'], ['e1'])).toBe(true);
        expect(SameIDs(['e1'], [])).toBe(false);
    });

    it('label a button with what is picked', () => {
        const options = [
            { ID: 'C1', Name: 'Acme' },
            { ID: 'C2', Name: 'Birch' },
        ];
        expect(SelectionLabel([], options)).toBe('All');
        expect(SelectionLabel(['c1'], options)).toBe('Acme');
        expect(SelectionLabel(['C2', 'C1'], options)).toBe('Birch +1');
        expect(SelectionLabel(['gone'], options)).toBe('1 selected');
    });
});

describe('SortedOptions', () => {
    it('sorts by name and drops a repeated ID', () => {
        const sorted = SortedOptions([
            { ID: 'b', Name: 'birch' },
            { ID: 'a', Name: 'Acme' },
            { ID: 'A', Name: 'Acme again' },
            { ID: '', Name: 'No id' },
        ]);
        expect(sorted.map((o) => o.Name)).toEqual(['Acme', 'birch']);
    });
});
