# Change Log - mj_generatedentities

## 5.46.1

## 5.46.0

### Minor Changes

- 12a6de8: Add Activity Tagging & Sentiment feature pipeline (FP-7 / P2-1).

  - Database schema and migration:
    - `Activity.SentimentScore`: Bounded decimal column `DECIMAL(4,3)` (-1.000 to +1.000) for activity sentiment.
    - Recreates `vwActivities` to include `SentimentScore`.
    - Updates `spCreateActivity` and `spUpdateActivity` with `@SentimentScore` parameter.
    - Appends `EntityField` for `SentimentScore` on `MJ_BizApps_Common: Activities`.
  - Metadata:
    - `Common: Activity With Contact History` query retrieving target activity and linked contact's historical baseline.
    - `Activity Tagging and Sentiment Derivation` prompt with contact baseline analysis.
    - `Sentiment` taxonomy root tag with child tags (`Positive`, `Neutral`, `Negative`, `EscalationRisk`, `Urgent`).
    - `Activity Tagging and Sentiment` Feature Pipeline Record Process (`WorkType: 'Infer'`, `Cacheable: false`, `Watermark: 'Checksum'`).

- 2f28572: Add Job Function & Seniority people model and feature pipeline integration (FP-6).

  - Database schema and migration:
    - `JobFunction`: Type table (`MJ_BizApps_Common: Job Functions`) with seed data in `metadata/job-functions/`.
    - `SeniorityLevel`: Type table (`MJ_BizApps_Common: Seniority Levels`) with seed data in `metadata/seniority-levels/` carrying rank order (IC -> Manager -> Director -> VP -> C-Level).
    - `PersonJobFunction`: 1:M bridge (`MJ_BizApps_Common: Person Job Functions`) with `Source` ('Manual' | 'Derived') and `Confidence`.
    - `Person.SeniorityLevelID` foreign key to `SeniorityLevel`.
    - `Relationship.JobFunctionID` and `Relationship.SeniorityLevelID` foreign keys for per-company role classification.
    - `vwPeople`: Virtual view columns `PrimaryJobFunctionID` and `PrimaryJobFunction` derived from the lowest Sequence `PersonJobFunction` row.
    - `metadata/record-processes/`: Dogfood RecordProcess feature pipeline configuration for Job Function and Seniority classification.
  - Progressive disclosure UX:
    - `PersonIdentityComponent`: Compact chips for `PrimaryJobFunction` and `SeniorityLevel` in the identity header badges, with interactive disclosure for multiple job functions, and `SeniorityLevelID` in EditMode.
    - `RelationshipListComponent`: Displays `JobFunction` and `SeniorityLevel` badges on timeline items when set; provides progressive disclosure section in Add and Edit forms so role classification is invisible until expanded or set.

## 5.45.0

### Minor Changes

