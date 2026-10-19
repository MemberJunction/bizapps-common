-- =============================================================================
-- Migration: V202610191130__v5.55.x__Contact_Method_Consent.sql
-- Description: Consent per contact method, per purpose, optionally per organization
--              (plans/contact-consent.md)
--              - ConsentPurpose: what a consent is for (Marketing, Transactional, ...), a lookup
--                like ContactType so a customer adds purposes without DDL
--              - ContactConsent: one current status per contact method, purpose and (optional)
--                organization, so one email can say yes to one sender and no to another
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
        ConsentPurposeID UNIQUEIDENTIFIER NOT NULL,
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
        @value = N'The current consent for one contact method (an email or phone), for one purpose, from one organization or from the whole installation when OrganizationID is null. A contact method has many of these, the way a person has many contact methods. ConsentStatus always equals NewConsentStatus on the ContactConsentHistory row with the latest ConsentStatusAt. Set it through ContactPreferenceEngine, which writes the history row with it. Deleting the contact method deletes its consents.',
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
         '44a8c590-484b-4b65-9195-bd42796ecade',
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
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '44a8c590-484b-4b65-9195-bd42796ecade', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Consent Purposes for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('44a8c590-484b-4b65-9195-bd42796ecade' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('44a8c590-484b-4b65-9195-bd42796ecade' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Consent Purposes for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('44a8c590-484b-4b65-9195-bd42796ecade' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('44a8c590-484b-4b65-9195-bd42796ecade' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Consent Purposes for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('44a8c590-484b-4b65-9195-bd42796ecade' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('44a8c590-484b-4b65-9195-bd42796ecade' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
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
         'a8a816b3-3238-4931-ac07-fea3f13dca05',
         'MJ_BizApps_Common: Contact Consents',
         'Contact Consents',
         'The current consent for one contact method (an email or phone), for one purpose, from one organization or from the whole installation when OrganizationID is null. A contact method has many of these, the way a person has many contact methods. ConsentStatus always equals NewConsentStatus on the ContactConsentHistory row with the latest ConsentStatusAt. Set it through ContactPreferenceEngine, which writes the history row with it. Deleting the contact method deletes its consents.',
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
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'a8a816b3-3238-4931-ac07-fea3f13dca05', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consents for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('a8a816b3-3238-4931-ac07-fea3f13dca05' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('a8a816b3-3238-4931-ac07-fea3f13dca05' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consents for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('a8a816b3-3238-4931-ac07-fea3f13dca05' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('a8a816b3-3238-4931-ac07-fea3f13dca05' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consents for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('a8a816b3-3238-4931-ac07-fea3f13dca05' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('a8a816b3-3238-4931-ac07-fea3f13dca05' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
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
         '953fd481-ed1d-4b8a-98f7-dd9a85111dba',
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
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '953fd481-ed1d-4b8a-98f7-dd9a85111dba', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consent Histories for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('953fd481-ed1d-4b8a-98f7-dd9a85111dba' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('953fd481-ed1d-4b8a-98f7-dd9a85111dba' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consent Histories for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('953fd481-ed1d-4b8a-98f7-dd9a85111dba' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('953fd481-ed1d-4b8a-98f7-dd9a85111dba' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Consent Histories for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('953fd481-ed1d-4b8a-98f7-dd9a85111dba' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('953fd481-ed1d-4b8a-98f7-dd9a85111dba' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'd0e260b2-4bd4-4ad7-9ca9-caa3d25ecb78' OR (EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND Name = 'CommunicationBaseMessageTypeID')) BEGIN
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
            'd0e260b2-4bd4-4ad7-9ca9-caa3d25ecb78',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '78fe7e83-2a35-4b09-bed4-d916e17ec806' OR (EntityID = '44A8C590-484B-4B65-9195-BD42796ECADE' AND Name = 'ID')) BEGIN
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
            '78fe7e83-2a35-4b09-bed4-d916e17ec806',
            '44A8C590-484B-4B65-9195-BD42796ECADE', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '44A8C590-484B-4B65-9195-BD42796ECADE'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '87ccd965-c421-4c63-909e-0ae1eec7d233' OR (EntityID = '44A8C590-484B-4B65-9195-BD42796ECADE' AND Name = 'Name')) BEGIN
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
            '87ccd965-c421-4c63-909e-0ae1eec7d233',
            '44A8C590-484B-4B65-9195-BD42796ECADE', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '44A8C590-484B-4B65-9195-BD42796ECADE'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'efdc585b-079f-4b65-b407-4a3180102cce' OR (EntityID = '44A8C590-484B-4B65-9195-BD42796ECADE' AND Name = 'Description')) BEGIN
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
            'efdc585b-079f-4b65-b407-4a3180102cce',
            '44A8C590-484B-4B65-9195-BD42796ECADE', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '44A8C590-484B-4B65-9195-BD42796ECADE'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '341fb737-4608-4032-a6af-15d8156a4679' OR (EntityID = '44A8C590-484B-4B65-9195-BD42796ECADE' AND Name = 'DisplayRank')) BEGIN
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
            '341fb737-4608-4032-a6af-15d8156a4679',
            '44A8C590-484B-4B65-9195-BD42796ECADE', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '44A8C590-484B-4B65-9195-BD42796ECADE'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '07d66e12-ef82-4545-9850-08a7be6ee525' OR (EntityID = '44A8C590-484B-4B65-9195-BD42796ECADE' AND Name = 'IsActive')) BEGIN
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
            '07d66e12-ef82-4545-9850-08a7be6ee525',
            '44A8C590-484B-4B65-9195-BD42796ECADE', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '44A8C590-484B-4B65-9195-BD42796ECADE'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '07f763ab-0ac9-4589-9f6d-bd9297e464f6' OR (EntityID = '44A8C590-484B-4B65-9195-BD42796ECADE' AND Name = '__mj_CreatedAt')) BEGIN
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
            '07f763ab-0ac9-4589-9f6d-bd9297e464f6',
            '44A8C590-484B-4B65-9195-BD42796ECADE', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '44A8C590-484B-4B65-9195-BD42796ECADE'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '1e2b0ef3-aab3-4725-8053-f4ccedb75292' OR (EntityID = '44A8C590-484B-4B65-9195-BD42796ECADE' AND Name = '__mj_UpdatedAt')) BEGIN
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
            '1e2b0ef3-aab3-4725-8053-f4ccedb75292',
            '44A8C590-484B-4B65-9195-BD42796ECADE', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '44A8C590-484B-4B65-9195-BD42796ECADE'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '42be174f-001b-46c3-87da-d8de4da3eaf4' OR (EntityID = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA' AND Name = 'ID')) BEGIN
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
            '42be174f-001b-46c3-87da-d8de4da3eaf4',
            '953FD481-ED1D-4B8A-98F7-DD9A85111DBA', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8ebc64f7-2569-406a-9d63-df18a3f62e3c' OR (EntityID = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA' AND Name = 'ContactConsentID')) BEGIN
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
            '8ebc64f7-2569-406a-9d63-df18a3f62e3c',
            '953FD481-ED1D-4B8A-98F7-DD9A85111DBA', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA'),
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
            'A8A816B3-3238-4931-AC07-FEA3F13DCA05',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '2d309d21-4596-4b19-ad7e-07b329dd68aa' OR (EntityID = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA' AND Name = 'NewConsentStatus')) BEGIN
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
            '2d309d21-4596-4b19-ad7e-07b329dd68aa',
            '953FD481-ED1D-4B8A-98F7-DD9A85111DBA', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '5faf0e60-3440-4929-b1d2-266957df9d53' OR (EntityID = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA' AND Name = 'ConsentStatusAt')) BEGIN
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
            '5faf0e60-3440-4929-b1d2-266957df9d53',
            '953FD481-ED1D-4B8A-98F7-DD9A85111DBA', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '0134e27e-6605-4626-a3c4-2dcea2435ae6' OR (EntityID = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA' AND Name = 'ConsentSource')) BEGIN
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
            '0134e27e-6605-4626-a3c4-2dcea2435ae6',
            '953FD481-ED1D-4B8A-98F7-DD9A85111DBA', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'a606f530-79bf-47cd-9a0c-df9360651443' OR (EntityID = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA' AND Name = 'RecordedByUserID')) BEGIN
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
            'a606f530-79bf-47cd-9a0c-df9360651443',
            '953FD481-ED1D-4B8A-98F7-DD9A85111DBA', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '833a5fc5-5ede-4216-866d-487f523b3fb3' OR (EntityID = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA' AND Name = 'Notes')) BEGIN
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
            '833a5fc5-5ede-4216-866d-487f523b3fb3',
            '953FD481-ED1D-4B8A-98F7-DD9A85111DBA', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '0a2ca89d-72af-4f94-9fe0-f54725c3a4a6' OR (EntityID = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA' AND Name = '__mj_CreatedAt')) BEGIN
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
            '0a2ca89d-72af-4f94-9fe0-f54725c3a4a6',
            '953FD481-ED1D-4B8A-98F7-DD9A85111DBA', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'cd1bc85e-4626-45f5-9ede-77607617228a' OR (EntityID = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA' AND Name = '__mj_UpdatedAt')) BEGIN
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
            'cd1bc85e-4626-45f5-9ede-77607617228a',
            '953FD481-ED1D-4B8A-98F7-DD9A85111DBA', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'b465e01f-6f97-44fb-aa87-a2b28e6659fe' OR (EntityID = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05' AND Name = 'ID')) BEGIN
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
            'b465e01f-6f97-44fb-aa87-a2b28e6659fe',
            'A8A816B3-3238-4931-AC07-FEA3F13DCA05', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'cf794624-48c3-4c76-a932-a5f3978b94b5' OR (EntityID = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05' AND Name = 'ContactMethodID')) BEGIN
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
            'cf794624-48c3-4c76-a932-a5f3978b94b5',
            'A8A816B3-3238-4931-AC07-FEA3F13DCA05', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '5796b5e9-d321-40ec-a89f-b6a7d850cca3' OR (EntityID = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05' AND Name = 'ConsentPurposeID')) BEGIN
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
            '5796b5e9-d321-40ec-a89f-b6a7d850cca3',
            'A8A816B3-3238-4931-AC07-FEA3F13DCA05', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05'),
            'ConsentPurposeID',
            'Consent Purpose ID',
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
            '44A8C590-484B-4B65-9195-BD42796ECADE',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '56ec38ca-9d32-4bb8-a8b6-daa10f9d8b34' OR (EntityID = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05' AND Name = 'OrganizationID')) BEGIN
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
            '56ec38ca-9d32-4bb8-a8b6-daa10f9d8b34',
            'A8A816B3-3238-4931-AC07-FEA3F13DCA05', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '7d7d7b01-0fe3-4653-876b-8d578d139a3a' OR (EntityID = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05' AND Name = 'ConsentStatus')) BEGIN
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
            '7d7d7b01-0fe3-4653-876b-8d578d139a3a',
            'A8A816B3-3238-4931-AC07-FEA3F13DCA05', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '3bf3b850-0161-4e7e-b820-43d3a3669ff4' OR (EntityID = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05' AND Name = '__mj_CreatedAt')) BEGIN
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
            '3bf3b850-0161-4e7e-b820-43d3a3669ff4',
            'A8A816B3-3238-4931-AC07-FEA3F13DCA05', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f0e48c87-da1c-48a9-a449-a89b5f87c7e2' OR (EntityID = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05' AND Name = '__mj_UpdatedAt')) BEGIN
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
            'f0e48c87-da1c-48a9-a449-a89b5f87c7e2',
            'A8A816B3-3238-4931-AC07-FEA3F13DCA05', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05'),
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

/* SQL text to insert entity field value with ID 3505e6d4-2585-45b4-a809-f5b86b9a6f34 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('3505e6d4-2585-45b4-a809-f5b86b9a6f34', '7D7D7B01-0FE3-4653-876B-8D578D139A3A', 1, 'NotSpecified', 'NotSpecified', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 629cc743-c462-4a8c-b4cf-27b60920e3e2 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('629cc743-c462-4a8c-b4cf-27b60920e3e2', '7D7D7B01-0FE3-4653-876B-8D578D139A3A', 2, 'OptedIn', 'OptedIn', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 1f3f2136-29fb-4455-89f6-2f04ec2a67aa */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('1f3f2136-29fb-4455-89f6-2f04ec2a67aa', '7D7D7B01-0FE3-4653-876B-8D578D139A3A', 3, 'OptedOut', 'OptedOut', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 7D7D7B01-0FE3-4653-876B-8D578D139A3A */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='7D7D7B01-0FE3-4653-876B-8D578D139A3A';

/* SQL text to insert entity field value with ID 9105363a-6458-481c-a8b6-59f55c4321ad */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('9105363a-6458-481c-a8b6-59f55c4321ad', '2D309D21-4596-4B19-AD7E-07B329DD68AA', 1, 'NotSpecified', 'NotSpecified', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 8e950a0b-0283-49a2-b677-f10a7179da37 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('8e950a0b-0283-49a2-b677-f10a7179da37', '2D309D21-4596-4B19-AD7E-07B329DD68AA', 2, 'OptedIn', 'OptedIn', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 8b7ba97c-ab13-4950-b196-eea146a481b8 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('8b7ba97c-ab13-4950-b196-eea146a481b8', '2D309D21-4596-4B19-AD7E-07B329DD68AA', 3, 'OptedOut', 'OptedOut', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 2D309D21-4596-4B19-AD7E-07B329DD68AA */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='2D309D21-4596-4B19-AD7E-07B329DD68AA';

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
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'c59bb1d1-23d6-474f-9292-4abf80f589d3'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('c59bb1d1-23d6-474f-9292-4abf80f589d3', '32C45078-D33B-4760-9BE5-0DF7F483F591', 'A8A816B3-3238-4931-AC07-FEA3F13DCA05', 'ContactMethodID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ: Users -> MJ_BizApps_Common: Contact Consent Histories (One To Many via RecordedByUserID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'bff086bb-629e-44fa-aec8-7be778f029a2'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('bff086bb-629e-44fa-aec8-7be778f029a2', 'E1238F34-2837-EF11-86D4-6045BDEE16E6', '953FD481-ED1D-4B8A-98F7-DD9A85111DBA', 'RecordedByUserID', 'One To Many', 1, 1, 124, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ: Communication Base Message Types -> MJ_BizApps_Common: Contact Types (One To Many via CommunicationBaseMessageTypeID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'fe49d5b0-a0f1-4b73-88b9-6e0b08a5c439'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('fe49d5b0-a0f1-4b73-88b9-6e0b08a5c439', '47248F34-2837-EF11-86D4-6045BDEE16E6', '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', 'CommunicationBaseMessageTypeID', 'One To Many', 1, 1, 3, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Organizations -> MJ_BizApps_Common: Contact Consents (One To Many via OrganizationID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '33823239-75c7-4c4c-b112-1ae1830624ff'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('33823239-75c7-4c4c-b112-1ae1830624ff', 'C70448F9-9792-41D7-A82C-784B66429D54', 'A8A816B3-3238-4931-AC07-FEA3F13DCA05', 'OrganizationID', 'One To Many', 1, 1, 5, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Consent Purposes -> MJ_BizApps_Common: Contact Consents (One To Many via ConsentPurposeID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'b11c0f53-737e-4976-a649-c1372971598d'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('b11c0f53-737e-4976-a649-c1372971598d', '44A8C590-484B-4B65-9195-BD42796ECADE', 'A8A816B3-3238-4931-AC07-FEA3F13DCA05', 'ConsentPurposeID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Contact Consents -> MJ_BizApps_Common: Contact Consent Histories (One To Many via ContactConsentID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'd3941063-0c7a-4f33-aacf-b40deee9e60e'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('d3941063-0c7a-4f33-aacf-b40deee9e60e', 'A8A816B3-3238-4931-AC07-FEA3F13DCA05', '953FD481-ED1D-4B8A-98F7-DD9A85111DBA', 'ContactConsentID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
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

/* SQL text to update entity field related entity name field map for entity field ID A606F530-79BF-47CD-9A0C-DF9360651443 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='A606F530-79BF-47CD-9A0C-DF9360651443', @RelatedEntityNameFieldMap='RecordedByUser';

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

/* SQL text to update entity field related entity name field map for entity field ID CF794624-48C3-4C76-A932-A5F3978B94B5 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='CF794624-48C3-4C76-A932-A5F3978B94B5', @RelatedEntityNameFieldMap='ContactMethod';

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

/* SQL text to update entity field related entity name field map for entity field ID D0E260B2-4BD4-4AD7-9CA9-CAA3D25ECB78 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='D0E260B2-4BD4-4AD7-9CA9-CAA3D25ECB78', @RelatedEntityNameFieldMap='CommunicationBaseMessageType';

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

/* SQL text to update entity field related entity name field map for entity field ID 5796B5E9-D321-40EC-A89F-B6A7D850CCA3 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='5796B5E9-D321-40EC-A89F-B6A7D850CCA3', @RelatedEntityNameFieldMap='ConsentPurpose';

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

/* SQL text to update entity field related entity name field map for entity field ID 56EC38CA-9D32-4BB8-A8B6-DAA10F9D8B34 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='56EC38CA-9D32-4BB8-A8B6-DAA10F9D8B34', @RelatedEntityNameFieldMap='Organization';

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
INNER JOIN
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
    @ConsentPurposeID uniqueidentifier,
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
                @ConsentPurposeID,
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
                @ConsentPurposeID,
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
        [ConsentPurposeID] = ISNULL(@ConsentPurposeID, [ConsentPurposeID]),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '80bd89e4-cc1c-4cab-8e36-9ad1925b558d' OR (EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND Name = 'CommunicationBaseMessageType')) BEGIN
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
            '80bd89e4-cc1c-4cab-8e36-9ad1925b558d',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '3c4e6244-1e69-4ee5-9ab4-26eeec3b22f4' OR (EntityID = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA' AND Name = 'RecordedByUser')) BEGIN
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
            '3c4e6244-1e69-4ee5-9ab4-26eeec3b22f4',
            '953FD481-ED1D-4B8A-98F7-DD9A85111DBA', -- Entity: MJ_BizApps_Common: Contact Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8f10cf1d-d737-4209-bc02-0c7541956b76' OR (EntityID = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05' AND Name = 'ContactMethod')) BEGIN
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
            '8f10cf1d-d737-4209-bc02-0c7541956b76',
            'A8A816B3-3238-4931-AC07-FEA3F13DCA05', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '2c6ae453-8439-4c86-8295-3dbdd8058719' OR (EntityID = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05' AND Name = 'ConsentPurpose')) BEGIN
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
            '2c6ae453-8439-4c86-8295-3dbdd8058719',
            'A8A816B3-3238-4931-AC07-FEA3F13DCA05', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05'),
            'ConsentPurpose',
            'Consent Purpose',
            NULL,
            'nvarchar',
            200,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '11ccc756-ec7c-41b0-a290-60ab306a554d' OR (EntityID = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05' AND Name = 'Organization')) BEGIN
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
            '11ccc756-ec7c-41b0-a290-60ab306a554d',
            'A8A816B3-3238-4931-AC07-FEA3F13DCA05', -- Entity: MJ_BizApps_Common: Contact Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05'),
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
            WHERE ID = '44A8C590-484B-4B65-9195-BD42796ECADE'
            AND AutoUpdateAllowUserSearchAPI = 1;

/* Set categories for 7 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '78FE7E83-2A35-4B09-BED4-D916E17EC806';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.Name 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Purpose Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '87CCD965-C421-4C63-909E-0AE1EEC7D233';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.Description 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Purpose Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'EFDC585B-079F-4B65-B407-4A3180102CCE';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.DisplayRank 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Purpose Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '341FB737-4608-4032-A6AF-15D8156A4679';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.IsActive 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Purpose Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Active'
WHERE 
   ID = '07D66E12-EF82-4545-9850-08A7BE6EE525';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '07F763AB-0AC9-4589-9F6D-BD9297E464F6';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '1E2B0EF3-AAB3-4725-8053-F4CCEDB75292';

/* Set entity icon to fa fa-shield-alt */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-shield-alt', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = '44A8C590-484B-4B65-9195-BD42796ECADE';

/* Insert FieldCategoryInfo setting for entity */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = '44A8C590-484B-4B65-9195-BD42796ECADE' AND [Name] = 'FieldCategoryInfo'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('af161dee-41e3-597b-9d2e-ded0e132db54', '44A8C590-484B-4B65-9195-BD42796ECADE', 'FieldCategoryInfo', '{
  "Consent Purpose Details": {
    "description": "Core configuration details for the consent purpose",
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
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = '44A8C590-484B-4B65-9195-BD42796ECADE' AND [Name] = 'FieldCategoryIcons'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('28e62fdd-2dd5-55d3-b1e7-f823c5da832a', '44A8C590-484B-4B65-9195-BD42796ECADE', 'FieldCategoryIcons', '{
  "Consent Purpose Details": "fa fa-shield-alt",
  "System Metadata": "fa fa-cog"
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Set DefaultForNewUser=false for NEW entity (category: reference, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = '44A8C590-484B-4B65-9195-BD42796ECADE';

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '8F10CF1D-D737-4209-BC02-0C7541956B76'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '2C6AE453-8439-4C86-8295-3DBDD8058719'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '11CCC756-EC7C-41B0-A290-60AB306A554D'
               AND AutoUpdateDefaultInView = 1;

/* Set categories for 2 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Types.CommunicationBaseMessageTypeID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category',
   DisplayName = 'Communication Base Message Type'
WHERE 
   ID = 'D0E260B2-4BD4-4AD7-9CA9-CAA3D25ECB78';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Types.CommunicationBaseMessageType 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category',
   DisplayName = 'Communication Base Message Type Name'
WHERE 
   ID = '80BD89E4-CC1C-4CAB-8E36-9AD1925B558D';

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET IsNameField = 1
               WHERE ID = '2D309D21-4596-4B19-AD7E-07B329DD68AA'
               AND AutoUpdateIsNameField = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '3C4E6244-1E69-4EE5-9AB4-26EEEC3B22F4'
               AND AutoUpdateDefaultInView = 1;

/* Set categories for 10 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'B465E01F-6F97-44FB-AA87-A2B28E6659FE';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.ContactMethodID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Contact Method'
WHERE 
   ID = 'CF794624-48C3-4C76-A932-A5F3978B94B5';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.ConsentPurposeID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Consent Purpose'
WHERE 
   ID = '5796B5E9-D321-40EC-A89F-B6A7D850CCA3';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.OrganizationID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Organization'
WHERE 
   ID = '56EC38CA-9D32-4BB8-A8B6-DAA10F9D8B34';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.ConsentStatus 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '7D7D7B01-0FE3-4653-876B-8D578D139A3A';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.ContactMethod 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Contact Method Text'
WHERE 
   ID = '8F10CF1D-D737-4209-BC02-0C7541956B76';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.ConsentPurpose 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Consent Purpose Text'
WHERE 
   ID = '2C6AE453-8439-4C86-8295-3DBDD8058719';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.Organization 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Organization Name'
WHERE 
   ID = '11CCC756-EC7C-41B0-A290-60AB306A554D';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '3BF3B850-0161-4E7E-B820-43D3A3669FF4';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consents.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'F0E48C87-DA1C-48A9-A449-A89B5F87C7E2';

/* Set entity icon to fa fa-shield-alt */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-shield-alt', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05';

/* Insert FieldCategoryInfo setting for entity */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05' AND [Name] = 'FieldCategoryInfo'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('9f3dd29e-f012-509a-b673-c44d3cd1bfe5', 'A8A816B3-3238-4931-AC07-FEA3F13DCA05', 'FieldCategoryInfo', '{
  "Consent Details": {
    "description": "Information regarding contact consent status, purposes, and associated methods or organizations",
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
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05' AND [Name] = 'FieldCategoryIcons'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('dd7bd02e-c383-5b77-aac3-ae84db9f3528', 'A8A816B3-3238-4931-AC07-FEA3F13DCA05', 'FieldCategoryIcons', '{
  "Consent Details": "fa fa-check-circle",
  "System Metadata": "fa fa-cog"
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Set DefaultForNewUser=false for NEW entity (category: supporting, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = 'A8A816B3-3238-4931-AC07-FEA3F13DCA05';

/* Set categories for 10 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '42BE174F-001B-46C3-87DA-D8DE4DA3EAF4';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.ContactConsentID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent History Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '8EBC64F7-2569-406A-9D63-DF18A3F62E3C';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.NewConsentStatus 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent History Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '2D309D21-4596-4B19-AD7E-07B329DD68AA';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.ConsentStatusAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent History Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '5FAF0E60-3440-4929-B1D2-266957DF9D53';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.ConsentSource 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent History Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '0134E27E-6605-4626-A3C4-2DCEA2435AE6';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.RecordedByUserID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Audit Information',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'A606F530-79BF-47CD-9A0C-DF9360651443';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.RecordedByUser 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Audit Information',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '3C4E6244-1E69-4EE5-9AB4-26EEEC3B22F4';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.Notes 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Audit Information',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '833A5FC5-5EDE-4216-866D-487F523B3FB3';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '0A2CA89D-72AF-4F94-9FE0-F54725C3A4A6';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Consent Histories.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'CD1BC85E-4626-45F5-9EDE-77607617228A';

/* Set entity icon to fa fa-history */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-history', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA';

/* Insert FieldCategoryInfo setting for entity */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA' AND [Name] = 'FieldCategoryInfo'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('74ae6e26-7622-5dc0-9640-248e05efc8c7', '953FD481-ED1D-4B8A-98F7-DD9A85111DBA', 'FieldCategoryInfo', '{
  "Audit Information": {
    "description": "Information about who recorded the consent change and supporting notes.",
    "icon": "fa fa-user-shield"
  },
  "Consent History Details": {
    "description": "Details regarding the consent status change, effective dates, and sources.",
    "icon": "fa fa-history"
  },
  "System Metadata": {
    "description": "System-managed audit and tracking fields.",
    "icon": "fa fa-cog"
  }
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Insert FieldCategoryIcons setting (legacy) */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA' AND [Name] = 'FieldCategoryIcons'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('81a7c8b0-33f0-5013-bb89-a572484f22ac', '953FD481-ED1D-4B8A-98F7-DD9A85111DBA', 'FieldCategoryIcons', '{
  "Audit Information": "fa fa-user-shield",
  "Consent History Details": "fa fa-history",
  "System Metadata": "fa fa-cog"
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Set DefaultForNewUser=false for NEW entity (category: supporting, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = '953FD481-ED1D-4B8A-98F7-DD9A85111DBA';

