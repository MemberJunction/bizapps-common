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

## Rules

1. Use `ctx.Provider.GetEntityObject<TypedEntity>(...)` and typed properties — never `.Get()` / `.Set()`.
2. Lookups go through `RunView.FromMetadataProvider(ctx.Provider)` — never `ctx.Pool`.
3. Compare IDs with `SameID` (SQL Server uppercases GUIDs).
4. A refused save must assert the refusal (`Assert(!saved)`), not only that something failed.
