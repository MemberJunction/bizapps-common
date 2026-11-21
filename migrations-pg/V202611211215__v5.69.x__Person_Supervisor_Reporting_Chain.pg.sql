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

-- Rebuild vwPeopleGenerated, vwPeople, dependent views, and spCreatePerson / spUpdatePerson cleanly.
-- Fails loudly if any dependent view or function cannot be recreated; never downgrades errors to warnings.
DO $do$
DECLARE
    v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
    v_gen_name CONSTANT TEXT := 'vwPeopleGenerated';
    v_has_seniority BOOLEAN;
    v_gen_sql TEXT;
    v_gen_oid OID;
    v_gen_acl TEXT;
    v_people_oid OID;
    v_people_acl TEXT;
    v_people_def TEXT;
    v_people_is_layered BOOLEAN := FALSE;
    v_dep RECORD;
    v_acl RECORD;
    v_views JSONB[] := ARRAY[]::JSONB[];
    v_fns JSONB[] := ARRAY[]::JSONB[];
    v_n INTEGER;
    v_rebuilt_people_sql TEXT;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_target_schema
          AND table_name = 'Person'
          AND column_name = 'SeniorityLevelID'
    ) INTO v_has_seniority;

    IF v_has_seniority THEN
        v_gen_sql := $vsql$CREATE OR REPLACE VIEW __mj_bizappscommon."vwPeopleGenerated"
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
    ELSE
        v_gen_sql := $vsql$CREATE OR REPLACE VIEW __mj_bizappscommon."vwPeopleGenerated"
AS SELECT
    p.*,
    "MJUser_LinkedUserID"."Name" AS "LinkedUser",
    "mjBizAppsCommonPerson_SupervisorPersonID"."DisplayName" AS "SupervisorPerson"
FROM
    __mj_bizappscommon."Person" AS p
LEFT OUTER JOIN
    ${mjSchema}."User" AS "MJUser_LinkedUserID"
  ON
    p."LinkedUserID" = "MJUser_LinkedUserID"."ID"
