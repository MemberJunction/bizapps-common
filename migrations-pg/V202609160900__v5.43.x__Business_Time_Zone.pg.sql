-- Hand-written PG twin of V202609160900__v5.43.x__Business_Time_Zone.sql.
-- The converter cannot translate JSON_VALUE or sys.time_zone_info, and PG needs
-- neither: AT TIME ZONE accepts IANA names, which is what "iana" holds.
--
-- Named .pg.sql, not .pgonly.sql: the converter treats a .pg.sql counterpart as "already
-- converted" and leaves the file alone. Under .pgonly.sql it would convert the T-SQL source
-- again and emit a SECOND migration at this version, which Flyway refuses.

INSERT INTO "__mj"."InstanceConfiguration"
    ("ID", "FeatureKey", "Value", "ValueType", "Category", "DisplayName", "Description", "DefaultValue")
SELECT 'B12A9C15-0168-4C0E-9D3A-4B7E2F1C6A08'::uuid, 'BizApps.BusinessTimeZone', '', 'json', 'BizApps',
       'Business time zone',
       'The zone that decides what "today" is for dates entered, defaulted and compared across the BizApps. JSON: "iana" is read by code (e.g. America/Chicago), "sql" by SQL Server views (e.g. Central Standard Time). Set once per instance; empty means UTC.',
       '{"iana":"UTC","sql":"UTC"}'
WHERE NOT EXISTS (SELECT 1 FROM "__mj"."InstanceConfiguration"
                  WHERE "ID" = 'B12A9C15-0168-4C0E-9D3A-4B7E2F1C6A08'::uuid
                     OR "FeatureKey" = 'BizApps.BusinessTimeZone');

-- The zone name a config row holds, or NULL when its JSON is unreadable or carries only one of
-- "iana"/"sql" (the T-SQL twin's AND JSON_VALUE(..., '$.iana') IS NOT NULL guard, mirrored). plpgsql
-- so a malformed Value degrades to the fallback instead of raising into every view that joins
-- fnBusinessToday() — the same lax behaviour SQL Server's JSON_VALUE has.
CREATE OR REPLACE FUNCTION __mj_bizappscommon."fnBusinessZoneIana"(p_value text)
RETURNS text
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
    IF p_value IS NULL OR BTRIM(p_value) = '' THEN
        RETURN NULL;
    END IF;
    RETURN (SELECT CASE WHEN NULLIF(j ->> 'sql', '') IS NULL THEN NULL ELSE NULLIF(j ->> 'iana', '') END
            FROM (SELECT BTRIM(p_value)::jsonb AS j) parsed);
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION __mj_bizappscommon."fnBusinessToday"()
RETURNS TABLE ("Today" date, "SqlZone" text)
LANGUAGE sql STABLE
AS $$
    WITH picked AS (
        -- Value when non-blank, else DefaultValue; an unreadable Value is UTC, never a
        -- fall-through to DefaultValue (the T-SQL twin and the TypeScript engine agree).
        SELECT CASE
                   WHEN NULLIF(BTRIM(c."Value"), '') IS NULL
                   THEN COALESCE(__mj_bizappscommon."fnBusinessZoneIana"(c."DefaultValue"), 'UTC')
                   ELSE COALESCE(__mj_bizappscommon."fnBusinessZoneIana"(c."Value"), 'UTC')
               END AS zone
        FROM "__mj"."InstanceConfiguration" c
        -- The first key present wins, readable or not; an unreadable preferred row means UTC on
        -- every tier rather than a code/view split.
        WHERE c."FeatureKey" IN ('Business.TimeZone', 'BizApps.BusinessTimeZone')
        ORDER BY CASE c."FeatureKey" WHEN 'Business.TimeZone' THEN 0 ELSE 1 END
        LIMIT 1
    ),
    zone AS (
        SELECT COALESCE((SELECT p.zone FROM picked p
                         WHERE EXISTS (SELECT 1 FROM pg_timezone_names n WHERE n.name = p.zone)),
                        'UTC') AS zone
    )
    -- "SqlZone" is the IANA name here: PostgreSQL's AT TIME ZONE takes IANA names, so the two
    -- columns coincide.
    SELECT (now() AT TIME ZONE z.zone)::date AS "Today", z.zone AS "SqlZone"
    FROM zone z;
$$;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."fnBusinessZoneIana" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."fnBusinessToday" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
