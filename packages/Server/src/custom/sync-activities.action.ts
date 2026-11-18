/**
 * `Common.SyncActivities` — the MJ Action a ScheduledJob fires hourly.
 *
 * Run by hand with `DryRun = true` (and optionally `ConnectionIDs`) it previews what each connection
 * would file, Paused ones included, writing only the run and its per-item decisions.
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
const P_DRY_RUN = 'DryRun';
const P_CONNECTION_IDS = 'ConnectionIDs';
const DEFAULT_LIMIT = 100;

function readParam(params: RunActionParams, name: string): unknown {
    return params.Params?.find((p) => p.Name?.toLowerCase() === name.toLowerCase())?.Value;
}

/** `true`, `'true'` or `'1'`. Anything else, absence included, is a live run. */
export function ReadDryRun(raw: unknown): boolean {
    if (typeof raw === 'boolean') return raw;
    const text = typeof raw === 'string' ? raw.trim().toLowerCase() : '';
    return text === 'true' || text === '1';
}

/** A comma-separated string or an array; blanks dropped. The engine rejects anything that is not a UUID. */
export function ReadConnectionIDs(raw: unknown): string[] {
    const parts = Array.isArray(raw) ? raw : typeof raw === 'string' ? raw.split(',') : [];
    return parts.map((p) => String(p).trim()).filter((p) => p.length > 0);
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
        const dryRun = ReadDryRun(readParam(params, P_DRY_RUN));
        // A dry run is a person previewing a connection; the hourly job never passes one.
        const options: SyncRunOptions = {
            DryRun: dryRun,
            TriggerType: dryRun ? 'Manual' : 'Scheduled',
            Limit: limit,
            ConnectionIDs: ReadConnectionIDs(readParam(params, P_CONNECTION_IDS)),
        };
        const fleet = await this.runOnOwnProvider(options, params.ContextUser);
        const totals = TotalsFromFleet(fleet);
        setOutput(params, 'DryRun', dryRun);
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
