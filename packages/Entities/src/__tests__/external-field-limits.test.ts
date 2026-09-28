/**
 * External field limits resolve from integration metadata rows. The engine only caches the rows, so
 * the resolution and the message are tested as pure functions over rows.
 */
import { describe, expect, it, vi } from 'vitest';
import {
    CheckExternalFieldLength,
    ExternalFieldLimitEngine,
    INTEGRATION_METADATA_UNREADABLE,
    ResolveExternalFieldLimit,
    type ExternalFieldTarget,
    type IntegrationObjectFieldRow,
    type IntegrationObjectRow,
} from '../external-field-limits.js';

const objects: IntegrationObjectRow[] = [
    { ID: 'A1B2C3D4-0000-0000-0000-000000000001', Name: 'customers', Integration: 'Bill.com' },
    { ID: 'A1B2C3D4-0000-0000-0000-000000000002', Name: 'customers', Integration: 'business-central' },
    { ID: 'A1B2C3D4-0000-0000-0000-000000000003', Name: 'journalLines', Integration: 'business-central' },
];

const fields: IntegrationObjectFieldRow[] = [
    { IntegrationObjectID: 'a1b2c3d4-0000-0000-0000-000000000001', Name: 'name', Length: 100 },
    { IntegrationObjectID: 'A1B2C3D4-0000-0000-0000-000000000002', Name: 'displayName', Length: 100 },
    { IntegrationObjectID: 'A1B2C3D4-0000-0000-0000-000000000003', Name: 'accountNumber', Length: 20 },
    { IntegrationObjectID: 'A1B2C3D4-0000-0000-0000-000000000003', Name: 'description', Length: 0 },
];

const billName: ExternalFieldTarget = { Integration: 'Bill.com', Object: 'customers', Field: 'name' };
const bcName: ExternalFieldTarget = { Integration: 'business-central', Object: 'customers', Field: 'displayName' };
const bcAccount: ExternalFieldTarget = { Integration: 'business-central', Object: 'journalLines', Field: 'accountNumber' };

describe('ResolveExternalFieldLimit', () => {
    it('returns the length of a single target', () => {
        expect(ResolveExternalFieldLimit([bcAccount], objects, fields)).toEqual({ Limit: { Length: 20, Target: bcAccount } });
    });

    it('returns the smallest length across targets, and the target that sets it', () => {
        const wide: IntegrationObjectFieldRow[] = fields.map((f) => (f.Name === 'name' ? { ...f, Length: 255 } : f));
        expect(ResolveExternalFieldLimit([billName, bcName], objects, wide)).toEqual({ Limit: { Length: 100, Target: bcName } });
    });

    it('matches integration, object and field names case-insensitively, and IDs regardless of case', () => {
        const target: ExternalFieldTarget = { Integration: 'BILL.COM', Object: 'Customers', Field: 'NAME' };
        expect(ResolveExternalFieldLimit([target], objects, fields).Limit?.Length).toBe(100);
    });

    it('reports a target whose integration or object is not installed', () => {
        const absent: ExternalFieldTarget = { Integration: 'QuickBooks', Object: 'customers', Field: 'name' };
        expect(ResolveExternalFieldLimit([bcName, absent], objects, fields)).toEqual({ Missing: [absent] });
    });

    it('reports a target whose field has no positive length', () => {
        const description: ExternalFieldTarget = { Integration: 'business-central', Object: 'journalLines', Field: 'description' };
        expect(ResolveExternalFieldLimit([description], objects, fields)).toEqual({ Missing: [description] });
    });

    it('refuses an empty target list', () => {
        expect(() => ResolveExternalFieldLimit([], objects, fields)).toThrow(/at least one target/);
    });
});

