-- =============================================================================
-- Migration: V202610191130__v5.55.x__Contact_Method_Consent.sql
-- Description: Per-contact-method consent (plans/contact-consent.md)
--              - ContactMethod.ConsentStatus: the current consent for this email or phone
--              - ContactConsentHistory: one row per consent change, with when it took effect
--                and where it came from
--              - ContactType.CommunicationBaseMessageTypeID: which MJ communication channel
--                (Email, Phone, SMS) a contact type carries, so code never matches on names
-- =============================================================================

---------------------------------------------------------------------------
-- ContactType: link each type to MJ's Communication Base Message Type
---------------------------------------------------------------------------
IF COL_LENGTH(N'[${flyway:defaultSchema}].[ContactType]', N'CommunicationBaseMessageTypeID') IS NULL
BEGIN
    ALTER TABLE [${flyway:defaultSchema}].[ContactType]
        ADD CommunicationBaseMessageTypeID UNIQUEIDENTIFIER NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ContactType_CommunicationBaseMessageType')
BEGIN
    ALTER TABLE [${flyway:defaultSchema}].[ContactType]
        ADD CONSTRAINT FK_ContactType_CommunicationBaseMessageType FOREIGN KEY (CommunicationBaseMessageTypeID)
            REFERENCES [${mjSchema}].[CommunicationBaseMessageType](ID);
END
GO

---------------------------------------------------------------------------
-- ContactMethod: current consent status
---------------------------------------------------------------------------
IF COL_LENGTH(N'[${flyway:defaultSchema}].[ContactMethod]', N'ConsentStatus') IS NULL
BEGIN
    ALTER TABLE [${flyway:defaultSchema}].[ContactMethod]
        ADD ConsentStatus NVARCHAR(20) NOT NULL DEFAULT N'NotSpecified';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ContactMethod_ConsentStatus')
BEGIN
    ALTER TABLE [${flyway:defaultSchema}].[ContactMethod]
        ADD CONSTRAINT CK_ContactMethod_ConsentStatus CHECK (ConsentStatus IN (N'NotSpecified', N'OptedIn', N'OptedOut'));
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description', N'SCHEMA', N'${flyway:defaultSchema}', N'TABLE', N'ContactMethod', N'COLUMN', N'ConsentStatus'))
BEGIN
    EXEC sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'The current consent for contacting this email or phone: NotSpecified, OptedIn or OptedOut. Always equals NewConsentStatus on the ContactConsentHistory row with the latest ConsentStatusAt. Set it through ContactPreferenceEngine, which writes the history row with it.',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE', @level1name = N'ContactMethod',
        @level2type = N'COLUMN', @level2name = N'ConsentStatus';
END
GO

---------------------------------------------------------------------------
-- ContactConsentHistory: one row per consent change on a contact method
---------------------------------------------------------------------------
IF OBJECT_ID(N'[${flyway:defaultSchema}].[ContactConsentHistory]', N'U') IS NULL
BEGIN
    CREATE TABLE [${flyway:defaultSchema}].[ContactConsentHistory] (
        ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
        ContactMethodID UNIQUEIDENTIFIER NOT NULL,
        NewConsentStatus NVARCHAR(20) NOT NULL,
        ConsentStatusAt DATETIMEOFFSET NOT NULL,
        ConsentSource NVARCHAR(200) NOT NULL,
        RecordedByUserID UNIQUEIDENTIFIER NULL,
        Notes NVARCHAR(MAX) NULL,
        CONSTRAINT PK_ContactConsentHistory PRIMARY KEY (ID),
        CONSTRAINT FK_ContactConsentHistory_ContactMethod FOREIGN KEY (ContactMethodID)
            REFERENCES [${flyway:defaultSchema}].[ContactMethod](ID)
            ON DELETE CASCADE,
        CONSTRAINT FK_ContactConsentHistory_RecordedByUser FOREIGN KEY (RecordedByUserID)
            REFERENCES [${mjSchema}].[User](ID),
        CONSTRAINT CK_ContactConsentHistory_NewConsentStatus CHECK (NewConsentStatus IN (N'NotSpecified', N'OptedIn', N'OptedOut'))
    );
END
GO

-- The "latest change for this contact method" read, which every status resolution does.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ContactConsentHistory_ContactMethod_ConsentStatusAt' AND object_id = OBJECT_ID(N'[${flyway:defaultSchema}].[ContactConsentHistory]'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_ContactConsentHistory_ContactMethod_ConsentStatusAt
        ON [${flyway:defaultSchema}].[ContactConsentHistory] (ContactMethodID, ConsentStatusAt DESC);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description', N'SCHEMA', N'${flyway:defaultSchema}', N'TABLE', N'ContactConsentHistory', NULL, NULL))
BEGIN
    EXEC sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'One row per consent change on a contact method (an email or phone): the status it set, when it took effect in the real world, and where it came from. ContactMethod.ConsentStatus mirrors the row with the latest ConsentStatusAt. A late-arriving change with an older date is kept here but does not change the current status. Deleting the contact method deletes its history.',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE', @level1name = N'ContactConsentHistory';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description', N'SCHEMA', N'${flyway:defaultSchema}', N'TABLE', N'ContactConsentHistory', N'COLUMN', N'NewConsentStatus'))
BEGIN
    EXEC sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'The consent status this change set: NotSpecified, OptedIn or OptedOut.',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE', @level1name = N'ContactConsentHistory',
        @level2type = N'COLUMN', @level2name = N'NewConsentStatus';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description', N'SCHEMA', N'${flyway:defaultSchema}', N'TABLE', N'ContactConsentHistory', N'COLUMN', N'ConsentStatusAt'))
BEGIN
    EXEC sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'When the change took effect in the real world (the unsubscribe click, the form submission, the import''s own date), not when this row was saved. The row with the latest value is the current status.',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE', @level1name = N'ContactConsentHistory',
        @level2type = N'COLUMN', @level2name = N'ConsentStatusAt';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description', N'SCHEMA', N'${flyway:defaultSchema}', N'TABLE', N'ContactConsentHistory', N'COLUMN', N'ConsentSource'))
BEGIN
    EXEC sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'Where the change came from, for example "Web signup", "Unsubscribe link", "Import: Tessitura" or "Staff".',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE', @level1name = N'ContactConsentHistory',
        @level2type = N'COLUMN', @level2name = N'ConsentSource';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description', N'SCHEMA', N'${flyway:defaultSchema}', N'TABLE', N'ContactConsentHistory', N'COLUMN', N'Notes'))
