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


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

-- =============================================================================
-- Migration: V202610201800__v5.56.x__People_Field_Level_Security.sql
-- Description: Turn on field-level security for MJ_BizApps_Common: People and
--              give every role that can read People a permission row on each
--              restrictable field, computed from this host's own permissions
--              (#216, #186).
--
-- Why: Collaboration guests and participants may read only People's name and
-- email fields. Without field-level security, any role with People read sees
-- every field (phone, birth date, gender, address).
--
-- Why the rows are computed here: on an entity with field-level security on, a
-- field with no MJ: Entity Field Permissions row is denied to every user, the
-- system user included. MJ writes the rows only when an Entity or
-- EntityPermission is saved through its entity layer, or in CodeGen; hosts
-- upgrade by migration and run neither. Rows captured from a build database
-- would apply that database's roles, not the host's. So this migration applies
-- MJ's snapshot rule (MJCoreEntitiesServer fieldPermissionDelta.ts,
-- ComputeFieldPermissionDelta) to the host's own EntityPermission rows:
--   * Roles: each role's People permissions, Allow minus Deny per verb. Only
--     roles left with Read get rows.
--   * Fields: People's restrictable fields: not a primary key, not a soft
--     primary key, not an __mj_ column.
--   * ReadAccess = Allow. UpdateAccess / CreateAccess = Allow only when the
--     field is writable (AllowUpdateAPI = 1) and the role has the verb;
--     otherwise No Access.
--   * An existing (EntityFieldID, RoleID) row is never touched, as in MJ.
-- The snapshot changes no access: each role keeps exactly what its entity-level
-- permission gave it, until an administrator tightens a field.
--
-- The flag and the rows land in one migration, so one transaction: no host is
-- ever left with the flag on and no rows. metadata/entities/.entities.json
-- already declares EnableFieldLevelSecurity = true, so the next release seed's
-- push sees no change on People and does not reconcile build-database rows
-- into the seed.
--
-- The INSERT is the reusable block in migrations/README.md ("People columns
-- ship their field permissions"). A later migration that adds a People column
-- appends the same block after its CodeGen output.
--
-- Recovery: if a host's rows are ever wrong or missing, saving any People
-- Entity Permission through the UI makes MJ reconcile People for all roles.
-- =============================================================================

-- ---- People field permissions: MJ snapshot rule on this host's permissions ----
-- 7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F is MJ_BizApps_Common: People. The ID is a literal,
-- not a variable, and RoleAccess's columns are not named after boolean columns, so
-- mj migrate convert turns this block into PostgreSQL without hand edits.
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
-- ---- end block ----

UPDATE ${mjSchema}."Entity"
SET "EnableFieldLevelSecurity" = TRUE
WHERE "ID" = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F';
