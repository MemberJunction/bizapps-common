-- =============================================================================================
-- PostgreSQL counterpart of V202611092335__v5.63.x__Metadata_Sync.sql
-- =============================================================================================
-- Same records, same values, same order as the T-SQL file; see its header for what ships, what is
-- held back, and why.
--
-- HOW IT WAS MADE: `mj sql-convert --from tsql --to postgres` (MJ CLI 6.2.1) on the T-SQL file.
-- Each record is a DO block that calls the function in whichever signature the host has (jsonb or
-- named parameters); the parameter inserts keep the T-SQL file's insert-or-update on the pinned ID.
-- Core references use ${mjSchema}. Every string value is the converter's output, unchanged.
-- =============================================================================================
-- Save MJ: Actions (core SP call only)
DO $mj$
DECLARE
  p_Description_b7d4acacfbdb TEXT;
  p_ID_b7d4acacfbdb UUID;
BEGIN
  p_Description_b7d4acacfbdb := 'Pull messages and calendar items for every Active-or-Error activity-sync connection and file the relevant ones as Activities. Downstream apps enrich in-stream via ActivitySyncExtension; they do not own this trigger. Idempotent: re-running over the same window writes nothing new. Run by hand with DryRun to preview what each connection would file, Paused connections included, without writing an Activity or moving a watermark.';
  p_ID_b7d4acacfbdb := 'B2CAEFB7-60FD-41FF-8B12-DB908A7BEF0E';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateAction'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateAction"(p_data := jsonb_build_object(
    'Description', p_Description_b7d4acacfbdb,
    'ID', p_ID_b7d4acacfbdb
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateAction"(p_Description := p_Description_b7d4acacfbdb, p_ID := p_ID_b7d4acacfbdb);
  END IF;
END $mj$;

-- Save MJ: Action Params (core SP call only)
DO $mj$
DECLARE
  p_ID_5933598cd3b0 UUID;
  p_ActionID_5933598cd3b0 UUID;
  p_Name_5933598cd3b0 VARCHAR(255);
  p_DefaultValue_5933598cd3b0 TEXT;
  p_Type_5933598cd3b0 CHAR(10);
  p_ValueType_5933598cd3b0 VARCHAR(30);
  p_IsArray_5933598cd3b0 BOOLEAN;
  p_Description_5933598cd3b0 TEXT;
  p_IsRequired_5933598cd3b0 BOOLEAN;
  p_MediaModality_5933598cd3b0 VARCHAR(20);
  p_LogValue_5933598cd3b0 BOOLEAN;
  p_ValueSchema_5933598cd3b0 TEXT;
