-- =============================================================================================
-- PostgreSQL counterpart of V202610161324__v5.54.x__Metadata_Sync.sql -- BizApps Common v5.54.x Metadata_Sync
-- =============================================================================================
-- Same records, same values, same order as the T-SQL file; see its header for what ships and why.
--
-- HOW IT WAS MADE
--   * `mj sql-convert --from tsql --to postgres` (MJ CLI 6.1.5) on the push log the T-SQL file
--     was generated from, held-back records removed as in the T-SQL file. Each record is a DO
--     block that calls the core spUpdateEntity or spUpdateEntityField function, in whichever
--     signature the host has (jsonb or named parameters).
--   * The T-SQL file has no lookups or guards: every record is an update by pinned ID.
--   * Every string value is taken verbatim from the T-SQL file: the converter rewrites T-SQL
--     inside string literals.
--   * Schema names use the same placeholders as the T-SQL file.
-- =============================================================================================

SET standard_conforming_strings = on;
-- Save MJ: Entities (core SP call only)
DO $mj$
DECLARE
  p_ParentID_2adf29f25a60 UUID;
  p_Name_2adf29f25a60 VARCHAR(255);
  p_NameSuffix_2adf29f25a60 VARCHAR(255);
  p_Description_2adf29f25a60 TEXT;
  p_AutoUpdateDescription_2adf29f25a60 BOOLEAN;
  p_BaseView_2adf29f25a60 VARCHAR(255);
  p_BaseViewGenerated_2adf29f25a60 BOOLEAN;
  p_VirtualEntity_2adf29f25a60 BOOLEAN;
  p_TrackRecordChanges_2adf29f25a60 BOOLEAN;
  p_AuditRecordAccess_2adf29f25a60 BOOLEAN;
  p_AuditViewRuns_2adf29f25a60 BOOLEAN;
  p_IncludeInAPI_2adf29f25a60 BOOLEAN;
  p_AllowAllRowsAPI_2adf29f25a60 BOOLEAN;
  p_AllowUpdateAPI_2adf29f25a60 BOOLEAN;
  p_AllowCreateAPI_2adf29f25a60 BOOLEAN;
  p_AllowDeleteAPI_2adf29f25a60 BOOLEAN;
  p_CustomResolverAPI_2adf29f25a60 BOOLEAN;
  p_AllowUserSearchAPI_2adf29f25a60 BOOLEAN;
  p_FullTextSearchEnabled_2adf29f25a60 BOOLEAN;
  p_FullTextCatalog_2adf29f25a60 VARCHAR(255);
  p_FullTextCatalogGenerated_2adf29f25a60 BOOLEAN;
  p_FullTextIndex_2adf29f25a60 VARCHAR(255);
  p_FullTextIndexGenerated_2adf29f25a60 BOOLEAN;
  p_FullTextSearchFunction_2adf29f25a60 VARCHAR(255);
  p_FullTextSearchFunctionGenerated_2adf29f25a60 BOOLEAN;
  p_UserViewMaxRows_2adf29f25a60 INTEGER;
  p_spCreate_2adf29f25a60 VARCHAR(255);
  p_spUpdate_2adf29f25a60 VARCHAR(255);
  p_spDelete_2adf29f25a60 VARCHAR(255);
  p_spCreateGenerated_2adf29f25a60 BOOLEAN;
  p_spUpdateGenerated_2adf29f25a60 BOOLEAN;
  p_spDeleteGenerated_2adf29f25a60 BOOLEAN;
  p_CascadeDeletes_2adf29f25a60 BOOLEAN;
  p_DeleteType_2adf29f25a60 VARCHAR(10);
  p_AllowRecordMerge_2adf29f25a60 BOOLEAN;
  p_spMatch_2adf29f25a60 VARCHAR(255);
  p_RelationshipDefaultDisplayType_2adf29f25a60 VARCHAR(20);
  p_UserFormGenerated_2adf29f25a60 BOOLEAN;
  p_EntityObjectSubclassName_2adf29f25a60 VARCHAR(255);
  p_EntityObjectSubclassImport_2adf29f25a60 VARCHAR(255);
  p_PreferredCommunicationField_2adf29f25a60 VARCHAR(255);
  p_Icon_2adf29f25a60 VARCHAR(500);
  p_ScopeDefault_2adf29f25a60 VARCHAR(100);
  p_RowsToPackWithSchema_2adf29f25a60 VARCHAR(20);
  p_RowsToPackSampleMethod_2adf29f25a60 VARCHAR(20);
  p_RowsToPackSampleCount_2adf29f25a60 INTEGER;
  p_RowsToPackSampleOrder_2adf29f25a60 TEXT;
  p_AutoRowCountFrequency_2adf29f25a60 INTEGER;
  p_RowCount_2adf29f25a60 BIGINT;
  p_RowCountRunAt_2adf29f25a60 TIMESTAMPTZ;
  p_Status_2adf29f25a60 VARCHAR(25);
  p_DisplayName_2adf29f25a60 VARCHAR(255);
  p_AllowMultipleSubtypes_2adf29f25a60 BOOLEAN;
  p_AutoUpdateFullTextSearch_2adf29f25a60 BOOLEAN;
  p_AutoUpdateAllowUserSearchAPI_2adf29f25a60 BOOLEAN;
  p_TrustServerCacheCompletely_2adf29f25a60 BOOLEAN;
  p_SupportsGeoCoding_2adf29f25a60 BOOLEAN;
  p_AutoUpdateSupportsGeoCoding_2adf29f25a60 BOOLEAN;
  p_AllowCaching_2adf29f25a60 BOOLEAN;
  p_DetectExternalChanges_2adf29f25a60 BOOLEAN;
  p_ExternalDataSourceID_2adf29f25a60 UUID;
  p_ExternalObjectName_2adf29f25a60 VARCHAR(255);
  p_GeneratedBaseViewName_2adf29f25a60 VARCHAR(255);
  p_AllowDirectSQLInsert_2adf29f25a60 BOOLEAN;
  p_AllowDirectSQLUpdate_2adf29f25a60 BOOLEAN;
  p_AllowDirectSQLDelete_2adf29f25a60 BOOLEAN;
  p_Configuration_2adf29f25a60 TEXT;
  p_SubtypeSelector_2adf29f25a60 TEXT;
  p_EnableFieldLevelSecurity_2adf29f25a60 BOOLEAN;
  p_ID_2adf29f25a60 UUID;
BEGIN
  p_Name_2adf29f25a60 := 'MJ_BizApps_Common: Address Links';
  p_Description_2adf29f25a60 := 'Polymorphic link table connecting Address records to any entity record in the system via EntityID and RecordID';
  p_AutoUpdateDescription_2adf29f25a60 := TRUE;
  p_BaseView_2adf29f25a60 := 'vwAddressLinks';
  p_BaseViewGenerated_2adf29f25a60 := TRUE;
  p_VirtualEntity_2adf29f25a60 := FALSE;
  p_TrackRecordChanges_2adf29f25a60 := TRUE;
  p_AuditRecordAccess_2adf29f25a60 := FALSE;
  p_AuditViewRuns_2adf29f25a60 := FALSE;
  p_IncludeInAPI_2adf29f25a60 := TRUE;
  p_AllowAllRowsAPI_2adf29f25a60 := FALSE;
  p_AllowUpdateAPI_2adf29f25a60 := TRUE;
  p_AllowCreateAPI_2adf29f25a60 := TRUE;
  p_AllowDeleteAPI_2adf29f25a60 := TRUE;
  p_CustomResolverAPI_2adf29f25a60 := FALSE;
  p_AllowUserSearchAPI_2adf29f25a60 := FALSE;
  p_FullTextSearchEnabled_2adf29f25a60 := FALSE;
  p_FullTextCatalogGenerated_2adf29f25a60 := TRUE;
  p_FullTextIndexGenerated_2adf29f25a60 := TRUE;
  p_FullTextSearchFunctionGenerated_2adf29f25a60 := TRUE;
  p_UserViewMaxRows_2adf29f25a60 := 1000;
  p_spCreateGenerated_2adf29f25a60 := TRUE;
  p_spUpdateGenerated_2adf29f25a60 := TRUE;
  p_spDeleteGenerated_2adf29f25a60 := TRUE;
  p_CascadeDeletes_2adf29f25a60 := FALSE;
  p_DeleteType_2adf29f25a60 := 'Hard';
  p_AllowRecordMerge_2adf29f25a60 := FALSE;
  p_RelationshipDefaultDisplayType_2adf29f25a60 := 'Search';
  p_UserFormGenerated_2adf29f25a60 := TRUE;
  p_Icon_2adf29f25a60 := 'fa fa-link';
  p_RowsToPackWithSchema_2adf29f25a60 := 'None';
  p_RowsToPackSampleMethod_2adf29f25a60 := 'random';
  p_RowsToPackSampleCount_2adf29f25a60 := 0;
  p_Status_2adf29f25a60 := 'Active';
  p_DisplayName_2adf29f25a60 := 'Address Links';
  p_AllowMultipleSubtypes_2adf29f25a60 := FALSE;
  p_AutoUpdateFullTextSearch_2adf29f25a60 := TRUE;
  p_AutoUpdateAllowUserSearchAPI_2adf29f25a60 := FALSE;
  p_TrustServerCacheCompletely_2adf29f25a60 := TRUE;
  p_SupportsGeoCoding_2adf29f25a60 := FALSE;
  p_AutoUpdateSupportsGeoCoding_2adf29f25a60 := FALSE;
  p_AllowCaching_2adf29f25a60 := FALSE;
  p_DetectExternalChanges_2adf29f25a60 := FALSE;
  p_AllowDirectSQLInsert_2adf29f25a60 := FALSE;
  p_AllowDirectSQLUpdate_2adf29f25a60 := FALSE;
  p_AllowDirectSQLDelete_2adf29f25a60 := FALSE;
  p_EnableFieldLevelSecurity_2adf29f25a60 := FALSE;
  p_ID_2adf29f25a60 := 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7';
  PERFORM "${mjSchema}"."spUpdateEntity"(p_data := jsonb_build_object(
    'ParentID', p_ParentID_2adf29f25a60,
    'Name', p_Name_2adf29f25a60,
    'NameSuffix', p_NameSuffix_2adf29f25a60,
    'Description', p_Description_2adf29f25a60,
    'AutoUpdateDescription', p_AutoUpdateDescription_2adf29f25a60,
    'BaseView', p_BaseView_2adf29f25a60,
    'BaseViewGenerated', p_BaseViewGenerated_2adf29f25a60,
    'VirtualEntity', p_VirtualEntity_2adf29f25a60,
    'TrackRecordChanges', p_TrackRecordChanges_2adf29f25a60,
    'AuditRecordAccess', p_AuditRecordAccess_2adf29f25a60,
    'AuditViewRuns', p_AuditViewRuns_2adf29f25a60,
    'IncludeInAPI', p_IncludeInAPI_2adf29f25a60,
    'AllowAllRowsAPI', p_AllowAllRowsAPI_2adf29f25a60,
    'AllowUpdateAPI', p_AllowUpdateAPI_2adf29f25a60,
    'AllowCreateAPI', p_AllowCreateAPI_2adf29f25a60,
    'AllowDeleteAPI', p_AllowDeleteAPI_2adf29f25a60,
    'CustomResolverAPI', p_CustomResolverAPI_2adf29f25a60,
    'AllowUserSearchAPI', p_AllowUserSearchAPI_2adf29f25a60,
    'FullTextSearchEnabled', p_FullTextSearchEnabled_2adf29f25a60,
    'FullTextCatalog', p_FullTextCatalog_2adf29f25a60,
    'FullTextCatalogGenerated', p_FullTextCatalogGenerated_2adf29f25a60,
    'FullTextIndex', p_FullTextIndex_2adf29f25a60,
    'FullTextIndexGenerated', p_FullTextIndexGenerated_2adf29f25a60,
    'FullTextSearchFunction', p_FullTextSearchFunction_2adf29f25a60,
    'FullTextSearchFunctionGenerated', p_FullTextSearchFunctionGenerated_2adf29f25a60,
    'UserViewMaxRows', p_UserViewMaxRows_2adf29f25a60,
    'spCreate', p_spCreate_2adf29f25a60,
    'spUpdate', p_spUpdate_2adf29f25a60,
    'spDelete', p_spDelete_2adf29f25a60,
    'spCreateGenerated', p_spCreateGenerated_2adf29f25a60,
    'spUpdateGenerated', p_spUpdateGenerated_2adf29f25a60,
    'spDeleteGenerated', p_spDeleteGenerated_2adf29f25a60,
    'CascadeDeletes', p_CascadeDeletes_2adf29f25a60,
    'DeleteType', p_DeleteType_2adf29f25a60,
    'AllowRecordMerge', p_AllowRecordMerge_2adf29f25a60,
    'spMatch', p_spMatch_2adf29f25a60,
    'RelationshipDefaultDisplayType', p_RelationshipDefaultDisplayType_2adf29f25a60,
    'UserFormGenerated', p_UserFormGenerated_2adf29f25a60,
    'EntityObjectSubclassName', p_EntityObjectSubclassName_2adf29f25a60,
    'EntityObjectSubclassImport', p_EntityObjectSubclassImport_2adf29f25a60,
    'PreferredCommunicationField', p_PreferredCommunicationField_2adf29f25a60,
    'Icon', p_Icon_2adf29f25a60,
    'ScopeDefault', p_ScopeDefault_2adf29f25a60,
    'RowsToPackWithSchema', p_RowsToPackWithSchema_2adf29f25a60,
    'RowsToPackSampleMethod', p_RowsToPackSampleMethod_2adf29f25a60,
    'RowsToPackSampleCount', p_RowsToPackSampleCount_2adf29f25a60,
    'RowsToPackSampleOrder', p_RowsToPackSampleOrder_2adf29f25a60,
    'AutoRowCountFrequency', p_AutoRowCountFrequency_2adf29f25a60,
    'RowCount', p_RowCount_2adf29f25a60,
    'RowCountRunAt', p_RowCountRunAt_2adf29f25a60
  ) ||
  jsonb_build_object(
    'Status', p_Status_2adf29f25a60,
    'DisplayName', p_DisplayName_2adf29f25a60,
    'AllowMultipleSubtypes', p_AllowMultipleSubtypes_2adf29f25a60,
    'AutoUpdateFullTextSearch', p_AutoUpdateFullTextSearch_2adf29f25a60,
    'AutoUpdateAllowUserSearchAPI', p_AutoUpdateAllowUserSearchAPI_2adf29f25a60,
    'TrustServerCacheCompletely', p_TrustServerCacheCompletely_2adf29f25a60,
    'SupportsGeoCoding', p_SupportsGeoCoding_2adf29f25a60,
    'AutoUpdateSupportsGeoCoding', p_AutoUpdateSupportsGeoCoding_2adf29f25a60,
    'AllowCaching', p_AllowCaching_2adf29f25a60,
    'DetectExternalChanges', p_DetectExternalChanges_2adf29f25a60,
    'ExternalDataSourceID', p_ExternalDataSourceID_2adf29f25a60,
    'ExternalObjectName', p_ExternalObjectName_2adf29f25a60,
    'GeneratedBaseViewName', p_GeneratedBaseViewName_2adf29f25a60,
    'AllowDirectSQLInsert', p_AllowDirectSQLInsert_2adf29f25a60,
    'AllowDirectSQLUpdate', p_AllowDirectSQLUpdate_2adf29f25a60,
    'AllowDirectSQLDelete', p_AllowDirectSQLDelete_2adf29f25a60,
    'Configuration', p_Configuration_2adf29f25a60,
    'SubtypeSelector', p_SubtypeSelector_2adf29f25a60,
    'EnableFieldLevelSecurity', p_EnableFieldLevelSecurity_2adf29f25a60,
    'ID', p_ID_2adf29f25a60
  ));
