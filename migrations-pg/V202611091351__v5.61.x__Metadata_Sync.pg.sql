-- =============================================================================================
-- PostgreSQL counterpart of V202611091351__v5.61.x__Metadata_Sync.sql
-- =============================================================================================
-- Same records, same values, same order as the T-SQL file; see its header for what ships, what is
-- held back, and why.
--
-- HOW IT WAS MADE
--   * `mj sql-convert --from tsql --to postgres` (MJ CLI 6.1.6) on the push log the T-SQL file was
--     generated from, held-back records removed as in the T-SQL file. Each record is a DO block that
--     calls the function in whichever signature the host has (jsonb or named parameters).
--   * The converter does not translate the lookups and guards the T-SQL file adds, so they are
--     written here by hand from the T-SQL ones, block for block:
--       - SELECT TOP 1 @x = [ID] ... ORDER BY ... becomes
--         p_x := COALESCE((SELECT "ID" ... ORDER BY ... LIMIT 1), p_x), which keeps the literal
--         ID when nothing matches, as the T-SQL assignment does.
--       - IF <guard> EXEC ... becomes IF <guard> THEN <call> END IF.
--   * Core calls use ${mjSchema}; signature checks name this app's schema in lowercase, as
--     PostgreSQL stores it.
--   * Every string value is taken verbatim from the T-SQL file.
--   * People's update keeps the host's EnableFieldLevelSecurity, as the T-SQL file does: the value is
--     read from the host's Entity row before the call.
-- =============================================================================================

-- Save MJ_BizApps_Common: Contact Types (core SP call only)
DO $mj$
DECLARE
  p_Name_8d6ff8b21659 VARCHAR(100);
  p_Description_8d6ff8b21659 TEXT;
  p_IconClass_8d6ff8b21659 VARCHAR(100);
  p_DisplayRank_8d6ff8b21659 INTEGER;
  p_IsActive_8d6ff8b21659 BOOLEAN;
  p_CommunicationBaseMessageTypeID_8d6ff8b21659 UUID;
  p_ID_8d6ff8b21659 UUID;
BEGIN
  p_Name_8d6ff8b21659 := 'Email';
  p_Description_8d6ff8b21659 := 'Email address';
  p_IconClass_8d6ff8b21659 := 'fa-solid fa-envelope';
  p_DisplayRank_8d6ff8b21659 := 10;
  p_IsActive_8d6ff8b21659 := TRUE;
  p_CommunicationBaseMessageTypeID_8d6ff8b21659 := 'F9A5CCEC-6A37-EF11-86D4-000D3A4E707E';
  p_ID_8d6ff8b21659 := 'FB4D3737-8479-44E5-AF91-2DB63311D293';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '__mj_bizappscommon' AND p.proname = 'spUpdateContactType'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM __mj_BizAppsCommon."spUpdateContactType"(p_data := jsonb_build_object(
    'Name', p_Name_8d6ff8b21659,
    'Description', p_Description_8d6ff8b21659,
    'IconClass', p_IconClass_8d6ff8b21659,
    'DisplayRank', p_DisplayRank_8d6ff8b21659,
    'IsActive', p_IsActive_8d6ff8b21659,
    'CommunicationBaseMessageTypeID', p_CommunicationBaseMessageTypeID_8d6ff8b21659,
    'ID', p_ID_8d6ff8b21659
  ));
  ELSE
    PERFORM __mj_BizAppsCommon."spUpdateContactType"(p_Name := p_Name_8d6ff8b21659, p_Description := p_Description_8d6ff8b21659, p_IconClass := p_IconClass_8d6ff8b21659, p_DisplayRank := p_DisplayRank_8d6ff8b21659, p_IsActive := p_IsActive_8d6ff8b21659, p_CommunicationBaseMessageTypeID := p_CommunicationBaseMessageTypeID_8d6ff8b21659, p_ID := p_ID_8d6ff8b21659);
  END IF;
END $mj$;

-- Save MJ_BizApps_Common: Contact Types (core SP call only)
DO $mj$
DECLARE
  p_Name_4abdc72b35b4 VARCHAR(100);
  p_Description_4abdc72b35b4 TEXT;
  p_IconClass_4abdc72b35b4 VARCHAR(100);
  p_DisplayRank_4abdc72b35b4 INTEGER;
  p_IsActive_4abdc72b35b4 BOOLEAN;
  p_CommunicationBaseMessageTypeID_4abdc72b35b4 UUID;
  p_ID_4abdc72b35b4 UUID;
BEGIN
  p_Name_4abdc72b35b4 := 'Mobile Phone';
  p_Description_4abdc72b35b4 := 'Mobile or cell phone number';
  p_IconClass_4abdc72b35b4 := 'fa-solid fa-mobile-screen';
  p_DisplayRank_4abdc72b35b4 := 20;
  p_IsActive_4abdc72b35b4 := TRUE;
  p_CommunicationBaseMessageTypeID_4abdc72b35b4 := 'FAA5CCEC-6A37-EF11-86D4-000D3A4E707E';
  p_ID_4abdc72b35b4 := '96421246-0F8F-4CDB-A5C5-BA6B190C1AFE';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '__mj_bizappscommon' AND p.proname = 'spUpdateContactType'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM __mj_BizAppsCommon."spUpdateContactType"(p_data := jsonb_build_object(
    'Name', p_Name_4abdc72b35b4,
    'Description', p_Description_4abdc72b35b4,
    'IconClass', p_IconClass_4abdc72b35b4,
    'DisplayRank', p_DisplayRank_4abdc72b35b4,
    'IsActive', p_IsActive_4abdc72b35b4,
    'CommunicationBaseMessageTypeID', p_CommunicationBaseMessageTypeID_4abdc72b35b4,
    'ID', p_ID_4abdc72b35b4
  ));
  ELSE
    PERFORM __mj_BizAppsCommon."spUpdateContactType"(p_Name := p_Name_4abdc72b35b4, p_Description := p_Description_4abdc72b35b4, p_IconClass := p_IconClass_4abdc72b35b4, p_DisplayRank := p_DisplayRank_4abdc72b35b4, p_IsActive := p_IsActive_4abdc72b35b4, p_CommunicationBaseMessageTypeID := p_CommunicationBaseMessageTypeID_4abdc72b35b4, p_ID := p_ID_4abdc72b35b4);
  END IF;
END $mj$;

-- Save MJ_BizApps_Common: Contact Types (core SP call only)
DO $mj$
DECLARE
  p_Name_127d4af5ce17 VARCHAR(100);
  p_Description_127d4af5ce17 TEXT;
  p_IconClass_127d4af5ce17 VARCHAR(100);
  p_DisplayRank_127d4af5ce17 INTEGER;
  p_IsActive_127d4af5ce17 BOOLEAN;
  p_CommunicationBaseMessageTypeID_127d4af5ce17 UUID;
  p_ID_127d4af5ce17 UUID;
BEGIN
  p_Name_127d4af5ce17 := 'Work Phone';
  p_Description_127d4af5ce17 := 'Business or office phone number';
  p_IconClass_127d4af5ce17 := 'fa-solid fa-phone-office';
  p_DisplayRank_127d4af5ce17 := 30;
  p_IsActive_127d4af5ce17 := TRUE;
  p_CommunicationBaseMessageTypeID_127d4af5ce17 := 'FAA5CCEC-6A37-EF11-86D4-000D3A4E707E';
  p_ID_127d4af5ce17 := 'BCDA98AC-06A4-40FC-A1CC-E44BB783FBC9';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '__mj_bizappscommon' AND p.proname = 'spUpdateContactType'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM __mj_BizAppsCommon."spUpdateContactType"(p_data := jsonb_build_object(
    'Name', p_Name_127d4af5ce17,
    'Description', p_Description_127d4af5ce17,
    'IconClass', p_IconClass_127d4af5ce17,
    'DisplayRank', p_DisplayRank_127d4af5ce17,
    'IsActive', p_IsActive_127d4af5ce17,
    'CommunicationBaseMessageTypeID', p_CommunicationBaseMessageTypeID_127d4af5ce17,
    'ID', p_ID_127d4af5ce17
  ));
  ELSE
    PERFORM __mj_BizAppsCommon."spUpdateContactType"(p_Name := p_Name_127d4af5ce17, p_Description := p_Description_127d4af5ce17, p_IconClass := p_IconClass_127d4af5ce17, p_DisplayRank := p_DisplayRank_127d4af5ce17, p_IsActive := p_IsActive_127d4af5ce17, p_CommunicationBaseMessageTypeID := p_CommunicationBaseMessageTypeID_127d4af5ce17, p_ID := p_ID_127d4af5ce17);
  END IF;
END $mj$;

-- Save MJ_BizApps_Common: Contact Types (core SP call only)
DO $mj$
DECLARE
  p_Name_929c97838cb6 VARCHAR(100);
  p_Description_929c97838cb6 TEXT;
  p_IconClass_929c97838cb6 VARCHAR(100);
  p_DisplayRank_929c97838cb6 INTEGER;
  p_IsActive_929c97838cb6 BOOLEAN;
  p_CommunicationBaseMessageTypeID_929c97838cb6 UUID;
  p_ID_929c97838cb6 UUID;
BEGIN
  p_Name_929c97838cb6 := 'Home Phone';
  p_Description_929c97838cb6 := 'Residential phone number';
  p_IconClass_929c97838cb6 := 'fa-solid fa-phone';
  p_DisplayRank_929c97838cb6 := 40;
  p_IsActive_929c97838cb6 := TRUE;
  p_CommunicationBaseMessageTypeID_929c97838cb6 := 'FAA5CCEC-6A37-EF11-86D4-000D3A4E707E';
  p_ID_929c97838cb6 := 'C3BA9432-8D05-4AFE-BF6D-61F976A466E6';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '__mj_bizappscommon' AND p.proname = 'spUpdateContactType'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM __mj_BizAppsCommon."spUpdateContactType"(p_data := jsonb_build_object(
    'Name', p_Name_929c97838cb6,
    'Description', p_Description_929c97838cb6,
    'IconClass', p_IconClass_929c97838cb6,
    'DisplayRank', p_DisplayRank_929c97838cb6,
    'IsActive', p_IsActive_929c97838cb6,
    'CommunicationBaseMessageTypeID', p_CommunicationBaseMessageTypeID_929c97838cb6,
    'ID', p_ID_929c97838cb6
  ));
  ELSE
    PERFORM __mj_BizAppsCommon."spUpdateContactType"(p_Name := p_Name_929c97838cb6, p_Description := p_Description_929c97838cb6, p_IconClass := p_IconClass_929c97838cb6, p_DisplayRank := p_DisplayRank_929c97838cb6, p_IsActive := p_IsActive_929c97838cb6, p_CommunicationBaseMessageTypeID := p_CommunicationBaseMessageTypeID_929c97838cb6, p_ID := p_ID_929c97838cb6);
  END IF;
END $mj$;

-- Save MJ_BizApps_Common: Consent Purposes (core SP call only)
DO $mj$
DECLARE
  p_ID_bf6bc78334e5 UUID;
  p_Name_bf6bc78334e5 VARCHAR(100);
  p_Description_bf6bc78334e5 TEXT;
  p_Sequence_bf6bc78334e5 INTEGER;
  p_IsActive_bf6bc78334e5 BOOLEAN;
BEGIN
  p_ID_bf6bc78334e5 := '960DC81B-D57E-4851-96AD-B534EBB6C426';
  p_Name_bf6bc78334e5 := 'Marketing';
  p_Description_bf6bc78334e5 := 'Promotional and informational messages: newsletters, offers, announcements.';
  p_Sequence_bf6bc78334e5 := 10;
  p_IsActive_bf6bc78334e5 := TRUE;
  IF NOT EXISTS (SELECT 1 FROM ${flyway:defaultSchema}."ConsentPurpose"
               WHERE "ID" = p_ID_bf6bc78334e5
                  OR "Name" = p_Name_bf6bc78334e5) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '__mj_bizappscommon' AND p.proname = 'spCreateConsentPurpose'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM __mj_BizAppsCommon."spCreateConsentPurpose"(p_data := jsonb_build_object(
      'ID', p_ID_bf6bc78334e5,
      'Name', p_Name_bf6bc78334e5,
      'Description', p_Description_bf6bc78334e5,
      'Sequence', p_Sequence_bf6bc78334e5,
      'IsActive', p_IsActive_bf6bc78334e5
    ));
    ELSE
      PERFORM __mj_BizAppsCommon."spCreateConsentPurpose"(p_ID := p_ID_bf6bc78334e5, p_Name := p_Name_bf6bc78334e5, p_Description := p_Description_bf6bc78334e5, p_Sequence := p_Sequence_bf6bc78334e5, p_IsActive := p_IsActive_bf6bc78334e5);
    END IF;
  END IF;
END $mj$;

-- Save MJ_BizApps_Common: Consent Purposes (core SP call only)
DO $mj$
DECLARE
  p_ID_7084f6d02bd4 UUID;
  p_Name_7084f6d02bd4 VARCHAR(100);
  p_Description_7084f6d02bd4 TEXT;
  p_Sequence_7084f6d02bd4 INTEGER;
  p_IsActive_7084f6d02bd4 BOOLEAN;
BEGIN
  p_ID_7084f6d02bd4 := '41C807B6-EB29-45A4-84EC-5796513768DC';
  p_Name_7084f6d02bd4 := 'Transactional';
  p_Description_7084f6d02bd4 := 'Messages about something the person did or owns: receipts, confirmations, reminders.';
  p_Sequence_7084f6d02bd4 := 20;
  p_IsActive_7084f6d02bd4 := TRUE;
  IF NOT EXISTS (SELECT 1 FROM ${flyway:defaultSchema}."ConsentPurpose"
               WHERE "ID" = p_ID_7084f6d02bd4
                  OR "Name" = p_Name_7084f6d02bd4) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '__mj_bizappscommon' AND p.proname = 'spCreateConsentPurpose'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM __mj_BizAppsCommon."spCreateConsentPurpose"(p_data := jsonb_build_object(
      'ID', p_ID_7084f6d02bd4,
      'Name', p_Name_7084f6d02bd4,
      'Description', p_Description_7084f6d02bd4,
      'Sequence', p_Sequence_7084f6d02bd4,
      'IsActive', p_IsActive_7084f6d02bd4
    ));
    ELSE
      PERFORM __mj_BizAppsCommon."spCreateConsentPurpose"(p_ID := p_ID_7084f6d02bd4, p_Name := p_Name_7084f6d02bd4, p_Description := p_Description_7084f6d02bd4, p_Sequence := p_Sequence_7084f6d02bd4, p_IsActive := p_IsActive_7084f6d02bd4);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Entities (core SP call only)
DO $mj$
DECLARE
  p_ParentID_45b6224f94d8 UUID;
  p_Name_45b6224f94d8 VARCHAR(255);
  p_NameSuffix_45b6224f94d8 VARCHAR(255);
  p_Description_45b6224f94d8 TEXT;
  p_AutoUpdateDescription_45b6224f94d8 BOOLEAN;
  p_BaseView_45b6224f94d8 VARCHAR(255);
  p_BaseViewGenerated_45b6224f94d8 BOOLEAN;
  p_VirtualEntity_45b6224f94d8 BOOLEAN;
  p_TrackRecordChanges_45b6224f94d8 BOOLEAN;
  p_AuditRecordAccess_45b6224f94d8 BOOLEAN;
  p_AuditViewRuns_45b6224f94d8 BOOLEAN;
  p_IncludeInAPI_45b6224f94d8 BOOLEAN;
  p_AllowAllRowsAPI_45b6224f94d8 BOOLEAN;
  p_AllowUpdateAPI_45b6224f94d8 BOOLEAN;
  p_AllowCreateAPI_45b6224f94d8 BOOLEAN;
  p_AllowDeleteAPI_45b6224f94d8 BOOLEAN;
  p_CustomResolverAPI_45b6224f94d8 BOOLEAN;
  p_AllowUserSearchAPI_45b6224f94d8 BOOLEAN;
  p_FullTextSearchEnabled_45b6224f94d8 BOOLEAN;
  p_FullTextCatalog_45b6224f94d8 VARCHAR(255);
  p_FullTextCatalogGenerated_45b6224f94d8 BOOLEAN;
  p_FullTextIndex_45b6224f94d8 VARCHAR(255);
  p_FullTextIndexGenerated_45b6224f94d8 BOOLEAN;
  p_FullTextSearchFunction_45b6224f94d8 VARCHAR(255);
  p_FullTextSearchFunctionGenerated_45b6224f94d8 BOOLEAN;
  p_UserViewMaxRows_45b6224f94d8 INTEGER;
  p_spCreate_45b6224f94d8 VARCHAR(255);
  p_spUpdate_45b6224f94d8 VARCHAR(255);
  p_spDelete_45b6224f94d8 VARCHAR(255);
  p_spCreateGenerated_45b6224f94d8 BOOLEAN;
  p_spUpdateGenerated_45b6224f94d8 BOOLEAN;
  p_spDeleteGenerated_45b6224f94d8 BOOLEAN;
  p_CascadeDeletes_45b6224f94d8 BOOLEAN;
  p_DeleteType_45b6224f94d8 VARCHAR(10);
  p_AllowRecordMerge_45b6224f94d8 BOOLEAN;
  p_spMatch_45b6224f94d8 VARCHAR(255);
  p_RelationshipDefaultDisplayType_45b6224f94d8 VARCHAR(20);
  p_UserFormGenerated_45b6224f94d8 BOOLEAN;
  p_EntityObjectSubclassName_45b6224f94d8 VARCHAR(255);
  p_EntityObjectSubclassImport_45b6224f94d8 VARCHAR(255);
  p_PreferredCommunicationField_45b6224f94d8 VARCHAR(255);
  p_Icon_45b6224f94d8 VARCHAR(500);
  p_ScopeDefault_45b6224f94d8 VARCHAR(100);
  p_RowsToPackWithSchema_45b6224f94d8 VARCHAR(20);
  p_RowsToPackSampleMethod_45b6224f94d8 VARCHAR(20);
  p_RowsToPackSampleCount_45b6224f94d8 INTEGER;
  p_RowsToPackSampleOrder_45b6224f94d8 TEXT;
  p_AutoRowCountFrequency_45b6224f94d8 INTEGER;
  p_RowCount_45b6224f94d8 BIGINT;
  p_RowCountRunAt_45b6224f94d8 TIMESTAMPTZ;
  p_Status_45b6224f94d8 VARCHAR(25);
  p_DisplayName_45b6224f94d8 VARCHAR(255);
  p_AllowMultipleSubtypes_45b6224f94d8 BOOLEAN;
  p_AutoUpdateFullTextSearch_45b6224f94d8 BOOLEAN;
  p_AutoUpdateAllowUserSearchAPI_45b6224f94d8 BOOLEAN;
  p_TrustServerCacheCompletely_45b6224f94d8 BOOLEAN;
  p_SupportsGeoCoding_45b6224f94d8 BOOLEAN;
  p_AutoUpdateSupportsGeoCoding_45b6224f94d8 BOOLEAN;
  p_AllowCaching_45b6224f94d8 BOOLEAN;
  p_DetectExternalChanges_45b6224f94d8 BOOLEAN;
  p_ExternalDataSourceID_45b6224f94d8 UUID;
  p_ExternalObjectName_45b6224f94d8 VARCHAR(255);
  p_GeneratedBaseViewName_45b6224f94d8 VARCHAR(255);
  p_AllowDirectSQLInsert_45b6224f94d8 BOOLEAN;
  p_AllowDirectSQLUpdate_45b6224f94d8 BOOLEAN;
  p_AllowDirectSQLDelete_45b6224f94d8 BOOLEAN;
  p_Configuration_45b6224f94d8 TEXT;
  p_SubtypeSelector_45b6224f94d8 TEXT;
  p_EnableFieldLevelSecurity_45b6224f94d8 BOOLEAN;
  p_ID_45b6224f94d8 UUID;
