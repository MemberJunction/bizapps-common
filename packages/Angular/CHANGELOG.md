# @mj-biz-apps/common-ng

## 5.38.0

### Patch Changes

- Updated dependencies [4c27078]
- Updated dependencies [4c27078]
  - @mj-biz-apps/common-entities@5.38.0

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

### Patch Changes

- Updated dependencies [d73a3af]
- Updated dependencies [d73a3af]
- Updated dependencies [d73a3af]
  - @mj-biz-apps/common-entities@5.37.0

## 5.36.0

### Minor Changes

- 60804ac: Ship CodeGen entity metadata, base views, and CRUD procedures for the six Activity tables introduced in V202608171935. A clean migrate previously left those tables without \_\_mj.Entity rows, so metadata sync of activity-types failed.
- 6fe1f09: Register the Activity related-name virtual EntityFields on Activity Links and Activity Files so save-capture ResultTables match the base views. Also covers the consumer-blind CodeGen V (no Orders in Common), Organizations CascadeDeletes off, and Activity Types hierarchy virtuals.

### Patch Changes

- Updated dependencies [60804ac]
- Updated dependencies [6fe1f09]
  - @mj-biz-apps/common-entities@5.36.0

## 5.35.1

### Patch Changes

- eac151e: Declare BUSL-1.1 in mj-app.json. The LICENSE file and every package already
  state BUSL-1.1; the manifest still said ISC, so anything reading it saw the
  wrong license.
- Updated dependencies [eac151e]
  - @mj-biz-apps/common-entities@5.35.1

## 5.35.0

### Minor Changes

- 6ce1aaf: Add the Common Explorer application (Directory / People / Organizations) and an operational directory dashboard: cheap counts, gap queues, recent people, organization-type mix, and list pages that open records.
- 07e27b6: Add interactive CommonRelationshipGraphComponent with on-demand expansion, add Relationship Graph navigation tab to Common application metadata, add list/graph toggle to Person and Organization relationship panels, and register Application Roles metadata for UI and Developer roles.
- 0e33a0c: Enhance RelationshipList with full-width native link field search and dedicated Add/Edit form card; enable collapsing hero headers during form EditMode to maximize vertical workspace; persist graph layout and zoom preferences via UserInfoEngine.

### Patch Changes

- 32c72f6: feat(common-ng): add interactive visual org chart to OrgHierarchyTree with UserInfoEngine persistence

  - Upgrades `OrgHierarchyTreeComponent` to support switching between an interactive **Visual Org Chart Canvas** (powered by `@memberjunction/ng-hierarchy-tree`) and the classic Outline list.
  - Integrates user preference persistence via `UserInfoEngine` (`'mj.orgHierarchy.viewMode'`).
  - Supports smooth pan, zoom, auto-fit, and direct navigation to parent/subsidiary organization records.

- bba54cb: Restyle Person/Org identity headers to match the payment card: compact surface, badge row, and a metric strip. PhotoURL / LogoURL already replace initials when set.
- c638c00: Person and Organization identity headers stack edit fields as labeled columns. Each field is wrapped so mj-form-field's display:contents cannot leak into a parent grid. Two-across only when the hero is at least 52rem wide; URLs and description still span the full row.
- 4b4bcaa: Stop overriding generated People and Organization forms. Address, contact-method, relationship, and org-hierarchy widgets register as BaseFormPanel contributions. Identity heroes (`contributionKey: 'header'`) replace the Personal Identity / Organization Identity field panels so verticals can last-win the same key (Orders adds stats without forking the form).
- cbd0e27: Add RelatedRecordCollection metadata configuration for People and Organizations (Contact Methods, Relationships, Child Organizations) and synchronize CodeGen output.
- 99efae7: Relationship list fills leftover left-nav height without parking its header mid-column. Type lookup is UUID-normalized so links still render when ID casing differs, and the empty state says there are no relationships instead of a blank panel.
- Updated dependencies [1f07f2a]
- Updated dependencies [026b83e]
- Updated dependencies [4b4bcaa]
- Updated dependencies [cbd0e27]
  - @mj-biz-apps/common-entities@5.35.0

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
