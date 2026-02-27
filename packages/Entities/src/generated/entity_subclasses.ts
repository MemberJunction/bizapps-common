import { BaseEntity, EntitySaveOptions, EntityDeleteOptions, CompositeKey, ValidationResult, ValidationErrorInfo, ValidationErrorType, Metadata, ProviderType, DatabaseProviderBase } from "@memberjunction/core";
import { RegisterClass } from "@memberjunction/global";
import { z } from "zod";

export const loadModule = () => {
  // no-op, only used to ensure this file is a valid module and to allow easy loading
}

     
 
/**
 * zod schema definition for the entity MJ.BizApps.Common: Address Links
 */
export const mjBizAppsCommonAddressLinkSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    AddressID: z.string().describe(`
        * * Field Name: AddressID
        * * Display Name: Address
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ.BizApps.Common: Addresses (vwAddresses.ID)`),
    EntityID: z.string().describe(`
        * * Field Name: EntityID
        * * Display Name: Entity
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ: Entities (vwEntities.ID)`),
    RecordID: z.string().describe(`
        * * Field Name: RecordID
        * * Display Name: Record ID
        * * SQL Data Type: nvarchar(700)
        * * Description: Primary key value(s) of the linked record. NVARCHAR(700) to support concatenated composite keys for entities without single-valued primary keys`),
    AddressTypeID: z.string().describe(`
        * * Field Name: AddressTypeID
        * * Display Name: Address Type
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ.BizApps.Common: Address Types (vwAddressTypes.ID)`),
    IsPrimary: z.boolean().describe(`
        * * Field Name: IsPrimary
        * * Display Name: Is Primary
        * * SQL Data Type: bit
        * * Default Value: 0
        * * Description: Whether this is the primary address for the linked record. Only one address per entity record should be marked primary`),
    Rank: z.number().nullable().describe(`
        * * Field Name: Rank
        * * Display Name: Rank
        * * SQL Data Type: int
        * * Description: Sort order override for this specific link. When NULL, falls back to AddressType.DefaultRank. Lower values appear first`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    Address: z.string().describe(`
        * * Field Name: Address
        * * Display Name: Address Summary
        * * SQL Data Type: nvarchar(255)`),
    Entity: z.string().describe(`
        * * Field Name: Entity
        * * Display Name: Entity Name
        * * SQL Data Type: nvarchar(255)`),
    AddressType: z.string().describe(`
        * * Field Name: AddressType
        * * Display Name: Address Type Name
        * * SQL Data Type: nvarchar(100)`),
});

export type mjBizAppsCommonAddressLinkEntityType = z.infer<typeof mjBizAppsCommonAddressLinkSchema>;

/**
 * zod schema definition for the entity MJ.BizApps.Common: Address Types
 */
export const mjBizAppsCommonAddressTypeSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Display name for the address type`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Detailed description of this address type`),
    IconClass: z.string().nullable().describe(`
        * * Field Name: IconClass
        * * Display Name: Icon Class
        * * SQL Data Type: nvarchar(100)
        * * Description: Font Awesome icon class for UI display`),
    DefaultRank: z.number().describe(`
        * * Field Name: DefaultRank
        * * Display Name: Default Rank
        * * SQL Data Type: int
        * * Default Value: 100
        * * Description: Default sort order for this address type in dropdown lists. Lower values appear first. Can be overridden per-record via AddressLink.Rank`),
    IsActive: z.boolean().describe(`
        * * Field Name: IsActive
        * * Display Name: Active
        * * SQL Data Type: bit
        * * Default Value: 1
        * * Description: Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
});

export type mjBizAppsCommonAddressTypeEntityType = z.infer<typeof mjBizAppsCommonAddressTypeSchema>;

/**
 * zod schema definition for the entity MJ.BizApps.Common: Addresses
 */
export const mjBizAppsCommonAddressSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Line1: z.string().describe(`
        * * Field Name: Line1
        * * Display Name: Address Line 1
        * * SQL Data Type: nvarchar(255)
        * * Description: Street address line 1`),
    Line2: z.string().nullable().describe(`
        * * Field Name: Line2
        * * Display Name: Address Line 2
        * * SQL Data Type: nvarchar(255)
        * * Description: Street address line 2 (suite, apt, etc.)`),
    Line3: z.string().nullable().describe(`
        * * Field Name: Line3
        * * Display Name: Address Line 3
        * * SQL Data Type: nvarchar(255)
        * * Description: Street address line 3 (additional detail)`),
    City: z.string().describe(`
        * * Field Name: City
        * * Display Name: City
        * * SQL Data Type: nvarchar(100)
        * * Description: City or locality name`),
    StateProvince: z.string().nullable().describe(`
        * * Field Name: StateProvince
        * * Display Name: State / Province
        * * SQL Data Type: nvarchar(100)
        * * Description: State, province, or region`),
    PostalCode: z.string().nullable().describe(`
        * * Field Name: PostalCode
        * * Display Name: Postal Code
        * * SQL Data Type: nvarchar(20)
        * * Description: Postal or ZIP code`),
    Country: z.string().describe(`
        * * Field Name: Country
        * * Display Name: Country
        * * SQL Data Type: nvarchar(100)
        * * Default Value: US
        * * Description: Country code or name, defaults to US`),
    Latitude: z.number().nullable().describe(`
        * * Field Name: Latitude
        * * Display Name: Latitude
        * * SQL Data Type: decimal(9, 6)
        * * Description: Geographic latitude for mapping`),
    Longitude: z.number().nullable().describe(`
        * * Field Name: Longitude
        * * Display Name: Longitude
        * * SQL Data Type: decimal(9, 6)
        * * Description: Geographic longitude for mapping`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
});

export type mjBizAppsCommonAddressEntityType = z.infer<typeof mjBizAppsCommonAddressSchema>;

/**
 * zod schema definition for the entity MJ.BizApps.Common: Contact Methods
 */
export const mjBizAppsCommonContactMethodSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    PersonID: z.string().nullable().describe(`
        * * Field Name: PersonID
        * * Display Name: Person
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ.BizApps.Common: People (vwPeopleExtended.ID)`),
    OrganizationID: z.string().nullable().describe(`
        * * Field Name: OrganizationID
        * * Display Name: Organization
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ.BizApps.Common: Organizations (vwOrganizationsExtended.ID)`),
    ContactTypeID: z.string().describe(`
        * * Field Name: ContactTypeID
        * * Display Name: Contact Type
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ.BizApps.Common: Contact Types (vwContactTypes.ID)`),
    Value: z.string().describe(`
        * * Field Name: Value
        * * Display Name: Contact Value
        * * SQL Data Type: nvarchar(500)
        * * Description: The contact value: phone number, email address, URL, social media handle, etc.`),
    Label: z.string().nullable().describe(`
        * * Field Name: Label
        * * Display Name: Label
        * * SQL Data Type: nvarchar(100)
        * * Description: Descriptive label such as Work cell, Personal Gmail, Corporate LinkedIn`),
    IsPrimary: z.boolean().describe(`
        * * Field Name: IsPrimary
        * * Display Name: Is Primary
        * * SQL Data Type: bit
        * * Default Value: 0
        * * Description: Whether this is the primary contact method of its type for the linked person or organization`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    Person: z.string().nullable().describe(`
        * * Field Name: Person
        * * Display Name: Person Name
        * * SQL Data Type: nvarchar(100)`),
    Organization: z.string().nullable().describe(`
        * * Field Name: Organization
        * * Display Name: Organization Name
        * * SQL Data Type: nvarchar(255)`),
    ContactType: z.string().describe(`
        * * Field Name: ContactType
        * * Display Name: Contact Type Name
        * * SQL Data Type: nvarchar(100)`),
});

export type mjBizAppsCommonContactMethodEntityType = z.infer<typeof mjBizAppsCommonContactMethodSchema>;

/**
 * zod schema definition for the entity MJ.BizApps.Common: Contact Types
 */
export const mjBizAppsCommonContactTypeSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Display name for the contact type`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Detailed description of this contact type`),
    IconClass: z.string().nullable().describe(`
        * * Field Name: IconClass
        * * Display Name: Icon Class
        * * SQL Data Type: nvarchar(100)
        * * Description: Font Awesome icon class for UI display`),
    DisplayRank: z.number().describe(`
        * * Field Name: DisplayRank
        * * Display Name: Display Rank
        * * SQL Data Type: int
        * * Default Value: 100
        * * Description: Sort order in dropdown lists. Lower values appear first`),
    IsActive: z.boolean().describe(`
        * * Field Name: IsActive
        * * Display Name: Is Active
        * * SQL Data Type: bit
        * * Default Value: 1
        * * Description: Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
});

export type mjBizAppsCommonContactTypeEntityType = z.infer<typeof mjBizAppsCommonContactTypeSchema>;

/**
 * zod schema definition for the entity MJ.BizApps.Common: Organization Types
 */
export const mjBizAppsCommonOrganizationTypeSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Display name for the organization type`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Detailed description of this organization type`),
    IconClass: z.string().nullable().describe(`
        * * Field Name: IconClass
        * * Display Name: Icon Class
        * * SQL Data Type: nvarchar(100)
        * * Description: Font Awesome icon class for UI display`),
    DisplayRank: z.number().describe(`
        * * Field Name: DisplayRank
        * * Display Name: Display Rank
        * * SQL Data Type: int
        * * Default Value: 100
        * * Description: Sort order in dropdown lists. Lower values appear first`),
    IsActive: z.boolean().describe(`
        * * Field Name: IsActive
        * * Display Name: Active
        * * SQL Data Type: bit
        * * Default Value: 1
        * * Description: Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
});

export type mjBizAppsCommonOrganizationTypeEntityType = z.infer<typeof mjBizAppsCommonOrganizationTypeSchema>;

/**
 * zod schema definition for the entity MJ.BizApps.Common: Organizations
 */
export const mjBizAppsCommonOrganizationSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(255)
        * * Description: Common or display name of the organization`),
    LegalName: z.string().nullable().describe(`
        * * Field Name: LegalName
        * * Display Name: Legal Name
        * * SQL Data Type: nvarchar(255)
        * * Description: Full legal name if different from display name`),
    OrganizationTypeID: z.string().nullable().describe(`
        * * Field Name: OrganizationTypeID
        * * Display Name: Organization Type
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ.BizApps.Common: Organization Types (vwOrganizationTypes.ID)`),
    ParentID: z.string().nullable().describe(`
        * * Field Name: ParentID
        * * Display Name: Parent
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ.BizApps.Common: Organizations (vwOrganizationsExtended.ID)`),
    Website: z.string().nullable().describe(`
        * * Field Name: Website
        * * Display Name: Website
        * * SQL Data Type: nvarchar(1000)
        * * Description: Primary website URL`),
    LogoURL: z.string().nullable().describe(`
        * * Field Name: LogoURL
        * * Display Name: Logo URL
        * * SQL Data Type: nvarchar(1000)
        * * Description: URL to organization logo image`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Description of the organization purpose and scope`),
    Email: z.string().nullable().describe(`
        * * Field Name: Email
        * * Display Name: Email
        * * SQL Data Type: nvarchar(255)
        * * Description: Primary contact email address`),
    Phone: z.string().nullable().describe(`
        * * Field Name: Phone
        * * Display Name: Phone
        * * SQL Data Type: nvarchar(50)
        * * Description: Primary phone number`),
    FoundedDate: z.date().nullable().describe(`
        * * Field Name: FoundedDate
        * * Display Name: Founded Date
        * * SQL Data Type: date
        * * Description: Date the organization was founded or incorporated`),
    TaxID: z.string().nullable().describe(`
        * * Field Name: TaxID
        * * Display Name: Tax ID
        * * SQL Data Type: nvarchar(50)
        * * Description: Tax identification number such as EIN`),
    Status: z.union([z.literal('Active'), z.literal('Dissolved'), z.literal('Inactive')]).describe(`
        * * Field Name: Status
        * * Display Name: Status
        * * SQL Data Type: nvarchar(50)
        * * Default Value: Active
    * * Value List Type: List
    * * Possible Values 
    *   * Active
    *   * Dissolved
    *   * Inactive
        * * Description: Current status: Active, Inactive, or Dissolved`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    OrganizationType: z.string().nullable().describe(`
        * * Field Name: OrganizationType
        * * Display Name: Organization Type Name
        * * SQL Data Type: nvarchar(100)`),
    Parent: z.string().nullable().describe(`
        * * Field Name: Parent
        * * Display Name: Parent Name
        * * SQL Data Type: nvarchar(255)`),
    RootParentID: z.string().nullable().describe(`
        * * Field Name: RootParentID
        * * Display Name: Root Parent
        * * SQL Data Type: uniqueidentifier`),
    PrimaryAddressLine1: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressLine1
        * * Display Name: Primary Address Line 1
        * * SQL Data Type: nvarchar(255)`),
    PrimaryAddressLine2: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressLine2
        * * Display Name: Primary Address Line 2
        * * SQL Data Type: nvarchar(255)`),
    PrimaryAddressCity: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressCity
        * * Display Name: Primary City
        * * SQL Data Type: nvarchar(100)`),
    PrimaryAddressState: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressState
        * * Display Name: Primary State
        * * SQL Data Type: nvarchar(100)`),
    PrimaryAddressPostalCode: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressPostalCode
        * * Display Name: Primary Postal Code
        * * SQL Data Type: nvarchar(20)`),
    PrimaryAddressCountry: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressCountry
        * * Display Name: Primary Country
        * * SQL Data Type: nvarchar(100)`),
    PrimaryAddressType: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressType
        * * Display Name: Primary Address Type
        * * SQL Data Type: nvarchar(100)`),
    PrimaryEmail: z.string().nullable().describe(`
        * * Field Name: PrimaryEmail
        * * Display Name: Primary Email
        * * SQL Data Type: nvarchar(500)`),
    PrimaryPhone: z.string().nullable().describe(`
        * * Field Name: PrimaryPhone
        * * Display Name: Primary Phone
        * * SQL Data Type: nvarchar(500)`),
    ActivePersonCount: z.number().nullable().describe(`
        * * Field Name: ActivePersonCount
        * * Display Name: Active Person Count
        * * SQL Data Type: int`),
    ChildOrgCount: z.number().nullable().describe(`
        * * Field Name: ChildOrgCount
        * * Display Name: Child Organization Count
        * * SQL Data Type: int`),
});

export type mjBizAppsCommonOrganizationEntityType = z.infer<typeof mjBizAppsCommonOrganizationSchema>;

/**
 * zod schema definition for the entity MJ.BizApps.Common: People
 */
export const mjBizAppsCommonPersonSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    FirstName: z.string().describe(`
        * * Field Name: FirstName
        * * Display Name: First Name
        * * SQL Data Type: nvarchar(100)
        * * Description: First (given) name`),
    LastName: z.string().describe(`
        * * Field Name: LastName
        * * Display Name: Last Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Last (family) name`),
    MiddleName: z.string().nullable().describe(`
        * * Field Name: MiddleName
        * * Display Name: Middle Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Middle name or initial`),
    Prefix: z.string().nullable().describe(`
        * * Field Name: Prefix
        * * Display Name: Prefix
        * * SQL Data Type: nvarchar(20)
        * * Description: Name prefix such as Dr., Mr., Ms., Rev.`),
    Suffix: z.string().nullable().describe(`
        * * Field Name: Suffix
        * * Display Name: Suffix
        * * SQL Data Type: nvarchar(20)
        * * Description: Name suffix such as Jr., III, PhD, Esq.`),
    PreferredName: z.string().nullable().describe(`
        * * Field Name: PreferredName
        * * Display Name: Preferred Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Nickname or preferred name the person goes by`),
    Title: z.string().nullable().describe(`
        * * Field Name: Title
        * * Display Name: Title
        * * SQL Data Type: nvarchar(200)
        * * Description: Professional or job title, e.g. VP of Engineering, Board Director`),
    Email: z.string().nullable().describe(`
        * * Field Name: Email
        * * Display Name: Email
        * * SQL Data Type: nvarchar(255)
        * * Description: Primary email address for this person`),
    Phone: z.string().nullable().describe(`
        * * Field Name: Phone
        * * Display Name: Phone
        * * SQL Data Type: nvarchar(50)
        * * Description: Primary phone number for this person`),
    DateOfBirth: z.date().nullable().describe(`
        * * Field Name: DateOfBirth
        * * Display Name: Date of Birth
        * * SQL Data Type: date
        * * Description: Date of birth`),
    Gender: z.string().nullable().describe(`
        * * Field Name: Gender
        * * Display Name: Gender
        * * SQL Data Type: nvarchar(50)
        * * Description: Gender identity`),
    PhotoURL: z.string().nullable().describe(`
        * * Field Name: PhotoURL
        * * Display Name: Photo URL
        * * SQL Data Type: nvarchar(1000)
        * * Description: URL to profile photo or avatar image`),
    Bio: z.string().nullable().describe(`
        * * Field Name: Bio
        * * Display Name: Biography
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Biographical text or notes about this person`),
    LinkedUserID: z.string().nullable().describe(`
        * * Field Name: LinkedUserID
        * * Display Name: Linked User
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ: Users (vwUsers.ID)`),
    Status: z.union([z.literal('Active'), z.literal('Deceased'), z.literal('Inactive')]).describe(`
        * * Field Name: Status
        * * Display Name: Status
        * * SQL Data Type: nvarchar(50)
        * * Default Value: Active
    * * Value List Type: List
    * * Possible Values 
    *   * Active
    *   * Deceased
    *   * Inactive
        * * Description: Current status: Active, Inactive, or Deceased`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    LinkedUser: z.string().nullable().describe(`
        * * Field Name: LinkedUser
        * * Display Name: Linked User Account
        * * SQL Data Type: nvarchar(100)`),
    DisplayName: z.string().nullable().describe(`
        * * Field Name: DisplayName
        * * Display Name: Display Name
        * * SQL Data Type: nvarchar(244)`),
    PrimaryAddressLine1: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressLine1
        * * Display Name: Primary Address Line 1
        * * SQL Data Type: nvarchar(255)`),
    PrimaryAddressLine2: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressLine2
        * * Display Name: Primary Address Line 2
        * * SQL Data Type: nvarchar(255)`),
    PrimaryAddressCity: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressCity
        * * Display Name: Primary City
        * * SQL Data Type: nvarchar(100)`),
    PrimaryAddressState: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressState
        * * Display Name: Primary State
        * * SQL Data Type: nvarchar(100)`),
    PrimaryAddressPostalCode: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressPostalCode
        * * Display Name: Primary Postal Code
        * * SQL Data Type: nvarchar(20)`),
    PrimaryAddressCountry: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressCountry
        * * Display Name: Primary Country
        * * SQL Data Type: nvarchar(100)`),
    PrimaryAddressLatitude: z.number().nullable().describe(`
        * * Field Name: PrimaryAddressLatitude
        * * Display Name: Primary Latitude
        * * SQL Data Type: decimal(9, 6)`),
    PrimaryAddressLongitude: z.number().nullable().describe(`
        * * Field Name: PrimaryAddressLongitude
        * * Display Name: Primary Longitude
        * * SQL Data Type: decimal(9, 6)`),
    PrimaryAddressType: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressType
        * * Display Name: Address Type
        * * SQL Data Type: nvarchar(100)`),
    PrimaryEmail: z.string().nullable().describe(`
        * * Field Name: PrimaryEmail
        * * Display Name: Primary Email
        * * SQL Data Type: nvarchar(500)`),
    PrimaryPhone: z.string().nullable().describe(`
        * * Field Name: PrimaryPhone
        * * Display Name: Primary Phone
        * * SQL Data Type: nvarchar(500)`),
    CurrentOrganizationID: z.string().nullable().describe(`
        * * Field Name: CurrentOrganizationID
        * * Display Name: Current Organization
        * * SQL Data Type: uniqueidentifier`),
    CurrentOrganizationName: z.string().nullable().describe(`
        * * Field Name: CurrentOrganizationName
        * * Display Name: Current Organization Name
        * * SQL Data Type: nvarchar(255)`),
    CurrentJobTitle: z.string().nullable().describe(`
        * * Field Name: CurrentJobTitle
        * * Display Name: Current Job Title
        * * SQL Data Type: nvarchar(255)`),
});

export type mjBizAppsCommonPersonEntityType = z.infer<typeof mjBizAppsCommonPersonSchema>;

/**
 * zod schema definition for the entity MJ.BizApps.Common: Relationship Types
 */
export const mjBizAppsCommonRelationshipTypeSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Display name for the relationship type, e.g. Employee, Spouse, Partner`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Detailed description of this relationship type`),
    Category: z.union([z.literal('OrganizationToOrganization'), z.literal('PersonToOrganization'), z.literal('PersonToPerson')]).describe(`
        * * Field Name: Category
        * * Display Name: Category
        * * SQL Data Type: nvarchar(50)
    * * Value List Type: List
    * * Possible Values 
    *   * OrganizationToOrganization
    *   * PersonToOrganization
    *   * PersonToPerson
        * * Description: Which entity types this relationship connects: PersonToPerson, PersonToOrganization, or OrganizationToOrganization`),
    IsDirectional: z.boolean().describe(`
        * * Field Name: IsDirectional
        * * Display Name: Is Directional
        * * SQL Data Type: bit
        * * Default Value: 1
        * * Description: Whether the relationship has a direction. False for symmetric relationships like Spouse or Partner`),
    ForwardLabel: z.string().nullable().describe(`
        * * Field Name: ForwardLabel
        * * Display Name: Forward Label
        * * SQL Data Type: nvarchar(100)
        * * Description: Label describing the From-to-To direction, e.g. is employee of, is parent of`),
    ReverseLabel: z.string().nullable().describe(`
        * * Field Name: ReverseLabel
        * * Display Name: Reverse Label
        * * SQL Data Type: nvarchar(100)
        * * Description: Label describing the To-to-From direction, e.g. employs, is child of`),
    IsActive: z.boolean().describe(`
        * * Field Name: IsActive
        * * Display Name: Active
        * * SQL Data Type: bit
        * * Default Value: 1
        * * Description: Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
});

export type mjBizAppsCommonRelationshipTypeEntityType = z.infer<typeof mjBizAppsCommonRelationshipTypeSchema>;

/**
 * zod schema definition for the entity MJ.BizApps.Common: Relationships
 */
export const mjBizAppsCommonRelationshipSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    RelationshipTypeID: z.string().describe(`
        * * Field Name: RelationshipTypeID
        * * Display Name: Relationship Type
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ.BizApps.Common: Relationship Types (vwRelationshipTypes.ID)`),
    FromPersonID: z.string().nullable().describe(`
        * * Field Name: FromPersonID
        * * Display Name: From Person
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ.BizApps.Common: People (vwPeopleExtended.ID)`),
    FromOrganizationID: z.string().nullable().describe(`
        * * Field Name: FromOrganizationID
        * * Display Name: From Organization
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ.BizApps.Common: Organizations (vwOrganizationsExtended.ID)`),
    ToPersonID: z.string().nullable().describe(`
        * * Field Name: ToPersonID
        * * Display Name: To Person
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ.BizApps.Common: People (vwPeopleExtended.ID)`),
    ToOrganizationID: z.string().nullable().describe(`
        * * Field Name: ToOrganizationID
        * * Display Name: To Organization
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ.BizApps.Common: Organizations (vwOrganizationsExtended.ID)`),
    Title: z.string().nullable().describe(`
        * * Field Name: Title
        * * Display Name: Title
        * * SQL Data Type: nvarchar(255)
        * * Description: Contextual title for this specific relationship, e.g. CEO, Primary Contact, Founding Member`),
    StartDate: z.date().nullable().describe(`
        * * Field Name: StartDate
        * * Display Name: Start Date
        * * SQL Data Type: date
        * * Description: Date the relationship began`),
    EndDate: z.date().nullable().describe(`
        * * Field Name: EndDate
        * * Display Name: End Date
        * * SQL Data Type: date
        * * Description: Date the relationship ended, if applicable`),
    Status: z.union([z.literal('Active'), z.literal('Ended'), z.literal('Inactive')]).describe(`
        * * Field Name: Status
        * * Display Name: Status
        * * SQL Data Type: nvarchar(50)
        * * Default Value: Active
    * * Value List Type: List
    * * Possible Values 
    *   * Active
    *   * Ended
    *   * Inactive
        * * Description: Current status: Active, Inactive, or Ended`),
    Notes: z.string().nullable().describe(`
        * * Field Name: Notes
        * * Display Name: Notes
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Additional notes about this relationship`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    RelationshipType: z.string().describe(`
        * * Field Name: RelationshipType
        * * Display Name: Relationship Type
        * * SQL Data Type: nvarchar(100)`),
    FromPerson: z.string().nullable().describe(`
        * * Field Name: FromPerson
        * * Display Name: From Person
        * * SQL Data Type: nvarchar(100)`),
    FromOrganization: z.string().nullable().describe(`
        * * Field Name: FromOrganization
        * * Display Name: From Organization
        * * SQL Data Type: nvarchar(255)`),
    ToPerson: z.string().nullable().describe(`
        * * Field Name: ToPerson
        * * Display Name: To Person
        * * SQL Data Type: nvarchar(100)`),
    ToOrganization: z.string().nullable().describe(`
        * * Field Name: ToOrganization
        * * Display Name: To Organization
        * * SQL Data Type: nvarchar(255)`),
});

export type mjBizAppsCommonRelationshipEntityType = z.infer<typeof mjBizAppsCommonRelationshipSchema>;
 
 

