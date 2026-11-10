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

-- =============================================================================
-- Native PostgreSQL CodeGen for the procedures and triggers the conversion above skipped
-- (Activity).
-- =============================================================================
-- ---------- native PostgreSQL CodeGen: MJ_BizApps_Common: Activities
-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Activities
-- Item: Index for Foreign Keys

-- ============================================================
CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_activity_activity_type_id"
    ON "__mj_bizappscommon"."Activity" ("ActivityTypeID");

CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_activity_parent_activity_id"
    ON "__mj_bizappscommon"."Activity" ("ParentActivityID");

CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_activity_logged_by_user_id"
    ON "__mj_bizappscommon"."Activity" ("LoggedByUserID");

CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_activity_address_id"
    ON "__mj_bizappscommon"."Activity" ("AddressID");

CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_activity_activity_sync_connection_id"
    ON "__mj_bizappscommon"."Activity" ("ActivitySyncConnectionID");

-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Activities
-- Item: fn_activity_parent_activity_id_get_hierarchy_meta

-- ============================================================

------------------------------------------------------------
----- HIERARCHY METADATA FUNCTION FOR: Activity.ParentActivityID
------------------------------------------------------------
CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."fn_activity_parent_activity_id_get_hierarchy_meta"(
    p_record_id UUID,
    p_parent_id UUID
) RETURNS TABLE (
    "RootID" UUID,
    "Depth" INTEGER,
    "Path" TEXT,
    "IsLeaf" BOOLEAN,
    "ChildCount" INTEGER
) AS $$
    WITH RECURSIVE cte_ancestors AS (
        SELECT
            "ID",
            "ParentActivityID",
            0 AS depth,
            '/' || "ID"::TEXT || '/' AS path
        FROM
            "__mj_bizappscommon"."Activity"
        WHERE
            "ID" = p_record_id

        UNION ALL

        SELECT
            p."ID",
            p."ParentActivityID",
            c.depth + 1 AS depth,
            '/' || p."ID"::TEXT || c.path AS path
        FROM
            "__mj_bizappscommon"."Activity" p
        INNER JOIN
            cte_ancestors c ON p."ID" = c."ParentActivityID"
        WHERE
            c.depth < 100
    )
    SELECT
        a."ID" AS "RootID",
        (SELECT MAX(depth) FROM cte_ancestors)::INTEGER AS "Depth",
        (SELECT path FROM cte_ancestors ORDER BY depth DESC LIMIT 1)::TEXT AS "Path",
        (NOT EXISTS (SELECT 1 FROM "__mj_bizappscommon"."Activity" WHERE "ParentActivityID" = p_record_id))::BOOLEAN AS "IsLeaf",
        (SELECT COUNT(1)::INTEGER FROM "__mj_bizappscommon"."Activity" WHERE "ParentActivityID" = p_record_id) AS "ChildCount"
    FROM
        cte_ancestors a
    WHERE
        a."ParentActivityID" IS NULL OR p_parent_id IS NULL
    ORDER BY
        a.depth DESC
    LIMIT 1;
$$ LANGUAGE sql STABLE;


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Activities
-- Item: fn_activity_parent_activity_id_get_descendants

-- ============================================================

------------------------------------------------------------
----- DESCENDANTS FUNCTION FOR: Activity.ParentActivityID
------------------------------------------------------------
CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."fn_activity_parent_activity_id_get_descendants"(
    p_root_id UUID,
    p_max_depth INTEGER DEFAULT NULL
) RETURNS TABLE (
    "ID" UUID,
    "Depth" INTEGER,
    "Path" TEXT,
    "IsLeaf" BOOLEAN,
    "ChildCount" INTEGER
) AS $$
    WITH RECURSIVE cte_descendants AS (
        SELECT
            "ID",
            "ParentActivityID",
            0 AS relative_depth,
            '/' || "ID"::TEXT || '/' AS path
        FROM
            "__mj_bizappscommon"."Activity"
        WHERE
            "ID" = p_root_id

        UNION ALL

        SELECT
            c."ID",
            c."ParentActivityID",
            p.relative_depth + 1 AS relative_depth,
            p.path || c."ID"::TEXT || '/' AS path
        FROM
            "__mj_bizappscommon"."Activity" c
        INNER JOIN
            cte_descendants p ON c."ParentActivityID" = p."ID"
        WHERE
            (p_max_depth IS NULL OR p.relative_depth < p_max_depth)
            AND p.relative_depth < 100
    )
    SELECT
        d."ID" AS "ID",
        d.relative_depth AS "Depth",
        d.path AS "Path",
        (NOT EXISTS (SELECT 1 FROM "__mj_bizappscommon"."Activity" WHERE "ParentActivityID" = d."ID"))::BOOLEAN AS "IsLeaf",
        (SELECT COUNT(1)::INTEGER FROM "__mj_bizappscommon"."Activity" WHERE "ParentActivityID" = d."ID") AS "ChildCount"
    FROM
        cte_descendants d;
