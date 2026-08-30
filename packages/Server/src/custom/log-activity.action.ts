/**
 * `Common.LogActivity` — the declarative entry point to the unified timeline.
 *
 * The keystone of the Entity Action adoption plan (plans/mj-entity-action-workflow-adoption.md
 * §3.1): any app binds `AfterCreate` / `AfterUpdate` on any entity to this action and the record's
 * lifecycle appears on a person's or organization's timeline with no code in the consuming app.
 *
 * It WRAPS `ActivityWriter` (§3.2 — one writer, two entry points), never writes its own rows, and
 * takes only serializable params: bind `RecordData` with ValueType `'Entity Object Data'`, never
 * `'Entity Object'` (§3.3 — a BaseEntity serializes to `{}` silently).
 */
import { BaseAction } from '@memberjunction/actions';
import type { ActionParam, ActionResultSimple, RunActionParams } from '@memberjunction/actions-base';
import { Metadata } from '@memberjunction/core';
import { RegisterClass } from '@memberjunction/global';
import { ActivityWriter, ParseLogActivityParams } from '@mj-biz-apps/common-activity-sync';

function setOutput(params: RunActionParams, name: string, value: unknown): void {
    const existing = params.Params?.find((p) => p.Name?.toLowerCase() === name.toLowerCase());
    if (existing) {
        existing.Value = value;
        return;
    }
    params.Params = params.Params ?? [];
    params.Params.push({ Name: name, Value: value, Type: 'Output' } as ActionParam);
}

@RegisterClass(BaseAction, 'Common.LogActivity')
export class LogActivityAction extends BaseAction {
    protected async InternalRunAction(params: RunActionParams): Promise<ActionResultSimple> {
        try {
            return await this.log(params);
        } catch (error) {
            return {
                Success: false,
                ResultCode: 'ERROR',
                Message: `LogActivity failed: ${error instanceof Error ? error.message : String(error)}`,
            };
        }
    }

    private async log(params: RunActionParams): Promise<ActionResultSimple> {
        if (!params.ContextUser) {
            return { Success: false, ResultCode: 'VALIDATION_ERROR', Message: 'ContextUser is required.' };
        }

        const values: Record<string, unknown> = {};
        for (const param of params.Params ?? []) {
            if (param.Name) values[param.Name] = param.Value;
        }

        const parsed = ParseLogActivityParams(values);
        if (!parsed.Input) {
            return {
                Success: false,
                ResultCode: 'VALIDATION_ERROR',
                Message: `LogActivity input is invalid: ${parsed.Errors.join(' | ')}`,
            };
        }

        const result = await new ActivityWriter().WriteManual(parsed.Input, Metadata.Provider, params.ContextUser);
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
}

export function LoadLogActivityAction(): void {
    void LogActivityAction;
}
