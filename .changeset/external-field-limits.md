---
"@mj-biz-apps/common-entities": minor
---

Add `ExternalFieldLimitEngine`: reads the field lengths of external systems (Business Central, BILL and other connectors) from `MJ: Integration Object Fields`, returns the smallest limit across the fields a value feeds, and builds a rejection message naming the field and the limit. Apps use it to reject over-long values on save and before sending, instead of failing later at sync. A target with no recorded length is an error, not a pass.

Configure it with a user who can read `MJ: Integration Objects` and `MJ: Integration Object Fields`; on a server, use the system user. If a user without that access configures it, the next `Config` reloads instead of keeping the empty result, and until a reload succeeds each check says it could not run instead of throwing. Installed metadata changes reach a running server only when `LocalCacheManager` is initialized; otherwise they apply after a restart or `Config(true)`.
