-- BizAppsCommon Schema and Tables
-- Common entities shared across business applications:
-- Person, Organization, Address, ContactMethod, Relationship

CREATE SCHEMA __mj_BizAppsCommon;
GO

---------------------------------------------------------------------------
-- Organization Types: Company, Non-Profit, Association, etc.
---------------------------------------------------------------------------
CREATE TABLE __mj_BizAppsCommon.OrganizationType (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX),
    IconClass NVARCHAR(100),
    CONSTRAINT PK_OrganizationType PRIMARY KEY (ID),
    CONSTRAINT UQ_OrganizationType_Name UNIQUE (Name)
);
GO

---------------------------------------------------------------------------
-- Address Types: Home, Work, Mailing, Billing, etc.
---------------------------------------------------------------------------
CREATE TABLE __mj_BizAppsCommon.AddressType (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX),
    DefaultRank INT NOT NULL DEFAULT 100,
    CONSTRAINT PK_AddressType PRIMARY KEY (ID),
    CONSTRAINT UQ_AddressType_Name UNIQUE (Name)
);
GO

---------------------------------------------------------------------------
-- Contact Types: Phone, Mobile, Email, LinkedIn, etc.
---------------------------------------------------------------------------
CREATE TABLE __mj_BizAppsCommon.ContactType (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX),
    IconClass NVARCHAR(100),
    CONSTRAINT PK_ContactType PRIMARY KEY (ID),
    CONSTRAINT UQ_ContactType_Name UNIQUE (Name)
);
GO

---------------------------------------------------------------------------
-- Relationship Types with directionality and category
---------------------------------------------------------------------------
CREATE TABLE __mj_BizAppsCommon.RelationshipType (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX),
    Category NVARCHAR(50) NOT NULL,
    IsDirectional BIT NOT NULL DEFAULT 1,
    ForwardLabel NVARCHAR(100),
    ReverseLabel NVARCHAR(100),
    CONSTRAINT PK_RelationshipType PRIMARY KEY (ID),
    CONSTRAINT UQ_RelationshipType_Name UNIQUE (Name),
    CONSTRAINT CK_RelationshipType_Category CHECK (Category IN ('PersonToPerson', 'PersonToOrganization', 'OrganizationToOrganization'))
);
GO

---------------------------------------------------------------------------
-- Person: individual people, optionally linked to MJ system users
---------------------------------------------------------------------------
CREATE TABLE __mj_BizAppsCommon.Person (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    MiddleName NVARCHAR(100),
    Prefix NVARCHAR(20),
    Suffix NVARCHAR(20),
    PreferredName NVARCHAR(100),
    Title NVARCHAR(200),
    Email NVARCHAR(255),
    Phone NVARCHAR(50),
    DateOfBirth DATE,
    Gender NVARCHAR(50),
    PhotoURL NVARCHAR(1000),
    Bio NVARCHAR(MAX),
    LinkedUserID UNIQUEIDENTIFIER,
    Status NVARCHAR(50) NOT NULL DEFAULT 'Active',
    CONSTRAINT PK_Person PRIMARY KEY (ID),
    CONSTRAINT FK_Person_LinkedUser FOREIGN KEY (LinkedUserID) REFERENCES __mj.[User](ID),
    CONSTRAINT CK_Person_Status CHECK (Status IN ('Active', 'Inactive', 'Deceased'))
);
GO

---------------------------------------------------------------------------
-- Organization: companies, associations, government bodies, etc.
---------------------------------------------------------------------------
CREATE TABLE __mj_BizAppsCommon.Organization (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    Name NVARCHAR(255) NOT NULL,
    LegalName NVARCHAR(255),
    OrganizationTypeID UNIQUEIDENTIFIER,
    ParentID UNIQUEIDENTIFIER,
    Website NVARCHAR(1000),
    LogoURL NVARCHAR(1000),
    Description NVARCHAR(MAX),
    Email NVARCHAR(255),
    Phone NVARCHAR(50),
    FoundedDate DATE,
    TaxID NVARCHAR(50),
    Status NVARCHAR(50) NOT NULL DEFAULT 'Active',
    CONSTRAINT PK_Organization PRIMARY KEY (ID),
    CONSTRAINT FK_Organization_Type FOREIGN KEY (OrganizationTypeID) REFERENCES __mj_BizAppsCommon.OrganizationType(ID),
    CONSTRAINT FK_Organization_Parent FOREIGN KEY (ParentID) REFERENCES __mj_BizAppsCommon.Organization(ID),
    CONSTRAINT CK_Organization_Status CHECK (Status IN ('Active', 'Inactive', 'Dissolved'))
);
GO

