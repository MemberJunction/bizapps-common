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

-- =====================================================================
-- Add DisplayName computed column to Person
-- =====================================================================
--
-- Adds a PERSISTED computed column `DisplayName` to
-- __mj_bizappscommon."Person" defined as `FirstName + ' ' + LastName`.
--
-- Purpose: provide a friendly human-readable name for Person records
-- so that UI dropdowns, FK display tooltips, and Explorer pickers show
-- "John Doe" instead of just "Doe" (the auto-picked LastName
-- IsNameField default that BAC inherited from CodeGen).
--
-- Why PERSISTED:
--   - FirstName and LastName are both VARCHAR(100) NOT NULL, so the
--     concatenation is deterministic and always non-NULL.
--   - PERSISTED stores the computed value on disk, which lets the
--     column be indexed and read with no per-query computation cost.
--
-- The `IsNameField=true` metadata override that points at this column
-- ships in the follow-up Metadata_Sync migration once codegen has
-- registered DisplayName as an EntityField.
--
-- =====================================================================

-- PG equivalent of the SQL Server PERSISTED computed column: a STORED generated column.
-- T-SQL string `+` becomes PG `||`; `PERSISTED` becomes `STORED`. NOT NULL is omitted because the
-- `||` expression null-propagates when a name part is NULL (matching the SS `+` semantics) and the
-- column's nullability is carried by its EntityField metadata, not a hard table constraint.
ALTER TABLE __mj_bizappscommon."Person"
 ADD COLUMN IF NOT EXISTS "DisplayName" TEXT GENERATED ALWAYS AS ("FirstName" || ' ' || "LastName") STORED;

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Person_LinkedUserID" ON __mj_bizappscommon."Person" ("LinkedUserID");


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
    "mjBizAppsCommonPerson_PersonID"."LastName" AS "Person",
    "mjBizAppsCommonOrganization_OrganizationID"."Name" AS "Organization",
    "mjBizAppsCommonContactType_ContactTypeID"."Name" AS "ContactType"
FROM
    __mj_bizappscommon."ContactMethod" AS c
LEFT OUTER JOIN
    __mj_bizappscommon."Person" AS "mjBizAppsCommonPerson_PersonID"
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

DROP VIEW IF EXISTS __mj_bizappscommon."vwPeople" CASCADE;
DROP VIEW IF EXISTS __mj_bizappscommon."vwPeople" CASCADE;
DROP VIEW IF EXISTS __mj_bizappscommon."vwPeople" CASCADE;
DROP VIEW IF EXISTS __mj_bizappscommon."vwPeople" CASCADE;
DROP VIEW IF EXISTS __mj_bizappscommon."vwPeople" CASCADE;
DO $do$
DECLARE
  v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
  v_target_name CONSTANT TEXT := 'vwPeople';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_bizappscommon."vwPeople"
AS SELECT p."ID",
    p."FirstName",
    p."LastName",
    p."MiddleName",
    p."Prefix",
    p."Suffix",
    p."PreferredName",
    p."Title",
    p."Email",
    p."Phone",
    p."DateOfBirth",
    p."Gender",
    p."PhotoURL",
    p."Bio",
    p."LinkedUserID",
    p."Status",
    p."__mj_CreatedAt",
    p."__mj_UpdatedAt",
    p."DisplayName",
    mjuser_linkeduserid."Name" AS "LinkedUser"
   FROM __mj_bizappscommon."Person" p
     LEFT JOIN "${mjSchema}"."User" mjuser_linkeduserid ON p."LinkedUserID" = mjuser_linkeduserid."ID"$vsql$;
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
    "mjBizAppsCommonPerson_FromPersonID"."LastName" AS "FromPerson",
    "mjBizAppsCommonOrganization_FromOrganizationID"."Name" AS "FromOrganization",
    "mjBizAppsCommonPerson_ToPersonID"."LastName" AS "ToPerson",
    "mjBizAppsCommonOrganization_ToOrganizationID"."Name" AS "ToOrganization"
