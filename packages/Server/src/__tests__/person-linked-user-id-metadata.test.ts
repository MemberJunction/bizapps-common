/**
 * Regression guard for Person.LinkedUserID metadata and schema (Chief of Staff / User-to-Person linkage).
 *
 * Ensures that:
 * 1. `metadata/entities/.entities.json` explicitly pins `LinkedUserID` on `MJ_BizApps_Common: People`
 *    with `Status = 'Active'` and `AutoUpdateDescription = false`.
 * 2. The description documents the 1:1 optional linkage (`UQ_Person_LinkedUserID`) and the
 *    non-auto-provisioning guarantee (saving a Person never creates or modifies MJ Users).
 * 3. The generated `mjBizAppsCommonPersonSchema` exposes `LinkedUserID` as a nullable string without
 *    a deprecation marker.
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { mjBizAppsCommonPersonSchema } from '@mj-biz-apps/common-entities';

interface EntityFieldMetadataEntry {
    fields: Record<string, string | number | boolean | null>;
    primaryKey?: { ID: string };
}

interface EntityMetadataEntry {
    fields: Record<string, unknown>;
    primaryKey?: { ID: string };
    relatedEntities?: {
        'MJ: Entity Fields'?: EntityFieldMetadataEntry[];
    };
}

function loadEntitiesMetadata(): EntityMetadataEntry[] {
    const path = fileURLToPath(new URL('../../../../metadata/entities/.entities.json', import.meta.url));
    return JSON.parse(readFileSync(path, 'utf8')) as EntityMetadataEntry[];
}

describe('MJ_BizApps_Common: People — LinkedUserID active optional User linkage', () => {
    it('declares LinkedUserID as Status=Active with AutoUpdateDescription=false in metadata/entities/.entities.json', () => {
        const entities = loadEntitiesMetadata();
        const people = entities.find(
            (e) => e.primaryKey?.ID === '@lookup:MJ: Entities.Name=MJ_BizApps_Common: People',
        );
        expect(people).toBeDefined();

        const fields = people?.relatedEntities?.['MJ: Entity Fields'] ?? [];
        const linkedUserField = fields.find(
            (f) => f.primaryKey?.ID === '@lookup:MJ: Entity Fields.Name=LinkedUserID&EntityID=@parent:ID',
        );
        expect(linkedUserField).toBeDefined();
        expect(linkedUserField?.fields.Status).toBe('Active');
        expect(linkedUserField?.fields.AutoUpdateDescription).toBe(false);
        expect(String(linkedUserField?.fields.Description)).toContain('UQ_Person_LinkedUserID');
        expect(String(linkedUserField?.fields.Description)).toContain('never auto-provisions');
    });

    it('exposes LinkedUserID on mjBizAppsCommonPersonSchema without a DEPRECATED description', () => {
        const shape = mjBizAppsCommonPersonSchema.shape;
        expect(shape.LinkedUserID).toBeDefined();
        expect(shape.LinkedUserID.description ?? '').not.toContain('DEPRECATED');
        expect(shape.LinkedUserID.safeParse(null).success).toBe(true);
        expect(shape.LinkedUserID.safeParse('11111111-2222-3333-4444-555555555555').success).toBe(true);
    });
});