---------------------------------------------------------------------------
-- Address: standalone physical location records, shared via AddressLink
---------------------------------------------------------------------------
CREATE TABLE __mj_BizAppsCommon.Address (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    Line1 NVARCHAR(255) NOT NULL,
    Line2 NVARCHAR(255),
    Line3 NVARCHAR(255),
    City NVARCHAR(100) NOT NULL,
    StateProvince NVARCHAR(100),
    PostalCode NVARCHAR(20),
    Country NVARCHAR(100) NOT NULL DEFAULT 'US',
    Latitude DECIMAL(9,6),
    Longitude DECIMAL(9,6),
    CONSTRAINT PK_Address PRIMARY KEY (ID)
);
GO

---------------------------------------------------------------------------
-- AddressLink: polymorphic link from Address to any entity record
---------------------------------------------------------------------------
CREATE TABLE __mj_BizAppsCommon.AddressLink (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    AddressID UNIQUEIDENTIFIER NOT NULL,
    EntityID UNIQUEIDENTIFIER NOT NULL,
    RecordID NVARCHAR(700) NOT NULL,
    AddressTypeID UNIQUEIDENTIFIER NOT NULL,
    IsPrimary BIT NOT NULL DEFAULT 0,
    Rank INT,
    CONSTRAINT PK_AddressLink PRIMARY KEY (ID),
    CONSTRAINT FK_AddressLink_Address FOREIGN KEY (AddressID) REFERENCES __mj_BizAppsCommon.Address(ID),
    CONSTRAINT FK_AddressLink_Entity FOREIGN KEY (EntityID) REFERENCES __mj.Entity(ID),
    CONSTRAINT FK_AddressLink_AddressType FOREIGN KEY (AddressTypeID) REFERENCES __mj_BizAppsCommon.AddressType(ID)
);
GO

---------------------------------------------------------------------------
-- ContactMethod: additional contact info beyond Person/Org primary fields
---------------------------------------------------------------------------
CREATE TABLE __mj_BizAppsCommon.ContactMethod (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    PersonID UNIQUEIDENTIFIER,
    OrganizationID UNIQUEIDENTIFIER,
    ContactTypeID UNIQUEIDENTIFIER NOT NULL,
    Value NVARCHAR(500) NOT NULL,
    Label NVARCHAR(100),
    IsPrimary BIT NOT NULL DEFAULT 0,
    CONSTRAINT PK_ContactMethod PRIMARY KEY (ID),
    CONSTRAINT FK_ContactMethod_Person FOREIGN KEY (PersonID) REFERENCES __mj_BizAppsCommon.Person(ID),
    CONSTRAINT FK_ContactMethod_Organization FOREIGN KEY (OrganizationID) REFERENCES __mj_BizAppsCommon.Organization(ID),
    CONSTRAINT FK_ContactMethod_ContactType FOREIGN KEY (ContactTypeID) REFERENCES __mj_BizAppsCommon.ContactType(ID),
    CONSTRAINT CK_ContactMethod_Owner CHECK (PersonID IS NOT NULL OR OrganizationID IS NOT NULL)
);
GO

---------------------------------------------------------------------------
-- Relationship: typed links between Person/Org in any combination
---------------------------------------------------------------------------
CREATE TABLE __mj_BizAppsCommon.Relationship (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    RelationshipTypeID UNIQUEIDENTIFIER NOT NULL,
    FromPersonID UNIQUEIDENTIFIER,
    FromOrganizationID UNIQUEIDENTIFIER,
    ToPersonID UNIQUEIDENTIFIER,
    ToOrganizationID UNIQUEIDENTIFIER,
    Title NVARCHAR(255),
    StartDate DATE,
    EndDate DATE,
    Status NVARCHAR(50) NOT NULL DEFAULT 'Active',
    Notes NVARCHAR(MAX),
    CONSTRAINT PK_Relationship PRIMARY KEY (ID),
    CONSTRAINT FK_Relationship_Type FOREIGN KEY (RelationshipTypeID) REFERENCES __mj_BizAppsCommon.RelationshipType(ID),
    CONSTRAINT FK_Relationship_FromPerson FOREIGN KEY (FromPersonID) REFERENCES __mj_BizAppsCommon.Person(ID),
    CONSTRAINT FK_Relationship_FromOrganization FOREIGN KEY (FromOrganizationID) REFERENCES __mj_BizAppsCommon.Organization(ID),
    CONSTRAINT FK_Relationship_ToPerson FOREIGN KEY (ToPersonID) REFERENCES __mj_BizAppsCommon.Person(ID),
    CONSTRAINT FK_Relationship_ToOrganization FOREIGN KEY (ToOrganizationID) REFERENCES __mj_BizAppsCommon.Organization(ID),
    CONSTRAINT CK_Relationship_Status CHECK (Status IN ('Active', 'Inactive', 'Ended')),
    CONSTRAINT CK_Relationship_FromOwner CHECK (
        (FromPersonID IS NOT NULL AND FromOrganizationID IS NULL) OR
        (FromPersonID IS NULL AND FromOrganizationID IS NOT NULL)
    ),
    CONSTRAINT CK_Relationship_ToOwner CHECK (
        (ToPersonID IS NOT NULL AND ToOrganizationID IS NULL) OR
        (ToPersonID IS NULL AND ToOrganizationID IS NOT NULL)
    )
);
GO

