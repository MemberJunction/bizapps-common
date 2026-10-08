-- =============================================================================
-- Migration: V202610081600__v5.52.x__People_Field_Level_Security.sql
-- Description: Turn on field-level security for MJ_BizApps_Common: People and
--              give every role that can read People a permission row on each
--              restrictable field, computed from this host's own permissions
--              (#216, #186).
--
-- Why: Collaboration guests and participants may read only People's name and
-- email fields. Without field-level security, any role with People read sees
-- every field (phone, birth date, gender, address).
--
-- Why the rows are computed here: on an entity with field-level security on, a
-- field with no MJ: Entity Field Permissions row is denied to every user, the
-- system user included. MJ writes the rows only when an Entity or
-- EntityPermission is saved through its entity layer, or in CodeGen; hosts
-- upgrade by migration and run neither. Rows captured from a build database
-- would apply that database's roles, not the host's. So this migration applies
-- MJ's snapshot rule (MJCoreEntitiesServer fieldPermissionDelta.ts,
-- ComputeFieldPermissionDelta) to the host's own EntityPermission rows:
--   * Roles: each role's People permissions, Allow minus Deny per verb. Only
--     roles left with Read get rows.
--   * Fields: People's restrictable fields: not a primary key, not a soft
--     primary key, not an __mj_ column.
--   * ReadAccess = Allow. UpdateAccess / CreateAccess = Allow only when the
--     field is writable (AllowUpdateAPI = 1) and the role has the verb;
--     otherwise No Access.
--   * An existing (EntityFieldID, RoleID) row is never touched, as in MJ.
-- The snapshot changes no access: each role keeps exactly what its entity-level
-- permission gave it, until an administrator tightens a field.
--
-- The flag and the rows land in one migration, so one transaction: no host is
-- ever left with the flag on and no rows. metadata/entities/.entities.json
-- already declares EnableFieldLevelSecurity = true, so the next release seed's
-- push sees no change on People and does not reconcile build-database rows
-- into the seed.
--
-- The INSERT is the reusable block in migrations/README.md ("People columns
-- ship their field permissions"). A later migration that adds a People column
-- appends the same block after its CodeGen output.
--
-- Recovery: if a host's rows are ever wrong or missing, saving any People
-- Entity Permission through the UI makes MJ reconcile People for all roles.
-- =============================================================================

DECLARE @FLSEntityID UNIQUEIDENTIFIER = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'; -- MJ_BizApps_Common: People

-- ---- People field permissions: MJ snapshot rule on this host's permissions ----
;WITH RoleVerbs AS (
    SELECT ep.RoleID,
           MAX(CASE WHEN ISNULL(LTRIM(RTRIM(ep.[Type])), N'Allow') <> N'Deny' AND ep.CanRead   = 1 THEN 1 ELSE 0 END) AS AllowRead,
           MAX(CASE WHEN ISNULL(LTRIM(RTRIM(ep.[Type])), N'Allow') <> N'Deny' AND ep.CanUpdate = 1 THEN 1 ELSE 0 END) AS AllowUpdate,
           MAX(CASE WHEN ISNULL(LTRIM(RTRIM(ep.[Type])), N'Allow') <> N'Deny' AND ep.CanCreate = 1 THEN 1 ELSE 0 END) AS AllowCreate,
           MAX(CASE WHEN ISNULL(LTRIM(RTRIM(ep.[Type])), N'Allow') =  N'Deny' AND ep.CanRead   = 1 THEN 1 ELSE 0 END) AS DenyRead,
           MAX(CASE WHEN ISNULL(LTRIM(RTRIM(ep.[Type])), N'Allow') =  N'Deny' AND ep.CanUpdate = 1 THEN 1 ELSE 0 END) AS DenyUpdate,
           MAX(CASE WHEN ISNULL(LTRIM(RTRIM(ep.[Type])), N'Allow') =  N'Deny' AND ep.CanCreate = 1 THEN 1 ELSE 0 END) AS DenyCreate
    FROM [${mjSchema}].[EntityPermission] ep
    WHERE ep.EntityID = @FLSEntityID
    GROUP BY ep.RoleID
),
RoleAccess AS (
    SELECT RoleID,
           CASE WHEN AllowUpdate = 1 AND DenyUpdate = 0 THEN 1 ELSE 0 END AS CanUpdate,
           CASE WHEN AllowCreate = 1 AND DenyCreate = 0 THEN 1 ELSE 0 END AS CanCreate
    FROM RoleVerbs
    WHERE AllowRead = 1 AND DenyRead = 0
)
INSERT INTO [${mjSchema}].[EntityFieldPermission] (EntityFieldID, RoleID, ReadAccess, UpdateAccess, CreateAccess)
SELECT ef.ID,
       ra.RoleID,
       N'Allow',
       CASE WHEN ef.AllowUpdateAPI = 1 AND ra.CanUpdate = 1 THEN N'Allow' ELSE N'No Access' END,
       CASE WHEN ef.AllowUpdateAPI = 1 AND ra.CanCreate = 1 THEN N'Allow' ELSE N'No Access' END
FROM [${mjSchema}].[EntityField] ef
CROSS JOIN RoleAccess ra
WHERE ef.EntityID = @FLSEntityID
  AND ef.IsPrimaryKey = 0
  AND ef.IsSoftPrimaryKey = 0
  AND LEFT(ef.Name, 5) <> N'__mj_'
  AND NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityFieldPermission] x
      WHERE x.EntityFieldID = ef.ID AND x.RoleID = ra.RoleID
  );
-- ---- end block ----

UPDATE [${mjSchema}].[Entity]
SET EnableFieldLevelSecurity = 1
WHERE ID = @FLSEntityID;
