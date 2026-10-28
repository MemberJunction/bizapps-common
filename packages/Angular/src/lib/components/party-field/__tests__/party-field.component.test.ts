import '@angular/compiler';
import { ChangeDetectorRef, Injector, runInInjectionContext } from '@angular/core';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

const H = vi.hoisted(() => ({ logError: vi.fn(), runQuery: vi.fn(), runView: vi.fn() }));

vi.mock('@memberjunction/core', async (importOriginal) => ({
    ...(await importOriginal<object>()),
    LogError: H.logError,
    RunQuery: class {
        public RunQuery = H.runQuery;
    },
    Metadata: class {
        public static Provider = {
            EntityByName: (name: string) => (name === 'Organizations' ? { NameField: { Name: 'Name' } } : undefined),
        };
    },
    RunView: { FromMetadataProvider: () => ({ RunView: H.runView }) },
}));
vi.mock('@memberjunction/ng-base-forms', () => ({ BaseFormsModule: class {} }));
vi.mock('@memberjunction/ng-ui-components', () => ({ MJComboboxComponent: class {} }));

import { PartyFieldComponent, type PartyOption } from '../party-field.component';
import type { PartyLookupParams } from '../party-lookup-term';

interface FakeRecord {
    values: Record<string, unknown>;
    dirty: boolean;
    EntityInfo: {
        Fields: {
            Name: string;
            DisplayNameOrName: string;
            RelatedEntityNameFieldMap: string | null;
            RelatedEntity: string;
            RelatedEntityFieldName: string;
        }[];
    };
    Get(field: string): unknown;
    Set(field: string, value: unknown): void;
    GetFieldByName(field: string): { Dirty: boolean } | null;
}

function record(accountID: string | null, accountName: string | null = null, dirty = false): FakeRecord {
    const values: Record<string, unknown> = { AccountID: accountID, Account: accountName };
    const rec: FakeRecord = {
        values,
        dirty,
        EntityInfo: {
            Fields: [
                {
                    Name: 'AccountID',
                    DisplayNameOrName: 'Account',
                    RelatedEntityNameFieldMap: 'Account',
                    RelatedEntity: 'Organizations',
                    RelatedEntityFieldName: 'ID',
                },
            ],
        },
        Get: (field: string) => values[field],
        Set: (field: string, value: unknown) => {
            values[field] = value;
        },
        GetFieldByName: () => ({ Dirty: rec.dirty }),
    };
    return rec;
}

