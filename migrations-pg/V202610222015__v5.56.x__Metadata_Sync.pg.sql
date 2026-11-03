-- =============================================================================================
-- PostgreSQL counterpart of V202610222015__v5.56.x__Metadata_Sync.sql -- BizApps Common v5.56.x Metadata_Sync
-- =============================================================================================
-- Same records, same values as the T-SQL file; see its header for what ships and what is held back.
--
-- HOW IT WAS MADE
--   * `mj sql-convert --from tsql --to postgres` (MJ CLI 6.1.6) on the push log the T-SQL file was
--     generated from, held-back records removed as in the T-SQL file (the People spUpdateEntity and
--     the 108 Entity Field Permission rows). 18 records: each is a DO block that calls the core
--     function in whichever signature the host has (jsonb or named parameters), as in 5.55.
--   * Core schema: `__mj` -> `${mjSchema}` in the 36 calls and the 18 signature probes.
--   * Every string value matches the T-SQL file, including the two queries' SQL text: the converter
--     rewrote type names inside 14 string literals (two EntityField descriptions and six query fields'
--     SQLBaseType / SQLFullType), and those were copied back from the T-SQL file, as in 5.53-5.55.
-- =============================================================================================

SET standard_conforming_strings = on;
-- ===================== Data (INSERT/UPDATE/DELETE) =====================

-- Save MJ: Entity Fields (core SP call only)
DO $mj$
DECLARE
  p_DisplayName_6c27268f4a8b VARCHAR(255);
  p_Description_6c27268f4a8b TEXT;
  p_AutoUpdateDescription_6c27268f4a8b BOOLEAN;
  p_IsPrimaryKey_6c27268f4a8b BOOLEAN;
  p_IsUnique_6c27268f4a8b BOOLEAN;
  p_Category_6c27268f4a8b VARCHAR(255);
  p_ValueListType_6c27268f4a8b VARCHAR(20);
  p_ExtendedType_6c27268f4a8b VARCHAR(50);
  p_CodeType_6c27268f4a8b VARCHAR(50);
  p_DefaultInView_6c27268f4a8b BOOLEAN;
  p_ViewCellTemplate_6c27268f4a8b TEXT;
  p_DefaultColumnWidth_6c27268f4a8b INTEGER;
  p_AllowUpdateAPI_6c27268f4a8b BOOLEAN;
  p_AllowUpdateInView_6c27268f4a8b BOOLEAN;
  p_IncludeInUserSearchAPI_6c27268f4a8b BOOLEAN;
  p_FullTextSearchEnabled_6c27268f4a8b BOOLEAN;
  p_UserSearchParamFormatAPI_6c27268f4a8b VARCHAR(500);
  p_IncludeInGeneratedForm_6c27268f4a8b BOOLEAN;
  p_GeneratedFormSection_6c27268f4a8b VARCHAR(10);
  p_IsNameField_6c27268f4a8b BOOLEAN;
  p_RelatedEntityID_6c27268f4a8b UUID;
  p_RelatedEntityFieldName_6c27268f4a8b VARCHAR(255);
  p_IncludeRelatedEntityNameFieldInBaseView_6c27268f4a8b BOOLEAN;
  p_RelatedEntityNameFieldMap_6c27268f4a8b VARCHAR(255);
  p_RelatedEntityDisplayType_6c27268f4a8b VARCHAR(20);
  p_EntityIDFieldName_6c27268f4a8b VARCHAR(100);
  p_ScopeDefault_6c27268f4a8b VARCHAR(100);
  p_AutoUpdateRelatedEntityInfo_6c27268f4a8b BOOLEAN;
  p_ValuesToPackWithSchema_6c27268f4a8b VARCHAR(10);
  p_Status_6c27268f4a8b VARCHAR(25);
  p_AutoUpdateIsNameField_6c27268f4a8b BOOLEAN;
  p_AutoUpdateDefaultInView_6c27268f4a8b BOOLEAN;
  p_AutoUpdateCategory_6c27268f4a8b BOOLEAN;
  p_AutoUpdateDisplayName_6c27268f4a8b BOOLEAN;
  p_AutoUpdateIncludeInUserSearchAPI_6c27268f4a8b BOOLEAN;
  p_Encrypt_6c27268f4a8b BOOLEAN;
  p_EncryptionKeyID_6c27268f4a8b UUID;
  p_AllowDecryptInAPI_6c27268f4a8b BOOLEAN;
  p_SendEncryptedValue_6c27268f4a8b BOOLEAN;
  p_IsSoftPrimaryKey_6c27268f4a8b BOOLEAN;
  p_IsSoftForeignKey_6c27268f4a8b BOOLEAN;
  p_RelatedEntityJoinFields_6c27268f4a8b TEXT;
  p_JSONType_6c27268f4a8b VARCHAR(255);
  p_JSONTypeIsArray_6c27268f4a8b BOOLEAN;
  p_JSONTypeDefinition_6c27268f4a8b TEXT;
  p_UserSearchPredicateAPI_6c27268f4a8b VARCHAR(20);
  p_AutoUpdateUserSearchPredicate_6c27268f4a8b BOOLEAN;
  p_AutoUpdateFullTextSearch_6c27268f4a8b BOOLEAN;
  p_AutoUpdateExtendedType_6c27268f4a8b BOOLEAN;
  p_IsComputed_6c27268f4a8b BOOLEAN;
  p_EmbeddedRecord_6c27268f4a8b TEXT;
  p_Configuration_6c27268f4a8b TEXT;
  p_ID_6c27268f4a8b UUID;
BEGIN
  p_DisplayName_6c27268f4a8b := 'Record ID';
  p_Description_6c27268f4a8b := 'Primary key of the resolved record. NVARCHAR so composite keys work. Required with EntityID; must be null when the link is an unresolved identity.';
  p_AutoUpdateDescription_6c27268f4a8b := TRUE;
  p_IsPrimaryKey_6c27268f4a8b := FALSE;
  p_IsUnique_6c27268f4a8b := TRUE;
  p_ValueListType_6c27268f4a8b := 'None';
  p_DefaultInView_6c27268f4a8b := FALSE;
  p_DefaultColumnWidth_6c27268f4a8b := 150;
  p_AllowUpdateAPI_6c27268f4a8b := TRUE;
  p_AllowUpdateInView_6c27268f4a8b := TRUE;
  p_IncludeInUserSearchAPI_6c27268f4a8b := FALSE;
  p_FullTextSearchEnabled_6c27268f4a8b := FALSE;
  p_IncludeInGeneratedForm_6c27268f4a8b := TRUE;
  p_GeneratedFormSection_6c27268f4a8b := 'Details';
  p_IsNameField_6c27268f4a8b := FALSE;
  p_IncludeRelatedEntityNameFieldInBaseView_6c27268f4a8b := FALSE;
  p_RelatedEntityDisplayType_6c27268f4a8b := 'Search';
  p_EntityIDFieldName_6c27268f4a8b := 'EntityID';
  p_AutoUpdateRelatedEntityInfo_6c27268f4a8b := TRUE;
  p_ValuesToPackWithSchema_6c27268f4a8b := 'Auto';
  p_Status_6c27268f4a8b := 'Active';
  p_AutoUpdateIsNameField_6c27268f4a8b := TRUE;
  p_AutoUpdateDefaultInView_6c27268f4a8b := TRUE;
  p_AutoUpdateCategory_6c27268f4a8b := TRUE;
  p_AutoUpdateDisplayName_6c27268f4a8b := TRUE;
  p_AutoUpdateIncludeInUserSearchAPI_6c27268f4a8b := TRUE;
  p_Encrypt_6c27268f4a8b := FALSE;
  p_AllowDecryptInAPI_6c27268f4a8b := FALSE;
  p_SendEncryptedValue_6c27268f4a8b := FALSE;
  p_IsSoftPrimaryKey_6c27268f4a8b := FALSE;
  p_IsSoftForeignKey_6c27268f4a8b := FALSE;
  p_JSONTypeIsArray_6c27268f4a8b := FALSE;
  p_UserSearchPredicateAPI_6c27268f4a8b := 'Contains';
  p_AutoUpdateUserSearchPredicate_6c27268f4a8b := TRUE;
  p_AutoUpdateFullTextSearch_6c27268f4a8b := TRUE;
  p_AutoUpdateExtendedType_6c27268f4a8b := TRUE;
  p_IsComputed_6c27268f4a8b := FALSE;
  p_ID_6c27268f4a8b := '5A697780-0A1A-4335-840E-90F6E8B1F432';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityField'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_data := jsonb_build_object(
    'DisplayName', p_DisplayName_6c27268f4a8b,
    'Description', p_Description_6c27268f4a8b,
    'AutoUpdateDescription', p_AutoUpdateDescription_6c27268f4a8b,
    'IsPrimaryKey', p_IsPrimaryKey_6c27268f4a8b,
    'IsUnique', p_IsUnique_6c27268f4a8b,
    'Category', p_Category_6c27268f4a8b,
    'ValueListType', p_ValueListType_6c27268f4a8b,
    'ExtendedType', p_ExtendedType_6c27268f4a8b,
    'CodeType', p_CodeType_6c27268f4a8b,
    'DefaultInView', p_DefaultInView_6c27268f4a8b,
    'ViewCellTemplate', p_ViewCellTemplate_6c27268f4a8b,
    'DefaultColumnWidth', p_DefaultColumnWidth_6c27268f4a8b,
    'AllowUpdateAPI', p_AllowUpdateAPI_6c27268f4a8b,
    'AllowUpdateInView', p_AllowUpdateInView_6c27268f4a8b,
    'IncludeInUserSearchAPI', p_IncludeInUserSearchAPI_6c27268f4a8b,
    'FullTextSearchEnabled', p_FullTextSearchEnabled_6c27268f4a8b,
    'UserSearchParamFormatAPI', p_UserSearchParamFormatAPI_6c27268f4a8b,
    'IncludeInGeneratedForm', p_IncludeInGeneratedForm_6c27268f4a8b,
    'GeneratedFormSection', p_GeneratedFormSection_6c27268f4a8b,
    'IsNameField', p_IsNameField_6c27268f4a8b,
    'RelatedEntityID', p_RelatedEntityID_6c27268f4a8b,
    'RelatedEntityFieldName', p_RelatedEntityFieldName_6c27268f4a8b,
    'IncludeRelatedEntityNameFieldInBaseView', p_IncludeRelatedEntityNameFieldInBaseView_6c27268f4a8b,
    'RelatedEntityNameFieldMap', p_RelatedEntityNameFieldMap_6c27268f4a8b,
    'RelatedEntityDisplayType', p_RelatedEntityDisplayType_6c27268f4a8b,
    'EntityIDFieldName', p_EntityIDFieldName_6c27268f4a8b,
    'ScopeDefault', p_ScopeDefault_6c27268f4a8b,
    'AutoUpdateRelatedEntityInfo', p_AutoUpdateRelatedEntityInfo_6c27268f4a8b,
    'ValuesToPackWithSchema', p_ValuesToPackWithSchema_6c27268f4a8b,
    'Status', p_Status_6c27268f4a8b,
    'AutoUpdateIsNameField', p_AutoUpdateIsNameField_6c27268f4a8b,
    'AutoUpdateDefaultInView', p_AutoUpdateDefaultInView_6c27268f4a8b,
    'AutoUpdateCategory', p_AutoUpdateCategory_6c27268f4a8b,
    'AutoUpdateDisplayName', p_AutoUpdateDisplayName_6c27268f4a8b,
    'AutoUpdateIncludeInUserSearchAPI', p_AutoUpdateIncludeInUserSearchAPI_6c27268f4a8b,
    'Encrypt', p_Encrypt_6c27268f4a8b,
    'EncryptionKeyID', p_EncryptionKeyID_6c27268f4a8b,
    'AllowDecryptInAPI', p_AllowDecryptInAPI_6c27268f4a8b,
    'SendEncryptedValue', p_SendEncryptedValue_6c27268f4a8b,
    'IsSoftPrimaryKey', p_IsSoftPrimaryKey_6c27268f4a8b,
    'IsSoftForeignKey', p_IsSoftForeignKey_6c27268f4a8b,
    'RelatedEntityJoinFields', p_RelatedEntityJoinFields_6c27268f4a8b,
    'JSONType', p_JSONType_6c27268f4a8b,
    'JSONTypeIsArray', p_JSONTypeIsArray_6c27268f4a8b,
    'JSONTypeDefinition', p_JSONTypeDefinition_6c27268f4a8b,
    'UserSearchPredicateAPI', p_UserSearchPredicateAPI_6c27268f4a8b,
    'AutoUpdateUserSearchPredicate', p_AutoUpdateUserSearchPredicate_6c27268f4a8b,
    'AutoUpdateFullTextSearch', p_AutoUpdateFullTextSearch_6c27268f4a8b,
    'AutoUpdateExtendedType', p_AutoUpdateExtendedType_6c27268f4a8b,
    'IsComputed', p_IsComputed_6c27268f4a8b
  ) ||
  jsonb_build_object(
    'EmbeddedRecord', p_EmbeddedRecord_6c27268f4a8b,
    'Configuration', p_Configuration_6c27268f4a8b,
    'ID', p_ID_6c27268f4a8b
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_DisplayName := p_DisplayName_6c27268f4a8b, p_Description := p_Description_6c27268f4a8b, p_AutoUpdateDescription := p_AutoUpdateDescription_6c27268f4a8b, p_IsPrimaryKey := p_IsPrimaryKey_6c27268f4a8b, p_IsUnique := p_IsUnique_6c27268f4a8b, p_Category := p_Category_6c27268f4a8b, p_Category_Clear := TRUE, p_ValueListType := p_ValueListType_6c27268f4a8b, p_ExtendedType := p_ExtendedType_6c27268f4a8b, p_ExtendedType_Clear := TRUE, p_CodeType := p_CodeType_6c27268f4a8b, p_CodeType_Clear := TRUE, p_DefaultInView := p_DefaultInView_6c27268f4a8b, p_ViewCellTemplate := p_ViewCellTemplate_6c27268f4a8b, p_ViewCellTemplate_Clear := TRUE, p_DefaultColumnWidth := p_DefaultColumnWidth_6c27268f4a8b, p_AllowUpdateAPI := p_AllowUpdateAPI_6c27268f4a8b, p_AllowUpdateInView := p_AllowUpdateInView_6c27268f4a8b, p_IncludeInUserSearchAPI := p_IncludeInUserSearchAPI_6c27268f4a8b, p_FullTextSearchEnabled := p_FullTextSearchEnabled_6c27268f4a8b, p_UserSearchParamFormatAPI := p_UserSearchParamFormatAPI_6c27268f4a8b, p_UserSearchParamFormatAPI_Clear := TRUE, p_IncludeInGeneratedForm := p_IncludeInGeneratedForm_6c27268f4a8b, p_GeneratedFormSection := p_GeneratedFormSection_6c27268f4a8b, p_IsNameField := p_IsNameField_6c27268f4a8b, p_RelatedEntityID := p_RelatedEntityID_6c27268f4a8b, p_RelatedEntityID_Clear := TRUE, p_RelatedEntityFieldName := p_RelatedEntityFieldName_6c27268f4a8b, p_RelatedEntityFieldName_Clear := TRUE, p_IncludeRelatedEntityNameFieldInBaseView := p_IncludeRelatedEntityNameFieldInBaseView_6c27268f4a8b, p_RelatedEntityNameFieldMap := p_RelatedEntityNameFieldMap_6c27268f4a8b, p_RelatedEntityNameFieldMap_Clear := TRUE, p_RelatedEntityDisplayType := p_RelatedEntityDisplayType_6c27268f4a8b, p_EntityIDFieldName := p_EntityIDFieldName_6c27268f4a8b, p_ScopeDefault := p_ScopeDefault_6c27268f4a8b, p_ScopeDefault_Clear := TRUE, p_AutoUpdateRelatedEntityInfo := p_AutoUpdateRelatedEntityInfo_6c27268f4a8b, p_ValuesToPackWithSchema := p_ValuesToPackWithSchema_6c27268f4a8b, p_Status := p_Status_6c27268f4a8b, p_AutoUpdateIsNameField := p_AutoUpdateIsNameField_6c27268f4a8b, p_AutoUpdateDefaultInView := p_AutoUpdateDefaultInView_6c27268f4a8b, p_AutoUpdateCategory := p_AutoUpdateCategory_6c27268f4a8b, p_AutoUpdateDisplayName := p_AutoUpdateDisplayName_6c27268f4a8b, p_AutoUpdateIncludeInUserSearchAPI := p_AutoUpdateIncludeInUserSearchAPI_6c27268f4a8b, p_Encrypt := p_Encrypt_6c27268f4a8b, p_EncryptionKeyID := p_EncryptionKeyID_6c27268f4a8b, p_EncryptionKeyID_Clear := TRUE, p_AllowDecryptInAPI := p_AllowDecryptInAPI_6c27268f4a8b, p_SendEncryptedValue := p_SendEncryptedValue_6c27268f4a8b, p_IsSoftPrimaryKey := p_IsSoftPrimaryKey_6c27268f4a8b, p_IsSoftForeignKey := p_IsSoftForeignKey_6c27268f4a8b, p_RelatedEntityJoinFields := p_RelatedEntityJoinFields_6c27268f4a8b, p_RelatedEntityJoinFields_Clear := TRUE, p_JSONType := p_JSONType_6c27268f4a8b, p_JSONType_Clear := TRUE, p_JSONTypeIsArray := p_JSONTypeIsArray_6c27268f4a8b, p_JSONTypeDefinition := p_JSONTypeDefinition_6c27268f4a8b, p_JSONTypeDefinition_Clear := TRUE, p_UserSearchPredicateAPI := p_UserSearchPredicateAPI_6c27268f4a8b, p_AutoUpdateUserSearchPredicate := p_AutoUpdateUserSearchPredicate_6c27268f4a8b, p_AutoUpdateFullTextSearch := p_AutoUpdateFullTextSearch_6c27268f4a8b, p_AutoUpdateExtendedType := p_AutoUpdateExtendedType_6c27268f4a8b, p_IsComputed := p_IsComputed_6c27268f4a8b, p_EmbeddedRecord := p_EmbeddedRecord_6c27268f4a8b, p_EmbeddedRecord_Clear := TRUE, p_Configuration := p_Configuration_6c27268f4a8b, p_Configuration_Clear := TRUE, p_ID := p_ID_6c27268f4a8b);
  END IF;
END $mj$;

