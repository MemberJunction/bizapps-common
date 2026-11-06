-- =============================================================================
-- Migration: V202611061600__v5.61.x__Contact_Method_Consent.sql
-- Description: Consent per contact method, per purpose, optionally per organization
--              (plans/contact-consent.md)
--              - ConsentPurpose: what a consent is for (Marketing, Transactional, ...), a lookup
--                like ContactType so a customer adds purposes without DDL
--              - ContactMethodConsent: one current status per contact method, (optional) purpose and
--                (optional) organization: a row with no purpose is the general answer for the
--                address, so one email can say yes in general, no to one purpose, no to one sender
--              - ContactMethodConsentHistory: one row per change on a ContactMethodConsent, with when it
--                took effect and where it came from
--              - ContactType.CommunicationBaseMessageTypeID: which MJ communication channel
--                (Email, Phone, SMS) a contact type carries, so code never matches on names
-- =============================================================================

---------------------------------------------------------------------------
-- ContactType: link each type to MJ's Communication Base Message Type
---------------------------------------------------------------------------
ALTER TABLE [${flyway:defaultSchema}].[ContactType]
    ADD CommunicationBaseMessageTypeID UNIQUEIDENTIFIER NULL;
GO

ALTER TABLE [${flyway:defaultSchema}].[ContactType]
    ADD CONSTRAINT FK_ContactType_CommunicationBaseMessageType FOREIGN KEY (CommunicationBaseMessageTypeID)
        REFERENCES [${mjSchema}].[CommunicationBaseMessageType](ID);
GO

---------------------------------------------------------------------------
-- ConsentPurpose: what a consent is for
---------------------------------------------------------------------------
CREATE TABLE [${flyway:defaultSchema}].[ConsentPurpose] (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    Sequence INT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_ConsentPurpose PRIMARY KEY (ID),
    CONSTRAINT UQ_ConsentPurpose_Name UNIQUE (Name)
);
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'What a consent is for. Common seeds the generic purposes, Marketing and Transactional; apps built on Common add their own. Consent is recorded per contact method and purpose, so one email can be opted in for transactional messages and opted out of marketing. Seeded by metadata; add rows rather than columns.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE', @level1name = N'ConsentPurpose';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Display name of the purpose, unique within the installation.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE', @level1name = N'ConsentPurpose',
    @level2type = N'COLUMN', @level2name = N'Name';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'What kinds of messages this purpose covers.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE', @level1name = N'ConsentPurpose',
    @level2type = N'COLUMN', @level2name = N'Description';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Sort order in dropdown lists. Lower values appear first.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE', @level1name = N'ConsentPurpose',
    @level2type = N'COLUMN', @level2name = N'Sequence';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Whether this purpose is offered for new consents. Inactive purposes are hidden from dropdowns but preserved for existing records.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE', @level1name = N'ConsentPurpose',
    @level2type = N'COLUMN', @level2name = N'IsActive';
GO

---------------------------------------------------------------------------
-- ContactMethodConsent: the current status for one contact method, purpose and (optional) organization
---------------------------------------------------------------------------
CREATE TABLE [${flyway:defaultSchema}].[ContactMethodConsent] (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    ContactMethodID UNIQUEIDENTIFIER NOT NULL,
    ConsentPurposeID UNIQUEIDENTIFIER NULL,
    RequestingOrganizationID UNIQUEIDENTIFIER NULL,
    ConsentStatus NVARCHAR(20) NOT NULL DEFAULT N'Not Specified',
    CONSTRAINT PK_ContactMethodConsent PRIMARY KEY (ID),
    CONSTRAINT FK_ContactMethodConsent_ContactMethod FOREIGN KEY (ContactMethodID)
        REFERENCES [${flyway:defaultSchema}].[ContactMethod](ID)
        ON DELETE CASCADE,
    CONSTRAINT FK_ContactMethodConsent_ConsentPurpose FOREIGN KEY (ConsentPurposeID)
        REFERENCES [${flyway:defaultSchema}].[ConsentPurpose](ID),
    CONSTRAINT FK_ContactMethodConsent_RequestingOrganization FOREIGN KEY (RequestingOrganizationID)
        REFERENCES [${flyway:defaultSchema}].[Organization](ID),
    CONSTRAINT UQ_ContactMethodConsent_Method_Purpose_Organization UNIQUE (ContactMethodID, ConsentPurposeID, RequestingOrganizationID),
    CONSTRAINT CK_ContactMethodConsent_ConsentStatus CHECK (ConsentStatus IN (N'Not Specified', N'Opted In', N'Opted Out'))
);
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'The current consent for one contact method (an email or phone): for one purpose or, when ConsentPurposeID is null, for anything; as asked by one organization or, when RequestingOrganizationID is null, by anyone on the installation. A contact method has many of these, the way a person has many contact methods, and the most specific row answers: purpose and organization, then purpose, then organization, then the general row. ConsentStatus always equals NewConsentStatus on the ContactMethodConsentHistory row with the latest ConsentStatusAt. Set it through ContactPreferenceEngine, which writes the history row with it. Deleting the contact method deletes its consents.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE', @level1name = N'ContactMethodConsent';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'The current consent: Not Specified, Opted In or Opted Out.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE', @level1name = N'ContactMethodConsent',
    @level2type = N'COLUMN', @level2name = N'ConsentStatus';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'The organization that asked for this consent, when the person answered differently for different organizations. Null means the answer applies to anyone on the installation. This is not the owner of the contact method; that is ContactMethod.PersonID or ContactMethod.OrganizationID.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE', @level1name = N'ContactMethodConsent',
    @level2type = N'COLUMN', @level2name = N'RequestingOrganizationID';
GO

---------------------------------------------------------------------------
-- ContactMethodConsentHistory: one row per change on a ContactMethodConsent
---------------------------------------------------------------------------
CREATE TABLE [${flyway:defaultSchema}].[ContactMethodConsentHistory] (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    ContactMethodConsentID UNIQUEIDENTIFIER NOT NULL,
    NewConsentStatus NVARCHAR(20) NOT NULL,
    ConsentStatusAt DATETIMEOFFSET NOT NULL,
    ConsentSource NVARCHAR(50) NOT NULL DEFAULT N'Staff',
    RecordedByUserID UNIQUEIDENTIFIER NULL,
    ConsentDetails NVARCHAR(MAX) NULL,
    CONSTRAINT PK_ContactMethodConsentHistory PRIMARY KEY (ID),
    CONSTRAINT FK_ContactMethodConsentHistory_ContactMethodConsent FOREIGN KEY (ContactMethodConsentID)
        REFERENCES [${flyway:defaultSchema}].[ContactMethodConsent](ID)
        ON DELETE CASCADE,
    CONSTRAINT FK_ContactMethodConsentHistory_RecordedByUser FOREIGN KEY (RecordedByUserID)
        REFERENCES [${mjSchema}].[User](ID),
    CONSTRAINT CK_ContactMethodConsentHistory_NewConsentStatus CHECK (NewConsentStatus IN (N'Not Specified', N'Opted In', N'Opted Out')),
    CONSTRAINT CK_ContactMethodConsentHistory_ConsentSource CHECK (ConsentSource IN (N'Web Form', N'Unsubscribe Link', N'Import', N'Staff', N'Other'))
);
GO

