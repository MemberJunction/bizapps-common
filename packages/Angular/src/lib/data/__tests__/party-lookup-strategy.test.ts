import { beforeEach, describe, expect, it, vi } from 'vitest';

const H = vi.hoisted(() => ({
    /** Rows the inherited (platform) hydrate/Lookup path is pretending to return. */
    directoryRows: [] as { Values: Record<string, unknown> }[],
    hydrated: [] as { Values: Record<string, unknown> }[],
    lookupCalls: [] as { Scope: string; Options: Record<string, unknown> }[],
    baseFilterCalls: [] as string[],
    customers: [] as unknown[],
    get: (_id: string) => null as unknown,
    runView: vi.fn(),
}));

// The workspace's platform build predates the lookup seam, so the base class and helpers are
// stubbed. The stub keeps the real contract: Lookup returns groups, baseFilter composes filters,
// hydrate resolves ids to rows — which is what this strategy builds on.
vi.mock('@memberjunction/ng-base-forms', () => {
    class DefaultFKLookupStrategy {
        public async Lookup(context: { Scope: string; Options: Record<string, unknown> }) {
            H.lookupCalls.push({ Scope: context.Scope, Options: context.Options });
            return [{ Key: 'results', Label: null, Rows: H.directoryRows }];
        }
        protected baseFilter(_context: unknown): string {
            return 'inherited = 1';
        }
        protected async hydrate(_context: unknown, ids: string[]) {
            return H.hydrated.filter((row) => ids.includes(String(row.Values['ID'])));
        }
    }
    return {
        DefaultFKLookupStrategy,
        FKLookupStrategy: class {},
        FormatFKCell: (value: unknown) => (value === null || value === undefined ? '' : String(value)),
        CombineFilters: (...parts: (string | null | undefined)[]) => {
            const kept = parts.filter((p) => p && p.length > 0);
            H.baseFilterCalls.push(kept.join(' AND '));
            return kept.join(' AND ');
        },
        QuoteSqlIdList: (ids: string[]) => ids.map((id) => `'${id}'`).join(','),
    };
});

vi.mock('@memberjunction/global', async (importOriginal) => ({
    ...(await importOriginal<object>()),
    RegisterClass: () => () => undefined,
}));

// common-entities re-exports the generated subclasses, which extend BaseEntity, so the real
// @memberjunction/core exports have to survive the mock.
vi.mock('@memberjunction/core', async (importOriginal) => ({
    ...(await importOriginal<object>()),
    RunView: { FromMetadataProvider: () => ({ RunView: H.runView }) },
}));

vi.mock('../party-signal-store', () => ({
    PartySignalStore: {
        Instance: {
            Load: async () => undefined,
            Customers: () => H.customers,
            Get: (id: string) => H.get(id),
        },
    },
}));

import { PartyLookupStrategy } from '../party-lookup-strategy';

const ORGANIZATIONS = 'MJ_BizApps_Common: Organizations';
const PEOPLE = 'MJ_BizApps_Common: People';

function entry(id: string, nounPlural: string, count: number, at: string | null) {
    return {
        PartyID: id,
        Kind: 'organization',
        TotalCount: count,
        LastActivityAt: at ? new Date(at) : null,
        Signals: [{ QueryKey: 'q', NounSingular: nounPlural.slice(0, -1), NounPlural: nounPlural, Count: count, LastActivityAt: null }],
    };
}

function context(overrides: Record<string, unknown> = {}) {
    return {
        Record: { Get: (field: string) => (overrides['recordValues'] as Record<string, unknown>)?.[field] ?? null },
        FieldInfo: { RelatedEntityFilter: null, RelatedEntityOrderBy: null },
        RelatedEntity: { Name: ORGANIZATIONS, PrimaryKeys: [{}] },
        Provider: {},
        Fields: ['ID', 'Name'],
        PkField: 'ID',
        NameField: 'Name',
        SearchField: 'Name',
        Query: '',
        Scope: 'primary',
        MaxRows: 20,
        Options: {},
        ...overrides,
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } as any;
}