---------------------------------------------------------------------------
-- EXTENDED PROPERTIES: Schema
---------------------------------------------------------------------------
EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Common business application entities shared across apps: Person, Organization, Address, ContactMethod, Relationship',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon';
GO

---------------------------------------------------------------------------
-- EXTENDED PROPERTIES: OrganizationType
---------------------------------------------------------------------------
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Categories of organizations such as Company, Non-Profit, Association, Government',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'OrganizationType';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Display name for the organization type',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'OrganizationType', @level2type = N'COLUMN', @level2name = N'Name';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Detailed description of this organization type',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'OrganizationType', @level2type = N'COLUMN', @level2name = N'Description';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Font Awesome icon class for UI display',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'OrganizationType', @level2type = N'COLUMN', @level2name = N'IconClass';
GO

---------------------------------------------------------------------------
-- EXTENDED PROPERTIES: AddressType
---------------------------------------------------------------------------
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Categories of addresses such as Home, Work, Mailing, Billing',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'AddressType';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Display name for the address type',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'AddressType', @level2type = N'COLUMN', @level2name = N'Name';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Detailed description of this address type',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'AddressType', @level2type = N'COLUMN', @level2name = N'Description';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Default sort order for this address type in dropdown lists. Lower values appear first. Can be overridden per-record via AddressLink.Rank',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'AddressType', @level2type = N'COLUMN', @level2name = N'DefaultRank';
GO

---------------------------------------------------------------------------
-- EXTENDED PROPERTIES: ContactType
---------------------------------------------------------------------------
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Categories of contact methods such as Phone, Mobile, Email, LinkedIn, Website',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'ContactType';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Display name for the contact type',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'ContactType', @level2type = N'COLUMN', @level2name = N'Name';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Detailed description of this contact type',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'ContactType', @level2type = N'COLUMN', @level2name = N'Description';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Font Awesome icon class for UI display',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'ContactType', @level2type = N'COLUMN', @level2name = N'IconClass';
GO

---------------------------------------------------------------------------
-- EXTENDED PROPERTIES: RelationshipType
---------------------------------------------------------------------------
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Defines types of relationships between people and organizations with directionality and labeling',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'RelationshipType';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Display name for the relationship type, e.g. Employee, Spouse, Partner',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'RelationshipType', @level2type = N'COLUMN', @level2name = N'Name';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Detailed description of this relationship type',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'RelationshipType', @level2type = N'COLUMN', @level2name = N'Description';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Which entity types this relationship connects: PersonToPerson, PersonToOrganization, or OrganizationToOrganization',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'RelationshipType', @level2type = N'COLUMN', @level2name = N'Category';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Whether the relationship has a direction. False for symmetric relationships like Spouse or Partner',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'RelationshipType', @level2type = N'COLUMN', @level2name = N'IsDirectional';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Label describing the From-to-To direction, e.g. is employee of, is parent of',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'RelationshipType', @level2type = N'COLUMN', @level2name = N'ForwardLabel';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Label describing the To-to-From direction, e.g. employs, is child of',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'RelationshipType', @level2type = N'COLUMN', @level2name = N'ReverseLabel';
GO

---------------------------------------------------------------------------
-- EXTENDED PROPERTIES: Person
---------------------------------------------------------------------------
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Individual people, optionally linked to MJ system user accounts',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Person';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'First (given) name',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'FirstName';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Last (family) name',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'LastName';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Middle name or initial',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'MiddleName';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Name prefix such as Dr., Mr., Ms., Rev.',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'Prefix';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Name suffix such as Jr., III, PhD, Esq.',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'Suffix';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Nickname or preferred name the person goes by',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'PreferredName';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Professional or job title, e.g. VP of Engineering, Board Director',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'Title';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Primary email address for this person',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'Email';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Primary phone number for this person',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'Phone';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Date of birth',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'DateOfBirth';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Gender identity',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'Gender';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'URL to profile photo or avatar image',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'PhotoURL';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Biographical text or notes about this person',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'Bio';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Current status: Active, Inactive, or Deceased',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'Status';
GO

