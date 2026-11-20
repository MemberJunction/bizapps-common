-- =============================================================================
-- PostgreSQL counterpart of V202611201230__v5.68.x__SaveReturnMode_DatestampsOnly_StoredProcedures.sql
-- =============================================================================
-- Atomically enables SaveReturnMode = 'datestamps_only' and TrackRecordChanges = FALSE
-- on MJ_BizApps_Common: Activity Sync Runs and Activity Sync Run Details, and installs
-- the native MJ 6.2.1 CodeGen PL/pgSQL spCreate*/spUpdate* functions returning
-- TABLE("ID" UUID, "__mj_CreatedAt" TIMESTAMPTZ, "__mj_UpdatedAt" TIMESTAMPTZ)
-- whenever those base tables exist in the PostgreSQL schema.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA IF NOT EXISTS __mj_bizappscommon;
SET search_path TO __mj_bizappscommon, public;
SET standard_conforming_strings = on;

-- Atomically enable SaveReturnMode = datestamps_only and TrackRecordChanges = FALSE
-- to match metadata/entities/.save-return-datestamps-only.json.
UPDATE ${mjSchema}."Entity"
SET
    "TrackRecordChanges" = FALSE,
    "Configuration" = CASE
        WHEN NULLIF(BTRIM(COALESCE("Configuration", '')), '') IS NULL
            THEN '{
  "SaveReturnMode": "datestamps_only"
}'
        ELSE jsonb_pretty(jsonb_set("Configuration"::jsonb, '{SaveReturnMode}', '"datestamps_only"'::jsonb, TRUE))
    END
WHERE LOWER("SchemaName") = '__mj_bizappscommon'
  AND "BaseTable" IN ('ActivitySyncRun', 'ActivitySyncRunDetail');

-- =============================================================================
-- Native PostgreSQL CodeGen CRUD functions (SaveReturnMode = datestamps_only)
-- Guarded on base table existence because V202608291500 (ActivitySync tables)
-- predates the repository's migrations-pg parity chain.
-- =============================================================================

DO $install_activity_sync_run_detail$
DECLARE
    r RECORD;
