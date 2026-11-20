-- =============================================================================================
-- PostgreSQL counterpart of V202610141644__v5.53.x__Metadata_Sync.sql -- BizApps Common v5.53.x Metadata_Sync
-- =============================================================================================
-- Same records, same values, same order as the T-SQL file; see its header for what ships and why.
--
-- HOW IT WAS MADE
--   * `mj sql-convert --from tsql --to postgres` (MJ CLI 6.1.5) on the push log the T-SQL file
--     was generated from, held-back records removed as in the T-SQL file. Each record is a DO
--     block that calls the core spCreateGeneratedCode function, in whichever signature the host
--     has (jsonb or named parameters).
--   * The converter does not translate the guards the T-SQL file adds, so they are written here by
--     hand from the T-SQL ones: IF <guard> EXEC ... becomes IF <guard> THEN <call> END IF.
--   * Every string value is taken verbatim from the T-SQL file: the converter rewrites T-SQL
--     inside string literals, which would change the stored validator code.
--   * Schema names use the same placeholders as the T-SQL file.
-- =============================================================================================

SET standard_conforming_strings = on;

-- Save MJ: Generated Codes (core SP call only)
DO $mj$
DECLARE
  p_ID_00f50332644b UUID;
  p_GeneratedAt_00f50332644b TIMESTAMPTZ;
  p_CategoryID_00f50332644b UUID;
  p_GeneratedByModelID_00f50332644b UUID;
  p_Name_00f50332644b VARCHAR(255);
  p_Description_00f50332644b TEXT;
  p_Code_00f50332644b TEXT;
  p_Source_00f50332644b TEXT;
  p_LinkedEntityID_00f50332644b UUID;
  p_LinkedRecordPrimaryKey_00f50332644b TEXT;
  p_Status_00f50332644b VARCHAR(20);
  p_Language_00f50332644b VARCHAR(50);
BEGIN
  p_ID_00f50332644b := '6E0792C1-E9B7-4304-972A-7B31EF773718';
  p_GeneratedAt_00f50332644b := '2026-10-06T21:29:03.990Z';
  p_CategoryID_00f50332644b := 'EE2D433E-F36B-1410-8D9D-00021F8B792E';
  p_GeneratedByModelID_00f50332644b := 'C43229F6-4CC8-4838-9D04-03419A2DA191';
  p_Name_00f50332644b := 'ValidateSentimentScoreRange';
  p_Description_00f50332644b := 'The sentiment score must be a value between -1.000 and 1.000, or left empty.';
  p_Code_00f50332644b := '	public ValidateSentimentScoreRange(result: ValidationResult) {
		if (this.SentimentScore != null && (this.SentimentScore < -1.0 || this.SentimentScore > 1.0)) {
			result.Errors.push(new ValidationErrorInfo(
				"SentimentScore",
				"Sentiment score must be between -1.000 and 1.000.",
				this.SentimentScore,
				ValidationErrorType.Failure
			));
		}
	}';
  p_Source_00f50332644b := '([SentimentScore] IS NULL OR [SentimentScore]>=(-1.000) AND [SentimentScore]<=(1.000))';
  p_LinkedEntityID_00f50332644b := 'DF238F34-2837-EF11-86D4-6045BDEE16E6';
  p_LinkedRecordPrimaryKey_00f50332644b := 'F482A17C-2B9A-4D76-96A8-A3F12462E08D';
  p_Status_00f50332644b := 'Approved';
  p_Language_00f50332644b := 'TypeScript';
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."GeneratedCode" WHERE "ID" = p_ID_00f50332644b) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateGeneratedCode'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_data := jsonb_build_object(
      'ID', p_ID_00f50332644b,
      'GeneratedAt', p_GeneratedAt_00f50332644b,
      'CategoryID', p_CategoryID_00f50332644b,
      'GeneratedByModelID', p_GeneratedByModelID_00f50332644b,
      'Name', p_Name_00f50332644b,
      'Description', p_Description_00f50332644b,
      'Code', p_Code_00f50332644b,
      'Source', p_Source_00f50332644b,
      'LinkedEntityID', p_LinkedEntityID_00f50332644b,
      'LinkedRecordPrimaryKey', p_LinkedRecordPrimaryKey_00f50332644b,
      'Status', p_Status_00f50332644b,
      'Language', p_Language_00f50332644b
    ));
    ELSE
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_ID := p_ID_00f50332644b, p_GeneratedAt := p_GeneratedAt_00f50332644b, p_CategoryID := p_CategoryID_00f50332644b, p_GeneratedByModelID := p_GeneratedByModelID_00f50332644b, p_Name := p_Name_00f50332644b, p_Description := p_Description_00f50332644b, p_Code := p_Code_00f50332644b, p_Source := p_Source_00f50332644b, p_LinkedEntityID := p_LinkedEntityID_00f50332644b, p_LinkedRecordPrimaryKey := p_LinkedRecordPrimaryKey_00f50332644b, p_Status := p_Status_00f50332644b, p_Language := p_Language_00f50332644b);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Generated Codes (core SP call only)
DO $mj$
DECLARE
  p_ID_e44cea044caf UUID;
  p_GeneratedAt_e44cea044caf TIMESTAMPTZ;
  p_CategoryID_e44cea044caf UUID;
  p_GeneratedByModelID_e44cea044caf UUID;
  p_Name_e44cea044caf VARCHAR(255);
  p_Description_e44cea044caf TEXT;
  p_Code_e44cea044caf TEXT;
  p_Source_e44cea044caf TEXT;
  p_LinkedEntityID_e44cea044caf UUID;
  p_LinkedRecordPrimaryKey_e44cea044caf TEXT;
  p_Status_e44cea044caf VARCHAR(20);
  p_Language_e44cea044caf VARCHAR(50);
BEGIN
  p_ID_e44cea044caf := '00255C89-655B-4D5A-B908-12E8F4233DD4';
  p_GeneratedAt_e44cea044caf := '2026-10-06T21:29:03.990Z';
  p_CategoryID_e44cea044caf := 'EE2D433E-F36B-1410-8D9D-00021F8B792E';
  p_GeneratedByModelID_e44cea044caf := 'C43229F6-4CC8-4838-9D04-03419A2DA191';
  p_Name_e44cea044caf := 'ValidateEndedAtAfterStartedAt';
  p_Description_e44cea044caf := 'The end date and time of an activity must be on or after its start date and time. This ensures that the duration of the activity is chronologically valid.';
  p_Code_e44cea044caf := 'public ValidateEndedAtAfterStartedAt(result: ValidationResult) {
	if (this.EndedAt != null && this.StartedAt != null) {
		const endedDate = new Date(this.EndedAt);
		const startedDate = new Date(this.StartedAt);
		if (endedDate < startedDate) {
			result.Errors.push(new ValidationErrorInfo(
				"EndedAt",
				"The end date and time must be on or after the start date and time.",
				this.EndedAt,
				ValidationErrorType.Failure
			));
		}
	}
}';
  p_Source_e44cea044caf := '([EndedAt] IS NULL OR [EndedAt]>=[StartedAt])';
  p_LinkedEntityID_e44cea044caf := 'E0238F34-2837-EF11-86D4-6045BDEE16E6';
  p_LinkedRecordPrimaryKey_e44cea044caf := '72E55425-8822-4E70-A075-116219CA5A5D';
  p_Status_e44cea044caf := 'Approved';
  p_Language_e44cea044caf := 'TypeScript';
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."GeneratedCode" WHERE "ID" = p_ID_e44cea044caf) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateGeneratedCode'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_data := jsonb_build_object(
      'ID', p_ID_e44cea044caf,
      'GeneratedAt', p_GeneratedAt_e44cea044caf,
      'CategoryID', p_CategoryID_e44cea044caf,
      'GeneratedByModelID', p_GeneratedByModelID_e44cea044caf,
      'Name', p_Name_e44cea044caf,
      'Description', p_Description_e44cea044caf,
      'Code', p_Code_e44cea044caf,
      'Source', p_Source_e44cea044caf,
      'LinkedEntityID', p_LinkedEntityID_e44cea044caf,
      'LinkedRecordPrimaryKey', p_LinkedRecordPrimaryKey_e44cea044caf,
      'Status', p_Status_e44cea044caf,
      'Language', p_Language_e44cea044caf
    ));
    ELSE
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_ID := p_ID_e44cea044caf, p_GeneratedAt := p_GeneratedAt_e44cea044caf, p_CategoryID := p_CategoryID_e44cea044caf, p_GeneratedByModelID := p_GeneratedByModelID_e44cea044caf, p_Name := p_Name_e44cea044caf, p_Description := p_Description_e44cea044caf, p_Code := p_Code_e44cea044caf, p_Source := p_Source_e44cea044caf, p_LinkedEntityID := p_LinkedEntityID_e44cea044caf, p_LinkedRecordPrimaryKey := p_LinkedRecordPrimaryKey_e44cea044caf, p_Status := p_Status_e44cea044caf, p_Language := p_Language_e44cea044caf);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Generated Codes (core SP call only)
DO $mj$
DECLARE
  p_ID_84023fd350d9 UUID;
  p_GeneratedAt_84023fd350d9 TIMESTAMPTZ;
  p_CategoryID_84023fd350d9 UUID;
  p_GeneratedByModelID_84023fd350d9 UUID;
  p_Name_84023fd350d9 VARCHAR(255);
  p_Description_84023fd350d9 TEXT;
  p_Code_84023fd350d9 TEXT;
  p_Source_84023fd350d9 TEXT;
  p_LinkedEntityID_84023fd350d9 UUID;
  p_LinkedRecordPrimaryKey_84023fd350d9 TEXT;
  p_Status_84023fd350d9 VARCHAR(20);
  p_Language_84023fd350d9 VARCHAR(50);
