-- =============================================================================================
-- PostgreSQL counterpart of V202611021520__v5.58.x__Company_Sender_Identity.sql
-- =============================================================================================
-- `mj sql-convert --from tsql --to postgres --schema __mj_BizAppsCommon` (MJ CLI 6.1.6) output,
-- then `scripts/pg-finalize.mjs`, finished by hand:
--   * Table, constraints, indexes, view, data, comments and grants are the converter's.
--   * CodeGen's CRUD procedures (spCreate/spUpdate/spDelete) and its __mj_UpdatedAt trigger are
--     NOT here: the converter cannot translate T-SQL procedures or triggers. A PostgreSQL host
--     runs `mj codegen` after installing, which generates them natively. The converter's notes
--     for them remain, fully commented out.
--   * By hand: the FK's referenced column quoted ("ID"); the filtered unique index name quoted;
--     the schema, the view-rebuild block's target schema and Entity.SchemaName lowercased; the
--     EntityPermission INSERT ... SELECT flags written as TRUE/FALSE.
-- Schema names are written unquoted, as the converter emits them, so they fold to the lowercase
-- schema a PostgreSQL install uses.
-- =============================================================================================

SET standard_conforming_strings = on;

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

-- =============================================================================
-- Migration: V202611021520__v5.58.x__Company_Sender_Identity.sql
-- Description: Add CompanySenderIdentity, the sender addresses and domains a company may send from.
--
-- WHY. A company (an MJ core Company) sends email as one or more mailboxes, or as any address on
-- a verified domain. Common owns the list so every consuming app reads one source for "who may
-- this company send as". Kind says what Address holds: a full mailbox, or a bare domain.
--
-- IsDefault marks the company's default sender. The filtered unique index allows at most one
-- default per company; the database does not check that a default is a Mailbox row (a domain has
-- no usable local part), so the entity enforces that rule.
-- =============================================================================
CREATE TABLE __mj_BizAppsCommon."CompanySenderIdentity" (
 "ID" UUID NOT NULL DEFAULT gen_random_uuid(),
 "CompanyID" UUID NOT NULL,
 "Kind" VARCHAR(20) NOT NULL,
 "Address" VARCHAR(320) NOT NULL,
 "DisplayName" VARCHAR(200) NULL,
 "IsDefault" BOOLEAN NOT NULL DEFAULT FALSE,
 CONSTRAINT "PK_CompanySenderIdentity" PRIMARY KEY ("ID"),
 CONSTRAINT "FK_CompanySenderIdentity_Company" FOREIGN KEY ("CompanyID") REFERENCES ${mjSchema}."Company"("ID"),
 CONSTRAINT "UQ_CompanySenderIdentity_CompanyAddress" UNIQUE ("CompanyID", "Address"),
 CONSTRAINT "CK_CompanySenderIdentity_Kind" CHECK ("Kind" IN ('Mailbox', 'Domain'))
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_CompanySenderIdentity_Default"
    ON __mj_BizAppsCommon."CompanySenderIdentity" ("CompanyID")
    WHERE "IsDefault" = TRUE;

ALTER TABLE __mj_BizAppsCommon."CompanySenderIdentity"
 ADD COLUMN IF NOT EXISTS "__mj_CreatedAt" TIMESTAMPTZ NULL;

/* SQL text to add special date field __mj_UpdatedAt to entity __mj_BizAppsCommon.CompanySenderIdentity */
ALTER TABLE __mj_BizAppsCommon."CompanySenderIdentity"
 ADD COLUMN IF NOT EXISTS "__mj_UpdatedAt" TIMESTAMPTZ NULL;

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_CompanySenderIdentity_CompanyID" ON __mj_BizAppsCommon."CompanySenderIdentity" ("CompanyID");


-- ===================== Views =====================

DROP VIEW IF EXISTS __mj_BizAppsCommon."vwCompanySenderIdentities" CASCADE;
DO $do$
DECLARE
  v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
  v_target_name CONSTANT TEXT := 'vwCompanySenderIdentities';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_BizAppsCommon."vwCompanySenderIdentities"
AS SELECT
    c.*,
    "MJCompany_CompanyID"."Name" AS "Company"
FROM
    __mj_BizAppsCommon."CompanySenderIdentity" AS c
INNER JOIN
    ${mjSchema}."Company" AS "MJCompany_CompanyID"
  ON
    c."CompanyID" = "MJCompany_CompanyID"."ID"$vsql$;
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
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spCreateCompanySenderIdentity]
--     @ID UUID = NULL,
--     @CompanyID UUID,
--     @Kind VARCHAR(20),
--     @Address VARCHAR(320),
--     @Display...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spUpdateCompanySenderIdentity]
--     @ID UUID,
--     @CompanyID UUID = NULL,
--     @Kind VARCHAR(20) = NULL,
--     @Address VARCHAR(320) = NULL...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE [__mj_BizAppsCommon].[spDeleteCompanySenderIdentity]
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         [__mj_BizAppsCommon].[CompanySenderIdentity]
--     WH...