describe('PartyLookupStrategy', () => {
    beforeEach(() => {
        H.directoryRows = [];
        H.hydrated = [];
        H.lookupCalls = [];
        H.baseFilterCalls = [];
        H.customers = [];
        H.get = () => null;
        H.runView.mockReset();
    });

    it('labels the scope toggle for the entity it is attached to', () => {
        const strategy = new PartyLookupStrategy();
        expect(strategy.ScopeLabels(context())).toEqual({ primary: 'Customers', all: 'All organizations' });
        expect(strategy.ScopeLabels(context({ RelatedEntity: { Name: PEOPLE, PrimaryKeys: [{}] } })).all).toBe('All people');
    });

    it('offers customers first, with a second line and a chip per signal', async () => {
        H.customers = [entry('org-a', 'orders', 4, '2026-09-01')];
        H.get = (id) => (id.toLowerCase() === 'org-a' ? (H.customers[0] as never) : null);
        H.hydrated = [
            {
                Values: {
                    ID: 'org-a',
                    Name: 'Northwind Energy',
                    PrimaryAddressCity: 'Springfield',
                    PrimaryAddressState: 'IL',
                    Website: 'northwind.example.org',
                },
            },
        ];

        const groups = await new PartyLookupStrategy().Lookup(context());

        expect(groups).toHaveLength(1);
        expect(groups[0].Key).toBe('customers');
        expect(groups[0].Label).toBe('Customers');
        expect(groups[0].Rows[0].Secondary).toBe('Springfield, IL · northwind.example.org');
        expect(groups[0].Rows[0].Chips).toEqual([{ Text: '4 orders' }]);
    });

    it('filters the customer roster in memory rather than going back to the server', async () => {
        H.customers = [entry('org-a', 'orders', 1, null), entry('org-b', 'orders', 1, null)];
        H.hydrated = [
            { Values: { ID: 'org-a', Name: 'Northwind Energy' } },
            { Values: { ID: 'org-b', Name: 'Contoso Freight' } },
        ];

        const groups = await new PartyLookupStrategy().Lookup(context({ Query: 'north' }));

        expect(groups[0].Rows.map((r) => r.Values['Name'])).toEqual(['Northwind Energy']);
        expect(H.lookupCalls).toHaveLength(0); // never reached the inherited query path
    });

    it('asks the platform for hybrid ranking on the wide scope, and decorates what comes back', async () => {
        H.directoryRows = [{ Values: { ID: 'org-z', Name: 'Zenith', PrimaryAddressCity: 'Austin', PrimaryAddressState: 'TX' } }];

        const groups = await new PartyLookupStrategy().Lookup(context({ Scope: 'all', Query: 'zen' }));

        expect(H.lookupCalls[0].Options['SearchMode']).toBe('hybrid');
        expect(groups[0].Rows[0].Secondary).toBe('Austin, TX');
    });

    it('hides inactive parties unless the host asks for them', () => {
        const strategy = new PartyLookupStrategy() as unknown as { baseFilter(c: unknown): string };
        expect(strategy.baseFilter(context())).toContain("[Status] = 'Active'");
        expect(strategy.baseFilter(context({ Options: { IncludeInactive: true } }))).not.toContain('[Status]');
    });

    it('offers people at the already-chosen organization ahead of everyone else', async () => {
        H.runView.mockResolvedValue({ Success: true, Results: [{ FromPersonID: 'per-1' }] });
        H.hydrated = [{ Values: { ID: 'per-1', DisplayName: 'Dana Reed', Title: 'Controller' } }];

        const groups = await new PartyLookupStrategy().Lookup(
            context({
                RelatedEntity: { Name: PEOPLE, PrimaryKeys: [{}] },
                NameField: 'DisplayName',
                Options: { ScopeField: 'BillToOrganizationID' },
                recordValues: { BillToOrganizationID: 'org-a', BillToOrganization: 'Northwind Energy' },
            }),
        );

        expect(groups[0].Key).toBe('at-organization');
        expect(groups[0].Label).toBe('At Northwind Energy');
        expect(groups[0].Rows[0].Values['DisplayName']).toBe('Dana Reed');
        expect(groups[1].Key).toBe('customers');
    });

    it('skips the affiliation group when the host names no scope field', async () => {
        const groups = await new PartyLookupStrategy().Lookup(context({ RelatedEntity: { Name: PEOPLE, PrimaryKeys: [{}] } }));
        expect(groups.map((g) => g.Key)).toEqual(['customers']);
        expect(H.runView).not.toHaveBeenCalled();
    });

    it('scopes the affiliation query to active, current, employee-type relationships', async () => {
        H.runView.mockResolvedValue({ Success: true, Results: [] });
        await new PartyLookupStrategy().Lookup(
            context({
                RelatedEntity: { Name: PEOPLE, PrimaryKeys: [{}] },
                Options: { ScopeField: 'BillToOrganizationID' },
                recordValues: { BillToOrganizationID: 'org-a' },
            }),
        );
        const filter = H.runView.mock.calls[0][0].ExtraFilter as string;
        expect(filter).toContain("[Status] = 'Active'");
        expect(filter).toContain("[RelationshipType] IN ('Employee')");
        expect(filter).toContain('[EndDate] IS NULL OR [EndDate] >=');
    });

    it('prefills a create from what was typed, split into names for a person', () => {
        const strategy = new PartyLookupStrategy();
        expect(strategy.CreateDefaults(context({ Query: 'Northwind Energy' }))).toEqual({ Name: 'Northwind Energy' });

        const people = context({ RelatedEntity: { Name: PEOPLE, PrimaryKeys: [{}] }, Query: 'Dana Reed' });
        expect(strategy.CreateDefaults(people)).toEqual({ FirstName: 'Dana', LastName: 'Reed' });

        const single = context({ RelatedEntity: { Name: PEOPLE, PrimaryKeys: [{}] }, Query: 'Reed' });
        expect(strategy.CreateDefaults(single)).toEqual({ LastName: 'Reed' });
        expect(strategy.CreateDefaults(context({ Query: '   ' }))).toEqual({});
    });
});