-- The "latest change for this consent" read, which every status resolution does.
CREATE NONCLUSTERED INDEX IX_ContactMethodConsentHistory_ContactMethodConsent_ConsentStatusAt
    ON [${flyway:defaultSchema}].[ContactMethodConsentHistory] (ContactMethodConsentID, ConsentStatusAt DESC);
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'One row per change on a ContactMethodConsent: the status it set, when it took effect in the real world, and where it came from. ContactMethodConsent.ConsentStatus mirrors the row with the latest ConsentStatusAt. A late-arriving change with an older date is kept here but does not change the current status. Deleting the consent deletes its history.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE', @level1name = N'ContactMethodConsentHistory';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'The consent status this change set: Not Specified, Opted In or Opted Out.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE', @level1name = N'ContactMethodConsentHistory',
    @level2type = N'COLUMN', @level2name = N'NewConsentStatus';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'When the change took effect in the real world (the unsubscribe click, the form submission, the import''s own date), not when this row was saved. The row with the latest value is the current status.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE', @level1name = N'ContactMethodConsentHistory',
    @level2type = N'COLUMN', @level2name = N'ConsentStatusAt';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Where the change came from: Web Form, Unsubscribe Link, Import, Staff or Other. Defaults to Staff, for a change made by a person in the app. The specifics, such as which system an import came from or what Other was, go in ConsentDetails.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE', @level1name = N'ContactMethodConsentHistory',
    @level2type = N'COLUMN', @level2name = N'ConsentSource';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'The specifics of the change: which system an import came from, what an Other source was, or evidence such as a form ID or the unsubscribe email''s message ID.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE', @level1name = N'ContactMethodConsentHistory',
    @level2type = N'COLUMN', @level2name = N'ConsentDetails';
GO


















































/* ============================================================================================
   ==== CODEGEN OUTPUT — DO NOT EDIT BELOW THIS LINE ====
   Generated by the MemberJunction CodeGen tool: MJ CLI 6.2.0-edge.4 / CodeGenLib from MJ `next`
   @ cf164901da, includeSchemas ['__mj_BizAppsCommon'], against a database built from migrations
   (through the 5.55 release seed) with metadata/ pushed first (so CHECK validators come from the
   pinned GeneratedCode rows).
   Contains: the Consent Purposes, Contact Method Consents and Contact Method Consent Histories
   entities and their fields, the CommunicationBaseMessageTypeID field on Contact Types, value
   lists and relationships, FK indexes, the regenerated views, CRUD procs and permissions.
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
         '2fb1367b-6f20-45be-af8d-ab205ddb6452',
         'MJ_BizApps_Common: Consent Purposes',
         'Consent Purposes',
         'What a consent is for. Common seeds the generic purposes, Marketing and Transactional; apps built on Common add their own. Consent is recorded per contact method and purpose, so one email can be opted in for transactional messages and opted out of marketing. Seeded by metadata; add rows rather than columns.',
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
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '2fb1367b-6f20-45be-af8d-ab205ddb6452', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Consent Purposes for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('2fb1367b-6f20-45be-af8d-ab205ddb6452' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('2fb1367b-6f20-45be-af8d-ab205ddb6452' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Consent Purposes for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('2fb1367b-6f20-45be-af8d-ab205ddb6452' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('2fb1367b-6f20-45be-af8d-ab205ddb6452' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Consent Purposes for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('2fb1367b-6f20-45be-af8d-ab205ddb6452' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('2fb1367b-6f20-45be-af8d-ab205ddb6452' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to create new entity MJ_BizApps_Common: Contact Method Consents */

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
         '3c3827e7-d90c-4c0f-8e41-2c2a17dafd31',
         'MJ_BizApps_Common: Contact Method Consents',
         'Contact Method Consents',
         'The current consent for one contact method (an email or phone): for one purpose or, when ConsentPurposeID is null, for anything; as asked by one organization or, when RequestingOrganizationID is null, by anyone on the installation. A contact method has many of these, the way a person has many contact methods, and the most specific row answers: purpose and organization, then purpose, then organization, then the general row. ConsentStatus always equals NewConsentStatus on the ContactMethodConsentHistory row with the latest ConsentStatusAt. Set it through ContactPreferenceEngine, which writes the history row with it. Deleting the contact method deletes its consents.',
         NULL,
         'ContactMethodConsent',
         'vwContactMethodConsents',
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

/* SQL generated to add new entity MJ_BizApps_Common: Contact Method Consents to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '3c3827e7-d90c-4c0f-8e41-2c2a17dafd31', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Method Consents for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('3c3827e7-d90c-4c0f-8e41-2c2a17dafd31' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('3c3827e7-d90c-4c0f-8e41-2c2a17dafd31' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Method Consents for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('3c3827e7-d90c-4c0f-8e41-2c2a17dafd31' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('3c3827e7-d90c-4c0f-8e41-2c2a17dafd31' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Method Consents for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('3c3827e7-d90c-4c0f-8e41-2c2a17dafd31' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('3c3827e7-d90c-4c0f-8e41-2c2a17dafd31' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to create new entity MJ_BizApps_Common: Contact Method Consent Histories */

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
         'ca348384-97e9-4a6f-a28b-56dc169c0051',
         'MJ_BizApps_Common: Contact Method Consent Histories',
         'Contact Method Consent Histories',
         'One row per change on a ContactMethodConsent: the status it set, when it took effect in the real world, and where it came from. ContactMethodConsent.ConsentStatus mirrors the row with the latest ConsentStatusAt. A late-arriving change with an older date is kept here but does not change the current status. Deleting the consent deletes its history.',
         NULL,
         'ContactMethodConsentHistory',
         'vwContactMethodConsentHistories',
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

