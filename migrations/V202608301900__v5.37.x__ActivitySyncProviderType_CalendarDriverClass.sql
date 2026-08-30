-- Companion calendar surface is data on ActivitySyncProviderType, not a literal on
-- the deprecated ActivitySyncConnection.Provider column (dropped as a CHECK in
-- V202608291500). A connection created the documented way — type FK set, Provider
-- NULL — must still get a calendar pass. The engine resolves CalendarDriverClass
-- through ClassFactory; it does not `new` the Graph calendar provider.
--
-- The view is SELECT a.*, so the new column appears without a view rebuild.

ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncProviderType]
ADD [CalendarDriverClass] NVARCHAR(200) NULL;
GO

UPDATE [${flyway:defaultSchema}].[ActivitySyncProviderType]
SET [CalendarDriverClass] = N'Microsoft365.Calendar'
WHERE [Code] = N'Microsoft365'
  AND [CalendarDriverClass] IS NULL;
GO
