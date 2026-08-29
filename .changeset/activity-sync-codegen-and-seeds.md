---
'@mj-biz-apps/common-entities': minor
'@mj-biz-apps/common-ng': minor
---

Activity Sync Engine P2 — CodeGen objects folded into the schema V, plus provider-type seeds.

Entity metadata, views, and CRUD for the seven new Activity Sync tables append under the
banner in `V202608291500` (one migration for the whole schema; no standalone CodeGen V).
Seeds Microsoft365, Gmail, Zoom, and Generic as metadata, with
`DefaultQualificationPolicy=Exclude` on mailbox-shaped types.