- 868b125: Party Signals: a shared answer to "which organizations and people are our customers", plus a
  selling-company field that defaults and confirms.

  Common owns Organizations and People but cannot see the orders, contracts or sales schemas, and
  neither party carries a customer flag or a last-activity date. So nothing that renders a party —
  a foreign-key picker above all — has ever been able to tell a customer from any other row in a
  directory that can run to hundreds of thousands. It offers the first twenty rows that contain the
  typed letters, in no particular order.

  **The contract.** An app declares its own customers by shipping ONE query in the new `Party Signals`
  query category, returning `PartyKind` (`'organization'` | `'person'`), `PartyID`, `Count` and
  `LastActivityAt`, and carrying a `[signal: noun|nouns]` marker in its own `Description` so a caller
  can label "4 orders" without knowing what an order is. The category is the registry: Common never
  imports an app, and an app joins the answer by shipping metadata, with no code change here.

  `@mj-biz-apps/common-entities` exports the contract and the pure union — `PARTY_SIGNALS_CATEGORY`,
  the row and roster types, `MergePartySignalRows`, `ParseSignalNouns`, `ChipText`. Party IDs are
  matched case-insensitively, because GUIDs arrive in whichever case the provider produced and two
  spellings of one organization would otherwise read as two customers.

  **Two readers, one definition.** `PartySignalStore` (common-ng) discovers the category through
  metadata and runs each query once per session, for Explorer. `Common.GetPartySignals`
  (common-server) does the same union server-side for everything that is not Angular — agents, MCP,
  reports, scripts. Both run every query as the calling user, so the roster is permission-filtered; a
  query the caller cannot read contributes nothing and is named in warnings rather than failing the
  call, so a missing signal weakens ranking instead of breaking the field.

  **`bizapps-selling-company-field`.** The company on an order or a contract decides which legal
  entity books the revenue, and the picker behind it lists every company row the instance has. Apps
  have defaulted it by whichever company sorted first alphabetically, or by the first product on the
  order — rules nobody wrote down. This field defaults to the current user's own company when they
  have one and it is a company the instance knows, otherwise to the new Common `DefaultSellingCompanyID`
  setting, otherwise to nothing. Anything else is held, named back to the user against the default,
  and written only on confirm; an unanswered question reverts, because it must not decide where
  revenue lands. It wraps `mj-form-field`, so the dropdown, keyboard behaviour and link rendering
  stay the platform's.

  **Metadata.** `AllowMultipleSubtypes` is now set on Organizations and People, because both are
  extended as IsA children and the disjoint default mis-chains silently. `AllowRecordMerge` is not:
  `CK_Entity_AllowRecordMerge` requires `AllowDeleteAPI = 1` and `DeleteType = 'Soft'`, and both
  parties are hard-delete, so enabling merge is a schema change rather than a flag and belongs in its
  own release. `Organizations.Website` and
  `People.Title` join user search, with `BeginsWith` predicates and `AutoUpdate` pins so CodeGen
  cannot flip them back; the other identifying fields were already flagged.

  The party lookup strategy that consumes all of this is a separate release: it needs the platform
  foreign-key lookup-strategy seam, which nothing here waits on.

## 5.44.0

### Minor Changes

- 7056463: Say on `ActivitySyncRunDetail.CapturedContent` that rotating its encryption key makes existing rows unreadable.

  The column already described its own contract — _"Ciphertext, always … Encrypted through MJ's EncryptionEngine against an MJ: Encryption Keys row"_ — which reads like a promise the value stays readable. It does not survive a key rotation, and the operator who turns retention on is the person who needs to know that before the rows exist rather than after.

  `RotateEncryptionKeyAction` finds what to re-encrypt by enumerating `MJ: Entity Fields` with `EncryptionKeyID = '<key>' AND Encrypt = 1`. This column is encrypted by calling the engine directly rather than by declaring the field — the same decision that keeps the crypto out of `common-activity-sync` — so rotation never sees it. The stored envelope, `$ENC$<keyId>$<algorithm>$<iv>$<ciphertext>[$<authTag>]`, records which key opened a value but not which version of it, so nothing in the row says it was written under an earlier one. Rotation reports success, skips these rows, and the next read of them fails.

  Live operational data is re-encrypted as part of a rotation, which is why this has not bitten anything before. An audit archive is the one kind of column where the read comes years after the write.

  Written as an `MS_Description` extended property rather than an `EntityField.Description` update, because `spUpdateExistingEntityFieldsFromSchema` mirrors the column comment over `EntityField.Description` whenever `AutoUpdateDescription = 1`, which this row took by default; a direct update would be reverted by the next `R__RefreshMetadata`. The migration also mirrors the property into `EntityField` itself, reading it back out of the catalog so the two cannot drift, since that repeatable only re-runs when its own checksum changes.

  The underlying platform gap is tracked as MemberJunction/MJ#4580. Nothing in this repo works around it: recording a key version in the envelope, or giving rotation a way to see hand-encrypted columns, are both platform decisions.

  The next CodeGen run will carry the new text into the generated entity docblock and the GraphQL field description; those files are not in this changeset.

## 5.43.0

### Minor Changes

