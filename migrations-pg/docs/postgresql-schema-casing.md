# PostgreSQL Schema-Name Casing in BizApps Migrations

## TL;DR

On PostgreSQL, the app schema name is **lowercase** everywhere in the `.pg.sql`
migrations: `__mj_bizappscommon`, **not** `__mj_BizAppsCommon`. Object names
(tables, views, columns, constraints) stay **quoted PascalCase**
(`"OrganizationType"`, `"ID"`). The schema name is the only thing that folds.

```sql
-- ✅ correct
CREATE SCHEMA IF NOT EXISTS __mj_bizappscommon;
SET search_path TO __mj_bizappscommon, public;
CREATE TABLE __mj_bizappscommon."OrganizationType" ( "ID" UUID NOT NULL, ... );

-- ❌ wrong (mixed-case schema)
CREATE TABLE "__mj_BizAppsCommon"."OrganizationType" ( ... );
```

## Why lowercase

PostgreSQL case-folds **unquoted** identifiers to lowercase. The `mj-app.json`
manifest may declare a mixed-case schema (`__mj_BizAppsCommon`), but MJ's
OpenApp engine deliberately canonicalizes it to lowercase on PG so there is a
single physical schema. This is owned by `SQLDialect.CanonicalSchemaName`
(MJ commit `eb15944562`, "own PG schema-casing in SQLDialect"):

- `CanonicalSchemaName('__mj_BizAppsCommon')` → `'__mj_bizappscommon'` on PostgreSQL
- `CanonicalSchemaName('__mj_BizAppsCommon')` → `'__mj_BizAppsCommon'` on SQL Server (identity; SS is case-insensitive)

`OpenApp/Engine/install/schema-manager.ts` (schema CREATE) and
`migration-runner.ts` (Skyway `DefaultSchema` / `${flyway:defaultSchema}`)
both route through it. So on a `mj app install`:

- the physical schema is created as `__mj_bizappscommon`
- the migration DDL **must** target that same lowercase schema

If the migration instead uses mixed-case (quoted) `"__mj_BizAppsCommon"`, you
get the **mixed-case/lowercase split** the canonicalization exists to prevent:
tables land in one schema, Skyway history + metadata reference another.

## The CodeGen symptom this prevents

If the **physical schema** (lowercase, from migration DDL) and the **metadata
`SchemaName`** (`__mj.SchemaInfo` / `__mj.Entity.SchemaName`) disagree in case,
`mj codegen` treats the discovered tables as *new* entities, hits a name
collision against the already-seeded entities, and creates phantom duplicates
suffixed with the schema name, e.g.:

```
MJ_BizApps_Common: Organization Types____mj_bizappscommon → missing create routine: spCreateOrganizationType____mj_bizappscommon
```

Keeping **both** the physical schema and every metadata `SchemaName` literal
lowercase keeps them in agreement, and the duplicates do not occur. (A
companion CodeGen fix makes its new-entity-detection schema comparison
case-insensitive so this can't recur even if the two ever diverge — tracked
separately.)

## What this means for the PG migrations (`migrations-pg/`)

Every `__mj_bizappscommon` reference in `migrations-pg/*.pg.sql` is lowercase:
`CREATE SCHEMA`, `SET search_path`, schema-qualified object refs
(`__mj_bizappscommon."Table"`), `v_target_schema CONSTANT TEXT :=
'__mj_bizappscommon'` constants, and the `SchemaName` values seeded into
`SchemaInfo` / `Entity` rows.

References to the **core** schema `__mj` are unchanged — `__mj` is already
all-lowercase, so it never had a casing problem.

The SQL Server migrations (`migrations/`) are unaffected: they use
`${flyway:defaultSchema}` and SQL Server is case-insensitive.
