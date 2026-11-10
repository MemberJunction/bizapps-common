-- =============================================================================================
-- PostgreSQL counterpart of V202610151049__v5.54.x__Person_DisplayName_Suffix_And_Blanks.sql
-- =============================================================================================
-- `mj sql-convert --from tsql --to postgres` (MJ CLI 6.1.5) output, finished by hand:
--   * Tables, columns, constraints, indexes, views, data and grants are the converter's.
--   * CodeGen's CRUD procedures (spCreate/spUpdate/spDelete), its __mj_UpdatedAt triggers and any
--     hierarchy functions are NOT here: the converter cannot translate T-SQL procedures, triggers
--     or table-valued functions. A PostgreSQL host runs `mj codegen` after installing, which
--     generates them natively. The converter's notes for them remain, fully commented out.
--   * IF COL_LENGTH('[__mj_BizAppsCommon].[Person]', 'DisplayName'): written by hand in PL/pgSQL from this migration's T-SQL.
--   * 5 view-rebuild block(s): the target schema lowercased, so the dependent-view rebuild
--     finds the view when its column list changes.
--   * 1 column description(s) the converter left calling SQL Server's sp_addextendedproperty
--     written as COMMENT ON COLUMN.
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

CREATE INDEX IF NOT EXISTS "IX_Person_DisplayName" ON __mj_BizAppsCommon."Person" ("DisplayName");

COMMENT ON COLUMN __mj_BizAppsCommon."Person"."DisplayName" IS 'Full name for display: FirstName LastName Suffix ("John Smith Jr."). Blank parts are skipped; empty when every part is blank. Computed and stored; this is the entity name field.';

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_ActivitySyncExclusion_ActivitySyncRuleSetID" ON __mj_BizAppsCommon."ActivitySyncExclusion" ("ActivitySyncRuleSetID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_ActivitySyncExclusion_PersonID" ON __mj_BizAppsCommon."ActivitySyncExclusion" ("PersonID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_ContactMethod_PersonID" ON __mj_BizAppsCommon."ContactMethod" ("PersonID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_ContactMethod_OrganizationID" ON __mj_BizAppsCommon."ContactMethod" ("OrganizationID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_ContactMethod_ContactTypeID" ON __mj_BizAppsCommon."ContactMethod" ("ContactTypeID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Person_LinkedUserID" ON __mj_BizAppsCommon."Person" ("LinkedUserID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Person_SeniorityLevelID" ON __mj_BizAppsCommon."Person" ("SeniorityLevelID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_PersonJobFunction_PersonID" ON __mj_BizAppsCommon."PersonJobFunction" ("PersonID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_PersonJobFunction_JobFunctionID" ON __mj_BizAppsCommon."PersonJobFunction" ("JobFunctionID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Relationship_RelationshipTypeID" ON __mj_BizAppsCommon."Relationship" ("RelationshipTypeID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Relationship_FromPersonID" ON __mj_BizAppsCommon."Relationship" ("FromPersonID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Relationship_FromOrganizationID" ON __mj_BizAppsCommon."Relationship" ("FromOrganizationID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Relationship_ToPersonID" ON __mj_BizAppsCommon."Relationship" ("ToPersonID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Relationship_ToOrganizationID" ON __mj_BizAppsCommon."Relationship" ("ToOrganizationID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Relationship_JobFunctionID" ON __mj_BizAppsCommon."Relationship" ("JobFunctionID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Relationship_SeniorityLevelID" ON __mj_BizAppsCommon."Relationship" ("SeniorityLevelID");


-- ===================== Views =====================

DO $do$
DECLARE
  v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
  v_target_name CONSTANT TEXT := 'vwActivitySyncExclusions';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwActivitySyncExclusions"
AS SELECT
    a.*,
    "mjBizAppsCommonActivitySyncRuleSet_ActivitySyncRuleSetID"."Name" AS "ActivitySyncRuleSet",
    "mjBizAppsCommonPerson_PersonID"."DisplayName" AS "Person"
FROM
    __mj_BizAppsCommon."ActivitySyncExclusion" AS a
LEFT OUTER JOIN
    __mj_BizAppsCommon."ActivitySyncRuleSet" AS "mjBizAppsCommonActivitySyncRuleSet_ActivitySyncRuleSetID"
  ON
    a."ActivitySyncRuleSetID" = "mjBizAppsCommonActivitySyncRuleSet_ActivitySyncRuleSetID"."ID"
LEFT OUTER JOIN
    __mj_BizAppsCommon."Person" AS "mjBizAppsCommonPerson_PersonID"
  ON
    a."PersonID" = "mjBizAppsCommonPerson_PersonID"."ID"$vsql$;
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
  v_target_name CONSTANT TEXT := 'vwContactMethods';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwContactMethods"
AS SELECT
    c.*,
    "mjBizAppsCommonPerson_PersonID"."DisplayName" AS "Person",
    "mjBizAppsCommonOrganization_OrganizationID"."Name" AS "Organization",
    "mjBizAppsCommonContactType_ContactTypeID"."Name" AS "ContactType"
FROM
    __mj_BizAppsCommon."ContactMethod" AS c
LEFT OUTER JOIN
    __mj_BizAppsCommon."Person" AS "mjBizAppsCommonPerson_PersonID"
  ON
    c."PersonID" = "mjBizAppsCommonPerson_PersonID"."ID"
LEFT OUTER JOIN
    __mj_BizAppsCommon."Organization" AS "mjBizAppsCommonOrganization_OrganizationID"
  ON
    c."OrganizationID" = "mjBizAppsCommonOrganization_OrganizationID"."ID"
INNER JOIN
    __mj_BizAppsCommon."ContactType" AS "mjBizAppsCommonContactType_ContactTypeID"
  ON
    c."ContactTypeID" = "mjBizAppsCommonContactType_ContactTypeID"."ID"$vsql$;
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
  v_target_name CONSTANT TEXT := 'vwPeopleGenerated';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwPeopleGenerated"
AS SELECT
    p.*,
    "MJUser_LinkedUserID"."Name" AS "LinkedUser",
    "mjBizAppsCommonSeniorityLevel_SeniorityLevelID"."Name" AS "SeniorityLevel"
FROM
    __mj_BizAppsCommon."Person" AS p
LEFT OUTER JOIN
    __mj."User" AS "MJUser_LinkedUserID"
  ON
    p."LinkedUserID" = "MJUser_LinkedUserID"."ID"
LEFT OUTER JOIN
    __mj_BizAppsCommon."SeniorityLevel" AS "mjBizAppsCommonSeniorityLevel_SeniorityLevelID"
  ON
    p."SeniorityLevelID" = "mjBizAppsCommonSeniorityLevel_SeniorityLevelID"."ID"$vsql$;
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
  v_target_name CONSTANT TEXT := 'vwPersonJobFunctions';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwPersonJobFunctions"
AS SELECT
    p.*,
    "mjBizAppsCommonPerson_PersonID"."DisplayName" AS "Person",
    "mjBizAppsCommonJobFunction_JobFunctionID"."Name" AS "JobFunction"
FROM
    __mj_BizAppsCommon."PersonJobFunction" AS p
INNER JOIN
    __mj_BizAppsCommon."Person" AS "mjBizAppsCommonPerson_PersonID"
  ON
    p."PersonID" = "mjBizAppsCommonPerson_PersonID"."ID"
INNER JOIN
    __mj_BizAppsCommon."JobFunction" AS "mjBizAppsCommonJobFunction_JobFunctionID"
  ON
    p."JobFunctionID" = "mjBizAppsCommonJobFunction_JobFunctionID"."ID"$vsql$;
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
  v_target_name CONSTANT TEXT := 'vwRelationshipsGenerated';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwRelationshipsGenerated"
AS SELECT
    r.*,
    "mjBizAppsCommonRelationshipType_RelationshipTypeID"."Name" AS "RelationshipType",
    "mjBizAppsCommonPerson_FromPersonID"."DisplayName" AS "FromPerson",
    "mjBizAppsCommonOrganization_FromOrganizationID"."Name" AS "FromOrganization",
    "mjBizAppsCommonPerson_ToPersonID"."DisplayName" AS "ToPerson",
    "mjBizAppsCommonOrganization_ToOrganizationID"."Name" AS "ToOrganization",
    "mjBizAppsCommonJobFunction_JobFunctionID"."Name" AS "JobFunction",
    "mjBizAppsCommonSeniorityLevel_SeniorityLevelID"."Name" AS "SeniorityLevel"
FROM
    __mj_BizAppsCommon."Relationship" AS r
INNER JOIN
    __mj_BizAppsCommon."RelationshipType" AS "mjBizAppsCommonRelationshipType_RelationshipTypeID"
  ON
    r."RelationshipTypeID" = "mjBizAppsCommonRelationshipType_RelationshipTypeID"."ID"
LEFT OUTER JOIN
    __mj_BizAppsCommon."Person" AS "mjBizAppsCommonPerson_FromPersonID"
  ON
    r."FromPersonID" = "mjBizAppsCommonPerson_FromPersonID"."ID"
LEFT OUTER JOIN
    __mj_BizAppsCommon."Organization" AS "mjBizAppsCommonOrganization_FromOrganizationID"
  ON
    r."FromOrganizationID" = "mjBizAppsCommonOrganization_FromOrganizationID"."ID"
LEFT OUTER JOIN
    __mj_BizAppsCommon."Person" AS "mjBizAppsCommonPerson_ToPersonID"
  ON
    r."ToPersonID" = "mjBizAppsCommonPerson_ToPersonID"."ID"
LEFT OUTER JOIN
    __mj_BizAppsCommon."Organization" AS "mjBizAppsCommonOrganization_ToOrganizationID"
  ON
    r."ToOrganizationID" = "mjBizAppsCommonOrganization_ToOrganizationID"."ID"
LEFT OUTER JOIN
    __mj_BizAppsCommon."JobFunction" AS "mjBizAppsCommonJobFunction_JobFunctionID"
  ON
    r."JobFunctionID" = "mjBizAppsCommonJobFunction_JobFunctionID"."ID"
LEFT OUTER JOIN
    __mj_BizAppsCommon."SeniorityLevel" AS "mjBizAppsCommonSeniorityLevel_SeniorityLevelID"
  ON
    r."SeniorityLevelID" = "mjBizAppsCommonSeniorityLevel_SeniorityLevelID"."ID"$vsql$;
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
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spCreateActivitySyncExclusion]
--     @ID UUID = NULL,
--     @ActivitySyncRuleSetID_Clear bit = 0,
--     @ActivitySyncRuleSetID UUID = NULL,
--    ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spUpdateActivitySyncExclusion]
--     @ID UUID,
--     @ActivitySyncRuleSetID_Clear bit = 0,
--     @ActivitySyncRuleSetID UUID = NULL,
--     @Ident...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spDeleteActivitySyncExclusion]
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         [__mj_BizAppsCommon].[ActivitySyncExclusion]
--     WH...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spCreateContactMethod]
--     @ID UUID = NULL,
--     @PersonID_Clear bit = 0,
--     @PersonID UUID = NULL,
--     @OrganizationID_Clear bit = 0,
--   ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spUpdateContactMethod]
--     @ID UUID,
--     @PersonID_Clear bit = 0,
--     @PersonID UUID = NULL,
--     @OrganizationID_Clear bit = 0,
--     @Orga...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spCreatePerson]
--     @ID UUID = NULL,
--     @FirstName VARCHAR(100),
--     @LastName VARCHAR(100),
--     @MiddleName_Clear bit = 0,
--     @MiddleName nvarch...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spUpdatePerson]
--     @ID UUID,
--     @FirstName VARCHAR(100) = NULL,
--     @LastName VARCHAR(100) = NULL,
--     @MiddleName_Clear bit = 0,
--     @MiddleName...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spCreatePersonJobFunction]
--     @ID UUID = NULL,
--     @PersonID UUID,
--     @JobFunctionID UUID,
--     @Sequence INTEGER = NULL,
--     @S...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spUpdatePersonJobFunction]
--     @ID UUID,
--     @PersonID UUID = NULL,
--     @JobFunctionID UUID = NULL,
--     @Sequence INTEGER = NULL,...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spDeleteContactMethod]
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         [__mj_BizAppsCommon].[ContactMethod]
--     WHERE
--         [ID]...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spDeletePerson]
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         [__mj_BizAppsCommon].[Person]
--     WHERE
--         [ID] = @ID
-- 
-- 
--     -...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spDeletePersonJobFunction]
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         [__mj_BizAppsCommon].[PersonJobFunction]
--     WHERE
--     ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spCreateRelationship]
--     @ID UUID = NULL,
--     @RelationshipTypeID UUID,
--     @FromPersonID_Clear bit = 0,
--     @FromPersonID uniqueidentif...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spUpdateRelationship]
--     @ID UUID,
--     @RelationshipTypeID UUID = NULL,
--     @FromPersonID_Clear bit = 0,
--     @FromPersonID uniqueidentif...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spDeleteRelationship]
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         [__mj_BizAppsCommon].[Relationship]
--     WHERE
--         [ID] =...


-- ===================== Triggers =====================

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_BizAppsCommon].trgUpdateActivitySyncExclusion
-- ON "__mj_BizAppsCommon"."ActivitySyncExclusion"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         "__mj_BizAppsCommon"."Ac

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_BizAppsCommon".trgUpdateContactMethod
-- ON "__mj_BizAppsCommon"."ContactMethod"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         "__mj_BizAppsCommon"."ContactMethod"
   

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_BizAppsCommon].trgUpdatePerson
-- ON "__mj_BizAppsCommon"."Person"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         "__mj_BizAppsCommon"."Person"
--     SET
--         __mj_Upd

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_BizAppsCommon].trgUpdatePersonJobFunction
-- ON "__mj_BizAppsCommon"."PersonJobFunction"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         "__mj_BizAppsCommon"."PersonJobF

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_BizAppsCommon".trgUpdateRelationship
-- ON "__mj_BizAppsCommon"."Relationship"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         "__mj_BizAppsCommon"."Relationship"
--     SE


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

UPDATE __mj."EntityField"
               SET "DefaultInView" = TRUE
               WHERE "ID" = 'DC5EBC38-46D2-414C-AC64-FA81B7EFC19A'
               AND "AutoUpdateDefaultInView" = TRUE;

/* Set field properties for entity */

UPDATE __mj."EntityField"
               SET "DefaultInView" = TRUE
               WHERE "ID" = 'A26F17B8-FDC7-4610-8872-40AFB9FDBF8B'
               AND "AutoUpdateDefaultInView" = TRUE;

/* Set field properties for entity */

UPDATE __mj."EntityField"
               SET "DefaultInView" = TRUE
               WHERE "ID" = 'B61DD372-EDE6-4B46-80FC-BCD0BCE3714F'
               AND "AutoUpdateDefaultInView" = TRUE;

/* Set field properties for entity */

UPDATE __mj."EntityField"
               SET "DefaultInView" = TRUE
               WHERE "ID" = '76D49448-C586-4701-9FFF-63F390EC78C0'
               AND "AutoUpdateDefaultInView" = TRUE;

/* Set entity icon to fa fa-id-card */

UPDATE __mj."Entity"
               SET "Icon" = 'fa fa-id-card', "__mj_UpdatedAt" = NOW()
               WHERE "ID" = '09D27A10-6C32-4EB5-A5DA-0317A8168C53';

/* Set categories for 1 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Methods.Person

UPDATE __mj."EntityField"
SET 
   "Category" = 'Linked Record',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = 'DC5EBC38-46D2-414C-AC64-FA81B7EFC19A';

/* Refresh custom base views for modified entities so schema changes are picked up */


