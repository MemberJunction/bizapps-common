---
'@mj-biz-apps/common-entities': minor
---

`Metadata_Sync` for the Activity Sync release — the metadata that makes 5.37.0 actually run.

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