BEGIN
  p_ID_84023fd350d9 := 'E638DAA2-09B8-4AEA-854D-3A48CAADC721';
  p_GeneratedAt_84023fd350d9 := '2026-10-06T21:29:03.990Z';
  p_CategoryID_84023fd350d9 := 'EE2D433E-F36B-1410-8D9D-00021F8B792E';
  p_GeneratedByModelID_84023fd350d9 := 'C43229F6-4CC8-4838-9D04-03419A2DA191';
  p_Name_84023fd350d9 := 'ValidateEntityOrIdentityExclusivity';
  p_Description_84023fd350d9 := 'The record must be associated with either an Entity and Record ID pair, or an Identity Kind and Identity Value pair. It cannot have both sets of fields populated, nor can it have a partial mix of these fields.';
  p_Code_84023fd350d9 := 'public ValidateEntityOrIdentityExclusivity(result: ValidationResult) {
    const hasEntity = this.EntityID != null;
    const hasRecord = this.RecordID != null;
    const hasIdentityKind = this.IdentityKind != null;
    const hasIdentityValue = this.IdentityValue != null;

    const isValidEntityPair = hasEntity && hasRecord && !hasIdentityKind && !hasIdentityValue;
    const isValidIdentityPair = !hasEntity && !hasRecord && hasIdentityKind && hasIdentityValue;

    if (!isValidEntityPair && !isValidIdentityPair) {
        result.Errors.push(new ValidationErrorInfo(
            "EntityID",
            "You must provide either both EntityID and RecordID (leaving IdentityKind and IdentityValue empty), or both IdentityKind and IdentityValue (leaving EntityID and RecordID empty). Mixed or incomplete pairs are not allowed.",
            this.EntityID,
            ValidationErrorType.Failure
        ));
    }
}';
  p_Source_84023fd350d9 := '([EntityID] IS NOT NULL AND [RecordID] IS NOT NULL AND [IdentityKind] IS NULL AND [IdentityValue] IS NULL OR [EntityID] IS NULL AND [RecordID] IS NULL AND [IdentityKind] IS NOT NULL AND [IdentityValue] IS NOT NULL)';
  p_LinkedEntityID_84023fd350d9 := 'E0238F34-2837-EF11-86D4-6045BDEE16E6';
  p_LinkedRecordPrimaryKey_84023fd350d9 := '9C48DF77-E4A1-4ADB-AABF-916F5798B894';
  p_Status_84023fd350d9 := 'Approved';
  p_Language_84023fd350d9 := 'TypeScript';
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."GeneratedCode" WHERE "ID" = p_ID_84023fd350d9) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateGeneratedCode'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_data := jsonb_build_object(
      'ID', p_ID_84023fd350d9,
      'GeneratedAt', p_GeneratedAt_84023fd350d9,
      'CategoryID', p_CategoryID_84023fd350d9,
      'GeneratedByModelID', p_GeneratedByModelID_84023fd350d9,
      'Name', p_Name_84023fd350d9,
      'Description', p_Description_84023fd350d9,
      'Code', p_Code_84023fd350d9,
      'Source', p_Source_84023fd350d9,
      'LinkedEntityID', p_LinkedEntityID_84023fd350d9,
      'LinkedRecordPrimaryKey', p_LinkedRecordPrimaryKey_84023fd350d9,
      'Status', p_Status_84023fd350d9,
      'Language', p_Language_84023fd350d9
    ));
    ELSE
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_ID := p_ID_84023fd350d9, p_GeneratedAt := p_GeneratedAt_84023fd350d9, p_CategoryID := p_CategoryID_84023fd350d9, p_GeneratedByModelID := p_GeneratedByModelID_84023fd350d9, p_Name := p_Name_84023fd350d9, p_Description := p_Description_84023fd350d9, p_Code := p_Code_84023fd350d9, p_Source := p_Source_84023fd350d9, p_LinkedEntityID := p_LinkedEntityID_84023fd350d9, p_LinkedRecordPrimaryKey := p_LinkedRecordPrimaryKey_84023fd350d9, p_Status := p_Status_84023fd350d9, p_Language := p_Language_84023fd350d9);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Generated Codes (core SP call only)
DO $mj$
DECLARE
  p_ID_e6cc76f40e79 UUID;
  p_GeneratedAt_e6cc76f40e79 TIMESTAMPTZ;
  p_CategoryID_e6cc76f40e79 UUID;
  p_GeneratedByModelID_e6cc76f40e79 UUID;
  p_Name_e6cc76f40e79 VARCHAR(255);
  p_Description_e6cc76f40e79 TEXT;
  p_Code_e6cc76f40e79 TEXT;
  p_Source_e6cc76f40e79 TEXT;
  p_LinkedEntityID_e6cc76f40e79 UUID;
  p_LinkedRecordPrimaryKey_e6cc76f40e79 TEXT;
  p_Status_e6cc76f40e79 VARCHAR(20);
  p_Language_e6cc76f40e79 VARCHAR(50);
