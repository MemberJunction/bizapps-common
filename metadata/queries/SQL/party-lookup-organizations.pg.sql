-- Party lookup for Organizations (PostgreSQL dialect): prefix and word/contains match on base-table
-- columns, LIMIT 20, no COUNT.
SELECT
    o."ID",
    o."Name",
    NULLIF(CONCAT_WS(' · ', NULLIF(o."Acronym", ''), NULLIF(o."WebsiteDomain", '')), '') AS "Detail"
FROM "__mj_BizAppsCommon"."Organization" o
WHERE o."Name" ILIKE {{ Term | sqlLikeContains }}
   OR o."LegalName" ILIKE {{ Term | sqlLikeContains }}
   OR o."Acronym" ILIKE {{ Term | sqlLikeBegins }}
{% if Domain %}   OR o."WebsiteDomain" ILIKE {{ Domain | sqlLikeBegins }}
{% endif %}ORDER BY
    CASE
        WHEN o."Name" ILIKE {{ Term | sqlLikeBegins }} OR o."Acronym" ILIKE {{ Term | sqlLikeBegins }} THEN 0
        WHEN o."LegalName" ILIKE {{ Term | sqlLikeBegins }} THEN 1
        WHEN o."Name" ILIKE ('% ' || {{ Term | sqlLikeBegins }}) OR o."LegalName" ILIKE ('% ' || {{ Term | sqlLikeBegins }}) THEN 2
        ELSE 3
    END,
    o."Name",
    o."ID"
LIMIT 20
