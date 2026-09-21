-- =============================================================================
-- Migration: V202609211200__v5.45.x__Job_Function_Seniority.sql
-- Description: Job function and seniority people model (P2-2a / D24)
--              - Tables: JobFunction, SeniorityLevel, PersonJobFunction
--              - Foreign keys on Person and Relationship
--              - Virtual view columns on vwPeople: PrimaryJobFunctionID, PrimaryJobFunction
-- =============================================================================

---------------------------------------------------------------------------
-- JobFunction: type table for business job functions (Engineering, Marketing, etc.)
---------------------------------------------------------------------------
IF OBJECT_ID(N'[${flyway:defaultSchema}].[JobFunction]', N'U') IS NULL
BEGIN
    CREATE TABLE [${flyway:defaultSchema}].[JobFunction] (
        ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
        Name NVARCHAR(100) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        Sequence INT NOT NULL DEFAULT 0,
        Status NVARCHAR(20) NOT NULL DEFAULT N'Active',
        [__mj_CreatedAt] DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE(),
        [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT PK_JobFunction PRIMARY KEY (ID),
        CONSTRAINT UQ_JobFunction_Name UNIQUE (Name),
        CONSTRAINT CK_JobFunction_Status CHECK (Status IN (N'Active', N'Disabled'))
    );
END
GO

---------------------------------------------------------------------------
-- SeniorityLevel: type table for career seniority rank (IC, Manager, Director, VP, C-Level)
---------------------------------------------------------------------------
IF OBJECT_ID(N'[${flyway:defaultSchema}].[SeniorityLevel]', N'U') IS NULL
BEGIN
    CREATE TABLE [${flyway:defaultSchema}].[SeniorityLevel] (
        ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
        Name NVARCHAR(100) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        Sequence INT NOT NULL DEFAULT 0,
        Status NVARCHAR(20) NOT NULL DEFAULT N'Active',
        [__mj_CreatedAt] DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE(),
        [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT PK_SeniorityLevel PRIMARY KEY (ID),
        CONSTRAINT UQ_SeniorityLevel_Name UNIQUE (Name),
        CONSTRAINT CK_SeniorityLevel_Status CHECK (Status IN (N'Active', N'Disabled'))
    );
END
GO

---------------------------------------------------------------------------
-- PersonJobFunction: 1:M association between Person and JobFunction(s)
---------------------------------------------------------------------------
IF OBJECT_ID(N'[${flyway:defaultSchema}].[PersonJobFunction]', N'U') IS NULL
BEGIN
    CREATE TABLE [${flyway:defaultSchema}].[PersonJobFunction] (
        ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
        PersonID UNIQUEIDENTIFIER NOT NULL,
        JobFunctionID UNIQUEIDENTIFIER NOT NULL,
        Sequence INT NOT NULL DEFAULT 0,
        Source NVARCHAR(20) NOT NULL DEFAULT N'Manual',
        Confidence DECIMAL(5, 4) NULL,
        [__mj_CreatedAt] DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE(),
        [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT PK_PersonJobFunction PRIMARY KEY (ID),
        CONSTRAINT FK_PersonJobFunction_Person FOREIGN KEY (PersonID)
            REFERENCES [${flyway:defaultSchema}].[Person](ID)
            ON DELETE CASCADE,
        CONSTRAINT FK_PersonJobFunction_JobFunction FOREIGN KEY (JobFunctionID)
            REFERENCES [${flyway:defaultSchema}].[JobFunction](ID),
        CONSTRAINT UQ_PersonJobFunction_Person_JobFunction UNIQUE (PersonID, JobFunctionID),
        CONSTRAINT CK_PersonJobFunction_Source CHECK (Source IN (N'Manual', N'Derived')),
        CONSTRAINT CK_PersonJobFunction_Confidence CHECK (Confidence IS NULL OR (Confidence >= 0.0 AND Confidence <= 1.0))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PersonJobFunction_Person_Sequence' AND object_id = OBJECT_ID(N'[${flyway:defaultSchema}].[PersonJobFunction]'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_PersonJobFunction_Person_Sequence
        ON [${flyway:defaultSchema}].[PersonJobFunction] (PersonID, Sequence ASC);
END
GO

---------------------------------------------------------------------------
-- Person: add SeniorityLevelID FK
---------------------------------------------------------------------------
IF COL_LENGTH(N'[${flyway:defaultSchema}].[Person]', N'SeniorityLevelID') IS NULL
BEGIN
    ALTER TABLE [${flyway:defaultSchema}].[Person]
        ADD SeniorityLevelID UNIQUEIDENTIFIER NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Person_SeniorityLevel')
BEGIN
    ALTER TABLE [${flyway:defaultSchema}].[Person]
        ADD CONSTRAINT FK_Person_SeniorityLevel FOREIGN KEY (SeniorityLevelID)
            REFERENCES [${flyway:defaultSchema}].[SeniorityLevel](ID);
END
GO

---------------------------------------------------------------------------
-- Relationship: add JobFunctionID and SeniorityLevelID FKs
---------------------------------------------------------------------------
IF COL_LENGTH(N'[${flyway:defaultSchema}].[Relationship]', N'JobFunctionID') IS NULL
BEGIN
    ALTER TABLE [${flyway:defaultSchema}].[Relationship]
        ADD JobFunctionID UNIQUEIDENTIFIER NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Relationship_JobFunction')
BEGIN
    ALTER TABLE [${flyway:defaultSchema}].[Relationship]
        ADD CONSTRAINT FK_Relationship_JobFunction FOREIGN KEY (JobFunctionID)
            REFERENCES [${flyway:defaultSchema}].[JobFunction](ID);
END
GO

IF COL_LENGTH(N'[${flyway:defaultSchema}].[Relationship]', N'SeniorityLevelID') IS NULL
BEGIN
    ALTER TABLE [${flyway:defaultSchema}].[Relationship]
        ADD SeniorityLevelID UNIQUEIDENTIFIER NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Relationship_SeniorityLevel')
BEGIN
    ALTER TABLE [${flyway:defaultSchema}].[Relationship]
        ADD CONSTRAINT FK_Relationship_SeniorityLevel FOREIGN KEY (SeniorityLevelID)
            REFERENCES [${flyway:defaultSchema}].[SeniorityLevel](ID);
END
GO

---------------------------------------------------------------------------
-- vwPeople: expose PrimaryJobFunctionID and PrimaryJobFunction via OUTER APPLY
---------------------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwPeople]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwPeople];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwPeople]
AS
SELECT
    -- Everything CodeGen generates: base columns, DisplayName, LinkedUser, and any
    -- foreign-key display field added from here on, without this file changing.
    g.*,

    -- Primary address, resolved through the polymorphic AddressLink (IsPrimary = 1).
    addr.Line1          AS [PrimaryAddressLine1],
    addr.Line2          AS [PrimaryAddressLine2],
    addr.City           AS [PrimaryAddressCity],
    addr.StateProvince  AS [PrimaryAddressState],
    addr.PostalCode     AS [PrimaryAddressPostalCode],
    addr.Country        AS [PrimaryAddressCountry],
    addr.Latitude       AS [PrimaryAddressLatitude],
    addr.Longitude      AS [PrimaryAddressLongitude],
    addrType.Name       AS [PrimaryAddressType],

    -- Primary contact methods, falling back to the columns on Person itself.
    COALESCE(cm_email.Value, g.Email) AS [PrimaryEmail],
    COALESCE(cm_phone.Value, g.Phone) AS [PrimaryPhone],

    -- Current employer: most recent active Employee relationship.
    emp_org.ID          AS [CurrentOrganizationID],
    emp_org.Name        AS [CurrentOrganizationName],
    emp_rel.Title       AS [CurrentJobTitle],

    -- Primary job function: lowest Sequence PersonJobFunction row.
    primary_jf.JobFunctionID   AS [PrimaryJobFunctionID],
    primary_jf.JobFunctionName AS [PrimaryJobFunction]

FROM
    [${flyway:defaultSchema}].[vwPeopleGenerated] AS g

LEFT OUTER JOIN
    [${flyway:defaultSchema}].[AddressLink] AS al
  ON
    al.[RecordID] = CAST(g.[ID] AS NVARCHAR(MAX))
    AND al.[EntityID] = (
        SELECT [ID] FROM [${mjSchema}].[Entity]
        WHERE [Name] = 'MJ_BizApps_Common: People'
    )
    AND al.[IsPrimary] = 1
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Address] AS addr
  ON
    addr.[ID] = al.[AddressID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[AddressType] AS addrType
  ON
    addrType.[ID] = al.[AddressTypeID]

LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ContactMethod] AS cm_email
  ON
    cm_email.[PersonID] = g.[ID]
    AND cm_email.[IsPrimary] = 1
    AND cm_email.[ContactTypeID] = (
        SELECT [ID] FROM [${flyway:defaultSchema}].[ContactType]
        WHERE [Name] = 'Email'
    )
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ContactMethod] AS cm_phone
  ON
    cm_phone.[PersonID] = g.[ID]
    AND cm_phone.[IsPrimary] = 1
    AND cm_phone.[ContactTypeID] = (
        SELECT [ID] FROM [${flyway:defaultSchema}].[ContactType]
        WHERE [Name] = 'Mobile Phone'
    )

