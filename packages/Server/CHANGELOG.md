# @mj-biz-apps/common-server

## 5.43.0

### Minor Changes

- b1e8650: Activity Sync — the calendar surface had no transport, so every calendar fetch returned nothing.

  `MSGraphCalendarSyncProvider` declared a `GraphEventFetcher` seam that **nothing implemented**,
  reachable only as the second constructor argument — and `MJGlobal.ClassFactory` builds plugins with
  no arguments. Through the engine, every calendar fetch returned `Payloads: []` and logged "no
  transport is wired". Exported, documented, typechecked and unreachable: exactly the state the message
  surface was in before its transport landed, one surface over.

  **It rides the same seam as mail rather than a parallel one.** `ActivityMessageTransport` is really
  "fetch raw payloads for a mailbox", which is the calendar contract too, and the host factory now
  dispatches on `DriverClass` to serve both. One connection, one `CredentialsRef`, one credential —
  separate factories would let a connection read mail as one principal and calendar as another.

  **There was nothing to wrap until now.** MJ's `MSGraphProvider` had no calendar API at all, and the
  piece that would make one possible (`getGraphClient`, which owns token acquisition and the
  credential-keyed client cache) is private. Building a Graph client here would have forked precisely
  what `BaseActivitySyncProvider` says to wrap, so calendar retrieval was added to MJ first
  (`GetEvents`) and this wraps it — with the same compile-time assertion the message reader uses, so
  drift in MJ's signature breaks the BUILD rather than the first live call.

  **One attestation, not two.** The same Exchange Application Access Policy scopes `Mail.Read` and
  `Calendars.Read`, so the calendar provider reads the same `AllowLiveMailboxFetch` attestation. A
  second switch would let someone record half a decision and believe they had scoped both.

  **`IsLive` now follows the transport** instead of being hard-coded `true`. The engine refuses to write
  `Source: 'Integration'` rows from a non-live provider, and that guard was worthless while a replayed
  calendar run could claim to be live — the resulting rows would be indistinguishable from real ones.

  **Three things a calendar read can do quietly, now said out loud:**

  - _The window is a rolling lookback and never the watermark._ `/calendarView` refuses an unbounded
    request, so a bound is invented — and an invented bound nobody mentions reads as "we synced your
    calendar" when it means "we synced a month of it". It is said out loud on the first run, where
    somebody expects full history; the same bound applies on every later run.

    An earlier version of this branch passed the watermark as `StartDateTime`, which is a different
    quantity used as if it were the same one. `WatermarkBasisForKind('Calendar')` is `ObservationTime`
    — when we last LOOKED — and `StartDateTime` filters on the EVENT'S own time. So a meeting held
    last week but added to the calendar tomorrow starts before the watermark, falls outside the next
    run's window, and outside every later one, since each starts later still. Never read, on any run,
    no issue, `Success = true`. Retroactive additions and back-dated invitations are ordinary calendar
    behaviour. The same events are now re-read every run, which costs one de-duplication lookup each
    and writes nothing, while a missed event is unrecoverable.

  - _Recurrence may not have been expanded._ A series master and a single occurrence look alike, so
    without this a weekly meeting is filed once, at whatever date the series began, and every
    downstream check still passes.
  - _A capped read_ may have left events in the window.

  Cancelled events are fetched deliberately — `MapGraphEvent` already carries `Cancelled` through, and
  dropping them at the transport would make that field dead code. The window reaches forward as well as
  back, because `Activity.Status` includes `Scheduled`.

  The dead `GraphEventFetcher` interface is removed: nothing implemented it, and keeping an unreachable
  seam is the defect this change exists to end.

  32 tests across the two packages, each mutation-checked — dropping the end bound, silencing the
  lookback notice, discarding cancelled events, reading the normalized `Events` instead of `SourceData`,
  omitting the recurrence warning, turning a Graph failure into an empty batch, hard-coding `IsLive`,
  opening the gate, ignoring the attestation, and refusing to serve the calendar driver are all caught.
  All of them are now REGISTERED rather than verified once by hand — `M-CAL1`–`M-CAL8` for the
  transport and the provider's `IsLive`, `M-GTF1`–`M-GTF5` for the factory's surface dispatch, and
  `M-SD1`/`M-SD2` for `SurfaceDriverClass`. Restoring the watermark as the window start is caught too
  (`M-CW1`), which it was not when that bug was live: the harness did not open this file at all, so
  every mutation aimed at it reported all-clear by never reaching it. That is the reason the list is
  worth registering rather than writing down — an enumerated "all caught" over a file the harness never
  opens reads exactly like coverage.

