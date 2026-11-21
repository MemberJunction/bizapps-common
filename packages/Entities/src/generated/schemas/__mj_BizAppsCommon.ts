import { z } from "zod";


/**
 * zod schema definition for the entity MJ_BizApps_Common: Activities
 */
export const mjBizAppsCommonActivitySchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    ActivityTypeID: z.string().describe(`
        * * Field Name: ActivityTypeID
        * * Display Name: Activity Type
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Types (vwActivityTypes.ID)`),
    StartedAt: z.date().describe(`
        * * Field Name: StartedAt
        * * Display Name: Started At
        * * SQL Data Type: datetimeoffset
        * * Description: Sort key for every timeline. Instant events use the date/time of the event.`),
    EndedAt: z.date().nullable().describe(`
        * * Field Name: EndedAt
        * * Display Name: Ended At
        * * SQL Data Type: datetimeoffset
        * * Description: End of a meeting/call. Leave null for a point-in-time log. Must be >= StartedAt when set. Duration is derived; do not store it.`),
    Title: z.string().describe(`
        * * Field Name: Title
        * * Display Name: Title
        * * SQL Data Type: nvarchar(500)
        * * Description: Subject / one-line card title (e.g. Called Jane about renewal).`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Notes or a short excerpt. Not the full email body — that lives on an ActivityFile of Kind Body.`),
    Direction: z.union([z.literal('Inbound'), z.literal('Internal'), z.literal('Outbound')]).describe(`
        * * Field Name: Direction
        * * Display Name: Direction
        * * SQL Data Type: nvarchar(20)
    * * Value List Type: List
    * * Possible Values 
    *   * Inbound
    *   * Internal
    *   * Outbound
        * * Description: Inbound, Outbound, or Internal. Channel lives on ActivityType; direction lives here so inbound email is a filter, not a type explosion.`),
    Status: z.union([z.literal('Cancelled'), z.literal('Completed'), z.literal('Failed'), z.literal('Logged'), z.literal('Scheduled')]).describe(`
        * * Field Name: Status
        * * Display Name: Status
        * * SQL Data Type: nvarchar(20)
        * * Default Value: Logged
    * * Value List Type: List
    * * Possible Values 
    *   * Cancelled
    *   * Completed
    *   * Failed
    *   * Logged
    *   * Scheduled
        * * Description: Logged (default for a past event), Scheduled, Completed, Cancelled, or Failed.`),
    Outcome: z.union([z.literal('Bounced'), z.literal('Connected'), z.literal('Interested'), z.literal('LeftVoicemail'), z.literal('NoAnswer'), z.literal('NoShow'), z.literal('NotInterested')]).nullable().describe(`
        * * Field Name: Outcome
        * * Display Name: Outcome
        * * SQL Data Type: nvarchar(40)
    * * Value List Type: List
    * * Possible Values 
    *   * Bounced
    *   * Connected
    *   * Interested
    *   * LeftVoicemail
    *   * NoAnswer
    *   * NoShow
    *   * NotInterested
        * * Description: Optional disposition: Connected, LeftVoicemail, NoAnswer, NoShow, Bounced, Interested, NotInterested. A filter, not a type.`),
    Visibility: z.union([z.literal('Internal'), z.literal('Private')]).describe(`
        * * Field Name: Visibility
        * * Display Name: Visibility
        * * SQL Data Type: nvarchar(20)
        * * Default Value: Internal
    * * Value List Type: List
    * * Possible Values 
    *   * Internal
    *   * Private
        * * Description: Internal (anyone who can read a Regarding record) or Private (LoggedByUserID only, until a PermissionEngine domain exists). Manual default is Internal; synced mail should default Private in the engine.`),
    Source: z.union([z.literal('Integration'), z.literal('Manual'), z.literal('System')]).describe(`
        * * Field Name: Source
        * * Display Name: Source
        * * SQL Data Type: nvarchar(20)
        * * Default Value: Manual
    * * Value List Type: List
    * * Possible Values 
    *   * Integration
    *   * Manual
    *   * System
        * * Description: How the row was written: Manual, System, or Integration.`),
    SourceSystem: z.string().nullable().describe(`
        * * Field Name: SourceSystem
        * * Display Name: Source System
        * * SQL Data Type: nvarchar(80)
        * * Description: Provider name for idempotent sync (Microsoft365, Gmail, Zoom). Required when ExternalID is set.`),
    ExternalID: z.string().nullable().describe(`
        * * Field Name: ExternalID
        * * Display Name: External ID
        * * SQL Data Type: nvarchar(400)
        * * Description: Provider message/event id. Unique with SourceSystem where set — never dedup by subject.`),
    ExternalThreadID: z.string().nullable().describe(`
        * * Field Name: ExternalThreadID
        * * Display Name: External Thread ID
        * * SQL Data Type: nvarchar(400)
        * * Description: Email or calendar thread id used to group replies.`),
    ParentActivityID: z.string().nullable().describe(`
        * * Field Name: ParentActivityID
        * * Display Name: Parent Activity
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activities (vwActivities.ID)`),
    LoggedByUserID: z.string().describe(`
        * * Field Name: LoggedByUserID
        * * Display Name: Logged By User
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ: Users (vwUsers.ID)`),
    Location: z.string().nullable().describe(`
        * * Field Name: Location
        * * Display Name: Location
        * * SQL Data Type: nvarchar(500)
        * * Description: Meeting place as text. Optional AddressID is the structured location.`),
    AddressID: z.string().nullable().describe(`
        * * Field Name: AddressID
        * * Display Name: Address
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Addresses (vwAddresses.ID)`),
    ActivitySyncConnectionID: z.string().nullable().describe(`
        * * Field Name: ActivitySyncConnectionID
        * * Display Name: Sync Connection
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Connections (vwActivitySyncConnections.ID)`),
    Details: z.string().nullable().describe(`
        * * Field Name: Details
        * * Display Name: Details
        * * SQL Data Type: nvarchar(MAX)
        * * Description: JSON extras that are not query predicates: MessageID, InReplyTo, MeetingURL, Mailbox, Folder, CalendarEventID. See ActivityDetails.`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    SentimentScore: z.number().nullable().describe(`
        * * Field Name: SentimentScore
        * * Display Name: Sentiment Score
        * * SQL Data Type: decimal(4, 3)
        * * Description: Derived sentiment score for this activity, bounded between -1.000 (most negative) and +1.000 (most positive). Populated by the Activity Tagging and Sentiment feature pipeline.`),
    ActivityType: z.string().nullable().describe(`
        * * Field Name: ActivityType
        * * Display Name: Activity Type Name
        * * SQL Data Type: nvarchar(100)`),
    ParentActivity: z.string().nullable().describe(`
        * * Field Name: ParentActivity
        * * Display Name: Parent Activity
        * * SQL Data Type: nvarchar(500)`),
    LoggedByUser: z.string().nullable().describe(`
        * * Field Name: LoggedByUser
        * * Display Name: Logged By
        * * SQL Data Type: nvarchar(100)`),
    Address: z.string().nullable().describe(`
        * * Field Name: Address
        * * Display Name: Address Details
        * * SQL Data Type: nvarchar(400)`),
    ActivitySyncConnection: z.string().nullable().describe(`
        * * Field Name: ActivitySyncConnection
        * * Display Name: Sync Connection Name
        * * SQL Data Type: nvarchar(200)`),
    RootParentActivityID: z.string().nullable().describe(`
        * * Field Name: RootParentActivityID
        * * Display Name: Root Parent Activity
        * * SQL Data Type: uniqueidentifier`),
    ParentActivityIDDepth: z.number().nullable().describe(`
        * * Field Name: ParentActivityIDDepth
        * * Display Name: Hierarchy Depth
        * * SQL Data Type: int`),
    ParentActivityIDPath: z.string().nullable().describe(`
        * * Field Name: ParentActivityIDPath
        * * Display Name: Hierarchy Path
        * * SQL Data Type: nvarchar(MAX)`),
    ParentActivityIDIsLeaf: z.boolean().nullable().describe(`
        * * Field Name: ParentActivityIDIsLeaf
        * * Display Name: Is Leaf
        * * SQL Data Type: bit`),
    ParentActivityIDChildCount: z.number().nullable().describe(`
        * * Field Name: ParentActivityIDChildCount
        * * Display Name: Child Count
        * * SQL Data Type: int`),
});

export type mjBizAppsCommonActivityEntityType = z.infer<typeof mjBizAppsCommonActivitySchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Activity Files
 */
export const mjBizAppsCommonActivityFileSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    ActivityID: z.string().describe(`
        * * Field Name: ActivityID
        * * Display Name: Activity ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activities (vwActivities.ID)`),
    FileID: z.string().describe(`
        * * Field Name: FileID
        * * Display Name: File ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ: Files (vwFiles.ID)`),
    Kind: z.union([z.literal('Attachment'), z.literal('Body'), z.literal('Ics')]).describe(`
        * * Field Name: Kind
        * * Display Name: Kind
        * * SQL Data Type: nvarchar(20)
    * * Value List Type: List
    * * Possible Values 
    *   * Attachment
    *   * Body
    *   * Ics
        * * Description: Body (full MIME/HTML, at most one per activity), Attachment, or Ics.`),
    Sequence: z.number().describe(`
        * * Field Name: Sequence
        * * Display Name: Sequence
        * * SQL Data Type: int
        * * Default Value: 0
        * * Description: Display order of attachments.`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    Activity: z.string().nullable().describe(`
        * * Field Name: Activity
        * * Display Name: Activity
        * * SQL Data Type: nvarchar(500)`),
    File: z.string().nullable().describe(`
        * * Field Name: File
        * * Display Name: File
        * * SQL Data Type: nvarchar(500)`),
});

export type mjBizAppsCommonActivityFileEntityType = z.infer<typeof mjBizAppsCommonActivityFileSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Activity Links
 */
export const mjBizAppsCommonActivityLinkSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    ActivityID: z.string().describe(`
        * * Field Name: ActivityID
        * * Display Name: Activity ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activities (vwActivities.ID)`),
    Role: z.union([z.literal('Attendee'), z.literal('Bcc'), z.literal('Cc'), z.literal('From'), z.literal('LoggedFor'), z.literal('Organizer'), z.literal('Participant'), z.literal('Regarding'), z.literal('To')]).describe(`
        * * Field Name: Role
        * * Display Name: Role
        * * SQL Data Type: nvarchar(30)
    * * Value List Type: List
    * * Possible Values 
    *   * Attendee
    *   * Bcc
    *   * Cc
    *   * From
    *   * LoggedFor
    *   * Organizer
    *   * Participant
    *   * Regarding
    *   * To
        * * Description: Why this record is on the activity: Regarding (what it is about), Participant, From/To/Cc/Bcc, Organizer/Attendee, or LoggedFor (the mailbox it was filed under).`),
    EntityID: z.string().nullable().describe(`
        * * Field Name: EntityID
        * * Display Name: Entity ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ: Entities (vwEntities.ID)`),
    RecordID: z.string().nullable().describe(`
        * * Field Name: RecordID
        * * Display Name: Record ID
        * * SQL Data Type: nvarchar(450)
        * * Description: Primary key of the resolved record. NVARCHAR so composite keys work. Required with EntityID; must be null when the link is an unresolved identity.`),
    IdentityKind: z.union([z.literal('Email'), z.literal('ExternalUser'), z.literal('Phone')]).nullable().describe(`
        * * Field Name: IdentityKind
        * * Display Name: Identity Kind
        * * SQL Data Type: nvarchar(20)
    * * Value List Type: List
    * * Possible Values 
    *   * Email
    *   * ExternalUser
    *   * Phone
        * * Description: Email, Phone, or ExternalUser. Set with IdentityValue when the participant has not been matched to a Person/Org yet.`),
    IdentityValue: z.string().nullable().describe(`
        * * Field Name: IdentityValue
        * * Display Name: Identity Value
        * * SQL Data Type: nvarchar(320)
        * * Description: The unmatched address, phone, or provider user id. A later matcher stamps EntityID/RecordID from ContactMethod.Value and clears these.`),
    Sequence: z.number().describe(`
        * * Field Name: Sequence
        * * Display Name: Sequence
        * * SQL Data Type: int
        * * Default Value: 0
        * * Description: Display order within a role (To, then Cc, …).`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    Activity: z.string().nullable().describe(`
        * * Field Name: Activity
        * * Display Name: Activity
        * * SQL Data Type: nvarchar(500)`),
    Entity: z.string().nullable().describe(`
        * * Field Name: Entity
        * * Display Name: Entity
        * * SQL Data Type: nvarchar(255)`),
});

export type mjBizAppsCommonActivityLinkEntityType = z.infer<typeof mjBizAppsCommonActivityLinkSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Activity Sync Connection Rule Sets
 */
export const mjBizAppsCommonActivitySyncConnectionRuleSetSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    ActivitySyncConnectionID: z.string().describe(`
        * * Field Name: ActivitySyncConnectionID
        * * Display Name: Activity Sync Connection
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Connections (vwActivitySyncConnections.ID)`),
    ActivitySyncRuleSetID: z.string().describe(`
        * * Field Name: ActivitySyncRuleSetID
        * * Display Name: Activity Sync Rule Set
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Rule Sets (vwActivitySyncRuleSets.ID)
        * * Description: The rule set bound to this connection. A mailbox composes several sets (org baseline, team overlay, mailbox-specific) through this join; Sequence on the binding is the evaluation order.`),
    Sequence: z.number().describe(`
        * * Field Name: Sequence
        * * Display Name: Evaluation Sequence
        * * SQL Data Type: int
        * * Default Value: 0`),
    IsEnabled: z.boolean().describe(`
        * * Field Name: IsEnabled
        * * Display Name: Is Enabled
        * * SQL Data Type: bit
        * * Default Value: 1`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    ActivitySyncConnection: z.string().describe(`
        * * Field Name: ActivitySyncConnection
        * * Display Name: Connection Name
        * * SQL Data Type: nvarchar(200)`),
    ActivitySyncRuleSet: z.string().describe(`
        * * Field Name: ActivitySyncRuleSet
        * * Display Name: Rule Set Name
        * * SQL Data Type: nvarchar(200)`),
});

export type mjBizAppsCommonActivitySyncConnectionRuleSetEntityType = z.infer<typeof mjBizAppsCommonActivitySyncConnectionRuleSetSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Activity Sync Connections
 */
export const mjBizAppsCommonActivitySyncConnectionSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(200)
        * * Description: Display name of the connection (e.g. Amith / Microsoft 365).`),
    Provider: z.union([z.literal('Generic'), z.literal('Gmail'), z.literal('Microsoft365'), z.literal('Zoom')]).nullable().describe(`
        * * Field Name: Provider
        * * Display Name: Provider
        * * SQL Data Type: nvarchar(40)
    * * Value List Type: List
    * * Possible Values 
    *   * Generic
    *   * Gmail
    *   * Microsoft365
    *   * Zoom
        * * Description: DEPRECATED — use ActivitySyncProviderTypeID. Retained nullable so a published host keeps working; removed in the next major.`),
    Status: z.union([z.literal('Active'), z.literal('Disabled'), z.literal('Error'), z.literal('Paused')]).describe(`
        * * Field Name: Status
        * * Display Name: Status
        * * SQL Data Type: nvarchar(20)
        * * Default Value: Active
    * * Value List Type: List
    * * Possible Values 
    *   * Active
    *   * Disabled
    *   * Error
    *   * Paused
        * * Description: Active, Paused, Error, or Disabled.`),
    Direction: z.union([z.literal('Bidirectional'), z.literal('Inbound'), z.literal('Outbound')]).describe(`
        * * Field Name: Direction
        * * Display Name: Direction
        * * SQL Data Type: nvarchar(20)
        * * Default Value: Inbound
    * * Value List Type: List
    * * Possible Values 
    *   * Bidirectional
    *   * Inbound
    *   * Outbound
        * * Description: Inbound (pull into CRM), Outbound, or Bidirectional.`),
    OwnerUserID: z.string().describe(`
        * * Field Name: OwnerUserID
        * * Display Name: Owner User ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ: Users (vwUsers.ID)`),
    CredentialsRef: z.string().nullable().describe(`
        * * Field Name: CredentialsRef
        * * Display Name: Credentials Reference
        * * SQL Data Type: nvarchar(200)
        * * Description: MJ Credentials engine key. NEVER a secret value at rest.`),
    Mailbox: z.string().nullable().describe(`
        * * Field Name: Mailbox
        * * Display Name: Mailbox
        * * SQL Data Type: nvarchar(320)
        * * Description: Mailbox address this connection reads (jane@acme.com).`),
    LastSyncAt: z.date().nullable().describe(`
        * * Field Name: LastSyncAt
        * * Display Name: Last Sync At
        * * SQL Data Type: datetimeoffset
        * * Description: When the engine last completed a sync for this connection.`),
    LastError: z.string().nullable().describe(`
        * * Field Name: LastError
        * * Display Name: Last Error
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Most recent sync error, if Status is Error.`),
    Settings: z.string().nullable().describe(`
        * * Field Name: Settings
        * * Display Name: Settings
        * * SQL Data Type: nvarchar(MAX)
        * * Description: JSON provider extras (TenantID, MailboxFolder, CalendarID, IncludeCalendar, IncludeMail). See ActivitySyncConnectionSettings.`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    ActivitySyncProviderTypeID: z.string().nullable().describe(`
        * * Field Name: ActivitySyncProviderTypeID
        * * Display Name: Provider Type
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Provider Types (vwActivitySyncProviderTypes.ID)
        * * Description: The provider type this connection reads. Supersedes the Provider string column, whose CHECK constraint made every new source a migration to Common.`),
    StartAt: z.date().nullable().describe(`
        * * Field Name: StartAt
        * * Display Name: Start At
        * * SQL Data Type: datetimeoffset
        * * Description: Activation window. Combines with Status: a connection syncs only when Status = Active AND now is within [StartAt, EndAt], treating either bound as open when null. Lets a mailbox be provisioned ahead of time, or retired on a date, without anyone remembering to flip a switch.`),
    EndAt: z.date().nullable().describe(`
        * * Field Name: EndAt
        * * Display Name: End At
        * * SQL Data Type: datetimeoffset
        * * Description: End of the activation window; see StartAt. Null means open-ended.`),
    SkippedContentPolicy: z.union([z.literal('FullEncrypted'), z.literal('None'), z.literal('SubjectEncrypted')]).nullable().describe(`
        * * Field Name: SkippedContentPolicy
        * * Display Name: Skipped Content Policy
        * * SQL Data Type: nvarchar(20)
    * * Value List Type: List
    * * Possible Values 
    *   * FullEncrypted
    *   * None
    *   * SubjectEncrypted
        * * Description: Per-connection override of the provider type's DefaultSkippedContentPolicy. Null inherits. This is the knob for "this one mailbox is sensitive" without changing the estate.`),
    EncryptionKeyID: z.string().nullable().describe(`
        * * Field Name: EncryptionKeyID
        * * Display Name: Encryption Key ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ: Encryption Keys (vwEncryptionKeys.ID)`),
    StorageProviderID: z.string().nullable().describe(`
        * * Field Name: StorageProviderID
        * * Display Name: Storage Provider ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ: File Storage Providers (vwFileStorageProviders.ID)`),
    MaxAttachmentBytes: z.number().nullable().describe(`
        * * Field Name: MaxAttachmentBytes
        * * Display Name: Max Attachment Bytes
        * * SQL Data Type: bigint`),
    OwnerUser: z.string().nullable().describe(`
        * * Field Name: OwnerUser
        * * Display Name: Owner User
        * * SQL Data Type: nvarchar(100)`),
    ActivitySyncProviderType: z.string().nullable().describe(`
        * * Field Name: ActivitySyncProviderType
        * * Display Name: Provider Type Name
        * * SQL Data Type: nvarchar(100)`),
    EncryptionKey: z.string().nullable().describe(`
        * * Field Name: EncryptionKey
        * * Display Name: Encryption Key
        * * SQL Data Type: nvarchar(100)`),
    StorageProvider: z.string().nullable().describe(`
        * * Field Name: StorageProvider
        * * Display Name: Storage Provider
        * * SQL Data Type: nvarchar(50)`),
});