OUTER APPLY (
    SELECT TOP 1
        r.[Title],
        r.[ToOrganizationID]
    FROM
        [${flyway:defaultSchema}].[Relationship] AS r
    INNER JOIN
        [${flyway:defaultSchema}].[RelationshipType] AS rt
      ON
        rt.[ID] = r.[RelationshipTypeID]
    WHERE
        rt.[Name] = 'Employee'
        AND r.[FromPersonID] = g.[ID]
        AND r.[Status] = 'Active'
    ORDER BY
        r.[StartDate] DESC
) AS emp_rel
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Organization] AS emp_org
  ON
    emp_org.[ID] = emp_rel.[ToOrganizationID]

OUTER APPLY (
    SELECT TOP 1
        pjf.[JobFunctionID],
        jf.[Name] AS [JobFunctionName]
    FROM
        [${flyway:defaultSchema}].[PersonJobFunction] AS pjf
    INNER JOIN
        [${flyway:defaultSchema}].[JobFunction] AS jf
      ON
        jf.[ID] = pjf.[JobFunctionID]
    WHERE
        pjf.[PersonID] = g.[ID]
    ORDER BY
        pjf.[Sequence] ASC,
        jf.[Name] ASC
) AS primary_jf;
GO

---------------------------------------------------------------------------
-- Extended Properties
---------------------------------------------------------------------------
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Business job functions (Engineering, Marketing, Sales, etc.) for categorizing roles and career paths.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'JobFunction';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Unique display name of the job function.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'JobFunction', @level2type=N'COLUMN', @level2name=N'Name';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Detailed description of the job function and the roles it encompasses.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'JobFunction', @level2type=N'COLUMN', @level2name=N'Description';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Display sort sequence order.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'JobFunction', @level2type=N'COLUMN', @level2name=N'Sequence';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Lifecycle status (Active, Inactive) of the job function.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'JobFunction', @level2type=N'COLUMN', @level2name=N'Status';

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Career seniority levels carrying rank order (IC, Manager, Director, VP, C-Level) for skill and scope classification.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'SeniorityLevel';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Unique display name of the seniority level.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'SeniorityLevel', @level2type=N'COLUMN', @level2name=N'Name';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Detailed description of the seniority level and role expectations.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'SeniorityLevel', @level2type=N'COLUMN', @level2name=N'Description';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Rank order sequence from entry-level/IC to executive/C-level.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'SeniorityLevel', @level2type=N'COLUMN', @level2name=N'Sequence';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Lifecycle status (Active, Inactive) of the seniority level.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'SeniorityLevel', @level2type=N'COLUMN', @level2name=N'Status';

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'1:M assignment of job functions to a person, supporting plural functions and ranking order.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonJobFunction';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Rank order sequence for a person with multiple job functions (Sequence 1 = primary).',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonJobFunction', @level2type=N'COLUMN', @level2name=N'Sequence';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Provenance of this function assignment (Manual by user, or Derived by automated pipeline).',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonJobFunction', @level2type=N'COLUMN', @level2name=N'Source';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Confidence score between 0.0 and 1.0 when derived by an AI feature pipeline.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonJobFunction', @level2type=N'COLUMN', @level2name=N'Confidence';

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Current primary seniority level for this person.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Person', @level2type=N'COLUMN', @level2name=N'SeniorityLevelID';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Company-specific job function for this relationship/employment link.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Relationship', @level2type=N'COLUMN', @level2name=N'JobFunctionID';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Company-specific seniority level for this relationship/employment link.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Relationship', @level2type=N'COLUMN', @level2name=N'SeniorityLevelID';
GO



















































-- =============================================================================
-- GENERATED BY MemberJunction CodeGen — DO NOT EDIT BY HAND
-- =============================================================================

---------------------------------------------------------------------------
-- 1. Entity Registrations
---------------------------------------------------------------------------
/* SQL generated to create new entity MJ_BizApps_Common: Job Functions */

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[Entity] WHERE [ID] = 'b453313c-d2fe-4bb9-9e6f-1d048495299d')
BEGIN
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
         'b453313c-d2fe-4bb9-9e6f-1d048495299d',
         'MJ_BizApps_Common: Job Functions',
         'Job Functions',
         'Business job functions (Engineering, Marketing, Sales, etc.) for categorizing roles and career paths.',
         NULL,
         'JobFunction',
         'vwJobFunctions',
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
END;
GO

/* SQL generated to add new entity MJ_BizApps_Common: Job Functions to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' AND [EntityID] = 'b453313c-d2fe-4bb9-9e6f-1d048495299d')
BEGIN
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'b453313c-d2fe-4bb9-9e6f-1d048495299d', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());
END;
GO

/* SQL generated to add new permission for entity MJ_BizApps_Common: Job Functions for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('b453313c-d2fe-4bb9-9e6f-1d048495299d' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('b453313c-d2fe-4bb9-9e6f-1d048495299d' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Job Functions for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('b453313c-d2fe-4bb9-9e6f-1d048495299d' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('b453313c-d2fe-4bb9-9e6f-1d048495299d' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Job Functions for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('b453313c-d2fe-4bb9-9e6f-1d048495299d' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('b453313c-d2fe-4bb9-9e6f-1d048495299d' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to create new entity MJ_BizApps_Common: Seniority Levels */

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[Entity] WHERE [ID] = 'adcd72cb-b817-4fbc-97a4-80ee770376d1')
BEGIN
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
         'adcd72cb-b817-4fbc-97a4-80ee770376d1',
         'MJ_BizApps_Common: Seniority Levels',
         'Seniority Levels',
         'Career seniority levels carrying rank order (IC, Manager, Director, VP, C-Level) for skill and scope classification.',
         NULL,
         'SeniorityLevel',
         'vwSeniorityLevels',
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
END;
GO

/* SQL generated to add new entity MJ_BizApps_Common: Seniority Levels to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' AND [EntityID] = 'adcd72cb-b817-4fbc-97a4-80ee770376d1')
BEGIN
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'adcd72cb-b817-4fbc-97a4-80ee770376d1', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());
END;
GO

/* SQL generated to add new permission for entity MJ_BizApps_Common: Seniority Levels for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('adcd72cb-b817-4fbc-97a4-80ee770376d1' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('adcd72cb-b817-4fbc-97a4-80ee770376d1' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Seniority Levels for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('adcd72cb-b817-4fbc-97a4-80ee770376d1' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('adcd72cb-b817-4fbc-97a4-80ee770376d1' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Seniority Levels for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('adcd72cb-b817-4fbc-97a4-80ee770376d1' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('adcd72cb-b817-4fbc-97a4-80ee770376d1' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to create new entity MJ_BizApps_Common: Person Job Functions */

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[Entity] WHERE [ID] = '09d27a10-6c32-4eb5-a5da-0317a8168c53')
BEGIN
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
         '09d27a10-6c32-4eb5-a5da-0317a8168c53',
         'MJ_BizApps_Common: Person Job Functions',
         'Person Job Functions',
         '1:M assignment of job functions to a person, supporting plural functions and ranking order.',
         NULL,
         'PersonJobFunction',
         'vwPersonJobFunctions',
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
END;
GO

