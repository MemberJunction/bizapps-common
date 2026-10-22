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
CREATE SCHEMA IF NOT EXISTS __mj_BizAppsCommon;
SET search_path TO __mj_BizAppsCommon, public;

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

-- HAND-WRITTEN (release work, 22 Oct 2026). The converter cannot translate the T-SQL computed
-- columns: it emitted EmailDomain with CHARINDEX/PERSISTED, commented WebsiteDomain out, put the
-- two indexes before the columns existed and wrapped the descriptions in sys.fn_listextendedproperty.
-- This is the PostgreSQL form of the same DDL, in order: STORED generated columns (every function
-- used is IMMUTABLE), then their indexes, then their descriptions. The converted original is kept
-- below, commented out. The expressions match the T-SQL ones exactly: TRIM there trims spaces, as
-- BTRIM does here; CHARINDEX(x, s) is POSITION(x IN s); SUBSTRING(s, start, len) is
-- SUBSTRING(s FROM start FOR len); Host + '/' is Host || '/'.
ALTER TABLE __mj_BizAppsCommon."Person"
    ADD COLUMN IF NOT EXISTS "EmailDomain" VARCHAR(255) GENERATED ALWAYS AS (
        CAST(
            CASE WHEN POSITION('@' IN "Email") > 0
                 THEN NULLIF(LOWER(BTRIM(SUBSTRING("Email" FROM POSITION('@' IN "Email") + 1 FOR 255))), '')
            END
            AS VARCHAR(255))
    ) STORED;

ALTER TABLE __mj_BizAppsCommon."Organization"
    ADD COLUMN IF NOT EXISTS "WebsiteDomain" VARCHAR(255) GENERATED ALWAYS AS (
        -- LEFT(Host, POSITION('/' IN Host || '/') - 1), where Host = SUBSTRING(x FROM Start FOR 1000).
        CAST(
            NULLIF(
                LEFT(
                    SUBSTRING(LOWER(BTRIM("Website")) FROM CASE WHEN LOWER(BTRIM("Website")) LIKE 'https://www.%' THEN 13
                         WHEN LOWER(BTRIM("Website")) LIKE 'http://www.%'  THEN 12
                         WHEN LOWER(BTRIM("Website")) LIKE 'https://%'     THEN 9
                         WHEN LOWER(BTRIM("Website")) LIKE 'http://%'      THEN 8
                         WHEN LOWER(BTRIM("Website")) LIKE 'www.%'         THEN 5
                         ELSE 1 END FOR 1000),
                    POSITION('/' IN SUBSTRING(LOWER(BTRIM("Website")) FROM CASE WHEN LOWER(BTRIM("Website")) LIKE 'https://www.%' THEN 13
                         WHEN LOWER(BTRIM("Website")) LIKE 'http://www.%'  THEN 12
                         WHEN LOWER(BTRIM("Website")) LIKE 'https://%'     THEN 9
                         WHEN LOWER(BTRIM("Website")) LIKE 'http://%'      THEN 8
                         WHEN LOWER(BTRIM("Website")) LIKE 'www.%'         THEN 5
                         ELSE 1 END FOR 1000) || '/') - 1),
                '')
            AS VARCHAR(255))
    ) STORED;

CREATE INDEX IF NOT EXISTS "IX_Person_EmailDomain" ON __mj_BizAppsCommon."Person" ("EmailDomain");

CREATE INDEX IF NOT EXISTS "IX_Organization_WebsiteDomain" ON __mj_BizAppsCommon."Organization" ("WebsiteDomain");

COMMENT ON COLUMN __mj_BizAppsCommon."Person"."EmailDomain" IS 'Lower-cased domain of Email: the text after the first @. NULL when Email is empty, has no @, or has nothing after it. Computed and stored, indexed for prefix search by domain.';

COMMENT ON COLUMN __mj_BizAppsCommon."Organization"."WebsiteDomain" IS 'Lower-cased host of Website, without the http(s):// scheme, a leading www. or any path. NULL when Website is empty. Computed and stored, indexed for prefix search by domain.';

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Organization_OrganizationTypeID" ON __mj_BizAppsCommon."Organization" ("OrganizationTypeID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Organization_ParentID" ON __mj_BizAppsCommon."Organization" ("ParentID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Person_LinkedUserID" ON __mj_BizAppsCommon."Person" ("LinkedUserID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Person_SeniorityLevelID" ON __mj_BizAppsCommon."Person" ("SeniorityLevelID");


-- ===================== Helper Functions (fn*) =====================