FROM
    __mj_bizappscommon."Relationship" AS r
INNER JOIN
    __mj_bizappscommon."RelationshipType" AS "mjBizAppsCommonRelationshipType_RelationshipTypeID"
  ON
    r."RelationshipTypeID" = "mjBizAppsCommonRelationshipType_RelationshipTypeID"."ID"
LEFT OUTER JOIN
    __mj_bizappscommon."Person" AS "mjBizAppsCommonPerson_FromPersonID"
  ON
    r."FromPersonID" = "mjBizAppsCommonPerson_FromPersonID"."ID"
LEFT OUTER JOIN
    __mj_bizappscommon."Organization" AS "mjBizAppsCommonOrganization_FromOrganizationID"
  ON
    r."FromOrganizationID" = "mjBizAppsCommonOrganization_FromOrganizationID"."ID"
LEFT OUTER JOIN
    __mj_bizappscommon."Person" AS "mjBizAppsCommonPerson_ToPersonID"
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

-- spCreateAddressLink: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spCreateAddressLink"(p_id uuid DEFAULT NULL::uuid, p_addressid uuid DEFAULT NULL::uuid, p_entityid uuid DEFAULT NULL::uuid, p_recordid character varying DEFAULT NULL::character varying, p_addresstypeid uuid DEFAULT NULL::uuid, p_isprimary boolean DEFAULT NULL::boolean, p_rank_clear boolean DEFAULT false, p_rank integer DEFAULT NULL::integer)
 RETURNS SETOF __mj_bizappscommon."vwAddressLinks"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO __mj_bizappscommon."AddressLink"
        (
            "ID",
            "AddressID",
                "EntityID",
                "RecordID",
                "AddressTypeID",
                "IsPrimary",
                "Rank"
        )
    VALUES
        (
            v_new_id,
            p_addressid,
                p_entityid,
                p_recordid,
                p_addresstypeid,
                COALESCE(p_isprimary, FALSE),
                CASE WHEN p_rank_clear = true THEN NULL ELSE COALESCE(p_rank, NULL) END
        )
    ;

    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwAddressLinks"
    WHERE "ID" = v_new_id;
END;
$function$;

-- spUpdateAddressLink: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spUpdateAddressLink"(p_id uuid, p_addressid uuid DEFAULT NULL::uuid, p_entityid uuid DEFAULT NULL::uuid, p_recordid character varying DEFAULT NULL::character varying, p_addresstypeid uuid DEFAULT NULL::uuid, p_isprimary boolean DEFAULT NULL::boolean, p_rank_clear boolean DEFAULT false, p_rank integer DEFAULT NULL::integer)
 RETURNS SETOF __mj_bizappscommon."vwAddressLinks"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE __mj_bizappscommon."AddressLink"
    SET
        "AddressID" = COALESCE(p_addressid, "AddressID"),
        "EntityID" = COALESCE(p_entityid, "EntityID"),
        "RecordID" = COALESCE(p_recordid, "RecordID"),
        "AddressTypeID" = COALESCE(p_addresstypeid, "AddressTypeID"),
        "IsPrimary" = COALESCE(p_isprimary, "IsPrimary"),
        "Rank" = CASE WHEN p_rank_clear = true THEN NULL ELSE COALESCE(p_rank, "Rank") END
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        -- Nothing was updated, return empty result set
        RETURN;
    END IF;

    -- Return the updated record from the base view
    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwAddressLinks"
    WHERE "ID" = p_id;
END;
$function$;

-- spDeleteAddressLink: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spDeleteAddressLink"(p_id uuid)
 RETURNS TABLE("ID" uuid)
 LANGUAGE plpgsql