- 7e6e87c: Activity Sync — the live-fetch gate was unreachable, so a scoped host could not turn it on.

  > **A DECISION IS REQUIRED BEFORE THIS IS TURNED ON, AND IT IS NOT A CODE DECISION.**
  >
  > `MSGraphProvider` authenticates app-only, so the `Mail.Read` **application** permission is granted
  > against the tenant, not against a mailbox: it can read **every mailbox in the organisation**. The
  > `Mailbox` column on a connection narrows what we _ask_ for, never what we are _allowed_ to read.
  > The only thing that narrows the grant is an Exchange RBAC-for-Applications assignment binding the
  > app registration to a mail-enabled security group.
  >
  > **We do not know whether that assignment exists**, and could not find out: it is visible only to an
  > Exchange administrator. The app in use (`BizApps Sales - Activity Ingest`) holds application
  > `Mail.Read` and nothing else — confirmed from the token's own `roles` claim.
  >
  > **Merging this changes nothing on its own.** Live fetch stays refused: the default is the host
  > attestation, no host has one, and the attestation cannot be satisfied by a flag. Whichever way the
  > question is answered it needs a person and a date, plus EITHER the security group an Exchange
  > assignment scopes the app to OR a written sentence accepting the tenant-wide grant. Whoever deploys
  > has to answer the question deliberately. They cannot skip it by accident.
  >
  > Two legitimate outcomes, both informed: accept the tenant-wide grant and record who accepted it, or
  > scope the app to a group first. Creating the restriction is an Exchange administrator's job
  > (`New-ManagementScope` and `New-ManagementRoleAssignment`), and it is not something this package
  > can do or check from inside the application.

  `AllowLiveFetch` was the FIRST constructor argument of `MSGraphActivitySyncProvider`, defaulting to
  `false`. `MJGlobal.ClassFactory` builds plugins with NO arguments. So through `ActivitySyncEngine` —
  the only path production uses — live fetch was permanently off, and the parameter could be set by
  tests and the demo alone. Every test passed, because every test constructed the provider directly.

  This is the same defect the transport factory had one layer down, and it gets the same fix: a host
  registry. What it is emphatically NOT is a relaxation. Making a gate reachable must not make it open,
  and most of the new tests exist to pin that: with nothing registered, an unconfigured host refuses
  exactly as before, and the transport it refused is never called.

  **Two decisions are modelled, because two decisions are what organisations make.** The attestation is
  a discriminated union:

  - `RestrictedToGroup` — an Exchange assignment binds the app to a named security group.
  - `TenantWideAccepted` — the tenant-wide grant was looked at and accepted, with `AcceptedRisk` saying
    what was accepted in the deciding person's own words.

  An earlier draft demanded a group name, which quietly assumed every deployment would create an
  Exchange RBAC assignment. Most will not: adding an API permission in Entra is one team's five-minute
  job, and RBAC for Applications is a different system that often nobody owns. A gate that accepts only
  "scoped" leaves everyone else choosing between inventing a group name and bypassing the gate — and
  both destroy the record it exists to keep. What stays impossible is the third state, _nobody looked_:
  neither variant can be satisfied without a name, a date, and either a group or a written reason.

  `AcceptedRisk` is free text and required rather than a flag, deliberately. A tick-box records that
  somebody clicked; a sentence records that somebody understood, and it is what an audit reads when the
  next person asks why this app can read every mailbox.

  **The opt-in is an attestation, not a boolean.** A boolean records that somebody WANTED live fetch.
  `LiveMailboxPolicyAttestation` records that somebody CHECKED — which mail-enabled security group the
  Exchange Application Access Policy names, who confirmed it, and when. Those are the things an audit
  asks for, and the things a person has to look up rather than guess. `Confirmed` is the literal `true`
  rather than `boolean`, so a variable that happens to be false will not type-check and the attestation
  cannot be satisfied by threading a flag through. The types are not the only guard, because a type is
  not a guard at all against an untyped caller: `AllowLiveMailboxFetch` CHECKS at runtime that
  `Confirmed` is literally `true`, that `ConfirmedBy` is not blank, and that `ConfirmedAt` is a real
  `Date` — each refusing by name. Whichever variant is used, a blank group or a blank accepted-risk
  sentence is rejected: accepting one would turn this straight back into a boolean with extra steps.

  Staleness is deliberately NOT enforced. `ConfirmedAt` is recorded and logged at bootstrap so an
  operator can SEE that an attestation is two years old; expiring it in code would take a working
  deployment off the air on a date nobody scheduled, which is a worse failure than a visible old date.

  **Deliberately not driven by data.** `ActivitySyncConnection` is an ordinary editable entity. Had the
  opt-in lived there, anyone who could edit a row could enable tenant-wide mail reading from a form —
  app-only `Mail.Read` reads EVERY mailbox in the tenant, and a connection's `Mailbox` narrows what we
  ask for, not what we are allowed to read. The package already refuses to let a database row swap the
  transport; this applies the same rule to the more dangerous switch. `AllowLiveMailboxFetch` is a
  bootstrap-time call, and the host reads it from deployment configuration.

  **A partial configuration throws rather than quietly staying off.** `LoadLiveMailboxPolicyFromEnv`
  wants `ACTIVITY_SYNC_MAILBOX_POLICY_CONFIRMED_BY` and `..._CONFIRMED_AT` whichever decision was made,
  and then EXACTLY ONE of `..._GROUP` or `..._ACCEPTED_RISK` — the two are mutually exclusive, because
  setting both claims the app is restricted and knowingly unrestricted at the same time. Setting none
  of the four is the ordinary un-opted-in case and is silent; setting some of them throws. Silently
  ignoring a half-written opt-in is the exact trap this codebase keeps being written against: an
  operator who set two of three would see the provider refuse, believe the Exchange policy was wrong,
  and go hunting for a fault that is in their `.env`. Blank and whitespace-only values read as absent,
  and an unparseable date is rejected by name.

  **The refusal now names the way out.** `LIVE_GRAPH_REFUSAL` explained why live fetch was off but not
  how to enable it, which left an operator who HAD verified the policy with no supported next step —
  and the tempting unsupported one is to go editing rows.

  343 tests in `common-activity-sync` and 47 in `common-server`, with a mutation driver in each:
  64 mutants in `packages/ActivitySync/test-harnesses/mutate-checks.mjs` and 15 in
  `packages/Server/test-harnesses/mutate-checks.mjs`, all 79 caught. Every source file this change
  touches carries at least one, bar the barrel and the types file. Between them they fell reverting
  the default to `false`, allowing everything, dropping any of the three runtime attestation checks,
  accepting whitespace as a group name, treating a partial env as complete, claiming both decisions at
  once, claiming neither, filing a tenant-wide acceptance as a group restriction, skipping date
  validation, and misreporting the result.

  Later commits on this branch fix defects of the same class found in the branch itself. The
  attestation was a compile-time shape with no runtime check. The `InternalDomains` fix had no test
  that could fail. The calendar window keyed on the watermark rather than on a lookback span, which
  silently skipped back-dated meetings, and the replay transport had the matching hole on its first
  run. Issues raised by a run that SUCCEEDED were never written anywhere, which discarded the delivery
  mechanism for every deliberate report this package makes. `ActivityFileSink` gained a host registry,
  because its only production construction passes no arguments and `Store()` therefore had no caller.

  Several of those were found by asking the suites to prove they could fail, rather than by reading.
  `common-server` had no mutation driver, and deleting either of the two guards that decide WHICH
  attestation was made left all 40 of its tests green — both rules are described above and neither had
  a reader. It also had no typecheck step over its tests, because its build config excludes them and
  vitest does not typecheck; adding one surfaced six type errors in test code, including assertions
  indexing an empty tuple, which could not have been reading what they claimed to.

  The last of them is the wiring itself. `LoadBizAppsCommonServer` is what MJAPI's
  `DynamicPackageLoader` calls at startup, and its two lines registering the transport factory and
  reading the attestation are the only thing that populates either registry on a real host. Commenting
  out either left every test green, because both loaders are unit-tested by calling them directly.
  Without the policy load a host that set all four variables correctly is refused, and the refusal
  tells it to set the variables it just set.

  **The refusal itself was part of the same problem.** It said to "call `AllowLiveMailboxFetch()` with
  the group the policy names" — naming one of the two decisions this release exists to model, and a
  function rather than the environment variables a deployment actually sets. Every test compared
  against the constant, so the text could have been trimmed to one sentence and stayed green. It now
  names both decisions and the configuration, and three tests pin that it keeps doing so.

