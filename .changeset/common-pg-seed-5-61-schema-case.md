---
'@mj-biz-apps/common-entities': minor
---

The 5.61 Metadata_Sync's Postgres counterpart checks the function signature against the schema name as PostgreSQL stores it (`__mj_bizappscommon`). Before, the check never matched, so a host whose functions take only the jsonb signature failed at the first record.
