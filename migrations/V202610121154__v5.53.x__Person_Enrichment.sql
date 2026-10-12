-- =============================================================================
-- Migration: V202610121154__v5.53.x__Person_Enrichment.sql
-- Description: Person enrichment schema (plans/person-enrichment.md, Phase 2)
--              - Tables: EnrichmentProvider, EnrichmentProviderRate, PersonEducation,
--                        PersonExternalIdentity
--              - Relationship: Source and SourceSystem provenance columns (decision D5)
--              Hand-written DDL only. CodeGen output is appended below the separator.
-- =============================================================================

---------------------------------------------------------------------------
-- EnrichmentProvider: registry of enrichment vendor plugins.
-- Same pattern as ActivitySyncProviderType: a row names a ClassFactory
-- key (DriverClass) registered under BaseEnrichmentProvider.
---------------------------------------------------------------------------
IF OBJECT_ID(N'[${flyway:defaultSchema}].[EnrichmentProvider]', N'U') IS NULL
BEGIN
    CREATE TABLE [${flyway:defaultSchema}].[EnrichmentProvider] (
        ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
        Code NVARCHAR(60) NOT NULL,
        Name NVARCHAR(100) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        DriverClass NVARCHAR(200) NOT NULL,
        IntegrationID UNIQUEIDENTIFIER NULL,
        MaxBatchSize INT NOT NULL DEFAULT 10,
        RequestsPerMinute INT NULL,
        Configuration NVARCHAR(MAX) NULL,
        CreditPrice DECIMAL(18, 6) NULL,
        CreditCurrency NCHAR(3) NULL,
        Sequence INT NOT NULL DEFAULT 0,
        IsActive BIT NOT NULL DEFAULT 1,
        CONSTRAINT PK_EnrichmentProvider PRIMARY KEY (ID),
        CONSTRAINT UQ_EnrichmentProvider_Code UNIQUE (Code),
        CONSTRAINT UQ_EnrichmentProvider_Name UNIQUE (Name),
        CONSTRAINT FK_EnrichmentProvider_Integration FOREIGN KEY (IntegrationID)
            REFERENCES [${mjSchema}].[Integration](ID),
        CONSTRAINT CK_EnrichmentProvider_MaxBatchSize CHECK (MaxBatchSize > 0),
        CONSTRAINT CK_EnrichmentProvider_RequestsPerMinute CHECK (RequestsPerMinute IS NULL OR RequestsPerMinute > 0),
        CONSTRAINT CK_EnrichmentProvider_CreditPrice CHECK (
            CreditPrice IS NULL OR (CreditPrice >= 0 AND CreditCurrency IS NOT NULL)
        )
    );
END
GO

---------------------------------------------------------------------------
-- EnrichmentProviderRate: how many vendor credits each operation uses
-- (decision D16). Money = credits x EnrichmentProvider.CreditPrice.
---------------------------------------------------------------------------
IF OBJECT_ID(N'[${flyway:defaultSchema}].[EnrichmentProviderRate]', N'U') IS NULL
BEGIN
    CREATE TABLE [${flyway:defaultSchema}].[EnrichmentProviderRate] (
        ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
        EnrichmentProviderID UNIQUEIDENTIFIER NOT NULL,
        Operation NVARCHAR(30) NOT NULL,
        Unit NVARCHAR(30) NOT NULL,
        CreditsPerUnit DECIMAL(18, 4) NOT NULL,
        Notes NVARCHAR(MAX) NULL,
        CONSTRAINT PK_EnrichmentProviderRate PRIMARY KEY (ID),
        CONSTRAINT FK_EnrichmentProviderRate_EnrichmentProvider FOREIGN KEY (EnrichmentProviderID)
            REFERENCES [${flyway:defaultSchema}].[EnrichmentProvider](ID)
            ON DELETE CASCADE,
        CONSTRAINT UQ_EnrichmentProviderRate_Provider_Operation UNIQUE (EnrichmentProviderID, Operation),
        CONSTRAINT CK_EnrichmentProviderRate_Operation CHECK (Operation IN (N'Enrich', N'Count', N'Search', N'SchoolLookup')),
        CONSTRAINT CK_EnrichmentProviderRate_Unit CHECK (Unit IN (N'MatchedPerson', N'ReturnedRecord', N'NonEmptyRequest', N'Request')),
        CONSTRAINT CK_EnrichmentProviderRate_Credits CHECK (CreditsPerUnit >= 0)
    );
END
GO

---------------------------------------------------------------------------
-- PersonEducation: a person's schools and degrees, any number per person.
---------------------------------------------------------------------------
IF OBJECT_ID(N'[${flyway:defaultSchema}].[PersonEducation]', N'U') IS NULL
BEGIN
    CREATE TABLE [${flyway:defaultSchema}].[PersonEducation] (
        ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
        PersonID UNIQUEIDENTIFIER NOT NULL,
        OrganizationID UNIQUEIDENTIFIER NULL,
        InstitutionName NVARCHAR(255) NOT NULL,
        Degree NVARCHAR(200) NULL,
        FieldOfStudy NVARCHAR(200) NULL,
        StartDate DATE NULL,
        EndDate DATE NULL,
        Source NVARCHAR(20) NOT NULL DEFAULT N'Manual',
        SourceSystem NVARCHAR(80) NULL,
        LastVerifiedAt DATETIMEOFFSET NULL,
        Notes NVARCHAR(MAX) NULL,
        CONSTRAINT PK_PersonEducation PRIMARY KEY (ID),
        CONSTRAINT FK_PersonEducation_Person FOREIGN KEY (PersonID)
            REFERENCES [${flyway:defaultSchema}].[Person](ID)
            ON DELETE CASCADE,
        CONSTRAINT FK_PersonEducation_Organization FOREIGN KEY (OrganizationID)
            REFERENCES [${flyway:defaultSchema}].[Organization](ID),
        CONSTRAINT CK_PersonEducation_Source CHECK (Source IN (N'Manual', N'Import', N'Enrichment')),
        CONSTRAINT CK_PersonEducation_SourceSystem CHECK (Source = N'Manual' OR SourceSystem IS NOT NULL),
        CONSTRAINT CK_PersonEducation_Dates CHECK (StartDate IS NULL OR EndDate IS NULL OR EndDate >= StartDate)
    );
END
GO

-- "Who went to <school>?" searches on the raw name until schools are linked to Organizations.
-- Not an FK index: CodeGen owns those.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PersonEducation_InstitutionName'
               AND object_id = OBJECT_ID(N'[${flyway:defaultSchema}].[PersonEducation]'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_PersonEducation_InstitutionName
        ON [${flyway:defaultSchema}].[PersonEducation] (InstitutionName);
END
GO

---------------------------------------------------------------------------
-- PersonExternalIdentity: a person's ID at an external system (Apollo, PDL,
-- an import source) and whether that system could match them.
-- One row per (person, system). The filtered unique index stops two People
-- claiming the same external person.
---------------------------------------------------------------------------
IF OBJECT_ID(N'[${flyway:defaultSchema}].[PersonExternalIdentity]', N'U') IS NULL
BEGIN
    CREATE TABLE [${flyway:defaultSchema}].[PersonExternalIdentity] (
        ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
        PersonID UNIQUEIDENTIFIER NOT NULL,
        SourceSystem NVARCHAR(80) NOT NULL,
        ExternalID NVARCHAR(400) NULL,
        MatchStatus NVARCHAR(20) NOT NULL DEFAULT N'Matched',
        MatchedBy NVARCHAR(20) NULL,
        MatchConfidence DECIMAL(5, 4) NULL,
        LastCheckedAt DATETIMEOFFSET NOT NULL,
        LastMatchedAt DATETIMEOFFSET NULL,
        CONSTRAINT PK_PersonExternalIdentity PRIMARY KEY (ID),
        CONSTRAINT FK_PersonExternalIdentity_Person FOREIGN KEY (PersonID)
            REFERENCES [${flyway:defaultSchema}].[Person](ID)
            ON DELETE CASCADE,
        CONSTRAINT UQ_PersonExternalIdentity_Person_SourceSystem UNIQUE (PersonID, SourceSystem),
        CONSTRAINT CK_PersonExternalIdentity_MatchStatus CHECK (MatchStatus IN (N'Matched', N'NotFound', N'Ambiguous')),
        CONSTRAINT CK_PersonExternalIdentity_MatchedBy CHECK (MatchedBy IN (N'ExternalID', N'Email', N'LinkedIn', N'NameAndDomain', N'Manual')),
        CONSTRAINT CK_PersonExternalIdentity_MatchedHasID CHECK (MatchStatus <> N'Matched' OR ExternalID IS NOT NULL),
        CONSTRAINT CK_PersonExternalIdentity_Confidence CHECK (
            MatchConfidence IS NULL OR (MatchConfidence >= 0.0 AND MatchConfidence <= 1.0)
        )
    );
END
GO

