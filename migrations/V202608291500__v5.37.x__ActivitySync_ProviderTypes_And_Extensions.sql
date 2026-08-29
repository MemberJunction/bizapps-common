-- =============================================================================
-- v5.37.x — Activity Sync: provider types, rule sets, run log, and extensions
-- =============================================================================
-- Everything the Activity Sync Engine needs that is CONFIGURATION rather than
-- CODE. Design of record: plans/activity-sync-engine.md
--
-- Six things become data that were previously either impossible or hardcoded:
--
--   1. ActivitySyncProviderType  — provider identity. Replaces
--      CK_ActivitySyncConnection_Provider, whose value list made every new
--      source (Twilio, WhatsApp, LinkedIn, X, Izzy) a MIGRATION TO COMMON.
--
--   2. ActivitySyncRuleSet       — a NAMED, REUSABLE set of rules bound to many
--      connections. Rules were per-connection and NOT NULL, so an org-wide
--      prohibition had to be retyped on every mailbox and a new mailbox began
--      with none. Governance rules must be inherited, not copy-pasted.
--
--   3. ActivitySyncExclusion     — never-ingest list, per identity (email,
--      phone, social handle, whole domain), optionally bound to a Person.
--      A legal hold has to be provable, so this is queryable rows and not a
--      comma-delimited string.
--
--   4. ActivitySyncRun / ...RunDetail — what a sync did, and the decision made
--      about EVERY message including the ones it skipped. This is what makes
--      "why did my email not appear" answerable, and it is where an LLM
--      qualification decision and its AIPromptRun are recorded.
--
--   5. ActivitySyncExtension     — in-process enrichment plugins. Common ships
--      the table; each consumer app ships its own rows.
--
--   6. Storage + retention policy — attachments go to MJ Storage, and captured
--      content on a SKIPPED message is encrypted with an MJ Encryption Key.
--      Both are defaulted per PROVIDER TYPE and overridable per CONNECTION, so
--      an operator configures them once rather than per mailbox.
--
-- Nothing here seeds rows. Provider types and system rule sets ship as
-- metadata/, never as INSERTs. CodeGen output is appended below the banner
-- in THIS file so a host that only runs mj migrate still gets entities,
-- views, and SPs. Two files can be applied out of order; one file cannot.
--
-- PostgreSQL counterpart is deferred to the release build engineer.
-- =============================================================================

---------------------------------------------------------------------------
-- ActivitySyncProviderType
---------------------------------------------------------------------------
CREATE TABLE [${flyway:defaultSchema}].[ActivitySyncProviderType] (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    Code NVARCHAR(60) NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    DriverClass NVARCHAR(200) NULL,
    IconClass NVARCHAR(100) NULL,
    SupportedKinds NVARCHAR(MAX) NULL,
    DefaultQualificationPolicy NVARCHAR(20) NOT NULL DEFAULT N'Exclude',
    DefaultSkippedContentPolicy NVARCHAR(20) NOT NULL DEFAULT N'None',
    DefaultEncryptionKeyID UNIQUEIDENTIFIER NULL,
    DefaultStorageProviderID UNIQUEIDENTIFIER NULL,
    DefaultMaxAttachmentBytes BIGINT NULL,
    Sequence INT NOT NULL DEFAULT 0,
    IsSystem BIT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_ActivitySyncProviderType PRIMARY KEY (ID),
    CONSTRAINT UQ_ActivitySyncProviderType_Code UNIQUE (Code),
    CONSTRAINT UQ_ActivitySyncProviderType_Name UNIQUE (Name),
    CONSTRAINT FK_ActivitySyncProviderType_EncryptionKey FOREIGN KEY (DefaultEncryptionKeyID)
        REFERENCES [${mjSchema}].[EncryptionKey](ID),
    CONSTRAINT FK_ActivitySyncProviderType_StorageProvider FOREIGN KEY (DefaultStorageProviderID)
        REFERENCES [${mjSchema}].[FileStorageProvider](ID),
    CONSTRAINT CK_ActivitySyncProviderType_QualPolicy CHECK (
        DefaultQualificationPolicy IN (N'Include', N'Exclude')
    ),
    CONSTRAINT CK_ActivitySyncProviderType_SkippedPolicy CHECK (
        DefaultSkippedContentPolicy IN (N'None', N'SubjectEncrypted', N'FullEncrypted')
    ),
    CONSTRAINT CK_ActivitySyncProviderType_MaxBytes CHECK (
        DefaultMaxAttachmentBytes IS NULL OR DefaultMaxAttachmentBytes > 0
    ),
    -- Capturing content from a message we declined to ingest is only permissible
    -- encrypted. Without a key there is nowhere safe to put it.
    CONSTRAINT CK_ActivitySyncProviderType_KeyRequired CHECK (
        DefaultSkippedContentPolicy = N'None' OR DefaultEncryptionKeyID IS NOT NULL
    )
);
GO

---------------------------------------------------------------------------
-- ActivitySyncRuleSet
--
-- InternalDomains is what makes an internal/external rule expressible at all:
-- "internal" is not a property of a message, it is a property of THIS
-- deployment. It lives on the rule set rather than the connection so one
-- definition serves every mailbox bound to it.
---------------------------------------------------------------------------
CREATE TABLE [${flyway:defaultSchema}].[ActivitySyncRuleSet] (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    ActivitySyncProviderTypeID UNIQUEIDENTIFIER NULL,
    InternalDomains NVARCHAR(MAX) NULL,
    Sequence INT NOT NULL DEFAULT 0,
    IsEnabled BIT NOT NULL DEFAULT 1,
    IsSystem BIT NOT NULL DEFAULT 0,
    CONSTRAINT PK_ActivitySyncRuleSet PRIMARY KEY (ID),
    CONSTRAINT UQ_ActivitySyncRuleSet_Name UNIQUE (Name),
    CONSTRAINT FK_ActivitySyncRuleSet_ProviderType FOREIGN KEY (ActivitySyncProviderTypeID)
        REFERENCES [${flyway:defaultSchema}].[ActivitySyncProviderType](ID)
);
GO

---------------------------------------------------------------------------
-- ActivitySyncConnectionRuleSet — many-to-many, ordered
--
-- Many-to-many rather than a single FK so a connection composes: an org-wide
-- baseline set, plus a team overlay, plus anything specific to that mailbox.
-- That is the whole point — a rule is authored once and bound many times.
---------------------------------------------------------------------------
CREATE TABLE [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet] (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    ActivitySyncConnectionID UNIQUEIDENTIFIER NOT NULL,
    ActivitySyncRuleSetID UNIQUEIDENTIFIER NOT NULL,
    Sequence INT NOT NULL DEFAULT 0,
    IsEnabled BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_ActivitySyncConnectionRuleSet PRIMARY KEY (ID),
    CONSTRAINT UQ_ActivitySyncConnectionRuleSet UNIQUE (ActivitySyncConnectionID, ActivitySyncRuleSetID),
    CONSTRAINT FK_ActivitySyncConnectionRuleSet_Connection FOREIGN KEY (ActivitySyncConnectionID)
        REFERENCES [${flyway:defaultSchema}].[ActivitySyncConnection](ID)
        ON DELETE CASCADE,
    CONSTRAINT FK_ActivitySyncConnectionRuleSet_RuleSet FOREIGN KEY (ActivitySyncRuleSetID)
        REFERENCES [${flyway:defaultSchema}].[ActivitySyncRuleSet](ID)
);
GO

---------------------------------------------------------------------------
-- ActivitySyncExclusion
--
-- Rows, not a comma-delimited column: an exclusion list you cannot query is
-- not auditable, and this is exactly what a legal hold or an opt-out has to be
-- able to prove. PersonID is optional because an address may be excluded
-- before anyone knows whose it is — and because a Person has several
-- ContactMethods, so the identity is the durable key, not the record.
---------------------------------------------------------------------------
CREATE TABLE [${flyway:defaultSchema}].[ActivitySyncExclusion] (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    ActivitySyncRuleSetID UNIQUEIDENTIFIER NULL,
    IdentityKind NVARCHAR(20) NOT NULL,
    IdentityValue NVARCHAR(320) NOT NULL,
    PersonID UNIQUEIDENTIFIER NULL,
    Reason NVARCHAR(MAX) NULL,
    EffectiveFrom DATETIMEOFFSET NULL,
    EffectiveTo DATETIMEOFFSET NULL,
    IsEnabled BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_ActivitySyncExclusion PRIMARY KEY (ID),
    CONSTRAINT UQ_ActivitySyncExclusion UNIQUE (ActivitySyncRuleSetID, IdentityKind, IdentityValue),
    CONSTRAINT FK_ActivitySyncExclusion_RuleSet FOREIGN KEY (ActivitySyncRuleSetID)
        REFERENCES [${flyway:defaultSchema}].[ActivitySyncRuleSet](ID)
        ON DELETE CASCADE,
    CONSTRAINT FK_ActivitySyncExclusion_Person FOREIGN KEY (PersonID)
        REFERENCES [${flyway:defaultSchema}].[Person](ID),
    CONSTRAINT CK_ActivitySyncExclusion_IdentityKind CHECK (
        IdentityKind IN (N'Email', N'Phone', N'Handle', N'Domain')
    ),
    CONSTRAINT CK_ActivitySyncExclusion_Window CHECK (
        EffectiveFrom IS NULL OR EffectiveTo IS NULL OR EffectiveTo >= EffectiveFrom
    )
);
GO

---------------------------------------------------------------------------
-- ActivitySyncRun — one sync pass over one connection
---------------------------------------------------------------------------
CREATE TABLE [${flyway:defaultSchema}].[ActivitySyncRun] (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    ActivitySyncConnectionID UNIQUEIDENTIFIER NOT NULL,
    StartedAt DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    EndedAt DATETIMEOFFSET NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT N'Running',
    TriggerType NVARCHAR(20) NOT NULL DEFAULT N'Scheduled',
    IsDryRun BIT NOT NULL DEFAULT 0,
    Fetched INT NOT NULL DEFAULT 0,
    Included INT NOT NULL DEFAULT 0,
    Excluded INT NOT NULL DEFAULT 0,
    Duplicates INT NOT NULL DEFAULT 0,
    Failed INT NOT NULL DEFAULT 0,
    ExtensionErrors INT NOT NULL DEFAULT 0,
    WatermarkBefore DATETIMEOFFSET NULL,
    WatermarkAfter DATETIMEOFFSET NULL,
    ErrorMessage NVARCHAR(MAX) NULL,
    CONSTRAINT PK_ActivitySyncRun PRIMARY KEY (ID),
    CONSTRAINT FK_ActivitySyncRun_Connection FOREIGN KEY (ActivitySyncConnectionID)
        REFERENCES [${flyway:defaultSchema}].[ActivitySyncConnection](ID)
        ON DELETE CASCADE,
    CONSTRAINT CK_ActivitySyncRun_Status CHECK (
        Status IN (N'Running', N'Completed', N'Failed', N'Cancelled')
    ),
    CONSTRAINT CK_ActivitySyncRun_TriggerType CHECK (
        TriggerType IN (N'Scheduled', N'Manual', N'Webhook', N'Backfill')
    ),
    -- A dry run evaluates and reports; it never writes an Activity and never
    -- moves the connection forward. Enforced here so a bug cannot claim it did.
    CONSTRAINT CK_ActivitySyncRun_DryRunNoWatermark CHECK (
        IsDryRun = 0 OR WatermarkAfter IS NULL
    )
);
GO

---------------------------------------------------------------------------
-- ActivitySyncRunDetail — the decision made about ONE message
--
-- Written for EVERY item the run considered, including every skip. ExternalID
-- and the decision are always safe to keep: they are opaque provider ids and
-- the name of a rule, not content.
--
-- CapturedContent is different in kind and is treated that way: it exists only
-- when the effective SkippedContentPolicy allows it, it is ALWAYS ciphertext,
-- and the key that opens it is named on the row. Give this entity permissions
-- distinct from Activity — the whole point is that it may hold fragments of
-- messages that were deliberately NOT ingested.
---------------------------------------------------------------------------
CREATE TABLE [${flyway:defaultSchema}].[ActivitySyncRunDetail] (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    ActivitySyncRunID UNIQUEIDENTIFIER NOT NULL,
    ExternalID NVARCHAR(400) NOT NULL,
    ExternalThreadID NVARCHAR(400) NULL,
    OccurredAt DATETIMEOFFSET NULL,
    Decision NVARCHAR(20) NOT NULL,
    DecidedByStage NVARCHAR(100) NULL,
    ActivitySyncRuleID UNIQUEIDENTIFIER NULL,
    ActivitySyncExclusionID UNIQUEIDENTIFIER NULL,
    Reason NVARCHAR(MAX) NULL,
    Confidence DECIMAL(5, 4) NULL,
    AIPromptRunID UNIQUEIDENTIFIER NULL,
    ActivityID UNIQUEIDENTIFIER NULL,
    CapturedContent NVARCHAR(MAX) NULL,
    EncryptionKeyID UNIQUEIDENTIFIER NULL,
    CONSTRAINT PK_ActivitySyncRunDetail PRIMARY KEY (ID),
    CONSTRAINT FK_ActivitySyncRunDetail_Run FOREIGN KEY (ActivitySyncRunID)
        REFERENCES [${flyway:defaultSchema}].[ActivitySyncRun](ID)
        ON DELETE CASCADE,
    CONSTRAINT FK_ActivitySyncRunDetail_Rule FOREIGN KEY (ActivitySyncRuleID)
        REFERENCES [${flyway:defaultSchema}].[ActivitySyncRule](ID),
    CONSTRAINT FK_ActivitySyncRunDetail_Exclusion FOREIGN KEY (ActivitySyncExclusionID)
        REFERENCES [${flyway:defaultSchema}].[ActivitySyncExclusion](ID),
    CONSTRAINT FK_ActivitySyncRunDetail_Activity FOREIGN KEY (ActivityID)
        REFERENCES [${flyway:defaultSchema}].[Activity](ID),
    CONSTRAINT FK_ActivitySyncRunDetail_EncryptionKey FOREIGN KEY (EncryptionKeyID)
        REFERENCES [${mjSchema}].[EncryptionKey](ID),
    CONSTRAINT CK_ActivitySyncRunDetail_Decision CHECK (
        Decision IN (N'Included', N'Excluded', N'Duplicate', N'Failed', N'WouldInclude', N'WouldExclude')
    ),
    CONSTRAINT CK_ActivitySyncRunDetail_Confidence CHECK (
        Confidence IS NULL OR (Confidence >= 0 AND Confidence <= 1)
    ),
    -- Ciphertext without a key is unreadable forever; a key without ciphertext
    -- is a false claim that something was captured. Both or neither.
    CONSTRAINT CK_ActivitySyncRunDetail_ContentKey CHECK (
        (CapturedContent IS NULL AND EncryptionKeyID IS NULL)
        OR (CapturedContent IS NOT NULL AND EncryptionKeyID IS NOT NULL)
    ),
    -- Only an INCLUDED item has an Activity. A skip that names one is a bug.
    CONSTRAINT CK_ActivitySyncRunDetail_ActivityOnlyWhenIncluded CHECK (
        ActivityID IS NULL OR Decision = N'Included'
    )
);
GO

---------------------------------------------------------------------------
-- ActivitySyncExtension — in-process enrichment registry
---------------------------------------------------------------------------
CREATE TABLE [${flyway:defaultSchema}].[ActivitySyncExtension] (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    DriverClass NVARCHAR(200) NOT NULL,
    ActivitySyncConnectionID UNIQUEIDENTIFIER NULL,
    ActivitySyncProviderTypeID UNIQUEIDENTIFIER NULL,
    Sequence INT NOT NULL DEFAULT 0,
    FailurePolicy NVARCHAR(20) NOT NULL DEFAULT N'Skip',
    TimeoutMS INT NOT NULL DEFAULT 5000,
    IsEnabled BIT NOT NULL DEFAULT 1,
    LastRunAt DATETIMEOFFSET NULL,
    LastError NVARCHAR(MAX) NULL,
    CONSTRAINT PK_ActivitySyncExtension PRIMARY KEY (ID),
    CONSTRAINT UQ_ActivitySyncExtension_Name UNIQUE (Name),
    CONSTRAINT FK_ActivitySyncExtension_Connection FOREIGN KEY (ActivitySyncConnectionID)
        REFERENCES [${flyway:defaultSchema}].[ActivitySyncConnection](ID)
        ON DELETE CASCADE,
    CONSTRAINT FK_ActivitySyncExtension_ProviderType FOREIGN KEY (ActivitySyncProviderTypeID)
        REFERENCES [${flyway:defaultSchema}].[ActivitySyncProviderType](ID),
    CONSTRAINT CK_ActivitySyncExtension_FailurePolicy CHECK (
        FailurePolicy IN (N'Skip', N'Abort')
    ),
    CONSTRAINT CK_ActivitySyncExtension_TimeoutMS CHECK (
        TimeoutMS > 0 AND TimeoutMS <= 300000
    )
);
GO

---------------------------------------------------------------------------
-- ActivitySyncConnection — provider type, activation window, policy overrides
--
-- ADDITIVE, per the Publish-Then-No-Breaking-Changes policy. Every new column
-- is nullable and the legacy Provider column stays in place, deprecated, so a
-- host on the published version keeps working. A later major removes it.
--
-- No backfill statement: no ingestion engine has ever shipped, so no host has a
-- connection row to backfill.
---------------------------------------------------------------------------
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncConnection]
    ADD ActivitySyncProviderTypeID UNIQUEIDENTIFIER NULL,
        StartAt DATETIMEOFFSET NULL,
        EndAt DATETIMEOFFSET NULL,
        SkippedContentPolicy NVARCHAR(20) NULL,
        EncryptionKeyID UNIQUEIDENTIFIER NULL,
        StorageProviderID UNIQUEIDENTIFIER NULL,
        MaxAttachmentBytes BIGINT NULL;
GO

ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncConnection]
    ADD CONSTRAINT FK_ActivitySyncConnection_ProviderType
        FOREIGN KEY (ActivitySyncProviderTypeID)
        REFERENCES [${flyway:defaultSchema}].[ActivitySyncProviderType](ID),
    CONSTRAINT FK_ActivitySyncConnection_EncryptionKey
        FOREIGN KEY (EncryptionKeyID)
        REFERENCES [${mjSchema}].[EncryptionKey](ID),
    CONSTRAINT FK_ActivitySyncConnection_StorageProvider
        FOREIGN KEY (StorageProviderID)
        REFERENCES [${mjSchema}].[FileStorageProvider](ID),
    CONSTRAINT CK_ActivitySyncConnection_ActivationWindow CHECK (
        StartAt IS NULL OR EndAt IS NULL OR EndAt >= StartAt
    ),
    CONSTRAINT CK_ActivitySyncConnection_SkippedPolicy CHECK (
        SkippedContentPolicy IS NULL
        OR SkippedContentPolicy IN (N'None', N'SubjectEncrypted', N'FullEncrypted')
    ),
    CONSTRAINT CK_ActivitySyncConnection_MaxBytes CHECK (
        MaxAttachmentBytes IS NULL OR MaxAttachmentBytes > 0
    );
GO

-- The constraint that made every new provider a migration to Common.
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncConnection]
    DROP CONSTRAINT CK_ActivitySyncConnection_Provider;
GO

-- Deprecated, and therefore no longer required. Widening NOT NULL to NULL is
-- additive for readers and lets a new row identify its provider by FK alone.
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncConnection]
    ALTER COLUMN Provider NVARCHAR(40) NULL;
GO

---------------------------------------------------------------------------
-- ActivitySyncRule — belongs to a RULE SET; gains participant-scope and size
--
-- ActivitySyncConnectionID is widened to NULL and ActivitySyncRuleSetID added,
-- with a strict exclusive-or. Existing rows (connection-scoped, rule-set null)
-- satisfy it unchanged, so this is additive.
---------------------------------------------------------------------------
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRule]
    ALTER COLUMN ActivitySyncConnectionID UNIQUEIDENTIFIER NULL;
GO

ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRule]
    ADD ActivitySyncRuleSetID UNIQUEIDENTIFIER NULL,
        ParticipantScope NVARCHAR(30) NULL,
        MaxAttachmentBytes BIGINT NULL;
GO

ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRule]
    ADD CONSTRAINT FK_ActivitySyncRule_RuleSet
        FOREIGN KEY (ActivitySyncRuleSetID)
        REFERENCES [${flyway:defaultSchema}].[ActivitySyncRuleSet](ID)
        ON DELETE CASCADE,
    CONSTRAINT CK_ActivitySyncRule_Owner CHECK (
        (ActivitySyncRuleSetID IS NULL AND ActivitySyncConnectionID IS NOT NULL)
        OR (ActivitySyncRuleSetID IS NOT NULL AND ActivitySyncConnectionID IS NULL)
    ),
    CONSTRAINT CK_ActivitySyncRule_ParticipantScope CHECK (
        ParticipantScope IS NULL
        OR ParticipantScope IN (N'Any', N'AllInternal', N'AllExternal', N'HasExternal', N'HasInternal', N'Mixed')
    ),
    CONSTRAINT CK_ActivitySyncRule_MaxBytes CHECK (
        MaxAttachmentBytes IS NULL OR MaxAttachmentBytes > 0
    );
GO

---------------------------------------------------------------------------
-- Extended properties — NEW tables (bare ADD is safe; they cannot pre-exist)
---------------------------------------------------------------------------
EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'A kind of activity source (Microsoft365, Gmail, Twilio SMS, LinkedIn, …). Provider identity is DATA, not a CHECK constraint, so a new source is a new plugin package plus a metadata row — never a migration to Common. Also carries the DEFAULTS an operator should set once per provider rather than per mailbox: storage, encryption key, attachment cap, and what an undecided qualification verdict means.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncProviderType';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'What an Undecided qualification verdict means for this provider once every rule stage has abstained. Exclude (the default) fails CLOSED — correct for anything mailbox-shaped, where capturing a private message is worse than missing a business one.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncProviderType',
    @level2type = N'COLUMN', @level2name = N'DefaultQualificationPolicy';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Whether a SKIPPED message may have content retained for audit, and how much. None keeps only the opaque external id and the decision. SubjectEncrypted and FullEncrypted additionally keep ciphertext, and are only valid with DefaultEncryptionKeyID set — enforced by CK_ActivitySyncProviderType_KeyRequired. Overridable per connection.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncProviderType',
    @level2type = N'COLUMN', @level2name = N'DefaultSkippedContentPolicy';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'A NAMED, REUSABLE set of rules bound to many connections. Rules used to hang off a single connection, so an org-wide prohibition had to be retyped for every mailbox and a new mailbox started with none — governance by copy-paste. A rule set is authored once and bound wherever it applies.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncRuleSet';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'JSON array of the domains this deployment considers INTERNAL, e.g. ["bluecypress.io"]. Required for any rule using ParticipantScope: "internal" is a property of the deployment, not of a message. Held on the rule set so one definition serves every mailbox bound to it.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncRuleSet',
    @level2type = N'COLUMN', @level2name = N'InternalDomains';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Optional provider type this rule set is written for. Null means the set applies regardless of source — an org-wide prohibition does not care whether the mailbox is Microsoft365 or Gmail.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncRuleSet',
    @level2type = N'COLUMN', @level2name = N'ActivitySyncProviderTypeID';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Binds a rule set to a connection, ordered. Many-to-many so a mailbox composes an org-wide baseline, a team overlay, and anything specific to itself — rather than owning one private copy of everything.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncConnectionRuleSet';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'The rule set bound to this connection. A mailbox composes several sets (org baseline, team overlay, mailbox-specific) through this join; Sequence on the binding is the evaluation order.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncConnectionRuleSet',
    @level2type = N'COLUMN', @level2name = N'ActivitySyncRuleSetID';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Never-ingest list, by identity: an email address, a phone number, a social handle, or a whole domain. Rows rather than a delimited string because an exclusion that cannot be queried cannot be audited, and this is precisely what a legal hold, an HR matter or an opt-out has to be able to prove. Scoped to a rule set, or global when ActivitySyncRuleSetID is null.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncExclusion';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Optional link to the Person this identity belongs to. Optional because an address is often excluded before anyone knows whose it is, and because a Person has several ContactMethods — the identity is the durable key here, not the record.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncExclusion',
    @level2type = N'COLUMN', @level2name = N'PersonID';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Optional rule set this exclusion belongs to. Null means global — the identity is never ingested on any connection. A legal hold or opt-out is usually global; a mailbox-specific mute is not.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncExclusion',
    @level2type = N'COLUMN', @level2name = N'ActivitySyncRuleSetID';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'One sync pass over one connection: what it fetched, what it decided, and whether it earned the right to move the watermark. A dry run is a real row with IsDryRun set — it evaluates and reports without writing an Activity or advancing the connection.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncRun';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'The decision made about ONE message, written for every item considered INCLUDING every skip — which is what makes "why did my email not appear" answerable. ExternalID and the decision are always safe to keep: an opaque provider id and the name of a rule, not content. CapturedContent is different in kind and is governed by the effective SkippedContentPolicy. Give this entity permissions DISTINCT from Activity: it can hold fragments of messages that were deliberately not ingested.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncRunDetail';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Ciphertext, always — never plaintext, whatever the policy. Present only when the effective SkippedContentPolicy allows retention, and always paired with the EncryptionKeyID that opens it (CK_ActivitySyncRunDetail_ContentKey). Encrypted through MJ''s EncryptionEngine against an MJ: Encryption Keys row; this app never implements its own crypto.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncRunDetail',
    @level2type = N'COLUMN', @level2name = N'CapturedContent';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Which stage of the qualification cascade decided — a rule set name, KnownParticipant, Inference, or DefaultPolicy. Paired with Reason it explains an outcome without retaining the message that produced it.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncRunDetail',
    @level2type = N'COLUMN', @level2name = N'DecidedByStage';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'The MJ: AI Prompt Run behind an inference-stage verdict. Non-null only when a model actually decided this item, which is the audit trail for every automated judgement the engine makes.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncRunDetail',
    @level2type = N'COLUMN', @level2name = N'AIPromptRunID';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Registration of an in-process enrichment plugin that runs inside the Activity write transaction. Common ships this table; each consumer app ships its own rows, so a downstream app adds links (a deal, a campaign) without Common knowing it exists. Extensions ENRICH — they never veto an activity, because qualification has already run and capture must not depend on which apps are installed.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncExtension';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Ascending run order. REQUIRED rather than incidental: two extensions both adding links must not depend on registration order, which varies with package load order and is not reproducible.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncExtension',
    @level2type = N'COLUMN', @level2name = N'Sequence';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'What happens when this extension throws. Skip (the default) records the error and commits the activity without the enrichment; Abort rolls the whole write back. Skip is the default because the activity is worth more than the enrichment, and one buggy consumer app must not be able to halt ingestion for every other app on the host.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncExtension',
    @level2type = N'COLUMN', @level2name = N'FailurePolicy';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Optional provider type this extension is registered for. Null means it runs on every connection. A deal-linker that only makes sense on email can bind here rather than being invoked for a phone transcript.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncExtension',
    @level2type = N'COLUMN', @level2name = N'ActivitySyncProviderTypeID';
