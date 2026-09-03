---
"@mj-biz-apps/common-actions": patch
"@mj-biz-apps/common-activity-sync": patch
"@mj-biz-apps/common-ng": patch
"@mj-biz-apps/common-core-entities-server": patch
"@mj-biz-apps/common-entities": patch
"@mj-biz-apps/common-server": patch
---

License declarations now agree on BUSL-1.1 everywhere.

`LICENSE`, `package.json`, `mj-app.json` and every workspace package already declared
BUSL-1.1. Two statements still said ISC: the README badge, which is the first license
statement a reader meets and so outranked all of them in practice, and the `mj-app.json`
sample in `docs/open-app.md` — this repo is the reference Open App, so that snippet is
copied into new repos and is how the wrong value spreads. The badge now links to `LICENSE`.
