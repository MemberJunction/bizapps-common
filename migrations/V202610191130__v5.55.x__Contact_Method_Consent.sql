-- =============================================================================
-- Migration: V202610191130__v5.55.x__Contact_Method_Consent.sql
-- Description: Consent per contact method, per purpose, optionally per organization
--              (plans/contact-consent.md)
--              - ConsentPurpose: what a consent is for (Marketing, Transactional, ...), a lookup
--                like ContactType so a customer adds purposes without DDL
--              - ContactConsent: one current status per contact method, (optional) purpose and
--                (optional) organization: a row with no purpose is the general answer for the
--                address, so one email can say yes in general, no to one purpose, no to one sender
--              - ContactConsentHistory: one row per change on a ContactConsent, with when it
--                took effect and where it came from
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
-- ConsentPurpose: what a consent is for
---------------------------------------------------------------------------
IF OBJECT_ID(N'[${flyway:defaultSchema}].[ConsentPurpose]', N'U') IS NULL
BEGIN
    CREATE TABLE [${flyway:defaultSchema}].[ConsentPurpose] (
        ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
        Name NVARCHAR(100) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        DisplayRank INT NOT NULL DEFAULT 100,
        IsActive BIT NOT NULL DEFAULT 1,
        CONSTRAINT PK_ConsentPurpose PRIMARY KEY (ID),
        CONSTRAINT UQ_ConsentPurpose_Name UNIQUE (Name)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description', N'SCHEMA', N'${flyway:defaultSchema}', N'TABLE', N'ConsentPurpose', NULL, NULL))
BEGIN
    EXEC sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'What a consent is for: Marketing, Transactional, Fundraising, and whatever else an installation needs. Consent is recorded per contact method and purpose, so one email can be opted in for transactional messages and opted out of marketing. Seeded by metadata; add rows rather than columns.',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE', @level1name = N'ConsentPurpose';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description', N'SCHEMA', N'${flyway:defaultSchema}', N'TABLE', N'ConsentPurpose', N'COLUMN', N'Name'))
BEGIN
    EXEC sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'Display name of the purpose, unique within the installation.',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE', @level1name = N'ConsentPurpose',
        @level2type = N'COLUMN', @level2name = N'Name';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description', N'SCHEMA', N'${flyway:defaultSchema}', N'TABLE', N'ConsentPurpose', N'COLUMN', N'Description'))
BEGIN
    EXEC sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'What kinds of messages this purpose covers.',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE', @level1name = N'ConsentPurpose',
        @level2type = N'COLUMN', @level2name = N'Description';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description', N'SCHEMA', N'${flyway:defaultSchema}', N'TABLE', N'ConsentPurpose', N'COLUMN', N'DisplayRank'))
BEGIN
    EXEC sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'Sort order in dropdown lists. Lower values appear first.',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE', @level1name = N'ConsentPurpose',
        @level2type = N'COLUMN', @level2name = N'DisplayRank';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description', N'SCHEMA', N'${flyway:defaultSchema}', N'TABLE', N'ConsentPurpose', N'COLUMN', N'IsActive'))
BEGIN
    EXEC sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'Whether this purpose is offered for new consents. Inactive purposes are hidden from dropdowns but preserved for existing records.',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE', @level1name = N'ConsentPurpose',
        @level2type = N'COLUMN', @level2name = N'IsActive';
END
GO

---------------------------------------------------------------------------
-- ContactConsent: the current status for one contact method, purpose and (optional) organization
---------------------------------------------------------------------------
IF OBJECT_ID(N'[${flyway:defaultSchema}].[ContactConsent]', N'U') IS NULL
BEGIN
    CREATE TABLE [${flyway:defaultSchema}].[ContactConsent] (
        ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
        ContactMethodID UNIQUEIDENTIFIER NOT NULL,
        ConsentPurposeID UNIQUEIDENTIFIER NULL,
        OrganizationID UNIQUEIDENTIFIER NULL,
        ConsentStatus NVARCHAR(20) NOT NULL DEFAULT N'NotSpecified',
        CONSTRAINT PK_ContactConsent PRIMARY KEY (ID),
        CONSTRAINT FK_ContactConsent_ContactMethod FOREIGN KEY (ContactMethodID)
            REFERENCES [${flyway:defaultSchema}].[ContactMethod](ID)
            ON DELETE CASCADE,
        CONSTRAINT FK_ContactConsent_ConsentPurpose FOREIGN KEY (ConsentPurposeID)
            REFERENCES [${flyway:defaultSchema}].[ConsentPurpose](ID),
        CONSTRAINT FK_ContactConsent_Organization FOREIGN KEY (OrganizationID)
            REFERENCES [${flyway:defaultSchema}].[Organization](ID),
        CONSTRAINT UQ_ContactConsent_Method_Purpose_Organization UNIQUE (ContactMethodID, ConsentPurposeID, OrganizationID),
        CONSTRAINT CK_ContactConsent_ConsentStatus CHECK (ConsentStatus IN (N'NotSpecified', N'OptedIn', N'OptedOut'))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description', N'SCHEMA', N'${flyway:defaultSchema}', N'TABLE', N'ContactConsent', NULL, NULL))
BEGIN
    EXEC sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'The current consent for one contact method (an email or phone): for one purpose or, when ConsentPurposeID is null, for anything; from one organization or, when OrganizationID is null, from the whole installation. A contact method has many of these, the way a person has many contact methods, and the most specific row answers: purpose and organization, then purpose, then organization, then the general row. ConsentStatus always equals NewConsentStatus on the ContactConsentHistory row with the latest ConsentStatusAt. Set it through ContactPreferenceEngine, which writes the history row with it. Deleting the contact method deletes its consents.',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE', @level1name = N'ContactConsent';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description', N'SCHEMA', N'${flyway:defaultSchema}', N'TABLE', N'ContactConsent', N'COLUMN', N'ConsentStatus'))
BEGIN
    EXEC sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'The current consent: NotSpecified, OptedIn or OptedOut.',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE', @level1name = N'ContactConsent',
        @level2type = N'COLUMN', @level2name = N'ConsentStatus';
