-- Context query for Activity Sentiment & Tagging feature pipeline.
-- Returns the target activity along with the linked contact's prior activities for baseline comparison.
SELECT
    targetActivity.ID AS TargetActivityID,
    targetActivity.Title AS TargetTitle,
    targetActivity.Description AS TargetDescription,
    targetActivity.StartedAt AS TargetStartedAt,
    targetActivity.Direction AS TargetDirection,
    targetActivity.Status AS TargetStatus,
    targetActivity.Outcome AS TargetOutcome,
    targetActivity.Details AS TargetDetails,
    linkedPerson.ID AS LinkedPersonID,
    linkedPerson.DisplayName AS LinkedPersonName,
    priorActivities.ID AS PriorActivityID,
    priorActivities.Title AS PriorTitle,
    priorActivities.Description AS PriorDescription,
    priorActivities.StartedAt AS PriorStartedAt,
    priorActivities.Direction AS PriorDirection,
    priorActivities.Outcome AS PriorOutcome,
    priorActivities.SentimentScore AS PriorSentimentScore
FROM [__mj_BizAppsCommon].[vwActivities] AS targetActivity
OUTER APPLY (
    SELECT TOP 1
        al.RecordID AS PersonID
    FROM [__mj_BizAppsCommon].[vwActivityLinks] al
    WHERE al.ActivityID = targetActivity.ID
      AND al.Entity = 'MJ_BizApps_Common: People'
) AS targetPersonLink
LEFT JOIN [__mj_BizAppsCommon].[vwPeople] AS linkedPerson
    ON linkedPerson.ID = targetPersonLink.PersonID
OUTER APPLY (
    SELECT TOP 10
        a.ID,
        a.Title,
        a.Description,
        a.StartedAt,
        a.Direction,
        a.Outcome,
        a.SentimentScore
    FROM [__mj_BizAppsCommon].[vwActivities] a
    INNER JOIN [__mj_BizAppsCommon].[vwActivityLinks] al2
        ON al2.ActivityID = a.ID
       AND al2.Entity = 'MJ_BizApps_Common: People'
       AND al2.RecordID = targetPersonLink.PersonID
    WHERE a.ID <> targetActivity.ID
      AND a.StartedAt <= targetActivity.StartedAt
    ORDER BY a.StartedAt DESC
) AS priorActivities
WHERE targetActivity.ID = {{ ActivityID | sqlString }};
