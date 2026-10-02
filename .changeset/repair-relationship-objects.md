---
'@mj-biz-apps/common-entities': minor
---

Repair `vwRelationships`, `spCreateRelationship` and `spUpdateRelationship` on hosts where bizapps-forms (up to 0.14.x) replaced them with stale copies (#219).

On those hosts every `MJ_BizApps_Common: Relationships` save failed with `@JobFunctionID is not a parameter for procedure spCreateRelationship`, and `vwRelationships` had no `JobFunction` or `SeniorityLevel` column. A new migration re-creates the three objects at their current definitions. On an undamaged host it replaces each with an identical copy.
