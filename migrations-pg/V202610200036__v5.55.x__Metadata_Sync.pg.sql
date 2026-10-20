-- =============================================================================================
-- PostgreSQL counterpart of V202610200036__v5.55.x__Metadata_Sync.sql -- BizApps Common v5.55.x Metadata_Sync
-- =============================================================================================
-- Same record, same values as the T-SQL file; see its header for what ships and why.
--
-- HOW IT WAS MADE
--   * `mj sql-convert --from tsql --to postgres` (MJ CLI 6.1.6) on the push log the T-SQL file
--     was generated from, held-back records removed as in the T-SQL file. The record is a DO
--     block that calls the core spUpdateEntityField function, in whichever signature the host has
--     (jsonb or named parameters).
--   * The T-SQL file has no lookups or guards: the record is an update by pinned ID.
--   * Every string value matches the T-SQL file.
--   * Schema names use the same placeholder as the T-SQL file.
-- =============================================================================================

SET standard_conforming_strings = on;
-- Save MJ: Entity Fields (core SP call only)
DO $mj$
DECLARE
  p_DisplayName_165f869f382f VARCHAR(255);
  p_Description_165f869f382f TEXT;
  p_AutoUpdateDescription_165f869f382f BOOLEAN;
  p_IsPrimaryKey_165f869f382f BOOLEAN;
  p_IsUnique_165f869f382f BOOLEAN;
  p_Category_165f869f382f VARCHAR(255);
  p_ValueListType_165f869f382f VARCHAR(20);
  p_ExtendedType_165f869f382f VARCHAR(50);
  p_CodeType_165f869f382f VARCHAR(50);
  p_DefaultInView_165f869f382f BOOLEAN;
  p_ViewCellTemplate_165f869f382f TEXT;
  p_DefaultColumnWidth_165f869f382f INTEGER;
  p_AllowUpdateAPI_165f869f382f BOOLEAN;
  p_AllowUpdateInView_165f869f382f BOOLEAN;
  p_IncludeInUserSearchAPI_165f869f382f BOOLEAN;
  p_FullTextSearchEnabled_165f869f382f BOOLEAN;
  p_UserSearchParamFormatAPI_165f869f382f VARCHAR(500);
  p_IncludeInGeneratedForm_165f869f382f BOOLEAN;
  p_GeneratedFormSection_165f869f382f VARCHAR(10);
  p_IsNameField_165f869f382f BOOLEAN;
  p_RelatedEntityID_165f869f382f UUID;
  p_RelatedEntityFieldName_165f869f382f VARCHAR(255);
  p_IncludeRelatedEntityNameFieldInBaseView_165f869f382f BOOLEAN;
  p_RelatedEntityNameFieldMap_165f869f382f VARCHAR(255);
  p_RelatedEntityDisplayType_165f869f382f VARCHAR(20);
  p_EntityIDFieldName_165f869f382f VARCHAR(100);
  p_ScopeDefault_165f869f382f VARCHAR(100);
  p_AutoUpdateRelatedEntityInfo_165f869f382f BOOLEAN;
  p_ValuesToPackWithSchema_165f869f382f VARCHAR(10);
  p_Status_165f869f382f VARCHAR(25);
  p_AutoUpdateIsNameField_165f869f382f BOOLEAN;
  p_AutoUpdateDefaultInView_165f869f382f BOOLEAN;
  p_AutoUpdateCategory_165f869f382f BOOLEAN;
  p_AutoUpdateDisplayName_165f869f382f BOOLEAN;
  p_AutoUpdateIncludeInUserSearchAPI_165f869f382f BOOLEAN;
  p_Encrypt_165f869f382f BOOLEAN;
  p_EncryptionKeyID_165f869f382f UUID;
  p_AllowDecryptInAPI_165f869f382f BOOLEAN;
  p_SendEncryptedValue_165f869f382f BOOLEAN;
  p_IsSoftPrimaryKey_165f869f382f BOOLEAN;
  p_IsSoftForeignKey_165f869f382f BOOLEAN;
  p_RelatedEntityJoinFields_165f869f382f TEXT;
  p_JSONType_165f869f382f VARCHAR(255);
  p_JSONTypeIsArray_165f869f382f BOOLEAN;
  p_JSONTypeDefinition_165f869f382f TEXT;
  p_UserSearchPredicateAPI_165f869f382f VARCHAR(20);
  p_AutoUpdateUserSearchPredicate_165f869f382f BOOLEAN;
  p_AutoUpdateFullTextSearch_165f869f382f BOOLEAN;
  p_AutoUpdateExtendedType_165f869f382f BOOLEAN;
  p_IsComputed_165f869f382f BOOLEAN;
  p_EmbeddedRecord_165f869f382f TEXT;
  p_Configuration_165f869f382f TEXT;
  p_ID_165f869f382f UUID;
