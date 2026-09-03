-- vwActivityLinks and vwActivityFiles join Activity.Title as [Activity] because
-- ActivityID.IncludeRelatedEntityNameFieldInBaseView = 1. The Entity virtual on
-- Links (and File on Files) was registered in V202608251531; the Activity
-- related-name virtual was not. Save-capture then declares N slots against an
-- N+1 column view (Links: 11 vs 12) and Activity Link Create fails on a
-- from-scratch install.

-- Sequence must match view column order (positional INSERT INTO @ResultTable EXEC).
-- Bump the trailing related-name field first so UQ_EntityField_EntityID_Sequence
-- stays intact.

DECLARE @LinksID UNIQUEIDENTIFIER = '9C48DF77-E4A1-4ADB-AABF-916F5798B894'; -- MJ_BizApps_Common: Activity Links
DECLARE @FilesID UNIQUEIDENTIFIER = '232C27E0-0AAC-450B-B902-251EF20A2802'; -- MJ_BizApps_Common: Activity Files

-- Activity Links: view order ... __mj_UpdatedAt, Activity, Entity
UPDATE [${mjSchema}].[EntityField]
SET [Sequence] = 12
WHERE [EntityID] = @LinksID
  AND [Name] = 'Entity'
  AND [Sequence] = 11;

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '99ee4347-a71c-4687-ab14-ece54ccbbdcd' OR (EntityID = @LinksID AND Name = 'Activity'))
INSERT INTO [${mjSchema}].[EntityField]
    (ID, EntityID, Sequence, Name, DisplayName, Type, Length, Precision, Scale, AllowsNull, AutoIncrement, AllowUpdateAPI, IsVirtual, IsComputed, IsNameField, IncludeInUserSearchAPI, IncludeRelatedEntityNameFieldInBaseView, DefaultInView, IsPrimaryKey, IsUnique, RelatedEntityDisplayType, __mj_CreatedAt, __mj_UpdatedAt)
VALUES
    ('99ee4347-a71c-4687-ab14-ece54ccbbdcd', @LinksID, 11, 'Activity', 'Activity', 'nvarchar', 1000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Search', GETUTCDATE(), GETUTCDATE());

-- Activity Files: view order ... __mj_UpdatedAt, Activity, File
UPDATE [${mjSchema}].[EntityField]
SET [Sequence] = 9
WHERE [EntityID] = @FilesID
  AND [Name] = 'File'
  AND [Sequence] = 8;

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8f910bcc-a121-481b-9ff0-ae33e5bdbb87' OR (EntityID = @FilesID AND Name = 'Activity'))
INSERT INTO [${mjSchema}].[EntityField]
    (ID, EntityID, Sequence, Name, DisplayName, Type, Length, Precision, Scale, AllowsNull, AutoIncrement, AllowUpdateAPI, IsVirtual, IsComputed, IsNameField, IncludeInUserSearchAPI, IncludeRelatedEntityNameFieldInBaseView, DefaultInView, IsPrimaryKey, IsUnique, RelatedEntityDisplayType, __mj_CreatedAt, __mj_UpdatedAt)
VALUES
    ('8f910bcc-a121-481b-9ff0-ae33e5bdbb87', @FilesID, 8, 'Activity', 'Activity', 'nvarchar', 1000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Search', GETUTCDATE(), GETUTCDATE());
GO

CREATE OR ALTER VIEW [${flyway:defaultSchema}].[vwActivityLinks]
AS
SELECT
    a.*,
    Activity_ActivityID.[Title] AS [Activity],
    MJEntity_EntityID.[Name] AS [Entity]
FROM
    [${flyway:defaultSchema}].[ActivityLink] AS a
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Activity] AS Activity_ActivityID
  ON
    [a].[ActivityID] = Activity_ActivityID.[ID]
LEFT OUTER JOIN
    [${mjSchema}].[Entity] AS MJEntity_EntityID
  ON
    [a].[EntityID] = MJEntity_EntityID.[ID]
GO

CREATE OR ALTER VIEW [${flyway:defaultSchema}].[vwActivityFiles]
AS
SELECT
    a.*,
    Activity_ActivityID.[Title] AS [Activity],
    MJFile_FileID.[Name] AS [File]
FROM
    [${flyway:defaultSchema}].[ActivityFile] AS a
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Activity] AS Activity_ActivityID
  ON
    [a].[ActivityID] = Activity_ActivityID.[ID]
INNER JOIN
    [${mjSchema}].[File] AS MJFile_FileID
  ON
    [a].[FileID] = MJFile_FileID.[ID]
GO
