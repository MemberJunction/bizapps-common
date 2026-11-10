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

-- NEUTRALIZED (release work, 22 Oct 2026): the four Organization ParentID hierarchy functions below are
-- T-SQL table-valued functions the converter left live (RETURNS TABLE AS RETURN), which PostgreSQL
-- rejects. As in the v5.54 twins, PostgreSQL CodeGen regenerates them natively.
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

-- NEUTRALIZED (release work, 22 Oct 2026): vwOrganizationsGenerated joins the ParentID hierarchy
-- function neutralized above, which no PostgreSQL migration creates, so this block would fail the
-- file. PostgreSQL CodeGen regenerates the view (docs/postgresql.md).
-- DROP VIEW IF EXISTS __mj_BizAppsCommon."vwOrganizationsGenerated" CASCADE;
-- DO $do$
-- DECLARE
--   v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
--   v_target_name CONSTANT TEXT := 'vwOrganizationsGenerated';
--   vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwOrganizationsGenerated"
-- AS SELECT
--     o.*,
--     "mjBizAppsCommonOrganizationType_OrganizationTypeID"."Name" AS "OrganizationType",
--     "mjBizAppsCommonOrganization_ParentID"."Name" AS "Parent",
--     "hier_ParentID"."RootID" AS "RootParentID",
--     "hier_ParentID"."Depth" AS "ParentIDDepth",
--     "hier_ParentID"."Path" AS "ParentIDPath",
--     "hier_ParentID"."IsLeaf" AS "ParentIDIsLeaf",
--     "hier_ParentID"."ChildCount" AS "ParentIDChildCount"
-- FROM
--     __mj_BizAppsCommon."Organization" AS o
-- LEFT OUTER JOIN
--     __mj_BizAppsCommon."OrganizationType" AS "mjBizAppsCommonOrganizationType_OrganizationTypeID"
--   ON
--     o."OrganizationTypeID" = "mjBizAppsCommonOrganizationType_OrganizationTypeID"."ID"
-- LEFT OUTER JOIN
--     __mj_BizAppsCommon."Organization" AS "mjBizAppsCommonOrganization_ParentID"
--   ON
--     o."ParentID" = "mjBizAppsCommonOrganization_ParentID"."ID"
-- LEFT JOIN LATERAL (SELECT * FROM __mj_BizAppsCommon."fnOrganizationParentID_GetHierarchyMeta"(o."ID", o."ParentID")) AS "hier_ParentID"
--     ON TRUE$vsql$;
--   v_target_oid OID;
--   v_dep RECORD;
--   v_captured JSONB[] := ARRAY[]::JSONB[];
--   v_n INTEGER;
-- BEGIN
--   EXECUTE vsql;
-- EXCEPTION WHEN invalid_table_definition THEN
--   -- Column list changed; need CASCADE. Preserve dependent views first.
--   SELECT c.oid INTO v_target_oid
--   FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid
--   WHERE n.nspname = v_target_schema AND c.relname = v_target_name AND c.relkind = 'v';
--   IF v_target_oid IS NOT NULL THEN
--     FOR v_dep IN
--       WITH RECURSIVE deps AS (
--         SELECT c.oid, c.relname AS name, n.nspname AS schema, 1 AS depth
--         FROM pg_rewrite r
--         JOIN pg_depend d ON d.objid = r.oid
--         JOIN pg_class c ON c.oid = r.ev_class
--         JOIN pg_namespace n ON c.relnamespace = n.oid
--         WHERE d.refobjid = v_target_oid AND d.deptype = 'n'
--           AND c.oid <> v_target_oid AND c.relkind = 'v'
--         UNION
--         SELECT c.oid, c.relname, n.nspname, p.depth + 1
--         FROM deps p
--         JOIN pg_rewrite r ON TRUE
--         JOIN pg_depend d ON d.objid = r.oid AND d.refobjid = p.oid
--         JOIN pg_class c ON c.oid = r.ev_class
--         JOIN pg_namespace n ON c.relnamespace = n.oid
--         WHERE c.relkind = 'v' AND c.oid <> p.oid
--       )
--       SELECT oid, name, schema, MAX(depth) AS max_depth,
--              pg_catalog.pg_get_viewdef(oid, true) AS viewdef
--       FROM deps GROUP BY oid, name, schema
--       ORDER BY MAX(depth) ASC
--     LOOP
--       v_captured := v_captured || jsonb_build_object(
--         'schema', v_dep.schema, 'name', v_dep.name, 'def', v_dep.viewdef);
--     END LOOP;
--   END IF;
--   EXECUTE format('DROP VIEW IF EXISTS %I.%I CASCADE', v_target_schema, v_target_name);
--   EXECUTE vsql;
--   IF v_captured IS NOT NULL AND array_length(v_captured, 1) > 0 THEN
--     FOR v_n IN 1..array_length(v_captured, 1) LOOP
--       BEGIN
--         EXECUTE format('CREATE VIEW %I.%I AS %s',
--           v_captured[v_n]->>'schema', v_captured[v_n]->>'name', v_captured[v_n]->>'def');
--       EXCEPTION WHEN others THEN
--         RAISE WARNING 'Could not restore dependent view %.%: %',
--           v_captured[v_n]->>'schema', v_captured[v_n]->>'name', SQLERRM;
--       END;
--     END LOOP;
--   END IF;
-- END;
-- $do$;

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