export type mjBizAppsCommonActivitySyncConnectionEntityType = z.infer<typeof mjBizAppsCommonActivitySyncConnectionSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Activity Sync Exclusions
 */
export const mjBizAppsCommonActivitySyncExclusionSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    ActivitySyncRuleSetID: z.string().nullable().describe(`
        * * Field Name: ActivitySyncRuleSetID
        * * Display Name: Activity Sync Rule Set
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Rule Sets (vwActivitySyncRuleSets.ID)
        * * Description: Optional rule set this exclusion belongs to. Null means global — the identity is never ingested on any connection. A legal hold or opt-out is usually global; a mailbox-specific mute is not.`),
    IdentityKind: z.union([z.literal('Domain'), z.literal('Email'), z.literal('Handle'), z.literal('Phone')]).describe(`
        * * Field Name: IdentityKind
        * * Display Name: Identity Kind
        * * SQL Data Type: nvarchar(20)
    * * Value List Type: List
    * * Possible Values 
    *   * Domain
    *   * Email
    *   * Handle
    *   * Phone`),
    IdentityValue: z.string().describe(`
        * * Field Name: IdentityValue
        * * Display Name: Identity Value
        * * SQL Data Type: nvarchar(320)`),
    PersonID: z.string().nullable().describe(`
        * * Field Name: PersonID
        * * Display Name: Person
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: People (vwPeople.ID)
        * * Description: Optional link to the Person this identity belongs to. Optional because an address is often excluded before anyone knows whose it is, and because a Person has several ContactMethods — the identity is the durable key here, not the record.`),
    Reason: z.string().nullable().describe(`
        * * Field Name: Reason
        * * Display Name: Reason
        * * SQL Data Type: nvarchar(MAX)`),
    EffectiveFrom: z.date().nullable().describe(`
        * * Field Name: EffectiveFrom
        * * Display Name: Effective From
        * * SQL Data Type: datetimeoffset
        * * Description: Start of the window of MESSAGES this exclusion covers, matched against the item's own time -- when a message was sent or received, or when a meeting starts -- NOT against the current time. Leave empty for no lower bound. This is deliberately different from ActivitySyncConnection.StartAt, which is evaluated against the clock: setting this to today does not mean "exclude from today onwards", it means "exclude messages dated today or later", so a later backfill of older mail is not covered by it. Item time is also what keeps a re-run reproducible, so the run log can answer which rule excluded a message and give the same answer next time.`),
    EffectiveTo: z.date().nullable().describe(`
        * * Field Name: EffectiveTo
        * * Display Name: Effective To
        * * SQL Data Type: datetimeoffset
        * * Description: End of the window of MESSAGES this exclusion covers, matched against the item's own time -- when a message was sent or received, or when a meeting starts -- NOT against the current time. Leave empty for no upper bound. Inclusive of the instant given, matching how ActivitySyncRule DateFrom/DateTo compare. See EffectiveFrom for why this is item time rather than clock time.`),
    IsEnabled: z.boolean().describe(`
        * * Field Name: IsEnabled
        * * Display Name: Is Enabled
        * * SQL Data Type: bit
        * * Default Value: 1
        * * Description: Whether this exclusion is in force. Unchecked, it is ignored entirely and the messages it names are qualified as if it did not exist.`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    ActivitySyncRuleSet: z.string().nullable().describe(`
        * * Field Name: ActivitySyncRuleSet
        * * Display Name: Rule Set Name
        * * SQL Data Type: nvarchar(200)`),
    Person: z.string().nullable().describe(`
        * * Field Name: Person
        * * Display Name: Person Name
        * * SQL Data Type: nvarchar(250)`),
});

