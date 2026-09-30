---
'@mj-biz-apps/common-entities': minor
---

The 5.48 Metadata_Sync. It turns on field-level security for People (#186) and ships a permission row for each People field and role, so People stays readable the moment the flag is set. It also takes People `PrimaryEmail` and Organization `Website` out of user search (#199), which lets the new lookup indexes answer in milliseconds.
