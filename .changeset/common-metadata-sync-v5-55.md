---
'@mj-biz-apps/common-entities': minor
---

Moves to MemberJunction 6.1.6 (`mjVersionRange` `>=6.1.6 <7.0.0`). The 5.55 Metadata_Sync ships People.LinkedUserID as an active, documented field (Status Active, new description, AutoUpdateDescription off), with its Postgres counterpart. SaveReturnMode `datestamps_only` on Activity Sync Runs and Activity Sync Run Details is withdrawn until an MJ release supports it. Field-level security for People stays held back, as in 5.48 through 5.54.