LEFT OUTER JOIN
    __mj_bizappscommon."Person" AS "mjBizAppsCommonPerson_SupervisorPersonID"
  ON
    p."SupervisorPersonID" = "mjBizAppsCommonPerson_SupervisorPersonID"."ID"$vsql$;
    END IF;

    SELECT c.oid, c.relacl::text INTO v_gen_oid, v_gen_acl
    FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = v_target_schema AND c.relname = v_gen_name AND c.relkind = 'v';

    SELECT c.oid, c.relacl::text INTO v_people_oid, v_people_acl
    FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = v_target_schema AND c.relname = 'vwPeople' AND c.relkind = 'v';

    IF v_people_oid IS NOT NULL THEN
        v_people_def := pg_catalog.pg_get_viewdef(v_people_oid, true);
        v_people_is_layered := v_people_def ILIKE '%vwPeopleGenerated%';
    END IF;

    -- Capture all views transitively depending on vwPeopleGenerated or vwPeople
    IF v_gen_oid IS NOT NULL OR v_people_oid IS NOT NULL THEN
        FOR v_dep IN
            WITH RECURSIVE deps AS (
                SELECT c.oid, 1 AS depth
                FROM pg_depend d
                JOIN pg_rewrite r ON r.oid = d.objid
                JOIN pg_class c ON c.oid = r.ev_class
                WHERE d.refobjid IN (v_gen_oid, v_people_oid)
                  AND d.deptype = 'n'
                  AND c.relkind = 'v'
                  AND c.oid NOT IN (COALESCE(v_gen_oid, 0), COALESCE(v_people_oid, 0))
                UNION
                SELECT c.oid, p.depth + 1
                FROM deps p
                JOIN pg_depend d ON d.refobjid = p.oid
                JOIN pg_rewrite r ON r.oid = d.objid
                JOIN pg_class c ON c.oid = r.ev_class
                WHERE c.relkind = 'v'
                  AND c.oid <> p.oid
            )
            SELECT c.oid, n.nspname AS schema, c.relname AS name, MAX(deps.depth) AS depth,
                   pg_catalog.pg_get_viewdef(c.oid, true) AS viewdef, c.relacl::text AS acl
            FROM deps
            JOIN pg_class c ON c.oid = deps.oid
            JOIN pg_namespace n ON n.oid = c.relnamespace
            GROUP BY c.oid, n.nspname, c.relname, c.relacl
            ORDER BY MAX(deps.depth) ASC
        LOOP
            v_views := v_views || jsonb_build_object(
                'oid', v_dep.oid,
                'schema', v_dep.schema,
                'name', v_dep.name,
                'def', v_dep.viewdef,
                'acl', v_dep.acl
            );
        END LOOP;

        -- Capture dependent functions referencing vwPeopleGenerated, vwPeople, or dependent views
        -- (spCreatePerson and spUpdatePerson are explicitly recreated below with SupervisorPersonID)
        FOR v_dep IN
            SELECT DISTINCT pr.oid, pg_catalog.pg_get_functiondef(pr.oid) AS def, pr.proacl::text AS acl,
                   pr.oid::regprocedure::text AS sig, pr.proname
            FROM pg_depend d
            JOIN pg_proc pr ON pr.oid = d.objid AND d.classid = 'pg_proc'::regclass
            JOIN pg_class c ON c.reltype = d.refobjid
            WHERE (c.oid = v_gen_oid OR c.oid = v_people_oid
                   OR c.oid IN (SELECT (x->>'oid')::oid FROM unnest(v_views) x))
              AND NOT (pr.pronamespace = v_target_schema::regnamespace
                       AND pr.proname IN ('spCreatePerson', 'spUpdatePerson'))
        LOOP
            v_fns := v_fns || jsonb_build_object('def', v_dep.def, 'acl', v_dep.acl, 'sig', v_dep.sig);
        END LOOP;
    END IF;

    -- Drop dependent functions (plus obsolete spCreatePerson/spUpdatePerson overloads) before views
    IF array_length(v_fns, 1) > 0 THEN
        FOR v_n IN 1..array_length(v_fns, 1) LOOP
            EXECUTE 'DROP FUNCTION ' || (v_fns[v_n]->>'sig');
        END LOOP;
    END IF;
    FOR v_dep IN
        SELECT oid::regprocedure::text AS sig
        FROM pg_proc
        WHERE pronamespace = v_target_schema::regnamespace
          AND proname IN ('spCreatePerson', 'spUpdatePerson')
    LOOP
        EXECUTE 'DROP FUNCTION ' || v_dep.sig;
    END LOOP;

    -- Drop dependent views deepest-first, then vwPeople, then vwPeopleGenerated (no CASCADE)
    IF array_length(v_views, 1) > 0 THEN
        FOR v_n IN REVERSE array_length(v_views, 1)..1 LOOP
            EXECUTE format('DROP VIEW IF EXISTS %I.%I', v_views[v_n]->>'schema', v_views[v_n]->>'name');
        END LOOP;
    END IF;
    IF v_people_oid IS NOT NULL THEN
        EXECUTE format('DROP VIEW IF EXISTS %I.%I', v_target_schema, 'vwPeople');
    END IF;
    IF v_gen_oid IS NOT NULL THEN
        EXECUTE format('DROP VIEW IF EXISTS %I.%I', v_target_schema, v_gen_name);
    END IF;

    -- Rebuild vwPeopleGenerated with SupervisorPersonID + SupervisorPerson
    EXECUTE v_gen_sql;
    BEGIN
        GRANT SELECT ON __mj_bizappscommon."vwPeopleGenerated" TO "cdp_UI", "cdp_Developer", "cdp_Integration";
    EXCEPTION WHEN undefined_object THEN NULL;
    END;
    IF v_gen_acl IS NOT NULL THEN
        FOR v_acl IN
            SELECT a.privilege_type,
                   CASE WHEN a.grantee = 0 THEN 'PUBLIC' ELSE quote_ident(pg_get_userbyid(a.grantee)) END AS grantee
            FROM aclexplode(v_gen_acl::aclitem[]) a
            WHERE a.grantee <> a.grantor
        LOOP
            EXECUTE format('GRANT %s ON %I.%I TO %s', v_acl.privilege_type, v_target_schema, v_gen_name, v_acl.grantee);
        END LOOP;
    END IF;

    -- Explicitly rebuild vwPeople over vwPeopleGenerated so SupervisorPersonID and SupervisorPerson are exposed
    IF v_people_is_layered AND v_people_def IS NOT NULL THEN
        IF v_people_def ILIKE '%"SupervisorPersonID"%' AND v_people_def ILIKE '%"SupervisorPerson"%' THEN
            v_rebuilt_people_sql := format('CREATE OR REPLACE VIEW %I.%I AS %s', v_target_schema, 'vwPeople', v_people_def);
        ELSE
            v_rebuilt_people_sql := format(
                'CREATE OR REPLACE VIEW %I.%I AS %s',
                v_target_schema,
                'vwPeople',
                regexp_replace(
                    v_people_def,
                    '(\s+FROM\s+__mj_bizappscommon\."vwPeopleGenerated")',
                    E',\n    g."SupervisorPersonID",\n    g."SupervisorPerson"\\1',
                    'i'
                )
            );
        END IF;
    ELSE
        v_rebuilt_people_sql := $vp$CREATE OR REPLACE VIEW __mj_bizappscommon."vwPeople"
