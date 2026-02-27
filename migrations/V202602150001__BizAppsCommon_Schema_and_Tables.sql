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


























































-- CODE GEN RUN 
/* SQL generated to create new entity Common: Address Types */

      INSERT INTO [${flyway:defaultSchema}].Entity (
         ID,
         Name,
         DisplayName,
         Description,
         NameSuffix,
         BaseTable,
         BaseView,
         SchemaName,
         IncludeInAPI,
         AllowUserSearchAPI
         , TrackRecordChanges
         , AuditRecordAccess
         , AuditViewRuns
         , AllowAllRowsAPI
         , AllowCreateAPI
         , AllowUpdateAPI
         , AllowDeleteAPI
         , UserViewMaxRows
      )
      VALUES (
         '66fa272f-59bb-4105-a1f3-4e5d4d63f381',
         'Common: Address Types',
         'Address Types',
         NULL,
         NULL,
         'AddressType',
         'vwAddressTypes',
         '${flyway:defaultSchema}_BizAppsCommon',
         1,
         0
         , 1
         , 0
         , 0
         , 0
         , 1
         , 1
         , 1
         , 1000
      )
   

/* SQL generated to create new application ${flyway:defaultSchema}_BizAppsCommon */
INSERT INTO [${flyway:defaultSchema}].Application (ID, Name, Description, SchemaAutoAddNewEntities, Path, AutoUpdatePath)
                       VALUES ('691ed607-8def-4598-8121-d4d2b45bc110', '${flyway:defaultSchema}_BizAppsCommon', 'Generated for schema', '${flyway:defaultSchema}_BizAppsCommon', 'mjbizappscommon', 1)

/* SQL generated to add new entity Common: Address Types to application ID: '691ed607-8def-4598-8121-d4d2b45bc110' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('691ed607-8def-4598-8121-d4d2b45bc110', '66fa272f-59bb-4105-a1f3-4e5d4d63f381', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = '691ed607-8def-4598-8121-d4d2b45bc110'))

/* SQL generated to add new permission for entity Common: Address Types for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('66fa272f-59bb-4105-a1f3-4e5d4d63f381', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity Common: Address Types for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('66fa272f-59bb-4105-a1f3-4e5d4d63f381', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity Common: Address Types for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('66fa272f-59bb-4105-a1f3-4e5d4d63f381', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL generated to create new entity Common: Contact Types */

      INSERT INTO [${flyway:defaultSchema}].Entity (
         ID,
         Name,
         DisplayName,
         Description,
         NameSuffix,
         BaseTable,
         BaseView,
         SchemaName,
         IncludeInAPI,
         AllowUserSearchAPI
         , TrackRecordChanges
         , AuditRecordAccess
         , AuditViewRuns
         , AllowAllRowsAPI
         , AllowCreateAPI
         , AllowUpdateAPI
         , AllowDeleteAPI
         , UserViewMaxRows
      )
      VALUES (
         'd17353e5-1fb0-4940-8d91-3e4007549200',
         'Common: Contact Types',
         'Contact Types',
         NULL,
         NULL,
         'ContactType',
         'vwContactTypes',
         '${flyway:defaultSchema}_BizAppsCommon',
         1,
         0
         , 1
         , 0
         , 0
         , 0
         , 1
         , 1
         , 1
         , 1000
      )
   

/* SQL generated to add new entity Common: Contact Types to application ID: '691ED607-8DEF-4598-8121-D4D2B45BC110' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('691ED607-8DEF-4598-8121-D4D2B45BC110', 'd17353e5-1fb0-4940-8d91-3e4007549200', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = '691ED607-8DEF-4598-8121-D4D2B45BC110'))

/* SQL generated to add new permission for entity Common: Contact Types for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('d17353e5-1fb0-4940-8d91-3e4007549200', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity Common: Contact Types for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('d17353e5-1fb0-4940-8d91-3e4007549200', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity Common: Contact Types for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('d17353e5-1fb0-4940-8d91-3e4007549200', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL generated to create new entity Common: Relationship Types */

      INSERT INTO [${flyway:defaultSchema}].Entity (
         ID,
         Name,
         DisplayName,
         Description,
         NameSuffix,
         BaseTable,
         BaseView,
         SchemaName,
         IncludeInAPI,
         AllowUserSearchAPI
         , TrackRecordChanges
         , AuditRecordAccess
         , AuditViewRuns
         , AllowAllRowsAPI
         , AllowCreateAPI
         , AllowUpdateAPI
         , AllowDeleteAPI
         , UserViewMaxRows
      )
      VALUES (
         '7bfa6aaf-c89f-41d6-bad5-737644abedcb',
         'Common: Relationship Types',
         'Relationship Types',
         NULL,
         NULL,
         'RelationshipType',
         'vwRelationshipTypes',
         '${flyway:defaultSchema}_BizAppsCommon',
         1,
         0
         , 1
         , 0
         , 0
         , 0
         , 1
         , 1
         , 1
         , 1000
      )
   

/* SQL generated to add new entity Common: Relationship Types to application ID: '691ED607-8DEF-4598-8121-D4D2B45BC110' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('691ED607-8DEF-4598-8121-D4D2B45BC110', '7bfa6aaf-c89f-41d6-bad5-737644abedcb', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = '691ED607-8DEF-4598-8121-D4D2B45BC110'))

/* SQL generated to add new permission for entity Common: Relationship Types for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('7bfa6aaf-c89f-41d6-bad5-737644abedcb', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity Common: Relationship Types for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('7bfa6aaf-c89f-41d6-bad5-737644abedcb', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity Common: Relationship Types for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('7bfa6aaf-c89f-41d6-bad5-737644abedcb', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL generated to create new entity Common: People */

      INSERT INTO [${flyway:defaultSchema}].Entity (
         ID,
         Name,
         DisplayName,
         Description,
         NameSuffix,
         BaseTable,
         BaseView,
         SchemaName,
         IncludeInAPI,
         AllowUserSearchAPI
         , TrackRecordChanges
         , AuditRecordAccess
         , AuditViewRuns
         , AllowAllRowsAPI
         , AllowCreateAPI
         , AllowUpdateAPI
         , AllowDeleteAPI
         , UserViewMaxRows
      )
      VALUES (
         'a3cb56e8-38b9-4456-bd88-f5e69e219d65',
         'Common: People',
         'People',
         NULL,
         NULL,
         'Person',
         'vwPeople',
         '${flyway:defaultSchema}_BizAppsCommon',
         1,
         0
         , 1
         , 0
         , 0
         , 0
         , 1
         , 1
         , 1
         , 1000
      )
   

/* SQL generated to add new entity Common: People to application ID: '691ED607-8DEF-4598-8121-D4D2B45BC110' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('691ED607-8DEF-4598-8121-D4D2B45BC110', 'a3cb56e8-38b9-4456-bd88-f5e69e219d65', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = '691ED607-8DEF-4598-8121-D4D2B45BC110'))

/* SQL generated to add new permission for entity Common: People for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('a3cb56e8-38b9-4456-bd88-f5e69e219d65', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity Common: People for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('a3cb56e8-38b9-4456-bd88-f5e69e219d65', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity Common: People for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('a3cb56e8-38b9-4456-bd88-f5e69e219d65', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL generated to create new entity Common: Organizations */

      INSERT INTO [${flyway:defaultSchema}].Entity (
         ID,
         Name,
         DisplayName,
         Description,
         NameSuffix,
         BaseTable,
         BaseView,
         SchemaName,
         IncludeInAPI,
         AllowUserSearchAPI
         , TrackRecordChanges
         , AuditRecordAccess
         , AuditViewRuns
         , AllowAllRowsAPI
         , AllowCreateAPI
         , AllowUpdateAPI
         , AllowDeleteAPI
         , UserViewMaxRows
      )
      VALUES (
         '74defef0-a5f5-41d6-9b63-8a07f706abfd',
         'Common: Organizations',
         'Organizations',
         NULL,
         NULL,
         'Organization',
         'vwOrganizations',
         '${flyway:defaultSchema}_BizAppsCommon',
         1,
         0
         , 1
         , 0
         , 0
         , 0
         , 1
         , 1
         , 1
         , 1000
      )
   

/* SQL generated to add new entity Common: Organizations to application ID: '691ED607-8DEF-4598-8121-D4D2B45BC110' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('691ED607-8DEF-4598-8121-D4D2B45BC110', '74defef0-a5f5-41d6-9b63-8a07f706abfd', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = '691ED607-8DEF-4598-8121-D4D2B45BC110'))

/* SQL generated to add new permission for entity Common: Organizations for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('74defef0-a5f5-41d6-9b63-8a07f706abfd', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity Common: Organizations for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('74defef0-a5f5-41d6-9b63-8a07f706abfd', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity Common: Organizations for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('74defef0-a5f5-41d6-9b63-8a07f706abfd', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL generated to create new entity Common: Addresses */

      INSERT INTO [${flyway:defaultSchema}].Entity (
         ID,
         Name,
         DisplayName,
         Description,
         NameSuffix,
         BaseTable,
         BaseView,
         SchemaName,
         IncludeInAPI,
         AllowUserSearchAPI
         , TrackRecordChanges
         , AuditRecordAccess
         , AuditViewRuns
         , AllowAllRowsAPI
         , AllowCreateAPI
         , AllowUpdateAPI
         , AllowDeleteAPI
         , UserViewMaxRows
      )
      VALUES (
         'b59cca6f-e48c-4de5-a784-db0df9e2885c',
         'Common: Addresses',
         'Addresses',
         NULL,
         NULL,
         'Address',
         'vwAddresses',
         '${flyway:defaultSchema}_BizAppsCommon',
         1,
         0
         , 1
         , 0
         , 0
         , 0
         , 1
         , 1
         , 1
         , 1000
      )
   

/* SQL generated to add new entity Common: Addresses to application ID: '691ED607-8DEF-4598-8121-D4D2B45BC110' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('691ED607-8DEF-4598-8121-D4D2B45BC110', 'b59cca6f-e48c-4de5-a784-db0df9e2885c', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = '691ED607-8DEF-4598-8121-D4D2B45BC110'))

/* SQL generated to add new permission for entity Common: Addresses for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('b59cca6f-e48c-4de5-a784-db0df9e2885c', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity Common: Addresses for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('b59cca6f-e48c-4de5-a784-db0df9e2885c', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity Common: Addresses for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('b59cca6f-e48c-4de5-a784-db0df9e2885c', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL generated to create new entity Common: Address Links */

      INSERT INTO [${flyway:defaultSchema}].Entity (
         ID,
         Name,
         DisplayName,
         Description,
         NameSuffix,
         BaseTable,
         BaseView,
         SchemaName,
         IncludeInAPI,
         AllowUserSearchAPI
         , TrackRecordChanges
         , AuditRecordAccess
         , AuditViewRuns
         , AllowAllRowsAPI
         , AllowCreateAPI
         , AllowUpdateAPI
         , AllowDeleteAPI
         , UserViewMaxRows
      )
      VALUES (
         '8e6d93fa-4768-4672-8a5c-35dcad34c9bd',
         'Common: Address Links',
         'Address Links',
         NULL,
         NULL,
         'AddressLink',
         'vwAddressLinks',
         '${flyway:defaultSchema}_BizAppsCommon',
         1,
         0
         , 1
         , 0
         , 0
         , 0
         , 1
         , 1
         , 1
         , 1000
      )
   

/* SQL generated to add new entity Common: Address Links to application ID: '691ED607-8DEF-4598-8121-D4D2B45BC110' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('691ED607-8DEF-4598-8121-D4D2B45BC110', '8e6d93fa-4768-4672-8a5c-35dcad34c9bd', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = '691ED607-8DEF-4598-8121-D4D2B45BC110'))

/* SQL generated to add new permission for entity Common: Address Links for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('8e6d93fa-4768-4672-8a5c-35dcad34c9bd', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity Common: Address Links for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('8e6d93fa-4768-4672-8a5c-35dcad34c9bd', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity Common: Address Links for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('8e6d93fa-4768-4672-8a5c-35dcad34c9bd', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL generated to create new entity Common: Contact Methods */

      INSERT INTO [${flyway:defaultSchema}].Entity (
         ID,
         Name,
         DisplayName,
         Description,
         NameSuffix,
         BaseTable,
         BaseView,
         SchemaName,
         IncludeInAPI,
         AllowUserSearchAPI
         , TrackRecordChanges
         , AuditRecordAccess
         , AuditViewRuns
         , AllowAllRowsAPI
         , AllowCreateAPI
         , AllowUpdateAPI
         , AllowDeleteAPI
         , UserViewMaxRows
      )
      VALUES (
         'fa624cad-3867-49dd-b9f8-be3ef2c81fca',
         'Common: Contact Methods',
         'Contact Methods',
         NULL,
         NULL,
         'ContactMethod',
         'vwContactMethods',
         '${flyway:defaultSchema}_BizAppsCommon',
         1,
         0
         , 1
         , 0
         , 0
         , 0
         , 1
         , 1
         , 1
         , 1000
      )
   

/* SQL generated to add new entity Common: Contact Methods to application ID: '691ED607-8DEF-4598-8121-D4D2B45BC110' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('691ED607-8DEF-4598-8121-D4D2B45BC110', 'fa624cad-3867-49dd-b9f8-be3ef2c81fca', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = '691ED607-8DEF-4598-8121-D4D2B45BC110'))

/* SQL generated to add new permission for entity Common: Contact Methods for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('fa624cad-3867-49dd-b9f8-be3ef2c81fca', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity Common: Contact Methods for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('fa624cad-3867-49dd-b9f8-be3ef2c81fca', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity Common: Contact Methods for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('fa624cad-3867-49dd-b9f8-be3ef2c81fca', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL generated to create new entity Common: Relationships */

      INSERT INTO [${flyway:defaultSchema}].Entity (
         ID,
         Name,
         DisplayName,
         Description,
         NameSuffix,
         BaseTable,
         BaseView,
         SchemaName,
         IncludeInAPI,
         AllowUserSearchAPI
         , TrackRecordChanges
         , AuditRecordAccess
         , AuditViewRuns
         , AllowAllRowsAPI
         , AllowCreateAPI
         , AllowUpdateAPI
         , AllowDeleteAPI
         , UserViewMaxRows
      )
      VALUES (
         '2c2b874f-0880-4de7-a0bf-63b6c6afe9eb',
         'Common: Relationships',
         'Relationships',
         NULL,
         NULL,
         'Relationship',
         'vwRelationships',
         '${flyway:defaultSchema}_BizAppsCommon',
         1,
         0
         , 1
         , 0
         , 0
         , 0
         , 1
         , 1
         , 1
         , 1000
      )
   

/* SQL generated to add new entity Common: Relationships to application ID: '691ED607-8DEF-4598-8121-D4D2B45BC110' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('691ED607-8DEF-4598-8121-D4D2B45BC110', '2c2b874f-0880-4de7-a0bf-63b6c6afe9eb', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = '691ED607-8DEF-4598-8121-D4D2B45BC110'))

/* SQL generated to add new permission for entity Common: Relationships for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('2c2b874f-0880-4de7-a0bf-63b6c6afe9eb', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity Common: Relationships for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('2c2b874f-0880-4de7-a0bf-63b6c6afe9eb', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity Common: Relationships for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('2c2b874f-0880-4de7-a0bf-63b6c6afe9eb', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL generated to create new entity Common: Organization Types */

      INSERT INTO [${flyway:defaultSchema}].Entity (
         ID,
         Name,
         DisplayName,
         Description,
         NameSuffix,
         BaseTable,
         BaseView,
         SchemaName,
         IncludeInAPI,
         AllowUserSearchAPI
         , TrackRecordChanges
         , AuditRecordAccess
         , AuditViewRuns
         , AllowAllRowsAPI
         , AllowCreateAPI
         , AllowUpdateAPI
         , AllowDeleteAPI
         , UserViewMaxRows
      )
      VALUES (
         '0ab066c1-8fe5-4363-86e6-bef80975205c',
         'Common: Organization Types',
         'Organization Types',
         NULL,
         NULL,
         'OrganizationType',
         'vwOrganizationTypes',
         '${flyway:defaultSchema}_BizAppsCommon',
         1,
         0
         , 1
         , 0
         , 0
         , 0
         , 1
         , 1
         , 1
         , 1000
      )
   