END $mj$;

-- Save MJ: Entity Fields (core SP call only)
DO $mj$
DECLARE
  p_DisplayName_9a588ea09e7a VARCHAR(255);
  p_Description_9a588ea09e7a TEXT;
  p_AutoUpdateDescription_9a588ea09e7a BOOLEAN;
  p_IsPrimaryKey_9a588ea09e7a BOOLEAN;
  p_IsUnique_9a588ea09e7a BOOLEAN;
  p_Category_9a588ea09e7a VARCHAR(255);
  p_ValueListType_9a588ea09e7a VARCHAR(20);
  p_ExtendedType_9a588ea09e7a VARCHAR(50);
  p_CodeType_9a588ea09e7a VARCHAR(50);
  p_DefaultInView_9a588ea09e7a BOOLEAN;
  p_ViewCellTemplate_9a588ea09e7a TEXT;
  p_DefaultColumnWidth_9a588ea09e7a INTEGER;
  p_AllowUpdateAPI_9a588ea09e7a BOOLEAN;
  p_AllowUpdateInView_9a588ea09e7a BOOLEAN;
  p_IncludeInUserSearchAPI_9a588ea09e7a BOOLEAN;
  p_FullTextSearchEnabled_9a588ea09e7a BOOLEAN;
  p_UserSearchParamFormatAPI_9a588ea09e7a VARCHAR(500);
  p_IncludeInGeneratedForm_9a588ea09e7a BOOLEAN;
  p_GeneratedFormSection_9a588ea09e7a VARCHAR(10);
  p_IsNameField_9a588ea09e7a BOOLEAN;
  p_RelatedEntityID_9a588ea09e7a UUID;
  p_RelatedEntityFieldName_9a588ea09e7a VARCHAR(255);
  p_IncludeRelatedEntityNameFieldInBaseView_9a588ea09e7a BOOLEAN;
  p_RelatedEntityNameFieldMap_9a588ea09e7a VARCHAR(255);
  p_RelatedEntityDisplayType_9a588ea09e7a VARCHAR(20);
  p_EntityIDFieldName_9a588ea09e7a VARCHAR(100);
  p_ScopeDefault_9a588ea09e7a VARCHAR(100);
  p_AutoUpdateRelatedEntityInfo_9a588ea09e7a BOOLEAN;
  p_ValuesToPackWithSchema_9a588ea09e7a VARCHAR(10);
  p_Status_9a588ea09e7a VARCHAR(25);
  p_AutoUpdateIsNameField_9a588ea09e7a BOOLEAN;
  p_AutoUpdateDefaultInView_9a588ea09e7a BOOLEAN;
  p_AutoUpdateCategory_9a588ea09e7a BOOLEAN;
  p_AutoUpdateDisplayName_9a588ea09e7a BOOLEAN;
  p_AutoUpdateIncludeInUserSearchAPI_9a588ea09e7a BOOLEAN;
  p_Encrypt_9a588ea09e7a BOOLEAN;
  p_EncryptionKeyID_9a588ea09e7a UUID;
  p_AllowDecryptInAPI_9a588ea09e7a BOOLEAN;
  p_SendEncryptedValue_9a588ea09e7a BOOLEAN;
  p_IsSoftPrimaryKey_9a588ea09e7a BOOLEAN;
  p_IsSoftForeignKey_9a588ea09e7a BOOLEAN;
  p_RelatedEntityJoinFields_9a588ea09e7a TEXT;
  p_JSONType_9a588ea09e7a VARCHAR(255);
  p_JSONTypeIsArray_9a588ea09e7a BOOLEAN;
  p_JSONTypeDefinition_9a588ea09e7a TEXT;
  p_UserSearchPredicateAPI_9a588ea09e7a VARCHAR(20);
  p_AutoUpdateUserSearchPredicate_9a588ea09e7a BOOLEAN;
  p_AutoUpdateFullTextSearch_9a588ea09e7a BOOLEAN;
  p_AutoUpdateExtendedType_9a588ea09e7a BOOLEAN;
  p_IsComputed_9a588ea09e7a BOOLEAN;
  p_EmbeddedRecord_9a588ea09e7a TEXT;
  p_Configuration_9a588ea09e7a TEXT;
  p_ID_9a588ea09e7a UUID;
BEGIN
  p_DisplayName_9a588ea09e7a := 'Display Name';
  p_Description_9a588ea09e7a := 'One-line label for the address in US order: Line1, City, State PostalCode, Country. Blank parts are skipped; NULL when every part is blank. Computed and stored; this is the entity name field.';
  p_AutoUpdateDescription_9a588ea09e7a := TRUE;
  p_IsPrimaryKey_9a588ea09e7a := FALSE;
  p_IsUnique_9a588ea09e7a := FALSE;
  p_Category_9a588ea09e7a := 'Address Details';
  p_ValueListType_9a588ea09e7a := 'None';
  p_DefaultInView_9a588ea09e7a := TRUE;
  p_DefaultColumnWidth_9a588ea09e7a := 150;
  p_AllowUpdateAPI_9a588ea09e7a := FALSE;
  p_AllowUpdateInView_9a588ea09e7a := TRUE;
  p_IncludeInUserSearchAPI_9a588ea09e7a := TRUE;
  p_FullTextSearchEnabled_9a588ea09e7a := FALSE;
  p_IncludeInGeneratedForm_9a588ea09e7a := TRUE;
  p_GeneratedFormSection_9a588ea09e7a := 'Category';
  p_IsNameField_9a588ea09e7a := TRUE;
  p_IncludeRelatedEntityNameFieldInBaseView_9a588ea09e7a := FALSE;
  p_RelatedEntityDisplayType_9a588ea09e7a := 'Search';
  p_AutoUpdateRelatedEntityInfo_9a588ea09e7a := TRUE;
  p_ValuesToPackWithSchema_9a588ea09e7a := 'Auto';
  p_Status_9a588ea09e7a := 'Active';
  p_AutoUpdateIsNameField_9a588ea09e7a := FALSE;
  p_AutoUpdateDefaultInView_9a588ea09e7a := TRUE;
  p_AutoUpdateCategory_9a588ea09e7a := TRUE;
  p_AutoUpdateDisplayName_9a588ea09e7a := TRUE;
  p_AutoUpdateIncludeInUserSearchAPI_9a588ea09e7a := TRUE;
  p_Encrypt_9a588ea09e7a := FALSE;
  p_AllowDecryptInAPI_9a588ea09e7a := FALSE;
  p_SendEncryptedValue_9a588ea09e7a := FALSE;
  p_IsSoftPrimaryKey_9a588ea09e7a := FALSE;
  p_IsSoftForeignKey_9a588ea09e7a := FALSE;
  p_JSONTypeIsArray_9a588ea09e7a := FALSE;
  p_UserSearchPredicateAPI_9a588ea09e7a := 'BeginsWith';
  p_AutoUpdateUserSearchPredicate_9a588ea09e7a := TRUE;
  p_AutoUpdateFullTextSearch_9a588ea09e7a := TRUE;
  p_AutoUpdateExtendedType_9a588ea09e7a := FALSE;
  p_IsComputed_9a588ea09e7a := TRUE;
  p_ID_9a588ea09e7a := '7B954EEF-A93E-4780-8692-8C1A25D33984';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityField'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_data := jsonb_build_object(
    'DisplayName', p_DisplayName_9a588ea09e7a,
    'Description', p_Description_9a588ea09e7a,
    'AutoUpdateDescription', p_AutoUpdateDescription_9a588ea09e7a,
    'IsPrimaryKey', p_IsPrimaryKey_9a588ea09e7a,
    'IsUnique', p_IsUnique_9a588ea09e7a,
    'Category', p_Category_9a588ea09e7a,
    'ValueListType', p_ValueListType_9a588ea09e7a,
    'ExtendedType', p_ExtendedType_9a588ea09e7a,
    'CodeType', p_CodeType_9a588ea09e7a,
    'DefaultInView', p_DefaultInView_9a588ea09e7a,
    'ViewCellTemplate', p_ViewCellTemplate_9a588ea09e7a,
    'DefaultColumnWidth', p_DefaultColumnWidth_9a588ea09e7a,
    'AllowUpdateAPI', p_AllowUpdateAPI_9a588ea09e7a,
    'AllowUpdateInView', p_AllowUpdateInView_9a588ea09e7a,
    'IncludeInUserSearchAPI', p_IncludeInUserSearchAPI_9a588ea09e7a,
    'FullTextSearchEnabled', p_FullTextSearchEnabled_9a588ea09e7a,
    'UserSearchParamFormatAPI', p_UserSearchParamFormatAPI_9a588ea09e7a,
    'IncludeInGeneratedForm', p_IncludeInGeneratedForm_9a588ea09e7a,
    'GeneratedFormSection', p_GeneratedFormSection_9a588ea09e7a,
    'IsNameField', p_IsNameField_9a588ea09e7a,
    'RelatedEntityID', p_RelatedEntityID_9a588ea09e7a,
    'RelatedEntityFieldName', p_RelatedEntityFieldName_9a588ea09e7a,
    'IncludeRelatedEntityNameFieldInBaseView', p_IncludeRelatedEntityNameFieldInBaseView_9a588ea09e7a,
    'RelatedEntityNameFieldMap', p_RelatedEntityNameFieldMap_9a588ea09e7a,
    'RelatedEntityDisplayType', p_RelatedEntityDisplayType_9a588ea09e7a,
    'EntityIDFieldName', p_EntityIDFieldName_9a588ea09e7a,
    'ScopeDefault', p_ScopeDefault_9a588ea09e7a,
    'AutoUpdateRelatedEntityInfo', p_AutoUpdateRelatedEntityInfo_9a588ea09e7a,
    'ValuesToPackWithSchema', p_ValuesToPackWithSchema_9a588ea09e7a,
    'Status', p_Status_9a588ea09e7a,
    'AutoUpdateIsNameField', p_AutoUpdateIsNameField_9a588ea09e7a,
    'AutoUpdateDefaultInView', p_AutoUpdateDefaultInView_9a588ea09e7a,
    'AutoUpdateCategory', p_AutoUpdateCategory_9a588ea09e7a,
    'AutoUpdateDisplayName', p_AutoUpdateDisplayName_9a588ea09e7a,
    'AutoUpdateIncludeInUserSearchAPI', p_AutoUpdateIncludeInUserSearchAPI_9a588ea09e7a,
    'Encrypt', p_Encrypt_9a588ea09e7a,
    'EncryptionKeyID', p_EncryptionKeyID_9a588ea09e7a,
    'AllowDecryptInAPI', p_AllowDecryptInAPI_9a588ea09e7a,
    'SendEncryptedValue', p_SendEncryptedValue_9a588ea09e7a,
    'IsSoftPrimaryKey', p_IsSoftPrimaryKey_9a588ea09e7a,
    'IsSoftForeignKey', p_IsSoftForeignKey_9a588ea09e7a,
    'RelatedEntityJoinFields', p_RelatedEntityJoinFields_9a588ea09e7a,
    'JSONType', p_JSONType_9a588ea09e7a,
    'JSONTypeIsArray', p_JSONTypeIsArray_9a588ea09e7a,
    'JSONTypeDefinition', p_JSONTypeDefinition_9a588ea09e7a,
    'UserSearchPredicateAPI', p_UserSearchPredicateAPI_9a588ea09e7a,
    'AutoUpdateUserSearchPredicate', p_AutoUpdateUserSearchPredicate_9a588ea09e7a,
    'AutoUpdateFullTextSearch', p_AutoUpdateFullTextSearch_9a588ea09e7a,
    'AutoUpdateExtendedType', p_AutoUpdateExtendedType_9a588ea09e7a,
    'IsComputed', p_IsComputed_9a588ea09e7a
  ) ||
  jsonb_build_object(
    'EmbeddedRecord', p_EmbeddedRecord_9a588ea09e7a,
    'Configuration', p_Configuration_9a588ea09e7a,
    'ID', p_ID_9a588ea09e7a
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_DisplayName := p_DisplayName_9a588ea09e7a, p_Description := p_Description_9a588ea09e7a, p_AutoUpdateDescription := p_AutoUpdateDescription_9a588ea09e7a, p_IsPrimaryKey := p_IsPrimaryKey_9a588ea09e7a, p_IsUnique := p_IsUnique_9a588ea09e7a, p_Category := p_Category_9a588ea09e7a, p_ValueListType := p_ValueListType_9a588ea09e7a, p_ExtendedType := p_ExtendedType_9a588ea09e7a, p_ExtendedType_Clear := TRUE, p_CodeType := p_CodeType_9a588ea09e7a, p_CodeType_Clear := TRUE, p_DefaultInView := p_DefaultInView_9a588ea09e7a, p_ViewCellTemplate := p_ViewCellTemplate_9a588ea09e7a, p_ViewCellTemplate_Clear := TRUE, p_DefaultColumnWidth := p_DefaultColumnWidth_9a588ea09e7a, p_AllowUpdateAPI := p_AllowUpdateAPI_9a588ea09e7a, p_AllowUpdateInView := p_AllowUpdateInView_9a588ea09e7a, p_IncludeInUserSearchAPI := p_IncludeInUserSearchAPI_9a588ea09e7a, p_FullTextSearchEnabled := p_FullTextSearchEnabled_9a588ea09e7a, p_UserSearchParamFormatAPI := p_UserSearchParamFormatAPI_9a588ea09e7a, p_UserSearchParamFormatAPI_Clear := TRUE, p_IncludeInGeneratedForm := p_IncludeInGeneratedForm_9a588ea09e7a, p_GeneratedFormSection := p_GeneratedFormSection_9a588ea09e7a, p_IsNameField := p_IsNameField_9a588ea09e7a, p_RelatedEntityID := p_RelatedEntityID_9a588ea09e7a, p_RelatedEntityID_Clear := TRUE, p_RelatedEntityFieldName := p_RelatedEntityFieldName_9a588ea09e7a, p_RelatedEntityFieldName_Clear := TRUE, p_IncludeRelatedEntityNameFieldInBaseView := p_IncludeRelatedEntityNameFieldInBaseView_9a588ea09e7a, p_RelatedEntityNameFieldMap := p_RelatedEntityNameFieldMap_9a588ea09e7a, p_RelatedEntityNameFieldMap_Clear := TRUE, p_RelatedEntityDisplayType := p_RelatedEntityDisplayType_9a588ea09e7a, p_EntityIDFieldName := p_EntityIDFieldName_9a588ea09e7a, p_EntityIDFieldName_Clear := TRUE, p_ScopeDefault := p_ScopeDefault_9a588ea09e7a, p_ScopeDefault_Clear := TRUE, p_AutoUpdateRelatedEntityInfo := p_AutoUpdateRelatedEntityInfo_9a588ea09e7a, p_ValuesToPackWithSchema := p_ValuesToPackWithSchema_9a588ea09e7a, p_Status := p_Status_9a588ea09e7a, p_AutoUpdateIsNameField := p_AutoUpdateIsNameField_9a588ea09e7a, p_AutoUpdateDefaultInView := p_AutoUpdateDefaultInView_9a588ea09e7a, p_AutoUpdateCategory := p_AutoUpdateCategory_9a588ea09e7a, p_AutoUpdateDisplayName := p_AutoUpdateDisplayName_9a588ea09e7a, p_AutoUpdateIncludeInUserSearchAPI := p_AutoUpdateIncludeInUserSearchAPI_9a588ea09e7a, p_Encrypt := p_Encrypt_9a588ea09e7a, p_EncryptionKeyID := p_EncryptionKeyID_9a588ea09e7a, p_EncryptionKeyID_Clear := TRUE, p_AllowDecryptInAPI := p_AllowDecryptInAPI_9a588ea09e7a, p_SendEncryptedValue := p_SendEncryptedValue_9a588ea09e7a, p_IsSoftPrimaryKey := p_IsSoftPrimaryKey_9a588ea09e7a, p_IsSoftForeignKey := p_IsSoftForeignKey_9a588ea09e7a, p_RelatedEntityJoinFields := p_RelatedEntityJoinFields_9a588ea09e7a, p_RelatedEntityJoinFields_Clear := TRUE, p_JSONType := p_JSONType_9a588ea09e7a, p_JSONType_Clear := TRUE, p_JSONTypeIsArray := p_JSONTypeIsArray_9a588ea09e7a, p_JSONTypeDefinition := p_JSONTypeDefinition_9a588ea09e7a, p_JSONTypeDefinition_Clear := TRUE, p_UserSearchPredicateAPI := p_UserSearchPredicateAPI_9a588ea09e7a, p_AutoUpdateUserSearchPredicate := p_AutoUpdateUserSearchPredicate_9a588ea09e7a, p_AutoUpdateFullTextSearch := p_AutoUpdateFullTextSearch_9a588ea09e7a, p_AutoUpdateExtendedType := p_AutoUpdateExtendedType_9a588ea09e7a, p_IsComputed := p_IsComputed_9a588ea09e7a, p_EmbeddedRecord := p_EmbeddedRecord_9a588ea09e7a, p_EmbeddedRecord_Clear := TRUE, p_Configuration := p_Configuration_9a588ea09e7a, p_Configuration_Clear := TRUE, p_ID := p_ID_9a588ea09e7a);
  END IF;
