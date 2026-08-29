---
'@mj-biz-apps/common-entities': minor
'@mj-biz-apps/common-ng': minor
---

Activity Sync Engine P2 — CodeGen objects, generated types, and provider-type seeds.

Folds entity metadata, views, and CRUD for the seven new Activity Sync tables into
`V202608292220__v5.37.x__ActivitySync_CodeGen_Objects.sql`. Seeds Microsoft365, Gmail, Zoom,
and Generic as metadata (not INSERTs in a migration), with `DefaultQualificationPolicy=Exclude`
on the mailbox-shaped types.
