/**
 * `Common.LogActivity` — the declarative entry point to the unified timeline.
 *
 * The keystone of the Entity Action adoption plan (plans/mj-entity-action-workflow-adoption.md
 * §3.1): any app binds `AfterCreate` / `AfterUpdate` on any entity to this action and the record's
 * lifecycle appears on a person's or organization's timeline with no code in the consuming app.
 *
 * It WRAPS `ActivityWriter` (§3.2 — one writer, two entry points), never writes its own rows, and
 * takes only serializable params. A `Durable` binding must pass only `Static` / `Entity Field`
 * values (e.g. `RecordID` via Entity Field `ID`): redaction always strips whole-record values from
 * the durable task payload. `RecordData` (`'Entity Object Data'`, never `'Entity Object'` — a
 * BaseEntity serializes to `{}` silently, §3.3) is only for `LinkFields` on inline bindings.
 *
 * The write runs on an independent provider instance, never the process-global one (#195).
 */
import { BaseAction } from '@memberjunction/actions';
import type { ActionParam, ActionResultSimple, RunActionParams } from '@memberjunction/actions-base';
import { LogError, Metadata, type UserInfo } from '@memberjunction/core';
import { RegisterClass } from '@memberjunction/global';
import {
    ActivityWriter,
    IsDatabaseProvider,
    ParseLogActivityParams,
    type WriteActivityResult,
    type WriteManualActivityInput,
} from '@mj-biz-apps/common-activity-sync';

function setOutput(params: RunActionParams, name: string, value: unknown): void {
    const existing = params.Params?.find((p) => p.Name?.toLowerCase() === name.toLowerCase());
    if (existing) {
        existing.Value = value;
        return;
    }
    params.Params = params.Params ?? [];
    params.Params.push({ Name: name, Value: value, Type: 'Output' } as ActionParam);
}

function paramValues(params: RunActionParams): Record<string, unknown> {
    const values: Record<string, unknown> = {};
    for (const param of params.Params ?? []) {
        if (param.Name) values[param.Name] = param.Value;
    }
    return values;
}

/** "which record, for whom" — read from the raw params so it is available even when parsing failed. */
function describeTarget(params: RunActionParams): string {
    const values = paramValues(params);
    const recordData = values.RecordData;
    const recordDataID =
        recordData !== null && typeof recordData === 'object' && 'ID' in recordData
            ? (recordData as { ID: unknown }).ID
            : undefined;
    const entityName = values.EntityName ?? '(none)';
    const recordID = values.RecordID ?? recordDataID ?? '(none)';
    return `EntityName=${String(entityName)}, RecordID=${String(recordID)}, ContextUser=${params.ContextUser?.ID ?? '(none)'}`;
}

@RegisterClass(BaseAction, 'Common.LogActivity')
export class LogActivityAction extends BaseAction {
    protected async InternalRunAction(params: RunActionParams): Promise<ActionResultSimple> {
        let result: ActionResultSimple;
        try {
            result = await this.log(params);
        } catch (error) {
            result = {
                Success: false,
                ResultCode: 'ERROR',
                Message: `LogActivity failed: ${error instanceof Error ? error.message : String(error)}`,
            };
        }
        // A durable run's failure otherwise lives only on its Task row, where nobody looks (#197).
        if (!result.Success) {
            LogError(`[Common.LogActivity] ${result.Message} (${describeTarget(params)})`);
        }
        return result;
    }

    private async log(params: RunActionParams): Promise<ActionResultSimple> {
        if (!params.ContextUser) {
            return { Success: false, ResultCode: 'VALIDATION_ERROR', Message: 'ContextUser is required.' };
        }

        const parsed = ParseLogActivityParams(paramValues(params));
        if (!parsed.Input) {
            return {
                Success: false,
                ResultCode: 'VALIDATION_ERROR',
                Message: `LogActivity input is invalid: ${parsed.Errors.join(' | ')}`,
            };
        }

        const result = await this.writeOnOwnProvider(parsed.Input, params.ContextUser);
        setOutput(params, 'ActivityID', result.ActivityID);
        setOutput(params, 'AlreadyPresent', result.AlreadyPresent);

        if (!result.Success) {
            return {
                Success: false,
                ResultCode: 'ERROR',
                Message: `The activity could not be written: ${result.Issues.join(' | ')}`,
            };
        }
        return {
            Success: true,
            ResultCode: result.AlreadyPresent ? 'ALREADY_PRESENT' : 'SUCCESS',
            Message: result.AlreadyPresent
                ? `An activity with this SourceSystem/ExternalID already exists (${result.ActivityID}).`
                : `Activity ${result.ActivityID} written with ${result.Links.length} link(s).`,
        };
    }

    /**
     * Metadata.Provider is process-global: a transaction opened on it captures every concurrent
     * caller's queries (#195). Never switch this to params.Provider either — the entity-action run is
     * detached from the save, and the caller may release that instance mid-write.
     */
    private async writeOnOwnProvider(
        input: WriteManualActivityInput,
        contextUser: UserInfo,
    ): Promise<WriteActivityResult> {
        const shared = Metadata.Provider;
        if (!IsDatabaseProvider(shared)) {
            throw new Error('Common.LogActivity is server-only: Metadata.Provider cannot open transactions.');
        }
        const own = await shared.CreateIndependentInstance();
        try {
            return await new ActivityWriter().WriteManual(input, own, contextUser);
        } finally {
            await own.ReleaseIndependentInstance(); // rolls back anything left open; never closes the shared pool
        }
    }
}

export function LoadLogActivityAction(): void {
    void LogActivityAction;
}
