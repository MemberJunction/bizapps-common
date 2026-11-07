import { describe, expect, it } from 'vitest';
import { COMMON_ENTITIES, WORLD_EMAIL_DOMAIN } from '../entity-names.js';

describe('COMMON_ENTITIES', () => {
    it('uses the generated Common entity names', () => {
        expect(COMMON_ENTITIES.Person).toBe('MJ_BizApps_Common: People');
        expect(COMMON_ENTITIES.Organization).toBe('MJ_BizApps_Common: Organizations');
        expect(COMMON_ENTITIES.Relationship).toBe('MJ_BizApps_Common: Relationships');
        expect(COMMON_ENTITIES.ActivityType).toBe('MJ_BizApps_Common: Activity Types');
        expect(COMMON_ENTITIES.Activity).toBe('MJ_BizApps_Common: Activities');
        expect(COMMON_ENTITIES.ActivityLink).toBe('MJ_BizApps_Common: Activity Links');
        expect(COMMON_ENTITIES.ActivityFile).toBe('MJ_BizApps_Common: Activity Files');
        expect(COMMON_ENTITIES.ActivitySyncConnection).toBe('MJ_BizApps_Common: Activity Sync Connections');
        expect(COMMON_ENTITIES.ActivitySyncRule).toBe('MJ_BizApps_Common: Activity Sync Rules');
        expect(WORLD_EMAIL_DOMAIN).toBe('com-world.test');
    });
});