/* SQL generated to add new entity MJ_BizApps_Common: Contact Method Consent Histories to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'ca348384-97e9-4a6f-a28b-56dc169c0051', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Method Consent Histories for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('ca348384-97e9-4a6f-a28b-56dc169c0051' AS uniqueidentifier), CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('ca348384-97e9-4a6f-a28b-56dc169c0051' AS uniqueidentifier) AND [RoleID] = CAST('E0AFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Method Consent Histories for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('ca348384-97e9-4a6f-a28b-56dc169c0051' AS uniqueidentifier), CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('ca348384-97e9-4a6f-a28b-56dc169c0051' AS uniqueidentifier) AND [RoleID] = CAST('DEAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL generated to add new permission for entity MJ_BizApps_Common: Contact Method Consent Histories for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                ([EntityID], [RoleID], [Type], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt])
              SELECT CAST('ca348384-97e9-4a6f-a28b-56dc169c0051' AS uniqueidentifier), CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier), 'Allow', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE()
              WHERE NOT EXISTS (
                SELECT 1 FROM [${mjSchema}].[EntityPermission]
                WHERE [EntityID] = CAST('ca348384-97e9-4a6f-a28b-56dc169c0051' AS uniqueidentifier) AND [RoleID] = CAST('DFAFCCEC-6A37-EF11-86D4-000D3A4E707E' AS uniqueidentifier) AND [Type] = 'Allow'
              );

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ContactMethodConsent */
ALTER TABLE [${flyway:defaultSchema}].[ContactMethodConsent] ADD [__mj_CreatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ContactMethodConsent */
UPDATE [${flyway:defaultSchema}].[ContactMethodConsent] SET [__mj_CreatedAt] = GETUTCDATE() WHERE [__mj_CreatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ContactMethodConsent */
ALTER TABLE [${flyway:defaultSchema}].[ContactMethodConsent] ALTER COLUMN [__mj_CreatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ContactMethodConsent */
ALTER TABLE [${flyway:defaultSchema}].[ContactMethodConsent] ADD CONSTRAINT [DF___mj_BizAppsCommon_ContactMethodConsent___mj_CreatedAt] DEFAULT GETUTCDATE() FOR [__mj_CreatedAt];
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ContactMethodConsent */
ALTER TABLE [${flyway:defaultSchema}].[ContactMethodConsent] ADD [__mj_UpdatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ContactMethodConsent */
UPDATE [${flyway:defaultSchema}].[ContactMethodConsent] SET [__mj_UpdatedAt] = GETUTCDATE() WHERE [__mj_UpdatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ContactMethodConsent */
ALTER TABLE [${flyway:defaultSchema}].[ContactMethodConsent] ALTER COLUMN [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ContactMethodConsent */
ALTER TABLE [${flyway:defaultSchema}].[ContactMethodConsent] ADD CONSTRAINT [DF___mj_BizAppsCommon_ContactMethodConsent___mj_UpdatedAt] DEFAULT GETUTCDATE() FOR [__mj_UpdatedAt];
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ContactMethodConsentHistory */
ALTER TABLE [${flyway:defaultSchema}].[ContactMethodConsentHistory] ADD [__mj_CreatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ContactMethodConsentHistory */
UPDATE [${flyway:defaultSchema}].[ContactMethodConsentHistory] SET [__mj_CreatedAt] = GETUTCDATE() WHERE [__mj_CreatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ContactMethodConsentHistory */
ALTER TABLE [${flyway:defaultSchema}].[ContactMethodConsentHistory] ALTER COLUMN [__mj_CreatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ContactMethodConsentHistory */
ALTER TABLE [${flyway:defaultSchema}].[ContactMethodConsentHistory] ADD CONSTRAINT [DF___mj_BizAppsCommon_ContactMethodConsentHistory___mj_CreatedAt] DEFAULT GETUTCDATE() FOR [__mj_CreatedAt];
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ContactMethodConsentHistory */
ALTER TABLE [${flyway:defaultSchema}].[ContactMethodConsentHistory] ADD [__mj_UpdatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ContactMethodConsentHistory */
UPDATE [${flyway:defaultSchema}].[ContactMethodConsentHistory] SET [__mj_UpdatedAt] = GETUTCDATE() WHERE [__mj_UpdatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ContactMethodConsentHistory */
ALTER TABLE [${flyway:defaultSchema}].[ContactMethodConsentHistory] ALTER COLUMN [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ContactMethodConsentHistory */
ALTER TABLE [${flyway:defaultSchema}].[ContactMethodConsentHistory] ADD CONSTRAINT [DF___mj_BizAppsCommon_ContactMethodConsentHistory___mj_UpdatedAt] DEFAULT GETUTCDATE() FOR [__mj_UpdatedAt];
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

/* SQL text to insert 24 new entity field(s) */

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '63580dc7-71eb-464a-9d9b-69ca81e53e18' OR (EntityID = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND Name = 'ID')) BEGIN
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
            '63580dc7-71eb-464a-9d9b-69ca81e53e18',
            '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- Entity: MJ_BizApps_Common: Contact Method Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'db56ea60-777b-4a0e-abdb-c32089f26ebb' OR (EntityID = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND Name = 'ContactMethodID')) BEGIN
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
            'db56ea60-777b-4a0e-abdb-c32089f26ebb',
            '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- Entity: MJ_BizApps_Common: Contact Method Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '428c56b9-02b4-4042-b3ec-6d94fb052fc7' OR (EntityID = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND Name = 'ConsentPurposeID')) BEGIN
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
            '428c56b9-02b4-4042-b3ec-6d94fb052fc7',
            '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- Entity: MJ_BizApps_Common: Contact Method Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
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
            '2FB1367B-6F20-45BE-AF8D-AB205DDB6452',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'cc1dfbb8-63bc-42ce-a127-36081c6c1f88' OR (EntityID = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND Name = 'RequestingOrganizationID')) BEGIN
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
            'cc1dfbb8-63bc-42ce-a127-36081c6c1f88',
            '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- Entity: MJ_BizApps_Common: Contact Method Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
            'RequestingOrganizationID',
            'Requesting Organization ID',
            'The organization that asked for this consent, when the person answered differently for different organizations. Null means the answer applies to anyone on the installation. This is not the owner of the contact method; that is ContactMethod.PersonID or ContactMethod.OrganizationID.',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '9be6252d-83c6-4635-956c-9098df0e3267' OR (EntityID = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND Name = 'ConsentStatus')) BEGIN
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
            '9be6252d-83c6-4635-956c-9098df0e3267',
            '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- Entity: MJ_BizApps_Common: Contact Method Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
            'ConsentStatus',
            'Consent Status',
            'The current consent: Not Specified, Opted In or Opted Out.',
            'nvarchar',
            40,
            0,
            0,
            0,
            'Not Specified',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8ee39d4d-0833-44e0-89a4-ad99417228b0' OR (EntityID = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND Name = '__mj_CreatedAt')) BEGIN
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
            '8ee39d4d-0833-44e0-89a4-ad99417228b0',
            '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- Entity: MJ_BizApps_Common: Contact Method Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f181e819-0dd8-4d42-b5ce-09ff372059ac' OR (EntityID = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND Name = '__mj_UpdatedAt')) BEGIN
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
            'f181e819-0dd8-4d42-b5ce-09ff372059ac',
            '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- Entity: MJ_BizApps_Common: Contact Method Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f0de470d-3ca4-4984-868c-d2e40e70da6d' OR (EntityID = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND Name = 'ID')) BEGIN
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
            'f0de470d-3ca4-4984-868c-d2e40e70da6d',
            'CA348384-97E9-4A6F-A28B-56DC169C0051', -- Entity: MJ_BizApps_Common: Contact Method Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'd7390a2a-889b-4e17-8acd-6e84473159db' OR (EntityID = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND Name = 'ContactMethodConsentID')) BEGIN
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
            'd7390a2a-889b-4e17-8acd-6e84473159db',
            'CA348384-97E9-4A6F-A28B-56DC169C0051', -- Entity: MJ_BizApps_Common: Contact Method Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
            'ContactMethodConsentID',
            'Contact Method Consent ID',
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
            '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f3731712-44b4-49e6-ae78-6427358aca2f' OR (EntityID = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND Name = 'NewConsentStatus')) BEGIN
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
            'f3731712-44b4-49e6-ae78-6427358aca2f',
            'CA348384-97E9-4A6F-A28B-56DC169C0051', -- Entity: MJ_BizApps_Common: Contact Method Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
            'NewConsentStatus',
            'New Consent Status',
            'The consent status this change set: Not Specified, Opted In or Opted Out.',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '4f09cf64-7ab8-4c54-ab0b-76abb393fce8' OR (EntityID = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND Name = 'ConsentStatusAt')) BEGIN
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
            '4f09cf64-7ab8-4c54-ab0b-76abb393fce8',
            'CA348384-97E9-4A6F-A28B-56DC169C0051', -- Entity: MJ_BizApps_Common: Contact Method Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '3c7ec1d1-f253-4860-9d9b-3be7263bf939' OR (EntityID = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND Name = 'ConsentSource')) BEGIN
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
            '3c7ec1d1-f253-4860-9d9b-3be7263bf939',
            'CA348384-97E9-4A6F-A28B-56DC169C0051', -- Entity: MJ_BizApps_Common: Contact Method Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
            'ConsentSource',
            'Consent Source',
            'Where the change came from: Web Form, Unsubscribe Link, Import, Staff or Other. Defaults to Staff, for a change made by a person in the app. The specifics, such as which system an import came from or what Other was, go in ConsentDetails.',
            'nvarchar',
            100,
            0,
            0,
            0,
            'Staff',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '49a2005b-27b9-4c8a-84c9-50148f4b9284' OR (EntityID = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND Name = 'RecordedByUserID')) BEGIN
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
            '49a2005b-27b9-4c8a-84c9-50148f4b9284',
            'CA348384-97E9-4A6F-A28B-56DC169C0051', -- Entity: MJ_BizApps_Common: Contact Method Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'bb5dd18b-b73d-4c65-bf5b-936c1674f35a' OR (EntityID = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND Name = 'ConsentDetails')) BEGIN
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
            'bb5dd18b-b73d-4c65-bf5b-936c1674f35a',
            'CA348384-97E9-4A6F-A28B-56DC169C0051', -- Entity: MJ_BizApps_Common: Contact Method Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
            'ConsentDetails',
            'Consent Details',
            'The specifics of the change: which system an import came from, what an Other source was, or evidence such as a form ID or the unsubscribe email''s message ID.',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'b05d0298-ef0f-4725-a66b-5c6489c1aceb' OR (EntityID = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND Name = '__mj_CreatedAt')) BEGIN
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
            'b05d0298-ef0f-4725-a66b-5c6489c1aceb',
            'CA348384-97E9-4A6F-A28B-56DC169C0051', -- Entity: MJ_BizApps_Common: Contact Method Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '4b667580-df5e-4b1c-bc4a-0a306f8e2a0e' OR (EntityID = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND Name = '__mj_UpdatedAt')) BEGIN
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
            '4b667580-df5e-4b1c-bc4a-0a306f8e2a0e',
            'CA348384-97E9-4A6F-A28B-56DC169C0051', -- Entity: MJ_BizApps_Common: Contact Method Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '438b7dbe-f13b-42ef-97a3-5d952b58e2e3' OR (EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND Name = 'CommunicationBaseMessageTypeID')) BEGIN
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
            '438b7dbe-f13b-42ef-97a3-5d952b58e2e3',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '7071f4ce-e586-4b98-aa23-fecf40b4eb85' OR (EntityID = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452' AND Name = 'ID')) BEGIN
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
            '7071f4ce-e586-4b98-aa23-fecf40b4eb85',
            '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '0efc615d-26a6-4583-97d0-e92d643b4ded' OR (EntityID = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452' AND Name = 'Name')) BEGIN
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
            '0efc615d-26a6-4583-97d0-e92d643b4ded',
            '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '822c3037-da30-41ef-b10d-b9e545d328f7' OR (EntityID = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452' AND Name = 'Description')) BEGIN
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
            '822c3037-da30-41ef-b10d-b9e545d328f7',
            '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c2d551f0-e612-47be-895c-e9e2d46acd1d' OR (EntityID = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452' AND Name = 'Sequence')) BEGIN
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
            'c2d551f0-e612-47be-895c-e9e2d46acd1d',
            '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452'),
            'Sequence',
            'Sequence',
            'Sort order in dropdown lists. Lower values appear first.',
            'int',
            4,
            10,
            0,
            0,
            '(0)',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '664cccaa-627f-4345-ae53-e37c28731a33' OR (EntityID = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452' AND Name = 'IsActive')) BEGIN
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
            '664cccaa-627f-4345-ae53-e37c28731a33',
            '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f2df4de8-3bdd-4eba-a349-b2efc2d7c362' OR (EntityID = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452' AND Name = '__mj_CreatedAt')) BEGIN
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
            'f2df4de8-3bdd-4eba-a349-b2efc2d7c362',
            '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c22f89cd-2eef-4ff7-bf60-58ccb001354d' OR (EntityID = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452' AND Name = '__mj_UpdatedAt')) BEGIN
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
            'c22f89cd-2eef-4ff7-bf60-58ccb001354d',
            '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', -- Entity: MJ_BizApps_Common: Consent Purposes
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452'),
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

/* SQL text to insert entity field value with ID 074b1447-88b9-427e-ad98-9f963a13dc0d */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('074b1447-88b9-427e-ad98-9f963a13dc0d', '9BE6252D-83C6-4635-956C-9098DF0E3267', 1, 'Not Specified', 'Not Specified', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 62392435-049d-4c73-ae34-bdc63c76bd50 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('62392435-049d-4c73-ae34-bdc63c76bd50', '9BE6252D-83C6-4635-956C-9098DF0E3267', 2, 'Opted In', 'Opted In', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID edf117d1-f532-4862-b995-37d39459ce6f */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('edf117d1-f532-4862-b995-37d39459ce6f', '9BE6252D-83C6-4635-956C-9098DF0E3267', 3, 'Opted Out', 'Opted Out', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 9BE6252D-83C6-4635-956C-9098DF0E3267 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='9BE6252D-83C6-4635-956C-9098DF0E3267';

/* SQL text to insert entity field value with ID b5b7fece-5e09-441a-a045-3f21c0eacb51 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('b5b7fece-5e09-441a-a045-3f21c0eacb51', 'F3731712-44B4-49E6-AE78-6427358ACA2F', 1, 'Not Specified', 'Not Specified', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID c98dc43c-d2e4-4bcf-ac60-a5b286554f9e */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('c98dc43c-d2e4-4bcf-ac60-a5b286554f9e', 'F3731712-44B4-49E6-AE78-6427358ACA2F', 2, 'Opted In', 'Opted In', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID d9fe48fa-2ea7-4274-a1e0-73ad047091a4 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('d9fe48fa-2ea7-4274-a1e0-73ad047091a4', 'F3731712-44B4-49E6-AE78-6427358ACA2F', 3, 'Opted Out', 'Opted Out', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID F3731712-44B4-49E6-AE78-6427358ACA2F */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='F3731712-44B4-49E6-AE78-6427358ACA2F';

/* SQL text to insert entity field value with ID 43af6502-cd4e-435f-ba1f-a3a88f54b5e2 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('43af6502-cd4e-435f-ba1f-a3a88f54b5e2', '3C7EC1D1-F253-4860-9D9B-3BE7263BF939', 1, 'Import', 'Import', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 846b4635-1d55-4af9-9806-417516527a1e */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('846b4635-1d55-4af9-9806-417516527a1e', '3C7EC1D1-F253-4860-9D9B-3BE7263BF939', 2, 'Other', 'Other', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 1400345b-1b40-4cf2-a19b-377e2919e5ce */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('1400345b-1b40-4cf2-a19b-377e2919e5ce', '3C7EC1D1-F253-4860-9D9B-3BE7263BF939', 3, 'Staff', 'Staff', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 49a5d87d-3428-45c9-83be-ca6a499d9fcb */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('49a5d87d-3428-45c9-83be-ca6a499d9fcb', '3C7EC1D1-F253-4860-9D9B-3BE7263BF939', 4, 'Unsubscribe Link', 'Unsubscribe Link', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 0d69f41e-5398-4978-832a-aacf47bfb2b5 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('0d69f41e-5398-4978-832a-aacf47bfb2b5', '3C7EC1D1-F253-4860-9D9B-3BE7263BF939', 5, 'Web Form', 'Web Form', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 3C7EC1D1-F253-4860-9D9B-3BE7263BF939 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='3C7EC1D1-F253-4860-9D9B-3BE7263BF939';

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


/* Create Entity Relationship: MJ_BizApps_Common: Contact Methods -> MJ_BizApps_Common: Contact Method Consents (One To Many via ContactMethodID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'dc918a16-93fb-4cb2-9669-a7356c582d64'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('dc918a16-93fb-4cb2-9669-a7356c582d64', '32C45078-D33B-4760-9BE5-0DF7F483F591', '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', 'ContactMethodID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Contact Method Consents -> MJ_BizApps_Common: Contact Method Consent Histories (One To Many via ContactMethodConsentID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '1e12a43c-69d0-4d63-a353-e6acdbfede03'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('1e12a43c-69d0-4d63-a353-e6acdbfede03', '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', 'CA348384-97E9-4A6F-A28B-56DC169C0051', 'ContactMethodConsentID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ: Users -> MJ_BizApps_Common: Contact Method Consent Histories (One To Many via RecordedByUserID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '7cfc0356-8cce-4b18-bb9c-ef695727b9e4'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('7cfc0356-8cce-4b18-bb9c-ef695727b9e4', 'E1238F34-2837-EF11-86D4-6045BDEE16E6', 'CA348384-97E9-4A6F-A28B-56DC169C0051', 'RecordedByUserID', 'One To Many', 1, 1, 124, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ: Communication Base Message Types -> MJ_BizApps_Common: Contact Types (One To Many via CommunicationBaseMessageTypeID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '707defb9-cc94-4f89-b30c-1cf530aa200c'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('707defb9-cc94-4f89-b30c-1cf530aa200c', '47248F34-2837-EF11-86D4-6045BDEE16E6', '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5', 'CommunicationBaseMessageTypeID', 'One To Many', 1, 1, 3, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Organizations -> MJ_BizApps_Common: Contact Method Consents (One To Many via RequestingOrganizationID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '7dd27fb4-72f5-4b72-93a0-b18024bd20ed'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('7dd27fb4-72f5-4b72-93a0-b18024bd20ed', 'C70448F9-9792-41D7-A82C-784B66429D54', '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', 'RequestingOrganizationID', 'One To Many', 1, 1, 5, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Consent Purposes -> MJ_BizApps_Common: Contact Method Consents (One To Many via ConsentPurposeID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '6a3795e5-5751-48d2-8640-bcefe6a16471'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('6a3795e5-5751-48d2-8640-bcefe6a16471', '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', 'ConsentPurposeID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
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

/* Index for Foreign Keys for ContactMethodConsentHistory */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consent Histories
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key ContactMethodConsentID in table ContactMethodConsentHistory
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactMethodConsentHistory_ContactMethodConsentID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ContactMethodConsentHistory]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactMethodConsentHistory_ContactMethodConsentID ON [${flyway:defaultSchema}].[ContactMethodConsentHistory] ([ContactMethodConsentID]);

-- Index for foreign key RecordedByUserID in table ContactMethodConsentHistory
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactMethodConsentHistory_RecordedByUserID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ContactMethodConsentHistory]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactMethodConsentHistory_RecordedByUserID ON [${flyway:defaultSchema}].[ContactMethodConsentHistory] ([RecordedByUserID]);

/* SQL text to update entity field related entity name field map for entity field ID 49A2005B-27B9-4C8A-84C9-50148F4B9284 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='49A2005B-27B9-4C8A-84C9-50148F4B9284', @RelatedEntityNameFieldMap='RecordedByUser';

/* Index for Foreign Keys for ContactMethodConsent */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consents
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key ContactMethodID in table ContactMethodConsent
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactMethodConsent_ContactMethodID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ContactMethodConsent]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactMethodConsent_ContactMethodID ON [${flyway:defaultSchema}].[ContactMethodConsent] ([ContactMethodID]);

-- Index for foreign key ConsentPurposeID in table ContactMethodConsent
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactMethodConsent_ConsentPurposeID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ContactMethodConsent]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactMethodConsent_ConsentPurposeID ON [${flyway:defaultSchema}].[ContactMethodConsent] ([ConsentPurposeID]);

-- Index for foreign key RequestingOrganizationID in table ContactMethodConsent
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ContactMethodConsent_RequestingOrganizationID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ContactMethodConsent]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ContactMethodConsent_RequestingOrganizationID ON [${flyway:defaultSchema}].[ContactMethodConsent] ([RequestingOrganizationID]);

/* SQL text to update entity field related entity name field map for entity field ID DB56EA60-777B-4A0E-ABDB-C32089F26EBB */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='DB56EA60-777B-4A0E-ABDB-C32089F26EBB', @RelatedEntityNameFieldMap='ContactMethod';

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

/* SQL text to update entity field related entity name field map for entity field ID 438B7DBE-F13B-42EF-97A3-5D952B58E2E3 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='438B7DBE-F13B-42EF-97A3-5D952B58E2E3', @RelatedEntityNameFieldMap='CommunicationBaseMessageType';

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
    @Sequence int = NULL,
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
                [Sequence],
                [IsActive]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                ISNULL(@Sequence, 0),
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
                [Sequence],
                [IsActive]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                ISNULL(@Sequence, 0),
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

/* SQL text to update entity field related entity name field map for entity field ID 428C56B9-02B4-4042-B3EC-6D94FB052FC7 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='428C56B9-02B4-4042-B3EC-6D94FB052FC7', @RelatedEntityNameFieldMap='ConsentPurpose';

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

/* Base View SQL for MJ_BizApps_Common: Contact Method Consent Histories */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consent Histories
-- Item: vwContactMethodConsentHistories
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Contact Method Consent Histories
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ContactMethodConsentHistory
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwContactMethodConsentHistories]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwContactMethodConsentHistories];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwContactMethodConsentHistories]
AS
SELECT
    c.*,
    MJUser_RecordedByUserID.[Name] AS [RecordedByUser]
FROM
    [${flyway:defaultSchema}].[ContactMethodConsentHistory] AS c
LEFT OUTER JOIN
    [${mjSchema}].[User] AS MJUser_RecordedByUserID
  ON
    [c].[RecordedByUserID] = MJUser_RecordedByUserID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwContactMethodConsentHistories] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Contact Method Consent Histories */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consent Histories
-- Item: Permissions for vwContactMethodConsentHistories
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwContactMethodConsentHistories] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Contact Method Consent Histories */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consent Histories
-- Item: spCreateContactMethodConsentHistory
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ContactMethodConsentHistory
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateContactMethodConsentHistory]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateContactMethodConsentHistory];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateContactMethodConsentHistory]
    @ID uniqueidentifier = NULL,
    @ContactMethodConsentID uniqueidentifier,
    @NewConsentStatus nvarchar(20),
    @ConsentStatusAt datetimeoffset,
    @ConsentSource nvarchar(50) = NULL,
    @RecordedByUserID_Clear bit = 0,
    @RecordedByUserID uniqueidentifier = NULL,
    @ConsentDetails_Clear bit = 0,
    @ConsentDetails nvarchar(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ContactMethodConsentHistory]
            (
                [ID],
                [ContactMethodConsentID],
                [NewConsentStatus],
                [ConsentStatusAt],
                [ConsentSource],
                [RecordedByUserID],
                [ConsentDetails]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @ContactMethodConsentID,
                @NewConsentStatus,
                @ConsentStatusAt,
                ISNULL(@ConsentSource, 'Staff'),
                CASE WHEN @RecordedByUserID_Clear = 1 THEN NULL ELSE ISNULL(@RecordedByUserID, NULL) END,
                CASE WHEN @ConsentDetails_Clear = 1 THEN NULL ELSE ISNULL(@ConsentDetails, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ContactMethodConsentHistory]
            (
                [ContactMethodConsentID],
                [NewConsentStatus],
                [ConsentStatusAt],
                [ConsentSource],
                [RecordedByUserID],
                [ConsentDetails]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ContactMethodConsentID,
                @NewConsentStatus,
                @ConsentStatusAt,
                ISNULL(@ConsentSource, 'Staff'),
                CASE WHEN @RecordedByUserID_Clear = 1 THEN NULL ELSE ISNULL(@RecordedByUserID, NULL) END,
                CASE WHEN @ConsentDetails_Clear = 1 THEN NULL ELSE ISNULL(@ConsentDetails, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwContactMethodConsentHistories] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateContactMethodConsentHistory] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Contact Method Consent Histories */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateContactMethodConsentHistory] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Contact Method Consent Histories */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consent Histories
