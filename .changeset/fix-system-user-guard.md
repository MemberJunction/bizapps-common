---
"@mj-biz-apps/common-core-entities-server": patch
---

Add system user guards to PersonEntityServer to prevent syncUserRecord and autoLinkUser from modifying the MJ system user record. Change method visibility from private to protected for downstream overridability.