-- Save MJ: Entity Fields (core SP call only)
DO $mj$
DECLARE
  p_DisplayName_f7571042d3dc VARCHAR(255);
  p_Description_f7571042d3dc TEXT;
  p_AutoUpdateDescription_f7571042d3dc BOOLEAN;
  p_IsPrimaryKey_f7571042d3dc BOOLEAN;
  p_IsUnique_f7571042d3dc BOOLEAN;
  p_Category_f7571042d3dc VARCHAR(255);
  p_ValueListType_f7571042d3dc VARCHAR(20);
  p_ExtendedType_f7571042d3dc VARCHAR(50);
  p_CodeType_f7571042d3dc VARCHAR(50);
  p_DefaultInView_f7571042d3dc BOOLEAN;
  p_ViewCellTemplate_f7571042d3dc TEXT;
  p_DefaultColumnWidth_f7571042d3dc INTEGER;
  p_AllowUpdateAPI_f7571042d3dc BOOLEAN;
  p_AllowUpdateInView_f7571042d3dc BOOLEAN;
  p_IncludeInUserSearchAPI_f7571042d3dc BOOLEAN;
  p_FullTextSearchEnabled_f7571042d3dc BOOLEAN;
  p_UserSearchParamFormatAPI_f7571042d3dc VARCHAR(500);
  p_IncludeInGeneratedForm_f7571042d3dc BOOLEAN;
  p_GeneratedFormSection_f7571042d3dc VARCHAR(10);
  p_IsNameField_f7571042d3dc BOOLEAN;
  p_RelatedEntityID_f7571042d3dc UUID;
  p_RelatedEntityFieldName_f7571042d3dc VARCHAR(255);
  p_IncludeRelatedEntityNameFieldInBaseView_f7571042d3dc BOOLEAN;
  p_RelatedEntityNameFieldMap_f7571042d3dc VARCHAR(255);
  p_RelatedEntityDisplayType_f7571042d3dc VARCHAR(20);
  p_EntityIDFieldName_f7571042d3dc VARCHAR(100);
  p_ScopeDefault_f7571042d3dc VARCHAR(100);
  p_AutoUpdateRelatedEntityInfo_f7571042d3dc BOOLEAN;
  p_ValuesToPackWithSchema_f7571042d3dc VARCHAR(10);
  p_Status_f7571042d3dc VARCHAR(25);
  p_AutoUpdateIsNameField_f7571042d3dc BOOLEAN;
  p_AutoUpdateDefaultInView_f7571042d3dc BOOLEAN;
  p_AutoUpdateCategory_f7571042d3dc BOOLEAN;
  p_AutoUpdateDisplayName_f7571042d3dc BOOLEAN;
  p_AutoUpdateIncludeInUserSearchAPI_f7571042d3dc BOOLEAN;
  p_Encrypt_f7571042d3dc BOOLEAN;
  p_EncryptionKeyID_f7571042d3dc UUID;
  p_AllowDecryptInAPI_f7571042d3dc BOOLEAN;
  p_SendEncryptedValue_f7571042d3dc BOOLEAN;
  p_IsSoftPrimaryKey_f7571042d3dc BOOLEAN;
  p_IsSoftForeignKey_f7571042d3dc BOOLEAN;
  p_RelatedEntityJoinFields_f7571042d3dc TEXT;
  p_JSONType_f7571042d3dc VARCHAR(255);
  p_JSONTypeIsArray_f7571042d3dc BOOLEAN;
  p_JSONTypeDefinition_f7571042d3dc TEXT;
  p_UserSearchPredicateAPI_f7571042d3dc VARCHAR(20);
  p_AutoUpdateUserSearchPredicate_f7571042d3dc BOOLEAN;
  p_AutoUpdateFullTextSearch_f7571042d3dc BOOLEAN;
  p_AutoUpdateExtendedType_f7571042d3dc BOOLEAN;
  p_IsComputed_f7571042d3dc BOOLEAN;
  p_EmbeddedRecord_f7571042d3dc TEXT;
  p_Configuration_f7571042d3dc TEXT;
  p_ID_f7571042d3dc UUID;
BEGIN
  p_DisplayName_f7571042d3dc := 'Record ID';
  p_Description_f7571042d3dc := 'Primary key value(s) of the linked record. NVARCHAR(700) to support concatenated composite keys for entities without single-valued primary keys';
  p_AutoUpdateDescription_f7571042d3dc := TRUE;
  p_IsPrimaryKey_f7571042d3dc := FALSE;
  p_IsUnique_f7571042d3dc := FALSE;
  p_Category_f7571042d3dc := 'Linkage Details';
  p_ValueListType_f7571042d3dc := 'None';
  p_DefaultInView_f7571042d3dc := TRUE;
  p_DefaultColumnWidth_f7571042d3dc := 150;
  p_AllowUpdateAPI_f7571042d3dc := TRUE;
  p_AllowUpdateInView_f7571042d3dc := TRUE;
  p_IncludeInUserSearchAPI_f7571042d3dc := TRUE;
  p_FullTextSearchEnabled_f7571042d3dc := FALSE;
  p_IncludeInGeneratedForm_f7571042d3dc := TRUE;
  p_GeneratedFormSection_f7571042d3dc := 'Category';
  p_IsNameField_f7571042d3dc := FALSE;
  p_IncludeRelatedEntityNameFieldInBaseView_f7571042d3dc := FALSE;
  p_RelatedEntityDisplayType_f7571042d3dc := 'Search';
  p_EntityIDFieldName_f7571042d3dc := 'EntityID';
  p_AutoUpdateRelatedEntityInfo_f7571042d3dc := TRUE;
  p_ValuesToPackWithSchema_f7571042d3dc := 'Auto';
  p_Status_f7571042d3dc := 'Active';
  p_AutoUpdateIsNameField_f7571042d3dc := TRUE;
  p_AutoUpdateDefaultInView_f7571042d3dc := TRUE;
  p_AutoUpdateCategory_f7571042d3dc := TRUE;
  p_AutoUpdateDisplayName_f7571042d3dc := TRUE;
  p_AutoUpdateIncludeInUserSearchAPI_f7571042d3dc := TRUE;
  p_Encrypt_f7571042d3dc := FALSE;
  p_AllowDecryptInAPI_f7571042d3dc := FALSE;
  p_SendEncryptedValue_f7571042d3dc := FALSE;
  p_IsSoftPrimaryKey_f7571042d3dc := FALSE;
  p_IsSoftForeignKey_f7571042d3dc := FALSE;
  p_JSONTypeIsArray_f7571042d3dc := FALSE;
  p_UserSearchPredicateAPI_f7571042d3dc := 'Contains';
  p_AutoUpdateUserSearchPredicate_f7571042d3dc := TRUE;
  p_AutoUpdateFullTextSearch_f7571042d3dc := TRUE;
  p_AutoUpdateExtendedType_f7571042d3dc := TRUE;
  p_IsComputed_f7571042d3dc := FALSE;
  p_ID_f7571042d3dc := '8E6C198E-773E-4582-B020-7C7A9716B2C8';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityField'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_data := jsonb_build_object(
    'DisplayName', p_DisplayName_f7571042d3dc,
    'Description', p_Description_f7571042d3dc,
    'AutoUpdateDescription', p_AutoUpdateDescription_f7571042d3dc,
    'IsPrimaryKey', p_IsPrimaryKey_f7571042d3dc,
    'IsUnique', p_IsUnique_f7571042d3dc,
    'Category', p_Category_f7571042d3dc,
    'ValueListType', p_ValueListType_f7571042d3dc,
    'ExtendedType', p_ExtendedType_f7571042d3dc,
    'CodeType', p_CodeType_f7571042d3dc,
    'DefaultInView', p_DefaultInView_f7571042d3dc,
    'ViewCellTemplate', p_ViewCellTemplate_f7571042d3dc,
    'DefaultColumnWidth', p_DefaultColumnWidth_f7571042d3dc,
    'AllowUpdateAPI', p_AllowUpdateAPI_f7571042d3dc,
    'AllowUpdateInView', p_AllowUpdateInView_f7571042d3dc,
    'IncludeInUserSearchAPI', p_IncludeInUserSearchAPI_f7571042d3dc,
    'FullTextSearchEnabled', p_FullTextSearchEnabled_f7571042d3dc,
    'UserSearchParamFormatAPI', p_UserSearchParamFormatAPI_f7571042d3dc,
    'IncludeInGeneratedForm', p_IncludeInGeneratedForm_f7571042d3dc,
    'GeneratedFormSection', p_GeneratedFormSection_f7571042d3dc,
    'IsNameField', p_IsNameField_f7571042d3dc,
    'RelatedEntityID', p_RelatedEntityID_f7571042d3dc,
    'RelatedEntityFieldName', p_RelatedEntityFieldName_f7571042d3dc,
    'IncludeRelatedEntityNameFieldInBaseView', p_IncludeRelatedEntityNameFieldInBaseView_f7571042d3dc,
    'RelatedEntityNameFieldMap', p_RelatedEntityNameFieldMap_f7571042d3dc,
    'RelatedEntityDisplayType', p_RelatedEntityDisplayType_f7571042d3dc,
    'EntityIDFieldName', p_EntityIDFieldName_f7571042d3dc,
    'ScopeDefault', p_ScopeDefault_f7571042d3dc,
    'AutoUpdateRelatedEntityInfo', p_AutoUpdateRelatedEntityInfo_f7571042d3dc,
    'ValuesToPackWithSchema', p_ValuesToPackWithSchema_f7571042d3dc,
    'Status', p_Status_f7571042d3dc,
    'AutoUpdateIsNameField', p_AutoUpdateIsNameField_f7571042d3dc,
    'AutoUpdateDefaultInView', p_AutoUpdateDefaultInView_f7571042d3dc,
    'AutoUpdateCategory', p_AutoUpdateCategory_f7571042d3dc,
    'AutoUpdateDisplayName', p_AutoUpdateDisplayName_f7571042d3dc,
    'AutoUpdateIncludeInUserSearchAPI', p_AutoUpdateIncludeInUserSearchAPI_f7571042d3dc,
    'Encrypt', p_Encrypt_f7571042d3dc,
    'EncryptionKeyID', p_EncryptionKeyID_f7571042d3dc,
    'AllowDecryptInAPI', p_AllowDecryptInAPI_f7571042d3dc,
    'SendEncryptedValue', p_SendEncryptedValue_f7571042d3dc,
    'IsSoftPrimaryKey', p_IsSoftPrimaryKey_f7571042d3dc,
    'IsSoftForeignKey', p_IsSoftForeignKey_f7571042d3dc,
    'RelatedEntityJoinFields', p_RelatedEntityJoinFields_f7571042d3dc,
    'JSONType', p_JSONType_f7571042d3dc,
    'JSONTypeIsArray', p_JSONTypeIsArray_f7571042d3dc,
    'JSONTypeDefinition', p_JSONTypeDefinition_f7571042d3dc,
    'UserSearchPredicateAPI', p_UserSearchPredicateAPI_f7571042d3dc,
    'AutoUpdateUserSearchPredicate', p_AutoUpdateUserSearchPredicate_f7571042d3dc,
    'AutoUpdateFullTextSearch', p_AutoUpdateFullTextSearch_f7571042d3dc,
    'AutoUpdateExtendedType', p_AutoUpdateExtendedType_f7571042d3dc,
    'IsComputed', p_IsComputed_f7571042d3dc
  ) ||
  jsonb_build_object(
    'EmbeddedRecord', p_EmbeddedRecord_f7571042d3dc,
    'Configuration', p_Configuration_f7571042d3dc,
    'ID', p_ID_f7571042d3dc
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_DisplayName := p_DisplayName_f7571042d3dc, p_Description := p_Description_f7571042d3dc, p_AutoUpdateDescription := p_AutoUpdateDescription_f7571042d3dc, p_IsPrimaryKey := p_IsPrimaryKey_f7571042d3dc, p_IsUnique := p_IsUnique_f7571042d3dc, p_Category := p_Category_f7571042d3dc, p_ValueListType := p_ValueListType_f7571042d3dc, p_ExtendedType := p_ExtendedType_f7571042d3dc, p_ExtendedType_Clear := TRUE, p_CodeType := p_CodeType_f7571042d3dc, p_CodeType_Clear := TRUE, p_DefaultInView := p_DefaultInView_f7571042d3dc, p_ViewCellTemplate := p_ViewCellTemplate_f7571042d3dc, p_ViewCellTemplate_Clear := TRUE, p_DefaultColumnWidth := p_DefaultColumnWidth_f7571042d3dc, p_AllowUpdateAPI := p_AllowUpdateAPI_f7571042d3dc, p_AllowUpdateInView := p_AllowUpdateInView_f7571042d3dc, p_IncludeInUserSearchAPI := p_IncludeInUserSearchAPI_f7571042d3dc, p_FullTextSearchEnabled := p_FullTextSearchEnabled_f7571042d3dc, p_UserSearchParamFormatAPI := p_UserSearchParamFormatAPI_f7571042d3dc, p_UserSearchParamFormatAPI_Clear := TRUE, p_IncludeInGeneratedForm := p_IncludeInGeneratedForm_f7571042d3dc, p_GeneratedFormSection := p_GeneratedFormSection_f7571042d3dc, p_IsNameField := p_IsNameField_f7571042d3dc, p_RelatedEntityID := p_RelatedEntityID_f7571042d3dc, p_RelatedEntityID_Clear := TRUE, p_RelatedEntityFieldName := p_RelatedEntityFieldName_f7571042d3dc, p_RelatedEntityFieldName_Clear := TRUE, p_IncludeRelatedEntityNameFieldInBaseView := p_IncludeRelatedEntityNameFieldInBaseView_f7571042d3dc, p_RelatedEntityNameFieldMap := p_RelatedEntityNameFieldMap_f7571042d3dc, p_RelatedEntityNameFieldMap_Clear := TRUE, p_RelatedEntityDisplayType := p_RelatedEntityDisplayType_f7571042d3dc, p_EntityIDFieldName := p_EntityIDFieldName_f7571042d3dc, p_ScopeDefault := p_ScopeDefault_f7571042d3dc, p_ScopeDefault_Clear := TRUE, p_AutoUpdateRelatedEntityInfo := p_AutoUpdateRelatedEntityInfo_f7571042d3dc, p_ValuesToPackWithSchema := p_ValuesToPackWithSchema_f7571042d3dc, p_Status := p_Status_f7571042d3dc, p_AutoUpdateIsNameField := p_AutoUpdateIsNameField_f7571042d3dc, p_AutoUpdateDefaultInView := p_AutoUpdateDefaultInView_f7571042d3dc, p_AutoUpdateCategory := p_AutoUpdateCategory_f7571042d3dc, p_AutoUpdateDisplayName := p_AutoUpdateDisplayName_f7571042d3dc, p_AutoUpdateIncludeInUserSearchAPI := p_AutoUpdateIncludeInUserSearchAPI_f7571042d3dc, p_Encrypt := p_Encrypt_f7571042d3dc, p_EncryptionKeyID := p_EncryptionKeyID_f7571042d3dc, p_EncryptionKeyID_Clear := TRUE, p_AllowDecryptInAPI := p_AllowDecryptInAPI_f7571042d3dc, p_SendEncryptedValue := p_SendEncryptedValue_f7571042d3dc, p_IsSoftPrimaryKey := p_IsSoftPrimaryKey_f7571042d3dc, p_IsSoftForeignKey := p_IsSoftForeignKey_f7571042d3dc, p_RelatedEntityJoinFields := p_RelatedEntityJoinFields_f7571042d3dc, p_RelatedEntityJoinFields_Clear := TRUE, p_JSONType := p_JSONType_f7571042d3dc, p_JSONType_Clear := TRUE, p_JSONTypeIsArray := p_JSONTypeIsArray_f7571042d3dc, p_JSONTypeDefinition := p_JSONTypeDefinition_f7571042d3dc, p_JSONTypeDefinition_Clear := TRUE, p_UserSearchPredicateAPI := p_UserSearchPredicateAPI_f7571042d3dc, p_AutoUpdateUserSearchPredicate := p_AutoUpdateUserSearchPredicate_f7571042d3dc, p_AutoUpdateFullTextSearch := p_AutoUpdateFullTextSearch_f7571042d3dc, p_AutoUpdateExtendedType := p_AutoUpdateExtendedType_f7571042d3dc, p_IsComputed := p_IsComputed_f7571042d3dc, p_EmbeddedRecord := p_EmbeddedRecord_f7571042d3dc, p_EmbeddedRecord_Clear := TRUE, p_Configuration := p_Configuration_f7571042d3dc, p_Configuration_Clear := TRUE, p_ID := p_ID_f7571042d3dc);
  END IF;
END $mj$;

-- Save MJ: Entity Fields (core SP call only)
DO $mj$
DECLARE
  p_DisplayName_daffe49d9f42 VARCHAR(255);
  p_Description_daffe49d9f42 TEXT;
  p_AutoUpdateDescription_daffe49d9f42 BOOLEAN;
  p_IsPrimaryKey_daffe49d9f42 BOOLEAN;
  p_IsUnique_daffe49d9f42 BOOLEAN;
  p_Category_daffe49d9f42 VARCHAR(255);
  p_ValueListType_daffe49d9f42 VARCHAR(20);
  p_ExtendedType_daffe49d9f42 VARCHAR(50);
  p_CodeType_daffe49d9f42 VARCHAR(50);
  p_DefaultInView_daffe49d9f42 BOOLEAN;
  p_ViewCellTemplate_daffe49d9f42 TEXT;
  p_DefaultColumnWidth_daffe49d9f42 INTEGER;
  p_AllowUpdateAPI_daffe49d9f42 BOOLEAN;
  p_AllowUpdateInView_daffe49d9f42 BOOLEAN;
  p_IncludeInUserSearchAPI_daffe49d9f42 BOOLEAN;
  p_FullTextSearchEnabled_daffe49d9f42 BOOLEAN;
  p_UserSearchParamFormatAPI_daffe49d9f42 VARCHAR(500);
  p_IncludeInGeneratedForm_daffe49d9f42 BOOLEAN;
  p_GeneratedFormSection_daffe49d9f42 VARCHAR(10);
  p_IsNameField_daffe49d9f42 BOOLEAN;
  p_RelatedEntityID_daffe49d9f42 UUID;
  p_RelatedEntityFieldName_daffe49d9f42 VARCHAR(255);
  p_IncludeRelatedEntityNameFieldInBaseView_daffe49d9f42 BOOLEAN;
  p_RelatedEntityNameFieldMap_daffe49d9f42 VARCHAR(255);
  p_RelatedEntityDisplayType_daffe49d9f42 VARCHAR(20);
  p_EntityIDFieldName_daffe49d9f42 VARCHAR(100);
  p_ScopeDefault_daffe49d9f42 VARCHAR(100);
  p_AutoUpdateRelatedEntityInfo_daffe49d9f42 BOOLEAN;
  p_ValuesToPackWithSchema_daffe49d9f42 VARCHAR(10);
  p_Status_daffe49d9f42 VARCHAR(25);
  p_AutoUpdateIsNameField_daffe49d9f42 BOOLEAN;
  p_AutoUpdateDefaultInView_daffe49d9f42 BOOLEAN;
  p_AutoUpdateCategory_daffe49d9f42 BOOLEAN;
  p_AutoUpdateDisplayName_daffe49d9f42 BOOLEAN;
  p_AutoUpdateIncludeInUserSearchAPI_daffe49d9f42 BOOLEAN;
  p_Encrypt_daffe49d9f42 BOOLEAN;
  p_EncryptionKeyID_daffe49d9f42 UUID;
  p_AllowDecryptInAPI_daffe49d9f42 BOOLEAN;
  p_SendEncryptedValue_daffe49d9f42 BOOLEAN;
  p_IsSoftPrimaryKey_daffe49d9f42 BOOLEAN;
  p_IsSoftForeignKey_daffe49d9f42 BOOLEAN;
  p_RelatedEntityJoinFields_daffe49d9f42 TEXT;
  p_JSONType_daffe49d9f42 VARCHAR(255);
  p_JSONTypeIsArray_daffe49d9f42 BOOLEAN;
  p_JSONTypeDefinition_daffe49d9f42 TEXT;
  p_UserSearchPredicateAPI_daffe49d9f42 VARCHAR(20);
  p_AutoUpdateUserSearchPredicate_daffe49d9f42 BOOLEAN;
  p_AutoUpdateFullTextSearch_daffe49d9f42 BOOLEAN;
  p_AutoUpdateExtendedType_daffe49d9f42 BOOLEAN;
  p_IsComputed_daffe49d9f42 BOOLEAN;
  p_EmbeddedRecord_daffe49d9f42 TEXT;
  p_Configuration_daffe49d9f42 TEXT;
  p_ID_daffe49d9f42 UUID;
