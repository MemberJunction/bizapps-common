-- ============================================================================
-- Add filtered unique index on Person.LinkedUserID
--
-- Enforces 1:1 relationship between Person and User records.
-- Filtered to WHERE LinkedUserID IS NOT NULL so multiple unlinked persons
-- are allowed. Prevents two Person records from linking to the same User.
-- ============================================================================

-- Verify no duplicates exist before adding the constraint
IF EXISTS (
    SELECT LinkedUserID, COUNT(*) AS cnt
    FROM ${flyway:defaultSchema}.Person
    WHERE LinkedUserID IS NOT NULL
    GROUP BY LinkedUserID
    HAVING COUNT(*) > 1
)
BEGIN
    RAISERROR('Cannot add unique index: duplicate LinkedUserID values exist in Person table. Resolve duplicates first.', 16, 1);
    RETURN;
END

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'UQ_Person_LinkedUserID'
      AND object_id = OBJECT_ID('${flyway:defaultSchema}.Person')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_Person_LinkedUserID
    ON ${flyway:defaultSchema}.Person (LinkedUserID)
    WHERE LinkedUserID IS NOT NULL;
END
GO

-- ============================================================================
-- CodeGen output below — paste regenerated views/SPs after running CodeGen
-- ============================================================================
