---
"@mj-biz-apps/common-entities": patch
"@mj-biz-apps/common-ng": patch
---

Export mjBizAppsCommonAddressLinkFormComponent in @mj-biz-apps/common-ng public-api for clean manifest/chunk resolution, and configure @RegisterForStartup({ deferred: typeof window !== 'undefined' }) on BusinessTimeZoneEngine in @mj-biz-apps/common-entities to defer browser startup initialization off the critical first-paint path.
