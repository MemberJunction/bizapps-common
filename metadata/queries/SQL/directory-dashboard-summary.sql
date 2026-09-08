-- Directory dashboard headline figures as ONE row of scalars.
--
-- The Angular tiles used to COUNT arrays from LoadDirectorySnapshot (RunView MaxRows 1000).
-- Cheese has ~3000 people, so every tile was a truncated sample. This query is COUNT(*)
-- over the Common base views — no row cap, no client aggregation.
--
-- Email = COALESCE(PrimaryEmail, Email), matching PersonEmail() in directory-stats.ts.
-- People-per-day buckets are UTC calendar days (CreatedAt is UTC). The old client used
-- the browser's local day; UTC is the only clock the server can apply consistently.
-- Org type mix is JSON so a variable number of types does not explode the column list.
--
-- Single SELECT (no DECLARE / temp tables) so RunQuery can wrap it.
SELECT
    p.TotalPeople,
    p.ActivePeople,
    p.PeopleMissingEmail,
    p.PeopleMissingOrganization,
    p.PeopleAddedD0,
    p.PeopleAddedD1,
    p.PeopleAddedD2,
    p.PeopleAddedD3,
    p.PeopleAddedD4,
    p.PeopleAddedD5,
    p.PeopleAddedD6,
    p.AttentionEmailPersonID,
    p.AttentionEmailName,
    p.AttentionEmailOrg,
    o.TotalOrganizations,
    o.ActiveOrganizations,
    o.OrganizationsMissingType,
    o.OrganizationsMissingWebsite,
    o.AttentionTypeOrgID,
    o.AttentionTypeOrgName,
    o.AttentionTypeWebsite,
    o.OrgTypeMixJson,
    r.RelationshipCount
