-- =====================================================================
-- v6.1 People & Organizations: overlapping subtypes + soft delete + record merge
-- =====================================================================
--
-- Enables downstream apps (BizApps Sales, AIDP-next CDP, etc.) to attach
-- MULTIPLE IsA subtypes to the same Person / Organization record, and turns
-- both parent entities into soft-delete + record-merge entities:
--
--   1. AllowMultipleSubtypes = 1   -- relax MJ's disjoint-subtype default so a
--                                     single Person/Organization can be the parent
--                                     of more than one IsA child (e.g. SalesContact
--                                     AND crm.Contact on the same Person).
--   2. AllowRecordMerge     = 1   -- allow MJ's record-merge feature on both.
--   3. DeleteType           = Soft -- deletes stamp __mj_DeletedAt instead of
--                                     physically removing the row (merge retains
--                                     the losing record for audit).
--
-- Soft delete requires the reserved __mj_DeletedAt column on each base table, the
-- matching EntityField metadata, regenerated spDelete procedures (UPDATE instead
-- of DELETE), and regenerated base views that filter out soft-deleted rows.
--
-- These are the hand-authored inputs a subsequent `mj codegen` run reconciles;
-- the regenerated spDelete procedures and base views below match CodeGen's output
-- for DeleteType=Soft entities so the change is functional even before the next
-- CodeGen replay.
--
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. DDL: add the reserved soft-delete column (nullable, no default) to
--    both base tables.
-- ---------------------------------------------------------------------

/* SQL text to add special date field __mj_DeletedAt to entity ${flyway:defaultSchema}.Person */
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('[${flyway:defaultSchema}].[Person]') AND name = '__mj_DeletedAt'
)
    ALTER TABLE [${flyway:defaultSchema}].[Person] ADD __mj_DeletedAt DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_DeletedAt to entity ${flyway:defaultSchema}.Organization */
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('[${flyway:defaultSchema}].[Organization]') AND name = '__mj_DeletedAt'
)
    ALTER TABLE [${flyway:defaultSchema}].[Organization] ADD __mj_DeletedAt DATETIMEOFFSET NULL;
GO


-- ---------------------------------------------------------------------
-- 2. Metadata: register the __mj_DeletedAt EntityField for both entities.
--    (Modeled on the generated __mj_UpdatedAt field; nullable, no default,
--    not updatable through the API.)
-- ---------------------------------------------------------------------

