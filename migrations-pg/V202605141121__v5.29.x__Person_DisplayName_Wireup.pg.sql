-- ============================================================================
-- MemberJunction PostgreSQL Migration
-- Converted from SQL Server using TypeScript conversion pipeline
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Schema
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

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_AddressLink_AddressID" ON __mj_bizappscommon."AddressLink" ("AddressID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_AddressLink_EntityID" ON __mj_bizappscommon."AddressLink" ("EntityID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_AddressLink_AddressTypeID" ON __mj_bizappscommon."AddressLink" ("AddressTypeID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_ContactMethod_PersonID" ON __mj_bizappscommon."ContactMethod" ("PersonID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_ContactMethod_OrganizationID" ON __mj_bizappscommon."ContactMethod" ("OrganizationID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_ContactMethod_ContactTypeID" ON __mj_bizappscommon."ContactMethod" ("ContactTypeID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Relationship_RelationshipTypeID" ON __mj_bizappscommon."Relationship" ("RelationshipTypeID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Relationship_FromPersonID" ON __mj_bizappscommon."Relationship" ("FromPersonID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Relationship_FromOrganizationID" ON __mj_bizappscommon."Relationship" ("FromOrganizationID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Relationship_ToPersonID" ON __mj_bizappscommon."Relationship" ("ToPersonID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Relationship_ToOrganizationID" ON __mj_bizappscommon."Relationship" ("ToOrganizationID");


-- ===================== Views =====================

DROP VIEW IF EXISTS __mj_bizappscommon."vwAddressLinks" CASCADE;
DROP VIEW IF EXISTS __mj_bizappscommon."vwAddressLinks" CASCADE;
DROP VIEW IF EXISTS __mj_bizappscommon."vwAddressLinks" CASCADE;
DROP VIEW IF EXISTS __mj_bizappscommon."vwAddressLinks" CASCADE;
DROP VIEW IF EXISTS __mj_bizappscommon."vwAddressLinks" CASCADE;
DO $do$
DECLARE
  v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
  v_target_name CONSTANT TEXT := 'vwAddressLinks';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_bizappscommon."vwAddressLinks"
AS SELECT
    a.*,
    "mjBizAppsCommonAddress_AddressID"."Line1" AS "Address",
    "MJEntity_EntityID"."Name" AS "Entity",
    "mjBizAppsCommonAddressType_AddressTypeID"."Name" AS "AddressType"
FROM
    __mj_bizappscommon."AddressLink" AS a
INNER JOIN
    __mj_bizappscommon."Address" AS "mjBizAppsCommonAddress_AddressID"
  ON
    a."AddressID" = "mjBizAppsCommonAddress_AddressID"."ID"
INNER JOIN
    "${mjSchema}"."Entity" AS "MJEntity_EntityID"
  ON
    a."EntityID" = "MJEntity_EntityID"."ID"
INNER JOIN
    __mj_bizappscommon."AddressType" AS "mjBizAppsCommonAddressType_AddressTypeID"
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

DROP VIEW IF EXISTS __mj_bizappscommon."vwContactMethods" CASCADE;
DROP VIEW IF EXISTS __mj_bizappscommon."vwContactMethods" CASCADE;
DROP VIEW IF EXISTS __mj_bizappscommon."vwContactMethods" CASCADE;
DROP VIEW IF EXISTS __mj_bizappscommon."vwContactMethods" CASCADE;
DROP VIEW IF EXISTS __mj_bizappscommon."vwContactMethods" CASCADE;
DO $do$
DECLARE
  v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
  v_target_name CONSTANT TEXT := 'vwContactMethods';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_bizappscommon."vwContactMethods"
AS SELECT
    c.*,
    "mjBizAppsCommonPerson_PersonID"."DisplayName" AS "Person",
    "mjBizAppsCommonOrganization_OrganizationID"."Name" AS "Organization",
    "mjBizAppsCommonContactType_ContactTypeID"."Name" AS "ContactType"
