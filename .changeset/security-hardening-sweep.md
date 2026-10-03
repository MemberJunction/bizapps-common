---
"@mj-biz-apps/common-ng": patch
"@mj-biz-apps/common-server": patch
---

Security hardening sweep: consolidate the Angular tier's four inline SQL-escaping copies onto the shared `EscapeFilterValue` (adds NUL stripping where it was missing), document the trusted-fragment contract on `SearchPeople`/`SearchOrganizations`, add the missing `ContextUser` guard to `Common.SyncActivities`, replace a `javascript:void(0)` href with a button, and harden the release workflows (no persisted write token during install/build, SHA-pinned actions in credential-holding jobs, env-routed base ref in changes.yml).
