-- =============================================================================
-- v5.35.x — Activities
-- =============================================================================
-- Interaction fact for Common: a phone call, email, meeting, note, SMS, or
-- chat that happened between people, about records. Manual log and mailbox
-- sync write the same graph.
--
-- This is NOT Record Changes (field diffs), NOT MJ CommunicationLog (send
-- plumbing), and NOT Tasks (work to do). Completing a task can later emit
-- an Activity; a Task is not an Activity.
--
-- Tables
--   ActivityType            lookup, hierarchy for the picker only
--   Activity                one row = one interaction (timeline card)
--   ActivityLink            polymorphic attachment + unresolved identity
--   ActivityFile            join to MJ Files (body / attachment / ICS)
--   ActivitySyncConnection  mailbox / Graph / Gmail / Zoom connection
--   ActivitySyncRule        include/exclude filter for a connection
--
-- Seeded Activity Types ship as metadata/activity-types/ (not INSERTs here).
-- PostgreSQL counterpart is deferred to the release build engineer.
-- =============================================================================

---------------------------------------------------------------------------
-- ActivityType
---------------------------------------------------------------------------
CREATE TABLE [${flyway:defaultSchema}].[ActivityType] (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    Code NVARCHAR(50) NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    ParentID UNIQUEIDENTIFIER NULL,
    IconClass NVARCHAR(100) NULL,
    Color NVARCHAR(30) NULL,
    Sequence INT NOT NULL DEFAULT 0,
    IsSystem BIT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_ActivityType PRIMARY KEY (ID),
    CONSTRAINT UQ_ActivityType_Code UNIQUE (Code),
    CONSTRAINT UQ_ActivityType_Name UNIQUE (Name),
    CONSTRAINT FK_ActivityType_Parent FOREIGN KEY (ParentID)
        REFERENCES [${flyway:defaultSchema}].[ActivityType](ID)
);
GO

---------------------------------------------------------------------------
-- ActivitySyncConnection
-- Defined before Activity so Activity can optionally point at the connection
-- that produced it. Secrets never live here — CredentialsRef is an MJ
-- Credentials engine key, same pattern as Orders PaymentProvider.
---------------------------------------------------------------------------
CREATE TABLE [${flyway:defaultSchema}].[ActivitySyncConnection] (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    Name NVARCHAR(200) NOT NULL,
    Provider NVARCHAR(40) NOT NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT N'Active',
    Direction NVARCHAR(20) NOT NULL DEFAULT N'Inbound',
    OwnerUserID UNIQUEIDENTIFIER NOT NULL,
    CredentialsRef NVARCHAR(200) NULL,
    Mailbox NVARCHAR(320) NULL,
    LastSyncAt DATETIMEOFFSET NULL,
    LastError NVARCHAR(MAX) NULL,
    Settings NVARCHAR(MAX) NULL,
    CONSTRAINT PK_ActivitySyncConnection PRIMARY KEY (ID),
    CONSTRAINT UQ_ActivitySyncConnection_Name UNIQUE (Name),
    CONSTRAINT FK_ActivitySyncConnection_OwnerUser FOREIGN KEY (OwnerUserID)
        REFERENCES [${mjSchema}].[User](ID),
    CONSTRAINT CK_ActivitySyncConnection_Provider CHECK (
        Provider IN (N'Microsoft365', N'Gmail', N'Zoom', N'Generic')
    ),
    CONSTRAINT CK_ActivitySyncConnection_Status CHECK (
        Status IN (N'Active', N'Paused', N'Error', N'Disabled')
    ),
    CONSTRAINT CK_ActivitySyncConnection_Direction CHECK (
        Direction IN (N'Inbound', N'Outbound', N'Bidirectional')
    )
);
GO