BEGIN
  p_ID_e6cc76f40e79 := '4EA7A5A0-372F-49A8-8555-AB7123C10878';
  p_GeneratedAt_e6cc76f40e79 := '2026-10-06T21:29:03.990Z';
  p_CategoryID_e6cc76f40e79 := 'EE2D433E-F36B-1410-8D9D-00021F8B792E';
  p_GeneratedByModelID_e6cc76f40e79 := 'C43229F6-4CC8-4838-9D04-03419A2DA191';
  p_Name_e6cc76f40e79 := 'ValidateMaxAttachmentBytesGreaterThanZero';
  p_Description_e6cc76f40e79 := 'The maximum attachment size limit must be a positive value greater than zero, if it is specified.';
  p_Code_e6cc76f40e79 := 'public ValidateMaxAttachmentBytesGreaterThanZero(result: ValidationResult) {
    if (this.MaxAttachmentBytes != null && this.MaxAttachmentBytes <= 0) {
        result.Errors.push(new ValidationErrorInfo(
            "MaxAttachmentBytes",
            "The maximum attachment size limit must be greater than zero.",
            this.MaxAttachmentBytes,
            ValidationErrorType.Failure
        ));
    }
}';
  p_Source_e6cc76f40e79 := '([MaxAttachmentBytes] IS NULL OR [MaxAttachmentBytes]>(0))';
  p_LinkedEntityID_e6cc76f40e79 := 'DF238F34-2837-EF11-86D4-6045BDEE16E6';
  p_LinkedRecordPrimaryKey_e6cc76f40e79 := 'A8E6FDD3-F038-42CB-A9DA-D92C5105EC34';
  p_Status_e6cc76f40e79 := 'Approved';
  p_Language_e6cc76f40e79 := 'TypeScript';
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."GeneratedCode" WHERE "ID" = p_ID_e6cc76f40e79) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateGeneratedCode'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_data := jsonb_build_object(
      'ID', p_ID_e6cc76f40e79,
      'GeneratedAt', p_GeneratedAt_e6cc76f40e79,
      'CategoryID', p_CategoryID_e6cc76f40e79,
      'GeneratedByModelID', p_GeneratedByModelID_e6cc76f40e79,
      'Name', p_Name_e6cc76f40e79,
      'Description', p_Description_e6cc76f40e79,
      'Code', p_Code_e6cc76f40e79,
      'Source', p_Source_e6cc76f40e79,
      'LinkedEntityID', p_LinkedEntityID_e6cc76f40e79,
      'LinkedRecordPrimaryKey', p_LinkedRecordPrimaryKey_e6cc76f40e79,
      'Status', p_Status_e6cc76f40e79,
      'Language', p_Language_e6cc76f40e79
    ));
    ELSE
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_ID := p_ID_e6cc76f40e79, p_GeneratedAt := p_GeneratedAt_e6cc76f40e79, p_CategoryID := p_CategoryID_e6cc76f40e79, p_GeneratedByModelID := p_GeneratedByModelID_e6cc76f40e79, p_Name := p_Name_e6cc76f40e79, p_Description := p_Description_e6cc76f40e79, p_Code := p_Code_e6cc76f40e79, p_Source := p_Source_e6cc76f40e79, p_LinkedEntityID := p_LinkedEntityID_e6cc76f40e79, p_LinkedRecordPrimaryKey := p_LinkedRecordPrimaryKey_e6cc76f40e79, p_Status := p_Status_e6cc76f40e79, p_Language := p_Language_e6cc76f40e79);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Generated Codes (core SP call only)
DO $mj$
DECLARE
  p_ID_3ba3b4c0d1ce UUID;
  p_GeneratedAt_3ba3b4c0d1ce TIMESTAMPTZ;
  p_CategoryID_3ba3b4c0d1ce UUID;
  p_GeneratedByModelID_3ba3b4c0d1ce UUID;
  p_Name_3ba3b4c0d1ce VARCHAR(255);
  p_Description_3ba3b4c0d1ce TEXT;
  p_Code_3ba3b4c0d1ce TEXT;
  p_Source_3ba3b4c0d1ce TEXT;
  p_LinkedEntityID_3ba3b4c0d1ce UUID;
  p_LinkedRecordPrimaryKey_3ba3b4c0d1ce TEXT;
  p_Status_3ba3b4c0d1ce VARCHAR(20);
  p_Language_3ba3b4c0d1ce VARCHAR(50);
BEGIN
  p_ID_3ba3b4c0d1ce := '2B906304-C1B5-40A2-A98B-41AB951D537D';
  p_GeneratedAt_3ba3b4c0d1ce := '2026-10-06T21:29:03.990Z';
  p_CategoryID_3ba3b4c0d1ce := 'EE2D433E-F36B-1410-8D9D-00021F8B792E';
  p_GeneratedByModelID_3ba3b4c0d1ce := 'C43229F6-4CC8-4838-9D04-03419A2DA191';
  p_Name_3ba3b4c0d1ce := 'ValidateEndAtAfterStartAt';
  p_Description_3ba3b4c0d1ce := 'If both start and end dates are specified, the end date must be greater than or equal to the start date to ensure logical chronological order.';
  p_Code_3ba3b4c0d1ce := 'public ValidateEndAtAfterStartAt(result: ValidationResult) {
	if (this.StartAt != null && this.EndAt != null) {
		if (this.EndAt < this.StartAt) {
			result.Errors.push(new ValidationErrorInfo(
				"EndAt",
				"The end date must be greater than or equal to the start date.",
				this.EndAt,
				ValidationErrorType.Failure
			));
		}
	}
}';
  p_Source_3ba3b4c0d1ce := '([StartAt] IS NULL OR [EndAt] IS NULL OR [EndAt]>=[StartAt])';
  p_LinkedEntityID_3ba3b4c0d1ce := 'E0238F34-2837-EF11-86D4-6045BDEE16E6';
  p_LinkedRecordPrimaryKey_3ba3b4c0d1ce := 'C22591BB-B33A-439C-9567-5494A7B71D8A';
  p_Status_3ba3b4c0d1ce := 'Approved';
  p_Language_3ba3b4c0d1ce := 'TypeScript';
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."GeneratedCode" WHERE "ID" = p_ID_3ba3b4c0d1ce) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateGeneratedCode'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_data := jsonb_build_object(
      'ID', p_ID_3ba3b4c0d1ce,
      'GeneratedAt', p_GeneratedAt_3ba3b4c0d1ce,
      'CategoryID', p_CategoryID_3ba3b4c0d1ce,
      'GeneratedByModelID', p_GeneratedByModelID_3ba3b4c0d1ce,
      'Name', p_Name_3ba3b4c0d1ce,
      'Description', p_Description_3ba3b4c0d1ce,
      'Code', p_Code_3ba3b4c0d1ce,
      'Source', p_Source_3ba3b4c0d1ce,
      'LinkedEntityID', p_LinkedEntityID_3ba3b4c0d1ce,
      'LinkedRecordPrimaryKey', p_LinkedRecordPrimaryKey_3ba3b4c0d1ce,
      'Status', p_Status_3ba3b4c0d1ce,
      'Language', p_Language_3ba3b4c0d1ce
    ));
    ELSE
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_ID := p_ID_3ba3b4c0d1ce, p_GeneratedAt := p_GeneratedAt_3ba3b4c0d1ce, p_CategoryID := p_CategoryID_3ba3b4c0d1ce, p_GeneratedByModelID := p_GeneratedByModelID_3ba3b4c0d1ce, p_Name := p_Name_3ba3b4c0d1ce, p_Description := p_Description_3ba3b4c0d1ce, p_Code := p_Code_3ba3b4c0d1ce, p_Source := p_Source_3ba3b4c0d1ce, p_LinkedEntityID := p_LinkedEntityID_3ba3b4c0d1ce, p_LinkedRecordPrimaryKey := p_LinkedRecordPrimaryKey_3ba3b4c0d1ce, p_Status := p_Status_3ba3b4c0d1ce, p_Language := p_Language_3ba3b4c0d1ce);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Generated Codes (core SP call only)
DO $mj$
DECLARE
  p_ID_83fe8028ca5c UUID;
  p_GeneratedAt_83fe8028ca5c TIMESTAMPTZ;
  p_CategoryID_83fe8028ca5c UUID;
  p_GeneratedByModelID_83fe8028ca5c UUID;
  p_Name_83fe8028ca5c VARCHAR(255);
  p_Description_83fe8028ca5c TEXT;
  p_Code_83fe8028ca5c TEXT;
  p_Source_83fe8028ca5c TEXT;
  p_LinkedEntityID_83fe8028ca5c UUID;
  p_LinkedRecordPrimaryKey_83fe8028ca5c TEXT;
  p_Status_83fe8028ca5c VARCHAR(20);
  p_Language_83fe8028ca5c VARCHAR(50);