-- ===================== Triggers =====================

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_BizAppsCommon].trgUpdateCompanySenderIdentity
-- ON __mj_BizAppsCommon."CompanySenderIdentity"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         __mj_BizAppsCommon.[Co


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

INSERT INTO ${mjSchema}."Entity" (
         "ID",
         "Name",
         "DisplayName",
         "Description",
         "NameSuffix",
         "BaseTable",
         "BaseView",
         "SchemaName",
         "IncludeInAPI",
         "AllowUserSearchAPI",
         "AllowCaching"
         , "TrackRecordChanges"
         , "AuditRecordAccess"
         , "AuditViewRuns"
         , "AllowAllRowsAPI"
         , "AllowCreateAPI"
         , "AllowUpdateAPI"
         , "AllowDeleteAPI"
         , "UserViewMaxRows"
         , "__mj_CreatedAt"
         , "__mj_UpdatedAt"
      )
      VALUES (
         '64c02581-1ae6-4e8d-a4f2-0d9bed1a9b13',
         'MJ_BizApps_Common: Company Sender Identities',
         'Company Sender Identities',
         'An address or domain a company may send email as. One row per sender identity; a company can have several.',
         NULL,
         'CompanySenderIdentity',
         'vwCompanySenderIdentities',
         '__mj_bizappscommon',
         TRUE,
         TRUE,
         FALSE
         , TRUE
         , FALSE
         , FALSE
         , FALSE
         , TRUE
         , TRUE
         , TRUE
         , 1000
         , NOW()
         , NOW()
      );

/* SQL generated to add new entity MJ_BizApps_Common: Company Sender Identities to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */

INSERT INTO ${mjSchema}."ApplicationEntity"
                                       ("ApplicationID", "EntityID", "Sequence", "__mj_CreatedAt", "__mj_UpdatedAt") VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '64c02581-1ae6-4e8d-a4f2-0d9bed1a9b13', (SELECT COALESCE(MAX("Sequence"),0)+1 FROM ${mjSchema}."ApplicationEntity" WHERE "ApplicationID" = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), NOW(), NOW());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Company Sender Identities for role UI */

INSERT INTO ${mjSchema}."EntityPermission"
                ("EntityID", "RoleID", "Type", "CanRead", "CanCreate", "CanUpdate", "CanDelete", "__mj_CreatedAt", "__mj_UpdatedAt")
              SELECT CAST('64c02581-1ae6-4e8d-a4f2-0d9bed1a9b13' AS UUID), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID), 'Allow', TRUE, FALSE, FALSE, FALSE, NOW(), NOW()
              WHERE NOT EXISTS (
                SELECT 1 FROM ${mjSchema}."EntityPermission"
                WHERE "EntityID" = CAST('64c02581-1ae6-4e8d-a4f2-0d9bed1a9b13' AS UUID) AND "RoleID" = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID) AND "Type" = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Company Sender Identities for role Developer */

INSERT INTO ${mjSchema}."EntityPermission"
                ("EntityID", "RoleID", "Type", "CanRead", "CanCreate", "CanUpdate", "CanDelete", "__mj_CreatedAt", "__mj_UpdatedAt")
              SELECT CAST('64c02581-1ae6-4e8d-a4f2-0d9bed1a9b13' AS UUID), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID), 'Allow', TRUE, TRUE, TRUE, TRUE, NOW(), NOW()
              WHERE NOT EXISTS (
                SELECT 1 FROM ${mjSchema}."EntityPermission"
                WHERE "EntityID" = CAST('64c02581-1ae6-4e8d-a4f2-0d9bed1a9b13' AS UUID) AND "RoleID" = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID) AND "Type" = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Company Sender Identities for role Integration */