AS SELECT
    g.*
FROM
    __mj_bizappscommon."vwPeopleGenerated" AS g$vp$;
    END IF;

    EXECUTE v_rebuilt_people_sql;
    BEGIN
        GRANT SELECT ON __mj_bizappscommon."vwPeople" TO "cdp_UI", "cdp_Developer", "cdp_Integration";
    EXCEPTION WHEN undefined_object THEN NULL;
    END;
    IF v_people_acl IS NOT NULL THEN
        FOR v_acl IN
            SELECT a.privilege_type,
                   CASE WHEN a.grantee = 0 THEN 'PUBLIC' ELSE quote_ident(pg_get_userbyid(a.grantee)) END AS grantee
            FROM aclexplode(v_people_acl::aclitem[]) a
            WHERE a.grantee <> a.grantor
        LOOP
            EXECUTE format('GRANT %s ON %I.%I TO %s', v_acl.privilege_type, v_target_schema, 'vwPeople', v_acl.grantee);
        END LOOP;
    END IF;

    -- Recreate all other dependent views and their grants (errors propagate, never downgraded to warnings)
    IF array_length(v_views, 1) > 0 THEN
        FOR v_n IN 1..array_length(v_views, 1) LOOP
            EXECUTE format('CREATE VIEW %I.%I AS %s',
                v_views[v_n]->>'schema', v_views[v_n]->>'name', v_views[v_n]->>'def');
            IF v_views[v_n]->>'acl' IS NOT NULL THEN
                FOR v_acl IN
                    SELECT a.privilege_type,
                           CASE WHEN a.grantee = 0 THEN 'PUBLIC' ELSE quote_ident(pg_get_userbyid(a.grantee)) END AS grantee
                    FROM aclexplode((v_views[v_n]->>'acl')::aclitem[]) a
                    WHERE a.grantee <> a.grantor
                LOOP
                    EXECUTE format('GRANT %s ON %I.%I TO %s',
                        v_acl.privilege_type, v_views[v_n]->>'schema', v_views[v_n]->>'name', v_acl.grantee);
                END LOOP;
            END IF;
        END LOOP;
    END IF;

    -- Recreate other dependent functions and their grants (errors propagate)
    IF array_length(v_fns, 1) > 0 THEN
        FOR v_n IN 1..array_length(v_fns, 1) LOOP
            EXECUTE v_fns[v_n]->>'def';
            IF v_fns[v_n]->>'acl' IS NOT NULL THEN
                FOR v_acl IN
                    SELECT a.privilege_type,
                           CASE WHEN a.grantee = 0 THEN 'PUBLIC' ELSE quote_ident(pg_get_userbyid(a.grantee)) END AS grantee
                    FROM aclexplode((v_fns[v_n]->>'acl')::aclitem[]) a
                    WHERE a.grantee <> a.grantor
                LOOP
                    EXECUTE format('GRANT %s ON FUNCTION %s TO %s',
                        v_acl.privilege_type, v_fns[v_n]->>'sig', v_acl.grantee);
                END LOOP;
            END IF;
        END LOOP;
    END IF;
