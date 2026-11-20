-- =============================================================================================
-- PostgreSQL counterpart of V202610151046__v5.54.x__Address_DisplayName.sql
-- =============================================================================================
-- `mj sql-convert --from tsql --to postgres` (MJ CLI 6.1.5) output, finished by hand:
--   * Tables, columns, constraints, indexes, views, data and grants are the converter's.
--   * CodeGen's CRUD procedures (spCreate/spUpdate/spDelete), its __mj_UpdatedAt triggers and any
--     hierarchy functions are NOT here: the converter cannot translate T-SQL procedures, triggers
--     or table-valued functions. A PostgreSQL host runs `mj codegen` after installing, which
--     generates them natively. The converter's notes for them remain, fully commented out.
--   * IF COL_LENGTH('[__mj_BizAppsCommon].[Address]', 'DisplayName') IS NULL: written by hand in PL/pgSQL from this migration's T-SQL.
--   * 5 view-rebuild block(s): the target schema lowercased, so the dependent-view rebuild
--     finds the view when its column list changes.
--   * 1 column description(s) the converter left calling SQL Server's sp_addextendedproperty
--     written as COMMENT ON COLUMN.
--   * CodeGen's hierarchy functions are left to `mj codegen` as well; the converter's output
--     is kept, commented out.
--   * 4 statements the converter drops (CodeGen's name-field map updates, column
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

CREATE INDEX IF NOT EXISTS "IX_Address_DisplayName" ON __mj_BizAppsCommon."Address" ("DisplayName");

COMMENT ON COLUMN __mj_BizAppsCommon."Address"."DisplayName" IS 'One-line label for the address in US order: Line1, City, State PostalCode, Country. Blank parts are skipped; NULL when every part is blank. Computed and stored; this is the entity name field.';

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Activity_ActivityTypeID" ON __mj_BizAppsCommon."Activity" ("ActivityTypeID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Activity_ParentActivityID" ON __mj_BizAppsCommon."Activity" ("ParentActivityID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Activity_LoggedByUserID" ON __mj_BizAppsCommon."Activity" ("LoggedByUserID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Activity_AddressID" ON __mj_BizAppsCommon."Activity" ("AddressID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Activity_ActivitySyncConnectionID" ON __mj_BizAppsCommon."Activity" ("ActivitySyncConnectionID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_AddressLink_AddressID" ON __mj_BizAppsCommon."AddressLink" ("AddressID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_AddressLink_EntityID" ON __mj_BizAppsCommon."AddressLink" ("EntityID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_AddressLink_AddressTypeID" ON __mj_BizAppsCommon."AddressLink" ("AddressTypeID");


-- ===================== Helper Functions (fn*) =====================
-- CodeGen's hierarchy functions. The converter cannot translate T-SQL table-valued functions;
-- `mj codegen` generates them natively on a PostgreSQL host. The converter's output is kept
-- below, commented out.

-- CREATE FUNCTION __mj_BizAppsCommon."fnActivityParentActivityID_GetHierarchyMeta"
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
--             "ParentActivityID",
--             0 AS "Depth",
--             CAST('/' || CAST("ID" AS VARCHAR(36)) || '/' AS TEXT) AS "Path"
--         FROM
--             __mj_BizAppsCommon."Activity"
--         WHERE
--             "ID" = p_RecordID

--         UNION ALL

--         SELECT
--             p."ID",
--             p."ParentActivityID",
--             c."Depth" + 1 AS "Depth",
--             CAST('/' || CAST(p."ID" AS VARCHAR(36)) || c."Path" AS TEXT) AS "Path"
--         FROM
--             __mj_BizAppsCommon."Activity" p
--         INNER JOIN
--             CTE_Ancestors c ON p."ID" = c."ParentActivityID"
--         WHERE
--             c."Depth" < 100
--     )
--     SELECT         a."ID" AS "RootID",
--         (SELECT MAX("Depth") FROM CTE_Ancestors) AS "Depth",
--         (SELECT "Path" FROM CTE_Ancestors ORDER BY "Depth" DESC
-- LIMIT 1) AS "Path",
--         CAST(CASE WHEN EXISTS (SELECT 1 FROM __mj_BizAppsCommon."Activity" WHERE "ParentActivityID" = p_RecordID) THEN 0 ELSE 1 END AS BOOLEAN) AS "IsLeaf",
--         (SELECT COUNT(1) FROM __mj_BizAppsCommon."Activity" WHERE "ParentActivityID" = p_RecordID) AS "ChildCount"
--     FROM
--         CTE_Ancestors a
--     WHERE
--         a."ParentActivityID" IS NULL OR p_ParentID IS NULL
--     ORDER BY
--         a."Depth" DESC

-- LIMIT 1);

-- CREATE FUNCTION __mj_BizAppsCommon."fnActivityParentActivityID_GetDescendants"
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
--             "ParentActivityID",
--             0 AS "RelativeDepth",
--             CAST('/' || CAST("ID" AS VARCHAR(36)) || '/' AS TEXT) AS "Path"
--         FROM
--             __mj_BizAppsCommon."Activity"
--         WHERE
--             "ID" = p_RootID

