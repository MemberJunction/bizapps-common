# Activity Sync replay sandbox — design

Date: 2026-11-12 · Status: draft for review · Scope: bizapps-common only

## 1. Intent and why

Activity Sync has never run end to end. Unit tests prove each part on its own: participant
classification (`participants.test.ts`), loading `InternalDomains` (`internal-domains.test.ts`,
`engine.internal-domains.test.ts`), the Graph mapper, the recorded transport. Nothing pushes one
fake email through `Common.SyncActivities` → engine → rules → database and checks the outcome.
`demo/run-demo.mjs` calls `provider.Fetch` only — no rules, no writes. PR #415 states "Not run: the
integration suite or a live mailbox." Go-live issue bc-aidp-next-golive#459 says nothing has ever
been synced from a live mailbox.

We want the equivalent of **Stripe test mode** for developers: the same front door (the real action
over GraphQL on a running MJAPI), with a "test key" that makes the source fake Microsoft Graph data
instead of a real tenant. Then a hard smoke-test suite over it, so the rule set we will configure for
PROD (internal domains, exclude-all-internal, exclusions) is proven before the first live dry run.

Users: developers and CI only. Not business users.

## 2. Goals, non-goals, anti-goals

Goals
- Run the **real** `Common.SyncActivities` action, through `GraphQLDataProvider` → MJAPI, against
  connections of the **real** `Microsoft365` provider type, with mail and calendar items served from
  fixture files.
- Assert per-item decisions (`ActivitySyncRunDetail`), written Activities and links, run counts,
  watermark and re-run behavior, for every rule case in §6.
- No behavior change for any host that does not opt in, except one: a `sandbox:` credential ref is
  refused instead of looked up (§5.1).

Non-goals
- Proving Microsoft auth, the Exchange Application Access Policy, or real Graph payload shapes. That
  is Level 2 (a test tenant), out of scope.
- The deal link. `DealLinkerExtension` is in bizapps-sales; Common must stay consumer-blind. A
  separate small check in bizapps-sales can follow.
- A sandbox mode for business users, a UI, or a reset button.
- Real paging in the recorded transport (its own comment names this as a separate change).

Anti-goals (a failure even if it "works")
- Any path where a production MJAPI could serve fake mail, or where a sandbox run could be mistaken
  for a live one in the database.
- A fake that agrees with our mapper rather than with Microsoft (hand-edited shapes that drift from
  the Graph `message` / `event` schema).
- Silent success: a missing fixture, an unknown scenario or a disabled sandbox must fail loudly.

## 3. How it works today (the parts this touches)

- `packages/Server/src/index.ts` bootstrap calls `LoadGraphTransportFactory()` and
  `LoadLiveMailboxPolicyFromEnv()`.
- `packages/Server/src/custom/graph-transport-factory.ts` `GraphTransportFactory(context)` dispatches
  on `context.DriverClass` (`Microsoft365` / `Microsoft365.Calendar`) and builds a live Graph
  transport from `context.CredentialsRef`. Returns null for other drivers or an empty ref.
- `packages/Server/src/custom/live-mailbox-policy.ts` is the precedent for an env-var opt-in that is
  all-or-nothing and throws at bootstrap when half-configured.
- `RecordedMessageTransport` (`ActivitySync/src/providers/`) replays verbatim Graph `value` entries
  per mailbox, `IsLive = false`, throws on an unknown mailbox, and is accepted by both
  `MSGraphActivitySyncProvider` and `MSGraphCalendarSyncProvider`.
- The engine writes `Source = 'System'` for a non-live plugin (`ActivitySyncEngine.ts:643`), so
  sandbox rows are distinguishable from live (`'Integration'`).
- The `Microsoft365` provider type is seeded in `metadata/activity-sync-provider-types/`
  (`DefaultQualificationPolicy = Exclude`, `CalendarDriverClass = Microsoft365.Calendar`).
