/** Entity names as CodeGen registered them. One place so the engine and writer cannot drift. */
export const ACTIVITY_SYNC_ENTITIES = {
    Activities: 'MJ_BizApps_Common: Activities',
    ActivityLinks: 'MJ_BizApps_Common: Activity Links',
    ActivityTypes: 'MJ_BizApps_Common: Activity Types',
    Connections: 'MJ_BizApps_Common: Activity Sync Connections',
    ProviderTypes: 'MJ_BizApps_Common: Activity Sync Provider Types',
    RuleSets: 'MJ_BizApps_Common: Activity Sync Rule Sets',
    Rules: 'MJ_BizApps_Common: Activity Sync Rules',
    ConnectionRuleSets: 'MJ_BizApps_Common: Activity Sync Connection Rule Sets',
    Exclusions: 'MJ_BizApps_Common: Activity Sync Exclusions',
    Runs: 'MJ_BizApps_Common: Activity Sync Runs',
    RunDetails: 'MJ_BizApps_Common: Activity Sync Run Details',
    Extensions: 'MJ_BizApps_Common: Activity Sync Extensions',
    ContactMethods: 'MJ_BizApps_Common: Contact Methods',
    People: 'MJ_BizApps_Common: People',
    Organizations: 'MJ_BizApps_Common: Organizations',
} as const;
