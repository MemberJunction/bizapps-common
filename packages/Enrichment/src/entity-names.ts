/** Entity names as CodeGen produced them. Never write a schema or view name literally; resolve it from EntityInfo. */
export const ENRICHMENT_ENTITIES = {
    People: 'MJ_BizApps_Common: People',
    ContactMethods: 'MJ_BizApps_Common: Contact Methods',
    ContactTypes: 'MJ_BizApps_Common: Contact Types',
    Relationships: 'MJ_BizApps_Common: Relationships',
    RelationshipTypes: 'MJ_BizApps_Common: Relationship Types',
    Organizations: 'MJ_BizApps_Common: Organizations',
    PersonEducations: 'MJ_BizApps_Common: Person Educations',
    PersonExternalIdentities: 'MJ_BizApps_Common: Person External Identities',
    EnrichmentProviders: 'MJ_BizApps_Common: Enrichment Providers',
    EnrichmentProviderRates: 'MJ_BizApps_Common: Enrichment Provider Rates',
} as const;

export const EMPLOYEE_RELATIONSHIP_TYPE = 'Employee';
export const EMAIL_CONTACT_TYPE = 'Email';
export const LINKEDIN_CONTACT_TYPE = 'LinkedIn';