BEGIN
  p_Name_45b6224f94d8 := 'MJ_BizApps_Common: People';
  p_Description_45b6224f94d8 := 'Individual people, optionally linked to MJ system user accounts';
  p_AutoUpdateDescription_45b6224f94d8 := TRUE;
  p_BaseView_45b6224f94d8 := 'vwPeople';
  p_BaseViewGenerated_45b6224f94d8 := FALSE;
  p_VirtualEntity_45b6224f94d8 := FALSE;
  p_TrackRecordChanges_45b6224f94d8 := TRUE;
  p_AuditRecordAccess_45b6224f94d8 := FALSE;
  p_AuditViewRuns_45b6224f94d8 := FALSE;
  p_IncludeInAPI_45b6224f94d8 := TRUE;
  p_AllowAllRowsAPI_45b6224f94d8 := FALSE;
  p_AllowUpdateAPI_45b6224f94d8 := TRUE;
  p_AllowCreateAPI_45b6224f94d8 := TRUE;
  p_AllowDeleteAPI_45b6224f94d8 := TRUE;
  p_CustomResolverAPI_45b6224f94d8 := FALSE;
  p_AllowUserSearchAPI_45b6224f94d8 := TRUE;
  p_FullTextSearchEnabled_45b6224f94d8 := FALSE;
  p_FullTextCatalogGenerated_45b6224f94d8 := TRUE;
  p_FullTextIndexGenerated_45b6224f94d8 := TRUE;
  p_FullTextSearchFunctionGenerated_45b6224f94d8 := TRUE;
  p_UserViewMaxRows_45b6224f94d8 := 1000;
  p_spCreateGenerated_45b6224f94d8 := TRUE;
  p_spUpdateGenerated_45b6224f94d8 := TRUE;
  p_spDeleteGenerated_45b6224f94d8 := TRUE;
  p_CascadeDeletes_45b6224f94d8 := FALSE;
  p_DeleteType_45b6224f94d8 := 'Hard';
  p_AllowRecordMerge_45b6224f94d8 := FALSE;
  p_RelationshipDefaultDisplayType_45b6224f94d8 := 'Search';
  p_UserFormGenerated_45b6224f94d8 := TRUE;
  p_Icon_45b6224f94d8 := 'fa fa-users';
  p_RowsToPackWithSchema_45b6224f94d8 := 'None';
  p_RowsToPackSampleMethod_45b6224f94d8 := 'random';
  p_RowsToPackSampleCount_45b6224f94d8 := 0;
  p_Status_45b6224f94d8 := 'Active';
  p_DisplayName_45b6224f94d8 := 'People';
  p_AllowMultipleSubtypes_45b6224f94d8 := TRUE;
  p_AutoUpdateFullTextSearch_45b6224f94d8 := TRUE;
  p_AutoUpdateAllowUserSearchAPI_45b6224f94d8 := FALSE;
  p_TrustServerCacheCompletely_45b6224f94d8 := TRUE;
  p_SupportsGeoCoding_45b6224f94d8 := TRUE;
  p_AutoUpdateSupportsGeoCoding_45b6224f94d8 := TRUE;
  p_AllowCaching_45b6224f94d8 := FALSE;
  p_DetectExternalChanges_45b6224f94d8 := FALSE;
  p_GeneratedBaseViewName_45b6224f94d8 := 'vwPeopleGenerated';
  p_AllowDirectSQLInsert_45b6224f94d8 := FALSE;
  p_AllowDirectSQLUpdate_45b6224f94d8 := FALSE;
  p_AllowDirectSQLDelete_45b6224f94d8 := FALSE;
  p_Configuration_45b6224f94d8 := '{
  "UI": {
    "Form": {
      "Layout": "left-nav",
      "RelatedRolePolicy": "smart",
      "PrimaryRelatedBudget": 6,
      "RelatedWhenEmpty": "more"
    }
  }
}';
  p_EnableFieldLevelSecurity_45b6224f94d8 := TRUE;
  p_ID_45b6224f94d8 := '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F';
  p_EnableFieldLevelSecurity_45b6224f94d8 := COALESCE((SELECT "EnableFieldLevelSecurity" FROM "${mjSchema}"."Entity" WHERE "ID" = p_ID_45b6224f94d8), p_EnableFieldLevelSecurity_45b6224f94d8);
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntity'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntity"(p_data := jsonb_build_object(
    'ParentID', p_ParentID_45b6224f94d8,
    'Name', p_Name_45b6224f94d8,
    'NameSuffix', p_NameSuffix_45b6224f94d8,
    'Description', p_Description_45b6224f94d8,
    'AutoUpdateDescription', p_AutoUpdateDescription_45b6224f94d8,
    'BaseView', p_BaseView_45b6224f94d8,
    'BaseViewGenerated', p_BaseViewGenerated_45b6224f94d8,
    'VirtualEntity', p_VirtualEntity_45b6224f94d8,
    'TrackRecordChanges', p_TrackRecordChanges_45b6224f94d8,
    'AuditRecordAccess', p_AuditRecordAccess_45b6224f94d8,
    'AuditViewRuns', p_AuditViewRuns_45b6224f94d8,
    'IncludeInAPI', p_IncludeInAPI_45b6224f94d8,
    'AllowAllRowsAPI', p_AllowAllRowsAPI_45b6224f94d8,
    'AllowUpdateAPI', p_AllowUpdateAPI_45b6224f94d8,
    'AllowCreateAPI', p_AllowCreateAPI_45b6224f94d8,
    'AllowDeleteAPI', p_AllowDeleteAPI_45b6224f94d8,
    'CustomResolverAPI', p_CustomResolverAPI_45b6224f94d8,
    'AllowUserSearchAPI', p_AllowUserSearchAPI_45b6224f94d8,
    'FullTextSearchEnabled', p_FullTextSearchEnabled_45b6224f94d8,
    'FullTextCatalog', p_FullTextCatalog_45b6224f94d8,
    'FullTextCatalogGenerated', p_FullTextCatalogGenerated_45b6224f94d8,
    'FullTextIndex', p_FullTextIndex_45b6224f94d8,
    'FullTextIndexGenerated', p_FullTextIndexGenerated_45b6224f94d8,
    'FullTextSearchFunction', p_FullTextSearchFunction_45b6224f94d8,
    'FullTextSearchFunctionGenerated', p_FullTextSearchFunctionGenerated_45b6224f94d8,
    'UserViewMaxRows', p_UserViewMaxRows_45b6224f94d8,
    'spCreate', p_spCreate_45b6224f94d8,
    'spUpdate', p_spUpdate_45b6224f94d8,
    'spDelete', p_spDelete_45b6224f94d8,
    'spCreateGenerated', p_spCreateGenerated_45b6224f94d8,
    'spUpdateGenerated', p_spUpdateGenerated_45b6224f94d8,
    'spDeleteGenerated', p_spDeleteGenerated_45b6224f94d8,
    'CascadeDeletes', p_CascadeDeletes_45b6224f94d8,
    'DeleteType', p_DeleteType_45b6224f94d8,
    'AllowRecordMerge', p_AllowRecordMerge_45b6224f94d8,
    'spMatch', p_spMatch_45b6224f94d8,
    'RelationshipDefaultDisplayType', p_RelationshipDefaultDisplayType_45b6224f94d8,
    'UserFormGenerated', p_UserFormGenerated_45b6224f94d8,
    'EntityObjectSubclassName', p_EntityObjectSubclassName_45b6224f94d8,
    'EntityObjectSubclassImport', p_EntityObjectSubclassImport_45b6224f94d8,
    'PreferredCommunicationField', p_PreferredCommunicationField_45b6224f94d8,
    'Icon', p_Icon_45b6224f94d8,
    'ScopeDefault', p_ScopeDefault_45b6224f94d8,
    'RowsToPackWithSchema', p_RowsToPackWithSchema_45b6224f94d8,
    'RowsToPackSampleMethod', p_RowsToPackSampleMethod_45b6224f94d8,
    'RowsToPackSampleCount', p_RowsToPackSampleCount_45b6224f94d8,
    'RowsToPackSampleOrder', p_RowsToPackSampleOrder_45b6224f94d8,
    'AutoRowCountFrequency', p_AutoRowCountFrequency_45b6224f94d8,
    'RowCount', p_RowCount_45b6224f94d8,
    'RowCountRunAt', p_RowCountRunAt_45b6224f94d8
  ) ||
  jsonb_build_object(
    'Status', p_Status_45b6224f94d8,
    'DisplayName', p_DisplayName_45b6224f94d8,
    'AllowMultipleSubtypes', p_AllowMultipleSubtypes_45b6224f94d8,
    'AutoUpdateFullTextSearch', p_AutoUpdateFullTextSearch_45b6224f94d8,
    'AutoUpdateAllowUserSearchAPI', p_AutoUpdateAllowUserSearchAPI_45b6224f94d8,
    'TrustServerCacheCompletely', p_TrustServerCacheCompletely_45b6224f94d8,
    'SupportsGeoCoding', p_SupportsGeoCoding_45b6224f94d8,
    'AutoUpdateSupportsGeoCoding', p_AutoUpdateSupportsGeoCoding_45b6224f94d8,
    'AllowCaching', p_AllowCaching_45b6224f94d8,
    'DetectExternalChanges', p_DetectExternalChanges_45b6224f94d8,
    'ExternalDataSourceID', p_ExternalDataSourceID_45b6224f94d8,
    'ExternalObjectName', p_ExternalObjectName_45b6224f94d8,
    'GeneratedBaseViewName', p_GeneratedBaseViewName_45b6224f94d8,
    'AllowDirectSQLInsert', p_AllowDirectSQLInsert_45b6224f94d8,
    'AllowDirectSQLUpdate', p_AllowDirectSQLUpdate_45b6224f94d8,
    'AllowDirectSQLDelete', p_AllowDirectSQLDelete_45b6224f94d8,
    'Configuration', p_Configuration_45b6224f94d8,
    'SubtypeSelector', p_SubtypeSelector_45b6224f94d8,
    'EnableFieldLevelSecurity', p_EnableFieldLevelSecurity_45b6224f94d8,
    'ID', p_ID_45b6224f94d8
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntity"(p_ParentID := p_ParentID_45b6224f94d8, p_ParentID_Clear := TRUE, p_Name := p_Name_45b6224f94d8, p_NameSuffix := p_NameSuffix_45b6224f94d8, p_NameSuffix_Clear := TRUE, p_Description := p_Description_45b6224f94d8, p_AutoUpdateDescription := p_AutoUpdateDescription_45b6224f94d8, p_BaseView := p_BaseView_45b6224f94d8, p_BaseViewGenerated := p_BaseViewGenerated_45b6224f94d8, p_VirtualEntity := p_VirtualEntity_45b6224f94d8, p_TrackRecordChanges := p_TrackRecordChanges_45b6224f94d8, p_AuditRecordAccess := p_AuditRecordAccess_45b6224f94d8, p_AuditViewRuns := p_AuditViewRuns_45b6224f94d8, p_IncludeInAPI := p_IncludeInAPI_45b6224f94d8, p_AllowAllRowsAPI := p_AllowAllRowsAPI_45b6224f94d8, p_AllowUpdateAPI := p_AllowUpdateAPI_45b6224f94d8, p_AllowCreateAPI := p_AllowCreateAPI_45b6224f94d8, p_AllowDeleteAPI := p_AllowDeleteAPI_45b6224f94d8, p_CustomResolverAPI := p_CustomResolverAPI_45b6224f94d8, p_AllowUserSearchAPI := p_AllowUserSearchAPI_45b6224f94d8, p_FullTextSearchEnabled := p_FullTextSearchEnabled_45b6224f94d8, p_FullTextCatalog := p_FullTextCatalog_45b6224f94d8, p_FullTextCatalog_Clear := TRUE, p_FullTextCatalogGenerated := p_FullTextCatalogGenerated_45b6224f94d8, p_FullTextIndex := p_FullTextIndex_45b6224f94d8, p_FullTextIndex_Clear := TRUE, p_FullTextIndexGenerated := p_FullTextIndexGenerated_45b6224f94d8, p_FullTextSearchFunction := p_FullTextSearchFunction_45b6224f94d8, p_FullTextSearchFunction_Clear := TRUE, p_FullTextSearchFunctionGenerated := p_FullTextSearchFunctionGenerated_45b6224f94d8, p_UserViewMaxRows := p_UserViewMaxRows_45b6224f94d8, p_spCreate := p_spCreate_45b6224f94d8, p_spCreate_Clear := TRUE, p_spUpdate := p_spUpdate_45b6224f94d8, p_spUpdate_Clear := TRUE, p_spDelete := p_spDelete_45b6224f94d8, p_spDelete_Clear := TRUE, p_spCreateGenerated := p_spCreateGenerated_45b6224f94d8, p_spUpdateGenerated := p_spUpdateGenerated_45b6224f94d8, p_spDeleteGenerated := p_spDeleteGenerated_45b6224f94d8, p_CascadeDeletes := p_CascadeDeletes_45b6224f94d8, p_DeleteType := p_DeleteType_45b6224f94d8, p_AllowRecordMerge := p_AllowRecordMerge_45b6224f94d8, p_spMatch := p_spMatch_45b6224f94d8, p_spMatch_Clear := TRUE, p_RelationshipDefaultDisplayType := p_RelationshipDefaultDisplayType_45b6224f94d8, p_UserFormGenerated := p_UserFormGenerated_45b6224f94d8, p_EntityObjectSubclassName := p_EntityObjectSubclassName_45b6224f94d8, p_EntityObjectSubclassName_Clear := TRUE, p_EntityObjectSubclassImport := p_EntityObjectSubclassImport_45b6224f94d8, p_EntityObjectSubclassImport_Clear := TRUE, p_PreferredCommunicationField := p_PreferredCommunicationField_45b6224f94d8, p_PreferredCommunicationField_Clear := TRUE, p_Icon := p_Icon_45b6224f94d8, p_ScopeDefault := p_ScopeDefault_45b6224f94d8, p_ScopeDefault_Clear := TRUE, p_RowsToPackWithSchema := p_RowsToPackWithSchema_45b6224f94d8, p_RowsToPackSampleMethod := p_RowsToPackSampleMethod_45b6224f94d8, p_RowsToPackSampleCount := p_RowsToPackSampleCount_45b6224f94d8, p_RowsToPackSampleOrder := p_RowsToPackSampleOrder_45b6224f94d8, p_RowsToPackSampleOrder_Clear := TRUE, p_AutoRowCountFrequency := p_AutoRowCountFrequency_45b6224f94d8, p_AutoRowCountFrequency_Clear := TRUE, p_RowCount := p_RowCount_45b6224f94d8, p_RowCount_Clear := TRUE, p_RowCountRunAt := p_RowCountRunAt_45b6224f94d8, p_RowCountRunAt_Clear := TRUE, p_Status := p_Status_45b6224f94d8, p_DisplayName := p_DisplayName_45b6224f94d8, p_AllowMultipleSubtypes := p_AllowMultipleSubtypes_45b6224f94d8, p_AutoUpdateFullTextSearch := p_AutoUpdateFullTextSearch_45b6224f94d8, p_AutoUpdateAllowUserSearchAPI := p_AutoUpdateAllowUserSearchAPI_45b6224f94d8, p_TrustServerCacheCompletely := p_TrustServerCacheCompletely_45b6224f94d8, p_SupportsGeoCoding := p_SupportsGeoCoding_45b6224f94d8, p_AutoUpdateSupportsGeoCoding := p_AutoUpdateSupportsGeoCoding_45b6224f94d8, p_AllowCaching := p_AllowCaching_45b6224f94d8, p_DetectExternalChanges := p_DetectExternalChanges_45b6224f94d8, p_ExternalDataSourceID := p_ExternalDataSourceID_45b6224f94d8, p_ExternalDataSourceID_Clear := TRUE, p_ExternalObjectName := p_ExternalObjectName_45b6224f94d8, p_ExternalObjectName_Clear := TRUE, p_GeneratedBaseViewName := p_GeneratedBaseViewName_45b6224f94d8, p_AllowDirectSQLInsert := p_AllowDirectSQLInsert_45b6224f94d8, p_AllowDirectSQLUpdate := p_AllowDirectSQLUpdate_45b6224f94d8, p_AllowDirectSQLDelete := p_AllowDirectSQLDelete_45b6224f94d8, p_Configuration := p_Configuration_45b6224f94d8, p_SubtypeSelector := p_SubtypeSelector_45b6224f94d8, p_SubtypeSelector_Clear := TRUE, p_EnableFieldLevelSecurity := p_EnableFieldLevelSecurity_45b6224f94d8, p_ID := p_ID_45b6224f94d8);
  END IF;
END $mj$;

-- Save MJ: Entities (core SP call only)
DO $mj$
DECLARE
  p_ParentID_32c9866d8d62 UUID;
  p_Name_32c9866d8d62 VARCHAR(255);
  p_NameSuffix_32c9866d8d62 VARCHAR(255);
  p_Description_32c9866d8d62 TEXT;
  p_AutoUpdateDescription_32c9866d8d62 BOOLEAN;
  p_BaseView_32c9866d8d62 VARCHAR(255);
  p_BaseViewGenerated_32c9866d8d62 BOOLEAN;
  p_VirtualEntity_32c9866d8d62 BOOLEAN;
  p_TrackRecordChanges_32c9866d8d62 BOOLEAN;
  p_AuditRecordAccess_32c9866d8d62 BOOLEAN;
  p_AuditViewRuns_32c9866d8d62 BOOLEAN;
  p_IncludeInAPI_32c9866d8d62 BOOLEAN;
  p_AllowAllRowsAPI_32c9866d8d62 BOOLEAN;
  p_AllowUpdateAPI_32c9866d8d62 BOOLEAN;
  p_AllowCreateAPI_32c9866d8d62 BOOLEAN;
  p_AllowDeleteAPI_32c9866d8d62 BOOLEAN;
  p_CustomResolverAPI_32c9866d8d62 BOOLEAN;
  p_AllowUserSearchAPI_32c9866d8d62 BOOLEAN;
  p_FullTextSearchEnabled_32c9866d8d62 BOOLEAN;
  p_FullTextCatalog_32c9866d8d62 VARCHAR(255);
  p_FullTextCatalogGenerated_32c9866d8d62 BOOLEAN;
  p_FullTextIndex_32c9866d8d62 VARCHAR(255);
  p_FullTextIndexGenerated_32c9866d8d62 BOOLEAN;
  p_FullTextSearchFunction_32c9866d8d62 VARCHAR(255);
  p_FullTextSearchFunctionGenerated_32c9866d8d62 BOOLEAN;
  p_UserViewMaxRows_32c9866d8d62 INTEGER;
  p_spCreate_32c9866d8d62 VARCHAR(255);
  p_spUpdate_32c9866d8d62 VARCHAR(255);
  p_spDelete_32c9866d8d62 VARCHAR(255);
  p_spCreateGenerated_32c9866d8d62 BOOLEAN;
  p_spUpdateGenerated_32c9866d8d62 BOOLEAN;
  p_spDeleteGenerated_32c9866d8d62 BOOLEAN;
  p_CascadeDeletes_32c9866d8d62 BOOLEAN;
  p_DeleteType_32c9866d8d62 VARCHAR(10);
  p_AllowRecordMerge_32c9866d8d62 BOOLEAN;
  p_spMatch_32c9866d8d62 VARCHAR(255);
  p_RelationshipDefaultDisplayType_32c9866d8d62 VARCHAR(20);
  p_UserFormGenerated_32c9866d8d62 BOOLEAN;
  p_EntityObjectSubclassName_32c9866d8d62 VARCHAR(255);
  p_EntityObjectSubclassImport_32c9866d8d62 VARCHAR(255);
  p_PreferredCommunicationField_32c9866d8d62 VARCHAR(255);
  p_Icon_32c9866d8d62 VARCHAR(500);
  p_ScopeDefault_32c9866d8d62 VARCHAR(100);
  p_RowsToPackWithSchema_32c9866d8d62 VARCHAR(20);
  p_RowsToPackSampleMethod_32c9866d8d62 VARCHAR(20);
  p_RowsToPackSampleCount_32c9866d8d62 INTEGER;
  p_RowsToPackSampleOrder_32c9866d8d62 TEXT;
  p_AutoRowCountFrequency_32c9866d8d62 INTEGER;
  p_RowCount_32c9866d8d62 BIGINT;
  p_RowCountRunAt_32c9866d8d62 TIMESTAMPTZ;
  p_Status_32c9866d8d62 VARCHAR(25);
  p_DisplayName_32c9866d8d62 VARCHAR(255);
  p_AllowMultipleSubtypes_32c9866d8d62 BOOLEAN;
  p_AutoUpdateFullTextSearch_32c9866d8d62 BOOLEAN;
  p_AutoUpdateAllowUserSearchAPI_32c9866d8d62 BOOLEAN;
  p_TrustServerCacheCompletely_32c9866d8d62 BOOLEAN;
  p_SupportsGeoCoding_32c9866d8d62 BOOLEAN;
  p_AutoUpdateSupportsGeoCoding_32c9866d8d62 BOOLEAN;
  p_AllowCaching_32c9866d8d62 BOOLEAN;
  p_DetectExternalChanges_32c9866d8d62 BOOLEAN;
  p_ExternalDataSourceID_32c9866d8d62 UUID;
  p_ExternalObjectName_32c9866d8d62 VARCHAR(255);
  p_GeneratedBaseViewName_32c9866d8d62 VARCHAR(255);
  p_AllowDirectSQLInsert_32c9866d8d62 BOOLEAN;
  p_AllowDirectSQLUpdate_32c9866d8d62 BOOLEAN;
  p_AllowDirectSQLDelete_32c9866d8d62 BOOLEAN;
  p_Configuration_32c9866d8d62 TEXT;
  p_SubtypeSelector_32c9866d8d62 TEXT;
  p_EnableFieldLevelSecurity_32c9866d8d62 BOOLEAN;
  p_ID_32c9866d8d62 UUID;
BEGIN
  p_Name_32c9866d8d62 := 'MJ_BizApps_Common: Organizations';
  p_Description_32c9866d8d62 := 'Companies, associations, government bodies, and other organizations with hierarchy support';
  p_AutoUpdateDescription_32c9866d8d62 := TRUE;
  p_BaseView_32c9866d8d62 := 'vwOrganizations';
  p_BaseViewGenerated_32c9866d8d62 := FALSE;
  p_VirtualEntity_32c9866d8d62 := FALSE;
  p_TrackRecordChanges_32c9866d8d62 := TRUE;
  p_AuditRecordAccess_32c9866d8d62 := FALSE;
  p_AuditViewRuns_32c9866d8d62 := FALSE;
  p_IncludeInAPI_32c9866d8d62 := TRUE;
  p_AllowAllRowsAPI_32c9866d8d62 := FALSE;
  p_AllowUpdateAPI_32c9866d8d62 := TRUE;
  p_AllowCreateAPI_32c9866d8d62 := TRUE;
  p_AllowDeleteAPI_32c9866d8d62 := TRUE;
  p_CustomResolverAPI_32c9866d8d62 := FALSE;
  p_AllowUserSearchAPI_32c9866d8d62 := TRUE;
  p_FullTextSearchEnabled_32c9866d8d62 := FALSE;
  p_FullTextCatalogGenerated_32c9866d8d62 := TRUE;
  p_FullTextIndexGenerated_32c9866d8d62 := TRUE;
  p_FullTextSearchFunctionGenerated_32c9866d8d62 := TRUE;
  p_UserViewMaxRows_32c9866d8d62 := 1000;
  p_spCreateGenerated_32c9866d8d62 := TRUE;
  p_spUpdateGenerated_32c9866d8d62 := TRUE;
  p_spDeleteGenerated_32c9866d8d62 := TRUE;
  p_CascadeDeletes_32c9866d8d62 := FALSE;
  p_DeleteType_32c9866d8d62 := 'Hard';
  p_AllowRecordMerge_32c9866d8d62 := FALSE;
  p_RelationshipDefaultDisplayType_32c9866d8d62 := 'Search';
  p_UserFormGenerated_32c9866d8d62 := TRUE;
  p_Icon_32c9866d8d62 := 'fa fa-building';
  p_RowsToPackWithSchema_32c9866d8d62 := 'None';
  p_RowsToPackSampleMethod_32c9866d8d62 := 'random';
  p_RowsToPackSampleCount_32c9866d8d62 := 0;
  p_Status_32c9866d8d62 := 'Active';
  p_DisplayName_32c9866d8d62 := 'Organizations';
  p_AllowMultipleSubtypes_32c9866d8d62 := TRUE;
  p_AutoUpdateFullTextSearch_32c9866d8d62 := TRUE;
  p_AutoUpdateAllowUserSearchAPI_32c9866d8d62 := FALSE;
  p_TrustServerCacheCompletely_32c9866d8d62 := TRUE;
  p_SupportsGeoCoding_32c9866d8d62 := TRUE;
  p_AutoUpdateSupportsGeoCoding_32c9866d8d62 := TRUE;
  p_AllowCaching_32c9866d8d62 := FALSE;
  p_DetectExternalChanges_32c9866d8d62 := FALSE;
  p_GeneratedBaseViewName_32c9866d8d62 := 'vwOrganizationsGenerated';
  p_AllowDirectSQLInsert_32c9866d8d62 := FALSE;
  p_AllowDirectSQLUpdate_32c9866d8d62 := FALSE;
  p_AllowDirectSQLDelete_32c9866d8d62 := FALSE;
  p_Configuration_32c9866d8d62 := '{
  "UI": {
    "Form": {
      "Layout": "left-nav",
      "RelatedRolePolicy": "smart",
      "PrimaryRelatedBudget": 6,
      "RelatedWhenEmpty": "more"
    }
  }
}';
  p_EnableFieldLevelSecurity_32c9866d8d62 := FALSE;
  p_ID_32c9866d8d62 := 'C70448F9-9792-41D7-A82C-784B66429D54';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntity'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntity"(p_data := jsonb_build_object(
    'ParentID', p_ParentID_32c9866d8d62,
    'Name', p_Name_32c9866d8d62,
    'NameSuffix', p_NameSuffix_32c9866d8d62,
    'Description', p_Description_32c9866d8d62,
    'AutoUpdateDescription', p_AutoUpdateDescription_32c9866d8d62,
    'BaseView', p_BaseView_32c9866d8d62,
    'BaseViewGenerated', p_BaseViewGenerated_32c9866d8d62,
    'VirtualEntity', p_VirtualEntity_32c9866d8d62,
    'TrackRecordChanges', p_TrackRecordChanges_32c9866d8d62,
    'AuditRecordAccess', p_AuditRecordAccess_32c9866d8d62,
    'AuditViewRuns', p_AuditViewRuns_32c9866d8d62,
    'IncludeInAPI', p_IncludeInAPI_32c9866d8d62,
    'AllowAllRowsAPI', p_AllowAllRowsAPI_32c9866d8d62,
    'AllowUpdateAPI', p_AllowUpdateAPI_32c9866d8d62,
    'AllowCreateAPI', p_AllowCreateAPI_32c9866d8d62,
    'AllowDeleteAPI', p_AllowDeleteAPI_32c9866d8d62,
    'CustomResolverAPI', p_CustomResolverAPI_32c9866d8d62,
    'AllowUserSearchAPI', p_AllowUserSearchAPI_32c9866d8d62,
    'FullTextSearchEnabled', p_FullTextSearchEnabled_32c9866d8d62,
    'FullTextCatalog', p_FullTextCatalog_32c9866d8d62,
    'FullTextCatalogGenerated', p_FullTextCatalogGenerated_32c9866d8d62,
    'FullTextIndex', p_FullTextIndex_32c9866d8d62,
    'FullTextIndexGenerated', p_FullTextIndexGenerated_32c9866d8d62,
    'FullTextSearchFunction', p_FullTextSearchFunction_32c9866d8d62,
    'FullTextSearchFunctionGenerated', p_FullTextSearchFunctionGenerated_32c9866d8d62,
    'UserViewMaxRows', p_UserViewMaxRows_32c9866d8d62,
    'spCreate', p_spCreate_32c9866d8d62,
    'spUpdate', p_spUpdate_32c9866d8d62,
    'spDelete', p_spDelete_32c9866d8d62,
    'spCreateGenerated', p_spCreateGenerated_32c9866d8d62,
    'spUpdateGenerated', p_spUpdateGenerated_32c9866d8d62,
    'spDeleteGenerated', p_spDeleteGenerated_32c9866d8d62,
    'CascadeDeletes', p_CascadeDeletes_32c9866d8d62,
    'DeleteType', p_DeleteType_32c9866d8d62,
    'AllowRecordMerge', p_AllowRecordMerge_32c9866d8d62,
    'spMatch', p_spMatch_32c9866d8d62,
    'RelationshipDefaultDisplayType', p_RelationshipDefaultDisplayType_32c9866d8d62,
    'UserFormGenerated', p_UserFormGenerated_32c9866d8d62,
    'EntityObjectSubclassName', p_EntityObjectSubclassName_32c9866d8d62,
    'EntityObjectSubclassImport', p_EntityObjectSubclassImport_32c9866d8d62,
    'PreferredCommunicationField', p_PreferredCommunicationField_32c9866d8d62,
    'Icon', p_Icon_32c9866d8d62,
    'ScopeDefault', p_ScopeDefault_32c9866d8d62,
    'RowsToPackWithSchema', p_RowsToPackWithSchema_32c9866d8d62,
    'RowsToPackSampleMethod', p_RowsToPackSampleMethod_32c9866d8d62,
    'RowsToPackSampleCount', p_RowsToPackSampleCount_32c9866d8d62,
    'RowsToPackSampleOrder', p_RowsToPackSampleOrder_32c9866d8d62,
    'AutoRowCountFrequency', p_AutoRowCountFrequency_32c9866d8d62,
    'RowCount', p_RowCount_32c9866d8d62,
    'RowCountRunAt', p_RowCountRunAt_32c9866d8d62
  ) ||
  jsonb_build_object(
    'Status', p_Status_32c9866d8d62,
    'DisplayName', p_DisplayName_32c9866d8d62,
    'AllowMultipleSubtypes', p_AllowMultipleSubtypes_32c9866d8d62,
    'AutoUpdateFullTextSearch', p_AutoUpdateFullTextSearch_32c9866d8d62,
    'AutoUpdateAllowUserSearchAPI', p_AutoUpdateAllowUserSearchAPI_32c9866d8d62,
    'TrustServerCacheCompletely', p_TrustServerCacheCompletely_32c9866d8d62,
    'SupportsGeoCoding', p_SupportsGeoCoding_32c9866d8d62,
    'AutoUpdateSupportsGeoCoding', p_AutoUpdateSupportsGeoCoding_32c9866d8d62,
    'AllowCaching', p_AllowCaching_32c9866d8d62,
    'DetectExternalChanges', p_DetectExternalChanges_32c9866d8d62,
    'ExternalDataSourceID', p_ExternalDataSourceID_32c9866d8d62,
    'ExternalObjectName', p_ExternalObjectName_32c9866d8d62,
    'GeneratedBaseViewName', p_GeneratedBaseViewName_32c9866d8d62,
    'AllowDirectSQLInsert', p_AllowDirectSQLInsert_32c9866d8d62,
    'AllowDirectSQLUpdate', p_AllowDirectSQLUpdate_32c9866d8d62,
    'AllowDirectSQLDelete', p_AllowDirectSQLDelete_32c9866d8d62,
    'Configuration', p_Configuration_32c9866d8d62,
    'SubtypeSelector', p_SubtypeSelector_32c9866d8d62,
    'EnableFieldLevelSecurity', p_EnableFieldLevelSecurity_32c9866d8d62,
    'ID', p_ID_32c9866d8d62
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntity"(p_ParentID := p_ParentID_32c9866d8d62, p_ParentID_Clear := TRUE, p_Name := p_Name_32c9866d8d62, p_NameSuffix := p_NameSuffix_32c9866d8d62, p_NameSuffix_Clear := TRUE, p_Description := p_Description_32c9866d8d62, p_AutoUpdateDescription := p_AutoUpdateDescription_32c9866d8d62, p_BaseView := p_BaseView_32c9866d8d62, p_BaseViewGenerated := p_BaseViewGenerated_32c9866d8d62, p_VirtualEntity := p_VirtualEntity_32c9866d8d62, p_TrackRecordChanges := p_TrackRecordChanges_32c9866d8d62, p_AuditRecordAccess := p_AuditRecordAccess_32c9866d8d62, p_AuditViewRuns := p_AuditViewRuns_32c9866d8d62, p_IncludeInAPI := p_IncludeInAPI_32c9866d8d62, p_AllowAllRowsAPI := p_AllowAllRowsAPI_32c9866d8d62, p_AllowUpdateAPI := p_AllowUpdateAPI_32c9866d8d62, p_AllowCreateAPI := p_AllowCreateAPI_32c9866d8d62, p_AllowDeleteAPI := p_AllowDeleteAPI_32c9866d8d62, p_CustomResolverAPI := p_CustomResolverAPI_32c9866d8d62, p_AllowUserSearchAPI := p_AllowUserSearchAPI_32c9866d8d62, p_FullTextSearchEnabled := p_FullTextSearchEnabled_32c9866d8d62, p_FullTextCatalog := p_FullTextCatalog_32c9866d8d62, p_FullTextCatalog_Clear := TRUE, p_FullTextCatalogGenerated := p_FullTextCatalogGenerated_32c9866d8d62, p_FullTextIndex := p_FullTextIndex_32c9866d8d62, p_FullTextIndex_Clear := TRUE, p_FullTextIndexGenerated := p_FullTextIndexGenerated_32c9866d8d62, p_FullTextSearchFunction := p_FullTextSearchFunction_32c9866d8d62, p_FullTextSearchFunction_Clear := TRUE, p_FullTextSearchFunctionGenerated := p_FullTextSearchFunctionGenerated_32c9866d8d62, p_UserViewMaxRows := p_UserViewMaxRows_32c9866d8d62, p_spCreate := p_spCreate_32c9866d8d62, p_spCreate_Clear := TRUE, p_spUpdate := p_spUpdate_32c9866d8d62, p_spUpdate_Clear := TRUE, p_spDelete := p_spDelete_32c9866d8d62, p_spDelete_Clear := TRUE, p_spCreateGenerated := p_spCreateGenerated_32c9866d8d62, p_spUpdateGenerated := p_spUpdateGenerated_32c9866d8d62, p_spDeleteGenerated := p_spDeleteGenerated_32c9866d8d62, p_CascadeDeletes := p_CascadeDeletes_32c9866d8d62, p_DeleteType := p_DeleteType_32c9866d8d62, p_AllowRecordMerge := p_AllowRecordMerge_32c9866d8d62, p_spMatch := p_spMatch_32c9866d8d62, p_spMatch_Clear := TRUE, p_RelationshipDefaultDisplayType := p_RelationshipDefaultDisplayType_32c9866d8d62, p_UserFormGenerated := p_UserFormGenerated_32c9866d8d62, p_EntityObjectSubclassName := p_EntityObjectSubclassName_32c9866d8d62, p_EntityObjectSubclassName_Clear := TRUE, p_EntityObjectSubclassImport := p_EntityObjectSubclassImport_32c9866d8d62, p_EntityObjectSubclassImport_Clear := TRUE, p_PreferredCommunicationField := p_PreferredCommunicationField_32c9866d8d62, p_PreferredCommunicationField_Clear := TRUE, p_Icon := p_Icon_32c9866d8d62, p_ScopeDefault := p_ScopeDefault_32c9866d8d62, p_ScopeDefault_Clear := TRUE, p_RowsToPackWithSchema := p_RowsToPackWithSchema_32c9866d8d62, p_RowsToPackSampleMethod := p_RowsToPackSampleMethod_32c9866d8d62, p_RowsToPackSampleCount := p_RowsToPackSampleCount_32c9866d8d62, p_RowsToPackSampleOrder := p_RowsToPackSampleOrder_32c9866d8d62, p_RowsToPackSampleOrder_Clear := TRUE, p_AutoRowCountFrequency := p_AutoRowCountFrequency_32c9866d8d62, p_AutoRowCountFrequency_Clear := TRUE, p_RowCount := p_RowCount_32c9866d8d62, p_RowCount_Clear := TRUE, p_RowCountRunAt := p_RowCountRunAt_32c9866d8d62, p_RowCountRunAt_Clear := TRUE, p_Status := p_Status_32c9866d8d62, p_DisplayName := p_DisplayName_32c9866d8d62, p_AllowMultipleSubtypes := p_AllowMultipleSubtypes_32c9866d8d62, p_AutoUpdateFullTextSearch := p_AutoUpdateFullTextSearch_32c9866d8d62, p_AutoUpdateAllowUserSearchAPI := p_AutoUpdateAllowUserSearchAPI_32c9866d8d62, p_TrustServerCacheCompletely := p_TrustServerCacheCompletely_32c9866d8d62, p_SupportsGeoCoding := p_SupportsGeoCoding_32c9866d8d62, p_AutoUpdateSupportsGeoCoding := p_AutoUpdateSupportsGeoCoding_32c9866d8d62, p_AllowCaching := p_AllowCaching_32c9866d8d62, p_DetectExternalChanges := p_DetectExternalChanges_32c9866d8d62, p_ExternalDataSourceID := p_ExternalDataSourceID_32c9866d8d62, p_ExternalDataSourceID_Clear := TRUE, p_ExternalObjectName := p_ExternalObjectName_32c9866d8d62, p_ExternalObjectName_Clear := TRUE, p_GeneratedBaseViewName := p_GeneratedBaseViewName_32c9866d8d62, p_AllowDirectSQLInsert := p_AllowDirectSQLInsert_32c9866d8d62, p_AllowDirectSQLUpdate := p_AllowDirectSQLUpdate_32c9866d8d62, p_AllowDirectSQLDelete := p_AllowDirectSQLDelete_32c9866d8d62, p_Configuration := p_Configuration_32c9866d8d62, p_SubtypeSelector := p_SubtypeSelector_32c9866d8d62, p_SubtypeSelector_Clear := TRUE, p_EnableFieldLevelSecurity := p_EnableFieldLevelSecurity_32c9866d8d62, p_ID := p_ID_32c9866d8d62);
  END IF;
END $mj$;

-- Save MJ: Entities (core SP call only)
DO $mj$
DECLARE
  p_ParentID_405f9af57670 UUID;
  p_Name_405f9af57670 VARCHAR(255);
  p_NameSuffix_405f9af57670 VARCHAR(255);
  p_Description_405f9af57670 TEXT;
  p_AutoUpdateDescription_405f9af57670 BOOLEAN;
  p_BaseView_405f9af57670 VARCHAR(255);
  p_BaseViewGenerated_405f9af57670 BOOLEAN;
  p_VirtualEntity_405f9af57670 BOOLEAN;
  p_TrackRecordChanges_405f9af57670 BOOLEAN;
  p_AuditRecordAccess_405f9af57670 BOOLEAN;
  p_AuditViewRuns_405f9af57670 BOOLEAN;
  p_IncludeInAPI_405f9af57670 BOOLEAN;
  p_AllowAllRowsAPI_405f9af57670 BOOLEAN;
  p_AllowUpdateAPI_405f9af57670 BOOLEAN;
  p_AllowCreateAPI_405f9af57670 BOOLEAN;
  p_AllowDeleteAPI_405f9af57670 BOOLEAN;
  p_CustomResolverAPI_405f9af57670 BOOLEAN;
  p_AllowUserSearchAPI_405f9af57670 BOOLEAN;
  p_FullTextSearchEnabled_405f9af57670 BOOLEAN;
  p_FullTextCatalog_405f9af57670 VARCHAR(255);
  p_FullTextCatalogGenerated_405f9af57670 BOOLEAN;
  p_FullTextIndex_405f9af57670 VARCHAR(255);
  p_FullTextIndexGenerated_405f9af57670 BOOLEAN;
  p_FullTextSearchFunction_405f9af57670 VARCHAR(255);
  p_FullTextSearchFunctionGenerated_405f9af57670 BOOLEAN;
  p_UserViewMaxRows_405f9af57670 INTEGER;
  p_spCreate_405f9af57670 VARCHAR(255);
  p_spUpdate_405f9af57670 VARCHAR(255);
  p_spDelete_405f9af57670 VARCHAR(255);
  p_spCreateGenerated_405f9af57670 BOOLEAN;
  p_spUpdateGenerated_405f9af57670 BOOLEAN;
  p_spDeleteGenerated_405f9af57670 BOOLEAN;
  p_CascadeDeletes_405f9af57670 BOOLEAN;
  p_DeleteType_405f9af57670 VARCHAR(10);
  p_AllowRecordMerge_405f9af57670 BOOLEAN;
  p_spMatch_405f9af57670 VARCHAR(255);
  p_RelationshipDefaultDisplayType_405f9af57670 VARCHAR(20);
  p_UserFormGenerated_405f9af57670 BOOLEAN;
  p_EntityObjectSubclassName_405f9af57670 VARCHAR(255);
  p_EntityObjectSubclassImport_405f9af57670 VARCHAR(255);
  p_PreferredCommunicationField_405f9af57670 VARCHAR(255);
  p_Icon_405f9af57670 VARCHAR(500);
  p_ScopeDefault_405f9af57670 VARCHAR(100);
  p_RowsToPackWithSchema_405f9af57670 VARCHAR(20);
  p_RowsToPackSampleMethod_405f9af57670 VARCHAR(20);
  p_RowsToPackSampleCount_405f9af57670 INTEGER;
  p_RowsToPackSampleOrder_405f9af57670 TEXT;
  p_AutoRowCountFrequency_405f9af57670 INTEGER;
  p_RowCount_405f9af57670 BIGINT;
  p_RowCountRunAt_405f9af57670 TIMESTAMPTZ;
  p_Status_405f9af57670 VARCHAR(25);
  p_DisplayName_405f9af57670 VARCHAR(255);
  p_AllowMultipleSubtypes_405f9af57670 BOOLEAN;
  p_AutoUpdateFullTextSearch_405f9af57670 BOOLEAN;
  p_AutoUpdateAllowUserSearchAPI_405f9af57670 BOOLEAN;
  p_TrustServerCacheCompletely_405f9af57670 BOOLEAN;
  p_SupportsGeoCoding_405f9af57670 BOOLEAN;
  p_AutoUpdateSupportsGeoCoding_405f9af57670 BOOLEAN;
  p_AllowCaching_405f9af57670 BOOLEAN;
  p_DetectExternalChanges_405f9af57670 BOOLEAN;
  p_ExternalDataSourceID_405f9af57670 UUID;
  p_ExternalObjectName_405f9af57670 VARCHAR(255);
  p_GeneratedBaseViewName_405f9af57670 VARCHAR(255);
  p_AllowDirectSQLInsert_405f9af57670 BOOLEAN;
  p_AllowDirectSQLUpdate_405f9af57670 BOOLEAN;
  p_AllowDirectSQLDelete_405f9af57670 BOOLEAN;
  p_Configuration_405f9af57670 TEXT;
  p_SubtypeSelector_405f9af57670 TEXT;
  p_EnableFieldLevelSecurity_405f9af57670 BOOLEAN;
  p_ID_405f9af57670 UUID;
BEGIN
  p_Name_405f9af57670 := 'MJ_BizApps_Common: Addresses';
  p_Description_405f9af57670 := 'Standalone physical address records linked to entities via AddressLink for sharing across people and organizations';
  p_AutoUpdateDescription_405f9af57670 := TRUE;
  p_BaseView_405f9af57670 := 'vwAddresses';
  p_BaseViewGenerated_405f9af57670 := TRUE;
  p_VirtualEntity_405f9af57670 := FALSE;
  p_TrackRecordChanges_405f9af57670 := TRUE;
  p_AuditRecordAccess_405f9af57670 := FALSE;
  p_AuditViewRuns_405f9af57670 := FALSE;
  p_IncludeInAPI_405f9af57670 := TRUE;
  p_AllowAllRowsAPI_405f9af57670 := FALSE;
  p_AllowUpdateAPI_405f9af57670 := TRUE;
  p_AllowCreateAPI_405f9af57670 := TRUE;
  p_AllowDeleteAPI_405f9af57670 := TRUE;
  p_CustomResolverAPI_405f9af57670 := FALSE;
  p_AllowUserSearchAPI_405f9af57670 := FALSE;
  p_FullTextSearchEnabled_405f9af57670 := FALSE;
  p_FullTextCatalogGenerated_405f9af57670 := TRUE;
  p_FullTextIndexGenerated_405f9af57670 := TRUE;
  p_FullTextSearchFunctionGenerated_405f9af57670 := TRUE;
  p_UserViewMaxRows_405f9af57670 := 1000;
  p_spCreateGenerated_405f9af57670 := TRUE;
  p_spUpdateGenerated_405f9af57670 := TRUE;
  p_spDeleteGenerated_405f9af57670 := TRUE;
  p_CascadeDeletes_405f9af57670 := FALSE;
  p_DeleteType_405f9af57670 := 'Hard';
  p_AllowRecordMerge_405f9af57670 := FALSE;
  p_RelationshipDefaultDisplayType_405f9af57670 := 'Search';
  p_UserFormGenerated_405f9af57670 := TRUE;
  p_Icon_405f9af57670 := 'fa fa-map-marker-alt';
  p_RowsToPackWithSchema_405f9af57670 := 'None';
  p_RowsToPackSampleMethod_405f9af57670 := 'random';
  p_RowsToPackSampleCount_405f9af57670 := 0;
  p_Status_405f9af57670 := 'Active';
  p_DisplayName_405f9af57670 := 'Addresses';
  p_AllowMultipleSubtypes_405f9af57670 := FALSE;
  p_AutoUpdateFullTextSearch_405f9af57670 := TRUE;
  p_AutoUpdateAllowUserSearchAPI_405f9af57670 := FALSE;
  p_TrustServerCacheCompletely_405f9af57670 := TRUE;
  p_SupportsGeoCoding_405f9af57670 := TRUE;
  p_AutoUpdateSupportsGeoCoding_405f9af57670 := TRUE;
  p_AllowCaching_405f9af57670 := FALSE;
  p_DetectExternalChanges_405f9af57670 := FALSE;
  p_AllowDirectSQLInsert_405f9af57670 := FALSE;
  p_AllowDirectSQLUpdate_405f9af57670 := FALSE;
  p_AllowDirectSQLDelete_405f9af57670 := FALSE;
  p_Configuration_405f9af57670 := '{
  "UI": {
    "Form": {
      "Layout": "left-nav",
      "RelatedRolePolicy": "smart",
      "PrimaryRelatedBudget": 6,
      "RelatedWhenEmpty": "more"
    }
  }
}';
  p_EnableFieldLevelSecurity_405f9af57670 := FALSE;
  p_ID_405f9af57670 := '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E';
  PERFORM "${mjSchema}"."spUpdateEntity"(p_data := jsonb_build_object(
    'ParentID', p_ParentID_405f9af57670,
    'Name', p_Name_405f9af57670,
    'NameSuffix', p_NameSuffix_405f9af57670,
    'Description', p_Description_405f9af57670,
    'AutoUpdateDescription', p_AutoUpdateDescription_405f9af57670,
    'BaseView', p_BaseView_405f9af57670,
    'BaseViewGenerated', p_BaseViewGenerated_405f9af57670,
    'VirtualEntity', p_VirtualEntity_405f9af57670,
    'TrackRecordChanges', p_TrackRecordChanges_405f9af57670,
    'AuditRecordAccess', p_AuditRecordAccess_405f9af57670,
    'AuditViewRuns', p_AuditViewRuns_405f9af57670,
    'IncludeInAPI', p_IncludeInAPI_405f9af57670,
    'AllowAllRowsAPI', p_AllowAllRowsAPI_405f9af57670,
    'AllowUpdateAPI', p_AllowUpdateAPI_405f9af57670,
    'AllowCreateAPI', p_AllowCreateAPI_405f9af57670,
    'AllowDeleteAPI', p_AllowDeleteAPI_405f9af57670,
    'CustomResolverAPI', p_CustomResolverAPI_405f9af57670,
    'AllowUserSearchAPI', p_AllowUserSearchAPI_405f9af57670,
    'FullTextSearchEnabled', p_FullTextSearchEnabled_405f9af57670,
    'FullTextCatalog', p_FullTextCatalog_405f9af57670,
    'FullTextCatalogGenerated', p_FullTextCatalogGenerated_405f9af57670,
    'FullTextIndex', p_FullTextIndex_405f9af57670,
    'FullTextIndexGenerated', p_FullTextIndexGenerated_405f9af57670,
    'FullTextSearchFunction', p_FullTextSearchFunction_405f9af57670,
    'FullTextSearchFunctionGenerated', p_FullTextSearchFunctionGenerated_405f9af57670,
    'UserViewMaxRows', p_UserViewMaxRows_405f9af57670,
    'spCreate', p_spCreate_405f9af57670,
    'spUpdate', p_spUpdate_405f9af57670,
    'spDelete', p_spDelete_405f9af57670,
    'spCreateGenerated', p_spCreateGenerated_405f9af57670,
    'spUpdateGenerated', p_spUpdateGenerated_405f9af57670,
    'spDeleteGenerated', p_spDeleteGenerated_405f9af57670,
    'CascadeDeletes', p_CascadeDeletes_405f9af57670,
    'DeleteType', p_DeleteType_405f9af57670,
    'AllowRecordMerge', p_AllowRecordMerge_405f9af57670,
    'spMatch', p_spMatch_405f9af57670,
    'RelationshipDefaultDisplayType', p_RelationshipDefaultDisplayType_405f9af57670,
    'UserFormGenerated', p_UserFormGenerated_405f9af57670,
    'EntityObjectSubclassName', p_EntityObjectSubclassName_405f9af57670,
    'EntityObjectSubclassImport', p_EntityObjectSubclassImport_405f9af57670,
    'PreferredCommunicationField', p_PreferredCommunicationField_405f9af57670,
    'Icon', p_Icon_405f9af57670,
    'ScopeDefault', p_ScopeDefault_405f9af57670,
    'RowsToPackWithSchema', p_RowsToPackWithSchema_405f9af57670,
    'RowsToPackSampleMethod', p_RowsToPackSampleMethod_405f9af57670,
    'RowsToPackSampleCount', p_RowsToPackSampleCount_405f9af57670,
    'RowsToPackSampleOrder', p_RowsToPackSampleOrder_405f9af57670,
    'AutoRowCountFrequency', p_AutoRowCountFrequency_405f9af57670,
    'RowCount', p_RowCount_405f9af57670,
    'RowCountRunAt', p_RowCountRunAt_405f9af57670
  ) ||
  jsonb_build_object(
    'Status', p_Status_405f9af57670,
    'DisplayName', p_DisplayName_405f9af57670,
    'AllowMultipleSubtypes', p_AllowMultipleSubtypes_405f9af57670,
    'AutoUpdateFullTextSearch', p_AutoUpdateFullTextSearch_405f9af57670,
    'AutoUpdateAllowUserSearchAPI', p_AutoUpdateAllowUserSearchAPI_405f9af57670,
    'TrustServerCacheCompletely', p_TrustServerCacheCompletely_405f9af57670,
    'SupportsGeoCoding', p_SupportsGeoCoding_405f9af57670,
    'AutoUpdateSupportsGeoCoding', p_AutoUpdateSupportsGeoCoding_405f9af57670,
    'AllowCaching', p_AllowCaching_405f9af57670,
    'DetectExternalChanges', p_DetectExternalChanges_405f9af57670,
    'ExternalDataSourceID', p_ExternalDataSourceID_405f9af57670,
    'ExternalObjectName', p_ExternalObjectName_405f9af57670,
    'GeneratedBaseViewName', p_GeneratedBaseViewName_405f9af57670,
    'AllowDirectSQLInsert', p_AllowDirectSQLInsert_405f9af57670,
    'AllowDirectSQLUpdate', p_AllowDirectSQLUpdate_405f9af57670,
    'AllowDirectSQLDelete', p_AllowDirectSQLDelete_405f9af57670,
    'Configuration', p_Configuration_405f9af57670,
    'SubtypeSelector', p_SubtypeSelector_405f9af57670,
    'EnableFieldLevelSecurity', p_EnableFieldLevelSecurity_405f9af57670,
    'ID', p_ID_405f9af57670
  ));