BEGIN
  p_DisplayName_daffe49d9f42 := 'Email Domain';
  p_Description_daffe49d9f42 := 'Lower-cased domain of Email: the text after the first @. NULL when Email is empty, has no @, or has nothing after it. Computed and stored, indexed for prefix search by domain.';
  p_AutoUpdateDescription_daffe49d9f42 := TRUE;
  p_IsPrimaryKey_daffe49d9f42 := FALSE;
  p_IsUnique_daffe49d9f42 := FALSE;
  p_Category_daffe49d9f42 := 'Professional and Profile';
  p_ValueListType_daffe49d9f42 := 'None';
  p_DefaultInView_daffe49d9f42 := FALSE;
  p_DefaultColumnWidth_daffe49d9f42 := 150;
  p_AllowUpdateAPI_daffe49d9f42 := FALSE;
  p_AllowUpdateInView_daffe49d9f42 := TRUE;
  p_IncludeInUserSearchAPI_daffe49d9f42 := FALSE;
  p_FullTextSearchEnabled_daffe49d9f42 := FALSE;
  p_IncludeInGeneratedForm_daffe49d9f42 := TRUE;
  p_GeneratedFormSection_daffe49d9f42 := 'Category';
  p_IsNameField_daffe49d9f42 := FALSE;
  p_IncludeRelatedEntityNameFieldInBaseView_daffe49d9f42 := FALSE;
  p_RelatedEntityDisplayType_daffe49d9f42 := 'Search';
  p_AutoUpdateRelatedEntityInfo_daffe49d9f42 := TRUE;
  p_ValuesToPackWithSchema_daffe49d9f42 := 'Auto';
  p_Status_daffe49d9f42 := 'Active';
  p_AutoUpdateIsNameField_daffe49d9f42 := TRUE;
  p_AutoUpdateDefaultInView_daffe49d9f42 := TRUE;
  p_AutoUpdateCategory_daffe49d9f42 := FALSE;
  p_AutoUpdateDisplayName_daffe49d9f42 := TRUE;
  p_AutoUpdateIncludeInUserSearchAPI_daffe49d9f42 := TRUE;
  p_Encrypt_daffe49d9f42 := FALSE;
  p_AllowDecryptInAPI_daffe49d9f42 := FALSE;
  p_SendEncryptedValue_daffe49d9f42 := FALSE;
  p_IsSoftPrimaryKey_daffe49d9f42 := FALSE;
  p_IsSoftForeignKey_daffe49d9f42 := FALSE;
  p_JSONTypeIsArray_daffe49d9f42 := FALSE;
  p_UserSearchPredicateAPI_daffe49d9f42 := 'Contains';
  p_AutoUpdateUserSearchPredicate_daffe49d9f42 := TRUE;
  p_AutoUpdateFullTextSearch_daffe49d9f42 := TRUE;
  p_AutoUpdateExtendedType_daffe49d9f42 := TRUE;
  p_IsComputed_daffe49d9f42 := TRUE;
  p_ID_daffe49d9f42 := '5F79A492-3538-46D5-8047-FF545F674B58';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityField'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_data := jsonb_build_object(
    'DisplayName', p_DisplayName_daffe49d9f42,
    'Description', p_Description_daffe49d9f42,
    'AutoUpdateDescription', p_AutoUpdateDescription_daffe49d9f42,
    'IsPrimaryKey', p_IsPrimaryKey_daffe49d9f42,
    'IsUnique', p_IsUnique_daffe49d9f42,
    'Category', p_Category_daffe49d9f42,
    'ValueListType', p_ValueListType_daffe49d9f42,
    'ExtendedType', p_ExtendedType_daffe49d9f42,
    'CodeType', p_CodeType_daffe49d9f42,
    'DefaultInView', p_DefaultInView_daffe49d9f42,
    'ViewCellTemplate', p_ViewCellTemplate_daffe49d9f42,
    'DefaultColumnWidth', p_DefaultColumnWidth_daffe49d9f42,
    'AllowUpdateAPI', p_AllowUpdateAPI_daffe49d9f42,
    'AllowUpdateInView', p_AllowUpdateInView_daffe49d9f42,
    'IncludeInUserSearchAPI', p_IncludeInUserSearchAPI_daffe49d9f42,
    'FullTextSearchEnabled', p_FullTextSearchEnabled_daffe49d9f42,
    'UserSearchParamFormatAPI', p_UserSearchParamFormatAPI_daffe49d9f42,
    'IncludeInGeneratedForm', p_IncludeInGeneratedForm_daffe49d9f42,
    'GeneratedFormSection', p_GeneratedFormSection_daffe49d9f42,
    'IsNameField', p_IsNameField_daffe49d9f42,
    'RelatedEntityID', p_RelatedEntityID_daffe49d9f42,
    'RelatedEntityFieldName', p_RelatedEntityFieldName_daffe49d9f42,
    'IncludeRelatedEntityNameFieldInBaseView', p_IncludeRelatedEntityNameFieldInBaseView_daffe49d9f42,
    'RelatedEntityNameFieldMap', p_RelatedEntityNameFieldMap_daffe49d9f42,
    'RelatedEntityDisplayType', p_RelatedEntityDisplayType_daffe49d9f42,
    'EntityIDFieldName', p_EntityIDFieldName_daffe49d9f42,
    'ScopeDefault', p_ScopeDefault_daffe49d9f42,
    'AutoUpdateRelatedEntityInfo', p_AutoUpdateRelatedEntityInfo_daffe49d9f42,
    'ValuesToPackWithSchema', p_ValuesToPackWithSchema_daffe49d9f42,
    'Status', p_Status_daffe49d9f42,
    'AutoUpdateIsNameField', p_AutoUpdateIsNameField_daffe49d9f42,
    'AutoUpdateDefaultInView', p_AutoUpdateDefaultInView_daffe49d9f42,
    'AutoUpdateCategory', p_AutoUpdateCategory_daffe49d9f42,
    'AutoUpdateDisplayName', p_AutoUpdateDisplayName_daffe49d9f42,
    'AutoUpdateIncludeInUserSearchAPI', p_AutoUpdateIncludeInUserSearchAPI_daffe49d9f42,
    'Encrypt', p_Encrypt_daffe49d9f42,
    'EncryptionKeyID', p_EncryptionKeyID_daffe49d9f42,
    'AllowDecryptInAPI', p_AllowDecryptInAPI_daffe49d9f42,
    'SendEncryptedValue', p_SendEncryptedValue_daffe49d9f42,
    'IsSoftPrimaryKey', p_IsSoftPrimaryKey_daffe49d9f42,
    'IsSoftForeignKey', p_IsSoftForeignKey_daffe49d9f42,
    'RelatedEntityJoinFields', p_RelatedEntityJoinFields_daffe49d9f42,
    'JSONType', p_JSONType_daffe49d9f42,
    'JSONTypeIsArray', p_JSONTypeIsArray_daffe49d9f42,
    'JSONTypeDefinition', p_JSONTypeDefinition_daffe49d9f42,
    'UserSearchPredicateAPI', p_UserSearchPredicateAPI_daffe49d9f42,
    'AutoUpdateUserSearchPredicate', p_AutoUpdateUserSearchPredicate_daffe49d9f42,
    'AutoUpdateFullTextSearch', p_AutoUpdateFullTextSearch_daffe49d9f42,
    'AutoUpdateExtendedType', p_AutoUpdateExtendedType_daffe49d9f42,
    'IsComputed', p_IsComputed_daffe49d9f42
  ) ||
  jsonb_build_object(
    'EmbeddedRecord', p_EmbeddedRecord_daffe49d9f42,
    'Configuration', p_Configuration_daffe49d9f42,
    'ID', p_ID_daffe49d9f42
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_DisplayName := p_DisplayName_daffe49d9f42, p_Description := p_Description_daffe49d9f42, p_AutoUpdateDescription := p_AutoUpdateDescription_daffe49d9f42, p_IsPrimaryKey := p_IsPrimaryKey_daffe49d9f42, p_IsUnique := p_IsUnique_daffe49d9f42, p_Category := p_Category_daffe49d9f42, p_ValueListType := p_ValueListType_daffe49d9f42, p_ExtendedType := p_ExtendedType_daffe49d9f42, p_ExtendedType_Clear := TRUE, p_CodeType := p_CodeType_daffe49d9f42, p_CodeType_Clear := TRUE, p_DefaultInView := p_DefaultInView_daffe49d9f42, p_ViewCellTemplate := p_ViewCellTemplate_daffe49d9f42, p_ViewCellTemplate_Clear := TRUE, p_DefaultColumnWidth := p_DefaultColumnWidth_daffe49d9f42, p_AllowUpdateAPI := p_AllowUpdateAPI_daffe49d9f42, p_AllowUpdateInView := p_AllowUpdateInView_daffe49d9f42, p_IncludeInUserSearchAPI := p_IncludeInUserSearchAPI_daffe49d9f42, p_FullTextSearchEnabled := p_FullTextSearchEnabled_daffe49d9f42, p_UserSearchParamFormatAPI := p_UserSearchParamFormatAPI_daffe49d9f42, p_UserSearchParamFormatAPI_Clear := TRUE, p_IncludeInGeneratedForm := p_IncludeInGeneratedForm_daffe49d9f42, p_GeneratedFormSection := p_GeneratedFormSection_daffe49d9f42, p_IsNameField := p_IsNameField_daffe49d9f42, p_RelatedEntityID := p_RelatedEntityID_daffe49d9f42, p_RelatedEntityID_Clear := TRUE, p_RelatedEntityFieldName := p_RelatedEntityFieldName_daffe49d9f42, p_RelatedEntityFieldName_Clear := TRUE, p_IncludeRelatedEntityNameFieldInBaseView := p_IncludeRelatedEntityNameFieldInBaseView_daffe49d9f42, p_RelatedEntityNameFieldMap := p_RelatedEntityNameFieldMap_daffe49d9f42, p_RelatedEntityNameFieldMap_Clear := TRUE, p_RelatedEntityDisplayType := p_RelatedEntityDisplayType_daffe49d9f42, p_EntityIDFieldName := p_EntityIDFieldName_daffe49d9f42, p_EntityIDFieldName_Clear := TRUE, p_ScopeDefault := p_ScopeDefault_daffe49d9f42, p_ScopeDefault_Clear := TRUE, p_AutoUpdateRelatedEntityInfo := p_AutoUpdateRelatedEntityInfo_daffe49d9f42, p_ValuesToPackWithSchema := p_ValuesToPackWithSchema_daffe49d9f42, p_Status := p_Status_daffe49d9f42, p_AutoUpdateIsNameField := p_AutoUpdateIsNameField_daffe49d9f42, p_AutoUpdateDefaultInView := p_AutoUpdateDefaultInView_daffe49d9f42, p_AutoUpdateCategory := p_AutoUpdateCategory_daffe49d9f42, p_AutoUpdateDisplayName := p_AutoUpdateDisplayName_daffe49d9f42, p_AutoUpdateIncludeInUserSearchAPI := p_AutoUpdateIncludeInUserSearchAPI_daffe49d9f42, p_Encrypt := p_Encrypt_daffe49d9f42, p_EncryptionKeyID := p_EncryptionKeyID_daffe49d9f42, p_EncryptionKeyID_Clear := TRUE, p_AllowDecryptInAPI := p_AllowDecryptInAPI_daffe49d9f42, p_SendEncryptedValue := p_SendEncryptedValue_daffe49d9f42, p_IsSoftPrimaryKey := p_IsSoftPrimaryKey_daffe49d9f42, p_IsSoftForeignKey := p_IsSoftForeignKey_daffe49d9f42, p_RelatedEntityJoinFields := p_RelatedEntityJoinFields_daffe49d9f42, p_RelatedEntityJoinFields_Clear := TRUE, p_JSONType := p_JSONType_daffe49d9f42, p_JSONType_Clear := TRUE, p_JSONTypeIsArray := p_JSONTypeIsArray_daffe49d9f42, p_JSONTypeDefinition := p_JSONTypeDefinition_daffe49d9f42, p_JSONTypeDefinition_Clear := TRUE, p_UserSearchPredicateAPI := p_UserSearchPredicateAPI_daffe49d9f42, p_AutoUpdateUserSearchPredicate := p_AutoUpdateUserSearchPredicate_daffe49d9f42, p_AutoUpdateFullTextSearch := p_AutoUpdateFullTextSearch_daffe49d9f42, p_AutoUpdateExtendedType := p_AutoUpdateExtendedType_daffe49d9f42, p_IsComputed := p_IsComputed_daffe49d9f42, p_EmbeddedRecord := p_EmbeddedRecord_daffe49d9f42, p_EmbeddedRecord_Clear := TRUE, p_Configuration := p_Configuration_daffe49d9f42, p_Configuration_Clear := TRUE, p_ID := p_ID_daffe49d9f42);
  END IF;
END $mj$;

-- Save MJ: Entity Fields (core SP call only)
DO $mj$
DECLARE
  p_DisplayName_76eefcea324c VARCHAR(255);
  p_Description_76eefcea324c TEXT;
  p_AutoUpdateDescription_76eefcea324c BOOLEAN;
  p_IsPrimaryKey_76eefcea324c BOOLEAN;
  p_IsUnique_76eefcea324c BOOLEAN;
  p_Category_76eefcea324c VARCHAR(255);
  p_ValueListType_76eefcea324c VARCHAR(20);
  p_ExtendedType_76eefcea324c VARCHAR(50);
  p_CodeType_76eefcea324c VARCHAR(50);
  p_DefaultInView_76eefcea324c BOOLEAN;
  p_ViewCellTemplate_76eefcea324c TEXT;
  p_DefaultColumnWidth_76eefcea324c INTEGER;
  p_AllowUpdateAPI_76eefcea324c BOOLEAN;
  p_AllowUpdateInView_76eefcea324c BOOLEAN;
  p_IncludeInUserSearchAPI_76eefcea324c BOOLEAN;
  p_FullTextSearchEnabled_76eefcea324c BOOLEAN;
  p_UserSearchParamFormatAPI_76eefcea324c VARCHAR(500);
  p_IncludeInGeneratedForm_76eefcea324c BOOLEAN;
  p_GeneratedFormSection_76eefcea324c VARCHAR(10);
  p_IsNameField_76eefcea324c BOOLEAN;
  p_RelatedEntityID_76eefcea324c UUID;
  p_RelatedEntityFieldName_76eefcea324c VARCHAR(255);
  p_IncludeRelatedEntityNameFieldInBaseView_76eefcea324c BOOLEAN;
  p_RelatedEntityNameFieldMap_76eefcea324c VARCHAR(255);
  p_RelatedEntityDisplayType_76eefcea324c VARCHAR(20);
  p_EntityIDFieldName_76eefcea324c VARCHAR(100);
  p_ScopeDefault_76eefcea324c VARCHAR(100);
  p_AutoUpdateRelatedEntityInfo_76eefcea324c BOOLEAN;
  p_ValuesToPackWithSchema_76eefcea324c VARCHAR(10);
  p_Status_76eefcea324c VARCHAR(25);
  p_AutoUpdateIsNameField_76eefcea324c BOOLEAN;
  p_AutoUpdateDefaultInView_76eefcea324c BOOLEAN;
  p_AutoUpdateCategory_76eefcea324c BOOLEAN;
  p_AutoUpdateDisplayName_76eefcea324c BOOLEAN;
  p_AutoUpdateIncludeInUserSearchAPI_76eefcea324c BOOLEAN;
  p_Encrypt_76eefcea324c BOOLEAN;
  p_EncryptionKeyID_76eefcea324c UUID;
  p_AllowDecryptInAPI_76eefcea324c BOOLEAN;
  p_SendEncryptedValue_76eefcea324c BOOLEAN;
  p_IsSoftPrimaryKey_76eefcea324c BOOLEAN;
  p_IsSoftForeignKey_76eefcea324c BOOLEAN;
  p_RelatedEntityJoinFields_76eefcea324c TEXT;
  p_JSONType_76eefcea324c VARCHAR(255);
  p_JSONTypeIsArray_76eefcea324c BOOLEAN;
  p_JSONTypeDefinition_76eefcea324c TEXT;
  p_UserSearchPredicateAPI_76eefcea324c VARCHAR(20);
  p_AutoUpdateUserSearchPredicate_76eefcea324c BOOLEAN;
  p_AutoUpdateFullTextSearch_76eefcea324c BOOLEAN;
  p_AutoUpdateExtendedType_76eefcea324c BOOLEAN;
  p_IsComputed_76eefcea324c BOOLEAN;
  p_EmbeddedRecord_76eefcea324c TEXT;
  p_Configuration_76eefcea324c TEXT;
  p_ID_76eefcea324c UUID;
