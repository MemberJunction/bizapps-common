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
    DisplayRank INT NOT NULL DEFAULT 100,
    IsActive BIT NOT NULL DEFAULT 1,
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
    IconClass NVARCHAR(100),
    DefaultRank INT NOT NULL DEFAULT 100,
    IsActive BIT NOT NULL DEFAULT 1,
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
    DisplayRank INT NOT NULL DEFAULT 100,
    IsActive BIT NOT NULL DEFAULT 1,
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
    IsActive BIT NOT NULL DEFAULT 1,
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
    CONSTRAINT CK_ContactMethod_Owner CHECK (
        (PersonID IS NOT NULL AND OrganizationID IS NULL) OR
        (PersonID IS NULL AND OrganizationID IS NOT NULL)
    )
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
-- INDEXES: Unique filtered index on Person.LinkedUserID
---------------------------------------------------------------------------
CREATE UNIQUE NONCLUSTERED INDEX UQ_Person_LinkedUserID
    ON __mj_BizAppsCommon.Person (LinkedUserID)
    WHERE LinkedUserID IS NOT NULL;
GO

---------------------------------------------------------------------------
-- INDEXES: Composite indexes for enriched view query performance
---------------------------------------------------------------------------
CREATE NONCLUSTERED INDEX IX_AddressLink_EntityRecord_Primary
    ON __mj_BizAppsCommon.AddressLink (EntityID, RecordID, IsPrimary)
    INCLUDE (AddressID, AddressTypeID);
GO

CREATE NONCLUSTERED INDEX IX_ContactMethod_Person_Type_Primary
    ON __mj_BizAppsCommon.ContactMethod (PersonID, ContactTypeID, IsPrimary)
    INCLUDE (Value)
    WHERE PersonID IS NOT NULL;
GO

CREATE NONCLUSTERED INDEX IX_ContactMethod_Organization_Type_Primary
    ON __mj_BizAppsCommon.ContactMethod (OrganizationID, ContactTypeID, IsPrimary)
    INCLUDE (Value)
    WHERE OrganizationID IS NOT NULL;
GO

CREATE NONCLUSTERED INDEX IX_Relationship_FromPerson_Type_Status
    ON __mj_BizAppsCommon.Relationship (FromPersonID, RelationshipTypeID, Status)
    INCLUDE (Title, ToOrganizationID, StartDate)
    WHERE FromPersonID IS NOT NULL;
GO

CREATE NONCLUSTERED INDEX IX_Relationship_ToOrganization_Status
    ON __mj_BizAppsCommon.Relationship (ToOrganizationID, Status)
    INCLUDE (RelationshipTypeID)
    WHERE ToOrganizationID IS NOT NULL;
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
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Sort order in dropdown lists. Lower values appear first',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'OrganizationType', @level2type = N'COLUMN', @level2name = N'DisplayRank';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'OrganizationType', @level2type = N'COLUMN', @level2name = N'IsActive';
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
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Font Awesome icon class for UI display',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'AddressType', @level2type = N'COLUMN', @level2name = N'IconClass';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Default sort order for this address type in dropdown lists. Lower values appear first. Can be overridden per-record via AddressLink.Rank',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'AddressType', @level2type = N'COLUMN', @level2name = N'DefaultRank';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'AddressType', @level2type = N'COLUMN', @level2name = N'IsActive';
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
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Sort order in dropdown lists. Lower values appear first',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'ContactType', @level2type = N'COLUMN', @level2name = N'DisplayRank';
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'ContactType', @level2type = N'COLUMN', @level2name = N'IsActive';
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
EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records',
    @level0type = N'SCHEMA', @level0name = N'__mj_BizAppsCommon', @level1type = N'TABLE', @level1name = N'RelationshipType', @level2type = N'COLUMN', @level2name = N'IsActive';
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

 





-- MANUAL UPDATE OF SCHEMA INFO from metadata file to ensure we have things set for the codegeneration
INSERT INTO __mj.SchemaInfo 
(
  ID,
  SchemaName,
  EntityIDMin, EntityIDMax,
  Comments,
  Description,
  EntityNamePrefix, EntityNameSuffix
)
VALUES
(
  '0A9F0FDD-CD4D-4892-BA45-85722B982032',
  '__mj_BizAppsCommon',
  1, 1000000,
  NULL,
  'MemberJunction: Common Business App Data',
  'MJ.BizApps.Common: ', NULL
)






















































-- CODE GEN RUN 
/* SQL generated to create new entity MJ.BizApps.Common: Organization Types */

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
         'a77d9725-4871-484b-99f0-f65461d7abee',
         'MJ.BizApps.Common: Organization Types',
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
   

/* SQL generated to create new application ${flyway:defaultSchema}_BizAppsCommon */
INSERT INTO [${flyway:defaultSchema}].Application (ID, Name, Description, SchemaAutoAddNewEntities, Path, AutoUpdatePath)
                       VALUES ('b479eb79-1260-40af-a5ea-f8aa0b71384f', '${flyway:defaultSchema}_BizAppsCommon', 'Generated for schema', '${flyway:defaultSchema}_BizAppsCommon', 'mjbizappscommon', 1)

/* SQL generated to add new entity MJ.BizApps.Common: Organization Types to application ID: 'b479eb79-1260-40af-a5ea-f8aa0b71384f' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('b479eb79-1260-40af-a5ea-f8aa0b71384f', 'a77d9725-4871-484b-99f0-f65461d7abee', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = 'b479eb79-1260-40af-a5ea-f8aa0b71384f'))

/* SQL generated to add new permission for entity MJ.BizApps.Common: Organization Types for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('a77d9725-4871-484b-99f0-f65461d7abee', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: Organization Types for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('a77d9725-4871-484b-99f0-f65461d7abee', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: Organization Types for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('a77d9725-4871-484b-99f0-f65461d7abee', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL generated to create new entity MJ.BizApps.Common: Address Types */

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
         '7a7245d1-2316-44a4-b147-a50ff19f5942',
         'MJ.BizApps.Common: Address Types',
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
   

/* SQL generated to add new entity MJ.BizApps.Common: Address Types to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '7a7245d1-2316-44a4-b147-a50ff19f5942', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'))

/* SQL generated to add new permission for entity MJ.BizApps.Common: Address Types for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('7a7245d1-2316-44a4-b147-a50ff19f5942', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: Address Types for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('7a7245d1-2316-44a4-b147-a50ff19f5942', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: Address Types for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('7a7245d1-2316-44a4-b147-a50ff19f5942', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL generated to create new entity MJ.BizApps.Common: Contact Types */

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
         '7355a5ef-b3be-4d6d-b48b-5f8fd76f97b5',
         'MJ.BizApps.Common: Contact Types',
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
   

/* SQL generated to add new entity MJ.BizApps.Common: Contact Types to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '7355a5ef-b3be-4d6d-b48b-5f8fd76f97b5', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'))

/* SQL generated to add new permission for entity MJ.BizApps.Common: Contact Types for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('7355a5ef-b3be-4d6d-b48b-5f8fd76f97b5', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: Contact Types for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('7355a5ef-b3be-4d6d-b48b-5f8fd76f97b5', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: Contact Types for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('7355a5ef-b3be-4d6d-b48b-5f8fd76f97b5', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL generated to create new entity MJ.BizApps.Common: Relationship Types */

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
         '5f214f43-109c-407d-b505-7b0b3b72acb5',
         'MJ.BizApps.Common: Relationship Types',
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
   

/* SQL generated to add new entity MJ.BizApps.Common: Relationship Types to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '5f214f43-109c-407d-b505-7b0b3b72acb5', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'))

/* SQL generated to add new permission for entity MJ.BizApps.Common: Relationship Types for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('5f214f43-109c-407d-b505-7b0b3b72acb5', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: Relationship Types for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('5f214f43-109c-407d-b505-7b0b3b72acb5', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: Relationship Types for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('5f214f43-109c-407d-b505-7b0b3b72acb5', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL generated to create new entity MJ.BizApps.Common: People */

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
         '7a94ada9-7880-4fae-97d8-db0e934c3f5f',
         'MJ.BizApps.Common: People',
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
   

/* SQL generated to add new entity MJ.BizApps.Common: People to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '7a94ada9-7880-4fae-97d8-db0e934c3f5f', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'))

/* SQL generated to add new permission for entity MJ.BizApps.Common: People for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('7a94ada9-7880-4fae-97d8-db0e934c3f5f', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: People for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('7a94ada9-7880-4fae-97d8-db0e934c3f5f', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: People for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('7a94ada9-7880-4fae-97d8-db0e934c3f5f', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL generated to create new entity MJ.BizApps.Common: Organizations */

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
         'c70448f9-9792-41d7-a82c-784b66429d54',
         'MJ.BizApps.Common: Organizations',
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
   

/* SQL generated to add new entity MJ.BizApps.Common: Organizations to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'c70448f9-9792-41d7-a82c-784b66429d54', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'))

/* SQL generated to add new permission for entity MJ.BizApps.Common: Organizations for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('c70448f9-9792-41d7-a82c-784b66429d54', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: Organizations for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('c70448f9-9792-41d7-a82c-784b66429d54', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: Organizations for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('c70448f9-9792-41d7-a82c-784b66429d54', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL generated to create new entity MJ.BizApps.Common: Addresses */

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
         '61b5c6fb-7317-46d1-8e05-f669b7bc6f3e',
         'MJ.BizApps.Common: Addresses',
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
   

/* SQL generated to add new entity MJ.BizApps.Common: Addresses to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '61b5c6fb-7317-46d1-8e05-f669b7bc6f3e', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'))

/* SQL generated to add new permission for entity MJ.BizApps.Common: Addresses for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('61b5c6fb-7317-46d1-8e05-f669b7bc6f3e', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: Addresses for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('61b5c6fb-7317-46d1-8e05-f669b7bc6f3e', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: Addresses for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('61b5c6fb-7317-46d1-8e05-f669b7bc6f3e', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL generated to create new entity MJ.BizApps.Common: Address Links */

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
         'f2fc2e85-b210-43a9-8565-290ad9d0c6e7',
         'MJ.BizApps.Common: Address Links',
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
   

/* SQL generated to add new entity MJ.BizApps.Common: Address Links to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'f2fc2e85-b210-43a9-8565-290ad9d0c6e7', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'))

/* SQL generated to add new permission for entity MJ.BizApps.Common: Address Links for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('f2fc2e85-b210-43a9-8565-290ad9d0c6e7', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: Address Links for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('f2fc2e85-b210-43a9-8565-290ad9d0c6e7', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: Address Links for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('f2fc2e85-b210-43a9-8565-290ad9d0c6e7', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL generated to create new entity MJ.BizApps.Common: Contact Methods */

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
         '32c45078-d33b-4760-9be5-0df7f483f591',
         'MJ.BizApps.Common: Contact Methods',
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
   

/* SQL generated to add new entity MJ.BizApps.Common: Contact Methods to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '32c45078-d33b-4760-9be5-0df7f483f591', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'))

/* SQL generated to add new permission for entity MJ.BizApps.Common: Contact Methods for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('32c45078-d33b-4760-9be5-0df7f483f591', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: Contact Methods for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('32c45078-d33b-4760-9be5-0df7f483f591', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: Contact Methods for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('32c45078-d33b-4760-9be5-0df7f483f591', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL generated to create new entity MJ.BizApps.Common: Relationships */

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
         '709ca9da-b124-4155-be39-e857ef672d82',
         'MJ.BizApps.Common: Relationships',
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
   

