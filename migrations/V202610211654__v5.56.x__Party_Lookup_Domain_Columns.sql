-- =============================================================================
-- Migration: V202610211654__v5.56.x__Party_Lookup_Domain_Columns.sql
-- Description: Add two PERSISTED, indexed computed columns for the party lookup
--              (bizapps-party-field): Person.EmailDomain and Organization.WebsiteDomain.
--
-- WHY. Pickers on Deal, Order and Contract forms must find a person by email domain
-- ("aqha.com") and an organization by website ("acme.com") in under a second. Matching
-- the raw columns needs a leading wildcard (Email LIKE '%@aqha.com', Website LIKE
-- '%acme.com%'), which scans: 1.9 s and 28 s on Stage (1.29M people, 448K organizations).
-- A stored, indexed domain turns both into a prefix seek.
--
-- Person.EmailDomain: the lower-cased text after the first '@' of Email. NULL when Email
-- is NULL, has no '@', or has nothing after it ("bob@").
--
-- Organization.WebsiteDomain: Website trimmed and lower-cased, then
--   1. the scheme (http:// or https://) and a leading "www." are skipped: Start is the
--      position after them;
--   2. the host runs from Start to the first '/' after it (or the end).
-- "HTTPS://WWW.Acme.com/about" -> "acme.com". A port stays ("acme.com:8080"); a query
-- string with no path stays too. NULL when Website is NULL or nothing is left.
-- The picker normalizes a typed URL the same way (party-lookup-term.ts websiteDomainOf).
--
-- Both are CAST to NVARCHAR(255) (510 bytes) so they fit an index key. Every function used
-- is deterministic, which PERSISTED and the index require.
--
-- POSTGRESQL. Release work. Both expressions use only IMMUTABLE functions (lower, btrim,
-- position/strpos, substr), so GENERATED ALWAYS AS (...) STORED works there.
-- =============================================================================
IF COL_LENGTH('[${flyway:defaultSchema}].[Person]', 'EmailDomain') IS NULL
    ALTER TABLE [${flyway:defaultSchema}].[Person]
        ADD [EmailDomain] AS (
            CAST(
                CASE WHEN CHARINDEX(N'@', [Email]) > 0
                     THEN NULLIF(LOWER(TRIM(SUBSTRING([Email], CHARINDEX(N'@', [Email]) + 1, 255))), N'')
                END
                AS NVARCHAR(255))
        ) PERSISTED;
GO
IF COL_LENGTH('[${flyway:defaultSchema}].[Organization]', 'WebsiteDomain') IS NULL
    ALTER TABLE [${flyway:defaultSchema}].[Organization]
        ADD [WebsiteDomain] AS (
            -- LEFT(Host, CHARINDEX('/', Host + '/') - 1), where Host = SUBSTRING(x, Start, 1000):
            -- Host is written out twice because a computed column cannot name a sub-expression.
            CAST(
                NULLIF(
                    LEFT(
                        SUBSTRING(LOWER(TRIM([Website])),
                            CASE WHEN LOWER(TRIM([Website])) LIKE N'https://www.%' THEN 13
                                 WHEN LOWER(TRIM([Website])) LIKE N'http://www.%'  THEN 12
                                 WHEN LOWER(TRIM([Website])) LIKE N'https://%'     THEN 9
                                 WHEN LOWER(TRIM([Website])) LIKE N'http://%'      THEN 8
                                 WHEN LOWER(TRIM([Website])) LIKE N'www.%'         THEN 5
                                 ELSE 1 END, 1000),
                        CHARINDEX(N'/', SUBSTRING(LOWER(TRIM([Website])),
                            CASE WHEN LOWER(TRIM([Website])) LIKE N'https://www.%' THEN 13
                                 WHEN LOWER(TRIM([Website])) LIKE N'http://www.%'  THEN 12
                                 WHEN LOWER(TRIM([Website])) LIKE N'https://%'     THEN 9
                                 WHEN LOWER(TRIM([Website])) LIKE N'http://%'      THEN 8
                                 WHEN LOWER(TRIM([Website])) LIKE N'www.%'         THEN 5
                                 ELSE 1 END, 1000) + N'/') - 1),
                    N'')
                AS NVARCHAR(255))
        ) PERSISTED;
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Person_EmailDomain'
      AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Person]')
)
    CREATE INDEX [IX_Person_EmailDomain]
        ON [${flyway:defaultSchema}].[Person] ([EmailDomain]);
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Organization_WebsiteDomain'
      AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Organization]')
)
    CREATE INDEX [IX_Organization_WebsiteDomain]
        ON [${flyway:defaultSchema}].[Organization] ([WebsiteDomain]);
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description',
        N'SCHEMA', N'${flyway:defaultSchema}', N'TABLE', N'Person', N'COLUMN', N'EmailDomain')
)
    EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Lower-cased domain of Email: the text after the first @. NULL when Email is empty, has no @, or has nothing after it. Computed and stored, indexed for prefix search by domain.',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'EmailDomain';
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description',
        N'SCHEMA', N'${flyway:defaultSchema}', N'TABLE', N'Organization', N'COLUMN', N'WebsiteDomain')
)
    EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Lower-cased host of Website, without the http(s):// scheme, a leading www. or any path. NULL when Website is empty. Computed and stored, indexed for prefix search by domain.',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}', @level1type = N'TABLE', @level1name = N'Organization', @level2type = N'COLUMN', @level2name = N'WebsiteDomain';
