-- =============================================================================
-- Migration: V202611211215__v5.69.x__Person_Supervisor_Reporting_Chain.sql
-- Description: Add People.SupervisorPersonID (nullable self-referential FK to
--              Person.ID with index), create cycle-safe recursive reporting view
--              vwPersonReportingChain (PersonID, SupervisorPersonID, Depth), and
--              create SyncEmployeesToPeople stored procedure to atomically sync
--              SupervisorPersonID and dated 'Reports To' Relationship rows.
-- =============================================================================

ALTER TABLE [${flyway:defaultSchema}].[Person]
    ADD [SupervisorPersonID] UNIQUEIDENTIFIER NULL;
GO

ALTER TABLE [${flyway:defaultSchema}].[Person]
    ADD CONSTRAINT [FK_Person_SupervisorPerson]
        FOREIGN KEY ([SupervisorPersonID]) REFERENCES [${flyway:defaultSchema}].[Person]([ID]);
GO

CREATE NONCLUSTERED INDEX [IDX_AUTO_MJ_FKEY_Person_SupervisorPersonID]
    ON [${flyway:defaultSchema}].[Person] ([SupervisorPersonID]);
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Optional self-referential foreign key to the Person record who directly supervises this person.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE', @level1name = N'Person',
    @level2type = N'COLUMN', @level2name = N'SupervisorPersonID';
GO

-- -----------------------------------------------------------------------------
-- Recursive reporting chain view: (PersonID, SupervisorPersonID, Depth)
-- Depth = 1 is direct supervisor, Depth = 2 is skip-level supervisor, etc.
-- Path tracking (VisitedPath) + Depth < 100 prevent infinite recursion if cyclic
-- supervisor data ever exists in the table.
-- -----------------------------------------------------------------------------
CREATE OR ALTER VIEW [${flyway:defaultSchema}].[vwPersonReportingChain]
AS
WITH [ReportingChain] AS (
    SELECT
        p.[ID] AS [PersonID],
        p.[SupervisorPersonID] AS [SupervisorPersonID],
        1 AS [Depth],
        CAST(
            '/' + LOWER(CAST(p.[ID] AS NVARCHAR(36))) + '/' + LOWER(CAST(p.[SupervisorPersonID] AS NVARCHAR(36))) + '/'
            AS NVARCHAR(MAX)
        ) AS [VisitedPath]
    FROM
        [${flyway:defaultSchema}].[Person] AS p
    WHERE
        p.[SupervisorPersonID] IS NOT NULL
        AND p.[SupervisorPersonID] <> p.[ID]

    UNION ALL

    SELECT
        rc.[PersonID] AS [PersonID],
        sup.[SupervisorPersonID] AS [SupervisorPersonID],
        rc.[Depth] + 1 AS [Depth],
        CAST(
            rc.[VisitedPath] + LOWER(CAST(sup.[SupervisorPersonID] AS NVARCHAR(36))) + '/'
            AS NVARCHAR(MAX)
        ) AS [VisitedPath]
    FROM
        [ReportingChain] AS rc
    INNER JOIN
        [${flyway:defaultSchema}].[Person] AS sup
        ON sup.[ID] = rc.[SupervisorPersonID]
    WHERE
        sup.[SupervisorPersonID] IS NOT NULL
        AND CHARINDEX('/' + LOWER(CAST(sup.[SupervisorPersonID] AS NVARCHAR(36))) + '/', rc.[VisitedPath]) = 0
        AND rc.[Depth] < 100
)
SELECT
    [PersonID],
    [SupervisorPersonID],
    [Depth]
FROM
    [ReportingChain];
GO

GRANT SELECT ON [${flyway:defaultSchema}].[vwPersonReportingChain] TO [cdp_UI], [cdp_Developer], [cdp_Integration];
GO

