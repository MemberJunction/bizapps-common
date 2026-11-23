---
"@mj-biz-apps/common-entities": patch
"@mj-biz-apps/common-core-entities-server": patch
---

Harden Company → Organization mirror integrity (`LinkedCompanyID`): add pre-create Organization deduplication via `RunView` (`ResultType: 'simple'`), replace silent mirror error swallowing with a strongly typed `CompanyMirrorError` / `CompanyMirrorResult` contract, add deterministic transactional Company delete unlink/archive handling preserving internal Organizations across SQL Server and PostgreSQL, enforce BUSL-1.1 headers and domain-neutral copy across mirror sources/tests/docs, and verify MJ 6.3 edge release-line and CI workflow alignment.