-- ===================== Grants =====================

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwActivitySyncExclusions" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwActivitySyncExclusions" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwActivitySyncExclusions" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwActivitySyncExclusions" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View Permissions SQL for MJ_BizApps_Common: Activity Sync Exclusions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Exclusions
-- Item: Permissions for vwActivitySyncExclusions
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwActivitySyncExclusions" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwActivitySyncExclusions" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwActivitySyncExclusions" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwActivitySyncExclusions" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Activity Sync Exclusions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Exclusions
-- Item: spCreateActivitySyncExclusion
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ActivitySyncExclusion
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateActivitySyncExclusion" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateActivitySyncExclusion" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateActivitySyncExclusion" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Activity Sync Exclusions */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateActivitySyncExclusion" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateActivitySyncExclusion" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateActivitySyncExclusion" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Activity Sync Exclusions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Exclusions
-- Item: spUpdateActivitySyncExclusion
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ActivitySyncExclusion
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateActivitySyncExclusion" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateActivitySyncExclusion" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateActivitySyncExclusion" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateActivitySyncExclusion" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateActivitySyncExclusion" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateActivitySyncExclusion" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Activity Sync Exclusions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Exclusions
-- Item: spDeleteActivitySyncExclusion
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ActivitySyncExclusion
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteActivitySyncExclusion" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteActivitySyncExclusion" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteActivitySyncExclusion" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Activity Sync Exclusions */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteActivitySyncExclusion" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteActivitySyncExclusion" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteActivitySyncExclusion" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Index for Foreign Keys for ContactMethod */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key PersonID in table ContactMethod;

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwContactMethods" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwContactMethods" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwContactMethods" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwContactMethods" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View Permissions SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: Permissions for vwContactMethods
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwContactMethods" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwContactMethods" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwContactMethods" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwContactMethods" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: spCreateContactMethod
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ContactMethod
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateContactMethod" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateContactMethod" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateContactMethod" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Contact Methods */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateContactMethod" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateContactMethod" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateContactMethod" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: spUpdateContactMethod
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ContactMethod
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateContactMethod" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateContactMethod" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateContactMethod" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateContactMethod" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateContactMethod" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateContactMethod" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View SQL for MJ_BizApps_Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: People
-- Item: vwPeopleGenerated
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: People
-----               SCHEMA:      __mj_BizAppsCommon
-----               BASE TABLE:  Person
-----               PRIMARY KEY: ID
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreatePerson" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreatePerson" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreatePerson" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: People */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreatePerson" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreatePerson" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreatePerson" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: People
-- Item: spUpdatePerson
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Person
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdatePerson" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdatePerson" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdatePerson" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdatePerson" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdatePerson" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdatePerson" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View SQL for MJ_BizApps_Common: Person Job Functions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person Job Functions
-- Item: vwPersonJobFunctions
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Person Job Functions
-----               SCHEMA:      __mj_BizAppsCommon
-----               BASE TABLE:  PersonJobFunction
-----               PRIMARY KEY: ID
------------------------------------------------------------;

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwPersonJobFunctions" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwPersonJobFunctions" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwPersonJobFunctions" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwPersonJobFunctions" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View Permissions SQL for MJ_BizApps_Common: Person Job Functions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person Job Functions
-- Item: Permissions for vwPersonJobFunctions
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwPersonJobFunctions" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwPersonJobFunctions" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwPersonJobFunctions" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwPersonJobFunctions" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Person Job Functions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person Job Functions
-- Item: spCreatePersonJobFunction
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR PersonJobFunction
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreatePersonJobFunction" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreatePersonJobFunction" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreatePersonJobFunction" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Person Job Functions */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreatePersonJobFunction" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreatePersonJobFunction" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreatePersonJobFunction" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Person Job Functions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person Job Functions
-- Item: spUpdatePersonJobFunction
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR PersonJobFunction
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdatePersonJobFunction" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdatePersonJobFunction" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdatePersonJobFunction" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdatePersonJobFunction" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdatePersonJobFunction" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdatePersonJobFunction" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: spDeleteContactMethod
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ContactMethod
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteContactMethod" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteContactMethod" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Contact Methods */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteContactMethod" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteContactMethod" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: People
-- Item: spDeletePerson
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Person
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeletePerson" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeletePerson" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: People */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeletePerson" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeletePerson" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Person Job Functions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Person Job Functions
-- Item: spDeletePersonJobFunction
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR PersonJobFunction
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeletePersonJobFunction" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeletePersonJobFunction" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeletePersonJobFunction" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Person Job Functions */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeletePersonJobFunction" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeletePersonJobFunction" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeletePersonJobFunction" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Index for Foreign Keys for Relationship */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key RelationshipTypeID in table Relationship;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateRelationship" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateRelationship" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateRelationship" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Relationships */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateRelationship" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateRelationship" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateRelationship" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
-- Item: spUpdateRelationship
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Relationship
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateRelationship" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateRelationship" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateRelationship" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateRelationship" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateRelationship" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateRelationship" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
-- Item: spDeleteRelationship
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Relationship
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteRelationship" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteRelationship" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Relationships */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteRelationship" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteRelationship" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Set field properties for entity */


-- ===================== Other =====================

-- Person.DisplayName becomes FirstName LastName Suffix with blank parts dropped. Written by hand: the
-- converter drops the T-SQL's column drop and passes its re-add through untranslated.
--   * PostgreSQL 17 and later change a generated column's expression in place (SET EXPRESSION), so
--     every view over it, in this app or another, stays as it is.
--   * Earlier versions cannot, so the column is dropped and added back. Every view that depends on
--     Person (in any schema, at any depth) is captured with its definition and grants, dropped
--     deepest first, and recreated in order afterwards; functions whose signature uses one of those
--     views' row types (CodeGen's CRUD functions) are captured, dropped and recreated the same way.
--     No CASCADE, so nothing is lost silently.
--   * Skipped when the column already has the new expression.
DO $dn$
DECLARE
  v_expr CONSTANT TEXT := $e$(CAST(COALESCE(SUBSTRING(
        COALESCE(' ' || NULLIF(TRIM("FirstName"), ''), '')
        || COALESCE(' ' || NULLIF(TRIM("LastName"), ''), '')
        || COALESCE(' ' || NULLIF(TRIM("Suffix"), ''), '')
    FROM 2), '') AS VARCHAR(250)))$e$;
  v_person OID := '__mj_bizappscommon."Person"'::regclass;
  v_views JSONB[] := ARRAY[]::JSONB[];
  v_fns JSONB[] := ARRAY[]::JSONB[];
  v_dep RECORD;
  v_acl RECORD;
  v_n INTEGER;
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema = '__mj_bizappscommon' AND table_name = 'Person'
               AND column_name = 'DisplayName' AND generation_expression ILIKE '%Suffix%') THEN
    RETURN;
  END IF;

  IF current_setting('server_version_num')::int >= 170000
     AND EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema = '__mj_bizappscommon' AND table_name = 'Person'
                   AND column_name = 'DisplayName' AND is_generated = 'ALWAYS') THEN
    EXECUTE 'ALTER TABLE __mj_bizappscommon."Person" ALTER COLUMN "DisplayName" SET EXPRESSION AS ' || v_expr;
    RETURN;
  END IF;

  FOR v_dep IN
    WITH RECURSIVE deps AS (
      SELECT c.oid, 1 AS depth
      FROM pg_depend d
      JOIN pg_rewrite r ON r.oid = d.objid
      JOIN pg_class c ON c.oid = r.ev_class
      WHERE d.refobjid = v_person AND c.relkind = 'v' AND c.oid <> v_person
      UNION
      SELECT c.oid, p.depth + 1
      FROM deps p
      JOIN pg_depend d ON d.refobjid = p.oid
      JOIN pg_rewrite r ON r.oid = d.objid
      JOIN pg_class c ON c.oid = r.ev_class
      WHERE c.relkind = 'v' AND c.oid <> p.oid
    )
    SELECT c.oid, n.nspname AS schema, c.relname AS name, MAX(deps.depth) AS depth,
           pg_catalog.pg_get_viewdef(c.oid, true) AS def, c.relacl::text AS acl
    FROM deps JOIN pg_class c ON c.oid = deps.oid JOIN pg_namespace n ON n.oid = c.relnamespace
    GROUP BY c.oid, n.nspname, c.relname, c.relacl
    ORDER BY MAX(deps.depth) ASC
  LOOP
    v_views := v_views || jsonb_build_object('oid', v_dep.oid, 'schema', v_dep.schema, 'name', v_dep.name,
                                             'def', v_dep.def, 'acl', v_dep.acl);
  END LOOP;

  -- Functions whose signature uses a captured view's row type (CodeGen's CRUD functions return
  -- SETOF the base view) block DROP VIEW; capture them too, with their grants, and drop them first.
  FOR v_dep IN
    SELECT DISTINCT pr.oid, pg_catalog.pg_get_functiondef(pr.oid) AS def, pr.proacl::text AS acl,
           pr.oid::regprocedure::text AS sig
    FROM pg_depend d JOIN pg_proc pr ON pr.oid = d.objid AND d.classid = 'pg_proc'::regclass
    JOIN pg_class c ON c.reltype = d.refobjid
    WHERE c.oid IN (SELECT (x->>'oid')::oid FROM unnest(v_views) x)
  LOOP
    v_fns := v_fns || jsonb_build_object('def', v_dep.def, 'acl', v_dep.acl, 'sig', v_dep.sig);
  END LOOP;
  IF array_length(v_fns, 1) > 0 THEN
    FOR v_n IN 1..array_length(v_fns, 1) LOOP
      EXECUTE 'DROP FUNCTION ' || (v_fns[v_n]->>'sig');
    END LOOP;
  END IF;
  IF array_length(v_views, 1) > 0 THEN
    FOR v_n IN REVERSE array_length(v_views, 1)..1 LOOP
      EXECUTE format('DROP VIEW %I.%I', v_views[v_n]->>'schema', v_views[v_n]->>'name');
    END LOOP;
  END IF;

  DROP INDEX IF EXISTS __mj_bizappscommon."IX_Person_DisplayName";
  ALTER TABLE __mj_bizappscommon."Person" DROP COLUMN IF EXISTS "DisplayName";
  EXECUTE 'ALTER TABLE __mj_bizappscommon."Person" ADD COLUMN "DisplayName" VARCHAR(250) NOT NULL GENERATED ALWAYS AS '
          || v_expr || ' STORED';
  CREATE INDEX "IX_Person_DisplayName" ON __mj_bizappscommon."Person" ("DisplayName" text_pattern_ops);

  IF array_length(v_views, 1) > 0 THEN
    FOR v_n IN 1..array_length(v_views, 1) LOOP
      EXECUTE format('CREATE VIEW %I.%I AS %s', v_views[v_n]->>'schema', v_views[v_n]->>'name', v_views[v_n]->>'def');
      IF v_views[v_n]->>'acl' IS NOT NULL THEN
        FOR v_acl IN
          SELECT a.privilege_type, CASE WHEN a.grantee = 0 THEN 'PUBLIC' ELSE quote_ident(pg_get_userbyid(a.grantee)) END AS grantee
          FROM aclexplode((v_views[v_n]->>'acl')::aclitem[]) a
          WHERE a.grantee <> a.grantor
        LOOP
          EXECUTE format('GRANT %s ON %I.%I TO %s', v_acl.privilege_type, v_views[v_n]->>'schema', v_views[v_n]->>'name', v_acl.grantee);
        END LOOP;
      END IF;
    END LOOP;
  END IF;

  IF array_length(v_fns, 1) > 0 THEN
    FOR v_n IN 1..array_length(v_fns, 1) LOOP
      EXECUTE v_fns[v_n]->>'def';
      IF v_fns[v_n]->>'acl' IS NOT NULL THEN
        FOR v_acl IN
          SELECT a.privilege_type, CASE WHEN a.grantee = 0 THEN 'PUBLIC' ELSE quote_ident(pg_get_userbyid(a.grantee)) END AS grantee
          FROM aclexplode((v_fns[v_n]->>'acl')::aclitem[]) a WHERE a.grantee <> a.grantor
        LOOP
          EXECUTE format('GRANT %s ON FUNCTION %s TO %s', v_acl.privilege_type, v_fns[v_n]->>'sig', v_acl.grantee);
        END LOOP;
      END IF;
    END LOOP;
  END IF;
END
$dn$;

/* ============================================================================================
   ==== CODEGEN OUTPUT — DO NOT EDIT BELOW THIS LINE ====
   Generated by the MemberJunction CodeGen tool: MJ CLI 6.2.0-edge.3 / CodeGenLib from MJ `next`
   @ d96fee72d7, includeSchemas ['__mj_BizAppsCommon'], against a database built from migrations
   through V202610151048 with this branch's metadata/ pushed (CodeGen then produced no SQL).
   Contains: vwPeopleGenerated and People CRUD procs, plus every entity whose view joins
   Person.DisplayName as an FK label (Contact Methods, Person Job Functions, Activity Sync
   Exclusions, Relationships), FK indexes, field settings, the Person Job Functions icon, and a
   guarded refresh of the vwPeople / vwRelationships wrappers.
   Do NOT edit by hand. If the hand-written SQL above changes, re-run CodeGen and replace this
   whole section.
   Runs: one, after the DDL above; two more runs produced no SQL.
   ============================================================================================ */

/* Index for Foreign Keys for ActivitySyncExclusion */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Exclusions
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key ActivitySyncRuleSetID in table ActivitySyncExclusion

/* spUpdate Permissions for MJ_BizApps_Common: Activity Sync Exclusions */

/* spUpdate Permissions for MJ_BizApps_Common: Contact Methods */

/* spUpdate Permissions for MJ_BizApps_Common: People */

/* spUpdate Permissions for MJ_BizApps_Common: Person Job Functions */

/* spUpdate Permissions for MJ_BizApps_Common: Relationships */

-- =============================================================================
-- Native PostgreSQL CodeGen for the procedures and triggers the conversion above skipped
-- (ActivitySyncExclusion, ContactMethod, Person, PersonJobFunction, Relationship).
-- =============================================================================
-- ---------- native PostgreSQL CodeGen: MJ_BizApps_Common: Activity Sync Exclusions
-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Activity Sync Exclusions
-- Item: Index for Foreign Keys

-- ============================================================
CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_activity_sync_exclusion_activity_sync_rule_set"
    ON "__mj_bizappscommon"."ActivitySyncExclusion" ("ActivitySyncRuleSetID");

CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_activity_sync_exclusion_person_id"
    ON "__mj_bizappscommon"."ActivitySyncExclusion" ("PersonID");

-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Activity Sync Exclusions
-- Item: vwActivitySyncExclusions

-- ============================================================

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Activity Sync Exclusions
-----               SCHEMA:      __mj_bizappscommon
-----               BASE TABLE:  ActivitySyncExclusion
-----               PRIMARY KEY: ID
------------------------------------------------------------
DO $vw_regen$
DECLARE
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW "__mj_bizappscommon"."vwActivitySyncExclusions"
AS
SELECT
    a.*,
    mjbizappscommonActivitySyncRuleSet_ActivitySyncRuleSetID."Name" AS "ActivitySyncRuleSet",
    mjbizappscommonPerson_PersonID."DisplayName" AS "Person"
FROM
    "__mj_bizappscommon"."ActivitySyncExclusion" AS a
LEFT OUTER JOIN
    "__mj_bizappscommon"."ActivitySyncRuleSet" AS mjbizappscommonActivitySyncRuleSet_ActivitySyncRuleSetID
  ON
    "a"."ActivitySyncRuleSetID" = mjbizappscommonActivitySyncRuleSet_ActivitySyncRuleSetID."ID"
LEFT OUTER JOIN
    "__mj_bizappscommon"."Person" AS mjbizappscommonPerson_PersonID
  ON
    "a"."PersonID" = mjbizappscommonPerson_PersonID."ID"
$vsql$;
  rec RECORD;
BEGIN
  EXECUTE vsql;
