---
"@mj-biz-apps/common-entities": patch
---

People and Organization pickers can now answer in milliseconds on large databases instead of timing
out. Every column the curated user search uses now has an index, People no longer search the
computed PrimaryEmail column (Email still matches exactly), and the People and Organizations views
join addresses in a way SQL Server can index. On a 1.2M-person database a lookup for a rare name
went from 15-19 seconds to under 5 ms once the curated search configuration is applied, which ships
in this release's Metadata_Sync.
