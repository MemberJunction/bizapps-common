---
"@mj-biz-apps/common-entities": minor
---

Add `Person.SupervisorPersonID` (nullable self-referential FK with `IDX_AUTO_MJ_FKEY_Person_SupervisorPersonID`), cycle-safe recursive reporting view `vwPersonReportingChain`, `'Reports To'` relationship type metadata, and `SyncEmployeesToPeople` stored procedure/routine across SQL Server and PostgreSQL.