BEGIN
    IF to_regclass('__mj_bizappscommon."ActivitySyncRunDetail"') IS NOT NULL THEN
        FOR r IN SELECT oid::regprocedure AS sig
                 FROM pg_proc
                 WHERE proname = 'spCreateActivitySyncRunDetail'
                   AND pronamespace = '__mj_bizappscommon'::regnamespace
        LOOP
            EXECUTE 'DROP FUNCTION ' || r.sig::text;
        END LOOP;

        EXECUTE $fn$
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spCreateActivitySyncRunDetail"(
    p_id UUID DEFAULT NULL,
    p_activitysyncrunid UUID DEFAULT NULL,
    p_externalid VARCHAR(400) DEFAULT NULL,
    p_externalthreadid_clear BOOLEAN DEFAULT FALSE,
    p_externalthreadid VARCHAR(400) DEFAULT NULL,
    p_occurredat_clear BOOLEAN DEFAULT FALSE,
    p_occurredat TIMESTAMPTZ DEFAULT NULL,
    p_decision VARCHAR(20) DEFAULT NULL,
    p_decidedbystage_clear BOOLEAN DEFAULT FALSE,
    p_decidedbystage VARCHAR(100) DEFAULT NULL,
    p_activitysyncruleid_clear BOOLEAN DEFAULT FALSE,
    p_activitysyncruleid UUID DEFAULT NULL,
    p_activitysyncexclusionid_clear BOOLEAN DEFAULT FALSE,
    p_activitysyncexclusionid UUID DEFAULT NULL,
    p_reason_clear BOOLEAN DEFAULT FALSE,
    p_reason TEXT DEFAULT NULL,
    p_confidence_clear BOOLEAN DEFAULT FALSE,
    p_confidence NUMERIC(5, 4) DEFAULT NULL,
    p_aipromptrunid_clear BOOLEAN DEFAULT FALSE,
    p_aipromptrunid UUID DEFAULT NULL,
    p_activityid_clear BOOLEAN DEFAULT FALSE,
    p_activityid UUID DEFAULT NULL,
    p_capturedcontent_clear BOOLEAN DEFAULT FALSE,
    p_capturedcontent TEXT DEFAULT NULL,
    p_encryptionkeyid_clear BOOLEAN DEFAULT FALSE,
    p_encryptionkeyid UUID DEFAULT NULL
) RETURNS TABLE("ID" UUID, "__mj_CreatedAt" TIMESTAMPTZ, "__mj_UpdatedAt" TIMESTAMPTZ) AS $$
#variable_conflict use_column
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO __mj_bizappscommon."ActivitySyncRunDetail"
        (
            "ID",
            "ActivitySyncRunID",
            "ExternalID",
            "ExternalThreadID",
            "OccurredAt",
            "Decision",
            "DecidedByStage",
            "ActivitySyncRuleID",
            "ActivitySyncExclusionID",
            "Reason",
            "Confidence",
            "AIPromptRunID",
            "ActivityID",
            "CapturedContent",
            "EncryptionKeyID"
        )
    VALUES
        (
            v_new_id,
            p_activitysyncrunid,
            p_externalid,
            CASE WHEN p_externalthreadid_clear = TRUE THEN NULL ELSE COALESCE(p_externalthreadid, NULL) END,
            CASE WHEN p_occurredat_clear = TRUE THEN NULL ELSE COALESCE(p_occurredat, NULL) END,
            p_decision,
            CASE WHEN p_decidedbystage_clear = TRUE THEN NULL ELSE COALESCE(p_decidedbystage, NULL) END,
            CASE WHEN p_activitysyncruleid_clear = TRUE THEN NULL ELSE COALESCE(p_activitysyncruleid, NULL) END,
            CASE WHEN p_activitysyncexclusionid_clear = TRUE THEN NULL ELSE COALESCE(p_activitysyncexclusionid, NULL) END,
            CASE WHEN p_reason_clear = TRUE THEN NULL ELSE COALESCE(p_reason, NULL) END,
            CASE WHEN p_confidence_clear = TRUE THEN NULL ELSE COALESCE(p_confidence, NULL) END,
            CASE WHEN p_aipromptrunid_clear = TRUE THEN NULL ELSE COALESCE(p_aipromptrunid, NULL) END,
            CASE WHEN p_activityid_clear = TRUE THEN NULL ELSE COALESCE(p_activityid, NULL) END,
            CASE WHEN p_capturedcontent_clear = TRUE THEN NULL ELSE COALESCE(p_capturedcontent, NULL) END,
            CASE WHEN p_encryptionkeyid_clear = TRUE THEN NULL ELSE COALESCE(p_encryptionkeyid, NULL) END
        );

    RETURN QUERY
    SELECT "ID", "__mj_CreatedAt", "__mj_UpdatedAt" FROM __mj_bizappscommon."ActivitySyncRunDetail"
    WHERE "ID" = v_new_id;
