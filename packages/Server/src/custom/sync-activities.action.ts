/**
 * `Common.SyncActivities` — the MJ Action a ScheduledJob fires hourly.
 *
 * Downstream apps do not wrap this. They register a BaseActivitySyncExtension
 * (Sales.DealLinker) which the engine runs inside the write transaction.
 *
 * The run uses an independent provider instance, never the process-global one (#195, #200).
 */
import { BaseAction } from '@memberjunction/actions';
import type { ActionParam, ActionResultSimple, RunActionParams } from '@memberjunction/actions-base';
import { Metadata, type UserInfo } from '@memberjunction/core';
import { RegisterClass } from '@memberjunction/global';
import {
    ActionResultFromFleet,
    ActivitySyncEngine,
    IsDatabaseProvider,
    TotalsFromFleet,
    type FleetRunResult,
    type SyncRunOptions,
} from '@mj-biz-apps/common-activity-sync';

const P_LIMIT = 'Limit';
const DEFAULT_LIMIT = 100;

function readParam(params: RunActionParams, name: string): unknown {
    return params.Params?.find((p) => p.Name?.toLowerCase() === name.toLowerCase())?.Value;
}

function setOutput(params: RunActionParams, name: string, value: unknown): void {
    const existing = params.Params?.find((p) => p.Name?.toLowerCase() === name.toLowerCase());
    if (existing) {
        existing.Value = value;
        return;
    }
    params.Params = params.Params ?? [];
    params.Params.push({ Name: name, Value: value, Type: 'Output' } as ActionParam);
}

@RegisterClass(BaseAction, 'Common.SyncActivities')
export class SyncActivitiesAction extends BaseAction {
    protected async InternalRunAction(params: RunActionParams): Promise<ActionResultSimple> {
        try {
            return await this.sync(params);
        } catch (error) {
            return {
                Success: false,
                ResultCode: 'ERROR',
                Message: `The activity sync failed: ${error instanceof Error ? error.message : String(error)}`,
            };
        }
    }

    private async sync(params: RunActionParams): Promise<ActionResultSimple> {
        const raw = readParam(params, P_LIMIT);
        const parsed = raw === null || raw === undefined || raw === '' ? DEFAULT_LIMIT : Number(raw);
        const limit = Number.isFinite(parsed) && parsed > 0 ? Math.floor(parsed) : DEFAULT_LIMIT;
        const fleet = await this.runOnOwnProvider(
            { DryRun: false, TriggerType: 'Scheduled', Limit: limit },
            params.ContextUser,
        );
        const totals = TotalsFromFleet(fleet);
        setOutput(params, 'ConnectionsAttempted', fleet.ConnectionsAttempted);
        setOutput(params, 'Fetched', totals.Fetched);
        setOutput(params, 'Written', totals.Written);
        setOutput(params, 'Duplicates', totals.Duplicates);
        setOutput(params, 'Excluded', totals.Excluded);
        setOutput(params, 'Failed', totals.Failed);
        setOutput(params, 'Issues', JSON.stringify(fleet.Issues));
        return ActionResultFromFleet(fleet, totals);
    }

    /**
     * Metadata.Provider is process-global: the writer's per-item transaction opened on it captures
     * every concurrent caller's queries, the scheduler's lock and release included (#195). One
     * instance serves the whole run; it shares the pool and metadata, so it holds no extra connection.
     */
    private async runOnOwnProvider(options: SyncRunOptions, contextUser: UserInfo): Promise<FleetRunResult> {
        const shared = Metadata.Provider;
        if (!IsDatabaseProvider(shared)) {
            throw new Error('Common.SyncActivities is server-only: Metadata.Provider cannot open transactions.');
        }
        const own = await shared.CreateIndependentInstance();
        try {
            return await new ActivitySyncEngine().RunConnections(options, own, contextUser);
        } finally {
            await own.ReleaseIndependentInstance(); // rolls back anything left open; never closes the shared pool
        }
    }
}

export function LoadSyncActivitiesAction(): void {
    void SyncActivitiesAction;
}