/* SQL generated to add new entity Common: Organization Types to application ID: '691ED607-8DEF-4598-8121-D4D2B45BC110' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('691ED607-8DEF-4598-8121-D4D2B45BC110', '0ab066c1-8fe5-4363-86e6-bef80975205c', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = '691ED607-8DEF-4598-8121-D4D2B45BC110'))

/* SQL generated to add new permission for entity Common: Organization Types for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('0ab066c1-8fe5-4363-86e6-bef80975205c', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity Common: Organization Types for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('0ab066c1-8fe5-4363-86e6-bef80975205c', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity Common: Organization Types for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('0ab066c1-8fe5-4363-86e6-bef80975205c', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.AddressLink */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[AddressLink] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.AddressLink */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[AddressLink] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.ContactType */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[ContactType] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.ContactType */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[ContactType] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.AddressType */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[AddressType] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.AddressType */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[AddressType] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.Relationship */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[Relationship] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.Relationship */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[Relationship] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.RelationshipType */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[RelationshipType] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.RelationshipType */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[RelationshipType] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.Organization */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[Organization] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.Organization */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[Organization] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.ContactMethod */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.ContactMethod */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.OrganizationType */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[OrganizationType] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.OrganizationType */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[OrganizationType] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.Address */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[Address] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.Address */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[Address] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.Person */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[Person] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.Person */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[Person] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '68dab59e-ca4c-4c79-9ab8-32ed9ba29b3e'  OR 
               (EntityID = '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD' AND Name = 'ID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '68dab59e-ca4c-4c79-9ab8-32ed9ba29b3e',
            '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD', -- Entity: Common: Address Links
            100001,
            'ID',
            'ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            'newsequentialid()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            1,
            0,
            0,
            1,
            1,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'd78a7c9e-a347-451a-8535-00edb6ab4359'  OR 
               (EntityID = '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD' AND Name = 'AddressID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'd78a7c9e-a347-451a-8535-00edb6ab4359',
            '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD', -- Entity: Common: Address Links
            100002,
            'AddressID',
            'Address ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            'null',
            0,
            1,
            0,
            'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'cfcbe12e-5b60-44c1-bdf9-f672294778fb'  OR 
               (EntityID = '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD' AND Name = 'EntityID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'cfcbe12e-5b60-44c1-bdf9-f672294778fb',
            '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD', -- Entity: Common: Address Links
            100003,
            'EntityID',
            'Entity ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            'null',
            0,
            1,
            0,
            'E0238F34-2837-EF11-86D4-6045BDEE16E6',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '4fc0f14d-3d67-412d-b93d-2944b9dd06b1'  OR 
               (EntityID = '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD' AND Name = 'RecordID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '4fc0f14d-3d67-412d-b93d-2944b9dd06b1',
            '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD', -- Entity: Common: Address Links
            100004,
            'RecordID',
            'Record ID',
            'Primary key value(s) of the linked record. NVARCHAR(700) to support concatenated composite keys for entities without single-valued primary keys',
            'nvarchar',
            1400,
            0,
            0,
            0,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '71e1c019-742d-422f-b412-d85757922adb'  OR 
               (EntityID = '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD' AND Name = 'AddressTypeID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '71e1c019-742d-422f-b412-d85757922adb',
            '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD', -- Entity: Common: Address Links
            100005,
            'AddressTypeID',
            'Address Type ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            'null',
            0,
            1,
            0,
            '66FA272F-59BB-4105-A1F3-4E5D4D63F381',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'cdcbe6ce-9644-4387-83fd-dd5d9d653665'  OR 
               (EntityID = '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD' AND Name = 'IsPrimary')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'cdcbe6ce-9644-4387-83fd-dd5d9d653665',
            '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD', -- Entity: Common: Address Links
            100006,
            'IsPrimary',
            'Is Primary',
            'Whether this is the primary address for the linked record. Only one address per entity record should be marked primary',
            'bit',
            1,
            1,
            0,
            0,
            '(0)',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'a679cd5b-cce9-4b4f-ba52-e9189c78e43d'  OR 
               (EntityID = '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD' AND Name = 'Rank')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'a679cd5b-cce9-4b4f-ba52-e9189c78e43d',
            '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD', -- Entity: Common: Address Links
            100007,
            'Rank',
            'Rank',
            'Sort order override for this specific link. When NULL, falls back to AddressType.DefaultRank. Lower values appear first',
            'int',
            4,
            10,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '81398f0e-7aef-40a2-8dcd-3504d4d2779a'  OR 
               (EntityID = '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD' AND Name = '__mj_CreatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '81398f0e-7aef-40a2-8dcd-3504d4d2779a',
            '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD', -- Entity: Common: Address Links
            100008,
            '__mj_CreatedAt',
            'Created At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '4e1dc335-24a5-4940-b511-c5c1b8369dc2'  OR 
               (EntityID = '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD' AND Name = '__mj_UpdatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '4e1dc335-24a5-4940-b511-c5c1b8369dc2',
            '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD', -- Entity: Common: Address Links
            100009,
            '__mj_UpdatedAt',
            'Updated At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '8a5238ff-1427-4868-9e70-27223709aad4'  OR 
               (EntityID = 'D17353E5-1FB0-4940-8D91-3E4007549200' AND Name = 'ID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '8a5238ff-1427-4868-9e70-27223709aad4',
            'D17353E5-1FB0-4940-8D91-3E4007549200', -- Entity: Common: Contact Types
            100001,
            'ID',
            'ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            'newsequentialid()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            1,
            0,
            0,
            1,
            1,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'af7d302b-8340-4ea7-bbf3-22c04f63333c'  OR 
               (EntityID = 'D17353E5-1FB0-4940-8D91-3E4007549200' AND Name = 'Name')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'af7d302b-8340-4ea7-bbf3-22c04f63333c',
            'D17353E5-1FB0-4940-8D91-3E4007549200', -- Entity: Common: Contact Types
            100002,
            'Name',
            'Name',
            'Display name for the contact type',
            'nvarchar',
            200,
            0,
            0,
            0,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            1,
            1,
            0,
            1,
            0,
            1,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'd5cbc8c6-0351-4ad2-8db8-22efed381292'  OR 
               (EntityID = 'D17353E5-1FB0-4940-8D91-3E4007549200' AND Name = 'Description')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'd5cbc8c6-0351-4ad2-8db8-22efed381292',
            'D17353E5-1FB0-4940-8D91-3E4007549200', -- Entity: Common: Contact Types
            100003,
            'Description',
            'Description',
            'Detailed description of this contact type',
            'nvarchar',
            -1,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '40359756-9750-41ec-8558-b9a87850f884'  OR 
               (EntityID = 'D17353E5-1FB0-4940-8D91-3E4007549200' AND Name = 'IconClass')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '40359756-9750-41ec-8558-b9a87850f884',
            'D17353E5-1FB0-4940-8D91-3E4007549200', -- Entity: Common: Contact Types
            100004,
            'IconClass',
            'Icon Class',
            'Font Awesome icon class for UI display',
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '99dc79f5-9599-45d9-b867-1ab3d029f2a8'  OR 
               (EntityID = 'D17353E5-1FB0-4940-8D91-3E4007549200' AND Name = '__mj_CreatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '99dc79f5-9599-45d9-b867-1ab3d029f2a8',
            'D17353E5-1FB0-4940-8D91-3E4007549200', -- Entity: Common: Contact Types
            100005,
            '__mj_CreatedAt',
            'Created At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'fd6a186c-1a0b-46b5-9020-dd50e850c41f'  OR 
               (EntityID = 'D17353E5-1FB0-4940-8D91-3E4007549200' AND Name = '__mj_UpdatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'fd6a186c-1a0b-46b5-9020-dd50e850c41f',
            'D17353E5-1FB0-4940-8D91-3E4007549200', -- Entity: Common: Contact Types
            100006,
            '__mj_UpdatedAt',
            'Updated At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '621fc111-0d6c-483d-b53c-1a5ad69865b2'  OR 
               (EntityID = '66FA272F-59BB-4105-A1F3-4E5D4D63F381' AND Name = 'ID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '621fc111-0d6c-483d-b53c-1a5ad69865b2',
            '66FA272F-59BB-4105-A1F3-4E5D4D63F381', -- Entity: Common: Address Types
            100001,
            'ID',
            'ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            'newsequentialid()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            1,
            0,
            0,
            1,
            1,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'ee25af1d-0b36-426f-9006-76007868a0a4'  OR 
               (EntityID = '66FA272F-59BB-4105-A1F3-4E5D4D63F381' AND Name = 'Name')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'ee25af1d-0b36-426f-9006-76007868a0a4',
            '66FA272F-59BB-4105-A1F3-4E5D4D63F381', -- Entity: Common: Address Types
            100002,
            'Name',
            'Name',
            'Display name for the address type',
            'nvarchar',
            200,
            0,
            0,
            0,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            1,
            1,
            0,
            1,
            0,
            1,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '075337aa-e0af-45a5-8de2-70764cd154d6'  OR 
               (EntityID = '66FA272F-59BB-4105-A1F3-4E5D4D63F381' AND Name = 'Description')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '075337aa-e0af-45a5-8de2-70764cd154d6',
            '66FA272F-59BB-4105-A1F3-4E5D4D63F381', -- Entity: Common: Address Types
            100003,
            'Description',
            'Description',
            'Detailed description of this address type',
            'nvarchar',
            -1,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '96f82cb6-0432-45c4-8449-af29288a372b'  OR 
               (EntityID = '66FA272F-59BB-4105-A1F3-4E5D4D63F381' AND Name = 'DefaultRank')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '96f82cb6-0432-45c4-8449-af29288a372b',
            '66FA272F-59BB-4105-A1F3-4E5D4D63F381', -- Entity: Common: Address Types
            100004,
            'DefaultRank',
            'Default Rank',
            'Default sort order for this address type in dropdown lists. Lower values appear first. Can be overridden per-record via AddressLink.Rank',
            'int',
            4,
            10,
            0,
            0,
            '(100)',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '40dae327-885c-47b6-892d-6a1a160e32b2'  OR 
               (EntityID = '66FA272F-59BB-4105-A1F3-4E5D4D63F381' AND Name = '__mj_CreatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '40dae327-885c-47b6-892d-6a1a160e32b2',
            '66FA272F-59BB-4105-A1F3-4E5D4D63F381', -- Entity: Common: Address Types
            100005,
            '__mj_CreatedAt',
            'Created At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '2e8428ca-21d5-4caa-ae2a-ae3783d8cb39'  OR 
               (EntityID = '66FA272F-59BB-4105-A1F3-4E5D4D63F381' AND Name = '__mj_UpdatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '2e8428ca-21d5-4caa-ae2a-ae3783d8cb39',
            '66FA272F-59BB-4105-A1F3-4E5D4D63F381', -- Entity: Common: Address Types
            100006,
            '__mj_UpdatedAt',
            'Updated At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'e1bf9e93-1f96-486f-b4e0-49d038159b5c'  OR 
               (EntityID = '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB' AND Name = 'ID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'e1bf9e93-1f96-486f-b4e0-49d038159b5c',
            '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', -- Entity: Common: Relationships
            100001,
            'ID',
            'ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            'newsequentialid()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            1,
            0,
            0,
            1,
            1,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'eaac9a59-ce53-43e4-b663-0cefaf8300d0'  OR 
               (EntityID = '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB' AND Name = 'RelationshipTypeID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'eaac9a59-ce53-43e4-b663-0cefaf8300d0',
            '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', -- Entity: Common: Relationships
            100002,
            'RelationshipTypeID',
            'Relationship Type ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            'null',
            0,
            1,
            0,
            '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '874ba7fa-14c5-4277-9c83-ff2187d6f0e1'  OR 
               (EntityID = '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB' AND Name = 'FromPersonID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '874ba7fa-14c5-4277-9c83-ff2187d6f0e1',
            '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', -- Entity: Common: Relationships
            100003,
            'FromPersonID',
            'From Person ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '12fbd8af-5847-453d-b40e-3d740c04769d'  OR 
               (EntityID = '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB' AND Name = 'FromOrganizationID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '12fbd8af-5847-453d-b40e-3d740c04769d',
            '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', -- Entity: Common: Relationships
            100004,
            'FromOrganizationID',
            'From Organization ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'eb71a369-66c0-4c86-9b77-63a11ba01874'  OR 
               (EntityID = '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB' AND Name = 'ToPersonID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'eb71a369-66c0-4c86-9b77-63a11ba01874',
            '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', -- Entity: Common: Relationships
            100005,
            'ToPersonID',
            'To Person ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'cffb2d6a-96bd-4548-82b2-a344d0f4df89'  OR 
               (EntityID = '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB' AND Name = 'ToOrganizationID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'cffb2d6a-96bd-4548-82b2-a344d0f4df89',
            '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', -- Entity: Common: Relationships
            100006,
            'ToOrganizationID',
            'To Organization ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '41798d66-072d-4f85-9d13-51c754f165c5'  OR 
               (EntityID = '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB' AND Name = 'Title')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '41798d66-072d-4f85-9d13-51c754f165c5',
            '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', -- Entity: Common: Relationships
            100007,
            'Title',
            'Title',
            'Contextual title for this specific relationship, e.g. CEO, Primary Contact, Founding Member',
            'nvarchar',
            510,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '854946a7-ef5b-4818-8afb-cd99b5e313e8'  OR 
               (EntityID = '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB' AND Name = 'StartDate')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '854946a7-ef5b-4818-8afb-cd99b5e313e8',
            '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', -- Entity: Common: Relationships
            100008,
            'StartDate',
            'Start Date',
            'Date the relationship began',
            'date',
            3,
            10,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '7d0ae077-e5ab-4b21-93aa-3cb682bb906a'  OR 
               (EntityID = '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB' AND Name = 'EndDate')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '7d0ae077-e5ab-4b21-93aa-3cb682bb906a',
            '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', -- Entity: Common: Relationships
            100009,
            'EndDate',
            'End Date',
            'Date the relationship ended, if applicable',
            'date',
            3,
            10,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '228f924e-db74-41e4-8d20-942d899c03d6'  OR 
               (EntityID = '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB' AND Name = 'Status')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '228f924e-db74-41e4-8d20-942d899c03d6',
            '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', -- Entity: Common: Relationships
            100010,
            'Status',
            'Status',
            'Current status: Active, Inactive, or Ended',
            'nvarchar',
            100,
            0,
            0,
            0,
            'Active',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '9929cc69-0349-4dca-9f74-4b11cf31ad1a'  OR 
               (EntityID = '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB' AND Name = 'Notes')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '9929cc69-0349-4dca-9f74-4b11cf31ad1a',
            '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', -- Entity: Common: Relationships
            100011,
            'Notes',
            'Notes',
            'Additional notes about this relationship',
            'nvarchar',
            -1,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'c4f00f0e-461c-4eac-b70c-b7508f850000'  OR 
               (EntityID = '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB' AND Name = '__mj_CreatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'c4f00f0e-461c-4eac-b70c-b7508f850000',
            '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', -- Entity: Common: Relationships
            100012,
            '__mj_CreatedAt',
            'Created At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '531daa90-2cbc-4af9-91b3-a77205d4d4a1'  OR 
               (EntityID = '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB' AND Name = '__mj_UpdatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '531daa90-2cbc-4af9-91b3-a77205d4d4a1',
            '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', -- Entity: Common: Relationships
            100013,
            '__mj_UpdatedAt',
            'Updated At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'b6a2c73f-6d40-45f9-af82-52dd3d29c6fb'  OR 
               (EntityID = '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB' AND Name = 'ID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'b6a2c73f-6d40-45f9-af82-52dd3d29c6fb',
            '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB', -- Entity: Common: Relationship Types
            100001,
            'ID',
            'ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            'newsequentialid()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            1,
            0,
            0,
            1,
            1,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'fda58326-2507-4f14-9143-d17758d1b999'  OR 
               (EntityID = '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB' AND Name = 'Name')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'fda58326-2507-4f14-9143-d17758d1b999',
            '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB', -- Entity: Common: Relationship Types
            100002,
            'Name',
            'Name',
            'Display name for the relationship type, e.g. Employee, Spouse, Partner',
            'nvarchar',
            200,
            0,
            0,
            0,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            1,
            1,
            0,
            1,
            0,
            1,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'e351f0d1-98d9-449e-9c0a-6d43d5b4d390'  OR 
               (EntityID = '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB' AND Name = 'Description')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'e351f0d1-98d9-449e-9c0a-6d43d5b4d390',
            '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB', -- Entity: Common: Relationship Types
            100003,
            'Description',
            'Description',
            'Detailed description of this relationship type',
            'nvarchar',
            -1,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '722c3e0d-ab64-4276-b53d-ca77c54143cf'  OR 
               (EntityID = '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB' AND Name = 'Category')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '722c3e0d-ab64-4276-b53d-ca77c54143cf',
            '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB', -- Entity: Common: Relationship Types
            100004,
            'Category',
            'Category',
            'Which entity types this relationship connects: PersonToPerson, PersonToOrganization, or OrganizationToOrganization',
            'nvarchar',
            100,
            0,
            0,
            0,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'd4ea503e-413f-4809-9969-a69e1df8261b'  OR 
               (EntityID = '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB' AND Name = 'IsDirectional')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'd4ea503e-413f-4809-9969-a69e1df8261b',
            '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB', -- Entity: Common: Relationship Types
            100005,
            'IsDirectional',
            'Is Directional',
            'Whether the relationship has a direction. False for symmetric relationships like Spouse or Partner',
            'bit',
            1,
            1,
            0,
            0,
            '(1)',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'c97e3d06-0d30-44f3-b692-45a4125bc66e'  OR 
               (EntityID = '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB' AND Name = 'ForwardLabel')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'c97e3d06-0d30-44f3-b692-45a4125bc66e',
            '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB', -- Entity: Common: Relationship Types
            100006,
            'ForwardLabel',
            'Forward Label',
            'Label describing the From-to-To direction, e.g. is employee of, is parent of',
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '80f81755-7e41-44c8-a429-ac94e5ce7689'  OR 
               (EntityID = '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB' AND Name = 'ReverseLabel')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '80f81755-7e41-44c8-a429-ac94e5ce7689',
            '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB', -- Entity: Common: Relationship Types
            100007,
            'ReverseLabel',
            'Reverse Label',
            'Label describing the To-to-From direction, e.g. employs, is child of',
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '8aeb1280-b915-4e5e-a5ee-f641d20378a4'  OR 
               (EntityID = '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB' AND Name = '__mj_CreatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '8aeb1280-b915-4e5e-a5ee-f641d20378a4',
            '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB', -- Entity: Common: Relationship Types
            100008,
            '__mj_CreatedAt',
            'Created At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'a40dafe1-4aa7-40e5-a0be-8a32b5ee8012'  OR 
               (EntityID = '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB' AND Name = '__mj_UpdatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'a40dafe1-4aa7-40e5-a0be-8a32b5ee8012',
            '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB', -- Entity: Common: Relationship Types
            100009,
            '__mj_UpdatedAt',
            'Updated At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '7c6e93c3-e124-46bb-a0f5-1da136396afd'  OR 
               (EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD' AND Name = 'ID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '7c6e93c3-e124-46bb-a0f5-1da136396afd',
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', -- Entity: Common: Organizations
            100001,
            'ID',
            'ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            'newsequentialid()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            1,
            0,
            0,
            1,
            1,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '3bb45a32-8836-4868-9408-44101f79da8d'  OR 
               (EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD' AND Name = 'Name')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '3bb45a32-8836-4868-9408-44101f79da8d',
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', -- Entity: Common: Organizations
            100002,
            'Name',
            'Name',
            'Common or display name of the organization',
            'nvarchar',
            510,
            0,
            0,
            0,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            1,
            1,
            0,
            1,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '4a6c3b90-a1dc-48b6-8268-7170539663a9'  OR 
               (EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD' AND Name = 'LegalName')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '4a6c3b90-a1dc-48b6-8268-7170539663a9',
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', -- Entity: Common: Organizations
            100003,
            'LegalName',
            'Legal Name',
            'Full legal name if different from display name',
            'nvarchar',
            510,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '0902c7f8-4d7f-40ea-baa6-a6c36b22fea5'  OR 
               (EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD' AND Name = 'OrganizationTypeID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '0902c7f8-4d7f-40ea-baa6-a6c36b22fea5',
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', -- Entity: Common: Organizations
            100004,
            'OrganizationTypeID',
            'Organization Type ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            '0AB066C1-8FE5-4363-86E6-BEF80975205C',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '7a4a63e0-651d-4127-932a-c3d2ec1f24c6'  OR 
               (EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD' AND Name = 'ParentID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '7a4a63e0-651d-4127-932a-c3d2ec1f24c6',
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', -- Entity: Common: Organizations
            100005,
            'ParentID',
            'Parent ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '0b217d86-fa43-4c64-bce7-ff4fabddaa6d'  OR 
               (EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD' AND Name = 'Website')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '0b217d86-fa43-4c64-bce7-ff4fabddaa6d',
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', -- Entity: Common: Organizations
            100006,
            'Website',
            'Website',
            'Primary website URL',
            'nvarchar',
            2000,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '31300b38-c784-4e2a-a7cf-1f18ced9c458'  OR 
               (EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD' AND Name = 'LogoURL')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '31300b38-c784-4e2a-a7cf-1f18ced9c458',
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', -- Entity: Common: Organizations
            100007,
            'LogoURL',
            'Logo URL',
            'URL to organization logo image',
            'nvarchar',
            2000,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '83410a49-636c-4540-88f5-7ac573e0fc39'  OR 
               (EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD' AND Name = 'Description')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '83410a49-636c-4540-88f5-7ac573e0fc39',
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', -- Entity: Common: Organizations
            100008,
            'Description',
            'Description',
            'Description of the organization purpose and scope',
            'nvarchar',
            -1,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'daa78da8-7a01-4ada-b992-c9518d4abc7a'  OR 
               (EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD' AND Name = 'Email')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'daa78da8-7a01-4ada-b992-c9518d4abc7a',
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', -- Entity: Common: Organizations
            100009,
            'Email',
            'Email',
            'Primary contact email address',
            'nvarchar',
            510,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '598bf53a-74ab-4d88-9087-fefe711a0784'  OR 
               (EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD' AND Name = 'Phone')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '598bf53a-74ab-4d88-9087-fefe711a0784',
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', -- Entity: Common: Organizations
            100010,
            'Phone',
            'Phone',
            'Primary phone number',
            'nvarchar',
            100,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '24f6c30c-ae49-4f55-bbb1-e9abf12af0db'  OR 
               (EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD' AND Name = 'FoundedDate')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '24f6c30c-ae49-4f55-bbb1-e9abf12af0db',
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', -- Entity: Common: Organizations
            100011,
            'FoundedDate',
            'Founded Date',
            'Date the organization was founded or incorporated',
            'date',
            3,
            10,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'c9defea8-649d-46ef-8ad5-67ce6f8365ce'  OR 
               (EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD' AND Name = 'TaxID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'c9defea8-649d-46ef-8ad5-67ce6f8365ce',
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', -- Entity: Common: Organizations
            100012,
            'TaxID',
            'Tax ID',
            'Tax identification number such as EIN',
            'nvarchar',
            100,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '5ed84866-8b7b-42c5-912e-80fdac5b4d1f'  OR 
               (EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD' AND Name = 'Status')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '5ed84866-8b7b-42c5-912e-80fdac5b4d1f',
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', -- Entity: Common: Organizations
            100013,
            'Status',
            'Status',
            'Current status: Active, Inactive, or Dissolved',
            'nvarchar',
            100,
            0,
            0,
            0,
            'Active',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '3f12cf81-8bf2-4f9f-8e77-de9819dcb251'  OR 
               (EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD' AND Name = '__mj_CreatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '3f12cf81-8bf2-4f9f-8e77-de9819dcb251',
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', -- Entity: Common: Organizations
            100014,
            '__mj_CreatedAt',
            'Created At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'ac571288-2d4b-431d-97ca-7328bf50404f'  OR 
               (EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD' AND Name = '__mj_UpdatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'ac571288-2d4b-431d-97ca-7328bf50404f',
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', -- Entity: Common: Organizations
            100015,
            '__mj_UpdatedAt',
            'Updated At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'b2e878a1-c0e8-450d-8525-732ca54589a3'  OR 
               (EntityID = 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA' AND Name = 'ID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'b2e878a1-c0e8-450d-8525-732ca54589a3',
            'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA', -- Entity: Common: Contact Methods
            100001,
            'ID',
            'ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            'newsequentialid()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            1,
            0,
            0,
            1,
            1,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '4781a91c-0f0b-40bf-b4dd-c95611b821f1'  OR 
               (EntityID = 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA' AND Name = 'PersonID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '4781a91c-0f0b-40bf-b4dd-c95611b821f1',
            'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA', -- Entity: Common: Contact Methods
            100002,
            'PersonID',
            'Person ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '203c3260-2df9-4478-b639-d0401ac0ac28'  OR 
               (EntityID = 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA' AND Name = 'OrganizationID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '203c3260-2df9-4478-b639-d0401ac0ac28',
            'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA', -- Entity: Common: Contact Methods
            100003,
            'OrganizationID',
            'Organization ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '0b306e5d-0024-471a-9e43-5293c57d4759'  OR 
               (EntityID = 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA' AND Name = 'ContactTypeID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '0b306e5d-0024-471a-9e43-5293c57d4759',
            'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA', -- Entity: Common: Contact Methods
            100004,
            'ContactTypeID',
            'Contact Type ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            'null',
            0,
            1,
            0,
            'D17353E5-1FB0-4940-8D91-3E4007549200',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'eeded48b-3219-4f5c-86b8-7fd7865041b5'  OR 
               (EntityID = 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA' AND Name = 'Value')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'eeded48b-3219-4f5c-86b8-7fd7865041b5',
            'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA', -- Entity: Common: Contact Methods
            100005,
            'Value',
            'Value',
            'The contact value: phone number, email address, URL, social media handle, etc.',
            'nvarchar',
            1000,
            0,
            0,
            0,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'bbf473e7-86cc-407d-844d-ffd044b468d6'  OR 
               (EntityID = 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA' AND Name = 'Label')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'bbf473e7-86cc-407d-844d-ffd044b468d6',
            'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA', -- Entity: Common: Contact Methods
            100006,
            'Label',
            'Label',
            'Descriptive label such as Work cell, Personal Gmail, Corporate LinkedIn',
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '3e918e15-cf7f-4141-bd82-87341be4206c'  OR 
               (EntityID = 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA' AND Name = 'IsPrimary')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '3e918e15-cf7f-4141-bd82-87341be4206c',
            'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA', -- Entity: Common: Contact Methods
            100007,
            'IsPrimary',
            'Is Primary',
            'Whether this is the primary contact method of its type for the linked person or organization',
            'bit',
            1,
            1,
            0,
            0,
            '(0)',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '89aa9c83-7ef0-42e8-a019-0791fc956ebc'  OR 
               (EntityID = 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA' AND Name = '__mj_CreatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '89aa9c83-7ef0-42e8-a019-0791fc956ebc',
            'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA', -- Entity: Common: Contact Methods
            100008,
            '__mj_CreatedAt',
            'Created At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '3553478f-f6ba-4c1e-a5db-91a7f3a3e11e'  OR 
               (EntityID = 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA' AND Name = '__mj_UpdatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '3553478f-f6ba-4c1e-a5db-91a7f3a3e11e',
            'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA', -- Entity: Common: Contact Methods
            100009,
            '__mj_UpdatedAt',
            'Updated At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '53e42417-862d-4a5f-aad2-32b83853313b'  OR 
               (EntityID = '0AB066C1-8FE5-4363-86E6-BEF80975205C' AND Name = 'ID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '53e42417-862d-4a5f-aad2-32b83853313b',
            '0AB066C1-8FE5-4363-86E6-BEF80975205C', -- Entity: Common: Organization Types
            100001,
            'ID',
            'ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            'newsequentialid()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            1,
            0,
            0,
            1,
            1,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'bb0e133c-34de-442e-a6be-26006cce426a'  OR 
               (EntityID = '0AB066C1-8FE5-4363-86E6-BEF80975205C' AND Name = 'Name')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'bb0e133c-34de-442e-a6be-26006cce426a',
            '0AB066C1-8FE5-4363-86E6-BEF80975205C', -- Entity: Common: Organization Types
            100002,
            'Name',
            'Name',
            'Display name for the organization type',
            'nvarchar',
            200,
            0,
            0,
            0,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            1,
            1,
            0,
            1,
            0,
            1,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'dc1550d3-7488-4cce-a291-8623ece507f1'  OR 
               (EntityID = '0AB066C1-8FE5-4363-86E6-BEF80975205C' AND Name = 'Description')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'dc1550d3-7488-4cce-a291-8623ece507f1',
            '0AB066C1-8FE5-4363-86E6-BEF80975205C', -- Entity: Common: Organization Types
            100003,
            'Description',
            'Description',
            'Detailed description of this organization type',
            'nvarchar',
            -1,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '48e12bde-31f1-4aa8-822e-ef3520612691'  OR 
               (EntityID = '0AB066C1-8FE5-4363-86E6-BEF80975205C' AND Name = 'IconClass')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '48e12bde-31f1-4aa8-822e-ef3520612691',
            '0AB066C1-8FE5-4363-86E6-BEF80975205C', -- Entity: Common: Organization Types
            100004,
            'IconClass',
            'Icon Class',
            'Font Awesome icon class for UI display',
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '8ad9e989-c6b1-4ca3-85e5-3d625b7c8812'  OR 
               (EntityID = '0AB066C1-8FE5-4363-86E6-BEF80975205C' AND Name = '__mj_CreatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '8ad9e989-c6b1-4ca3-85e5-3d625b7c8812',
            '0AB066C1-8FE5-4363-86E6-BEF80975205C', -- Entity: Common: Organization Types
            100005,
            '__mj_CreatedAt',
            'Created At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'f8a490db-1a16-401d-a33a-a3213d95ee3d'  OR 
               (EntityID = '0AB066C1-8FE5-4363-86E6-BEF80975205C' AND Name = '__mj_UpdatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'f8a490db-1a16-401d-a33a-a3213d95ee3d',
            '0AB066C1-8FE5-4363-86E6-BEF80975205C', -- Entity: Common: Organization Types
            100006,
            '__mj_UpdatedAt',
            'Updated At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'ae4f724d-aece-4d56-945e-d5b5170f9222'  OR 
               (EntityID = 'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C' AND Name = 'ID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'ae4f724d-aece-4d56-945e-d5b5170f9222',
            'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C', -- Entity: Common: Addresses
            100001,
            'ID',
            'ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            'newsequentialid()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            1,
            0,
            0,
            1,
            1,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '67bdb609-9120-4e5d-826d-d2536d3ce054'  OR 
               (EntityID = 'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C' AND Name = 'Line1')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '67bdb609-9120-4e5d-826d-d2536d3ce054',
            'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C', -- Entity: Common: Addresses
            100002,
            'Line1',
            'Line 1',
            'Street address line 1',
            'nvarchar',
            510,
            0,
            0,
            0,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'a6b583ac-755f-4489-a79f-3e1a200baffc'  OR 
               (EntityID = 'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C' AND Name = 'Line2')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'a6b583ac-755f-4489-a79f-3e1a200baffc',
            'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C', -- Entity: Common: Addresses
            100003,
            'Line2',
            'Line 2',
            'Street address line 2 (suite, apt, etc.)',
            'nvarchar',
            510,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'c3bf655f-a151-4297-bdb7-96cf0f22308a'  OR 
               (EntityID = 'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C' AND Name = 'Line3')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'c3bf655f-a151-4297-bdb7-96cf0f22308a',
            'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C', -- Entity: Common: Addresses
            100004,
            'Line3',
            'Line 3',
            'Street address line 3 (additional detail)',
            'nvarchar',
            510,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '1ec1dc9d-2630-4ae3-92de-49b4f15f28bc'  OR 
               (EntityID = 'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C' AND Name = 'City')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '1ec1dc9d-2630-4ae3-92de-49b4f15f28bc',
            'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C', -- Entity: Common: Addresses
            100005,
            'City',
            'City',
            'City or locality name',
            'nvarchar',
            200,
            0,
            0,
            0,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '150d68ad-0e84-42eb-8b49-f977df4a92ab'  OR 
               (EntityID = 'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C' AND Name = 'StateProvince')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '150d68ad-0e84-42eb-8b49-f977df4a92ab',
            'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C', -- Entity: Common: Addresses
            100006,
            'StateProvince',
            'State Province',
            'State, province, or region',
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '64328a12-e707-45fc-aed0-0149f0a584b9'  OR 
               (EntityID = 'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C' AND Name = 'PostalCode')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '64328a12-e707-45fc-aed0-0149f0a584b9',
            'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C', -- Entity: Common: Addresses
            100007,
            'PostalCode',
            'Postal Code',
            'Postal or ZIP code',
            'nvarchar',
            40,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '174fd558-ffb0-4499-8586-ada3511a4e39'  OR 
               (EntityID = 'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C' AND Name = 'Country')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '174fd558-ffb0-4499-8586-ada3511a4e39',
            'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C', -- Entity: Common: Addresses
            100008,
            'Country',
            'Country',
            'Country code or name, defaults to US',
            'nvarchar',
            200,
            0,
            0,
            0,
            'US',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '78e3ec5b-4f15-45cf-9d80-e1a0e0405a42'  OR 
               (EntityID = 'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C' AND Name = 'Latitude')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '78e3ec5b-4f15-45cf-9d80-e1a0e0405a42',
            'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C', -- Entity: Common: Addresses
            100009,
            'Latitude',
            'Latitude',
            'Geographic latitude for mapping',
            'decimal',
            5,
            9,
            6,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '4200842e-a5d3-4c2c-85bb-e0c9699bb419'  OR 
               (EntityID = 'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C' AND Name = 'Longitude')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '4200842e-a5d3-4c2c-85bb-e0c9699bb419',
            'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C', -- Entity: Common: Addresses
            100010,
            'Longitude',
            'Longitude',
            'Geographic longitude for mapping',
            'decimal',
            5,
            9,
            6,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '7e8f1d7a-a42d-4944-9739-44adb7e902d7'  OR 
               (EntityID = 'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C' AND Name = '__mj_CreatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '7e8f1d7a-a42d-4944-9739-44adb7e902d7',
            'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C', -- Entity: Common: Addresses
            100011,
            '__mj_CreatedAt',
            'Created At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '0cb3ad60-386a-4a43-8ace-d692cdb39f1c'  OR 
               (EntityID = 'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C' AND Name = '__mj_UpdatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '0cb3ad60-386a-4a43-8ace-d692cdb39f1c',
            'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C', -- Entity: Common: Addresses
            100012,
            '__mj_UpdatedAt',
            'Updated At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'd0b95ea1-8f6a-42f7-8a57-0509760535c4'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = 'ID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'd0b95ea1-8f6a-42f7-8a57-0509760535c4',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100001,
            'ID',
            'ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            'newsequentialid()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            1,
            0,
            0,
            1,
            1,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'c36f71ab-a12a-466b-91ce-d3b3c466f277'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = 'FirstName')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'c36f71ab-a12a-466b-91ce-d3b3c466f277',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100002,
            'FirstName',
            'First Name',
            'First (given) name',
            'nvarchar',
            200,
            0,
            0,
            0,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'fcdcecc5-509b-4a56-a7e6-7a9bbebbebec'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = 'LastName')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'fcdcecc5-509b-4a56-a7e6-7a9bbebbebec',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100003,
            'LastName',
            'Last Name',
            'Last (family) name',
            'nvarchar',
            200,
            0,
            0,
            0,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '1d5f5717-709d-4934-a749-11fe56a2bbbb'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = 'MiddleName')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '1d5f5717-709d-4934-a749-11fe56a2bbbb',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100004,
            'MiddleName',
            'Middle Name',
            'Middle name or initial',
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'cf1e51af-191b-47e7-bc44-3a6c705ac739'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = 'Prefix')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'cf1e51af-191b-47e7-bc44-3a6c705ac739',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100005,
            'Prefix',
            'Prefix',
            'Name prefix such as Dr., Mr., Ms., Rev.',
            'nvarchar',
            40,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'e6687162-799a-4bb3-a5be-54eb87e22e83'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = 'Suffix')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'e6687162-799a-4bb3-a5be-54eb87e22e83',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100006,
            'Suffix',
            'Suffix',
            'Name suffix such as Jr., III, PhD, Esq.',
            'nvarchar',
            40,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '61021226-3fcc-468d-828a-d4c6b01d6200'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = 'PreferredName')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '61021226-3fcc-468d-828a-d4c6b01d6200',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100007,
            'PreferredName',
            'Preferred Name',
            'Nickname or preferred name the person goes by',
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '39c0d8a8-099b-4427-8921-8bb4e766ea47'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = 'Title')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '39c0d8a8-099b-4427-8921-8bb4e766ea47',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100008,
            'Title',
            'Title',
            'Professional or job title, e.g. VP of Engineering, Board Director',
            'nvarchar',
            400,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '8f92f420-e2b8-4ea9-8aef-efd6d5b41607'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = 'Email')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '8f92f420-e2b8-4ea9-8aef-efd6d5b41607',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100009,
            'Email',
            'Email',
            'Primary email address for this person',
            'nvarchar',
            510,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '886ccd64-5654-4095-9e8e-345951b0db65'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = 'Phone')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '886ccd64-5654-4095-9e8e-345951b0db65',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100010,
            'Phone',
            'Phone',
            'Primary phone number for this person',
            'nvarchar',
            100,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '05d10617-2fa9-40ff-b9e4-59b6aac4acbe'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = 'DateOfBirth')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '05d10617-2fa9-40ff-b9e4-59b6aac4acbe',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100011,
            'DateOfBirth',
            'Date Of Birth',
            'Date of birth',
            'date',
            3,
            10,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '6354a8e3-2ad5-4fbf-bc44-321aee5c669f'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = 'Gender')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '6354a8e3-2ad5-4fbf-bc44-321aee5c669f',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100012,
            'Gender',
            'Gender',
            'Gender identity',
            'nvarchar',
            100,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'a494bb71-2768-4024-b778-509aa1e8cb55'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = 'PhotoURL')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'a494bb71-2768-4024-b778-509aa1e8cb55',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100013,
            'PhotoURL',
            'Photo URL',
            'URL to profile photo or avatar image',
            'nvarchar',
            2000,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'f32f4925-bdd8-4f42-b2a8-8dafec07de2f'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = 'Bio')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'f32f4925-bdd8-4f42-b2a8-8dafec07de2f',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100014,
            'Bio',
            'Bio',
            'Biographical text or notes about this person',
            'nvarchar',
            -1,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '7dfc3bf1-a07f-463e-845a-c934275bbfcf'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = 'LinkedUserID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '7dfc3bf1-a07f-463e-845a-c934275bbfcf',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100015,
            'LinkedUserID',
            'Linked User ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            1,
            'null',
            0,
            1,
            0,
            'E1238F34-2837-EF11-86D4-6045BDEE16E6',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'c64968cb-cc40-403a-a02b-e245fe564172'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = 'Status')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'c64968cb-cc40-403a-a02b-e245fe564172',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100016,
            'Status',
            'Status',
            'Current status: Active, Inactive, or Deceased',
            'nvarchar',
            100,
            0,
            0,
            0,
            'Active',
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'e4076d06-6941-4562-95de-ec544aa22861'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = '__mj_CreatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'e4076d06-6941-4562-95de-ec544aa22861',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100017,
            '__mj_CreatedAt',
            'Created At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '8a17598a-ffa8-4a10-8d14-0454d494457e'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = '__mj_UpdatedAt')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '8a17598a-ffa8-4a10-8d14-0454d494457e',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100018,
            '__mj_UpdatedAt',
            'Updated At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert entity field value with ID 6eb44eb5-68a0-4680-a4bd-1360fce6b095 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('6eb44eb5-68a0-4680-a4bd-1360fce6b095', '722C3E0D-AB64-4276-B53D-CA77C54143CF', 1, 'OrganizationToOrganization', 'OrganizationToOrganization')

/* SQL text to insert entity field value with ID 9931055f-87bf-46d7-afac-dbe3dff6e4b4 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('9931055f-87bf-46d7-afac-dbe3dff6e4b4', '722C3E0D-AB64-4276-B53D-CA77C54143CF', 2, 'PersonToOrganization', 'PersonToOrganization')

/* SQL text to insert entity field value with ID 882fa96c-0de3-4af5-957d-89f408256d61 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('882fa96c-0de3-4af5-957d-89f408256d61', '722C3E0D-AB64-4276-B53D-CA77C54143CF', 3, 'PersonToPerson', 'PersonToPerson')

/* SQL text to update ValueListType for entity field ID 722C3E0D-AB64-4276-B53D-CA77C54143CF */
UPDATE [${flyway:defaultSchema}].EntityField SET ValueListType='List' WHERE ID='722C3E0D-AB64-4276-B53D-CA77C54143CF'

/* SQL text to insert entity field value with ID 322f3b64-1d55-4058-9347-0b022b5b596a */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('322f3b64-1d55-4058-9347-0b022b5b596a', 'C64968CB-CC40-403A-A02B-E245FE564172', 1, 'Active', 'Active')

/* SQL text to insert entity field value with ID a2e1739f-11fa-4ab9-9538-9914adbdaa4a */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('a2e1739f-11fa-4ab9-9538-9914adbdaa4a', 'C64968CB-CC40-403A-A02B-E245FE564172', 2, 'Deceased', 'Deceased')

/* SQL text to insert entity field value with ID ec370387-816c-4b2e-9c05-bae2cff8af97 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('ec370387-816c-4b2e-9c05-bae2cff8af97', 'C64968CB-CC40-403A-A02B-E245FE564172', 3, 'Inactive', 'Inactive')

/* SQL text to update ValueListType for entity field ID C64968CB-CC40-403A-A02B-E245FE564172 */
UPDATE [${flyway:defaultSchema}].EntityField SET ValueListType='List' WHERE ID='C64968CB-CC40-403A-A02B-E245FE564172'

/* SQL text to insert entity field value with ID 693e6655-1f22-4a12-aa92-3dd657f36584 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('693e6655-1f22-4a12-aa92-3dd657f36584', '5ED84866-8B7B-42C5-912E-80FDAC5B4D1F', 1, 'Active', 'Active')

/* SQL text to insert entity field value with ID a31ffdca-a66d-4267-919a-580f195ceea4 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('a31ffdca-a66d-4267-919a-580f195ceea4', '5ED84866-8B7B-42C5-912E-80FDAC5B4D1F', 2, 'Dissolved', 'Dissolved')

/* SQL text to insert entity field value with ID 4515dfea-8f4f-491d-87b7-5f4d4bd81651 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('4515dfea-8f4f-491d-87b7-5f4d4bd81651', '5ED84866-8B7B-42C5-912E-80FDAC5B4D1F', 3, 'Inactive', 'Inactive')

/* SQL text to update ValueListType for entity field ID 5ED84866-8B7B-42C5-912E-80FDAC5B4D1F */
UPDATE [${flyway:defaultSchema}].EntityField SET ValueListType='List' WHERE ID='5ED84866-8B7B-42C5-912E-80FDAC5B4D1F'

/* SQL text to insert entity field value with ID c5422acf-c9c4-4e9c-a97c-2bd5768d13a7 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('c5422acf-c9c4-4e9c-a97c-2bd5768d13a7', '228F924E-DB74-41E4-8D20-942D899C03D6', 1, 'Active', 'Active')

/* SQL text to insert entity field value with ID be5f406e-536c-470f-93ed-dd209d56b007 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('be5f406e-536c-470f-93ed-dd209d56b007', '228F924E-DB74-41E4-8D20-942D899C03D6', 2, 'Ended', 'Ended')

/* SQL text to insert entity field value with ID 945fde93-a912-4d53-8e27-ff91fdc2cb06 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('945fde93-a912-4d53-8e27-ff91fdc2cb06', '228F924E-DB74-41E4-8D20-942D899C03D6', 3, 'Inactive', 'Inactive')

/* SQL text to update ValueListType for entity field ID 228F924E-DB74-41E4-8D20-942D899C03D6 */
UPDATE [${flyway:defaultSchema}].EntityField SET ValueListType='List' WHERE ID='228F924E-DB74-41E4-8D20-942D899C03D6'


/* Create Entity Relationship: Common: Contact Types -> Common: Contact Methods (One To Many via ContactTypeID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '7acdd231-51b3-416e-8e7a-e7e75ac87e6d'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('7acdd231-51b3-416e-8e7a-e7e75ac87e6d', 'D17353E5-1FB0-4940-8D91-3E4007549200', 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA', 'ContactTypeID', 'One To Many', 1, 1, 'Common: Contact Methods', 1);
   END
                              
/* Create Entity Relationship: Common: Address Types -> Common: Address Links (One To Many via AddressTypeID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = 'f1e2bf7c-4973-446e-8b48-3975bf9b15ed'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('f1e2bf7c-4973-446e-8b48-3975bf9b15ed', '66FA272F-59BB-4105-A1F3-4E5D4D63F381', '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD', 'AddressTypeID', 'One To Many', 1, 1, 'Common: Address Links', 1);
   END
                              
/* Create Entity Relationship: MJ: Entities -> Common: Address Links (One To Many via EntityID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '54a62f1c-7827-4eb7-964e-6239dc8d405c'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('54a62f1c-7827-4eb7-964e-6239dc8d405c', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD', 'EntityID', 'One To Many', 1, 1, 'Common: Address Links', 2);
   END
                              
/* Create Entity Relationship: MJ: Users -> Common: People (One To Many via LinkedUserID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '824ce063-f4cf-416f-8b13-83186157c95f'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('824ce063-f4cf-416f-8b13-83186157c95f', 'E1238F34-2837-EF11-86D4-6045BDEE16E6', 'A3CB56E8-38B9-4456-BD88-F5E69E219D65', 'LinkedUserID', 'One To Many', 1, 1, 'Common: People', 1);
   END
                              
/* Create Entity Relationship: Common: Relationship Types -> Common: Relationships (One To Many via RelationshipTypeID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '99f43e3f-8037-41df-8a25-19f2f14b64c0'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('99f43e3f-8037-41df-8a25-19f2f14b64c0', '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB', '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', 'RelationshipTypeID', 'One To Many', 1, 1, 'Common: Relationships', 1);
   END
                              


/* Create Entity Relationship: Common: Organizations -> Common: Relationships (One To Many via FromOrganizationID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '2d071d5c-cc49-4a2c-8577-3bee4d5797af'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('2d071d5c-cc49-4a2c-8577-3bee4d5797af', '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', 'FromOrganizationID', 'One To Many', 1, 1, 'Common: Relationships', 2);
   END
                              
/* Create Entity Relationship: Common: Organizations -> Common: Relationships (One To Many via ToOrganizationID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '821e0b04-ad20-40b4-b19d-b6c1c1c6b948'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('821e0b04-ad20-40b4-b19d-b6c1c1c6b948', '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', 'ToOrganizationID', 'One To Many', 1, 1, 'Common: Relationships', 3);
   END
                              
/* Create Entity Relationship: Common: Organizations -> Common: Organizations (One To Many via ParentID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '3533be62-dfa7-4b4d-b640-31aebf2e9cbc'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('3533be62-dfa7-4b4d-b640-31aebf2e9cbc', '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', 'ParentID', 'One To Many', 1, 1, 'Common: Organizations', 1);
   END
                              
/* Create Entity Relationship: Common: Organizations -> Common: Contact Methods (One To Many via OrganizationID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '0d6871dd-9689-4dda-85bd-a6d5f5688728'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('0d6871dd-9689-4dda-85bd-a6d5f5688728', '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA', 'OrganizationID', 'One To Many', 1, 1, 'Common: Contact Methods', 2);
   END
                              
/* Create Entity Relationship: Common: Organization Types -> Common: Organizations (One To Many via OrganizationTypeID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '58296c32-759f-4ab8-9a03-11f7097c836b'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('58296c32-759f-4ab8-9a03-11f7097c836b', '0AB066C1-8FE5-4363-86E6-BEF80975205C', '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', 'OrganizationTypeID', 'One To Many', 1, 1, 'Common: Organizations', 2);
   END
                              


/* Create Entity Relationship: Common: Addresses -> Common: Address Links (One To Many via AddressID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = 'bc311529-aa34-4e07-ad29-3dbc4deda591'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('bc311529-aa34-4e07-ad29-3dbc4deda591', 'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C', '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD', 'AddressID', 'One To Many', 1, 1, 'Common: Address Links', 3);
   END
                              
/* Create Entity Relationship: Common: People -> Common: Relationships (One To Many via ToPersonID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = 'acd1104e-96ea-419d-a160-e153a0b4b6c6'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('acd1104e-96ea-419d-a160-e153a0b4b6c6', 'A3CB56E8-38B9-4456-BD88-F5E69E219D65', '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', 'ToPersonID', 'One To Many', 1, 1, 'Common: Relationships', 4);
   END
                              
/* Create Entity Relationship: Common: People -> Common: Contact Methods (One To Many via PersonID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = 'c44d4251-ffd0-4db6-bd21-1f43e731191a'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('c44d4251-ffd0-4db6-bd21-1f43e731191a', 'A3CB56E8-38B9-4456-BD88-F5E69E219D65', 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA', 'PersonID', 'One To Many', 1, 1, 'Common: Contact Methods', 3);
   END
                              
/* Create Entity Relationship: Common: People -> Common: Relationships (One To Many via FromPersonID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = 'e01a742b-643c-4afa-9e6a-3e2245e1c39a'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('e01a742b-643c-4afa-9e6a-3e2245e1c39a', 'A3CB56E8-38B9-4456-BD88-F5E69E219D65', '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', 'FromPersonID', 'One To Many', 1, 1, 'Common: Relationships', 5);
   END
                              

/* Index for Foreign Keys for AddressLink */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Address Links
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key AddressID in table AddressLink
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_AddressLink_AddressID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[AddressLink]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_AddressLink_AddressID ON [${flyway:defaultSchema}_BizAppsCommon].[AddressLink] ([AddressID]);

-- Index for foreign key EntityID in table AddressLink
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_AddressLink_EntityID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[AddressLink]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_AddressLink_EntityID ON [${flyway:defaultSchema}_BizAppsCommon].[AddressLink] ([EntityID]);

-- Index for foreign key AddressTypeID in table AddressLink
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_AddressLink_AddressTypeID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[AddressLink]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_AddressLink_AddressTypeID ON [${flyway:defaultSchema}_BizAppsCommon].[AddressLink] ([AddressTypeID]);

/* SQL text to update entity field related entity name field map for entity field ID CFCBE12E-5B60-44C1-BDF9-F672294778FB */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='CFCBE12E-5B60-44C1-BDF9-F672294778FB',
         @RelatedEntityNameFieldMap='Entity'

/* Index for Foreign Keys for AddressType */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Address Types
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------


/* Index for Foreign Keys for Address */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Addresses
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------


/* Index for Foreign Keys for ContactMethod */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Contact Methods
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key PersonID in table ContactMethod
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactMethod_PersonID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[ContactMethod]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactMethod_PersonID ON [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod] ([PersonID]);

-- Index for foreign key OrganizationID in table ContactMethod
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactMethod_OrganizationID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[ContactMethod]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactMethod_OrganizationID ON [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod] ([OrganizationID]);

-- Index for foreign key ContactTypeID in table ContactMethod
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactMethod_ContactTypeID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[ContactMethod]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactMethod_ContactTypeID ON [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod] ([ContactTypeID]);

/* SQL text to update entity field related entity name field map for entity field ID 203C3260-2DF9-4478-B639-D0401AC0AC28 */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='203C3260-2DF9-4478-B639-D0401AC0AC28',
         @RelatedEntityNameFieldMap='Organization'

/* Index for Foreign Keys for ContactType */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Contact Types
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------


/* Base View SQL for Common: Address Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Address Types
-- Item: vwAddressTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      Common: Address Types
-----               SCHEMA:      ${flyway:defaultSchema}_BizAppsCommon
-----               BASE TABLE:  AddressType
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[vwAddressTypes]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwAddressTypes];
GO

CREATE VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwAddressTypes]
AS
SELECT
    a.*
FROM
    [${flyway:defaultSchema}_BizAppsCommon].[AddressType] AS a
GO
GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwAddressTypes] TO [cdp_UI], [cdp_Developer], [cdp_Integration]
    

/* Base View Permissions SQL for Common: Address Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Address Types
-- Item: Permissions for vwAddressTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwAddressTypes] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for Common: Address Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Address Types
-- Item: spCreateAddressType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR AddressType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spCreateAddressType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddressType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddressType]
    @ID uniqueidentifier = NULL,
    @Name nvarchar(100),
    @Description nvarchar(MAX),
    @DefaultRank int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)
    
    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[AddressType]
            (
                [ID],
                [Name],
                [Description],
                [DefaultRank]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Name,
                @Description,
                ISNULL(@DefaultRank, 100)
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[AddressType]
            (
                [Name],
                [Description],
                [DefaultRank]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                @Description,
                ISNULL(@DefaultRank, 100)
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwAddressTypes] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddressType] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for Common: Address Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddressType] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for Common: Address Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Address Types
-- Item: spUpdateAddressType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR AddressType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddressType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddressType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddressType]
    @ID uniqueidentifier,
    @Name nvarchar(100),
    @Description nvarchar(MAX),
    @DefaultRank int
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[AddressType]
    SET
        [Name] = @Name,
        [Description] = @Description,
        [DefaultRank] = @DefaultRank
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwAddressTypes] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}_BizAppsCommon].[vwAddressTypes]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddressType] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the AddressType table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[trgUpdateAddressType]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}_BizAppsCommon].[trgUpdateAddressType];
GO
CREATE TRIGGER [${flyway:defaultSchema}_BizAppsCommon].trgUpdateAddressType
ON [${flyway:defaultSchema}_BizAppsCommon].[AddressType]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[AddressType]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}_BizAppsCommon].[AddressType] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO
        

/* spUpdate Permissions for Common: Address Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddressType] TO [cdp_Developer], [cdp_Integration]



/* Base View SQL for Common: Addresses */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Addresses
-- Item: vwAddresses
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      Common: Addresses
-----               SCHEMA:      ${flyway:defaultSchema}_BizAppsCommon
-----               BASE TABLE:  Address
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[vwAddresses]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwAddresses];
GO

CREATE VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwAddresses]
AS
SELECT
    a.*
FROM
    [${flyway:defaultSchema}_BizAppsCommon].[Address] AS a
GO
GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwAddresses] TO [cdp_UI], [cdp_Developer], [cdp_Integration]
    

/* Base View Permissions SQL for Common: Addresses */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Addresses
-- Item: Permissions for vwAddresses
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwAddresses] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for Common: Addresses */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Addresses
-- Item: spCreateAddress
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Address
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spCreateAddress]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddress];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddress]
    @ID uniqueidentifier = NULL,
    @Line1 nvarchar(255),
    @Line2 nvarchar(255),
    @Line3 nvarchar(255),
    @City nvarchar(100),
    @StateProvince nvarchar(100),
    @PostalCode nvarchar(20),
    @Country nvarchar(100) = NULL,
    @Latitude decimal(9, 6),
    @Longitude decimal(9, 6)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)
    
    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[Address]
            (
                [ID],
                [Line1],
                [Line2],
                [Line3],
                [City],
                [StateProvince],
                [PostalCode],
                [Country],
                [Latitude],
                [Longitude]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Line1,
                @Line2,
                @Line3,
                @City,
                @StateProvince,
                @PostalCode,
                ISNULL(@Country, 'US'),
                @Latitude,
                @Longitude
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[Address]
            (
                [Line1],
                [Line2],
                [Line3],
                [City],
                [StateProvince],
                [PostalCode],
                [Country],
                [Latitude],
                [Longitude]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Line1,
                @Line2,
                @Line3,
                @City,
                @StateProvince,
                @PostalCode,
                ISNULL(@Country, 'US'),
                @Latitude,
                @Longitude
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwAddresses] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddress] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for Common: Addresses */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddress] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for Common: Addresses */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Addresses
-- Item: spUpdateAddress
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Address
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddress]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddress];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddress]
    @ID uniqueidentifier,
    @Line1 nvarchar(255),
    @Line2 nvarchar(255),
    @Line3 nvarchar(255),
    @City nvarchar(100),
    @StateProvince nvarchar(100),
    @PostalCode nvarchar(20),
    @Country nvarchar(100),
    @Latitude decimal(9, 6),
    @Longitude decimal(9, 6)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[Address]
    SET
        [Line1] = @Line1,
        [Line2] = @Line2,
        [Line3] = @Line3,
        [City] = @City,
        [StateProvince] = @StateProvince,
        [PostalCode] = @PostalCode,
        [Country] = @Country,
        [Latitude] = @Latitude,
        [Longitude] = @Longitude
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwAddresses] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}_BizAppsCommon].[vwAddresses]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddress] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Address table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[trgUpdateAddress]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}_BizAppsCommon].[trgUpdateAddress];
GO
CREATE TRIGGER [${flyway:defaultSchema}_BizAppsCommon].trgUpdateAddress
ON [${flyway:defaultSchema}_BizAppsCommon].[Address]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[Address]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}_BizAppsCommon].[Address] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO
        

/* spUpdate Permissions for Common: Addresses */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddress] TO [cdp_Developer], [cdp_Integration]



/* Base View SQL for Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Contact Types
-- Item: vwContactTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      Common: Contact Types
-----               SCHEMA:      ${flyway:defaultSchema}_BizAppsCommon
-----               BASE TABLE:  ContactType
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[vwContactTypes]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwContactTypes];
GO

CREATE VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwContactTypes]
AS
SELECT
    c.*
FROM
    [${flyway:defaultSchema}_BizAppsCommon].[ContactType] AS c
GO
GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwContactTypes] TO [cdp_UI], [cdp_Developer], [cdp_Integration]
    

/* Base View Permissions SQL for Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Contact Types
-- Item: Permissions for vwContactTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwContactTypes] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Contact Types
-- Item: spCreateContactType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ContactType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spCreateContactType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateContactType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateContactType]
    @ID uniqueidentifier = NULL,
    @Name nvarchar(100),
    @Description nvarchar(MAX),
    @IconClass nvarchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)
    
    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[ContactType]
            (
                [ID],
                [Name],
                [Description],
                [IconClass]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Name,
                @Description,
                @IconClass
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[ContactType]
            (
                [Name],
                [Description],
                [IconClass]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                @Description,
                @IconClass
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwContactTypes] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateContactType] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for Common: Contact Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateContactType] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Contact Types
-- Item: spUpdateContactType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ContactType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spUpdateContactType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateContactType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateContactType]
    @ID uniqueidentifier,
    @Name nvarchar(100),
    @Description nvarchar(MAX),
    @IconClass nvarchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[ContactType]
    SET
        [Name] = @Name,
        [Description] = @Description,
        [IconClass] = @IconClass
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwContactTypes] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}_BizAppsCommon].[vwContactTypes]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateContactType] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ContactType table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[trgUpdateContactType]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}_BizAppsCommon].[trgUpdateContactType];
GO
CREATE TRIGGER [${flyway:defaultSchema}_BizAppsCommon].trgUpdateContactType
ON [${flyway:defaultSchema}_BizAppsCommon].[ContactType]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[ContactType]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}_BizAppsCommon].[ContactType] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO
        

/* spUpdate Permissions for Common: Contact Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateContactType] TO [cdp_Developer], [cdp_Integration]



/* spDelete SQL for Common: Address Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Address Types
-- Item: spDeleteAddressType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR AddressType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddressType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddressType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddressType]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}_BizAppsCommon].[AddressType]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddressType] TO [cdp_Integration]
    

/* spDelete Permissions for Common: Address Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddressType] TO [cdp_Integration]



/* spDelete SQL for Common: Addresses */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Addresses
-- Item: spDeleteAddress
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Address
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddress]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddress];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddress]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}_BizAppsCommon].[Address]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddress] TO [cdp_Integration]
    

/* spDelete Permissions for Common: Addresses */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddress] TO [cdp_Integration]



/* spDelete SQL for Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Contact Types
-- Item: spDeleteContactType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ContactType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spDeleteContactType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteContactType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteContactType]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}_BizAppsCommon].[ContactType]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteContactType] TO [cdp_Integration]
    

/* spDelete Permissions for Common: Contact Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteContactType] TO [cdp_Integration]



/* SQL text to update entity field related entity name field map for entity field ID 71E1C019-742D-422F-B412-D85757922ADB */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='71E1C019-742D-422F-B412-D85757922ADB',
         @RelatedEntityNameFieldMap='AddressType'

/* SQL text to update entity field related entity name field map for entity field ID 0B306E5D-0024-471A-9E43-5293C57D4759 */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='0B306E5D-0024-471A-9E43-5293C57D4759',
         @RelatedEntityNameFieldMap='ContactType'

/* Base View SQL for Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Address Links
-- Item: vwAddressLinks
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      Common: Address Links
-----               SCHEMA:      ${flyway:defaultSchema}_BizAppsCommon
-----               BASE TABLE:  AddressLink
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[vwAddressLinks]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwAddressLinks];
GO

CREATE VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwAddressLinks]
AS
SELECT
    a.*,
    MJEntity_EntityID.[Name] AS [Entity],
    mjBizAppsCommonAddressType_AddressTypeID.[Name] AS [AddressType]
FROM
    [${flyway:defaultSchema}_BizAppsCommon].[AddressLink] AS a
INNER JOIN
    [${flyway:defaultSchema}].[Entity] AS MJEntity_EntityID
  ON
    [a].[EntityID] = MJEntity_EntityID.[ID]
INNER JOIN
    [${flyway:defaultSchema}_BizAppsCommon].[AddressType] AS mjBizAppsCommonAddressType_AddressTypeID
  ON
    [a].[AddressTypeID] = mjBizAppsCommonAddressType_AddressTypeID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwAddressLinks] TO [cdp_UI], [cdp_Developer], [cdp_Integration]
    

/* Base View Permissions SQL for Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Address Links
-- Item: Permissions for vwAddressLinks
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwAddressLinks] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Address Links
-- Item: spCreateAddressLink
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR AddressLink
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spCreateAddressLink]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddressLink];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddressLink]
    @ID uniqueidentifier = NULL,
    @AddressID uniqueidentifier,
    @EntityID uniqueidentifier,
    @RecordID nvarchar(700),
    @AddressTypeID uniqueidentifier,
    @IsPrimary bit = NULL,
    @Rank int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)
    
    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[AddressLink]
            (
                [ID],
                [AddressID],
                [EntityID],
                [RecordID],
                [AddressTypeID],
                [IsPrimary],
                [Rank]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @AddressID,
                @EntityID,
                @RecordID,
                @AddressTypeID,
                ISNULL(@IsPrimary, 0),
                @Rank
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[AddressLink]
            (
                [AddressID],
                [EntityID],
                [RecordID],
                [AddressTypeID],
                [IsPrimary],
                [Rank]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @AddressID,
                @EntityID,
                @RecordID,
                @AddressTypeID,
                ISNULL(@IsPrimary, 0),
                @Rank
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwAddressLinks] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddressLink] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for Common: Address Links */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddressLink] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Address Links
-- Item: spUpdateAddressLink
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR AddressLink
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddressLink]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddressLink];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddressLink]
    @ID uniqueidentifier,
    @AddressID uniqueidentifier,
    @EntityID uniqueidentifier,
    @RecordID nvarchar(700),
    @AddressTypeID uniqueidentifier,
    @IsPrimary bit,
    @Rank int
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[AddressLink]
    SET
        [AddressID] = @AddressID,
        [EntityID] = @EntityID,
        [RecordID] = @RecordID,
        [AddressTypeID] = @AddressTypeID,
        [IsPrimary] = @IsPrimary,
        [Rank] = @Rank
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwAddressLinks] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}_BizAppsCommon].[vwAddressLinks]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddressLink] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the AddressLink table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[trgUpdateAddressLink]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}_BizAppsCommon].[trgUpdateAddressLink];
GO
CREATE TRIGGER [${flyway:defaultSchema}_BizAppsCommon].trgUpdateAddressLink
ON [${flyway:defaultSchema}_BizAppsCommon].[AddressLink]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[AddressLink]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}_BizAppsCommon].[AddressLink] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO
        