INSERT INTO ${mjSchema}."EntityPermission"
                ("EntityID", "RoleID", "Type", "CanRead", "CanCreate", "CanUpdate", "CanDelete", "__mj_CreatedAt", "__mj_UpdatedAt")
              SELECT CAST('64c02581-1ae6-4e8d-a4f2-0d9bed1a9b13' AS UUID), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID), 'Allow', TRUE, TRUE, TRUE, TRUE, NOW(), NOW()
              WHERE NOT EXISTS (
                SELECT 1 FROM ${mjSchema}."EntityPermission"
                WHERE "EntityID" = CAST('64c02581-1ae6-4e8d-a4f2-0d9bed1a9b13' AS UUID) AND "RoleID" = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS UUID) AND "Type" = 'Allow'
              );

/* SQL text to add special date field __mj_CreatedAt to entity __mj_BizAppsCommon."CompanySenderIdentity" */

/* SQL text to add special date field __mj_CreatedAt to entity __mj_BizAppsCommon."CompanySenderIdentity" */
UPDATE __mj_BizAppsCommon."CompanySenderIdentity" SET "__mj_CreatedAt" = NOW() WHERE "__mj_CreatedAt" IS NULL;

/* SQL text to add special date field __mj_CreatedAt to entity __mj_BizAppsCommon.CompanySenderIdentity */
ALTER TABLE __mj_BizAppsCommon."CompanySenderIdentity" ALTER COLUMN "__mj_CreatedAt" SET NOT NULL;

ALTER TABLE __mj_BizAppsCommon."CompanySenderIdentity"
  ALTER COLUMN "__mj_CreatedAt" SET DEFAULT NOW();

/* SQL text to add special date field __mj_UpdatedAt to entity __mj_BizAppsCommon."CompanySenderIdentity" */
UPDATE __mj_BizAppsCommon."CompanySenderIdentity" SET "__mj_UpdatedAt" = NOW() WHERE "__mj_UpdatedAt" IS NULL;

/* SQL text to add special date field __mj_UpdatedAt to entity __mj_BizAppsCommon.CompanySenderIdentity */
ALTER TABLE __mj_BizAppsCommon."CompanySenderIdentity" ALTER COLUMN "__mj_UpdatedAt" SET NOT NULL;