BEGIN
    EXEC sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'Evidence for the change, such as a form ID or the unsubscribe email''s message ID.',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE', @level1name = N'ContactConsentHistory',
        @level2type = N'COLUMN', @level2name = N'Notes';
END
GO


















































/* ============================================================================================
   ==== CODEGEN OUTPUT — DO NOT EDIT BELOW THIS LINE ====
   Generated by the MemberJunction CodeGen tool: MJ CLI 6.2.0-edge.4 / CodeGenLib from MJ `next`
   @ cf164901da, includeSchemas ['__mj_BizAppsCommon'], against a database built from migrations
   with metadata/ pushed first (so CHECK validators come from the pinned GeneratedCode rows).
   Contains: the Contact Consent Histories entity and its fields, the ConsentStatus and
   CommunicationBaseMessageTypeID fields, their value lists and relationships, FK indexes, the
   vwContactConsentHistories / vwContactMethods / vwContactTypes views, CRUD procs and permissions.
   Do NOT edit by hand. If the hand-written SQL above changes, re-run CodeGen and replace this
   whole section.
   Runs: one, after the hand-written DDL above.
   ============================================================================================ */

/* SQL generated to create new entity MJ_BizApps_Common: Contact Consent Histories */

      INSERT INTO [${mjSchema}].[Entity] (
         [ID],
         [Name],
         [DisplayName],
         [Description],
         [NameSuffix],
         [BaseTable],
         [BaseView],
         [SchemaName],
         [IncludeInAPI],
         [AllowUserSearchAPI],
         [AllowCaching],
         [TrackRecordChanges],
         [AuditRecordAccess],
         [AuditViewRuns],
         [AllowAllRowsAPI],
         [AllowCreateAPI],
         [AllowUpdateAPI],
         [AllowDeleteAPI],
         [UserViewMaxRows]
         , [__mj_CreatedAt]
         , [__mj_UpdatedAt]
      )
      VALUES (
         'b99c00a2-c42a-4e20-b23e-d8c88e2602d9',
         'MJ_BizApps_Common: Contact Consent Histories',
         'Contact Consent Histories',
         'One row per consent change on a contact method (an email or phone): the status it set, when it took effect in the real world, and where it came from. ContactMethod.ConsentStatus mirrors the row with the latest ConsentStatusAt. A late-arriving change with an older date is kept here but does not change the current status. Deleting the contact method deletes its history.',
         NULL,
         'ContactConsentHistory',
         'vwContactConsentHistories',
         '${flyway:defaultSchema}',
         1,
         1,
         0,
         1,
         0,
         0,
         0,
         1,
         1,
         1,
         1000
         , GETUTCDATE()
         , GETUTCDATE()
      );