-- -----------------------------------------------------------------------------
-- SyncEmployeesToPeople
-- Atomically synchronizes __mj.Employee records to __mj_BizAppsCommon.Person,
-- populates/updates Person.SupervisorPersonID from Employee.SupervisorID, and
-- maintains dated 'Reports To' Relationship rows (ending outdated active rows
-- and inserting new active rows).
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [${flyway:defaultSchema}].[SyncEmployeesToPeople]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @StartedTransaction BIT = 0;
    IF @@TRANCOUNT = 0
    BEGIN
        BEGIN TRANSACTION;
        SET @StartedTransaction = 1;
    END

    BEGIN TRY
        DECLARE @SyncDate DATE = CAST(GETUTCDATE() AS DATE);
        DECLARE @ReportsToTypeID UNIQUEIDENTIFIER;
        DECLARE @PeopleEntityID UNIQUEIDENTIFIER;

        SELECT TOP 1 @PeopleEntityID = e.[ID]
        FROM [${mjSchema}].[Entity] AS e
        WHERE e.[Name] = N'MJ_BizApps_Common: People';

        SELECT TOP 1 @ReportsToTypeID = rt.[ID]
        FROM [${flyway:defaultSchema}].[RelationshipType] AS rt
        WHERE LOWER(LTRIM(RTRIM(rt.[Name]))) = N'reports to';

        IF @ReportsToTypeID IS NULL
        BEGIN
            SET @ReportsToTypeID = 'F1449971-6488-49E3-8F5B-823EB3E8CB11';
            INSERT INTO [${flyway:defaultSchema}].[RelationshipType] (
                [ID],
                [Name],
                [Description],
                [Category],
                [IsDirectional],
                [ForwardLabel],
                [ReverseLabel],
                [IsActive]
            )
            VALUES (
                @ReportsToTypeID,
                N'Reports To',
                N'Direct reporting line between a person and their supervisor',
                N'PersonToPerson',
                1,
                N'reports to',
                N'supervises',
                1
            );
        END

        -- Resolve each Employee row to a matching Person (via User link or Email)
        DECLARE @EmployeeMatch TABLE (
            [EmployeeID] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
            [SupervisorEmployeeID] UNIQUEIDENTIFIER NULL,
            [FirstName] NVARCHAR(100) NOT NULL,
            [LastName] NVARCHAR(100) NOT NULL,
            [Title] NVARCHAR(200) NULL,
            [Email] NVARCHAR(255) NULL,
            [Phone] NVARCHAR(50) NULL,
            [Active] BIT NOT NULL,
            [PersonID] UNIQUEIDENTIFIER NULL,
            [LinkedUserID] UNIQUEIDENTIFIER NULL
        );

        INSERT INTO @EmployeeMatch (
            [EmployeeID],
            [SupervisorEmployeeID],
            [FirstName],
            [LastName],
            [Title],
            [Email],
            [Phone],
            [Active],
            [PersonID],
            [LinkedUserID]
        )
        SELECT
            emp.[ID],
            emp.[SupervisorID],
            emp.[FirstName],
            emp.[LastName],
            emp.[Title],
            NULLIF(LTRIM(RTRIM(emp.[Email])), N''),
            NULLIF(LTRIM(RTRIM(emp.[Phone])), N''),
            emp.[Active],
            COALESCE(userLinkedPerson.[ID], userDirectPerson.[ID], emailPerson.[ID]),
            matchedUser.[ID]
        FROM [${mjSchema}].[Employee] AS emp
        OUTER APPLY (
            SELECT TOP 1
                u.[ID],
                TRY_CAST(u.[LinkedEntityRecordID] AS UNIQUEIDENTIFIER) AS [LinkedPersonID],
                u.[LinkedEntityID]
            FROM [${mjSchema}].[User] AS u
            WHERE u.[EmployeeID] = emp.[ID]
            ORDER BY u.[IsActive] DESC, u.[__mj_CreatedAt] ASC
        ) AS matchedUser
        OUTER APPLY (
            SELECT TOP 1 p.[ID]
            FROM [${flyway:defaultSchema}].[Person] AS p
            WHERE matchedUser.[LinkedPersonID] IS NOT NULL
              AND p.[ID] = matchedUser.[LinkedPersonID]
              AND (
                  @PeopleEntityID IS NULL
                  OR matchedUser.[LinkedEntityID] = @PeopleEntityID
                  OR EXISTS (
                      SELECT 1
                      FROM [${mjSchema}].[Entity] AS subE
                      WHERE subE.[ID] = matchedUser.[LinkedEntityID]
                        AND subE.[ParentID] = @PeopleEntityID
                  )
              )
        ) AS userLinkedPerson
        OUTER APPLY (
            SELECT TOP 1 p.[ID]
            FROM [${flyway:defaultSchema}].[Person] AS p
            WHERE matchedUser.[ID] IS NOT NULL
              AND p.[LinkedUserID] = matchedUser.[ID]
        ) AS userDirectPerson
        OUTER APPLY (
            SELECT TOP 1 p.[ID]
            FROM [${flyway:defaultSchema}].[Person] AS p
            WHERE NULLIF(LTRIM(RTRIM(emp.[Email])), N'') IS NOT NULL
              AND LOWER(LTRIM(RTRIM(p.[Email]))) = LOWER(LTRIM(RTRIM(emp.[Email])))
            ORDER BY
                CASE WHEN p.[Status] = N'Active' THEN 0 ELSE 1 END,
                p.[__mj_CreatedAt] ASC
        ) AS emailPerson;

        -- Insert Person records for active employees that do not yet have a Person
        DECLARE @NewPeople TABLE (
            [EmployeeID] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
            [PersonID] UNIQUEIDENTIFIER NOT NULL
        );

        INSERT INTO @NewPeople ([EmployeeID], [PersonID])
        SELECT
            m.[EmployeeID],
            NEWID()
        FROM @EmployeeMatch AS m
        WHERE m.[PersonID] IS NULL
          AND m.[Active] = 1;

        INSERT INTO [${flyway:defaultSchema}].[Person] (
            [ID],
            [FirstName],
            [LastName],
            [Title],
            [Email],
            [Phone],
            [LinkedUserID],
            [Status]
        )
        SELECT
            np.[PersonID],
            m.[FirstName],
            m.[LastName],
            m.[Title],
            m.[Email],
            m.[Phone],
            CASE
                WHEN m.[LinkedUserID] IS NOT NULL
                     AND NOT EXISTS (
                         SELECT 1
                         FROM [${flyway:defaultSchema}].[Person] AS existingByUser
                         WHERE existingByUser.[LinkedUserID] = m.[LinkedUserID]
                     )
                THEN m.[LinkedUserID]
                ELSE NULL
            END,
            N'Active'
        FROM @EmployeeMatch AS m
        INNER JOIN @NewPeople AS np
            ON np.[EmployeeID] = m.[EmployeeID];

        UPDATE m
        SET m.[PersonID] = np.[PersonID]
        FROM @EmployeeMatch AS m
        INNER JOIN @NewPeople AS np
            ON np.[EmployeeID] = m.[EmployeeID];

        -- Deduplicate by PersonID and resolve each Person's TargetSupervisorPersonID
        DECLARE @PersonSupervisorSync TABLE (
            [PersonID] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
            [TargetSupervisorPersonID] UNIQUEIDENTIFIER NULL
        );

        ;WITH [RankedEmployeePerPerson] AS (
            SELECT
                m.[PersonID],
                CASE
                    WHEN sup.[PersonID] IS NOT NULL AND sup.[PersonID] <> m.[PersonID]
                        THEN sup.[PersonID]
                    ELSE NULL
                END AS [TargetSupervisorPersonID],
                ROW_NUMBER() OVER (
                    PARTITION BY m.[PersonID]
                    ORDER BY m.[Active] DESC, m.[EmployeeID] ASC
                ) AS [RowNum]
            FROM @EmployeeMatch AS m
            LEFT OUTER JOIN @EmployeeMatch AS sup
                ON sup.[EmployeeID] = m.[SupervisorEmployeeID]
            WHERE m.[PersonID] IS NOT NULL
        )
        INSERT INTO @PersonSupervisorSync ([PersonID], [TargetSupervisorPersonID])
        SELECT
            r.[PersonID],
            r.[TargetSupervisorPersonID]
        FROM [RankedEmployeePerPerson] AS r
        WHERE r.[RowNum] = 1;

        -- Update Person.SupervisorPersonID wherever it differs from the employee hierarchy
        UPDATE p
        SET p.[SupervisorPersonID] = s.[TargetSupervisorPersonID]
        FROM [${flyway:defaultSchema}].[Person] AS p
        INNER JOIN @PersonSupervisorSync AS s
            ON s.[PersonID] = p.[ID]
        WHERE (p.[SupervisorPersonID] IS NULL AND s.[TargetSupervisorPersonID] IS NOT NULL)
           OR (p.[SupervisorPersonID] IS NOT NULL AND s.[TargetSupervisorPersonID] IS NULL)
           OR (p.[SupervisorPersonID] <> s.[TargetSupervisorPersonID]);

        -- Close out outdated active 'Reports To' relationships for synced people
        UPDATE r
        SET r.[Status] = N'Ended',
            r.[EndDate] = COALESCE(r.[EndDate], @SyncDate)
        FROM [${flyway:defaultSchema}].[Relationship] AS r
        INNER JOIN @PersonSupervisorSync AS s
            ON s.[PersonID] = r.[FromPersonID]
        WHERE r.[RelationshipTypeID] = @ReportsToTypeID
          AND r.[Status] = N'Active'
          AND (
              s.[TargetSupervisorPersonID] IS NULL
              OR r.[ToPersonID] IS NULL
              OR r.[ToPersonID] <> s.[TargetSupervisorPersonID]
          );

        -- Insert new active 'Reports To' relationships when missing
        INSERT INTO [${flyway:defaultSchema}].[Relationship] (
            [ID],
            [RelationshipTypeID],
            [FromPersonID],
            [FromOrganizationID],
            [ToPersonID],
            [ToOrganizationID],
            [StartDate],
            [EndDate],
            [Status],
            [Notes]
        )
        SELECT
            NEWID(),
            @ReportsToTypeID,
            s.[PersonID],
            NULL,
            s.[TargetSupervisorPersonID],
            NULL,
            @SyncDate,
            NULL,
            N'Active',
            N'Synced from MJ: Employees supervisor hierarchy'
        FROM @PersonSupervisorSync AS s
        WHERE s.[TargetSupervisorPersonID] IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM [${flyway:defaultSchema}].[Relationship] AS r
              WHERE r.[RelationshipTypeID] = @ReportsToTypeID
                AND r.[FromPersonID] = s.[PersonID]
                AND r.[ToPersonID] = s.[TargetSupervisorPersonID]
                AND r.[Status] = N'Active'
          );

        IF @StartedTransaction = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @StartedTransaction = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        ELSE IF @@TRANCOUNT > 0 AND XACT_STATE() = -1
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[SyncEmployeesToPeople] TO [cdp_Developer], [cdp_Integration];
GO






















