/* SQL generated to add new entity MJ_BizApps_Common: Person Job Functions to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' AND [EntityID] = '09d27a10-6c32-4eb5-a5da-0317a8168c53')
BEGIN
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '09d27a10-6c32-4eb5-a5da-0317a8168c53', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());
END;
GO

/* SQL generated to add new permission for entity MJ_BizApps_Common: Person Job Functions for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('09d27a10-6c32-4eb5-a5da-0317a8168c53' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('09d27a10-6c32-4eb5-a5da-0317a8168c53' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Person Job Functions for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('09d27a10-6c32-4eb5-a5da-0317a8168c53' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('09d27a10-6c32-4eb5-a5da-0317a8168c53' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Person Job Functions for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('09d27a10-6c32-4eb5-a5da-0317a8168c53' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('09d27a10-6c32-4eb5-a5da-0317a8168c53' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );


---------------------------------------------------------------------------
-- 2. Entity Fields
---------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f6cd5478-e440-4ffb-a97d-2279fca7e7fb' OR (EntityID = '09D27A10-6C32-4EB5-A5DA-0317A8168C53' AND Name = 'ID')) BEGIN
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
            'f6cd5478-e440-4ffb-a97d-2279fca7e7fb',
            '09D27A10-6C32-4EB5-A5DA-0317A8168C53', -- Entity: MJ_BizApps_Common: Person Job Functions
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '09D27A10-6C32-4EB5-A5DA-0317A8168C53'),
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '4389d414-26d3-463e-a90d-38afa3836e5c' OR (EntityID = '09D27A10-6C32-4EB5-A5DA-0317A8168C53' AND Name = 'PersonID')) BEGIN
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
            '4389d414-26d3-463e-a90d-38afa3836e5c',
            '09D27A10-6C32-4EB5-A5DA-0317A8168C53', -- Entity: MJ_BizApps_Common: Person Job Functions
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '09D27A10-6C32-4EB5-A5DA-0317A8168C53'),
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '439bdb57-0951-443d-a70a-b35ecf982a21' OR (EntityID = '09D27A10-6C32-4EB5-A5DA-0317A8168C53' AND Name = 'JobFunctionID')) BEGIN
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
            '439bdb57-0951-443d-a70a-b35ecf982a21',
            '09D27A10-6C32-4EB5-A5DA-0317A8168C53', -- Entity: MJ_BizApps_Common: Person Job Functions
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '09D27A10-6C32-4EB5-A5DA-0317A8168C53'),
            'JobFunctionID',
            'Job Function ID',
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
            'B453313C-D2FE-4BB9-9E6F-1D048495299D',
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c9d0dde8-e92c-4aff-bf6e-38bd66c73b6d' OR (EntityID = '09D27A10-6C32-4EB5-A5DA-0317A8168C53' AND Name = 'Sequence')) BEGIN
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
            'c9d0dde8-e92c-4aff-bf6e-38bd66c73b6d',
            '09D27A10-6C32-4EB5-A5DA-0317A8168C53', -- Entity: MJ_BizApps_Common: Person Job Functions
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '09D27A10-6C32-4EB5-A5DA-0317A8168C53'),
            'Sequence',
            'Sequence',
            NULL,
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
            1,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '43d9293d-cfda-409e-9e1f-617f547e783b' OR (EntityID = '09D27A10-6C32-4EB5-A5DA-0317A8168C53' AND Name = 'Source')) BEGIN
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
            '43d9293d-cfda-409e-9e1f-617f547e783b',
            '09D27A10-6C32-4EB5-A5DA-0317A8168C53', -- Entity: MJ_BizApps_Common: Person Job Functions
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '09D27A10-6C32-4EB5-A5DA-0317A8168C53'),
            'Source',
            'Source',
            NULL,
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
            1,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'ff39c3b5-e0b6-47c3-8aed-e8dc16717356' OR (EntityID = '09D27A10-6C32-4EB5-A5DA-0317A8168C53' AND Name = 'Confidence')) BEGIN
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
            'ff39c3b5-e0b6-47c3-8aed-e8dc16717356',
            '09D27A10-6C32-4EB5-A5DA-0317A8168C53', -- Entity: MJ_BizApps_Common: Person Job Functions
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '09D27A10-6C32-4EB5-A5DA-0317A8168C53'),
            'Confidence',
            'Confidence',
            NULL,
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8aebf883-89a4-4083-9ddf-499f43b1840f' OR (EntityID = '09D27A10-6C32-4EB5-A5DA-0317A8168C53' AND Name = '__mj_CreatedAt')) BEGIN
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
            '8aebf883-89a4-4083-9ddf-499f43b1840f',
            '09D27A10-6C32-4EB5-A5DA-0317A8168C53', -- Entity: MJ_BizApps_Common: Person Job Functions
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '09D27A10-6C32-4EB5-A5DA-0317A8168C53'),
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '02290f0a-9930-47d2-bff3-280821750653' OR (EntityID = '09D27A10-6C32-4EB5-A5DA-0317A8168C53' AND Name = '__mj_UpdatedAt')) BEGIN
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
            '02290f0a-9930-47d2-bff3-280821750653',
            '09D27A10-6C32-4EB5-A5DA-0317A8168C53', -- Entity: MJ_BizApps_Common: Person Job Functions
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '09D27A10-6C32-4EB5-A5DA-0317A8168C53'),
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'a6f8c6fc-e516-419f-bc16-3eecb07a0ea0' OR (EntityID = 'B453313C-D2FE-4BB9-9E6F-1D048495299D' AND Name = 'ID')) BEGIN
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
            'a6f8c6fc-e516-419f-bc16-3eecb07a0ea0',
            'B453313C-D2FE-4BB9-9E6F-1D048495299D', -- Entity: MJ_BizApps_Common: Job Functions
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'B453313C-D2FE-4BB9-9E6F-1D048495299D'),
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '6e943f80-e01f-4b7e-8fe8-ecf10a20c56d' OR (EntityID = 'B453313C-D2FE-4BB9-9E6F-1D048495299D' AND Name = 'Name')) BEGIN
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
            '6e943f80-e01f-4b7e-8fe8-ecf10a20c56d',
            'B453313C-D2FE-4BB9-9E6F-1D048495299D', -- Entity: MJ_BizApps_Common: Job Functions
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'B453313C-D2FE-4BB9-9E6F-1D048495299D'),
            'Name',
            'Name',
            NULL,
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f4bd89b6-ec34-45db-9507-a3b12fcce40c' OR (EntityID = 'B453313C-D2FE-4BB9-9E6F-1D048495299D' AND Name = 'Description')) BEGIN
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
            'f4bd89b6-ec34-45db-9507-a3b12fcce40c',
            'B453313C-D2FE-4BB9-9E6F-1D048495299D', -- Entity: MJ_BizApps_Common: Job Functions
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'B453313C-D2FE-4BB9-9E6F-1D048495299D'),
            'Description',
            'Description',
            NULL,
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'ff1d9b55-7ecd-49f8-bf33-121429fe4bdf' OR (EntityID = 'B453313C-D2FE-4BB9-9E6F-1D048495299D' AND Name = 'Sequence')) BEGIN
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
            'ff1d9b55-7ecd-49f8-bf33-121429fe4bdf',
            'B453313C-D2FE-4BB9-9E6F-1D048495299D', -- Entity: MJ_BizApps_Common: Job Functions
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'B453313C-D2FE-4BB9-9E6F-1D048495299D'),
            'Sequence',
            'Sequence',
            NULL,
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
            1,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'd2f1bdab-7fb3-4897-98fb-49116cfcc7d8' OR (EntityID = 'B453313C-D2FE-4BB9-9E6F-1D048495299D' AND Name = 'Status')) BEGIN
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
            'd2f1bdab-7fb3-4897-98fb-49116cfcc7d8',
            'B453313C-D2FE-4BB9-9E6F-1D048495299D', -- Entity: MJ_BizApps_Common: Job Functions
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'B453313C-D2FE-4BB9-9E6F-1D048495299D'),
            'Status',
            'Status',
            NULL,
            'nvarchar',
            40,
            0,
            0,
            0,
            'Active',
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '0bd3af7f-ef62-4f93-aabb-7caa1d402f75' OR (EntityID = 'B453313C-D2FE-4BB9-9E6F-1D048495299D' AND Name = '__mj_CreatedAt')) BEGIN
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
            '0bd3af7f-ef62-4f93-aabb-7caa1d402f75',
            'B453313C-D2FE-4BB9-9E6F-1D048495299D', -- Entity: MJ_BizApps_Common: Job Functions
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'B453313C-D2FE-4BB9-9E6F-1D048495299D'),
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '22860fab-3009-4a08-be37-3b7bf40f5825' OR (EntityID = 'B453313C-D2FE-4BB9-9E6F-1D048495299D' AND Name = '__mj_UpdatedAt')) BEGIN
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
            '22860fab-3009-4a08-be37-3b7bf40f5825',
            'B453313C-D2FE-4BB9-9E6F-1D048495299D', -- Entity: MJ_BizApps_Common: Job Functions
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'B453313C-D2FE-4BB9-9E6F-1D048495299D'),
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '715dafb6-f807-4006-b232-1f683108e7ca' OR (EntityID = 'ADCD72CB-B817-4FBC-97A4-80EE770376D1' AND Name = 'ID')) BEGIN
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
            '715dafb6-f807-4006-b232-1f683108e7ca',
            'ADCD72CB-B817-4FBC-97A4-80EE770376D1', -- Entity: MJ_BizApps_Common: Seniority Levels
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'ADCD72CB-B817-4FBC-97A4-80EE770376D1'),
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'a395c9b8-2c44-46ac-bb4c-acd807c29722' OR (EntityID = 'ADCD72CB-B817-4FBC-97A4-80EE770376D1' AND Name = 'Name')) BEGIN
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
            'a395c9b8-2c44-46ac-bb4c-acd807c29722',
            'ADCD72CB-B817-4FBC-97A4-80EE770376D1', -- Entity: MJ_BizApps_Common: Seniority Levels
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'ADCD72CB-B817-4FBC-97A4-80EE770376D1'),
            'Name',
            'Name',
            NULL,
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '306b9ecf-2241-40bc-9f2f-8006ad966e39' OR (EntityID = 'ADCD72CB-B817-4FBC-97A4-80EE770376D1' AND Name = 'Description')) BEGIN
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
            '306b9ecf-2241-40bc-9f2f-8006ad966e39',
            'ADCD72CB-B817-4FBC-97A4-80EE770376D1', -- Entity: MJ_BizApps_Common: Seniority Levels
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'ADCD72CB-B817-4FBC-97A4-80EE770376D1'),
            'Description',
            'Description',
            NULL,
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '58bdf256-0f00-4654-875f-9171083ea0b6' OR (EntityID = 'ADCD72CB-B817-4FBC-97A4-80EE770376D1' AND Name = 'Sequence')) BEGIN
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
            '58bdf256-0f00-4654-875f-9171083ea0b6',
            'ADCD72CB-B817-4FBC-97A4-80EE770376D1', -- Entity: MJ_BizApps_Common: Seniority Levels
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'ADCD72CB-B817-4FBC-97A4-80EE770376D1'),
            'Sequence',
            'Sequence',
            NULL,
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
            1,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'bf5cc452-2914-46da-b5a2-195e3f27104f' OR (EntityID = 'ADCD72CB-B817-4FBC-97A4-80EE770376D1' AND Name = 'Status')) BEGIN
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
            'bf5cc452-2914-46da-b5a2-195e3f27104f',
            'ADCD72CB-B817-4FBC-97A4-80EE770376D1', -- Entity: MJ_BizApps_Common: Seniority Levels
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'ADCD72CB-B817-4FBC-97A4-80EE770376D1'),
            'Status',
            'Status',
            NULL,
            'nvarchar',
            40,
            0,
            0,
            0,
            'Active',
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f3936745-6016-46b4-a660-e6f1cd51ab7a' OR (EntityID = 'ADCD72CB-B817-4FBC-97A4-80EE770376D1' AND Name = '__mj_CreatedAt')) BEGIN
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
            'f3936745-6016-46b4-a660-e6f1cd51ab7a',
            'ADCD72CB-B817-4FBC-97A4-80EE770376D1', -- Entity: MJ_BizApps_Common: Seniority Levels
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'ADCD72CB-B817-4FBC-97A4-80EE770376D1'),
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '22ff7eaa-eef0-4be9-a097-5f26c74ad1dd' OR (EntityID = 'ADCD72CB-B817-4FBC-97A4-80EE770376D1' AND Name = '__mj_UpdatedAt')) BEGIN
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
            '22ff7eaa-eef0-4be9-a097-5f26c74ad1dd',
            'ADCD72CB-B817-4FBC-97A4-80EE770376D1', -- Entity: MJ_BizApps_Common: Seniority Levels
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'ADCD72CB-B817-4FBC-97A4-80EE770376D1'),
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'a26f17b8-fdc7-4610-8872-40afb9fdbf8b' OR (EntityID = '09D27A10-6C32-4EB5-A5DA-0317A8168C53' AND Name = 'Person')) BEGIN
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
            'a26f17b8-fdc7-4610-8872-40afb9fdbf8b',
            '09D27A10-6C32-4EB5-A5DA-0317A8168C53', -- Entity: MJ_BizApps_Common: Person Job Functions
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '09D27A10-6C32-4EB5-A5DA-0317A8168C53'),
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

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f39d5a1b-5600-4183-a766-5ba676f2ca5f' OR (EntityID = '09D27A10-6C32-4EB5-A5DA-0317A8168C53' AND Name = 'JobFunction')) BEGIN
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
            'f39d5a1b-5600-4183-a766-5ba676f2ca5f',
            '09D27A10-6C32-4EB5-A5DA-0317A8168C53', -- Entity: MJ_BizApps_Common: Person Job Functions
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '09D27A10-6C32-4EB5-A5DA-0317A8168C53'),
            'JobFunction',
            'Job Function',
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

---------------------------------------------------------------------------
-- 3. Entity Field Values (Value Lists)
---------------------------------------------------------------------------
/* SQL text to insert entity field value with ID 5ce01875-892f-49ca-aa8e-354e14da2644 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('5ce01875-892f-49ca-aa8e-354e14da2644', 'D2F1BDAB-7FB3-4897-98FB-49116CFCC7D8', 1, 'Active', 'Active', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 50a24ea4-b456-404a-a55d-41216c7a956a */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('50a24ea4-b456-404a-a55d-41216c7a956a', 'D2F1BDAB-7FB3-4897-98FB-49116CFCC7D8', 2, 'Disabled', 'Disabled', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID D2F1BDAB-7FB3-4897-98FB-49116CFCC7D8 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='D2F1BDAB-7FB3-4897-98FB-49116CFCC7D8';

/* SQL text to insert entity field value with ID b2aacf3a-6d63-4897-aedd-ada2c75ae275 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('b2aacf3a-6d63-4897-aedd-ada2c75ae275', 'BF5CC452-2914-46DA-B5A2-195E3F27104F', 1, 'Active', 'Active', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 84a48182-56de-4972-9e38-0faca6289b64 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('84a48182-56de-4972-9e38-0faca6289b64', 'BF5CC452-2914-46DA-B5A2-195E3F27104F', 2, 'Disabled', 'Disabled', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID BF5CC452-2914-46DA-B5A2-195E3F27104F */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='BF5CC452-2914-46DA-B5A2-195E3F27104F';

/* SQL text to insert entity field value with ID 646783fe-b4f2-4b0f-9f66-8669cfee245e */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('646783fe-b4f2-4b0f-9f66-8669cfee245e', '43D9293D-CFDA-409E-9E1F-617F547E783B', 1, 'Derived', 'Derived', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID d63d0687-cc76-41f0-9812-015dfe9cb9bf */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('d63d0687-cc76-41f0-9812-015dfe9cb9bf', '43D9293D-CFDA-409E-9E1F-617F547E783B', 2, 'Manual', 'Manual', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 43D9293D-CFDA-409E-9E1F-617F547E783B */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='43D9293D-CFDA-409E-9E1F-617F547E783B';



---------------------------------------------------------------------------
-- 4. Entity Relationships
---------------------------------------------------------------------------
/* Create Entity Relationship: MJ_BizApps_Common: Job Functions -> MJ_BizApps_Common: Person Job Functions (One To Many via JobFunctionID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '3ac99e02-8cc8-4fb6-9311-8e47ba01c3ec'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('3ac99e02-8cc8-4fb6-9311-8e47ba01c3ec', 'B453313C-D2FE-4BB9-9E6F-1D048495299D', '09D27A10-6C32-4EB5-A5DA-0317A8168C53', 'JobFunctionID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ_BizApps_Common: Job Functions -> MJ_BizApps_Common: Relationships (One To Many via JobFunctionID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '97b789f1-43e8-4669-a06e-a60651e730ac'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('97b789f1-43e8-4669-a06e-a60651e730ac', 'B453313C-D2FE-4BB9-9E6F-1D048495299D', '709CA9DA-B124-4155-BE39-E857EF672D82', 'JobFunctionID', 'One To Many', 1, 1, 2, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Seniority Levels -> MJ_BizApps_Common: People (One To Many via SeniorityLevelID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '6302d88e-5f4d-4e9c-94f7-f88642c9c776'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('6302d88e-5f4d-4e9c-94f7-f88642c9c776', 'ADCD72CB-B817-4FBC-97A4-80EE770376D1', '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', 'SeniorityLevelID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ_BizApps_Common: Seniority Levels -> MJ_BizApps_Common: Relationships (One To Many via SeniorityLevelID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'e14c07be-d019-40ba-a6dc-9b730ba9d874'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('e14c07be-d019-40ba-a6dc-9b730ba9d874', 'ADCD72CB-B817-4FBC-97A4-80EE770376D1', '709CA9DA-B124-4155-BE39-E857EF672D82', 'SeniorityLevelID', 'One To Many', 1, 1, 2, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: People -> MJ_BizApps_Common: Person Job Functions (One To Many via PersonID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'f3463be5-f757-46a8-ab5f-c09dc6314645'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('f3463be5-f757-46a8-ab5f-c09dc6314645', '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', '09D27A10-6C32-4EB5-A5DA-0317A8168C53', 'PersonID', 'One To Many', 1, 1, 39, GETUTCDATE(), GETUTCDATE())
   END;


---------------------------------------------------------------------------
-- 5. Base Views & Permissions
---------------------------------------------------------------------------
/* Base View SQL for MJ_BizApps_Common: Job Functions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Job Functions
-- Item: vwJobFunctions
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Job Functions
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  JobFunction
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwJobFunctions]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwJobFunctions];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwJobFunctions]
AS
SELECT
    j.*
FROM
    [${flyway:defaultSchema}].[JobFunction] AS j
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwJobFunctions] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Job Functions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Job Functions
-- Item: Permissions for vwJobFunctions
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwJobFunctions] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View SQL for MJ_BizApps_Common: Seniority Levels */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Seniority Levels
-- Item: vwSeniorityLevels
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Seniority Levels
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  SeniorityLevel
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwSeniorityLevels]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwSeniorityLevels];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwSeniorityLevels]
AS
SELECT
    s.*
