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


-- ===================== Stored Procedures (sp*) =====================

-- spCreateAddressType: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spCreateAddressType"(p_id uuid DEFAULT NULL::uuid, p_name character varying DEFAULT NULL::character varying, p_description_clear boolean DEFAULT false, p_description text DEFAULT NULL::text, p_iconclass_clear boolean DEFAULT false, p_iconclass character varying DEFAULT NULL::character varying, p_defaultrank integer DEFAULT NULL::integer, p_isactive boolean DEFAULT NULL::boolean)
 RETURNS SETOF __mj_bizappscommon."vwAddressTypes"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO __mj_bizappscommon."AddressType"
        (
            "ID",
            "Name",
                "Description",
                "IconClass",
                "DefaultRank",
                "IsActive"
        )
    VALUES
        (
            v_new_id,
            p_name,
                CASE WHEN p_description_clear = true THEN NULL ELSE COALESCE(p_description, NULL) END,
                CASE WHEN p_iconclass_clear = true THEN NULL ELSE COALESCE(p_iconclass, NULL) END,
                COALESCE(p_defaultrank, 100),
                COALESCE(p_isactive, TRUE)
        )
    ;

    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwAddressTypes"
    WHERE "ID" = v_new_id;
END;
$function$;

-- spUpdateAddressType: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spUpdateAddressType"(p_id uuid, p_name character varying DEFAULT NULL::character varying, p_description_clear boolean DEFAULT false, p_description text DEFAULT NULL::text, p_iconclass_clear boolean DEFAULT false, p_iconclass character varying DEFAULT NULL::character varying, p_defaultrank integer DEFAULT NULL::integer, p_isactive boolean DEFAULT NULL::boolean)
 RETURNS SETOF __mj_bizappscommon."vwAddressTypes"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE __mj_bizappscommon."AddressType"
    SET
        "Name" = COALESCE(p_name, "Name"),
        "Description" = CASE WHEN p_description_clear = true THEN NULL ELSE COALESCE(p_description, "Description") END,
        "IconClass" = CASE WHEN p_iconclass_clear = true THEN NULL ELSE COALESCE(p_iconclass, "IconClass") END,
        "DefaultRank" = COALESCE(p_defaultrank, "DefaultRank"),
        "IsActive" = COALESCE(p_isactive, "IsActive")
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        -- Nothing was updated, return empty result set
        RETURN;
    END IF;

    -- Return the updated record from the base view
    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwAddressTypes"
    WHERE "ID" = p_id;
END;
$function$;

-- spDeleteAddressType: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spDeleteAddressType"(p_id uuid)
 RETURNS TABLE("ID" uuid)
 LANGUAGE plpgsql
AS $function$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
BEGIN

    DELETE FROM __mj_bizappscommon."AddressType"
    WHERE "ID" = p_id;

    GET DIAGNOSTICS v_affected_count = ROW_COUNT;

    IF v_affected_count = 0 THEN
        RETURN QUERY SELECT NULL::UUID AS "ID";
    ELSE
        RETURN QUERY SELECT p_id AS "ID";
    END IF;
END;
$function$;

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

-- spCreateAddress: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spCreateAddress"(p_id uuid DEFAULT NULL::uuid, p_line1 character varying DEFAULT NULL::character varying, p_line2_clear boolean DEFAULT false, p_line2 character varying DEFAULT NULL::character varying, p_line3_clear boolean DEFAULT false, p_line3 character varying DEFAULT NULL::character varying, p_city character varying DEFAULT NULL::character varying, p_stateprovince_clear boolean DEFAULT false, p_stateprovince character varying DEFAULT NULL::character varying, p_postalcode_clear boolean DEFAULT false, p_postalcode character varying DEFAULT NULL::character varying, p_country character varying DEFAULT NULL::character varying, p_latitude_clear boolean DEFAULT false, p_latitude numeric DEFAULT NULL::numeric, p_longitude_clear boolean DEFAULT false, p_longitude numeric DEFAULT NULL::numeric)
 RETURNS SETOF __mj_bizappscommon."vwAddresses"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO __mj_bizappscommon."Address"
        (
            "ID",
            "Line1",
                "Line2",
                "Line3",
                "City",
                "StateProvince",
                "PostalCode",
                "Country",
                "Latitude",
                "Longitude"
        )
    VALUES
        (
            v_new_id,
            p_line1,
                CASE WHEN p_line2_clear = true THEN NULL ELSE COALESCE(p_line2, NULL) END,
                CASE WHEN p_line3_clear = true THEN NULL ELSE COALESCE(p_line3, NULL) END,
                p_city,
                CASE WHEN p_stateprovince_clear = true THEN NULL ELSE COALESCE(p_stateprovince, NULL) END,
                CASE WHEN p_postalcode_clear = true THEN NULL ELSE COALESCE(p_postalcode, NULL) END,
                COALESCE(p_country, 'US'),
                CASE WHEN p_latitude_clear = true THEN NULL ELSE COALESCE(p_latitude, NULL) END,
                CASE WHEN p_longitude_clear = true THEN NULL ELSE COALESCE(p_longitude, NULL) END
        )
    ;

    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwAddresses"
    WHERE "ID" = v_new_id;