/* spUpdate Permissions for Common: Address Links */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddressLink] TO [cdp_Developer], [cdp_Integration]



/* spDelete SQL for Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Address Links
-- Item: spDeleteAddressLink
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR AddressLink
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddressLink]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddressLink];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddressLink]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}_BizAppsCommon].[AddressLink]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddressLink] TO [cdp_Integration]
    

/* spDelete Permissions for Common: Address Links */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddressLink] TO [cdp_Integration]



/* Base View SQL for Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Contact Methods
-- Item: vwContactMethods
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      Common: Contact Methods
-----               SCHEMA:      ${flyway:defaultSchema}_BizAppsCommon
-----               BASE TABLE:  ContactMethod
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[vwContactMethods]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwContactMethods];
GO

CREATE VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwContactMethods]
AS
SELECT
    c.*,
    mjBizAppsCommonOrganization_OrganizationID.[Name] AS [Organization],
    mjBizAppsCommonContactType_ContactTypeID.[Name] AS [ContactType]
FROM
    [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod] AS c
LEFT OUTER JOIN
    [${flyway:defaultSchema}_BizAppsCommon].[Organization] AS mjBizAppsCommonOrganization_OrganizationID
  ON
    [c].[OrganizationID] = mjBizAppsCommonOrganization_OrganizationID.[ID]
INNER JOIN
    [${flyway:defaultSchema}_BizAppsCommon].[ContactType] AS mjBizAppsCommonContactType_ContactTypeID
  ON
    [c].[ContactTypeID] = mjBizAppsCommonContactType_ContactTypeID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwContactMethods] TO [cdp_UI], [cdp_Developer], [cdp_Integration]
    

/* Base View Permissions SQL for Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Contact Methods
-- Item: Permissions for vwContactMethods
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwContactMethods] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Contact Methods
-- Item: spCreateContactMethod
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ContactMethod
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spCreateContactMethod]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateContactMethod];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateContactMethod]
    @ID uniqueidentifier = NULL,
    @PersonID uniqueidentifier,
    @OrganizationID uniqueidentifier,
    @ContactTypeID uniqueidentifier,
    @Value nvarchar(500),
    @Label nvarchar(100),
    @IsPrimary bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)
    
    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod]
            (
                [ID],
                [PersonID],
                [OrganizationID],
                [ContactTypeID],
                [Value],
                [Label],
                [IsPrimary]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @PersonID,
                @OrganizationID,
                @ContactTypeID,
                @Value,
                @Label,
                ISNULL(@IsPrimary, 0)
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod]
            (
                [PersonID],
                [OrganizationID],
                [ContactTypeID],
                [Value],
                [Label],
                [IsPrimary]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @PersonID,
                @OrganizationID,
                @ContactTypeID,
                @Value,
                @Label,
                ISNULL(@IsPrimary, 0)
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwContactMethods] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateContactMethod] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for Common: Contact Methods */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateContactMethod] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Contact Methods
-- Item: spUpdateContactMethod
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ContactMethod
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spUpdateContactMethod]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateContactMethod];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateContactMethod]
    @ID uniqueidentifier,
    @PersonID uniqueidentifier,
    @OrganizationID uniqueidentifier,
    @ContactTypeID uniqueidentifier,
    @Value nvarchar(500),
    @Label nvarchar(100),
    @IsPrimary bit
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod]
    SET
        [PersonID] = @PersonID,
        [OrganizationID] = @OrganizationID,
        [ContactTypeID] = @ContactTypeID,
        [Value] = @Value,
        [Label] = @Label,
        [IsPrimary] = @IsPrimary
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwContactMethods] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}_BizAppsCommon].[vwContactMethods]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateContactMethod] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ContactMethod table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[trgUpdateContactMethod]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}_BizAppsCommon].[trgUpdateContactMethod];
GO
CREATE TRIGGER [${flyway:defaultSchema}_BizAppsCommon].trgUpdateContactMethod
ON [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO
        

/* spUpdate Permissions for Common: Contact Methods */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateContactMethod] TO [cdp_Developer], [cdp_Integration]



