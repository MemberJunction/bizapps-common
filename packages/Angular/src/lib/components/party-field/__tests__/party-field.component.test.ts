import '@angular/compiler';
import { ChangeDetectorRef, Injector, runInInjectionContext } from '@angular/core';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

const H = vi.hoisted(() => ({ logError: vi.fn(), runQuery: vi.fn() }));

vi.mock('@memberjunction/core', async (importOriginal) => ({
    ...(await importOriginal<object>()),
    LogError: H.logError,
    RunQuery: class {
        public RunQuery = H.runQuery;
    },
}));
vi.mock('@memberjunction/ng-base-forms', () => ({ BaseFormsModule: class {} }));
vi.mock('@memberjunction/ng-ui-components', () => ({ MJComboboxComponent: class {} }));

import { PartyFieldComponent, type PartyOption } from '../party-field.component';
import type { PartyLookupParams } from '../party-lookup-term';

interface FakeRecord {
    values: Record<string, unknown>;
    EntityInfo: { Fields: { Name: string; DisplayNameOrName: string; RelatedEntityNameFieldMap: string | null }[] };
    Get(field: string): unknown;
    Set(field: string, value: unknown): void;
}

function record(accountID: string | null, accountName: string | null = null): FakeRecord {
    const values: Record<string, unknown> = { AccountID: accountID, Account: accountName };
    return {
        values,
        EntityInfo: { Fields: [{ Name: 'AccountID', DisplayNameOrName: 'Account', RelatedEntityNameFieldMap: 'Account' }] },
        Get: (field: string) => values[field],
        Set: (field: string, value: unknown) => {
            values[field] = value;
        },
    };
}

/** Stubs the RunQuery seam: each call returns a promise the test resolves by hand, in any order. */
class TestPartyField extends PartyFieldComponent {
    public Calls: { params: PartyLookupParams; resolve: (rows: PartyOption[]) => void; reject: (e: Error) => void }[] = [];
    protected override runSearch(params: PartyLookupParams): Promise<PartyOption[]> {
        return new Promise((resolve, reject) => this.Calls.push({ params, resolve, reject }));
    }
}

function build(rec: FakeRecord): TestPartyField {
    const injector = Injector.create({
        providers: [{ provide: ChangeDetectorRef, useValue: { markForCheck: () => undefined } }],
    });
    const component = runInInjectionContext(injector, () => new TestPartyField());
    component.Record = rec as unknown as PartyFieldComponent['Record'];
    component.FieldName = 'AccountID';
    component.Kind = 'Organization';
    component.EditMode = true;
    component.ngOnInit();
    return component;
}

const DAVE: PartyOption = { ID: 'o-dave', Name: 'Dave Co', Detail: 'dave.com' };
const DA: PartyOption = { ID: 'o-da', Name: 'Da Inc', Detail: null };