-- =============================================================================
-- Native PostgreSQL CodeGen for the procedures and triggers the conversion above skipped
-- (Organization, Person).
-- =============================================================================
-- ---------- native PostgreSQL CodeGen: MJ_BizApps_Common: Organizations
-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Organizations
-- Item: Index for Foreign Keys

-- ============================================================
CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_organization_organization_type_id"
    ON "__mj_bizappscommon"."Organization" ("OrganizationTypeID");

CREATE INDEX IF NOT EXISTS "idx_auto_mj_fkey_organization_parent_id"
    ON "__mj_bizappscommon"."Organization" ("ParentID");

-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Organizations
-- Item: fn_organization_parent_id_get_hierarchy_meta

-- ============================================================

------------------------------------------------------------
----- HIERARCHY METADATA FUNCTION FOR: Organization.ParentID
------------------------------------------------------------
CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."fn_organization_parent_id_get_hierarchy_meta"(
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
            "ParentID",
            0 AS depth,
            '/' || "ID"::TEXT || '/' AS path
        FROM
            "__mj_bizappscommon"."Organization"
        WHERE
            "ID" = p_record_id

        UNION ALL

        SELECT
            p."ID",
            p."ParentID",
            c.depth + 1 AS depth,
            '/' || p."ID"::TEXT || c.path AS path
        FROM
            "__mj_bizappscommon"."Organization" p
        INNER JOIN
            cte_ancestors c ON p."ID" = c."ParentID"
        WHERE
            c.depth < 100
    )
    SELECT
        a."ID" AS "RootID",
        (SELECT MAX(depth) FROM cte_ancestors)::INTEGER AS "Depth",
        (SELECT path FROM cte_ancestors ORDER BY depth DESC LIMIT 1)::TEXT AS "Path",
        (NOT EXISTS (SELECT 1 FROM "__mj_bizappscommon"."Organization" WHERE "ParentID" = p_record_id))::BOOLEAN AS "IsLeaf",
        (SELECT COUNT(1)::INTEGER FROM "__mj_bizappscommon"."Organization" WHERE "ParentID" = p_record_id) AS "ChildCount"
    FROM
        cte_ancestors a
    WHERE
        a."ParentID" IS NULL OR p_parent_id IS NULL
    ORDER BY
        a.depth DESC
    LIMIT 1;
$$ LANGUAGE sql STABLE;


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Organizations
-- Item: fn_organization_parent_id_get_descendants

-- ============================================================