export type mjBizAppsCommonActivitySyncExclusionEntityType = z.infer<typeof mjBizAppsCommonActivitySyncExclusionSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Activity Sync Extensions
 */
export const mjBizAppsCommonActivitySyncExtensionSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(200)`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)`),
    DriverClass: z.string().describe(`
        * * Field Name: DriverClass
        * * Display Name: Driver Class
        * * SQL Data Type: nvarchar(200)`),
    ActivitySyncConnectionID: z.string().nullable().describe(`
        * * Field Name: ActivitySyncConnectionID
        * * Display Name: Activity Sync Connection
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Connections (vwActivitySyncConnections.ID)`),
    ActivitySyncProviderTypeID: z.string().nullable().describe(`
        * * Field Name: ActivitySyncProviderTypeID
        * * Display Name: Activity Sync Provider Type
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Provider Types (vwActivitySyncProviderTypes.ID)
        * * Description: Optional provider type this extension is registered for. Null means it runs on every connection. A deal-linker that only makes sense on email can bind here rather than being invoked for a phone transcript.`),
    Sequence: z.number().describe(`
        * * Field Name: Sequence
        * * Display Name: Sequence
        * * SQL Data Type: int
        * * Default Value: 0
        * * Description: Ascending run order. REQUIRED rather than incidental: two extensions both adding links must not depend on registration order, which varies with package load order and is not reproducible.`),
    FailurePolicy: z.union([z.literal('Abort'), z.literal('Skip')]).describe(`
        * * Field Name: FailurePolicy
        * * Display Name: Failure Policy
        * * SQL Data Type: nvarchar(20)
        * * Default Value: Skip
    * * Value List Type: List
    * * Possible Values 
    *   * Abort
    *   * Skip
        * * Description: What happens when this extension throws. Skip (the default) records the error and commits the activity without the enrichment; Abort rolls the whole write back. Skip is the default because the activity is worth more than the enrichment, and one buggy consumer app must not be able to halt ingestion for every other app on the host.`),
    TimeoutMS: z.number().describe(`
        * * Field Name: TimeoutMS
        * * Display Name: Timeout (ms)
        * * SQL Data Type: int
        * * Default Value: 5000`),
    IsEnabled: z.boolean().describe(`
        * * Field Name: IsEnabled
        * * Display Name: Is Enabled
        * * SQL Data Type: bit
        * * Default Value: 1`),
    LastRunAt: z.date().nullable().describe(`
        * * Field Name: LastRunAt
        * * Display Name: Last Run At
        * * SQL Data Type: datetimeoffset`),
    LastError: z.string().nullable().describe(`
        * * Field Name: LastError
        * * Display Name: Last Error
        * * SQL Data Type: nvarchar(MAX)`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    ActivitySyncConnection: z.string().nullable().describe(`
        * * Field Name: ActivitySyncConnection
        * * Display Name: Activity Sync Connection (Name)
        * * SQL Data Type: nvarchar(200)`),
    ActivitySyncProviderType: z.string().nullable().describe(`
        * * Field Name: ActivitySyncProviderType
        * * Display Name: Activity Sync Provider Type (Name)
        * * SQL Data Type: nvarchar(100)`),
});

export type mjBizAppsCommonActivitySyncExtensionEntityType = z.infer<typeof mjBizAppsCommonActivitySyncExtensionSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Activity Sync Provider Types
 */
export const mjBizAppsCommonActivitySyncProviderTypeSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Code: z.string().describe(`
        * * Field Name: Code
        * * Display Name: Code
        * * SQL Data Type: nvarchar(60)`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(100)`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)`),
    DriverClass: z.string().nullable().describe(`
        * * Field Name: DriverClass
        * * Display Name: Driver Class
        * * SQL Data Type: nvarchar(200)`),
    IconClass: z.string().nullable().describe(`
        * * Field Name: IconClass
        * * Display Name: Icon Class
        * * SQL Data Type: nvarchar(100)`),
    SupportedKinds: z.string().nullable().describe(`
        * * Field Name: SupportedKinds
        * * Display Name: Supported Kinds
        * * SQL Data Type: nvarchar(MAX)`),
    DefaultQualificationPolicy: z.union([z.literal('Exclude'), z.literal('Include')]).describe(`
        * * Field Name: DefaultQualificationPolicy
        * * Display Name: Default Qualification Policy
        * * SQL Data Type: nvarchar(20)
        * * Default Value: Exclude
    * * Value List Type: List
    * * Possible Values 
    *   * Exclude
    *   * Include
        * * Description: What an Undecided qualification verdict means for this provider once every rule stage has abstained. Exclude (the default) fails CLOSED — correct for anything mailbox-shaped, where capturing a private message is worse than missing a business one.`),
    DefaultSkippedContentPolicy: z.union([z.literal('FullEncrypted'), z.literal('None'), z.literal('SubjectEncrypted')]).describe(`
        * * Field Name: DefaultSkippedContentPolicy
        * * Display Name: Default Skipped Content Policy
        * * SQL Data Type: nvarchar(20)
        * * Default Value: None
    * * Value List Type: List
    * * Possible Values 
    *   * FullEncrypted
    *   * None
    *   * SubjectEncrypted
        * * Description: Whether a SKIPPED message may have content retained for audit, and how much. None keeps only the opaque external id and the decision. SubjectEncrypted and FullEncrypted additionally keep ciphertext, and are only valid with DefaultEncryptionKeyID set — enforced by CK_ActivitySyncProviderType_KeyRequired. Overridable per connection.`),
    DefaultEncryptionKeyID: z.string().nullable().describe(`
        * * Field Name: DefaultEncryptionKeyID
        * * Display Name: Default Encryption Key ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ: Encryption Keys (vwEncryptionKeys.ID)`),
    DefaultStorageProviderID: z.string().nullable().describe(`
        * * Field Name: DefaultStorageProviderID
        * * Display Name: Default Storage Provider ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ: File Storage Providers (vwFileStorageProviders.ID)`),
    DefaultMaxAttachmentBytes: z.number().nullable().describe(`
        * * Field Name: DefaultMaxAttachmentBytes
        * * Display Name: Default Max Attachment Bytes
        * * SQL Data Type: bigint`),
    Sequence: z.number().describe(`
        * * Field Name: Sequence
        * * Display Name: Sequence
        * * SQL Data Type: int
        * * Default Value: 0`),
    IsSystem: z.boolean().describe(`
        * * Field Name: IsSystem
        * * Display Name: Is System
        * * SQL Data Type: bit
        * * Default Value: 0`),
    IsActive: z.boolean().describe(`
        * * Field Name: IsActive
        * * Display Name: Is Active
        * * SQL Data Type: bit
        * * Default Value: 1
        * * Description: Whether this connector type may run. Unchecked, every connection using it refuses on its next fleet tick and reports Status = Error with the reason, rather than appearing to sync -- and each returns to Active by itself once the type is re-enabled and a run succeeds. Nothing is read from any mailbox while it is off.`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    CalendarDriverClass: z.string().nullable().describe(`
        * * Field Name: CalendarDriverClass
        * * Display Name: Calendar Driver Class
        * * SQL Data Type: nvarchar(200)`),
    DefaultEncryptionKey: z.string().nullable().describe(`
        * * Field Name: DefaultEncryptionKey
        * * Display Name: Default Encryption Key
        * * SQL Data Type: nvarchar(100)`),
    DefaultStorageProvider: z.string().nullable().describe(`
        * * Field Name: DefaultStorageProvider
        * * Display Name: Default Storage Provider
        * * SQL Data Type: nvarchar(50)`),
});

export type mjBizAppsCommonActivitySyncProviderTypeEntityType = z.infer<typeof mjBizAppsCommonActivitySyncProviderTypeSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Activity Sync Rule Sets
 */
export const mjBizAppsCommonActivitySyncRuleSetSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(200)`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)`),
    ActivitySyncProviderTypeID: z.string().nullable().describe(`
        * * Field Name: ActivitySyncProviderTypeID
        * * Display Name: Activity Sync Provider Type ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Provider Types (vwActivitySyncProviderTypes.ID)
        * * Description: Optional provider type this rule set is written for. Null means the set applies regardless of source — an org-wide prohibition does not care whether the mailbox is Microsoft365 or Gmail.`),
    InternalDomains: z.string().nullable().describe(`
        * * Field Name: InternalDomains
        * * Display Name: Internal Domains
        * * SQL Data Type: nvarchar(MAX)
        * * Description: JSON array of the domains this deployment considers INTERNAL, e.g. ["bluecypress.io"]. Required for any rule using ParticipantScope: "internal" is a property of the deployment, not of a message. Held on the rule set so one definition serves every mailbox bound to it.`),
    Sequence: z.number().describe(`
        * * Field Name: Sequence
        * * Display Name: Sequence
        * * SQL Data Type: int
        * * Default Value: 0`),
    IsEnabled: z.boolean().describe(`
        * * Field Name: IsEnabled
        * * Display Name: Is Enabled
        * * SQL Data Type: bit
        * * Default Value: 1`),
    IsSystem: z.boolean().describe(`
        * * Field Name: IsSystem
        * * Display Name: Is System
        * * SQL Data Type: bit
        * * Default Value: 0`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    ActivitySyncProviderType: z.string().nullable().describe(`
        * * Field Name: ActivitySyncProviderType
        * * Display Name: Activity Sync Provider Type
        * * SQL Data Type: nvarchar(100)`),
});

export type mjBizAppsCommonActivitySyncRuleSetEntityType = z.infer<typeof mjBizAppsCommonActivitySyncRuleSetSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Activity Sync Rules
 */