GO

---------------------------------------------------------------------------
-- Extended properties on the PRE-EXISTING tables
--
-- Guarded drop-then-add, not a bare ADD. ActivitySyncConnection.Provider
-- already carries an MS_Description from V202608171935, and
-- sp_addextendedproperty FAILS on a property that exists rather than
-- overwriting it -- so a bare ADD breaks this migration on any host that has
-- the table. Found by applying it to a real database (thanks @local-agent).
--
-- The guard is on all seven rather than only on Provider: the cause is
-- "writing a property on a table that already exists", and keying the fix to
-- that survives the next person adding one. Keying it to the single column
-- that happens to collide today would not.
--
-- New tables above keep a bare ADD: their properties cannot pre-exist.
---------------------------------------------------------------------------

IF EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncConnection]')
      AND minor_id = COLUMNPROPERTY(OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncConnection]'), N'StartAt', 'ColumnId')
      AND name = N'MS_Description'
)
    EXEC sp_dropextendedproperty
        @name = N'MS_Description',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE',  @level1name = N'ActivitySyncConnection',
        @level2type = N'COLUMN', @level2name = N'StartAt';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Activation window. Combines with Status: a connection syncs only when Status = Active AND now is within [StartAt, EndAt], treating either bound as open when null. Lets a mailbox be provisioned ahead of time, or retired on a date, without anyone remembering to flip a switch.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncConnection',
    @level2type = N'COLUMN', @level2name = N'StartAt';
GO

IF EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncConnection]')
      AND minor_id = COLUMNPROPERTY(OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncConnection]'), N'EndAt', 'ColumnId')
      AND name = N'MS_Description'
)
    EXEC sp_dropextendedproperty
        @name = N'MS_Description',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE',  @level1name = N'ActivitySyncConnection',
        @level2type = N'COLUMN', @level2name = N'EndAt';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'End of the activation window; see StartAt. Null means open-ended.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncConnection',
    @level2type = N'COLUMN', @level2name = N'EndAt';
GO

IF EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncConnection]')
      AND minor_id = COLUMNPROPERTY(OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncConnection]'), N'SkippedContentPolicy', 'ColumnId')
      AND name = N'MS_Description'
)
    EXEC sp_dropextendedproperty
        @name = N'MS_Description',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE',  @level1name = N'ActivitySyncConnection',
        @level2type = N'COLUMN', @level2name = N'SkippedContentPolicy';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Per-connection override of the provider type''s DefaultSkippedContentPolicy. Null inherits. This is the knob for "this one mailbox is sensitive" without changing the estate.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncConnection',
    @level2type = N'COLUMN', @level2name = N'SkippedContentPolicy';
GO

IF EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncConnection]')
      AND minor_id = COLUMNPROPERTY(OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncConnection]'), N'ActivitySyncProviderTypeID', 'ColumnId')
      AND name = N'MS_Description'
)
    EXEC sp_dropextendedproperty
        @name = N'MS_Description',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE',  @level1name = N'ActivitySyncConnection',
        @level2type = N'COLUMN', @level2name = N'ActivitySyncProviderTypeID';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'The provider type this connection reads. Supersedes the Provider string column, whose CHECK constraint made every new source a migration to Common.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncConnection',
    @level2type = N'COLUMN', @level2name = N'ActivitySyncProviderTypeID';
GO

IF EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncConnection]')
      AND minor_id = COLUMNPROPERTY(OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncConnection]'), N'Provider', 'ColumnId')
      AND name = N'MS_Description'
)
    EXEC sp_dropextendedproperty
        @name = N'MS_Description',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE',  @level1name = N'ActivitySyncConnection',
        @level2type = N'COLUMN', @level2name = N'Provider';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'DEPRECATED — use ActivitySyncProviderTypeID. Retained nullable so a published host keeps working; removed in the next major.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncConnection',
    @level2type = N'COLUMN', @level2name = N'Provider';
GO

IF EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncRule]')
      AND minor_id = COLUMNPROPERTY(OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncRule]'), N'ParticipantScope', 'ColumnId')
      AND name = N'MS_Description'
)
    EXEC sp_dropextendedproperty
        @name = N'MS_Description',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE',  @level1name = N'ActivitySyncRule',
        @level2type = N'COLUMN', @level2name = N'ParticipantScope';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Which participants must be present for this rule to apply — the internal/external control. AllInternal excludes purely internal chatter; HasExternal catches a thread with any outside party on it; Mixed is the case an all-or-nothing rule gets wrong. Requires the rule set to define InternalDomains. Null means the rule does not test participants.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncRule',
    @level2type = N'COLUMN', @level2name = N'ParticipantScope';
GO

IF EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncRule]')
      AND minor_id = COLUMNPROPERTY(OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncRule]'), N'ActivitySyncRuleSetID', 'ColumnId')
      AND name = N'MS_Description'
)
    EXEC sp_dropextendedproperty
        @name = N'MS_Description',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE',  @level1name = N'ActivitySyncRule',
        @level2type = N'COLUMN', @level2name = N'ActivitySyncRuleSetID';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'The rule set this rule belongs to. Exactly one of ActivitySyncRuleSetID and ActivitySyncConnectionID is set (CK_ActivitySyncRule_Owner) — the connection form is the deprecated original and remains only so existing rows stay valid.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncRule',
    @level2type = N'COLUMN', @level2name = N'ActivitySyncRuleSetID';
GO


















































-- =============================================================================
-- CODE GEN RUN
-- =============================================================================
-- Appended from CodeGen_Run_2026-08-29_23-23-53.sql (ONE skipfiles pass on
-- bizapps_activity_sync_grok_r3_20260829 after V1500 DDL, including 7e153a8
-- drop-then-add properties and the two item-4 properties, actually executed).
-- Host-install edits vs the raw emit, proven on r4 (it6 restore + this file):
--   * spUpdateExistingEntityFieldsFromSchema scoped to the seven NEW entities
--     (the unscoped form rewrites Sequence on existing Connection/Rule fields
--     and hits UQ_EntityField_EntityID_Sequence).
--   * second-pass +100000 sequence bump skipped on Connection and Rule
--     (those entities already shipped; a second bump collides at 100015).
-- No second skipfiles. No r2 two-capture append. No sp_updateextendedproperty.
-- =============================================================================

/* SQL generated to create new entity MJ_BizApps_Common: Activity Sync Provider Types */

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
         [AllowCaching]
         , [TrackRecordChanges]
         , [AuditRecordAccess]
         , [AuditViewRuns]
         , [AllowAllRowsAPI]
         , [AllowCreateAPI]
         , [AllowUpdateAPI]
         , [AllowDeleteAPI]
         , [UserViewMaxRows]
         , [__mj_CreatedAt]
         , [__mj_UpdatedAt]
      )
      VALUES (
         'ad8b1485-8be1-4e5c-8efb-3b4fea363f75',
         'MJ_BizApps_Common: Activity Sync Provider Types',
         'Activity Sync Provider Types',
         'A kind of activity source (Microsoft365, Gmail, Twilio SMS, LinkedIn, …). Provider identity is DATA, not a CHECK constraint, so a new source is a new plugin package plus a metadata row — never a migration to Common. Also carries the DEFAULTS an operator should set once per provider rather than per mailbox: storage, encryption key, attachment cap, and what an undecided qualification verdict means.',
         NULL,
         'ActivitySyncProviderType',
         'vwActivitySyncProviderTypes',
         '${flyway:defaultSchema}',
         1,
         1,
         0
         , 1
         , 0
         , 0
         , 0
         , 1
         , 1
         , 1
         , 1000
         , GETUTCDATE()
         , GETUTCDATE()
      );

/* SQL generated to add new entity MJ_BizApps_Common: Activity Sync Provider Types to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'ad8b1485-8be1-4e5c-8efb-3b4fea363f75', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Provider Types for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('ad8b1485-8be1-4e5c-8efb-3b4fea363f75', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Provider Types for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('ad8b1485-8be1-4e5c-8efb-3b4fea363f75', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Provider Types for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('ad8b1485-8be1-4e5c-8efb-3b4fea363f75', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE());

/* SQL generated to create new entity MJ_BizApps_Common: Activity Sync Rule Sets */

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
         [AllowCaching]
         , [TrackRecordChanges]
         , [AuditRecordAccess]
         , [AuditViewRuns]
         , [AllowAllRowsAPI]
         , [AllowCreateAPI]
         , [AllowUpdateAPI]
         , [AllowDeleteAPI]
         , [UserViewMaxRows]
         , [__mj_CreatedAt]
         , [__mj_UpdatedAt]
      )
      VALUES (
         '7ed9f26e-b01d-472a-87c9-b163287f80b4',
         'MJ_BizApps_Common: Activity Sync Rule Sets',
         'Activity Sync Rule Sets',
         'A NAMED, REUSABLE set of rules bound to many connections. Rules used to hang off a single connection, so an org-wide prohibition had to be retyped for every mailbox and a new mailbox started with none — governance by copy-paste. A rule set is authored once and bound wherever it applies.',
         NULL,
         'ActivitySyncRuleSet',
         'vwActivitySyncRuleSets',
         '${flyway:defaultSchema}',
         1,
         1,
         0
         , 1
         , 0
         , 0
         , 0
         , 1
         , 1
         , 1
         , 1000
         , GETUTCDATE()
         , GETUTCDATE()
      );

/* SQL generated to add new entity MJ_BizApps_Common: Activity Sync Rule Sets to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '7ed9f26e-b01d-472a-87c9-b163287f80b4', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Rule Sets for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('7ed9f26e-b01d-472a-87c9-b163287f80b4', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Rule Sets for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('7ed9f26e-b01d-472a-87c9-b163287f80b4', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Rule Sets for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('7ed9f26e-b01d-472a-87c9-b163287f80b4', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE());

/* SQL generated to create new entity MJ_BizApps_Common: Activity Sync Connection Rule Sets */

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
         [AllowCaching]
         , [TrackRecordChanges]
         , [AuditRecordAccess]
         , [AuditViewRuns]
         , [AllowAllRowsAPI]
         , [AllowCreateAPI]
         , [AllowUpdateAPI]
         , [AllowDeleteAPI]
         , [UserViewMaxRows]
         , [__mj_CreatedAt]
         , [__mj_UpdatedAt]
      )
      VALUES (
         'd2a4da75-fccd-4196-b6eb-0c15b28c95b0',
         'MJ_BizApps_Common: Activity Sync Connection Rule Sets',
         'Activity Sync Connection Rule Sets',
         'Binds a rule set to a connection, ordered. Many-to-many so a mailbox composes an org-wide baseline, a team overlay, and anything specific to itself — rather than owning one private copy of everything.',
         NULL,
         'ActivitySyncConnectionRuleSet',
         'vwActivitySyncConnectionRuleSets',
         '${flyway:defaultSchema}',
         1,
         1,
         0
         , 1
         , 0
         , 0
         , 0
         , 1
         , 1
         , 1
         , 1000
         , GETUTCDATE()
         , GETUTCDATE()
      );

/* SQL generated to add new entity MJ_BizApps_Common: Activity Sync Connection Rule Sets to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'd2a4da75-fccd-4196-b6eb-0c15b28c95b0', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Connection Rule Sets for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('d2a4da75-fccd-4196-b6eb-0c15b28c95b0', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Connection Rule Sets for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('d2a4da75-fccd-4196-b6eb-0c15b28c95b0', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Connection Rule Sets for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('d2a4da75-fccd-4196-b6eb-0c15b28c95b0', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE());

/* SQL generated to create new entity MJ_BizApps_Common: Activity Sync Exclusions */

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
         [AllowCaching]
         , [TrackRecordChanges]
         , [AuditRecordAccess]
         , [AuditViewRuns]
         , [AllowAllRowsAPI]
         , [AllowCreateAPI]
         , [AllowUpdateAPI]
         , [AllowDeleteAPI]
         , [UserViewMaxRows]
         , [__mj_CreatedAt]
         , [__mj_UpdatedAt]
      )
      VALUES (
         '556381bf-9ace-4a69-85bb-22eae1856c88',
         'MJ_BizApps_Common: Activity Sync Exclusions',
         'Activity Sync Exclusions',
         'Never-ingest list, by identity: an email address, a phone number, a social handle, or a whole domain. Rows rather than a delimited string because an exclusion that cannot be queried cannot be audited, and this is precisely what a legal hold, an HR matter or an opt-out has to be able to prove. Scoped to a rule set, or global when ActivitySyncRuleSetID is null.',
         NULL,
         'ActivitySyncExclusion',
         'vwActivitySyncExclusions',
         '${flyway:defaultSchema}',
         1,
         1,
         0
         , 1
         , 0
         , 0
         , 0
         , 1
         , 1
         , 1
         , 1000
         , GETUTCDATE()
         , GETUTCDATE()
      );

/* SQL generated to add new entity MJ_BizApps_Common: Activity Sync Exclusions to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', '556381bf-9ace-4a69-85bb-22eae1856c88', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Exclusions for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('556381bf-9ace-4a69-85bb-22eae1856c88', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Exclusions for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('556381bf-9ace-4a69-85bb-22eae1856c88', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Exclusions for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('556381bf-9ace-4a69-85bb-22eae1856c88', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE());

/* SQL generated to create new entity MJ_BizApps_Common: Activity Sync Runs */

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
         [AllowCaching]
         , [TrackRecordChanges]
         , [AuditRecordAccess]
         , [AuditViewRuns]
         , [AllowAllRowsAPI]
         , [AllowCreateAPI]
         , [AllowUpdateAPI]
         , [AllowDeleteAPI]
         , [UserViewMaxRows]
         , [__mj_CreatedAt]
         , [__mj_UpdatedAt]
      )
      VALUES (
         'ecf19741-cba6-4db7-95a3-85fa37bec2f1',
         'MJ_BizApps_Common: Activity Sync Runs',
         'Activity Sync Runs',
         'One sync pass over one connection: what it fetched, what it decided, and whether it earned the right to move the watermark. A dry run is a real row with IsDryRun set — it evaluates and reports without writing an Activity or advancing the connection.',
         NULL,
         'ActivitySyncRun',
         'vwActivitySyncRuns',
         '${flyway:defaultSchema}',
         1,
         1,
         0
         , 1
         , 0
         , 0
         , 0
         , 1
         , 1
         , 1
         , 1000
         , GETUTCDATE()
         , GETUTCDATE()
      );

/* SQL generated to add new entity MJ_BizApps_Common: Activity Sync Runs to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'ecf19741-cba6-4db7-95a3-85fa37bec2f1', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Runs for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('ecf19741-cba6-4db7-95a3-85fa37bec2f1', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Runs for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('ecf19741-cba6-4db7-95a3-85fa37bec2f1', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Runs for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('ecf19741-cba6-4db7-95a3-85fa37bec2f1', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE());

/* SQL generated to create new entity MJ_BizApps_Common: Activity Sync Run Details */

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
         [AllowCaching]
         , [TrackRecordChanges]
         , [AuditRecordAccess]
         , [AuditViewRuns]
         , [AllowAllRowsAPI]
         , [AllowCreateAPI]
         , [AllowUpdateAPI]
         , [AllowDeleteAPI]
         , [UserViewMaxRows]
         , [__mj_CreatedAt]
         , [__mj_UpdatedAt]
      )
      VALUES (
         'ac16b066-9460-44f5-b027-3fd397e61f34',
         'MJ_BizApps_Common: Activity Sync Run Details',
         'Activity Sync Run Details',
         'The decision made about ONE message, written for every item considered INCLUDING every skip — which is what makes "why did my email not appear" answerable. ExternalID and the decision are always safe to keep: an opaque provider id and the name of a rule, not content. CapturedContent is different in kind and is governed by the effective SkippedContentPolicy. Give this entity permissions DISTINCT from Activity: it can hold fragments of messages that were deliberately not ingested.',
         NULL,
         'ActivitySyncRunDetail',
         'vwActivitySyncRunDetails',
         '${flyway:defaultSchema}',
         1,
         1,
         0
         , 1
         , 0
         , 0
         , 0
         , 1
         , 1
         , 1
         , 1000
         , GETUTCDATE()
         , GETUTCDATE()
      );

/* SQL generated to add new entity MJ_BizApps_Common: Activity Sync Run Details to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'ac16b066-9460-44f5-b027-3fd397e61f34', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Run Details for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('ac16b066-9460-44f5-b027-3fd397e61f34', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Run Details for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('ac16b066-9460-44f5-b027-3fd397e61f34', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Run Details for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('ac16b066-9460-44f5-b027-3fd397e61f34', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE());

/* SQL generated to create new entity MJ_BizApps_Common: Activity Sync Extensions */

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
         [AllowCaching]
         , [TrackRecordChanges]
         , [AuditRecordAccess]
         , [AuditViewRuns]
         , [AllowAllRowsAPI]
         , [AllowCreateAPI]
         , [AllowUpdateAPI]
         , [AllowDeleteAPI]
         , [UserViewMaxRows]
         , [__mj_CreatedAt]
         , [__mj_UpdatedAt]
      )
      VALUES (
         'c7e5ece1-f347-4bc9-ac53-e2f33577b449',
         'MJ_BizApps_Common: Activity Sync Extensions',
         'Activity Sync Extensions',
         'Registration of an in-process enrichment plugin that runs inside the Activity write transaction. Common ships this table; each consumer app ships its own rows, so a downstream app adds links (a deal, a campaign) without Common knowing it exists. Extensions ENRICH — they never veto an activity, because qualification has already run and capture must not depend on which apps are installed.',
         NULL,
         'ActivitySyncExtension',
         'vwActivitySyncExtensions',
         '${flyway:defaultSchema}',
         1,
         1,
         0
         , 1
         , 0
         , 0
         , 0
         , 1
         , 1
         , 1
         , 1000
         , GETUTCDATE()
         , GETUTCDATE()
      );