------------------------------------------------------------
----- DESCENDANTS FUNCTION FOR: Organization.ParentID
------------------------------------------------------------
CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."fn_organization_parent_id_get_descendants"(
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
            "ParentID",
            0 AS relative_depth,
            '/' || "ID"::TEXT || '/' AS path
        FROM
            "__mj_bizappscommon"."Organization"
        WHERE
            "ID" = p_root_id

        UNION ALL

        SELECT
            c."ID",
            c."ParentID",
            p.relative_depth + 1 AS relative_depth,
            p.path || c."ID"::TEXT || '/' AS path
        FROM
            "__mj_bizappscommon"."Organization" c
        INNER JOIN
            cte_descendants p ON c."ParentID" = p."ID"
        WHERE
            (p_max_depth IS NULL OR p.relative_depth < p_max_depth)
            AND p.relative_depth < 100
    )
    SELECT
        d."ID" AS "ID",
        d.relative_depth AS "Depth",
        d.path AS "Path",
        (NOT EXISTS (SELECT 1 FROM "__mj_bizappscommon"."Organization" WHERE "ParentID" = d."ID"))::BOOLEAN AS "IsLeaf",
        (SELECT COUNT(1)::INTEGER FROM "__mj_bizappscommon"."Organization" WHERE "ParentID" = d."ID") AS "ChildCount"
    FROM
        cte_descendants d;
$$ LANGUAGE sql STABLE;


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Organizations
-- Item: fn_organization_parent_id_get_ancestors

-- ============================================================

------------------------------------------------------------
----- ANCESTORS FUNCTION FOR: Organization.ParentID
------------------------------------------------------------
CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."fn_organization_parent_id_get_ancestors"(
    p_record_id UUID
) RETURNS TABLE (
    "ID" UUID,
    "LevelUp" INTEGER,
    "Path" TEXT
) AS $$
    WITH RECURSIVE cte_ancestors AS (
        SELECT
            "ID",
            "ParentID",
            0 AS level_up,
            '/' || "ID"::TEXT || '/' AS path
        FROM
            "__mj_bizappscommon"."Organization"
        WHERE
            "ID" = p_record_id

        UNION ALL

        SELECT
            p."ID",
            p."ParentID",
            c.level_up + 1 AS level_up,
            '/' || p."ID"::TEXT || c.path AS path
        FROM
            "__mj_bizappscommon"."Organization" p
        INNER JOIN
            cte_ancestors c ON p."ID" = c."ParentID"
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
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Organizations
-- Item: fn_organization_parent_id_get_root_id

-- ============================================================

------------------------------------------------------------
----- ROOT ID FUNCTION FOR: Organization.ParentID
------------------------------------------------------------
CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."fn_organization_parent_id_get_root_id"(
    p_record_id UUID,
    p_parent_id UUID
) RETURNS UUID AS $$
    WITH RECURSIVE cte_root_parent AS (
        -- Anchor: Start from p_parent_id if not null, otherwise start from p_record_id
        SELECT
            "ID",
            "ParentID",
            "ID" AS root_parent_id,
            0 AS depth
        FROM
            "__mj_bizappscommon"."Organization"
        WHERE
            "ID" = COALESCE(p_parent_id, p_record_id)

        UNION ALL

        -- Recursive: Keep going up the hierarchy
        SELECT
            c."ID",
            c."ParentID",
            c."ID" AS root_parent_id,
            p.depth + 1 AS depth
        FROM
            "__mj_bizappscommon"."Organization" c
        INNER JOIN
            cte_root_parent p ON c."ID" = p."ParentID"
        WHERE
            p.depth < 100  -- Prevent infinite loops
    )
    SELECT root_parent_id
    FROM cte_root_parent
    WHERE "ParentID" IS NULL
    ORDER BY root_parent_id
    LIMIT 1;
$$ LANGUAGE sql STABLE;


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Organizations
-- Item: vwOrganizationsGenerated

-- ============================================================

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Organizations
-----               SCHEMA:      __mj_bizappscommon
-----               BASE TABLE:  Organization
-----               PRIMARY KEY: ID
------------------------------------------------------------
DO $vw_regen$
DECLARE
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW "__mj_bizappscommon"."vwOrganizationsGenerated"
AS
SELECT
    o.*,
    mjbizappscommonOrganizationType_OrganizationTypeID."Name" AS "OrganizationType",
    mjbizappscommonOrganization_ParentID."Name" AS "Parent",
    hier_ParentID."RootID" AS "RootParentID",
    hier_ParentID."Depth" AS "ParentIDDepth",
    hier_ParentID."Path" AS "ParentIDPath",
    hier_ParentID."IsLeaf" AS "ParentIDIsLeaf",
    hier_ParentID."ChildCount" AS "ParentIDChildCount"
FROM
    "__mj_bizappscommon"."Organization" AS o
LEFT OUTER JOIN
    "__mj_bizappscommon"."OrganizationType" AS mjbizappscommonOrganizationType_OrganizationTypeID
  ON
    "o"."OrganizationTypeID" = mjbizappscommonOrganizationType_OrganizationTypeID."ID"
LEFT OUTER JOIN
    "__mj_bizappscommon"."Organization" AS mjbizappscommonOrganization_ParentID
  ON
    "o"."ParentID" = mjbizappscommonOrganization_ParentID."ID"

LEFT JOIN LATERAL "__mj_bizappscommon"."fn_organization_parent_id_get_hierarchy_meta"(o."ID", o."ParentID") AS hier_ParentID ON true
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
        AND tc.relname = 'vwOrganizationsGenerated'
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
                           AND tc.relname = 'vwOrganizationsGenerated'
                           AND tc.relkind IN ('v', 'm')))
        AND (pp.prorettype = c.reltype
             OR EXISTS (SELECT 1 FROM pg_depend d
                        WHERE d.classid = 'pg_proc'::regclass
                          AND d.objid = pp.oid
                          AND d.refobjid = c.oid))
  );

  DROP VIEW IF EXISTS "__mj_bizappscommon"."vwOrganizationsGenerated" CASCADE;
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
  IF to_regclass('"__mj_bizappscommon"."vwOrganizations"') IS NOT NULL THEN
    EXECUTE 'GRANT SELECT ON "__mj_bizappscommon"."vwOrganizations" TO "cdp_UI";