END $mj$;

-- Save MJ: Entity Relationships (core SP call only)
DO $mj$
DECLARE
  p_EntityID_0a22fac07137 UUID;
  p_Sequence_0a22fac07137 INTEGER;
  p_RelatedEntityID_0a22fac07137 UUID;
  p_BundleInAPI_0a22fac07137 BOOLEAN;
  p_IncludeInParentAllQuery_0a22fac07137 BOOLEAN;
  p_Type_0a22fac07137 CHAR(20);
  p_EntityKeyField_0a22fac07137 VARCHAR(255);
  p_RelatedEntityJoinField_0a22fac07137 VARCHAR(255);
  p_JoinView_0a22fac07137 VARCHAR(255);
  p_JoinEntityJoinField_0a22fac07137 VARCHAR(255);
  p_JoinEntityInverseJoinField_0a22fac07137 VARCHAR(255);
  p_DisplayInForm_0a22fac07137 BOOLEAN;
  p_DisplayLocation_0a22fac07137 VARCHAR(50);
  p_DisplayName_0a22fac07137 VARCHAR(255);
  p_DisplayIconType_0a22fac07137 VARCHAR(50);
  p_DisplayIcon_0a22fac07137 VARCHAR(255);
  p_DisplayComponentID_0a22fac07137 UUID;
  p_DisplayComponentConfiguration_0a22fac07137 TEXT;
  p_AutoUpdateFromSchema_0a22fac07137 BOOLEAN;
  p_AdditionalFieldsToInclude_0a22fac07137 TEXT;
  p_AutoUpdateAdditionalFieldsToInclude_0a22fac07137 BOOLEAN;
  p_RelatedRecordCollection_0a22fac07137 TEXT;
  p_Configuration_0a22fac07137 TEXT;
  p_ID_0a22fac07137 UUID;