--         UNION ALL

--         SELECT
--             c."ID",
--             c."ParentActivityID",
--             p."RelativeDepth" || 1 AS "RelativeDepth",
--             CAST(p."Path" || CAST(c."ID" AS VARCHAR(36)) || '/' AS TEXT) AS "Path"
--         FROM
--             __mj_BizAppsCommon."Activity" c
--         INNER JOIN
--             CTE_Descendants p ON c."ParentActivityID" = p."ID"
--         WHERE
--             (p_MaxDepth IS NULL OR p."RelativeDepth" < p_MaxDepth)
--             AND p."RelativeDepth" < 100
--     )
--     SELECT
--         d."ID" AS "ID",
--         d."RelativeDepth" AS "Depth",
--         d."Path",
--         CAST(CASE WHEN EXISTS (SELECT 1 FROM __mj_BizAppsCommon."Activity" WHERE "ParentActivityID" = d."ID") THEN 0 ELSE 1 END AS BOOLEAN) AS "IsLeaf",
--         (SELECT COUNT(1) FROM __mj_BizAppsCommon."Activity" WHERE "ParentActivityID" = d."ID") AS "ChildCount"
--     FROM
--         CTE_Descendants d
-- );

-- CREATE FUNCTION __mj_BizAppsCommon."fnActivityParentActivityID_GetAncestors"
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
--             "ParentActivityID",
--             0 AS "LevelUp",
--             CAST('/' || CAST("ID" AS VARCHAR(36)) || '/' AS TEXT) AS "Path"
--         FROM
--             __mj_BizAppsCommon."Activity"
--         WHERE
--             "ID" = p_RecordID

--         UNION ALL

--         SELECT
--             p."ID",
--             p."ParentActivityID",
--             c."LevelUp" + 1 AS "LevelUp",
--             CAST('/' || CAST(p."ID" AS VARCHAR(36)) || c."Path" AS TEXT) AS "Path"
--         FROM
--             __mj_BizAppsCommon."Activity" p
--         INNER JOIN
--             CTE_Ancestors c ON p."ID" = c."ParentActivityID"
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

-- CREATE FUNCTION __mj_BizAppsCommon."fnActivityParentActivityID_GetRootID"
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
--             "ParentActivityID",
--             "ID" AS "RootParentID",
--             0 AS "Depth"
--         FROM
--             __mj_BizAppsCommon."Activity"
--         WHERE
--             "ID" = COALESCE(p_ParentID, p_RecordID)

--         UNION ALL

--         SELECT
--             c."ID",
--             c."ParentActivityID",
--             c."ID" AS "RootParentID",
--             p."Depth" + 1 AS "Depth"
--         FROM
--             __mj_BizAppsCommon."Activity" c
--         INNER JOIN
--             CTE_RootParent p ON c."ID" = p."ParentActivityID"
--         WHERE
--             p."Depth" < 100
--     )
--     SELECT         "RootParentID" AS RootID
--     FROM
--         CTE_RootParent
--     WHERE
--         "ParentActivityID" IS NULL
--     ORDER BY
--         "RootParentID"

-- LIMIT 1);

-- CREATE FUNCTION __mj_BizAppsCommon."fnActivityParentActivityID_GetHierarchyMeta"
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
--             "ParentActivityID",
--             0 AS "Depth",
--             CAST('/' || CAST("ID" AS VARCHAR(36)) || '/' AS TEXT) AS "Path"
--         FROM
--             __mj_BizAppsCommon."Activity"
--         WHERE
--             "ID" = p_RecordID

--         UNION ALL

--         SELECT
--             p."ID",
--             p."ParentActivityID",
--             c."Depth" + 1 AS "Depth",
--             CAST('/' || CAST(p."ID" AS VARCHAR(36)) || c."Path" AS TEXT) AS "Path"
--         FROM
--             __mj_BizAppsCommon."Activity" p
--         INNER JOIN
--             CTE_Ancestors c ON p."ID" = c."ParentActivityID"
--         WHERE
--             c."Depth" < 100
--     )
--     SELECT         a."ID" AS "RootID",
--         (SELECT MAX("Depth") FROM CTE_Ancestors) AS "Depth",
--         (SELECT "Path" FROM CTE_Ancestors ORDER BY "Depth" DESC
-- LIMIT 1) AS "Path",
--         CAST(CASE WHEN EXISTS (SELECT 1 FROM __mj_BizAppsCommon."Activity" WHERE "ParentActivityID" = p_RecordID) THEN 0 ELSE 1 END AS BOOLEAN) AS "IsLeaf",
--         (SELECT COUNT(1) FROM __mj_BizAppsCommon."Activity" WHERE "ParentActivityID" = p_RecordID) AS "ChildCount"
--     FROM
--         CTE_Ancestors a
--     WHERE
--         a."ParentActivityID" IS NULL OR p_ParentID IS NULL
--     ORDER BY
--         a."Depth" DESC