/* SQL text to insert new entity field __mj_DeletedAt for MJ_BizApps_Common: People */
IF NOT EXISTS (
    SELECT 1 FROM [${mjSchema}].[EntityField]
    WHERE ID = 'f7c1d7ad-0309-4c7f-9f3f-dbe771bf9ed0'
       OR (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = '__mj_DeletedAt')
)
BEGIN
    INSERT INTO [${mjSchema}].[EntityField]
    (
        ID, EntityID, Sequence, Name, DisplayName, Description, Type, Length, Precision, Scale,
        AllowsNull, DefaultValue, AutoIncrement, AllowUpdateAPI, IsVirtual, RelatedEntityID,
        RelatedEntityFieldName, IsNameField, IncludeInUserSearchAPI, IncludeRelatedEntityNameFieldInBaseView,
        DefaultInView, IsPrimaryKey, IsUnique, RelatedEntityDisplayType
    )
    VALUES
    (
        'f7c1d7ad-0309-4c7f-9f3f-dbe771bf9ed0',
        '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ_BizApps_Common: People
        (SELECT ISNULL(MAX(Sequence), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F'),
        '__mj_DeletedAt',
        'Deleted At',
        NULL,
        'datetimeoffset',
        10,
        34,
        7,
        1,      -- AllowsNull
        NULL,   -- DefaultValue
        0,      -- AutoIncrement
        0,      -- AllowUpdateAPI
        0,      -- IsVirtual
        NULL,
        NULL,
        0,
        0,
        0,
        0,
        0,
        0,
        'Search'
    )
END
GO

/* SQL text to insert new entity field __mj_DeletedAt for MJ_BizApps_Common: Organizations */
IF NOT EXISTS (
    SELECT 1 FROM [${mjSchema}].[EntityField]
    WHERE ID = 'd6637a22-acf9-4fb3-8537-6b4a9cd12d69'
       OR (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = '__mj_DeletedAt')
)
BEGIN
    INSERT INTO [${mjSchema}].[EntityField]
    (
        ID, EntityID, Sequence, Name, DisplayName, Description, Type, Length, Precision, Scale,
        AllowsNull, DefaultValue, AutoIncrement, AllowUpdateAPI, IsVirtual, RelatedEntityID,
        RelatedEntityFieldName, IsNameField, IncludeInUserSearchAPI, IncludeRelatedEntityNameFieldInBaseView,
        DefaultInView, IsPrimaryKey, IsUnique, RelatedEntityDisplayType
    )
    VALUES
    (
        'd6637a22-acf9-4fb3-8537-6b4a9cd12d69',
        'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ_BizApps_Common: Organizations
        (SELECT ISNULL(MAX(Sequence), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54'),
        '__mj_DeletedAt',
        'Deleted At',
        NULL,
        'datetimeoffset',
        10,
        34,
        7,
        1,      -- AllowsNull
        NULL,   -- DefaultValue
        0,      -- AutoIncrement
        0,      -- AllowUpdateAPI
        0,      -- IsVirtual
        NULL,
        NULL,
        0,
        0,
        0,
        0,
        0,
        0,
        'Search'
    )
END
GO


-- ---------------------------------------------------------------------
-- 3. Metadata: flip the entity-level flags on both parents.
-- ---------------------------------------------------------------------

/* SQL text to enable overlapping subtypes, record merge, and soft delete on People & Organizations */
UPDATE [${mjSchema}].[Entity]
SET
    AllowMultipleSubtypes = 1,
    AllowRecordMerge      = 1,
    DeleteType            = N'Soft'
WHERE ID IN (
    '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- MJ_BizApps_Common: People
    'C70448F9-9792-41D7-A82C-784B66429D54'  -- MJ_BizApps_Common: Organizations
);
GO


-- ---------------------------------------------------------------------
-- 4. Regenerate spDelete procedures as soft deletes (UPDATE __mj_DeletedAt
--    instead of DELETE). Matches MJ CodeGen output for DeleteType=Soft.
-- ---------------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Person
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeletePerson]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeletePerson];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeletePerson]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE
        [${flyway:defaultSchema}].[Person]
    SET
        __mj_DeletedAt = GETUTCDATE()
    WHERE
        [ID] = @ID
        AND __mj_DeletedAt IS NULL -- don't update the record if it's already been deleted via a soft delete

    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeletePerson] TO [cdp_Integration]
GO

------------------------------------------------------------
----- DELETE PROCEDURE FOR Organization
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteOrganization]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteOrganization];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteOrganization]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE
        [${flyway:defaultSchema}].[Organization]
    SET
        __mj_DeletedAt = GETUTCDATE()
    WHERE
        [ID] = @ID
        AND __mj_DeletedAt IS NULL -- don't update the record if it's already been deleted via a soft delete

    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteOrganization] TO [cdp_Integration]
GO


-- ---------------------------------------------------------------------
-- 5. Regenerate base views to exclude soft-deleted rows. __mj_DeletedAt
--    is included automatically via the base-table wildcard (t.*).
-- ---------------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: People
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  Person
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwPeople]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwPeople];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwPeople]
AS
SELECT
    p.*,
    MJUser_LinkedUserID.[Name] AS [LinkedUser]
FROM
    [${flyway:defaultSchema}].[Person] AS p
LEFT OUTER JOIN
    [${mjSchema}].[User] AS MJUser_LinkedUserID
  ON
    [p].[LinkedUserID] = MJUser_LinkedUserID.[ID]
WHERE
    p.[__mj_DeletedAt] IS NULL
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwPeople] TO [cdp_UI], [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Organizations
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  Organization
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwOrganizations]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwOrganizations];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwOrganizations]
AS
SELECT
    o.*,
    mjBizAppsCommonOrganizationType_OrganizationTypeID.[Name] AS [OrganizationType],
    mjBizAppsCommonOrganization_ParentID.[Name] AS [Parent],
    root_ParentID.RootID AS [RootParentID]
FROM
    [${flyway:defaultSchema}].[Organization] AS o
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[OrganizationType] AS mjBizAppsCommonOrganizationType_OrganizationTypeID
  ON
    [o].[OrganizationTypeID] = mjBizAppsCommonOrganizationType_OrganizationTypeID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Organization] AS mjBizAppsCommonOrganization_ParentID
  ON
    [o].[ParentID] = mjBizAppsCommonOrganization_ParentID.[ID]
OUTER APPLY
    [${flyway:defaultSchema}].[fnOrganizationParentID_GetRootID]([o].[ID], [o].[ParentID]) AS root_ParentID
WHERE
    o.[__mj_DeletedAt] IS NULL
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwOrganizations] TO [cdp_UI], [cdp_Developer], [cdp_Integration];
GO