END;
$function$;

-- spUpdateAddress: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spUpdateAddress"(p_id uuid, p_line1 character varying DEFAULT NULL::character varying, p_line2_clear boolean DEFAULT false, p_line2 character varying DEFAULT NULL::character varying, p_line3_clear boolean DEFAULT false, p_line3 character varying DEFAULT NULL::character varying, p_city character varying DEFAULT NULL::character varying, p_stateprovince_clear boolean DEFAULT false, p_stateprovince character varying DEFAULT NULL::character varying, p_postalcode_clear boolean DEFAULT false, p_postalcode character varying DEFAULT NULL::character varying, p_country character varying DEFAULT NULL::character varying, p_latitude_clear boolean DEFAULT false, p_latitude numeric DEFAULT NULL::numeric, p_longitude_clear boolean DEFAULT false, p_longitude numeric DEFAULT NULL::numeric)
 RETURNS SETOF __mj_bizappscommon."vwAddresses"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE __mj_bizappscommon."Address"
    SET
        "Line1" = COALESCE(p_line1, "Line1"),
        "Line2" = CASE WHEN p_line2_clear = true THEN NULL ELSE COALESCE(p_line2, "Line2") END,
        "Line3" = CASE WHEN p_line3_clear = true THEN NULL ELSE COALESCE(p_line3, "Line3") END,
        "City" = COALESCE(p_city, "City"),
        "StateProvince" = CASE WHEN p_stateprovince_clear = true THEN NULL ELSE COALESCE(p_stateprovince, "StateProvince") END,
        "PostalCode" = CASE WHEN p_postalcode_clear = true THEN NULL ELSE COALESCE(p_postalcode, "PostalCode") END,
        "Country" = COALESCE(p_country, "Country"),
        "Latitude" = CASE WHEN p_latitude_clear = true THEN NULL ELSE COALESCE(p_latitude, "Latitude") END,
        "Longitude" = CASE WHEN p_longitude_clear = true THEN NULL ELSE COALESCE(p_longitude, "Longitude") END
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        -- Nothing was updated, return empty result set
        RETURN;
    END IF;

    -- Return the updated record from the base view
    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwAddresses"
    WHERE "ID" = p_id;
END;
$function$;

-- spDeleteAddress: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spDeleteAddress"(p_id uuid)
 RETURNS TABLE("ID" uuid)
 LANGUAGE plpgsql
AS $function$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
BEGIN

    DELETE FROM __mj_bizappscommon."Address"
    WHERE "ID" = p_id;

    GET DIAGNOSTICS v_affected_count = ROW_COUNT;

    IF v_affected_count = 0 THEN
        RETURN QUERY SELECT NULL::UUID AS "ID";
    ELSE
        RETURN QUERY SELECT p_id AS "ID";
    END IF;
END;
$function$;

-- spCreateContactType: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spCreateContactType"(p_id uuid DEFAULT NULL::uuid, p_name character varying DEFAULT NULL::character varying, p_description_clear boolean DEFAULT false, p_description text DEFAULT NULL::text, p_iconclass_clear boolean DEFAULT false, p_iconclass character varying DEFAULT NULL::character varying, p_displayrank integer DEFAULT NULL::integer, p_isactive boolean DEFAULT NULL::boolean)
 RETURNS SETOF __mj_bizappscommon."vwContactTypes"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO __mj_bizappscommon."ContactType"
        (
            "ID",
            "Name",
                "Description",
                "IconClass",
                "DisplayRank",
                "IsActive"
        )
    VALUES
        (
            v_new_id,
            p_name,
                CASE WHEN p_description_clear = true THEN NULL ELSE COALESCE(p_description, NULL) END,
                CASE WHEN p_iconclass_clear = true THEN NULL ELSE COALESCE(p_iconclass, NULL) END,
                COALESCE(p_displayrank, 100),
                COALESCE(p_isactive, TRUE)
        )
    ;

    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwContactTypes"
    WHERE "ID" = v_new_id;
