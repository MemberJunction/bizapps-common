-- Directory dashboard headline figures as ONE row of scalars.
--
-- The Angular tiles used to COUNT arrays from LoadDirectorySnapshot (RunView MaxRows 1000).
-- Cheese has ~3000 people, so every tile was a truncated sample. This query is COUNT(*)
-- over the Common base views — no row cap, no client aggregation.
--
-- Email = COALESCE(PrimaryEmail, Email), matching PersonEmail() in directory-stats.ts.
-- People added per business day is a separate query, Common: Directory People Per Day. Its
-- fnBusinessDayOf is a scalar function that SQL Server cannot inline (it converts time zones),
-- and one such call anywhere in a statement makes the whole plan single-threaded: in this query
-- that took the counts from about 9 seconds to over 20 on 1.3M people.
-- Org type mix is JSON so a variable number of types does not explode the column list.
--
-- The "worth a look" person and organization are each one TOP (1) row in its own derived table,
-- joined ON 1 = 1 so an empty result still returns the counts: one pass each instead of three
-- scalar subqueries, and the three fields always come from the same row.
--
-- People without an organization are counted with NOT EXISTS over active Employee relationships,
-- not from vwPeople.CurrentOrganizationID. The view finds that column with a TOP (1) OUTER APPLY
-- per person, which over 1.3M people took about 17 seconds; the NOT EXISTS count takes about 2.
-- It counts the same people as long as an active Employee relationship always names an
-- organization (vwPeople takes the latest one, and would show no organization if that one did not).
--
-- Single SELECT (no DECLARE / temp tables) so RunQuery can wrap it.
SELECT
    p.TotalPeople,
    p.ActivePeople,
    p.PeopleMissingEmail,
    po.PeopleMissingOrganization,
    pe.AttentionEmailPersonID,
    pe.AttentionEmailName,
    pe.AttentionEmailOrg,
    o.TotalOrganizations,
    o.ActiveOrganizations,
    o.OrganizationsMissingType,
    o.OrganizationsMissingWebsite,
    ot.AttentionTypeOrgID,
    ot.AttentionTypeOrgName,
    ot.AttentionTypeWebsite,
    o.OrgTypeMixJson,
    r.RelationshipCount
FROM
(
    SELECT
        COUNT(*) AS TotalPeople,
        ISNULL(SUM(CASE WHEN Status = N'Active' THEN 1 ELSE 0 END), 0) AS ActivePeople,
        ISNULL(SUM(CASE WHEN Status = N'Active'
                  AND NULLIF(LTRIM(RTRIM(COALESCE(PrimaryEmail, Email))), N'') IS NULL
                 THEN 1 ELSE 0 END), 0) AS PeopleMissingEmail
    FROM [__mj_BizAppsCommon].[vwPeople]
) p
CROSS JOIN
(
    SELECT COUNT(*) AS PeopleMissingOrganization
    FROM [__mj_BizAppsCommon].[vwPeople] p3
    WHERE p3.Status = N'Active'
      AND NOT EXISTS (
          SELECT 1
          FROM [__mj_BizAppsCommon].[Relationship] r
          INNER JOIN [__mj_BizAppsCommon].[RelationshipType] rt ON rt.[ID] = r.[RelationshipTypeID]
          WHERE rt.[Name] = N'Employee'
            AND r.[Status] = N'Active'
            AND r.[ToOrganizationID] IS NOT NULL
            AND r.[FromPersonID] = p3.[ID]
      )
) po
CROSS JOIN
(
    SELECT
        COUNT(*) AS TotalOrganizations,
        ISNULL(SUM(CASE WHEN Status = N'Active' THEN 1 ELSE 0 END), 0) AS ActiveOrganizations,
        ISNULL(SUM(CASE WHEN Status = N'Active' AND OrganizationTypeID IS NULL THEN 1 ELSE 0 END), 0) AS OrganizationsMissingType,
        ISNULL(SUM(CASE WHEN Status = N'Active' AND NULLIF(LTRIM(RTRIM(Website)), N'') IS NULL THEN 1 ELSE 0 END), 0) AS OrganizationsMissingWebsite,
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
LEFT JOIN
(
    SELECT TOP (1)
        p2.ID AS AttentionEmailPersonID,
        p2.DisplayName AS AttentionEmailName,
        p2.CurrentOrganizationName AS AttentionEmailOrg
    FROM [__mj_BizAppsCommon].[vwPeople] p2
    WHERE p2.Status = N'Active'
      AND NULLIF(LTRIM(RTRIM(COALESCE(p2.PrimaryEmail, p2.Email))), N'') IS NULL
    ORDER BY p2.__mj_CreatedAt DESC
) pe ON 1 = 1
LEFT JOIN
(
    SELECT TOP (1)
        o2.ID AS AttentionTypeOrgID,
        o2.Name AS AttentionTypeOrgName,
        o2.Website AS AttentionTypeWebsite
    FROM [__mj_BizAppsCommon].[vwOrganizations] o2
    WHERE o2.Status = N'Active' AND o2.OrganizationTypeID IS NULL
    ORDER BY o2.__mj_CreatedAt DESC
) ot ON 1 = 1
;