AS $function$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
BEGIN

    DELETE FROM __mj_bizappscommon."AddressLink"
    WHERE "ID" = p_id;

    GET DIAGNOSTICS v_affected_count = ROW_COUNT;

    IF v_affected_count = 0 THEN
        RETURN QUERY SELECT NULL::UUID AS "ID";
    ELSE
        RETURN QUERY SELECT p_id AS "ID";
    END IF;
END;
$function$;

-- spCreateContactMethod: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spCreateContactMethod"(p_id uuid DEFAULT NULL::uuid, p_personid_clear boolean DEFAULT false, p_personid uuid DEFAULT NULL::uuid, p_organizationid_clear boolean DEFAULT false, p_organizationid uuid DEFAULT NULL::uuid, p_contacttypeid uuid DEFAULT NULL::uuid, p_value character varying DEFAULT NULL::character varying, p_label_clear boolean DEFAULT false, p_label character varying DEFAULT NULL::character varying, p_isprimary boolean DEFAULT NULL::boolean)
 RETURNS SETOF __mj_bizappscommon."vwContactMethods"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO __mj_bizappscommon."ContactMethod"
        (
            "ID",
            "PersonID",
                "OrganizationID",
                "ContactTypeID",
                "Value",
                "Label",
                "IsPrimary"
        )
    VALUES
        (
            v_new_id,
            CASE WHEN p_personid_clear = true THEN NULL ELSE COALESCE(p_personid, NULL) END,
                CASE WHEN p_organizationid_clear = true THEN NULL ELSE COALESCE(p_organizationid, NULL) END,
                p_contacttypeid,
                p_value,
                CASE WHEN p_label_clear = true THEN NULL ELSE COALESCE(p_label, NULL) END,
                COALESCE(p_isprimary, FALSE)
        )
    ;

    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwContactMethods"
    WHERE "ID" = v_new_id;
END;
$function$;

-- spUpdateContactMethod: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spUpdateContactMethod"(p_id uuid, p_personid_clear boolean DEFAULT false, p_personid uuid DEFAULT NULL::uuid, p_organizationid_clear boolean DEFAULT false, p_organizationid uuid DEFAULT NULL::uuid, p_contacttypeid uuid DEFAULT NULL::uuid, p_value character varying DEFAULT NULL::character varying, p_label_clear boolean DEFAULT false, p_label character varying DEFAULT NULL::character varying, p_isprimary boolean DEFAULT NULL::boolean)
 RETURNS SETOF __mj_bizappscommon."vwContactMethods"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE __mj_bizappscommon."ContactMethod"
    SET
        "PersonID" = CASE WHEN p_personid_clear = true THEN NULL ELSE COALESCE(p_personid, "PersonID") END,
        "OrganizationID" = CASE WHEN p_organizationid_clear = true THEN NULL ELSE COALESCE(p_organizationid, "OrganizationID") END,
        "ContactTypeID" = COALESCE(p_contacttypeid, "ContactTypeID"),
        "Value" = COALESCE(p_value, "Value"),
        "Label" = CASE WHEN p_label_clear = true THEN NULL ELSE COALESCE(p_label, "Label") END,
        "IsPrimary" = COALESCE(p_isprimary, "IsPrimary")
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        -- Nothing was updated, return empty result set
        RETURN;
    END IF;

    -- Return the updated record from the base view
    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwContactMethods"
    WHERE "ID" = p_id;
END;
$function$;

-- spDeleteContactMethod: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spDeleteContactMethod"(p_id uuid)
 RETURNS TABLE("ID" uuid)
 LANGUAGE plpgsql
AS $function$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
BEGIN

    DELETE FROM __mj_bizappscommon."ContactMethod"
    WHERE "ID" = p_id;

    GET DIAGNOSTICS v_affected_count = ROW_COUNT;

    IF v_affected_count = 0 THEN
        RETURN QUERY SELECT NULL::UUID AS "ID";
    ELSE
        RETURN QUERY SELECT p_id AS "ID";
    END IF;
END;
$function$;