-- Item: spUpdateContactMethodConsentHistory
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

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
        [ConsentDetails] = CASE WHEN @ConsentDetails_Clear = 1 THEN NULL ELSE ISNULL(@ConsentDetails, [ConsentDetails]) END
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
    UPDATE
        [${flyway:defaultSchema}].[ContactMethodConsentHistory]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ContactMethodConsentHistory] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Contact Method Consent Histories */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactMethodConsentHistory] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Contact Method Consent Histories */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consent Histories
-- Item: spDeleteContactMethodConsentHistory
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ContactMethodConsentHistory
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteContactMethodConsentHistory]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteContactMethodConsentHistory];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteContactMethodConsentHistory]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ContactMethodConsentHistory]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteContactMethodConsentHistory] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Contact Method Consent Histories */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteContactMethodConsentHistory] TO [cdp_Developer], [cdp_Integration];

/* SQL text to update entity field related entity name field map for entity field ID CC1DFBB8-63BC-42CE-A127-36081C6C1F88 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='CC1DFBB8-63BC-42CE-A127-36081C6C1F88', @RelatedEntityNameFieldMap='RequestingOrganization';

/* Base View SQL for MJ_BizApps_Common: Contact Method Consents */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consents
-- Item: vwContactMethodConsents
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Contact Method Consents
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ContactMethodConsent
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwContactMethodConsents]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwContactMethodConsents];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwContactMethodConsents]
AS
SELECT
    c.*,
    mjBizAppsCommonContactMethod_ContactMethodID.[Value] AS [ContactMethod],
    mjBizAppsCommonConsentPurpose_ConsentPurposeID.[Name] AS [ConsentPurpose],
    mjBizAppsCommonOrganization_RequestingOrganizationID.[Name] AS [RequestingOrganization]