EXCEPTION WHEN invalid_table_definition THEN
  -- 42P16: column rename/reorder/type change. CREATE OR REPLACE can't handle
  -- non-additive shape changes — must DROP CASCADE + recreate. CASCADE drops
  -- every dependent view (anything that JOINs this view in its body), so we
  -- capture each dependent's definition + grants BEFORE the drop and replay
  -- them afterward (best-effort). Without this, on a fresh-DB replay where
  -- one entity's wrapper triggers (e.g. vwAIModelTypes shape changed since
  -- baseline V202605021056), CASCADE wipes downstream views (vwAIModels)
  -- that the wrapper for this entity doesn't know how to recreate, and
  -- those views stay permanently missing.
  CREATE TEMP TABLE IF NOT EXISTS _vw_regen_deps (
    schema_name TEXT,
    view_name   TEXT,
    relkind     CHAR(1),
    definition  TEXT,
    grants_sql  TEXT,
    depth       INT
  ) ON COMMIT DROP;
  DELETE FROM _vw_regen_deps;

  -- Every view that DROP ... CASCADE removes: direct dependents AND theirs, transitively.
  -- Capturing only direct dependents restored vwTestRuns after a vwTestSuiteRuns regen but
  -- not vwConversations / vwConversationDetails, which select from vwTestRuns — they and their
  -- CRUD functions stayed permanently missing. depth is the LONGEST path from the target, so
  -- replaying in depth order always recreates a view after every view it reads.
  CREATE TEMP TABLE IF NOT EXISTS _vw_regen_dep_oids (
    view_oid OID,
    depth    INT
  ) ON COMMIT DROP;
  DELETE FROM _vw_regen_dep_oids;
  INSERT INTO _vw_regen_dep_oids (view_oid, depth)
  WITH RECURSIVE deps(view_oid, depth) AS (
      SELECT DISTINCT dc.oid, 1
      FROM pg_depend d
      JOIN pg_rewrite r ON r.oid = d.objid AND d.classid = 'pg_rewrite'::regclass
      JOIN pg_class dc ON dc.oid = r.ev_class AND dc.relkind IN ('v', 'm')
      JOIN pg_class tc ON tc.oid = d.refobjid
      JOIN pg_namespace tn ON tn.oid = tc.relnamespace
      WHERE tn.nspname = '__mj_bizappscommon'
        AND tc.relname = 'vwActivitySyncExclusions'
        AND tc.relkind IN ('v', 'm')
        AND dc.oid <> tc.oid
    UNION
      SELECT dc.oid, deps.depth + 1
      FROM deps
      JOIN pg_depend d ON d.refobjid = deps.view_oid
      JOIN pg_rewrite r ON r.oid = d.objid AND d.classid = 'pg_rewrite'::regclass
      JOIN pg_class dc ON dc.oid = r.ev_class AND dc.relkind IN ('v', 'm')
      WHERE dc.oid <> deps.view_oid
        AND deps.depth < 50
  )
  SELECT view_oid, MAX(depth) FROM deps GROUP BY view_oid;

  -- Capture dependent FUNCTIONS too. CASCADE drops every function with
  -- RETURNS SETOF <view> (the codegen-emitted spCreate/spUpdate/spDelete
  -- pattern) when the target view is dropped. Without restoring them,
  -- post-codegen CRUD validation reports those routines as missing —
  -- e.g. "MJ: Recommendation Items → missing create routine
  -- spCreateRecommendationItem" — even though the next codegen pass
  -- emits them. The restored definitions are pg_get_functiondef() output
  -- which is a complete CREATE OR REPLACE FUNCTION statement plus a
  -- trailing semicolon; replaying them verbatim recreates the function
  -- with its original body, parameter list, and return type.
  CREATE TEMP TABLE IF NOT EXISTS _vw_regen_fn_deps (
    schema_name TEXT,
    fn_name     TEXT,
    fn_oid      OID,
    definition  TEXT
  ) ON COMMIT DROP;
  DELETE FROM _vw_regen_fn_deps;

  -- Capture dependents. NOTES on the grants_sql build:
  --   - Resolve role name via pg_get_userbyid(oid) — returns the bare,
  --     unquoted role name (or 'unknown (OID=N)' if the oid no longer
  --     exists). pg_get_userbyid is a public catalog function available to
  --     every database user, including unprivileged accounts on managed
  --     PostgreSQL services (Amazon RDS, Azure Database for PostgreSQL,
  --     Cloud SQL) where pg_authid is restricted to the rds_superuser /
  --     azure_pg_admin / cloudsqlsuperuser group. Earlier revisions joined
  --     to pg_authid which works on self-hosted PG but fails with
  --     "permission denied for table pg_authid" on managed services.
  --   - The earlier (broken) approach cast (aclexplode).grantee::regrole::text
  --     which RETURNS the role name pre-quoted when it contains uppercase
  --     (e.g. cdp_Developer comes back already wrapped); calling quote_ident
  --     on the already-quoted string double-wrapped and the GRANT failed at
  --     replay with "role does not exist". Using
  --     pg_get_userbyid returns a bare name and lets quote_ident wrap it
  --     correctly exactly once.
  --   - PUBLIC is grantee oid 0; pg_get_userbyid(0) returns 'unknown
  --     (OID=0)' so handle the PUBLIC case explicitly and use it as the
  --     literal 'PUBLIC' rather than quote_ident on the synthetic name.
  INSERT INTO _vw_regen_deps (schema_name, view_name, relkind, definition, grants_sql, depth)
  SELECT
      dn.nspname,
      dc.relname,
      dc.relkind,
      pg_get_viewdef(dc.oid),
      (SELECT string_agg(
          'GRANT ' || g.privilege || ' ON ' || quote_ident(dn.nspname) || '.' || quote_ident(dc.relname) ||
          ' TO ' || (CASE WHEN g.grantee_oid = 0 THEN 'PUBLIC' ELSE quote_ident(pg_get_userbyid(g.grantee_oid)) END) || ';',
          E'
')
       FROM (
           SELECT (aclexplode(dc.relacl)).grantee AS grantee_oid,
                  (aclexplode(dc.relacl)).privilege_type AS privilege
       ) g
       WHERE g.privilege IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES', 'TRIGGER')),
      o.depth
  FROM _vw_regen_dep_oids o
  JOIN pg_class dc ON dc.oid = o.view_oid
  JOIN pg_namespace dn ON dn.oid = dc.relnamespace;

  -- Capture dependent functions. Two paths matter on PG:
  --   1. Functions whose RETURN type references the view (RETURNS SETOF
  --      <view>) — pg_depend records this as type=pg_type → pg_class.
  --   2. Functions whose body references the view (used by sql functions
  --      and by some plpgsql edge cases) — pg_depend records this as
  --      pg_proc → pg_class.
  -- pg_get_functiondef returns a complete CREATE OR REPLACE FUNCTION
  -- statement that we replay verbatim. We DO include RETURNS-only
  -- references because that's the dominant codegen pattern (sp* CRUD
  -- functions all RETURNS SETOF the matching vwX).
  -- The set is the target view plus every view captured above, because CASCADE drops the
  -- functions of each of them, not only the target's.
  INSERT INTO _vw_regen_fn_deps (schema_name, fn_name, fn_oid, definition)
  SELECT DISTINCT
      pn.nspname,
      pp.proname,
      pp.oid,
      pg_get_functiondef(pp.oid)
  FROM pg_proc pp
  JOIN pg_namespace pn ON pn.oid = pp.pronamespace
  WHERE pp.prokind IN ('f', 'p')
    AND EXISTS (
      SELECT 1
      FROM pg_class c
      WHERE (c.oid IN (SELECT view_oid FROM _vw_regen_dep_oids)
             OR c.oid = (SELECT tc.oid FROM pg_class tc
                         JOIN pg_namespace tn ON tn.oid = tc.relnamespace
                         WHERE tn.nspname = '__mj_bizappscommon'
                           AND tc.relname = 'vwActivitySyncExclusions'
                           AND tc.relkind IN ('v', 'm')))
        AND (pp.prorettype = c.reltype
             OR EXISTS (SELECT 1 FROM pg_depend d
                        WHERE d.classid = 'pg_proc'::regclass
                          AND d.objid = pp.oid
                          AND d.refobjid = c.oid))
  );

  DROP VIEW IF EXISTS "__mj_bizappscommon"."vwActivitySyncExclusions" CASCADE;
  EXECUTE vsql;

  -- Replay captured dependents. Best-effort: log + continue on failure.
  -- IMPORTANT: the CREATE VIEW and the GRANTs run in SEPARATE inner BEGIN
  -- blocks. PL/pgSQL's BEGIN ... EXCEPTION creates an implicit savepoint
  -- and rolls back EVERY statement in the block on any exception. If we
  -- combined CREATE+GRANT in one block and a GRANT failed (e.g. role not
  -- present in target environment), the just-recreated VIEW would also
  -- get rolled back and stay missing — the exact failure mode this
  -- wrapper exists to prevent.
  FOR rec IN SELECT schema_name, view_name, relkind, definition, grants_sql FROM _vw_regen_deps ORDER BY depth, view_name LOOP
    BEGIN
      IF rec.relkind = 'm' THEN
        EXECUTE 'CREATE MATERIALIZED VIEW ' || quote_ident(rec.schema_name) || '.' || quote_ident(rec.view_name) || ' AS ' || rec.definition;
      ELSE
        EXECUTE 'CREATE VIEW ' || quote_ident(rec.schema_name) || '.' || quote_ident(rec.view_name) || ' AS ' || rec.definition;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Best-effort restore skipped dependent %.%: %', rec.schema_name, rec.view_name, SQLERRM;
    END;

    IF rec.grants_sql IS NOT NULL THEN
      BEGIN
        EXECUTE rec.grants_sql;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Best-effort grant restore skipped %.%: %', rec.schema_name, rec.view_name, SQLERRM;
      END;
    END IF;
  END LOOP;

  -- Replay captured dependent functions AFTER all dependent views are
  -- restored — most codegen-emitted sp* functions reference both the
  -- target view AND the dependent views in their bodies/return types.
  -- Wrapped per-function in its own savepoint so a single failure
  -- doesn't poison subsequent restores or the just-recreated target.
  FOR rec IN SELECT schema_name, fn_name, definition FROM _vw_regen_fn_deps LOOP
    BEGIN
      EXECUTE rec.definition;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Best-effort restore skipped dependent function %.%: %', rec.schema_name, rec.fn_name, SQLERRM;
    END;
  END LOOP;

  DROP TABLE _vw_regen_deps;
  DROP TABLE _vw_regen_dep_oids;
  DROP TABLE _vw_regen_fn_deps;
END $vw_regen$;
GRANT SELECT ON "__mj_bizappscommon"."vwActivitySyncExclusions" TO "cdp_UI";
GRANT SELECT ON "__mj_bizappscommon"."vwActivitySyncExclusions" TO "cdp_Developer";
GRANT SELECT ON "__mj_bizappscommon"."vwActivitySyncExclusions" TO "cdp_Integration";

-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Activity Sync Exclusions
-- Item: spCreateActivitySyncExclusion

-- ============================================================

------------------------------------------------------------
----- CREATE FUNCTION FOR ActivitySyncExclusion
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spCreateActivitySyncExclusion'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spCreateActivitySyncExclusion"(
    p_id UUID DEFAULT NULL,
    p_activitysyncrulesetid_clear boolean DEFAULT false,
    p_activitysyncrulesetid UUID DEFAULT NULL,
    p_identitykind varchar(20) DEFAULT NULL,
    p_identityvalue varchar(320) DEFAULT NULL,
    p_personid_clear boolean DEFAULT false,
    p_personid UUID DEFAULT NULL,
    p_reason_clear boolean DEFAULT false,
    p_reason TEXT DEFAULT NULL,
    p_effectivefrom_clear boolean DEFAULT false,
    p_effectivefrom TIMESTAMPTZ DEFAULT NULL,
    p_effectiveto_clear boolean DEFAULT false,
    p_effectiveto TIMESTAMPTZ DEFAULT NULL,
    p_isenabled BOOLEAN DEFAULT NULL
) RETURNS SETOF "__mj_bizappscommon"."vwActivitySyncExclusions" AS $$
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO "__mj_bizappscommon"."ActivitySyncExclusion"
        (
            "ID",
            "ActivitySyncRuleSetID",
                "IdentityKind",
                "IdentityValue",
                "PersonID",
                "Reason",
                "EffectiveFrom",
                "EffectiveTo",
                "IsEnabled"
        )
    VALUES
        (
            v_new_id,
            CASE WHEN p_activitysyncrulesetid_clear = true THEN NULL ELSE COALESCE(p_activitysyncrulesetid, NULL) END,
                p_identitykind,
                p_identityvalue,
                CASE WHEN p_personid_clear = true THEN NULL ELSE COALESCE(p_personid, NULL) END,
                CASE WHEN p_reason_clear = true THEN NULL ELSE COALESCE(p_reason, NULL) END,
                CASE WHEN p_effectivefrom_clear = true THEN NULL ELSE COALESCE(p_effectivefrom, NULL) END,
                CASE WHEN p_effectiveto_clear = true THEN NULL ELSE COALESCE(p_effectiveto, NULL) END,
                COALESCE(p_isenabled, TRUE)
        )
    ;

    RETURN QUERY
    SELECT * FROM "__mj_bizappscommon"."vwActivitySyncExclusions"
    WHERE "ID" = v_new_id;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spCreateActivitySyncExclusion" TO "cdp_Developer";
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spCreateActivitySyncExclusion" TO "cdp_Integration";


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Activity Sync Exclusions
-- Item: spUpdateActivitySyncExclusion

-- ============================================================

------------------------------------------------------------
----- UPDATE FUNCTION FOR ActivitySyncExclusion
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spUpdateActivitySyncExclusion'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spUpdateActivitySyncExclusion"(
    p_id UUID,
    p_activitysyncrulesetid_clear boolean DEFAULT false,
    p_activitysyncrulesetid UUID DEFAULT NULL,
    p_identitykind varchar(20) DEFAULT NULL,
    p_identityvalue varchar(320) DEFAULT NULL,
    p_personid_clear boolean DEFAULT false,
    p_personid UUID DEFAULT NULL,
    p_reason_clear boolean DEFAULT false,
    p_reason TEXT DEFAULT NULL,
    p_effectivefrom_clear boolean DEFAULT false,
    p_effectivefrom TIMESTAMPTZ DEFAULT NULL,
    p_effectiveto_clear boolean DEFAULT false,
    p_effectiveto TIMESTAMPTZ DEFAULT NULL,
    p_isenabled BOOLEAN DEFAULT NULL
) RETURNS SETOF "__mj_bizappscommon"."vwActivitySyncExclusions" AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE "__mj_bizappscommon"."ActivitySyncExclusion"
    SET
        "ActivitySyncRuleSetID" = CASE WHEN p_activitysyncrulesetid_clear = true THEN NULL ELSE COALESCE(p_activitysyncrulesetid, "ActivitySyncRuleSetID") END,
        "IdentityKind" = COALESCE(p_identitykind, "IdentityKind"),
        "IdentityValue" = COALESCE(p_identityvalue, "IdentityValue"),
        "PersonID" = CASE WHEN p_personid_clear = true THEN NULL ELSE COALESCE(p_personid, "PersonID") END,
        "Reason" = CASE WHEN p_reason_clear = true THEN NULL ELSE COALESCE(p_reason, "Reason") END,
        "EffectiveFrom" = CASE WHEN p_effectivefrom_clear = true THEN NULL ELSE COALESCE(p_effectivefrom, "EffectiveFrom") END,
        "EffectiveTo" = CASE WHEN p_effectiveto_clear = true THEN NULL ELSE COALESCE(p_effectiveto, "EffectiveTo") END,
        "IsEnabled" = COALESCE(p_isenabled, "IsEnabled")
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        -- Nothing was updated, return empty result set
        RETURN;
    END IF;

    -- Return the updated record from the base view
    RETURN QUERY
    SELECT * FROM "__mj_bizappscommon"."vwActivitySyncExclusions"
    WHERE "ID" = p_id;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spUpdateActivitySyncExclusion" TO "cdp_Developer";
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spUpdateActivitySyncExclusion" TO "cdp_Integration";


------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ActivitySyncExclusion table
------------------------------------------------------------
CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."fn_trg_update_activity_sync_exclusion"()
RETURNS TRIGGER AS $$
BEGIN
    NEW."__mj_UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS "trg_update_activity_sync_exclusion" ON "__mj_bizappscommon"."ActivitySyncExclusion";

CREATE TRIGGER "trg_update_activity_sync_exclusion"
BEFORE UPDATE ON "__mj_bizappscommon"."ActivitySyncExclusion"
FOR EACH ROW
EXECUTE FUNCTION "__mj_bizappscommon"."fn_trg_update_activity_sync_exclusion"();



-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Activity Sync Exclusions
-- Item: spDeleteActivitySyncExclusion

-- ============================================================

------------------------------------------------------------
----- DELETE FUNCTION FOR ActivitySyncExclusion
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spDeleteActivitySyncExclusion'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spDeleteActivitySyncExclusion"(
    p_id UUID
) RETURNS TABLE("ID" UUID) AS $$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
BEGIN

    DELETE FROM "__mj_bizappscommon"."ActivitySyncExclusion"
    WHERE "ID" = p_id;

    GET DIAGNOSTICS v_affected_count = ROW_COUNT;

    IF v_affected_count = 0 THEN
        RETURN QUERY SELECT NULL::UUID AS "ID";
    ELSE
        RETURN QUERY SELECT p_id AS "ID";
    END IF;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spDeleteActivitySyncExclusion" TO "cdp_Developer";
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spDeleteActivitySyncExclusion" TO "cdp_Integration";