GRANT SELECT ON "__mj_bizappscommon"."vwOrganizations" TO "cdp_Developer";
GRANT SELECT ON "__mj_bizappscommon"."vwOrganizations" TO "cdp_Integration";';
  END IF;
END
$if_view_exists$;


DO $if_view_exists$
BEGIN
  IF to_regclass('"__mj_bizappscommon"."vwOrganizations"') IS NOT NULL THEN
    EXECUTE 'SELECT "__mj"."spRebindLayeredOuterView"(''__mj_bizappscommon'', ''vwOrganizations'', ''vwOrganizationsGenerated'');';
  END IF;
END
$if_view_exists$;


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Organizations
-- Item: Permissions for vwOrganizations

-- ============================================================
DO $if_view_exists$
BEGIN
  IF to_regclass('"__mj_bizappscommon"."vwOrganizations"') IS NOT NULL THEN
    EXECUTE 'GRANT SELECT ON "__mj_bizappscommon"."vwOrganizations" TO "cdp_UI";
GRANT SELECT ON "__mj_bizappscommon"."vwOrganizations" TO "cdp_Developer";
GRANT SELECT ON "__mj_bizappscommon"."vwOrganizations" TO "cdp_Integration";';
  END IF;
END
$if_view_exists$;


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Organizations
-- Item: spCreateOrganization

-- ============================================================