export const mjBizAppsCommonActivitySyncRuleSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    ActivitySyncConnectionID: z.string().nullable().describe(`
        * * Field Name: ActivitySyncConnectionID
        * * Display Name: Sync Connection
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Connections (vwActivitySyncConnections.ID)`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Rule Name
        * * SQL Data Type: nvarchar(200)
        * * Description: Display name of the rule.`),
    IsEnabled: z.boolean().describe(`
        * * Field Name: IsEnabled
        * * Display Name: Is Enabled
        * * SQL Data Type: bit
        * * Default Value: 1
        * * Description: 0 skips the rule without deleting it.`),
    Sequence: z.number().describe(`
        * * Field Name: Sequence
        * * Display Name: Sequence
        * * SQL Data Type: int
        * * Default Value: 0
        * * Description: Evaluation order within the connection. Lower first.`),
    Action: z.union([z.literal('Exclude'), z.literal('Include')]).describe(`
        * * Field Name: Action
        * * Display Name: Action
        * * SQL Data Type: nvarchar(20)
        * * Default Value: Include
    * * Value List Type: List
    * * Possible Values 
    *   * Exclude
    *   * Include
        * * Description: Include or Exclude matching items. With no rules, the engine syncs everything the connection can see.`),
    ActivityTypeID: z.string().nullable().describe(`
        * * Field Name: ActivityTypeID
        * * Display Name: Activity Type
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Types (vwActivityTypes.ID)`),
    Direction: z.union([z.literal('Inbound'), z.literal('Internal'), z.literal('Outbound')]).nullable().describe(`
        * * Field Name: Direction
        * * Display Name: Direction
        * * SQL Data Type: nvarchar(20)
    * * Value List Type: List
    * * Possible Values 
    *   * Inbound
    *   * Internal
    *   * Outbound
        * * Description: Optional direction filter (Inbound / Outbound / Internal). Null = any.`),
    DateFrom: z.date().nullable().describe(`
        * * Field Name: DateFrom
        * * Display Name: Sync From
        * * SQL Data Type: datetimeoffset
        * * Description: Inclusive lower bound of the sync window. Null = no lower bound.`),
    DateTo: z.date().nullable().describe(`
        * * Field Name: DateTo
        * * Display Name: Sync To
        * * SQL Data Type: datetimeoffset
        * * Description: Inclusive upper bound of the sync window. Null = no upper bound.`),
    IncludeAttachments: z.boolean().describe(`
        * * Field Name: IncludeAttachments
        * * Display Name: Include Attachments
        * * SQL Data Type: bit
        * * Default Value: 0
        * * Description: 1 = also pull attachments into ActivityFile rows.`),
    Filter: z.string().nullable().describe(`
        * * Field Name: Filter
        * * Display Name: Filter Rules
        * * SQL Data Type: nvarchar(MAX)
        * * Description: JSON match extras: Folders, ExcludeFolders, Domains, ExcludeDomains, ParticipantMustMatchContactMethod, SubjectContains, SubjectExcludes. See ActivitySyncRuleFilter.`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    ActivitySyncRuleSetID: z.string().nullable().describe(`
        * * Field Name: ActivitySyncRuleSetID
        * * Display Name: Sync Rule Set
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Rule Sets (vwActivitySyncRuleSets.ID)
        * * Description: The rule set this rule belongs to. Exactly one of ActivitySyncRuleSetID and ActivitySyncConnectionID is set (CK_ActivitySyncRule_Owner) — the connection form is the deprecated original and remains only so existing rows stay valid.`),
    ParticipantScope: z.union([z.literal('AllExternal'), z.literal('AllInternal'), z.literal('Any'), z.literal('HasExternal'), z.literal('HasInternal'), z.literal('Mixed')]).nullable().describe(`
        * * Field Name: ParticipantScope
        * * Display Name: Participant Scope
        * * SQL Data Type: nvarchar(30)
    * * Value List Type: List
    * * Possible Values 
    *   * AllExternal
    *   * AllInternal
    *   * Any
    *   * HasExternal
    *   * HasInternal
    *   * Mixed
        * * Description: Which participants must be present for this rule to apply — the internal/external control. AllInternal excludes purely internal chatter; HasExternal catches a thread with any outside party on it; Mixed is the case an all-or-nothing rule gets wrong. Requires the rule set to define InternalDomains. Null means the rule does not test participants.`),
    MaxAttachmentBytes: z.number().nullable().describe(`
        * * Field Name: MaxAttachmentBytes
        * * Display Name: Max Attachment Size (Bytes)
        * * SQL Data Type: bigint`),
    ActivitySyncConnection: z.string().nullable().describe(`
        * * Field Name: ActivitySyncConnection
        * * Display Name: Sync Connection Name
        * * SQL Data Type: nvarchar(200)`),
    ActivityType: z.string().nullable().describe(`
        * * Field Name: ActivityType
        * * Display Name: Activity Type Name
        * * SQL Data Type: nvarchar(100)`),
    ActivitySyncRuleSet: z.string().nullable().describe(`
        * * Field Name: ActivitySyncRuleSet
        * * Display Name: Sync Rule Set Name
        * * SQL Data Type: nvarchar(200)`),
});

export type mjBizAppsCommonActivitySyncRuleEntityType = z.infer<typeof mjBizAppsCommonActivitySyncRuleSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Activity Sync Run Details
 */
export const mjBizAppsCommonActivitySyncRunDetailSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    ActivitySyncRunID: z.string().describe(`
        * * Field Name: ActivitySyncRunID
        * * Display Name: Activity Sync Run
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Runs (vwActivitySyncRuns.ID)`),
    ExternalID: z.string().describe(`
        * * Field Name: ExternalID
        * * Display Name: External ID
        * * SQL Data Type: nvarchar(400)`),
    ExternalThreadID: z.string().nullable().describe(`
        * * Field Name: ExternalThreadID
        * * Display Name: External Thread ID
        * * SQL Data Type: nvarchar(400)`),
    OccurredAt: z.date().nullable().describe(`
        * * Field Name: OccurredAt
        * * Display Name: Occurred At
        * * SQL Data Type: datetimeoffset`),
    Decision: z.union([z.literal('Duplicate'), z.literal('Excluded'), z.literal('Failed'), z.literal('Included'), z.literal('WouldExclude'), z.literal('WouldInclude')]).describe(`
        * * Field Name: Decision
        * * Display Name: Decision
        * * SQL Data Type: nvarchar(20)
    * * Value List Type: List
    * * Possible Values 
    *   * Duplicate
    *   * Excluded
    *   * Failed
    *   * Included
    *   * WouldExclude
    *   * WouldInclude`),
    DecidedByStage: z.string().nullable().describe(`
        * * Field Name: DecidedByStage
        * * Display Name: Decided By Stage
        * * SQL Data Type: nvarchar(100)
        * * Description: Which stage of the qualification cascade decided — a rule set name, KnownParticipant, Inference, or DefaultPolicy. Paired with Reason it explains an outcome without retaining the message that produced it.`),
    ActivitySyncRuleID: z.string().nullable().describe(`
        * * Field Name: ActivitySyncRuleID
        * * Display Name: Activity Sync Rule ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Rules (vwActivitySyncRules.ID)`),
    ActivitySyncExclusionID: z.string().nullable().describe(`
        * * Field Name: ActivitySyncExclusionID
        * * Display Name: Activity Sync Exclusion ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Exclusions (vwActivitySyncExclusions.ID)`),
    Reason: z.string().nullable().describe(`
        * * Field Name: Reason
        * * Display Name: Reason
        * * SQL Data Type: nvarchar(MAX)`),
    Confidence: z.number().nullable().describe(`
        * * Field Name: Confidence
        * * Display Name: Confidence
        * * SQL Data Type: decimal(5, 4)`),
    AIPromptRunID: z.string().nullable().describe(`
        * * Field Name: AIPromptRunID
        * * Display Name: AI Prompt Run ID
        * * SQL Data Type: uniqueidentifier
        * * Description: The MJ: AI Prompt Run behind an inference-stage verdict. Non-null only when a model actually decided this item, which is the audit trail for every automated judgement the engine makes.`),
    ActivityID: z.string().nullable().describe(`
        * * Field Name: ActivityID
        * * Display Name: Activity ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activities (vwActivities.ID)`),
    CapturedContent: z.string().nullable().describe(`
        * * Field Name: CapturedContent
        * * Display Name: Captured Content
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Ciphertext, always — never plaintext, whatever the policy. Present only when the effective SkippedContentPolicy allows retention, and always paired with the EncryptionKeyID that opens it (CK_ActivitySyncRunDetail_ContentKey). Encrypted through MJ's EncryptionEngine against an MJ: Encryption Keys row; this app never implements its own crypto. ROTATING THAT KEY MAKES EXISTING ROWS UNREADABLE: rotation re-encrypts only fields declared with Encrypt = 1, this column is encrypted by calling the engine directly, and the stored value records which key opened it but not which version — so a rotation skips these rows silently and the next read of them fails. Retain content here only for as long as the key behind it will not be rotated, or rotate with a plan for this column. Tracked upstream as MemberJunction/MJ#4580.`),
    EncryptionKeyID: z.string().nullable().describe(`
        * * Field Name: EncryptionKeyID
        * * Display Name: Encryption Key ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ: Encryption Keys (vwEncryptionKeys.ID)`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    ActivitySyncRule: z.string().nullable().describe(`
        * * Field Name: ActivitySyncRule
        * * Display Name: Activity Sync Rule
        * * SQL Data Type: nvarchar(200)`),
    ActivitySyncExclusion: z.string().nullable().describe(`
        * * Field Name: ActivitySyncExclusion
        * * Display Name: Activity Sync Exclusion
        * * SQL Data Type: nvarchar(320)`),
    Activity: z.string().nullable().describe(`
        * * Field Name: Activity
        * * Display Name: Activity
        * * SQL Data Type: nvarchar(500)`),
    EncryptionKey: z.string().nullable().describe(`
        * * Field Name: EncryptionKey
        * * Display Name: Encryption Key
        * * SQL Data Type: nvarchar(100)`),
});

export type mjBizAppsCommonActivitySyncRunDetailEntityType = z.infer<typeof mjBizAppsCommonActivitySyncRunDetailSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Activity Sync Runs
 */
export const mjBizAppsCommonActivitySyncRunSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    ActivitySyncConnectionID: z.string().describe(`
        * * Field Name: ActivitySyncConnectionID
        * * Display Name: Connection ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Connections (vwActivitySyncConnections.ID)`),
    StartedAt: z.date().describe(`
        * * Field Name: StartedAt
        * * Display Name: Started At
        * * SQL Data Type: datetimeoffset
        * * Default Value: sysdatetimeoffset()`),
    EndedAt: z.date().nullable().describe(`
        * * Field Name: EndedAt
        * * Display Name: Ended At
        * * SQL Data Type: datetimeoffset`),
    Status: z.union([z.literal('Cancelled'), z.literal('Completed'), z.literal('Failed'), z.literal('Running')]).describe(`
        * * Field Name: Status
        * * Display Name: Status
        * * SQL Data Type: nvarchar(20)
        * * Default Value: Running
    * * Value List Type: List
    * * Possible Values 
    *   * Cancelled
    *   * Completed
    *   * Failed
    *   * Running`),
    TriggerType: z.union([z.literal('Backfill'), z.literal('Manual'), z.literal('Scheduled'), z.literal('Webhook')]).describe(`
        * * Field Name: TriggerType
        * * Display Name: Trigger Type
        * * SQL Data Type: nvarchar(20)
        * * Default Value: Scheduled
    * * Value List Type: List
    * * Possible Values 
    *   * Backfill
    *   * Manual
    *   * Scheduled
    *   * Webhook`),
    IsDryRun: z.boolean().describe(`
        * * Field Name: IsDryRun
        * * Display Name: Is Dry Run
        * * SQL Data Type: bit
        * * Default Value: 0`),
    Fetched: z.number().describe(`
        * * Field Name: Fetched
        * * Display Name: Fetched Count
        * * SQL Data Type: int
        * * Default Value: 0`),
    Included: z.number().describe(`
        * * Field Name: Included
        * * Display Name: Included Count
        * * SQL Data Type: int
        * * Default Value: 0`),
    Excluded: z.number().describe(`
        * * Field Name: Excluded
        * * Display Name: Excluded Count
        * * SQL Data Type: int
        * * Default Value: 0`),
    Duplicates: z.number().describe(`
        * * Field Name: Duplicates
        * * Display Name: Duplicate Count
        * * SQL Data Type: int
        * * Default Value: 0`),
    Failed: z.number().describe(`
        * * Field Name: Failed
        * * Display Name: Failed Count
        * * SQL Data Type: int
        * * Default Value: 0`),
    ExtensionErrors: z.number().describe(`
        * * Field Name: ExtensionErrors
        * * Display Name: Extension Errors
        * * SQL Data Type: int
        * * Default Value: 0`),
    WatermarkBefore: z.date().nullable().describe(`
        * * Field Name: WatermarkBefore
        * * Display Name: Watermark Before
        * * SQL Data Type: datetimeoffset`),
    WatermarkAfter: z.date().nullable().describe(`
        * * Field Name: WatermarkAfter
        * * Display Name: Watermark After
        * * SQL Data Type: datetimeoffset`),
    ErrorMessage: z.string().nullable().describe(`
        * * Field Name: ErrorMessage
        * * Display Name: Error Message
        * * SQL Data Type: nvarchar(MAX)`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    ActivitySyncConnection: z.string().nullable().describe(`
        * * Field Name: ActivitySyncConnection
        * * Display Name: Connection Name
        * * SQL Data Type: nvarchar(200)`),
});