FROM
    [${flyway:defaultSchema}].[SeniorityLevel] AS s
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwSeniorityLevels] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Seniority Levels */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Seniority Levels
-- Item: Permissions for vwSeniorityLevels
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwSeniorityLevels] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View SQL for MJ_BizApps_Common: Person Job Functions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person Job Functions
-- Item: vwPersonJobFunctions
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Person Job Functions
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  PersonJobFunction
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwPersonJobFunctions]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwPersonJobFunctions];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwPersonJobFunctions]
AS
SELECT
    p.*,
    mjBizAppsCommonPerson_PersonID.[DisplayName] AS [Person],
    mjBizAppsCommonJobFunction_JobFunctionID.[Name] AS [JobFunction]
FROM
    [${flyway:defaultSchema}].[PersonJobFunction] AS p
INNER JOIN
    [${flyway:defaultSchema}].[Person] AS mjBizAppsCommonPerson_PersonID
  ON
    [p].[PersonID] = mjBizAppsCommonPerson_PersonID.[ID]
INNER JOIN
    [${flyway:defaultSchema}].[JobFunction] AS mjBizAppsCommonJobFunction_JobFunctionID
  ON
    [p].[JobFunctionID] = mjBizAppsCommonJobFunction_JobFunctionID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwPersonJobFunctions] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Person Job Functions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person Job Functions