FROM
    __mj_bizappscommon."ContactMethod" AS c
LEFT OUTER JOIN
    __mj_bizappscommon."vwPeople" AS "mjBizAppsCommonPerson_PersonID"
  ON
    c."PersonID" = "mjBizAppsCommonPerson_PersonID"."ID"
LEFT OUTER JOIN
    __mj_bizappscommon."Organization" AS "mjBizAppsCommonOrganization_OrganizationID"
  ON
    c."OrganizationID" = "mjBizAppsCommonOrganization_OrganizationID"."ID"
INNER JOIN
    __mj_bizappscommon."ContactType" AS "mjBizAppsCommonContactType_ContactTypeID"
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

DROP VIEW IF EXISTS __mj_bizappscommon."vwRelationships" CASCADE;
DROP VIEW IF EXISTS __mj_bizappscommon."vwRelationships" CASCADE;
DROP VIEW IF EXISTS __mj_bizappscommon."vwRelationships" CASCADE;
DROP VIEW IF EXISTS __mj_bizappscommon."vwRelationships" CASCADE;
DROP VIEW IF EXISTS __mj_bizappscommon."vwRelationships" CASCADE;
DO $do$
DECLARE
  v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
  v_target_name CONSTANT TEXT := 'vwRelationships';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_bizappscommon."vwRelationships"
AS SELECT
    r.*,
    "mjBizAppsCommonRelationshipType_RelationshipTypeID"."Name" AS "RelationshipType",
    "mjBizAppsCommonPerson_FromPersonID"."DisplayName" AS "FromPerson",
    "mjBizAppsCommonOrganization_FromOrganizationID"."Name" AS "FromOrganization",
    "mjBizAppsCommonPerson_ToPersonID"."DisplayName" AS "ToPerson",
    "mjBizAppsCommonOrganization_ToOrganizationID"."Name" AS "ToOrganization"
FROM
    __mj_bizappscommon."Relationship" AS r
INNER JOIN
    __mj_bizappscommon."RelationshipType" AS "mjBizAppsCommonRelationshipType_RelationshipTypeID"
  ON
    r."RelationshipTypeID" = "mjBizAppsCommonRelationshipType_RelationshipTypeID"."ID"
LEFT OUTER JOIN
    __mj_bizappscommon."vwPeople" AS "mjBizAppsCommonPerson_FromPersonID"
  ON
    r."FromPersonID" = "mjBizAppsCommonPerson_FromPersonID"."ID"
LEFT OUTER JOIN
    __mj_bizappscommon."Organization" AS "mjBizAppsCommonOrganization_FromOrganizationID"
  ON
    r."FromOrganizationID" = "mjBizAppsCommonOrganization_FromOrganizationID"."ID"
LEFT OUTER JOIN
    __mj_bizappscommon."vwPeople" AS "mjBizAppsCommonPerson_ToPersonID"
  ON
    r."ToPersonID" = "mjBizAppsCommonPerson_ToPersonID"."ID"
