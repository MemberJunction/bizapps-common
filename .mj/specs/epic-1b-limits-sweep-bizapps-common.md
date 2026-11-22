# Epic 1b Specification: Limits Sweep & Runaway Guard Resolution (`MemberJunction/bizapps-common`)

## 1. Scope & Repository Inventory Confirmation

This specification documents Slice 1 of **Epic 1b — Limits Sweep & Runaway Guard Resolution** for `MemberJunction/bizapps-common`.

### Repository Package Inventory
`MemberJunction/bizapps-common` is a multi-package Open App monorepo containing **7 workspace packages** plus **repo maintenance scripts** (rather than `packages/Angular` alone):

| Directory | Package Name | Purpose |
|---|---|---|
| `packages/Angular` | `@mj-biz-apps/common-ng` | Angular form panels, identity headers, lookup fields, directory/activity pages |
| `packages/ActivitySync` | `@mj-biz-apps/common-activity-sync` | Email/calendar activity sync engine, consent intake, Graph transports |
| `packages/CoreEntitiesServer` | `@mj-biz-apps/common-core-entities-server` | Server entity subclasses & entity guards |
| `packages/Entities` | `@mj-biz-apps/common-entities` | Generated entity subclasses, business-day engine, reporting-chain validation |
| `packages/Actions` | `@mj-biz-apps/common-actions` | Generated action subclasses |
| `packages/Server` | `@mj-biz-apps/common-server` | Server bootstrap & custom actions (`SyncActivitiesAction`, `GetPartySignalsAction`, etc.) |
| `packages/IntegrationTests` | `@mj-biz-apps/common-integration-tests` | Live-database integration test harness & sandbox sync checks |
| `scripts/` | *(unpacked repo tools)* | CI release/token/UUID comparison guards |

Both `packages/Angular/src` (the primary UI package targeted by Epic 1b) and all sibling packages/scripts were mechanically swept and cataloged in [`.mj/specs/epic-1b-limits-sweep-bizapps-common.csv`](./epic-1b-limits-sweep-bizapps-common.csv).

---

## 2. Sweep Methodology

1. **TypeScript AST Scan**: Walked all non-generated, non-test source files (`*.ts`, `*.js`, `*.mjs`, `*.cjs`) across `packages/` and `scripts/`, excluding `node_modules/`, `dist/`, `generated/`, `__tests__/`, `*.test.*`, and `*.spec.*`.
2. **Cross-Check with Canonical MJ Sweeper**: Executed MJ's canonical `sweep-limits-literals.mjs` AST classifier as a baseline (159 files scanned, 31 named-bound hits, **0 unapproved `RunawayGuard` hits**), then broadened the scan to capture unnamed `RunView` `MaxRows`, slice/truncation caps, timeouts, debounces, sentiment thresholds, and CSS layout/media breakpoints.
3. **Explicit Exclusions**:
   - Trivial index/offset sentinels (`0`, `1`, `-1`) in array indexing, sort comparators, and length-empty checks (retained only when used as a bounding cap such as `MaxRows: 1`).
   - Mathematical unit-conversion multipliers (`1000 * 60` ms/min, `60` min/hr, `* 100` percentage scaling) and calendar math (`12` months, `3` months/quarter, `padStart(4, '0')`).
   - Static presentation metadata (panel `sortKey`, grid column `orderIndex` / `width` definitions in `directory-views.ts`).
   - CodeGen-generated entity/action files under `**/generated/**` and test fixtures under `**/__tests__/**`.

---

## 3. Classification Summary

Every discovered bounding numeric literal is classified into one of the five canonical Epic 1 categories:

| Category | `packages/Angular` Hits | Other Packages & `scripts/` Hits | Total Hits | Summary |
|---|---:|---:|---:|---|
| **`RunawayGuard`** | **0** | **0** | **0** | **Zero hits repository-wide.** `bizapps-common` contains no AI agent loops, workflow graphs, `While`/`ForEach` loop executors, or briefing contributor runners. |
| **`ResourceGuard`** | 4 | 10 | 14 | Bounded query limits (`COMPANY_LIST_LIMIT = 1000`, directory snapshot `MaxRows: 1000`, `MAX_RUNNABLE_CONNECTIONS = 500`, `MAX_REPORTING_CHAIN_DEPTH = 100`), search timeout (`DEFAULT_SEARCH_TIMEOUT_MS = 20_000`), bounded Graph sweep/page/request caps, and subprocess `maxBuffer` guards. |
| **`ProtocolLimit`** | **0** | 5 | 5 | **Zero hits in `packages/Angular`.** Five hits in `packages/ActivitySync`: MS Graph `$top` ceiling (`SWEEP_WIDE_PAGE = 1000`), MS Graph 1s timestamp precision (`MIN_SWEEP_WINDOW_MS = 1_000`, `MIN_MAIL_WINDOW_MS = 1_000`), and `Activity.Title` DB column truncation bounds (`200`, `500`). |
| **`UX`** | 29 | 1 | 30 | Input debounce (`DEBOUNCE_MS = 250`), min query length (`MIN_TERM_LENGTH = 2`), postal min length (`3`), sentiment thresholds (`0.25` / `-0.25`), content collapse thresholds (`350` chars / `7` lines), clipboard toast (`2000` ms), `LatestByCreated` (`take = 7`), sort fallback sentinels (`999`), CSS responsive breakpoints (`1200px`, `760px`, `720px`), graph canvas/node sizes, and single-row UI lookups (`MaxRows: 1`). |
| **`Tuning`** | 4 | 17 | 21 | Graph edge query caps (`MaxRows: 60`, `30`), directory search caps (`MaxRows: 200`), activities dashboard cap (`MaxRows: 250`), sync lookback/horizon days (`30`), batch sizes (`10`), `BODY_SNIPPET_CHARS` (`500`), `DEFAULT_LIMIT` (`100`), and single-row server lookups (`MaxRows: 1`). |
| **Total** | **37** | **33** | **70** | **70 classified bounding literals across the repository.** |

