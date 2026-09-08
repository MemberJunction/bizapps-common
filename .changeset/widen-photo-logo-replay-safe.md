---
"@mj-biz-apps/common-entities": patch
---

Replay-safe PhotoURL/LogoURL NVARCHAR(MAX) migration: DDL only, then inlined R__RefreshMetadata, then CodeGen emit authored while EntityField.Length still showed the old size so Person/Org CRUD procs pick up MAX.
