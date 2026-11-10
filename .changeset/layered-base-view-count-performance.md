---
"@mj-biz-apps/common-entities": minor
---

Counting People and Organizations no longer times out. `vwPeople` and `vwOrganizations` now look up
the primary address, primary email and primary phone with `OUTER APPLY (SELECT TOP 1 …)` instead of
`LEFT OUTER JOIN`, so SQL Server skips those lookups in any query that doesn't read them, such as the
`COUNT(*)` MJ runs for every paged list and lookup. On AIDP Next stage, counting People went from
36.8 s to 0.20 s, Organizations from 8.5 s to 0.08 s, and Sales Contacts (built on `vwPeople`) from
15-22 s to 0.05 s.

The views return the same columns and, while no person or organization has two primary rows of one
kind, the same values. If a duplicate primary ever exists, the person or organization now appears
once, with the lowest-ID row, instead of once per combination of primary rows.

Re-cut of #100 by @MS-BC, who found and measured this; it starts from the current v5.48 definitions.