------------------------------------------------------------
----- CREATE FUNCTION FOR Organization
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spCreateOrganization'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spCreateOrganization"(
    p_id UUID DEFAULT NULL,
    p_name varchar(255) DEFAULT NULL,
    p_legalname_clear boolean DEFAULT false,
    p_legalname varchar(255) DEFAULT NULL,
    p_organizationtypeid_clear boolean DEFAULT false,
    p_organizationtypeid UUID DEFAULT NULL,
    p_parentid_clear boolean DEFAULT false,
    p_parentid UUID DEFAULT NULL,
    p_website_clear boolean DEFAULT false,
    p_website varchar(1000) DEFAULT NULL,
    p_logourl_clear boolean DEFAULT false,
    p_logourl TEXT DEFAULT NULL,
    p_description_clear boolean DEFAULT false,
    p_description TEXT DEFAULT NULL,
    p_email_clear boolean DEFAULT false,
    p_email varchar(255) DEFAULT NULL,
    p_phone_clear boolean DEFAULT false,
    p_phone varchar(50) DEFAULT NULL,
    p_foundeddate_clear boolean DEFAULT false,
    p_foundeddate date DEFAULT NULL,
    p_taxid_clear boolean DEFAULT false,
    p_taxid varchar(50) DEFAULT NULL,
    p_status varchar(50) DEFAULT NULL
) RETURNS SETOF "__mj_bizappscommon"."vwOrganizations" AS $$
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO "__mj_bizappscommon"."Organization"
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
                "Status"
        )
    VALUES
        (
            v_new_id,
            p_name,
                CASE WHEN p_legalname_clear = true THEN NULL ELSE COALESCE(p_legalname, NULL) END,
                CASE WHEN p_organizationtypeid_clear = true THEN NULL ELSE COALESCE(p_organizationtypeid, NULL) END,
                CASE WHEN p_parentid_clear = true THEN NULL ELSE COALESCE(p_parentid, NULL) END,
                CASE WHEN p_website_clear = true THEN NULL ELSE COALESCE(p_website, NULL) END,
                CASE WHEN p_logourl_clear = true THEN NULL ELSE COALESCE(p_logourl, NULL) END,
                CASE WHEN p_description_clear = true THEN NULL ELSE COALESCE(p_description, NULL) END,
                CASE WHEN p_email_clear = true THEN NULL ELSE COALESCE(p_email, NULL) END,
                CASE WHEN p_phone_clear = true THEN NULL ELSE COALESCE(p_phone, NULL) END,
                CASE WHEN p_foundeddate_clear = true THEN NULL ELSE COALESCE(p_foundeddate, NULL) END,
                CASE WHEN p_taxid_clear = true THEN NULL ELSE COALESCE(p_taxid, NULL) END,
                COALESCE(p_status, 'Active')
        )
    ;

    RETURN QUERY
    SELECT * FROM "__mj_bizappscommon"."vwOrganizations"
    WHERE "ID" = v_new_id;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spCreateOrganization" TO "cdp_Developer";
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spCreateOrganization" TO "cdp_Integration";


-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Organizations
-- Item: spUpdateOrganization

-- ============================================================