BEGIN
  p_DisplayName_76eefcea324c := 'Website Domain';
  p_Description_76eefcea324c := 'Lower-cased host of Website, without the http(s):// scheme, a leading www. or any path. NULL when Website is empty. Computed and stored, indexed for prefix search by domain.';
  p_AutoUpdateDescription_76eefcea324c := TRUE;
  p_IsPrimaryKey_76eefcea324c := FALSE;
  p_IsUnique_76eefcea324c := FALSE;
  p_Category_76eefcea324c := 'Contact Information';
  p_ValueListType_76eefcea324c := 'None';
  p_DefaultInView_76eefcea324c := FALSE;
  p_DefaultColumnWidth_76eefcea324c := 150;
  p_AllowUpdateAPI_76eefcea324c := FALSE;
  p_AllowUpdateInView_76eefcea324c := TRUE;
  p_IncludeInUserSearchAPI_76eefcea324c := FALSE;
  p_FullTextSearchEnabled_76eefcea324c := FALSE;
  p_IncludeInGeneratedForm_76eefcea324c := TRUE;
  p_GeneratedFormSection_76eefcea324c := 'Category';
  p_IsNameField_76eefcea324c := FALSE;
  p_IncludeRelatedEntityNameFieldInBaseView_76eefcea324c := FALSE;
  p_RelatedEntityDisplayType_76eefcea324c := 'Search';
  p_AutoUpdateRelatedEntityInfo_76eefcea324c := TRUE;
  p_ValuesToPackWithSchema_76eefcea324c := 'Auto';
  p_Status_76eefcea324c := 'Active';
  p_AutoUpdateIsNameField_76eefcea324c := TRUE;
  p_AutoUpdateDefaultInView_76eefcea324c := TRUE;
  p_AutoUpdateCategory_76eefcea324c := FALSE;
  p_AutoUpdateDisplayName_76eefcea324c := TRUE;
  p_AutoUpdateIncludeInUserSearchAPI_76eefcea324c := TRUE;
  p_Encrypt_76eefcea324c := FALSE;
  p_AllowDecryptInAPI_76eefcea324c := FALSE;
  p_SendEncryptedValue_76eefcea324c := FALSE;
  p_IsSoftPrimaryKey_76eefcea324c := FALSE;
  p_IsSoftForeignKey_76eefcea324c := FALSE;
  p_JSONTypeIsArray_76eefcea324c := FALSE;
  p_UserSearchPredicateAPI_76eefcea324c := 'Contains';
  p_AutoUpdateUserSearchPredicate_76eefcea324c := TRUE;
  p_AutoUpdateFullTextSearch_76eefcea324c := TRUE;
  p_AutoUpdateExtendedType_76eefcea324c := TRUE;
  p_IsComputed_76eefcea324c := TRUE;
  p_ID_76eefcea324c := 'B132DCAC-4F9F-4E98-9116-BE13AFD0E71A';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityField'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_data := jsonb_build_object(
    'DisplayName', p_DisplayName_76eefcea324c,
    'Description', p_Description_76eefcea324c,
    'AutoUpdateDescription', p_AutoUpdateDescription_76eefcea324c,
    'IsPrimaryKey', p_IsPrimaryKey_76eefcea324c,
    'IsUnique', p_IsUnique_76eefcea324c,
    'Category', p_Category_76eefcea324c,
    'ValueListType', p_ValueListType_76eefcea324c,
    'ExtendedType', p_ExtendedType_76eefcea324c,
    'CodeType', p_CodeType_76eefcea324c,
    'DefaultInView', p_DefaultInView_76eefcea324c,
    'ViewCellTemplate', p_ViewCellTemplate_76eefcea324c,
    'DefaultColumnWidth', p_DefaultColumnWidth_76eefcea324c,
    'AllowUpdateAPI', p_AllowUpdateAPI_76eefcea324c,
    'AllowUpdateInView', p_AllowUpdateInView_76eefcea324c,
    'IncludeInUserSearchAPI', p_IncludeInUserSearchAPI_76eefcea324c,
    'FullTextSearchEnabled', p_FullTextSearchEnabled_76eefcea324c,
    'UserSearchParamFormatAPI', p_UserSearchParamFormatAPI_76eefcea324c,
    'IncludeInGeneratedForm', p_IncludeInGeneratedForm_76eefcea324c,
    'GeneratedFormSection', p_GeneratedFormSection_76eefcea324c,
    'IsNameField', p_IsNameField_76eefcea324c,
    'RelatedEntityID', p_RelatedEntityID_76eefcea324c,
    'RelatedEntityFieldName', p_RelatedEntityFieldName_76eefcea324c,
    'IncludeRelatedEntityNameFieldInBaseView', p_IncludeRelatedEntityNameFieldInBaseView_76eefcea324c,
    'RelatedEntityNameFieldMap', p_RelatedEntityNameFieldMap_76eefcea324c,
    'RelatedEntityDisplayType', p_RelatedEntityDisplayType_76eefcea324c,
    'EntityIDFieldName', p_EntityIDFieldName_76eefcea324c,
    'ScopeDefault', p_ScopeDefault_76eefcea324c,
    'AutoUpdateRelatedEntityInfo', p_AutoUpdateRelatedEntityInfo_76eefcea324c,
    'ValuesToPackWithSchema', p_ValuesToPackWithSchema_76eefcea324c,
    'Status', p_Status_76eefcea324c,
    'AutoUpdateIsNameField', p_AutoUpdateIsNameField_76eefcea324c,
    'AutoUpdateDefaultInView', p_AutoUpdateDefaultInView_76eefcea324c,
    'AutoUpdateCategory', p_AutoUpdateCategory_76eefcea324c,
    'AutoUpdateDisplayName', p_AutoUpdateDisplayName_76eefcea324c,
    'AutoUpdateIncludeInUserSearchAPI', p_AutoUpdateIncludeInUserSearchAPI_76eefcea324c,
    'Encrypt', p_Encrypt_76eefcea324c,
    'EncryptionKeyID', p_EncryptionKeyID_76eefcea324c,
    'AllowDecryptInAPI', p_AllowDecryptInAPI_76eefcea324c,
    'SendEncryptedValue', p_SendEncryptedValue_76eefcea324c,
    'IsSoftPrimaryKey', p_IsSoftPrimaryKey_76eefcea324c,
    'IsSoftForeignKey', p_IsSoftForeignKey_76eefcea324c,
    'RelatedEntityJoinFields', p_RelatedEntityJoinFields_76eefcea324c,
    'JSONType', p_JSONType_76eefcea324c,
    'JSONTypeIsArray', p_JSONTypeIsArray_76eefcea324c,
    'JSONTypeDefinition', p_JSONTypeDefinition_76eefcea324c,
    'UserSearchPredicateAPI', p_UserSearchPredicateAPI_76eefcea324c,
    'AutoUpdateUserSearchPredicate', p_AutoUpdateUserSearchPredicate_76eefcea324c,
    'AutoUpdateFullTextSearch', p_AutoUpdateFullTextSearch_76eefcea324c,
    'AutoUpdateExtendedType', p_AutoUpdateExtendedType_76eefcea324c,
    'IsComputed', p_IsComputed_76eefcea324c
  ) ||
  jsonb_build_object(
    'EmbeddedRecord', p_EmbeddedRecord_76eefcea324c,
    'Configuration', p_Configuration_76eefcea324c,
    'ID', p_ID_76eefcea324c
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_DisplayName := p_DisplayName_76eefcea324c, p_Description := p_Description_76eefcea324c, p_AutoUpdateDescription := p_AutoUpdateDescription_76eefcea324c, p_IsPrimaryKey := p_IsPrimaryKey_76eefcea324c, p_IsUnique := p_IsUnique_76eefcea324c, p_Category := p_Category_76eefcea324c, p_ValueListType := p_ValueListType_76eefcea324c, p_ExtendedType := p_ExtendedType_76eefcea324c, p_ExtendedType_Clear := TRUE, p_CodeType := p_CodeType_76eefcea324c, p_CodeType_Clear := TRUE, p_DefaultInView := p_DefaultInView_76eefcea324c, p_ViewCellTemplate := p_ViewCellTemplate_76eefcea324c, p_ViewCellTemplate_Clear := TRUE, p_DefaultColumnWidth := p_DefaultColumnWidth_76eefcea324c, p_AllowUpdateAPI := p_AllowUpdateAPI_76eefcea324c, p_AllowUpdateInView := p_AllowUpdateInView_76eefcea324c, p_IncludeInUserSearchAPI := p_IncludeInUserSearchAPI_76eefcea324c, p_FullTextSearchEnabled := p_FullTextSearchEnabled_76eefcea324c, p_UserSearchParamFormatAPI := p_UserSearchParamFormatAPI_76eefcea324c, p_UserSearchParamFormatAPI_Clear := TRUE, p_IncludeInGeneratedForm := p_IncludeInGeneratedForm_76eefcea324c, p_GeneratedFormSection := p_GeneratedFormSection_76eefcea324c, p_IsNameField := p_IsNameField_76eefcea324c, p_RelatedEntityID := p_RelatedEntityID_76eefcea324c, p_RelatedEntityID_Clear := TRUE, p_RelatedEntityFieldName := p_RelatedEntityFieldName_76eefcea324c, p_RelatedEntityFieldName_Clear := TRUE, p_IncludeRelatedEntityNameFieldInBaseView := p_IncludeRelatedEntityNameFieldInBaseView_76eefcea324c, p_RelatedEntityNameFieldMap := p_RelatedEntityNameFieldMap_76eefcea324c, p_RelatedEntityNameFieldMap_Clear := TRUE, p_RelatedEntityDisplayType := p_RelatedEntityDisplayType_76eefcea324c, p_EntityIDFieldName := p_EntityIDFieldName_76eefcea324c, p_EntityIDFieldName_Clear := TRUE, p_ScopeDefault := p_ScopeDefault_76eefcea324c, p_ScopeDefault_Clear := TRUE, p_AutoUpdateRelatedEntityInfo := p_AutoUpdateRelatedEntityInfo_76eefcea324c, p_ValuesToPackWithSchema := p_ValuesToPackWithSchema_76eefcea324c, p_Status := p_Status_76eefcea324c, p_AutoUpdateIsNameField := p_AutoUpdateIsNameField_76eefcea324c, p_AutoUpdateDefaultInView := p_AutoUpdateDefaultInView_76eefcea324c, p_AutoUpdateCategory := p_AutoUpdateCategory_76eefcea324c, p_AutoUpdateDisplayName := p_AutoUpdateDisplayName_76eefcea324c, p_AutoUpdateIncludeInUserSearchAPI := p_AutoUpdateIncludeInUserSearchAPI_76eefcea324c, p_Encrypt := p_Encrypt_76eefcea324c, p_EncryptionKeyID := p_EncryptionKeyID_76eefcea324c, p_EncryptionKeyID_Clear := TRUE, p_AllowDecryptInAPI := p_AllowDecryptInAPI_76eefcea324c, p_SendEncryptedValue := p_SendEncryptedValue_76eefcea324c, p_IsSoftPrimaryKey := p_IsSoftPrimaryKey_76eefcea324c, p_IsSoftForeignKey := p_IsSoftForeignKey_76eefcea324c, p_RelatedEntityJoinFields := p_RelatedEntityJoinFields_76eefcea324c, p_RelatedEntityJoinFields_Clear := TRUE, p_JSONType := p_JSONType_76eefcea324c, p_JSONType_Clear := TRUE, p_JSONTypeIsArray := p_JSONTypeIsArray_76eefcea324c, p_JSONTypeDefinition := p_JSONTypeDefinition_76eefcea324c, p_JSONTypeDefinition_Clear := TRUE, p_UserSearchPredicateAPI := p_UserSearchPredicateAPI_76eefcea324c, p_AutoUpdateUserSearchPredicate := p_AutoUpdateUserSearchPredicate_76eefcea324c, p_AutoUpdateFullTextSearch := p_AutoUpdateFullTextSearch_76eefcea324c, p_AutoUpdateExtendedType := p_AutoUpdateExtendedType_76eefcea324c, p_IsComputed := p_IsComputed_76eefcea324c, p_EmbeddedRecord := p_EmbeddedRecord_76eefcea324c, p_EmbeddedRecord_Clear := TRUE, p_Configuration := p_Configuration_76eefcea324c, p_Configuration_Clear := TRUE, p_ID := p_ID_76eefcea324c);
  END IF;
END $mj$;

-- Save MJ: Queries (core SP call only)
DO $mj$
DECLARE
  p_ID_a5c607129cb3 UUID;
  p_Name_a5c607129cb3 VARCHAR(255);
  p_CategoryID_a5c607129cb3 UUID;
  p_UserQuestion_a5c607129cb3 TEXT;
  p_Description_a5c607129cb3 TEXT;
  p_SQL_a5c607129cb3 TEXT;
  p_TechnicalDescription_a5c607129cb3 TEXT;
  p_OriginalSQL_a5c607129cb3 TEXT;
  p_Feedback_a5c607129cb3 TEXT;
  p_Status_a5c607129cb3 VARCHAR(15);
  p_QualityRank_a5c607129cb3 INTEGER;
  p_ExecutionCostRank_a5c607129cb3 INTEGER;
  p_UsesTemplate_a5c607129cb3 BOOLEAN;
  p_AuditQueryRuns_a5c607129cb3 BOOLEAN;
  p_CacheEnabled_a5c607129cb3 BOOLEAN;
  p_CacheTTLMinutes_a5c607129cb3 INTEGER;
  p_CacheMaxSize_a5c607129cb3 INTEGER;
  p_EmbeddingVector_a5c607129cb3 TEXT;
  p_EmbeddingModelID_a5c607129cb3 UUID;
  p_CacheValidationSQL_a5c607129cb3 TEXT;
  p_SQLDialectID_a5c607129cb3 UUID;
  p_Reusable_a5c607129cb3 BOOLEAN;
  p_ExternalDataSourceID_a5c607129cb3 UUID;
  p_IsMaterialized_a5c607129cb3 BOOLEAN;
BEGIN
  p_ID_a5c607129cb3 := '90E212A2-5E1B-46DC-B468-38B6AF5E2352';
  p_Name_a5c607129cb3 := 'Common: Party Lookup Organizations';
  p_CategoryID_a5c607129cb3 := '6C0A1000-0000-4000-A000-000000000001';
  p_UserQuestion_a5c607129cb3 := 'Which organizations match what the user is typing into an organization picker?';
  p_Description_a5c607129cb3 := 'Up to 20 organizations whose name or legal name starts with the typed term, or whose website domain starts with the typed domain. Backs bizapps-party-field.';
  p_SQL_a5c607129cb3 := '-- Party lookup for Organizations: prefix match on indexed base-table columns, TOP 20, no COUNT.
-- Contract shared by every party lookup query (bizapps-party-field): columns ID, Name, Detail;
-- parameters Term (required) and Domain (optional, already normalized by the picker).
-- sqlLikeBegins escapes the term and appends the trailing wildcard.
SELECT TOP 20
    o.ID,
    o.Name,
    o.WebsiteDomain AS Detail
