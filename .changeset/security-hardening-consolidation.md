---
"@mj-biz-apps/common-server": patch
"@mj-biz-apps/common-activity-sync": patch
"@mj-biz-apps/common-entities": patch
"@mj-biz-apps/common-ng": patch
---

Consolidated security hardening across server actions, activity sync, entity helpers, Angular filters, and release workflow credentials:

- Require `ContextUser` in `Common.SyncActivities` (`SyncActivitiesAction`) returning `VALIDATION_ERROR`, matching sibling actions.
- Validate `Links[].EntityName` against `provider.EntityByName` in `ActivityWriter.WriteManual` before opening a write transaction.
- Enforce UUID validation inside `quoteList` in `person-user-link.ts` as defense-in-depth.
- Route `AddressEditorComponent` address IDs and `related-links.ts` through the shared `EscapeFilterValue` helper; document the pre-escaped `filter` contract on `SearchPeople`/`SearchOrganizations`; replace `href="javascript:void(0)"` in `relationship-list` with a `<button type="button">`.
- Harden `.github/workflows/publish.yml` with `persist-credentials: false` on checkout and explicit per-step credentials, minting the GitHub App token only after install/build/publish.
