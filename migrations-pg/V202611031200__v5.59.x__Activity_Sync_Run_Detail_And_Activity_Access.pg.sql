-- =============================================================================================
-- PostgreSQL counterpart of V202611031200__v5.59.x__Activity_Sync_Run_Detail_And_Activity_Access.sql
-- =============================================================================================

SET standard_conforming_strings = on;
SET search_path TO __mj_bizappscommon, public;

-- -----------------------------------------------------------------------------
-- Part 1: Activity Sync Run Details — UI CanRead + Field-Level Security
-- -----------------------------------------------------------------------------

UPDATE ${mjSchema}."EntityPermission"
   SET "CanRead" = TRUE,
       "__mj_UpdatedAt" = NOW()
 WHERE "EntityID" = 'AC16B066-9460-44F5-B027-3FD397E61F34'
   AND "RoleID" = 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E';

WITH "RoleVerbs" AS (
    SELECT ep."RoleID",
           MAX(CASE WHEN COALESCE(LTRIM(RTRIM(ep."Type")), 'Allow') <> 'Deny' AND ep."CanRead"   = TRUE THEN 1 ELSE 0 END) AS "AllowRead",
           MAX(CASE WHEN COALESCE(LTRIM(RTRIM(ep."Type")), 'Allow') <> 'Deny' AND ep."CanUpdate" = TRUE THEN 1 ELSE 0 END) AS "AllowUpdate",
           MAX(CASE WHEN COALESCE(LTRIM(RTRIM(ep."Type")), 'Allow') <> 'Deny' AND ep."CanCreate" = TRUE THEN 1 ELSE 0 END) AS "AllowCreate",
           MAX(CASE WHEN COALESCE(LTRIM(RTRIM(ep."Type")), 'Allow') =  'Deny' AND ep."CanRead"   = TRUE THEN 1 ELSE 0 END) AS "DenyRead",
           MAX(CASE WHEN COALESCE(LTRIM(RTRIM(ep."Type")), 'Allow') =  'Deny' AND ep."CanUpdate" = TRUE THEN 1 ELSE 0 END) AS "DenyUpdate",
           MAX(CASE WHEN COALESCE(LTRIM(RTRIM(ep."Type")), 'Allow') =  'Deny' AND ep."CanCreate" = TRUE THEN 1 ELSE 0 END) AS "DenyCreate"
      FROM ${mjSchema}."EntityPermission" ep
     WHERE ep."EntityID" = 'AC16B066-9460-44F5-B027-3FD397E61F34'
     GROUP BY ep."RoleID"
),
"RoleAccess" AS (
    SELECT "RoleID",
           CASE WHEN "AllowRead"   = 1 AND "DenyRead"   = 0 THEN 1 ELSE 0 END AS "HasRead",
           CASE WHEN "AllowUpdate" = 1 AND "DenyUpdate" = 0 THEN 1 ELSE 0 END AS "HasUpdate",
           CASE WHEN "AllowCreate" = 1 AND "DenyCreate" = 0 THEN 1 ELSE 0 END AS "HasCreate"
      FROM "RoleVerbs"
     WHERE ("AllowRead" = 1 AND "DenyRead" = 0)
        OR ("AllowUpdate" = 1 AND "DenyUpdate" = 0)
        OR ("AllowCreate" = 1 AND "DenyCreate" = 0)
)
INSERT INTO ${mjSchema}."EntityFieldPermission" ("EntityFieldID", "RoleID", "ReadAccess", "UpdateAccess", "CreateAccess")
SELECT ef."ID",
       ra."RoleID",
       CASE
           WHEN ef."Name" IN ('CapturedContent', 'EncryptionKeyID', 'EncryptionKey') THEN
               CASE WHEN ra."RoleID" = 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AND ra."HasRead" = 1 THEN 'Allow' ELSE 'No Access' END
           WHEN ra."HasRead" = 1 THEN 'Allow'
           ELSE 'No Access'
       END,
       CASE
           WHEN ef."IsPrimaryKey" = FALSE AND ef."IsVirtual" = FALSE AND ef."Name" NOT IN ('__mj_CreatedAt', '__mj_UpdatedAt') AND ef."AllowUpdateAPI" = TRUE AND ra."HasUpdate" = 1 THEN 'Allow'
           ELSE 'No Access'
       END,
       CASE
           WHEN ef."IsPrimaryKey" = FALSE AND ef."IsVirtual" = FALSE AND ef."Name" NOT IN ('__mj_CreatedAt', '__mj_UpdatedAt') AND ef."AllowUpdateAPI" = TRUE AND ra."HasCreate" = 1 THEN 'Allow'
           ELSE 'No Access'
       END
  FROM ${mjSchema}."EntityField" ef
 CROSS JOIN "RoleAccess" ra
  LEFT JOIN ${mjSchema}."EntityFieldPermission" existing
    ON existing."EntityFieldID" = ef."ID"
   AND existing."RoleID" = ra."RoleID"
 WHERE ef."EntityID" = 'AC16B066-9460-44F5-B027-3FD397E61F34'
   AND ef."IsPrimaryKey" = FALSE
   AND ef."IsSoftPrimaryKey" = FALSE
   AND LEFT(ef."Name", 5) <> '__mj_'
   AND existing."ID" IS NULL;

