-- =============================================================================
-- Migration: V202609051800__v5.39.x__Widen_PhotoURL_LogoURL.sql
-- Description: Widen Person.PhotoURL and Organization.LogoURL to NVARCHAR(MAX)
--              so inline illustrated avatars/logos fit (loom #12 WP1). Additive.
--              Hand-authored DDL only. Do NOT UPDATE EntityField here — CodeGen
--              reconciles Length from the column and regenerates CRUD procs.
--              After CodeGen, this file is completed as:
--                DDL → 50 blank lines → inlined R__RefreshMetadata → 50 blank
--                lines → CODEGEN banner → CodeGen SQL emit.
--              Authoring order: apply DDL, run CodeGen, THEN append R + emit.
--              Replay order: DDL, R (heal metadata), CodeGen emit (SPs).
-- =============================================================================

-- 1) Columns
IF COL_LENGTH('${flyway:defaultSchema}.Person', 'PhotoURL') IS NOT NULL
   AND COLUMNPROPERTY(OBJECT_ID('${flyway:defaultSchema}.Person'), 'PhotoURL', 'Precision') <> -1
BEGIN
    ALTER TABLE [${flyway:defaultSchema}].[Person] ALTER COLUMN [PhotoURL] NVARCHAR(MAX) NULL;
END
GO
IF COL_LENGTH('${flyway:defaultSchema}.Organization', 'LogoURL') IS NOT NULL
   AND COLUMNPROPERTY(OBJECT_ID('${flyway:defaultSchema}.Organization'), 'LogoURL', 'Precision') <> -1
BEGIN
    ALTER TABLE [${flyway:defaultSchema}].[Organization] ALTER COLUMN [LogoURL] NVARCHAR(MAX) NULL;
END
GO

-- 2) Extended properties (column docs; not EntityField rows)
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE major_id = OBJECT_ID('${flyway:defaultSchema}.Person') AND name = 'MS_Description' AND minor_id = COLUMNPROPERTY(OBJECT_ID('${flyway:defaultSchema}.Person'), 'PhotoURL', 'ColumnId'))
    EXEC sp_updateextendedproperty @name = N'MS_Description', @value = N'Profile photo or avatar. May be an HTTP(S) URL or an inline data URI (NVARCHAR(MAX)).',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'PhotoURL';
ELSE
    EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Profile photo or avatar. May be an HTTP(S) URL or an inline data URI (NVARCHAR(MAX)).',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'PhotoURL';
GO
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE major_id = OBJECT_ID('${flyway:defaultSchema}.Organization') AND name = 'MS_Description' AND minor_id = COLUMNPROPERTY(OBJECT_ID('${flyway:defaultSchema}.Organization'), 'LogoURL', 'ColumnId'))
    EXEC sp_updateextendedproperty @name = N'MS_Description', @value = N'Organization logo. May be an HTTP(S) URL or an inline data URI (NVARCHAR(MAX)).',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}', @level1type = N'TABLE', @level1name = N'Organization', @level2type = N'COLUMN', @level2name = N'LogoURL';
ELSE
    EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Organization logo. May be an HTTP(S) URL or an inline data URI (NVARCHAR(MAX)).',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}', @level1type = N'TABLE', @level1name = N'Organization', @level2type = N'COLUMN', @level2name = N'LogoURL';
GO


















































/* ==============================================================================================
   METADATA REFRESH — inlined copy of MJ/migrations/R__RefreshMetadata.sql
   (minus ${flyway:timestamp}, which exists only to churn the repeatable checksum).

   Why this is here: Flyway runs every versioned migration before any R__ script.
   The ALTER COLUMN above lands first. CodeGen (below) was authored against that
   DDL with EntityField.Length still at the old size so it regenerated Person/Org
   CRUD. On REPLAY, this refresh runs AFTER the ALTER and BEFORE the CodeGen emit
   so metadata (Length, views) matches what the emit assumes.

   EXEC target is ${mjSchema} (__mj) — these stored procedures live in MJ core, not
   this app schema. Verbatim R__ bodies minus timestamp; ${flyway:defaultSchema}
   in the original R file is MJ core, here replaced with ${mjSchema}.
   ============================================================================================== */

/* SQL text to recompile all views (dependency order: inner layered views before g.* wrappers) */
EXEC [${mjSchema}].spRecompileAllViews
GO

/* SQL text to update existing entities from schema */
EXEC [${mjSchema}].spUpdateExistingEntitiesFromSchema @ExcludedSchemaNames='sys,staging'
GO

/* SQL text to sync schema info from database schemas */
EXEC [${mjSchema}].spUpdateSchemaInfoFromDatabase @ExcludedSchemaNames='sys,staging'
GO

/* SQL text to delete unneeded entity fields */
EXEC [${mjSchema}].spDeleteUnneededEntityFields @ExcludedSchemaNames='sys,staging'
GO

/* SQL text to update existing entity fields from schema */
EXEC [${mjSchema}].spUpdateExistingEntityFieldsFromSchema @ExcludedSchemaNames='sys,staging'
GO

/* SQL text to set default column width where needed */
EXEC [${mjSchema}].spSetDefaultColumnWidthWhereNeeded @ExcludedSchemaNames='sys,staging'
GO

/* SQL text to recompile all stored procedures in dependency order */
EXEC [${mjSchema}].spRecompileAllProceduresInDependencyOrder @ExcludedSchemaNames='sys,staging', @LogOutput=0, @ContinueOnError=1
GO


















