/**
 * MJ.BizApps.Common: Address Links - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: AddressLink
 * * Base View: vwAddressLinks
 * * @description Polymorphic link table connecting Address records to any entity record in the system via EntityID and RecordID
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ.BizApps.Common: Address Links')
export class mjBizAppsCommonAddressLinkEntity extends BaseEntity<mjBizAppsCommonAddressLinkEntityType> {
    /**
    * Loads the MJ.BizApps.Common: Address Links record from the database
    * @param ID: string - primary key value to load the MJ.BizApps.Common: Address Links record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonAddressLinkEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: AddressID
    * * Display Name: Address
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ.BizApps.Common: Addresses (vwAddresses.ID)
    */
    get AddressID(): string {
        return this.Get('AddressID');
    }
    set AddressID(value: string) {
        this.Set('AddressID', value);
    }

    /**
    * * Field Name: EntityID
    * * Display Name: Entity
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ: Entities (vwEntities.ID)
    */
    get EntityID(): string {
        return this.Get('EntityID');
    }
    set EntityID(value: string) {
        this.Set('EntityID', value);
    }

    /**
    * * Field Name: RecordID
    * * Display Name: Record ID
    * * SQL Data Type: nvarchar(700)
    * * Description: Primary key value(s) of the linked record. NVARCHAR(700) to support concatenated composite keys for entities without single-valued primary keys
    */
    get RecordID(): string {
        return this.Get('RecordID');
    }
    set RecordID(value: string) {
        this.Set('RecordID', value);
    }

    /**
    * * Field Name: AddressTypeID
    * * Display Name: Address Type
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ.BizApps.Common: Address Types (vwAddressTypes.ID)
    */
    get AddressTypeID(): string {
        return this.Get('AddressTypeID');
    }
    set AddressTypeID(value: string) {
        this.Set('AddressTypeID', value);
    }

    /**
    * * Field Name: IsPrimary
    * * Display Name: Is Primary
    * * SQL Data Type: bit
    * * Default Value: 0
    * * Description: Whether this is the primary address for the linked record. Only one address per entity record should be marked primary
    */
    get IsPrimary(): boolean {
        return this.Get('IsPrimary');
    }
    set IsPrimary(value: boolean) {
        this.Set('IsPrimary', value);
    }

    /**
    * * Field Name: Rank
    * * Display Name: Rank
    * * SQL Data Type: int
    * * Description: Sort order override for this specific link. When NULL, falls back to AddressType.DefaultRank. Lower values appear first
    */
    get Rank(): number | null {
        return this.Get('Rank');
    }
    set Rank(value: number | null) {
        this.Set('Rank', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: Address
    * * Display Name: Address Summary
    * * SQL Data Type: nvarchar(255)
    */
    get Address(): string {
        return this.Get('Address');
    }

    /**
    * * Field Name: Entity
    * * Display Name: Entity Name
    * * SQL Data Type: nvarchar(255)
    */
    get Entity(): string {
        return this.Get('Entity');
    }

    /**
    * * Field Name: AddressType
    * * Display Name: Address Type Name
    * * SQL Data Type: nvarchar(100)
    */
    get AddressType(): string {
        return this.Get('AddressType');
    }
}


/**
 * MJ.BizApps.Common: Address Types - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: AddressType
 * * Base View: vwAddressTypes
 * * @description Categories of addresses such as Home, Work, Mailing, Billing
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ.BizApps.Common: Address Types')
export class mjBizAppsCommonAddressTypeEntity extends BaseEntity<mjBizAppsCommonAddressTypeEntityType> {
    /**
    * Loads the MJ.BizApps.Common: Address Types record from the database
    * @param ID: string - primary key value to load the MJ.BizApps.Common: Address Types record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonAddressTypeEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: Name
    * * Display Name: Name
    * * SQL Data Type: nvarchar(100)
    * * Description: Display name for the address type
    */
    get Name(): string {
        return this.Get('Name');
    }
    set Name(value: string) {
        this.Set('Name', value);
    }

    /**
    * * Field Name: Description
    * * Display Name: Description
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Detailed description of this address type
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: IconClass
    * * Display Name: Icon Class
    * * SQL Data Type: nvarchar(100)
    * * Description: Font Awesome icon class for UI display
    */
    get IconClass(): string | null {
        return this.Get('IconClass');
    }
    set IconClass(value: string | null) {
        this.Set('IconClass', value);
    }

    /**
    * * Field Name: DefaultRank
    * * Display Name: Default Rank
    * * SQL Data Type: int
    * * Default Value: 100
    * * Description: Default sort order for this address type in dropdown lists. Lower values appear first. Can be overridden per-record via AddressLink.Rank
    */
    get DefaultRank(): number {
        return this.Get('DefaultRank');
    }
    set DefaultRank(value: number) {
        this.Set('DefaultRank', value);
    }

    /**
    * * Field Name: IsActive
    * * Display Name: Active
    * * SQL Data Type: bit
    * * Default Value: 1
    * * Description: Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records
    */
    get IsActive(): boolean {
        return this.Get('IsActive');
    }
    set IsActive(value: boolean) {
        this.Set('IsActive', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }
}


/**
 * MJ.BizApps.Common: Addresses - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: Address
 * * Base View: vwAddresses
 * * @description Standalone physical address records linked to entities via AddressLink for sharing across people and organizations
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ.BizApps.Common: Addresses')
export class mjBizAppsCommonAddressEntity extends BaseEntity<mjBizAppsCommonAddressEntityType> {
    /**
    * Loads the MJ.BizApps.Common: Addresses record from the database
    * @param ID: string - primary key value to load the MJ.BizApps.Common: Addresses record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonAddressEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: Line1
    * * Display Name: Address Line 1
    * * SQL Data Type: nvarchar(255)
    * * Description: Street address line 1
    */
    get Line1(): string {
        return this.Get('Line1');
    }
    set Line1(value: string) {
        this.Set('Line1', value);
    }

    /**
    * * Field Name: Line2
    * * Display Name: Address Line 2
    * * SQL Data Type: nvarchar(255)
    * * Description: Street address line 2 (suite, apt, etc.)
    */
    get Line2(): string | null {
        return this.Get('Line2');
    }
    set Line2(value: string | null) {
        this.Set('Line2', value);
    }

    /**
    * * Field Name: Line3
    * * Display Name: Address Line 3
    * * SQL Data Type: nvarchar(255)
    * * Description: Street address line 3 (additional detail)
    */
    get Line3(): string | null {
        return this.Get('Line3');
    }
    set Line3(value: string | null) {
        this.Set('Line3', value);
    }

    /**
    * * Field Name: City
    * * Display Name: City
    * * SQL Data Type: nvarchar(100)
    * * Description: City or locality name
    */
    get City(): string {
        return this.Get('City');
    }
    set City(value: string) {
        this.Set('City', value);
    }

    /**
    * * Field Name: StateProvince
    * * Display Name: State / Province
    * * SQL Data Type: nvarchar(100)
    * * Description: State, province, or region
    */
    get StateProvince(): string | null {
        return this.Get('StateProvince');
    }
    set StateProvince(value: string | null) {
        this.Set('StateProvince', value);
    }

    /**
    * * Field Name: PostalCode
    * * Display Name: Postal Code
    * * SQL Data Type: nvarchar(20)
    * * Description: Postal or ZIP code
    */
    get PostalCode(): string | null {
        return this.Get('PostalCode');
    }
    set PostalCode(value: string | null) {
        this.Set('PostalCode', value);
    }

    /**
    * * Field Name: Country
    * * Display Name: Country
    * * SQL Data Type: nvarchar(100)
    * * Default Value: US
    * * Description: Country code or name, defaults to US
    */
    get Country(): string {
        return this.Get('Country');
    }
    set Country(value: string) {
        this.Set('Country', value);
    }

    /**
    * * Field Name: Latitude
    * * Display Name: Latitude
    * * SQL Data Type: decimal(9, 6)
    * * Description: Geographic latitude for mapping
    */
    get Latitude(): number | null {
        return this.Get('Latitude');
    }
    set Latitude(value: number | null) {
        this.Set('Latitude', value);
    }

    /**
    * * Field Name: Longitude
    * * Display Name: Longitude
    * * SQL Data Type: decimal(9, 6)
    * * Description: Geographic longitude for mapping
    */
    get Longitude(): number | null {
        return this.Get('Longitude');
    }
    set Longitude(value: number | null) {
        this.Set('Longitude', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }
}


/**
 * MJ.BizApps.Common: Contact Methods - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: ContactMethod
 * * Base View: vwContactMethods
 * * @description Additional contact methods for people and organizations beyond the primary email and phone fields
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ.BizApps.Common: Contact Methods')
export class mjBizAppsCommonContactMethodEntity extends BaseEntity<mjBizAppsCommonContactMethodEntityType> {
    /**
    * Loads the MJ.BizApps.Common: Contact Methods record from the database
    * @param ID: string - primary key value to load the MJ.BizApps.Common: Contact Methods record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonContactMethodEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * Validate() method override for MJ.BizApps.Common: Contact Methods entity. This is an auto-generated method that invokes the generated validators for this entity for the following fields:
    * * Table-Level: Each record must be linked to either a person or an organization. This ensures that contact information is correctly attributed to exactly one entity and prevents data ambiguity caused by having both or neither assigned.
    * @public
    * @method
    * @override
    */
    public override Validate(): ValidationResult {
        const result = super.Validate();
        this.ValidatePersonIDOrOrganizationIDExclusivity(result);
        result.Success = result.Success && (result.Errors.length === 0);

        return result;
    }

    /**
    * Each record must be linked to either a person or an organization. This ensures that contact information is correctly attributed to exactly one entity and prevents data ambiguity caused by having both or neither assigned.
    * @param result - the ValidationResult object to add any errors or warnings to
    * @public
    * @method
    */
    public ValidatePersonIDOrOrganizationIDExclusivity(result: ValidationResult) {
    	// Check if both fields are null or if both fields are populated
    	const hasPerson = this.PersonID != null;
    	const hasOrganization = this.OrganizationID != null;
    
    	if (hasPerson === hasOrganization) {
    		const errorMessage = "Each record must be associated with either a person or an organization, but not both.";
    		result.Errors.push(new ValidationErrorInfo(
    			"PersonID",
    			errorMessage,
    			this.PersonID,
    			ValidationErrorType.Failure
    		));
    		result.Errors.push(new ValidationErrorInfo(
    			"OrganizationID",
    			errorMessage,
    			this.OrganizationID,
    			ValidationErrorType.Failure
    		));
    	}
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: PersonID
    * * Display Name: Person
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ.BizApps.Common: People (vwPeopleExtended.ID)
    */
    get PersonID(): string | null {
        return this.Get('PersonID');
    }
    set PersonID(value: string | null) {
        this.Set('PersonID', value);
    }

    /**
    * * Field Name: OrganizationID
    * * Display Name: Organization
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ.BizApps.Common: Organizations (vwOrganizationsExtended.ID)
    */
    get OrganizationID(): string | null {
        return this.Get('OrganizationID');
    }
    set OrganizationID(value: string | null) {
        this.Set('OrganizationID', value);
    }

    /**
    * * Field Name: ContactTypeID
    * * Display Name: Contact Type
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ.BizApps.Common: Contact Types (vwContactTypes.ID)
    */
    get ContactTypeID(): string {
        return this.Get('ContactTypeID');
    }
    set ContactTypeID(value: string) {
        this.Set('ContactTypeID', value);
    }

    /**
    * * Field Name: Value
    * * Display Name: Contact Value
    * * SQL Data Type: nvarchar(500)
    * * Description: The contact value: phone number, email address, URL, social media handle, etc.
    */
    get Value(): string {
        return this.Get('Value');
    }
    set Value(value: string) {
        this.Set('Value', value);
    }

    /**
    * * Field Name: Label
    * * Display Name: Label
    * * SQL Data Type: nvarchar(100)
    * * Description: Descriptive label such as Work cell, Personal Gmail, Corporate LinkedIn
    */
    get Label(): string | null {
        return this.Get('Label');
    }
    set Label(value: string | null) {
        this.Set('Label', value);
    }

    /**
    * * Field Name: IsPrimary
    * * Display Name: Is Primary
    * * SQL Data Type: bit
    * * Default Value: 0
    * * Description: Whether this is the primary contact method of its type for the linked person or organization
    */
    get IsPrimary(): boolean {
        return this.Get('IsPrimary');
    }
    set IsPrimary(value: boolean) {
        this.Set('IsPrimary', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: Person
    * * Display Name: Person Name
    * * SQL Data Type: nvarchar(100)
    */
    get Person(): string | null {
        return this.Get('Person');
    }

    /**
    * * Field Name: Organization
    * * Display Name: Organization Name
    * * SQL Data Type: nvarchar(255)
    */
    get Organization(): string | null {
        return this.Get('Organization');
    }

    /**
    * * Field Name: ContactType
    * * Display Name: Contact Type Name
    * * SQL Data Type: nvarchar(100)
    */
    get ContactType(): string {
        return this.Get('ContactType');
    }
}


/**
 * MJ.BizApps.Common: Contact Types - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: ContactType
 * * Base View: vwContactTypes
 * * @description Categories of contact methods such as Phone, Mobile, Email, LinkedIn, Website
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ.BizApps.Common: Contact Types')
export class mjBizAppsCommonContactTypeEntity extends BaseEntity<mjBizAppsCommonContactTypeEntityType> {
    /**
    * Loads the MJ.BizApps.Common: Contact Types record from the database
    * @param ID: string - primary key value to load the MJ.BizApps.Common: Contact Types record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonContactTypeEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: Name
    * * Display Name: Name
    * * SQL Data Type: nvarchar(100)
    * * Description: Display name for the contact type
    */
    get Name(): string {
        return this.Get('Name');
    }
    set Name(value: string) {
        this.Set('Name', value);
    }

    /**
    * * Field Name: Description
    * * Display Name: Description
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Detailed description of this contact type
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: IconClass
    * * Display Name: Icon Class
    * * SQL Data Type: nvarchar(100)
    * * Description: Font Awesome icon class for UI display
    */
    get IconClass(): string | null {
        return this.Get('IconClass');
    }
    set IconClass(value: string | null) {
        this.Set('IconClass', value);
    }

    /**
    * * Field Name: DisplayRank
    * * Display Name: Display Rank
    * * SQL Data Type: int
    * * Default Value: 100
    * * Description: Sort order in dropdown lists. Lower values appear first
    */
    get DisplayRank(): number {
        return this.Get('DisplayRank');
    }
    set DisplayRank(value: number) {
        this.Set('DisplayRank', value);
    }

    /**
    * * Field Name: IsActive
    * * Display Name: Is Active
    * * SQL Data Type: bit
    * * Default Value: 1
    * * Description: Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records
    */
    get IsActive(): boolean {
        return this.Get('IsActive');
    }
    set IsActive(value: boolean) {
        this.Set('IsActive', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }
}


/**
 * MJ.BizApps.Common: Organization Types - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: OrganizationType
 * * Base View: vwOrganizationTypes
 * * @description Categories of organizations such as Company, Non-Profit, Association, Government
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ.BizApps.Common: Organization Types')
export class mjBizAppsCommonOrganizationTypeEntity extends BaseEntity<mjBizAppsCommonOrganizationTypeEntityType> {
    /**
    * Loads the MJ.BizApps.Common: Organization Types record from the database
    * @param ID: string - primary key value to load the MJ.BizApps.Common: Organization Types record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonOrganizationTypeEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: Name
    * * Display Name: Name
    * * SQL Data Type: nvarchar(100)
    * * Description: Display name for the organization type
    */
    get Name(): string {
        return this.Get('Name');
    }
    set Name(value: string) {
        this.Set('Name', value);
    }

    /**
    * * Field Name: Description
    * * Display Name: Description
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Detailed description of this organization type
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: IconClass
    * * Display Name: Icon Class
    * * SQL Data Type: nvarchar(100)
    * * Description: Font Awesome icon class for UI display
    */
    get IconClass(): string | null {
        return this.Get('IconClass');
    }
    set IconClass(value: string | null) {
        this.Set('IconClass', value);
    }

    /**
    * * Field Name: DisplayRank
    * * Display Name: Display Rank
    * * SQL Data Type: int
    * * Default Value: 100
    * * Description: Sort order in dropdown lists. Lower values appear first
    */
    get DisplayRank(): number {
        return this.Get('DisplayRank');
    }
    set DisplayRank(value: number) {
        this.Set('DisplayRank', value);
    }

    /**
    * * Field Name: IsActive
    * * Display Name: Active
    * * SQL Data Type: bit
    * * Default Value: 1
    * * Description: Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records
    */
    get IsActive(): boolean {
        return this.Get('IsActive');
    }
    set IsActive(value: boolean) {
        this.Set('IsActive', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }
}


/**
 * MJ.BizApps.Common: Organizations - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: Organization
 * * Base View: vwOrganizationsExtended
 * * @description Companies, associations, government bodies, and other organizations with hierarchy support
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ.BizApps.Common: Organizations')
export class mjBizAppsCommonOrganizationEntity extends BaseEntity<mjBizAppsCommonOrganizationEntityType> {
    /**
    * Loads the MJ.BizApps.Common: Organizations record from the database
    * @param ID: string - primary key value to load the MJ.BizApps.Common: Organizations record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonOrganizationEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: Name
    * * Display Name: Name
    * * SQL Data Type: nvarchar(255)
    * * Description: Common or display name of the organization
    */
    get Name(): string {
        return this.Get('Name');
    }
    set Name(value: string) {
        this.Set('Name', value);
    }

    /**
    * * Field Name: LegalName
    * * Display Name: Legal Name
    * * SQL Data Type: nvarchar(255)
    * * Description: Full legal name if different from display name
    */
    get LegalName(): string | null {
        return this.Get('LegalName');
    }
    set LegalName(value: string | null) {
        this.Set('LegalName', value);
    }

    /**
    * * Field Name: OrganizationTypeID
    * * Display Name: Organization Type
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ.BizApps.Common: Organization Types (vwOrganizationTypes.ID)
    */
    get OrganizationTypeID(): string | null {
        return this.Get('OrganizationTypeID');
    }
    set OrganizationTypeID(value: string | null) {
        this.Set('OrganizationTypeID', value);
    }

    /**
    * * Field Name: ParentID
    * * Display Name: Parent
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ.BizApps.Common: Organizations (vwOrganizationsExtended.ID)
    */
    get ParentID(): string | null {
        return this.Get('ParentID');
    }
    set ParentID(value: string | null) {
        this.Set('ParentID', value);
    }

    /**
    * * Field Name: Website
    * * Display Name: Website
    * * SQL Data Type: nvarchar(1000)
    * * Description: Primary website URL
    */
    get Website(): string | null {
        return this.Get('Website');
    }
    set Website(value: string | null) {
        this.Set('Website', value);
    }

    /**
    * * Field Name: LogoURL
    * * Display Name: Logo URL
    * * SQL Data Type: nvarchar(1000)
    * * Description: URL to organization logo image
    */
    get LogoURL(): string | null {
        return this.Get('LogoURL');
    }
    set LogoURL(value: string | null) {
        this.Set('LogoURL', value);
    }

    /**
    * * Field Name: Description
    * * Display Name: Description
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Description of the organization purpose and scope
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: Email
    * * Display Name: Email
    * * SQL Data Type: nvarchar(255)
    * * Description: Primary contact email address
    */
    get Email(): string | null {
        return this.Get('Email');
    }
    set Email(value: string | null) {
        this.Set('Email', value);
    }

    /**
    * * Field Name: Phone
    * * Display Name: Phone
    * * SQL Data Type: nvarchar(50)
    * * Description: Primary phone number
    */
    get Phone(): string | null {
        return this.Get('Phone');
    }
    set Phone(value: string | null) {
        this.Set('Phone', value);
    }

    /**
    * * Field Name: FoundedDate
    * * Display Name: Founded Date
    * * SQL Data Type: date
    * * Description: Date the organization was founded or incorporated
    */
    get FoundedDate(): Date | null {
        return this.Get('FoundedDate');
    }
    set FoundedDate(value: Date | null) {
        this.Set('FoundedDate', value);
    }

    /**
    * * Field Name: TaxID
    * * Display Name: Tax ID
    * * SQL Data Type: nvarchar(50)
    * * Description: Tax identification number such as EIN
    */
    get TaxID(): string | null {
        return this.Get('TaxID');
    }
    set TaxID(value: string | null) {
        this.Set('TaxID', value);
    }

    /**
    * * Field Name: Status
    * * Display Name: Status
    * * SQL Data Type: nvarchar(50)
    * * Default Value: Active
    * * Value List Type: List
    * * Possible Values 
    *   * Active
    *   * Dissolved
    *   * Inactive
    * * Description: Current status: Active, Inactive, or Dissolved
    */
    get Status(): 'Active' | 'Dissolved' | 'Inactive' {
        return this.Get('Status');
    }
    set Status(value: 'Active' | 'Dissolved' | 'Inactive') {
        this.Set('Status', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: OrganizationType
    * * Display Name: Organization Type Name
    * * SQL Data Type: nvarchar(100)
    */
    get OrganizationType(): string | null {
        return this.Get('OrganizationType');
    }

    /**
    * * Field Name: Parent
    * * Display Name: Parent Name
    * * SQL Data Type: nvarchar(255)
    */
    get Parent(): string | null {
        return this.Get('Parent');
    }

    /**
    * * Field Name: RootParentID
    * * Display Name: Root Parent
    * * SQL Data Type: uniqueidentifier
    */
    get RootParentID(): string | null {
        return this.Get('RootParentID');
    }

    /**
    * * Field Name: PrimaryAddressLine1
    * * Display Name: Primary Address Line 1
    * * SQL Data Type: nvarchar(255)
    */
    get PrimaryAddressLine1(): string | null {
        return this.Get('PrimaryAddressLine1');
    }

    /**
    * * Field Name: PrimaryAddressLine2
    * * Display Name: Primary Address Line 2
    * * SQL Data Type: nvarchar(255)
    */
    get PrimaryAddressLine2(): string | null {
        return this.Get('PrimaryAddressLine2');
    }

    /**
    * * Field Name: PrimaryAddressCity
    * * Display Name: Primary City
    * * SQL Data Type: nvarchar(100)
    */
    get PrimaryAddressCity(): string | null {
        return this.Get('PrimaryAddressCity');
    }

    /**
    * * Field Name: PrimaryAddressState
    * * Display Name: Primary State
    * * SQL Data Type: nvarchar(100)
    */
    get PrimaryAddressState(): string | null {
        return this.Get('PrimaryAddressState');
    }

    /**
    * * Field Name: PrimaryAddressPostalCode
    * * Display Name: Primary Postal Code
    * * SQL Data Type: nvarchar(20)
    */
    get PrimaryAddressPostalCode(): string | null {
        return this.Get('PrimaryAddressPostalCode');
    }

    /**
    * * Field Name: PrimaryAddressCountry
    * * Display Name: Primary Country
    * * SQL Data Type: nvarchar(100)
    */
    get PrimaryAddressCountry(): string | null {
        return this.Get('PrimaryAddressCountry');
    }

    /**
    * * Field Name: PrimaryAddressType
    * * Display Name: Primary Address Type
    * * SQL Data Type: nvarchar(100)
    */
    get PrimaryAddressType(): string | null {
        return this.Get('PrimaryAddressType');
    }

    /**
    * * Field Name: PrimaryEmail
    * * Display Name: Primary Email
    * * SQL Data Type: nvarchar(500)
    */
    get PrimaryEmail(): string | null {
        return this.Get('PrimaryEmail');
    }

    /**
    * * Field Name: PrimaryPhone
    * * Display Name: Primary Phone
    * * SQL Data Type: nvarchar(500)
    */
    get PrimaryPhone(): string | null {
        return this.Get('PrimaryPhone');
    }

    /**
    * * Field Name: ActivePersonCount
    * * Display Name: Active Person Count
    * * SQL Data Type: int
    */
    get ActivePersonCount(): number | null {
        return this.Get('ActivePersonCount');
    }

    /**
    * * Field Name: ChildOrgCount
    * * Display Name: Child Organization Count
    * * SQL Data Type: int
    */
    get ChildOrgCount(): number | null {
        return this.Get('ChildOrgCount');
    }
}


/**
 * MJ.BizApps.Common: People - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: Person
 * * Base View: vwPeopleExtended
 * * @description Individual people, optionally linked to MJ system user accounts
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ.BizApps.Common: People')
export class mjBizAppsCommonPersonEntity extends BaseEntity<mjBizAppsCommonPersonEntityType> {
    /**
    * Loads the MJ.BizApps.Common: People record from the database
    * @param ID: string - primary key value to load the MJ.BizApps.Common: People record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonPersonEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: FirstName
    * * Display Name: First Name
    * * SQL Data Type: nvarchar(100)
    * * Description: First (given) name
    */
    get FirstName(): string {
        return this.Get('FirstName');
    }
    set FirstName(value: string) {
        this.Set('FirstName', value);
    }

    /**
    * * Field Name: LastName
    * * Display Name: Last Name
    * * SQL Data Type: nvarchar(100)
    * * Description: Last (family) name
    */
    get LastName(): string {
        return this.Get('LastName');
    }
    set LastName(value: string) {
        this.Set('LastName', value);
    }

    /**
    * * Field Name: MiddleName
    * * Display Name: Middle Name
    * * SQL Data Type: nvarchar(100)
    * * Description: Middle name or initial
    */
    get MiddleName(): string | null {
        return this.Get('MiddleName');
    }
    set MiddleName(value: string | null) {
        this.Set('MiddleName', value);
    }

    /**
    * * Field Name: Prefix
    * * Display Name: Prefix
    * * SQL Data Type: nvarchar(20)
    * * Description: Name prefix such as Dr., Mr., Ms., Rev.
    */
    get Prefix(): string | null {
        return this.Get('Prefix');
    }
    set Prefix(value: string | null) {
        this.Set('Prefix', value);
    }

    /**
    * * Field Name: Suffix
    * * Display Name: Suffix
    * * SQL Data Type: nvarchar(20)
    * * Description: Name suffix such as Jr., III, PhD, Esq.
    */
    get Suffix(): string | null {
        return this.Get('Suffix');
    }
    set Suffix(value: string | null) {
        this.Set('Suffix', value);
    }

    /**
    * * Field Name: PreferredName
    * * Display Name: Preferred Name
    * * SQL Data Type: nvarchar(100)
    * * Description: Nickname or preferred name the person goes by
    */
    get PreferredName(): string | null {
        return this.Get('PreferredName');
    }
    set PreferredName(value: string | null) {
        this.Set('PreferredName', value);
    }

    /**
    * * Field Name: Title
    * * Display Name: Title
    * * SQL Data Type: nvarchar(200)
    * * Description: Professional or job title, e.g. VP of Engineering, Board Director
    */
    get Title(): string | null {
        return this.Get('Title');
    }
    set Title(value: string | null) {
        this.Set('Title', value);
    }

    /**
    * * Field Name: Email
    * * Display Name: Email
    * * SQL Data Type: nvarchar(255)
    * * Description: Primary email address for this person
    */
    get Email(): string | null {
        return this.Get('Email');
    }
    set Email(value: string | null) {
        this.Set('Email', value);
    }

    /**
    * * Field Name: Phone
    * * Display Name: Phone
    * * SQL Data Type: nvarchar(50)
    * * Description: Primary phone number for this person
    */
    get Phone(): string | null {
        return this.Get('Phone');
    }
    set Phone(value: string | null) {
        this.Set('Phone', value);
    }

    /**
    * * Field Name: DateOfBirth
    * * Display Name: Date of Birth
    * * SQL Data Type: date
    * * Description: Date of birth
    */
    get DateOfBirth(): Date | null {
        return this.Get('DateOfBirth');
    }
    set DateOfBirth(value: Date | null) {
        this.Set('DateOfBirth', value);
    }

    /**
    * * Field Name: Gender
    * * Display Name: Gender
    * * SQL Data Type: nvarchar(50)
    * * Description: Gender identity
    */
    get Gender(): string | null {
        return this.Get('Gender');
    }
    set Gender(value: string | null) {
        this.Set('Gender', value);
    }

    /**
    * * Field Name: PhotoURL
    * * Display Name: Photo URL
    * * SQL Data Type: nvarchar(1000)
    * * Description: URL to profile photo or avatar image
    */
    get PhotoURL(): string | null {
        return this.Get('PhotoURL');
    }
    set PhotoURL(value: string | null) {
        this.Set('PhotoURL', value);
    }

    /**
    * * Field Name: Bio
    * * Display Name: Biography
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Biographical text or notes about this person
    */
    get Bio(): string | null {
        return this.Get('Bio');
    }
    set Bio(value: string | null) {
        this.Set('Bio', value);
    }

    /**
    * * Field Name: LinkedUserID
    * * Display Name: Linked User
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ: Users (vwUsers.ID)
    */
    get LinkedUserID(): string | null {
        return this.Get('LinkedUserID');
    }
    set LinkedUserID(value: string | null) {
        this.Set('LinkedUserID', value);
    }

    /**
    * * Field Name: Status
    * * Display Name: Status
    * * SQL Data Type: nvarchar(50)
    * * Default Value: Active
    * * Value List Type: List
    * * Possible Values 
    *   * Active
    *   * Deceased
    *   * Inactive
    * * Description: Current status: Active, Inactive, or Deceased
    */
    get Status(): 'Active' | 'Deceased' | 'Inactive' {
        return this.Get('Status');
    }
    set Status(value: 'Active' | 'Deceased' | 'Inactive') {
        this.Set('Status', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: LinkedUser
    * * Display Name: Linked User Account
    * * SQL Data Type: nvarchar(100)
    */
    get LinkedUser(): string | null {
        return this.Get('LinkedUser');
    }

    /**
    * * Field Name: DisplayName
    * * Display Name: Display Name
    * * SQL Data Type: nvarchar(244)
    */
    get DisplayName(): string | null {
        return this.Get('DisplayName');
    }

    /**
    * * Field Name: PrimaryAddressLine1
    * * Display Name: Primary Address Line 1
    * * SQL Data Type: nvarchar(255)
    */
    get PrimaryAddressLine1(): string | null {
        return this.Get('PrimaryAddressLine1');
    }

    /**
    * * Field Name: PrimaryAddressLine2
    * * Display Name: Primary Address Line 2
    * * SQL Data Type: nvarchar(255)
    */
    get PrimaryAddressLine2(): string | null {
        return this.Get('PrimaryAddressLine2');
    }

    /**
    * * Field Name: PrimaryAddressCity
    * * Display Name: Primary City
    * * SQL Data Type: nvarchar(100)
    */
    get PrimaryAddressCity(): string | null {
        return this.Get('PrimaryAddressCity');
    }

    /**
    * * Field Name: PrimaryAddressState
    * * Display Name: Primary State
    * * SQL Data Type: nvarchar(100)
    */
    get PrimaryAddressState(): string | null {
        return this.Get('PrimaryAddressState');
    }

    /**
    * * Field Name: PrimaryAddressPostalCode
    * * Display Name: Primary Postal Code
    * * SQL Data Type: nvarchar(20)
    */
    get PrimaryAddressPostalCode(): string | null {
        return this.Get('PrimaryAddressPostalCode');
    }

    /**
    * * Field Name: PrimaryAddressCountry
    * * Display Name: Primary Country
    * * SQL Data Type: nvarchar(100)
    */
    get PrimaryAddressCountry(): string | null {
        return this.Get('PrimaryAddressCountry');
    }

    /**
    * * Field Name: PrimaryAddressLatitude
    * * Display Name: Primary Latitude
    * * SQL Data Type: decimal(9, 6)
    */
    get PrimaryAddressLatitude(): number | null {
        return this.Get('PrimaryAddressLatitude');
    }

    /**
    * * Field Name: PrimaryAddressLongitude
    * * Display Name: Primary Longitude
    * * SQL Data Type: decimal(9, 6)
    */
    get PrimaryAddressLongitude(): number | null {
        return this.Get('PrimaryAddressLongitude');
    }

    /**
    * * Field Name: PrimaryAddressType
    * * Display Name: Address Type
    * * SQL Data Type: nvarchar(100)
    */
    get PrimaryAddressType(): string | null {
        return this.Get('PrimaryAddressType');
    }

    /**
    * * Field Name: PrimaryEmail
    * * Display Name: Primary Email
    * * SQL Data Type: nvarchar(500)
    */
    get PrimaryEmail(): string | null {
        return this.Get('PrimaryEmail');
    }

    /**
    * * Field Name: PrimaryPhone
    * * Display Name: Primary Phone
    * * SQL Data Type: nvarchar(500)
    */
    get PrimaryPhone(): string | null {
        return this.Get('PrimaryPhone');
    }

    /**
    * * Field Name: CurrentOrganizationID
    * * Display Name: Current Organization
    * * SQL Data Type: uniqueidentifier
    */
    get CurrentOrganizationID(): string | null {
        return this.Get('CurrentOrganizationID');
    }

    /**
    * * Field Name: CurrentOrganizationName
    * * Display Name: Current Organization Name
    * * SQL Data Type: nvarchar(255)
    */
    get CurrentOrganizationName(): string | null {
        return this.Get('CurrentOrganizationName');
    }

    /**
    * * Field Name: CurrentJobTitle
    * * Display Name: Current Job Title
    * * SQL Data Type: nvarchar(255)
    */
    get CurrentJobTitle(): string | null {
        return this.Get('CurrentJobTitle');
    }
}


/**
 * MJ.BizApps.Common: Relationship Types - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: RelationshipType
 * * Base View: vwRelationshipTypes
 * * @description Defines types of relationships between people and organizations with directionality and labeling
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ.BizApps.Common: Relationship Types')
export class mjBizAppsCommonRelationshipTypeEntity extends BaseEntity<mjBizAppsCommonRelationshipTypeEntityType> {
    /**
    * Loads the MJ.BizApps.Common: Relationship Types record from the database
    * @param ID: string - primary key value to load the MJ.BizApps.Common: Relationship Types record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonRelationshipTypeEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: Name
    * * Display Name: Name
    * * SQL Data Type: nvarchar(100)
    * * Description: Display name for the relationship type, e.g. Employee, Spouse, Partner
    */
    get Name(): string {
        return this.Get('Name');
    }
    set Name(value: string) {
        this.Set('Name', value);
    }

    /**
    * * Field Name: Description
    * * Display Name: Description
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Detailed description of this relationship type
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: Category
    * * Display Name: Category
    * * SQL Data Type: nvarchar(50)
    * * Value List Type: List
    * * Possible Values 
    *   * OrganizationToOrganization
    *   * PersonToOrganization
    *   * PersonToPerson
    * * Description: Which entity types this relationship connects: PersonToPerson, PersonToOrganization, or OrganizationToOrganization
    */
    get Category(): 'OrganizationToOrganization' | 'PersonToOrganization' | 'PersonToPerson' {
        return this.Get('Category');
    }
    set Category(value: 'OrganizationToOrganization' | 'PersonToOrganization' | 'PersonToPerson') {
        this.Set('Category', value);
    }

    /**
    * * Field Name: IsDirectional
    * * Display Name: Is Directional
    * * SQL Data Type: bit
    * * Default Value: 1
    * * Description: Whether the relationship has a direction. False for symmetric relationships like Spouse or Partner
    */
    get IsDirectional(): boolean {
        return this.Get('IsDirectional');
    }
    set IsDirectional(value: boolean) {
        this.Set('IsDirectional', value);
    }

    /**
    * * Field Name: ForwardLabel
    * * Display Name: Forward Label
    * * SQL Data Type: nvarchar(100)
    * * Description: Label describing the From-to-To direction, e.g. is employee of, is parent of
    */
    get ForwardLabel(): string | null {
        return this.Get('ForwardLabel');
    }
    set ForwardLabel(value: string | null) {
        this.Set('ForwardLabel', value);
    }

    /**
    * * Field Name: ReverseLabel
    * * Display Name: Reverse Label
    * * SQL Data Type: nvarchar(100)
    * * Description: Label describing the To-to-From direction, e.g. employs, is child of
    */
    get ReverseLabel(): string | null {
        return this.Get('ReverseLabel');
    }
    set ReverseLabel(value: string | null) {
        this.Set('ReverseLabel', value);
    }

    /**
    * * Field Name: IsActive
    * * Display Name: Active
    * * SQL Data Type: bit
    * * Default Value: 1
    * * Description: Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records
    */
    get IsActive(): boolean {
        return this.Get('IsActive');
    }
    set IsActive(value: boolean) {
        this.Set('IsActive', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }
}


/**
 * MJ.BizApps.Common: Relationships - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: Relationship
 * * Base View: vwRelationships
 * * @description Typed, directional links between people and organizations supporting Person-to-Person, Person-to-Organization, and Organization-to-Organization relationships
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ.BizApps.Common: Relationships')
export class mjBizAppsCommonRelationshipEntity extends BaseEntity<mjBizAppsCommonRelationshipEntityType> {
    /**
    * Loads the MJ.BizApps.Common: Relationships record from the database
    * @param ID: string - primary key value to load the MJ.BizApps.Common: Relationships record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonRelationshipEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * Validate() method override for MJ.BizApps.Common: Relationships entity. This is an auto-generated method that invokes the generated validators for this entity for the following fields:
    * * Table-Level: A relationship must be linked to exactly one source: either a person or an organization. This ensures that the origin of the relationship is clearly defined and prevents data where both or neither are specified.
    * * Table-Level: A relationship must be linked to exactly one target: either a person or an organization. This ensures that the destination of the relationship is clearly defined and prevents ambiguous or missing links.
    * @public
    * @method
    * @override
    */
    public override Validate(): ValidationResult {
        const result = super.Validate();
        this.ValidateFromPersonOrFromOrganizationExclusivity(result);
        this.ValidateToPersonOrToOrganizationExclusivity(result);
        result.Success = result.Success && (result.Errors.length === 0);

        return result;
    }

    /**
    * A relationship must be linked to exactly one source: either a person or an organization. This ensures that the origin of the relationship is clearly defined and prevents data where both or neither are specified.
    * @param result - the ValidationResult object to add any errors or warnings to
    * @public
    * @method
    */
    public ValidateFromPersonOrFromOrganizationExclusivity(result: ValidationResult) {
    	const hasPerson = this.FromPersonID != null;
    	const hasOrg = this.FromOrganizationID != null;
    
    	if ((hasPerson && hasOrg) || (!hasPerson && !hasOrg)) {
    		result.Errors.push(new ValidationErrorInfo(
    			"FromPersonID",
    			"You must specify either a Person or an Organization as the source, but not both and not neither.",
    			this.FromPersonID,
    			ValidationErrorType.Failure
    		));
    	}
    }

    /**
    * A relationship must be linked to exactly one target: either a person or an organization. This ensures that the destination of the relationship is clearly defined and prevents ambiguous or missing links.
    * @param result - the ValidationResult object to add any errors or warnings to
    * @public
    * @method
    */
    public ValidateToPersonOrToOrganizationExclusivity(result: ValidationResult) {
    	// Ensure that exactly one of ToPersonID or ToOrganizationID is populated
    	const hasPerson = this.ToPersonID != null;
    	const hasOrganization = this.ToOrganizationID != null;
    
    	if ((hasPerson && hasOrganization) || (!hasPerson && !hasOrganization)) {
    		result.Errors.push(new ValidationErrorInfo(
    			"ToPersonID",
    			"A relationship must be associated with either a person or an organization, but not both and not neither.",
    			this.ToPersonID,
    			ValidationErrorType.Failure
    		));
    	}
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: RelationshipTypeID
    * * Display Name: Relationship Type
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ.BizApps.Common: Relationship Types (vwRelationshipTypes.ID)
    */
    get RelationshipTypeID(): string {
        return this.Get('RelationshipTypeID');
    }
    set RelationshipTypeID(value: string) {
        this.Set('RelationshipTypeID', value);
    }

    /**
    * * Field Name: FromPersonID
    * * Display Name: From Person
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ.BizApps.Common: People (vwPeopleExtended.ID)
    */
    get FromPersonID(): string | null {
        return this.Get('FromPersonID');
    }
    set FromPersonID(value: string | null) {
        this.Set('FromPersonID', value);
    }

    /**
    * * Field Name: FromOrganizationID
    * * Display Name: From Organization
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ.BizApps.Common: Organizations (vwOrganizationsExtended.ID)
    */
    get FromOrganizationID(): string | null {
        return this.Get('FromOrganizationID');
    }
    set FromOrganizationID(value: string | null) {
        this.Set('FromOrganizationID', value);
    }

    /**
    * * Field Name: ToPersonID
    * * Display Name: To Person
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ.BizApps.Common: People (vwPeopleExtended.ID)
    */
    get ToPersonID(): string | null {
        return this.Get('ToPersonID');
    }
    set ToPersonID(value: string | null) {
        this.Set('ToPersonID', value);
    }

    /**
    * * Field Name: ToOrganizationID
    * * Display Name: To Organization
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ.BizApps.Common: Organizations (vwOrganizationsExtended.ID)
    */
    get ToOrganizationID(): string | null {
        return this.Get('ToOrganizationID');
    }
    set ToOrganizationID(value: string | null) {
        this.Set('ToOrganizationID', value);
    }

    /**
    * * Field Name: Title
    * * Display Name: Title
    * * SQL Data Type: nvarchar(255)
    * * Description: Contextual title for this specific relationship, e.g. CEO, Primary Contact, Founding Member
    */
    get Title(): string | null {
        return this.Get('Title');
    }
    set Title(value: string | null) {
        this.Set('Title', value);
    }

    /**
    * * Field Name: StartDate
    * * Display Name: Start Date
    * * SQL Data Type: date
    * * Description: Date the relationship began
    */
    get StartDate(): Date | null {
        return this.Get('StartDate');
    }
    set StartDate(value: Date | null) {
        this.Set('StartDate', value);
    }

    /**
    * * Field Name: EndDate
    * * Display Name: End Date
    * * SQL Data Type: date
    * * Description: Date the relationship ended, if applicable
    */
    get EndDate(): Date | null {
        return this.Get('EndDate');
    }
    set EndDate(value: Date | null) {
        this.Set('EndDate', value);
    }

    /**
    * * Field Name: Status
    * * Display Name: Status
    * * SQL Data Type: nvarchar(50)
    * * Default Value: Active
    * * Value List Type: List
    * * Possible Values 
    *   * Active
    *   * Ended
    *   * Inactive
    * * Description: Current status: Active, Inactive, or Ended
    */
    get Status(): 'Active' | 'Ended' | 'Inactive' {
        return this.Get('Status');
    }
    set Status(value: 'Active' | 'Ended' | 'Inactive') {
        this.Set('Status', value);
    }

    /**
    * * Field Name: Notes
    * * Display Name: Notes
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Additional notes about this relationship
    */
    get Notes(): string | null {
        return this.Get('Notes');
    }
    set Notes(value: string | null) {
        this.Set('Notes', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: RelationshipType
    * * Display Name: Relationship Type
    * * SQL Data Type: nvarchar(100)
    */
    get RelationshipType(): string {
        return this.Get('RelationshipType');
    }

    /**
    * * Field Name: FromPerson
    * * Display Name: From Person
    * * SQL Data Type: nvarchar(100)
    */
    get FromPerson(): string | null {
        return this.Get('FromPerson');
    }

    /**
    * * Field Name: FromOrganization
    * * Display Name: From Organization
    * * SQL Data Type: nvarchar(255)
    */
    get FromOrganization(): string | null {
        return this.Get('FromOrganization');
    }

    /**
    * * Field Name: ToPerson
    * * Display Name: To Person
    * * SQL Data Type: nvarchar(100)
    */
    get ToPerson(): string | null {
        return this.Get('ToPerson');
    }

    /**
    * * Field Name: ToOrganization
    * * Display Name: To Organization
    * * SQL Data Type: nvarchar(255)
    */
    get ToOrganization(): string | null {
        return this.Get('ToOrganization');
    }
}
