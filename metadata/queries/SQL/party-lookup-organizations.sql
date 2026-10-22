-- Party lookup for Organizations: prefix match on indexed base-table columns, TOP 20, no COUNT.
-- Contract shared by every party lookup query (bizapps-party-field): columns ID, Name, Detail;
-- parameters Term (required) and Domain (optional, already normalized by the picker).
-- sqlLikeBegins escapes the term and appends the trailing wildcard.
SELECT TOP 20
    o.ID,
    o.Name,
    o.WebsiteDomain AS Detail
FROM [__mj_BizAppsCommon].[Organization] o
WHERE o.Name LIKE {{ Term | sqlLikeBegins }}
   OR o.LegalName LIKE {{ Term | sqlLikeBegins }}
{% if Domain %}   OR o.WebsiteDomain LIKE {{ Domain | sqlLikeBegins }}
{% endif %}ORDER BY o.Name, o.ID
