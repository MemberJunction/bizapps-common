-- V202608301900 set RelatedEntityNameFieldMap = 'ActivitySyncExclusion' on
-- Activity Sync Run Details.ActivitySyncExclusionID and shipped
-- vwActivitySyncRunDetails with the matching [ActivitySyncExclusion] join
-- column — but never registered the virtual EntityField for it. Its siblings
-- (ActivitySyncRule @18, Activity @20, EncryptionKey @21) were registered;
-- sequence 19 was left empty. Save-capture then declares 20 slots against a
-- 21-column view and EVERY Activity Sync Run Detail save fails on a
-- from-scratch install — silently, because the engine reports the run as
-- successful and only the audit rows are lost. Found by a live Microsoft 365
-- sync against a migrations-only database; verified fixed by this insert.
-- Same fix class as V202608261015 (Activity Files / Activity Links).
-- Sequence must match view column order (positional INSERT INTO @ResultTable EXEC):
-- ... __mj_UpdatedAt @17, ActivitySyncRule @18, ActivitySyncExclusion @19, Activity @20, EncryptionKey @21.

DECLARE @RunDetailsID UNIQUEIDENTIFIER = (
    SELECT [ID] FROM [${mjSchema}].[Entity]
    WHERE [Name] = 'MJ_BizApps_Common: Activity Sync Run Details'
);

-- Fresh-install order is ActivitySyncRule @18, Activity @19, EncryptionKey @20 (no hole).
-- Open slot 19 by bumping the trailing virtuals DESCENDING so UQ_EntityField_EntityID_Sequence
-- stays intact at every step; each bump is guarded on its expected current sequence so a
-- database CodeGen has already re-sequenced (Activity @20, EncryptionKey @21) is left alone.
UPDATE [${mjSchema}].[EntityField]
SET [Sequence] = 21
WHERE [EntityID] = @RunDetailsID AND [Name] = 'EncryptionKey' AND [Sequence] = 20;

UPDATE [${mjSchema}].[EntityField]
SET [Sequence] = 20
WHERE [EntityID] = @RunDetailsID AND [Name] = 'Activity' AND [Sequence] = 19;

IF @RunDetailsID IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM [${mjSchema}].[EntityField]
       WHERE [ID] = '98544955-be9a-492a-86f5-46926389df09'
          OR ([EntityID] = @RunDetailsID AND [Name] = 'ActivitySyncExclusion')
   )
INSERT INTO [${mjSchema}].[EntityField]
    (ID, EntityID, Sequence, Name, DisplayName, Type, Length, Precision, Scale, AllowsNull, AutoIncrement, AllowUpdateAPI, IsVirtual, IsComputed, IsNameField, IncludeInUserSearchAPI, IncludeRelatedEntityNameFieldInBaseView, DefaultInView, IsPrimaryKey, IsUnique, RelatedEntityDisplayType, __mj_CreatedAt, __mj_UpdatedAt)
VALUES
    ('98544955-be9a-492a-86f5-46926389df09', @RunDetailsID, 19, 'ActivitySyncExclusion', 'Activity Sync Exclusion', 'nvarchar', 1000, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Search', GETUTCDATE(), GETUTCDATE());
GO
