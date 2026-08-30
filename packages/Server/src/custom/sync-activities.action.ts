/**
 * `Common.SyncActivities` — the MJ Action a ScheduledJob fires hourly.
 *
 * Downstream apps do not wrap this. They register a BaseActivitySyncExtension
 * (Sales.DealLinker) which the engine runs inside the write transaction.
 */
import { BaseAction } from '@memberjunction/actions';
import type { ActionParam, ActionResultSimple, RunActionParams } from '@memberjunction/actions-base';
import { Metadata } from '@memberjunction/core';
import { RegisterClass } from '@memberjunction/global';
import { ActivitySyncEngine } from '@mj-biz-apps/common-activity-sync';

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
        const fleet = await new ActivitySyncEngine().RunConnections(
            { DryRun: false, TriggerType: 'Scheduled', Limit: limit },
            Metadata.Provider,
            params.ContextUser,
        );
        const totals = fleet.Results.reduce(
            (sum, run) => ({
                Fetched: sum.Fetched + run.Result.Fetched,
                Written: sum.Written + run.Result.Included,
                Duplicates: sum.Duplicates + run.Result.Duplicates,
                Excluded: sum.Excluded + run.Result.Excluded,
                Failed: sum.Failed + run.Result.Failed,
            }),
            { Fetched: 0, Written: 0, Duplicates: 0, Excluded: 0, Failed: 0 },
        );
        setOutput(params, 'ConnectionsAttempted', fleet.ConnectionsAttempted);
        setOutput(params, 'Fetched', totals.Fetched);
        setOutput(params, 'Written', totals.Written);
        setOutput(params, 'Duplicates', totals.Duplicates);
        setOutput(params, 'Excluded', totals.Excluded);
        setOutput(params, 'Failed', totals.Failed);
        setOutput(params, 'Issues', JSON.stringify(fleet.Issues));
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
}

export function LoadSyncActivitiesAction(): void {
    void SyncActivitiesAction;
}
