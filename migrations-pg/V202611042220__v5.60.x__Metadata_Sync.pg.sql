-- =============================================================================================
-- PostgreSQL counterpart of V202611042220__v5.60.x__Metadata_Sync.sql -- BizApps Common v5.60.x Metadata_Sync
-- =============================================================================================
-- Same records, same values, same order as the T-SQL file; see its header for what ships and why.
--
-- HOW IT WAS MADE
--   * `mj sql-convert --from tsql --to postgres` (MJ CLI 6.1.6) on the push log the T-SQL file was
--     generated from. Each record is a DO block that calls the function in whichever signature the
--     host has (jsonb or named parameters).
--   * The converter emitted the AI Prompt Model and Record Process blocks with an empty DECLARE
--     and no assignments (a variant of MemberJunction/MJ#5918). Their declarations and values are
--     written here by hand from the T-SQL file, by the same mapping the converter applied to the AI
--     Prompt block: UNIQUEIDENTIFIER -> UUID, NVARCHAR(n) -> VARCHAR(n), NVARCHAR(MAX) -> TEXT,
--     BIT -> BOOLEAN (1/0 -> TRUE/FALSE), INT -> INTEGER.
--   * Core calls use ${mjSchema}.
--   * Every string value is taken verbatim from the T-SQL file, including the
--     [__mj_BizAppsCommon] reference inside the Record Process ScopeFilter.
-- =============================================================================================

-- Save MJ: AI Prompts (core SP call only)
DO $mj$
DECLARE
  p_Name_c807cfd04459 VARCHAR(255);
  p_Description_c807cfd04459 TEXT;
  p_TemplateID_c807cfd04459 UUID;
  p_CategoryID_c807cfd04459 UUID;
  p_TypeID_c807cfd04459 UUID;
  p_Status_c807cfd04459 VARCHAR(50);
  p_ResponseFormat_c807cfd04459 VARCHAR(20);
  p_ModelSpecificResponseFormat_c807cfd04459 TEXT;
  p_AIModelTypeID_c807cfd04459 UUID;
  p_MinPowerRank_c807cfd04459 INTEGER;
  p_SelectionStrategy_c807cfd04459 VARCHAR(20);
  p_PowerPreference_c807cfd04459 VARCHAR(20);
  p_ParallelizationMode_c807cfd04459 VARCHAR(20);
  p_ParallelCount_c807cfd04459 INTEGER;
  p_ParallelConfigParam_c807cfd04459 VARCHAR(100);
  p_OutputType_c807cfd04459 VARCHAR(50);
  p_OutputExample_c807cfd04459 TEXT;
  p_ValidationBehavior_c807cfd04459 VARCHAR(50);
  p_MaxRetries_c807cfd04459 INTEGER;
  p_RetryDelayMS_c807cfd04459 INTEGER;
  p_RetryStrategy_c807cfd04459 VARCHAR(20);
  p_ResultSelectorPromptID_c807cfd04459 UUID;
  p_EnableCaching_c807cfd04459 BOOLEAN;
  p_CacheTTLSeconds_c807cfd04459 INTEGER;
  p_CacheMatchType_c807cfd04459 VARCHAR(20);
  p_CacheSimilarityThreshold_c807cfd04459 DOUBLE PRECISION;
  p_CacheMustMatchModel_c807cfd04459 BOOLEAN;
  p_CacheMustMatchVendor_c807cfd04459 BOOLEAN;
  p_CacheMustMatchAgent_c807cfd04459 BOOLEAN;
  p_CacheMustMatchConfig_c807cfd04459 BOOLEAN;
  p_PromptRole_c807cfd04459 VARCHAR(20);
  p_PromptPosition_c807cfd04459 VARCHAR(20);
  p_Temperature_c807cfd04459 NUMERIC(3,2);
  p_TopP_c807cfd04459 NUMERIC(3,2);
  p_TopK_c807cfd04459 INTEGER;
  p_MinP_c807cfd04459 NUMERIC(3,2);
  p_FrequencyPenalty_c807cfd04459 NUMERIC(3,2);
  p_PresencePenalty_c807cfd04459 NUMERIC(3,2);
  p_Seed_c807cfd04459 INTEGER;
  p_StopSequences_c807cfd04459 VARCHAR(1000);
  p_IncludeLogProbs_c807cfd04459 BOOLEAN;
  p_TopLogProbs_c807cfd04459 INTEGER;
  p_FailoverStrategy_c807cfd04459 VARCHAR(50);
  p_FailoverMaxAttempts_c807cfd04459 INTEGER;
  p_FailoverDelaySeconds_c807cfd04459 INTEGER;
  p_FailoverModelStrategy_c807cfd04459 VARCHAR(50);
  p_FailoverErrorScope_c807cfd04459 VARCHAR(50);
  p_EffortLevel_c807cfd04459 INTEGER;
  p_AssistantPrefill_c807cfd04459 TEXT;
  p_PrefillFallbackMode_c807cfd04459 VARCHAR(20);
  p_RequireSpecificModels_c807cfd04459 BOOLEAN;
  p_PromptConfiguration_c807cfd04459 TEXT;
  p_ID_c807cfd04459 UUID;
BEGIN
  p_Name_c807cfd04459 := 'Job Function and Seniority Derivation';
  p_Description_c807cfd04459 := 'Derives job functions (plural child rows) and seniority level (FK field) from a person''s current job title using LLM inference with deduplicating feature value caching.';
  p_TemplateID_c807cfd04459 := 'B8221E1A-F5DB-4C71-8196-944EA959E82A';
  p_CategoryID_c807cfd04459 := '7D2DEF7F-138F-4620-8309-33964A97A997';
  p_TypeID_c807cfd04459 := 'A6DA423E-F36B-1410-8DAC-00021F8B792E';
  p_Status_c807cfd04459 := 'Active';
  p_ResponseFormat_c807cfd04459 := 'JSON';
  p_MinPowerRank_c807cfd04459 := 0;
  p_SelectionStrategy_c807cfd04459 := 'Specific';
  p_PowerPreference_c807cfd04459 := 'Lowest';
  p_ParallelizationMode_c807cfd04459 := 'None';
  p_OutputType_c807cfd04459 := 'string';
  p_ValidationBehavior_c807cfd04459 := 'Warn';
  p_MaxRetries_c807cfd04459 := 3;
  p_RetryDelayMS_c807cfd04459 := 3000;
  p_RetryStrategy_c807cfd04459 := 'Exponential';
  p_EnableCaching_c807cfd04459 := FALSE;
  p_CacheMatchType_c807cfd04459 := 'Exact';
  p_CacheMustMatchModel_c807cfd04459 := TRUE;
  p_CacheMustMatchVendor_c807cfd04459 := TRUE;
  p_CacheMustMatchAgent_c807cfd04459 := FALSE;
  p_CacheMustMatchConfig_c807cfd04459 := FALSE;
  p_PromptRole_c807cfd04459 := 'System';
  p_PromptPosition_c807cfd04459 := 'First';
  p_IncludeLogProbs_c807cfd04459 := FALSE;
  p_FailoverStrategy_c807cfd04459 := 'SameModelDifferentVendor';
  p_FailoverMaxAttempts_c807cfd04459 := 3;
  p_FailoverDelaySeconds_c807cfd04459 := 5;
  p_FailoverModelStrategy_c807cfd04459 := 'PreferSameModel';
  p_FailoverErrorScope_c807cfd04459 := 'All';
  p_PrefillFallbackMode_c807cfd04459 := 'Ignore';
  p_RequireSpecificModels_c807cfd04459 := FALSE;
  p_ID_c807cfd04459 := '19736B1D-923B-4BB7-AAE8-9A98D9B25C1E';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateAIPrompt'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateAIPrompt"(p_data := jsonb_build_object(
    'Name', p_Name_c807cfd04459,
    'Description', p_Description_c807cfd04459,
    'TemplateID', p_TemplateID_c807cfd04459,
    'CategoryID', p_CategoryID_c807cfd04459,
    'TypeID', p_TypeID_c807cfd04459,
    'Status', p_Status_c807cfd04459,
    'ResponseFormat', p_ResponseFormat_c807cfd04459,
    'ModelSpecificResponseFormat', p_ModelSpecificResponseFormat_c807cfd04459,
    'AIModelTypeID', p_AIModelTypeID_c807cfd04459,
    'MinPowerRank', p_MinPowerRank_c807cfd04459,
    'SelectionStrategy', p_SelectionStrategy_c807cfd04459,
    'PowerPreference', p_PowerPreference_c807cfd04459,
    'ParallelizationMode', p_ParallelizationMode_c807cfd04459,
    'ParallelCount', p_ParallelCount_c807cfd04459,
    'ParallelConfigParam', p_ParallelConfigParam_c807cfd04459,
    'OutputType', p_OutputType_c807cfd04459,
    'OutputExample', p_OutputExample_c807cfd04459,
    'ValidationBehavior', p_ValidationBehavior_c807cfd04459,
    'MaxRetries', p_MaxRetries_c807cfd04459,
    'RetryDelayMS', p_RetryDelayMS_c807cfd04459,
    'RetryStrategy', p_RetryStrategy_c807cfd04459,
    'ResultSelectorPromptID', p_ResultSelectorPromptID_c807cfd04459,
    'EnableCaching', p_EnableCaching_c807cfd04459,
    'CacheTTLSeconds', p_CacheTTLSeconds_c807cfd04459,
    'CacheMatchType', p_CacheMatchType_c807cfd04459,
    'CacheSimilarityThreshold', p_CacheSimilarityThreshold_c807cfd04459,
    'CacheMustMatchModel', p_CacheMustMatchModel_c807cfd04459,
    'CacheMustMatchVendor', p_CacheMustMatchVendor_c807cfd04459,
    'CacheMustMatchAgent', p_CacheMustMatchAgent_c807cfd04459,
    'CacheMustMatchConfig', p_CacheMustMatchConfig_c807cfd04459,
    'PromptRole', p_PromptRole_c807cfd04459,
    'PromptPosition', p_PromptPosition_c807cfd04459,
    'Temperature', p_Temperature_c807cfd04459,
    'TopP', p_TopP_c807cfd04459,
    'TopK', p_TopK_c807cfd04459,
    'MinP', p_MinP_c807cfd04459,
    'FrequencyPenalty', p_FrequencyPenalty_c807cfd04459,
    'PresencePenalty', p_PresencePenalty_c807cfd04459,
    'Seed', p_Seed_c807cfd04459,
    'StopSequences', p_StopSequences_c807cfd04459,
    'IncludeLogProbs', p_IncludeLogProbs_c807cfd04459,
    'TopLogProbs', p_TopLogProbs_c807cfd04459,
    'FailoverStrategy', p_FailoverStrategy_c807cfd04459,
    'FailoverMaxAttempts', p_FailoverMaxAttempts_c807cfd04459,
    'FailoverDelaySeconds', p_FailoverDelaySeconds_c807cfd04459,
    'FailoverModelStrategy', p_FailoverModelStrategy_c807cfd04459,
    'FailoverErrorScope', p_FailoverErrorScope_c807cfd04459,
    'EffortLevel', p_EffortLevel_c807cfd04459,
    'AssistantPrefill', p_AssistantPrefill_c807cfd04459,
    'PrefillFallbackMode', p_PrefillFallbackMode_c807cfd04459
  ) ||
  jsonb_build_object(
    'RequireSpecificModels', p_RequireSpecificModels_c807cfd04459,
    'PromptConfiguration', p_PromptConfiguration_c807cfd04459,
    'ID', p_ID_c807cfd04459
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateAIPrompt"(p_Name := p_Name_c807cfd04459, p_Description := p_Description_c807cfd04459, p_TemplateID := p_TemplateID_c807cfd04459, p_CategoryID := p_CategoryID_c807cfd04459, p_TypeID := p_TypeID_c807cfd04459, p_Status := p_Status_c807cfd04459, p_ResponseFormat := p_ResponseFormat_c807cfd04459, p_ModelSpecificResponseFormat := p_ModelSpecificResponseFormat_c807cfd04459, p_ModelSpecificResponseFormat_Clear := TRUE, p_AIModelTypeID := p_AIModelTypeID_c807cfd04459, p_AIModelTypeID_Clear := TRUE, p_MinPowerRank := p_MinPowerRank_c807cfd04459, p_SelectionStrategy := p_SelectionStrategy_c807cfd04459, p_PowerPreference := p_PowerPreference_c807cfd04459, p_ParallelizationMode := p_ParallelizationMode_c807cfd04459, p_ParallelCount := p_ParallelCount_c807cfd04459, p_ParallelCount_Clear := TRUE, p_ParallelConfigParam := p_ParallelConfigParam_c807cfd04459, p_ParallelConfigParam_Clear := TRUE, p_OutputType := p_OutputType_c807cfd04459, p_OutputExample := p_OutputExample_c807cfd04459, p_OutputExample_Clear := TRUE, p_ValidationBehavior := p_ValidationBehavior_c807cfd04459, p_MaxRetries := p_MaxRetries_c807cfd04459, p_RetryDelayMS := p_RetryDelayMS_c807cfd04459, p_RetryStrategy := p_RetryStrategy_c807cfd04459, p_ResultSelectorPromptID := p_ResultSelectorPromptID_c807cfd04459, p_ResultSelectorPromptID_Clear := TRUE, p_EnableCaching := p_EnableCaching_c807cfd04459, p_CacheTTLSeconds := p_CacheTTLSeconds_c807cfd04459, p_CacheTTLSeconds_Clear := TRUE, p_CacheMatchType := p_CacheMatchType_c807cfd04459, p_CacheSimilarityThreshold := p_CacheSimilarityThreshold_c807cfd04459, p_CacheSimilarityThreshold_Clear := TRUE, p_CacheMustMatchModel := p_CacheMustMatchModel_c807cfd04459, p_CacheMustMatchVendor := p_CacheMustMatchVendor_c807cfd04459, p_CacheMustMatchAgent := p_CacheMustMatchAgent_c807cfd04459, p_CacheMustMatchConfig := p_CacheMustMatchConfig_c807cfd04459, p_PromptRole := p_PromptRole_c807cfd04459, p_PromptPosition := p_PromptPosition_c807cfd04459, p_Temperature := p_Temperature_c807cfd04459, p_Temperature_Clear := TRUE, p_TopP := p_TopP_c807cfd04459, p_TopP_Clear := TRUE, p_TopK := p_TopK_c807cfd04459, p_TopK_Clear := TRUE, p_MinP := p_MinP_c807cfd04459, p_MinP_Clear := TRUE, p_FrequencyPenalty := p_FrequencyPenalty_c807cfd04459, p_FrequencyPenalty_Clear := TRUE, p_PresencePenalty := p_PresencePenalty_c807cfd04459, p_PresencePenalty_Clear := TRUE, p_Seed := p_Seed_c807cfd04459, p_Seed_Clear := TRUE, p_StopSequences := p_StopSequences_c807cfd04459, p_StopSequences_Clear := TRUE, p_IncludeLogProbs := p_IncludeLogProbs_c807cfd04459, p_TopLogProbs := p_TopLogProbs_c807cfd04459, p_TopLogProbs_Clear := TRUE, p_FailoverStrategy := p_FailoverStrategy_c807cfd04459, p_FailoverMaxAttempts := p_FailoverMaxAttempts_c807cfd04459, p_FailoverDelaySeconds := p_FailoverDelaySeconds_c807cfd04459, p_FailoverModelStrategy := p_FailoverModelStrategy_c807cfd04459, p_FailoverErrorScope := p_FailoverErrorScope_c807cfd04459, p_EffortLevel := p_EffortLevel_c807cfd04459, p_EffortLevel_Clear := TRUE, p_AssistantPrefill := p_AssistantPrefill_c807cfd04459, p_AssistantPrefill_Clear := TRUE, p_PrefillFallbackMode := p_PrefillFallbackMode_c807cfd04459, p_RequireSpecificModels := p_RequireSpecificModels_c807cfd04459, p_PromptConfiguration := p_PromptConfiguration_c807cfd04459, p_PromptConfiguration_Clear := TRUE, p_ID := p_ID_c807cfd04459);
  END IF;
END $mj$;

-- Save MJ: AI Prompt Models (core SP call only)
DO $mj$
DECLARE
  p_PromptID_88bac8023101 UUID;
  p_ModelID_88bac8023101 UUID;
  p_VendorID_88bac8023101 UUID;
  p_ConfigurationID_88bac8023101 UUID;
  p_Priority_88bac8023101 INTEGER;
  p_ExecutionGroup_88bac8023101 INTEGER;
  p_ModelParameters_88bac8023101 TEXT;
  p_Status_88bac8023101 VARCHAR(20);
  p_ParallelizationMode_88bac8023101 VARCHAR(20);
  p_ParallelCount_88bac8023101 INTEGER;
  p_ParallelConfigParam_88bac8023101 VARCHAR(100);
  p_EffortLevel_88bac8023101 INTEGER;
  p_PromptConfiguration_88bac8023101 TEXT;
  p_ID_88bac8023101 UUID;
BEGIN
  p_PromptID_88bac8023101 := '19736B1D-923B-4BB7-AAE8-9A98D9B25C1E';
  p_ModelID_88bac8023101 := 'E8C833BC-1723-4B4B-9B12-0629EB5190A3';
  p_VendorID_88bac8023101 := 'E4A5CCEC-6A37-EF11-86D4-000D3A4E707E';
  p_Priority_88bac8023101 := 1;
  p_ExecutionGroup_88bac8023101 := 0;
  p_Status_88bac8023101 := 'Active';
  p_ParallelizationMode_88bac8023101 := 'None';
  p_ParallelCount_88bac8023101 := 1;
  p_ID_88bac8023101 := 'FE550867-CA64-4578-9912-083314D3AEF2';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateAIPromptModel'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateAIPromptModel"(p_data := jsonb_build_object(
    'PromptID', p_PromptID_88bac8023101,
    'ModelID', p_ModelID_88bac8023101,
    'VendorID', p_VendorID_88bac8023101,
    'ConfigurationID', p_ConfigurationID_88bac8023101,
    'Priority', p_Priority_88bac8023101,
    'ExecutionGroup', p_ExecutionGroup_88bac8023101,
    'ModelParameters', p_ModelParameters_88bac8023101,
    'Status', p_Status_88bac8023101,
    'ParallelizationMode', p_ParallelizationMode_88bac8023101,
    'ParallelCount', p_ParallelCount_88bac8023101,
    'ParallelConfigParam', p_ParallelConfigParam_88bac8023101,
    'EffortLevel', p_EffortLevel_88bac8023101,
    'PromptConfiguration', p_PromptConfiguration_88bac8023101,
    'ID', p_ID_88bac8023101
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateAIPromptModel"(p_PromptID := p_PromptID_88bac8023101, p_ModelID := p_ModelID_88bac8023101, p_VendorID := p_VendorID_88bac8023101, p_ConfigurationID := p_ConfigurationID_88bac8023101, p_ConfigurationID_Clear := TRUE, p_Priority := p_Priority_88bac8023101, p_ExecutionGroup := p_ExecutionGroup_88bac8023101, p_ModelParameters := p_ModelParameters_88bac8023101, p_ModelParameters_Clear := TRUE, p_Status := p_Status_88bac8023101, p_ParallelizationMode := p_ParallelizationMode_88bac8023101, p_ParallelCount := p_ParallelCount_88bac8023101, p_ParallelConfigParam := p_ParallelConfigParam_88bac8023101, p_ParallelConfigParam_Clear := TRUE, p_EffortLevel := p_EffortLevel_88bac8023101, p_EffortLevel_Clear := TRUE, p_PromptConfiguration := p_PromptConfiguration_88bac8023101, p_PromptConfiguration_Clear := TRUE, p_ID := p_ID_88bac8023101);
  END IF;
END $mj$;

-- Save MJ: Record Processes (core SP call only)
DO $mj$
DECLARE
  p_Name_e9579a894e19 VARCHAR(255);
  p_Description_e9579a894e19 TEXT;
  p_CategoryID_e9579a894e19 UUID;
  p_EntityID_e9579a894e19 UUID;
  p_Status_e9579a894e19 VARCHAR(20);
  p_WorkType_e9579a894e19 VARCHAR(20);
  p_ActionID_e9579a894e19 UUID;
  p_AgentID_e9579a894e19 UUID;
  p_PromptID_e9579a894e19 UUID;
  p_ScopeType_e9579a894e19 VARCHAR(20);
  p_ScopeViewID_e9579a894e19 UUID;
  p_ScopeListID_e9579a894e19 UUID;
  p_ScopeFilter_e9579a894e19 TEXT;
  p_OnChangeEnabled_e9579a894e19 BOOLEAN;
  p_OnChangeInvocationType_e9579a894e19 VARCHAR(30);
  p_OnChangeFilter_e9579a894e19 TEXT;
  p_ScheduleEnabled_e9579a894e19 BOOLEAN;
  p_CronExpression_e9579a894e19 VARCHAR(120);
  p_Timezone_e9579a894e19 VARCHAR(100);
  p_OnDemandEnabled_e9579a894e19 BOOLEAN;
  p_InputMapping_e9579a894e19 TEXT;
  p_OutputMapping_e9579a894e19 TEXT;
  p_SkipUnchanged_e9579a894e19 BOOLEAN;
  p_WatermarkStrategy_e9579a894e19 VARCHAR(20);
  p_BatchSize_e9579a894e19 INTEGER;
  p_MaxConcurrency_e9579a894e19 INTEGER;
  p_Configuration_e9579a894e19 TEXT;
  p_ID_e9579a894e19 UUID;
BEGIN
  p_Name_e9579a894e19 := 'Job Function and Seniority Derivation';
  p_Description_e9579a894e19 := 'Derives job functions (plural child rows) and seniority level (FK field) from a person''s current job title using LLM inference with deduplicating feature value caching.';
  p_CategoryID_e9579a894e19 := 'DF605624-5E5F-4508-A691-9E573FF3F3C3';
  p_EntityID_e9579a894e19 := '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F';
  p_Status_e9579a894e19 := 'Active';
  p_WorkType_e9579a894e19 := 'Infer';
  p_PromptID_e9579a894e19 := '19736B1D-923B-4BB7-AAE8-9A98D9B25C1E';
  p_ScopeType_e9579a894e19 := 'Filter';
  p_ScopeFilter_e9579a894e19 := 'CurrentJobTitle IS NOT NULL AND (SeniorityLevelID IS NULL OR NOT EXISTS (SELECT 1 FROM [__mj_BizAppsCommon].[vwPersonJobFunctions] pjf WHERE pjf.PersonID = ID))';
  p_OnChangeEnabled_e9579a894e19 := FALSE;
  p_ScheduleEnabled_e9579a894e19 := FALSE;
  p_Timezone_e9579a894e19 := 'UTC';
  p_OnDemandEnabled_e9579a894e19 := TRUE;
  p_OutputMapping_e9579a894e19 := '{"fields":{"SeniorityLevelID":"$.SeniorityLevel"},"childRecords":[{"entity":"MJ_BizApps_Common: Person Job Functions","parentField":"PersonID","fanOutRef":"$.Functions","map":{"JobFunctionID":"$.JobFunctionID","Confidence":"$.Confidence","Sequence":"$.Sequence"}}]}';
  p_SkipUnchanged_e9579a894e19 := TRUE;
  p_BatchSize_e9579a894e19 := 100;
  p_MaxConcurrency_e9579a894e19 := 1;
  p_Configuration_e9579a894e19 := '{"Name":"Job Function and Seniority Derivation","Description":"Derives job functions (plural child rows) and seniority level (FK field) from a person''s current job title using LLM inference with deduplicating feature value caching.","PromptID":"19736B1D-923B-4BB7-AAE8-9A98D9B25C1E","Context":{"Fields":["CurrentJobTitle"]},"Outputs":[{"Ref":"$.Functions","Name":"JobFunctions","FeatureKind":"categorical","Target":{"Mode":"child","EntityName":"MJ_BizApps_Common: Person Job Functions","ParentField":"PersonID","Map":{"JobFunctionID":"$.JobFunctionID","Confidence":"$.Confidence","Sequence":"$.Sequence"},"FanOutRef":"Functions"}},{"Ref":"$.SeniorityLevel","Name":"SeniorityLevel","FeatureKind":"categorical","Target":{"Mode":"field","EntityFieldName":"SeniorityLevelID","LookupMatchField":"Name","OnLookupMiss":"null"}}],"Caching":{"Cacheable":true,"KeyFields":["CurrentJobTitle"],"TTLSeconds":2592000,"Scope":"pipeline"},"CaptureReasoning":true}';
  p_ID_e9579a894e19 := '7E030001-A101-4B01-8C01-000000000001';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateRecordProcess'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateRecordProcess"(p_data := jsonb_build_object(
    'Name', p_Name_e9579a894e19,
    'Description', p_Description_e9579a894e19,
    'CategoryID', p_CategoryID_e9579a894e19,
    'EntityID', p_EntityID_e9579a894e19,
    'Status', p_Status_e9579a894e19,
    'WorkType', p_WorkType_e9579a894e19,
    'ActionID', p_ActionID_e9579a894e19,
    'AgentID', p_AgentID_e9579a894e19,
    'PromptID', p_PromptID_e9579a894e19,
    'ScopeType', p_ScopeType_e9579a894e19,
    'ScopeViewID', p_ScopeViewID_e9579a894e19,
    'ScopeListID', p_ScopeListID_e9579a894e19,
    'ScopeFilter', p_ScopeFilter_e9579a894e19,
    'OnChangeEnabled', p_OnChangeEnabled_e9579a894e19,
    'OnChangeInvocationType', p_OnChangeInvocationType_e9579a894e19,
    'OnChangeFilter', p_OnChangeFilter_e9579a894e19,
    'ScheduleEnabled', p_ScheduleEnabled_e9579a894e19,
    'CronExpression', p_CronExpression_e9579a894e19,
    'Timezone', p_Timezone_e9579a894e19,
    'OnDemandEnabled', p_OnDemandEnabled_e9579a894e19,
    'InputMapping', p_InputMapping_e9579a894e19,
    'OutputMapping', p_OutputMapping_e9579a894e19,
    'SkipUnchanged', p_SkipUnchanged_e9579a894e19,
    'WatermarkStrategy', p_WatermarkStrategy_e9579a894e19,
    'BatchSize', p_BatchSize_e9579a894e19,
    'MaxConcurrency', p_MaxConcurrency_e9579a894e19,
    'Configuration', p_Configuration_e9579a894e19,
    'ID', p_ID_e9579a894e19
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateRecordProcess"(p_Name := p_Name_e9579a894e19, p_Description := p_Description_e9579a894e19, p_CategoryID := p_CategoryID_e9579a894e19, p_EntityID := p_EntityID_e9579a894e19, p_Status := p_Status_e9579a894e19, p_WorkType := p_WorkType_e9579a894e19, p_ActionID := p_ActionID_e9579a894e19, p_ActionID_Clear := TRUE, p_AgentID := p_AgentID_e9579a894e19, p_AgentID_Clear := TRUE, p_PromptID := p_PromptID_e9579a894e19, p_ScopeType := p_ScopeType_e9579a894e19, p_ScopeViewID := p_ScopeViewID_e9579a894e19, p_ScopeViewID_Clear := TRUE, p_ScopeListID := p_ScopeListID_e9579a894e19, p_ScopeListID_Clear := TRUE, p_ScopeFilter := p_ScopeFilter_e9579a894e19, p_OnChangeEnabled := p_OnChangeEnabled_e9579a894e19, p_OnChangeInvocationType := p_OnChangeInvocationType_e9579a894e19, p_OnChangeInvocationType_Clear := TRUE, p_OnChangeFilter := p_OnChangeFilter_e9579a894e19, p_OnChangeFilter_Clear := TRUE, p_ScheduleEnabled := p_ScheduleEnabled_e9579a894e19, p_CronExpression := p_CronExpression_e9579a894e19, p_CronExpression_Clear := TRUE, p_Timezone := p_Timezone_e9579a894e19, p_OnDemandEnabled := p_OnDemandEnabled_e9579a894e19, p_InputMapping := p_InputMapping_e9579a894e19, p_InputMapping_Clear := TRUE, p_OutputMapping := p_OutputMapping_e9579a894e19, p_SkipUnchanged := p_SkipUnchanged_e9579a894e19, p_WatermarkStrategy := p_WatermarkStrategy_e9579a894e19, p_WatermarkStrategy_Clear := TRUE, p_BatchSize := p_BatchSize_e9579a894e19, p_MaxConcurrency := p_MaxConcurrency_e9579a894e19, p_Configuration := p_Configuration_e9579a894e19, p_ID := p_ID_e9579a894e19);
  END IF;
END $mj$;
