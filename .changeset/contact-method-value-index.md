---
"@mj-biz-apps/common-entities": minor
---

Add index `IX_ContactMethod_Value` on `ContactMethod.Value` (SQL Server and PostgreSQL), so Activity Sync's address lookup (`Value IN (...)` on `vwContactMethods`) seeks instead of scanning the table.
