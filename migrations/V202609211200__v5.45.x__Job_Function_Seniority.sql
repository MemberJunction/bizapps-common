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