END $mj$;

-- Save MJ: Entity Fields (core SP call only)
DO $mj$
DECLARE
  p_DisplayName_969c5072658c VARCHAR(255);
  p_Description_969c5072658c TEXT;
  p_AutoUpdateDescription_969c5072658c BOOLEAN;
  p_IsPrimaryKey_969c5072658c BOOLEAN;
  p_IsUnique_969c5072658c BOOLEAN;
  p_Category_969c5072658c VARCHAR(255);
  p_ValueListType_969c5072658c VARCHAR(20);
  p_ExtendedType_969c5072658c VARCHAR(50);
  p_CodeType_969c5072658c VARCHAR(50);
  p_DefaultInView_969c5072658c BOOLEAN;
  p_ViewCellTemplate_969c5072658c TEXT;
  p_DefaultColumnWidth_969c5072658c INTEGER;
  p_AllowUpdateAPI_969c5072658c BOOLEAN;
  p_AllowUpdateInView_969c5072658c BOOLEAN;
  p_IncludeInUserSearchAPI_969c5072658c BOOLEAN;
  p_FullTextSearchEnabled_969c5072658c BOOLEAN;
  p_UserSearchParamFormatAPI_969c5072658c VARCHAR(500);
  p_IncludeInGeneratedForm_969c5072658c BOOLEAN;
  p_GeneratedFormSection_969c5072658c VARCHAR(10);
  p_IsNameField_969c5072658c BOOLEAN;
  p_RelatedEntityID_969c5072658c UUID;
  p_RelatedEntityFieldName_969c5072658c VARCHAR(255);
  p_IncludeRelatedEntityNameFieldInBaseView_969c5072658c BOOLEAN;
  p_RelatedEntityNameFieldMap_969c5072658c VARCHAR(255);
  p_RelatedEntityDisplayType_969c5072658c VARCHAR(20);
  p_EntityIDFieldName_969c5072658c VARCHAR(100);
  p_ScopeDefault_969c5072658c VARCHAR(100);
  p_AutoUpdateRelatedEntityInfo_969c5072658c BOOLEAN;
  p_ValuesToPackWithSchema_969c5072658c VARCHAR(10);
  p_Status_969c5072658c VARCHAR(25);
  p_AutoUpdateIsNameField_969c5072658c BOOLEAN;
  p_AutoUpdateDefaultInView_969c5072658c BOOLEAN;
  p_AutoUpdateCategory_969c5072658c BOOLEAN;
  p_AutoUpdateDisplayName_969c5072658c BOOLEAN;
  p_AutoUpdateIncludeInUserSearchAPI_969c5072658c BOOLEAN;
  p_Encrypt_969c5072658c BOOLEAN;
  p_EncryptionKeyID_969c5072658c UUID;
  p_AllowDecryptInAPI_969c5072658c BOOLEAN;
  p_SendEncryptedValue_969c5072658c BOOLEAN;
  p_IsSoftPrimaryKey_969c5072658c BOOLEAN;
  p_IsSoftForeignKey_969c5072658c BOOLEAN;
  p_RelatedEntityJoinFields_969c5072658c TEXT;
  p_JSONType_969c5072658c VARCHAR(255);
  p_JSONTypeIsArray_969c5072658c BOOLEAN;
  p_JSONTypeDefinition_969c5072658c TEXT;
  p_UserSearchPredicateAPI_969c5072658c VARCHAR(20);
  p_AutoUpdateUserSearchPredicate_969c5072658c BOOLEAN;
  p_AutoUpdateFullTextSearch_969c5072658c BOOLEAN;
  p_AutoUpdateExtendedType_969c5072658c BOOLEAN;
  p_IsComputed_969c5072658c BOOLEAN;
  p_EmbeddedRecord_969c5072658c TEXT;
  p_Configuration_969c5072658c TEXT;
  p_ID_969c5072658c UUID;
BEGIN
  p_DisplayName_969c5072658c := 'Address Line 1';
  p_Description_969c5072658c := 'Street address line 1. Optional: an address may record only a location (country, region, postal code) before a street line is known.';
  p_AutoUpdateDescription_969c5072658c := TRUE;
  p_IsPrimaryKey_969c5072658c := FALSE;
  p_IsUnique_969c5072658c := FALSE;
  p_Category_969c5072658c := 'Address Details';
  p_ValueListType_969c5072658c := 'None';
  p_ExtendedType_969c5072658c := 'GeoAddress';
  p_DefaultInView_969c5072658c := TRUE;
  p_DefaultColumnWidth_969c5072658c := 150;
  p_AllowUpdateAPI_969c5072658c := TRUE;
  p_AllowUpdateInView_969c5072658c := TRUE;
  p_IncludeInUserSearchAPI_969c5072658c := TRUE;
  p_FullTextSearchEnabled_969c5072658c := FALSE;
  p_IncludeInGeneratedForm_969c5072658c := TRUE;
  p_GeneratedFormSection_969c5072658c := 'Category';
  p_IsNameField_969c5072658c := FALSE;
  p_IncludeRelatedEntityNameFieldInBaseView_969c5072658c := FALSE;
  p_RelatedEntityDisplayType_969c5072658c := 'Search';
  p_AutoUpdateRelatedEntityInfo_969c5072658c := TRUE;
  p_ValuesToPackWithSchema_969c5072658c := 'Auto';
  p_Status_969c5072658c := 'Active';
  p_AutoUpdateIsNameField_969c5072658c := FALSE;
  p_AutoUpdateDefaultInView_969c5072658c := TRUE;
  p_AutoUpdateCategory_969c5072658c := TRUE;
  p_AutoUpdateDisplayName_969c5072658c := TRUE;
  p_AutoUpdateIncludeInUserSearchAPI_969c5072658c := TRUE;
  p_Encrypt_969c5072658c := FALSE;
  p_AllowDecryptInAPI_969c5072658c := FALSE;
  p_SendEncryptedValue_969c5072658c := FALSE;
  p_IsSoftPrimaryKey_969c5072658c := FALSE;
  p_IsSoftForeignKey_969c5072658c := FALSE;
  p_JSONTypeIsArray_969c5072658c := FALSE;
  p_UserSearchPredicateAPI_969c5072658c := 'Contains';
  p_AutoUpdateUserSearchPredicate_969c5072658c := TRUE;
  p_AutoUpdateFullTextSearch_969c5072658c := TRUE;
  p_AutoUpdateExtendedType_969c5072658c := FALSE;
  p_IsComputed_969c5072658c := FALSE;
  p_ID_969c5072658c := '8C5ED1B2-107E-4195-9E05-AC25C452971D';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityField'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_data := jsonb_build_object(
    'DisplayName', p_DisplayName_969c5072658c,
    'Description', p_Description_969c5072658c,
    'AutoUpdateDescription', p_AutoUpdateDescription_969c5072658c,
    'IsPrimaryKey', p_IsPrimaryKey_969c5072658c,
    'IsUnique', p_IsUnique_969c5072658c,
    'Category', p_Category_969c5072658c,
    'ValueListType', p_ValueListType_969c5072658c,
    'ExtendedType', p_ExtendedType_969c5072658c,
    'CodeType', p_CodeType_969c5072658c,
    'DefaultInView', p_DefaultInView_969c5072658c,
    'ViewCellTemplate', p_ViewCellTemplate_969c5072658c,
    'DefaultColumnWidth', p_DefaultColumnWidth_969c5072658c,
    'AllowUpdateAPI', p_AllowUpdateAPI_969c5072658c,
    'AllowUpdateInView', p_AllowUpdateInView_969c5072658c,
    'IncludeInUserSearchAPI', p_IncludeInUserSearchAPI_969c5072658c,
    'FullTextSearchEnabled', p_FullTextSearchEnabled_969c5072658c,
    'UserSearchParamFormatAPI', p_UserSearchParamFormatAPI_969c5072658c,
    'IncludeInGeneratedForm', p_IncludeInGeneratedForm_969c5072658c,
    'GeneratedFormSection', p_GeneratedFormSection_969c5072658c,
    'IsNameField', p_IsNameField_969c5072658c,
    'RelatedEntityID', p_RelatedEntityID_969c5072658c,
    'RelatedEntityFieldName', p_RelatedEntityFieldName_969c5072658c,
    'IncludeRelatedEntityNameFieldInBaseView', p_IncludeRelatedEntityNameFieldInBaseView_969c5072658c,
    'RelatedEntityNameFieldMap', p_RelatedEntityNameFieldMap_969c5072658c,
    'RelatedEntityDisplayType', p_RelatedEntityDisplayType_969c5072658c,
    'EntityIDFieldName', p_EntityIDFieldName_969c5072658c,
    'ScopeDefault', p_ScopeDefault_969c5072658c,
    'AutoUpdateRelatedEntityInfo', p_AutoUpdateRelatedEntityInfo_969c5072658c,
    'ValuesToPackWithSchema', p_ValuesToPackWithSchema_969c5072658c,
    'Status', p_Status_969c5072658c,
    'AutoUpdateIsNameField', p_AutoUpdateIsNameField_969c5072658c,
    'AutoUpdateDefaultInView', p_AutoUpdateDefaultInView_969c5072658c,
    'AutoUpdateCategory', p_AutoUpdateCategory_969c5072658c,
    'AutoUpdateDisplayName', p_AutoUpdateDisplayName_969c5072658c,
    'AutoUpdateIncludeInUserSearchAPI', p_AutoUpdateIncludeInUserSearchAPI_969c5072658c,
    'Encrypt', p_Encrypt_969c5072658c,
    'EncryptionKeyID', p_EncryptionKeyID_969c5072658c,
    'AllowDecryptInAPI', p_AllowDecryptInAPI_969c5072658c,
    'SendEncryptedValue', p_SendEncryptedValue_969c5072658c,
    'IsSoftPrimaryKey', p_IsSoftPrimaryKey_969c5072658c,
    'IsSoftForeignKey', p_IsSoftForeignKey_969c5072658c,
    'RelatedEntityJoinFields', p_RelatedEntityJoinFields_969c5072658c,
    'JSONType', p_JSONType_969c5072658c,
    'JSONTypeIsArray', p_JSONTypeIsArray_969c5072658c,
    'JSONTypeDefinition', p_JSONTypeDefinition_969c5072658c,
    'UserSearchPredicateAPI', p_UserSearchPredicateAPI_969c5072658c,
    'AutoUpdateUserSearchPredicate', p_AutoUpdateUserSearchPredicate_969c5072658c,
    'AutoUpdateFullTextSearch', p_AutoUpdateFullTextSearch_969c5072658c,
    'AutoUpdateExtendedType', p_AutoUpdateExtendedType_969c5072658c,
    'IsComputed', p_IsComputed_969c5072658c
  ) ||
  jsonb_build_object(
    'EmbeddedRecord', p_EmbeddedRecord_969c5072658c,
    'Configuration', p_Configuration_969c5072658c,
    'ID', p_ID_969c5072658c
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_DisplayName := p_DisplayName_969c5072658c, p_Description := p_Description_969c5072658c, p_AutoUpdateDescription := p_AutoUpdateDescription_969c5072658c, p_IsPrimaryKey := p_IsPrimaryKey_969c5072658c, p_IsUnique := p_IsUnique_969c5072658c, p_Category := p_Category_969c5072658c, p_ValueListType := p_ValueListType_969c5072658c, p_ExtendedType := p_ExtendedType_969c5072658c, p_CodeType := p_CodeType_969c5072658c, p_CodeType_Clear := TRUE, p_DefaultInView := p_DefaultInView_969c5072658c, p_ViewCellTemplate := p_ViewCellTemplate_969c5072658c, p_ViewCellTemplate_Clear := TRUE, p_DefaultColumnWidth := p_DefaultColumnWidth_969c5072658c, p_AllowUpdateAPI := p_AllowUpdateAPI_969c5072658c, p_AllowUpdateInView := p_AllowUpdateInView_969c5072658c, p_IncludeInUserSearchAPI := p_IncludeInUserSearchAPI_969c5072658c, p_FullTextSearchEnabled := p_FullTextSearchEnabled_969c5072658c, p_UserSearchParamFormatAPI := p_UserSearchParamFormatAPI_969c5072658c, p_UserSearchParamFormatAPI_Clear := TRUE, p_IncludeInGeneratedForm := p_IncludeInGeneratedForm_969c5072658c, p_GeneratedFormSection := p_GeneratedFormSection_969c5072658c, p_IsNameField := p_IsNameField_969c5072658c, p_RelatedEntityID := p_RelatedEntityID_969c5072658c, p_RelatedEntityID_Clear := TRUE, p_RelatedEntityFieldName := p_RelatedEntityFieldName_969c5072658c, p_RelatedEntityFieldName_Clear := TRUE, p_IncludeRelatedEntityNameFieldInBaseView := p_IncludeRelatedEntityNameFieldInBaseView_969c5072658c, p_RelatedEntityNameFieldMap := p_RelatedEntityNameFieldMap_969c5072658c, p_RelatedEntityNameFieldMap_Clear := TRUE, p_RelatedEntityDisplayType := p_RelatedEntityDisplayType_969c5072658c, p_EntityIDFieldName := p_EntityIDFieldName_969c5072658c, p_EntityIDFieldName_Clear := TRUE, p_ScopeDefault := p_ScopeDefault_969c5072658c, p_ScopeDefault_Clear := TRUE, p_AutoUpdateRelatedEntityInfo := p_AutoUpdateRelatedEntityInfo_969c5072658c, p_ValuesToPackWithSchema := p_ValuesToPackWithSchema_969c5072658c, p_Status := p_Status_969c5072658c, p_AutoUpdateIsNameField := p_AutoUpdateIsNameField_969c5072658c, p_AutoUpdateDefaultInView := p_AutoUpdateDefaultInView_969c5072658c, p_AutoUpdateCategory := p_AutoUpdateCategory_969c5072658c, p_AutoUpdateDisplayName := p_AutoUpdateDisplayName_969c5072658c, p_AutoUpdateIncludeInUserSearchAPI := p_AutoUpdateIncludeInUserSearchAPI_969c5072658c, p_Encrypt := p_Encrypt_969c5072658c, p_EncryptionKeyID := p_EncryptionKeyID_969c5072658c, p_EncryptionKeyID_Clear := TRUE, p_AllowDecryptInAPI := p_AllowDecryptInAPI_969c5072658c, p_SendEncryptedValue := p_SendEncryptedValue_969c5072658c, p_IsSoftPrimaryKey := p_IsSoftPrimaryKey_969c5072658c, p_IsSoftForeignKey := p_IsSoftForeignKey_969c5072658c, p_RelatedEntityJoinFields := p_RelatedEntityJoinFields_969c5072658c, p_RelatedEntityJoinFields_Clear := TRUE, p_JSONType := p_JSONType_969c5072658c, p_JSONType_Clear := TRUE, p_JSONTypeIsArray := p_JSONTypeIsArray_969c5072658c, p_JSONTypeDefinition := p_JSONTypeDefinition_969c5072658c, p_JSONTypeDefinition_Clear := TRUE, p_UserSearchPredicateAPI := p_UserSearchPredicateAPI_969c5072658c, p_AutoUpdateUserSearchPredicate := p_AutoUpdateUserSearchPredicate_969c5072658c, p_AutoUpdateFullTextSearch := p_AutoUpdateFullTextSearch_969c5072658c, p_AutoUpdateExtendedType := p_AutoUpdateExtendedType_969c5072658c, p_IsComputed := p_IsComputed_969c5072658c, p_EmbeddedRecord := p_EmbeddedRecord_969c5072658c, p_EmbeddedRecord_Clear := TRUE, p_Configuration := p_Configuration_969c5072658c, p_Configuration_Clear := TRUE, p_ID := p_ID_969c5072658c);
  END IF;