BEGIN
  p_ID_83fe8028ca5c := '2FF94B9E-893A-4263-A3A2-26D7212B8348';
  p_GeneratedAt_83fe8028ca5c := '2026-10-06T21:29:03.990Z';
  p_CategoryID_83fe8028ca5c := 'EE2D433E-F36B-1410-8D9D-00021F8B792E';
  p_GeneratedByModelID_83fe8028ca5c := 'C43229F6-4CC8-4838-9D04-03419A2DA191';
  p_Name_83fe8028ca5c := 'ValidateTimeoutMSRange';
  p_Description_83fe8028ca5c := 'The timeout value must be greater than 0 and less than or equal to 300,000 milliseconds (5 minutes) to ensure a valid and reasonable execution limit.';
  p_Code_83fe8028ca5c := 'public ValidateTimeoutMSRange(result: ValidationResult) {
	if (this.TimeoutMS !== undefined && this.TimeoutMS !== null) {
		if (this.TimeoutMS <= 0 || this.TimeoutMS > 300000) {
			result.Errors.push(new ValidationErrorInfo(
				"TimeoutMS",
				"Timeout must be greater than 0 and less than or equal to 300,000 milliseconds (5 minutes).",
				this.TimeoutMS,
				ValidationErrorType.Failure
			));
		}
	}
}';
  p_Source_83fe8028ca5c := '([TimeoutMS]>(0) AND [TimeoutMS]<=(300000))';
  p_LinkedEntityID_83fe8028ca5c := 'DF238F34-2837-EF11-86D4-6045BDEE16E6';
  p_LinkedRecordPrimaryKey_83fe8028ca5c := 'A12A8C4C-DBD9-40FB-97B4-3872AA966FC3';
  p_Status_83fe8028ca5c := 'Approved';
  p_Language_83fe8028ca5c := 'TypeScript';
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."GeneratedCode" WHERE "ID" = p_ID_83fe8028ca5c) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateGeneratedCode'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_data := jsonb_build_object(
      'ID', p_ID_83fe8028ca5c,
      'GeneratedAt', p_GeneratedAt_83fe8028ca5c,
      'CategoryID', p_CategoryID_83fe8028ca5c,
      'GeneratedByModelID', p_GeneratedByModelID_83fe8028ca5c,
      'Name', p_Name_83fe8028ca5c,
      'Description', p_Description_83fe8028ca5c,
      'Code', p_Code_83fe8028ca5c,
      'Source', p_Source_83fe8028ca5c,
      'LinkedEntityID', p_LinkedEntityID_83fe8028ca5c,
      'LinkedRecordPrimaryKey', p_LinkedRecordPrimaryKey_83fe8028ca5c,
      'Status', p_Status_83fe8028ca5c,
      'Language', p_Language_83fe8028ca5c
    ));
    ELSE
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_ID := p_ID_83fe8028ca5c, p_GeneratedAt := p_GeneratedAt_83fe8028ca5c, p_CategoryID := p_CategoryID_83fe8028ca5c, p_GeneratedByModelID := p_GeneratedByModelID_83fe8028ca5c, p_Name := p_Name_83fe8028ca5c, p_Description := p_Description_83fe8028ca5c, p_Code := p_Code_83fe8028ca5c, p_Source := p_Source_83fe8028ca5c, p_LinkedEntityID := p_LinkedEntityID_83fe8028ca5c, p_LinkedRecordPrimaryKey := p_LinkedRecordPrimaryKey_83fe8028ca5c, p_Status := p_Status_83fe8028ca5c, p_Language := p_Language_83fe8028ca5c);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Generated Codes (core SP call only)
DO $mj$
DECLARE
  p_ID_d22a68a9bcfd UUID;
  p_GeneratedAt_d22a68a9bcfd TIMESTAMPTZ;
  p_CategoryID_d22a68a9bcfd UUID;
  p_GeneratedByModelID_d22a68a9bcfd UUID;
  p_Name_d22a68a9bcfd VARCHAR(255);
  p_Description_d22a68a9bcfd TEXT;
  p_Code_d22a68a9bcfd TEXT;
  p_Source_d22a68a9bcfd TEXT;
  p_LinkedEntityID_d22a68a9bcfd UUID;
  p_LinkedRecordPrimaryKey_d22a68a9bcfd TEXT;
  p_Status_d22a68a9bcfd VARCHAR(20);
  p_Language_d22a68a9bcfd VARCHAR(50);
BEGIN
  p_ID_d22a68a9bcfd := '1507137B-80D8-4EFB-B7F4-6C07EA14964B';
  p_GeneratedAt_d22a68a9bcfd := '2026-10-06T21:29:03.990Z';
  p_CategoryID_d22a68a9bcfd := 'EE2D433E-F36B-1410-8D9D-00021F8B792E';
  p_GeneratedByModelID_d22a68a9bcfd := 'C43229F6-4CC8-4838-9D04-03419A2DA191';
  p_Name_d22a68a9bcfd := 'ValidateDefaultMaxAttachmentBytesGreaterThanZero';
  p_Description_d22a68a9bcfd := 'The default maximum attachment size must be greater than zero if it is specified.';
  p_Code_d22a68a9bcfd := 'public ValidateDefaultMaxAttachmentBytesGreaterThanZero(result: ValidationResult) {
    if (this.DefaultMaxAttachmentBytes != null && this.DefaultMaxAttachmentBytes <= 0) {
        result.Errors.push(new ValidationErrorInfo(
            "DefaultMaxAttachmentBytes",
            "The default maximum attachment size must be greater than 0 bytes.",
            this.DefaultMaxAttachmentBytes,
            ValidationErrorType.Failure
        ));
    }
}';
  p_Source_d22a68a9bcfd := '([DefaultMaxAttachmentBytes] IS NULL OR [DefaultMaxAttachmentBytes]>(0))';
  p_LinkedEntityID_d22a68a9bcfd := 'DF238F34-2837-EF11-86D4-6045BDEE16E6';
  p_LinkedRecordPrimaryKey_d22a68a9bcfd := '827D6B7C-BA37-446C-A9C1-912320C1AFF3';
  p_Status_d22a68a9bcfd := 'Approved';
  p_Language_d22a68a9bcfd := 'TypeScript';
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."GeneratedCode" WHERE "ID" = p_ID_d22a68a9bcfd) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateGeneratedCode'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_data := jsonb_build_object(
      'ID', p_ID_d22a68a9bcfd,
      'GeneratedAt', p_GeneratedAt_d22a68a9bcfd,
      'CategoryID', p_CategoryID_d22a68a9bcfd,
      'GeneratedByModelID', p_GeneratedByModelID_d22a68a9bcfd,
      'Name', p_Name_d22a68a9bcfd,
      'Description', p_Description_d22a68a9bcfd,
      'Code', p_Code_d22a68a9bcfd,
      'Source', p_Source_d22a68a9bcfd,
      'LinkedEntityID', p_LinkedEntityID_d22a68a9bcfd,
      'LinkedRecordPrimaryKey', p_LinkedRecordPrimaryKey_d22a68a9bcfd,
      'Status', p_Status_d22a68a9bcfd,
      'Language', p_Language_d22a68a9bcfd
    ));
    ELSE
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_ID := p_ID_d22a68a9bcfd, p_GeneratedAt := p_GeneratedAt_d22a68a9bcfd, p_CategoryID := p_CategoryID_d22a68a9bcfd, p_GeneratedByModelID := p_GeneratedByModelID_d22a68a9bcfd, p_Name := p_Name_d22a68a9bcfd, p_Description := p_Description_d22a68a9bcfd, p_Code := p_Code_d22a68a9bcfd, p_Source := p_Source_d22a68a9bcfd, p_LinkedEntityID := p_LinkedEntityID_d22a68a9bcfd, p_LinkedRecordPrimaryKey := p_LinkedRecordPrimaryKey_d22a68a9bcfd, p_Status := p_Status_d22a68a9bcfd, p_Language := p_Language_d22a68a9bcfd);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Generated Codes (core SP call only)
DO $mj$
DECLARE
  p_ID_df1b2fa6e308 UUID;
  p_GeneratedAt_df1b2fa6e308 TIMESTAMPTZ;
  p_CategoryID_df1b2fa6e308 UUID;
  p_GeneratedByModelID_df1b2fa6e308 UUID;
  p_Name_df1b2fa6e308 VARCHAR(255);
  p_Description_df1b2fa6e308 TEXT;
  p_Code_df1b2fa6e308 TEXT;
  p_Source_df1b2fa6e308 TEXT;
  p_LinkedEntityID_df1b2fa6e308 UUID;
  p_LinkedRecordPrimaryKey_df1b2fa6e308 TEXT;
  p_Status_df1b2fa6e308 VARCHAR(20);
  p_Language_df1b2fa6e308 VARCHAR(50);