END;
$$ LANGUAGE plpgsql;
$fn$;

        BEGIN
            GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateActivitySyncRunDetail" TO "cdp_Developer", "cdp_Integration";
        EXCEPTION WHEN others THEN NULL;
        END;

        FOR r IN SELECT oid::regprocedure AS sig
                 FROM pg_proc
                 WHERE proname = 'spUpdateActivitySyncRunDetail'
                   AND pronamespace = '__mj_bizappscommon'::regnamespace
        LOOP
            EXECUTE 'DROP FUNCTION ' || r.sig::text;
        END LOOP;

        EXECUTE $fn$
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spUpdateActivitySyncRunDetail"(
    p_id UUID,
    p_activitysyncrunid UUID DEFAULT NULL,
    p_externalid VARCHAR(400) DEFAULT NULL,
    p_externalthreadid_clear BOOLEAN DEFAULT FALSE,
    p_externalthreadid VARCHAR(400) DEFAULT NULL,
    p_occurredat_clear BOOLEAN DEFAULT FALSE,
    p_occurredat TIMESTAMPTZ DEFAULT NULL,
    p_decision VARCHAR(20) DEFAULT NULL,
    p_decidedbystage_clear BOOLEAN DEFAULT FALSE,
    p_decidedbystage VARCHAR(100) DEFAULT NULL,
    p_activitysyncruleid_clear BOOLEAN DEFAULT FALSE,
    p_activitysyncruleid UUID DEFAULT NULL,
    p_activitysyncexclusionid_clear BOOLEAN DEFAULT FALSE,
    p_activitysyncexclusionid UUID DEFAULT NULL,
    p_reason_clear BOOLEAN DEFAULT FALSE,
    p_reason TEXT DEFAULT NULL,
    p_confidence_clear BOOLEAN DEFAULT FALSE,
    p_confidence NUMERIC(5, 4) DEFAULT NULL,
    p_aipromptrunid_clear BOOLEAN DEFAULT FALSE,
    p_aipromptrunid UUID DEFAULT NULL,
    p_activityid_clear BOOLEAN DEFAULT FALSE,
    p_activityid UUID DEFAULT NULL,
    p_capturedcontent_clear BOOLEAN DEFAULT FALSE,
    p_capturedcontent TEXT DEFAULT NULL,
    p_encryptionkeyid_clear BOOLEAN DEFAULT FALSE,
    p_encryptionkeyid UUID DEFAULT NULL
) RETURNS TABLE("ID" UUID, "__mj_CreatedAt" TIMESTAMPTZ, "__mj_UpdatedAt" TIMESTAMPTZ) AS $$
#variable_conflict use_column
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE __mj_bizappscommon."ActivitySyncRunDetail"
    SET
        "ActivitySyncRunID" = COALESCE(p_activitysyncrunid, "ActivitySyncRunID"),
        "ExternalID" = COALESCE(p_externalid, "ExternalID"),
        "ExternalThreadID" = CASE WHEN p_externalthreadid_clear = TRUE THEN NULL ELSE COALESCE(p_externalthreadid, "ExternalThreadID") END,
        "OccurredAt" = CASE WHEN p_occurredat_clear = TRUE THEN NULL ELSE COALESCE(p_occurredat, "OccurredAt") END,
        "Decision" = COALESCE(p_decision, "Decision"),
        "DecidedByStage" = CASE WHEN p_decidedbystage_clear = TRUE THEN NULL ELSE COALESCE(p_decidedbystage, "DecidedByStage") END,
        "ActivitySyncRuleID" = CASE WHEN p_activitysyncruleid_clear = TRUE THEN NULL ELSE COALESCE(p_activitysyncruleid, "ActivitySyncRuleID") END,
        "ActivitySyncExclusionID" = CASE WHEN p_activitysyncexclusionid_clear = TRUE THEN NULL ELSE COALESCE(p_activitysyncexclusionid, "ActivitySyncExclusionID") END,
        "Reason" = CASE WHEN p_reason_clear = TRUE THEN NULL ELSE COALESCE(p_reason, "Reason") END,
        "Confidence" = CASE WHEN p_confidence_clear = TRUE THEN NULL ELSE COALESCE(p_confidence, "Confidence") END,
        "AIPromptRunID" = CASE WHEN p_aipromptrunid_clear = TRUE THEN NULL ELSE COALESCE(p_aipromptrunid, "AIPromptRunID") END,
        "ActivityID" = CASE WHEN p_activityid_clear = TRUE THEN NULL ELSE COALESCE(p_activityid, "ActivityID") END,
        "CapturedContent" = CASE WHEN p_capturedcontent_clear = TRUE THEN NULL ELSE COALESCE(p_capturedcontent, "CapturedContent") END,
        "EncryptionKeyID" = CASE WHEN p_encryptionkeyid_clear = TRUE THEN NULL ELSE COALESCE(p_encryptionkeyid, "EncryptionKeyID") END
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT "ID", "__mj_CreatedAt", "__mj_UpdatedAt" FROM __mj_bizappscommon."ActivitySyncRunDetail"
    WHERE "ID" = p_id;
END;
$$ LANGUAGE plpgsql;
$fn$;

        BEGIN
            GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateActivitySyncRunDetail" TO "cdp_Developer";
        EXCEPTION WHEN others THEN NULL;
        END;
    END IF;
