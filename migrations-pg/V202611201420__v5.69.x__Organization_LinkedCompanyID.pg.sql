-- =============================================================================================
-- PostgreSQL counterpart of V202611201420__v5.69.x__Organization_LinkedCompanyID.sql
-- =============================================================================================
-- `mj migrate convert` (MJ CLI 6.3.0-edge.2) output, finished by hand:
--   * The two vwOrganizations grant blocks the converter nested inside each other (a syntax
--     error) are written as flat statements.
--   * The converter dropped two statements, added back: the guarded EntityUniqueKey row for
--     UQ_Organization_LinkedCompanyID, and the RelatedEntityNameFieldMap call for LinkedCompanyID.
--   * The schema is lowercased in CREATE SCHEMA, search_path and the view-rebuild block, so the
--     dependent-view rebuild finds the view when its column list changes.
--   * Then `node scripts/pg-finalize.mjs`, which adds the DROP VIEW before the view block.
--   * NULLS NOT DISTINCT is removed from the unique index: the index already skips NULLs, and
--     the clause needs PostgreSQL 15.
-- Schema names elsewhere are written unquoted, as the converter emits them, so they fold to the
-- lowercase schema a PostgreSQL install uses.
-- =============================================================================================

-- ============================================================================
-- MemberJunction PostgreSQL Migration
-- Converted from SQL Server using TypeScript conversion pipeline
-- ============================================================================

-- Extensions
-- None required: UUID defaults use the built-in gen_random_uuid() (PostgreSQL 13+).

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
-- Migration: V202611201420__v5.69.x__Organization_LinkedCompanyID.sql
-- Description: Add Organization.LinkedCompanyID (optional 1:1 link to __mj."Company")
--              so internal legal entities mirrored from MJ: Companies and external
--              client/partner organizations share Organization as the canonical
--              entity across BizApps (symmetric with Person.LinkedUserID).
-- =============================================================================

ALTER TABLE __mj_BizAppsCommon."Organization"
 ADD COLUMN IF NOT EXISTS "LinkedCompanyID" UUID NULL;

CREATE UNIQUE  INDEX IF NOT EXISTS "UQ_Organization_LinkedCompanyID"
    ON __mj_BizAppsCommon."Organization" ("LinkedCompanyID")
    WHERE "LinkedCompanyID" IS NOT NULL;

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Organization_OrganizationTypeID" ON __mj_BizAppsCommon."Organization" ("OrganizationTypeID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Organization_ParentID" ON __mj_BizAppsCommon."Organization" ("ParentID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Organization_LinkedCompanyID" ON __mj_BizAppsCommon."Organization" ("LinkedCompanyID");


-- ===================== Helper Functions (fn*) =====================

DO $$ DECLARE r record;
BEGIN
  FOR r IN SELECT oid::regprocedure AS sig FROM pg_proc
           WHERE proname = 'fnOrganizationParentID_GetHierarchyMeta'
             AND pronamespace = '__mj_BizAppsCommon'::regnamespace
  LOOP EXECUTE 'DROP FUNCTION IF EXISTS ' || r.sig || ' CASCADE';
  END LOOP;