describe('CheckExternalFieldLength', () => {
    it('passes a value at the limit', () => {
        expect(CheckExternalFieldLength('Code', 'x'.repeat(20), [bcAccount], objects, fields)).toBeNull();
    });

    it('passes blank values', () => {
        expect(CheckExternalFieldLength('Code', null, [bcAccount], objects, fields)).toBeNull();
        expect(CheckExternalFieldLength('Code', '', [bcAccount], objects, fields)).toBeNull();
    });

    it('names the field, the length, the limiting target and the limit', () => {
        expect(CheckExternalFieldLength('Code', 'x'.repeat(21), [bcAccount], objects, fields)).toBe(
            'Code is 21 characters; business-central journalLines.accountNumber allows 20. Shorten it.',
        );
    });

    it('fails when a limit cannot be found, rather than passing', () => {
        const absent: ExternalFieldTarget = { Integration: 'QuickBooks', Object: 'customers', Field: 'name' };
        expect(CheckExternalFieldLength('Name', 'short', [absent], objects, fields)).toBe(
            'Name cannot be checked: no field length is recorded for QuickBooks customers.name.',
        );
    });
});

/**
 * The engine over BaseEngine's cache. Held with `Object.create` and BaseEngine's state shadowed by
 * plain properties, so `Load` is a stub and no provider is needed.
 */
describe('ExternalFieldLimitEngine', () => {
    type Loader = (params: Array<Record<string, unknown>>, provider: unknown, force: boolean, user: unknown) => Promise<void>;

    function engine(state: { loaded: boolean; constrained: boolean; load?: Loader }): ExternalFieldLimitEngine {
        const e = Object.create(ExternalFieldLimitEngine.prototype) as ExternalFieldLimitEngine;
        const data: Record<string, unknown[]> = { _objects: objects, _fields: fields };
        Object.defineProperty(e, 'Loaded', { get: () => state.loaded });
        Object.defineProperty(e, 'IsPermissionConstrained', { get: () => state.constrained });
        Object.defineProperty(e, 'GetConfigData', { value: (name: string) => data[name] });
        Object.defineProperty(e, 'Load', { value: state.load ?? (async () => undefined) });
        return e;
    }

    it('loads integration objects, and only fields with a positive length', async () => {
        const load = vi.fn<Loader>(async () => undefined);
        await engine({ loaded: false, constrained: false, load }).Config(false, undefined, undefined);
        const [params, , force] = load.mock.calls[0];
        expect(params).toEqual([
            { PropertyName: '_objects', EntityName: 'MJ: Integration Objects', ResultType: 'simple' },
            { PropertyName: '_fields', EntityName: 'MJ: Integration Object Fields', Filter: 'Length > 0', ResultType: 'simple' },
        ]);
        expect(force).toBe(false);
    });

    it('reloads when the last load was skipped for lack of permission', async () => {
        const load = vi.fn<Loader>(async () => undefined);
        await engine({ loaded: true, constrained: true, load }).Config(false, undefined, undefined);
        expect(load.mock.calls[0][2]).toBe(true);
    });

    it('refuses to check before it is configured', () => {
        const e = engine({ loaded: false, constrained: false });
        expect(() => e.Check('Code', 'x', [bcAccount])).toThrow(/not configured/);
        expect(() => e.GetLimit([bcAccount])).toThrow(/not configured/);
    });

    it('checks and returns limits from the loaded rows', () => {
        const e = engine({ loaded: true, constrained: false });
        expect(e.GetLimit([bcAccount])).toEqual({ Length: 20, Target: bcAccount });
        expect(e.Check('Code', 'x'.repeat(21), [bcAccount])).toMatch(/^Code is 21 characters/);
    });

    it('throws from GetLimit when a target has no length', () => {
        const absent: ExternalFieldTarget = { Integration: 'QuickBooks', Object: 'customers', Field: 'name' };
        expect(() => engine({ loaded: true, constrained: false }).GetLimit([absent])).toThrow(/No field length is recorded for QuickBooks customers\.name/);
    });

    it('reports that it cannot check, rather than throwing, when metadata was unreadable', () => {
        const e = engine({ loaded: true, constrained: true });
        expect(e.Check('Name', 'x', [billName])).toBe(`Name cannot be checked: ${INTEGRATION_METADATA_UNREADABLE}.`);
        expect(() => e.GetLimit([billName])).toThrow(/cannot read MJ: Integration Objects/);
    });
});
