-- Companion calendar surface is data on ActivitySyncProviderType, not a literal on
-- the deprecated ActivitySyncConnection.Provider column (dropped as a CHECK in
-- V202608291500). A connection created the documented way — type FK set, Provider
-- NULL — must still get a calendar pass. The engine resolves CalendarDriverClass
-- through ClassFactory; it does not `new` the Graph calendar provider.
--
-- Hosts run mj migrate, never CodeGen. This V therefore carries the column AND the
-- CodeGen objects a write path needs: EntityField (sequence matches view order),
-- and spCreate / spUpdate with the new parameter. The view is SELECT a.*, so the
-- column appears in the result set after the __mj timestamps and before the two
-- related-name virtuals — EntityField Sequence 18, with DefaultEncryptionKey /
-- DefaultStorageProvider bumped 18→19 and 19→20 so INSERT INTO @ResultTable EXEC
-- stays aligned.

ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncProviderType]
ADD [CalendarDriverClass] NVARCHAR(200) NULL;
GO

UPDATE [${flyway:defaultSchema}].[ActivitySyncProviderType]
SET [CalendarDriverClass] = N'Microsoft365.Calendar'
WHERE [Code] = N'Microsoft365'
  AND [CalendarDriverClass] IS NULL;
GO

DECLARE @EntityID UNIQUEIDENTIFIER = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75'; -- MJ_BizApps_Common: Activity Sync Provider Types

-- View order after ALTER: a.* (… __mj_UpdatedAt, CalendarDriverClass), DefaultEncryptionKey, DefaultStorageProvider.
UPDATE [${mjSchema}].[EntityField]
SET [Sequence] = 20
WHERE [EntityID] = @EntityID
  AND [Name] = 'DefaultStorageProvider'
  AND [Sequence] = 19;

UPDATE [${mjSchema}].[EntityField]
SET [Sequence] = 19
WHERE [EntityID] = @EntityID
  AND [Name] = 'DefaultEncryptionKey'
  AND [Sequence] = 18;

IF NOT EXISTS (
    SELECT 1 FROM [${mjSchema}].[EntityField]
    WHERE ID = '1BC8E870-B508-49C3-A66E-2AEE1AD7A159'
       OR (EntityID = @EntityID AND Name = 'CalendarDriverClass')
)
INSERT INTO [${mjSchema}].[EntityField]
    (ID, EntityID, Sequence, Name, DisplayName, Description, Type, Length, Precision, Scale, AllowsNull, DefaultValue, AutoIncrement, AllowUpdateAPI, IsVirtual, IsComputed, IsNameField, IncludeInUserSearchAPI, IncludeRelatedEntityNameFieldInBaseView, DefaultInView, IsPrimaryKey, IsUnique, RelatedEntityDisplayType, __mj_CreatedAt, __mj_UpdatedAt)
VALUES
    (
        '1BC8E870-B508-49C3-A66E-2AEE1AD7A159',
        @EntityID,
        18,
        'CalendarDriverClass',
        'Calendar Driver Class',
        'ClassFactory key for the companion calendar surface on this provider type. Null means this type has no second surface. Resolved through ClassFactory — never constructed with new.',
        'nvarchar',
        400,
        0,
        0,
        1,
        NULL,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        'Search',
        GETUTCDATE(),
        GETUTCDATE()
    );
GO

IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateActivitySyncProviderType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncProviderType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncProviderType]
    @ID uniqueidentifier = NULL,
    @Code nvarchar(60),
    @Name nvarchar(100),
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @DriverClass_Clear bit = 0,
    @DriverClass nvarchar(200) = NULL,
    @CalendarDriverClass_Clear bit = 0,
    @CalendarDriverClass nvarchar(200) = NULL,
    @IconClass_Clear bit = 0,
    @IconClass nvarchar(100) = NULL,
    @SupportedKinds_Clear bit = 0,
    @SupportedKinds nvarchar(MAX) = NULL,
    @DefaultQualificationPolicy nvarchar(20) = NULL,
    @DefaultSkippedContentPolicy nvarchar(20) = NULL,
    @DefaultEncryptionKeyID_Clear bit = 0,
    @DefaultEncryptionKeyID uniqueidentifier = NULL,
    @DefaultStorageProviderID_Clear bit = 0,
    @DefaultStorageProviderID uniqueidentifier = NULL,
    @DefaultMaxAttachmentBytes_Clear bit = 0,
    @DefaultMaxAttachmentBytes bigint = NULL,
    @Sequence int = NULL,
    @IsSystem bit = NULL,
    @IsActive bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncProviderType]
            (
                [ID],
                [Code],
                [Name],
                [Description],
                [DriverClass],
                [CalendarDriverClass],
                [IconClass],
                [SupportedKinds],
                [DefaultQualificationPolicy],
                [DefaultSkippedContentPolicy],
                [DefaultEncryptionKeyID],
                [DefaultStorageProviderID],
                [DefaultMaxAttachmentBytes],
                [Sequence],
                [IsSystem],
                [IsActive]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Code,
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                CASE WHEN @DriverClass_Clear = 1 THEN NULL ELSE ISNULL(@DriverClass, NULL) END,
                CASE WHEN @CalendarDriverClass_Clear = 1 THEN NULL ELSE ISNULL(@CalendarDriverClass, NULL) END,
                CASE WHEN @IconClass_Clear = 1 THEN NULL ELSE ISNULL(@IconClass, NULL) END,
                CASE WHEN @SupportedKinds_Clear = 1 THEN NULL ELSE ISNULL(@SupportedKinds, NULL) END,
                ISNULL(@DefaultQualificationPolicy, 'Exclude'),
                ISNULL(@DefaultSkippedContentPolicy, 'None'),
                CASE WHEN @DefaultEncryptionKeyID_Clear = 1 THEN NULL ELSE ISNULL(@DefaultEncryptionKeyID, NULL) END,
                CASE WHEN @DefaultStorageProviderID_Clear = 1 THEN NULL ELSE ISNULL(@DefaultStorageProviderID, NULL) END,
                CASE WHEN @DefaultMaxAttachmentBytes_Clear = 1 THEN NULL ELSE ISNULL(@DefaultMaxAttachmentBytes, NULL) END,
                ISNULL(@Sequence, 0),
                ISNULL(@IsSystem, 0),
                ISNULL(@IsActive, 1)
            )
    END
    ELSE
    BEGIN
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncProviderType]
            (
                [Code],
                [Name],
                [Description],
                [DriverClass],
                [CalendarDriverClass],
                [IconClass],
                [SupportedKinds],
                [DefaultQualificationPolicy],
                [DefaultSkippedContentPolicy],
                [DefaultEncryptionKeyID],
                [DefaultStorageProviderID],
                [DefaultMaxAttachmentBytes],
                [Sequence],
                [IsSystem],
                [IsActive]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Code,
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                CASE WHEN @DriverClass_Clear = 1 THEN NULL ELSE ISNULL(@DriverClass, NULL) END,
                CASE WHEN @CalendarDriverClass_Clear = 1 THEN NULL ELSE ISNULL(@CalendarDriverClass, NULL) END,
                CASE WHEN @IconClass_Clear = 1 THEN NULL ELSE ISNULL(@IconClass, NULL) END,
                CASE WHEN @SupportedKinds_Clear = 1 THEN NULL ELSE ISNULL(@SupportedKinds, NULL) END,
                ISNULL(@DefaultQualificationPolicy, 'Exclude'),
                ISNULL(@DefaultSkippedContentPolicy, 'None'),
                CASE WHEN @DefaultEncryptionKeyID_Clear = 1 THEN NULL ELSE ISNULL(@DefaultEncryptionKeyID, NULL) END,
                CASE WHEN @DefaultStorageProviderID_Clear = 1 THEN NULL ELSE ISNULL(@DefaultStorageProviderID, NULL) END,
                CASE WHEN @DefaultMaxAttachmentBytes_Clear = 1 THEN NULL ELSE ISNULL(@DefaultMaxAttachmentBytes, NULL) END,
                ISNULL(@Sequence, 0),
                ISNULL(@IsSystem, 0),
                ISNULL(@IsActive, 1)
            )
    END
    SELECT * FROM [${flyway:defaultSchema}].[vwActivitySyncProviderTypes] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncProviderType] TO [cdp_Developer], [cdp_Integration];
