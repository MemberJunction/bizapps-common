-- @mj-pg-provenance: split-bake v1 source=V202611261245__v6.3.x__Activity_ArtifactID.sql source-sha256=a680a56ac0770010d3249ebf9734392068e9356ee4532f14dfb178ce7b006f90 mode=needs-hand-rebaked
-- ============================================================================
-- MemberJunction PostgreSQL Migration — V202611261245__v6.3.x__Activity_ArtifactID.sql
-- Split-and-regenerate with INLINE NATIVE CodeGen baking: hand-written DDL transpiled
-- (AST dialect), metadata DML inline, and CodeGen objects (views/sprocs/triggers/grants)
-- baked natively from `mj codegen`. Applies standalone via `mj migrate` — no deploy codegen.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE SCHEMA IF NOT EXISTS __mj_bizappscommon;
SET search_path TO __mj_bizappscommon, public;
SET standard_conforming_strings = on;

ALTER TABLE __mj_bizappscommon."Activity"
ADD COLUMN "ArtifactID" UUID NULL /* ============================================================================= */ /* Migration: V202611261245__v6.3.x__Activity_ArtifactID.sql */ /* Description: Add nullable Activity.ArtifactID foreign key referencing */ /*              [__mj].[Artifact]([ID]) with a filtered nonclustered index */ /*              (WHERE [ArtifactID] IS NOT NULL) so Common.Activity remains a */ /*              fast Category B hybrid spine (ArtifactID stays NULL for quick */ /*              notes, calls, meetings, and emails; populated only on opt-in */ /*              MJ Doc link/expansion). Never drops, renames, or narrows */ /*              Description, Details, or any existing column. */ /* ============================================================================= */;

ALTER TABLE __mj_bizappscommon."Activity"
  ADD CONSTRAINT "FK_Activity_Artifact" FOREIGN KEY ("ArtifactID") REFERENCES "__mj"."Artifact" (
    "ID"
  );

CREATE INDEX "IDX_AUTO_MJ_FKEY_Activity_ArtifactID" ON __mj_bizappscommon."Activity"("ArtifactID")
WHERE
  NOT "ArtifactID" IS NULL;

COMMENT ON COLUMN __mj_bizappscommon."Activity"."ArtifactID" IS 'Optional foreign key to an MJ: Artifacts (MJ Doc) record linked to this activity. Remains NULL for frictionless quick notes, calls, meetings, and emails; populated only when a user explicitly links or expands an activity into a rich MJ Doc.';

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM "__mj"."EntityField" WHERE "ID" = 'c5fc4267-5216-4260-9252-7a3469109cff' OR ("EntityID" = '72E55425-8822-4E70-A075-116219CA5A5D' AND "Name" = 'ArtifactID')) THEN
    INSERT INTO "__mj"."EntityField" ("ID", "EntityID", "Sequence", "Name", "DisplayName", "Description", "Type", "Length", "Precision", "Scale", "AllowsNull", "DefaultValue", "AutoIncrement", "AllowUpdateAPI", "IsVirtual", "IsComputed", "RelatedEntityID", "RelatedEntityFieldName", "IsNameField", "IncludeInUserSearchAPI", "IncludeRelatedEntityNameFieldInBaseView", "DefaultInView", "IsPrimaryKey", "IsUnique", "RelatedEntityDisplayType", "__mj_CreatedAt", "__mj_UpdatedAt") VALUES ('c5fc4267-5216-4260-9252-7a3469109cff', '72E55425-8822-4E70-A075-116219CA5A5D' /* Entity: MJ_BizApps_Common: Activities */, (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM "__mj"."EntityField" WHERE "EntityID" = '72E55425-8822-4E70-A075-116219CA5A5D'), 'ArtifactID', 'Artifact ID', 'Optional foreign key to an MJ: Artifacts (MJ Doc) record linked to this activity. Remains NULL for frictionless quick notes, calls, meetings, and emails; populated only when a user explicitly links or expands an activity into a rich MJ Doc.', 'uniqueidentifier', 16, 0, 0, TRUE, NULL, FALSE, TRUE, FALSE, FALSE, 'F48D2341-8667-40BB-BCA8-87D7F80E16CD', 'ID', FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, 'Search', NOW(), NOW());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM "__mj"."EntityRelationship" WHERE "ID" = '4a953b15-558e-485c-998c-8b3ea5c3868e' OR ("EntityID" = 'F48D2341-8667-40BB-BCA8-87D7F80E16CD' AND "RelatedEntityID" = '72E55425-8822-4E70-A075-116219CA5A5D' AND "RelatedEntityJoinField" = 'ArtifactID')) THEN
    INSERT INTO "__mj"."EntityRelationship" ("ID", "EntityID", "RelatedEntityID", "RelatedEntityJoinField", "Type", "BundleInAPI", "DisplayInForm", "Sequence", "__mj_CreatedAt", "__mj_UpdatedAt") VALUES ('4a953b15-558e-485c-998c-8b3ea5c3868e', 'F48D2341-8667-40BB-BCA8-87D7F80E16CD', '72E55425-8822-4E70-A075-116219CA5A5D', 'ArtifactID', 'One To Many', TRUE, TRUE, 6, NOW(), NOW());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM "__mj"."EntityField" WHERE "ID" = '0f6231a0-d75a-4e7d-8126-9b1392f7dc2a' OR ("EntityID" = '72E55425-8822-4E70-A075-116219CA5A5D' AND "Name" = 'Artifact')) THEN
    INSERT INTO "__mj"."EntityField" ("ID", "EntityID", "Sequence", "Name", "DisplayName", "Description", "Type", "Length", "Precision", "Scale", "AllowsNull", "DefaultValue", "AutoIncrement", "AllowUpdateAPI", "IsVirtual", "IsComputed", "RelatedEntityID", "RelatedEntityFieldName", "IsNameField", "IncludeInUserSearchAPI", "IncludeRelatedEntityNameFieldInBaseView", "DefaultInView", "IsPrimaryKey", "IsUnique", "RelatedEntityDisplayType", "__mj_CreatedAt", "__mj_UpdatedAt") VALUES ('0f6231a0-d75a-4e7d-8126-9b1392f7dc2a', '72E55425-8822-4E70-A075-116219CA5A5D' /* Entity: MJ_BizApps_Common: Activities */, (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM "__mj"."EntityField" WHERE "EntityID" = '72E55425-8822-4E70-A075-116219CA5A5D'), 'Artifact', 'Artifact', NULL, 'nvarchar', 510, 0, 0, TRUE, NULL, FALSE, FALSE, TRUE, FALSE, NULL, NULL, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, 'Search', NOW(), NOW());
  END IF;
