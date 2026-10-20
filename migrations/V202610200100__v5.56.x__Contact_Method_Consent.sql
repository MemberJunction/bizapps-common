-- =============================================================================
-- Migration: V202610200100__v5.56.x__Contact_Method_Consent.sql
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
   (through the 5.55 release seed) with metadata/ pushed first (so CHECK validators come from the
   pinned GeneratedCode rows).
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
         '075ab823-01cc-4768-8012-416d88fc1b2f',
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
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '075ab823-01cc-4768-8012-416d88fc1b2f', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Consent Purposes for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('075ab823-01cc-4768-8012-416d88fc1b2f' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('075ab823-01cc-4768-8012-416d88fc1b2f' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Consent Purposes for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('075ab823-01cc-4768-8012-416d88fc1b2f' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('075ab823-01cc-4768-8012-416d88fc1b2f' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Consent Purposes for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('075ab823-01cc-4768-8012-416d88fc1b2f' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('075ab823-01cc-4768-8012-416d88fc1b2f' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
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
         'ed3229d4-6a35-40c2-a819-c5fc47b6ef92',
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
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'ed3229d4-6a35-40c2-a819-c5fc47b6ef92', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consents for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('ed3229d4-6a35-40c2-a819-c5fc47b6ef92' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('ed3229d4-6a35-40c2-a819-c5fc47b6ef92' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consents for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('ed3229d4-6a35-40c2-a819-c5fc47b6ef92' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('ed3229d4-6a35-40c2-a819-c5fc47b6ef92' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consents for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('ed3229d4-6a35-40c2-a819-c5fc47b6ef92' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('ed3229d4-6a35-40c2-a819-c5fc47b6ef92' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
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
         '3f3bf282-7707-453c-8770-0248c46d04e7',
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
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '3f3bf282-7707-453c-8770-0248c46d04e7', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consent Histories for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('3f3bf282-7707-453c-8770-0248c46d04e7' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('3f3bf282-7707-453c-8770-0248c46d04e7' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consent Histories for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('3f3bf282-7707-453c-8770-0248c46d04e7' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('3f3bf282-7707-453c-8770-0248c46d04e7' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consent Histories for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('3f3bf282-7707-453c-8770-0248c46d04e7' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('3f3bf282-7707-453c-8770-0248c46d04e7' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
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

/* SQL text to insert 24 new entity field(s) */

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c8c0591f-3be9-46e0-9208-2543c9d3963b' OR (EntityID = '3F3BF282-7707-453C-8770-0248C46D04E7' AND Name = 'ID')) BEGIN
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
            'c8c0591f-3be9-46e0-9208-2543c9d3963b',
            '3F3BF282-7707-453C-8770-0248C46D04E7', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3F3BF282-7707-453C-8770-0248C46D04E7'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '6422ac03-d557-4e34-9a0a-bb045ecf5551' OR (EntityID = '3F3BF282-7707-453C-8770-0248C46D04E7' AND Name = 'ContactConsentID')) BEGIN
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
            '6422ac03-d557-4e34-9a0a-bb045ecf5551',
            '3F3BF282-7707-453C-8770-0248C46D04E7', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3F3BF282-7707-453C-8770-0248C46D04E7'),
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
            'ED3229D4-6A35-40C2-A819-C5FC47B6EF92',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '9d2e34ee-3cfd-4e67-bb99-b0d21091e038' OR (EntityID = '3F3BF282-7707-453C-8770-0248C46D04E7' AND Name = 'NewConsentStatus')) BEGIN
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
            '9d2e34ee-3cfd-4e67-bb99-b0d21091e038',
            '3F3BF282-7707-453C-8770-0248C46D04E7', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3F3BF282-7707-453C-8770-0248C46D04E7'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '4a6097e4-8cb7-4627-998b-df446d819440' OR (EntityID = '3F3BF282-7707-453C-8770-0248C46D04E7' AND Name = 'ConsentStatusAt')) BEGIN
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
            '4a6097e4-8cb7-4627-998b-df446d819440',
            '3F3BF282-7707-453C-8770-0248C46D04E7', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3F3BF282-7707-453C-8770-0248C46D04E7'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c09976fa-3b4c-44a5-a8d4-2e30cac08406' OR (EntityID = '3F3BF282-7707-453C-8770-0248C46D04E7' AND Name = 'ConsentSource')) BEGIN
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
            'c09976fa-3b4c-44a5-a8d4-2e30cac08406',
            '3F3BF282-7707-453C-8770-0248C46D04E7', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3F3BF282-7707-453C-8770-0248C46D04E7'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '3dcb4e11-ce5f-4872-a1e1-6d9728435ea8' OR (EntityID = '3F3BF282-7707-453C-8770-0248C46D04E7' AND Name = 'RecordedByUserID')) BEGIN
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
            '3dcb4e11-ce5f-4872-a1e1-6d9728435ea8',
            '3F3BF282-7707-453C-8770-0248C46D04E7', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3F3BF282-7707-453C-8770-0248C46D04E7'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '49179f0e-300b-43e7-940b-b0c7e7b2103f' OR (EntityID = '3F3BF282-7707-453C-8770-0248C46D04E7' AND Name = 'Notes')) BEGIN
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
            '49179f0e-300b-43e7-940b-b0c7e7b2103f',
            '3F3BF282-7707-453C-8770-0248C46D04E7', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3F3BF282-7707-453C-8770-0248C46D04E7'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f82015e3-4e9e-4585-aedf-5a6875fbbf87' OR (EntityID = '3F3BF282-7707-453C-8770-0248C46D04E7' AND Name = '__mj_CreatedAt')) BEGIN
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
            'f82015e3-4e9e-4585-aedf-5a6875fbbf87',
            '3F3BF282-7707-453C-8770-0248C46D04E7', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3F3BF282-7707-453C-8770-0248C46D04E7'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '7b77ff6c-60ef-4b85-9b78-d16a404f9419' OR (EntityID = '3F3BF282-7707-453C-8770-0248C46D04E7' AND Name = '__mj_UpdatedAt')) BEGIN
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
            '7b77ff6c-60ef-4b85-9b78-d16a404f9419',
            '3F3BF282-7707-453C-8770-0248C46D04E7', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3F3BF282-7707-453C-8770-0248C46D04E7'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c0740fcf-601e-4d56-a5ef-a4f7e79f7d9e' OR (EntityID = '075AB823-01CC-4768-8012-416D88FC1B2F' AND Name = 'ID')) BEGIN
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
            'c0740fcf-601e-4d56-a5ef-a4f7e79f7d9e',
            '075AB823-01CC-4768-8012-416D88FC1B2F', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '075AB823-01CC-4768-8012-416D88FC1B2F'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '908742c4-f5de-424e-afd9-c51dc7f10eed' OR (EntityID = '075AB823-01CC-4768-8012-416D88FC1B2F' AND Name = 'Name')) BEGIN
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
            '908742c4-f5de-424e-afd9-c51dc7f10eed',
            '075AB823-01CC-4768-8012-416D88FC1B2F', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '075AB823-01CC-4768-8012-416D88FC1B2F'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '6e3fe9d8-b584-4989-90b0-5dd0c2e08eb1' OR (EntityID = '075AB823-01CC-4768-8012-416D88FC1B2F' AND Name = 'Description')) BEGIN
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
            '6e3fe9d8-b584-4989-90b0-5dd0c2e08eb1',
            '075AB823-01CC-4768-8012-416D88FC1B2F', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '075AB823-01CC-4768-8012-416D88FC1B2F'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8338a59b-1603-4ec7-ad38-3aa53081ba06' OR (EntityID = '075AB823-01CC-4768-8012-416D88FC1B2F' AND Name = 'DisplayRank')) BEGIN
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
            '8338a59b-1603-4ec7-ad38-3aa53081ba06',
            '075AB823-01CC-4768-8012-416D88FC1B2F', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '075AB823-01CC-4768-8012-416D88FC1B2F'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c4b9e848-f65b-4197-8116-19652562b201' OR (EntityID = '075AB823-01CC-4768-8012-416D88FC1B2F' AND Name = 'IsActive')) BEGIN
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
            'c4b9e848-f65b-4197-8116-19652562b201',
            '075AB823-01CC-4768-8012-416D88FC1B2F', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '075AB823-01CC-4768-8012-416D88FC1B2F'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'da1ef72e-052f-4efd-b9f4-ff8eccdf1070' OR (EntityID = '075AB823-01CC-4768-8012-416D88FC1B2F' AND Name = '__mj_CreatedAt')) BEGIN
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
            'da1ef72e-052f-4efd-b9f4-ff8eccdf1070',
            '075AB823-01CC-4768-8012-416D88FC1B2F', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '075AB823-01CC-4768-8012-416D88FC1B2F'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'bb66ef16-55c5-41e1-9dc3-d627789595f1' OR (EntityID = '075AB823-01CC-4768-8012-416D88FC1B2F' AND Name = '__mj_UpdatedAt')) BEGIN
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
            'bb66ef16-55c5-41e1-9dc3-d627789595f1',
            '075AB823-01CC-4768-8012-416D88FC1B2F', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '075AB823-01CC-4768-8012-416D88FC1B2F'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '245b389f-dedf-40f2-a2c6-228b6257046b' OR (EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND Name = 'CommunicationBaseMessageTypeID')) BEGIN
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
            '245b389f-dedf-40f2-a2c6-228b6257046b',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '11d8eccd-0030-43e5-9806-769454cb8ee7' OR (EntityID = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92' AND Name = 'ID')) BEGIN
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
            '11d8eccd-0030-43e5-9806-769454cb8ee7',
            'ED3229D4-6A35-40C2-A819-C5FC47B6EF92', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '0b6c664c-6bb1-4716-acc8-6f91a2f077eb' OR (EntityID = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92' AND Name = 'ContactMethodID')) BEGIN
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
            '0b6c664c-6bb1-4716-acc8-6f91a2f077eb',
            'ED3229D4-6A35-40C2-A819-C5FC47B6EF92', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '92831fe8-267f-4156-a4bc-b22ea262ac7b' OR (EntityID = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92' AND Name = 'ConsentPurposeID')) BEGIN
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
            '92831fe8-267f-4156-a4bc-b22ea262ac7b',
            'ED3229D4-6A35-40C2-A819-C5FC47B6EF92', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92'),
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
            '075AB823-01CC-4768-8012-416D88FC1B2F',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '6b6a0a5f-1c16-4861-bb25-4bdd0593c4f5' OR (EntityID = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92' AND Name = 'OrganizationID')) BEGIN
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
            '6b6a0a5f-1c16-4861-bb25-4bdd0593c4f5',
            'ED3229D4-6A35-40C2-A819-C5FC47B6EF92', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '14bfeb78-a2b2-4102-a005-8cd538d4c875' OR (EntityID = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92' AND Name = 'ConsentStatus')) BEGIN
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
            '14bfeb78-a2b2-4102-a005-8cd538d4c875',
            'ED3229D4-6A35-40C2-A819-C5FC47B6EF92', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'fc4e72de-b3d8-404e-9e08-e00365c77fbb' OR (EntityID = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92' AND Name = '__mj_CreatedAt')) BEGIN
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
            'fc4e72de-b3d8-404e-9e08-e00365c77fbb',
            'ED3229D4-6A35-40C2-A819-C5FC47B6EF92', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '43ccbd96-a8de-45be-8525-bbaf81636db1' OR (EntityID = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92' AND Name = '__mj_UpdatedAt')) BEGIN
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
            '43ccbd96-a8de-45be-8525-bbaf81636db1',
            'ED3229D4-6A35-40C2-A819-C5FC47B6EF92', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92'),
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

/* SQL text to insert entity field value with ID 001d77f2-1846-420c-852a-7a1b5b4c5a81 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('001d77f2-1846-420c-852a-7a1b5b4c5a81', '14BFEB78-A2B2-4102-A005-8CD538D4C875', 1, 'NotSpecified', 'NotSpecified', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 039f007b-2dd5-4995-a83e-0f51edc8d698 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('039f007b-2dd5-4995-a83e-0f51edc8d698', '14BFEB78-A2B2-4102-A005-8CD538D4C875', 2, 'OptedIn', 'OptedIn', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID cbbf07d6-17dd-4d55-9b6a-c2a61399031e */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('cbbf07d6-17dd-4d55-9b6a-c2a61399031e', '14BFEB78-A2B2-4102-A005-8CD538D4C875', 3, 'OptedOut', 'OptedOut', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 14BFEB78-A2B2-4102-A005-8CD538D4C875 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='14BFEB78-A2B2-4102-A005-8CD538D4C875';

/* SQL text to insert entity field value with ID cc5eba53-5550-4071-9b5c-ee3d97daa86a */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('cc5eba53-5550-4071-9b5c-ee3d97daa86a', '9D2E34EE-3CFD-4E67-BB99-B0D21091E038', 1, 'NotSpecified', 'NotSpecified', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID f7c96db2-bfee-462d-9a44-f42c36fb2849 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('f7c96db2-bfee-462d-9a44-f42c36fb2849', '9D2E34EE-3CFD-4E67-BB99-B0D21091E038', 2, 'OptedIn', 'OptedIn', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID b59b8f70-9254-432d-9ab8-ca64021b56fd */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('b59b8f70-9254-432d-9ab8-ca64021b56fd', '9D2E34EE-3CFD-4E67-BB99-B0D21091E038', 3, 'OptedOut', 'OptedOut', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 9D2E34EE-3CFD-4E67-BB99-B0D21091E038 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='9D2E34EE-3CFD-4E67-BB99-B0D21091E038';

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
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '1bb0306e-0d43-454c-b9b9-902d1ee54ce7'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('1bb0306e-0d43-454c-b9b9-902d1ee54ce7', '32C45078-D33B-4760-9BE5-0DF7F483F591', 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92', 'ContactMethodID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Consent Purposes -> MJ_BizApps_Common: Contact Consents (One To Many via ConsentPurposeID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '7c58824e-3e96-4e99-8407-7d03c696e6c7'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('7c58824e-3e96-4e99-8407-7d03c696e6c7', '075AB823-01CC-4768-8012-416D88FC1B2F', 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92', 'ConsentPurposeID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ: Users -> MJ_BizApps_Common: Contact Consent Histories (One To Many via RecordedByUserID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '0db7a106-7c70-4577-b5ce-c2d698c1cd21'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('0db7a106-7c70-4577-b5ce-c2d698c1cd21', 'E1238F34-2837-EF11-86D4-6045BDEE16E6', '3F3BF282-7707-453C-8770-0248C46D04E7', 'RecordedByUserID', 'One To Many', 1, 1, 124, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ: Communication Base Message Types -> MJ_BizApps_Common: Contact Types (One To Many via CommunicationBaseMessageTypeID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '08e0f3c9-9ab3-439d-922e-220d5bb1a626'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('08e0f3c9-9ab3-439d-922e-220d5bb1a626', '47248F34-2837-EF11-86D4-6045BDEE16E6', '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', 'CommunicationBaseMessageTypeID', 'One To Many', 1, 1, 3, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Organizations -> MJ_BizApps_Common: Contact Consents (One To Many via OrganizationID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'f5f56e63-a190-482e-b16d-3093327be1c2'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('f5f56e63-a190-482e-b16d-3093327be1c2', 'C70448F9-9792-41D7-A82C-784B66429D54', 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92', 'OrganizationID', 'One To Many', 1, 1, 5, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Contact Consents -> MJ_BizApps_Common: Contact Consent Histories (One To Many via ContactConsentID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'f5a2d95d-2ea2-457b-af62-9ba5fc5bb417'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('f5a2d95d-2ea2-457b-af62-9ba5fc5bb417', 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92', '3F3BF282-7707-453C-8770-0248C46D04E7', 'ContactConsentID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;

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

/* SQL text to update entity field related entity name field map for entity field ID 3DCB4E11-CE5F-4872-A1E1-6D9728435EA8 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='3DCB4E11-CE5F-4872-A1E1-6D9728435EA8', @RelatedEntityNameFieldMap='RecordedByUser';

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

/* SQL text to update entity field related entity name field map for entity field ID 0B6C664C-6BB1-4716-ACC8-6F91A2F077EB */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='0B6C664C-6BB1-4716-ACC8-6F91A2F077EB', @RelatedEntityNameFieldMap='ContactMethod';

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

/* SQL text to update entity field related entity name field map for entity field ID 245B389F-DEDF-40F2-A2C6-228B6257046B */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='245B389F-DEDF-40F2-A2C6-228B6257046B', @RelatedEntityNameFieldMap='CommunicationBaseMessageType';

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

/* SQL text to update entity field related entity name field map for entity field ID 92831FE8-267F-4156-A4BC-B22EA262AC7B */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='92831FE8-267F-4156-A4BC-B22EA262AC7B', @RelatedEntityNameFieldMap='ConsentPurpose';

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

/* SQL text to update entity field related entity name field map for entity field ID 6B6A0A5F-1C16-4861-BB25-4BDD0593C4F5 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='6B6A0A5F-1C16-4861-BB25-4BDD0593C4F5', @RelatedEntityNameFieldMap='Organization';

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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '35d95504-fed5-4a8d-92f9-1218e1d5d437' OR (EntityID = '3F3BF282-7707-453C-8770-0248C46D04E7' AND Name = 'RecordedByUser')) BEGIN
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
            '35d95504-fed5-4a8d-92f9-1218e1d5d437',
            '3F3BF282-7707-453C-8770-0248C46D04E7', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3F3BF282-7707-453C-8770-0248C46D04E7'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'cf1e29fa-623c-4b1b-b234-17b5e9697ed4' OR (EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND Name = 'CommunicationBaseMessageType')) BEGIN
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
            'cf1e29fa-623c-4b1b-b234-17b5e9697ed4',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'e8b1f343-588e-4a37-a5f1-4256f0bfa292' OR (EntityID = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92' AND Name = 'ContactMethod')) BEGIN
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
            'e8b1f343-588e-4a37-a5f1-4256f0bfa292',
            'ED3229D4-6A35-40C2-A819-C5FC47B6EF92', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8117bcfa-9f75-4fa7-a50e-a0d4c73de11c' OR (EntityID = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92' AND Name = 'ConsentPurpose')) BEGIN
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
            '8117bcfa-9f75-4fa7-a50e-a0d4c73de11c',
            'ED3229D4-6A35-40C2-A819-C5FC47B6EF92', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'bd0fa55e-589d-443f-9c6c-c6ce2c7d9481' OR (EntityID = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92' AND Name = 'Organization')) BEGIN
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
            'bd0fa55e-589d-443f-9c6c-c6ce2c7d9481',
            'ED3229D4-6A35-40C2-A819-C5FC47B6EF92', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92'),
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

/* Set field properties for entity */

            UPDATE [${mjSchema}].[Entity]
            SET AllowUserSearchAPI = 0
            WHERE ID = '075AB823-01CC-4768-8012-416D88FC1B2F'
            AND AutoUpdateAllowUserSearchAPI = 1;

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET IsNameField = 1
               WHERE ID = '9D2E34EE-3CFD-4E67-BB99-B0D21091E038'
               AND AutoUpdateIsNameField = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '35D95504-FED5-4A8D-92F9-1218E1D5D437'
               AND AutoUpdateDefaultInView = 1;

/* Set categories for 2 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Types.CommunicationBaseMessageTypeID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category',
   DisplayName = 'Communication Base Message Type'
WHERE 
   ID = '245B389F-DEDF-40F2-A2C6-228B6257046B';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Types.CommunicationBaseMessageType 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'CF1E29FA-623C-4B1B-B234-17B5E9697ED4';

/* Set categories for 7 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'C0740FCF-601E-4D56-A5EF-A4F7E79F7D9E';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.Name 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Purpose Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '908742C4-F5DE-424E-AFD9-C51DC7F10EED';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.Description 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Purpose Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '6E3FE9D8-B584-4989-90B0-5DD0C2E08EB1';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.DisplayRank 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Purpose Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '8338A59B-1603-4EC7-AD38-3AA53081BA06';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.IsActive 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Purpose Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'C4B9E848-F65B-4197-8116-19652562B201';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'DA1EF72E-052F-4EFD-B9F4-FF8ECCDF1070';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'BB66EF16-55C5-41E1-9DC3-D627789595F1';

/* Set entity icon to fa fa-check-circle */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-check-circle', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = '075AB823-01CC-4768-8012-416D88FC1B2F';

/* Insert FieldCategoryInfo setting for entity */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = '075AB823-01CC-4768-8012-416D88FC1B2F' AND [Name] = 'FieldCategoryInfo'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('b52d850e-e5ad-55eb-9477-dffd51735782', '075AB823-01CC-4768-8012-416D88FC1B2F', 'FieldCategoryInfo', '{
  "Consent Purpose Details": {
    "description": "Name, description, and display settings for consent purposes",
    "icon": "fa fa-check-circle"
  },
  "System Metadata": {
    "description": "System-managed audit and tracking fields",
    "icon": "fa fa-cog"
  }
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Insert FieldCategoryIcons setting (legacy) */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = '075AB823-01CC-4768-8012-416D88FC1B2F' AND [Name] = 'FieldCategoryIcons'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('4418aa87-72dc-5392-aa25-fc17c147a0f1', '075AB823-01CC-4768-8012-416D88FC1B2F', 'FieldCategoryIcons', '{
  "Consent Purpose Details": "fa fa-check-circle",
  "System Metadata": "fa fa-cog"
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Set DefaultForNewUser=false for NEW entity (category: reference, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = '075AB823-01CC-4768-8012-416D88FC1B2F';

/* Set categories for 10 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'C8C0591F-3BE9-46E0-9208-2543C9D3963B';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.ContactConsentID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent History Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '6422AC03-D557-4E34-9A0A-BB045ECF5551';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.NewConsentStatus 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent History Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '9D2E34EE-3CFD-4E67-BB99-B0D21091E038';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.ConsentStatusAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent History Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '4A6097E4-8CB7-4627-998B-DF446D819440';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.ConsentSource 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent History Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'C09976FA-3B4C-44A5-A8D4-2E30CAC08406';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.RecordedByUserID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Audit and Tracking',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '3DCB4E11-CE5F-4872-A1E1-6D9728435EA8';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.RecordedByUser 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Audit and Tracking',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '35D95504-FED5-4A8D-92F9-1218E1D5D437';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.Notes 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent History Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '49179F0E-300B-43E7-940B-B0C7E7B2103F';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'F82015E3-4E9E-4585-AEDF-5A6875FBBF87';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '7B77FF6C-60EF-4B85-9B78-D16A404F9419';

/* Set entity icon to fa fa-history */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-history', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = '3F3BF282-7707-453C-8770-0248C46D04E7';

/* Insert FieldCategoryInfo setting for entity */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = '3F3BF282-7707-453C-8770-0248C46D04E7' AND [Name] = 'FieldCategoryInfo'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('304154cd-3986-5d34-ba81-cdcaadb121f5', '3F3BF282-7707-453C-8770-0248C46D04E7', 'FieldCategoryInfo', '{
  "Audit and Tracking": {
    "description": "Information about who recorded the consent change",
    "icon": "fa fa-user-shield"
  },
  "Consent History Details": {
    "description": "Details regarding the consent status change, timeline, source, and notes",
    "icon": "fa fa-history"
  },
  "System Metadata": {
    "description": "System-managed audit and tracking fields",
    "icon": "fa fa-cog"
  }
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Insert FieldCategoryIcons setting (legacy) */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = '3F3BF282-7707-453C-8770-0248C46D04E7' AND [Name] = 'FieldCategoryIcons'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('253b1cc4-0314-5af3-a9e4-3bf0b5e4ab1d', '3F3BF282-7707-453C-8770-0248C46D04E7', 'FieldCategoryIcons', '{
  "Audit and Tracking": "fa fa-user-shield",
  "Consent History Details": "fa fa-history",
  "System Metadata": "fa fa-cog"
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Set DefaultForNewUser=false for NEW entity (category: supporting, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = '3F3BF282-7707-453C-8770-0248C46D04E7';

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'E8B1F343-588E-4A37-A5F1-4256F0BFA292'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '8117BCFA-9F75-4FA7-A50E-A0D4C73DE11C'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'BD0FA55E-589D-443F-9C6C-C6CE2C7D9481'
               AND AutoUpdateDefaultInView = 1;

/* Set categories for 10 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '11D8ECCD-0030-43E5-9806-769454CB8EE7';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.ContactMethodID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Contact Method'
WHERE 
   ID = '0B6C664C-6BB1-4716-ACC8-6F91A2F077EB';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.ConsentPurposeID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Consent Purpose'
WHERE 
   ID = '92831FE8-267F-4156-A4BC-B22EA262AC7B';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.OrganizationID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Organization'
WHERE 
   ID = '6B6A0A5F-1C16-4861-BB25-4BDD0593C4F5';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.ConsentStatus 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '14BFEB78-A2B2-4102-A005-8CD538D4C875';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.ContactMethod 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Contact Method Name'
WHERE 
   ID = 'E8B1F343-588E-4A37-A5F1-4256F0BFA292';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.ConsentPurpose 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Consent Purpose Name'
WHERE 
   ID = '8117BCFA-9F75-4FA7-A50E-A0D4C73DE11C';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.Organization 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Organization Name'
WHERE 
   ID = 'BD0FA55E-589D-443F-9C6C-C6CE2C7D9481';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'FC4E72DE-B3D8-404E-9E08-E00365C77FBB';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '43CCBD96-A8DE-45BE-8525-BBAF81636DB1';

/* Set entity icon to fa fa-shield-alt */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-shield-alt', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92';

/* Insert FieldCategoryInfo setting for entity */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92' AND [Name] = 'FieldCategoryInfo'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('4337229e-1b4c-54a3-9318-fab384223ad5', 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92', 'FieldCategoryInfo', '{
  "Consent Details": {
    "description": "Core information regarding contact consent statuses, purposes, and associations",
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
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92' AND [Name] = 'FieldCategoryIcons'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('7293b061-0f39-5039-b5d8-b37949c9bd7f', 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92', 'FieldCategoryIcons', '{
  "Consent Details": "fa fa-shield-alt",
  "System Metadata": "fa fa-cog"
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Set DefaultForNewUser=false for NEW entity (category: supporting, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = 'ED3229D4-6A35-40C2-A819-C5FC47B6EF92';