/* SQL generated to add new entity MJ.BizApps.Common: Relationships to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO ${flyway:defaultSchema}.ApplicationEntity
                                       (ApplicationID, EntityID, Sequence) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '709ca9da-b124-4155-be39-e857ef672d82', (SELECT ISNULL(MAX(Sequence),0)+1 FROM ${flyway:defaultSchema}.ApplicationEntity WHERE ApplicationID = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'))

/* SQL generated to add new permission for entity MJ.BizApps.Common: Relationships for role UI */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('709ca9da-b124-4155-be39-e857ef672d82', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: Relationships for role Developer */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('709ca9da-b124-4155-be39-e857ef672d82', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 0)

/* SQL generated to add new permission for entity MJ.BizApps.Common: Relationships for role Integration */
INSERT INTO ${flyway:defaultSchema}.EntityPermission
                                                   (EntityID, RoleID, CanRead, CanCreate, CanUpdate, CanDelete) VALUES
                                                   ('709ca9da-b124-4155-be39-e857ef672d82', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1)

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.ContactMethod */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.ContactMethod */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.AddressLink */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[AddressLink] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.AddressLink */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[AddressLink] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.ContactType */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[ContactType] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.ContactType */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[ContactType] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.Organization */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[Organization] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.Organization */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[Organization] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.RelationshipType */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[RelationshipType] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.RelationshipType */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[RelationshipType] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.AddressType */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[AddressType] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.AddressType */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[AddressType] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.Person */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[Person] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.Person */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[Person] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.Relationship */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[Relationship] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.Relationship */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[Relationship] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.OrganizationType */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[OrganizationType] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.OrganizationType */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[OrganizationType] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.Address */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[Address] ADD __mj_CreatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}_BizAppsCommon.Address */
ALTER TABLE [${flyway:defaultSchema}_BizAppsCommon].[Address] ADD __mj_UpdatedAt DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE()

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'c66b3740-b4b9-4ba4-b53d-9cdc6a64dafb'  OR 
               (EntityID = '32C45078-D33B-4760-9BE5-0DF7F483F591' AND Name = 'ID')
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
            'c66b3740-b4b9-4ba4-b53d-9cdc6a64dafb',
            '32C45078-D33B-4760-9BE5-0DF7F483F591', -- Entity: MJ.BizApps.Common: Contact Methods
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
         WHERE ID = 'b6b5a623-f308-496e-8845-0cf1e92e9d00'  OR 
               (EntityID = '32C45078-D33B-4760-9BE5-0DF7F483F591' AND Name = 'PersonID')
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
            'b6b5a623-f308-496e-8845-0cf1e92e9d00',
            '32C45078-D33B-4760-9BE5-0DF7F483F591', -- Entity: MJ.BizApps.Common: Contact Methods
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
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F',
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
         WHERE ID = '0ec64524-99cd-484d-bf82-0e422d0c9903'  OR 
               (EntityID = '32C45078-D33B-4760-9BE5-0DF7F483F591' AND Name = 'OrganizationID')
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
            '0ec64524-99cd-484d-bf82-0e422d0c9903',
            '32C45078-D33B-4760-9BE5-0DF7F483F591', -- Entity: MJ.BizApps.Common: Contact Methods
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
            'C70448F9-9792-41D7-A82C-784B66429D54',
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
         WHERE ID = '5c42f4d1-4abd-4cc6-b5da-a164d5cba7a1'  OR 
               (EntityID = '32C45078-D33B-4760-9BE5-0DF7F483F591' AND Name = 'ContactTypeID')
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
            '5c42f4d1-4abd-4cc6-b5da-a164d5cba7a1',
            '32C45078-D33B-4760-9BE5-0DF7F483F591', -- Entity: MJ.BizApps.Common: Contact Methods
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
            '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5',
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
         WHERE ID = '77c20975-15e3-4a89-9414-3a829a5ea249'  OR 
               (EntityID = '32C45078-D33B-4760-9BE5-0DF7F483F591' AND Name = 'Value')
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
            '77c20975-15e3-4a89-9414-3a829a5ea249',
            '32C45078-D33B-4760-9BE5-0DF7F483F591', -- Entity: MJ.BizApps.Common: Contact Methods
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
         WHERE ID = 'cba68064-c466-460e-ad1b-89256634a753'  OR 
               (EntityID = '32C45078-D33B-4760-9BE5-0DF7F483F591' AND Name = 'Label')
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
            'cba68064-c466-460e-ad1b-89256634a753',
            '32C45078-D33B-4760-9BE5-0DF7F483F591', -- Entity: MJ.BizApps.Common: Contact Methods
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
         WHERE ID = '9aaa02e5-c378-43be-a1b3-6ef7355cdf22'  OR 
               (EntityID = '32C45078-D33B-4760-9BE5-0DF7F483F591' AND Name = 'IsPrimary')
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
            '9aaa02e5-c378-43be-a1b3-6ef7355cdf22',
            '32C45078-D33B-4760-9BE5-0DF7F483F591', -- Entity: MJ.BizApps.Common: Contact Methods
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
         WHERE ID = 'da376286-2631-4fa3-88da-1d7be44312cc'  OR 
               (EntityID = '32C45078-D33B-4760-9BE5-0DF7F483F591' AND Name = '__mj_CreatedAt')
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
            'da376286-2631-4fa3-88da-1d7be44312cc',
            '32C45078-D33B-4760-9BE5-0DF7F483F591', -- Entity: MJ.BizApps.Common: Contact Methods
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
         WHERE ID = 'fc8dc59a-e1b5-4136-9000-99643e602806'  OR 
               (EntityID = '32C45078-D33B-4760-9BE5-0DF7F483F591' AND Name = '__mj_UpdatedAt')
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
            'fc8dc59a-e1b5-4136-9000-99643e602806',
            '32C45078-D33B-4760-9BE5-0DF7F483F591', -- Entity: MJ.BizApps.Common: Contact Methods
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
         WHERE ID = 'c7ef895a-84e9-4388-8f9d-4e60a73ce67d'  OR 
               (EntityID = 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7' AND Name = 'ID')
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
            'c7ef895a-84e9-4388-8f9d-4e60a73ce67d',
            'F2FC2E85-B210-43A9-8565-290AD9D0C6E7', -- Entity: MJ.BizApps.Common: Address Links
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
         WHERE ID = 'effa8dd0-9fce-4504-83a8-a1415c912621'  OR 
               (EntityID = 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7' AND Name = 'AddressID')
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
            'effa8dd0-9fce-4504-83a8-a1415c912621',
            'F2FC2E85-B210-43A9-8565-290AD9D0C6E7', -- Entity: MJ.BizApps.Common: Address Links
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
            '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E',
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
         WHERE ID = '63d14e61-c4be-4369-a775-7a93a14a6432'  OR 
               (EntityID = 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7' AND Name = 'EntityID')
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
            '63d14e61-c4be-4369-a775-7a93a14a6432',
            'F2FC2E85-B210-43A9-8565-290AD9D0C6E7', -- Entity: MJ.BizApps.Common: Address Links
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
         WHERE ID = '8e6c198e-773e-4582-b020-7c7a9716b2c8'  OR 
               (EntityID = 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7' AND Name = 'RecordID')
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
            '8e6c198e-773e-4582-b020-7c7a9716b2c8',
            'F2FC2E85-B210-43A9-8565-290AD9D0C6E7', -- Entity: MJ.BizApps.Common: Address Links
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
         WHERE ID = '633eab3f-8828-4db0-9b19-6ad04a75cb83'  OR 
               (EntityID = 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7' AND Name = 'AddressTypeID')
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
            '633eab3f-8828-4db0-9b19-6ad04a75cb83',
            'F2FC2E85-B210-43A9-8565-290AD9D0C6E7', -- Entity: MJ.BizApps.Common: Address Links
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
            '7A7245D1-2316-44A4-B147-A50FF19F5942',
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
         WHERE ID = '80d85088-71d2-42f1-a9a3-086ee3f96b3d'  OR 
               (EntityID = 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7' AND Name = 'IsPrimary')
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
            '80d85088-71d2-42f1-a9a3-086ee3f96b3d',
            'F2FC2E85-B210-43A9-8565-290AD9D0C6E7', -- Entity: MJ.BizApps.Common: Address Links
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
         WHERE ID = 'cf61a8c5-2f33-4756-ad71-257504e7b4e3'  OR 
               (EntityID = 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7' AND Name = 'Rank')
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
            'cf61a8c5-2f33-4756-ad71-257504e7b4e3',
            'F2FC2E85-B210-43A9-8565-290AD9D0C6E7', -- Entity: MJ.BizApps.Common: Address Links
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
         WHERE ID = '8d738e18-a0ba-45ef-88c0-d8bc29d8d877'  OR 
               (EntityID = 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7' AND Name = '__mj_CreatedAt')
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
            '8d738e18-a0ba-45ef-88c0-d8bc29d8d877',
            'F2FC2E85-B210-43A9-8565-290AD9D0C6E7', -- Entity: MJ.BizApps.Common: Address Links
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
         WHERE ID = 'b3518e84-62ff-488b-963b-4e7076932a8f'  OR 
               (EntityID = 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7' AND Name = '__mj_UpdatedAt')
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
            'b3518e84-62ff-488b-963b-4e7076932a8f',
            'F2FC2E85-B210-43A9-8565-290AD9D0C6E7', -- Entity: MJ.BizApps.Common: Address Links
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
         WHERE ID = 'c40c2682-a2fa-4676-833b-75030293220c'  OR 
               (EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND Name = 'ID')
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
            'c40c2682-a2fa-4676-833b-75030293220c',
            '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', -- Entity: MJ.BizApps.Common: Contact Types
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
         WHERE ID = '1d142a23-e13c-4852-9dd9-a896774c3bda'  OR 
               (EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND Name = 'Name')
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
            '1d142a23-e13c-4852-9dd9-a896774c3bda',
            '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', -- Entity: MJ.BizApps.Common: Contact Types
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
         WHERE ID = '8096a2bd-684f-44e0-b26b-424f52619220'  OR 
               (EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND Name = 'Description')
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
            '8096a2bd-684f-44e0-b26b-424f52619220',
            '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', -- Entity: MJ.BizApps.Common: Contact Types
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
         WHERE ID = '00865ed9-b98d-4f58-8c5d-022ac87ff8e7'  OR 
               (EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND Name = 'IconClass')
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
            '00865ed9-b98d-4f58-8c5d-022ac87ff8e7',
            '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', -- Entity: MJ.BizApps.Common: Contact Types
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
         WHERE ID = '45829cd8-c67d-4527-b25e-4390889eeb85'  OR 
               (EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND Name = 'DisplayRank')
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
            '45829cd8-c67d-4527-b25e-4390889eeb85',
            '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', -- Entity: MJ.BizApps.Common: Contact Types
            100005,
            'DisplayRank',
            'Display Rank',
            'Sort order in dropdown lists. Lower values appear first',
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
         WHERE ID = '9fff0788-f1a4-4971-9b53-2fef0407880a'  OR 
               (EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND Name = 'IsActive')
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
            '9fff0788-f1a4-4971-9b53-2fef0407880a',
            '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', -- Entity: MJ.BizApps.Common: Contact Types
            100006,
            'IsActive',
            'Is Active',
            'Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records',
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
         WHERE ID = '86c73c1a-89cd-4326-a8bb-145e6b0b2f4a'  OR 
               (EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND Name = '__mj_CreatedAt')
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
            '86c73c1a-89cd-4326-a8bb-145e6b0b2f4a',
            '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', -- Entity: MJ.BizApps.Common: Contact Types
            100007,
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
         WHERE ID = 'a005a7db-76ec-4ddf-8482-7951be69b165'  OR 
               (EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND Name = '__mj_UpdatedAt')
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
            'a005a7db-76ec-4ddf-8482-7951be69b165',
            '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', -- Entity: MJ.BizApps.Common: Contact Types
            100008,
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
         WHERE ID = 'b194ee44-85db-4d2a-a76f-9feb0b5f1aeb'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'ID')
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
            'b194ee44-85db-4d2a-a76f-9feb0b5f1aeb',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
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
         WHERE ID = '9f465e98-0614-4987-bed8-90b8a1450685'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'Name')
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
            '9f465e98-0614-4987-bed8-90b8a1450685',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
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
         WHERE ID = '28daa78c-fabd-438d-8f24-055987b58b60'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'LegalName')
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
            '28daa78c-fabd-438d-8f24-055987b58b60',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
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
         WHERE ID = '9e6fcd82-bcdf-443a-a87d-e16eef761068'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'OrganizationTypeID')
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
            '9e6fcd82-bcdf-443a-a87d-e16eef761068',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
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
            'A77D9725-4871-484B-99F0-F65461D7ABEE',
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
         WHERE ID = 'd78a9db0-2ed9-4d73-a408-24b0e03981c9'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'ParentID')
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
            'd78a9db0-2ed9-4d73-a408-24b0e03981c9',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
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
            'C70448F9-9792-41D7-A82C-784B66429D54',
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
         WHERE ID = 'c8c255e3-d3c1-4f3d-84aa-07b30981fb3e'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'Website')
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
            'c8c255e3-d3c1-4f3d-84aa-07b30981fb3e',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
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
         WHERE ID = '428426b8-70e5-409e-ba30-8aad6dfaf08e'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'LogoURL')
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
            '428426b8-70e5-409e-ba30-8aad6dfaf08e',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
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
         WHERE ID = 'e1f4b6bc-8465-429b-922c-353f6d1b547c'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'Description')
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
            'e1f4b6bc-8465-429b-922c-353f6d1b547c',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
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
         WHERE ID = '46b9d67f-3365-47b4-bfe1-6bb932392ae3'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'Email')
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
            '46b9d67f-3365-47b4-bfe1-6bb932392ae3',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
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
         WHERE ID = '9a9b834c-1d11-4a4e-98b3-904d048f89dc'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'Phone')
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
            '9a9b834c-1d11-4a4e-98b3-904d048f89dc',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
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
         WHERE ID = '012ce6d0-f4dc-4921-90d6-c56be2f3d1b3'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'FoundedDate')
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
            '012ce6d0-f4dc-4921-90d6-c56be2f3d1b3',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
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
         WHERE ID = '3a676695-4dee-4a2e-95e5-00a96de43dad'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'TaxID')
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
            '3a676695-4dee-4a2e-95e5-00a96de43dad',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
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
         WHERE ID = '8620f795-6511-4715-a823-d3c905af3ecc'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'Status')
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
            '8620f795-6511-4715-a823-d3c905af3ecc',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
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
         WHERE ID = '36566057-63b7-49b2-a7f2-928c0d798c02'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = '__mj_CreatedAt')
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
            '36566057-63b7-49b2-a7f2-928c0d798c02',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
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
         WHERE ID = 'e219f8e5-5247-425e-bd32-abd41f8615bd'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = '__mj_UpdatedAt')
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
            'e219f8e5-5247-425e-bd32-abd41f8615bd',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
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
         WHERE ID = '2b7f56c2-c197-45e1-9c79-af1bfde094d4'  OR 
               (EntityID = '5F214F43-109C-407D-B505-7B0B3B72ACB5' AND Name = 'ID')
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
            '2b7f56c2-c197-45e1-9c79-af1bfde094d4',
            '5F214F43-109C-407D-B505-7B0B3B72ACB5', -- Entity: MJ.BizApps.Common: Relationship Types
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
         WHERE ID = 'b0c9f62f-cd73-4eeb-87a8-1f55ade79539'  OR 
               (EntityID = '5F214F43-109C-407D-B505-7B0B3B72ACB5' AND Name = 'Name')
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
            'b0c9f62f-cd73-4eeb-87a8-1f55ade79539',
            '5F214F43-109C-407D-B505-7B0B3B72ACB5', -- Entity: MJ.BizApps.Common: Relationship Types
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
         WHERE ID = '8f51e66c-379d-4e06-acf6-75f98e690782'  OR 
               (EntityID = '5F214F43-109C-407D-B505-7B0B3B72ACB5' AND Name = 'Description')
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
            '8f51e66c-379d-4e06-acf6-75f98e690782',
            '5F214F43-109C-407D-B505-7B0B3B72ACB5', -- Entity: MJ.BizApps.Common: Relationship Types
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
         WHERE ID = 'acaec8f6-49f4-47c0-983d-33bb4fb29e7b'  OR 
               (EntityID = '5F214F43-109C-407D-B505-7B0B3B72ACB5' AND Name = 'Category')
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
            'acaec8f6-49f4-47c0-983d-33bb4fb29e7b',
            '5F214F43-109C-407D-B505-7B0B3B72ACB5', -- Entity: MJ.BizApps.Common: Relationship Types
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
         WHERE ID = 'b66f18b2-77da-4f8e-b9e3-44e9bc6cfc54'  OR 
               (EntityID = '5F214F43-109C-407D-B505-7B0B3B72ACB5' AND Name = 'IsDirectional')
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
            'b66f18b2-77da-4f8e-b9e3-44e9bc6cfc54',
            '5F214F43-109C-407D-B505-7B0B3B72ACB5', -- Entity: MJ.BizApps.Common: Relationship Types
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
         WHERE ID = '7b610118-fb6d-4ce0-886f-23881c4647e3'  OR 
               (EntityID = '5F214F43-109C-407D-B505-7B0B3B72ACB5' AND Name = 'ForwardLabel')
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
            '7b610118-fb6d-4ce0-886f-23881c4647e3',
            '5F214F43-109C-407D-B505-7B0B3B72ACB5', -- Entity: MJ.BizApps.Common: Relationship Types
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
         WHERE ID = '8221fa5a-6288-48ea-9f5c-92dbbb9020cf'  OR 
               (EntityID = '5F214F43-109C-407D-B505-7B0B3B72ACB5' AND Name = 'ReverseLabel')
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
            '8221fa5a-6288-48ea-9f5c-92dbbb9020cf',
            '5F214F43-109C-407D-B505-7B0B3B72ACB5', -- Entity: MJ.BizApps.Common: Relationship Types
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
         WHERE ID = '60d162bd-2934-4ad7-a74e-f27ef47656d7'  OR 
               (EntityID = '5F214F43-109C-407D-B505-7B0B3B72ACB5' AND Name = 'IsActive')
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
            '60d162bd-2934-4ad7-a74e-f27ef47656d7',
            '5F214F43-109C-407D-B505-7B0B3B72ACB5', -- Entity: MJ.BizApps.Common: Relationship Types
            100008,
            'IsActive',
            'Is Active',
            'Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records',
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
         WHERE ID = '8c67deb3-e9ba-412d-9875-dd29a5523fce'  OR 
               (EntityID = '5F214F43-109C-407D-B505-7B0B3B72ACB5' AND Name = '__mj_CreatedAt')
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
            '8c67deb3-e9ba-412d-9875-dd29a5523fce',
            '5F214F43-109C-407D-B505-7B0B3B72ACB5', -- Entity: MJ.BizApps.Common: Relationship Types
            100009,
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
         WHERE ID = 'f28625fd-5f8f-429c-8100-9b9c54205ab0'  OR 
               (EntityID = '5F214F43-109C-407D-B505-7B0B3B72ACB5' AND Name = '__mj_UpdatedAt')
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
            'f28625fd-5f8f-429c-8100-9b9c54205ab0',
            '5F214F43-109C-407D-B505-7B0B3B72ACB5', -- Entity: MJ.BizApps.Common: Relationship Types
            100010,
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
         WHERE ID = '85492901-7593-46e0-8d3d-d50ed60346d5'  OR 
               (EntityID = '7A7245D1-2316-44A4-B147-A50FF19F5942' AND Name = 'ID')
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
            '85492901-7593-46e0-8d3d-d50ed60346d5',
            '7A7245D1-2316-44A4-B147-A50FF19F5942', -- Entity: MJ.BizApps.Common: Address Types
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
         WHERE ID = 'b93aa266-faa5-461d-b32b-a0f26c698b2c'  OR 
               (EntityID = '7A7245D1-2316-44A4-B147-A50FF19F5942' AND Name = 'Name')
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
            'b93aa266-faa5-461d-b32b-a0f26c698b2c',
            '7A7245D1-2316-44A4-B147-A50FF19F5942', -- Entity: MJ.BizApps.Common: Address Types
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
         WHERE ID = '255fcd46-e0e2-4b77-ab45-0ccdf6181e36'  OR 
               (EntityID = '7A7245D1-2316-44A4-B147-A50FF19F5942' AND Name = 'Description')
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
            '255fcd46-e0e2-4b77-ab45-0ccdf6181e36',
            '7A7245D1-2316-44A4-B147-A50FF19F5942', -- Entity: MJ.BizApps.Common: Address Types
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
         WHERE ID = 'b0408d09-cf61-4d1d-b951-8e0c5490bd29'  OR 
               (EntityID = '7A7245D1-2316-44A4-B147-A50FF19F5942' AND Name = 'IconClass')
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
            'b0408d09-cf61-4d1d-b951-8e0c5490bd29',
            '7A7245D1-2316-44A4-B147-A50FF19F5942', -- Entity: MJ.BizApps.Common: Address Types
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
         WHERE ID = '971c65dd-9f0c-4b46-ab06-8d5a3e47cbc3'  OR 
               (EntityID = '7A7245D1-2316-44A4-B147-A50FF19F5942' AND Name = 'DefaultRank')
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
            '971c65dd-9f0c-4b46-ab06-8d5a3e47cbc3',
            '7A7245D1-2316-44A4-B147-A50FF19F5942', -- Entity: MJ.BizApps.Common: Address Types
            100005,
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
         WHERE ID = 'f70d2734-af27-4969-9c8b-b51259e71f8f'  OR 
               (EntityID = '7A7245D1-2316-44A4-B147-A50FF19F5942' AND Name = 'IsActive')
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
            'f70d2734-af27-4969-9c8b-b51259e71f8f',
            '7A7245D1-2316-44A4-B147-A50FF19F5942', -- Entity: MJ.BizApps.Common: Address Types
            100006,
            'IsActive',
            'Is Active',
            'Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records',
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
         WHERE ID = '236794a4-9f6f-472e-9d9f-c77383cf48f5'  OR 
               (EntityID = '7A7245D1-2316-44A4-B147-A50FF19F5942' AND Name = '__mj_CreatedAt')
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
            '236794a4-9f6f-472e-9d9f-c77383cf48f5',
            '7A7245D1-2316-44A4-B147-A50FF19F5942', -- Entity: MJ.BizApps.Common: Address Types
            100007,
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
         WHERE ID = 'bca9babd-e370-4376-89ac-dcf9340e5734'  OR 
               (EntityID = '7A7245D1-2316-44A4-B147-A50FF19F5942' AND Name = '__mj_UpdatedAt')
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
            'bca9babd-e370-4376-89ac-dcf9340e5734',
            '7A7245D1-2316-44A4-B147-A50FF19F5942', -- Entity: MJ.BizApps.Common: Address Types
            100008,
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
         WHERE ID = '2a0b54f1-94f8-466c-86c2-931e200258c1'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'ID')
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
            '2a0b54f1-94f8-466c-86c2-931e200258c1',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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
         WHERE ID = '4942cbcc-6d0b-44f5-be38-9d697d02b463'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'FirstName')
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
            '4942cbcc-6d0b-44f5-be38-9d697d02b463',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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
         WHERE ID = '09ad91da-42c7-44f4-ae71-5ac6e50d7657'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'LastName')
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
            '09ad91da-42c7-44f4-ae71-5ac6e50d7657',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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
         WHERE ID = '528500f1-1bb8-4564-a46d-5d45362f3e05'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'MiddleName')
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
            '528500f1-1bb8-4564-a46d-5d45362f3e05',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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
         WHERE ID = '31733eb2-a6cb-4433-8fac-f278676855dc'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'Prefix')
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
            '31733eb2-a6cb-4433-8fac-f278676855dc',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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
         WHERE ID = '9f22ee0d-ac30-4805-89ec-e2c8576615be'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'Suffix')
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
            '9f22ee0d-ac30-4805-89ec-e2c8576615be',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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
         WHERE ID = '27375f71-8f8f-4dab-8803-96ae73ea28ce'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'PreferredName')
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
            '27375f71-8f8f-4dab-8803-96ae73ea28ce',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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
         WHERE ID = '0b992115-7c59-4d6e-a49e-ddae2d7e9056'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'Title')
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
            '0b992115-7c59-4d6e-a49e-ddae2d7e9056',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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
         WHERE ID = 'f6b2a29b-cfe9-410d-9732-3ae2acf44dc0'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'Email')
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
            'f6b2a29b-cfe9-410d-9732-3ae2acf44dc0',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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
         WHERE ID = '1b312aa3-5ccc-48e6-b034-a8bf437c9a4d'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'Phone')
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
            '1b312aa3-5ccc-48e6-b034-a8bf437c9a4d',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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
         WHERE ID = '45090e40-2e5c-4359-b14d-b3d902685c11'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'DateOfBirth')
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
            '45090e40-2e5c-4359-b14d-b3d902685c11',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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
         WHERE ID = '69b0d1a5-c5f5-4f21-9f39-4dcb1c46f76f'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'Gender')
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
            '69b0d1a5-c5f5-4f21-9f39-4dcb1c46f76f',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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
         WHERE ID = '6bd597e1-05b9-46f6-80fd-5a98d35c4fdd'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'PhotoURL')
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
            '6bd597e1-05b9-46f6-80fd-5a98d35c4fdd',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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
         WHERE ID = '152f8f83-767b-4b4f-af92-ef786126dec0'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'Bio')
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
            '152f8f83-767b-4b4f-af92-ef786126dec0',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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
         WHERE ID = '79f1eeab-367e-4b45-a9b8-75639f6410cb'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'LinkedUserID')
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
            '79f1eeab-367e-4b45-a9b8-75639f6410cb',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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
            1,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '57f78065-e9db-4d2c-a2f8-524d4f15d902'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'Status')
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
            '57f78065-e9db-4d2c-a2f8-524d4f15d902',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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
         WHERE ID = '86c714e8-b200-4f9f-817a-baf052aeee3d'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = '__mj_CreatedAt')
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
            '86c714e8-b200-4f9f-817a-baf052aeee3d',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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
         WHERE ID = 'cc25d06a-8f7e-433d-9658-500f225d55ec'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = '__mj_UpdatedAt')
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
            'cc25d06a-8f7e-433d-9658-500f225d55ec',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'fefdad15-7ba5-470a-a689-147d9303ab34'  OR 
               (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = 'ID')
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
            'fefdad15-7ba5-470a-a689-147d9303ab34',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ.BizApps.Common: Relationships
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
         WHERE ID = '4bffafbd-bf4e-4907-963b-95733c670b7e'  OR 
               (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = 'RelationshipTypeID')
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
            '4bffafbd-bf4e-4907-963b-95733c670b7e',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ.BizApps.Common: Relationships
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
            '5F214F43-109C-407D-B505-7B0B3B72ACB5',
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
         WHERE ID = '8974264b-dc82-4276-b89e-c65e14f078f8'  OR 
               (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = 'FromPersonID')
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
            '8974264b-dc82-4276-b89e-c65e14f078f8',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ.BizApps.Common: Relationships
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
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F',
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
         WHERE ID = '6d46f59f-ff3f-4351-a697-e7db414a1e3e'  OR 
               (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = 'FromOrganizationID')
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
            '6d46f59f-ff3f-4351-a697-e7db414a1e3e',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ.BizApps.Common: Relationships
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
            'C70448F9-9792-41D7-A82C-784B66429D54',
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
         WHERE ID = 'ad3ecdaa-e2be-40d9-b83e-1868ab68c778'  OR 
               (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = 'ToPersonID')
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
            'ad3ecdaa-e2be-40d9-b83e-1868ab68c778',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ.BizApps.Common: Relationships
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
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F',
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
         WHERE ID = '42eba3ce-7ddb-4149-be93-e245f351b963'  OR 
               (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = 'ToOrganizationID')
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
            '42eba3ce-7ddb-4149-be93-e245f351b963',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ.BizApps.Common: Relationships
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
            'C70448F9-9792-41D7-A82C-784B66429D54',
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
         WHERE ID = '2acbd16a-2a78-4807-8b8d-d0920382eae6'  OR 
               (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = 'Title')
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
            '2acbd16a-2a78-4807-8b8d-d0920382eae6',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ.BizApps.Common: Relationships
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
         WHERE ID = '62d8a345-e8ac-4ee6-88a9-1959f6258657'  OR 
               (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = 'StartDate')
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
            '62d8a345-e8ac-4ee6-88a9-1959f6258657',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ.BizApps.Common: Relationships
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
         WHERE ID = '0afc293d-e93d-4bd2-a71c-acb2631ca278'  OR 
               (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = 'EndDate')
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
            '0afc293d-e93d-4bd2-a71c-acb2631ca278',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ.BizApps.Common: Relationships
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
         WHERE ID = '80b0c5c4-915a-4e72-9978-74cb33902f08'  OR 
               (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = 'Status')
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
            '80b0c5c4-915a-4e72-9978-74cb33902f08',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ.BizApps.Common: Relationships
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
         WHERE ID = 'cd66c882-d041-46f1-8de2-3807b1bd8b5a'  OR 
               (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = 'Notes')
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
            'cd66c882-d041-46f1-8de2-3807b1bd8b5a',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ.BizApps.Common: Relationships
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
         WHERE ID = '5f0be392-8f9c-4995-bc97-344d361c9706'  OR 
               (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = '__mj_CreatedAt')
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
            '5f0be392-8f9c-4995-bc97-344d361c9706',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ.BizApps.Common: Relationships
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
         WHERE ID = 'b15ae830-4bcb-4aa3-847e-916885287462'  OR 
               (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = '__mj_UpdatedAt')
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
            'b15ae830-4bcb-4aa3-847e-916885287462',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ.BizApps.Common: Relationships
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
         WHERE ID = '665481ad-fc97-49be-a98c-ab58aa509f59'  OR 
               (EntityID = 'A77D9725-4871-484B-99F0-F65461D7ABEE' AND Name = 'ID')
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
            '665481ad-fc97-49be-a98c-ab58aa509f59',
            'A77D9725-4871-484B-99F0-F65461D7ABEE', -- Entity: MJ.BizApps.Common: Organization Types
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
         WHERE ID = '82f2cdbc-8793-4fe4-bfca-380a8a22f41f'  OR 
               (EntityID = 'A77D9725-4871-484B-99F0-F65461D7ABEE' AND Name = 'Name')
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
            '82f2cdbc-8793-4fe4-bfca-380a8a22f41f',
            'A77D9725-4871-484B-99F0-F65461D7ABEE', -- Entity: MJ.BizApps.Common: Organization Types
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
         WHERE ID = 'e6f5450e-c909-426c-8ea6-968a3a68b6ca'  OR 
               (EntityID = 'A77D9725-4871-484B-99F0-F65461D7ABEE' AND Name = 'Description')
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
            'e6f5450e-c909-426c-8ea6-968a3a68b6ca',
            'A77D9725-4871-484B-99F0-F65461D7ABEE', -- Entity: MJ.BizApps.Common: Organization Types
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
         WHERE ID = '1d7e13df-447a-49b8-9a07-1fa0cc058115'  OR 
               (EntityID = 'A77D9725-4871-484B-99F0-F65461D7ABEE' AND Name = 'IconClass')
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
            '1d7e13df-447a-49b8-9a07-1fa0cc058115',
            'A77D9725-4871-484B-99F0-F65461D7ABEE', -- Entity: MJ.BizApps.Common: Organization Types
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
         WHERE ID = '8686f717-72ac-4ecb-b3ff-200da50df000'  OR 
               (EntityID = 'A77D9725-4871-484B-99F0-F65461D7ABEE' AND Name = 'DisplayRank')
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
            '8686f717-72ac-4ecb-b3ff-200da50df000',
            'A77D9725-4871-484B-99F0-F65461D7ABEE', -- Entity: MJ.BizApps.Common: Organization Types
            100005,
            'DisplayRank',
            'Display Rank',
            'Sort order in dropdown lists. Lower values appear first',
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
         WHERE ID = 'a6aaf1ab-1212-4066-9a84-2f0dae43b5be'  OR 
               (EntityID = 'A77D9725-4871-484B-99F0-F65461D7ABEE' AND Name = 'IsActive')
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
            'a6aaf1ab-1212-4066-9a84-2f0dae43b5be',
            'A77D9725-4871-484B-99F0-F65461D7ABEE', -- Entity: MJ.BizApps.Common: Organization Types
            100006,
            'IsActive',
            'Is Active',
            'Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records',
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
         WHERE ID = '7c026948-1d22-4d12-b839-a8af848811ba'  OR 
               (EntityID = 'A77D9725-4871-484B-99F0-F65461D7ABEE' AND Name = '__mj_CreatedAt')
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
            '7c026948-1d22-4d12-b839-a8af848811ba',
            'A77D9725-4871-484B-99F0-F65461D7ABEE', -- Entity: MJ.BizApps.Common: Organization Types
            100007,
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
         WHERE ID = 'a2efb1da-409f-40fa-be98-02e394a0f965'  OR 
               (EntityID = 'A77D9725-4871-484B-99F0-F65461D7ABEE' AND Name = '__mj_UpdatedAt')
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
            'a2efb1da-409f-40fa-be98-02e394a0f965',
            'A77D9725-4871-484B-99F0-F65461D7ABEE', -- Entity: MJ.BizApps.Common: Organization Types
            100008,
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
         WHERE ID = 'ba3e4fae-198f-48e4-bd9f-774d8584e259'  OR 
               (EntityID = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E' AND Name = 'ID')
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
            'ba3e4fae-198f-48e4-bd9f-774d8584e259',
            '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E', -- Entity: MJ.BizApps.Common: Addresses
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
         WHERE ID = '8c5ed1b2-107e-4195-9e05-ac25c452971d'  OR 
               (EntityID = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E' AND Name = 'Line1')
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
            '8c5ed1b2-107e-4195-9e05-ac25c452971d',
            '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E', -- Entity: MJ.BizApps.Common: Addresses
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
         WHERE ID = 'c6515a57-dace-4684-ad9d-03297e60cde4'  OR 
               (EntityID = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E' AND Name = 'Line2')
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
            'c6515a57-dace-4684-ad9d-03297e60cde4',
            '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E', -- Entity: MJ.BizApps.Common: Addresses
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
         WHERE ID = '9540ede1-741a-4b6f-b9f0-8de3c3edfc31'  OR 
               (EntityID = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E' AND Name = 'Line3')
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
            '9540ede1-741a-4b6f-b9f0-8de3c3edfc31',
            '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E', -- Entity: MJ.BizApps.Common: Addresses
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
         WHERE ID = '0c71e92a-d747-4302-b17f-78c92930d2ce'  OR 
               (EntityID = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E' AND Name = 'City')
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
            '0c71e92a-d747-4302-b17f-78c92930d2ce',
            '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E', -- Entity: MJ.BizApps.Common: Addresses
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
         WHERE ID = 'd43eca52-4b7a-434e-92ce-c3ff69824306'  OR 
               (EntityID = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E' AND Name = 'StateProvince')
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
            'd43eca52-4b7a-434e-92ce-c3ff69824306',
            '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E', -- Entity: MJ.BizApps.Common: Addresses
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
         WHERE ID = '65acac26-5f6c-4a67-8559-bd7c0943a925'  OR 
               (EntityID = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E' AND Name = 'PostalCode')
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
            '65acac26-5f6c-4a67-8559-bd7c0943a925',
            '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E', -- Entity: MJ.BizApps.Common: Addresses
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
         WHERE ID = '63bb48d1-67c2-4cd9-bdd9-f86f6154f77c'  OR 
               (EntityID = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E' AND Name = 'Country')
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
            '63bb48d1-67c2-4cd9-bdd9-f86f6154f77c',
            '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E', -- Entity: MJ.BizApps.Common: Addresses
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
         WHERE ID = '66d63980-b9b5-47a0-ba8b-6b55977cb60c'  OR 
               (EntityID = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E' AND Name = 'Latitude')
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
            '66d63980-b9b5-47a0-ba8b-6b55977cb60c',
            '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E', -- Entity: MJ.BizApps.Common: Addresses
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
         WHERE ID = 'b03f710e-9199-4986-90bf-3ece5037d79a'  OR 
               (EntityID = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E' AND Name = 'Longitude')
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
            'b03f710e-9199-4986-90bf-3ece5037d79a',
            '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E', -- Entity: MJ.BizApps.Common: Addresses
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
         WHERE ID = 'cfe3572f-9b12-4d14-bba5-2f9a8a3b66f0'  OR 
               (EntityID = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E' AND Name = '__mj_CreatedAt')
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
            'cfe3572f-9b12-4d14-bba5-2f9a8a3b66f0',
            '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E', -- Entity: MJ.BizApps.Common: Addresses
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
         WHERE ID = '2ff61a35-fb7c-455a-8883-6998b141b095'  OR 
               (EntityID = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E' AND Name = '__mj_UpdatedAt')
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
            '2ff61a35-fb7c-455a-8883-6998b141b095',
            '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E', -- Entity: MJ.BizApps.Common: Addresses
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

/* SQL text to insert entity field value with ID 43ccc1f7-a27a-4bd1-8424-e29edefe48b0 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('43ccc1f7-a27a-4bd1-8424-e29edefe48b0', 'ACAEC8F6-49F4-47C0-983D-33BB4FB29E7B', 1, 'OrganizationToOrganization', 'OrganizationToOrganization')

/* SQL text to insert entity field value with ID 42cbe5a8-ac27-42aa-b0af-0218573d30dd */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('42cbe5a8-ac27-42aa-b0af-0218573d30dd', 'ACAEC8F6-49F4-47C0-983D-33BB4FB29E7B', 2, 'PersonToOrganization', 'PersonToOrganization')

/* SQL text to insert entity field value with ID 1f80325c-a9f1-4eac-aff5-2d071efe77b7 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('1f80325c-a9f1-4eac-aff5-2d071efe77b7', 'ACAEC8F6-49F4-47C0-983D-33BB4FB29E7B', 3, 'PersonToPerson', 'PersonToPerson')

/* SQL text to update ValueListType for entity field ID ACAEC8F6-49F4-47C0-983D-33BB4FB29E7B */
UPDATE [${flyway:defaultSchema}].EntityField SET ValueListType='List' WHERE ID='ACAEC8F6-49F4-47C0-983D-33BB4FB29E7B'

/* SQL text to insert entity field value with ID facaa0a3-9463-47ce-975c-e3d00717335c */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('facaa0a3-9463-47ce-975c-e3d00717335c', '57F78065-E9DB-4D2C-A2F8-524D4F15D902', 1, 'Active', 'Active')

/* SQL text to insert entity field value with ID 51f1886c-560e-4321-a9bd-f7cb311a22ea */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('51f1886c-560e-4321-a9bd-f7cb311a22ea', '57F78065-E9DB-4D2C-A2F8-524D4F15D902', 2, 'Deceased', 'Deceased')

/* SQL text to insert entity field value with ID 5d5c5c1c-8314-493a-a647-13eda26e4120 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('5d5c5c1c-8314-493a-a647-13eda26e4120', '57F78065-E9DB-4D2C-A2F8-524D4F15D902', 3, 'Inactive', 'Inactive')

/* SQL text to update ValueListType for entity field ID 57F78065-E9DB-4D2C-A2F8-524D4F15D902 */
UPDATE [${flyway:defaultSchema}].EntityField SET ValueListType='List' WHERE ID='57F78065-E9DB-4D2C-A2F8-524D4F15D902'

/* SQL text to insert entity field value with ID 615f2381-74ed-428f-91d5-f0d1272f5ad2 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('615f2381-74ed-428f-91d5-f0d1272f5ad2', '8620F795-6511-4715-A823-D3C905AF3ECC', 1, 'Active', 'Active')

/* SQL text to insert entity field value with ID ebdcd22f-fb23-48fb-8905-7f66811f3532 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('ebdcd22f-fb23-48fb-8905-7f66811f3532', '8620F795-6511-4715-A823-D3C905AF3ECC', 2, 'Dissolved', 'Dissolved')

/* SQL text to insert entity field value with ID 23179677-9fbd-4ad5-8374-895734b795b7 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('23179677-9fbd-4ad5-8374-895734b795b7', '8620F795-6511-4715-A823-D3C905AF3ECC', 3, 'Inactive', 'Inactive')

/* SQL text to update ValueListType for entity field ID 8620F795-6511-4715-A823-D3C905AF3ECC */
UPDATE [${flyway:defaultSchema}].EntityField SET ValueListType='List' WHERE ID='8620F795-6511-4715-A823-D3C905AF3ECC'

/* SQL text to insert entity field value with ID 6dcd32d9-9534-4295-9de1-204f961127e8 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('6dcd32d9-9534-4295-9de1-204f961127e8', '80B0C5C4-915A-4E72-9978-74CB33902F08', 1, 'Active', 'Active')

/* SQL text to insert entity field value with ID 58ff360b-46f2-458d-b66c-95768c6e95e7 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('58ff360b-46f2-458d-b66c-95768c6e95e7', '80B0C5C4-915A-4E72-9978-74CB33902F08', 2, 'Ended', 'Ended')

/* SQL text to insert entity field value with ID 71e4f1ea-0f72-4b43-befe-7a1de14eed47 */
INSERT INTO [${flyway:defaultSchema}].EntityFieldValue
                                       (ID, EntityFieldID, Sequence, Value, Code)
                                    VALUES
                                       ('71e4f1ea-0f72-4b43-befe-7a1de14eed47', '80B0C5C4-915A-4E72-9978-74CB33902F08', 3, 'Inactive', 'Inactive')

/* SQL text to update ValueListType for entity field ID 80B0C5C4-915A-4E72-9978-74CB33902F08 */
UPDATE [${flyway:defaultSchema}].EntityField SET ValueListType='List' WHERE ID='80B0C5C4-915A-4E72-9978-74CB33902F08'


/* Create Entity Relationship: MJ.BizApps.Common: Contact Types -> MJ.BizApps.Common: Contact Methods (One To Many via ContactTypeID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '2d050398-8dba-49b2-848e-4a88a9191eff'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('2d050398-8dba-49b2-848e-4a88a9191eff', '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', '32C45078-D33B-4760-9BE5-0DF7F483F591', 'ContactTypeID', 'One To Many', 1, 1, 'MJ.BizApps.Common: Contact Methods', 1);
   END
                              
/* Create Entity Relationship: MJ: Entities -> MJ.BizApps.Common: Address Links (One To Many via EntityID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '2a078d6b-5ef4-4eba-b166-57a295bb304d'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('2a078d6b-5ef4-4eba-b166-57a295bb304d', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7', 'EntityID', 'One To Many', 1, 1, 'MJ.BizApps.Common: Address Links', 1);
   END
                              
/* Create Entity Relationship: MJ: Users -> MJ.BizApps.Common: People (One To Many via LinkedUserID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '4b115dcc-dbc1-4c6f-b45c-3ae939cde7b8'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('4b115dcc-dbc1-4c6f-b45c-3ae939cde7b8', 'E1238F34-2837-EF11-86D4-6045BDEE16E6', '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', 'LinkedUserID', 'One To Many', 1, 1, 'MJ.BizApps.Common: People', 1);
   END
                              
/* Create Entity Relationship: MJ.BizApps.Common: Organizations -> MJ.BizApps.Common: Contact Methods (One To Many via OrganizationID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '4d7a3d74-4e29-4fea-98f1-2d870a226a63'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('4d7a3d74-4e29-4fea-98f1-2d870a226a63', 'C70448F9-9792-41D7-A82C-784B66429D54', '32C45078-D33B-4760-9BE5-0DF7F483F591', 'OrganizationID', 'One To Many', 1, 1, 'MJ.BizApps.Common: Contact Methods', 2);
   END
                              
/* Create Entity Relationship: MJ.BizApps.Common: Organizations -> MJ.BizApps.Common: Organizations (One To Many via ParentID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '9d170fc9-ece8-4a03-a857-54ccaf628836'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('9d170fc9-ece8-4a03-a857-54ccaf628836', 'C70448F9-9792-41D7-A82C-784B66429D54', 'C70448F9-9792-41D7-A82C-784B66429D54', 'ParentID', 'One To Many', 1, 1, 'MJ.BizApps.Common: Organizations', 1);
   END
                              


/* Create Entity Relationship: MJ.BizApps.Common: Organizations -> MJ.BizApps.Common: Relationships (One To Many via ToOrganizationID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = 'c1f0a217-026c-44c6-8724-ca4991dc0258'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('c1f0a217-026c-44c6-8724-ca4991dc0258', 'C70448F9-9792-41D7-A82C-784B66429D54', '709CA9DA-B124-4155-BE39-E857EF672D82', 'ToOrganizationID', 'One To Many', 1, 1, 'MJ.BizApps.Common: Relationships', 1);
   END
                              
/* Create Entity Relationship: MJ.BizApps.Common: Organizations -> MJ.BizApps.Common: Relationships (One To Many via FromOrganizationID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '1997a9d1-921a-4af2-9f04-a42bd22163a4'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('1997a9d1-921a-4af2-9f04-a42bd22163a4', 'C70448F9-9792-41D7-A82C-784B66429D54', '709CA9DA-B124-4155-BE39-E857EF672D82', 'FromOrganizationID', 'One To Many', 1, 1, 'MJ.BizApps.Common: Relationships', 2);
   END
                              
/* Create Entity Relationship: MJ.BizApps.Common: Relationship Types -> MJ.BizApps.Common: Relationships (One To Many via RelationshipTypeID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '978706e5-7e49-45de-b904-c917571f6f67'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('978706e5-7e49-45de-b904-c917571f6f67', '5F214F43-109C-407D-B505-7B0B3B72ACB5', '709CA9DA-B124-4155-BE39-E857EF672D82', 'RelationshipTypeID', 'One To Many', 1, 1, 'MJ.BizApps.Common: Relationships', 3);
   END
                              
/* Create Entity Relationship: MJ.BizApps.Common: Address Types -> MJ.BizApps.Common: Address Links (One To Many via AddressTypeID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '9013b0db-bd0e-463a-9861-bd587744e75a'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('9013b0db-bd0e-463a-9861-bd587744e75a', '7A7245D1-2316-44A4-B147-A50FF19F5942', 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7', 'AddressTypeID', 'One To Many', 1, 1, 'MJ.BizApps.Common: Address Links', 2);
   END
                              
/* Create Entity Relationship: MJ.BizApps.Common: People -> MJ.BizApps.Common: Relationships (One To Many via ToPersonID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = 'e5d30b7e-fcbc-49eb-97a7-28e12bd604c9'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('e5d30b7e-fcbc-49eb-97a7-28e12bd604c9', '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', '709CA9DA-B124-4155-BE39-E857EF672D82', 'ToPersonID', 'One To Many', 1, 1, 'MJ.BizApps.Common: Relationships', 4);
   END
                              


/* Create Entity Relationship: MJ.BizApps.Common: People -> MJ.BizApps.Common: Contact Methods (One To Many via PersonID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '1f63a0cf-3f16-4eac-a241-845c633779cc'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('1f63a0cf-3f16-4eac-a241-845c633779cc', '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', '32C45078-D33B-4760-9BE5-0DF7F483F591', 'PersonID', 'One To Many', 1, 1, 'MJ.BizApps.Common: Contact Methods', 3);
   END
                              
/* Create Entity Relationship: MJ.BizApps.Common: People -> MJ.BizApps.Common: Relationships (One To Many via FromPersonID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = 'c37cbf7a-9f75-4210-b2c5-7b64f8e9480d'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('c37cbf7a-9f75-4210-b2c5-7b64f8e9480d', '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', '709CA9DA-B124-4155-BE39-E857EF672D82', 'FromPersonID', 'One To Many', 1, 1, 'MJ.BizApps.Common: Relationships', 5);
   END
                              
/* Create Entity Relationship: MJ.BizApps.Common: Organization Types -> MJ.BizApps.Common: Organizations (One To Many via OrganizationTypeID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = '654b6801-e8d4-4c42-bb6b-5a5784dbbd5b'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('654b6801-e8d4-4c42-bb6b-5a5784dbbd5b', 'A77D9725-4871-484B-99F0-F65461D7ABEE', 'C70448F9-9792-41D7-A82C-784B66429D54', 'OrganizationTypeID', 'One To Many', 1, 1, 'MJ.BizApps.Common: Organizations', 2);
   END
                              
/* Create Entity Relationship: MJ.BizApps.Common: Addresses -> MJ.BizApps.Common: Address Links (One To Many via AddressID) */
   IF NOT EXISTS (
      SELECT 1
      FROM [${flyway:defaultSchema}].EntityRelationship
      WHERE ID = 'ce979efc-9636-4d0b-94f8-48e0ca9ff33b'
   )
   BEGIN
      INSERT INTO ${flyway:defaultSchema}.EntityRelationship (ID, EntityID, RelatedEntityID, RelatedEntityJoinField, Type, BundleInAPI, DisplayInForm, DisplayName, Sequence)
                              VALUES ('ce979efc-9636-4d0b-94f8-48e0ca9ff33b', '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E', 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7', 'AddressID', 'One To Many', 1, 1, 'MJ.BizApps.Common: Address Links', 3);
   END
                              

/* Index for Foreign Keys for AddressLink */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Address Links
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

/* SQL text to update entity field related entity name field map for entity field ID 63D14E61-C4BE-4369-A775-7A93A14A6432 */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='63D14E61-C4BE-4369-A775-7A93A14A6432',
         @RelatedEntityNameFieldMap='Entity'

/* Index for Foreign Keys for AddressType */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Address Types
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------


/* Index for Foreign Keys for Address */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Addresses
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------


/* Index for Foreign Keys for ContactMethod */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Contact Methods
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

/* SQL text to update entity field related entity name field map for entity field ID 0EC64524-99CD-484D-BF82-0E422D0C9903 */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='0EC64524-99CD-484D-BF82-0E422D0C9903',
         @RelatedEntityNameFieldMap='Organization'

/* Index for Foreign Keys for ContactType */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Contact Types
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------


/* Base View SQL for MJ.BizApps.Common: Address Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Address Types
-- Item: vwAddressTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ.BizApps.Common: Address Types
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
    

/* Base View Permissions SQL for MJ.BizApps.Common: Address Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Address Types
-- Item: Permissions for vwAddressTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwAddressTypes] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for MJ.BizApps.Common: Address Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Address Types
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
    @IconClass nvarchar(100),
    @DefaultRank int = NULL,
    @IsActive bit = NULL
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
                [IconClass],
                [DefaultRank],
                [IsActive]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Name,
                @Description,
                @IconClass,
                ISNULL(@DefaultRank, 100),
                ISNULL(@IsActive, 1)
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[AddressType]
            (
                [Name],
                [Description],
                [IconClass],
                [DefaultRank],
                [IsActive]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                @Description,
                @IconClass,
                ISNULL(@DefaultRank, 100),
                ISNULL(@IsActive, 1)
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwAddressTypes] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddressType] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for MJ.BizApps.Common: Address Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddressType] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for MJ.BizApps.Common: Address Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Address Types
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
    @IconClass nvarchar(100),
    @DefaultRank int,
    @IsActive bit
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[AddressType]
    SET
        [Name] = @Name,
        [Description] = @Description,
        [IconClass] = @IconClass,
        [DefaultRank] = @DefaultRank,
        [IsActive] = @IsActive
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
        

/* spUpdate Permissions for MJ.BizApps.Common: Address Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddressType] TO [cdp_Developer], [cdp_Integration]



/* Base View SQL for MJ.BizApps.Common: Addresses */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Addresses
-- Item: vwAddresses
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ.BizApps.Common: Addresses
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
    

/* Base View Permissions SQL for MJ.BizApps.Common: Addresses */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Addresses
-- Item: Permissions for vwAddresses
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwAddresses] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for MJ.BizApps.Common: Addresses */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Addresses
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
    

/* spCreate Permissions for MJ.BizApps.Common: Addresses */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddress] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for MJ.BizApps.Common: Addresses */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Addresses
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
        

/* spUpdate Permissions for MJ.BizApps.Common: Addresses */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddress] TO [cdp_Developer], [cdp_Integration]



/* Base View SQL for MJ.BizApps.Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Contact Types
-- Item: vwContactTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ.BizApps.Common: Contact Types
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
    

/* Base View Permissions SQL for MJ.BizApps.Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Contact Types
-- Item: Permissions for vwContactTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwContactTypes] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for MJ.BizApps.Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Contact Types
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
    @IconClass nvarchar(100),
    @DisplayRank int = NULL,
    @IsActive bit = NULL
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
                [IconClass],
                [DisplayRank],
                [IsActive]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Name,
                @Description,
                @IconClass,
                ISNULL(@DisplayRank, 100),
                ISNULL(@IsActive, 1)
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[ContactType]
            (
                [Name],
                [Description],
                [IconClass],
                [DisplayRank],
                [IsActive]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                @Description,
                @IconClass,
                ISNULL(@DisplayRank, 100),
                ISNULL(@IsActive, 1)
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwContactTypes] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateContactType] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for MJ.BizApps.Common: Contact Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateContactType] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for MJ.BizApps.Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Contact Types
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
    @IconClass nvarchar(100),
    @DisplayRank int,
    @IsActive bit
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[ContactType]
    SET
        [Name] = @Name,
        [Description] = @Description,
        [IconClass] = @IconClass,
        [DisplayRank] = @DisplayRank,
        [IsActive] = @IsActive
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
        

/* spUpdate Permissions for MJ.BizApps.Common: Contact Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateContactType] TO [cdp_Developer], [cdp_Integration]



/* spDelete SQL for MJ.BizApps.Common: Address Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Address Types
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
    

/* spDelete Permissions for MJ.BizApps.Common: Address Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddressType] TO [cdp_Integration]



/* spDelete SQL for MJ.BizApps.Common: Addresses */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Addresses
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
    

/* spDelete Permissions for MJ.BizApps.Common: Addresses */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddress] TO [cdp_Integration]



/* spDelete SQL for MJ.BizApps.Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Contact Types
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
    

/* spDelete Permissions for MJ.BizApps.Common: Contact Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteContactType] TO [cdp_Integration]



/* SQL text to update entity field related entity name field map for entity field ID 5C42F4D1-4ABD-4CC6-B5DA-A164D5CBA7A1 */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='5C42F4D1-4ABD-4CC6-B5DA-A164D5CBA7A1',
         @RelatedEntityNameFieldMap='ContactType'

/* SQL text to update entity field related entity name field map for entity field ID 633EAB3F-8828-4DB0-9B19-6AD04A75CB83 */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='633EAB3F-8828-4DB0-9B19-6AD04A75CB83',
         @RelatedEntityNameFieldMap='AddressType'

/* Base View SQL for MJ.BizApps.Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Contact Methods
-- Item: vwContactMethods
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ.BizApps.Common: Contact Methods
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
    

/* Base View Permissions SQL for MJ.BizApps.Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Contact Methods
-- Item: Permissions for vwContactMethods
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwContactMethods] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for MJ.BizApps.Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Contact Methods
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
    

/* spCreate Permissions for MJ.BizApps.Common: Contact Methods */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateContactMethod] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for MJ.BizApps.Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Contact Methods
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
        

/* spUpdate Permissions for MJ.BizApps.Common: Contact Methods */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateContactMethod] TO [cdp_Developer], [cdp_Integration]



/* spDelete SQL for MJ.BizApps.Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Contact Methods
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
    

/* spDelete Permissions for MJ.BizApps.Common: Contact Methods */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteContactMethod] TO [cdp_Integration]



/* Base View SQL for MJ.BizApps.Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Address Links
-- Item: vwAddressLinks
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ.BizApps.Common: Address Links
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
    

/* Base View Permissions SQL for MJ.BizApps.Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Address Links
-- Item: Permissions for vwAddressLinks
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwAddressLinks] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for MJ.BizApps.Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Address Links
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
    

/* spCreate Permissions for MJ.BizApps.Common: Address Links */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddressLink] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for MJ.BizApps.Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Address Links
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
        

/* spUpdate Permissions for MJ.BizApps.Common: Address Links */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddressLink] TO [cdp_Developer], [cdp_Integration]



/* spDelete SQL for MJ.BizApps.Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Address Links
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
    

/* spDelete Permissions for MJ.BizApps.Common: Address Links */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddressLink] TO [cdp_Integration]



/* Index for Foreign Keys for OrganizationType */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Organization Types
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------


/* Index for Foreign Keys for Organization */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Organizations
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

/* Root ID Function SQL for MJ.BizApps.Common: Organizations.ParentID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Organizations
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


/* SQL text to update entity field related entity name field map for entity field ID 9E6FCD82-BCDF-443A-A87D-E16EEF761068 */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='9E6FCD82-BCDF-443A-A87D-E16EEF761068',
         @RelatedEntityNameFieldMap='OrganizationType'

/* Index for Foreign Keys for Person */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: People
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

/* SQL text to update entity field related entity name field map for entity field ID 79F1EEAB-367E-4B45-A9B8-75639F6410CB */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='79F1EEAB-367E-4B45-A9B8-75639F6410CB',
         @RelatedEntityNameFieldMap='LinkedUser'

/* Index for Foreign Keys for RelationshipType */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Relationship Types
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------


/* Index for Foreign Keys for Relationship */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Relationships
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

/* SQL text to update entity field related entity name field map for entity field ID 4BFFAFBD-BF4E-4907-963B-95733C670B7E */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='4BFFAFBD-BF4E-4907-963B-95733C670B7E',
         @RelatedEntityNameFieldMap='RelationshipType'

/* Base View SQL for MJ.BizApps.Common: Organization Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Organization Types
-- Item: vwOrganizationTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ.BizApps.Common: Organization Types
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
    

/* Base View Permissions SQL for MJ.BizApps.Common: Organization Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Organization Types
-- Item: Permissions for vwOrganizationTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizationTypes] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for MJ.BizApps.Common: Organization Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Organization Types
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
    @IconClass nvarchar(100),
    @DisplayRank int = NULL,
    @IsActive bit = NULL
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
                [IconClass],
                [DisplayRank],
                [IsActive]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Name,
                @Description,
                @IconClass,
                ISNULL(@DisplayRank, 100),
                ISNULL(@IsActive, 1)
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[OrganizationType]
            (
                [Name],
                [Description],
                [IconClass],
                [DisplayRank],
                [IsActive]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                @Description,
                @IconClass,
                ISNULL(@DisplayRank, 100),
                ISNULL(@IsActive, 1)
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizationTypes] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateOrganizationType] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for MJ.BizApps.Common: Organization Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateOrganizationType] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for MJ.BizApps.Common: Organization Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Organization Types
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
    @IconClass nvarchar(100),
    @DisplayRank int,
    @IsActive bit
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[OrganizationType]
    SET
        [Name] = @Name,
        [Description] = @Description,
        [IconClass] = @IconClass,
        [DisplayRank] = @DisplayRank,
        [IsActive] = @IsActive
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
        

/* spUpdate Permissions for MJ.BizApps.Common: Organization Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateOrganizationType] TO [cdp_Developer], [cdp_Integration]



/* Base View SQL for MJ.BizApps.Common: Relationship Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Relationship Types
-- Item: vwRelationshipTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ.BizApps.Common: Relationship Types
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
    

/* Base View Permissions SQL for MJ.BizApps.Common: Relationship Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Relationship Types
-- Item: Permissions for vwRelationshipTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwRelationshipTypes] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for MJ.BizApps.Common: Relationship Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Relationship Types
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
    @ReverseLabel nvarchar(100),
    @IsActive bit = NULL
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
                [ReverseLabel],
                [IsActive]
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
                @ReverseLabel,
                ISNULL(@IsActive, 1)
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
                [ReverseLabel],
                [IsActive]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                @Description,
                @Category,
                ISNULL(@IsDirectional, 1),
                @ForwardLabel,
                @ReverseLabel,
                ISNULL(@IsActive, 1)
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwRelationshipTypes] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateRelationshipType] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for MJ.BizApps.Common: Relationship Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateRelationshipType] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for MJ.BizApps.Common: Relationship Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Relationship Types
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
    @ReverseLabel nvarchar(100),
    @IsActive bit
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
        [ReverseLabel] = @ReverseLabel,
        [IsActive] = @IsActive
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
        

/* spUpdate Permissions for MJ.BizApps.Common: Relationship Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateRelationshipType] TO [cdp_Developer], [cdp_Integration]



/* spDelete SQL for MJ.BizApps.Common: Organization Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Organization Types
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
    

/* spDelete Permissions for MJ.BizApps.Common: Organization Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteOrganizationType] TO [cdp_Integration]



/* spDelete SQL for MJ.BizApps.Common: Relationship Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Relationship Types
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
    

/* spDelete Permissions for MJ.BizApps.Common: Relationship Types */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteRelationshipType] TO [cdp_Integration]



/* Base View SQL for MJ.BizApps.Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: People
-- Item: vwPeople
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ.BizApps.Common: People
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
    

/* Base View Permissions SQL for MJ.BizApps.Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: People
-- Item: Permissions for vwPeople
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwPeople] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for MJ.BizApps.Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: People
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
    

/* spCreate Permissions for MJ.BizApps.Common: People */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreatePerson] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for MJ.BizApps.Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: People
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
        

/* spUpdate Permissions for MJ.BizApps.Common: People */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdatePerson] TO [cdp_Developer], [cdp_Integration]



