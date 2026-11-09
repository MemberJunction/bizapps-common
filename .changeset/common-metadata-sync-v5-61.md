---
'@mj-biz-apps/common-entities': minor
---

The 5.61 Metadata_Sync ships the Marketing and Transactional consent purposes, the contact types' message types, and Configuration on People, Organizations, Addresses and ten entity relationships, so a host that upgrades by migration gets the same metadata as one that ran `mj sync push`. It and the Contact_Method_Consent migration have Postgres counterparts. Field-level security for People stays held back: the People update keeps the host's EnableFieldLevelSecurity.