-- Two People may never claim the same external person. NULL ExternalIDs (NotFound, Ambiguous) are exempt.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_PersonExternalIdentity_SourceSystem_ExternalID'
               AND object_id = OBJECT_ID(N'[${flyway:defaultSchema}].[PersonExternalIdentity]'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_PersonExternalIdentity_SourceSystem_ExternalID
        ON [${flyway:defaultSchema}].[PersonExternalIdentity] (SourceSystem, ExternalID)
        WHERE ExternalID IS NOT NULL;
END
GO

-- The eligibility filter (plan 7.5) asks "checked by <system> since <cutoff>?" for every candidate.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PersonExternalIdentity_SourceSystem_LastCheckedAt'
               AND object_id = OBJECT_ID(N'[${flyway:defaultSchema}].[PersonExternalIdentity]'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_PersonExternalIdentity_SourceSystem_LastCheckedAt
        ON [${flyway:defaultSchema}].[PersonExternalIdentity] (SourceSystem, LastCheckedAt)
        INCLUDE (PersonID, MatchStatus);
END
GO

---------------------------------------------------------------------------
-- Relationship: provenance (decision D5). Existing rows become 'Manual'.
---------------------------------------------------------------------------
IF COL_LENGTH(N'[${flyway:defaultSchema}].[Relationship]', N'Source') IS NULL
BEGIN
    ALTER TABLE [${flyway:defaultSchema}].[Relationship] ADD
        Source NVARCHAR(20) NOT NULL CONSTRAINT DF_Relationship_Source DEFAULT N'Manual',
        SourceSystem NVARCHAR(80) NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Relationship_Source')
BEGIN
    ALTER TABLE [${flyway:defaultSchema}].[Relationship]
        ADD CONSTRAINT CK_Relationship_Source CHECK (Source IN (N'Manual', N'Import', N'Enrichment'));
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Relationship_SourceSystem')
BEGIN
    ALTER TABLE [${flyway:defaultSchema}].[Relationship]
        ADD CONSTRAINT CK_Relationship_SourceSystem CHECK (Source = N'Manual' OR SourceSystem IS NOT NULL);
END
GO

---------------------------------------------------------------------------
-- Extended Properties
---------------------------------------------------------------------------
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Registry of person-enrichment vendor plugins. Each row names a class registered under BaseEnrichmentProvider.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'EnrichmentProvider';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Stable short code, e.g. Apollo or PDL. Also written as SourceSystem on every row this provider produces. Never rename.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'EnrichmentProvider', @level2type=N'COLUMN', @level2name=N'Code';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Display name.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'EnrichmentProvider', @level2type=N'COLUMN', @level2name=N'Name';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'What the provider supplies and any caveats.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'EnrichmentProvider', @level2type=N'COLUMN', @level2name=N'Description';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'ClassFactory key of the BaseEnrichmentProvider subclass that implements this provider.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'EnrichmentProvider', @level2type=N'COLUMN', @level2name=N'DriverClass';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Most people the vendor accepts in one request (Apollo 10, PDL 100). The engine batches to this size.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'EnrichmentProvider', @level2type=N'COLUMN', @level2name=N'MaxBatchSize';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Optional client-side request ceiling. NULL means rely on the vendor''s 429 responses.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'EnrichmentProvider', @level2type=N'COLUMN', @level2name=N'RequestsPerMinute';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Provider-specific JSON options, e.g. a PDL minimum likelihood. Engine-wide policy lives on the action params, not here.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'EnrichmentProvider', @level2type=N'COLUMN', @level2name=N'Configuration';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'This host''s price for one vendor credit, from its own contract. NULL means unpriced: estimates then show credits only, never a zero cost.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'EnrichmentProvider', @level2type=N'COLUMN', @level2name=N'CreditPrice';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'ISO 4217 code for CreditPrice, e.g. USD. Required when CreditPrice is set.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'EnrichmentProvider', @level2type=N'COLUMN', @level2name=N'CreditCurrency';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Display and preference order when several providers are active.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'EnrichmentProvider', @level2type=N'COLUMN', @level2name=N'Sequence';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Inactive providers are refused by the engine.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'EnrichmentProvider', @level2type=N'COLUMN', @level2name=N'IsActive';

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'How many vendor credits each operation uses, per provider. Used to estimate cost before a run or import.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'EnrichmentProviderRate';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Enrich (bulk match of existing people), Count (counting a cohort), Search (one page of an import) or SchoolLookup (resolving a school name).',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'EnrichmentProviderRate', @level2type=N'COLUMN', @level2name=N'Operation';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'What the vendor bills per: MatchedPerson, ReturnedRecord, NonEmptyRequest (a request that returned anything) or Request.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'EnrichmentProviderRate', @level2type=N'COLUMN', @level2name=N'Unit';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Credits used per unit. 0 means free.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'EnrichmentProviderRate', @level2type=N'COLUMN', @level2name=N'CreditsPerUnit';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Where the number came from and when it was checked, e.g. "Phase 0 spike, 2026-10".',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'EnrichmentProviderRate', @level2type=N'COLUMN', @level2name=N'Notes';

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Schools and degrees a person has attended or earned. Any number per person, from any source.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonEducation';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'The school name exactly as the source gave it. Kept even when OrganizationID is set, so unmatched names are never lost.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonEducation', @level2type=N'COLUMN', @level2name=N'InstitutionName';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Degree as the source gave it, e.g. "Master of Public Administration" or "MPP".',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonEducation', @level2type=N'COLUMN', @level2name=N'Degree';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Major or field of study, when known.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonEducation', @level2type=N'COLUMN', @level2name=N'FieldOfStudy';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Date study began, when known.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonEducation', @level2type=N'COLUMN', @level2name=N'StartDate';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Graduation or end date, when known.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonEducation', @level2type=N'COLUMN', @level2name=N'EndDate';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Manual (entered by a person), Import (bulk load) or Enrichment (written by an enrichment provider). Enrichment never edits Manual rows.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonEducation', @level2type=N'COLUMN', @level2name=N'Source';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Which system supplied a non-manual row. Equals EnrichmentProvider.Code for enrichment rows.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonEducation', @level2type=N'COLUMN', @level2name=N'SourceSystem';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'When the source last confirmed this row.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonEducation', @level2type=N'COLUMN', @level2name=N'LastVerifiedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Free text.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonEducation', @level2type=N'COLUMN', @level2name=N'Notes';

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'A person''s identifier in an external system and the outcome of the last match attempt. One row per person per system.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonExternalIdentity';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'The external system, e.g. Apollo or PDL.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonExternalIdentity', @level2type=N'COLUMN', @level2name=N'SourceSystem';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'The person''s ID in that system. Unique per system. Required when MatchStatus is Matched.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonExternalIdentity', @level2type=N'COLUMN', @level2name=N'ExternalID';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Matched; NotFound (the system had no match, retried after a cooling-off period); Ambiguous (the system''s ID already belongs to another Person, so a human must resolve the possible duplicate).',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonExternalIdentity', @level2type=N'COLUMN', @level2name=N'MatchStatus';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Which identifier produced the match: ExternalID, Email, LinkedIn, NameAndDomain or Manual.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonExternalIdentity', @level2type=N'COLUMN', @level2name=N'MatchedBy';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Vendor match confidence from 0 to 1, when the vendor reports one.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonExternalIdentity', @level2type=N'COLUMN', @level2name=N'MatchConfidence';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'When this person was last sent to this system. Drives re-enrichment eligibility.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonExternalIdentity', @level2type=N'COLUMN', @level2name=N'LastCheckedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'When the system last returned a match.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonExternalIdentity', @level2type=N'COLUMN', @level2name=N'LastMatchedAt';

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Manual, Import or Enrichment. Enrichment only updates or ends relationships it created.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Relationship', @level2type=N'COLUMN', @level2name=N'Source';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Which system supplied a non-manual relationship.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Relationship', @level2type=N'COLUMN', @level2name=N'SourceSystem';
GO


















































/**************************************************************************************************
 **************************************************************************************************
 **                                                                                              **
 **                CODEGEN OUTPUT — Person Enrichment (v5.53.x), RUN #1                          **
 **                                                                                              **
 **  Everything below this banner was generated by MemberJunction CodeGen (MJ `next`,            **
 **  6.2.0-edge.3 source, against a database built from migrations alone) AFTER the hand-written **
 **  DDL above was applied and the schema introspected. It carries the Entity / EntityField /    **
 **  EntityFieldValue / EntityRelationship / EntityPermission rows for the four new entities and  **
 **  the two Relationship columns, the regenerated base views and CRUD procedures (including      **
 **  spCreateRelationship / spUpdateRelationship with OPTIONAL @Source and @SourceSystem), the   **
 **  __mj_UpdatedAt triggers, FK indexes and permission grants.                                   **
 **                                                                                              **
 **  DO NOT EDIT BY HAND. If the DDL above changes, re-run CodeGen and replace this section.     **
 **                                                                                              **
 **************************************************************************************************
 **************************************************************************************************/
/* SQL generated to create new entity MJ_BizApps_Common: Enrichment Providers */

      INSERT INTO [${mjSchema}].[Entity] (
         [ID],
         [Name],
         [DisplayName],
         [Description],
         [NameSuffix],
         [BaseTable],
         [BaseView],
         [SchemaName],
         [IncludeInAPI],
         [AllowUserSearchAPI],
         [AllowCaching]
         , [TrackRecordChanges]
         , [AuditRecordAccess]
         , [AuditViewRuns]
         , [AllowAllRowsAPI]
         , [AllowCreateAPI]
         , [AllowUpdateAPI]
         , [AllowDeleteAPI]
         , [UserViewMaxRows]
         , [__mj_CreatedAt]
         , [__mj_UpdatedAt]
      )
      VALUES (
         'fd00fce2-3ef2-4319-bccc-13bb7c986ad7',
         'MJ_BizApps_Common: Enrichment Providers',
         'Enrichment Providers',
         'Registry of person-enrichment vendor plugins. Each row names a class registered under BaseEnrichmentProvider.',
         NULL,
         'EnrichmentProvider',
         'vwEnrichmentProviders',
         '${flyway:defaultSchema}',
         1,
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
         , GETUTCDATE()
         , GETUTCDATE()
      );

/* SQL generated to add new entity MJ_BizApps_Common: Enrichment Providers to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'fd00fce2-3ef2-4319-bccc-13bb7c986ad7', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Enrichment Providers for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('fd00fce2-3ef2-4319-bccc-13bb7c986ad7' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('fd00fce2-3ef2-4319-bccc-13bb7c986ad7' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Enrichment Providers for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('fd00fce2-3ef2-4319-bccc-13bb7c986ad7' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('fd00fce2-3ef2-4319-bccc-13bb7c986ad7' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Enrichment Providers for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('fd00fce2-3ef2-4319-bccc-13bb7c986ad7' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('fd00fce2-3ef2-4319-bccc-13bb7c986ad7' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to create new entity MJ_BizApps_Common: Enrichment Provider Rates */

      INSERT INTO [${mjSchema}].[Entity] (
         [ID],
         [Name],
         [DisplayName],
         [Description],
         [NameSuffix],
         [BaseTable],
         [BaseView],
         [SchemaName],
         [IncludeInAPI],
         [AllowUserSearchAPI],
         [AllowCaching]
         , [TrackRecordChanges]
         , [AuditRecordAccess]
         , [AuditViewRuns]
         , [AllowAllRowsAPI]
         , [AllowCreateAPI]
         , [AllowUpdateAPI]
         , [AllowDeleteAPI]
         , [UserViewMaxRows]
         , [__mj_CreatedAt]
         , [__mj_UpdatedAt]
      )
      VALUES (
         'fece9795-e393-4470-b1fd-7d826f505105',
         'MJ_BizApps_Common: Enrichment Provider Rates',
         'Enrichment Provider Rates',
         'How many vendor credits each operation uses, per provider. Used to estimate cost before a run or import.',
         NULL,
         'EnrichmentProviderRate',
         'vwEnrichmentProviderRates',
         '${flyway:defaultSchema}',
         1,
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
         , GETUTCDATE()
         , GETUTCDATE()
      );

/* SQL generated to add new entity MJ_BizApps_Common: Enrichment Provider Rates to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'fece9795-e393-4470-b1fd-7d826f505105', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Enrichment Provider Rates for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('fece9795-e393-4470-b1fd-7d826f505105' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('fece9795-e393-4470-b1fd-7d826f505105' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Enrichment Provider Rates for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('fece9795-e393-4470-b1fd-7d826f505105' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('fece9795-e393-4470-b1fd-7d826f505105' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Enrichment Provider Rates for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('fece9795-e393-4470-b1fd-7d826f505105' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('fece9795-e393-4470-b1fd-7d826f505105' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to create new entity MJ_BizApps_Common: Person Educations */

      INSERT INTO [${mjSchema}].[Entity] (
         [ID],
         [Name],
         [DisplayName],
         [Description],
         [NameSuffix],
         [BaseTable],
         [BaseView],
         [SchemaName],
         [IncludeInAPI],
         [AllowUserSearchAPI],
         [AllowCaching]
         , [TrackRecordChanges]
         , [AuditRecordAccess]
         , [AuditViewRuns]
         , [AllowAllRowsAPI]
         , [AllowCreateAPI]
         , [AllowUpdateAPI]
         , [AllowDeleteAPI]
         , [UserViewMaxRows]
         , [__mj_CreatedAt]
         , [__mj_UpdatedAt]
      )
      VALUES (
         'a50829b7-110b-48d9-acb4-b169917bbf41',
         'MJ_BizApps_Common: Person Educations',
         'Person Educations',
         'Schools and degrees a person has attended or earned. Any number per person, from any source.',
         NULL,
         'PersonEducation',
         'vwPersonEducations',
         '${flyway:defaultSchema}',
         1,
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
         , GETUTCDATE()
         , GETUTCDATE()
      );

/* SQL generated to add new entity MJ_BizApps_Common: Person Educations to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'a50829b7-110b-48d9-acb4-b169917bbf41', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Person Educations for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('a50829b7-110b-48d9-acb4-b169917bbf41' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('a50829b7-110b-48d9-acb4-b169917bbf41' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Person Educations for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('a50829b7-110b-48d9-acb4-b169917bbf41' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('a50829b7-110b-48d9-acb4-b169917bbf41' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Person Educations for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('a50829b7-110b-48d9-acb4-b169917bbf41' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('a50829b7-110b-48d9-acb4-b169917bbf41' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to create new entity MJ_BizApps_Common: Person External Identities */

      INSERT INTO [${mjSchema}].[Entity] (
         [ID],
         [Name],
         [DisplayName],
         [Description],
         [NameSuffix],
         [BaseTable],
         [BaseView],
         [SchemaName],
         [IncludeInAPI],
         [AllowUserSearchAPI],
         [AllowCaching]
         , [TrackRecordChanges]
         , [AuditRecordAccess]
         , [AuditViewRuns]
         , [AllowAllRowsAPI]
         , [AllowCreateAPI]
         , [AllowUpdateAPI]
         , [AllowDeleteAPI]
         , [UserViewMaxRows]
         , [__mj_CreatedAt]
         , [__mj_UpdatedAt]
      )
      VALUES (
         'c92e1e9e-bcb6-49b0-838c-1fa50ea7ce62',
         'MJ_BizApps_Common: Person External Identities',
         'Person External Identities',
         'A person''s identifier in an external system and the outcome of the last match attempt. One row per person per system.',
         NULL,
         'PersonExternalIdentity',
         'vwPersonExternalIdentities',
         '${flyway:defaultSchema}',
         1,
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
         , GETUTCDATE()
         , GETUTCDATE()
      );

/* SQL generated to add new entity MJ_BizApps_Common: Person External Identities to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'c92e1e9e-bcb6-49b0-838c-1fa50ea7ce62', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Person External Identities for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('c92e1e9e-bcb6-49b0-838c-1fa50ea7ce62' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('c92e1e9e-bcb6-49b0-838c-1fa50ea7ce62' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Person External Identities for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('c92e1e9e-bcb6-49b0-838c-1fa50ea7ce62' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('c92e1e9e-bcb6-49b0-838c-1fa50ea7ce62' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Person External Identities for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('c92e1e9e-bcb6-49b0-838c-1fa50ea7ce62' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('c92e1e9e-bcb6-49b0-838c-1fa50ea7ce62' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.EnrichmentProvider */
ALTER TABLE [${flyway:defaultSchema}].[EnrichmentProvider] ADD [__mj_CreatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.EnrichmentProvider */
UPDATE [${flyway:defaultSchema}].[EnrichmentProvider] SET [__mj_CreatedAt] = GETUTCDATE() WHERE [__mj_CreatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.EnrichmentProvider */
ALTER TABLE [${flyway:defaultSchema}].[EnrichmentProvider] ALTER COLUMN [__mj_CreatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.EnrichmentProvider */
ALTER TABLE [${flyway:defaultSchema}].[EnrichmentProvider] ADD CONSTRAINT [DF___mj_BizAppsCommon_EnrichmentProvider___mj_CreatedAt] DEFAULT GETUTCDATE() FOR [__mj_CreatedAt];
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.EnrichmentProvider */
ALTER TABLE [${flyway:defaultSchema}].[EnrichmentProvider] ADD [__mj_UpdatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.EnrichmentProvider */
UPDATE [${flyway:defaultSchema}].[EnrichmentProvider] SET [__mj_UpdatedAt] = GETUTCDATE() WHERE [__mj_UpdatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.EnrichmentProvider */
ALTER TABLE [${flyway:defaultSchema}].[EnrichmentProvider] ALTER COLUMN [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.EnrichmentProvider */
ALTER TABLE [${flyway:defaultSchema}].[EnrichmentProvider] ADD CONSTRAINT [DF___mj_BizAppsCommon_EnrichmentProvider___mj_UpdatedAt] DEFAULT GETUTCDATE() FOR [__mj_UpdatedAt];
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.PersonExternalIdentity */
ALTER TABLE [${flyway:defaultSchema}].[PersonExternalIdentity] ADD [__mj_CreatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.PersonExternalIdentity */
UPDATE [${flyway:defaultSchema}].[PersonExternalIdentity] SET [__mj_CreatedAt] = GETUTCDATE() WHERE [__mj_CreatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.PersonExternalIdentity */
ALTER TABLE [${flyway:defaultSchema}].[PersonExternalIdentity] ALTER COLUMN [__mj_CreatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.PersonExternalIdentity */
ALTER TABLE [${flyway:defaultSchema}].[PersonExternalIdentity] ADD CONSTRAINT [DF___mj_BizAppsCommon_PersonExternalIdentity___mj_CreatedAt] DEFAULT GETUTCDATE() FOR [__mj_CreatedAt];
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.PersonExternalIdentity */
ALTER TABLE [${flyway:defaultSchema}].[PersonExternalIdentity] ADD [__mj_UpdatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.PersonExternalIdentity */
UPDATE [${flyway:defaultSchema}].[PersonExternalIdentity] SET [__mj_UpdatedAt] = GETUTCDATE() WHERE [__mj_UpdatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.PersonExternalIdentity */
ALTER TABLE [${flyway:defaultSchema}].[PersonExternalIdentity] ALTER COLUMN [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.PersonExternalIdentity */
ALTER TABLE [${flyway:defaultSchema}].[PersonExternalIdentity] ADD CONSTRAINT [DF___mj_BizAppsCommon_PersonExternalIdentity___mj_UpdatedAt] DEFAULT GETUTCDATE() FOR [__mj_UpdatedAt];
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.EnrichmentProviderRate */
ALTER TABLE [${flyway:defaultSchema}].[EnrichmentProviderRate] ADD [__mj_CreatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.EnrichmentProviderRate */
UPDATE [${flyway:defaultSchema}].[EnrichmentProviderRate] SET [__mj_CreatedAt] = GETUTCDATE() WHERE [__mj_CreatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.EnrichmentProviderRate */
ALTER TABLE [${flyway:defaultSchema}].[EnrichmentProviderRate] ALTER COLUMN [__mj_CreatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.EnrichmentProviderRate */
ALTER TABLE [${flyway:defaultSchema}].[EnrichmentProviderRate] ADD CONSTRAINT [DF___mj_BizAppsCommon_EnrichmentProviderRate___mj_CreatedAt] DEFAULT GETUTCDATE() FOR [__mj_CreatedAt];
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.EnrichmentProviderRate */
ALTER TABLE [${flyway:defaultSchema}].[EnrichmentProviderRate] ADD [__mj_UpdatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.EnrichmentProviderRate */
UPDATE [${flyway:defaultSchema}].[EnrichmentProviderRate] SET [__mj_UpdatedAt] = GETUTCDATE() WHERE [__mj_UpdatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.EnrichmentProviderRate */
ALTER TABLE [${flyway:defaultSchema}].[EnrichmentProviderRate] ALTER COLUMN [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.EnrichmentProviderRate */
ALTER TABLE [${flyway:defaultSchema}].[EnrichmentProviderRate] ADD CONSTRAINT [DF___mj_BizAppsCommon_EnrichmentProviderRate___mj_UpdatedAt] DEFAULT GETUTCDATE() FOR [__mj_UpdatedAt];
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.PersonEducation */
ALTER TABLE [${flyway:defaultSchema}].[PersonEducation] ADD [__mj_CreatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.PersonEducation */
UPDATE [${flyway:defaultSchema}].[PersonEducation] SET [__mj_CreatedAt] = GETUTCDATE() WHERE [__mj_CreatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.PersonEducation */
ALTER TABLE [${flyway:defaultSchema}].[PersonEducation] ALTER COLUMN [__mj_CreatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.PersonEducation */
ALTER TABLE [${flyway:defaultSchema}].[PersonEducation] ADD CONSTRAINT [DF___mj_BizAppsCommon_PersonEducation___mj_CreatedAt] DEFAULT GETUTCDATE() FOR [__mj_CreatedAt];
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.PersonEducation */
ALTER TABLE [${flyway:defaultSchema}].[PersonEducation] ADD [__mj_UpdatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.PersonEducation */
UPDATE [${flyway:defaultSchema}].[PersonEducation] SET [__mj_UpdatedAt] = GETUTCDATE() WHERE [__mj_UpdatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.PersonEducation */
ALTER TABLE [${flyway:defaultSchema}].[PersonEducation] ALTER COLUMN [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.PersonEducation */
ALTER TABLE [${flyway:defaultSchema}].[PersonEducation] ADD CONSTRAINT [DF___mj_BizAppsCommon_PersonEducation___mj_UpdatedAt] DEFAULT GETUTCDATE() FOR [__mj_UpdatedAt];
GO

/* SQL text to insert 50 new entity field(s) */

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c73482c2-7218-4864-9358-d12441add7e8' OR (EntityID = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND Name = 'ID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'c73482c2-7218-4864-9358-d12441add7e8',
            'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', -- Entity: MJ_BizApps_Common: Enrichment Providers
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7'),
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
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            1,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'b5d4e755-6262-456f-8cf5-0154a28aa419' OR (EntityID = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND Name = 'Code')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'b5d4e755-6262-456f-8cf5-0154a28aa419',
            'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', -- Entity: MJ_BizApps_Common: Enrichment Providers
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7'),
            'Code',
            'Code',
            'Stable short code, e.g. Apollo or PDL. Also written as SourceSystem on every row this provider produces. Never rename.',
            'nvarchar',
            120,
            0,
            0,
            0,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            1,
            0,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8a9e570f-45f9-4880-8e46-8bd7754c49eb' OR (EntityID = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND Name = 'Name')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '8a9e570f-45f9-4880-8e46-8bd7754c49eb',
            'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', -- Entity: MJ_BizApps_Common: Enrichment Providers
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7'),
            'Name',
            'Name',
            'Display name.',
            'nvarchar',
            200,
            0,
            0,
            0,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            1,
            1,
            0,
            1,
            0,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f1e611b5-630d-4c06-97ab-7c9186abeb12' OR (EntityID = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND Name = 'Description')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'f1e611b5-630d-4c06-97ab-7c9186abeb12',
            'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', -- Entity: MJ_BizApps_Common: Enrichment Providers
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7'),
            'Description',
            'Description',
            'What the provider supplies and any caveats.',
            'nvarchar',
            -1,
            0,
            0,
            1,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            1,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'e11c8374-1f9e-4845-9833-3a52f8cba181' OR (EntityID = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND Name = 'DriverClass')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'e11c8374-1f9e-4845-9833-3a52f8cba181',
            'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', -- Entity: MJ_BizApps_Common: Enrichment Providers
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7'),
            'DriverClass',
            'Driver Class',
            'ClassFactory key of the BaseEnrichmentProvider subclass that implements this provider.',
            'nvarchar',
            400,
            0,
            0,
            0,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            1,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c45f676e-fe35-4000-ab4c-b80896d48ffb' OR (EntityID = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND Name = 'IntegrationID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'c45f676e-fe35-4000-ab4c-b80896d48ffb',
            'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', -- Entity: MJ_BizApps_Common: Enrichment Providers
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7'),
            'IntegrationID',
            'Integration ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            1,
            NULL,
            0,
            1,
            0,
            0,
            'DD238F34-2837-EF11-86D4-6045BDEE16E6',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '347a97bb-6f89-44de-ac75-423fad2a6954' OR (EntityID = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND Name = 'MaxBatchSize')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '347a97bb-6f89-44de-ac75-423fad2a6954',
            'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', -- Entity: MJ_BizApps_Common: Enrichment Providers
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7'),
            'MaxBatchSize',
            'Max Batch Size',
            'Most people the vendor accepts in one request (Apollo 10, PDL 100). The engine batches to this size.',
            'int',
            4,
            10,
            0,
            0,
            '(10)',
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '228e2ffa-9bad-4df9-9a8e-8fd34a61c755' OR (EntityID = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND Name = 'RequestsPerMinute')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '228e2ffa-9bad-4df9-9a8e-8fd34a61c755',
            'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', -- Entity: MJ_BizApps_Common: Enrichment Providers
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7'),
            'RequestsPerMinute',
            'Requests Per Minute',
            'Optional client-side request ceiling. NULL means rely on the vendor''s 429 responses.',
            'int',
            4,
            10,
            0,
            1,
            NULL,
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8fe1c97c-5370-4cc8-92cd-cb9299e3696e' OR (EntityID = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND Name = 'Configuration')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '8fe1c97c-5370-4cc8-92cd-cb9299e3696e',
            'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', -- Entity: MJ_BizApps_Common: Enrichment Providers
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7'),
            'Configuration',
            'Configuration',
            'Provider-specific JSON options, e.g. a PDL minimum likelihood. Engine-wide policy lives on the action params, not here.',
            'nvarchar',
            -1,
            0,
            0,
            1,
            NULL,
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '255753d7-0383-4ed1-8925-4fbc76a93fab' OR (EntityID = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND Name = 'CreditPrice')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '255753d7-0383-4ed1-8925-4fbc76a93fab',
            'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', -- Entity: MJ_BizApps_Common: Enrichment Providers
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7'),
            'CreditPrice',
            'Credit Price',
            'This host''s price for one vendor credit, from its own contract. NULL means unpriced: estimates then show credits only, never a zero cost.',
            'decimal',
            9,
            18,
            6,
            1,
            NULL,
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '759bb2ad-6e8c-458e-b657-2f7311fc9f33' OR (EntityID = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND Name = 'CreditCurrency')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '759bb2ad-6e8c-458e-b657-2f7311fc9f33',
            'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', -- Entity: MJ_BizApps_Common: Enrichment Providers
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7'),
            'CreditCurrency',
            'Credit Currency',
            'ISO 4217 code for CreditPrice, e.g. USD. Required when CreditPrice is set.',
            'nchar',
            6,
            0,
            0,
            1,
            NULL,
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '3357be27-b960-4614-8878-df9397f227ab' OR (EntityID = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND Name = 'Sequence')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '3357be27-b960-4614-8878-df9397f227ab',
            'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', -- Entity: MJ_BizApps_Common: Enrichment Providers
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7'),
            'Sequence',
            'Sequence',
            'Display and preference order when several providers are active.',
            'int',
            4,
            10,
            0,
            0,
            '(0)',
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f5782f12-9b29-4b94-925e-d8c88e08c755' OR (EntityID = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND Name = 'IsActive')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'f5782f12-9b29-4b94-925e-d8c88e08c755',
            'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', -- Entity: MJ_BizApps_Common: Enrichment Providers
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7'),
            'IsActive',
            'Is Active',
            'Inactive providers are refused by the engine.',
            'bit',
            1,
            1,
            0,
            0,
            '(1)',
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '1f5cf4bf-2aef-4d67-a670-f6e80ed4ea8e' OR (EntityID = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND Name = '__mj_CreatedAt')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '1f5cf4bf-2aef-4d67-a670-f6e80ed4ea8e',
            'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', -- Entity: MJ_BizApps_Common: Enrichment Providers
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7'),
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
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '1c802c40-dbf8-4a96-a20d-58d5422070ab' OR (EntityID = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND Name = '__mj_UpdatedAt')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '1c802c40-dbf8-4a96-a20d-58d5422070ab',
            'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', -- Entity: MJ_BizApps_Common: Enrichment Providers
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7'),
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
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '6f47161f-44f9-4c09-82e1-7688cb48bd60' OR (EntityID = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62' AND Name = 'ID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '6f47161f-44f9-4c09-82e1-7688cb48bd60',
            'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62', -- Entity: MJ_BizApps_Common: Person External Identities
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62'),
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
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            1,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'b8247a33-a3e3-4e75-aa71-4c5b1599875e' OR (EntityID = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62' AND Name = 'PersonID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'b8247a33-a3e3-4e75-aa71-4c5b1599875e',
            'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62', -- Entity: MJ_BizApps_Common: Person External Identities
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62'),
            'PersonID',
            'Person ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            NULL,
            0,
            1,
            0,
            0,
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F',
            'ID',
            0,
            0,
            1,
            0,
            0,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8993aaf1-0133-4394-bbbf-c2eda0ef90bf' OR (EntityID = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62' AND Name = 'SourceSystem')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '8993aaf1-0133-4394-bbbf-c2eda0ef90bf',
            'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62', -- Entity: MJ_BizApps_Common: Person External Identities
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62'),
            'SourceSystem',
            'Source System',
            'The external system, e.g. Apollo or PDL.',
            'nvarchar',
            160,
            0,
            0,
            0,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            1,
            0,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'e0d2c339-18ee-4d84-a496-1f33ca5591cb' OR (EntityID = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62' AND Name = 'ExternalID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'e0d2c339-18ee-4d84-a496-1f33ca5591cb',
            'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62', -- Entity: MJ_BizApps_Common: Person External Identities
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62'),
            'ExternalID',
            'External ID',
            'The person''s ID in that system. Unique per system. Required when MatchStatus is Matched.',
            'nvarchar',
            800,
            0,
            0,
            1,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            1,
            0,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'd5aa5d25-dbe1-45ac-93a2-07dcaef834b1' OR (EntityID = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62' AND Name = 'MatchStatus')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'd5aa5d25-dbe1-45ac-93a2-07dcaef834b1',
            'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62', -- Entity: MJ_BizApps_Common: Person External Identities
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62'),
            'MatchStatus',
            'Match Status',
            'Matched; NotFound (the system had no match, retried after a cooling-off period); Ambiguous (the system''s ID already belongs to another Person, so a human must resolve the possible duplicate).',
            'nvarchar',
            40,
            0,
            0,
            0,
            'Matched',
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            1,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '016190cc-296c-4e75-b04b-a61284ff8fd2' OR (EntityID = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62' AND Name = 'MatchedBy')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '016190cc-296c-4e75-b04b-a61284ff8fd2',
            'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62', -- Entity: MJ_BizApps_Common: Person External Identities
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62'),
            'MatchedBy',
            'Matched By',
            'Which identifier produced the match: ExternalID, Email, LinkedIn, NameAndDomain or Manual.',
            'nvarchar',
            40,
            0,
            0,
            1,
            NULL,
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '75afed22-e199-4946-a4be-b74fd41d9d13' OR (EntityID = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62' AND Name = 'MatchConfidence')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '75afed22-e199-4946-a4be-b74fd41d9d13',
            'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62', -- Entity: MJ_BizApps_Common: Person External Identities
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62'),
            'MatchConfidence',
            'Match Confidence',
            'Vendor match confidence from 0 to 1, when the vendor reports one.',
            'decimal',
            5,
            5,
            4,
            1,
            NULL,
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '4f9e5bb3-92cb-41ed-9b17-503ee920541e' OR (EntityID = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62' AND Name = 'LastCheckedAt')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '4f9e5bb3-92cb-41ed-9b17-503ee920541e',
            'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62', -- Entity: MJ_BizApps_Common: Person External Identities
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62'),
            'LastCheckedAt',
            'Last Checked At',
            'When this person was last sent to this system. Drives re-enrichment eligibility.',
            'datetimeoffset',
            10,
            34,
            7,
            0,
            NULL,
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '395cefca-887a-4bf8-a3d2-4ad6eb83884b' OR (EntityID = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62' AND Name = 'LastMatchedAt')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '395cefca-887a-4bf8-a3d2-4ad6eb83884b',
            'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62', -- Entity: MJ_BizApps_Common: Person External Identities
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62'),
            'LastMatchedAt',
            'Last Matched At',
            'When the system last returned a match.',
            'datetimeoffset',
            10,
            34,
            7,
            1,
            NULL,
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '697d4bb5-81df-4d98-bf63-a58a2534d40f' OR (EntityID = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62' AND Name = '__mj_CreatedAt')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '697d4bb5-81df-4d98-bf63-a58a2534d40f',
            'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62', -- Entity: MJ_BizApps_Common: Person External Identities
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62'),
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
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'ade2b65b-b7ee-42d6-8c19-cd6ee97f5c3b' OR (EntityID = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62' AND Name = '__mj_UpdatedAt')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'ade2b65b-b7ee-42d6-8c19-cd6ee97f5c3b',
            'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62', -- Entity: MJ_BizApps_Common: Person External Identities
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62'),
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
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '7a9ca7ae-7e75-4b09-b003-c90f6196ca09' OR (EntityID = 'FECE9795-E393-4470-B1FD-7D826F505105' AND Name = 'ID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '7a9ca7ae-7e75-4b09-b003-c90f6196ca09',
            'FECE9795-E393-4470-B1FD-7D826F505105', -- Entity: MJ_BizApps_Common: Enrichment Provider Rates
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FECE9795-E393-4470-B1FD-7D826F505105'),
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
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            1,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'ce7651e6-07db-47c4-a603-d456e1d0ea14' OR (EntityID = 'FECE9795-E393-4470-B1FD-7D826F505105' AND Name = 'EnrichmentProviderID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'ce7651e6-07db-47c4-a603-d456e1d0ea14',
            'FECE9795-E393-4470-B1FD-7D826F505105', -- Entity: MJ_BizApps_Common: Enrichment Provider Rates
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FECE9795-E393-4470-B1FD-7D826F505105'),
            'EnrichmentProviderID',
            'Enrichment Provider ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            NULL,
            0,
            1,
            0,
            0,
            'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7',
            'ID',
            0,
            0,
            1,
            0,
            0,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'a0198fe1-df0d-49dd-b6cd-a9c76fdd47fc' OR (EntityID = 'FECE9795-E393-4470-B1FD-7D826F505105' AND Name = 'Operation')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'a0198fe1-df0d-49dd-b6cd-a9c76fdd47fc',
            'FECE9795-E393-4470-B1FD-7D826F505105', -- Entity: MJ_BizApps_Common: Enrichment Provider Rates
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FECE9795-E393-4470-B1FD-7D826F505105'),
            'Operation',
            'Operation',
            'Enrich (bulk match of existing people), Count (counting a cohort), Search (one page of an import) or SchoolLookup (resolving a school name).',
            'nvarchar',
            60,
            0,
            0,
            0,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            1,
            0,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '31bcb292-f75a-4018-8b4e-9cc6f1c445e1' OR (EntityID = 'FECE9795-E393-4470-B1FD-7D826F505105' AND Name = 'Unit')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '31bcb292-f75a-4018-8b4e-9cc6f1c445e1',
            'FECE9795-E393-4470-B1FD-7D826F505105', -- Entity: MJ_BizApps_Common: Enrichment Provider Rates
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FECE9795-E393-4470-B1FD-7D826F505105'),
            'Unit',
            'Unit',
            'What the vendor bills per: MatchedPerson, ReturnedRecord, NonEmptyRequest (a request that returned anything) or Request.',
            'nvarchar',
            60,
            0,
            0,
            0,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            1,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '89ab5701-2149-4134-a6d0-39ca35cf4a9a' OR (EntityID = 'FECE9795-E393-4470-B1FD-7D826F505105' AND Name = 'CreditsPerUnit')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '89ab5701-2149-4134-a6d0-39ca35cf4a9a',
            'FECE9795-E393-4470-B1FD-7D826F505105', -- Entity: MJ_BizApps_Common: Enrichment Provider Rates
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FECE9795-E393-4470-B1FD-7D826F505105'),
            'CreditsPerUnit',
            'Credits Per Unit',
            'Credits used per unit. 0 means free.',
            'decimal',
            9,
            18,
            4,
            0,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            1,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '55e41f32-bd19-41c3-a5e3-a41ada55ccf0' OR (EntityID = 'FECE9795-E393-4470-B1FD-7D826F505105' AND Name = 'Notes')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '55e41f32-bd19-41c3-a5e3-a41ada55ccf0',
            'FECE9795-E393-4470-B1FD-7D826F505105', -- Entity: MJ_BizApps_Common: Enrichment Provider Rates
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FECE9795-E393-4470-B1FD-7D826F505105'),
            'Notes',
            'Notes',
            'Where the number came from and when it was checked, e.g. "Phase 0 spike, 2026-10".',
            'nvarchar',
            -1,
            0,
            0,
            1,
            NULL,
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'd0d39f9a-0aee-4b5e-9d38-b2a9194a47b8' OR (EntityID = 'FECE9795-E393-4470-B1FD-7D826F505105' AND Name = '__mj_CreatedAt')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'd0d39f9a-0aee-4b5e-9d38-b2a9194a47b8',
            'FECE9795-E393-4470-B1FD-7D826F505105', -- Entity: MJ_BizApps_Common: Enrichment Provider Rates
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FECE9795-E393-4470-B1FD-7D826F505105'),
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
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f483b9df-2762-49db-87c8-590ca69bcc41' OR (EntityID = 'FECE9795-E393-4470-B1FD-7D826F505105' AND Name = '__mj_UpdatedAt')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'f483b9df-2762-49db-87c8-590ca69bcc41',
            'FECE9795-E393-4470-B1FD-7D826F505105', -- Entity: MJ_BizApps_Common: Enrichment Provider Rates
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FECE9795-E393-4470-B1FD-7D826F505105'),
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
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '46a8f6ba-2923-46be-be41-5da396caf33e' OR (EntityID = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND Name = 'ID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '46a8f6ba-2923-46be-be41-5da396caf33e',
            'A50829B7-110B-48D9-ACB4-B169917BBF41', -- Entity: MJ_BizApps_Common: Person Educations
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41'),
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
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            1,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'd9562be6-1a1f-4973-944a-e079495831d5' OR (EntityID = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND Name = 'PersonID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'd9562be6-1a1f-4973-944a-e079495831d5',
            'A50829B7-110B-48D9-ACB4-B169917BBF41', -- Entity: MJ_BizApps_Common: Person Educations
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41'),
            'PersonID',
            'Person ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            NULL,
            0,
            1,
            0,
            0,
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'bae8d0d8-f7b4-4795-afe6-58290bcfc445' OR (EntityID = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND Name = 'OrganizationID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'bae8d0d8-f7b4-4795-afe6-58290bcfc445',
            'A50829B7-110B-48D9-ACB4-B169917BBF41', -- Entity: MJ_BizApps_Common: Person Educations
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41'),
            'OrganizationID',
            'Organization ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            1,
            NULL,
            0,
            1,
            0,
            0,
            'C70448F9-9792-41D7-A82C-784B66429D54',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '3cb6418a-b35d-4e1d-93ae-e6bc15214803' OR (EntityID = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND Name = 'InstitutionName')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '3cb6418a-b35d-4e1d-93ae-e6bc15214803',
            'A50829B7-110B-48D9-ACB4-B169917BBF41', -- Entity: MJ_BizApps_Common: Person Educations
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41'),
            'InstitutionName',
            'Institution Name',
            'The school name exactly as the source gave it. Kept even when OrganizationID is set, so unmatched names are never lost.',
            'nvarchar',
            510,
            0,
            0,
            0,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            1,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '37549db7-3917-4fec-863d-fe5df0d4b381' OR (EntityID = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND Name = 'Degree')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '37549db7-3917-4fec-863d-fe5df0d4b381',
            'A50829B7-110B-48D9-ACB4-B169917BBF41', -- Entity: MJ_BizApps_Common: Person Educations
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41'),
            'Degree',
            'Degree',
            'Degree as the source gave it, e.g. "Master of Public Administration" or "MPP".',
            'nvarchar',
            400,
            0,
            0,
            1,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            1,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '0b30bc7c-a0f6-4861-9ef3-57dceea0203a' OR (EntityID = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND Name = 'FieldOfStudy')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '0b30bc7c-a0f6-4861-9ef3-57dceea0203a',
            'A50829B7-110B-48D9-ACB4-B169917BBF41', -- Entity: MJ_BizApps_Common: Person Educations
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41'),
            'FieldOfStudy',
            'Field Of Study',
            'Major or field of study, when known.',
            'nvarchar',
            400,
            0,
            0,
            1,
            NULL,
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '485e2d19-8915-4f06-9965-aade644d789a' OR (EntityID = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND Name = 'StartDate')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '485e2d19-8915-4f06-9965-aade644d789a',
            'A50829B7-110B-48D9-ACB4-B169917BBF41', -- Entity: MJ_BizApps_Common: Person Educations
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41'),
            'StartDate',
            'Start Date',
            'Date study began, when known.',
            'date',
            3,
            10,
            0,
            1,
            NULL,
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '7658f588-08cb-49de-bd60-ec377f359638' OR (EntityID = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND Name = 'EndDate')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '7658f588-08cb-49de-bd60-ec377f359638',
            'A50829B7-110B-48D9-ACB4-B169917BBF41', -- Entity: MJ_BizApps_Common: Person Educations
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41'),
            'EndDate',
            'End Date',
            'Graduation or end date, when known.',
            'date',
            3,
            10,
            0,
            1,
            NULL,
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '54d4115f-3f63-4923-82be-4a15e07466f0' OR (EntityID = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND Name = 'Source')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '54d4115f-3f63-4923-82be-4a15e07466f0',
            'A50829B7-110B-48D9-ACB4-B169917BBF41', -- Entity: MJ_BizApps_Common: Person Educations
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41'),
            'Source',
            'Source',
            'Manual (entered by a person), Import (bulk load) or Enrichment (written by an enrichment provider). Enrichment never edits Manual rows.',
            'nvarchar',
            40,
            0,
            0,
            0,
            'Manual',
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8d0113bc-a3da-4155-852f-4a086a5a68cc' OR (EntityID = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND Name = 'SourceSystem')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '8d0113bc-a3da-4155-852f-4a086a5a68cc',
            'A50829B7-110B-48D9-ACB4-B169917BBF41', -- Entity: MJ_BizApps_Common: Person Educations
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41'),
            'SourceSystem',
            'Source System',
            'Which system supplied a non-manual row. Equals EnrichmentProvider.Code for enrichment rows.',
            'nvarchar',
            160,
            0,
            0,
            1,
            NULL,
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'a77e85cd-bb84-4aa6-a24b-33a818522689' OR (EntityID = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND Name = 'LastVerifiedAt')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'a77e85cd-bb84-4aa6-a24b-33a818522689',
            'A50829B7-110B-48D9-ACB4-B169917BBF41', -- Entity: MJ_BizApps_Common: Person Educations
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41'),
            'LastVerifiedAt',
            'Last Verified At',
            'When the source last confirmed this row.',
            'datetimeoffset',
            10,
            34,
            7,
            1,
            NULL,
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '7a710139-1a81-4106-a723-48e5e256b72c' OR (EntityID = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND Name = 'Notes')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '7a710139-1a81-4106-a723-48e5e256b72c',
            'A50829B7-110B-48D9-ACB4-B169917BBF41', -- Entity: MJ_BizApps_Common: Person Educations
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41'),
            'Notes',
            'Notes',
            'Free text.',
            'nvarchar',
            -1,
            0,
            0,
            1,
            NULL,
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '238ddb26-b96c-49ec-81c8-f99296f441cc' OR (EntityID = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND Name = '__mj_CreatedAt')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '238ddb26-b96c-49ec-81c8-f99296f441cc',
            'A50829B7-110B-48D9-ACB4-B169917BBF41', -- Entity: MJ_BizApps_Common: Person Educations
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41'),
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
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '416c8ce3-11b2-484b-9874-c0cc88e0d46b' OR (EntityID = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND Name = '__mj_UpdatedAt')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '416c8ce3-11b2-484b-9874-c0cc88e0d46b',
            'A50829B7-110B-48D9-ACB4-B169917BBF41', -- Entity: MJ_BizApps_Common: Person Educations
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41'),
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
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'd5f53051-28b5-4a04-b043-d57eaa21c1c1' OR (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = 'Source')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'd5f53051-28b5-4a04-b043-d57eaa21c1c1',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ_BizApps_Common: Relationships
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '709CA9DA-B124-4155-BE39-E857EF672D82'),
            'Source',
            'Source',
            'Manual, Import or Enrichment. Enrichment only updates or ends relationships it created.',
            'nvarchar',
            40,
            0,
            0,
            0,
            'Manual',
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '6e4bcd8b-d195-44d1-bca0-c30397ebc72e' OR (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = 'SourceSystem')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '6e4bcd8b-d195-44d1-bca0-c30397ebc72e',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ_BizApps_Common: Relationships
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '709CA9DA-B124-4155-BE39-E857EF672D82'),
            'SourceSystem',
            'Source System',
            'Which system supplied a non-manual relationship.',
            'nvarchar',
            160,
            0,
            0,
            1,
            NULL,
            0,
            1,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

/* SQL text to insert entity field value with ID 3ecf8cc6-f4b9-4151-acbd-e0cc63119367 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('3ecf8cc6-f4b9-4151-acbd-e0cc63119367', 'A0198FE1-DF0D-49DD-B6CD-A9C76FDD47FC', 1, 'Count', 'Count', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 66ebbac0-9440-4d21-814d-4b79b8febd24 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('66ebbac0-9440-4d21-814d-4b79b8febd24', 'A0198FE1-DF0D-49DD-B6CD-A9C76FDD47FC', 2, 'Enrich', 'Enrich', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 189f6a3e-b585-4854-94f3-622232faf3bb */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('189f6a3e-b585-4854-94f3-622232faf3bb', 'A0198FE1-DF0D-49DD-B6CD-A9C76FDD47FC', 3, 'SchoolLookup', 'SchoolLookup', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 217d5953-6f73-4223-a407-3d03299fe9eb */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('217d5953-6f73-4223-a407-3d03299fe9eb', 'A0198FE1-DF0D-49DD-B6CD-A9C76FDD47FC', 4, 'Search', 'Search', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID A0198FE1-DF0D-49DD-B6CD-A9C76FDD47FC */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='A0198FE1-DF0D-49DD-B6CD-A9C76FDD47FC';

/* SQL text to insert entity field value with ID 0a8980a4-5dc7-4d18-a9a1-8cb7cd6544b4 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('0a8980a4-5dc7-4d18-a9a1-8cb7cd6544b4', '31BCB292-F75A-4018-8B4E-9CC6F1C445E1', 1, 'MatchedPerson', 'MatchedPerson', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID d4b2e11e-932a-434f-b534-1ca3f2c9c5f8 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('d4b2e11e-932a-434f-b534-1ca3f2c9c5f8', '31BCB292-F75A-4018-8B4E-9CC6F1C445E1', 2, 'NonEmptyRequest', 'NonEmptyRequest', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 81546cbd-b5b8-4365-bfe9-c9daa1d734a9 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('81546cbd-b5b8-4365-bfe9-c9daa1d734a9', '31BCB292-F75A-4018-8B4E-9CC6F1C445E1', 3, 'Request', 'Request', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID f0b249e3-a508-44a6-9f6d-3835a1d5d7df */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('f0b249e3-a508-44a6-9f6d-3835a1d5d7df', '31BCB292-F75A-4018-8B4E-9CC6F1C445E1', 4, 'ReturnedRecord', 'ReturnedRecord', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 31BCB292-F75A-4018-8B4E-9CC6F1C445E1 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='31BCB292-F75A-4018-8B4E-9CC6F1C445E1';

/* SQL text to insert entity field value with ID e28c32fa-c911-4bf5-ac5a-fa8fc193013b */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('e28c32fa-c911-4bf5-ac5a-fa8fc193013b', '54D4115F-3F63-4923-82BE-4A15E07466F0', 1, 'Enrichment', 'Enrichment', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 5ef429f1-9f84-4ee3-b3be-6f1a2faa52ca */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('5ef429f1-9f84-4ee3-b3be-6f1a2faa52ca', '54D4115F-3F63-4923-82BE-4A15E07466F0', 2, 'Import', 'Import', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 04abfcbe-b696-4744-8a38-791409702668 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('04abfcbe-b696-4744-8a38-791409702668', '54D4115F-3F63-4923-82BE-4A15E07466F0', 3, 'Manual', 'Manual', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 54D4115F-3F63-4923-82BE-4A15E07466F0 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='54D4115F-3F63-4923-82BE-4A15E07466F0';

/* SQL text to insert entity field value with ID 7d6f7352-a312-4fdb-b3e3-92cd0353d332 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('7d6f7352-a312-4fdb-b3e3-92cd0353d332', 'D5AA5D25-DBE1-45AC-93A2-07DCAEF834B1', 1, 'Ambiguous', 'Ambiguous', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 3271a1ae-741f-41ef-9e51-248913c29923 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('3271a1ae-741f-41ef-9e51-248913c29923', 'D5AA5D25-DBE1-45AC-93A2-07DCAEF834B1', 2, 'Matched', 'Matched', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID e0620fc5-8031-4d2f-bbe1-2a1d3b94eade */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('e0620fc5-8031-4d2f-bbe1-2a1d3b94eade', 'D5AA5D25-DBE1-45AC-93A2-07DCAEF834B1', 3, 'NotFound', 'NotFound', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID D5AA5D25-DBE1-45AC-93A2-07DCAEF834B1 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='D5AA5D25-DBE1-45AC-93A2-07DCAEF834B1';

/* SQL text to insert entity field value with ID e2761315-ae1c-4c0d-9d74-0471dc5c0aa7 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('e2761315-ae1c-4c0d-9d74-0471dc5c0aa7', '016190CC-296C-4E75-B04B-A61284FF8FD2', 1, 'Email', 'Email', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 9933d86a-adc1-49b4-99b5-d27188396e78 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('9933d86a-adc1-49b4-99b5-d27188396e78', '016190CC-296C-4E75-B04B-A61284FF8FD2', 2, 'ExternalID', 'ExternalID', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 1ae93844-0d03-4b9d-b4f0-111c3a015ebc */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('1ae93844-0d03-4b9d-b4f0-111c3a015ebc', '016190CC-296C-4E75-B04B-A61284FF8FD2', 3, 'LinkedIn', 'LinkedIn', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 71ead1e3-2949-46cd-a083-966766cec8d8 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('71ead1e3-2949-46cd-a083-966766cec8d8', '016190CC-296C-4E75-B04B-A61284FF8FD2', 4, 'Manual', 'Manual', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID f3113fe1-f8e6-4fd3-8d7f-52ffc40b8c49 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('f3113fe1-f8e6-4fd3-8d7f-52ffc40b8c49', '016190CC-296C-4E75-B04B-A61284FF8FD2', 5, 'NameAndDomain', 'NameAndDomain', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 016190CC-296C-4E75-B04B-A61284FF8FD2 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='016190CC-296C-4E75-B04B-A61284FF8FD2';

/* SQL text to insert entity field value with ID 58b0087b-db66-4074-a772-4f89eb7853ed */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('58b0087b-db66-4074-a772-4f89eb7853ed', 'D5F53051-28B5-4A04-B043-D57EAA21C1C1', 1, 'Enrichment', 'Enrichment', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 9acebf73-2d44-4ec3-9fd8-cb0db4291960 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('9acebf73-2d44-4ec3-9fd8-cb0db4291960', 'D5F53051-28B5-4A04-B043-D57EAA21C1C1', 2, 'Import', 'Import', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 9d0eb30c-5392-488e-a2ce-aba1ac4947e6 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('9d0eb30c-5392-488e-a2ce-aba1ac4947e6', 'D5F53051-28B5-4A04-B043-D57EAA21C1C1', 3, 'Manual', 'Manual', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID D5F53051-28B5-4A04-B043-D57EAA21C1C1 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='D5F53051-28B5-4A04-B043-D57EAA21C1C1';

/* Deterministic search-flag hygiene — clear AllowUserSearchAPI */

         UPDATE [${mjSchema}].[Entity]
         SET [AllowUserSearchAPI] = 0
         WHERE [ID] IN (
            SELECT e.[ID]
            FROM [${mjSchema}].[Entity] e
            WHERE e.[AllowUserSearchAPI] = 1
              AND e.[AutoUpdateAllowUserSearchAPI] = 1
              AND e.[VirtualEntity] = 0
              AND ISNULL(e.[FullTextSearchEnabled], 0) = 0
              AND e.[SchemaName] NOT IN ('${mjSchema}','sys')
              AND NOT EXISTS (
               SELECT 1 FROM [${mjSchema}].[EntityField] f2
               WHERE f2.[EntityID] = e.[ID]
                 AND f2.[IncludeInUserSearchAPI] = 1
            )
         );


/* Create Entity Relationship: MJ_BizApps_Common: Enrichment Providers -> MJ_BizApps_Common: Enrichment Provider Rates (One To Many via EnrichmentProviderID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'e1f81c7f-b29f-4582-a36a-19be72ad2896'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('e1f81c7f-b29f-4582-a36a-19be72ad2896', 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', 'FECE9795-E393-4470-B1FD-7D826F505105', 'EnrichmentProviderID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ: Integrations -> MJ_BizApps_Common: Enrichment Providers (One To Many via IntegrationID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '75c6f658-fdb7-4214-afc3-5c94d4922411'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('75c6f658-fdb7-4214-afc3-5c94d4922411', 'DD238F34-2837-EF11-86D4-6045BDEE16E6', 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', 'IntegrationID', 'One To Many', 1, 1, 5, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Organizations -> MJ_BizApps_Common: Person Educations (One To Many via OrganizationID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '18a589a1-b590-4aca-b256-8e4c8f57aec1'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('18a589a1-b590-4aca-b256-8e4c8f57aec1', 'C70448F9-9792-41D7-A82C-784B66429D54', 'A50829B7-110B-48D9-ACB4-B169917BBF41', 'OrganizationID', 'One To Many', 1, 1, 5, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: People -> MJ_BizApps_Common: Person External Identities (One To Many via PersonID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'd773be60-2ec3-40ee-98c5-dfbccc98cce8'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('d773be60-2ec3-40ee-98c5-dfbccc98cce8', '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62', 'PersonID', 'One To Many', 1, 1, 6, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ_BizApps_Common: People -> MJ_BizApps_Common: Person Educations (One To Many via PersonID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'b2239fc0-f067-4661-8077-cae56a28208e'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('b2239fc0-f067-4661-8077-cae56a28208e', '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', 'A50829B7-110B-48D9-ACB4-B169917BBF41', 'PersonID', 'One To Many', 1, 1, 7, GETUTCDATE(), GETUTCDATE())
   END;

/* Index for Foreign Keys for EnrichmentProviderRate */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Enrichment Provider Rates
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key EnrichmentProviderID in table EnrichmentProviderRate
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_EnrichmentProviderRate_EnrichmentProviderID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[EnrichmentProviderRate]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_EnrichmentProviderRate_EnrichmentProviderID ON [${flyway:defaultSchema}].[EnrichmentProviderRate] ([EnrichmentProviderID]);

/* SQL text to update entity field related entity name field map for entity field ID CE7651E6-07DB-47C4-A603-D456E1D0EA14 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='CE7651E6-07DB-47C4-A603-D456E1D0EA14', @RelatedEntityNameFieldMap='EnrichmentProvider';

/* Index for Foreign Keys for EnrichmentProvider */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Enrichment Providers
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key IntegrationID in table EnrichmentProvider
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_EnrichmentProvider_IntegrationID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[EnrichmentProvider]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_EnrichmentProvider_IntegrationID ON [${flyway:defaultSchema}].[EnrichmentProvider] ([IntegrationID]);

/* SQL text to update entity field related entity name field map for entity field ID C45F676E-FE35-4000-AB4C-B80896D48FFB */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='C45F676E-FE35-4000-AB4C-B80896D48FFB', @RelatedEntityNameFieldMap='Integration';

/* SQL text to update entity field related entity name field map for entity field ID EB506B92-343C-434D-B21F-12CFECDA3D3B */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='EB506B92-343C-434D-B21F-12CFECDA3D3B', @RelatedEntityNameFieldMap='SeniorityLevel';

/* Base View SQL for MJ_BizApps_Common: Enrichment Provider Rates */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Enrichment Provider Rates
-- Item: vwEnrichmentProviderRates
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Enrichment Provider Rates
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  EnrichmentProviderRate
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwEnrichmentProviderRates]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwEnrichmentProviderRates];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwEnrichmentProviderRates]
AS
SELECT
    e.*,
    mjBizAppsCommonEnrichmentProvider_EnrichmentProviderID.[Name] AS [EnrichmentProvider]
FROM
    [${flyway:defaultSchema}].[EnrichmentProviderRate] AS e
INNER JOIN
    [${flyway:defaultSchema}].[EnrichmentProvider] AS mjBizAppsCommonEnrichmentProvider_EnrichmentProviderID
  ON
    [e].[EnrichmentProviderID] = mjBizAppsCommonEnrichmentProvider_EnrichmentProviderID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwEnrichmentProviderRates] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Enrichment Provider Rates */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Enrichment Provider Rates
-- Item: Permissions for vwEnrichmentProviderRates
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwEnrichmentProviderRates] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Enrichment Provider Rates */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Enrichment Provider Rates
-- Item: spCreateEnrichmentProviderRate
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR EnrichmentProviderRate
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateEnrichmentProviderRate]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateEnrichmentProviderRate];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateEnrichmentProviderRate]
    @ID uniqueidentifier = NULL,
    @EnrichmentProviderID uniqueidentifier,
    @Operation nvarchar(30),
    @Unit nvarchar(30),
    @CreditsPerUnit decimal(18, 4),
    @Notes_Clear bit = 0,
    @Notes nvarchar(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[EnrichmentProviderRate]
            (
                [ID],
                [EnrichmentProviderID],
                [Operation],
                [Unit],
                [CreditsPerUnit],
                [Notes]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @EnrichmentProviderID,
                @Operation,
                @Unit,
                @CreditsPerUnit,
                CASE WHEN @Notes_Clear = 1 THEN NULL ELSE ISNULL(@Notes, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[EnrichmentProviderRate]
            (
                [EnrichmentProviderID],
                [Operation],
                [Unit],
                [CreditsPerUnit],
                [Notes]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @EnrichmentProviderID,
                @Operation,
                @Unit,
                @CreditsPerUnit,
                CASE WHEN @Notes_Clear = 1 THEN NULL ELSE ISNULL(@Notes, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwEnrichmentProviderRates] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateEnrichmentProviderRate] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Enrichment Provider Rates */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateEnrichmentProviderRate] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Enrichment Provider Rates */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Enrichment Provider Rates
-- Item: spUpdateEnrichmentProviderRate
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR EnrichmentProviderRate
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateEnrichmentProviderRate]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateEnrichmentProviderRate];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateEnrichmentProviderRate]
    @ID uniqueidentifier,
    @EnrichmentProviderID uniqueidentifier = NULL,
    @Operation nvarchar(30) = NULL,
    @Unit nvarchar(30) = NULL,
    @CreditsPerUnit decimal(18, 4) = NULL,
    @Notes_Clear bit = 0,
    @Notes nvarchar(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[EnrichmentProviderRate]
    SET
        [EnrichmentProviderID] = ISNULL(@EnrichmentProviderID, [EnrichmentProviderID]),
        [Operation] = ISNULL(@Operation, [Operation]),
        [Unit] = ISNULL(@Unit, [Unit]),
        [CreditsPerUnit] = ISNULL(@CreditsPerUnit, [CreditsPerUnit]),
        [Notes] = CASE WHEN @Notes_Clear = 1 THEN NULL ELSE ISNULL(@Notes, [Notes]) END
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwEnrichmentProviderRates] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwEnrichmentProviderRates]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateEnrichmentProviderRate] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the EnrichmentProviderRate table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateEnrichmentProviderRate]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateEnrichmentProviderRate];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateEnrichmentProviderRate
ON [${flyway:defaultSchema}].[EnrichmentProviderRate]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[EnrichmentProviderRate]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[EnrichmentProviderRate] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Enrichment Provider Rates */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateEnrichmentProviderRate] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Enrichment Provider Rates */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Enrichment Provider Rates
-- Item: spDeleteEnrichmentProviderRate
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR EnrichmentProviderRate
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteEnrichmentProviderRate]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteEnrichmentProviderRate];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteEnrichmentProviderRate]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[EnrichmentProviderRate]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteEnrichmentProviderRate] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Enrichment Provider Rates */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteEnrichmentProviderRate] TO [cdp_Developer], [cdp_Integration];

/* Base View SQL for MJ_BizApps_Common: Enrichment Providers */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Enrichment Providers
-- Item: vwEnrichmentProviders
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Enrichment Providers
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  EnrichmentProvider
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwEnrichmentProviders]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwEnrichmentProviders];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwEnrichmentProviders]
AS
SELECT
    e.*,
    MJIntegration_IntegrationID.[Name] AS [Integration]
FROM
    [${flyway:defaultSchema}].[EnrichmentProvider] AS e
LEFT OUTER JOIN
    [${mjSchema}].[Integration] AS MJIntegration_IntegrationID
  ON
    [e].[IntegrationID] = MJIntegration_IntegrationID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwEnrichmentProviders] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Enrichment Providers */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Enrichment Providers
-- Item: Permissions for vwEnrichmentProviders
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwEnrichmentProviders] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Enrichment Providers */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Enrichment Providers
-- Item: spCreateEnrichmentProvider
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR EnrichmentProvider
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateEnrichmentProvider]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateEnrichmentProvider];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateEnrichmentProvider]
    @ID uniqueidentifier = NULL,
    @Code nvarchar(60),
    @Name nvarchar(100),
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @DriverClass nvarchar(200),
    @IntegrationID_Clear bit = 0,
    @IntegrationID uniqueidentifier = NULL,
    @MaxBatchSize int = NULL,
    @RequestsPerMinute_Clear bit = 0,
    @RequestsPerMinute int = NULL,
    @Configuration_Clear bit = 0,
    @Configuration nvarchar(MAX) = NULL,
    @CreditPrice_Clear bit = 0,
    @CreditPrice decimal(18, 6) = NULL,
    @CreditCurrency_Clear bit = 0,
    @CreditCurrency nchar(3) = NULL,
    @Sequence int = NULL,
    @IsActive bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[EnrichmentProvider]
            (
                [ID],
                [Code],
                [Name],
                [Description],
                [DriverClass],
                [IntegrationID],
                [MaxBatchSize],
                [RequestsPerMinute],
                [Configuration],
                [CreditPrice],
                [CreditCurrency],
                [Sequence],
                [IsActive]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Code,
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                @DriverClass,
                CASE WHEN @IntegrationID_Clear = 1 THEN NULL ELSE ISNULL(@IntegrationID, NULL) END,
                ISNULL(@MaxBatchSize, 10),
                CASE WHEN @RequestsPerMinute_Clear = 1 THEN NULL ELSE ISNULL(@RequestsPerMinute, NULL) END,
                CASE WHEN @Configuration_Clear = 1 THEN NULL ELSE ISNULL(@Configuration, NULL) END,
                CASE WHEN @CreditPrice_Clear = 1 THEN NULL ELSE ISNULL(@CreditPrice, NULL) END,
                CASE WHEN @CreditCurrency_Clear = 1 THEN NULL ELSE ISNULL(@CreditCurrency, NULL) END,
                ISNULL(@Sequence, 0),
                ISNULL(@IsActive, 1)
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[EnrichmentProvider]
            (
                [Code],
                [Name],
                [Description],
                [DriverClass],
                [IntegrationID],
                [MaxBatchSize],
                [RequestsPerMinute],
                [Configuration],
                [CreditPrice],
                [CreditCurrency],
                [Sequence],
                [IsActive]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Code,
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                @DriverClass,
                CASE WHEN @IntegrationID_Clear = 1 THEN NULL ELSE ISNULL(@IntegrationID, NULL) END,
                ISNULL(@MaxBatchSize, 10),
                CASE WHEN @RequestsPerMinute_Clear = 1 THEN NULL ELSE ISNULL(@RequestsPerMinute, NULL) END,
                CASE WHEN @Configuration_Clear = 1 THEN NULL ELSE ISNULL(@Configuration, NULL) END,
                CASE WHEN @CreditPrice_Clear = 1 THEN NULL ELSE ISNULL(@CreditPrice, NULL) END,
                CASE WHEN @CreditCurrency_Clear = 1 THEN NULL ELSE ISNULL(@CreditCurrency, NULL) END,
                ISNULL(@Sequence, 0),
                ISNULL(@IsActive, 1)
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwEnrichmentProviders] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateEnrichmentProvider] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Enrichment Providers */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateEnrichmentProvider] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Enrichment Providers */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Enrichment Providers
-- Item: spUpdateEnrichmentProvider
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR EnrichmentProvider
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateEnrichmentProvider]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateEnrichmentProvider];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateEnrichmentProvider]
    @ID uniqueidentifier,
    @Code nvarchar(60) = NULL,
    @Name nvarchar(100) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @DriverClass nvarchar(200) = NULL,
    @IntegrationID_Clear bit = 0,
    @IntegrationID uniqueidentifier = NULL,
    @MaxBatchSize int = NULL,
    @RequestsPerMinute_Clear bit = 0,
    @RequestsPerMinute int = NULL,
    @Configuration_Clear bit = 0,
    @Configuration nvarchar(MAX) = NULL,
    @CreditPrice_Clear bit = 0,
    @CreditPrice decimal(18, 6) = NULL,
    @CreditCurrency_Clear bit = 0,
    @CreditCurrency nchar(3) = NULL,
    @Sequence int = NULL,
    @IsActive bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[EnrichmentProvider]
    SET
        [Code] = ISNULL(@Code, [Code]),
        [Name] = ISNULL(@Name, [Name]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [DriverClass] = ISNULL(@DriverClass, [DriverClass]),
        [IntegrationID] = CASE WHEN @IntegrationID_Clear = 1 THEN NULL ELSE ISNULL(@IntegrationID, [IntegrationID]) END,
        [MaxBatchSize] = ISNULL(@MaxBatchSize, [MaxBatchSize]),
        [RequestsPerMinute] = CASE WHEN @RequestsPerMinute_Clear = 1 THEN NULL ELSE ISNULL(@RequestsPerMinute, [RequestsPerMinute]) END,
        [Configuration] = CASE WHEN @Configuration_Clear = 1 THEN NULL ELSE ISNULL(@Configuration, [Configuration]) END,
        [CreditPrice] = CASE WHEN @CreditPrice_Clear = 1 THEN NULL ELSE ISNULL(@CreditPrice, [CreditPrice]) END,
        [CreditCurrency] = CASE WHEN @CreditCurrency_Clear = 1 THEN NULL ELSE ISNULL(@CreditCurrency, [CreditCurrency]) END,
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [IsActive] = ISNULL(@IsActive, [IsActive])
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwEnrichmentProviders] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwEnrichmentProviders]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateEnrichmentProvider] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the EnrichmentProvider table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateEnrichmentProvider]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateEnrichmentProvider];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateEnrichmentProvider
ON [${flyway:defaultSchema}].[EnrichmentProvider]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[EnrichmentProvider]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[EnrichmentProvider] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Enrichment Providers */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateEnrichmentProvider] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Enrichment Providers */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Enrichment Providers
-- Item: spDeleteEnrichmentProvider
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR EnrichmentProvider
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteEnrichmentProvider]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteEnrichmentProvider];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteEnrichmentProvider]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[EnrichmentProvider]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteEnrichmentProvider] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Enrichment Providers */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteEnrichmentProvider] TO [cdp_Developer], [cdp_Integration];

/* Index for Foreign Keys for PersonEducation */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person Educations
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key PersonID in table PersonEducation
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_PersonEducation_PersonID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[PersonEducation]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_PersonEducation_PersonID ON [${flyway:defaultSchema}].[PersonEducation] ([PersonID]);

-- Index for foreign key OrganizationID in table PersonEducation
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_PersonEducation_OrganizationID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[PersonEducation]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_PersonEducation_OrganizationID ON [${flyway:defaultSchema}].[PersonEducation] ([OrganizationID]);

/* SQL text to update entity field related entity name field map for entity field ID D9562BE6-1A1F-4973-944A-E079495831D5 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='D9562BE6-1A1F-4973-944A-E079495831D5', @RelatedEntityNameFieldMap='Person';

/* Index for Foreign Keys for PersonExternalIdentity */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person External Identities
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key PersonID in table PersonExternalIdentity
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_PersonExternalIdentity_PersonID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[PersonExternalIdentity]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_PersonExternalIdentity_PersonID ON [${flyway:defaultSchema}].[PersonExternalIdentity] ([PersonID]);

/* SQL text to update entity field related entity name field map for entity field ID B8247A33-A3E3-4E75-AA71-4C5B1599875E */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='B8247A33-A3E3-4E75-AA71-4C5B1599875E', @RelatedEntityNameFieldMap='Person';

/* SQL text to update entity field related entity name field map for entity field ID 4389D414-26D3-463E-A90D-38AFA3836E5C */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='4389D414-26D3-463E-A90D-38AFA3836E5C', @RelatedEntityNameFieldMap='Person';

/* Index for Foreign Keys for Relationship */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
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
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Relationship]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Relationship_RelationshipTypeID ON [${flyway:defaultSchema}].[Relationship] ([RelationshipTypeID]);

-- Index for foreign key FromPersonID in table Relationship
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Relationship_FromPersonID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Relationship]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Relationship_FromPersonID ON [${flyway:defaultSchema}].[Relationship] ([FromPersonID]);

-- Index for foreign key FromOrganizationID in table Relationship
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Relationship_FromOrganizationID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Relationship]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Relationship_FromOrganizationID ON [${flyway:defaultSchema}].[Relationship] ([FromOrganizationID]);

-- Index for foreign key ToPersonID in table Relationship
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Relationship_ToPersonID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Relationship]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Relationship_ToPersonID ON [${flyway:defaultSchema}].[Relationship] ([ToPersonID]);

-- Index for foreign key ToOrganizationID in table Relationship
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Relationship_ToOrganizationID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Relationship]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Relationship_ToOrganizationID ON [${flyway:defaultSchema}].[Relationship] ([ToOrganizationID]);

-- Index for foreign key JobFunctionID in table Relationship
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Relationship_JobFunctionID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Relationship]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Relationship_JobFunctionID ON [${flyway:defaultSchema}].[Relationship] ([JobFunctionID]);

-- Index for foreign key SeniorityLevelID in table Relationship
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Relationship_SeniorityLevelID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Relationship]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Relationship_SeniorityLevelID ON [${flyway:defaultSchema}].[Relationship] ([SeniorityLevelID]);

/* SQL text to update entity field related entity name field map for entity field ID 0E353B64-06BA-4582-8532-5DB427B539EE */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='0E353B64-06BA-4582-8532-5DB427B539EE', @RelatedEntityNameFieldMap='JobFunction';

/* Base View SQL for MJ_BizApps_Common: Person External Identities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person External Identities
-- Item: vwPersonExternalIdentities
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Person External Identities
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  PersonExternalIdentity
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwPersonExternalIdentities]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwPersonExternalIdentities];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwPersonExternalIdentities]
AS
SELECT
    p.*,
    mjBizAppsCommonPerson_PersonID.[DisplayName] AS [Person]
FROM
    [${flyway:defaultSchema}].[PersonExternalIdentity] AS p
INNER JOIN
    [${flyway:defaultSchema}].[Person] AS mjBizAppsCommonPerson_PersonID
  ON
    [p].[PersonID] = mjBizAppsCommonPerson_PersonID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwPersonExternalIdentities] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Person External Identities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person External Identities
-- Item: Permissions for vwPersonExternalIdentities
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwPersonExternalIdentities] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Person External Identities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person External Identities
-- Item: spCreatePersonExternalIdentity
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR PersonExternalIdentity
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreatePersonExternalIdentity]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreatePersonExternalIdentity];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreatePersonExternalIdentity]
    @ID uniqueidentifier = NULL,
    @PersonID uniqueidentifier,
    @SourceSystem nvarchar(80),
    @ExternalID_Clear bit = 0,
    @ExternalID nvarchar(400) = NULL,
    @MatchStatus nvarchar(20) = NULL,
    @MatchedBy_Clear bit = 0,
    @MatchedBy nvarchar(20) = NULL,
    @MatchConfidence_Clear bit = 0,
    @MatchConfidence decimal(5, 4) = NULL,
    @LastCheckedAt datetimeoffset,
    @LastMatchedAt_Clear bit = 0,
    @LastMatchedAt datetimeoffset = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[PersonExternalIdentity]
            (
                [ID],
                [PersonID],
                [SourceSystem],
                [ExternalID],
                [MatchStatus],
                [MatchedBy],
                [MatchConfidence],
                [LastCheckedAt],
                [LastMatchedAt]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @PersonID,
                @SourceSystem,
                CASE WHEN @ExternalID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalID, NULL) END,
                ISNULL(@MatchStatus, 'Matched'),
                CASE WHEN @MatchedBy_Clear = 1 THEN NULL ELSE ISNULL(@MatchedBy, NULL) END,
                CASE WHEN @MatchConfidence_Clear = 1 THEN NULL ELSE ISNULL(@MatchConfidence, NULL) END,
                @LastCheckedAt,
                CASE WHEN @LastMatchedAt_Clear = 1 THEN NULL ELSE ISNULL(@LastMatchedAt, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[PersonExternalIdentity]
            (
                [PersonID],
                [SourceSystem],
                [ExternalID],
                [MatchStatus],
                [MatchedBy],
                [MatchConfidence],
                [LastCheckedAt],
                [LastMatchedAt]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @PersonID,
                @SourceSystem,
                CASE WHEN @ExternalID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalID, NULL) END,
                ISNULL(@MatchStatus, 'Matched'),
                CASE WHEN @MatchedBy_Clear = 1 THEN NULL ELSE ISNULL(@MatchedBy, NULL) END,
                CASE WHEN @MatchConfidence_Clear = 1 THEN NULL ELSE ISNULL(@MatchConfidence, NULL) END,
                @LastCheckedAt,
                CASE WHEN @LastMatchedAt_Clear = 1 THEN NULL ELSE ISNULL(@LastMatchedAt, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwPersonExternalIdentities] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreatePersonExternalIdentity] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Person External Identities */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreatePersonExternalIdentity] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Person External Identities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person External Identities
-- Item: spUpdatePersonExternalIdentity
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR PersonExternalIdentity
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdatePersonExternalIdentity]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdatePersonExternalIdentity];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdatePersonExternalIdentity]
    @ID uniqueidentifier,
    @PersonID uniqueidentifier = NULL,
    @SourceSystem nvarchar(80) = NULL,
    @ExternalID_Clear bit = 0,
    @ExternalID nvarchar(400) = NULL,
    @MatchStatus nvarchar(20) = NULL,
    @MatchedBy_Clear bit = 0,
    @MatchedBy nvarchar(20) = NULL,
    @MatchConfidence_Clear bit = 0,
    @MatchConfidence decimal(5, 4) = NULL,
    @LastCheckedAt datetimeoffset = NULL,
    @LastMatchedAt_Clear bit = 0,
    @LastMatchedAt datetimeoffset = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[PersonExternalIdentity]
    SET
        [PersonID] = ISNULL(@PersonID, [PersonID]),
        [SourceSystem] = ISNULL(@SourceSystem, [SourceSystem]),
        [ExternalID] = CASE WHEN @ExternalID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalID, [ExternalID]) END,
        [MatchStatus] = ISNULL(@MatchStatus, [MatchStatus]),
        [MatchedBy] = CASE WHEN @MatchedBy_Clear = 1 THEN NULL ELSE ISNULL(@MatchedBy, [MatchedBy]) END,
        [MatchConfidence] = CASE WHEN @MatchConfidence_Clear = 1 THEN NULL ELSE ISNULL(@MatchConfidence, [MatchConfidence]) END,
        [LastCheckedAt] = ISNULL(@LastCheckedAt, [LastCheckedAt]),
        [LastMatchedAt] = CASE WHEN @LastMatchedAt_Clear = 1 THEN NULL ELSE ISNULL(@LastMatchedAt, [LastMatchedAt]) END
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwPersonExternalIdentities] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwPersonExternalIdentities]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdatePersonExternalIdentity] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the PersonExternalIdentity table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdatePersonExternalIdentity]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdatePersonExternalIdentity];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdatePersonExternalIdentity
ON [${flyway:defaultSchema}].[PersonExternalIdentity]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[PersonExternalIdentity]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[PersonExternalIdentity] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Person External Identities */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdatePersonExternalIdentity] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Person External Identities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person External Identities
-- Item: spDeletePersonExternalIdentity
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR PersonExternalIdentity
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeletePersonExternalIdentity]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeletePersonExternalIdentity];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeletePersonExternalIdentity]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[PersonExternalIdentity]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeletePersonExternalIdentity] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Person External Identities */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeletePersonExternalIdentity] TO [cdp_Developer], [cdp_Integration];

