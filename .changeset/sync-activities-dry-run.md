---
"@mj-biz-apps/common-activity-sync": minor
"@mj-biz-apps/common-server": minor
---

`Common.SyncActivities` takes two optional inputs, `DryRun` and `ConnectionIDs`. A dry run previews what each connection would file without writing an Activity or moving a watermark, and it includes Paused connections. That lets a new mailbox be built Paused, reviewed, and only then set Active. `ConnectionIDs` narrows a run to the named connections and reports each one that did not run. The hourly job passes neither input, so it behaves as before.
