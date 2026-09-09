/*
  Describe the four Activity Sync switches an operator actually sets.

  WHY. The exclusion window and the two on/off switches had no reader until recently: switching an
  exclusion off left it excluding, one dated to lapse never lapsed, and deactivating a provider type
  changed nothing. Those are fixed. What is still missing is the part an operator meets -- all four
  columns were created without a description, so the Explorer offers a date box and a checkbox with
  nothing to say what they mean.

  THE ONE THAT ACTUALLY NEEDS SAYING is EffectiveFrom / EffectiveTo, because the same feature carries
  the opposite convention a few fields away. ActivitySyncConnection.StartAt/EndAt are described as an
  activation window -- "now is within [StartAt, EndAt]" -- and IsConnectionActive is handed `now` to
  evaluate them against. The exclusion window is NOT that. ExclusionAppliesTo is handed the item's own
  StartedAt, so the window selects which MESSAGES the exclusion covers, not when the exclusion is live.

  An operator who reads the connection's description and reasonably generalises it will get this wrong
  in a specific, quiet way: setting EffectiveFrom to today on an opt-out, expecting "from now on", and
  then finding a backfill of older mail is not excluded at all. Nothing errors. The descriptions are
  where that is cheapest to prevent.

  WHY EXTENDED PROPERTIES AND NOT JUST AN EntityField UPDATE -- this is the part that is easy to get
  wrong, and a first pass at this migration did. EntityField.Description is not a place to write; it
  is a mirror. spUpdateExistingEntityFieldsFromSchema, which R__RefreshMetadata runs, does:

      ef.Description = IIF(fr.AutoUpdateDescription=1, fr.SQLDescription, ef.Description)

  and AutoUpdateDescription is DEFAULT ((1)), which these four rows took. So a bare UPDATE against
  EntityField would have been reverted to NULL by the next refresh -- silently, and on someone else's
  deploy. MS_Description on the column is the durable source; EntityField follows from it.

  The EntityField statement at the bottom then exists only for TIMING. R__RefreshMetadata is a Flyway
  repeatable: it re-runs when its checksum changes, and this migration does not change it. So without
  that statement the descriptions would sit in the catalog and not reach the Explorer until something
  unrelated happened to touch the refresh. It reads the value back out of the property just written
  rather than repeating the literal, so the two cannot drift, and it is exactly the write the next
  refresh would make anyway -- running it early, not instead.

  Deliberately NOT guarded on `Description IS NULL`. With AutoUpdateDescription = 1 a hand-written
  description is already overwritten by the platform on every refresh, so preserving one here would
  only buy it the few minutes until then while leaving EntityField and the catalog disagreeing.
  Hand-authoring a description means setting AutoUpdateDescription = 0 on that row, which the platform
  does honour; that case is untouched by this migration, because the refresh reads the same flag.

  Metadata only: no table is created or altered, and no data in any Activity Sync table is touched.

  It is NOT free of CodeGen output, though, and the generated files are deliberately not in this
  commit. CodeGen emits a field's description in two places -- a `* * Description:` line in the
  entity class docblock, and the `description:` argument of the GraphQL `@Field` decorator -- so the
  next CodeGen run will add four of each. Authoring those by hand is what is being avoided: CodeGen
  reads them from a live database, no CI job checks that the generated files are current, and a
  hand-written approximation that differs from the real emit would show up as a phantom diff for
  whoever next runs it. The generated files follow on the next run, correctly, from this source.
*/

---------------------------------------------------------------------------
-- ActivitySyncExclusion.IsEnabled
---------------------------------------------------------------------------
IF EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncExclusion]')
      AND minor_id = COLUMNPROPERTY(OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncExclusion]'), N'IsEnabled', 'ColumnId')
      AND name = N'MS_Description'
      AND class = 1  -- column, not an index or the table itself
)
    EXEC sp_dropextendedproperty
        @name = N'MS_Description',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE',  @level1name = N'ActivitySyncExclusion',
        @level2type = N'COLUMN', @level2name = N'IsEnabled';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Whether this exclusion is in force. Unchecked, it is ignored entirely and the messages it names are qualified as if it did not exist. Rules honoured their own IsEnabled from the start; exclusions did not until v5.39, so an exclusion switched off before then kept excluding.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncExclusion',
    @level2type = N'COLUMN', @level2name = N'IsEnabled';
GO