/** Stubs the RunQuery seam: each call returns a promise the test resolves by hand, in any order. */
class TestPartyField extends PartyFieldComponent {
    public Calls: { params: PartyLookupParams; resolve: (rows: PartyOption[]) => void; reject: (e: Error) => void }[] = [];
    protected override runSearch(params: PartyLookupParams): Promise<PartyOption[]> {
        return new Promise((resolve, reject) => this.Calls.push({ params, resolve, reject }));
    }
    /** Labels the combobox was told to show: the visible text, not just the option list. */
    public Shown: (string | null)[] = [];
    protected override RefreshComboboxText(): void {
        this.Shown.push(this.Options.find((o) => o.ID === this.CurrentID)?.Name ?? null);
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
        H.runView.mockReset();
    });
    afterEach(() => vi.useRealTimers());

    it('names a value set in code (no name on the record) with one lookup on the related entity', async () => {
        H.runView.mockResolvedValue({ Success: true, Results: [{ ID: 'o-new', Name: 'New Co' }] });
        const c = build(record('o-new', null));
        await vi.advanceTimersByTimeAsync(0);
        expect(H.runView).toHaveBeenCalledWith(
            expect.objectContaining({ EntityName: 'Organizations', ExtraFilter: "ID='o-new'", Fields: ['ID', 'Name'], MaxRows: 1 }),
        );
        expect(c.Options).toEqual([{ ID: 'o-new', Name: 'New Co', Detail: null }]);
    });

    it('re-reads the name when the field was changed in code, since the view name is stale', async () => {
        H.runView.mockResolvedValue({ Success: true, Results: [{ ID: 'o-new', Name: 'New Co' }] });
        const c = build(record('o-new', 'Old Co', true));
        await vi.advanceTimersByTimeAsync(0);
        expect(c.Options).toEqual([{ ID: 'o-new', Name: 'New Co', Detail: null }]);
    });

    it('logs a failed name lookup and keeps the ID as the label', async () => {
        H.runView.mockResolvedValue({ Success: false, ErrorMessage: 'denied', Results: [] });
        const c = build(record('o-new', null));
        await vi.advanceTimersByTimeAsync(0);
        expect(H.logError).toHaveBeenCalled();
        expect(c.Options).toEqual([{ ID: 'o-new', Name: 'o-new', Detail: null }]);
    });

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
        expect(H.runView).not.toHaveBeenCalled();
    });

    it('labels the field with its name field ("Person"), as read mode does, not the key ("Person ID")', () => {
        const rec = record('o-old', 'Old Co');
        rec.EntityInfo.Fields[0].DisplayNameOrName = 'Account ID';
        rec.EntityInfo.Fields.push({
            Name: 'Account',
            DisplayNameOrName: 'Account',
            RelatedEntityNameFieldMap: null,
            RelatedEntity: '',
            RelatedEntityFieldName: '',
        });
        expect(build(rec).Label).toBe('Account');
    });

    it('falls back to the key field label when there is no name field', () => {
        const rec = record('o-old', 'Old Co');
        rec.EntityInfo.Fields[0].DisplayNameOrName = 'Account ID';
        rec.EntityInfo.Fields[0].RelatedEntityNameFieldMap = null;
        H.runView.mockResolvedValue({ Success: true, Results: [] });
        expect(build(rec).Label).toBe('Account ID');
    });

    it('keeps the picked name when focus leaves after a pick', async () => {
        const rec = record('o-old', 'Old Co');
        const c = build(rec);
        c.OnFilterChange('dave');
        await vi.advanceTimersByTimeAsync(250);
        c.Calls[0].resolve([DAVE]);
        await vi.advanceTimersByTimeAsync(0);
        c.OnSelect('o-dave');
        rec.dirty = true;
        c.OnFocusOut();
        await vi.advanceTimersByTimeAsync(300);
        expect(c.Options).toEqual([DAVE]);
    });

    it('writes the picked name to the related name field, as the stock field does', async () => {
        const c = build(record(null));
        c.OnFilterChange('dave');
        await vi.advanceTimersByTimeAsync(250);
        c.Calls[0].resolve([DAVE]);
        await vi.advanceTimersByTimeAsync(0);
        c.OnSelect('o-dave');
        expect(c.Record.Get('Account')).toBe('Dave Co');
    });

    it('writes null when cleared, to the key and the name field', () => {
        const c = build(record('o-old', 'Old Co'));
        c.OnSelect(null);
        expect(c.Record.Get('AccountID')).toBeNull();
        expect(c.Record.Get('Account')).toBeNull();
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

    it('shows the resolved name in the combobox, not only in the option list', async () => {
        H.runView.mockResolvedValue({ Success: true, Results: [{ ID: 'o-new', Name: 'New Co' }] });
        const c = build(record('o-new', null));
        await vi.advanceTimersByTimeAsync(0);
        expect(c.Shown.at(-1)).toBe('New Co');
    });

    it('re-reads the current value when it changes outside the picker', async () => {
        H.runView.mockResolvedValue({ Success: true, Results: [{ ID: 'o-new', Name: 'New Co' }] });
        const rec = record('o-old', 'Old Co');
        const c = build(rec);
        rec.values['AccountID'] = 'o-new';
        rec.dirty = true;
        c.ngDoCheck();
        await vi.advanceTimersByTimeAsync(0);
        expect(c.Options).toEqual([{ ID: 'o-new', Name: 'New Co', Detail: null }]);
        expect(c.Shown.at(-1)).toBe('New Co');
    });

    it('does nothing on a check when the value has not changed', () => {
        const c = build(record('o-old', 'Old Co'));
        c.ngDoCheck();
        expect(H.runView).not.toHaveBeenCalled();
        expect(c.Shown).toEqual([]);
    });

    it('does not show a stale failure beside newer results', async () => {
        const c = build(record(null));
        c.OnFilterChange('da');
        await vi.advanceTimersByTimeAsync(250);
        c.OnFilterChange('dave');
        await vi.advanceTimersByTimeAsync(250);
        c.Calls[1].resolve([DAVE]);
        await vi.advanceTimersByTimeAsync(0);
        c.Calls[0].reject(new Error('late'));
        await vi.advanceTimersByTimeAsync(0);
        expect(c.Options).toEqual([DAVE]);
        expect(c.SearchFailed).toBe(false);
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
        expect(c.SearchError).toBe('failed');
    });

    it('says the search took too long when it runs past the timeout', async () => {
        const c = build(record(null));
        c.OnFilterChange('dave');
        await vi.advanceTimersByTimeAsync(250);
        await vi.advanceTimersByTimeAsync(19_999);
        expect(c.SearchError).toBeNull();
        await vi.advanceTimersByTimeAsync(1);
        expect(c.SearchError).toBe('timeout');
        expect(c.Options).toEqual([]);
        expect(H.logError).toHaveBeenCalled();
    });

    it('ignores the late answer of a timed-out search', async () => {
        const c = build(record(null));
        c.SearchTimeoutMs = 1_000;
        c.OnFilterChange('dave');
        await vi.advanceTimersByTimeAsync(1_250);
        c.Calls[0].resolve([DAVE]);
        await vi.advanceTimersByTimeAsync(0);
        expect(c.SearchError).toBe('timeout');
        expect(c.Options).toEqual([]);
    });

    it('clears the timeout once the next search answers', async () => {
        const c = build(record(null));
        c.SearchTimeoutMs = 1_000;
        c.OnFilterChange('da');
        await vi.advanceTimersByTimeAsync(1_250);
        expect(c.SearchError).toBe('timeout');
        c.OnFilterChange('dave');
        await vi.advanceTimersByTimeAsync(250);
        c.Calls[1].resolve([DAVE]);
        await vi.advanceTimersByTimeAsync(0);
        expect(c.SearchError).toBeNull();
        expect(c.Options).toEqual([DAVE]);
    });

    it.each([0, -1, undefined, NaN])('waits indefinitely when the timeout is %s', async (ms) => {
        const c = build(record(null));
        c.SearchTimeoutMs = ms as number;
        c.OnFilterChange('dave');
        await vi.advanceTimersByTimeAsync(60_250);
        expect(c.SearchError).toBeNull();
        c.Calls[0].resolve([DAVE]);
        await vi.advanceTimersByTimeAsync(0);
        expect(c.Options).toEqual([DAVE]);
    });

    it('leaves no timer pending once a search answers', async () => {
        const c = build(record(null));
        c.OnFilterChange('dave');
        await vi.advanceTimersByTimeAsync(250);
        c.Calls[0].resolve([DAVE]);
        await vi.advanceTimersByTimeAsync(0);
        expect(vi.getTimerCount()).toBe(0);
    });

    it('counts a timeout as a failed search', async () => {
        const c = build(record(null));
        c.SearchTimeoutMs = 1_000;
        c.OnFilterChange('dave');
        await vi.advanceTimersByTimeAsync(1_250);
        expect(c.SearchFailed).toBe(true);
    });

    it('does not log the timeout of a search a newer one replaced', async () => {
        const c = build(record(null));
        c.SearchTimeoutMs = 1_000;
        c.OnFilterChange('da');
        await vi.advanceTimersByTimeAsync(250);
        c.OnFilterChange('dave');
        await vi.advanceTimersByTimeAsync(250);
        c.Calls[1].resolve([DAVE]);
        await vi.advanceTimersByTimeAsync(1_000);
        expect(H.logError).not.toHaveBeenCalled();
        expect(c.Options).toEqual([DAVE]);
    });

    it('drops the timeout hint at once when the host clears the search', async () => {
        const c = build(record(null));
        c.SearchTimeoutMs = 1_000;
        c.OnFilterChange('dave');
        await vi.advanceTimersByTimeAsync(1_250);
        expect(c.SearchError).toBe('timeout');
        c.ClearSearch();
        expect(c.SearchError).toBeNull();
        expect(c.Options).toEqual([]);
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
