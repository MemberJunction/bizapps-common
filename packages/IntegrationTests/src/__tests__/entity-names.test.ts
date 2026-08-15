import { describe, expect, it } from 'vitest';
import { COMMON_ENTITIES, WORLD_EMAIL_DOMAIN } from '../entity-names.js';

describe('COMMON_ENTITIES', () => {
    it('uses the generated Common entity names', () => {
        expect(COMMON_ENTITIES.Person).toBe('MJ_BizApps_Common: People');
        expect(COMMON_ENTITIES.Organization).toBe('MJ_BizApps_Common: Organizations');
        expect(COMMON_ENTITIES.Relationship).toBe('MJ_BizApps_Common: Relationships');
        expect(WORLD_EMAIL_DOMAIN).toBe('com-world.test');
    });
});