BEGIN
  p_ID_5933598cd3b0 := '1C1BE8C0-CE21-41CA-9E92-D5A8523603F2';
  p_ActionID_5933598cd3b0 := 'B2CAEFB7-60FD-41FF-8B12-DB908A7BEF0E';
  p_Name_5933598cd3b0 := 'DryRun';
  p_DefaultValue_5933598cd3b0 := 'false';
  p_Type_5933598cd3b0 := 'Input';
  p_ValueType_5933598cd3b0 := 'Scalar';
  p_IsArray_5933598cd3b0 := FALSE;
  p_Description_5933598cd3b0 := 'true previews instead of writing: every item is fetched, qualified and resolved, and only the run and its per-item decisions (WouldInclude / WouldExclude) are saved. No Activity is written and no watermark moves. Paused connections are included, so a new mailbox can be built Paused and reviewed before it goes live. The hourly job leaves this false.';
  p_IsRequired_5933598cd3b0 := FALSE;
  p_LogValue_5933598cd3b0 := TRUE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."ActionParam" WHERE "ID" = p_ID_5933598cd3b0) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateActionParam'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateActionParam"(p_data := jsonb_build_object(
    'ID', p_ID_5933598cd3b0,
    'ActionID', p_ActionID_5933598cd3b0,
    'Name', p_Name_5933598cd3b0,
    'DefaultValue', p_DefaultValue_5933598cd3b0,
    'Type', p_Type_5933598cd3b0,
    'ValueType', p_ValueType_5933598cd3b0,
    'IsArray', p_IsArray_5933598cd3b0,
    'Description', p_Description_5933598cd3b0,
    'IsRequired', p_IsRequired_5933598cd3b0,
    'MediaModality', p_MediaModality_5933598cd3b0,
    'LogValue', p_LogValue_5933598cd3b0,
    'ValueSchema', p_ValueSchema_5933598cd3b0
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateActionParam"(p_ID := p_ID_5933598cd3b0, p_ActionID := p_ActionID_5933598cd3b0, p_Name := p_Name_5933598cd3b0, p_DefaultValue := p_DefaultValue_5933598cd3b0, p_Type := p_Type_5933598cd3b0, p_ValueType := p_ValueType_5933598cd3b0, p_IsArray := p_IsArray_5933598cd3b0, p_Description := p_Description_5933598cd3b0, p_IsRequired := p_IsRequired_5933598cd3b0, p_MediaModality := p_MediaModality_5933598cd3b0, p_MediaModality_Clear := TRUE, p_LogValue := p_LogValue_5933598cd3b0, p_ValueSchema := p_ValueSchema_5933598cd3b0, p_ValueSchema_Clear := TRUE);
    END IF;
  ELSE
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateActionParam'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spUpdateActionParam"(p_data := jsonb_build_object(
    'ID', p_ID_5933598cd3b0,
    'ActionID', p_ActionID_5933598cd3b0,
    'Name', p_Name_5933598cd3b0,
    'DefaultValue', p_DefaultValue_5933598cd3b0,
    'Type', p_Type_5933598cd3b0,
    'ValueType', p_ValueType_5933598cd3b0,
    'IsArray', p_IsArray_5933598cd3b0,
    'Description', p_Description_5933598cd3b0,
    'IsRequired', p_IsRequired_5933598cd3b0,
    'MediaModality', p_MediaModality_5933598cd3b0,
    'LogValue', p_LogValue_5933598cd3b0,
    'ValueSchema', p_ValueSchema_5933598cd3b0
  ));
    ELSE
      PERFORM "${mjSchema}"."spUpdateActionParam"(p_ID := p_ID_5933598cd3b0, p_ActionID := p_ActionID_5933598cd3b0, p_Name := p_Name_5933598cd3b0, p_DefaultValue := p_DefaultValue_5933598cd3b0, p_Type := p_Type_5933598cd3b0, p_ValueType := p_ValueType_5933598cd3b0, p_IsArray := p_IsArray_5933598cd3b0, p_Description := p_Description_5933598cd3b0, p_IsRequired := p_IsRequired_5933598cd3b0, p_MediaModality := p_MediaModality_5933598cd3b0, p_MediaModality_Clear := TRUE, p_LogValue := p_LogValue_5933598cd3b0, p_ValueSchema := p_ValueSchema_5933598cd3b0, p_ValueSchema_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Action Params (core SP call only)
DO $mj$
DECLARE
  p_ID_087fff4d8775 UUID;
  p_ActionID_087fff4d8775 UUID;
  p_Name_087fff4d8775 VARCHAR(255);
  p_DefaultValue_087fff4d8775 TEXT;
  p_Type_087fff4d8775 CHAR(10);
  p_ValueType_087fff4d8775 VARCHAR(30);
  p_IsArray_087fff4d8775 BOOLEAN;
  p_Description_087fff4d8775 TEXT;
  p_IsRequired_087fff4d8775 BOOLEAN;
  p_MediaModality_087fff4d8775 VARCHAR(20);
  p_LogValue_087fff4d8775 BOOLEAN;
  p_ValueSchema_087fff4d8775 TEXT;
BEGIN
  p_ID_087fff4d8775 := '66E97A11-5560-4C69-BA40-E71005474573';
  p_ActionID_087fff4d8775 := 'B2CAEFB7-60FD-41FF-8B12-DB908A7BEF0E';
  p_Name_087fff4d8775 := 'ConnectionIDs';
  p_Type_087fff4d8775 := 'Input';
  p_ValueType_087fff4d8775 := 'Scalar';
  p_IsArray_087fff4d8775 := FALSE;
  p_Description_087fff4d8775 := 'Optional comma-separated ActivitySyncConnection IDs. When set, only these connections run; each requested one that does not run (missing, Disabled, or Paused on a live run) is reported in Issues. Empty means every runnable connection.';
  p_IsRequired_087fff4d8775 := FALSE;
  p_LogValue_087fff4d8775 := TRUE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."ActionParam" WHERE "ID" = p_ID_087fff4d8775) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateActionParam'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateActionParam"(p_data := jsonb_build_object(
    'ID', p_ID_087fff4d8775,
    'ActionID', p_ActionID_087fff4d8775,
    'Name', p_Name_087fff4d8775,
    'DefaultValue', p_DefaultValue_087fff4d8775,
    'Type', p_Type_087fff4d8775,
    'ValueType', p_ValueType_087fff4d8775,
    'IsArray', p_IsArray_087fff4d8775,
    'Description', p_Description_087fff4d8775,
    'IsRequired', p_IsRequired_087fff4d8775,
    'MediaModality', p_MediaModality_087fff4d8775,
    'LogValue', p_LogValue_087fff4d8775,
    'ValueSchema', p_ValueSchema_087fff4d8775
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateActionParam"(p_ID := p_ID_087fff4d8775, p_ActionID := p_ActionID_087fff4d8775, p_Name := p_Name_087fff4d8775, p_DefaultValue := p_DefaultValue_087fff4d8775, p_DefaultValue_Clear := TRUE, p_Type := p_Type_087fff4d8775, p_ValueType := p_ValueType_087fff4d8775, p_IsArray := p_IsArray_087fff4d8775, p_Description := p_Description_087fff4d8775, p_IsRequired := p_IsRequired_087fff4d8775, p_MediaModality := p_MediaModality_087fff4d8775, p_MediaModality_Clear := TRUE, p_LogValue := p_LogValue_087fff4d8775, p_ValueSchema := p_ValueSchema_087fff4d8775, p_ValueSchema_Clear := TRUE);
    END IF;
  ELSE
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateActionParam'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spUpdateActionParam"(p_data := jsonb_build_object(
    'ID', p_ID_087fff4d8775,
    'ActionID', p_ActionID_087fff4d8775,
    'Name', p_Name_087fff4d8775,
    'DefaultValue', p_DefaultValue_087fff4d8775,
    'Type', p_Type_087fff4d8775,
    'ValueType', p_ValueType_087fff4d8775,
    'IsArray', p_IsArray_087fff4d8775,
    'Description', p_Description_087fff4d8775,
    'IsRequired', p_IsRequired_087fff4d8775,
    'MediaModality', p_MediaModality_087fff4d8775,
    'LogValue', p_LogValue_087fff4d8775,
    'ValueSchema', p_ValueSchema_087fff4d8775
  ));
    ELSE
      PERFORM "${mjSchema}"."spUpdateActionParam"(p_ID := p_ID_087fff4d8775, p_ActionID := p_ActionID_087fff4d8775, p_Name := p_Name_087fff4d8775, p_DefaultValue := p_DefaultValue_087fff4d8775, p_DefaultValue_Clear := TRUE, p_Type := p_Type_087fff4d8775, p_ValueType := p_ValueType_087fff4d8775, p_IsArray := p_IsArray_087fff4d8775, p_Description := p_Description_087fff4d8775, p_IsRequired := p_IsRequired_087fff4d8775, p_MediaModality := p_MediaModality_087fff4d8775, p_MediaModality_Clear := TRUE, p_LogValue := p_LogValue_087fff4d8775, p_ValueSchema := p_ValueSchema_087fff4d8775, p_ValueSchema_Clear := TRUE);
    END IF;
  END IF;
END $mj$;
