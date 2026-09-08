# @mj-biz-apps/common-activity-sync

## 5.40.0

### Minor Changes

- de47552: Activity Sync — an exclusion could not be switched off, and one dated to lapse never lapsed.

  `ActivitySyncExclusion` carries `IsEnabled`, `EffectiveFrom` and `EffectiveTo`. The qualification
  cascade read none of the three. Same shape as the `CredentialsRef` and `InternalDomains` gaps:
  columns written, migrated, documented, and consumed by nothing.

  Two independent failures, both silent:

  | set by an operator            | intended                    | what actually happened                |
  | ----------------------------- | --------------------------- | ------------------------------------- |
  | `IsEnabled = 0`               | stop excluding this address | kept excluding, indefinitely          |
  | `EffectiveTo` in the past     | the exclusion lapses        | never lapsed                          |
  | `EffectiveFrom` in the future | starts excluding later      | excluded from the moment it was saved |

  None of it is visible from the outside. The run reports success, `ActivitySyncRunDetail` records the
  exclusion as matched, and the only symptom is mail that quietly never arrives — typically noticed
  months after whoever set the date stopped watching for it. Rules honoured their own `IsEnabled` from
  the first commit, so the two halves of one cascade disagreed about whether an off switch meant
  anything.

  **The window is matched against the item, not the wall clock.** `RuleRow.DateFrom`/`DateTo` are
  already compared against `item.StartedAt` one stage later in the same cascade. Had an exclusion's
  window meant "while this record is in force" instead, the same two dates would mean different things
  one stage apart — a trap for whoever writes the second rule set. Item time also keeps a re-run
  reproducible: `ActivitySyncRunDetail` exists to answer "which rule ate my message", and an answer
  that moves with the clock is a narrative rather than evidence.

  **Absence reads as enabled.** A row that does not carry `IsEnabled` still excludes. An exclusion
  exists to stop something being ingested, so the missing-flag case has to fail in the direction that
  keeps it stopped.

  **The check lives in memory, not in `ExclusionsExtraFilter`.** One place decides, matching how rules
  are handled — a SQL half and a TypeScript half would be two places to keep in agreement.

  `ExclusionAppliesTo` is a pure exported function, so the three ways an exclusion can fail to apply
  are testable without standing up a cascade. 16 tests, each mutation-checked (M-AC31–M-AC38): dropping
  either bound, dropping the enabled check, reading absence as off, making either boundary exclusive,
  abandoning the cascade instead of skipping one lapsed row, and judging by run time instead of item
  time are all caught.

- de47552: Activity Sync — deactivating a provider type did nothing, and no test file was ever typechecked.

  `ActivitySyncProviderType.IsActive` had no reader anywhere: not on `ProviderTypeRow`, not in
  `loadProviderType`'s `Fields` list, not in the run path. An administrator switching a connector type
  off changed nothing — every connection pointing at it kept fetching mail and kept reporting success.

  **It refuses rather than skipping quietly.** A connection that stops syncing while still showing
  green is the failure this subsystem exists to make impossible, so an inactive type produces an issue
  naming the type and lands in the connection's health stamp. It follows the shape already set by
  "Connection X is not in its Active window" directly above it. The refusal is taken before any
  provider is resolved and before any fetch, so it cannot be reached only through a driver lookup
  failure, and no mailbox is read on the way to it.

  **What an operator will see when they switch a type off.** Every connection using it reports the
  refusal on the next fleet tick, so each flips to `Status = 'Error'` with the reason in `LastError`.
  That is the existing behaviour for any failed run, not something new here, and it is self-healing:
  errored connections are still selected by the fleet query, so the next successful run after the type
  is reactivated clears `LastError` and returns them to `Active` with no manual step.

  **Absence keeps running.** The comparison is `=== false`, so a row loaded without the field still
  syncs. Absence means the query did not ask for the column, and turning one trimmed `Fields` list into
  a silent total halt of every sync is a worse failure than the one being guarded against. SQL `BIT`
  arrives through `RunView` as a real JS boolean — measured against the database rather than assumed —
  so the strict comparison is safe.

  **The trap that caused it is now a test.** A field declared on `ProviderTypeRow` but absent from the
  `Fields` list is `undefined` at runtime, so any check written against it silently never fires. That
  is exactly how `IsActive` came to be ignored. The existing `SELECT *` tripwire now pins the interface
  and the field list to each other and fails until a new column is added to both.

  **Separately: the test suite was never typechecked.** `tsconfig.json` excludes
  `src/**/__tests__/**` so test files never reach `dist` — correct for a published package — but
  nothing else checked them either, and vitest transpiles through esbuild without typechecking. Six
  errors were sitting in the suite, including a test constructing an `ExclusionRow` missing three
  required fields. A `noEmit` config now covers everything, and `pnpm test` runs it before vitest,
  which is the only hook available: CI runs `build`, `changes` and `publish`, and never the tests.

  11 mutants added to the package harness (M-AC31–M-AC41); all 27 pass.

