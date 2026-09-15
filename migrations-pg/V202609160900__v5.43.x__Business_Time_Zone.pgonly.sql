-- Hand-written PG twin of V202609160900__v5.43.x__Business_Time_Zone.sql.
-- The converter cannot translate JSON_VALUE or sys.time_zone_info, and PG needs
-- neither: AT TIME ZONE accepts IANA names, which is what "iana" holds.

INSERT INTO "__mj"."InstanceConfiguration"
    ("ID", "FeatureKey", "Value", "ValueType", "Category", "DisplayName", "Description", "DefaultValue")
SELECT 'B12A9C15-0168-4C0E-9D3A-4B7E2F1C6A08'::uuid, 'BizApps.BusinessTimeZone', '', 'json', 'BizApps',
       'Business time zone',
       'The zone that decides what "today" is for dates entered, defaulted and compared across the BizApps. JSON: "iana" is read by code (e.g. America/Chicago), "sql" by SQL Server views (e.g. Central Standard Time). Set once per instance; empty means UTC.',
       '{"iana":"UTC","sql":"UTC"}'
WHERE NOT EXISTS (SELECT 1 FROM "__mj"."InstanceConfiguration"
                  WHERE "ID" = 'B12A9C15-0168-4C0E-9D3A-4B7E2F1C6A08'::uuid
                     OR "FeatureKey" = 'BizApps.BusinessTimeZone');

-- The zone name a config row holds, or NULL when its JSON is unreadable. plpgsql so a
-- malformed Value degrades to the fallback instead of raising into every view that
-- joins fnBusinessToday() — the same lax behaviour SQL Server's JSON_VALUE has.
CREATE OR REPLACE FUNCTION "__mj_BizAppsCommon"."fnBusinessZoneIana"(p_value text)
RETURNS text
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
    IF p_value IS NULL OR BTRIM(p_value) = '' THEN
        RETURN NULL;
    END IF;
    RETURN NULLIF(BTRIM(p_value)::jsonb ->> 'iana', '');
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION "__mj_BizAppsCommon"."fnBusinessToday"()
RETURNS TABLE ("Today" date, "SqlZone" text)
LANGUAGE sql STABLE
AS $$
    WITH picked AS (
        SELECT COALESCE(
                   "__mj_BizAppsCommon"."fnBusinessZoneIana"(c."Value"),
                   "__mj_BizAppsCommon"."fnBusinessZoneIana"(c."DefaultValue"),
                   'UTC') AS zone
        FROM "__mj"."InstanceConfiguration" c
        WHERE c."FeatureKey" IN ('Business.TimeZone', 'BizApps.BusinessTimeZone')
        ORDER BY CASE c."FeatureKey" WHEN 'Business.TimeZone' THEN 0 ELSE 1 END
        LIMIT 1
    ),
    zone AS (
        SELECT COALESCE((SELECT p.zone FROM picked p
                         WHERE EXISTS (SELECT 1 FROM pg_timezone_names n WHERE n.name = p.zone)),
                        'UTC') AS zone
    )
    SELECT (now() AT TIME ZONE z.zone)::date AS "Today", z.zone AS "SqlZone"
    FROM zone z;
$$;
