---
"@mj-biz-apps/common-server": patch
"@mj-biz-apps/common-activity-sync": patch
---

`Common.LogActivity` now writes on its own provider instance instead of the process-global one, so
its transaction no longer captures other callers' queries, such as scheduled jobs or form hooks
(#195). The People and Organizations bindings now pass `RecordID` in place of `RecordData`.
Durable dispatch always strips `RecordData` from the task payload, which left those bindings
unable to link the activity to its record (#197).
