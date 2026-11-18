-- =============================================================================
-- Migration: V202610031700__v5.50.x__Repair_Relationship_Objects.sql
-- Description: Re-create vwRelationships, spCreateRelationship and
--              spUpdateRelationship at their current definitions (#219).
--
-- bizapps-forms releases up to and including 0.14.x carried June-2026 copies of
-- these three objects in their baseline migration. Forms installs after Common,
-- so a host that installed Forms after Common 5.45 had Common's objects replaced
-- by the stale copies:
--   - spCreateRelationship / spUpdateRelationship lack @JobFunctionID and
--     @SeniorityLevelID, so every MJ_BizApps_Common: Relationships save fails.
--   - vwRelationships lacks the JobFunction and SeniorityLevel columns.
-- Hosts that installed Forms before Common 5.45 were repaired by
-- V202609211200__v5.45.x__Job_Function_Seniority.sql at the time.
--
-- The objects below are copied verbatim from V202609211200, which still holds
-- their current definitions. They are re-emitted unconditionally: on an
-- undamaged host this replaces each object with an identical copy.
--
-- The other Common objects the Forms baseline overwrote (the ContactMethod
-- objects, spDeleteRelationship, trgUpdateRelationship) are not re-created:
-- their stale copies are functionally identical to Common's current ones.
--
-- Detection (no row = damaged):
--   SELECT 1 FROM sys.parameters
--   WHERE object_id = OBJECT_ID('__mj_BizAppsCommon.spCreateRelationship')
--     AND name = '@JobFunctionID';
-- =============================================================================


















































/**************************************************************************************************
 **************************************************************************************************
 **                                                                                              **
 **                 CODEGEN OUTPUT — copied verbatim from V202609211200 (v5.45.x)                **
 **                                                                                              **
 **************************************************************************************************
 **************************************************************************************************/

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

/* spUpdate Permissions for MJ_BizApps_Common: Relationships */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateRelationship] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateRelationship] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateRelationship] TO [cdp_Developer], [cdp_Integration];