### Explicit Zero-Hit Category Documentation
- **`RunawayGuard` (`0` hits repo-wide)**: `bizapps-common` is a business-entity, activity-sync, and Angular UI library; it does not host agent prompt loops, channel turn guards, or task-graph executors. In Slice 2, the typed Angular limits configuration resolver will still expose explicit `RunawayGuard` schema fields (with safe defaults / documentation) and unit tests confirming 0 unapproved `RunawayGuard` literals.
- **`ProtocolLimit` (`0` hits in `packages/Angular`, `5` hits in `packages/ActivitySync`)**: No Angular source file encodes wire-protocol or schema-width constants. All 5 `ProtocolLimit` constants live in `packages/ActivitySync` (`consent-intake.ts`, `GraphCommunicationTransport.ts`, `writer.ts`).

---

## 4. CI Workflow Verification

An active GitHub Actions CI workflow has been verified and supplemented with [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) targeting branch `next` on both `push` and `pull_request` events (`opened`, `synchronize`, `reopened`, `ready_for_review`), with explicit `concurrency` (`cancel-in-progress: true`) and job `timeout-minutes` bounds (`15` for static gates, `20` for build & tests):
- **`static-gates`**: Enforces zero `: any` / `as any` / `<any>` across `packages/*/src`, runs `scripts/check-uuid-comparisons.mjs` + its self-test, and validates `.mj/specs/epic-1b-limits-sweep-bizapps-common.csv` & `.md`.
- **`build-and-test`**: Installs the joined `MJ next` workspace via `./.github/actions/ci-install` and runs `pnpm run build:packages` and `pnpm run test`.

---

## 5. Slice 2 Migration & Verification Plan

Slice 2 will execute against the inventory above with zero changes to `dashboard-filter-bar.component.ts` or database migrations:

1. **Typed Browser-Safe Limits Configuration Resolver (`packages/Angular`)**:
   - Introduce `CommonAngularLimitsConfig` + `InjectionToken` + `ResolveCommonAngularLimits()` helper (browser-safe, zero `process.env` access, finite positive bounds validation and ceiling clamping).
   - Route `packages/Angular` `ResourceGuard`, `Tuning`, and configurable `UX` bounds (`DEFAULT_SEARCH_TIMEOUT_MS`, `COMPANY_LIST_LIMIT`, `LoadDirectorySnapshot` `MaxRows`, `SearchPeople` / `SearchOrganizations` `MaxRows`, `LoadGraphData` / `OnHopExpanded` `MaxRows`, `LoadActivities` `MaxRows`, `DEBOUNCE_MS`, `MIN_TERM_LENGTH`, `LatestByCreated` default `take`) through the typed resolver with safe defaults and runtime override support.
   - Document `RunawayGuard` zero-hit status explicitly with unit-tested resolver defaults in `packages/Angular/src/__tests__/limits-config.spec.ts`.
2. **Inline `ProtocolLimit` & Local Annotations**:
   - Add canonical `// ProtocolLimit: ...` inline rationale comments to the 5 `ProtocolLimit` sites in `packages/ActivitySync` (`SWEEP_WIDE_PAGE`, `MIN_SWEEP_WINDOW_MS`, `MIN_MAIL_WINDOW_MS`, `writer.ts` `Activity.Title` slices) and `// UX:` / `// ResourceGuard:` rationale comments where retained locally.
3. **OpenApp Readiness & Headless Playwright Verification**:
   - Run full workspace `build:packages`, `test`, OpenApp readiness checks (`ART-4`), and a headless Chromium Playwright harness under `packages/Angular/**` verifying 0 `pageErrors` and 0 `consoleErrors` (`ART-5`).
