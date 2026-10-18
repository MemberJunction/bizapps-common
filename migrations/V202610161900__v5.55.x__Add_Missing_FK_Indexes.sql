-- =============================================================================
-- Migration: V202610161900__v5.55.x__Add_Missing_FK_Indexes.sql
-- Description: Ensure all foreign key columns in __mj_BizAppsCommon have their
--              CodeGen-standard IDX_AUTO_MJ_FKEY_{Table}_{Column} nonclustered
--              indexes (MC4 schema consistency check).
--
-- Covers:
--   - ActivityFile (ActivityID, FileID) — omitted from V202608251531
--   - ActivityLink (ActivityID, EntityID) — omitted from V202608251531
--   - Person (SeniorityLevelID) — omitted from V202609211200
--   - PersonJobFunction (JobFunctionID, PersonID) — omitted from V202609211200
--   - Relationship (JobFunctionID, SeniorityLevelID) — omitted from V202609211200
-- =============================================================================

-- Index for Foreign Keys for ActivityFile
-----------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivityFile_ActivityID'
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivityFile]')
)
CREATE NONCLUSTERED INDEX IDX_AUTO_MJ_FKEY_ActivityFile_ActivityID ON [${flyway:defaultSchema}].[ActivityFile] ([ActivityID]);
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivityFile_FileID'
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivityFile]')
)
CREATE NONCLUSTERED INDEX IDX_AUTO_MJ_FKEY_ActivityFile_FileID ON [${flyway:defaultSchema}].[ActivityFile] ([FileID]);
GO

-- Index for Foreign Keys for ActivityLink
-----------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivityLink_ActivityID'
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivityLink]')
)
CREATE NONCLUSTERED INDEX IDX_AUTO_MJ_FKEY_ActivityLink_ActivityID ON [${flyway:defaultSchema}].[ActivityLink] ([ActivityID]);
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivityLink_EntityID'
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivityLink]')
)
CREATE NONCLUSTERED INDEX IDX_AUTO_MJ_FKEY_ActivityLink_EntityID ON [${flyway:defaultSchema}].[ActivityLink] ([EntityID]);
GO

-- Index for Foreign Keys for Person
-----------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Person_SeniorityLevelID'
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Person]')
)
CREATE NONCLUSTERED INDEX IDX_AUTO_MJ_FKEY_Person_SeniorityLevelID ON [${flyway:defaultSchema}].[Person] ([SeniorityLevelID]);
GO

-- Index for Foreign Keys for PersonJobFunction
-----------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_PersonJobFunction_JobFunctionID'
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[PersonJobFunction]')
)
CREATE NONCLUSTERED INDEX IDX_AUTO_MJ_FKEY_PersonJobFunction_JobFunctionID ON [${flyway:defaultSchema}].[PersonJobFunction] ([JobFunctionID]);
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_PersonJobFunction_PersonID'
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[PersonJobFunction]')
)
CREATE NONCLUSTERED INDEX IDX_AUTO_MJ_FKEY_PersonJobFunction_PersonID ON [${flyway:defaultSchema}].[PersonJobFunction] ([PersonID]);
GO

-- Index for Foreign Keys for Relationship
-----------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Relationship_JobFunctionID'
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Relationship]')
)
CREATE NONCLUSTERED INDEX IDX_AUTO_MJ_FKEY_Relationship_JobFunctionID ON [${flyway:defaultSchema}].[Relationship] ([JobFunctionID]);
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Relationship_SeniorityLevelID'
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Relationship]')
)
CREATE NONCLUSTERED INDEX IDX_AUTO_MJ_FKEY_Relationship_SeniorityLevelID ON [${flyway:defaultSchema}].[Relationship] ([SeniorityLevelID]);
GO