END
GO

---------------------------------------------------------------------------
-- ContactConsentHistory: one row per change on a ContactConsent
---------------------------------------------------------------------------
IF OBJECT_ID(N'[${flyway:defaultSchema}].[ContactConsentHistory]', N'U') IS NULL
BEGIN
    CREATE TABLE [${flyway:defaultSchema}].[ContactConsentHistory] (
        ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
        ContactConsentID UNIQUEIDENTIFIER NOT NULL,
        NewConsentStatus NVARCHAR(20) NOT NULL,
        ConsentStatusAt DATETIMEOFFSET NOT NULL,
        ConsentSource NVARCHAR(200) NOT NULL,
        RecordedByUserID UNIQUEIDENTIFIER NULL,
        Notes NVARCHAR(MAX) NULL,
        CONSTRAINT PK_ContactConsentHistory PRIMARY KEY (ID),
        CONSTRAINT FK_ContactConsentHistory_ContactConsent FOREIGN KEY (ContactConsentID)
            REFERENCES [${flyway:defaultSchema}].[ContactConsent](ID)
            ON DELETE CASCADE,
        CONSTRAINT FK_ContactConsentHistory_RecordedByUser FOREIGN KEY (RecordedByUserID)
            REFERENCES [${mjSchema}].[User](ID),
        CONSTRAINT CK_ContactConsentHistory_NewConsentStatus CHECK (NewConsentStatus IN (N'NotSpecified', N'OptedIn', N'OptedOut'))
    );
END
GO

-- The "latest change for this consent" read, which every status resolution does.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ContactConsentHistory_ContactConsent_ConsentStatusAt' AND object_id = OBJECT_ID(N'[${flyway:defaultSchema}].[ContactConsentHistory]'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_ContactConsentHistory_ContactConsent_ConsentStatusAt
        ON [${flyway:defaultSchema}].[ContactConsentHistory] (ContactConsentID, ConsentStatusAt DESC);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description', N'SCHEMA', N'${flyway:defaultSchema}', N'TABLE', N'ContactConsentHistory', NULL, NULL))
BEGIN
    EXEC sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'One row per change on a ContactConsent: the status it set, when it took effect in the real world, and where it came from. ContactConsent.ConsentStatus mirrors the row with the latest ConsentStatusAt. A late-arriving change with an older date is kept here but does not change the current status. Deleting the consent deletes its history.',
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
        @value = N'Where the change came from, for example "Web signup", "Unsubscribe link", "Import: CRM" or "Staff".',
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
   Contains: the Consent Purposes, Contact Consents and Contact Consent Histories entities and
   their fields, the CommunicationBaseMessageTypeID field on Contact Types, value lists and
   relationships, FK indexes, the regenerated views, CRUD procs and permissions.
   Do NOT edit by hand. If the hand-written SQL above changes, re-run CodeGen and replace this
   whole section.
   Runs: one, after the hand-written DDL above.
   ============================================================================================ */

/* SQL generated to create new entity MJ_BizApps_Common: Consent Purposes */

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
         '7e461bc4-be9a-417f-a5e0-2b884dadd3f8',
         'MJ_BizApps_Common: Consent Purposes',
         'Consent Purposes',
         'What a consent is for: Marketing, Transactional, Fundraising, and whatever else an installation needs. Consent is recorded per contact method and purpose, so one email can be opted in for transactional messages and opted out of marketing. Seeded by metadata; add rows rather than columns.',
         NULL,
         'ConsentPurpose',
         'vwConsentPurposes',
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

/* SQL generated to add new entity MJ_BizApps_Common: Consent Purposes to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '7e461bc4-be9a-417f-a5e0-2b884dadd3f8', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Consent Purposes for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('7e461bc4-be9a-417f-a5e0-2b884dadd3f8' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('7e461bc4-be9a-417f-a5e0-2b884dadd3f8' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Consent Purposes for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('7e461bc4-be9a-417f-a5e0-2b884dadd3f8' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('7e461bc4-be9a-417f-a5e0-2b884dadd3f8' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Consent Purposes for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('7e461bc4-be9a-417f-a5e0-2b884dadd3f8' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('7e461bc4-be9a-417f-a5e0-2b884dadd3f8' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to create new entity MJ_BizApps_Common: Contact Consents */

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
         'd3ab1411-7e47-4ee7-9b1e-8b42dba35904',
         'MJ_BizApps_Common: Contact Consents',
         'Contact Consents',
         'The current consent for one contact method (an email or phone): for one purpose or, when ConsentPurposeID is null, for anything; from one organization or, when OrganizationID is null, from the whole installation. A contact method has many of these, the way a person has many contact methods, and the most specific row answers: purpose and organization, then purpose, then organization, then the general row. ConsentStatus always equals NewConsentStatus on the ContactConsentHistory row with the latest ConsentStatusAt. Set it through ContactPreferenceEngine, which writes the history row with it. Deleting the contact method deletes its consents.',
         NULL,
         'ContactConsent',
         'vwContactConsents',
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