export type mjBizAppsCommonActivitySyncRunEntityType = z.infer<typeof mjBizAppsCommonActivitySyncRunSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Activity Types
 */
export const mjBizAppsCommonActivityTypeSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Code: z.string().describe(`
        * * Field Name: Code
        * * Display Name: Code
        * * SQL Data Type: nvarchar(50)
        * * Description: Stable key targeted by sync and code (Email, Call, Meeting, Note, SMS, Chat). Unique. Names can be renamed; codes cannot.`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Display name for the picker and timeline.`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Optional longer description of the type.`),
    ParentID: z.string().nullable().describe(`
        * * Field Name: ParentID
        * * Display Name: Parent ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Types (vwActivityTypes.ID)`),
    IconClass: z.string().nullable().describe(`
        * * Field Name: IconClass
        * * Display Name: Icon Class
        * * SQL Data Type: nvarchar(100)
        * * Description: Font Awesome class for timeline chrome (e.g. fa-solid fa-envelope).`),
    Color: z.string().nullable().describe(`
        * * Field Name: Color
        * * Display Name: Color
        * * SQL Data Type: nvarchar(30)
        * * Description: Optional categorical color for timeline chrome. Not a design-token — this is stored per type.`),
    Sequence: z.number().describe(`
        * * Field Name: Sequence
        * * Display Name: Sequence
        * * SQL Data Type: int
        * * Default Value: 0
        * * Description: Picker sort order. Lower first.`),
    IsSystem: z.boolean().describe(`
        * * Field Name: IsSystem
        * * Display Name: Is System
        * * SQL Data Type: bit
        * * Default Value: 0
        * * Description: 1 = seeded system type the sync engine may assume (Email, Call, Meeting, Note, SMS, Chat). Clients add children with IsSystem = 0.`),
    IsActive: z.boolean().describe(`
        * * Field Name: IsActive
        * * Display Name: Is Active
        * * SQL Data Type: bit
        * * Default Value: 1
        * * Description: 0 hides the type from the picker without deleting historical activities.`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    Parent: z.string().nullable().describe(`
        * * Field Name: Parent
        * * Display Name: Parent
        * * SQL Data Type: nvarchar(100)`),
    RootParentID: z.string().nullable().describe(`
        * * Field Name: RootParentID
        * * Display Name: Root Parent ID
        * * SQL Data Type: uniqueidentifier`),
    ParentIDDepth: z.number().nullable().describe(`
        * * Field Name: ParentIDDepth
        * * Display Name: Parent ID Depth
        * * SQL Data Type: int`),
    ParentIDPath: z.string().nullable().describe(`
        * * Field Name: ParentIDPath
        * * Display Name: Parent ID Path
        * * SQL Data Type: nvarchar(MAX)`),
    ParentIDIsLeaf: z.boolean().nullable().describe(`
        * * Field Name: ParentIDIsLeaf
        * * Display Name: Parent ID Is Leaf
        * * SQL Data Type: bit`),
    ParentIDChildCount: z.number().nullable().describe(`
        * * Field Name: ParentIDChildCount
        * * Display Name: Parent ID Child Count
        * * SQL Data Type: int`),
});

export type mjBizAppsCommonActivityTypeEntityType = z.infer<typeof mjBizAppsCommonActivityTypeSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Address Links
 */
export const mjBizAppsCommonAddressLinkSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    AddressID: z.string().describe(`
        * * Field Name: AddressID
        * * Display Name: Address
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Addresses (vwAddresses.ID)`),
    EntityID: z.string().describe(`
        * * Field Name: EntityID
        * * Display Name: Entity
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ: Entities (vwEntities.ID)`),
    RecordID: z.string().describe(`
        * * Field Name: RecordID
        * * Display Name: Record ID
        * * SQL Data Type: nvarchar(700)
        * * Description: Primary key value(s) of the linked record. NVARCHAR(700) to support concatenated composite keys for entities without single-valued primary keys`),
    AddressTypeID: z.string().describe(`
        * * Field Name: AddressTypeID
        * * Display Name: Address Type
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Address Types (vwAddressTypes.ID)`),
    IsPrimary: z.boolean().describe(`
        * * Field Name: IsPrimary
        * * Display Name: Is Primary
        * * SQL Data Type: bit
        * * Default Value: 0
        * * Description: Whether this is the primary address for the linked record. Only one address per entity record should be marked primary`),
    Rank: z.number().nullable().describe(`
        * * Field Name: Rank
        * * Display Name: Rank
        * * SQL Data Type: int
        * * Description: Sort order override for this specific link. When NULL, falls back to AddressType.DefaultRank. Lower values appear first`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    Address: z.string().nullable().describe(`
        * * Field Name: Address
        * * Display Name: Address
        * * SQL Data Type: nvarchar(400)`),
    Entity: z.string().describe(`
        * * Field Name: Entity
        * * Display Name: Entity Name
        * * SQL Data Type: nvarchar(255)`),
    AddressType: z.string().describe(`
        * * Field Name: AddressType
        * * Display Name: Address Type Name
        * * SQL Data Type: nvarchar(100)`),
});

export type mjBizAppsCommonAddressLinkEntityType = z.infer<typeof mjBizAppsCommonAddressLinkSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Address Types
 */
export const mjBizAppsCommonAddressTypeSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Display name for the address type`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Detailed description of this address type`),
    IconClass: z.string().nullable().describe(`
        * * Field Name: IconClass
        * * Display Name: Icon Class
        * * SQL Data Type: nvarchar(100)
        * * Description: Font Awesome icon class for UI display`),
    DefaultRank: z.number().describe(`
        * * Field Name: DefaultRank
        * * Display Name: Default Rank
        * * SQL Data Type: int
        * * Default Value: 100
        * * Description: Default sort order for this address type in dropdown lists. Lower values appear first. Can be overridden per-record via AddressLink.Rank`),
    IsActive: z.boolean().describe(`
        * * Field Name: IsActive
        * * Display Name: Active
        * * SQL Data Type: bit
        * * Default Value: 1
        * * Description: Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
});

export type mjBizAppsCommonAddressTypeEntityType = z.infer<typeof mjBizAppsCommonAddressTypeSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Addresses
 */
export const mjBizAppsCommonAddressSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Line1: z.string().nullable().describe(`
        * * Field Name: Line1
        * * Display Name: Address Line 1
        * * SQL Data Type: nvarchar(255)
        * * Description: Street address line 1. Optional: an address may record only a location (country, region, postal code) before a street line is known.`),
    Line2: z.string().nullable().describe(`
        * * Field Name: Line2
        * * Display Name: Address Line 2
        * * SQL Data Type: nvarchar(255)
        * * Description: Street address line 2 (suite, apt, etc.)`),
    Line3: z.string().nullable().describe(`
        * * Field Name: Line3
        * * Display Name: Address Line 3
        * * SQL Data Type: nvarchar(255)
        * * Description: Street address line 3 (additional detail)`),
    City: z.string().nullable().describe(`
        * * Field Name: City
        * * Display Name: City
        * * SQL Data Type: nvarchar(100)
        * * Description: City or locality name. Optional: an address may record only a location (country, region, postal code) before a city is known.`),
    StateProvince: z.string().nullable().describe(`
        * * Field Name: StateProvince
        * * Display Name: State / Province
        * * SQL Data Type: nvarchar(100)
        * * Description: State, province, or region`),
    PostalCode: z.string().nullable().describe(`
        * * Field Name: PostalCode
        * * Display Name: Postal Code
        * * SQL Data Type: nvarchar(20)
        * * Description: Postal or ZIP code`),
    Country: z.string().describe(`
        * * Field Name: Country
        * * Display Name: Country
        * * SQL Data Type: nvarchar(100)
        * * Default Value: US
        * * Description: Country code or name, defaults to US`),
    Latitude: z.number().nullable().describe(`
        * * Field Name: Latitude
        * * Display Name: Latitude
        * * SQL Data Type: decimal(9, 6)
        * * Description: Geographic latitude for mapping`),
    Longitude: z.number().nullable().describe(`
        * * Field Name: Longitude
        * * Display Name: Longitude
        * * SQL Data Type: decimal(9, 6)
        * * Description: Geographic longitude for mapping`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    DisplayName: z.string().nullable().describe(`
        * * Field Name: DisplayName
        * * Display Name: Display Name
        * * SQL Data Type: nvarchar(400)
        * * Description: One-line label for the address in US order: Line1, City, State PostalCode, Country. Blank parts are skipped; NULL when every part is blank. Computed and stored; this is the entity name field.`),
    __mj_Latitude: z.number().nullable().describe(`
        * * Field Name: __mj_Latitude
        * * Display Name: __mj_Latitude
        * * SQL Data Type: decimal(9, 6)`),
    __mj_Longitude: z.number().nullable().describe(`
        * * Field Name: __mj_Longitude
        * * Display Name: __mj_Longitude
        * * SQL Data Type: decimal(9, 6)`),
});

export type mjBizAppsCommonAddressEntityType = z.infer<typeof mjBizAppsCommonAddressSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Company Sender Identities
 */
export const mjBizAppsCommonCompanySenderIdentitySchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()
        * * Description: Unique identifier for the sender identity.`),
    CompanyID: z.string().describe(`
        * * Field Name: CompanyID
        * * Display Name: Company ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ: Companies (vwCompanies.ID)
        * * Description: The company that owns this sender identity.`),
    Kind: z.union([z.literal('Domain'), z.literal('Mailbox')]).describe(`
        * * Field Name: Kind
        * * Display Name: Identity Kind
        * * SQL Data Type: nvarchar(20)
    * * Value List Type: List
    * * Possible Values 
    *   * Domain
    *   * Mailbox
        * * Description: What Address holds: Mailbox is one full email address, Domain is a bare domain any address on which may be used.`),
    Address: z.string().describe(`
        * * Field Name: Address
        * * Display Name: Address
        * * SQL Data Type: nvarchar(320)
        * * Description: The sender address, stored trimmed and lower-cased by the entity; a full mailbox when Kind = Mailbox, a bare domain when Kind = Domain. Unique per company.`),
    DisplayName: z.string().nullable().describe(`
        * * Field Name: DisplayName
        * * Display Name: Display Name
        * * SQL Data Type: nvarchar(200)
        * * Description: Optional friendly name shown with the address in the From line.`),
    IsDefault: z.boolean().describe(`
        * * Field Name: IsDefault
        * * Display Name: Is Default
        * * SQL Data Type: bit
        * * Default Value: 0
        * * Description: Marks the company's default sender: at most one per company (UQ_CompanySenderIdentity_Default); only a Mailbox row is a usable default.`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    Company: z.string().nullable().describe(`
        * * Field Name: Company
        * * Display Name: Company Name
        * * SQL Data Type: nvarchar(50)`),
});

