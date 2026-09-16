-- =============================================================================
-- Migration: V202609160900__v5.43.x__Business_Time_Zone.sql
-- Description: The business time zone as one instance-wide setting, and the one
--              function every app's views use for "today" in that zone
--              (bc-aidp-next-golive#168, aidp-next plans/2026-09-15-business-dates-design.md §4).
--
--   1. One MJ: Instance Configurations row, FeatureKey 'BizApps.BusinessTimeZone',
--      JSON with the IANA name code reads ('iana') and the Windows name SQL
--      Server's AT TIME ZONE accepts ('sql'). Shipped with an EMPTY value so the
--      DefaultValue (UTC) applies; the host instance sets the value (for example to Central).
--      Seeded through the MJ procedure, guarded by the fixed ID, so a host that
--      seeded it first (a host's own upsert using the same ID) is left alone.
--      Not a metadata-sync file, deliberately: a later `mj sync push` from this
--      repo cannot overwrite the instance's value.
--   2. fnBusinessToday(): an INLINE table-valued function, not a scalar one. A
--      scalar function that calls SYSDATETIMEOFFSET() is never inlined and would
--      run once per row inside a view predicate; an inline TVF is expanded into
--      the query and the config lookup runs once. Views use
--        CROSS JOIN [__mj_BizAppsCommon].[fnBusinessToday]() AS bt ... < bt.Today
--      MJ 6.2 will define 'Business.TimeZone'; when that row exists it wins.
--      A name sys.time_zone_info does not know falls back to UTC rather than
--      failing every view that joins the function.
-- No table DDL. No CodeGen capture. Idempotent.
-- =============================================================================

-- 1) The setting
IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[InstanceConfiguration]
               WHERE [ID] = 'B12A9C15-0168-4C0E-9D3A-4B7E2F1C6A08'
                  OR [FeatureKey] = N'BizApps.BusinessTimeZone')
BEGIN
    EXEC [${mjSchema}].[spCreateInstanceConfiguration]
        @ID = 'B12A9C15-0168-4C0E-9D3A-4B7E2F1C6A08',
        @FeatureKey = N'BizApps.BusinessTimeZone',
        @Value = N'',
        @ValueType = N'json',
        @Category = N'BizApps',
        @DisplayName = N'Business time zone',
        @Description = N'The zone that decides what "today" is for dates entered, defaulted and compared across the BizApps. JSON: "iana" is read by code (e.g. America/Chicago), "sql" by SQL Server views (e.g. Central Standard Time). Set once per instance; empty means UTC.',
        @DefaultValue = N'{"iana":"UTC","sql":"UTC"}';
END
GO

-- 2) Today in the business zone, for views
CREATE OR ALTER FUNCTION [${flyway:defaultSchema}].[fnBusinessToday]()
RETURNS TABLE
AS RETURN (
    SELECT CAST(SYSDATETIMEOFFSET() AT TIME ZONE v.SqlZone AS date) AS [Today],
           v.SqlZone AS [SqlZone]
    FROM (
        SELECT CASE WHEN EXISTS (SELECT 1 FROM sys.time_zone_info t WHERE t.[name] = z.SqlZone COLLATE DATABASE_DEFAULT)
                    THEN z.SqlZone ELSE N'UTC' END AS SqlZone
        FROM (
            -- The first key present wins, readable or not; an unreadable preferred row means UTC
            -- on every tier rather than a code/view split.
            -- Value when non-blank, else DefaultValue — never a fall-through from an unreadable
            -- Value to DefaultValue, which would answer Central here while code answered UTC.
            SELECT CASE
                       WHEN NULLIF(LTRIM(RTRIM(c.[Value])), N'') IS NULL
                       THEN COALESCE(NULLIF(CASE WHEN ISJSON(c.[DefaultValue]) = 1
                                                  AND JSON_VALUE(c.[DefaultValue], '$.iana') IS NOT NULL
                                                 THEN JSON_VALUE(c.[DefaultValue], '$.sql') END, N''), N'UTC')
                       ELSE COALESCE(NULLIF(CASE WHEN ISJSON(c.[Value]) = 1
                                                  AND JSON_VALUE(c.[Value], '$.iana') IS NOT NULL
                                                 THEN JSON_VALUE(c.[Value], '$.sql') END, N''), N'UTC')
                   END AS SqlZone
            FROM (SELECT TOP (1) [Value], [DefaultValue]
                  FROM [${mjSchema}].[InstanceConfiguration]
                  WHERE [FeatureKey] IN (N'Business.TimeZone', N'BizApps.BusinessTimeZone')
                  ORDER BY CASE [FeatureKey] WHEN N'Business.TimeZone' THEN 0 ELSE 1 END) c
            UNION ALL
            SELECT N'UTC' WHERE NOT EXISTS (
                  SELECT 1 FROM [${mjSchema}].[InstanceConfiguration]
                  WHERE [FeatureKey] IN (N'Business.TimeZone', N'BizApps.BusinessTimeZone'))
        ) z
    ) v
);
GO

GRANT SELECT ON [${flyway:defaultSchema}].[fnBusinessToday] TO [cdp_UI], [cdp_Developer], [cdp_Integration];
GO
