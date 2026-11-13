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
| `activities` | A1–A5 |
| `party-lookup` | PL1–PL4 |
| `activity-sync` | AS-D1–D4, AS-R1–R5, AS-S1–S3 (needs a sandbox host, below) |

## Activity Sync sandbox (`activity-sync`)

These checks run the real `Common.SyncActivities` action over GraphQL against Microsoft365
connections whose mail and calendar come from fixture files in [`sandbox/`](sandbox/), instead of
Microsoft Graph. Like Stripe test mode: same front door, test data.

- **The host must opt in.** Start MJAPI with `ACTIVITY_SYNC_SANDBOX_DIR` set to the absolute path of
  `packages/IntegrationTests/sandbox`. On any other host a `sandbox:` connection is refused (never
  looked up as a credential), and a host that also allows live mailbox fetch refuses to start.
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
- **Fixtures are generated** by `node sandbox/build-fixtures.mjs` from the ActivitySync demo Graph
  payloads; `src/__tests__/sandbox-fixtures.test.ts` checks the committed files match. Calendar
  shapes were never compared with live Graph data; the files say so.

## Rules

1. Use `ctx.Provider.GetEntityObject<TypedEntity>(...)` and typed properties — never `.Get()` / `.Set()`.
2. Lookups go through `RunView.FromMetadataProvider(ctx.Provider)` — never `ctx.Pool`.
3. Compare IDs with `SameID` (SQL Server uppercases GUIDs).
4. A refused save must assert the refusal (`Assert(!saved)`), not only that something failed.