- `packages/IntegrationTests` runs client-side checks over GraphQL against a running MJAPI; the
  COM-WORLD fixture (`common-world.CW1`) upserts people on `@com-world.test` with primary email
  ContactMethods. Rows are idempotent, not rolled back.

## 4. Approaches

| | Approach | Proves | Costs |
|---|---|---|---|
| **A (chosen)** | Over the wire: checks call the real action via GraphQL; the server factory serves fixtures when an env opt-in is set and the connection's `CredentialsRef` names a sandbox scenario | Real entry point (#415 inputs, auth), engine, rules, writes, `System` marking, re-runs | A small, gated branch in production server code; needs a private MJAPI running |
| B | In-process vitest with a direct SQL provider calling the engine | Engine, rules, writes; no production change; faster | Skips the action and GraphQL layer — the path a real run takes |
| Dropped | Engine over an in-memory fake data provider | Fast | Does not prove database writes |

Soham picked **A** on 2026-11-12: it tests the real front door, and the risky part is small and off
by default.

## 5. Design (decided)

### 5.1 Server: sandbox opt-in (`packages/Server`)

- New `custom/activity-sync-sandbox.ts`, loaded from the bootstrap **after**
  `LoadGraphTransportFactory()` and `LoadLiveMailboxPolicyFromEnv()`.
