---
"@mj-biz-apps/common-ng": minor
---

Directory dashboard: the page no longer hangs on "Loading the directory…". The two grids show as soon as their views load and the count cards say "Counting…" until the summary arrives; a failed or thrown load ends its loading state. The summary query runs in about 9 seconds instead of 45–70 on a 1.3M-person directory: the people-added bars move to a new query, Common: Directory People Per Day, because their non-inlinable business-day function made the whole statement single-threaded, and people without an organization are counted with NOT EXISTS instead of through vwPeople's per-row OUTER APPLY.