BEGIN
  p_EntityID_0a22fac07137 := '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F';
  p_Sequence_0a22fac07137 := 3;
  p_RelatedEntityID_0a22fac07137 := '32C45078-D33B-4760-9BE5-0DF7F483F591';
  p_BundleInAPI_0a22fac07137 := TRUE;
  p_IncludeInParentAllQuery_0a22fac07137 := FALSE;
  p_Type_0a22fac07137 := 'One To Many';
  p_RelatedEntityJoinField_0a22fac07137 := 'PersonID';
  p_DisplayInForm_0a22fac07137 := TRUE;
  p_DisplayLocation_0a22fac07137 := 'After Field Tabs';
  p_DisplayName_0a22fac07137 := 'MJ_BizApps_Common: Contact Methods';
  p_DisplayIconType_0a22fac07137 := 'Related Entity Icon';
  p_AutoUpdateFromSchema_0a22fac07137 := TRUE;
  p_AutoUpdateAdditionalFieldsToInclude_0a22fac07137 := TRUE;
  p_RelatedRecordCollection_0a22fac07137 := '{
  "Name": "ContactMethods",
  "Load": "explicit",
  "OnRemove": "delete"
}';
  p_Configuration_0a22fac07137 := '{
  "UI": {
    "inclusion": "Primary",
    "whenEmpty": "show"
  }
}';
  p_ID_0a22fac07137 := '1F63A0CF-3F16-4EAC-A241-845C633779CC';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityRelationship'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_data := jsonb_build_object(
    'EntityID', p_EntityID_0a22fac07137,
    'Sequence', p_Sequence_0a22fac07137,
    'RelatedEntityID', p_RelatedEntityID_0a22fac07137,
    'BundleInAPI', p_BundleInAPI_0a22fac07137,
    'IncludeInParentAllQuery', p_IncludeInParentAllQuery_0a22fac07137,
    'Type', p_Type_0a22fac07137,
    'EntityKeyField', p_EntityKeyField_0a22fac07137,
    'RelatedEntityJoinField', p_RelatedEntityJoinField_0a22fac07137,
    'JoinView', p_JoinView_0a22fac07137,
    'JoinEntityJoinField', p_JoinEntityJoinField_0a22fac07137,
    'JoinEntityInverseJoinField', p_JoinEntityInverseJoinField_0a22fac07137,
    'DisplayInForm', p_DisplayInForm_0a22fac07137,
    'DisplayLocation', p_DisplayLocation_0a22fac07137,
    'DisplayName', p_DisplayName_0a22fac07137,
    'DisplayIconType', p_DisplayIconType_0a22fac07137,
    'DisplayIcon', p_DisplayIcon_0a22fac07137,
    'DisplayComponentID', p_DisplayComponentID_0a22fac07137,
    'DisplayComponentConfiguration', p_DisplayComponentConfiguration_0a22fac07137,
    'AutoUpdateFromSchema', p_AutoUpdateFromSchema_0a22fac07137,
    'AdditionalFieldsToInclude', p_AdditionalFieldsToInclude_0a22fac07137,
    'AutoUpdateAdditionalFieldsToInclude', p_AutoUpdateAdditionalFieldsToInclude_0a22fac07137,
    'RelatedRecordCollection', p_RelatedRecordCollection_0a22fac07137,
    'Configuration', p_Configuration_0a22fac07137,
    'ID', p_ID_0a22fac07137
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_EntityID := p_EntityID_0a22fac07137, p_Sequence := p_Sequence_0a22fac07137, p_RelatedEntityID := p_RelatedEntityID_0a22fac07137, p_BundleInAPI := p_BundleInAPI_0a22fac07137, p_IncludeInParentAllQuery := p_IncludeInParentAllQuery_0a22fac07137, p_Type := p_Type_0a22fac07137, p_EntityKeyField := p_EntityKeyField_0a22fac07137, p_EntityKeyField_Clear := TRUE, p_RelatedEntityJoinField := p_RelatedEntityJoinField_0a22fac07137, p_JoinView := p_JoinView_0a22fac07137, p_JoinView_Clear := TRUE, p_JoinEntityJoinField := p_JoinEntityJoinField_0a22fac07137, p_JoinEntityJoinField_Clear := TRUE, p_JoinEntityInverseJoinField := p_JoinEntityInverseJoinField_0a22fac07137, p_JoinEntityInverseJoinField_Clear := TRUE, p_DisplayInForm := p_DisplayInForm_0a22fac07137, p_DisplayLocation := p_DisplayLocation_0a22fac07137, p_DisplayName := p_DisplayName_0a22fac07137, p_DisplayIconType := p_DisplayIconType_0a22fac07137, p_DisplayIcon := p_DisplayIcon_0a22fac07137, p_DisplayIcon_Clear := TRUE, p_DisplayComponentID := p_DisplayComponentID_0a22fac07137, p_DisplayComponentID_Clear := TRUE, p_DisplayComponentConfiguration := p_DisplayComponentConfiguration_0a22fac07137, p_DisplayComponentConfiguration_Clear := TRUE, p_AutoUpdateFromSchema := p_AutoUpdateFromSchema_0a22fac07137, p_AdditionalFieldsToInclude := p_AdditionalFieldsToInclude_0a22fac07137, p_AdditionalFieldsToInclude_Clear := TRUE, p_AutoUpdateAdditionalFieldsToInclude := p_AutoUpdateAdditionalFieldsToInclude_0a22fac07137, p_RelatedRecordCollection := p_RelatedRecordCollection_0a22fac07137, p_Configuration := p_Configuration_0a22fac07137, p_ID := p_ID_0a22fac07137);
  END IF;