-- =============================================================================
-- GENERATED BY MemberJunction CodeGen — DO NOT EDIT BY HAND
-- =============================================================================

/* SQL text to insert 1 new entity field(s) */

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'd327403d-481d-4c07-9d8d-0c6628578b61' OR (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'SupervisorPersonID')) BEGIN
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
            'd327403d-481d-4c07-9d8d-0c6628578b61',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ_BizApps_Common: People
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'),
            'SupervisorPersonID',
            'Supervisor',
            'Optional self-referential foreign key to the Person record who directly supervises this person.',
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
GO

/* Create Entity Relationship: MJ_BizApps_Common: People -> MJ_BizApps_Common: People (One To Many via SupervisorPersonID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '7e1cc753-8dc8-4583-98cc-d464615ef304' OR ([EntityID] = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND [RelatedEntityID] = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND [RelatedEntityJoinField] = 'SupervisorPersonID')
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('7e1cc753-8dc8-4583-98cc-d464615ef304', '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', 'SupervisorPersonID', 'One To Many', 1, 1, (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityRelationship] WHERE [EntityID] = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'), GETUTCDATE(), GETUTCDATE())
   END;
GO

/* SQL text to update entity field related entity name field map for entity field ID D327403D-481D-4C07-9D8D-0C6628578B61 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='D327403D-481D-4C07-9D8D-0C6628578B61', @RelatedEntityNameFieldMap='SupervisorPerson';
GO

/* Base View SQL for MJ_BizApps_Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: People
-- Item: vwPeopleGenerated
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: People
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  Person
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwPeopleGenerated]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwPeopleGenerated];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwPeopleGenerated]
AS
SELECT
    p.*,
    MJUser_LinkedUserID.[Name] AS [LinkedUser],
    mjBizAppsCommonSeniorityLevel_SeniorityLevelID.[Name] AS [SeniorityLevel],
    mjBizAppsCommonPerson_SupervisorPersonID.[DisplayName] AS [SupervisorPerson]
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
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Person] AS mjBizAppsCommonPerson_SupervisorPersonID
  ON
    [p].[SupervisorPersonID] = mjBizAppsCommonPerson_SupervisorPersonID.[ID]
GO
IF OBJECT_ID('[${flyway:defaultSchema}].[vwPeople]', 'V') IS NOT NULL
BEGIN
    EXEC sp_executesql N'REVOKE SELECT ON [${flyway:defaultSchema}].[vwPeople] FROM [cdp_Developer]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwPeople] FROM [cdp_Integration]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwPeople] FROM [cdp_UI]
GRANT SELECT ON [${flyway:defaultSchema}].[vwPeople] TO [cdp_UI], [cdp_Developer], [cdp_Integration]';
END;

/* Refresh layered base view for MJ_BizApps_Common: People after its inner view changed */
EXEC sp_refreshview '${flyway:defaultSchema}.vwPeopleGenerated';
IF OBJECT_ID('[${flyway:defaultSchema}].[vwPeople]', 'V') IS NOT NULL
BEGIN
    EXEC sp_executesql N'EXEC sp_refreshview ''${flyway:defaultSchema}.vwPeople'';';
