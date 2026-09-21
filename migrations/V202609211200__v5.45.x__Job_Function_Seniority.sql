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
        pjf.[Sequence] ASC
) AS primary_jf;
GO

---------------------------------------------------------------------------
-- Extended Properties
---------------------------------------------------------------------------
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Business job functions (Engineering, Marketing, Sales, etc.) for categorizing roles and career paths.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'JobFunction';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Career seniority levels carrying rank order (IC, Manager, Director, VP, C-Level) for skill and scope classification.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'SeniorityLevel';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'1:M assignment of job functions to a person, supporting plural functions and ranking order.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'PersonJobFunction';
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
-- EntityField registrations for Person and Relationship extensions
-- Resolves entities by natural key (SchemaName + BaseTable).
-- Guards inserts on natural key (EntityID + Name).
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