$$ LANGUAGE sql STABLE;


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Activities
-- Item: fn_activity_parent_activity_id_get_ancestors

-- ============================================================

------------------------------------------------------------
----- ANCESTORS FUNCTION FOR: Activity.ParentActivityID
------------------------------------------------------------
CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."fn_activity_parent_activity_id_get_ancestors"(
    p_record_id UUID
) RETURNS TABLE (
    "ID" UUID,
    "LevelUp" INTEGER,
    "Path" TEXT
) AS $$
    WITH RECURSIVE cte_ancestors AS (
        SELECT
            "ID",
            "ParentActivityID",
            0 AS level_up,
            '/' || "ID"::TEXT || '/' AS path
        FROM
            "__mj_bizappscommon"."Activity"
        WHERE
            "ID" = p_record_id

        UNION ALL

        SELECT
            p."ID",
            p."ParentActivityID",
            c.level_up + 1 AS level_up,
            '/' || p."ID"::TEXT || c.path AS path
        FROM
            "__mj_bizappscommon"."Activity" p
        INNER JOIN
            cte_ancestors c ON p."ID" = c."ParentActivityID"
        WHERE
            c.level_up < 100
    )
    SELECT
        a."ID" AS "ID",
        a.level_up AS "LevelUp",
        a.path AS "Path"
    FROM
        cte_ancestors a;
$$ LANGUAGE sql STABLE;


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Activities
-- Item: fn_activity_parent_activity_id_get_root_id

-- ============================================================

------------------------------------------------------------
----- ROOT ID FUNCTION FOR: Activity.ParentActivityID
------------------------------------------------------------
CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."fn_activity_parent_activity_id_get_root_id"(
    p_record_id UUID,
    p_parent_id UUID
) RETURNS UUID AS $$
    WITH RECURSIVE cte_root_parent AS (
        -- Anchor: Start from p_parent_id if not null, otherwise start from p_record_id
        SELECT
            "ID",
            "ParentActivityID",
            "ID" AS root_parent_id,
            0 AS depth
        FROM
            "__mj_bizappscommon"."Activity"
        WHERE
            "ID" = COALESCE(p_parent_id, p_record_id)

        UNION ALL

        -- Recursive: Keep going up the hierarchy
        SELECT
            c."ID",
            c."ParentActivityID",
            c."ID" AS root_parent_id,
            p.depth + 1 AS depth
        FROM
            "__mj_bizappscommon"."Activity" c
        INNER JOIN
            cte_root_parent p ON c."ID" = p."ParentActivityID"
        WHERE
            p.depth < 100  -- Prevent infinite loops
    )
    SELECT root_parent_id
    FROM cte_root_parent
    WHERE "ParentActivityID" IS NULL
    ORDER BY root_parent_id
    LIMIT 1;
$$ LANGUAGE sql STABLE;


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Activities
-- Item: vwActivities

-- ============================================================

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Activities
-----               SCHEMA:      __mj_bizappscommon
-----               BASE TABLE:  Activity
-----               PRIMARY KEY: ID
------------------------------------------------------------
DO $vw_regen$
DECLARE
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW "__mj_bizappscommon"."vwActivities"
AS
SELECT
    a.*,
    mjbizappscommonActivityType_ActivityTypeID."Name" AS "ActivityType",
    mjbizappscommonActivity_ParentActivityID."Title" AS "ParentActivity",
    MJUser_LoggedByUserID."Name" AS "LoggedByUser",
    mjbizappscommonAddress_AddressID."Line1" AS "Address",
    mjbizappscommonActivitySyncConnection_ActivitySyncConnectionID."Name" AS "ActivitySyncConnection",
    hier_ParentActivityID."RootID" AS "RootParentActivityID",
    hier_ParentActivityID."Depth" AS "ParentActivityIDDepth",
    hier_ParentActivityID."Path" AS "ParentActivityIDPath",
    hier_ParentActivityID."IsLeaf" AS "ParentActivityIDIsLeaf",
    hier_ParentActivityID."ChildCount" AS "ParentActivityIDChildCount"
