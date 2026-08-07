-- =============================================================================
-- v5.33.x — Decouple Person from MJ User
-- =============================================================================
-- Context: https://github.com/MemberJunction/bizapps-common/issues/36
--
-- bizapps-common is a generic CRM layer: a Person is a record of a human
-- being, with no implication of platform access. The LinkedUserID column (and
-- the PersonEntityServer auto-provisioning hooks removed in this release)
-- coupled every emailed Person to an active MJ User with the 'UI' role —
-- wrong for job applicants, CRM contacts, and message senders.
--
-- This migration:
--   1. Marks the Person.LinkedUserID EntityField as Status='Deprecated'
--      (runtime emits console warnings on Get/Set; generated classes gain
--      @deprecated JSDoc; views/SPs/GraphQL remain functional).
--   2. Rewrites the column's MS_Description extended property with a
--      DEPRECATED: prefix. NOTE: with AutoUpdateDescription=1, EntityField
--      Description re-syncs from the extended property every migrate cycle,
--      so the deprecation text MUST live in the extended property (see MJ's
--      V202606021427__v5.39.x deprecation migration for the precedent).
--   3. Sets AllowMultipleSubtypes=1 on the People entity, declaring it an
--      overlapping IS-A parent: a Person may be several subtypes at once
--      (e.g., a platform user AND an applicant), parent-side saves never
--      delegate to a subtype, and multiple products may layer their own
--      subtype entities on Person.
--
-- The column, FK_Person_LinkedUser, and UQ_Person_LinkedUserID remain
-- physically in place for backward compatibility. Data disposition is owned
-- by the platform layer: BCSaaS v1.8.0's migration moves LinkedUserID values
-- into its __BCSaaS.Person IS-A subtype (shared PK with Person),
-- repoints User back-pointers, and nulls this column. This migration moves
-- NO data — it always runs before the platform layer's.
-- =============================================================================

DECLARE @PeopleEntityID UNIQUEIDENTIFIER = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F';
DECLARE @DeprecationText NVARCHAR(1000) = N'DEPRECATED: Do not use. bizapps-common no longer reads or writes this column; person-to-MJ-User bindings are owned by platform-layer IS-A subtypes of Person (e.g., BCSaaS ''BC: People''). Retained only for backward compatibility and scheduled for removal in the next major release.';

-- -----------------------------------------------------------------------------
-- 1. Mark the EntityField as Deprecated
-- -----------------------------------------------------------------------------
UPDATE ef
SET ef.Status = N'Deprecated',
    ef.Description = @DeprecationText
FROM [${mjSchema}].[EntityField] ef
WHERE ef.EntityID = @PeopleEntityID
  AND ef.Name = N'LinkedUserID';

IF @@ROWCOUNT = 0
BEGIN
    RAISERROR(N'Expected EntityField LinkedUserID on entity MJ_BizApps_Common: People (7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F) was not found. Aborting migration.', 16, 1);
    SET NOEXEC ON;
END

-- -----------------------------------------------------------------------------
-- 2. Rewrite the column-level MS_Description extended property
-- -----------------------------------------------------------------------------
IF EXISTS (
    SELECT 1 FROM sys.extended_properties ep
    JOIN sys.columns c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
    WHERE ep.name = N'MS_Description'
      AND ep.class = 1
      AND c.object_id = OBJECT_ID(N'[${flyway:defaultSchema}].[Person]')
      AND c.name = N'LinkedUserID'
)
BEGIN
    EXEC sp_updateextendedproperty
        @name = N'MS_Description', @value = @DeprecationText,
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE',  @level1name = N'Person',
        @level2type = N'COLUMN', @level2name = N'LinkedUserID';
END
ELSE
BEGIN
    EXEC sp_addextendedproperty
        @name = N'MS_Description', @value = @DeprecationText,
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE',  @level1name = N'Person',
        @level2type = N'COLUMN', @level2name = N'LinkedUserID';
END

IF @@ERROR <> 0 SET NOEXEC ON;

-- -----------------------------------------------------------------------------
-- 3. Declare People as an overlapping IS-A parent
-- -----------------------------------------------------------------------------
UPDATE [${mjSchema}].[Entity]
SET AllowMultipleSubtypes = 1
WHERE ID = @PeopleEntityID
  AND AllowMultipleSubtypes = 0;

IF @@ERROR <> 0 SET NOEXEC ON;

SET NOEXEC OFF;