FROM
(
    SELECT
        COUNT(*) AS TotalPeople,
        ISNULL(SUM(CASE WHEN Status = N'Active' THEN 1 ELSE 0 END), 0) AS ActivePeople,
        ISNULL(SUM(CASE WHEN Status = N'Active'
                  AND NULLIF(LTRIM(RTRIM(COALESCE(PrimaryEmail, Email))), N'') IS NULL
                 THEN 1 ELSE 0 END), 0) AS PeopleMissingEmail,
        ISNULL(SUM(CASE WHEN Status = N'Active' AND CurrentOrganizationID IS NULL
                 THEN 1 ELSE 0 END), 0) AS PeopleMissingOrganization,
        ISNULL(SUM(CASE WHEN CAST(__mj_CreatedAt AS date) = CAST(SYSUTCDATETIME() AS date) THEN 1 ELSE 0 END), 0) AS PeopleAddedD0,
        ISNULL(SUM(CASE WHEN CAST(__mj_CreatedAt AS date) = DATEADD(DAY, -1, CAST(SYSUTCDATETIME() AS date)) THEN 1 ELSE 0 END), 0) AS PeopleAddedD1,
        ISNULL(SUM(CASE WHEN CAST(__mj_CreatedAt AS date) = DATEADD(DAY, -2, CAST(SYSUTCDATETIME() AS date)) THEN 1 ELSE 0 END), 0) AS PeopleAddedD2,
        ISNULL(SUM(CASE WHEN CAST(__mj_CreatedAt AS date) = DATEADD(DAY, -3, CAST(SYSUTCDATETIME() AS date)) THEN 1 ELSE 0 END), 0) AS PeopleAddedD3,
        ISNULL(SUM(CASE WHEN CAST(__mj_CreatedAt AS date) = DATEADD(DAY, -4, CAST(SYSUTCDATETIME() AS date)) THEN 1 ELSE 0 END), 0) AS PeopleAddedD4,
        ISNULL(SUM(CASE WHEN CAST(__mj_CreatedAt AS date) = DATEADD(DAY, -5, CAST(SYSUTCDATETIME() AS date)) THEN 1 ELSE 0 END), 0) AS PeopleAddedD5,
        ISNULL(SUM(CASE WHEN CAST(__mj_CreatedAt AS date) = DATEADD(DAY, -6, CAST(SYSUTCDATETIME() AS date)) THEN 1 ELSE 0 END), 0) AS PeopleAddedD6,
        (
            SELECT TOP (1) p2.ID
            FROM [__mj_BizAppsCommon].[vwPeople] p2
            WHERE p2.Status = N'Active'
              AND NULLIF(LTRIM(RTRIM(COALESCE(p2.PrimaryEmail, p2.Email))), N'') IS NULL
            ORDER BY p2.__mj_CreatedAt DESC
        ) AS AttentionEmailPersonID,
        (
            SELECT TOP (1) p2.DisplayName
            FROM [__mj_BizAppsCommon].[vwPeople] p2
            WHERE p2.Status = N'Active'
              AND NULLIF(LTRIM(RTRIM(COALESCE(p2.PrimaryEmail, p2.Email))), N'') IS NULL
            ORDER BY p2.__mj_CreatedAt DESC
        ) AS AttentionEmailName,
        (
            SELECT TOP (1) p2.CurrentOrganizationName
            FROM [__mj_BizAppsCommon].[vwPeople] p2
            WHERE p2.Status = N'Active'
              AND NULLIF(LTRIM(RTRIM(COALESCE(p2.PrimaryEmail, p2.Email))), N'') IS NULL
            ORDER BY p2.__mj_CreatedAt DESC
        ) AS AttentionEmailOrg
    FROM [__mj_BizAppsCommon].[vwPeople]
) p
CROSS JOIN
(
    SELECT
        COUNT(*) AS TotalOrganizations,
        ISNULL(SUM(CASE WHEN Status = N'Active' THEN 1 ELSE 0 END), 0) AS ActiveOrganizations,
        ISNULL(SUM(CASE WHEN Status = N'Active' AND OrganizationTypeID IS NULL THEN 1 ELSE 0 END), 0) AS OrganizationsMissingType,
        ISNULL(SUM(CASE WHEN Status = N'Active' AND NULLIF(LTRIM(RTRIM(Website)), N'') IS NULL THEN 1 ELSE 0 END), 0) AS OrganizationsMissingWebsite,
        (
            SELECT TOP (1) o2.ID
            FROM [__mj_BizAppsCommon].[vwOrganizations] o2
            WHERE o2.Status = N'Active' AND o2.OrganizationTypeID IS NULL
            ORDER BY o2.__mj_CreatedAt DESC
        ) AS AttentionTypeOrgID,
        (
            SELECT TOP (1) o2.Name
            FROM [__mj_BizAppsCommon].[vwOrganizations] o2
            WHERE o2.Status = N'Active' AND o2.OrganizationTypeID IS NULL
            ORDER BY o2.__mj_CreatedAt DESC
        ) AS AttentionTypeOrgName,
        (
            SELECT TOP (1) o2.Website
            FROM [__mj_BizAppsCommon].[vwOrganizations] o2
            WHERE o2.Status = N'Active' AND o2.OrganizationTypeID IS NULL
            ORDER BY o2.__mj_CreatedAt DESC
        ) AS AttentionTypeWebsite,
        (
            SELECT TOP (100)
                ISNULL(NULLIF(LTRIM(RTRIM(o3.OrganizationType)), N''), N'Unspecified') AS Label,
                COUNT(*) AS Value
            FROM [__mj_BizAppsCommon].[vwOrganizations] o3
            GROUP BY ISNULL(NULLIF(LTRIM(RTRIM(o3.OrganizationType)), N''), N'Unspecified')
            ORDER BY COUNT(*) DESC
            FOR JSON PATH
        ) AS OrgTypeMixJson
    FROM [__mj_BizAppsCommon].[vwOrganizations]
) o
CROSS JOIN
(
    SELECT COUNT(*) AS RelationshipCount
    FROM [__mj_BizAppsCommon].[vwRelationships]
) r
;