BEGIN
  p_ID_df1b2fa6e308 := 'AD9C20D9-6E3C-4671-A29F-4997AAC29FDE';
  p_GeneratedAt_df1b2fa6e308 := '2026-10-06T21:29:03.990Z';
  p_CategoryID_df1b2fa6e308 := 'EE2D433E-F36B-1410-8D9D-00021F8B792E';
  p_GeneratedByModelID_df1b2fa6e308 := 'C43229F6-4CC8-4838-9D04-03419A2DA191';
  p_Name_df1b2fa6e308 := 'ValidateDefaultEncryptionKeyForSkippedContentPolicy';
  p_Description_df1b2fa6e308 := 'A default encryption key must be specified unless the default skipped content policy is set to ''None''.';
  p_Code_df1b2fa6e308 := 'public ValidateDefaultEncryptionKeyForSkippedContentPolicy(result: ValidationResult) {
	if (this.DefaultSkippedContentPolicy !== "None" && this.DefaultEncryptionKeyID == null) {
		result.Errors.push(new ValidationErrorInfo(
			"DefaultEncryptionKeyID",
			"A default encryption key must be specified when the default skipped content policy is not set to ''None''.",
			this.DefaultEncryptionKeyID,
			ValidationErrorType.Failure
		));
	}
}';
  p_Source_df1b2fa6e308 := '([DefaultSkippedContentPolicy]=N''None'' OR [DefaultEncryptionKeyID] IS NOT NULL)';
  p_LinkedEntityID_df1b2fa6e308 := 'E0238F34-2837-EF11-86D4-6045BDEE16E6';
  p_LinkedRecordPrimaryKey_df1b2fa6e308 := 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75';
  p_Status_df1b2fa6e308 := 'Approved';
  p_Language_df1b2fa6e308 := 'TypeScript';
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."GeneratedCode" WHERE "ID" = p_ID_df1b2fa6e308) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateGeneratedCode'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_data := jsonb_build_object(
      'ID', p_ID_df1b2fa6e308,
      'GeneratedAt', p_GeneratedAt_df1b2fa6e308,
      'CategoryID', p_CategoryID_df1b2fa6e308,
      'GeneratedByModelID', p_GeneratedByModelID_df1b2fa6e308,
      'Name', p_Name_df1b2fa6e308,
      'Description', p_Description_df1b2fa6e308,
      'Code', p_Code_df1b2fa6e308,
      'Source', p_Source_df1b2fa6e308,
      'LinkedEntityID', p_LinkedEntityID_df1b2fa6e308,
      'LinkedRecordPrimaryKey', p_LinkedRecordPrimaryKey_df1b2fa6e308,
      'Status', p_Status_df1b2fa6e308,
      'Language', p_Language_df1b2fa6e308
    ));
    ELSE
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_ID := p_ID_df1b2fa6e308, p_GeneratedAt := p_GeneratedAt_df1b2fa6e308, p_CategoryID := p_CategoryID_df1b2fa6e308, p_GeneratedByModelID := p_GeneratedByModelID_df1b2fa6e308, p_Name := p_Name_df1b2fa6e308, p_Description := p_Description_df1b2fa6e308, p_Code := p_Code_df1b2fa6e308, p_Source := p_Source_df1b2fa6e308, p_LinkedEntityID := p_LinkedEntityID_df1b2fa6e308, p_LinkedRecordPrimaryKey := p_LinkedRecordPrimaryKey_df1b2fa6e308, p_Status := p_Status_df1b2fa6e308, p_Language := p_Language_df1b2fa6e308);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Generated Codes (core SP call only)
DO $mj$
DECLARE
  p_ID_c2bd28305652 UUID;
  p_GeneratedAt_c2bd28305652 TIMESTAMPTZ;
  p_CategoryID_c2bd28305652 UUID;
  p_GeneratedByModelID_c2bd28305652 UUID;
  p_Name_c2bd28305652 VARCHAR(255);
  p_Description_c2bd28305652 TEXT;
  p_Code_c2bd28305652 TEXT;
  p_Source_c2bd28305652 TEXT;
  p_LinkedEntityID_c2bd28305652 UUID;
  p_LinkedRecordPrimaryKey_c2bd28305652 TEXT;
  p_Status_c2bd28305652 VARCHAR(20);
  p_Language_c2bd28305652 VARCHAR(50);
BEGIN
  p_ID_c2bd28305652 := 'B7BAF581-6014-45AD-9150-5BE7A13FFEBD';
  p_GeneratedAt_c2bd28305652 := '2026-10-06T21:29:03.990Z';
  p_CategoryID_c2bd28305652 := 'EE2D433E-F36B-1410-8D9D-00021F8B792E';
  p_GeneratedByModelID_c2bd28305652 := 'C43229F6-4CC8-4838-9D04-03419A2DA191';
  p_Name_c2bd28305652 := 'ValidateMaxAttachmentBytesGreaterThanZero';
  p_Description_c2bd28305652 := 'If a maximum attachment size limit is specified, it must be a positive number greater than zero.';
  p_Code_c2bd28305652 := 'public ValidateMaxAttachmentBytesGreaterThanZero(result: ValidationResult) {
	if (this.MaxAttachmentBytes != null && this.MaxAttachmentBytes <= 0) {
		result.Errors.push(new ValidationErrorInfo(
			"MaxAttachmentBytes",
			"The maximum attachment size must be greater than 0 bytes.",
			this.MaxAttachmentBytes,
			ValidationErrorType.Failure
		));
	}
}';
  p_Source_c2bd28305652 := '([MaxAttachmentBytes] IS NULL OR [MaxAttachmentBytes]>(0))';
  p_LinkedEntityID_c2bd28305652 := 'DF238F34-2837-EF11-86D4-6045BDEE16E6';
  p_LinkedRecordPrimaryKey_c2bd28305652 := 'DCA96B15-B3EE-4F41-BBD1-146C71922BA8';
  p_Status_c2bd28305652 := 'Approved';
  p_Language_c2bd28305652 := 'TypeScript';
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."GeneratedCode" WHERE "ID" = p_ID_c2bd28305652) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateGeneratedCode'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_data := jsonb_build_object(
      'ID', p_ID_c2bd28305652,
      'GeneratedAt', p_GeneratedAt_c2bd28305652,
      'CategoryID', p_CategoryID_c2bd28305652,
      'GeneratedByModelID', p_GeneratedByModelID_c2bd28305652,
      'Name', p_Name_c2bd28305652,
      'Description', p_Description_c2bd28305652,
      'Code', p_Code_c2bd28305652,
      'Source', p_Source_c2bd28305652,
      'LinkedEntityID', p_LinkedEntityID_c2bd28305652,
      'LinkedRecordPrimaryKey', p_LinkedRecordPrimaryKey_c2bd28305652,
      'Status', p_Status_c2bd28305652,
      'Language', p_Language_c2bd28305652
    ));
    ELSE
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_ID := p_ID_c2bd28305652, p_GeneratedAt := p_GeneratedAt_c2bd28305652, p_CategoryID := p_CategoryID_c2bd28305652, p_GeneratedByModelID := p_GeneratedByModelID_c2bd28305652, p_Name := p_Name_c2bd28305652, p_Description := p_Description_c2bd28305652, p_Code := p_Code_c2bd28305652, p_Source := p_Source_c2bd28305652, p_LinkedEntityID := p_LinkedEntityID_c2bd28305652, p_LinkedRecordPrimaryKey := p_LinkedRecordPrimaryKey_c2bd28305652, p_Status := p_Status_c2bd28305652, p_Language := p_Language_c2bd28305652);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Generated Codes (core SP call only)
DO $mj$
DECLARE
  p_ID_7bed2a9d4a56 UUID;
  p_GeneratedAt_7bed2a9d4a56 TIMESTAMPTZ;
  p_CategoryID_7bed2a9d4a56 UUID;
  p_GeneratedByModelID_7bed2a9d4a56 UUID;
  p_Name_7bed2a9d4a56 VARCHAR(255);
  p_Description_7bed2a9d4a56 TEXT;
  p_Code_7bed2a9d4a56 TEXT;
  p_Source_7bed2a9d4a56 TEXT;
  p_LinkedEntityID_7bed2a9d4a56 UUID;
  p_LinkedRecordPrimaryKey_7bed2a9d4a56 TEXT;
  p_Status_7bed2a9d4a56 VARCHAR(20);
  p_Language_7bed2a9d4a56 VARCHAR(50);