-- LIMIT 1);

-- CREATE FUNCTION __mj_BizAppsCommon."fnActivityParentActivityID_GetDescendants"
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
--             "ParentActivityID",
--             0 AS "RelativeDepth",
--             CAST('/' || CAST("ID" AS VARCHAR(36)) || '/' AS TEXT) AS "Path"
--         FROM
--             __mj_BizAppsCommon."Activity"
--         WHERE
--             "ID" = p_RootID

--         UNION ALL

--         SELECT
--             c."ID",
--             c."ParentActivityID",
--             p."RelativeDepth" || 1 AS "RelativeDepth",
--             CAST(p."Path" || CAST(c."ID" AS VARCHAR(36)) || '/' AS TEXT) AS "Path"
--         FROM
--             __mj_BizAppsCommon."Activity" c
--         INNER JOIN
--             CTE_Descendants p ON c."ParentActivityID" = p."ID"
--         WHERE
--             (p_MaxDepth IS NULL OR p."RelativeDepth" < p_MaxDepth)
--             AND p."RelativeDepth" < 100
--     )
--     SELECT
--         d."ID" AS "ID",
--         d."RelativeDepth" AS "Depth",
--         d."Path",
--         CAST(CASE WHEN EXISTS (SELECT 1 FROM __mj_BizAppsCommon."Activity" WHERE "ParentActivityID" = d."ID") THEN 0 ELSE 1 END AS BOOLEAN) AS "IsLeaf",
--         (SELECT COUNT(1) FROM __mj_BizAppsCommon."Activity" WHERE "ParentActivityID" = d."ID") AS "ChildCount"
--     FROM
--         CTE_Descendants d
-- );

-- CREATE FUNCTION __mj_BizAppsCommon."fnActivityParentActivityID_GetAncestors"
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
--             "ParentActivityID",
--             0 AS "LevelUp",
--             CAST('/' || CAST("ID" AS VARCHAR(36)) || '/' AS TEXT) AS "Path"
--         FROM
--             __mj_BizAppsCommon."Activity"
--         WHERE
--             "ID" = p_RecordID

--         UNION ALL

--         SELECT
--             p."ID",
--             p."ParentActivityID",
--             c."LevelUp" + 1 AS "LevelUp",
--             CAST('/' || CAST(p."ID" AS VARCHAR(36)) || c."Path" AS TEXT) AS "Path"
--         FROM
--             __mj_BizAppsCommon."Activity" p
--         INNER JOIN
--             CTE_Ancestors c ON p."ID" = c."ParentActivityID"
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

-- CREATE FUNCTION __mj_BizAppsCommon."fnActivityParentActivityID_GetRootID"
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
--             "ParentActivityID",
--             "ID" AS "RootParentID",
--             0 AS "Depth"
--         FROM
--             __mj_BizAppsCommon."Activity"
--         WHERE
--             "ID" = COALESCE(p_ParentID, p_RecordID)

--         UNION ALL

--         SELECT
--             c."ID",
--             c."ParentActivityID",
--             c."ID" AS "RootParentID",
--             p."Depth" + 1 AS "Depth"
--         FROM
--             __mj_BizAppsCommon."Activity" c
--         INNER JOIN
--             CTE_RootParent p ON c."ID" = p."ParentActivityID"
--         WHERE
--             p."Depth" < 100
--     )
--     SELECT         "RootParentID" AS RootID
--     FROM
--         CTE_RootParent
--     WHERE
--         "ParentActivityID" IS NULL
--     ORDER BY
--         "RootParentID"

-- LIMIT 1);


-- ===================== Views =====================

DO $do$
DECLARE
  v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
  v_target_name CONSTANT TEXT := 'vwAddresses';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwAddresses"
AS SELECT
    a.*,    a."Latitude" AS "__mj_Latitude",
    a."Longitude" AS "__mj_Longitude"
FROM
    __mj_BizAppsCommon."Address" AS a$vsql$;
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
  v_target_name CONSTANT TEXT := 'vwActivities';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwActivities"
AS SELECT
    a.*,
    "mjBizAppsCommonActivityType_ActivityTypeID"."Name" AS "ActivityType",
    "mjBizAppsCommonActivity_ParentActivityID"."Title" AS "ParentActivity",
    "MJUser_LoggedByUserID"."Name" AS "LoggedByUser",
    "mjBizAppsCommonAddress_AddressID"."DisplayName" AS "Address",
    "mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID"."Name" AS "ActivitySyncConnection",
    __mj_rgc."Latitude" AS "__mj_Latitude",
    __mj_rgc."Longitude" AS "__mj_Longitude",
    "hier_ParentActivityID"."RootID" AS "RootParentActivityID",
    "hier_ParentActivityID"."Depth" AS "ParentActivityIDDepth",
    "hier_ParentActivityID"."Path" AS "ParentActivityIDPath",
    "hier_ParentActivityID"."IsLeaf" AS "ParentActivityIDIsLeaf",
    "hier_ParentActivityID"."ChildCount" AS "ParentActivityIDChildCount"
