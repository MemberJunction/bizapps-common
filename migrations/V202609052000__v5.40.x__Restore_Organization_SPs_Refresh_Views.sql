-- =============================================================================
-- Migration: V202609052000__v5.40.x__Restore_Organization_SPs_Refresh_Views.sql
-- Follow-up to V202609051800 (PR #123, loom #12 WP1). That migration widened
-- Person.PhotoURL / Organization.LogoURL to NVARCHAR(MAX) correctly, but:
--   1. it re-created spCreateOrganization / spUpdateOrganization /
--      spDeleteOrganization from an older capture (V202608241515) instead of
--      the current CodeGen output (V202608252150). That re-introduced cascade
--      deletes of ContactMethod / AddressLink / Relationship in
--      spDeleteOrganization, which V202608252150 removed on purpose
--      (CascadeDeletes is off for shipped Open App entities), and dropped the
--      @@ROWCOUNT = 0 contracts on Update and Delete.
--   2. it did not refresh the non-schema-bound views that select the widened
--      columns, so their cached column metadata still reports 1000.
--   3. it referenced the core schema by its literal name rather than ${mjSchema}.
-- Person SPs are untouched: V202608241515 is still their current definition.
-- V202609051800 itself is left as-is; it may already be applied on databases
-- that migrated next, and Flyway checksums it.
-- =============================================================================

-- 1) EntityField.Length = -1 for both columns, via the core-schema placeholder
--    (idempotent re-run of V202609051800 step 2).
UPDATE ef
SET ef.Length = -1,
    ef.__mj_UpdatedAt = GETUTCDATE()
FROM [${mjSchema}].[EntityField] ef
INNER JOIN [${mjSchema}].[Entity] e ON e.ID = ef.EntityID
WHERE ((e.ID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND ef.Name = 'PhotoURL')
    OR (e.ID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND ef.Name = 'LogoURL'))
  AND ef.Length <> -1;
GO

-- 2) Refresh the views that select PhotoURL / LogoURL so sys.columns reports
--    NVARCHAR(MAX) (-1) for them. Same pattern as V202608132239.
IF OBJECT_ID('[${flyway:defaultSchema}].[vwPeopleGenerated]', 'V') IS NOT NULL
    EXEC sp_executesql N'EXEC sp_refreshview ''${flyway:defaultSchema}.vwPeopleGenerated'';';
IF OBJECT_ID('[${flyway:defaultSchema}].[vwPeople]', 'V') IS NOT NULL
    EXEC sp_executesql N'EXEC sp_refreshview ''${flyway:defaultSchema}.vwPeople'';';
IF OBJECT_ID('[${flyway:defaultSchema}].[vwOrganizationsGenerated]', 'V') IS NOT NULL
    EXEC sp_executesql N'EXEC sp_refreshview ''${flyway:defaultSchema}.vwOrganizationsGenerated'';';
IF OBJECT_ID('[${flyway:defaultSchema}].[vwOrganizations]', 'V') IS NOT NULL
    EXEC sp_executesql N'EXEC sp_refreshview ''${flyway:defaultSchema}.vwOrganizations'';';
GO