-- spCreatePerson: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure).
-- References LinkedUserID (added in V202605201354); safe because plpgsql bodies are not
-- validated against columns until first execution, and nothing executes this during migration.
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spCreatePerson"(p_id uuid DEFAULT NULL::uuid, p_firstname character varying DEFAULT NULL::character varying, p_lastname character varying DEFAULT NULL::character varying, p_middlename_clear boolean DEFAULT false, p_middlename character varying DEFAULT NULL::character varying, p_prefix_clear boolean DEFAULT false, p_prefix character varying DEFAULT NULL::character varying, p_suffix_clear boolean DEFAULT false, p_suffix character varying DEFAULT NULL::character varying, p_preferredname_clear boolean DEFAULT false, p_preferredname character varying DEFAULT NULL::character varying, p_title_clear boolean DEFAULT false, p_title character varying DEFAULT NULL::character varying, p_email_clear boolean DEFAULT false, p_email character varying DEFAULT NULL::character varying, p_phone_clear boolean DEFAULT false, p_phone character varying DEFAULT NULL::character varying, p_dateofbirth_clear boolean DEFAULT false, p_dateofbirth date DEFAULT NULL::date, p_gender_clear boolean DEFAULT false, p_gender character varying DEFAULT NULL::character varying, p_photourl_clear boolean DEFAULT false, p_photourl character varying DEFAULT NULL::character varying, p_bio_clear boolean DEFAULT false, p_bio text DEFAULT NULL::text, p_linkeduserid_clear boolean DEFAULT false, p_linkeduserid uuid DEFAULT NULL::uuid, p_status character varying DEFAULT NULL::character varying)
 RETURNS SETOF __mj_bizappscommon."vwPeople"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO __mj_bizappscommon."Person"
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
                "Status"
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
                COALESCE(p_status, 'Active')
        )
    ;

    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwPeople"
    WHERE "ID" = v_new_id;
END;
$function$;

-- spUpdatePerson: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure).
-- References LinkedUserID (added in V202605201354); safe — see spCreatePerson note.
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spUpdatePerson"(p_id uuid, p_firstname character varying DEFAULT NULL::character varying, p_lastname character varying DEFAULT NULL::character varying, p_middlename_clear boolean DEFAULT false, p_middlename character varying DEFAULT NULL::character varying, p_prefix_clear boolean DEFAULT false, p_prefix character varying DEFAULT NULL::character varying, p_suffix_clear boolean DEFAULT false, p_suffix character varying DEFAULT NULL::character varying, p_preferredname_clear boolean DEFAULT false, p_preferredname character varying DEFAULT NULL::character varying, p_title_clear boolean DEFAULT false, p_title character varying DEFAULT NULL::character varying, p_email_clear boolean DEFAULT false, p_email character varying DEFAULT NULL::character varying, p_phone_clear boolean DEFAULT false, p_phone character varying DEFAULT NULL::character varying, p_dateofbirth_clear boolean DEFAULT false, p_dateofbirth date DEFAULT NULL::date, p_gender_clear boolean DEFAULT false, p_gender character varying DEFAULT NULL::character varying, p_photourl_clear boolean DEFAULT false, p_photourl character varying DEFAULT NULL::character varying, p_bio_clear boolean DEFAULT false, p_bio text DEFAULT NULL::text, p_linkeduserid_clear boolean DEFAULT false, p_linkeduserid uuid DEFAULT NULL::uuid, p_status character varying DEFAULT NULL::character varying)
 RETURNS SETOF __mj_bizappscommon."vwPeople"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE __mj_bizappscommon."Person"
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
    SELECT * FROM __mj_bizappscommon."vwPeople"
    WHERE "ID" = p_id;
END;
$function$;

-- spDeletePerson: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spDeletePerson"(p_id uuid)
 RETURNS TABLE("ID" uuid)
 LANGUAGE plpgsql
