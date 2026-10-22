-- Party lookup for People: prefix match on indexed base-table columns, TOP 20, no COUNT.
-- Contract shared by every party lookup query (bizapps-party-field): columns ID, Name, Detail;
-- parameters Term (required) and Domain (optional, already normalized by the picker).
-- sqlLikeBegins escapes the term and appends the trailing wildcard.
SELECT TOP 20
    p.ID,
    p.DisplayName AS Name,
    p.Email AS Detail
FROM [__mj_BizAppsCommon].[Person] p
WHERE p.LastName LIKE {{ Term | sqlLikeBegins }}
   OR p.DisplayName LIKE {{ Term | sqlLikeBegins }}
   OR p.Email LIKE {{ Term | sqlLikeBegins }}
{% if Domain %}   OR p.EmailDomain LIKE {{ Domain | sqlLikeBegins }}
{% endif %}ORDER BY p.DisplayName, p.ID
