-- =============================================================================================
-- PostgreSQL counterpart of V202611061600__v5.61.x__Contact_Method_Consent.sql
-- =============================================================================================
-- `mj sql-convert --from tsql --to postgres` (MJ CLI 6.1.6) output, finished by hand:
--   * Tables, columns, constraints, indexes, views, data and grants are the converter's.
--   * CodeGen's CRUD procedures (spCreate/spUpdate/spDelete), its __mj_UpdatedAt triggers and any
--     hierarchy functions are NOT here: the converter cannot translate T-SQL procedures, triggers
--     or table-valued functions. A PostgreSQL host runs `mj codegen` after installing, which
--     generates them natively. The converter's notes for them remain, fully commented out.
--   * 4 view-rebuild block(s): the target schema lowercased, so the dependent-view rebuild
--     finds the view when its column list changes.
--   * 17 string values restored verbatim from the T-SQL: the converter re-indents text
--     inside string literals and rewrites T-SQL inside stored constraint text and display names.
--   * 5 statements the converter drops (CodeGen's name-field map updates, column
--     description updates) translated by hand at the end of the file.
-- Schema names are written unquoted, as the converter emits them, so they fold to the lowercase
-- schema a PostgreSQL install uses.
-- =============================================================================================

SET standard_conforming_strings = on;

-- ============================================================================
-- MemberJunction PostgreSQL Migration
-- Converted from SQL Server using TypeScript conversion pipeline
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Schema
--
-- The schema name is emitted UNQUOTED, so PostgreSQL folds it to lowercase. That is deliberate and
-- self-consistent: everything downstream in a converted migration refers to it unquoted too, so
-- both definition and lookup land on the same folded name.
--
-- DOWNSTREAM NOTE for the build engineer: a PostgreSQL database that was populated by an EARLIER
-- converter — one that emitted a quoted, case-preserved name — already holds that mixed-case
-- schema: for a target named MySchema_Name, the quoted "MySchema_Name". Re-converting against
-- that database creates a SECOND, empty schema myschema_name rather than reusing the existing
-- one, because IF NOT EXISTS compares the folded name and finds no match. The repo's own committed
-- migrations-pg files are unaffected (the only quoted CREATE SCHEMAs there are the four pg_dump
-- baselines, which this path does not produce), so this is an open-app / downstream concern, not
-- one for this repo's Flyway history.
CREATE SCHEMA IF NOT EXISTS __mj_bizappscommon;
SET search_path TO __mj_bizappscommon, public;

-- Ensure backslashes in string literals are treated literally (not as escape sequences)
SET standard_conforming_strings = on;

-- NOTE: Earlier converter versions made INTEGER to BOOLEAN cast implicit by
-- modifying the system catalog so SS-style INSERT INTO bool_col VALUES (1)
-- would work. That modification required pg_catalog write privileges, which
-- managed PG (RDS, Aurora, Cloud SQL, Azure) does not grant. As of v5.30 all
-- bulk INSERTs are emitted with native TRUE/FALSE values directly, so the
-- cast modification is no longer needed. Removed to support managed-PG
-- installs out of the box.


-- ===================== DDL: Tables, PKs, Indexes =====================

-- =============================================================================
-- Migration: V202611061600__v5.61.x__Contact_Method_Consent.sql
-- Description: Consent per contact method, per purpose, optionally per organization
--              (plans/contact-consent.md)
--              - ConsentPurpose: what a consent is for (Marketing, Transactional, ...), a lookup
--                like ContactType so a customer adds purposes without DDL
--              - ContactMethodConsent: one current status per contact method, (optional) purpose and
--                (optional) organization: a row with no purpose is the general answer for the
--                address, so one email can say yes in general, no to one purpose, no to one sender
--              - ContactMethodConsentHistory: one row per change on a ContactMethodConsent, with when it
--                took effect and where it came from
--              - ContactType.CommunicationBaseMessageTypeID: which MJ communication channel
--                (Email, Phone, SMS) a contact type carries, so code never matches on names
-- =============================================================================

---------------------------------------------------------------------------
-- ContactType: link each type to MJ's Communication Base Message Type
---------------------------------------------------------------------------
ALTER TABLE __mj_BizAppsCommon."ContactType"
 ADD COLUMN IF NOT EXISTS "CommunicationBaseMessageTypeID" UUID NULL;

---------------------------------------------------------------------------
-- ConsentPurpose: what a consent is for
---------------------------------------------------------------------------
CREATE TABLE __mj_BizAppsCommon."ConsentPurpose" (
 "ID" UUID NOT NULL DEFAULT gen_random_uuid(),
 "Name" VARCHAR(100) NOT NULL,
 "Description" TEXT NULL,
 "Sequence" INTEGER NOT NULL DEFAULT 0,
 "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
 CONSTRAINT "PK_ConsentPurpose" PRIMARY KEY ("ID"),
 CONSTRAINT "UQ_ConsentPurpose_Name" UNIQUE ("Name")
);

---------------------------------------------------------------------------
-- ContactMethodConsent: the current status for one contact method, purpose and (optional) organization
---------------------------------------------------------------------------
CREATE TABLE __mj_BizAppsCommon."ContactMethodConsent" (
 "ID" UUID NOT NULL DEFAULT gen_random_uuid(),
 "ContactMethodID" UUID NOT NULL,
 "ConsentPurposeID" UUID NULL,
 "RequestingOrganizationID" UUID NULL,
 "ConsentStatus" VARCHAR(20) NOT NULL DEFAULT 'Not Specified',
 CONSTRAINT "PK_ContactMethodConsent" PRIMARY KEY ("ID"),
 CONSTRAINT "FK_ContactMethodConsent_ContactMethod" FOREIGN KEY ("ContactMethodID")
 REFERENCES __mj_BizAppsCommon."ContactMethod"("ID")
 ON DELETE CASCADE,
 CONSTRAINT "FK_ContactMethodConsent_ConsentPurpose" FOREIGN KEY ("ConsentPurposeID")
 REFERENCES __mj_BizAppsCommon."ConsentPurpose"("ID"),
 CONSTRAINT "FK_ContactMethodConsent_RequestingOrganization" FOREIGN KEY ("RequestingOrganizationID")
 REFERENCES __mj_BizAppsCommon."Organization"("ID"),
 CONSTRAINT "UQ_ContactMethodConsent_Method_Purpose_Organization" UNIQUE ("ContactMethodID", "ConsentPurposeID", "RequestingOrganizationID"),
 CONSTRAINT "CK_ContactMethodConsent_ConsentStatus" CHECK ("ConsentStatus" IN ('Not Specified', 'Opted In', 'Opted Out'))
);

---------------------------------------------------------------------------
-- ContactMethodConsentHistory: one row per change on a ContactMethodConsent
---------------------------------------------------------------------------
CREATE TABLE __mj_BizAppsCommon."ContactMethodConsentHistory" (
 "ID" UUID NOT NULL DEFAULT gen_random_uuid(),
 "ContactMethodConsentID" UUID NOT NULL,
 "NewConsentStatus" VARCHAR(20) NOT NULL,
 "ConsentStatusAt" TIMESTAMPTZ NOT NULL,
 "ConsentSource" VARCHAR(50) NOT NULL DEFAULT 'Staff',
 "RecordedByUserID" UUID NULL,
 "ConsentDetails" TEXT NULL,
 CONSTRAINT "PK_ContactMethodConsentHistory" PRIMARY KEY ("ID"),
 CONSTRAINT "FK_ContactMethodConsentHistory_ContactMethodConsent" FOREIGN KEY ("ContactMethodConsentID")
 REFERENCES __mj_BizAppsCommon."ContactMethodConsent"("ID")
 ON DELETE CASCADE,
 CONSTRAINT "FK_ContactMethodConsentHistory_RecordedByUser" FOREIGN KEY ("RecordedByUserID")
 REFERENCES __mj."User"("ID"),
 CONSTRAINT "CK_ContactMethodConsentHistory_NewConsentStatus" CHECK ("NewConsentStatus" IN ('Not Specified', 'Opted In', 'Opted Out')),
 CONSTRAINT "CK_ContactMethodConsentHistory_ConsentSource" CHECK ("ConsentSource" IN ('Web Form', 'Unsubscribe Link', 'Import', 'Staff', 'Other'))
);

-- The "latest change for this consent" read, which every status resolution does.
CREATE INDEX IF NOT EXISTS IX_ContactMethodConsentHistory_ContactMethodConsent_ConsentStatusAt
    ON __mj_BizAppsCommon."ContactMethodConsentHistory" ("ContactMethodConsentID", ConsentStatusAt DESC);

ALTER TABLE __mj_BizAppsCommon."ContactMethodConsent"
 ADD COLUMN IF NOT EXISTS "__mj_CreatedAt" TIMESTAMPTZ NULL;

/* SQL text to add special date field __mj_UpdatedAt to entity __mj_BizAppsCommon.ContactMethodConsent */
ALTER TABLE __mj_BizAppsCommon."ContactMethodConsent"
 ADD COLUMN IF NOT EXISTS "__mj_UpdatedAt" TIMESTAMPTZ NULL;

/* SQL text to add special date field __mj_CreatedAt to entity __mj_BizAppsCommon.ContactMethodConsentHistory */
ALTER TABLE __mj_BizAppsCommon."ContactMethodConsentHistory"
 ADD COLUMN IF NOT EXISTS "__mj_CreatedAt" TIMESTAMPTZ NULL;

/* SQL text to add special date field __mj_UpdatedAt to entity __mj_BizAppsCommon.ContactMethodConsentHistory */
ALTER TABLE __mj_BizAppsCommon."ContactMethodConsentHistory"
 ADD COLUMN IF NOT EXISTS "__mj_UpdatedAt" TIMESTAMPTZ NULL;

/* SQL text to add special date field __mj_CreatedAt to entity __mj_BizAppsCommon.ConsentPurpose */
ALTER TABLE __mj_BizAppsCommon."ConsentPurpose"
 ADD COLUMN IF NOT EXISTS "__mj_CreatedAt" TIMESTAMPTZ NULL;

/* SQL text to add special date field __mj_UpdatedAt to entity __mj_BizAppsCommon.ConsentPurpose */
ALTER TABLE __mj_BizAppsCommon."ConsentPurpose"
 ADD COLUMN IF NOT EXISTS "__mj_UpdatedAt" TIMESTAMPTZ NULL;

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_ContactMethodConsentHistory_ContactMe_5c8d4fe8" ON __mj_BizAppsCommon."ContactMethodConsentHistory" ("ContactMethodConsentID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_ContactMethodConsentHistory_RecordedByUserID" ON __mj_BizAppsCommon."ContactMethodConsentHistory" ("RecordedByUserID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_ContactMethodConsent_ContactMethodID" ON __mj_BizAppsCommon."ContactMethodConsent" ("ContactMethodID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_ContactMethodConsent_ConsentPurposeID" ON __mj_BizAppsCommon."ContactMethodConsent" ("ConsentPurposeID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_ContactMethodConsent_RequestingOrganizationID" ON __mj_BizAppsCommon."ContactMethodConsent" ("RequestingOrganizationID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_ContactType_CommunicationBaseMessageTypeID" ON __mj_BizAppsCommon."ContactType" ("CommunicationBaseMessageTypeID");


-- ===================== Views =====================

DO $do$
DECLARE
  v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
  v_target_name CONSTANT TEXT := 'vwConsentPurposes';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwConsentPurposes"
AS SELECT
    c.*
FROM
    __mj_BizAppsCommon."ConsentPurpose" AS c$vsql$;
  v_target_oid OID;
  v_dep RECORD;
  v_captured JSONB[] := ARRAY[]::JSONB[];
  v_n INTEGER;
BEGIN
  EXECUTE vsql;
