# Verifying BizApps Common on PostgreSQL (one-shot install, no CodeGen)

This runbook simulates what `mj app install` does to a PostgreSQL database and
verifies that the app is **fully functional without ever running `mj codegen`**.

Why simulate instead of running the real command? `mj app install` downloads
the app's migrations from the **latest GitHub release**. To test unreleased
changes to `migrations-pg/`, you run the same four database steps the installer
performs — mapped 1:1 from `@memberjunction/open-app-engine`'s
`install-orchestrator` — but point the migration step at your local branch.
Once a release ships, step 3 collapses back to the real `mj app install`.

Background: on SQL Server, CodeGen's DDL (CRUD sprocs, views, triggers, grants)
is appended into the migrations at authoring time, so an install is complete on
its own. The PG conversion pipeline cannot translate T-SQL procedures
(`-- SKIPPED: procedure (auto-conversion not supported)`), so historically a PG
install was incomplete until a consumer ran `mj codegen`. The `migrations-pg/`
files in this repo now carry CodeGen's native plpgsql directly (extracted
verbatim from a post-codegen v5.44 database — CodeGen's fixed point), which is
what makes the one-shot install work and makes a subsequent codegen run a no-op.

## 0. Fresh PostgreSQL (throwaway container)

```bash
docker run -d --name bac-pg-test \
  -e POSTGRES_USER=mj_admin -e POSTGRES_PASSWORD=<pw> \
  -e POSTGRES_DB=BAC_Test -p 5434:5432 postgres:17
```

## 1. Point the MJ CLI at it

Shell exports take precedence over `.env`, so nothing in the repo needs editing:

```bash
export DB_PLATFORM=postgresql DB_HOST=localhost DB_PORT=5434 \
  DB_DATABASE=BAC_Test DB_USERNAME=mj_admin DB_PASSWORD=<pw> \
  CODEGEN_DB_USERNAME=mj_admin CODEGEN_DB_PASSWORD=<pw> DB_ENCRYPT=false
```

`CODEGEN_DB_*` is required even for migrate — the CLI opens its admin
connection with those credentials.

## 2. Platform install (the consumer's `mj migrate`)

```bash
npx mj migrate --tag v5.44.0        # expect: 61 applied on a virgin DB
```