/* SQL text to update entity field related entity name field map for entity field ID BAE8D0D8-F7B4-4795-AFE6-58290BCFC445 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='BAE8D0D8-F7B4-4795-AFE6-58290BCFC445', @RelatedEntityNameFieldMap='Organization';

/* SQL text to update entity field related entity name field map for entity field ID 438BD1D0-764F-4D90-A51F-24C150CB8313 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='438BD1D0-764F-4D90-A51F-24C150CB8313', @RelatedEntityNameFieldMap='SeniorityLevel';

/* Base View SQL for MJ_BizApps_Common: Person Educations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person Educations
-- Item: vwPersonEducations
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Person Educations
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  PersonEducation
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwPersonEducations]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwPersonEducations];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwPersonEducations]
AS
SELECT
    p.*,
    mjBizAppsCommonPerson_PersonID.[DisplayName] AS [Person],
    mjBizAppsCommonOrganization_OrganizationID.[Name] AS [Organization]
FROM
    [${flyway:defaultSchema}].[PersonEducation] AS p
INNER JOIN
    [${flyway:defaultSchema}].[Person] AS mjBizAppsCommonPerson_PersonID
  ON
    [p].[PersonID] = mjBizAppsCommonPerson_PersonID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Organization] AS mjBizAppsCommonOrganization_OrganizationID
  ON
    [p].[OrganizationID] = mjBizAppsCommonOrganization_OrganizationID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwPersonEducations] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Person Educations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person Educations
-- Item: Permissions for vwPersonEducations
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwPersonEducations] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Person Educations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person Educations
-- Item: spCreatePersonEducation
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR PersonEducation
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreatePersonEducation]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreatePersonEducation];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreatePersonEducation]
    @ID uniqueidentifier = NULL,
    @PersonID uniqueidentifier,
    @OrganizationID_Clear bit = 0,
    @OrganizationID uniqueidentifier = NULL,
    @InstitutionName nvarchar(255),
    @Degree_Clear bit = 0,
    @Degree nvarchar(200) = NULL,
    @FieldOfStudy_Clear bit = 0,
    @FieldOfStudy nvarchar(200) = NULL,
    @StartDate_Clear bit = 0,
    @StartDate date = NULL,
    @EndDate_Clear bit = 0,
    @EndDate date = NULL,
    @Source nvarchar(20) = NULL,
    @SourceSystem_Clear bit = 0,
    @SourceSystem nvarchar(80) = NULL,
    @LastVerifiedAt_Clear bit = 0,
    @LastVerifiedAt datetimeoffset = NULL,
    @Notes_Clear bit = 0,
    @Notes nvarchar(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[PersonEducation]
            (
                [ID],
                [PersonID],
                [OrganizationID],
                [InstitutionName],
                [Degree],
                [FieldOfStudy],
                [StartDate],
                [EndDate],
                [Source],
                [SourceSystem],
                [LastVerifiedAt],
                [Notes]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @PersonID,
                CASE WHEN @OrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationID, NULL) END,
                @InstitutionName,
                CASE WHEN @Degree_Clear = 1 THEN NULL ELSE ISNULL(@Degree, NULL) END,
                CASE WHEN @FieldOfStudy_Clear = 1 THEN NULL ELSE ISNULL(@FieldOfStudy, NULL) END,
                CASE WHEN @StartDate_Clear = 1 THEN NULL ELSE ISNULL(@StartDate, NULL) END,
                CASE WHEN @EndDate_Clear = 1 THEN NULL ELSE ISNULL(@EndDate, NULL) END,
                ISNULL(@Source, 'Manual'),
                CASE WHEN @SourceSystem_Clear = 1 THEN NULL ELSE ISNULL(@SourceSystem, NULL) END,
                CASE WHEN @LastVerifiedAt_Clear = 1 THEN NULL ELSE ISNULL(@LastVerifiedAt, NULL) END,
                CASE WHEN @Notes_Clear = 1 THEN NULL ELSE ISNULL(@Notes, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[PersonEducation]
            (
                [PersonID],
                [OrganizationID],
                [InstitutionName],
                [Degree],
                [FieldOfStudy],
                [StartDate],
                [EndDate],
                [Source],
                [SourceSystem],
                [LastVerifiedAt],
                [Notes]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @PersonID,
                CASE WHEN @OrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationID, NULL) END,
                @InstitutionName,
                CASE WHEN @Degree_Clear = 1 THEN NULL ELSE ISNULL(@Degree, NULL) END,
                CASE WHEN @FieldOfStudy_Clear = 1 THEN NULL ELSE ISNULL(@FieldOfStudy, NULL) END,
                CASE WHEN @StartDate_Clear = 1 THEN NULL ELSE ISNULL(@StartDate, NULL) END,
                CASE WHEN @EndDate_Clear = 1 THEN NULL ELSE ISNULL(@EndDate, NULL) END,
                ISNULL(@Source, 'Manual'),
                CASE WHEN @SourceSystem_Clear = 1 THEN NULL ELSE ISNULL(@SourceSystem, NULL) END,
                CASE WHEN @LastVerifiedAt_Clear = 1 THEN NULL ELSE ISNULL(@LastVerifiedAt, NULL) END,
                CASE WHEN @Notes_Clear = 1 THEN NULL ELSE ISNULL(@Notes, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwPersonEducations] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreatePersonEducation] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Person Educations */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreatePersonEducation] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Person Educations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person Educations