/* SQL generated to add new entity MJ_BizApps_Common: Contact Consent Histories to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'b99c00a2-c42a-4e20-b23e-d8c88e2602d9', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consent Histories for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('b99c00a2-c42a-4e20-b23e-d8c88e2602d9' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('b99c00a2-c42a-4e20-b23e-d8c88e2602d9' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consent Histories for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('b99c00a2-c42a-4e20-b23e-d8c88e2602d9' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('b99c00a2-c42a-4e20-b23e-d8c88e2602d9' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consent Histories for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('b99c00a2-c42a-4e20-b23e-d8c88e2602d9' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('b99c00a2-c42a-4e20-b23e-d8c88e2602d9' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ContactConsentHistory */
ALTER TABLE [${flyway:defaultSchema}].[ContactConsentHistory] ADD [__mj_CreatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ContactConsentHistory */
UPDATE [${flyway:defaultSchema}].[ContactConsentHistory] SET [__mj_CreatedAt] = GETUTCDATE() WHERE [__mj_CreatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ContactConsentHistory */
ALTER TABLE [${flyway:defaultSchema}].[ContactConsentHistory] ALTER COLUMN [__mj_CreatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ContactConsentHistory */
ALTER TABLE [${flyway:defaultSchema}].[ContactConsentHistory] ADD CONSTRAINT [DF___mj_BizAppsCommon_ContactConsentHistory___mj_CreatedAt] DEFAULT GETUTCDATE() FOR [__mj_CreatedAt];
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ContactConsentHistory */
ALTER TABLE [${flyway:defaultSchema}].[ContactConsentHistory] ADD [__mj_UpdatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ContactConsentHistory */
UPDATE [${flyway:defaultSchema}].[ContactConsentHistory] SET [__mj_UpdatedAt] = GETUTCDATE() WHERE [__mj_UpdatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ContactConsentHistory */
ALTER TABLE [${flyway:defaultSchema}].[ContactConsentHistory] ALTER COLUMN [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ContactConsentHistory */
ALTER TABLE [${flyway:defaultSchema}].[ContactConsentHistory] ADD CONSTRAINT [DF___mj_BizAppsCommon_ContactConsentHistory___mj_UpdatedAt] DEFAULT GETUTCDATE() FOR [__mj_UpdatedAt];
GO

/* SQL text to insert 11 new entity field(s) */

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '44b3ed10-b4b9-4243-b876-e469a3022240' OR (EntityID = '32C45078-D33B-4760-9BE5-0DF7F483F591' AND Name = 'ConsentStatus')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '44b3ed10-b4b9-4243-b876-e469a3022240',
            '32C45078-D33B-4760-9BE5-0DF7F483F591', -- Entity: MJ_BizApps_Common: Contact Methods
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '32C45078-D33B-4760-9BE5-0DF7F483F591'),
            'ConsentStatus',
            'Consent Status',
            'The current consent for contacting this email or phone: NotSpecified, OptedIn or OptedOut. Always equals NewConsentStatus on the ContactConsentHistory row with the latest ConsentStatusAt. Set it through ContactPreferenceEngine, which writes the history row with it.',
            'nvarchar',
            40,
            0,
            0,
            0,
            'NotSpecified',
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c220c610-a6f1-4281-b1ee-700430cde3c7' OR (EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND Name = 'CommunicationBaseMessageTypeID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'c220c610-a6f1-4281-b1ee-700430cde3c7',
            '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', -- Entity: MJ_BizApps_Common: Contact Types
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5'),
            'CommunicationBaseMessageTypeID',
            'Communication Base Message Type ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            1,
            NULL,
            0,
            1,
            0,
            0,
            '47248F34-2837-EF11-86D4-6045BDEE16E6',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '5e24a8ad-13f3-4a91-8154-e367b16e2ef9' OR (EntityID = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9' AND Name = 'ID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '5e24a8ad-13f3-4a91-8154-e367b16e2ef9',
            'B99C00A2-C42A-4E20-B23E-D8C88E2602D9', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9'),
            'ID',
            'ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            'newsequentialid()',
            0,
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            1,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '010e9817-cdb7-4495-acd4-929d045b0408' OR (EntityID = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9' AND Name = 'ContactMethodID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '010e9817-cdb7-4495-acd4-929d045b0408',
            'B99C00A2-C42A-4E20-B23E-D8C88E2602D9', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9'),
            'ContactMethodID',
            'Contact Method ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            NULL,
            0,
            1,
            0,
            0,
            '32C45078-D33B-4760-9BE5-0DF7F483F591',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f9f2c365-8397-44e8-8f7a-f3f770d64803' OR (EntityID = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9' AND Name = 'NewConsentStatus')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'f9f2c365-8397-44e8-8f7a-f3f770d64803',
            'B99C00A2-C42A-4E20-B23E-D8C88E2602D9', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9'),
            'NewConsentStatus',
            'New Consent Status',
            'The consent status this change set: NotSpecified, OptedIn or OptedOut.',
            'nvarchar',
            40,
            0,
            0,
            0,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            1,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'de90a625-e247-4890-bea2-949b6312c233' OR (EntityID = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9' AND Name = 'ConsentStatusAt')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'de90a625-e247-4890-bea2-949b6312c233',
            'B99C00A2-C42A-4E20-B23E-D8C88E2602D9', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9'),
            'ConsentStatusAt',
            'Consent Status At',
            'When the change took effect in the real world (the unsubscribe click, the form submission, the import''s own date), not when this row was saved. The row with the latest value is the current status.',
            'datetimeoffset',
            10,
            34,
            7,
            0,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            1,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'ff88a9de-2d26-4ebf-988a-2fe21abb8436' OR (EntityID = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9' AND Name = 'ConsentSource')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'ff88a9de-2d26-4ebf-988a-2fe21abb8436',
            'B99C00A2-C42A-4E20-B23E-D8C88E2602D9', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9'),
            'ConsentSource',
            'Consent Source',
            'Where the change came from, for example "Web signup", "Unsubscribe link", "Import: Tessitura" or "Staff".',
            'nvarchar',
            400,
            0,
            0,
            0,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            1,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'b9b7b9a9-e829-4205-85cb-5930cf13762d' OR (EntityID = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9' AND Name = 'RecordedByUserID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'b9b7b9a9-e829-4205-85cb-5930cf13762d',
            'B99C00A2-C42A-4E20-B23E-D8C88E2602D9', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9'),
            'RecordedByUserID',
            'Recorded By User ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            1,
            NULL,
            0,
            1,
            0,
            0,
            'E1238F34-2837-EF11-86D4-6045BDEE16E6',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'ec820c79-0bec-4f9d-8270-6c2d54f8ecf8' OR (EntityID = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9' AND Name = 'Notes')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'ec820c79-0bec-4f9d-8270-6c2d54f8ecf8',
            'B99C00A2-C42A-4E20-B23E-D8C88E2602D9', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9'),
            'Notes',
            'Notes',
            'Evidence for the change, such as a form ID or the unsubscribe email''s message ID.',
            'nvarchar',
            -1,
            0,
            0,
            1,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '5a530def-1a07-4c56-a2e6-9f6f746188fb' OR (EntityID = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9' AND Name = '__mj_CreatedAt')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '5a530def-1a07-4c56-a2e6-9f6f746188fb',
            'B99C00A2-C42A-4E20-B23E-D8C88E2602D9', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9'),
            '__mj_CreatedAt',
            'Created At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '3c49ea7c-0336-4a56-836e-68271584bada' OR (EntityID = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9' AND Name = '__mj_UpdatedAt')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '3c49ea7c-0336-4a56-836e-68271584bada',
            'B99C00A2-C42A-4E20-B23E-D8C88E2602D9', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9'),
            '__mj_UpdatedAt',
            'Updated At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

/* SQL text to insert entity field value with ID 3eaca132-4061-43c7-817a-5954af97b94c */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('3eaca132-4061-43c7-817a-5954af97b94c', '44B3ED10-B4B9-4243-B876-E469A3022240', 1, 'NotSpecified', 'NotSpecified', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 6bf59906-f00a-457b-b6ff-d8c51f86c2a4 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('6bf59906-f00a-457b-b6ff-d8c51f86c2a4', '44B3ED10-B4B9-4243-B876-E469A3022240', 2, 'OptedIn', 'OptedIn', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 2db43a79-1a67-4966-b117-9b2b29b38646 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('2db43a79-1a67-4966-b117-9b2b29b38646', '44B3ED10-B4B9-4243-B876-E469A3022240', 3, 'OptedOut', 'OptedOut', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 44B3ED10-B4B9-4243-B876-E469A3022240 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='44B3ED10-B4B9-4243-B876-E469A3022240';

/* SQL text to insert entity field value with ID e10a28a9-0a07-4f0d-aeac-1c81b2496226 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('e10a28a9-0a07-4f0d-aeac-1c81b2496226', 'F9F2C365-8397-44E8-8F7A-F3F770D64803', 1, 'NotSpecified', 'NotSpecified', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 4d2dc35b-32b9-4c8a-91da-e40393ae2465 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('4d2dc35b-32b9-4c8a-91da-e40393ae2465', 'F9F2C365-8397-44E8-8F7A-F3F770D64803', 2, 'OptedIn', 'OptedIn', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 466bb2ea-2695-4234-8a3b-5e9aa79e610f */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('466bb2ea-2695-4234-8a3b-5e9aa79e610f', 'F9F2C365-8397-44E8-8F7A-F3F770D64803', 3, 'OptedOut', 'OptedOut', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID F9F2C365-8397-44E8-8F7A-F3F770D64803 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='F9F2C365-8397-44E8-8F7A-F3F770D64803';

/* Deterministic search-flag hygiene — clear AllowUserSearchAPI */

         UPDATE [${mjSchema}].[Entity]
         SET [AllowUserSearchAPI] = 0
         WHERE [ID] IN (
            SELECT e.[ID]
            FROM [${mjSchema}].[Entity] e
            WHERE e.[AllowUserSearchAPI] = 1
              AND e.[AutoUpdateAllowUserSearchAPI] = 1
              AND e.[VirtualEntity] = 0
              AND ISNULL(e.[FullTextSearchEnabled], 0) = 0
              AND e.[SchemaName] NOT IN ('${mjSchema}','sys')
              AND NOT EXISTS (
               SELECT 1 FROM [${mjSchema}].[EntityField] f2
               WHERE f2.[EntityID] = e.[ID]
                 AND f2.[IncludeInUserSearchAPI] = 1
            )
         );


/* Create Entity Relationship: MJ_BizApps_Common: Contact Methods -> MJ_BizApps_Common: Contact Consent Histories (One To Many via ContactMethodID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'c95802c2-4c91-4f6d-b656-909414577224'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('c95802c2-4c91-4f6d-b656-909414577224', '32C45078-D33B-4760-9BE5-0DF7F483F591', 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9', 'ContactMethodID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ: Users -> MJ_BizApps_Common: Contact Consent Histories (One To Many via RecordedByUserID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'df879cec-91f9-4657-8d33-eb6e1d111cdb'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('df879cec-91f9-4657-8d33-eb6e1d111cdb', 'E1238F34-2837-EF11-86D4-6045BDEE16E6', 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9', 'RecordedByUserID', 'One To Many', 1, 1, 124, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ: Communication Base Message Types -> MJ_BizApps_Common: Contact Types (One To Many via CommunicationBaseMessageTypeID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'd5be70ed-fdae-4396-8884-89e39181592d'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('d5be70ed-fdae-4396-8884-89e39181592d', '47248F34-2837-EF11-86D4-6045BDEE16E6', '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', 'CommunicationBaseMessageTypeID', 'One To Many', 1, 1, 3, GETUTCDATE(), GETUTCDATE())
   END;

/* spCreate SQL for MJ_BizApps_Common: Activity Sync Run Details */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Run Details
-- Item: spCreateActivitySyncRunDetail
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ActivitySyncRunDetail
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateActivitySyncRunDetail]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncRunDetail];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncRunDetail]
    @ID uniqueidentifier = NULL,
    @ActivitySyncRunID uniqueidentifier,
    @ExternalID nvarchar(400),
    @ExternalThreadID_Clear bit = 0,
    @ExternalThreadID nvarchar(400) = NULL,
    @OccurredAt_Clear bit = 0,
    @OccurredAt datetimeoffset = NULL,
    @Decision nvarchar(20),
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
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncRunDetail]
            (
                [ID],
                [ActivitySyncRunID],
                [ExternalID],
                [ExternalThreadID],
                [OccurredAt],
                [Decision],
                [DecidedByStage],
                [ActivitySyncRuleID],
                [ActivitySyncExclusionID],
                [Reason],
                [Confidence],
                [AIPromptRunID],
                [ActivityID],
                [CapturedContent],
                [EncryptionKeyID]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @ActivitySyncRunID,
                @ExternalID,
                CASE WHEN @ExternalThreadID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalThreadID, NULL) END,
                CASE WHEN @OccurredAt_Clear = 1 THEN NULL ELSE ISNULL(@OccurredAt, NULL) END,
                @Decision,
                CASE WHEN @DecidedByStage_Clear = 1 THEN NULL ELSE ISNULL(@DecidedByStage, NULL) END,
                CASE WHEN @ActivitySyncRuleID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncRuleID, NULL) END,
                CASE WHEN @ActivitySyncExclusionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncExclusionID, NULL) END,
                CASE WHEN @Reason_Clear = 1 THEN NULL ELSE ISNULL(@Reason, NULL) END,
                CASE WHEN @Confidence_Clear = 1 THEN NULL ELSE ISNULL(@Confidence, NULL) END,
                CASE WHEN @AIPromptRunID_Clear = 1 THEN NULL ELSE ISNULL(@AIPromptRunID, NULL) END,
                CASE WHEN @ActivityID_Clear = 1 THEN NULL ELSE ISNULL(@ActivityID, NULL) END,
                CASE WHEN @CapturedContent_Clear = 1 THEN NULL ELSE ISNULL(@CapturedContent, NULL) END,
                CASE WHEN @EncryptionKeyID_Clear = 1 THEN NULL ELSE ISNULL(@EncryptionKeyID, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncRunDetail]
            (
                [ActivitySyncRunID],
                [ExternalID],
                [ExternalThreadID],
                [OccurredAt],
                [Decision],
                [DecidedByStage],
                [ActivitySyncRuleID],
                [ActivitySyncExclusionID],
                [Reason],
                [Confidence],
                [AIPromptRunID],
                [ActivityID],
                [CapturedContent],
                [EncryptionKeyID]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ActivitySyncRunID,
                @ExternalID,
                CASE WHEN @ExternalThreadID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalThreadID, NULL) END,
                CASE WHEN @OccurredAt_Clear = 1 THEN NULL ELSE ISNULL(@OccurredAt, NULL) END,
                @Decision,
                CASE WHEN @DecidedByStage_Clear = 1 THEN NULL ELSE ISNULL(@DecidedByStage, NULL) END,
                CASE WHEN @ActivitySyncRuleID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncRuleID, NULL) END,
                CASE WHEN @ActivitySyncExclusionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncExclusionID, NULL) END,
                CASE WHEN @Reason_Clear = 1 THEN NULL ELSE ISNULL(@Reason, NULL) END,
                CASE WHEN @Confidence_Clear = 1 THEN NULL ELSE ISNULL(@Confidence, NULL) END,
                CASE WHEN @AIPromptRunID_Clear = 1 THEN NULL ELSE ISNULL(@AIPromptRunID, NULL) END,
                CASE WHEN @ActivityID_Clear = 1 THEN NULL ELSE ISNULL(@ActivityID, NULL) END,
                CASE WHEN @CapturedContent_Clear = 1 THEN NULL ELSE ISNULL(@CapturedContent, NULL) END,
                CASE WHEN @EncryptionKeyID_Clear = 1 THEN NULL ELSE ISNULL(@EncryptionKeyID, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwActivitySyncRunDetails] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRunDetail] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRunDetail] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRunDetail] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Activity Sync Run Details */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRunDetail] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRunDetail] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRunDetail] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Activity Sync Run Details */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Run Details