BEGIN
  p_ID_7bed2a9d4a56 := '3AF96CBB-96BA-4B6F-B84F-DD1B5E7C4479';
  p_GeneratedAt_7bed2a9d4a56 := '2026-10-06T21:29:03.990Z';
  p_CategoryID_7bed2a9d4a56 := 'EE2D433E-F36B-1410-8D9D-00021F8B792E';
  p_GeneratedByModelID_7bed2a9d4a56 := 'C43229F6-4CC8-4838-9D04-03419A2DA191';
  p_Name_7bed2a9d4a56 := 'ValidateActivitySyncConnectionOrRuleSetRequired';
  p_Description_7bed2a9d4a56 := 'Exactly one of Activity Sync Connection or Activity Sync Rule Set must be specified. You cannot provide both, and you cannot leave both empty.';
  p_Code_7bed2a9d4a56 := 'public ValidateActivitySyncConnectionOrRuleSetRequired(result: ValidationResult) {
	const hasRuleSet = this.ActivitySyncRuleSetID != null;
	const hasConnection = this.ActivitySyncConnectionID != null;

	if ((hasRuleSet && hasConnection) || (!hasRuleSet && !hasConnection)) {
		result.Errors.push(new ValidationErrorInfo(
			"ActivitySyncConnectionID",
			"Exactly one of Activity Sync Connection or Activity Sync Rule Set must be specified.",
			this.ActivitySyncConnectionID,
			ValidationErrorType.Failure
		));
	}
}';
  p_Source_7bed2a9d4a56 := '([ActivitySyncRuleSetID] IS NULL AND [ActivitySyncConnectionID] IS NOT NULL OR [ActivitySyncRuleSetID] IS NOT NULL AND [ActivitySyncConnectionID] IS NULL)';
  p_LinkedEntityID_7bed2a9d4a56 := 'E0238F34-2837-EF11-86D4-6045BDEE16E6';
  p_LinkedRecordPrimaryKey_7bed2a9d4a56 := '21B78371-132C-4507-AED8-D44E366468F2';
  p_Status_7bed2a9d4a56 := 'Approved';
  p_Language_7bed2a9d4a56 := 'TypeScript';
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."GeneratedCode" WHERE "ID" = p_ID_7bed2a9d4a56) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateGeneratedCode'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_data := jsonb_build_object(
      'ID', p_ID_7bed2a9d4a56,
      'GeneratedAt', p_GeneratedAt_7bed2a9d4a56,
      'CategoryID', p_CategoryID_7bed2a9d4a56,
      'GeneratedByModelID', p_GeneratedByModelID_7bed2a9d4a56,
      'Name', p_Name_7bed2a9d4a56,
      'Description', p_Description_7bed2a9d4a56,
      'Code', p_Code_7bed2a9d4a56,
      'Source', p_Source_7bed2a9d4a56,
      'LinkedEntityID', p_LinkedEntityID_7bed2a9d4a56,
      'LinkedRecordPrimaryKey', p_LinkedRecordPrimaryKey_7bed2a9d4a56,
      'Status', p_Status_7bed2a9d4a56,
      'Language', p_Language_7bed2a9d4a56
    ));
    ELSE
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_ID := p_ID_7bed2a9d4a56, p_GeneratedAt := p_GeneratedAt_7bed2a9d4a56, p_CategoryID := p_CategoryID_7bed2a9d4a56, p_GeneratedByModelID := p_GeneratedByModelID_7bed2a9d4a56, p_Name := p_Name_7bed2a9d4a56, p_Description := p_Description_7bed2a9d4a56, p_Code := p_Code_7bed2a9d4a56, p_Source := p_Source_7bed2a9d4a56, p_LinkedEntityID := p_LinkedEntityID_7bed2a9d4a56, p_LinkedRecordPrimaryKey := p_LinkedRecordPrimaryKey_7bed2a9d4a56, p_Status := p_Status_7bed2a9d4a56, p_Language := p_Language_7bed2a9d4a56);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Generated Codes (core SP call only)
DO $mj$
DECLARE
  p_ID_0e22c6e65a17 UUID;
  p_GeneratedAt_0e22c6e65a17 TIMESTAMPTZ;
  p_CategoryID_0e22c6e65a17 UUID;
  p_GeneratedByModelID_0e22c6e65a17 UUID;
  p_Name_0e22c6e65a17 VARCHAR(255);
  p_Description_0e22c6e65a17 TEXT;
  p_Code_0e22c6e65a17 TEXT;
  p_Source_0e22c6e65a17 TEXT;
  p_LinkedEntityID_0e22c6e65a17 UUID;
  p_LinkedRecordPrimaryKey_0e22c6e65a17 TEXT;
  p_Status_0e22c6e65a17 VARCHAR(20);
  p_Language_0e22c6e65a17 VARCHAR(50);
BEGIN
  p_ID_0e22c6e65a17 := '2D2C1C88-8BFD-4871-B51C-956777843D01';
  p_GeneratedAt_0e22c6e65a17 := '2026-10-06T21:29:03.990Z';
  p_CategoryID_0e22c6e65a17 := 'EE2D433E-F36B-1410-8D9D-00021F8B792E';
  p_GeneratedByModelID_0e22c6e65a17 := 'C43229F6-4CC8-4838-9D04-03419A2DA191';
  p_Name_0e22c6e65a17 := 'ValidateDateToAfterOrEqualDateFrom';
  p_Description_0e22c6e65a17 := 'The end date must be on or after the start date when both dates are provided.';
  p_Code_0e22c6e65a17 := 'public ValidateDateToAfterOrEqualDateFrom(result: ValidationResult) {
	if (this.DateFrom != null && this.DateTo != null) {
		if (this.DateTo < this.DateFrom) {
			result.Errors.push(new ValidationErrorInfo(
				"DateTo",
				"The end date (DateTo) must be on or after the start date (DateFrom).",
				this.DateTo,
				ValidationErrorType.Failure
			));
		}
	}
}';
  p_Source_0e22c6e65a17 := '([DateFrom] IS NULL OR [DateTo] IS NULL OR [DateTo]>=[DateFrom])';
  p_LinkedEntityID_0e22c6e65a17 := 'E0238F34-2837-EF11-86D4-6045BDEE16E6';
  p_LinkedRecordPrimaryKey_0e22c6e65a17 := '21B78371-132C-4507-AED8-D44E366468F2';
  p_Status_0e22c6e65a17 := 'Approved';
  p_Language_0e22c6e65a17 := 'TypeScript';
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."GeneratedCode" WHERE "ID" = p_ID_0e22c6e65a17) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateGeneratedCode'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_data := jsonb_build_object(
      'ID', p_ID_0e22c6e65a17,
      'GeneratedAt', p_GeneratedAt_0e22c6e65a17,
      'CategoryID', p_CategoryID_0e22c6e65a17,
      'GeneratedByModelID', p_GeneratedByModelID_0e22c6e65a17,
      'Name', p_Name_0e22c6e65a17,
      'Description', p_Description_0e22c6e65a17,
      'Code', p_Code_0e22c6e65a17,
      'Source', p_Source_0e22c6e65a17,
      'LinkedEntityID', p_LinkedEntityID_0e22c6e65a17,
      'LinkedRecordPrimaryKey', p_LinkedRecordPrimaryKey_0e22c6e65a17,
      'Status', p_Status_0e22c6e65a17,
      'Language', p_Language_0e22c6e65a17
    ));
    ELSE
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_ID := p_ID_0e22c6e65a17, p_GeneratedAt := p_GeneratedAt_0e22c6e65a17, p_CategoryID := p_CategoryID_0e22c6e65a17, p_GeneratedByModelID := p_GeneratedByModelID_0e22c6e65a17, p_Name := p_Name_0e22c6e65a17, p_Description := p_Description_0e22c6e65a17, p_Code := p_Code_0e22c6e65a17, p_Source := p_Source_0e22c6e65a17, p_LinkedEntityID := p_LinkedEntityID_0e22c6e65a17, p_LinkedRecordPrimaryKey := p_LinkedRecordPrimaryKey_0e22c6e65a17, p_Status := p_Status_0e22c6e65a17, p_Language := p_Language_0e22c6e65a17);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Generated Codes (core SP call only)
DO $mj$
DECLARE
  p_ID_3ff0545edf44 UUID;
  p_GeneratedAt_3ff0545edf44 TIMESTAMPTZ;
  p_CategoryID_3ff0545edf44 UUID;
  p_GeneratedByModelID_3ff0545edf44 UUID;
  p_Name_3ff0545edf44 VARCHAR(255);
  p_Description_3ff0545edf44 TEXT;
  p_Code_3ff0545edf44 TEXT;
  p_Source_3ff0545edf44 TEXT;
  p_LinkedEntityID_3ff0545edf44 UUID;
  p_LinkedRecordPrimaryKey_3ff0545edf44 TEXT;
  p_Status_3ff0545edf44 VARCHAR(20);
  p_Language_3ff0545edf44 VARCHAR(50);
