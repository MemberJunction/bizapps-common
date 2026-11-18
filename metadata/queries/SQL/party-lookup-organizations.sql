-- Party lookup for Organizations: prefix match on indexed base-table columns, TOP 20, no COUNT.
-- Contract shared by every party lookup query (bizapps-party-field): columns ID, Name, Detail;
-- parameters Term (required) and Domain (optional, already normalized by the picker).
-- sqlLikeBegins escapes the term and appends the trailing wildcard.
-- Detail shows the acronym and the website domain ("NAR · nar.realtor"), whichever exist, so two
-- organizations with the same name or acronym can be told apart.
SELECT TOP 20
    o.ID,
    o.Name,
    NULLIF(CONCAT_WS(N' · ', o.Acronym, o.WebsiteDomain), N'') AS Detail
FROM [__mj_BizAppsCommon].[Organization] o
WHERE o.Name LIKE {{ Term | sqlLikeBegins }}
   OR o.LegalName LIKE {{ Term | sqlLikeBegins }}
   OR o.Acronym LIKE {{ Term | sqlLikeBegins }}
{% if Domain %}   OR o.WebsiteDomain LIKE {{ Domain | sqlLikeBegins }}
{% endif %}ORDER BY o.Name, o.ID
