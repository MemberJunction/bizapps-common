/**
 * Regression guard for the People·AfterUpdate `Execute Agent` binding (#197's sibling): it is
 * Durable, so its params reach the agent through `Task.InputPayload`, which MJ builds with
 * `RedactParams`. Redaction rule 1 always strips whole-record ValueTypes, so a `Data` bound as
 * 'Entity Object Data' reached the Person Lifecycle Changed agent as nothing at all.
 *
 * This test resolves the binding the way MJ's EntityActionInvocationTypes does (including the
 * Script ValueType), redacts it the way the durable path does, then feeds the surviving `Data`
 * through the agent step's own ActionInputMapping into the real LogActivity parser.
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { IsRedactedParam, RedactParams, type ActionParam } from '@memberjunction/actions-base';
import type { MJActionParamEntity, MJEntityActionParamEntity } from '@memberjunction/core-entities';
import { ParseLogActivityParams } from '@mj-biz-apps/common-activity-sync';

interface MetadataRecord {
    fields: Record<string, string | number | boolean | null | Record<string, string>>;
    primaryKey?: { ID: string };
    deleteRecord?: { delete: boolean };
    relatedEntities?: Record<string, MetadataRecord[]>;
}

/**
 * Execute Agent's param definitions, from MJ's metadata/actions/.execute-agent.json. They ship with
 * MJ, not this repo, so the two this binding uses are pinned here — LogValue included, because MJ
 * declares `Data` LogValue = false and redaction rule 3 then strips it from a durable payload unless
 * the binding row overrides it.
 */
const EXECUTE_AGENT_PARAMS: Record<string, { Name: string; LogValue: boolean }> = {
    '617E9E56-EF54-4D5F-8561-1D5AF245295B': { Name: 'AgentName', LogValue: true },
    'F12EF739-720B-4FD4-8B9F-0656A756502E': { Name: 'Data', LogValue: false },
};

const PERSON = {
    ID: '11111111-2222-3333-4444-555555555555',
    Status: 'Inactive',
    FirstName: 'Ada',
    Email: 'ada@example.com',
};

function loadMetadata(relativePath: string): MetadataRecord[] {
    const path = fileURLToPath(new URL(`../../../../metadata/${relativePath}`, import.meta.url));
    return JSON.parse(readFileSync(path, 'utf8')) as MetadataRecord[];
}

function lookupName(value: MetadataRecord['fields'][string]): string {
    return String(value).split('=').pop() ?? '';
}

/** Mirrors EntityActionInvocationTypes.SafeEvalScript: the body runs with `EntityActionContext`. */
async function runScript(body: string): Promise<unknown> {
    const script = new Function('EntityActionContext', `return (async () => { ${body} })();`) as (
        context: { entityObject: typeof PERSON },
    ) => Promise<unknown>;
    return script({ entityObject: PERSON });
}

async function resolveValue(row: MJEntityActionParamEntity): Promise<unknown> {
    switch (row.ValueType) {
        case 'Static':
            return row.Value;
        case 'Script':
            return runScript(row.Value ?? '');
        case 'Entity Object Data':
            return { ...PERSON };
        default:
            throw new Error(`Test does not model ValueType '${row.ValueType}'.`);
    }
}

function agentBinding(): MetadataRecord {
    const binding = loadMetadata('entity-actions/.common-entity-actions.json').find(
        (b) =>
            lookupName(b.fields.EntityID) === 'MJ_BizApps_Common: People' &&
            lookupName(b.fields.ActionID) === 'Execute Agent',
    );
    if (!binding) throw new Error('People·Execute Agent binding is missing from metadata/entity-actions.');
    return binding;
}

async function durablePayload(binding: MetadataRecord): Promise<Record<string, unknown>> {
    const rows = (binding.relatedEntities?.['MJ: Entity Action Params'] ?? [])
        .filter((p) => p.deleteRecord?.delete !== true)
        .map(
            (p) =>
                ({
                    ActionParamID: String(p.fields.ActionParamID),
                    ValueType: p.fields.ValueType as MJEntityActionParamEntity['ValueType'],
                    Value: (p.fields.Value as string | undefined) ?? null,
                    LogValue: (p.fields.LogValue as boolean | undefined) ?? null,
                }) as MJEntityActionParamEntity,
        );
    const defs = Object.entries(EXECUTE_AGENT_PARAMS).map(
        ([ID, def]) => ({ ID, Name: def.Name, LogValue: def.LogValue }) as MJActionParamEntity,
    );
    const runtime: ActionParam[] = [];
    for (const row of rows) {
        const def = EXECUTE_AGENT_PARAMS[row.ActionParamID.toUpperCase()];
        if (!def) throw new Error(`Binding param ${row.ActionParamID} is not a known Execute Agent param.`);
        runtime.push({ Name: def.Name, Value: await resolveValue(row), Type: 'Input' });
    }
    const payload: Record<string, unknown> = {};
    for (const p of RedactParams(runtime, defs, rows)) {
        if (!IsRedactedParam(p)) payload[p.Name] = p.Value; // a redacted param arrives absent
    }
    return payload;
}

/** Applies the agent step's ActionInputMapping (`static:<v>` / `data.<Field>`) to the agent's data. */
function agentLogActivityInput(data: Record<string, unknown> | undefined): Record<string, unknown> {
    const agent = loadMetadata('agents/.person-lifecycle-agent.json')[0];
    const step = agent?.relatedEntities?.['MJ: AI Agent Steps']?.find(
        (s) => lookupName(s.fields.ActionID) === 'Common.LogActivity',
    );
    const mapping = step?.fields.ActionInputMapping;
    if (!mapping || typeof mapping !== 'object') throw new Error('Agent has no LogActivity step mapping.');
    const values: Record<string, unknown> = {};
    for (const [param, source] of Object.entries(mapping)) {
        values[param] = source.startsWith('static:')
            ? source.slice('static:'.length)
            : data?.[source.replace(/^data\./, '')];
    }
    return values;
}

describe('People·AfterUpdate Execute Agent binding survives durable redaction', () => {
    it('is still a Durable binding (this guard is moot otherwise)', () => {
        expect(agentBinding().fields.RunMode).toBe('Durable');
    });

    it('delivers exactly the fields the agent reads, and no other person data', async () => {
        const payload = await durablePayload(agentBinding());
        expect(payload.AgentName).toBe('Person Lifecycle Changed');
        expect(payload.Data).toEqual({ ID: PERSON.ID, Status: PERSON.Status });
    });

    it("lets the agent's LogActivity step parse with a Regarding link to the person", async () => {
        const payload = await durablePayload(agentBinding());
        const parsed = ParseLogActivityParams(agentLogActivityInput(payload.Data as Record<string, unknown>));

        expect(parsed.Errors).toEqual([]);
        expect(parsed.Input?.Description).toBe(PERSON.Status);
        expect(parsed.Input?.Links?.[0]).toEqual({
            Role: 'Regarding',
            EntityName: 'MJ_BizApps_Common: People',
            RecordID: PERSON.ID,
        });
    });
});