/* ============================================================================================
   ==== CODEGEN OUTPUT — DO NOT EDIT BELOW THIS LINE ====
   Generated by local MJ CLI 6.1.0-edge.5 (`mj codegen --skipfiles`) with
   includeSchemas ['__mj_BizAppsCommon'] after the DDL above was applied and
   BEFORE this R refresh on authoring. Replay order: DDL, R, then this emit.
   Source: migrations/codegen/CodeGen_Run_2026-09-06_17-30-31.sql
   ============================================================================================ */

/* SQL text to update existing entities from schema */
EXEC [${mjSchema}].[spUpdateExistingEntitiesFromSchema] @ExcludedSchemaNames='', @IncludedSchemaNames='${flyway:defaultSchema}';

/* SQL text to insert 7 new entity field(s) */
UPDATE [${mjSchema}].[EntityField]
         SET [Sequence] = [Sequence] + 100000
       WHERE [EntityID] = 'AC16B066-9460-44F5-B027-3FD397E61F34'
         AND [Sequence] < 100000
         AND NOT EXISTS (
             SELECT 1 FROM [${mjSchema}].[EntityField]
              WHERE [EntityID] = 'AC16B066-9460-44F5-B027-3FD397E61F34'
                AND [Sequence] >= 100000
         );

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c976c194-d37c-41f0-9263-288091fe825c' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'ActivitySyncExclusion')) BEGIN
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
            'c976c194-d37c-41f0-9263-288091fe825c',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            19,
            'ActivitySyncExclusion',
            'Activity Sync Exclusion',
            NULL,
            'nvarchar',
            640,
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
UPDATE [${mjSchema}].[EntityField]
         SET [Sequence] = [Sequence] + 100000
       WHERE [EntityID] = 'C70448F9-9792-41D7-A82C-784B66429D54'
         AND [Sequence] < 100000
         AND NOT EXISTS (
             SELECT 1 FROM [${mjSchema}].[EntityField]
              WHERE [EntityID] = 'C70448F9-9792-41D7-A82C-784B66429D54'
                AND [Sequence] >= 100000
         );

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'e5527b14-513b-4f7c-b2a3-939a3180db51' OR (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'ParentIDDepth')) BEGIN
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
            'e5527b14-513b-4f7c-b2a3-939a3180db51',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ_BizApps_Common: Organizations
            21,
            'ParentIDDepth',
            'Parent ID Depth',
            NULL,
            'int',
            4,
            10,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'a67b9cda-102a-4236-8ccd-52d09864bf5e' OR (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'ParentIDPath')) BEGIN
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
            'a67b9cda-102a-4236-8ccd-52d09864bf5e',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ_BizApps_Common: Organizations
            22,
            'ParentIDPath',
            'Parent ID Path',
            NULL,
            'nvarchar',
            -1,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c16617d4-c82f-4617-9749-072902c36b2f' OR (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'ParentIDIsLeaf')) BEGIN
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
            'c16617d4-c82f-4617-9749-072902c36b2f',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ_BizApps_Common: Organizations
            23,
            'ParentIDIsLeaf',
            'Parent ID Is Leaf',
            NULL,
            'bit',
            1,
            1,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'cf502be5-5ecd-4a4b-9a5d-4099b369818a' OR (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'ParentIDChildCount')) BEGIN
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
            'cf502be5-5ecd-4a4b-9a5d-4099b369818a',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ_BizApps_Common: Organizations
            24,
            'ParentIDChildCount',
            'Parent ID Child Count',
            NULL,
            'int',
            4,
            10,
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

/* SQL text to update existing entity fields from schema */
EXEC [${mjSchema}].[spUpdateExistingEntityFieldsFromSchema] @ExcludedSchemaNames='', @IncludedSchemaNames='${flyway:defaultSchema}';

/* SQL text to set default column width where needed */
EXEC [${mjSchema}].[spSetDefaultColumnWidthWhereNeeded] @ExcludedSchemaNames='', @IncludedSchemaNames='${flyway:defaultSchema}';

/* SQL text to sync schema info from database schemas */
EXEC [${mjSchema}].[spUpdateSchemaInfoFromDatabase] @ExcludedSchemaNames='', @IncludedSchemaNames='${flyway:defaultSchema}';

