# Change Log - mj_generatedentities

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
