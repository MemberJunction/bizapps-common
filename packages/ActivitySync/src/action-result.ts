/**
 * Map a fleet run onto the Common.SyncActivities Action result codes.
 *
 * Lives next to FleetRunResult so the Action cannot re-invent a success path the engine
 * already marked failed. The load-failed case (Success=false, ConnectionsAttempted=0) is
 * not "no connections" — that is the same class of bug as treating a failed ViewLoad as [].
 */

export interface FleetSurfaceResult {
    Fetched: number;
    Included: number;
    Duplicates: number;
    Excluded: number;
    Failed: number;
}

export interface FleetLike {
    Success: boolean;
    ConnectionsAttempted: number;
    Issues: readonly string[];
    Results: ReadonlyArray<{ Result: FleetSurfaceResult }>;
}

export interface FleetTotals {
    Fetched: number;
    Written: number;
    Duplicates: number;
    Excluded: number;
    Failed: number;
}

export type SyncActionResultCode = 'SUCCESS' | 'PARTIAL' | 'NO_CONNECTIONS' | 'ERROR';

export interface SyncActionResult {
    Success: boolean;
    ResultCode: SyncActionResultCode;
    Message: string;
}

export function TotalsFromFleet(fleet: FleetLike): FleetTotals {
    return fleet.Results.reduce(
        (sum, run) => ({
            Fetched: sum.Fetched + run.Result.Fetched,
            Written: sum.Written + run.Result.Included,
            Duplicates: sum.Duplicates + run.Result.Duplicates,
            Excluded: sum.Excluded + run.Result.Excluded,
            Failed: sum.Failed + run.Result.Failed,
        }),
        { Fetched: 0, Written: 0, Duplicates: 0, Excluded: 0, Failed: 0 },
    );
}

export function ActionResultFromFleet(fleet: FleetLike, totals: FleetTotals): SyncActionResult {
    if (!fleet.Success && fleet.ConnectionsAttempted === 0) {
        return {
            Success: false,
            ResultCode: 'ERROR',
            Message: fleet.Issues.length
                ? fleet.Issues.join(' | ')
                : 'Activity sync failed before any connection was attempted.',
        };
    }
    if (fleet.ConnectionsAttempted === 0) {
        return {
            Success: true,
            ResultCode: 'NO_CONNECTIONS',
            Message: 'No Active activity-sync connection exists, so nothing was read.',
        };
    }
    return {
        Success: fleet.Success,
        ResultCode: fleet.Success ? 'SUCCESS' : 'PARTIAL',
        Message:
            `${fleet.ConnectionsAttempted} connection(s): fetched ${totals.Fetched}, ` +
            `written ${totals.Written}, duplicates ${totals.Duplicates}, ` +
            `excluded ${totals.Excluded}, failed ${totals.Failed}.` +
            (fleet.Issues.length ? ` Issues: ${fleet.Issues.join(' | ')}` : ''),
    };
}