-- Item: spUpdateActivitySyncRunDetail
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

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
        [EncryptionKeyID] = CASE WHEN @EncryptionKeyID_Clear = 1 THEN NULL ELSE ISNULL(@EncryptionKeyID, [EncryptionKeyID]) END
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

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRunDetail] FROM [cdp_Developer]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRunDetail] TO [cdp_Developer]
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
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncRunDetail]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ActivitySyncRunDetail] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Activity Sync Run Details */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRunDetail] FROM [cdp_Developer]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRunDetail] TO [cdp_Developer];

/* spCreate SQL for MJ_BizApps_Common: Activity Sync Runs */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Runs
-- Item: spCreateActivitySyncRun
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ActivitySyncRun
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateActivitySyncRun]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncRun];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncRun]
    @ID uniqueidentifier = NULL,
    @ActivitySyncConnectionID uniqueidentifier,
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
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncRun]
            (
                [ID],
                [ActivitySyncConnectionID],
                [StartedAt],
                [EndedAt],
                [Status],
                [TriggerType],
                [IsDryRun],
                [Fetched],
                [Included],
                [Excluded],
                [Duplicates],
                [Failed],
                [ExtensionErrors],
                [WatermarkBefore],
                [WatermarkAfter],
                [ErrorMessage]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @ActivitySyncConnectionID,
                ISNULL(@StartedAt, sysdatetimeoffset()),
                CASE WHEN @EndedAt_Clear = 1 THEN NULL ELSE ISNULL(@EndedAt, NULL) END,
                ISNULL(@Status, 'Running'),
                ISNULL(@TriggerType, 'Scheduled'),
                ISNULL(@IsDryRun, 0),
                ISNULL(@Fetched, 0),
                ISNULL(@Included, 0),
                ISNULL(@Excluded, 0),
                ISNULL(@Duplicates, 0),
                ISNULL(@Failed, 0),
                ISNULL(@ExtensionErrors, 0),
                CASE WHEN @WatermarkBefore_Clear = 1 THEN NULL ELSE ISNULL(@WatermarkBefore, NULL) END,
                CASE WHEN @WatermarkAfter_Clear = 1 THEN NULL ELSE ISNULL(@WatermarkAfter, NULL) END,
                CASE WHEN @ErrorMessage_Clear = 1 THEN NULL ELSE ISNULL(@ErrorMessage, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncRun]
            (
                [ActivitySyncConnectionID],
                [StartedAt],
                [EndedAt],
                [Status],
                [TriggerType],
                [IsDryRun],
                [Fetched],
                [Included],
                [Excluded],
                [Duplicates],
                [Failed],
                [ExtensionErrors],
                [WatermarkBefore],
                [WatermarkAfter],
                [ErrorMessage]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ActivitySyncConnectionID,
                ISNULL(@StartedAt, sysdatetimeoffset()),
                CASE WHEN @EndedAt_Clear = 1 THEN NULL ELSE ISNULL(@EndedAt, NULL) END,
                ISNULL(@Status, 'Running'),
                ISNULL(@TriggerType, 'Scheduled'),
                ISNULL(@IsDryRun, 0),
                ISNULL(@Fetched, 0),
                ISNULL(@Included, 0),
                ISNULL(@Excluded, 0),
                ISNULL(@Duplicates, 0),
                ISNULL(@Failed, 0),
                ISNULL(@ExtensionErrors, 0),
                CASE WHEN @WatermarkBefore_Clear = 1 THEN NULL ELSE ISNULL(@WatermarkBefore, NULL) END,
                CASE WHEN @WatermarkAfter_Clear = 1 THEN NULL ELSE ISNULL(@WatermarkAfter, NULL) END,
                CASE WHEN @ErrorMessage_Clear = 1 THEN NULL ELSE ISNULL(@ErrorMessage, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwActivitySyncRuns] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRun] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRun] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRun] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Activity Sync Runs */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRun] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRun] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRun] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Activity Sync Runs */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Runs