FROM
    __mj_BizAppsCommon."Activity" AS a
INNER JOIN
    __mj_BizAppsCommon."ActivityType" AS "mjBizAppsCommonActivityType_ActivityTypeID"
  ON
    a."ActivityTypeID" = "mjBizAppsCommonActivityType_ActivityTypeID"."ID"
LEFT OUTER JOIN
    __mj_BizAppsCommon."Activity" AS "mjBizAppsCommonActivity_ParentActivityID"
  ON
    a."ParentActivityID" = "mjBizAppsCommonActivity_ParentActivityID"."ID"
INNER JOIN
    __mj."User" AS "MJUser_LoggedByUserID"
  ON
    a."LoggedByUserID" = "MJUser_LoggedByUserID"."ID"
LEFT OUTER JOIN
    __mj_BizAppsCommon."Address" AS "mjBizAppsCommonAddress_AddressID"
  ON
    a."AddressID" = "mjBizAppsCommonAddress_AddressID"."ID"
LEFT OUTER JOIN
    __mj_BizAppsCommon."ActivitySyncConnection" AS "mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID"
  ON
    a."ActivitySyncConnectionID" = "mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID"."ID"
LEFT OUTER JOIN
    __mj."vwRecordGeoCodes" AS __mj_rgc
  ON
    __mj_rgc."EntityID" = '72E55425-8822-4E70-A075-116219CA5A5D'
    AND __mj_rgc."RecordID" = CAST(a."ID" AS VARCHAR(450))
    AND __mj_rgc."LocationType" = 'Primary'
LEFT JOIN LATERAL (SELECT * FROM __mj_BizAppsCommon."fnActivityParentActivityID_GetHierarchyMeta"(a."ID", a."ParentActivityID")) AS "hier_ParentActivityID"
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

DO $do$
DECLARE
  v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
  v_target_name CONSTANT TEXT := 'vwAddressLinks';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwAddressLinks"
AS SELECT
    a.*,
    "mjBizAppsCommonAddress_AddressID"."DisplayName" AS "Address",
    "MJEntity_EntityID"."Name" AS "Entity",
    "mjBizAppsCommonAddressType_AddressTypeID"."Name" AS "AddressType"
FROM
    __mj_BizAppsCommon."AddressLink" AS a
INNER JOIN
    __mj_BizAppsCommon."Address" AS "mjBizAppsCommonAddress_AddressID"
  ON
    a."AddressID" = "mjBizAppsCommonAddress_AddressID"."ID"
INNER JOIN
    __mj."Entity" AS "MJEntity_EntityID"
  ON
    a."EntityID" = "MJEntity_EntityID"."ID"
INNER JOIN
    __mj_BizAppsCommon."AddressType" AS "mjBizAppsCommonAddressType_AddressTypeID"
  ON
    a."AddressTypeID" = "mjBizAppsCommonAddressType_AddressTypeID"."ID"$vsql$;
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
  v_target_name CONSTANT TEXT := 'vwActivities';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwActivities"
AS SELECT
    a.*,
    "mjBizAppsCommonActivityType_ActivityTypeID"."Name" AS "ActivityType",
    "mjBizAppsCommonActivity_ParentActivityID"."Title" AS "ParentActivity",
    "MJUser_LoggedByUserID"."Name" AS "LoggedByUser",
    "mjBizAppsCommonAddress_AddressID"."DisplayName" AS "Address",
    "mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID"."Name" AS "ActivitySyncConnection",
    __mj_rgc."Latitude" AS "__mj_Latitude",
    __mj_rgc."Longitude" AS "__mj_Longitude",
    "hier_ParentActivityID"."RootID" AS "RootParentActivityID",
    "hier_ParentActivityID"."Depth" AS "ParentActivityIDDepth",
    "hier_ParentActivityID"."Path" AS "ParentActivityIDPath",
    "hier_ParentActivityID"."IsLeaf" AS "ParentActivityIDIsLeaf",
    "hier_ParentActivityID"."ChildCount" AS "ParentActivityIDChildCount"
FROM
    __mj_BizAppsCommon."Activity" AS a
INNER JOIN
    __mj_BizAppsCommon."ActivityType" AS "mjBizAppsCommonActivityType_ActivityTypeID"
  ON
    a."ActivityTypeID" = "mjBizAppsCommonActivityType_ActivityTypeID"."ID"
LEFT OUTER JOIN
    __mj_BizAppsCommon."Activity" AS "mjBizAppsCommonActivity_ParentActivityID"
  ON
    a."ParentActivityID" = "mjBizAppsCommonActivity_ParentActivityID"."ID"
INNER JOIN
    __mj."User" AS "MJUser_LoggedByUserID"
  ON
    a."LoggedByUserID" = "MJUser_LoggedByUserID"."ID"
LEFT OUTER JOIN
    __mj_BizAppsCommon."Address" AS "mjBizAppsCommonAddress_AddressID"
  ON
    a."AddressID" = "mjBizAppsCommonAddress_AddressID"."ID"