BEGIN
  p_DisplayName_165f869f382f := 'Linked User ID';
  p_Description_165f869f382f := 'Optional foreign key to the MemberJunction core User record (__mj.User) when this person is also an authenticated platform user. Enforced 1:1 via UQ_Person_LinkedUserID where not null. Saving a Person never auto-provisions or modifies MJ Users.';
  p_AutoUpdateDescription_165f869f382f := FALSE;
  p_IsPrimaryKey_165f869f382f := FALSE;
  p_IsUnique_165f869f382f := TRUE;
  p_Category_165f869f382f := 'Account and Status';
  p_ValueListType_165f869f382f := 'None';
  p_DefaultInView_165f869f382f := FALSE;
  p_DefaultColumnWidth_165f869f382f := 150;
  p_AllowUpdateAPI_165f869f382f := TRUE;
  p_AllowUpdateInView_165f869f382f := TRUE;
  p_IncludeInUserSearchAPI_165f869f382f := FALSE;
  p_FullTextSearchEnabled_165f869f382f := FALSE;
  p_IncludeInGeneratedForm_165f869f382f := TRUE;
  p_GeneratedFormSection_165f869f382f := 'Category';
  p_IsNameField_165f869f382f := FALSE;
  p_RelatedEntityID_165f869f382f := 'E1238F34-2837-EF11-86D4-6045BDEE16E6';
  p_RelatedEntityFieldName_165f869f382f := 'ID';
  p_IncludeRelatedEntityNameFieldInBaseView_165f869f382f := TRUE;
  p_RelatedEntityNameFieldMap_165f869f382f := 'LinkedUser';
  p_RelatedEntityDisplayType_165f869f382f := 'Search';
  p_AutoUpdateRelatedEntityInfo_165f869f382f := TRUE;
  p_ValuesToPackWithSchema_165f869f382f := 'Auto';
  p_Status_165f869f382f := 'Active';
  p_AutoUpdateIsNameField_165f869f382f := TRUE;
  p_AutoUpdateDefaultInView_165f869f382f := TRUE;
  p_AutoUpdateCategory_165f869f382f := TRUE;
  p_AutoUpdateDisplayName_165f869f382f := TRUE;
  p_AutoUpdateIncludeInUserSearchAPI_165f869f382f := TRUE;
  p_Encrypt_165f869f382f := FALSE;
  p_AllowDecryptInAPI_165f869f382f := FALSE;
  p_SendEncryptedValue_165f869f382f := FALSE;
  p_IsSoftPrimaryKey_165f869f382f := FALSE;
  p_IsSoftForeignKey_165f869f382f := FALSE;
  p_JSONTypeIsArray_165f869f382f := FALSE;
  p_UserSearchPredicateAPI_165f869f382f := 'Contains';
  p_AutoUpdateUserSearchPredicate_165f869f382f := TRUE;
  p_AutoUpdateFullTextSearch_165f869f382f := TRUE;
  p_AutoUpdateExtendedType_165f869f382f := TRUE;
  p_IsComputed_165f869f382f := FALSE;
  p_ID_165f869f382f := '79F1EEAB-367E-4B45-A9B8-75639F6410CB';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityField'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_data := jsonb_build_object(
    'DisplayName', p_DisplayName_165f869f382f,
    'Description', p_Description_165f869f382f,
    'AutoUpdateDescription', p_AutoUpdateDescription_165f869f382f,
    'IsPrimaryKey', p_IsPrimaryKey_165f869f382f,
    'IsUnique', p_IsUnique_165f869f382f,
    'Category', p_Category_165f869f382f,
    'ValueListType', p_ValueListType_165f869f382f,
    'ExtendedType', p_ExtendedType_165f869f382f,
    'CodeType', p_CodeType_165f869f382f,
    'DefaultInView', p_DefaultInView_165f869f382f,
    'ViewCellTemplate', p_ViewCellTemplate_165f869f382f,
    'DefaultColumnWidth', p_DefaultColumnWidth_165f869f382f,
    'AllowUpdateAPI', p_AllowUpdateAPI_165f869f382f,
    'AllowUpdateInView', p_AllowUpdateInView_165f869f382f,
    'IncludeInUserSearchAPI', p_IncludeInUserSearchAPI_165f869f382f,
    'FullTextSearchEnabled', p_FullTextSearchEnabled_165f869f382f,
    'UserSearchParamFormatAPI', p_UserSearchParamFormatAPI_165f869f382f,
    'IncludeInGeneratedForm', p_IncludeInGeneratedForm_165f869f382f,
    'GeneratedFormSection', p_GeneratedFormSection_165f869f382f,
    'IsNameField', p_IsNameField_165f869f382f,
    'RelatedEntityID', p_RelatedEntityID_165f869f382f,
    'RelatedEntityFieldName', p_RelatedEntityFieldName_165f869f382f,
    'IncludeRelatedEntityNameFieldInBaseView', p_IncludeRelatedEntityNameFieldInBaseView_165f869f382f,
    'RelatedEntityNameFieldMap', p_RelatedEntityNameFieldMap_165f869f382f,
    'RelatedEntityDisplayType', p_RelatedEntityDisplayType_165f869f382f,
    'EntityIDFieldName', p_EntityIDFieldName_165f869f382f,
    'ScopeDefault', p_ScopeDefault_165f869f382f,
    'AutoUpdateRelatedEntityInfo', p_AutoUpdateRelatedEntityInfo_165f869f382f,
    'ValuesToPackWithSchema', p_ValuesToPackWithSchema_165f869f382f,
    'Status', p_Status_165f869f382f,
    'AutoUpdateIsNameField', p_AutoUpdateIsNameField_165f869f382f,
    'AutoUpdateDefaultInView', p_AutoUpdateDefaultInView_165f869f382f,
    'AutoUpdateCategory', p_AutoUpdateCategory_165f869f382f,
    'AutoUpdateDisplayName', p_AutoUpdateDisplayName_165f869f382f,
    'AutoUpdateIncludeInUserSearchAPI', p_AutoUpdateIncludeInUserSearchAPI_165f869f382f,
    'Encrypt', p_Encrypt_165f869f382f,
    'EncryptionKeyID', p_EncryptionKeyID_165f869f382f,
    'AllowDecryptInAPI', p_AllowDecryptInAPI_165f869f382f,
    'SendEncryptedValue', p_SendEncryptedValue_165f869f382f,
    'IsSoftPrimaryKey', p_IsSoftPrimaryKey_165f869f382f,
    'IsSoftForeignKey', p_IsSoftForeignKey_165f869f382f,
    'RelatedEntityJoinFields', p_RelatedEntityJoinFields_165f869f382f,
    'JSONType', p_JSONType_165f869f382f,
    'JSONTypeIsArray', p_JSONTypeIsArray_165f869f382f,
    'JSONTypeDefinition', p_JSONTypeDefinition_165f869f382f,
    'UserSearchPredicateAPI', p_UserSearchPredicateAPI_165f869f382f,
    'AutoUpdateUserSearchPredicate', p_AutoUpdateUserSearchPredicate_165f869f382f,
    'AutoUpdateFullTextSearch', p_AutoUpdateFullTextSearch_165f869f382f,
    'AutoUpdateExtendedType', p_AutoUpdateExtendedType_165f869f382f,
    'IsComputed', p_IsComputed_165f869f382f
  ) ||
  jsonb_build_object(
    'EmbeddedRecord', p_EmbeddedRecord_165f869f382f,
    'Configuration', p_Configuration_165f869f382f,
    'ID', p_ID_165f869f382f
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_DisplayName := p_DisplayName_165f869f382f, p_Description := p_Description_165f869f382f, p_AutoUpdateDescription := p_AutoUpdateDescription_165f869f382f, p_IsPrimaryKey := p_IsPrimaryKey_165f869f382f, p_IsUnique := p_IsUnique_165f869f382f, p_Category := p_Category_165f869f382f, p_ValueListType := p_ValueListType_165f869f382f, p_ExtendedType := p_ExtendedType_165f869f382f, p_ExtendedType_Clear := TRUE, p_CodeType := p_CodeType_165f869f382f, p_CodeType_Clear := TRUE, p_DefaultInView := p_DefaultInView_165f869f382f, p_ViewCellTemplate := p_ViewCellTemplate_165f869f382f, p_ViewCellTemplate_Clear := TRUE, p_DefaultColumnWidth := p_DefaultColumnWidth_165f869f382f, p_AllowUpdateAPI := p_AllowUpdateAPI_165f869f382f, p_AllowUpdateInView := p_AllowUpdateInView_165f869f382f, p_IncludeInUserSearchAPI := p_IncludeInUserSearchAPI_165f869f382f, p_FullTextSearchEnabled := p_FullTextSearchEnabled_165f869f382f, p_UserSearchParamFormatAPI := p_UserSearchParamFormatAPI_165f869f382f, p_UserSearchParamFormatAPI_Clear := TRUE, p_IncludeInGeneratedForm := p_IncludeInGeneratedForm_165f869f382f, p_GeneratedFormSection := p_GeneratedFormSection_165f869f382f, p_IsNameField := p_IsNameField_165f869f382f, p_RelatedEntityID := p_RelatedEntityID_165f869f382f, p_RelatedEntityFieldName := p_RelatedEntityFieldName_165f869f382f, p_IncludeRelatedEntityNameFieldInBaseView := p_IncludeRelatedEntityNameFieldInBaseView_165f869f382f, p_RelatedEntityNameFieldMap := p_RelatedEntityNameFieldMap_165f869f382f, p_RelatedEntityDisplayType := p_RelatedEntityDisplayType_165f869f382f, p_EntityIDFieldName := p_EntityIDFieldName_165f869f382f, p_EntityIDFieldName_Clear := TRUE, p_ScopeDefault := p_ScopeDefault_165f869f382f, p_ScopeDefault_Clear := TRUE, p_AutoUpdateRelatedEntityInfo := p_AutoUpdateRelatedEntityInfo_165f869f382f, p_ValuesToPackWithSchema := p_ValuesToPackWithSchema_165f869f382f, p_Status := p_Status_165f869f382f, p_AutoUpdateIsNameField := p_AutoUpdateIsNameField_165f869f382f, p_AutoUpdateDefaultInView := p_AutoUpdateDefaultInView_165f869f382f, p_AutoUpdateCategory := p_AutoUpdateCategory_165f869f382f, p_AutoUpdateDisplayName := p_AutoUpdateDisplayName_165f869f382f, p_AutoUpdateIncludeInUserSearchAPI := p_AutoUpdateIncludeInUserSearchAPI_165f869f382f, p_Encrypt := p_Encrypt_165f869f382f, p_EncryptionKeyID := p_EncryptionKeyID_165f869f382f, p_EncryptionKeyID_Clear := TRUE, p_AllowDecryptInAPI := p_AllowDecryptInAPI_165f869f382f, p_SendEncryptedValue := p_SendEncryptedValue_165f869f382f, p_IsSoftPrimaryKey := p_IsSoftPrimaryKey_165f869f382f, p_IsSoftForeignKey := p_IsSoftForeignKey_165f869f382f, p_RelatedEntityJoinFields := p_RelatedEntityJoinFields_165f869f382f, p_RelatedEntityJoinFields_Clear := TRUE, p_JSONType := p_JSONType_165f869f382f, p_JSONType_Clear := TRUE, p_JSONTypeIsArray := p_JSONTypeIsArray_165f869f382f, p_JSONTypeDefinition := p_JSONTypeDefinition_165f869f382f, p_JSONTypeDefinition_Clear := TRUE, p_UserSearchPredicateAPI := p_UserSearchPredicateAPI_165f869f382f, p_AutoUpdateUserSearchPredicate := p_AutoUpdateUserSearchPredicate_165f869f382f, p_AutoUpdateFullTextSearch := p_AutoUpdateFullTextSearch_165f869f382f, p_AutoUpdateExtendedType := p_AutoUpdateExtendedType_165f869f382f, p_IsComputed := p_IsComputed_165f869f382f, p_EmbeddedRecord := p_EmbeddedRecord_165f869f382f, p_EmbeddedRecord_Clear := TRUE, p_Configuration := p_Configuration_165f869f382f, p_Configuration_Clear := TRUE, p_ID := p_ID_165f869f382f);
  END IF;
END $mj$;
