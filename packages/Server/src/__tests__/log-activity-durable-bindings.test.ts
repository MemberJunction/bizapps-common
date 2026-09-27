/**
 * Regression guard for #197: every DURABLE `Common.LogActivity` binding shipped in metadata/ must
 * still parse after its params go through the redaction a durable dispatch applies.
 *
 * A durable binding's params reach the task as `Task.InputPayload`, which MJ builds with
 * `RedactParams` — and its rule 1 strips whole-record ValueTypes ('Entity Object Data') no matter
 * what. A binding that needs `RecordData` therefore works inline and fails on every durable run.
 * This test replays the binding the way MJ's EntityActionInvocationTypes resolves it, redacts it the
 * way the durable path does, and asks the real parser whether the action could run.
 *
 * It models the redaction only, not MJ's param-shape bug on the same path (params stored as an
 * array and re-read as an object, MJ-side) — that one breaks every binding and is fixed in MJ.
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { IsRedactedParam, RedactParams, type ActionParam } from '@memberjunction/actions-base';
import type { MJActionParamEntity, MJEntityActionParamEntity } from '@memberjunction/core-entities';
import { ParseLogActivityParams } from '@mj-biz-apps/common-activity-sync';

interface MetadataRecord {
    fields: Record<string, string | number | boolean | null>;
    primaryKey?: { ID: string };
    deleteRecord?: { delete: boolean };
    relatedEntities?: Record<string, MetadataRecord[]>;
}

/**
 * Durable LogActivity bindings known to need RecordData (they route links with `LinkFields`). They
 * cannot be fixed by binding the id alone; `it.fails` keeps them visible and flips red the day one
 * becomes durable-safe, so it has to be taken off this list deliberately.
 */
const KNOWN_DURABLE_UNSAFE = new Set([
    'MJ_BizApps_Common: Relationships|AfterCreate',
    'MJ_BizApps_Common: Relationships|AfterUpdate',
]);

const RECORD_ID = '11111111-2222-3333-4444-555555555555';
const FAKE_RECORD: Record<string, string> = {
    ID: RECORD_ID,
    Status: 'Active',
    FromPersonID: '22222222-3333-4444-5555-666666666666',
    ToOrganizationID: '33333333-4444-5555-6666-777777777777',
};

function loadMetadata(relativePath: string): MetadataRecord[] {
    const path = fileURLToPath(new URL(`../../../../metadata/${relativePath}`, import.meta.url));
    return JSON.parse(readFileSync(path, 'utf8')) as MetadataRecord[];
}

function lookupName(value: string | number | boolean | null): string {
    return String(value).split('=').pop() ?? '';
}

function logActivityParamDefinitions(): MJActionParamEntity[] {
    const action = loadMetadata('actions/.common-actions.json').find((a) => a.fields.Name === 'Common.LogActivity');
    if (!action) throw new Error('Common.LogActivity is missing from metadata/actions/.common-actions.json');
    // RedactParams reads only ID / Name / LogValue off a definition.
    return (action.relatedEntities?.['MJ: Action Params'] ?? []).map(
        (p) => ({ ID: p.primaryKey?.ID, Name: p.fields.Name, LogValue: true }) as MJActionParamEntity,
    );
}

/** Live (not deleted) binding rows, typed as MJ reads them. */
function bindingRows(binding: MetadataRecord): MJEntityActionParamEntity[] {
    return (binding.relatedEntities?.['MJ: Entity Action Params'] ?? [])
        .filter((p) => p.deleteRecord?.delete !== true)
        .map(
            (p) =>
                ({
                    ActionParamID: String(p.fields.ActionParamID),
                    ValueType: p.fields.ValueType as MJEntityActionParamEntity['ValueType'],
                    Value: (p.fields.Value as string | undefined) ?? null,
                    LogValue: null,
                }) as MJEntityActionParamEntity,
        );
}

/** Mirrors EntityActionInvocationTypes' param resolution for the ValueTypes these bindings use. */
function resolveValue(row: MJEntityActionParamEntity): unknown {
    switch (row.ValueType) {
        case 'Static':
            try {
                return JSON.parse(row.Value ?? '') as unknown;
            } catch {
                return row.Value; // a scalar Static value is not JSON — MJ passes it through as-is
            }
        case 'Entity Field':
            return FAKE_RECORD[row.Value ?? ''];
        case 'Entity Object Data':
            return { ...FAKE_RECORD };
        default:
            throw new Error(`Test does not model ValueType '${row.ValueType}'.`);
    }
}

function durablePayload(rows: MJEntityActionParamEntity[], defs: MJActionParamEntity[]): Record<string, unknown> {
    const runtime: ActionParam[] = rows.map((row) => {
        const def = defs.find((d) => d.ID?.toUpperCase() === row.ActionParamID.toUpperCase());
        if (!def) throw new Error(`Binding param ${row.ActionParamID} has no Common.LogActivity definition.`);
        return { Name: def.Name, Value: resolveValue(row), Type: 'Input' };
    });
    const payload: Record<string, unknown> = {};
    for (const p of RedactParams(runtime, defs, rows)) {
        if (!IsRedactedParam(p)) payload[p.Name] = p.Value; // a redacted param arrives absent
    }
    return payload;
}

const defs = logActivityParamDefinitions();
const durableBindings = loadMetadata('entity-actions/.common-entity-actions.json').filter(
    (b) => lookupName(b.fields.ActionID) === 'Common.LogActivity' && b.fields.RunMode === 'Durable',
);

describe('durable Common.LogActivity bindings survive redaction (#197)', () => {
    it('ships at least one durable LogActivity binding to check', () => {
        expect(durableBindings.length).toBeGreaterThan(0);
    });

    for (const binding of durableBindings) {
        const entityName = lookupName(binding.fields.EntityID);
        const invocation = lookupName(
            binding.relatedEntities?.['MJ: Entity Action Invocations']?.[0]?.fields.InvocationTypeID ?? '',
        );
        const key = `${entityName}|${invocation}`;
        const test = KNOWN_DURABLE_UNSAFE.has(key) ? it.fails : it;

        test(`${key} parses from its redacted payload with a Regarding link`, () => {
            const rows = bindingRows(binding);
            const parsed = ParseLogActivityParams(durablePayload(rows, defs));

            expect(parsed.Errors).toEqual([]);
            expect(parsed.Input?.Links?.[0]).toEqual({ Role: 'Regarding', EntityName: entityName, RecordID: RECORD_ID });
            const eventKeyDef = defs.find((d) => d.Name === 'EventKey');
            if (rows.some((r) => r.ActionParamID.toUpperCase() === eventKeyDef?.ID?.toUpperCase())) {
                expect(parsed.Input?.ExternalID).toContain(RECORD_ID);
            }
        });
    }
});