END $mj$;

-- Save MJ: Entity Fields (core SP call only)
DO $mj$
DECLARE
  p_DisplayName_b543e88649d3 VARCHAR(255);
  p_Description_b543e88649d3 TEXT;
  p_AutoUpdateDescription_b543e88649d3 BOOLEAN;
  p_IsPrimaryKey_b543e88649d3 BOOLEAN;
  p_IsUnique_b543e88649d3 BOOLEAN;
  p_Category_b543e88649d3 VARCHAR(255);
  p_ValueListType_b543e88649d3 VARCHAR(20);
  p_ExtendedType_b543e88649d3 VARCHAR(50);
  p_CodeType_b543e88649d3 VARCHAR(50);
  p_DefaultInView_b543e88649d3 BOOLEAN;
  p_ViewCellTemplate_b543e88649d3 TEXT;
  p_DefaultColumnWidth_b543e88649d3 INTEGER;
  p_AllowUpdateAPI_b543e88649d3 BOOLEAN;
  p_AllowUpdateInView_b543e88649d3 BOOLEAN;
  p_IncludeInUserSearchAPI_b543e88649d3 BOOLEAN;
  p_FullTextSearchEnabled_b543e88649d3 BOOLEAN;
  p_UserSearchParamFormatAPI_b543e88649d3 VARCHAR(500);
  p_IncludeInGeneratedForm_b543e88649d3 BOOLEAN;
  p_GeneratedFormSection_b543e88649d3 VARCHAR(10);
  p_IsNameField_b543e88649d3 BOOLEAN;
  p_RelatedEntityID_b543e88649d3 UUID;
  p_RelatedEntityFieldName_b543e88649d3 VARCHAR(255);
  p_IncludeRelatedEntityNameFieldInBaseView_b543e88649d3 BOOLEAN;
  p_RelatedEntityNameFieldMap_b543e88649d3 VARCHAR(255);
  p_RelatedEntityDisplayType_b543e88649d3 VARCHAR(20);
  p_EntityIDFieldName_b543e88649d3 VARCHAR(100);
  p_ScopeDefault_b543e88649d3 VARCHAR(100);
  p_AutoUpdateRelatedEntityInfo_b543e88649d3 BOOLEAN;
  p_ValuesToPackWithSchema_b543e88649d3 VARCHAR(10);
  p_Status_b543e88649d3 VARCHAR(25);
  p_AutoUpdateIsNameField_b543e88649d3 BOOLEAN;
  p_AutoUpdateDefaultInView_b543e88649d3 BOOLEAN;
  p_AutoUpdateCategory_b543e88649d3 BOOLEAN;
  p_AutoUpdateDisplayName_b543e88649d3 BOOLEAN;
  p_AutoUpdateIncludeInUserSearchAPI_b543e88649d3 BOOLEAN;
  p_Encrypt_b543e88649d3 BOOLEAN;
  p_EncryptionKeyID_b543e88649d3 UUID;
  p_AllowDecryptInAPI_b543e88649d3 BOOLEAN;
  p_SendEncryptedValue_b543e88649d3 BOOLEAN;
  p_IsSoftPrimaryKey_b543e88649d3 BOOLEAN;
  p_IsSoftForeignKey_b543e88649d3 BOOLEAN;
  p_RelatedEntityJoinFields_b543e88649d3 TEXT;
  p_JSONType_b543e88649d3 VARCHAR(255);
  p_JSONTypeIsArray_b543e88649d3 BOOLEAN;
  p_JSONTypeDefinition_b543e88649d3 TEXT;
  p_UserSearchPredicateAPI_b543e88649d3 VARCHAR(20);
  p_AutoUpdateUserSearchPredicate_b543e88649d3 BOOLEAN;
  p_AutoUpdateFullTextSearch_b543e88649d3 BOOLEAN;
  p_AutoUpdateExtendedType_b543e88649d3 BOOLEAN;
  p_IsComputed_b543e88649d3 BOOLEAN;
  p_EmbeddedRecord_b543e88649d3 TEXT;
  p_Configuration_b543e88649d3 TEXT;
  p_ID_b543e88649d3 UUID;
