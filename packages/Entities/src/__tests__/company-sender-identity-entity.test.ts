import type { EntityInfo } from '@memberjunction/core';
import { beforeEach, describe, expect, it, vi } from 'vitest';

/** The slice of `BaseEntity` the subclass depends on, backed by a plain record. */
interface SenderRecord {
    Kind: 'Domain' | 'Mailbox';
    Address: string;
    DisplayName: string | null;
    IsDefault?: boolean;
    CompanyID?: string;
}

const baseSave = vi.hoisted(() => vi.fn<(saved: Record<string, string | null>) => boolean>(() => true));

vi.mock('@memberjunction/core', async (importOriginal) => {
    const actual = await importOriginal<typeof import('@memberjunction/core')>();
    class FakeBaseEntity {
        public readonly record: Record<string, string | null> = {};
        public IsSaved = false;
        public readonly ResultHistory: InstanceType<typeof actual.BaseEntityResult>[] = [];
        public Get(name: string): string | null { return this.record[name] ?? null; }
        public Set(name: string, value: string | null): void { this.record[name] = value; }
        public Validate(): InstanceType<typeof actual.ValidationResult> {
            const result = new actual.ValidationResult();
            result.Success = true;
            return result;
        }
        public get LatestResult(): InstanceType<typeof actual.BaseEntityResult> { return this.ResultHistory[this.ResultHistory.length - 1]; }
        public RegisterResultHistoryEntry(result: InstanceType<typeof actual.BaseEntityResult>): void { this.ResultHistory.push(result); }
        public async Save(): Promise<boolean> { return baseSave({ ...this.record }); }
    }
    return { ...actual, BaseEntity: FakeBaseEntity };
});

import { CompanySenderIdentityEntity } from '../CompanySenderIdentityEntity.js';

function makeEntity(values: SenderRecord): CompanySenderIdentityEntity {
    const entity = new CompanySenderIdentityEntity({} as EntityInfo); // the fake base ignores its EntityInfo
    entity.Kind = values.Kind;
    entity.Address = values.Address;
    entity.DisplayName = values.DisplayName;
    entity.IsDefault = values.IsDefault ?? false;
    entity.CompanyID = values.CompanyID ?? 'co-1';
    return entity;
}

describe('CompanySenderIdentityEntity', () => {
    beforeEach(() => baseSave.mockClear());

    it('Validate reports a malformed Mailbox on the Address field', () => {
        const result = makeEntity({ Kind: 'Mailbox', Address: 'acme.com', DisplayName: null }).Validate();
        expect(result.Success).toBe(false);
        expect(result.Errors).toHaveLength(1);
        expect(result.Errors[0].Source).toBe('Address');
    });

    it('Validate reports a DisplayName on a Domain row on the DisplayName field', () => {
        const result = makeEntity({ Kind: 'Domain', Address: 'acme.com', DisplayName: 'Acme' }).Validate();
        expect(result.Success).toBe(false);
        expect(result.Errors.map((e) => e.Source)).toEqual(['DisplayName']);
    });

    it('Validate succeeds for a well-formed Mailbox', () => {
        expect(makeEntity({ Kind: 'Mailbox', Address: 'hr@acme.com', DisplayName: 'Acme HR' }).Validate().Success).toBe(true);
    });

    it('Validate refuses a Domain row as the default, on the IsDefault field, naming the domain', () => {
        const result = makeEntity({ Kind: 'Domain', Address: 'acme.com', DisplayName: null, IsDefault: true }).Validate();
        expect(result.Success).toBe(false);
        expect(result.Errors[0].Source).toBe('IsDefault');
        expect(result.Errors[0].Message).toContain('"acme.com"');
    });

    it('Validate accepts a default Mailbox row', () => {
        expect(makeEntity({ Kind: 'Mailbox', Address: 'hr@acme.com', DisplayName: null, IsDefault: true }).Validate().Success).toBe(true);
    });

    it('Save writes the trimmed lower-cased Address before calling the base save', async () => {
        const entity = makeEntity({ Kind: 'Mailbox', Address: '  HR@Acme.com ', DisplayName: '  Acme HR ' });
        expect(await entity.Save()).toBe(true);
        expect(baseSave).toHaveBeenCalledWith(expect.objectContaining({ Address: 'hr@acme.com', DisplayName: 'Acme HR' }));
    });

    it('Save refuses and does not call the base save when Validate fails', async () => {
        const entity = makeEntity({ Kind: 'Mailbox', Address: 'Acme.com', DisplayName: null, CompanyID: 'co-42' });
        expect(await entity.Save()).toBe(false);
        expect(baseSave).not.toHaveBeenCalled();
        expect(entity.LatestResult.Success).toBe(false);
        expect(entity.LatestResult.Message).toContain('acme.com');
        expect(entity.LatestResult.Message).toContain('co-42');
    });
});