BEGIN
  p_ID_3ff0545edf44 := 'C8FB9783-8E0A-44BB-9FA0-9E04DBAF9351';
  p_GeneratedAt_3ff0545edf44 := '2026-10-06T21:29:03.990Z';
  p_CategoryID_3ff0545edf44 := 'EE2D433E-F36B-1410-8D9D-00021F8B792E';
  p_GeneratedByModelID_3ff0545edf44 := 'C43229F6-4CC8-4838-9D04-03419A2DA191';
  p_Name_3ff0545edf44 := 'ValidateConfidenceRange';
  p_Description_3ff0545edf44 := 'Confidence score must be a value between 0 and 1 (inclusive) when specified.';
  p_Code_3ff0545edf44 := 'public ValidateConfidenceRange(result: ValidationResult) {
	if (this.Confidence != null && (this.Confidence < 0 || this.Confidence > 1)) {
		result.Errors.push(new ValidationErrorInfo(
			''Confidence'',
			''Confidence score must be between 0 and 1.'',
			this.Confidence,
			ValidationErrorType.Failure
		));
	}
}';
  p_Source_3ff0545edf44 := '([Confidence] IS NULL OR [Confidence]>=(0) AND [Confidence]<=(1))';
  p_LinkedEntityID_3ff0545edf44 := 'DF238F34-2837-EF11-86D4-6045BDEE16E6';
  p_LinkedRecordPrimaryKey_3ff0545edf44 := '74F9BDC0-2B51-4F54-80DD-62677C682D67';
  p_Status_3ff0545edf44 := 'Approved';
  p_Language_3ff0545edf44 := 'TypeScript';
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."GeneratedCode" WHERE "ID" = p_ID_3ff0545edf44) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateGeneratedCode'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_data := jsonb_build_object(
      'ID', p_ID_3ff0545edf44,
      'GeneratedAt', p_GeneratedAt_3ff0545edf44,
      'CategoryID', p_CategoryID_3ff0545edf44,
      'GeneratedByModelID', p_GeneratedByModelID_3ff0545edf44,
      'Name', p_Name_3ff0545edf44,
      'Description', p_Description_3ff0545edf44,
      'Code', p_Code_3ff0545edf44,
      'Source', p_Source_3ff0545edf44,
      'LinkedEntityID', p_LinkedEntityID_3ff0545edf44,
      'LinkedRecordPrimaryKey', p_LinkedRecordPrimaryKey_3ff0545edf44,
      'Status', p_Status_3ff0545edf44,
      'Language', p_Language_3ff0545edf44
    ));
    ELSE
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_ID := p_ID_3ff0545edf44, p_GeneratedAt := p_GeneratedAt_3ff0545edf44, p_CategoryID := p_CategoryID_3ff0545edf44, p_GeneratedByModelID := p_GeneratedByModelID_3ff0545edf44, p_Name := p_Name_3ff0545edf44, p_Description := p_Description_3ff0545edf44, p_Code := p_Code_3ff0545edf44, p_Source := p_Source_3ff0545edf44, p_LinkedEntityID := p_LinkedEntityID_3ff0545edf44, p_LinkedRecordPrimaryKey := p_LinkedRecordPrimaryKey_3ff0545edf44, p_Status := p_Status_3ff0545edf44, p_Language := p_Language_3ff0545edf44);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Generated Codes (core SP call only)
DO $mj$
DECLARE
  p_ID_158a38dc580f UUID;
  p_GeneratedAt_158a38dc580f TIMESTAMPTZ;
  p_CategoryID_158a38dc580f UUID;
  p_GeneratedByModelID_158a38dc580f UUID;
  p_Name_158a38dc580f VARCHAR(255);
  p_Description_158a38dc580f TEXT;
  p_Code_158a38dc580f TEXT;
  p_Source_158a38dc580f TEXT;
  p_LinkedEntityID_158a38dc580f UUID;
  p_LinkedRecordPrimaryKey_158a38dc580f TEXT;
  p_Status_158a38dc580f VARCHAR(20);
  p_Language_158a38dc580f VARCHAR(50);
BEGIN
  p_ID_158a38dc580f := 'F72A148E-725B-495A-A3D5-D4C52E061851';
  p_GeneratedAt_158a38dc580f := '2026-10-06T21:29:03.990Z';
  p_CategoryID_158a38dc580f := 'EE2D433E-F36B-1410-8D9D-00021F8B792E';
  p_GeneratedByModelID_158a38dc580f := 'C43229F6-4CC8-4838-9D04-03419A2DA191';
  p_Name_158a38dc580f := 'ValidateActivityIDRequiresIncludedDecision';
  p_Description_158a38dc580f := 'An activity can only be associated with this record if the decision is set to ''Included''.';
  p_Code_158a38dc580f := 'public ValidateActivityIDRequiresIncludedDecision(result: ValidationResult) {
	if (this.ActivityID != null && this.Decision !== ''Included'') {
		result.Errors.push(new ValidationErrorInfo(
			"ActivityID",
			"An activity can only be associated when the decision is ''Included''.",
			this.ActivityID,
			ValidationErrorType.Failure
		));
	}
}';
  p_Source_158a38dc580f := '([ActivityID] IS NULL OR [Decision]=N''Included'')';
  p_LinkedEntityID_158a38dc580f := 'E0238F34-2837-EF11-86D4-6045BDEE16E6';
  p_LinkedRecordPrimaryKey_158a38dc580f := 'AC16B066-9460-44F5-B027-3FD397E61F34';
  p_Status_158a38dc580f := 'Approved';
  p_Language_158a38dc580f := 'TypeScript';
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."GeneratedCode" WHERE "ID" = p_ID_158a38dc580f) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateGeneratedCode'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_data := jsonb_build_object(
      'ID', p_ID_158a38dc580f,
      'GeneratedAt', p_GeneratedAt_158a38dc580f,
      'CategoryID', p_CategoryID_158a38dc580f,
      'GeneratedByModelID', p_GeneratedByModelID_158a38dc580f,
      'Name', p_Name_158a38dc580f,
      'Description', p_Description_158a38dc580f,
      'Code', p_Code_158a38dc580f,
      'Source', p_Source_158a38dc580f,
      'LinkedEntityID', p_LinkedEntityID_158a38dc580f,
      'LinkedRecordPrimaryKey', p_LinkedRecordPrimaryKey_158a38dc580f,
      'Status', p_Status_158a38dc580f,
      'Language', p_Language_158a38dc580f
    ));
    ELSE
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_ID := p_ID_158a38dc580f, p_GeneratedAt := p_GeneratedAt_158a38dc580f, p_CategoryID := p_CategoryID_158a38dc580f, p_GeneratedByModelID := p_GeneratedByModelID_158a38dc580f, p_Name := p_Name_158a38dc580f, p_Description := p_Description_158a38dc580f, p_Code := p_Code_158a38dc580f, p_Source := p_Source_158a38dc580f, p_LinkedEntityID := p_LinkedEntityID_158a38dc580f, p_LinkedRecordPrimaryKey := p_LinkedRecordPrimaryKey_158a38dc580f, p_Status := p_Status_158a38dc580f, p_Language := p_Language_158a38dc580f);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Generated Codes (core SP call only)
DO $mj$
DECLARE
  p_ID_146e44da4d0c UUID;
  p_GeneratedAt_146e44da4d0c TIMESTAMPTZ;
  p_CategoryID_146e44da4d0c UUID;
  p_GeneratedByModelID_146e44da4d0c UUID;
  p_Name_146e44da4d0c VARCHAR(255);
  p_Description_146e44da4d0c TEXT;
  p_Code_146e44da4d0c TEXT;
  p_Source_146e44da4d0c TEXT;
  p_LinkedEntityID_146e44da4d0c UUID;
  p_LinkedRecordPrimaryKey_146e44da4d0c TEXT;
  p_Status_146e44da4d0c VARCHAR(20);
  p_Language_146e44da4d0c VARCHAR(50);