---------------------------------------------------------------------------
-- Activity
---------------------------------------------------------------------------
CREATE TABLE [${flyway:defaultSchema}].[Activity] (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    ActivityTypeID UNIQUEIDENTIFIER NOT NULL,
    StartedAt DATETIMEOFFSET NOT NULL,
    EndedAt DATETIMEOFFSET NULL,
    Title NVARCHAR(500) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    Direction NVARCHAR(20) NOT NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT N'Logged',
    Outcome NVARCHAR(40) NULL,
    Visibility NVARCHAR(20) NOT NULL DEFAULT N'Internal',
    Source NVARCHAR(20) NOT NULL DEFAULT N'Manual',
    SourceSystem NVARCHAR(80) NULL,
    ExternalID NVARCHAR(400) NULL,
    ExternalThreadID NVARCHAR(400) NULL,
    ParentActivityID UNIQUEIDENTIFIER NULL,
    LoggedByUserID UNIQUEIDENTIFIER NOT NULL,
    Location NVARCHAR(500) NULL,
    AddressID UNIQUEIDENTIFIER NULL,
    ActivitySyncConnectionID UNIQUEIDENTIFIER NULL,
    Details NVARCHAR(MAX) NULL,
    CONSTRAINT PK_Activity PRIMARY KEY (ID),
    CONSTRAINT FK_Activity_Type FOREIGN KEY (ActivityTypeID)
        REFERENCES [${flyway:defaultSchema}].[ActivityType](ID),
    CONSTRAINT FK_Activity_Parent FOREIGN KEY (ParentActivityID)
        REFERENCES [${flyway:defaultSchema}].[Activity](ID),
    CONSTRAINT FK_Activity_LoggedByUser FOREIGN KEY (LoggedByUserID)
        REFERENCES [${mjSchema}].[User](ID),
    CONSTRAINT FK_Activity_Address FOREIGN KEY (AddressID)
        REFERENCES [${flyway:defaultSchema}].[Address](ID),
    CONSTRAINT FK_Activity_SyncConnection FOREIGN KEY (ActivitySyncConnectionID)
        REFERENCES [${flyway:defaultSchema}].[ActivitySyncConnection](ID)
        ON DELETE SET NULL,
    CONSTRAINT CK_Activity_Direction CHECK (
        Direction IN (N'Inbound', N'Outbound', N'Internal')
    ),
    CONSTRAINT CK_Activity_Status CHECK (
        Status IN (N'Logged', N'Scheduled', N'Completed', N'Cancelled', N'Failed')
    ),
    CONSTRAINT CK_Activity_Visibility CHECK (
        Visibility IN (N'Internal', N'Private')
    ),
    CONSTRAINT CK_Activity_Source CHECK (
        Source IN (N'Manual', N'System', N'Integration')
    ),
    CONSTRAINT CK_Activity_Outcome CHECK (
        Outcome IS NULL OR Outcome IN (
            N'Connected', N'LeftVoicemail', N'NoAnswer', N'NoShow',
            N'Bounced', N'Interested', N'NotInterested'
        )
    ),
    CONSTRAINT CK_Activity_EndedAt CHECK (
        EndedAt IS NULL OR EndedAt >= StartedAt
    ),
    CONSTRAINT CK_Activity_External CHECK (
        (ExternalID IS NULL AND SourceSystem IS NULL)
        OR (ExternalID IS NOT NULL AND SourceSystem IS NOT NULL)
    )
);
GO