-- Item: spUpdateActivitySyncRun
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

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
        [ErrorMessage] = CASE WHEN @ErrorMessage_Clear = 1 THEN NULL ELSE ISNULL(@ErrorMessage, [ErrorMessage]) END
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

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRun] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRun] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRun] TO [cdp_Developer], [cdp_Integration]
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
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncRun]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ActivitySyncRun] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Activity Sync Runs */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRun] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRun] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRun] TO [cdp_Developer], [cdp_Integration];

/* Index for Foreign Keys for ContactConsentHistory */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Consent Histories
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key ContactMethodID in table ContactConsentHistory
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactConsentHistory_ContactMethodID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ContactConsentHistory]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactConsentHistory_ContactMethodID ON [${flyway:defaultSchema}].[ContactConsentHistory] ([ContactMethodID]);

-- Index for foreign key RecordedByUserID in table ContactConsentHistory
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactConsentHistory_RecordedByUserID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ContactConsentHistory]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactConsentHistory_RecordedByUserID ON [${flyway:defaultSchema}].[ContactConsentHistory] ([RecordedByUserID]);

/* SQL text to update entity field related entity name field map for entity field ID 010E9817-CDB7-4495-ACD4-929D045B0408 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='010E9817-CDB7-4495-ACD4-929D045B0408', @RelatedEntityNameFieldMap='ContactMethod';

/* Index for Foreign Keys for ContactMethod */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key PersonID in table ContactMethod
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactMethod_PersonID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ContactMethod]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactMethod_PersonID ON [${flyway:defaultSchema}].[ContactMethod] ([PersonID]);

-- Index for foreign key OrganizationID in table ContactMethod
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactMethod_OrganizationID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ContactMethod]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactMethod_OrganizationID ON [${flyway:defaultSchema}].[ContactMethod] ([OrganizationID]);

-- Index for foreign key ContactTypeID in table ContactMethod
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactMethod_ContactTypeID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ContactMethod]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactMethod_ContactTypeID ON [${flyway:defaultSchema}].[ContactMethod] ([ContactTypeID]);

