-- =============================================================================
-- Migration: V202610062130__v5.51.x__Drop_Person_Organization_Virtual_Geo_Fields.sql
-- Description: People and Organizations stop carrying the virtual __mj_Latitude /
--              __mj_Longitude fields (#215). MJ CodeGen adds the vwRecordGeoCodes
--              join only to entities that are geo sources; Person and Organization
--              are display-only and take their coordinates from the primary Address
--              (PrimaryAddressLatitude / PrimaryAddressLongitude on the wrappers).
--              Earlier CodeGen output in this chain (V202609051800) still joined
--              vwRecordGeoCodes, so a host's first CodeGen run rewrote the inner
--              views without it and left four EntityField rows naming columns the
--              views no longer produce. Every later CodeGen run then failed on
--              UQ_EntityField_EntityID_Sequence, and reads of both entities selected
--              missing columns.
--
--              1) Recreate vwPeopleGenerated / vwOrganizationsGenerated in the shape
--                 CodeGen emits (no vwRecordGeoCodes join).
--              2) Refresh the g.* wrappers vwPeople / vwOrganizations.
--              3) Delete the four EntityField rows and the rows that reference them.
--
--              No CodeGen emit follows. With this applied, CodeGen regenerates
--              the same views and leaves the Person / Organization CRUD procedures
--              as they are, so its output for this change is empty. The app
--              migrate's metadata heal renumbers the remaining fields.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) Inner generated views, as CodeGen emits them
-- -----------------------------------------------------------------------------
CREATE OR ALTER VIEW [${flyway:defaultSchema}].[vwPeopleGenerated]
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

CREATE OR ALTER VIEW [${flyway:defaultSchema}].[vwOrganizationsGenerated]
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

-- -----------------------------------------------------------------------------
-- 2) Refresh the wrappers. A g.* view keeps the column list it was compiled
--    with, so without this it still lists __mj_Latitude and fails ("more column
--    names specified than columns defined"), and CodeGen cannot create the CRUD
--    procedures that read it (MemberJunction/MJ#4927).
-- -----------------------------------------------------------------------------
EXEC sp_refreshview N'[${flyway:defaultSchema}].[vwPeople]';
GO
EXEC sp_refreshview N'[${flyway:defaultSchema}].[vwOrganizations]';
GO

-- -----------------------------------------------------------------------------
-- 3) The four EntityField rows, and the rows that reference them.
--    EntityFieldPermission exists from MJ 6.1.x on; this app still installs on
--    earlier 6.1 Edge cores without it, hence the dynamic statement.
-- -----------------------------------------------------------------------------
DELETE FROM [${mjSchema}].[EntityFieldValue]
WHERE EntityFieldID IN (
    SELECT ID FROM [${mjSchema}].[EntityField]
    WHERE EntityID IN ('7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', 'C70448F9-9792-41D7-A82C-784B66429D54')
      AND Name IN ('__mj_Latitude', '__mj_Longitude')
);
GO

IF OBJECT_ID(N'[${mjSchema}].[EntityFieldPermission]', N'U') IS NOT NULL
    EXEC (N'DELETE FROM [${mjSchema}].[EntityFieldPermission]
WHERE EntityFieldID IN (
    SELECT ID FROM [${mjSchema}].[EntityField]
    WHERE EntityID IN (''7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'', ''C70448F9-9792-41D7-A82C-784B66429D54'')
      AND Name IN (''__mj_Latitude'', ''__mj_Longitude'')
);');
GO

DELETE FROM [${mjSchema}].[EntityField] WHERE EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name IN ('__mj_Latitude', '__mj_Longitude'); -- Entity: MJ_BizApps_Common: People
GO
DELETE FROM [${mjSchema}].[EntityField] WHERE EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name IN ('__mj_Latitude', '__mj_Longitude'); -- Entity: MJ_BizApps_Common: Organizations
GO
