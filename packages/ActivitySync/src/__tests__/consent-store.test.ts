import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { IMetadataProvider, RunViewParams, UserInfo } from '@memberjunction/core';

const H = vi.hoisted(() => ({
    runViewCalls: [] as RunViewParams[],
    runViewsCalls: [] as RunViewParams[][],
    runViewHandler: vi.fn(),
    runViewsHandler: vi.fn(),
}));

vi.mock('@memberjunction/core', () => ({
    RunView: {
        FromMetadataProvider: () => ({
            RunView: async (params: RunViewParams) => {
                H.runViewCalls.push(params);
                return H.runViewHandler(params);
            },
            RunViews: async (requests: RunViewParams[]) => {
                H.runViewsCalls.push(requests);
                return H.runViewsHandler(requests);
            },
        }),
    },
}));

import { DatabaseConsentStore } from '../consent-store.js';

const CONN_A = '11111111-1111-1111-1111-111111111111';
const CONN_B = '22222222-2222-2222-2222-222222222222';
const RUN_A = '33333333-3333-3333-3333-333333333333';
const RUN_B = '44444444-4444-4444-4444-444444444444';
const TYPE_EMAIL = '55555555-5555-5555-5555-555555555555';
const ACT_1 = '66666666-6666-6666-6666-666666666666';

const PROVIDER = {} as IMetadataProvider;
const USER = { ID: '77777777-7777-7777-7777-777777777777' } as UserInfo;

describe('DatabaseConsentStore RLS-safe reads', () => {
    beforeEach(() => {
        H.runViewCalls.length = 0;
        H.runViewsCalls.length = 0;
        H.runViewHandler.mockReset();
        H.runViewsHandler.mockReset();
    });

    it('ConsentedActivities batches runs + activity types via RunViews and uses zero raw vw* SQL subqueries', async () => {
        H.runViewsHandler.mockResolvedValueOnce([
            { Success: true, Results: [{ ID: RUN_A }] },
            { Success: true, Results: [{ ID: TYPE_EMAIL }] },
        ]);
        H.runViewHandler
            .mockResolvedValueOnce({
                Success: true,
                Results: [
                    {
                        ExternalID: '<msg-1@example.com>',
                        ActivitySyncRunID: RUN_A,
                        Decision: 'Included',
                        Reason: 'Tagged "AIDP"',
                        __mj_CreatedAt: '2026-11-01T10:00:00Z',
                    },
                ],
            })
            .mockResolvedValueOnce({
                Success: true,
                Results: [
                    {
                        ID: ACT_1,
                        ExternalID: '<msg-1@example.com>',
                        ExternalThreadID: 'thread-1',
                        Details: null,
                    },
                ],
            });

        const store = new DatabaseConsentStore(PROVIDER, USER);
        const res = await store.ConsentedActivities({ ConnectionID: CONN_A, TypeCode: 'Email' });

        expect(res.Failed).toBe(false);
        if (!res.Failed) {
            expect(res.Value).toHaveLength(1);
            expect(res.Value[0].ActivityID).toBe(ACT_1);
        }
        expect(H.runViewsCalls).toHaveLength(1);
        expect(H.runViewsCalls[0]).toHaveLength(2);
        for (const call of [...H.runViewsCalls.flat(), ...H.runViewCalls]) {
            expect(call.ExtraFilter ?? '').not.toMatch(/\bSELECT\b/i);
            expect(call.CacheLocal).toBe(false);
        }
    });

    it('ConsentedElsewhere resolves other connections with two-step RunView reads and zero raw SQL subqueries', async () => {
        H.runViewHandler
            .mockResolvedValueOnce({
                Success: true,
                Results: [
                    {
                        ExternalID: '<msg-1@example.com>',
                        ActivitySyncRunID: RUN_A,
                        Decision: 'Included',
                        Reason: null,
                        __mj_CreatedAt: '2026-11-01T11:00:00Z',
                    },
                    {
                        ExternalID: '<msg-1@example.com>',
                        ActivitySyncRunID: RUN_B,
                        Decision: 'Duplicate',
                        Reason: null,
                        __mj_CreatedAt: '2026-11-01T10:00:00Z',
                    },
                ],
            })
            .mockResolvedValueOnce({
                Success: true,
                Results: [{ ID: RUN_B, ActivitySyncConnectionID: CONN_B }],
            });

        const store = new DatabaseConsentStore(PROVIDER, USER);
        const res = await store.ConsentedElsewhere(['<msg-1@example.com>'], CONN_A);

        expect(res.Failed).toBe(false);
        if (!res.Failed) {
            expect(res.Value.has('<msg-1@example.com>')).toBe(true);
        }
        expect(H.runViewCalls).toHaveLength(2);
        for (const call of H.runViewCalls) {
            expect(call.ExtraFilter ?? '').not.toMatch(/\bSELECT\b/i);
            expect(call.CacheLocal).toBe(false);
        }
    });
});
