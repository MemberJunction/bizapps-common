# @mj-biz-apps/common-ng

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

### Patch Changes

- Updated dependencies [12a6de8]
- Updated dependencies [2f28572]
  - @mj-biz-apps/common-entities@5.46.0

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

### Patch Changes

- Updated dependencies [868b125]
  - @mj-biz-apps/common-entities@5.45.0

## 5.44.0

### Minor Changes

- 549a57e: Add the shared BizApps "Related records" chip row: `bizapps-related-chips`.

  A tester walking Deal → Order → Contract found no consistent way to get from a record to the
  records linked to it. The Contract header linked its source Deal, the Deal form buried its Order
  in a panel, the Order form pointed at nothing, and where a link did exist it sometimes rendered a
  GUID instead of a name. Each app had solved a slice of it differently; this is the one they
  collapse into.

  A caller passes link descriptors naming an entity and either the id it holds (`RecordID`) or a
  filter that finds the record holding the id (`Filter`, for a reverse link such as Order → Deal).
  The component resolves the entity, reads the record's name, and decides whether the chip may be
  drawn at all.

  Three behaviours it guarantees, and the reason each is behaviour rather than styling. **A chip
  never shows a raw id** — the name comes from the entity's name field, and an entity with no name
  field produces no chip rather than a GUID wearing a label. **A chip that cannot navigate is not
  rendered** — an entity missing from the catalog (the app is not installed here, or this user may
  not read it, which are deliberately one outcome), a read that succeeded while matching zero rows,
  and a read the server answered with `Success: false` all produce nothing, because a link that goes
  nowhere is worse than an absent one. **A read that THREW is not a read that was refused** — the
  line is whether the server answered. `Success: false` is MJ's channel for a permission denial as
  much as for a bad filter, so it drops the chip; a throw means the request never got an answer, so
  it keeps the chip when the link already carried the id to open.

  Clicking a chip emits a `record` navigation event; ctrl or cmd-click sets `OpenInNewTab`, and a
  plain click OMITS it rather than sending `false` — `NavigationService.shouldForceNewTab` honours
  any defined `forceNewTab` and only otherwise consults its global shift-key state, so an explicit
  `false` would disable shift-click. The component never touches `NavigationService` — a host form
  wires `Navigate` to its own `OnFormNavigate`, which keeps it usable from a `BaseFormPanel` hero and
  a form component override alike.

  Styles are the component's own, design tokens only, under a `bizapps-related` class prefix that
  collides with none of the app kits, which are global under `ViewEncapsulation.None`.

  `Links` and `Provider` are both setters that queue a single re-resolve on the next microtask, and
  the row clears before it re-reads. Angular assigns bound inputs in template order, so a resolve
  kicked off synchronously from the `Links` setter would read `Provider` as `null` and silently fall
  back to the ambient `Metadata.Provider`; and a row that kept the previous record's chips while the
  new reads ran would offer a click that navigates to the record the reader just left.

  The resolve-and-hide rules live in `related-links.ts` rather than in the component, so they can be
  tested without standing up Angular DI: `ResolveRelatedChip`, `FilterForRelatedLink`,
  `LabelForRelatedLink` and `RelatedChipNavigation` are exported alongside the component.

### Patch Changes