------------------------------------------------------------
----- UPDATE FUNCTION FOR Organization
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spUpdateOrganization'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spUpdateOrganization"(
    p_id UUID,
    p_name varchar(255) DEFAULT NULL,
    p_legalname_clear boolean DEFAULT false,
    p_legalname varchar(255) DEFAULT NULL,
    p_organizationtypeid_clear boolean DEFAULT false,
    p_organizationtypeid UUID DEFAULT NULL,
    p_parentid_clear boolean DEFAULT false,
    p_parentid UUID DEFAULT NULL,
    p_website_clear boolean DEFAULT false,
    p_website varchar(1000) DEFAULT NULL,
    p_logourl_clear boolean DEFAULT false,
    p_logourl TEXT DEFAULT NULL,
    p_description_clear boolean DEFAULT false,
    p_description TEXT DEFAULT NULL,
    p_email_clear boolean DEFAULT false,
    p_email varchar(255) DEFAULT NULL,
    p_phone_clear boolean DEFAULT false,
    p_phone varchar(50) DEFAULT NULL,
    p_foundeddate_clear boolean DEFAULT false,
    p_foundeddate date DEFAULT NULL,
    p_taxid_clear boolean DEFAULT false,
    p_taxid varchar(50) DEFAULT NULL,
    p_status varchar(50) DEFAULT NULL
) RETURNS SETOF "__mj_bizappscommon"."vwOrganizations" AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE "__mj_bizappscommon"."Organization"
    SET
        "Name" = COALESCE(p_name, "Name"),
        "LegalName" = CASE WHEN p_legalname_clear = true THEN NULL ELSE COALESCE(p_legalname, "LegalName") END,
        "OrganizationTypeID" = CASE WHEN p_organizationtypeid_clear = true THEN NULL ELSE COALESCE(p_organizationtypeid, "OrganizationTypeID") END,
        "ParentID" = CASE WHEN p_parentid_clear = true THEN NULL ELSE COALESCE(p_parentid, "ParentID") END,
        "Website" = CASE WHEN p_website_clear = true THEN NULL ELSE COALESCE(p_website, "Website") END,
        "LogoURL" = CASE WHEN p_logourl_clear = true THEN NULL ELSE COALESCE(p_logourl, "LogoURL") END,
        "Description" = CASE WHEN p_description_clear = true THEN NULL ELSE COALESCE(p_description, "Description") END,
        "Email" = CASE WHEN p_email_clear = true THEN NULL ELSE COALESCE(p_email, "Email") END,
        "Phone" = CASE WHEN p_phone_clear = true THEN NULL ELSE COALESCE(p_phone, "Phone") END,
        "FoundedDate" = CASE WHEN p_foundeddate_clear = true THEN NULL ELSE COALESCE(p_foundeddate, "FoundedDate") END,
        "TaxID" = CASE WHEN p_taxid_clear = true THEN NULL ELSE COALESCE(p_taxid, "TaxID") END,
        "Status" = COALESCE(p_status, "Status")
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        -- Nothing was updated, return empty result set
        RETURN;
    END IF;

    -- Return the updated record from the base view
    RETURN QUERY
    SELECT * FROM "__mj_bizappscommon"."vwOrganizations"
    WHERE "ID" = p_id;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spUpdateOrganization" TO "cdp_Developer";
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spUpdateOrganization" TO "cdp_Integration";


------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Organization table
------------------------------------------------------------
CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."fn_trg_update_organization"()
RETURNS TRIGGER AS $$
BEGIN
    NEW."__mj_UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS "trg_update_organization" ON "__mj_bizappscommon"."Organization";

CREATE TRIGGER "trg_update_organization"
BEFORE UPDATE ON "__mj_bizappscommon"."Organization"
FOR EACH ROW
EXECUTE FUNCTION "__mj_bizappscommon"."fn_trg_update_organization"();



-- ============================================================
-- PostgreSQL Generated SQL for Entity: MJ_BizApps_Common: Organizations
-- Item: spDeleteOrganization

-- ============================================================

------------------------------------------------------------
----- DELETE FUNCTION FOR Organization
------------------------------------------------------------
DO $do$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT oid::regprocedure AS sig
             FROM pg_proc
             WHERE proname = 'spDeleteOrganization'
               AND pronamespace = '__mj_bizappscommon'::regnamespace
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;
END
$do$;

CREATE OR REPLACE FUNCTION "__mj_bizappscommon"."spDeleteOrganization"(
    p_id UUID
) RETURNS TABLE("ID" UUID) AS $$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
BEGIN

    DELETE FROM "__mj_bizappscommon"."Organization"
    WHERE "ID" = p_id;

    GET DIAGNOSTICS v_affected_count = ROW_COUNT;

    IF v_affected_count = 0 THEN
        RETURN QUERY SELECT NULL::UUID AS "ID";
    ELSE
        RETURN QUERY SELECT p_id AS "ID";
    END IF;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION "__mj_bizappscommon"."spDeleteOrganization" TO "cdp_Integration";

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