-- Item: Permissions for vwPersonJobFunctions
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwPersonJobFunctions] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

GO

CREATE VIEW [${flyway:defaultSchema}].[vwPeopleGenerated]
AS
SELECT
    p.*,
    MJUser_LinkedUserID.[Name] AS [LinkedUser],
    mjBizAppsCommonSeniorityLevel_SeniorityLevelID.[Name] AS [SeniorityLevel]
FROM
    [${flyway:defaultSchema}].[Person] AS p
LEFT OUTER JOIN
    [${mjSchema}].[User] AS MJUser_LinkedUserID
  ON
    [p].[LinkedUserID] = MJUser_LinkedUserID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[SeniorityLevel] AS mjBizAppsCommonSeniorityLevel_SeniorityLevelID
  ON
    [p].[SeniorityLevelID] = mjBizAppsCommonSeniorityLevel_SeniorityLevelID.[ID]
GO
IF OBJECT_ID('[${flyway:defaultSchema}].[vwPeople]', 'V') IS NOT NULL
BEGIN
    EXEC sp_executesql N'GRANT SELECT ON [${flyway:defaultSchema}].[vwPeople] TO [cdp_UI], [cdp_Developer], [cdp_Integration]';
END;

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


---------------------------------------------------------------------------
-- 6. Stored Procedures & Permissions
---------------------------------------------------------------------------
----- CREATE PROCEDURE FOR JobFunction
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateJobFunction]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateJobFunction];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateJobFunction]
    @ID uniqueidentifier = NULL,
    @Name nvarchar(100),
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Sequence int = NULL,
    @Status nvarchar(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[JobFunction]
            (
                [ID],
                [Name],
                [Description],
                [Sequence],
                [Status]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                ISNULL(@Sequence, 0),
                ISNULL(@Status, 'Active')
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[JobFunction]
            (
                [Name],
                [Description],
                [Sequence],
                [Status]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                ISNULL(@Sequence, 0),
                ISNULL(@Status, 'Active')
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwJobFunctions] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateJobFunction] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Job Functions */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateJobFunction] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Job Functions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Job Functions
-- Item: spUpdateJobFunction
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR JobFunction
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateJobFunction]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateJobFunction];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateJobFunction]
    @ID uniqueidentifier,
    @Name nvarchar(100) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Sequence int = NULL,
    @Status nvarchar(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[JobFunction]
    SET
        [Name] = ISNULL(@Name, [Name]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [Status] = ISNULL(@Status, [Status])
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwJobFunctions] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwJobFunctions]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateJobFunction] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the JobFunction table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateJobFunction]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateJobFunction];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateJobFunction
ON [${flyway:defaultSchema}].[JobFunction]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[JobFunction]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[JobFunction] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Job Functions */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateJobFunction] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Job Functions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Job Functions
-- Item: spDeleteJobFunction
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR JobFunction
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteJobFunction]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteJobFunction];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteJobFunction]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[JobFunction]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteJobFunction] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Job Functions */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteJobFunction] TO [cdp_Developer], [cdp_Integration];