-- ---------- native PostgreSQL CodeGen: MJ_BizApps_Common: Contact Methods
-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Contact Methods
-- Item: Index for Foreign Keys

-- ============================================================
CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_contact_method_person_id"
    ON "__mj_bizappscommon"."ContactMethod" ("PersonID");

CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_contact_method_organization_id"
    ON "__mj_bizappscommon"."ContactMethod" ("OrganizationID");

CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_contact_method_contact_type_id"
    ON "__mj_bizappscommon"."ContactMethod" ("ContactTypeID");

-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Contact Methods
-- Item: vwContactMethods

-- ============================================================

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Contact Methods
-----               SCHEMA:      __mj_bizappscommon
-----               BASE TABLE:  ContactMethod
-----               PRIMARY KEY: ID
------------------------------------------------------------
DO $vw_regen$
DECLARE
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW "__mj_bizappscommon"."vwContactMethods"
AS
SELECT
    c.*,
    mjbizappscommonPerson_PersonID."DisplayName" AS "Person",
    mjbizappscommonOrganization_OrganizationID."Name" AS "Organization",
    mjbizappscommonContactType_ContactTypeID."Name" AS "ContactType"
FROM
    "__mj_bizappscommon"."ContactMethod" AS c
LEFT OUTER JOIN
    "__mj_bizappscommon"."Person" AS mjbizappscommonPerson_PersonID
  ON
    "c"."PersonID" = mjbizappscommonPerson_PersonID."ID"
LEFT OUTER JOIN
    "__mj_bizappscommon"."Organization" AS mjbizappscommonOrganization_OrganizationID
  ON
    "c"."OrganizationID" = mjbizappscommonOrganization_OrganizationID."ID"
INNER JOIN
    "__mj_bizappscommon"."ContactType" AS mjbizappscommonContactType_ContactTypeID
  ON
    "c"."ContactTypeID" = mjbizappscommonContactType_ContactTypeID."ID"
$vsql$;
  rec RECORD;
BEGIN
  EXECUTE vsql;
EXCEPTION WHEN invalid_table_definition THEN
  -- 42P16: column rename/reorder/type change. CREATE OR REPLACE can't handle
  -- non-additive shape changes — must DROP CASCADE + recreate. CASCADE drops
  -- every dependent view (anything that JOINs this view in its body), so we
  -- capture each dependent's definition + grants BEFORE the drop and replay
  -- them afterward (best-effort). Without this, on a fresh-DB replay where
  -- one entity's wrapper triggers (e.g. vwAIModelTypes shape changed since
  -- baseline V202605021056), CASCADE wipes downstream views (vwAIModels)
  -- that the wrapper for this entity doesn't know how to recreate, and
  -- those views stay permanently missing.
  CREATE TEMP TABLE IF NOT EXISTS _vw_regen_deps (
    schema_name TEXT,
    view_name   TEXT,
    relkind     CHAR(1),
    definition  TEXT,
    grants_sql  TEXT,
    depth       INT
  ) ON COMMIT DROP;
  DELETE FROM _vw_regen_deps;

  -- Every view that DROP ... CASCADE removes: direct dependents AND theirs, transitively.
  -- Capturing only direct dependents restored vwTestRuns after a vwTestSuiteRuns regen but
  -- not vwConversations / vwConversationDetails, which select from vwTestRuns — they and their
  -- CRUD functions stayed permanently missing. depth is the LONGEST path from the target, so
  -- replaying in depth order always recreates a view after every view it reads.
  CREATE TEMP TABLE IF NOT EXISTS _vw_regen_dep_oids (
    view_oid OID,
    depth    INT
  ) ON COMMIT DROP;
  DELETE FROM _vw_regen_dep_oids;
  INSERT INTO _vw_regen_dep_oids (view_oid, depth)
  WITH RECURSIVE deps(view_oid, depth) AS (
      SELECT DISTINCT dc.oid, 1
      FROM pg_depend d
      JOIN pg_rewrite r ON r.oid = d.objid AND d.classid = 'pg_rewrite'::regclass
      JOIN pg_class dc ON dc.oid = r.ev_class AND dc.relkind IN ('v', 'm')
      JOIN pg_class tc ON tc.oid = d.refobjid
      JOIN pg_namespace tn ON tn.oid = tc.relnamespace
      WHERE tn.nspname = '__mj_bizappscommon'
        AND tc.relname = 'vwContactMethods'
        AND tc.relkind IN ('v', 'm')
        AND dc.oid <> tc.oid
    UNION
      SELECT dc.oid, deps.depth + 1
      FROM deps
      JOIN pg_depend d ON d.refobjid = deps.view_oid
      JOIN pg_rewrite r ON r.oid = d.objid AND d.classid = 'pg_rewrite'::regclass
      JOIN pg_class dc ON dc.oid = r.ev_class AND dc.relkind IN ('v', 'm')
      WHERE dc.oid <> deps.view_oid
        AND deps.depth < 50
  )
  SELECT view_oid, MAX(depth) FROM deps GROUP BY view_oid;

  -- Capture dependent FUNCTIONS too. CASCADE drops every function with
  -- RETURNS SETOF <view> (the codegen-emitted spCreate/spUpdate/spDelete
  -- pattern) when the target view is dropped. Without restoring them,
  -- post-codegen CRUD validation reports those routines as missing —
  -- e.g. "MJ: Recommendation Items → missing create routine
  -- spCreateRecommendationItem" — even though the next codegen pass
  -- emits them. The restored definitions are pg_get_functiondef() output
  -- which is a complete CREATE OR REPLACE FUNCTION statement plus a
  -- trailing semicolon; replaying them verbatim recreates the function
  -- with its original body, parameter list, and return type.
  CREATE TEMP TABLE IF NOT EXISTS _vw_regen_fn_deps (
    schema_name TEXT,
    fn_name     TEXT,
    fn_oid      OID,
    definition  TEXT
  ) ON COMMIT DROP;
  DELETE FROM _vw_regen_fn_deps;

  -- Capture dependents. NOTES on the grants_sql build:
  --   - Resolve role name via pg_get_userbyid(oid) — returns the bare,
  --     unquoted role name (or 'unknown (OID=N)' if the oid no longer
  --     exists). pg_get_userbyid is a public catalog function available to
  --     every database user, including unprivileged accounts on managed
  --     PostgreSQL services (Amazon RDS, Azure Database for PostgreSQL,
  --     Cloud SQL) where pg_authid is restricted to the rds_superuser /
  --     azure_pg_admin / cloudsqlsuperuser group. Earlier revisions joined
  --     to pg_authid which works on self-hosted PG but fails with
  --     "permission denied for table pg_authid" on managed services.
  --   - The earlier (broken) approach cast (aclexplode).grantee::regrole::text
  --     which RETURNS the role name pre-quoted when it contains uppercase
  --     (e.g. cdp_Developer comes back already wrapped); calling quote_ident
  --     on the already-quoted string double-wrapped and the GRANT failed at
  --     replay with "role does not exist". Using
  --     pg_get_userbyid returns a bare name and lets quote_ident wrap it
  --     correctly exactly once.
  --   - PUBLIC is grantee oid 0; pg_get_userbyid(0) returns 'unknown
  --     (OID=0)' so handle the PUBLIC case explicitly and use it as the
  --     literal 'PUBLIC' rather than quote_ident on the synthetic name.
  INSERT INTO _vw_regen_deps (schema_name, view_name, relkind, definition, grants_sql, depth)
  SELECT
      dn.nspname,
      dc.relname,
      dc.relkind,
      pg_get_viewdef(dc.oid),
      (SELECT string_agg(
          'GRANT ' || g.privilege || ' ON ' || quote_ident(dn.nspname) || '.' || quote_ident(dc.relname) ||
          ' TO ' || (CASE WHEN g.grantee_oid = 0 THEN 'PUBLIC' ELSE quote_ident(pg_get_userbyid(g.grantee_oid)) END) || ';',
          E'
')
       FROM (
           SELECT (aclexplode(dc.relacl)).grantee AS grantee_oid,
                  (aclexplode(dc.relacl)).privilege_type AS privilege
       ) g
       WHERE g.privilege IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES', 'TRIGGER')),
      o.depth
  FROM _vw_regen_dep_oids o
  JOIN pg_class dc ON dc.oid = o.view_oid
  JOIN pg_namespace dn ON dn.oid = dc.relnamespace;

  -- Capture dependent functions. Two paths matter on PG:
  --   1. Functions whose RETURN type references the view (RETURNS SETOF
  --      <view>) — pg_depend records this as type=pg_type → pg_class.
  --   2. Functions whose body references the view (used by sql functions
  --      and by some plpgsql edge cases) — pg_depend records this as
  --      pg_proc → pg_class.
  -- pg_get_functiondef returns a complete CREATE OR REPLACE FUNCTION
  -- statement that we replay verbatim. We DO include RETURNS-only
  -- references because that's the dominant codegen pattern (sp* CRUD
  -- functions all RETURNS SETOF the matching vwX).
  -- The set is the target view plus every view captured above, because CASCADE drops the
  -- functions of each of them, not only the target's.
  INSERT INTO _vw_regen_fn_deps (schema_name, fn_name, fn_oid, definition)
  SELECT DISTINCT
      pn.nspname,
      pp.proname,
      pp.oid,
      pg_get_functiondef(pp.oid)
  FROM pg_proc pp
  JOIN pg_namespace pn ON pn.oid = pp.pronamespace
  WHERE pp.prokind IN ('f', 'p')
    AND EXISTS (
      SELECT 1
      FROM pg_class c
      WHERE (c.oid IN (SELECT view_oid FROM _vw_regen_dep_oids)
             OR c.oid = (SELECT tc.oid FROM pg_class tc
                         JOIN pg_namespace tn ON tn.oid = tc.relnamespace
                         WHERE tn.nspname = '__mj_bizappscommon'
                           AND tc.relname = 'vwContactMethods'
                           AND tc.relkind IN ('v', 'm')))
        AND (pp.prorettype = c.reltype
             OR EXISTS (SELECT 1 FROM pg_depend d
                        WHERE d.classid = 'pg_proc'::regclass
                          AND d.objid = pp.oid
                          AND d.refobjid = c.oid))
  );

  DROP VIEW IF EXISTS "__mj_bizappscommon"."vwContactMethods" CASCADE;
  EXECUTE vsql;

  -- Replay captured dependents. Best-effort: log + continue on failure.
  -- IMPORTANT: the CREATE VIEW and the GRANTs run in SEPARATE inner BEGIN
  -- blocks. PL/pgSQL's BEGIN ... EXCEPTION creates an implicit savepoint
  -- and rolls back EVERY statement in the block on any exception. If we
  -- combined CREATE+GRANT in one block and a GRANT failed (e.g. role not
  -- present in target environment), the just-recreated VIEW would also
  -- get rolled back and stay missing — the exact failure mode this
  -- wrapper exists to prevent.
  FOR rec IN SELECT schema_name, view_name, relkind, definition, grants_sql FROM _vw_regen_deps ORDER BY depth, view_name LOOP
    BEGIN
      IF rec.relkind = 'm' THEN
        EXECUTE 'CREATE MATERIALIZED VIEW ' || quote_ident(rec.schema_name) || '.' || quote_ident(rec.view_name) || ' AS ' || rec.definition;
      ELSE
        EXECUTE 'CREATE VIEW ' || quote_ident(rec.schema_name) || '.' || quote_ident(rec.view_name) || ' AS ' || rec.definition;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Best-effort restore skipped dependent %.%: %', rec.schema_name, rec.view_name, SQLERRM;
    END;

    IF rec.grants_sql IS NOT NULL THEN
      BEGIN
        EXECUTE rec.grants_sql;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Best-effort grant restore skipped %.%: %', rec.schema_name, rec.view_name, SQLERRM;
      END;
    END IF;
  END LOOP;

  -- Replay captured dependent functions AFTER all dependent views are
  -- restored — most codegen-emitted sp* functions reference both the
  -- target view AND the dependent views in their bodies/return types.
  -- Wrapped per-function in its own savepoint so a single failure
  -- doesn't poison subsequent restores or the just-recreated target.
  FOR rec IN SELECT schema_name, fn_name, definition FROM _vw_regen_fn_deps LOOP
    BEGIN
      EXECUTE rec.definition;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Best-effort restore skipped dependent function %.%: %', rec.schema_name, rec.fn_name, SQLERRM;
    END;
  END LOOP;

  DROP TABLE _vw_regen_deps;
  DROP TABLE _vw_regen_dep_oids;
  DROP TABLE _vw_regen_fn_deps;
END $vw_regen$;
GRANT SELECT ON "__mj_bizappscommon"."vwContactMethods" TO "cdp_UI";
GRANT SELECT ON "__mj_bizappscommon"."vwContactMethods" TO "cdp_Developer";
GRANT SELECT ON "__mj_bizappscommon"."vwContactMethods" TO "cdp_Integration";

-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Contact Methods
-- Item: spCreateContactMethod

-- ============================================================

------------------------------------------------------------
----- CREATE FUNCTION FOR ContactMethod
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spCreateContactMethod'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spCreateContactMethod"(
    p_id UUID DEFAULT NULL,
    p_personid_clear boolean DEFAULT false,
    p_personid UUID DEFAULT NULL,
    p_organizationid_clear boolean DEFAULT false,
    p_organizationid UUID DEFAULT NULL,
    p_contacttypeid UUID DEFAULT NULL,
    p_value varchar(500) DEFAULT NULL,
    p_label_clear boolean DEFAULT false,
    p_label varchar(100) DEFAULT NULL,
    p_isprimary BOOLEAN DEFAULT NULL
) RETURNS SETOF "__mj_bizappscommon"."vwContactMethods" AS $$
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO "__mj_bizappscommon"."ContactMethod"
        (
            "ID",
            "PersonID",
                "OrganizationID",
                "ContactTypeID",
                "Value",
                "Label",
                "IsPrimary"
        )
    VALUES
        (
            v_new_id,
            CASE WHEN p_personid_clear = true THEN NULL ELSE COALESCE(p_personid, NULL) END,
                CASE WHEN p_organizationid_clear = true THEN NULL ELSE COALESCE(p_organizationid, NULL) END,
                p_contacttypeid,
                p_value,
                CASE WHEN p_label_clear = true THEN NULL ELSE COALESCE(p_label, NULL) END,
                COALESCE(p_isprimary, FALSE)
        )
    ;

    RETURN QUERY
    SELECT * FROM "__mj_bizappscommon"."vwContactMethods"
    WHERE "ID" = v_new_id;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spCreateContactMethod" TO "cdp_Developer";
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spCreateContactMethod" TO "cdp_Integration";


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Contact Methods
-- Item: spUpdateContactMethod

-- ============================================================

------------------------------------------------------------
----- UPDATE FUNCTION FOR ContactMethod
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spUpdateContactMethod'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spUpdateContactMethod"(
    p_id UUID,
    p_personid_clear boolean DEFAULT false,
    p_personid UUID DEFAULT NULL,
    p_organizationid_clear boolean DEFAULT false,
    p_organizationid UUID DEFAULT NULL,
    p_contacttypeid UUID DEFAULT NULL,
    p_value varchar(500) DEFAULT NULL,
    p_label_clear boolean DEFAULT false,
    p_label varchar(100) DEFAULT NULL,
    p_isprimary BOOLEAN DEFAULT NULL
) RETURNS SETOF "__mj_bizappscommon"."vwContactMethods" AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE "__mj_bizappscommon"."ContactMethod"
    SET
        "PersonID" = CASE WHEN p_personid_clear = true THEN NULL ELSE COALESCE(p_personid, "PersonID") END,
        "OrganizationID" = CASE WHEN p_organizationid_clear = true THEN NULL ELSE COALESCE(p_organizationid, "OrganizationID") END,
        "ContactTypeID" = COALESCE(p_contacttypeid, "ContactTypeID"),
        "Value" = COALESCE(p_value, "Value"),
        "Label" = CASE WHEN p_label_clear = true THEN NULL ELSE COALESCE(p_label, "Label") END,
        "IsPrimary" = COALESCE(p_isprimary, "IsPrimary")
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        -- Nothing was updated, return empty result set
        RETURN;
    END IF;

    -- Return the updated record from the base view
    RETURN QUERY
    SELECT * FROM "__mj_bizappscommon"."vwContactMethods"
    WHERE "ID" = p_id;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spUpdateContactMethod" TO "cdp_Developer";
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spUpdateContactMethod" TO "cdp_Integration";


