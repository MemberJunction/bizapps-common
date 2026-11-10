-- =============================================================================================
-- PostgreSQL counterpart of V202610280946__v5.57.x__Organization_Acronym.sql
-- =============================================================================================
-- `mj sql-convert --from tsql --to postgres` (MJ CLI 6.1.6) output, finished by hand:
--   * Tables, columns, constraints, indexes, views, data and grants are the converter's.
--   * CodeGen's CRUD procedures (spCreate/spUpdate/spDelete), its __mj_UpdatedAt triggers and any
--     hierarchy functions are NOT here: the converter cannot translate T-SQL procedures, triggers
--     or table-valued functions. A PostgreSQL host runs `mj codegen` after installing, which
--     generates them natively. The converter's notes for them remain, fully commented out.
--   * 1 view-rebuild block(s): the target schema lowercased, so the dependent-view rebuild
--     finds the view when its column list changes.
--   * CodeGen's hierarchy functions are left to `mj codegen` as well; the converter's output
--     is kept, commented out.
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
-- Migration: V202610280946__v5.57.x__Organization_Acronym.sql
-- Description: Add Organization.Acronym, indexed for the party lookup's prefix search.
--
-- WHY. Users know many organizations by an acronym (a trade association by its initials,
-- for example). Pickers must find an organization by it, and show it under the name so two
-- organizations with the same acronym can be told apart. Data converted from a prior CRM
-- carries the acronym in a 20-character column, so the width matches it.
--
-- The index serves "Acronym LIKE 'term%'" in the party lookup queries (prefix seek, no scan).
-- =============================================================================
ALTER TABLE __mj_BizAppsCommon."Organization"
 ADD COLUMN IF NOT EXISTS "Acronym" VARCHAR(20) NULL;

CREATE INDEX IF NOT EXISTS "IX_Organization_Acronym"
    ON __mj_BizAppsCommon."Organization" ("Acronym");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Organization_OrganizationTypeID" ON __mj_BizAppsCommon."Organization" ("OrganizationTypeID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Organization_ParentID" ON __mj_BizAppsCommon."Organization" ("ParentID");


-- ===================== Helper Functions (fn*) =====================
-- CodeGen's hierarchy functions. The converter cannot translate T-SQL table-valued functions;
-- `mj codegen` generates them natively on a PostgreSQL host. The converter's output is kept
-- below, commented out.

-- CREATE FUNCTION __mj_BizAppsCommon."fnOrganizationParentID_GetHierarchyMeta"
-- (
--     p_RecordID UUID,
--     p_ParentID UUID
-- )
-- RETURNS TABLE
-- AS
-- RETURN
-- (
--     WITH CTE_Ancestors AS (
--         SELECT
--             "ID",
--             "ParentID",
--             0 AS "Depth",
--             CAST('/' || CAST("ID" AS VARCHAR(36)) || '/' AS TEXT) AS "Path"
--         FROM
--             __mj_BizAppsCommon."Organization"
--         WHERE
--             "ID" = p_RecordID

--         UNION ALL

--         SELECT
--             p."ID",
--             p."ParentID",
--             c."Depth" + 1 AS "Depth",
--             CAST('/' || CAST(p."ID" AS VARCHAR(36)) || c."Path" AS TEXT) AS "Path"
--         FROM
--             __mj_BizAppsCommon."Organization" p
--         INNER JOIN
--             CTE_Ancestors c ON p."ID" = c."ParentID"
--         WHERE
--             c."Depth" < 100
--     )
--     SELECT         a."ID" AS "RootID",
--         (SELECT MAX("Depth") FROM CTE_Ancestors) AS "Depth",
--         (SELECT "Path" FROM CTE_Ancestors ORDER BY "Depth" DESC
-- LIMIT 1) AS "Path",
--         CAST(CASE WHEN EXISTS (SELECT 1 FROM __mj_BizAppsCommon."Organization" WHERE "ParentID" = p_RecordID) THEN 0 ELSE 1 END AS BOOLEAN) AS "IsLeaf",
--         (SELECT COUNT(1) FROM __mj_BizAppsCommon."Organization" WHERE "ParentID" = p_RecordID) AS "ChildCount"
--     FROM
--         CTE_Ancestors a
--     WHERE
--         a."ParentID" IS NULL OR p_ParentID IS NULL
--     ORDER BY
--         a."Depth" DESC

-- LIMIT 1);

