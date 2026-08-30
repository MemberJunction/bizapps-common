---
'@mj-biz-apps/common-activity-sync': minor
'@mj-biz-apps/common-server': minor
---

Activity sync trigger, calendar companion as data, and per-connection health.

Seeds Common.SyncActivities (Action, Limit, result codes, hourly job) as JSON.
CalendarDriverClass on ActivitySyncProviderType drives the companion surface through
ClassFactory. Connection health is stamped once from combined surfaces. A failed
connection list load is ERROR, not NO_CONNECTIONS.
