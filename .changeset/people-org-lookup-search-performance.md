---
"@mj-biz-apps/common-entities": patch
---

People and Organization pickers now answer in milliseconds on large databases instead of timing
out. The search settings curated in 5.44 now reach installed databases (they previously lived only
in metadata, which upgrades do not apply), People no longer search the computed PrimaryEmail column
(Email still matches exactly), every searched column has an index, and the People and Organizations
views join addresses in a way SQL Server can index. On a 1.2M-person database a lookup for a rare
name went from 15-19 seconds to under 50 ms.