END $$;
CREATE OR REPLACE FUNCTION __mj_BizAppsCommon."fnOrganizationParentID_GetHierarchyMeta"(
    p_RecordID UUID,
    p_ParentID UUID
)
RETURNS TABLE("RootID" UUID, "Depth" INTEGER, "Path" TEXT, "IsLeaf" BOOLEAN, "ChildCount" INTEGER) AS $$
WITH RECURSIVE CTE_Ancestors AS (
        SELECT
            "ID",
            "ParentID",
            0 AS "Depth",
            CAST('/' || CAST("ID" AS VARCHAR(36)) || '/' AS TEXT) AS "Path"
        FROM
            __mj_BizAppsCommon."Organization"
        WHERE
            "ID" = p_RecordID

        UNION ALL

        SELECT
            p."ID",
            p."ParentID",
            c."Depth" + 1 AS "Depth",
            CAST('/' || CAST(p."ID" AS VARCHAR(36)) || c."Path" AS TEXT) AS "Path"
        FROM
            __mj_BizAppsCommon."Organization" p
        INNER JOIN
            CTE_Ancestors c ON p."ID" = c."ParentID"
        WHERE
            c."Depth" < 100
    )
    SELECT         a."ID" AS "RootID",
        a."Depth" AS "Depth",
        a."Path" AS "Path",
        CAST(CASE WHEN ch."ChildCount" > 0 THEN 0 ELSE 1 END AS BOOLEAN) AS "IsLeaf",
        ch."ChildCount" AS "ChildCount"
    FROM
        CTE_Ancestors a
    LEFT JOIN LATERAL (
        SELECT COUNT(1) AS "ChildCount"
        FROM __mj_BizAppsCommon."Organization"
        WHERE "ParentID" = p_RecordID
    ) ch
    ON TRUE
    WHERE
        a."ParentID" IS NULL OR p_ParentID IS NULL
    ORDER BY
        a."Depth" DESC

LIMIT 1
$$ LANGUAGE sql;

DO $$ DECLARE r record;
BEGIN
  FOR r IN SELECT oid::regprocedure AS sig FROM pg_proc
           WHERE proname = 'fnOrganizationParentID_GetDescendants'
             AND pronamespace = '__mj_BizAppsCommon'::regnamespace
  LOOP EXECUTE 'DROP FUNCTION IF EXISTS ' || r.sig || ' CASCADE';
  END LOOP;
END $$;
CREATE OR REPLACE FUNCTION __mj_BizAppsCommon."fnOrganizationParentID_GetDescendants"(
    p_RootID UUID,
    p_MaxDepth INTEGER = NULL
)
RETURNS TABLE("ID" UUID, "Depth" INTEGER, "Path" TEXT, "IsLeaf" BOOLEAN, "ChildCount" INTEGER) AS $$
WITH RECURSIVE CTE_Descendants AS (
        SELECT
            "ID",
            "ParentID",
            0 AS "RelativeDepth",
            CAST('/' || CAST("ID" AS VARCHAR(36)) || '/' AS TEXT) AS "Path"
        FROM
            __mj_BizAppsCommon."Organization"
        WHERE
            "ID" = p_RootID

        UNION ALL

        SELECT
            c."ID",
            c."ParentID",
            p."RelativeDepth" + 1 AS "RelativeDepth",
            CAST(p."Path" || CAST(c."ID" AS VARCHAR(36)) || '/' AS TEXT) AS "Path"
        FROM
            __mj_BizAppsCommon."Organization" c
        INNER JOIN
            CTE_Descendants p ON c."ParentID" = p."ID"
        WHERE
            (p_MaxDepth IS NULL OR p."RelativeDepth" < p_MaxDepth)
            AND p."RelativeDepth" < 100
    )
    SELECT
        d."ID" AS "ID",
        d."RelativeDepth" AS "Depth",
        d."Path",
        CAST(CASE WHEN EXISTS (SELECT 1 FROM __mj_BizAppsCommon."Organization" WHERE "ParentID" = d."ID") THEN 0 ELSE 1 END AS BOOLEAN) AS "IsLeaf",
        (SELECT COUNT(1) FROM __mj_BizAppsCommon."Organization" WHERE "ParentID" = d."ID") AS "ChildCount"
    FROM
        CTE_Descendants d
$$ LANGUAGE sql;

DO $$ DECLARE r record;
BEGIN
  FOR r IN SELECT oid::regprocedure AS sig FROM pg_proc
           WHERE proname = 'fnOrganizationParentID_GetAncestors'
             AND pronamespace = '__mj_BizAppsCommon'::regnamespace
  LOOP EXECUTE 'DROP FUNCTION IF EXISTS ' || r.sig || ' CASCADE';
  END LOOP;
