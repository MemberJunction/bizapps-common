---
"@mj-biz-apps/common-entities": minor
---

Release seed for the Job Function and Seniority scope filter: `V…__v5.65.x__Metadata_Sync` updates the "Job Function and Seniority Derivation" record process's ScopeFilter to the `ID NOT IN (SELECT PersonID …)` form, by ID and only when the record process exists. It has a Postgres counterpart.
