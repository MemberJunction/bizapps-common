# Activity Sync Replay Sandbox Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run the real `Common.SyncActivities` action over GraphQL against `Microsoft365` connections whose mail and calendar come from fixture files, and prove the 27-case catalog.

**Architecture:** `common-server` gains one module that wraps the registered transport factory: a `sandbox:` CredentialsRef is always intercepted (refused when the opt-in is off, served from `ACTIVITY_SYNC_SANDBOX_DIR` when it is on). `IntegrationTests` gains fixture files and an `activity-sync` check bundle that creates rule sets and connections, calls the action through `GraphQLActionClient`, and reads back runs, details and activities.

**Tech Stack:** TypeScript, vitest (unit), `@memberjunction/testing-integration` (wire checks), MJAPI from `../MJ`, SQL Server.

**Spec:** `docs/superpowers/specs/2026-11-12-activity-sync-sandbox-design.md`

## Global Constraints

- Env var name: `ACTIVITY_SYNC_SANDBOX_DIR`. Ref prefix: `sandbox:`. Scenario name regex: `^[a-z0-9-]+$`.
- Fixture files: `<dir>/<scenario>.mail.json`, `<dir>/<scenario>.calendar.json`; envelope `{ $comment, mailbox, capturedAt, value }`.
- Internal domain `sandbox-internal.test`; mailbox `rep@sandbox-internal.test`; customers are COM-WORLD people (`nora.calhoun@com-world.test`, `ada.lovelace@com-world.test`); unknown external `@stranger.test`.
- Action: `Sync Activities`, ID `B2CAEFB7-60FD-41FF-8B12-DB908A7BEF0E`, params `DryRun`, `ConnectionIDs`, `Limit`.
- Repo rules: no `any`; never swallow errors; `contextUser` on every server call; no `RunView` in a loop; no re-exports between packages.
- **No commits by the agent** (repo CLAUDE.md rule 1). "Commit" steps below mean: stop and leave the change for Soham to stage and commit.
- No migration, no metadata change.

## Review Focus

1. Opt-in off + `sandbox:` ref → run recorded **Failed** with the specific message, never a credential lookup → Task 1 test `refuses a sandbox ref when the opt-in is off`.
2. Sandbox env set together with the live mailbox policy → bootstrap throws → Task 1 test `refuses to start with both sandbox and live policy`.
3. A non-`sandbox:` ref on a sandbox host reaches the inner factory unchanged → Task 1 test `passes other refs through untouched`.
4. Fixture `mailbox` differs from the connection's `Mailbox` → the recorded transport throws, run Failed (not "0 fetched, success") → Task 3 check AS-S3.
5. Test connections left Active after a failing check → `finally` sets Disabled → Task 3 helper `WithSandboxConnection`, asserted in AS-R1.

---

### Task 0: Environment spike (scariest unknown first)

Prove a private database + private MJAPI + the wire harness work on this branch before writing feature code.

- [ ] **Step 1:** Create database `MJ_SANDBOX_AS` as `sa` (see memory recipe "private MJAPI for integration tests"); `.env.clean` copies in `../MJ` and outside this repo.
- [ ] **Step 2:** `DOTENV_CONFIG_PATH=<env> pnpm run mj:migrate` in `../MJ`, then here. Expected: both finish with no failed migration.
- [ ] **Step 3:** Build: `pnpm --filter @mj-biz-apps/common-server... run build` and `pnpm --filter @mj-biz-apps/common-integration-tests run build`.
- [ ] **Step 4:** Start MJAPI from this repo root on `GRAPHQL_PORT=4391` (memory recipe step 3). Expected: GraphQL listening, `common-server` loaded.
- [ ] **Step 5:** Run `common-world` and `activities` bundles via the #286 workaround. Expected: all pass. If anything fails, stop and report — the rest of the plan depends on this.

### Task 1: Sandbox transport factory (`packages/Server`)

**Files:**
- Create: `packages/Server/src/custom/activity-sync-sandbox.ts`
- Modify: `packages/Server/src/index.ts` (bootstrap: call `LoadActivitySyncSandboxFromEnv()` right after `LoadLiveMailboxPolicyFromEnv()`; add export line)
- Test: `packages/Server/src/__tests__/activity-sync-sandbox.test.ts`