/* SQL text to update entity field related entity name field map for entity field ID 7937A593-4D16-4E5B-AA61-DDF7EC7D6093 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='7937A593-4D16-4E5B-AA61-DDF7EC7D6093', @RelatedEntityNameFieldMap='Activity';

/* SQL text to update entity field related entity name field map for entity field ID 2263EC18-32FF-4E2C-A277-78FBECA31EA0 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='2263EC18-32FF-4E2C-A277-78FBECA31EA0', @RelatedEntityNameFieldMap='Activity';

/* Base View SQL for MJ_BizApps_Common: Activity Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Links
-- Item: vwActivityLinks
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Activity Links
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ActivityLink
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwActivityLinks]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwActivityLinks];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwActivityLinks]
AS
SELECT
    a.*,
    mjBizAppsCommonActivity_ActivityID.[Title] AS [Activity],
    MJEntity_EntityID.[Name] AS [Entity]
FROM
    [${flyway:defaultSchema}].[ActivityLink] AS a
INNER JOIN
    [${flyway:defaultSchema}].[Activity] AS mjBizAppsCommonActivity_ActivityID
  ON
    [a].[ActivityID] = mjBizAppsCommonActivity_ActivityID.[ID]
LEFT OUTER JOIN
    [${mjSchema}].[Entity] AS MJEntity_EntityID
  ON
    [a].[EntityID] = MJEntity_EntityID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwActivityLinks] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Activity Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Links
-- Item: Permissions for vwActivityLinks
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwActivityLinks] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Activity Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Links
-- Item: spCreateActivityLink
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ActivityLink
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateActivityLink]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateActivityLink];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateActivityLink]
    @ID uniqueidentifier = NULL,
    @ActivityID uniqueidentifier,
    @Role nvarchar(30),
    @EntityID_Clear bit = 0,
    @EntityID uniqueidentifier = NULL,
    @RecordID_Clear bit = 0,
    @RecordID nvarchar(450) = NULL,
    @IdentityKind_Clear bit = 0,
    @IdentityKind nvarchar(20) = NULL,
    @IdentityValue_Clear bit = 0,
    @IdentityValue nvarchar(320) = NULL,
    @Sequence int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ActivityLink]
            (
                [ID],
                [ActivityID],
                [Role],
                [EntityID],
                [RecordID],
                [IdentityKind],
                [IdentityValue],
                [Sequence]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @ActivityID,
                @Role,
                CASE WHEN @EntityID_Clear = 1 THEN NULL ELSE ISNULL(@EntityID, NULL) END,
                CASE WHEN @RecordID_Clear = 1 THEN NULL ELSE ISNULL(@RecordID, NULL) END,
                CASE WHEN @IdentityKind_Clear = 1 THEN NULL ELSE ISNULL(@IdentityKind, NULL) END,
                CASE WHEN @IdentityValue_Clear = 1 THEN NULL ELSE ISNULL(@IdentityValue, NULL) END,
                ISNULL(@Sequence, 0)
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ActivityLink]
            (
                [ActivityID],
                [Role],
                [EntityID],
                [RecordID],
                [IdentityKind],
                [IdentityValue],
                [Sequence]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ActivityID,
                @Role,
                CASE WHEN @EntityID_Clear = 1 THEN NULL ELSE ISNULL(@EntityID, NULL) END,
                CASE WHEN @RecordID_Clear = 1 THEN NULL ELSE ISNULL(@RecordID, NULL) END,
                CASE WHEN @IdentityKind_Clear = 1 THEN NULL ELSE ISNULL(@IdentityKind, NULL) END,
                CASE WHEN @IdentityValue_Clear = 1 THEN NULL ELSE ISNULL(@IdentityValue, NULL) END,
                ISNULL(@Sequence, 0)
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwActivityLinks] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivityLink] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Activity Links */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivityLink] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Activity Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Links
-- Item: spUpdateActivityLink
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ActivityLink
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivityLink]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivityLink];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivityLink]
    @ID uniqueidentifier,
    @ActivityID uniqueidentifier = NULL,
    @Role nvarchar(30) = NULL,
    @EntityID_Clear bit = 0,
    @EntityID uniqueidentifier = NULL,
    @RecordID_Clear bit = 0,
    @RecordID nvarchar(450) = NULL,
    @IdentityKind_Clear bit = 0,
    @IdentityKind nvarchar(20) = NULL,
    @IdentityValue_Clear bit = 0,
    @IdentityValue nvarchar(320) = NULL,
    @Sequence int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivityLink]
    SET
        [ActivityID] = ISNULL(@ActivityID, [ActivityID]),
        [Role] = ISNULL(@Role, [Role]),
        [EntityID] = CASE WHEN @EntityID_Clear = 1 THEN NULL ELSE ISNULL(@EntityID, [EntityID]) END,
        [RecordID] = CASE WHEN @RecordID_Clear = 1 THEN NULL ELSE ISNULL(@RecordID, [RecordID]) END,
        [IdentityKind] = CASE WHEN @IdentityKind_Clear = 1 THEN NULL ELSE ISNULL(@IdentityKind, [IdentityKind]) END,
        [IdentityValue] = CASE WHEN @IdentityValue_Clear = 1 THEN NULL ELSE ISNULL(@IdentityValue, [IdentityValue]) END,
        [Sequence] = ISNULL(@Sequence, [Sequence])
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivityLinks] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivityLinks]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivityLink] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ActivityLink table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivityLink]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivityLink];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivityLink
ON [${flyway:defaultSchema}].[ActivityLink]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivityLink]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ActivityLink] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Activity Links */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivityLink] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Activity Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Links
-- Item: spDeleteActivityLink
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ActivityLink
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteActivityLink]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteActivityLink];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteActivityLink]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ActivityLink]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivityLink] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Activity Links */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivityLink] TO [cdp_Developer], [cdp_Integration];

/* Base View SQL for MJ_BizApps_Common: Activity Files */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Files
-- Item: vwActivityFiles
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Activity Files
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ActivityFile
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwActivityFiles]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwActivityFiles];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwActivityFiles]
AS
SELECT
    a.*,
    mjBizAppsCommonActivity_ActivityID.[Title] AS [Activity],
    MJFile_FileID.[Name] AS [File]
FROM
    [${flyway:defaultSchema}].[ActivityFile] AS a
INNER JOIN
    [${flyway:defaultSchema}].[Activity] AS mjBizAppsCommonActivity_ActivityID
  ON
    [a].[ActivityID] = mjBizAppsCommonActivity_ActivityID.[ID]