- e0c5680: Directory dashboard now renders the shared `bizapps-stat-tile` instead of its own tiles.

  The page carried a fifth near-copy of the dashboard tile — same label/value/detail structure, same
  tokens, same hover rule as the shared component, and living in the same package that exports the
  replacement, which made it the copy most likely to drift.

  Two things were not a mechanical swap:

  `Clickable` is now passed explicitly on every tile. Two of the four were real buttons and two were
  inert `div`s, and the component's default inference — "is anything listening to `Clicked`" — cannot
  tell them apart, because a template binding counts as a subscriber whatever its handler does. The
  two inert tiles pass `[Clickable]="false"` and stay unfocusable, with no `role` and no pointer.

  The Gaps tile's whole-tile alert is now `Tone="warn"` on the value. The shared component colours the
  number only, so the tinted background and amber border are gone. Note that in dark theme
  `--mj-status-warning-text` resolves to `--mj-color-warning-100` (`#fef3c7`), which sits very close to
  the primary text colour on `--mj-bg-surface` — the warn tone reads clearly in light theme but is
  faint in dark. That is a property of the status token ramp, not of this page.

  Responsive behaviour changes below 1200px: the page's own breakpoints dropped the row to 2 columns
  and then 1, while the shared row keeps 4 columns down to 808px and reflows from there. Desktop width
  is unchanged.

  A failed summary read now shows em dashes, not zeros. The four counts were plain `number` fields
  defaulting to `0`, so when `Common: Directory Dashboard Summary` failed the page rendered "0 people,
  0 organizations, 0 gaps" — the exact false reassurance the tile's null rule exists to prevent. They
  are now one `DirectoryHeadline` value built by `BuildDirectoryHeadline`, which returns `null` for
  every count on a failed read and a sentence for `bizapps-stat-row`'s previously unbound `Error`
  input. The counts come from a single query, so the headline is all-or-nothing by construction —
  there is no state in which some of the numbers are trustworthy and others are not. An unread gap
  count also stays `Tone="none"`: "we could not check" must not read as "there is something to fix".

  The three cards fed by that same read no longer claim success when it fails. "Needs someone" and
  "Worth a look" showed a green check over an unread directory, "Organization types" said "No
  organizations yet", and "People added" drew an empty element still labelled as a seven-day chart —
  all four from the same empty arrays the failed read leaves behind. `DirectoryHeadline` now carries
  `ReadFailed`, and each section consults it before reporting itself empty: a list that is empty
  because nothing was read is not "nothing to do".

- Updated dependencies [7056463]
  - @mj-biz-apps/common-entities@5.44.0

## 5.43.0

### Minor Changes

- b2a310b: Require the MemberJunction release this branch actually needs, in every package that asks for it.

  The calendar transport compiles against `GetEvents`, which `6.1.0-edge.5` does not carry, so the
  declared range moved to `^6.1.0-edge.6` across the workspace. Three published packages took that
  bump without a changeset naming them — `common-actions`, `common-ng` and
  `common-core-entities-server` — so they would never have versioned, and the raised floor would
  never have reached npm. A consumer installing them would resolve a MemberJunction that cannot
  satisfy their own dependency range.

  `mj-app.json`'s `mjVersionRange` moves with them, from `>=6.1.0-edge.5` to `>=6.1.0-edge.6`. It is
  the manifest `mj app install` checks, and leaving it behind meant a host sitting on exactly edge.5
  satisfied the manifest and then failed to install.

### Patch Changes

- 41b12f2: Angular — `ng-graph-view` and `ng-hierarchy-tree` were regular dependencies, so every consumer got a second copy of MJ.

  `@mj-biz-apps/common-ng` declared `@memberjunction/ng-graph-view` and `@memberjunction/ng-hierarchy-tree` under
  `dependencies`. Every other MJ package this library consumes — eleven of them, including `ng-base-forms`,
  `ng-entity-viewer` and `core-entities` — is a peer. These two were the exception, and `ng-graph-view` was in fact
  listed in _both_ sections.

  **A published Angular library must not depend on MJ directly.** A peer says "the host supplies this"; a dependency
  says "install your own." For MJ that difference is not cosmetic: a second physical copy of an MJ package means a
  second `MJGlobal` class registry and a second set of Angular component/DI tokens, so `@RegisterClass` lookups and
  `instanceof` checks silently resolve against the wrong copy. The failure surfaces far from the cause — a component
  that renders blank, or a registration that "already exists" — which is exactly the class of bug the peer convention
  across the other eleven packages exists to prevent.

  **This was reachable, not theoretical.** Both packages are imported at runtime: `ng-graph-view` by
  `common-relationship-graph.component.ts`, and `ng-hierarchy-tree` by `org-hierarchy-tree.component.ts`,
  `activity-hierarchy.panel.ts` and `activity-type-hierarchy.panel.ts`. A host on a different 6.1.x patch than the one
  npm resolved for the nested copy would get two, and npm is free to nest rather than dedupe whenever the host's
  resolved version differs from the declared range.

  `ng-hierarchy-tree` is added to `peerDependencies` at the same `^6.1.0-edge.6` range the rest of the package already
  uses; `ng-graph-view` simply loses its duplicate `dependencies` entry and keeps the peer it already had. The
  internal `@mj-biz-apps/common-entities` pin stays a real dependency — it is a sibling released in lockstep, not a
  host-supplied package.

  **No version ranges were changed.** `^6.1.0-edge.6` already admits 6.1.2 (`semver.satisfies('6.1.2',
'^6.1.0-edge.6')` is `true`), and `ci/sync-mj-app-version.mjs` documents the retained `-edge.N` suffix as
  deliberate — it states the floor the code actually needs, since the package imports `MJCard*` components that first
  appeared in `6.1.0-edge.3`. Stripping it is recorded there as a previously-reverted mistake, so it is left alone.

  Verified by building `@mj-biz-apps/common-ng` before and after the change against an identical tree: three
  pre-existing `TS2345` errors in both runs, none of them new. Those three are a local-environment artifact — the
  globally linked `@memberjunction/cli` symlink resolves a second `@memberjunction/*` tree out of the MJ checkout, so
  `FormNavigationEvent` has two declarations. That duplication is itself the same hazard this change removes from the
  published manifest.