-- CREATE FUNCTION __mj_BizAppsCommon."fnOrganizationParentID_GetDescendants"
-- (
--     p_RootID UUID,
--     p_MaxDepth INTEGER = NULL
-- )
-- RETURNS TABLE
-- AS
-- RETURN
-- (
--     WITH CTE_Descendants AS (
--         SELECT
--             "ID",
--             "ParentID",
--             0 AS "RelativeDepth",
--             CAST('/' || CAST("ID" AS VARCHAR(36)) || '/' AS TEXT) AS "Path"
--         FROM
--             __mj_BizAppsCommon."Organization"
--         WHERE
--             "ID" = p_RootID

--         UNION ALL

--         SELECT
--             c."ID",
--             c."ParentID",
--             p."RelativeDepth" || 1 AS "RelativeDepth",
--             CAST(p."Path" || CAST(c."ID" AS VARCHAR(36)) || '/' AS TEXT) AS "Path"
--         FROM
--             __mj_BizAppsCommon."Organization" c
--         INNER JOIN
--             CTE_Descendants p ON c."ParentID" = p."ID"
--         WHERE
--             (p_MaxDepth IS NULL OR p."RelativeDepth" < p_MaxDepth)
--             AND p."RelativeDepth" < 100
--     )
--     SELECT
--         d."ID" AS "ID",
--         d."RelativeDepth" AS "Depth",
--         d."Path",
--         CAST(CASE WHEN EXISTS (SELECT 1 FROM __mj_BizAppsCommon."Organization" WHERE "ParentID" = d."ID") THEN 0 ELSE 1 END AS BOOLEAN) AS "IsLeaf",
--         (SELECT COUNT(1) FROM __mj_BizAppsCommon."Organization" WHERE "ParentID" = d."ID") AS "ChildCount"
--     FROM
--         CTE_Descendants d
-- );

-- CREATE FUNCTION __mj_BizAppsCommon."fnOrganizationParentID_GetAncestors"
-- (
--     p_RecordID UUID
-- )
-- RETURNS TABLE
-- AS
-- RETURN
-- (
--     WITH CTE_Ancestors AS (
--         SELECT
--             "ID",
--             "ParentID",
--             0 AS "LevelUp",
--             CAST('/' || CAST("ID" AS VARCHAR(36)) || '/' AS TEXT) AS "Path"
--         FROM
--             __mj_BizAppsCommon."Organization"
--         WHERE
--             "ID" = p_RecordID

--         UNION ALL

--         SELECT
--             p."ID",
--             p."ParentID",
--             c."LevelUp" + 1 AS "LevelUp",
--             CAST('/' || CAST(p."ID" AS VARCHAR(36)) || c."Path" AS TEXT) AS "Path"
--         FROM
--             __mj_BizAppsCommon."Organization" p
--         INNER JOIN
--             CTE_Ancestors c ON p."ID" = c."ParentID"
--         WHERE
--             c."LevelUp" < 100
--     )
--     SELECT
--         a."ID" AS "ID",
--         a."LevelUp",
--         a."Path"
--     FROM
--         CTE_Ancestors a
-- );

-- CREATE FUNCTION __mj_BizAppsCommon."fnOrganizationParentID_GetRootID"
-- (
--     p_RecordID UUID,
--     p_ParentID UUID
-- )
-- RETURNS TABLE
-- AS
-- RETURN
-- (
--     WITH CTE_RootParent AS (
--         SELECT
--             "ID",
--             "ParentID",
--             "ID" AS "RootParentID",
--             0 AS "Depth"
--         FROM
--             __mj_BizAppsCommon."Organization"
--         WHERE
--             "ID" = COALESCE(p_ParentID, p_RecordID)

--         UNION ALL

--         SELECT
--             c."ID",
--             c."ParentID",
--             c."ID" AS "RootParentID",
--             p."Depth" + 1 AS "Depth"
--         FROM
--             __mj_BizAppsCommon."Organization" c
--         INNER JOIN
--             CTE_RootParent p ON c."ID" = p."ParentID"
--         WHERE
--             p."Depth" < 100
--     )
--     SELECT         "RootParentID" AS RootID
--     FROM
--         CTE_RootParent
--     WHERE
--         "ParentID" IS NULL
--     ORDER BY
--         "RootParentID"

-- LIMIT 1);


-- ===================== Views =====================

DO $do$
DECLARE
  v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
  v_target_name CONSTANT TEXT := 'vwOrganizationsGenerated';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwOrganizationsGenerated"
AS SELECT
    o.*,
    "mjBizAppsCommonOrganizationType_OrganizationTypeID"."Name" AS "OrganizationType",
    "mjBizAppsCommonOrganization_ParentID"."Name" AS "Parent",
    "hier_ParentID"."RootID" AS "RootParentID",
    "hier_ParentID"."Depth" AS "ParentIDDepth",
    "hier_ParentID"."Path" AS "ParentIDPath",
    "hier_ParentID"."IsLeaf" AS "ParentIDIsLeaf",
    "hier_ParentID"."ChildCount" AS "ParentIDChildCount"
FROM
    __mj_BizAppsCommon."Organization" AS o
LEFT OUTER JOIN
    __mj_BizAppsCommon."OrganizationType" AS "mjBizAppsCommonOrganizationType_OrganizationTypeID"
  ON
    o."OrganizationTypeID" = "mjBizAppsCommonOrganizationType_OrganizationTypeID"."ID"
