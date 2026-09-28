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
 * The end-to-end block then runs that payload through the real `LogActivityAction` and
 * `ActivityWriter` (database faked) and asserts the Activity and its Regarding link are written.
 *
 * The payload is built as MJ's contract says it should be (Name → Value, redacted params absent).
 * MJ's own param-shape bug on this path — params stored as an array and re-read as an object —
 * breaks every binding and is tracked in MemberJunction/MJ#4794.
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { beforeEach, describe, expect, it, vi } from 'vitest';

// A fake database behind Metadata.Provider: the action takes an independent instance of it (#195)
// and the real ActivityWriter saves through that instance, so the test can see what was written.
const H = vi.hoisted(() => {
    const saved: Array<{ Entity: string; Row: Record<string, unknown> }> = [];
    let nextID = 0;
    const own = {
        Entities: [
            { Name: 'MJ_BizApps_Common: People', ID: 'entity-people' },
            { Name: 'MJ_BizApps_Common: Organizations', ID: 'entity-organizations' },
        ],
        BeginEntityTransaction: async () => ({ Commit: async () => undefined, Rollback: async () => undefined }),
        GetEntityObject: async (entity: string) => {
            const row: Record<string, unknown> = {
                NewRecord: () => undefined,
                Save: async () => {
                    row.ID = row.ID ?? `row-${++nextID}`;
                    saved.push({ Entity: entity, Row: row });
                    return true;
                },
            };
            return row;
        },
        ReleaseIndependentInstance: vi.fn(async () => undefined),
    };
    const shared = { BeginEntityTransaction: () => undefined, CreateIndependentInstance: async () => own };
    return { saved, own, shared, logError: vi.fn() };
});

vi.mock('@memberjunction/core', async (importOriginal) => ({
    ...(await importOriginal<object>()),
    Metadata: {
        get Provider() {
            return H.shared;
        },
    },
    RunView: class {
        public async RunView(params: { ExtraFilter?: string }) {
            // ActivityType lookup finds the seeded type; the dedupe lookup finds nothing yet.
            return params.ExtraFilter?.startsWith('Code =')
                ? { Success: true, Results: [{ ID: 'type-system-event' }] }
                : { Success: true, Results: [] };
        }
    },
    LogError: H.logError,
}));

vi.mock('@memberjunction/actions', () => ({ BaseAction: class {} }));

import { IsRedactedParam, RedactParams, type ActionParam, type ActionResultSimple, type RunActionParams } from '@memberjunction/actions-base';
import type { UserInfo } from '@memberjunction/core';
import type { MJActionParamEntity, MJEntityActionParamEntity } from '@memberjunction/core-entities';
import { ParseLogActivityParams } from '@mj-biz-apps/common-activity-sync';
import { LogActivityAction } from '../custom/log-activity.action';

interface MetadataRecord {
    fields: Record<string, string | number | boolean | null>;
    primaryKey?: { ID: string };
    deleteRecord?: { delete: boolean };
    relatedEntities?: Record<string, MetadataRecord[]>;
}

const RECORD_ID = '11111111-2222-3333-4444-555555555555';
const FAKE_RECORD: Record<string, string> = { ID: RECORD_ID, Status: 'Active' };

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
    // RedactParams reads only ID / Name / LogValue off a definition. LogValue is the shipped value, not a
    // stand-in: redaction rule 3 strips a param whose definition says LogValue = false (Description does).
    return (action.relatedEntities?.['MJ: Action Params'] ?? []).map(
        (p) => ({ ID: p.primaryKey?.ID, Name: p.fields.Name, LogValue: p.fields.LogValue !== false }) as MJActionParamEntity,
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
                    LogValue: (p.fields.LogValue as boolean | undefined) ?? null,
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
        it(`${key} delivers every param it binds — none is redacted out of the task payload`, () => {
            const rows = bindingRows(binding);
            const runtime: ActionParam[] = rows.map((row) => ({
                Name: defs.find((d) => d.ID?.toUpperCase() === row.ActionParamID.toUpperCase())?.Name ?? row.ActionParamID,
                Value: resolveValue(row),
                Type: 'Input',
            }));
            const redacted = RedactParams(runtime, defs, rows).filter(IsRedactedParam).map((p) => `${p.Name} (${p.Reason})`);
            expect(redacted).toEqual([]);
        });

        it(`${key} parses from its redacted payload with a Regarding link`, () => {
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

class TestableAction extends LogActivityAction {
    public Run(params: RunActionParams): Promise<ActionResultSimple> {
        return this.InternalRunAction(params);
    }
}

function runParamsFrom(payload: Record<string, unknown>): RunActionParams {
    const Params: ActionParam[] = Object.entries(payload).map(([Name, Value]) => ({ Name, Value, Type: 'Input' }));
    const ContextUser: Pick<UserInfo, 'ID'> = { ID: 'automation-user' };
    const params: Pick<RunActionParams, 'Params' | 'ContextUser'> = { Params, ContextUser: ContextUser as UserInfo };
    return params as RunActionParams;
}

describe('durable Common.LogActivity writes the activity end to end (#197)', () => {
    beforeEach(() => {
        H.saved.length = 0;
        H.logError.mockClear();
        H.own.ReleaseIndependentInstance.mockClear();
    });

    for (const binding of durableBindings) {
        const entityName = lookupName(binding.fields.EntityID);
        const invocation = lookupName(
            binding.relatedEntities?.['MJ: Entity Action Invocations']?.[0]?.fields.InvocationTypeID ?? '',
        );

        it(`${entityName}|${invocation} writes an Activity with a Regarding link to the record`, async () => {
            const result = await new TestableAction().Run(runParamsFrom(durablePayload(bindingRows(binding), defs)));

            expect(result.Success).toBe(true);
            expect(H.logError).not.toHaveBeenCalled();

            const activity = H.saved.find((s) => s.Entity.endsWith('Activities'));
            expect(activity?.Row.ActivityTypeID).toBe('type-system-event');
            const link = H.saved.find((s) => s.Entity.endsWith('Activity Links'));
            expect(link?.Row).toMatchObject({
                ActivityID: activity?.Row.ID,
                Role: 'Regarding',
                EntityID: H.own.Entities.find((e) => e.Name === entityName)?.ID,
                RecordID: RECORD_ID,
            });
            expect(H.own.ReleaseIndependentInstance).toHaveBeenCalledTimes(1);
        });
    }
});