**Interfaces:**
- Consumes: `ActivityTransportFactory`, `ActivityTransportContext`, `ActivityMessageTransport`, `RecordedMessageTransport`, `RegisterActivityTransportFactory`, `HostAllowsLiveMailboxFetch` from `@mj-biz-apps/common-activity-sync`; `GraphTransportFactory` from `./graph-transport-factory.js`.
- Produces:
  - `export const ENV_SANDBOX_DIR = 'ACTIVITY_SYNC_SANDBOX_DIR'`
  - `export const SANDBOX_REF_PREFIX = 'sandbox:'`
  - `export const SANDBOX_DISABLED_REFUSAL: string` (contains `ACTIVITY_SYNC_SANDBOX_DIR`)
  - `export function SandboxAwareTransportFactory(inner: ActivityTransportFactory, sandboxDir: string | null): ActivityTransportFactory`
  - `export function LoadActivitySyncSandboxFromEnv(env?: NodeJS.ProcessEnv): string | null` — returns the resolved dir or null.

Behavior: for `DriverClass` `Microsoft365` / `Microsoft365.Calendar` and a trimmed ref starting with `sandbox:`, return a transport with `IsLive = false` whose `Fetch` (not the factory) does: opt-in off → throw `SANDBOX_DISABLED_REFUSAL`; bad scenario name → throw naming the name; read `<dir>/<scenario>.<mail|calendar>.json` (calendar when `DriverClass === 'Microsoft365.Calendar'`) → missing/unparseable → throw naming the path; else delegate to `new RecordedMessageTransport([{ Mailbox, Payloads: value, Provenance: 'sandbox <file> (capturedAt …)' }]).Fetch(query)`. Every other context goes to `inner`. `LoadActivitySyncSandboxFromEnv`: blank env → register `SandboxAwareTransportFactory(GraphTransportFactory, null)` and return null; set → dir must be an existing readable directory else throw; `HostAllowsLiveMailboxFetch()` true → throw; register with dir, `console.log` one line naming the dir, return it.

- [ ] **Step 1: Write failing tests** (temp dir fixtures via `fs.mkdtempSync`; inner factory is a `vi.fn` returning a stub transport):
  - `refuses a sandbox ref when the opt-in is off` — `Fetch` rejects with `SANDBOX_DISABLED_REFUSAL`; inner not called.
  - `serves the mail file for the primary pass and the calendar file for the calendar pass` — payload ids from each file; `IsLive === false`.
  - `rejects a scenario name with ../` and `rejects uppercase` — `Fetch` rejects, message contains the name.
  - `missing scenario file names the expected path` — rejects with `<dir>/nope.mail.json`.
  - `passes other refs through untouched` — `ref = 'prod-graph'` and `DriverClass = 'Gmail'` both call inner with the same context and return its result.
  - `refuses to start with both sandbox and live policy` — `AllowLiveMailboxFetch(<complete attestation>)` then `LoadActivitySyncSandboxFromEnv({ ACTIVITY_SYNC_SANDBOX_DIR: dir })` throws.
  - `throws when the directory does not exist`; `blank env returns null and still intercepts sandbox refs`.
  - `afterEach`: `AllowLiveMailboxFetch(null)` and `RegisterActivityTransportFactory(null)`.
- [ ] **Step 2:** `cd packages/Server && pnpm exec vitest run src/__tests__/activity-sync-sandbox.test.ts` → FAIL (module missing).
- [ ] **Step 3:** Implement `activity-sync-sandbox.ts` and the bootstrap change.
- [ ] **Step 4:** Same command → PASS; then `pnpm test` and `pnpm run build` in `packages/Server` → all pass, no TS errors.
- [ ] **Step 5:** Stop for Soham to commit (`feat(server): activity-sync sandbox transport`).

### Task 2: Fixtures (`packages/IntegrationTests/sandbox/`)

**Files:**
- Create: `packages/IntegrationTests/sandbox/baseline.mail.json`, `baseline.calendar.json`, `newer.mail.json`, `newer.calendar.json`, `mismatch.mail.json`, `mismatch.calendar.json`, `README.md`
- Modify: `packages/IntegrationTests/package.json` `files` only if the package lists them (it is private; likely no change).

