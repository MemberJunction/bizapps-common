---
"@mj-biz-apps/common-entities": minor
---

Add the PostgreSQL counterpart of the Organization.LinkedCompanyID migration (V202611201420). On PostgreSQL it adds the nullable LinkedCompanyID column with its foreign key to MJ: Companies, the unique index that allows one Organization per Company, the LinkedCompany name in vwOrganizationsGenerated, and the entity field metadata, matching the SQL Server migration.