GO

IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivitySyncProviderType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncProviderType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncProviderType]
    @ID uniqueidentifier,
    @Code nvarchar(60) = NULL,
    @Name nvarchar(100) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @DriverClass_Clear bit = 0,
    @DriverClass nvarchar(200) = NULL,
    @CalendarDriverClass_Clear bit = 0,
    @CalendarDriverClass nvarchar(200) = NULL,
    @IconClass_Clear bit = 0,
    @IconClass nvarchar(100) = NULL,
    @SupportedKinds_Clear bit = 0,
    @SupportedKinds nvarchar(MAX) = NULL,
    @DefaultQualificationPolicy nvarchar(20) = NULL,
    @DefaultSkippedContentPolicy nvarchar(20) = NULL,
    @DefaultEncryptionKeyID_Clear bit = 0,
    @DefaultEncryptionKeyID uniqueidentifier = NULL,
    @DefaultStorageProviderID_Clear bit = 0,
    @DefaultStorageProviderID uniqueidentifier = NULL,
    @DefaultMaxAttachmentBytes_Clear bit = 0,
    @DefaultMaxAttachmentBytes bigint = NULL,
    @Sequence int = NULL,
    @IsSystem bit = NULL,
    @IsActive bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncProviderType]
    SET
        [Code] = ISNULL(@Code, [Code]),
        [Name] = ISNULL(@Name, [Name]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [DriverClass] = CASE WHEN @DriverClass_Clear = 1 THEN NULL ELSE ISNULL(@DriverClass, [DriverClass]) END,
        [CalendarDriverClass] = CASE WHEN @CalendarDriverClass_Clear = 1 THEN NULL ELSE ISNULL(@CalendarDriverClass, [CalendarDriverClass]) END,
        [IconClass] = CASE WHEN @IconClass_Clear = 1 THEN NULL ELSE ISNULL(@IconClass, [IconClass]) END,
        [SupportedKinds] = CASE WHEN @SupportedKinds_Clear = 1 THEN NULL ELSE ISNULL(@SupportedKinds, [SupportedKinds]) END,
        [DefaultQualificationPolicy] = ISNULL(@DefaultQualificationPolicy, [DefaultQualificationPolicy]),
        [DefaultSkippedContentPolicy] = ISNULL(@DefaultSkippedContentPolicy, [DefaultSkippedContentPolicy]),
        [DefaultEncryptionKeyID] = CASE WHEN @DefaultEncryptionKeyID_Clear = 1 THEN NULL ELSE ISNULL(@DefaultEncryptionKeyID, [DefaultEncryptionKeyID]) END,
        [DefaultStorageProviderID] = CASE WHEN @DefaultStorageProviderID_Clear = 1 THEN NULL ELSE ISNULL(@DefaultStorageProviderID, [DefaultStorageProviderID]) END,
        [DefaultMaxAttachmentBytes] = CASE WHEN @DefaultMaxAttachmentBytes_Clear = 1 THEN NULL ELSE ISNULL(@DefaultMaxAttachmentBytes, [DefaultMaxAttachmentBytes]) END,
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [IsSystem] = ISNULL(@IsSystem, [IsSystem]),
        [IsActive] = ISNULL(@IsActive, [IsActive])
    WHERE
        [ID] = @ID

    IF @@ROWCOUNT = 0
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivitySyncProviderTypes] WHERE 1=0
    ELSE
        SELECT * FROM [${flyway:defaultSchema}].[vwActivitySyncProviderTypes] WHERE [ID] = @ID
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncProviderType] TO [cdp_Developer], [cdp_Integration];
GO