END $mj$;

-- Save MJ: Entity Relationships (core SP call only)
DO $mj$
DECLARE
  p_EntityID_31b202ac1bc1 UUID;
  p_Sequence_31b202ac1bc1 INTEGER;
  p_RelatedEntityID_31b202ac1bc1 UUID;
  p_BundleInAPI_31b202ac1bc1 BOOLEAN;
  p_IncludeInParentAllQuery_31b202ac1bc1 BOOLEAN;
  p_Type_31b202ac1bc1 CHAR(20);
  p_EntityKeyField_31b202ac1bc1 VARCHAR(255);
  p_RelatedEntityJoinField_31b202ac1bc1 VARCHAR(255);
  p_JoinView_31b202ac1bc1 VARCHAR(255);
  p_JoinEntityJoinField_31b202ac1bc1 VARCHAR(255);
  p_JoinEntityInverseJoinField_31b202ac1bc1 VARCHAR(255);
  p_DisplayInForm_31b202ac1bc1 BOOLEAN;
  p_DisplayLocation_31b202ac1bc1 VARCHAR(50);
  p_DisplayName_31b202ac1bc1 VARCHAR(255);
  p_DisplayIconType_31b202ac1bc1 VARCHAR(50);
  p_DisplayIcon_31b202ac1bc1 VARCHAR(255);
  p_DisplayComponentID_31b202ac1bc1 UUID;
  p_DisplayComponentConfiguration_31b202ac1bc1 TEXT;
  p_AutoUpdateFromSchema_31b202ac1bc1 BOOLEAN;
  p_AdditionalFieldsToInclude_31b202ac1bc1 TEXT;
  p_AutoUpdateAdditionalFieldsToInclude_31b202ac1bc1 BOOLEAN;
  p_RelatedRecordCollection_31b202ac1bc1 TEXT;
  p_Configuration_31b202ac1bc1 TEXT;
  p_ID_31b202ac1bc1 UUID;
BEGIN
  p_EntityID_31b202ac1bc1 := '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F';
  p_Sequence_31b202ac1bc1 := 5;
  p_RelatedEntityID_31b202ac1bc1 := '709CA9DA-B124-4155-BE39-E857EF672D82';
  p_BundleInAPI_31b202ac1bc1 := TRUE;
  p_IncludeInParentAllQuery_31b202ac1bc1 := FALSE;
  p_Type_31b202ac1bc1 := 'One To Many';
  p_RelatedEntityJoinField_31b202ac1bc1 := 'FromPersonID';
  p_DisplayInForm_31b202ac1bc1 := TRUE;
  p_DisplayLocation_31b202ac1bc1 := 'After Field Tabs';
  p_DisplayName_31b202ac1bc1 := 'MJ_BizApps_Common: Relationships';
  p_DisplayIconType_31b202ac1bc1 := 'Related Entity Icon';
  p_AutoUpdateFromSchema_31b202ac1bc1 := TRUE;
  p_AutoUpdateAdditionalFieldsToInclude_31b202ac1bc1 := TRUE;
  p_RelatedRecordCollection_31b202ac1bc1 := '{
  "Name": "OutgoingRelationships",
  "Load": "explicit",
  "OnRemove": "delete"
}';
  p_Configuration_31b202ac1bc1 := '{
  "UI": {
    "inclusion": "Primary",
    "whenEmpty": "more"
  }
}';
  p_ID_31b202ac1bc1 := 'C37CBF7A-9F75-4210-B2C5-7B64F8E9480D';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityRelationship'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_data := jsonb_build_object(
    'EntityID', p_EntityID_31b202ac1bc1,
    'Sequence', p_Sequence_31b202ac1bc1,
    'RelatedEntityID', p_RelatedEntityID_31b202ac1bc1,
    'BundleInAPI', p_BundleInAPI_31b202ac1bc1,
    'IncludeInParentAllQuery', p_IncludeInParentAllQuery_31b202ac1bc1,
    'Type', p_Type_31b202ac1bc1,
    'EntityKeyField', p_EntityKeyField_31b202ac1bc1,
    'RelatedEntityJoinField', p_RelatedEntityJoinField_31b202ac1bc1,
    'JoinView', p_JoinView_31b202ac1bc1,
    'JoinEntityJoinField', p_JoinEntityJoinField_31b202ac1bc1,
    'JoinEntityInverseJoinField', p_JoinEntityInverseJoinField_31b202ac1bc1,
    'DisplayInForm', p_DisplayInForm_31b202ac1bc1,
    'DisplayLocation', p_DisplayLocation_31b202ac1bc1,
    'DisplayName', p_DisplayName_31b202ac1bc1,
    'DisplayIconType', p_DisplayIconType_31b202ac1bc1,
    'DisplayIcon', p_DisplayIcon_31b202ac1bc1,
    'DisplayComponentID', p_DisplayComponentID_31b202ac1bc1,
    'DisplayComponentConfiguration', p_DisplayComponentConfiguration_31b202ac1bc1,
    'AutoUpdateFromSchema', p_AutoUpdateFromSchema_31b202ac1bc1,
    'AdditionalFieldsToInclude', p_AdditionalFieldsToInclude_31b202ac1bc1,
    'AutoUpdateAdditionalFieldsToInclude', p_AutoUpdateAdditionalFieldsToInclude_31b202ac1bc1,
    'RelatedRecordCollection', p_RelatedRecordCollection_31b202ac1bc1,
    'Configuration', p_Configuration_31b202ac1bc1,
    'ID', p_ID_31b202ac1bc1
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_EntityID := p_EntityID_31b202ac1bc1, p_Sequence := p_Sequence_31b202ac1bc1, p_RelatedEntityID := p_RelatedEntityID_31b202ac1bc1, p_BundleInAPI := p_BundleInAPI_31b202ac1bc1, p_IncludeInParentAllQuery := p_IncludeInParentAllQuery_31b202ac1bc1, p_Type := p_Type_31b202ac1bc1, p_EntityKeyField := p_EntityKeyField_31b202ac1bc1, p_EntityKeyField_Clear := TRUE, p_RelatedEntityJoinField := p_RelatedEntityJoinField_31b202ac1bc1, p_JoinView := p_JoinView_31b202ac1bc1, p_JoinView_Clear := TRUE, p_JoinEntityJoinField := p_JoinEntityJoinField_31b202ac1bc1, p_JoinEntityJoinField_Clear := TRUE, p_JoinEntityInverseJoinField := p_JoinEntityInverseJoinField_31b202ac1bc1, p_JoinEntityInverseJoinField_Clear := TRUE, p_DisplayInForm := p_DisplayInForm_31b202ac1bc1, p_DisplayLocation := p_DisplayLocation_31b202ac1bc1, p_DisplayName := p_DisplayName_31b202ac1bc1, p_DisplayIconType := p_DisplayIconType_31b202ac1bc1, p_DisplayIcon := p_DisplayIcon_31b202ac1bc1, p_DisplayIcon_Clear := TRUE, p_DisplayComponentID := p_DisplayComponentID_31b202ac1bc1, p_DisplayComponentID_Clear := TRUE, p_DisplayComponentConfiguration := p_DisplayComponentConfiguration_31b202ac1bc1, p_DisplayComponentConfiguration_Clear := TRUE, p_AutoUpdateFromSchema := p_AutoUpdateFromSchema_31b202ac1bc1, p_AdditionalFieldsToInclude := p_AdditionalFieldsToInclude_31b202ac1bc1, p_AdditionalFieldsToInclude_Clear := TRUE, p_AutoUpdateAdditionalFieldsToInclude := p_AutoUpdateAdditionalFieldsToInclude_31b202ac1bc1, p_RelatedRecordCollection := p_RelatedRecordCollection_31b202ac1bc1, p_Configuration := p_Configuration_31b202ac1bc1, p_ID := p_ID_31b202ac1bc1);
  END IF;
END $mj$;

-- Save MJ: Entity Relationships (core SP call only)
DO $mj$
DECLARE
  p_EntityID_190389883710 UUID;
  p_Sequence_190389883710 INTEGER;
  p_RelatedEntityID_190389883710 UUID;
  p_BundleInAPI_190389883710 BOOLEAN;
  p_IncludeInParentAllQuery_190389883710 BOOLEAN;
  p_Type_190389883710 CHAR(20);
  p_EntityKeyField_190389883710 VARCHAR(255);
  p_RelatedEntityJoinField_190389883710 VARCHAR(255);
  p_JoinView_190389883710 VARCHAR(255);
  p_JoinEntityJoinField_190389883710 VARCHAR(255);
  p_JoinEntityInverseJoinField_190389883710 VARCHAR(255);
  p_DisplayInForm_190389883710 BOOLEAN;
  p_DisplayLocation_190389883710 VARCHAR(50);
  p_DisplayName_190389883710 VARCHAR(255);
  p_DisplayIconType_190389883710 VARCHAR(50);
  p_DisplayIcon_190389883710 VARCHAR(255);
  p_DisplayComponentID_190389883710 UUID;
  p_DisplayComponentConfiguration_190389883710 TEXT;
  p_AutoUpdateFromSchema_190389883710 BOOLEAN;
  p_AdditionalFieldsToInclude_190389883710 TEXT;
  p_AutoUpdateAdditionalFieldsToInclude_190389883710 BOOLEAN;
  p_RelatedRecordCollection_190389883710 TEXT;
  p_Configuration_190389883710 TEXT;
  p_ID_190389883710 UUID;
