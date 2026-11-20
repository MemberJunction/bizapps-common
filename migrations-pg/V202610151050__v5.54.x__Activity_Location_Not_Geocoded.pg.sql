-- =============================================================================================
-- PostgreSQL counterpart of V202610151050__v5.54.x__Activity_Location_Not_Geocoded.sql
-- =============================================================================================
-- `mj sql-convert --from tsql --to postgres` (MJ CLI 6.1.5) output, finished by hand:
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


-- ===================== Views =====================

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


-- ===================== Stored Procedures (sp*) =====================

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


-- ===================== Triggers =====================

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


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

-- =============================================================================
-- Migration: V202610151050__v5.54.x__Activity_Location_Not_Geocoded.sql
-- Description: Activities stop being a geo write source.
--
-- WHY. Activity.Location is free text ("Virtual (Teams)", "Conference room B"), but
-- CodeGen's AI typing tagged it ExtendedType = 'GeoAddress'. That made it Activity's only
-- writable geo field, so MJ's GeoCodeSyncService ran on every Activity save: with a provider
-- configured it sent the text to the provider, and when the text was not a place it wrote a
-- failed RecordGeoCode row. more-cheese's seed ships 500 such rows, one per sample Activity.
-- The structured location is AddressID, and an Address carries its own coordinates.
--
-- WHAT CHANGES.
--   1) Location's ExtendedType is cleared and pinned (AutoUpdateExtendedType = 0). The same
--      pin is in metadata/entities/.entities.json; it is here too because the generated
--      vwActivities below is only correct while Location is untagged, and the Open App
--      installer applies migrations, not metadata/.
--   2) With no writable geo field left, MJ CodeGen no longer joins vwRecordGeoCodes on
--      Activities (MJCore geoFields ShouldJoinRecordGeoCodes: the join is for geo sources),
--      so vwActivities loses __mj_Latitude / __mj_Longitude. Their two EntityField rows are
--      deleted here, with any rows that reference them. Left in place they name columns the
--      view no longer has, every read of Activities fails, and every later CodeGen run fails
--      on UQ_EntityField_EntityID_Sequence. Same fix and shape as V202610062130 (#215, #237);
--      packages/Server geo-virtual-fields.test.ts reads these DELETEs in chain order.
--   3) The CodeGen section regenerates vwActivities without the join, with its procedures.
--   4) Address's geo tags match metadata/: DisplayName untagged, the five parts tagged, all
--      pinned. V202610151046's CodeGen section tags DisplayName GeoAddress; that has to be
--      undone after it runs, so it is here rather than there. Pinning DisplayName alone would
--      leave Address with no geo field until the release seed, so the parts are set too.
--
-- Activity.Address (the view's label for AddressID) keeps its GeoAddress tag: it is virtual,
-- so it never triggers the geocoder; it only tells map features which column holds a place.
-- =============================================================================

-- 1) Location is not a geo field.
UPDATE __mj."EntityField"
   SET "ExtendedType"           = NULL,
       "AutoUpdateExtendedType" = FALSE
 WHERE "EntityID" = '72E55425-8822-4E70-A075-116219CA5A5D'  -- Entity: MJ_BizApps_Common: Activities
   AND "Name" = 'Location';

-- 4) Address: the parts are the geo source, the one-line label is not.
UPDATE __mj."EntityField"
   SET "ExtendedType" = CASE "Name"
                            WHEN 'Line1'         THEN 'GeoAddress'
                            WHEN 'City'          THEN 'GeoCity'
                            WHEN 'StateProvince' THEN 'GeoStateProvince'
                            WHEN 'PostalCode'    THEN 'GeoPostalCode'
                            WHEN 'Country'       THEN 'GeoCountry'
                        END,
       "AutoUpdateExtendedType" = FALSE
 WHERE "EntityID" = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E'  -- Entity: MJ_BizApps_Common: Addresses
   AND "Name" IN ('DisplayName', 'Line1', 'City', 'StateProvince', 'PostalCode', 'Country');

-- 2) The two virtual geo fields, and the rows that reference them.
--    EntityFieldPermission exists from MJ 6.1.x on; this app still installs on earlier 6.1
--    Edge cores without it, hence the dynamic statement (as in V202610062130).
DELETE FROM __mj."EntityFieldValue"
WHERE "EntityFieldID" IN (
    SELECT "ID" FROM __mj."EntityField"
    WHERE "EntityID" = '72E55425-8822-4E70-A075-116219CA5A5D'
      AND "Name" IN ('__mj_Latitude', '__mj_Longitude')
);

DELETE FROM __mj."EntityField" WHERE "EntityID" = '72E55425-8822-4E70-A075-116219CA5A5D' AND "Name" IN ('__mj_Latitude', '__mj_Longitude'); -- Entity: MJ_BizApps_Common: Activities;


-- ===================== Grants =====================

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
-- ===================== Other =====================

/* spUpdate Permissions for MJ_BizApps_Common: Activities */