FROM
    "__mj_bizappscommon"."Activity" AS a
INNER JOIN
    "__mj_bizappscommon"."ActivityType" AS mjbizappscommonActivityType_ActivityTypeID
  ON
    "a"."ActivityTypeID" = mjbizappscommonActivityType_ActivityTypeID."ID"
LEFT OUTER JOIN
    "__mj_bizappscommon"."Activity" AS mjbizappscommonActivity_ParentActivityID
  ON
    "a"."ParentActivityID" = mjbizappscommonActivity_ParentActivityID."ID"
INNER JOIN
    "__mj"."User" AS MJUser_LoggedByUserID
  ON
    "a"."LoggedByUserID" = MJUser_LoggedByUserID."ID"
LEFT OUTER JOIN
    "__mj_bizappscommon"."Address" AS mjbizappscommonAddress_AddressID
  ON
    "a"."AddressID" = mjbizappscommonAddress_AddressID."ID"
LEFT OUTER JOIN
    "__mj_bizappscommon"."ActivitySyncConnection" AS mjbizappscommonActivitySyncConnection_ActivitySyncConnectionID
  ON
    "a"."ActivitySyncConnectionID" = mjbizappscommonActivitySyncConnection_ActivitySyncConnectionID."ID"

LEFT JOIN LATERAL "__mj_bizappscommon"."fn_activity_parent_activity_id_get_hierarchy_meta"(a."ID", a."ParentActivityID") AS hier_ParentActivityID ON true
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
        AND tc.relname = 'vwActivities'
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
                           AND tc.relname = 'vwActivities'
                           AND tc.relkind IN ('v', 'm')))
        AND (pp.prorettype = c.reltype
             OR EXISTS (SELECT 1 FROM pg_depend d
                        WHERE d.classid = 'pg_proc'::regclass
                          AND d.objid = pp.oid
                          AND d.refobjid = c.oid))
  );

  DROP VIEW IF EXISTS "__mj_bizappscommon"."vwActivities" CASCADE;
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
GRANT SELECT ON "__mj_bizappscommon"."vwActivities" TO "cdp_UI";
GRANT SELECT ON "__mj_bizappscommon"."vwActivities" TO "cdp_Developer";
GRANT SELECT ON "__mj_bizappscommon"."vwActivities" TO "cdp_Integration";

-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Activities
-- Item: spCreateActivity

-- ============================================================

