-- ============================================================================
-- MemberJunction PostgreSQL Migration
-- Converted from SQL Server counterpart of the same version
-- ============================================================================
--
-- v5.33.x — Decouple Person from MJ User
-- Context: https://github.com/MemberJunction/bizapps-common/issues/36
--
-- bizapps-common is a generic CRM layer: a Person is a record of a human
-- being, with no implication of platform access. The LinkedUserID column (and
-- the PersonEntityServer auto-provisioning hooks removed in this release)
-- coupled every emailed Person to an active MJ User with the 'UI' role —
-- wrong for job applicants, CRM contacts, and message senders.
--
-- This migration:
--   1. Marks the Person.LinkedUserID EntityField as Status='Deprecated'
--      (runtime emits console warnings on Get/Set; generated classes gain
--      @deprecated JSDoc; views/SPs/GraphQL remain functional).
--   2. Rewrites the column comment with a DEPRECATED: prefix. NOTE: with
--      AutoUpdateDescription=1, EntityField Description re-syncs from the
--      column comment every migrate cycle, so the deprecation text MUST
--      live on the column itself (PG equivalent of the SQL Server
--      MS_Description extended property).
--   3. Sets AllowMultipleSubtypes=TRUE on the People AND Organizations
--      entities, declaring both as overlapping IS-A parents: a
--      Person/Organization may be several subtypes at once (e.g., a platform
--      user AND an applicant; a SalesAccount AND a CRM Account), parent-side
--      saves never delegate to a subtype, and multiple products may layer
--      their own subtype entities on either parent.
--
-- The column and UQ_Person_LinkedUserID index remain physically in place for
-- backward compatibility. Data disposition is owned by the platform layer:
-- BCSaaS v1.8.0's migration moves LinkedUserID values into its
-- __BCSaaS.Person IS-A subtype (shared PK with Person), repoints User
-- back-pointers, and nulls this column. This migration moves NO data — it
-- always runs before the platform layer's.
-- ============================================================================

SET search_path TO __mj_bizappscommon, public;
SET standard_conforming_strings = on;

DO $$
DECLARE
    v_people_entity_id  UUID := '7a94ada9-7880-4fae-97d8-db0e934c3f5f';
    v_orgs_entity_id    UUID := 'c70448f9-9792-41d7-a82c-784b66429d54';
    v_deprecation_text  TEXT := 'DEPRECATED: Do not use. bizapps-common no longer reads or writes this column; person-to-MJ-User bindings are owned by platform-layer IS-A subtypes of Person (e.g., BCSaaS ''BC: People''). Retained only for backward compatibility and scheduled for removal in the next major release.';
    v_rowcount          INTEGER;
BEGIN
    -- -------------------------------------------------------------------------
    -- 1. Mark the EntityField as Deprecated
    -- -------------------------------------------------------------------------
    UPDATE __mj."EntityField" ef
    SET "Status" = 'Deprecated',
        "Description" = v_deprecation_text
    WHERE ef."EntityID" = v_people_entity_id
      AND ef."Name" = 'LinkedUserID';

    GET DIAGNOSTICS v_rowcount = ROW_COUNT;
    IF v_rowcount = 0 THEN
        RAISE EXCEPTION 'Expected EntityField LinkedUserID on entity MJ_BizApps_Common: People (7a94ada9-7880-4fae-97d8-db0e934c3f5f) was not found. Aborting migration.';
    END IF;

    -- -------------------------------------------------------------------------
    -- 2. Rewrite the column comment (PG analogue of MS_Description; COMMENT ON
    --    is create-or-replace, so no existence branching is needed)
    -- -------------------------------------------------------------------------
    EXECUTE format(
        'COMMENT ON COLUMN __mj_bizappscommon."Person"."LinkedUserID" IS %L',
        v_deprecation_text
    );

    -- -------------------------------------------------------------------------
    -- 3. Declare People and Organizations as overlapping IS-A parents
    -- -------------------------------------------------------------------------
    UPDATE __mj."Entity"
    SET "AllowMultipleSubtypes" = TRUE
    WHERE "ID" IN (v_people_entity_id, v_orgs_entity_id)
      AND "AllowMultipleSubtypes" = FALSE;
END $$;