FROM
    [${flyway:defaultSchema}].[ContactMethodConsent] AS c
INNER JOIN
    [${flyway:defaultSchema}].[ContactMethod] AS mjBizAppsCommonContactMethod_ContactMethodID
  ON
    [c].[ContactMethodID] = mjBizAppsCommonContactMethod_ContactMethodID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ConsentPurpose] AS mjBizAppsCommonConsentPurpose_ConsentPurposeID
  ON
    [c].[ConsentPurposeID] = mjBizAppsCommonConsentPurpose_ConsentPurposeID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Organization] AS mjBizAppsCommonOrganization_RequestingOrganizationID
  ON
    [c].[RequestingOrganizationID] = mjBizAppsCommonOrganization_RequestingOrganizationID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwContactMethodConsents] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Contact Method Consents */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consents
-- Item: Permissions for vwContactMethodConsents
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwContactMethodConsents] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Contact Method Consents */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consents
-- Item: spCreateContactMethodConsent
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ContactMethodConsent
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateContactMethodConsent]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateContactMethodConsent];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateContactMethodConsent]
    @ID uniqueidentifier = NULL,
    @ContactMethodID uniqueidentifier,
    @ConsentPurposeID_Clear bit = 0,
    @ConsentPurposeID uniqueidentifier = NULL,
    @RequestingOrganizationID_Clear bit = 0,
    @RequestingOrganizationID uniqueidentifier = NULL,
    @ConsentStatus nvarchar(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ContactMethodConsent]
            (
                [ID],
                [ContactMethodID],
                [ConsentPurposeID],
                [RequestingOrganizationID],
                [ConsentStatus]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @ContactMethodID,
                CASE WHEN @ConsentPurposeID_Clear = 1 THEN NULL ELSE ISNULL(@ConsentPurposeID, NULL) END,
                CASE WHEN @RequestingOrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@RequestingOrganizationID, NULL) END,
                ISNULL(@ConsentStatus, 'Not Specified')
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ContactMethodConsent]
            (
                [ContactMethodID],
                [ConsentPurposeID],
                [RequestingOrganizationID],
                [ConsentStatus]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ContactMethodID,
                CASE WHEN @ConsentPurposeID_Clear = 1 THEN NULL ELSE ISNULL(@ConsentPurposeID, NULL) END,
                CASE WHEN @RequestingOrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@RequestingOrganizationID, NULL) END,
                ISNULL(@ConsentStatus, 'Not Specified')
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwContactMethodConsents] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateContactMethodConsent] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Contact Method Consents */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateContactMethodConsent] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Contact Method Consents */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consents
-- Item: spUpdateContactMethodConsent
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

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
        [ConsentStatus] = ISNULL(@ConsentStatus, [ConsentStatus])
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
    UPDATE
        [${flyway:defaultSchema}].[ContactMethodConsent]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ContactMethodConsent] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Contact Method Consents */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactMethodConsent] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Contact Method Consents */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Method Consents
