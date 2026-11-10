-- =============================================================================================
-- PostgreSQL counterpart of V202610151047__v5.54.x__Relationship_Layered_Base_View_Metadata.sql
-- =============================================================================================
-- `mj sql-convert --from tsql --to postgres` (MJ CLI 6.1.5) output, finished by hand:
--   * Tables, columns, constraints, indexes, views, data and grants are the converter's.
--   * CodeGen's CRUD procedures (spCreate/spUpdate/spDelete), its __mj_UpdatedAt triggers and any
--     hierarchy functions are NOT here: the converter cannot translate T-SQL procedures, triggers
--     or table-valued functions. A PostgreSQL host runs `mj codegen` after installing, which
--     generates them natively. The converter's notes for them remain, fully commented out.
--   * 1 view-rebuild block(s): the target schema lowercased, so the dependent-view rebuild
--     finds the view when its column list changes.
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
-- CREATE TRIGGER [__mj_BizAppsCommon].trgUpdateRelationship
-- ON "__mj_BizAppsCommon"."Relationship"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         "__mj_BizAppsCommon"."Relationship"
--     SE


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

-- =============================================================================
-- Layered base view for Relationships — PART 1 of 2 (metadata + CodeGen)
-- =============================================================================
--
-- WHY. The Relationships name field was Title: nullable, and a job title. "CEO" does
-- not say who is related to whom, and most relationships (Spouse, Member, Vendor) have
-- no title at all, so they showed up blank in pickers and FK labels. The useful label is
-- "<From> → <To> (<Type>)": "Jane Smith → Acme (Employee)". That needs names from
-- Person, Organization and RelationshipType, so it cannot be a PERSISTED computed column
-- on Relationship; it is a column of the base view, and the name field points at it.
--
-- WHY LAYERED. vwRelationships is CodeGen-generated. Same move as People and
-- Organizations in V202608132239/V202608132240: CodeGen keeps generating everything
-- mechanical under GeneratedBaseViewName (vwRelationshipsGenerated), and PART 2 owns
-- BaseView as a thin wrapper that adds DisplayName. BaseViewGenerated must be 0 for a
-- layered view — a CHECK constraint enforces that the two settings agree.
--
-- WHY TWO FILES. PART 2's wrapper SELECTs from vwRelationshipsGenerated, which the
-- CodeGen section below creates; SQL Server has no deferred name resolution for views.
--
-- WHY THE METADATA IS SQL HERE. The Open App installer applies migrations, not
-- metadata/. The flip is also in metadata/entities/.entities.json for `mj sync push`.
-- The IsNameField change ships through metadata/ and the release seed, like Person's.
-- =============================================================================

UPDATE __mj."Entity"
   SET "BaseViewGenerated" = FALSE,
       "GeneratedBaseViewName"  = 'vwRelationshipsGenerated'
 WHERE "ID" = '709CA9DA-B124-4155-BE39-E857EF672D82';  -- MJ_BizApps_Common: Relationships;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = 'a4bbbc1d-aadc-48bb-ae3e-751e270f397c' OR ("EntityID" = '709CA9DA-B124-4155-BE39-E857EF672D82' AND "Name" = 'DisplayName')
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
        'a4bbbc1d-aadc-48bb-ae3e-751e270f397c',
        '709CA9DA-B124-4155-BE39-E857EF672D82', -- "Entity": "MJ_BizApps_Common": "Relationships"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '709CA9DA-B124-4155-BE39-E857EF672D82'),
        'DisplayName',
        'Display Name',
        NULL,
        'TEXT',
        2000,
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

UPDATE __mj."EntityField"
               SET "DefaultInView" = TRUE
               WHERE "ID" = 'A4BBBC1D-AADC-48BB-AE3E-751E270F397C'
               AND "AutoUpdateDefaultInView" = TRUE;

/* Set categories for 1 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Relationships.DisplayName

UPDATE __mj."EntityField"
SET 
   "Category" = 'Relationship Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = 'A4BBBC1D-AADC-48BB-AE3E-751E270F397C';

/* Refresh custom base views for modified entities so schema changes are picked up */


-- ===================== Grants =====================

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

/* ============================================================================================
   ==== CODEGEN OUTPUT — DO NOT EDIT BELOW THIS LINE ====
   Generated by the MemberJunction CodeGen tool: MJ CLI 6.2.0-edge.3 / CodeGenLib from MJ `next`
   @ d96fee72d7, includeSchemas ['__mj_BizAppsCommon'], against a database built from migrations
   with metadata/ pushed first (so CHECK validators come from the pinned GeneratedCode rows).
   Contains: the Relationships.DisplayName EntityField insert (IsVirtual — the column lives on the PART 2
   wrapper), vwRelationshipsGenerated, its permissions, Relationship CRUD procs, field settings,
   and a guarded refresh of the wrapper. Authored with the PART 2 wrapper already applied.
   Do NOT edit by hand. If the hand-written SQL above changes, re-run CodeGen and replace this
   whole section.
   Runs: one, after the flip above and the PART 2 wrapper.
   ============================================================================================ */

/* SQL text to insert 1 new entity field(s) */

/* spUpdate Permissions for MJ_BizApps_Common: Relationships */

-- =============================================================================
-- Native PostgreSQL CodeGen for the procedures and triggers the conversion above skipped
-- (Relationship).
-- =============================================================================
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