FROM [__mj_BizAppsCommon].[Organization] o
WHERE o.Name LIKE {{ Term | sqlLikeBegins }}
   OR o.LegalName LIKE {{ Term | sqlLikeBegins }}
{% if Domain %}   OR o.WebsiteDomain LIKE {{ Domain | sqlLikeBegins }}
{% endif %}ORDER BY o.Name, o.ID
';
  p_TechnicalDescription_a5c607129cb3 := 'Grain: one row per Organization, TOP 20 ordered by Name, ID. Base table __mj_BizAppsCommon.Organization, prefix LIKE on indexed Name, LegalName and WebsiteDomain; no view, no COUNT. Parameters: Term (required), Domain (optional, lower-cased host without scheme, www. or path). Columns: ID, Name, Detail (WebsiteDomain).';
  p_Status_a5c607129cb3 := 'Approved';
  p_QualityRank_a5c607129cb3 := 9;
  p_ExecutionCostRank_a5c607129cb3 := 1;
  p_UsesTemplate_a5c607129cb3 := TRUE;
  p_AuditQueryRuns_a5c607129cb3 := FALSE;
  p_CacheEnabled_a5c607129cb3 := FALSE;
  p_EmbeddingVector_a5c607129cb3 := '[-0.00464969826862216,0.05749530717730522,0.031015122309327126,-0.015673315152525902,0.000994990230537951,-0.07683653384447098,0.061803217977285385,0.028522774577140808,0.05503202602267265,0.0004626007576007396,-0.01990542560815811,0.015948981046676636,0.03072373755276203,0.05933351442217827,-0.050539568066596985,0.001820718520320952,0.02048090659081936,-0.01675092987716198,0.0024375675711780787,-0.033311616629362106,-0.016226746141910553,-0.005412350408732891,-0.036179352551698685,-0.0017372685251757503,-0.01747543178498745,0.01042481791228056,0.0014456461649388075,-0.009877834469079971,0.022637799382209778,-0.03792611137032509,0.009808307513594627,-0.019961385056376457,-0.027200929820537567,0.011816873215138912,0.0000022203514618013287,-0.03485051542520523,-0.06400328874588013,-0.00808139517903328,-0.007145541720092297,-0.0019242604030296206,-0.02482675574719906,0.06281022727489471,-0.016476314514875412,0.007388751953840256,0.02432171255350113,0.02821010909974575,0.01006452739238739,0.03334314003586769,-0.03026488609611988,0.001289878273382783,0.014136264100670815,0.028939949348568916,-0.02380395121872425,0.011476133950054646,-0.01326716598123312,-0.054354142397642136,0.04920387268066406,-0.08686952292919159,0.05564437806606293,0.0074873510748147964,0.0378253236413002,-0.037533119320869446,-0.05024729669094086,-0.028290117159485817,-0.025665540248155594,0.04554847627878189,-0.036545827984809875,-0.009660841897130013,-0.001454644021578133,-0.025812579318881035,0.05974731594324112,0.02954464592039585,-0.0544036403298378,-0.06592825800180435,-0.008275511674582958,0.07351754605770111,0.01154301781207323,0.022205373272299767,-0.012632197700440884,-0.015192319639027119,0.03699653223156929,0.07436555624008179,-0.005672852974385023,0.03751291334629059,-0.03904156759381294,0.10010350495576859,0.004566550254821777,-0.003499471815302968,0.009774915874004364,-0.00934159941971302,-0.011705098673701286,-0.003728821175172925,0.027653153985738754,-0.010379759594798088,-0.04558224231004715,-0.021048305556178093,0.008613036945462227,0.03679252043366432,0.07077465206384659,-0.022894510999321938,-0.014709742739796638,0.015697326511144638,-0.02172710746526718,0.02299206331372261,0.05179538205265999,-0.04343067482113838,-0.010905887931585312,0.02988123893737793,0.02005043998360634,-0.05073390156030655,-0.023930542171001434,-0.0036357888020575047,-0.04414491727948189,0.06107698008418083,-0.05729950591921806,-0.016400348395109177,-0.05611080676317215,0.03341340646147728,-0.01102900318801403,0.009687384590506554,0.06868159770965576,0.012391782365739346,0.06429704278707504,-0.02416580729186535,-0.07157736271619797,-0.019347894936800003,-0.05704604461789131,-0.015773260965943336,-0.005822828505188227,-0.010317635722458363,0.03270316123962402,-0.01303580217063427,0.04817567765712738,-0.06560774147510529,0.0294768325984478,0.020588938146829605,0.013456655666232109,-0.03941153734922409,0.02737613581120968,0.05088069662451744,0.019100239500403404,-0.03734571486711502,0.002030988223850727,0.05341280251741409,0.009861733764410019,-0.0167912095785141,0.012614095583558083,-0.0920511931180954,-0.00914661306887865,0.02222122624516487,-0.04292454570531845,0.007037754636257887,-0.030102042481303215,-0.009137994609773159,0.034938275814056396,-0.009958534501492977,-0.02429770864546299,-0.012051459401845932,0.01954203099012375,-0.021572401747107506,0.01561374869197607,-0.022477617487311363,0.026471586897969246,0.02504868060350418,-0.02054101787507534,-0.0007319802534766495,0.061214279383420944,0.050429146736860275,-0.0031249872408807278,0.019292673096060753,-0.00936347246170044,-0.025770965963602066,0.005976920947432518,-0.05216943100094795,0.014922256581485271,0.07915574312210083,0.04075031727552414,0.01689176820218563,-0.037887685000896454,-0.02582995407283306,-0.008228380233049393,-0.04005712270736694,-0.04621439799666405,0.02995024435222149,-0.025632312521338463,-0.01078388374298811,0.04908725619316101,0.04470202326774597,-0.011755048297345638,0.0358593724668026,0.005060639698058367,0.007050949148833752,-0.029910294339060783,0.028625503182411194,0.019134724512696266,-0.042859192937612534,-0.024498557671904564,-0.027448777109384537,-0.010507756844162941,0.02673780918121338,-0.06058352068066597,-0.05477345734834671,-0.04266536608338356,0.08801928907632828,0.012931063771247864,-0.0487792044878006,0.010144953615963459,0.01966002583503723,-0.03757808357477188,0.031085655093193054,0.038172248750925064,0.010114242322742939,0.021447138860821724,0.04684380814433098,-0.010431678965687752,0.12677940726280212,0.025192497298121452,0.019894666969776154,0.0072134388610720634,-0.016452955082058907,-0.03754303976893425,0.02562948502600193,0.005712698679417372,0.01513706985861063,-0.012203590013086796,0.05591484159231186,-0.025407331064343452,0.014529491774737835,0.012942439876496792,-0.01347199734300375,0.021790916100144386,-0.01312826108187437,0.04540596529841423,0.02074815332889557,0.055302299559116364,-0.06686452776193619,0.0815223976969719,0.07668786495923996,0.009908612817525864,0.028434785082936287,0.0044297887943685055,-0.035432398319244385,0.01127240527421236,-0.0008990340284071863,0.016192981973290443,0.018875496461987495,-0.029131755232810974,0.018082574009895325,0.020093152299523354,-0.002586774528026581,-0.0029730258975178003,-0.005593554116785526,0.04472414031624794,-0.017990760505199432,-0.026229355484247208,-0.04249463230371475,-0.029139284044504166,0.0047180624678730965,-0.03954729437828064,0.015399230644106865,0.015024776570498943,-0.02769661508500576,0.015445160679519176,0.005222592037171125,-0.009135154075920582,0.004986138548702002,-0.03570745512843132,0.011706494726240635,0.02452000044286251,0.021951017901301384,-0.012430079281330109,-0.0631290078163147,0.03975239023566246,-0.011640183627605438,0.031578294932842255,0.05863558128476143,-0.0293285995721817,-0.015429156832396984,0.035049960017204285,-0.0009612946305423975,-0.0052449326030910015,-0.07194673269987106,-0.00875834096223116,0.012246224097907543,-0.010437491349875927,0.0156304519623518,0.02884550392627716,-0.13957606256008148,0.02616726979613304,-0.054132960736751556,-0.026175634935498238,-0.022601144388318062,0.0031157254707068205,-0.018545087426900864,0.04843582585453987,0.022588133811950684,-0.014580024406313896,0.0626942366361618,0.009309620596468449,0.007271573878824711,-0.008293960243463516,0.0567941814661026,-0.06537019461393356,-0.029459211975336075,0.007721583358943462,0.0035606836900115013,0.047007005661726,0.002304866909980774,0.041816674172878265,0.08584227412939072,-0.055286962538957596,0.03516476973891258,0.03717536851763725,-0.01404198445379734,0.0571022666990757,0.0033614758867770433,0.029757948592305183,-0.027800753712654114,-0.04062293469905853,0.02125827595591545,0.04982609674334526,0.04588873311877251,0.008649283088743687,-0.011742775328457355,-0.0028343412559479475,0.0381355918943882,-0.01694684848189354,0.014135574921965599,-0.01651882380247116,0.02269378863275051,0.01683075726032257,0.0612042099237442,-0.04307984188199043,0.024960076436400414,0.02647305093705654,-0.015151293016970158,-0.0289829783141613,0.11645542830228806,0.03790595382452011,0.04309036582708359,0.010096171870827675,-0.024103177711367607,-0.03955825790762901,-0.01729755476117134,-0.019973481073975563,0.028111472725868225,-0.04918042570352554,-0.018519584089517593,-0.056874845176935196,0.008946768939495087,0.004239202011376619,0.034540191292762756,-0.007263730745762587,-0.005605506245046854,0.001982963876798749,-0.05171843618154526,-0.02712293341755867,0.015514151193201542,0.017260199412703514,-0.0006289660814218223,-0.1107286587357521,-0.037091758102178574,0.034965548664331436,-0.008734703063964844,-0.028303422033786774,-0.01904693804681301,0.004352923482656479,-0.08851666003465652,-0.023035803809762,-0.029785355553030968,0.009959332644939423,-0.006343551445752382,0.04406268149614334,-0.0055459183640778065,0.011047535575926304,-0.041341155767440796,-0.024787671864032745,0.017025409266352654,0.011664044111967087,0.03511049598455429,0.03782748058438301,-0.053655240684747696,-0.008445140905678272,-0.0007168431766331196,-0.027761349454522133,-0.040241725742816925,-0.04437240585684776,-0.0402546189725399,-0.06329623609781265,-0.03504865616559982,-0.04709739238023758,0.05159541592001915,0.00446298997849226,-0.011273205280303955,0.046410489827394485,-0.046434544026851654,-0.0580248199403286,-0.009047061204910278,-0.04446125403046608,-0.022507047280669212,0.0007991011952981353,0.0010830076644197106,0.0017416216433048248,0.00354846497066319,-0.03429357334971428,0.028187524527311325,0.021234525367617607,0.03081955574452877,0.02359473519027233,0.017864972352981567,0.03200950846076012,-0.04681294411420822,-0.022063065320253372,0.009012347087264061,0.02671419270336628,-0.032606158405542374,0.0530882328748703,0.006551648024469614,-0.004920291714370251,0.05626298487186432,-0.01658831723034382,0.0017517493106424809,0.022936299443244934,0.0077073462307453156,-0.009677250869572163,-0.008797716349363327,0.024382926523685455,-0.008239826187491417,0.053091879934072495,0.013566112145781517,-0.04236970841884613,0.051276396960020065,-0.05749768391251564,0.002814807230606675,-0.012465890496969223,0.036775197833776474,0.003691144986078143,-0.028018902987241745,0.02631937526166439,0.005308670923113823,0.04611104354262352,0.04409481957554817,0.023960435763001442,-0.002444805111736059,0.04352357238531113,-0.003538173856213689,0.024927057325839996,0.06691210716962814,0.025254011154174805,-0.03701440244913101,-0.014949849806725979,-0.02918814681470394,-0.06622208654880524,0.0001754535478539765,0.017881661653518677,-0.040177199989557266,-0.010502224788069725,0.10749145597219467,-0.0114406393840909,0.06598395854234695,-0.0307147279381752,0.028389638289809227,-0.010324440896511078,-0.020323552191257477,-0.020327253267169,-0.01218980923295021,-0.020814215764403343,0.004126028157770634,-0.02805471047759056,-0.025500275194644928,0.003334605600684881,0.028241632506251335,0.0005089687183499336,-0.015207801945507526,0.027828140184283257,0.024927332997322083,-0.04550663381814957,-0.07285548001527786,-0.03171776607632637,0.004396241623908281,0.04821011424064636,-0.00445231469348073,-0.007479738909751177,0.005125853233039379,0.022428790107369423,-0.00989498756825924,0.020084688439965248,0.021352143958210945,-0.003512887516990304,-0.02484046295285225,-0.011723036877810955,-0.07687779515981674,-0.011963997036218643,0.010291929356753826,-0.04310663416981697,0.1024857759475708,0.0044314805418252945,0.02274888940155506,0.003858576063066721,0.015155337750911713,0.013566539622843266,0.006859467830508947,-0.004055332858115435,-0.006625785492360592,-0.0127313993871212,0.05483773723244667,0.01424548588693142,-0.06402827799320221,0.016556082293391228,-0.014048303477466106,-0.02013413794338703,-0.025913380086421967,-0.03287290409207344,0.039670430123806,0.014817907474935055,0.13851313292980194,-0.01529702078551054,0.034942787140607834,-0.03085997886955738,0.014990122988820076,0.017954230308532715,-0.004289430100470781,0.0006769352476112545,0.040688347071409225,-0.0662728101015091,0.00766459247097373,0.03416319936513901,0.0010916288010776043,-0.04459444433450699,0.0015291145537048578,0.0761309564113617,-0.049261145293712616,0.0038582191336899996,0.052610937505960464,-0.00880130473524332,-0.00145908840931952,-0.04956044629216194,0.02551037259399891,-0.03750278055667877,0.02281903102993965,-0.008861795999109745,0.02305958792567253,-0.037778839468955994,-0.037945300340652466,0.00770173966884613,0.02119433879852295,-0.021881088614463806,-0.01971137523651123,-0.0027746378909796476,0.011641332879662514,0.007275060750544071,-0.019724898040294647,-0.06170181557536125,-0.03757063299417496,0.03492021560668945,-6.646416240914052e-33,-0.0680190697312355,-0.03403758630156517,0.029510095715522766,-0.07521336525678635,-0.04180257022380829,-0.034196700900793076,-0.005681363400071859,0.00418833177536726,-0.026825958862900734,0.007817137986421585,-0.05242028087377548,-0.033861879259347916,0.017835356295108795,0.004468067549169064,0.04233019798994064,-0.02260987088084221,-0.015913302078843117,0.009846207685768604,-0.018410896882414818,-0.01984093151986599,-0.004402780439704657,0.028441883623600006,0.011573267169296741,0.0009154761210083961,-0.03928186744451523,0.016106702387332916,-0.01708226464688778,0.0080118952319026,0.04199377819895744,0.0434555783867836,0.03491531312465668,-0.06144978478550911,-0.017319025471806526,-0.03431137651205063,0.01787865348160267,0.02603105828166008,-0.043207015842199326,0.02153904363512993,-0.024013275280594826,0.009897039271891117,0.12787598371505737,-0.017523709684610367,-0.025714855641126633,-0.034159377217292786,0.0034507273230701685,0.0037242050748318434,0.02942666783928871,-0.046513959765434265,-0.06754074990749359,0.07379560172557831,0.005442282650619745,-0.027110032737255096,0.04075998067855835,0.0740722194314003,0.032676197588443756,0.00697599072009325,0.03143159672617912,-0.011305741965770721,-0.006662158295512199,0.002328325528651476,-0.05772782117128372,-0.015919458121061325,-0.018699774518609047,-0.0197902899235487,-0.005117008928209543,0.02827506884932518,-0.06373090296983719,-0.04399118572473526,-0.039269350469112396,-0.11419776827096939,-0.05752820149064064,0.07342194765806198,-0.028256183490157127,0.0010615900391712785,0.047232866287231445,-0.028266167268157005,-0.011699155904352665,0.004072493873536587,0.048581309616565704,-0.08672767132520676,0.05363360047340393,-0.024643927812576294,-0.011961755342781544,-0.001565802376717329,0.022464832291007042,0.00449791457504034,-0.018297499045729637,-0.020557131618261337,-0.0012393821962177753,0.01565682142972946,-0.020344935357570648,0.054020702838897705,-0.017084673047065735,-0.054391153156757355,-0.07768773287534714,0.03652448579668999,0.02170402556657791,0.002067029010504484,-0.0009311971953138709,-0.003977383952587843,-0.03971797972917557,0.01035988051444292,-0.061502132564783096,-0.009465615265071392,0.047531601041555405,0.00764372618868947,0.007815533317625523,-0.047577813267707825,-0.049931034445762634,0.00035929997102357447,0.004386628046631813,-0.0024503320455551147,-0.03220842406153679,-0.003144675400108099,0.0454709455370903,-0.004258366767317057,0.01237950287759304,-0.04379299283027649,0.004433603957295418,0.011886171996593475,0.04808202013373375,0.04959733784198761,-0.03687211126089096,0.0317426361143589,-0.025180663913488388,0.023779388517141342,-0.02510467730462551,-0.022767754271626472,0.017979975789785385,0.005612501408904791,0.0009009990026243031,-0.042794160544872284,2.9804502332808624e-7,0.0034716762602329254,0.021866723895072937,-0.04784338176250458,0.07027789950370789,-0.007312247529625893,-0.009068554267287254,0.04054288566112518,0.02054695226252079,-0.03235694766044617,-0.041158560663461685,-0.06008667126297951,-0.040634188801050186,0.01484947931021452,0.034337859600782394,-0.0537429042160511,-0.06032542884349823,0.04872586205601692,0.044947728514671326,-0.02543029934167862,0.018142037093639374,-0.0727938786149025,-0.012438937090337276,0.04450607672333717,-0.014183327555656433,0.0014481715625151992,-0.0022249009925872087,0.012458189390599728,-0.027414090931415558,-0.02404712699353695,0.05589333176612854,-0.016087902709841728,-0.0673695057630539,0.00015664537204429507,0.08894562721252441,-0.012004387564957142,0.056516993790864944,-0.002677849493920803,-0.011729811318218708,0.012572678737342358,-0.026077773422002792,0.02054775319993496,-0.08119001984596252,0.004949316382408142,0.0271233469247818,0.026611536741256714,-0.022450098767876625,0.008543932810425758,0.0117224445566535,-0.03163043409585953,-0.07866120338439941,0.021281208842992783,-0.005665542557835579,0.027152348309755325,-0.013770423829555511,0.023755716159939766,-0.05195557326078415,0.01831205002963543,0.03101804479956627,0.05413563922047615,-0.034024517983198166,0.005648665130138397,-0.006596403196454048,-0.0034565816167742014,-0.05612397566437721,0.09760383516550064,0.011110086925327778,-0.0569581538438797,3.0452097217125534e-34,-0.006006239913403988,0.014682985842227936,0.02073010243475437,0.05625973269343376,0.017043597996234894,0.0012405675370246172,0.05408794432878494,-0.02592133730649948,0.011424463242292404,0.050631605088710785,0.023771168664097786]';
  p_EmbeddingModelID_a5c607129cb3 := '1D45AA65-41EC-4572-9ECD-AB2826C9B059';
  p_Reusable_a5c607129cb3 := TRUE;
  p_IsMaterialized_a5c607129cb3 := FALSE;
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQuery'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spCreateQuery"(p_data := jsonb_build_object(
    'ID', p_ID_a5c607129cb3,
    'Name', p_Name_a5c607129cb3,
    'CategoryID', p_CategoryID_a5c607129cb3,
    'UserQuestion', p_UserQuestion_a5c607129cb3,
    'Description', p_Description_a5c607129cb3,
    'SQL', p_SQL_a5c607129cb3,
    'TechnicalDescription', p_TechnicalDescription_a5c607129cb3,
    'OriginalSQL', p_OriginalSQL_a5c607129cb3,
    'Feedback', p_Feedback_a5c607129cb3,
    'Status', p_Status_a5c607129cb3,
    'QualityRank', p_QualityRank_a5c607129cb3,
    'ExecutionCostRank', p_ExecutionCostRank_a5c607129cb3,
    'UsesTemplate', p_UsesTemplate_a5c607129cb3,
    'AuditQueryRuns', p_AuditQueryRuns_a5c607129cb3,
    'CacheEnabled', p_CacheEnabled_a5c607129cb3,
    'CacheTTLMinutes', p_CacheTTLMinutes_a5c607129cb3,
    'CacheMaxSize', p_CacheMaxSize_a5c607129cb3,
    'EmbeddingVector', p_EmbeddingVector_a5c607129cb3,
    'EmbeddingModelID', p_EmbeddingModelID_a5c607129cb3,
    'CacheValidationSQL', p_CacheValidationSQL_a5c607129cb3,
    'SQLDialectID', p_SQLDialectID_a5c607129cb3,
    'Reusable', p_Reusable_a5c607129cb3,
    'ExternalDataSourceID', p_ExternalDataSourceID_a5c607129cb3,
    'IsMaterialized', p_IsMaterialized_a5c607129cb3
  ));
  ELSE
    PERFORM "${mjSchema}"."spCreateQuery"(p_ID := p_ID_a5c607129cb3, p_Name := p_Name_a5c607129cb3, p_CategoryID := p_CategoryID_a5c607129cb3, p_UserQuestion := p_UserQuestion_a5c607129cb3, p_Description := p_Description_a5c607129cb3, p_SQL := p_SQL_a5c607129cb3, p_TechnicalDescription := p_TechnicalDescription_a5c607129cb3, p_OriginalSQL := p_OriginalSQL_a5c607129cb3, p_OriginalSQL_Clear := TRUE, p_Feedback := p_Feedback_a5c607129cb3, p_Feedback_Clear := TRUE, p_Status := p_Status_a5c607129cb3, p_QualityRank := p_QualityRank_a5c607129cb3, p_ExecutionCostRank := p_ExecutionCostRank_a5c607129cb3, p_UsesTemplate := p_UsesTemplate_a5c607129cb3, p_AuditQueryRuns := p_AuditQueryRuns_a5c607129cb3, p_CacheEnabled := p_CacheEnabled_a5c607129cb3, p_CacheTTLMinutes := p_CacheTTLMinutes_a5c607129cb3, p_CacheTTLMinutes_Clear := TRUE, p_CacheMaxSize := p_CacheMaxSize_a5c607129cb3, p_CacheMaxSize_Clear := TRUE, p_EmbeddingVector := p_EmbeddingVector_a5c607129cb3, p_EmbeddingModelID := p_EmbeddingModelID_a5c607129cb3, p_CacheValidationSQL := p_CacheValidationSQL_a5c607129cb3, p_CacheValidationSQL_Clear := TRUE, p_SQLDialectID := p_SQLDialectID_a5c607129cb3, p_Reusable := p_Reusable_a5c607129cb3, p_ExternalDataSourceID := p_ExternalDataSourceID_a5c607129cb3, p_ExternalDataSourceID_Clear := TRUE, p_IsMaterialized := p_IsMaterialized_a5c607129cb3);
  END IF;
END $mj$;

-- Save MJ: Query Parameters (core SP call only)
DO $mj$
DECLARE
  p_ID_c6e761392588 UUID;
  p_QueryID_c6e761392588 UUID;
  p_Name_c6e761392588 VARCHAR(255);
  p_Type_c6e761392588 VARCHAR(50);
  p_IsRequired_c6e761392588 BOOLEAN;
  p_DefaultValue_c6e761392588 TEXT;
  p_Description_c6e761392588 TEXT;
  p_SampleValue_c6e761392588 TEXT;
  p_ValidationFilters_c6e761392588 TEXT;
  p_DetectionMethod_c6e761392588 VARCHAR(50);
  p_AutoDetectConfidenceScore_c6e761392588 NUMERIC(3,2);
BEGIN
  p_ID_c6e761392588 := '9b219892-7d55-4878-b368-477ee0165130';
  p_QueryID_c6e761392588 := '90E212A2-5E1B-46DC-B468-38B6AF5E2352';
  p_Name_c6e761392588 := 'Term';
  p_Type_c6e761392588 := 'string';
  p_IsRequired_c6e761392588 := TRUE;
  p_Description_c6e761392588 := 'Required value for Term';
  p_DetectionMethod_c6e761392588 := 'AI';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryParameter'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spCreateQueryParameter"(p_data := jsonb_build_object(
    'ID', p_ID_c6e761392588,
    'QueryID', p_QueryID_c6e761392588,
    'Name', p_Name_c6e761392588,
    'Type', p_Type_c6e761392588,
    'IsRequired', p_IsRequired_c6e761392588,
    'DefaultValue', p_DefaultValue_c6e761392588,
    'Description', p_Description_c6e761392588,
    'SampleValue', p_SampleValue_c6e761392588,
    'ValidationFilters', p_ValidationFilters_c6e761392588,
    'DetectionMethod', p_DetectionMethod_c6e761392588,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_c6e761392588
  ));
  ELSE
    PERFORM "${mjSchema}"."spCreateQueryParameter"(p_ID := p_ID_c6e761392588, p_QueryID := p_QueryID_c6e761392588, p_Name := p_Name_c6e761392588, p_Type := p_Type_c6e761392588, p_IsRequired := p_IsRequired_c6e761392588, p_DefaultValue := p_DefaultValue_c6e761392588, p_DefaultValue_Clear := TRUE, p_Description := p_Description_c6e761392588, p_SampleValue := p_SampleValue_c6e761392588, p_SampleValue_Clear := TRUE, p_ValidationFilters := p_ValidationFilters_c6e761392588, p_ValidationFilters_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_c6e761392588, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_c6e761392588, p_AutoDetectConfidenceScore_Clear := TRUE);
  END IF;
END $mj$;

-- Save MJ: Query Parameters (core SP call only)
DO $mj$
DECLARE
  p_ID_e7e40eeffe32 UUID;
  p_QueryID_e7e40eeffe32 UUID;
  p_Name_e7e40eeffe32 VARCHAR(255);
  p_Type_e7e40eeffe32 VARCHAR(50);
  p_IsRequired_e7e40eeffe32 BOOLEAN;
  p_DefaultValue_e7e40eeffe32 TEXT;
  p_Description_e7e40eeffe32 TEXT;
  p_SampleValue_e7e40eeffe32 TEXT;
  p_ValidationFilters_e7e40eeffe32 TEXT;
  p_DetectionMethod_e7e40eeffe32 VARCHAR(50);
  p_AutoDetectConfidenceScore_e7e40eeffe32 NUMERIC(3,2);