/* SQL generated to add new entity MJ_BizApps_Common: Contact Consents to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'd3ab1411-7e47-4ee7-9b1e-8b42dba35904', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consents for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('d3ab1411-7e47-4ee7-9b1e-8b42dba35904' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('d3ab1411-7e47-4ee7-9b1e-8b42dba35904' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consents for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('d3ab1411-7e47-4ee7-9b1e-8b42dba35904' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('d3ab1411-7e47-4ee7-9b1e-8b42dba35904' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consents for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('d3ab1411-7e47-4ee7-9b1e-8b42dba35904' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('d3ab1411-7e47-4ee7-9b1e-8b42dba35904' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

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
         '22e5fe8e-8670-4e8e-980e-f66af472f43d',
         'MJ_BizApps_Common: Contact Consent Histories',
         'Contact Consent Histories',
         'One row per change on a ContactConsent: the status it set, when it took effect in the real world, and where it came from. ContactConsent.ConsentStatus mirrors the row with the latest ConsentStatusAt. A late-arriving change with an older date is kept here but does not change the current status. Deleting the consent deletes its history.',
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
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '22e5fe8e-8670-4e8e-980e-f66af472f43d', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consent Histories for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('22e5fe8e-8670-4e8e-980e-f66af472f43d' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('22e5fe8e-8670-4e8e-980e-f66af472f43d' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consent Histories for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('22e5fe8e-8670-4e8e-980e-f66af472f43d' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('22e5fe8e-8670-4e8e-980e-f66af472f43d' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consent Histories for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('22e5fe8e-8670-4e8e-980e-f66af472f43d' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('22e5fe8e-8670-4e8e-980e-f66af472f43d' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ConsentPurpose */
ALTER TABLE [${flyway:defaultSchema}].[ConsentPurpose] ADD [__mj_CreatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ConsentPurpose */
UPDATE [${flyway:defaultSchema}].[ConsentPurpose] SET [__mj_CreatedAt] = GETUTCDATE() WHERE [__mj_CreatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ConsentPurpose */
ALTER TABLE [${flyway:defaultSchema}].[ConsentPurpose] ALTER COLUMN [__mj_CreatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ConsentPurpose */
ALTER TABLE [${flyway:defaultSchema}].[ConsentPurpose] ADD CONSTRAINT [DF___mj_BizAppsCommon_ConsentPurpose___mj_CreatedAt] DEFAULT GETUTCDATE() FOR [__mj_CreatedAt];
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ConsentPurpose */
ALTER TABLE [${flyway:defaultSchema}].[ConsentPurpose] ADD [__mj_UpdatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ConsentPurpose */
UPDATE [${flyway:defaultSchema}].[ConsentPurpose] SET [__mj_UpdatedAt] = GETUTCDATE() WHERE [__mj_UpdatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ConsentPurpose */
ALTER TABLE [${flyway:defaultSchema}].[ConsentPurpose] ALTER COLUMN [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ConsentPurpose */
ALTER TABLE [${flyway:defaultSchema}].[ConsentPurpose] ADD CONSTRAINT [DF___mj_BizAppsCommon_ConsentPurpose___mj_UpdatedAt] DEFAULT GETUTCDATE() FOR [__mj_UpdatedAt];
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ContactConsent */
ALTER TABLE [${flyway:defaultSchema}].[ContactConsent] ADD [__mj_CreatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ContactConsent */
UPDATE [${flyway:defaultSchema}].[ContactConsent] SET [__mj_CreatedAt] = GETUTCDATE() WHERE [__mj_CreatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ContactConsent */
ALTER TABLE [${flyway:defaultSchema}].[ContactConsent] ALTER COLUMN [__mj_CreatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ContactConsent */
ALTER TABLE [${flyway:defaultSchema}].[ContactConsent] ADD CONSTRAINT [DF___mj_BizAppsCommon_ContactConsent___mj_CreatedAt] DEFAULT GETUTCDATE() FOR [__mj_CreatedAt];
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ContactConsent */
ALTER TABLE [${flyway:defaultSchema}].[ContactConsent] ADD [__mj_UpdatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ContactConsent */
UPDATE [${flyway:defaultSchema}].[ContactConsent] SET [__mj_UpdatedAt] = GETUTCDATE() WHERE [__mj_UpdatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ContactConsent */
ALTER TABLE [${flyway:defaultSchema}].[ContactConsent] ALTER COLUMN [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ContactConsent */
ALTER TABLE [${flyway:defaultSchema}].[ContactConsent] ADD CONSTRAINT [DF___mj_BizAppsCommon_ContactConsent___mj_UpdatedAt] DEFAULT GETUTCDATE() FOR [__mj_UpdatedAt];
GO

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

/* SQL text to insert 24 new entity field(s) */

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '180b944d-0b26-46d1-b6e4-30871b956d3c' OR (EntityID = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8' AND Name = 'ID')) BEGIN
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
            '180b944d-0b26-46d1-b6e4-30871b956d3c',
            '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '5655d4f1-6c44-4ce6-bb17-cff4a214b849' OR (EntityID = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8' AND Name = 'Name')) BEGIN
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
            '5655d4f1-6c44-4ce6-bb17-cff4a214b849',
            '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8'),
            'Name',
            'Name',
            'Display name of the purpose, unique within the installation.',
            'nvarchar',
            200,
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
            1,
            1,
            0,
            1,
            0,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '65cc4d51-6aaa-47fd-87db-1aae84af54e0' OR (EntityID = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8' AND Name = 'Description')) BEGIN
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
            '65cc4d51-6aaa-47fd-87db-1aae84af54e0',
            '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8'),
            'Description',
            'Description',
            'What kinds of messages this purpose covers.',
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
            1,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '1fad7ce1-f02c-4c7f-9512-40c36607d5eb' OR (EntityID = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8' AND Name = 'DisplayRank')) BEGIN
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
            '1fad7ce1-f02c-4c7f-9512-40c36607d5eb',
            '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8'),
            'DisplayRank',
            'Display Rank',
            'Sort order in dropdown lists. Lower values appear first.',
            'int',
            4,
            10,
            0,
            0,
            '(100)',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '857b4e9a-1d18-4c89-a764-6b6d8f367f3d' OR (EntityID = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8' AND Name = 'IsActive')) BEGIN
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
            '857b4e9a-1d18-4c89-a764-6b6d8f367f3d',
            '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8'),
            'IsActive',
            'Is Active',
            'Whether this purpose is offered for new consents. Inactive purposes are hidden from dropdowns but preserved for existing records.',
            'bit',
            1,
            1,
            0,
            0,
            '(1)',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '49636b28-99bc-4500-b10e-14490a0c7433' OR (EntityID = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8' AND Name = '__mj_CreatedAt')) BEGIN
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
            '49636b28-99bc-4500-b10e-14490a0c7433',
            '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8c12b39d-239b-48ba-9ba6-ef165dea7a21' OR (EntityID = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8' AND Name = '__mj_UpdatedAt')) BEGIN
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
            '8c12b39d-239b-48ba-9ba6-ef165dea7a21',
            '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '220d9d13-864a-461e-aa06-fd0ffa3d417f' OR (EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND Name = 'CommunicationBaseMessageTypeID')) BEGIN
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
            '220d9d13-864a-461e-aa06-fd0ffa3d417f',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '564490be-a253-4d86-be14-7035792ea683' OR (EntityID = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904' AND Name = 'ID')) BEGIN
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
            '564490be-a253-4d86-be14-7035792ea683',
            'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8fed315d-f210-4f2c-b05e-8a0e2b907fef' OR (EntityID = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904' AND Name = 'ContactMethodID')) BEGIN
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
            '8fed315d-f210-4f2c-b05e-8a0e2b907fef',
            'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904'),
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
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '0eb73d4b-a2eb-4216-afc0-38f13c869183' OR (EntityID = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904' AND Name = 'ConsentPurposeID')) BEGIN
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
            '0eb73d4b-a2eb-4216-afc0-38f13c869183',
            'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904'),
            'ConsentPurposeID',
            'Consent Purpose ID',
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
            '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8',
            'ID',
            0,
            0,
            1,
            0,
            0,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '25b684ba-9321-43eb-a677-4998ea657b7a' OR (EntityID = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904' AND Name = 'OrganizationID')) BEGIN
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
            '25b684ba-9321-43eb-a677-4998ea657b7a',
            'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904'),
            'OrganizationID',
            'Organization ID',
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
            'C70448F9-9792-41D7-A82C-784B66429D54',
            'ID',
            0,
            0,
            1,
            0,
            0,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '59f57802-3b68-4185-b84c-28bd69461b1f' OR (EntityID = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904' AND Name = 'ConsentStatus')) BEGIN
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
            '59f57802-3b68-4185-b84c-28bd69461b1f',
            'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904'),
            'ConsentStatus',
            'Consent Status',
            'The current consent: NotSpecified, OptedIn or OptedOut.',
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
            1,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '1f2a80dd-3858-47a3-af29-efe02ab3f4f1' OR (EntityID = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904' AND Name = '__mj_CreatedAt')) BEGIN
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
            '1f2a80dd-3858-47a3-af29-efe02ab3f4f1',
            'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c098eb09-bc0d-4c82-9028-dc5abe2ddb58' OR (EntityID = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904' AND Name = '__mj_UpdatedAt')) BEGIN
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
            'c098eb09-bc0d-4c82-9028-dc5abe2ddb58',
            'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '5a67f7ac-440c-4230-9589-65249925b616' OR (EntityID = '22E5FE8E-8670-4E8E-980E-F66AF472F43D' AND Name = 'ID')) BEGIN
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
            '5a67f7ac-440c-4230-9589-65249925b616',
            '22E5FE8E-8670-4E8E-980E-F66AF472F43D', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '22E5FE8E-8670-4E8E-980E-F66AF472F43D'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '4666c636-ee4a-4636-b1da-25f2f4d8bc7e' OR (EntityID = '22E5FE8E-8670-4E8E-980E-F66AF472F43D' AND Name = 'ContactConsentID')) BEGIN
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
            '4666c636-ee4a-4636-b1da-25f2f4d8bc7e',
            '22E5FE8E-8670-4E8E-980E-F66AF472F43D', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '22E5FE8E-8670-4E8E-980E-F66AF472F43D'),
            'ContactConsentID',
            'Contact Consent ID',
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
            'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c0c7b5d8-256f-4451-ba87-972a77cfdedd' OR (EntityID = '22E5FE8E-8670-4E8E-980E-F66AF472F43D' AND Name = 'NewConsentStatus')) BEGIN
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
            'c0c7b5d8-256f-4451-ba87-972a77cfdedd',
            '22E5FE8E-8670-4E8E-980E-F66AF472F43D', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '22E5FE8E-8670-4E8E-980E-F66AF472F43D'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f7ce05d0-efef-40fa-92f8-2a22f4cf7b5d' OR (EntityID = '22E5FE8E-8670-4E8E-980E-F66AF472F43D' AND Name = 'ConsentStatusAt')) BEGIN
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
            'f7ce05d0-efef-40fa-92f8-2a22f4cf7b5d',
            '22E5FE8E-8670-4E8E-980E-F66AF472F43D', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '22E5FE8E-8670-4E8E-980E-F66AF472F43D'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '5c88f0df-59b1-4b2a-9d32-e12cf14332e4' OR (EntityID = '22E5FE8E-8670-4E8E-980E-F66AF472F43D' AND Name = 'ConsentSource')) BEGIN
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
            '5c88f0df-59b1-4b2a-9d32-e12cf14332e4',
            '22E5FE8E-8670-4E8E-980E-F66AF472F43D', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '22E5FE8E-8670-4E8E-980E-F66AF472F43D'),
            'ConsentSource',
            'Consent Source',
            'Where the change came from, for example "Web signup", "Unsubscribe link", "Import: CRM" or "Staff".',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'fd15ff4f-1e6d-4b53-9dae-e484af981a4e' OR (EntityID = '22E5FE8E-8670-4E8E-980E-F66AF472F43D' AND Name = 'RecordedByUserID')) BEGIN
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
            'fd15ff4f-1e6d-4b53-9dae-e484af981a4e',
            '22E5FE8E-8670-4E8E-980E-F66AF472F43D', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '22E5FE8E-8670-4E8E-980E-F66AF472F43D'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '862c0f47-7d92-4115-956f-ef6893dc61ed' OR (EntityID = '22E5FE8E-8670-4E8E-980E-F66AF472F43D' AND Name = 'Notes')) BEGIN
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
            '862c0f47-7d92-4115-956f-ef6893dc61ed',
            '22E5FE8E-8670-4E8E-980E-F66AF472F43D', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '22E5FE8E-8670-4E8E-980E-F66AF472F43D'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '62f75b57-7d9d-4d22-ab13-316a2d1b6d2f' OR (EntityID = '22E5FE8E-8670-4E8E-980E-F66AF472F43D' AND Name = '__mj_CreatedAt')) BEGIN
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
            '62f75b57-7d9d-4d22-ab13-316a2d1b6d2f',
            '22E5FE8E-8670-4E8E-980E-F66AF472F43D', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '22E5FE8E-8670-4E8E-980E-F66AF472F43D'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'b15616be-b917-47e7-b7da-d8014284d78b' OR (EntityID = '22E5FE8E-8670-4E8E-980E-F66AF472F43D' AND Name = '__mj_UpdatedAt')) BEGIN
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
            'b15616be-b917-47e7-b7da-d8014284d78b',
            '22E5FE8E-8670-4E8E-980E-F66AF472F43D', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '22E5FE8E-8670-4E8E-980E-F66AF472F43D'),
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

/* SQL text to insert entity field value with ID d8b54919-6380-4658-a53d-0248db4faa46 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('d8b54919-6380-4658-a53d-0248db4faa46', '59F57802-3B68-4185-B84C-28BD69461B1F', 1, 'NotSpecified', 'NotSpecified', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 0a705645-d637-4093-baf1-27fd5c62686b */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('0a705645-d637-4093-baf1-27fd5c62686b', '59F57802-3B68-4185-B84C-28BD69461B1F', 2, 'OptedIn', 'OptedIn', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID b66a3935-e4ef-4ec0-aa14-dd4336cfe0fb */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('b66a3935-e4ef-4ec0-aa14-dd4336cfe0fb', '59F57802-3B68-4185-B84C-28BD69461B1F', 3, 'OptedOut', 'OptedOut', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 59F57802-3B68-4185-B84C-28BD69461B1F */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='59F57802-3B68-4185-B84C-28BD69461B1F';

/* SQL text to insert entity field value with ID fe6399e4-7501-4250-a2b7-0bcede85fbde */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('fe6399e4-7501-4250-a2b7-0bcede85fbde', 'C0C7B5D8-256F-4451-BA87-972A77CFDEDD', 1, 'NotSpecified', 'NotSpecified', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID b4bf8bcc-741f-4c86-857d-dd5bf5795f9c */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('b4bf8bcc-741f-4c86-857d-dd5bf5795f9c', 'C0C7B5D8-256F-4451-BA87-972A77CFDEDD', 2, 'OptedIn', 'OptedIn', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 8acee8ea-6306-42ea-8957-0abc442d05e8 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('8acee8ea-6306-42ea-8957-0abc442d05e8', 'C0C7B5D8-256F-4451-BA87-972A77CFDEDD', 3, 'OptedOut', 'OptedOut', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID C0C7B5D8-256F-4451-BA87-972A77CFDEDD */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='C0C7B5D8-256F-4451-BA87-972A77CFDEDD';

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


/* Create Entity Relationship: MJ_BizApps_Common: Contact Methods -> MJ_BizApps_Common: Contact Consents (One To Many via ContactMethodID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '4757d4e8-7780-4c2d-aed3-3e10012f4cc1'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('4757d4e8-7780-4c2d-aed3-3e10012f4cc1', '32C45078-D33B-4760-9BE5-0DF7F483F591', 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904', 'ContactMethodID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Consent Purposes -> MJ_BizApps_Common: Contact Consents (One To Many via ConsentPurposeID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '8fd91063-ce00-428b-9043-a9417cedae18'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('8fd91063-ce00-428b-9043-a9417cedae18', '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8', 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904', 'ConsentPurposeID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ: Users -> MJ_BizApps_Common: Contact Consent Histories (One To Many via RecordedByUserID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'fa5ebead-8a7f-4b96-80fb-214b3cb23f7a'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('fa5ebead-8a7f-4b96-80fb-214b3cb23f7a', 'E1238F34-2837-EF11-86D4-6045BDEE16E6', '22E5FE8E-8670-4E8E-980E-F66AF472F43D', 'RecordedByUserID', 'One To Many', 1, 1, 124, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ: Communication Base Message Types -> MJ_BizApps_Common: Contact Types (One To Many via CommunicationBaseMessageTypeID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '2ff7e909-aa83-4e4d-960e-d4866ff7b221'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('2ff7e909-aa83-4e4d-960e-d4866ff7b221', '47248F34-2837-EF11-86D4-6045BDEE16E6', '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', 'CommunicationBaseMessageTypeID', 'One To Many', 1, 1, 3, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Organizations -> MJ_BizApps_Common: Contact Consents (One To Many via OrganizationID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'aa308995-ab42-4057-8754-c97af6f25afe'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('aa308995-ab42-4057-8754-c97af6f25afe', 'C70448F9-9792-41D7-A82C-784B66429D54', 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904', 'OrganizationID', 'One To Many', 1, 1, 5, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Contact Consents -> MJ_BizApps_Common: Contact Consent Histories (One To Many via ContactConsentID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '6c846e44-acc5-4a58-9171-08fb028207ea'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('6c846e44-acc5-4a58-9171-08fb028207ea', 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904', '22E5FE8E-8670-4E8E-980E-F66AF472F43D', 'ContactConsentID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;

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

/* Index for Foreign Keys for ConsentPurpose */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Consent Purposes
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------;

/* Index for Foreign Keys for ContactConsentHistory */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Consent Histories
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key ContactConsentID in table ContactConsentHistory
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactConsentHistory_ContactConsentID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ContactConsentHistory]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactConsentHistory_ContactConsentID ON [${flyway:defaultSchema}].[ContactConsentHistory] ([ContactConsentID]);

-- Index for foreign key RecordedByUserID in table ContactConsentHistory
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactConsentHistory_RecordedByUserID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ContactConsentHistory]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactConsentHistory_RecordedByUserID ON [${flyway:defaultSchema}].[ContactConsentHistory] ([RecordedByUserID]);

/* SQL text to update entity field related entity name field map for entity field ID FD15FF4F-1E6D-4B53-9DAE-E484AF981A4E */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='FD15FF4F-1E6D-4B53-9DAE-E484AF981A4E', @RelatedEntityNameFieldMap='RecordedByUser';

/* Index for Foreign Keys for ContactConsent */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Consents
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key ContactMethodID in table ContactConsent
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactConsent_ContactMethodID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ContactConsent]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactConsent_ContactMethodID ON [${flyway:defaultSchema}].[ContactConsent] ([ContactMethodID]);

-- Index for foreign key ConsentPurposeID in table ContactConsent
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactConsent_ConsentPurposeID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ContactConsent]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactConsent_ConsentPurposeID ON [${flyway:defaultSchema}].[ContactConsent] ([ConsentPurposeID]);

-- Index for foreign key OrganizationID in table ContactConsent
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactConsent_OrganizationID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ContactConsent]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactConsent_OrganizationID ON [${flyway:defaultSchema}].[ContactConsent] ([OrganizationID]);

/* SQL text to update entity field related entity name field map for entity field ID 8FED315D-F210-4F2C-B05E-8A0E2B907FEF */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='8FED315D-F210-4F2C-B05E-8A0E2B907FEF', @RelatedEntityNameFieldMap='ContactMethod';

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

/* SQL text to update entity field related entity name field map for entity field ID 220D9D13-864A-461E-AA06-FD0FFA3D417F */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='220D9D13-864A-461E-AA06-FD0FFA3D417F', @RelatedEntityNameFieldMap='CommunicationBaseMessageType';

/* Base View SQL for MJ_BizApps_Common: Consent Purposes */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Consent Purposes
-- Item: vwConsentPurposes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Consent Purposes
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ConsentPurpose
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwConsentPurposes]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwConsentPurposes];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwConsentPurposes]
AS
SELECT
    c.*
FROM
    [${flyway:defaultSchema}].[ConsentPurpose] AS c
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwConsentPurposes] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Consent Purposes */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Consent Purposes
-- Item: Permissions for vwConsentPurposes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwConsentPurposes] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Consent Purposes */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Consent Purposes
-- Item: spCreateConsentPurpose
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ConsentPurpose
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateConsentPurpose]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateConsentPurpose];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateConsentPurpose]
    @ID uniqueidentifier = NULL,
    @Name nvarchar(100),
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @DisplayRank int = NULL,
    @IsActive bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ConsentPurpose]
            (
                [ID],
                [Name],
                [Description],
                [DisplayRank],
                [IsActive]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                ISNULL(@DisplayRank, 100),
                ISNULL(@IsActive, 1)
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ConsentPurpose]
            (
                [Name],
                [Description],
                [DisplayRank],
                [IsActive]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                ISNULL(@DisplayRank, 100),
                ISNULL(@IsActive, 1)
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwConsentPurposes] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateConsentPurpose] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Consent Purposes */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateConsentPurpose] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Consent Purposes */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Consent Purposes
-- Item: spUpdateConsentPurpose
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

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
    @DisplayRank int = NULL,
    @IsActive bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ConsentPurpose]
    SET
        [Name] = ISNULL(@Name, [Name]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [DisplayRank] = ISNULL(@DisplayRank, [DisplayRank]),
        [IsActive] = ISNULL(@IsActive, [IsActive])
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
    UPDATE
        [${flyway:defaultSchema}].[ConsentPurpose]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ConsentPurpose] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Consent Purposes */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateConsentPurpose] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Consent Purposes */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Consent Purposes