-- Item: spDeleteContactMethodConsent
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ContactMethodConsent
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteContactMethodConsent]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteContactMethodConsent];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteContactMethodConsent]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ContactMethodConsent]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteContactMethodConsent] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Contact Method Consents */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteContactMethodConsent] TO [cdp_Developer], [cdp_Integration];

/* SQL text to insert 5 new entity field(s) */

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c220d85b-7d94-4573-8303-4707c8cc3365' OR (EntityID = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND Name = 'ContactMethod')) BEGIN
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
            'c220d85b-7d94-4573-8303-4707c8cc3365',
            '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- Entity: MJ_BizApps_Common: Contact Method Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '394380cc-b0f8-44f0-8f50-46f3f071bf0f' OR (EntityID = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND Name = 'ConsentPurpose')) BEGIN
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
            '394380cc-b0f8-44f0-8f50-46f3f071bf0f',
            '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- Entity: MJ_BizApps_Common: Contact Method Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f2e5756b-f4e8-4fc7-9aa4-a6675516f5c2' OR (EntityID = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND Name = 'RequestingOrganization')) BEGIN
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
            'f2e5756b-f4e8-4fc7-9aa4-a6675516f5c2',
            '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', -- Entity: MJ_BizApps_Common: Contact Method Consents
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31'),
            'RequestingOrganization',
            'Requesting Organization',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'fc1a8169-146e-402e-b165-f70524dfcfc6' OR (EntityID = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND Name = 'RecordedByUser')) BEGIN
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
            'fc1a8169-146e-402e-b165-f70524dfcfc6',
            'CA348384-97E9-4A6F-A28B-56DC169C0051', -- Entity: MJ_BizApps_Common: Contact Method Consent Histories
            (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = 'CA348384-97E9-4A6F-A28B-56DC169C0051'),
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '859c9d5f-5b5c-447b-9f3a-75511e1092c3' OR (EntityID = '7355A5EF-B3BE-4D6D-B48B-5F8FD76F97B5' AND Name = 'CommunicationBaseMessageType')) BEGIN
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
            '859c9d5f-5b5c-447b-9f3a-75511e1092c3',
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