BEGIN
  p_ID_e7e40eeffe32 := '3773d9e2-7080-4215-be82-338ab7ab222a';
  p_QueryID_e7e40eeffe32 := '90E212A2-5E1B-46DC-B468-38B6AF5E2352';
  p_Name_e7e40eeffe32 := 'Domain';
  p_Type_e7e40eeffe32 := 'string';
  p_IsRequired_e7e40eeffe32 := FALSE;
  p_Description_e7e40eeffe32 := 'Optional value for Domain';
  p_DetectionMethod_e7e40eeffe32 := 'AI';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryParameter'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spCreateQueryParameter"(p_data := jsonb_build_object(
    'ID', p_ID_e7e40eeffe32,
    'QueryID', p_QueryID_e7e40eeffe32,
    'Name', p_Name_e7e40eeffe32,
    'Type', p_Type_e7e40eeffe32,
    'IsRequired', p_IsRequired_e7e40eeffe32,
    'DefaultValue', p_DefaultValue_e7e40eeffe32,
    'Description', p_Description_e7e40eeffe32,
    'SampleValue', p_SampleValue_e7e40eeffe32,
    'ValidationFilters', p_ValidationFilters_e7e40eeffe32,
    'DetectionMethod', p_DetectionMethod_e7e40eeffe32,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_e7e40eeffe32
  ));
  ELSE
    PERFORM "${mjSchema}"."spCreateQueryParameter"(p_ID := p_ID_e7e40eeffe32, p_QueryID := p_QueryID_e7e40eeffe32, p_Name := p_Name_e7e40eeffe32, p_Type := p_Type_e7e40eeffe32, p_IsRequired := p_IsRequired_e7e40eeffe32, p_DefaultValue := p_DefaultValue_e7e40eeffe32, p_DefaultValue_Clear := TRUE, p_Description := p_Description_e7e40eeffe32, p_SampleValue := p_SampleValue_e7e40eeffe32, p_SampleValue_Clear := TRUE, p_ValidationFilters := p_ValidationFilters_e7e40eeffe32, p_ValidationFilters_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_e7e40eeffe32, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_e7e40eeffe32, p_AutoDetectConfidenceScore_Clear := TRUE);
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_a41da6863aa8 UUID;
  p_QueryID_a41da6863aa8 UUID;
  p_Name_a41da6863aa8 VARCHAR(255);
  p_Description_a41da6863aa8 TEXT;
  p_Sequence_a41da6863aa8 INTEGER;
  p_SQLBaseType_a41da6863aa8 VARCHAR(50);
  p_SQLFullType_a41da6863aa8 VARCHAR(100);
  p_SourceEntityID_a41da6863aa8 UUID;
  p_SourceFieldName_a41da6863aa8 VARCHAR(255);
  p_IsComputed_a41da6863aa8 BOOLEAN;
  p_ComputationDescription_a41da6863aa8 TEXT;
  p_IsSummary_a41da6863aa8 BOOLEAN;
  p_SummaryDescription_a41da6863aa8 TEXT;
  p_DetectionMethod_a41da6863aa8 VARCHAR(50);
  p_AutoDetectConfidenceScore_a41da6863aa8 NUMERIC(3,2);
BEGIN
  p_ID_a41da6863aa8 := '74dadf73-198d-4ade-a1d9-a7b8e111ce07';
  p_QueryID_a41da6863aa8 := '90E212A2-5E1B-46DC-B468-38B6AF5E2352';
  p_Name_a41da6863aa8 := 'ID';
  p_Description_a41da6863aa8 := 'ID';
  p_Sequence_a41da6863aa8 := 1;
  p_SQLBaseType_a41da6863aa8 := 'uniqueidentifier';
  p_SQLFullType_a41da6863aa8 := 'uniqueidentifier';
  p_SourceEntityID_a41da6863aa8 := 'C70448F9-9792-41D7-A82C-784B66429D54';
  p_SourceFieldName_a41da6863aa8 := 'ID';
  p_IsComputed_a41da6863aa8 := FALSE;
  p_IsSummary_a41da6863aa8 := FALSE;
  p_DetectionMethod_a41da6863aa8 := 'Manual';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_a41da6863aa8,
    'QueryID', p_QueryID_a41da6863aa8,
    'Name', p_Name_a41da6863aa8,
    'Description', p_Description_a41da6863aa8,
    'Sequence', p_Sequence_a41da6863aa8,
    'SQLBaseType', p_SQLBaseType_a41da6863aa8,
    'SQLFullType', p_SQLFullType_a41da6863aa8,
    'SourceEntityID', p_SourceEntityID_a41da6863aa8,
    'SourceFieldName', p_SourceFieldName_a41da6863aa8,
    'IsComputed', p_IsComputed_a41da6863aa8,
    'ComputationDescription', p_ComputationDescription_a41da6863aa8,
    'IsSummary', p_IsSummary_a41da6863aa8,
    'SummaryDescription', p_SummaryDescription_a41da6863aa8,
    'DetectionMethod', p_DetectionMethod_a41da6863aa8,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_a41da6863aa8
  ));
  ELSE
    PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_a41da6863aa8, p_QueryID := p_QueryID_a41da6863aa8, p_Name := p_Name_a41da6863aa8, p_Description := p_Description_a41da6863aa8, p_Sequence := p_Sequence_a41da6863aa8, p_SQLBaseType := p_SQLBaseType_a41da6863aa8, p_SQLFullType := p_SQLFullType_a41da6863aa8, p_SourceEntityID := p_SourceEntityID_a41da6863aa8, p_SourceFieldName := p_SourceFieldName_a41da6863aa8, p_IsComputed := p_IsComputed_a41da6863aa8, p_ComputationDescription := p_ComputationDescription_a41da6863aa8, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_a41da6863aa8, p_SummaryDescription := p_SummaryDescription_a41da6863aa8, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_a41da6863aa8, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_a41da6863aa8, p_AutoDetectConfidenceScore_Clear := TRUE);
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_6f1631f21e4c UUID;
  p_QueryID_6f1631f21e4c UUID;
  p_Name_6f1631f21e4c VARCHAR(255);
  p_Description_6f1631f21e4c TEXT;
  p_Sequence_6f1631f21e4c INTEGER;
  p_SQLBaseType_6f1631f21e4c VARCHAR(50);
  p_SQLFullType_6f1631f21e4c VARCHAR(100);
  p_SourceEntityID_6f1631f21e4c UUID;
  p_SourceFieldName_6f1631f21e4c VARCHAR(255);
  p_IsComputed_6f1631f21e4c BOOLEAN;
  p_ComputationDescription_6f1631f21e4c TEXT;
  p_IsSummary_6f1631f21e4c BOOLEAN;
  p_SummaryDescription_6f1631f21e4c TEXT;
  p_DetectionMethod_6f1631f21e4c VARCHAR(50);
  p_AutoDetectConfidenceScore_6f1631f21e4c NUMERIC(3,2);
BEGIN
  p_ID_6f1631f21e4c := 'c40951b7-1bf3-4703-ba05-cdecdb4dc478';
  p_QueryID_6f1631f21e4c := '90E212A2-5E1B-46DC-B468-38B6AF5E2352';
  p_Name_6f1631f21e4c := 'Name';
  p_Description_6f1631f21e4c := 'Name';
  p_Sequence_6f1631f21e4c := 2;
  p_SQLBaseType_6f1631f21e4c := 'nvarchar';
  p_SQLFullType_6f1631f21e4c := 'nvarchar(255)';
  p_SourceEntityID_6f1631f21e4c := 'C70448F9-9792-41D7-A82C-784B66429D54';
  p_SourceFieldName_6f1631f21e4c := 'Name';
  p_IsComputed_6f1631f21e4c := FALSE;
  p_IsSummary_6f1631f21e4c := FALSE;
  p_DetectionMethod_6f1631f21e4c := 'Manual';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_6f1631f21e4c,
    'QueryID', p_QueryID_6f1631f21e4c,
    'Name', p_Name_6f1631f21e4c,
    'Description', p_Description_6f1631f21e4c,
    'Sequence', p_Sequence_6f1631f21e4c,
    'SQLBaseType', p_SQLBaseType_6f1631f21e4c,
    'SQLFullType', p_SQLFullType_6f1631f21e4c,
    'SourceEntityID', p_SourceEntityID_6f1631f21e4c,
    'SourceFieldName', p_SourceFieldName_6f1631f21e4c,
    'IsComputed', p_IsComputed_6f1631f21e4c,
    'ComputationDescription', p_ComputationDescription_6f1631f21e4c,
    'IsSummary', p_IsSummary_6f1631f21e4c,
    'SummaryDescription', p_SummaryDescription_6f1631f21e4c,
    'DetectionMethod', p_DetectionMethod_6f1631f21e4c,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_6f1631f21e4c
  ));
  ELSE
    PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_6f1631f21e4c, p_QueryID := p_QueryID_6f1631f21e4c, p_Name := p_Name_6f1631f21e4c, p_Description := p_Description_6f1631f21e4c, p_Sequence := p_Sequence_6f1631f21e4c, p_SQLBaseType := p_SQLBaseType_6f1631f21e4c, p_SQLFullType := p_SQLFullType_6f1631f21e4c, p_SourceEntityID := p_SourceEntityID_6f1631f21e4c, p_SourceFieldName := p_SourceFieldName_6f1631f21e4c, p_IsComputed := p_IsComputed_6f1631f21e4c, p_ComputationDescription := p_ComputationDescription_6f1631f21e4c, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_6f1631f21e4c, p_SummaryDescription := p_SummaryDescription_6f1631f21e4c, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_6f1631f21e4c, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_6f1631f21e4c, p_AutoDetectConfidenceScore_Clear := TRUE);
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_bf0eb9203dbd UUID;
  p_QueryID_bf0eb9203dbd UUID;
  p_Name_bf0eb9203dbd VARCHAR(255);
  p_Description_bf0eb9203dbd TEXT;
  p_Sequence_bf0eb9203dbd INTEGER;
  p_SQLBaseType_bf0eb9203dbd VARCHAR(50);
  p_SQLFullType_bf0eb9203dbd VARCHAR(100);
  p_SourceEntityID_bf0eb9203dbd UUID;
  p_SourceFieldName_bf0eb9203dbd VARCHAR(255);
  p_IsComputed_bf0eb9203dbd BOOLEAN;
  p_ComputationDescription_bf0eb9203dbd TEXT;
  p_IsSummary_bf0eb9203dbd BOOLEAN;
  p_SummaryDescription_bf0eb9203dbd TEXT;
  p_DetectionMethod_bf0eb9203dbd VARCHAR(50);
  p_AutoDetectConfidenceScore_bf0eb9203dbd NUMERIC(3,2);
BEGIN
  p_ID_bf0eb9203dbd := '9a99c114-5742-490c-af4c-1e7d6d321d0d';
  p_QueryID_bf0eb9203dbd := '90E212A2-5E1B-46DC-B468-38B6AF5E2352';
  p_Name_bf0eb9203dbd := 'Detail';
  p_Description_bf0eb9203dbd := 'WebsiteDomain (aliased as Detail)';
  p_Sequence_bf0eb9203dbd := 3;
  p_SQLBaseType_bf0eb9203dbd := 'nvarchar';
  p_SQLFullType_bf0eb9203dbd := 'nvarchar(255)';
  p_SourceEntityID_bf0eb9203dbd := 'C70448F9-9792-41D7-A82C-784B66429D54';
  p_SourceFieldName_bf0eb9203dbd := 'WebsiteDomain';
  p_IsComputed_bf0eb9203dbd := FALSE;
  p_IsSummary_bf0eb9203dbd := FALSE;
  p_DetectionMethod_bf0eb9203dbd := 'Manual';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_bf0eb9203dbd,
    'QueryID', p_QueryID_bf0eb9203dbd,
    'Name', p_Name_bf0eb9203dbd,
    'Description', p_Description_bf0eb9203dbd,
    'Sequence', p_Sequence_bf0eb9203dbd,
    'SQLBaseType', p_SQLBaseType_bf0eb9203dbd,
    'SQLFullType', p_SQLFullType_bf0eb9203dbd,
    'SourceEntityID', p_SourceEntityID_bf0eb9203dbd,
    'SourceFieldName', p_SourceFieldName_bf0eb9203dbd,
    'IsComputed', p_IsComputed_bf0eb9203dbd,
    'ComputationDescription', p_ComputationDescription_bf0eb9203dbd,
    'IsSummary', p_IsSummary_bf0eb9203dbd,
    'SummaryDescription', p_SummaryDescription_bf0eb9203dbd,
    'DetectionMethod', p_DetectionMethod_bf0eb9203dbd,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_bf0eb9203dbd
  ));
  ELSE
    PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_bf0eb9203dbd, p_QueryID := p_QueryID_bf0eb9203dbd, p_Name := p_Name_bf0eb9203dbd, p_Description := p_Description_bf0eb9203dbd, p_Sequence := p_Sequence_bf0eb9203dbd, p_SQLBaseType := p_SQLBaseType_bf0eb9203dbd, p_SQLFullType := p_SQLFullType_bf0eb9203dbd, p_SourceEntityID := p_SourceEntityID_bf0eb9203dbd, p_SourceFieldName := p_SourceFieldName_bf0eb9203dbd, p_IsComputed := p_IsComputed_bf0eb9203dbd, p_ComputationDescription := p_ComputationDescription_bf0eb9203dbd, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_bf0eb9203dbd, p_SummaryDescription := p_SummaryDescription_bf0eb9203dbd, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_bf0eb9203dbd, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_bf0eb9203dbd, p_AutoDetectConfidenceScore_Clear := TRUE);
  END IF;
END $mj$;

-- Save MJ: Query Entities (core SP call only)
DO $mj$
DECLARE
  p_ID_088104f55023 UUID;
  p_QueryID_088104f55023 UUID;
  p_EntityID_088104f55023 UUID;
  p_DetectionMethod_088104f55023 VARCHAR(50);
  p_AutoDetectConfidenceScore_088104f55023 NUMERIC(3,2);
BEGIN
  p_ID_088104f55023 := '340568b7-4543-4549-a26a-1dc7b092cc06';
  p_QueryID_088104f55023 := '90E212A2-5E1B-46DC-B468-38B6AF5E2352';
  p_EntityID_088104f55023 := 'C70448F9-9792-41D7-A82C-784B66429D54';
  p_DetectionMethod_088104f55023 := 'AI';
  p_AutoDetectConfidenceScore_088104f55023 := 1;
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryEntity'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spCreateQueryEntity"(p_data := jsonb_build_object(
    'ID', p_ID_088104f55023,
    'QueryID', p_QueryID_088104f55023,
    'EntityID', p_EntityID_088104f55023,
    'DetectionMethod', p_DetectionMethod_088104f55023,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_088104f55023
  ));
  ELSE
    PERFORM "${mjSchema}"."spCreateQueryEntity"(p_ID := p_ID_088104f55023, p_QueryID := p_QueryID_088104f55023, p_EntityID := p_EntityID_088104f55023, p_DetectionMethod := p_DetectionMethod_088104f55023, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_088104f55023);
  END IF;
END $mj$;

-- Save MJ: Queries (core SP call only)
DO $mj$
DECLARE
  p_ID_2f6f251be8b2 UUID;
  p_Name_2f6f251be8b2 VARCHAR(255);
  p_CategoryID_2f6f251be8b2 UUID;
  p_UserQuestion_2f6f251be8b2 TEXT;
  p_Description_2f6f251be8b2 TEXT;
  p_SQL_2f6f251be8b2 TEXT;
  p_TechnicalDescription_2f6f251be8b2 TEXT;
  p_OriginalSQL_2f6f251be8b2 TEXT;
  p_Feedback_2f6f251be8b2 TEXT;
  p_Status_2f6f251be8b2 VARCHAR(15);
  p_QualityRank_2f6f251be8b2 INTEGER;
  p_ExecutionCostRank_2f6f251be8b2 INTEGER;
  p_UsesTemplate_2f6f251be8b2 BOOLEAN;
  p_AuditQueryRuns_2f6f251be8b2 BOOLEAN;
  p_CacheEnabled_2f6f251be8b2 BOOLEAN;
  p_CacheTTLMinutes_2f6f251be8b2 INTEGER;
  p_CacheMaxSize_2f6f251be8b2 INTEGER;
  p_EmbeddingVector_2f6f251be8b2 TEXT;
  p_EmbeddingModelID_2f6f251be8b2 UUID;
  p_CacheValidationSQL_2f6f251be8b2 TEXT;
  p_SQLDialectID_2f6f251be8b2 UUID;
  p_Reusable_2f6f251be8b2 BOOLEAN;
  p_ExternalDataSourceID_2f6f251be8b2 UUID;
  p_IsMaterialized_2f6f251be8b2 BOOLEAN;
BEGIN
  p_ID_2f6f251be8b2 := '42438426-39E0-41A9-A40C-12BAE6487BFC';
  p_Name_2f6f251be8b2 := 'Common: Party Lookup People';
  p_CategoryID_2f6f251be8b2 := '6C0A1000-0000-4000-A000-000000000001';
  p_UserQuestion_2f6f251be8b2 := 'Which people match what the user is typing into a person picker?';
  p_Description_2f6f251be8b2 := 'Up to 20 people whose last name, display name or email starts with the typed term, or whose email domain starts with the typed domain. Backs bizapps-party-field.';
  p_SQL_2f6f251be8b2 := '-- Party lookup for People: prefix match on indexed base-table columns, TOP 20, no COUNT.
-- Contract shared by every party lookup query (bizapps-party-field): columns ID, Name, Detail;
-- parameters Term (required) and Domain (optional, already normalized by the picker).
-- sqlLikeBegins escapes the term and appends the trailing wildcard.
SELECT TOP 20
    p.ID,
    p.DisplayName AS Name,
    p.Email AS Detail
