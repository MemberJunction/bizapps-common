---
'@mj-biz-apps/common-entities': minor
---

The 5.54 Metadata_Sync ships the name-field settings for Addresses, Relationships, Address Links and People (6 Entity Fields) and pins Address Links as not geocoded, so a host that upgrades by migration gets the same metadata as one that ran `mj sync push`. The five 5.54 schema migrations and the Metadata_Sync now have Postgres counterparts. Field-level security for People stays held back, as in 5.48, 5.51 and 5.53.