- 23b6827: Activity: remove the phantom `ParentActivity` EntityField that made every Activity create fail.

  `Activity` metadata carried a virtual field `ParentActivity` at sequence 24 that `vwActivities` does
  not emit. MJ's save-capture is POSITIONAL — it declares one slot per EntityField and reads them back
  by position from the base view — so metadata declared 34 slots against a 33-column view and every
  create failed with `Column name or number of supplied values does not match table definition`.

  **What that looked like in practice.** Activity Sync fetched, qualified, resolved identities and
  threading correctly, then wrote nothing: `Failed: 5, Success: false`. The watermark is held on
  failure, so it retried the same messages on every pass and never made progress. Nothing about the
  message named the real cause.

  **WHICH DATABASES ARE IN THAT STATE, since on many this migration will print and do nothing.**
  `V202608252150` ships `vwActivities` WITH a `ParentActivity` column and the matching EntityField, so a
  database built from this repo's Flyway chain and never regenerated is aligned at 34/34 and the guard
  below leaves it alone. The mismatch appears once someone runs `mj codegen` against such a host: for a
  self-referencing FK, CodeGen rebuilds the view with the hierarchy columns and no `ParentActivity`,
  while the EntityField row stays — 34 slots against 33. That is the state the development database was
  in. The closing assertion runs on every host regardless, so an aligned database proves it rather than
  being assumed to be.

  This is the same defect `V202608261015` fixed for Activity Links and Activity Files, in the opposite
  direction — that one added a virtual field the view HAD and metadata lacked (N slots against N+1
  columns); this removes one metadata HAS and the view lacks.

  **Why remove the field rather than add the column.** `ParentActivityID` is a self-referencing FK, and
  for it CodeGen emits the hierarchy columns (`RootParentActivityID`, `ParentActivityIDDepth`/`Path`/
  `IsLeaf`/`ChildCount`) rather than a plain related-name join. A migration that added the column would
  be undone on the next CodeGen run. Verified: after a full `mj codegen` on a healed database, metadata
  and view stay aligned at 33/33 and the field does not come back — which is also why this leaves
  `IncludeRelatedEntityNameFieldInBaseView` alone rather than flipping a flag whose CodeGen behaviour
  differs between this entity and `ActivityType` for reasons not established here.

  **Guarded on the actual state, not on an ID.** The field is created by a CodeGen proc that mints a
  fresh GUID per host, so an ID-only guard would match nothing on most databases — the trap that stalled
  the migration chain in bizapps-orders#126. It matches on `(EntityID, Name)`, and acts only where
  `vwActivities` genuinely lacks the column, so a database whose view does expose it is left untouched.
  The migration ends by re-checking that no Activity field lacks a view column and throwing if one does,
  because failing in the migration is far cheaper than failing on the next create.

  All three paths exercised against a real database: the defect reproduced (`Failed: 5`, nothing
  written), the migration applied (`Included: 5`, five Activities and seventeen links written), a second
  and third application were clean no-ops, and with the column artificially present the migration
  correctly declined to remove the field.

  **The generated artifacts are deliberately left stale, and this is the record of that.**
  `get ParentActivity()` stays in the generated entity class and Zod schema, and `ParentActivity?:
string` in the GraphQL type. Where this migration removes the field those read `null` rather than
  throwing — `BaseEntity.Get` falls through both the raw path and `GetFieldByName` — so the positional
  save-capture fix holds either way.

  They are not regenerated because the deletion does not stop at generated files.
  `activity-identity.component.html` DISPLAYS the field: `@if (Record.ParentActivity)` gates a
  "Thread / Parent" stat in the Activity header, and the Angular package compiles with
  `strictTemplates: true`, so removing the getter makes that template a build error. Regenerating means
  changing a hand-written component that shows a user something — a different change from this one.

  The cost is drift: the next `mj codegen` on a healed database emits a three-file deletion, and
  whoever sees it should know it belongs here.