FROM [__mj_BizAppsCommon].[Person] p
WHERE p.LastName LIKE {{ Term | sqlLikeBegins }}
   OR p.DisplayName LIKE {{ Term | sqlLikeBegins }}
   OR p.Email LIKE {{ Term | sqlLikeBegins }}
{% if Domain %}   OR p.EmailDomain LIKE {{ Domain | sqlLikeBegins }}
{% endif %}ORDER BY p.DisplayName, p.ID
';
  p_TechnicalDescription_2f6f251be8b2 := 'Grain: one row per Person, TOP 20 ordered by DisplayName, ID. Base table __mj_BizAppsCommon.Person, prefix LIKE on indexed LastName, DisplayName, Email and EmailDomain; no view, no COUNT. Parameters: Term (required), Domain (optional, lower-cased, no leading @). Columns: ID, Name, Detail (Email).';
  p_Status_2f6f251be8b2 := 'Approved';
  p_QualityRank_2f6f251be8b2 := 9;
  p_ExecutionCostRank_2f6f251be8b2 := 1;
  p_UsesTemplate_2f6f251be8b2 := TRUE;
  p_AuditQueryRuns_2f6f251be8b2 := FALSE;
  p_CacheEnabled_2f6f251be8b2 := FALSE;
  p_EmbeddingVector_2f6f251be8b2 := '[0.023823779076337814,0.014636019244790077,0.02058834210038185,-0.0050925943069159985,-0.04406792297959328,-0.059762172400951385,0.04607084020972252,0.009526167064905167,0.02863265573978424,-0.0069257281720638275,0.02538793720304966,-0.034495435655117035,0.02557203359901905,0.012965764850378036,-0.016969479620456696,-0.054631881415843964,0.023395564407110214,0.011355618946254253,-0.014322685077786446,-0.005413329694420099,0.013760054484009743,-0.00023913627956062555,-0.015992552042007446,-0.010271781124174595,-0.021540261805057526,0.01794196479022503,-0.01230868510901928,-0.004502920899540186,0.05999891459941864,-0.01371446531265974,0.00827885139733553,-0.005993129685521126,-0.03174580633640289,-0.0255332812666893,0.000002241097945443471,-0.03557179123163223,-0.03508298471570015,0.00873332004994154,-0.019308989867568016,0.0032181707210838795,-0.015467486344277859,0.06307753175497055,-0.003609806066378951,-0.009391684085130692,0.008508240804076195,0.02953873947262764,-0.011619940400123596,0.06579463928937912,0.02262616902589798,0.01631677709519863,0.01817195490002632,-0.007400136906653643,-0.016385797411203384,0.01446540467441082,0.037239182740449905,-0.07781215012073517,0.04277421161532402,-0.06862671673297882,0.0638546571135521,-0.00539075443521142,0.059812579303979874,-0.0764712542295456,-0.04346494749188423,-0.044241707772016525,-0.04508957266807556,0.015696702525019646,-0.005017073359340429,-0.008905723690986633,0.012951567769050598,-0.0008590584038756788,0.046477869153022766,0.03324432671070099,-0.04324983432888985,-0.07578113675117493,-0.0025305133312940598,0.08246511220932007,0.03329920023679733,-0.041676294058561325,-0.03864787518978119,-0.004517330788075924,0.0032647757325321436,0.05305361747741699,-0.005817162338644266,0.009788084775209427,-0.029988983646035194,0.08693163096904755,0.003629229497164488,-0.00531550170853734,-0.0000863188979565166,-0.012611760757863522,0.02227116748690605,-0.006710832938551903,0.03921513259410858,0.010466796346008778,0.022186676040291786,-0.038952697068452835,-0.011651838198304176,-0.026455886662006378,0.028094589710235596,-0.00809619203209877,-0.02193143405020237,0.04574199020862579,-0.025908876210451126,-0.0065277800895273685,0.07147733867168427,-0.019430434331297874,0.009579792618751526,0.009008328430354595,0.012980022467672825,-0.08387654274702072,-0.0097360135987401,0.02741653472185135,-0.07021632045507431,-0.009717238135635853,-0.01739070564508438,0.030254030600190163,-0.03407325968146324,-0.0047901286743581295,-0.03685113042593002,-0.022020788863301277,0.045571472495794296,0.007827196270227432,0.04011883586645126,-0.0341058149933815,-0.07528311759233475,0.013004887849092484,-0.06991034001111984,-0.050174057483673096,0.00195889500901103,-0.00024722545640543103,0.03657149896025658,-0.031160933896899223,0.04985771328210831,-0.06999745965003967,0.017391588538885117,-0.02971879579126835,-0.0023021711967885494,-0.031489066779613495,0.03423655405640602,0.04042075201869011,0.029964523389935493,-0.0015180548653006554,-0.0066591426730155945,0.03304778411984444,-0.010634923353791237,-0.04116281121969223,0.008313557133078575,-0.10909567773342133,0.018095042556524277,0.021054964512586594,-0.035717565566301346,0.002712612971663475,-0.011302842758595943,-0.0011482308618724346,0.06389456987380981,-0.0009578795288689435,-0.04226086661219597,-0.030495652928948402,0.011388658545911312,-0.02170129306614399,0.008368749171495438,-0.01173549983650446,0.062127735465765,0.017597580328583717,-0.024775568395853043,-0.018570518121123314,0.027440208941698074,0.061615731567144394,0.020625827834010124,0.007314928807318211,0.020958323031663895,-0.004753506742417812,-0.02217171899974346,-0.05681445077061653,0.008439643308520317,0.05936717242002487,-0.004272333811968565,0.04014581814408302,-0.005137281026691198,-0.0062701646238565445,-0.0165866706520319,-0.02121286652982235,-0.0338180810213089,0.026044761762022972,-0.004418174736201763,-0.04518648982048035,0.06712270528078079,0.029725678265094757,-0.011837662197649479,0.05573344975709915,0.03759003430604935,-0.0009895386174321175,-0.00290667824447155,-0.009198238141834736,0.01452442817389965,-0.006444406695663929,-0.00764066819101572,-0.004830075893551111,0.0018403797876089811,0.007775829639285803,-0.05518512800335884,-0.04152071103453636,-0.028492018580436707,0.07715769857168198,0.016317948698997498,-0.013358807191252708,0.005548210348933935,0.02402951382100582,0.006755251437425613,-0.029870178550481796,0.03903841972351074,0.022773703560233116,0.03029840625822544,0.053566306829452515,-0.036756664514541626,0.12756790220737457,-0.005626058671623468,0.026626355946063995,0.06823553889989853,-0.04221519082784653,-0.0010149430017918348,0.05189600586891174,0.01753642037510872,0.0030111002270132303,-0.04510236158967018,0.05425981432199478,-0.005852802190929651,-0.0011563778389245272,-0.0016735538374632597,-0.028543582186102867,0.008795437403023243,-0.017214637249708176,0.015470500104129314,0.01269681565463543,0.07152744382619858,-0.06307316571474075,0.07037398964166641,0.0621294267475605,-0.025296658277511597,0.012920025736093521,-0.028565604239702225,-0.016155581921339035,0.005898738745599985,0.03649728745222092,0.023363422602415085,-0.010883909650146961,-0.02449931763112545,-0.00006724055128870532,-0.005515529774129391,-0.01641307957470417,-0.017579587176442146,0.005668258294463158,0.05858798325061798,0.0025366030167788267,-0.02493966743350029,-0.04508334770798683,0.014215908944606781,-0.011695017106831074,-0.10015388578176498,0.01755737140774727,-0.014533617533743382,-0.009420565329492092,0.005727836862206459,-0.003430378856137395,0.025597382336854935,0.011033907532691956,-0.03834864869713783,-0.015698373317718506,0.009304668754339218,0.026353374123573303,0.0005121685098856688,-0.06252863258123398,0.052263565361499786,0.009238001890480518,0.01699799671769142,0.032737262547016144,-0.021607808768749237,-0.029714025557041168,0.013327454216778278,0.014108636416494846,0.020030701532959938,-0.06868760287761688,-0.008261611685156822,0.029849639162421227,-0.01762988790869713,0.015556849539279938,0.032246608287096024,-0.07324597984552383,0.04247576743364334,-0.09786980599164963,0.00340487202629447,-0.013638807460665703,-0.010419255122542381,-0.006077127065509558,0.025227298960089684,0.011188477277755737,0.0016050082631409168,0.05160292983055115,0.014131063595414162,-0.006016612984240055,-0.0697915256023407,0.05947786197066307,-0.05248923599720001,0.006743856240063906,-0.0030722275841981173,0.010939253494143486,0.0365559346973896,0.00001546872954349965,0.002134463284164667,0.101532481610775,-0.05320274829864502,0.005288755986839533,0.009618204087018967,0.01641230285167694,0.05985141918063164,0.015522104687988758,0.03794829547405243,-0.01877964474260807,-0.04110395163297653,0.011302563361823559,0.024445470422506332,0.030102241784334183,0.04971656575798988,-0.014360375702381134,0.007933580316603184,0.04198070243000984,-0.006061011925339699,0.03023618832230568,-0.004051005933433771,0.05137142166495323,0.007383659482002258,0.0378684438765049,-0.011581981554627419,0.02456226758658886,-0.010668067261576653,-0.03757043555378914,-0.016560504212975502,0.08410518616437912,-0.00359691702760756,0.03179117292165756,0.012748351320624352,-0.04447934031486511,-0.03907473012804985,-0.06353415548801422,-0.04902460053563118,0.01910577528178692,-0.04660442844033241,-0.035130005329847336,-0.03426196426153183,-0.014818254858255386,0.017910083755850792,-0.0026364277582615614,-0.027200141921639442,-0.016952022910118103,-0.00204991246573627,-0.062084417790174484,-0.030605530366301537,0.06340435147285461,-0.020164478570222855,0.0022637771908193827,-0.11501621454954147,-0.04763946682214737,0.07376355677843094,-0.01375941839069128,-0.01286298781633377,-0.013701326213777065,-0.002270087832584977,-0.03541417419910431,-0.06373912841081619,-0.00846345815807581,-0.007156233303248882,-0.0028947151731699705,0.042722899466753006,0.036574870347976685,-0.016840318217873573,-0.01503595057874918,-0.030004223808646202,-0.025890620425343513,-0.008839788846671581,0.011214999482035637,0.07990992814302444,-0.05292464792728424,-0.03614012897014618,-0.007104851771146059,-0.00968406442552805,-0.0312176626175642,-0.03713793307542801,-0.028736263513565063,-0.09552166610956192,-0.044721685349941254,-0.023447994142770767,0.06761589646339417,0.01264176145195961,-0.017738256603479385,0.02809453383088112,-0.023026850074529648,-0.035953156650066376,-0.00554346339777112,-0.02989586815237999,-0.028905600309371948,0.003100272035226226,0.02573005110025406,0.014866759069263935,0.03918423876166344,-0.06538400799036026,0.0350620336830616,0.03563074395060539,0.0659383088350296,0.026427993550896645,-0.01692516729235649,-0.0061872838996350765,-0.04738074168562889,0.004274304490536451,0.007355378475040197,0.006909821182489395,-0.05810202285647392,0.03548646345734596,-0.003990401979535818,-0.025745101273059845,0.06490053981542587,-0.015545974485576153,0.0009166793897747993,0.034563932567834854,-0.010867882519960403,0.01026518177241087,-0.005873828195035458,0.07182495296001434,-0.005175543017685413,0.049401309341192245,0.018335536122322083,-0.02616763673722744,0.042931824922561646,-0.045524466782808304,0.03186539560556412,0.004278622567653656,-0.006846641190350056,0.006715000607073307,-0.05740264430642128,0.042010195553302765,0.019417431205511093,0.013324754312634468,0.05550990626215935,0.0120315533131361,0.00504023302346468,0.02230430580675602,0.002282507484778762,0.04196880757808685,0.0539529025554657,0.02265249751508236,-0.03197924792766571,0.025595510378479958,-0.03296595439314842,-0.07720207422971725,0.006766532547771931,0.015529504977166653,-0.043708834797143936,-0.04633324220776558,0.08450259268283844,-0.011096182279288769,0.05152658000588417,-0.021757932379841805,0.0290825255215168,-0.004829456564038992,-0.01696815900504589,-0.08001112192869186,-0.0639662891626358,-0.007631319109350443,0.033669613301754,0.010671878233551979,-0.033669035881757736,-0.003537758020684123,0.03180772438645363,0.004722894635051489,0.001665799063630402,0.05378087982535362,-0.0032958893571048975,-0.05250472575426102,-0.07777119427919388,-0.06047176569700241,-0.002943405881524086,0.020336400717496872,0.009234732016921043,0.008488013409078121,-0.04174308851361275,0.023380879312753677,-0.013355813920497894,-0.012511026114225388,0.016310814768075943,-0.023644838482141495,-0.059132806956768036,-0.0360557846724987,-0.04468150436878204,0.006157536990940571,-0.01101367175579071,-0.040797412395477295,0.09595762938261032,0.012550471350550652,-0.018704045563936234,-0.026536788791418076,0.008748994208872318,-0.028633296489715576,0.009240971878170967,0.0013389374362304807,-0.03230644762516022,-0.03097156248986721,0.06474504619836807,0.01692906953394413,-0.03288308158516884,-0.008849221281707287,-0.018431684002280235,-0.020727932453155518,-0.04681408405303955,-0.06834248453378677,0.01663900353014469,0.008586544543504715,0.0939812958240509,-0.06606150418519974,0.05132696032524109,-0.013894547708332539,0.028817707672715187,0.010451656766235828,0.0016893796855583787,0.011184078641235828,0.00636383006349206,-0.02861524000763893,-0.03691072762012482,0.03419690206646919,0.015530480071902275,-0.030768591910600662,0.022394822910428047,0.11725284904241562,-0.023442549630999565,-0.0066270772367715836,0.040896523743867874,0.031433481723070145,0.0021747213322669268,0.004464669153094292,-0.019865309819579124,-0.018224013969302177,0.015767110511660576,-0.03379315137863159,0.05240098387002945,0.0024150959216058254,-0.015145647339522839,-0.019145427271723747,0.008044552989304066,-0.012094704434275627,-0.0345117412507534,-0.03864414989948273,0.0030407404992729425,0.010904326103627682,0.01299955416470766,-0.007605460472404957,-0.019165359437465668,0.036816369742155075,-6.93170063833496e-33,-0.10551383346319199,-0.027179110795259476,0.025523368269205093,-0.01997225172817707,-0.04754844680428505,-0.035562459379434586,-0.017621254548430443,-0.011264120228588581,-0.0302271731197834,0.04258463904261589,-0.05933118239045143,-0.01203080266714096,0.021059133112430573,-0.004014729056507349,0.005855693481862545,-0.03545956313610077,-0.0027148877270519733,0.0011777596082538366,0.03249166160821915,0.007003470323979855,0.026369741186499596,0.03591533377766609,0.009337805211544037,0.007226852234452963,-0.02210012450814247,0.00877151545137167,-0.005335240624845028,0.03689439967274666,0.04352481663227081,0.014759963378310204,0.02343527413904667,-0.09138613939285278,0.0004400869947858155,0.02698369324207306,0.04009038954973221,0.03548971191048622,-0.05812865495681763,-0.016037248075008392,-0.07386338710784912,0.0049753617495298386,0.09374182671308517,-0.013906008563935757,0.00029015782638452947,-0.02167617529630661,-0.023591771721839905,0.00643115071579814,0.05162327364087105,-0.013368059881031513,-0.05648423731327057,0.06464360654354095,0.03151936084032059,-0.02267197147011757,0.02421434223651886,0.027792610228061676,-0.0026968619786202908,0.03764813765883446,0.02026359550654888,-0.021055905148386955,-0.029055587947368622,-0.04478521645069122,-0.006437537260353565,-0.005320331081748009,-0.059803567826747894,-0.009454520419239998,0.015557651408016682,0.03988829255104065,-0.007845263928174973,-0.026321686804294586,-0.05671903118491173,-0.11146534234285355,-0.06813101470470428,0.06129589304327965,-0.04015979543328285,0.06992020457983017,0.09790581464767456,-0.030110575258731842,0.006005159579217434,0.036283645778894424,0.059532977640628815,-0.047777701169252396,0.04909079149365425,-0.025233576074242592,-0.02842075191438198,-0.01663004420697689,0.03015090525150299,0.021401146426796913,0.003103800117969513,-0.020687129348516464,-0.028210144490003586,-0.008291713893413544,-0.0680309608578682,0.038608916103839874,-0.004727405495941639,-0.05352802202105522,-0.03882449492812157,-0.02570319175720215,0.023533908650279045,-0.0006668916321359575,0.004046372603625059,-0.01978108286857605,0.007394788786768913,-0.0232692938297987,-0.022221341729164124,-0.014446089044213295,0.05431908369064331,0.0048110950738191605,0.018067585304379463,-0.031214382499456406,-0.024689961224794388,-0.01219386700540781,-0.0034662457183003426,0.010125430300831795,-0.04170842096209526,0.059867456555366516,0.024029972031712532,0.04655001685023308,0.009509261697530746,-0.02954998053610325,0.023286154493689537,-0.0010385987116023898,0.03034692443907261,0.027919510379433632,0.01856781542301178,0.006025269627571106,-0.01865868829190731,0.012022086419165134,-0.038544993847608566,-0.06861820816993713,0.01404651254415512,-0.011632549576461315,-0.0077142552472651005,-0.026512393727898598,3.0445318088823115e-7,0.0006411026115529239,0.00989033654332161,-0.0177165474742651,0.05139274150133133,0.011624177917838097,0.014824525453150272,0.05508171021938324,0.05425596237182617,0.017005883157253265,-0.05786243826150894,-0.0166100412607193,-0.02140185236930847,0.048188138753175735,0.046986453235149384,-0.05821213126182556,-0.016064856201410294,0.008199455216526985,-0.003843206912279129,-0.001486551365815103,0.03197117894887924,-0.018937163054943085,-0.013205875642597675,0.058699991554021835,-0.01319261733442545,0.002458670875057578,-0.008705362677574158,0.01738346368074417,-0.022811759263277054,-0.03095170669257641,0.05294094234704971,0.013339716009795666,-0.08553843945264816,0.023769451305270195,0.0807940661907196,0.010568448342382908,0.05825003981590271,0.006446912884712219,0.00031850169762037694,-0.01624373160302639,-0.014206700958311558,0.01665932685136795,-0.07630235701799393,0.0015135358553379774,0.028081633150577545,0.03687434270977974,-0.026677578687667847,0.03374263271689415,0.02706877700984478,-0.028535690158605576,-0.09065492451190948,0.014268270693719387,-0.007367027923464775,0.03787045180797577,-0.011118131689727306,0.050816744565963745,-0.06321346014738083,-0.007788177113980055,0.03316441923379898,0.020686322823166847,-0.07261372357606888,0.005960423499345779,-0.014777563512325287,0.009179296903312206,-0.04695461690425873,0.06740641593933105,0.028375165536999702,-0.03537048026919365,2.8911517738989364e-34,-0.008757397532463074,0.02630358561873436,-0.013414638116955757,0.009944724850356579,0.04588090628385544,0.01974440924823284,0.04860936477780342,-0.013437808491289616,0.022596418857574463,0.042773425579071045,0.0250132717192173]';
  p_EmbeddingModelID_2f6f251be8b2 := '1D45AA65-41EC-4572-9ECD-AB2826C9B059';
  p_Reusable_2f6f251be8b2 := TRUE;
  p_IsMaterialized_2f6f251be8b2 := FALSE;
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQuery'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spCreateQuery"(p_data := jsonb_build_object(
    'ID', p_ID_2f6f251be8b2,
    'Name', p_Name_2f6f251be8b2,
    'CategoryID', p_CategoryID_2f6f251be8b2,
    'UserQuestion', p_UserQuestion_2f6f251be8b2,
    'Description', p_Description_2f6f251be8b2,
    'SQL', p_SQL_2f6f251be8b2,
    'TechnicalDescription', p_TechnicalDescription_2f6f251be8b2,
    'OriginalSQL', p_OriginalSQL_2f6f251be8b2,
    'Feedback', p_Feedback_2f6f251be8b2,
    'Status', p_Status_2f6f251be8b2,
    'QualityRank', p_QualityRank_2f6f251be8b2,
    'ExecutionCostRank', p_ExecutionCostRank_2f6f251be8b2,
    'UsesTemplate', p_UsesTemplate_2f6f251be8b2,
    'AuditQueryRuns', p_AuditQueryRuns_2f6f251be8b2,
    'CacheEnabled', p_CacheEnabled_2f6f251be8b2,
    'CacheTTLMinutes', p_CacheTTLMinutes_2f6f251be8b2,
    'CacheMaxSize', p_CacheMaxSize_2f6f251be8b2,
    'EmbeddingVector', p_EmbeddingVector_2f6f251be8b2,
    'EmbeddingModelID', p_EmbeddingModelID_2f6f251be8b2,
    'CacheValidationSQL', p_CacheValidationSQL_2f6f251be8b2,
    'SQLDialectID', p_SQLDialectID_2f6f251be8b2,
    'Reusable', p_Reusable_2f6f251be8b2,
    'ExternalDataSourceID', p_ExternalDataSourceID_2f6f251be8b2,
    'IsMaterialized', p_IsMaterialized_2f6f251be8b2
  ));
  ELSE
    PERFORM "${mjSchema}"."spCreateQuery"(p_ID := p_ID_2f6f251be8b2, p_Name := p_Name_2f6f251be8b2, p_CategoryID := p_CategoryID_2f6f251be8b2, p_UserQuestion := p_UserQuestion_2f6f251be8b2, p_Description := p_Description_2f6f251be8b2, p_SQL := p_SQL_2f6f251be8b2, p_TechnicalDescription := p_TechnicalDescription_2f6f251be8b2, p_OriginalSQL := p_OriginalSQL_2f6f251be8b2, p_OriginalSQL_Clear := TRUE, p_Feedback := p_Feedback_2f6f251be8b2, p_Feedback_Clear := TRUE, p_Status := p_Status_2f6f251be8b2, p_QualityRank := p_QualityRank_2f6f251be8b2, p_ExecutionCostRank := p_ExecutionCostRank_2f6f251be8b2, p_UsesTemplate := p_UsesTemplate_2f6f251be8b2, p_AuditQueryRuns := p_AuditQueryRuns_2f6f251be8b2, p_CacheEnabled := p_CacheEnabled_2f6f251be8b2, p_CacheTTLMinutes := p_CacheTTLMinutes_2f6f251be8b2, p_CacheTTLMinutes_Clear := TRUE, p_CacheMaxSize := p_CacheMaxSize_2f6f251be8b2, p_CacheMaxSize_Clear := TRUE, p_EmbeddingVector := p_EmbeddingVector_2f6f251be8b2, p_EmbeddingModelID := p_EmbeddingModelID_2f6f251be8b2, p_CacheValidationSQL := p_CacheValidationSQL_2f6f251be8b2, p_CacheValidationSQL_Clear := TRUE, p_SQLDialectID := p_SQLDialectID_2f6f251be8b2, p_Reusable := p_Reusable_2f6f251be8b2, p_ExternalDataSourceID := p_ExternalDataSourceID_2f6f251be8b2, p_ExternalDataSourceID_Clear := TRUE, p_IsMaterialized := p_IsMaterialized_2f6f251be8b2);
  END IF;