-- Item: spUpdatePersonEducation
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR PersonEducation
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdatePersonEducation]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdatePersonEducation];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdatePersonEducation]
    @ID uniqueidentifier,
    @PersonID uniqueidentifier = NULL,
    @OrganizationID_Clear bit = 0,
    @OrganizationID uniqueidentifier = NULL,
    @InstitutionName nvarchar(255) = NULL,
    @Degree_Clear bit = 0,
    @Degree nvarchar(200) = NULL,
    @FieldOfStudy_Clear bit = 0,
    @FieldOfStudy nvarchar(200) = NULL,
    @StartDate_Clear bit = 0,
    @StartDate date = NULL,
    @EndDate_Clear bit = 0,
    @EndDate date = NULL,
    @Source nvarchar(20) = NULL,
    @SourceSystem_Clear bit = 0,
    @SourceSystem nvarchar(80) = NULL,
    @LastVerifiedAt_Clear bit = 0,
    @LastVerifiedAt datetimeoffset = NULL,
    @Notes_Clear bit = 0,
    @Notes nvarchar(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[PersonEducation]
    SET
        [PersonID] = ISNULL(@PersonID, [PersonID]),
        [OrganizationID] = CASE WHEN @OrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationID, [OrganizationID]) END,
        [InstitutionName] = ISNULL(@InstitutionName, [InstitutionName]),
        [Degree] = CASE WHEN @Degree_Clear = 1 THEN NULL ELSE ISNULL(@Degree, [Degree]) END,
        [FieldOfStudy] = CASE WHEN @FieldOfStudy_Clear = 1 THEN NULL ELSE ISNULL(@FieldOfStudy, [FieldOfStudy]) END,
        [StartDate] = CASE WHEN @StartDate_Clear = 1 THEN NULL ELSE ISNULL(@StartDate, [StartDate]) END,
        [EndDate] = CASE WHEN @EndDate_Clear = 1 THEN NULL ELSE ISNULL(@EndDate, [EndDate]) END,
        [Source] = ISNULL(@Source, [Source]),
        [SourceSystem] = CASE WHEN @SourceSystem_Clear = 1 THEN NULL ELSE ISNULL(@SourceSystem, [SourceSystem]) END,
        [LastVerifiedAt] = CASE WHEN @LastVerifiedAt_Clear = 1 THEN NULL ELSE ISNULL(@LastVerifiedAt, [LastVerifiedAt]) END,
        [Notes] = CASE WHEN @Notes_Clear = 1 THEN NULL ELSE ISNULL(@Notes, [Notes]) END
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwPersonEducations] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwPersonEducations]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdatePersonEducation] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the PersonEducation table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdatePersonEducation]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdatePersonEducation];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdatePersonEducation
ON [${flyway:defaultSchema}].[PersonEducation]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[PersonEducation]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[PersonEducation] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Person Educations */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdatePersonEducation] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Person Educations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person Educations
-- Item: spDeletePersonEducation
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR PersonEducation
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeletePersonEducation]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeletePersonEducation];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeletePersonEducation]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[PersonEducation]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeletePersonEducation] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Person Educations */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeletePersonEducation] TO [cdp_Developer], [cdp_Integration];