LEFT OUTER JOIN
    __mj_bizappscommon."Organization" AS "mjBizAppsCommonOrganization_ToOrganizationID"
  ON
    r."ToOrganizationID" = "mjBizAppsCommonOrganization_ToOrganizationID"."ID"$vsql$;
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
-- CREATE PROCEDURE __mj_bizappscommon."spCreateAddressLink"
--     @ID UUID = NULL,
--     @AddressID UUID,
--     @EntityID UUID,
--     @RecordID VARCHAR(700),
--     @AddressT...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spUpdateAddressLink"
--     @ID UUID,
--     @AddressID UUID = NULL,
--     @EntityID UUID = NULL,
--     @RecordID VARCHAR(700) = NULL,...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spCreateContactMethod"
--     @ID UUID = NULL,
--     @PersonID_Clear bit = 0,
--     @PersonID UUID = NULL,
--     @OrganizationID_Clear bit = 0,
--   ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spUpdateContactMethod"
--     @ID UUID,
--     @PersonID_Clear bit = 0,
--     @PersonID UUID = NULL,
--     @OrganizationID_Clear bit = 0,
--     @Orga...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spDeleteAddressLink"
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         __mj_bizappscommon."AddressLink"
--     WHERE
--         "ID" = @...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spDeleteContactMethod"
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         __mj_bizappscommon."ContactMethod"
--     WHERE
--         "ID"...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spCreateRelationship"
--     @ID UUID = NULL,
--     @RelationshipTypeID UUID,
--     @FromPersonID_Clear bit = 0,
--     @FromPersonID uniqueidentif...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spUpdateRelationship"
--     @ID UUID,
--     @RelationshipTypeID UUID = NULL,
--     @FromPersonID_Clear bit = 0,
--     @FromPersonID uniqueidentif...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spDeleteRelationship"
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         __mj_bizappscommon."Relationship"
--     WHERE
--         "ID" =...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spDeleteOrganization"
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     -- Cascade update on ContactMethod using cursor to call spUpdateContactMethod
--    ...


-- ===================== Triggers =====================

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER __mj_bizappscommon.trgUpdateAddressLink
-- ON __mj_bizappscommon."AddressLink"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         __mj_bizappscommon."AddressLink"
--     SET
 

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER __mj_bizappscommon.trgUpdateContactMethod
-- ON __mj_bizappscommon."ContactMethod"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         __mj_bizappscommon."ContactMethod"
   

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER __mj_bizappscommon.trgUpdateRelationship
-- ON __mj_bizappscommon."Relationship"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         __mj_bizappscommon."Relationship"
--     SE


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM "${mjSchema}"."EntityField" WHERE "ID" = 'dc5ebc38-46d2-414c-ac64-fa81b7efc19a' OR ("EntityID" = '32C45078-D33B-4760-9BE5-0DF7F483F591' AND "Name" = 'Person')
    ) THEN
        INSERT INTO "${mjSchema}"."EntityField"
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
        'dc5ebc38-46d2-414c-ac64-fa81b7efc19a',
        '32C45078-D33B-4760-9BE5-0DF7F483F591', -- "Entity": "MJ_BizApps_Common": "Contact" "Methods"
        100021,
        'Person',
        'Person',
        NULL,
        'TEXT',
        200,
        0,
        0,
        TRUE,
        NULL,
        FALSE,
        FALSE,
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
        SELECT 1 FROM "${mjSchema}"."EntityField" WHERE "ID" = '99d4fe49-bc0b-4d9d-b7ec-84e04f7281ee' OR ("EntityID" = 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7' AND "Name" = 'Address')
    ) THEN
        INSERT INTO "${mjSchema}"."EntityField"
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
        '99d4fe49-bc0b-4d9d-b7ec-84e04f7281ee',
        'F2FC2E85-B210-43A9-8565-290AD9D0C6E7', -- "Entity": "MJ_BizApps_Common": "Address" "Links"
        100021,
        'Address',
        'Address',
        NULL,
        'TEXT',
        510,
        0,
        0,
        FALSE,
        NULL,
        FALSE,
        FALSE,
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
        SELECT 1 FROM "${mjSchema}"."EntityField" WHERE "ID" = '0f3e3c98-748b-4b54-9604-27f16e69b5b3' OR ("EntityID" = '709CA9DA-B124-4155-BE39-E857EF672D82' AND "Name" = 'FromPerson')
    ) THEN
        INSERT INTO "${mjSchema}"."EntityField"
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
        '0f3e3c98-748b-4b54-9604-27f16e69b5b3',
        '709CA9DA-B124-4155-BE39-E857EF672D82', -- "Entity": "MJ_BizApps_Common": "Relationships"
        100031,
        'FromPerson',
        'From Person',
        NULL,
        'TEXT',
        200,
        0,
        0,
        TRUE,
        NULL,
        FALSE,
        FALSE,
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
        SELECT 1 FROM "${mjSchema}"."EntityField" WHERE "ID" = '045230a0-3fed-4fec-94bd-cfc3dbf18245' OR ("EntityID" = '709CA9DA-B124-4155-BE39-E857EF672D82' AND "Name" = 'ToPerson')
    ) THEN
        INSERT INTO "${mjSchema}"."EntityField"
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
        '045230a0-3fed-4fec-94bd-cfc3dbf18245',
        '709CA9DA-B124-4155-BE39-E857EF672D82', -- "Entity": "MJ_BizApps_Common": "Relationships"
        100033,
        'ToPerson',
        'To Person',
        NULL,
        'TEXT',
        200,
        0,
        0,
        TRUE,
        NULL,
        FALSE,
        FALSE,
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