BEGIN
  p_EntityID_190389883710 := 'C70448F9-9792-41D7-A82C-784B66429D54';
  p_Sequence_190389883710 := 2;
  p_RelatedEntityID_190389883710 := '32C45078-D33B-4760-9BE5-0DF7F483F591';
  p_BundleInAPI_190389883710 := TRUE;
  p_IncludeInParentAllQuery_190389883710 := FALSE;
  p_Type_190389883710 := 'One To Many';
  p_RelatedEntityJoinField_190389883710 := 'OrganizationID';
  p_DisplayInForm_190389883710 := TRUE;
  p_DisplayLocation_190389883710 := 'After Field Tabs';
  p_DisplayName_190389883710 := 'MJ_BizApps_Common: Contact Methods';
  p_DisplayIconType_190389883710 := 'Related Entity Icon';
  p_AutoUpdateFromSchema_190389883710 := TRUE;
  p_AutoUpdateAdditionalFieldsToInclude_190389883710 := TRUE;
  p_RelatedRecordCollection_190389883710 := '{
  "Name": "ContactMethods",
  "Load": "explicit",
  "OnRemove": "delete"
}';
  p_Configuration_190389883710 := '{
  "UI": {
    "inclusion": "Primary",
    "whenEmpty": "show"
  }
}';
  p_ID_190389883710 := '4D7A3D74-4E29-4FEA-98F1-2D870A226A63';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityRelationship'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_data := jsonb_build_object(
    'EntityID', p_EntityID_190389883710,
    'Sequence', p_Sequence_190389883710,
    'RelatedEntityID', p_RelatedEntityID_190389883710,
    'BundleInAPI', p_BundleInAPI_190389883710,
    'IncludeInParentAllQuery', p_IncludeInParentAllQuery_190389883710,
    'Type', p_Type_190389883710,
    'EntityKeyField', p_EntityKeyField_190389883710,
    'RelatedEntityJoinField', p_RelatedEntityJoinField_190389883710,
    'JoinView', p_JoinView_190389883710,
    'JoinEntityJoinField', p_JoinEntityJoinField_190389883710,
    'JoinEntityInverseJoinField', p_JoinEntityInverseJoinField_190389883710,
    'DisplayInForm', p_DisplayInForm_190389883710,
    'DisplayLocation', p_DisplayLocation_190389883710,
    'DisplayName', p_DisplayName_190389883710,
    'DisplayIconType', p_DisplayIconType_190389883710,
    'DisplayIcon', p_DisplayIcon_190389883710,
    'DisplayComponentID', p_DisplayComponentID_190389883710,
    'DisplayComponentConfiguration', p_DisplayComponentConfiguration_190389883710,
    'AutoUpdateFromSchema', p_AutoUpdateFromSchema_190389883710,
    'AdditionalFieldsToInclude', p_AdditionalFieldsToInclude_190389883710,
    'AutoUpdateAdditionalFieldsToInclude', p_AutoUpdateAdditionalFieldsToInclude_190389883710,
    'RelatedRecordCollection', p_RelatedRecordCollection_190389883710,
    'Configuration', p_Configuration_190389883710,
    'ID', p_ID_190389883710
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_EntityID := p_EntityID_190389883710, p_Sequence := p_Sequence_190389883710, p_RelatedEntityID := p_RelatedEntityID_190389883710, p_BundleInAPI := p_BundleInAPI_190389883710, p_IncludeInParentAllQuery := p_IncludeInParentAllQuery_190389883710, p_Type := p_Type_190389883710, p_EntityKeyField := p_EntityKeyField_190389883710, p_EntityKeyField_Clear := TRUE, p_RelatedEntityJoinField := p_RelatedEntityJoinField_190389883710, p_JoinView := p_JoinView_190389883710, p_JoinView_Clear := TRUE, p_JoinEntityJoinField := p_JoinEntityJoinField_190389883710, p_JoinEntityJoinField_Clear := TRUE, p_JoinEntityInverseJoinField := p_JoinEntityInverseJoinField_190389883710, p_JoinEntityInverseJoinField_Clear := TRUE, p_DisplayInForm := p_DisplayInForm_190389883710, p_DisplayLocation := p_DisplayLocation_190389883710, p_DisplayName := p_DisplayName_190389883710, p_DisplayIconType := p_DisplayIconType_190389883710, p_DisplayIcon := p_DisplayIcon_190389883710, p_DisplayIcon_Clear := TRUE, p_DisplayComponentID := p_DisplayComponentID_190389883710, p_DisplayComponentID_Clear := TRUE, p_DisplayComponentConfiguration := p_DisplayComponentConfiguration_190389883710, p_DisplayComponentConfiguration_Clear := TRUE, p_AutoUpdateFromSchema := p_AutoUpdateFromSchema_190389883710, p_AdditionalFieldsToInclude := p_AdditionalFieldsToInclude_190389883710, p_AdditionalFieldsToInclude_Clear := TRUE, p_AutoUpdateAdditionalFieldsToInclude := p_AutoUpdateAdditionalFieldsToInclude_190389883710, p_RelatedRecordCollection := p_RelatedRecordCollection_190389883710, p_Configuration := p_Configuration_190389883710, p_ID := p_ID_190389883710);
  END IF;
END $mj$;

-- Save MJ: Entity Relationships (core SP call only)
DO $mj$
DECLARE
  p_EntityID_4f379f38bb14 UUID;
  p_Sequence_4f379f38bb14 INTEGER;
  p_RelatedEntityID_4f379f38bb14 UUID;
  p_BundleInAPI_4f379f38bb14 BOOLEAN;
  p_IncludeInParentAllQuery_4f379f38bb14 BOOLEAN;
  p_Type_4f379f38bb14 CHAR(20);
  p_EntityKeyField_4f379f38bb14 VARCHAR(255);
  p_RelatedEntityJoinField_4f379f38bb14 VARCHAR(255);
  p_JoinView_4f379f38bb14 VARCHAR(255);
  p_JoinEntityJoinField_4f379f38bb14 VARCHAR(255);
  p_JoinEntityInverseJoinField_4f379f38bb14 VARCHAR(255);
  p_DisplayInForm_4f379f38bb14 BOOLEAN;
  p_DisplayLocation_4f379f38bb14 VARCHAR(50);
  p_DisplayName_4f379f38bb14 VARCHAR(255);
  p_DisplayIconType_4f379f38bb14 VARCHAR(50);
  p_DisplayIcon_4f379f38bb14 VARCHAR(255);
  p_DisplayComponentID_4f379f38bb14 UUID;
  p_DisplayComponentConfiguration_4f379f38bb14 TEXT;
  p_AutoUpdateFromSchema_4f379f38bb14 BOOLEAN;
  p_AdditionalFieldsToInclude_4f379f38bb14 TEXT;
  p_AutoUpdateAdditionalFieldsToInclude_4f379f38bb14 BOOLEAN;
  p_RelatedRecordCollection_4f379f38bb14 TEXT;
  p_Configuration_4f379f38bb14 TEXT;
  p_ID_4f379f38bb14 UUID;
BEGIN
  p_EntityID_4f379f38bb14 := 'C70448F9-9792-41D7-A82C-784B66429D54';
  p_Sequence_4f379f38bb14 := 2;
  p_RelatedEntityID_4f379f38bb14 := '709CA9DA-B124-4155-BE39-E857EF672D82';
  p_BundleInAPI_4f379f38bb14 := TRUE;
  p_IncludeInParentAllQuery_4f379f38bb14 := FALSE;
  p_Type_4f379f38bb14 := 'One To Many';
  p_RelatedEntityJoinField_4f379f38bb14 := 'FromOrganizationID';
  p_DisplayInForm_4f379f38bb14 := TRUE;
  p_DisplayLocation_4f379f38bb14 := 'After Field Tabs';
  p_DisplayName_4f379f38bb14 := 'MJ_BizApps_Common: Relationships';
  p_DisplayIconType_4f379f38bb14 := 'Related Entity Icon';
  p_AutoUpdateFromSchema_4f379f38bb14 := TRUE;
  p_AutoUpdateAdditionalFieldsToInclude_4f379f38bb14 := TRUE;
  p_RelatedRecordCollection_4f379f38bb14 := '{
  "Name": "OutgoingRelationships",
  "Load": "explicit",
  "OnRemove": "delete"
}';
  p_Configuration_4f379f38bb14 := '{
  "UI": {
    "inclusion": "Primary",
    "whenEmpty": "more"
  }
}';
  p_ID_4f379f38bb14 := '1997A9D1-921A-4AF2-9F04-A42BD22163A4';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityRelationship'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_data := jsonb_build_object(
    'EntityID', p_EntityID_4f379f38bb14,
    'Sequence', p_Sequence_4f379f38bb14,
    'RelatedEntityID', p_RelatedEntityID_4f379f38bb14,
    'BundleInAPI', p_BundleInAPI_4f379f38bb14,
    'IncludeInParentAllQuery', p_IncludeInParentAllQuery_4f379f38bb14,
    'Type', p_Type_4f379f38bb14,
    'EntityKeyField', p_EntityKeyField_4f379f38bb14,
    'RelatedEntityJoinField', p_RelatedEntityJoinField_4f379f38bb14,
    'JoinView', p_JoinView_4f379f38bb14,
    'JoinEntityJoinField', p_JoinEntityJoinField_4f379f38bb14,
    'JoinEntityInverseJoinField', p_JoinEntityInverseJoinField_4f379f38bb14,
    'DisplayInForm', p_DisplayInForm_4f379f38bb14,
    'DisplayLocation', p_DisplayLocation_4f379f38bb14,
    'DisplayName', p_DisplayName_4f379f38bb14,
    'DisplayIconType', p_DisplayIconType_4f379f38bb14,
    'DisplayIcon', p_DisplayIcon_4f379f38bb14,
    'DisplayComponentID', p_DisplayComponentID_4f379f38bb14,
    'DisplayComponentConfiguration', p_DisplayComponentConfiguration_4f379f38bb14,
    'AutoUpdateFromSchema', p_AutoUpdateFromSchema_4f379f38bb14,
    'AdditionalFieldsToInclude', p_AdditionalFieldsToInclude_4f379f38bb14,
    'AutoUpdateAdditionalFieldsToInclude', p_AutoUpdateAdditionalFieldsToInclude_4f379f38bb14,
    'RelatedRecordCollection', p_RelatedRecordCollection_4f379f38bb14,
    'Configuration', p_Configuration_4f379f38bb14,
    'ID', p_ID_4f379f38bb14
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_EntityID := p_EntityID_4f379f38bb14, p_Sequence := p_Sequence_4f379f38bb14, p_RelatedEntityID := p_RelatedEntityID_4f379f38bb14, p_BundleInAPI := p_BundleInAPI_4f379f38bb14, p_IncludeInParentAllQuery := p_IncludeInParentAllQuery_4f379f38bb14, p_Type := p_Type_4f379f38bb14, p_EntityKeyField := p_EntityKeyField_4f379f38bb14, p_EntityKeyField_Clear := TRUE, p_RelatedEntityJoinField := p_RelatedEntityJoinField_4f379f38bb14, p_JoinView := p_JoinView_4f379f38bb14, p_JoinView_Clear := TRUE, p_JoinEntityJoinField := p_JoinEntityJoinField_4f379f38bb14, p_JoinEntityJoinField_Clear := TRUE, p_JoinEntityInverseJoinField := p_JoinEntityInverseJoinField_4f379f38bb14, p_JoinEntityInverseJoinField_Clear := TRUE, p_DisplayInForm := p_DisplayInForm_4f379f38bb14, p_DisplayLocation := p_DisplayLocation_4f379f38bb14, p_DisplayName := p_DisplayName_4f379f38bb14, p_DisplayIconType := p_DisplayIconType_4f379f38bb14, p_DisplayIcon := p_DisplayIcon_4f379f38bb14, p_DisplayIcon_Clear := TRUE, p_DisplayComponentID := p_DisplayComponentID_4f379f38bb14, p_DisplayComponentID_Clear := TRUE, p_DisplayComponentConfiguration := p_DisplayComponentConfiguration_4f379f38bb14, p_DisplayComponentConfiguration_Clear := TRUE, p_AutoUpdateFromSchema := p_AutoUpdateFromSchema_4f379f38bb14, p_AdditionalFieldsToInclude := p_AdditionalFieldsToInclude_4f379f38bb14, p_AdditionalFieldsToInclude_Clear := TRUE, p_AutoUpdateAdditionalFieldsToInclude := p_AutoUpdateAdditionalFieldsToInclude_4f379f38bb14, p_RelatedRecordCollection := p_RelatedRecordCollection_4f379f38bb14, p_Configuration := p_Configuration_4f379f38bb14, p_ID := p_ID_4f379f38bb14);
  END IF;
END $mj$;

-- Save MJ: Entity Relationships (core SP call only)
DO $mj$
DECLARE
  p_EntityID_4ffcd790f552 UUID;
  p_Sequence_4ffcd790f552 INTEGER;
  p_RelatedEntityID_4ffcd790f552 UUID;
  p_BundleInAPI_4ffcd790f552 BOOLEAN;
  p_IncludeInParentAllQuery_4ffcd790f552 BOOLEAN;
  p_Type_4ffcd790f552 CHAR(20);
  p_EntityKeyField_4ffcd790f552 VARCHAR(255);
  p_RelatedEntityJoinField_4ffcd790f552 VARCHAR(255);
  p_JoinView_4ffcd790f552 VARCHAR(255);
  p_JoinEntityJoinField_4ffcd790f552 VARCHAR(255);
  p_JoinEntityInverseJoinField_4ffcd790f552 VARCHAR(255);
  p_DisplayInForm_4ffcd790f552 BOOLEAN;
  p_DisplayLocation_4ffcd790f552 VARCHAR(50);
  p_DisplayName_4ffcd790f552 VARCHAR(255);
  p_DisplayIconType_4ffcd790f552 VARCHAR(50);
  p_DisplayIcon_4ffcd790f552 VARCHAR(255);
  p_DisplayComponentID_4ffcd790f552 UUID;
  p_DisplayComponentConfiguration_4ffcd790f552 TEXT;
  p_AutoUpdateFromSchema_4ffcd790f552 BOOLEAN;
  p_AdditionalFieldsToInclude_4ffcd790f552 TEXT;
  p_AutoUpdateAdditionalFieldsToInclude_4ffcd790f552 BOOLEAN;
  p_RelatedRecordCollection_4ffcd790f552 TEXT;
  p_Configuration_4ffcd790f552 TEXT;
  p_ID_4ffcd790f552 UUID;
BEGIN
  p_EntityID_4ffcd790f552 := 'C70448F9-9792-41D7-A82C-784B66429D54';
  p_Sequence_4ffcd790f552 := 1;
  p_RelatedEntityID_4ffcd790f552 := 'C70448F9-9792-41D7-A82C-784B66429D54';
  p_BundleInAPI_4ffcd790f552 := TRUE;
  p_IncludeInParentAllQuery_4ffcd790f552 := FALSE;
  p_Type_4ffcd790f552 := 'One To Many';
  p_RelatedEntityJoinField_4ffcd790f552 := 'ParentID';
  p_DisplayInForm_4ffcd790f552 := TRUE;
  p_DisplayLocation_4ffcd790f552 := 'After Field Tabs';
  p_DisplayName_4ffcd790f552 := 'MJ_BizApps_Common: Organizations';
  p_DisplayIconType_4ffcd790f552 := 'Related Entity Icon';
  p_AutoUpdateFromSchema_4ffcd790f552 := TRUE;
  p_AutoUpdateAdditionalFieldsToInclude_4ffcd790f552 := TRUE;
  p_RelatedRecordCollection_4ffcd790f552 := '{
  "Name": "ChildOrganizations",
  "Load": "explicit",
  "OnRemove": "orphan"
}';
  p_Configuration_4ffcd790f552 := '{
  "UI": {
    "inclusion": "Primary",
    "whenEmpty": "more"
  }
}';
  p_ID_4ffcd790f552 := '9D170FC9-ECE8-4A03-A857-54CCAF628836';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityRelationship'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_data := jsonb_build_object(
    'EntityID', p_EntityID_4ffcd790f552,
    'Sequence', p_Sequence_4ffcd790f552,
    'RelatedEntityID', p_RelatedEntityID_4ffcd790f552,
    'BundleInAPI', p_BundleInAPI_4ffcd790f552,
    'IncludeInParentAllQuery', p_IncludeInParentAllQuery_4ffcd790f552,
    'Type', p_Type_4ffcd790f552,
    'EntityKeyField', p_EntityKeyField_4ffcd790f552,
    'RelatedEntityJoinField', p_RelatedEntityJoinField_4ffcd790f552,
    'JoinView', p_JoinView_4ffcd790f552,
    'JoinEntityJoinField', p_JoinEntityJoinField_4ffcd790f552,
    'JoinEntityInverseJoinField', p_JoinEntityInverseJoinField_4ffcd790f552,
    'DisplayInForm', p_DisplayInForm_4ffcd790f552,
    'DisplayLocation', p_DisplayLocation_4ffcd790f552,
    'DisplayName', p_DisplayName_4ffcd790f552,
    'DisplayIconType', p_DisplayIconType_4ffcd790f552,
    'DisplayIcon', p_DisplayIcon_4ffcd790f552,
    'DisplayComponentID', p_DisplayComponentID_4ffcd790f552,
    'DisplayComponentConfiguration', p_DisplayComponentConfiguration_4ffcd790f552,
    'AutoUpdateFromSchema', p_AutoUpdateFromSchema_4ffcd790f552,
    'AdditionalFieldsToInclude', p_AdditionalFieldsToInclude_4ffcd790f552,
    'AutoUpdateAdditionalFieldsToInclude', p_AutoUpdateAdditionalFieldsToInclude_4ffcd790f552,
    'RelatedRecordCollection', p_RelatedRecordCollection_4ffcd790f552,
    'Configuration', p_Configuration_4ffcd790f552,
    'ID', p_ID_4ffcd790f552
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_EntityID := p_EntityID_4ffcd790f552, p_Sequence := p_Sequence_4ffcd790f552, p_RelatedEntityID := p_RelatedEntityID_4ffcd790f552, p_BundleInAPI := p_BundleInAPI_4ffcd790f552, p_IncludeInParentAllQuery := p_IncludeInParentAllQuery_4ffcd790f552, p_Type := p_Type_4ffcd790f552, p_EntityKeyField := p_EntityKeyField_4ffcd790f552, p_EntityKeyField_Clear := TRUE, p_RelatedEntityJoinField := p_RelatedEntityJoinField_4ffcd790f552, p_JoinView := p_JoinView_4ffcd790f552, p_JoinView_Clear := TRUE, p_JoinEntityJoinField := p_JoinEntityJoinField_4ffcd790f552, p_JoinEntityJoinField_Clear := TRUE, p_JoinEntityInverseJoinField := p_JoinEntityInverseJoinField_4ffcd790f552, p_JoinEntityInverseJoinField_Clear := TRUE, p_DisplayInForm := p_DisplayInForm_4ffcd790f552, p_DisplayLocation := p_DisplayLocation_4ffcd790f552, p_DisplayName := p_DisplayName_4ffcd790f552, p_DisplayIconType := p_DisplayIconType_4ffcd790f552, p_DisplayIcon := p_DisplayIcon_4ffcd790f552, p_DisplayIcon_Clear := TRUE, p_DisplayComponentID := p_DisplayComponentID_4ffcd790f552, p_DisplayComponentID_Clear := TRUE, p_DisplayComponentConfiguration := p_DisplayComponentConfiguration_4ffcd790f552, p_DisplayComponentConfiguration_Clear := TRUE, p_AutoUpdateFromSchema := p_AutoUpdateFromSchema_4ffcd790f552, p_AdditionalFieldsToInclude := p_AdditionalFieldsToInclude_4ffcd790f552, p_AdditionalFieldsToInclude_Clear := TRUE, p_AutoUpdateAdditionalFieldsToInclude := p_AutoUpdateAdditionalFieldsToInclude_4ffcd790f552, p_RelatedRecordCollection := p_RelatedRecordCollection_4ffcd790f552, p_Configuration := p_Configuration_4ffcd790f552, p_ID := p_ID_4ffcd790f552);
  END IF;
