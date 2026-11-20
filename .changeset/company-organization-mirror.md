---
"@mj-biz-apps/common-entities": minor
"@mj-biz-apps/common-core-entities-server": minor
"@mj-biz-apps/common-server": minor
"@mj-biz-apps/common-ng": minor
---

Add canonical `MJ: Companies` → `MJ_BizApps_Common: Organizations` mirroring via `Organization.LinkedCompanyID` (filtered unique FK symmetric with `Person.LinkedUserID`), server-side `CompanyOrganizationMirrorEntityServer` auto-sync on `MJ: Companies` saves, and the `BizAppsCommon.SyncCompaniesToOrganizations` Remotable Operation for idempotent backfill and drift reconciliation. Also export sandbox consent source classes from `@mj-biz-apps/common-server` for MJ 6.3 class-manifest compatibility.