END $do$;

-- =============================================================================
-- Native PostgreSQL CodeGen CRUD functions: spCreatePerson and spUpdatePerson
-- Drops any obsolete overloads and recreates both functions with SupervisorPersonID
-- (including _clear boolean semantics) and restores EXECUTE grants.
-- =============================================================================
DO $install_person_crud$
DECLARE
    v_has_seniority BOOLEAN;
    r RECORD;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = '__mj_bizappscommon'
          AND table_name = 'Person'
          AND column_name = 'SeniorityLevelID'
    ) INTO v_has_seniority;

    FOR r IN
        SELECT oid::regprocedure AS sig
        FROM pg_proc
        WHERE pronamespace = '__mj_bizappscommon'::regnamespace
          AND proname IN ('spCreatePerson', 'spUpdatePerson')
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig::text;
    END LOOP;

    IF v_has_seniority THEN
        EXECUTE $fn$
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spCreatePerson"(
    p_id uuid DEFAULT NULL::uuid,
    p_firstname character varying DEFAULT NULL::character varying,
    p_lastname character varying DEFAULT NULL::character varying,
    p_middlename_clear boolean DEFAULT false,
    p_middlename character varying DEFAULT NULL::character varying,
    p_prefix_clear boolean DEFAULT false,
    p_prefix character varying DEFAULT NULL::character varying,
    p_suffix_clear boolean DEFAULT false,
    p_suffix character varying DEFAULT NULL::character varying,
    p_preferredname_clear boolean DEFAULT false,
    p_preferredname character varying DEFAULT NULL::character varying,
    p_title_clear boolean DEFAULT false,
    p_title character varying DEFAULT NULL::character varying,
    p_email_clear boolean DEFAULT false,
    p_email character varying DEFAULT NULL::character varying,
    p_phone_clear boolean DEFAULT false,
    p_phone character varying DEFAULT NULL::character varying,
    p_dateofbirth_clear boolean DEFAULT false,
    p_dateofbirth date DEFAULT NULL::date,
    p_gender_clear boolean DEFAULT false,
    p_gender character varying DEFAULT NULL::character varying,
    p_photourl_clear boolean DEFAULT false,
    p_photourl character varying DEFAULT NULL::character varying,
    p_bio_clear boolean DEFAULT false,
    p_bio text DEFAULT NULL::text,
    p_linkeduserid_clear boolean DEFAULT false,
    p_linkeduserid uuid DEFAULT NULL::uuid,
    p_status character varying DEFAULT NULL::character varying,
    p_senioritylevelid_clear boolean DEFAULT false,
    p_senioritylevelid uuid DEFAULT NULL::uuid,
    p_supervisorpersonid_clear boolean DEFAULT false,
    p_supervisorpersonid uuid DEFAULT NULL::uuid
)
 RETURNS SETOF __mj_bizappscommon."vwPeople"
 LANGUAGE plpgsql
AS $function$
#variable_conflict use_column
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
            "Status",
            "SeniorityLevelID",
            "SupervisorPersonID"
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
            CASE WHEN p_senioritylevelid_clear = true THEN NULL ELSE COALESCE(p_senioritylevelid, NULL) END,
            CASE WHEN p_supervisorpersonid_clear = true THEN NULL ELSE COALESCE(p_supervisorpersonid, NULL) END
        );

    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwPeople"
    WHERE "ID" = v_new_id;