/* SQL generated to add new entity MJ_BizApps_Common: Activity Sync Extensions to application ID: 'B479EB79-1260-40AF-A5EA-F8AA0B71384F' */
INSERT INTO [${mjSchema}].[ApplicationEntity]
                                       ([ApplicationID], [EntityID], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                       ('B479EB79-1260-40AF-A5EA-F8AA0B71384F', 'c7e5ece1-f347-4bc9-ac53-e2f33577b449', (SELECT COALESCE(MAX([Sequence]),0)+1 FROM [${mjSchema}].[ApplicationEntity] WHERE [ApplicationID] = 'B479EB79-1260-40AF-A5EA-F8AA0B71384F'), GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Extensions for role UI */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('c7e5ece1-f347-4bc9-ac53-e2f33577b449', 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 0, 0, 0, GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Extensions for role Developer */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('c7e5ece1-f347-4bc9-ac53-e2f33577b449', 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE());

/* SQL generated to add new permission for entity MJ_BizApps_Common: Activity Sync Extensions for role Integration */
INSERT INTO [${mjSchema}].[EntityPermission]
                                                   ([EntityID], [RoleID], [CanRead], [CanCreate], [CanUpdate], [CanDelete], [__mj_CreatedAt], [__mj_UpdatedAt]) VALUES
                                                   ('c7e5ece1-f347-4bc9-ac53-e2f33577b449', 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', 1, 1, 1, 1, GETUTCDATE(), GETUTCDATE());

/* SQL text to update existing entities from schema */
EXEC [${mjSchema}].[spUpdateExistingEntitiesFromSchema] @ExcludedSchemaNames='', @IncludedSchemaNames='${flyway:defaultSchema}';

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncConnectionRuleSet */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet] ADD [__mj_CreatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncConnectionRuleSet */
UPDATE [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet] SET [__mj_CreatedAt] = GETUTCDATE() WHERE [__mj_CreatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncConnectionRuleSet */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet] ALTER COLUMN [__mj_CreatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncConnectionRuleSet */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet] ADD CONSTRAINT [DF___mj_BizAppsCommon_ActivitySyncConnectionRuleSet___mj_CreatedAt] DEFAULT GETUTCDATE() FOR [__mj_CreatedAt];
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncConnectionRuleSet */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet] ADD [__mj_UpdatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncConnectionRuleSet */
UPDATE [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet] SET [__mj_UpdatedAt] = GETUTCDATE() WHERE [__mj_UpdatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncConnectionRuleSet */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet] ALTER COLUMN [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncConnectionRuleSet */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet] ADD CONSTRAINT [DF___mj_BizAppsCommon_ActivitySyncConnectionRuleSet___mj_UpdatedAt] DEFAULT GETUTCDATE() FOR [__mj_UpdatedAt];
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncExclusion */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncExclusion] ADD [__mj_CreatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncExclusion */
UPDATE [${flyway:defaultSchema}].[ActivitySyncExclusion] SET [__mj_CreatedAt] = GETUTCDATE() WHERE [__mj_CreatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncExclusion */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncExclusion] ALTER COLUMN [__mj_CreatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncExclusion */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncExclusion] ADD CONSTRAINT [DF___mj_BizAppsCommon_ActivitySyncExclusion___mj_CreatedAt] DEFAULT GETUTCDATE() FOR [__mj_CreatedAt];
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncExclusion */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncExclusion] ADD [__mj_UpdatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncExclusion */
UPDATE [${flyway:defaultSchema}].[ActivitySyncExclusion] SET [__mj_UpdatedAt] = GETUTCDATE() WHERE [__mj_UpdatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncExclusion */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncExclusion] ALTER COLUMN [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncExclusion */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncExclusion] ADD CONSTRAINT [DF___mj_BizAppsCommon_ActivitySyncExclusion___mj_UpdatedAt] DEFAULT GETUTCDATE() FOR [__mj_UpdatedAt];
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncProviderType */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncProviderType] ADD [__mj_CreatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncProviderType */
UPDATE [${flyway:defaultSchema}].[ActivitySyncProviderType] SET [__mj_CreatedAt] = GETUTCDATE() WHERE [__mj_CreatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncProviderType */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncProviderType] ALTER COLUMN [__mj_CreatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncProviderType */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncProviderType] ADD CONSTRAINT [DF___mj_BizAppsCommon_ActivitySyncProviderType___mj_CreatedAt] DEFAULT GETUTCDATE() FOR [__mj_CreatedAt];
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncProviderType */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncProviderType] ADD [__mj_UpdatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncProviderType */
UPDATE [${flyway:defaultSchema}].[ActivitySyncProviderType] SET [__mj_UpdatedAt] = GETUTCDATE() WHERE [__mj_UpdatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncProviderType */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncProviderType] ALTER COLUMN [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncProviderType */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncProviderType] ADD CONSTRAINT [DF___mj_BizAppsCommon_ActivitySyncProviderType___mj_UpdatedAt] DEFAULT GETUTCDATE() FOR [__mj_UpdatedAt];
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncRunDetail */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRunDetail] ADD [__mj_CreatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncRunDetail */
UPDATE [${flyway:defaultSchema}].[ActivitySyncRunDetail] SET [__mj_CreatedAt] = GETUTCDATE() WHERE [__mj_CreatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncRunDetail */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRunDetail] ALTER COLUMN [__mj_CreatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncRunDetail */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRunDetail] ADD CONSTRAINT [DF___mj_BizAppsCommon_ActivitySyncRunDetail___mj_CreatedAt] DEFAULT GETUTCDATE() FOR [__mj_CreatedAt];
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncRunDetail */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRunDetail] ADD [__mj_UpdatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncRunDetail */
UPDATE [${flyway:defaultSchema}].[ActivitySyncRunDetail] SET [__mj_UpdatedAt] = GETUTCDATE() WHERE [__mj_UpdatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncRunDetail */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRunDetail] ALTER COLUMN [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncRunDetail */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRunDetail] ADD CONSTRAINT [DF___mj_BizAppsCommon_ActivitySyncRunDetail___mj_UpdatedAt] DEFAULT GETUTCDATE() FOR [__mj_UpdatedAt];
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncRun */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRun] ADD [__mj_CreatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncRun */
UPDATE [${flyway:defaultSchema}].[ActivitySyncRun] SET [__mj_CreatedAt] = GETUTCDATE() WHERE [__mj_CreatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncRun */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRun] ALTER COLUMN [__mj_CreatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncRun */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRun] ADD CONSTRAINT [DF___mj_BizAppsCommon_ActivitySyncRun___mj_CreatedAt] DEFAULT GETUTCDATE() FOR [__mj_CreatedAt];
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncRun */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRun] ADD [__mj_UpdatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncRun */
UPDATE [${flyway:defaultSchema}].[ActivitySyncRun] SET [__mj_UpdatedAt] = GETUTCDATE() WHERE [__mj_UpdatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncRun */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRun] ALTER COLUMN [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncRun */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRun] ADD CONSTRAINT [DF___mj_BizAppsCommon_ActivitySyncRun___mj_UpdatedAt] DEFAULT GETUTCDATE() FOR [__mj_UpdatedAt];
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncRuleSet */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRuleSet] ADD [__mj_CreatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncRuleSet */
UPDATE [${flyway:defaultSchema}].[ActivitySyncRuleSet] SET [__mj_CreatedAt] = GETUTCDATE() WHERE [__mj_CreatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncRuleSet */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRuleSet] ALTER COLUMN [__mj_CreatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncRuleSet */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRuleSet] ADD CONSTRAINT [DF___mj_BizAppsCommon_ActivitySyncRuleSet___mj_CreatedAt] DEFAULT GETUTCDATE() FOR [__mj_CreatedAt];
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncRuleSet */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRuleSet] ADD [__mj_UpdatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncRuleSet */
UPDATE [${flyway:defaultSchema}].[ActivitySyncRuleSet] SET [__mj_UpdatedAt] = GETUTCDATE() WHERE [__mj_UpdatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncRuleSet */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRuleSet] ALTER COLUMN [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncRuleSet */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncRuleSet] ADD CONSTRAINT [DF___mj_BizAppsCommon_ActivitySyncRuleSet___mj_UpdatedAt] DEFAULT GETUTCDATE() FOR [__mj_UpdatedAt];
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncExtension */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncExtension] ADD [__mj_CreatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncExtension */
UPDATE [${flyway:defaultSchema}].[ActivitySyncExtension] SET [__mj_CreatedAt] = GETUTCDATE() WHERE [__mj_CreatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncExtension */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncExtension] ALTER COLUMN [__mj_CreatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_CreatedAt to entity ${flyway:defaultSchema}.ActivitySyncExtension */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncExtension] ADD CONSTRAINT [DF___mj_BizAppsCommon_ActivitySyncExtension___mj_CreatedAt] DEFAULT GETUTCDATE() FOR [__mj_CreatedAt];
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncExtension */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncExtension] ADD [__mj_UpdatedAt] DATETIMEOFFSET NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncExtension */
UPDATE [${flyway:defaultSchema}].[ActivitySyncExtension] SET [__mj_UpdatedAt] = GETUTCDATE() WHERE [__mj_UpdatedAt] IS NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncExtension */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncExtension] ALTER COLUMN [__mj_UpdatedAt] DATETIMEOFFSET NOT NULL;
GO

/* SQL text to add special date field __mj_UpdatedAt to entity ${flyway:defaultSchema}.ActivitySyncExtension */
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncExtension] ADD CONSTRAINT [DF___mj_BizAppsCommon_ActivitySyncExtension___mj_UpdatedAt] DEFAULT GETUTCDATE() FOR [__mj_UpdatedAt];
GO

/* SQL text to insert 113 new entity field(s) */
UPDATE [${mjSchema}].[EntityField]
         SET [Sequence] = [Sequence] + 100000
       WHERE [EntityID] = 'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0'
         AND [Sequence] < 100000;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '210d070a-bc54-43e3-83aa-999b27982e16' OR (EntityID = 'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0' AND Name = 'ID')) BEGIN
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
            '210d070a-bc54-43e3-83aa-999b27982e16',
            'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0', -- Entity: MJ_BizApps_Common: Activity Sync Connection Rule Sets
            1,
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
            1,
            0,
            0,
            1,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '25052037-85a8-4f55-a64f-a17de48ae3fb' OR (EntityID = 'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0' AND Name = 'ActivitySyncConnectionID')) BEGIN
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
            '25052037-85a8-4f55-a64f-a17de48ae3fb',
            'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0', -- Entity: MJ_BizApps_Common: Activity Sync Connection Rule Sets
            2,
            'ActivitySyncConnectionID',
            'Activity Sync Connection ID',
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
            'C22591BB-B33A-439C-9567-5494A7B71D8A',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '7bb4c198-cf87-4258-aeb5-99bf1f035baa' OR (EntityID = 'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0' AND Name = 'ActivitySyncRuleSetID')) BEGIN
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
            '7bb4c198-cf87-4258-aeb5-99bf1f035baa',
            'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0', -- Entity: MJ_BizApps_Common: Activity Sync Connection Rule Sets
            3,
            'ActivitySyncRuleSetID',
            'Activity Sync Rule Set ID',
            'The rule set bound to this connection. A mailbox composes several sets (org baseline, team overlay, mailbox-specific) through this join; Sequence on the binding is the evaluation order.',
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
            '7ED9F26E-B01D-472A-87C9-B163287F80B4',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '47ccf48d-b837-44e0-9475-ff1b42076f34' OR (EntityID = 'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0' AND Name = 'Sequence')) BEGIN
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
            '47ccf48d-b837-44e0-9475-ff1b42076f34',
            'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0', -- Entity: MJ_BizApps_Common: Activity Sync Connection Rule Sets
            4,
            'Sequence',
            'Sequence',
            NULL,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '7f25d600-b7d0-4548-816c-fa78ffe59044' OR (EntityID = 'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0' AND Name = 'IsEnabled')) BEGIN
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
            '7f25d600-b7d0-4548-816c-fa78ffe59044',
            'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0', -- Entity: MJ_BizApps_Common: Activity Sync Connection Rule Sets
            5,
            'IsEnabled',
            'Is Enabled',
            NULL,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '813e93a7-d167-45f0-87f5-c05f70947b92' OR (EntityID = 'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0' AND Name = '__mj_CreatedAt')) BEGIN
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
            '813e93a7-d167-45f0-87f5-c05f70947b92',
            'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0', -- Entity: MJ_BizApps_Common: Activity Sync Connection Rule Sets
            6,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '70644c38-265d-492e-a219-b17262d3736c' OR (EntityID = 'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0' AND Name = '__mj_UpdatedAt')) BEGIN
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
            '70644c38-265d-492e-a219-b17262d3736c',
            'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0', -- Entity: MJ_BizApps_Common: Activity Sync Connection Rule Sets
            7,
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
UPDATE [${mjSchema}].[EntityField]
         SET [Sequence] = [Sequence] + 100000
       WHERE [EntityID] = '556381BF-9ACE-4A69-85BB-22EAE1856C88'
         AND [Sequence] < 100000;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '1fb477c2-553d-479c-907f-af425f214adc' OR (EntityID = '556381BF-9ACE-4A69-85BB-22EAE1856C88' AND Name = 'ID')) BEGIN
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
            '1fb477c2-553d-479c-907f-af425f214adc',
            '556381BF-9ACE-4A69-85BB-22EAE1856C88', -- Entity: MJ_BizApps_Common: Activity Sync Exclusions
            1,
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
            1,
            0,
            0,
            1,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '84d4e65c-c18b-4a52-bd56-1fc459420563' OR (EntityID = '556381BF-9ACE-4A69-85BB-22EAE1856C88' AND Name = 'ActivitySyncRuleSetID')) BEGIN
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
            '84d4e65c-c18b-4a52-bd56-1fc459420563',
            '556381BF-9ACE-4A69-85BB-22EAE1856C88', -- Entity: MJ_BizApps_Common: Activity Sync Exclusions
            2,
            'ActivitySyncRuleSetID',
            'Activity Sync Rule Set ID',
            'Optional rule set this exclusion belongs to. Null means global — the identity is never ingested on any connection. A legal hold or opt-out is usually global; a mailbox-specific mute is not.',
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
            '7ED9F26E-B01D-472A-87C9-B163287F80B4',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'ad5a0fb1-1144-408a-a0e8-3f300bc786ac' OR (EntityID = '556381BF-9ACE-4A69-85BB-22EAE1856C88' AND Name = 'IdentityKind')) BEGIN
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
            'ad5a0fb1-1144-408a-a0e8-3f300bc786ac',
            '556381BF-9ACE-4A69-85BB-22EAE1856C88', -- Entity: MJ_BizApps_Common: Activity Sync Exclusions
            3,
            'IdentityKind',
            'Identity Kind',
            NULL,
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
            0,
            0,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '7a54676f-41bd-466b-9bb6-26425b32f8b0' OR (EntityID = '556381BF-9ACE-4A69-85BB-22EAE1856C88' AND Name = 'IdentityValue')) BEGIN
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
            '7a54676f-41bd-466b-9bb6-26425b32f8b0',
            '556381BF-9ACE-4A69-85BB-22EAE1856C88', -- Entity: MJ_BizApps_Common: Activity Sync Exclusions
            4,
            'IdentityValue',
            'Identity Value',
            NULL,
            'nvarchar',
            640,
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
            0,
            0,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '568087ee-b48d-43b3-9411-28302a37b0c5' OR (EntityID = '556381BF-9ACE-4A69-85BB-22EAE1856C88' AND Name = 'PersonID')) BEGIN
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
            '568087ee-b48d-43b3-9411-28302a37b0c5',
            '556381BF-9ACE-4A69-85BB-22EAE1856C88', -- Entity: MJ_BizApps_Common: Activity Sync Exclusions
            5,
            'PersonID',
            'Person ID',
            'Optional link to the Person this identity belongs to. Optional because an address is often excluded before anyone knows whose it is, and because a Person has several ContactMethods — the identity is the durable key here, not the record.',
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
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '9560bace-04ee-4b7e-826b-a5e64e8513e1' OR (EntityID = '556381BF-9ACE-4A69-85BB-22EAE1856C88' AND Name = 'Reason')) BEGIN
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
            '9560bace-04ee-4b7e-826b-a5e64e8513e1',
            '556381BF-9ACE-4A69-85BB-22EAE1856C88', -- Entity: MJ_BizApps_Common: Activity Sync Exclusions
            6,
            'Reason',
            'Reason',
            NULL,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8f9e007e-b597-44e8-ab81-7bb7d2aca504' OR (EntityID = '556381BF-9ACE-4A69-85BB-22EAE1856C88' AND Name = 'EffectiveFrom')) BEGIN
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
            '8f9e007e-b597-44e8-ab81-7bb7d2aca504',
            '556381BF-9ACE-4A69-85BB-22EAE1856C88', -- Entity: MJ_BizApps_Common: Activity Sync Exclusions
            7,
            'EffectiveFrom',
            'Effective From',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '85b42461-d8db-4d00-ad4e-9b9cc42eaf3e' OR (EntityID = '556381BF-9ACE-4A69-85BB-22EAE1856C88' AND Name = 'EffectiveTo')) BEGIN
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
            '85b42461-d8db-4d00-ad4e-9b9cc42eaf3e',
            '556381BF-9ACE-4A69-85BB-22EAE1856C88', -- Entity: MJ_BizApps_Common: Activity Sync Exclusions
            8,
            'EffectiveTo',
            'Effective To',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'b741ade2-f250-40d7-b0d2-61d28b331f3e' OR (EntityID = '556381BF-9ACE-4A69-85BB-22EAE1856C88' AND Name = 'IsEnabled')) BEGIN
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
            'b741ade2-f250-40d7-b0d2-61d28b331f3e',
            '556381BF-9ACE-4A69-85BB-22EAE1856C88', -- Entity: MJ_BizApps_Common: Activity Sync Exclusions
            9,
            'IsEnabled',
            'Is Enabled',
            NULL,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'a572f4c8-52e8-49ec-a42d-de68c3c730b5' OR (EntityID = '556381BF-9ACE-4A69-85BB-22EAE1856C88' AND Name = '__mj_CreatedAt')) BEGIN
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
            'a572f4c8-52e8-49ec-a42d-de68c3c730b5',
            '556381BF-9ACE-4A69-85BB-22EAE1856C88', -- Entity: MJ_BizApps_Common: Activity Sync Exclusions
            10,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '64004f94-0e95-4424-91e9-86aa9cd5d167' OR (EntityID = '556381BF-9ACE-4A69-85BB-22EAE1856C88' AND Name = '__mj_UpdatedAt')) BEGIN
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
            '64004f94-0e95-4424-91e9-86aa9cd5d167',
            '556381BF-9ACE-4A69-85BB-22EAE1856C88', -- Entity: MJ_BizApps_Common: Activity Sync Exclusions
            11,
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
UPDATE [${mjSchema}].[EntityField]
         SET [Sequence] = [Sequence] + 100000
       WHERE [EntityID] = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75'
         AND [Sequence] < 100000;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '57a720bd-8cb1-4429-95dd-150c529ff1dd' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = 'ID')) BEGIN
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
            '57a720bd-8cb1-4429-95dd-150c529ff1dd',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            1,
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
            1,
            0,
            0,
            1,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '52553d7e-79da-4dfd-9cc3-5f551e411de5' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = 'Code')) BEGIN
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
            '52553d7e-79da-4dfd-9cc3-5f551e411de5',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            2,
            'Code',
            'Code',
            NULL,
            'nvarchar',
            120,
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
            0,
            0,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'e3a328e8-5b81-48d7-9021-21ef3e67e3c2' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = 'Name')) BEGIN
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
            'e3a328e8-5b81-48d7-9021-21ef3e67e3c2',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            3,
            'Name',
            'Name',
            NULL,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'b4ba9bc4-5776-424b-b009-5ebb50ca712f' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = 'Description')) BEGIN
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
            'b4ba9bc4-5776-424b-b009-5ebb50ca712f',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            4,
            'Description',
            'Description',
            NULL,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'b89e3f6e-bedb-4ce4-82f8-29c1ff23b809' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = 'DriverClass')) BEGIN
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
            'b89e3f6e-bedb-4ce4-82f8-29c1ff23b809',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            5,
            'DriverClass',
            'Driver Class',
            NULL,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '43042f34-0dd3-4789-bd19-f3ae56cc733c' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = 'IconClass')) BEGIN
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
            '43042f34-0dd3-4789-bd19-f3ae56cc733c',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            6,
            'IconClass',
            'Icon Class',
            NULL,
            'nvarchar',
            200,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '2c86f25a-3816-4ec0-8885-06e4399313e0' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = 'SupportedKinds')) BEGIN
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
            '2c86f25a-3816-4ec0-8885-06e4399313e0',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            7,
            'SupportedKinds',
            'Supported Kinds',
            NULL,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '2b27de14-383f-4d07-9dcf-050237cec7c7' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = 'DefaultQualificationPolicy')) BEGIN
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
            '2b27de14-383f-4d07-9dcf-050237cec7c7',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            8,
            'DefaultQualificationPolicy',
            'Default Qualification Policy',
            'What an Undecided qualification verdict means for this provider once every rule stage has abstained. Exclude (the default) fails CLOSED — correct for anything mailbox-shaped, where capturing a private message is worse than missing a business one.',
            'nvarchar',
            40,
            0,
            0,
            0,
            'Exclude',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '10fdaf3a-2042-41f1-b148-beffc8fcb001' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = 'DefaultSkippedContentPolicy')) BEGIN
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
            '10fdaf3a-2042-41f1-b148-beffc8fcb001',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            9,
            'DefaultSkippedContentPolicy',
            'Default Skipped Content Policy',
            'Whether a SKIPPED message may have content retained for audit, and how much. None keeps only the opaque external id and the decision. SubjectEncrypted and FullEncrypted additionally keep ciphertext, and are only valid with DefaultEncryptionKeyID set — enforced by CK_ActivitySyncProviderType_KeyRequired. Overridable per connection.',
            'nvarchar',
            40,
            0,
            0,
            0,
            'None',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '5e2effe9-2376-454d-8f8c-7e967e27e485' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = 'DefaultEncryptionKeyID')) BEGIN
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
            '5e2effe9-2376-454d-8f8c-7e967e27e485',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            10,
            'DefaultEncryptionKeyID',
            'Default Encryption Key ID',
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
            '854DB803-34D4-46CD-8B8D-712974AE592F',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'd1c50585-1359-49b7-a011-6d590570b9e1' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = 'DefaultStorageProviderID')) BEGIN
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
            'd1c50585-1359-49b7-a011-6d590570b9e1',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            11,
            'DefaultStorageProviderID',
            'Default Storage Provider ID',
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
            '28248F34-2837-EF11-86D4-6045BDEE16E6',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '827d6b7c-ba37-446c-a9c1-912320c1aff3' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = 'DefaultMaxAttachmentBytes')) BEGIN
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
            '827d6b7c-ba37-446c-a9c1-912320c1aff3',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            12,
            'DefaultMaxAttachmentBytes',
            'Default Max Attachment Bytes',
            NULL,
            'bigint',
            8,
            19,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8f863005-aa6e-40a3-8ede-5601e45281e0' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = 'Sequence')) BEGIN
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
            '8f863005-aa6e-40a3-8ede-5601e45281e0',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            13,
            'Sequence',
            'Sequence',
            NULL,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f609014d-e4d4-41a9-b26c-a12871cc782c' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = 'IsSystem')) BEGIN
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
            'f609014d-e4d4-41a9-b26c-a12871cc782c',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            14,
            'IsSystem',
            'Is System',
            NULL,
            'bit',
            1,
            1,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'd6351250-3c56-41cb-a5c1-003df4812fc3' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = 'IsActive')) BEGIN
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
            'd6351250-3c56-41cb-a5c1-003df4812fc3',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            15,
            'IsActive',
            'Is Active',
            NULL,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '5e0546dd-7ea6-48ed-81df-3b9bfae705cd' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = '__mj_CreatedAt')) BEGIN
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
            '5e0546dd-7ea6-48ed-81df-3b9bfae705cd',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            16,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'ffcd695a-8745-44ba-af76-b532f8bd5db5' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = '__mj_UpdatedAt')) BEGIN
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
            'ffcd695a-8745-44ba-af76-b532f8bd5db5',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            17,
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
UPDATE [${mjSchema}].[EntityField]
         SET [Sequence] = [Sequence] + 100000
       WHERE [EntityID] = 'AC16B066-9460-44F5-B027-3FD397E61F34'
         AND [Sequence] < 100000;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '87194352-7d59-4bb2-af24-c815d3d43892' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'ID')) BEGIN
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
            '87194352-7d59-4bb2-af24-c815d3d43892',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            1,
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
            1,
            0,
            0,
            1,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '92dd62bb-d66f-401b-8830-33b3246b0e26' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'ActivitySyncRunID')) BEGIN
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
            '92dd62bb-d66f-401b-8830-33b3246b0e26',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            2,
            'ActivitySyncRunID',
            'Activity Sync Run ID',
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
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '36d13a87-c5b8-472a-9cda-eb3731afcc41' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'ExternalID')) BEGIN
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
            '36d13a87-c5b8-472a-9cda-eb3731afcc41',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            3,
            'ExternalID',
            'External ID',
            NULL,
            'nvarchar',
            800,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '15dd6494-57f4-42ca-bd84-0a15426a96be' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'ExternalThreadID')) BEGIN
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
            '15dd6494-57f4-42ca-bd84-0a15426a96be',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            4,
            'ExternalThreadID',
            'External Thread ID',
            NULL,
            'nvarchar',
            800,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '7e700ed9-c6e6-487c-9304-aa7bb9fc222b' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'OccurredAt')) BEGIN
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
            '7e700ed9-c6e6-487c-9304-aa7bb9fc222b',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            5,
            'OccurredAt',
            'Occurred At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '0078772b-133b-45cd-b584-0d96cbf51a88' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'Decision')) BEGIN
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
            '0078772b-133b-45cd-b584-0d96cbf51a88',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            6,
            'Decision',
            'Decision',
            NULL,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '38a89e25-30dd-4d1b-83d2-5e824d542e6d' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'DecidedByStage')) BEGIN
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
            '38a89e25-30dd-4d1b-83d2-5e824d542e6d',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            7,
            'DecidedByStage',
            'Decided By Stage',
            'Which stage of the qualification cascade decided — a rule set name, KnownParticipant, Inference, or DefaultPolicy. Paired with Reason it explains an outcome without retaining the message that produced it.',
            'nvarchar',
            200,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f9d3b360-0da7-4fb7-ac4f-8ca065aa9bf3' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'ActivitySyncRuleID')) BEGIN
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
            'f9d3b360-0da7-4fb7-ac4f-8ca065aa9bf3',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            8,
            'ActivitySyncRuleID',
            'Activity Sync Rule ID',
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
            '21B78371-132C-4507-AED8-D44E366468F2',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'b7be5c0e-e4d5-42fc-9b82-c0fd25de4b2a' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'ActivitySyncExclusionID')) BEGIN
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
            'b7be5c0e-e4d5-42fc-9b82-c0fd25de4b2a',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            9,
            'ActivitySyncExclusionID',
            'Activity Sync Exclusion ID',
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
            '556381BF-9ACE-4A69-85BB-22EAE1856C88',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f31cbd79-1083-435a-9d00-39a89f03b524' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'Reason')) BEGIN
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
            'f31cbd79-1083-435a-9d00-39a89f03b524',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            10,
            'Reason',
            'Reason',
            NULL,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '74f9bdc0-2b51-4f54-80dd-62677c682d67' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'Confidence')) BEGIN
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
            '74f9bdc0-2b51-4f54-80dd-62677c682d67',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            11,
            'Confidence',
            'Confidence',
            NULL,
            'decimal',
            5,
            5,
            4,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '21e93bc8-0535-445f-aafd-f3468f1eb62d' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'AIPromptRunID')) BEGIN
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
            '21e93bc8-0535-445f-aafd-f3468f1eb62d',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            12,
            'AIPromptRunID',
            'AI Prompt Run ID',
            'The MJ: AI Prompt Run behind an inference-stage verdict. Non-null only when a model actually decided this item, which is the audit trail for every automated judgement the engine makes.',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '4087a170-cd32-4b2a-a59e-e2747f272aa8' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'ActivityID')) BEGIN
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
            '4087a170-cd32-4b2a-a59e-e2747f272aa8',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            13,
            'ActivityID',
            'Activity ID',
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
            '72E55425-8822-4E70-A075-116219CA5A5D',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '7905d4d1-557e-4693-92a9-8cd497d793cd' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'CapturedContent')) BEGIN
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
            '7905d4d1-557e-4693-92a9-8cd497d793cd',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            14,
            'CapturedContent',
            'Captured Content',
            'Ciphertext, always — never plaintext, whatever the policy. Present only when the effective SkippedContentPolicy allows retention, and always paired with the EncryptionKeyID that opens it (CK_ActivitySyncRunDetail_ContentKey). Encrypted through MJ''s EncryptionEngine against an MJ: Encryption Keys row; this app never implements its own crypto.',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '1e55257f-d2be-4817-82c9-723aee6f8e42' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'EncryptionKeyID')) BEGIN
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
            '1e55257f-d2be-4817-82c9-723aee6f8e42',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            15,
            'EncryptionKeyID',
            'Encryption Key ID',
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
            '854DB803-34D4-46CD-8B8D-712974AE592F',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '07f6ab2b-c765-45a5-bafe-6166ec42f137' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = '__mj_CreatedAt')) BEGIN
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
            '07f6ab2b-c765-45a5-bafe-6166ec42f137',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            16,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '5cda5908-7b09-4ea1-bfdf-75fa10555031' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = '__mj_UpdatedAt')) BEGIN
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
            '5cda5908-7b09-4ea1-bfdf-75fa10555031',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            17,
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
UPDATE [${mjSchema}].[EntityField]
         SET [Sequence] = [Sequence] + 100000
       WHERE [EntityID] = 'C22591BB-B33A-439C-9567-5494A7B71D8A'
         AND [Sequence] < 100000;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '0eeefd0a-3809-4be9-b54e-c7c7efc8dbd0' OR (EntityID = 'C22591BB-B33A-439C-9567-5494A7B71D8A' AND Name = 'ActivitySyncProviderTypeID')) BEGIN
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
            '0eeefd0a-3809-4be9-b54e-c7c7efc8dbd0',
            'C22591BB-B33A-439C-9567-5494A7B71D8A', -- Entity: MJ_BizApps_Common: Activity Sync Connections
            14,
            'ActivitySyncProviderTypeID',
            'Activity Sync Provider Type ID',
            'The provider type this connection reads. Supersedes the Provider string column, whose CHECK constraint made every new source a migration to Common.',
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
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '55161592-6265-4026-a501-72a6eb5a0e14' OR (EntityID = 'C22591BB-B33A-439C-9567-5494A7B71D8A' AND Name = 'StartAt')) BEGIN
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
            '55161592-6265-4026-a501-72a6eb5a0e14',
            'C22591BB-B33A-439C-9567-5494A7B71D8A', -- Entity: MJ_BizApps_Common: Activity Sync Connections
            15,
            'StartAt',
            'Start At',
            'Activation window. Combines with Status: a connection syncs only when Status = Active AND now is within [StartAt, EndAt], treating either bound as open when null. Lets a mailbox be provisioned ahead of time, or retired on a date, without anyone remembering to flip a switch.',
            'datetimeoffset',
            10,
            34,
            7,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '068bee66-56da-445d-946e-514b1f3410c0' OR (EntityID = 'C22591BB-B33A-439C-9567-5494A7B71D8A' AND Name = 'EndAt')) BEGIN
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
            '068bee66-56da-445d-946e-514b1f3410c0',
            'C22591BB-B33A-439C-9567-5494A7B71D8A', -- Entity: MJ_BizApps_Common: Activity Sync Connections
            16,
            'EndAt',
            'End At',
            'End of the activation window; see StartAt. Null means open-ended.',
            'datetimeoffset',
            10,
            34,
            7,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '1e88da7c-c64b-4d7a-b218-804a9aeea2fa' OR (EntityID = 'C22591BB-B33A-439C-9567-5494A7B71D8A' AND Name = 'SkippedContentPolicy')) BEGIN
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
            '1e88da7c-c64b-4d7a-b218-804a9aeea2fa',
            'C22591BB-B33A-439C-9567-5494A7B71D8A', -- Entity: MJ_BizApps_Common: Activity Sync Connections
            17,
            'SkippedContentPolicy',
            'Skipped Content Policy',
            'Per-connection override of the provider type''s DefaultSkippedContentPolicy. Null inherits. This is the knob for "this one mailbox is sensitive" without changing the estate.',
            'nvarchar',
            40,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '2a5381dd-a180-4e03-9c04-9815703ddee3' OR (EntityID = 'C22591BB-B33A-439C-9567-5494A7B71D8A' AND Name = 'EncryptionKeyID')) BEGIN
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
            '2a5381dd-a180-4e03-9c04-9815703ddee3',
            'C22591BB-B33A-439C-9567-5494A7B71D8A', -- Entity: MJ_BizApps_Common: Activity Sync Connections
            18,
            'EncryptionKeyID',
            'Encryption Key ID',
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
            '854DB803-34D4-46CD-8B8D-712974AE592F',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '136ff7b4-bc67-4c96-98b2-9fd82c21363b' OR (EntityID = 'C22591BB-B33A-439C-9567-5494A7B71D8A' AND Name = 'StorageProviderID')) BEGIN
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
            '136ff7b4-bc67-4c96-98b2-9fd82c21363b',
            'C22591BB-B33A-439C-9567-5494A7B71D8A', -- Entity: MJ_BizApps_Common: Activity Sync Connections
            19,
            'StorageProviderID',
            'Storage Provider ID',
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
            '28248F34-2837-EF11-86D4-6045BDEE16E6',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'a8e6fdd3-f038-42cb-a9da-d92c5105ec34' OR (EntityID = 'C22591BB-B33A-439C-9567-5494A7B71D8A' AND Name = 'MaxAttachmentBytes')) BEGIN
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
            'a8e6fdd3-f038-42cb-a9da-d92c5105ec34',
            'C22591BB-B33A-439C-9567-5494A7B71D8A', -- Entity: MJ_BizApps_Common: Activity Sync Connections
            20,
            'MaxAttachmentBytes',
            'Max Attachment Bytes',
            NULL,
            'bigint',
            8,
            19,
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
UPDATE [${mjSchema}].[EntityField]
         SET [Sequence] = [Sequence] + 100000
       WHERE [EntityID] = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1'
         AND [Sequence] < 100000;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'ab8bb2dc-fde4-400d-bc2f-a2e77bd22d57' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = 'ID')) BEGIN
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
            'ab8bb2dc-fde4-400d-bc2f-a2e77bd22d57',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            1,
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
            1,
            0,
            0,
            1,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '721edd40-b7f9-4227-bde7-f276389364f0' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = 'ActivitySyncConnectionID')) BEGIN
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
            '721edd40-b7f9-4227-bde7-f276389364f0',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            2,
            'ActivitySyncConnectionID',
            'Activity Sync Connection ID',
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
            'C22591BB-B33A-439C-9567-5494A7B71D8A',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '23d4f371-f534-4ff6-880d-d3b7a9eb5032' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = 'StartedAt')) BEGIN
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
            '23d4f371-f534-4ff6-880d-d3b7a9eb5032',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            3,
            'StartedAt',
            'Started At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'sysdatetimeoffset()',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '3b1e4e05-435b-4f9d-8288-c1961123b8ec' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = 'EndedAt')) BEGIN
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
            '3b1e4e05-435b-4f9d-8288-c1961123b8ec',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            4,
            'EndedAt',
            'Ended At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'ba933d11-ce9f-4f78-863f-8c73443df808' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = 'Status')) BEGIN
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
            'ba933d11-ce9f-4f78-863f-8c73443df808',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            5,
            'Status',
            'Status',
            NULL,
            'nvarchar',
            40,
            0,
            0,
            0,
            'Running',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '1b3e1546-1ce5-417f-bf91-e64d591079ed' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = 'TriggerType')) BEGIN
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
            '1b3e1546-1ce5-417f-bf91-e64d591079ed',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            6,
            'TriggerType',
            'Trigger Type',
            NULL,
            'nvarchar',
            40,
            0,
            0,
            0,
            'Scheduled',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'd29a08ef-c6c7-4aac-8239-d3db29a2d011' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = 'IsDryRun')) BEGIN
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
            'd29a08ef-c6c7-4aac-8239-d3db29a2d011',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            7,
            'IsDryRun',
            'Is Dry Run',
            NULL,
            'bit',
            1,
            1,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'fbbbe636-ee2a-4b4c-92a4-17e9b872495e' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = 'Fetched')) BEGIN
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
            'fbbbe636-ee2a-4b4c-92a4-17e9b872495e',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            8,
            'Fetched',
            'Fetched',
            NULL,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '666aadeb-9b84-4b06-b89c-6b46eba5c9a8' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = 'Included')) BEGIN
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
            '666aadeb-9b84-4b06-b89c-6b46eba5c9a8',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            9,
            'Included',
            'Included',
            NULL,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '930f7630-5819-4b43-a54f-b2de76900ea0' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = 'Excluded')) BEGIN
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
            '930f7630-5819-4b43-a54f-b2de76900ea0',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            10,
            'Excluded',
            'Excluded',
            NULL,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '77461d70-12ab-4f6a-97b8-253140d4efbd' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = 'Duplicates')) BEGIN
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
            '77461d70-12ab-4f6a-97b8-253140d4efbd',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            11,
            'Duplicates',
            'Duplicates',
            NULL,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '674b8800-2821-494e-a291-6c1f3ad8764e' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = 'Failed')) BEGIN
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
            '674b8800-2821-494e-a291-6c1f3ad8764e',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            12,
            'Failed',
            'Failed',
            NULL,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '18d52c2d-5d4e-4c33-840f-fffc866a3ee5' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = 'ExtensionErrors')) BEGIN
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
            '18d52c2d-5d4e-4c33-840f-fffc866a3ee5',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            13,
            'ExtensionErrors',
            'Extension Errors',
            NULL,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c886d78b-82d5-4d3c-8a05-94f8db060525' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = 'WatermarkBefore')) BEGIN
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
            'c886d78b-82d5-4d3c-8a05-94f8db060525',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            14,
            'WatermarkBefore',
            'Watermark Before',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '0221e342-6338-48cf-a821-12f7ed4af644' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = 'WatermarkAfter')) BEGIN
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
            '0221e342-6338-48cf-a821-12f7ed4af644',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            15,
            'WatermarkAfter',
            'Watermark After',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '22813953-a45f-4a63-97b9-440330021ad4' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = 'ErrorMessage')) BEGIN
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
            '22813953-a45f-4a63-97b9-440330021ad4',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            16,
            'ErrorMessage',
            'Error Message',
            NULL,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '7fb56db3-4235-473e-8034-34fde9f8458e' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = '__mj_CreatedAt')) BEGIN
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
            '7fb56db3-4235-473e-8034-34fde9f8458e',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            17,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8474a9be-ca44-4467-816a-65d885e0e44e' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = '__mj_UpdatedAt')) BEGIN
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
            '8474a9be-ca44-4467-816a-65d885e0e44e',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            18,
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
UPDATE [${mjSchema}].[EntityField]
         SET [Sequence] = [Sequence] + 100000
       WHERE [EntityID] = '7ED9F26E-B01D-472A-87C9-B163287F80B4'
         AND [Sequence] < 100000;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '5f781a56-a58e-4f5e-9fb6-9e602bc31892' OR (EntityID = '7ED9F26E-B01D-472A-87C9-B163287F80B4' AND Name = 'ID')) BEGIN
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
            '5f781a56-a58e-4f5e-9fb6-9e602bc31892',
            '7ED9F26E-B01D-472A-87C9-B163287F80B4', -- Entity: MJ_BizApps_Common: Activity Sync Rule Sets
            1,
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
            1,
            0,
            0,
            1,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '7b94c459-6d4f-45f6-85a8-c6f436d83b1c' OR (EntityID = '7ED9F26E-B01D-472A-87C9-B163287F80B4' AND Name = 'Name')) BEGIN
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
            '7b94c459-6d4f-45f6-85a8-c6f436d83b1c',
            '7ED9F26E-B01D-472A-87C9-B163287F80B4', -- Entity: MJ_BizApps_Common: Activity Sync Rule Sets
            2,
            'Name',
            'Name',
            NULL,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'e56c30dd-befc-4a2f-8447-314d1a1578e5' OR (EntityID = '7ED9F26E-B01D-472A-87C9-B163287F80B4' AND Name = 'Description')) BEGIN
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
            'e56c30dd-befc-4a2f-8447-314d1a1578e5',
            '7ED9F26E-B01D-472A-87C9-B163287F80B4', -- Entity: MJ_BizApps_Common: Activity Sync Rule Sets
            3,
            'Description',
            'Description',
            NULL,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '1cb40317-e514-4bb1-86bf-c8b2b18ae84c' OR (EntityID = '7ED9F26E-B01D-472A-87C9-B163287F80B4' AND Name = 'ActivitySyncProviderTypeID')) BEGIN
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
            '1cb40317-e514-4bb1-86bf-c8b2b18ae84c',
            '7ED9F26E-B01D-472A-87C9-B163287F80B4', -- Entity: MJ_BizApps_Common: Activity Sync Rule Sets
            4,
            'ActivitySyncProviderTypeID',
            'Activity Sync Provider Type ID',
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
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '990e8112-4f9b-439e-8a0d-8472b630c5f9' OR (EntityID = '7ED9F26E-B01D-472A-87C9-B163287F80B4' AND Name = 'InternalDomains')) BEGIN
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
            '990e8112-4f9b-439e-8a0d-8472b630c5f9',
            '7ED9F26E-B01D-472A-87C9-B163287F80B4', -- Entity: MJ_BizApps_Common: Activity Sync Rule Sets
            5,
            'InternalDomains',
            'Internal Domains',
            'JSON array of the domains this deployment considers INTERNAL, e.g. ["bluecypress.io"]. Required for any rule using ParticipantScope: "internal" is a property of the deployment, not of a message. Held on the rule set so one definition serves every mailbox bound to it.',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '7bafea34-d767-4b1b-8d6f-c304bc765ca5' OR (EntityID = '7ED9F26E-B01D-472A-87C9-B163287F80B4' AND Name = 'Sequence')) BEGIN
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
            '7bafea34-d767-4b1b-8d6f-c304bc765ca5',
            '7ED9F26E-B01D-472A-87C9-B163287F80B4', -- Entity: MJ_BizApps_Common: Activity Sync Rule Sets
            6,
            'Sequence',
            'Sequence',
            NULL,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '9fc296ef-bd9d-417d-b75b-bcc67a253534' OR (EntityID = '7ED9F26E-B01D-472A-87C9-B163287F80B4' AND Name = 'IsEnabled')) BEGIN
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
            '9fc296ef-bd9d-417d-b75b-bcc67a253534',
            '7ED9F26E-B01D-472A-87C9-B163287F80B4', -- Entity: MJ_BizApps_Common: Activity Sync Rule Sets
            7,
            'IsEnabled',
            'Is Enabled',
            NULL,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'a239da06-157e-477e-905d-d306159cc1f3' OR (EntityID = '7ED9F26E-B01D-472A-87C9-B163287F80B4' AND Name = 'IsSystem')) BEGIN
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
            'a239da06-157e-477e-905d-d306159cc1f3',
            '7ED9F26E-B01D-472A-87C9-B163287F80B4', -- Entity: MJ_BizApps_Common: Activity Sync Rule Sets
            8,
            'IsSystem',
            'Is System',
            NULL,
            'bit',
            1,
            1,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '4fd3836b-cea9-43c3-b81e-3b0f3a5c0c21' OR (EntityID = '7ED9F26E-B01D-472A-87C9-B163287F80B4' AND Name = '__mj_CreatedAt')) BEGIN
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
            '4fd3836b-cea9-43c3-b81e-3b0f3a5c0c21',
            '7ED9F26E-B01D-472A-87C9-B163287F80B4', -- Entity: MJ_BizApps_Common: Activity Sync Rule Sets
            9,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '5515d121-d16f-4aea-a77a-6e094274ddee' OR (EntityID = '7ED9F26E-B01D-472A-87C9-B163287F80B4' AND Name = '__mj_UpdatedAt')) BEGIN
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
            '5515d121-d16f-4aea-a77a-6e094274ddee',
            '7ED9F26E-B01D-472A-87C9-B163287F80B4', -- Entity: MJ_BizApps_Common: Activity Sync Rule Sets
            10,
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
UPDATE [${mjSchema}].[EntityField]
         SET [Sequence] = [Sequence] + 100000
       WHERE [EntityID] = '21B78371-132C-4507-AED8-D44E366468F2'
         AND [Sequence] < 100000;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '3b472ade-9440-46fc-ab87-9cb4b27fe729' OR (EntityID = '21B78371-132C-4507-AED8-D44E366468F2' AND Name = 'ActivitySyncRuleSetID')) BEGIN
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
            '3b472ade-9440-46fc-ab87-9cb4b27fe729',
            '21B78371-132C-4507-AED8-D44E366468F2', -- Entity: MJ_BizApps_Common: Activity Sync Rules
            15,
            'ActivitySyncRuleSetID',
            'Activity Sync Rule Set ID',
            'The rule set this rule belongs to. Exactly one of ActivitySyncRuleSetID and ActivitySyncConnectionID is set (CK_ActivitySyncRule_Owner) — the connection form is the deprecated original and remains only so existing rows stay valid.',
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
            '7ED9F26E-B01D-472A-87C9-B163287F80B4',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'ae0a8eb2-3130-4cbf-98fa-ca3c3676795b' OR (EntityID = '21B78371-132C-4507-AED8-D44E366468F2' AND Name = 'ParticipantScope')) BEGIN
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
            'ae0a8eb2-3130-4cbf-98fa-ca3c3676795b',
            '21B78371-132C-4507-AED8-D44E366468F2', -- Entity: MJ_BizApps_Common: Activity Sync Rules
            16,
            'ParticipantScope',
            'Participant Scope',
            'Which participants must be present for this rule to apply — the internal/external control. AllInternal excludes purely internal chatter; HasExternal catches a thread with any outside party on it; Mixed is the case an all-or-nothing rule gets wrong. Requires the rule set to define InternalDomains. Null means the rule does not test participants.',
            'nvarchar',
            60,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'dca96b15-b3ee-4f41-bbd1-146c71922ba8' OR (EntityID = '21B78371-132C-4507-AED8-D44E366468F2' AND Name = 'MaxAttachmentBytes')) BEGIN
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
            'dca96b15-b3ee-4f41-bbd1-146c71922ba8',
            '21B78371-132C-4507-AED8-D44E366468F2', -- Entity: MJ_BizApps_Common: Activity Sync Rules
            17,
            'MaxAttachmentBytes',
            'Max Attachment Bytes',
            NULL,
            'bigint',
            8,
            19,
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
UPDATE [${mjSchema}].[EntityField]
         SET [Sequence] = [Sequence] + 100000
       WHERE [EntityID] = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449'
         AND [Sequence] < 100000;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8ff6284e-9816-42da-939c-b353b11dafeb' OR (EntityID = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449' AND Name = 'ID')) BEGIN
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
            '8ff6284e-9816-42da-939c-b353b11dafeb',
            'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', -- Entity: MJ_BizApps_Common: Activity Sync Extensions
            1,
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
            1,
            0,
            0,
            1,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'e6722a67-7051-46f8-8c6f-b3475b4f6b69' OR (EntityID = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449' AND Name = 'Name')) BEGIN
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
            'e6722a67-7051-46f8-8c6f-b3475b4f6b69',
            'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', -- Entity: MJ_BizApps_Common: Activity Sync Extensions
            2,
            'Name',
            'Name',
            NULL,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '2665d26d-e5d2-42eb-acd0-6dab290d3b9e' OR (EntityID = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449' AND Name = 'Description')) BEGIN
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
            '2665d26d-e5d2-42eb-acd0-6dab290d3b9e',
            'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', -- Entity: MJ_BizApps_Common: Activity Sync Extensions
            3,
            'Description',
            'Description',
            NULL,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'd75c9fd1-f6a9-450a-b405-aff4728750d6' OR (EntityID = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449' AND Name = 'DriverClass')) BEGIN
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
            'd75c9fd1-f6a9-450a-b405-aff4728750d6',
            'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', -- Entity: MJ_BizApps_Common: Activity Sync Extensions
            4,
            'DriverClass',
            'Driver Class',
            NULL,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'cefe0ec3-92e4-4890-b36a-3e9ce5f60ee6' OR (EntityID = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449' AND Name = 'ActivitySyncConnectionID')) BEGIN
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
            'cefe0ec3-92e4-4890-b36a-3e9ce5f60ee6',
            'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', -- Entity: MJ_BizApps_Common: Activity Sync Extensions
            5,
            'ActivitySyncConnectionID',
            'Activity Sync Connection ID',
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
            'C22591BB-B33A-439C-9567-5494A7B71D8A',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '6c142921-feee-4d50-a601-adb0b370ee47' OR (EntityID = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449' AND Name = 'ActivitySyncProviderTypeID')) BEGIN
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
            '6c142921-feee-4d50-a601-adb0b370ee47',
            'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', -- Entity: MJ_BizApps_Common: Activity Sync Extensions
            6,
            'ActivitySyncProviderTypeID',
            'Activity Sync Provider Type ID',
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
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '7790ea43-823f-4fa3-963d-a1110d614029' OR (EntityID = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449' AND Name = 'Sequence')) BEGIN
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
            '7790ea43-823f-4fa3-963d-a1110d614029',
            'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', -- Entity: MJ_BizApps_Common: Activity Sync Extensions
            7,
            'Sequence',
            'Sequence',
            'Ascending run order. REQUIRED rather than incidental: two extensions both adding links must not depend on registration order, which varies with package load order and is not reproducible.',
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'fd76a168-2af9-462d-b284-549ab7cced6f' OR (EntityID = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449' AND Name = 'FailurePolicy')) BEGIN
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
            'fd76a168-2af9-462d-b284-549ab7cced6f',
            'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', -- Entity: MJ_BizApps_Common: Activity Sync Extensions
            8,
            'FailurePolicy',
            'Failure Policy',
            'What happens when this extension throws. Skip (the default) records the error and commits the activity without the enrichment; Abort rolls the whole write back. Skip is the default because the activity is worth more than the enrichment, and one buggy consumer app must not be able to halt ingestion for every other app on the host.',
            'nvarchar',
            40,
            0,
            0,
            0,
            'Skip',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'a12a8c4c-dbd9-40fb-97b4-3872aa966fc3' OR (EntityID = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449' AND Name = 'TimeoutMS')) BEGIN
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
            'a12a8c4c-dbd9-40fb-97b4-3872aa966fc3',
            'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', -- Entity: MJ_BizApps_Common: Activity Sync Extensions
            9,
            'TimeoutMS',
            'Timeout MS',
            NULL,
            'int',
            4,
            10,
            0,
            0,
            '(5000)',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '70ff0fe5-2a34-430f-85e4-10a5a38f83ca' OR (EntityID = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449' AND Name = 'IsEnabled')) BEGIN
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
            '70ff0fe5-2a34-430f-85e4-10a5a38f83ca',
            'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', -- Entity: MJ_BizApps_Common: Activity Sync Extensions
            10,
            'IsEnabled',
            'Is Enabled',
            NULL,
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
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'b0acf26a-484c-4a19-899b-b6995030ead7' OR (EntityID = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449' AND Name = 'LastRunAt')) BEGIN
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
            'b0acf26a-484c-4a19-899b-b6995030ead7',
            'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', -- Entity: MJ_BizApps_Common: Activity Sync Extensions
            11,
            'LastRunAt',
            'Last Run At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '840551bd-057b-44cb-9651-d8cda50f7f06' OR (EntityID = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449' AND Name = 'LastError')) BEGIN
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
            '840551bd-057b-44cb-9651-d8cda50f7f06',
            'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', -- Entity: MJ_BizApps_Common: Activity Sync Extensions
            12,
            'LastError',
            'Last Error',
            NULL,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'ee946000-7849-412f-ae49-71d092d7c389' OR (EntityID = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449' AND Name = '__mj_CreatedAt')) BEGIN
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
            'ee946000-7849-412f-ae49-71d092d7c389',
            'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', -- Entity: MJ_BizApps_Common: Activity Sync Extensions
            13,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'fbf026fb-33e9-4a3e-ac40-63062a60d26b' OR (EntityID = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449' AND Name = '__mj_UpdatedAt')) BEGIN
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
            'fbf026fb-33e9-4a3e-ac40-63062a60d26b',
            'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', -- Entity: MJ_BizApps_Common: Activity Sync Extensions
            14,
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

/* SQL text to update existing entity fields from schema
   SCOPED to the seven NEW Activity Sync entities. The unscoped form
   (CodeGen's live-DB emit) also rewrites Sequence on existing
   ActivitySyncConnection / ActivitySyncRule fields from SQL ordinals,
   which collides with UQ_EntityField_EntityID_Sequence once this
   migration has inserted the new columns at those sequence numbers.
   A host that only runs mj migrate never runs CodeGen, so this call
   must not touch entities that already shipped in V202608251531. */
EXEC [${mjSchema}].[spUpdateExistingEntityFieldsFromSchema]
    @ExcludedSchemaNames='',
    @EntityIDs='AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75,7ED9F26E-B01D-472A-87C9-B163287F80B4,D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0,556381BF-9ACE-4A69-85BB-22EAE1856C88,ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1,AC16B066-9460-44F5-B027-3FD397E61F34,C7E5ECE1-F347-4BC9-AC53-E2F33577B449',
    @IncludedSchemaNames='${flyway:defaultSchema}';

/* SQL text to set default column width where needed */
EXEC [${mjSchema}].[spSetDefaultColumnWidthWhereNeeded] @ExcludedSchemaNames='', @IncludedSchemaNames='${flyway:defaultSchema}';

/* SQL text to insert entity field value with ID 25b1b24b-41ab-49a1-8c75-6a199530db14 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('25b1b24b-41ab-49a1-8c75-6a199530db14', '2B27DE14-383F-4D07-9DCF-050237CEC7C7', 1, 'Exclude', 'Exclude', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 05d3c571-b899-4096-8070-b9c0ca79cbc8 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('05d3c571-b899-4096-8070-b9c0ca79cbc8', '2B27DE14-383F-4D07-9DCF-050237CEC7C7', 2, 'Include', 'Include', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 2B27DE14-383F-4D07-9DCF-050237CEC7C7 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='2B27DE14-383F-4D07-9DCF-050237CEC7C7';

/* SQL text to insert entity field value with ID 01a9fe4e-e4bc-4633-b7f5-ad601bac07c3 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('01a9fe4e-e4bc-4633-b7f5-ad601bac07c3', '10FDAF3A-2042-41F1-B148-BEFFC8FCB001', 1, 'FullEncrypted', 'FullEncrypted', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 03618c22-8a98-4271-b82f-cfaf956a789c */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('03618c22-8a98-4271-b82f-cfaf956a789c', '10FDAF3A-2042-41F1-B148-BEFFC8FCB001', 2, 'None', 'None', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID ab6ef7c0-c416-4bbd-be89-43cc412b3915 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('ab6ef7c0-c416-4bbd-be89-43cc412b3915', '10FDAF3A-2042-41F1-B148-BEFFC8FCB001', 3, 'SubjectEncrypted', 'SubjectEncrypted', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 10FDAF3A-2042-41F1-B148-BEFFC8FCB001 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='10FDAF3A-2042-41F1-B148-BEFFC8FCB001';

/* SQL text to insert entity field value with ID 2731345f-de5d-4412-95a5-5a0a0b6e9a12 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('2731345f-de5d-4412-95a5-5a0a0b6e9a12', 'AD5A0FB1-1144-408A-A0E8-3F300BC786AC', 1, 'Domain', 'Domain', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID cbf21b53-1347-4cec-9712-d913b9ec339a */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('cbf21b53-1347-4cec-9712-d913b9ec339a', 'AD5A0FB1-1144-408A-A0E8-3F300BC786AC', 2, 'Email', 'Email', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 9042e972-cdb1-41f6-bdb6-0b4e1249536a */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('9042e972-cdb1-41f6-bdb6-0b4e1249536a', 'AD5A0FB1-1144-408A-A0E8-3F300BC786AC', 3, 'Handle', 'Handle', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 3f07ec49-12b2-4875-aaf3-4fa8434d4e9d */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('3f07ec49-12b2-4875-aaf3-4fa8434d4e9d', 'AD5A0FB1-1144-408A-A0E8-3F300BC786AC', 4, 'Phone', 'Phone', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID AD5A0FB1-1144-408A-A0E8-3F300BC786AC */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='AD5A0FB1-1144-408A-A0E8-3F300BC786AC';

/* SQL text to insert entity field value with ID fcb5f25d-ff42-4974-bdbf-51d2b11e72cb */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('fcb5f25d-ff42-4974-bdbf-51d2b11e72cb', 'BA933D11-CE9F-4F78-863F-8C73443DF808', 1, 'Cancelled', 'Cancelled', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 1c5136d1-112c-4651-a167-942583ebd13e */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('1c5136d1-112c-4651-a167-942583ebd13e', 'BA933D11-CE9F-4F78-863F-8C73443DF808', 2, 'Completed', 'Completed', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 90a1362f-d2a9-44e0-a6da-aed6cde885f8 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('90a1362f-d2a9-44e0-a6da-aed6cde885f8', 'BA933D11-CE9F-4F78-863F-8C73443DF808', 3, 'Failed', 'Failed', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 4fcd310a-bd97-48b4-8d97-8d01ac772037 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('4fcd310a-bd97-48b4-8d97-8d01ac772037', 'BA933D11-CE9F-4F78-863F-8C73443DF808', 4, 'Running', 'Running', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID BA933D11-CE9F-4F78-863F-8C73443DF808 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='BA933D11-CE9F-4F78-863F-8C73443DF808';

/* SQL text to insert entity field value with ID 890b8ebb-6c06-46a1-a107-db0acf6e8d18 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('890b8ebb-6c06-46a1-a107-db0acf6e8d18', '1B3E1546-1CE5-417F-BF91-E64D591079ED', 1, 'Backfill', 'Backfill', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 92e464e1-440d-45f1-8e6c-5186a2ca3441 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('92e464e1-440d-45f1-8e6c-5186a2ca3441', '1B3E1546-1CE5-417F-BF91-E64D591079ED', 2, 'Manual', 'Manual', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 42560280-9d99-46b7-8900-754df07d9112 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('42560280-9d99-46b7-8900-754df07d9112', '1B3E1546-1CE5-417F-BF91-E64D591079ED', 3, 'Scheduled', 'Scheduled', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 9b6315cb-4e56-4c2d-93bf-1fc09ae49ad2 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('9b6315cb-4e56-4c2d-93bf-1fc09ae49ad2', '1B3E1546-1CE5-417F-BF91-E64D591079ED', 4, 'Webhook', 'Webhook', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 1B3E1546-1CE5-417F-BF91-E64D591079ED */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='1B3E1546-1CE5-417F-BF91-E64D591079ED';

/* SQL text to insert entity field value with ID ce1dc7c4-a826-4449-97c8-47edcd0b504d */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('ce1dc7c4-a826-4449-97c8-47edcd0b504d', '0078772B-133B-45CD-B584-0D96CBF51A88', 1, 'Duplicate', 'Duplicate', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID a39c03f5-c710-4932-affe-7b5ee5b530fd */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('a39c03f5-c710-4932-affe-7b5ee5b530fd', '0078772B-133B-45CD-B584-0D96CBF51A88', 2, 'Excluded', 'Excluded', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID a25ceea6-43d8-47c2-9fb1-e12b230f9fec */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('a25ceea6-43d8-47c2-9fb1-e12b230f9fec', '0078772B-133B-45CD-B584-0D96CBF51A88', 3, 'Failed', 'Failed', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID a7d50b65-25fb-47cf-8ac6-64aa1057f8c0 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('a7d50b65-25fb-47cf-8ac6-64aa1057f8c0', '0078772B-133B-45CD-B584-0D96CBF51A88', 4, 'Included', 'Included', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID dd50c232-862e-49d3-84b6-2926039d9ad3 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('dd50c232-862e-49d3-84b6-2926039d9ad3', '0078772B-133B-45CD-B584-0D96CBF51A88', 5, 'WouldExclude', 'WouldExclude', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID d72fbcac-6439-4277-aa15-2cf7db8df547 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('d72fbcac-6439-4277-aa15-2cf7db8df547', '0078772B-133B-45CD-B584-0D96CBF51A88', 6, 'WouldInclude', 'WouldInclude', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 0078772B-133B-45CD-B584-0D96CBF51A88 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='0078772B-133B-45CD-B584-0D96CBF51A88';

/* SQL text to insert entity field value with ID 0bc3676c-d8e2-4fc7-8897-ad9b288a0f6d */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('0bc3676c-d8e2-4fc7-8897-ad9b288a0f6d', 'FD76A168-2AF9-462D-B284-549AB7CCED6F', 1, 'Abort', 'Abort', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID ef9ada9c-bad3-46dc-948e-2a2cb5575477 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('ef9ada9c-bad3-46dc-948e-2a2cb5575477', 'FD76A168-2AF9-462D-B284-549AB7CCED6F', 2, 'Skip', 'Skip', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID FD76A168-2AF9-462D-B284-549AB7CCED6F */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='FD76A168-2AF9-462D-B284-549AB7CCED6F';

/* SQL text to insert entity field value with ID a6d8c080-28cf-49e7-8419-1df6cfdb571a */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('a6d8c080-28cf-49e7-8419-1df6cfdb571a', '1E88DA7C-C64B-4D7A-B218-804A9AEEA2FA', 1, 'FullEncrypted', 'FullEncrypted', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID aca33bb4-76e5-4054-aa9d-23393c36efe5 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('aca33bb4-76e5-4054-aa9d-23393c36efe5', '1E88DA7C-C64B-4D7A-B218-804A9AEEA2FA', 2, 'None', 'None', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 1f650d73-be6b-4379-9a3c-d9a7dc496182 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('1f650d73-be6b-4379-9a3c-d9a7dc496182', '1E88DA7C-C64B-4D7A-B218-804A9AEEA2FA', 3, 'SubjectEncrypted', 'SubjectEncrypted', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 1E88DA7C-C64B-4D7A-B218-804A9AEEA2FA */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='1E88DA7C-C64B-4D7A-B218-804A9AEEA2FA';

/* SQL text to insert entity field value with ID b30788bf-f564-42d7-a9f5-8355f79f9a3a */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('b30788bf-f564-42d7-a9f5-8355f79f9a3a', 'AE0A8EB2-3130-4CBF-98FA-CA3C3676795B', 1, 'AllExternal', 'AllExternal', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID f064dfd9-bf58-4a37-87aa-36c7e74ba0ed */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('f064dfd9-bf58-4a37-87aa-36c7e74ba0ed', 'AE0A8EB2-3130-4CBF-98FA-CA3C3676795B', 2, 'AllInternal', 'AllInternal', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 844d7163-57ba-4f54-aaaa-14f0b7d7d3fc */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('844d7163-57ba-4f54-aaaa-14f0b7d7d3fc', 'AE0A8EB2-3130-4CBF-98FA-CA3C3676795B', 3, 'Any', 'Any', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 7e50f5e5-b5f6-44f9-a071-ff55564d0032 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('7e50f5e5-b5f6-44f9-a071-ff55564d0032', 'AE0A8EB2-3130-4CBF-98FA-CA3C3676795B', 4, 'HasExternal', 'HasExternal', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID c5c5d108-3bce-4841-a467-bd0c03aa418e */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('c5c5d108-3bce-4841-a467-bd0c03aa418e', 'AE0A8EB2-3130-4CBF-98FA-CA3C3676795B', 5, 'HasInternal', 'HasInternal', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID f19c30ef-9e98-4f4a-8e54-2210ab9984ab */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('f19c30ef-9e98-4f4a-8e54-2210ab9984ab', 'AE0A8EB2-3130-4CBF-98FA-CA3C3676795B', 6, 'Mixed', 'Mixed', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID AE0A8EB2-3130-4CBF-98FA-CA3C3676795B */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='AE0A8EB2-3130-4CBF-98FA-CA3C3676795B';


/* Create Entity Relationship: MJ_BizApps_Common: Activities -> MJ_BizApps_Common: Activity Sync Run Details (One To Many via ActivityID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '821a47b0-e690-4474-aed9-1e70bd1702ae'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('821a47b0-e690-4474-aed9-1e70bd1702ae', '72E55425-8822-4E70-A075-116219CA5A5D', 'AC16B066-9460-44F5-B027-3FD397E61F34', 'ActivityID', 'One To Many', 1, 1, 4, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ_BizApps_Common: Activity Sync Exclusions -> MJ_BizApps_Common: Activity Sync Run Details (One To Many via ActivitySyncExclusionID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '1fec4588-519e-42cf-be19-67ca38ee5a70'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('1fec4588-519e-42cf-be19-67ca38ee5a70', '556381BF-9ACE-4A69-85BB-22EAE1856C88', 'AC16B066-9460-44F5-B027-3FD397E61F34', 'ActivitySyncExclusionID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Activity Sync Provider Types -> MJ_BizApps_Common: Activity Sync Rule Sets (One To Many via ActivitySyncProviderTypeID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '886131d1-502e-4c18-9dc1-76adf339f530'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('886131d1-502e-4c18-9dc1-76adf339f530', 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', '7ED9F26E-B01D-472A-87C9-B163287F80B4', 'ActivitySyncProviderTypeID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ_BizApps_Common: Activity Sync Provider Types -> MJ_BizApps_Common: Activity Sync Connections (One To Many via ActivitySyncProviderTypeID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '40ef7fd6-5a93-4888-9ae7-ed5ecfce65a0'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('40ef7fd6-5a93-4888-9ae7-ed5ecfce65a0', 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', 'C22591BB-B33A-439C-9567-5494A7B71D8A', 'ActivitySyncProviderTypeID', 'One To Many', 1, 1, 2, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ_BizApps_Common: Activity Sync Provider Types -> MJ_BizApps_Common: Activity Sync Extensions (One To Many via ActivitySyncProviderTypeID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '37a0cf73-58af-48d4-a14e-39f981f1eb8f'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('37a0cf73-58af-48d4-a14e-39f981f1eb8f', 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', 'ActivitySyncProviderTypeID', 'One To Many', 1, 1, 3, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ_BizApps_Common: Activity Sync Connections -> MJ_BizApps_Common: Activity Sync Extensions (One To Many via ActivitySyncConnectionID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'c635ab08-b8fc-424a-a2af-1e16b38439e9'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('c635ab08-b8fc-424a-a2af-1e16b38439e9', 'C22591BB-B33A-439C-9567-5494A7B71D8A', 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', 'ActivitySyncConnectionID', 'One To Many', 1, 1, 3, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Activity Sync Connections -> MJ_BizApps_Common: Activity Sync Runs (One To Many via ActivitySyncConnectionID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'b719e155-0210-4961-8791-1483fb940527'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('b719e155-0210-4961-8791-1483fb940527', 'C22591BB-B33A-439C-9567-5494A7B71D8A', 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', 'ActivitySyncConnectionID', 'One To Many', 1, 1, 4, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ_BizApps_Common: Activity Sync Connections -> MJ_BizApps_Common: Activity Sync Connection Rule Sets (One To Many via ActivitySyncConnectionID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '88704d93-dc17-4c52-8865-d0d6236b23ed'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('88704d93-dc17-4c52-8865-d0d6236b23ed', 'C22591BB-B33A-439C-9567-5494A7B71D8A', 'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0', 'ActivitySyncConnectionID', 'One To Many', 1, 1, 5, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ: File Storage Providers -> MJ_BizApps_Common: Activity Sync Connections (One To Many via StorageProviderID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '3773ae43-a556-4df7-9d3e-b56dea6756b0'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('3773ae43-a556-4df7-9d3e-b56dea6756b0', '28248F34-2837-EF11-86D4-6045BDEE16E6', 'C22591BB-B33A-439C-9567-5494A7B71D8A', 'StorageProviderID', 'One To Many', 1, 1, 6, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ: File Storage Providers -> MJ_BizApps_Common: Activity Sync Provider Types (One To Many via DefaultStorageProviderID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '1ce6d16a-a447-4d17-a434-9b2e5750fadd'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('1ce6d16a-a447-4d17-a434-9b2e5750fadd', '28248F34-2837-EF11-86D4-6045BDEE16E6', 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', 'DefaultStorageProviderID', 'One To Many', 1, 1, 7, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ: Encryption Keys -> MJ_BizApps_Common: Activity Sync Run Details (One To Many via EncryptionKeyID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '5fb3fdd8-3dcd-4c7c-b865-39bb874defa0'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('5fb3fdd8-3dcd-4c7c-b865-39bb874defa0', '854DB803-34D4-46CD-8B8D-712974AE592F', 'AC16B066-9460-44F5-B027-3FD397E61F34', 'EncryptionKeyID', 'One To Many', 1, 1, 2, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ: Encryption Keys -> MJ_BizApps_Common: Activity Sync Connections (One To Many via EncryptionKeyID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'e7dfa7ca-fd8c-4621-adc7-93bedf3ff0f3'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('e7dfa7ca-fd8c-4621-adc7-93bedf3ff0f3', '854DB803-34D4-46CD-8B8D-712974AE592F', 'C22591BB-B33A-439C-9567-5494A7B71D8A', 'EncryptionKeyID', 'One To Many', 1, 1, 3, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ: Encryption Keys -> MJ_BizApps_Common: Activity Sync Provider Types (One To Many via DefaultEncryptionKeyID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'd3838578-45b5-4f6c-9c12-63b47e8e761e'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('d3838578-45b5-4f6c-9c12-63b47e8e761e', '854DB803-34D4-46CD-8B8D-712974AE592F', 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', 'DefaultEncryptionKeyID', 'One To Many', 1, 1, 4, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Activity Sync Runs -> MJ_BizApps_Common: Activity Sync Run Details (One To Many via ActivitySyncRunID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'd277b718-0a26-4828-b741-d2298ee52f72'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('d277b718-0a26-4828-b741-d2298ee52f72', 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', 'AC16B066-9460-44F5-B027-3FD397E61F34', 'ActivitySyncRunID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Activity Sync Rule Sets -> MJ_BizApps_Common: Activity Sync Connection Rule Sets (One To Many via ActivitySyncRuleSetID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '3099ec33-190e-480b-b5ee-54125e8b3249'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('3099ec33-190e-480b-b5ee-54125e8b3249', '7ED9F26E-B01D-472A-87C9-B163287F80B4', 'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0', 'ActivitySyncRuleSetID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Activity Sync Rule Sets -> MJ_BizApps_Common: Activity Sync Exclusions (One To Many via ActivitySyncRuleSetID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '3ab4bc5f-59ee-47d0-8574-de643ef6bd88'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('3ab4bc5f-59ee-47d0-8574-de643ef6bd88', '7ED9F26E-B01D-472A-87C9-B163287F80B4', '556381BF-9ACE-4A69-85BB-22EAE1856C88', 'ActivitySyncRuleSetID', 'One To Many', 1, 1, 2, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ_BizApps_Common: Activity Sync Rule Sets -> MJ_BizApps_Common: Activity Sync Rules (One To Many via ActivitySyncRuleSetID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '45cbf900-c66f-4edf-b103-c758b411d8b0'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('45cbf900-c66f-4edf-b103-c758b411d8b0', '7ED9F26E-B01D-472A-87C9-B163287F80B4', '21B78371-132C-4507-AED8-D44E366468F2', 'ActivitySyncRuleSetID', 'One To Many', 1, 1, 3, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ_BizApps_Common: Activity Sync Rules -> MJ_BizApps_Common: Activity Sync Run Details (One To Many via ActivitySyncRuleID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'a9714372-a5a1-4477-bb5e-a1f5235c4088'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('a9714372-a5a1-4477-bb5e-a1f5235c4088', '21B78371-132C-4507-AED8-D44E366468F2', 'AC16B066-9460-44F5-B027-3FD397E61F34', 'ActivitySyncRuleID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ_BizApps_Common: People -> MJ_BizApps_Common: Activity Sync Exclusions (One To Many via PersonID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '28baf494-3ee7-4a6f-a388-6cfbc9bc4af2'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('28baf494-3ee7-4a6f-a388-6cfbc9bc4af2', '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', '556381BF-9ACE-4A69-85BB-22EAE1856C88', 'PersonID', 'One To Many', 1, 1, 29, GETUTCDATE(), GETUTCDATE())
   END;

/* SQL text to sync schema info from database schemas */
EXEC [${mjSchema}].[spUpdateSchemaInfoFromDatabase] @ExcludedSchemaNames='', @IncludedSchemaNames='${flyway:defaultSchema}';

/* Index for Foreign Keys for ActivitySyncConnectionRuleSet */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Connection Rule Sets
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key ActivitySyncConnectionID in table ActivitySyncConnectionRuleSet
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncConnectionRuleSet_ActivitySyncConnectionID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncConnectionRuleSet_ActivitySyncConnectionID ON [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet] ([ActivitySyncConnectionID]);

-- Index for foreign key ActivitySyncRuleSetID in table ActivitySyncConnectionRuleSet
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncConnectionRuleSet_ActivitySyncRuleSetID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncConnectionRuleSet_ActivitySyncRuleSetID ON [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet] ([ActivitySyncRuleSetID]);

/* SQL text to update entity field related entity name field map for entity field ID 25052037-85A8-4F55-A64F-A17DE48AE3FB */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='25052037-85A8-4F55-A64F-A17DE48AE3FB', @RelatedEntityNameFieldMap='ActivitySyncConnection';

/* Index for Foreign Keys for ActivitySyncConnection */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Connections
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key OwnerUserID in table ActivitySyncConnection
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncConnection_OwnerUserID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncConnection]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncConnection_OwnerUserID ON [${flyway:defaultSchema}].[ActivitySyncConnection] ([OwnerUserID]);

-- Index for foreign key ActivitySyncProviderTypeID in table ActivitySyncConnection
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncConnection_ActivitySyncProviderTypeID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncConnection]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncConnection_ActivitySyncProviderTypeID ON [${flyway:defaultSchema}].[ActivitySyncConnection] ([ActivitySyncProviderTypeID]);

-- Index for foreign key EncryptionKeyID in table ActivitySyncConnection
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncConnection_EncryptionKeyID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncConnection]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncConnection_EncryptionKeyID ON [${flyway:defaultSchema}].[ActivitySyncConnection] ([EncryptionKeyID]);

-- Index for foreign key StorageProviderID in table ActivitySyncConnection
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncConnection_StorageProviderID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncConnection]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncConnection_StorageProviderID ON [${flyway:defaultSchema}].[ActivitySyncConnection] ([StorageProviderID]);

/* SQL text to update entity field related entity name field map for entity field ID 0EEEFD0A-3809-4BE9-B54E-C7C7EFC8DBD0 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='0EEEFD0A-3809-4BE9-B54E-C7C7EFC8DBD0', @RelatedEntityNameFieldMap='ActivitySyncProviderType';

/* Index for Foreign Keys for ActivitySyncExclusion */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Exclusions
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key ActivitySyncRuleSetID in table ActivitySyncExclusion
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncExclusion_ActivitySyncRuleSetID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncExclusion]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncExclusion_ActivitySyncRuleSetID ON [${flyway:defaultSchema}].[ActivitySyncExclusion] ([ActivitySyncRuleSetID]);

-- Index for foreign key PersonID in table ActivitySyncExclusion
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncExclusion_PersonID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncExclusion]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncExclusion_PersonID ON [${flyway:defaultSchema}].[ActivitySyncExclusion] ([PersonID]);

/* SQL text to update entity field related entity name field map for entity field ID 84D4E65C-C18B-4A52-BD56-1FC459420563 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='84D4E65C-C18B-4A52-BD56-1FC459420563', @RelatedEntityNameFieldMap='ActivitySyncRuleSet';

/* Index for Foreign Keys for ActivitySyncExtension */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Extensions
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key ActivitySyncConnectionID in table ActivitySyncExtension
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncExtension_ActivitySyncConnectionID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncExtension]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncExtension_ActivitySyncConnectionID ON [${flyway:defaultSchema}].[ActivitySyncExtension] ([ActivitySyncConnectionID]);

-- Index for foreign key ActivitySyncProviderTypeID in table ActivitySyncExtension
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncExtension_ActivitySyncProviderTypeID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncExtension]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncExtension_ActivitySyncProviderTypeID ON [${flyway:defaultSchema}].[ActivitySyncExtension] ([ActivitySyncProviderTypeID]);

/* SQL text to update entity field related entity name field map for entity field ID CEFE0EC3-92E4-4890-B36A-3E9CE5F60EE6 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='CEFE0EC3-92E4-4890-B36A-3E9CE5F60EE6', @RelatedEntityNameFieldMap='ActivitySyncConnection';

/* Index for Foreign Keys for ActivitySyncProviderType */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Provider Types
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key DefaultEncryptionKeyID in table ActivitySyncProviderType
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncProviderType_DefaultEncryptionKeyID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncProviderType]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncProviderType_DefaultEncryptionKeyID ON [${flyway:defaultSchema}].[ActivitySyncProviderType] ([DefaultEncryptionKeyID]);

-- Index for foreign key DefaultStorageProviderID in table ActivitySyncProviderType
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncProviderType_DefaultStorageProviderID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncProviderType]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncProviderType_DefaultStorageProviderID ON [${flyway:defaultSchema}].[ActivitySyncProviderType] ([DefaultStorageProviderID]);

/* SQL text to update entity field related entity name field map for entity field ID 5E2EFFE9-2376-454D-8F8C-7E967E27E485 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='5E2EFFE9-2376-454D-8F8C-7E967E27E485', @RelatedEntityNameFieldMap='DefaultEncryptionKey';

/* SQL text to update entity field related entity name field map for entity field ID 6C142921-FEEE-4D50-A601-ADB0B370EE47 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='6C142921-FEEE-4D50-A601-ADB0B370EE47', @RelatedEntityNameFieldMap='ActivitySyncProviderType';

/* SQL text to update entity field related entity name field map for entity field ID 2A5381DD-A180-4E03-9C04-9815703DDEE3 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='2A5381DD-A180-4E03-9C04-9815703DDEE3', @RelatedEntityNameFieldMap='EncryptionKey';

/* SQL text to update entity field related entity name field map for entity field ID D1C50585-1359-49B7-A011-6D590570B9E1 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='D1C50585-1359-49B7-A011-6D590570B9E1', @RelatedEntityNameFieldMap='DefaultStorageProvider';

/* SQL text to update entity field related entity name field map for entity field ID 7BB4C198-CF87-4258-AEB5-99BF1F035BAA */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='7BB4C198-CF87-4258-AEB5-99BF1F035BAA', @RelatedEntityNameFieldMap='ActivitySyncRuleSet';

/* SQL text to update entity field related entity name field map for entity field ID 568087EE-B48D-43B3-9411-28302A37B0C5 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='568087EE-B48D-43B3-9411-28302A37B0C5', @RelatedEntityNameFieldMap='Person';

/* Base View SQL for MJ_BizApps_Common: Activity Sync Connection Rule Sets */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Connection Rule Sets
-- Item: vwActivitySyncConnectionRuleSets
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Activity Sync Connection Rule Sets
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ActivitySyncConnectionRuleSet
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwActivitySyncConnectionRuleSets]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwActivitySyncConnectionRuleSets];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwActivitySyncConnectionRuleSets]
AS
SELECT
    a.*,
    mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID.[Name] AS [ActivitySyncConnection],
    mjBizAppsCommonActivitySyncRuleSet_ActivitySyncRuleSetID.[Name] AS [ActivitySyncRuleSet]
FROM
    [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet] AS a
INNER JOIN
    [${flyway:defaultSchema}].[ActivitySyncConnection] AS mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID
  ON
    [a].[ActivitySyncConnectionID] = mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID.[ID]
INNER JOIN
    [${flyway:defaultSchema}].[ActivitySyncRuleSet] AS mjBizAppsCommonActivitySyncRuleSet_ActivitySyncRuleSetID
  ON
    [a].[ActivitySyncRuleSetID] = mjBizAppsCommonActivitySyncRuleSet_ActivitySyncRuleSetID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncConnectionRuleSets] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Activity Sync Connection Rule Sets */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Connection Rule Sets
-- Item: Permissions for vwActivitySyncConnectionRuleSets
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncConnectionRuleSets] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Activity Sync Connection Rule Sets */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Connection Rule Sets
-- Item: spCreateActivitySyncConnectionRuleSet
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ActivitySyncConnectionRuleSet
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateActivitySyncConnectionRuleSet]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncConnectionRuleSet];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncConnectionRuleSet]
    @ID uniqueidentifier = NULL,
    @ActivitySyncConnectionID uniqueidentifier,
    @ActivitySyncRuleSetID uniqueidentifier,
    @Sequence int = NULL,
    @IsEnabled bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet]
            (
                [ID],
                [ActivitySyncConnectionID],
                [ActivitySyncRuleSetID],
                [Sequence],
                [IsEnabled]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @ActivitySyncConnectionID,
                @ActivitySyncRuleSetID,
                ISNULL(@Sequence, 0),
                ISNULL(@IsEnabled, 1)
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet]
            (
                [ActivitySyncConnectionID],
                [ActivitySyncRuleSetID],
                [Sequence],
                [IsEnabled]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ActivitySyncConnectionID,
                @ActivitySyncRuleSetID,
                ISNULL(@Sequence, 0),
                ISNULL(@IsEnabled, 1)
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwActivitySyncConnectionRuleSets] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncConnectionRuleSet] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Activity Sync Connection Rule Sets */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncConnectionRuleSet] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Activity Sync Connection Rule Sets */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Connection Rule Sets
-- Item: spUpdateActivitySyncConnectionRuleSet
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

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
        [IsEnabled] = ISNULL(@IsEnabled, [IsEnabled])
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
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Activity Sync Connection Rule Sets */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncConnectionRuleSet] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Activity Sync Connection Rule Sets */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Connection Rule Sets
-- Item: spDeleteActivitySyncConnectionRuleSet
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ActivitySyncConnectionRuleSet
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteActivitySyncConnectionRuleSet]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncConnectionRuleSet];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncConnectionRuleSet]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ActivitySyncConnectionRuleSet]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncConnectionRuleSet] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Activity Sync Connection Rule Sets */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncConnectionRuleSet] TO [cdp_Developer], [cdp_Integration];

/* Base View SQL for MJ_BizApps_Common: Activity Sync Provider Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Provider Types
-- Item: vwActivitySyncProviderTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Activity Sync Provider Types
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ActivitySyncProviderType
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwActivitySyncProviderTypes]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwActivitySyncProviderTypes];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwActivitySyncProviderTypes]
AS
SELECT
    a.*,
    MJEncryptionKey_DefaultEncryptionKeyID.[Name] AS [DefaultEncryptionKey],
    MJFileStorageProvider_DefaultStorageProviderID.[Name] AS [DefaultStorageProvider]
FROM
    [${flyway:defaultSchema}].[ActivitySyncProviderType] AS a
LEFT OUTER JOIN
    [${mjSchema}].[EncryptionKey] AS MJEncryptionKey_DefaultEncryptionKeyID
  ON
    [a].[DefaultEncryptionKeyID] = MJEncryptionKey_DefaultEncryptionKeyID.[ID]
LEFT OUTER JOIN
    [${mjSchema}].[FileStorageProvider] AS MJFileStorageProvider_DefaultStorageProviderID
  ON
    [a].[DefaultStorageProviderID] = MJFileStorageProvider_DefaultStorageProviderID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncProviderTypes] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Activity Sync Provider Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Provider Types
-- Item: Permissions for vwActivitySyncProviderTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncProviderTypes] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Activity Sync Provider Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Provider Types
-- Item: spCreateActivitySyncProviderType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ActivitySyncProviderType
------------------------------------------------------------
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
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncProviderType]
            (
                [ID],
                [Code],
                [Name],
                [Description],
                [DriverClass],
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
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncProviderType]
            (
                [Code],
                [Name],
                [Description],
                [DriverClass],
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
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwActivitySyncProviderTypes] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncProviderType] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Activity Sync Provider Types */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncProviderType] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Activity Sync Provider Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Provider Types
-- Item: spUpdateActivitySyncProviderType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

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
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncProviderType]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ActivitySyncProviderType] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Activity Sync Provider Types */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncProviderType] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Activity Sync Provider Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Provider Types
-- Item: spDeleteActivitySyncProviderType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ActivitySyncProviderType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteActivitySyncProviderType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncProviderType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncProviderType]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ActivitySyncProviderType]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncProviderType] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Activity Sync Provider Types */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncProviderType] TO [cdp_Developer], [cdp_Integration];

