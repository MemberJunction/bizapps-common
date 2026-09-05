-- =============================================================================
-- Migration: V202609051800__v5.39.x__Widen_PhotoURL_LogoURL.sql
-- Description: Widen Person.PhotoURL and Organization.LogoURL to NVARCHAR(MAX)
--              so inline illustrated avatars/logos fit (loom #12 WP1). Additive.
-- =============================================================================

-- 1) Columns
IF COL_LENGTH('${flyway:defaultSchema}.Person', 'PhotoURL') IS NOT NULL
   AND COLUMNPROPERTY(OBJECT_ID('${flyway:defaultSchema}.Person'), 'PhotoURL', 'Precision') <> -1
BEGIN
    ALTER TABLE [${flyway:defaultSchema}].[Person] ALTER COLUMN [PhotoURL] NVARCHAR(MAX) NULL;
END
GO
IF COL_LENGTH('${flyway:defaultSchema}.Organization', 'LogoURL') IS NOT NULL
   AND COLUMNPROPERTY(OBJECT_ID('${flyway:defaultSchema}.Organization'), 'LogoURL', 'Precision') <> -1
BEGIN
    ALTER TABLE [${flyway:defaultSchema}].[Organization] ALTER COLUMN [LogoURL] NVARCHAR(MAX) NULL;
END
GO

-- 2) EntityField.Length = -1 (NVARCHAR(MAX))
UPDATE ef
SET ef.Length = -1,
    ef.__mj_UpdatedAt = GETUTCDATE()
FROM [__mj].[EntityField] ef
INNER JOIN [__mj].[Entity] e ON e.ID = ef.EntityID
WHERE (e.ID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND ef.Name = 'PhotoURL')
   OR (e.ID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND ef.Name = 'LogoURL');
GO

-- 3) Extended properties
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE major_id = OBJECT_ID('${flyway:defaultSchema}.Person') AND name = 'MS_Description' AND minor_id = COLUMNPROPERTY(OBJECT_ID('${flyway:defaultSchema}.Person'), 'PhotoURL', 'ColumnId'))
    EXEC sp_updateextendedproperty @name = N'MS_Description', @value = N'Profile photo or avatar. May be an HTTP(S) URL or an inline data URI (NVARCHAR(MAX)).',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'PhotoURL';
ELSE
    EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Profile photo or avatar. May be an HTTP(S) URL or an inline data URI (NVARCHAR(MAX)).',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'PhotoURL';
GO
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE major_id = OBJECT_ID('${flyway:defaultSchema}.Organization') AND name = 'MS_Description' AND minor_id = COLUMNPROPERTY(OBJECT_ID('${flyway:defaultSchema}.Organization'), 'LogoURL', 'ColumnId'))
    EXEC sp_updateextendedproperty @name = N'MS_Description', @value = N'Organization logo. May be an HTTP(S) URL or an inline data URI (NVARCHAR(MAX)).',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}', @level1type = N'TABLE', @level1name = N'Organization', @level2type = N'COLUMN', @level2name = N'LogoURL';
ELSE
    EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Organization logo. May be an HTTP(S) URL or an inline data URI (NVARCHAR(MAX)).',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}', @level1type = N'TABLE', @level1name = N'Organization', @level2type = N'COLUMN', @level2name = N'LogoURL';
GO

-- 4) Recreate create/update SPs so @PhotoURL/@LogoURL parameters are NVARCHAR(MAX).
--    Bodies match V202608241515 (latest Person/Organization CRUD before this change).

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

    SELECT * FROM [${flyway:defaultSchema}].[vwOrganizations]
    WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
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
    UPDATE [${flyway:defaultSchema}].[Organization]
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

    SELECT * FROM [${flyway:defaultSchema}].[vwOrganizations]
    WHERE [ID] = @ID
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateOrganization] TO [cdp_Developer], [cdp_Integration];
GO

IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteOrganization]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteOrganization];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteOrganization]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM [${flyway:defaultSchema}].[ContactMethod]
    WHERE [OrganizationID] = @ID;

    DELETE FROM [${flyway:defaultSchema}].[AddressLink]
    WHERE [RecordID] = CAST(@ID AS NVARCHAR(MAX))
      AND [EntityID] = (SELECT [ID] FROM [__mj].[Entity] WHERE [Name] = 'MJ_BizApps_Common: Organizations');

    DELETE FROM [${flyway:defaultSchema}].[Relationship]
    WHERE [FromOrganizationID] = @ID OR [ToOrganizationID] = @ID;

    DELETE FROM [${flyway:defaultSchema}].[Organization]
    WHERE [ID] = @ID;

    SELECT @ID AS [ID];
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteOrganization] TO [cdp_Integration];
GO

-----------------------------------------------------------------
-- Person Procedures
-----------------------------------------------------------------

