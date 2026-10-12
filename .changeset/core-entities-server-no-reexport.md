---
"@mj-biz-apps/common-core-entities-server": patch
"@mj-biz-apps/common-server": patch
---

`@mj-biz-apps/common-core-entities-server` no longer re-exports `LoadActivitySyncEngine` and no
longer depends on `@mj-biz-apps/common-activity-sync`. Import `LoadActivitySyncEngine` from
`@mj-biz-apps/common-activity-sync`, as `@mj-biz-apps/common-server` now does. Startup behaviour is
unchanged.