/* Base View SQL for MJ_BizApps_Common: Activity Sync Exclusions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Exclusions
-- Item: vwActivitySyncExclusions
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Activity Sync Exclusions
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ActivitySyncExclusion
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwActivitySyncExclusions]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwActivitySyncExclusions];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwActivitySyncExclusions]
AS
SELECT
    a.*,
    mjBizAppsCommonActivitySyncRuleSet_ActivitySyncRuleSetID.[Name] AS [ActivitySyncRuleSet],
    mjBizAppsCommonPerson_PersonID.[DisplayName] AS [Person]
FROM
    [${flyway:defaultSchema}].[ActivitySyncExclusion] AS a
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ActivitySyncRuleSet] AS mjBizAppsCommonActivitySyncRuleSet_ActivitySyncRuleSetID
  ON
    [a].[ActivitySyncRuleSetID] = mjBizAppsCommonActivitySyncRuleSet_ActivitySyncRuleSetID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Person] AS mjBizAppsCommonPerson_PersonID
  ON
    [a].[PersonID] = mjBizAppsCommonPerson_PersonID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncExclusions] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Activity Sync Exclusions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Exclusions
-- Item: Permissions for vwActivitySyncExclusions
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncExclusions] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Activity Sync Exclusions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Exclusions
-- Item: spCreateActivitySyncExclusion
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ActivitySyncExclusion
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateActivitySyncExclusion]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncExclusion];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncExclusion]
    @ID uniqueidentifier = NULL,
    @ActivitySyncRuleSetID_Clear bit = 0,
    @ActivitySyncRuleSetID uniqueidentifier = NULL,
    @IdentityKind nvarchar(20),
    @IdentityValue nvarchar(320),
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
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncExclusion]
            (
                [ID],
                [ActivitySyncRuleSetID],
                [IdentityKind],
                [IdentityValue],
                [PersonID],
                [Reason],
                [EffectiveFrom],
                [EffectiveTo],
                [IsEnabled]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                CASE WHEN @ActivitySyncRuleSetID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncRuleSetID, NULL) END,
                @IdentityKind,
                @IdentityValue,
                CASE WHEN @PersonID_Clear = 1 THEN NULL ELSE ISNULL(@PersonID, NULL) END,
                CASE WHEN @Reason_Clear = 1 THEN NULL ELSE ISNULL(@Reason, NULL) END,
                CASE WHEN @EffectiveFrom_Clear = 1 THEN NULL ELSE ISNULL(@EffectiveFrom, NULL) END,
                CASE WHEN @EffectiveTo_Clear = 1 THEN NULL ELSE ISNULL(@EffectiveTo, NULL) END,
                ISNULL(@IsEnabled, 1)
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncExclusion]
            (
                [ActivitySyncRuleSetID],
                [IdentityKind],
                [IdentityValue],
                [PersonID],
                [Reason],
                [EffectiveFrom],
                [EffectiveTo],
                [IsEnabled]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                CASE WHEN @ActivitySyncRuleSetID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncRuleSetID, NULL) END,
                @IdentityKind,
                @IdentityValue,
                CASE WHEN @PersonID_Clear = 1 THEN NULL ELSE ISNULL(@PersonID, NULL) END,
                CASE WHEN @Reason_Clear = 1 THEN NULL ELSE ISNULL(@Reason, NULL) END,
                CASE WHEN @EffectiveFrom_Clear = 1 THEN NULL ELSE ISNULL(@EffectiveFrom, NULL) END,
                CASE WHEN @EffectiveTo_Clear = 1 THEN NULL ELSE ISNULL(@EffectiveTo, NULL) END,
                ISNULL(@IsEnabled, 1)
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwActivitySyncExclusions] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncExclusion] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Activity Sync Exclusions */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncExclusion] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Activity Sync Exclusions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Exclusions
-- Item: spUpdateActivitySyncExclusion
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

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
        [IsEnabled] = ISNULL(@IsEnabled, [IsEnabled])
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
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncExclusion]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ActivitySyncExclusion] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Activity Sync Exclusions */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncExclusion] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Activity Sync Exclusions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Exclusions
-- Item: spDeleteActivitySyncExclusion
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ActivitySyncExclusion
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteActivitySyncExclusion]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncExclusion];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncExclusion]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ActivitySyncExclusion]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncExclusion] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Activity Sync Exclusions */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncExclusion] TO [cdp_Developer], [cdp_Integration];