END $$;

-- Resolve unhandled T-SQL EXEC spUpdateEntityFieldRelatedEntityNameFieldMap (native PG function)
DO $$
BEGIN
  PERFORM __mj."spUpdateEntityFieldRelatedEntityNameFieldMap"(
    p_entityfieldid             := 'c5fc4267-5216-4260-9252-7a3469109cff'::uuid,
    p_relatedentitynamefieldmap := 'Artifact'
  );
END $$;

-- ===================== CodeGen (native PG, baked) =====================

-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Activities
-- Item: Index for Foreign Keys
-- ============================================================
-- Skipped when another non-partial index already leads with the column.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_index ix
        INNER JOIN pg_class t ON t.oid = ix.indrelid
        INNER JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE n.nspname = '__mj_bizappscommon'
          AND t.relname = 'Activity'
          AND ix.indpred IS NULL
          AND ix.indnkeyatts >= 1
              AND ix.indkey[0] = (SELECT a.attnum FROM pg_attribute a WHERE a.attrelid = t.oid AND a.attname = 'ActivityTypeID')
    ) THEN
        CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_activity_activity_type_id"
            ON "__mj_bizappscommon"."Activity" ("ActivityTypeID");
    END IF;
END
$$;

-- Skipped when another non-partial index already leads with the column.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_index ix
        INNER JOIN pg_class t ON t.oid = ix.indrelid
        INNER JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE n.nspname = '__mj_bizappscommon'
          AND t.relname = 'Activity'
          AND ix.indpred IS NULL
          AND ix.indnkeyatts >= 1
              AND ix.indkey[0] = (SELECT a.attnum FROM pg_attribute a WHERE a.attrelid = t.oid AND a.attname = 'ParentActivityID')
    ) THEN
        CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_activity_parent_activity_id"
            ON "__mj_bizappscommon"."Activity" ("ParentActivityID");
    END IF;
END
$$;

-- Skipped when another non-partial index already leads with the column.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_index ix
        INNER JOIN pg_class t ON t.oid = ix.indrelid
        INNER JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE n.nspname = '__mj_bizappscommon'
          AND t.relname = 'Activity'
          AND ix.indpred IS NULL
          AND ix.indnkeyatts >= 1
              AND ix.indkey[0] = (SELECT a.attnum FROM pg_attribute a WHERE a.attrelid = t.oid AND a.attname = 'LoggedByUserID')
    ) THEN
        CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_activity_logged_by_user_id"
            ON "__mj_bizappscommon"."Activity" ("LoggedByUserID");
    END IF;
END
$$;

-- Skipped when another non-partial index already leads with the column.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_index ix
        INNER JOIN pg_class t ON t.oid = ix.indrelid
        INNER JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE n.nspname = '__mj_bizappscommon'
          AND t.relname = 'Activity'
          AND ix.indpred IS NULL
          AND ix.indnkeyatts >= 1
              AND ix.indkey[0] = (SELECT a.attnum FROM pg_attribute a WHERE a.attrelid = t.oid AND a.attname = 'AddressID')
    ) THEN
        CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_activity_address_id"
            ON "__mj_bizappscommon"."Activity" ("AddressID");
    END IF;
