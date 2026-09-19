import { beforeEach, describe, expect, it, vi } from 'vitest';

const H = vi.hoisted(() => ({
    queries: [
        { ID: 'Q1', Name: 'Party Customer Roster', Category: 'Party Signals', Description: 'orders [signal: order|orders]' },
        { ID: 'Q2', Name: 'Customer Roster', Category: 'Party Signals', Description: 'contracts [signal: contract|contracts]' },
        { ID: 'Q3', Name: 'Directory Dashboard Summary', Category: 'Common', Description: 'unrelated' },
    ],
    config: vi.fn(async () => undefined),
    runQuery: vi.fn(async (params: { QueryID: string }) => {
        if (params.QueryID === 'Q1') {
            return {
                Success: true,
                Results: [
                    { PartyKind: 'organization', PartyID: 'ORG-A', Count: 4, LastActivityAt: '2026-08-01' },
                    { PartyKind: 'person', PartyID: 'PER-A', Count: 1, LastActivityAt: '2026-01-01' },
                ],
            };
        }
        return { Success: false, ErrorMessage: 'no read permission', Results: [] };
    }),
}));

// The common-entities barrel pulls in the generated entity subclasses, which extend BaseEntity,
// so @memberjunction/core has to keep its real exports; only what this store calls is replaced.
vi.mock('@memberjunction/core', async (importOriginal) => ({
    ...(await importOriginal<object>()),
    Metadata: Object.assign(
        class {
            public get CurrentUser() {
                return { ID: 'u1' };
            }
        },
        { Provider: {} },
    ),
    RunQuery: class {
        public RunQuery = H.runQuery;
    },
    LogError: () => undefined,
}));

vi.mock('@memberjunction/core-entities', async (importOriginal) => ({
    ...(await importOriginal<object>()),
    QueryEngine: {
        Instance: {
            Config: H.config,
            get Queries() {
                return H.queries;
            },
        },
    },
}));

import { PartySignalStore } from '../party-signal-store';

function freshStore(): PartySignalStore {
    return PartySignalStore.Instance;
}

describe('PartySignalStore', () => {
    beforeEach(async () => {
        H.runQuery.mockClear();
        H.config.mockClear();
        await freshStore().Reset();
    });

    it('runs only the queries in the Party Signals category', async () => {
        const store = freshStore();
        await store.Load();
        expect(H.runQuery).toHaveBeenCalledTimes(2);
        expect(H.runQuery.mock.calls.map((call) => call[0].QueryID).sort()).toEqual(['Q1', 'Q2']);
    });

    it('merges the rows into a roster keyed case-insensitively by party ID', async () => {
        const store = freshStore();
        await store.Load();
        expect(store.Get('org-a')?.TotalCount).toBe(4);
        expect(store.Get('ORG-A')?.Signals[0].NounPlural).toBe('orders');
        expect(store.Get('nobody')).toBeNull();
    });

    it('separates customers by kind, most recent activity first', async () => {
        const store = freshStore();
        await store.Load();
        expect(store.Customers('organization').map((entry) => entry.PartyID)).toEqual(['ORG-A']);
        expect(store.Customers('person').map((entry) => entry.PartyID)).toEqual(['PER-A']);
    });

    it('records a query it could not read as a warning instead of failing the whole roster', async () => {
        const store = freshStore();
        await store.Load();
        expect(store.Warnings).toHaveLength(1);
        expect(store.Warnings[0]).toContain('Customer Roster');
        expect(store.Customers('organization')).toHaveLength(1);
    });

    it('loads once for concurrent callers and not again afterwards', async () => {
        const store = freshStore();
        await Promise.all([store.Load(), store.Load(), store.Load()]);
        await store.Load();
        expect(H.runQuery).toHaveBeenCalledTimes(2);
        expect(store.Loaded).toBe(true);
    });

    it('re-runs the queries on an explicit refresh and drops the previous warnings', async () => {
        const store = freshStore();
        await store.Load();
        await store.Refresh();
        expect(H.runQuery).toHaveBeenCalledTimes(4);
        expect(store.Warnings).toHaveLength(1);
    });
});
