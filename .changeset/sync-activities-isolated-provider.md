---
"@mj-biz-apps/common-server": patch
---

`Common.SyncActivities` now runs on an independent provider instance, released when the run ends,
instead of the process-global `Metadata.Provider`. The writer's per-item transaction, and any
registered `BaseActivitySyncExtension` running inside it, no longer capture queries from unrelated
callers such as the scheduler's lock and release bookkeeping.