### Patch Changes

- Updated dependencies [23b6827]
- Updated dependencies [192cc39]
- Updated dependencies [4ad78ac]
- Updated dependencies [9d5cb06]
- Updated dependencies [b1e8650]
- Updated dependencies [9fc60ef]
- Updated dependencies [3aeb4a1]
- Updated dependencies [7e6e87c]
- Updated dependencies [ec6fab7]
- Updated dependencies [b2a310b]
  - @mj-biz-apps/common-entities@5.43.0
  - @mj-biz-apps/common-activity-sync@5.43.0
  - @mj-biz-apps/common-actions@5.43.0
  - @mj-biz-apps/common-core-entities-server@5.43.0

## 5.42.0

### Patch Changes

- @mj-biz-apps/common-actions@5.42.0
- @mj-biz-apps/common-activity-sync@5.42.0
- @mj-biz-apps/common-core-entities-server@5.42.0
- @mj-biz-apps/common-entities@5.42.0

## 5.41.0

### Patch Changes

- Updated dependencies [783936a]
- Updated dependencies [7d94d43]
  - @mj-biz-apps/common-entities@5.41.0
  - @mj-biz-apps/common-activity-sync@5.41.0
  - @mj-biz-apps/common-core-entities-server@5.41.0
  - @mj-biz-apps/common-actions@5.41.0