-- Item: spDeleteConsentPurpose
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ConsentPurpose
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteConsentPurpose]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteConsentPurpose];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteConsentPurpose]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ConsentPurpose]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteConsentPurpose] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Consent Purposes */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteConsentPurpose] TO [cdp_Developer], [cdp_Integration];

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
    MJUser_RecordedByUserID.[Name] AS [RecordedByUser]
FROM
    [${flyway:defaultSchema}].[ContactConsentHistory] AS c
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
    @ContactConsentID uniqueidentifier,
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
                [ContactConsentID],
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
                @ContactConsentID,
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
                [ContactConsentID],
                [NewConsentStatus],
                [ConsentStatusAt],
                [ConsentSource],
                [RecordedByUserID],
                [Notes]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ContactConsentID,
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
    @ContactConsentID uniqueidentifier = NULL,
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
        [ContactConsentID] = ISNULL(@ContactConsentID, [ContactConsentID]),
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

/* SQL text to update entity field related entity name field map for entity field ID 0EB73D4B-A2EB-4216-AFC0-38F13C869183 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='0EB73D4B-A2EB-4216-AFC0-38F13C869183', @RelatedEntityNameFieldMap='ConsentPurpose';

/* SQL text to update entity field related entity name field map for entity field ID 25B684BA-9321-43EB-A677-4998EA657B7A */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='25B684BA-9321-43EB-A677-4998EA657B7A', @RelatedEntityNameFieldMap='Organization';

