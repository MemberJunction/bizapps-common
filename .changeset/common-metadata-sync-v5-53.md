---
'@mj-biz-apps/common-entities': minor
---

The 5.53 Metadata_Sync ships the 15 CHECK-constraint validators pinned in metadata/generated-codes since 5.52, so a host that upgrades by migration gets the same validator rows as one that ran `mj sync push`. It has a Postgres counterpart. Field-level security for People stays held back, as in 5.48 and 5.51.