## 5.40.0

### Patch Changes

- Updated dependencies [de47552]
- Updated dependencies [de47552]
- Updated dependencies [e21b2db]
- Updated dependencies [b4387e4]
- Updated dependencies [dc7693c]
- Updated dependencies [22f6624]
  - @mj-biz-apps/common-activity-sync@5.40.0
  - @mj-biz-apps/common-entities@5.40.0
  - @mj-biz-apps/common-core-entities-server@5.40.0
  - @mj-biz-apps/common-actions@5.40.0

## 5.39.0

### Minor Changes

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

- Updated dependencies [8657091]
- Updated dependencies [b6b2b64]
- Updated dependencies [7887d5d]
  - @mj-biz-apps/common-activity-sync@5.39.0
  - @mj-biz-apps/common-actions@5.39.0
  - @mj-biz-apps/common-core-entities-server@5.39.0
  - @mj-biz-apps/common-entities@5.39.0

## 5.38.0

### Patch Changes

- Updated dependencies [4c27078]
- Updated dependencies [4c27078]
  - @mj-biz-apps/common-entities@5.38.0
  - @mj-biz-apps/common-activity-sync@5.38.0
  - @mj-biz-apps/common-core-entities-server@5.38.0
  - @mj-biz-apps/common-actions@5.38.0

## 5.37.0

### Minor Changes

- d73a3af: Fold CodeGen output for ActivitySyncProviderType.CalendarDriverClass into V202608301900.

  Hand DDL is the ALTER TABLE only. Microsoft365's CalendarDriverClass value stays in
  metadata JSON. CodeGen SQL (EntityField, view, spCreate/spUpdate/spDelete, trigger)
  is appended after the standard banner.

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
- Updated dependencies [d73a3af]
- Updated dependencies [d73a3af]
- Updated dependencies [d73a3af]
  - @mj-biz-apps/common-entities@5.37.0
  - @mj-biz-apps/common-activity-sync@5.37.0
  - @mj-biz-apps/common-core-entities-server@5.37.0
  - @mj-biz-apps/common-actions@5.37.0

## 5.36.0

### Minor Changes

- 60804ac: Ship CodeGen entity metadata, base views, and CRUD procedures for the six Activity tables introduced in V202608171935. A clean migrate previously left those tables without \_\_mj.Entity rows, so metadata sync of activity-types failed.
- 6fe1f09: Register the Activity related-name virtual EntityFields on Activity Links and Activity Files so save-capture ResultTables match the base views. Also covers the consumer-blind CodeGen V (no Orders in Common), Organizations CascadeDeletes off, and Activity Types hierarchy virtuals.

### Patch Changes

- Updated dependencies [60804ac]
- Updated dependencies [6fe1f09]
  - @mj-biz-apps/common-entities@5.36.0
  - @mj-biz-apps/common-core-entities-server@5.36.0
  - @mj-biz-apps/common-actions@5.36.0

## 5.35.1

### Patch Changes

- eac151e: Declare BUSL-1.1 in mj-app.json. The LICENSE file and every package already
  state BUSL-1.1; the manifest still said ISC, so anything reading it saw the
  wrong license.
- Updated dependencies [eac151e]
  - @mj-biz-apps/common-actions@5.35.1
  - @mj-biz-apps/common-core-entities-server@5.35.1
  - @mj-biz-apps/common-entities@5.35.1

## 5.35.0

### Patch Changes

- cbd0e27: Add RelatedRecordCollection metadata configuration for People and Organizations (Contact Methods, Relationships, Child Organizations) and synchronize CodeGen output.
- Updated dependencies [1f07f2a]
- Updated dependencies [026b83e]
- Updated dependencies [4b4bcaa]
- Updated dependencies [cbd0e27]
  - @mj-biz-apps/common-entities@5.35.0
  - @mj-biz-apps/common-core-entities-server@5.35.0
  - @mj-biz-apps/common-actions@5.35.0

## 5.34.0

### Patch Changes

