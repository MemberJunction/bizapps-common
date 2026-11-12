-- =============================================================================================
-- PostgreSQL counterpart of V202611120330__v5.65.x__Metadata_Sync.sql
-- =============================================================================================
-- Same record, same value as the T-SQL file; see its header for what ships and why.
--
-- HOW IT WAS MADE: `mj sql-convert --from tsql --to postgres` (MJ CLI 6.2.1) on the push log's one
-- block, wrapped so it runs only when the record process exists. The ScopeFilter string is the T-SQL
-- file's, verbatim. Core references use ${mjSchema}.
-- =============================================================================================

-- Save MJ: Record Processes (core SP call only)
DO $mj$
DECLARE
  p_ScopeFilter_e9579a894e19 TEXT;
  p_ID_e9579a894e19 UUID;
BEGIN
  p_ScopeFilter_e9579a894e19 := 'CurrentJobTitle IS NOT NULL AND (SeniorityLevelID IS NULL OR ID NOT IN (SELECT PersonID FROM [${flyway:defaultSchema}].[vwPersonJobFunctions]))';
  p_ID_e9579a894e19 := '7E030001-A101-4B01-8C01-000000000001';
  IF EXISTS (SELECT 1 FROM "${mjSchema}"."RecordProcess" WHERE "ID" = p_ID_e9579a894e19) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateRecordProcess'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spUpdateRecordProcess"(p_data := jsonb_build_object(
      'ScopeFilter', p_ScopeFilter_e9579a894e19,
      'ID', p_ID_e9579a894e19
    ));
    ELSE
      PERFORM "${mjSchema}"."spUpdateRecordProcess"(p_ScopeFilter := p_ScopeFilter_e9579a894e19, p_ID := p_ID_e9579a894e19);
    END IF;
  END IF;
END $mj$;