GO


















































/* ============================================================================================
   ==== CODEGEN OUTPUT — DO NOT EDIT BELOW THIS LINE ====
   Generated by the MemberJunction CodeGen tool: published @memberjunction/cli 6.1.6 (this repo's
   floor), includeSchemas ['__mj_BizAppsCommon'], against a database built from migrations alone
   (MJ core v6.1.6, then this repo's chain at origin/next, then the DDL above).
   Contains: the Person.EmailDomain and Organization.WebsiteDomain EntityField inserts, and the
   regenerated vwPeopleGenerated / vwOrganizationsGenerated, Person and Organization CRUD procs,
   Organization hierarchy TVFs and FK indexes that regenerate with them.
   No AI pass: field descriptions come from MS_Description above, and the form sections for the two
   fields are pinned in metadata/entity-fields/.form-layout.json (they reach hosts in the release seed).
   Do NOT edit by hand. If the hand-written SQL above changes, re-run CodeGen and replace this
   whole section.
   ============================================================================================ */
/* SQL text to insert 2 new entity field(s) */

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'b132dcac-4f9f-4e98-9116-be13afd0e71a' OR (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'WebsiteDomain')) BEGIN
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
            'b132dcac-4f9f-4e98-9116-be13afd0e71a',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ_BizApps_Common: Organizations
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'C70448F9-9792-41D7-A82C-784B66429D54'),
            'WebsiteDomain',
            'Website Domain',
            'Lower-cased host of Website, without the http(s):// scheme, a leading www. or any path. NULL when Website is empty. Computed and stored, indexed for prefix search by domain.',
            'nvarchar',
            510,
            0,
            0,
            1,
            NULL,
            0,
            0,
            1,
            1,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '5f79a492-3538-46d5-8047-ff545f674b58' OR (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'EmailDomain')) BEGIN
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
            '5f79a492-3538-46d5-8047-ff545f674b58',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ_BizApps_Common: People
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'),
            'EmailDomain',
            'Email Domain',
            'Lower-cased domain of Email: the text after the first @. NULL when Email is empty, has no @, or has nothing after it. Computed and stored, indexed for prefix search by domain.',
            'nvarchar',
            510,
            0,
            0,
            1,
            NULL,
            0,
            0,
            1,
            1,
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

/* Index for Foreign Keys for Organization */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
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
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Organization]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Organization_OrganizationTypeID ON [${flyway:defaultSchema}].[Organization] ([OrganizationTypeID]);

-- Index for foreign key ParentID in table Organization
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Organization_ParentID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Organization]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Organization_ParentID ON [${flyway:defaultSchema}].[Organization] ([ParentID]);

/* Index for Foreign Keys for Person */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: People
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
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Person]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Person_LinkedUserID ON [${flyway:defaultSchema}].[Person] ([LinkedUserID]);

-- Index for foreign key SeniorityLevelID in table Person
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Person_SeniorityLevelID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Person]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Person_SeniorityLevelID ON [${flyway:defaultSchema}].[Person] ([SeniorityLevelID]);