END;
$function$;

-- spUpdateContactType: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spUpdateContactType"(p_id uuid, p_name character varying DEFAULT NULL::character varying, p_description_clear boolean DEFAULT false, p_description text DEFAULT NULL::text, p_iconclass_clear boolean DEFAULT false, p_iconclass character varying DEFAULT NULL::character varying, p_displayrank integer DEFAULT NULL::integer, p_isactive boolean DEFAULT NULL::boolean)
 RETURNS SETOF __mj_bizappscommon."vwContactTypes"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE __mj_bizappscommon."ContactType"
    SET
        "Name" = COALESCE(p_name, "Name"),
        "Description" = CASE WHEN p_description_clear = true THEN NULL ELSE COALESCE(p_description, "Description") END,
        "IconClass" = CASE WHEN p_iconclass_clear = true THEN NULL ELSE COALESCE(p_iconclass, "IconClass") END,
        "DisplayRank" = COALESCE(p_displayrank, "DisplayRank"),
        "IsActive" = COALESCE(p_isactive, "IsActive")
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        -- Nothing was updated, return empty result set
        RETURN;
    END IF;

    -- Return the updated record from the base view
    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwContactTypes"
    WHERE "ID" = p_id;
END;
$function$;

-- spDeleteContactType: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spDeleteContactType"(p_id uuid)
 RETURNS TABLE("ID" uuid)
 LANGUAGE plpgsql
AS $function$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
BEGIN

    DELETE FROM __mj_bizappscommon."ContactType"
    WHERE "ID" = p_id;

    GET DIAGNOSTICS v_affected_count = ROW_COUNT;

    IF v_affected_count = 0 THEN
        RETURN QUERY SELECT NULL::UUID AS "ID";
    ELSE
        RETURN QUERY SELECT p_id AS "ID";
    END IF;
END;
$function$;

-- spCreateOrganization: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spCreateOrganization"(p_id uuid DEFAULT NULL::uuid, p_name character varying DEFAULT NULL::character varying, p_legalname_clear boolean DEFAULT false, p_legalname character varying DEFAULT NULL::character varying, p_organizationtypeid_clear boolean DEFAULT false, p_organizationtypeid uuid DEFAULT NULL::uuid, p_parentid_clear boolean DEFAULT false, p_parentid uuid DEFAULT NULL::uuid, p_website_clear boolean DEFAULT false, p_website character varying DEFAULT NULL::character varying, p_logourl_clear boolean DEFAULT false, p_logourl character varying DEFAULT NULL::character varying, p_description_clear boolean DEFAULT false, p_description text DEFAULT NULL::text, p_email_clear boolean DEFAULT false, p_email character varying DEFAULT NULL::character varying, p_phone_clear boolean DEFAULT false, p_phone character varying DEFAULT NULL::character varying, p_foundeddate_clear boolean DEFAULT false, p_foundeddate date DEFAULT NULL::date, p_taxid_clear boolean DEFAULT false, p_taxid character varying DEFAULT NULL::character varying, p_status character varying DEFAULT NULL::character varying)
 RETURNS SETOF __mj_bizappscommon."vwOrganizations"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO __mj_bizappscommon."Organization"
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
    SELECT * FROM __mj_bizappscommon."vwOrganizations"
    WHERE "ID" = v_new_id;
END;
$function$;