/* spDelete SQL for Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Contact Methods
-- Item: spDeleteContactMethod
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ContactMethod
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spDeleteContactMethod]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteContactMethod];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteContactMethod]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteContactMethod] TO [cdp_Integration]
    

/* spDelete Permissions for Common: Contact Methods */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteContactMethod] TO [cdp_Integration]



/* Index for Foreign Keys for OrganizationType */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Organization Types
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------


/* Index for Foreign Keys for Organization */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Organizations
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key OrganizationTypeID in table Organization
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Organization_OrganizationTypeID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[Organization]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Organization_OrganizationTypeID ON [${flyway:defaultSchema}_BizAppsCommon].[Organization] ([OrganizationTypeID]);

-- Index for foreign key ParentID in table Organization
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Organization_ParentID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[Organization]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Organization_ParentID ON [${flyway:defaultSchema}_BizAppsCommon].[Organization] ([ParentID]);

/* Root ID Function SQL for Common: Organizations.ParentID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Organizations
-- Item: fnOrganizationParentID_GetRootID
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- ROOT ID FUNCTION FOR: [Organization].[ParentID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[fnOrganizationParentID_GetRootID]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}_BizAppsCommon].[fnOrganizationParentID_GetRootID];
GO

CREATE FUNCTION [${flyway:defaultSchema}_BizAppsCommon].[fnOrganizationParentID_GetRootID]
(
    @RecordID uniqueidentifier,
    @ParentID uniqueidentifier
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_RootParent AS (
        -- Anchor: Start from @ParentID if not null, otherwise start from @RecordID
        SELECT
            [ID],
            [ParentID],
            [ID] AS [RootParentID],
            0 AS [Depth]
        FROM
            [${flyway:defaultSchema}_BizAppsCommon].[Organization]
        WHERE
            [ID] = COALESCE(@ParentID, @RecordID)

        UNION ALL

        -- Recursive: Keep going up the hierarchy until ParentID is NULL
        -- Includes depth counter to prevent infinite loops from circular references
        SELECT
            c.[ID],
            c.[ParentID],
            c.[ID] AS [RootParentID],
            p.[Depth] + 1 AS [Depth]
        FROM
            [${flyway:defaultSchema}_BizAppsCommon].[Organization] c
        INNER JOIN
            CTE_RootParent p ON c.[ID] = p.[ParentID]
        WHERE
            p.[Depth] < 100  -- Prevent infinite loops, max 100 levels
    )
    SELECT TOP 1
        [RootParentID] AS RootID
    FROM
        CTE_RootParent
    WHERE
        [ParentID] IS NULL
    ORDER BY
        [RootParentID]
);
GO


/* SQL text to update entity field related entity name field map for entity field ID 0902C7F8-4D7F-40EA-BAA6-A6C36B22FEA5 */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='0902C7F8-4D7F-40EA-BAA6-A6C36B22FEA5',
         @RelatedEntityNameFieldMap='OrganizationType'