DO $$ BEGIN GRANT SELECT ON __mj_bizappscommon."vwAddressLinks" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View Permissions SQL for MJ_BizApps_Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Address Links
-- Item: Permissions for vwAddressLinks
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

DO $$ BEGIN GRANT SELECT ON __mj_bizappscommon."vwAddressLinks" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
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

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateAddressLink" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Address Links */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateAddressLink" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
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

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateAddressLink" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateAddressLink" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: vwContactMethods
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Contact Methods
-----               SCHEMA:      __mj_bizappscommon
-----               BASE TABLE:  ContactMethod
-----               PRIMARY KEY: ID
------------------------------------------------------------;

DO $$ BEGIN GRANT SELECT ON __mj_bizappscommon."vwContactMethods" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View Permissions SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: Permissions for vwContactMethods
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

DO $$ BEGIN GRANT SELECT ON __mj_bizappscommon."vwContactMethods" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
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

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateContactMethod" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Contact Methods */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateContactMethod" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
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

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateContactMethod" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateContactMethod" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
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

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteAddressLink" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Address Links */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteAddressLink" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
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

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteContactMethod" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Contact Methods */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteContactMethod" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
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

DO $$ BEGIN GRANT SELECT ON __mj_bizappscommon."vwRelationships" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View Permissions SQL for MJ_BizApps_Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
-- Item: Permissions for vwRelationships
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

DO $$ BEGIN GRANT SELECT ON __mj_bizappscommon."vwRelationships" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
-- Item: spCreateRelationship
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Relationship
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateRelationship" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Relationships */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateRelationship" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
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

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateRelationship" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateRelationship" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
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

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteRelationship" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Relationships */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteRelationship" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
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

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteOrganization" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Organizations */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteOrganization" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* SQL text to delete unneeded entity fields (3 scoped entities) */


-- ===================== Other =====================

-- =====================================================================
-- v5.29 Person DisplayName Wireup
-- =====================================================================
--
-- Regenerates BAC's views and stored procedures now that
-- Person."DisplayName"."IsNameField"=TRUE (flipped by the immediately-prior
-- V202605141056__v5.29.x__Metadata_Sync migration).
--
-- The earlier V202605131929 (Add Person DisplayName Computed Column)
-- migration installed views/sprocs that read Person."LastName" for the
-- FromPerson/ToPerson virtual columns on vwRelationships (because at
-- that point LastName was still the auto-picked IsNameField).
-- Now that DisplayName is the registered IsNameField, this migration
-- re-emits those artifacts to reference Person."DisplayName" instead.
--
-- Generated by `mj codegen` against a DB where all prior migrations
-- AND the Metadata_Sync had been applied. The trailing-semicolon
-- bug after CREATE TRIGGER blocks (`GO;` -> `GO`) is fixed here
-- inline; this is a CodeGen template bug that should be patched
-- upstream in MJ.
--
-- =====================================================================

/* SQL text to update existing entities from schema */

/* spUpdate Permissions for MJ_BizApps_Common: Address Links */

/* spUpdate Permissions for MJ_BizApps_Common: Contact Methods */

/* spUpdate Permissions for MJ_BizApps_Common: Relationships */
