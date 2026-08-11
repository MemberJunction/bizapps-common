---
"@mj-biz-apps/common-core-entities-server": patch
---

Import UserCache from @memberjunction/generic-database-provider — MJ #3734 moved it out of @memberjunction/sqlserver-dataprovider with no re-export, so this package failed to compile against MJ next. Peer dependency swapped accordingly (PersonEntityServer was the only sqlserver-dataprovider usage). Requires the first MJ edge release that carries #3734.
