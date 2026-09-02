---
'@mj-biz-apps/common-entities': minor
'@mj-biz-apps/common-server': minor
'@mj-biz-apps/common-ng': minor
---

Fold CodeGen output for ActivitySyncProviderType.CalendarDriverClass into V202608301900.

Hand DDL is the ALTER TABLE only. Microsoft365's CalendarDriverClass value stays in
metadata JSON. CodeGen SQL (EntityField, view, spCreate/spUpdate/spDelete, trigger)
is appended after the standard banner.