END
GO

/* Base View Permissions SQL for MJ_BizApps_Common: People */
IF OBJECT_ID('[${flyway:defaultSchema}].[vwPeople]', 'V') IS NOT NULL
BEGIN
    EXEC sp_executesql N'REVOKE SELECT ON [${flyway:defaultSchema}].[vwPeople] FROM [cdp_Developer]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwPeople] FROM [cdp_Integration]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwPeople] FROM [cdp_UI]
GRANT SELECT ON [${flyway:defaultSchema}].[vwPeople] TO [cdp_UI], [cdp_Developer], [cdp_Integration]';
END;
GO

/* spCreate SQL for MJ_BizApps_Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: People
-- Item: spCreatePerson
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
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
    @PhotoURL nvarchar(MAX) = NULL,
    @Bio_Clear bit = 0,
    @Bio nvarchar(MAX) = NULL,
    @LinkedUserID_Clear bit = 0,
    @LinkedUserID uniqueidentifier = NULL,
    @Status nvarchar(50) = NULL,
    @SeniorityLevelID_Clear bit = 0,
    @SeniorityLevelID uniqueidentifier = NULL,
    @SupervisorPersonID_Clear bit = 0,
    @SupervisorPersonID uniqueidentifier = NULL
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
                [SeniorityLevelID],
                [SupervisorPersonID]
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
                CASE WHEN @SeniorityLevelID_Clear = 1 THEN NULL ELSE ISNULL(@SeniorityLevelID, NULL) END,
                CASE WHEN @SupervisorPersonID_Clear = 1 THEN NULL ELSE ISNULL(@SupervisorPersonID, NULL) END
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
                [SeniorityLevelID],
                [SupervisorPersonID]
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
                CASE WHEN @SeniorityLevelID_Clear = 1 THEN NULL ELSE ISNULL(@SeniorityLevelID, NULL) END,
                CASE WHEN @SupervisorPersonID_Clear = 1 THEN NULL ELSE ISNULL(@SupervisorPersonID, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwPeople] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreatePerson] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreatePerson] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreatePerson] TO [cdp_Developer], [cdp_Integration];
GO

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
    @PhotoURL nvarchar(MAX) = NULL,
    @Bio_Clear bit = 0,
    @Bio nvarchar(MAX) = NULL,
    @LinkedUserID_Clear bit = 0,
    @LinkedUserID uniqueidentifier = NULL,
    @Status nvarchar(50) = NULL,
    @SeniorityLevelID_Clear bit = 0,
    @SeniorityLevelID uniqueidentifier = NULL,
    @SupervisorPersonID_Clear bit = 0,
    @SupervisorPersonID uniqueidentifier = NULL
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
        [SeniorityLevelID] = CASE WHEN @SeniorityLevelID_Clear = 1 THEN NULL ELSE ISNULL(@SeniorityLevelID, [SeniorityLevelID]) END,
        [SupervisorPersonID] = CASE WHEN @SupervisorPersonID_Clear = 1 THEN NULL ELSE ISNULL(@SupervisorPersonID, [SupervisorPersonID]) END,
        [__mj_UpdatedAt] = GETUTCDATE()
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

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdatePerson] TO [cdp_Developer], [cdp_Integration];
GO

/* SQL text to insert 1 new virtual entity field(s) */

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '915fd715-b7e6-429a-928f-2421706467f5' OR (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'SupervisorPerson')) BEGIN
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
            '915fd715-b7e6-429a-928f-2421706467f5',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ_BizApps_Common: People
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'),
            'SupervisorPerson',
            'Supervisor Name',
            NULL,
            'nvarchar',
            250,
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
GO