EXCEPTION WHEN invalid_table_definition THEN
  -- Column list changed; need CASCADE. Preserve dependent views first.
  SELECT c.oid INTO v_target_oid
  FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE n.nspname = v_target_schema AND c.relname = v_target_name AND c.relkind = 'v';
  IF v_target_oid IS NOT NULL THEN
    FOR v_dep IN
      WITH RECURSIVE deps AS (
        SELECT c.oid, c.relname AS name, n.nspname AS schema, 1 AS depth
        FROM pg_rewrite r
        JOIN pg_depend d ON d.objid = r.oid
        JOIN pg_class c ON c.oid = r.ev_class
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE d.refobjid = v_target_oid AND d.deptype = 'n'
          AND c.oid <> v_target_oid AND c.relkind = 'v'
        UNION
        SELECT c.oid, c.relname, n.nspname, p.depth + 1
        FROM deps p
        JOIN pg_rewrite r ON TRUE
        JOIN pg_depend d ON d.objid = r.oid AND d.refobjid = p.oid
        JOIN pg_class c ON c.oid = r.ev_class
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE c.relkind = 'v' AND c.oid <> p.oid
      )
      SELECT oid, name, schema, MAX(depth) AS max_depth,
             pg_catalog.pg_get_viewdef(oid, true) AS viewdef
      FROM deps GROUP BY oid, name, schema
      ORDER BY MAX(depth) ASC
    LOOP
      v_captured := v_captured || jsonb_build_object(
        'schema', v_dep.schema, 'name', v_dep.name, 'def', v_dep.viewdef);
    END LOOP;
  END IF;
  EXECUTE format('DROP VIEW IF EXISTS %I.%I CASCADE', v_target_schema, v_target_name);
  EXECUTE vsql;
  IF v_captured IS NOT NULL AND array_length(v_captured, 1) > 0 THEN
    FOR v_n IN 1..array_length(v_captured, 1) LOOP
      BEGIN
        EXECUTE format('CREATE VIEW %I.%I AS %s',
          v_captured[v_n]->>'schema', v_captured[v_n]->>'name', v_captured[v_n]->>'def');
      EXCEPTION WHEN others THEN
        RAISE WARNING 'Could not restore dependent view %.%: %',
          v_captured[v_n]->>'schema', v_captured[v_n]->>'name', SQLERRM;
      END;
    END LOOP;
  END IF;
END;
$do$;

DO $do$
DECLARE
  v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
  v_target_name CONSTANT TEXT := 'vwContactTypes';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwContactTypes"
AS SELECT
    c.*,
    "MJCommunicationBaseMessageType_CommunicationBaseMessageTypeID"."Type" AS "CommunicationBaseMessageType"
FROM
    __mj_BizAppsCommon."ContactType" AS c
LEFT OUTER JOIN
    __mj."CommunicationBaseMessageType" AS "MJCommunicationBaseMessageType_CommunicationBaseMessageTypeID"
  ON
    c."CommunicationBaseMessageTypeID" = "MJCommunicationBaseMessageType_CommunicationBaseMessageTypeID"."ID"$vsql$;
  v_target_oid OID;
  v_dep RECORD;
  v_captured JSONB[] := ARRAY[]::JSONB[];
  v_n INTEGER;
BEGIN
  EXECUTE vsql;
EXCEPTION WHEN invalid_table_definition THEN
  -- Column list changed; need CASCADE. Preserve dependent views first.
  SELECT c.oid INTO v_target_oid
  FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE n.nspname = v_target_schema AND c.relname = v_target_name AND c.relkind = 'v';
  IF v_target_oid IS NOT NULL THEN
    FOR v_dep IN
      WITH RECURSIVE deps AS (
        SELECT c.oid, c.relname AS name, n.nspname AS schema, 1 AS depth
        FROM pg_rewrite r
        JOIN pg_depend d ON d.objid = r.oid
        JOIN pg_class c ON c.oid = r.ev_class
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE d.refobjid = v_target_oid AND d.deptype = 'n'
          AND c.oid <> v_target_oid AND c.relkind = 'v'
        UNION
        SELECT c.oid, c.relname, n.nspname, p.depth + 1
        FROM deps p
        JOIN pg_rewrite r ON TRUE
        JOIN pg_depend d ON d.objid = r.oid AND d.refobjid = p.oid
        JOIN pg_class c ON c.oid = r.ev_class
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE c.relkind = 'v' AND c.oid <> p.oid
      )
      SELECT oid, name, schema, MAX(depth) AS max_depth,
             pg_catalog.pg_get_viewdef(oid, true) AS viewdef
      FROM deps GROUP BY oid, name, schema
      ORDER BY MAX(depth) ASC
    LOOP
      v_captured := v_captured || jsonb_build_object(
        'schema', v_dep.schema, 'name', v_dep.name, 'def', v_dep.viewdef);
    END LOOP;
  END IF;
  EXECUTE format('DROP VIEW IF EXISTS %I.%I CASCADE', v_target_schema, v_target_name);
  EXECUTE vsql;
  IF v_captured IS NOT NULL AND array_length(v_captured, 1) > 0 THEN
    FOR v_n IN 1..array_length(v_captured, 1) LOOP
      BEGIN
        EXECUTE format('CREATE VIEW %I.%I AS %s',
          v_captured[v_n]->>'schema', v_captured[v_n]->>'name', v_captured[v_n]->>'def');
      EXCEPTION WHEN others THEN
        RAISE WARNING 'Could not restore dependent view %.%: %',
          v_captured[v_n]->>'schema', v_captured[v_n]->>'name', SQLERRM;
      END;
    END LOOP;
  END IF;
END;
$do$;

DO $do$
DECLARE
  v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
  v_target_name CONSTANT TEXT := 'vwContactMethodConsentHistories';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwContactMethodConsentHistories"
AS SELECT
    c.*,
    "MJUser_RecordedByUserID"."Name" AS "RecordedByUser"
FROM
    __mj_BizAppsCommon."ContactMethodConsentHistory" AS c
LEFT OUTER JOIN
    __mj."User" AS "MJUser_RecordedByUserID"
  ON
    c."RecordedByUserID" = "MJUser_RecordedByUserID"."ID"$vsql$;
  v_target_oid OID;
  v_dep RECORD;
  v_captured JSONB[] := ARRAY[]::JSONB[];
  v_n INTEGER;
BEGIN
  EXECUTE vsql;
EXCEPTION WHEN invalid_table_definition THEN
  -- Column list changed; need CASCADE. Preserve dependent views first.
  SELECT c.oid INTO v_target_oid
  FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE n.nspname = v_target_schema AND c.relname = v_target_name AND c.relkind = 'v';
  IF v_target_oid IS NOT NULL THEN
    FOR v_dep IN
      WITH RECURSIVE deps AS (
        SELECT c.oid, c.relname AS name, n.nspname AS schema, 1 AS depth
        FROM pg_rewrite r
        JOIN pg_depend d ON d.objid = r.oid
        JOIN pg_class c ON c.oid = r.ev_class
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE d.refobjid = v_target_oid AND d.deptype = 'n'
          AND c.oid <> v_target_oid AND c.relkind = 'v'
        UNION
        SELECT c.oid, c.relname, n.nspname, p.depth + 1
        FROM deps p
        JOIN pg_rewrite r ON TRUE
        JOIN pg_depend d ON d.objid = r.oid AND d.refobjid = p.oid
        JOIN pg_class c ON c.oid = r.ev_class
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE c.relkind = 'v' AND c.oid <> p.oid
      )
      SELECT oid, name, schema, MAX(depth) AS max_depth,
             pg_catalog.pg_get_viewdef(oid, true) AS viewdef
      FROM deps GROUP BY oid, name, schema
      ORDER BY MAX(depth) ASC
    LOOP
      v_captured := v_captured || jsonb_build_object(
        'schema', v_dep.schema, 'name', v_dep.name, 'def', v_dep.viewdef);
    END LOOP;
  END IF;
  EXECUTE format('DROP VIEW IF EXISTS %I.%I CASCADE', v_target_schema, v_target_name);
  EXECUTE vsql;
  IF v_captured IS NOT NULL AND array_length(v_captured, 1) > 0 THEN
    FOR v_n IN 1..array_length(v_captured, 1) LOOP
      BEGIN
        EXECUTE format('CREATE VIEW %I.%I AS %s',
          v_captured[v_n]->>'schema', v_captured[v_n]->>'name', v_captured[v_n]->>'def');
      EXCEPTION WHEN others THEN
        RAISE WARNING 'Could not restore dependent view %.%: %',
          v_captured[v_n]->>'schema', v_captured[v_n]->>'name', SQLERRM;
      END;
    END LOOP;
  END IF;
END;
$do$;

DO $do$
DECLARE
  v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
  v_target_name CONSTANT TEXT := 'vwContactMethodConsents';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwContactMethodConsents"
AS SELECT
    c.*,
    "mjBizAppsCommonContactMethod_ContactMethodID"."Value" AS "ContactMethod",
    "mjBizAppsCommonConsentPurpose_ConsentPurposeID"."Name" AS "ConsentPurpose",
    "mjBizAppsCommonOrganization_RequestingOrganizationID"."Name" AS "RequestingOrganization"
FROM
    __mj_BizAppsCommon."ContactMethodConsent" AS c
INNER JOIN
    __mj_BizAppsCommon."ContactMethod" AS "mjBizAppsCommonContactMethod_ContactMethodID"
  ON
    c."ContactMethodID" = "mjBizAppsCommonContactMethod_ContactMethodID"."ID"
LEFT OUTER JOIN
    __mj_BizAppsCommon."ConsentPurpose" AS "mjBizAppsCommonConsentPurpose_ConsentPurposeID"
  ON
    c."ConsentPurposeID" = "mjBizAppsCommonConsentPurpose_ConsentPurposeID"."ID"
LEFT OUTER JOIN
    __mj_BizAppsCommon."Organization" AS "mjBizAppsCommonOrganization_RequestingOrganizationID"
  ON
    c."RequestingOrganizationID" = "mjBizAppsCommonOrganization_RequestingOrganizationID"."ID"$vsql$;
  v_target_oid OID;
  v_dep RECORD;
  v_captured JSONB[] := ARRAY[]::JSONB[];
  v_n INTEGER;
BEGIN
  EXECUTE vsql;
EXCEPTION WHEN invalid_table_definition THEN
  -- Column list changed; need CASCADE. Preserve dependent views first.
  SELECT c.oid INTO v_target_oid
  FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE n.nspname = v_target_schema AND c.relname = v_target_name AND c.relkind = 'v';
  IF v_target_oid IS NOT NULL THEN
    FOR v_dep IN
      WITH RECURSIVE deps AS (
        SELECT c.oid, c.relname AS name, n.nspname AS schema, 1 AS depth
        FROM pg_rewrite r
        JOIN pg_depend d ON d.objid = r.oid
        JOIN pg_class c ON c.oid = r.ev_class
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE d.refobjid = v_target_oid AND d.deptype = 'n'
          AND c.oid <> v_target_oid AND c.relkind = 'v'
        UNION
        SELECT c.oid, c.relname, n.nspname, p.depth + 1
        FROM deps p
        JOIN pg_rewrite r ON TRUE
        JOIN pg_depend d ON d.objid = r.oid AND d.refobjid = p.oid
        JOIN pg_class c ON c.oid = r.ev_class
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE c.relkind = 'v' AND c.oid <> p.oid
      )
      SELECT oid, name, schema, MAX(depth) AS max_depth,
             pg_catalog.pg_get_viewdef(oid, true) AS viewdef
      FROM deps GROUP BY oid, name, schema
      ORDER BY MAX(depth) ASC
    LOOP
      v_captured := v_captured || jsonb_build_object(
        'schema', v_dep.schema, 'name', v_dep.name, 'def', v_dep.viewdef);
    END LOOP;
  END IF;
  EXECUTE format('DROP VIEW IF EXISTS %I.%I CASCADE', v_target_schema, v_target_name);
  EXECUTE vsql;
  IF v_captured IS NOT NULL AND array_length(v_captured, 1) > 0 THEN
    FOR v_n IN 1..array_length(v_captured, 1) LOOP
      BEGIN
        EXECUTE format('CREATE VIEW %I.%I AS %s',
          v_captured[v_n]->>'schema', v_captured[v_n]->>'name', v_captured[v_n]->>'def');
      EXCEPTION WHEN others THEN
        RAISE WARNING 'Could not restore dependent view %.%: %',
          v_captured[v_n]->>'schema', v_captured[v_n]->>'name', SQLERRM;
      END;
    END LOOP;
  END IF;