INNER JOIN
    [${mjSchema}].[File] AS MJFile_FileID
  ON
    [a].[FileID] = MJFile_FileID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwActivityFiles] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Activity Files */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Files
-- Item: Permissions for vwActivityFiles
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwActivityFiles] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Activity Files */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Files
-- Item: spCreateActivityFile
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ActivityFile
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateActivityFile]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateActivityFile];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateActivityFile]
    @ID uniqueidentifier = NULL,
    @ActivityID uniqueidentifier,
    @FileID uniqueidentifier,
    @Kind nvarchar(20),
    @Sequence int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ActivityFile]
            (
                [ID],
                [ActivityID],
                [FileID],
                [Kind],
                [Sequence]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @ActivityID,
                @FileID,
                @Kind,
                ISNULL(@Sequence, 0)
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ActivityFile]
            (
                [ActivityID],
                [FileID],
                [Kind],
                [Sequence]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ActivityID,
                @FileID,
                @Kind,
                ISNULL(@Sequence, 0)
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwActivityFiles] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivityFile] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Activity Files */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivityFile] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Activity Files */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Files
-- Item: spUpdateActivityFile
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ActivityFile
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivityFile]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivityFile];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivityFile]
    @ID uniqueidentifier,
    @ActivityID uniqueidentifier = NULL,
    @FileID uniqueidentifier = NULL,
    @Kind nvarchar(20) = NULL,
    @Sequence int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivityFile]
    SET
        [ActivityID] = ISNULL(@ActivityID, [ActivityID]),
        [FileID] = ISNULL(@FileID, [FileID]),
        [Kind] = ISNULL(@Kind, [Kind]),
        [Sequence] = ISNULL(@Sequence, [Sequence])
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivityFiles] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivityFiles]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivityFile] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ActivityFile table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivityFile]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivityFile];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivityFile
ON [${flyway:defaultSchema}].[ActivityFile]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivityFile]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ActivityFile] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Activity Files */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivityFile] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Activity Files */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Files
-- Item: spDeleteActivityFile
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ActivityFile
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteActivityFile]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteActivityFile];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteActivityFile]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ActivityFile]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivityFile] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Activity Files */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivityFile] TO [cdp_Developer], [cdp_Integration];

/* Index for Foreign Keys for ActivitySyncRunDetail */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Run Details
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key ActivitySyncRunID in table ActivitySyncRunDetail
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_ActivitySyncRunID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncRunDetail]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_ActivitySyncRunID ON [${flyway:defaultSchema}].[ActivitySyncRunDetail] ([ActivitySyncRunID]);

-- Index for foreign key ActivitySyncRuleID in table ActivitySyncRunDetail
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_ActivitySyncRuleID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncRunDetail]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_ActivitySyncRuleID ON [${flyway:defaultSchema}].[ActivitySyncRunDetail] ([ActivitySyncRuleID]);

-- Index for foreign key ActivitySyncExclusionID in table ActivitySyncRunDetail
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_ActivitySyncExclusionID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncRunDetail]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_ActivitySyncExclusionID ON [${flyway:defaultSchema}].[ActivitySyncRunDetail] ([ActivitySyncExclusionID]);

-- Index for foreign key ActivityID in table ActivitySyncRunDetail
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_ActivityID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncRunDetail]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_ActivityID ON [${flyway:defaultSchema}].[ActivitySyncRunDetail] ([ActivityID]);

-- Index for foreign key EncryptionKeyID in table ActivitySyncRunDetail
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_EncryptionKeyID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncRunDetail]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_EncryptionKeyID ON [${flyway:defaultSchema}].[ActivitySyncRunDetail] ([EncryptionKeyID]);

/* Base View SQL for MJ_BizApps_Common: Activity Sync Run Details */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Run Details
-- Item: vwActivitySyncRunDetails
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Activity Sync Run Details
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ActivitySyncRunDetail
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwActivitySyncRunDetails]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwActivitySyncRunDetails];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwActivitySyncRunDetails]
AS
SELECT
    a.*,
    mjBizAppsCommonActivitySyncRule_ActivitySyncRuleID.[Name] AS [ActivitySyncRule],
    mjBizAppsCommonActivitySyncExclusion_ActivitySyncExclusionID.[IdentityValue] AS [ActivitySyncExclusion],
    mjBizAppsCommonActivity_ActivityID.[Title] AS [Activity],
    MJEncryptionKey_EncryptionKeyID.[Name] AS [EncryptionKey]
FROM
    [${flyway:defaultSchema}].[ActivitySyncRunDetail] AS a
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ActivitySyncRule] AS mjBizAppsCommonActivitySyncRule_ActivitySyncRuleID
  ON
    [a].[ActivitySyncRuleID] = mjBizAppsCommonActivitySyncRule_ActivitySyncRuleID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ActivitySyncExclusion] AS mjBizAppsCommonActivitySyncExclusion_ActivitySyncExclusionID
  ON
    [a].[ActivitySyncExclusionID] = mjBizAppsCommonActivitySyncExclusion_ActivitySyncExclusionID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Activity] AS mjBizAppsCommonActivity_ActivityID
  ON
    [a].[ActivityID] = mjBizAppsCommonActivity_ActivityID.[ID]
