# @mj-biz-apps/common-ng

## 5.34.0

### Minor Changes

- 2c8c1bc: Address/contact widgets: MJ design tokens, two field-population bugs, and the layered base views that make the Primary Address panel work at all.

  **Design tokens.** All four shared widgets (address editor, contact method list, relationship list, org hierarchy tree) predate MJ's token system and hardcoded 191 colour values, so they were unreadable in dark mode — dark grey label text on a dark surface, and white form-input backgrounds. Every value now maps to a semantic token (`--mj-text-*`, `--mj-bg-surface*`, `--mj-border-*`, `--mj-status-*`), with translucent tints via `color-mix()` so they adapt too. Note that 8 of these were CSS _keyword_ colours (`background: white`) rather than hex — MJ's `check:ui-tokens` gate only scans hex/rgb/hsl, so those would not have been caught by it, and they were the ones most visibly breaking dark mode.

  **Postal-code lookup never filled the state box.** The Postal Code Lookup action returns its `Message` as the raw `ProviderGeocodeResult`, whose field is `StateProvinceCode` / `StateProvinceName`; there is no `State` on that shape (`State` exists only as a separate Output param). Reading `address.State` was therefore always `undefined` — City worked purely because that name happens to match. Now reads `StateProvinceCode ?? StateProvinceName ?? State`.

  **Mailing addresses showed a blank icon.** The seed data used `fa-solid fa-mailbox`, which is Font Awesome **Pro**; the bundled set is Free, so the browser matched no rule and rendered an empty square. The existing `|| fallback` could not help because the class was non-empty, just unrenderable. Corrected the seed to `fa-solid fa-envelope`, and added `resolveIconClass()`, which also falls back for blank, whitespace-only, style-only (`fa-solid` alone) and known Pro-only classes.

  **Primary Address panel was empty on every record.** The Person and Organization forms bind to `PrimaryAddressLine1` / `City` / `State` / `PostalCode` / `Country` / `Type`, which only ever existed on the hand-written `vwPeopleExtended` / `vwOrganizationsExtended` — archived, and present in no current database. This completes the move to MJ layered base views planned in 35bb1fa and unblocked by MJ#3419: CodeGen now generates everything mechanical under `vwPeopleGenerated` / `vwOrganizationsGenerated`, and this app owns a thin `SELECT g.*, <enriched columns>` wrapper. The 14 layered columns register as virtual `EntityField`s, so the forms populate with no template change. Both wrappers expose a superset of the previous base views — no column is lost, and foreign keys added later gain their display fields automatically instead of silently going missing.

  While porting the archived view, one bug was found and not carried over: it resolved the polymorphic `AddressLink` with `WHERE [Name] = 'MJ.BizApps.Common: People'` — dotted. That subquery returns NULL, so the join matched nothing and every address column came back NULL. Restoring those views as-written would have produced the same empty panel, looking exactly like "this person has no primary address".

### Patch Changes

- cefafed: Fix address editor: adding an address failed with a SQL uniqueidentifier conversion error.

  `person-form` and `organization-form` passed the address editor a DOTTED entity name
  (`MJ.BizApps.Common: People`). The authoritative prefix is UNDERSCORED —
  `MJ_BizApps_Common: `, as declared in this repo's own `metadata/schema-info/.schema-info.json`
  — so the lookup missed and `loadData()` returned early, leaving both `resolvedEntityID` and
  `AddressTypes` empty. The editor still rendered an editable form, so saving sent empty strings
  into `AddressLink.EntityID` and `AddressLink.AddressTypeID` (both NOT NULL uniqueidentifier),
  and the insert died at the database with "Conversion failed when converting from a character
  string to uniqueidentifier". This is the same dots-vs-underscores mistake that took down ORDER
  CONFIRM in bizapps-orders (corrected there 2026-08-03); these two templates were the last live
  instances in the estate.

  Also hardens the component so a bad `EntityName` can no longer reach the database:

  - resolve via `Metadata.EntityByName()` rather than `Entities.find(e => e.Name === …)` — the
    MJ-documented lookup, case- and whitespace-insensitive and O(1); the strict equality check is
    what turned a near-miss into a total miss
  - a new `LoadError` state renders the misconfiguration in the UI instead of console-only
  - `onSave()` refuses to save when the entity or the address type is unresolved, naming which