/* Base View SQL for MJ_BizApps_Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
-- Item: vwRelationships
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Relationships
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  Relationship
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwRelationships]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwRelationships];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwRelationships]
AS
SELECT
    r.*,
    mjBizAppsCommonRelationshipType_RelationshipTypeID.[Name] AS [RelationshipType],
    mjBizAppsCommonPerson_FromPersonID.[DisplayName] AS [FromPerson],
    mjBizAppsCommonOrganization_FromOrganizationID.[Name] AS [FromOrganization],
    mjBizAppsCommonPerson_ToPersonID.[DisplayName] AS [ToPerson],
    mjBizAppsCommonOrganization_ToOrganizationID.[Name] AS [ToOrganization],
    mjBizAppsCommonJobFunction_JobFunctionID.[Name] AS [JobFunction],
    mjBizAppsCommonSeniorityLevel_SeniorityLevelID.[Name] AS [SeniorityLevel]
FROM
    [${flyway:defaultSchema}].[Relationship] AS r
INNER JOIN
    [${flyway:defaultSchema}].[RelationshipType] AS mjBizAppsCommonRelationshipType_RelationshipTypeID
  ON
    [r].[RelationshipTypeID] = mjBizAppsCommonRelationshipType_RelationshipTypeID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Person] AS mjBizAppsCommonPerson_FromPersonID
  ON
    [r].[FromPersonID] = mjBizAppsCommonPerson_FromPersonID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Organization] AS mjBizAppsCommonOrganization_FromOrganizationID
  ON
    [r].[FromOrganizationID] = mjBizAppsCommonOrganization_FromOrganizationID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Person] AS mjBizAppsCommonPerson_ToPersonID
  ON
    [r].[ToPersonID] = mjBizAppsCommonPerson_ToPersonID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Organization] AS mjBizAppsCommonOrganization_ToOrganizationID
  ON
    [r].[ToOrganizationID] = mjBizAppsCommonOrganization_ToOrganizationID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[JobFunction] AS mjBizAppsCommonJobFunction_JobFunctionID
  ON
    [r].[JobFunctionID] = mjBizAppsCommonJobFunction_JobFunctionID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[SeniorityLevel] AS mjBizAppsCommonSeniorityLevel_SeniorityLevelID
  ON
    [r].[SeniorityLevelID] = mjBizAppsCommonSeniorityLevel_SeniorityLevelID.[ID]
GO
REVOKE SELECT ON [${flyway:defaultSchema}].[vwRelationships] FROM [cdp_Developer]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwRelationships] FROM [cdp_Integration]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwRelationships] FROM [cdp_UI]
GRANT SELECT ON [${flyway:defaultSchema}].[vwRelationships] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
-- Item: Permissions for vwRelationships
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

REVOKE SELECT ON [${flyway:defaultSchema}].[vwRelationships] FROM [cdp_Developer]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwRelationships] FROM [cdp_Integration]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwRelationships] FROM [cdp_UI]
GRANT SELECT ON [${flyway:defaultSchema}].[vwRelationships] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
-- Item: spCreateRelationship
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Relationship
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateRelationship]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateRelationship];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateRelationship]
    @ID uniqueidentifier = NULL,
    @RelationshipTypeID uniqueidentifier,
    @FromPersonID_Clear bit = 0,
    @FromPersonID uniqueidentifier = NULL,
    @FromOrganizationID_Clear bit = 0,
    @FromOrganizationID uniqueidentifier = NULL,
    @ToPersonID_Clear bit = 0,
    @ToPersonID uniqueidentifier = NULL,
    @ToOrganizationID_Clear bit = 0,
    @ToOrganizationID uniqueidentifier = NULL,
    @Title_Clear bit = 0,
    @Title nvarchar(255) = NULL,
    @StartDate_Clear bit = 0,
    @StartDate date = NULL,
    @EndDate_Clear bit = 0,
    @EndDate date = NULL,
    @Status nvarchar(50) = NULL,
    @Notes_Clear bit = 0,
    @Notes nvarchar(MAX) = NULL,
    @JobFunctionID_Clear bit = 0,
    @JobFunctionID uniqueidentifier = NULL,
    @SeniorityLevelID_Clear bit = 0,
    @SeniorityLevelID uniqueidentifier = NULL,
    @Source nvarchar(20) = NULL,
    @SourceSystem_Clear bit = 0,
    @SourceSystem nvarchar(80) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[Relationship]
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
                [Notes],
                [JobFunctionID],
                [SeniorityLevelID],
                [Source],
                [SourceSystem]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @RelationshipTypeID,
                CASE WHEN @FromPersonID_Clear = 1 THEN NULL ELSE ISNULL(@FromPersonID, NULL) END,
                CASE WHEN @FromOrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@FromOrganizationID, NULL) END,
                CASE WHEN @ToPersonID_Clear = 1 THEN NULL ELSE ISNULL(@ToPersonID, NULL) END,
                CASE WHEN @ToOrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@ToOrganizationID, NULL) END,
                CASE WHEN @Title_Clear = 1 THEN NULL ELSE ISNULL(@Title, NULL) END,
                CASE WHEN @StartDate_Clear = 1 THEN NULL ELSE ISNULL(@StartDate, NULL) END,
                CASE WHEN @EndDate_Clear = 1 THEN NULL ELSE ISNULL(@EndDate, NULL) END,
                ISNULL(@Status, 'Active'),
                CASE WHEN @Notes_Clear = 1 THEN NULL ELSE ISNULL(@Notes, NULL) END,
                CASE WHEN @JobFunctionID_Clear = 1 THEN NULL ELSE ISNULL(@JobFunctionID, NULL) END,
                CASE WHEN @SeniorityLevelID_Clear = 1 THEN NULL ELSE ISNULL(@SeniorityLevelID, NULL) END,
                ISNULL(@Source, 'Manual'),
                CASE WHEN @SourceSystem_Clear = 1 THEN NULL ELSE ISNULL(@SourceSystem, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[Relationship]
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
                [Notes],
                [JobFunctionID],
                [SeniorityLevelID],
                [Source],
                [SourceSystem]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @RelationshipTypeID,
                CASE WHEN @FromPersonID_Clear = 1 THEN NULL ELSE ISNULL(@FromPersonID, NULL) END,
                CASE WHEN @FromOrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@FromOrganizationID, NULL) END,
                CASE WHEN @ToPersonID_Clear = 1 THEN NULL ELSE ISNULL(@ToPersonID, NULL) END,
                CASE WHEN @ToOrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@ToOrganizationID, NULL) END,
                CASE WHEN @Title_Clear = 1 THEN NULL ELSE ISNULL(@Title, NULL) END,
                CASE WHEN @StartDate_Clear = 1 THEN NULL ELSE ISNULL(@StartDate, NULL) END,
                CASE WHEN @EndDate_Clear = 1 THEN NULL ELSE ISNULL(@EndDate, NULL) END,
                ISNULL(@Status, 'Active'),
                CASE WHEN @Notes_Clear = 1 THEN NULL ELSE ISNULL(@Notes, NULL) END,
                CASE WHEN @JobFunctionID_Clear = 1 THEN NULL ELSE ISNULL(@JobFunctionID, NULL) END,
                CASE WHEN @SeniorityLevelID_Clear = 1 THEN NULL ELSE ISNULL(@SeniorityLevelID, NULL) END,
                ISNULL(@Source, 'Manual'),
                CASE WHEN @SourceSystem_Clear = 1 THEN NULL ELSE ISNULL(@SourceSystem, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwRelationships] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateRelationship] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateRelationship] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateRelationship] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Relationships */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateRelationship] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateRelationship] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateRelationship] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
