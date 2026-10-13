/**
 * Common.EnrichPeople: the scheduled entry point for person enrichment. It stays thin: parse and
 * validate params, run `PersonEnrichmentEngine` on an independent provider instance, and map the
 * result onto output params and a result code. Business logic lives in @mj-biz-apps/common-enrichment.
 *
 * Result codes: SUCCESS (Completed or MaxPeople), PARTIAL (TimeBudget or RateLimited; the rest
 * continue next run), QUOTA_EXHAUSTED, ERROR_THRESHOLD, PROVIDER_NOT_FOUND, PROVIDER_INACTIVE,
 * CREDENTIALS_NOT_FOUND, VALIDATION_ERROR, ERROR.
 *
 * Never deletes education rows: a school a vendor stops returning keeps its row with an old
 * LastVerifiedAt. Admin-only: PersonFilter is SQL, validated but trusted beyond that.
 */
import { BaseAction } from '@memberjunction/actions';
import type { ActionParam, ActionResultSimple, RunActionParams } from '@memberjunction/actions-base';
import { LogError, Metadata, type UserInfo } from '@memberjunction/core';
import { RegisterClass } from '@memberjunction/global';
import { IsDatabaseProvider } from '@mj-biz-apps/common-activity-sync';
import { EnrichmentRefusedError, PersonEnrichmentEngine, type EnrichmentStoppedReason, type PersonEnrichmentRunResult } from '@mj-biz-apps/common-enrichment';
import { ParseEnrichPeopleParams, type EnrichPeopleInput } from './enrich-people.params.js';

export type EnrichPeopleResultCode =
    | 'SUCCESS'
    | 'PARTIAL'
    | 'QUOTA_EXHAUSTED'
    | 'ERROR_THRESHOLD'
    | 'PROVIDER_NOT_FOUND'
    | 'PROVIDER_INACTIVE'
    | 'CREDENTIALS_NOT_FOUND'
    | 'VALIDATION_ERROR'
    | 'ERROR';

const OUTPUT_NAMES: (keyof PersonEnrichmentRunResult & string)[] = [
    'ProcessRunID', 'Eligible', 'EstimatedCredits', 'EstimatedCost', 'Processed', 'Matched', 'NotFound', 'Ambiguous', 'Errored',
    'EducationCreated', 'EducationUpdated', 'RelationshipsCreated', 'RelationshipsUpdated', 'RelationshipsEnded', 'OrganizationsCreated',
    'LinkedInAdded', 'CreditsConsumed', 'Cost', 'CostCurrency', 'StoppedReason',
];

function paramValues(params: RunActionParams): Record<string, unknown> {
    const out: Record<string, unknown> = {};
    for (const param of params.Params ?? []) if (param.Name) out[param.Name] = param.Value;
    return out;
}

function setOutput(params: RunActionParams, name: string, value: unknown): void {
    const existing = params.Params?.find((p) => p.Name?.toLowerCase() === name.toLowerCase());
    if (existing) { existing.Value = value; return; }
    params.Params = params.Params ?? [];
    params.Params.push({ Name: name, Value: value, Type: 'Output' } as ActionParam);
}

/** Pure: the stop reason decides the code and whether the job run shows as failed. */
export function ResultCodeFor(reason: EnrichmentStoppedReason): { Code: EnrichPeopleResultCode; Success: boolean } {
    switch (reason) {
        case 'Completed':
        case 'MaxPeople':
            return { Code: 'SUCCESS', Success: true };
        case 'TimeBudget':
        case 'RateLimited':
            return { Code: 'PARTIAL', Success: true };
        case 'QuotaExhausted':
            return { Code: 'QUOTA_EXHAUSTED', Success: false };
        case 'ErrorThreshold':
            return { Code: 'ERROR_THRESHOLD', Success: false };
    }
}

@RegisterClass(BaseAction, 'Common.EnrichPeople')
export class EnrichPeopleAction extends BaseAction {
    protected async InternalRunAction(params: RunActionParams): Promise<ActionResultSimple> {
        if (!params.ContextUser) return { Success: false, ResultCode: 'VALIDATION_ERROR', Message: 'ContextUser is required.' };
        const parsed = ParseEnrichPeopleParams(paramValues(params));
        if (!parsed.Input) return { Success: false, ResultCode: 'VALIDATION_ERROR', Message: parsed.Errors.join(' ') };
        try {
            const result = await this.runOnOwnProvider(parsed.Input, params.ContextUser);
            for (const name of OUTPUT_NAMES) setOutput(params, name, result[name]);
            const verdict = ResultCodeFor(result.StoppedReason);
            return { Success: verdict.Success, ResultCode: verdict.Code, Message: Summary(parsed.Input, result), Params: params.Params };
        } catch (error) {
            return this.failure(error);
        }
    }

    private async runOnOwnProvider(input: EnrichPeopleInput, contextUser: UserInfo): Promise<PersonEnrichmentRunResult> {
        const shared = Metadata.Provider;
        if (!IsDatabaseProvider(shared)) {
            throw new Error('Common.EnrichPeople is server-only: Metadata.Provider cannot open transactions.');
        }
        const own = await shared.CreateIndependentInstance();
        try {
            return await new PersonEnrichmentEngine().Run({ ...input, ContextUser: contextUser, MetadataProvider: own });
        } finally {
            await own.ReleaseIndependentInstance();
        }
    }

    private failure(error: unknown): ActionResultSimple {
        const message = error instanceof Error ? error.message : String(error);
        LogError(`[Common.EnrichPeople] ${message}`);
        if (error instanceof EnrichmentRefusedError) return { Success: false, ResultCode: error.Code, Message: message };
        return { Success: false, ResultCode: 'ERROR', Message: `Person enrichment failed: ${message}` };
    }
}

function Summary(input: EnrichPeopleInput, result: PersonEnrichmentRunResult): string {
    if (input.Mode === 'Preview') {
        const credits = result.EstimatedCredits == null ? 'cost unknown' : `up to ${result.EstimatedCredits} credits`;
        const cost = result.EstimatedCost == null ? '' : `, ${result.EstimatedCost} ${result.CostCurrency ?? ''}`.trimEnd();
        return `${input.ProviderCode}: ${result.Eligible} eligible, ${Math.min(result.Eligible ?? 0, input.MaxPeople)} would be sent (${credits}${cost}).`;
    }
    return `${input.ProviderCode}: processed ${result.Processed}, matched ${result.Matched}, not found ${result.NotFound}, ambiguous ${result.Ambiguous}, errored ${result.Errored}; stopped: ${result.StoppedReason}.`;
}

export function LoadEnrichPeopleAction(): void {
    void EnrichPeopleAction;
}
