---
'@mj-biz-apps/common-entities': minor
---

The 5.57 Metadata_Sync ships the Party Lookup Organizations query change and the form and search settings for the new Organizations Acronym field, so a host that upgrades by migration gets the same metadata as one that ran `mj sync push`. It and the Organization_Acronym migration have Postgres counterparts. Field-level security for People stays held back, as in every release since 5.48.