------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ContactMethod table
------------------------------------------------------------
CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."fn_trg_update_contact_method"()
RETURNS TRIGGER AS $$
BEGIN
    NEW."__mj_UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS "trg_update_contact_method" ON "__mj_bizappscommon"."ContactMethod";

CREATE TRIGGER "trg_update_contact_method"
BEFORE UPDATE ON "__mj_bizappscommon"."ContactMethod"
FOR EACH ROW
EXECUTE FUNCTION "__mj_bizappscommon"."fn_trg_update_contact_method"();



-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Contact Methods
-- Item: spDeleteContactMethod

-- ============================================================

------------------------------------------------------------
----- DELETE FUNCTION FOR ContactMethod
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spDeleteContactMethod'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spDeleteContactMethod"(
    p_id UUID
) RETURNS TABLE("ID" UUID) AS $$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
BEGIN

    DELETE FROM "__mj_bizappscommon"."ContactMethod"
    WHERE "ID" = p_id;

    GET DIAGNOSTICS v_affected_count = ROW_COUNT;

    IF v_affected_count = 0 THEN
        RETURN QUERY SELECT NULL::UUID AS "ID";
    ELSE
        RETURN QUERY SELECT p_id AS "ID";
    END IF;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spDeleteContactMethod" TO "cdp_Integration";

-- ---------- native PostgreSQL CodeGen: MJ_BizApps_Common: People
-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: People
-- Item: Index for Foreign Keys

-- ============================================================
CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_person_linked_user_id"
    ON "__mj_bizappscommon"."Person" ("LinkedUserID");

CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_person_seniority_level_id"
    ON "__mj_bizappscommon"."Person" ("SeniorityLevelID");

-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: People
-- Item: vwPeopleGenerated

-- ============================================================

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: People
-----               SCHEMA:      __mj_bizappscommon
-----               BASE TABLE:  Person
-----               PRIMARY KEY: ID
------------------------------------------------------------
DO $vw_regen$
DECLARE
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW "__mj_bizappscommon"."vwPeopleGenerated"
AS
SELECT
    p.*,
    MJUser_LinkedUserID."Name" AS "LinkedUser",
    mjbizappscommonSeniorityLevel_SeniorityLevelID."Name" AS "SeniorityLevel"
FROM
    "__mj_bizappscommon"."Person" AS p
LEFT OUTER JOIN
    "__mj"."User" AS MJUser_LinkedUserID
  ON
    "p"."LinkedUserID" = MJUser_LinkedUserID."ID"
LEFT OUTER JOIN
    "__mj_bizappscommon"."SeniorityLevel" AS mjbizappscommonSeniorityLevel_SeniorityLevelID
  ON
    "p"."SeniorityLevelID" = mjbizappscommonSeniorityLevel_SeniorityLevelID."ID"
$vsql$;
  rec RECORD;
BEGIN
  EXECUTE vsql;
EXCEPTION WHEN invalid_table_definition THEN
  -- 42P16: column rename/reorder/type change. CREATE OR REPLACE can't handle
  -- non-additive shape changes — must DROP CASCADE + recreate. CASCADE drops
  -- every dependent view (anything that JOINs this view in its body), so we
  -- capture each dependent's definition + grants BEFORE the drop and replay
  -- them afterward (best-effort). Without this, on a fresh-DB replay where
  -- one entity's wrapper triggers (e.g. vwAIModelTypes shape changed since
  -- baseline V202605021056), CASCADE wipes downstream views (vwAIModels)
  -- that the wrapper for this entity doesn't know how to recreate, and
  -- those views stay permanently missing.
  CREATE TEMP TABLE IF NOT EXISTS _vw_regen_deps (
    schema_name TEXT,
    view_name   TEXT,
    relkind     CHAR(1),
    definition  TEXT,
    grants_sql  TEXT,
    depth       INT
  ) ON COMMIT DROP;
  DELETE FROM _vw_regen_deps;

  -- Every view that DROP ... CASCADE removes: direct dependents AND theirs, transitively.
  -- Capturing only direct dependents restored vwTestRuns after a vwTestSuiteRuns regen but
  -- not vwConversations / vwConversationDetails, which select from vwTestRuns — they and their
  -- CRUD functions stayed permanently missing. depth is the LONGEST path from the target, so
  -- replaying in depth order always recreates a view after every view it reads.
  CREATE TEMP TABLE IF NOT EXISTS _vw_regen_dep_oids (
    view_oid OID,
    depth    INT
  ) ON COMMIT DROP;
  DELETE FROM _vw_regen_dep_oids;
  INSERT INTO _vw_regen_dep_oids (view_oid, depth)
  WITH RECURSIVE deps(view_oid, depth) AS (
      SELECT DISTINCT dc.oid, 1
      FROM pg_depend d
      JOIN pg_rewrite r ON r.oid = d.objid AND d.classid = 'pg_rewrite'::regclass
      JOIN pg_class dc ON dc.oid = r.ev_class AND dc.relkind IN ('v', 'm')
      JOIN pg_class tc ON tc.oid = d.refobjid
      JOIN pg_namespace tn ON tn.oid = tc.relnamespace
      WHERE tn.nspname = '__mj_bizappscommon'
        AND tc.relname = 'vwPeopleGenerated'
        AND tc.relkind IN ('v', 'm')
        AND dc.oid <> tc.oid
    UNION
      SELECT dc.oid, deps.depth + 1
      FROM deps
      JOIN pg_depend d ON d.refobjid = deps.view_oid
      JOIN pg_rewrite r ON r.oid = d.objid AND d.classid = 'pg_rewrite'::regclass
      JOIN pg_class dc ON dc.oid = r.ev_class AND dc.relkind IN ('v', 'm')
      WHERE dc.oid <> deps.view_oid
        AND deps.depth < 50
  )
  SELECT view_oid, MAX(depth) FROM deps GROUP BY view_oid;

  -- Capture dependent FUNCTIONS too. CASCADE drops every function with
  -- RETURNS SETOF <view> (the codegen-emitted spCreate/spUpdate/spDelete
  -- pattern) when the target view is dropped. Without restoring them,
  -- post-codegen CRUD validation reports those routines as missing —
  -- e.g. "MJ: Recommendation Items → missing create routine
  -- spCreateRecommendationItem" — even though the next codegen pass
  -- emits them. The restored definitions are pg_get_functiondef() output
  -- which is a complete CREATE OR REPLACE FUNCTION statement plus a
  -- trailing semicolon; replaying them verbatim recreates the function
  -- with its original body, parameter list, and return type.
  CREATE TEMP TABLE IF NOT EXISTS _vw_regen_fn_deps (
    schema_name TEXT,
    fn_name     TEXT,
    fn_oid      OID,
    definition  TEXT
  ) ON COMMIT DROP;
  DELETE FROM _vw_regen_fn_deps;

  -- Capture dependents. NOTES on the grants_sql build:
  --   - Resolve role name via pg_get_userbyid(oid) — returns the bare,
  --     unquoted role name (or 'unknown (OID=N)' if the oid no longer
  --     exists). pg_get_userbyid is a public catalog function available to
  --     every database user, including unprivileged accounts on managed
  --     PostgreSQL services (Amazon RDS, Azure Database for PostgreSQL,
  --     Cloud SQL) where pg_authid is restricted to the rds_superuser /
  --     azure_pg_admin / cloudsqlsuperuser group. Earlier revisions joined
  --     to pg_authid which works on self-hosted PG but fails with
  --     "permission denied for table pg_authid" on managed services.
  --   - The earlier (broken) approach cast (aclexplode).grantee::regrole::text
  --     which RETURNS the role name pre-quoted when it contains uppercase
  --     (e.g. cdp_Developer comes back already wrapped); calling quote_ident
  --     on the already-quoted string double-wrapped and the GRANT failed at
  --     replay with "role does not exist". Using
  --     pg_get_userbyid returns a bare name and lets quote_ident wrap it
  --     correctly exactly once.
  --   - PUBLIC is grantee oid 0; pg_get_userbyid(0) returns 'unknown
  --     (OID=0)' so handle the PUBLIC case explicitly and use it as the
  --     literal 'PUBLIC' rather than quote_ident on the synthetic name.
  INSERT INTO _vw_regen_deps (schema_name, view_name, relkind, definition, grants_sql, depth)
  SELECT
      dn.nspname,
      dc.relname,
      dc.relkind,
      pg_get_viewdef(dc.oid),
      (SELECT string_agg(
          'GRANT ' || g.privilege || ' ON ' || quote_ident(dn.nspname) || '.' || quote_ident(dc.relname) ||
          ' TO ' || (CASE WHEN g.grantee_oid = 0 THEN 'PUBLIC' ELSE quote_ident(pg_get_userbyid(g.grantee_oid)) END) || ';',
          E'
')
       FROM (
           SELECT (aclexplode(dc.relacl)).grantee AS grantee_oid,
                  (aclexplode(dc.relacl)).privilege_type AS privilege
       ) g
       WHERE g.privilege IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES', 'TRIGGER')),
      o.depth
  FROM _vw_regen_dep_oids o
  JOIN pg_class dc ON dc.oid = o.view_oid
  JOIN pg_namespace dn ON dn.oid = dc.relnamespace;

  -- Capture dependent functions. Two paths matter on PG:
  --   1. Functions whose RETURN type references the view (RETURNS SETOF
  --      <view>) — pg_depend records this as type=pg_type → pg_class.
  --   2. Functions whose body references the view (used by sql functions
  --      and by some plpgsql edge cases) — pg_depend records this as
  --      pg_proc → pg_class.
  -- pg_get_functiondef returns a complete CREATE OR REPLACE FUNCTION
  -- statement that we replay verbatim. We DO include RETURNS-only
  -- references because that's the dominant codegen pattern (sp* CRUD
  -- functions all RETURNS SETOF the matching vwX).
  -- The set is the target view plus every view captured above, because CASCADE drops the
  -- functions of each of them, not only the target's.
  INSERT INTO _vw_regen_fn_deps (schema_name, fn_name, fn_oid, definition)
  SELECT DISTINCT
      pn.nspname,
      pp.proname,
      pp.oid,
      pg_get_functiondef(pp.oid)
  FROM pg_proc pp
  JOIN pg_namespace pn ON pn.oid = pp.pronamespace
  WHERE pp.prokind IN ('f', 'p')
    AND EXISTS (
      SELECT 1
      FROM pg_class c
      WHERE (c.oid IN (SELECT view_oid FROM _vw_regen_dep_oids)
             OR c.oid = (SELECT tc.oid FROM pg_class tc
                         JOIN pg_namespace tn ON tn.oid = tc.relnamespace
                         WHERE tn.nspname = '__mj_bizappscommon'
                           AND tc.relname = 'vwPeopleGenerated'
                           AND tc.relkind IN ('v', 'm')))
        AND (pp.prorettype = c.reltype
             OR EXISTS (SELECT 1 FROM pg_depend d
                        WHERE d.classid = 'pg_proc'::regclass
                          AND d.objid = pp.oid
                          AND d.refobjid = c.oid))
  );

  DROP VIEW IF EXISTS "__mj_bizappscommon"."vwPeopleGenerated" CASCADE;
  EXECUTE vsql;

  -- Replay captured dependents. Best-effort: log + continue on failure.
  -- IMPORTANT: the CREATE VIEW and the GRANTs run in SEPARATE inner BEGIN
  -- blocks. PL/pgSQL's BEGIN ... EXCEPTION creates an implicit savepoint
  -- and rolls back EVERY statement in the block on any exception. If we
  -- combined CREATE+GRANT in one block and a GRANT failed (e.g. role not
  -- present in target environment), the just-recreated VIEW would also
  -- get rolled back and stay missing — the exact failure mode this
  -- wrapper exists to prevent.
  FOR rec IN SELECT schema_name, view_name, relkind, definition, grants_sql FROM _vw_regen_deps ORDER BY depth, view_name LOOP
    BEGIN
      IF rec.relkind = 'm' THEN
        EXECUTE 'CREATE MATERIALIZED VIEW ' || quote_ident(rec.schema_name) || '.' || quote_ident(rec.view_name) || ' AS ' || rec.definition;
      ELSE
        EXECUTE 'CREATE VIEW ' || quote_ident(rec.schema_name) || '.' || quote_ident(rec.view_name) || ' AS ' || rec.definition;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Best-effort restore skipped dependent %.%: %', rec.schema_name, rec.view_name, SQLERRM;
    END;

    IF rec.grants_sql IS NOT NULL THEN
      BEGIN
        EXECUTE rec.grants_sql;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Best-effort grant restore skipped %.%: %', rec.schema_name, rec.view_name, SQLERRM;
      END;
    END IF;
  END LOOP;

  -- Replay captured dependent functions AFTER all dependent views are
  -- restored — most codegen-emitted sp* functions reference both the
  -- target view AND the dependent views in their bodies/return types.
  -- Wrapped per-function in its own savepoint so a single failure
  -- doesn't poison subsequent restores or the just-recreated target.
  FOR rec IN SELECT schema_name, fn_name, definition FROM _vw_regen_fn_deps LOOP
    BEGIN
      EXECUTE rec.definition;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Best-effort restore skipped dependent function %.%: %', rec.schema_name, rec.fn_name, SQLERRM;
    END;
  END LOOP;

  DROP TABLE _vw_regen_deps;
  DROP TABLE _vw_regen_dep_oids;
  DROP TABLE _vw_regen_fn_deps;
END $vw_regen$;

DO $if_view_exists$
BEGIN
  IF to_regclass('"__mj_bizappscommon"."vwPeople"') IS NOT NULL THEN
    EXECUTE 'GRANT SELECT ON "__mj_bizappscommon"."vwPeople" TO "cdp_UI";
GRANT SELECT ON "__mj_bizappscommon"."vwPeople" TO "cdp_Developer";
GRANT SELECT ON "__mj_bizappscommon"."vwPeople" TO "cdp_Integration";';
  END IF;
END
$if_view_exists$;


DO $if_view_exists$
BEGIN
  IF to_regclass('"__mj_bizappscommon"."vwPeople"') IS NOT NULL THEN
    EXECUTE 'SELECT "__mj"."spRebindLayeredOuterView"(''__mj_bizappscommon'', ''vwPeople'', ''vwPeopleGenerated'');';
  END IF;
END
$if_view_exists$;


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: People
-- Item: Permissions for vwPeople

-- ============================================================
DO $if_view_exists$
BEGIN
  IF to_regclass('"__mj_bizappscommon"."vwPeople"') IS NOT NULL THEN
    EXECUTE 'GRANT SELECT ON "__mj_bizappscommon"."vwPeople" TO "cdp_UI";
GRANT SELECT ON "__mj_bizappscommon"."vwPeople" TO "cdp_Developer";
GRANT SELECT ON "__mj_bizappscommon"."vwPeople" TO "cdp_Integration";';
  END IF;
END
$if_view_exists$;


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: People
-- Item: spCreatePerson

-- ============================================================

------------------------------------------------------------
----- CREATE FUNCTION FOR Person
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spCreatePerson'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spCreatePerson"(
    p_id UUID DEFAULT NULL,
    p_firstname varchar(100) DEFAULT NULL,
    p_lastname varchar(100) DEFAULT NULL,
    p_middlename_clear boolean DEFAULT false,
    p_middlename varchar(100) DEFAULT NULL,
    p_prefix_clear boolean DEFAULT false,
    p_prefix varchar(20) DEFAULT NULL,
    p_suffix_clear boolean DEFAULT false,
    p_suffix varchar(20) DEFAULT NULL,
    p_preferredname_clear boolean DEFAULT false,
    p_preferredname varchar(100) DEFAULT NULL,
    p_title_clear boolean DEFAULT false,
    p_title varchar(200) DEFAULT NULL,
    p_email_clear boolean DEFAULT false,
    p_email varchar(255) DEFAULT NULL,
    p_phone_clear boolean DEFAULT false,
    p_phone varchar(50) DEFAULT NULL,
    p_dateofbirth_clear boolean DEFAULT false,
    p_dateofbirth date DEFAULT NULL,
    p_gender_clear boolean DEFAULT false,
    p_gender varchar(50) DEFAULT NULL,
    p_photourl_clear boolean DEFAULT false,
    p_photourl TEXT DEFAULT NULL,
    p_bio_clear boolean DEFAULT false,
    p_bio TEXT DEFAULT NULL,
    p_linkeduserid_clear boolean DEFAULT false,
    p_linkeduserid UUID DEFAULT NULL,
    p_status varchar(50) DEFAULT NULL,
    p_senioritylevelid_clear boolean DEFAULT false,
    p_senioritylevelid UUID DEFAULT NULL
) RETURNS SETOF "__mj_bizappscommon"."vwPeople" AS $$
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO "__mj_bizappscommon"."Person"
        (
            "ID",
            "FirstName",
                "LastName",
                "MiddleName",
                "Prefix",
                "Suffix",
                "PreferredName",
                "Title",
                "Email",
                "Phone",
                "DateOfBirth",
                "Gender",
                "PhotoURL",
                "Bio",
                "LinkedUserID",
                "Status",
                "SeniorityLevelID"
        )
    VALUES
        (
            v_new_id,
            p_firstname,
                p_lastname,
                CASE WHEN p_middlename_clear = true THEN NULL ELSE COALESCE(p_middlename, NULL) END,
                CASE WHEN p_prefix_clear = true THEN NULL ELSE COALESCE(p_prefix, NULL) END,
                CASE WHEN p_suffix_clear = true THEN NULL ELSE COALESCE(p_suffix, NULL) END,
                CASE WHEN p_preferredname_clear = true THEN NULL ELSE COALESCE(p_preferredname, NULL) END,
                CASE WHEN p_title_clear = true THEN NULL ELSE COALESCE(p_title, NULL) END,
                CASE WHEN p_email_clear = true THEN NULL ELSE COALESCE(p_email, NULL) END,
                CASE WHEN p_phone_clear = true THEN NULL ELSE COALESCE(p_phone, NULL) END,
                CASE WHEN p_dateofbirth_clear = true THEN NULL ELSE COALESCE(p_dateofbirth, NULL) END,
                CASE WHEN p_gender_clear = true THEN NULL ELSE COALESCE(p_gender, NULL) END,
                CASE WHEN p_photourl_clear = true THEN NULL ELSE COALESCE(p_photourl, NULL) END,
                CASE WHEN p_bio_clear = true THEN NULL ELSE COALESCE(p_bio, NULL) END,
                CASE WHEN p_linkeduserid_clear = true THEN NULL ELSE COALESCE(p_linkeduserid, NULL) END,
                COALESCE(p_status, 'Active'),
                CASE WHEN p_senioritylevelid_clear = true THEN NULL ELSE COALESCE(p_senioritylevelid, NULL) END
        )
    ;

    RETURN QUERY
    SELECT * FROM "__mj_bizappscommon"."vwPeople"
    WHERE "ID" = v_new_id;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spCreatePerson" TO "cdp_Developer";
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spCreatePerson" TO "cdp_Integration";


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: People
-- Item: spUpdatePerson