/* Base View SQL for MJ_BizApps_Common: Activity Sync Extensions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Extensions
-- Item: vwActivitySyncExtensions
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Activity Sync Extensions
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ActivitySyncExtension
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwActivitySyncExtensions]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwActivitySyncExtensions];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwActivitySyncExtensions]
AS
SELECT
    a.*,
    mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID.[Name] AS [ActivitySyncConnection],
    mjBizAppsCommonActivitySyncProviderType_ActivitySyncProviderTypeID.[Name] AS [ActivitySyncProviderType]
FROM
    [${flyway:defaultSchema}].[ActivitySyncExtension] AS a
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ActivitySyncConnection] AS mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID
  ON
    [a].[ActivitySyncConnectionID] = mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ActivitySyncProviderType] AS mjBizAppsCommonActivitySyncProviderType_ActivitySyncProviderTypeID
  ON
    [a].[ActivitySyncProviderTypeID] = mjBizAppsCommonActivitySyncProviderType_ActivitySyncProviderTypeID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncExtensions] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Activity Sync Extensions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Extensions
-- Item: Permissions for vwActivitySyncExtensions
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncExtensions] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Activity Sync Extensions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Extensions
-- Item: spCreateActivitySyncExtension
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ActivitySyncExtension
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateActivitySyncExtension]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncExtension];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncExtension]
    @ID uniqueidentifier = NULL,
    @Name nvarchar(200),
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @DriverClass nvarchar(200),
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
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncExtension]
            (
                [ID],
                [Name],
                [Description],
                [DriverClass],
                [ActivitySyncConnectionID],
                [ActivitySyncProviderTypeID],
                [Sequence],
                [FailurePolicy],
                [TimeoutMS],
                [IsEnabled],
                [LastRunAt],
                [LastError]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                @DriverClass,
                CASE WHEN @ActivitySyncConnectionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncConnectionID, NULL) END,
                CASE WHEN @ActivitySyncProviderTypeID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncProviderTypeID, NULL) END,
                ISNULL(@Sequence, 0),
                ISNULL(@FailurePolicy, 'Skip'),
                ISNULL(@TimeoutMS, 5000),
                ISNULL(@IsEnabled, 1),
                CASE WHEN @LastRunAt_Clear = 1 THEN NULL ELSE ISNULL(@LastRunAt, NULL) END,
                CASE WHEN @LastError_Clear = 1 THEN NULL ELSE ISNULL(@LastError, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncExtension]
            (
                [Name],
                [Description],
                [DriverClass],
                [ActivitySyncConnectionID],
                [ActivitySyncProviderTypeID],
                [Sequence],
                [FailurePolicy],
                [TimeoutMS],
                [IsEnabled],
                [LastRunAt],
                [LastError]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                @DriverClass,
                CASE WHEN @ActivitySyncConnectionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncConnectionID, NULL) END,
                CASE WHEN @ActivitySyncProviderTypeID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncProviderTypeID, NULL) END,
                ISNULL(@Sequence, 0),
                ISNULL(@FailurePolicy, 'Skip'),
                ISNULL(@TimeoutMS, 5000),
                ISNULL(@IsEnabled, 1),
                CASE WHEN @LastRunAt_Clear = 1 THEN NULL ELSE ISNULL(@LastRunAt, NULL) END,
                CASE WHEN @LastError_Clear = 1 THEN NULL ELSE ISNULL(@LastError, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwActivitySyncExtensions] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncExtension] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Activity Sync Extensions */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncExtension] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Activity Sync Extensions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Extensions
