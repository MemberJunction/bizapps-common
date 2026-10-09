---
'@mj-biz-apps/common-entities': minor
---

Restores `spCreatePerson` / `spUpdatePerson` `@PhotoURL` to `NVARCHAR(MAX)`. The v5.45 job-function migration re-emitted both procs at the old 1000-character width, so SQL Server silently truncated every Person photo URL longer than that — inline data-URI avatars were stored cut off at exactly 1000 characters and never rendered. Truncated values must be re-saved by their source.