END $$;
CREATE OR REPLACE FUNCTION __mj_BizAppsCommon."fnOrganizationParentID_GetAncestors"(
    p_RecordID UUID
)
RETURNS TABLE("ID" UUID, "LevelUp" INTEGER, "Path" TEXT) AS $$
WITH RECURSIVE CTE_Ancestors AS (
        SELECT
            "ID",
            "ParentID",
            0 AS "LevelUp",
            CAST('/' || CAST("ID" AS VARCHAR(36)) || '/' AS TEXT) AS "Path"
        FROM
            __mj_BizAppsCommon."Organization"
        WHERE
            "ID" = p_RecordID

        UNION ALL

        SELECT
            p."ID",
            p."ParentID",
            c."LevelUp" + 1 AS "LevelUp",
            CAST('/' || CAST(p."ID" AS VARCHAR(36)) || c."Path" AS TEXT) AS "Path"
        FROM
            __mj_BizAppsCommon."Organization" p
        INNER JOIN
            CTE_Ancestors c ON p."ID" = c."ParentID"
        WHERE
            c."LevelUp" < 100
    )
    SELECT
        a."ID" AS "ID",
        a."LevelUp",
        a."Path"
    FROM
        CTE_Ancestors a
$$ LANGUAGE sql;

DO $$ DECLARE r record;
BEGIN
  FOR r IN SELECT oid::regprocedure AS sig FROM pg_proc
           WHERE proname = 'fnOrganizationParentID_GetRootID'
             AND pronamespace = '__mj_BizAppsCommon'::regnamespace
  LOOP EXECUTE 'DROP FUNCTION IF EXISTS ' || r.sig || ' CASCADE';
  END LOOP;
END $$;
CREATE OR REPLACE FUNCTION __mj_BizAppsCommon."fnOrganizationParentID_GetRootID"(
    p_RecordID UUID,
    p_ParentID UUID
)
RETURNS TABLE("RootID" UUID) AS $$
WITH RECURSIVE CTE_RootParent AS (
        SELECT
            "ID",
            "ParentID",
            "ID" AS "RootParentID",
            0 AS "Depth"
        FROM
            __mj_BizAppsCommon."Organization"
        WHERE
            "ID" = COALESCE(p_ParentID, p_RecordID)

        UNION ALL

        SELECT
            c."ID",
            c."ParentID",
            c."ID" AS "RootParentID",
            p."Depth" + 1 AS "Depth"
        FROM
            __mj_BizAppsCommon."Organization" c
        INNER JOIN
            CTE_RootParent p ON c."ID" = p."ParentID"
        WHERE
            p."Depth" < 100
    )
    SELECT         "RootParentID" AS RootID
    FROM
        CTE_RootParent
    WHERE
        "ParentID" IS NULL
    ORDER BY
        "RootParentID"

LIMIT 1
$$ LANGUAGE sql;


-- ===================== Views =====================

DROP VIEW IF EXISTS __mj_BizAppsCommon."vwOrganizationsGenerated" CASCADE;
DO $do$
DECLARE
  v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
  v_target_name CONSTANT TEXT := 'vwOrganizationsGenerated';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwOrganizationsGenerated"
AS SELECT
    o.*,
    "mjBizAppsCommonOrganizationType_OrganizationTypeID"."Name" AS "OrganizationType",
    "mjBizAppsCommonOrganization_ParentID"."Name" AS "Parent",
    "MJCompany_LinkedCompanyID"."Name" AS "LinkedCompany",
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
LEFT OUTER JOIN
    ${mjSchema}."Company" AS "MJCompany_LinkedCompanyID"
  ON
    o."LinkedCompanyID" = "MJCompany_LinkedCompanyID"."ID"
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

DO $$ DECLARE r record;
BEGIN
  FOR r IN SELECT oid::regprocedure AS sig FROM pg_proc
           WHERE proname = 'spCreateOrganization'
             AND pronamespace = '__mj_BizAppsCommon'::regnamespace
  LOOP EXECUTE 'DROP FUNCTION IF EXISTS ' || r.sig || ' CASCADE';
  END LOOP;
