/**
 * `Common.GetPartySignals` — the server-side union of every `Party Signals` query.
 *
 * Explorer's party pickers use the client store, which does this in the browser. This action is
 * the same answer for everything that is not Angular: Skip, agents, MCP, and any report or script
 * that needs to know which organizations and people are customers. One definition of "customer",
 * discovered from metadata rather than hard-coded, so the two can never drift.
 *
 * Runs every query as the CALLING user, so the roster a caller gets back is the one their
 * permissions allow. A query the user cannot read contributes nothing and is named in `Warnings`
 * — a missing signal degrades ranking, it does not fail the call.
 */
import { BaseAction } from '@memberjunction/actions';
import type { ActionParam, ActionResultSimple, RunActionParams } from '@memberjunction/actions-base';
import { RunQuery, type UserInfo } from '@memberjunction/core';
import { QueryEngine } from '@memberjunction/core-entities';
import { RegisterClass } from '@memberjunction/global';
import {
    MergePartySignalRows,
    ParseSignalNouns,
    PARTY_SIGNALS_CATEGORY,
    type PartySignalRow,
    type PartySignalSource,
} from '@mj-biz-apps/common-entities';

function setOutput(params: RunActionParams, name: string, value: unknown): void {
    const existing = params.Params?.find((p) => p.Name?.toLowerCase() === name.toLowerCase());
    if (existing) {
        existing.Value = value;
        return;
    }
    params.Params = params.Params ?? [];
    params.Params.push({ Name: name, Value: value, Type: 'Output' } as ActionParam);
}

@RegisterClass(BaseAction, 'Common.GetPartySignals')
export class GetPartySignalsAction extends BaseAction {
    protected async InternalRunAction(params: RunActionParams): Promise<ActionResultSimple> {
        if (!params.ContextUser) {
            return { Success: false, ResultCode: 'VALIDATION_ERROR', Message: 'ContextUser is required.' };
        }
        try {
            return await this.union(params, params.ContextUser);
        } catch (error) {
            return {
                Success: false,
                ResultCode: 'ERROR',
                Message: `GetPartySignals failed: ${messageOf(error)}`,
            };
        }
    }

    private async union(params: RunActionParams, user: UserInfo): Promise<ActionResultSimple> {
        const warnings: string[] = [];
        await QueryEngine.Instance.Config(false, user);
        const queries = QueryEngine.Instance.Queries.filter((query) => query.Category === PARTY_SIGNALS_CATEGORY);
        const sources = await Promise.all(queries.map((query) => this.runSource(query.ID, query.Name, query.Description, user, warnings)));

        const roster = MergePartySignalRows(sources);
        setOutput(params, 'Roster', JSON.stringify(roster));
        setOutput(params, 'Warnings', JSON.stringify(warnings));

        return {
            Success: true,
            ResultCode: 'SUCCESS',
            Message: `${roster.length} part${roster.length === 1 ? 'y' : 'ies'} from ${sources.length} signal quer${sources.length === 1 ? 'y' : 'ies'}`
                + `${warnings.length > 0 ? `, ${warnings.length} unavailable` : ''}.`,
        };
    }

    private async runSource(
        id: string,
        name: string,
        description: string | null,
        user: UserInfo,
        warnings: string[],
    ): Promise<PartySignalSource> {
        const source: PartySignalSource = { QueryKey: name, ...ParseSignalNouns(description), Rows: [] };
        try {
            const result = await new RunQuery().RunQuery({ QueryID: id }, user);
            if (result.Success) {
                source.Rows = (result.Results as PartySignalRow[]) ?? [];
            } else {
                warnings.push(`${name}: ${result.ErrorMessage ?? 'failed'}`);
            }
        } catch (error) {
            warnings.push(`${name}: ${messageOf(error)}`);
        }
        return source;
    }
}

function messageOf(error: unknown): string {
    return error instanceof Error ? error.message : String(error);
}

export function LoadGetPartySignalsAction(): void {
    void GetPartySignalsAction;
}