/* Hierarchy Metadata Function SQL for MJ_BizApps_Common: Organizations.ParentID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: fnOrganizationParentID_GetHierarchyMeta
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- HIERARCHY METADATA FUNCTION FOR: [Organization].[ParentID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnOrganizationParentID_GetHierarchyMeta]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnOrganizationParentID_GetHierarchyMeta];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnOrganizationParentID_GetHierarchyMeta]
(
    @RecordID uniqueidentifier,
    @ParentID uniqueidentifier
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_Ancestors AS (
        SELECT
            [ID],
            [ParentID],
            0 AS [Depth],
            CAST('/' + CAST([ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Organization]
        WHERE
            [ID] = @RecordID

        UNION ALL

        SELECT
            p.[ID],
            p.[ParentID],
            c.[Depth] + 1 AS [Depth],
            CAST('/' + CAST(p.[ID] AS NVARCHAR(36)) + c.[Path] AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Organization] p
        INNER JOIN
            CTE_Ancestors c ON p.[ID] = c.[ParentID]
        WHERE
            c.[Depth] < 100
    )
    SELECT TOP 1
        a.[ID] AS [RootID],
        (SELECT MAX([Depth]) FROM CTE_Ancestors) AS [Depth],
        (SELECT TOP 1 [Path] FROM CTE_Ancestors ORDER BY [Depth] DESC) AS [Path],
        CAST(CASE WHEN EXISTS (SELECT 1 FROM [${flyway:defaultSchema}].[Organization] WHERE [ParentID] = @RecordID) THEN 0 ELSE 1 END AS BIT) AS [IsLeaf],
        (SELECT COUNT(1) FROM [${flyway:defaultSchema}].[Organization] WHERE [ParentID] = @RecordID) AS [ChildCount]
    FROM
        CTE_Ancestors a
    WHERE
        a.[ParentID] IS NULL OR @ParentID IS NULL
    ORDER BY
        a.[Depth] DESC
);
GO

/* Descendants Traversal Function SQL for MJ_BizApps_Common: Organizations.ParentID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: fnOrganizationParentID_GetDescendants
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- DESCENDANTS FUNCTION FOR: [Organization].[ParentID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnOrganizationParentID_GetDescendants]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnOrganizationParentID_GetDescendants];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnOrganizationParentID_GetDescendants]
(
    @RootID uniqueidentifier,
    @MaxDepth INT = NULL
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_Descendants AS (
        SELECT
            [ID],
            [ParentID],
            0 AS [RelativeDepth],
            CAST('/' + CAST([ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Organization]
        WHERE
            [ID] = @RootID

        UNION ALL

        SELECT
            c.[ID],
            c.[ParentID],
            p.[RelativeDepth] + 1 AS [RelativeDepth],
            CAST(p.[Path] + CAST(c.[ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Organization] c
        INNER JOIN
            CTE_Descendants p ON c.[ParentID] = p.[ID]
        WHERE
            (@MaxDepth IS NULL OR p.[RelativeDepth] < @MaxDepth)
            AND p.[RelativeDepth] < 100
    )
    SELECT
        d.[ID] AS [ID],
        d.[RelativeDepth] AS [Depth],
        d.[Path],
        CAST(CASE WHEN EXISTS (SELECT 1 FROM [${flyway:defaultSchema}].[Organization] WHERE [ParentID] = d.[ID]) THEN 0 ELSE 1 END AS BIT) AS [IsLeaf],
        (SELECT COUNT(1) FROM [${flyway:defaultSchema}].[Organization] WHERE [ParentID] = d.[ID]) AS [ChildCount]
    FROM
        CTE_Descendants d
);
GO

/* Ancestors Traversal Function SQL for MJ_BizApps_Common: Organizations.ParentID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: fnOrganizationParentID_GetAncestors
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- ANCESTORS FUNCTION FOR: [Organization].[ParentID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnOrganizationParentID_GetAncestors]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnOrganizationParentID_GetAncestors];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnOrganizationParentID_GetAncestors]
(
    @RecordID uniqueidentifier
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_Ancestors AS (
        SELECT
            [ID],
            [ParentID],
            0 AS [LevelUp],
            CAST('/' + CAST([ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Organization]
        WHERE
            [ID] = @RecordID

        UNION ALL

        SELECT
            p.[ID],
            p.[ParentID],
            c.[LevelUp] + 1 AS [LevelUp],
            CAST('/' + CAST(p.[ID] AS NVARCHAR(36)) + c.[Path] AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Organization] p
        INNER JOIN
            CTE_Ancestors c ON p.[ID] = c.[ParentID]
        WHERE
            c.[LevelUp] < 100
    )
    SELECT
        a.[ID] AS [ID],
        a.[LevelUp],
        a.[Path]
    FROM
        CTE_Ancestors a
);
GO

/* Root ID Function SQL for MJ_BizApps_Common: Organizations.ParentID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: fnOrganizationParentID_GetRootID
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- ROOT ID FUNCTION FOR: [Organization].[ParentID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnOrganizationParentID_GetRootID]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnOrganizationParentID_GetRootID];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnOrganizationParentID_GetRootID]
(
    @RecordID uniqueidentifier,
    @ParentID uniqueidentifier
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_RootParent AS (
        SELECT
            [ID],
            [ParentID],
            [ID] AS [RootParentID],
            0 AS [Depth]
        FROM
            [${flyway:defaultSchema}].[Organization]
        WHERE
            [ID] = COALESCE(@ParentID, @RecordID)

        UNION ALL

        SELECT
            c.[ID],
            c.[ParentID],
            c.[ID] AS [RootParentID],
            p.[Depth] + 1 AS [Depth]
        FROM
            [${flyway:defaultSchema}].[Organization] c
        INNER JOIN
            CTE_RootParent p ON c.[ID] = p.[ParentID]
        WHERE
            p.[Depth] < 100
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

/* Base View SQL for MJ_BizApps_Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: vwOrganizationsGenerated
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Organizations
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  Organization
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwOrganizationsGenerated]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwOrganizationsGenerated];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwOrganizationsGenerated]
AS
SELECT
    o.*,
    mjBizAppsCommonOrganizationType_OrganizationTypeID.[Name] AS [OrganizationType],
    mjBizAppsCommonOrganization_ParentID.[Name] AS [Parent],
    hier_ParentID.RootID AS [RootParentID],
    hier_ParentID.Depth AS [ParentIDDepth],
    hier_ParentID.Path AS [ParentIDPath],
    hier_ParentID.IsLeaf AS [ParentIDIsLeaf],
    hier_ParentID.ChildCount AS [ParentIDChildCount]
FROM
    [${flyway:defaultSchema}].[Organization] AS o
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[OrganizationType] AS mjBizAppsCommonOrganizationType_OrganizationTypeID
  ON
    [o].[OrganizationTypeID] = mjBizAppsCommonOrganizationType_OrganizationTypeID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Organization] AS mjBizAppsCommonOrganization_ParentID
  ON
    [o].[ParentID] = mjBizAppsCommonOrganization_ParentID.[ID]
OUTER APPLY
    [${flyway:defaultSchema}].[fnOrganizationParentID_GetHierarchyMeta]([o].[ID], [o].[ParentID]) AS hier_ParentID
GO
IF OBJECT_ID('[${flyway:defaultSchema}].[vwOrganizations]', 'V') IS NOT NULL
BEGIN
    EXEC sp_executesql N'REVOKE SELECT ON [${flyway:defaultSchema}].[vwOrganizations] FROM [cdp_Developer]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwOrganizations] FROM [cdp_Integration]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwOrganizations] FROM [cdp_UI]
GRANT SELECT ON [${flyway:defaultSchema}].[vwOrganizations] TO [cdp_UI], [cdp_Developer], [cdp_Integration]';
END;

/* Base View Permissions SQL for MJ_BizApps_Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: Permissions for vwOrganizations
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

IF OBJECT_ID('[${flyway:defaultSchema}].[vwOrganizations]', 'V') IS NOT NULL
BEGIN
    EXEC sp_executesql N'REVOKE SELECT ON [${flyway:defaultSchema}].[vwOrganizations] FROM [cdp_Developer]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwOrganizations] FROM [cdp_Integration]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwOrganizations] FROM [cdp_UI]
GRANT SELECT ON [${flyway:defaultSchema}].[vwOrganizations] TO [cdp_UI], [cdp_Developer], [cdp_Integration]';
END;

/* spCreate SQL for MJ_BizApps_Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: spCreateOrganization
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Organization
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateOrganization]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateOrganization];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateOrganization]
    @ID uniqueidentifier = NULL,
    @Name nvarchar(255),
    @LegalName_Clear bit = 0,
    @LegalName nvarchar(255) = NULL,
    @OrganizationTypeID_Clear bit = 0,
    @OrganizationTypeID uniqueidentifier = NULL,
    @ParentID_Clear bit = 0,
    @ParentID uniqueidentifier = NULL,
    @Website_Clear bit = 0,
    @Website nvarchar(1000) = NULL,
    @LogoURL_Clear bit = 0,
    @LogoURL nvarchar(MAX) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Email_Clear bit = 0,
    @Email nvarchar(255) = NULL,
    @Phone_Clear bit = 0,
    @Phone nvarchar(50) = NULL,
    @FoundedDate_Clear bit = 0,
    @FoundedDate date = NULL,
    @TaxID_Clear bit = 0,
    @TaxID nvarchar(50) = NULL,
    @Status nvarchar(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[Organization]
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
                CASE WHEN @LegalName_Clear = 1 THEN NULL ELSE ISNULL(@LegalName, NULL) END,
                CASE WHEN @OrganizationTypeID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationTypeID, NULL) END,
                CASE WHEN @ParentID_Clear = 1 THEN NULL ELSE ISNULL(@ParentID, NULL) END,
                CASE WHEN @Website_Clear = 1 THEN NULL ELSE ISNULL(@Website, NULL) END,
                CASE WHEN @LogoURL_Clear = 1 THEN NULL ELSE ISNULL(@LogoURL, NULL) END,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                CASE WHEN @Email_Clear = 1 THEN NULL ELSE ISNULL(@Email, NULL) END,
                CASE WHEN @Phone_Clear = 1 THEN NULL ELSE ISNULL(@Phone, NULL) END,
                CASE WHEN @FoundedDate_Clear = 1 THEN NULL ELSE ISNULL(@FoundedDate, NULL) END,
                CASE WHEN @TaxID_Clear = 1 THEN NULL ELSE ISNULL(@TaxID, NULL) END,
                ISNULL(@Status, 'Active')
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[Organization]
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
                CASE WHEN @LegalName_Clear = 1 THEN NULL ELSE ISNULL(@LegalName, NULL) END,
                CASE WHEN @OrganizationTypeID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationTypeID, NULL) END,
                CASE WHEN @ParentID_Clear = 1 THEN NULL ELSE ISNULL(@ParentID, NULL) END,
                CASE WHEN @Website_Clear = 1 THEN NULL ELSE ISNULL(@Website, NULL) END,
                CASE WHEN @LogoURL_Clear = 1 THEN NULL ELSE ISNULL(@LogoURL, NULL) END,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                CASE WHEN @Email_Clear = 1 THEN NULL ELSE ISNULL(@Email, NULL) END,
                CASE WHEN @Phone_Clear = 1 THEN NULL ELSE ISNULL(@Phone, NULL) END,
                CASE WHEN @FoundedDate_Clear = 1 THEN NULL ELSE ISNULL(@FoundedDate, NULL) END,
                CASE WHEN @TaxID_Clear = 1 THEN NULL ELSE ISNULL(@TaxID, NULL) END,
                ISNULL(@Status, 'Active')
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwOrganizations] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateOrganization] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateOrganization] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateOrganization] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Organizations */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateOrganization] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateOrganization] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateOrganization] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: spUpdateOrganization
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Organization
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateOrganization]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateOrganization];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateOrganization]
    @ID uniqueidentifier,
    @Name nvarchar(255) = NULL,
    @LegalName_Clear bit = 0,
    @LegalName nvarchar(255) = NULL,
    @OrganizationTypeID_Clear bit = 0,
    @OrganizationTypeID uniqueidentifier = NULL,
    @ParentID_Clear bit = 0,
    @ParentID uniqueidentifier = NULL,
    @Website_Clear bit = 0,
    @Website nvarchar(1000) = NULL,
    @LogoURL_Clear bit = 0,
    @LogoURL nvarchar(MAX) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Email_Clear bit = 0,
    @Email nvarchar(255) = NULL,
    @Phone_Clear bit = 0,
    @Phone nvarchar(50) = NULL,
    @FoundedDate_Clear bit = 0,
    @FoundedDate date = NULL,
    @TaxID_Clear bit = 0,
    @TaxID nvarchar(50) = NULL,
    @Status nvarchar(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Organization]
    SET
        [Name] = ISNULL(@Name, [Name]),
        [LegalName] = CASE WHEN @LegalName_Clear = 1 THEN NULL ELSE ISNULL(@LegalName, [LegalName]) END,
        [OrganizationTypeID] = CASE WHEN @OrganizationTypeID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationTypeID, [OrganizationTypeID]) END,
        [ParentID] = CASE WHEN @ParentID_Clear = 1 THEN NULL ELSE ISNULL(@ParentID, [ParentID]) END,
        [Website] = CASE WHEN @Website_Clear = 1 THEN NULL ELSE ISNULL(@Website, [Website]) END,
        [LogoURL] = CASE WHEN @LogoURL_Clear = 1 THEN NULL ELSE ISNULL(@LogoURL, [LogoURL]) END,
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [Email] = CASE WHEN @Email_Clear = 1 THEN NULL ELSE ISNULL(@Email, [Email]) END,
        [Phone] = CASE WHEN @Phone_Clear = 1 THEN NULL ELSE ISNULL(@Phone, [Phone]) END,
        [FoundedDate] = CASE WHEN @FoundedDate_Clear = 1 THEN NULL ELSE ISNULL(@FoundedDate, [FoundedDate]) END,
        [TaxID] = CASE WHEN @TaxID_Clear = 1 THEN NULL ELSE ISNULL(@TaxID, [TaxID]) END,
        [Status] = ISNULL(@Status, [Status])
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwOrganizations] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwOrganizations]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateOrganization] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateOrganization] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateOrganization] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Organization table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateOrganization]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateOrganization];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateOrganization
ON [${flyway:defaultSchema}].[Organization]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Organization]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[Organization] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Organizations */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateOrganization] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateOrganization] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateOrganization] TO [cdp_Developer], [cdp_Integration];

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
    EXEC sp_executesql N'REVOKE SELECT ON [${flyway:defaultSchema}].[vwPeople] FROM [cdp_Developer]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwPeople] FROM [cdp_Integration]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwPeople] FROM [cdp_UI]