/* Index for Foreign Keys for Person */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: People
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key LinkedUserID in table Person
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Person_LinkedUserID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[Person]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Person_LinkedUserID ON [${flyway:defaultSchema}_BizAppsCommon].[Person] ([LinkedUserID]);

/* SQL text to update entity field related entity name field map for entity field ID 7DFC3BF1-A07F-463E-845A-C934275BBFCF */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='7DFC3BF1-A07F-463E-845A-C934275BBFCF',
         @RelatedEntityNameFieldMap='LinkedUser'

/* Index for Foreign Keys for RelationshipType */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Relationship Types
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------


/* Index for Foreign Keys for Relationship */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Relationships
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key RelationshipTypeID in table Relationship
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Relationship_RelationshipTypeID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[Relationship]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Relationship_RelationshipTypeID ON [${flyway:defaultSchema}_BizAppsCommon].[Relationship] ([RelationshipTypeID]);

-- Index for foreign key FromPersonID in table Relationship
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Relationship_FromPersonID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[Relationship]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Relationship_FromPersonID ON [${flyway:defaultSchema}_BizAppsCommon].[Relationship] ([FromPersonID]);

-- Index for foreign key FromOrganizationID in table Relationship
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Relationship_FromOrganizationID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[Relationship]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Relationship_FromOrganizationID ON [${flyway:defaultSchema}_BizAppsCommon].[Relationship] ([FromOrganizationID]);

-- Index for foreign key ToPersonID in table Relationship
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Relationship_ToPersonID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[Relationship]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Relationship_ToPersonID ON [${flyway:defaultSchema}_BizAppsCommon].[Relationship] ([ToPersonID]);

-- Index for foreign key ToOrganizationID in table Relationship
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Relationship_ToOrganizationID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[Relationship]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Relationship_ToOrganizationID ON [${flyway:defaultSchema}_BizAppsCommon].[Relationship] ([ToOrganizationID]);

/* SQL text to update entity field related entity name field map for entity field ID EAAC9A59-CE53-43E4-B663-0CEFAF8300D0 */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='EAAC9A59-CE53-43E4-B663-0CEFAF8300D0',
         @RelatedEntityNameFieldMap='RelationshipType'

/* Base View SQL for Common: Organization Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Organization Types
-- Item: vwOrganizationTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      Common: Organization Types
-----               SCHEMA:      ${flyway:defaultSchema}_BizAppsCommon
-----               BASE TABLE:  OrganizationType
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[vwOrganizationTypes]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizationTypes];
GO

CREATE VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizationTypes]
AS
SELECT
    o.*
FROM
    [${flyway:defaultSchema}_BizAppsCommon].[OrganizationType] AS o
GO
GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizationTypes] TO [cdp_UI], [cdp_Developer], [cdp_Integration]
    

/* Base View Permissions SQL for Common: Organization Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Organization Types
-- Item: Permissions for vwOrganizationTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizationTypes] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for Common: Organization Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Organization Types
-- Item: spCreateOrganizationType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR OrganizationType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spCreateOrganizationType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateOrganizationType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateOrganizationType]
    @ID uniqueidentifier = NULL,
    @Name nvarchar(100),
    @Description nvarchar(MAX),
    @IconClass nvarchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)
    
    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[OrganizationType]
            (
                [ID],
                [Name],
                [Description],
                [IconClass]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Name,
                @Description,
                @IconClass
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[OrganizationType]
            (
                [Name],
                [Description],
                [IconClass]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                @Description,
                @IconClass
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizationTypes] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateOrganizationType] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for Common: Organization Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateOrganizationType] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for Common: Organization Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Organization Types
-- Item: spUpdateOrganizationType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR OrganizationType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spUpdateOrganizationType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateOrganizationType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateOrganizationType]
    @ID uniqueidentifier,
    @Name nvarchar(100),
    @Description nvarchar(MAX),
    @IconClass nvarchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[OrganizationType]
    SET
        [Name] = @Name,
        [Description] = @Description,
        [IconClass] = @IconClass
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizationTypes] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizationTypes]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateOrganizationType] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the OrganizationType table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[trgUpdateOrganizationType]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}_BizAppsCommon].[trgUpdateOrganizationType];
GO
CREATE TRIGGER [${flyway:defaultSchema}_BizAppsCommon].trgUpdateOrganizationType
ON [${flyway:defaultSchema}_BizAppsCommon].[OrganizationType]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[OrganizationType]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}_BizAppsCommon].[OrganizationType] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO
        

/* spUpdate Permissions for Common: Organization Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateOrganizationType] TO [cdp_Developer], [cdp_Integration]



/* Base View SQL for Common: Relationship Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Relationship Types
-- Item: vwRelationshipTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      Common: Relationship Types
-----               SCHEMA:      ${flyway:defaultSchema}_BizAppsCommon
-----               BASE TABLE:  RelationshipType
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[vwRelationshipTypes]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwRelationshipTypes];
GO

CREATE VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwRelationshipTypes]
AS
SELECT
    r.*
FROM
    [${flyway:defaultSchema}_BizAppsCommon].[RelationshipType] AS r
GO
GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwRelationshipTypes] TO [cdp_UI], [cdp_Developer], [cdp_Integration]
    

/* Base View Permissions SQL for Common: Relationship Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Relationship Types
-- Item: Permissions for vwRelationshipTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwRelationshipTypes] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for Common: Relationship Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Relationship Types
-- Item: spCreateRelationshipType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR RelationshipType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spCreateRelationshipType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateRelationshipType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateRelationshipType]
    @ID uniqueidentifier = NULL,
    @Name nvarchar(100),
    @Description nvarchar(MAX),
    @Category nvarchar(50),
    @IsDirectional bit = NULL,
    @ForwardLabel nvarchar(100),
    @ReverseLabel nvarchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)
    
    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[RelationshipType]
            (
                [ID],
                [Name],
                [Description],
                [Category],
                [IsDirectional],
                [ForwardLabel],
                [ReverseLabel]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Name,
                @Description,
                @Category,
                ISNULL(@IsDirectional, 1),
                @ForwardLabel,
                @ReverseLabel
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[RelationshipType]
            (
                [Name],
                [Description],
                [Category],
                [IsDirectional],
                [ForwardLabel],
                [ReverseLabel]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                @Description,
                @Category,
                ISNULL(@IsDirectional, 1),
                @ForwardLabel,
                @ReverseLabel
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwRelationshipTypes] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateRelationshipType] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for Common: Relationship Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateRelationshipType] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for Common: Relationship Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Relationship Types
-- Item: spUpdateRelationshipType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR RelationshipType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spUpdateRelationshipType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateRelationshipType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateRelationshipType]
    @ID uniqueidentifier,
    @Name nvarchar(100),
    @Description nvarchar(MAX),
    @Category nvarchar(50),
    @IsDirectional bit,
    @ForwardLabel nvarchar(100),
    @ReverseLabel nvarchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[RelationshipType]
    SET
        [Name] = @Name,
        [Description] = @Description,
        [Category] = @Category,
        [IsDirectional] = @IsDirectional,
        [ForwardLabel] = @ForwardLabel,
        [ReverseLabel] = @ReverseLabel
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwRelationshipTypes] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}_BizAppsCommon].[vwRelationshipTypes]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateRelationshipType] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the RelationshipType table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[trgUpdateRelationshipType]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}_BizAppsCommon].[trgUpdateRelationshipType];
GO
CREATE TRIGGER [${flyway:defaultSchema}_BizAppsCommon].trgUpdateRelationshipType
ON [${flyway:defaultSchema}_BizAppsCommon].[RelationshipType]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[RelationshipType]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}_BizAppsCommon].[RelationshipType] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO
        

/* spUpdate Permissions for Common: Relationship Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateRelationshipType] TO [cdp_Developer], [cdp_Integration]



/* spDelete SQL for Common: Organization Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Organization Types
-- Item: spDeleteOrganizationType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR OrganizationType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spDeleteOrganizationType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteOrganizationType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteOrganizationType]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}_BizAppsCommon].[OrganizationType]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteOrganizationType] TO [cdp_Integration]
    

/* spDelete Permissions for Common: Organization Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteOrganizationType] TO [cdp_Integration]



/* spDelete SQL for Common: Relationship Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Relationship Types
-- Item: spDeleteRelationshipType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR RelationshipType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spDeleteRelationshipType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteRelationshipType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteRelationshipType]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}_BizAppsCommon].[RelationshipType]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteRelationshipType] TO [cdp_Integration]
    

/* spDelete Permissions for Common: Relationship Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteRelationshipType] TO [cdp_Integration]



/* SQL text to update entity field related entity name field map for entity field ID 7A4A63E0-651D-4127-932A-C3D2EC1F24C6 */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='7A4A63E0-651D-4127-932A-C3D2EC1F24C6',
         @RelatedEntityNameFieldMap='Parent'