END $$;
CREATE OR REPLACE FUNCTION __mj_BizAppsCommon."spCreateOrganization"(
    IN p_ID UUID DEFAULT NULL,
    IN p_Name VARCHAR(255) DEFAULT NULL,
    IN p_LegalName_Clear BOOLEAN DEFAULT FALSE,
    IN p_LegalName VARCHAR(255) DEFAULT NULL,
    IN p_OrganizationTypeID_Clear BOOLEAN DEFAULT FALSE,
    IN p_OrganizationTypeID UUID DEFAULT NULL,
    IN p_ParentID_Clear BOOLEAN DEFAULT FALSE,
    IN p_ParentID UUID DEFAULT NULL,
    IN p_Website_Clear BOOLEAN DEFAULT FALSE,
    IN p_Website VARCHAR(1000) DEFAULT NULL,
    IN p_LogoURL_Clear BOOLEAN DEFAULT FALSE,
    IN p_LogoURL TEXT DEFAULT NULL,
    IN p_Description_Clear BOOLEAN DEFAULT FALSE,
    IN p_Description TEXT DEFAULT NULL,
    IN p_Email_Clear BOOLEAN DEFAULT FALSE,
    IN p_Email VARCHAR(255) DEFAULT NULL,
    IN p_Phone_Clear BOOLEAN DEFAULT FALSE,
    IN p_Phone VARCHAR(50) DEFAULT NULL,
    IN p_FoundedDate_Clear BOOLEAN DEFAULT FALSE,
    IN p_FoundedDate DATE DEFAULT NULL,
    IN p_TaxID_Clear BOOLEAN DEFAULT FALSE,
    IN p_TaxID VARCHAR(50) DEFAULT NULL,
    IN p_Status VARCHAR(50) DEFAULT NULL,
    IN p_Acronym_Clear BOOLEAN DEFAULT FALSE,
    IN p_Acronym VARCHAR(20) DEFAULT NULL,
    IN p_LinkedCompanyID_Clear BOOLEAN DEFAULT FALSE,
    IN p_LinkedCompanyID UUID DEFAULT NULL
)
RETURNS SETOF __mj_BizAppsCommon."vwOrganizations" AS
$$
BEGIN
IF p_ID IS NOT NULL THEN
        -- User provided a value, use it
        INSERT INTO __mj_BizAppsCommon."Organization"
            (
                "ID",
                "Name",
                "LegalName",
                "OrganizationTypeID",
                "ParentID",
                "Website",
                "LogoURL",
                "Description",
                "Email",
                "Phone",
                "FoundedDate",
                "TaxID",
                "Status",
                "Acronym",
                "LinkedCompanyID"
            )
        VALUES
            (
                p_ID,
                p_Name,
                CASE WHEN p_LegalName_Clear = TRUE THEN NULL ELSE COALESCE(p_LegalName, NULL) END,
                CASE WHEN p_OrganizationTypeID_Clear = TRUE THEN NULL ELSE COALESCE(p_OrganizationTypeID, NULL) END,
                CASE WHEN p_ParentID_Clear = TRUE THEN NULL ELSE COALESCE(p_ParentID, NULL) END,
                CASE WHEN p_Website_Clear = TRUE THEN NULL ELSE COALESCE(p_Website, NULL) END,
                CASE WHEN p_LogoURL_Clear = TRUE THEN NULL ELSE COALESCE(p_LogoURL, NULL) END,
                CASE WHEN p_Description_Clear = TRUE THEN NULL ELSE COALESCE(p_Description, NULL) END,
                CASE WHEN p_Email_Clear = TRUE THEN NULL ELSE COALESCE(p_Email, NULL) END,
                CASE WHEN p_Phone_Clear = TRUE THEN NULL ELSE COALESCE(p_Phone, NULL) END,
                CASE WHEN p_FoundedDate_Clear = TRUE THEN NULL ELSE COALESCE(p_FoundedDate, NULL) END,
                CASE WHEN p_TaxID_Clear = TRUE THEN NULL ELSE COALESCE(p_TaxID, NULL) END,
                COALESCE(p_Status, 'Active'),
                CASE WHEN p_Acronym_Clear = TRUE THEN NULL ELSE COALESCE(p_Acronym, NULL) END,
                CASE WHEN p_LinkedCompanyID_Clear = TRUE THEN NULL ELSE COALESCE(p_LinkedCompanyID, NULL) END
            );
    ELSE
        -- No value provided, let database use its default (e.g., gen_random_uuid())
        INSERT INTO __mj_BizAppsCommon."Organization"
            (
                "Name",
                "LegalName",
                "OrganizationTypeID",
                "ParentID",
                "Website",
                "LogoURL",
                "Description",
                "Email",
                "Phone",
                "FoundedDate",
                "TaxID",
                "Status",
                "Acronym",
                "LinkedCompanyID"
            )
        VALUES
            (
                p_Name,
                CASE WHEN p_LegalName_Clear = TRUE THEN NULL ELSE COALESCE(p_LegalName, NULL) END,
                CASE WHEN p_OrganizationTypeID_Clear = TRUE THEN NULL ELSE COALESCE(p_OrganizationTypeID, NULL) END,
                CASE WHEN p_ParentID_Clear = TRUE THEN NULL ELSE COALESCE(p_ParentID, NULL) END,
                CASE WHEN p_Website_Clear = TRUE THEN NULL ELSE COALESCE(p_Website, NULL) END,
                CASE WHEN p_LogoURL_Clear = TRUE THEN NULL ELSE COALESCE(p_LogoURL, NULL) END,
                CASE WHEN p_Description_Clear = TRUE THEN NULL ELSE COALESCE(p_Description, NULL) END,
                CASE WHEN p_Email_Clear = TRUE THEN NULL ELSE COALESCE(p_Email, NULL) END,
                CASE WHEN p_Phone_Clear = TRUE THEN NULL ELSE COALESCE(p_Phone, NULL) END,
                CASE WHEN p_FoundedDate_Clear = TRUE THEN NULL ELSE COALESCE(p_FoundedDate, NULL) END,
                CASE WHEN p_TaxID_Clear = TRUE THEN NULL ELSE COALESCE(p_TaxID, NULL) END,
                COALESCE(p_Status, 'Active'),
                CASE WHEN p_Acronym_Clear = TRUE THEN NULL ELSE COALESCE(p_Acronym, NULL) END,
                CASE WHEN p_LinkedCompanyID_Clear = TRUE THEN NULL ELSE COALESCE(p_LinkedCompanyID, NULL) END
            );
    END IF;
    -- return the new record from the base view, which might have some calculated fields
    RETURN QUERY SELECT * FROM __mj_BizAppsCommon."vwOrganizations" WHERE "ID" = p_ID;