-- UPDATE Entity Field Category Info MJ_BizApps_Common: People.SupervisorPersonID
UPDATE [${mjSchema}].[EntityField]
SET
   Category = 'Professional and Profile',
   GeneratedFormSection = 'Category',
   DisplayName = 'Supervisor'
WHERE
   ID = 'D327403D-481D-4C07-9D8D-0C6628578B61';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: People.SupervisorPerson
UPDATE [${mjSchema}].[EntityField]
SET
   Category = 'Professional and Profile',
   GeneratedFormSection = 'Category',
   DisplayName = 'Supervisor Name'
WHERE
   ID = '915FD715-B7E6-429A-928F-2421706467F5';
GO

-- ---- People field permissions: MJ snapshot rule on this host's permissions ----
-- 7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F is MJ_BizApps_Common: People.
;WITH RoleVerbs AS (
    SELECT ep.RoleID,
           MAX(CASE WHEN ISNULL(LTRIM(RTRIM(ep.[Type])), N'Allow') <> N'Deny' AND ep.CanRead   = 1 THEN 1 ELSE 0 END) AS AllowRead,
           MAX(CASE WHEN ISNULL(LTRIM(RTRIM(ep.[Type])), N'Allow') <> N'Deny' AND ep.CanUpdate = 1 THEN 1 ELSE 0 END) AS AllowUpdate,
           MAX(CASE WHEN ISNULL(LTRIM(RTRIM(ep.[Type])), N'Allow') <> N'Deny' AND ep.CanCreate = 1 THEN 1 ELSE 0 END) AS AllowCreate,
           MAX(CASE WHEN ISNULL(LTRIM(RTRIM(ep.[Type])), N'Allow') =  N'Deny' AND ep.CanRead   = 1 THEN 1 ELSE 0 END) AS DenyRead,
           MAX(CASE WHEN ISNULL(LTRIM(RTRIM(ep.[Type])), N'Allow') =  N'Deny' AND ep.CanUpdate = 1 THEN 1 ELSE 0 END) AS DenyUpdate,
           MAX(CASE WHEN ISNULL(LTRIM(RTRIM(ep.[Type])), N'Allow') =  N'Deny' AND ep.CanCreate = 1 THEN 1 ELSE 0 END) AS DenyCreate
    FROM [${mjSchema}].[EntityPermission] ep
    WHERE ep.EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'
    GROUP BY ep.RoleID
),
RoleAccess AS (
    SELECT RoleID,
           CASE WHEN AllowUpdate = 1 AND DenyUpdate = 0 THEN 1 ELSE 0 END AS RoleCanUpdate,
           CASE WHEN AllowCreate = 1 AND DenyCreate = 0 THEN 1 ELSE 0 END AS RoleCanCreate
    FROM RoleVerbs
    WHERE AllowRead = 1 AND DenyRead = 0
)
INSERT INTO [${mjSchema}].[EntityFieldPermission] (EntityFieldID, RoleID, ReadAccess, UpdateAccess, CreateAccess)
SELECT ef.ID,
       ra.RoleID,
       N'Allow',
       CASE WHEN ef.AllowUpdateAPI = 1 AND ra.RoleCanUpdate = 1 THEN N'Allow' ELSE N'No Access' END,
       CASE WHEN ef.AllowUpdateAPI = 1 AND ra.RoleCanCreate = 1 THEN N'Allow' ELSE N'No Access' END
FROM [${mjSchema}].[EntityField] ef
CROSS JOIN RoleAccess ra
WHERE ef.EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'
  AND ef.IsPrimaryKey = 0
  AND ef.IsSoftPrimaryKey = 0
  AND LEFT(ef.Name, 5) <> N'__mj_'
  AND NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityFieldPermission] x
      WHERE x.EntityFieldID = ef.ID AND x.RoleID = ra.RoleID
  );
GO
