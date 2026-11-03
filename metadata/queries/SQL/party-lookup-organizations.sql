-- Party lookup for Organizations: prefix and word/contains match on base-table columns, TOP 20, no COUNT.
-- Contract shared by every party lookup query (bizapps-party-field): columns ID, Name, Detail;
-- parameters Term (required) and Domain (optional, already normalized by the picker).
-- sqlLikeBegins and sqlLikeContains escape the term and append wildcards; prefix matches rank ahead
-- of mid-name word matches, which rank ahead of substring matches.
-- Detail joins non-empty Acronym and WebsiteDomain with " · " so organizations with similar names
-- can be told apart without showing a stray separator when one column is blank.
SELECT TOP 20
    o.ID,
    o.Name,
    NULLIF(CONCAT_WS(N' · ', NULLIF(o.Acronym, N''), NULLIF(o.WebsiteDomain, N'')), N'') AS Detail
FROM [__mj_BizAppsCommon].[Organization] o
WHERE o.Name LIKE {{ Term | sqlLikeContains }}
   OR o.LegalName LIKE {{ Term | sqlLikeContains }}
   OR o.Acronym LIKE {{ Term | sqlLikeBegins }}
{% if Domain %}   OR o.WebsiteDomain LIKE {{ Domain | sqlLikeBegins }}
{% endif %}ORDER BY
    CASE
        WHEN o.Name LIKE {{ Term | sqlLikeBegins }} OR o.Acronym LIKE {{ Term | sqlLikeBegins }} THEN 0
        WHEN o.LegalName LIKE {{ Term | sqlLikeBegins }} THEN 1
        WHEN o.Name LIKE N'% ' + {{ Term | sqlLikeBegins }} OR o.LegalName LIKE N'% ' + {{ Term | sqlLikeBegins }} THEN 2
        ELSE 3
    END,
    o.Name,
    o.ID