/* Index for Foreign Keys for ContactType */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Types
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key CommunicationBaseMessageTypeID in table ContactType
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactType_CommunicationBaseMessageTypeID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ContactType]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactType_CommunicationBaseMessageTypeID ON [${flyway:defaultSchema}].[ContactType] ([CommunicationBaseMessageTypeID]);

/* SQL text to update entity field related entity name field map for entity field ID C220C610-A6F1-4281-B1EE-700430CDE3C7 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='C220C610-A6F1-4281-B1EE-700430CDE3C7', @RelatedEntityNameFieldMap='CommunicationBaseMessageType';

/* Base View SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: vwContactMethods
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Contact Methods
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ContactMethod
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwContactMethods]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwContactMethods];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwContactMethods]
AS
SELECT
    c.*,
    mjBizAppsCommonPerson_PersonID.[DisplayName] AS [Person],
    mjBizAppsCommonOrganization_OrganizationID.[Name] AS [Organization],
    mjBizAppsCommonContactType_ContactTypeID.[Name] AS [ContactType]
FROM
    [${flyway:defaultSchema}].[ContactMethod] AS c
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Person] AS mjBizAppsCommonPerson_PersonID
  ON
    [c].[PersonID] = mjBizAppsCommonPerson_PersonID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Organization] AS mjBizAppsCommonOrganization_OrganizationID
  ON
    [c].[OrganizationID] = mjBizAppsCommonOrganization_OrganizationID.[ID]
INNER JOIN
    [${flyway:defaultSchema}].[ContactType] AS mjBizAppsCommonContactType_ContactTypeID
  ON
    [c].[ContactTypeID] = mjBizAppsCommonContactType_ContactTypeID.[ID]
GO
REVOKE SELECT ON [${flyway:defaultSchema}].[vwContactMethods] FROM [cdp_Developer]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwContactMethods] FROM [cdp_Integration]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwContactMethods] FROM [cdp_UI]
GRANT SELECT ON [${flyway:defaultSchema}].[vwContactMethods] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: Permissions for vwContactMethods
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

REVOKE SELECT ON [${flyway:defaultSchema}].[vwContactMethods] FROM [cdp_Developer]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwContactMethods] FROM [cdp_Integration]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwContactMethods] FROM [cdp_UI]
GRANT SELECT ON [${flyway:defaultSchema}].[vwContactMethods] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: spCreateContactMethod
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ContactMethod
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateContactMethod]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateContactMethod];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateContactMethod]
    @ID uniqueidentifier = NULL,
    @PersonID_Clear bit = 0,
    @PersonID uniqueidentifier = NULL,
    @OrganizationID_Clear bit = 0,
    @OrganizationID uniqueidentifier = NULL,
    @ContactTypeID uniqueidentifier,
    @Value nvarchar(500),
    @Label_Clear bit = 0,
    @Label nvarchar(100) = NULL,
    @IsPrimary bit = NULL,
    @ConsentStatus nvarchar(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ContactMethod]
            (
                [ID],
                [PersonID],
                [OrganizationID],
                [ContactTypeID],
                [Value],
                [Label],
                [IsPrimary],
                [ConsentStatus]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                CASE WHEN @PersonID_Clear = 1 THEN NULL ELSE ISNULL(@PersonID, NULL) END,
                CASE WHEN @OrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationID, NULL) END,
                @ContactTypeID,
                @Value,
                CASE WHEN @Label_Clear = 1 THEN NULL ELSE ISNULL(@Label, NULL) END,
                ISNULL(@IsPrimary, 0),
                ISNULL(@ConsentStatus, 'NotSpecified')
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ContactMethod]
            (
                [PersonID],
                [OrganizationID],
                [ContactTypeID],
                [Value],
                [Label],
                [IsPrimary],
                [ConsentStatus]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                CASE WHEN @PersonID_Clear = 1 THEN NULL ELSE ISNULL(@PersonID, NULL) END,
                CASE WHEN @OrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationID, NULL) END,
                @ContactTypeID,
                @Value,
                CASE WHEN @Label_Clear = 1 THEN NULL ELSE ISNULL(@Label, NULL) END,
                ISNULL(@IsPrimary, 0),
                ISNULL(@ConsentStatus, 'NotSpecified')
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwContactMethods] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateContactMethod] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateContactMethod] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateContactMethod] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Contact Methods */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateContactMethod] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateContactMethod] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateContactMethod] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: spUpdateContactMethod
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

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
    @IsPrimary bit = NULL,
    @ConsentStatus nvarchar(20) = NULL
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
        [ConsentStatus] = ISNULL(@ConsentStatus, [ConsentStatus])
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

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactMethod] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactMethod] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactMethod] TO [cdp_Developer], [cdp_Integration]
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
    UPDATE
        [${flyway:defaultSchema}].[ContactMethod]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ContactMethod] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Contact Methods */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactMethod] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactMethod] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactMethod] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: spDeleteContactMethod
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ContactMethod
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteContactMethod]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteContactMethod];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteContactMethod]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ContactMethod]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spDeleteContactMethod] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteContactMethod] TO [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Contact Methods */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spDeleteContactMethod] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteContactMethod] TO [cdp_Integration];

/* SQL text to update entity field related entity name field map for entity field ID B9B7B9A9-E829-4205-85CB-5930CF13762D */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='B9B7B9A9-E829-4205-85CB-5930CF13762D', @RelatedEntityNameFieldMap='RecordedByUser';

/* Base View SQL for MJ_BizApps_Common: Contact Consent Histories */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Consent Histories
-- Item: vwContactConsentHistories
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Contact Consent Histories
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ContactConsentHistory
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwContactConsentHistories]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwContactConsentHistories];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwContactConsentHistories]
AS
SELECT
    c.*,
    mjBizAppsCommonContactMethod_ContactMethodID.[Value] AS [ContactMethod],
    MJUser_RecordedByUserID.[Name] AS [RecordedByUser]
FROM
    [${flyway:defaultSchema}].[ContactConsentHistory] AS c
INNER JOIN
    [${flyway:defaultSchema}].[ContactMethod] AS mjBizAppsCommonContactMethod_ContactMethodID
  ON
    [c].[ContactMethodID] = mjBizAppsCommonContactMethod_ContactMethodID.[ID]
LEFT OUTER JOIN
    [${mjSchema}].[User] AS MJUser_RecordedByUserID
  ON
    [c].[RecordedByUserID] = MJUser_RecordedByUserID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwContactConsentHistories] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Contact Consent Histories */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Consent Histories