---------------------------------------------------------------------------
-- ActivityLink
-- Exactly one of: resolved (EntityID + RecordID) XOR unresolved identity.
-- Do not auto-create stub People from unmatched addresses.
---------------------------------------------------------------------------
CREATE TABLE [${flyway:defaultSchema}].[ActivityLink] (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    ActivityID UNIQUEIDENTIFIER NOT NULL,
    Role NVARCHAR(30) NOT NULL,
    EntityID UNIQUEIDENTIFIER NULL,
    RecordID NVARCHAR(450) NULL,
    IdentityKind NVARCHAR(20) NULL,
    IdentityValue NVARCHAR(320) NULL,
    Sequence INT NOT NULL DEFAULT 0,
    CONSTRAINT PK_ActivityLink PRIMARY KEY (ID),
    CONSTRAINT FK_ActivityLink_Activity FOREIGN KEY (ActivityID)
        REFERENCES [${flyway:defaultSchema}].[Activity](ID)
        ON DELETE CASCADE,
    CONSTRAINT FK_ActivityLink_Entity FOREIGN KEY (EntityID)
        REFERENCES [${mjSchema}].[Entity](ID),
    CONSTRAINT CK_ActivityLink_Role CHECK (
        Role IN (
            N'Regarding', N'Participant',
            N'From', N'To', N'Cc', N'Bcc',
            N'Organizer', N'Attendee',
            N'LoggedFor'
        )
    ),
    CONSTRAINT CK_ActivityLink_IdentityKind CHECK (
        IdentityKind IS NULL OR IdentityKind IN (N'Email', N'Phone', N'ExternalUser')
    ),
    CONSTRAINT CK_ActivityLink_Target CHECK (
        (
            EntityID IS NOT NULL AND RecordID IS NOT NULL
            AND IdentityKind IS NULL AND IdentityValue IS NULL
        )
        OR
        (
            EntityID IS NULL AND RecordID IS NULL
            AND IdentityKind IS NOT NULL AND IdentityValue IS NOT NULL
        )
    )
);
GO

---------------------------------------------------------------------------
-- ActivityFile
-- Join only. The MJ File row owns the bytes; deleting an Activity drops
-- the join, not the File.
---------------------------------------------------------------------------
CREATE TABLE [${flyway:defaultSchema}].[ActivityFile] (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    ActivityID UNIQUEIDENTIFIER NOT NULL,
    FileID UNIQUEIDENTIFIER NOT NULL,
    Kind NVARCHAR(20) NOT NULL,
    Sequence INT NOT NULL DEFAULT 0,
    CONSTRAINT PK_ActivityFile PRIMARY KEY (ID),
    CONSTRAINT FK_ActivityFile_Activity FOREIGN KEY (ActivityID)
        REFERENCES [${flyway:defaultSchema}].[Activity](ID)
        ON DELETE CASCADE,
    CONSTRAINT FK_ActivityFile_File FOREIGN KEY (FileID)
        REFERENCES [${mjSchema}].[File](ID),
    CONSTRAINT UQ_ActivityFile_ActivityFile UNIQUE (ActivityID, FileID),
    CONSTRAINT CK_ActivityFile_Kind CHECK (
        Kind IN (N'Body', N'Attachment', N'Ics')
    )
);
GO

---------------------------------------------------------------------------
-- ActivitySyncRule
---------------------------------------------------------------------------
CREATE TABLE [${flyway:defaultSchema}].[ActivitySyncRule] (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    ActivitySyncConnectionID UNIQUEIDENTIFIER NOT NULL,
    Name NVARCHAR(200) NOT NULL,
    IsEnabled BIT NOT NULL DEFAULT 1,
    Sequence INT NOT NULL DEFAULT 0,
    Action NVARCHAR(20) NOT NULL DEFAULT N'Include',
    ActivityTypeID UNIQUEIDENTIFIER NULL,
    Direction NVARCHAR(20) NULL,
    DateFrom DATETIMEOFFSET NULL,
    DateTo DATETIMEOFFSET NULL,
    IncludeAttachments BIT NOT NULL DEFAULT 0,
    Filter NVARCHAR(MAX) NULL,
    CONSTRAINT PK_ActivitySyncRule PRIMARY KEY (ID),
    CONSTRAINT FK_ActivitySyncRule_Connection FOREIGN KEY (ActivitySyncConnectionID)
        REFERENCES [${flyway:defaultSchema}].[ActivitySyncConnection](ID)
        ON DELETE CASCADE,
    CONSTRAINT FK_ActivitySyncRule_ActivityType FOREIGN KEY (ActivityTypeID)
        REFERENCES [${flyway:defaultSchema}].[ActivityType](ID),
    CONSTRAINT CK_ActivitySyncRule_Action CHECK (
        Action IN (N'Include', N'Exclude')
    ),
    CONSTRAINT CK_ActivitySyncRule_Direction CHECK (
        Direction IS NULL OR Direction IN (N'Inbound', N'Outbound', N'Internal')
    ),
    CONSTRAINT CK_ActivitySyncRule_DateWindow CHECK (
        DateFrom IS NULL OR DateTo IS NULL OR DateTo >= DateFrom
    )
);
GO

