-- =====================================================================
-- v6.1 People & Organizations: overlapping subtypes + soft delete + record merge
-- (PostgreSQL — converted counterpart of the T-SQL migration of the same name)
-- =====================================================================
--
-- Enables downstream apps (BizApps Sales, AIDP-next CDP, etc.) to attach
-- MULTIPLE IsA subtypes to the same Person / Organization record, and turns
-- both parent entities into soft-delete + record-merge entities:
--
--   1. AllowMultipleSubtypes = TRUE  -- relax MJ's disjoint-subtype default so a
--                                       single Person/Organization can parent more
--                                       than one IsA child (SalesContact AND
--                                       crm.Contact on the same Person).
--   2. AllowRecordMerge      = TRUE  -- allow MJ's record-merge feature on both.
--   3. DeleteType            = Soft  -- deletes stamp __mj_DeletedAt instead of
--                                       physically removing the row.
--
-- The regenerated spDelete functions and base views below match MJ CodeGen output
-- for DeleteType=Soft entities. Base views use CREATE OR REPLACE (appending the new
-- column at the end) so the spCreate/spUpdate functions that RETURN SETOF these
-- views are not cascade-dropped.
--
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. DDL: add the reserved soft-delete column (nullable, no default).
-- ---------------------------------------------------------------------

/* SQL text to add special date field __mj_DeletedAt to entity __mj_bizappscommon."Person" */
ALTER TABLE __mj_bizappscommon."Person"
    ADD COLUMN IF NOT EXISTS "__mj_DeletedAt" TIMESTAMPTZ;

/* SQL text to add special date field __mj_DeletedAt to entity __mj_bizappscommon."Organization" */
ALTER TABLE __mj_bizappscommon."Organization"
    ADD COLUMN IF NOT EXISTS "__mj_DeletedAt" TIMESTAMPTZ;


-- ---------------------------------------------------------------------
-- 2. Metadata: register the __mj_DeletedAt EntityField for both entities.
-- ---------------------------------------------------------------------

/* SQL text to insert new entity field __mj_DeletedAt for MJ_BizApps_Common: People */
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM "__mj"."EntityField"
        WHERE "ID" = 'f7c1d7ad-0309-4c7f-9f3f-dbe771bf9ed0'
           OR ("EntityID" = '7a94ada9-7880-4fae-97d8-db0e934c3f5f' AND "Name" = '__mj_DeletedAt')
    ) THEN
        INSERT INTO "__mj"."EntityField"
        (
            "ID", "EntityID", "Sequence", "Name", "DisplayName", "Description", "Type", "Length", "Precision", "Scale",
            "AllowsNull", "DefaultValue", "AutoIncrement", "AllowUpdateAPI", "IsVirtual", "RelatedEntityID",
            "RelatedEntityFieldName", "IsNameField", "IncludeInUserSearchAPI", "IncludeRelatedEntityNameFieldInBaseView",
            "DefaultInView", "IsPrimaryKey", "IsUnique", "RelatedEntityDisplayType"
        )
        VALUES
        (
            'f7c1d7ad-0309-4c7f-9f3f-dbe771bf9ed0',
            '7a94ada9-7880-4fae-97d8-db0e934c3f5f', -- Entity: MJ_BizApps_Common: People
            (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM "__mj"."EntityField" WHERE "EntityID" = '7a94ada9-7880-4fae-97d8-db0e934c3f5f'),
            '__mj_DeletedAt',
            'Deleted At',
            NULL,
            'TIMESTAMPTZ',
            10,
            34,
            7,
            TRUE,   -- AllowsNull
            NULL,   -- DefaultValue
            FALSE,  -- AutoIncrement
            FALSE,  -- AllowUpdateAPI
            FALSE,  -- IsVirtual
            NULL,
            NULL,
            FALSE,
            FALSE,
            FALSE,
            FALSE,
            FALSE,
            FALSE,
            'Search'
        );
    END IF;
END $$;

/* SQL text to insert new entity field __mj_DeletedAt for MJ_BizApps_Common: Organizations */
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM "__mj"."EntityField"
        WHERE "ID" = 'd6637a22-acf9-4fb3-8537-6b4a9cd12d69'
           OR ("EntityID" = 'c70448f9-9792-41d7-a82c-784b66429d54' AND "Name" = '__mj_DeletedAt')
    ) THEN
        INSERT INTO "__mj"."EntityField"
        (
            "ID", "EntityID", "Sequence", "Name", "DisplayName", "Description", "Type", "Length", "Precision", "Scale",
            "AllowsNull", "DefaultValue", "AutoIncrement", "AllowUpdateAPI", "IsVirtual", "RelatedEntityID",
            "RelatedEntityFieldName", "IsNameField", "IncludeInUserSearchAPI", "IncludeRelatedEntityNameFieldInBaseView",
            "DefaultInView", "IsPrimaryKey", "IsUnique", "RelatedEntityDisplayType"
        )
        VALUES
        (
            'd6637a22-acf9-4fb3-8537-6b4a9cd12d69',
            'c70448f9-9792-41d7-a82c-784b66429d54', -- Entity: MJ_BizApps_Common: Organizations
            (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM "__mj"."EntityField" WHERE "EntityID" = 'c70448f9-9792-41d7-a82c-784b66429d54'),
            '__mj_DeletedAt',
            'Deleted At',
            NULL,
            'TIMESTAMPTZ',
            10,
            34,
            7,
            TRUE,   -- AllowsNull
            NULL,   -- DefaultValue
            FALSE,  -- AutoIncrement
            FALSE,  -- AllowUpdateAPI
            FALSE,  -- IsVirtual
            NULL,
            NULL,
            FALSE,
            FALSE,
            FALSE,
            FALSE,
            FALSE,
            FALSE,
            'Search'
        );
    END IF;