-- Item: Permissions for vwContactConsentHistories
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwContactConsentHistories] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Contact Consent Histories */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Consent Histories
-- Item: spCreateContactConsentHistory
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ContactConsentHistory
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateContactConsentHistory]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateContactConsentHistory];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateContactConsentHistory]
    @ID uniqueidentifier = NULL,
    @ContactMethodID uniqueidentifier,
    @NewConsentStatus nvarchar(20),
    @ConsentStatusAt datetimeoffset,
    @ConsentSource nvarchar(200),
    @RecordedByUserID_Clear bit = 0,
    @RecordedByUserID uniqueidentifier = NULL,
    @Notes_Clear bit = 0,
    @Notes nvarchar(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ContactConsentHistory]
            (
                [ID],
                [ContactMethodID],
                [NewConsentStatus],
                [ConsentStatusAt],
                [ConsentSource],
                [RecordedByUserID],
                [Notes]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @ContactMethodID,
                @NewConsentStatus,
                @ConsentStatusAt,
                @ConsentSource,
                CASE WHEN @RecordedByUserID_Clear = 1 THEN NULL ELSE ISNULL(@RecordedByUserID, NULL) END,
                CASE WHEN @Notes_Clear = 1 THEN NULL ELSE ISNULL(@Notes, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ContactConsentHistory]
            (
                [ContactMethodID],
                [NewConsentStatus],
                [ConsentStatusAt],
                [ConsentSource],
                [RecordedByUserID],
                [Notes]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ContactMethodID,
                @NewConsentStatus,
                @ConsentStatusAt,
                @ConsentSource,
                CASE WHEN @RecordedByUserID_Clear = 1 THEN NULL ELSE ISNULL(@RecordedByUserID, NULL) END,
                CASE WHEN @Notes_Clear = 1 THEN NULL ELSE ISNULL(@Notes, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwContactConsentHistories] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateContactConsentHistory] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Contact Consent Histories */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateContactConsentHistory] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Contact Consent Histories */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Consent Histories
-- Item: spUpdateContactConsentHistory
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ContactConsentHistory
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateContactConsentHistory]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateContactConsentHistory];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateContactConsentHistory]
    @ID uniqueidentifier,
    @ContactMethodID uniqueidentifier = NULL,
    @NewConsentStatus nvarchar(20) = NULL,
    @ConsentStatusAt datetimeoffset = NULL,
    @ConsentSource nvarchar(200) = NULL,
    @RecordedByUserID_Clear bit = 0,
    @RecordedByUserID uniqueidentifier = NULL,
    @Notes_Clear bit = 0,
    @Notes nvarchar(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ContactConsentHistory]
    SET
        [ContactMethodID] = ISNULL(@ContactMethodID, [ContactMethodID]),
        [NewConsentStatus] = ISNULL(@NewConsentStatus, [NewConsentStatus]),
        [ConsentStatusAt] = ISNULL(@ConsentStatusAt, [ConsentStatusAt]),
        [ConsentSource] = ISNULL(@ConsentSource, [ConsentSource]),
        [RecordedByUserID] = CASE WHEN @RecordedByUserID_Clear = 1 THEN NULL ELSE ISNULL(@RecordedByUserID, [RecordedByUserID]) END,
        [Notes] = CASE WHEN @Notes_Clear = 1 THEN NULL ELSE ISNULL(@Notes, [Notes]) END
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwContactConsentHistories] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwContactConsentHistories]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactConsentHistory] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ContactConsentHistory table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateContactConsentHistory]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateContactConsentHistory];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateContactConsentHistory
ON [${flyway:defaultSchema}].[ContactConsentHistory]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ContactConsentHistory]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ContactConsentHistory] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Contact Consent Histories */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactConsentHistory] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Contact Consent Histories */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Consent Histories
-- Item: spDeleteContactConsentHistory
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ContactConsentHistory
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteContactConsentHistory]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteContactConsentHistory];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteContactConsentHistory]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ContactConsentHistory]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteContactConsentHistory] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Contact Consent Histories */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteContactConsentHistory] TO [cdp_Developer], [cdp_Integration];

/* Base View SQL for MJ_BizApps_Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Types
-- Item: vwContactTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Contact Types
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ContactType
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwContactTypes]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwContactTypes];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwContactTypes]
AS
SELECT
    c.*,
    MJCommunicationBaseMessageType_CommunicationBaseMessageTypeID.[Type] AS [CommunicationBaseMessageType]
FROM
    [${flyway:defaultSchema}].[ContactType] AS c
LEFT OUTER JOIN
    [${mjSchema}].[CommunicationBaseMessageType] AS MJCommunicationBaseMessageType_CommunicationBaseMessageTypeID
  ON
    [c].[CommunicationBaseMessageTypeID] = MJCommunicationBaseMessageType_CommunicationBaseMessageTypeID.[ID]
GO
REVOKE SELECT ON [${flyway:defaultSchema}].[vwContactTypes] FROM [cdp_Developer]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwContactTypes] FROM [cdp_Integration]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwContactTypes] FROM [cdp_UI]
GRANT SELECT ON [${flyway:defaultSchema}].[vwContactTypes] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Types
-- Item: Permissions for vwContactTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

REVOKE SELECT ON [${flyway:defaultSchema}].[vwContactTypes] FROM [cdp_Developer]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwContactTypes] FROM [cdp_Integration]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwContactTypes] FROM [cdp_UI]
GRANT SELECT ON [${flyway:defaultSchema}].[vwContactTypes] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Types
-- Item: spCreateContactType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ContactType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateContactType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateContactType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateContactType]
    @ID uniqueidentifier = NULL,
    @Name nvarchar(100),
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
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ContactType]
            (
                [ID],
                [Name],
                [Description],
                [IconClass],
                [DisplayRank],
                [IsActive],
                [CommunicationBaseMessageTypeID]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                CASE WHEN @IconClass_Clear = 1 THEN NULL ELSE ISNULL(@IconClass, NULL) END,
                ISNULL(@DisplayRank, 100),
                ISNULL(@IsActive, 1),
                CASE WHEN @CommunicationBaseMessageTypeID_Clear = 1 THEN NULL ELSE ISNULL(@CommunicationBaseMessageTypeID, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ContactType]
            (
                [Name],
                [Description],
                [IconClass],
                [DisplayRank],
                [IsActive],
                [CommunicationBaseMessageTypeID]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                CASE WHEN @IconClass_Clear = 1 THEN NULL ELSE ISNULL(@IconClass, NULL) END,
                ISNULL(@DisplayRank, 100),
                ISNULL(@IsActive, 1),
                CASE WHEN @CommunicationBaseMessageTypeID_Clear = 1 THEN NULL ELSE ISNULL(@CommunicationBaseMessageTypeID, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwContactTypes] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateContactType] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateContactType] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateContactType] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Contact Types */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateContactType] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spCreateContactType] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateContactType] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Types