/* Base View SQL for MJ_BizApps_Common: Contact Consents */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Consents
-- Item: vwContactConsents
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Contact Consents
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ContactConsent
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwContactConsents]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwContactConsents];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwContactConsents]
AS
SELECT
    c.*,
    mjBizAppsCommonContactMethod_ContactMethodID.[Value] AS [ContactMethod],
    mjBizAppsCommonConsentPurpose_ConsentPurposeID.[Name] AS [ConsentPurpose],
    mjBizAppsCommonOrganization_OrganizationID.[Name] AS [Organization]
FROM
    [${flyway:defaultSchema}].[ContactConsent] AS c
INNER JOIN
    [${flyway:defaultSchema}].[ContactMethod] AS mjBizAppsCommonContactMethod_ContactMethodID
  ON
    [c].[ContactMethodID] = mjBizAppsCommonContactMethod_ContactMethodID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ConsentPurpose] AS mjBizAppsCommonConsentPurpose_ConsentPurposeID
  ON
    [c].[ConsentPurposeID] = mjBizAppsCommonConsentPurpose_ConsentPurposeID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Organization] AS mjBizAppsCommonOrganization_OrganizationID
  ON
    [c].[OrganizationID] = mjBizAppsCommonOrganization_OrganizationID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwContactConsents] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Contact Consents */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Consents
