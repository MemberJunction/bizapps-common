---
"@mj-biz-apps/common-entities": patch
"@mj-biz-apps/common-actions": patch
"@mj-biz-apps/common-ng": patch
"@mj-biz-apps/common-server": patch
---

Move `@memberjunction/*` and `@angular/*` deps to peerDependencies so consuming MJ apps resolve a single instance and avoid duplicate singletons.
