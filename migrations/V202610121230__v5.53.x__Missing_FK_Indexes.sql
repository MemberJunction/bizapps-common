-- =============================================================================
-- Migration: V202610121230__v5.53.x__Missing_FK_Indexes.sql
-- Description: Create the IDX_AUTO_MJ_FKEY_* foreign-key indexes that CodeGen
--              emits for every FK column but that earlier migrations never
--              shipped for seven columns:
--                ActivityFile.ActivityID, ActivityFile.FileID,
--                ActivityLink.ActivityID, ActivityLink.EntityID,
--                Person.SeniorityLevelID,
--                PersonJobFunction.PersonID, PersonJobFunction.JobFunctionID
--              (V202608251531 / V202608252150 shipped the Activity* CodeGen emit
--              without these index files; V202609211200 added the
--              PersonJobFunction table and Person.SeniorityLevelID without them.)
--              A database-only install (mj migrate + mj sync push, no CodeGen
--              over this schema) therefore lacked them; integration check
--              IT24/MC4 requires every FK column to have its CodeGen-named index.
--              Statements are in the exact form CodeGen emits (idempotent by name).
--
-- Exception to CLAUDE.md "no foreign-key indexes (CodeGen adds them)": that rule
-- keeps hand DDL from duplicating CodeGen's emit in the same migration. Here
-- the migrations that added these columns (V202608251531, V202608252150,
-- V202609211200) shipped their CodeGen output without these index statements,
-- and a database-only install never runs CodeGen over this schema.
-- So this whole file IS the missing CodeGen output, byte-for-byte in CodeGen's
-- IDX_AUTO_MJ_FKEY_* form and idempotent, rather than hand DDL beside a
-- CodeGen block. It has no hand DDL above a banner, so it carries no banner.
-- =============================================================================

-- Index for foreign key ActivityID in table ActivityFile
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivityFile_ActivityID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivityFile]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivityFile_ActivityID ON [${flyway:defaultSchema}].[ActivityFile] ([ActivityID]);

-- Index for foreign key FileID in table ActivityFile
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivityFile_FileID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivityFile]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivityFile_FileID ON [${flyway:defaultSchema}].[ActivityFile] ([FileID]);

-- Index for foreign key ActivityID in table ActivityLink
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivityLink_ActivityID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivityLink]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivityLink_ActivityID ON [${flyway:defaultSchema}].[ActivityLink] ([ActivityID]);

-- Index for foreign key EntityID in table ActivityLink
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivityLink_EntityID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivityLink]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivityLink_EntityID ON [${flyway:defaultSchema}].[ActivityLink] ([EntityID]);

-- Index for foreign key SeniorityLevelID in table Person
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Person_SeniorityLevelID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Person]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Person_SeniorityLevelID ON [${flyway:defaultSchema}].[Person] ([SeniorityLevelID]);

-- Index for foreign key PersonID in table PersonJobFunction
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_PersonJobFunction_PersonID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[PersonJobFunction]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_PersonJobFunction_PersonID ON [${flyway:defaultSchema}].[PersonJobFunction] ([PersonID]);

-- Index for foreign key JobFunctionID in table PersonJobFunction
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_PersonJobFunction_JobFunctionID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[PersonJobFunction]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_PersonJobFunction_JobFunctionID ON [${flyway:defaultSchema}].[PersonJobFunction] ([JobFunctionID]);