LEFT OUTER JOIN
    [${mjSchema}].[EncryptionKey] AS MJEncryptionKey_EncryptionKeyID
  ON
    [a].[EncryptionKeyID] = MJEncryptionKey_EncryptionKeyID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncRunDetails] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Activity Sync Run Details */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Run Details
-- Item: Permissions for vwActivitySyncRunDetails
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncRunDetails] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Activity Sync Run Details */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Run Details
-- Item: spCreateActivitySyncRunDetail
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ActivitySyncRunDetail
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateActivitySyncRunDetail]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncRunDetail];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncRunDetail]
    @ID uniqueidentifier = NULL,
    @ActivitySyncRunID uniqueidentifier,
    @ExternalID nvarchar(400),
    @ExternalThreadID_Clear bit = 0,
    @ExternalThreadID nvarchar(400) = NULL,
    @OccurredAt_Clear bit = 0,
    @OccurredAt datetimeoffset = NULL,
    @Decision nvarchar(20),
    @DecidedByStage_Clear bit = 0,
    @DecidedByStage nvarchar(100) = NULL,
    @ActivitySyncRuleID_Clear bit = 0,
    @ActivitySyncRuleID uniqueidentifier = NULL,
    @ActivitySyncExclusionID_Clear bit = 0,
    @ActivitySyncExclusionID uniqueidentifier = NULL,
    @Reason_Clear bit = 0,
    @Reason nvarchar(MAX) = NULL,
    @Confidence_Clear bit = 0,
    @Confidence decimal(5, 4) = NULL,
    @AIPromptRunID_Clear bit = 0,
    @AIPromptRunID uniqueidentifier = NULL,
    @ActivityID_Clear bit = 0,
    @ActivityID uniqueidentifier = NULL,
    @CapturedContent_Clear bit = 0,
    @CapturedContent nvarchar(MAX) = NULL,
    @EncryptionKeyID_Clear bit = 0,
    @EncryptionKeyID uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncRunDetail]
            (
                [ID],
                [ActivitySyncRunID],
                [ExternalID],
                [ExternalThreadID],
                [OccurredAt],
                [Decision],
                [DecidedByStage],
                [ActivitySyncRuleID],
                [ActivitySyncExclusionID],
                [Reason],
                [Confidence],
                [AIPromptRunID],
                [ActivityID],
                [CapturedContent],
                [EncryptionKeyID]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @ActivitySyncRunID,
                @ExternalID,
                CASE WHEN @ExternalThreadID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalThreadID, NULL) END,
                CASE WHEN @OccurredAt_Clear = 1 THEN NULL ELSE ISNULL(@OccurredAt, NULL) END,
                @Decision,
                CASE WHEN @DecidedByStage_Clear = 1 THEN NULL ELSE ISNULL(@DecidedByStage, NULL) END,
                CASE WHEN @ActivitySyncRuleID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncRuleID, NULL) END,
                CASE WHEN @ActivitySyncExclusionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncExclusionID, NULL) END,
                CASE WHEN @Reason_Clear = 1 THEN NULL ELSE ISNULL(@Reason, NULL) END,
                CASE WHEN @Confidence_Clear = 1 THEN NULL ELSE ISNULL(@Confidence, NULL) END,
                CASE WHEN @AIPromptRunID_Clear = 1 THEN NULL ELSE ISNULL(@AIPromptRunID, NULL) END,
                CASE WHEN @ActivityID_Clear = 1 THEN NULL ELSE ISNULL(@ActivityID, NULL) END,
                CASE WHEN @CapturedContent_Clear = 1 THEN NULL ELSE ISNULL(@CapturedContent, NULL) END,
                CASE WHEN @EncryptionKeyID_Clear = 1 THEN NULL ELSE ISNULL(@EncryptionKeyID, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncRunDetail]
            (
                [ActivitySyncRunID],
                [ExternalID],
                [ExternalThreadID],
                [OccurredAt],
                [Decision],
                [DecidedByStage],
                [ActivitySyncRuleID],
                [ActivitySyncExclusionID],
                [Reason],
                [Confidence],
                [AIPromptRunID],
                [ActivityID],
                [CapturedContent],
                [EncryptionKeyID]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ActivitySyncRunID,
                @ExternalID,
                CASE WHEN @ExternalThreadID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalThreadID, NULL) END,
                CASE WHEN @OccurredAt_Clear = 1 THEN NULL ELSE ISNULL(@OccurredAt, NULL) END,
                @Decision,
                CASE WHEN @DecidedByStage_Clear = 1 THEN NULL ELSE ISNULL(@DecidedByStage, NULL) END,
                CASE WHEN @ActivitySyncRuleID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncRuleID, NULL) END,
                CASE WHEN @ActivitySyncExclusionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncExclusionID, NULL) END,
                CASE WHEN @Reason_Clear = 1 THEN NULL ELSE ISNULL(@Reason, NULL) END,
                CASE WHEN @Confidence_Clear = 1 THEN NULL ELSE ISNULL(@Confidence, NULL) END,
                CASE WHEN @AIPromptRunID_Clear = 1 THEN NULL ELSE ISNULL(@AIPromptRunID, NULL) END,
                CASE WHEN @ActivityID_Clear = 1 THEN NULL ELSE ISNULL(@ActivityID, NULL) END,
                CASE WHEN @CapturedContent_Clear = 1 THEN NULL ELSE ISNULL(@CapturedContent, NULL) END,
                CASE WHEN @EncryptionKeyID_Clear = 1 THEN NULL ELSE ISNULL(@EncryptionKeyID, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwActivitySyncRunDetails] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRunDetail] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Activity Sync Run Details */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRunDetail] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Activity Sync Run Details */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Run Details