---------------------------------------------------------------------------
-- EXTENDED PROPERTIES: Organization
---------------------------------------------------------------------------
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Companies, associations, government bodies, and other organizations with hierarchy support',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Organization';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Common or display name of the organization',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Organization', @level2type = N'COLUMN', @level2name = N'Name';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Full legal name if different from display name',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Organization', @level2type = N'COLUMN', @level2name = N'LegalName';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Primary website URL',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Organization', @level2type = N'COLUMN', @level2name = N'Website';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'URL to organization logo image',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Organization', @level2type = N'COLUMN', @level2name = N'LogoURL';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Description of the organization purpose and scope',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Organization', @level2type = N'COLUMN', @level2name = N'Description';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Primary contact email address',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Organization', @level2type = N'COLUMN', @level2name = N'Email';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Primary phone number',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Organization', @level2type = N'COLUMN', @level2name = N'Phone';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Date the organization was founded or incorporated',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Organization', @level2type = N'COLUMN', @level2name = N'FoundedDate';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Tax identification number such as EIN',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Organization', @level2type = N'COLUMN', @level2name = N'TaxID';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Current status: Active, Inactive, or Dissolved',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Organization', @level2type = N'COLUMN', @level2name = N'Status';
GO

---------------------------------------------------------------------------
-- EXTENDED PROPERTIES: Address
---------------------------------------------------------------------------
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Standalone physical address records linked to entities via AddressLink for sharing across people and organizations',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Address';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Street address line 1',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Address', @level2type = N'COLUMN', @level2name = N'Line1';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Street address line 2 (suite, apt, etc.)',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Address', @level2type = N'COLUMN', @level2name = N'Line2';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Street address line 3 (additional detail)',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Address', @level2type = N'COLUMN', @level2name = N'Line3';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'City or locality name',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Address', @level2type = N'COLUMN', @level2name = N'City';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'State, province, or region',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Address', @level2type = N'COLUMN', @level2name = N'StateProvince';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Postal or ZIP code',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Address', @level2type = N'COLUMN', @level2name = N'PostalCode';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Country code or name, defaults to US',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Address', @level2type = N'COLUMN', @level2name = N'Country';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Geographic latitude for mapping',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Address', @level2type = N'COLUMN', @level2name = N'Latitude';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Geographic longitude for mapping',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Address', @level2type = N'COLUMN', @level2name = N'Longitude';
GO

---------------------------------------------------------------------------
-- EXTENDED PROPERTIES: AddressLink
---------------------------------------------------------------------------
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Polymorphic link table connecting Address records to any entity record in the system via EntityID and RecordID',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'AddressLink';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Primary key value(s) of the linked record. NVARCHAR(700) to support concatenated composite keys for entities without single-valued primary keys',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'AddressLink', @level2type = N'COLUMN', @level2name = N'RecordID';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Whether this is the primary address for the linked record. Only one address per entity record should be marked primary',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'AddressLink', @level2type = N'COLUMN', @level2name = N'IsPrimary';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Sort order override for this specific link. When NULL, falls back to AddressType.DefaultRank. Lower values appear first',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'AddressLink', @level2type = N'COLUMN', @level2name = N'Rank';
GO

---------------------------------------------------------------------------
-- EXTENDED PROPERTIES: ContactMethod
---------------------------------------------------------------------------
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Additional contact methods for people and organizations beyond the primary email and phone fields',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'ContactMethod';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'The contact value: phone number, email address, URL, social media handle, etc.',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'ContactMethod', @level2type = N'COLUMN', @level2name = N'Value';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Descriptive label such as Work cell, Personal Gmail, Corporate LinkedIn',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'ContactMethod', @level2type = N'COLUMN', @level2name = N'Label';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Whether this is the primary contact method of its type for the linked person or organization',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'ContactMethod', @level2type = N'COLUMN', @level2name = N'IsPrimary';
GO

---------------------------------------------------------------------------
-- EXTENDED PROPERTIES: Relationship
---------------------------------------------------------------------------
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Typed, directional links between people and organizations supporting Person-to-Person, Person-to-Organization, and Organization-to-Organization relationships',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Relationship';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Contextual title for this specific relationship, e.g. CEO, Primary Contact, Founding Member',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Relationship', @level2type = N'COLUMN', @level2name = N'Title';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Date the relationship began',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Relationship', @level2type = N'COLUMN', @level2name = N'StartDate';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Date the relationship ended, if applicable',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Relationship', @level2type = N'COLUMN', @level2name = N'EndDate';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Current status: Active, Inactive, or Ended',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Relationship', @level2type = N'COLUMN', @level2name = N'Status';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Additional notes about this relationship',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'Relationship', @level2type = N'COLUMN', @level2name = N'Notes';
GO