END;
$$ LANGUAGE plpgsql;

DO $$ DECLARE r record;
BEGIN
  FOR r IN SELECT oid::regprocedure AS sig FROM pg_proc
           WHERE proname = 'spUpdateOrganization'
             AND pronamespace = '__mj_BizAppsCommon'::regnamespace
  LOOP EXECUTE 'DROP FUNCTION IF EXISTS ' || r.sig || ' CASCADE';
  END LOOP;
END $$;
CREATE OR REPLACE FUNCTION __mj_BizAppsCommon."spUpdateOrganization"(
    IN p_ID UUID,
    IN p_Name VARCHAR(255) DEFAULT NULL,
    IN p_LegalName_Clear BOOLEAN DEFAULT FALSE,
    IN p_LegalName VARCHAR(255) DEFAULT NULL,
    IN p_OrganizationTypeID_Clear BOOLEAN DEFAULT FALSE,
    IN p_OrganizationTypeID UUID DEFAULT NULL,
    IN p_ParentID_Clear BOOLEAN DEFAULT FALSE,
    IN p_ParentID UUID DEFAULT NULL,
    IN p_Website_Clear BOOLEAN DEFAULT FALSE,
    IN p_Website VARCHAR(1000) DEFAULT NULL,
    IN p_LogoURL_Clear BOOLEAN DEFAULT FALSE,
    IN p_LogoURL TEXT DEFAULT NULL,
    IN p_Description_Clear BOOLEAN DEFAULT FALSE,
    IN p_Description TEXT DEFAULT NULL,
    IN p_Email_Clear BOOLEAN DEFAULT FALSE,
    IN p_Email VARCHAR(255) DEFAULT NULL,
    IN p_Phone_Clear BOOLEAN DEFAULT FALSE,
    IN p_Phone VARCHAR(50) DEFAULT NULL,
    IN p_FoundedDate_Clear BOOLEAN DEFAULT FALSE,
    IN p_FoundedDate DATE DEFAULT NULL,
    IN p_TaxID_Clear BOOLEAN DEFAULT FALSE,
    IN p_TaxID VARCHAR(50) DEFAULT NULL,
    IN p_Status VARCHAR(50) DEFAULT NULL,
    IN p_Acronym_Clear BOOLEAN DEFAULT FALSE,
    IN p_Acronym VARCHAR(20) DEFAULT NULL,
    IN p_LinkedCompanyID_Clear BOOLEAN DEFAULT FALSE,
    IN p_LinkedCompanyID UUID DEFAULT NULL
)
RETURNS SETOF __mj_BizAppsCommon."vwOrganizations" AS
$$
DECLARE
    _v_row_count INTEGER;
