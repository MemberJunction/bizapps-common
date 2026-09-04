-- =============================================================================
-- Activity: remove the phantom `ParentActivity` EntityField, and close the gap
-- it left in the sequence.
-- =============================================================================
--
-- WHAT IS BROKEN WITHOUT THIS. `Activity` metadata carries a virtual field
-- `ParentActivity` at sequence 24 that `vwActivities` does not emit. MJ's
-- save-capture is POSITIONAL -- it declares one slot per EntityField and reads
-- them back by position from the base view -- so metadata declared 34 slots
-- against a 33-column view and EVERY Activity create failed with:
--
--     Column name or number of supplied values does not match table definition.
--
-- Activity Sync therefore fetched, qualified and resolved correctly and then
-- wrote nothing, reporting Failed rather than Success. The watermark is held on
-- failure, so it retried the same messages forever.
--
-- This is the same defect V202608261015 fixed for Activity Links and Activity
-- Files, in the opposite direction: that one added a virtual field the view HAD
-- and metadata lacked (N slots against N+1 columns); this one removes a virtual
-- field metadata HAS and the view lacks (N+1 slots against N columns).
--
-- WHY REMOVE THE FIELD RATHER THAN ADD THE COLUMN. `ParentActivityID` is a
-- self-referencing FK, and for it CodeGen emits the HIERARCHY columns
-- (RootParentActivityID, ParentActivityIDDepth/Path/IsLeaf/ChildCount) instead
-- of a plain related-name join. Re-running CodeGen regenerates the view without
-- `ParentActivity`, so a migration that added the column would be undone on the
-- next run. Verified on a healed host: after a full `mj codegen`, metadata and
-- view stay aligned at 33/33 and the field does NOT come back -- which is also
-- why this deliberately leaves `IncludeRelatedEntityNameFieldInBaseView` alone
-- rather than flipping a flag whose CodeGen behaviour differs between this
-- entity and ActivityType for reasons not established here.
--
-- GUARDED ON THE ACTUAL STATE, NOT ON AN ID. Two reasons:
--   * the field is created by a CodeGen proc that MINTS A FRESH GUID PER HOST,
--     so an ID-only guard would match nothing on most databases -- the same
--     trap as bizapps-orders#126, where an ID-only guard silently skipped and
--     the migration chain died on the unique index;
--   * if some CodeGen version DOES emit the column, removing the field would
--     recreate the defect mirrored. So this acts only where the view genuinely
--     lacks it.
-- Idempotent: re-running finds nothing to do.
-- =============================================================================

DECLARE @ActivityEntityID UNIQUEIDENTIFIER = (
    SELECT ID FROM [${mjSchema}].[Entity]
    WHERE BaseTable = 'Activity' AND SchemaName = '${flyway:defaultSchema}'
);

IF @ActivityEntityID IS NULL
BEGIN
    -- Not an error: a database without the Activities entity has nothing to fix.
    PRINT 'Activity entity not present in this database - nothing to do.';
END
ELSE
BEGIN
    DECLARE @ViewHasColumn BIT = CASE WHEN EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = '${flyway:defaultSchema}'
          AND TABLE_NAME   = 'vwActivities'
          AND COLUMN_NAME  = 'ParentActivity'
    ) THEN 1 ELSE 0 END;

    DECLARE @PhantomID UNIQUEIDENTIFIER = (
        SELECT ID FROM [${mjSchema}].[EntityField]
        WHERE EntityID = @ActivityEntityID AND Name = 'ParentActivity'
    );

    IF @PhantomID IS NULL
    BEGIN
        PRINT 'No ParentActivity EntityField - already aligned.';
    END
    ELSE IF @ViewHasColumn = 1
    BEGIN
        -- The view really does expose it here, so metadata is correct and the
        -- positional contract holds. Leave it alone and say why.
        PRINT 'vwActivities exposes ParentActivity on this database - metadata is correct, leaving it.';
    END
    ELSE
    BEGIN
        DECLARE @PhantomSeq INT = (
            SELECT Sequence FROM [${mjSchema}].[EntityField] WHERE ID = @PhantomID
        );

        -- EntityFieldValue is the only FK onto EntityField. A virtual field should
        -- carry none, but a value list left behind would block the delete.
        DELETE FROM [${mjSchema}].[EntityFieldValue] WHERE EntityFieldID = @PhantomID;

        DELETE FROM [${mjSchema}].[EntityField] WHERE ID = @PhantomID;

        -- Close the gap so Sequence matches ORDINAL_POSITION again -- the whole
        -- point, since the positional read is what was broken. Ascending order
        -- keeps UQ_EntityField_EntityID_Sequence satisfied at every step, because
        -- the vacated slot is always filled before the next one is vacated.
        UPDATE [${mjSchema}].[EntityField]
        SET Sequence = Sequence - 1
        WHERE EntityID = @ActivityEntityID AND Sequence > @PhantomSeq;

        PRINT CONCAT('Removed phantom ParentActivity (was sequence ', @PhantomSeq, ') and closed the gap.');
    END
END
GO

-- Prove it, in the migration itself: a metadata field with no matching view
-- column is exactly the condition that breaks the positional save, so failing
-- here is far cheaper than failing on the next Activity create.
DECLARE @Mismatched INT = (
    SELECT COUNT(*)
    FROM [${mjSchema}].[EntityField] f
    JOIN [${mjSchema}].[Entity] e ON e.ID = f.EntityID
    WHERE e.BaseTable = 'Activity'
      AND e.SchemaName = '${flyway:defaultSchema}'
      AND NOT EXISTS (
          SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS c
          WHERE c.TABLE_SCHEMA = '${flyway:defaultSchema}'
            AND c.TABLE_NAME   = 'vwActivities'
            AND c.COLUMN_NAME  = f.Name
      )
);

IF @Mismatched > 0
BEGIN
    DECLARE @Msg NVARCHAR(400) = CONCAT(
        'Activity metadata still declares ', @Mismatched,
        ' field(s) that vwActivities does not expose. Activity create will fail on the positional save.'
    );
    THROW 51000, @Msg, 1;
END
GO
