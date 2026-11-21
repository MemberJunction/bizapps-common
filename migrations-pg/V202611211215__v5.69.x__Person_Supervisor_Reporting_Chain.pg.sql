-- =============================================================================
-- PostgreSQL counterpart of V202611211215__v5.69.x__Person_Supervisor_Reporting_Chain.sql
-- =============================================================================
-- Adds Person.SupervisorPersonID (nullable self-referential FK to Person.ID
-- with index), creates cycle-safe recursive view vwPersonReportingChain
-- ("PersonID", "SupervisorPersonID", "Depth"), defines PL/pgSQL stored
-- procedure __mj_bizappscommon."SyncEmployeesToPeople"() for atomic sync of
-- SupervisorPersonID and dated 'Reports To' Relationship rows, updates
-- vwPeopleGenerated / EntityField metadata, and applies People FLS permissions.
-- =============================================================================

SET standard_conforming_strings = on;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA IF NOT EXISTS __mj_bizappscommon;
SET search_path TO __mj_bizappscommon, public;

-- =============================================================================
-- DDL: Person.SupervisorPersonID column, FK, index, and column comment
-- =============================================================================
ALTER TABLE __mj_bizappscommon."Person"
    ADD COLUMN "SupervisorPersonID" UUID NULL;

ALTER TABLE __mj_bizappscommon."Person"
    ADD CONSTRAINT "FK_Person_SupervisorPerson"
        FOREIGN KEY ("SupervisorPersonID") REFERENCES __mj_bizappscommon."Person"("ID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Person_SupervisorPersonID"
    ON __mj_bizappscommon."Person" ("SupervisorPersonID");

COMMENT ON COLUMN __mj_bizappscommon."Person"."SupervisorPersonID"
    IS 'Optional self-referential foreign key to the Person record who directly supervises this person.';

-- =============================================================================
-- Recursive reporting chain view: ("PersonID", "SupervisorPersonID", "Depth")
-- Depth = 1 is direct supervisor, Depth = 2 is skip-level supervisor, etc.
-- VisitedPath array + Depth < 100 prevent infinite recursion on cyclic data.
-- =============================================================================
CREATE OR REPLACE VIEW __mj_bizappscommon."vwPersonReportingChain"
AS
WITH RECURSIVE "ReportingChain" ("PersonID", "SupervisorPersonID", "Depth", "VisitedPath") AS (
    SELECT
        p."ID" AS "PersonID",
        p."SupervisorPersonID" AS "SupervisorPersonID",
        1 AS "Depth",
        ARRAY[p."ID", p."SupervisorPersonID"] AS "VisitedPath"
    FROM
        __mj_bizappscommon."Person" AS p
    WHERE
        p."SupervisorPersonID" IS NOT NULL
        AND p."SupervisorPersonID" <> p."ID"

    UNION ALL

    SELECT
        rc."PersonID" AS "PersonID",
        sup."SupervisorPersonID" AS "SupervisorPersonID",
        rc."Depth" + 1 AS "Depth",
        rc."VisitedPath" || sup."SupervisorPersonID" AS "VisitedPath"
    FROM
        "ReportingChain" AS rc
    INNER JOIN
        __mj_bizappscommon."Person" AS sup
        ON sup."ID" = rc."SupervisorPersonID"
    WHERE
        sup."SupervisorPersonID" IS NOT NULL
        AND NOT (sup."SupervisorPersonID" = ANY(rc."VisitedPath"))
        AND rc."Depth" < 100
)
SELECT
    "PersonID",
    "SupervisorPersonID",
    "Depth"
FROM
    "ReportingChain";

DO $$ BEGIN
    GRANT SELECT ON __mj_bizappscommon."vwPersonReportingChain" TO "cdp_UI", "cdp_Developer", "cdp_Integration";
EXCEPTION WHEN others THEN NULL;
END $$;

-- =============================================================================
-- SyncEmployeesToPeople
-- Atomically synchronizes __mj."Employee" records to __mj_bizappscommon."Person",
-- populates/updates "SupervisorPersonID" from "Employee"."SupervisorID", and
-- maintains dated 'Reports To' Relationship rows (closing outdated active rows
-- and inserting new active rows) inside the caller's or an implicit atomic transaction.
-- =============================================================================
CREATE OR REPLACE PROCEDURE __mj_bizappscommon."SyncEmployeesToPeople"()
LANGUAGE plpgsql
AS $$
DECLARE
    v_sync_date DATE := (NOW() AT TIME ZONE 'UTC')::date;
    v_reports_to_type_id UUID;
    v_people_entity_id UUID;
BEGIN
    SELECT e."ID"
    INTO v_people_entity_id
    FROM ${mjSchema}."Entity" AS e
    WHERE e."Name" = 'MJ_BizApps_Common: People'
    LIMIT 1;

    SELECT rt."ID"
    INTO v_reports_to_type_id
    FROM __mj_bizappscommon."RelationshipType" AS rt
    WHERE LOWER(BTRIM(rt."Name")) = 'reports to'
    LIMIT 1;

    IF v_reports_to_type_id IS NULL THEN
        v_reports_to_type_id := 'F1449971-6488-49E3-8F5B-823EB3E8CB11'::uuid;
        INSERT INTO __mj_bizappscommon."RelationshipType" (
            "ID",
            "Name",
            "Description",
            "Category",
            "IsDirectional",
            "ForwardLabel",
            "ReverseLabel",
            "IsActive"
        )
        VALUES (
            v_reports_to_type_id,
            'Reports To',
            'Direct reporting line between a person and their supervisor',
            'PersonToPerson',
            TRUE,
            'reports to',
            'supervises',
            TRUE
        );
    END IF;

    CREATE TEMP TABLE "_tmp_emp_person_map" (
        "EmployeeID" UUID PRIMARY KEY,
        "SupervisorEmployeeID" UUID NULL,
        "FirstName" VARCHAR(100) NOT NULL,
        "LastName" VARCHAR(100) NOT NULL,
        "Title" VARCHAR(200) NULL,
        "Email" VARCHAR(255) NULL,
        "Phone" VARCHAR(50) NULL,
        "Active" BOOLEAN NOT NULL,
        "PersonID" UUID NULL,
        "LinkedUserID" UUID NULL
    ) ON COMMIT DROP;

    INSERT INTO "_tmp_emp_person_map" (
        "EmployeeID",
        "SupervisorEmployeeID",
        "FirstName",
        "LastName",
        "Title",
        "Email",
        "Phone",
        "Active",
        "PersonID",
        "LinkedUserID"
    )
    SELECT
        emp."ID",
        emp."SupervisorID",
        emp."FirstName",
        emp."LastName",
        emp."Title",
        NULLIF(BTRIM(emp."Email"), ''),
        NULLIF(BTRIM(emp."Phone"), ''),
        emp."Active",
        COALESCE(user_linked_person."ID", user_direct_person."ID", email_person."ID"),
        matched_user."ID"
    FROM ${mjSchema}."Employee" AS emp
    LEFT JOIN LATERAL (
        SELECT
            u."ID",
            CASE
                WHEN u."LinkedEntityRecordID" ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
                    THEN u."LinkedEntityRecordID"::uuid
                ELSE NULL
            END AS "LinkedPersonID",
            u."LinkedEntityID"
        FROM ${mjSchema}."User" AS u
        WHERE u."EmployeeID" = emp."ID"
        ORDER BY u."IsActive" DESC, u."__mj_CreatedAt" ASC
        LIMIT 1
    ) AS matched_user ON TRUE
    LEFT JOIN LATERAL (
        SELECT p."ID"
        FROM __mj_bizappscommon."Person" AS p
        WHERE matched_user."LinkedPersonID" IS NOT NULL
          AND p."ID" = matched_user."LinkedPersonID"
          AND (
              v_people_entity_id IS NULL
              OR matched_user."LinkedEntityID" = v_people_entity_id
              OR EXISTS (
                  SELECT 1
                  FROM ${mjSchema}."Entity" AS sub_e
                  WHERE sub_e."ID" = matched_user."LinkedEntityID"
                    AND sub_e."ParentID" = v_people_entity_id
              )
          )
        LIMIT 1
    ) AS user_linked_person ON TRUE
    LEFT JOIN LATERAL (
        SELECT p."ID"
        FROM __mj_bizappscommon."Person" AS p
        WHERE matched_user."ID" IS NOT NULL
          AND p."LinkedUserID" = matched_user."ID"
        LIMIT 1
    ) AS user_direct_person ON TRUE
    LEFT JOIN LATERAL (
        SELECT p."ID"
        FROM __mj_bizappscommon."Person" AS p
        WHERE NULLIF(BTRIM(emp."Email"), '') IS NOT NULL
          AND LOWER(BTRIM(p."Email")) = LOWER(BTRIM(emp."Email"))
        ORDER BY
            CASE WHEN p."Status" = 'Active' THEN 0 ELSE 1 END,
            p."__mj_CreatedAt" ASC
        LIMIT 1
    ) AS email_person ON TRUE;

    -- Create Person records for active employees without a matched Person
    CREATE TEMP TABLE "_tmp_new_people" (
        "EmployeeID" UUID PRIMARY KEY,
        "PersonID" UUID NOT NULL
    ) ON COMMIT DROP;

    INSERT INTO "_tmp_new_people" ("EmployeeID", "PersonID")
    SELECT
        m."EmployeeID",
        gen_random_uuid()
    FROM "_tmp_emp_person_map" AS m
    WHERE m."PersonID" IS NULL
      AND m."Active" = TRUE;

    INSERT INTO __mj_bizappscommon."Person" (
        "ID",
        "FirstName",
        "LastName",
        "Title",
        "Email",
        "Phone",
        "LinkedUserID",
        "Status"
    )
    SELECT
        np."PersonID",
        m."FirstName",
        m."LastName",
        m."Title",
        m."Email",
        m."Phone",
        CASE
            WHEN m."LinkedUserID" IS NOT NULL
                 AND NOT EXISTS (
                     SELECT 1
                     FROM __mj_bizappscommon."Person" AS existing_by_user
                     WHERE existing_by_user."LinkedUserID" = m."LinkedUserID"
                 )
            THEN m."LinkedUserID"
            ELSE NULL
        END,
        'Active'
    FROM "_tmp_emp_person_map" AS m
    INNER JOIN "_tmp_new_people" AS np
        ON np."EmployeeID" = m."EmployeeID";

    UPDATE "_tmp_emp_person_map" AS m
    SET "PersonID" = np."PersonID"
    FROM "_tmp_new_people" AS np
    WHERE np."EmployeeID" = m."EmployeeID";

    -- Deduplicate by PersonID and resolve each Person's TargetSupervisorPersonID
    CREATE TEMP TABLE "_tmp_person_supervisor_sync" (
        "PersonID" UUID PRIMARY KEY,
        "TargetSupervisorPersonID" UUID NULL
    ) ON COMMIT DROP;

    INSERT INTO "_tmp_person_supervisor_sync" ("PersonID", "TargetSupervisorPersonID")
    SELECT
        ranked."PersonID",
        ranked."TargetSupervisorPersonID"
    FROM (
        SELECT
            m."PersonID",
            CASE
                WHEN sup."PersonID" IS NOT NULL AND sup."PersonID" <> m."PersonID"
                    THEN sup."PersonID"
                ELSE NULL
            END AS "TargetSupervisorPersonID",
            ROW_NUMBER() OVER (
                PARTITION BY m."PersonID"
                ORDER BY m."Active" DESC, m."EmployeeID" ASC
            ) AS "RowNum"
        FROM "_tmp_emp_person_map" AS m
        LEFT JOIN "_tmp_emp_person_map" AS sup
            ON sup."EmployeeID" = m."SupervisorEmployeeID"
        WHERE m."PersonID" IS NOT NULL
    ) AS ranked
    WHERE ranked."RowNum" = 1;

    -- Update Person.SupervisorPersonID wherever it differs
    UPDATE __mj_bizappscommon."Person" AS p
    SET "SupervisorPersonID" = s."TargetSupervisorPersonID"
    FROM "_tmp_person_supervisor_sync" AS s
    WHERE p."ID" = s."PersonID"
      AND p."SupervisorPersonID" IS DISTINCT FROM s."TargetSupervisorPersonID";

    -- Close out outdated active 'Reports To' relationships
    UPDATE __mj_bizappscommon."Relationship" AS r
    SET "Status" = 'Ended',
        "EndDate" = COALESCE(r."EndDate", v_sync_date)
    FROM "_tmp_person_supervisor_sync" AS s
    WHERE r."FromPersonID" = s."PersonID"
      AND r."RelationshipTypeID" = v_reports_to_type_id
      AND r."Status" = 'Active'
      AND (
          s."TargetSupervisorPersonID" IS NULL
          OR r."ToPersonID" IS NULL
          OR r."ToPersonID" <> s."TargetSupervisorPersonID"
      );

    -- Insert new active 'Reports To' relationships when missing
    INSERT INTO __mj_bizappscommon."Relationship" (
        "ID",
        "RelationshipTypeID",
        "FromPersonID",
        "FromOrganizationID",
        "ToPersonID",
        "ToOrganizationID",
        "StartDate",
        "EndDate",
        "Status",
        "Notes"
    )
    SELECT
        gen_random_uuid(),
        v_reports_to_type_id,
        s."PersonID",
        NULL,
        s."TargetSupervisorPersonID",
        NULL,
        v_sync_date,
        NULL,
        'Active',
        'Synced from MJ: Employees supervisor hierarchy'
    FROM "_tmp_person_supervisor_sync" AS s
    WHERE s."TargetSupervisorPersonID" IS NOT NULL
      AND NOT EXISTS (
          SELECT 1
          FROM __mj_bizappscommon."Relationship" AS r
          WHERE r."RelationshipTypeID" = v_reports_to_type_id
            AND r."FromPersonID" = s."PersonID"
            AND r."ToPersonID" = s."TargetSupervisorPersonID"
            AND r."Status" = 'Active'
      );
END;
$$;

DO $$ BEGIN
    GRANT EXECUTE ON PROCEDURE __mj_bizappscommon."SyncEmployeesToPeople"() TO "cdp_Developer", "cdp_Integration";
EXCEPTION WHEN others THEN NULL;
END $$;






















































-- =============================================================================
-- Metadata & Base View Parity (CodeGen-aligned PostgreSQL counterpart)
-- =============================================================================

INSERT INTO ${mjSchema}."EntityField" (
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
    "Category",
    "GeneratedFormSection",
    "__mj_CreatedAt",
    "__mj_UpdatedAt"
)
SELECT
    'd327403d-481d-4c07-9d8d-0c6628578b61'::uuid,
    '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'::uuid,
    (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM ${mjSchema}."EntityField" WHERE "EntityID" = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'::uuid),
    'SupervisorPersonID',
    'Supervisor',
    'Optional self-referential foreign key to the Person record who directly supervises this person.',
    'uniqueidentifier',
    16,
    0,
    0,
    TRUE,
    NULL,
    FALSE,
    TRUE,
    FALSE,
    FALSE,
    '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'::uuid,
    'ID',
    FALSE,
    FALSE,
    TRUE,
    FALSE,
    FALSE,
    FALSE,
    'Search',
    'Professional and Profile',
    'Category',
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM ${mjSchema}."EntityField"
    WHERE "ID" = 'd327403d-481d-4c07-9d8d-0c6628578b61'::uuid
       OR ("EntityID" = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'::uuid AND "Name" = 'SupervisorPersonID')
);

INSERT INTO ${mjSchema}."EntityField" (
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
    "Category",
    "GeneratedFormSection",
    "__mj_CreatedAt",
    "__mj_UpdatedAt"
)
SELECT
    '915fd715-b7e6-429a-928f-2421706467f5'::uuid,
    '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'::uuid,
    (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM ${mjSchema}."EntityField" WHERE "EntityID" = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'::uuid),
    'SupervisorPerson',
    'Supervisor Name',
    NULL,
    'nvarchar',
    250,
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
    'Professional and Profile',
    'Category',
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM ${mjSchema}."EntityField"
    WHERE "ID" = '915fd715-b7e6-429a-928f-2421706467f5'::uuid
       OR ("EntityID" = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'::uuid AND "Name" = 'SupervisorPerson')
);

UPDATE ${mjSchema}."EntityField"
SET "RelatedEntityNameFieldMap" = 'SupervisorPerson'
WHERE "ID" = 'd327403d-481d-4c07-9d8d-0c6628578b61'::uuid;

INSERT INTO ${mjSchema}."EntityRelationship" (
    "ID",
    "EntityID",
    "RelatedEntityID",
    "RelatedEntityJoinField",
    "Type",
    "BundleInAPI",
    "DisplayInForm",
    "Sequence",
    "__mj_CreatedAt",
    "__mj_UpdatedAt"
)
SELECT
    '7e1cc753-8dc8-4583-98cc-d464615ef304'::uuid,
    '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'::uuid,
    '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'::uuid,
    'SupervisorPersonID',
    'One To Many',
    TRUE,
    TRUE,
    (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM ${mjSchema}."EntityRelationship" WHERE "EntityID" = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'::uuid),
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM ${mjSchema}."EntityRelationship"
    WHERE "ID" = '7e1cc753-8dc8-4583-98cc-d464615ef304'::uuid
       OR ("EntityID" = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'::uuid
           AND "RelatedEntityID" = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'::uuid
           AND "RelatedEntityJoinField" = 'SupervisorPersonID')
);

-- Rebuild vwPeopleGenerated cleanly and restore any dependent views (vwPeople)
DO $do$
DECLARE
    v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
    v_target_name CONSTANT TEXT := 'vwPeopleGenerated';
    vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_bizappscommon."vwPeopleGenerated"
AS SELECT
    p.*,
    "MJUser_LinkedUserID"."Name" AS "LinkedUser",
    "mjBizAppsCommonSeniorityLevel_SeniorityLevelID"."Name" AS "SeniorityLevel",
    "mjBizAppsCommonPerson_SupervisorPersonID"."DisplayName" AS "SupervisorPerson"
FROM
    __mj_bizappscommon."Person" AS p
LEFT OUTER JOIN
    ${mjSchema}."User" AS "MJUser_LinkedUserID"
  ON
    p."LinkedUserID" = "MJUser_LinkedUserID"."ID"
LEFT OUTER JOIN
    __mj_bizappscommon."SeniorityLevel" AS "mjBizAppsCommonSeniorityLevel_SeniorityLevelID"
  ON
    p."SeniorityLevelID" = "mjBizAppsCommonSeniorityLevel_SeniorityLevelID"."ID"
LEFT OUTER JOIN
    __mj_bizappscommon."Person" AS "mjBizAppsCommonPerson_SupervisorPersonID"
  ON
    p."SupervisorPersonID" = "mjBizAppsCommonPerson_SupervisorPersonID"."ID"$vsql$;
    v_target_oid OID;
    v_dep RECORD;
    v_captured JSONB[] := ARRAY[]::JSONB[];
    v_n INTEGER;
BEGIN
    EXECUTE vsql;
EXCEPTION WHEN invalid_table_definition THEN
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
                'schema', v_dep.schema, 'name', v_dep.name, 'def', v_dep.viewdef
            );
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
                RAISE WARNING 'Could not recreate dependent view %.%: %',
                    v_captured[v_n]->>'schema', v_captured[v_n]->>'name', SQLERRM;
            END;
        END LOOP;
    END IF;
END $do$;

-- ---- People field permissions: MJ snapshot rule on this host's permissions ----
WITH "RoleVerbs" AS (
    SELECT ep."RoleID",
           MAX(CASE WHEN COALESCE(LTRIM(RTRIM(ep."Type")), 'Allow') <> 'Deny' AND ep."CanRead" = TRUE THEN 1 ELSE 0 END) AS "AllowRead",
           MAX(CASE WHEN COALESCE(LTRIM(RTRIM(ep."Type")), 'Allow') <> 'Deny' AND ep."CanUpdate" = TRUE THEN 1 ELSE 0 END) AS "AllowUpdate",
           MAX(CASE WHEN COALESCE(LTRIM(RTRIM(ep."Type")), 'Allow') <> 'Deny' AND ep."CanCreate" = TRUE THEN 1 ELSE 0 END) AS "AllowCreate",
           MAX(CASE WHEN COALESCE(LTRIM(RTRIM(ep."Type")), 'Allow') =  'Deny' AND ep."CanRead" = TRUE THEN 1 ELSE 0 END) AS "DenyRead",
           MAX(CASE WHEN COALESCE(LTRIM(RTRIM(ep."Type")), 'Allow') =  'Deny' AND ep."CanUpdate" = TRUE THEN 1 ELSE 0 END) AS "DenyUpdate",
           MAX(CASE WHEN COALESCE(LTRIM(RTRIM(ep."Type")), 'Allow') =  'Deny' AND ep."CanCreate" = TRUE THEN 1 ELSE 0 END) AS "DenyCreate"
    FROM ${mjSchema}."EntityPermission" ep
    WHERE ep."EntityID" = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'
    GROUP BY ep."RoleID"
),
"RoleAccess" AS (
    SELECT "RoleID",
           CASE WHEN "AllowUpdate" = 1 AND "DenyUpdate" = 0 THEN 1 ELSE 0 END AS "RoleCanUpdate",
           CASE WHEN "AllowCreate" = 1 AND "DenyCreate" = 0 THEN 1 ELSE 0 END AS "RoleCanCreate"
    FROM "RoleVerbs"
    WHERE "AllowRead" = 1 AND "DenyRead" = 0
)
INSERT INTO ${mjSchema}."EntityFieldPermission" ("EntityFieldID", "RoleID", "ReadAccess", "UpdateAccess", "CreateAccess")
SELECT ef."ID",
       ra."RoleID",
       'Allow',
       CASE WHEN ef."AllowUpdateAPI" = TRUE AND ra."RoleCanUpdate" = 1 THEN 'Allow' ELSE 'No Access' END,
       CASE WHEN ef."AllowUpdateAPI" = TRUE AND ra."RoleCanCreate" = 1 THEN 'Allow' ELSE 'No Access' END
FROM ${mjSchema}."EntityField" ef
CROSS JOIN "RoleAccess" ra
WHERE ef."EntityID" = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'
  AND ef."IsPrimaryKey" = FALSE
  AND ef."IsSoftPrimaryKey" = FALSE
  AND LEFT(ef."Name", 5) <> '__mj_'
  AND NOT EXISTS (
      SELECT 1 FROM ${mjSchema}."EntityFieldPermission" x
      WHERE x."EntityFieldID" = ef."ID" AND x."RoleID" = ra."RoleID"
  );
