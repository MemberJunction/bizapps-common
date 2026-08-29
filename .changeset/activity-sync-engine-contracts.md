---
'@mj-biz-apps/common-activity-sync': minor
---

Activity Sync Engine — provider plugin contracts and the provider-type/extension schema.

Adds `@mj-biz-apps/common-activity-sync` with the `BaseActivitySyncProvider` plugin base class,
the qualification cascade (deterministic stages first, inference last — enforced, not documented),
and `BaseActivitySyncExtension`, the in-process contract a downstream app implements to add links
to an Activity inside its own write transaction.

Adds a migration turning two things that were code into data: `ActivitySyncProviderType` replaces
`CK_ActivitySyncConnection_Provider`, so a new source is a plugin package plus a metadata row
rather than a migration to Common; and `ActivitySyncExtension` registers enrichment plugins that
consumer apps ship rows for.

Design: `plans/activity-sync-engine.md`.