-- Item: spUpdateActivitySyncExtension
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

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
        [LastError] = CASE WHEN @LastError_Clear = 1 THEN NULL ELSE ISNULL(@LastError, [LastError]) END
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
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncExtension]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ActivitySyncExtension] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Activity Sync Extensions */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncExtension] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Activity Sync Extensions */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Extensions
-- Item: spDeleteActivitySyncExtension
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ActivitySyncExtension
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteActivitySyncExtension]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncExtension];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncExtension]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ActivitySyncExtension]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncExtension] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Activity Sync Extensions */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncExtension] TO [cdp_Developer], [cdp_Integration];

/* SQL text to update entity field related entity name field map for entity field ID 136FF7B4-BC67-4C96-98B2-9FD82C21363B */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='136FF7B4-BC67-4C96-98B2-9FD82C21363B', @RelatedEntityNameFieldMap='StorageProvider';

/* Base View SQL for MJ_BizApps_Common: Activity Sync Connections */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Connections
-- Item: vwActivitySyncConnections
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Activity Sync Connections
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ActivitySyncConnection
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwActivitySyncConnections]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwActivitySyncConnections];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwActivitySyncConnections]
AS
SELECT
    a.*,
    MJUser_OwnerUserID.[Name] AS [OwnerUser],
    mjBizAppsCommonActivitySyncProviderType_ActivitySyncProviderTypeID.[Name] AS [ActivitySyncProviderType],
    MJEncryptionKey_EncryptionKeyID.[Name] AS [EncryptionKey],
    MJFileStorageProvider_StorageProviderID.[Name] AS [StorageProvider]
FROM
    [${flyway:defaultSchema}].[ActivitySyncConnection] AS a
INNER JOIN
    [${mjSchema}].[User] AS MJUser_OwnerUserID
  ON
    [a].[OwnerUserID] = MJUser_OwnerUserID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ActivitySyncProviderType] AS mjBizAppsCommonActivitySyncProviderType_ActivitySyncProviderTypeID
  ON
    [a].[ActivitySyncProviderTypeID] = mjBizAppsCommonActivitySyncProviderType_ActivitySyncProviderTypeID.[ID]
LEFT OUTER JOIN
    [${mjSchema}].[EncryptionKey] AS MJEncryptionKey_EncryptionKeyID
  ON
    [a].[EncryptionKeyID] = MJEncryptionKey_EncryptionKeyID.[ID]
LEFT OUTER JOIN
    [${mjSchema}].[FileStorageProvider] AS MJFileStorageProvider_StorageProviderID
  ON
    [a].[StorageProviderID] = MJFileStorageProvider_StorageProviderID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncConnections] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Activity Sync Connections */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Connections
-- Item: Permissions for vwActivitySyncConnections
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncConnections] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Activity Sync Connections */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Connections
-- Item: spCreateActivitySyncConnection
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ActivitySyncConnection
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateActivitySyncConnection]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncConnection];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncConnection]
    @ID uniqueidentifier = NULL,
    @Name nvarchar(200),
    @Provider_Clear bit = 0,
    @Provider nvarchar(40) = NULL,
    @Status nvarchar(20) = NULL,
    @Direction nvarchar(20) = NULL,
    @OwnerUserID uniqueidentifier,
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
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncConnection]
            (
                [ID],
                [Name],
                [Provider],
                [Status],
                [Direction],
                [OwnerUserID],
                [CredentialsRef],
                [Mailbox],
                [LastSyncAt],
                [LastError],
                [Settings],
                [ActivitySyncProviderTypeID],
                [StartAt],
                [EndAt],
                [SkippedContentPolicy],
                [EncryptionKeyID],
                [StorageProviderID],
                [MaxAttachmentBytes]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Name,
                CASE WHEN @Provider_Clear = 1 THEN NULL ELSE ISNULL(@Provider, NULL) END,
                ISNULL(@Status, 'Active'),
                ISNULL(@Direction, 'Inbound'),
                @OwnerUserID,
                CASE WHEN @CredentialsRef_Clear = 1 THEN NULL ELSE ISNULL(@CredentialsRef, NULL) END,
                CASE WHEN @Mailbox_Clear = 1 THEN NULL ELSE ISNULL(@Mailbox, NULL) END,
                CASE WHEN @LastSyncAt_Clear = 1 THEN NULL ELSE ISNULL(@LastSyncAt, NULL) END,
                CASE WHEN @LastError_Clear = 1 THEN NULL ELSE ISNULL(@LastError, NULL) END,
                CASE WHEN @Settings_Clear = 1 THEN NULL ELSE ISNULL(@Settings, NULL) END,
                CASE WHEN @ActivitySyncProviderTypeID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncProviderTypeID, NULL) END,
                CASE WHEN @StartAt_Clear = 1 THEN NULL ELSE ISNULL(@StartAt, NULL) END,
                CASE WHEN @EndAt_Clear = 1 THEN NULL ELSE ISNULL(@EndAt, NULL) END,
                CASE WHEN @SkippedContentPolicy_Clear = 1 THEN NULL ELSE ISNULL(@SkippedContentPolicy, NULL) END,
                CASE WHEN @EncryptionKeyID_Clear = 1 THEN NULL ELSE ISNULL(@EncryptionKeyID, NULL) END,
                CASE WHEN @StorageProviderID_Clear = 1 THEN NULL ELSE ISNULL(@StorageProviderID, NULL) END,
                CASE WHEN @MaxAttachmentBytes_Clear = 1 THEN NULL ELSE ISNULL(@MaxAttachmentBytes, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncConnection]
            (
                [Name],
                [Provider],
                [Status],
                [Direction],
                [OwnerUserID],
                [CredentialsRef],
                [Mailbox],
                [LastSyncAt],
                [LastError],
                [Settings],
                [ActivitySyncProviderTypeID],
                [StartAt],
                [EndAt],
                [SkippedContentPolicy],
                [EncryptionKeyID],
                [StorageProviderID],
                [MaxAttachmentBytes]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                CASE WHEN @Provider_Clear = 1 THEN NULL ELSE ISNULL(@Provider, NULL) END,
                ISNULL(@Status, 'Active'),
                ISNULL(@Direction, 'Inbound'),
                @OwnerUserID,
                CASE WHEN @CredentialsRef_Clear = 1 THEN NULL ELSE ISNULL(@CredentialsRef, NULL) END,
                CASE WHEN @Mailbox_Clear = 1 THEN NULL ELSE ISNULL(@Mailbox, NULL) END,
                CASE WHEN @LastSyncAt_Clear = 1 THEN NULL ELSE ISNULL(@LastSyncAt, NULL) END,
                CASE WHEN @LastError_Clear = 1 THEN NULL ELSE ISNULL(@LastError, NULL) END,
                CASE WHEN @Settings_Clear = 1 THEN NULL ELSE ISNULL(@Settings, NULL) END,
                CASE WHEN @ActivitySyncProviderTypeID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncProviderTypeID, NULL) END,
                CASE WHEN @StartAt_Clear = 1 THEN NULL ELSE ISNULL(@StartAt, NULL) END,
                CASE WHEN @EndAt_Clear = 1 THEN NULL ELSE ISNULL(@EndAt, NULL) END,
                CASE WHEN @SkippedContentPolicy_Clear = 1 THEN NULL ELSE ISNULL(@SkippedContentPolicy, NULL) END,
                CASE WHEN @EncryptionKeyID_Clear = 1 THEN NULL ELSE ISNULL(@EncryptionKeyID, NULL) END,
                CASE WHEN @StorageProviderID_Clear = 1 THEN NULL ELSE ISNULL(@StorageProviderID, NULL) END,
                CASE WHEN @MaxAttachmentBytes_Clear = 1 THEN NULL ELSE ISNULL(@MaxAttachmentBytes, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwActivitySyncConnections] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncConnection] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Activity Sync Connections */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncConnection] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Activity Sync Connections */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Connections
-- Item: spUpdateActivitySyncConnection
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

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
        [MaxAttachmentBytes] = CASE WHEN @MaxAttachmentBytes_Clear = 1 THEN NULL ELSE ISNULL(@MaxAttachmentBytes, [MaxAttachmentBytes]) END
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
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncConnection]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ActivitySyncConnection] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Activity Sync Connections */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncConnection] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Activity Sync Connections */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Connections
-- Item: spDeleteActivitySyncConnection
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ActivitySyncConnection
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteActivitySyncConnection]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncConnection];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncConnection]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ActivitySyncConnection]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncConnection] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Activity Sync Connections */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncConnection] TO [cdp_Developer], [cdp_Integration];

/* Index for Foreign Keys for ActivitySyncRuleSet */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Rule Sets
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key ActivitySyncProviderTypeID in table ActivitySyncRuleSet
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncRuleSet_ActivitySyncProviderTypeID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncRuleSet]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncRuleSet_ActivitySyncProviderTypeID ON [${flyway:defaultSchema}].[ActivitySyncRuleSet] ([ActivitySyncProviderTypeID]);

/* SQL text to update entity field related entity name field map for entity field ID 1CB40317-E514-4BB1-86BF-C8B2B18AE84C */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='1CB40317-E514-4BB1-86BF-C8B2B18AE84C', @RelatedEntityNameFieldMap='ActivitySyncProviderType';

/* Index for Foreign Keys for ActivitySyncRule */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Rules
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key ActivitySyncConnectionID in table ActivitySyncRule
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncRule_ActivitySyncConnectionID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncRule]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncRule_ActivitySyncConnectionID ON [${flyway:defaultSchema}].[ActivitySyncRule] ([ActivitySyncConnectionID]);

-- Index for foreign key ActivityTypeID in table ActivitySyncRule
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncRule_ActivityTypeID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncRule]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncRule_ActivityTypeID ON [${flyway:defaultSchema}].[ActivitySyncRule] ([ActivityTypeID]);

-- Index for foreign key ActivitySyncRuleSetID in table ActivitySyncRule
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncRule_ActivitySyncRuleSetID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncRule]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncRule_ActivitySyncRuleSetID ON [${flyway:defaultSchema}].[ActivitySyncRule] ([ActivitySyncRuleSetID]);

/* SQL text to update entity field related entity name field map for entity field ID 3B472ADE-9440-46FC-AB87-9CB4B27FE729 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='3B472ADE-9440-46FC-AB87-9CB4B27FE729', @RelatedEntityNameFieldMap='ActivitySyncRuleSet';

/* Index for Foreign Keys for ActivitySyncRunDetail */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Run Details
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key ActivitySyncRunID in table ActivitySyncRunDetail
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_ActivitySyncRunID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncRunDetail]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_ActivitySyncRunID ON [${flyway:defaultSchema}].[ActivitySyncRunDetail] ([ActivitySyncRunID]);

-- Index for foreign key ActivitySyncRuleID in table ActivitySyncRunDetail
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_ActivitySyncRuleID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncRunDetail]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_ActivitySyncRuleID ON [${flyway:defaultSchema}].[ActivitySyncRunDetail] ([ActivitySyncRuleID]);

-- Index for foreign key ActivitySyncExclusionID in table ActivitySyncRunDetail
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_ActivitySyncExclusionID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncRunDetail]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_ActivitySyncExclusionID ON [${flyway:defaultSchema}].[ActivitySyncRunDetail] ([ActivitySyncExclusionID]);

-- Index for foreign key ActivityID in table ActivitySyncRunDetail
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_ActivityID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncRunDetail]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_ActivityID ON [${flyway:defaultSchema}].[ActivitySyncRunDetail] ([ActivityID]);

-- Index for foreign key EncryptionKeyID in table ActivitySyncRunDetail
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_EncryptionKeyID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncRunDetail]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncRunDetail_EncryptionKeyID ON [${flyway:defaultSchema}].[ActivitySyncRunDetail] ([EncryptionKeyID]);

/* SQL text to update entity field related entity name field map for entity field ID F9D3B360-0DA7-4FB7-AC4F-8CA065AA9BF3 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='F9D3B360-0DA7-4FB7-AC4F-8CA065AA9BF3', @RelatedEntityNameFieldMap='ActivitySyncRule';

/* Index for Foreign Keys for ActivitySyncRun */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Runs
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key ActivitySyncConnectionID in table ActivitySyncRun
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncRun_ActivitySyncConnectionID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncRun]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncRun_ActivitySyncConnectionID ON [${flyway:defaultSchema}].[ActivitySyncRun] ([ActivitySyncConnectionID]);

/* SQL text to update entity field related entity name field map for entity field ID 721EDD40-B7F9-4227-BDE7-F276389364F0 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='721EDD40-B7F9-4227-BDE7-F276389364F0', @RelatedEntityNameFieldMap='ActivitySyncConnection';

/* SQL text to update entity field related entity name field map for entity field ID 4087A170-CD32-4B2A-A59E-E2747F272AA8 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='4087A170-CD32-4B2A-A59E-E2747F272AA8', @RelatedEntityNameFieldMap='Activity';

/* Base View SQL for MJ_BizApps_Common: Activity Sync Rules */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Rules
-- Item: vwActivitySyncRules
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Activity Sync Rules
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ActivitySyncRule
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwActivitySyncRules]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwActivitySyncRules];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwActivitySyncRules]
AS
SELECT
    a.*,
    mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID.[Name] AS [ActivitySyncConnection],
    mjBizAppsCommonActivityType_ActivityTypeID.[Name] AS [ActivityType],
    mjBizAppsCommonActivitySyncRuleSet_ActivitySyncRuleSetID.[Name] AS [ActivitySyncRuleSet]
FROM
    [${flyway:defaultSchema}].[ActivitySyncRule] AS a
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ActivitySyncConnection] AS mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID
  ON
    [a].[ActivitySyncConnectionID] = mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ActivityType] AS mjBizAppsCommonActivityType_ActivityTypeID
  ON
    [a].[ActivityTypeID] = mjBizAppsCommonActivityType_ActivityTypeID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ActivitySyncRuleSet] AS mjBizAppsCommonActivitySyncRuleSet_ActivitySyncRuleSetID
  ON
    [a].[ActivitySyncRuleSetID] = mjBizAppsCommonActivitySyncRuleSet_ActivitySyncRuleSetID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncRules] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Activity Sync Rules */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Rules
-- Item: Permissions for vwActivitySyncRules
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncRules] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Activity Sync Rules */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Rules
-- Item: spCreateActivitySyncRule
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ActivitySyncRule
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateActivitySyncRule]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncRule];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncRule]
    @ID uniqueidentifier = NULL,
    @ActivitySyncConnectionID_Clear bit = 0,
    @ActivitySyncConnectionID uniqueidentifier = NULL,
    @Name nvarchar(200),
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
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncRule]
            (
                [ID],
                [ActivitySyncConnectionID],
                [Name],
                [IsEnabled],
                [Sequence],
                [Action],
                [ActivityTypeID],
                [Direction],
                [DateFrom],
                [DateTo],
                [IncludeAttachments],
                [Filter],
                [ActivitySyncRuleSetID],
                [ParticipantScope],
                [MaxAttachmentBytes]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                CASE WHEN @ActivitySyncConnectionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncConnectionID, NULL) END,
                @Name,
                ISNULL(@IsEnabled, 1),
                ISNULL(@Sequence, 0),
                ISNULL(@Action, 'Include'),
                CASE WHEN @ActivityTypeID_Clear = 1 THEN NULL ELSE ISNULL(@ActivityTypeID, NULL) END,
                CASE WHEN @Direction_Clear = 1 THEN NULL ELSE ISNULL(@Direction, NULL) END,
                CASE WHEN @DateFrom_Clear = 1 THEN NULL ELSE ISNULL(@DateFrom, NULL) END,
                CASE WHEN @DateTo_Clear = 1 THEN NULL ELSE ISNULL(@DateTo, NULL) END,
                ISNULL(@IncludeAttachments, 0),
                CASE WHEN @Filter_Clear = 1 THEN NULL ELSE ISNULL(@Filter, NULL) END,
                CASE WHEN @ActivitySyncRuleSetID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncRuleSetID, NULL) END,
                CASE WHEN @ParticipantScope_Clear = 1 THEN NULL ELSE ISNULL(@ParticipantScope, NULL) END,
                CASE WHEN @MaxAttachmentBytes_Clear = 1 THEN NULL ELSE ISNULL(@MaxAttachmentBytes, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncRule]
            (
                [ActivitySyncConnectionID],
                [Name],
                [IsEnabled],
                [Sequence],
                [Action],
                [ActivityTypeID],
                [Direction],
                [DateFrom],
                [DateTo],
                [IncludeAttachments],
                [Filter],
                [ActivitySyncRuleSetID],
                [ParticipantScope],
                [MaxAttachmentBytes]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                CASE WHEN @ActivitySyncConnectionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncConnectionID, NULL) END,
                @Name,
                ISNULL(@IsEnabled, 1),
                ISNULL(@Sequence, 0),
                ISNULL(@Action, 'Include'),
                CASE WHEN @ActivityTypeID_Clear = 1 THEN NULL ELSE ISNULL(@ActivityTypeID, NULL) END,
                CASE WHEN @Direction_Clear = 1 THEN NULL ELSE ISNULL(@Direction, NULL) END,
                CASE WHEN @DateFrom_Clear = 1 THEN NULL ELSE ISNULL(@DateFrom, NULL) END,
                CASE WHEN @DateTo_Clear = 1 THEN NULL ELSE ISNULL(@DateTo, NULL) END,
                ISNULL(@IncludeAttachments, 0),
                CASE WHEN @Filter_Clear = 1 THEN NULL ELSE ISNULL(@Filter, NULL) END,
                CASE WHEN @ActivitySyncRuleSetID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncRuleSetID, NULL) END,
                CASE WHEN @ParticipantScope_Clear = 1 THEN NULL ELSE ISNULL(@ParticipantScope, NULL) END,
                CASE WHEN @MaxAttachmentBytes_Clear = 1 THEN NULL ELSE ISNULL(@MaxAttachmentBytes, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwActivitySyncRules] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRule] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Activity Sync Rules */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRule] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Activity Sync Rules */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Rules
-- Item: spUpdateActivitySyncRule
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

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
        [MaxAttachmentBytes] = CASE WHEN @MaxAttachmentBytes_Clear = 1 THEN NULL ELSE ISNULL(@MaxAttachmentBytes, [MaxAttachmentBytes]) END
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
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncRule]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ActivitySyncRule] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Activity Sync Rules */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRule] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Activity Sync Rules */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Rules
-- Item: spDeleteActivitySyncRule
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ActivitySyncRule
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteActivitySyncRule]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncRule];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncRule]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ActivitySyncRule]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncRule] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Activity Sync Rules */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncRule] TO [cdp_Developer], [cdp_Integration];

/* Base View SQL for MJ_BizApps_Common: Activity Sync Rule Sets */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Rule Sets
-- Item: vwActivitySyncRuleSets
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Activity Sync Rule Sets
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ActivitySyncRuleSet
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwActivitySyncRuleSets]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwActivitySyncRuleSets];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwActivitySyncRuleSets]
AS
SELECT
    a.*,
    mjBizAppsCommonActivitySyncProviderType_ActivitySyncProviderTypeID.[Name] AS [ActivitySyncProviderType]
FROM
    [${flyway:defaultSchema}].[ActivitySyncRuleSet] AS a
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ActivitySyncProviderType] AS mjBizAppsCommonActivitySyncProviderType_ActivitySyncProviderTypeID
  ON
    [a].[ActivitySyncProviderTypeID] = mjBizAppsCommonActivitySyncProviderType_ActivitySyncProviderTypeID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncRuleSets] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Activity Sync Rule Sets */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Rule Sets