CREATE FUNCTION __mj_BizAppsCommon."fnOrganizationParentID_GetHierarchyMeta"
(
    p_RecordID UUID,
    p_ParentID UUID
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_Ancestors AS (
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
        (SELECT MAX("Depth") FROM CTE_Ancestors) AS "Depth",
        (SELECT "Path" FROM CTE_Ancestors ORDER BY "Depth" DESC
LIMIT 1) AS "Path",
        CAST(CASE WHEN EXISTS (SELECT 1 FROM __mj_BizAppsCommon."Organization" WHERE "ParentID" = p_RecordID) THEN 0 ELSE 1 END AS BOOLEAN) AS "IsLeaf",
        (SELECT COUNT(1) FROM __mj_BizAppsCommon."Organization" WHERE "ParentID" = p_RecordID) AS "ChildCount"
    FROM
        CTE_Ancestors a
    WHERE
        a."ParentID" IS NULL OR p_ParentID IS NULL
    ORDER BY
        a."Depth" DESC

LIMIT 1);

CREATE FUNCTION __mj_BizAppsCommon."fnOrganizationParentID_GetDescendants"
(
    p_RootID UUID,
    p_MaxDepth INTEGER = NULL
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_Descendants AS (
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
            p."RelativeDepth" || 1 AS "RelativeDepth",
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
);

CREATE FUNCTION __mj_BizAppsCommon."fnOrganizationParentID_GetAncestors"
(
    p_RecordID UUID
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_Ancestors AS (
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
);

CREATE FUNCTION __mj_BizAppsCommon."fnOrganizationParentID_GetRootID"
(
    p_RecordID UUID,
    p_ParentID UUID
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_RootParent AS (
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

LIMIT 1);


-- ===================== Views =====================

DROP VIEW IF EXISTS __mj_BizAppsCommon."vwOrganizationsGenerated" CASCADE;
DO $do$
DECLARE
  v_target_schema CONSTANT TEXT := '__mj_BizAppsCommon';
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

DROP VIEW IF EXISTS __mj_BizAppsCommon."vwPeopleGenerated" CASCADE;
DO $do$
DECLARE
  v_target_schema CONSTANT TEXT := '__mj_BizAppsCommon';
  v_target_name CONSTANT TEXT := 'vwPeopleGenerated';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwPeopleGenerated"
AS SELECT
    p.*,
    "MJUser_LinkedUserID"."Name" AS "LinkedUser",
    "mjBizAppsCommonSeniorityLevel_SeniorityLevelID"."Name" AS "SeniorityLevel"
FROM
    __mj_BizAppsCommon."Person" AS p
LEFT OUTER JOIN
    ${mjSchema}."User" AS "MJUser_LinkedUserID"
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


-- ===================== Triggers =====================

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_BizAppsCommon].trgUpdateOrganization
-- ON __mj_BizAppsCommon."Organization"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         __mj_BizAppsCommon."Organization"
--     SE

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_BizAppsCommon].trgUpdatePerson
-- ON __mj_BizAppsCommon."Person"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         __mj_BizAppsCommon."Person"
--     SET
--         __mj_Upd


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ${mjSchema}."EntityField" WHERE "ID" = 'b132dcac-4f9f-4e98-9116-be13afd0e71a' OR ("EntityID" = 'C70448F9-9792-41D7-A82C-784B66429D54' AND "Name" = 'WebsiteDomain')
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
        'b132dcac-4f9f-4e98-9116-be13afd0e71a',
        'C70448F9-9792-41D7-A82C-784B66429D54', -- "Entity": "MJ_BizApps_Common": "Organizations"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM ${mjSchema}."EntityField" WHERE "EntityID" = 'C70448F9-9792-41D7-A82C-784B66429D54'),
        'WebsiteDomain',
        'Website Domain',
        'Lower-cased host of Website, without the http(s):// scheme, a leading www. or any path. NULL when Website is empty. Computed and stored, indexed for prefix search by domain.',
        'TEXT',
        510,
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

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ${mjSchema}."EntityField" WHERE "ID" = '5f79a492-3538-46d5-8047-ff545f674b58' OR ("EntityID" = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND "Name" = 'EmailDomain')
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
        '5f79a492-3538-46d5-8047-ff545f674b58',
        '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- "Entity": "MJ_BizApps_Common": "People"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM ${mjSchema}."EntityField" WHERE "EntityID" = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'),
        'EmailDomain',
        'Email Domain',
        'Lower-cased domain of Email: the text after the first @. NULL when Email is empty, has no @, or has nothing after it. Computed and stored, indexed for prefix search by domain.',
        'TEXT',
        510,
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
/* Refresh custom base views for modified entities so schema changes are picked up */


-- ===================== Other =====================