/* Hierarchy Metadata Function SQL for MJ_BizApps_Common: Organizations.ParentID */
-----------------------------------------------------------------
-- SQL Code Generation
----- CREATE PROCEDURE FOR SeniorityLevel
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateSeniorityLevel]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateSeniorityLevel];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateSeniorityLevel]
    @ID uniqueidentifier = NULL,
    @Name nvarchar(100),
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Sequence int = NULL,
    @Status nvarchar(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[SeniorityLevel]
            (
                [ID],
                [Name],
                [Description],
                [Sequence],
                [Status]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                ISNULL(@Sequence, 0),
                ISNULL(@Status, 'Active')
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[SeniorityLevel]
            (
                [Name],
                [Description],
                [Sequence],
                [Status]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                ISNULL(@Sequence, 0),
                ISNULL(@Status, 'Active')
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwSeniorityLevels] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateSeniorityLevel] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Seniority Levels */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateSeniorityLevel] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Seniority Levels */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Seniority Levels
-- Item: spUpdateSeniorityLevel
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR SeniorityLevel
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateSeniorityLevel]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateSeniorityLevel];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateSeniorityLevel]
    @ID uniqueidentifier,
    @Name nvarchar(100) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Sequence int = NULL,
    @Status nvarchar(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[SeniorityLevel]
    SET
        [Name] = ISNULL(@Name, [Name]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [Status] = ISNULL(@Status, [Status])
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwSeniorityLevels] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwSeniorityLevels]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateSeniorityLevel] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the SeniorityLevel table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateSeniorityLevel]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateSeniorityLevel];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateSeniorityLevel
ON [${flyway:defaultSchema}].[SeniorityLevel]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[SeniorityLevel]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[SeniorityLevel] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Seniority Levels */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateSeniorityLevel] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Seniority Levels */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Seniority Levels
-- Item: spDeleteSeniorityLevel
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR SeniorityLevel
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteSeniorityLevel]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteSeniorityLevel];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteSeniorityLevel]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[SeniorityLevel]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteSeniorityLevel] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Seniority Levels */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteSeniorityLevel] TO [cdp_Developer], [cdp_Integration];

/* SQL text to update entity field related entity name field map for entity field ID 438BD1D0-764F-4D90-A51F-24C150CB8313 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='438BD1D0-764F-4D90-A51F-24C150CB8313', @RelatedEntityNameFieldMap='SeniorityLevel';

----- CREATE PROCEDURE FOR PersonJobFunction
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreatePersonJobFunction]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreatePersonJobFunction];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreatePersonJobFunction]
    @ID uniqueidentifier = NULL,
    @PersonID uniqueidentifier,
    @JobFunctionID uniqueidentifier,
    @Sequence int = NULL,
    @Source nvarchar(20) = NULL,
    @Confidence_Clear bit = 0,
    @Confidence decimal(5, 4) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[PersonJobFunction]
            (
                [ID],
                [PersonID],
                [JobFunctionID],
                [Sequence],
                [Source],
                [Confidence]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @PersonID,
                @JobFunctionID,
                ISNULL(@Sequence, 0),
                ISNULL(@Source, 'Manual'),
                CASE WHEN @Confidence_Clear = 1 THEN NULL ELSE ISNULL(@Confidence, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[PersonJobFunction]
            (
                [PersonID],
                [JobFunctionID],
                [Sequence],
                [Source],
                [Confidence]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @PersonID,
                @JobFunctionID,
                ISNULL(@Sequence, 0),
                ISNULL(@Source, 'Manual'),
                CASE WHEN @Confidence_Clear = 1 THEN NULL ELSE ISNULL(@Confidence, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwPersonJobFunctions] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreatePersonJobFunction] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Person Job Functions */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreatePersonJobFunction] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Person Job Functions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person Job Functions
-- Item: spUpdatePersonJobFunction
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR PersonJobFunction
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdatePersonJobFunction]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdatePersonJobFunction];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdatePersonJobFunction]
    @ID uniqueidentifier,
    @PersonID uniqueidentifier = NULL,
    @JobFunctionID uniqueidentifier = NULL,
    @Sequence int = NULL,
    @Source nvarchar(20) = NULL,
    @Confidence_Clear bit = 0,
    @Confidence decimal(5, 4) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[PersonJobFunction]
    SET
        [PersonID] = ISNULL(@PersonID, [PersonID]),
        [JobFunctionID] = ISNULL(@JobFunctionID, [JobFunctionID]),
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [Source] = ISNULL(@Source, [Source]),
        [Confidence] = CASE WHEN @Confidence_Clear = 1 THEN NULL ELSE ISNULL(@Confidence, [Confidence]) END
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwPersonJobFunctions] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwPersonJobFunctions]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdatePersonJobFunction] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the PersonJobFunction table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdatePersonJobFunction]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdatePersonJobFunction];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdatePersonJobFunction
ON [${flyway:defaultSchema}].[PersonJobFunction]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[PersonJobFunction]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[PersonJobFunction] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Person Job Functions */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdatePersonJobFunction] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Person Job Functions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person Job Functions
-- Item: spDeletePersonJobFunction
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR PersonJobFunction
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeletePersonJobFunction]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeletePersonJobFunction];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeletePersonJobFunction]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[PersonJobFunction]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeletePersonJobFunction] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Person Job Functions */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeletePersonJobFunction] TO [cdp_Developer], [cdp_Integration];

----- CREATE PROCEDURE FOR Person
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreatePerson]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreatePerson];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreatePerson]
    @ID uniqueidentifier = NULL,
    @FirstName nvarchar(100),
    @LastName nvarchar(100),
    @MiddleName_Clear bit = 0,
    @MiddleName nvarchar(100) = NULL,
    @Prefix_Clear bit = 0,
    @Prefix nvarchar(20) = NULL,
    @Suffix_Clear bit = 0,
    @Suffix nvarchar(20) = NULL,
    @PreferredName_Clear bit = 0,
    @PreferredName nvarchar(100) = NULL,
    @Title_Clear bit = 0,
    @Title nvarchar(200) = NULL,
    @Email_Clear bit = 0,
    @Email nvarchar(255) = NULL,
    @Phone_Clear bit = 0,
    @Phone nvarchar(50) = NULL,
    @DateOfBirth_Clear bit = 0,
    @DateOfBirth date = NULL,
    @Gender_Clear bit = 0,
    @Gender nvarchar(50) = NULL,
    @PhotoURL_Clear bit = 0,
    @PhotoURL nvarchar(1000) = NULL,
    @Bio_Clear bit = 0,
    @Bio nvarchar(MAX) = NULL,
    @LinkedUserID_Clear bit = 0,
    @LinkedUserID uniqueidentifier = NULL,
    @Status nvarchar(50) = NULL,
    @SeniorityLevelID_Clear bit = 0,
    @SeniorityLevelID uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[Person]
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
                [Status],
                [SeniorityLevelID]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @FirstName,
                @LastName,
                CASE WHEN @MiddleName_Clear = 1 THEN NULL ELSE ISNULL(@MiddleName, NULL) END,
                CASE WHEN @Prefix_Clear = 1 THEN NULL ELSE ISNULL(@Prefix, NULL) END,
                CASE WHEN @Suffix_Clear = 1 THEN NULL ELSE ISNULL(@Suffix, NULL) END,
                CASE WHEN @PreferredName_Clear = 1 THEN NULL ELSE ISNULL(@PreferredName, NULL) END,
                CASE WHEN @Title_Clear = 1 THEN NULL ELSE ISNULL(@Title, NULL) END,
                CASE WHEN @Email_Clear = 1 THEN NULL ELSE ISNULL(@Email, NULL) END,
                CASE WHEN @Phone_Clear = 1 THEN NULL ELSE ISNULL(@Phone, NULL) END,
                CASE WHEN @DateOfBirth_Clear = 1 THEN NULL ELSE ISNULL(@DateOfBirth, NULL) END,
                CASE WHEN @Gender_Clear = 1 THEN NULL ELSE ISNULL(@Gender, NULL) END,
                CASE WHEN @PhotoURL_Clear = 1 THEN NULL ELSE ISNULL(@PhotoURL, NULL) END,
                CASE WHEN @Bio_Clear = 1 THEN NULL ELSE ISNULL(@Bio, NULL) END,
                CASE WHEN @LinkedUserID_Clear = 1 THEN NULL ELSE ISNULL(@LinkedUserID, NULL) END,
                ISNULL(@Status, 'Active'),
                CASE WHEN @SeniorityLevelID_Clear = 1 THEN NULL ELSE ISNULL(@SeniorityLevelID, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[Person]
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
                [Status],
                [SeniorityLevelID]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @FirstName,
                @LastName,
                CASE WHEN @MiddleName_Clear = 1 THEN NULL ELSE ISNULL(@MiddleName, NULL) END,
                CASE WHEN @Prefix_Clear = 1 THEN NULL ELSE ISNULL(@Prefix, NULL) END,
                CASE WHEN @Suffix_Clear = 1 THEN NULL ELSE ISNULL(@Suffix, NULL) END,
                CASE WHEN @PreferredName_Clear = 1 THEN NULL ELSE ISNULL(@PreferredName, NULL) END,
                CASE WHEN @Title_Clear = 1 THEN NULL ELSE ISNULL(@Title, NULL) END,
                CASE WHEN @Email_Clear = 1 THEN NULL ELSE ISNULL(@Email, NULL) END,
                CASE WHEN @Phone_Clear = 1 THEN NULL ELSE ISNULL(@Phone, NULL) END,
                CASE WHEN @DateOfBirth_Clear = 1 THEN NULL ELSE ISNULL(@DateOfBirth, NULL) END,
                CASE WHEN @Gender_Clear = 1 THEN NULL ELSE ISNULL(@Gender, NULL) END,
                CASE WHEN @PhotoURL_Clear = 1 THEN NULL ELSE ISNULL(@PhotoURL, NULL) END,
                CASE WHEN @Bio_Clear = 1 THEN NULL ELSE ISNULL(@Bio, NULL) END,
                CASE WHEN @LinkedUserID_Clear = 1 THEN NULL ELSE ISNULL(@LinkedUserID, NULL) END,
                ISNULL(@Status, 'Active'),
                CASE WHEN @SeniorityLevelID_Clear = 1 THEN NULL ELSE ISNULL(@SeniorityLevelID, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwPeople] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreatePerson] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreatePerson] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreatePerson] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: People */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreatePerson] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreatePerson] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreatePerson] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: People