- Updated dependencies [2c8c1bc]
- Updated dependencies [ab9f88e]
- Updated dependencies [2f8dd2b]
  - @mj-biz-apps/common-entities@5.34.0

## 5.33.2

### Patch Changes

- Updated dependencies [c2974b6]
  - @mj-biz-apps/common-entities@5.33.2

## 5.33.1

### Patch Changes

- Updated dependencies [6eae25b]
  - @mj-biz-apps/common-entities@5.33.1

## 5.33.0

### Minor Changes

- 2c33643: Decouple Person from MJ User (fixes #36): saving a Person no longer provisions, links, syncs, or deactivates MJ User accounts. `PersonEntityServer` is reduced to a deprecated compatibility shell (protected helpers retained for downstream subclasses); the `LinkedUserID` EntityField is marked Status='Deprecated' via migration; the People entity is declared an overlapping IS-A parent (`AllowMultipleSubtypes=1`) so platform layers (e.g., BCSaaS 'BC: People') can own the person-to-user binding as an IS-A subtype. The LinkedUserID column remains physically in place; data disposition is owned by the platform layer's migration. The custom Person form no longer renders LinkedUserID.

### Patch Changes

- Updated dependencies [1ffb2a5]
  - @mj-biz-apps/common-entities@5.33.0

## 5.32.0

### Minor Changes

- b5f34d2: PG fixes for CanonicalSchema and CodeGen

### Patch Changes

- Updated dependencies [b5f34d2]
  - @mj-biz-apps/common-entities@5.32.0

## 5.31.3

### Patch Changes

- 5346c70: Upgraded BAC to MJ 5.44; PostgreSQL install verified, seeds fixed.
- Updated dependencies [5346c70]
  - @mj-biz-apps/common-entities@5.31.3

## 5.31.2

### Patch Changes

- 969954b: fix(common): lowercase PostgreSQL app schema name in migrations to match physical schema
- Updated dependencies [969954b]
  - @mj-biz-apps/common-entities@5.31.2

## 5.31.1

### Patch Changes

- @mj-biz-apps/common-entities@5.31.1

## 5.31.0

### Minor Changes

- 64200c7: Added PG support and MJ upgrade to 5.40.2

### Patch Changes

- Updated dependencies [64200c7]
  - @mj-biz-apps/common-entities@5.31.0

## 5.30.1

### Patch Changes

- Updated dependencies [a46ab44]
  - @mj-biz-apps/common-entities@5.30.1

## 5.30.0

### Patch Changes

- Updated dependencies [49d5b9c]
  - @mj-biz-apps/common-entities@5.30.0

## 5.29.0

### Minor Changes

- b0b2d13: Adds BAC's first Metadata_Sync migration plus a Person.DisplayName computed column so consumers get correct seed data and friendly entity display names

### Patch Changes

- Updated dependencies [b0b2d13]
  - @mj-biz-apps/common-entities@5.29.0

## 5.28.0

### Minor Changes

- b61bb46: Upgrade MJ to 5.33.0, regenerate BAC's CRUD sprocs with v5.33 tolerant signatures, and enable cascade deletes on Organizations.

### Patch Changes

- Updated dependencies [b61bb46]
  - @mj-biz-apps/common-entities@5.28.0

## 5.27.1

### Patch Changes

- fa421da: Move `@memberjunction/*` and `@angular/*` deps to peerDependencies so consuming MJ apps resolve a single instance and avoid duplicate singletons.
- Updated dependencies [fa421da]
  - @mj-biz-apps/common-entities@5.27.1