BEGIN
UPDATE
        __mj_BizAppsCommon."Organization"
    SET
        "Name" = COALESCE(p_Name, "Name"),
        "LegalName" = CASE WHEN p_LegalName_Clear = TRUE THEN NULL ELSE COALESCE(p_LegalName, "LegalName") END,
        "OrganizationTypeID" = CASE WHEN p_OrganizationTypeID_Clear = TRUE THEN NULL ELSE COALESCE(p_OrganizationTypeID, "OrganizationTypeID") END,
        "ParentID" = CASE WHEN p_ParentID_Clear = TRUE THEN NULL ELSE COALESCE(p_ParentID, "ParentID") END,
        "Website" = CASE WHEN p_Website_Clear = TRUE THEN NULL ELSE COALESCE(p_Website, "Website") END,
        "LogoURL" = CASE WHEN p_LogoURL_Clear = TRUE THEN NULL ELSE COALESCE(p_LogoURL, "LogoURL") END,
        "Description" = CASE WHEN p_Description_Clear = TRUE THEN NULL ELSE COALESCE(p_Description, "Description") END,
        "Email" = CASE WHEN p_Email_Clear = TRUE THEN NULL ELSE COALESCE(p_Email, "Email") END,
        "Phone" = CASE WHEN p_Phone_Clear = TRUE THEN NULL ELSE COALESCE(p_Phone, "Phone") END,
        "FoundedDate" = CASE WHEN p_FoundedDate_Clear = TRUE THEN NULL ELSE COALESCE(p_FoundedDate, "FoundedDate") END,
        "TaxID" = CASE WHEN p_TaxID_Clear = TRUE THEN NULL ELSE COALESCE(p_TaxID, "TaxID") END,
        "Status" = COALESCE(p_Status, "Status"),
        "Acronym" = CASE WHEN p_Acronym_Clear = TRUE THEN NULL ELSE COALESCE(p_Acronym, "Acronym") END,
        "LinkedCompanyID" = CASE WHEN p_LinkedCompanyID_Clear = TRUE THEN NULL ELSE COALESCE(p_LinkedCompanyID, "LinkedCompanyID") END,
        "__mj_UpdatedAt" = NOW()
    WHERE
        "ID" = p_ID;

    GET DIAGNOSTICS _v_row_count = ROW_COUNT;

    IF _v_row_count = 0 THEN
        RETURN QUERY SELECT * FROM __mj_BizAppsCommon."vwOrganizations" WHERE 1=0;
    ELSE
        RETURN QUERY SELECT * FROM __mj_BizAppsCommon."vwOrganizations" WHERE "ID" = p_ID;
    END IF;
END;
$$ LANGUAGE plpgsql;

DO $$ DECLARE r record;
BEGIN
  FOR r IN SELECT oid::regprocedure AS sig FROM pg_proc
           WHERE proname = 'spDeleteOrganization'
             AND pronamespace = '__mj_BizAppsCommon'::regnamespace
  LOOP EXECUTE 'DROP FUNCTION IF EXISTS ' || r.sig || ' CASCADE';
  END LOOP;