-- =============================================================================
-- Migration: V202610211654__v5.56.x__Party_Lookup_Domain_Columns.sql
-- Description: Add two PERSISTED, indexed computed columns for the party lookup
--              (bizapps-party-field): Person.EmailDomain and Organization.WebsiteDomain.
--
-- WHY. Pickers on Deal, Order and Contract forms must find a person by email domain
-- ("aqha.com") and an organization by website ("acme.com") in under a second. Matching
-- the raw columns needs a leading wildcard (Email LIKE '%@aqha.com', Website LIKE
-- '%acme.com%'), which scans: 1.9 s and 28 s on Stage (1.29M people, 448K organizations).
-- A stored, indexed domain turns both into a prefix seek.
--
-- Person.EmailDomain: the lower-cased text after the first '@' of Email. NULL when Email
-- is NULL, has no '@', or has nothing after it ("bob@").
--
-- Organization.WebsiteDomain: Website trimmed and lower-cased, then
--   1. the scheme (http:// or https://) and a leading "www." are skipped: Start is the
--      position after them;
--   2. the host runs from Start to the first '/' after it (or the end).
-- "HTTPS://WWW.Acme.com/about" -> "acme.com". A port stays ("acme.com:8080"); a query
-- string with no path stays too. NULL when Website is NULL or nothing is left.
-- The picker normalizes a typed URL the same way (party-lookup-term.ts websiteDomainOf).
--
-- Both are CAST to VARCHAR(255) (510 bytes) so they fit an index key. Every function used
-- is deterministic, which PERSISTED and the index require.
--
-- POSTGRESQL. Release work. Both expressions use only IMMUTABLE functions (lower, btrim,
-- position/strpos, substr), so GENERATED ALWAYS AS (...) STORED works there.
-- =============================================================================
-- (converted T-SQL, replaced by the hand-written DDL near the top of this file)
-- IF COL_LENGTH('[__mj_BizAppsCommon].[Person]', 'EmailDomain') IS NULL
--     ALTER TABLE __mj_BizAppsCommon."Person"
--         ADD "EmailDomain" AS (
--             CAST(
--                 CASE WHEN CHARINDEX(N'@', "Email") > 0
--                      THEN NULLIF(LOWER(TRIM(SUBSTRING("Email", CHARINDEX(N'@', "Email") + 1, 255))), N'')
--                 END
--                 AS VARCHAR(255))
--         ) PERSISTED;

-- NOTE: unrecognized batch type (UNKNOWN) — passed through as-is
-- IF COL_LENGTH('[__mj_BizAppsCommon].[Organization]', 'WebsiteDomain') IS NULL
--     ALTER TABLE __mj_BizAppsCommon."Organization"
--         ADD "WebsiteDomain" AS (
--             -- LEFT(Host, CHARINDEX('/', Host + '/') - 1), where Host = SUBSTRING(x, Start, 1000):
--             -- Host is written out twice because a computed column cannot name a sub-expression.
--             CAST(
--                 NULLIF(
--                     LEFT(
--                         SUBSTRING(LOWER(TRIM("Website")),
--                             CASE WHEN LOWER(TRIM("Website")) LIKE N'https://www.%' THEN 13
--                                  WHEN LOWER(TRIM("Website")) LIKE N'http://www.%'  THEN 12
--                                  WHEN LOWER(TRIM("Website")) LIKE N'https://%'     THEN 9
--                                  WHEN LOWER(TRIM("Website")) LIKE N'http://%'      THEN 8
--                                  WHEN LOWER(TRIM("Website")) LIKE N'www.%'         THEN 5
--                                  ELSE 1 END, 1000),
--                         CHARINDEX(N'/', SUBSTRING(LOWER(TRIM("Website")),
--                             CASE WHEN LOWER(TRIM("Website")) LIKE N'https://www.%' THEN 13
--                                  WHEN LOWER(TRIM("Website")) LIKE N'http://www.%'  THEN 12
--                                  WHEN LOWER(TRIM("Website")) LIKE N'https://%'     THEN 9
--                                  WHEN LOWER(TRIM("Website")) LIKE N'http://%'      THEN 8
--                                  WHEN LOWER(TRIM("Website")) LIKE N'www.%'         THEN 5
--                                  ELSE 1 END, 1000) + N'/') - 1),
--                     N'')
--                 AS VARCHAR(255))
--         ) PERSISTED;

/* ============================================================================================
   ==== CODEGEN OUTPUT — DO NOT EDIT BELOW THIS LINE ====
   Generated by the MemberJunction CodeGen tool: published @memberjunction/cli 6.1.6 (this repo's
   floor), includeSchemas ['__mj_BizAppsCommon'], against a database built from migrations alone
   (MJ core v6.1.6, then this repo's chain at origin/next, then the DDL above).
   Contains: the Person.EmailDomain and Organization.WebsiteDomain EntityField inserts, and the
   regenerated vwPeopleGenerated / vwOrganizationsGenerated, Person and Organization CRUD procs,
   Organization hierarchy TVFs and FK indexes that regenerate with them.
   No AI pass: field descriptions come from MS_Description above, and the form sections for the two
   fields are pinned in metadata/entity-fields/.form-layout.json (they reach hosts in the release seed).
   Do NOT edit by hand. If the hand-written SQL above changes, re-run CodeGen and replace this
   whole section.
   ============================================================================================ */
/* SQL text to insert 2 new entity field(s) */

/* spUpdate Permissions for MJ_BizApps_Common: Organizations */

/* spUpdate Permissions for MJ_BizApps_Common: People */
