-- =============================================================================
-- Migration: V202610062305__v5.51.x__Business_Day_Of.sql
-- Description: fnBusinessDayOf(@At) — the calendar day an instant falls on in the
--              business time zone (bc-aidp-next-golive#168).
--
--   fnBusinessToday() answers "what day is it now"; this answers "what day was it
--   then", for bucketing timestamps (__mj_CreatedAt, an order's placed-at) by
--   business day. It exists so queries never spell out
--       CAST(x AT TIME ZONE bt.SqlZone AS date)
--   themselves: MJ's SQL parser (node-sql-parser, transactsql) cannot parse
--   AT TIME ZONE, so a stored query that uses it falls back to regex parsing.
--   A schema-qualified scalar function call parses.
--
--   Zone resolution is fnBusinessToday's, read from it rather than copied: the same
--   config row, the same sys.time_zone_info check, the same UTC fallback. The two
--   functions cannot disagree about the zone.
--
--   @At is DATETIMEOFFSET. A DATETIME/DATETIME2 argument converts implicitly with
--   offset +00:00, so it is read as UTC (MJ stores UTC). Do NOT pass a DATE column:
--   it converts to UTC midnight and comes back as the PREVIOUS day west of UTC.
--   A DATE column already is a business day.
--
--   NULL in, NULL out (RETURNS NULL ON NULL INPUT: the body does not run).
--
--   Not inlined (SQL Server 2019+ scalar UDF inlining): AT TIME ZONE and
--   sys.time_zone_info are both on the exclusion list, so no body that converts
--   zones can be inlined (sys.sql_modules.is_inlineable = 0, checked on 2022). It
--   runs once per row it is called for: in a large scan, filter on the raw
--   timestamp first and call it for the rows that survive.
--
-- No table DDL. No CodeGen capture. Idempotent.
-- =============================================================================

CREATE OR ALTER FUNCTION [${flyway:defaultSchema}].[fnBusinessDayOf](@At DATETIMEOFFSET)
RETURNS DATE
WITH RETURNS NULL ON NULL INPUT
AS
BEGIN
    RETURN (
        SELECT CAST(@At AT TIME ZONE bt.SqlZone AS date)
        FROM [${flyway:defaultSchema}].[fnBusinessToday]() AS bt
    );
END;
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[fnBusinessDayOf] TO [cdp_UI], [cdp_Developer], [cdp_Integration];
GO