/* SQL text to update entity field related entity name field map for entity field ID 12FBD8AF-5847-453D-B40E-3D740C04769D */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='12FBD8AF-5847-453D-B40E-3D740C04769D',
         @RelatedEntityNameFieldMap='FromOrganization'

/* Base View SQL for Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: People
-- Item: vwPeople
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      Common: People
-----               SCHEMA:      ${flyway:defaultSchema}_BizAppsCommon
-----               BASE TABLE:  Person
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[vwPeople]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwPeople];
GO

CREATE VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwPeople]
AS
SELECT
    p.*,
    MJUser_LinkedUserID.[Name] AS [LinkedUser]
FROM
    [${flyway:defaultSchema}_BizAppsCommon].[Person] AS p
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[User] AS MJUser_LinkedUserID
  ON
    [p].[LinkedUserID] = MJUser_LinkedUserID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwPeople] TO [cdp_UI], [cdp_Developer], [cdp_Integration]
    

/* Base View Permissions SQL for Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: People
-- Item: Permissions for vwPeople
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwPeople] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: People
-- Item: spCreatePerson
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Person
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spCreatePerson]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreatePerson];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreatePerson]
    @ID uniqueidentifier = NULL,
    @FirstName nvarchar(100),
    @LastName nvarchar(100),
    @MiddleName nvarchar(100),
    @Prefix nvarchar(20),
    @Suffix nvarchar(20),
    @PreferredName nvarchar(100),
    @Title nvarchar(200),
    @Email nvarchar(255),
    @Phone nvarchar(50),
    @DateOfBirth date,
    @Gender nvarchar(50),
    @PhotoURL nvarchar(1000),
    @Bio nvarchar(MAX),
    @LinkedUserID uniqueidentifier,
    @Status nvarchar(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)
    
    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[Person]
            (
                [ID],
                [FirstName],
                [LastName],
                [MiddleName],
                [Prefix],
                [Suffix],
                [PreferredName],
                [Title],
                [Email],
                [Phone],
                [DateOfBirth],
                [Gender],
                [PhotoURL],
                [Bio],
                [LinkedUserID],
                [Status]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @FirstName,
                @LastName,
                @MiddleName,
                @Prefix,
                @Suffix,
                @PreferredName,
                @Title,
                @Email,
                @Phone,
                @DateOfBirth,
                @Gender,
                @PhotoURL,
                @Bio,
                @LinkedUserID,
                ISNULL(@Status, 'Active')
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[Person]
            (
                [FirstName],
                [LastName],
                [MiddleName],
                [Prefix],
                [Suffix],
                [PreferredName],
                [Title],
                [Email],
                [Phone],
                [DateOfBirth],
                [Gender],
                [PhotoURL],
                [Bio],
                [LinkedUserID],
                [Status]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @FirstName,
                @LastName,
                @MiddleName,
                @Prefix,
                @Suffix,
                @PreferredName,
                @Title,
                @Email,
                @Phone,
                @DateOfBirth,
                @Gender,
                @PhotoURL,
                @Bio,
                @LinkedUserID,
                ISNULL(@Status, 'Active')
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwPeople] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreatePerson] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for Common: People */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreatePerson] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: People
-- Item: spUpdatePerson
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Person
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spUpdatePerson]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdatePerson];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdatePerson]
    @ID uniqueidentifier,
    @FirstName nvarchar(100),
    @LastName nvarchar(100),
    @MiddleName nvarchar(100),
    @Prefix nvarchar(20),
    @Suffix nvarchar(20),
    @PreferredName nvarchar(100),
    @Title nvarchar(200),
    @Email nvarchar(255),
    @Phone nvarchar(50),
    @DateOfBirth date,
    @Gender nvarchar(50),
    @PhotoURL nvarchar(1000),
    @Bio nvarchar(MAX),
    @LinkedUserID uniqueidentifier,
    @Status nvarchar(50)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[Person]
    SET
        [FirstName] = @FirstName,
        [LastName] = @LastName,
        [MiddleName] = @MiddleName,
        [Prefix] = @Prefix,
        [Suffix] = @Suffix,
        [PreferredName] = @PreferredName,
        [Title] = @Title,
        [Email] = @Email,
        [Phone] = @Phone,
        [DateOfBirth] = @DateOfBirth,
        [Gender] = @Gender,
        [PhotoURL] = @PhotoURL,
        [Bio] = @Bio,
        [LinkedUserID] = @LinkedUserID,
        [Status] = @Status
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwPeople] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}_BizAppsCommon].[vwPeople]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdatePerson] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Person table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[trgUpdatePerson]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}_BizAppsCommon].[trgUpdatePerson];
GO
CREATE TRIGGER [${flyway:defaultSchema}_BizAppsCommon].trgUpdatePerson
ON [${flyway:defaultSchema}_BizAppsCommon].[Person]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[Person]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}_BizAppsCommon].[Person] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO
        

/* spUpdate Permissions for Common: People */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdatePerson] TO [cdp_Developer], [cdp_Integration]



/* spDelete SQL for Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: People
-- Item: spDeletePerson
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Person
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spDeletePerson]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeletePerson];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeletePerson]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}_BizAppsCommon].[Person]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeletePerson] TO [cdp_Integration]
    

/* spDelete Permissions for Common: People */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeletePerson] TO [cdp_Integration]



/* Base View SQL for Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Organizations
-- Item: vwOrganizations
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      Common: Organizations
-----               SCHEMA:      ${flyway:defaultSchema}_BizAppsCommon
-----               BASE TABLE:  Organization
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[vwOrganizations]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizations];
GO

CREATE VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizations]
AS
SELECT
    o.*,
    mjBizAppsCommonOrganizationType_OrganizationTypeID.[Name] AS [OrganizationType],
    mjBizAppsCommonOrganization_ParentID.[Name] AS [Parent],
    root_ParentID.RootID AS [RootParentID]
FROM
    [${flyway:defaultSchema}_BizAppsCommon].[Organization] AS o
LEFT OUTER JOIN
    [${flyway:defaultSchema}_BizAppsCommon].[OrganizationType] AS mjBizAppsCommonOrganizationType_OrganizationTypeID
  ON
    [o].[OrganizationTypeID] = mjBizAppsCommonOrganizationType_OrganizationTypeID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}_BizAppsCommon].[Organization] AS mjBizAppsCommonOrganization_ParentID
  ON
    [o].[ParentID] = mjBizAppsCommonOrganization_ParentID.[ID]
OUTER APPLY
    [${flyway:defaultSchema}_BizAppsCommon].[fnOrganizationParentID_GetRootID]([o].[ID], [o].[ParentID]) AS root_ParentID
GO
GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizations] TO [cdp_UI], [cdp_Developer], [cdp_Integration]
    

/* Base View Permissions SQL for Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Organizations
-- Item: Permissions for vwOrganizations
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizations] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Organizations
-- Item: spCreateOrganization
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Organization
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spCreateOrganization]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateOrganization];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateOrganization]
    @ID uniqueidentifier = NULL,
    @Name nvarchar(255),
    @LegalName nvarchar(255),
    @OrganizationTypeID uniqueidentifier,
    @ParentID uniqueidentifier,
    @Website nvarchar(1000),
    @LogoURL nvarchar(1000),
    @Description nvarchar(MAX),
    @Email nvarchar(255),
    @Phone nvarchar(50),
    @FoundedDate date,
    @TaxID nvarchar(50),
    @Status nvarchar(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)
    
    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[Organization]
            (
                [ID],
                [Name],
                [LegalName],
                [OrganizationTypeID],
                [ParentID],
                [Website],
                [LogoURL],
                [Description],
                [Email],
                [Phone],
                [FoundedDate],
                [TaxID],
                [Status]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Name,
                @LegalName,
                @OrganizationTypeID,
                @ParentID,
                @Website,
                @LogoURL,
                @Description,
                @Email,
                @Phone,
                @FoundedDate,
                @TaxID,
                ISNULL(@Status, 'Active')
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[Organization]
            (
                [Name],
                [LegalName],
                [OrganizationTypeID],
                [ParentID],
                [Website],
                [LogoURL],
                [Description],
                [Email],
                [Phone],
                [FoundedDate],
                [TaxID],
                [Status]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                @LegalName,
                @OrganizationTypeID,
                @ParentID,
                @Website,
                @LogoURL,
                @Description,
                @Email,
                @Phone,
                @FoundedDate,
                @TaxID,
                ISNULL(@Status, 'Active')
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizations] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateOrganization] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for Common: Organizations */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateOrganization] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Organizations
-- Item: spUpdateOrganization
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Organization
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spUpdateOrganization]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateOrganization];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateOrganization]
    @ID uniqueidentifier,
    @Name nvarchar(255),
    @LegalName nvarchar(255),
    @OrganizationTypeID uniqueidentifier,
    @ParentID uniqueidentifier,
    @Website nvarchar(1000),
    @LogoURL nvarchar(1000),
    @Description nvarchar(MAX),
    @Email nvarchar(255),
    @Phone nvarchar(50),
    @FoundedDate date,
    @TaxID nvarchar(50),
    @Status nvarchar(50)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[Organization]
    SET
        [Name] = @Name,
        [LegalName] = @LegalName,
        [OrganizationTypeID] = @OrganizationTypeID,
        [ParentID] = @ParentID,
        [Website] = @Website,
        [LogoURL] = @LogoURL,
        [Description] = @Description,
        [Email] = @Email,
        [Phone] = @Phone,
        [FoundedDate] = @FoundedDate,
        [TaxID] = @TaxID,
        [Status] = @Status
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizations] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizations]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateOrganization] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Organization table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[trgUpdateOrganization]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}_BizAppsCommon].[trgUpdateOrganization];
GO
CREATE TRIGGER [${flyway:defaultSchema}_BizAppsCommon].trgUpdateOrganization
ON [${flyway:defaultSchema}_BizAppsCommon].[Organization]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[Organization]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}_BizAppsCommon].[Organization] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO
        

/* spUpdate Permissions for Common: Organizations */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateOrganization] TO [cdp_Developer], [cdp_Integration]



/* spDelete SQL for Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Organizations
-- Item: spDeleteOrganization
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Organization
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spDeleteOrganization]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteOrganization];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteOrganization]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}_BizAppsCommon].[Organization]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteOrganization] TO [cdp_Integration]
    

/* spDelete Permissions for Common: Organizations */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteOrganization] TO [cdp_Integration]



/* SQL text to update entity field related entity name field map for entity field ID CFFB2D6A-96BD-4548-82B2-A344D0F4DF89 */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='CFFB2D6A-96BD-4548-82B2-A344D0F4DF89',
         @RelatedEntityNameFieldMap='ToOrganization'

/* Base View SQL for Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Relationships
-- Item: vwRelationships
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      Common: Relationships
-----               SCHEMA:      ${flyway:defaultSchema}_BizAppsCommon
-----               BASE TABLE:  Relationship
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[vwRelationships]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwRelationships];
GO

CREATE VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwRelationships]
AS
SELECT
    r.*,
    mjBizAppsCommonRelationshipType_RelationshipTypeID.[Name] AS [RelationshipType],
    mjBizAppsCommonOrganization_FromOrganizationID.[Name] AS [FromOrganization],
    mjBizAppsCommonOrganization_ToOrganizationID.[Name] AS [ToOrganization]
FROM
    [${flyway:defaultSchema}_BizAppsCommon].[Relationship] AS r
INNER JOIN
    [${flyway:defaultSchema}_BizAppsCommon].[RelationshipType] AS mjBizAppsCommonRelationshipType_RelationshipTypeID
  ON
    [r].[RelationshipTypeID] = mjBizAppsCommonRelationshipType_RelationshipTypeID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}_BizAppsCommon].[Organization] AS mjBizAppsCommonOrganization_FromOrganizationID
  ON
    [r].[FromOrganizationID] = mjBizAppsCommonOrganization_FromOrganizationID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}_BizAppsCommon].[Organization] AS mjBizAppsCommonOrganization_ToOrganizationID
  ON
    [r].[ToOrganizationID] = mjBizAppsCommonOrganization_ToOrganizationID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwRelationships] TO [cdp_UI], [cdp_Developer], [cdp_Integration]
    

/* Base View Permissions SQL for Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Relationships
-- Item: Permissions for vwRelationships
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwRelationships] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Relationships
-- Item: spCreateRelationship
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Relationship
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spCreateRelationship]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateRelationship];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateRelationship]
    @ID uniqueidentifier = NULL,
    @RelationshipTypeID uniqueidentifier,
    @FromPersonID uniqueidentifier,
    @FromOrganizationID uniqueidentifier,
    @ToPersonID uniqueidentifier,
    @ToOrganizationID uniqueidentifier,
    @Title nvarchar(255),
    @StartDate date,
    @EndDate date,
    @Status nvarchar(50) = NULL,
    @Notes nvarchar(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)
    
    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[Relationship]
            (
                [ID],
                [RelationshipTypeID],
                [FromPersonID],
                [FromOrganizationID],
                [ToPersonID],
                [ToOrganizationID],
                [Title],
                [StartDate],
                [EndDate],
                [Status],
                [Notes]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @RelationshipTypeID,
                @FromPersonID,
                @FromOrganizationID,
                @ToPersonID,
                @ToOrganizationID,
                @Title,
                @StartDate,
                @EndDate,
                ISNULL(@Status, 'Active'),
                @Notes
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[Relationship]
            (
                [RelationshipTypeID],
                [FromPersonID],
                [FromOrganizationID],
                [ToPersonID],
                [ToOrganizationID],
                [Title],
                [StartDate],
                [EndDate],
                [Status],
                [Notes]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @RelationshipTypeID,
                @FromPersonID,
                @FromOrganizationID,
                @ToPersonID,
                @ToOrganizationID,
                @Title,
                @StartDate,
                @EndDate,
                ISNULL(@Status, 'Active'),
                @Notes
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwRelationships] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateRelationship] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for Common: Relationships */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateRelationship] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Relationships
-- Item: spUpdateRelationship
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Relationship
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spUpdateRelationship]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateRelationship];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateRelationship]
    @ID uniqueidentifier,
    @RelationshipTypeID uniqueidentifier,
    @FromPersonID uniqueidentifier,
    @FromOrganizationID uniqueidentifier,
    @ToPersonID uniqueidentifier,
    @ToOrganizationID uniqueidentifier,
    @Title nvarchar(255),
    @StartDate date,
    @EndDate date,
    @Status nvarchar(50),
    @Notes nvarchar(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[Relationship]
    SET
        [RelationshipTypeID] = @RelationshipTypeID,
        [FromPersonID] = @FromPersonID,
        [FromOrganizationID] = @FromOrganizationID,
        [ToPersonID] = @ToPersonID,
        [ToOrganizationID] = @ToOrganizationID,
        [Title] = @Title,
        [StartDate] = @StartDate,
        [EndDate] = @EndDate,
        [Status] = @Status,
        [Notes] = @Notes
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwRelationships] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}_BizAppsCommon].[vwRelationships]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateRelationship] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Relationship table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[trgUpdateRelationship]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}_BizAppsCommon].[trgUpdateRelationship];
GO
CREATE TRIGGER [${flyway:defaultSchema}_BizAppsCommon].trgUpdateRelationship
ON [${flyway:defaultSchema}_BizAppsCommon].[Relationship]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[Relationship]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}_BizAppsCommon].[Relationship] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO
        

/* spUpdate Permissions for Common: Relationships */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateRelationship] TO [cdp_Developer], [cdp_Integration]



/* spDelete SQL for Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: Common: Relationships
-- Item: spDeleteRelationship
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Relationship
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spDeleteRelationship]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteRelationship];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteRelationship]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}_BizAppsCommon].[Relationship]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteRelationship] TO [cdp_Integration]
    

/* spDelete Permissions for Common: Relationships */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteRelationship] TO [cdp_Integration]