- Opt-in env var: `ACTIVITY_SYNC_SANDBOX_DIR` = absolute path to a fixture directory.
- **One always-on change, on every host** (builder check, Q1): a `CredentialsRef` that starts with
  `sandbox:` is **never** treated as a credential name. Today `GraphTransportFactory` would look up a
  credential literally named `sandbox:x` (`graph-transport-factory.ts:53-90`). With the opt-in off,
  such a ref gets a transport that **throws at `Fetch`** with a specific message ("sandbox connection
  on a host without ACTIVITY_SYNC_SANDBOX_DIR"). Throwing at `Fetch`, not in the factory, is
  deliberate: a factory throw escapes `Configure` and `Run` up to the action's catch, so no
  `ActivitySyncRun` is saved and the other connections in the call do not run; a `Fetch` throw goes
  through `failClosed` and is recorded as a failed run (`ActivitySyncEngine.ts:456-466`). For every
  ref that does not start with `sandbox:`, behavior is unchanged. This is the part to describe to
  security review #390.
- **Gated by the opt-in**: for `Microsoft365` / `Microsoft365.Calendar` connections whose ref starts
  with `sandbox:`, return a `RecordedMessageTransport` built from
  `<dir>/<scenario>.mail.json` (primary pass) or `<dir>/<scenario>.calendar.json` (calendar pass).
  Everything else falls through to `GraphTransportFactory` unchanged.
- Safety rules (each one tested):
  1. **Sandbox and live are mutually exclusive.** If the sandbox env var is set and the live-mailbox
     policy is also enabled, bootstrap throws. A host is either a sandbox or can read real mail,
     never both.
  2. Directory must exist and be readable at bootstrap, else throw (half-configured = loud).
  3. Scenario name must match `^[a-z0-9-]+$`. Anything else fails at `Fetch` — no path traversal.
  4. A `sandbox:` ref when the opt-in is off: the refusal above, never a credential lookup.
  5. A missing scenario file fails at `Fetch` with the expected path in the message. Every scenario
     therefore ships **both** files; a surface with nothing to test uses an empty `value: []`
     (builder check, Q2).
  6. Bootstrap logs one line when sandbox mode is on, naming the directory.
- The transport stays `IsLive = false`, so the engine writes `Source = 'System'` and the existing
  live gate is not involved.

### 5.2 Fixtures (`packages/IntegrationTests/sandbox/`)

- One scenario = a mail file **and** a calendar file (either may have an empty `value`), in the same
  envelope as `demo/graph-sample-*.json` (`mailbox`, `capturedAt`, `value`, `$comment` provenance).
  The engine always runs both surfaces for a `Microsoft365` connection, because the type has a
  `CalendarDriverClass` (`ActivitySyncEngine.ts:806-846`).
- Shapes are copied from the existing demo files; only addresses, ids, subjects and times change.
  The message shapes were checked field-by-field against 25 live payloads on 2026-09-04 (per that
  file's `$comment`). The **event shapes were never checked against live data** (per
  `graph-sample-events.json`'s `$comment`). Calendar items 11–15 therefore prove the pipeline's
  decisions, not Microsoft's shapes; each calendar file's `$comment` says so. Level 2 (real capture)
  replaces them (builder check, Q5).
- Address plan:
  - Internal (our company): `@sandbox-internal.test`. The sandbox mailbox owner lives here.
  - Known customers: COM-WORLD people on `@com-world.test` (they have ContactMethods, so the
    known-participant stage matches them).
  - Unknown external: `@stranger.test`.
  - Excluded (HR-style): one fixed address on `@sandbox-internal.test` and one external address.
- Each item carries its expected decision in the scenario's `$comment` table, and the check holds
  the same table as code (second opinion, per the repo's existing pattern).

### 5.3 Check bundle (`packages/IntegrationTests/src/checks/activity-sync.checks.ts`)

- Setup per check: a rule set (`InternalDomains = ["sandbox-internal.test"]`), rules, exclusions, a
  binding, and **one** connection on the `Microsoft365` provider type with
  `CredentialsRef = "sandbox:<scenario>"`; that one connection runs both the mail and the calendar
  pass. Names carry a run stamp, like `activities.checks.ts` A5.
- **The rule set is a baseline, not the PROD rule set** (builder check, Q3). The PROD set is not
  defined yet; it is #459 step 3 (internal domains from IT, confirmed by Johanna, authored with JB
  and JS). The baseline: exclusions → `Exclude` + `AllInternal` → known-participant match →
  `DefaultQualificationPolicy = Exclude`, with no `Include` rules. Item 3 (mixed thread) is
  `Included` through the known-participant stage, because the customer is a COM-WORLD person with a
  ContactMethod (`stages.ts:106-192`). When the PROD set exists, add it as a second rule-set fixture
  and run the same catalog against it.
- **Lifecycle** (builder check, Q4). The seeded hourly job (`metadata/scheduled-jobs/`) runs every
  Active or Error connection. So each check creates its connection **Paused**, sets it **Active**
  only for a live run, and sets it **Disabled** in a `finally` (Disabled is never run). Sandbox
  Activities (`Source = 'System'`) stay in the private database; they are linked only to COM-WORLD
  people and are found by the run stamp. A check started in the first minute of an hour can still
  race the job; the harness waits until minute 1 if it is in minute 0.
- Calls `Common.SyncActivities` over GraphQL with `ConnectionIDs` = only this check's connection, so
  checks never touch other rows.
- Reads back `ActivitySyncRun`, `ActivitySyncRunDetail`, Activities and ActivityLinks and compares
  them with the expected table.

## 6. Smoke-test catalog

Rules and decisions
1. Rep → known customer: `Included`, Activity written, linked to the Person/Organization.
2. Rep → colleague only: `Excluded` by the `Exclude` + `AllInternal` rule; the detail names the rule.
3. Rep → customer, CC colleague (mixed): `Included`.
4. Email to an excluded address: `Excluded` by the exclusion, even when an `Include` rule also matches
   (exclusions are absolute and first).
5. Unknown external sender, no matching rule: `Excluded` (fail closed, `DefaultQualificationPolicy`).
6. Malformed / domain-less address on an otherwise internal thread: not treated as internal-only.
7. Address case and leading `@` in `InternalDomains` (`SANDBOX-INTERNAL.TEST`, `@sandbox-internal.test`).
8. Subdomain is not internal (`mail.sandbox-internal.test` counts as external): pins exact matching.
9. Empty `InternalDomains`: `AllInternal` never matches.
10. Unparseable `InternalDomains` JSON: the run fails, not "no domains".

Calendar
11. External meeting → Meeting activity keyed by the Graph event id.
12. Recurring occurrence threads to its series and keeps its own start.
13. Cancelled meeting carries `Cancelled`.
14. All-internal meeting excluded.
15. Naive local time with a named non-UTC zone is skipped with an issue, never guessed.

Run behavior
16. Dry run: `WouldInclude` / `WouldExclude` details, zero Activities, watermark unchanged.
17. Dry run includes a `Paused` connection; a live run does not.
18. Live run, then identical re-run: no duplicates; counts show duplicates or nothing fetched.
19. Watermark: a second scenario file with newer items syncs only the new ones.
20. `ConnectionIDs` filter: an unrelated sandbox connection is not run; a named-but-missing ID
    produces an `Issues` line.
21. Written rows have `Source = 'System'`.
22. Limit binds (recording longer than `Limit`): watermark withheld, issue reported.

Safety (the gate)
23. `sandbox:` ref with the opt-in off: specific refusal, run recorded as failed.
24. Unknown scenario name: loud failure naming the expected file.
25. Scenario name with `../`: refused.
26. Sandbox env + live policy both set: bootstrap throws (unit test in `packages/Server`).
27. Non-sandbox `Microsoft365` connection on a sandbox host: falls through to the normal factory
    (and is refused there for lack of a live policy).

Safety items 23–27 also get unit tests in `packages/Server/src/__tests__/` so they run without a
database.

## 7. Constraints

- Repo rules in `CLAUDE.md`: no `any`, `contextUser` everywhere, no `RunView` in a loop, never swallow
  errors, `BaseSingleton` for singletons, no re-exports between packages.
- One database per agent: a private database and a second MJAPI on its own port (the recipe in the
  developer's notes; `test:integration` from the root is broken — bizapps-common#286).
- No migration and no new metadata expected. If one turns out to be needed, it needs a `minor`
  changeset written by Soham.
- Security review PR #390 is open on the sync entry points; this change must be described to it.

## 8. Calls made by the designer (check these)

- §5.1: the `sandbox:` refusal is always on; fixture serving is gated. Failures happen at `Fetch`.
- §5.2: every scenario ships both surface files; missing file = loud failure.
- §5.2: calendar fixtures stay in scope, labelled "shape not live-checked".
- §5.3: the suite tests a baseline rule set until the PROD set is defined.
- §5.3: lifecycle Paused → Active (live run only) → Disabled in `finally`; no row deletion.

Changed during the build (measured, 2026-11-12):

- **Run tag.** The ref is `sandbox:<scenario>[:<tag>]`; a tag is appended to each item's `id`,
  `seriesMasterId` and `conversationId`. The engine dedupes on `SourceSystem` + `ExternalID`, and
  `SourceSystem` is the provider type code (`Microsoft365`) for every mailbox, so a second suite run
  over fixed fixture ids wrote nothing. Real Graph ids are unique per mailbox, so this has no live
  counterpart. Same validation as the scenario name.
- **Case 6 is not reachable on the Graph path.** `GraphMessageMapper` drops a domain-less address
  (with an issue) before participant classification, so a colleagues-plus-malformed thread reaches
  the rules as colleagues-only and the AllInternal rule excludes it. The check pins that measured
  behaviour; whether it is wanted is a question for the engine owner.
- **One call writes two runs** per Microsoft365 connection (mail pass, calendar pass); checks read
  every run the call created, not the newest.
- **Action params are strings** over GraphQL (`RunAction` types `Value` as String).

## 9. Left to the builder

- Exact module and function names, and how the wrapper composes with `GraphTransportFactory`
  (wrap vs. second registration), as long as §5.1's rules hold.
- How many scenario files to split the catalog into.
- Whether checks share one scenario per bundle or one per check.
- How the integration harness is started for this bundle given #286 (document the command in the
  package README).
