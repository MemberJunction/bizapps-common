---
"@mj-biz-apps/common-entities": minor
"@mj-biz-apps/common-server": minor
---

`Address.Line1` and `Address.City` are now nullable, so an address row may record a location
(country, region, postal code) before a street line and city are known.

The migration alters both columns to `NULL` (types and lengths unchanged) and updates their column
descriptions. CodeGen regenerates `spCreateAddress` / `spUpdateAddress` with `@Line1_Clear` /
`@City_Clear` parameters, and the generated entity and GraphQL types for `Line1` and `City` become
`string | null`.
