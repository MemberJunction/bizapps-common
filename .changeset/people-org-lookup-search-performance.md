---
"@mj-biz-apps/common-entities": minor
---

People and Organization pickers can now answer in milliseconds on large databases instead of timing out. Every column the curated user search uses now has an index, and the People and Organizations views join addresses in a way SQL Server can index. On a restored 1.2M-person AIDP database, a lookup for a rare name went from 15-19 seconds to 2-5 ms (People) and 2-4 ms (Organizations). On PostgreSQL, the prefix-searched columns are indexed with pattern operator classes, so `LIKE 'x%'` can use them under the default collation.

Two matches go away. People search no longer looks at the computed PrimaryEmail, so a person is no longer found by a primary contact-method email that differs from `Person.Email`. `Email` itself still matches exactly. Organization search no longer includes Website: most stored values carry a scheme (`https://...`), which `BeginsWith` never matched, and an unindexed field in the search would force a scan. Both search settings are metadata, so they reach installed databases in the next release Metadata_Sync. The indexes alone don't speed up lookups until that sync is installed.