ALTER TABLE __mj_BizAppsCommon."CompanySenderIdentity"
  ALTER COLUMN "__mj_UpdatedAt" SET DEFAULT NOW();

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ${mjSchema}."EntityField" WHERE "ID" = 'a770a82f-0e97-4147-9cda-9f7491cf0b2f' OR ("EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13' AND "Name" = 'ID')
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
        'a770a82f-0e97-4147-9cda-9f7491cf0b2f',
        '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13', -- "Entity": "MJ_BizApps_Common": "Company" "Sender" "Identities"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM ${mjSchema}."EntityField" WHERE "EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13'),
        'ID',
        'ID',
        'Unique identifier for the sender identity.',
        'UUID',
        16,
        0,
        0,
        FALSE,
        'gen_random_uuid()',
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        TRUE,
        TRUE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ${mjSchema}."EntityField" WHERE "ID" = '0362cda4-d1dc-4529-9e78-1a43aaf40fd1' OR ("EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13' AND "Name" = 'CompanyID')
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
        '0362cda4-d1dc-4529-9e78-1a43aaf40fd1',
        '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13', -- "Entity": "MJ_BizApps_Common": "Company" "Sender" "Identities"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM ${mjSchema}."EntityField" WHERE "EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13'),
        'CompanyID',
        'Company ID',
        'The company that owns this sender identity.',
        'UUID',
        16,
        0,
        0,
        FALSE,
        NULL,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        'D4238F34-2837-EF11-86D4-6045BDEE16E6',
        'ID',
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        TRUE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ${mjSchema}."EntityField" WHERE "ID" = '179bdb81-1e4c-4ce0-940f-fb10641e08f1' OR ("EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13' AND "Name" = 'Kind')
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
        '179bdb81-1e4c-4ce0-940f-fb10641e08f1',
        '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13', -- "Entity": "MJ_BizApps_Common": "Company" "Sender" "Identities"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM ${mjSchema}."EntityField" WHERE "EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13'),
        'Kind',
        'Kind',
        'What Address holds: Mailbox is one full email address, Domain is a bare domain any address on which may be used.',
        'TEXT',
        40,
        0,
        0,
        FALSE,
        NULL,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        TRUE,
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
        SELECT 1 FROM ${mjSchema}."EntityField" WHERE "ID" = '0550cd70-a5cb-4f0f-aed3-7e7abadcc691' OR ("EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13' AND "Name" = 'Address')
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
        '0550cd70-a5cb-4f0f-aed3-7e7abadcc691',
        '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13', -- "Entity": "MJ_BizApps_Common": "Company" "Sender" "Identities"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM ${mjSchema}."EntityField" WHERE "EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13'),
        'Address',
        'Address',
        'The sender address, stored trimmed and lower-cased by the entity; a full mailbox when Kind = Mailbox, a bare domain when Kind = Domain. Unique per company.',
        'TEXT',
        640,
        0,
        0,
        FALSE,
        NULL,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        TRUE,
        'Search',
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ${mjSchema}."EntityField" WHERE "ID" = '6f3545da-bbcb-437f-a2cf-f45c0d9c62db' OR ("EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13' AND "Name" = 'DisplayName')
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
        '6f3545da-bbcb-437f-a2cf-f45c0d9c62db',
        '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13', -- "Entity": "MJ_BizApps_Common": "Company" "Sender" "Identities"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM ${mjSchema}."EntityField" WHERE "EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13'),
        'DisplayName',
        'Display Name',
        'Optional friendly name shown with the address in the From line.',
        'TEXT',
        400,
        0,
        0,
        TRUE,
        NULL,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        NULL,
        NULL,
        FALSE,
        FALSE,
        FALSE,
        TRUE,
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
        SELECT 1 FROM ${mjSchema}."EntityField" WHERE "ID" = 'a39987e4-9b08-4866-b1f2-c544e5569c2c' OR ("EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13' AND "Name" = 'IsDefault')
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
        'a39987e4-9b08-4866-b1f2-c544e5569c2c',
        '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13', -- "Entity": "MJ_BizApps_Common": "Company" "Sender" "Identities"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM ${mjSchema}."EntityField" WHERE "EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13'),
        'IsDefault',
        'Is Default',
        'Marks the company''s default sender: at most one per company (UQ_CompanySenderIdentity_Default); only a Mailbox row is a usable default.',
        'BOOLEAN',
        1,
        1,
        0,
        FALSE,
        '(0)',
        FALSE,
        TRUE,
        FALSE,
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
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ${mjSchema}."EntityField" WHERE "ID" = '40b25180-0ab6-4237-a5c3-7dd422cfb184' OR ("EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13' AND "Name" = '__mj_CreatedAt')
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
        '40b25180-0ab6-4237-a5c3-7dd422cfb184',
        '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13', -- "Entity": "MJ_BizApps_Common": "Company" "Sender" "Identities"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM ${mjSchema}."EntityField" WHERE "EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13'),
        '__mj_CreatedAt',
        'Created At',
        NULL,
        'TIMESTAMPTZ',
        10,
        34,
        7,
        FALSE,
        'NOW()',
        FALSE,
        FALSE,
        FALSE,
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
        NOW(),
        NOW()
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ${mjSchema}."EntityField" WHERE "ID" = 'cc518ee0-4b52-4ad8-a378-9c0abef46d14' OR ("EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13' AND "Name" = '__mj_UpdatedAt')
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
        'cc518ee0-4b52-4ad8-a378-9c0abef46d14',
        '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13', -- "Entity": "MJ_BizApps_Common": "Company" "Sender" "Identities"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM ${mjSchema}."EntityField" WHERE "EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13'),
        '__mj_UpdatedAt',
        'Updated At',
        NULL,
        'TIMESTAMPTZ',
        10,
        34,
        7,
        FALSE,
        'NOW()',
        FALSE,
        FALSE,
        FALSE,
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
        NOW(),
        NOW()
        );
    END IF;
END $$;

INSERT INTO ${mjSchema}."EntityFieldValue"
                                       ("ID", "EntityFieldID", "Sequence", "Value", "Code", "__mj_CreatedAt", "__mj_UpdatedAt")
                                    VALUES
                                       ('bad4dbe8-4231-4eb8-bc75-8ae1d41817f2', '179BDB81-1E4C-4CE0-940F-FB10641E08F1', 1, 'Domain', 'Domain', NOW(), NOW());

/* SQL text to insert entity field value with ID ce2fb109-c53c-4516-b0a4-20bdf4eb1d6a */

INSERT INTO ${mjSchema}."EntityFieldValue"
                                       ("ID", "EntityFieldID", "Sequence", "Value", "Code", "__mj_CreatedAt", "__mj_UpdatedAt")
                                    VALUES
                                       ('ce2fb109-c53c-4516-b0a4-20bdf4eb1d6a', '179BDB81-1E4C-4CE0-940F-FB10641E08F1', 2, 'Mailbox', 'Mailbox', NOW(), NOW());

/* SQL text to update ValueListType for entity field ID 179BDB81-1E4C-4CE0-940F-FB10641E08F1 */

UPDATE ${mjSchema}."EntityField" SET "ValueListType"='List' WHERE "ID"='179BDB81-1E4C-4CE0-940F-FB10641E08F1';


/* Create Entity Relationship: MJ: Companies -> MJ_BizApps_Common: Company Sender Identities (One To Many via CompanyID) */

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ${mjSchema}."EntityRelationship" WHERE "ID" = '43849959-24fd-4924-b391-86ae32e6895c'
    ) THEN
        INSERT INTO ${mjSchema}."EntityRelationship" ("ID", "EntityID", "RelatedEntityID", "RelatedEntityJoinField", "Type", "BundleInAPI", "DisplayInForm", "Sequence", "__mj_CreatedAt", "__mj_UpdatedAt")
        VALUES ('43849959-24fd-4924-b391-86ae32e6895c', 'D4238F34-2837-EF11-86D4-6045BDEE16E6', '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13', 'CompanyID', 'One To Many', TRUE, TRUE, 7, NOW(), NOW());
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ${mjSchema}."EntityField" WHERE "ID" = '08e11ee2-961d-455c-ba52-5289340a2c36' OR ("EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13' AND "Name" = 'Company')
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
        '08e11ee2-961d-455c-ba52-5289340a2c36',
        '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13', -- "Entity": "MJ_BizApps_Common": "Company" "Sender" "Identities"
        (SELECT COALESCE(MAX("Sequence"), 0) + 1 FROM ${mjSchema}."EntityField" WHERE "EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13'),
        'Company',
        'Company',
        NULL,
        'TEXT',
        100,
        0,
        0,
        FALSE,
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
        NOW(),
        NOW()
        );
    END IF;
END $$;

UPDATE ${mjSchema}."EntityField"
               SET "IsNameField" = TRUE
               WHERE "ID" = '6F3545DA-BBCB-437F-A2CF-F45C0D9C62DB'
               AND "AutoUpdateIsNameField" = TRUE;

UPDATE ${mjSchema}."EntityField"
               SET "DefaultInView" = TRUE
               WHERE "ID" = 'A39987E4-9B08-4866-B1F2-C544E5569C2C'
               AND "AutoUpdateDefaultInView" = TRUE;

UPDATE ${mjSchema}."EntityField"
               SET "DefaultInView" = TRUE
               WHERE "ID" = '08E11EE2-961D-455C-BA52-5289340A2C36'
               AND "AutoUpdateDefaultInView" = TRUE;

UPDATE ${mjSchema}."EntityField"
               SET "IncludeInUserSearchAPI" = TRUE
               WHERE "ID" = '0550CD70-A5CB-4F0F-AED3-7E7ABADCC691'
               AND "AutoUpdateIncludeInUserSearchAPI" = TRUE;

UPDATE ${mjSchema}."EntityField"
               SET "IncludeInUserSearchAPI" = TRUE
               WHERE "ID" = '6F3545DA-BBCB-437F-A2CF-F45C0D9C62DB'
               AND "AutoUpdateIncludeInUserSearchAPI" = TRUE;

UPDATE ${mjSchema}."EntityField"
               SET "UserSearchPredicateAPI" = 'BeginsWith'
               WHERE "ID" = '0550CD70-A5CB-4F0F-AED3-7E7ABADCC691'
               AND "AutoUpdateUserSearchPredicate" = TRUE;

UPDATE ${mjSchema}."EntityField"
               SET "UserSearchPredicateAPI" = 'BeginsWith'
               WHERE "ID" = '6F3545DA-BBCB-437F-A2CF-F45C0D9C62DB'
               AND "AutoUpdateUserSearchPredicate" = TRUE;

/* Set categories for 9 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Company Sender Identities.ID

UPDATE ${mjSchema}."EntityField"
SET 
   "Category" = 'System Metadata',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = 'A770A82F-0E97-4147-9CDA-9F7491CF0B2F';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Company Sender Identities.CompanyID

UPDATE ${mjSchema}."EntityField"
SET 
   "Category" = 'Identity Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '0362CDA4-D1DC-4529-9E78-1A43AAF40FD1';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Company Sender Identities.Company

UPDATE ${mjSchema}."EntityField"
SET 
   "Category" = 'Identity Details',
   "GeneratedFormSection" = 'Category',
   "DisplayName" = 'Company Name'
WHERE 
   "ID" = '08E11EE2-961D-455C-BA52-5289340A2C36';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Company Sender Identities.Kind

UPDATE ${mjSchema}."EntityField"
SET 
   "Category" = 'Identity Details',
   "GeneratedFormSection" = 'Category',
   "DisplayName" = 'Identity Kind'
WHERE 
   "ID" = '179BDB81-1E4C-4CE0-940F-FB10641E08F1';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Company Sender Identities.Address

UPDATE ${mjSchema}."EntityField"
SET 
   "Category" = 'Identity Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '0550CD70-A5CB-4F0F-AED3-7E7ABADCC691';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Company Sender Identities.DisplayName

UPDATE ${mjSchema}."EntityField"
SET 
   "Category" = 'Identity Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '6F3545DA-BBCB-437F-A2CF-F45C0D9C62DB';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Company Sender Identities.IsDefault

UPDATE ${mjSchema}."EntityField"
SET 
   "Category" = 'Identity Details',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = 'A39987E4-9B08-4866-B1F2-C544E5569C2C';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Company Sender Identities.__mj_CreatedAt

UPDATE ${mjSchema}."EntityField"
SET 
   "Category" = 'System Metadata',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = '40B25180-0AB6-4237-A5C3-7DD422CFB184';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Company Sender Identities.__mj_UpdatedAt

UPDATE ${mjSchema}."EntityField"
SET 
   "Category" = 'System Metadata',
   "GeneratedFormSection" = 'Category'
WHERE 
   "ID" = 'CC518EE0-4B52-4AD8-A378-9C0ABEF46D14';

/* Set entity icon to fa fa-envelope-open-text */

UPDATE ${mjSchema}."Entity"
               SET "Icon" = 'fa fa-envelope-open-text', "__mj_UpdatedAt" = NOW()
               WHERE "ID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13';

/* Insert FieldCategoryInfo setting for entity */

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ${mjSchema}."EntitySetting" WHERE "EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13' AND "Name" = 'FieldCategoryInfo'
    ) THEN
        INSERT INTO ${mjSchema}."EntitySetting" ("ID", "EntityID", "Name", "Value", "__mj_CreatedAt", "__mj_UpdatedAt")
        VALUES ('eb9b290e-80b1-5bd2-90d3-f1b438c45438', '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13', 'FieldCategoryInfo', '{
        "Identity Details": {
        "description": "Configuration settings for the sender identity, including type, address, and default status",
        "icon": "fa fa-id-card"
        },
        "System Metadata": {
        "description": "System-managed audit and tracking fields",
        "icon": "fa fa-cog"
        }
        }', NOW(), NOW());
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ${mjSchema}."EntitySetting" WHERE "EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13' AND "Name" = 'FieldCategoryIcons'
    ) THEN
        INSERT INTO ${mjSchema}."EntitySetting" ("ID", "EntityID", "Name", "Value", "__mj_CreatedAt", "__mj_UpdatedAt")
        VALUES ('5902d27d-b468-53ac-95d8-a52af329ccbc', '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13', 'FieldCategoryIcons', '{
        "Identity Details": "fa fa-id-card",
        "System Metadata": "fa fa-cog"
        }', NOW(), NOW());
    END IF;
END $$;

UPDATE ${mjSchema}."ApplicationEntity"
         SET "DefaultForNewUser" = FALSE, "__mj_UpdatedAt" = NOW()
         WHERE "EntityID" = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13';


-- ===================== Grants =====================

DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwCompanySenderIdentities" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* Base View Permissions SQL for MJ_BizApps_Common: Company Sender Identities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Company Sender Identities
-- Item: Permissions for vwCompanySenderIdentities
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

DO $$ BEGIN GRANT SELECT ON __mj_BizAppsCommon."vwCompanySenderIdentities" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Company Sender Identities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Company Sender Identities
-- Item: spCreateCompanySenderIdentity
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR CompanySenderIdentity
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateCompanySenderIdentity" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Company Sender Identities */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spCreateCompanySenderIdentity" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Company Sender Identities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Company Sender Identities
-- Item: spUpdateCompanySenderIdentity
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR CompanySenderIdentity
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateCompanySenderIdentity" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spUpdateCompanySenderIdentity" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Company Sender Identities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Company Sender Identities
-- Item: spDeleteCompanySenderIdentity
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR CompanySenderIdentity
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteCompanySenderIdentity" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Company Sender Identities */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_BizAppsCommon."spDeleteCompanySenderIdentity" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* SQL text to insert 1 new entity field(s) */


-- ===================== Comments =====================

COMMENT ON TABLE __mj_BizAppsCommon."CompanySenderIdentity" IS 'An address or domain a company may send email as. One row per sender identity; a company can have several.';

COMMENT ON COLUMN __mj_BizAppsCommon."CompanySenderIdentity"."ID" IS 'Unique identifier for the sender identity.';

COMMENT ON COLUMN __mj_BizAppsCommon."CompanySenderIdentity"."CompanyID" IS 'The company that owns this sender identity.';

COMMENT ON COLUMN __mj_BizAppsCommon."CompanySenderIdentity"."Kind" IS 'What Address holds: Mailbox is one full email address, Domain is a bare domain any address on which may be used.';

COMMENT ON COLUMN __mj_BizAppsCommon."CompanySenderIdentity"."Address" IS 'The sender address, stored trimmed and lower-cased by the entity; a full mailbox when Kind = Mailbox, a bare domain when Kind = Domain. Unique per company.';

COMMENT ON COLUMN __mj_BizAppsCommon."CompanySenderIdentity"."DisplayName" IS 'Optional friendly name shown with the address in the From line.';

COMMENT ON COLUMN __mj_BizAppsCommon."CompanySenderIdentity"."IsDefault" IS 'Marks the company''s default sender: at most one per company (UQ_CompanySenderIdentity_Default); only a Mailbox row is a usable default.';


-- ===================== Other =====================

/* ============================================================================================
   ==== CODEGEN OUTPUT — DO NOT EDIT BELOW THIS LINE ====
   Generated by the MemberJunction CodeGen tool from the mj dev workspace link to MJ next source
   (../MJ, commit 32db642), includeSchemas ['__mj_BizAppsCommon'], against a database built from
   migrations alone (MJ core v6.1.6 migrations from that checkout, then this repo's chain at
   origin/next ed045a0, then the DDL above).
   Contains: the CompanySenderIdentity entity, fields, relationships, view, CRUD procs and FK
   indexes.
   Do NOT edit by hand. If the hand-written SQL above changes, re-run CodeGen and replace this
   whole section.
   ============================================================================================ */
/* SQL generated to create new entity MJ_BizApps_Common: Company Sender Identities */

/* SQL text to insert 8 new entity field(s) */

/* spUpdate Permissions for MJ_BizApps_Common: Company Sender Identities */
