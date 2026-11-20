-- =============================================================================
-- Wave 4.3b: Single-write __mj_UpdatedAt backfill
--   1. Sets [__mj_UpdatedAt] = GETUTCDATE() directly inside spUpdate* procedures
--      so BaseEntity.Save() performs a single write to the base table.
--   2. Wraps trgUpdate* __mj_UpdatedAt triggers in IF NOT UPDATE([__mj_UpdatedAt])
--      so direct SQL UPDATEs that omit __mj_UpdatedAt still get stamped, while
--      spUpdate* (and explicit callers) skip the redundant second write.
-- =============================================================================























































------------------------------------------------------------
----- UPDATE PROCEDURE FOR Activity
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivity]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivity];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivity]
    @ID uniqueidentifier,
    @ActivityTypeID uniqueidentifier = NULL,
    @StartedAt datetimeoffset = NULL,
    @EndedAt_Clear bit = 0,
    @EndedAt datetimeoffset = NULL,
    @Title nvarchar(500) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Direction nvarchar(20) = NULL,
    @Status nvarchar(20) = NULL,
    @Outcome_Clear bit = 0,
    @Outcome nvarchar(40) = NULL,
    @Visibility nvarchar(20) = NULL,
    @Source nvarchar(20) = NULL,
    @SourceSystem_Clear bit = 0,
    @SourceSystem nvarchar(80) = NULL,
    @ExternalID_Clear bit = 0,
    @ExternalID nvarchar(400) = NULL,
    @ExternalThreadID_Clear bit = 0,
    @ExternalThreadID nvarchar(400) = NULL,
    @ParentActivityID_Clear bit = 0,
    @ParentActivityID uniqueidentifier = NULL,
    @LoggedByUserID uniqueidentifier = NULL,
    @Location_Clear bit = 0,
    @Location nvarchar(500) = NULL,
    @AddressID_Clear bit = 0,
    @AddressID uniqueidentifier = NULL,
    @ActivitySyncConnectionID_Clear bit = 0,
    @ActivitySyncConnectionID uniqueidentifier = NULL,
    @Details_Clear bit = 0,
    @Details nvarchar(MAX) = NULL,
    @SentimentScore_Clear bit = 0,
    @SentimentScore decimal(4, 3) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Activity]
    SET
        [ActivityTypeID] = ISNULL(@ActivityTypeID, [ActivityTypeID]),
        [StartedAt] = ISNULL(@StartedAt, [StartedAt]),
        [EndedAt] = CASE WHEN @EndedAt_Clear = 1 THEN NULL ELSE ISNULL(@EndedAt, [EndedAt]) END,
        [Title] = ISNULL(@Title, [Title]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [Direction] = ISNULL(@Direction, [Direction]),
        [Status] = ISNULL(@Status, [Status]),
        [Outcome] = CASE WHEN @Outcome_Clear = 1 THEN NULL ELSE ISNULL(@Outcome, [Outcome]) END,
        [Visibility] = ISNULL(@Visibility, [Visibility]),
        [Source] = ISNULL(@Source, [Source]),
        [SourceSystem] = CASE WHEN @SourceSystem_Clear = 1 THEN NULL ELSE ISNULL(@SourceSystem, [SourceSystem]) END,
        [ExternalID] = CASE WHEN @ExternalID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalID, [ExternalID]) END,
        [ExternalThreadID] = CASE WHEN @ExternalThreadID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalThreadID, [ExternalThreadID]) END,
        [ParentActivityID] = CASE WHEN @ParentActivityID_Clear = 1 THEN NULL ELSE ISNULL(@ParentActivityID, [ParentActivityID]) END,
        [LoggedByUserID] = ISNULL(@LoggedByUserID, [LoggedByUserID]),
        [Location] = CASE WHEN @Location_Clear = 1 THEN NULL ELSE ISNULL(@Location, [Location]) END,
        [AddressID] = CASE WHEN @AddressID_Clear = 1 THEN NULL ELSE ISNULL(@AddressID, [AddressID]) END,
        [ActivitySyncConnectionID] = CASE WHEN @ActivitySyncConnectionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncConnectionID, [ActivitySyncConnectionID]) END,
        [Details] = CASE WHEN @Details_Clear = 1 THEN NULL ELSE ISNULL(@Details, [Details]) END,
        [SentimentScore] = CASE WHEN @SentimentScore_Clear = 1 THEN NULL ELSE ISNULL(@SentimentScore, [SentimentScore]) END,
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivities] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivities]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivity] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivity] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Activity table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivity]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivity];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivity
ON [${flyway:defaultSchema}].[Activity]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[Activity]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[Activity] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ActivityFile
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivityFile]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivityFile];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivityFile]
    @ID uniqueidentifier,
    @ActivityID uniqueidentifier = NULL,
    @FileID uniqueidentifier = NULL,
    @Kind nvarchar(20) = NULL,
    @Sequence int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivityFile]
    SET
        [ActivityID] = ISNULL(@ActivityID, [ActivityID]),
        [FileID] = ISNULL(@FileID, [FileID]),
        [Kind] = ISNULL(@Kind, [Kind]),
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivityFiles] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivityFiles]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivityFile] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivityFile] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ActivityFile table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivityFile]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivityFile];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivityFile
ON [${flyway:defaultSchema}].[ActivityFile]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[ActivityFile]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[ActivityFile] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ActivityLink
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivityLink]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivityLink];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivityLink]
    @ID uniqueidentifier,
    @ActivityID uniqueidentifier = NULL,
    @Role nvarchar(30) = NULL,
    @EntityID_Clear bit = 0,
    @EntityID uniqueidentifier = NULL,
    @RecordID_Clear bit = 0,
    @RecordID nvarchar(450) = NULL,
    @IdentityKind_Clear bit = 0,
    @IdentityKind nvarchar(20) = NULL,
    @IdentityValue_Clear bit = 0,
    @IdentityValue nvarchar(320) = NULL,
    @Sequence int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivityLink]
    SET
        [ActivityID] = ISNULL(@ActivityID, [ActivityID]),
        [Role] = ISNULL(@Role, [Role]),
        [EntityID] = CASE WHEN @EntityID_Clear = 1 THEN NULL ELSE ISNULL(@EntityID, [EntityID]) END,
        [RecordID] = CASE WHEN @RecordID_Clear = 1 THEN NULL ELSE ISNULL(@RecordID, [RecordID]) END,
        [IdentityKind] = CASE WHEN @IdentityKind_Clear = 1 THEN NULL ELSE ISNULL(@IdentityKind, [IdentityKind]) END,
        [IdentityValue] = CASE WHEN @IdentityValue_Clear = 1 THEN NULL ELSE ISNULL(@IdentityValue, [IdentityValue]) END,
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivityLinks] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivityLinks]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivityLink] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivityLink] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ActivityLink table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivityLink]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivityLink];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivityLink
ON [${flyway:defaultSchema}].[ActivityLink]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[ActivityLink]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[ActivityLink] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ActivitySyncConnection
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivitySyncConnection]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncConnection];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncConnection]
    @ID uniqueidentifier,
    @Name nvarchar(200) = NULL,
    @Provider_Clear bit = 0,
    @Provider nvarchar(40) = NULL,
    @Status nvarchar(20) = NULL,
    @Direction nvarchar(20) = NULL,
    @OwnerUserID uniqueidentifier = NULL,
    @CredentialsRef_Clear bit = 0,
    @CredentialsRef nvarchar(200) = NULL,
    @Mailbox_Clear bit = 0,
    @Mailbox nvarchar(320) = NULL,
    @LastSyncAt_Clear bit = 0,
    @LastSyncAt datetimeoffset = NULL,
    @LastError_Clear bit = 0,
    @LastError nvarchar(MAX) = NULL,
    @Settings_Clear bit = 0,
    @Settings nvarchar(MAX) = NULL,
    @ActivitySyncProviderTypeID_Clear bit = 0,
    @ActivitySyncProviderTypeID uniqueidentifier = NULL,
    @StartAt_Clear bit = 0,
    @StartAt datetimeoffset = NULL,
    @EndAt_Clear bit = 0,
    @EndAt datetimeoffset = NULL,
    @SkippedContentPolicy_Clear bit = 0,
    @SkippedContentPolicy nvarchar(20) = NULL,
    @EncryptionKeyID_Clear bit = 0,
    @EncryptionKeyID uniqueidentifier = NULL,
    @StorageProviderID_Clear bit = 0,
    @StorageProviderID uniqueidentifier = NULL,
    @MaxAttachmentBytes_Clear bit = 0,
    @MaxAttachmentBytes bigint = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncConnection]
    SET
        [Name] = ISNULL(@Name, [Name]),
        [Provider] = CASE WHEN @Provider_Clear = 1 THEN NULL ELSE ISNULL(@Provider, [Provider]) END,
        [Status] = ISNULL(@Status, [Status]),
        [Direction] = ISNULL(@Direction, [Direction]),
        [OwnerUserID] = ISNULL(@OwnerUserID, [OwnerUserID]),
        [CredentialsRef] = CASE WHEN @CredentialsRef_Clear = 1 THEN NULL ELSE ISNULL(@CredentialsRef, [CredentialsRef]) END,
        [Mailbox] = CASE WHEN @Mailbox_Clear = 1 THEN NULL ELSE ISNULL(@Mailbox, [Mailbox]) END,
        [LastSyncAt] = CASE WHEN @LastSyncAt_Clear = 1 THEN NULL ELSE ISNULL(@LastSyncAt, [LastSyncAt]) END,
        [LastError] = CASE WHEN @LastError_Clear = 1 THEN NULL ELSE ISNULL(@LastError, [LastError]) END,
        [Settings] = CASE WHEN @Settings_Clear = 1 THEN NULL ELSE ISNULL(@Settings, [Settings]) END,
        [ActivitySyncProviderTypeID] = CASE WHEN @ActivitySyncProviderTypeID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncProviderTypeID, [ActivitySyncProviderTypeID]) END,
        [StartAt] = CASE WHEN @StartAt_Clear = 1 THEN NULL ELSE ISNULL(@StartAt, [StartAt]) END,
        [EndAt] = CASE WHEN @EndAt_Clear = 1 THEN NULL ELSE ISNULL(@EndAt, [EndAt]) END,
        [SkippedContentPolicy] = CASE WHEN @SkippedContentPolicy_Clear = 1 THEN NULL ELSE ISNULL(@SkippedContentPolicy, [SkippedContentPolicy]) END,
        [EncryptionKeyID] = CASE WHEN @EncryptionKeyID_Clear = 1 THEN NULL ELSE ISNULL(@EncryptionKeyID, [EncryptionKeyID]) END,
        [StorageProviderID] = CASE WHEN @StorageProviderID_Clear = 1 THEN NULL ELSE ISNULL(@StorageProviderID, [StorageProviderID]) END,
        [MaxAttachmentBytes] = CASE WHEN @MaxAttachmentBytes_Clear = 1 THEN NULL ELSE ISNULL(@MaxAttachmentBytes, [MaxAttachmentBytes]) END,
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivitySyncConnections] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivitySyncConnections]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncConnection] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncConnection] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ActivitySyncConnection table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivitySyncConnection]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivitySyncConnection];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivitySyncConnection
ON [${flyway:defaultSchema}].[ActivitySyncConnection]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[ActivitySyncConnection]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[ActivitySyncConnection] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ActivitySyncConnectionRuleSet
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivitySyncConnectionRuleSet]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncConnectionRuleSet];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncConnectionRuleSet]
    @ID uniqueidentifier,
    @ActivitySyncConnectionID uniqueidentifier = NULL,
    @ActivitySyncRuleSetID uniqueidentifier = NULL,
    @Sequence int = NULL,
    @IsEnabled bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet]
    SET
        [ActivitySyncConnectionID] = ISNULL(@ActivitySyncConnectionID, [ActivitySyncConnectionID]),
        [ActivitySyncRuleSetID] = ISNULL(@ActivitySyncRuleSetID, [ActivitySyncRuleSetID]),
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [IsEnabled] = ISNULL(@IsEnabled, [IsEnabled]),
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivitySyncConnectionRuleSets] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivitySyncConnectionRuleSets]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncConnectionRuleSet] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncConnectionRuleSet] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ActivitySyncConnectionRuleSet table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivitySyncConnectionRuleSet]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivitySyncConnectionRuleSet];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivitySyncConnectionRuleSet
ON [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ActivitySyncExclusion
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivitySyncExclusion]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncExclusion];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncExclusion]
    @ID uniqueidentifier,
    @ActivitySyncRuleSetID_Clear bit = 0,
    @ActivitySyncRuleSetID uniqueidentifier = NULL,
    @IdentityKind nvarchar(20) = NULL,
    @IdentityValue nvarchar(320) = NULL,
    @PersonID_Clear bit = 0,
    @PersonID uniqueidentifier = NULL,
    @Reason_Clear bit = 0,
    @Reason nvarchar(MAX) = NULL,
    @EffectiveFrom_Clear bit = 0,
    @EffectiveFrom datetimeoffset = NULL,
    @EffectiveTo_Clear bit = 0,
    @EffectiveTo datetimeoffset = NULL,
    @IsEnabled bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncExclusion]
    SET
        [ActivitySyncRuleSetID] = CASE WHEN @ActivitySyncRuleSetID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncRuleSetID, [ActivitySyncRuleSetID]) END,
        [IdentityKind] = ISNULL(@IdentityKind, [IdentityKind]),
        [IdentityValue] = ISNULL(@IdentityValue, [IdentityValue]),
        [PersonID] = CASE WHEN @PersonID_Clear = 1 THEN NULL ELSE ISNULL(@PersonID, [PersonID]) END,
        [Reason] = CASE WHEN @Reason_Clear = 1 THEN NULL ELSE ISNULL(@Reason, [Reason]) END,
        [EffectiveFrom] = CASE WHEN @EffectiveFrom_Clear = 1 THEN NULL ELSE ISNULL(@EffectiveFrom, [EffectiveFrom]) END,
        [EffectiveTo] = CASE WHEN @EffectiveTo_Clear = 1 THEN NULL ELSE ISNULL(@EffectiveTo, [EffectiveTo]) END,
        [IsEnabled] = ISNULL(@IsEnabled, [IsEnabled]),
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivitySyncExclusions] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivitySyncExclusions]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncExclusion] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncExclusion] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ActivitySyncExclusion table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivitySyncExclusion]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivitySyncExclusion];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivitySyncExclusion
ON [${flyway:defaultSchema}].[ActivitySyncExclusion]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[ActivitySyncExclusion]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[ActivitySyncExclusion] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ActivitySyncExtension
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivitySyncExtension]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncExtension];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncExtension]
    @ID uniqueidentifier,
    @Name nvarchar(200) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @DriverClass nvarchar(200) = NULL,
    @ActivitySyncConnectionID_Clear bit = 0,
    @ActivitySyncConnectionID uniqueidentifier = NULL,
    @ActivitySyncProviderTypeID_Clear bit = 0,
    @ActivitySyncProviderTypeID uniqueidentifier = NULL,
    @Sequence int = NULL,
    @FailurePolicy nvarchar(20) = NULL,
    @TimeoutMS int = NULL,
    @IsEnabled bit = NULL,
    @LastRunAt_Clear bit = 0,
    @LastRunAt datetimeoffset = NULL,
    @LastError_Clear bit = 0,
    @LastError nvarchar(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncExtension]
    SET
        [Name] = ISNULL(@Name, [Name]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [DriverClass] = ISNULL(@DriverClass, [DriverClass]),
        [ActivitySyncConnectionID] = CASE WHEN @ActivitySyncConnectionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncConnectionID, [ActivitySyncConnectionID]) END,
        [ActivitySyncProviderTypeID] = CASE WHEN @ActivitySyncProviderTypeID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncProviderTypeID, [ActivitySyncProviderTypeID]) END,
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [FailurePolicy] = ISNULL(@FailurePolicy, [FailurePolicy]),
        [TimeoutMS] = ISNULL(@TimeoutMS, [TimeoutMS]),
        [IsEnabled] = ISNULL(@IsEnabled, [IsEnabled]),
        [LastRunAt] = CASE WHEN @LastRunAt_Clear = 1 THEN NULL ELSE ISNULL(@LastRunAt, [LastRunAt]) END,
        [LastError] = CASE WHEN @LastError_Clear = 1 THEN NULL ELSE ISNULL(@LastError, [LastError]) END,
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivitySyncExtensions] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivitySyncExtensions]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncExtension] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncExtension] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ActivitySyncExtension table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivitySyncExtension]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivitySyncExtension];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivitySyncExtension
ON [${flyway:defaultSchema}].[ActivitySyncExtension]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[ActivitySyncExtension]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[ActivitySyncExtension] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ActivitySyncProviderType
------------------------------------------------------------
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
    @IsActive bit = NULL,
    @CalendarDriverClass_Clear bit = 0,
    @CalendarDriverClass nvarchar(200) = NULL
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
        [IconClass] = CASE WHEN @IconClass_Clear = 1 THEN NULL ELSE ISNULL(@IconClass, [IconClass]) END,
        [SupportedKinds] = CASE WHEN @SupportedKinds_Clear = 1 THEN NULL ELSE ISNULL(@SupportedKinds, [SupportedKinds]) END,
        [DefaultQualificationPolicy] = ISNULL(@DefaultQualificationPolicy, [DefaultQualificationPolicy]),
        [DefaultSkippedContentPolicy] = ISNULL(@DefaultSkippedContentPolicy, [DefaultSkippedContentPolicy]),
        [DefaultEncryptionKeyID] = CASE WHEN @DefaultEncryptionKeyID_Clear = 1 THEN NULL ELSE ISNULL(@DefaultEncryptionKeyID, [DefaultEncryptionKeyID]) END,
        [DefaultStorageProviderID] = CASE WHEN @DefaultStorageProviderID_Clear = 1 THEN NULL ELSE ISNULL(@DefaultStorageProviderID, [DefaultStorageProviderID]) END,
        [DefaultMaxAttachmentBytes] = CASE WHEN @DefaultMaxAttachmentBytes_Clear = 1 THEN NULL ELSE ISNULL(@DefaultMaxAttachmentBytes, [DefaultMaxAttachmentBytes]) END,
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [IsSystem] = ISNULL(@IsSystem, [IsSystem]),
        [IsActive] = ISNULL(@IsActive, [IsActive]),
        [CalendarDriverClass] = CASE WHEN @CalendarDriverClass_Clear = 1 THEN NULL ELSE ISNULL(@CalendarDriverClass, [CalendarDriverClass]) END,
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivitySyncProviderTypes] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivitySyncProviderTypes]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncProviderType] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncProviderType] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ActivitySyncProviderType table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivitySyncProviderType]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivitySyncProviderType];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivitySyncProviderType
ON [${flyway:defaultSchema}].[ActivitySyncProviderType]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[ActivitySyncProviderType]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[ActivitySyncProviderType] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ActivitySyncRule
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivitySyncRule]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncRule];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncRule]
    @ID uniqueidentifier,
    @ActivitySyncConnectionID_Clear bit = 0,
    @ActivitySyncConnectionID uniqueidentifier = NULL,
    @Name nvarchar(200) = NULL,
    @IsEnabled bit = NULL,
    @Sequence int = NULL,
    @Action nvarchar(20) = NULL,
    @ActivityTypeID_Clear bit = 0,
    @ActivityTypeID uniqueidentifier = NULL,
    @Direction_Clear bit = 0,
    @Direction nvarchar(20) = NULL,
    @DateFrom_Clear bit = 0,
    @DateFrom datetimeoffset = NULL,
    @DateTo_Clear bit = 0,
    @DateTo datetimeoffset = NULL,
    @IncludeAttachments bit = NULL,
    @Filter_Clear bit = 0,
    @Filter nvarchar(MAX) = NULL,
    @ActivitySyncRuleSetID_Clear bit = 0,
    @ActivitySyncRuleSetID uniqueidentifier = NULL,
    @ParticipantScope_Clear bit = 0,
    @ParticipantScope nvarchar(30) = NULL,
    @MaxAttachmentBytes_Clear bit = 0,
    @MaxAttachmentBytes bigint = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncRule]
    SET
        [ActivitySyncConnectionID] = CASE WHEN @ActivitySyncConnectionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncConnectionID, [ActivitySyncConnectionID]) END,
        [Name] = ISNULL(@Name, [Name]),
        [IsEnabled] = ISNULL(@IsEnabled, [IsEnabled]),
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [Action] = ISNULL(@Action, [Action]),
        [ActivityTypeID] = CASE WHEN @ActivityTypeID_Clear = 1 THEN NULL ELSE ISNULL(@ActivityTypeID, [ActivityTypeID]) END,
        [Direction] = CASE WHEN @Direction_Clear = 1 THEN NULL ELSE ISNULL(@Direction, [Direction]) END,
        [DateFrom] = CASE WHEN @DateFrom_Clear = 1 THEN NULL ELSE ISNULL(@DateFrom, [DateFrom]) END,
        [DateTo] = CASE WHEN @DateTo_Clear = 1 THEN NULL ELSE ISNULL(@DateTo, [DateTo]) END,
        [IncludeAttachments] = ISNULL(@IncludeAttachments, [IncludeAttachments]),
        [Filter] = CASE WHEN @Filter_Clear = 1 THEN NULL ELSE ISNULL(@Filter, [Filter]) END,
        [ActivitySyncRuleSetID] = CASE WHEN @ActivitySyncRuleSetID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncRuleSetID, [ActivitySyncRuleSetID]) END,
        [ParticipantScope] = CASE WHEN @ParticipantScope_Clear = 1 THEN NULL ELSE ISNULL(@ParticipantScope, [ParticipantScope]) END,
        [MaxAttachmentBytes] = CASE WHEN @MaxAttachmentBytes_Clear = 1 THEN NULL ELSE ISNULL(@MaxAttachmentBytes, [MaxAttachmentBytes]) END,
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivitySyncRules] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivitySyncRules]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRule] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRule] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ActivitySyncRule table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivitySyncRule]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivitySyncRule];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivitySyncRule
ON [${flyway:defaultSchema}].[ActivitySyncRule]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[ActivitySyncRule]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[ActivitySyncRule] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ActivitySyncRuleSet
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivitySyncRuleSet]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncRuleSet];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncRuleSet]
    @ID uniqueidentifier,
    @Name nvarchar(200) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @ActivitySyncProviderTypeID_Clear bit = 0,
    @ActivitySyncProviderTypeID uniqueidentifier = NULL,
    @InternalDomains_Clear bit = 0,
    @InternalDomains nvarchar(MAX) = NULL,
    @Sequence int = NULL,
    @IsEnabled bit = NULL,
    @IsSystem bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncRuleSet]
    SET
        [Name] = ISNULL(@Name, [Name]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [ActivitySyncProviderTypeID] = CASE WHEN @ActivitySyncProviderTypeID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncProviderTypeID, [ActivitySyncProviderTypeID]) END,
        [InternalDomains] = CASE WHEN @InternalDomains_Clear = 1 THEN NULL ELSE ISNULL(@InternalDomains, [InternalDomains]) END,
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [IsEnabled] = ISNULL(@IsEnabled, [IsEnabled]),
        [IsSystem] = ISNULL(@IsSystem, [IsSystem]),
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivitySyncRuleSets] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivitySyncRuleSets]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRuleSet] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRuleSet] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ActivitySyncRuleSet table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivitySyncRuleSet]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivitySyncRuleSet];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivitySyncRuleSet
ON [${flyway:defaultSchema}].[ActivitySyncRuleSet]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[ActivitySyncRuleSet]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[ActivitySyncRuleSet] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ActivitySyncRun
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivitySyncRun]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncRun];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncRun]
    @ID uniqueidentifier,
    @ActivitySyncConnectionID uniqueidentifier = NULL,
    @StartedAt datetimeoffset = NULL,
    @EndedAt_Clear bit = 0,
    @EndedAt datetimeoffset = NULL,
    @Status nvarchar(20) = NULL,
    @TriggerType nvarchar(20) = NULL,
    @IsDryRun bit = NULL,
    @Fetched int = NULL,
    @Included int = NULL,
    @Excluded int = NULL,
    @Duplicates int = NULL,
    @Failed int = NULL,
    @ExtensionErrors int = NULL,
    @WatermarkBefore_Clear bit = 0,
    @WatermarkBefore datetimeoffset = NULL,
    @WatermarkAfter_Clear bit = 0,
    @WatermarkAfter datetimeoffset = NULL,
    @ErrorMessage_Clear bit = 0,
    @ErrorMessage nvarchar(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncRun]
    SET
        [ActivitySyncConnectionID] = ISNULL(@ActivitySyncConnectionID, [ActivitySyncConnectionID]),
        [StartedAt] = ISNULL(@StartedAt, [StartedAt]),
        [EndedAt] = CASE WHEN @EndedAt_Clear = 1 THEN NULL ELSE ISNULL(@EndedAt, [EndedAt]) END,
        [Status] = ISNULL(@Status, [Status]),
        [TriggerType] = ISNULL(@TriggerType, [TriggerType]),
        [IsDryRun] = ISNULL(@IsDryRun, [IsDryRun]),
        [Fetched] = ISNULL(@Fetched, [Fetched]),
        [Included] = ISNULL(@Included, [Included]),
        [Excluded] = ISNULL(@Excluded, [Excluded]),
        [Duplicates] = ISNULL(@Duplicates, [Duplicates]),
        [Failed] = ISNULL(@Failed, [Failed]),
        [ExtensionErrors] = ISNULL(@ExtensionErrors, [ExtensionErrors]),
        [WatermarkBefore] = CASE WHEN @WatermarkBefore_Clear = 1 THEN NULL ELSE ISNULL(@WatermarkBefore, [WatermarkBefore]) END,
        [WatermarkAfter] = CASE WHEN @WatermarkAfter_Clear = 1 THEN NULL ELSE ISNULL(@WatermarkAfter, [WatermarkAfter]) END,
        [ErrorMessage] = CASE WHEN @ErrorMessage_Clear = 1 THEN NULL ELSE ISNULL(@ErrorMessage, [ErrorMessage]) END,
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivitySyncRuns] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivitySyncRuns]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRun] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRun] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ActivitySyncRun table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivitySyncRun]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivitySyncRun];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivitySyncRun
ON [${flyway:defaultSchema}].[ActivitySyncRun]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[ActivitySyncRun]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[ActivitySyncRun] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ActivitySyncRunDetail
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivitySyncRunDetail]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncRunDetail];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncRunDetail]
    @ID uniqueidentifier,
    @ActivitySyncRunID uniqueidentifier = NULL,
    @ExternalID nvarchar(400) = NULL,
    @ExternalThreadID_Clear bit = 0,
    @ExternalThreadID nvarchar(400) = NULL,
    @OccurredAt_Clear bit = 0,
    @OccurredAt datetimeoffset = NULL,
    @Decision nvarchar(20) = NULL,
    @DecidedByStage_Clear bit = 0,
    @DecidedByStage nvarchar(100) = NULL,
    @ActivitySyncRuleID_Clear bit = 0,
    @ActivitySyncRuleID uniqueidentifier = NULL,
    @ActivitySyncExclusionID_Clear bit = 0,
    @ActivitySyncExclusionID uniqueidentifier = NULL,
    @Reason_Clear bit = 0,
    @Reason nvarchar(MAX) = NULL,
    @Confidence_Clear bit = 0,
    @Confidence decimal(5, 4) = NULL,
    @AIPromptRunID_Clear bit = 0,
    @AIPromptRunID uniqueidentifier = NULL,
    @ActivityID_Clear bit = 0,
    @ActivityID uniqueidentifier = NULL,
    @CapturedContent_Clear bit = 0,
    @CapturedContent nvarchar(MAX) = NULL,
    @EncryptionKeyID_Clear bit = 0,
    @EncryptionKeyID uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncRunDetail]
    SET
        [ActivitySyncRunID] = ISNULL(@ActivitySyncRunID, [ActivitySyncRunID]),
        [ExternalID] = ISNULL(@ExternalID, [ExternalID]),
        [ExternalThreadID] = CASE WHEN @ExternalThreadID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalThreadID, [ExternalThreadID]) END,
        [OccurredAt] = CASE WHEN @OccurredAt_Clear = 1 THEN NULL ELSE ISNULL(@OccurredAt, [OccurredAt]) END,
        [Decision] = ISNULL(@Decision, [Decision]),
        [DecidedByStage] = CASE WHEN @DecidedByStage_Clear = 1 THEN NULL ELSE ISNULL(@DecidedByStage, [DecidedByStage]) END,
        [ActivitySyncRuleID] = CASE WHEN @ActivitySyncRuleID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncRuleID, [ActivitySyncRuleID]) END,
        [ActivitySyncExclusionID] = CASE WHEN @ActivitySyncExclusionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncExclusionID, [ActivitySyncExclusionID]) END,
        [Reason] = CASE WHEN @Reason_Clear = 1 THEN NULL ELSE ISNULL(@Reason, [Reason]) END,
        [Confidence] = CASE WHEN @Confidence_Clear = 1 THEN NULL ELSE ISNULL(@Confidence, [Confidence]) END,
        [AIPromptRunID] = CASE WHEN @AIPromptRunID_Clear = 1 THEN NULL ELSE ISNULL(@AIPromptRunID, [AIPromptRunID]) END,
        [ActivityID] = CASE WHEN @ActivityID_Clear = 1 THEN NULL ELSE ISNULL(@ActivityID, [ActivityID]) END,
        [CapturedContent] = CASE WHEN @CapturedContent_Clear = 1 THEN NULL ELSE ISNULL(@CapturedContent, [CapturedContent]) END,
        [EncryptionKeyID] = CASE WHEN @EncryptionKeyID_Clear = 1 THEN NULL ELSE ISNULL(@EncryptionKeyID, [EncryptionKeyID]) END,
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivitySyncRunDetails] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivitySyncRunDetails]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRunDetail] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRunDetail] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ActivitySyncRunDetail table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivitySyncRunDetail]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivitySyncRunDetail];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivitySyncRunDetail
ON [${flyway:defaultSchema}].[ActivitySyncRunDetail]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[ActivitySyncRunDetail]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[ActivitySyncRunDetail] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ActivityType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivityType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivityType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivityType]
    @ID uniqueidentifier,
    @Code nvarchar(50) = NULL,
    @Name nvarchar(100) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @ParentID_Clear bit = 0,
    @ParentID uniqueidentifier = NULL,
    @IconClass_Clear bit = 0,
    @IconClass nvarchar(100) = NULL,
    @Color_Clear bit = 0,
    @Color nvarchar(30) = NULL,
    @Sequence int = NULL,
    @IsSystem bit = NULL,
    @IsActive bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivityType]
    SET
        [Code] = ISNULL(@Code, [Code]),
        [Name] = ISNULL(@Name, [Name]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [ParentID] = CASE WHEN @ParentID_Clear = 1 THEN NULL ELSE ISNULL(@ParentID, [ParentID]) END,
        [IconClass] = CASE WHEN @IconClass_Clear = 1 THEN NULL ELSE ISNULL(@IconClass, [IconClass]) END,
        [Color] = CASE WHEN @Color_Clear = 1 THEN NULL ELSE ISNULL(@Color, [Color]) END,
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [IsSystem] = ISNULL(@IsSystem, [IsSystem]),
        [IsActive] = ISNULL(@IsActive, [IsActive]),
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivityTypes] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivityTypes]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivityType] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivityType] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ActivityType table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivityType]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivityType];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivityType
ON [${flyway:defaultSchema}].[ActivityType]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[ActivityType]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[ActivityType] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Address
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateAddress]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateAddress];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateAddress]
    @ID uniqueidentifier,
    @Line1_Clear bit = 0,
    @Line1 nvarchar(255) = NULL,
    @Line2_Clear bit = 0,
    @Line2 nvarchar(255) = NULL,
    @Line3_Clear bit = 0,
    @Line3 nvarchar(255) = NULL,
    @City_Clear bit = 0,
    @City nvarchar(100) = NULL,
    @StateProvince_Clear bit = 0,
    @StateProvince nvarchar(100) = NULL,
    @PostalCode_Clear bit = 0,
    @PostalCode nvarchar(20) = NULL,
    @Country nvarchar(100) = NULL,
    @Latitude_Clear bit = 0,
    @Latitude decimal(9, 6) = NULL,
    @Longitude_Clear bit = 0,
    @Longitude decimal(9, 6) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Address]
    SET
        [Line1] = CASE WHEN @Line1_Clear = 1 THEN NULL ELSE ISNULL(@Line1, [Line1]) END,
        [Line2] = CASE WHEN @Line2_Clear = 1 THEN NULL ELSE ISNULL(@Line2, [Line2]) END,
        [Line3] = CASE WHEN @Line3_Clear = 1 THEN NULL ELSE ISNULL(@Line3, [Line3]) END,
        [City] = CASE WHEN @City_Clear = 1 THEN NULL ELSE ISNULL(@City, [City]) END,
        [StateProvince] = CASE WHEN @StateProvince_Clear = 1 THEN NULL ELSE ISNULL(@StateProvince, [StateProvince]) END,
        [PostalCode] = CASE WHEN @PostalCode_Clear = 1 THEN NULL ELSE ISNULL(@PostalCode, [PostalCode]) END,
        [Country] = ISNULL(@Country, [Country]),
        [Latitude] = CASE WHEN @Latitude_Clear = 1 THEN NULL ELSE ISNULL(@Latitude, [Latitude]) END,
        [Longitude] = CASE WHEN @Longitude_Clear = 1 THEN NULL ELSE ISNULL(@Longitude, [Longitude]) END,
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwAddresses] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwAddresses]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateAddress] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateAddress] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Address table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateAddress]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateAddress];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateAddress
ON [${flyway:defaultSchema}].[Address]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[Address]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[Address] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR AddressLink
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateAddressLink]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateAddressLink];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateAddressLink]
    @ID uniqueidentifier,
    @AddressID uniqueidentifier = NULL,
    @EntityID uniqueidentifier = NULL,
    @RecordID nvarchar(700) = NULL,
    @AddressTypeID uniqueidentifier = NULL,
    @IsPrimary bit = NULL,
    @Rank_Clear bit = 0,
    @Rank int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[AddressLink]
    SET
        [AddressID] = ISNULL(@AddressID, [AddressID]),
        [EntityID] = ISNULL(@EntityID, [EntityID]),
        [RecordID] = ISNULL(@RecordID, [RecordID]),
        [AddressTypeID] = ISNULL(@AddressTypeID, [AddressTypeID]),
        [IsPrimary] = ISNULL(@IsPrimary, [IsPrimary]),
        [Rank] = CASE WHEN @Rank_Clear = 1 THEN NULL ELSE ISNULL(@Rank, [Rank]) END,
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwAddressLinks] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwAddressLinks]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateAddressLink] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateAddressLink] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the AddressLink table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateAddressLink]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateAddressLink];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateAddressLink
ON [${flyway:defaultSchema}].[AddressLink]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[AddressLink]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[AddressLink] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR AddressType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateAddressType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateAddressType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateAddressType]
    @ID uniqueidentifier,
    @Name nvarchar(100) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @IconClass_Clear bit = 0,
    @IconClass nvarchar(100) = NULL,
    @DefaultRank int = NULL,
    @IsActive bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[AddressType]
    SET
        [Name] = ISNULL(@Name, [Name]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [IconClass] = CASE WHEN @IconClass_Clear = 1 THEN NULL ELSE ISNULL(@IconClass, [IconClass]) END,
        [DefaultRank] = ISNULL(@DefaultRank, [DefaultRank]),
        [IsActive] = ISNULL(@IsActive, [IsActive]),
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwAddressTypes] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwAddressTypes]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateAddressType] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateAddressType] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the AddressType table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateAddressType]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateAddressType];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateAddressType
ON [${flyway:defaultSchema}].[AddressType]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[AddressType]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[AddressType] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR CompanySenderIdentity
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateCompanySenderIdentity]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateCompanySenderIdentity];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateCompanySenderIdentity]
    @ID uniqueidentifier,
    @CompanyID uniqueidentifier = NULL,
    @Kind nvarchar(20) = NULL,
    @Address nvarchar(320) = NULL,
    @DisplayName_Clear bit = 0,
    @DisplayName nvarchar(200) = NULL,
    @IsDefault bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[CompanySenderIdentity]
    SET
        [CompanyID] = ISNULL(@CompanyID, [CompanyID]),
        [Kind] = ISNULL(@Kind, [Kind]),
        [Address] = ISNULL(@Address, [Address]),
        [DisplayName] = CASE WHEN @DisplayName_Clear = 1 THEN NULL ELSE ISNULL(@DisplayName, [DisplayName]) END,
        [IsDefault] = ISNULL(@IsDefault, [IsDefault]),
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwCompanySenderIdentities] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwCompanySenderIdentities]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateCompanySenderIdentity] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateCompanySenderIdentity] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the CompanySenderIdentity table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateCompanySenderIdentity]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateCompanySenderIdentity];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateCompanySenderIdentity
ON [${flyway:defaultSchema}].[CompanySenderIdentity]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[CompanySenderIdentity]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[CompanySenderIdentity] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ConsentPurpose
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateConsentPurpose]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateConsentPurpose];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateConsentPurpose]
    @ID uniqueidentifier,
    @Name nvarchar(100) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Sequence int = NULL,
    @IsActive bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ConsentPurpose]
    SET
        [Name] = ISNULL(@Name, [Name]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [IsActive] = ISNULL(@IsActive, [IsActive]),
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwConsentPurposes] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwConsentPurposes]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateConsentPurpose] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateConsentPurpose] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ConsentPurpose table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateConsentPurpose]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateConsentPurpose];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateConsentPurpose
ON [${flyway:defaultSchema}].[ConsentPurpose]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[ConsentPurpose]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[ConsentPurpose] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ContactMethod
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateContactMethod]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateContactMethod];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateContactMethod]
    @ID uniqueidentifier,
    @PersonID_Clear bit = 0,
    @PersonID uniqueidentifier = NULL,
    @OrganizationID_Clear bit = 0,
    @OrganizationID uniqueidentifier = NULL,
    @ContactTypeID uniqueidentifier = NULL,
    @Value nvarchar(500) = NULL,
    @Label_Clear bit = 0,
    @Label nvarchar(100) = NULL,
    @IsPrimary bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ContactMethod]
    SET
        [PersonID] = CASE WHEN @PersonID_Clear = 1 THEN NULL ELSE ISNULL(@PersonID, [PersonID]) END,
        [OrganizationID] = CASE WHEN @OrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationID, [OrganizationID]) END,
        [ContactTypeID] = ISNULL(@ContactTypeID, [ContactTypeID]),
        [Value] = ISNULL(@Value, [Value]),
        [Label] = CASE WHEN @Label_Clear = 1 THEN NULL ELSE ISNULL(@Label, [Label]) END,
        [IsPrimary] = ISNULL(@IsPrimary, [IsPrimary]),
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwContactMethods] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwContactMethods]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactMethod] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactMethod] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ContactMethod table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateContactMethod]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateContactMethod];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateContactMethod
ON [${flyway:defaultSchema}].[ContactMethod]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[ContactMethod]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[ContactMethod] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ContactMethodConsent
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateContactMethodConsent]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateContactMethodConsent];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateContactMethodConsent]
    @ID uniqueidentifier,
    @ContactMethodID uniqueidentifier = NULL,
    @ConsentPurposeID_Clear bit = 0,
    @ConsentPurposeID uniqueidentifier = NULL,
    @RequestingOrganizationID_Clear bit = 0,
    @RequestingOrganizationID uniqueidentifier = NULL,
    @ConsentStatus nvarchar(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ContactMethodConsent]
    SET
        [ContactMethodID] = ISNULL(@ContactMethodID, [ContactMethodID]),
        [ConsentPurposeID] = CASE WHEN @ConsentPurposeID_Clear = 1 THEN NULL ELSE ISNULL(@ConsentPurposeID, [ConsentPurposeID]) END,
        [RequestingOrganizationID] = CASE WHEN @RequestingOrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@RequestingOrganizationID, [RequestingOrganizationID]) END,
        [ConsentStatus] = ISNULL(@ConsentStatus, [ConsentStatus]),
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwContactMethodConsents] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwContactMethodConsents]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactMethodConsent] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactMethodConsent] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ContactMethodConsent table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateContactMethodConsent]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateContactMethodConsent];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateContactMethodConsent
ON [${flyway:defaultSchema}].[ContactMethodConsent]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[ContactMethodConsent]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[ContactMethodConsent] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ContactMethodConsentHistory
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateContactMethodConsentHistory]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateContactMethodConsentHistory];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateContactMethodConsentHistory]
    @ID uniqueidentifier,
    @ContactMethodConsentID uniqueidentifier = NULL,
    @NewConsentStatus nvarchar(20) = NULL,
    @ConsentStatusAt datetimeoffset = NULL,
    @ConsentSource nvarchar(50) = NULL,
    @RecordedByUserID_Clear bit = 0,
    @RecordedByUserID uniqueidentifier = NULL,
    @ConsentDetails_Clear bit = 0,
    @ConsentDetails nvarchar(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ContactMethodConsentHistory]
    SET
        [ContactMethodConsentID] = ISNULL(@ContactMethodConsentID, [ContactMethodConsentID]),
        [NewConsentStatus] = ISNULL(@NewConsentStatus, [NewConsentStatus]),
        [ConsentStatusAt] = ISNULL(@ConsentStatusAt, [ConsentStatusAt]),
        [ConsentSource] = ISNULL(@ConsentSource, [ConsentSource]),
        [RecordedByUserID] = CASE WHEN @RecordedByUserID_Clear = 1 THEN NULL ELSE ISNULL(@RecordedByUserID, [RecordedByUserID]) END,
        [ConsentDetails] = CASE WHEN @ConsentDetails_Clear = 1 THEN NULL ELSE ISNULL(@ConsentDetails, [ConsentDetails]) END,
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwContactMethodConsentHistories] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwContactMethodConsentHistories]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactMethodConsentHistory] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactMethodConsentHistory] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ContactMethodConsentHistory table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateContactMethodConsentHistory]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateContactMethodConsentHistory];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateContactMethodConsentHistory
ON [${flyway:defaultSchema}].[ContactMethodConsentHistory]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[ContactMethodConsentHistory]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[ContactMethodConsentHistory] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ContactType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateContactType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateContactType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateContactType]
    @ID uniqueidentifier,
    @Name nvarchar(100) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @IconClass_Clear bit = 0,
    @IconClass nvarchar(100) = NULL,
    @DisplayRank int = NULL,
    @IsActive bit = NULL,
    @CommunicationBaseMessageTypeID_Clear bit = 0,
    @CommunicationBaseMessageTypeID uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ContactType]
    SET
        [Name] = ISNULL(@Name, [Name]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [IconClass] = CASE WHEN @IconClass_Clear = 1 THEN NULL ELSE ISNULL(@IconClass, [IconClass]) END,
        [DisplayRank] = ISNULL(@DisplayRank, [DisplayRank]),
        [IsActive] = ISNULL(@IsActive, [IsActive]),
        [CommunicationBaseMessageTypeID] = CASE WHEN @CommunicationBaseMessageTypeID_Clear = 1 THEN NULL ELSE ISNULL(@CommunicationBaseMessageTypeID, [CommunicationBaseMessageTypeID]) END,
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwContactTypes] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwContactTypes]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactType] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactType] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ContactType table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateContactType]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateContactType];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateContactType
ON [${flyway:defaultSchema}].[ContactType]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[ContactType]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[ContactType] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR JobFunction
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateJobFunction]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateJobFunction];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateJobFunction]
    @ID uniqueidentifier,
    @Name nvarchar(100) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Sequence int = NULL,
    @Status nvarchar(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[JobFunction]
    SET
        [Name] = ISNULL(@Name, [Name]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [Status] = ISNULL(@Status, [Status]),
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwJobFunctions] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwJobFunctions]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateJobFunction] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateJobFunction] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the JobFunction table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateJobFunction]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateJobFunction];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateJobFunction
ON [${flyway:defaultSchema}].[JobFunction]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[JobFunction]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[JobFunction] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Organization
------------------------------------------------------------
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
    @Status nvarchar(50) = NULL,
    @Acronym_Clear bit = 0,
    @Acronym nvarchar(20) = NULL
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
        [Status] = ISNULL(@Status, [Status]),
        [Acronym] = CASE WHEN @Acronym_Clear = 1 THEN NULL ELSE ISNULL(@Acronym, [Acronym]) END,
        [__mj_UpdatedAt] = GETUTCDATE()
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
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateOrganization] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Organization table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateOrganization]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateOrganization];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateOrganization
ON [${flyway:defaultSchema}].[Organization]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[Organization]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[Organization] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR OrganizationType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateOrganizationType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateOrganizationType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateOrganizationType]
    @ID uniqueidentifier,
    @Name nvarchar(100) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @IconClass_Clear bit = 0,
    @IconClass nvarchar(100) = NULL,
    @DisplayRank int = NULL,
    @IsActive bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[OrganizationType]
    SET
        [Name] = ISNULL(@Name, [Name]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [IconClass] = CASE WHEN @IconClass_Clear = 1 THEN NULL ELSE ISNULL(@IconClass, [IconClass]) END,
        [DisplayRank] = ISNULL(@DisplayRank, [DisplayRank]),
        [IsActive] = ISNULL(@IsActive, [IsActive]),
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwOrganizationTypes] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwOrganizationTypes]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateOrganizationType] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateOrganizationType] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the OrganizationType table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateOrganizationType]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateOrganizationType];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateOrganizationType
ON [${flyway:defaultSchema}].[OrganizationType]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[OrganizationType]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[OrganizationType] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

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
        [SeniorityLevelID] = CASE WHEN @SeniorityLevelID_Clear = 1 THEN NULL ELSE ISNULL(@SeniorityLevelID, [SeniorityLevelID]) END,
        [__mj_UpdatedAt] = GETUTCDATE()
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

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdatePerson] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdatePerson] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Person table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdatePerson]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdatePerson];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdatePerson
ON [${flyway:defaultSchema}].[Person]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[Person]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[Person] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR PersonJobFunction
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdatePersonJobFunction]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdatePersonJobFunction];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdatePersonJobFunction]
    @ID uniqueidentifier,
    @PersonID uniqueidentifier = NULL,
    @JobFunctionID uniqueidentifier = NULL,
    @Sequence int = NULL,
    @Source nvarchar(20) = NULL,
    @Confidence_Clear bit = 0,
    @Confidence decimal(5, 4) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[PersonJobFunction]
    SET
        [PersonID] = ISNULL(@PersonID, [PersonID]),
        [JobFunctionID] = ISNULL(@JobFunctionID, [JobFunctionID]),
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [Source] = ISNULL(@Source, [Source]),
        [Confidence] = CASE WHEN @Confidence_Clear = 1 THEN NULL ELSE ISNULL(@Confidence, [Confidence]) END,
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwPersonJobFunctions] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwPersonJobFunctions]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdatePersonJobFunction] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdatePersonJobFunction] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the PersonJobFunction table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdatePersonJobFunction]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdatePersonJobFunction];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdatePersonJobFunction
ON [${flyway:defaultSchema}].[PersonJobFunction]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[PersonJobFunction]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[PersonJobFunction] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Relationship
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateRelationship]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateRelationship];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateRelationship]
    @ID uniqueidentifier,
    @RelationshipTypeID uniqueidentifier = NULL,
    @FromPersonID_Clear bit = 0,
    @FromPersonID uniqueidentifier = NULL,
    @FromOrganizationID_Clear bit = 0,
    @FromOrganizationID uniqueidentifier = NULL,
    @ToPersonID_Clear bit = 0,
    @ToPersonID uniqueidentifier = NULL,
    @ToOrganizationID_Clear bit = 0,
    @ToOrganizationID uniqueidentifier = NULL,
    @Title_Clear bit = 0,
    @Title nvarchar(255) = NULL,
    @StartDate_Clear bit = 0,
    @StartDate date = NULL,
    @EndDate_Clear bit = 0,
    @EndDate date = NULL,
    @Status nvarchar(50) = NULL,
    @Notes_Clear bit = 0,
    @Notes nvarchar(MAX) = NULL,
    @JobFunctionID_Clear bit = 0,
    @JobFunctionID uniqueidentifier = NULL,
    @SeniorityLevelID_Clear bit = 0,
    @SeniorityLevelID uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Relationship]
    SET
        [RelationshipTypeID] = ISNULL(@RelationshipTypeID, [RelationshipTypeID]),
        [FromPersonID] = CASE WHEN @FromPersonID_Clear = 1 THEN NULL ELSE ISNULL(@FromPersonID, [FromPersonID]) END,
        [FromOrganizationID] = CASE WHEN @FromOrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@FromOrganizationID, [FromOrganizationID]) END,
        [ToPersonID] = CASE WHEN @ToPersonID_Clear = 1 THEN NULL ELSE ISNULL(@ToPersonID, [ToPersonID]) END,
        [ToOrganizationID] = CASE WHEN @ToOrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@ToOrganizationID, [ToOrganizationID]) END,
        [Title] = CASE WHEN @Title_Clear = 1 THEN NULL ELSE ISNULL(@Title, [Title]) END,
        [StartDate] = CASE WHEN @StartDate_Clear = 1 THEN NULL ELSE ISNULL(@StartDate, [StartDate]) END,
        [EndDate] = CASE WHEN @EndDate_Clear = 1 THEN NULL ELSE ISNULL(@EndDate, [EndDate]) END,
        [Status] = ISNULL(@Status, [Status]),
        [Notes] = CASE WHEN @Notes_Clear = 1 THEN NULL ELSE ISNULL(@Notes, [Notes]) END,
        [JobFunctionID] = CASE WHEN @JobFunctionID_Clear = 1 THEN NULL ELSE ISNULL(@JobFunctionID, [JobFunctionID]) END,
        [SeniorityLevelID] = CASE WHEN @SeniorityLevelID_Clear = 1 THEN NULL ELSE ISNULL(@SeniorityLevelID, [SeniorityLevelID]) END,
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwRelationships] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwRelationships]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateRelationship] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateRelationship] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Relationship table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateRelationship]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateRelationship];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateRelationship
ON [${flyway:defaultSchema}].[Relationship]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[Relationship]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[Relationship] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR RelationshipType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateRelationshipType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateRelationshipType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateRelationshipType]
    @ID uniqueidentifier,
    @Name nvarchar(100) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Category nvarchar(50) = NULL,
    @IsDirectional bit = NULL,
    @ForwardLabel_Clear bit = 0,
    @ForwardLabel nvarchar(100) = NULL,
    @ReverseLabel_Clear bit = 0,
    @ReverseLabel nvarchar(100) = NULL,
    @IsActive bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[RelationshipType]
    SET
        [Name] = ISNULL(@Name, [Name]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [Category] = ISNULL(@Category, [Category]),
        [IsDirectional] = ISNULL(@IsDirectional, [IsDirectional]),
        [ForwardLabel] = CASE WHEN @ForwardLabel_Clear = 1 THEN NULL ELSE ISNULL(@ForwardLabel, [ForwardLabel]) END,
        [ReverseLabel] = CASE WHEN @ReverseLabel_Clear = 1 THEN NULL ELSE ISNULL(@ReverseLabel, [ReverseLabel]) END,
        [IsActive] = ISNULL(@IsActive, [IsActive]),
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwRelationshipTypes] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwRelationshipTypes]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateRelationshipType] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateRelationshipType] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the RelationshipType table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateRelationshipType]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateRelationshipType];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateRelationshipType
ON [${flyway:defaultSchema}].[RelationshipType]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[RelationshipType]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[RelationshipType] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO

------------------------------------------------------------
----- UPDATE PROCEDURE FOR SeniorityLevel
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateSeniorityLevel]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateSeniorityLevel];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateSeniorityLevel]
    @ID uniqueidentifier,
    @Name nvarchar(100) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Sequence int = NULL,
    @Status nvarchar(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[SeniorityLevel]
    SET
        [Name] = ISNULL(@Name, [Name]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [Status] = ISNULL(@Status, [Status]),
        [__mj_UpdatedAt] = GETUTCDATE()
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwSeniorityLevels] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwSeniorityLevels]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateSeniorityLevel] TO [cdp_Developer], [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateSeniorityLevel] TO [cdp_Developer], [cdp_Integration];
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the SeniorityLevel table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateSeniorityLevel]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateSeniorityLevel];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateSeniorityLevel
ON [${flyway:defaultSchema}].[SeniorityLevel]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([__mj_UpdatedAt])
    BEGIN
        UPDATE
            [${flyway:defaultSchema}].[SeniorityLevel]
        SET
            __mj_UpdatedAt = GETUTCDATE()
        FROM
            [${flyway:defaultSchema}].[SeniorityLevel] AS _organicTable
        INNER JOIN
            INSERTED AS I ON
            _organicTable.[ID] = I.[ID];
    END
END;
GO
