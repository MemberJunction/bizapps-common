-- =============================================================================================
-- PostgreSQL counterpart of V202611032053__v5.59.x__Metadata_Sync.sql -- BizApps Common v5.59.x Metadata_Sync
-- =============================================================================================
-- Same records, same values, same order as the T-SQL file; see its header for what ships and why.
--
-- HOW IT WAS MADE
--   * `mj sql-convert --from tsql --to postgres` (MJ CLI 6.1.6) on the push log the T-SQL file was
--     generated from, held-back records removed as in the T-SQL file. Each record is a DO block that calls the function in whichever
--     signature the host has (jsonb or named parameters).
--   * The converter does not translate the lookups and guards the T-SQL file adds, so they are
--     written here by hand from the T-SQL ones, block for block:
--       - SELECT TOP 1 @x = [ID] ... ORDER BY ... becomes
--         p_x := COALESCE((SELECT "ID" ... ORDER BY ... LIMIT 1), p_x), which keeps the literal
--         ID when nothing matches, as the T-SQL assignment does.
--       - IF <guard> EXEC ... becomes IF <guard> THEN <call> END IF.
--   * Core calls use ${mjSchema}.
--   * Every string value is taken verbatim from the T-SQL file.
-- =============================================================================================

-- Save MJ: Entity Permissions (core SP call only)
DO $mj$
DECLARE
  p_EntityID_4df655f70c78 UUID;
  p_RoleID_4df655f70c78 UUID;
  p_CanCreate_4df655f70c78 BOOLEAN;
  p_CanRead_4df655f70c78 BOOLEAN;
  p_CanUpdate_4df655f70c78 BOOLEAN;
  p_CanDelete_4df655f70c78 BOOLEAN;
  p_ReadRLSFilterID_4df655f70c78 UUID;
  p_CreateRLSFilterID_4df655f70c78 UUID;
  p_UpdateRLSFilterID_4df655f70c78 UUID;
  p_DeleteRLSFilterID_4df655f70c78 UUID;
  p_Type_4df655f70c78 VARCHAR(10);
  p_ID_4df655f70c78 UUID;
BEGIN
  p_EntityID_4df655f70c78 := '72E55425-8822-4E70-A075-116219CA5A5D';
  p_RoleID_4df655f70c78 := 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E';
  p_CanCreate_4df655f70c78 := TRUE;
  p_CanRead_4df655f70c78 := TRUE;
  p_CanUpdate_4df655f70c78 := FALSE;
  p_CanDelete_4df655f70c78 := FALSE;
  p_Type_4df655f70c78 := 'Allow';
  p_ID_4df655f70c78 := '61D0423E-F36B-1410-8489-00031FE78EB9';
  p_ID_4df655f70c78 := COALESCE((SELECT "ID" FROM "${mjSchema}"."EntityPermission" WHERE "EntityID" = p_EntityID_4df655f70c78 AND "RoleID" = p_RoleID_4df655f70c78 ORDER BY CASE WHEN "ID" = p_ID_4df655f70c78 THEN 0 ELSE 1 END LIMIT 1), p_ID_4df655f70c78);
  IF EXISTS (SELECT 1 FROM "${mjSchema}"."EntityPermission" WHERE "ID" = p_ID_4df655f70c78) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityPermission'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spUpdateEntityPermission"(p_data := jsonb_build_object(
      'EntityID', p_EntityID_4df655f70c78,
      'RoleID', p_RoleID_4df655f70c78,
      'CanCreate', p_CanCreate_4df655f70c78,
      'CanRead', p_CanRead_4df655f70c78,
      'CanUpdate', p_CanUpdate_4df655f70c78,
      'CanDelete', p_CanDelete_4df655f70c78,
      'ReadRLSFilterID', p_ReadRLSFilterID_4df655f70c78,
      'CreateRLSFilterID', p_CreateRLSFilterID_4df655f70c78,
      'UpdateRLSFilterID', p_UpdateRLSFilterID_4df655f70c78,
      'DeleteRLSFilterID', p_DeleteRLSFilterID_4df655f70c78,
      'Type', p_Type_4df655f70c78,
      'ID', p_ID_4df655f70c78
    ));
    ELSE
      PERFORM "${mjSchema}"."spUpdateEntityPermission"(p_EntityID := p_EntityID_4df655f70c78, p_RoleID := p_RoleID_4df655f70c78, p_CanCreate := p_CanCreate_4df655f70c78, p_CanRead := p_CanRead_4df655f70c78, p_CanUpdate := p_CanUpdate_4df655f70c78, p_CanDelete := p_CanDelete_4df655f70c78, p_ReadRLSFilterID := p_ReadRLSFilterID_4df655f70c78, p_ReadRLSFilterID_Clear := TRUE, p_CreateRLSFilterID := p_CreateRLSFilterID_4df655f70c78, p_CreateRLSFilterID_Clear := TRUE, p_UpdateRLSFilterID := p_UpdateRLSFilterID_4df655f70c78, p_UpdateRLSFilterID_Clear := TRUE, p_DeleteRLSFilterID := p_DeleteRLSFilterID_4df655f70c78, p_DeleteRLSFilterID_Clear := TRUE, p_Type := p_Type_4df655f70c78, p_ID := p_ID_4df655f70c78);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Entity Permissions (core SP call only)