export type mjBizAppsCommonCompanySenderIdentityEntityType = z.infer<typeof mjBizAppsCommonCompanySenderIdentitySchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Consent Purposes
 */
export const mjBizAppsCommonConsentPurposeSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Display name of the purpose, unique within the installation.`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: What kinds of messages this purpose covers.`),
    Sequence: z.number().describe(`
        * * Field Name: Sequence
        * * Display Name: Sequence
        * * SQL Data Type: int
        * * Default Value: 0
        * * Description: Sort order in dropdown lists. Lower values appear first.`),
    IsActive: z.boolean().describe(`
        * * Field Name: IsActive
        * * Display Name: Is Active
        * * SQL Data Type: bit
        * * Default Value: 1
        * * Description: Whether this purpose is offered for new consents. Inactive purposes are hidden from dropdowns but preserved for existing records.`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
});

export type mjBizAppsCommonConsentPurposeEntityType = z.infer<typeof mjBizAppsCommonConsentPurposeSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Contact Method Consent Histories
 */
export const mjBizAppsCommonContactMethodConsentHistorySchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    ContactMethodConsentID: z.string().describe(`
        * * Field Name: ContactMethodConsentID
        * * Display Name: Contact Method Consent
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Contact Method Consents (vwContactMethodConsents.ID)`),
    NewConsentStatus: z.union([z.literal('Not Specified'), z.literal('Opted In'), z.literal('Opted Out')]).describe(`
        * * Field Name: NewConsentStatus
        * * Display Name: New Consent Status
        * * SQL Data Type: nvarchar(20)
    * * Value List Type: List
    * * Possible Values 
    *   * Not Specified
    *   * Opted In
    *   * Opted Out
        * * Description: The consent status this change set: Not Specified, Opted In or Opted Out.`),
    ConsentStatusAt: z.date().describe(`
        * * Field Name: ConsentStatusAt
        * * Display Name: Consent Status At
        * * SQL Data Type: datetimeoffset
        * * Description: When the change took effect in the real world (the unsubscribe click, the form submission, the import's own date), not when this row was saved. The row with the latest value is the current status.`),
    ConsentSource: z.union([z.literal('Import'), z.literal('Other'), z.literal('Staff'), z.literal('Unsubscribe Link'), z.literal('Web Form')]).describe(`
        * * Field Name: ConsentSource
        * * Display Name: Consent Source
        * * SQL Data Type: nvarchar(50)
        * * Default Value: Staff
    * * Value List Type: List
    * * Possible Values 
    *   * Import
    *   * Other
    *   * Staff
    *   * Unsubscribe Link
    *   * Web Form
        * * Description: Where the change came from: Web Form, Unsubscribe Link, Import, Staff or Other. Defaults to Staff, for a change made by a person in the app. The specifics, such as which system an import came from or what Other was, go in ConsentDetails.`),
    RecordedByUserID: z.string().nullable().describe(`
        * * Field Name: RecordedByUserID
        * * Display Name: Recorded By User ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ: Users (vwUsers.ID)`),
    ConsentDetails: z.string().nullable().describe(`
        * * Field Name: ConsentDetails
        * * Display Name: Consent Details
        * * SQL Data Type: nvarchar(MAX)
        * * Description: The specifics of the change: which system an import came from, what an Other source was, or evidence such as a form ID or the unsubscribe email's message ID.`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    RecordedByUser: z.string().nullable().describe(`
        * * Field Name: RecordedByUser
        * * Display Name: Recorded By User
        * * SQL Data Type: nvarchar(100)`),
});

export type mjBizAppsCommonContactMethodConsentHistoryEntityType = z.infer<typeof mjBizAppsCommonContactMethodConsentHistorySchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Contact Method Consents
 */
export const mjBizAppsCommonContactMethodConsentSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    ContactMethodID: z.string().describe(`
        * * Field Name: ContactMethodID
        * * Display Name: Contact Method
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Contact Methods (vwContactMethods.ID)`),
    ConsentPurposeID: z.string().nullable().describe(`
        * * Field Name: ConsentPurposeID
        * * Display Name: Consent Purpose ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Consent Purposes (vwConsentPurposes.ID)`),
    RequestingOrganizationID: z.string().nullable().describe(`
        * * Field Name: RequestingOrganizationID
        * * Display Name: Requesting Organization ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Organizations (vwOrganizations.ID)
        * * Description: The organization that asked for this consent, when the person answered differently for different organizations. Null means the answer applies to anyone on the installation. This is not the owner of the contact method; that is ContactMethod.PersonID or ContactMethod.OrganizationID.`),
    ConsentStatus: z.union([z.literal('Not Specified'), z.literal('Opted In'), z.literal('Opted Out')]).describe(`
        * * Field Name: ConsentStatus
        * * Display Name: Consent Status
        * * SQL Data Type: nvarchar(20)
        * * Default Value: Not Specified
    * * Value List Type: List
    * * Possible Values 
    *   * Not Specified
    *   * Opted In
    *   * Opted Out
        * * Description: The current consent: Not Specified, Opted In or Opted Out.`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    ContactMethod: z.string().nullable().describe(`
        * * Field Name: ContactMethod
        * * Display Name: Contact Method Details
        * * SQL Data Type: nvarchar(500)`),
    ConsentPurpose: z.string().nullable().describe(`
        * * Field Name: ConsentPurpose
        * * Display Name: Consent Purpose
        * * SQL Data Type: nvarchar(100)`),
    RequestingOrganization: z.string().nullable().describe(`
        * * Field Name: RequestingOrganization
        * * Display Name: Requesting Organization
        * * SQL Data Type: nvarchar(255)`),
});

export type mjBizAppsCommonContactMethodConsentEntityType = z.infer<typeof mjBizAppsCommonContactMethodConsentSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Contact Methods
 */
export const mjBizAppsCommonContactMethodSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    PersonID: z.string().nullable().describe(`
        * * Field Name: PersonID
        * * Display Name: Person
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: People (vwPeople.ID)`),
    OrganizationID: z.string().nullable().describe(`
        * * Field Name: OrganizationID
        * * Display Name: Organization
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Organizations (vwOrganizations.ID)`),
    ContactTypeID: z.string().describe(`
        * * Field Name: ContactTypeID
        * * Display Name: Contact Type
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Contact Types (vwContactTypes.ID)`),
    Value: z.string().describe(`
        * * Field Name: Value
        * * Display Name: Contact Value
        * * SQL Data Type: nvarchar(500)
        * * Description: The contact value: phone number, email address, URL, social media handle, etc.`),
    Label: z.string().nullable().describe(`
        * * Field Name: Label
        * * Display Name: Label
        * * SQL Data Type: nvarchar(100)
        * * Description: Descriptive label such as Work cell, Personal Gmail, Corporate LinkedIn`),
    IsPrimary: z.boolean().describe(`
        * * Field Name: IsPrimary
        * * Display Name: Is Primary
        * * SQL Data Type: bit
        * * Default Value: 0
        * * Description: Whether this is the primary contact method of its type for the linked person or organization`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    Person: z.string().nullable().describe(`
        * * Field Name: Person
        * * Display Name: Person
        * * SQL Data Type: nvarchar(250)`),
    Organization: z.string().nullable().describe(`
        * * Field Name: Organization
        * * Display Name: Organization Name
        * * SQL Data Type: nvarchar(255)`),
    ContactType: z.string().describe(`
        * * Field Name: ContactType
        * * Display Name: Contact Type Name
        * * SQL Data Type: nvarchar(100)`),
});

export type mjBizAppsCommonContactMethodEntityType = z.infer<typeof mjBizAppsCommonContactMethodSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Contact Types
 */
export const mjBizAppsCommonContactTypeSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Display name for the contact type`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Detailed description of this contact type`),
    IconClass: z.string().nullable().describe(`
        * * Field Name: IconClass
        * * Display Name: Icon Class
        * * SQL Data Type: nvarchar(100)
        * * Description: Font Awesome icon class for UI display`),
    DisplayRank: z.number().describe(`
        * * Field Name: DisplayRank
        * * Display Name: Display Rank
        * * SQL Data Type: int
        * * Default Value: 100
        * * Description: Sort order in dropdown lists. Lower values appear first`),
    IsActive: z.boolean().describe(`
        * * Field Name: IsActive
        * * Display Name: Is Active
        * * SQL Data Type: bit
        * * Default Value: 1
        * * Description: Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    CommunicationBaseMessageTypeID: z.string().nullable().describe(`
        * * Field Name: CommunicationBaseMessageTypeID
        * * Display Name: Communication Base Message Type
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ: Communication Base Message Types (vwCommunicationBaseMessageTypes.ID)`),
    CommunicationBaseMessageType: z.string().nullable().describe(`
        * * Field Name: CommunicationBaseMessageType
        * * Display Name: Communication Base Message Type
        * * SQL Data Type: nvarchar(100)`),
});

export type mjBizAppsCommonContactTypeEntityType = z.infer<typeof mjBizAppsCommonContactTypeSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Job Functions
 */
export const mjBizAppsCommonJobFunctionSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Unique display name of the job function.`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Detailed description of the job function and the roles it encompasses.`),
    Sequence: z.number().describe(`
        * * Field Name: Sequence
        * * Display Name: Sequence
        * * SQL Data Type: int
        * * Default Value: 0
        * * Description: Display sort sequence order.`),
    Status: z.union([z.literal('Active'), z.literal('Disabled')]).describe(`
        * * Field Name: Status
        * * Display Name: Status
        * * SQL Data Type: nvarchar(20)
        * * Default Value: Active
    * * Value List Type: List
    * * Possible Values 
    *   * Active
    *   * Disabled
        * * Description: Lifecycle status (Active, Inactive) of the job function.`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
});

export type mjBizAppsCommonJobFunctionEntityType = z.infer<typeof mjBizAppsCommonJobFunctionSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Organization Types
 */
export const mjBizAppsCommonOrganizationTypeSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Display name for the organization type`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Detailed description of this organization type`),
    IconClass: z.string().nullable().describe(`
        * * Field Name: IconClass
        * * Display Name: Icon Class
        * * SQL Data Type: nvarchar(100)
        * * Description: Font Awesome icon class for UI display`),
    DisplayRank: z.number().describe(`
        * * Field Name: DisplayRank
        * * Display Name: Display Rank
        * * SQL Data Type: int
        * * Default Value: 100
        * * Description: Sort order in dropdown lists. Lower values appear first`),
    IsActive: z.boolean().describe(`
        * * Field Name: IsActive
        * * Display Name: Active
        * * SQL Data Type: bit
        * * Default Value: 1
        * * Description: Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
});

export type mjBizAppsCommonOrganizationTypeEntityType = z.infer<typeof mjBizAppsCommonOrganizationTypeSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Organizations
 */
export const mjBizAppsCommonOrganizationSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(255)
        * * Description: Common or display name of the organization`),
    LegalName: z.string().nullable().describe(`
        * * Field Name: LegalName
        * * Display Name: Legal Name
        * * SQL Data Type: nvarchar(255)
        * * Description: Full legal name if different from display name`),
    OrganizationTypeID: z.string().nullable().describe(`
        * * Field Name: OrganizationTypeID
        * * Display Name: Organization Type
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Organization Types (vwOrganizationTypes.ID)`),
    ParentID: z.string().nullable().describe(`
        * * Field Name: ParentID
        * * Display Name: Parent Organization
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Organizations (vwOrganizations.ID)`),
    Website: z.string().nullable().describe(`
        * * Field Name: Website
        * * Display Name: Website
        * * SQL Data Type: nvarchar(1000)
        * * Description: Primary website URL`),
    LogoURL: z.string().nullable().describe(`
        * * Field Name: LogoURL
        * * Display Name: Logo URL
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Organization logo. May be an HTTP(S) URL or an inline data URI (NVARCHAR(MAX)).`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Description of the organization purpose and scope`),
    Email: z.string().nullable().describe(`
        * * Field Name: Email
        * * Display Name: Email
        * * SQL Data Type: nvarchar(255)
        * * Description: Primary contact email address`),
    Phone: z.string().nullable().describe(`
        * * Field Name: Phone
        * * Display Name: Phone
        * * SQL Data Type: nvarchar(50)
        * * Description: Primary phone number`),
    FoundedDate: z.date().nullable().describe(`
        * * Field Name: FoundedDate
        * * Display Name: Founded Date
        * * SQL Data Type: date
        * * Description: Date the organization was founded or incorporated`),
    TaxID: z.string().nullable().describe(`
        * * Field Name: TaxID
        * * Display Name: Tax ID
        * * SQL Data Type: nvarchar(50)
        * * Description: Tax identification number such as EIN`),
    Status: z.union([z.literal('Active'), z.literal('Dissolved'), z.literal('Inactive')]).describe(`
        * * Field Name: Status
        * * Display Name: Status
        * * SQL Data Type: nvarchar(50)
        * * Default Value: Active
    * * Value List Type: List
    * * Possible Values 
    *   * Active
    *   * Dissolved
    *   * Inactive
        * * Description: Current status: Active, Inactive, or Dissolved`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    WebsiteDomain: z.string().nullable().describe(`
        * * Field Name: WebsiteDomain
        * * Display Name: Website Domain
        * * SQL Data Type: nvarchar(255)
        * * Description: Lower-cased host of Website, without the http(s):// scheme, a leading www. or any path. NULL when Website is empty. Computed and stored, indexed for prefix search by domain.`),
    Acronym: z.string().nullable().describe(`
        * * Field Name: Acronym
        * * Display Name: Acronym
        * * SQL Data Type: nvarchar(20)
        * * Description: Short name or initials the organization is commonly known by. Searched by the organization pickers as a starts-with match and shown under the name.`),
    LinkedCompanyID: z.string().nullable().describe(`
        * * Field Name: LinkedCompanyID
        * * Display Name: Linked Company
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ: Companies (vwCompanies.ID)
        * * Description: Optional 1:1 foreign key to the MJ: Companies record mirrored by this Organization (enforced unique when non-null via UQ_Organization_LinkedCompanyID). Enables internal legal entities and external client/partner organizations to share Organization as the single canonical entity across BizApps.`),
    OrganizationType: z.string().nullable().describe(`
        * * Field Name: OrganizationType
        * * Display Name: Organization Type Name
        * * SQL Data Type: nvarchar(100)`),
    Parent: z.string().nullable().describe(`
        * * Field Name: Parent
        * * Display Name: Parent Name
        * * SQL Data Type: nvarchar(255)`),
    LinkedCompany: z.string().nullable().describe(`
        * * Field Name: LinkedCompany
        * * Display Name: Linked Company Name
        * * SQL Data Type: nvarchar(50)`),
    RootParentID: z.string().nullable().describe(`
        * * Field Name: RootParentID
        * * Display Name: Root Parent
        * * SQL Data Type: uniqueidentifier`),
    ParentIDDepth: z.number().nullable().describe(`
        * * Field Name: ParentIDDepth
        * * Display Name: Hierarchy Depth
        * * SQL Data Type: int`),
    ParentIDPath: z.string().nullable().describe(`
        * * Field Name: ParentIDPath
        * * Display Name: Hierarchy Path
        * * SQL Data Type: nvarchar(MAX)`),
    ParentIDIsLeaf: z.boolean().nullable().describe(`
        * * Field Name: ParentIDIsLeaf
        * * Display Name: Is Leaf Node
        * * SQL Data Type: bit`),
    ParentIDChildCount: z.number().nullable().describe(`
        * * Field Name: ParentIDChildCount
        * * Display Name: Child Count
        * * SQL Data Type: int`),
    PrimaryAddressLine1: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressLine1
        * * Display Name: Address Line 1
        * * SQL Data Type: nvarchar(255)`),
    PrimaryAddressLine2: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressLine2
        * * Display Name: Address Line 2
        * * SQL Data Type: nvarchar(255)`),
    PrimaryAddressCity: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressCity
        * * Display Name: City
        * * SQL Data Type: nvarchar(100)`),
    PrimaryAddressState: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressState
        * * Display Name: State/Province
        * * SQL Data Type: nvarchar(100)`),
    PrimaryAddressPostalCode: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressPostalCode
        * * Display Name: Postal Code
        * * SQL Data Type: nvarchar(20)`),
    PrimaryAddressCountry: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressCountry
        * * Display Name: Country
        * * SQL Data Type: nvarchar(100)`),
    PrimaryAddressLatitude: z.number().nullable().describe(`
        * * Field Name: PrimaryAddressLatitude
        * * Display Name: Primary Address Latitude
        * * SQL Data Type: decimal(9, 6)`),
    PrimaryAddressLongitude: z.number().nullable().describe(`
        * * Field Name: PrimaryAddressLongitude
        * * Display Name: Primary Address Longitude
        * * SQL Data Type: decimal(9, 6)`),
    PrimaryAddressType: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressType
        * * Display Name: Address Type
        * * SQL Data Type: nvarchar(100)`),
    PrimaryEmail: z.string().nullable().describe(`
        * * Field Name: PrimaryEmail
        * * Display Name: Primary Email
        * * SQL Data Type: nvarchar(500)`),
    PrimaryPhone: z.string().nullable().describe(`
        * * Field Name: PrimaryPhone
        * * Display Name: Primary Phone
        * * SQL Data Type: nvarchar(500)`),
    ActivePersonCount: z.number().nullable().describe(`
        * * Field Name: ActivePersonCount
        * * Display Name: Active Staff Count
        * * SQL Data Type: int`),
    ChildOrgCount: z.number().nullable().describe(`
        * * Field Name: ChildOrgCount
        * * Display Name: Total Child Organizations
        * * SQL Data Type: int`),
});

export type mjBizAppsCommonOrganizationEntityType = z.infer<typeof mjBizAppsCommonOrganizationSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: People
 */
export const mjBizAppsCommonPersonSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    FirstName: z.string().describe(`
        * * Field Name: FirstName
        * * Display Name: First Name
        * * SQL Data Type: nvarchar(100)
        * * Description: First (given) name`),
    LastName: z.string().describe(`
        * * Field Name: LastName
        * * Display Name: Last Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Last (family) name`),
    MiddleName: z.string().nullable().describe(`
        * * Field Name: MiddleName
        * * Display Name: Middle Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Middle name or initial`),
    Prefix: z.string().nullable().describe(`
        * * Field Name: Prefix
        * * Display Name: Prefix
        * * SQL Data Type: nvarchar(20)
        * * Description: Name prefix such as Dr., Mr., Ms., Rev.`),
    Suffix: z.string().nullable().describe(`
        * * Field Name: Suffix
        * * Display Name: Suffix
        * * SQL Data Type: nvarchar(20)
        * * Description: Name suffix such as Jr., III, PhD, Esq.`),
    PreferredName: z.string().nullable().describe(`
        * * Field Name: PreferredName
        * * Display Name: Preferred Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Nickname or preferred name the person goes by`),
    Title: z.string().nullable().describe(`
        * * Field Name: Title
        * * Display Name: Title
        * * SQL Data Type: nvarchar(200)
        * * Description: Professional or job title, e.g. VP of Engineering, Board Director`),
    Email: z.string().nullable().describe(`
        * * Field Name: Email
        * * Display Name: Email
        * * SQL Data Type: nvarchar(255)
        * * Description: Primary email address for this person`),
    Phone: z.string().nullable().describe(`
        * * Field Name: Phone
        * * Display Name: Phone
        * * SQL Data Type: nvarchar(50)
        * * Description: Primary phone number for this person`),
    DateOfBirth: z.date().nullable().describe(`
        * * Field Name: DateOfBirth
        * * Display Name: Date of Birth
        * * SQL Data Type: date
        * * Description: Date of birth`),
    Gender: z.string().nullable().describe(`
        * * Field Name: Gender
        * * Display Name: Gender
        * * SQL Data Type: nvarchar(50)
        * * Description: Gender identity`),
    PhotoURL: z.string().nullable().describe(`
        * * Field Name: PhotoURL
        * * Display Name: Photo URL
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Profile photo or avatar. May be an HTTP(S) URL or an inline data URI (NVARCHAR(MAX)).`),
    Bio: z.string().nullable().describe(`
        * * Field Name: Bio
        * * Display Name: Bio
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Biographical text or notes about this person`),
    LinkedUserID: z.string().nullable().describe(`
        * * Field Name: LinkedUserID
        * * Display Name: Linked User ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ: Users (vwUsers.ID)
        * * Description: Optional foreign key to the MemberJunction core User record (__mj.User) when this person is also an authenticated platform user. Enforced 1:1 via UQ_Person_LinkedUserID where not null. Saving a Person never auto-provisions or modifies MJ Users.`),
    Status: z.union([z.literal('Active'), z.literal('Deceased'), z.literal('Inactive')]).describe(`
        * * Field Name: Status
        * * Display Name: Status
        * * SQL Data Type: nvarchar(50)
        * * Default Value: Active
    * * Value List Type: List
    * * Possible Values 
    *   * Active
    *   * Deceased
    *   * Inactive
        * * Description: Current status: Active, Inactive, or Deceased`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    SeniorityLevelID: z.string().nullable().describe(`
        * * Field Name: SeniorityLevelID
        * * Display Name: Seniority Level
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Seniority Levels (vwSeniorityLevels.ID)
        * * Description: Current primary seniority level for this person.`),
    DisplayName: z.string().describe(`
        * * Field Name: DisplayName
        * * Display Name: Display Name
        * * SQL Data Type: nvarchar(250)
        * * Description: Full name for display: FirstName LastName Suffix ("John Smith Jr."). Blank parts are skipped; empty when every part is blank. Computed and stored; this is the entity name field.`),
    EmailDomain: z.string().nullable().describe(`
        * * Field Name: EmailDomain
        * * Display Name: Email Domain
        * * SQL Data Type: nvarchar(255)
        * * Description: Lower-cased domain of Email: the text after the first @. NULL when Email is empty, has no @, or has nothing after it. Computed and stored, indexed for prefix search by domain.`),
    LinkedUser: z.string().nullable().describe(`
        * * Field Name: LinkedUser
        * * Display Name: Linked User
        * * SQL Data Type: nvarchar(100)`),
    SeniorityLevel: z.string().nullable().describe(`
        * * Field Name: SeniorityLevel
        * * Display Name: Seniority Level
        * * SQL Data Type: nvarchar(100)`),
    PrimaryAddressLine1: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressLine1
        * * Display Name: Primary Address Line 1
        * * SQL Data Type: nvarchar(255)`),
    PrimaryAddressLine2: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressLine2
        * * Display Name: Primary Address Line 2
        * * SQL Data Type: nvarchar(255)`),
    PrimaryAddressCity: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressCity
        * * Display Name: Primary Address City
        * * SQL Data Type: nvarchar(100)`),
    PrimaryAddressState: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressState
        * * Display Name: Primary Address State
        * * SQL Data Type: nvarchar(100)`),
    PrimaryAddressPostalCode: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressPostalCode
        * * Display Name: Primary Address Postal Code
        * * SQL Data Type: nvarchar(20)`),
    PrimaryAddressCountry: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressCountry
        * * Display Name: Primary Address Country
        * * SQL Data Type: nvarchar(100)`),
    PrimaryAddressLatitude: z.number().nullable().describe(`
        * * Field Name: PrimaryAddressLatitude
        * * Display Name: Primary Address Latitude
        * * SQL Data Type: decimal(9, 6)`),
    PrimaryAddressLongitude: z.number().nullable().describe(`
        * * Field Name: PrimaryAddressLongitude
        * * Display Name: Primary Address Longitude
        * * SQL Data Type: decimal(9, 6)`),
    PrimaryAddressType: z.string().nullable().describe(`
        * * Field Name: PrimaryAddressType
        * * Display Name: Primary Address Type
        * * SQL Data Type: nvarchar(100)`),
    PrimaryEmail: z.string().nullable().describe(`
        * * Field Name: PrimaryEmail
        * * Display Name: Primary Email
        * * SQL Data Type: nvarchar(500)`),
    PrimaryPhone: z.string().nullable().describe(`
        * * Field Name: PrimaryPhone
        * * Display Name: Primary Phone
        * * SQL Data Type: nvarchar(500)`),
    CurrentOrganizationID: z.string().nullable().describe(`
        * * Field Name: CurrentOrganizationID
        * * Display Name: Current Organization ID
        * * SQL Data Type: uniqueidentifier`),
    CurrentOrganizationName: z.string().nullable().describe(`
        * * Field Name: CurrentOrganizationName
        * * Display Name: Current Organization Name
        * * SQL Data Type: nvarchar(255)`),
    CurrentJobTitle: z.string().nullable().describe(`
        * * Field Name: CurrentJobTitle
        * * Display Name: Current Job Title
        * * SQL Data Type: nvarchar(255)`),
    PrimaryJobFunctionID: z.string().nullable().describe(`
        * * Field Name: PrimaryJobFunctionID
        * * Display Name: Primary Job Function
        * * SQL Data Type: uniqueidentifier`),
    PrimaryJobFunction: z.string().nullable().describe(`
        * * Field Name: PrimaryJobFunction
        * * Display Name: Primary Job Function Name
        * * SQL Data Type: nvarchar(100)`),
});

export type mjBizAppsCommonPersonEntityType = z.infer<typeof mjBizAppsCommonPersonSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Person Job Functions
 */
export const mjBizAppsCommonPersonJobFunctionSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    PersonID: z.string().describe(`
        * * Field Name: PersonID
        * * Display Name: Person
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: People (vwPeople.ID)`),
    JobFunctionID: z.string().describe(`
        * * Field Name: JobFunctionID
        * * Display Name: Job Function
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Job Functions (vwJobFunctions.ID)`),
    Sequence: z.number().describe(`
        * * Field Name: Sequence
        * * Display Name: Sequence
        * * SQL Data Type: int
        * * Default Value: 0
        * * Description: Rank order sequence for a person with multiple job functions (Sequence 1 = primary).`),
    Source: z.union([z.literal('Derived'), z.literal('Manual')]).describe(`
        * * Field Name: Source
        * * Display Name: Source
        * * SQL Data Type: nvarchar(20)
        * * Default Value: Manual
    * * Value List Type: List
    * * Possible Values 
    *   * Derived
    *   * Manual
        * * Description: Provenance of this function assignment (Manual by user, or Derived by automated pipeline).`),
    Confidence: z.number().nullable().describe(`
        * * Field Name: Confidence
        * * Display Name: Confidence
        * * SQL Data Type: decimal(5, 4)
        * * Description: Confidence score between 0.0 and 1.0 when derived by an AI feature pipeline.`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    Person: z.string().nullable().describe(`
        * * Field Name: Person
        * * Display Name: Person Name
        * * SQL Data Type: nvarchar(250)`),
    JobFunction: z.string().nullable().describe(`
        * * Field Name: JobFunction
        * * Display Name: Job Function Name
        * * SQL Data Type: nvarchar(100)`),
});

export type mjBizAppsCommonPersonJobFunctionEntityType = z.infer<typeof mjBizAppsCommonPersonJobFunctionSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Relationship Types
 */
export const mjBizAppsCommonRelationshipTypeSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Display name for the relationship type, e.g. Employee, Spouse, Partner`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Detailed description of this relationship type`),
    Category: z.union([z.literal('OrganizationToOrganization'), z.literal('PersonToOrganization'), z.literal('PersonToPerson')]).describe(`
        * * Field Name: Category
        * * Display Name: Category
        * * SQL Data Type: nvarchar(50)
    * * Value List Type: List
    * * Possible Values 
    *   * OrganizationToOrganization
    *   * PersonToOrganization
    *   * PersonToPerson
        * * Description: Which entity types this relationship connects: PersonToPerson, PersonToOrganization, or OrganizationToOrganization`),
    IsDirectional: z.boolean().describe(`
        * * Field Name: IsDirectional
        * * Display Name: Is Directional
        * * SQL Data Type: bit
        * * Default Value: 1
        * * Description: Whether the relationship has a direction. False for symmetric relationships like Spouse or Partner`),
    ForwardLabel: z.string().nullable().describe(`
        * * Field Name: ForwardLabel
        * * Display Name: Forward Label
        * * SQL Data Type: nvarchar(100)
        * * Description: Label describing the From-to-To direction, e.g. is employee of, is parent of`),
    ReverseLabel: z.string().nullable().describe(`
        * * Field Name: ReverseLabel
        * * Display Name: Reverse Label
        * * SQL Data Type: nvarchar(100)
        * * Description: Label describing the To-to-From direction, e.g. employs, is child of`),
    IsActive: z.boolean().describe(`
        * * Field Name: IsActive
        * * Display Name: Active
        * * SQL Data Type: bit
        * * Default Value: 1
        * * Description: Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
});