END $mj$;

-- Save MJ: Entity Relationships (core SP call only)
DO $mj$
DECLARE
  p_EntityID_c20c4146f254 UUID;
  p_Sequence_c20c4146f254 INTEGER;
  p_RelatedEntityID_c20c4146f254 UUID;
  p_BundleInAPI_c20c4146f254 BOOLEAN;
  p_IncludeInParentAllQuery_c20c4146f254 BOOLEAN;
  p_Type_c20c4146f254 CHAR(20);
  p_EntityKeyField_c20c4146f254 VARCHAR(255);
  p_RelatedEntityJoinField_c20c4146f254 VARCHAR(255);
  p_JoinView_c20c4146f254 VARCHAR(255);
  p_JoinEntityJoinField_c20c4146f254 VARCHAR(255);
  p_JoinEntityInverseJoinField_c20c4146f254 VARCHAR(255);
  p_DisplayInForm_c20c4146f254 BOOLEAN;
  p_DisplayLocation_c20c4146f254 VARCHAR(50);
  p_DisplayName_c20c4146f254 VARCHAR(255);
  p_DisplayIconType_c20c4146f254 VARCHAR(50);
  p_DisplayIcon_c20c4146f254 VARCHAR(255);
  p_DisplayComponentID_c20c4146f254 UUID;
  p_DisplayComponentConfiguration_c20c4146f254 TEXT;
  p_AutoUpdateFromSchema_c20c4146f254 BOOLEAN;
  p_AdditionalFieldsToInclude_c20c4146f254 TEXT;
  p_AutoUpdateAdditionalFieldsToInclude_c20c4146f254 BOOLEAN;
  p_RelatedRecordCollection_c20c4146f254 TEXT;
  p_Configuration_c20c4146f254 TEXT;
  p_ID_c20c4146f254 UUID;
BEGIN
  p_EntityID_c20c4146f254 := '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F';
  p_Sequence_c20c4146f254 := 4;
  p_RelatedEntityID_c20c4146f254 := '709CA9DA-B124-4155-BE39-E857EF672D82';
  p_BundleInAPI_c20c4146f254 := TRUE;
  p_IncludeInParentAllQuery_c20c4146f254 := FALSE;
  p_Type_c20c4146f254 := 'One To Many';
  p_RelatedEntityJoinField_c20c4146f254 := 'ToPersonID';
  p_DisplayInForm_c20c4146f254 := TRUE;
  p_DisplayLocation_c20c4146f254 := 'After Field Tabs';
  p_DisplayName_c20c4146f254 := 'MJ_BizApps_Common: Relationships';
  p_DisplayIconType_c20c4146f254 := 'Related Entity Icon';
  p_AutoUpdateFromSchema_c20c4146f254 := TRUE;
  p_AutoUpdateAdditionalFieldsToInclude_c20c4146f254 := TRUE;
  p_Configuration_c20c4146f254 := '{
  "UI": {
    "inclusion": "More",
    "whenEmpty": "hide"
  }
}';
  p_ID_c20c4146f254 := 'E5D30B7E-FCBC-49EB-97A7-28E12BD604C9';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityRelationship'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_data := jsonb_build_object(
    'EntityID', p_EntityID_c20c4146f254,
    'Sequence', p_Sequence_c20c4146f254,
    'RelatedEntityID', p_RelatedEntityID_c20c4146f254,
    'BundleInAPI', p_BundleInAPI_c20c4146f254,
    'IncludeInParentAllQuery', p_IncludeInParentAllQuery_c20c4146f254,
    'Type', p_Type_c20c4146f254,
    'EntityKeyField', p_EntityKeyField_c20c4146f254,
    'RelatedEntityJoinField', p_RelatedEntityJoinField_c20c4146f254,
    'JoinView', p_JoinView_c20c4146f254,
    'JoinEntityJoinField', p_JoinEntityJoinField_c20c4146f254,
    'JoinEntityInverseJoinField', p_JoinEntityInverseJoinField_c20c4146f254,
    'DisplayInForm', p_DisplayInForm_c20c4146f254,
    'DisplayLocation', p_DisplayLocation_c20c4146f254,
    'DisplayName', p_DisplayName_c20c4146f254,
    'DisplayIconType', p_DisplayIconType_c20c4146f254,
    'DisplayIcon', p_DisplayIcon_c20c4146f254,
    'DisplayComponentID', p_DisplayComponentID_c20c4146f254,
    'DisplayComponentConfiguration', p_DisplayComponentConfiguration_c20c4146f254,
    'AutoUpdateFromSchema', p_AutoUpdateFromSchema_c20c4146f254,
    'AdditionalFieldsToInclude', p_AdditionalFieldsToInclude_c20c4146f254,
    'AutoUpdateAdditionalFieldsToInclude', p_AutoUpdateAdditionalFieldsToInclude_c20c4146f254,
    'RelatedRecordCollection', p_RelatedRecordCollection_c20c4146f254,
    'Configuration', p_Configuration_c20c4146f254,
    'ID', p_ID_c20c4146f254
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_EntityID := p_EntityID_c20c4146f254, p_Sequence := p_Sequence_c20c4146f254, p_RelatedEntityID := p_RelatedEntityID_c20c4146f254, p_BundleInAPI := p_BundleInAPI_c20c4146f254, p_IncludeInParentAllQuery := p_IncludeInParentAllQuery_c20c4146f254, p_Type := p_Type_c20c4146f254, p_EntityKeyField := p_EntityKeyField_c20c4146f254, p_EntityKeyField_Clear := TRUE, p_RelatedEntityJoinField := p_RelatedEntityJoinField_c20c4146f254, p_JoinView := p_JoinView_c20c4146f254, p_JoinView_Clear := TRUE, p_JoinEntityJoinField := p_JoinEntityJoinField_c20c4146f254, p_JoinEntityJoinField_Clear := TRUE, p_JoinEntityInverseJoinField := p_JoinEntityInverseJoinField_c20c4146f254, p_JoinEntityInverseJoinField_Clear := TRUE, p_DisplayInForm := p_DisplayInForm_c20c4146f254, p_DisplayLocation := p_DisplayLocation_c20c4146f254, p_DisplayName := p_DisplayName_c20c4146f254, p_DisplayIconType := p_DisplayIconType_c20c4146f254, p_DisplayIcon := p_DisplayIcon_c20c4146f254, p_DisplayIcon_Clear := TRUE, p_DisplayComponentID := p_DisplayComponentID_c20c4146f254, p_DisplayComponentID_Clear := TRUE, p_DisplayComponentConfiguration := p_DisplayComponentConfiguration_c20c4146f254, p_DisplayComponentConfiguration_Clear := TRUE, p_AutoUpdateFromSchema := p_AutoUpdateFromSchema_c20c4146f254, p_AdditionalFieldsToInclude := p_AdditionalFieldsToInclude_c20c4146f254, p_AdditionalFieldsToInclude_Clear := TRUE, p_AutoUpdateAdditionalFieldsToInclude := p_AutoUpdateAdditionalFieldsToInclude_c20c4146f254, p_RelatedRecordCollection := p_RelatedRecordCollection_c20c4146f254, p_RelatedRecordCollection_Clear := TRUE, p_Configuration := p_Configuration_c20c4146f254, p_ID := p_ID_c20c4146f254);
  END IF;
END $mj$;

-- Save MJ: Entity Relationships (core SP call only)
DO $mj$
DECLARE
  p_EntityID_f72345925ff6 UUID;
  p_Sequence_f72345925ff6 INTEGER;
  p_RelatedEntityID_f72345925ff6 UUID;
  p_BundleInAPI_f72345925ff6 BOOLEAN;
  p_IncludeInParentAllQuery_f72345925ff6 BOOLEAN;
  p_Type_f72345925ff6 CHAR(20);
  p_EntityKeyField_f72345925ff6 VARCHAR(255);
  p_RelatedEntityJoinField_f72345925ff6 VARCHAR(255);
  p_JoinView_f72345925ff6 VARCHAR(255);
  p_JoinEntityJoinField_f72345925ff6 VARCHAR(255);
  p_JoinEntityInverseJoinField_f72345925ff6 VARCHAR(255);
  p_DisplayInForm_f72345925ff6 BOOLEAN;
  p_DisplayLocation_f72345925ff6 VARCHAR(50);
  p_DisplayName_f72345925ff6 VARCHAR(255);
  p_DisplayIconType_f72345925ff6 VARCHAR(50);
  p_DisplayIcon_f72345925ff6 VARCHAR(255);
  p_DisplayComponentID_f72345925ff6 UUID;
  p_DisplayComponentConfiguration_f72345925ff6 TEXT;
  p_AutoUpdateFromSchema_f72345925ff6 BOOLEAN;
  p_AdditionalFieldsToInclude_f72345925ff6 TEXT;
  p_AutoUpdateAdditionalFieldsToInclude_f72345925ff6 BOOLEAN;
  p_RelatedRecordCollection_f72345925ff6 TEXT;
  p_Configuration_f72345925ff6 TEXT;
  p_ID_f72345925ff6 UUID;
BEGIN
  p_EntityID_f72345925ff6 := 'C70448F9-9792-41D7-A82C-784B66429D54';
  p_Sequence_f72345925ff6 := 1;
  p_RelatedEntityID_f72345925ff6 := '709CA9DA-B124-4155-BE39-E857EF672D82';
  p_BundleInAPI_f72345925ff6 := TRUE;
  p_IncludeInParentAllQuery_f72345925ff6 := FALSE;
  p_Type_f72345925ff6 := 'One To Many';
  p_RelatedEntityJoinField_f72345925ff6 := 'ToOrganizationID';
  p_DisplayInForm_f72345925ff6 := TRUE;
  p_DisplayLocation_f72345925ff6 := 'After Field Tabs';
  p_DisplayName_f72345925ff6 := 'MJ_BizApps_Common: Relationships';
  p_DisplayIconType_f72345925ff6 := 'Related Entity Icon';
  p_AutoUpdateFromSchema_f72345925ff6 := TRUE;
  p_AutoUpdateAdditionalFieldsToInclude_f72345925ff6 := TRUE;
  p_Configuration_f72345925ff6 := '{
  "UI": {
    "inclusion": "More",
    "whenEmpty": "hide"
  }
}';
  p_ID_f72345925ff6 := 'C1F0A217-026C-44C6-8724-CA4991DC0258';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityRelationship'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_data := jsonb_build_object(
    'EntityID', p_EntityID_f72345925ff6,
    'Sequence', p_Sequence_f72345925ff6,
    'RelatedEntityID', p_RelatedEntityID_f72345925ff6,
    'BundleInAPI', p_BundleInAPI_f72345925ff6,
    'IncludeInParentAllQuery', p_IncludeInParentAllQuery_f72345925ff6,
    'Type', p_Type_f72345925ff6,
    'EntityKeyField', p_EntityKeyField_f72345925ff6,
    'RelatedEntityJoinField', p_RelatedEntityJoinField_f72345925ff6,
    'JoinView', p_JoinView_f72345925ff6,
    'JoinEntityJoinField', p_JoinEntityJoinField_f72345925ff6,
    'JoinEntityInverseJoinField', p_JoinEntityInverseJoinField_f72345925ff6,
    'DisplayInForm', p_DisplayInForm_f72345925ff6,
    'DisplayLocation', p_DisplayLocation_f72345925ff6,
    'DisplayName', p_DisplayName_f72345925ff6,
    'DisplayIconType', p_DisplayIconType_f72345925ff6,
    'DisplayIcon', p_DisplayIcon_f72345925ff6,
    'DisplayComponentID', p_DisplayComponentID_f72345925ff6,
    'DisplayComponentConfiguration', p_DisplayComponentConfiguration_f72345925ff6,
    'AutoUpdateFromSchema', p_AutoUpdateFromSchema_f72345925ff6,
    'AdditionalFieldsToInclude', p_AdditionalFieldsToInclude_f72345925ff6,
    'AutoUpdateAdditionalFieldsToInclude', p_AutoUpdateAdditionalFieldsToInclude_f72345925ff6,
    'RelatedRecordCollection', p_RelatedRecordCollection_f72345925ff6,
    'Configuration', p_Configuration_f72345925ff6,
    'ID', p_ID_f72345925ff6
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_EntityID := p_EntityID_f72345925ff6, p_Sequence := p_Sequence_f72345925ff6, p_RelatedEntityID := p_RelatedEntityID_f72345925ff6, p_BundleInAPI := p_BundleInAPI_f72345925ff6, p_IncludeInParentAllQuery := p_IncludeInParentAllQuery_f72345925ff6, p_Type := p_Type_f72345925ff6, p_EntityKeyField := p_EntityKeyField_f72345925ff6, p_EntityKeyField_Clear := TRUE, p_RelatedEntityJoinField := p_RelatedEntityJoinField_f72345925ff6, p_JoinView := p_JoinView_f72345925ff6, p_JoinView_Clear := TRUE, p_JoinEntityJoinField := p_JoinEntityJoinField_f72345925ff6, p_JoinEntityJoinField_Clear := TRUE, p_JoinEntityInverseJoinField := p_JoinEntityInverseJoinField_f72345925ff6, p_JoinEntityInverseJoinField_Clear := TRUE, p_DisplayInForm := p_DisplayInForm_f72345925ff6, p_DisplayLocation := p_DisplayLocation_f72345925ff6, p_DisplayName := p_DisplayName_f72345925ff6, p_DisplayIconType := p_DisplayIconType_f72345925ff6, p_DisplayIcon := p_DisplayIcon_f72345925ff6, p_DisplayIcon_Clear := TRUE, p_DisplayComponentID := p_DisplayComponentID_f72345925ff6, p_DisplayComponentID_Clear := TRUE, p_DisplayComponentConfiguration := p_DisplayComponentConfiguration_f72345925ff6, p_DisplayComponentConfiguration_Clear := TRUE, p_AutoUpdateFromSchema := p_AutoUpdateFromSchema_f72345925ff6, p_AdditionalFieldsToInclude := p_AdditionalFieldsToInclude_f72345925ff6, p_AdditionalFieldsToInclude_Clear := TRUE, p_AutoUpdateAdditionalFieldsToInclude := p_AutoUpdateAdditionalFieldsToInclude_f72345925ff6, p_RelatedRecordCollection := p_RelatedRecordCollection_f72345925ff6, p_RelatedRecordCollection_Clear := TRUE, p_Configuration := p_Configuration_f72345925ff6, p_ID := p_ID_f72345925ff6);
  END IF;
END $mj$;

-- Save MJ: Entity Relationships (core SP call only)
DO $mj$
DECLARE
  p_EntityID_8813b8ff4eeb UUID;
  p_Sequence_8813b8ff4eeb INTEGER;
  p_RelatedEntityID_8813b8ff4eeb UUID;
  p_BundleInAPI_8813b8ff4eeb BOOLEAN;
  p_IncludeInParentAllQuery_8813b8ff4eeb BOOLEAN;
  p_Type_8813b8ff4eeb CHAR(20);
  p_EntityKeyField_8813b8ff4eeb VARCHAR(255);
  p_RelatedEntityJoinField_8813b8ff4eeb VARCHAR(255);
  p_JoinView_8813b8ff4eeb VARCHAR(255);
  p_JoinEntityJoinField_8813b8ff4eeb VARCHAR(255);
  p_JoinEntityInverseJoinField_8813b8ff4eeb VARCHAR(255);
  p_DisplayInForm_8813b8ff4eeb BOOLEAN;
  p_DisplayLocation_8813b8ff4eeb VARCHAR(50);
  p_DisplayName_8813b8ff4eeb VARCHAR(255);
  p_DisplayIconType_8813b8ff4eeb VARCHAR(50);
  p_DisplayIcon_8813b8ff4eeb VARCHAR(255);
  p_DisplayComponentID_8813b8ff4eeb UUID;
  p_DisplayComponentConfiguration_8813b8ff4eeb TEXT;
  p_AutoUpdateFromSchema_8813b8ff4eeb BOOLEAN;
  p_AdditionalFieldsToInclude_8813b8ff4eeb TEXT;
  p_AutoUpdateAdditionalFieldsToInclude_8813b8ff4eeb BOOLEAN;
  p_RelatedRecordCollection_8813b8ff4eeb TEXT;
  p_Configuration_8813b8ff4eeb TEXT;
  p_ID_8813b8ff4eeb UUID;