-- Item: Permissions for vwActivitySyncRuleSets
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncRuleSets] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Activity Sync Rule Sets */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Rule Sets
-- Item: spCreateActivitySyncRuleSet
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ActivitySyncRuleSet
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateActivitySyncRuleSet]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncRuleSet];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncRuleSet]
    @ID uniqueidentifier = NULL,
    @Name nvarchar(200),
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
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncRuleSet]
            (
                [ID],
                [Name],
                [Description],
                [ActivitySyncProviderTypeID],
                [InternalDomains],
                [Sequence],
                [IsEnabled],
                [IsSystem]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                CASE WHEN @ActivitySyncProviderTypeID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncProviderTypeID, NULL) END,
                CASE WHEN @InternalDomains_Clear = 1 THEN NULL ELSE ISNULL(@InternalDomains, NULL) END,
                ISNULL(@Sequence, 0),
                ISNULL(@IsEnabled, 1),
                ISNULL(@IsSystem, 0)
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncRuleSet]
            (
                [Name],
                [Description],
                [ActivitySyncProviderTypeID],
                [InternalDomains],
                [Sequence],
                [IsEnabled],
                [IsSystem]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                CASE WHEN @ActivitySyncProviderTypeID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncProviderTypeID, NULL) END,
                CASE WHEN @InternalDomains_Clear = 1 THEN NULL ELSE ISNULL(@InternalDomains, NULL) END,
                ISNULL(@Sequence, 0),
                ISNULL(@IsEnabled, 1),
                ISNULL(@IsSystem, 0)
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwActivitySyncRuleSets] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRuleSet] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Activity Sync Rule Sets */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRuleSet] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Activity Sync Rule Sets */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Rule Sets
-- Item: spUpdateActivitySyncRuleSet
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

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
        [IsSystem] = ISNULL(@IsSystem, [IsSystem])
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
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncRuleSet]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ActivitySyncRuleSet] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Activity Sync Rule Sets */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRuleSet] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Activity Sync Rule Sets */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Rule Sets
-- Item: spDeleteActivitySyncRuleSet
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ActivitySyncRuleSet
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteActivitySyncRuleSet]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncRuleSet];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncRuleSet]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ActivitySyncRuleSet]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncRuleSet] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Activity Sync Rule Sets */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncRuleSet] TO [cdp_Developer], [cdp_Integration];

/* SQL text to update entity field related entity name field map for entity field ID 1E55257F-D2BE-4817-82C9-723AEE6F8E42 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='1E55257F-D2BE-4817-82C9-723AEE6F8E42', @RelatedEntityNameFieldMap='EncryptionKey';

/* Base View SQL for MJ_BizApps_Common: Activity Sync Runs */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Runs
-- Item: vwActivitySyncRuns
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Activity Sync Runs
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ActivitySyncRun
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwActivitySyncRuns]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwActivitySyncRuns];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwActivitySyncRuns]
AS
SELECT
    a.*,
    mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID.[Name] AS [ActivitySyncConnection]
FROM
    [${flyway:defaultSchema}].[ActivitySyncRun] AS a
INNER JOIN
    [${flyway:defaultSchema}].[ActivitySyncConnection] AS mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID
  ON
    [a].[ActivitySyncConnectionID] = mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncRuns] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Activity Sync Runs */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Runs
-- Item: Permissions for vwActivitySyncRuns
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncRuns] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

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
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRun] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Activity Sync Runs */

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

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRun] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Activity Sync Runs */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Runs
-- Item: spDeleteActivitySyncRun
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ActivitySyncRun
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteActivitySyncRun]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncRun];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncRun]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ActivitySyncRun]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncRun] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Activity Sync Runs */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncRun] TO [cdp_Developer], [cdp_Integration];

/* Base View SQL for MJ_BizApps_Common: Activity Sync Run Details */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Run Details
-- Item: vwActivitySyncRunDetails
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Activity Sync Run Details
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ActivitySyncRunDetail
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwActivitySyncRunDetails]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwActivitySyncRunDetails];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwActivitySyncRunDetails]
AS
SELECT
    a.*,
    mjBizAppsCommonActivitySyncRule_ActivitySyncRuleID.[Name] AS [ActivitySyncRule],
    mjBizAppsCommonActivity_ActivityID.[Title] AS [Activity],
    MJEncryptionKey_EncryptionKeyID.[Name] AS [EncryptionKey]
FROM
    [${flyway:defaultSchema}].[ActivitySyncRunDetail] AS a
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ActivitySyncRule] AS mjBizAppsCommonActivitySyncRule_ActivitySyncRuleID
  ON
    [a].[ActivitySyncRuleID] = mjBizAppsCommonActivitySyncRule_ActivitySyncRuleID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Activity] AS mjBizAppsCommonActivity_ActivityID
  ON
    [a].[ActivityID] = mjBizAppsCommonActivity_ActivityID.[ID]
LEFT OUTER JOIN
    [${mjSchema}].[EncryptionKey] AS MJEncryptionKey_EncryptionKeyID
  ON
    [a].[EncryptionKeyID] = MJEncryptionKey_EncryptionKeyID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncRunDetails] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Activity Sync Run Details */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Run Details
-- Item: Permissions for vwActivitySyncRunDetails
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncRunDetails] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

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
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRunDetail] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Activity Sync Run Details */

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

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRunDetail] TO [cdp_Developer], [cdp_Integration]
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

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRunDetail] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Activity Sync Run Details */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Run Details
-- Item: spDeleteActivitySyncRunDetail
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ActivitySyncRunDetail
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteActivitySyncRunDetail]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncRunDetail];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncRunDetail]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ActivitySyncRunDetail]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncRunDetail] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Activity Sync Run Details */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncRunDetail] TO [cdp_Developer], [cdp_Integration];

/* SQL text to delete unneeded entity fields (7 scoped entities) */
EXEC [${mjSchema}].[spDeleteUnneededEntityFields] @ExcludedSchemaNames='', @EntityIDs='AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75,7ED9F26E-B01D-472A-87C9-B163287F80B4,D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0,556381BF-9ACE-4A69-85BB-22EAE1856C88,ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1,AC16B066-9460-44F5-B027-3FD397E61F34,C7E5ECE1-F347-4BC9-AC53-E2F33577B449', @IncludedSchemaNames='${flyway:defaultSchema}';

