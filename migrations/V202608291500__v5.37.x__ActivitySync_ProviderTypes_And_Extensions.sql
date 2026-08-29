-- =============================================================================
-- v5.37.x — Activity Sync: provider types + extension registry
-- =============================================================================
-- Turns two things that were CODE into DATA, so the Activity Sync Engine is a
-- real plugin architecture rather than a fixed list of four providers.
--
--   1. ActivitySyncProviderType  — provider identity. Replaces
--      CK_ActivitySyncConnection_Provider, whose value list made every new
--      source (Twilio, WhatsApp, LinkedIn, X, …) a MIGRATION TO COMMON. That is
--      vocabulary-as-code and it is the exact consumer coupling this app exists
--      to avoid: Common must never need editing because a consumer added a
--      source.
--
--   2. ActivitySyncExtension     — the in-process enrichment registry. Common
--      ships the TABLE; each consumer app ships its own ROWS. A downstream app
--      contributes extra ActivityLinks inside the same transaction as the write
--      without Common naming it. A host without that app installed has no row.
--
-- Design: plans/activity-sync-engine.md
--
-- Both tables follow the ActivityType pattern: Code is the stable key that code
-- and metadata target; Name is display and may be renamed freely.
--
-- CodeGen output for these two entities ships as its own migration, matching
-- V202608251531__v5.36.x__Activity_CodeGen_Objects.sql — this file is DDL only.
-- Seed rows (the four existing provider types) ship as metadata/, never as
-- INSERTs here.
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
    Sequence INT NOT NULL DEFAULT 0,
    IsSystem BIT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_ActivitySyncProviderType PRIMARY KEY (ID),
    CONSTRAINT UQ_ActivitySyncProviderType_Code UNIQUE (Code),
    CONSTRAINT UQ_ActivitySyncProviderType_Name UNIQUE (Name),
    CONSTRAINT CK_ActivitySyncProviderType_QualPolicy CHECK (
        DefaultQualificationPolicy IN (N'Include', N'Exclude')
    )
);
GO

---------------------------------------------------------------------------
-- ActivitySyncConnection — point at the provider type
--
-- ADDITIVE, per the Publish-Then-No-Breaking-Changes policy. The new FK is
-- nullable and the legacy Provider column stays in place, deprecated, so a host
-- on the published version keeps working. A later major removes Provider.
--
-- No backfill statement: no ingestion engine has ever shipped, so no host has a
-- connection row to backfill. The metadata seed supplies the four provider-type
-- rows with hardcoded IDs; a host that somehow has legacy rows sets the FK from
-- Provider by hand.
---------------------------------------------------------------------------
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncConnection]
    ADD ActivitySyncProviderTypeID UNIQUEIDENTIFIER NULL;
GO

ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncConnection]
    ADD CONSTRAINT FK_ActivitySyncConnection_ProviderType
        FOREIGN KEY (ActivitySyncProviderTypeID)
        REFERENCES [${flyway:defaultSchema}].[ActivitySyncProviderType](ID);
GO

-- The constraint this whole migration exists to remove.
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncConnection]
    DROP CONSTRAINT CK_ActivitySyncConnection_Provider;
GO

-- Deprecated, and therefore no longer required. Widening a NOT NULL to NULL is
-- additive for readers and lets a new row identify its provider by FK alone.
ALTER TABLE [${flyway:defaultSchema}].[ActivitySyncConnection]
    ALTER COLUMN Provider NVARCHAR(40) NULL;
GO

---------------------------------------------------------------------------
-- ActivitySyncExtension
--
-- Registration is deliberately TWO-PART, matching DriverClass everywhere else
-- in MJ: @RegisterClass carries the code, this row enables and configures it
-- per host. Metadata alone cannot carry code; code alone cannot be configured
-- per deployment.
--
-- Scope is by connection OR provider type OR neither (= all connections). Both
-- are nullable and independent — a NULL in both columns is the common case for
-- an app that wants to enrich every activity it can see.
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
    CONSTRAINT FK_ActivitySyncExtension_Connection
        FOREIGN KEY (ActivitySyncConnectionID)
        REFERENCES [${flyway:defaultSchema}].[ActivitySyncConnection](ID)
        ON DELETE CASCADE,
    CONSTRAINT FK_ActivitySyncExtension_ProviderType
        FOREIGN KEY (ActivitySyncProviderTypeID)
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
-- Extended properties
---------------------------------------------------------------------------
EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'A kind of activity source (Microsoft365, Gmail, Twilio SMS, LinkedIn, …). Provider identity is DATA, not a CHECK constraint, so a new source is a new plugin package plus a metadata row — never a migration to Common. Code is the stable key that DriverClass registration and metadata target; Name is display.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncProviderType';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'The @RegisterClass key for the BaseActivitySyncProvider subclass that drives this provider type. Null means no driver is installed on this host — connections of this type will not run.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncProviderType',
    @level2type = N'COLUMN', @level2name = N'DriverClass';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'JSON array of the surfaces this provider can read, e.g. ["Message","Calendar"]. A calendar surface advances its watermark on INGEST time, never on max(StartedAt) — a meeting starts in the future, so a start-time watermark pins forward and the calendar silently stops ingesting.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncProviderType',
    @level2type = N'COLUMN', @level2name = N'SupportedKinds';
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
    @value = N'Registration of an in-process enrichment plugin that runs inside the Activity write transaction. Common ships this table; each consumer app ships its own rows, so a downstream app adds links (a deal, a campaign) without Common knowing it exists. Extensions ENRICH — they never veto an activity, because qualification has already run and capture must not depend on which apps are installed.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncExtension';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'The @RegisterClass key for the BaseActivitySyncExtension subclass, e.g. Sales.DealLinker. The class ships in the consumer app''s package; this row enables and configures it on this host.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncExtension',
    @level2type = N'COLUMN', @level2name = N'DriverClass';
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
    @value = N'Hard cap on this extension''s run. It holds the write transaction open for its whole duration, so an unbounded extension is an unbounded lock.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncExtension',
    @level2type = N'COLUMN', @level2name = N'TimeoutMS';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'The provider type this connection reads. Supersedes the Provider string column, whose CHECK constraint made every new source a migration to Common.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncConnection',
    @level2type = N'COLUMN', @level2name = N'ActivitySyncProviderTypeID';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'DEPRECATED — use ActivitySyncProviderTypeID. Retained nullable so a published host keeps working; removed in the next major.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncConnection',
    @level2type = N'COLUMN', @level2name = N'Provider';
GO