-- Item: spUpdateContactType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

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
        [CommunicationBaseMessageTypeID] = CASE WHEN @CommunicationBaseMessageTypeID_Clear = 1 THEN NULL ELSE ISNULL(@CommunicationBaseMessageTypeID, [CommunicationBaseMessageTypeID]) END
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

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactType] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactType] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactType] TO [cdp_Developer], [cdp_Integration]
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
    UPDATE
        [${flyway:defaultSchema}].[ContactType]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ContactType] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Contact Types */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactType] FROM [cdp_Developer]
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactType] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactType] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Types
-- Item: spDeleteContactType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ContactType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteContactType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteContactType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteContactType]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ContactType]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
REVOKE EXECUTE ON [${flyway:defaultSchema}].[spDeleteContactType] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteContactType] TO [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Contact Types */

REVOKE EXECUTE ON [${flyway:defaultSchema}].[spDeleteContactType] FROM [cdp_Integration]
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteContactType] TO [cdp_Integration];

/* SQL text to insert 3 new entity field(s) */

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c3081eb8-5d29-4470-bb27-41b006dc4b2e' OR (EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND Name = 'CommunicationBaseMessageType')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'c3081eb8-5d29-4470-bb27-41b006dc4b2e',
            '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', -- Entity: MJ_BizApps_Common: Contact Types
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5'),
            'CommunicationBaseMessageType',
            'Communication Base Message Type',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            1,
            NULL,
            0,
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '3f72a2b0-69c9-4b67-a4d1-0ada2e4c3d9e' OR (EntityID = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9' AND Name = 'ContactMethod')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '3f72a2b0-69c9-4b67-a4d1-0ada2e4c3d9e',
            'B99C00A2-C42A-4E20-B23E-D8C88E2602D9', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9'),
            'ContactMethod',
            'Contact Method',
            NULL,
            'nvarchar',
            1000,
            0,
            0,
            0,
            NULL,
            0,
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '9c593043-8d5e-49de-bbb8-ee00e01fe86e' OR (EntityID = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9' AND Name = 'RecordedByUser')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '9c593043-8d5e-49de-bbb8-ee00e01fe86e',
            'B99C00A2-C42A-4E20-B23E-D8C88E2602D9', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9'),
            'RecordedByUser',
            'Recorded By User',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            1,
            NULL,
            0,
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '44B3ED10-B4B9-4243-B876-E469A3022240'
               AND AutoUpdateDefaultInView = 1;

/* Set categories for 2 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Types.CommunicationBaseMessageTypeID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category',
   DisplayName = 'Communication Base Message Type'
WHERE 
   ID = 'C220C610-A6F1-4281-B1EE-700430CDE3C7';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Types.CommunicationBaseMessageType 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'C3081EB8-5D29-4470-BB27-41B006DC4B2E';

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET IsNameField = 1
               WHERE ID = 'F9F2C365-8397-44E8-8F7A-F3F770D64803'
               AND AutoUpdateIsNameField = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '3F72A2B0-69C9-4B67-A4D1-0ADA2E4C3D9E'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '9C593043-8D5E-49DE-BBB8-EE00E01FE86E'
               AND AutoUpdateDefaultInView = 1;

/* Set categories for 1 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Methods.ConsentStatus 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Contact Information',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '44B3ED10-B4B9-4243-B876-E469A3022240';

/* Set categories for 11 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '5E24A8AD-13F3-4A91-8154-E367B16E2EF9';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.ContactMethodID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '010E9817-CDB7-4495-ACD4-929D045B0408';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.ContactMethod 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '3F72A2B0-69C9-4B67-A4D1-0ADA2E4C3D9E';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.NewConsentStatus 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'F9F2C365-8397-44E8-8F7A-F3F770D64803';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.ConsentStatusAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'DE90A625-E247-4890-BEA2-949B6312C233';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.ConsentSource 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'FF88A9DE-2D26-4EBF-988A-2FE21ABB8436';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.RecordedByUserID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Audit and Notes',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'B9B7B9A9-E829-4205-85CB-5930CF13762D';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.RecordedByUser 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Audit and Notes',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '9C593043-8D5E-49DE-BBB8-EE00E01FE86E';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.Notes 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Audit and Notes',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'EC820C79-0BEC-4F9D-8270-6C2D54F8ECF8';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '5A530DEF-1A07-4C56-A2E6-9F6F746188FB';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '3C49EA7C-0336-4A56-836E-68271584BADA';

/* Set entity icon to fa fa-history */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-history', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9';

/* Insert FieldCategoryInfo setting for entity */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9' AND [Name] = 'FieldCategoryInfo'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('44b790c2-35c9-5396-b821-c449a49899aa', 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9', 'FieldCategoryInfo', '{
  "Audit and Notes": {
    "description": "Information on who recorded the change and any supporting notes",
    "icon": "fa fa-clipboard-list"
  },
  "Consent Details": {
    "description": "Details regarding the consent status change, timestamps, and source",
    "icon": "fa fa-shield-alt"
  },
  "System Metadata": {
    "description": "System-managed audit and tracking fields",
    "icon": "fa fa-cog"
  }
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Insert FieldCategoryIcons setting (legacy) */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9' AND [Name] = 'FieldCategoryIcons'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('3ae05704-e920-5b02-bb11-52b9ec2cc1a4', 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9', 'FieldCategoryIcons', '{
  "Audit and Notes": "fa fa-clipboard-list",
  "Consent Details": "fa fa-shield-alt",
  "System Metadata": "fa fa-cog"
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Set DefaultForNewUser=false for NEW entity (category: supporting, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = 'B99C00A2-C42A-4E20-B23E-D8C88E2602D9';