export type mjBizAppsCommonRelationshipTypeEntityType = z.infer<typeof mjBizAppsCommonRelationshipTypeSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Relationships
 */
export const mjBizAppsCommonRelationshipSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    RelationshipTypeID: z.string().describe(`
        * * Field Name: RelationshipTypeID
        * * Display Name: Relationship Type ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Relationship Types (vwRelationshipTypes.ID)`),
    FromPersonID: z.string().nullable().describe(`
        * * Field Name: FromPersonID
        * * Display Name: From Person
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: People (vwPeople.ID)`),
    FromOrganizationID: z.string().nullable().describe(`
        * * Field Name: FromOrganizationID
        * * Display Name: From Organization
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Organizations (vwOrganizations.ID)`),
    ToPersonID: z.string().nullable().describe(`
        * * Field Name: ToPersonID
        * * Display Name: To Person
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: People (vwPeople.ID)`),
    ToOrganizationID: z.string().nullable().describe(`
        * * Field Name: ToOrganizationID
        * * Display Name: To Organization
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Organizations (vwOrganizations.ID)`),
    Title: z.string().nullable().describe(`
        * * Field Name: Title
        * * Display Name: Title
        * * SQL Data Type: nvarchar(255)
        * * Description: Contextual title for this specific relationship, e.g. CEO, Primary Contact, Founding Member`),
    StartDate: z.date().nullable().describe(`
        * * Field Name: StartDate
        * * Display Name: Start Date
        * * SQL Data Type: date
        * * Description: Date the relationship began`),
    EndDate: z.date().nullable().describe(`
        * * Field Name: EndDate
        * * Display Name: End Date
        * * SQL Data Type: date
        * * Description: Date the relationship ended, if applicable`),
    Status: z.union([z.literal('Active'), z.literal('Ended'), z.literal('Inactive')]).describe(`
        * * Field Name: Status
        * * Display Name: Status
        * * SQL Data Type: nvarchar(50)
        * * Default Value: Active
    * * Value List Type: List
    * * Possible Values 
    *   * Active
    *   * Ended
    *   * Inactive
        * * Description: Current status: Active, Inactive, or Ended`),
    Notes: z.string().nullable().describe(`
        * * Field Name: Notes
        * * Display Name: Notes
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Additional notes about this relationship`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    JobFunctionID: z.string().nullable().describe(`
        * * Field Name: JobFunctionID
        * * Display Name: Job Function
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Job Functions (vwJobFunctions.ID)
        * * Description: Company-specific job function for this relationship/employment link.`),
    SeniorityLevelID: z.string().nullable().describe(`
        * * Field Name: SeniorityLevelID
        * * Display Name: Seniority Level
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Seniority Levels (vwSeniorityLevels.ID)
        * * Description: Company-specific seniority level for this relationship/employment link.`),
    RelationshipType: z.string().nullable().describe(`
        * * Field Name: RelationshipType
        * * Display Name: Relationship Type
        * * SQL Data Type: nvarchar(100)`),
    FromPerson: z.string().nullable().describe(`
        * * Field Name: FromPerson
        * * Display Name: From Person
        * * SQL Data Type: nvarchar(250)`),
    FromOrganization: z.string().nullable().describe(`
        * * Field Name: FromOrganization
        * * Display Name: From Organization Name
        * * SQL Data Type: nvarchar(255)`),
    ToPerson: z.string().nullable().describe(`
        * * Field Name: ToPerson
        * * Display Name: To Person
        * * SQL Data Type: nvarchar(250)`),
    ToOrganization: z.string().nullable().describe(`
        * * Field Name: ToOrganization
        * * Display Name: To Organization Name
        * * SQL Data Type: nvarchar(255)`),
    JobFunction: z.string().nullable().describe(`
        * * Field Name: JobFunction
        * * Display Name: Job Function Name
        * * SQL Data Type: nvarchar(100)`),
    SeniorityLevel: z.string().nullable().describe(`
        * * Field Name: SeniorityLevel
        * * Display Name: Seniority Level Name
        * * SQL Data Type: nvarchar(100)`),
    DisplayName: z.string().nullable().describe(`
        * * Field Name: DisplayName
        * * Display Name: Display Name
        * * SQL Data Type: nvarchar(1000)`),
});

export type mjBizAppsCommonRelationshipEntityType = z.infer<typeof mjBizAppsCommonRelationshipSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Seniority Levels
 */
export const mjBizAppsCommonSeniorityLevelSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Unique display name of the seniority level.`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Detailed description of the seniority level and role expectations.`),
    Sequence: z.number().describe(`
        * * Field Name: Sequence
        * * Display Name: Sequence
        * * SQL Data Type: int
        * * Default Value: 0
        * * Description: Rank order sequence from entry-level/IC to executive/C-level.`),
    Status: z.union([z.literal('Active'), z.literal('Disabled')]).describe(`
        * * Field Name: Status
        * * Display Name: Status
        * * SQL Data Type: nvarchar(20)
        * * Default Value: Active
    * * Value List Type: List
    * * Possible Values 
    *   * Active
    *   * Disabled
        * * Description: Lifecycle status (Active, Inactive) of the seniority level.`),
    __mj_CreatedAt: z.date().describe(`
        * * Field Name: __mj_CreatedAt
        * * Display Name: Created At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
    __mj_UpdatedAt: z.date().describe(`
        * * Field Name: __mj_UpdatedAt
        * * Display Name: Updated At
        * * SQL Data Type: datetimeoffset
        * * Default Value: getutcdate()`),
});

export type mjBizAppsCommonSeniorityLevelEntityType = z.infer<typeof mjBizAppsCommonSeniorityLevelSchema>;