AS $function$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
BEGIN

    DELETE FROM __mj_bizappscommon."Person"
    WHERE "ID" = p_id;

    GET DIAGNOSTICS v_affected_count = ROW_COUNT;

    IF v_affected_count = 0 THEN
        RETURN QUERY SELECT NULL::UUID AS "ID";
    ELSE
        RETURN QUERY SELECT p_id AS "ID";
    END IF;
END;
$function$;

-- spCreateRelationship: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spCreateRelationship"(p_id uuid DEFAULT NULL::uuid, p_relationshiptypeid uuid DEFAULT NULL::uuid, p_frompersonid_clear boolean DEFAULT false, p_frompersonid uuid DEFAULT NULL::uuid, p_fromorganizationid_clear boolean DEFAULT false, p_fromorganizationid uuid DEFAULT NULL::uuid, p_topersonid_clear boolean DEFAULT false, p_topersonid uuid DEFAULT NULL::uuid, p_toorganizationid_clear boolean DEFAULT false, p_toorganizationid uuid DEFAULT NULL::uuid, p_title_clear boolean DEFAULT false, p_title character varying DEFAULT NULL::character varying, p_startdate_clear boolean DEFAULT false, p_startdate date DEFAULT NULL::date, p_enddate_clear boolean DEFAULT false, p_enddate date DEFAULT NULL::date, p_status character varying DEFAULT NULL::character varying, p_notes_clear boolean DEFAULT false, p_notes text DEFAULT NULL::text)
 RETURNS SETOF __mj_bizappscommon."vwRelationships"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO __mj_bizappscommon."Relationship"
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
                "Notes"
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
                CASE WHEN p_notes_clear = true THEN NULL ELSE COALESCE(p_notes, NULL) END
        )
    ;

    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwRelationships"
    WHERE "ID" = v_new_id;
END;
$function$;

-- spUpdateRelationship: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spUpdateRelationship"(p_id uuid, p_relationshiptypeid uuid DEFAULT NULL::uuid, p_frompersonid_clear boolean DEFAULT false, p_frompersonid uuid DEFAULT NULL::uuid, p_fromorganizationid_clear boolean DEFAULT false, p_fromorganizationid uuid DEFAULT NULL::uuid, p_topersonid_clear boolean DEFAULT false, p_topersonid uuid DEFAULT NULL::uuid, p_toorganizationid_clear boolean DEFAULT false, p_toorganizationid uuid DEFAULT NULL::uuid, p_title_clear boolean DEFAULT false, p_title character varying DEFAULT NULL::character varying, p_startdate_clear boolean DEFAULT false, p_startdate date DEFAULT NULL::date, p_enddate_clear boolean DEFAULT false, p_enddate date DEFAULT NULL::date, p_status character varying DEFAULT NULL::character varying, p_notes_clear boolean DEFAULT false, p_notes text DEFAULT NULL::text)
 RETURNS SETOF __mj_bizappscommon."vwRelationships"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE __mj_bizappscommon."Relationship"
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
        "Notes" = CASE WHEN p_notes_clear = true THEN NULL ELSE COALESCE(p_notes, "Notes") END
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        -- Nothing was updated, return empty result set
        RETURN;
    END IF;

    -- Return the updated record from the base view
    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwRelationships"
    WHERE "ID" = p_id;
END;
$function$;

-- spDeleteRelationship: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spDeleteRelationship"(p_id uuid)
 RETURNS TABLE("ID" uuid)
 LANGUAGE plpgsql
AS $function$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
BEGIN

    DELETE FROM __mj_bizappscommon."Relationship"
    WHERE "ID" = p_id;

    GET DIAGNOSTICS v_affected_count = ROW_COUNT;

    IF v_affected_count = 0 THEN
        RETURN QUERY SELECT NULL::UUID AS "ID";
    ELSE
        RETURN QUERY SELECT p_id AS "ID";
    END IF;
END;
$function$;


-- ===================== Triggers =====================

