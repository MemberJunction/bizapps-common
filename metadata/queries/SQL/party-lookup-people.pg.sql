-- Party lookup for People (PostgreSQL dialect): prefix and word/contains match on base-table
-- columns, LIMIT 20, no COUNT.
SELECT
    p."ID",
    p."DisplayName" AS "Name",
    p."Email" AS "Detail"
FROM "__mj_BizAppsCommon"."Person" p
WHERE p."LastName" ILIKE {{ Term | sqlLikeContains }}
   OR p."FirstName" ILIKE {{ Term | sqlLikeContains }}
   OR p."DisplayName" ILIKE {{ Term | sqlLikeContains }}
   OR p."Email" ILIKE {{ Term | sqlLikeBegins }}
{% if Domain %}   OR p."EmailDomain" ILIKE {{ Domain | sqlLikeBegins }}
{% endif %}ORDER BY
    CASE
        WHEN p."LastName" ILIKE {{ Term | sqlLikeBegins }} OR p."FirstName" ILIKE {{ Term | sqlLikeBegins }} OR p."DisplayName" ILIKE {{ Term | sqlLikeBegins }} THEN 0
        WHEN p."DisplayName" ILIKE ('% ' || {{ Term | sqlLikeBegins }}) OR p."LastName" ILIKE ('% ' || {{ Term | sqlLikeBegins }}) THEN 1
        ELSE 2
    END,
    p."DisplayName",
    p."ID"
LIMIT 20