UPDATE ${mjSchema}."EntityFieldPermission" efp
   SET "ReadAccess" = 'No Access',
       "__mj_UpdatedAt" = NOW()
  FROM ${mjSchema}."EntityField" ef
 WHERE ef."ID" = efp."EntityFieldID"
   AND ef."EntityID" = 'AC16B066-9460-44F5-B027-3FD397E61F34'
   AND ef."Name" IN ('CapturedContent', 'EncryptionKeyID', 'EncryptionKey')
   AND efp."RoleID" <> 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E';

UPDATE ${mjSchema}."Entity"
   SET "EnableFieldLevelSecurity" = TRUE,
       "__mj_UpdatedAt" = NOW()
 WHERE "ID" = 'AC16B066-9460-44F5-B027-3FD397E61F34';

-- -----------------------------------------------------------------------------
-- Part 2: Activities — Row-Level Security for Private visibility on UI role
-- -----------------------------------------------------------------------------

INSERT INTO ${mjSchema}."RowLevelSecurityFilter" ("ID", "Name", "Description", "FilterText", "PlatformVariants")
SELECT v."ID", v."Name", v."Description", v."FilterText", v."PlatformVariants"
  FROM (
      VALUES (
          CAST('72E55425-8822-4E70-A075-000000000347' AS UUID),
          'Common: Non-Private or Own Activities',
          'Allows reading non-Private Activities, or Private Activities created by the requesting user or ingested through a connection owned by the requesting user.',
          '([Visibility] <> N''Private'' OR [LoggedByUserID] = ''{{UserID}}'' OR [ActivitySyncConnectionID] IN (SELECT [ID] FROM [__mj_BizAppsCommon].[ActivitySyncConnection] WHERE [OwnerUserID] = ''{{UserID}}''))',
          '{"postgresql":{"FilterText":"(\"Visibility\" <> ''Private'' OR \"LoggedByUserID\" = ''{{UserID}}''::uuid OR \"ActivitySyncConnectionID\" IN (SELECT \"ID\" FROM \"__mj_BizAppsCommon\".\"ActivitySyncConnection\" WHERE \"OwnerUserID\" = ''{{UserID}}''::uuid))"}}'
      )
  ) AS v("ID", "Name", "Description", "FilterText", "PlatformVariants")
  LEFT JOIN ${mjSchema}."RowLevelSecurityFilter" existing
    ON existing."ID" = v."ID"
    OR existing."Name" = v."Name"
 WHERE existing."ID" IS NULL;

UPDATE ${mjSchema}."EntityPermission"
   SET "ReadRLSFilterID" = '72E55425-8822-4E70-A075-000000000347',
       "__mj_UpdatedAt" = NOW()
 WHERE "EntityID" = '72E55425-8822-4E70-A075-116219CA5A5D'
   AND "RoleID" = 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E';