END
$install_activity_sync_run_detail$;

DO $install_activity_sync_run$
DECLARE
    r RECORD;
BEGIN
    IF to_regclass('__mj_bizappscommon."ActivitySyncRun"') IS NOT NULL THEN
        FOR r IN SELECT oid::regprocedure AS sig
                 FROM pg_proc
                 WHERE proname = 'spCreateActivitySyncRun'
                   AND pronamespace = '__mj_bizappscommon'::regnamespace
        LOOP
            EXECUTE 'DROP FUNCTION ' || r.sig::text;
        END LOOP;

        EXECUTE $fn$
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spCreateActivitySyncRun"(
    p_id UUID DEFAULT NULL,
    p_activitysyncconnectionid UUID DEFAULT NULL,
    p_startedat TIMESTAMPTZ DEFAULT NULL,
    p_endedat_clear BOOLEAN DEFAULT FALSE,
    p_endedat TIMESTAMPTZ DEFAULT NULL,
    p_status VARCHAR(20) DEFAULT NULL,
    p_triggertype VARCHAR(20) DEFAULT NULL,
    p_isdryrun BOOLEAN DEFAULT NULL,
    p_fetched INTEGER DEFAULT NULL,
    p_included INTEGER DEFAULT NULL,
    p_excluded INTEGER DEFAULT NULL,
    p_duplicates INTEGER DEFAULT NULL,
    p_failed INTEGER DEFAULT NULL,
    p_extensionerrors INTEGER DEFAULT NULL,
    p_watermarkbefore_clear BOOLEAN DEFAULT FALSE,
    p_watermarkbefore TIMESTAMPTZ DEFAULT NULL,
    p_watermarkafter_clear BOOLEAN DEFAULT FALSE,
    p_watermarkafter TIMESTAMPTZ DEFAULT NULL,
    p_errormessage_clear BOOLEAN DEFAULT FALSE,
    p_errormessage TEXT DEFAULT NULL
) RETURNS TABLE("ID" UUID, "__mj_CreatedAt" TIMESTAMPTZ, "__mj_UpdatedAt" TIMESTAMPTZ) AS $$
#variable_conflict use_column
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO __mj_bizappscommon."ActivitySyncRun"
        (
            "ID",
            "ActivitySyncConnectionID",
            "StartedAt",
            "EndedAt",
            "Status",
            "TriggerType",
            "IsDryRun",
            "Fetched",
            "Included",
            "Excluded",
            "Duplicates",
            "Failed",
            "ExtensionErrors",
            "WatermarkBefore",
            "WatermarkAfter",
            "ErrorMessage"
        )
    VALUES
        (
            v_new_id,
            p_activitysyncconnectionid,
            COALESCE(p_startedat, NOW()),
            CASE WHEN p_endedat_clear = TRUE THEN NULL ELSE COALESCE(p_endedat, NULL) END,
            COALESCE(p_status, 'Running'),
            COALESCE(p_triggertype, 'Scheduled'),
            COALESCE(p_isdryrun, FALSE),
            COALESCE(p_fetched, 0),
            COALESCE(p_included, 0),
            COALESCE(p_excluded, 0),
            COALESCE(p_duplicates, 0),
            COALESCE(p_failed, 0),
            COALESCE(p_extensionerrors, 0),
            CASE WHEN p_watermarkbefore_clear = TRUE THEN NULL ELSE COALESCE(p_watermarkbefore, NULL) END,
            CASE WHEN p_watermarkafter_clear = TRUE THEN NULL ELSE COALESCE(p_watermarkafter, NULL) END,
            CASE WHEN p_errormessage_clear = TRUE THEN NULL ELSE COALESCE(p_errormessage, NULL) END
        );

    RETURN QUERY
    SELECT "ID", "__mj_CreatedAt", "__mj_UpdatedAt" FROM __mj_bizappscommon."ActivitySyncRun"
    WHERE "ID" = v_new_id;
