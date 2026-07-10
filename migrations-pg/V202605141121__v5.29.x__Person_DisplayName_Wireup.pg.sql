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
AS SELECT a."ID",
    a."AddressID",
    a."EntityID",
    a."RecordID",
    a."AddressTypeID",
    a."IsPrimary",
    a."Rank",
    a."__mj_CreatedAt",
    a."__mj_UpdatedAt",
    mjbizappscommonaddress_addressid."Line1" AS "Address",
    mjentity_entityid."Name" AS "Entity",
    mjbizappscommonaddresstype_addresstypeid."Name" AS "AddressType"
   FROM __mj_bizappscommon."AddressLink" a
     JOIN __mj_bizappscommon."Address" mjbizappscommonaddress_addressid ON a."AddressID" = mjbizappscommonaddress_addressid."ID"
     JOIN "${mjSchema}"."Entity" mjentity_entityid ON a."EntityID" = mjentity_entityid."ID"
     JOIN __mj_bizappscommon."AddressType" mjbizappscommonaddresstype_addresstypeid ON a."AddressTypeID" = mjbizappscommonaddresstype_addresstypeid."ID"$vsql$;
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
AS SELECT c."ID",
    c."PersonID",
    c."OrganizationID",
    c."ContactTypeID",
    c."Value",
    c."Label",
    c."IsPrimary",
    c."__mj_CreatedAt",
    c."__mj_UpdatedAt",
    mjbizappscommonperson_personid."DisplayName" AS "Person",
    mjbizappscommonorganization_organizationid."Name" AS "Organization",
    mjbizappscommoncontacttype_contacttypeid."Name" AS "ContactType"
   FROM __mj_bizappscommon."ContactMethod" c
     LEFT JOIN __mj_bizappscommon."Person" mjbizappscommonperson_personid ON c."PersonID" = mjbizappscommonperson_personid."ID"
     LEFT JOIN __mj_bizappscommon."Organization" mjbizappscommonorganization_organizationid ON c."OrganizationID" = mjbizappscommonorganization_organizationid."ID"
     JOIN __mj_bizappscommon."ContactType" mjbizappscommoncontacttype_contacttypeid ON c."ContactTypeID" = mjbizappscommoncontacttype_contacttypeid."ID"$vsql$;
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
AS SELECT r."ID",
    r."RelationshipTypeID",
    r."FromPersonID",
    r."FromOrganizationID",
    r."ToPersonID",
    r."ToOrganizationID",
    r."Title",
    r."StartDate",
    r."EndDate",
    r."Status",
    r."Notes",
    r."__mj_CreatedAt",
    r."__mj_UpdatedAt",
    mjbizappscommonrelationshiptype_relationshiptypeid."Name" AS "RelationshipType",
    mjbizappscommonperson_frompersonid."DisplayName" AS "FromPerson",
    mjbizappscommonorganization_fromorganizationid."Name" AS "FromOrganization",
    mjbizappscommonperson_topersonid."DisplayName" AS "ToPerson",
    mjbizappscommonorganization_toorganizationid."Name" AS "ToOrganization"
   FROM __mj_bizappscommon."Relationship" r
     JOIN __mj_bizappscommon."RelationshipType" mjbizappscommonrelationshiptype_relationshiptypeid ON r."RelationshipTypeID" = mjbizappscommonrelationshiptype_relationshiptypeid."ID"
     LEFT JOIN __mj_bizappscommon."Person" mjbizappscommonperson_frompersonid ON r."FromPersonID" = mjbizappscommonperson_frompersonid."ID"
     LEFT JOIN __mj_bizappscommon."Organization" mjbizappscommonorganization_fromorganizationid ON r."FromOrganizationID" = mjbizappscommonorganization_fromorganizationid."ID"
     LEFT JOIN __mj_bizappscommon."Person" mjbizappscommonperson_topersonid ON r."ToPersonID" = mjbizappscommonperson_topersonid."ID"
     LEFT JOIN __mj_bizappscommon."Organization" mjbizappscommonorganization_toorganizationid ON r."ToOrganizationID" = mjbizappscommonorganization_toorganizationid."ID"$vsql$;
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

-- spDeleteOrganization: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spDeleteOrganization"(p_id uuid)
 RETURNS TABLE("ID" uuid)
 LANGUAGE plpgsql
AS $function$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
    v_rec RECORD;
BEGIN
    -- Cascade: Set MJ_BizApps_Common: Contact Methods.OrganizationID to NULL
    FOR v_rec IN
        SELECT "ID"
        FROM __mj_bizappscommon."ContactMethod"
        WHERE "OrganizationID" = p_id
    LOOP
        -- Update related record to set FK to NULL
        UPDATE __mj_bizappscommon."ContactMethod"
        SET "OrganizationID" = NULL
        WHERE "ID" = v_rec."ID";
    END LOOP;

        -- Cascade: Set MJ_BizApps_Common: Organizations.ParentID to NULL
    FOR v_rec IN
        SELECT "ID"
        FROM __mj_bizappscommon."Organization"
        WHERE "ParentID" = p_id
    LOOP
        -- Update related record to set FK to NULL
        UPDATE __mj_bizappscommon."Organization"
        SET "ParentID" = NULL
        WHERE "ID" = v_rec."ID";
    END LOOP;

        -- Cascade: Set MJ_BizApps_Common: Relationships.FromOrganizationID to NULL
    FOR v_rec IN
        SELECT "ID"
        FROM __mj_bizappscommon."Relationship"
        WHERE "FromOrganizationID" = p_id
    LOOP
        -- Update related record to set FK to NULL
        UPDATE __mj_bizappscommon."Relationship"
        SET "FromOrganizationID" = NULL
        WHERE "ID" = v_rec."ID";
    END LOOP;

        -- Cascade: Set MJ_BizApps_Common: Relationships.ToOrganizationID to NULL
    FOR v_rec IN
        SELECT "ID"
        FROM __mj_bizappscommon."Relationship"
        WHERE "ToOrganizationID" = p_id
    LOOP
        -- Update related record to set FK to NULL
        UPDATE __mj_bizappscommon."Relationship"
        SET "ToOrganizationID" = NULL
        WHERE "ID" = v_rec."ID";
    END LOOP;

    
    DELETE FROM __mj_bizappscommon."Organization"
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