-- Item: spUpdateRelationship
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Relationship
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateRelationship]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateRelationship];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateRelationship]
    @ID uniqueidentifier,
    @RelationshipTypeID uniqueidentifier = NULL,
    @FromPersonID_Clear bit = 0,
    @FromPersonID uniqueidentifier = NULL,
    @FromOrganizationID_Clear bit = 0,
    @FromOrganizationID uniqueidentifier = NULL,
    @ToPersonID_Clear bit = 0,
    @ToPersonID uniqueidentifier = NULL,
    @ToOrganizationID_Clear bit = 0,
    @ToOrganizationID uniqueidentifier = NULL,
    @Title_Clear bit = 0,
    @Title nvarchar(255) = NULL,
    @StartDate_Clear bit = 0,
    @StartDate date = NULL,
    @EndDate_Clear bit = 0,
    @EndDate date = NULL,
    @Status nvarchar(50) = NULL,
    @Notes_Clear bit = 0,
    @Notes nvarchar(MAX) = NULL,
    @JobFunctionID_Clear bit = 0,
    @JobFunctionID uniqueidentifier = NULL,
    @SeniorityLevelID_Clear bit = 0,
    @SeniorityLevelID uniqueidentifier = NULL,
    @Source nvarchar(20) = NULL,
    @SourceSystem_Clear bit = 0,
    @SourceSystem nvarchar(80) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Relationship]
    SET
        [RelationshipTypeID] = ISNULL(@RelationshipTypeID, [RelationshipTypeID]),
        [FromPersonID] = CASE WHEN @FromPersonID_Clear = 1 THEN NULL ELSE ISNULL(@FromPersonID, [FromPersonID]) END,
        [FromOrganizationID] = CASE WHEN @FromOrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@FromOrganizationID, [FromOrganizationID]) END,
        [ToPersonID] = CASE WHEN @ToPersonID_Clear = 1 THEN NULL ELSE ISNULL(@ToPersonID, [ToPersonID]) END,
        [ToOrganizationID] = CASE WHEN @ToOrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@ToOrganizationID, [ToOrganizationID]) END,
        [Title] = CASE WHEN @Title_Clear = 1 THEN NULL ELSE ISNULL(@Title, [Title]) END,
        [StartDate] = CASE WHEN @StartDate_Clear = 1 THEN NULL ELSE ISNULL(@StartDate, [StartDate]) END,
        [EndDate] = CASE WHEN @EndDate_Clear = 1 THEN NULL ELSE ISNULL(@EndDate, [EndDate]) END,
        [Status] = ISNULL(@Status, [Status]),
        [Notes] = CASE WHEN @Notes_Clear = 1 THEN NULL ELSE ISNULL(@Notes, [Notes]) END,
        [JobFunctionID] = CASE WHEN @JobFunctionID_Clear = 1 THEN NULL ELSE ISNULL(@JobFunctionID, [JobFunctionID]) END,
        [SeniorityLevelID] = CASE WHEN @SeniorityLevelID_Clear = 1 THEN NULL ELSE ISNULL(@SeniorityLevelID, [SeniorityLevelID]) END,
        [Source] = ISNULL(@Source, [Source]),
        [SourceSystem] = CASE WHEN @SourceSystem_Clear = 1 THEN NULL ELSE ISNULL(@SourceSystem, [SourceSystem]) END
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwRelationships] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwRelationships]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateRelationship] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateRelationship] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateRelationship] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Relationship table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateRelationship]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateRelationship];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateRelationship
ON [${flyway:defaultSchema}].[Relationship]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Relationship]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[Relationship] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Relationships */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateRelationship] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateRelationship] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateRelationship] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
-- Item: spDeleteRelationship
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Relationship
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteRelationship]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteRelationship];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteRelationship]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[Relationship]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spDeleteRelationship] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteRelationship] TO [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Relationships */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spDeleteRelationship] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteRelationship] TO [cdp_Integration];

/* SQL text to insert 5 new entity field(s) */

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8bb2f83b-3f2b-444b-ba1a-8203fc0864bd' OR (EntityID = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND Name = 'Integration')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '8bb2f83b-3f2b-444b-ba1a-8203fc0864bd',
            'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', -- Entity: MJ_BizApps_Common: Enrichment Providers
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7'),
            'Integration',
            'Integration',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            1,
            NULL,
            0,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'a1b9c6e0-801c-4ab0-b53c-1fec397e0bf7' OR (EntityID = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62' AND Name = 'Person')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'a1b9c6e0-801c-4ab0-b53c-1fec397e0bf7',
            'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62', -- Entity: MJ_BizApps_Common: Person External Identities
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62'),
            'Person',
            'Person',
            NULL,
            'nvarchar',
            402,
            0,
            0,
            0,
            NULL,
            0,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'b900ccd8-2a04-4605-8501-26cd1b507139' OR (EntityID = 'FECE9795-E393-4470-B1FD-7D826F505105' AND Name = 'EnrichmentProvider')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'b900ccd8-2a04-4605-8501-26cd1b507139',
            'FECE9795-E393-4470-B1FD-7D826F505105', -- Entity: MJ_BizApps_Common: Enrichment Provider Rates
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'FECE9795-E393-4470-B1FD-7D826F505105'),
            'EnrichmentProvider',
            'Enrichment Provider',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            0,
            NULL,
            0,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '1de15b08-ea18-46e6-b67d-90bd9f6ad723' OR (EntityID = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND Name = 'Person')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '1de15b08-ea18-46e6-b67d-90bd9f6ad723',
            'A50829B7-110B-48D9-ACB4-B169917BBF41', -- Entity: MJ_BizApps_Common: Person Educations
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41'),
            'Person',
            'Person',
            NULL,
            'nvarchar',
            402,
            0,
            0,
            0,
            NULL,
            0,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '05e2309b-68c2-4786-bbd4-f3e67e17c410' OR (EntityID = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND Name = 'Organization')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '05e2309b-68c2-4786-bbd4-f3e67e17c410',
            'A50829B7-110B-48D9-ACB4-B169917BBF41', -- Entity: MJ_BizApps_Common: Person Educations
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41'),
            'Organization',
            'Organization',
            NULL,
            'nvarchar',
            510,
            0,
            0,
            1,
            NULL,
            0,
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
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET IsNameField = 1
               WHERE ID = '8993AAF1-0133-4394-BBBF-C2EDA0EF90BF'
               AND AutoUpdateIsNameField = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '016190CC-296C-4E75-B04B-A61284FF8FD2'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '75AFED22-E199-4946-A4BE-B74FD41D9D13'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '4F9E5BB3-92CB-41ED-9B17-503EE920541E'
               AND AutoUpdateDefaultInView = 1;

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET IsNameField = 1
               WHERE ID = 'A0198FE1-DF0D-49DD-B6CD-A9C76FDD47FC'
               AND AutoUpdateIsNameField = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'B900CCD8-2A04-4605-8501-26CD1B507139'
               AND AutoUpdateDefaultInView = 1;

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '255753D7-0383-4ED1-8925-4FBC76A93FAB'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '759BB2AD-6E8C-458E-B657-2F7311FC9F33'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '3357BE27-B960-4614-8878-DF9397F227AB'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'F5782F12-9B29-4B94-925E-D8C88E08C755'
               AND AutoUpdateDefaultInView = 1;

            UPDATE [${mjSchema}].[Entity]
            SET AllowUserSearchAPI = 0
            WHERE ID = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7'
            AND AutoUpdateAllowUserSearchAPI = 1;

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET IsNameField = 1
               WHERE ID = '3CB6418A-B35D-4E1D-93AE-E6BC15214803'
               AND AutoUpdateIsNameField = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '0B30BC7C-A0F6-4861-9EF3-57DCEEA0203A'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '485E2D19-8915-4F06-9965-AADE644D789A'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '7658F588-08CB-49DE-BD60-EC377F359638'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '54D4115F-3F63-4923-82BE-4A15E07466F0'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET IncludeInUserSearchAPI = 1
               WHERE ID = '3CB6418A-B35D-4E1D-93AE-E6BC15214803'
               AND AutoUpdateIncludeInUserSearchAPI = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET IncludeInUserSearchAPI = 1
               WHERE ID = '37549DB7-3917-4FEC-863D-FE5DF0D4B381'
               AND AutoUpdateIncludeInUserSearchAPI = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET IncludeInUserSearchAPI = 1
               WHERE ID = '0B30BC7C-A0F6-4861-9EF3-57DCEEA0203A'
               AND AutoUpdateIncludeInUserSearchAPI = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET UserSearchPredicateAPI = 'BeginsWith'
               WHERE ID = '3CB6418A-B35D-4E1D-93AE-E6BC15214803'
               AND AutoUpdateUserSearchPredicate = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET UserSearchPredicateAPI = 'BeginsWith'
               WHERE ID = '37549DB7-3917-4FEC-863D-FE5DF0D4B381'
               AND AutoUpdateUserSearchPredicate = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET UserSearchPredicateAPI = 'BeginsWith'
               WHERE ID = '0B30BC7C-A0F6-4861-9EF3-57DCEEA0203A'
               AND AutoUpdateUserSearchPredicate = 1;

            UPDATE [${mjSchema}].[Entity]
            SET AllowUserSearchAPI = 1
            WHERE ID = 'A50829B7-110B-48D9-ACB4-B169917BBF41'
            AND AutoUpdateAllowUserSearchAPI = 1;

/* Set categories for 2 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Relationships.Source 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Relationship Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'D5F53051-28B5-4A04-B043-D57EAA21C1C1';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Relationships.SourceSystem 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Relationship Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '6E4BCD8B-D195-44D1-BCA0-C30397EBC72E';

/* Set categories for 9 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Provider Rates.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '7A9CA7AE-7E75-4B09-B003-C90F6196CA09';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Provider Rates.EnrichmentProviderID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Provider Configuration',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'CE7651E6-07DB-47C4-A603-D456E1D0EA14';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Provider Rates.EnrichmentProvider 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Provider Configuration',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'B900CCD8-2A04-4605-8501-26CD1B507139';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Provider Rates.Operation 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Provider Configuration',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'A0198FE1-DF0D-49DD-B6CD-A9C76FDD47FC';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Provider Rates.Unit 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Rate and Billing',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '31BCB292-F75A-4018-8B4E-9CC6F1C445E1';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Provider Rates.CreditsPerUnit 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Rate and Billing',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '89AB5701-2149-4134-A6D0-39CA35CF4A9A';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Provider Rates.Notes 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Provider Configuration',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '55E41F32-BD19-41C3-A5E3-A41ADA55CCF0';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Provider Rates.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'D0D39F9A-0AEE-4B5E-9D38-B2A9194A47B8';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Provider Rates.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'F483B9DF-2762-49DB-87C8-590CA69BCC41';

/* Set entity icon to fa fa-calculator */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-calculator', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = 'FECE9795-E393-4470-B1FD-7D826F505105';