END;
$function$;
$fn$;

        EXECUTE $fn$
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spUpdatePerson"(
    p_id uuid,
    p_firstname character varying DEFAULT NULL::character varying,
    p_lastname character varying DEFAULT NULL::character varying,
    p_middlename_clear boolean DEFAULT false,
    p_middlename character varying DEFAULT NULL::character varying,
    p_prefix_clear boolean DEFAULT false,
    p_prefix character varying DEFAULT NULL::character varying,
    p_suffix_clear boolean DEFAULT false,
    p_suffix character varying DEFAULT NULL::character varying,
    p_preferredname_clear boolean DEFAULT false,
    p_preferredname character varying DEFAULT NULL::character varying,
    p_title_clear boolean DEFAULT false,
    p_title character varying DEFAULT NULL::character varying,
    p_email_clear boolean DEFAULT false,
    p_email character varying DEFAULT NULL::character varying,
    p_phone_clear boolean DEFAULT false,
    p_phone character varying DEFAULT NULL::character varying,
    p_dateofbirth_clear boolean DEFAULT false,
    p_dateofbirth date DEFAULT NULL::date,
    p_gender_clear boolean DEFAULT false,
    p_gender character varying DEFAULT NULL::character varying,
    p_photourl_clear boolean DEFAULT false,
    p_photourl character varying DEFAULT NULL::character varying,
    p_bio_clear boolean DEFAULT false,
    p_bio text DEFAULT NULL::text,
    p_linkeduserid_clear boolean DEFAULT false,
    p_linkeduserid uuid DEFAULT NULL::uuid,
    p_status character varying DEFAULT NULL::character varying,
    p_senioritylevelid_clear boolean DEFAULT false,
    p_senioritylevelid uuid DEFAULT NULL::uuid,
    p_supervisorpersonid_clear boolean DEFAULT false,
    p_supervisorpersonid uuid DEFAULT NULL::uuid
)
 RETURNS SETOF __mj_bizappscommon."vwPeople"
 LANGUAGE plpgsql
AS $function$
#variable_conflict use_column
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
        "Status" = COALESCE(p_status, "Status"),
        "SeniorityLevelID" = CASE WHEN p_senioritylevelid_clear = true THEN NULL ELSE COALESCE(p_senioritylevelid, "SeniorityLevelID") END,
        "SupervisorPersonID" = CASE WHEN p_supervisorpersonid_clear = true THEN NULL ELSE COALESCE(p_supervisorpersonid, "SupervisorPersonID") END,
        "__mj_UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwPeople"
    WHERE "ID" = p_id;
END;
$function$;
$fn$;
    ELSE
        EXECUTE $fn$
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spCreatePerson"(
    p_id uuid DEFAULT NULL::uuid,
    p_firstname character varying DEFAULT NULL::character varying,
    p_lastname character varying DEFAULT NULL::character varying,
    p_middlename_clear boolean DEFAULT false,
    p_middlename character varying DEFAULT NULL::character varying,
    p_prefix_clear boolean DEFAULT false,
    p_prefix character varying DEFAULT NULL::character varying,
    p_suffix_clear boolean DEFAULT false,
    p_suffix character varying DEFAULT NULL::character varying,
    p_preferredname_clear boolean DEFAULT false,
    p_preferredname character varying DEFAULT NULL::character varying,
    p_title_clear boolean DEFAULT false,
    p_title character varying DEFAULT NULL::character varying,
    p_email_clear boolean DEFAULT false,
    p_email character varying DEFAULT NULL::character varying,
    p_phone_clear boolean DEFAULT false,
    p_phone character varying DEFAULT NULL::character varying,
    p_dateofbirth_clear boolean DEFAULT false,
    p_dateofbirth date DEFAULT NULL::date,
    p_gender_clear boolean DEFAULT false,
    p_gender character varying DEFAULT NULL::character varying,
    p_photourl_clear boolean DEFAULT false,
    p_photourl character varying DEFAULT NULL::character varying,
    p_bio_clear boolean DEFAULT false,
    p_bio text DEFAULT NULL::text,
    p_linkeduserid_clear boolean DEFAULT false,
    p_linkeduserid uuid DEFAULT NULL::uuid,
    p_status character varying DEFAULT NULL::character varying,
    p_supervisorpersonid_clear boolean DEFAULT false,
    p_supervisorpersonid uuid DEFAULT NULL::uuid
)
 RETURNS SETOF __mj_bizappscommon."vwPeople"
 LANGUAGE plpgsql