/* Set field properties for entity */

            UPDATE [${mjSchema}].[Entity]
            SET AllowUserSearchAPI = 0
            WHERE ID = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452'
            AND AutoUpdateAllowUserSearchAPI = 1;

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET IsNameField = 1
               WHERE ID = 'F3731712-44B4-49E6-AE78-6427358ACA2F'
               AND AutoUpdateIsNameField = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'FC1A8169-146E-402E-B165-F70524DFCFC6'
               AND AutoUpdateDefaultInView = 1;

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'C220D85B-7D94-4573-8303-4707C8CC3365'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '394380CC-B0F8-44F0-8F50-46F3F071BF0F'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'F2E5756B-F4E8-4FC7-9AA4-A6675516F5C2'
               AND AutoUpdateDefaultInView = 1;

/* Set categories for 7 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '7071F4CE-E586-4B98-AA23-FECF40B4EB85';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.Name 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Purpose Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '0EFC615D-26A6-4583-97D0-E92D643B4DED';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.Description 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Purpose Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '822C3037-DA30-41EF-B10D-B9E545D328F7';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.Sequence 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Purpose Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'C2D551F0-E612-47BE-895C-E9E2D46ACD1D';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.IsActive 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Purpose Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '664CCCAA-627F-4345-AE53-E37C28731A33';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'F2DF4DE8-3BDD-4EBA-A349-B2EFC2D7C362';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Consent Purposes.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'C22F89CD-2EEF-4FF7-BF60-58CCB001354D';

/* Set entity icon to fa fa-shield-alt */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-shield-alt', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452';