-- trg_update_address_link: native row-touch trigger as emitted by MJ CodeGen (replaces the skipped T-SQL trigger)
CREATE OR REPLACE FUNCTION __mj_bizappscommon.fn_trg_update_address_link()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW."__mj_UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_update_address_link ON __mj_bizappscommon."AddressLink";
CREATE TRIGGER trg_update_address_link BEFORE UPDATE ON __mj_bizappscommon."AddressLink" FOR EACH ROW EXECUTE FUNCTION __mj_bizappscommon.fn_trg_update_address_link();
 

-- trg_update_contact_method: native row-touch trigger as emitted by MJ CodeGen (replaces the skipped T-SQL trigger)
CREATE OR REPLACE FUNCTION __mj_bizappscommon.fn_trg_update_contact_method()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW."__mj_UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_update_contact_method ON __mj_bizappscommon."ContactMethod";
CREATE TRIGGER trg_update_contact_method BEFORE UPDATE ON __mj_bizappscommon."ContactMethod" FOR EACH ROW EXECUTE FUNCTION __mj_bizappscommon.fn_trg_update_contact_method();
   

-- trg_update_person: native row-touch trigger as emitted by MJ CodeGen (replaces the skipped T-SQL trigger)
CREATE OR REPLACE FUNCTION __mj_bizappscommon.fn_trg_update_person()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW."__mj_UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_update_person ON __mj_bizappscommon."Person";
CREATE TRIGGER trg_update_person BEFORE UPDATE ON __mj_bizappscommon."Person" FOR EACH ROW EXECUTE FUNCTION __mj_bizappscommon.fn_trg_update_person();

-- trg_update_relationship: native row-touch trigger as emitted by MJ CodeGen (replaces the skipped T-SQL trigger)
CREATE OR REPLACE FUNCTION __mj_bizappscommon.fn_trg_update_relationship()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW."__mj_UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_update_relationship ON __mj_bizappscommon."Relationship";
CREATE TRIGGER trg_update_relationship BEFORE UPDATE ON __mj_bizappscommon."Relationship" FOR EACH ROW EXECUTE FUNCTION __mj_bizappscommon.fn_trg_update_relationship();


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM "${mjSchema}"."EntityField" WHERE "ID" = '76d49448-c586-4701-9fff-63f390ec78c0' OR ("EntityID" = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND "Name" = 'DisplayName')
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
        '76d49448-c586-4701-9fff-63f390ec78c0',
        '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- "Entity": "MJ_BizApps_Common": "People"
        100038,
        'DisplayName',
        'Display Name',
        NULL,
        'TEXT',
        402,
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
/* Index for Foreign Keys for Person */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: People
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key LinkedUserID in table Person;

DO $$ BEGIN GRANT SELECT ON __mj_bizappscommon."vwPeople" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View Permissions SQL for MJ_BizApps_Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: People
-- Item: Permissions for vwPeople
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

DO $$ BEGIN GRANT SELECT ON __mj_bizappscommon."vwPeople" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: People
-- Item: spCreatePerson
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Person
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreatePerson" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: People */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreatePerson" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
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

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdatePerson" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdatePerson" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
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

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeletePerson" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: People */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeletePerson" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* SQL text to update entity field related entity name field map for entity field ID AD3ECDAA-E2BE-40D9-B83E-1868AB68C778 */

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
/* SQL text to delete unneeded entity fields (1 scoped entities) */


-- ===================== Other =====================

-- =====================================================================
-- CodeGen output (vwPeople regen + EntityField row for DisplayName +
-- related-entity SP regens). Generated by `mj codegen` against a DB
-- where the ALTER TABLE above had been applied.
-- =====================================================================

/* SQL text to update existing entities from schema */

/* spUpdate Permissions for MJ_BizApps_Common: Address Links */

/* spUpdate Permissions for MJ_BizApps_Common: Contact Methods */

/* spUpdate Permissions for MJ_BizApps_Common: People */

/* spUpdate Permissions for MJ_BizApps_Common: Relationships */