/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'f3b09f69-8011-4432-9c00-eb25b7105552'  OR 
               (EntityID = '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD' AND Name = 'Entity')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'f3b09f69-8011-4432-9c00-eb25b7105552',
            '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD', -- Entity: Common: Address Links
            100019,
            'Entity',
            'Entity',
            NULL,
            'nvarchar',
            510,
            0,
            0,
            0,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '3f5652f9-ecdd-4150-9d86-9cf42b2bc70a'  OR 
               (EntityID = '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD' AND Name = 'AddressType')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '3f5652f9-ecdd-4150-9d86-9cf42b2bc70a',
            '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD', -- Entity: Common: Address Links
            100020,
            'AddressType',
            'Address Type',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            0,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'cbc69adf-fa7d-49bb-8381-a865e1835ecf'  OR 
               (EntityID = '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB' AND Name = 'RelationshipType')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'cbc69adf-fa7d-49bb-8381-a865e1835ecf',
            '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', -- Entity: Common: Relationships
            100027,
            'RelationshipType',
            'Relationship Type',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            0,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '38964da0-3d90-40de-907b-9cf0dff7d28d'  OR 
               (EntityID = '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB' AND Name = 'FromOrganization')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '38964da0-3d90-40de-907b-9cf0dff7d28d',
            '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', -- Entity: Common: Relationships
            100028,
            'FromOrganization',
            'From Organization',
            NULL,
            'nvarchar',
            510,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '7832fc96-8f92-4741-8db9-a294e60de30b'  OR 
               (EntityID = '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB' AND Name = 'ToOrganization')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '7832fc96-8f92-4741-8db9-a294e60de30b',
            '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', -- Entity: Common: Relationships
            100029,
            'ToOrganization',
            'To Organization',
            NULL,
            'nvarchar',
            510,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'c48b0fee-c836-4bb3-8420-16566930fa4b'  OR 
               (EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD' AND Name = 'OrganizationType')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'c48b0fee-c836-4bb3-8420-16566930fa4b',
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', -- Entity: Common: Organizations
            100031,
            'OrganizationType',
            'Organization Type',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'e20d4075-a743-4ce0-90d0-d69e62e9636b'  OR 
               (EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD' AND Name = 'Parent')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'e20d4075-a743-4ce0-90d0-d69e62e9636b',
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', -- Entity: Common: Organizations
            100032,
            'Parent',
            'Parent',
            NULL,
            'nvarchar',
            510,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '74ed75bd-8b3d-45b4-8f7c-f4d8e249a032'  OR 
               (EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD' AND Name = 'RootParentID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '74ed75bd-8b3d-45b4-8f7c-f4d8e249a032',
            '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', -- Entity: Common: Organizations
            100033,
            'RootParentID',
            'Root Parent ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'e9a06e3f-8fb4-4477-aa70-8772710d15ef'  OR 
               (EntityID = 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA' AND Name = 'Organization')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'e9a06e3f-8fb4-4477-aa70-8772710d15ef',
            'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA', -- Entity: Common: Contact Methods
            100019,
            'Organization',
            'Organization',
            NULL,
            'nvarchar',
            510,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '9f1c52a9-52cc-4e28-89e6-506a3c461a23'  OR 
               (EntityID = 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA' AND Name = 'ContactType')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '9f1c52a9-52cc-4e28-89e6-506a3c461a23',
            'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA', -- Entity: Common: Contact Methods
            100020,
            'ContactType',
            'Contact Type',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            0,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'fcaa14f7-23bd-41c0-bbb0-b9655ecfc0ac'  OR 
               (EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65' AND Name = 'LinkedUser')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'fcaa14f7-23bd-41c0-bbb0-b9655ecfc0ac',
            'A3CB56E8-38B9-4456-BD88-F5E69E219D65', -- Entity: Common: People
            100037,
            'LinkedUser',
            'Linked User',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* Set field properties for entity */

            UPDATE [${flyway:defaultSchema}].EntityField
            SET IsNameField = 1
            WHERE ID = '67BDB609-9120-4E5D-826D-D2536D3CE054'
            AND AutoUpdateIsNameField = 1
         

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '67BDB609-9120-4E5D-826D-D2536D3CE054'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '1EC1DC9D-2630-4AE3-92DE-49B4F15F28BC'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '150D68AD-0E84-42EB-8B49-F977DF4A92AB'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '64328A12-E707-45FC-AED0-0149F0A584B9'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '174FD558-FFB0-4499-8586-ADA3511A4E39'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '67BDB609-9120-4E5D-826D-D2536D3CE054'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'A6B583AC-755F-4489-A79F-3E1A200BAFFC'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '1EC1DC9D-2630-4AE3-92DE-49B4F15F28BC'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '150D68AD-0E84-42EB-8B49-F977DF4A92AB'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '64328A12-E707-45FC-AED0-0149F0A584B9'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set field properties for entity */

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'D5CBC8C6-0351-4AD2-8DB8-22EFED381292'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '40359756-9750-41EC-8558-B9A87850F884'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'D5CBC8C6-0351-4AD2-8DB8-22EFED381292'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set field properties for entity */

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '075337AA-E0AF-45A5-8DE2-70764CD154D6'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '96F82CB6-0432-45C4-8449-AF29288A372B'
               AND AutoUpdateDefaultInView = 1
            

/* Set field properties for entity */

            UPDATE [${flyway:defaultSchema}].EntityField
            SET IsNameField = 1
            WHERE ID = 'EEDED48B-3219-4F5C-86B8-7FD7865041B5'
            AND AutoUpdateIsNameField = 1
         

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'EEDED48B-3219-4F5C-86B8-7FD7865041B5'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'BBF473E7-86CC-407D-844D-FFD044B468D6'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '3E918E15-CF7F-4141-BD82-87341BE4206C'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '9F1C52A9-52CC-4E28-89E6-506A3C461A23'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'EEDED48B-3219-4F5C-86B8-7FD7865041B5'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'BBF473E7-86CC-407D-844D-FFD044B468D6'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'E9A06E3F-8FB4-4477-AA70-8772710D15EF'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '9F1C52A9-52CC-4E28-89E6-506A3C461A23'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set field properties for entity */

            UPDATE [${flyway:defaultSchema}].EntityField
            SET IsNameField = 1
            WHERE ID = '3F5652F9-ECDD-4150-9D86-9CF42B2BC70A'
            AND AutoUpdateIsNameField = 1
         

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '4FC0F14D-3D67-412D-B93D-2944B9DD06B1'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'CDCBE6CE-9644-4387-83FD-DD5D9D653665'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'A679CD5B-CCE9-4B4F-BA52-E9189C78E43D'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'F3B09F69-8011-4432-9C00-EB25B7105552'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '3F5652F9-ECDD-4150-9D86-9CF42B2BC70A'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '4FC0F14D-3D67-412D-B93D-2944B9DD06B1'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'F3B09F69-8011-4432-9C00-EB25B7105552'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '3F5652F9-ECDD-4150-9D86-9CF42B2BC70A'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set categories for 6 fields */

-- UPDATE Entity Field Category Info Common: Address Types.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '621FC111-0D6C-483D-B53C-1A5AD69865B2' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Address Types.Name 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Type Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'EE25AF1D-0B36-426F-9006-76007868A0A4' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Address Types.Description 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Type Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '075337AA-E0AF-45A5-8DE2-70764CD154D6' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Address Types.DefaultRank 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Type Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '96F82CB6-0432-45C4-8449-AF29288A372B' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Address Types.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '40DAE327-885C-47B6-892D-6A1A160E32B2' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Address Types.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '2E8428CA-21D5-4CAA-AE2A-AE3783D8CB39' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-tags */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-tags', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = '66FA272F-59BB-4105-A1F3-4E5D4D63F381'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('43799fd7-3ee0-4ef9-b20b-631c8b1839ea', '66FA272F-59BB-4105-A1F3-4E5D4D63F381', 'FieldCategoryInfo', '{"Address Type Details":{"icon":"fa fa-address-book","description":"Configuration for address categories including naming and display priority"},"System Metadata":{"icon":"fa fa-database","description":"System-managed audit fields and unique identifiers"}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('01fdf8bc-8eea-4a79-bdf5-f007ebada4ec', '66FA272F-59BB-4105-A1F3-4E5D4D63F381', 'FieldCategoryIcons', '{"Address Type Details":"fa fa-address-book","System Metadata":"fa fa-database"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=0 for NEW entity (category: reference, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 0, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = '66FA272F-59BB-4105-A1F3-4E5D4D63F381'
      

/* Set categories for 6 fields */

-- UPDATE Entity Field Category Info Common: Contact Types.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8A5238FF-1427-4868-9E70-27223709AAD4' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Contact Types.Name 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Type Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'AF7D302B-8340-4EA7-BBF3-22C04F63333C' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Contact Types.Description 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Type Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D5CBC8C6-0351-4AD2-8DB8-22EFED381292' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Contact Types.IconClass 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Type Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '40359756-9750-41EC-8558-B9A87850F884' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Contact Types.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '99DC79F5-9599-45D9-B867-1AB3D029F2A8' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Contact Types.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'FD6A186C-1A0B-46B5-9020-DD50E850C41F' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-address-book */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-address-book', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = 'D17353E5-1FB0-4940-8D91-3E4007549200'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('f0482151-a366-4a4b-9b24-896291d8ee3c', 'D17353E5-1FB0-4940-8D91-3E4007549200', 'FieldCategoryInfo', '{"Contact Type Details":{"icon":"fa fa-id-card","description":"Basic information and visual configuration for contact method categories"},"System Metadata":{"icon":"fa fa-cog","description":"System-managed audit and tracking fields"}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('2811b294-3996-40bf-987a-689830392b89', 'D17353E5-1FB0-4940-8D91-3E4007549200', 'FieldCategoryIcons', '{"Contact Type Details":"fa fa-id-card","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=0 for NEW entity (category: reference, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 0, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = 'D17353E5-1FB0-4940-8D91-3E4007549200'
      

/* Set categories for 12 fields */

-- UPDATE Entity Field Category Info Common: Addresses.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'AE4F724D-AECE-4D56-945E-D5B5170F9222' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Addresses.Line1 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Street Address',
   GeneratedFormSection = 'Category',
   DisplayName = 'Address Line 1',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '67BDB609-9120-4E5D-826D-D2536D3CE054' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Addresses.Line2 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Street Address',
   GeneratedFormSection = 'Category',
   DisplayName = 'Address Line 2',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'A6B583AC-755F-4489-A79F-3E1A200BAFFC' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Addresses.Line3 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Street Address',
   GeneratedFormSection = 'Category',
   DisplayName = 'Address Line 3',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C3BF655F-A151-4297-BDB7-96CF0F22308A' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Addresses.City 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Locality and Region',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '1EC1DC9D-2630-4AE3-92DE-49B4F15F28BC' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Addresses.StateProvince 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Locality and Region',
   GeneratedFormSection = 'Category',
   DisplayName = 'State / Province',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '150D68AD-0E84-42EB-8B49-F977DF4A92AB' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Addresses.PostalCode 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Locality and Region',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '64328A12-E707-45FC-AED0-0149F0A584B9' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Addresses.Country 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Locality and Region',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '174FD558-FFB0-4499-8586-ADA3511A4E39' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Addresses.Latitude 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Geographic Location',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Geo',
   CodeType = NULL
WHERE 
   ID = '78E3EC5B-4F15-45CF-9D80-E1A0E0405A42' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Addresses.Longitude 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Geographic Location',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Geo',
   CodeType = NULL
WHERE 
   ID = '4200842E-A5D3-4C2C-85BB-E0C9699BB419' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Addresses.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7E8F1D7A-A42D-4944-9739-44ADB7E902D7' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Addresses.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '0CB3AD60-386A-4A43-8ACE-D692CDB39F1C' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-map-marked-alt */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-map-marked-alt', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = 'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('a55faf4b-fc0f-446e-a2d7-f1946e3eae05', 'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C', 'FieldCategoryInfo', '{"Street Address":{"icon":"fa fa-road","description":"Specific street-level location details including building and unit numbers"},"Locality and Region":{"icon":"fa fa-city","description":"Broader geographic identifiers including city, state, postal code, and country"},"Geographic Location":{"icon":"fa fa-globe-americas","description":"Precise GPS coordinates used for mapping and spatial analysis"},"System Metadata":{"icon":"fa fa-cog","description":"System-managed audit and tracking fields"}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('150c4065-a91d-4dd0-ba41-7ad9daf7eb39', 'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C', 'FieldCategoryIcons', '{"Street Address":"fa fa-road","Locality and Region":"fa fa-city","Geographic Location":"fa fa-globe-americas","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=0 for NEW entity (category: supporting, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 0, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = 'B59CCA6F-E48C-4DE5-A784-DB0DF9E2885C'
      

/* Set categories for 11 fields */

-- UPDATE Entity Field Category Info Common: Address Links.AddressID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Assignment',
   GeneratedFormSection = 'Category',
   DisplayName = 'Address',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D78A7C9E-A347-451A-8535-00EDB6AB4359' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Address Links.AddressType 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Assignment',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '3F5652F9-ECDD-4150-9D86-9CF42B2BC70A' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Address Links.AddressTypeID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Assignment',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '71E1C019-742D-422F-B412-D85757922ADB' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Address Links.IsPrimary 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Assignment',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'CDCBE6CE-9644-4387-83FD-DD5D9D653665' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Address Links.Rank 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Assignment',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'A679CD5B-CCE9-4B4F-BA52-E9189C78E43D' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Address Links.Entity 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Linked Record Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Entity Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'F3B09F69-8011-4432-9C00-EB25B7105552' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Address Links.EntityID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Linked Record Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'CFCBE12E-5B60-44C1-BDF9-F672294778FB' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Address Links.RecordID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Linked Record Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '4FC0F14D-3D67-412D-B93D-2944B9DD06B1' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Address Links.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '68DAB59E-CA4C-4C79-9AB8-32ED9BA29B3E' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Address Links.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '81398F0E-7AEF-40A2-8DCD-3504D4D2779A' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Address Links.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '4E1DC335-24A5-4940-B511-C5C1B8369DC2' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-link */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-link', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('bc1e8289-b541-417d-9586-5981b2838d95', '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD', 'FieldCategoryInfo', '{"Address Assignment":{"icon":"fa fa-map-marker-alt","description":"Configuration for the specific address link, including its type and priority."},"Linked Record Details":{"icon":"fa fa-database","description":"Information identifying the specific system record this address is associated with."},"System Metadata":{"icon":"fa fa-cog","description":"System-managed identifiers and audit timestamps for the link record."}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('5ed7a139-f64c-47c3-a27b-2d998a470196', '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD', 'FieldCategoryIcons', '{"Address Assignment":"fa fa-map-marker-alt","Linked Record Details":"fa fa-database","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=0 for NEW entity (category: junction, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 0, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = '8E6D93FA-4768-4672-8A5C-35DCAD34C9BD'
      

/* Set categories for 11 fields */

-- UPDATE Entity Field Category Info Common: Contact Methods.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B2E878A1-C0E8-450D-8525-732CA54589A3' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Contact Methods.PersonID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Linked Records',
   GeneratedFormSection = 'Category',
   DisplayName = 'Person',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '4781A91C-0F0B-40BF-B4DD-C95611B821F1' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Contact Methods.OrganizationID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Linked Records',
   GeneratedFormSection = 'Category',
   DisplayName = 'Organization',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '203C3260-2DF9-4478-B639-D0401AC0AC28' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Contact Methods.Organization 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Linked Records',
   GeneratedFormSection = 'Category',
   DisplayName = 'Organization Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E9A06E3F-8FB4-4477-AA70-8772710D15EF' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Contact Methods.ContactTypeID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Contact Type',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '0B306E5D-0024-471A-9E43-5293C57D4759' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Contact Methods.ContactType 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Contact Type Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '9F1C52A9-52CC-4E28-89E6-506A3C461A23' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Contact Methods.Value 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Contact Value',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'EEDED48B-3219-4F5C-86B8-7FD7865041B5' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Contact Methods.Label 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'BBF473E7-86CC-407D-844D-FFD044B468D6' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Contact Methods.IsPrimary 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '3E918E15-CF7F-4141-BD82-87341BE4206C' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Contact Methods.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '89AA9C83-7EF0-42E8-A019-0791FC956EBC' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Contact Methods.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '3553478F-F6BA-4C1E-A5DB-91A7F3A3E11E' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-address-book */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-address-book', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('e53cca14-6eea-487f-be40-38cc4caf5f6c', 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA', 'FieldCategoryInfo', '{"Contact Details":{"icon":"fa fa-id-card","description":"Core information about the contact method including its type, value, and priority."},"Linked Records":{"icon":"fa fa-link","description":"Information about the person or organization associated with this contact method."},"System Metadata":{"icon":"fa fa-cog","description":"System-managed audit and tracking fields."}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('af7a90a1-e7e9-4f08-a738-fdf6b60ba73a', 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA', 'FieldCategoryIcons', '{"Contact Details":"fa fa-id-card","Linked Records":"fa fa-link","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=0 for NEW entity (category: supporting, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 0, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA'
      

/* Set field properties for entity */

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'DAA78DA8-7A01-4ADA-B992-C9518D4ABC7A'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '5ED84866-8B7B-42C5-912E-80FDAC5B4D1F'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'C48B0FEE-C836-4BB3-8420-16566930FA4B'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'E20D4075-A743-4CE0-90D0-D69E62E9636B'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '4A6C3B90-A1DC-48B6-8268-7170539663A9'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '0B217D86-FA43-4C64-BCE7-FF4FABDDAA6D'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'DAA78DA8-7A01-4ADA-B992-C9518D4ABC7A'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '598BF53A-74AB-4D88-9087-FEFE711A0784'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'C9DEFEA8-649D-46EF-8AD5-67CE6F8365CE'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set field properties for entity */

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'DC1550D3-7488-4CCE-A291-8623ECE507F1'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '48E12BDE-31F1-4AA8-822E-EF3520612691'
               AND AutoUpdateDefaultInView = 1
            

/* Set field properties for entity */

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '722C3E0D-AB64-4276-B53D-CA77C54143CF'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'C97E3D06-0D30-44F3-B692-45A4125BC66E'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '80F81755-7E41-44C8-A429-AC94E5CE7689'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '722C3E0D-AB64-4276-B53D-CA77C54143CF'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'C97E3D06-0D30-44F3-B692-45A4125BC66E'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '80F81755-7E41-44C8-A429-AC94E5CE7689'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set field properties for entity */

            UPDATE [${flyway:defaultSchema}].EntityField
            SET IsNameField = 1
            WHERE ID = 'FCDCECC5-509B-4A56-A7E6-7A9BBEBBEBEC'
            AND AutoUpdateIsNameField = 1
         

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'C36F71AB-A12A-466B-91CE-D3B3C466F277'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'FCDCECC5-509B-4A56-A7E6-7A9BBEBBEBEC'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '39C0D8A8-099B-4427-8921-8BB4E766EA47'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '8F92F420-E2B8-4EA9-8AEF-EFD6D5B41607'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'C64968CB-CC40-403A-A02B-E245FE564172'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'C36F71AB-A12A-466B-91CE-D3B3C466F277'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'FCDCECC5-509B-4A56-A7E6-7A9BBEBBEBEC'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '1D5F5717-709D-4934-A749-11FE56A2BBBB'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '61021226-3FCC-468D-828A-D4C6B01D6200'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '39C0D8A8-099B-4427-8921-8BB4E766EA47'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '8F92F420-E2B8-4EA9-8AEF-EFD6D5B41607'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '886CCD64-5654-4095-9E8E-345951B0DB65'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'FCAA14F7-23BD-41C0-BBB0-B9655ECFC0AC'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set categories for 6 fields */

-- UPDATE Entity Field Category Info Common: Organization Types.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '53E42417-862D-4A5F-AAD2-32B83853313B' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organization Types.Name 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Type Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'BB0E133C-34DE-442E-A6BE-26006CCE426A' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organization Types.Description 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Type Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'DC1550D3-7488-4CCE-A291-8623ECE507F1' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organization Types.IconClass 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Type Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '48E12BDE-31F1-4AA8-822E-EF3520612691' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organization Types.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8AD9E989-C6B1-4CA3-85E5-3D625B7C8812' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organization Types.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'F8A490DB-1A16-401D-A33A-A3213D95EE3D' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-building */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-building', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = '0AB066C1-8FE5-4363-86E6-BEF80975205C'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('c59873fa-e72d-4132-b792-ad49e243bcb1', '0AB066C1-8FE5-4363-86E6-BEF80975205C', 'FieldCategoryInfo', '{"Type Configuration":{"icon":"fa fa-list-ul","description":"Core attributes defining the organization type and its visual display in the application."},"System Metadata":{"icon":"fa fa-cog","description":"Internal system identifiers and audit tracking timestamps."}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('1eea04e7-d542-4a4c-b9a9-d6bb14a8da2d', '0AB066C1-8FE5-4363-86E6-BEF80975205C', 'FieldCategoryIcons', '{"Type Configuration":"fa fa-list-ul","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=0 for NEW entity (category: reference, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 0, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = '0AB066C1-8FE5-4363-86E6-BEF80975205C'
      

/* Set categories for 9 fields */

-- UPDATE Entity Field Category Info Common: Relationship Types.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B6A2C73F-6D40-45F9-AF82-52DD3D29C6FB' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationship Types.Name 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Definition',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'FDA58326-2507-4F14-9143-D17758D1B999' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationship Types.Description 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Definition',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E351F0D1-98D9-449E-9C0A-6D43D5B4D390' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationship Types.Category 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Definition',
   GeneratedFormSection = 'Category',
   DisplayName = 'Connection Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '722C3E0D-AB64-4276-B53D-CA77C54143CF' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationship Types.IsDirectional 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Directional Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D4EA503E-413F-4809-9969-A69E1DF8261B' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationship Types.ForwardLabel 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Directional Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C97E3D06-0D30-44F3-B692-45A4125BC66E' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationship Types.ReverseLabel 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Directional Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '80F81755-7E41-44C8-A429-AC94E5CE7689' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationship Types.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8AEB1280-B915-4E5E-A5EE-F641D20378A4' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationship Types.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'A40DAFE1-4AA7-40E5-A0BE-8A32B5EE8012' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-project-diagram */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-project-diagram', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('2175fda0-7bd8-41bd-a14c-5a5bd9ec464c', '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB', 'FieldCategoryInfo', '{"Relationship Definition":{"icon":"fa fa-tag","description":"Basic properties and classification of the relationship type"},"Directional Configuration":{"icon":"fa fa-exchange-alt","description":"Settings for relationship symmetry and directional display labels"},"System Metadata":{"icon":"fa fa-cog","description":"System-managed audit and tracking fields"}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('61b0daac-ca07-4d2d-8cd2-cf93951ddcc9', '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB', 'FieldCategoryIcons', '{"Relationship Definition":"fa fa-tag","Directional Configuration":"fa fa-exchange-alt","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=0 for NEW entity (category: reference, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 0, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = '7BFA6AAF-C89F-41D6-BAD5-737644ABEDCB'
      

/* Set field properties for entity */

            UPDATE [${flyway:defaultSchema}].EntityField
            SET IsNameField = 1
            WHERE ID = '41798D66-072D-4F85-9D13-51C754F165C5'
            AND AutoUpdateIsNameField = 1
         

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '41798D66-072D-4F85-9D13-51C754F165C5'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '854946A7-EF5B-4818-8AFB-CD99B5E313E8'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '228F924E-DB74-41E4-8D20-942D899C03D6'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'CBC69ADF-FA7D-49BB-8381-A865E1835ECF'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '38964DA0-3D90-40DE-907B-9CF0DFF7D28D'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '7832FC96-8F92-4741-8DB9-A294E60DE30B'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '41798D66-072D-4F85-9D13-51C754F165C5'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '228F924E-DB74-41E4-8D20-942D899C03D6'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'CBC69ADF-FA7D-49BB-8381-A865E1835ECF'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '38964DA0-3D90-40DE-907B-9CF0DFF7D28D'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '7832FC96-8F92-4741-8DB9-A294E60DE30B'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set categories for 18 fields */

-- UPDATE Entity Field Category Info Common: Organizations.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7C6E93C3-E124-46BB-A0F5-1DA136396AFD' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organizations.Name 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '3BB45A32-8836-4868-9408-44101F79DA8D' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organizations.LegalName 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '4A6C3B90-A1DC-48B6-8268-7170539663A9' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organizations.OrganizationTypeID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Organization Type',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '0902C7F8-4D7F-40EA-BAA6-A6C36B22FEA5' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organizations.OrganizationType 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Organization Type Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C48B0FEE-C836-4BB3-8420-16566930FA4B' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organizations.Status 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '5ED84866-8B7B-42C5-912E-80FDAC5B4D1F' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organizations.FoundedDate 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '24F6C30C-AE49-4F55-BBB1-E9ABF12AF0DB' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organizations.TaxID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C9DEFEA8-649D-46EF-8AD5-67CE6F8365CE' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organizations.Description 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '83410A49-636C-4540-88F5-7AC573E0FC39' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organizations.Website 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact and Online Presence',
   GeneratedFormSection = 'Category',
   ExtendedType = 'URL',
   CodeType = NULL
WHERE 
   ID = '0B217D86-FA43-4C64-BCE7-FF4FABDDAA6D' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organizations.LogoURL 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact and Online Presence',
   GeneratedFormSection = 'Category',
   ExtendedType = 'URL',
   CodeType = NULL
WHERE 
   ID = '31300B38-C784-4E2A-A7CF-1F18CED9C458' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organizations.Email 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact and Online Presence',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Email',
   CodeType = NULL
WHERE 
   ID = 'DAA78DA8-7A01-4ADA-B992-C9518D4ABC7A' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organizations.Phone 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact and Online Presence',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Tel',
   CodeType = NULL
WHERE 
   ID = '598BF53A-74AB-4D88-9087-FEFE711A0784' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organizations.ParentID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Hierarchy and Structure',
   GeneratedFormSection = 'Category',
   DisplayName = 'Parent Organization',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7A4A63E0-651D-4127-932A-C3D2EC1F24C6' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organizations.Parent 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Hierarchy and Structure',
   GeneratedFormSection = 'Category',
   DisplayName = 'Parent Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E20D4075-A743-4CE0-90D0-D69E62E9636B' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organizations.RootParentID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Hierarchy and Structure',
   GeneratedFormSection = 'Category',
   DisplayName = 'Root Parent',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '74ED75BD-8B3D-45B4-8F7C-F4D8E249A032' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organizations.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '3F12CF81-8BF2-4F9F-8E77-DE9819DCB251' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Organizations.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'AC571288-2D4B-431D-97CA-7328BF50404F' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-building */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-building', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('aa5b3614-5f5a-411e-b80b-e610929c93d9', '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', 'FieldCategoryInfo', '{"Organization Details":{"icon":"fa fa-id-card","description":"Core identity information, classification, and legal identification for the organization"},"Contact and Online Presence":{"icon":"fa fa-address-book","description":"Communication channels and digital branding information"},"Hierarchy and Structure":{"icon":"fa fa-sitemap","description":"Information regarding the organization''s position within a corporate or structural hierarchy"},"System Metadata":{"icon":"fa fa-cog","description":"Internal system identifiers and audit timestamps"}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('f1d3e6ac-263a-41c5-a40c-c31ecae13c59', '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD', 'FieldCategoryIcons', '{"Organization Details":"fa fa-id-card","Contact and Online Presence":"fa fa-address-book","Hierarchy and Structure":"fa fa-sitemap","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=1 for NEW entity (category: primary, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 1, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = '74DEFEF0-A5F5-41D6-9B63-8A07F706ABFD'
      

/* Set categories for 19 fields */

-- UPDATE Entity Field Category Info Common: People.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D0B95EA1-8F6A-42F7-8A57-0509760535C4' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: People.FirstName 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Identity & Profile',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C36F71AB-A12A-466B-91CE-D3B3C466F277' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: People.LastName 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Identity & Profile',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'FCDCECC5-509B-4A56-A7E6-7A9BBEBBEBEC' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: People.MiddleName 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Identity & Profile',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '1D5F5717-709D-4934-A749-11FE56A2BBBB' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: People.Prefix 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Identity & Profile',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'CF1E51AF-191B-47E7-BC44-3A6C705AC739' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: People.Suffix 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Identity & Profile',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E6687162-799A-4BB3-A5BE-54EB87E22E83' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: People.PreferredName 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Identity & Profile',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '61021226-3FCC-468D-828A-D4C6B01D6200' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: People.DateOfBirth 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Identity & Profile',
   GeneratedFormSection = 'Category',
   DisplayName = 'Date of Birth',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '05D10617-2FA9-40FF-B9E4-59B6AAC4ACBE' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: People.Gender 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Identity & Profile',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '6354A8E3-2AD5-4FBF-BC44-321AEE5C669F' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: People.PhotoURL 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Identity & Profile',
   GeneratedFormSection = 'Category',
   ExtendedType = 'URL',
   CodeType = NULL
WHERE 
   ID = 'A494BB71-2768-4024-B778-509AA1E8CB55' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: People.Bio 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Identity & Profile',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'F32F4925-BDD8-4F42-B2A8-8DAFEC07DE2F' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: People.Title 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact & Professional',
   GeneratedFormSection = 'Category',
   DisplayName = 'Professional Title',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '39C0D8A8-099B-4427-8921-8BB4E766EA47' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: People.Email 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact & Professional',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Email',
   CodeType = NULL
WHERE 
   ID = '8F92F420-E2B8-4EA9-8AEF-EFD6D5B41607' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: People.Phone 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact & Professional',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Tel',
   CodeType = NULL
WHERE 
   ID = '886CCD64-5654-4095-9E8E-345951B0DB65' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: People.Status 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Account Management',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C64968CB-CC40-403A-A02B-E245FE564172' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: People.LinkedUserID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Account Management',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7DFC3BF1-A07F-463E-845A-C934275BBFCF' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: People.LinkedUser 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Account Management',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'FCAA14F7-23BD-41C0-BBB0-B9655ECFC0AC' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: People.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E4076D06-6941-4562-95DE-EC544AA22861' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: People.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8A17598A-FFA8-4A10-8D14-0454D494457E' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-user */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-user', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('e442b6d0-7e30-4f2e-8983-350e189e0bdc', 'A3CB56E8-38B9-4456-BD88-F5E69E219D65', 'FieldCategoryInfo', '{"Identity & Profile":{"icon":"fa fa-id-card","description":"Personal details, names, demographics, and biographical information"},"Contact & Professional":{"icon":"fa fa-address-book","description":"Information on how to reach the person and their professional role"},"Account Management":{"icon":"fa fa-user-cog","description":"Record status and links to internal system user accounts"},"System Metadata":{"icon":"fa fa-database","description":"System-managed audit fields and technical identifiers"}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('41d3db9a-ba53-4a55-820b-01426b505f37', 'A3CB56E8-38B9-4456-BD88-F5E69E219D65', 'FieldCategoryIcons', '{"Identity & Profile":"fa fa-id-card","Contact & Professional":"fa fa-address-book","Account Management":"fa fa-user-cog","System Metadata":"fa fa-database"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=1 for NEW entity (category: primary, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 1, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = 'A3CB56E8-38B9-4456-BD88-F5E69E219D65'
      

/* Set categories for 16 fields */

-- UPDATE Entity Field Category Info Common: Relationships.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E1BF9E93-1F96-486F-B4E0-49D038159B5C' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationships.RelationshipTypeID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Relationship Type',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'EAAC9A59-CE53-43E4-B663-0CEFAF8300D0' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationships.RelationshipType 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Relationship Type Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'CBC69ADF-FA7D-49BB-8381-A865E1835ECF' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationships.Title 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '41798D66-072D-4F85-9D13-51C754F165C5' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationships.Status 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '228F924E-DB74-41E4-8D20-942D899C03D6' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationships.StartDate 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '854946A7-EF5B-4818-8AFB-CD99B5E313E8' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationships.EndDate 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7D0AE077-E5AB-4B21-93AA-3CB682BB906A' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationships.Notes 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '9929CC69-0349-4DCA-9F74-4B11CF31AD1A' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationships.FromPersonID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Participants',
   GeneratedFormSection = 'Category',
   DisplayName = 'From Person',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '874BA7FA-14C5-4277-9C83-FF2187D6F0E1' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationships.FromOrganizationID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Participants',
   GeneratedFormSection = 'Category',
   DisplayName = 'From Organization',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '12FBD8AF-5847-453D-B40E-3D740C04769D' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationships.FromOrganization 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Participants',
   GeneratedFormSection = 'Category',
   DisplayName = 'From Organization Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '38964DA0-3D90-40DE-907B-9CF0DFF7D28D' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationships.ToPersonID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Participants',
   GeneratedFormSection = 'Category',
   DisplayName = 'To Person',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'EB71A369-66C0-4C86-9B77-63A11BA01874' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationships.ToOrganizationID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Participants',
   GeneratedFormSection = 'Category',
   DisplayName = 'To Organization',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'CFFB2D6A-96BD-4548-82B2-A344D0F4DF89' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationships.ToOrganization 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Participants',
   GeneratedFormSection = 'Category',
   DisplayName = 'To Organization Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7832FC96-8F92-4741-8DB9-A294E60DE30B' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationships.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C4F00F0E-461C-4EAC-B70C-B7508F850000' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info Common: Relationships.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '531DAA90-2CBC-4AF9-91B3-A77205D4D4A1' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-project-diagram */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-project-diagram', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('59511a5f-6d5a-4e2e-a4eb-fa75a77cb5f2', '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', 'FieldCategoryInfo', '{"Relationship Details":{"icon":"fa fa-id-card","description":"Core attributes of the link including type, title, status, and effective dates"},"Participants":{"icon":"fa fa-users","description":"The people or organizations involved in this directional relationship"},"System Metadata":{"icon":"fa fa-cog","description":"System-managed identifiers and audit tracking information"}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('8077344a-6690-4b3a-b74c-3eefafb01237', '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB', 'FieldCategoryIcons', '{"Relationship Details":"fa fa-id-card","Participants":"fa fa-users","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=0 for NEW entity (category: supporting, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 0, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB'
      

/* Generated Validation Functions for Common: Contact Methods */
-- CHECK constraint for Common: Contact Methods @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
INSERT INTO [${flyway:defaultSchema}].[GeneratedCode] (CategoryID, GeneratedByModelID, GeneratedAt, Language, Status, Source, Code, Description, Name, LinkedEntityID, LinkedRecordPrimaryKey)
                      VALUES ((SELECT ID FROM ${flyway:defaultSchema}.vwGeneratedCodeCategories WHERE Name='CodeGen: Validators'), '7B31F48E-EDA3-47B4-9602-D98B7EB1AF45', GETUTCDATE(), 'TypeScript','Approved', '([PersonID] IS NOT NULL OR [OrganizationID] IS NOT NULL)', 'public ValidatePersonIDOrOrganizationIDNotNull(result: ValidationResult) {
	if (this.PersonID == null && this.OrganizationID == null) {
		result.Errors.push(new ValidationErrorInfo(
			"PersonID",
			"A contact record must be associated with either a person or an organization.",
			this.PersonID,
			ValidationErrorType.Failure
		));
	}
}', 'Each contact record must be linked to either a person or an organization to ensure the information is correctly assigned and not left orphaned.', 'ValidatePersonIDOrOrganizationIDNotNull', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', 'FA624CAD-3867-49DD-B9F8-BE3EF2C81FCA');
  
            

/* Generated Validation Functions for Common: Relationships */
-- CHECK constraint for Common: Relationships @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
INSERT INTO [${flyway:defaultSchema}].[GeneratedCode] (CategoryID, GeneratedByModelID, GeneratedAt, Language, Status, Source, Code, Description, Name, LinkedEntityID, LinkedRecordPrimaryKey)
                      VALUES ((SELECT ID FROM ${flyway:defaultSchema}.vwGeneratedCodeCategories WHERE Name='CodeGen: Validators'), '7B31F48E-EDA3-47B4-9602-D98B7EB1AF45', GETUTCDATE(), 'TypeScript','Approved', '([FromPersonID] IS NOT NULL AND [FromOrganizationID] IS NULL OR [FromPersonID] IS NULL AND [FromOrganizationID] IS NOT NULL)', 'public ValidateExclusiveFromPersonOrOrganization(result: ValidationResult) {
	if ((this.FromPersonID == null && this.FromOrganizationID == null) || (this.FromPersonID != null && this.FromOrganizationID != null)) {
		result.Errors.push(new ValidationErrorInfo(
			"FromPersonID",
			"A relationship must be linked to exactly one source: either a person or an organization.",
			this.FromPersonID,
			ValidationErrorType.Failure
		));
	}
}', 'A relationship must be associated with either a person or an organization as the source, but not both and not neither.', 'ValidateExclusiveFromPersonOrOrganization', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB');
  
            -- CHECK constraint for Common: Relationships @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
INSERT INTO [${flyway:defaultSchema}].[GeneratedCode] (CategoryID, GeneratedByModelID, GeneratedAt, Language, Status, Source, Code, Description, Name, LinkedEntityID, LinkedRecordPrimaryKey)
                      VALUES ((SELECT ID FROM ${flyway:defaultSchema}.vwGeneratedCodeCategories WHERE Name='CodeGen: Validators'), '7B31F48E-EDA3-47B4-9602-D98B7EB1AF45', GETUTCDATE(), 'TypeScript','Approved', '([ToPersonID] IS NOT NULL AND [ToOrganizationID] IS NULL OR [ToPersonID] IS NULL AND [ToOrganizationID] IS NOT NULL)', 'public ValidateToPersonOrToOrganization(result: ValidationResult) {
	// The constraint requires exactly one of ToPersonID or ToOrganizationID to be populated
	const hasToPerson = this.ToPersonID != null;
	const hasToOrganization = this.ToOrganizationID != null;

	if ((hasToPerson && hasToOrganization) || (!hasToPerson && !hasToOrganization)) {
		result.Errors.push(new ValidationErrorInfo(
			"ToPersonID",
			"A relationship must be associated with exactly one recipient: either a Person or an Organization.",
			this.ToPersonID,
			ValidationErrorType.Failure
		));
	}
}', 'Each relationship must be assigned to either a person or an organization. This ensures that the destination of the relationship is clearly defined and prevents records from being linked to both types of entities or neither.', 'ValidateToPersonOrToOrganization', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', '2C2B874F-0880-4DE7-A0BF-63B6C6AFE9EB');
  
            