END $$;
CREATE OR REPLACE FUNCTION __mj_BizAppsCommon."spDeleteOrganization"(
    IN p_ID UUID
)
RETURNS TABLE("_result_id" UUID) AS
$$
DECLARE
    _v_row_count INTEGER;
BEGIN
DELETE FROM
        __mj_BizAppsCommon."Organization"
    WHERE
        "ID" = p_ID;

    GET DIAGNOSTICS _v_row_count = ROW_COUNT;

    IF _v_row_count = 0 THEN
        RETURN QUERY SELECT NULL::UUID AS "_result_id";
    ELSE
        RETURN QUERY SELECT p_ID::UUID AS "_result_id";
    END IF;
END;
$$ LANGUAGE plpgsql;


-- ===================== Triggers =====================

CREATE OR REPLACE FUNCTION __mj_BizAppsCommon."trgUpdateOrganization_func"()
RETURNS TRIGGER AS $$
BEGIN
    NEW."__mj_UpdatedAt" = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS "trgUpdateOrganization" ON __mj_BizAppsCommon."Organization";
CREATE TRIGGER "trgUpdateOrganization"
    BEFORE UPDATE ON __mj_BizAppsCommon."Organization"
    FOR EACH ROW
    EXECUTE FUNCTION __mj_BizAppsCommon."trgUpdateOrganization_func"();


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ${mjSchema}."EntityField" WHERE "ID" = '04b281b0-5773-482c-a550-5bddfa23011e' OR ("EntityID" = 'C70448F9-9792-41D7-A82C-784B66429D54' AND "Name" = 'LinkedCompanyID')
    ) THEN
        INSERT INTO ${mjSchema}."EntityField"
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
        '04b281b0-5773-482c-a550-5bddfa23011e',
        'C70448F9-9792-41D7-A82C-784B66429D54', -- "Entity": "MJ_BizApps_Common": "Organizations"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM ${mjSchema}."EntityField" WHERE "EntityID" = 'C70448F9-9792-41D7-A82C-784B66429D54'),
        'LinkedCompanyID',
        'Linked Company ID',
        'Optional 1:1 foreign key to the MJ: Companies record mirrored by this Organization (enforced unique when non-null via UQ_Organization_LinkedCompanyID). Enables internal legal entities and external client/partner organizations to share Organization as the single canonical entity across BizApps.',
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
        'D4238F34-2837-EF11-86D4-6045BDEE16E6',
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
        SELECT 1 FROM ${mjSchema}."EntityRelationship" WHERE "ID" = 'ef95017c-7c4c-4eeb-945f-b26259ff43ea' OR ("EntityID" = 'D4238F34-2837-EF11-86D4-6045BDEE16E6' AND "RelatedEntityID" = 'C70448F9-9792-41D7-A82C-784B66429D54' AND "RelatedEntityJoinField" = 'LinkedCompanyID')
    ) THEN
        INSERT INTO ${mjSchema}."EntityRelationship" ("ID", "EntityID", "RelatedEntityID", "RelatedEntityJoinField", "Type", "BundleInAPI", "DisplayInForm", "Sequence", "__mj_CreatedAt", "__mj_UpdatedAt")
        VALUES ('ef95017c-7c4c-4eeb-945f-b26259ff43ea', 'D4238F34-2837-EF11-86D4-6045BDEE16E6', 'C70448F9-9792-41D7-A82C-784B66429D54', 'LinkedCompanyID', 'One To Many', TRUE, TRUE, 12, NOW(), NOW());
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ${mjSchema}."EntityField" WHERE "ID" = '79143329-b73c-4405-8349-3a45b6ec91fc' OR ("EntityID" = 'C70448F9-9792-41D7-A82C-784B66429D54' AND "Name" = 'LinkedCompany')
    ) THEN
        INSERT INTO ${mjSchema}."EntityField"
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
        '79143329-b73c-4405-8349-3a45b6ec91fc',
        'C70448F9-9792-41D7-A82C-784B66429D54', -- "Entity": "MJ_BizApps_Common": "Organizations"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM ${mjSchema}."EntityField" WHERE "EntityID" = 'C70448F9-9792-41D7-A82C-784B66429D54'),
        'LinkedCompany',
        'Linked Company',
        NULL,
        'nvarchar',
        100,
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