------------------------------------------------------------
----- CREATE FUNCTION FOR Activity
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spCreateActivity'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spCreateActivity"(
    p_id UUID DEFAULT NULL,
    p_activitytypeid UUID DEFAULT NULL,
    p_startedat TIMESTAMPTZ DEFAULT NULL,
    p_endedat_clear boolean DEFAULT false,
    p_endedat TIMESTAMPTZ DEFAULT NULL,
    p_title varchar(500) DEFAULT NULL,
    p_description_clear boolean DEFAULT false,
    p_description TEXT DEFAULT NULL,
    p_direction varchar(20) DEFAULT NULL,
    p_status varchar(20) DEFAULT NULL,
    p_outcome_clear boolean DEFAULT false,
    p_outcome varchar(40) DEFAULT NULL,
    p_visibility varchar(20) DEFAULT NULL,
    p_source varchar(20) DEFAULT NULL,
    p_sourcesystem_clear boolean DEFAULT false,
    p_sourcesystem varchar(80) DEFAULT NULL,
    p_externalid_clear boolean DEFAULT false,
    p_externalid varchar(400) DEFAULT NULL,
    p_externalthreadid_clear boolean DEFAULT false,
    p_externalthreadid varchar(400) DEFAULT NULL,
    p_parentactivityid_clear boolean DEFAULT false,
    p_parentactivityid UUID DEFAULT NULL,
    p_loggedbyuserid UUID DEFAULT NULL,
    p_location_clear boolean DEFAULT false,
    p_location varchar(500) DEFAULT NULL,
    p_addressid_clear boolean DEFAULT false,
    p_addressid UUID DEFAULT NULL,
    p_activitysyncconnectionid_clear boolean DEFAULT false,
    p_activitysyncconnectionid UUID DEFAULT NULL,
    p_details_clear boolean DEFAULT false,
    p_details TEXT DEFAULT NULL,
    p_sentimentscore_clear boolean DEFAULT false,
    p_sentimentscore decimal(4, 3) DEFAULT NULL
) RETURNS SETOF "__mj_bizappscommon"."vwActivities" AS $$
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO "__mj_bizappscommon"."Activity"
        (
            "ID",
            "ActivityTypeID",
                "StartedAt",
                "EndedAt",
                "Title",
                "Description",
                "Direction",
                "Status",
                "Outcome",
                "Visibility",
                "Source",
                "SourceSystem",
                "ExternalID",
                "ExternalThreadID",
                "ParentActivityID",
                "LoggedByUserID",
                "Location",
                "AddressID",
                "ActivitySyncConnectionID",
                "Details",
                "SentimentScore"
        )
    VALUES
        (
            v_new_id,
            p_activitytypeid,
                p_startedat,
                CASE WHEN p_endedat_clear = true THEN NULL ELSE COALESCE(p_endedat, NULL) END,
                p_title,
                CASE WHEN p_description_clear = true THEN NULL ELSE COALESCE(p_description, NULL) END,
                p_direction,
                COALESCE(p_status, 'Logged'),
                CASE WHEN p_outcome_clear = true THEN NULL ELSE COALESCE(p_outcome, NULL) END,
                COALESCE(p_visibility, 'Internal'),
                COALESCE(p_source, 'Manual'),
                CASE WHEN p_sourcesystem_clear = true THEN NULL ELSE COALESCE(p_sourcesystem, NULL) END,
                CASE WHEN p_externalid_clear = true THEN NULL ELSE COALESCE(p_externalid, NULL) END,
                CASE WHEN p_externalthreadid_clear = true THEN NULL ELSE COALESCE(p_externalthreadid, NULL) END,
                CASE WHEN p_parentactivityid_clear = true THEN NULL ELSE COALESCE(p_parentactivityid, NULL) END,
                p_loggedbyuserid,
                CASE WHEN p_location_clear = true THEN NULL ELSE COALESCE(p_location, NULL) END,
                CASE WHEN p_addressid_clear = true THEN NULL ELSE COALESCE(p_addressid, NULL) END,
                CASE WHEN p_activitysyncconnectionid_clear = true THEN NULL ELSE COALESCE(p_activitysyncconnectionid, NULL) END,
                CASE WHEN p_details_clear = true THEN NULL ELSE COALESCE(p_details, NULL) END,
                CASE WHEN p_sentimentscore_clear = true THEN NULL ELSE COALESCE(p_sentimentscore, NULL) END
        )
    ;

    RETURN QUERY
    SELECT * FROM "__mj_bizappscommon"."vwActivities"
    WHERE "ID" = v_new_id;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spCreateActivity" TO "cdp_Developer";
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spCreateActivity" TO "cdp_Integration";


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Activities
-- Item: spUpdateActivity

-- ============================================================