-- Item: Permissions for vwContactConsents
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwContactConsents] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Contact Consents */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Consents
-- Item: spCreateContactConsent
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ContactConsent
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateContactConsent]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateContactConsent];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateContactConsent]
    @ID uniqueidentifier = NULL,
    @ContactMethodID uniqueidentifier,
    @ConsentPurposeID_Clear bit = 0,
    @ConsentPurposeID uniqueidentifier = NULL,
    @OrganizationID_Clear bit = 0,
    @OrganizationID uniqueidentifier = NULL,
    @ConsentStatus nvarchar(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ContactConsent]
            (
                [ID],
                [ContactMethodID],
                [ConsentPurposeID],
                [OrganizationID],
                [ConsentStatus]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @ContactMethodID,
                CASE WHEN @ConsentPurposeID_Clear = 1 THEN NULL ELSE ISNULL(@ConsentPurposeID, NULL) END,
                CASE WHEN @OrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationID, NULL) END,
                ISNULL(@ConsentStatus, 'NotSpecified')
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ContactConsent]
            (
                [ContactMethodID],
                [ConsentPurposeID],
                [OrganizationID],
                [ConsentStatus]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ContactMethodID,
                CASE WHEN @ConsentPurposeID_Clear = 1 THEN NULL ELSE ISNULL(@ConsentPurposeID, NULL) END,
                CASE WHEN @OrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationID, NULL) END,
                ISNULL(@ConsentStatus, 'NotSpecified')
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwContactConsents] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateContactConsent] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Contact Consents */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateContactConsent] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Contact Consents */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Consents
-- Item: spUpdateContactConsent
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ContactConsent
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateContactConsent]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateContactConsent];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateContactConsent]
    @ID uniqueidentifier,
    @ContactMethodID uniqueidentifier = NULL,
    @ConsentPurposeID_Clear bit = 0,
    @ConsentPurposeID uniqueidentifier = NULL,
    @OrganizationID_Clear bit = 0,
    @OrganizationID uniqueidentifier = NULL,
    @ConsentStatus nvarchar(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ContactConsent]
    SET
        [ContactMethodID] = ISNULL(@ContactMethodID, [ContactMethodID]),
        [ConsentPurposeID] = CASE WHEN @ConsentPurposeID_Clear = 1 THEN NULL ELSE ISNULL(@ConsentPurposeID, [ConsentPurposeID]) END,
        [OrganizationID] = CASE WHEN @OrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationID, [OrganizationID]) END,
        [ConsentStatus] = ISNULL(@ConsentStatus, [ConsentStatus])
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwContactConsents] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwContactConsents]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactConsent] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ContactConsent table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateContactConsent]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateContactConsent];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateContactConsent
ON [${flyway:defaultSchema}].[ContactConsent]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ContactConsent]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ContactConsent] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Contact Consents */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactConsent] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Contact Consents */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Consents
-- Item: spDeleteContactConsent
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ContactConsent
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteContactConsent]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteContactConsent];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteContactConsent]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ContactConsent]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteContactConsent] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Contact Consents */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteContactConsent] TO [cdp_Developer], [cdp_Integration];