LEFT OUTER JOIN
    __mj_BizAppsCommon."ActivitySyncConnection" AS "mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID"
  ON
    a."ActivitySyncConnectionID" = "mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID"."ID"
LEFT OUTER JOIN
    __mj."vwRecordGeoCodes" AS __mj_rgc
  ON
    __mj_rgc."EntityID" = '72E55425-8822-4E70-A075-116219CA5A5D'
    AND __mj_rgc."RecordID" = CAST(a."ID" AS VARCHAR(450))
    AND __mj_rgc."LocationType" = 'Primary'
LEFT JOIN LATERAL (SELECT * FROM __mj_BizAppsCommon."fnActivityParentActivityID_GetHierarchyMeta"(a."ID", a."ParentActivityID")) AS "hier_ParentActivityID"
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

DO $do$
DECLARE
  v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
  v_target_name CONSTANT TEXT := 'vwAddressLinks';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwAddressLinks"
AS SELECT
    a.*,
    "mjBizAppsCommonAddress_AddressID"."DisplayName" AS "Address",
    "MJEntity_EntityID"."Name" AS "Entity",
    "mjBizAppsCommonAddressType_AddressTypeID"."Name" AS "AddressType"
FROM
    __mj_BizAppsCommon."AddressLink" AS a
INNER JOIN
    __mj_BizAppsCommon."Address" AS "mjBizAppsCommonAddress_AddressID"
  ON
    a."AddressID" = "mjBizAppsCommonAddress_AddressID"."ID"
INNER JOIN
    __mj."Entity" AS "MJEntity_EntityID"
  ON
    a."EntityID" = "MJEntity_EntityID"."ID"
INNER JOIN
    __mj_BizAppsCommon."AddressType" AS "mjBizAppsCommonAddressType_AddressTypeID"
  ON
    a."AddressTypeID" = "mjBizAppsCommonAddressType_AddressTypeID"."ID"$vsql$;
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
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spCreateAddress]
--     @ID UUID = NULL,
--     @Line1_Clear bit = 0,
--     @Line1 VARCHAR(255) = NULL,
--     @Line2_Clear bit = 0,
--     @Line2 VARCHAR(255) =...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spUpdateAddress]
--     @ID UUID,
--     @Line1_Clear bit = 0,
--     @Line1 VARCHAR(255) = NULL,
--     @Line2_Clear bit = 0,
--     @Line2 VARCHAR(255) = NULL,
-- ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spDeleteAddress]
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         [__mj_BizAppsCommon].[Address]
--     WHERE
--         [ID] = @ID
-- 
-- 
--    ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spCreateActivity]
--     @ID UUID = NULL,
--     @ActivityTypeID UUID,
--     @StartedAt datetimeoffset,
--     @EndedAt_Clear bit = 0,
--     @EndedAt ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spUpdateActivity]
--     @ID UUID,
--     @ActivityTypeID UUID = NULL,
--     @StartedAt datetimeoffset = NULL,
--     @EndedAt_Clear bit = 0,
--     @E...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spDeleteActivity]
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         [__mj_BizAppsCommon].[Activity]
--     WHERE
--         [ID] = @ID
-- 
-- 
--  ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spCreateAddressLink]
--     @ID UUID = NULL,
--     @AddressID UUID,
--     @EntityID UUID,
--     @RecordID VARCHAR(700),
--     @AddressT...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spUpdateAddressLink]
--     @ID UUID,
--     @AddressID UUID = NULL,
--     @EntityID UUID = NULL,
--     @RecordID VARCHAR(700) = NULL,...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spDeleteAddressLink]
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         [__mj_BizAppsCommon].[AddressLink]
--     WHERE
--         [ID] = @...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spCreateActivity]
--     @ID UUID = NULL,
--     @ActivityTypeID UUID,
--     @StartedAt datetimeoffset,
--     @EndedAt_Clear bit = 0,
--     @EndedAt ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spUpdateActivity]
--     @ID UUID,
--     @ActivityTypeID UUID = NULL,
--     @StartedAt datetimeoffset = NULL,
--     @EndedAt_Clear bit = 0,
--     @E...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spDeleteActivity]
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         [__mj_BizAppsCommon].[Activity]
--     WHERE
--         [ID] = @ID
-- 
-- 
--  ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spCreateAddressLink]
--     @ID UUID = NULL,
--     @AddressID UUID,
--     @EntityID UUID,
--     @RecordID VARCHAR(700),
--     @AddressT...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spUpdateAddressLink]
--     @ID UUID,
--     @AddressID UUID = NULL,
--     @EntityID UUID = NULL,
--     @RecordID VARCHAR(700) = NULL,...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spDeleteAddressLink]
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         [__mj_BizAppsCommon].[AddressLink]
--     WHERE
--         [ID] = @...