-- spUpdateOrganization: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spUpdateOrganization"(p_id uuid, p_name character varying DEFAULT NULL::character varying, p_legalname_clear boolean DEFAULT false, p_legalname character varying DEFAULT NULL::character varying, p_organizationtypeid_clear boolean DEFAULT false, p_organizationtypeid uuid DEFAULT NULL::uuid, p_parentid_clear boolean DEFAULT false, p_parentid uuid DEFAULT NULL::uuid, p_website_clear boolean DEFAULT false, p_website character varying DEFAULT NULL::character varying, p_logourl_clear boolean DEFAULT false, p_logourl character varying DEFAULT NULL::character varying, p_description_clear boolean DEFAULT false, p_description text DEFAULT NULL::text, p_email_clear boolean DEFAULT false, p_email character varying DEFAULT NULL::character varying, p_phone_clear boolean DEFAULT false, p_phone character varying DEFAULT NULL::character varying, p_foundeddate_clear boolean DEFAULT false, p_foundeddate date DEFAULT NULL::date, p_taxid_clear boolean DEFAULT false, p_taxid character varying DEFAULT NULL::character varying, p_status character varying DEFAULT NULL::character varying)
 RETURNS SETOF __mj_bizappscommon."vwOrganizations"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE __mj_bizappscommon."Organization"
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
    SELECT * FROM __mj_bizappscommon."vwOrganizations"
    WHERE "ID" = p_id;
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

-- spCreateOrganizationType: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spCreateOrganizationType"(p_id uuid DEFAULT NULL::uuid, p_name character varying DEFAULT NULL::character varying, p_description_clear boolean DEFAULT false, p_description text DEFAULT NULL::text, p_iconclass_clear boolean DEFAULT false, p_iconclass character varying DEFAULT NULL::character varying, p_displayrank integer DEFAULT NULL::integer, p_isactive boolean DEFAULT NULL::boolean)
 RETURNS SETOF __mj_bizappscommon."vwOrganizationTypes"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO __mj_bizappscommon."OrganizationType"
        (
            "ID",
            "Name",
                "Description",
                "IconClass",
                "DisplayRank",
                "IsActive"
        )
    VALUES
        (
            v_new_id,
            p_name,
                CASE WHEN p_description_clear = true THEN NULL ELSE COALESCE(p_description, NULL) END,
                CASE WHEN p_iconclass_clear = true THEN NULL ELSE COALESCE(p_iconclass, NULL) END,
                COALESCE(p_displayrank, 100),
                COALESCE(p_isactive, TRUE)
        )
    ;

    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwOrganizationTypes"
    WHERE "ID" = v_new_id;
END;
$function$;

-- spUpdateOrganizationType: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spUpdateOrganizationType"(p_id uuid, p_name character varying DEFAULT NULL::character varying, p_description_clear boolean DEFAULT false, p_description text DEFAULT NULL::text, p_iconclass_clear boolean DEFAULT false, p_iconclass character varying DEFAULT NULL::character varying, p_displayrank integer DEFAULT NULL::integer, p_isactive boolean DEFAULT NULL::boolean)
 RETURNS SETOF __mj_bizappscommon."vwOrganizationTypes"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE __mj_bizappscommon."OrganizationType"
    SET
        "Name" = COALESCE(p_name, "Name"),
        "Description" = CASE WHEN p_description_clear = true THEN NULL ELSE COALESCE(p_description, "Description") END,
        "IconClass" = CASE WHEN p_iconclass_clear = true THEN NULL ELSE COALESCE(p_iconclass, "IconClass") END,
        "DisplayRank" = COALESCE(p_displayrank, "DisplayRank"),
        "IsActive" = COALESCE(p_isactive, "IsActive")
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        -- Nothing was updated, return empty result set
        RETURN;
    END IF;

    -- Return the updated record from the base view
    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwOrganizationTypes"
    WHERE "ID" = p_id;
END;
$function$;

-- spDeleteOrganizationType: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spDeleteOrganizationType"(p_id uuid)
 RETURNS TABLE("ID" uuid)
 LANGUAGE plpgsql
AS $function$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
BEGIN

    DELETE FROM __mj_bizappscommon."OrganizationType"
    WHERE "ID" = p_id;

    GET DIAGNOSTICS v_affected_count = ROW_COUNT;

    IF v_affected_count = 0 THEN
        RETURN QUERY SELECT NULL::UUID AS "ID";
    ELSE
        RETURN QUERY SELECT p_id AS "ID";
    END IF;
END;
$function$;