### Patch Changes

- Updated dependencies [e21b2db]
- Updated dependencies [b4387e4]
- Updated dependencies [dc7693c]
- Updated dependencies [22f6624]
  - @mj-biz-apps/common-entities@5.40.0

## 5.39.0

### Minor Changes

- 8657091: Activity Sync — the MS Graph provider gets an actual transport, and credentials.

  `MSGraphActivitySyncProvider` had none. Both of its `FetchRaw` returns handed back `Payloads: []`,
  one behind an opt-in flag and one behind a "not supported in this build" log — written, typechecked
  and refused. The consequence was not only that live sync did not work: nothing ever exercised the
  path that needs a credential, so the fact that no credential was configured anywhere went unnoticed
  until someone asked for a live demo. A fixture provider that bypasses the Graph path entirely was
  the only thing producing data, and it was green throughout.

  **The transport is now a seam.** `ActivityMessageTransport` isolates the one call that reaches the
  network. `GraphCommunicationTransport` wraps MJ's Communication MS Graph provider and resolves an
  "Azure Service Principal" credential from MJ's Credentials engine per fetch — never held on the
  object, never logged, never interpolated into an issue string, and incomplete credentials are
  refused by FIELD NAME before any call is made. `RecordedMessageTransport` replays captured Graph
  payloads through the same mapper, so a run against recordings exercises everything except the
  network hop rather than standing in for the engine wholesale.

  **`IsLive` now follows the transport** instead of being hard-coded true. The engine refuses to write
  `Source: 'Integration'` rows from a non-live provider, and that guard was worthless while a replayed
  run could claim to be live. `AllowLiveFetch` still defaults false and still refuses live Graph reads
  for the unchanged reason: app-only `Mail.Read` reads every mailbox in the tenant until an Exchange
  Application Access Policy scopes the app registration. A recorded transport is exempt because it
  reaches no mailbox.

  **A message could go missing, and did so silently.** `Normalize` unwrapped a one-element `Payloads`
  array and handed `MapGraphMessages` a bare message object, which matches neither shape it accepts —
  so a mailbox with exactly one new message normalized to nothing and reported a clean, empty,
  successful sync. One message is the most likely size of a real incremental pass. The response
  envelope is now detected by shape rather than inferred from array length.

  **A mutant had been skipping.** `M-AC18`'s anchor carried 12 spaces of indentation against
  `writer.ts`'s 8 — the code was re-indented and the mutant never updated — so "stores a cancelled
  meeting as Cancelled, not Logged" had no proof it could fail. Re-anchored, and `M-AC23`–`M-AC28`
  added for the new behaviour.

  **`CredentialsRef` is finally read.** The column describes itself as an "MJ Credentials engine key.
  NEVER a secret value at rest" — and no code anywhere consumed it, so a connection could name the
  credential it wanted and be silently ignored. Worse than an absent column: the configuration looked
  complete while the provider refused for what appeared to be an unrelated reason. `BaseActivitySyncProvider`
  gains a `Configure` hook (a no-op by default, so every existing provider is untouched), the engine calls
  it with the connection's `CredentialsRef`, `Mailbox` and driver before fetching, and the Graph provider
  resolves a transport from it through a host-supplied factory. Each way of failing now says something
  different — no CredentialsRef, no factory registered, or a factory that served nothing — because each
  has a different fix. A transport passed to the constructor still wins and is never replaced.

  **No date bound is sent yet, deliberately.** The published Communication API has no first-class date
  filter, and the only alternative was `ContextData.Filter`, which silently discarded any other clause.
  MemberJunction/MJ#4123 adds `ReceivedAfter` and fixes that overwrite; until it publishes, the window
  is applied downstream in `Normalize` as before, and a capped read that may have left mail behind now
  reports an issue instead of passing quietly.

  `@memberjunction/communication-types` and `@memberjunction/credentials` are added as peer
  dependencies for their types. Neither is a runtime dependency: both collaborators are injected, so a
  host that syncs only fixtures need install neither.

