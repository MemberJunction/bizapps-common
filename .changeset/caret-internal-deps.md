---
'@mj-biz-apps/common-ng': patch
'@mj-biz-apps/common-activity-sync': patch
'@mj-biz-apps/common-core-entities-server': patch
'@mj-biz-apps/common-server': patch
---

The packages' dependencies on each other are caret ranges (`^5.53.0`) instead of exact versions. A host that pins or overrides one common package at a later compatible version no longer forces an exact-match copy of its sibling: `common-server` 5.53.0 required `common-activity-sync` at exactly 5.53.0, so a host overriding it at any other version got a second copy or an unresolvable lockfile. Changesets keeps the caret and moves its floor on each release.