/* spDelete SQL for MJ.BizApps.Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: People
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
    

/* spDelete Permissions for MJ.BizApps.Common: People */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeletePerson] TO [cdp_Integration]



/* SQL text to update entity field related entity name field map for entity field ID D78A9DB0-2ED9-4D73-A408-24B0E03981C9 */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='D78A9DB0-2ED9-4D73-A408-24B0E03981C9',
         @RelatedEntityNameFieldMap='Parent'

/* SQL text to update entity field related entity name field map for entity field ID 6D46F59F-FF3F-4351-A697-E7DB414A1E3E */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='6D46F59F-FF3F-4351-A697-E7DB414A1E3E',
         @RelatedEntityNameFieldMap='FromOrganization'

/* Base View SQL for MJ.BizApps.Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Organizations
-- Item: vwOrganizations
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ.BizApps.Common: Organizations
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
    

/* Base View Permissions SQL for MJ.BizApps.Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Organizations
-- Item: Permissions for vwOrganizations
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizations] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for MJ.BizApps.Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Organizations
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
    

/* spCreate Permissions for MJ.BizApps.Common: Organizations */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateOrganization] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for MJ.BizApps.Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Organizations
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
        

/* spUpdate Permissions for MJ.BizApps.Common: Organizations */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateOrganization] TO [cdp_Developer], [cdp_Integration]