-- ============================================================

------------------------------------------------------------
----- UPDATE FUNCTION FOR Person
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spUpdatePerson'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spUpdatePerson"(
    p_id UUID,
    p_firstname varchar(100) DEFAULT NULL,
    p_lastname varchar(100) DEFAULT NULL,
    p_middlename_clear boolean DEFAULT false,
    p_middlename varchar(100) DEFAULT NULL,
    p_prefix_clear boolean DEFAULT false,
    p_prefix varchar(20) DEFAULT NULL,
    p_suffix_clear boolean DEFAULT false,
    p_suffix varchar(20) DEFAULT NULL,
    p_preferredname_clear boolean DEFAULT false,
    p_preferredname varchar(100) DEFAULT NULL,
    p_title_clear boolean DEFAULT false,
    p_title varchar(200) DEFAULT NULL,
    p_email_clear boolean DEFAULT false,
    p_email varchar(255) DEFAULT NULL,
    p_phone_clear boolean DEFAULT false,
    p_phone varchar(50) DEFAULT NULL,
    p_dateofbirth_clear boolean DEFAULT false,
    p_dateofbirth date DEFAULT NULL,
    p_gender_clear boolean DEFAULT false,
    p_gender varchar(50) DEFAULT NULL,
    p_photourl_clear boolean DEFAULT false,
    p_photourl TEXT DEFAULT NULL,
    p_bio_clear boolean DEFAULT false,
    p_bio TEXT DEFAULT NULL,
    p_linkeduserid_clear boolean DEFAULT false,
    p_linkeduserid UUID DEFAULT NULL,
    p_status varchar(50) DEFAULT NULL,
    p_senioritylevelid_clear boolean DEFAULT false,
    p_senioritylevelid UUID DEFAULT NULL
) RETURNS SETOF "__mj_bizappscommon"."vwPeople" AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE "__mj_bizappscommon"."Person"
    SET
        "FirstName" = COALESCE(p_firstname, "FirstName"),
        "LastName" = COALESCE(p_lastname, "LastName"),
        "MiddleName" = CASE WHEN p_middlename_clear = true THEN NULL ELSE COALESCE(p_middlename, "MiddleName") END,
        "Prefix" = CASE WHEN p_prefix_clear = true THEN NULL ELSE COALESCE(p_prefix, "Prefix") END,
        "Suffix" = CASE WHEN p_suffix_clear = true THEN NULL ELSE COALESCE(p_suffix, "Suffix") END,
        "PreferredName" = CASE WHEN p_preferredname_clear = true THEN NULL ELSE COALESCE(p_preferredname, "PreferredName") END,
        "Title" = CASE WHEN p_title_clear = true THEN NULL ELSE COALESCE(p_title, "Title") END,
        "Email" = CASE WHEN p_email_clear = true THEN NULL ELSE COALESCE(p_email, "Email") END,
        "Phone" = CASE WHEN p_phone_clear = true THEN NULL ELSE COALESCE(p_phone, "Phone") END,
        "DateOfBirth" = CASE WHEN p_dateofbirth_clear = true THEN NULL ELSE COALESCE(p_dateofbirth, "DateOfBirth") END,
        "Gender" = CASE WHEN p_gender_clear = true THEN NULL ELSE COALESCE(p_gender, "Gender") END,
        "PhotoURL" = CASE WHEN p_photourl_clear = true THEN NULL ELSE COALESCE(p_photourl, "PhotoURL") END,
        "Bio" = CASE WHEN p_bio_clear = true THEN NULL ELSE COALESCE(p_bio, "Bio") END,
        "LinkedUserID" = CASE WHEN p_linkeduserid_clear = true THEN NULL ELSE COALESCE(p_linkeduserid, "LinkedUserID") END,
        "Status" = COALESCE(p_status, "Status"),
        "SeniorityLevelID" = CASE WHEN p_senioritylevelid_clear = true THEN NULL ELSE COALESCE(p_senioritylevelid, "SeniorityLevelID") END
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        -- Nothing was updated, return empty result set
        RETURN;
    END IF;

    -- Return the updated record from the base view
    RETURN QUERY
    SELECT * FROM "__mj_bizappscommon"."vwPeople"
    WHERE "ID" = p_id;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spUpdatePerson" TO "cdp_Developer";
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spUpdatePerson" TO "cdp_Integration";


------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Person table
------------------------------------------------------------
CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."fn_trg_update_person"()
RETURNS TRIGGER AS $$
BEGIN
    NEW."__mj_UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS "trg_update_person" ON "__mj_bizappscommon"."Person";

CREATE TRIGGER "trg_update_person"
BEFORE UPDATE ON "__mj_bizappscommon"."Person"
FOR EACH ROW
EXECUTE FUNCTION "__mj_bizappscommon"."fn_trg_update_person"();



-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: People
-- Item: spDeletePerson

-- ============================================================

------------------------------------------------------------
----- DELETE FUNCTION FOR Person
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spDeletePerson'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spDeletePerson"(
    p_id UUID
) RETURNS TABLE("ID" UUID) AS $$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
BEGIN

    DELETE FROM "__mj_bizappscommon"."Person"
    WHERE "ID" = p_id;

    GET DIAGNOSTICS v_affected_count = ROW_COUNT;

    IF v_affected_count = 0 THEN
        RETURN QUERY SELECT NULL::UUID AS "ID";
    ELSE
        RETURN QUERY SELECT p_id AS "ID";
    END IF;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spDeletePerson" TO "cdp_Integration";

-- ---------- native PostgreSQL CodeGen: MJ_BizApps_Common: Person Job Functions
-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Person Job Functions
-- Item: Index for Foreign Keys

-- ============================================================
CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_person_job_function_person_id"
    ON "__mj_bizappscommon"."PersonJobFunction" ("PersonID");

CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_person_job_function_job_function_id"
    ON "__mj_bizappscommon"."PersonJobFunction" ("JobFunctionID");

-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Person Job Functions
-- Item: vwPersonJobFunctions

-- ============================================================

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Person Job Functions
-----               SCHEMA:      __mj_bizappscommon
-----               BASE TABLE:  PersonJobFunction
-----               PRIMARY KEY: ID
------------------------------------------------------------
DO $vw_regen$
DECLARE
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW "__mj_bizappscommon"."vwPersonJobFunctions"
AS
SELECT
    p.*,
    mjbizappscommonPerson_PersonID."DisplayName" AS "Person",
    mjbizappscommonJobFunction_JobFunctionID."Name" AS "JobFunction"
FROM
    "__mj_bizappscommon"."PersonJobFunction" AS p
INNER JOIN
    "__mj_bizappscommon"."Person" AS mjbizappscommonPerson_PersonID
  ON
    "p"."PersonID" = mjbizappscommonPerson_PersonID."ID"
INNER JOIN
    "__mj_bizappscommon"."JobFunction" AS mjbizappscommonJobFunction_JobFunctionID
  ON
    "p"."JobFunctionID" = mjbizappscommonJobFunction_JobFunctionID."ID"
$vsql$;
  rec RECORD;
BEGIN
  EXECUTE vsql;
EXCEPTION WHEN invalid_table_definition THEN
  -- 42P16: column rename/reorder/type change. CREATE OR REPLACE can't handle
  -- non-additive shape changes — must DROP CASCADE + recreate. CASCADE drops
  -- every dependent view (anything that JOINs this view in its body), so we
  -- capture each dependent's definition + grants BEFORE the drop and replay
  -- them afterward (best-effort). Without this, on a fresh-DB replay where
  -- one entity's wrapper triggers (e.g. vwAIModelTypes shape changed since
  -- baseline V202605021056), CASCADE wipes downstream views (vwAIModels)
  -- that the wrapper for this entity doesn't know how to recreate, and
  -- those views stay permanently missing.
  CREATE TEMP TABLE IF NOT EXISTS _vw_regen_deps (
    schema_name TEXT,
    view_name   TEXT,
    relkind     CHAR(1),
    definition  TEXT,
    grants_sql  TEXT,
    depth       INT
  ) ON COMMIT DROP;
  DELETE FROM _vw_regen_deps;

  -- Every view that DROP ... CASCADE removes: direct dependents AND theirs, transitively.
  -- Capturing only direct dependents restored vwTestRuns after a vwTestSuiteRuns regen but
  -- not vwConversations / vwConversationDetails, which select from vwTestRuns — they and their
  -- CRUD functions stayed permanently missing. depth is the LONGEST path from the target, so
  -- replaying in depth order always recreates a view after every view it reads.
  CREATE TEMP TABLE IF NOT EXISTS _vw_regen_dep_oids (
    view_oid OID,
    depth    INT
  ) ON COMMIT DROP;
  DELETE FROM _vw_regen_dep_oids;
  INSERT INTO _vw_regen_dep_oids (view_oid, depth)
  WITH RECURSIVE deps(view_oid, depth) AS (
      SELECT DISTINCT dc.oid, 1
      FROM pg_depend d
      JOIN pg_rewrite r ON r.oid = d.objid AND d.classid = 'pg_rewrite'::regclass
      JOIN pg_class dc ON dc.oid = r.ev_class AND dc.relkind IN ('v', 'm')
      JOIN pg_class tc ON tc.oid = d.refobjid
      JOIN pg_namespace tn ON tn.oid = tc.relnamespace
      WHERE tn.nspname = '__mj_bizappscommon'
        AND tc.relname = 'vwPersonJobFunctions'
        AND tc.relkind IN ('v', 'm')
        AND dc.oid <> tc.oid
    UNION
      SELECT dc.oid, deps.depth + 1
      FROM deps
      JOIN pg_depend d ON d.refobjid = deps.view_oid
      JOIN pg_rewrite r ON r.oid = d.objid AND d.classid = 'pg_rewrite'::regclass
      JOIN pg_class dc ON dc.oid = r.ev_class AND dc.relkind IN ('v', 'm')
      WHERE dc.oid <> deps.view_oid
        AND deps.depth < 50
  )
  SELECT view_oid, MAX(depth) FROM deps GROUP BY view_oid;

  -- Capture dependent FUNCTIONS too. CASCADE drops every function with
  -- RETURNS SETOF <view> (the codegen-emitted spCreate/spUpdate/spDelete
  -- pattern) when the target view is dropped. Without restoring them,
  -- post-codegen CRUD validation reports those routines as missing —
  -- e.g. "MJ: Recommendation Items → missing create routine
  -- spCreateRecommendationItem" — even though the next codegen pass
  -- emits them. The restored definitions are pg_get_functiondef() output
  -- which is a complete CREATE OR REPLACE FUNCTION statement plus a
  -- trailing semicolon; replaying them verbatim recreates the function
  -- with its original body, parameter list, and return type.
  CREATE TEMP TABLE IF NOT EXISTS _vw_regen_fn_deps (
    schema_name TEXT,
    fn_name     TEXT,
    fn_oid      OID,
    definition  TEXT
  ) ON COMMIT DROP;
  DELETE FROM _vw_regen_fn_deps;

  -- Capture dependents. NOTES on the grants_sql build:
  --   - Resolve role name via pg_get_userbyid(oid) — returns the bare,
  --     unquoted role name (or 'unknown (OID=N)' if the oid no longer
  --     exists). pg_get_userbyid is a public catalog function available to
  --     every database user, including unprivileged accounts on managed
  --     PostgreSQL services (Amazon RDS, Azure Database for PostgreSQL,
  --     Cloud SQL) where pg_authid is restricted to the rds_superuser /
  --     azure_pg_admin / cloudsqlsuperuser group. Earlier revisions joined
  --     to pg_authid which works on self-hosted PG but fails with
  --     "permission denied for table pg_authid" on managed services.
  --   - The earlier (broken) approach cast (aclexplode).grantee::regrole::text
  --     which RETURNS the role name pre-quoted when it contains uppercase
  --     (e.g. cdp_Developer comes back already wrapped); calling quote_ident
  --     on the already-quoted string double-wrapped and the GRANT failed at
  --     replay with "role does not exist". Using
  --     pg_get_userbyid returns a bare name and lets quote_ident wrap it
  --     correctly exactly once.
  --   - PUBLIC is grantee oid 0; pg_get_userbyid(0) returns 'unknown
  --     (OID=0)' so handle the PUBLIC case explicitly and use it as the
  --     literal 'PUBLIC' rather than quote_ident on the synthetic name.
  INSERT INTO _vw_regen_deps (schema_name, view_name, relkind, definition, grants_sql, depth)
  SELECT
      dn.nspname,
      dc.relname,
      dc.relkind,
      pg_get_viewdef(dc.oid),
      (SELECT string_agg(
          'GRANT ' || g.privilege || ' ON ' || quote_ident(dn.nspname) || '.' || quote_ident(dc.relname) ||
          ' TO ' || (CASE WHEN g.grantee_oid = 0 THEN 'PUBLIC' ELSE quote_ident(pg_get_userbyid(g.grantee_oid)) END) || ';',
          E'
')
       FROM (
           SELECT (aclexplode(dc.relacl)).grantee AS grantee_oid,
                  (aclexplode(dc.relacl)).privilege_type AS privilege
       ) g
       WHERE g.privilege IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES', 'TRIGGER')),
      o.depth
  FROM _vw_regen_dep_oids o
  JOIN pg_class dc ON dc.oid = o.view_oid
  JOIN pg_namespace dn ON dn.oid = dc.relnamespace;

  -- Capture dependent functions. Two paths matter on PG:
  --   1. Functions whose RETURN type references the view (RETURNS SETOF
  --      <view>) — pg_depend records this as type=pg_type → pg_class.
  --   2. Functions whose body references the view (used by sql functions
  --      and by some plpgsql edge cases) — pg_depend records this as
  --      pg_proc → pg_class.
  -- pg_get_functiondef returns a complete CREATE OR REPLACE FUNCTION
  -- statement that we replay verbatim. We DO include RETURNS-only
  -- references because that's the dominant codegen pattern (sp* CRUD
  -- functions all RETURNS SETOF the matching vwX).
  -- The set is the target view plus every view captured above, because CASCADE drops the
  -- functions of each of them, not only the target's.
  INSERT INTO _vw_regen_fn_deps (schema_name, fn_name, fn_oid, definition)
  SELECT DISTINCT
      pn.nspname,
      pp.proname,
      pp.oid,
      pg_get_functiondef(pp.oid)
  FROM pg_proc pp
  JOIN pg_namespace pn ON pn.oid = pp.pronamespace
  WHERE pp.prokind IN ('f', 'p')
    AND EXISTS (
      SELECT 1
      FROM pg_class c
      WHERE (c.oid IN (SELECT view_oid FROM _vw_regen_dep_oids)
             OR c.oid = (SELECT tc.oid FROM pg_class tc
                         JOIN pg_namespace tn ON tn.oid = tc.relnamespace
                         WHERE tn.nspname = '__mj_bizappscommon'
                           AND tc.relname = 'vwPersonJobFunctions'
                           AND tc.relkind IN ('v', 'm')))
        AND (pp.prorettype = c.reltype
             OR EXISTS (SELECT 1 FROM pg_depend d
                        WHERE d.classid = 'pg_proc'::regclass
                          AND d.objid = pp.oid
                          AND d.refobjid = c.oid))
  );

  DROP VIEW IF EXISTS "__mj_bizappscommon"."vwPersonJobFunctions" CASCADE;
  EXECUTE vsql;

  -- Replay captured dependents. Best-effort: log + continue on failure.
  -- IMPORTANT: the CREATE VIEW and the GRANTs run in SEPARATE inner BEGIN
  -- blocks. PL/pgSQL's BEGIN ... EXCEPTION creates an implicit savepoint
  -- and rolls back EVERY statement in the block on any exception. If we
  -- combined CREATE+GRANT in one block and a GRANT failed (e.g. role not
  -- present in target environment), the just-recreated VIEW would also
  -- get rolled back and stay missing — the exact failure mode this
  -- wrapper exists to prevent.
  FOR rec IN SELECT schema_name, view_name, relkind, definition, grants_sql FROM _vw_regen_deps ORDER BY depth, view_name LOOP
    BEGIN
      IF rec.relkind = 'm' THEN
        EXECUTE 'CREATE MATERIALIZED VIEW ' || quote_ident(rec.schema_name) || '.' || quote_ident(rec.view_name) || ' AS ' || rec.definition;
      ELSE
        EXECUTE 'CREATE VIEW ' || quote_ident(rec.schema_name) || '.' || quote_ident(rec.view_name) || ' AS ' || rec.definition;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Best-effort restore skipped dependent %.%: %', rec.schema_name, rec.view_name, SQLERRM;
    END;

    IF rec.grants_sql IS NOT NULL THEN
      BEGIN
        EXECUTE rec.grants_sql;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Best-effort grant restore skipped %.%: %', rec.schema_name, rec.view_name, SQLERRM;
      END;
    END IF;
  END LOOP;

  -- Replay captured dependent functions AFTER all dependent views are
  -- restored — most codegen-emitted sp* functions reference both the
  -- target view AND the dependent views in their bodies/return types.
  -- Wrapped per-function in its own savepoint so a single failure
  -- doesn't poison subsequent restores or the just-recreated target.
  FOR rec IN SELECT schema_name, fn_name, definition FROM _vw_regen_fn_deps LOOP
    BEGIN
      EXECUTE rec.definition;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Best-effort restore skipped dependent function %.%: %', rec.schema_name, rec.fn_name, SQLERRM;
    END;
  END LOOP;

  DROP TABLE _vw_regen_deps;
  DROP TABLE _vw_regen_dep_oids;
  DROP TABLE _vw_regen_fn_deps;
END $vw_regen$;
GRANT SELECT ON "__mj_bizappscommon"."vwPersonJobFunctions" TO "cdp_UI";
GRANT SELECT ON "__mj_bizappscommon"."vwPersonJobFunctions" TO "cdp_Developer";
GRANT SELECT ON "__mj_bizappscommon"."vwPersonJobFunctions" TO "cdp_Integration";

-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Person Job Functions
-- Item: spCreatePersonJobFunction

-- ============================================================

------------------------------------------------------------
----- CREATE FUNCTION FOR PersonJobFunction
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spCreatePersonJobFunction'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spCreatePersonJobFunction"(
    p_id UUID DEFAULT NULL,
    p_personid UUID DEFAULT NULL,
    p_jobfunctionid UUID DEFAULT NULL,
    p_sequence int DEFAULT NULL,
    p_source varchar(20) DEFAULT NULL,
    p_confidence_clear boolean DEFAULT false,
    p_confidence decimal(5, 4) DEFAULT NULL
) RETURNS SETOF "__mj_bizappscommon"."vwPersonJobFunctions" AS $$
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO "__mj_bizappscommon"."PersonJobFunction"
        (
            "ID",
            "PersonID",
                "JobFunctionID",
                "Sequence",
                "Source",
                "Confidence"
        )
    VALUES
        (
            v_new_id,
            p_personid,
                p_jobfunctionid,
                COALESCE(p_sequence, 0),
                COALESCE(p_source, 'Manual'),
                CASE WHEN p_confidence_clear = true THEN NULL ELSE COALESCE(p_confidence, NULL) END
        )
    ;

    RETURN QUERY
    SELECT * FROM "__mj_bizappscommon"."vwPersonJobFunctions"
    WHERE "ID" = v_new_id;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spCreatePersonJobFunction" TO "cdp_Developer";
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spCreatePersonJobFunction" TO "cdp_Integration";


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Person Job Functions
-- Item: spUpdatePersonJobFunction

