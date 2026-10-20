export const COMMON_ENTITIES = {
    Person: 'MJ_BizApps_Common: People',
    Organization: 'MJ_BizApps_Common: Organizations',
    OrganizationType: 'MJ_BizApps_Common: Organization Types',
    Address: 'MJ_BizApps_Common: Addresses',
    AddressLink: 'MJ_BizApps_Common: Address Links',
    AddressType: 'MJ_BizApps_Common: Address Types',
    ContactMethod: 'MJ_BizApps_Common: Contact Methods',
    ContactType: 'MJ_BizApps_Common: Contact Types',
    Relationship: 'MJ_BizApps_Common: Relationships',
    RelationshipType: 'MJ_BizApps_Common: Relationship Types',
    ActivityType: 'MJ_BizApps_Common: Activity Types',
    Activity: 'MJ_BizApps_Common: Activities',
    ActivityLink: 'MJ_BizApps_Common: Activity Links',
    ActivityFile: 'MJ_BizApps_Common: Activity Files',
    ActivitySyncConnection: 'MJ_BizApps_Common: Activity Sync Connections',
    ActivitySyncRule: 'MJ_BizApps_Common: Activity Sync Rules',
} as const;

/** Email / name suffix that identifies COM-WORLD rows for cleanup. */
export const WORLD_EMAIL_DOMAIN = 'com-world.test';
export const WORLD_TAG = 'COM-WORLD';

/**
 * Deterministic CC0 avatars via the official DiceBear HTTP API (MIT).
 * Style `lorelei` is a remix of Lisa Wischofsky's Lorelei, dedicated CC0 1.0 —
 * generated illustrations, not scraped photographs of real people.
 * @see https://www.dicebear.com/licenses/
 */
export function WorldAvatarURL(email: string): string {
    return `https://api.dicebear.com/9.x/lorelei/png?seed=${encodeURIComponent(email)}&size=256`;
}