LEFT OUTER JOIN
    __mj_BizAppsCommon."Organization" AS "mjBizAppsCommonOrganization_ParentID"
  ON
    o."ParentID" = "mjBizAppsCommonOrganization_ParentID"."ID"
LEFT JOIN LATERAL (SELECT * FROM __mj_BizAppsCommon."fnOrganizationParentID_GetHierarchyMeta"(o."ID", o."ParentID")) AS "hier_ParentID"
    ON TRUE$vsql$;
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
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spCreateOrganization]
--     @ID UUID = NULL,
--     @Name VARCHAR(255),
--     @LegalName_Clear bit = 0,
--     @LegalName VARCHAR(255) = NULL,
--     @Organizat...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spUpdateOrganization]
--     @ID UUID,
--     @Name VARCHAR(255) = NULL,
--     @LegalName_Clear bit = 0,
--     @LegalName VARCHAR(255) = NULL,
--     @Organizat...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spDeleteOrganization]
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         [__mj_BizAppsCommon].[Organization]
--     WHERE
--         [ID] =...


-- ===================== Triggers =====================

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_BizAppsCommon].trgUpdateOrganization
-- ON "__mj_BizAppsCommon"."Organization"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         "__mj_BizAppsCommon"."Organization"
--     SE


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = '72fb8c84-f602-4d27-ab5d-7820998c97f7' OR ("EntityID" = 'C70448F9-9792-41D7-A82C-784B66429D54' AND "Name" = 'Acronym')
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
        '72fb8c84-f602-4d27-ab5d-7820998c97f7',
        'C70448F9-9792-41D7-A82C-784B66429D54', -- "Entity": "MJ_BizApps_Common": "Organizations"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = 'C70448F9-9792-41D7-A82C-784B66429D54'),
        'Acronym',
        'Acronym',
        'Short name or initials the organization is commonly known by. Searched by the organization pickers as a starts-with match and shown under the name.',
        'TEXT',
        40,
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

UPDATE __mj."EntityField"
               SET "DefaultInView" = TRUE
               WHERE "ID" = '72FB8C84-F602-4D27-AB5D-7820998C97F7'
               AND "AutoUpdateDefaultInView" = TRUE;

UPDATE __mj."EntityField"
               SET "IncludeInUserSearchAPI" = TRUE
               WHERE "ID" = '72FB8C84-F602-4D27-AB5D-7820998C97F7'
               AND "AutoUpdateIncludeInUserSearchAPI" = TRUE;

UPDATE __mj."EntityField"
               SET "UserSearchPredicateAPI" = 'BeginsWith'
               WHERE "ID" = '72FB8C84-F602-4D27-AB5D-7820998C97F7'
               AND "AutoUpdateUserSearchPredicate" = TRUE;

/* Set categories for 1 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Organizations.Acronym

UPDATE __mj."EntityField"
SET 
   "Category" = 'Organization Identity',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '72FB8C84-F602-4D27-AB5D-7820998C97F7';

/* Refresh custom base views for modified entities so schema changes are picked up */


-- ===================== Grants =====================

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateOrganization" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateOrganization" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateOrganization" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Organizations */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateOrganization" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateOrganization" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateOrganization" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: spUpdateOrganization
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Organization
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateOrganization" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateOrganization" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateOrganization" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateOrganization" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateOrganization" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateOrganization" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: spDeleteOrganization
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Organization
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteOrganization" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteOrganization" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Organizations */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteOrganization" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteOrganization" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Set field properties for entity */


-- ===================== Comments =====================

COMMENT ON COLUMN __mj_BizAppsCommon."Organization"."Acronym" IS 'Short name or initials the organization is commonly known by. Searched by the organization pickers as a starts-with match and shown under the name.';


-- ===================== Other =====================

/* ============================================================================================
   ==== CODEGEN OUTPUT — DO NOT EDIT BELOW THIS LINE ====
   Generated by the MemberJunction CodeGen tool: published @memberjunction/cli 6.1.6 (this repo's
   floor), includeSchemas ['__mj_BizAppsCommon'], against a database built from migrations alone
   (MJ core v6.1.6, then this repo's chain at origin/next, then the DDL above).
   Contains: the Organization.Acronym EntityField insert, its search and category settings, and
   the regenerated vwOrganizationsGenerated, Organization CRUD procs, hierarchy TVFs and FK
   indexes that regenerate with them.
   The field's description comes from MS_Description above; its search settings and form section
   are pinned in metadata/ (they reach hosts in the release seed).
   Do NOT edit by hand. If the hand-written SQL above changes, re-run CodeGen and replace this
   whole section.
   ============================================================================================ */
/* SQL text to insert 1 new entity field(s) */

/* spUpdate Permissions for MJ_BizApps_Common: Organizations */