IF OBJECT_ID('[${flyway:defaultSchema}].[spCreatePerson]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreatePerson];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreatePerson]
    @ID uniqueidentifier = NULL,
    @FirstName nvarchar(100),
    @LastName nvarchar(100),
    @MiddleName_Clear bit = 0,
    @MiddleName nvarchar(100) = NULL,
    @Prefix_Clear bit = 0,
    @Prefix nvarchar(20) = NULL,
    @Suffix_Clear bit = 0,
    @Suffix nvarchar(20) = NULL,
    @PreferredName_Clear bit = 0,
    @PreferredName nvarchar(100) = NULL,
    @Title_Clear bit = 0,
    @Title nvarchar(200) = NULL,
    @Email_Clear bit = 0,
    @Email nvarchar(255) = NULL,
    @Phone_Clear bit = 0,
    @Phone nvarchar(50) = NULL,
    @DateOfBirth_Clear bit = 0,
    @DateOfBirth date = NULL,
    @Gender_Clear bit = 0,
    @Gender nvarchar(50) = NULL,
    @PhotoURL_Clear bit = 0,
    @PhotoURL nvarchar(MAX) = NULL,
    @Bio_Clear bit = 0,
    @Bio nvarchar(MAX) = NULL,
    @LinkedUserID_Clear bit = 0,
    @LinkedUserID uniqueidentifier = NULL,
    @Status nvarchar(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        INSERT INTO [${flyway:defaultSchema}].[Person]
            (
                [ID],
                [FirstName],
                [LastName],
                [MiddleName],
                [Prefix],
                [Suffix],
                [PreferredName],
                [Title],
                [Email],
                [Phone],
                [DateOfBirth],
                [Gender],
                [PhotoURL],
                [Bio],
                [LinkedUserID],
                [Status]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @FirstName,
                @LastName,
                CASE WHEN @MiddleName_Clear = 1 THEN NULL ELSE ISNULL(@MiddleName, NULL) END,
                CASE WHEN @Prefix_Clear = 1 THEN NULL ELSE ISNULL(@Prefix, NULL) END,
                CASE WHEN @Suffix_Clear = 1 THEN NULL ELSE ISNULL(@Suffix, NULL) END,
                CASE WHEN @PreferredName_Clear = 1 THEN NULL ELSE ISNULL(@PreferredName, NULL) END,
                CASE WHEN @Title_Clear = 1 THEN NULL ELSE ISNULL(@Title, NULL) END,
                CASE WHEN @Email_Clear = 1 THEN NULL ELSE ISNULL(@Email, NULL) END,
                CASE WHEN @Phone_Clear = 1 THEN NULL ELSE ISNULL(@Phone, NULL) END,
                CASE WHEN @DateOfBirth_Clear = 1 THEN NULL ELSE ISNULL(@DateOfBirth, NULL) END,
                CASE WHEN @Gender_Clear = 1 THEN NULL ELSE ISNULL(@Gender, NULL) END,
                CASE WHEN @PhotoURL_Clear = 1 THEN NULL ELSE ISNULL(@PhotoURL, NULL) END,
                CASE WHEN @Bio_Clear = 1 THEN NULL ELSE ISNULL(@Bio, NULL) END,
                CASE WHEN @LinkedUserID_Clear = 1 THEN NULL ELSE ISNULL(@LinkedUserID, NULL) END,
                ISNULL(@Status, 'Active')
            )
    END
    ELSE
    BEGIN
        INSERT INTO [${flyway:defaultSchema}].[Person]
            (
                [FirstName],
                [LastName],
                [MiddleName],
                [Prefix],
                [Suffix],
                [PreferredName],
                [Title],
                [Email],
                [Phone],
                [DateOfBirth],
                [Gender],
                [PhotoURL],
                [Bio],
                [LinkedUserID],
                [Status]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @FirstName,
                @LastName,
                CASE WHEN @MiddleName_Clear = 1 THEN NULL ELSE ISNULL(@MiddleName, NULL) END,
                CASE WHEN @Prefix_Clear = 1 THEN NULL ELSE ISNULL(@Prefix, NULL) END,
                CASE WHEN @Suffix_Clear = 1 THEN NULL ELSE ISNULL(@Suffix, NULL) END,
                CASE WHEN @PreferredName_Clear = 1 THEN NULL ELSE ISNULL(@PreferredName, NULL) END,
                CASE WHEN @Title_Clear = 1 THEN NULL ELSE ISNULL(@Title, NULL) END,
                CASE WHEN @Email_Clear = 1 THEN NULL ELSE ISNULL(@Email, NULL) END,
                CASE WHEN @Phone_Clear = 1 THEN NULL ELSE ISNULL(@Phone, NULL) END,
                CASE WHEN @DateOfBirth_Clear = 1 THEN NULL ELSE ISNULL(@DateOfBirth, NULL) END,
                CASE WHEN @Gender_Clear = 1 THEN NULL ELSE ISNULL(@Gender, NULL) END,
                CASE WHEN @PhotoURL_Clear = 1 THEN NULL ELSE ISNULL(@PhotoURL, NULL) END,
                CASE WHEN @Bio_Clear = 1 THEN NULL ELSE ISNULL(@Bio, NULL) END,
                CASE WHEN @LinkedUserID_Clear = 1 THEN NULL ELSE ISNULL(@LinkedUserID, NULL) END,
                ISNULL(@Status, 'Active')
            )
    END

    SELECT * FROM [${flyway:defaultSchema}].[vwPeople]
    WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreatePerson] TO [cdp_Developer], [cdp_Integration];
GO

IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdatePerson]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdatePerson];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdatePerson]
    @ID uniqueidentifier,
    @FirstName nvarchar(100) = NULL,
    @LastName nvarchar(100) = NULL,
    @MiddleName_Clear bit = 0,
    @MiddleName nvarchar(100) = NULL,
    @Prefix_Clear bit = 0,
    @Prefix nvarchar(20) = NULL,
    @Suffix_Clear bit = 0,
    @Suffix nvarchar(20) = NULL,
    @PreferredName_Clear bit = 0,
    @PreferredName nvarchar(100) = NULL,
    @Title_Clear bit = 0,
    @Title nvarchar(200) = NULL,
    @Email_Clear bit = 0,
    @Email nvarchar(255) = NULL,
    @Phone_Clear bit = 0,
    @Phone nvarchar(50) = NULL,
    @DateOfBirth_Clear bit = 0,
    @DateOfBirth date = NULL,
    @Gender_Clear bit = 0,
    @Gender nvarchar(50) = NULL,
    @PhotoURL_Clear bit = 0,
    @PhotoURL nvarchar(MAX) = NULL,
    @Bio_Clear bit = 0,
    @Bio nvarchar(MAX) = NULL,
    @LinkedUserID_Clear bit = 0,
    @LinkedUserID uniqueidentifier = NULL,
    @Status nvarchar(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [${flyway:defaultSchema}].[Person]
    SET
        [FirstName] = ISNULL(@FirstName, [FirstName]),
        [LastName] = ISNULL(@LastName, [LastName]),
        [MiddleName] = CASE WHEN @MiddleName_Clear = 1 THEN NULL ELSE ISNULL(@MiddleName, [MiddleName]) END,
        [Prefix] = CASE WHEN @Prefix_Clear = 1 THEN NULL ELSE ISNULL(@Prefix, [Prefix]) END,
        [Suffix] = CASE WHEN @Suffix_Clear = 1 THEN NULL ELSE ISNULL(@Suffix, [Suffix]) END,
        [PreferredName] = CASE WHEN @PreferredName_Clear = 1 THEN NULL ELSE ISNULL(@PreferredName, [PreferredName]) END,
        [Title] = CASE WHEN @Title_Clear = 1 THEN NULL ELSE ISNULL(@Title, [Title]) END,
        [Email] = CASE WHEN @Email_Clear = 1 THEN NULL ELSE ISNULL(@Email, [Email]) END,
        [Phone] = CASE WHEN @Phone_Clear = 1 THEN NULL ELSE ISNULL(@Phone, [Phone]) END,
        [DateOfBirth] = CASE WHEN @DateOfBirth_Clear = 1 THEN NULL ELSE ISNULL(@DateOfBirth, [DateOfBirth]) END,
        [Gender] = CASE WHEN @Gender_Clear = 1 THEN NULL ELSE ISNULL(@Gender, [Gender]) END,
        [PhotoURL] = CASE WHEN @PhotoURL_Clear = 1 THEN NULL ELSE ISNULL(@PhotoURL, [PhotoURL]) END,
        [Bio] = CASE WHEN @Bio_Clear = 1 THEN NULL ELSE ISNULL(@Bio, [Bio]) END,
        [LinkedUserID] = CASE WHEN @LinkedUserID_Clear = 1 THEN NULL ELSE ISNULL(@LinkedUserID, [LinkedUserID]) END,
        [Status] = ISNULL(@Status, [Status])
    WHERE
        [ID] = @ID

    SELECT * FROM [${flyway:defaultSchema}].[vwPeople]
    WHERE [ID] = @ID
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdatePerson] TO [cdp_Developer], [cdp_Integration];
GO

IF OBJECT_ID('[${flyway:defaultSchema}].[spDeletePerson]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeletePerson];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeletePerson]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM [${flyway:defaultSchema}].[ContactMethod]
    WHERE [PersonID] = @ID;

    DELETE FROM [${flyway:defaultSchema}].[AddressLink]
    WHERE [RecordID] = CAST(@ID AS NVARCHAR(MAX))
      AND [EntityID] = (SELECT [ID] FROM [__mj].[Entity] WHERE [Name] = 'MJ_BizApps_Common: People');

    DELETE FROM [${flyway:defaultSchema}].[Relationship]
    WHERE [FromPersonID] = @ID OR [ToPersonID] = @ID;

    DELETE FROM [${flyway:defaultSchema}].[Person]
    WHERE [ID] = @ID;

    SELECT @ID AS [ID];
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeletePerson] TO [cdp_Integration];
GO
