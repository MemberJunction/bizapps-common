import { beforeEach, describe, expect, it, vi } from 'vitest';

const H = vi.hoisted(() => ({
    queries: [
        { ID: 'Q1', Name: 'Party Customer Roster', Category: 'Party Signals', Description: '[signal: order|orders]' },
        { ID: 'Q2', Name: 'Won Account Roster', Category: 'Party Signals', Description: '[signal: won deal|won deals]' },
        { ID: 'Q3', Name: 'Directory Dashboard Summary', Category: 'Common', Description: 'unrelated' },
    ],
    config: vi.fn(async () => undefined),
    runQuery: vi.fn(async (params: { QueryID: string }) => {
        if (params.QueryID === 'Q1') {
            return {
                Success: true,
                Results: [
                    { PartyKind: 'person', PartyID: 'PER-1', Count: 3, LastActivityAt: null },
                    { PartyKind: 'organization', PartyID: 'ORG-1', Count: 2, LastActivityAt: '2026-07-01' },
                ],
            };
        }
        return { Success: false, ErrorMessage: 'no read permission', Results: [] };
    }),
}));

// common-entities re-exports the generated subclasses, which extend BaseEntity, so the real
// @memberjunction/core exports have to survive the mock.
vi.mock('@memberjunction/core', async (importOriginal) => ({
    ...(await importOriginal<object>()),
    RunQuery: class {
        public RunQuery = H.runQuery;
    },
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

vi.mock('@memberjunction/actions', () => ({ BaseAction: class {} }));

import type { ActionParam, ActionResultSimple, RunActionParams } from '@memberjunction/actions-base';
import { GetPartySignalsAction } from '../custom/get-party-signals.action';

/** InternalRunAction is protected on BaseAction, as it is on every action in this package. */
class TestableAction extends GetPartySignalsAction {
    public Run(params: RunActionParams): Promise<ActionResultSimple> {
        return this.InternalRunAction(params);
    }
}

function paramsFor(overrides: Partial<RunActionParams> = {}): RunActionParams {
    return { Params: [] as ActionParam[], ContextUser: { ID: 'u1' }, ...overrides } as unknown as RunActionParams;
}

function outputOf(params: RunActionParams, name: string): unknown {
    return params.Params?.find((param) => param.Name === name)?.Value;
}

describe('GetPartySignalsAction', () => {
    beforeEach(() => {
        H.runQuery.mockClear();
        H.config.mockClear();
    });

    it('runs only the Party Signals queries and returns the merged roster', async () => {
        const params = paramsFor();
        const result = await new TestableAction().Run(params);

        expect(result.Success).toBe(true);
        expect(result.ResultCode).toBe('SUCCESS');
        expect(H.runQuery.mock.calls.map((call) => call[0].QueryID).sort()).toEqual(['Q1', 'Q2']);

        const roster = JSON.parse(String(outputOf(params, 'Roster')));
        expect(roster).toHaveLength(2);
        expect(roster.find((entry: { PartyID: string }) => entry.PartyID === 'PER-1').TotalCount).toBe(3);
        expect(roster.find((entry: { PartyID: string }) => entry.PartyID === 'ORG-1').Signals[0].NounPlural).toBe('orders');
    });

    it('reports a query it could not read as a warning rather than failing the action', async () => {
        const params = paramsFor();
        const result = await new TestableAction().Run(params);

        expect(result.Success).toBe(true);
        const warnings = JSON.parse(String(outputOf(params, 'Warnings')));
        expect(warnings).toHaveLength(1);
        expect(warnings[0]).toContain('Won Account Roster');
    });

    it('overwrites an existing output param instead of appending a second one', async () => {
        const params = paramsFor({ Params: [{ Name: 'Roster', Value: 'stale', Type: 'Output' }] as ActionParam[] });
        await new TestableAction().Run(params);
        expect(params.Params.filter((param) => param.Name === 'Roster')).toHaveLength(1);
        expect(String(outputOf(params, 'Roster'))).not.toBe('stale');
    });

    it('refuses without a context user, because the roster is permission-filtered per user', async () => {
        const result = await new TestableAction().Run(paramsFor({ ContextUser: undefined }));
        expect(result.Success).toBe(false);
        expect(result.ResultCode).toBe('VALIDATION_ERROR');
        expect(H.runQuery).not.toHaveBeenCalled();
    });

    it('fails with ERROR rather than throwing when the query engine cannot be configured', async () => {
        H.config.mockRejectedValueOnce(new Error('metadata unavailable'));
        const result = await new TestableAction().Run(paramsFor());
        expect(result.Success).toBe(false);
        expect(result.ResultCode).toBe('ERROR');
        expect(result.Message).toContain('metadata unavailable');
    });
});
