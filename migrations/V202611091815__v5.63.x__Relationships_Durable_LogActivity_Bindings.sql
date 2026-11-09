-- =============================================================================
-- Migration: V202611091815__v5.63.x__Relationships_Durable_LogActivity_Bindings.sql
-- Description: Move both MJ_BizApps_Common: Relationships Common.LogActivity
--              bindings (ABF0B899-C4D8-4BF8-9AE8-4EAE7DD32346 and
--              32D1707C-D9BE-48F7-BB46-701F8DB09110) from Inline to Durable,
--              replace their whole-record RecordData ('Entity Object Data')
--              params with Script projections of only the five ID columns,
--              and set LogValue = 1 on RecordData and LinkFields so durable
--              task redaction preserves them.
-- =============================================================================

-- 1) Remove the two superseded 'Entity Object Data' RecordData EntityActionParam rows.
DELETE FROM [${mjSchema}].[EntityActionParam]
 WHERE [ID] IN (
     '01F9747B-6F07-4671-A44E-953113442878',
     '42AF8F1E-0B3E-4879-A72C-9D728D9DFAAB'
 );
GO

-- 2) Switch both Relationships Common.LogActivity bindings to RunMode = 'Durable'.
UPDATE [${mjSchema}].[EntityAction]
   SET [RunMode] = N'Durable',
       [__mj_UpdatedAt] = GETUTCDATE()
 WHERE [ID] IN (
     'ABF0B899-C4D8-4BF8-9AE8-4EAE7DD32346',
     '32D1707C-D9BE-48F7-BB46-701F8DB09110'
 );
GO

-- 3) Set LogValue = 1 on both Relationships LinkFields EntityActionParam rows.
UPDATE [${mjSchema}].[EntityActionParam]
   SET [LogValue] = 1,
       [__mj_UpdatedAt] = GETUTCDATE()
 WHERE [ID] IN (
     '0002071D-7D2B-4777-A211-9F4CCD3626E9',
     'C3209787-8595-49A9-A026-3C45237AB2EC'
 );
GO

-- 4) Seed the two Script RecordData EntityActionParam rows for hosts upgrading via migration.
INSERT INTO [${mjSchema}].[EntityActionParam] ([ID], [EntityActionID], [ActionParamID], [ValueType], [Value], [LogValue], [Comments])
SELECT v.[ID], v.[EntityActionID], v.[ActionParamID], v.[ValueType], v.[Value], v.[LogValue], v.[Comments]
  FROM (
      VALUES
          (
              CAST('01F9747B-6F07-4671-A44E-953113442879' AS UNIQUEIDENTIFIER),
              CAST('ABF0B899-C4D8-4BF8-9AE8-4EAE7DD32346' AS UNIQUEIDENTIFIER),
              CAST('D067FFE0-70B2-4A28-9C31-066BB536E637' AS UNIQUEIDENTIFIER),
              N'Script',
              N'return { ID: EntityActionContext.entityObject.ID, FromPersonID: EntityActionContext.entityObject.FromPersonID, ToPersonID: EntityActionContext.entityObject.ToPersonID, FromOrganizationID: EntityActionContext.entityObject.FromOrganizationID, ToOrganizationID: EntityActionContext.entityObject.ToOrganizationID };',
              CAST(1 AS BIT),
              N'RecordData — projects only the five party/record IDs needed for LinkFields so RedactParams keeps it in the durable task payload.'
          ),
          (
              CAST('42AF8F1E-0B3E-4879-A72C-9D728D9DFAAC' AS UNIQUEIDENTIFIER),
              CAST('32D1707C-D9BE-48F7-BB46-701F8DB09110' AS UNIQUEIDENTIFIER),
              CAST('D067FFE0-70B2-4A28-9C31-066BB536E637' AS UNIQUEIDENTIFIER),
              N'Script',
              N'return { ID: EntityActionContext.entityObject.ID, FromPersonID: EntityActionContext.entityObject.FromPersonID, ToPersonID: EntityActionContext.entityObject.ToPersonID, FromOrganizationID: EntityActionContext.entityObject.FromOrganizationID, ToOrganizationID: EntityActionContext.entityObject.ToOrganizationID };',
              CAST(1 AS BIT),
              N'RecordData — projects only the five party/record IDs needed for LinkFields so RedactParams keeps it in the durable task payload. No EventKey: a relationship can end, restart and end again; each transition is its own entry.'
          )
  ) AS v([ID], [EntityActionID], [ActionParamID], [ValueType], [Value], [LogValue], [Comments])
 INNER JOIN [${mjSchema}].[EntityAction] ea
    ON ea.[ID] = v.[EntityActionID]
 INNER JOIN [${mjSchema}].[ActionParam] ap
    ON ap.[ID] = v.[ActionParamID]
  LEFT JOIN [${mjSchema}].[EntityActionParam] existing
    ON existing.[ID] = v.[ID]
 WHERE existing.[ID] IS NULL;
GO


















































/* ============================================================================================
   ==== CODEGEN OUTPUT — DO NOT EDIT BELOW THIS LINE ====
   ============================================================================================ */