---------------------------------------------------------------------------
-- Indexes that are NOT "just the FK" (CodeGen owns IDX_AUTO_MJ_FKEY_*)
---------------------------------------------------------------------------
CREATE UNIQUE NONCLUSTERED INDEX UQ_Activity_External
    ON [${flyway:defaultSchema}].[Activity] (SourceSystem, ExternalID)
    WHERE ExternalID IS NOT NULL;
GO

CREATE NONCLUSTERED INDEX IX_Activity_StartedAt
    ON [${flyway:defaultSchema}].[Activity] (StartedAt DESC);
GO

CREATE NONCLUSTERED INDEX IX_Activity_TypeStarted
    ON [${flyway:defaultSchema}].[Activity] (ActivityTypeID, StartedAt DESC);
GO

CREATE NONCLUSTERED INDEX IX_Activity_LoggedByStarted
    ON [${flyway:defaultSchema}].[Activity] (LoggedByUserID, StartedAt DESC);
GO

CREATE NONCLUSTERED INDEX IX_Activity_ExternalThread
    ON [${flyway:defaultSchema}].[Activity] (ExternalThreadID)
    WHERE ExternalThreadID IS NOT NULL;
GO

CREATE NONCLUSTERED INDEX IX_Activity_Parent
    ON [${flyway:defaultSchema}].[Activity] (ParentActivityID)
    WHERE ParentActivityID IS NOT NULL;
GO

CREATE UNIQUE NONCLUSTERED INDEX UQ_ActivityLink_Resolved
    ON [${flyway:defaultSchema}].[ActivityLink] (ActivityID, Role, EntityID, RecordID)
    WHERE EntityID IS NOT NULL;
GO

CREATE UNIQUE NONCLUSTERED INDEX UQ_ActivityLink_Unresolved
    ON [${flyway:defaultSchema}].[ActivityLink] (ActivityID, Role, IdentityKind, IdentityValue)
    WHERE IdentityKind IS NOT NULL;
GO

CREATE NONCLUSTERED INDEX IX_ActivityLink_EntityRecord
    ON [${flyway:defaultSchema}].[ActivityLink] (EntityID, RecordID)
    WHERE EntityID IS NOT NULL;
GO

CREATE NONCLUSTERED INDEX IX_ActivityLink_Identity
    ON [${flyway:defaultSchema}].[ActivityLink] (IdentityKind, IdentityValue)
    WHERE IdentityKind IS NOT NULL;
GO

CREATE UNIQUE NONCLUSTERED INDEX UQ_ActivityFile_Body
    ON [${flyway:defaultSchema}].[ActivityFile] (ActivityID)
    WHERE Kind = N'Body';
GO

CREATE NONCLUSTERED INDEX IX_ActivitySyncRule_ConnectionSequence
    ON [${flyway:defaultSchema}].[ActivitySyncRule] (ActivitySyncConnectionID, Sequence);
GO

---------------------------------------------------------------------------
-- Table descriptions
---------------------------------------------------------------------------
EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Lookup of interaction channels (Email, Call, Meeting, Note, SMS, Chat). Hierarchy is picker-only; direction lives on Activity. Code is the stable key — sync and code target Code, never Name.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivityType';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'One interaction that happened between people, about records. Timeline card — not a blob store, not a task, not field-level audit. Duration is derived from StartedAt/EndedAt.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'Activity';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Attaches an Activity to a resolved MJ record (EntityID + RecordID) or an unresolved identity (email/phone/external user) the matcher has not stamped yet. Role says whether the link is Regarding, a participant, or an email/meeting mailbox role.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivityLink';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Join from an Activity to an MJ File. Kind Body is the full MIME/HTML (at most one per activity); Attachment and Ics are extras. Deleting the activity drops the join, not the File.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivityFile';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'A mailbox, calendar, or other provider connection that writes Activities. CredentialsRef is an MJ Credentials engine key — never a secret at rest.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncConnection';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Include/exclude rule for an ActivitySyncConnection: type, direction, date window, attachments, plus a JSON Filter (folders, domains, participant-must-match-ContactMethod).',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncRule';
GO