-- Item: spUpdateActivitySyncRunDetail
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ActivitySyncRunDetail
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivitySyncRunDetail]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncRunDetail];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncRunDetail]
    @ID uniqueidentifier,
    @ActivitySyncRunID uniqueidentifier = NULL,
    @ExternalID nvarchar(400) = NULL,
    @ExternalThreadID_Clear bit = 0,
    @ExternalThreadID nvarchar(400) = NULL,
    @OccurredAt_Clear bit = 0,
    @OccurredAt datetimeoffset = NULL,
    @Decision nvarchar(20) = NULL,
    @DecidedByStage_Clear bit = 0,
    @DecidedByStage nvarchar(100) = NULL,
    @ActivitySyncRuleID_Clear bit = 0,
    @ActivitySyncRuleID uniqueidentifier = NULL,
    @ActivitySyncExclusionID_Clear bit = 0,
    @ActivitySyncExclusionID uniqueidentifier = NULL,
    @Reason_Clear bit = 0,
    @Reason nvarchar(MAX) = NULL,
    @Confidence_Clear bit = 0,
    @Confidence decimal(5, 4) = NULL,
    @AIPromptRunID_Clear bit = 0,
    @AIPromptRunID uniqueidentifier = NULL,
    @ActivityID_Clear bit = 0,
    @ActivityID uniqueidentifier = NULL,
    @CapturedContent_Clear bit = 0,
    @CapturedContent nvarchar(MAX) = NULL,
    @EncryptionKeyID_Clear bit = 0,
    @EncryptionKeyID uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncRunDetail]
    SET
        [ActivitySyncRunID] = ISNULL(@ActivitySyncRunID, [ActivitySyncRunID]),
        [ExternalID] = ISNULL(@ExternalID, [ExternalID]),
        [ExternalThreadID] = CASE WHEN @ExternalThreadID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalThreadID, [ExternalThreadID]) END,
        [OccurredAt] = CASE WHEN @OccurredAt_Clear = 1 THEN NULL ELSE ISNULL(@OccurredAt, [OccurredAt]) END,
        [Decision] = ISNULL(@Decision, [Decision]),
        [DecidedByStage] = CASE WHEN @DecidedByStage_Clear = 1 THEN NULL ELSE ISNULL(@DecidedByStage, [DecidedByStage]) END,
        [ActivitySyncRuleID] = CASE WHEN @ActivitySyncRuleID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncRuleID, [ActivitySyncRuleID]) END,
        [ActivitySyncExclusionID] = CASE WHEN @ActivitySyncExclusionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncExclusionID, [ActivitySyncExclusionID]) END,
        [Reason] = CASE WHEN @Reason_Clear = 1 THEN NULL ELSE ISNULL(@Reason, [Reason]) END,
        [Confidence] = CASE WHEN @Confidence_Clear = 1 THEN NULL ELSE ISNULL(@Confidence, [Confidence]) END,
        [AIPromptRunID] = CASE WHEN @AIPromptRunID_Clear = 1 THEN NULL ELSE ISNULL(@AIPromptRunID, [AIPromptRunID]) END,
        [ActivityID] = CASE WHEN @ActivityID_Clear = 1 THEN NULL ELSE ISNULL(@ActivityID, [ActivityID]) END,
        [CapturedContent] = CASE WHEN @CapturedContent_Clear = 1 THEN NULL ELSE ISNULL(@CapturedContent, [CapturedContent]) END,
        [EncryptionKeyID] = CASE WHEN @EncryptionKeyID_Clear = 1 THEN NULL ELSE ISNULL(@EncryptionKeyID, [EncryptionKeyID]) END
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivitySyncRunDetails] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivitySyncRunDetails]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRunDetail] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ActivitySyncRunDetail table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivitySyncRunDetail]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivitySyncRunDetail];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivitySyncRunDetail
ON [${flyway:defaultSchema}].[ActivitySyncRunDetail]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncRunDetail]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ActivitySyncRunDetail] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Activity Sync Run Details */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRunDetail] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Activity Sync Run Details */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Run Details
-- Item: spDeleteActivitySyncRunDetail
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ActivitySyncRunDetail
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteActivitySyncRunDetail]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncRunDetail];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncRunDetail]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ActivitySyncRunDetail]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncRunDetail] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Activity Sync Run Details */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncRunDetail] TO [cdp_Developer], [cdp_Integration];

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
    ${mjSchema}_rgc.[Latitude] AS [${mjSchema}_Latitude],
    ${mjSchema}_rgc.[Longitude] AS [${mjSchema}_Longitude],
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
LEFT OUTER JOIN
    [${mjSchema}].[vwRecordGeoCodes] AS ${mjSchema}_rgc
  ON
    ${mjSchema}_rgc.[EntityID] = 'C70448F9-9792-41D7-A82C-784B66429D54'
    AND ${mjSchema}_rgc.[RecordID] = CAST([o].[ID] AS NVARCHAR(450))
    AND ${mjSchema}_rgc.[LocationType] = 'Primary'