/* spDelete SQL for MJ.BizApps.Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Organizations
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
    

/* spDelete Permissions for MJ.BizApps.Common: Organizations */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteOrganization] TO [cdp_Integration]



/* SQL text to update entity field related entity name field map for entity field ID 42EBA3CE-7DDB-4149-BE93-E245F351B963 */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='42EBA3CE-7DDB-4149-BE93-E245F351B963',
         @RelatedEntityNameFieldMap='ToOrganization'

/* Base View SQL for MJ.BizApps.Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Relationships
-- Item: vwRelationships
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ.BizApps.Common: Relationships
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
    

/* Base View Permissions SQL for MJ.BizApps.Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Relationships
-- Item: Permissions for vwRelationships
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwRelationships] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for MJ.BizApps.Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Relationships
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
    

/* spCreate Permissions for MJ.BizApps.Common: Relationships */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateRelationship] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for MJ.BizApps.Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Relationships
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
        

/* spUpdate Permissions for MJ.BizApps.Common: Relationships */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateRelationship] TO [cdp_Developer], [cdp_Integration]



/* spDelete SQL for MJ.BizApps.Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Relationships
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
    

/* spDelete Permissions for MJ.BizApps.Common: Relationships */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteRelationship] TO [cdp_Integration]



/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '86227274-0d90-4f5e-b43f-8b303ebe4844'  OR 
               (EntityID = '32C45078-D33B-4760-9BE5-0DF7F483F591' AND Name = 'Organization')
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
            '86227274-0d90-4f5e-b43f-8b303ebe4844',
            '32C45078-D33B-4760-9BE5-0DF7F483F591', -- Entity: MJ.BizApps.Common: Contact Methods
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
         WHERE ID = 'f261cf20-990d-44df-b604-a603a9892a90'  OR 
               (EntityID = '32C45078-D33B-4760-9BE5-0DF7F483F591' AND Name = 'ContactType')
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
            'f261cf20-990d-44df-b604-a603a9892a90',
            '32C45078-D33B-4760-9BE5-0DF7F483F591', -- Entity: MJ.BizApps.Common: Contact Methods
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
         WHERE ID = '311aec01-4c33-4cef-9898-bd3425834c3c'  OR 
               (EntityID = 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7' AND Name = 'Entity')
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
            '311aec01-4c33-4cef-9898-bd3425834c3c',
            'F2FC2E85-B210-43A9-8565-290AD9D0C6E7', -- Entity: MJ.BizApps.Common: Address Links
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
         WHERE ID = 'e79c20c4-b9d9-433f-bd0e-5134829f1a25'  OR 
               (EntityID = 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7' AND Name = 'AddressType')
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
            'e79c20c4-b9d9-433f-bd0e-5134829f1a25',
            'F2FC2E85-B210-43A9-8565-290AD9D0C6E7', -- Entity: MJ.BizApps.Common: Address Links
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
         WHERE ID = 'efd20ada-e18b-41dc-8f4f-f4ed58fe0165'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'OrganizationType')
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
            'efd20ada-e18b-41dc-8f4f-f4ed58fe0165',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
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
         WHERE ID = '97844d3b-a436-4ce7-8246-976ba9ff9a87'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'Parent')
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
            '97844d3b-a436-4ce7-8246-976ba9ff9a87',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
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
         WHERE ID = '8f929c6b-ab7e-438c-839f-3cb4357bb69c'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'RootParentID')
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
            '8f929c6b-ab7e-438c-839f-3cb4357bb69c',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
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
         WHERE ID = '5f857a6e-befc-4c29-bc2b-fd6876c269b2'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'LinkedUser')
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
            '5f857a6e-befc-4c29-bc2b-fd6876c269b2',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
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

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '07c7d2b2-8916-4220-961f-076c298dd2c9'  OR 
               (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = 'RelationshipType')
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
            '07c7d2b2-8916-4220-961f-076c298dd2c9',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ.BizApps.Common: Relationships
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
         WHERE ID = 'db499ee6-8fc5-4fc7-bc36-f758d5b76bcb'  OR 
               (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = 'FromOrganization')
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
            'db499ee6-8fc5-4fc7-bc36-f758d5b76bcb',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ.BizApps.Common: Relationships
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
         WHERE ID = 'e9b40366-4907-44c0-99b1-502e35d6e345'  OR 
               (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = 'ToOrganization')
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
            'e9b40366-4907-44c0-99b1-502e35d6e345',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ.BizApps.Common: Relationships
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