-- 3) Organization procedures: verbatim V202608252150 (CodeGen output) with the
--    single change @LogoURL nvarchar(1000) -> nvarchar(MAX) on Create/Update.
--    Delete is byte-identical to V202608252150 (no cascade).
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateOrganization]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateOrganization];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateOrganization]
    @ID uniqueidentifier = NULL,
    @Name nvarchar(255),
    @LegalName_Clear bit = 0,
    @LegalName nvarchar(255) = NULL,
    @OrganizationTypeID_Clear bit = 0,
    @OrganizationTypeID uniqueidentifier = NULL,
    @ParentID_Clear bit = 0,
    @ParentID uniqueidentifier = NULL,
    @Website_Clear bit = 0,
    @Website nvarchar(1000) = NULL,
    @LogoURL_Clear bit = 0,
    @LogoURL nvarchar(MAX) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Email_Clear bit = 0,
    @Email nvarchar(255) = NULL,
    @Phone_Clear bit = 0,
    @Phone nvarchar(50) = NULL,
    @FoundedDate_Clear bit = 0,
    @FoundedDate date = NULL,
    @TaxID_Clear bit = 0,
    @TaxID nvarchar(50) = NULL,
    @Status nvarchar(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[Organization]
            (
                [ID],
                [Name],
                [LegalName],
                [OrganizationTypeID],
                [ParentID],
                [Website],
                [LogoURL],
                [Description],
                [Email],
                [Phone],
                [FoundedDate],
                [TaxID],
                [Status]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Name,
                CASE WHEN @LegalName_Clear = 1 THEN NULL ELSE ISNULL(@LegalName, NULL) END,
                CASE WHEN @OrganizationTypeID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationTypeID, NULL) END,
                CASE WHEN @ParentID_Clear = 1 THEN NULL ELSE ISNULL(@ParentID, NULL) END,
                CASE WHEN @Website_Clear = 1 THEN NULL ELSE ISNULL(@Website, NULL) END,
                CASE WHEN @LogoURL_Clear = 1 THEN NULL ELSE ISNULL(@LogoURL, NULL) END,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                CASE WHEN @Email_Clear = 1 THEN NULL ELSE ISNULL(@Email, NULL) END,
                CASE WHEN @Phone_Clear = 1 THEN NULL ELSE ISNULL(@Phone, NULL) END,
                CASE WHEN @FoundedDate_Clear = 1 THEN NULL ELSE ISNULL(@FoundedDate, NULL) END,
                CASE WHEN @TaxID_Clear = 1 THEN NULL ELSE ISNULL(@TaxID, NULL) END,
                ISNULL(@Status, 'Active')
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[Organization]
            (
                [Name],
                [LegalName],
                [OrganizationTypeID],
                [ParentID],
                [Website],
                [LogoURL],
                [Description],
                [Email],
                [Phone],
                [FoundedDate],
                [TaxID],
                [Status]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                CASE WHEN @LegalName_Clear = 1 THEN NULL ELSE ISNULL(@LegalName, NULL) END,
                CASE WHEN @OrganizationTypeID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationTypeID, NULL) END,
                CASE WHEN @ParentID_Clear = 1 THEN NULL ELSE ISNULL(@ParentID, NULL) END,
                CASE WHEN @Website_Clear = 1 THEN NULL ELSE ISNULL(@Website, NULL) END,
                CASE WHEN @LogoURL_Clear = 1 THEN NULL ELSE ISNULL(@LogoURL, NULL) END,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                CASE WHEN @Email_Clear = 1 THEN NULL ELSE ISNULL(@Email, NULL) END,
                CASE WHEN @Phone_Clear = 1 THEN NULL ELSE ISNULL(@Phone, NULL) END,
                CASE WHEN @FoundedDate_Clear = 1 THEN NULL ELSE ISNULL(@FoundedDate, NULL) END,
                CASE WHEN @TaxID_Clear = 1 THEN NULL ELSE ISNULL(@TaxID, NULL) END,
                ISNULL(@Status, 'Active')
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwOrganizations] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateOrganization] TO [cdp_Developer], [cdp_Integration];
GO

IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateOrganization]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateOrganization];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateOrganization]
    @ID uniqueidentifier,
    @Name nvarchar(255) = NULL,
    @LegalName_Clear bit = 0,
    @LegalName nvarchar(255) = NULL,
    @OrganizationTypeID_Clear bit = 0,
    @OrganizationTypeID uniqueidentifier = NULL,
    @ParentID_Clear bit = 0,
    @ParentID uniqueidentifier = NULL,
    @Website_Clear bit = 0,
    @Website nvarchar(1000) = NULL,
    @LogoURL_Clear bit = 0,
    @LogoURL nvarchar(MAX) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Email_Clear bit = 0,
    @Email nvarchar(255) = NULL,
    @Phone_Clear bit = 0,
    @Phone nvarchar(50) = NULL,
    @FoundedDate_Clear bit = 0,
    @FoundedDate date = NULL,
    @TaxID_Clear bit = 0,
    @TaxID nvarchar(50) = NULL,
    @Status nvarchar(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Organization]
    SET
        [Name] = ISNULL(@Name, [Name]),
        [LegalName] = CASE WHEN @LegalName_Clear = 1 THEN NULL ELSE ISNULL(@LegalName, [LegalName]) END,
        [OrganizationTypeID] = CASE WHEN @OrganizationTypeID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationTypeID, [OrganizationTypeID]) END,
        [ParentID] = CASE WHEN @ParentID_Clear = 1 THEN NULL ELSE ISNULL(@ParentID, [ParentID]) END,
        [Website] = CASE WHEN @Website_Clear = 1 THEN NULL ELSE ISNULL(@Website, [Website]) END,
        [LogoURL] = CASE WHEN @LogoURL_Clear = 1 THEN NULL ELSE ISNULL(@LogoURL, [LogoURL]) END,
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [Email] = CASE WHEN @Email_Clear = 1 THEN NULL ELSE ISNULL(@Email, [Email]) END,
        [Phone] = CASE WHEN @Phone_Clear = 1 THEN NULL ELSE ISNULL(@Phone, [Phone]) END,
        [FoundedDate] = CASE WHEN @FoundedDate_Clear = 1 THEN NULL ELSE ISNULL(@FoundedDate, [FoundedDate]) END,
        [TaxID] = CASE WHEN @TaxID_Clear = 1 THEN NULL ELSE ISNULL(@TaxID, [TaxID]) END,
        [Status] = ISNULL(@Status, [Status])
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwOrganizations] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwOrganizations]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateOrganization] TO [cdp_Developer], [cdp_Integration]
GO

IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteOrganization]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteOrganization];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteOrganization]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    -- CascadeDeletes is off for shipped Open App entities. Deleting an
    -- Organization that still has ContactMethods / Relationships / child orgs
    -- fails the FK — callers reassign or delete children first.
    DELETE FROM [${flyway:defaultSchema}].[Organization]
    WHERE [ID] = @ID

    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID]
    ELSE
        SELECT @ID AS [ID]
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteOrganization] TO [cdp_Integration];
GO