DO $mj$
DECLARE
  p_EntityID_211b18e02f74 UUID;
  p_RoleID_211b18e02f74 UUID;
  p_CanCreate_211b18e02f74 BOOLEAN;
  p_CanRead_211b18e02f74 BOOLEAN;
  p_CanUpdate_211b18e02f74 BOOLEAN;
  p_CanDelete_211b18e02f74 BOOLEAN;
  p_ReadRLSFilterID_211b18e02f74 UUID;
  p_CreateRLSFilterID_211b18e02f74 UUID;
  p_UpdateRLSFilterID_211b18e02f74 UUID;
  p_DeleteRLSFilterID_211b18e02f74 UUID;
  p_Type_211b18e02f74 VARCHAR(10);
  p_ID_211b18e02f74 UUID;
BEGIN
  p_EntityID_211b18e02f74 := '9C48DF77-E4A1-4ADB-AABF-916F5798B894';
  p_RoleID_211b18e02f74 := 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E';
  p_CanCreate_211b18e02f74 := TRUE;
  p_CanRead_211b18e02f74 := TRUE;
  p_CanUpdate_211b18e02f74 := FALSE;
  p_CanDelete_211b18e02f74 := FALSE;
  p_Type_211b18e02f74 := 'Allow';
  p_ID_211b18e02f74 := '72D0423E-F36B-1410-8489-00031FE78EB9';
  p_ID_211b18e02f74 := COALESCE((SELECT "ID" FROM "${mjSchema}"."EntityPermission" WHERE "EntityID" = p_EntityID_211b18e02f74 AND "RoleID" = p_RoleID_211b18e02f74 ORDER BY CASE WHEN "ID" = p_ID_211b18e02f74 THEN 0 ELSE 1 END LIMIT 1), p_ID_211b18e02f74);
  IF EXISTS (SELECT 1 FROM "${mjSchema}"."EntityPermission" WHERE "ID" = p_ID_211b18e02f74) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityPermission'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spUpdateEntityPermission"(p_data := jsonb_build_object(
      'EntityID', p_EntityID_211b18e02f74,
      'RoleID', p_RoleID_211b18e02f74,
      'CanCreate', p_CanCreate_211b18e02f74,
      'CanRead', p_CanRead_211b18e02f74,
      'CanUpdate', p_CanUpdate_211b18e02f74,
      'CanDelete', p_CanDelete_211b18e02f74,
      'ReadRLSFilterID', p_ReadRLSFilterID_211b18e02f74,
      'CreateRLSFilterID', p_CreateRLSFilterID_211b18e02f74,
      'UpdateRLSFilterID', p_UpdateRLSFilterID_211b18e02f74,
      'DeleteRLSFilterID', p_DeleteRLSFilterID_211b18e02f74,
      'Type', p_Type_211b18e02f74,
      'ID', p_ID_211b18e02f74
    ));
    ELSE
      PERFORM "${mjSchema}"."spUpdateEntityPermission"(p_EntityID := p_EntityID_211b18e02f74, p_RoleID := p_RoleID_211b18e02f74, p_CanCreate := p_CanCreate_211b18e02f74, p_CanRead := p_CanRead_211b18e02f74, p_CanUpdate := p_CanUpdate_211b18e02f74, p_CanDelete := p_CanDelete_211b18e02f74, p_ReadRLSFilterID := p_ReadRLSFilterID_211b18e02f74, p_ReadRLSFilterID_Clear := TRUE, p_CreateRLSFilterID := p_CreateRLSFilterID_211b18e02f74, p_CreateRLSFilterID_Clear := TRUE, p_UpdateRLSFilterID := p_UpdateRLSFilterID_211b18e02f74, p_UpdateRLSFilterID_Clear := TRUE, p_DeleteRLSFilterID := p_DeleteRLSFilterID_211b18e02f74, p_DeleteRLSFilterID_Clear := TRUE, p_Type := p_Type_211b18e02f74, p_ID := p_ID_211b18e02f74);
    END IF;
  END IF;
END $mj$;