END;
$do$;


-- ===================== Stored Procedures (sp*) =====================

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spCreateConsentPurpose]
--     @ID UUID = NULL,
--     @Name VARCHAR(100),
--     @Description_Clear bit = 0,
--     @Description TEXT = NULL,
--     @Seq...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spUpdateConsentPurpose]
--     @ID UUID,
--     @Name VARCHAR(100) = NULL,
--     @Description_Clear bit = 0,
--     @Description TEXT = NULL,
--     @Seq...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spDeleteConsentPurpose]
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         [__mj_BizAppsCommon].[ConsentPurpose]
--     WHERE
--         [I...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spCreateContactType]
--     @ID UUID = NULL,
--     @Name VARCHAR(100),
--     @Description_Clear bit = 0,
--     @Description TEXT = NULL,
--     @IconCl...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spUpdateContactType]
--     @ID UUID,
--     @Name VARCHAR(100) = NULL,
--     @Description_Clear bit = 0,
--     @Description TEXT = NULL,
--     @IconCl...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spDeleteContactType]
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         [__mj_BizAppsCommon].[ContactType]
--     WHERE
--         [ID] = @...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spCreateContactMethodConsentHistory]
--     @ID UUID = NULL,
--     @ContactMethodConsentID UUID,
--     @NewConsentStatus VARCHAR(20),
--     @Cons...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spUpdateContactMethodConsentHistory]
--     @ID UUID,
--     @ContactMethodConsentID UUID = NULL,
--     @NewConsentStatus VARCHAR(20) = NULL,
--   ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spDeleteContactMethodConsentHistory]
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         [__mj_BizAppsCommon].[ContactMethodConsentHis...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spCreateContactMethodConsent]
--     @ID UUID = NULL,
--     @ContactMethodID UUID,
--     @ConsentPurposeID_Clear bit = 0,
--     @ConsentPurposeID ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spUpdateContactMethodConsent]
--     @ID UUID,
--     @ContactMethodID UUID = NULL,
--     @ConsentPurposeID_Clear bit = 0,
--     @ConsentPurposeID ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spDeleteContactMethodConsent]
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         [__mj_BizAppsCommon].[ContactMethodConsent]
--     WHER...


-- ===================== Triggers =====================

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_BizAppsCommon].trgUpdateConsentPurpose
-- ON "__mj_BizAppsCommon"."ConsentPurpose"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         "__mj_BizAppsCommon"."ConsentPurpose"


-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_BizAppsCommon].trgUpdateContactType
-- ON "__mj_BizAppsCommon"."ContactType"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         "__mj_BizAppsCommon"."ContactType"
--     SET
 

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_BizAppsCommon].trgUpdateContactMethodConsentHistory
-- ON "__mj_BizAppsCommon"."ContactMethodConsentHistory"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         "__mj_BizApp

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_BizAppsCommon".trgUpdateContactMethodConsent
-- ON "__mj_BizAppsCommon"."ContactMethodConsent"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         "__mj_BizAppsCommon".[Cont


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

INSERT INTO __mj."Entity" (
         "ID",
         "Name",
         "DisplayName",
         "Description",
         "NameSuffix",
         "BaseTable",
         "BaseView",
         "SchemaName",
         "IncludeInAPI",
         "AllowUserSearchAPI",
         "AllowCaching",
         "TrackRecordChanges",
         "AuditRecordAccess",
         "AuditViewRuns",
         "AllowAllRowsAPI",
         "AllowCreateAPI",
         "AllowUpdateAPI",
         "AllowDeleteAPI",
         "UserViewMaxRows"
         , "__mj_CreatedAt"
         , "__mj_UpdatedAt"
      )
      VALUES (
         '2fb1367b-6f20-45be-af8d-ab205ddb6452',
         'MJ_BizApps_Common: Consent Purposes',
         'Consent Purposes',
         'What a consent is for. Common seeds the generic purposes, Marketing and Transactional; apps built on Common add their own. Consent is recorded per contact method and purpose, so one email can be opted in for transactional messages and opted out of marketing. Seeded by metadata; add rows rather than columns.',
         NULL,
         'ConsentPurpose',
         'vwConsentPurposes',
         '__mj_BizAppsCommon',
         TRUE,
         TRUE,
         FALSE,
         TRUE,
         FALSE,
         FALSE,
         FALSE,
         TRUE,
         TRUE,
         TRUE,
         1000
         , NOW()
         , NOW()
      );

/* SQL generated to add new entity MJ_BizApps_Common: Consent Purposes to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */

INSERT INTO __mj."ApplicationEntity"
                                       ("ApplicationID", "EntityID", "Sequence", "__mj_CreatedAt", "__mj_UpdatedAt") VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '2fb1367b-6f20-45be-af8d-ab205ddb6452', (SELECT COALESCE(MAX("Sequence"),0)+1 FROM __mj."ApplicationEntity" WHERE "ApplicationID" = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), NOW(), NOW());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Consent Purposes for role UI */

INSERT INTO __mj."EntityPermission"
                ("EntityID", "RoleID", "Type", "CanRead", "CanCreate", "CanUpdate", "CanDelete", "__mj_CreatedAt", "__mj_UpdatedAt")
              SELECT CAST('2fb1367b-6f20-45be-af8d-ab205ddb6452' AS UUID), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID), 'Allow', 1, 0, 0, 0, NOW(), NOW()
              WHERE NOT EXISTS (
                SELECT 1 FROM __mj."EntityPermission"
                WHERE "EntityID" = CAST('2fb1367b-6f20-45be-af8d-ab205ddb6452' AS UUID) AND "RoleID" = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID) AND "Type" = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Consent Purposes for role Developer */

INSERT INTO __mj."EntityPermission"
                ("EntityID", "RoleID", "Type", "CanRead", "CanCreate", "CanUpdate", "CanDelete", "__mj_CreatedAt", "__mj_UpdatedAt")
              SELECT CAST('2fb1367b-6f20-45be-af8d-ab205ddb6452' AS UUID), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID), 'Allow', 1, 1, 1, 1, NOW(), NOW()
              WHERE NOT EXISTS (
                SELECT 1 FROM __mj."EntityPermission"
                WHERE "EntityID" = CAST('2fb1367b-6f20-45be-af8d-ab205ddb6452' AS UUID) AND "RoleID" = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID) AND "Type" = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Consent Purposes for role Integration */

INSERT INTO __mj."EntityPermission"
                ("EntityID", "RoleID", "Type", "CanRead", "CanCreate", "CanUpdate", "CanDelete", "__mj_CreatedAt", "__mj_UpdatedAt")
              SELECT CAST('2fb1367b-6f20-45be-af8d-ab205ddb6452' AS UUID), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID), 'Allow', 1, 1, 1, 1, NOW(), NOW()
              WHERE NOT EXISTS (
                SELECT 1 FROM __mj."EntityPermission"
                WHERE "EntityID" = CAST('2fb1367b-6f20-45be-af8d-ab205ddb6452' AS UUID) AND "RoleID" = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID) AND "Type" = 'Allow'
              );

/* SQL generated to create new entity MJ_BizApps_Common: Contact Method Consents */

INSERT INTO __mj."Entity" (
         "ID",
         "Name",
         "DisplayName",
         "Description",
         "NameSuffix",
         "BaseTable",
         "BaseView",
         "SchemaName",
         "IncludeInAPI",
         "AllowUserSearchAPI",
         "AllowCaching",
         "TrackRecordChanges",
         "AuditRecordAccess",
         "AuditViewRuns",
         "AllowAllRowsAPI",
         "AllowCreateAPI",
         "AllowUpdateAPI",
         "AllowDeleteAPI",
         "UserViewMaxRows"
         , "__mj_CreatedAt"
         , "__mj_UpdatedAt"
      )
      VALUES (
         '3c3827e7-d90c-4c0f-8e41-2c2a17dafd31',
         'MJ_BizApps_Common: Contact Method Consents',
         'Contact Method Consents',
         'The current consent for one contact method (an email or phone): for one purpose or, when ConsentPurposeID is null, for anything; as asked by one organization or, when RequestingOrganizationID is null, by anyone on the installation. A contact method has many of these, the way a person has many contact methods, and the most specific row answers: purpose and organization, then purpose, then organization, then the general row. ConsentStatus always equals NewConsentStatus on the ContactMethodConsentHistory row with the latest ConsentStatusAt. Set it through ContactPreferenceEngine, which writes the history row with it. Deleting the contact method deletes its consents.',
         NULL,
         'ContactMethodConsent',
         'vwContactMethodConsents',
         '__mj_BizAppsCommon',
         TRUE,
         TRUE,
         FALSE,
         TRUE,
         FALSE,
         FALSE,
         FALSE,
         TRUE,
         TRUE,
         TRUE,
         1000
         , NOW()
         , NOW()
      );

/* SQL generated to add new entity MJ_BizApps_Common: Contact Method Consents to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */

INSERT INTO __mj."ApplicationEntity"
                                       ("ApplicationID", "EntityID", "Sequence", "__mj_CreatedAt", "__mj_UpdatedAt") VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '3c3827e7-d90c-4c0f-8e41-2c2a17dafd31', (SELECT COALESCE(MAX("Sequence"),0)+1 FROM __mj."ApplicationEntity" WHERE "ApplicationID" = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), NOW(), NOW());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Method Consents for role UI */

INSERT INTO __mj."EntityPermission"
                ("EntityID", "RoleID", "Type", "CanRead", "CanCreate", "CanUpdate", "CanDelete", "__mj_CreatedAt", "__mj_UpdatedAt")
              SELECT CAST('3c3827e7-d90c-4c0f-8e41-2c2a17dafd31' AS UUID), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID), 'Allow', 1, 0, 0, 0, NOW(), NOW()
              WHERE NOT EXISTS (
                SELECT 1 FROM __mj."EntityPermission"
                WHERE "EntityID" = CAST('3c3827e7-d90c-4c0f-8e41-2c2a17dafd31' AS UUID) AND "RoleID" = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID) AND "Type" = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Method Consents for role Developer */

INSERT INTO __mj."EntityPermission"
                ("EntityID", "RoleID", "Type", "CanRead", "CanCreate", "CanUpdate", "CanDelete", "__mj_CreatedAt", "__mj_UpdatedAt")
              SELECT CAST('3c3827e7-d90c-4c0f-8e41-2c2a17dafd31' AS UUID), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID), 'Allow', 1, 1, 1, 1, NOW(), NOW()
              WHERE NOT EXISTS (
                SELECT 1 FROM __mj."EntityPermission"
                WHERE "EntityID" = CAST('3c3827e7-d90c-4c0f-8e41-2c2a17dafd31' AS UUID) AND "RoleID" = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID) AND "Type" = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Method Consents for role Integration */

INSERT INTO __mj."EntityPermission"
                ("EntityID", "RoleID", "Type", "CanRead", "CanCreate", "CanUpdate", "CanDelete", "__mj_CreatedAt", "__mj_UpdatedAt")
              SELECT CAST('3c3827e7-d90c-4c0f-8e41-2c2a17dafd31' AS UUID), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID), 'Allow', 1, 1, 1, 1, NOW(), NOW()
              WHERE NOT EXISTS (
                SELECT 1 FROM __mj."EntityPermission"
                WHERE "EntityID" = CAST('3c3827e7-d90c-4c0f-8e41-2c2a17dafd31' AS UUID) AND "RoleID" = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID) AND "Type" = 'Allow'
              );