UPDATE ${mjSchema}."EntityField"
SET 
   "Category" = 'Organization Identity',
   "GeneratedFormSection" = 'Category',
   "DisplayName" = 'Linked Company'
WHERE 
   "ID" = '04B281B0-5773-482C-A550-5BDDFA23011E';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Organizations.LinkedCompany

UPDATE ${mjSchema}."EntityField"
SET 
   "Category" = 'Organization Identity',
   "GeneratedFormSection" = 'Category',
   "DisplayName" = 'Linked Company Name'
WHERE 
   "ID" = '79143329-B73C-4405-8349-3A45B6EC91FC';


-- Unique key for UQ_Organization_LinkedCompanyID (only where MJ core has EntityUniqueKey).
DO $$
BEGIN
    IF to_regclass('${mjSchema}."EntityUniqueKey"') IS NOT NULL THEN
        EXECUTE $q$
            INSERT INTO ${mjSchema}."EntityUniqueKey" ("ID", "EntityID", "Name", "FieldNames", "FilterDefinition")
            SELECT 'fb65ca12-a867-400a-9b19-9a2eb1b594dc', 'C70448F9-9792-41D7-A82C-784B66429D54', 'UQ_Organization_LinkedCompanyID', 'LinkedCompanyID', '("LinkedCompanyID" IS NOT NULL)'
            WHERE NOT EXISTS (SELECT 1 FROM ${mjSchema}."EntityUniqueKey" WHERE "EntityID" = 'C70448F9-9792-41D7-A82C-784B66429D54' AND "Name" = 'UQ_Organization_LinkedCompanyID')
        $q$;
    END IF;
END $$;

SELECT ${mjSchema}."spUpdateEntityFieldRelatedEntityNameFieldMap"('04B281B0-5773-482C-A550-5BDDFA23011E'::uuid, 'LinkedCompany');

-- ===================== FK & CHECK Constraints =====================


-- Flush any pending deferred trigger events from prior DML so DDL below can proceed.
SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE __mj_BizAppsCommon."Organization"
 ADD CONSTRAINT "FK_Organization_LinkedCompany"
        FOREIGN KEY ("LinkedCompanyID") REFERENCES ${mjSchema}."Company"("ID") DEFERRABLE INITIALLY DEFERRED;


-- ===================== Grants =====================

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwOrganizations" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwOrganizations" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwOrganizations" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwOrganizations" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;

DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwOrganizations" FROM "cdp_Developer"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwOrganizations" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN REVOKE SELECT ON __mj_BizAppsCommon."vwOrganizations" FROM "cdp_UI"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwOrganizations" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;

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
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteOrganization" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Organizations */

DO $$ BEGIN REVOKE EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteOrganization" FROM "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteOrganization" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Index for Foreign Keys for Person */
-----------------------------------------------------------------;


-- ===================== Comments =====================

COMMENT ON COLUMN __mj_BizAppsCommon."Organization"."LinkedCompanyID" IS 'Optional 1:1 foreign key to the MJ: Companies record mirrored by this Organization (enforced unique when non-null via UQ_Organization_LinkedCompanyID). Enables internal legal entities and external client/partner organizations to share Organization as the single canonical entity across BizApps.';


-- ===================== Other =====================

-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key OrganizationTypeID in table Organization
-- Skipped when the index exists or another unfiltered index already leads with the column.

-- WARNING: sp_refreshview '__mj_BizAppsCommon.vwOrganizationsGenerated' has no PostgreSQL equivalent; rebuild the view with CREATE OR REPLACE VIEW so it carries the new columns

/* Base View Permissions SQL for MJ_BizApps_Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: Permissions for vwOrganizations
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

/* spUpdate Permissions for MJ_BizApps_Common: Organizations */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Organizations.LinkedCompanyID