- Updated dependencies [23b6827]
- Updated dependencies [ec6fab7]
  - @mj-biz-apps/common-entities@5.43.0

## 5.42.0

### Minor Changes

- b61b440: Add the shared BizApps dashboard stat tile: `bizapps-stat-tile` and `bizapps-stat-row`.

  Orders grew the first version of this tile and the other apps each grew a near-copy; this is
  the one they collapse into. It is a rewrite rather than a move — Orders' version rendered
  `class="mj-stat"` with every rule living in `orders-kit.css`, so copied into another app it
  rendered as three unstyled spans. Styles are now the component's own, design tokens only, under
  a `bizapps-stat` prefix that collides with neither `.mj-stat` (orders-kit) nor `.mjc-stat`
  (contracts-kit).

  Two behaviours the tile guarantees. A `null` or `undefined` value renders an em dash rather
  than `0`, so an unreadable count can never read as an empty queue — a real `0` still renders
  as `0`. And a tile that does nothing is not focusable, not announced as a button and not
  keyboard-activatable: the `Clickable` input decides, and when it is unset the tile falls back
  to whether anything subscribes to `Clicked`. Passing `Clickable` overrides that inference in
  both directions, which a row mixing live and inert tiles needs — Angular subscribes to an
  output whenever a template binds it, whatever the handler expression later evaluates to.

  `bizapps-stat-tile` takes `Label`, `Icon`, `Value`, `Detail`, `Tone` and `Clickable`, and emits
  `Clicked`. `bizapps-stat-row` takes `Error` and renders the row's one shared error line.

### Patch Changes

- @mj-biz-apps/common-entities@5.42.0

## 5.41.0

### Patch Changes

- Updated dependencies [783936a]
- Updated dependencies [7d94d43]
  - @mj-biz-apps/common-entities@5.41.0

## 5.40.0

### Minor Changes

- 06ea2b3: Directory dashboard Latest People / Latest Relationships and the People and Organizations resources use `mj-entity-viewer` bound to stored User Views (`Common: People directory`, `Common: Latest people`, `Common: Organizations directory`, `Common: Latest relationships`) with PhotoURL / LogoURL in GridState.

### Patch Changes

- 5994721: Directory dashboard tiles use MJ Query Common: Directory Dashboard Summary (COUNT over the whole party file) instead of counting a RunView MaxRows=1000 snapshot. Latest people/relationships viewers use entity-viewer chrome: embedded so Filter records and the extra grid Search box are gone.
- cd879e6: Classify People.PhotoURL and Organizations.LogoURL as EntityField.ExtendedType=Image and lock AutoUpdateExtendedType so CodeGen cannot revert them to URL. mj-entity-viewer and ng-base-forms then render thumbnails / image upload from metadata.
- Updated dependencies [e21b2db]
- Updated dependencies [b4387e4]
- Updated dependencies [dc7693c]
- Updated dependencies [22f6624]
  - @mj-biz-apps/common-entities@5.40.0

## 5.39.0

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