Shapes copied from `packages/ActivitySync/demo/graph-sample-messages.json` / `graph-sample-events.json` with every field kept. `mailbox` = `rep@sandbox-internal.test` (mismatch: `someone-else@sandbox-internal.test`). Each `$comment` holds provenance and the expected-decision table; calendar files say "shape not live-checked".

| id (`value[].id`) | Case | Expected (baseline rule set) |
|---|---|---|
| `sbx-m1-customer` | rep → nora.calhoun | Included, link to Nora |
| `sbx-m2-internal` | rep → colleague@sandbox-internal.test | Excluded by AllInternal rule |
| `sbx-m3-mixed` | rep → ada.lovelace, cc colleague | Included |
| `sbx-m4-hr` | rep → hr@sandbox-internal.test **and** nora | Excluded by exclusion |
| `sbx-m5-stranger` | stranger@stranger.test → rep | Excluded (fail closed) |
| `sbx-m6-malformed` | rep → colleague + `undisclosed-recipients` (no @) | not AllInternal → falls to known-participant → Excluded (no known person) |
| `sbx-m7-subdomain` | rep → x@mail.sandbox-internal.test | not internal → Excluded (no known person) |
| `sbx-e1-external` | meeting with nora | Included, ExternalID = event id |
| `sbx-e2-occurrence` | occurrence with seriesMasterId, with ada | Included, own start, thread = series |
| `sbx-e3-cancelled` | cancelled, with nora | Included, Cancelled |
| `sbx-e4-internal` | colleagues only | Excluded |
| `sbx-e5-naive-tz` | `Pacific Standard Time`, no offset | skipped with an issue |

`newer.*` = baseline items plus `sbx-m8-newer` (rep → nora, newer `receivedDateTime`) and an empty calendar.

- [ ] **Step 1:** Write the files; `node -e` JSON-parse each → no error.
- [ ] **Step 2:** Write a vitest `src/__tests__/sandbox-fixtures.test.ts` in IntegrationTests asserting: every file parses, has `mailbox`, `capturedAt`, `value` array; every id in the table above exists exactly once; no address outside `sandbox-internal.test`, `com-world.test`, `stranger.test` (plus the documented malformed token).
- [ ] **Step 3:** `cd packages/IntegrationTests && pnpm test` → PASS.
- [ ] **Step 4:** Stop for Soham to commit.

### Task 3: `activity-sync` check bundle (`packages/IntegrationTests`)

**Files:**
- Create: `packages/IntegrationTests/src/checks/activity-sync.checks.ts`
- Create: `packages/IntegrationTests/src/sandbox-sync.ts` (helpers)
- Modify: `src/entity-names.ts` (add RuleSet, ConnectionRuleSet, Exclusion, Run, RunDetail, ProviderType names), `src/index.ts` (export + bundle doc line), `package.json` (add `@memberjunction/graphql-dataprovider` `^6.2.1`; then `pnpm install` at the workspace parent), `test-harnesses/integration.mjs` (`ALL_BUNDLES` += `activity-sync`), `README.md` (bundle row + how to run with the sandbox MJAPI).

**Interfaces (in `sandbox-sync.ts`):**
- `interface SandboxRuleSetOptions { InternalDomains: string | null; Exclusions?: Array<{ Kind: 'Email' | 'Domain'; Value: string }>; ExcludeAllInternal?: boolean }`
- `CreateSandboxRuleSet(ctx, stamp: string, opts: SandboxRuleSetOptions): Promise<string>` — rule set (`InternalDomains` raw string so case 10 can pass bad JSON), `Exclude` + `AllInternal` rule at Sequence 10 when `ExcludeAllInternal !== false`, exclusions.
- `WithSandboxConnection<T>(ctx, stamp: string, scenario: string, ruleSetIds: string[], fn: (connectionId: string) => Promise<T>, mailbox?: string): Promise<T>` — creates connection (`Provider = 'Microsoft365'`, `ActivitySyncProviderTypeID` = the Microsoft365 type, `CredentialsRef = 'sandbox:' + scenario`, `Mailbox` default `rep@sandbox-internal.test`, `Status = 'Paused'`, `Direction = 'Inbound'`, `OwnerUserID = ctx.User.ID`), binds rule sets, runs `fn`, and in `finally` sets `Status = 'Disabled'` and saves (a failed save throws with context).
- `SetConnectionStatus(ctx, connectionId, status): Promise<void>`
- `RunSync(ctx, connectionIds: string[], opts: { DryRun: boolean; Limit?: number }): Promise<ActionResult>` — `new GraphQLActionClient(ctx.Provider as GraphQLDataProvider).RunAction(SYNC_ACTION_ID, params)`; throws when the action itself fails to execute.
- `ReadRuns(ctx, connectionId)`, `ReadDetails(ctx, runId)`, `ReadActivities(ctx, connectionId)` — one `RunViews` call returning runs + latest run's details + activities (no RunView in a loop).
- `WaitPastTopOfHour(): Promise<void>` — if the UTC minute is 0, wait until minute 1 (bounded: `MAX_WAIT_MS = 70_000`).