------------------------------------------------------------
----- UPDATE FUNCTION FOR Activity
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spUpdateActivity'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spUpdateActivity"(
    p_id UUID,
    p_activitytypeid UUID DEFAULT NULL,
    p_startedat TIMESTAMPTZ DEFAULT NULL,
    p_endedat_clear boolean DEFAULT false,
    p_endedat TIMESTAMPTZ DEFAULT NULL,
    p_title varchar(500) DEFAULT NULL,
    p_description_clear boolean DEFAULT false,
    p_description TEXT DEFAULT NULL,
    p_direction varchar(20) DEFAULT NULL,
    p_status varchar(20) DEFAULT NULL,
    p_outcome_clear boolean DEFAULT false,
    p_outcome varchar(40) DEFAULT NULL,
    p_visibility varchar(20) DEFAULT NULL,
    p_source varchar(20) DEFAULT NULL,
    p_sourcesystem_clear boolean DEFAULT false,
    p_sourcesystem varchar(80) DEFAULT NULL,
    p_externalid_clear boolean DEFAULT false,
    p_externalid varchar(400) DEFAULT NULL,
    p_externalthreadid_clear boolean DEFAULT false,
    p_externalthreadid varchar(400) DEFAULT NULL,
    p_parentactivityid_clear boolean DEFAULT false,
    p_parentactivityid UUID DEFAULT NULL,
    p_loggedbyuserid UUID DEFAULT NULL,
    p_location_clear boolean DEFAULT false,
    p_location varchar(500) DEFAULT NULL,
    p_addressid_clear boolean DEFAULT false,
    p_addressid UUID DEFAULT NULL,
    p_activitysyncconnectionid_clear boolean DEFAULT false,
    p_activitysyncconnectionid UUID DEFAULT NULL,
    p_details_clear boolean DEFAULT false,
    p_details TEXT DEFAULT NULL,
    p_sentimentscore_clear boolean DEFAULT false,
    p_sentimentscore decimal(4, 3) DEFAULT NULL
) RETURNS SETOF "__mj_bizappscommon"."vwActivities" AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE "__mj_bizappscommon"."Activity"
    SET
        "ActivityTypeID" = COALESCE(p_activitytypeid, "ActivityTypeID"),
        "StartedAt" = COALESCE(p_startedat, "StartedAt"),
        "EndedAt" = CASE WHEN p_endedat_clear = true THEN NULL ELSE COALESCE(p_endedat, "EndedAt") END,
        "Title" = COALESCE(p_title, "Title"),
        "Description" = CASE WHEN p_description_clear = true THEN NULL ELSE COALESCE(p_description, "Description") END,
        "Direction" = COALESCE(p_direction, "Direction"),
        "Status" = COALESCE(p_status, "Status"),
        "Outcome" = CASE WHEN p_outcome_clear = true THEN NULL ELSE COALESCE(p_outcome, "Outcome") END,
        "Visibility" = COALESCE(p_visibility, "Visibility"),
        "Source" = COALESCE(p_source, "Source"),
        "SourceSystem" = CASE WHEN p_sourcesystem_clear = true THEN NULL ELSE COALESCE(p_sourcesystem, "SourceSystem") END,
        "ExternalID" = CASE WHEN p_externalid_clear = true THEN NULL ELSE COALESCE(p_externalid, "ExternalID") END,
        "ExternalThreadID" = CASE WHEN p_externalthreadid_clear = true THEN NULL ELSE COALESCE(p_externalthreadid, "ExternalThreadID") END,
        "ParentActivityID" = CASE WHEN p_parentactivityid_clear = true THEN NULL ELSE COALESCE(p_parentactivityid, "ParentActivityID") END,
        "LoggedByUserID" = COALESCE(p_loggedbyuserid, "LoggedByUserID"),
        "Location" = CASE WHEN p_location_clear = true THEN NULL ELSE COALESCE(p_location, "Location") END,
        "AddressID" = CASE WHEN p_addressid_clear = true THEN NULL ELSE COALESCE(p_addressid, "AddressID") END,
        "ActivitySyncConnectionID" = CASE WHEN p_activitysyncconnectionid_clear = true THEN NULL ELSE COALESCE(p_activitysyncconnectionid, "ActivitySyncConnectionID") END,
        "Details" = CASE WHEN p_details_clear = true THEN NULL ELSE COALESCE(p_details, "Details") END,
        "SentimentScore" = CASE WHEN p_sentimentscore_clear = true THEN NULL ELSE COALESCE(p_sentimentscore, "SentimentScore") END
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        -- Nothing was updated, return empty result set
        RETURN;
    END IF;

    -- Return the updated record from the base view
    RETURN QUERY
    SELECT * FROM "__mj_bizappscommon"."vwActivities"
    WHERE "ID" = p_id;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spUpdateActivity" TO "cdp_Developer";
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spUpdateActivity" TO "cdp_Integration";


------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Activity table
------------------------------------------------------------
CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."fn_trg_update_activity"()
RETURNS TRIGGER AS $$
BEGIN
    NEW."__mj_UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS "trg_update_activity" ON "__mj_bizappscommon"."Activity";

CREATE TRIGGER "trg_update_activity"
BEFORE UPDATE ON "__mj_bizappscommon"."Activity"
FOR EACH ROW
EXECUTE FUNCTION "__mj_bizappscommon"."fn_trg_update_activity"();



-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Activities
-- Item: spDeleteActivity

-- ============================================================

------------------------------------------------------------
----- DELETE FUNCTION FOR Activity
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spDeleteActivity'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spDeleteActivity"(
    p_id UUID
) RETURNS TABLE("ID" UUID) AS $$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
BEGIN

    DELETE FROM "__mj_bizappscommon"."Activity"
    WHERE "ID" = p_id;

    GET DIAGNOSTICS v_affected_count = ROW_COUNT;

    IF v_affected_count = 0 THEN
        RETURN QUERY SELECT NULL::UUID AS "ID";
    ELSE
        RETURN QUERY SELECT p_id AS "ID";
    END IF;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spDeleteActivity" TO "cdp_Developer";
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spDeleteActivity" TO "cdp_Integration";
