/**
 * External field limits resolve from integration metadata rows. The engine only caches the rows, so
 * the resolution and the message are tested as pure functions over rows.
 */
import { describe, expect, it } from 'vitest';
import {
    CheckExternalFieldLength,
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
            'Code is 21 characters; business-central journalLines.accountNumber allows 20. Shorten it before saving.',
        );
    });

    it('fails when a limit cannot be found, rather than passing', () => {
        const absent: ExternalFieldTarget = { Integration: 'QuickBooks', Object: 'customers', Field: 'name' };
        expect(CheckExternalFieldLength('Name', 'short', [absent], objects, fields)).toBe(
            'Name cannot be checked: no field length is recorded for QuickBooks customers.name.',
        );
    });
});
