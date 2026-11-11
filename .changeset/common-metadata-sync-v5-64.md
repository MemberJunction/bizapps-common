---
"@mj-biz-apps/common-entities": minor
---

Release seed for the Directory dashboard fix: `V…__v5.64.x__Metadata_Sync` updates the `Common: Directory Dashboard Summary` query's SQL and adds its result fields, and creates the `Common: Directory People Per Day` query with its fields. The summary update is applied by ID; everything else is create-only, guarded on its ID or key. It has a Postgres counterpart.
