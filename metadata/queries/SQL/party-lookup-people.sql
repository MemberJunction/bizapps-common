-- Party lookup for People: prefix and word/contains match on base-table columns, TOP 20, no COUNT.
-- Contract shared by every party lookup query (bizapps-party-field): columns ID, Name, Detail;
-- parameters Term (required) and Domain (optional, already normalized by the picker).
-- sqlLikeBegins and sqlLikeContains escape the term and append wildcards; prefix matches rank ahead
-- of mid-name word matches, which rank ahead of substring matches.
SELECT TOP 20
    p.ID,
    p.DisplayName AS Name,
    p.Email AS Detail
FROM [__mj_BizAppsCommon].[Person] p
WHERE p.LastName LIKE {{ Term | sqlLikeContains }}
   OR p.FirstName LIKE {{ Term | sqlLikeContains }}
   OR p.DisplayName LIKE {{ Term | sqlLikeContains }}
   OR p.Email LIKE {{ Term | sqlLikeBegins }}
{% if Domain %}   OR p.EmailDomain LIKE {{ Domain | sqlLikeBegins }}
{% endif %}ORDER BY
    CASE
        WHEN p.LastName LIKE {{ Term | sqlLikeBegins }} OR p.FirstName LIKE {{ Term | sqlLikeBegins }} OR p.DisplayName LIKE {{ Term | sqlLikeBegins }} THEN 0
        WHEN p.DisplayName LIKE N'% ' + {{ Term | sqlLikeBegins }} OR p.LastName LIKE N'% ' + {{ Term | sqlLikeBegins }} THEN 1
        ELSE 2
    END,
    p.DisplayName,
    p.ID