- ec6fab7: The business time zone, and calendar-day helpers every BizApp shares (bc-aidp-next-golive#168).

  `Order Date` defaulted to the UTC calendar day, so an order entered after 7 PM Central was dated
  tomorrow; the accounting journal-entry draft used the browser's local day; every view compared
  against `CAST(GETUTCDATE() AS date)`, so a contract ending December 31 read as expired at 7 PM
  Central on the 31st. Each app had its own copy of the same date arithmetic.

  One instance configuration row, `BizApps.BusinessTimeZone`, holds the zone the business books in:
  `{"iana": "America/Chicago", "sql": "Central Standard Time"}`. **Both names are required.** `Intl`
  accepts only the IANA name and SQL Server's `AT TIME ZONE` accepts only the Windows one, so a row
  carrying one of them would have code and views answering different days; a one-name row is treated
  as unreadable and everything falls back to UTC. The row ships empty, which means UTC until the host
  sets it. `BusinessTimeZoneEngine` caches it on client and
  server and answers `Today()` in that zone, falling back to UTC when the row is unset, unreadable, or
  names a zone the runtime does not know. `business-day.ts`
  is the one implementation of calendar-day parsing, formatting and arithmetic: a `DATE` column is read
  from its UTC parts and written as UTC midnight, exactly as MJ's own form field does. The migration
  seeds the row empty (the host sets it) and defines `fnBusinessToday()` in the common schema, an
  inline table-valued function every app's views cross join for "today".

## 5.42.0

## 5.41.0

### Minor Changes

- 783936a: Describe the four Activity Sync switches an operator sets: `ActivitySyncExclusion.IsEnabled`, `EffectiveFrom`, `EffectiveTo` and `ActivitySyncProviderType.IsActive` were all created without a column description. The one that needed saying is the exclusion window, because the same feature carries the opposite convention a few fields away — `ActivitySyncConnection.StartAt`/`EndAt` are evaluated against the clock, while the exclusion window is matched against the message's own timestamp, so setting `EffectiveFrom` to today does not mean "from now on".

  Written as `MS_Description` extended properties rather than as an `EntityField.Description` update, because `spUpdateExistingEntityFieldsFromSchema` mirrors the column comment over `EntityField.Description` whenever `AutoUpdateDescription = 1`, which these rows default to; a direct update would have been reverted by the next `R__RefreshMetadata`. The migration also mirrors the four properties into `EntityField` itself, reading them back out of the catalog so the two cannot drift, since that repeatable only re-runs when its own checksum changes.

  The next CodeGen run will add the matching `* * Description:` docblock lines and GraphQL `@Field` descriptions for these four fields; those generated files are not in this changeset.

- 7d94d43: Forward-heal missing EntityField registrations for Addresses (**mj_Latitude, **mj_Longitude), Activity Files (Activity), and Activity Links (Activity).

## 5.40.0

### Minor Changes

- e21b2db: Address is the geo write source (`SupportsGeoCoding=1`, Latitude/Longitude tagged GeoLatitude/GeoLongitude). Organizations layered view bubbles PrimaryAddressLatitude/Longitude (virtual display fields) like People. GeoCodeSyncService does not run on Person/Org (no writable Geo\*).
- b4387e4: Widen Person.PhotoURL and Organization.LogoURL to NVARCHAR(MAX) (DDL) and fold scoped CodeGen emit (`includeSchemas: __mj_BizAppsCommon`) for views, CRUD procs, and generated TS/HTML (loom #12 WP1).
- 22f6624: Widen Person.PhotoURL and Organization.LogoURL to NVARCHAR(MAX) so illustrated avatars and logos can be stored as inline data URIs (loom #12 WP1).

### Patch Changes

- dc7693c: Replay-safe PhotoURL/LogoURL NVARCHAR(MAX) migration: DDL only, then inlined R\_\_RefreshMetadata, then CodeGen emit authored while EntityField.Length still showed the old size so Person/Org CRUD procs pick up MAX.

## 5.39.0

### Patch Changes

- 7887d5d: License declarations now agree on BUSL-1.1 everywhere.

  `LICENSE`, `package.json`, `mj-app.json` and every workspace package already declared
  BUSL-1.1. Two statements still said ISC: the README badge, which is the first license
  statement a reader meets and so outranked all of them in practice, and the `mj-app.json`
  sample in `docs/open-app.md` — this repo is the reference Open App, so that snippet is
  copied into new repos and is how the wrong value spreads. The badge now links to `LICENSE`.

## 5.38.0

### Minor Changes

- 4c27078: `Metadata_Sync` for the Activity Sync release — the metadata that makes 5.37.0 actually run.

  The last Metadata_Sync was `V202608262255` (v5.36.x), which predates every row the Activity Sync work
  added. Release seed coverage counted **83 metadata primaryKeys across 8 files appearing in no
  migration**: 32 Actions, 40 Entity Actions, 2 AI Agents, 1 Scheduled Job, 4 Activity Sync Provider
  Types, 2 Action Filters, 1 Action Category, 1 Activity Type.

  Because `mj-app.json`'s `metadata.directory` is a dev-time pointer the install engine never reads,
  **5.37.0 shipped the ActivitySync schema and engine with none of the metadata that drives them** — the
  actions the engine dispatches, the entity-action bindings, the lifecycle agent and the daily job. A
  clean install reported success and produced a feature that could not run.

  `V202609020500__v5.38.x__Metadata_Sync.sql` carries 165 records (83 created, 3 updated, 0 errors),
  generated against a database built from migrations only (MJ core v6.1.0-edge.5 + this app).

  Minor, not patch: this release carries a migration.

### Patch Changes

- 4c27078: Move to MJ `6.1.0-edge.5`, and drop the two exact `ng-*` pins.

  All 41 `@memberjunction/*` dependencies now use `^6.1.0-edge.5`. They were spread across three
  versions — `^6.1.0-edge.2` (2), `^6.1.0-edge.3` (37), and an **exact** `6.1.0-edge.3` on
  `ng-graph-view` and `ng-hierarchy-tree` (2).

  Those two exact pins are the shape bizapps-orders removed for cause: an exact `ng-hierarchy-tree` pin
  _"forced two MJ copies into consumers' Explorer trees and split the ClassFactory registry"_. Caret,
  never exact.

  This also matters to consumers rather than just to this repo: `common-entities@5.37.0` publishes with
  `@memberjunction/*` at `^6.1.0-edge.3`, so anything installing bizapps-common alongside an
  edge.5 app resolves two MJ trees. bizapps-sales hit exactly that.

  Verified after a clean install: a single `@memberjunction/core` at `6.1.0-edge.5`, zero packages left
  at edge.2 or edge.3, and build 7/7.

## 5.37.0

### Minor Changes

- d73a3af: Activity Sync Engine P2 — CodeGen objects folded into the schema V, plus provider-type seeds.

  Entity metadata, views, and CRUD for the seven new Activity Sync tables append under the
  banner in `V202608291500` (one migration for the whole schema; no standalone CodeGen V).
  Seeds Microsoft365, Gmail, Zoom, and Generic as metadata, with
  `DefaultQualificationPolicy=Exclude` on mailbox-shaped types.

- d73a3af: Fold CodeGen output for ActivitySyncProviderType.CalendarDriverClass into V202608301900.

  Hand DDL is the ALTER TABLE only. Microsoft365's CalendarDriverClass value stays in
  metadata JSON. CodeGen SQL (EntityField, view, spCreate/spUpdate/spDelete, trigger)
  is appended after the standard banner.

- d73a3af: Activity sync trigger, calendar companion as data, and per-connection health.

  Seeds Common.SyncActivities (Action, Limit, result codes, hourly job) as JSON.
  CalendarDriverClass on ActivitySyncProviderType drives the companion surface through
  ClassFactory. Connection health is stamped once from combined surfaces. A failed
  connection list load is ERROR, not NO_CONNECTIONS.

## 5.36.0

### Minor Changes

- 60804ac: Ship CodeGen entity metadata, base views, and CRUD procedures for the six Activity tables introduced in V202608171935. A clean migrate previously left those tables without \_\_mj.Entity rows, so metadata sync of activity-types failed.
- 6fe1f09: Register the Activity related-name virtual EntityFields on Activity Links and Activity Files so save-capture ResultTables match the base views. Also covers the consumer-blind CodeGen V (no Orders in Common), Organizations CascadeDeletes off, and Activity Types hierarchy virtuals.

## 5.35.1

### Patch Changes

- eac151e: Declare BUSL-1.1 in mj-app.json. The LICENSE file and every package already
  state BUSL-1.1; the manifest still said ISC, so anything reading it saw the
  wrong license.

## 5.35.0

### Minor Changes

- 1f07f2a: Add Activity, ActivityType, ActivityLink, ActivityFile, ActivitySyncConnection, and ActivitySyncRule so Common can log interactions and control what a mailbox/calendar connection syncs. System activity types (Email, Call, Meeting, Note, SMS, Chat) are seeded via metadata, not SQL INSERTs.
- 026b83e: Person and Organization related-grid membership uses L1 inclusion (Primary / More). Incoming Relationships sit in More.
- 4b4bcaa: Mark People and Organizations as smart-ranked hub forms, and punch Contact Methods / outgoing Relationships / child Organizations as FormRole Primary so they stay top-level when other apps hang grids on the same record.

### Patch Changes

- cbd0e27: Add RelatedRecordCollection metadata configuration for People and Organizations (Contact Methods, Relationships, Child Organizations) and synchronize CodeGen output.

## 5.34.0

### Minor Changes

- 2c8c1bc: Address/contact widgets: MJ design tokens, two field-population bugs, and the layered base views that make the Primary Address panel work at all.

  **Design tokens.** All four shared widgets (address editor, contact method list, relationship list, org hierarchy tree) predate MJ's token system and hardcoded 191 colour values, so they were unreadable in dark mode — dark grey label text on a dark surface, and white form-input backgrounds. Every value now maps to a semantic token (`--mj-text-*`, `--mj-bg-surface*`, `--mj-border-*`, `--mj-status-*`), with translucent tints via `color-mix()` so they adapt too. Note that 8 of these were CSS _keyword_ colours (`background: white`) rather than hex — MJ's `check:ui-tokens` gate only scans hex/rgb/hsl, so those would not have been caught by it, and they were the ones most visibly breaking dark mode.

  **Postal-code lookup never filled the state box.** The Postal Code Lookup action returns its `Message` as the raw `ProviderGeocodeResult`, whose field is `StateProvinceCode` / `StateProvinceName`; there is no `State` on that shape (`State` exists only as a separate Output param). Reading `address.State` was therefore always `undefined` — City worked purely because that name happens to match. Now reads `StateProvinceCode ?? StateProvinceName ?? State`.

  **Mailing addresses showed a blank icon.** The seed data used `fa-solid fa-mailbox`, which is Font Awesome **Pro**; the bundled set is Free, so the browser matched no rule and rendered an empty square. The existing `|| fallback` could not help because the class was non-empty, just unrenderable. Corrected the seed to `fa-solid fa-envelope`, and added `resolveIconClass()`, which also falls back for blank, whitespace-only, style-only (`fa-solid` alone) and known Pro-only classes.

  **Primary Address panel was empty on every record.** The Person and Organization forms bind to `PrimaryAddressLine1` / `City` / `State` / `PostalCode` / `Country` / `Type`, which only ever existed on the hand-written `vwPeopleExtended` / `vwOrganizationsExtended` — archived, and present in no current database. This completes the move to MJ layered base views planned in 35bb1fa and unblocked by MJ#3419: CodeGen now generates everything mechanical under `vwPeopleGenerated` / `vwOrganizationsGenerated`, and this app owns a thin `SELECT g.*, <enriched columns>` wrapper. The 14 layered columns register as virtual `EntityField`s, so the forms populate with no template change. Both wrappers expose a superset of the previous base views — no column is lost, and foreign keys added later gain their display fields automatically instead of silently going missing.

  While porting the archived view, one bug was found and not carried over: it resolved the polymorphic `AddressLink` with `WHERE [Name] = 'MJ.BizApps.Common: People'` — dotted. That subquery returns NULL, so the join matched nothing and every address column came back NULL. Restoring those views as-written would have produced the same empty panel, looking exactly like "this person has no primary address".

- ab9f88e: Re-register the layered `EntityField` rows after the wrapper views exist, so the Person and
  Organization "Primary Address" panels actually populate on a host.

  `V202608132239` inserts the 29 EntityField rows for the layered columns and then, 3,000 lines
  later, runs `spDeleteUnneededEntityFields` — which compares that metadata against the columns
  visible in each entity's `BaseView`. At that point `BaseView` is the application-owned wrapper
  (`vwPeople` / `vwOrganizations`), which does not exist yet: it is created by `V202608132240`,
  and it has to come second because a view cannot be created over the inner view that the same
  migration creates. The columns are invisible, the procedure correctly deletes the rows, and the
  panels stay empty.

  Verified on a clean database — MJ core plus every bizapps-common migration in order, no CodeGen:
  0 of the layered fields registered before this migration, 11 on People and 9 on Organizations
  after it.

### Patch Changes

- 2f8dd2b: Unify every `@memberjunction` range at the estate-wide floor `^6.1.0-edge.2` — replacing the
  mix of `^6.1.0-edge.0` (the original 6.x upgrade), `^6.1.0-edge.1` (the UserCache peer from
  #54), and three exact `6.1.0-edge.0` pins. Pure range change; no code, migrations, or
  metadata.

## 5.33.2

### Patch Changes

- c2974b6: Migrate the workspace from npm to pnpm, and release the peer-range fix from #51.

  No published package's code, types, metadata or migrations change — this is a
  build-tooling change plus a dependency-range correction, which is why it is a patch.

  **pnpm migration.** `packageManager` moves to `pnpm@10.33.0`, `package-lock.json` is
  replaced by `pnpm-lock.yaml`, the npm `overrides` block moves to `pnpm.overrides`, and
  CI installs with `pnpm install --frozen-lockfile`. Two workspace settings are
  load-bearing and mirror MJ core: `linkWorkspacePackages: true` (pnpm 10 defaults it
  false, which resolves this repo's exact-pinned internal packages from the registry
  instead of linking them locally) and an `onlyBuiltDependencies` allowlist (pnpm 10 runs
  no dependency build scripts without one).

  pnpm's non-hoisted layout also surfaced one latent defect: `apps/MJAPI` runs `vitest run`
  but never declared `vitest` anywhere in the repo, so it had been resolving from a hoisted
  transitive copy. It is now declared. That app is private and unpublished, so this does
  not affect consumers.

  **Why this ships #51.** The peer-range fix merged to `next` without a changeset, so it
  had no path to npm. This release carries it: every `@memberjunction/*` peer across the
  five published packages moves from an exact `6.1.0-edge.0` pin to `^6.1.0-edge.0`.

  That matters for consumers. An exact peer pin says "this build and no other", so a
  consumer on `6.1.0-edge.1` — which is the rest of the estate — had a mismatch. Under npm
  with `legacy-peer-deps` the mismatch was silently ignored; under pnpm it is satisfied by
  installing a **second copy** of ~100 MemberJunction packages. Two `@memberjunction/global`
  instances means two `MJGlobal` singletons and a split `ClassFactory` registry: it compiles
  cleanly and fails at runtime. A caret on a prerelease matches other prereleases sharing
  the same major.minor.patch, so `^6.1.0-edge.0` is satisfied by an existing edge.1 copy and
  the duplicate disappears.

  Consumers on a MemberJunction 6.x line should take this release and will need no
  `overrides` workaround to deduplicate MJ.

## 5.33.1

### Patch Changes

- 6eae25b: Upgrade to MemberJunction 6.1.0-edge.0. All `@memberjunction/*` dependencies and peer ranges now require the 6.x line, and the Open App manifest's `mjVersionRange` is `>=6.1.0 <7.0.0` — consumers must be on a MemberJunction 6.x environment. No source changes were required: the MJ 6.x breaking-change surface (integration connectors, ActionExecutionLog.Params, AIEngine similarity APIs, system-catalog SQL, HS256 JWTs, negation-form RLS filters) does not touch this codebase.

## 5.33.0

### Minor Changes

- 1ffb2a5: Deprecate Person LinkedUserID

## 5.32.0

### Minor Changes

- b5f34d2: PG fixes for CanonicalSchema and CodeGen

## 5.31.3

### Patch Changes

- 5346c70: Upgraded BAC to MJ 5.44; PostgreSQL install verified, seeds fixed.

## 5.31.2

### Patch Changes

- 969954b: fix(common): lowercase PostgreSQL app schema name in migrations to match physical schema

## 5.31.1

## 5.31.0

### Minor Changes

- 64200c7: Added PG support and MJ upgrade to 5.40.2

## 5.30.1

### Patch Changes

- a46ab44: Fix publish CI/CD to sync mj-app.json version and mjVersionRange automatically during release

## 5.30.0

### Patch Changes

- 49d5b9c: Add CoreEntitiesServer package with PersonEntityServer and LinkedUserID unique constraint

## 5.29.0

### Minor Changes

- b0b2d13: Adds BAC's first Metadata_Sync migration plus a Person.DisplayName computed column so consumers get correct seed data and friendly entity display names

## 5.28.0

### Minor Changes

- b61bb46: Upgrade MJ to 5.33.0, regenerate BAC's CRUD sprocs with v5.33 tolerant signatures, and enable cascade deletes on Organizations.

## 5.27.1

### Patch Changes

- fa421da: Move `@memberjunction/*` and `@angular/*` deps to peerDependencies so consuming MJ apps resolve a single instance and avoid duplicate singletons.

This log was last generated on Sun, 14 Apr 2024 15:50:05 GMT and should not be manually modified.

<!-- Start content -->

## 1.0.3

Sun, 14 Apr 2024 15:50:05 GMT

### Patches

- Bump @memberjunction/core to v1.0.9
- Bump @memberjunction/global to v1.0.9

## 1.0.2

Sat, 13 Apr 2024 02:32:44 GMT

### Patches

- Update build and publish automation (craig.adam@bluecypress.io)
- Bump @memberjunction/core to v1.0.8
- Bump @memberjunction/global to v1.0.8