- Updated dependencies [2c8c1bc]
- Updated dependencies [ab9f88e]
- Updated dependencies [2f8dd2b]
- Updated dependencies [e69c364]
  - @mj-biz-apps/common-entities@5.34.0
  - @mj-biz-apps/common-core-entities-server@5.34.0
  - @mj-biz-apps/common-actions@5.34.0

## 5.33.2

### Patch Changes

- Updated dependencies [c2974b6]
  - @mj-biz-apps/common-entities@5.33.2
  - @mj-biz-apps/common-core-entities-server@5.33.2
  - @mj-biz-apps/common-actions@5.33.2

## 5.33.1

### Patch Changes

- Updated dependencies [6eae25b]
  - @mj-biz-apps/common-entities@5.33.1
  - @mj-biz-apps/common-core-entities-server@5.33.1
  - @mj-biz-apps/common-actions@5.33.1

## 5.33.0

### Patch Changes

- Updated dependencies [1ffb2a5]
- Updated dependencies [2c33643]
  - @mj-biz-apps/common-entities@5.33.0
  - @mj-biz-apps/common-core-entities-server@5.33.0
  - @mj-biz-apps/common-actions@5.33.0

## 5.32.0

### Minor Changes

- b5f34d2: PG fixes for CanonicalSchema and CodeGen

### Patch Changes

- Updated dependencies [b5f34d2]
  - @mj-biz-apps/common-core-entities-server@5.32.0
  - @mj-biz-apps/common-entities@5.32.0
  - @mj-biz-apps/common-actions@5.32.0

## 5.31.3

### Patch Changes

- 5346c70: Upgraded BAC to MJ 5.44; PostgreSQL install verified, seeds fixed.
- Updated dependencies [5346c70]
  - @mj-biz-apps/common-core-entities-server@5.31.3
  - @mj-biz-apps/common-entities@5.31.3
  - @mj-biz-apps/common-actions@5.31.3

## 5.31.2

### Patch Changes

- 969954b: fix(common): lowercase PostgreSQL app schema name in migrations to match physical schema
- Updated dependencies [969954b]
  - @mj-biz-apps/common-actions@5.31.2
  - @mj-biz-apps/common-core-entities-server@5.31.2
  - @mj-biz-apps/common-entities@5.31.2

## 5.31.1

### Patch Changes

- Updated dependencies [6e0ea6c]
  - @mj-biz-apps/common-core-entities-server@5.31.1
  - @mj-biz-apps/common-actions@5.31.1
  - @mj-biz-apps/common-entities@5.31.1

## 5.31.0

### Minor Changes

- 64200c7: Added PG support and MJ upgrade to 5.40.2

### Patch Changes

- Updated dependencies [64200c7]
  - @mj-biz-apps/common-core-entities-server@5.31.0
  - @mj-biz-apps/common-entities@5.31.0
  - @mj-biz-apps/common-actions@5.31.0

## 5.30.1

### Patch Changes

- Updated dependencies [a46ab44]
  - @mj-biz-apps/common-entities@5.30.1
  - @mj-biz-apps/common-core-entities-server@5.30.1
  - @mj-biz-apps/common-actions@5.30.1

## 5.30.0

### Patch Changes

- 49d5b9c: Add CoreEntitiesServer package with PersonEntityServer and LinkedUserID unique constraint
- Updated dependencies [49d5b9c]
  - @mj-biz-apps/common-core-entities-server@5.30.0
  - @mj-biz-apps/common-entities@5.30.0
  - @mj-biz-apps/common-actions@5.30.0

## 5.29.0

### Minor Changes

- b0b2d13: Adds BAC's first Metadata_Sync migration plus a Person.DisplayName computed column so consumers get correct seed data and friendly entity display names

### Patch Changes

- Updated dependencies [b0b2d13]
  - @mj-biz-apps/common-entities@5.29.0
  - @mj-biz-apps/common-actions@5.29.0

## 5.28.0

### Minor Changes

- b61bb46: Upgrade MJ to 5.33.0, regenerate BAC's CRUD sprocs with v5.33 tolerant signatures, and enable cascade deletes on Organizations.

### Patch Changes

- Updated dependencies [b61bb46]
  - @mj-biz-apps/common-entities@5.28.0
  - @mj-biz-apps/common-actions@5.28.0

## 5.27.1

### Patch Changes

- fa421da: Move `@memberjunction/*` and `@angular/*` deps to peerDependencies so consuming MJ apps resolve a single instance and avoid duplicate singletons.
- Updated dependencies [fa421da]
  - @mj-biz-apps/common-entities@5.27.1
  - @mj-biz-apps/common-actions@5.27.1
