/**
 * MJ entity names for this app. Looked up by string at runtime — a typo
 * does not fail to compile. `RunView` then returns an empty list and every
 * dashboard tile reads zero. Keep them here; verify against generated
 * `@RegisterClass(BaseEntity, '...')` in `@mj-biz-apps/common-entities`.
 */
export const COMMON_ENTITIES = {
    Person: 'MJ_BizApps_Common: People',
    Organization: 'MJ_BizApps_Common: Organizations',
    Relationship: 'MJ_BizApps_Common: Relationships',
    ContactMethod: 'MJ_BizApps_Common: Contact Methods',
    Address: 'MJ_BizApps_Common: Addresses',
    AddressLink: 'MJ_BizApps_Common: Address Links',
    OrganizationType: 'MJ_BizApps_Common: Organization Types',
    RelationshipType: 'MJ_BizApps_Common: Relationship Types',
    Activity: 'MJ_BizApps_Common: Activities',
    ActivityType: 'MJ_BizApps_Common: Activity Types',
    ActivityLink: 'MJ_BizApps_Common: Activity Links',
    ActivityFile: 'MJ_BizApps_Common: Activity Files',
} as const;