-- spCreateRelationshipType: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spCreateRelationshipType"(p_id uuid DEFAULT NULL::uuid, p_name character varying DEFAULT NULL::character varying, p_description_clear boolean DEFAULT false, p_description text DEFAULT NULL::text, p_category character varying DEFAULT NULL::character varying, p_isdirectional boolean DEFAULT NULL::boolean, p_forwardlabel_clear boolean DEFAULT false, p_forwardlabel character varying DEFAULT NULL::character varying, p_reverselabel_clear boolean DEFAULT false, p_reverselabel character varying DEFAULT NULL::character varying, p_isactive boolean DEFAULT NULL::boolean)
 RETURNS SETOF __mj_bizappscommon."vwRelationshipTypes"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_new_id UUID;
BEGIN
    v_new_id := COALESCE(p_id, gen_random_uuid());
    INSERT INTO __mj_bizappscommon."RelationshipType"
        (
            "ID",
            "Name",
                "Description",
                "Category",
                "IsDirectional",
                "ForwardLabel",
                "ReverseLabel",
                "IsActive"
        )
    VALUES
        (
            v_new_id,
            p_name,
                CASE WHEN p_description_clear = true THEN NULL ELSE COALESCE(p_description, NULL) END,
                p_category,
                COALESCE(p_isdirectional, TRUE),
                CASE WHEN p_forwardlabel_clear = true THEN NULL ELSE COALESCE(p_forwardlabel, NULL) END,
                CASE WHEN p_reverselabel_clear = true THEN NULL ELSE COALESCE(p_reverselabel, NULL) END,
                COALESCE(p_isactive, TRUE)
        )
    ;

    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwRelationshipTypes"
    WHERE "ID" = v_new_id;
END;
$function$;

-- spUpdateRelationshipType: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spUpdateRelationshipType"(p_id uuid, p_name character varying DEFAULT NULL::character varying, p_description_clear boolean DEFAULT false, p_description text DEFAULT NULL::text, p_category character varying DEFAULT NULL::character varying, p_isdirectional boolean DEFAULT NULL::boolean, p_forwardlabel_clear boolean DEFAULT false, p_forwardlabel character varying DEFAULT NULL::character varying, p_reverselabel_clear boolean DEFAULT false, p_reverselabel character varying DEFAULT NULL::character varying, p_isactive boolean DEFAULT NULL::boolean)
 RETURNS SETOF __mj_bizappscommon."vwRelationshipTypes"
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE __mj_bizappscommon."RelationshipType"
    SET
        "Name" = COALESCE(p_name, "Name"),
        "Description" = CASE WHEN p_description_clear = true THEN NULL ELSE COALESCE(p_description, "Description") END,
        "Category" = COALESCE(p_category, "Category"),
        "IsDirectional" = COALESCE(p_isdirectional, "IsDirectional"),
        "ForwardLabel" = CASE WHEN p_forwardlabel_clear = true THEN NULL ELSE COALESCE(p_forwardlabel, "ForwardLabel") END,
        "ReverseLabel" = CASE WHEN p_reverselabel_clear = true THEN NULL ELSE COALESCE(p_reverselabel, "ReverseLabel") END,
        "IsActive" = COALESCE(p_isactive, "IsActive")
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        -- Nothing was updated, return empty result set
        RETURN;
    END IF;

    -- Return the updated record from the base view
    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwRelationshipTypes"
    WHERE "ID" = p_id;
END;
$function$;

-- spDeleteRelationshipType: native plpgsql as emitted by MJ CodeGen (replaces the skipped T-SQL procedure)
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spDeleteRelationshipType"(p_id uuid)
 RETURNS TABLE("ID" uuid)
 LANGUAGE plpgsql
AS $function$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
BEGIN

    DELETE FROM __mj_bizappscommon."RelationshipType"
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

-- trg_update_address_type: native row-touch trigger as emitted by MJ CodeGen (replaces the skipped T-SQL trigger)
CREATE OR REPLACE FUNCTION __mj_bizappscommon.fn_trg_update_address_type()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW."__mj_UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_update_address_type ON __mj_bizappscommon."AddressType";
CREATE TRIGGER trg_update_address_type BEFORE UPDATE ON __mj_bizappscommon."AddressType" FOR EACH ROW EXECUTE FUNCTION __mj_bizappscommon.fn_trg_update_address_type();
 

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
   