-- Item: spUpdatePerson
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Person
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdatePerson]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdatePerson];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdatePerson]
    @ID uniqueidentifier,
    @FirstName nvarchar(100) = NULL,
    @LastName nvarchar(100) = NULL,
    @MiddleName_Clear bit = 0,
    @MiddleName nvarchar(100) = NULL,
    @Prefix_Clear bit = 0,
    @Prefix nvarchar(20) = NULL,
    @Suffix_Clear bit = 0,
    @Suffix nvarchar(20) = NULL,
    @PreferredName_Clear bit = 0,
    @PreferredName nvarchar(100) = NULL,
    @Title_Clear bit = 0,
    @Title nvarchar(200) = NULL,
    @Email_Clear bit = 0,
    @Email nvarchar(255) = NULL,
    @Phone_Clear bit = 0,
    @Phone nvarchar(50) = NULL,
    @DateOfBirth_Clear bit = 0,
    @DateOfBirth date = NULL,
    @Gender_Clear bit = 0,
    @Gender nvarchar(50) = NULL,
    @PhotoURL_Clear bit = 0,
    @PhotoURL nvarchar(1000) = NULL,
    @Bio_Clear bit = 0,
    @Bio nvarchar(MAX) = NULL,
    @LinkedUserID_Clear bit = 0,
    @LinkedUserID uniqueidentifier = NULL,
    @Status nvarchar(50) = NULL,
    @SeniorityLevelID_Clear bit = 0,
    @SeniorityLevelID uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Person]
    SET
        [FirstName] = ISNULL(@FirstName, [FirstName]),
        [LastName] = ISNULL(@LastName, [LastName]),
        [MiddleName] = CASE WHEN @MiddleName_Clear = 1 THEN NULL ELSE ISNULL(@MiddleName, [MiddleName]) END,
        [Prefix] = CASE WHEN @Prefix_Clear = 1 THEN NULL ELSE ISNULL(@Prefix, [Prefix]) END,
        [Suffix] = CASE WHEN @Suffix_Clear = 1 THEN NULL ELSE ISNULL(@Suffix, [Suffix]) END,
        [PreferredName] = CASE WHEN @PreferredName_Clear = 1 THEN NULL ELSE ISNULL(@PreferredName, [PreferredName]) END,
        [Title] = CASE WHEN @Title_Clear = 1 THEN NULL ELSE ISNULL(@Title, [Title]) END,
        [Email] = CASE WHEN @Email_Clear = 1 THEN NULL ELSE ISNULL(@Email, [Email]) END,
        [Phone] = CASE WHEN @Phone_Clear = 1 THEN NULL ELSE ISNULL(@Phone, [Phone]) END,
        [DateOfBirth] = CASE WHEN @DateOfBirth_Clear = 1 THEN NULL ELSE ISNULL(@DateOfBirth, [DateOfBirth]) END,
        [Gender] = CASE WHEN @Gender_Clear = 1 THEN NULL ELSE ISNULL(@Gender, [Gender]) END,
        [PhotoURL] = CASE WHEN @PhotoURL_Clear = 1 THEN NULL ELSE ISNULL(@PhotoURL, [PhotoURL]) END,
        [Bio] = CASE WHEN @Bio_Clear = 1 THEN NULL ELSE ISNULL(@Bio, [Bio]) END,
        [LinkedUserID] = CASE WHEN @LinkedUserID_Clear = 1 THEN NULL ELSE ISNULL(@LinkedUserID, [LinkedUserID]) END,
        [Status] = ISNULL(@Status, [Status]),
        [SeniorityLevelID] = CASE WHEN @SeniorityLevelID_Clear = 1 THEN NULL ELSE ISNULL(@SeniorityLevelID, [SeniorityLevelID]) END
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwPeople] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwPeople]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdatePerson] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdatePerson] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdatePerson] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Person table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdatePerson]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdatePerson];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdatePerson
ON [${flyway:defaultSchema}].[Person]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Person]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[Person] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: People */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdatePerson] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdatePerson] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdatePerson] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: People
-- Item: spDeletePerson
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Person
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeletePerson]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeletePerson];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeletePerson]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[Person]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spDeletePerson] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeletePerson] TO [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: People */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spDeletePerson] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeletePerson] TO [cdp_Integration];

