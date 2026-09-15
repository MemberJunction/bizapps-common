---
"@mj-biz-apps/common-entities": minor
---

The business time zone, and calendar-day helpers every BizApp shares (bc-aidp-next-golive#168).

`Order Date` defaulted to the UTC calendar day, so an order entered after 7 PM Central was dated
tomorrow; the accounting journal-entry draft used the browser's local day; every view compared
against `CAST(GETUTCDATE() AS date)`, so a contract ending December 31 read as expired at 7 PM
Central on the 31st. Each app had its own copy of the same date arithmetic.

One instance configuration row, `BizApps.BusinessTimeZone`, holds the zone the business books in
(IANA name for code, Windows name for SQL Server). `BusinessTimeZoneEngine` caches it on client and
server and answers `Today()` in that zone, falling back to UTC when the row is unset. `business-day.ts`
is the one implementation of calendar-day parsing, formatting and arithmetic: a `DATE` column is read
from its UTC parts and written as UTC midnight, exactly as MJ's own form field does. The migration
seeds the row empty (the host sets it) and defines `fnBusinessToday()` in the common schema, an
inline table-valued function every app's views cross join for "today".