/* SQL text to insert 5 new entity field(s) */

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '46a3022b-0cb0-4078-9531-ac53477819cd' OR (EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND Name = 'CommunicationBaseMessageType')) BEGIN
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
            '46a3022b-0cb0-4078-9531-ac53477819cd',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '1aa32191-2e94-4352-8d11-1e9098b2fa4d' OR (EntityID = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904' AND Name = 'ContactMethod')) BEGIN
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
            '1aa32191-2e94-4352-8d11-1e9098b2fa4d',
            'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '21c9a830-abe5-4591-8e4d-3e846c683a62' OR (EntityID = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904' AND Name = 'ConsentPurpose')) BEGIN
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
            '21c9a830-abe5-4591-8e4d-3e846c683a62',
            'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904'),
            'ConsentPurpose',
            'Consent Purpose',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '20f65e01-9ded-4d83-b161-786395af1d8f' OR (EntityID = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904' AND Name = 'Organization')) BEGIN
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
            '20f65e01-9ded-4d83-b161-786395af1d8f',
            'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904'),
            'Organization',
            'Organization',
            NULL,
            'nvarchar',
            510,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'e71f087b-43e9-4176-a4ac-9cabfcab2678' OR (EntityID = '22E5FE8E-8670-4E8E-980E-F66AF472F43D' AND Name = 'RecordedByUser')) BEGIN
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
            'e71f087b-43e9-4176-a4ac-9cabfcab2678',
            '22E5FE8E-8670-4E8E-980E-F66AF472F43D', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '22E5FE8E-8670-4E8E-980E-F66AF472F43D'),
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
               SET IsNameField = 1
               WHERE ID = 'C0C7B5D8-256F-4451-BA87-972A77CFDEDD'
               AND AutoUpdateIsNameField = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'E71F087B-43E9-4176-A4AC-9CABFCAB2678'
               AND AutoUpdateDefaultInView = 1;

/* Set field properties for entity */

            UPDATE [${mjSchema}].[Entity]
            SET AllowUserSearchAPI = 0
            WHERE ID = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8'
            AND AutoUpdateAllowUserSearchAPI = 1;

/* Set categories for 2 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Types.CommunicationBaseMessageTypeID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '220D9D13-864A-461E-AA06-FD0FFA3D417F';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Types.CommunicationBaseMessageType 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '46A3022B-0CB0-4078-9531-AC53477819CD';

/* Set categories for 7 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '180B944D-0B26-46D1-B6E4-30871B956D3C';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.Name 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Purpose Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '5655D4F1-6C44-4CE6-BB17-CFF4A214B849';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.Description 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Purpose Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '65CC4D51-6AAA-47FD-87DB-1AAE84AF54E0';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.DisplayRank 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Purpose Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '1FAD7CE1-F02C-4C7F-9512-40C36607D5EB';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.IsActive 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Purpose Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '857B4E9A-1D18-4C89-A764-6B6D8F367F3D';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '49636B28-99BC-4500-B10E-14490A0C7433';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '8C12B39D-239B-48BA-9BA6-EF165DEA7A21';

/* Set entity icon to fa fa-shield-alt */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-shield-alt', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8';

