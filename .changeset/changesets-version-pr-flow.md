---
'@mj-biz-apps/common-integration-tests': patch
---

Split the release into a version step and a publish step, so neither writes directly to a branch,
and adopt the family's evolved publish gates.

`version.yml` (new, on `next`) turns pending changesets into a reviewable "Version Packages" PR —
bumps, CHANGELOGs, the mj-app.json version and range, and a refreshed lockfile.
`release-readiness.yml` (new) gates the version PR and any PR to `main`. `publish.yml` keeps only
the publish half. Adds the private-package skip to both existing gates plus a third gate requiring
every publishable package to declare `files` and `publishConfig.access`.

Relates to #79: this repo has no branch protection, and the old release flow depended on that.