END;
$$ LANGUAGE plpgsql;
$fn$;

        BEGIN
            GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateActivitySyncRun" TO "cdp_Developer", "cdp_Integration";
        EXCEPTION WHEN others THEN NULL;
        END;

        FOR r IN SELECT oid::regprocedure AS sig
                 FROM pg_proc
                 WHERE proname = 'spUpdateActivitySyncRun'
                   AND pronamespace = '__mj_bizappscommon'::regnamespace
        LOOP
            EXECUTE 'DROP FUNCTION ' || r.sig::text;
        END LOOP;

        EXECUTE $fn$
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spUpdateActivitySyncRun"(
    p_id UUID,
    p_activitysyncconnectionid UUID DEFAULT NULL,
    p_startedat TIMESTAMPTZ DEFAULT NULL,
    p_endedat_clear BOOLEAN DEFAULT FALSE,
    p_endedat TIMESTAMPTZ DEFAULT NULL,
    p_status VARCHAR(20) DEFAULT NULL,
    p_triggertype VARCHAR(20) DEFAULT NULL,
    p_isdryrun BOOLEAN DEFAULT NULL,
    p_fetched INTEGER DEFAULT NULL,
    p_included INTEGER DEFAULT NULL,
    p_excluded INTEGER DEFAULT NULL,
    p_duplicates INTEGER DEFAULT NULL,
    p_failed INTEGER DEFAULT NULL,
    p_extensionerrors INTEGER DEFAULT NULL,
    p_watermarkbefore_clear BOOLEAN DEFAULT FALSE,
    p_watermarkbefore TIMESTAMPTZ DEFAULT NULL,
    p_watermarkafter_clear BOOLEAN DEFAULT FALSE,
    p_watermarkafter TIMESTAMPTZ DEFAULT NULL,
    p_errormessage_clear BOOLEAN DEFAULT FALSE,
    p_errormessage TEXT DEFAULT NULL
) RETURNS TABLE("ID" UUID, "__mj_CreatedAt" TIMESTAMPTZ, "__mj_UpdatedAt" TIMESTAMPTZ) AS $$
#variable_conflict use_column
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE __mj_bizappscommon."ActivitySyncRun"
    SET
        "ActivitySyncConnectionID" = COALESCE(p_activitysyncconnectionid, "ActivitySyncConnectionID"),
        "StartedAt" = COALESCE(p_startedat, "StartedAt"),
        "EndedAt" = CASE WHEN p_endedat_clear = TRUE THEN NULL ELSE COALESCE(p_endedat, "EndedAt") END,
        "Status" = COALESCE(p_status, "Status"),
        "TriggerType" = COALESCE(p_triggertype, "TriggerType"),
        "IsDryRun" = COALESCE(p_isdryrun, "IsDryRun"),
        "Fetched" = COALESCE(p_fetched, "Fetched"),
        "Included" = COALESCE(p_included, "Included"),
        "Excluded" = COALESCE(p_excluded, "Excluded"),
        "Duplicates" = COALESCE(p_duplicates, "Duplicates"),
        "Failed" = COALESCE(p_failed, "Failed"),
        "ExtensionErrors" = COALESCE(p_extensionerrors, "ExtensionErrors"),
        "WatermarkBefore" = CASE WHEN p_watermarkbefore_clear = TRUE THEN NULL ELSE COALESCE(p_watermarkbefore, "WatermarkBefore") END,
        "WatermarkAfter" = CASE WHEN p_watermarkafter_clear = TRUE THEN NULL ELSE COALESCE(p_watermarkafter, "WatermarkAfter") END,
        "ErrorMessage" = CASE WHEN p_errormessage_clear = TRUE THEN NULL ELSE COALESCE(p_errormessage, "ErrorMessage") END
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT "ID", "__mj_CreatedAt", "__mj_UpdatedAt" FROM __mj_bizappscommon."ActivitySyncRun"
    WHERE "ID" = p_id;
END;
$$ LANGUAGE plpgsql;
$fn$;

        BEGIN
            GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateActivitySyncRun" TO "cdp_Developer", "cdp_Integration";
        EXCEPTION WHEN others THEN NULL;
        END;
    END IF;
END
$install_activity_sync_run$;
