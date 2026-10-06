-- Hand-written PG twin of V202610062305__v5.51.x__Business_Day_Of.sql.
-- The calendar day an instant falls on in the business time zone. Zone resolution is
-- fnBusinessToday()'s, read from it rather than copied, so the two cannot disagree; its
-- "SqlZone" column holds the IANA name on PostgreSQL, which AT TIME ZONE accepts.
-- STRICT mirrors the T-SQL twin's RETURNS NULL ON NULL INPUT: NULL in, NULL out.
--
-- Named .pg.sql, not .pgonly.sql: the converter treats a .pg.sql counterpart as "already
-- converted" and leaves the file alone. Under .pgonly.sql it would convert the T-SQL source
-- again and emit a SECOND migration at this version, which Flyway refuses.

CREATE OR REPLACE FUNCTION __mj_bizappscommon."fnBusinessDayOf"("at" timestamptz)
RETURNS date
LANGUAGE sql STABLE STRICT
AS $$
    SELECT ("at" AT TIME ZONE bt."SqlZone")::date
    FROM __mj_bizappscommon."fnBusinessToday"() bt;
$$;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."fnBusinessDayOf" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
