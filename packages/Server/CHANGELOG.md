# @mj-biz-apps/common-server

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