-- trg_update_address: native row-touch trigger as emitted by MJ CodeGen (replaces the skipped T-SQL trigger)
CREATE OR REPLACE FUNCTION __mj_bizappscommon.fn_trg_update_address()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW."__mj_UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_update_address ON __mj_bizappscommon."Address";
CREATE TRIGGER trg_update_address BEFORE UPDATE ON __mj_bizappscommon."Address" FOR EACH ROW EXECUTE FUNCTION __mj_bizappscommon.fn_trg_update_address();

-- trg_update_contact_type: native row-touch trigger as emitted by MJ CodeGen (replaces the skipped T-SQL trigger)
CREATE OR REPLACE FUNCTION __mj_bizappscommon.fn_trg_update_contact_type()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW."__mj_UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_update_contact_type ON __mj_bizappscommon."ContactType";
CREATE TRIGGER trg_update_contact_type BEFORE UPDATE ON __mj_bizappscommon."ContactType" FOR EACH ROW EXECUTE FUNCTION __mj_bizappscommon.fn_trg_update_contact_type();
 

-- trg_update_organization: native row-touch trigger as emitted by MJ CodeGen (replaces the skipped T-SQL trigger)
CREATE OR REPLACE FUNCTION __mj_bizappscommon.fn_trg_update_organization()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW."__mj_UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_update_organization ON __mj_bizappscommon."Organization";
CREATE TRIGGER trg_update_organization BEFORE UPDATE ON __mj_bizappscommon."Organization" FOR EACH ROW EXECUTE FUNCTION __mj_bizappscommon.fn_trg_update_organization();

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

-- trg_update_organization_type: native row-touch trigger as emitted by MJ CodeGen (replaces the skipped T-SQL trigger)
CREATE OR REPLACE FUNCTION __mj_bizappscommon.fn_trg_update_organization_type()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW."__mj_UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_update_organization_type ON __mj_bizappscommon."OrganizationType";
CREATE TRIGGER trg_update_organization_type BEFORE UPDATE ON __mj_bizappscommon."OrganizationType" FOR EACH ROW EXECUTE FUNCTION __mj_bizappscommon.fn_trg_update_organization_type();

-- trg_update_relationship_type: native row-touch trigger as emitted by MJ CodeGen (replaces the skipped T-SQL trigger)
CREATE OR REPLACE FUNCTION __mj_bizappscommon.fn_trg_update_relationship_type()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW."__mj_UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_update_relationship_type ON __mj_bizappscommon."RelationshipType";
CREATE TRIGGER trg_update_relationship_type BEFORE UPDATE ON __mj_bizappscommon."RelationshipType" FOR EACH ROW EXECUTE FUNCTION __mj_bizappscommon.fn_trg_update_relationship_type();


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

UPDATE __mj."Entity"
SET    "CascadeDeletes" = TRUE
WHERE  "Name" = 'MJ_BizApps_Common: Organizations';