BEGIN
  p_DisplayName_b543e88649d3 := 'Display Name';
  p_AutoUpdateDescription_b543e88649d3 := TRUE;
  p_IsPrimaryKey_b543e88649d3 := FALSE;
  p_IsUnique_b543e88649d3 := FALSE;
  p_Category_b543e88649d3 := 'Relationship Details';
  p_ValueListType_b543e88649d3 := 'None';
  p_DefaultInView_b543e88649d3 := TRUE;
  p_DefaultColumnWidth_b543e88649d3 := 150;
  p_AllowUpdateAPI_b543e88649d3 := FALSE;
  p_AllowUpdateInView_b543e88649d3 := TRUE;
  p_IncludeInUserSearchAPI_b543e88649d3 := FALSE;
  p_FullTextSearchEnabled_b543e88649d3 := FALSE;
  p_IncludeInGeneratedForm_b543e88649d3 := TRUE;
  p_GeneratedFormSection_b543e88649d3 := 'Category';
  p_IsNameField_b543e88649d3 := TRUE;
  p_IncludeRelatedEntityNameFieldInBaseView_b543e88649d3 := FALSE;
  p_RelatedEntityDisplayType_b543e88649d3 := 'Search';
  p_AutoUpdateRelatedEntityInfo_b543e88649d3 := TRUE;
  p_ValuesToPackWithSchema_b543e88649d3 := 'Auto';
  p_Status_b543e88649d3 := 'Active';
  p_AutoUpdateIsNameField_b543e88649d3 := FALSE;
  p_AutoUpdateDefaultInView_b543e88649d3 := TRUE;
  p_AutoUpdateCategory_b543e88649d3 := TRUE;
  p_AutoUpdateDisplayName_b543e88649d3 := TRUE;
  p_AutoUpdateIncludeInUserSearchAPI_b543e88649d3 := TRUE;
  p_Encrypt_b543e88649d3 := FALSE;
  p_AllowDecryptInAPI_b543e88649d3 := FALSE;
  p_SendEncryptedValue_b543e88649d3 := FALSE;
  p_IsSoftPrimaryKey_b543e88649d3 := FALSE;
  p_IsSoftForeignKey_b543e88649d3 := FALSE;
  p_JSONTypeIsArray_b543e88649d3 := FALSE;
  p_UserSearchPredicateAPI_b543e88649d3 := 'Contains';
  p_AutoUpdateUserSearchPredicate_b543e88649d3 := TRUE;
  p_AutoUpdateFullTextSearch_b543e88649d3 := TRUE;
  p_AutoUpdateExtendedType_b543e88649d3 := TRUE;
  p_IsComputed_b543e88649d3 := FALSE;
  p_ID_b543e88649d3 := 'A4BBBC1D-AADC-48BB-AE3E-751E270F397C';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityField'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_data := jsonb_build_object(
    'DisplayName', p_DisplayName_b543e88649d3,
    'Description', p_Description_b543e88649d3,
    'AutoUpdateDescription', p_AutoUpdateDescription_b543e88649d3,
    'IsPrimaryKey', p_IsPrimaryKey_b543e88649d3,
    'IsUnique', p_IsUnique_b543e88649d3,
    'Category', p_Category_b543e88649d3,
    'ValueListType', p_ValueListType_b543e88649d3,
    'ExtendedType', p_ExtendedType_b543e88649d3,
    'CodeType', p_CodeType_b543e88649d3,
    'DefaultInView', p_DefaultInView_b543e88649d3,
    'ViewCellTemplate', p_ViewCellTemplate_b543e88649d3,
    'DefaultColumnWidth', p_DefaultColumnWidth_b543e88649d3,
    'AllowUpdateAPI', p_AllowUpdateAPI_b543e88649d3,
    'AllowUpdateInView', p_AllowUpdateInView_b543e88649d3,
    'IncludeInUserSearchAPI', p_IncludeInUserSearchAPI_b543e88649d3,
    'FullTextSearchEnabled', p_FullTextSearchEnabled_b543e88649d3,
    'UserSearchParamFormatAPI', p_UserSearchParamFormatAPI_b543e88649d3,
    'IncludeInGeneratedForm', p_IncludeInGeneratedForm_b543e88649d3,
    'GeneratedFormSection', p_GeneratedFormSection_b543e88649d3,
    'IsNameField', p_IsNameField_b543e88649d3,
    'RelatedEntityID', p_RelatedEntityID_b543e88649d3,
    'RelatedEntityFieldName', p_RelatedEntityFieldName_b543e88649d3,
    'IncludeRelatedEntityNameFieldInBaseView', p_IncludeRelatedEntityNameFieldInBaseView_b543e88649d3,
    'RelatedEntityNameFieldMap', p_RelatedEntityNameFieldMap_b543e88649d3,
    'RelatedEntityDisplayType', p_RelatedEntityDisplayType_b543e88649d3,
    'EntityIDFieldName', p_EntityIDFieldName_b543e88649d3,
    'ScopeDefault', p_ScopeDefault_b543e88649d3,
    'AutoUpdateRelatedEntityInfo', p_AutoUpdateRelatedEntityInfo_b543e88649d3,
    'ValuesToPackWithSchema', p_ValuesToPackWithSchema_b543e88649d3,
    'Status', p_Status_b543e88649d3,
    'AutoUpdateIsNameField', p_AutoUpdateIsNameField_b543e88649d3,
    'AutoUpdateDefaultInView', p_AutoUpdateDefaultInView_b543e88649d3,
    'AutoUpdateCategory', p_AutoUpdateCategory_b543e88649d3,
    'AutoUpdateDisplayName', p_AutoUpdateDisplayName_b543e88649d3,
    'AutoUpdateIncludeInUserSearchAPI', p_AutoUpdateIncludeInUserSearchAPI_b543e88649d3,
    'Encrypt', p_Encrypt_b543e88649d3,
    'EncryptionKeyID', p_EncryptionKeyID_b543e88649d3,
    'AllowDecryptInAPI', p_AllowDecryptInAPI_b543e88649d3,
    'SendEncryptedValue', p_SendEncryptedValue_b543e88649d3,
    'IsSoftPrimaryKey', p_IsSoftPrimaryKey_b543e88649d3,
    'IsSoftForeignKey', p_IsSoftForeignKey_b543e88649d3,
    'RelatedEntityJoinFields', p_RelatedEntityJoinFields_b543e88649d3,
    'JSONType', p_JSONType_b543e88649d3,
    'JSONTypeIsArray', p_JSONTypeIsArray_b543e88649d3,
    'JSONTypeDefinition', p_JSONTypeDefinition_b543e88649d3,
    'UserSearchPredicateAPI', p_UserSearchPredicateAPI_b543e88649d3,
    'AutoUpdateUserSearchPredicate', p_AutoUpdateUserSearchPredicate_b543e88649d3,
    'AutoUpdateFullTextSearch', p_AutoUpdateFullTextSearch_b543e88649d3,
    'AutoUpdateExtendedType', p_AutoUpdateExtendedType_b543e88649d3,
    'IsComputed', p_IsComputed_b543e88649d3
  ) ||
  jsonb_build_object(
    'EmbeddedRecord', p_EmbeddedRecord_b543e88649d3,
    'Configuration', p_Configuration_b543e88649d3,
    'ID', p_ID_b543e88649d3
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_DisplayName := p_DisplayName_b543e88649d3, p_Description := p_Description_b543e88649d3, p_Description_Clear := TRUE, p_AutoUpdateDescription := p_AutoUpdateDescription_b543e88649d3, p_IsPrimaryKey := p_IsPrimaryKey_b543e88649d3, p_IsUnique := p_IsUnique_b543e88649d3, p_Category := p_Category_b543e88649d3, p_ValueListType := p_ValueListType_b543e88649d3, p_ExtendedType := p_ExtendedType_b543e88649d3, p_ExtendedType_Clear := TRUE, p_CodeType := p_CodeType_b543e88649d3, p_CodeType_Clear := TRUE, p_DefaultInView := p_DefaultInView_b543e88649d3, p_ViewCellTemplate := p_ViewCellTemplate_b543e88649d3, p_ViewCellTemplate_Clear := TRUE, p_DefaultColumnWidth := p_DefaultColumnWidth_b543e88649d3, p_AllowUpdateAPI := p_AllowUpdateAPI_b543e88649d3, p_AllowUpdateInView := p_AllowUpdateInView_b543e88649d3, p_IncludeInUserSearchAPI := p_IncludeInUserSearchAPI_b543e88649d3, p_FullTextSearchEnabled := p_FullTextSearchEnabled_b543e88649d3, p_UserSearchParamFormatAPI := p_UserSearchParamFormatAPI_b543e88649d3, p_UserSearchParamFormatAPI_Clear := TRUE, p_IncludeInGeneratedForm := p_IncludeInGeneratedForm_b543e88649d3, p_GeneratedFormSection := p_GeneratedFormSection_b543e88649d3, p_IsNameField := p_IsNameField_b543e88649d3, p_RelatedEntityID := p_RelatedEntityID_b543e88649d3, p_RelatedEntityID_Clear := TRUE, p_RelatedEntityFieldName := p_RelatedEntityFieldName_b543e88649d3, p_RelatedEntityFieldName_Clear := TRUE, p_IncludeRelatedEntityNameFieldInBaseView := p_IncludeRelatedEntityNameFieldInBaseView_b543e88649d3, p_RelatedEntityNameFieldMap := p_RelatedEntityNameFieldMap_b543e88649d3, p_RelatedEntityNameFieldMap_Clear := TRUE, p_RelatedEntityDisplayType := p_RelatedEntityDisplayType_b543e88649d3, p_EntityIDFieldName := p_EntityIDFieldName_b543e88649d3, p_EntityIDFieldName_Clear := TRUE, p_ScopeDefault := p_ScopeDefault_b543e88649d3, p_ScopeDefault_Clear := TRUE, p_AutoUpdateRelatedEntityInfo := p_AutoUpdateRelatedEntityInfo_b543e88649d3, p_ValuesToPackWithSchema := p_ValuesToPackWithSchema_b543e88649d3, p_Status := p_Status_b543e88649d3, p_AutoUpdateIsNameField := p_AutoUpdateIsNameField_b543e88649d3, p_AutoUpdateDefaultInView := p_AutoUpdateDefaultInView_b543e88649d3, p_AutoUpdateCategory := p_AutoUpdateCategory_b543e88649d3, p_AutoUpdateDisplayName := p_AutoUpdateDisplayName_b543e88649d3, p_AutoUpdateIncludeInUserSearchAPI := p_AutoUpdateIncludeInUserSearchAPI_b543e88649d3, p_Encrypt := p_Encrypt_b543e88649d3, p_EncryptionKeyID := p_EncryptionKeyID_b543e88649d3, p_EncryptionKeyID_Clear := TRUE, p_AllowDecryptInAPI := p_AllowDecryptInAPI_b543e88649d3, p_SendEncryptedValue := p_SendEncryptedValue_b543e88649d3, p_IsSoftPrimaryKey := p_IsSoftPrimaryKey_b543e88649d3, p_IsSoftForeignKey := p_IsSoftForeignKey_b543e88649d3, p_RelatedEntityJoinFields := p_RelatedEntityJoinFields_b543e88649d3, p_RelatedEntityJoinFields_Clear := TRUE, p_JSONType := p_JSONType_b543e88649d3, p_JSONType_Clear := TRUE, p_JSONTypeIsArray := p_JSONTypeIsArray_b543e88649d3, p_JSONTypeDefinition := p_JSONTypeDefinition_b543e88649d3, p_JSONTypeDefinition_Clear := TRUE, p_UserSearchPredicateAPI := p_UserSearchPredicateAPI_b543e88649d3, p_AutoUpdateUserSearchPredicate := p_AutoUpdateUserSearchPredicate_b543e88649d3, p_AutoUpdateFullTextSearch := p_AutoUpdateFullTextSearch_b543e88649d3, p_AutoUpdateExtendedType := p_AutoUpdateExtendedType_b543e88649d3, p_IsComputed := p_IsComputed_b543e88649d3, p_EmbeddedRecord := p_EmbeddedRecord_b543e88649d3, p_EmbeddedRecord_Clear := TRUE, p_Configuration := p_Configuration_b543e88649d3, p_Configuration_Clear := TRUE, p_ID := p_ID_b543e88649d3);
  END IF;
END $mj$;

-- Save MJ: Entity Fields (core SP call only)
DO $mj$
DECLARE
  p_DisplayName_647bd9c3f2ef VARCHAR(255);
  p_Description_647bd9c3f2ef TEXT;
  p_AutoUpdateDescription_647bd9c3f2ef BOOLEAN;
  p_IsPrimaryKey_647bd9c3f2ef BOOLEAN;
  p_IsUnique_647bd9c3f2ef BOOLEAN;
  p_Category_647bd9c3f2ef VARCHAR(255);
  p_ValueListType_647bd9c3f2ef VARCHAR(20);
  p_ExtendedType_647bd9c3f2ef VARCHAR(50);
  p_CodeType_647bd9c3f2ef VARCHAR(50);
  p_DefaultInView_647bd9c3f2ef BOOLEAN;
  p_ViewCellTemplate_647bd9c3f2ef TEXT;
  p_DefaultColumnWidth_647bd9c3f2ef INTEGER;
  p_AllowUpdateAPI_647bd9c3f2ef BOOLEAN;
  p_AllowUpdateInView_647bd9c3f2ef BOOLEAN;
  p_IncludeInUserSearchAPI_647bd9c3f2ef BOOLEAN;
  p_FullTextSearchEnabled_647bd9c3f2ef BOOLEAN;
  p_UserSearchParamFormatAPI_647bd9c3f2ef VARCHAR(500);
  p_IncludeInGeneratedForm_647bd9c3f2ef BOOLEAN;
  p_GeneratedFormSection_647bd9c3f2ef VARCHAR(10);
  p_IsNameField_647bd9c3f2ef BOOLEAN;
  p_RelatedEntityID_647bd9c3f2ef UUID;
  p_RelatedEntityFieldName_647bd9c3f2ef VARCHAR(255);
  p_IncludeRelatedEntityNameFieldInBaseView_647bd9c3f2ef BOOLEAN;
  p_RelatedEntityNameFieldMap_647bd9c3f2ef VARCHAR(255);
  p_RelatedEntityDisplayType_647bd9c3f2ef VARCHAR(20);
  p_EntityIDFieldName_647bd9c3f2ef VARCHAR(100);
  p_ScopeDefault_647bd9c3f2ef VARCHAR(100);
  p_AutoUpdateRelatedEntityInfo_647bd9c3f2ef BOOLEAN;
  p_ValuesToPackWithSchema_647bd9c3f2ef VARCHAR(10);
  p_Status_647bd9c3f2ef VARCHAR(25);
  p_AutoUpdateIsNameField_647bd9c3f2ef BOOLEAN;
  p_AutoUpdateDefaultInView_647bd9c3f2ef BOOLEAN;
  p_AutoUpdateCategory_647bd9c3f2ef BOOLEAN;
  p_AutoUpdateDisplayName_647bd9c3f2ef BOOLEAN;
  p_AutoUpdateIncludeInUserSearchAPI_647bd9c3f2ef BOOLEAN;
  p_Encrypt_647bd9c3f2ef BOOLEAN;
  p_EncryptionKeyID_647bd9c3f2ef UUID;
  p_AllowDecryptInAPI_647bd9c3f2ef BOOLEAN;
  p_SendEncryptedValue_647bd9c3f2ef BOOLEAN;
  p_IsSoftPrimaryKey_647bd9c3f2ef BOOLEAN;
  p_IsSoftForeignKey_647bd9c3f2ef BOOLEAN;
  p_RelatedEntityJoinFields_647bd9c3f2ef TEXT;
  p_JSONType_647bd9c3f2ef VARCHAR(255);
  p_JSONTypeIsArray_647bd9c3f2ef BOOLEAN;
  p_JSONTypeDefinition_647bd9c3f2ef TEXT;
  p_UserSearchPredicateAPI_647bd9c3f2ef VARCHAR(20);
  p_AutoUpdateUserSearchPredicate_647bd9c3f2ef BOOLEAN;
  p_AutoUpdateFullTextSearch_647bd9c3f2ef BOOLEAN;
  p_AutoUpdateExtendedType_647bd9c3f2ef BOOLEAN;
  p_IsComputed_647bd9c3f2ef BOOLEAN;
  p_EmbeddedRecord_647bd9c3f2ef TEXT;
  p_Configuration_647bd9c3f2ef TEXT;
  p_ID_647bd9c3f2ef UUID;