END
$$;

-- Skipped when another non-partial index already leads with the column.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_index ix
        INNER JOIN pg_class t ON t.oid = ix.indrelid
        INNER JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE n.nspname = '__mj_bizappscommon'
          AND t.relname = 'Activity'
          AND ix.indpred IS NULL
          AND ix.indnkeyatts >= 1
              AND ix.indkey[0] = (SELECT a.attnum FROM pg_attribute a WHERE a.attrelid = t.oid AND a.attname = 'ActivitySyncConnectionID')
    ) THEN
        CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_activity_activity_sync_connection_id"
            ON "__mj_bizappscommon"."Activity" ("ActivitySyncConnectionID");
    END IF;
END
$$;

-- Skipped when another non-partial index already leads with the column.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_index ix
        INNER JOIN pg_class t ON t.oid = ix.indrelid
        INNER JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE n.nspname = '__mj_bizappscommon'
          AND t.relname = 'Activity'
          AND ix.indpred IS NULL
          AND ix.indnkeyatts >= 1
              AND ix.indkey[0] = (SELECT a.attnum FROM pg_attribute a WHERE a.attrelid = t.oid AND a.attname = 'ArtifactID')
    ) THEN
        CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_activity_artifact_id"
            ON "__mj_bizappscommon"."Activity" ("ArtifactID");
    END IF;
END
$$;

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
        a.depth::INTEGER AS "Depth",
        a.path::TEXT AS "Path",
        (ch.child_count = 0)::BOOLEAN AS "IsLeaf",
        ch.child_count AS "ChildCount"
    FROM
        cte_ancestors a
    CROSS JOIN LATERAL (
        SELECT COUNT(1)::INTEGER AS child_count
        FROM "__mj_bizappscommon"."Activity"
        WHERE "ParentActivityID" = p_record_id
    ) ch
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
    mjbizappscommonAddress_AddressID."DisplayName" AS "Address",
    mjbizappscommonActivitySyncConnection_ActivitySyncConnectionID."Name" AS "ActivitySyncConnection",
    MJArtifact_ArtifactID."Name" AS "Artifact",
    hier_ParentActivityID."RootID" AS "RootParentActivityID",
    hier_ParentActivityID."Depth" AS "ParentActivityIDDepth",
    hier_ParentActivityID."Path" AS "ParentActivityIDPath",
    hier_ParentActivityID."IsLeaf" AS "ParentActivityIDIsLeaf",
    hier_ParentActivityID."ChildCount" AS "ParentActivityIDChildCount"
FROM
    "__mj_bizappscommon"."Activity" AS a
LEFT OUTER JOIN
    "__mj_bizappscommon"."ActivityType" AS mjbizappscommonActivityType_ActivityTypeID
  ON
    "a"."ActivityTypeID" = mjbizappscommonActivityType_ActivityTypeID."ID"
LEFT OUTER JOIN
    "__mj_bizappscommon"."Activity" AS mjbizappscommonActivity_ParentActivityID
  ON
    "a"."ParentActivityID" = mjbizappscommonActivity_ParentActivityID."ID"
LEFT OUTER JOIN
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
LEFT OUTER JOIN
    "__mj"."Artifact" AS MJArtifact_ArtifactID
  ON
    "a"."ArtifactID" = MJArtifact_ArtifactID."ID"

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
    p_sentimentscore decimal(4, 3) DEFAULT NULL,
    p_artifactid_clear boolean DEFAULT false,
    p_artifactid UUID DEFAULT NULL
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
                "SentimentScore",
                "ArtifactID"
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
                CASE WHEN p_sentimentscore_clear = true THEN NULL ELSE COALESCE(p_sentimentscore, NULL) END,
                CASE WHEN p_artifactid_clear = true THEN NULL ELSE COALESCE(p_artifactid, NULL) END
        )
    ;

    RETURN QUERY
    SELECT * FROM "__mj_bizappscommon"."vwActivities"
    WHERE "ID" = v_new_id;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spCreateActivity" TO "cdp_UI";
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
    p_sentimentscore decimal(4, 3) DEFAULT NULL,
    p_artifactid_clear boolean DEFAULT false,
    p_artifactid UUID DEFAULT NULL
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
        "SentimentScore" = CASE WHEN p_sentimentscore_clear = true THEN NULL ELSE COALESCE(p_sentimentscore, "SentimentScore") END,
        "ArtifactID" = CASE WHEN p_artifactid_clear = true THEN NULL ELSE COALESCE(p_artifactid, "ArtifactID") END,
        "__mj_UpdatedAt" = (NOW() AT TIME ZONE 'UTC')
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