-- Sanity check: ensure exactly one row was updated. If zero, the entity
-- was missing (Metadata_Sync hasn't run, or entity was renamed). If
-- multiple, something is very wrong.


-- ===================== Grants =====================

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateAddressType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Address Types */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateAddressType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Address Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Address Types
-- Item: spUpdateAddressType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR AddressType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateAddressType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateAddressType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Address Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Address Types
-- Item: spDeleteAddressType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR AddressType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteAddressType" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Address Types */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteAddressType" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
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

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateAddress" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Addresses */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateAddress" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
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

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateAddress" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateAddress" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
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

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteAddress" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Addresses */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteAddress" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Types
-- Item: spCreateContactType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ContactType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateContactType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Contact Types */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateContactType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Types
-- Item: spUpdateContactType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ContactType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateContactType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateContactType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Types
-- Item: spDeleteContactType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ContactType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteContactType" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Contact Types */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteContactType" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: spCreateOrganization
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Organization
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateOrganization" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Organizations */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateOrganization" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
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

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateOrganization" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateOrganization" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
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
/* spCreate SQL for MJ_BizApps_Common: Organization Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organization Types
-- Item: spCreateOrganizationType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR OrganizationType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateOrganizationType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Organization Types */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateOrganizationType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Organization Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organization Types
-- Item: spUpdateOrganizationType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR OrganizationType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateOrganizationType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateOrganizationType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Organization Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organization Types
-- Item: spDeleteOrganizationType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR OrganizationType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteOrganizationType" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Organization Types */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteOrganizationType" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Relationship Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationship Types
-- Item: spCreateRelationshipType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR RelationshipType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateRelationshipType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Relationship Types */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateRelationshipType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Relationship Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationship Types
-- Item: spUpdateRelationshipType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR RelationshipType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateRelationshipType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateRelationshipType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Relationship Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationship Types
-- Item: spDeleteRelationshipType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR RelationshipType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteRelationshipType" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Relationship Types */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteRelationshipType" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
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
/* SQL text to delete unneeded entity fields */


-- ===================== Other =====================

-- =====================================================================
-- v5.33 Tolerant SP Regeneration + Enable CascadeDeletes for Organizations
-- =====================================================================
--
-- Purpose:
--   1. Flip [CascadeDeletes" = 1 on the "MJ_BizApps_Common: Organizations"
--      entity in "__mj"."Entity" so CodeGen emits cascade cleanup logic
--      in spDeleteOrganization.
--   2. Install regenerated tolerant CRUD stored procedures for every
--      BAC entity (introduced in MJ v5.31+). These accept NULL for any
--      non-primary-key parameter and apply database defaults via
--      COALESCE(...) in the body, so historical EXEC calls remain valid
--      after additive schema changes. Nullable columns with database
--      defaults get an accompanying `<Field>_Clear bit = 0` companion
--      parameter that lets callers explicitly set the column to NULL.
--
-- Per-FK cascade direction is determined automatically by MJ CodeGen:
--   - Non-nullable FKs to Organization -> cascade DELETE child rows
--   - Nullable FKs to Organization     -> cascade UPDATE child rows
--                                         setting FK to NULL (via
--                                         tolerant SP `_Clear` param)
--
-- This migration mirrors the pattern established in BCSaaS's
-- V202605131038__v1.2.x_Enable_CascadeDeletes_For_Organizations.sql:
-- STEP 1 is a hand-authored flag flip with a strict @@ROWCOUNT guard;
-- STEP 2 is the appended output of a forceRegeneration CodeGen run.
--
-- =====================================================================


-- =====================================================================
-- STEP 1: Flip the metadata flag on Organizations
-- =====================================================================

-- NOTE: unrecognized batch type (UNKNOWN) — passed through as-is
-- IF @@ROWCOUNT <> 1
-- BEGIN
--     DECLARE @err VARCHAR(400) = CONCAT(
--         N'Expected exactly 1 row updated for "MJ_BizApps_Common: Organizations" in "__mj"."Entity"; got ',
--         CAST(@@ROWCOUNT AS VARCHAR(10)),
--         N'. Aborting migration.'
--     );
--     THROW 50000, @err, 1;
-- END;

-- =====================================================================
-- STEP 2: Regenerated tolerant CRUD stored procedures (CodeGen output)
-- =====================================================================
--
-- Generated by running `mj codegen` with mj.config.cjs flags:
--
--     forceRegeneration: {
--         enabled: true,
--         spCreate: true,
--         spUpdate: true,
--         spDelete: true,
--         allStoredProcedures: false,
--         baseViews: false,
--         indexes: false,
--         fullTextSearch: false,
--     }
--
-- against a BAC DB where STEP 1 (CascadeDeletes = 1 on
-- MJ_BizApps_Common: Organizations) was previously applied. The
-- regenerated spDeleteOrganization body therefore contains cascade
-- cursors for every dependent FK; the other 29 sprocs (spCreate,
-- spUpdate, and the remaining 9 spDeletes) are the v5.33 tolerant
-- signatures.
--
-- =====================================================================

/* SQL text to update existing entities from schema */

/* spUpdate Permissions for MJ_BizApps_Common: Address Types */

/* spUpdate Permissions for MJ_BizApps_Common: Address Links */

/* spUpdate Permissions for MJ_BizApps_Common: Contact Methods */

/* spUpdate Permissions for MJ_BizApps_Common: Addresses */

/* spUpdate Permissions for MJ_BizApps_Common: Contact Types */

/* spUpdate Permissions for MJ_BizApps_Common: Organizations */

/* spUpdate Permissions for MJ_BizApps_Common: Relationships */

/* spUpdate Permissions for MJ_BizApps_Common: People */

/* spUpdate Permissions for MJ_BizApps_Common: Organization Types */

/* spUpdate Permissions for MJ_BizApps_Common: Relationship Types */
