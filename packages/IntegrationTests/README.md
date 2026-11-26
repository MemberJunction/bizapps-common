# @mj-biz-apps/common-integration-tests

GraphQL-wire integration checks for BizApps Common. **Private — never published.**

Every check runs through `GraphQLDataProvider` against a **running MJAPI**. That is the point:
serialization, resolvers, auth, and field mapping are on the path. There is no SQL pool and no
in-process `SQLServerDataProvider`.

```
bootstrapIntegrationClient → GraphQLDataProvider → MJAPI → SQL
```

## Running

MJAPI must be up (`GRAPHQL_PORT`, `MJ_API_KEY` in the environment — typically the MJ repo `.env`).
You may wipe party rows in the `bizapps_orders` database between runs.

```bash
# from this repo root
pnpm --filter @mj-biz-apps/common-integration-tests build
node test-harnesses/integration.mjs                 # all bundles
node test-harnesses/integration.mjs people          # one bundle
node test-harnesses/integration.mjs people.P1       # one check
IT_VERBOSE=1 node test-harnesses/integration.mjs    # stack traces
```

`mj test` also loads this package via `mj.config.cjs` `testing.checkModules`.

## World (000)

`common-world.CW1` upserts **COM-WORLD**: ten people, seven organizations (including a parent/child),
three HQ addresses, primary email contact methods, and employment relationships.

Shipped **types** (Organization Type, Address Type, Contact Type, Relationship Type) are looked up
from metadata and never created. Missing types fail the load.

Rows are keyed by `@com-world.test` emails so they are idempotent and easy to find.

## Bundles

| Bundle | Checks |
|---|---|
| `common-world` | CW1 |
| `people` | P1–P5 |
| `organizations` | O1–O3 |
| `contacts-addresses` | CA1–CA3 |
| `relationships` | R1–R4 |
| `activities` | A1–A7 (types, regarding/xor/unresolved links, ExternalID, sync, `SaveReturnMode`, and A7 Category B Hybrid `Activity.ArtifactID` fast-path/link/unlink/FK refusal) |
| `party-lookup` | PL1–PL4 |
| `company-org-mirror` | CM1–CM4 (`MJ: Companies` → `Organization` auto-mirroring, update sync, `SyncCompaniesToOrganizations` RPC, `UQ_Organization_LinkedCompanyID` uniqueness) |
| `activity-sync` | AS-D1–D4, AS-R1–R5, AS-S1–S3, AS-C1–C5 (needs a sandbox host, below; not in the default run, so name it) |

## Activity Sync sandbox (`activity-sync`)

These checks run the real `Common.SyncActivities` action over GraphQL against Microsoft365
connections whose mail and calendar come from fixture files in [`sandbox/`](sandbox/), instead of
Microsoft Graph. Like a payment sandbox test mode: same front door, test data.

- **The host must opt in.** Start MJAPI with `ACTIVITY_SYNC_SANDBOX_DIR` set to the absolute path of
  `packages/IntegrationTests/sandbox`. On any other host a `sandbox:` connection is refused (never
  looked up as a credential), and a host that also allows live mailbox fetch refuses to start.
  On such a host every check fails with that refusal, so a run with no arguments skips this bundle
  and prints why; name it to run it.
- **Use a private database and MJAPI** (one per agent). From the repo root, with an env file whose
  `DB_DATABASE` is yours:
  ```bash
  GRAPHQL_PORT=4391 ACTIVITY_SYNC_SANDBOX_DIR=$PWD/packages/IntegrationTests/sandbox \
    DOTENV_CONFIG_PATH=<your env file> \
    node --experimental-specifier-resolution=node -r dotenv/config ../MJ/packages/MJAPI/dist/index.js
  GRAPHQL_PORT=4391 node test-harnesses/integration.mjs common-world activity-sync
  ```
  (`test-harnesses/integration.mjs` from the root currently needs the workaround in bizapps-common#286.)
- **A connection's ref is `sandbox:<scenario>:<tag>`.** The scenario picks `<scenario>.mail.json` and
  `<scenario>.calendar.json`; the tag (each check's stamp) is appended to every item id, because the
  engine dedupes on SourceSystem + ExternalID across all mailboxes and fixed fixture ids would
  collide between runs.
- **Rows written are `Source = 'System'`**, never `'Integration'`. Connections end Disabled.
- **Tagged (consent) connections** (`AS-C1–C5`, `consent` and `consent-late` scenarios): a connection
  whose `Settings` holds `{"Consent":{"Mode":"Tagged","Tag":"AIDP"}}` captures only what the mailbox
  owner tagged, proven replies to it and the earlier messages it names. `consent-late` is the same
  mailbox after the owner tagged one old email and untagged one email and one meeting, so the checks
  cover the late-tag sweep and the withdrawal. The fixtures carry the reply headers and sensitivity as
  the `singleValueExtendedProperties` a live read expands.
- **Fixtures are generated** by `node sandbox/build-fixtures.mjs` from the ActivitySync demo Graph
  payloads; `src/__tests__/sandbox-fixtures.test.ts` checks the committed files match. Calendar
  shapes were never compared with live Graph data; the files say so.

## Rules

1. Use `ctx.Provider.GetEntityObject<TypedEntity>(...)` and typed properties — never `.Get()` / `.Set()`.
2. Lookups go through `RunView.FromMetadataProvider(ctx.Provider)` — never `ctx.Pool`.
3. Compare IDs with `SameID` / `UUIDsEqual` (SQL Server uppercases GUIDs; PostgreSQL lowercases UUIDs).
4. A refused save must assert the refusal (`Assert(!saved)`), not only that something failed.

## Dual-DBMS Cross-Stack Activity Hybrid Verification

For parallel SQL Server + PostgreSQL schema parity, multi-entity domain seeding (`scripts/seed-activity-hybrid-world.mjs`, `>= 20` domain records across organizations, people, roles/permissions, `Note`/`Call`/`Meeting`/`Email` activities, and linked/unlinked MJ Docs), FK adversarial checks, RLS boundaries, and transactional rollback hygiene, run via the workspace broker:

```bash
node ../bizapps-software-factory/scripts/sf-workspace-db-broker.mjs rehearse-dual-db \
  --repo . \
  --schema __mj_BizAppsCommon \
  --migrations migrations/V202611261245__v6.3.x__Activity_ArtifactID.sql \
  --sync-metadata \
  --integration-cmd "node packages/IntegrationTests/checks/activity-hybrid-artifact.check.mjs"
```

Deterministic offline parity and guard checks also run automatically inside `pnpm test` via `src/__tests__/ActivityPgParityAndGuards.test.ts`.