/* Insert FieldCategoryInfo setting for entity */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = 'FECE9795-E393-4470-B1FD-7D826F505105' AND [Name] = 'FieldCategoryInfo'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('3b5cb818-63bc-5667-921f-aca4b9e31510', 'FECE9795-E393-4470-B1FD-7D826F505105', 'FieldCategoryInfo', '{
  "Provider Configuration": {
    "description": "Provider identification, target operation, and contextual notes",
    "icon": "fa fa-sliders-h"
  },
  "Rate and Billing": {
    "description": "Credit consumption rates and billing units per operation",
    "icon": "fa fa-dollar-sign"
  }
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Insert FieldCategoryIcons setting (legacy) */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = 'FECE9795-E393-4470-B1FD-7D826F505105' AND [Name] = 'FieldCategoryIcons'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('98156e51-e160-5255-8e62-086705932dff', 'FECE9795-E393-4470-B1FD-7D826F505105', 'FieldCategoryIcons', '{
  "Provider Configuration": "fa fa-sliders-h",
  "Rate and Billing": "fa fa-dollar-sign"
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Set DefaultForNewUser=false for NEW entity (category: reference, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = 'FECE9795-E393-4470-B1FD-7D826F505105';

/* Set categories for 12 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person External Identities.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '6F47161F-44F9-4C09-82E1-7688CB48BD60';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person External Identities.PersonID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Identity Information',
   GeneratedFormSection = 'Category',
   DisplayName = 'Person'
WHERE 
   ID = 'B8247A33-A3E3-4E75-AA71-4C5B1599875E';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person External Identities.Person 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Identity Information',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'A1B9C6E0-801C-4AB0-B53C-1FEC397E0BF7';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person External Identities.SourceSystem 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Identity Information',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '8993AAF1-0133-4394-BBBF-C2EDA0EF90BF';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person External Identities.ExternalID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Identity Information',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'E0D2C339-18EE-4D84-A496-1F33CA5591CB';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person External Identities.MatchStatus 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Match Status & Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'D5AA5D25-DBE1-45AC-93A2-07DCAEF834B1';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person External Identities.MatchedBy 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Match Status & Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '016190CC-296C-4E75-B04B-A61284FF8FD2';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person External Identities.MatchConfidence 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Match Status & Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '75AFED22-E199-4946-A4BE-B74FD41D9D13';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person External Identities.LastCheckedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Matching Timeline',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '4F9E5BB3-92CB-41ED-9B17-503EE920541E';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person External Identities.LastMatchedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Matching Timeline',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '395CEFCA-887A-4BF8-A3D2-4AD6EB83884B';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person External Identities.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '697D4BB5-81DF-4D98-BF63-A58A2534D40F';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person External Identities.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'ADE2B65B-B7EE-42D6-8C19-CD6EE97F5C3B';

/* Set entity icon to fa fa-id-card */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-id-card', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62';

/* Insert FieldCategoryInfo setting for entity */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62' AND [Name] = 'FieldCategoryInfo'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('22400836-5daf-5e8b-b5d9-faca82f41dbb', 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62', 'FieldCategoryInfo', '{
  "Identity Information": {
    "description": "Core external system references and identifiers for the person",
    "icon": "fa fa-id-badge"
  },
  "Match Status & Details": {
    "description": "Outcomes, confidence scores, and mechanisms of match attempts",
    "icon": "fa fa-check-circle"
  },
  "Matching Timeline": {
    "description": "Timestamps driving re-enrichment and check schedules",
    "icon": "fa fa-clock"
  }
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Insert FieldCategoryIcons setting (legacy) */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62' AND [Name] = 'FieldCategoryIcons'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('e73fb67a-aa73-57be-92a6-5700263a115e', 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62', 'FieldCategoryIcons', '{
  "Identity Information": "fa fa-id-badge",
  "Match Status & Details": "fa fa-check-circle",
  "Matching Timeline": "fa fa-clock"
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Set DefaultForNewUser=false for NEW entity (category: supporting, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62';

/* Set categories for 16 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Providers.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'C73482C2-7218-4864-9358-D12441ADD7E8';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Providers.Code 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Provider Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'B5D4E755-6262-456F-8CF5-0154A28AA419';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Providers.Name 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Provider Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '8A9E570F-45F9-4880-8E46-8BD7754C49EB';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Providers.Description 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Provider Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'F1E611B5-630D-4C06-97AB-7C9186ABEB12';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Providers.DriverClass 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Configuration and Integration',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'E11C8374-1F9E-4845-9833-3A52F8CBA181';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Providers.IntegrationID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Configuration and Integration',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'C45F676E-FE35-4000-AB4C-B80896D48FFB';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Providers.MaxBatchSize 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Performance and Limits',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '347A97BB-6F89-44DE-AC75-423FAD2A6954';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Providers.RequestsPerMinute 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Performance and Limits',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '228E2FFA-9BAD-4DF9-9A8E-8FD34A61C755';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Providers.Configuration 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Configuration and Integration',
   GeneratedFormSection = 'Category',
   ExtendedType = 'JSON'
WHERE 
   ID = '8FE1C97C-5370-4CC8-92CD-CB9299E3696E';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Providers.CreditPrice 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Pricing and Economics',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '255753D7-0383-4ED1-8925-4FBC76A93FAB';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Providers.CreditCurrency 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Pricing and Economics',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '759BB2AD-6E8C-458E-B657-2F7311FC9F33';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Providers.Sequence 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Provider Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '3357BE27-B960-4614-8878-DF9397F227AB';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Providers.IsActive 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Provider Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'F5782F12-9B29-4B94-925E-D8C88E08C755';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Providers.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '1F5CF4BF-2AEF-4D67-A670-F6E80ED4EA8E';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Providers.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '1C802C40-DBF8-4A96-A20D-58D5422070AB';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Enrichment Providers.Integration 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Configuration and Integration',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '8BB2F83B-3F2B-444B-BA1A-8203FC0864BD';

/* Set entity icon to fa fa-plug */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-plug', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7';

/* Insert FieldCategoryInfo setting for entity */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND [Name] = 'FieldCategoryInfo'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('36171602-c9df-56b6-9a44-00ef3811276a', 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', 'FieldCategoryInfo', '{
  "Configuration and Integration": {
    "description": "Technical configuration settings, driver classes, and integration links",
    "icon": "fa fa-sliders-h"
  },
  "Performance and Limits": {
    "description": "Batch limits, rate ceilings, and performance constraints",
    "icon": "fa fa-tachometer-alt"
  },
  "Pricing and Economics": {
    "description": "Credit pricing and currency details for vendor utilization",
    "icon": "fa fa-dollar-sign"
  },
  "Provider Details": {
    "description": "General descriptive information, naming, and status of the enrichment provider",
    "icon": "fa fa-info-circle"
  }
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Insert FieldCategoryIcons setting (legacy) */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND [Name] = 'FieldCategoryIcons'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('d51f37c5-6db9-5596-98ae-7129d668bce1', 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7', 'FieldCategoryIcons', '{
  "Configuration and Integration": "fa fa-sliders-h",
  "Performance and Limits": "fa fa-tachometer-alt",
  "Pricing and Economics": "fa fa-dollar-sign",
  "Provider Details": "fa fa-info-circle"
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Set DefaultForNewUser=false for NEW entity (category: reference, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7';

/* Set categories for 16 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person Educations.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '46A8F6BA-2923-46BE-BE41-5DA396CAF33E';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person Educations.PersonID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Education Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Person'
WHERE 
   ID = 'D9562BE6-1A1F-4973-944A-E079495831D5';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person Educations.OrganizationID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Education Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'BAE8D0D8-F7B4-4795-AFE6-58290BCFC445';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person Educations.InstitutionName 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Education Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '3CB6418A-B35D-4E1D-93AE-E6BC15214803';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person Educations.Degree 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Education Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '37549DB7-3917-4FEC-863D-FE5DF0D4B381';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person Educations.FieldOfStudy 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Education Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Field of Study'
WHERE 
   ID = '0B30BC7C-A0F6-4861-9EF3-57DCEEA0203A';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person Educations.StartDate 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Timeline',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '485E2D19-8915-4F06-9965-AADE644D789A';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person Educations.EndDate 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Timeline',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '7658F588-08CB-49DE-BD60-EC377F359638';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person Educations.Source 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Source and Verification',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '54D4115F-3F63-4923-82BE-4A15E07466F0';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person Educations.SourceSystem 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Source and Verification',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '8D0113BC-A3DA-4155-852F-4A086A5A68CC';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person Educations.LastVerifiedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Source and Verification',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'A77E85CD-BB84-4AA6-A24B-33A818522689';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person Educations.Notes 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Additional Information',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '7A710139-1A81-4106-A723-48E5E256B72C';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person Educations.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '238DDB26-B96C-49EC-81C8-F99296F441CC';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person Educations.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '416C8CE3-11B2-484B-9874-C0CC88E0D46B';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person Educations.Person 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Education Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Person Name'
WHERE 
   ID = '1DE15B08-EA18-46E6-B67D-90BD9F6AD723';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Person Educations.Organization 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Education Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Organization Name'
WHERE 
   ID = '05E2309B-68C2-4786-BBD4-F3E67E17C410';

/* Set entity icon to fa fa-graduation-cap */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-graduation-cap', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41';

/* Insert FieldCategoryInfo setting for entity */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND [Name] = 'FieldCategoryInfo'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('a6f35db1-3aa3-5359-90ee-43e3f7aa1ae0', 'A50829B7-110B-48D9-ACB4-B169917BBF41', 'FieldCategoryInfo', '{
  "Additional Information": {
    "description": "Free text notes and miscellaneous information",
    "icon": "fa fa-align-left"
  },
  "Education Details": {
    "description": "Core information about the school, degree, and field of study",
    "icon": "fa fa-graduation-cap"
  },
  "Source and Verification": {
    "description": "Tracking for data provenance, source systems, and verification dates",
    "icon": "fa fa-shield-alt"
  },
  "Timeline": {
    "description": "Start and end dates of the academic program",
    "icon": "fa fa-calendar-alt"
  }
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Insert FieldCategoryIcons setting (legacy) */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND [Name] = 'FieldCategoryIcons'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('dc554ca3-f8a4-585f-aeea-78a541dc8740', 'A50829B7-110B-48D9-ACB4-B169917BBF41', 'FieldCategoryIcons', '{
  "Additional Information": "fa fa-align-left",
  "Education Details": "fa fa-graduation-cap",
  "Source and Verification": "fa fa-shield-alt",
  "Timeline": "fa fa-calendar-alt"
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Set DefaultForNewUser=true for NEW entity (category: supporting, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 1, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = 'A50829B7-110B-48D9-ACB4-B169917BBF41';



/**************************************************************************************************
 **************************************************************************************************
 **                                                                                              **
 **                CODEGEN OUTPUT — Person Enrichment (v5.53.x), RUN #2 (validators)             **
 **                                                                                              **
 **  Generated by a second CodeGen pass with every schema re-emitted. It persists the CHECK-     **
 **  constraint validators (MJ: Generated Codes rows, category "CodeGen: Validators") that the   **
 **  generated entity classes carry: 10 for the new tables and Relationship's new columns, and   **
 **  20 for pre-existing constraints whose validator rows had only ever existed in a developer   **
 **  database and were never shipped. Without these rows a database built from migrations        **
 **  regenerates the entity classes WITHOUT those Validate*() methods. Each insert is guarded     **
 **  by IF NOT EXISTS on (category, entity, record), so it is idempotent on any host.             **
 **                                                                                              **
 **  DO NOT EDIT BY HAND.                                                                         **
 **                                                                                              **
 **************************************************************************************************
 **************************************************************************************************/
/* Generated Validation Functions for MJ_BizApps_Common: Activities */
-- CHECK constraint for MJ_BizApps_Common: Activities: Field: SentimentScore was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'DF238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = 'F482A17C-2B9A-4D76-96A8-A3F12462E08D'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('5ff0302d-7b3c-43af-bbbc-547b47c533be', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([SentimentScore] IS NULL OR [SentimentScore]>=(-1.000) AND [SentimentScore]<=(1.000))', 'public ValidateSentimentScoreRange(result: ValidationResult): void {
	if (this.SentimentScore != null && (this.SentimentScore < -1 || this.SentimentScore > 1)) {
		result.Errors.push(new ValidationErrorInfo(
			"SentimentScore",
			"Sentiment score must be between -1.0 and 1.0.",
			this.SentimentScore,
			ValidationErrorType.Failure
		));
	}
}', 'Sentiment score must be between -1.0 and 1.0, or left blank.', 'ValidateSentimentScoreRange', 'DF238F34-2837-EF11-86D4-6045BDEE16E6', 'F482A17C-2B9A-4D76-96A8-A3F12462E08D')
   END;

-- CHECK constraint for MJ_BizApps_Common: Activities @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'E0238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = '72E55425-8822-4E70-A075-116219CA5A5D' AND [Name] = 'ValidateEndedAtOnOrAfterStartedAt'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('3af1893a-3ba3-4d4d-ac3c-2d2155c9f02b', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([EndedAt] IS NULL OR [EndedAt]>=[StartedAt])', 'public ValidateEndedAtOnOrAfterStartedAt(result: ValidationResult) {
	if (this.EndedAt != null && this.StartedAt != null && new Date(this.EndedAt) < new Date(this.StartedAt)) {
		result.Errors.push(new ValidationErrorInfo(
			"EndedAt",
			"The end date and time must be on or after the start date and time.",
			this.EndedAt,
			ValidationErrorType.Failure
		));
	}
}', 'The activity end date and time must occur on or after the start date and time to maintain valid activity timelines.', 'ValidateEndedAtOnOrAfterStartedAt', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', '72E55425-8822-4E70-A075-116219CA5A5D')
   END;

/* Generated Validation Functions for MJ_BizApps_Common: Activity Links */
-- CHECK constraint for MJ_BizApps_Common: Activity Links @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'E0238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = '9C48DF77-E4A1-4ADB-AABF-916F5798B894' AND [Name] = 'ValidateEntityRecordOrIdentityTarget'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('a4622f93-7fc9-46f0-aa00-f038c4fb6621', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([EntityID] IS NOT NULL AND [RecordID] IS NOT NULL AND [IdentityKind] IS NULL AND [IdentityValue] IS NULL OR [EntityID] IS NULL AND [RecordID] IS NULL AND [IdentityKind] IS NOT NULL AND [IdentityValue] IS NOT NULL)', 'public ValidateEntityRecordOrIdentityTarget(result: ValidationResult) {
	const hasEntity = this.EntityID != null;
	const hasRecord = this.RecordID != null;
	const hasIdentityKind = this.IdentityKind != null;
	const hasIdentityValue = this.IdentityValue != null;

	const isEntityRecordTarget = hasEntity && hasRecord && !hasIdentityKind && !hasIdentityValue;
	const isIdentityTarget = !hasEntity && !hasRecord && hasIdentityKind && hasIdentityValue;

	if (!isEntityRecordTarget && !isIdentityTarget) {
		result.Errors.push(new ValidationErrorInfo(
			"EntityID",
			"You must specify either both EntityID and RecordID, or both IdentityKind and IdentityValue, but not a partial combination or both pairs.",
			this.EntityID,
			ValidationErrorType.Failure
		));
	}
}', 'Records must be linked either to an entity record (specifying both Entity ID and Record ID) or to an identity (specifying both Identity Kind and Identity Value), but never both or a partial combination.', 'ValidateEntityRecordOrIdentityTarget', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', '9C48DF77-E4A1-4ADB-AABF-916F5798B894')
   END;

/* Generated Validation Functions for MJ_BizApps_Common: Activity Sync Connections */
-- CHECK constraint for MJ_BizApps_Common: Activity Sync Connections: Field: MaxAttachmentBytes was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'DF238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = 'A8E6FDD3-F038-42CB-A9DA-D92C5105EC34'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('2ae97ca9-cd3e-40a9-8dbe-3aec1c9b33fc', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([MaxAttachmentBytes] IS NULL OR [MaxAttachmentBytes]>(0))', 'public ValidateMaxAttachmentBytesGreaterThanZero(result: ValidationResult) {
	if (this.MaxAttachmentBytes != null && this.MaxAttachmentBytes <= 0) {
		result.Errors.push(new ValidationErrorInfo(
			"MaxAttachmentBytes",
			"Maximum attachment bytes must be greater than 0.",
			this.MaxAttachmentBytes,
			ValidationErrorType.Failure
		));
	}
}', 'Maximum attachment size must be greater than zero bytes if specified.', 'ValidateMaxAttachmentBytesGreaterThanZero', 'DF238F34-2837-EF11-86D4-6045BDEE16E6', 'A8E6FDD3-F038-42CB-A9DA-D92C5105EC34')
   END;

-- CHECK constraint for MJ_BizApps_Common: Activity Sync Connections @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'E0238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = 'C22591BB-B33A-439C-9567-5494A7B71D8A' AND [Name] = 'ValidateEndAtGreaterThanOrEqualToStartAt'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('248a980e-5a3f-4784-830a-136273607574', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([StartAt] IS NULL OR [EndAt] IS NULL OR [EndAt]>=[StartAt])', 'public ValidateEndAtGreaterThanOrEqualToStartAt(result: ValidationResult) {
	if (this.StartAt != null && this.EndAt != null && this.EndAt < this.StartAt) {
		result.Errors.push(new ValidationErrorInfo(
			"EndAt",
			"End date and time must be on or after the start date and time.",
			this.EndAt,
			ValidationErrorType.Failure
		));
	}
}', 'End date and time must be on or after the start date and time when both are provided.', 'ValidateEndAtGreaterThanOrEqualToStartAt', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', 'C22591BB-B33A-439C-9567-5494A7B71D8A')
   END;

/* Generated Validation Functions for MJ_BizApps_Common: Activity Sync Extensions */
-- CHECK constraint for MJ_BizApps_Common: Activity Sync Extensions: Field: TimeoutMS was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'DF238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = 'A12A8C4C-DBD9-40FB-97B4-3872AA966FC3'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('d6d56387-840c-4a72-b871-a48d7aef8117', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([TimeoutMS]>(0) AND [TimeoutMS]<=(300000))', 'public ValidateTimeoutMSRange(result: ValidationResult) {
	if (this.TimeoutMS != null && (this.TimeoutMS <= 0 || this.TimeoutMS > 300000)) {
		result.Errors.push(new ValidationErrorInfo(
			"TimeoutMS",
			"Timeout must be greater than 0 and cannot exceed 300,000 milliseconds.",
			this.TimeoutMS,
			ValidationErrorType.Failure
		));
	}
}', 'Timeout must be greater than 0 and cannot exceed 300,000 milliseconds (5 minutes).', 'ValidateTimeoutMSRange', 'DF238F34-2837-EF11-86D4-6045BDEE16E6', 'A12A8C4C-DBD9-40FB-97B4-3872AA966FC3')
   END;

/* Generated Validation Functions for MJ_BizApps_Common: Activity Sync Provider Types */
-- CHECK constraint for MJ_BizApps_Common: Activity Sync Provider Types: Field: DefaultMaxAttachmentBytes was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'DF238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = '827D6B7C-BA37-446C-A9C1-912320C1AFF3'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('bbefb94e-997d-4f3a-9d88-18cd82bd08e0', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([DefaultMaxAttachmentBytes] IS NULL OR [DefaultMaxAttachmentBytes]>(0))', 'public ValidateDefaultMaxAttachmentBytesGreaterThanZero(result: ValidationResult) {
	if (this.DefaultMaxAttachmentBytes != null && this.DefaultMaxAttachmentBytes <= 0) {
		result.Errors.push(new ValidationErrorInfo(
			"DefaultMaxAttachmentBytes",
			"Default maximum attachment size must be greater than 0 bytes.",
			this.DefaultMaxAttachmentBytes,
			ValidationErrorType.Failure
		));
	}
}', 'Default maximum attachment bytes must be greater than zero if a limit is specified.', 'ValidateDefaultMaxAttachmentBytesGreaterThanZero', 'DF238F34-2837-EF11-86D4-6045BDEE16E6', '827D6B7C-BA37-446C-A9C1-912320C1AFF3')
   END;

-- CHECK constraint for MJ_BizApps_Common: Activity Sync Provider Types @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'E0238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND [Name] = 'ValidateDefaultEncryptionKeyIDForSkippedContentPolicy'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('e5cd97aa-4cde-4263-b73e-b7adaeb84f69', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([DefaultSkippedContentPolicy]=N''None'' OR [DefaultEncryptionKeyID] IS NOT NULL)', 'public ValidateDefaultEncryptionKeyIDForSkippedContentPolicy(result: ValidationResult) {
	if (this.DefaultSkippedContentPolicy !== "None" && this.DefaultEncryptionKeyID == null) {
		result.Errors.push(new ValidationErrorInfo(
			"DefaultEncryptionKeyID",
			"A default encryption key is required when the default skipped content policy is set to anything other than None.",
			this.DefaultEncryptionKeyID,
			ValidationErrorType.Failure
		));
	}
}', 'A default encryption key must be specified whenever the default skipped content policy is set to anything other than None.', 'ValidateDefaultEncryptionKeyIDForSkippedContentPolicy', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75')
   END;

