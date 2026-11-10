-- People added on each of the last seven BUSINESS days, as one row: PeopleAddedD0 is today,
-- PeopleAddedD6 six days ago. Read by the directory dashboard's "people added" bars.
--
-- __mj_CreatedAt is a UTC instant; fnBusinessDayOf turns it into the day it was in the business
-- time zone, the same zone fnBusinessToday() reads for "today" (bc-aidp-next-golive#168). A UTC
-- day put Thursday evening's signups in Friday's bar for anyone in the Americas.
--
-- Kept apart from Common: Directory Dashboard Summary on purpose. fnBusinessDayOf is a scalar
-- function SQL Server cannot inline (it converts time zones), so it runs once per row and makes
-- any statement that calls it single-threaded. Here it runs only for the rows the WHERE keeps
-- (the last eight days); in the summary it slowed every count with it.
-- No inline AT TIME ZONE: MJ's SQL parser cannot read it.
--
-- Single SELECT (no DECLARE / temp tables) so RunQuery can wrap it.
SELECT
    ISNULL(SUM(CASE WHEN d.CreatedDay = bt.Today THEN 1 ELSE 0 END), 0) AS PeopleAddedD0,
    ISNULL(SUM(CASE WHEN d.CreatedDay = DATEADD(DAY, -1, bt.Today) THEN 1 ELSE 0 END), 0) AS PeopleAddedD1,
    ISNULL(SUM(CASE WHEN d.CreatedDay = DATEADD(DAY, -2, bt.Today) THEN 1 ELSE 0 END), 0) AS PeopleAddedD2,
    ISNULL(SUM(CASE WHEN d.CreatedDay = DATEADD(DAY, -3, bt.Today) THEN 1 ELSE 0 END), 0) AS PeopleAddedD3,
    ISNULL(SUM(CASE WHEN d.CreatedDay = DATEADD(DAY, -4, bt.Today) THEN 1 ELSE 0 END), 0) AS PeopleAddedD4,
    ISNULL(SUM(CASE WHEN d.CreatedDay = DATEADD(DAY, -5, bt.Today) THEN 1 ELSE 0 END), 0) AS PeopleAddedD5,
    ISNULL(SUM(CASE WHEN d.CreatedDay = DATEADD(DAY, -6, bt.Today) THEN 1 ELSE 0 END), 0) AS PeopleAddedD6
FROM [__mj_BizAppsCommon].[fnBusinessToday]() AS bt
LEFT JOIN
(
    SELECT [__mj_BizAppsCommon].[fnBusinessDayOf](x.__mj_CreatedAt) AS CreatedDay
    FROM [__mj_BizAppsCommon].[vwPeople] x
    WHERE x.__mj_CreatedAt >= DATEADD(DAY, -8, SYSDATETIMEOFFSET())
) d ON 1 = 1
;