BEGIN
  p_ID_146e44da4d0c := 'EB5C59EA-E2BC-48C2-8D27-7DCF934F3DC5';
  p_GeneratedAt_146e44da4d0c := '2026-10-06T21:29:03.990Z';
  p_CategoryID_146e44da4d0c := 'EE2D433E-F36B-1410-8D9D-00021F8B792E';
  p_GeneratedByModelID_146e44da4d0c := 'C43229F6-4CC8-4838-9D04-03419A2DA191';
  p_Name_146e44da4d0c := 'ValidateWatermarkAfterForDryRun';
  p_Description_146e44da4d0c := 'If the sync is marked as a dry run, a ''Watermark After'' date cannot be specified because no progress is actually saved.';
  p_Code_146e44da4d0c := 'public ValidateWatermarkAfterForDryRun(result: ValidationResult) {
	if (this.IsDryRun && this.WatermarkAfter != null) {
		result.Errors.push(new ValidationErrorInfo(
			"WatermarkAfter",
			"Watermark After date cannot be set when IsDryRun is enabled.",
			this.WatermarkAfter,
			ValidationErrorType.Failure
		));
	}
}';
  p_Source_146e44da4d0c := '([IsDryRun]=(0) OR [WatermarkAfter] IS NULL)';
  p_LinkedEntityID_146e44da4d0c := 'E0238F34-2837-EF11-86D4-6045BDEE16E6';
  p_LinkedRecordPrimaryKey_146e44da4d0c := 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1';
  p_Status_146e44da4d0c := 'Approved';
  p_Language_146e44da4d0c := 'TypeScript';
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."GeneratedCode" WHERE "ID" = p_ID_146e44da4d0c) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateGeneratedCode'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_data := jsonb_build_object(
      'ID', p_ID_146e44da4d0c,
      'GeneratedAt', p_GeneratedAt_146e44da4d0c,
      'CategoryID', p_CategoryID_146e44da4d0c,
      'GeneratedByModelID', p_GeneratedByModelID_146e44da4d0c,
      'Name', p_Name_146e44da4d0c,
      'Description', p_Description_146e44da4d0c,
      'Code', p_Code_146e44da4d0c,
      'Source', p_Source_146e44da4d0c,
      'LinkedEntityID', p_LinkedEntityID_146e44da4d0c,
      'LinkedRecordPrimaryKey', p_LinkedRecordPrimaryKey_146e44da4d0c,
      'Status', p_Status_146e44da4d0c,
      'Language', p_Language_146e44da4d0c
    ));
    ELSE
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_ID := p_ID_146e44da4d0c, p_GeneratedAt := p_GeneratedAt_146e44da4d0c, p_CategoryID := p_CategoryID_146e44da4d0c, p_GeneratedByModelID := p_GeneratedByModelID_146e44da4d0c, p_Name := p_Name_146e44da4d0c, p_Description := p_Description_146e44da4d0c, p_Code := p_Code_146e44da4d0c, p_Source := p_Source_146e44da4d0c, p_LinkedEntityID := p_LinkedEntityID_146e44da4d0c, p_LinkedRecordPrimaryKey := p_LinkedRecordPrimaryKey_146e44da4d0c, p_Status := p_Status_146e44da4d0c, p_Language := p_Language_146e44da4d0c);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Generated Codes (core SP call only)
DO $mj$
DECLARE
  p_ID_775b22afa247 UUID;
  p_GeneratedAt_775b22afa247 TIMESTAMPTZ;
  p_CategoryID_775b22afa247 UUID;
  p_GeneratedByModelID_775b22afa247 UUID;
  p_Name_775b22afa247 VARCHAR(255);
  p_Description_775b22afa247 TEXT;
  p_Code_775b22afa247 TEXT;
  p_Source_775b22afa247 TEXT;
  p_LinkedEntityID_775b22afa247 UUID;
  p_LinkedRecordPrimaryKey_775b22afa247 TEXT;
  p_Status_775b22afa247 VARCHAR(20);
  p_Language_775b22afa247 VARCHAR(50);
BEGIN
  p_ID_775b22afa247 := '3BDC4A50-18DF-42D8-A85E-C1103F5C70D4';
  p_GeneratedAt_775b22afa247 := '2026-10-06T21:29:03.990Z';
  p_CategoryID_775b22afa247 := 'EE2D433E-F36B-1410-8D9D-00021F8B792E';
  p_GeneratedByModelID_775b22afa247 := 'C43229F6-4CC8-4838-9D04-03419A2DA191';
  p_Name_775b22afa247 := 'ValidateConfidenceRange';
  p_Description_775b22afa247 := 'Confidence score must be a value between 0.0 and 1.0 (inclusive) if it is provided, representing a valid probability range.';
  p_Code_775b22afa247 := 'public ValidateConfidenceRange(result: ValidationResult) {
	if (this.Confidence != null && (this.Confidence < 0.0 || this.Confidence > 1.0)) {
		result.Errors.push(new ValidationErrorInfo(
			"Confidence",
			"Confidence score must be between 0.0 and 1.0.",
			this.Confidence,
			ValidationErrorType.Failure
		));
	}
}';
  p_Source_775b22afa247 := '([Confidence] IS NULL OR [Confidence]>=(0.0) AND [Confidence]<=(1.0))';
  p_LinkedEntityID_775b22afa247 := 'DF238F34-2837-EF11-86D4-6045BDEE16E6';
  p_LinkedRecordPrimaryKey_775b22afa247 := 'FF39C3B5-E0B6-47C3-8AED-E8DC16717356';
  p_Status_775b22afa247 := 'Approved';
  p_Language_775b22afa247 := 'TypeScript';
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."GeneratedCode" WHERE "ID" = p_ID_775b22afa247) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateGeneratedCode'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_data := jsonb_build_object(
      'ID', p_ID_775b22afa247,
      'GeneratedAt', p_GeneratedAt_775b22afa247,
      'CategoryID', p_CategoryID_775b22afa247,
      'GeneratedByModelID', p_GeneratedByModelID_775b22afa247,
      'Name', p_Name_775b22afa247,
      'Description', p_Description_775b22afa247,
      'Code', p_Code_775b22afa247,
      'Source', p_Source_775b22afa247,
      'LinkedEntityID', p_LinkedEntityID_775b22afa247,
      'LinkedRecordPrimaryKey', p_LinkedRecordPrimaryKey_775b22afa247,
      'Status', p_Status_775b22afa247,
      'Language', p_Language_775b22afa247
    ));
    ELSE
      PERFORM "${mjSchema}"."spCreateGeneratedCode"(p_ID := p_ID_775b22afa247, p_GeneratedAt := p_GeneratedAt_775b22afa247, p_CategoryID := p_CategoryID_775b22afa247, p_GeneratedByModelID := p_GeneratedByModelID_775b22afa247, p_Name := p_Name_775b22afa247, p_Description := p_Description_775b22afa247, p_Code := p_Code_775b22afa247, p_Source := p_Source_775b22afa247, p_LinkedEntityID := p_LinkedEntityID_775b22afa247, p_LinkedRecordPrimaryKey := p_LinkedRecordPrimaryKey_775b22afa247, p_Status := p_Status_775b22afa247, p_Language := p_Language_775b22afa247);
    END IF;
  END IF;
END $mj$;


-- ===================== Other =====================

-- End of SQL Logging Session
-- Session ID: bf72177f-1b6b-4d42-83a0-3d1d19559cd9
-- Completed: 2026-10-14T16:43:56.794Z
-- Duration: 6444ms
-- Total Statements: 121