GRANT SELECT ON [${flyway:defaultSchema}].[vwPeople] TO [cdp_UI], [cdp_Developer], [cdp_Integration]';
END;

/* Base View Permissions SQL for MJ_BizApps_Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: People
-- Item: Permissions for vwPeople
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

IF OBJECT_ID('[${flyway:defaultSchema}].[vwPeople]', 'V') IS NOT NULL
BEGIN
    EXEC sp_executesql N'REVOKE SELECT ON [${flyway:defaultSchema}].[vwPeople] FROM [cdp_Developer]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwPeople] FROM [cdp_Integration]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwPeople] FROM [cdp_UI]
GRANT SELECT ON [${flyway:defaultSchema}].[vwPeople] TO [cdp_UI], [cdp_Developer], [cdp_Integration]';
END;

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
    @PhotoURL nvarchar(MAX) = NULL,
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

/* spDelete SQL for MJ_BizApps_Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: spDeleteOrganization
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Organization
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteOrganization]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteOrganization];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteOrganization]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[Organization]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spDeleteOrganization] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteOrganization] TO [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Organizations */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spDeleteOrganization] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteOrganization] TO [cdp_Integration];

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

/* Refresh custom base views for modified entities so schema changes are picked up */
EXEC sp_refreshview '${flyway:defaultSchema}.vwOrganizationsGenerated';
IF OBJECT_ID('[${flyway:defaultSchema}].[vwOrganizations]', 'V') IS NOT NULL
BEGIN
    EXEC sp_executesql N'EXEC sp_refreshview ''${flyway:defaultSchema}.vwOrganizations'';';
END

EXEC sp_refreshview '${flyway:defaultSchema}.vwPeopleGenerated';
IF OBJECT_ID('[${flyway:defaultSchema}].[vwPeople]', 'V') IS NOT NULL
BEGIN
    EXEC sp_executesql N'EXEC sp_refreshview ''${flyway:defaultSchema}.vwPeople'';';
END;