BEGIN
  p_DisplayName_647bd9c3f2ef := 'Title';
  p_Description_647bd9c3f2ef := 'Contextual title for this specific relationship, e.g. CEO, Primary Contact, Founding Member';
  p_AutoUpdateDescription_647bd9c3f2ef := TRUE;
  p_IsPrimaryKey_647bd9c3f2ef := FALSE;
  p_IsUnique_647bd9c3f2ef := FALSE;
  p_Category_647bd9c3f2ef := 'Relationship Details';
  p_ValueListType_647bd9c3f2ef := 'None';
  p_DefaultInView_647bd9c3f2ef := TRUE;
  p_DefaultColumnWidth_647bd9c3f2ef := 150;
  p_AllowUpdateAPI_647bd9c3f2ef := TRUE;
  p_AllowUpdateInView_647bd9c3f2ef := TRUE;
  p_IncludeInUserSearchAPI_647bd9c3f2ef := TRUE;
  p_FullTextSearchEnabled_647bd9c3f2ef := FALSE;
  p_IncludeInGeneratedForm_647bd9c3f2ef := TRUE;
  p_GeneratedFormSection_647bd9c3f2ef := 'Category';
  p_IsNameField_647bd9c3f2ef := FALSE;
  p_IncludeRelatedEntityNameFieldInBaseView_647bd9c3f2ef := FALSE;
  p_RelatedEntityDisplayType_647bd9c3f2ef := 'Search';
  p_AutoUpdateRelatedEntityInfo_647bd9c3f2ef := TRUE;
  p_ValuesToPackWithSchema_647bd9c3f2ef := 'Auto';
  p_Status_647bd9c3f2ef := 'Active';
  p_AutoUpdateIsNameField_647bd9c3f2ef := FALSE;
  p_AutoUpdateDefaultInView_647bd9c3f2ef := TRUE;
  p_AutoUpdateCategory_647bd9c3f2ef := TRUE;
  p_AutoUpdateDisplayName_647bd9c3f2ef := TRUE;
  p_AutoUpdateIncludeInUserSearchAPI_647bd9c3f2ef := TRUE;
  p_Encrypt_647bd9c3f2ef := FALSE;
  p_AllowDecryptInAPI_647bd9c3f2ef := FALSE;
  p_SendEncryptedValue_647bd9c3f2ef := FALSE;
  p_IsSoftPrimaryKey_647bd9c3f2ef := FALSE;
  p_IsSoftForeignKey_647bd9c3f2ef := FALSE;
  p_JSONTypeIsArray_647bd9c3f2ef := FALSE;
  p_UserSearchPredicateAPI_647bd9c3f2ef := 'Contains';
  p_AutoUpdateUserSearchPredicate_647bd9c3f2ef := TRUE;
  p_AutoUpdateFullTextSearch_647bd9c3f2ef := TRUE;
  p_AutoUpdateExtendedType_647bd9c3f2ef := TRUE;
  p_IsComputed_647bd9c3f2ef := FALSE;
  p_ID_647bd9c3f2ef := '2ACBD16A-2A78-4807-8B8D-D0920382EAE6';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityField'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_data := jsonb_build_object(
    'DisplayName', p_DisplayName_647bd9c3f2ef,
    'Description', p_Description_647bd9c3f2ef,
    'AutoUpdateDescription', p_AutoUpdateDescription_647bd9c3f2ef,
    'IsPrimaryKey', p_IsPrimaryKey_647bd9c3f2ef,
    'IsUnique', p_IsUnique_647bd9c3f2ef,
    'Category', p_Category_647bd9c3f2ef,
    'ValueListType', p_ValueListType_647bd9c3f2ef,
    'ExtendedType', p_ExtendedType_647bd9c3f2ef,
    'CodeType', p_CodeType_647bd9c3f2ef,
    'DefaultInView', p_DefaultInView_647bd9c3f2ef,
    'ViewCellTemplate', p_ViewCellTemplate_647bd9c3f2ef,
    'DefaultColumnWidth', p_DefaultColumnWidth_647bd9c3f2ef,
    'AllowUpdateAPI', p_AllowUpdateAPI_647bd9c3f2ef,
    'AllowUpdateInView', p_AllowUpdateInView_647bd9c3f2ef,
    'IncludeInUserSearchAPI', p_IncludeInUserSearchAPI_647bd9c3f2ef,
    'FullTextSearchEnabled', p_FullTextSearchEnabled_647bd9c3f2ef,
    'UserSearchParamFormatAPI', p_UserSearchParamFormatAPI_647bd9c3f2ef,
    'IncludeInGeneratedForm', p_IncludeInGeneratedForm_647bd9c3f2ef,
    'GeneratedFormSection', p_GeneratedFormSection_647bd9c3f2ef,
    'IsNameField', p_IsNameField_647bd9c3f2ef,
    'RelatedEntityID', p_RelatedEntityID_647bd9c3f2ef,
    'RelatedEntityFieldName', p_RelatedEntityFieldName_647bd9c3f2ef,
    'IncludeRelatedEntityNameFieldInBaseView', p_IncludeRelatedEntityNameFieldInBaseView_647bd9c3f2ef,
    'RelatedEntityNameFieldMap', p_RelatedEntityNameFieldMap_647bd9c3f2ef,
    'RelatedEntityDisplayType', p_RelatedEntityDisplayType_647bd9c3f2ef,
    'EntityIDFieldName', p_EntityIDFieldName_647bd9c3f2ef,
    'ScopeDefault', p_ScopeDefault_647bd9c3f2ef,
    'AutoUpdateRelatedEntityInfo', p_AutoUpdateRelatedEntityInfo_647bd9c3f2ef,
    'ValuesToPackWithSchema', p_ValuesToPackWithSchema_647bd9c3f2ef,
    'Status', p_Status_647bd9c3f2ef,
    'AutoUpdateIsNameField', p_AutoUpdateIsNameField_647bd9c3f2ef,
    'AutoUpdateDefaultInView', p_AutoUpdateDefaultInView_647bd9c3f2ef,
    'AutoUpdateCategory', p_AutoUpdateCategory_647bd9c3f2ef,
    'AutoUpdateDisplayName', p_AutoUpdateDisplayName_647bd9c3f2ef,
    'AutoUpdateIncludeInUserSearchAPI', p_AutoUpdateIncludeInUserSearchAPI_647bd9c3f2ef,
    'Encrypt', p_Encrypt_647bd9c3f2ef,
    'EncryptionKeyID', p_EncryptionKeyID_647bd9c3f2ef,
    'AllowDecryptInAPI', p_AllowDecryptInAPI_647bd9c3f2ef,
    'SendEncryptedValue', p_SendEncryptedValue_647bd9c3f2ef,
    'IsSoftPrimaryKey', p_IsSoftPrimaryKey_647bd9c3f2ef,
    'IsSoftForeignKey', p_IsSoftForeignKey_647bd9c3f2ef,
    'RelatedEntityJoinFields', p_RelatedEntityJoinFields_647bd9c3f2ef,
    'JSONType', p_JSONType_647bd9c3f2ef,
    'JSONTypeIsArray', p_JSONTypeIsArray_647bd9c3f2ef,
    'JSONTypeDefinition', p_JSONTypeDefinition_647bd9c3f2ef,
    'UserSearchPredicateAPI', p_UserSearchPredicateAPI_647bd9c3f2ef,
    'AutoUpdateUserSearchPredicate', p_AutoUpdateUserSearchPredicate_647bd9c3f2ef,
    'AutoUpdateFullTextSearch', p_AutoUpdateFullTextSearch_647bd9c3f2ef,
    'AutoUpdateExtendedType', p_AutoUpdateExtendedType_647bd9c3f2ef,
    'IsComputed', p_IsComputed_647bd9c3f2ef
  ) ||
  jsonb_build_object(
    'EmbeddedRecord', p_EmbeddedRecord_647bd9c3f2ef,
    'Configuration', p_Configuration_647bd9c3f2ef,
    'ID', p_ID_647bd9c3f2ef
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_DisplayName := p_DisplayName_647bd9c3f2ef, p_Description := p_Description_647bd9c3f2ef, p_AutoUpdateDescription := p_AutoUpdateDescription_647bd9c3f2ef, p_IsPrimaryKey := p_IsPrimaryKey_647bd9c3f2ef, p_IsUnique := p_IsUnique_647bd9c3f2ef, p_Category := p_Category_647bd9c3f2ef, p_ValueListType := p_ValueListType_647bd9c3f2ef, p_ExtendedType := p_ExtendedType_647bd9c3f2ef, p_ExtendedType_Clear := TRUE, p_CodeType := p_CodeType_647bd9c3f2ef, p_CodeType_Clear := TRUE, p_DefaultInView := p_DefaultInView_647bd9c3f2ef, p_ViewCellTemplate := p_ViewCellTemplate_647bd9c3f2ef, p_ViewCellTemplate_Clear := TRUE, p_DefaultColumnWidth := p_DefaultColumnWidth_647bd9c3f2ef, p_AllowUpdateAPI := p_AllowUpdateAPI_647bd9c3f2ef, p_AllowUpdateInView := p_AllowUpdateInView_647bd9c3f2ef, p_IncludeInUserSearchAPI := p_IncludeInUserSearchAPI_647bd9c3f2ef, p_FullTextSearchEnabled := p_FullTextSearchEnabled_647bd9c3f2ef, p_UserSearchParamFormatAPI := p_UserSearchParamFormatAPI_647bd9c3f2ef, p_UserSearchParamFormatAPI_Clear := TRUE, p_IncludeInGeneratedForm := p_IncludeInGeneratedForm_647bd9c3f2ef, p_GeneratedFormSection := p_GeneratedFormSection_647bd9c3f2ef, p_IsNameField := p_IsNameField_647bd9c3f2ef, p_RelatedEntityID := p_RelatedEntityID_647bd9c3f2ef, p_RelatedEntityID_Clear := TRUE, p_RelatedEntityFieldName := p_RelatedEntityFieldName_647bd9c3f2ef, p_RelatedEntityFieldName_Clear := TRUE, p_IncludeRelatedEntityNameFieldInBaseView := p_IncludeRelatedEntityNameFieldInBaseView_647bd9c3f2ef, p_RelatedEntityNameFieldMap := p_RelatedEntityNameFieldMap_647bd9c3f2ef, p_RelatedEntityNameFieldMap_Clear := TRUE, p_RelatedEntityDisplayType := p_RelatedEntityDisplayType_647bd9c3f2ef, p_EntityIDFieldName := p_EntityIDFieldName_647bd9c3f2ef, p_EntityIDFieldName_Clear := TRUE, p_ScopeDefault := p_ScopeDefault_647bd9c3f2ef, p_ScopeDefault_Clear := TRUE, p_AutoUpdateRelatedEntityInfo := p_AutoUpdateRelatedEntityInfo_647bd9c3f2ef, p_ValuesToPackWithSchema := p_ValuesToPackWithSchema_647bd9c3f2ef, p_Status := p_Status_647bd9c3f2ef, p_AutoUpdateIsNameField := p_AutoUpdateIsNameField_647bd9c3f2ef, p_AutoUpdateDefaultInView := p_AutoUpdateDefaultInView_647bd9c3f2ef, p_AutoUpdateCategory := p_AutoUpdateCategory_647bd9c3f2ef, p_AutoUpdateDisplayName := p_AutoUpdateDisplayName_647bd9c3f2ef, p_AutoUpdateIncludeInUserSearchAPI := p_AutoUpdateIncludeInUserSearchAPI_647bd9c3f2ef, p_Encrypt := p_Encrypt_647bd9c3f2ef, p_EncryptionKeyID := p_EncryptionKeyID_647bd9c3f2ef, p_EncryptionKeyID_Clear := TRUE, p_AllowDecryptInAPI := p_AllowDecryptInAPI_647bd9c3f2ef, p_SendEncryptedValue := p_SendEncryptedValue_647bd9c3f2ef, p_IsSoftPrimaryKey := p_IsSoftPrimaryKey_647bd9c3f2ef, p_IsSoftForeignKey := p_IsSoftForeignKey_647bd9c3f2ef, p_RelatedEntityJoinFields := p_RelatedEntityJoinFields_647bd9c3f2ef, p_RelatedEntityJoinFields_Clear := TRUE, p_JSONType := p_JSONType_647bd9c3f2ef, p_JSONType_Clear := TRUE, p_JSONTypeIsArray := p_JSONTypeIsArray_647bd9c3f2ef, p_JSONTypeDefinition := p_JSONTypeDefinition_647bd9c3f2ef, p_JSONTypeDefinition_Clear := TRUE, p_UserSearchPredicateAPI := p_UserSearchPredicateAPI_647bd9c3f2ef, p_AutoUpdateUserSearchPredicate := p_AutoUpdateUserSearchPredicate_647bd9c3f2ef, p_AutoUpdateFullTextSearch := p_AutoUpdateFullTextSearch_647bd9c3f2ef, p_AutoUpdateExtendedType := p_AutoUpdateExtendedType_647bd9c3f2ef, p_IsComputed := p_IsComputed_647bd9c3f2ef, p_EmbeddedRecord := p_EmbeddedRecord_647bd9c3f2ef, p_EmbeddedRecord_Clear := TRUE, p_Configuration := p_Configuration_647bd9c3f2ef, p_Configuration_Clear := TRUE, p_ID := p_ID_647bd9c3f2ef);
  END IF;
END $mj$;

-- Save MJ: Entity Fields (core SP call only)
DO $mj$
DECLARE
  p_DisplayName_5fb54378aeb0 VARCHAR(255);
  p_Description_5fb54378aeb0 TEXT;
  p_AutoUpdateDescription_5fb54378aeb0 BOOLEAN;
  p_IsPrimaryKey_5fb54378aeb0 BOOLEAN;
  p_IsUnique_5fb54378aeb0 BOOLEAN;
  p_Category_5fb54378aeb0 VARCHAR(255);
  p_ValueListType_5fb54378aeb0 VARCHAR(20);
  p_ExtendedType_5fb54378aeb0 VARCHAR(50);
  p_CodeType_5fb54378aeb0 VARCHAR(50);
  p_DefaultInView_5fb54378aeb0 BOOLEAN;
  p_ViewCellTemplate_5fb54378aeb0 TEXT;
  p_DefaultColumnWidth_5fb54378aeb0 INTEGER;
  p_AllowUpdateAPI_5fb54378aeb0 BOOLEAN;
  p_AllowUpdateInView_5fb54378aeb0 BOOLEAN;
  p_IncludeInUserSearchAPI_5fb54378aeb0 BOOLEAN;
  p_FullTextSearchEnabled_5fb54378aeb0 BOOLEAN;
  p_UserSearchParamFormatAPI_5fb54378aeb0 VARCHAR(500);
  p_IncludeInGeneratedForm_5fb54378aeb0 BOOLEAN;
  p_GeneratedFormSection_5fb54378aeb0 VARCHAR(10);
  p_IsNameField_5fb54378aeb0 BOOLEAN;
  p_RelatedEntityID_5fb54378aeb0 UUID;
  p_RelatedEntityFieldName_5fb54378aeb0 VARCHAR(255);
  p_IncludeRelatedEntityNameFieldInBaseView_5fb54378aeb0 BOOLEAN;
  p_RelatedEntityNameFieldMap_5fb54378aeb0 VARCHAR(255);
  p_RelatedEntityDisplayType_5fb54378aeb0 VARCHAR(20);
  p_EntityIDFieldName_5fb54378aeb0 VARCHAR(100);
  p_ScopeDefault_5fb54378aeb0 VARCHAR(100);
  p_AutoUpdateRelatedEntityInfo_5fb54378aeb0 BOOLEAN;
  p_ValuesToPackWithSchema_5fb54378aeb0 VARCHAR(10);
  p_Status_5fb54378aeb0 VARCHAR(25);
  p_AutoUpdateIsNameField_5fb54378aeb0 BOOLEAN;
  p_AutoUpdateDefaultInView_5fb54378aeb0 BOOLEAN;
  p_AutoUpdateCategory_5fb54378aeb0 BOOLEAN;
  p_AutoUpdateDisplayName_5fb54378aeb0 BOOLEAN;
  p_AutoUpdateIncludeInUserSearchAPI_5fb54378aeb0 BOOLEAN;
  p_Encrypt_5fb54378aeb0 BOOLEAN;
  p_EncryptionKeyID_5fb54378aeb0 UUID;
  p_AllowDecryptInAPI_5fb54378aeb0 BOOLEAN;
  p_SendEncryptedValue_5fb54378aeb0 BOOLEAN;
  p_IsSoftPrimaryKey_5fb54378aeb0 BOOLEAN;
  p_IsSoftForeignKey_5fb54378aeb0 BOOLEAN;
  p_RelatedEntityJoinFields_5fb54378aeb0 TEXT;
  p_JSONType_5fb54378aeb0 VARCHAR(255);
  p_JSONTypeIsArray_5fb54378aeb0 BOOLEAN;
  p_JSONTypeDefinition_5fb54378aeb0 TEXT;
  p_UserSearchPredicateAPI_5fb54378aeb0 VARCHAR(20);
  p_AutoUpdateUserSearchPredicate_5fb54378aeb0 BOOLEAN;
  p_AutoUpdateFullTextSearch_5fb54378aeb0 BOOLEAN;
  p_AutoUpdateExtendedType_5fb54378aeb0 BOOLEAN;
  p_IsComputed_5fb54378aeb0 BOOLEAN;
  p_EmbeddedRecord_5fb54378aeb0 TEXT;
  p_Configuration_5fb54378aeb0 TEXT;
  p_ID_5fb54378aeb0 UUID;