/* Generated Validation Functions for MJ_BizApps_Common: Activity Sync Rules */
-- CHECK constraint for MJ_BizApps_Common: Activity Sync Rules: Field: MaxAttachmentBytes was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'DF238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = 'DCA96B15-B3EE-4F41-BBD1-146C71922BA8'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('18c05355-10b8-44a4-8d02-5513800f0460', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([MaxAttachmentBytes] IS NULL OR [MaxAttachmentBytes]>(0))', 'public ValidateMaxAttachmentBytesGreaterThanZero(result: ValidationResult) {
	if (this.MaxAttachmentBytes != null && this.MaxAttachmentBytes <= 0) {
		result.Errors.push(new ValidationErrorInfo(
			"MaxAttachmentBytes",
			"Maximum attachment bytes must be greater than 0.",
			this.MaxAttachmentBytes,
			ValidationErrorType.Failure
		));
	}
}', 'Maximum attachment size in bytes must be greater than zero if a limit is specified.', 'ValidateMaxAttachmentBytesGreaterThanZero', 'DF238F34-2837-EF11-86D4-6045BDEE16E6', 'DCA96B15-B3EE-4F41-BBD1-146C71922BA8')
   END;

-- CHECK constraint for MJ_BizApps_Common: Activity Sync Rules @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'E0238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = '21B78371-132C-4507-AED8-D44E366468F2' AND [Name] = 'ValidateActivitySyncRuleSetIDOrActivitySyncConnectionID'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('c276f4e3-6585-4db9-81eb-e4f0fe94be58', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([ActivitySyncRuleSetID] IS NULL AND [ActivitySyncConnectionID] IS NOT NULL OR [ActivitySyncRuleSetID] IS NOT NULL AND [ActivitySyncConnectionID] IS NULL)', 'public ValidateActivitySyncRuleSetIDOrActivitySyncConnectionID(result: ValidationResult) {
	const hasRuleSet = this.ActivitySyncRuleSetID != null;
	const hasConnection = this.ActivitySyncConnectionID != null;

	if ((hasRuleSet && hasConnection) || (!hasRuleSet && !hasConnection)) {
		result.Errors.push(new ValidationErrorInfo(
			"ActivitySyncRuleSetID",
			"Exactly one of Activity Sync Rule Set or Activity Sync Connection must be specified.",
			this.ActivitySyncRuleSetID,
			ValidationErrorType.Failure
		));
	}
}', 'Each rule must be associated with either an Activity Sync Rule Set or an Activity Sync Connection, but cannot have both or neither specified.', 'ValidateActivitySyncRuleSetIDOrActivitySyncConnectionID', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', '21B78371-132C-4507-AED8-D44E366468F2')
   END;

-- CHECK constraint for MJ_BizApps_Common: Activity Sync Rules @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'E0238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = '21B78371-132C-4507-AED8-D44E366468F2' AND [Name] = 'ValidateDateToGreaterThanOrEqualToDateFrom'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('0b8d6507-3e55-4f54-9567-23a836402ab5', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([DateFrom] IS NULL OR [DateTo] IS NULL OR [DateTo]>=[DateFrom])', 'public ValidateDateToGreaterThanOrEqualToDateFrom(result: ValidationResult) {
	if (this.DateFrom != null && this.DateTo != null && new Date(this.DateTo).getTime() < new Date(this.DateFrom).getTime()) {
		result.Errors.push(new ValidationErrorInfo(
			"DateTo",
			"Date To must be on or after Date From.",
			this.DateTo,
			ValidationErrorType.Failure
		));
	}
}', 'The end date must be on or after the start date when both dates are specified.', 'ValidateDateToGreaterThanOrEqualToDateFrom', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', '21B78371-132C-4507-AED8-D44E366468F2')
   END;

/* Generated Validation Functions for MJ_BizApps_Common: Activity Sync Run Details */
-- CHECK constraint for MJ_BizApps_Common: Activity Sync Run Details: Field: Confidence was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'DF238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = '74F9BDC0-2B51-4F54-80DD-62677C682D67'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('467c3374-1e65-460b-bc4d-73a906ddd8a1', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([Confidence] IS NULL OR [Confidence]>=(0) AND [Confidence]<=(1))', 'public ValidateConfidenceRange(result: ValidationResult) {
	if (this.Confidence != null && (this.Confidence < 0 || this.Confidence > 1)) {
		result.Errors.push(new ValidationErrorInfo(
			"Confidence",
			"Confidence score must be between 0 and 1.",
			this.Confidence,
			ValidationErrorType.Failure
		));
	}
}', 'Confidence score, if provided, must be a value between 0 and 1 inclusive.', 'ValidateConfidenceRange', 'DF238F34-2837-EF11-86D4-6045BDEE16E6', '74F9BDC0-2B51-4F54-80DD-62677C682D67')
   END;

-- CHECK constraint for MJ_BizApps_Common: Activity Sync Run Details @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'E0238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND [Name] = 'ValidateActivityIDRequiresIncludedDecision'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('f03bf280-1b50-420c-bb23-ecf3804bd21c', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([ActivityID] IS NULL OR [Decision]=N''Included'')', 'public ValidateActivityIDRequiresIncludedDecision(result: ValidationResult) {
	if (this.ActivityID != null && this.Decision !== "Included") {
		result.Errors.push(new ValidationErrorInfo(
			"ActivityID",
			"An activity can only be associated when the decision is set to ''Included''.",
			this.ActivityID,
			ValidationErrorType.Failure
		));
	}
}', 'An activity can only be associated when the decision is set to ''Included''.', 'ValidateActivityIDRequiresIncludedDecision', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', 'AC16B066-9460-44F5-B027-3FD397E61F34')
   END;

/* Generated Validation Functions for MJ_BizApps_Common: Activity Sync Runs */
-- CHECK constraint for MJ_BizApps_Common: Activity Sync Runs @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'E0238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND [Name] = 'ValidateWatermarkAfterWhenIsDryRun'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('59ce76cc-e6d7-406b-8103-f4737aa95029', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([IsDryRun]=(0) OR [WatermarkAfter] IS NULL)', 'public ValidateWatermarkAfterWhenIsDryRun(result: ValidationResult) {
	if (this.IsDryRun && this.WatermarkAfter != null) {
		result.Errors.push(new ValidationErrorInfo(
			"WatermarkAfter",
			"WatermarkAfter must be empty when IsDryRun is enabled.",
			this.WatermarkAfter,
			ValidationErrorType.Failure
		));
	}
}', 'Dry run executions cannot advance the watermark, so WatermarkAfter must be empty when running in dry run mode.', 'ValidateWatermarkAfterWhenIsDryRun', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1')
   END;

/* Generated Validation Functions for MJ_BizApps_Common: Enrichment Provider Rates */
-- CHECK constraint for MJ_BizApps_Common: Enrichment Provider Rates: Field: CreditsPerUnit was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'DF238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = '89AB5701-2149-4134-A6D0-39CA35CF4A9A'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('ffd1566e-8bea-44d8-99f9-39b3fc27b7b8', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([CreditsPerUnit]>=(0))', 'public ValidateCreditsPerUnitGreaterThanOrEqualToZero(result: ValidationResult) {
	if (this.CreditsPerUnit != null && this.CreditsPerUnit < 0) {
		result.Errors.push(new ValidationErrorInfo(
			"CreditsPerUnit",
			"Credits per unit must be greater than or equal to zero.",
			this.CreditsPerUnit,
			ValidationErrorType.Failure
		));
	}
}', 'Credits per unit must be zero or greater to prevent negative billing rates.', 'ValidateCreditsPerUnitGreaterThanOrEqualToZero', 'DF238F34-2837-EF11-86D4-6045BDEE16E6', '89AB5701-2149-4134-A6D0-39CA35CF4A9A')
   END;

/* Generated Validation Functions for MJ_BizApps_Common: Enrichment Providers */
-- CHECK constraint for MJ_BizApps_Common: Enrichment Providers: Field: MaxBatchSize was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'DF238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = '347A97BB-6F89-44DE-AC75-423FAD2A6954'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('94a58f9a-1d72-4176-ae95-af0afe04cdd2', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([MaxBatchSize]>(0))', 'public ValidateMaxBatchSizeGreaterThanZero(result: ValidationResult) {
	if (this.MaxBatchSize != null && this.MaxBatchSize <= 0) {
		result.Errors.push(new ValidationErrorInfo(
			"MaxBatchSize",
			"Maximum batch size must be greater than 0.",
			this.MaxBatchSize,
			ValidationErrorType.Failure
		));
	}
}', 'Maximum batch size must be greater than zero to ensure at least one record can be processed per batch.', 'ValidateMaxBatchSizeGreaterThanZero', 'DF238F34-2837-EF11-86D4-6045BDEE16E6', '347A97BB-6F89-44DE-AC75-423FAD2A6954')
   END;

-- CHECK constraint for MJ_BizApps_Common: Enrichment Providers: Field: RequestsPerMinute was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'DF238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = '228E2FFA-9BAD-4DF9-9A8E-8FD34A61C755'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('d0174810-df9a-40e3-a832-7f954502d33d', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([RequestsPerMinute] IS NULL OR [RequestsPerMinute]>(0))', 'public ValidateRequestsPerMinuteGreaterThanZero(result: ValidationResult) {
	if (this.RequestsPerMinute != null && this.RequestsPerMinute <= 0) {
		result.Errors.push(new ValidationErrorInfo(
			"RequestsPerMinute",
			"Requests per minute must be greater than 0.",
			this.RequestsPerMinute,
			ValidationErrorType.Failure
		));
	}
}', 'Requests per minute, if specified, must be greater than zero.', 'ValidateRequestsPerMinuteGreaterThanZero', 'DF238F34-2837-EF11-86D4-6045BDEE16E6', '228E2FFA-9BAD-4DF9-9A8E-8FD34A61C755')
   END;

-- CHECK constraint for MJ_BizApps_Common: Enrichment Providers @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'E0238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7' AND [Name] = 'ValidateCreditPriceAndCurrency'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('0b282c8e-d94b-44dc-bc45-7b3c20240903', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([CreditPrice] IS NULL OR [CreditPrice]>=(0) AND [CreditCurrency] IS NOT NULL)', 'public ValidateCreditPriceAndCurrency(result: ValidationResult): void {
	if (this.CreditPrice != null) {
		if (this.CreditPrice < 0) {
			result.Errors.push(new ValidationErrorInfo(
				"CreditPrice",
				"Credit price must be zero or greater.",
				this.CreditPrice,
				ValidationErrorType.Failure
			));
		}
		if (this.CreditCurrency == null || this.CreditCurrency.trim().length === 0) {
			result.Errors.push(new ValidationErrorInfo(
				"CreditCurrency",
				"Credit currency is required when a credit price is specified.",
				this.CreditCurrency,
				ValidationErrorType.Failure
			));
		}
	}
}', 'If a credit price is specified, it must be zero or greater and a credit currency must also be provided.', 'ValidateCreditPriceAndCurrency', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', 'FD00FCE2-3EF2-4319-BCCC-13BB7C986AD7')
   END;

/* Generated Validation Functions for MJ_BizApps_Common: Person Educations */
-- CHECK constraint for MJ_BizApps_Common: Person Educations @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'E0238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND [Name] = 'ValidateEndDateOnOrAfterStartDate'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('7ca88ad0-3b34-46b8-baf7-921a42de3aa4', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([StartDate] IS NULL OR [EndDate] IS NULL OR [EndDate]>=[StartDate])', 'public ValidateEndDateOnOrAfterStartDate(result: ValidationResult) {
	if (this.StartDate != null && this.EndDate != null && this.EndDate < this.StartDate) {
		result.Errors.push(new ValidationErrorInfo(
			"EndDate",
			"End date must be on or after start date.",
			this.EndDate,
			ValidationErrorType.Failure
		));
	}
}', 'End date must be on or after the start date when both dates are specified.', 'ValidateEndDateOnOrAfterStartDate', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', 'A50829B7-110B-48D9-ACB4-B169917BBF41')
   END;

-- CHECK constraint for MJ_BizApps_Common: Person Educations @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'E0238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = 'A50829B7-110B-48D9-ACB4-B169917BBF41' AND [Name] = 'ValidateSourceSystemForNonManualSource'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('a39eb2fc-d72b-4e6a-998e-e22bfbc0c0e0', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([Source]=N''Manual'' OR [SourceSystem] IS NOT NULL)', 'public ValidateSourceSystemForNonManualSource(result: ValidationResult): void {
	if (this.Source !== "Manual" && (this.SourceSystem == null || this.SourceSystem.trim() === "")) {
		result.Errors.push(new ValidationErrorInfo(
			"SourceSystem",
			"Source system must be provided when the source is not ''Manual''.",
			this.SourceSystem,
			ValidationErrorType.Failure
		));
	}
}', 'Records that are not created manually must specify a source system to track where the data originated.', 'ValidateSourceSystemForNonManualSource', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', 'A50829B7-110B-48D9-ACB4-B169917BBF41')
   END;

/* Generated Validation Functions for MJ_BizApps_Common: Person External Identities */
-- CHECK constraint for MJ_BizApps_Common: Person External Identities: Field: MatchConfidence was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'DF238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = '75AFED22-E199-4946-A4BE-B74FD41D9D13'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('b2f49dc7-2b42-49c9-ad13-f1f07b4722f1', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([MatchConfidence] IS NULL OR [MatchConfidence]>=(0.0) AND [MatchConfidence]<=(1.0))', 'public ValidateMatchConfidenceRange(result: ValidationResult) {
	if (this.MatchConfidence != null && (this.MatchConfidence < 0.0 || this.MatchConfidence > 1.0)) {
		result.Errors.push(new ValidationErrorInfo(
			"MatchConfidence",
			"Match confidence must be between 0.0 and 1.0.",
			this.MatchConfidence,
			ValidationErrorType.Failure
		));
	}
}', 'Match confidence must be between 0.0 and 1.0 when specified.', 'ValidateMatchConfidenceRange', 'DF238F34-2837-EF11-86D4-6045BDEE16E6', '75AFED22-E199-4946-A4BE-B74FD41D9D13')
   END;

-- CHECK constraint for MJ_BizApps_Common: Person External Identities @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'E0238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62' AND [Name] = 'ValidateExternalIDForMatchedStatus'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('296a2e24-0530-4916-bb9b-bf22bddc8383', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([MatchStatus]<>N''Matched'' OR [ExternalID] IS NOT NULL)', 'public ValidateExternalIDForMatchedStatus(result: ValidationResult) {
	if (this.MatchStatus === "Matched" && this.ExternalID == null) {
		result.Errors.push(new ValidationErrorInfo(
			"ExternalID",
			"An External ID is required when the match status is ''Matched''.",
			this.ExternalID,
			ValidationErrorType.Failure
		));
	}
}', 'Records with a match status of ''Matched'' must have an external ID specified.', 'ValidateExternalIDForMatchedStatus', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', 'C92E1E9E-BCB6-49B0-838C-1FA50EA7CE62')
   END;

/* Generated Validation Functions for MJ_BizApps_Common: Person Job Functions */
-- CHECK constraint for MJ_BizApps_Common: Person Job Functions: Field: Confidence was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'DF238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = 'FF39C3B5-E0B6-47C3-8AED-E8DC16717356'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('d016d0fa-d31e-45b9-942f-fd9ea85ec10f', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([Confidence] IS NULL OR [Confidence]>=(0.0) AND [Confidence]<=(1.0))', 'public ValidateConfidenceRange(result: ValidationResult) {
	if (this.Confidence != null && (this.Confidence < 0.0 || this.Confidence > 1.0)) {
		result.Errors.push(new ValidationErrorInfo(
			"Confidence",
			"Confidence must be between 0.0 and 1.0.",
			this.Confidence,
			ValidationErrorType.Failure
		));
	}
}', 'Confidence score must be between 0.0 and 1.0, or left blank.', 'ValidateConfidenceRange', 'DF238F34-2837-EF11-86D4-6045BDEE16E6', 'FF39C3B5-E0B6-47C3-8AED-E8DC16717356')
   END;

/* Generated Validation Functions for MJ_BizApps_Common: Relationships */
-- CHECK constraint for MJ_BizApps_Common: Relationships @ Table Level was newly set or modified since the last generation of the validation function, the code was regenerated and updating the GeneratedCode table with the new generated validation function
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[GeneratedCode] WHERE [CategoryID] = (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators') AND [LinkedEntityID] = 'E0238F34-2837-EF11-86D4-6045BDEE16E6' AND [LinkedRecordPrimaryKey] = '709CA9DA-B124-4155-BE39-E857EF672D82' AND [Name] = 'ValidateSourceSystemWhenSourceNotManual'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[GeneratedCode] ([ID], [CategoryID], [GeneratedByModelID], [GeneratedAt], [Language], [Status], [Source], [Code], [Description], [Name], [LinkedEntityID], [LinkedRecordPrimaryKey])
VALUES ('24851e7a-e6ce-4393-8efe-c113f8cd006b', (SELECT [ID] FROM [${mjSchema}].[vwGeneratedCodeCategories] WHERE [Name]='CodeGen: Validators'), '4B500A24-0259-4EFF-9E34-24E9F5EC9DAB', GETUTCDATE(), 'TypeScript', 'Approved', '([Source]=N''Manual'' OR [SourceSystem] IS NOT NULL)', 'public ValidateSourceSystemWhenSourceNotManual(result: ValidationResult) {
	if (this.Source !== "Manual" && (this.SourceSystem == null || this.SourceSystem.trim() === "")) {
		result.Errors.push(new ValidationErrorInfo(
			"SourceSystem",
			"A source system must be specified when the source is not Manual.",
			this.SourceSystem,
			ValidationErrorType.Failure
		));
	}
}', 'A source system is required to track where the data originated unless the record is manually created.', 'ValidateSourceSystemWhenSourceNotManual', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', '709CA9DA-B124-4155-BE39-E857EF672D82')
   END;