---------------------------------------------------------------------------
-- Column descriptions (skip PK and FK — CodeGen owns those)
---------------------------------------------------------------------------
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Stable key targeted by sync and code (Email, Call, Meeting, Note, SMS, Chat). Unique. Names can be renamed; codes cannot.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivityType', @level2type=N'COLUMN', @level2name=N'Code';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Display name for the picker and timeline.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivityType', @level2type=N'COLUMN', @level2name=N'Name';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Optional longer description of the type.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivityType', @level2type=N'COLUMN', @level2name=N'Description';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Font Awesome class for timeline chrome (e.g. fa-solid fa-envelope).',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivityType', @level2type=N'COLUMN', @level2name=N'IconClass';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Optional categorical color for timeline chrome. Not a design-token — this is stored per type.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivityType', @level2type=N'COLUMN', @level2name=N'Color';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Picker sort order. Lower first.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivityType', @level2type=N'COLUMN', @level2name=N'Sequence';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'1 = seeded system type the sync engine may assume (Email, Call, Meeting, Note, SMS, Chat). Clients add children with IsSystem = 0.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivityType', @level2type=N'COLUMN', @level2name=N'IsSystem';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'0 hides the type from the picker without deleting historical activities.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivityType', @level2type=N'COLUMN', @level2name=N'IsActive';
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Sort key for every timeline. Instant events use the date/time of the event.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Activity', @level2type=N'COLUMN', @level2name=N'StartedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'End of a meeting/call. Leave null for a point-in-time log. Must be >= StartedAt when set. Duration is derived; do not store it.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Activity', @level2type=N'COLUMN', @level2name=N'EndedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Subject / one-line card title (e.g. Called Jane about renewal).',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Activity', @level2type=N'COLUMN', @level2name=N'Title';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Notes or a short excerpt. Not the full email body — that lives on an ActivityFile of Kind Body.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Activity', @level2type=N'COLUMN', @level2name=N'Description';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Inbound, Outbound, or Internal. Channel lives on ActivityType; direction lives here so inbound email is a filter, not a type explosion.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Activity', @level2type=N'COLUMN', @level2name=N'Direction';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Logged (default for a past event), Scheduled, Completed, Cancelled, or Failed.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Activity', @level2type=N'COLUMN', @level2name=N'Status';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Optional disposition: Connected, LeftVoicemail, NoAnswer, NoShow, Bounced, Interested, NotInterested. A filter, not a type.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Activity', @level2type=N'COLUMN', @level2name=N'Outcome';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Internal (anyone who can read a Regarding record) or Private (LoggedByUserID only, until a PermissionEngine domain exists). Manual default is Internal; synced mail should default Private in the engine.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Activity', @level2type=N'COLUMN', @level2name=N'Visibility';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'How the row was written: Manual, System, or Integration.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Activity', @level2type=N'COLUMN', @level2name=N'Source';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Provider name for idempotent sync (Microsoft365, Gmail, Zoom). Required when ExternalID is set.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Activity', @level2type=N'COLUMN', @level2name=N'SourceSystem';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Provider message/event id. Unique with SourceSystem where set — never dedup by subject.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Activity', @level2type=N'COLUMN', @level2name=N'ExternalID';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Email or calendar thread id used to group replies.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Activity', @level2type=N'COLUMN', @level2name=N'ExternalThreadID';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Meeting place as text. Optional AddressID is the structured location.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Activity', @level2type=N'COLUMN', @level2name=N'Location';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'JSON extras that are not query predicates: MessageID, InReplyTo, MeetingURL, Mailbox, Folder, CalendarEventID. See ActivityDetails.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'Activity', @level2type=N'COLUMN', @level2name=N'Details';
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Why this record is on the activity: Regarding (what it is about), Participant, From/To/Cc/Bcc, Organizer/Attendee, or LoggedFor (the mailbox it was filed under).',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivityLink', @level2type=N'COLUMN', @level2name=N'Role';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key of the resolved record. NVARCHAR so composite keys work. Required with EntityID; must be null when the link is an unresolved identity.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivityLink', @level2type=N'COLUMN', @level2name=N'RecordID';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Email, Phone, or ExternalUser. Set with IdentityValue when the participant has not been matched to a Person/Org yet.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivityLink', @level2type=N'COLUMN', @level2name=N'IdentityKind';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'The unmatched address, phone, or provider user id. A later matcher stamps EntityID/RecordID from ContactMethod.Value and clears these.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivityLink', @level2type=N'COLUMN', @level2name=N'IdentityValue';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Display order within a role (To, then Cc, …).',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivityLink', @level2type=N'COLUMN', @level2name=N'Sequence';
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Body (full MIME/HTML, at most one per activity), Attachment, or Ics.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivityFile', @level2type=N'COLUMN', @level2name=N'Kind';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Display order of attachments.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivityFile', @level2type=N'COLUMN', @level2name=N'Sequence';
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Display name of the connection (e.g. Amith / Microsoft 365).',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivitySyncConnection', @level2type=N'COLUMN', @level2name=N'Name';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Microsoft365, Gmail, Zoom, or Generic. Widen the CHECK when a new first-class provider lands.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivitySyncConnection', @level2type=N'COLUMN', @level2name=N'Provider';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Active, Paused, Error, or Disabled.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivitySyncConnection', @level2type=N'COLUMN', @level2name=N'Status';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Inbound (pull into CRM), Outbound, or Bidirectional.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivitySyncConnection', @level2type=N'COLUMN', @level2name=N'Direction';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'MJ Credentials engine key. NEVER a secret value at rest.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivitySyncConnection', @level2type=N'COLUMN', @level2name=N'CredentialsRef';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Mailbox address this connection reads (jane@acme.com).',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivitySyncConnection', @level2type=N'COLUMN', @level2name=N'Mailbox';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'When the engine last completed a sync for this connection.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivitySyncConnection', @level2type=N'COLUMN', @level2name=N'LastSyncAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Most recent sync error, if Status is Error.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivitySyncConnection', @level2type=N'COLUMN', @level2name=N'LastError';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'JSON provider extras (TenantID, MailboxFolder, CalendarID, IncludeCalendar, IncludeMail). See ActivitySyncConnectionSettings.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivitySyncConnection', @level2type=N'COLUMN', @level2name=N'Settings';
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Display name of the rule.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivitySyncRule', @level2type=N'COLUMN', @level2name=N'Name';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'0 skips the rule without deleting it.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivitySyncRule', @level2type=N'COLUMN', @level2name=N'IsEnabled';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Evaluation order within the connection. Lower first.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivitySyncRule', @level2type=N'COLUMN', @level2name=N'Sequence';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Include or Exclude matching items. With no rules, the engine syncs everything the connection can see.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivitySyncRule', @level2type=N'COLUMN', @level2name=N'Action';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Optional direction filter (Inbound / Outbound / Internal). Null = any.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivitySyncRule', @level2type=N'COLUMN', @level2name=N'Direction';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Inclusive lower bound of the sync window. Null = no lower bound.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivitySyncRule', @level2type=N'COLUMN', @level2name=N'DateFrom';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Inclusive upper bound of the sync window. Null = no upper bound.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivitySyncRule', @level2type=N'COLUMN', @level2name=N'DateTo';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'1 = also pull attachments into ActivityFile rows.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivitySyncRule', @level2type=N'COLUMN', @level2name=N'IncludeAttachments';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'JSON match extras: Folders, ExcludeFolders, Domains, ExcludeDomains, ParticipantMustMatchContactMethod, SubjectContains, SubjectExcludes. See ActivitySyncRuleFilter.',
    @level0type=N'SCHEMA', @level0name=N'${flyway:defaultSchema}', @level1type=N'TABLE', @level1name=N'ActivitySyncRule', @level2type=N'COLUMN', @level2name=N'Filter';
GO
