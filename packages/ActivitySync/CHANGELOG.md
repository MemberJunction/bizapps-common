# @mj-biz-apps/common-activity-sync

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
