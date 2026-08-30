import { describe, expect, it } from 'vitest';

import { ActionResultFromFleet, TotalsFromFleet, type FleetLike } from '../action-result.js';

function fleet(partial: Partial<FleetLike>): FleetLike {
    return {
        Success: true,
        ConnectionsAttempted: 0,
        Issues: [],
        Results: [],
        ...partial,
    };
}

describe('ActionResultFromFleet', () => {
    it('does not report NO_CONNECTIONS when the connection load failed', () => {
        const failed = fleet({
            Success: false,
            ConnectionsAttempted: 0,
            Issues: ['ActivitySyncConnection lookup failed.'],
        });
        const result = ActionResultFromFleet(failed, TotalsFromFleet(failed));
        expect(result.Success).toBe(false);
        expect(result.ResultCode).toBe('ERROR');
        expect(result.Message).toMatch(/lookup failed/);
        expect(result.Message).not.toMatch(/No Active/);
    });

    it('reports NO_CONNECTIONS only when the load succeeded and the list is empty', () => {
        const empty = fleet({ Success: true, ConnectionsAttempted: 0 });
        const result = ActionResultFromFleet(empty, TotalsFromFleet(empty));
        expect(result.Success).toBe(true);
        expect(result.ResultCode).toBe('NO_CONNECTIONS');
    });

    it('reports PARTIAL when a connection was attempted and the fleet failed', () => {
        const partial = fleet({
            Success: false,
            ConnectionsAttempted: 1,
            Issues: ['ContactMethod lookup failed — watermark will not advance.'],
            Results: [
                {
                    Result: { Fetched: 3, Included: 0, Duplicates: 0, Excluded: 0, Failed: 3 },
                },
            ],
        });
        const result = ActionResultFromFleet(partial, TotalsFromFleet(partial));
        expect(result.Success).toBe(false);
        expect(result.ResultCode).toBe('PARTIAL');
        expect(result.Message).toMatch(/failed 3/);
    });

    it('reports SUCCESS when every attempted connection succeeded', () => {
        const ok = fleet({
            Success: true,
            ConnectionsAttempted: 1,
            Results: [
                {
                    Result: { Fetched: 2, Included: 2, Duplicates: 0, Excluded: 0, Failed: 0 },
                },
            ],
        });
        const result = ActionResultFromFleet(ok, TotalsFromFleet(ok));
        expect(result.Success).toBe(true);
        expect(result.ResultCode).toBe('SUCCESS');
        expect(result.Message).toMatch(/written 2/);
    });
});
