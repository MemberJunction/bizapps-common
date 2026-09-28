---
"@mj-biz-apps/common-entities": patch
---

Add `ExternalFieldLimitEngine`: reads the field lengths of external systems (Business Central, BILL and other connectors) from `MJ: Integration Object Fields`, returns the smallest limit across the fields a value feeds, and builds a rejection message naming the field and the limit. Apps use it to reject over-long values on save and before sending, instead of failing later at sync. A target with no recorded length is an error, not a pass.