-- ===================== Triggers =====================

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_BizAppsCommon].trgUpdateAddress
-- ON "__mj_BizAppsCommon"."Address"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         "__mj_BizAppsCommon"."Address"
--     SET
--         __mj_

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_BizAppsCommon].trgUpdateActivity
-- ON "__mj_BizAppsCommon"."Activity"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         "__mj_BizAppsCommon"."Activity"
--     SET
--         __

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_BizAppsCommon].trgUpdateAddressLink
-- ON "__mj_BizAppsCommon"."AddressLink"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         "__mj_BizAppsCommon"."AddressLink"
--     SET
 

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_BizAppsCommon].trgUpdateActivity
-- ON "__mj_BizAppsCommon"."Activity"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         "__mj_BizAppsCommon"."Activity"
--     SET
--         __

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_BizAppsCommon].trgUpdateAddressLink
-- ON "__mj_BizAppsCommon"."AddressLink"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         "__mj_BizAppsCommon"."AddressLink"
--     SET
 


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."EntityField" WHERE "ID" = '7b954eef-a93e-4780-8692-8c1a25d33984' OR ("EntityID" = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E' AND "Name" = 'DisplayName')
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
        '7b954eef-a93e-4780-8692-8c1a25d33984',
        '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E', -- "Entity": "MJ_BizApps_Common": "Addresses"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM __mj."EntityField" WHERE "EntityID" = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E'),
        'DisplayName',
        'Display Name',
        'One-line label for the address in US order: Line1, City, State PostalCode, Country. Blank parts are skipped; NULL when every part is blank. Computed and stored; this is the entity name field.',
        'TEXT',
        800,
        0,
        0,
        TRUE,
        NULL,
        FALSE,
        FALSE,
        TRUE,
        TRUE,
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

/* Index for Foreign Keys for Address */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Addresses
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

/* Base View SQL for MJ_BizApps_Common: Addresses */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Addresses
-- Item: vwAddresses
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Addresses
-----               SCHEMA:      __mj_BizAppsCommon
-----               BASE TABLE:  Address
-----               PRIMARY KEY: ID
------------------------------------------------------------

UPDATE __mj."EntityField"
               SET "DefaultInView" = TRUE
               WHERE "ID" = '7B954EEF-A93E-4780-8692-8C1A25D33984'
               AND "AutoUpdateDefaultInView" = TRUE;

UPDATE __mj."EntityField"
               SET "IncludeInUserSearchAPI" = TRUE
               WHERE "ID" = '7B954EEF-A93E-4780-8692-8C1A25D33984'
               AND "AutoUpdateIncludeInUserSearchAPI" = TRUE;

UPDATE __mj."EntityField"
               SET "UserSearchPredicateAPI" = 'BeginsWith'
               WHERE "ID" = '7B954EEF-A93E-4780-8692-8C1A25D33984'
               AND "AutoUpdateUserSearchPredicate" = TRUE;

/* Set categories for 3 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Addresses.DisplayName

UPDATE __mj."EntityField"
SET 
   "Category" = 'Address Details',
   "GeneratedFormSection" = 'Category',
   "ExtendedType" = 'GeoAddress'
WHERE 
   "ID" = '7B954EEF-A93E-4780-8692-8C1A25D33984';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Addresses.__mj_Latitude

UPDATE __mj."EntityField"
SET 
   "Category" = 'System Metadata',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '7B94AD01-7880-4FAE-97D8-DB0E934C3F5F';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Addresses.__mj_Longitude

UPDATE __mj."EntityField"
SET 
   "Category" = 'System Metadata',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '7B94AD02-7880-4FAE-97D8-DB0E934C3F5F';

/* Hierarchy Metadata Function SQL for MJ_BizApps_Common: Activities.ParentActivityID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: fnActivityParentActivityID_GetHierarchyMeta
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- HIERARCHY METADATA FUNCTION FOR: [Activity].[ParentActivityID]
------------------------------------------------------------

UPDATE __mj."EntityField"
               SET "DefaultInView" = TRUE
               WHERE "ID" = '99D4FE49-BC0B-4D9D-B7EC-84E04F7281EE'
               AND "AutoUpdateDefaultInView" = TRUE;

/* Set categories for 1 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Address Links.Address

UPDATE __mj."EntityField"
SET 
   "Category" = 'Linkage Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '99D4FE49-BC0B-4D9D-B7EC-84E04F7281EE';

/* Set categories for 3 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.ParentActivity

UPDATE __mj."EntityField"
SET 
   "Category" = 'Relationships',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '7DAD09C3-0203-4DE1-8655-D882D3BC5875';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.__mj_Latitude

UPDATE __mj."EntityField"
SET 
   "Category" = 'System Metadata',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = 'C5AD14B9-DEB5-41AE-B1E7-0E928085AE39';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.__mj_Longitude

UPDATE __mj."EntityField"
SET 
   "Category" = 'System Metadata',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = 'BAA8C311-EE92-4F3B-BB5F-000810AF4894';


-- ===================== Grants =====================

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwAddresses" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwAddresses" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwAddresses" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwAddresses" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View Permissions SQL for MJ_BizApps_Common: Addresses */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Addresses
-- Item: Permissions for vwAddresses
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwAddresses" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwAddresses" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwAddresses" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwAddresses" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Addresses */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Addresses
-- Item: spCreateAddress
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Address
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateAddress" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateAddress" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateAddress" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Addresses */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateAddress" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateAddress" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateAddress" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Addresses */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Addresses
-- Item: spUpdateAddress
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Address
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateAddress" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateAddress" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateAddress" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateAddress" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateAddress" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateAddress" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Addresses */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Addresses
-- Item: spDeleteAddress
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Address
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteAddress" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteAddress" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Addresses */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteAddress" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteAddress" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* SQL text to update entity field related entity name field map for entity field ID EB506B92-343C-434D-B21F-12CFECDA3D3B */

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwActivities" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwActivities" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwActivities" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwActivities" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View Permissions SQL for MJ_BizApps_Common: Activities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: Permissions for vwActivities
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwActivities" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwActivities" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwActivities" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwActivities" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Activities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: spCreateActivity
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Activity
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateActivity" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateActivity" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateActivity" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Activities */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateActivity" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateActivity" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateActivity" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Activities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: spUpdateActivity
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Activity
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateActivity" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateActivity" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateActivity" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateActivity" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateActivity" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateActivity" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Activities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: spDeleteActivity
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Activity
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteActivity" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteActivity" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteActivity" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Activities */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteActivity" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteActivity" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteActivity" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View SQL for MJ_BizApps_Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Address Links
-- Item: vwAddressLinks
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Address Links
-----               SCHEMA:      __mj_BizAppsCommon
-----               BASE TABLE:  AddressLink
-----               PRIMARY KEY: ID
------------------------------------------------------------;

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwAddressLinks" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwAddressLinks" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwAddressLinks" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwAddressLinks" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View Permissions SQL for MJ_BizApps_Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Address Links
-- Item: Permissions for vwAddressLinks
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwAddressLinks" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwAddressLinks" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwAddressLinks" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwAddressLinks" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Address Links
-- Item: spCreateAddressLink
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR AddressLink
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateAddressLink" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateAddressLink" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateAddressLink" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Address Links */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateAddressLink" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateAddressLink" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateAddressLink" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Address Links
-- Item: spUpdateAddressLink
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR AddressLink
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateAddressLink" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateAddressLink" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateAddressLink" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateAddressLink" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateAddressLink" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateAddressLink" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Address Links
-- Item: spDeleteAddressLink
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR AddressLink
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteAddressLink" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteAddressLink" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Address Links */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteAddressLink" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteAddressLink" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Index for Foreign Keys for Activity */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key ActivityTypeID in table Activity;

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwActivities" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwActivities" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwActivities" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwActivities" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View Permissions SQL for MJ_BizApps_Common: Activities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: Permissions for vwActivities
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwActivities" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwActivities" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwActivities" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwActivities" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Activities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: spCreateActivity
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Activity
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateActivity" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateActivity" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateActivity" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Activities */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateActivity" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateActivity" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateActivity" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Activities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: spUpdateActivity
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Activity
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateActivity" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateActivity" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateActivity" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateActivity" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateActivity" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateActivity" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Activities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: spDeleteActivity
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Activity
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteActivity" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteActivity" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteActivity" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Activities */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteActivity" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteActivity" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteActivity" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Index for Foreign Keys for AddressLink */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Address Links
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key AddressID in table AddressLink;

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwAddressLinks" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwAddressLinks" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwAddressLinks" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwAddressLinks" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View Permissions SQL for MJ_BizApps_Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Address Links
-- Item: Permissions for vwAddressLinks
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwAddressLinks" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwAddressLinks" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwAddressLinks" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwAddressLinks" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Address Links
-- Item: spCreateAddressLink
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR AddressLink
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateAddressLink" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateAddressLink" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateAddressLink" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Address Links */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateAddressLink" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateAddressLink" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateAddressLink" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Address Links
-- Item: spUpdateAddressLink
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR AddressLink
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateAddressLink" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateAddressLink" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateAddressLink" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateAddressLink" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateAddressLink" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateAddressLink" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Address Links
-- Item: spDeleteAddressLink
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR AddressLink
------------------------------------------------------------;

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteAddressLink" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteAddressLink" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Address Links */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteAddressLink" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteAddressLink" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Set field properties for entity */


-- ===================== Other =====================

-- =============================================================================
-- Migration: V202610151046__v5.54.x__Address_DisplayName.sql
-- Description: Add a PERSISTED computed column Address.DisplayName — a one-line,
--              US-ordered label ("123 Main St, Springfield, IL 62701, United States")
--              — and make it the Addresses name field (metadata/entities/.entities.json).
--
-- WHY. The name field was Line1, which V202610031602 made nullable: an address that
-- records only a location (country, region, postal code) showed up blank in pickers,
-- FK labels (AddressLink.Address, Activity.Address) and search results, and two
-- "123 Main St" rows in different cities were indistinguishable.
--
-- WHY ONE FIXED LAYOUT, NOT PER-COUNTRY. Address.Country is free text, not a key to
-- __mj.Country, and no table stores postal layouts, so a per-country format would first
-- have to resolve "USA" / "United States" / "U.S." inside the view. The name field
-- identifies a row; it is not a mailing label. Country-aware formatting belongs in the
-- presentation layer, where an address is printed in full.
--
-- WHY PERSISTED. Stored and indexed, so BeginsWith user search can seek on it instead
-- of recomputing a view expression for every row.
--
-- SHAPE. Each part is trimmed and an empty part is dropped (NULLIF(TRIM(x), N'')), so a
-- location-only address reads "ON, Canada", never ", , ON, , Canada". State and postal
-- code share one comma slot ("IL 62701"). Line2/Line3 are left out of the one-line label.
-- An address with no parts at all is NULL rather than an empty string. Capped at 400
-- characters (800 bytes) so it stays under SQL Server's 1,700-byte index key limit.
--
-- POSTGRESQL. Release work. concat_ws() is STABLE, not IMMUTABLE, so it cannot appear in
-- a GENERATED column; the counterpart needs || with COALESCE/NULLIF instead.
-- =============================================================================

-- Address.DisplayName: "Line1, City, State PostalCode, Country", blank parts dropped, NULL when all are
-- blank. Written by hand: the converter passes the T-SQL computed column through untranslated. concat_ws()
-- and array_to_string() are STABLE, so the generated column joins with || and SUBSTRING (see Person.DisplayName
-- in V202610151049); checked equal to the T-SQL on full, partial and blank addresses.
ALTER TABLE __mj_bizappscommon."Address"
    ADD COLUMN IF NOT EXISTS "DisplayName" VARCHAR(400) GENERATED ALWAYS AS (CAST(NULLIF(SUBSTRING(
        COALESCE(', ' || NULLIF(TRIM("Line1"), ''), '')
        || COALESCE(', ' || NULLIF(TRIM("City"), ''), '')
        || COALESCE(', ' || NULLIF(SUBSTRING(
               COALESCE(' ' || NULLIF(TRIM("StateProvince"), ''), '')
               || COALESCE(' ' || NULLIF(TRIM("PostalCode"), ''), '')
           FROM 2), ''), '')
        || COALESCE(', ' || NULLIF(TRIM("Country"), ''), '')
    FROM 3), '') AS VARCHAR(400))) STORED;


/* ============================================================================================
   ==== CODEGEN OUTPUT — DO NOT EDIT BELOW THIS LINE ====
   Generated by the MemberJunction CodeGen tool: MJ CLI 6.2.0-edge.3 / CodeGenLib from MJ `next`
   @ d96fee72d7, includeSchemas ['__mj_BizAppsCommon'], against a database built from migrations
   with metadata/ pushed first (so CHECK validators come from the pinned GeneratedCode rows).
   Contains: the Address.DisplayName EntityField insert, regenerated vwAddresses and Address CRUD procs,
   field settings, and — after Address.DisplayName became the name field — vwActivities and
   vwAddressLinks, whose "Address" column now reads Address.DisplayName, with their CRUD procs and
   the Activity hierarchy TVFs that regenerate with vwActivities.
   NOTE: run (1) tags Address.DisplayName ExtendedType = 'GeoAddress' (AI field typing). metadata/
   pins it back to none (AutoUpdateExtendedType = 0); that pin reaches hosts in the release seed.
   Do NOT edit by hand. If the hand-written SQL above changes, re-run CodeGen and replace this
   whole section.
   Runs: (1) after the DDL above; (2) and (3) after `mj sync push` set the name field and the geo pins;
   a fourth run produced no SQL.
   ============================================================================================ */

/* SQL text to update entity field related entity name field map for entity field ID 0E353B64-06BA-4582-8532-5DB427B539EE */

/* spUpdate Permissions for MJ_BizApps_Common: Addresses */

/* spUpdate Permissions for MJ_BizApps_Common: Activities */

/* spUpdate Permissions for MJ_BizApps_Common: Address Links */

/* spUpdate Permissions for MJ_BizApps_Common: Activities */

/* spUpdate Permissions for MJ_BizApps_Common: Address Links */

-- ===================== Skipped by the converter, translated by hand =====================
-- CodeGen's related-entity name-field map updates and changed column descriptions.
SELECT __mj."spUpdateEntityFieldRelatedEntityNameFieldMap"('0E353B64-06BA-4582-8532-5DB427B539EE'::uuid, 'JobFunction');
SELECT __mj."spUpdateEntityFieldRelatedEntityNameFieldMap"('438BD1D0-764F-4D90-A51F-24C150CB8313'::uuid, 'SeniorityLevel');
SELECT __mj."spUpdateEntityFieldRelatedEntityNameFieldMap"('EB506B92-343C-434D-B21F-12CFECDA3D3B'::uuid, 'SeniorityLevel');
SELECT __mj."spUpdateEntityFieldRelatedEntityNameFieldMap"('4389D414-26D3-463E-A90D-38AFA3836E5C'::uuid, 'Person');