Do **not** run plain `npx mj migrate` — without `--tag` it uses this repo's
local migrations directory (the app's own), not MJ core's.

## 3. Simulate `mj app install` — four steps, the installer's exact order

```bash
# [Schema] HandleSchemaCreation
psql -h localhost -p 5434 -U mj_admin -d BAC_Test \
  -c 'CREATE SCHEMA IF NOT EXISTS __mj_bizappscommon;'

# [Schema] PersistCanonicalSchemaName — expect "UPDATE 0". The installer fires
# this BEFORE migrations, so it always misses on a fresh install. That is why
# the metadata-sync migration sets CanonicalSchemaName itself.
psql -h localhost -p 5434 -U mj_admin -d BAC_Test -c \
  "UPDATE __mj.\"SchemaInfo\" SET \"CanonicalSchemaName\"='__mj_BizAppsCommon'
   WHERE LOWER(\"SchemaName\")=LOWER('__mj_bizappscommon');"

# [Migration] HandleMigrations — the app's PG migrations from YOUR branch
npx mj migrate --schema __mj_BizAppsCommon --dir ./migrations-pg   # expect: 7 applied
# (the .pgonly.sql metadata backfill runs last; the history table gains one
# extra row for flyway's schema-creation entry)

# [Record] RecordInstallationAtomically + finalize Status=Active
psql -h localhost -p 5434 -U mj_admin -d BAC_Test -c \
  "INSERT INTO __mj.\"OpenApp\" (\"ID\",\"Name\",\"DisplayName\",\"Version\",\"Publisher\",
    \"RepositoryURL\",\"MJVersionRange\",\"ManifestJSON\",\"SchemaName\",\"InstalledByUserID\",\"Status\")
   SELECT gen_random_uuid(),'mj-bizapps-common','BizApps Common','<version>','MemberJunction',
    'https://github.com/MemberJunction/bizapps-common','>=5.40.2 <6.0.0','{}',
    '__mj_BizAppsCommon',(SELECT \"ID\" FROM __mj.\"User\" LIMIT 1),'Active';"
```

**Do not run codegen.** That is the point of the test.

Post-release, this whole step is one command:

```bash
npx mj app install https://github.com/MemberJunction/bizapps-common \
  --dangerously-ignore-dbl-underscore-schema-rule
```

(The flag is required because the app's schema starts with `__mj_`. The
installer's final "add packages to host project" step only succeeds inside a
real MJ host project — the database-side steps complete regardless.)

## 4. Verify everything is there

```sql
-- expected values in comments
SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
 WHERE n.nspname = '__mj_bizappscommon' AND p.proname LIKE 'sp%';        -- 30

SELECT count(*) FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid
 JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE NOT t.tgisinternal AND n.nspname = '__mj_bizappscommon';          -- 10

SELECT "CanonicalSchemaName" FROM __mj."SchemaInfo"
 WHERE "SchemaName" = '__mj_bizappscommon';                              -- __mj_BizAppsCommon

SELECT count(*) FROM __mj."vwEntities"
 WHERE "SchemaName" = '__mj_bizappscommon'
   AND "ClassName" LIKE 'mjBizAppsCommon%';                              -- 10 (and 0 lowercase)

SELECT (SELECT count(*) FROM __mj_bizappscommon."AddressType"),          -- 6
       (SELECT count(*) FROM __mj_bizappscommon."ContactType"),          -- 8
       (SELECT count(*) FROM __mj_bizappscommon."OrganizationType"),     -- 8
       (SELECT count(*) FROM __mj_bizappscommon."RelationshipType");     -- 14
```

Then the two live proofs:

```bash
# Functional suite — edit the pool config at the top of the script to your
# host/port/database/credentials first
node scripts/pg-objectmodel-test.mjs      # expect: RESULT: 17 passed, 0 failed

# MJAPI against it (same shell, exports still set)
npm run start:api                         # expect: DB PostgreSQL · 383 entities · Ready :4101
```

## 5. Optional: prove codegen is a no-op

Run `npx mj codegen`, then re-run every query in step 4 — identical numbers.
A stronger check snapshots every function/view/trigger definition hash plus all
`__mj` metadata rows before and after: the diff is empty.

CodeGen will rewrite this repo's generated TypeScript with PG-flavored doc
comments (`gen_random_uuid()` vs `newsequentialid()`, etc.) — restore them
afterward; they are not part of the test:

```bash
git checkout -- 'packages/Entities/src/generated' 'packages/Server/src/generated' \
  'packages/Angular/src/lib/generated' apps/MJAPI/schema.graphql
rm -rf temp_sql_scripts
```

## Things that look wrong but aren't

- **First codegen on a virgin MJ core reconciles ~4 CORE metadata rows**
  (`__mj` schema: the `CanonicalSchemaName` EntityField registrations on
  MJ: Schema Info / MJ: Entities, plus two `AllowsNull` flags on AI entities).
  That is MJ core's own migrations not shipping their codegen metadata — the
  same platform gap this repo fixed for its app schema — and it is outside
  BAC's control. The BAC acceptance criterion is that **no `__mj_bizappscommon`
  object and no app-entity metadata row changes**; that diff is empty.

- **Flyway history schema casing**: `mj migrate --schema __mj_BizAppsCommon`
  creates the history table in a quoted `"__mj_BizAppsCommon"` schema, while
  the real installer uses the lowercase physical schema. Cosmetic CLI
  inconsistency; affects nothing.
- **15 EntityField rows typed `TEXT`/`UUID`**: these are virtual view columns
  (FK display names like `Person`, `Organization`, plus `RootParentID`). On PG
  CodeGen types them from the view's column types — this is CodeGen's own
  fixed-point output, not leftover conversion damage.
- **Two SchemaInfo rows** (`__mj_bizappscommon` + `__mj_BizAppsCommon`): the
  second is what CodeGen auto-creates keyed by the canonical name; the
  metadata-sync migration pre-creates it with a pinned ID so codegen has
  nothing to add.

## Maintenance contract

The plpgsql in `migrations-pg/` is CodeGen's own emission, frozen at v5.44.
When a future schema change regenerates any CRUD function, view, or trigger,
the new definition must be captured into the corresponding PG migration (the
manual PG analog of what `appendOutputCode` does automatically for T-SQL).
The no-op check in step 5 is the regression test for this: if codegen changes
anything after a fresh install, a migration is missing codegen output.

## Cleanup

```bash
docker rm -f bac-pg-test
```