/* SQL generated to create new entity MJ_BizApps_Common: Contact Method Consent Histories */

INSERT INTO __mj."Entity" (
         "ID",
         "Name",
         "DisplayName",
         "Description",
         "NameSuffix",
         "BaseTable",
         "BaseView",
         "SchemaName",
         "IncludeInAPI",
         "AllowUserSearchAPI",
         "AllowCaching",
         "TrackRecordChanges",
         "AuditRecordAccess",
         "AuditViewRuns",
         "AllowAllRowsAPI",
         "AllowCreateAPI",
         "AllowUpdateAPI",
         "AllowDeleteAPI",
         "UserViewMaxRows"
         , "__mj_CreatedAt"
         , "__mj_UpdatedAt"
      )
      VALUES (
         'ca348384-97e9-4a6f-a28b-56dc169c0051',
         'MJ_BizApps_Common: Contact Method Consent Histories',
         'Contact Method Consent Histories',
         'One row per change on a ContactMethodConsent: the status it set, when it took effect in the real world, and where it came from. ContactMethodConsent.ConsentStatus mirrors the row with the latest ConsentStatusAt. A late-arriving change with an older date is kept here but does not change the current status. Deleting the consent deletes its history.',
         NULL,
         'ContactMethodConsentHistory',
         'vwContactMethodConsentHistories',
         '__mj_BizAppsCommon',
         TRUE,
         TRUE,
         FALSE,
         TRUE,
         FALSE,
         FALSE,
         FALSE,
         TRUE,
         TRUE,
         TRUE,
         1000
         , NOW()
         , NOW()
      );

/* SQL generated to add new entity MJ_BizApps_Common: Contact Method Consent Histories to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */

INSERT INTO __mj."ApplicationEntity"
                                       ("ApplicationID", "EntityID", "Sequence", "__mj_CreatedAt", "__mj_UpdatedAt") VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'ca348384-97e9-4a6f-a28b-56dc169c0051', (SELECT COALESCE(MAX("Sequence"),0)+1 FROM __mj."ApplicationEntity" WHERE "ApplicationID" = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), NOW(), NOW());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Method Consent Histories for role UI */

INSERT INTO __mj."EntityPermission"
                ("EntityID", "RoleID", "Type", "CanRead", "CanCreate", "CanUpdate", "CanDelete", "__mj_CreatedAt", "__mj_UpdatedAt")
              SELECT CAST('ca348384-97e9-4a6f-a28b-56dc169c0051' AS UUID), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID), 'Allow', 1, 0, 0, 0, NOW(), NOW()
              WHERE NOT EXISTS (
                SELECT 1 FROM __mj."EntityPermission"
                WHERE "EntityID" = CAST('ca348384-97e9-4a6f-a28b-56dc169c0051' AS UUID) AND "RoleID" = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID) AND "Type" = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Method Consent Histories for role Developer */

INSERT INTO __mj."EntityPermission"
                ("EntityID", "RoleID", "Type", "CanRead", "CanCreate", "CanUpdate", "CanDelete", "__mj_CreatedAt", "__mj_UpdatedAt")
              SELECT CAST('ca348384-97e9-4a6f-a28b-56dc169c0051' AS UUID), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID), 'Allow', 1, 1, 1, 1, NOW(), NOW()
              WHERE NOT EXISTS (
                SELECT 1 FROM __mj."EntityPermission"
                WHERE "EntityID" = CAST('ca348384-97e9-4a6f-a28b-56dc169c0051' AS UUID) AND "RoleID" = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID) AND "Type" = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Method Consent Histories for role Integration */

INSERT INTO __mj."EntityPermission"
                ("EntityID", "RoleID", "Type", "CanRead", "CanCreate", "CanUpdate", "CanDelete", "__mj_CreatedAt", "__mj_UpdatedAt")
              SELECT CAST('ca348384-97e9-4a6f-a28b-56dc169c0051' AS UUID), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID), 'Allow', 1, 1, 1, 1, NOW(), NOW()
              WHERE NOT EXISTS (
                SELECT 1 FROM __mj."EntityPermission"
                WHERE "EntityID" = CAST('ca348384-97e9-4a6f-a28b-56dc169c0051' AS UUID) AND "RoleID" = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID) AND "Type" = 'Allow'
              );

/* SQL text to add special date field __mj_CreatedAt to entity __mj_BizAppsCommon.ContactMethodConsent */

/* SQL text to add special date field __mj_CreatedAt to entity __mj_BizAppsCommon.ContactMethodConsent */
UPDATE "__mj_BizAppsCommon"."ContactMethodConsent" SET "__mj_CreatedAt" = NOW() WHERE "__mj_CreatedAt" IS NULL;

/* SQL text to add special date field __mj_CreatedAt to entity __mj_BizAppsCommon.ContactMethodConsent */
ALTER TABLE __mj_BizAppsCommon."ContactMethodConsent" ALTER COLUMN "__mj_CreatedAt" SET NOT NULL;

ALTER TABLE __mj_BizAppsCommon."ContactMethodConsent"
  ALTER COLUMN "__mj_CreatedAt" SET DEFAULT NOW();

/* SQL text to add special date field __mj_UpdatedAt to entity __mj_BizAppsCommon.ContactMethodConsent */
UPDATE "__mj_BizAppsCommon"."ContactMethodConsent" SET "__mj_UpdatedAt" = NOW() WHERE "__mj_UpdatedAt" IS NULL;

/* SQL text to add special date field __mj_UpdatedAt to entity __mj_BizAppsCommon.ContactMethodConsent */
ALTER TABLE __mj_BizAppsCommon."ContactMethodConsent" ALTER COLUMN "__mj_UpdatedAt" SET NOT NULL;

ALTER TABLE __mj_BizAppsCommon."ContactMethodConsent"
  ALTER COLUMN "__mj_UpdatedAt" SET DEFAULT NOW();

/* SQL text to add special date field __mj_CreatedAt to entity __mj_BizAppsCommon.ContactMethodConsentHistory */
UPDATE "__mj_BizAppsCommon"."ContactMethodConsentHistory" SET "__mj_CreatedAt" = NOW() WHERE "__mj_CreatedAt" IS NULL;

/* SQL text to add special date field __mj_CreatedAt to entity __mj_BizAppsCommon.ContactMethodConsentHistory */
ALTER TABLE __mj_BizAppsCommon."ContactMethodConsentHistory" ALTER COLUMN "__mj_CreatedAt" SET NOT NULL;

ALTER TABLE __mj_BizAppsCommon."ContactMethodConsentHistory"
  ALTER COLUMN "__mj_CreatedAt" SET DEFAULT NOW();

/* SQL text to add special date field __mj_UpdatedAt to entity __mj_BizAppsCommon.ContactMethodConsentHistory */
UPDATE "__mj_BizAppsCommon"."ContactMethodConsentHistory" SET "__mj_UpdatedAt" = NOW() WHERE "__mj_UpdatedAt" IS NULL;

/* SQL text to add special date field __mj_UpdatedAt to entity __mj_BizAppsCommon.ContactMethodConsentHistory */
ALTER TABLE __mj_BizAppsCommon."ContactMethodConsentHistory" ALTER COLUMN "__mj_UpdatedAt" SET NOT NULL;

ALTER TABLE __mj_BizAppsCommon."ContactMethodConsentHistory"
  ALTER COLUMN "__mj_UpdatedAt" SET DEFAULT NOW();

/* SQL text to add special date field __mj_CreatedAt to entity __mj_BizAppsCommon.ConsentPurpose */
UPDATE "__mj_BizAppsCommon"."ConsentPurpose" SET "__mj_CreatedAt" = NOW() WHERE "__mj_CreatedAt" IS NULL;

/* SQL text to add special date field __mj_CreatedAt to entity __mj_BizAppsCommon.ConsentPurpose */
ALTER TABLE __mj_BizAppsCommon."ConsentPurpose" ALTER COLUMN "__mj_CreatedAt" SET NOT NULL;

ALTER TABLE __mj_BizAppsCommon."ConsentPurpose"
  ALTER COLUMN "__mj_CreatedAt" SET DEFAULT NOW();

/* SQL text to add special date field __mj_UpdatedAt to entity __mj_BizAppsCommon.ConsentPurpose */
UPDATE "__mj_BizAppsCommon"."ConsentPurpose" SET "__mj_UpdatedAt" = NOW() WHERE "__mj_UpdatedAt" IS NULL;

/* SQL text to add special date field __mj_UpdatedAt to entity __mj_BizAppsCommon.ConsentPurpose */
ALTER TABLE __mj_BizAppsCommon."ConsentPurpose" ALTER COLUMN "__mj_UpdatedAt" SET NOT NULL;