/* Insert FieldCategoryInfo setting for entity */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452' AND [Name] = 'FieldCategoryInfo'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('93b873d8-55df-5cac-8b29-421557ac9191', '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', 'FieldCategoryInfo', '{
  "Consent Purpose Details": {
    "description": "Information defining what a consent is for, including display name, description, and display order",
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
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452' AND [Name] = 'FieldCategoryIcons'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('2454944c-9dea-5386-8f6d-4f605e85f22b', '2FB1367B-6F20-45BE-AF8D-AB205DDB6452', 'FieldCategoryIcons', '{
  "Consent Purpose Details": "fa fa-shield-alt",
  "System Metadata": "fa fa-cog"
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Set DefaultForNewUser=false for NEW entity (category: reference, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = '2FB1367B-6F20-45BE-AF8D-AB205DDB6452';

/* Set categories for 10 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'F0DE470D-3CA4-4984-868C-D2E40E70DA6D';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.ContactMethodConsentID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent History Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Contact Method Consent'
WHERE 
   ID = 'D7390A2A-889B-4E17-8ACD-6E84473159DB';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.NewConsentStatus 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent History Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'F3731712-44B4-49E6-AE78-6427358ACA2F';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.ConsentStatusAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent History Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '4F09CF64-7AB8-4C54-AB0B-76ABB393FCE8';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.ConsentSource 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent History Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '3C7EC1D1-F253-4860-9D9B-3BE7263BF939';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.ConsentDetails 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent History Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'BB5DD18B-B73D-4C65-BF5B-936C1674F35A';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.RecordedByUserID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Audit Information',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '49A2005B-27B9-4C8A-84C9-50148F4B9284';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.RecordedByUser 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Audit Information',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'FC1A8169-146E-402E-B165-F70524DFCFC6';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'B05D0298-EF0F-4725-A66B-5C6489C1ACEB';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consent Histories.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '4B667580-DF5E-4B1C-BC4A-0A306F8E2A0E';

/* Set entity icon to fa fa-history */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-history', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = 'CA348384-97E9-4A6F-A28B-56DC169C0051';

/* Insert FieldCategoryInfo setting for entity */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND [Name] = 'FieldCategoryInfo'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('a7fff22b-089c-5bac-ae3d-ad6d8c496e26', 'CA348384-97E9-4A6F-A28B-56DC169C0051', 'FieldCategoryInfo', '{
  "Audit Information": {
    "description": "Information about who recorded the consent change",
    "icon": "fa fa-user-shield"
  },
  "Consent History Details": {
    "description": "Details regarding the consent status change, source, and timing",
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
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = 'CA348384-97E9-4A6F-A28B-56DC169C0051' AND [Name] = 'FieldCategoryIcons'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('308a7695-f2e0-5a75-908b-5a5eae99b618', 'CA348384-97E9-4A6F-A28B-56DC169C0051', 'FieldCategoryIcons', '{
  "Audit Information": "fa fa-user-shield",
  "Consent History Details": "fa fa-history",
  "System Metadata": "fa fa-cog"
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Set DefaultForNewUser=false for NEW entity (category: supporting, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = 'CA348384-97E9-4A6F-A28B-56DC169C0051';

/* Set categories for 2 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Types.CommunicationBaseMessageTypeID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category',
   DisplayName = 'Communication Base Message Type'
WHERE 
   ID = '438B7DBE-F13B-42EF-97A3-5D952B58E2E3';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Types.CommunicationBaseMessageType 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Type Definition',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '859C9D5F-5B5C-447B-9F3A-75511E1092C3';

/* Set categories for 10 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '63580DC7-71EB-464A-9D9B-69CA81E53E18';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.ContactMethodID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Contact Association',
   GeneratedFormSection = 'Category',
   DisplayName = 'Contact Method'
WHERE 
   ID = 'DB56EA60-777B-4A0E-ABDB-C32089F26EBB';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.ConsentPurposeID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '428C56B9-02B4-4042-B3EC-6D94FB052FC7';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.RequestingOrganizationID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'CC1DFBB8-63BC-42CE-A127-36081C6C1F88';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.ConsentStatus 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '9BE6252D-83C6-4635-956C-9098DF0E3267';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '8EE39D4D-0833-44E0-89A4-AD99417228B0';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'F181E819-0DD8-4D42-B5CE-09FF372059AC';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.ContactMethod 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Contact Association',
   GeneratedFormSection = 'Category',
   DisplayName = 'Contact Method Details'
WHERE 
   ID = 'C220D85B-7D94-4573-8303-4707C8CC3365';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.ConsentPurpose 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = '394380CC-B0F8-44F0-8F50-46F3F071BF0F';

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Contact Method Consents.RequestingOrganization 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Consent Details',
   GeneratedFormSection = 'Category'
WHERE 
   ID = 'F2E5756B-F4E8-4FC7-9AA4-A6675516F5C2';

/* Set entity icon to fa fa-shield-alt */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-shield-alt', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31';

/* Insert FieldCategoryInfo setting for entity */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND [Name] = 'FieldCategoryInfo'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('446a62d1-14af-557d-b4ab-bd862b0e8d43', '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', 'FieldCategoryInfo', '{
  "Consent Details": {
    "description": "Details regarding the consent status, purpose, and requesting organization",
    "icon": "fa fa-check-circle"
  },
  "Contact Association": {
    "description": "Information linking the consent to a specific contact method",
    "icon": "fa fa-address-card"
  },
  "System Metadata": {
    "description": "System-managed audit and tracking fields",
    "icon": "fa fa-cog"
  }
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Insert FieldCategoryIcons setting (legacy) */
IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntitySetting] WHERE [EntityID] = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31' AND [Name] = 'FieldCategoryIcons'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('c4acfb14-faad-5be5-adaa-c20819484a38', '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31', 'FieldCategoryIcons', '{
  "Consent Details": "fa fa-check-circle",
  "Contact Association": "fa fa-address-card",
  "System Metadata": "fa fa-cog"
}', GETUTCDATE(), GETUTCDATE())
   END;

/* Set DefaultForNewUser=false for NEW entity (category: supporting, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = '3C3827E7-D90C-4C0F-8E41-2C2A17DAFD31';