/* Insert FieldCategoryInfo setting for entity */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8' AND [Name] = 'FieldCategoryInfo'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('47763911-2f28-571f-9eeb-57776bc7c750', '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8', 'FieldCategoryInfo', '{
  "Consent Purpose Details": {
    "description": "Core configuration and display details for consent purposes",
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
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8' AND [Name] = 'FieldCategoryIcons'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('dfd50b14-be8c-517f-8ec6-dc1f705526aa', '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8', 'FieldCategoryIcons', '{
  "Consent Purpose Details": "fa fa-shield-alt",
  "System Metadata": "fa fa-cog"
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Set DefaultForNewUser=false for NEW entity (category: reference, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = '7E461BC4-BE9A-417F-A5E0-2B884DADD3F8';

/* Set categories for 10 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '5A67F7AC-440C-4230-9589-65249925B616';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.ContactConsentID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent History Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Contact Consent'
WHERE 
   ID = '4666C636-EE4A-4636-B1DA-25F2F4D8BC7E';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.NewConsentStatus 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent History Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'C0C7B5D8-256F-4451-BA87-972A77CFDEDD';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.ConsentStatusAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent History Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'F7CE05D0-EFEF-40FA-92F8-2A22F4CF7B5D';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.ConsentSource 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent History Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '5C88F0DF-59B1-4B2A-9D32-E12CF14332E4';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.RecordedByUserID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Audit Information',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'FD15FF4F-1E6D-4B53-9DAE-E484AF981A4E';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.RecordedByUser 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Audit Information',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'E71F087B-43E9-4176-A4AC-9CABFCAB2678';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.Notes 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Audit Information',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '862C0F47-7D92-4115-956F-EF6893DC61ED';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '62F75B57-7D9D-4D22-AB13-316A2D1B6D2F';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'B15616BE-B917-47E7-B7DA-D8014284D78B';

/* Set entity icon to fa fa-history */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-history', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = '22E5FE8E-8670-4E8E-980E-F66AF472F43D';

/* Insert FieldCategoryInfo setting for entity */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = '22E5FE8E-8670-4E8E-980E-F66AF472F43D' AND [Name] = 'FieldCategoryInfo'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('a1751161-b7bb-5a5a-8b05-77fc35d55541', '22E5FE8E-8670-4E8E-980E-F66AF472F43D', 'FieldCategoryInfo', '{
  "Audit Information": {
    "description": "Information about who recorded the consent change and supporting evidence notes",
    "icon": "fa fa-user-shield"
  },
  "Consent History Details": {
    "description": "Core details tracking the status, effective date, and source of consent changes",
    "icon": "fa fa-clipboard-list"
  },
  "System Metadata": {
    "description": "System-managed audit and tracking fields",
    "icon": "fa fa-cog"
  }
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Insert FieldCategoryIcons setting (legacy) */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = '22E5FE8E-8670-4E8E-980E-F66AF472F43D' AND [Name] = 'FieldCategoryIcons'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('23959947-2aa2-5b93-aa10-149257b8ba68', '22E5FE8E-8670-4E8E-980E-F66AF472F43D', 'FieldCategoryIcons', '{
  "Audit Information": "fa fa-user-shield",
  "Consent History Details": "fa fa-clipboard-list",
  "System Metadata": "fa fa-cog"
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Set DefaultForNewUser=false for NEW entity (category: supporting, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = '22E5FE8E-8670-4E8E-980E-F66AF472F43D';

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '1AA32191-2E94-4352-8D11-1E9098B2FA4D'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '21C9A830-ABE5-4591-8E4D-3E846C683A62'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '20F65E01-9DED-4D83-B161-786395AF1D8F'
               AND AutoUpdateDefaultInView = 1;

/* Set categories for 10 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '564490BE-A253-4D86-BE14-7035792EA683';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.ContactMethodID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Contact Method'
WHERE 
   ID = '8FED315D-F210-4F2C-B05E-8A0E2B907FEF';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.ConsentPurposeID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Consent Purpose'
WHERE 
   ID = '0EB73D4B-A2EB-4216-AFC0-38F13C869183';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.OrganizationID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Organization'
WHERE 
   ID = '25B684BA-9321-43EB-A677-4998EA657B7A';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.ConsentStatus 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '59F57802-3B68-4185-B84C-28BD69461B1F';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.ContactMethod 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Contact Method Detail'
WHERE 
   ID = '1AA32191-2E94-4352-8D11-1E9098B2FA4D';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.ConsentPurpose 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Consent Purpose Detail'
WHERE 
   ID = '21C9A830-ABE5-4591-8E4D-3E846C683A62';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.Organization 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Organization Detail'
WHERE 
   ID = '20F65E01-9DED-4D83-B161-786395AF1D8F';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '1F2A80DD-3858-47A3-AF29-EFE02AB3F4F1';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'C098EB09-BC0D-4C82-9028-DC5ABE2DDB58';

/* Set entity icon to fa fa-shield-alt */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-shield-alt', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904';

/* Insert FieldCategoryInfo setting for entity */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904' AND [Name] = 'FieldCategoryInfo'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('98eb1790-4e14-5c19-b6ed-1a4318f7825b', 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904', 'FieldCategoryInfo', '{
  "Consent Details": {
    "description": "Details regarding contact consent status, purpose, and organization associations",
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
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904' AND [Name] = 'FieldCategoryIcons'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('4450a667-24d7-59c3-b15e-8bb2a5432404', 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904', 'FieldCategoryIcons', '{
  "Consent Details": "fa fa-shield-alt",
  "System Metadata": "fa fa-cog"
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Set DefaultForNewUser=false for NEW entity (category: supporting, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = 'D3AB1411-7E47-4EE7-9B1E-8B42DBA35904';