/* SQL text to insert 26 new entity field(s) */
UPDATE [${mjSchema}].[EntityField]
         SET [Sequence] = [Sequence] + 100000
       WHERE [EntityID] = 'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0'
         AND [Sequence] < 100000;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '6321804a-a19f-44d7-828b-5d6f68b2a633' OR (EntityID = 'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0' AND Name = 'ActivitySyncConnection')) BEGIN
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
            '6321804a-a19f-44d7-828b-5d6f68b2a633',
            'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0', -- Entity: MJ_BizApps_Common: Activity Sync Connection Rule Sets
            8,
            'ActivitySyncConnection',
            'Activity Sync Connection',
            NULL,
            'nvarchar',
            400,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '36a25924-2dbb-4082-9c26-ed805b9bddce' OR (EntityID = 'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0' AND Name = 'ActivitySyncRuleSet')) BEGIN
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
            '36a25924-2dbb-4082-9c26-ed805b9bddce',
            'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0', -- Entity: MJ_BizApps_Common: Activity Sync Connection Rule Sets
            9,
            'ActivitySyncRuleSet',
            'Activity Sync Rule Set',
            NULL,
            'nvarchar',
            400,
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
UPDATE [${mjSchema}].[EntityField]
         SET [Sequence] = [Sequence] + 100000
       WHERE [EntityID] = '556381BF-9ACE-4A69-85BB-22EAE1856C88'
         AND [Sequence] < 100000;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '1e3b2d01-0bb3-4546-901a-b314226dea2a' OR (EntityID = '556381BF-9ACE-4A69-85BB-22EAE1856C88' AND Name = 'ActivitySyncRuleSet')) BEGIN
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
            '1e3b2d01-0bb3-4546-901a-b314226dea2a',
            '556381BF-9ACE-4A69-85BB-22EAE1856C88', -- Entity: MJ_BizApps_Common: Activity Sync Exclusions
            12,
            'ActivitySyncRuleSet',
            'Activity Sync Rule Set',
            NULL,
            'nvarchar',
            400,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'b61dd372-ede6-4b46-80fc-bcd0bce3714f' OR (EntityID = '556381BF-9ACE-4A69-85BB-22EAE1856C88' AND Name = 'Person')) BEGIN
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
            'b61dd372-ede6-4b46-80fc-bcd0bce3714f',
            '556381BF-9ACE-4A69-85BB-22EAE1856C88', -- Entity: MJ_BizApps_Common: Activity Sync Exclusions
            13,
            'Person',
            'Person',
            NULL,
            'nvarchar',
            402,
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
UPDATE [${mjSchema}].[EntityField]
         SET [Sequence] = [Sequence] + 100000
       WHERE [EntityID] = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75'
         AND [Sequence] < 100000;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'ae2c135e-282f-485c-947b-396cc6e36548' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = 'DefaultEncryptionKey')) BEGIN
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
            'ae2c135e-282f-485c-947b-396cc6e36548',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            18,
            'DefaultEncryptionKey',
            'Default Encryption Key',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '51369d06-bcee-4156-93bb-e8c09bf0d7f1' OR (EntityID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75' AND Name = 'DefaultStorageProvider')) BEGIN
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
            '51369d06-bcee-4156-93bb-e8c09bf0d7f1',
            'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', -- Entity: MJ_BizApps_Common: Activity Sync Provider Types
            19,
            'DefaultStorageProvider',
            'Default Storage Provider',
            NULL,
            'nvarchar',
            100,
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
UPDATE [${mjSchema}].[EntityField]
         SET [Sequence] = [Sequence] + 100000
       WHERE [EntityID] = 'AC16B066-9460-44F5-B027-3FD397E61F34'
         AND [Sequence] < 100000;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '33f6dc61-4a5b-4367-87d9-4b50fd89f1f3' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'ActivitySyncRule')) BEGIN
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
            '33f6dc61-4a5b-4367-87d9-4b50fd89f1f3',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            18,
            'ActivitySyncRule',
            'Activity Sync Rule',
            NULL,
            'nvarchar',
            400,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '5bf4cf4b-b9e3-4237-8d0c-eea4df89cad4' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'Activity')) BEGIN
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
            '5bf4cf4b-b9e3-4237-8d0c-eea4df89cad4',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            19,
            'Activity',
            'Activity',
            NULL,
            'nvarchar',
            1000,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '49c089a3-71f3-46a2-8182-e3a351b60a8c' OR (EntityID = 'AC16B066-9460-44F5-B027-3FD397E61F34' AND Name = 'EncryptionKey')) BEGIN
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
            '49c089a3-71f3-46a2-8182-e3a351b60a8c',
            'AC16B066-9460-44F5-B027-3FD397E61F34', -- Entity: MJ_BizApps_Common: Activity Sync Run Details
            20,
            'EncryptionKey',
            'Encryption Key',
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
-- Do not re-bump ActivitySyncConnection sequences: the first field pass
-- already moved pre-existing rows to 100000+ and inserted new physical
-- columns at 14–20. A second +100000 collides (UQ_EntityField_EntityID_Sequence).
      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '8b8e6e5a-015d-4f82-8b01-36d0e20e6072' OR (EntityID = 'C22591BB-B33A-439C-9567-5494A7B71D8A' AND Name = 'ActivitySyncProviderType')) BEGIN
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
            '8b8e6e5a-015d-4f82-8b01-36d0e20e6072',
            'C22591BB-B33A-439C-9567-5494A7B71D8A', -- Entity: MJ_BizApps_Common: Activity Sync Connections
            22,
            'ActivitySyncProviderType',
            'Activity Sync Provider Type',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'd7b744c6-6756-4f40-b9ae-32debe51322b' OR (EntityID = 'C22591BB-B33A-439C-9567-5494A7B71D8A' AND Name = 'EncryptionKey')) BEGIN
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
            'd7b744c6-6756-4f40-b9ae-32debe51322b',
            'C22591BB-B33A-439C-9567-5494A7B71D8A', -- Entity: MJ_BizApps_Common: Activity Sync Connections
            23,
            'EncryptionKey',
            'Encryption Key',
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'df8219d5-e2b4-4460-97bd-25e6efc8002b' OR (EntityID = 'C22591BB-B33A-439C-9567-5494A7B71D8A' AND Name = 'StorageProvider')) BEGIN
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
            'df8219d5-e2b4-4460-97bd-25e6efc8002b',
            'C22591BB-B33A-439C-9567-5494A7B71D8A', -- Entity: MJ_BizApps_Common: Activity Sync Connections
            24,
            'StorageProvider',
            'Storage Provider',
            NULL,
            'nvarchar',
            100,
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
UPDATE [${mjSchema}].[EntityField]
         SET [Sequence] = [Sequence] + 100000
       WHERE [EntityID] = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1'
         AND [Sequence] < 100000;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c270fa0d-d8ca-4a7e-9441-fa3bcdc7eaaf' OR (EntityID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1' AND Name = 'ActivitySyncConnection')) BEGIN
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
            'c270fa0d-d8ca-4a7e-9441-fa3bcdc7eaaf',
            'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', -- Entity: MJ_BizApps_Common: Activity Sync Runs
            19,
            'ActivitySyncConnection',
            'Activity Sync Connection',
            NULL,
            'nvarchar',
            400,
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
UPDATE [${mjSchema}].[EntityField]
         SET [Sequence] = [Sequence] + 100000
       WHERE [EntityID] = '7ED9F26E-B01D-472A-87C9-B163287F80B4'
         AND [Sequence] < 100000;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'dd283888-a644-4070-ac78-fc167b2d0a7c' OR (EntityID = '7ED9F26E-B01D-472A-87C9-B163287F80B4' AND Name = 'ActivitySyncProviderType')) BEGIN
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
            'dd283888-a644-4070-ac78-fc167b2d0a7c',
            '7ED9F26E-B01D-472A-87C9-B163287F80B4', -- Entity: MJ_BizApps_Common: Activity Sync Rule Sets
            11,
            'ActivitySyncProviderType',
            'Activity Sync Provider Type',
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
-- Same as Connections: ActivitySyncRule already shipped; do not re-bump.
      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '29a07a5e-2f5a-40de-87cf-6c89368ab7d7' OR (EntityID = '21B78371-132C-4507-AED8-D44E366468F2' AND Name = 'ActivitySyncRuleSet')) BEGIN
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
            '29a07a5e-2f5a-40de-87cf-6c89368ab7d7',
            '21B78371-132C-4507-AED8-D44E366468F2', -- Entity: MJ_BizApps_Common: Activity Sync Rules
            20,
            'ActivitySyncRuleSet',
            'Activity Sync Rule Set',
            NULL,
            'nvarchar',
            400,
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
UPDATE [${mjSchema}].[EntityField]
         SET [Sequence] = [Sequence] + 100000
       WHERE [EntityID] = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449'
         AND [Sequence] < 100000;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '24fc40b3-8cd9-4c23-9202-87b0b63b3b15' OR (EntityID = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449' AND Name = 'ActivitySyncConnection')) BEGIN
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
            '24fc40b3-8cd9-4c23-9202-87b0b63b3b15',
            'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', -- Entity: MJ_BizApps_Common: Activity Sync Extensions
            15,
            'ActivitySyncConnection',
            'Activity Sync Connection',
            NULL,
            'nvarchar',
            400,
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

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'b90d18ef-6655-47ba-a664-0a9ac97cd44f' OR (EntityID = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449' AND Name = 'ActivitySyncProviderType')) BEGIN
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
            'b90d18ef-6655-47ba-a664-0a9ac97cd44f',
            'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', -- Entity: MJ_BizApps_Common: Activity Sync Extensions
            16,
            'ActivitySyncProviderType',
            'Activity Sync Provider Type',
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

/* SQL text to update existing entity fields from schema (7 scoped entities) */
EXEC [${mjSchema}].[spUpdateExistingEntityFieldsFromSchema] @ExcludedSchemaNames='', @EntityIDs='AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75,7ED9F26E-B01D-472A-87C9-B163287F80B4,D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0,556381BF-9ACE-4A69-85BB-22EAE1856C88,ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1,AC16B066-9460-44F5-B027-3FD397E61F34,C7E5ECE1-F347-4BC9-AC53-E2F33577B449', @IncludedSchemaNames='${flyway:defaultSchema}';

/* SQL text to set default column width where needed */
EXEC [${mjSchema}].[spSetDefaultColumnWidthWhereNeeded] @ExcludedSchemaNames='', @IncludedSchemaNames='${flyway:defaultSchema}';

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'D75C9FD1-F6A9-450A-B405-AFF4728750D6'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '7790EA43-823F-4FA3-963D-A1110D614029'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'FD76A168-2AF9-462D-B284-549AB7CCED6F'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '70FF0FE5-2A34-430F-85E4-10A5A38F83CA'
               AND AutoUpdateDefaultInView = 1;

            UPDATE [${mjSchema}].[Entity]
            SET AllowUserSearchAPI = 0
            WHERE ID = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449'
            AND AutoUpdateAllowUserSearchAPI = 1;

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'C66A81AA-25FF-461B-8C8D-F8E99382F5A0'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '1F569493-170C-42FB-BD80-821BEB6C75ED'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '57D01C0F-01DA-4B55-A748-CA4B445062E1'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'D799893A-F650-4F86-A1EA-3B8BBA7CABFC'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET IncludeInUserSearchAPI = 1
               WHERE ID = '57D01C0F-01DA-4B55-A748-CA4B445062E1'
               AND AutoUpdateIncludeInUserSearchAPI = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET UserSearchPredicateAPI = 'BeginsWith'
               WHERE ID = 'D06C399C-6939-4BC0-950C-93E4899405AC'
               AND AutoUpdateUserSearchPredicate = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET UserSearchPredicateAPI = 'Exact'
               WHERE ID = '57D01C0F-01DA-4B55-A748-CA4B445062E1'
               AND AutoUpdateUserSearchPredicate = 1;

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '47CCF48D-B837-44E0-9475-FF1B42076F34'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '7F25D600-B7D0-4548-816C-FA78FFE59044'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '6321804A-A19F-44D7-828B-5D6F68B2A633'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '36A25924-2DBB-4082-9C26-ED805B9BDDCE'
               AND AutoUpdateDefaultInView = 1;

            UPDATE [${mjSchema}].[Entity]
            SET AllowUserSearchAPI = 0
            WHERE ID = 'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0'
            AND AutoUpdateAllowUserSearchAPI = 1;

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET IsNameField = 1
               WHERE ID = '7A54676F-41BD-466B-9BB6-26425B32F8B0'
               AND AutoUpdateIsNameField = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'AD5A0FB1-1144-408A-A0E8-3F300BC786AC'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '7A54676F-41BD-466B-9BB6-26425B32F8B0'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '9560BACE-04EE-4B7E-826B-A5E64E8513E1'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'B741ADE2-F250-40D7-B0D2-61D28B331F3E'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '1E3B2D01-0BB3-4546-901A-B314226DEA2A'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET IncludeInUserSearchAPI = 1
               WHERE ID = '7A54676F-41BD-466B-9BB6-26425B32F8B0'
               AND AutoUpdateIncludeInUserSearchAPI = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET UserSearchPredicateAPI = 'Exact'
               WHERE ID = '7A54676F-41BD-466B-9BB6-26425B32F8B0'
               AND AutoUpdateUserSearchPredicate = 1;

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '52553D7E-79DA-4DFD-9CC3-5F551E411DE5'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'F609014D-E4D4-41A9-B26C-A12871CC782C'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'D6351250-3C56-41CB-A5C1-003DF4812FC3'
               AND AutoUpdateDefaultInView = 1;

            UPDATE [${mjSchema}].[Entity]
            SET AllowUserSearchAPI = 0
            WHERE ID = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75'
            AND AutoUpdateAllowUserSearchAPI = 1;

/* Set categories for 9 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connection Rule Sets.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '210D070A-BC54-43E3-83AA-999B27982E16' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connection Rule Sets.ActivitySyncConnectionID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Connection Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Activity Sync Connection',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '25052037-85A8-4F55-A64F-A17DE48AE3FB' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connection Rule Sets.ActivitySyncConnection 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Connection Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Connection Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '6321804A-A19F-44D7-828B-5D6F68B2A633' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connection Rule Sets.ActivitySyncRuleSetID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Rule Set Configuration',
   GeneratedFormSection = 'Category',
   DisplayName = 'Activity Sync Rule Set',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7BB4C198-CF87-4258-AEB5-99BF1F035BAA' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connection Rule Sets.ActivitySyncRuleSet 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Rule Set Configuration',
   GeneratedFormSection = 'Category',
   DisplayName = 'Rule Set Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '36A25924-2DBB-4082-9C26-ED805B9BDDCE' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connection Rule Sets.Sequence 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Rule Set Configuration',
   GeneratedFormSection = 'Category',
   DisplayName = 'Evaluation Sequence',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '47CCF48D-B837-44E0-9475-FF1B42076F34' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connection Rule Sets.IsEnabled 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Rule Set Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7F25D600-B7D0-4548-816C-FA78FFE59044' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connection Rule Sets.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '813E93A7-D167-45F0-87F5-C05F70947B92' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connection Rule Sets.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '70644C38-265D-492E-A219-B17262D3736C' AND AutoUpdateCategory = 1;

/* Set entity icon to fa fa-link */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-link', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = 'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0';

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('29010232-ab5d-46d3-a4f8-5a066ece67fd', 'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0', 'FieldCategoryInfo', '{"Connection Details":{"icon":"fa fa-plug","description":"Information regarding the activity sync connection being bound"},"Rule Set Configuration":{"icon":"fa fa-cogs","description":"Rules and evaluation settings for the connection binding"},"System Metadata":{"icon":"fa fa-database","description":"System-managed audit and tracking fields"}}', GETUTCDATE(), GETUTCDATE());

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('44fffe78-ae2d-4699-a875-d1b0cd3cb46a', 'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0', 'FieldCategoryIcons', '{"Connection Details":"fa fa-plug","Rule Set Configuration":"fa fa-cogs","System Metadata":"fa fa-database"}', GETUTCDATE(), GETUTCDATE());

/* Set DefaultForNewUser=false for NEW entity (category: junction, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = 'D2A4DA75-FCCD-4196-B6EB-0C15B28C95B0';

/* Set categories for 13 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Exclusions.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '1FB477C2-553D-479C-907F-AF425F214ADC' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Exclusions.ActivitySyncRuleSetID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Exclusion Rules',
   GeneratedFormSection = 'Category',
   DisplayName = 'Activity Sync Rule Set',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '84D4E65C-C18B-4A52-BD56-1FC459420563' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Exclusions.ActivitySyncRuleSet 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Exclusion Rules',
   GeneratedFormSection = 'Category',
   DisplayName = 'Rule Set Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '1E3B2D01-0BB3-4546-901A-B314226DEA2A' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Exclusions.IdentityKind 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Identity Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'AD5A0FB1-1144-408A-A0E8-3F300BC786AC' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Exclusions.IdentityValue 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Identity Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7A54676F-41BD-466B-9BB6-26425B32F8B0' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Exclusions.PersonID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Identity Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Person',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '568087EE-B48D-43B3-9411-28302A37B0C5' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Exclusions.Person 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Identity Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Person Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B61DD372-EDE6-4B46-80FC-BCD0BCE3714F' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Exclusions.Reason 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Exclusion Policy',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '9560BACE-04EE-4B7E-826B-A5E64E8513E1' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Exclusions.IsEnabled 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Exclusion Policy',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B741ADE2-F250-40D7-B0D2-61D28B331F3E' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Exclusions.EffectiveFrom 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Exclusion Policy',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8F9E007E-B597-44E8-AB81-7BB7D2ACA504' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Exclusions.EffectiveTo 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Exclusion Policy',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '85B42461-D8DB-4D00-AD4E-9B9CC42EAF3E' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Exclusions.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'A572F4C8-52E8-49EC-A42D-DE68C3C730B5' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Exclusions.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '64004F94-0E95-4424-91E9-86AA9CD5D167' AND AutoUpdateCategory = 1;

/* Set entity icon to fa fa-user-slash */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-user-slash', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = '556381BF-9ACE-4A69-85BB-22EAE1856C88';

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('f315fcec-d3dd-4f56-bb97-ecb3aed311c7', '556381BF-9ACE-4A69-85BB-22EAE1856C88', 'FieldCategoryInfo', '{"Exclusion Rules":{"icon":"fa fa-cogs","description":"Configuration settings for linking exclusions to specific rule sets"},"Identity Details":{"icon":"fa fa-user-tag","description":"Details regarding the specific identity (email, phone, etc.) being excluded"},"Exclusion Policy":{"icon":"fa fa-shield-alt","description":"Policy settings including reasons, active status, and effective date ranges"},"System Metadata":{"icon":"fa fa-database","description":"System-managed audit and tracking fields"}}', GETUTCDATE(), GETUTCDATE());

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('bfb2b2d9-c7fe-4ef3-b236-050c3678d25a', '556381BF-9ACE-4A69-85BB-22EAE1856C88', 'FieldCategoryIcons', '{"Exclusion Rules":"fa fa-cogs","Identity Details":"fa fa-user-tag","Exclusion Policy":"fa fa-shield-alt","System Metadata":"fa fa-database"}', GETUTCDATE(), GETUTCDATE());

/* Set DefaultForNewUser=false for NEW entity (category: supporting, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = '556381BF-9ACE-4A69-85BB-22EAE1856C88';

/* Set categories for 16 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Extensions.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8FF6284E-9816-42DA-939C-B353B11DAFEB' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Extensions.Name 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Plugin Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E6722A67-7051-46F8-8C6F-B3475B4F6B69' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Extensions.Description 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Plugin Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '2665D26D-E5D2-42EB-ACD0-6DAB290D3B9E' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Extensions.DriverClass 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Plugin Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D75C9FD1-F6A9-450A-B405-AFF4728750D6' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Extensions.ActivitySyncConnectionID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Integration Settings',
   GeneratedFormSection = 'Category',
   DisplayName = 'Activity Sync Connection',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'CEFE0EC3-92E4-4890-B36A-3E9CE5F60EE6' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Extensions.ActivitySyncProviderTypeID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Integration Settings',
   GeneratedFormSection = 'Category',
   DisplayName = 'Activity Sync Provider Type',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '6C142921-FEEE-4D50-A601-ADB0B370EE47' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Extensions.Sequence 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Execution Logic',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7790EA43-823F-4FA3-963D-A1110D614029' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Extensions.FailurePolicy 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Execution Logic',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'FD76A168-2AF9-462D-B284-549AB7CCED6F' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Extensions.TimeoutMS 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Execution Logic',
   GeneratedFormSection = 'Category',
   DisplayName = 'Timeout (ms)',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'A12A8C4C-DBD9-40FB-97B4-3872AA966FC3' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Extensions.IsEnabled 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Plugin Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '70FF0FE5-2A34-430F-85E4-10A5A38F83CA' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Extensions.LastRunAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Performance and Health',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B0ACF26A-484C-4A19-899B-B6995030EAD7' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Extensions.LastError 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Performance and Health',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '840551BD-057B-44CB-9651-D8CDA50F7F06' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Extensions.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'EE946000-7849-412F-AE49-71D092D7C389' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Extensions.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'FBF026FB-33E9-4A3E-AC40-63062A60D26B' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Extensions.ActivitySyncConnection 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Integration Settings',
   GeneratedFormSection = 'Category',
   DisplayName = 'Activity Sync Connection (Name)',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '24FC40B3-8CD9-4C23-9202-87B0B63B3B15' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Extensions.ActivitySyncProviderType 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Integration Settings',
   GeneratedFormSection = 'Category',
   DisplayName = 'Activity Sync Provider Type (Name)',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B90D18EF-6655-47BA-A664-0A9AC97CD44F' AND AutoUpdateCategory = 1;

/* Set entity icon to fa fa-plug */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-plug', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449';

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('50dba497-8296-4df5-bdfe-f6f14eebd831', 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', 'FieldCategoryInfo', '{"Plugin Configuration":{"icon":"fa fa-cog","description":"General settings and identification for the enrichment plugin."},"Integration Settings":{"icon":"fa fa-link","description":"Configuration for external sync connections and provider types."},"Execution Logic":{"icon":"fa fa-terminal","description":"Operational parameters defining how the plugin executes."},"Performance and Health":{"icon":"fa fa-heartbeat","description":"Monitoring and audit logs for plugin performance."},"System Metadata":{"icon":"fa fa-database","description":"System-managed audit and tracking fields."}}', GETUTCDATE(), GETUTCDATE());

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('4901cf1b-47f6-4164-8d4e-9dda29c67931', 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449', 'FieldCategoryIcons', '{"Plugin Configuration":"fa fa-cog","Integration Settings":"fa fa-link","Execution Logic":"fa fa-terminal","Performance and Health":"fa fa-heartbeat","System Metadata":"fa fa-database"}', GETUTCDATE(), GETUTCDATE());

/* Set DefaultForNewUser=false for NEW entity (category: supporting, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = 'C7E5ECE1-F347-4BC9-AC53-E2F33577B449';

/* Set categories for 19 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '57A720BD-8CB1-4429-95DD-150C529FF1DD' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.Code 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Provider Identification',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '52553D7E-79DA-4DFD-9CC3-5F551E411DE5' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.Name 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Provider Identification',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E3A328E8-5B81-48D7-9021-21EF3E67E3C2' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.Description 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Provider Identification',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B4BA9BC4-5776-424B-B009-5EBB50CA712F' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.DriverClass 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Provider Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B89E3F6E-BEDB-4CE4-82F8-29C1FF23B809' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.IconClass 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Provider Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '43042F34-0DD3-4789-BD19-F3AE56CC733C' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.SupportedKinds 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Provider Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '2C86F25A-3816-4EC0-8885-06E4399313E0' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.DefaultQualificationPolicy 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Operational Defaults',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '2B27DE14-383F-4D07-9DCF-050237CEC7C7' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.DefaultSkippedContentPolicy 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Operational Defaults',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '10FDAF3A-2042-41F1-B148-BEFFC8FCB001' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.DefaultEncryptionKeyID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Operational Defaults',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '5E2EFFE9-2376-454D-8F8C-7E967E27E485' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.DefaultEncryptionKey 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Operational Defaults',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'AE2C135E-282F-485C-947B-396CC6E36548' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.DefaultStorageProviderID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Operational Defaults',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D1C50585-1359-49B7-A011-6D590570B9E1' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.DefaultStorageProvider 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Operational Defaults',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '51369D06-BCEE-4156-93BB-E8C09BF0D7F1' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.DefaultMaxAttachmentBytes 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Operational Defaults',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '827D6B7C-BA37-446C-A9C1-912320C1AFF3' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.Sequence 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Provider Identification',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8F863005-AA6E-40A3-8EDE-5601E45281E0' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.IsSystem 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Provider Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'F609014D-E4D4-41A9-B26C-A12871CC782C' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.IsActive 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Provider Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D6351250-3C56-41CB-A5C1-003DF4812FC3' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '5E0546DD-7EA6-48ED-81DF-3B9BFAE705CD' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Provider Types.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'FFCD695A-8745-44BA-AF76-B532F8BD5DB5' AND AutoUpdateCategory = 1;

/* Set entity icon to fa fa-sync-alt */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-sync-alt', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75';

/* Set categories for 24 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7652BFF2-EDE4-4E6D-9789-C3DF01D6D909' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.Name 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Connection Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D06C399C-6939-4BC0-950C-93E4899405AC' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.Provider 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Connection Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'F73D370A-4708-4E90-AF7F-6194848DF918' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.ActivitySyncProviderTypeID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Connection Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Provider Type',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '0EEEFD0A-3809-4BE9-B54E-C7C7EFC8DBD0' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.ActivitySyncProviderType 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Connection Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Provider Type Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8B8E6E5A-015D-4F82-8B01-36D0E20E6072' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.Status 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Operational Status',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C66A81AA-25FF-461B-8C8D-F8E99382F5A0' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.Direction 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Operational Status',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '1F569493-170C-42FB-BD80-821BEB6C75ED' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.LastSyncAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Operational Status',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D799893A-F650-4F86-A1EA-3B8BBA7CABFC' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.LastError 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Operational Status',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '6F07727C-D449-4B90-B81C-AE0D8E3944A9' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.StartAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Activation Window',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '55161592-6265-4026-A501-72A6EB5A0E14' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.EndAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Activation Window',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '068BEE66-56DA-445D-946E-514B1F3410C0' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.OwnerUserID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Access and Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C875E212-006C-44F9-9A31-D19F78D5146B' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.OwnerUser 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Access and Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E4E58DF3-BDAB-4D12-9346-4EED2DDF053A' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.CredentialsRef 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Access and Configuration',
   GeneratedFormSection = 'Category',
   DisplayName = 'Credentials Reference',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'F3BBB1A4-F50D-40EF-9FAA-F0FD13E6FC97' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.Mailbox 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Access and Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Email',
   CodeType = NULL
WHERE 
   ID = '57D01C0F-01DA-4B55-A748-CA4B445062E1' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.Settings 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Access and Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Code',
   CodeType = 'Other'
WHERE 
   ID = '3213A7A7-6404-4F89-9752-55874E53D6FD' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.SkippedContentPolicy 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Access and Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '1E88DA7C-C64B-4D7A-B218-804A9AEEA2FA' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.EncryptionKeyID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Security and Storage',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '2A5381DD-A180-4E03-9C04-9815703DDEE3' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.EncryptionKey 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Security and Storage',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D7B744C6-6756-4F40-B9AE-32DEBE51322B' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.StorageProviderID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Security and Storage',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '136FF7B4-BC67-4C96-98B2-9FD82C21363B' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.StorageProvider 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Security and Storage',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'DF8219D5-E2B4-4460-97BD-25E6EFC8002B' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.MaxAttachmentBytes 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Security and Storage',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'A8E6FDD3-F038-42CB-A9DA-D92C5105EC34' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7D785FBB-268A-4AC6-811D-A6C2F70CD300' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Connections.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '1D637687-5D39-403F-90B5-E063CDFED790' AND AutoUpdateCategory = 1;

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('a4c9df05-9063-4dde-9c87-2aa502b3eb32', 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', 'FieldCategoryInfo', '{"Provider Identification":{"icon":"fa fa-id-badge","description":"Basic identification and display settings for the sync provider."},"Provider Configuration":{"icon":"fa fa-sliders-h","description":"Technical implementation settings and operational flags for the provider."},"Operational Defaults":{"icon":"fa fa-cogs","description":"Default policies and settings applied to mailboxes using this provider."},"System Metadata":{"icon":"fa fa-database","description":"Internal system tracking and audit information."}}', GETUTCDATE(), GETUTCDATE());

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('3a661e91-07bc-4f28-bb8b-b86e49a6a343', 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75', 'FieldCategoryIcons', '{"Provider Identification":"fa fa-id-badge","Provider Configuration":"fa fa-sliders-h","Operational Defaults":"fa fa-cogs","System Metadata":"fa fa-database"}', GETUTCDATE(), GETUTCDATE());

/* Set DefaultForNewUser=false for NEW entity (category: reference, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = 'AD8B1485-8BE1-4E5C-8EFB-3B4FEA363F75';

/* Set entity icon to fa fa-sync-alt */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-sync-alt', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = 'C22591BB-B33A-439C-9567-5494A7B71D8A';

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('8a8266c4-a771-40e6-9abd-8a5880d7d906', 'C22591BB-B33A-439C-9567-5494A7B71D8A', 'FieldCategoryInfo', '{"Connection Details":{"icon":"fa fa-plug","description":"Provider and identity information for the sync connection"},"Operational Status":{"icon":"fa fa-tachometer-alt","description":"Current health, sync direction, and error tracking information"},"Activation Window":{"icon":"fa fa-calendar-alt","description":"Scheduled time range for when the connection is active"},"Access and Configuration":{"icon":"fa fa-sliders-h","description":"Ownership, authentication references, and provider-specific configurations"},"Security and Storage":{"icon":"fa fa-shield-alt","description":"Encryption and storage provider settings for data at rest"},"System Metadata":{"icon":"fa fa-database","description":"System-managed audit and tracking fields"}}', GETUTCDATE(), GETUTCDATE());

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('fa6cf77f-f9c5-42ac-badd-214627d2791d', 'C22591BB-B33A-439C-9567-5494A7B71D8A', 'FieldCategoryIcons', '{"Connection Details":"fa fa-plug","Operational Status":"fa fa-tachometer-alt","Activation Window":"fa fa-calendar-alt","Access and Configuration":"fa fa-sliders-h","Security and Storage":"fa fa-shield-alt","System Metadata":"fa fa-database"}', GETUTCDATE(), GETUTCDATE());

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '23D4F371-F534-4FF6-880D-D3B7A9EB5032'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'BA933D11-CE9F-4F78-863F-8C73443DF808'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '1B3E1546-1CE5-417F-BF91-E64D591079ED'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'D29A08EF-C6C7-4AAC-8239-D3DB29A2D011'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'FBBBE636-EE2A-4B4C-92A4-17E9B872495E'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '674B8800-2821-494E-A291-6C1F3AD8764E'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'C270FA0D-D8CA-4A7E-9441-FA3BCDC7EAAF'
               AND AutoUpdateDefaultInView = 1;

            UPDATE [${mjSchema}].[Entity]
            SET AllowUserSearchAPI = 0
            WHERE ID = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1'
            AND AutoUpdateAllowUserSearchAPI = 1;

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '082DF2CA-E47E-4FF3-969A-A6B8D090A39A'
               AND AutoUpdateDefaultInView = 1;

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '7BAFEA34-D767-4B1B-8D6F-C304BC765CA5'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '9FC296EF-BD9D-417D-B75B-BCC67A253534'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'DD283888-A644-4070-AC78-FC167B2D0A7C'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET UserSearchPredicateAPI = 'BeginsWith'
               WHERE ID = '7B94C459-6D4F-45F6-85A8-C6F436D83B1C'
               AND AutoUpdateUserSearchPredicate = 1;

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET IsNameField = 1
               WHERE ID = '36D13A87-C5B8-472A-9CDA-EB3731AFCC41'
               AND AutoUpdateIsNameField = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '36D13A87-C5B8-472A-9CDA-EB3731AFCC41'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '7E700ED9-C6E6-487C-9304-AA7BB9FC222B'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '0078772B-133B-45CD-B584-0D96CBF51A88'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'F31CBD79-1083-435A-9D00-39A89F03B524'
               AND AutoUpdateDefaultInView = 1;

            UPDATE [${mjSchema}].[Entity]
            SET AllowUserSearchAPI = 0
            WHERE ID = 'AC16B066-9460-44F5-B027-3FD397E61F34'
            AND AutoUpdateAllowUserSearchAPI = 1;

/* Set categories for 11 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rule Sets.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '5F781A56-A58E-4F5E-9FB6-9E602BC31892' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rule Sets.Name 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Rule Set Information',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7B94C459-6D4F-45F6-85A8-C6F436D83B1C' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rule Sets.Description 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Rule Set Information',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E56C30DD-BEFC-4A2F-8447-314D1A1578E5' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rule Sets.ActivitySyncProviderTypeID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Rule Set Information',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '1CB40317-E514-4BB1-86BF-C8B2B18AE84C' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rule Sets.ActivitySyncProviderType 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Rule Set Information',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'DD283888-A644-4070-AC78-FC167B2D0A7C' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rule Sets.InternalDomains 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Code',
   CodeType = 'Other'
WHERE 
   ID = '990E8112-4F9B-439E-8A0D-8472B630C5F9' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rule Sets.Sequence 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7BAFEA34-D767-4B1B-8D6F-C304BC765CA5' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rule Sets.IsEnabled 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '9FC296EF-BD9D-417D-B75B-BCC67A253534' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rule Sets.IsSystem 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Configuration',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'A239DA06-157E-477E-905D-D306159CC1F3' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rule Sets.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '4FD3836B-CEA9-43C3-B81E-3B0F3A5C0C21' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rule Sets.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '5515D121-D16F-4AEA-A77A-6E094274DDEE' AND AutoUpdateCategory = 1;

/* Set entity icon to fa fa-sync-alt */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-sync-alt', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = '7ED9F26E-B01D-472A-87C9-B163287F80B4';

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('510e1bf1-03d3-4b56-8d16-173f400a425f', '7ED9F26E-B01D-472A-87C9-B163287F80B4', 'FieldCategoryInfo', '{"Rule Set Information":{"icon":"fa fa-info-circle","description":"General identification and provider details for the activity sync rule set"},"Configuration":{"icon":"fa fa-sliders-h","description":"Operational settings, sequence, and domain scoping for rule execution"},"System Metadata":{"icon":"fa fa-cog","description":"System-managed audit and tracking fields"}}', GETUTCDATE(), GETUTCDATE());

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('acb42ec4-7b6a-4936-a8bd-7880a0e2c0f7', '7ED9F26E-B01D-472A-87C9-B163287F80B4', 'FieldCategoryIcons', '{"Rule Set Information":"fa fa-info-circle","Configuration":"fa fa-sliders-h","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE());

/* Set DefaultForNewUser=false for NEW entity (category: supporting, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = '7ED9F26E-B01D-472A-87C9-B163287F80B4';

/* Set categories for 20 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E1B36B74-715B-4E9D-9258-614FF7101FFE' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '552E9653-CD6D-4AE2-9ECE-97D1F826A059' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'A29D4B01-5A2B-466B-84BD-BFF484743805' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.ActivitySyncConnectionID 
UPDATE [${mjSchema}].[EntityField]
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '59023ECB-98AD-4950-B328-C1384AA89E32' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.ActivitySyncConnection 
UPDATE [${mjSchema}].[EntityField]
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8673C6DF-0291-480E-9A7E-1D3A05F1BD99' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.ActivitySyncRuleSetID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Configuration',
   GeneratedFormSection = 'Category',
   DisplayName = 'Sync Rule Set',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '3B472ADE-9440-46FC-AB87-9CB4B27FE729' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.ActivitySyncRuleSet 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Configuration',
   GeneratedFormSection = 'Category',
   DisplayName = 'Sync Rule Set Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '29A07A5E-2F5A-40DE-87CF-6C89368AB7D7' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.Name 
UPDATE [${mjSchema}].[EntityField]
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'F1702A65-5058-4203-81FD-7BCA32FA800D' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.IsEnabled 
UPDATE [${mjSchema}].[EntityField]
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E13550D7-7D7E-41D0-A80D-3A19801854B2' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.Sequence 
UPDATE [${mjSchema}].[EntityField]
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'AF9411C8-092E-4CE2-9154-5233819CA56D' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.Action 
UPDATE [${mjSchema}].[EntityField]
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D4794101-7846-413E-8858-6EB0C756206F' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.ActivityTypeID 
UPDATE [${mjSchema}].[EntityField]
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '551E82A3-0C8C-42A1-82FE-C0194883E318' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.ActivityType 
UPDATE [${mjSchema}].[EntityField]
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D70B6EE4-51D2-40F5-A8FA-7ECD8F1E6477' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.Direction 
UPDATE [${mjSchema}].[EntityField]
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '082DF2CA-E47E-4FF3-969A-A6B8D090A39A' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.IncludeAttachments 
UPDATE [${mjSchema}].[EntityField]
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '1B5E756E-B7B5-43C8-BCC9-D4219331D68A' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.MaxAttachmentBytes 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Criteria',
   GeneratedFormSection = 'Category',
   DisplayName = 'Max Attachment Size (Bytes)',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'DCA96B15-B3EE-4F41-BBD1-146C71922BA8' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.ParticipantScope 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Criteria',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'AE0A8EB2-3130-4CBF-98FA-CA3C3676795B' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.DateFrom 
UPDATE [${mjSchema}].[EntityField]
SET 
   GeneratedFormSection = 'Category',
   DisplayName = 'Sync From',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '4A9BD72C-C439-457D-8F76-B655F8C7CBF6' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.DateTo 
UPDATE [${mjSchema}].[EntityField]
SET 
   GeneratedFormSection = 'Category',
   DisplayName = 'Sync To',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '09A7CD6F-F752-4B2A-A91F-09FC926E4CC3' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.Filter 
UPDATE [${mjSchema}].[EntityField]
SET 
   GeneratedFormSection = 'Category',
   DisplayName = 'Filter Rules',
   ExtendedType = 'Code',
   CodeType = 'Other'
WHERE 
   ID = 'AF4D4277-FA14-4AB6-84BD-A232458C9783' AND AutoUpdateCategory = 1;

/* Set categories for 19 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'AB8BB2DC-FDE4-400D-BC2F-A2E77BD22D57' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.ActivitySyncConnectionID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Configuration',
   GeneratedFormSection = 'Category',
   DisplayName = 'Connection ID',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '721EDD40-B7F9-4227-BDE7-F276389364F0' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.ActivitySyncConnection 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Configuration',
   GeneratedFormSection = 'Category',
   DisplayName = 'Connection Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C270FA0D-D8CA-4A7E-9441-FA3BCDC7EAAF' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.StartedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Execution Timeline',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '23D4F371-F534-4FF6-880D-D3B7A9EB5032' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.EndedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Execution Timeline',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '3B1E4E05-435B-4F9D-8288-C1961123B8EC' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.Status 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Execution Status',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'BA933D11-CE9F-4F78-863F-8C73443DF808' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.TriggerType 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Execution Status',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '1B3E1546-1CE5-417F-BF91-E64D591079ED' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.IsDryRun 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Execution Status',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D29A08EF-C6C7-4AAC-8239-D3DB29A2D011' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.ErrorMessage 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Execution Status',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '22813953-A45F-4A63-97B9-440330021AD4' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.Fetched 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Metrics',
   GeneratedFormSection = 'Category',
   DisplayName = 'Fetched Count',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'FBBBE636-EE2A-4B4C-92A4-17E9B872495E' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.Included 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Metrics',
   GeneratedFormSection = 'Category',
   DisplayName = 'Included Count',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '666AADEB-9B84-4B06-B89C-6B46EBA5C9A8' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.Excluded 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Metrics',
   GeneratedFormSection = 'Category',
   DisplayName = 'Excluded Count',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '930F7630-5819-4B43-A54F-B2DE76900EA0' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.Duplicates 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Metrics',
   GeneratedFormSection = 'Category',
   DisplayName = 'Duplicate Count',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '77461D70-12AB-4F6A-97B8-253140D4EFBD' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.Failed 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Metrics',
   GeneratedFormSection = 'Category',
   DisplayName = 'Failed Count',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '674B8800-2821-494E-A291-6C1F3AD8764E' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.ExtensionErrors 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Metrics',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '18D52C2D-5D4E-4C33-840F-FFFC866A3EE5' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.WatermarkBefore 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Watermark',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C886D78B-82D5-4D3C-8A05-94F8DB060525' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.WatermarkAfter 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Watermark',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '0221E342-6338-48CF-A821-12F7ED4AF644' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7FB56DB3-4235-473E-8034-34FDE9F8458E' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Runs.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8474A9BE-CA44-4467-816A-65D885E0E44E' AND AutoUpdateCategory = 1;

/* Set entity icon to fa fa-sync */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-sync', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1';

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('7d5b856f-6fc1-4bde-a455-df131ea59e0b', 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', 'FieldCategoryInfo', '{"Sync Configuration":{"icon":"fa fa-plug","description":"Details regarding the connection being synchronized"},"Execution Timeline":{"icon":"fa fa-clock","description":"Start and end times for the synchronization process"},"Execution Status":{"icon":"fa fa-check-circle","description":"Information about the state, triggers, and outcome of the sync"},"Sync Metrics":{"icon":"fa fa-chart-line","description":"Quantitative results of the sync including counts of processed records"},"Sync Watermark":{"icon":"fa fa-bookmark","description":"Tracking of synchronization progress markers"},"System Metadata":{"icon":"fa fa-cog","description":"System-managed audit and tracking fields"}}', GETUTCDATE(), GETUTCDATE());

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('e1cf78cd-c655-4c3d-b43d-cf85c0b7f485', 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1', 'FieldCategoryIcons', '{"Sync Configuration":"fa fa-plug","Execution Timeline":"fa fa-clock","Execution Status":"fa fa-check-circle","Sync Metrics":"fa fa-chart-line","Sync Watermark":"fa fa-bookmark","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE());

/* Set DefaultForNewUser=false for NEW entity (category: supporting, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = 'ECF19741-CBA6-4DB7-95A3-85FA37BEC2F1';

/* Set categories for 20 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '87194352-7D59-4BB2-AF24-C815D3D43892' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.ActivitySyncRunID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Execution Context',
   GeneratedFormSection = 'Category',
   DisplayName = 'Activity Sync Run',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '92DD62BB-D66F-401B-8830-33B3246B0E26' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.ExternalID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'External Reference',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '36D13A87-C5B8-472A-9CDA-EB3731AFCC41' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.ExternalThreadID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'External Reference',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '15DD6494-57F4-42CA-BD84-0A15426A96BE' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.OccurredAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Execution Context',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7E700ED9-C6E6-487C-9304-AA7BB9FC222B' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.Decision 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Decision Logic',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '0078772B-133B-45CD-B584-0D96CBF51A88' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.DecidedByStage 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Decision Logic',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '38A89E25-30DD-4D1B-83D2-5E824D542E6D' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.ActivitySyncRuleID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Decision Logic',
   GeneratedFormSection = 'Category',
   DisplayName = 'Activity Sync Rule',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'F9D3B360-0DA7-4FB7-AC4F-8CA065AA9BF3' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.ActivitySyncExclusionID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Decision Logic',
   GeneratedFormSection = 'Category',
   DisplayName = 'Activity Sync Exclusion',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B7BE5C0E-E4D5-42FC-9B82-C0FD25DE4B2A' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.Reason 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Decision Logic',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'F31CBD79-1083-435A-9D00-39A89F03B524' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.Confidence 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Decision Logic',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '74F9BDC0-2B51-4F54-80DD-62677C682D67' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.AIPromptRunID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Decision Logic',
   GeneratedFormSection = 'Category',
   DisplayName = 'AI Prompt Run',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '21E93BC8-0535-445F-AAFD-F3468F1EB62D' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.ActivityID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Execution Context',
   GeneratedFormSection = 'Category',
   DisplayName = 'Activity',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '4087A170-CD32-4B2A-A59E-E2747F272AA8' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.CapturedContent 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Message Content',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7905D4D1-557E-4693-92A9-8CD497D793CD' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.EncryptionKeyID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Message Content',
   GeneratedFormSection = 'Category',
   DisplayName = 'Encryption Key',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '1E55257F-D2BE-4817-82C9-723AEE6F8E42' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '07F6AB2B-C765-45A5-BAFE-6166EC42F137' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '5CDA5908-7B09-4EA1-BFDF-75FA10555031' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.ActivitySyncRule 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Decision Logic',
   GeneratedFormSection = 'Category',
   DisplayName = 'Activity Sync Rule Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '33F6DC61-4A5B-4367-87D9-4B50FD89F1F3' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.Activity 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Execution Context',
   GeneratedFormSection = 'Category',
   DisplayName = 'Activity Reference',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '5BF4CF4B-B9E3-4237-8D0C-EEA4DF89CAD4' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Run Details.EncryptionKey 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Message Content',
   GeneratedFormSection = 'Category',
   DisplayName = 'Encryption Key Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '49C089A3-71F3-46A2-8182-E3A351B60A8C' AND AutoUpdateCategory = 1;

/* Set entity icon to fa fa-sync-alt */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-sync-alt', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = 'AC16B066-9460-44F5-B027-3FD397E61F34';

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('a9030c42-3d74-4c18-ba0d-9118d0fd3280', 'AC16B066-9460-44F5-B027-3FD397E61F34', 'FieldCategoryInfo', '{"Execution Context":{"icon":"fa fa-tasks","description":"Contextual information regarding the sync run and resulting activity links"},"External Reference":{"icon":"fa fa-external-link-alt","description":"Identifiers linking to the external message provider"},"Decision Logic":{"icon":"fa fa-brain","description":"Details on how and why a specific sync decision was reached"},"Message Content":{"icon":"fa fa-lock","description":"Secure storage for fragments of non-ingested messages"},"System Metadata":{"icon":"fa fa-cog","description":"System-managed audit and tracking fields"}}', GETUTCDATE(), GETUTCDATE());

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('f2d5b3bb-cbf5-46aa-8db9-0f31713c9b11', 'AC16B066-9460-44F5-B027-3FD397E61F34', 'FieldCategoryIcons', '{"Execution Context":"fa fa-tasks","External Reference":"fa fa-external-link-alt","Decision Logic":"fa fa-brain","Message Content":"fa fa-lock","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE());

/* Set DefaultForNewUser=false for NEW entity (category: supporting, confidence: high) */

         UPDATE [${mjSchema}].[ApplicationEntity]
         SET [DefaultForNewUser] = 0, [__mj_UpdatedAt] = GETUTCDATE()
         WHERE [EntityID] = 'AC16B066-9460-44F5-B027-3FD397E61F34';