---------------------------------------------------------------------------
-- ActivitySyncExclusion.EffectiveFrom
---------------------------------------------------------------------------
IF EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncExclusion]')
      AND minor_id = COLUMNPROPERTY(OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncExclusion]'), N'EffectiveFrom', 'ColumnId')
      AND name = N'MS_Description'
      AND class = 1  -- column, not an index or the table itself
)
    EXEC sp_dropextendedproperty
        @name = N'MS_Description',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE',  @level1name = N'ActivitySyncExclusion',
        @level2type = N'COLUMN', @level2name = N'EffectiveFrom';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Start of the window of MESSAGES this exclusion covers, matched against when the message was sent or received -- NOT against the current time. Leave empty for no lower bound. This is deliberately different from ActivitySyncConnection.StartAt, which is evaluated against the clock: setting this to today does not mean "exclude from today onwards", it means "exclude messages dated today or later", so a later backfill of older mail is not covered by it. Item time is also what keeps a re-run reproducible, so the run log can answer which rule excluded a message and give the same answer next time.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncExclusion',
    @level2type = N'COLUMN', @level2name = N'EffectiveFrom';
GO

---------------------------------------------------------------------------
-- ActivitySyncExclusion.EffectiveTo
---------------------------------------------------------------------------
IF EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncExclusion]')
      AND minor_id = COLUMNPROPERTY(OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncExclusion]'), N'EffectiveTo', 'ColumnId')
      AND name = N'MS_Description'
      AND class = 1  -- column, not an index or the table itself
)
    EXEC sp_dropextendedproperty
        @name = N'MS_Description',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE',  @level1name = N'ActivitySyncExclusion',
        @level2type = N'COLUMN', @level2name = N'EffectiveTo';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'End of the window of MESSAGES this exclusion covers, matched against when the message was sent or received -- NOT against the current time. Leave empty for no upper bound. Inclusive of the instant given, matching how ActivitySyncRule DateFrom/DateTo compare. See EffectiveFrom for why this is item time rather than clock time.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncExclusion',
    @level2type = N'COLUMN', @level2name = N'EffectiveTo';
GO

---------------------------------------------------------------------------
-- ActivitySyncProviderType.IsActive
---------------------------------------------------------------------------
IF EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncProviderType]')
      AND minor_id = COLUMNPROPERTY(OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncProviderType]'), N'IsActive', 'ColumnId')
      AND name = N'MS_Description'
      AND class = 1  -- column, not an index or the table itself
)
    EXEC sp_dropextendedproperty
        @name = N'MS_Description',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE',  @level1name = N'ActivitySyncProviderType',
        @level2type = N'COLUMN', @level2name = N'IsActive';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Whether this connector type may run. Unchecked, every connection using it refuses on its next fleet tick and reports Status = Error with the reason, rather than appearing to sync -- and each returns to Active by itself once the type is re-enabled and a run succeeds. Nothing is read from any mailbox while it is off.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncProviderType',
    @level2type = N'COLUMN', @level2name = N'IsActive';
GO

---------------------------------------------------------------------------
-- Mirror the four properties into EntityField now, rather than waiting for
-- whichever later deploy happens to re-run R__RefreshMetadata.
--
-- CROSS APPLY, not LEFT JOIN, on purpose: if a property is somehow absent the
-- row simply does not update. Writing NULL over a description is the one
-- outcome this statement must not be able to produce.
---------------------------------------------------------------------------
;WITH targets (EntityFieldID, TableName, ColumnName) AS (
    SELECT CAST('b741ade2-f250-40d7-b0d2-61d28b331f3e' AS UNIQUEIDENTIFIER), N'ActivitySyncExclusion',    N'IsEnabled'     UNION ALL
    SELECT CAST('8f9e007e-b597-44e8-ab81-7bb7d2aca504' AS UNIQUEIDENTIFIER), N'ActivitySyncExclusion',    N'EffectiveFrom' UNION ALL
    SELECT CAST('85b42461-d8db-4d00-ad4e-9b9cc42eaf3e' AS UNIQUEIDENTIFIER), N'ActivitySyncExclusion',    N'EffectiveTo'   UNION ALL
    SELECT CAST('d6351250-3c56-41cb-a5c1-003df4812fc3' AS UNIQUEIDENTIFIER), N'ActivitySyncProviderType', N'IsActive'
)
UPDATE ef
SET ef.[Description]    = CONVERT(NVARCHAR(MAX), ep.[value]),
    ef.[__mj_UpdatedAt] = GETUTCDATE()
FROM [${mjSchema}].[EntityField] ef
INNER JOIN targets t
    ON t.EntityFieldID = ef.[ID]
CROSS APPLY (
    SELECT x.[value]
    FROM sys.extended_properties x
    WHERE x.major_id = OBJECT_ID(N'[${flyway:defaultSchema}].[' + t.TableName + N']')
      AND x.minor_id = COLUMNPROPERTY(OBJECT_ID(N'[${flyway:defaultSchema}].[' + t.TableName + N']'), t.ColumnName, 'ColumnId')
      AND x.[name] = N'MS_Description'
      AND x.class = 1
) ep;
GO