END $mj$;

-- Save MJ: Query Parameters (core SP call only)
DO $mj$
DECLARE
  p_ID_772bf589e980 UUID;
  p_QueryID_772bf589e980 UUID;
  p_Name_772bf589e980 VARCHAR(255);
  p_Type_772bf589e980 VARCHAR(50);
  p_IsRequired_772bf589e980 BOOLEAN;
  p_DefaultValue_772bf589e980 TEXT;
  p_Description_772bf589e980 TEXT;
  p_SampleValue_772bf589e980 TEXT;
  p_ValidationFilters_772bf589e980 TEXT;
  p_DetectionMethod_772bf589e980 VARCHAR(50);
  p_AutoDetectConfidenceScore_772bf589e980 NUMERIC(3,2);
BEGIN
  p_ID_772bf589e980 := 'fc650cc8-936d-43e1-b2f0-a1fce5d9c11a';
  p_QueryID_772bf589e980 := '42438426-39E0-41A9-A40C-12BAE6487BFC';
  p_Name_772bf589e980 := 'Term';
  p_Type_772bf589e980 := 'string';
  p_IsRequired_772bf589e980 := TRUE;
  p_Description_772bf589e980 := 'Required value for Term';
  p_DetectionMethod_772bf589e980 := 'AI';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryParameter'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spCreateQueryParameter"(p_data := jsonb_build_object(
    'ID', p_ID_772bf589e980,
    'QueryID', p_QueryID_772bf589e980,
    'Name', p_Name_772bf589e980,
    'Type', p_Type_772bf589e980,
    'IsRequired', p_IsRequired_772bf589e980,
    'DefaultValue', p_DefaultValue_772bf589e980,
    'Description', p_Description_772bf589e980,
    'SampleValue', p_SampleValue_772bf589e980,
    'ValidationFilters', p_ValidationFilters_772bf589e980,
    'DetectionMethod', p_DetectionMethod_772bf589e980,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_772bf589e980
  ));
  ELSE
    PERFORM "${mjSchema}"."spCreateQueryParameter"(p_ID := p_ID_772bf589e980, p_QueryID := p_QueryID_772bf589e980, p_Name := p_Name_772bf589e980, p_Type := p_Type_772bf589e980, p_IsRequired := p_IsRequired_772bf589e980, p_DefaultValue := p_DefaultValue_772bf589e980, p_DefaultValue_Clear := TRUE, p_Description := p_Description_772bf589e980, p_SampleValue := p_SampleValue_772bf589e980, p_SampleValue_Clear := TRUE, p_ValidationFilters := p_ValidationFilters_772bf589e980, p_ValidationFilters_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_772bf589e980, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_772bf589e980, p_AutoDetectConfidenceScore_Clear := TRUE);
  END IF;
END $mj$;

-- Save MJ: Query Parameters (core SP call only)
DO $mj$
DECLARE
  p_ID_5cb9f7929a75 UUID;
  p_QueryID_5cb9f7929a75 UUID;
  p_Name_5cb9f7929a75 VARCHAR(255);
  p_Type_5cb9f7929a75 VARCHAR(50);
  p_IsRequired_5cb9f7929a75 BOOLEAN;
  p_DefaultValue_5cb9f7929a75 TEXT;
  p_Description_5cb9f7929a75 TEXT;
  p_SampleValue_5cb9f7929a75 TEXT;
  p_ValidationFilters_5cb9f7929a75 TEXT;
  p_DetectionMethod_5cb9f7929a75 VARCHAR(50);
  p_AutoDetectConfidenceScore_5cb9f7929a75 NUMERIC(3,2);
BEGIN
  p_ID_5cb9f7929a75 := 'f9fadda5-bf0a-479a-a66d-f55450eb92d6';
  p_QueryID_5cb9f7929a75 := '42438426-39E0-41A9-A40C-12BAE6487BFC';
  p_Name_5cb9f7929a75 := 'Domain';
  p_Type_5cb9f7929a75 := 'string';
  p_IsRequired_5cb9f7929a75 := FALSE;
  p_Description_5cb9f7929a75 := 'Optional value for Domain';
  p_DetectionMethod_5cb9f7929a75 := 'AI';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryParameter'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spCreateQueryParameter"(p_data := jsonb_build_object(
    'ID', p_ID_5cb9f7929a75,
    'QueryID', p_QueryID_5cb9f7929a75,
    'Name', p_Name_5cb9f7929a75,
    'Type', p_Type_5cb9f7929a75,
    'IsRequired', p_IsRequired_5cb9f7929a75,
    'DefaultValue', p_DefaultValue_5cb9f7929a75,
    'Description', p_Description_5cb9f7929a75,
    'SampleValue', p_SampleValue_5cb9f7929a75,
    'ValidationFilters', p_ValidationFilters_5cb9f7929a75,
    'DetectionMethod', p_DetectionMethod_5cb9f7929a75,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_5cb9f7929a75
  ));
  ELSE
    PERFORM "${mjSchema}"."spCreateQueryParameter"(p_ID := p_ID_5cb9f7929a75, p_QueryID := p_QueryID_5cb9f7929a75, p_Name := p_Name_5cb9f7929a75, p_Type := p_Type_5cb9f7929a75, p_IsRequired := p_IsRequired_5cb9f7929a75, p_DefaultValue := p_DefaultValue_5cb9f7929a75, p_DefaultValue_Clear := TRUE, p_Description := p_Description_5cb9f7929a75, p_SampleValue := p_SampleValue_5cb9f7929a75, p_SampleValue_Clear := TRUE, p_ValidationFilters := p_ValidationFilters_5cb9f7929a75, p_ValidationFilters_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_5cb9f7929a75, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_5cb9f7929a75, p_AutoDetectConfidenceScore_Clear := TRUE);
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_7e6b6ac93ad0 UUID;
  p_QueryID_7e6b6ac93ad0 UUID;
  p_Name_7e6b6ac93ad0 VARCHAR(255);
  p_Description_7e6b6ac93ad0 TEXT;
  p_Sequence_7e6b6ac93ad0 INTEGER;
  p_SQLBaseType_7e6b6ac93ad0 VARCHAR(50);
  p_SQLFullType_7e6b6ac93ad0 VARCHAR(100);
  p_SourceEntityID_7e6b6ac93ad0 UUID;
  p_SourceFieldName_7e6b6ac93ad0 VARCHAR(255);
  p_IsComputed_7e6b6ac93ad0 BOOLEAN;
  p_ComputationDescription_7e6b6ac93ad0 TEXT;
  p_IsSummary_7e6b6ac93ad0 BOOLEAN;
  p_SummaryDescription_7e6b6ac93ad0 TEXT;
  p_DetectionMethod_7e6b6ac93ad0 VARCHAR(50);
  p_AutoDetectConfidenceScore_7e6b6ac93ad0 NUMERIC(3,2);
BEGIN
  p_ID_7e6b6ac93ad0 := '7bda5896-ccea-4cc0-9658-fbf7c024b70b';
  p_QueryID_7e6b6ac93ad0 := '42438426-39E0-41A9-A40C-12BAE6487BFC';
  p_Name_7e6b6ac93ad0 := 'ID';
  p_Description_7e6b6ac93ad0 := 'ID';
  p_Sequence_7e6b6ac93ad0 := 1;
  p_SQLBaseType_7e6b6ac93ad0 := 'uniqueidentifier';
  p_SQLFullType_7e6b6ac93ad0 := 'uniqueidentifier';
  p_SourceEntityID_7e6b6ac93ad0 := '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F';
  p_SourceFieldName_7e6b6ac93ad0 := 'ID';
  p_IsComputed_7e6b6ac93ad0 := FALSE;
  p_IsSummary_7e6b6ac93ad0 := FALSE;
  p_DetectionMethod_7e6b6ac93ad0 := 'Manual';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_7e6b6ac93ad0,
    'QueryID', p_QueryID_7e6b6ac93ad0,
    'Name', p_Name_7e6b6ac93ad0,
    'Description', p_Description_7e6b6ac93ad0,
    'Sequence', p_Sequence_7e6b6ac93ad0,
    'SQLBaseType', p_SQLBaseType_7e6b6ac93ad0,
    'SQLFullType', p_SQLFullType_7e6b6ac93ad0,
    'SourceEntityID', p_SourceEntityID_7e6b6ac93ad0,
    'SourceFieldName', p_SourceFieldName_7e6b6ac93ad0,
    'IsComputed', p_IsComputed_7e6b6ac93ad0,
    'ComputationDescription', p_ComputationDescription_7e6b6ac93ad0,
    'IsSummary', p_IsSummary_7e6b6ac93ad0,
    'SummaryDescription', p_SummaryDescription_7e6b6ac93ad0,
    'DetectionMethod', p_DetectionMethod_7e6b6ac93ad0,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_7e6b6ac93ad0
  ));
  ELSE
    PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_7e6b6ac93ad0, p_QueryID := p_QueryID_7e6b6ac93ad0, p_Name := p_Name_7e6b6ac93ad0, p_Description := p_Description_7e6b6ac93ad0, p_Sequence := p_Sequence_7e6b6ac93ad0, p_SQLBaseType := p_SQLBaseType_7e6b6ac93ad0, p_SQLFullType := p_SQLFullType_7e6b6ac93ad0, p_SourceEntityID := p_SourceEntityID_7e6b6ac93ad0, p_SourceFieldName := p_SourceFieldName_7e6b6ac93ad0, p_IsComputed := p_IsComputed_7e6b6ac93ad0, p_ComputationDescription := p_ComputationDescription_7e6b6ac93ad0, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_7e6b6ac93ad0, p_SummaryDescription := p_SummaryDescription_7e6b6ac93ad0, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_7e6b6ac93ad0, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_7e6b6ac93ad0, p_AutoDetectConfidenceScore_Clear := TRUE);
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_4527f9461e8c UUID;
  p_QueryID_4527f9461e8c UUID;
  p_Name_4527f9461e8c VARCHAR(255);
  p_Description_4527f9461e8c TEXT;
  p_Sequence_4527f9461e8c INTEGER;
  p_SQLBaseType_4527f9461e8c VARCHAR(50);
  p_SQLFullType_4527f9461e8c VARCHAR(100);
  p_SourceEntityID_4527f9461e8c UUID;
  p_SourceFieldName_4527f9461e8c VARCHAR(255);
  p_IsComputed_4527f9461e8c BOOLEAN;
  p_ComputationDescription_4527f9461e8c TEXT;
  p_IsSummary_4527f9461e8c BOOLEAN;
  p_SummaryDescription_4527f9461e8c TEXT;
  p_DetectionMethod_4527f9461e8c VARCHAR(50);
  p_AutoDetectConfidenceScore_4527f9461e8c NUMERIC(3,2);
BEGIN
  p_ID_4527f9461e8c := '9ff88d85-e3cc-49ba-8fdf-ea8692198415';
  p_QueryID_4527f9461e8c := '42438426-39E0-41A9-A40C-12BAE6487BFC';
  p_Name_4527f9461e8c := 'Name';
  p_Description_4527f9461e8c := 'DisplayName (aliased as Name)';
  p_Sequence_4527f9461e8c := 2;
  p_SQLBaseType_4527f9461e8c := 'nvarchar';
  p_SQLFullType_4527f9461e8c := 'nvarchar(250)';
  p_SourceEntityID_4527f9461e8c := '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F';
  p_SourceFieldName_4527f9461e8c := 'DisplayName';
  p_IsComputed_4527f9461e8c := FALSE;
  p_IsSummary_4527f9461e8c := FALSE;
  p_DetectionMethod_4527f9461e8c := 'Manual';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_4527f9461e8c,
    'QueryID', p_QueryID_4527f9461e8c,
    'Name', p_Name_4527f9461e8c,
    'Description', p_Description_4527f9461e8c,
    'Sequence', p_Sequence_4527f9461e8c,
    'SQLBaseType', p_SQLBaseType_4527f9461e8c,
    'SQLFullType', p_SQLFullType_4527f9461e8c,
    'SourceEntityID', p_SourceEntityID_4527f9461e8c,
    'SourceFieldName', p_SourceFieldName_4527f9461e8c,
    'IsComputed', p_IsComputed_4527f9461e8c,
    'ComputationDescription', p_ComputationDescription_4527f9461e8c,
    'IsSummary', p_IsSummary_4527f9461e8c,
    'SummaryDescription', p_SummaryDescription_4527f9461e8c,
    'DetectionMethod', p_DetectionMethod_4527f9461e8c,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_4527f9461e8c
  ));
  ELSE
    PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_4527f9461e8c, p_QueryID := p_QueryID_4527f9461e8c, p_Name := p_Name_4527f9461e8c, p_Description := p_Description_4527f9461e8c, p_Sequence := p_Sequence_4527f9461e8c, p_SQLBaseType := p_SQLBaseType_4527f9461e8c, p_SQLFullType := p_SQLFullType_4527f9461e8c, p_SourceEntityID := p_SourceEntityID_4527f9461e8c, p_SourceFieldName := p_SourceFieldName_4527f9461e8c, p_IsComputed := p_IsComputed_4527f9461e8c, p_ComputationDescription := p_ComputationDescription_4527f9461e8c, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_4527f9461e8c, p_SummaryDescription := p_SummaryDescription_4527f9461e8c, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_4527f9461e8c, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_4527f9461e8c, p_AutoDetectConfidenceScore_Clear := TRUE);
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_42df43331db7 UUID;
  p_QueryID_42df43331db7 UUID;
  p_Name_42df43331db7 VARCHAR(255);
  p_Description_42df43331db7 TEXT;
  p_Sequence_42df43331db7 INTEGER;
  p_SQLBaseType_42df43331db7 VARCHAR(50);
  p_SQLFullType_42df43331db7 VARCHAR(100);
  p_SourceEntityID_42df43331db7 UUID;
  p_SourceFieldName_42df43331db7 VARCHAR(255);
  p_IsComputed_42df43331db7 BOOLEAN;
  p_ComputationDescription_42df43331db7 TEXT;
  p_IsSummary_42df43331db7 BOOLEAN;
  p_SummaryDescription_42df43331db7 TEXT;
  p_DetectionMethod_42df43331db7 VARCHAR(50);
  p_AutoDetectConfidenceScore_42df43331db7 NUMERIC(3,2);
BEGIN
  p_ID_42df43331db7 := 'a9b4fdaf-a770-4cd8-aa53-c34bf4e62b31';
  p_QueryID_42df43331db7 := '42438426-39E0-41A9-A40C-12BAE6487BFC';
  p_Name_42df43331db7 := 'Detail';
  p_Description_42df43331db7 := 'Email (aliased as Detail)';
  p_Sequence_42df43331db7 := 3;
  p_SQLBaseType_42df43331db7 := 'nvarchar';
  p_SQLFullType_42df43331db7 := 'nvarchar(255)';
  p_SourceEntityID_42df43331db7 := '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F';
  p_SourceFieldName_42df43331db7 := 'Email';
  p_IsComputed_42df43331db7 := FALSE;
  p_IsSummary_42df43331db7 := FALSE;
  p_DetectionMethod_42df43331db7 := 'Manual';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_42df43331db7,
    'QueryID', p_QueryID_42df43331db7,
    'Name', p_Name_42df43331db7,
    'Description', p_Description_42df43331db7,
    'Sequence', p_Sequence_42df43331db7,
    'SQLBaseType', p_SQLBaseType_42df43331db7,
    'SQLFullType', p_SQLFullType_42df43331db7,
    'SourceEntityID', p_SourceEntityID_42df43331db7,
    'SourceFieldName', p_SourceFieldName_42df43331db7,
    'IsComputed', p_IsComputed_42df43331db7,
    'ComputationDescription', p_ComputationDescription_42df43331db7,
    'IsSummary', p_IsSummary_42df43331db7,
    'SummaryDescription', p_SummaryDescription_42df43331db7,
    'DetectionMethod', p_DetectionMethod_42df43331db7,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_42df43331db7
  ));
  ELSE
    PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_42df43331db7, p_QueryID := p_QueryID_42df43331db7, p_Name := p_Name_42df43331db7, p_Description := p_Description_42df43331db7, p_Sequence := p_Sequence_42df43331db7, p_SQLBaseType := p_SQLBaseType_42df43331db7, p_SQLFullType := p_SQLFullType_42df43331db7, p_SourceEntityID := p_SourceEntityID_42df43331db7, p_SourceFieldName := p_SourceFieldName_42df43331db7, p_IsComputed := p_IsComputed_42df43331db7, p_ComputationDescription := p_ComputationDescription_42df43331db7, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_42df43331db7, p_SummaryDescription := p_SummaryDescription_42df43331db7, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_42df43331db7, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_42df43331db7, p_AutoDetectConfidenceScore_Clear := TRUE);
  END IF;
END $mj$;

-- Save MJ: Query Entities (core SP call only)
DO $mj$
DECLARE
  p_ID_8b24b92c6605 UUID;
  p_QueryID_8b24b92c6605 UUID;
  p_EntityID_8b24b92c6605 UUID;
  p_DetectionMethod_8b24b92c6605 VARCHAR(50);
  p_AutoDetectConfidenceScore_8b24b92c6605 NUMERIC(3,2);
BEGIN
  p_ID_8b24b92c6605 := 'cd0c10ae-1062-4ede-a960-133449047651';
  p_QueryID_8b24b92c6605 := '42438426-39E0-41A9-A40C-12BAE6487BFC';
  p_EntityID_8b24b92c6605 := '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F';
  p_DetectionMethod_8b24b92c6605 := 'AI';
  p_AutoDetectConfidenceScore_8b24b92c6605 := 1;
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryEntity'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spCreateQueryEntity"(p_data := jsonb_build_object(
    'ID', p_ID_8b24b92c6605,
    'QueryID', p_QueryID_8b24b92c6605,
    'EntityID', p_EntityID_8b24b92c6605,
    'DetectionMethod', p_DetectionMethod_8b24b92c6605,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_8b24b92c6605
  ));
  ELSE
    PERFORM "${mjSchema}"."spCreateQueryEntity"(p_ID := p_ID_8b24b92c6605, p_QueryID := p_QueryID_8b24b92c6605, p_EntityID := p_EntityID_8b24b92c6605, p_DetectionMethod := p_DetectionMethod_8b24b92c6605, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_8b24b92c6605);
  END IF;
END $mj$;