-- ============================================================

------------------------------------------------------------
----- UPDATE FUNCTION FOR PersonJobFunction
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spUpdatePersonJobFunction'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spUpdatePersonJobFunction"(
    p_id UUID,
    p_personid UUID DEFAULT NULL,
    p_jobfunctionid UUID DEFAULT NULL,
    p_sequence int DEFAULT NULL,
    p_source varchar(20) DEFAULT NULL,
    p_confidence_clear boolean DEFAULT false,
    p_confidence decimal(5, 4) DEFAULT NULL
) RETURNS SETOF "__mj_bizappscommon"."vwPersonJobFunctions" AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE "__mj_bizappscommon"."PersonJobFunction"
    SET
        "PersonID" = COALESCE(p_personid, "PersonID"),
        "JobFunctionID" = COALESCE(p_jobfunctionid, "JobFunctionID"),
        "Sequence" = COALESCE(p_sequence, "Sequence"),
        "Source" = COALESCE(p_source, "Source"),
        "Confidence" = CASE WHEN p_confidence_clear = true THEN NULL ELSE COALESCE(p_confidence, "Confidence") END
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        -- Nothing was updated, return empty result set
        RETURN;
    END IF;

    -- Return the updated record from the base view
    RETURN QUERY
    SELECT * FROM "__mj_bizappscommon"."vwPersonJobFunctions"
    WHERE "ID" = p_id;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spUpdatePersonJobFunction" TO "cdp_Developer";
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spUpdatePersonJobFunction" TO "cdp_Integration";


------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the PersonJobFunction table
------------------------------------------------------------
CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."fn_trg_update_person_job_function"()
RETURNS TRIGGER AS $$
BEGIN
    NEW."__mj_UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS "trg_update_person_job_function" ON "__mj_bizappscommon"."PersonJobFunction";

CREATE TRIGGER "trg_update_person_job_function"
BEFORE UPDATE ON "__mj_bizappscommon"."PersonJobFunction"
FOR EACH ROW
EXECUTE FUNCTION "__mj_bizappscommon"."fn_trg_update_person_job_function"();



-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Person Job Functions
-- Item: spDeletePersonJobFunction

-- ============================================================

------------------------------------------------------------
----- DELETE FUNCTION FOR PersonJobFunction
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spDeletePersonJobFunction'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spDeletePersonJobFunction"(
    p_id UUID
) RETURNS TABLE("ID" UUID) AS $$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
BEGIN

    DELETE FROM "__mj_bizappscommon"."PersonJobFunction"
    WHERE "ID" = p_id;

    GET DIAGNOSTICS v_affected_count = ROW_COUNT;

    IF v_affected_count = 0 THEN
        RETURN QUERY SELECT NULL::UUID AS "ID";
    ELSE
        RETURN QUERY SELECT p_id AS "ID";
    END IF;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spDeletePersonJobFunction" TO "cdp_Developer";
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spDeletePersonJobFunction" TO "cdp_Integration";

-- ---------- native PostgreSQL CodeGen: MJ_BizApps_Common: Relationships
-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Relationships
-- Item: Index for Foreign Keys

-- ============================================================
CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_relationship_relationship_type_id"
    ON "__mj_bizappscommon"."Relationship" ("RelationshipTypeID");

CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_relationship_from_person_id"
    ON "__mj_bizappscommon"."Relationship" ("FromPersonID");

CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_relationship_from_organization_id"
    ON "__mj_bizappscommon"."Relationship" ("FromOrganizationID");

CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_relationship_to_person_id"
    ON "__mj_bizappscommon"."Relationship" ("ToPersonID");

CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_relationship_to_organization_id"
    ON "__mj_bizappscommon"."Relationship" ("ToOrganizationID");

CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_relationship_job_function_id"
    ON "__mj_bizappscommon"."Relationship" ("JobFunctionID");

CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_relationship_seniority_level_id"
    ON "__mj_bizappscommon"."Relationship" ("SeniorityLevelID");

-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Relationships
-- Item: vwRelationshipsGenerated

-- ============================================================

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Relationships
-----               SCHEMA:      __mj_bizappscommon
-----               BASE TABLE:  Relationship
-----               PRIMARY KEY: ID
------------------------------------------------------------
DO $vw_regen$
DECLARE
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW "__mj_bizappscommon"."vwRelationshipsGenerated"
AS
SELECT
    r.*,
    mjbizappscommonRelationshipType_RelationshipTypeID."Name" AS "RelationshipType",
    mjbizappscommonPerson_FromPersonID."DisplayName" AS "FromPerson",
    mjbizappscommonOrganization_FromOrganizationID."Name" AS "FromOrganization",
    mjbizappscommonPerson_ToPersonID."DisplayName" AS "ToPerson",
    mjbizappscommonOrganization_ToOrganizationID."Name" AS "ToOrganization",
    mjbizappscommonJobFunction_JobFunctionID."Name" AS "JobFunction",
    mjbizappscommonSeniorityLevel_SeniorityLevelID."Name" AS "SeniorityLevel"
FROM
    "__mj_bizappscommon"."Relationship" AS r
INNER JOIN
    "__mj_bizappscommon"."RelationshipType" AS mjbizappscommonRelationshipType_RelationshipTypeID
  ON
    "r"."RelationshipTypeID" = mjbizappscommonRelationshipType_RelationshipTypeID."ID"
LEFT OUTER JOIN
    "__mj_bizappscommon"."Person" AS mjbizappscommonPerson_FromPersonID
  ON
    "r"."FromPersonID" = mjbizappscommonPerson_FromPersonID."ID"
LEFT OUTER JOIN
    "__mj_bizappscommon"."Organization" AS mjbizappscommonOrganization_FromOrganizationID
  ON
    "r"."FromOrganizationID" = mjbizappscommonOrganization_FromOrganizationID."ID"
LEFT OUTER JOIN
    "__mj_bizappscommon"."Person" AS mjbizappscommonPerson_ToPersonID
  ON
    "r"."ToPersonID" = mjbizappscommonPerson_ToPersonID."ID"
LEFT OUTER JOIN
    "__mj_bizappscommon"."Organization" AS mjbizappscommonOrganization_ToOrganizationID
  ON
    "r"."ToOrganizationID" = mjbizappscommonOrganization_ToOrganizationID."ID"
LEFT OUTER JOIN
    "__mj_bizappscommon"."JobFunction" AS mjbizappscommonJobFunction_JobFunctionID
  ON
    "r"."JobFunctionID" = mjbizappscommonJobFunction_JobFunctionID."ID"
LEFT OUTER JOIN
    "__mj_bizappscommon"."SeniorityLevel" AS mjbizappscommonSeniorityLevel_SeniorityLevelID
  ON
    "r"."SeniorityLevelID" = mjbizappscommonSeniorityLevel_SeniorityLevelID."ID"
$vsql$;
  rec RECORD;
BEGIN
  EXECUTE vsql;
