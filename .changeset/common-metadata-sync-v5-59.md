---
'@mj-biz-apps/common-entities': minor
---

The 5.59 Metadata_Sync ships the UI role's create permission on Activities and Activity Links, finding each host's permission row by entity and role, so a host that upgrades by migration lets a UI-only user log an activity the same way as one that ran `mj sync push`. It has a Postgres counterpart. Field-level security for People stays held back, as in every release since 5.48.
