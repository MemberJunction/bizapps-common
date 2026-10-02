---
"@mj-biz-apps/common-ng": patch
---

Relationship dates no longer move a day on their own (MemberJunction/bc-aidp-next-golive#168).
StartDate and EndDate are `date` columns that arrive as UTC midnight. The relationship list's Edit
form read them with local getters, so west of UTC it showed the previous day and saving the form,
even untouched, stored that earlier day: every save moved both dates back one. It now reads the
stored day. Ending a relationship stored `new Date()`, whose UTC day is already tomorrow on an
American evening; it now stores today in the business time zone (`BusinessTimeZoneEngine`).