OUTER APPLY
    [${flyway:defaultSchema}].[fnOrganizationParentID_GetHierarchyMeta]([o].[ID], [o].[ParentID]) AS hier_ParentID
GO
IF OBJECT_ID('[${flyway:defaultSchema}].[vwOrganizations]', 'V') IS NOT NULL
BEGIN
    EXEC sp_executesql N'GRANT SELECT ON [${flyway:defaultSchema}].[vwOrganizations] TO [cdp_UI], [cdp_Developer], [cdp_Integration]';
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
    EXEC sp_executesql N'GRANT SELECT ON [${flyway:defaultSchema}].[vwOrganizations] TO [cdp_UI], [cdp_Developer], [cdp_Integration]';
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
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateOrganization] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Organizations */

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
    ${mjSchema}_rgc.[Latitude] AS [${mjSchema}_Latitude],
    ${mjSchema}_rgc.[Longitude] AS [${mjSchema}_Longitude]
FROM
    [${flyway:defaultSchema}].[Person] AS p
LEFT OUTER JOIN
    [${mjSchema}].[User] AS MJUser_LinkedUserID
  ON
    [p].[LinkedUserID] = MJUser_LinkedUserID.[ID]
LEFT OUTER JOIN
    [${mjSchema}].[vwRecordGeoCodes] AS ${mjSchema}_rgc
  ON
    ${mjSchema}_rgc.[EntityID] = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'
    AND ${mjSchema}_rgc.[RecordID] = CAST([p].[ID] AS NVARCHAR(450))
    AND ${mjSchema}_rgc.[LocationType] = 'Primary'
GO
IF OBJECT_ID('[${flyway:defaultSchema}].[vwPeople]', 'V') IS NOT NULL
BEGIN
    EXEC sp_executesql N'GRANT SELECT ON [${flyway:defaultSchema}].[vwPeople] TO [cdp_UI], [cdp_Developer], [cdp_Integration]';
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
    EXEC sp_executesql N'GRANT SELECT ON [${flyway:defaultSchema}].[vwPeople] TO [cdp_UI], [cdp_Developer], [cdp_Integration]';
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
    @Status nvarchar(50) = NULL
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
                [Status]
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
                ISNULL(@Status, 'Active')
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
                [Status]
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
                ISNULL(@Status, 'Active')
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwPeople] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreatePerson] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: People */

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
    @Status nvarchar(50) = NULL
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
        [Status] = ISNULL(@Status, [Status])
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
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteOrganization] TO [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Organizations */

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
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeletePerson] TO [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: People */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeletePerson] TO [cdp_Integration];

/* SQL text to delete unneeded entity fields (3 scoped entities) */
EXEC [${mjSchema}].[spDeleteUnneededEntityFields] @ExcludedSchemaNames='', @EntityIDs='AC16B066-9460-44F5-B027-3FD397E61F34,C70448F9-9792-41D7-A82C-784B66429D54,7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', @IncludedSchemaNames='${flyway:defaultSchema}';

/* SQL text to update existing entity fields from schema (3 scoped entities) */
EXEC [${mjSchema}].[spUpdateExistingEntityFieldsFromSchema] @ExcludedSchemaNames='', @EntityIDs='AC16B066-9460-44F5-B027-3FD397E61F34,C70448F9-9792-41D7-A82C-784B66429D54,7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', @IncludedSchemaNames='${flyway:defaultSchema}';

/* SQL text to set default column width where needed */
EXEC [${mjSchema}].[spSetDefaultColumnWidthWhereNeeded] @ExcludedSchemaNames='', @IncludedSchemaNames='${flyway:defaultSchema}';

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '2C5F0735-BCCE-4FFE-A225-DF937DACE682'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '0904A337-B7D5-4EF5-A431-D780F5EA6140'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '272EFE15-04A0-4421-82D1-272C18D9EDD2'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET IncludeInUserSearchAPI = 1
               WHERE ID = '2C5F0735-BCCE-4FFE-A225-DF937DACE682'
               AND AutoUpdateIncludeInUserSearchAPI = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET UserSearchPredicateAPI = 'Exact'
               WHERE ID = '2C5F0735-BCCE-4FFE-A225-DF937DACE682'
               AND AutoUpdateUserSearchPredicate = 1;

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '74F9BDC0-2B51-4F54-80DD-62677C682D67'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '33F6DC61-4A5B-4367-87D9-4B50FD89F1F3'
               AND AutoUpdateDefaultInView = 1;

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'F469B1E3-FE73-4B08-93B3-8EBC58742A35'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '60E759AA-6AAE-486A-B99B-3B0D34AF0B9C'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET UserSearchPredicateAPI = 'Exact'
               WHERE ID = '46B9D67F-3365-47B4-BFE1-6BB932392AE3'
               AND AutoUpdateUserSearchPredicate = 1;

