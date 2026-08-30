---
'@mj-biz-apps/common-activity-sync': minor
'@mj-biz-apps/common-server': minor
---

Entity Action workflow adoption — the Common side (plans/mj-entity-action-workflow-adoption.md).

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
