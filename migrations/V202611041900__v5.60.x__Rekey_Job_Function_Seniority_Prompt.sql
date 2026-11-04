-- =============================================================================
-- Migration: V202611041900__v5.60.x__Rekey_Job_Function_Seniority_Prompt.sql
-- Description: Move common's AI Prompt "Job Function and Seniority Derivation" from
--              7C46041F-0412-4C2E-9B9E-3ED61D32210C to its own ID, 19736B1D-923B-4BB7-AAE8-9A98D9B25C1E.
--
-- WHY. Common (5.47+) and MJ 6.2 both seeded an AI Prompt with the ID 7C46041F. On a host that
-- installed common on MJ 6.1.x and then migrates MJ to 6.2.0, MJ's
-- V202609221852__v6.2.x__Metadata_Sync.sql inserts AI Prompt Model 29E25958 with the same
-- (PromptID, ModelID, VendorID, ConfigurationID) as common's FE550867, fails on
-- UQ_AIPromptModel_Prompt_Model_Vendor_ConfigID and stops the MJ upgrade. Getting past that by hand
-- is worse: MJ's V202610022141 then runs spDeleteAIPrompt on 7C46041F and deletes common's prompt.
-- Once common's prompt lives under its own ID, MJ creates and later deletes only its own copy.
-- See bizapps-common#408 and MemberJunction/MJ#4939.
--
-- WHOSE ROW. When this runs, 7C46041F is common's on every install path: on MJ 6.1.x hosts MJ never
-- seeded it, and on hosts that migrated MJ to 6.2 first, V202610022141 deleted MJ's copy before
-- common's V202609282100 created this one. Where it does not exist, every statement below touches no
-- rows.
--
-- SCHEMA-INDEPENDENT. The host may run this on an MJ 6.1.x schema (the normal upgrade path: install
-- this release first, then migrate MJ) or on an MJ 6.2.x schema (MJ was migrated first). So the
-- prompt copy and the repoint read the column list and the foreign keys from the catalog instead of
-- naming them. Every foreign key to AIPrompt is NO ACTION, so the final DELETE fails, and the whole
-- migration rolls back, if any reference was missed. Nothing can be orphaned.
-- =============================================================================
SET XACT_ABORT ON;

DECLARE @OldID UNIQUEIDENTIFIER = '7C46041F-0412-4C2E-9B9E-3ED61D32210C';
DECLARE @NewID UNIQUEIDENTIFIER = '19736B1D-923B-4BB7-AAE8-9A98D9B25C1E';
DECLARE @PipelineRecordProcessID UNIQUEIDENTIFIER = '7E030001-A101-4B01-8C01-000000000001';
DECLARE @MJSchema SYSNAME = N'${mjSchema}';
DECLARE @PromptTable NVARCHAR(300) = QUOTENAME(@MJSchema) + N'.' + QUOTENAME(N'AIPrompt');
DECLARE @SQL NVARCHAR(MAX);

-- 1. Copy the prompt row to the new ID. Every stored column except ID and the __mj_ timestamps is
--    copied, so the copy is exact on any MJ schema version.
DECLARE @Columns NVARCHAR(MAX);
SELECT @Columns = STRING_AGG(CAST(QUOTENAME(c.name) AS NVARCHAR(MAX)), N', ') WITHIN GROUP (ORDER BY c.column_id)
  FROM sys.columns c
 WHERE c.object_id = OBJECT_ID(@PromptTable)
   AND c.is_computed = 0
   AND c.name <> N'ID'
   AND c.name NOT LIKE N'[_][_]mj[_]%';

SET @SQL = N'
INSERT INTO ' + @PromptTable + N' (ID, ' + @Columns + N')
SELECT @NewID, ' + @Columns + N' FROM ' + @PromptTable + N' WHERE ID = @OldID;';
EXEC sp_executesql @SQL, N'@OldID UNIQUEIDENTIFIER, @NewID UNIQUEIDENTIFIER', @OldID = @OldID, @NewID = @NewID;

-- 2. Repoint every foreign-key column that references AIPrompt (22 on MJ 6.1.6; more on 6.2).
--    On a normal host only AIPromptModel FE550867 and Record Process 7E030001-...-0001 match.
DECLARE @RefTable NVARCHAR(300), @RefColumn SYSNAME;
DECLARE FKRefs CURSOR LOCAL FAST_FORWARD FOR
    SELECT QUOTENAME(OBJECT_SCHEMA_NAME(fkc.parent_object_id)) + N'.' + QUOTENAME(OBJECT_NAME(fkc.parent_object_id)),
           COL_NAME(fkc.parent_object_id, fkc.parent_column_id)
      FROM sys.foreign_key_columns fkc
     WHERE fkc.referenced_object_id = OBJECT_ID(@PromptTable);
OPEN FKRefs;
FETCH NEXT FROM FKRefs INTO @RefTable, @RefColumn;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = N'UPDATE ' + @RefTable + N' SET ' + QUOTENAME(@RefColumn) + N' = @NewID WHERE ' + QUOTENAME(@RefColumn) + N' = @OldID;';
    EXEC sp_executesql @SQL, N'@OldID UNIQUEIDENTIFIER, @NewID UNIQUEIDENTIFIER', @OldID = @OldID, @NewID = @NewID;
    FETCH NEXT FROM FKRefs INTO @RefTable, @RefColumn;
END
CLOSE FKRefs;
DEALLOCATE FKRefs;

-- 3. The job-function pipeline also carries the prompt ID inside its Configuration JSON, which the
--    feature-pipeline runner reads instead of the PromptID column.
SET @SQL = N'
UPDATE ' + QUOTENAME(@MJSchema) + N'.[RecordProcess]
   SET Configuration = REPLACE(Configuration, @OldText, @NewText)
 WHERE ID = @RecordProcessID;';
EXEC sp_executesql @SQL,
    N'@OldText NVARCHAR(100), @NewText NVARCHAR(100), @RecordProcessID UNIQUEIDENTIFIER',
    @OldText = N'"PromptID":"7C46041F-0412-4C2E-9B9E-3ED61D32210C"',
    @NewText = N'"PromptID":"19736B1D-923B-4BB7-AAE8-9A98D9B25C1E"',
    @RecordProcessID = @PipelineRecordProcessID;

-- 4. Remove the old row. A plain DELETE, not spDeleteAIPrompt: that sproc cascades into the
--    prompt's models and runs, which now belong to the new ID.
SET @SQL = N'DELETE FROM ' + @PromptTable + N' WHERE ID = @OldID;';
EXEC sp_executesql @SQL, N'@OldID UNIQUEIDENTIFIER', @OldID = @OldID;
GO
