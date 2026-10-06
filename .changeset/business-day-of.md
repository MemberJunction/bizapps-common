---
"@mj-biz-apps/common-entities": minor
---

New SQL function `[__mj_BizAppsCommon].[fnBusinessDayOf](@At DATETIMEOFFSET) RETURNS DATE`, with a
PostgreSQL twin `__mj_bizappscommon."fnBusinessDayOf"(at timestamptz) RETURNS date`
(migration `V202610011930__v5.49.x__Business_Day_Of`; MemberJunction/bc-aidp-next-golive#168). It
returns the calendar day an instant falls on in the business time zone, reading the zone from
`fnBusinessToday()` so the two always agree, and NULL for NULL. Queries use it instead of
`AT TIME ZONE bt.SqlZone`, which MJ's SQL parser cannot parse. A `DATETIME`/`DATETIME2` argument is
read as UTC; do not pass a `DATE` column (west of UTC it comes back a day early).