BEGIN
  p_EntityID_8813b8ff4eeb := '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E';
  p_Sequence_8813b8ff4eeb := 5;
  p_RelatedEntityID_8813b8ff4eeb := '72E55425-8822-4E70-A075-116219CA5A5D';
  p_BundleInAPI_8813b8ff4eeb := TRUE;
  p_IncludeInParentAllQuery_8813b8ff4eeb := FALSE;
  p_Type_8813b8ff4eeb := 'One To Many';
  p_RelatedEntityJoinField_8813b8ff4eeb := 'AddressID';
  p_DisplayInForm_8813b8ff4eeb := TRUE;
  p_DisplayLocation_8813b8ff4eeb := 'After Field Tabs';
  p_DisplayIconType_8813b8ff4eeb := 'Related Entity Icon';
  p_AutoUpdateFromSchema_8813b8ff4eeb := TRUE;
  p_AutoUpdateAdditionalFieldsToInclude_8813b8ff4eeb := TRUE;
  p_Configuration_8813b8ff4eeb := '{
  "UI": {
    "inclusion": "More",
    "whenEmpty": "hide"
  }
}';
  p_ID_8813b8ff4eeb := 'A84C4FB7-B289-48F2-B3DD-5D9AFD24CC84';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityRelationship'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_data := jsonb_build_object(
    'EntityID', p_EntityID_8813b8ff4eeb,
    'Sequence', p_Sequence_8813b8ff4eeb,
    'RelatedEntityID', p_RelatedEntityID_8813b8ff4eeb,
    'BundleInAPI', p_BundleInAPI_8813b8ff4eeb,
    'IncludeInParentAllQuery', p_IncludeInParentAllQuery_8813b8ff4eeb,
    'Type', p_Type_8813b8ff4eeb,
    'EntityKeyField', p_EntityKeyField_8813b8ff4eeb,
    'RelatedEntityJoinField', p_RelatedEntityJoinField_8813b8ff4eeb,
    'JoinView', p_JoinView_8813b8ff4eeb,
    'JoinEntityJoinField', p_JoinEntityJoinField_8813b8ff4eeb,
    'JoinEntityInverseJoinField', p_JoinEntityInverseJoinField_8813b8ff4eeb,
    'DisplayInForm', p_DisplayInForm_8813b8ff4eeb,
    'DisplayLocation', p_DisplayLocation_8813b8ff4eeb,
    'DisplayName', p_DisplayName_8813b8ff4eeb,
    'DisplayIconType', p_DisplayIconType_8813b8ff4eeb,
    'DisplayIcon', p_DisplayIcon_8813b8ff4eeb,
    'DisplayComponentID', p_DisplayComponentID_8813b8ff4eeb,
    'DisplayComponentConfiguration', p_DisplayComponentConfiguration_8813b8ff4eeb,
    'AutoUpdateFromSchema', p_AutoUpdateFromSchema_8813b8ff4eeb,
    'AdditionalFieldsToInclude', p_AdditionalFieldsToInclude_8813b8ff4eeb,
    'AutoUpdateAdditionalFieldsToInclude', p_AutoUpdateAdditionalFieldsToInclude_8813b8ff4eeb,
    'RelatedRecordCollection', p_RelatedRecordCollection_8813b8ff4eeb,
    'Configuration', p_Configuration_8813b8ff4eeb,
    'ID', p_ID_8813b8ff4eeb
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_EntityID := p_EntityID_8813b8ff4eeb, p_Sequence := p_Sequence_8813b8ff4eeb, p_RelatedEntityID := p_RelatedEntityID_8813b8ff4eeb, p_BundleInAPI := p_BundleInAPI_8813b8ff4eeb, p_IncludeInParentAllQuery := p_IncludeInParentAllQuery_8813b8ff4eeb, p_Type := p_Type_8813b8ff4eeb, p_EntityKeyField := p_EntityKeyField_8813b8ff4eeb, p_EntityKeyField_Clear := TRUE, p_RelatedEntityJoinField := p_RelatedEntityJoinField_8813b8ff4eeb, p_JoinView := p_JoinView_8813b8ff4eeb, p_JoinView_Clear := TRUE, p_JoinEntityJoinField := p_JoinEntityJoinField_8813b8ff4eeb, p_JoinEntityJoinField_Clear := TRUE, p_JoinEntityInverseJoinField := p_JoinEntityInverseJoinField_8813b8ff4eeb, p_JoinEntityInverseJoinField_Clear := TRUE, p_DisplayInForm := p_DisplayInForm_8813b8ff4eeb, p_DisplayLocation := p_DisplayLocation_8813b8ff4eeb, p_DisplayName := p_DisplayName_8813b8ff4eeb, p_DisplayName_Clear := TRUE, p_DisplayIconType := p_DisplayIconType_8813b8ff4eeb, p_DisplayIcon := p_DisplayIcon_8813b8ff4eeb, p_DisplayIcon_Clear := TRUE, p_DisplayComponentID := p_DisplayComponentID_8813b8ff4eeb, p_DisplayComponentID_Clear := TRUE, p_DisplayComponentConfiguration := p_DisplayComponentConfiguration_8813b8ff4eeb, p_DisplayComponentConfiguration_Clear := TRUE, p_AutoUpdateFromSchema := p_AutoUpdateFromSchema_8813b8ff4eeb, p_AdditionalFieldsToInclude := p_AdditionalFieldsToInclude_8813b8ff4eeb, p_AdditionalFieldsToInclude_Clear := TRUE, p_AutoUpdateAdditionalFieldsToInclude := p_AutoUpdateAdditionalFieldsToInclude_8813b8ff4eeb, p_RelatedRecordCollection := p_RelatedRecordCollection_8813b8ff4eeb, p_RelatedRecordCollection_Clear := TRUE, p_Configuration := p_Configuration_8813b8ff4eeb, p_ID := p_ID_8813b8ff4eeb);
  END IF;
END $mj$;

-- Save MJ: Entity Relationships (core SP call only)
DO $mj$
DECLARE
  p_EntityID_b5560881804b UUID;
  p_Sequence_b5560881804b INTEGER;
  p_RelatedEntityID_b5560881804b UUID;
  p_BundleInAPI_b5560881804b BOOLEAN;
  p_IncludeInParentAllQuery_b5560881804b BOOLEAN;
  p_Type_b5560881804b CHAR(20);
  p_EntityKeyField_b5560881804b VARCHAR(255);
  p_RelatedEntityJoinField_b5560881804b VARCHAR(255);
  p_JoinView_b5560881804b VARCHAR(255);
  p_JoinEntityJoinField_b5560881804b VARCHAR(255);
  p_JoinEntityInverseJoinField_b5560881804b VARCHAR(255);
  p_DisplayInForm_b5560881804b BOOLEAN;
  p_DisplayLocation_b5560881804b VARCHAR(50);
  p_DisplayName_b5560881804b VARCHAR(255);
  p_DisplayIconType_b5560881804b VARCHAR(50);
  p_DisplayIcon_b5560881804b VARCHAR(255);
  p_DisplayComponentID_b5560881804b UUID;
  p_DisplayComponentConfiguration_b5560881804b TEXT;
  p_AutoUpdateFromSchema_b5560881804b BOOLEAN;
  p_AdditionalFieldsToInclude_b5560881804b TEXT;
  p_AutoUpdateAdditionalFieldsToInclude_b5560881804b BOOLEAN;
  p_RelatedRecordCollection_b5560881804b TEXT;
  p_Configuration_b5560881804b TEXT;
  p_ID_b5560881804b UUID;
BEGIN
  p_EntityID_b5560881804b := '32C45078-D33B-4760-9BE5-0DF7F483F591';
  p_Sequence_b5560881804b := 1;
  p_RelatedEntityID_b5560881804b := '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31';
  p_BundleInAPI_b5560881804b := TRUE;
  p_IncludeInParentAllQuery_b5560881804b := FALSE;
  p_Type_b5560881804b := 'One To Many';
  p_RelatedEntityJoinField_b5560881804b := 'ContactMethodID';
  p_DisplayInForm_b5560881804b := TRUE;
  p_DisplayLocation_b5560881804b := 'After Field Tabs';
  p_DisplayIconType_b5560881804b := 'Related Entity Icon';
  p_AutoUpdateFromSchema_b5560881804b := TRUE;
  p_AutoUpdateAdditionalFieldsToInclude_b5560881804b := TRUE;
  p_RelatedRecordCollection_b5560881804b := '{
  "Name": "Consents",
  "Load": "explicit",
  "OnRemove": "delete"
}';
  p_ID_b5560881804b := 'DC918A16-93FB-4CB2-9669-A7356C582D64';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityRelationship'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_data := jsonb_build_object(
    'EntityID', p_EntityID_b5560881804b,
    'Sequence', p_Sequence_b5560881804b,
    'RelatedEntityID', p_RelatedEntityID_b5560881804b,
    'BundleInAPI', p_BundleInAPI_b5560881804b,
    'IncludeInParentAllQuery', p_IncludeInParentAllQuery_b5560881804b,
    'Type', p_Type_b5560881804b,
    'EntityKeyField', p_EntityKeyField_b5560881804b,
    'RelatedEntityJoinField', p_RelatedEntityJoinField_b5560881804b,
    'JoinView', p_JoinView_b5560881804b,
    'JoinEntityJoinField', p_JoinEntityJoinField_b5560881804b,
    'JoinEntityInverseJoinField', p_JoinEntityInverseJoinField_b5560881804b,
    'DisplayInForm', p_DisplayInForm_b5560881804b,
    'DisplayLocation', p_DisplayLocation_b5560881804b,
    'DisplayName', p_DisplayName_b5560881804b,
    'DisplayIconType', p_DisplayIconType_b5560881804b,
    'DisplayIcon', p_DisplayIcon_b5560881804b,
    'DisplayComponentID', p_DisplayComponentID_b5560881804b,
    'DisplayComponentConfiguration', p_DisplayComponentConfiguration_b5560881804b,
    'AutoUpdateFromSchema', p_AutoUpdateFromSchema_b5560881804b,
    'AdditionalFieldsToInclude', p_AdditionalFieldsToInclude_b5560881804b,
    'AutoUpdateAdditionalFieldsToInclude', p_AutoUpdateAdditionalFieldsToInclude_b5560881804b,
    'RelatedRecordCollection', p_RelatedRecordCollection_b5560881804b,
    'Configuration', p_Configuration_b5560881804b,
    'ID', p_ID_b5560881804b
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_EntityID := p_EntityID_b5560881804b, p_Sequence := p_Sequence_b5560881804b, p_RelatedEntityID := p_RelatedEntityID_b5560881804b, p_BundleInAPI := p_BundleInAPI_b5560881804b, p_IncludeInParentAllQuery := p_IncludeInParentAllQuery_b5560881804b, p_Type := p_Type_b5560881804b, p_EntityKeyField := p_EntityKeyField_b5560881804b, p_EntityKeyField_Clear := TRUE, p_RelatedEntityJoinField := p_RelatedEntityJoinField_b5560881804b, p_JoinView := p_JoinView_b5560881804b, p_JoinView_Clear := TRUE, p_JoinEntityJoinField := p_JoinEntityJoinField_b5560881804b, p_JoinEntityJoinField_Clear := TRUE, p_JoinEntityInverseJoinField := p_JoinEntityInverseJoinField_b5560881804b, p_JoinEntityInverseJoinField_Clear := TRUE, p_DisplayInForm := p_DisplayInForm_b5560881804b, p_DisplayLocation := p_DisplayLocation_b5560881804b, p_DisplayName := p_DisplayName_b5560881804b, p_DisplayName_Clear := TRUE, p_DisplayIconType := p_DisplayIconType_b5560881804b, p_DisplayIcon := p_DisplayIcon_b5560881804b, p_DisplayIcon_Clear := TRUE, p_DisplayComponentID := p_DisplayComponentID_b5560881804b, p_DisplayComponentID_Clear := TRUE, p_DisplayComponentConfiguration := p_DisplayComponentConfiguration_b5560881804b, p_DisplayComponentConfiguration_Clear := TRUE, p_AutoUpdateFromSchema := p_AutoUpdateFromSchema_b5560881804b, p_AdditionalFieldsToInclude := p_AdditionalFieldsToInclude_b5560881804b, p_AdditionalFieldsToInclude_Clear := TRUE, p_AutoUpdateAdditionalFieldsToInclude := p_AutoUpdateAdditionalFieldsToInclude_b5560881804b, p_RelatedRecordCollection := p_RelatedRecordCollection_b5560881804b, p_Configuration := p_Configuration_b5560881804b, p_Configuration_Clear := TRUE, p_ID := p_ID_b5560881804b);
  END IF;
END $mj$;

-- Save MJ: Entity Relationships (core SP call only)
DO $mj$
DECLARE
  p_EntityID_c44192666f37 UUID;
  p_Sequence_c44192666f37 INTEGER;
  p_RelatedEntityID_c44192666f37 UUID;
  p_BundleInAPI_c44192666f37 BOOLEAN;
  p_IncludeInParentAllQuery_c44192666f37 BOOLEAN;
  p_Type_c44192666f37 CHAR(20);
  p_EntityKeyField_c44192666f37 VARCHAR(255);
  p_RelatedEntityJoinField_c44192666f37 VARCHAR(255);
  p_JoinView_c44192666f37 VARCHAR(255);
  p_JoinEntityJoinField_c44192666f37 VARCHAR(255);
  p_JoinEntityInverseJoinField_c44192666f37 VARCHAR(255);
  p_DisplayInForm_c44192666f37 BOOLEAN;
  p_DisplayLocation_c44192666f37 VARCHAR(50);
  p_DisplayName_c44192666f37 VARCHAR(255);
  p_DisplayIconType_c44192666f37 VARCHAR(50);
  p_DisplayIcon_c44192666f37 VARCHAR(255);
  p_DisplayComponentID_c44192666f37 UUID;
  p_DisplayComponentConfiguration_c44192666f37 TEXT;
  p_AutoUpdateFromSchema_c44192666f37 BOOLEAN;
  p_AdditionalFieldsToInclude_c44192666f37 TEXT;
  p_AutoUpdateAdditionalFieldsToInclude_c44192666f37 BOOLEAN;
  p_RelatedRecordCollection_c44192666f37 TEXT;
  p_Configuration_c44192666f37 TEXT;
  p_ID_c44192666f37 UUID;
BEGIN
  p_EntityID_c44192666f37 := '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31';
  p_Sequence_c44192666f37 := 1;
  p_RelatedEntityID_c44192666f37 := 'CA348384-97E9-4A6F-A28B-56DC169C0051';
  p_BundleInAPI_c44192666f37 := TRUE;
  p_IncludeInParentAllQuery_c44192666f37 := FALSE;
  p_Type_c44192666f37 := 'One To Many';
  p_RelatedEntityJoinField_c44192666f37 := 'ContactMethodConsentID';
  p_DisplayInForm_c44192666f37 := TRUE;
  p_DisplayLocation_c44192666f37 := 'After Field Tabs';
  p_DisplayIconType_c44192666f37 := 'Related Entity Icon';
  p_AutoUpdateFromSchema_c44192666f37 := TRUE;
  p_AutoUpdateAdditionalFieldsToInclude_c44192666f37 := TRUE;
  p_RelatedRecordCollection_c44192666f37 := '{
  "Name": "History",
  "OrderBy": "ConsentStatusAt DESC",
  "Load": "explicit",
  "OnRemove": "delete"
}';
  p_ID_c44192666f37 := '1E12A43C-69D0-4D63-A353-E6ACDBFEDE03';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityRelationship'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_data := jsonb_build_object(
    'EntityID', p_EntityID_c44192666f37,
    'Sequence', p_Sequence_c44192666f37,
    'RelatedEntityID', p_RelatedEntityID_c44192666f37,
    'BundleInAPI', p_BundleInAPI_c44192666f37,
    'IncludeInParentAllQuery', p_IncludeInParentAllQuery_c44192666f37,
    'Type', p_Type_c44192666f37,
    'EntityKeyField', p_EntityKeyField_c44192666f37,
    'RelatedEntityJoinField', p_RelatedEntityJoinField_c44192666f37,
    'JoinView', p_JoinView_c44192666f37,
    'JoinEntityJoinField', p_JoinEntityJoinField_c44192666f37,
    'JoinEntityInverseJoinField', p_JoinEntityInverseJoinField_c44192666f37,
    'DisplayInForm', p_DisplayInForm_c44192666f37,
    'DisplayLocation', p_DisplayLocation_c44192666f37,
    'DisplayName', p_DisplayName_c44192666f37,
    'DisplayIconType', p_DisplayIconType_c44192666f37,
    'DisplayIcon', p_DisplayIcon_c44192666f37,
    'DisplayComponentID', p_DisplayComponentID_c44192666f37,
    'DisplayComponentConfiguration', p_DisplayComponentConfiguration_c44192666f37,
    'AutoUpdateFromSchema', p_AutoUpdateFromSchema_c44192666f37,
    'AdditionalFieldsToInclude', p_AdditionalFieldsToInclude_c44192666f37,
    'AutoUpdateAdditionalFieldsToInclude', p_AutoUpdateAdditionalFieldsToInclude_c44192666f37,
    'RelatedRecordCollection', p_RelatedRecordCollection_c44192666f37,
    'Configuration', p_Configuration_c44192666f37,
    'ID', p_ID_c44192666f37
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityRelationship"(p_EntityID := p_EntityID_c44192666f37, p_Sequence := p_Sequence_c44192666f37, p_RelatedEntityID := p_RelatedEntityID_c44192666f37, p_BundleInAPI := p_BundleInAPI_c44192666f37, p_IncludeInParentAllQuery := p_IncludeInParentAllQuery_c44192666f37, p_Type := p_Type_c44192666f37, p_EntityKeyField := p_EntityKeyField_c44192666f37, p_EntityKeyField_Clear := TRUE, p_RelatedEntityJoinField := p_RelatedEntityJoinField_c44192666f37, p_JoinView := p_JoinView_c44192666f37, p_JoinView_Clear := TRUE, p_JoinEntityJoinField := p_JoinEntityJoinField_c44192666f37, p_JoinEntityJoinField_Clear := TRUE, p_JoinEntityInverseJoinField := p_JoinEntityInverseJoinField_c44192666f37, p_JoinEntityInverseJoinField_Clear := TRUE, p_DisplayInForm := p_DisplayInForm_c44192666f37, p_DisplayLocation := p_DisplayLocation_c44192666f37, p_DisplayName := p_DisplayName_c44192666f37, p_DisplayName_Clear := TRUE, p_DisplayIconType := p_DisplayIconType_c44192666f37, p_DisplayIcon := p_DisplayIcon_c44192666f37, p_DisplayIcon_Clear := TRUE, p_DisplayComponentID := p_DisplayComponentID_c44192666f37, p_DisplayComponentID_Clear := TRUE, p_DisplayComponentConfiguration := p_DisplayComponentConfiguration_c44192666f37, p_DisplayComponentConfiguration_Clear := TRUE, p_AutoUpdateFromSchema := p_AutoUpdateFromSchema_c44192666f37, p_AdditionalFieldsToInclude := p_AdditionalFieldsToInclude_c44192666f37, p_AdditionalFieldsToInclude_Clear := TRUE, p_AutoUpdateAdditionalFieldsToInclude := p_AutoUpdateAdditionalFieldsToInclude_c44192666f37, p_RelatedRecordCollection := p_RelatedRecordCollection_c44192666f37, p_Configuration := p_Configuration_c44192666f37, p_Configuration_Clear := TRUE, p_ID := p_ID_c44192666f37);
  END IF;
END $mj$;