describe('PartyFieldComponent', () => {
    beforeEach(() => {
        vi.useFakeTimers();
        H.logError.mockReset();
    });
    afterEach(() => vi.useRealTimers());

    it('sends nothing and lists nothing for one character', async () => {
        const c = build(record(null));
        c.OnFilterChange('d');
        await vi.advanceTimersByTimeAsync(300);
        expect(c.Calls).toHaveLength(0);
        expect(c.Options).toEqual([]);
    });

    it('debounces typing into one search with the last term', async () => {
        const c = build(record(null));
        c.OnFilterChange('da');
        await vi.advanceTimersByTimeAsync(100);
        c.OnFilterChange('dave');
        await vi.advanceTimersByTimeAsync(250);
        expect(c.Calls.map((call) => call.params.Term)).toEqual(['dave']);
    });

    it('drops a slow response for an earlier term', async () => {
        const c = build(record(null));
        c.OnFilterChange('da');
        await vi.advanceTimersByTimeAsync(250);
        c.OnFilterChange('dave');
        await vi.advanceTimersByTimeAsync(250);
        c.Calls[1].resolve([DAVE]);
        await vi.advanceTimersByTimeAsync(0);
        c.Calls[0].resolve([DA]);
        await vi.advanceTimersByTimeAsync(0);
        expect(c.Options).toEqual([DAVE]);
    });

    it('writes the picked ID and emits old and new values', async () => {
        const c = build(record('o-old', 'Old Co'));
        const emitted: unknown[] = [];
        c.ValueChange.subscribe((e) => emitted.push(e));
        c.OnFilterChange('dave');
        await vi.advanceTimersByTimeAsync(250);
        c.Calls[0].resolve([DAVE]);
        await vi.advanceTimersByTimeAsync(0);

        c.OnSelect('o-dave');
        expect(c.Record.Get('AccountID')).toBe('o-dave');
        expect(emitted).toEqual([{ FieldName: 'AccountID', OldValue: 'o-old', NewValue: 'o-dave' }]);
    });

    it('shows a saved value by name without searching', () => {
        const c = build(record('o-old', 'Old Co'));
        expect(c.Options).toEqual([{ ID: 'o-old', Name: 'Old Co', Detail: null }]);
        expect(c.CurrentID).toBe('o-old');
        expect(c.Label).toBe('Account');
        expect(c.Calls).toHaveLength(0);
    });

    it('writes null when cleared', () => {
        const c = build(record('o-old', 'Old Co'));
        c.OnSelect(null);
        expect(c.Record.Get('AccountID')).toBeNull();
    });

    it('goes back to the current value when focus leaves mid-search', async () => {
        const c = build(record('o-old', 'Old Co'));
        c.OnFilterChange('dave');
        await vi.advanceTimersByTimeAsync(250);
        c.Calls[0].resolve([DAVE]);
        await vi.advanceTimersByTimeAsync(0);
        c.OnFocusOut();
        expect(c.Options).toEqual([{ ID: 'o-old', Name: 'Old Co', Detail: null }]);
    });

    it('logs a failed search and shows an empty list with a hint', async () => {
        const c = build(record(null));
        c.OnFilterChange('dave');
        await vi.advanceTimersByTimeAsync(250);
        c.Calls[0].reject(new Error('boom'));
        await vi.advanceTimersByTimeAsync(0);
        expect(H.logError).toHaveBeenCalled();
        expect(c.Options).toEqual([]);
        expect(c.SearchFailed).toBe(true);
    });
});

describe('PartyFieldComponent.runSearch', () => {
    beforeEach(() => H.runQuery.mockReset());

    class Exposed extends PartyFieldComponent {
        public Search(params: PartyLookupParams): Promise<PartyOption[]> {
            return this.runSearch(params);
        }
    }

    function bare(): Exposed {
        const injector = Injector.create({
            providers: [{ provide: ChangeDetectorRef, useValue: { markForCheck: () => undefined } }],
        });
        return runInInjectionContext(injector, () => new Exposed());
    }

    it('runs the default query for the kind and omits a null domain', async () => {
        H.runQuery.mockResolvedValue({ Success: true, Results: [{ ID: 'p1', Name: 'Zed', Detail: 'z@x.com' }] });
        const c = bare();
        c.Kind = 'Person';
        const rows = await c.Search({ Term: 'ze', Domain: null });
        expect(H.runQuery).toHaveBeenCalledWith({
            QueryName: 'Common: Party Lookup People',
            CategoryPath: 'Common',
            Parameters: { Term: 'ze' },
        });
        expect(rows).toEqual([{ ID: 'p1', Name: 'Zed', Detail: 'z@x.com' }]);
    });

    it('runs the QueryName override with its category and passes the domain', async () => {
        H.runQuery.mockResolvedValue({ Success: true, Results: [] });
        const c = bare();
        c.Kind = 'Organization';
        c.QueryName = 'Sales: Party Lookup Accounts';
        c.CategoryPath = 'Sales';
        await c.Search({ Term: 'acme.com', Domain: 'acme.com' });
        expect(H.runQuery).toHaveBeenCalledWith({
            QueryName: 'Sales: Party Lookup Accounts',
            CategoryPath: 'Sales',
            Parameters: { Term: 'acme.com', Domain: 'acme.com' },
        });
    });

    it('throws when the query fails, so the caller can log it', async () => {
        H.runQuery.mockResolvedValue({ Success: false, ErrorMessage: 'denied', Results: [] });
        const c = bare();
        c.Kind = 'Person';
        await expect(c.Search({ Term: 'ze', Domain: null })).rejects.toThrow('denied');
    });
});