/* Set field properties for entity */

            UPDATE [${flyway:defaultSchema}].EntityField
            SET IsNameField = 1
            WHERE ID = '8C5ED1B2-107E-4195-9E05-AC25C452971D'
            AND AutoUpdateIsNameField = 1
         

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '8C5ED1B2-107E-4195-9E05-AC25C452971D'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '0C71E92A-D747-4302-B17F-78C92930D2CE'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'D43ECA52-4B7A-434E-92CE-C3FF69824306'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '65ACAC26-5F6C-4A67-8559-BD7C0943A925'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '63BB48D1-67C2-4CD9-BDD9-F86F6154F77C'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '8C5ED1B2-107E-4195-9E05-AC25C452971D'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'C6515A57-DACE-4684-AD9D-03297E60CDE4'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '0C71E92A-D747-4302-B17F-78C92930D2CE'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '65ACAC26-5F6C-4A67-8559-BD7C0943A925'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set field properties for entity */

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '255FCD46-E0E2-4B77-AB45-0CCDF6181E36'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '971C65DD-9F0C-4B46-AB06-8D5A3E47CBC3'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'F70D2734-AF27-4969-9C8B-B51259E71F8F'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '255FCD46-E0E2-4B77-AB45-0CCDF6181E36'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set field properties for entity */

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '8096A2BD-684F-44E0-B26B-424F52619220'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '00865ED9-B98D-4F58-8C5D-022AC87FF8E7'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '45829CD8-C67D-4527-B25E-4390889EEB85'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '9FFF0788-F1A4-4971-9B53-2FEF0407880A'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '8096A2BD-684F-44E0-B26B-424F52619220'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set field properties for entity */

            UPDATE [${flyway:defaultSchema}].EntityField
            SET IsNameField = 1
            WHERE ID = '77C20975-15E3-4A89-9414-3A829A5EA249'
            AND AutoUpdateIsNameField = 1
         

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '77C20975-15E3-4A89-9414-3A829A5EA249'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'CBA68064-C466-460E-AD1B-89256634A753'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '9AAA02E5-C378-43BE-A1B3-6EF7355CDF22'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'F261CF20-990D-44DF-B604-A603A9892A90'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '77C20975-15E3-4A89-9414-3A829A5EA249'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'CBA68064-C466-460E-AD1B-89256634A753'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '86227274-0D90-4F5E-B43F-8B303EBE4844'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'F261CF20-990D-44DF-B604-A603A9892A90'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set field properties for entity */

            UPDATE [${flyway:defaultSchema}].EntityField
            SET IsNameField = 1
            WHERE ID = 'E79C20C4-B9D9-433F-BD0E-5134829F1A25'
            AND AutoUpdateIsNameField = 1
         

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '8E6C198E-773E-4582-B020-7C7A9716B2C8'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '80D85088-71D2-42F1-A9A3-086EE3F96B3D'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'CF61A8C5-2F33-4756-AD71-257504E7B4E3'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '311AEC01-4C33-4CEF-9898-BD3425834C3C'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'E79C20C4-B9D9-433F-BD0E-5134829F1A25'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '8E6C198E-773E-4582-B020-7C7A9716B2C8'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '311AEC01-4C33-4CEF-9898-BD3425834C3C'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'E79C20C4-B9D9-433F-BD0E-5134829F1A25'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set categories for 11 fields */

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C7EF895A-84E9-4388-8F9D-4E60A73CE67D' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.AddressID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Linkage Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Address',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'EFFA8DD0-9FCE-4504-83A8-A1415C912621' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.EntityID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Linkage Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Entity',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '63D14E61-C4BE-4369-A775-7A93A14A6432' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.RecordID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Linkage Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8E6C198E-773E-4582-B020-7C7A9716B2C8' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.Entity 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Linkage Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Entity Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '311AEC01-4C33-4CEF-9898-BD3425834C3C' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.AddressTypeID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Preferences',
   GeneratedFormSection = 'Category',
   DisplayName = 'Address Type',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '633EAB3F-8828-4DB0-9B19-6AD04A75CB83' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.AddressType 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Preferences',
   GeneratedFormSection = 'Category',
   DisplayName = 'Address Type Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E79C20C4-B9D9-433F-BD0E-5134829F1A25' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.IsPrimary 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Preferences',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '80D85088-71D2-42F1-A9A3-086EE3F96B3D' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.Rank 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Preferences',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'CF61A8C5-2F33-4756-AD71-257504E7B4E3' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8D738E18-A0BA-45EF-88C0-D8BC29D8D877' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B3518E84-62FF-488B-963B-4E7076932A8F' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-link */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-link', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('7fd53db4-1494-48e2-898e-2e0dff273160', 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7', 'FieldCategoryInfo', '{"Linkage Details":{"icon":"fa fa-link","description":"Fields defining the connection between a specific record and an address record."},"Address Preferences":{"icon":"fa fa-sliders-h","description":"Settings for how this address is categorized and prioritized for the linked record."},"System Metadata":{"icon":"fa fa-cog","description":"System-managed audit and tracking fields."}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('2cef1622-be9a-4935-928a-99acd5df2f79', 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7', 'FieldCategoryIcons', '{"Linkage Details":"fa fa-link","Address Preferences":"fa fa-sliders-h","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=0 for NEW entity (category: junction, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 0, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7'
      