**Checks** (each uses a unique stamp, `GetOrLoadWorld` first):
- AS-D1 (items 1–5, 16): baseline, dry run → details `WouldInclude` m1, m3; `WouldExclude` m2 (`ActivitySyncRuleID` = the AllInternal rule), m4 (`ActivitySyncExclusionID` set), m5; zero activities; `LastSyncAt` unchanged.
- AS-D2 (6, 7, 8): rule set `InternalDomains = '["SANDBOX-INTERNAL.TEST"]'` and a second with `'["@sandbox-internal.test"]'` → m2 excluded in both; m6, m7 not decided by the AllInternal rule.
- AS-D3 (9): `InternalDomains = '[]'` → m2 not excluded by the rule.
- AS-D4 (10): `InternalDomains = 'not json'` → run Failed / issue names the rule set.
- AS-C1 (11–15): calendar details in the same baseline dry run: e1, e2, e3 WouldInclude; e4 WouldExclude; e5 absent with an issue naming it. Live run: Meeting activities with `ExternalID` = event id, e3 `Status = 'Cancelled'`.
- AS-R1 (17, 21, 5-focus): Paused connection runs under DryRun; live run with Paused does nothing; set Active, live run → Included activities written with `Source = 'System'`; after the check the connection reads `Disabled`.
- AS-R2 (18): live run twice → second run writes no new activities; activity count unchanged.
- AS-R3 (19): live run on `baseline`, then update `CredentialsRef` to `sandbox:newer`, run → only `sbx-m8-newer` added.
- AS-R4 (20): two connections, `ConnectionIDs` = one → only it has a new run; a random UUID in the list yields an `Issues` line.
- AS-R5 (22): `Limit = 2` → capped issue present, `LastSyncAt` not advanced past the batch.
- AS-S1 (24): `sandbox:does-not-exist` → run Failed, message contains `does-not-exist.mail.json`.
- AS-S2 (25): `sandbox:../etc` → run Failed, message names the scenario.
- AS-S3 (Review focus 4): mismatch scenario → run Failed with "No recorded payloads for mailbox".
- Items 23, 26, 27 are covered by Task 1 unit tests (they need a host without the opt-in or with the live policy).

- [ ] **Step 1:** Add the dependency, entity names and helpers; `pnpm run build` in IntegrationTests → no TS errors.
- [ ] **Step 2:** Write AS-S1 first and run it against the Task 0 MJAPI started **without** the env var → expect failure mode = `SANDBOX_DISABLED_REFUSAL` (proves item 23 on the wire too). Restart MJAPI with `ACTIVITY_SYNC_SANDBOX_DIR=<repo>/packages/IntegrationTests/sandbox`.
- [ ] **Step 3:** Write the remaining checks; run `activity-sync` bundle → every check passes. Fix code, not expectations, unless the expectation contradicts the spec (then stop and report).
- [ ] **Step 4:** Run all bundles once → no regressions.
- [ ] **Step 5:** Stop for Soham to commit.

### Task 4: Wrap-up

- [ ] Run `pnpm test` at the repo root; report pass/fail/skip counts per package.
- [ ] Update `docs/superpowers/specs/...` §8 if any call changed during the build.
- [ ] Fresh reviewer (`adversarial-reviewer`) over the branch diff; fix confirmed findings.
- [ ] Report to Soham: what ran, counts, anything not run, and the commits to make.