EXCEPTION WHEN invalid_table_definition THEN
  -- 42P16: column rename/reorder/type change. CREATE OR REPLACE can't handle
  -- non-additive shape changes — must DROP CASCADE + recreate. CASCADE drops
  -- every dependent view (anything that JOINs this view in its body), so we
  -- capture each dependent's definition + grants BEFORE the drop and replay
  -- them afterward (best-effort). Without this, on a fresh-DB replay where
  -- one entity's wrapper triggers (e.g. vwAIModelTypes shape changed since
  -- baseline V202605021056), CASCADE wipes downstream views (vwAIModels)
  -- that the wrapper for this entity doesn't know how to recreate, and
  -- those views stay permanently missing.
  CREATE TEMP TABLE IF NOT EXISTS _vw_regen_deps (
    schema_name TEXT,
    view_name   TEXT,
    relkind     CHAR(1),
    definition  TEXT,
    grants_sql  TEXT,
    depth       INT
  ) ON COMMIT DROP;
  DELETE FROM _vw_regen_deps;

  -- Every view that DROP ... CASCADE removes: direct dependents AND theirs, transitively.
  -- Capturing only direct dependents restored vwTestRuns after a vwTestSuiteRuns regen but
  -- not vwConversations / vwConversationDetails, which select from vwTestRuns — they and their
  -- CRUD functions stayed permanently missing. depth is the LONGEST path from the target, so
  -- replaying in depth order always recreates a view after every view it reads.
  CREATE TEMP TABLE IF NOT EXISTS _vw_regen_dep_oids (
    view_oid OID,
    depth    INT
  ) ON COMMIT DROP;
  DELETE FROM _vw_regen_dep_oids;
  INSERT INTO _vw_regen_dep_oids (view_oid, depth)
  WITH RECURSIVE deps(view_oid, depth) AS (
      SELECT DISTINCT dc.oid, 1
      FROM pg_depend d
      JOIN pg_rewrite r ON r.oid = d.objid AND d.classid = 'pg_rewrite'::regclass
      JOIN pg_class dc ON dc.oid = r.ev_class AND dc.relkind IN ('v', 'm')
      JOIN pg_class tc ON tc.oid = d.refobjid
      JOIN pg_namespace tn ON tn.oid = tc.relnamespace
      WHERE tn.nspname = '__mj_bizappscommon'
        AND tc.relname = 'vwRelationshipsGenerated'
        AND tc.relkind IN ('v', 'm')
        AND dc.oid <> tc.oid
    UNION
      SELECT dc.oid, deps.depth + 1
      FROM deps
      JOIN pg_depend d ON d.refobjid = deps.view_oid
      JOIN pg_rewrite r ON r.oid = d.objid AND d.classid = 'pg_rewrite'::regclass
      JOIN pg_class dc ON dc.oid = r.ev_class AND dc.relkind IN ('v', 'm')
      WHERE dc.oid <> deps.view_oid
        AND deps.depth < 50
  )
  SELECT view_oid, MAX(depth) FROM deps GROUP BY view_oid;

  -- Capture dependent FUNCTIONS too. CASCADE drops every function with
  -- RETURNS SETOF <view> (the codegen-emitted spCreate/spUpdate/spDelete
  -- pattern) when the target view is dropped. Without restoring them,
  -- post-codegen CRUD validation reports those routines as missing —
  -- e.g. "MJ: Recommendation Items → missing create routine
  -- spCreateRecommendationItem" — even though the next codegen pass
  -- emits them. The restored definitions are pg_get_functiondef() output
  -- which is a complete CREATE OR REPLACE FUNCTION statement plus a
  -- trailing semicolon; replaying them verbatim recreates the function
  -- with its original body, parameter list, and return type.
  CREATE TEMP TABLE IF NOT EXISTS _vw_regen_fn_deps (
    schema_name TEXT,
    fn_name     TEXT,
    fn_oid      OID,
    definition  TEXT
  ) ON COMMIT DROP;
  DELETE FROM _vw_regen_fn_deps;

  -- Capture dependents. NOTES on the grants_sql build:
  --   - Resolve role name via pg_get_userbyid(oid) — returns the bare,
  --     unquoted role name (or 'unknown (OID=N)' if the oid no longer
  --     exists). pg_get_userbyid is a public catalog function available to
  --     every database user, including unprivileged accounts on managed
  --     PostgreSQL services (Amazon RDS, Azure Database for PostgreSQL,
  --     Cloud SQL) where pg_authid is restricted to the rds_superuser /
  --     azure_pg_admin / cloudsqlsuperuser group. Earlier revisions joined
  --     to pg_authid which works on self-hosted PG but fails with
  --     "permission denied for table pg_authid" on managed services.
  --   - The earlier (broken) approach cast (aclexplode).grantee::regrole::text
  --     which RETURNS the role name pre-quoted when it contains uppercase
  --     (e.g. cdp_Developer comes back already wrapped); calling quote_ident
  --     on the already-quoted string double-wrapped and the GRANT failed at
  --     replay with "role does not exist". Using
  --     pg_get_userbyid returns a bare name and lets quote_ident wrap it
  --     correctly exactly once.
  --   - PUBLIC is grantee oid 0; pg_get_userbyid(0) returns 'unknown
  --     (OID=0)' so handle the PUBLIC case explicitly and use it as the
  --     literal 'PUBLIC' rather than quote_ident on the synthetic name.
  INSERT INTO _vw_regen_deps (schema_name, view_name, relkind, definition, grants_sql, depth)
  SELECT
      dn.nspname,
      dc.relname,
      dc.relkind,
      pg_get_viewdef(dc.oid),
      (SELECT string_agg(
          'GRANT ' || g.privilege || ' ON ' || quote_ident(dn.nspname) || '.' || quote_ident(dc.relname) ||
          ' TO ' || (CASE WHEN g.grantee_oid = 0 THEN 'PUBLIC' ELSE quote_ident(pg_get_userbyid(g.grantee_oid)) END) || ';',
          E'
')
       FROM (
           SELECT (aclexplode(dc.relacl)).grantee AS grantee_oid,
                  (aclexplode(dc.relacl)).privilege_type AS privilege
       ) g
       WHERE g.privilege IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES', 'TRIGGER')),
      o.depth
  FROM _vw_regen_dep_oids o
  JOIN pg_class dc ON dc.oid = o.view_oid
  JOIN pg_namespace dn ON dn.oid = dc.relnamespace;

  -- Capture dependent functions. Two paths matter on PG:
  --   1. Functions whose RETURN type references the view (RETURNS SETOF
  --      <view>) — pg_depend records this as type=pg_type → pg_class.
  --   2. Functions whose body references the view (used by sql functions
  --      and by some plpgsql edge cases) — pg_depend records this as
  --      pg_proc → pg_class.
  -- pg_get_functiondef returns a complete CREATE OR REPLACE FUNCTION
  -- statement that we replay verbatim. We DO include RETURNS-only
  -- references because that's the dominant codegen pattern (sp* CRUD
  -- functions all RETURNS SETOF the matching vwX).
  -- The set is the target view plus every view captured above, because CASCADE drops the
  -- functions of each of them, not only the target's.
  INSERT INTO _vw_regen_fn_deps (schema_name, fn_name, fn_oid, definition)
  SELECT DISTINCT
      pn.nspname,
      pp.proname,
      pp.oid,
      pg_get_functiondef(pp.oid)
  FROM pg_proc pp
  JOIN pg_namespace pn ON pn.oid = pp.pronamespace
  WHERE pp.prokind IN ('f', 'p')
    AND EXISTS (
      SELECT 1
      FROM pg_class c
      WHERE (c.oid IN (SELECT view_oid FROM _vw_regen_dep_oids)
             OR c.oid = (SELECT tc.oid FROM pg_class tc
                         JOIN pg_namespace tn ON tn.oid = tc.relnamespace
                         WHERE tn.nspname = '__mj_bizappscommon'
                           AND tc.relname = 'vwRelationshipsGenerated'
                           AND tc.relkind IN ('v', 'm')))
        AND (pp.prorettype = c.reltype
             OR EXISTS (SELECT 1 FROM pg_depend d
                        WHERE d.classid = 'pg_proc'::regclass
                          AND d.objid = pp.oid
                          AND d.refobjid = c.oid))
  );

  DROP VIEW IF EXISTS "__mj_bizappscommon"."vwRelationshipsGenerated" CASCADE;
  EXECUTE vsql;

  -- Replay captured dependents. Best-effort: log + continue on failure.
  -- IMPORTANT: the CREATE VIEW and the GRANTs run in SEPARATE inner BEGIN
  -- blocks. PL/pgSQL's BEGIN ... EXCEPTION creates an implicit savepoint
  -- and rolls back EVERY statement in the block on any exception. If we
  -- combined CREATE+GRANT in one block and a GRANT failed (e.g. role not
  -- present in target environment), the just-recreated VIEW would also
  -- get rolled back and stay missing — the exact failure mode this
  -- wrapper exists to prevent.
  FOR rec IN SELECT schema_name, view_name, relkind, definition, grants_sql FROM _vw_regen_deps ORDER BY depth, view_name LOOP
    BEGIN
      IF rec.relkind = 'm' THEN
        EXECUTE 'CREATE MATERIALIZED VIEW ' || quote_ident(rec.schema_name) || '.' || quote_ident(rec.view_name) || ' AS ' || rec.definition;
      ELSE
        EXECUTE 'CREATE VIEW ' || quote_ident(rec.schema_name) || '.' || quote_ident(rec.view_name) || ' AS ' || rec.definition;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Best-effort restore skipped dependent %.%: %', rec.schema_name, rec.view_name, SQLERRM;
    END;

    IF rec.grants_sql IS NOT NULL THEN
      BEGIN
        EXECUTE rec.grants_sql;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Best-effort grant restore skipped %.%: %', rec.schema_name, rec.view_name, SQLERRM;
      END;
    END IF;
  END LOOP;

  -- Replay captured dependent functions AFTER all dependent views are
  -- restored — most codegen-emitted sp* functions reference both the
  -- target view AND the dependent views in their bodies/return types.
  -- Wrapped per-function in its own savepoint so a single failure
  -- doesn't poison subsequent restores or the just-recreated target.
  FOR rec IN SELECT schema_name, fn_name, definition FROM _vw_regen_fn_deps LOOP
    BEGIN
      EXECUTE rec.definition;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Best-effort restore skipped dependent function %.%: %', rec.schema_name, rec.fn_name, SQLERRM;
    END;
  END LOOP;

  DROP TABLE _vw_regen_deps;
  DROP TABLE _vw_regen_dep_oids;
  DROP TABLE _vw_regen_fn_deps;
END $vw_regen$;

DO $if_view_exists$
BEGIN
  IF to_regclass('"__mj_bizappscommon"."vwRelationships"') IS NOT NULL THEN
    EXECUTE 'GRANT SELECT ON "__mj_bizappscommon"."vwRelationships" TO "cdp_UI";
GRANT SELECT ON "__mj_bizappscommon"."vwRelationships" TO "cdp_Developer";
GRANT SELECT ON "__mj_bizappscommon"."vwRelationships" TO "cdp_Integration";';
  END IF;
END
$if_view_exists$;


DO $if_view_exists$
BEGIN
  IF to_regclass('"__mj_bizappscommon"."vwRelationships"') IS NOT NULL THEN
    EXECUTE 'SELECT "__mj"."spRebindLayeredOuterView"(''__mj_bizappscommon'', ''vwRelationships'', ''vwRelationshipsGenerated'');';
  END IF;
END
$if_view_exists$;


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Relationships
-- Item: Permissions for vwRelationships

-- ============================================================
DO $if_view_exists$
BEGIN
  IF to_regclass('"__mj_bizappscommon"."vwRelationships"') IS NOT NULL THEN
    EXECUTE 'GRANT SELECT ON "__mj_bizappscommon"."vwRelationships" TO "cdp_UI";
GRANT SELECT ON "__mj_bizappscommon"."vwRelationships" TO "cdp_Developer";
GRANT SELECT ON "__mj_bizappscommon"."vwRelationships" TO "cdp_Integration";';
  END IF;
END
$if_view_exists$;


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Relationships
-- Item: spCreateRelationship

-- ============================================================

------------------------------------------------------------
----- CREATE FUNCTION FOR Relationship
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spCreateRelationship'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spCreateRelationship"(
    p_id UUID DEFAULT NULL,
    p_relationshiptypeid UUID DEFAULT NULL,
    p_frompersonid_clear boolean DEFAULT false,
    p_frompersonid UUID DEFAULT NULL,
    p_fromorganizationid_clear boolean DEFAULT false,
    p_fromorganizationid UUID DEFAULT NULL,
    p_topersonid_clear boolean DEFAULT false,
    p_topersonid UUID DEFAULT NULL,
    p_toorganizationid_clear boolean DEFAULT false,
    p_toorganizationid UUID DEFAULT NULL,
    p_title_clear boolean DEFAULT false,
    p_title varchar(255) DEFAULT NULL,
    p_startdate_clear boolean DEFAULT false,
    p_startdate date DEFAULT NULL,
    p_enddate_clear boolean DEFAULT false,
    p_enddate date DEFAULT NULL,
    p_status varchar(50) DEFAULT NULL,
    p_notes_clear boolean DEFAULT false,
    p_notes TEXT DEFAULT NULL,
    p_jobfunctionid_clear boolean DEFAULT false,
    p_jobfunctionid UUID DEFAULT NULL,
    p_senioritylevelid_clear boolean DEFAULT false,
    p_senioritylevelid UUID DEFAULT NULL
) RETURNS SETOF "__mj_bizappscommon"."vwRelationships" AS $$
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO "__mj_bizappscommon"."Relationship"
        (
            "ID",
            "RelationshipTypeID",
                "FromPersonID",
                "FromOrganizationID",
                "ToPersonID",
                "ToOrganizationID",
                "Title",
                "StartDate",
                "EndDate",
                "Status",
                "Notes",
                "JobFunctionID",
                "SeniorityLevelID"
        )
    VALUES
        (
            v_new_id,
            p_relationshiptypeid,
                CASE WHEN p_frompersonid_clear = true THEN NULL ELSE COALESCE(p_frompersonid, NULL) END,
                CASE WHEN p_fromorganizationid_clear = true THEN NULL ELSE COALESCE(p_fromorganizationid, NULL) END,
                CASE WHEN p_topersonid_clear = true THEN NULL ELSE COALESCE(p_topersonid, NULL) END,
                CASE WHEN p_toorganizationid_clear = true THEN NULL ELSE COALESCE(p_toorganizationid, NULL) END,
                CASE WHEN p_title_clear = true THEN NULL ELSE COALESCE(p_title, NULL) END,
                CASE WHEN p_startdate_clear = true THEN NULL ELSE COALESCE(p_startdate, NULL) END,
                CASE WHEN p_enddate_clear = true THEN NULL ELSE COALESCE(p_enddate, NULL) END,
                COALESCE(p_status, 'Active'),
                CASE WHEN p_notes_clear = true THEN NULL ELSE COALESCE(p_notes, NULL) END,
                CASE WHEN p_jobfunctionid_clear = true THEN NULL ELSE COALESCE(p_jobfunctionid, NULL) END,
                CASE WHEN p_senioritylevelid_clear = true THEN NULL ELSE COALESCE(p_senioritylevelid, NULL) END
        )
    ;

    RETURN QUERY
    SELECT * FROM "__mj_bizappscommon"."vwRelationships"
    WHERE "ID" = v_new_id;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spCreateRelationship" TO "cdp_Developer";
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spCreateRelationship" TO "cdp_Integration";


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Relationships
-- Item: spUpdateRelationship

-- ============================================================

------------------------------------------------------------
----- UPDATE FUNCTION FOR Relationship
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spUpdateRelationship'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spUpdateRelationship"(
    p_id UUID,
    p_relationshiptypeid UUID DEFAULT NULL,
    p_frompersonid_clear boolean DEFAULT false,
    p_frompersonid UUID DEFAULT NULL,
    p_fromorganizationid_clear boolean DEFAULT false,
    p_fromorganizationid UUID DEFAULT NULL,
    p_topersonid_clear boolean DEFAULT false,
    p_topersonid UUID DEFAULT NULL,
    p_toorganizationid_clear boolean DEFAULT false,
    p_toorganizationid UUID DEFAULT NULL,
    p_title_clear boolean DEFAULT false,
    p_title varchar(255) DEFAULT NULL,
    p_startdate_clear boolean DEFAULT false,
    p_startdate date DEFAULT NULL,
    p_enddate_clear boolean DEFAULT false,
    p_enddate date DEFAULT NULL,
    p_status varchar(50) DEFAULT NULL,
    p_notes_clear boolean DEFAULT false,
    p_notes TEXT DEFAULT NULL,
    p_jobfunctionid_clear boolean DEFAULT false,
    p_jobfunctionid UUID DEFAULT NULL,
    p_senioritylevelid_clear boolean DEFAULT false,
    p_senioritylevelid UUID DEFAULT NULL
) RETURNS SETOF "__mj_bizappscommon"."vwRelationships" AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE "__mj_bizappscommon"."Relationship"
    SET
        "RelationshipTypeID" = COALESCE(p_relationshiptypeid, "RelationshipTypeID"),
        "FromPersonID" = CASE WHEN p_frompersonid_clear = true THEN NULL ELSE COALESCE(p_frompersonid, "FromPersonID") END,
        "FromOrganizationID" = CASE WHEN p_fromorganizationid_clear = true THEN NULL ELSE COALESCE(p_fromorganizationid, "FromOrganizationID") END,
        "ToPersonID" = CASE WHEN p_topersonid_clear = true THEN NULL ELSE COALESCE(p_topersonid, "ToPersonID") END,
        "ToOrganizationID" = CASE WHEN p_toorganizationid_clear = true THEN NULL ELSE COALESCE(p_toorganizationid, "ToOrganizationID") END,
        "Title" = CASE WHEN p_title_clear = true THEN NULL ELSE COALESCE(p_title, "Title") END,
        "StartDate" = CASE WHEN p_startdate_clear = true THEN NULL ELSE COALESCE(p_startdate, "StartDate") END,
        "EndDate" = CASE WHEN p_enddate_clear = true THEN NULL ELSE COALESCE(p_enddate, "EndDate") END,
        "Status" = COALESCE(p_status, "Status"),
        "Notes" = CASE WHEN p_notes_clear = true THEN NULL ELSE COALESCE(p_notes, "Notes") END,
        "JobFunctionID" = CASE WHEN p_jobfunctionid_clear = true THEN NULL ELSE COALESCE(p_jobfunctionid, "JobFunctionID") END,
        "SeniorityLevelID" = CASE WHEN p_senioritylevelid_clear = true THEN NULL ELSE COALESCE(p_senioritylevelid, "SeniorityLevelID") END
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        -- Nothing was updated, return empty result set
        RETURN;
    END IF;

    -- Return the updated record from the base view
    RETURN QUERY
    SELECT * FROM "__mj_bizappscommon"."vwRelationships"
    WHERE "ID" = p_id;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spUpdateRelationship" TO "cdp_Developer";
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spUpdateRelationship" TO "cdp_Integration";


------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Relationship table
------------------------------------------------------------
CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."fn_trg_update_relationship"()
RETURNS TRIGGER AS $$
BEGIN
    NEW."__mj_UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS "trg_update_relationship" ON "__mj_bizappscommon"."Relationship";

CREATE TRIGGER "trg_update_relationship"
BEFORE UPDATE ON "__mj_bizappscommon"."Relationship"
FOR EACH ROW
EXECUTE FUNCTION "__mj_bizappscommon"."fn_trg_update_relationship"();



-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Relationships
-- Item: spDeleteRelationship

-- ============================================================

------------------------------------------------------------
----- DELETE FUNCTION FOR Relationship
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spDeleteRelationship'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spDeleteRelationship"(
    p_id UUID
) RETURNS TABLE("ID" UUID) AS $$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
BEGIN

    DELETE FROM "__mj_bizappscommon"."Relationship"
    WHERE "ID" = p_id;

    GET DIAGNOSTICS v_affected_count = ROW_COUNT;

    IF v_affected_count = 0 THEN
        RETURN QUERY SELECT NULL::UUID AS "ID";
    ELSE
        RETURN QUERY SELECT p_id AS "ID";
    END IF;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spDeleteRelationship" TO "cdp_Integration";
