# Epic 1b Specification: Limits Sweep & Runaway Guard Resolution (`MemberJunction/bizapps-common`)

## 1. Scope & Repository Inventory Confirmation

This specification documents Slices 1 & 2 of **Epic 1b — Limits Sweep & Runaway Guard Resolution** for `MemberJunction/bizapps-common`.

### Repository Package Inventory
`MemberJunction/bizapps-common` is a multi-package Open App monorepo containing **7 workspace packages** plus **repo maintenance scripts**:

| Directory | Package Name | Purpose | Limits Resolver Module |
|---|---|---|---|
| `packages/Angular` | `@mj-biz-apps/common-ng` | Angular form panels, identity headers, lookup fields, directory/activity pages | `packages/Angular/src/lib/config/limits.config.ts` |
| `packages/ActivitySync` | `@mj-biz-apps/common-activity-sync` | Email/calendar activity sync engine, consent intake, Graph transports | `packages/ActivitySync/src/limits.config.ts` |
| `packages/CoreEntitiesServer` | `@mj-biz-apps/common-core-entities-server` | Server entity subclasses & entity guards | *(Single-row `MaxRows: 1` lookups only)* |
| `packages/Entities` | `@mj-biz-apps/common-entities` | Generated entity subclasses, business-day engine, reporting-chain validation | `packages/Entities/src/limits.config.ts` |
| `packages/Actions` | `@mj-biz-apps/common-actions` | Generated action subclasses | *(Generated code only)* |
| `packages/Server` | `@mj-biz-apps/common-server` | Server bootstrap & custom actions (`SyncActivitiesAction`, `GetPartySignalsAction`, etc.) | `packages/Server/src/custom/limits.config.ts` |
| `packages/IntegrationTests` | `@mj-biz-apps/common-integration-tests` | Live-database integration test harness & sandbox sync checks | *(Local `// ResourceGuard:` annotation)* |
| `scripts/` | *(unpacked repo tools)* | CI release/token/UUID comparison guards | *(Subprocess `maxBuffer` / scan bounds)* |

Both `packages/Angular/src` and all sibling packages/scripts were mechanically swept and cataloged in [`.mj/specs/epic-1b-limits-sweep-bizapps-common.csv`](./epic-1b-limits-sweep-bizapps-common.csv).

---

## 2. Sweep Methodology

1. **TypeScript AST Scan**: Walked all non-generated, non-test source files (`*.ts`, `*.js`, `*.mjs`, `*.cjs`) across `packages/` and `scripts/`, excluding `node_modules/`, `dist/`, `generated/`, `__tests__/`, `*.test.*`, and `*.spec.*`.
2. **Cross-Check with Canonical MJ Sweeper**: Executed MJ's canonical `sweep-limits-literals.mjs` AST classifier as a baseline (159 files scanned, **0 unapproved `RunawayGuard` hits**), then broadened the scan to capture unnamed `RunView` `MaxRows`, slice/truncation caps, timeouts, debounces, sentiment thresholds, and CSS layout/media breakpoints.
3. **Explicit Exclusions**:
   - Trivial index/offset sentinels (`0`, `1`, `-1`) in array indexing, sort comparators, and length-empty checks (retained only when used as a bounding cap such as `MaxRows: 1`).
   - Mathematical unit-conversion multipliers (`1000 * 60` ms/min, `60` min/hr, `* 100` percentage scaling) and calendar math (`12` months, `3` months/quarter, `padStart(4, '0')`).
   - Static presentation metadata (panel `sortKey`, grid column `orderIndex` / `width` definitions in `directory-views.ts`).
   - CodeGen-generated entity/action files under `**/generated/**` and test fixtures under `**/__tests__/**`.

---

## 3. Classification Summary

Every discovered bounding numeric literal is classified into one of the five canonical Epic 1 categories:

| Category | `packages/Angular` Hits | Other Packages & `scripts/` Hits | Total Hits | Slice 2 Resolution Status |
|---|---:|---:|---:|---|
| **`RunawayGuard`** | **0** | **0** | **0** | **Zero hits repository-wide.** Explicit `RunawayGuards` schema anchors (`ZeroHitsConfirmed: true`) exposed & unit-tested across all 4 resolver modules. |
| **`ResourceGuard`** | 5 | 9 | 14 | 5 Angular + 7 Entities/ActivitySync guards routed through typed resolvers with finite bounds & upper-ceiling clamping; 1 test wait guard annotated `// ResourceGuard:`; 3 script/buffer bounds retained (`NoChange`). |
| **`ProtocolLimit`** | **0** | 5 | 5 | **Zero hits in `packages/Angular`.** All 5 sites in `packages/ActivitySync` (`SWEEP_WIDE_PAGE`, `MIN_SWEEP_WINDOW_MS`, `MIN_MAIL_WINDOW_MS`, `writer.ts` `Activity.Title` slices) annotated with inline `// ProtocolLimit:` comments. |
| **`UX`** | 29 | 1 | 30 | 3 configurable Angular UX bounds (`PartySearchDebounceMs`, `PartyLookupMinTermLength`, `DirectoryLatestTakeCount`) routed through `ResolveCommonAngularLimits()`; 10 local thresholds annotated `// UX:`; 17 CSS/layout/single-row sites retained (`NoChange`). |
| **`Tuning`** | 5 | 16 | 21 | 5 Angular + 7 ActivitySync + 1 Server tuning constants routed through typed resolvers; 8 single-row `MaxRows: 1` lookup caps retained (`NoChange`). |
| **Total** | **39** | **31** | **70** | **All 70 classified bounding literals accounted for and verified.** |

*(Note: In Slice 2, `LoadDirectorySnapshot` has 3 `MaxRows: 1000` `ResourceGuard` bounds — People, Organizations, Relationships — and 5 `Tuning` bounds in `packages/Angular`, plus 2 `UX` `LatestByCreated`/`PartyLookupMinTermLength`/`DEBOUNCE_MS` bounds routed to `limits.config.ts`.)*

### Explicit Zero-Hit Category Documentation
- **`RunawayGuard` (`0` hits repo-wide)**: `bizapps-common` is a business-entity, activity-sync, and Angular UI library; it does not host agent prompt loops, channel turn guards, or task-graph executors. Every typed limits resolver (`@mj-biz-apps/common-ng`, `@mj-biz-apps/common-activity-sync`, `@mj-biz-apps/common-entities`, `@mj-biz-apps/common-server`) exposes explicit `RunawayGuards` schema fields (`ZeroHitsConfirmed: true`, `ActiveGuardCount: 0` in Angular) and unit tests confirming 0 unapproved `RunawayGuard` literals.
- **`ProtocolLimit` (`0` hits in `packages/Angular`, `5` hits in `packages/ActivitySync`)**: No Angular source file encodes wire-protocol or schema-width constants. All 5 `ProtocolLimit` constants live in `packages/ActivitySync` (`consent-intake.ts`, `GraphCommunicationTransport.ts`, `writer.ts`) and carry inline `// ProtocolLimit:` rationale comments.

---

## 4. Typed Limits Configuration Resolvers (Slice 2)

While `@memberjunction/core` (`LimitsConfigResolver`) governs MJ core AI/agent/workflow limits (`AgentChannelConsecutiveTurns`, `Budgets`, `ProgressDetector`, etc.) and is linked on `next`, `bizapps-common` must also compile cleanly against published `@memberjunction/core` releases and govern domain-specific `bizapps-common` limits across browser and server packages. Each affected package therefore exposes a zero-`any`, zero-`unknown`, browser-safe typed limits resolver with finite/integer bounds validation, upper-ceiling clamping, and runtime override support:

1. **`packages/Angular/src/lib/config/limits.config.ts`** (exported from `@mj-biz-apps/common-ng` `public-api.ts`):
   - `COMMON_ANGULAR_LIMITS_CONFIG` (`InjectionToken<CommonAngularLimitsOverride>`), `DEFAULT_COMMON_ANGULAR_LIMITS`, `COMMON_ANGULAR_LIMITS_BOUNDS`, `RegisterCommonAngularLimits`, `ResetCommonAngularLimits`, `ResolveCommonAngularLimits`, `ResolveCommonAngularLimitsWithProvenance`.
   - Browser-safe (zero `process.env` access). Wired into `PartyFieldComponent`, `PartyLookupParamsFor`, `SellingCompanyFieldComponent`, `CommonRelationshipGraphComponent`, `directory-queries.ts`, `directory-stats.ts`, and `CommonActivitiesPageComponent`.
   - Non-goal respected: `packages/Angular/src/lib/components/dashboard-filter-bar/dashboard-filter-bar.component.ts` was left untouched.
2. **`packages/ActivitySync/src/limits.config.ts`** (exported from `@mj-biz-apps/common-activity-sync`):
   - `DEFAULT_ACTIVITY_SYNC_LIMITS`, `ACTIVITY_SYNC_LIMITS_BOUNDS`, `RegisterActivitySyncLimits`, `ResetActivitySyncLimits`, `ResolveActivitySyncLimits`.
   - Wired into `ActivitySyncEngine.ts`, `consent-intake.ts`, `consent.ts`, `GraphCalendarTransport.ts`, `GraphCommunicationTransport.ts`, and `writer.ts` while preserving existing exported constant names for backward compatibility.
3. **`packages/Entities/src/limits.config.ts`** (exported from `@mj-biz-apps/common-entities`):
   - `DEFAULT_COMMON_ENTITIES_LIMITS`, `COMMON_ENTITIES_LIMITS_BOUNDS`, `RegisterCommonEntitiesLimits`, `ResetCommonEntitiesLimits`, `ResolveCommonEntitiesLimits`.
   - Wired into `PersonEntity.ts` supervisor reporting-chain traversal (`MaxReportingChainDepth`).
4. **`packages/Server/src/custom/limits.config.ts`** (exported from `@mj-biz-apps/common-server`):
   - `DEFAULT_SERVER_LIMITS`, `SERVER_LIMITS_BOUNDS`, `RegisterServerLimits`, `ResetServerLimits`, `ResolveServerLimits`.
   - Wired into `sync-activities.action.ts` (`SyncActivitiesDefaultLimit`).

---

## 5. CI Workflow & Verification

An active GitHub Actions CI workflow at [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) targets branch `next` on both `push` and `pull_request` events (`opened`, `synchronize`, `reopened`, `ready_for_review`), with `concurrency` (`cancel-in-progress: true`) and job `timeout-minutes` bounds (`15` for static gates, `20` for build & tests):
- **`ci: static-gates`**: Enforces zero explicit `: any` / `as any` / `<any>` in hand-written TypeScript code (stripping comments before matching), runs `scripts/check-uuid-comparisons.mjs` + its self-test, and validates `.mj/specs/epic-1b-limits-sweep-bizapps-common.csv` & `.md`.
- **`ci: build-and-test`**: Installs the joined `MJ next` workspace via `./.github/actions/ci-install` and runs `pnpm run build:packages` and `pnpm run test`.
- **Verification Suites**:
  - `packages/Angular/src/__tests__/limits-config.spec.ts` & `limits-sweep-report.spec.ts`
  - `packages/ActivitySync/src/__tests__/limits-config.test.ts`
  - `packages/Entities/src/__tests__/limits-config.test.ts`
  - `packages/Server/src/__tests__/limits-config.test.ts`
  - OpenApp readiness verification (`ART-4`) and headless Chromium Playwright component harness smoke test with 0 `pageErrors` and 0 `consoleErrors` (`ART-5`).