/* Set categories for 8 fields */

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Types.Name 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '1D142A23-E13C-4852-9DD9-A896774C3BDA' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Types.Description 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8096A2BD-684F-44E0-B26B-424F52619220' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Types.IconClass 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'UI Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '00865ED9-B98D-4F58-8C5D-022AC87FF8E7' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Types.DisplayRank 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'UI Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '45829CD8-C67D-4527-B25E-4390889EEB85' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Types.IsActive 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'UI Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '9FFF0788-F1A4-4971-9B53-2FEF0407880A' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Types.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C40C2682-A2FA-4676-833B-75030293220C' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Types.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '86C73C1A-89CD-4326-A8BB-145E6B0B2F4A' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Types.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'A005A7DB-76EC-4DDF-8482-7951BE69B165' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-address-card */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-address-card', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('449a8f9f-5278-41e7-b16b-8b3b44fb1d5b', '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', 'FieldCategoryInfo', '{"Type Definition":{"icon":"fa fa-tag","description":"Core identification and descriptive information for the contact method"},"UI Configuration":{"icon":"fa fa-desktop","description":"Settings controlling the visual presentation, sorting, and availability in the application"},"System Metadata":{"icon":"fa fa-cog","description":"System-managed audit and tracking fields"}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('5d6d1806-aa02-4e9f-b0be-04b1faa07d03', '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', 'FieldCategoryIcons', '{"Type Definition":"fa fa-tag","UI Configuration":"fa fa-desktop","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=0 for NEW entity (category: reference, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 0, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5'
      

/* Set categories for 12 fields */

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Addresses.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'BA3E4FAE-198F-48E4-BD9F-774D8584E259' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Addresses.Line1 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Address Line 1',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8C5ED1B2-107E-4195-9E05-AC25C452971D' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Addresses.Line2 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Address Line 2',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C6515A57-DACE-4684-AD9D-03297E60CDE4' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Addresses.Line3 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Address Line 3',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '9540EDE1-741A-4B6F-B9F0-8DE3C3EDFC31' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Addresses.City 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '0C71E92A-D747-4302-B17F-78C92930D2CE' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Addresses.StateProvince 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'State / Province',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D43ECA52-4B7A-434E-92CE-C3FF69824306' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Addresses.PostalCode 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '65ACAC26-5F6C-4A67-8559-BD7C0943A925' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Addresses.Country 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Address Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '63BB48D1-67C2-4CD9-BDD9-F86F6154F77C' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Addresses.Latitude 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Geographic Location',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Geo',
   CodeType = NULL
WHERE 
   ID = '66D63980-B9B5-47A0-BA8B-6B55977CB60C' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Addresses.Longitude 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Geographic Location',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Geo',
   CodeType = NULL
WHERE 
   ID = 'B03F710E-9199-4986-90BF-3ECE5037D79A' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Addresses.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'CFE3572F-9B12-4D14-BBA5-2F9A8A3B66F0' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Addresses.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '2FF61A35-FB7C-455A-8883-6998B141B095' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-map-marker-alt */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-map-marker-alt', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('dd5d439c-a2ee-4880-973b-e2ac49de7913', '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E', 'FieldCategoryInfo', '{"Address Details":{"icon":"fa fa-home","description":"Physical street address, locality, and regional information"},"Geographic Location":{"icon":"fa fa-globe-americas","description":"Precise geospatial coordinates for mapping and location services"},"System Metadata":{"icon":"fa fa-cog","description":"Internal record identifiers and system-managed audit timestamps"}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('fee02b31-8541-4c15-8ee8-4eb7c94e0aaf', '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E', 'FieldCategoryIcons', '{"Address Details":"fa fa-home","Geographic Location":"fa fa-globe-americas","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=0 for NEW entity (category: supporting, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 0, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E'
      

/* Set categories for 8 fields */

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Types.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '85492901-7593-46E0-8D3D-D50ED60346D5' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Types.Name 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B93AA266-FAA5-461D-B32B-A0F26C698B2C' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Types.Description 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '255FCD46-E0E2-4B77-AB45-0CCDF6181E36' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Types.IsActive 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category',
   DisplayName = 'Active',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'F70D2734-AF27-4969-9C8B-B51259E71F8F' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Types.IconClass 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Display and Sorting',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B0408D09-CF61-4D1D-B951-8E0C5490BD29' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Types.DefaultRank 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Display and Sorting',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '971C65DD-9F0C-4B46-AB06-8D5A3E47CBC3' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Types.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '236794A4-9F6F-472E-9D9F-C77383CF48F5' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Types.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'BCA9BABD-E370-4376-89AC-DCF9340E5734' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-map-signs */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-map-signs', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = '7A7245D1-2316-44A4-B147-A50FF19F5942'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('885b5884-f599-4c9e-8686-0347959cafbc', '7A7245D1-2316-44A4-B147-A50FF19F5942', 'FieldCategoryInfo', '{"Type Definition":{"icon":"fa fa-tag","description":"Core properties defining the address category and its availability status."},"Display and Sorting":{"icon":"fa fa-sort-amount-down-alt","description":"Visual configuration for how this type is represented and ordered in the user interface."},"System Metadata":{"icon":"fa fa-database","description":"Internal identifiers and system-managed audit timestamps."}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('70a2e738-3547-4283-98e0-b31659a5b1b4', '7A7245D1-2316-44A4-B147-A50FF19F5942', 'FieldCategoryIcons', '{"Type Definition":"fa fa-tag","Display and Sorting":"fa fa-sort-amount-down-alt","System Metadata":"fa fa-database"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=0 for NEW entity (category: reference, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 0, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = '7A7245D1-2316-44A4-B147-A50FF19F5942'
      

/* Set categories for 11 fields */

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C66B3740-B4B9-4BA4-B53D-9CDC6A64DAFB' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.PersonID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Linked Record',
   GeneratedFormSection = 'Category',
   DisplayName = 'Person',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B6B5A623-F308-496E-8845-0CF1E92E9D00' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.OrganizationID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Linked Record',
   GeneratedFormSection = 'Category',
   DisplayName = 'Organization',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '0EC64524-99CD-484D-BF82-0E422D0C9903' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.Organization 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Linked Record',
   GeneratedFormSection = 'Category',
   DisplayName = 'Organization Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '86227274-0D90-4F5E-B43F-8B303EBE4844' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.ContactTypeID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Information',
   GeneratedFormSection = 'Category',
   DisplayName = 'Contact Type',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '5C42F4D1-4ABD-4CC6-B5DA-A164D5CBA7A1' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.ContactType 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Information',
   GeneratedFormSection = 'Category',
   DisplayName = 'Contact Type Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'F261CF20-990D-44DF-B604-A603A9892A90' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.Value 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Information',
   GeneratedFormSection = 'Category',
   DisplayName = 'Contact Value',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '77C20975-15E3-4A89-9414-3A829A5EA249' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.Label 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Information',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'CBA68064-C466-460E-AD1B-89256634A753' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.IsPrimary 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Information',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '9AAA02E5-C378-43BE-A1B3-6EF7355CDF22' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'DA376286-2631-4FA3-88DA-1D7BE44312CC' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'FC8DC59A-E1B5-4136-9000-99643E602806' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-address-book */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-address-book', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = '32C45078-D33B-4760-9BE5-0DF7F483F591'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('84c0c552-a6b2-497b-ab9d-76e79ab4a6f8', '32C45078-D33B-4760-9BE5-0DF7F483F591', 'FieldCategoryInfo', '{"Contact Information":{"icon":"fa fa-address-card","description":"Core details of the contact method including the value, type, and priority status."},"Linked Record":{"icon":"fa fa-link","description":"Information regarding the person or organization associated with this contact method."},"System Metadata":{"icon":"fa fa-cog","description":"System-managed audit fields and internal identifiers."}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('0a789d66-d4b6-4db8-ab17-f86f350e4170', '32C45078-D33B-4760-9BE5-0DF7F483F591', 'FieldCategoryIcons', '{"Contact Information":"fa fa-address-card","Linked Record":"fa fa-link","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=0 for NEW entity (category: supporting, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 0, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = '32C45078-D33B-4760-9BE5-0DF7F483F591'
      

/* Set field properties for entity */

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '46B9D67F-3365-47B4-BFE1-6BB932392AE3'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '9A9B834C-1D11-4A4E-98B3-904D048F89DC'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '8620F795-6511-4715-A823-D3C905AF3ECC'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'EFD20ADA-E18B-41DC-8F4F-F4ED58FE0165'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '28DAA78C-FABD-438D-8F24-055987B58B60'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'C8C255E3-D3C1-4F3D-84AA-07B30981FB3E'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '46B9D67F-3365-47B4-BFE1-6BB932392AE3'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '9A9B834C-1D11-4A4E-98B3-904D048F89DC'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '3A676695-4DEE-4A2E-95E5-00A96DE43DAD'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set field properties for entity */

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'E6F5450E-C909-426C-8EA6-968A3A68B6CA'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '8686F717-72AC-4ECB-B3FF-200DA50DF000'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'A6AAF1AB-1212-4066-9A84-2F0DAE43B5BE'
               AND AutoUpdateDefaultInView = 1
            

/* Set field properties for entity */

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'ACAEC8F6-49F4-47C0-983D-33BB4FB29E7B'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '7B610118-FB6D-4CE0-886F-23881C4647E3'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '8221FA5A-6288-48EA-9F5C-92DBBB9020CF'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '60D162BD-2934-4AD7-A74E-F27EF47656D7'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'ACAEC8F6-49F4-47C0-983D-33BB4FB29E7B'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '7B610118-FB6D-4CE0-886F-23881C4647E3'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '8221FA5A-6288-48EA-9F5C-92DBBB9020CF'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set field properties for entity */

            UPDATE [${flyway:defaultSchema}].EntityField
            SET IsNameField = 1
            WHERE ID = '09AD91DA-42C7-44F4-AE71-5AC6E50D7657'
            AND AutoUpdateIsNameField = 1
         

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '4942CBCC-6D0B-44F5-BE38-9D697D02B463'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '09AD91DA-42C7-44F4-AE71-5AC6E50D7657'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '0B992115-7C59-4D6E-A49E-DDAE2D7E9056'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'F6B2A29B-CFE9-410D-9732-3AE2ACF44DC0'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '57F78065-E9DB-4D2C-A2F8-524D4F15D902'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '5F857A6E-BEFC-4C29-BC2B-FD6876C269B2'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '4942CBCC-6D0B-44F5-BE38-9D697D02B463'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '09AD91DA-42C7-44F4-AE71-5AC6E50D7657'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '528500F1-1BB8-4564-A46D-5D45362F3E05'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '27375F71-8F8F-4DAB-8803-96AE73EA28CE'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '0B992115-7C59-4D6E-A49E-DDAE2D7E9056'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'F6B2A29B-CFE9-410D-9732-3AE2ACF44DC0'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '1B312AA3-5CCC-48E6-B034-A8BF437C9A4D'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set field properties for entity */

            UPDATE [${flyway:defaultSchema}].EntityField
            SET IsNameField = 1
            WHERE ID = '2ACBD16A-2A78-4807-8B8D-D0920382EAE6'
            AND AutoUpdateIsNameField = 1
         

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '2ACBD16A-2A78-4807-8B8D-D0920382EAE6'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '62D8A345-E8AC-4EE6-88A9-1959F6258657'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '80B0C5C4-915A-4E72-9978-74CB33902F08'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '07C7D2B2-8916-4220-961F-076C298DD2C9'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'DB499EE6-8FC5-4FC7-BC36-F758D5B76BCB'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'E9B40366-4907-44C0-99B1-502E35D6E345'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '2ACBD16A-2A78-4807-8B8D-D0920382EAE6'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '80B0C5C4-915A-4E72-9978-74CB33902F08'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '07C7D2B2-8916-4220-961F-076C298DD2C9'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'DB499EE6-8FC5-4FC7-BC36-F758D5B76BCB'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'E9B40366-4907-44C0-99B1-502E35D6E345'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set categories for 10 fields */

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationship Types.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '2B7F56C2-C197-45E1-9C79-AF1BFDE094D4' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationship Types.Name 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B0C9F62F-CD73-4EEB-87A8-1F55ADE79539' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationship Types.Description 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8F51E66C-379D-4E06-ACF6-75F98E690782' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationship Types.Category 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'ACAEC8F6-49F4-47C0-983D-33BB4FB29E7B' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationship Types.IsActive 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category',
   DisplayName = 'Active',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '60D162BD-2934-4AD7-A74E-F27EF47656D7' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationship Types.IsDirectional 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Directionality and Labels',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B66F18B2-77DA-4F8E-B9E3-44E9BC6CFC54' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationship Types.ForwardLabel 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Directionality and Labels',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7B610118-FB6D-4CE0-886F-23881C4647E3' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationship Types.ReverseLabel 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Directionality and Labels',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8221FA5A-6288-48EA-9F5C-92DBBB9020CF' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationship Types.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8C67DEB3-E9BA-412D-9875-DD29A5523FCE' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationship Types.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'F28625FD-5F8F-429C-8100-9B9C54205AB0' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-project-diagram */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-project-diagram', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = '5F214F43-109C-407D-B505-7B0B3B72ACB5'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('53e9f46a-8aac-456f-8dcf-5c631cbec3de', '5F214F43-109C-407D-B505-7B0B3B72ACB5', 'FieldCategoryInfo', '{"Type Definition":{"icon":"fa fa-tags","description":"Basic identification, description, and classification of the relationship type"},"Directionality and Labels":{"icon":"fa fa-exchange-alt","description":"Configuration for how relationships are labeled and whether they have a specific direction"},"System Metadata":{"icon":"fa fa-cog","description":"System-managed identifiers and audit timestamps"}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('30e7e163-24ac-44e9-80fd-061defd0e33b', '5F214F43-109C-407D-B505-7B0B3B72ACB5', 'FieldCategoryIcons', '{"Type Definition":"fa fa-tags","Directionality and Labels":"fa fa-exchange-alt","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=0 for NEW entity (category: reference, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 0, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = '5F214F43-109C-407D-B505-7B0B3B72ACB5'
      

/* Set categories for 8 fields */

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organization Types.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '665481AD-FC97-49BE-A98C-AB58AA509F59' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organization Types.Name 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Type Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '82F2CDBC-8793-4FE4-BFCA-380A8A22F41F' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organization Types.Description 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Type Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E6F5450E-C909-426C-8EA6-968A3A68B6CA' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organization Types.IconClass 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Type Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '1D7E13DF-447A-49B8-9A07-1FA0CC058115' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organization Types.DisplayRank 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Type Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8686F717-72AC-4ECB-B3FF-200DA50DF000' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organization Types.IsActive 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Type Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Active',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'A6AAF1AB-1212-4066-9A84-2F0DAE43B5BE' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organization Types.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7C026948-1D22-4D12-B839-A8AF848811BA' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organization Types.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'A2EFB1DA-409F-40FA-BE98-02E394A0F965' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-building */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-building', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = 'A77D9725-4871-484B-99F0-F65461D7ABEE'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('5b1136b8-dd63-4fc0-a319-04b8349847da', 'A77D9725-4871-484B-99F0-F65461D7ABEE', 'FieldCategoryInfo', '{"Organization Type Details":{"icon":"fa fa-list-ul","description":"Configuration for organization categories including labels, descriptions, and UI display settings"},"System Metadata":{"icon":"fa fa-cog","description":"System-managed audit fields and unique identifiers"}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('e0b43043-9502-45c8-9eb4-72fd7adf5f22', 'A77D9725-4871-484B-99F0-F65461D7ABEE', 'FieldCategoryIcons', '{"Organization Type Details":"fa fa-list-ul","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=0 for NEW entity (category: reference, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 0, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = 'A77D9725-4871-484B-99F0-F65461D7ABEE'
      

/* Set categories for 18 fields */

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B194EE44-85DB-4D2A-A76F-9FEB0B5F1AEB' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.Name 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Identity',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '9F465E98-0614-4987-BED8-90B8A1450685' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.LegalName 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Identity',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '28DAA78C-FABD-438D-8F24-055987B58B60' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.OrganizationType 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Identity',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'EFD20ADA-E18B-41DC-8F4F-F4ED58FE0165' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.OrganizationTypeID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Identity',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '9E6FCD82-BCDF-443A-A87D-E16EEF761068' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.FoundedDate 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Identity',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '012CE6D0-F4DC-4921-90D6-C56BE2F3D1B3' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.TaxID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Identity',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '3A676695-4DEE-4A2E-95E5-00A96DE43DAD' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.Status 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Identity',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8620F795-6511-4715-A823-D3C905AF3ECC' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.Description 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Identity',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E1F4B6BC-8465-429B-922C-353F6D1B547C' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.Website 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Information',
   GeneratedFormSection = 'Category',
   ExtendedType = 'URL',
   CodeType = NULL
WHERE 
   ID = 'C8C255E3-D3C1-4F3D-84AA-07B30981FB3E' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.LogoURL 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Information',
   GeneratedFormSection = 'Category',
   ExtendedType = 'URL',
   CodeType = NULL
WHERE 
   ID = '428426B8-70E5-409E-BA30-8AAD6DFAF08E' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.Email 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Information',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Email',
   CodeType = NULL
WHERE 
   ID = '46B9D67F-3365-47B4-BFE1-6BB932392AE3' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.Phone 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Information',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Tel',
   CodeType = NULL
WHERE 
   ID = '9A9B834C-1D11-4A4E-98B3-904D048F89DC' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.Parent 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Hierarchy and Structure',
   GeneratedFormSection = 'Category',
   DisplayName = 'Parent Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '97844D3B-A436-4CE7-8246-976BA9FF9A87' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.ParentID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Hierarchy and Structure',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D78A9DB0-2ED9-4D73-A408-24B0E03981C9' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.RootParentID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Hierarchy and Structure',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8F929C6B-AB7E-438C-839F-3CB4357BB69C' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '36566057-63B7-49B2-A7F2-928C0D798C02' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E219F8E5-5247-425E-BD32-ABD41F8615BD' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-building */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-building', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = 'C70448F9-9792-41D7-A82C-784B66429D54'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('4c3a1db8-34e8-487c-9f87-c37187658d61', 'C70448F9-9792-41D7-A82C-784B66429D54', 'FieldCategoryInfo', '{"Organization Identity":{"icon":"fa fa-id-card","description":"Core identity details including legal names, types, and operational status"},"Contact Information":{"icon":"fa fa-address-book","description":"Communication channels including website, email, and phone details"},"Hierarchy and Structure":{"icon":"fa fa-sitemap","description":"Relationship details defining the organization''s position within a corporate hierarchy"},"System Metadata":{"icon":"fa fa-cog","description":"System-generated audit and identification fields"}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('67187477-2498-46db-bf43-c9363ea694cf', 'C70448F9-9792-41D7-A82C-784B66429D54', 'FieldCategoryIcons', '{"Organization Identity":"fa fa-id-card","Contact Information":"fa fa-address-book","Hierarchy and Structure":"fa fa-sitemap","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=1 for NEW entity (category: primary, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 1, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54'
      

/* Set categories for 19 fields */

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '2A0B54F1-94F8-466C-86C2-931E200258C1' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.FirstName 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Personal Identity',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '4942CBCC-6D0B-44F5-BE38-9D697D02B463' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.LastName 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Personal Identity',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '09AD91DA-42C7-44F4-AE71-5AC6E50D7657' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.MiddleName 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Personal Identity',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '528500F1-1BB8-4564-A46D-5D45362F3E05' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.Prefix 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Personal Identity',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '31733EB2-A6CB-4433-8FAC-F278676855DC' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.Suffix 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Personal Identity',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '9F22EE0D-AC30-4805-89EC-E2C8576615BE' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.PreferredName 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Personal Identity',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '27375F71-8F8F-4DAB-8803-96AE73EA28CE' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.DateOfBirth 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Personal Identity',
   GeneratedFormSection = 'Category',
   DisplayName = 'Date of Birth',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '45090E40-2E5C-4359-B14D-B3D902685C11' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.Gender 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Personal Identity',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '69B0D1A5-C5F5-4F21-9F39-4DCB1C46F76F' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.Title 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Professional and Profile',
   GeneratedFormSection = 'Category',
   DisplayName = 'Job Title',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '0B992115-7C59-4D6E-A49E-DDAE2D7E9056' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.Email 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Professional and Profile',
   GeneratedFormSection = 'Category',
   DisplayName = 'Email Address',
   ExtendedType = 'Email',
   CodeType = NULL
WHERE 
   ID = 'F6B2A29B-CFE9-410D-9732-3AE2ACF44DC0' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.Phone 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Professional and Profile',
   GeneratedFormSection = 'Category',
   DisplayName = 'Phone Number',
   ExtendedType = 'Tel',
   CodeType = NULL
WHERE 
   ID = '1B312AA3-5CCC-48E6-B034-A8BF437C9A4D' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.PhotoURL 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Professional and Profile',
   GeneratedFormSection = 'Category',
   ExtendedType = 'URL',
   CodeType = NULL
WHERE 
   ID = '6BD597E1-05B9-46F6-80FD-5A98D35C4FDD' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.Bio 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Professional and Profile',
   GeneratedFormSection = 'Category',
   DisplayName = 'Biography',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '152F8F83-767B-4B4F-AF92-EF786126DEC0' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.LinkedUserID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Account and Status',
   GeneratedFormSection = 'Category',
   DisplayName = 'Linked User',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '79F1EEAB-367E-4B45-A9B8-75639F6410CB' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.LinkedUser 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Account and Status',
   GeneratedFormSection = 'Category',
   DisplayName = 'Linked User Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '5F857A6E-BEFC-4C29-BC2B-FD6876C269B2' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.Status 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Account and Status',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '57F78065-E9DB-4D2C-A2F8-524D4F15D902' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '86C714E8-B200-4F9F-817A-BAF052AEEE3D' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'CC25D06A-8F7E-433D-9658-500F225D55EC' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-users */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-users', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('1e69ca34-851b-4425-be26-94b9efeb7192', '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', 'FieldCategoryInfo', '{"Personal Identity":{"icon":"fa fa-id-card","description":"Core identification details including name, date of birth, and gender"},"Professional and Profile":{"icon":"fa fa-user-tie","description":"Professional title, contact details, and biographical information"},"Account and Status":{"icon":"fa fa-user-check","description":"Current record status and links to system user accounts"},"System Metadata":{"icon":"fa fa-cog","description":"System-managed audit and tracking fields"}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('c19bfff2-a14c-4e01-9550-809a42ee947f', '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', 'FieldCategoryIcons', '{"Personal Identity":"fa fa-id-card","Professional and Profile":"fa fa-user-tie","Account and Status":"fa fa-user-check","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=1 for NEW entity (category: primary, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 1, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'
      

/* Set categories for 16 fields */

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.FromPersonID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Participants',
   GeneratedFormSection = 'Category',
   DisplayName = 'From Person',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8974264B-DC82-4276-B89E-C65E14F078F8' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.FromOrganizationID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Participants',
   GeneratedFormSection = 'Category',
   DisplayName = 'From Organization',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '6D46F59F-FF3F-4351-A697-E7DB414A1E3E' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.FromOrganization 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Participants',
   GeneratedFormSection = 'Category',
   DisplayName = 'From Organization Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'DB499EE6-8FC5-4FC7-BC36-F758D5B76BCB' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.ToPersonID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Participants',
   GeneratedFormSection = 'Category',
   DisplayName = 'To Person',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'AD3ECDAA-E2BE-40D9-B83E-1868AB68C778' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.ToOrganizationID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Participants',
   GeneratedFormSection = 'Category',
   DisplayName = 'To Organization',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '42EBA3CE-7DDB-4149-BE93-E245F351B963' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.ToOrganization 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Participants',
   GeneratedFormSection = 'Category',
   DisplayName = 'To Organization Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E9B40366-4907-44C0-99B1-502E35D6E345' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.RelationshipType 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '07C7D2B2-8916-4220-961F-076C298DD2C9' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.Title 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '2ACBD16A-2A78-4807-8B8D-D0920382EAE6' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.Status 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '80B0C5C4-915A-4E72-9978-74CB33902F08' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.StartDate 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '62D8A345-E8AC-4EE6-88A9-1959F6258657' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.EndDate 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '0AFC293D-E93D-4BD2-A71C-ACB2631CA278' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.Notes 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'CD66C882-D041-46F1-8DE2-3807B1BD8B5A' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'FEFDAD15-7BA5-470A-A689-147D9303AB34' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.RelationshipTypeID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '4BFFAFBD-BF4E-4907-963B-95733C670B7E' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '5F0BE392-8F9C-4995-BC97-344D361C9706' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B15AE830-4BCB-4AA3-847E-916885287462' AND AutoUpdateCategory = 1

/* Set entity icon to fa fa-handshake */

               UPDATE [${flyway:defaultSchema}].Entity
               SET Icon = 'fa fa-handshake', __mj_UpdatedAt = GETUTCDATE()
               WHERE ID = '709CA9DA-B124-4155-BE39-E857EF672D82'
            

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('13263fbc-3148-4e07-912e-fe7853d85442', '709CA9DA-B124-4155-BE39-E857EF672D82', 'FieldCategoryInfo', '{"Relationship Participants":{"icon":"fa fa-users","description":"The people and organizations being linked together in this relationship"},"Relationship Details":{"icon":"fa fa-info-circle","description":"Core attributes including the type, status, duration, and contextual title of the link"},"System Metadata":{"icon":"fa fa-cog","description":"System-managed identifiers and audit tracking information"}}', GETUTCDATE(), GETUTCDATE())
            

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${flyway:defaultSchema}].EntitySetting (ID, EntityID, Name, Value, __mj_CreatedAt, __mj_UpdatedAt)
               VALUES ('b475965c-2d9c-423f-9eb0-4827f5490909', '709CA9DA-B124-4155-BE39-E857EF672D82', 'FieldCategoryIcons', '{"Relationship Participants":"fa fa-users","Relationship Details":"fa fa-info-circle","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE())
            

/* Set DefaultForNewUser=0 for NEW entity (category: supporting, confidence: high) */

         UPDATE [${flyway:defaultSchema}].ApplicationEntity
         SET DefaultForNewUser = 0, __mj_UpdatedAt = GETUTCDATE()
         WHERE EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82'
      

/* Generated Validation Functions for MJ.BizApps.Common: Contact Methods */
-- CHECK constraint for MJ.BizApps.Common: Contact Methods @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
INSERT INTO [${flyway:defaultSchema}].[GeneratedCode] (CategoryID, GeneratedByModelID, GeneratedAt, Language, Status, Source, Code, Description, Name, LinkedEntityID, LinkedRecordPrimaryKey)
                      VALUES ((SELECT ID FROM ${flyway:defaultSchema}.vwGeneratedCodeCategories WHERE Name='CodeGen: Validators'), '7B31F48E-EDA3-47B4-9602-D98B7EB1AF45', GETUTCDATE(), 'TypeScript','Approved', '([PersonID] IS NOT NULL AND [OrganizationID] IS NULL OR [PersonID] IS NULL AND [OrganizationID] IS NOT NULL)', 'public ValidatePersonIDOrOrganizationIDExclusivity(result: ValidationResult) {
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
}', 'Each record must be linked to either a person or an organization. This ensures that contact information is correctly attributed to exactly one entity and prevents data ambiguity caused by having both or neither assigned.', 'ValidatePersonIDOrOrganizationIDExclusivity', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', '32C45078-D33B-4760-9BE5-0DF7F483F591');
  
            

/* Generated Validation Functions for MJ.BizApps.Common: Relationships */
-- CHECK constraint for MJ.BizApps.Common: Relationships @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
INSERT INTO [${flyway:defaultSchema}].[GeneratedCode] (CategoryID, GeneratedByModelID, GeneratedAt, Language, Status, Source, Code, Description, Name, LinkedEntityID, LinkedRecordPrimaryKey)
                      VALUES ((SELECT ID FROM ${flyway:defaultSchema}.vwGeneratedCodeCategories WHERE Name='CodeGen: Validators'), '7B31F48E-EDA3-47B4-9602-D98B7EB1AF45', GETUTCDATE(), 'TypeScript','Approved', '([FromPersonID] IS NOT NULL AND [FromOrganizationID] IS NULL OR [FromPersonID] IS NULL AND [FromOrganizationID] IS NOT NULL)', 'public ValidateFromPersonOrFromOrganizationExclusivity(result: ValidationResult) {
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
}', 'A relationship must be linked to exactly one source: either a person or an organization. This ensures that the origin of the relationship is clearly defined and prevents data where both or neither are specified.', 'ValidateFromPersonOrFromOrganizationExclusivity', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', '709CA9DA-B124-4155-BE39-E857EF672D82');
  
            -- CHECK constraint for MJ.BizApps.Common: Relationships @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
INSERT INTO [${flyway:defaultSchema}].[GeneratedCode] (CategoryID, GeneratedByModelID, GeneratedAt, Language, Status, Source, Code, Description, Name, LinkedEntityID, LinkedRecordPrimaryKey)
                      VALUES ((SELECT ID FROM ${flyway:defaultSchema}.vwGeneratedCodeCategories WHERE Name='CodeGen: Validators'), '7B31F48E-EDA3-47B4-9602-D98B7EB1AF45', GETUTCDATE(), 'TypeScript','Approved', '([ToPersonID] IS NOT NULL AND [ToOrganizationID] IS NULL OR [ToPersonID] IS NULL AND [ToOrganizationID] IS NOT NULL)', 'public ValidateToPersonOrToOrganizationExclusivity(result: ValidationResult) {
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
}', 'A relationship must be linked to exactly one target: either a person or an organization. This ensures that the destination of the relationship is clearly defined and prevents ambiguous or missing links.', 'ValidateToPersonOrToOrganizationExclusivity', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', '709CA9DA-B124-4155-BE39-E857EF672D82');
  
            