ALTER TABLE __mj_BizAppsCommon."ConsentPurpose"
  ALTER COLUMN "__mj_UpdatedAt" SET DEFAULT NOW();

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = '63580dc7-71eb-464a-9d9b-69ca81e53e18' OR ("EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND "Name" = 'ID')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        '63580dc7-71eb-464a-9d9b-69ca81e53e18',
        '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consents"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
        'ID',
        'ID',
        NULL,
        'UUID',
        16,
        0,
        0,
        FALSE,
        'gen_random_uuid()',
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        TRUE,
        TRUE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = 'db56ea60-777b-4a0e-abdb-c32089f26ebb' OR ("EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND "Name" = 'ContactMethodID')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        'db56ea60-777b-4a0e-abdb-c32089f26ebb',
        '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consents"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
        'ContactMethodID',
        'Contact Method ID',
        NULL,
        'UUID',
        16,
        0,
        0,
        FALSE,
        NULL,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        '32C45078-D33B-4760-9BE5-0DF7F483F591',
        'ID',
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        TRUE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = '428c56b9-02b4-4042-b3ec-6d94fb052fc7' OR ("EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND "Name" = 'ConsentPurposeID')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        '428c56b9-02b4-4042-b3ec-6d94fb052fc7',
        '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consents"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
        'ConsentPurposeID',
        'Consent Purpose ID',
        NULL,
        'UUID',
        16,
        0,
        0,
        TRUE,
        NULL,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        '2FB1367B-6F20-45BE-AF8D-AB205DDB6452',
        'ID',
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        TRUE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = 'cc1dfbb8-63bc-42ce-a127-36081c6c1f88' OR ("EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND "Name" = 'RequestingOrganizationID')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        'cc1dfbb8-63bc-42ce-a127-36081c6c1f88',
        '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consents"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
        'RequestingOrganizationID',
        'Requesting Organization ID',
        'The organization that asked for this consent, when the person answered differently for different organizations. Null means the answer applies to anyone on the installation. This is not the owner of the contact method; that is ContactMethod.PersonID or ContactMethod.OrganizationID.',
        'UUID',
        16,
        0,
        0,
        TRUE,
        NULL,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        'C70448F9-9792-41D7-A82C-784B66429D54',
        'ID',
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        TRUE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = '9be6252d-83c6-4635-956c-9098df0e3267' OR ("EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND "Name" = 'ConsentStatus')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        '9be6252d-83c6-4635-956c-9098df0e3267',
        '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consents"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
        'ConsentStatus',
        'Consent Status',
        'The current consent: Not Specified, Opted In or Opted Out.',
        'TEXT',
        40,
        0,
        0,
        FALSE,
        'Not Specified',
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = '8ee39d4d-0833-44e0-89a4-ad99417228b0' OR ("EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND "Name" = '__mj_CreatedAt')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        '8ee39d4d-0833-44e0-89a4-ad99417228b0',
        '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consents"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
        '__mj_CreatedAt',
        'Created At',
        NULL,
        'TIMESTAMPTZ',
        10,
        34,
        7,
        FALSE,
        'NOW()',
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = 'f181e819-0dd8-4d42-b5ce-09ff372059ac' OR ("EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND "Name" = '__mj_UpdatedAt')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        'f181e819-0dd8-4d42-b5ce-09ff372059ac',
        '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consents"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
        '__mj_UpdatedAt',
        'Updated At',
        NULL,
        'TIMESTAMPTZ',
        10,
        34,
        7,
        FALSE,
        'NOW()',
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = 'f0de470d-3ca4-4984-868c-d2e40e70da6d' OR ("EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND "Name" = 'ID')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        'f0de470d-3ca4-4984-868c-d2e40e70da6d',
        'CA348384-97E9-4A6F-A28B-56DC169C0051', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consent" "Histories"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
        'ID',
        'ID',
        NULL,
        'UUID',
        16,
        0,
        0,
        FALSE,
        'gen_random_uuid()',
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        TRUE,
        TRUE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = 'd7390a2a-889b-4e17-8acd-6e84473159db' OR ("EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND "Name" = 'ContactMethodConsentID')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        'd7390a2a-889b-4e17-8acd-6e84473159db',
        'CA348384-97E9-4A6F-A28B-56DC169C0051', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consent" "Histories"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
        'ContactMethodConsentID',
        'Contact Method Consent ID',
        NULL,
        'UUID',
        16,
        0,
        0,
        FALSE,
        NULL,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31',
        'ID',
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = 'f3731712-44b4-49e6-ae78-6427358aca2f' OR ("EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND "Name" = 'NewConsentStatus')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        'f3731712-44b4-49e6-ae78-6427358aca2f',
        'CA348384-97E9-4A6F-A28B-56DC169C0051', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consent" "Histories"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
        'NewConsentStatus',
        'New Consent Status',
        'The consent status this change set: Not Specified, Opted In or Opted Out.',
        'TEXT',
        40,
        0,
        0,
        FALSE,
        NULL,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = '4f09cf64-7ab8-4c54-ab0b-76abb393fce8' OR ("EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND "Name" = 'ConsentStatusAt')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        '4f09cf64-7ab8-4c54-ab0b-76abb393fce8',
        'CA348384-97E9-4A6F-A28B-56DC169C0051', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consent" "Histories"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
        'ConsentStatusAt',
        'Consent Status At',
        'When the change took effect in the real world (the unsubscribe click, the form submission, the import''s own date), not when this row was saved. The row with the latest value is the current status.',
        'TIMESTAMPTZ',
        10,
        34,
        7,
        FALSE,
        NULL,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = '3c7ec1d1-f253-4860-9d9b-3be7263bf939' OR ("EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND "Name" = 'ConsentSource')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        '3c7ec1d1-f253-4860-9d9b-3be7263bf939',
        'CA348384-97E9-4A6F-A28B-56DC169C0051', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consent" "Histories"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
        'ConsentSource',
        'Consent Source',
        'Where the change came from: Web Form, Unsubscribe Link, Import, Staff or Other. Defaults to Staff, for a change made by a person in the app. The specifics, such as which system an import came from or what Other was, go in ConsentDetails.',
        'TEXT',
        100,
        0,
        0,
        FALSE,
        'Staff',
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = '49a2005b-27b9-4c8a-84c9-50148f4b9284' OR ("EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND "Name" = 'RecordedByUserID')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        '49a2005b-27b9-4c8a-84c9-50148f4b9284',
        'CA348384-97E9-4A6F-A28B-56DC169C0051', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consent" "Histories"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
        'RecordedByUserID',
        'Recorded By User ID',
        NULL,
        'UUID',
        16,
        0,
        0,
        TRUE,
        NULL,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        'E1238F34-2837-EF11-86D4-6045BDEE16E6',
        'ID',
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = 'bb5dd18b-b73d-4c65-bf5b-936c1674f35a' OR ("EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND "Name" = 'ConsentDetails')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        'bb5dd18b-b73d-4c65-bf5b-936c1674f35a',
        'CA348384-97E9-4A6F-A28B-56DC169C0051', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consent" "Histories"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
        'ConsentDetails',
        'Consent Details',
        'The specifics of the change: which system an import came from, what an Other source was, or evidence such as a form ID or the unsubscribe email''s message ID.',
        'TEXT',
        -1,
        0,
        0,
        TRUE,
        NULL,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = 'b05d0298-ef0f-4725-a66b-5c6489c1aceb' OR ("EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND "Name" = '__mj_CreatedAt')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        'b05d0298-ef0f-4725-a66b-5c6489c1aceb',
        'CA348384-97E9-4A6F-A28B-56DC169C0051', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consent" "Histories"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
        '__mj_CreatedAt',
        'Created At',
        NULL,
        'TIMESTAMPTZ',
        10,
        34,
        7,
        FALSE,
        'NOW()',
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = '4b667580-df5e-4b1c-bc4a-0a306f8e2a0e' OR ("EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND "Name" = '__mj_UpdatedAt')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        '4b667580-df5e-4b1c-bc4a-0a306f8e2a0e',
        'CA348384-97E9-4A6F-A28B-56DC169C0051', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consent" "Histories"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
        '__mj_UpdatedAt',
        'Updated At',
        NULL,
        'TIMESTAMPTZ',
        10,
        34,
        7,
        FALSE,
        'NOW()',
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = '438b7dbe-f13b-42ef-97a3-5d952b58e2e3' OR ("EntityID" = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND "Name" = 'CommunicationBaseMessageTypeID')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        '438b7dbe-f13b-42ef-97a3-5d952b58e2e3',
        '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', -- "Entity": "MJ_BizApps_Common": "Contact" "Types"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5'),
        'CommunicationBaseMessageTypeID',
        'Communication Base Message Type ID',
        NULL,
        'UUID',
        16,
        0,
        0,
        TRUE,
        NULL,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        '47248F34-2837-EF11-86D4-6045BDEE16E6',
        'ID',
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = '7071f4ce-e586-4b98-aa23-fecf40b4eb85' OR ("EntityID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452' AND "Name" = 'ID')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        '7071f4ce-e586-4b98-aa23-fecf40b4eb85',
        '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', -- "Entity": "MJ_BizApps_Common": "Consent" "Purposes"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452'),
        'ID',
        'ID',
        NULL,
        'UUID',
        16,
        0,
        0,
        FALSE,
        'gen_random_uuid()',
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        TRUE,
        TRUE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = '0efc615d-26a6-4583-97d0-e92d643b4ded' OR ("EntityID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452' AND "Name" = 'Name')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        '0efc615d-26a6-4583-97d0-e92d643b4ded',
        '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', -- "Entity": "MJ_BizApps_Common": "Consent" "Purposes"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452'),
        'Name',
        'Name',
        'Display name of the purpose, unique within the installation.',
        'TEXT',
        200,
        0,
        0,
        FALSE,
        NULL,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        TRUE,
        TRUE,
        FALSE,
        TRUE,
        FALSE,
        TRUE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = '822c3037-da30-41ef-b10d-b9e545d328f7' OR ("EntityID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452' AND "Name" = 'Description')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        '822c3037-da30-41ef-b10d-b9e545d328f7',
        '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', -- "Entity": "MJ_BizApps_Common": "Consent" "Purposes"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452'),
        'Description',
        'Description',
        'What kinds of messages this purpose covers.',
        'TEXT',
        -1,
        0,
        0,
        TRUE,
        NULL,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = 'c2d551f0-e612-47be-895c-e9e2d46acd1d' OR ("EntityID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452' AND "Name" = 'Sequence')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        'c2d551f0-e612-47be-895c-e9e2d46acd1d',
        '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', -- "Entity": "MJ_BizApps_Common": "Consent" "Purposes"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452'),
        'Sequence',
        'Sequence',
        'Sort order in dropdown lists. Lower values appear first.',
        'INTEGER',
        4,
        10,
        0,
        FALSE,
        '(0)',
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = '664cccaa-627f-4345-ae53-e37c28731a33' OR ("EntityID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452' AND "Name" = 'IsActive')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        '664cccaa-627f-4345-ae53-e37c28731a33',
        '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', -- "Entity": "MJ_BizApps_Common": "Consent" "Purposes"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452'),
        'IsActive',
        'Is Active',
        'Whether this purpose is offered for new consents. Inactive purposes are hidden from dropdowns but preserved for existing records.',
        'BOOLEAN',
        1,
        1,
        0,
        FALSE,
        '(1)',
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = 'f2df4de8-3bdd-4eba-a349-b2efc2d7c362' OR ("EntityID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452' AND "Name" = '__mj_CreatedAt')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        'f2df4de8-3bdd-4eba-a349-b2efc2d7c362',
        '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', -- "Entity": "MJ_BizApps_Common": "Consent" "Purposes"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452'),
        '__mj_CreatedAt',
        'Created At',
        NULL,
        'TIMESTAMPTZ',
        10,
        34,
        7,
        FALSE,
        'NOW()',
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = 'c22f89cd-2eef-4ff7-bf60-58ccb001354d' OR ("EntityID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452' AND "Name" = '__mj_UpdatedAt')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        'c22f89cd-2eef-4ff7-bf60-58ccb001354d',
        '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', -- "Entity": "MJ_BizApps_Common": "Consent" "Purposes"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452'),
        '__mj_UpdatedAt',
        'Updated At',
        NULL,
        'TIMESTAMPTZ',
        10,
        34,
        7,
        FALSE,
        'NOW()',
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

INSERT INTO __mj."EntityFieldValue"
                                       ("ID", "EntityFieldID", "Sequence", "Value", "Code", "__mj_CreatedAt", "__mj_UpdatedAt")
                                    VALUES
                                       ('074b1447-88b9-427e-ad98-9f963a13dc0d', '9BE6252D-83C6-4635-956C-9098DF0E3267', 1, 'Not Specified', 'Not Specified', NOW(), NOW());

/* SQL text to insert entity field value with ID 62392435-049d-4c73-ae34-bdc63c76bd50 */

INSERT INTO __mj."EntityFieldValue"
                                       ("ID", "EntityFieldID", "Sequence", "Value", "Code", "__mj_CreatedAt", "__mj_UpdatedAt")
                                    VALUES
                                       ('62392435-049d-4c73-ae34-bdc63c76bd50', '9BE6252D-83C6-4635-956C-9098DF0E3267', 2, 'Opted In', 'Opted In', NOW(), NOW());

/* SQL text to insert entity field value with ID edf117d1-f532-4862-b995-37d39459ce6f */

INSERT INTO __mj."EntityFieldValue"
                                       ("ID", "EntityFieldID", "Sequence", "Value", "Code", "__mj_CreatedAt", "__mj_UpdatedAt")
                                    VALUES
                                       ('edf117d1-f532-4862-b995-37d39459ce6f', '9BE6252D-83C6-4635-956C-9098DF0E3267', 3, 'Opted Out', 'Opted Out', NOW(), NOW());

/* SQL text to update ValueListType for entity field ID 9BE6252D-83C6-4635-956C-9098DF0E3267 */

UPDATE __mj."EntityField" SET "ValueListType"='List' WHERE "ID"='9BE6252D-83C6-4635-956C-9098DF0E3267';

/* SQL text to insert entity field value with ID b5b7fece-5e09-441a-a045-3f21c0eacb51 */

INSERT INTO __mj."EntityFieldValue"
                                       ("ID", "EntityFieldID", "Sequence", "Value", "Code", "__mj_CreatedAt", "__mj_UpdatedAt")
                                    VALUES
                                       ('b5b7fece-5e09-441a-a045-3f21c0eacb51', 'F3731712-44B4-49E6-AE78-6427358ACA2F', 1, 'Not Specified', 'Not Specified', NOW(), NOW());

/* SQL text to insert entity field value with ID c98dc43c-d2e4-4bcf-ac60-a5b286554f9e */

INSERT INTO __mj."EntityFieldValue"
                                       ("ID", "EntityFieldID", "Sequence", "Value", "Code", "__mj_CreatedAt", "__mj_UpdatedAt")
                                    VALUES
                                       ('c98dc43c-d2e4-4bcf-ac60-a5b286554f9e', 'F3731712-44B4-49E6-AE78-6427358ACA2F', 2, 'Opted In', 'Opted In', NOW(), NOW());

/* SQL text to insert entity field value with ID d9fe48fa-2ea7-4274-a1e0-73ad047091a4 */

INSERT INTO __mj."EntityFieldValue"
                                       ("ID", "EntityFieldID", "Sequence", "Value", "Code", "__mj_CreatedAt", "__mj_UpdatedAt")
                                    VALUES
                                       ('d9fe48fa-2ea7-4274-a1e0-73ad047091a4', 'F3731712-44B4-49E6-AE78-6427358ACA2F', 3, 'Opted Out', 'Opted Out', NOW(), NOW());

/* SQL text to update ValueListType for entity field ID F3731712-44B4-49E6-AE78-6427358ACA2F */

UPDATE __mj."EntityField" SET "ValueListType"='List' WHERE "ID"='F3731712-44B4-49E6-AE78-6427358ACA2F';

/* SQL text to insert entity field value with ID 43af6502-cd4e-435f-ba1f-a3a88f54b5e2 */

INSERT INTO __mj."EntityFieldValue"
                                       ("ID", "EntityFieldID", "Sequence", "Value", "Code", "__mj_CreatedAt", "__mj_UpdatedAt")
                                    VALUES
                                       ('43af6502-cd4e-435f-ba1f-a3a88f54b5e2', '3C7EC1D1-F253-4860-9D9B-3BE7263BF939', 1, 'Import', 'Import', NOW(), NOW());

/* SQL text to insert entity field value with ID 846b4635-1d55-4af9-9806-417516527a1e */

INSERT INTO __mj."EntityFieldValue"
                                       ("ID", "EntityFieldID", "Sequence", "Value", "Code", "__mj_CreatedAt", "__mj_UpdatedAt")
                                    VALUES
                                       ('846b4635-1d55-4af9-9806-417516527a1e', '3C7EC1D1-F253-4860-9D9B-3BE7263BF939', 2, 'Other', 'Other', NOW(), NOW());

/* SQL text to insert entity field value with ID 1400345b-1b40-4cf2-a19b-377e2919e5ce */

INSERT INTO __mj."EntityFieldValue"
                                       ("ID", "EntityFieldID", "Sequence", "Value", "Code", "__mj_CreatedAt", "__mj_UpdatedAt")
                                    VALUES
                                       ('1400345b-1b40-4cf2-a19b-377e2919e5ce', '3C7EC1D1-F253-4860-9D9B-3BE7263BF939', 3, 'Staff', 'Staff', NOW(), NOW());

/* SQL text to insert entity field value with ID 49a5d87d-3428-45c9-83be-ca6a499d9fcb */

INSERT INTO __mj."EntityFieldValue"
                                       ("ID", "EntityFieldID", "Sequence", "Value", "Code", "__mj_CreatedAt", "__mj_UpdatedAt")
                                    VALUES
                                       ('49a5d87d-3428-45c9-83be-ca6a499d9fcb', '3C7EC1D1-F253-4860-9D9B-3BE7263BF939', 4, 'Unsubscribe Link', 'Unsubscribe Link', NOW(), NOW());

/* SQL text to insert entity field value with ID 0d69f41e-5398-4978-832a-aacf47bfb2b5 */

INSERT INTO __mj."EntityFieldValue"
                                       ("ID", "EntityFieldID", "Sequence", "Value", "Code", "__mj_CreatedAt", "__mj_UpdatedAt")
                                    VALUES
                                       ('0d69f41e-5398-4978-832a-aacf47bfb2b5', '3C7EC1D1-F253-4860-9D9B-3BE7263BF939', 5, 'Web Form', 'Web Form', NOW(), NOW());

/* SQL text to update ValueListType for entity field ID 3C7EC1D1-F253-4860-9D9B-3BE7263BF939 */

UPDATE __mj."EntityField" SET "ValueListType"='List' WHERE "ID"='3C7EC1D1-F253-4860-9D9B-3BE7263BF939';

/* Deterministic search-flag hygiene — clear AllowUserSearchAPI */

UPDATE __mj."Entity"
         SET "AllowUserSearchAPI" = FALSE
         WHERE "ID" IN (
            SELECT e."ID"
            FROM __mj."Entity" e
            WHERE e."AllowUserSearchAPI" = TRUE
              AND e."AutoUpdateAllowUserSearchAPI" = TRUE
              AND e."VirtualEntity" = FALSE
              AND COALESCE(e."FullTextSearchEnabled", 0) = 0
              AND e."SchemaName" NOT IN ('__mj','sys')
              AND NOT EXISTS (
               SELECT 1 FROM __mj."EntityField" f2
               WHERE f2."EntityID" = e."ID"
                 AND f2."IncludeInUserSearchAPI" = TRUE
            )
         );


/* Create Entity Relationship: MJ_BizApps_Common: Contact Methods -> MJ_BizApps_Common: Contact Method Consents (One To Many via ContactMethodID) */

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityRelationship" WHERE "ID" = 'dc918a16-93fb-4cb2-9669-a7356c582d64'
    ) THEN
        INSERT INTO __mj."EntityRelationship" ("ID", "EntityID", "RelatedEntityID", "RelatedEntityJoinField", "Type", "BundleInAPI", "DisplayInForm", "Sequence", "__mj_CreatedAt", "__mj_UpdatedAt")
        VALUES ('dc918a16-93fb-4cb2-9669-a7356c582d64', '32C45078-D33B-4760-9BE5-0DF7F483F591', '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', 'ContactMethodID', 'One To Many', TRUE, TRUE, 1, NOW(), NOW());
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityRelationship" WHERE "ID" = '1e12a43c-69d0-4d63-a353-e6acdbfede03'
    ) THEN
        INSERT INTO __mj."EntityRelationship" ("ID", "EntityID", "RelatedEntityID", "RelatedEntityJoinField", "Type", "BundleInAPI", "DisplayInForm", "Sequence", "__mj_CreatedAt", "__mj_UpdatedAt")
        VALUES ('1e12a43c-69d0-4d63-a353-e6acdbfede03', '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', 'CA348384-97E9-4A6F-A28B-56DC169C0051', 'ContactMethodConsentID', 'One To Many', TRUE, TRUE, 1, NOW(), NOW());
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityRelationship" WHERE "ID" = '7cfc0356-8cce-4b18-bb9c-ef695727b9e4'
    ) THEN
        INSERT INTO __mj."EntityRelationship" ("ID", "EntityID", "RelatedEntityID", "RelatedEntityJoinField", "Type", "BundleInAPI", "DisplayInForm", "Sequence", "__mj_CreatedAt", "__mj_UpdatedAt")
        VALUES ('7cfc0356-8cce-4b18-bb9c-ef695727b9e4', 'E1238F34-2837-EF11-86D4-6045BDEE16E6', 'CA348384-97E9-4A6F-A28B-56DC169C0051', 'RecordedByUserID', 'One To Many', TRUE, TRUE, 124, NOW(), NOW());
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityRelationship" WHERE "ID" = '707defb9-cc94-4f89-b30c-1cf530aa200c'
    ) THEN
        INSERT INTO __mj."EntityRelationship" ("ID", "EntityID", "RelatedEntityID", "RelatedEntityJoinField", "Type", "BundleInAPI", "DisplayInForm", "Sequence", "__mj_CreatedAt", "__mj_UpdatedAt")
        VALUES ('707defb9-cc94-4f89-b30c-1cf530aa200c', '47248F34-2837-EF11-86D4-6045BDEE16E6', '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', 'CommunicationBaseMessageTypeID', 'One To Many', TRUE, TRUE, 3, NOW(), NOW());
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityRelationship" WHERE "ID" = '7dd27fb4-72f5-4b72-93a0-b18024bd20ed'
    ) THEN
        INSERT INTO __mj."EntityRelationship" ("ID", "EntityID", "RelatedEntityID", "RelatedEntityJoinField", "Type", "BundleInAPI", "DisplayInForm", "Sequence", "__mj_CreatedAt", "__mj_UpdatedAt")
        VALUES ('7dd27fb4-72f5-4b72-93a0-b18024bd20ed', 'C70448F9-9792-41D7-A82C-784B66429D54', '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', 'RequestingOrganizationID', 'One To Many', TRUE, TRUE, 5, NOW(), NOW());
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityRelationship" WHERE "ID" = '6a3795e5-5751-48d2-8640-bcefe6a16471'
    ) THEN
        INSERT INTO __mj."EntityRelationship" ("ID", "EntityID", "RelatedEntityID", "RelatedEntityJoinField", "Type", "BundleInAPI", "DisplayInForm", "Sequence", "__mj_CreatedAt", "__mj_UpdatedAt")
        VALUES ('6a3795e5-5751-48d2-8640-bcefe6a16471', '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', 'ConsentPurposeID', 'One To Many', TRUE, TRUE, 1, NOW(), NOW());
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = 'c220d85b-7d94-4573-8303-4707c8cc3365' OR ("EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND "Name" = 'ContactMethod')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        'c220d85b-7d94-4573-8303-4707c8cc3365',
        '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consents"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
        'ContactMethod',
        'Contact Method',
        NULL,
        'TEXT',
        1000,
        0,
        0,
        FALSE,
        NULL,
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = '394380cc-b0f8-44f0-8f50-46f3f071bf0f' OR ("EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND "Name" = 'ConsentPurpose')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        '394380cc-b0f8-44f0-8f50-46f3f071bf0f',
        '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consents"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
        'ConsentPurpose',
        'Consent Purpose',
        NULL,
        'TEXT',
        200,
        0,
        0,
        TRUE,
        NULL,
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = 'f2e5756b-f4e8-4fc7-9aa4-a6675516f5c2' OR ("EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND "Name" = 'RequestingOrganization')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        'f2e5756b-f4e8-4fc7-9aa4-a6675516f5c2',
        '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consents"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
        'RequestingOrganization',
        'Requesting Organization',
        NULL,
        'TEXT',
        510,
        0,
        0,
        TRUE,
        NULL,
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = 'fc1a8169-146e-402e-b165-f70524dfcfc6' OR ("EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND "Name" = 'RecordedByUser')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        'fc1a8169-146e-402e-b165-f70524dfcfc6',
        'CA348384-97E9-4A6F-A28B-56DC169C0051', -- "Entity": "MJ_BizApps_Common": "Contact" "Method" "Consent" "Histories"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
        'RecordedByUser',
        'Recorded By User',
        NULL,
        'TEXT',
        200,
        0,
        0,
        TRUE,
        NULL,
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = '859c9d5f-5b5c-447b-9f3a-75511e1092c3' OR ("EntityID" = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND "Name" = 'CommunicationBaseMessageType')
    ) THEN
        INSERT INTO __mj."EntityField"
        (
        "ID",
        "EntityID",
        "Sequence",
        "Name",
        "DisplayName",
        "Description",
        "Type",
        "Length",
        "Precision",
        "Scale",
        "AllowsNull",
        "DefaultValue",
        "AutoIncrement",
        "AllowUpdateAPI",
        "IsVirtual",
        "IsComputed",
        "RelatedEntityID",
        "RelatedEntityFieldName",
        "IsNameField",
        "IncludeInUserSearchAPI",
        "IncludeRelatedEntityNameFieldInBaseView",
        "DefaultInView",
        "IsPrimaryKey",
        "IsUnique",
        "RelatedEntityDisplayType",
        "__mj_CreatedAt",
        "__mj_UpdatedAt"
        )
        VALUES
        (
        '859c9d5f-5b5c-447b-9f3a-75511e1092c3',
        '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', -- "Entity": "MJ_BizApps_Common": "Contact" "Types"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5'),
        'CommunicationBaseMessageType',
        'Communication Base Message Type',
        NULL,
        'TEXT',
        200,
        0,
        0,
        TRUE,
        NULL,
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

UPDATE __mj."Entity"
            SET "AllowUserSearchAPI" = FALSE
            WHERE "ID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452'
            AND "AutoUpdateAllowUserSearchAPI" = TRUE;

/* Set field properties for entity */

UPDATE __mj."EntityField"
               SET "IsNameField" = TRUE
               WHERE "ID" = 'F3731712-44B4-49E6-AE78-6427358ACA2F'
               AND "AutoUpdateIsNameField" = TRUE;

UPDATE __mj."EntityField"
               SET "DefaultInView" = TRUE
               WHERE "ID" = 'FC1A8169-146E-402E-B165-F70524DFCFC6'
               AND "AutoUpdateDefaultInView" = TRUE;

/* Set field properties for entity */

UPDATE __mj."EntityField"
               SET "DefaultInView" = TRUE
               WHERE "ID" = 'C220D85B-7D94-4573-8303-4707C8CC3365'
               AND "AutoUpdateDefaultInView" = TRUE;

UPDATE __mj."EntityField"
               SET "DefaultInView" = TRUE
               WHERE "ID" = '394380CC-B0F8-44F0-8F50-46F3F071BF0F'
               AND "AutoUpdateDefaultInView" = TRUE;

UPDATE __mj."EntityField"
               SET "DefaultInView" = TRUE
               WHERE "ID" = 'F2E5756B-F4E8-4FC7-9AA4-A6675516F5C2'
               AND "AutoUpdateDefaultInView" = TRUE;

/* Set categories for 7 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.ID

UPDATE __mj."EntityField"
SET 
   "Category" = 'System Metadata',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '7071F4CE-E586-4B98-AA23-FECF40B4EB85';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.Name

UPDATE __mj."EntityField"
SET 
   "Category" = 'Consent Purpose Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '0EFC615D-26A6-4583-97D0-E92D643B4DED';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.Description

UPDATE __mj."EntityField"
SET 
   "Category" = 'Consent Purpose Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '822C3037-DA30-41EF-B10D-B9E545D328F7';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.Sequence

UPDATE __mj."EntityField"
SET 
   "Category" = 'Consent Purpose Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = 'C2D551F0-E612-47BE-895C-E9E2D46ACD1D';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.IsActive

UPDATE __mj."EntityField"
SET 
   "Category" = 'Consent Purpose Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '664CCCAA-627F-4345-AE53-E37C28731A33';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.__mj_CreatedAt

UPDATE __mj."EntityField"
SET 
   "Category" = 'System Metadata',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = 'F2DF4DE8-3BDD-4EBA-A349-B2EFC2D7C362';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.__mj_UpdatedAt

UPDATE __mj."EntityField"
SET 
   "Category" = 'System Metadata',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = 'C22F89CD-2EEF-4FF7-BF60-58CCB001354D';

/* Set entity icon to fa fa-shield-alt */

UPDATE __mj."Entity"
               SET "Icon" = 'fa fa-shield-alt', "__mj_UpdatedAt" = NOW()
               WHERE "ID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452';

/* Insert FieldCategoryInfo setting for entity */

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntitySetting" WHERE "EntityID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452' AND "Name" = 'FieldCategoryInfo'
    ) THEN
        INSERT INTO __mj."EntitySetting" ("ID", "EntityID", "Name", "Value", "__mj_CreatedAt", "__mj_UpdatedAt")
        VALUES ('93b873d8-55df-5cac-8b29-421557ac9191', '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', 'FieldCategoryInfo', '{
  "Consent Purpose Details": {
    "description": "Information defining what a consent is for, including display name, description, and display order",
    "icon": "fa fa-shield-alt"
  },
  "System Metadata": {
    "description": "System-managed audit and tracking fields",
    "icon": "fa fa-cog"
  }
}', NOW(), NOW());
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntitySetting" WHERE "EntityID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452' AND "Name" = 'FieldCategoryIcons'
    ) THEN
        INSERT INTO __mj."EntitySetting" ("ID", "EntityID", "Name", "Value", "__mj_CreatedAt", "__mj_UpdatedAt")
        VALUES ('2454944c-9dea-5386-8f6d-4f605e85f22b', '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', 'FieldCategoryIcons', '{
  "Consent Purpose Details": "fa fa-shield-alt",
  "System Metadata": "fa fa-cog"
}', NOW(), NOW());
    END IF;
END $$;

UPDATE __mj."ApplicationEntity"
         SET "DefaultForNewUser" = FALSE, "__mj_UpdatedAt" = NOW()
         WHERE "EntityID" = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452';

/* Set categories for 10 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.ID

UPDATE __mj."EntityField"
SET 
   "Category" = 'System Metadata',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = 'F0DE470D-3CA4-4984-868C-D2E40E70DA6D';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.ContactMethodConsentID

UPDATE __mj."EntityField"
SET 
   "Category" = 'Consent History Details',
   "GeneratedFormSection" = 'Category',
   "DisplayName" = 'Contact Method Consent'
WHERE 
   "ID" = 'D7390A2A-889B-4E17-8ACD-6E84473159DB';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.NewConsentStatus

UPDATE __mj."EntityField"
SET 
   "Category" = 'Consent History Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = 'F3731712-44B4-49E6-AE78-6427358ACA2F';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.ConsentStatusAt

UPDATE __mj."EntityField"
SET 
   "Category" = 'Consent History Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '4F09CF64-7AB8-4C54-AB0B-76ABB393FCE8';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.ConsentSource

UPDATE __mj."EntityField"
SET 
   "Category" = 'Consent History Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '3C7EC1D1-F253-4860-9D9B-3BE7263BF939';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.ConsentDetails

UPDATE __mj."EntityField"
SET 
   "Category" = 'Consent History Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = 'BB5DD18B-B73D-4C65-BF5B-936C1674F35A';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.RecordedByUserID

UPDATE __mj."EntityField"
SET 
   "Category" = 'Audit Information',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '49A2005B-27B9-4C8A-84C9-50148F4B9284';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.RecordedByUser

UPDATE __mj."EntityField"
SET 
   "Category" = 'Audit Information',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = 'FC1A8169-146E-402E-B165-F70524DFCFC6';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.__mj_CreatedAt

UPDATE __mj."EntityField"
SET 
   "Category" = 'System Metadata',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = 'B05D0298-EF0F-4725-A66B-5C6489C1ACEB';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.__mj_UpdatedAt

UPDATE __mj."EntityField"
SET 
   "Category" = 'System Metadata',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '4B667580-DF5E-4B1C-BC4A-0A306F8E2A0E';

/* Set entity icon to fa fa-history */

UPDATE __mj."Entity"
               SET "Icon" = 'fa fa-history', "__mj_UpdatedAt" = NOW()
               WHERE "ID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051';

/* Insert FieldCategoryInfo setting for entity */

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntitySetting" WHERE "EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND "Name" = 'FieldCategoryInfo'
    ) THEN
        INSERT INTO __mj."EntitySetting" ("ID", "EntityID", "Name", "Value", "__mj_CreatedAt", "__mj_UpdatedAt")
        VALUES ('a7fff22b-089c-5bac-ae3d-ad6d8c496e26', 'CA348384-97E9-4A6F-A28B-56DC169C0051', 'FieldCategoryInfo', '{
  "Audit Information": {
    "description": "Information about who recorded the consent change",
    "icon": "fa fa-user-shield"
  },
  "Consent History Details": {
    "description": "Details regarding the consent status change, source, and timing",
    "icon": "fa fa-history"
  },
  "System Metadata": {
    "description": "System-managed audit and tracking fields",
    "icon": "fa fa-cog"
  }
}', NOW(), NOW());
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntitySetting" WHERE "EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND "Name" = 'FieldCategoryIcons'
    ) THEN
        INSERT INTO __mj."EntitySetting" ("ID", "EntityID", "Name", "Value", "__mj_CreatedAt", "__mj_UpdatedAt")
        VALUES ('308a7695-f2e0-5a75-908b-5a5eae99b618', 'CA348384-97E9-4A6F-A28B-56DC169C0051', 'FieldCategoryIcons', '{
  "Audit Information": "fa fa-user-shield",
  "Consent History Details": "fa fa-history",
  "System Metadata": "fa fa-cog"
}', NOW(), NOW());
    END IF;
END $$;

UPDATE __mj."ApplicationEntity"
         SET "DefaultForNewUser" = FALSE, "__mj_UpdatedAt" = NOW()
         WHERE "EntityID" = 'CA348384-97E9-4A6F-A28B-56DC169C0051';

/* Set categories for 2 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Types.CommunicationBaseMessageTypeID

UPDATE __mj."EntityField"
SET 
   "Category" = 'Type Definition',
   "GeneratedFormSection" = 'Category',
   "DisplayName" = 'CommunicationBaseMessageType'
WHERE 
   "ID" = '438B7DBE-F13B-42EF-97A3-5D952B58E2E3';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Types.CommunicationBaseMessageType

UPDATE __mj."EntityField"
SET 
   "Category" = 'Type Definition',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '859C9D5F-5B5C-447B-9F3A-75511E1092C3';

/* Set categories for 10 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.ID

UPDATE __mj."EntityField"
SET 
   "Category" = 'System Metadata',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '63580DC7-71EB-464A-9D9B-69CA81E53E18';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.ContactMethodID

UPDATE __mj."EntityField"
SET 
   "Category" = 'Contact Association',
   "GeneratedFormSection" = 'Category',
   "DisplayName" = 'Contact Method'
WHERE 
   "ID" = 'DB56EA60-777B-4A0E-ABDB-C32089F26EBB';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.ConsentPurposeID

UPDATE __mj."EntityField"
SET 
   "Category" = 'Consent Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '428C56B9-02B4-4042-B3EC-6D94FB052FC7';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.RequestingOrganizationID

UPDATE __mj."EntityField"
SET 
   "Category" = 'Consent Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = 'CC1DFBB8-63BC-42CE-A127-36081C6C1F88';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.ConsentStatus

UPDATE __mj."EntityField"
SET 
   "Category" = 'Consent Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '9BE6252D-83C6-4635-956C-9098DF0E3267';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.__mj_CreatedAt

UPDATE __mj."EntityField"
SET 
   "Category" = 'System Metadata',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '8EE39D4D-0833-44E0-89A4-AD99417228B0';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.__mj_UpdatedAt

UPDATE __mj."EntityField"
SET 
   "Category" = 'System Metadata',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = 'F181E819-0DD8-4D42-B5CE-09FF372059AC';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.ContactMethod

UPDATE __mj."EntityField"
SET 
   "Category" = 'Contact Association',
   "GeneratedFormSection" = 'Category',
   "DisplayName" = 'Contact Method Details'
WHERE 
   "ID" = 'C220D85B-7D94-4573-8303-4707C8CC3365';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.ConsentPurpose

UPDATE __mj."EntityField"
SET 
   "Category" = 'Consent Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '394380CC-B0F8-44F0-8F50-46F3F071BF0F';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.RequestingOrganization

UPDATE __mj."EntityField"
SET 
   "Category" = 'Consent Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = 'F2E5756B-F4E8-4FC7-9AA4-A6675516F5C2';

/* Set entity icon to fa fa-shield-alt */

UPDATE __mj."Entity"
               SET "Icon" = 'fa fa-shield-alt', "__mj_UpdatedAt" = NOW()
               WHERE "ID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31';

/* Insert FieldCategoryInfo setting for entity */

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntitySetting" WHERE "EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND "Name" = 'FieldCategoryInfo'
    ) THEN
        INSERT INTO __mj."EntitySetting" ("ID", "EntityID", "Name", "Value", "__mj_CreatedAt", "__mj_UpdatedAt")
        VALUES ('446a62d1-14af-557d-b4ab-bd862b0e8d43', '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', 'FieldCategoryInfo', '{
  "Consent Details": {
    "description": "Details regarding the consent status, purpose, and requesting organization",
    "icon": "fa fa-check-circle"
  },
  "Contact Association": {
    "description": "Information linking the consent to a specific contact method",
    "icon": "fa fa-address-card"
  },
  "System Metadata": {
    "description": "System-managed audit and tracking fields",
    "icon": "fa fa-cog"
  }
}', NOW(), NOW());
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntitySetting" WHERE "EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND "Name" = 'FieldCategoryIcons'
    ) THEN
        INSERT INTO __mj."EntitySetting" ("ID", "EntityID", "Name", "Value", "__mj_CreatedAt", "__mj_UpdatedAt")
        VALUES ('c4acfb14-faad-5be5-adaa-c20819484a38', '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', 'FieldCategoryIcons', '{
  "Consent Details": "fa fa-check-circle",
  "Contact Association": "fa fa-address-card",
  "System Metadata": "fa fa-cog"
}', NOW(), NOW());
    END IF;
END $$;

UPDATE __mj."ApplicationEntity"
         SET "DefaultForNewUser" = FALSE, "__mj_UpdatedAt" = NOW()
         WHERE "EntityID" = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31';


-- ===================== FK & CHECK Constraints =====================


-- Flush any pending deferred trigger events from prior DML so DDL below can proceed.
SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE __mj_BizAppsCommon."ContactType"
 ADD CONSTRAINT "FK_ContactType_CommunicationBaseMessageType" FOREIGN KEY ("CommunicationBaseMessageTypeID")
        REFERENCES __mj."CommunicationBaseMessageType"("ID") DEFERRABLE INITIALLY DEFERRED;


-- ===================== Grants =====================

DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwConsentPurposes" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View Permissions SQL for MJ_BizApps_Common: Consent Purposes */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Consent Purposes
-- Item: Permissions for vwConsentPurposes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwConsentPurposes" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Consent Purposes */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Consent Purposes
-- Item: spCreateConsentPurpose
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ConsentPurpose
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateConsentPurpose" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Consent Purposes */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateConsentPurpose" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Consent Purposes */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Consent Purposes
-- Item: spUpdateConsentPurpose
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ConsentPurpose
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateConsentPurpose" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateConsentPurpose" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Consent Purposes */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Consent Purposes
-- Item: spDeleteConsentPurpose
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ConsentPurpose
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteConsentPurpose" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Consent Purposes */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteConsentPurpose" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* SQL text to update entity field related entity name field map for entity field ID 428C56B9-02B4-4042-B3EC-6D94FB052FC7 */

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwContactTypes" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwContactTypes" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwContactTypes" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwContactTypes" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View Permissions SQL for MJ_BizApps_Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Types
-- Item: Permissions for vwContactTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwContactTypes" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwContactTypes" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwContactTypes" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwContactTypes" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Types
-- Item: spCreateContactType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ContactType
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateContactType" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateContactType" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateContactType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Contact Types */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateContactType" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateContactType" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateContactType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Types
-- Item: spUpdateContactType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ContactType
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateContactType" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateContactType" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateContactType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateContactType" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateContactType" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateContactType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Types
-- Item: spDeleteContactType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ContactType
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteContactType" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteContactType" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Contact Types */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteContactType" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteContactType" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View SQL for MJ_BizApps_Common: Contact Method Consent Histories */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consent Histories
-- Item: vwContactMethodConsentHistories
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Contact Method Consent Histories
-----               SCHEMA:      __mj_BizAppsCommon
-----               BASE TABLE:  ContactMethodConsentHistory
-----               PRIMARY KEY: ID
------------------------------------------------------------;

DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwContactMethodConsentHistories" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View Permissions SQL for MJ_BizApps_Common: Contact Method Consent Histories */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consent Histories
-- Item: Permissions for vwContactMethodConsentHistories
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwContactMethodConsentHistories" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Contact Method Consent Histories */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consent Histories
-- Item: spCreateContactMethodConsentHistory
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ContactMethodConsentHistory
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateContactMethodConsentHistory" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Contact Method Consent Histories */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateContactMethodConsentHistory" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Contact Method Consent Histories */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consent Histories
-- Item: spUpdateContactMethodConsentHistory
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ContactMethodConsentHistory
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateContactMethodConsentHistory" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateContactMethodConsentHistory" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Contact Method Consent Histories */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consent Histories
-- Item: spDeleteContactMethodConsentHistory
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ContactMethodConsentHistory
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteContactMethodConsentHistory" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Contact Method Consent Histories */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteContactMethodConsentHistory" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* SQL text to update entity field related entity name field map for entity field ID CC1DFBB8-63BC-42CE-A127-36081C6C1F88 */

DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwContactMethodConsents" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View Permissions SQL for MJ_BizApps_Common: Contact Method Consents */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consents
-- Item: Permissions for vwContactMethodConsents
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwContactMethodConsents" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Contact Method Consents */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consents
-- Item: spCreateContactMethodConsent
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ContactMethodConsent
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateContactMethodConsent" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Contact Method Consents */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateContactMethodConsent" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Contact Method Consents */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consents
-- Item: spUpdateContactMethodConsent
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ContactMethodConsent
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateContactMethodConsent" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateContactMethodConsent" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Contact Method Consents */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consents
-- Item: spDeleteContactMethodConsent
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ContactMethodConsent
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteContactMethodConsent" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Contact Method Consents */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteContactMethodConsent" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* SQL text to insert 5 new entity field(s) */


-- ===================== Comments =====================

COMMENT ON TABLE __mj_BizAppsCommon."ConsentPurpose" IS 'What a consent is for. Common seeds the generic purposes, Marketing and Transactional; apps built on Common add their own. Consent is recorded per contact method and purpose, so one email can be opted in for transactional messages and opted out of marketing. Seeded by metadata; add rows rather than columns.';

COMMENT ON COLUMN __mj_BizAppsCommon."ConsentPurpose"."Name" IS 'Display name of the purpose, unique within the installation.';

COMMENT ON COLUMN __mj_BizAppsCommon."ConsentPurpose"."Description" IS 'What kinds of messages this purpose covers.';

COMMENT ON COLUMN __mj_BizAppsCommon."ConsentPurpose"."Sequence" IS 'Sort order in dropdown lists. Lower values appear first.';

COMMENT ON COLUMN __mj_BizAppsCommon."ConsentPurpose"."IsActive" IS 'Whether this purpose is offered for new consents. Inactive purposes are hidden from dropdowns but preserved for existing records.';

COMMENT ON TABLE __mj_BizAppsCommon."ContactMethodConsent" IS 'The current consent for one contact method (an email or phone): for one purpose or, when ConsentPurposeID is null, for anything; as asked by one organization or, when RequestingOrganizationID is null, by anyone on the installation. A contact method has many of these, the way a person has many contact methods, and the most specific row answers: purpose and organization, then purpose, then organization, then the general row. ConsentStatus always equals NewConsentStatus on the ContactMethodConsentHistory row with the latest ConsentStatusAt. Set it through ContactPreferenceEngine, which writes the history row with it. Deleting the contact method deletes its consents.';

COMMENT ON COLUMN __mj_BizAppsCommon."ContactMethodConsent"."ConsentStatus" IS 'The current consent: Not Specified, Opted In or Opted Out.';

COMMENT ON COLUMN __mj_BizAppsCommon."ContactMethodConsent"."RequestingOrganizationID" IS 'The organization that asked for this consent, when the person answered differently for different organizations. Null means the answer applies to anyone on the installation. This is not the owner of the contact method; that is ContactMethod.PersonID or ContactMethod.OrganizationID.';

COMMENT ON TABLE __mj_BizAppsCommon."ContactMethodConsentHistory" IS 'One row per change on a ContactMethodConsent: the status it set, when it took effect in the real world, and where it came from. ContactMethodConsent.ConsentStatus mirrors the row with the latest ConsentStatusAt. A late-arriving change with an older date is kept here but does not change the current status. Deleting the consent deletes its history.';

COMMENT ON COLUMN __mj_BizAppsCommon."ContactMethodConsentHistory"."NewConsentStatus" IS 'The consent status this change set: Not Specified, Opted In or Opted Out.';

COMMENT ON COLUMN __mj_BizAppsCommon."ContactMethodConsentHistory"."ConsentStatusAt" IS 'When the change took effect in the real world (the unsubscribe click, the form submission, the import''s own date), not when this row was saved. The row with the latest value is the current status.';

COMMENT ON COLUMN __mj_BizAppsCommon."ContactMethodConsentHistory"."ConsentSource" IS 'Where the change came from: Web Form, Unsubscribe Link, Import, Staff or Other. Defaults to Staff, for a change made by a person in the app. The specifics, such as which system an import came from or what Other was, go in ConsentDetails.';

COMMENT ON COLUMN __mj_BizAppsCommon."ContactMethodConsentHistory"."ConsentDetails" IS 'The specifics of the change: which system an import came from, what an Other source was, or evidence such as a form ID or the unsubscribe email''s message ID.';


-- ===================== Other =====================

/* ============================================================================================
   ==== CODEGEN OUTPUT — DO NOT EDIT BELOW THIS LINE ====
   Generated by the MemberJunction CodeGen tool: MJ CLI 6.2.0-edge.4 / CodeGenLib from MJ `next`
   @ cf164901da, includeSchemas ['__mj_BizAppsCommon'], against a database built from migrations
   (through the 5.55 release seed) with metadata/ pushed first (so CHECK validators come from the
   pinned GeneratedCode rows).
   Contains: the Consent Purposes, Contact Method Consents and Contact Method Consent Histories
   entities and their fields, the CommunicationBaseMessageTypeID field on Contact Types, value
   lists and relationships, FK indexes, the regenerated views, CRUD procs and permissions.
   Do NOT edit by hand. If the hand-written SQL above changes, re-run CodeGen and replace this
   whole section.
   Runs: one, after the hand-written DDL above.
   ============================================================================================ */

/* SQL generated to create new entity MJ_BizApps_Common: Consent Purposes */

/* SQL text to insert 24 new entity field(s) */

/* spUpdate Permissions for MJ_BizApps_Common: Consent Purposes */

/* spUpdate Permissions for MJ_BizApps_Common: Contact Types */

/* spUpdate Permissions for MJ_BizApps_Common: Contact Method Consent Histories */

/* spUpdate Permissions for MJ_BizApps_Common: Contact Method Consents */

-- ===================== Skipped by the converter, translated by hand =====================
-- CodeGen's related-entity name-field map updates and changed column descriptions.
SELECT __mj."spUpdateEntityFieldRelatedEntityNameFieldMap"('49A2005B-27B9-4C8A-84C9-50148F4B9284'::uuid, 'RecordedByUser');
SELECT __mj."spUpdateEntityFieldRelatedEntityNameFieldMap"('DB56EA60-777B-4A0E-ABDB-C32089F26EBB'::uuid, 'ContactMethod');
SELECT __mj."spUpdateEntityFieldRelatedEntityNameFieldMap"('438B7DBE-F13B-42EF-97A3-5D952B58E2E3'::uuid, 'CommunicationBaseMessageType');
SELECT __mj."spUpdateEntityFieldRelatedEntityNameFieldMap"('428C56B9-02B4-4042-B3EC-6D94FB052FC7'::uuid, 'ConsentPurpose');
SELECT __mj."spUpdateEntityFieldRelatedEntityNameFieldMap"('CC1DFBB8-63BC-42CE-A127-36081C6C1F88'::uuid, 'RequestingOrganization');
