-- =============================================================================================
-- BizApps Common v5.69.x -- Metadata_Sync (one per release)
-- =============================================================================================
-- Ships the one metadata change since v5.68.0 that no migration writes: organization search by
-- website domain (#329), from metadata/entities/.entities.json. The Organizations.WebsiteDomain
-- entity field becomes a user-search field with a starts-with predicate, and both settings are
-- pinned (AutoUpdate* = 0) so CodeGen cannot flip them back. WebsiteDomain and its index
-- IX_Organization_WebsiteDomain exist since V202610211654__v5.56.x__Party_Lookup_Domain_Columns.
--
-- HOW IT WAS MADE: written by hand from the metadata values, not captured from `mj sync push`. The
-- push writes a full spUpdateEntityField snapshot of every column; this update sets only the four
-- columns the metadata changed. The other changes in that file since v5.68.0 are `_comments`,
-- which the push never writes.
--
-- HOST VALUES KEPT: the update runs only while the field's user-search settings are still owned by
-- CodeGen (AutoUpdateIncludeInUserSearchAPI = 1). A host that pinned them keeps its own.
-- Idempotent: a second run matches no row.
-- =============================================================================================

UPDATE [${mjSchema}].[EntityField]
SET [IncludeInUserSearchAPI] = 1,
    [UserSearchPredicateAPI] = N'BeginsWith',
    [AutoUpdateIncludeInUserSearchAPI] = 0,
    [AutoUpdateUserSearchPredicate] = 0
WHERE [EntityID] = 'C70448F9-9792-41D7-A82C-784B66429D54' -- MJ_BizApps_Common: Organizations
  AND [Name] = N'WebsiteDomain'
  AND [AutoUpdateIncludeInUserSearchAPI] = 1;
GO