/* Set categories for 9 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.ActivityID 
UPDATE [${mjSchema}].[EntityField]
SET 
   DisplayName = 'Activity ID'
WHERE 
   ID = '4087A170-CD32-4B2A-A59E-E2747F272AA8' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.Activity 
UPDATE [${mjSchema}].[EntityField]
SET 
   DisplayName = 'Activity'
WHERE 
   ID = '5BF4CF4B-B9E3-4237-8D0C-EEA4DF89CAD4' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.ActivitySyncRuleID 
UPDATE [${mjSchema}].[EntityField]
SET 
   DisplayName = 'Activity Sync Rule ID'
WHERE 
   ID = 'F9D3B360-0DA7-4FB7-AC4F-8CA065AA9BF3' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.ActivitySyncExclusionID 
UPDATE [${mjSchema}].[EntityField]
SET 
   DisplayName = 'Activity Sync Exclusion ID'
WHERE 
   ID = 'B7BE5C0E-E4D5-42FC-9B82-C0FD25DE4B2A' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.AIPromptRunID 
UPDATE [${mjSchema}].[EntityField]
SET 
   DisplayName = 'AI Prompt Run ID'
WHERE 
   ID = '21E93BC8-0535-445F-AAFD-F3468F1EB62D' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.ActivitySyncRule 
UPDATE [${mjSchema}].[EntityField]
SET 
   DisplayName = 'Activity Sync Rule'
WHERE 
   ID = '33F6DC61-4A5B-4367-87D9-4B50FD89F1F3' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.ActivitySyncExclusion 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Decision Logic',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'C976C194-D37C-41F0-9263-288091FE825C' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.EncryptionKeyID 
UPDATE [${mjSchema}].[EntityField]
SET 
   DisplayName = 'Encryption Key ID'
WHERE 
   ID = '1E55257F-D2BE-4817-82C9-723AEE6F8E42' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.EncryptionKey 
UPDATE [${mjSchema}].[EntityField]
SET 
   DisplayName = 'Encryption Key'
WHERE 
   ID = '49C089A3-71F3-46A2-8182-E3A351B60A8C' AND AutoUpdateCategory = 1;

/* Set categories for 16 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: People.${mjSchema}_Latitude 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   DisplayName = 'Latitude'
WHERE 
   ID = 'DCBAFE92-F383-4836-929C-59F6D1B8438A' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: People.${mjSchema}_Longitude 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   DisplayName = 'Longitude'
WHERE 
   ID = '38138F10-0416-49E1-A6B8-F13F03819D15' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: People.PrimaryAddressLine1 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Location Details',
   GeneratedFormSection = 'Category',
   ExtendedType = 'GeoAddress'
WHERE 
   ID = 'B8E4BFEF-DF50-4DE7-9202-1B95FF662F51' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: People.PrimaryAddressLine2 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Location Details',
   GeneratedFormSection = 'Category',
   ExtendedType = 'GeoAddress'
WHERE 
   ID = '83C29103-8C1C-4483-99A4-3C9A002CF6DB' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: People.PrimaryAddressCity 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Location Details',
   GeneratedFormSection = 'Category',
   ExtendedType = 'GeoCity'
WHERE 
   ID = 'DF8CC5B5-F424-4B3C-8D37-4E6C247477AA' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: People.PrimaryAddressState 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Location Details',
   GeneratedFormSection = 'Category',
   ExtendedType = 'GeoStateProvince'
WHERE 
   ID = 'F847D2DA-3F4A-48C9-8DB1-ADD65D33B6CF' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: People.PrimaryAddressPostalCode 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Location Details',
   GeneratedFormSection = 'Category',
   ExtendedType = 'GeoPostalCode'
WHERE 
   ID = '649C5408-A3C4-4290-B543-9BFF661EBCED' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: People.PrimaryAddressCountry 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Location Details',
   GeneratedFormSection = 'Category',
   ExtendedType = 'GeoCountry'
WHERE 
   ID = 'F7613583-6B36-4589-B6D5-D6A6CAC04657' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: People.PrimaryAddressLatitude 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Location Details',
   GeneratedFormSection = 'Category',
   ExtendedType = 'GeoLatitude'
WHERE 
   ID = '805A2011-2D53-4008-86AB-026B516AE51A' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: People.PrimaryAddressLongitude 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Location Details',
   GeneratedFormSection = 'Category',
   ExtendedType = 'GeoLongitude'
WHERE 
   ID = '8D7D598F-67A8-4B97-869A-4F31B1832A9D' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: People.PrimaryAddressType 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Location Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '0AA8E2BB-850A-4470-9667-6556B3EACB96' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: People.PrimaryEmail 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Professional and Profile',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Email'
WHERE 
   ID = '2C5F0735-BCCE-4FFE-A225-DF937DACE682' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: People.PrimaryPhone 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Professional and Profile',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Tel'
WHERE 
   ID = '2470EF76-2225-4AC3-958B-A01B3A48B910' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: People.CurrentOrganizationID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Professional and Profile',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'B938E862-CC06-4826-9EE0-FFE36EB7C5AC' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: People.CurrentOrganizationName 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Professional and Profile',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '0904A337-B7D5-4EF5-A431-D780F5EA6140' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: People.CurrentJobTitle 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Professional and Profile',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '272EFE15-04A0-4421-82D1-272C18D9EDD2' AND AutoUpdateCategory = 1;

/* Update FieldCategoryInfo setting for entity */

               UPDATE [${mjSchema}].[EntitySetting]
               SET [Value] = '{"Location Details":{"icon":"fa fa-map-marker-alt","description":"Geographic location, address, and mapping coordinates for the person"}}', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [EntityID] = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND [Name] = 'FieldCategoryInfo';

/* Update FieldCategoryIcons setting (legacy) */

               UPDATE [${mjSchema}].[EntitySetting]
               SET [Value] = '{"Location Details":"fa fa-map-marker-alt"}', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [EntityID] = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND [Name] = 'FieldCategoryIcons';

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