- b6b2b64: Activity Sync — the transport factory seam is finally reachable, and a host implements it.

  `ActivityTransportFactory` was declared as "how a HOST supplies a transport", exported, documented,
  and reachable **only as the third constructor argument**. `MJGlobal.ClassFactory` builds plugins with
  no arguments, so through `ActivitySyncEngine` — the only path production uses — a factory could never
  arrive. Every test that exercised one passed it to the constructor, which production never does. A
  seam that is exported and unreachable is the same class of defect this package keeps being written
  against, one layer up.

  **A host registry replaces the unreachable parameter.** `RegisterActivityTransportFactory` is called
  once at bootstrap and `Configure` consults it. A transport or factory passed to the CONSTRUCTOR still
  wins, so tests and the demo keep supplying their own and a process-wide registration cannot reach in
  and replace them.

  **`ActivityTransportContext` gains `ContextUser`.** MJ's Credentials engine documents `contextUser` as
  required server-side, so a factory that resolves a credential cannot work without it. It stays
  optional because a factory serving recordings needs no user.

  **`common-server` now implements the factory.** `GraphTransportFactory` turns a connection's
  `CredentialsRef` into a `GraphCommunicationTransport`, resolving the credential through MJ's
  Credentials engine and the provider through `ClassFactory` — including the base-class check copied
  from `CommunicationEngine.GetProvider`, because `CreateInstance` returns a BASE instance when no
  registration matches, so a missing provider otherwise comes back as a truthy object that answers no
  call usefully. It lives in the host rather than in ActivitySync because ActivitySync takes both
  engines as peers deliberately: a host syncing only fixtures should install neither.

  **This enables nothing on its own.** `AllowLiveFetch` still defaults false, so a live read is still
  refused until someone who has confirmed the Exchange Application Access Policy opts in. What ends is
  the state where a correctly configured credential could not be resolved at all.

### Patch Changes

- 7887d5d: License declarations now agree on BUSL-1.1 everywhere.

  `LICENSE`, `package.json`, `mj-app.json` and every workspace package already declared
  BUSL-1.1. Two statements still said ISC: the README badge, which is the first license
  statement a reader meets and so outranked all of them in practice, and the `mj-app.json`
  sample in `docs/open-app.md` — this repo is the reference Open App, so that snippet is
  copied into new repos and is how the wrong value spreads. The badge now links to `LICENSE`.

- Updated dependencies [7887d5d]
  - @mj-biz-apps/common-entities@5.39.0

## 5.38.0

### Patch Changes

- Updated dependencies [4c27078]
- Updated dependencies [4c27078]
  - @mj-biz-apps/common-entities@5.38.0

## 5.37.0

### Minor Changes

- d73a3af: Activity Sync Engine — provider plugin contracts and the provider-type/extension schema.

  Adds `@mj-biz-apps/common-activity-sync` with the `BaseActivitySyncProvider` plugin base class,
  the qualification cascade (deterministic stages first, inference last — enforced, not documented),
  and `BaseActivitySyncExtension`, the in-process contract a downstream app implements to add links
  to an Activity inside its own write transaction.

  Adds a migration turning two things that were code into data: `ActivitySyncProviderType` replaces
  `CK_ActivitySyncConnection_Provider`, so a new source is a plugin package plus a metadata row
  rather than a migration to Common; and `ActivitySyncExtension` registers enrichment plugins that
  consumer apps ship rows for.

  Design: `plans/activity-sync-engine.md`.

- d73a3af: Activity Sync Engine P4/P5 — engine, writer, identity resolver, fixture and Graph providers.

  Graph refuses live fetch until an Exchange Application Access Policy exists. Synced
  activities are Visibility=Private. Unmatched addresses become unresolved ActivityLinks.
  Dry runs never set WatermarkAfter. Exclusions run first and are absolute.

- d73a3af: Entity Action workflow adoption — the Common side (plans/mj-entity-action-workflow-adoption.md).

  `Common.LogActivity` is the declarative entry point to the unified timeline: a thin action over the
  new `ActivityWriter.WriteManual`, the second entry point on the ONE writer (manual defaults —
  Visibility Internal, no connection, no sync-extension dispatch; same transactional core, dedupe and
  link writing as the sync path). Takes only serializable params ('Entity Object Data', never
  'Entity Object'), with EventKey per-record idempotency and LinkFields declarative link routing.

  Ships the §5 bindings as metadata: People·AfterCreate → LogActivity, People·AfterUpdate (Status
  changed) → the Person Lifecycle Changed flow agent, Organizations·AfterUpdate scoped to an
  OrganizationType, Relationships·AfterCreate/ended scoped to the Employee RelationshipType — all
  RunMode Durable, all Status Active at every level. Two reusable ActionFilter rows (MJ ships no
  seeds — verified) and the SystemEvent activity type.

- d73a3af: Activity sync trigger, calendar companion as data, and per-connection health.

  Seeds Common.SyncActivities (Action, Limit, result codes, hourly job) as JSON.
  CalendarDriverClass on ActivitySyncProviderType drives the companion surface through
  ClassFactory. Connection health is stamped once from combined surfaces. A failed
  connection list load is ERROR, not NO_CONNECTIONS.

### Patch Changes

- Updated dependencies [d73a3af]
- Updated dependencies [d73a3af]
- Updated dependencies [d73a3af]
  - @mj-biz-apps/common-entities@5.37.0