BEGIN
  p_DisplayName_5fb54378aeb0 := 'Address';
  p_AutoUpdateDescription_5fb54378aeb0 := TRUE;
  p_IsPrimaryKey_5fb54378aeb0 := FALSE;
  p_IsUnique_5fb54378aeb0 := FALSE;
  p_Category_5fb54378aeb0 := 'Linkage Details';
  p_ValueListType_5fb54378aeb0 := 'None';
  p_DefaultInView_5fb54378aeb0 := TRUE;
  p_DefaultColumnWidth_5fb54378aeb0 := 150;
  p_AllowUpdateAPI_5fb54378aeb0 := FALSE;
  p_AllowUpdateInView_5fb54378aeb0 := TRUE;
  p_IncludeInUserSearchAPI_5fb54378aeb0 := FALSE;
  p_FullTextSearchEnabled_5fb54378aeb0 := FALSE;
  p_IncludeInGeneratedForm_5fb54378aeb0 := TRUE;
  p_GeneratedFormSection_5fb54378aeb0 := 'Category';
  p_IsNameField_5fb54378aeb0 := TRUE;
  p_IncludeRelatedEntityNameFieldInBaseView_5fb54378aeb0 := FALSE;
  p_RelatedEntityDisplayType_5fb54378aeb0 := 'Search';
  p_AutoUpdateRelatedEntityInfo_5fb54378aeb0 := TRUE;
  p_ValuesToPackWithSchema_5fb54378aeb0 := 'Auto';
  p_Status_5fb54378aeb0 := 'Active';
  p_AutoUpdateIsNameField_5fb54378aeb0 := FALSE;
  p_AutoUpdateDefaultInView_5fb54378aeb0 := TRUE;
  p_AutoUpdateCategory_5fb54378aeb0 := TRUE;
  p_AutoUpdateDisplayName_5fb54378aeb0 := TRUE;
  p_AutoUpdateIncludeInUserSearchAPI_5fb54378aeb0 := TRUE;
  p_Encrypt_5fb54378aeb0 := FALSE;
  p_AllowDecryptInAPI_5fb54378aeb0 := FALSE;
  p_SendEncryptedValue_5fb54378aeb0 := FALSE;
  p_IsSoftPrimaryKey_5fb54378aeb0 := FALSE;
  p_IsSoftForeignKey_5fb54378aeb0 := FALSE;
  p_JSONTypeIsArray_5fb54378aeb0 := FALSE;
  p_UserSearchPredicateAPI_5fb54378aeb0 := 'Contains';
  p_AutoUpdateUserSearchPredicate_5fb54378aeb0 := TRUE;
  p_AutoUpdateFullTextSearch_5fb54378aeb0 := TRUE;
  p_AutoUpdateExtendedType_5fb54378aeb0 := FALSE;
  p_IsComputed_5fb54378aeb0 := FALSE;
  p_ID_5fb54378aeb0 := '99D4FE49-BC0B-4D9D-B7EC-84E04F7281EE';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityField'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_data := jsonb_build_object(
    'DisplayName', p_DisplayName_5fb54378aeb0,
    'Description', p_Description_5fb54378aeb0,
    'AutoUpdateDescription', p_AutoUpdateDescription_5fb54378aeb0,
    'IsPrimaryKey', p_IsPrimaryKey_5fb54378aeb0,
    'IsUnique', p_IsUnique_5fb54378aeb0,
    'Category', p_Category_5fb54378aeb0,
    'ValueListType', p_ValueListType_5fb54378aeb0,
    'ExtendedType', p_ExtendedType_5fb54378aeb0,
    'CodeType', p_CodeType_5fb54378aeb0,
    'DefaultInView', p_DefaultInView_5fb54378aeb0,
    'ViewCellTemplate', p_ViewCellTemplate_5fb54378aeb0,
    'DefaultColumnWidth', p_DefaultColumnWidth_5fb54378aeb0,
    'AllowUpdateAPI', p_AllowUpdateAPI_5fb54378aeb0,
    'AllowUpdateInView', p_AllowUpdateInView_5fb54378aeb0,
    'IncludeInUserSearchAPI', p_IncludeInUserSearchAPI_5fb54378aeb0,
    'FullTextSearchEnabled', p_FullTextSearchEnabled_5fb54378aeb0,
    'UserSearchParamFormatAPI', p_UserSearchParamFormatAPI_5fb54378aeb0,
    'IncludeInGeneratedForm', p_IncludeInGeneratedForm_5fb54378aeb0,
    'GeneratedFormSection', p_GeneratedFormSection_5fb54378aeb0,
    'IsNameField', p_IsNameField_5fb54378aeb0,
    'RelatedEntityID', p_RelatedEntityID_5fb54378aeb0,
    'RelatedEntityFieldName', p_RelatedEntityFieldName_5fb54378aeb0,
    'IncludeRelatedEntityNameFieldInBaseView', p_IncludeRelatedEntityNameFieldInBaseView_5fb54378aeb0,
    'RelatedEntityNameFieldMap', p_RelatedEntityNameFieldMap_5fb54378aeb0,
    'RelatedEntityDisplayType', p_RelatedEntityDisplayType_5fb54378aeb0,
    'EntityIDFieldName', p_EntityIDFieldName_5fb54378aeb0,
    'ScopeDefault', p_ScopeDefault_5fb54378aeb0,
    'AutoUpdateRelatedEntityInfo', p_AutoUpdateRelatedEntityInfo_5fb54378aeb0,
    'ValuesToPackWithSchema', p_ValuesToPackWithSchema_5fb54378aeb0,
    'Status', p_Status_5fb54378aeb0,
    'AutoUpdateIsNameField', p_AutoUpdateIsNameField_5fb54378aeb0,
    'AutoUpdateDefaultInView', p_AutoUpdateDefaultInView_5fb54378aeb0,
    'AutoUpdateCategory', p_AutoUpdateCategory_5fb54378aeb0,
    'AutoUpdateDisplayName', p_AutoUpdateDisplayName_5fb54378aeb0,
    'AutoUpdateIncludeInUserSearchAPI', p_AutoUpdateIncludeInUserSearchAPI_5fb54378aeb0,
    'Encrypt', p_Encrypt_5fb54378aeb0,
    'EncryptionKeyID', p_EncryptionKeyID_5fb54378aeb0,
    'AllowDecryptInAPI', p_AllowDecryptInAPI_5fb54378aeb0,
    'SendEncryptedValue', p_SendEncryptedValue_5fb54378aeb0,
    'IsSoftPrimaryKey', p_IsSoftPrimaryKey_5fb54378aeb0,
    'IsSoftForeignKey', p_IsSoftForeignKey_5fb54378aeb0,
    'RelatedEntityJoinFields', p_RelatedEntityJoinFields_5fb54378aeb0,
    'JSONType', p_JSONType_5fb54378aeb0,
    'JSONTypeIsArray', p_JSONTypeIsArray_5fb54378aeb0,
    'JSONTypeDefinition', p_JSONTypeDefinition_5fb54378aeb0,
    'UserSearchPredicateAPI', p_UserSearchPredicateAPI_5fb54378aeb0,
    'AutoUpdateUserSearchPredicate', p_AutoUpdateUserSearchPredicate_5fb54378aeb0,
    'AutoUpdateFullTextSearch', p_AutoUpdateFullTextSearch_5fb54378aeb0,
    'AutoUpdateExtendedType', p_AutoUpdateExtendedType_5fb54378aeb0,
    'IsComputed', p_IsComputed_5fb54378aeb0
  ) ||
  jsonb_build_object(
    'EmbeddedRecord', p_EmbeddedRecord_5fb54378aeb0,
    'Configuration', p_Configuration_5fb54378aeb0,
    'ID', p_ID_5fb54378aeb0
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_DisplayName := p_DisplayName_5fb54378aeb0, p_Description := p_Description_5fb54378aeb0, p_Description_Clear := TRUE, p_AutoUpdateDescription := p_AutoUpdateDescription_5fb54378aeb0, p_IsPrimaryKey := p_IsPrimaryKey_5fb54378aeb0, p_IsUnique := p_IsUnique_5fb54378aeb0, p_Category := p_Category_5fb54378aeb0, p_ValueListType := p_ValueListType_5fb54378aeb0, p_ExtendedType := p_ExtendedType_5fb54378aeb0, p_ExtendedType_Clear := TRUE, p_CodeType := p_CodeType_5fb54378aeb0, p_CodeType_Clear := TRUE, p_DefaultInView := p_DefaultInView_5fb54378aeb0, p_ViewCellTemplate := p_ViewCellTemplate_5fb54378aeb0, p_ViewCellTemplate_Clear := TRUE, p_DefaultColumnWidth := p_DefaultColumnWidth_5fb54378aeb0, p_AllowUpdateAPI := p_AllowUpdateAPI_5fb54378aeb0, p_AllowUpdateInView := p_AllowUpdateInView_5fb54378aeb0, p_IncludeInUserSearchAPI := p_IncludeInUserSearchAPI_5fb54378aeb0, p_FullTextSearchEnabled := p_FullTextSearchEnabled_5fb54378aeb0, p_UserSearchParamFormatAPI := p_UserSearchParamFormatAPI_5fb54378aeb0, p_UserSearchParamFormatAPI_Clear := TRUE, p_IncludeInGeneratedForm := p_IncludeInGeneratedForm_5fb54378aeb0, p_GeneratedFormSection := p_GeneratedFormSection_5fb54378aeb0, p_IsNameField := p_IsNameField_5fb54378aeb0, p_RelatedEntityID := p_RelatedEntityID_5fb54378aeb0, p_RelatedEntityID_Clear := TRUE, p_RelatedEntityFieldName := p_RelatedEntityFieldName_5fb54378aeb0, p_RelatedEntityFieldName_Clear := TRUE, p_IncludeRelatedEntityNameFieldInBaseView := p_IncludeRelatedEntityNameFieldInBaseView_5fb54378aeb0, p_RelatedEntityNameFieldMap := p_RelatedEntityNameFieldMap_5fb54378aeb0, p_RelatedEntityNameFieldMap_Clear := TRUE, p_RelatedEntityDisplayType := p_RelatedEntityDisplayType_5fb54378aeb0, p_EntityIDFieldName := p_EntityIDFieldName_5fb54378aeb0, p_EntityIDFieldName_Clear := TRUE, p_ScopeDefault := p_ScopeDefault_5fb54378aeb0, p_ScopeDefault_Clear := TRUE, p_AutoUpdateRelatedEntityInfo := p_AutoUpdateRelatedEntityInfo_5fb54378aeb0, p_ValuesToPackWithSchema := p_ValuesToPackWithSchema_5fb54378aeb0, p_Status := p_Status_5fb54378aeb0, p_AutoUpdateIsNameField := p_AutoUpdateIsNameField_5fb54378aeb0, p_AutoUpdateDefaultInView := p_AutoUpdateDefaultInView_5fb54378aeb0, p_AutoUpdateCategory := p_AutoUpdateCategory_5fb54378aeb0, p_AutoUpdateDisplayName := p_AutoUpdateDisplayName_5fb54378aeb0, p_AutoUpdateIncludeInUserSearchAPI := p_AutoUpdateIncludeInUserSearchAPI_5fb54378aeb0, p_Encrypt := p_Encrypt_5fb54378aeb0, p_EncryptionKeyID := p_EncryptionKeyID_5fb54378aeb0, p_EncryptionKeyID_Clear := TRUE, p_AllowDecryptInAPI := p_AllowDecryptInAPI_5fb54378aeb0, p_SendEncryptedValue := p_SendEncryptedValue_5fb54378aeb0, p_IsSoftPrimaryKey := p_IsSoftPrimaryKey_5fb54378aeb0, p_IsSoftForeignKey := p_IsSoftForeignKey_5fb54378aeb0, p_RelatedEntityJoinFields := p_RelatedEntityJoinFields_5fb54378aeb0, p_RelatedEntityJoinFields_Clear := TRUE, p_JSONType := p_JSONType_5fb54378aeb0, p_JSONType_Clear := TRUE, p_JSONTypeIsArray := p_JSONTypeIsArray_5fb54378aeb0, p_JSONTypeDefinition := p_JSONTypeDefinition_5fb54378aeb0, p_JSONTypeDefinition_Clear := TRUE, p_UserSearchPredicateAPI := p_UserSearchPredicateAPI_5fb54378aeb0, p_AutoUpdateUserSearchPredicate := p_AutoUpdateUserSearchPredicate_5fb54378aeb0, p_AutoUpdateFullTextSearch := p_AutoUpdateFullTextSearch_5fb54378aeb0, p_AutoUpdateExtendedType := p_AutoUpdateExtendedType_5fb54378aeb0, p_IsComputed := p_IsComputed_5fb54378aeb0, p_EmbeddedRecord := p_EmbeddedRecord_5fb54378aeb0, p_EmbeddedRecord_Clear := TRUE, p_Configuration := p_Configuration_5fb54378aeb0, p_Configuration_Clear := TRUE, p_ID := p_ID_5fb54378aeb0);
  END IF;
END $mj$;