/* SQL text to update entity field related entity name field map for entity field ID 439BDB57-0951-443D-A70A-B35ECF982A21 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='439BDB57-0951-443D-A70A-B35ECF982A21', @RelatedEntityNameFieldMap='JobFunction';
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
    @SeniorityLevelID uniqueidentifier = NULL
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
                [SeniorityLevelID]
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
                CASE WHEN @SeniorityLevelID_Clear = 1 THEN NULL ELSE ISNULL(@SeniorityLevelID, NULL) END
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
                [SeniorityLevelID]
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
                CASE WHEN @SeniorityLevelID_Clear = 1 THEN NULL ELSE ISNULL(@SeniorityLevelID, NULL) END
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
    @SeniorityLevelID uniqueidentifier = NULL
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
        [SeniorityLevelID] = CASE WHEN @SeniorityLevelID_Clear = 1 THEN NULL ELSE ISNULL(@SeniorityLevelID, [SeniorityLevelID]) END
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


---------------------------------------------------------------------------
-- 7. EntityField registrations for Person and Relationship extensions
-- Evaluates Sequence at apply time.
-- Asserts end state and throws if drift detected.
---------------------------------------------------------------------------
DECLARE @PersonEntityID UNIQUEIDENTIFIER;
SELECT @PersonEntityID = [ID]
  FROM [${mjSchema}].[Entity]
 WHERE [SchemaName] = '${flyway:defaultSchema}' AND [BaseTable] = 'Person';

DECLARE @RelationshipEntityID UNIQUEIDENTIFIER;
SELECT @RelationshipEntityID = [ID]
  FROM [${mjSchema}].[Entity]
 WHERE [SchemaName] = '${flyway:defaultSchema}' AND [BaseTable] = 'Relationship';

DECLARE @SeniorityLevelEntityID UNIQUEIDENTIFIER;
SELECT @SeniorityLevelEntityID = [ID]
  FROM [${mjSchema}].[Entity]
 WHERE [SchemaName] = '${flyway:defaultSchema}' AND [BaseTable] = 'SeniorityLevel';

DECLARE @JobFunctionEntityID UNIQUEIDENTIFIER;
SELECT @JobFunctionEntityID = [ID]
  FROM [${mjSchema}].[Entity]
 WHERE [SchemaName] = '${flyway:defaultSchema}' AND [BaseTable] = 'JobFunction';

-- 1. Person: SeniorityLevelID (physical FK)
IF @PersonEntityID IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM [${mjSchema}].[EntityField]
     WHERE [EntityID] = @PersonEntityID AND [Name] = 'SeniorityLevelID'
)
BEGIN
    INSERT INTO [${mjSchema}].[EntityField] (
        [ID], [EntityID], [Sequence], [Name], [DisplayName],
        [Description], [Type], [Length], [Precision], [Scale],
        [AllowsNull], [DefaultValue], [AutoIncrement], [AllowUpdateAPI],
        [IsVirtual], [IsComputed], [RelatedEntityID], [RelatedEntityFieldName],
        [IsNameField], [IncludeInUserSearchAPI], [IncludeRelatedEntityNameFieldInBaseView],
        [DefaultInView], [IsPrimaryKey], [IsUnique], [RelatedEntityDisplayType],
        [__mj_CreatedAt], [__mj_UpdatedAt]
    ) VALUES (
        'eb506b92-343c-434d-b21f-12cfecda3d3b',
        @PersonEntityID,
        (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = @PersonEntityID),
        'SeniorityLevelID', 'Seniority Level',
        'Current primary seniority level for this person.', 'uniqueidentifier', 16, 0, 0,
        1, NULL, 0, 1,
        0, 0, @SeniorityLevelEntityID, 'ID',
        0, 0, 1,
        0, 0, 0, 'Search',
        GETUTCDATE(), GETUTCDATE()
    );
END

-- 2. Person: PrimaryJobFunctionID (virtual FK)
IF @PersonEntityID IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM [${mjSchema}].[EntityField]
     WHERE [EntityID] = @PersonEntityID AND [Name] = 'PrimaryJobFunctionID'
)
BEGIN
    INSERT INTO [${mjSchema}].[EntityField] (
        [ID], [EntityID], [Sequence], [Name], [DisplayName],
        [Description], [Type], [Length], [Precision], [Scale],
        [AllowsNull], [DefaultValue], [AutoIncrement], [AllowUpdateAPI],
        [IsVirtual], [IsComputed], [RelatedEntityID], [RelatedEntityFieldName],
        [IsNameField], [IncludeInUserSearchAPI], [IncludeRelatedEntityNameFieldInBaseView],
        [DefaultInView], [IsPrimaryKey], [IsUnique], [RelatedEntityDisplayType],
        [__mj_CreatedAt], [__mj_UpdatedAt]
    ) VALUES (
        'ccf5585c-4e68-4a91-927c-ee932ffb7db0',
        @PersonEntityID,
        (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = @PersonEntityID),
        'PrimaryJobFunctionID', 'Primary Job Function',
        'Primary job function for this person derived from lowest sequence PersonJobFunction.', 'uniqueidentifier', 16, 0, 0,
        1, NULL, 0, 0,
        1, 0, NULL, NULL,
        0, 0, 0,
        0, 0, 0, 'Search',
        GETUTCDATE(), GETUTCDATE()
    );
END

-- 3. Person: PrimaryJobFunction (virtual nvarchar)
IF @PersonEntityID IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM [${mjSchema}].[EntityField]
     WHERE [EntityID] = @PersonEntityID AND [Name] = 'PrimaryJobFunction'
)
BEGIN
    INSERT INTO [${mjSchema}].[EntityField] (
        [ID], [EntityID], [Sequence], [Name], [DisplayName],
        [Description], [Type], [Length], [Precision], [Scale],
        [AllowsNull], [DefaultValue], [AutoIncrement], [AllowUpdateAPI],
        [IsVirtual], [IsComputed], [RelatedEntityID], [RelatedEntityFieldName],
        [IsNameField], [IncludeInUserSearchAPI], [IncludeRelatedEntityNameFieldInBaseView],
        [DefaultInView], [IsPrimaryKey], [IsUnique], [RelatedEntityDisplayType],
        [__mj_CreatedAt], [__mj_UpdatedAt]
    ) VALUES (
        '904393bd-8eea-4d69-b7e4-596958ece934',
        @PersonEntityID,
        (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = @PersonEntityID),
        'PrimaryJobFunction', 'Primary Job Function Name',
        'Primary job function name for this person derived from lowest sequence PersonJobFunction.', 'nvarchar', 200, 0, 0,
        1, NULL, 0, 0,
        1, 0, NULL, NULL,
        0, 0, 0,
        0, 0, 0, 'Search',
        GETUTCDATE(), GETUTCDATE()
    );
END

-- 4. Relationship: JobFunctionID (physical FK)
IF @RelationshipEntityID IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM [${mjSchema}].[EntityField]
     WHERE [EntityID] = @RelationshipEntityID AND [Name] = 'JobFunctionID'
)
BEGIN
    INSERT INTO [${mjSchema}].[EntityField] (
        [ID], [EntityID], [Sequence], [Name], [DisplayName],
        [Description], [Type], [Length], [Precision], [Scale],
        [AllowsNull], [DefaultValue], [AutoIncrement], [AllowUpdateAPI],
        [IsVirtual], [IsComputed], [RelatedEntityID], [RelatedEntityFieldName],
        [IsNameField], [IncludeInUserSearchAPI], [IncludeRelatedEntityNameFieldInBaseView],
        [DefaultInView], [IsPrimaryKey], [IsUnique], [RelatedEntityDisplayType],
        [__mj_CreatedAt], [__mj_UpdatedAt]
    ) VALUES (
        '0e353b64-06ba-4582-8532-5db427b539ee',
        @RelationshipEntityID,
        (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = @RelationshipEntityID),
        'JobFunctionID', 'Job Function',
        'Company-specific job function for this relationship/employment link.', 'uniqueidentifier', 16, 0, 0,
        1, NULL, 0, 1,
        0, 0, @JobFunctionEntityID, 'ID',
        0, 0, 1,
        0, 0, 0, 'Search',
        GETUTCDATE(), GETUTCDATE()
    );
END

-- 5. Relationship: SeniorityLevelID (physical FK)
IF @RelationshipEntityID IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM [${mjSchema}].[EntityField]
     WHERE [EntityID] = @RelationshipEntityID AND [Name] = 'SeniorityLevelID'
)
BEGIN
    INSERT INTO [${mjSchema}].[EntityField] (
        [ID], [EntityID], [Sequence], [Name], [DisplayName],
        [Description], [Type], [Length], [Precision], [Scale],
        [AllowsNull], [DefaultValue], [AutoIncrement], [AllowUpdateAPI],
        [IsVirtual], [IsComputed], [RelatedEntityID], [RelatedEntityFieldName],
        [IsNameField], [IncludeInUserSearchAPI], [IncludeRelatedEntityNameFieldInBaseView],
        [DefaultInView], [IsPrimaryKey], [IsUnique], [RelatedEntityDisplayType],
        [__mj_CreatedAt], [__mj_UpdatedAt]
    ) VALUES (
        '438bd1d0-764f-4d90-a51f-24c150cb8313',
        @RelationshipEntityID,
        (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = @RelationshipEntityID),
        'SeniorityLevelID', 'Seniority Level',
        'Company-specific seniority level for this relationship/employment link.', 'uniqueidentifier', 16, 0, 0,
        1, NULL, 0, 1,
        0, 0, @SeniorityLevelEntityID, 'ID',
        0, 0, 1,
        0, 0, 0, 'Search',
        GETUTCDATE(), GETUTCDATE()
    );
END

-- Assert no missing EntityFields for Person or Relationship
IF EXISTS (
    SELECT 1
      FROM [${mjSchema}].[Entity] e
      JOIN INFORMATION_SCHEMA.COLUMNS c
        ON c.TABLE_SCHEMA = e.SchemaName AND c.TABLE_NAME = e.BaseView
      LEFT JOIN [${mjSchema}].[EntityField] ef
        ON ef.EntityID = e.ID AND ef.Name = c.COLUMN_NAME
     WHERE e.SchemaName = '${flyway:defaultSchema}'
       AND e.BaseTable IN ('Person', 'Relationship')
       AND ef.ID IS NULL
)
BEGIN
    THROW 50001, 'EntityField drift detected on Person or Relationship after migration', 1;
END
GO