AS $function$
#variable_conflict use_column
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
            "Status",
            "SupervisorPersonID"
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
            CASE WHEN p_supervisorpersonid_clear = true THEN NULL ELSE COALESCE(p_supervisorpersonid, NULL) END
        );

    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwPeople"
    WHERE "ID" = v_new_id;
END;
$function$;
$fn$;

        EXECUTE $fn$
CREATE OR REPLACE FUNCTION __mj_bizappscommon."spUpdatePerson"(
    p_id uuid,
    p_firstname character varying DEFAULT NULL::character varying,
    p_lastname character varying DEFAULT NULL::character varying,
    p_middlename_clear boolean DEFAULT false,
    p_middlename character varying DEFAULT NULL::character varying,
    p_prefix_clear boolean DEFAULT false,
    p_prefix character varying DEFAULT NULL::character varying,
    p_suffix_clear boolean DEFAULT false,
    p_suffix character varying DEFAULT NULL::character varying,
    p_preferredname_clear boolean DEFAULT false,
    p_preferredname character varying DEFAULT NULL::character varying,
    p_title_clear boolean DEFAULT false,
    p_title character varying DEFAULT NULL::character varying,
    p_email_clear boolean DEFAULT false,
    p_email character varying DEFAULT NULL::character varying,
    p_phone_clear boolean DEFAULT false,
    p_phone character varying DEFAULT NULL::character varying,
    p_dateofbirth_clear boolean DEFAULT false,
    p_dateofbirth date DEFAULT NULL::date,
    p_gender_clear boolean DEFAULT false,
    p_gender character varying DEFAULT NULL::character varying,
    p_photourl_clear boolean DEFAULT false,
    p_photourl character varying DEFAULT NULL::character varying,
    p_bio_clear boolean DEFAULT false,
    p_bio text DEFAULT NULL::text,
    p_linkeduserid_clear boolean DEFAULT false,
    p_linkeduserid uuid DEFAULT NULL::uuid,
    p_status character varying DEFAULT NULL::character varying,
    p_supervisorpersonid_clear boolean DEFAULT false,
    p_supervisorpersonid uuid DEFAULT NULL::uuid
)
 RETURNS SETOF __mj_bizappscommon."vwPeople"
 LANGUAGE plpgsql
AS $function$
#variable_conflict use_column
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
        "Status" = COALESCE(p_status, "Status"),
        "SupervisorPersonID" = CASE WHEN p_supervisorpersonid_clear = true THEN NULL ELSE COALESCE(p_supervisorpersonid, "SupervisorPersonID") END,
        "__mj_UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE
        "ID" = p_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    IF v_updated_count = 0 THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT * FROM __mj_bizappscommon."vwPeople"
    WHERE "ID" = p_id;
END;
$function$;
$fn$;
    END IF;

    BEGIN
        REVOKE EXECUTE ON FUNCTION __mj_bizappscommon."spCreatePerson" FROM "cdp_Developer";
        REVOKE EXECUTE ON FUNCTION __mj_bizappscommon."spCreatePerson" FROM "cdp_Integration";
        GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreatePerson" TO "cdp_Developer", "cdp_Integration";
        REVOKE EXECUTE ON FUNCTION __mj_bizappscommon."spUpdatePerson" FROM "cdp_Developer";
        REVOKE EXECUTE ON FUNCTION __mj_bizappscommon."spUpdatePerson" FROM "cdp_Integration";
        GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdatePerson" TO "cdp_Developer", "cdp_Integration";
    EXCEPTION WHEN undefined_object THEN NULL;
    END;
END
$install_person_crud$;

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