-- Save MJ: Entity Fields (core SP call only)
DO $mj$
DECLARE
  p_DisplayName_ff37120579c9 VARCHAR(255);
  p_Description_ff37120579c9 TEXT;
  p_AutoUpdateDescription_ff37120579c9 BOOLEAN;
  p_IsPrimaryKey_ff37120579c9 BOOLEAN;
  p_IsUnique_ff37120579c9 BOOLEAN;
  p_Category_ff37120579c9 VARCHAR(255);
  p_ValueListType_ff37120579c9 VARCHAR(20);
  p_ExtendedType_ff37120579c9 VARCHAR(50);
  p_CodeType_ff37120579c9 VARCHAR(50);
  p_DefaultInView_ff37120579c9 BOOLEAN;
  p_ViewCellTemplate_ff37120579c9 TEXT;
  p_DefaultColumnWidth_ff37120579c9 INTEGER;
  p_AllowUpdateAPI_ff37120579c9 BOOLEAN;
  p_AllowUpdateInView_ff37120579c9 BOOLEAN;
  p_IncludeInUserSearchAPI_ff37120579c9 BOOLEAN;
  p_FullTextSearchEnabled_ff37120579c9 BOOLEAN;
  p_UserSearchParamFormatAPI_ff37120579c9 VARCHAR(500);
  p_IncludeInGeneratedForm_ff37120579c9 BOOLEAN;
  p_GeneratedFormSection_ff37120579c9 VARCHAR(10);
  p_IsNameField_ff37120579c9 BOOLEAN;
  p_RelatedEntityID_ff37120579c9 UUID;
  p_RelatedEntityFieldName_ff37120579c9 VARCHAR(255);
  p_IncludeRelatedEntityNameFieldInBaseView_ff37120579c9 BOOLEAN;
  p_RelatedEntityNameFieldMap_ff37120579c9 VARCHAR(255);
  p_RelatedEntityDisplayType_ff37120579c9 VARCHAR(20);
  p_EntityIDFieldName_ff37120579c9 VARCHAR(100);
  p_ScopeDefault_ff37120579c9 VARCHAR(100);
  p_AutoUpdateRelatedEntityInfo_ff37120579c9 BOOLEAN;
  p_ValuesToPackWithSchema_ff37120579c9 VARCHAR(10);
  p_Status_ff37120579c9 VARCHAR(25);
  p_AutoUpdateIsNameField_ff37120579c9 BOOLEAN;
  p_AutoUpdateDefaultInView_ff37120579c9 BOOLEAN;
  p_AutoUpdateCategory_ff37120579c9 BOOLEAN;
  p_AutoUpdateDisplayName_ff37120579c9 BOOLEAN;
  p_AutoUpdateIncludeInUserSearchAPI_ff37120579c9 BOOLEAN;
  p_Encrypt_ff37120579c9 BOOLEAN;
  p_EncryptionKeyID_ff37120579c9 UUID;
  p_AllowDecryptInAPI_ff37120579c9 BOOLEAN;
  p_SendEncryptedValue_ff37120579c9 BOOLEAN;
  p_IsSoftPrimaryKey_ff37120579c9 BOOLEAN;
  p_IsSoftForeignKey_ff37120579c9 BOOLEAN;
  p_RelatedEntityJoinFields_ff37120579c9 TEXT;
  p_JSONType_ff37120579c9 VARCHAR(255);
  p_JSONTypeIsArray_ff37120579c9 BOOLEAN;
  p_JSONTypeDefinition_ff37120579c9 TEXT;
  p_UserSearchPredicateAPI_ff37120579c9 VARCHAR(20);
  p_AutoUpdateUserSearchPredicate_ff37120579c9 BOOLEAN;
  p_AutoUpdateFullTextSearch_ff37120579c9 BOOLEAN;
  p_AutoUpdateExtendedType_ff37120579c9 BOOLEAN;
  p_IsComputed_ff37120579c9 BOOLEAN;
  p_EmbeddedRecord_ff37120579c9 TEXT;
  p_Configuration_ff37120579c9 TEXT;
  p_ID_ff37120579c9 UUID;
BEGIN
  p_DisplayName_ff37120579c9 := 'Address Type Name';
  p_AutoUpdateDescription_ff37120579c9 := TRUE;
  p_IsPrimaryKey_ff37120579c9 := FALSE;
  p_IsUnique_ff37120579c9 := FALSE;
  p_Category_ff37120579c9 := 'Address Preferences';
  p_ValueListType_ff37120579c9 := 'None';
  p_DefaultInView_ff37120579c9 := TRUE;
  p_DefaultColumnWidth_ff37120579c9 := 150;
  p_AllowUpdateAPI_ff37120579c9 := FALSE;
  p_AllowUpdateInView_ff37120579c9 := TRUE;
  p_IncludeInUserSearchAPI_ff37120579c9 := TRUE;
  p_FullTextSearchEnabled_ff37120579c9 := FALSE;
  p_IncludeInGeneratedForm_ff37120579c9 := TRUE;
  p_GeneratedFormSection_ff37120579c9 := 'Category';
  p_IsNameField_ff37120579c9 := FALSE;
  p_IncludeRelatedEntityNameFieldInBaseView_ff37120579c9 := FALSE;
  p_RelatedEntityDisplayType_ff37120579c9 := 'Search';
  p_AutoUpdateRelatedEntityInfo_ff37120579c9 := TRUE;
  p_ValuesToPackWithSchema_ff37120579c9 := 'Auto';
  p_Status_ff37120579c9 := 'Active';
  p_AutoUpdateIsNameField_ff37120579c9 := FALSE;
  p_AutoUpdateDefaultInView_ff37120579c9 := TRUE;
  p_AutoUpdateCategory_ff37120579c9 := TRUE;
  p_AutoUpdateDisplayName_ff37120579c9 := TRUE;
  p_AutoUpdateIncludeInUserSearchAPI_ff37120579c9 := TRUE;
  p_Encrypt_ff37120579c9 := FALSE;
  p_AllowDecryptInAPI_ff37120579c9 := FALSE;
  p_SendEncryptedValue_ff37120579c9 := FALSE;
  p_IsSoftPrimaryKey_ff37120579c9 := FALSE;
  p_IsSoftForeignKey_ff37120579c9 := FALSE;
  p_JSONTypeIsArray_ff37120579c9 := FALSE;
  p_UserSearchPredicateAPI_ff37120579c9 := 'Contains';
  p_AutoUpdateUserSearchPredicate_ff37120579c9 := TRUE;
  p_AutoUpdateFullTextSearch_ff37120579c9 := TRUE;
  p_AutoUpdateExtendedType_ff37120579c9 := TRUE;
  p_IsComputed_ff37120579c9 := FALSE;
  p_ID_ff37120579c9 := 'E79C20C4-B9D9-433F-BD0E-5134829F1A25';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateEntityField'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_data := jsonb_build_object(
    'DisplayName', p_DisplayName_ff37120579c9,
    'Description', p_Description_ff37120579c9,
    'AutoUpdateDescription', p_AutoUpdateDescription_ff37120579c9,
    'IsPrimaryKey', p_IsPrimaryKey_ff37120579c9,
    'IsUnique', p_IsUnique_ff37120579c9,
    'Category', p_Category_ff37120579c9,
    'ValueListType', p_ValueListType_ff37120579c9,
    'ExtendedType', p_ExtendedType_ff37120579c9,
    'CodeType', p_CodeType_ff37120579c9,
    'DefaultInView', p_DefaultInView_ff37120579c9,
    'ViewCellTemplate', p_ViewCellTemplate_ff37120579c9,
    'DefaultColumnWidth', p_DefaultColumnWidth_ff37120579c9,
    'AllowUpdateAPI', p_AllowUpdateAPI_ff37120579c9,
    'AllowUpdateInView', p_AllowUpdateInView_ff37120579c9,
    'IncludeInUserSearchAPI', p_IncludeInUserSearchAPI_ff37120579c9,
    'FullTextSearchEnabled', p_FullTextSearchEnabled_ff37120579c9,
    'UserSearchParamFormatAPI', p_UserSearchParamFormatAPI_ff37120579c9,
    'IncludeInGeneratedForm', p_IncludeInGeneratedForm_ff37120579c9,
    'GeneratedFormSection', p_GeneratedFormSection_ff37120579c9,
    'IsNameField', p_IsNameField_ff37120579c9,
    'RelatedEntityID', p_RelatedEntityID_ff37120579c9,
    'RelatedEntityFieldName', p_RelatedEntityFieldName_ff37120579c9,
    'IncludeRelatedEntityNameFieldInBaseView', p_IncludeRelatedEntityNameFieldInBaseView_ff37120579c9,
    'RelatedEntityNameFieldMap', p_RelatedEntityNameFieldMap_ff37120579c9,
    'RelatedEntityDisplayType', p_RelatedEntityDisplayType_ff37120579c9,
    'EntityIDFieldName', p_EntityIDFieldName_ff37120579c9,
    'ScopeDefault', p_ScopeDefault_ff37120579c9,
    'AutoUpdateRelatedEntityInfo', p_AutoUpdateRelatedEntityInfo_ff37120579c9,
    'ValuesToPackWithSchema', p_ValuesToPackWithSchema_ff37120579c9,
    'Status', p_Status_ff37120579c9,
    'AutoUpdateIsNameField', p_AutoUpdateIsNameField_ff37120579c9,
    'AutoUpdateDefaultInView', p_AutoUpdateDefaultInView_ff37120579c9,
    'AutoUpdateCategory', p_AutoUpdateCategory_ff37120579c9,
    'AutoUpdateDisplayName', p_AutoUpdateDisplayName_ff37120579c9,
    'AutoUpdateIncludeInUserSearchAPI', p_AutoUpdateIncludeInUserSearchAPI_ff37120579c9,
    'Encrypt', p_Encrypt_ff37120579c9,
    'EncryptionKeyID', p_EncryptionKeyID_ff37120579c9,
    'AllowDecryptInAPI', p_AllowDecryptInAPI_ff37120579c9,
    'SendEncryptedValue', p_SendEncryptedValue_ff37120579c9,
    'IsSoftPrimaryKey', p_IsSoftPrimaryKey_ff37120579c9,
    'IsSoftForeignKey', p_IsSoftForeignKey_ff37120579c9,
    'RelatedEntityJoinFields', p_RelatedEntityJoinFields_ff37120579c9,
    'JSONType', p_JSONType_ff37120579c9,
    'JSONTypeIsArray', p_JSONTypeIsArray_ff37120579c9,
    'JSONTypeDefinition', p_JSONTypeDefinition_ff37120579c9,
    'UserSearchPredicateAPI', p_UserSearchPredicateAPI_ff37120579c9,
    'AutoUpdateUserSearchPredicate', p_AutoUpdateUserSearchPredicate_ff37120579c9,
    'AutoUpdateFullTextSearch', p_AutoUpdateFullTextSearch_ff37120579c9,
    'AutoUpdateExtendedType', p_AutoUpdateExtendedType_ff37120579c9,
    'IsComputed', p_IsComputed_ff37120579c9
  ) ||
  jsonb_build_object(
    'EmbeddedRecord', p_EmbeddedRecord_ff37120579c9,
    'Configuration', p_Configuration_ff37120579c9,
    'ID', p_ID_ff37120579c9
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateEntityField"(p_DisplayName := p_DisplayName_ff37120579c9, p_Description := p_Description_ff37120579c9, p_Description_Clear := TRUE, p_AutoUpdateDescription := p_AutoUpdateDescription_ff37120579c9, p_IsPrimaryKey := p_IsPrimaryKey_ff37120579c9, p_IsUnique := p_IsUnique_ff37120579c9, p_Category := p_Category_ff37120579c9, p_ValueListType := p_ValueListType_ff37120579c9, p_ExtendedType := p_ExtendedType_ff37120579c9, p_ExtendedType_Clear := TRUE, p_CodeType := p_CodeType_ff37120579c9, p_CodeType_Clear := TRUE, p_DefaultInView := p_DefaultInView_ff37120579c9, p_ViewCellTemplate := p_ViewCellTemplate_ff37120579c9, p_ViewCellTemplate_Clear := TRUE, p_DefaultColumnWidth := p_DefaultColumnWidth_ff37120579c9, p_AllowUpdateAPI := p_AllowUpdateAPI_ff37120579c9, p_AllowUpdateInView := p_AllowUpdateInView_ff37120579c9, p_IncludeInUserSearchAPI := p_IncludeInUserSearchAPI_ff37120579c9, p_FullTextSearchEnabled := p_FullTextSearchEnabled_ff37120579c9, p_UserSearchParamFormatAPI := p_UserSearchParamFormatAPI_ff37120579c9, p_UserSearchParamFormatAPI_Clear := TRUE, p_IncludeInGeneratedForm := p_IncludeInGeneratedForm_ff37120579c9, p_GeneratedFormSection := p_GeneratedFormSection_ff37120579c9, p_IsNameField := p_IsNameField_ff37120579c9, p_RelatedEntityID := p_RelatedEntityID_ff37120579c9, p_RelatedEntityID_Clear := TRUE, p_RelatedEntityFieldName := p_RelatedEntityFieldName_ff37120579c9, p_RelatedEntityFieldName_Clear := TRUE, p_IncludeRelatedEntityNameFieldInBaseView := p_IncludeRelatedEntityNameFieldInBaseView_ff37120579c9, p_RelatedEntityNameFieldMap := p_RelatedEntityNameFieldMap_ff37120579c9, p_RelatedEntityNameFieldMap_Clear := TRUE, p_RelatedEntityDisplayType := p_RelatedEntityDisplayType_ff37120579c9, p_EntityIDFieldName := p_EntityIDFieldName_ff37120579c9, p_EntityIDFieldName_Clear := TRUE, p_ScopeDefault := p_ScopeDefault_ff37120579c9, p_ScopeDefault_Clear := TRUE, p_AutoUpdateRelatedEntityInfo := p_AutoUpdateRelatedEntityInfo_ff37120579c9, p_ValuesToPackWithSchema := p_ValuesToPackWithSchema_ff37120579c9, p_Status := p_Status_ff37120579c9, p_AutoUpdateIsNameField := p_AutoUpdateIsNameField_ff37120579c9, p_AutoUpdateDefaultInView := p_AutoUpdateDefaultInView_ff37120579c9, p_AutoUpdateCategory := p_AutoUpdateCategory_ff37120579c9, p_AutoUpdateDisplayName := p_AutoUpdateDisplayName_ff37120579c9, p_AutoUpdateIncludeInUserSearchAPI := p_AutoUpdateIncludeInUserSearchAPI_ff37120579c9, p_Encrypt := p_Encrypt_ff37120579c9, p_EncryptionKeyID := p_EncryptionKeyID_ff37120579c9, p_EncryptionKeyID_Clear := TRUE, p_AllowDecryptInAPI := p_AllowDecryptInAPI_ff37120579c9, p_SendEncryptedValue := p_SendEncryptedValue_ff37120579c9, p_IsSoftPrimaryKey := p_IsSoftPrimaryKey_ff37120579c9, p_IsSoftForeignKey := p_IsSoftForeignKey_ff37120579c9, p_RelatedEntityJoinFields := p_RelatedEntityJoinFields_ff37120579c9, p_RelatedEntityJoinFields_Clear := TRUE, p_JSONType := p_JSONType_ff37120579c9, p_JSONType_Clear := TRUE, p_JSONTypeIsArray := p_JSONTypeIsArray_ff37120579c9, p_JSONTypeDefinition := p_JSONTypeDefinition_ff37120579c9, p_JSONTypeDefinition_Clear := TRUE, p_UserSearchPredicateAPI := p_UserSearchPredicateAPI_ff37120579c9, p_AutoUpdateUserSearchPredicate := p_AutoUpdateUserSearchPredicate_ff37120579c9, p_AutoUpdateFullTextSearch := p_AutoUpdateFullTextSearch_ff37120579c9, p_AutoUpdateExtendedType := p_AutoUpdateExtendedType_ff37120579c9, p_IsComputed := p_IsComputed_ff37120579c9, p_EmbeddedRecord := p_EmbeddedRecord_ff37120579c9, p_EmbeddedRecord_Clear := TRUE, p_Configuration := p_Configuration_ff37120579c9, p_Configuration_Clear := TRUE, p_ID := p_ID_ff37120579c9);
  END IF;
END $mj$;
