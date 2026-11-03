-- =============================================================================
-- Migration: V202611031200__v5.59.x__Activity_Sync_Run_Detail_And_Activity_Access.sql
-- Description: Enable Field-Level Security on MJ_BizApps_Common: Activity Sync Run Details
--              (restoring UI read for non-sensitive diagnostic columns while restricting
--              CapturedContent, EncryptionKeyID, and EncryptionKey to Developer) and
--              apply Row-Level Security on MJ_BizApps_Common: Activities for the UI role
--              so Private activities are visible only to their creator or connection owner.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Part 1: Activity Sync Run Details — UI CanRead + Field-Level Security
-- -----------------------------------------------------------------------------
-- AC16B066-9460-44F5-B027-3FD397E61F34 = MJ_BizApps_Common: Activity Sync Run Details
-- E0AFCCEC-6A37-EF11-86D4-000D3A4E707E = UI role
-- DEAFCCEC-6A37-EF11-86D4-000D3A4E707E = Developer role

UPDATE [${mjSchema}].[EntityPermission]
   SET [CanRead] = 1,
       [__mj_UpdatedAt] = GETUTCDATE()
 WHERE [EntityID] = 'AC16B066-9460-44F5-B027-3FD397E61F34'
   AND [RoleID] = 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E';
GO

;WITH RoleVerbs AS (
    SELECT ep.[RoleID],
           MAX(CASE WHEN ISNULL(LTRIM(RTRIM(ep.[Type])), N'Allow') <> N'Deny' AND ep.[CanRead]   = 1 THEN 1 ELSE 0 END) AS AllowRead,
           MAX(CASE WHEN ISNULL(LTRIM(RTRIM(ep.[Type])), N'Allow') <> N'Deny' AND ep.[CanUpdate] = 1 THEN 1 ELSE 0 END) AS AllowUpdate,
           MAX(CASE WHEN ISNULL(LTRIM(RTRIM(ep.[Type])), N'Allow') <> N'Deny' AND ep.[CanCreate] = 1 THEN 1 ELSE 0 END) AS AllowCreate,
           MAX(CASE WHEN ISNULL(LTRIM(RTRIM(ep.[Type])), N'Allow') =  N'Deny' AND ep.[CanRead]   = 1 THEN 1 ELSE 0 END) AS DenyRead,
           MAX(CASE WHEN ISNULL(LTRIM(RTRIM(ep.[Type])), N'Allow') =  N'Deny' AND ep.[CanUpdate] = 1 THEN 1 ELSE 0 END) AS DenyUpdate,
           MAX(CASE WHEN ISNULL(LTRIM(RTRIM(ep.[Type])), N'Allow') =  N'Deny' AND ep.[CanCreate] = 1 THEN 1 ELSE 0 END) AS DenyCreate
      FROM [${mjSchema}].[EntityPermission] ep
     WHERE ep.[EntityID] = 'AC16B066-9460-44F5-B027-3FD397E61F34'
     GROUP BY ep.[RoleID]
),
RoleAccess AS (
    SELECT [RoleID],
           CASE WHEN AllowRead   = 1 AND DenyRead   = 0 THEN 1 ELSE 0 END AS HasRead,
           CASE WHEN AllowUpdate = 1 AND DenyUpdate = 0 THEN 1 ELSE 0 END AS HasUpdate,
           CASE WHEN AllowCreate = 1 AND DenyCreate = 0 THEN 1 ELSE 0 END AS HasCreate
      FROM RoleVerbs
     WHERE (AllowRead = 1 AND DenyRead = 0)
        OR (AllowUpdate = 1 AND DenyUpdate = 0)
        OR (AllowCreate = 1 AND DenyCreate = 0)
)
INSERT INTO [${mjSchema}].[EntityFieldPermission] ([EntityFieldID], [RoleID], [ReadAccess], [UpdateAccess], [CreateAccess])
SELECT ef.[ID],
       ra.[RoleID],
       CASE
           WHEN ef.[Name] IN (N'CapturedContent', N'EncryptionKeyID', N'EncryptionKey') THEN
               CASE WHEN ra.[RoleID] = 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AND ra.HasRead = 1 THEN N'Allow' ELSE N'No Access' END
           WHEN ra.HasRead = 1 THEN N'Allow'
           ELSE N'No Access'
       END,
       CASE
           WHEN ef.[IsPrimaryKey] = 0 AND ef.[IsVirtual] = 0 AND ef.[Name] NOT IN (N'__mj_CreatedAt', N'__mj_UpdatedAt') AND ef.[AllowUpdateAPI] = 1 AND ra.HasUpdate = 1 THEN N'Allow'
           ELSE N'No Access'
       END,
       CASE
           WHEN ef.[IsPrimaryKey] = 0 AND ef.[IsVirtual] = 0 AND ef.[Name] NOT IN (N'__mj_CreatedAt', N'__mj_UpdatedAt') AND ef.[AllowUpdateAPI] = 1 AND ra.HasCreate = 1 THEN N'Allow'
           ELSE N'No Access'
       END
  FROM [${mjSchema}].[EntityField] ef
 CROSS JOIN RoleAccess ra
  LEFT JOIN [${mjSchema}].[EntityFieldPermission] existing
    ON existing.[EntityFieldID] = ef.[ID]
   AND existing.[RoleID] = ra.[RoleID]
 WHERE ef.[EntityID] = 'AC16B066-9460-44F5-B027-3FD397E61F34'
   AND ef.[IsPrimaryKey] = 0
   AND ef.[IsSoftPrimaryKey] = 0
   AND LEFT(ef.[Name], 5) <> N'__mj_'
   AND existing.[ID] IS NULL;
