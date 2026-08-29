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
-- metadata/, never as INSERTs. CodeGen output ships as its own migration,
-- matching V202608251531__v5.36.x__Activity_CodeGen_Objects.sql.
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
    @value = N'Binds a rule set to a connection, ordered. Many-to-many so a mailbox composes an org-wide baseline, a team overlay, and anything specific to itself — rather than owning one private copy of everything.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncConnectionRuleSet';
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