END $$;


-- ---------------------------------------------------------------------
-- 3. Metadata: flip the entity-level flags on both parents.
-- ---------------------------------------------------------------------

/* SQL text to enable overlapping subtypes, record merge, and soft delete on People & Organizations */
UPDATE "__mj"."Entity"
SET
    "AllowMultipleSubtypes" = TRUE,
    "AllowRecordMerge"      = TRUE,
    "DeleteType"            = 'Soft'
WHERE "ID" IN (
    '7a94ada9-7880-4fae-97d8-db0e934c3f5f', -- MJ_BizApps_Common: People
    'c70448f9-9792-41d7-a82c-784b66429d54'  -- MJ_BizApps_Common: Organizations
);


-- ---------------------------------------------------------------------
-- 4. Regenerate spDelete functions as soft deletes.
-- ---------------------------------------------------------------------

-- spDeletePerson: soft delete (UPDATE __mj_DeletedAt) as emitted by MJ CodeGen for DeleteType=Soft
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spDeletePerson"(p_id uuid)
 RETURNS TABLE("ID" uuid)
 LANGUAGE plpgsql
AS $function$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
BEGIN

    UPDATE __mj_bizappscommon."Person"
    SET "__mj_DeletedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "ID" = p_id
        AND "__mj_DeletedAt" IS NULL;

    GET DIAGNOSTICS v_affected_count = ROW_COUNT;

    IF v_affected_count = 0 THEN
        RETURN QUERY SELECT NULL::UUID AS "ID";
    ELSE
        RETURN QUERY SELECT p_id AS "ID";
    END IF;
END;
$function$;

-- spDeleteOrganization: soft delete (UPDATE __mj_DeletedAt) as emitted by MJ CodeGen for DeleteType=Soft
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spDeleteOrganization"(p_id uuid)
 RETURNS TABLE("ID" uuid)
 LANGUAGE plpgsql
AS $function$
#variable_conflict use_column
DECLARE
    v_affected_count INTEGER;
BEGIN

    UPDATE __mj_bizappscommon."Organization"
    SET "__mj_DeletedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "ID" = p_id
        AND "__mj_DeletedAt" IS NULL;

    GET DIAGNOSTICS v_affected_count = ROW_COUNT;

    IF v_affected_count = 0 THEN
        RETURN QUERY SELECT NULL::UUID AS "ID";
    ELSE
        RETURN QUERY SELECT p_id AS "ID";
    END IF;
END;
$function$;


-- ---------------------------------------------------------------------
-- 5. Regenerate base views to exclude soft-deleted rows. The new column
--    is appended at the end so CREATE OR REPLACE succeeds without dropping
--    the spCreate/spUpdate functions that RETURN SETOF these views.
-- ---------------------------------------------------------------------

CREATE OR REPLACE VIEW __mj_bizappscommon."vwPeople"
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
    mjuser_linkeduserid."Name" AS "LinkedUser",
    p."__mj_DeletedAt"
   FROM __mj_bizappscommon."Person" p
     LEFT JOIN "__mj"."User" mjuser_linkeduserid ON p."LinkedUserID" = mjuser_linkeduserid."ID"
  WHERE p."__mj_DeletedAt" IS NULL;

CREATE OR REPLACE VIEW __mj_bizappscommon."vwOrganizations"
AS SELECT o."ID",
    o."Name",
    o."LegalName",
    o."OrganizationTypeID",
    o."ParentID",
    o."Website",
    o."LogoURL",
    o."Description",
    o."Email",
    o."Phone",
    o."FoundedDate",
    o."TaxID",
    o."Status",
    o."__mj_CreatedAt",
    o."__mj_UpdatedAt",
    mjbizappscommonorganizationtype_organizationtypeid."Name" AS "OrganizationType",
    mjbizappscommonorganization_parentid."Name" AS "Parent",
    root_parentid.root_id AS "RootParentID",
    o."__mj_DeletedAt"
   FROM __mj_bizappscommon."Organization" o
     LEFT JOIN __mj_bizappscommon."OrganizationType" mjbizappscommonorganizationtype_organizationtypeid ON o."OrganizationTypeID" = mjbizappscommonorganizationtype_organizationtypeid."ID"
     LEFT JOIN __mj_bizappscommon."Organization" mjbizappscommonorganization_parentid ON o."ParentID" = mjbizappscommonorganization_parentid."ID"
     LEFT JOIN LATERAL ( SELECT __mj_bizappscommon.fn_organization_parent_id_get_root_id(o."ID", o."ParentID") AS root_id) root_parentid ON true
  WHERE o."__mj_DeletedAt" IS NULL;