GO

UPDATE efp
   SET efp.[ReadAccess] = N'No Access',
       efp.[__mj_UpdatedAt] = GETUTCDATE()
  FROM [${mjSchema}].[EntityFieldPermission] efp
 INNER JOIN [${mjSchema}].[EntityField] ef
    ON ef.[ID] = efp.[EntityFieldID]
 WHERE ef.[EntityID] = 'AC16B066-9460-44F5-B027-3FD397E61F34'
   AND ef.[Name] IN (N'CapturedContent', N'EncryptionKeyID', N'EncryptionKey')
   AND efp.[RoleID] <> 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E';
GO

UPDATE [${mjSchema}].[Entity]
   SET [EnableFieldLevelSecurity] = 1,
       [__mj_UpdatedAt] = GETUTCDATE()
 WHERE [ID] = 'AC16B066-9460-44F5-B027-3FD397E61F34';
GO

-- -----------------------------------------------------------------------------
-- Part 2: Activities — Row-Level Security for Private visibility on UI role
-- -----------------------------------------------------------------------------
-- 72E55425-8822-4E70-A075-116219CA5A5D = MJ_BizApps_Common: Activities
-- 72E55425-8822-4E70-A075-000000000347 = RowLevelSecurityFilter: Common: Non-Private or Own Activities

INSERT INTO [${mjSchema}].[RowLevelSecurityFilter] ([ID], [Name], [Description], [FilterText], [PlatformVariants])
SELECT v.[ID], v.[Name], v.[Description], v.[FilterText], v.[PlatformVariants]
  FROM (
      VALUES (
          CAST('72E55425-8822-4E70-A075-000000000347' AS UNIQUEIDENTIFIER),
          N'Common: Non-Private or Own Activities',
          N'Allows reading non-Private Activities, or Private Activities created by the requesting user or ingested through a connection owned by the requesting user.',
          N'([Visibility] <> N''Private'' OR [LoggedByUserID] = ''{{UserID}}'' OR [ActivitySyncConnectionID] IN (SELECT [ID] FROM [${flyway:defaultSchema}].[ActivitySyncConnection] WHERE [OwnerUserID] = ''{{UserID}}''))',
          N'{"postgresql":{"FilterText":"(\"Visibility\" <> ''Private'' OR \"LoggedByUserID\" = ''{{UserID}}''::uuid OR \"ActivitySyncConnectionID\" IN (SELECT \"ID\" FROM \"__mj_BizAppsCommon\".\"ActivitySyncConnection\" WHERE \"OwnerUserID\" = ''{{UserID}}''::uuid))"}}'
      )
  ) AS v([ID], [Name], [Description], [FilterText], [PlatformVariants])
  LEFT JOIN [${mjSchema}].[RowLevelSecurityFilter] existing
    ON existing.[ID] = v.[ID]
    OR existing.[Name] = v.[Name]
 WHERE existing.[ID] IS NULL;
GO

UPDATE [${mjSchema}].[EntityPermission]
   SET [ReadRLSFilterID] = '72E55425-8822-4E70-A075-000000000347',
       [__mj_UpdatedAt] = GETUTCDATE()
 WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D'
   AND [RoleID] = 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E';
GO


















































/* ============================================================================================
   ==== CODEGEN OUTPUT — DO NOT EDIT BELOW THIS LINE ====
   ============================================================================================ */
