-- =============================================================================
-- Restore spCreatePerson / spUpdatePerson @PhotoURL to NVARCHAR(MAX)
--
-- V202609051800__v5.39.x__Widen_PhotoURL_LogoURL widened [Person].[PhotoURL] to NVARCHAR(MAX)
-- and regenerated both procs with @PhotoURL nvarchar(MAX). V202609211200__v5.45.x__Job_Function_Seniority
-- (PR #171) re-emitted both procs from a CodeGen run against a database still at the old width,
-- putting @PhotoURL back to nvarchar(1000). The column stayed MAX, but SQL Server SILENTLY truncates
-- procedure parameters, so every Person create/update since v5.45 cuts PhotoURL at 1000 characters
-- (e.g. inline SVG data-URI avatars, 4-10k chars, all stored as exactly 1000 and fail to render).
--
-- This re-issues the v5.45 definitions verbatim except @PhotoURL nvarchar(1000) -> nvarchar(MAX).
-- Organization procs are unaffected (@LogoURL is still MAX). Data already truncated must be
-- re-saved by its source (e.g. re-push the People records) — the original value is not recoverable here.
-- =============================================================================

----- CREATE PROCEDURE FOR Person
------------------------------------------------------------
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
    @Status nvarchar(50) = NULL,
    @SeniorityLevelID_Clear bit = 0,
    @SeniorityLevelID uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
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
                [Status],
                [SeniorityLevelID]
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
                ISNULL(@Status, 'Active'),
                CASE WHEN @SeniorityLevelID_Clear = 1 THEN NULL ELSE ISNULL(@SeniorityLevelID, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
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
                [Status],
                [SeniorityLevelID]
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
                ISNULL(@Status, 'Active'),
                CASE WHEN @SeniorityLevelID_Clear = 1 THEN NULL ELSE ISNULL(@SeniorityLevelID, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwPeople] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreatePerson] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreatePerson] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreatePerson] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: People */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreatePerson] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreatePerson] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreatePerson] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: People
-- Item: spUpdatePerson
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Person
------------------------------------------------------------
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
    @Status nvarchar(50) = NULL,
    @SeniorityLevelID_Clear bit = 0,
    @SeniorityLevelID uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Person]
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
        [Status] = ISNULL(@Status, [Status]),
        [SeniorityLevelID] = CASE WHEN @SeniorityLevelID_Clear = 1 THEN NULL ELSE ISNULL(@SeniorityLevelID, [SeniorityLevelID]) END
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwPeople] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwPeople]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdatePerson] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdatePerson] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdatePerson] TO [cdp_Developer], [cdp_Integration]
GO
