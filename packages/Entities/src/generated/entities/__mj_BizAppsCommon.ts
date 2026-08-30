import { BaseEntity, EntitySaveOptions, EntityDeleteOptions, CompositeKey, ValidationResult, ValidationErrorInfo, ValidationErrorType, Metadata, ProviderType, DatabaseProviderBase, RunView } from "@memberjunction/core";
import { RegisterClass } from "@memberjunction/global";
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
    ActivityType: z.string().describe(`
        * * Field Name: ActivityType
        * * Display Name: Activity Type Name
        * * SQL Data Type: nvarchar(100)`),
    ParentActivity: z.string().nullable().describe(`
        * * Field Name: ParentActivity
        * * Display Name: Parent Activity
        * * SQL Data Type: nvarchar(500)`),
    LoggedByUser: z.string().describe(`
        * * Field Name: LoggedByUser
        * * Display Name: Logged By
        * * SQL Data Type: nvarchar(100)`),
    Address: z.string().nullable().describe(`
        * * Field Name: Address
        * * Display Name: Address Details
        * * SQL Data Type: nvarchar(255)`),
    ActivitySyncConnection: z.string().nullable().describe(`
        * * Field Name: ActivitySyncConnection
        * * Display Name: Sync Connection Name
        * * SQL Data Type: nvarchar(200)`),
    __mj_Latitude: z.number().nullable().describe(`
        * * Field Name: __mj_Latitude
        * * Display Name: Mj Latitude
        * * SQL Data Type: decimal(10, 6)`),
    __mj_Longitude: z.number().nullable().describe(`
        * * Field Name: __mj_Longitude
        * * Display Name: Mj Longitude
        * * SQL Data Type: decimal(10, 6)`),
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
    Activity: z.string().describe(`
        * * Field Name: Activity
        * * Display Name: Activity
        * * SQL Data Type: nvarchar(500)`),
    File: z.string().describe(`
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
    Activity: z.string().describe(`
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
    OwnerUser: z.string().describe(`
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
        * * SQL Data Type: datetimeoffset`),
    EffectiveTo: z.date().nullable().describe(`
        * * Field Name: EffectiveTo
        * * Display Name: Effective To
        * * SQL Data Type: datetimeoffset`),
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
    ActivitySyncRuleSet: z.string().nullable().describe(`
        * * Field Name: ActivitySyncRuleSet
        * * Display Name: Rule Set Name
        * * SQL Data Type: nvarchar(200)`),
    Person: z.string().nullable().describe(`
        * * Field Name: Person
        * * Display Name: Person Name
        * * SQL Data Type: nvarchar(201)`),
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
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Provider Types (vwActivitySyncProviderTypes.ID)`),
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
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Provider Types (vwActivitySyncProviderTypes.ID)`),
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
        * * Display Name: Activity Sync Rule
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Rules (vwActivitySyncRules.ID)`),
    ActivitySyncExclusionID: z.string().nullable().describe(`
        * * Field Name: ActivitySyncExclusionID
        * * Display Name: Activity Sync Exclusion
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
        * * Display Name: AI Prompt Run
        * * SQL Data Type: uniqueidentifier
        * * Description: The MJ: AI Prompt Run behind an inference-stage verdict. Non-null only when a model actually decided this item, which is the audit trail for every automated judgement the engine makes.`),
    ActivityID: z.string().nullable().describe(`
        * * Field Name: ActivityID
        * * Display Name: Activity
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activities (vwActivities.ID)`),
    CapturedContent: z.string().nullable().describe(`
        * * Field Name: CapturedContent
        * * Display Name: Captured Content
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Ciphertext, always — never plaintext, whatever the policy. Present only when the effective SkippedContentPolicy allows retention, and always paired with the EncryptionKeyID that opens it (CK_ActivitySyncRunDetail_ContentKey). Encrypted through MJ's EncryptionEngine against an MJ: Encryption Keys row; this app never implements its own crypto.`),
    EncryptionKeyID: z.string().nullable().describe(`
        * * Field Name: EncryptionKeyID
        * * Display Name: Encryption Key
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
        * * Display Name: Activity Sync Rule Name
        * * SQL Data Type: nvarchar(200)`),
    Activity: z.string().nullable().describe(`
        * * Field Name: Activity
        * * Display Name: Activity Reference
        * * SQL Data Type: nvarchar(500)`),
    EncryptionKey: z.string().nullable().describe(`
        * * Field Name: EncryptionKey
        * * Display Name: Encryption Key Name
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
    ActivitySyncConnection: z.string().describe(`
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
    Address: z.string().describe(`
        * * Field Name: Address
        * * Display Name: Address
        * * SQL Data Type: nvarchar(255)`),
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
    Line1: z.string().describe(`
        * * Field Name: Line1
        * * Display Name: Address Line 1
        * * SQL Data Type: nvarchar(255)
        * * Description: Street address line 1`),
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
    City: z.string().describe(`
        * * Field Name: City
        * * Display Name: City
        * * SQL Data Type: nvarchar(100)
        * * Description: City or locality name`),
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
});

export type mjBizAppsCommonAddressEntityType = z.infer<typeof mjBizAppsCommonAddressSchema>;

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
        * * SQL Data Type: nvarchar(201)`),
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
});

export type mjBizAppsCommonContactTypeEntityType = z.infer<typeof mjBizAppsCommonContactTypeSchema>;

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
        * * SQL Data Type: nvarchar(1000)
        * * Description: URL to organization logo image`),
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
    OrganizationType: z.string().nullable().describe(`
        * * Field Name: OrganizationType
        * * Display Name: Organization Type Name
        * * SQL Data Type: nvarchar(100)`),
    Parent: z.string().nullable().describe(`
        * * Field Name: Parent
        * * Display Name: Parent Name
        * * SQL Data Type: nvarchar(255)`),
    __mj_Latitude: z.number().nullable().describe(`
        * * Field Name: __mj_Latitude
        * * Display Name: Latitude
        * * SQL Data Type: decimal(10, 6)`),
    __mj_Longitude: z.number().nullable().describe(`
        * * Field Name: __mj_Longitude
        * * Display Name: Longitude
        * * SQL Data Type: decimal(10, 6)`),
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
        * * SQL Data Type: nvarchar(1000)
        * * Description: URL to profile photo or avatar image`),
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
        * * Description: DEPRECATED: Do not use. bizapps-common no longer reads or writes this column; person-to-MJ-User bindings are owned by platform-layer IS-A subtypes of Person (e.g., BCSaaS 'BC: People'). Retained only for backward compatibility and scheduled for removal in the next major release.`),
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
    DisplayName: z.string().describe(`
        * * Field Name: DisplayName
        * * Display Name: Display Name
        * * SQL Data Type: nvarchar(201)`),
    LinkedUser: z.string().nullable().describe(`
        * * Field Name: LinkedUser
        * * Display Name: Linked User
        * * SQL Data Type: nvarchar(100)`),
    __mj_Latitude: z.number().nullable().describe(`
        * * Field Name: __mj_Latitude
        * * Display Name: Mj Latitude
        * * SQL Data Type: decimal(10, 6)`),
    __mj_Longitude: z.number().nullable().describe(`
        * * Field Name: __mj_Longitude
        * * Display Name: Mj Longitude
        * * SQL Data Type: decimal(10, 6)`),
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
});

export type mjBizAppsCommonPersonEntityType = z.infer<typeof mjBizAppsCommonPersonSchema>;

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
    RelationshipType: z.string().describe(`
        * * Field Name: RelationshipType
        * * Display Name: Relationship Type
        * * SQL Data Type: nvarchar(100)`),
    FromPerson: z.string().nullable().describe(`
        * * Field Name: FromPerson
        * * Display Name: From Person
        * * SQL Data Type: nvarchar(201)`),
    FromOrganization: z.string().nullable().describe(`
        * * Field Name: FromOrganization
        * * Display Name: From Organization Name
        * * SQL Data Type: nvarchar(255)`),
    ToPerson: z.string().nullable().describe(`
        * * Field Name: ToPerson
        * * Display Name: To Person
        * * SQL Data Type: nvarchar(201)`),
    ToOrganization: z.string().nullable().describe(`
        * * Field Name: ToOrganization
        * * Display Name: To Organization Name
        * * SQL Data Type: nvarchar(255)`),
});

export type mjBizAppsCommonRelationshipEntityType = z.infer<typeof mjBizAppsCommonRelationshipSchema>;
 
 

/**
 * MJ_BizApps_Common: Activities - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: Activity
 * * Base View: vwActivities
 * * @description One interaction that happened between people, about records. Timeline card — not a blob store, not a task, not field-level audit. Duration is derived from StartedAt/EndedAt.
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Activities')
export class mjBizAppsCommonActivityEntity extends BaseEntity<mjBizAppsCommonActivityEntityType> {

  /**
  * Related records: MJ_BizApps_Common: Activity Files
  *
  * Loads, validates and persists as one unit with this MJ_BizApps_Common: Activities record — see
  * guides/TRANSACTIONS_AND_BATCHING_GUIDE.md. Declared by the RelatedRecordCollection metadata on
  * the 'MJ_BizApps_Common: Activities → MJ_BizApps_Common: Activity Files' relationship; edit that row, not this file.
  *
  */
  public readonly Files = this.DeclareRelatedRecords<mjBizAppsCommonActivityFileEntity>({
      Name: 'Files',
        RelatedEntity: 'MJ_BizApps_Common: Activity Files',
        RelatedEntityJoinField: 'ActivityID',
        Load: 'explicit',
        OnRemove: 'delete',
  });


  /**
  * Related records: MJ_BizApps_Common: Activity Links
  *
  * Loads, validates and persists as one unit with this MJ_BizApps_Common: Activities record — see
  * guides/TRANSACTIONS_AND_BATCHING_GUIDE.md. Declared by the RelatedRecordCollection metadata on
  * the 'MJ_BizApps_Common: Activities → MJ_BizApps_Common: Activity Links' relationship; edit that row, not this file.
  *
  */
  public readonly Links = this.DeclareRelatedRecords<mjBizAppsCommonActivityLinkEntity>({
      Name: 'Links',
        RelatedEntity: 'MJ_BizApps_Common: Activity Links',
        RelatedEntityJoinField: 'ActivityID',
        Load: 'explicit',
        OnRemove: 'delete',
  });

    /**
    * Loads the MJ_BizApps_Common: Activities record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Activities record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonActivityEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: ActivityTypeID
    * * Display Name: Activity Type
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Types (vwActivityTypes.ID)
    */
    get ActivityTypeID(): string {
        return this.Get('ActivityTypeID');
    }
    set ActivityTypeID(value: string) {
        this.Set('ActivityTypeID', value);
    }

    /**
    * * Field Name: StartedAt
    * * Display Name: Started At
    * * SQL Data Type: datetimeoffset
    * * Description: Sort key for every timeline. Instant events use the date/time of the event.
    */
    get StartedAt(): Date {
        return this.Get('StartedAt');
    }
    set StartedAt(value: Date) {
        this.Set('StartedAt', value);
    }

    /**
    * * Field Name: EndedAt
    * * Display Name: Ended At
    * * SQL Data Type: datetimeoffset
    * * Description: End of a meeting/call. Leave null for a point-in-time log. Must be >= StartedAt when set. Duration is derived; do not store it.
    */
    get EndedAt(): Date | null {
        return this.Get('EndedAt');
    }
    set EndedAt(value: Date | null) {
        this.Set('EndedAt', value);
    }

    /**
    * * Field Name: Title
    * * Display Name: Title
    * * SQL Data Type: nvarchar(500)
    * * Description: Subject / one-line card title (e.g. Called Jane about renewal).
    */
    get Title(): string {
        return this.Get('Title');
    }
    set Title(value: string) {
        this.Set('Title', value);
    }

    /**
    * * Field Name: Description
    * * Display Name: Description
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Notes or a short excerpt. Not the full email body — that lives on an ActivityFile of Kind Body.
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: Direction
    * * Display Name: Direction
    * * SQL Data Type: nvarchar(20)
    * * Value List Type: List
    * * Possible Values 
    *   * Inbound
    *   * Internal
    *   * Outbound
    * * Description: Inbound, Outbound, or Internal. Channel lives on ActivityType; direction lives here so inbound email is a filter, not a type explosion.
    */
    get Direction(): 'Inbound' | 'Internal' | 'Outbound' {
        return this.Get('Direction');
    }
    set Direction(value: 'Inbound' | 'Internal' | 'Outbound') {
        this.Set('Direction', value);
    }

    /**
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
    * * Description: Logged (default for a past event), Scheduled, Completed, Cancelled, or Failed.
    */
    get Status(): 'Cancelled' | 'Completed' | 'Failed' | 'Logged' | 'Scheduled' {
        return this.Get('Status');
    }
    set Status(value: 'Cancelled' | 'Completed' | 'Failed' | 'Logged' | 'Scheduled') {
        this.Set('Status', value);
    }

    /**
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
    * * Description: Optional disposition: Connected, LeftVoicemail, NoAnswer, NoShow, Bounced, Interested, NotInterested. A filter, not a type.
    */
    get Outcome(): 'Bounced' | 'Connected' | 'Interested' | 'LeftVoicemail' | 'NoAnswer' | 'NoShow' | 'NotInterested' | null {
        return this.Get('Outcome');
    }
    set Outcome(value: 'Bounced' | 'Connected' | 'Interested' | 'LeftVoicemail' | 'NoAnswer' | 'NoShow' | 'NotInterested' | null) {
        this.Set('Outcome', value);
    }

    /**
    * * Field Name: Visibility
    * * Display Name: Visibility
    * * SQL Data Type: nvarchar(20)
    * * Default Value: Internal
    * * Value List Type: List
    * * Possible Values 
    *   * Internal
    *   * Private
    * * Description: Internal (anyone who can read a Regarding record) or Private (LoggedByUserID only, until a PermissionEngine domain exists). Manual default is Internal; synced mail should default Private in the engine.
    */
    get Visibility(): 'Internal' | 'Private' {
        return this.Get('Visibility');
    }
    set Visibility(value: 'Internal' | 'Private') {
        this.Set('Visibility', value);
    }

    /**
    * * Field Name: Source
    * * Display Name: Source
    * * SQL Data Type: nvarchar(20)
    * * Default Value: Manual
    * * Value List Type: List
    * * Possible Values 
    *   * Integration
    *   * Manual
    *   * System
    * * Description: How the row was written: Manual, System, or Integration.
    */
    get Source(): 'Integration' | 'Manual' | 'System' {
        return this.Get('Source');
    }
    set Source(value: 'Integration' | 'Manual' | 'System') {
        this.Set('Source', value);
    }

    /**
    * * Field Name: SourceSystem
    * * Display Name: Source System
    * * SQL Data Type: nvarchar(80)
    * * Description: Provider name for idempotent sync (Microsoft365, Gmail, Zoom). Required when ExternalID is set.
    */
    get SourceSystem(): string | null {
        return this.Get('SourceSystem');
    }
    set SourceSystem(value: string | null) {
        this.Set('SourceSystem', value);
    }

    /**
    * * Field Name: ExternalID
    * * Display Name: External ID
    * * SQL Data Type: nvarchar(400)
    * * Description: Provider message/event id. Unique with SourceSystem where set — never dedup by subject.
    */
    get ExternalID(): string | null {
        return this.Get('ExternalID');
    }
    set ExternalID(value: string | null) {
        this.Set('ExternalID', value);
    }

    /**
    * * Field Name: ExternalThreadID
    * * Display Name: External Thread ID
    * * SQL Data Type: nvarchar(400)
    * * Description: Email or calendar thread id used to group replies.
    */
    get ExternalThreadID(): string | null {
        return this.Get('ExternalThreadID');
    }
    set ExternalThreadID(value: string | null) {
        this.Set('ExternalThreadID', value);
    }

    /**
    * * Field Name: ParentActivityID
    * * Display Name: Parent Activity
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activities (vwActivities.ID)
    */
    get ParentActivityID(): string | null {
        return this.Get('ParentActivityID');
    }
    set ParentActivityID(value: string | null) {
        this.Set('ParentActivityID', value);
    }

    /**
    * * Field Name: LoggedByUserID
    * * Display Name: Logged By User
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ: Users (vwUsers.ID)
    */
    get LoggedByUserID(): string {
        return this.Get('LoggedByUserID');
    }
    set LoggedByUserID(value: string) {
        this.Set('LoggedByUserID', value);
    }

    /**
    * * Field Name: Location
    * * Display Name: Location
    * * SQL Data Type: nvarchar(500)
    * * Description: Meeting place as text. Optional AddressID is the structured location.
    */
    get Location(): string | null {
        return this.Get('Location');
    }
    set Location(value: string | null) {
        this.Set('Location', value);
    }

    /**
    * * Field Name: AddressID
    * * Display Name: Address
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Addresses (vwAddresses.ID)
    */
    get AddressID(): string | null {
        return this.Get('AddressID');
    }
    set AddressID(value: string | null) {
        this.Set('AddressID', value);
    }

    /**
    * * Field Name: ActivitySyncConnectionID
    * * Display Name: Sync Connection
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Connections (vwActivitySyncConnections.ID)
    */
    get ActivitySyncConnectionID(): string | null {
        return this.Get('ActivitySyncConnectionID');
    }
    set ActivitySyncConnectionID(value: string | null) {
        this.Set('ActivitySyncConnectionID', value);
    }

    /**
    * * Field Name: Details
    * * Display Name: Details
    * * SQL Data Type: nvarchar(MAX)
    * * Description: JSON extras that are not query predicates: MessageID, InReplyTo, MeetingURL, Mailbox, Folder, CalendarEventID. See ActivityDetails.
    */
    get Details(): string | null {
        return this.Get('Details');
    }
    set Details(value: string | null) {
        this.Set('Details', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: ActivityType
    * * Display Name: Activity Type Name
    * * SQL Data Type: nvarchar(100)
    */
    get ActivityType(): string {
        return this.Get('ActivityType');
    }

    /**
    * * Field Name: ParentActivity
    * * Display Name: Parent Activity
    * * SQL Data Type: nvarchar(500)
    */
    get ParentActivity(): string | null {
        return this.Get('ParentActivity');
    }

    /**
    * * Field Name: LoggedByUser
    * * Display Name: Logged By
    * * SQL Data Type: nvarchar(100)
    */
    get LoggedByUser(): string {
        return this.Get('LoggedByUser');
    }

    /**
    * * Field Name: Address
    * * Display Name: Address Details
    * * SQL Data Type: nvarchar(255)
    */
    get Address(): string | null {
        return this.Get('Address');
    }

    /**
    * * Field Name: ActivitySyncConnection
    * * Display Name: Sync Connection Name
    * * SQL Data Type: nvarchar(200)
    */
    get ActivitySyncConnection(): string | null {
        return this.Get('ActivitySyncConnection');
    }

    /**
    * * Field Name: __mj_Latitude
    * * Display Name: Mj Latitude
    * * SQL Data Type: decimal(10, 6)
    */
    get __mj_Latitude(): number | null {
        return this.Get('__mj_Latitude');
    }

    /**
    * * Field Name: __mj_Longitude
    * * Display Name: Mj Longitude
    * * SQL Data Type: decimal(10, 6)
    */
    get __mj_Longitude(): number | null {
        return this.Get('__mj_Longitude');
    }

    /**
    * * Field Name: RootParentActivityID
    * * Display Name: Root Parent Activity
    * * SQL Data Type: uniqueidentifier
    */
    get RootParentActivityID(): string | null {
        return this.Get('RootParentActivityID');
    }

    /**
    * * Field Name: ParentActivityIDDepth
    * * Display Name: Hierarchy Depth
    * * SQL Data Type: int
    */
    get ParentActivityIDDepth(): number | null {
        return this.Get('ParentActivityIDDepth');
    }

    /**
    * * Field Name: ParentActivityIDPath
    * * Display Name: Hierarchy Path
    * * SQL Data Type: nvarchar(MAX)
    */
    get ParentActivityIDPath(): string | null {
        return this.Get('ParentActivityIDPath');
    }

    /**
    * * Field Name: ParentActivityIDIsLeaf
    * * Display Name: Is Leaf
    * * SQL Data Type: bit
    */
    get ParentActivityIDIsLeaf(): boolean | null {
        return this.Get('ParentActivityIDIsLeaf');
    }

    /**
    * * Field Name: ParentActivityIDChildCount
    * * Display Name: Child Count
    * * SQL Data Type: int
    */
    get ParentActivityIDChildCount(): number | null {
        return this.Get('ParentActivityIDChildCount');
    }
}


/**
 * MJ_BizApps_Common: Activity Files - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: ActivityFile
 * * Base View: vwActivityFiles
 * * @description Join from an Activity to an MJ File. Kind Body is the full MIME/HTML (at most one per activity); Attachment and Ics are extras. Deleting the activity drops the join, not the File.
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Activity Files')
export class mjBizAppsCommonActivityFileEntity extends BaseEntity<mjBizAppsCommonActivityFileEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Activity Files record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Activity Files record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonActivityFileEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: ActivityID
    * * Display Name: Activity ID
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activities (vwActivities.ID)
    */
    get ActivityID(): string {
        return this.Get('ActivityID');
    }
    set ActivityID(value: string) {
        this.Set('ActivityID', value);
    }

    /**
    * * Field Name: FileID
    * * Display Name: File ID
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ: Files (vwFiles.ID)
    */
    get FileID(): string {
        return this.Get('FileID');
    }
    set FileID(value: string) {
        this.Set('FileID', value);
    }

    /**
    * * Field Name: Kind
    * * Display Name: Kind
    * * SQL Data Type: nvarchar(20)
    * * Value List Type: List
    * * Possible Values 
    *   * Attachment
    *   * Body
    *   * Ics
    * * Description: Body (full MIME/HTML, at most one per activity), Attachment, or Ics.
    */
    get Kind(): 'Attachment' | 'Body' | 'Ics' {
        return this.Get('Kind');
    }
    set Kind(value: 'Attachment' | 'Body' | 'Ics') {
        this.Set('Kind', value);
    }

    /**
    * * Field Name: Sequence
    * * Display Name: Sequence
    * * SQL Data Type: int
    * * Default Value: 0
    * * Description: Display order of attachments.
    */
    get Sequence(): number {
        return this.Get('Sequence');
    }
    set Sequence(value: number) {
        this.Set('Sequence', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: Activity
    * * Display Name: Activity
    * * SQL Data Type: nvarchar(500)
    */
    get Activity(): string {
        return this.Get('Activity');
    }

    /**
    * * Field Name: File
    * * Display Name: File
    * * SQL Data Type: nvarchar(500)
    */
    get File(): string {
        return this.Get('File');
    }
}


/**
 * MJ_BizApps_Common: Activity Links - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: ActivityLink
 * * Base View: vwActivityLinks
 * * @description Attaches an Activity to a resolved MJ record (EntityID + RecordID) or an unresolved identity (email/phone/external user) the matcher has not stamped yet. Role says whether the link is Regarding, a participant, or an email/meeting mailbox role.
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Activity Links')
export class mjBizAppsCommonActivityLinkEntity extends BaseEntity<mjBizAppsCommonActivityLinkEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Activity Links record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Activity Links record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonActivityLinkEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: ActivityID
    * * Display Name: Activity ID
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activities (vwActivities.ID)
    */
    get ActivityID(): string {
        return this.Get('ActivityID');
    }
    set ActivityID(value: string) {
        this.Set('ActivityID', value);
    }

    /**
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
    * * Description: Why this record is on the activity: Regarding (what it is about), Participant, From/To/Cc/Bcc, Organizer/Attendee, or LoggedFor (the mailbox it was filed under).
    */
    get Role(): 'Attendee' | 'Bcc' | 'Cc' | 'From' | 'LoggedFor' | 'Organizer' | 'Participant' | 'Regarding' | 'To' {
        return this.Get('Role');
    }
    set Role(value: 'Attendee' | 'Bcc' | 'Cc' | 'From' | 'LoggedFor' | 'Organizer' | 'Participant' | 'Regarding' | 'To') {
        this.Set('Role', value);
    }

    /**
    * * Field Name: EntityID
    * * Display Name: Entity ID
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ: Entities (vwEntities.ID)
    */
    get EntityID(): string | null {
        return this.Get('EntityID');
    }
    set EntityID(value: string | null) {
        this.Set('EntityID', value);
    }

    /**
    * * Field Name: RecordID
    * * Display Name: Record ID
    * * SQL Data Type: nvarchar(450)
    * * Description: Primary key of the resolved record. NVARCHAR so composite keys work. Required with EntityID; must be null when the link is an unresolved identity.
    */
    get RecordID(): string | null {
        return this.Get('RecordID');
    }
    set RecordID(value: string | null) {
        this.Set('RecordID', value);
    }

    /**
    * * Field Name: IdentityKind
    * * Display Name: Identity Kind
    * * SQL Data Type: nvarchar(20)
    * * Value List Type: List
    * * Possible Values 
    *   * Email
    *   * ExternalUser
    *   * Phone
    * * Description: Email, Phone, or ExternalUser. Set with IdentityValue when the participant has not been matched to a Person/Org yet.
    */
    get IdentityKind(): 'Email' | 'ExternalUser' | 'Phone' | null {
        return this.Get('IdentityKind');
    }
    set IdentityKind(value: 'Email' | 'ExternalUser' | 'Phone' | null) {
        this.Set('IdentityKind', value);
    }

    /**
    * * Field Name: IdentityValue
    * * Display Name: Identity Value
    * * SQL Data Type: nvarchar(320)
    * * Description: The unmatched address, phone, or provider user id. A later matcher stamps EntityID/RecordID from ContactMethod.Value and clears these.
    */
    get IdentityValue(): string | null {
        return this.Get('IdentityValue');
    }
    set IdentityValue(value: string | null) {
        this.Set('IdentityValue', value);
    }

    /**
    * * Field Name: Sequence
    * * Display Name: Sequence
    * * SQL Data Type: int
    * * Default Value: 0
    * * Description: Display order within a role (To, then Cc, …).
    */
    get Sequence(): number {
        return this.Get('Sequence');
    }
    set Sequence(value: number) {
        this.Set('Sequence', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: Activity
    * * Display Name: Activity
    * * SQL Data Type: nvarchar(500)
    */
    get Activity(): string {
        return this.Get('Activity');
    }

    /**
    * * Field Name: Entity
    * * Display Name: Entity
    * * SQL Data Type: nvarchar(255)
    */
    get Entity(): string | null {
        return this.Get('Entity');
    }
}


/**
 * MJ_BizApps_Common: Activity Sync Connection Rule Sets - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: ActivitySyncConnectionRuleSet
 * * Base View: vwActivitySyncConnectionRuleSets
 * * @description Binds a rule set to a connection, ordered. Many-to-many so a mailbox composes an org-wide baseline, a team overlay, and anything specific to itself — rather than owning one private copy of everything.
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Activity Sync Connection Rule Sets')
export class mjBizAppsCommonActivitySyncConnectionRuleSetEntity extends BaseEntity<mjBizAppsCommonActivitySyncConnectionRuleSetEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Activity Sync Connection Rule Sets record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Activity Sync Connection Rule Sets record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonActivitySyncConnectionRuleSetEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: ActivitySyncConnectionID
    * * Display Name: Activity Sync Connection
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Connections (vwActivitySyncConnections.ID)
    */
    get ActivitySyncConnectionID(): string {
        return this.Get('ActivitySyncConnectionID');
    }
    set ActivitySyncConnectionID(value: string) {
        this.Set('ActivitySyncConnectionID', value);
    }

    /**
    * * Field Name: ActivitySyncRuleSetID
    * * Display Name: Activity Sync Rule Set
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Rule Sets (vwActivitySyncRuleSets.ID)
    * * Description: The rule set bound to this connection. A mailbox composes several sets (org baseline, team overlay, mailbox-specific) through this join; Sequence on the binding is the evaluation order.
    */
    get ActivitySyncRuleSetID(): string {
        return this.Get('ActivitySyncRuleSetID');
    }
    set ActivitySyncRuleSetID(value: string) {
        this.Set('ActivitySyncRuleSetID', value);
    }

    /**
    * * Field Name: Sequence
    * * Display Name: Evaluation Sequence
    * * SQL Data Type: int
    * * Default Value: 0
    */
    get Sequence(): number {
        return this.Get('Sequence');
    }
    set Sequence(value: number) {
        this.Set('Sequence', value);
    }

    /**
    * * Field Name: IsEnabled
    * * Display Name: Is Enabled
    * * SQL Data Type: bit
    * * Default Value: 1
    */
    get IsEnabled(): boolean {
        return this.Get('IsEnabled');
    }
    set IsEnabled(value: boolean) {
        this.Set('IsEnabled', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: ActivitySyncConnection
    * * Display Name: Connection Name
    * * SQL Data Type: nvarchar(200)
    */
    get ActivitySyncConnection(): string {
        return this.Get('ActivitySyncConnection');
    }

    /**
    * * Field Name: ActivitySyncRuleSet
    * * Display Name: Rule Set Name
    * * SQL Data Type: nvarchar(200)
    */
    get ActivitySyncRuleSet(): string {
        return this.Get('ActivitySyncRuleSet');
    }
}


/**
 * MJ_BizApps_Common: Activity Sync Connections - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: ActivitySyncConnection
 * * Base View: vwActivitySyncConnections
 * * @description A mailbox, calendar, or other provider connection that writes Activities. CredentialsRef is an MJ Credentials engine key — never a secret at rest.
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Activity Sync Connections')
export class mjBizAppsCommonActivitySyncConnectionEntity extends BaseEntity<mjBizAppsCommonActivitySyncConnectionEntityType> {

  /**
  * Related records: MJ_BizApps_Common: Activity Sync Rules
  *
  * Loads, validates and persists as one unit with this MJ_BizApps_Common: Activity Sync Connections record — see
  * guides/TRANSACTIONS_AND_BATCHING_GUIDE.md. Declared by the RelatedRecordCollection metadata on
  * the 'MJ_BizApps_Common: Activity Sync Connections → MJ_BizApps_Common: Activity Sync Rules' relationship; edit that row, not this file.
  *
  */
  public readonly Rules = this.DeclareRelatedRecords<mjBizAppsCommonActivitySyncRuleEntity>({
      Name: 'Rules',
        RelatedEntity: 'MJ_BizApps_Common: Activity Sync Rules',
        RelatedEntityJoinField: 'ActivitySyncConnectionID',
        Load: 'explicit',
        OnRemove: 'delete',
  });

    /**
    * Loads the MJ_BizApps_Common: Activity Sync Connections record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Activity Sync Connections record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonActivitySyncConnectionEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: Name
    * * Display Name: Name
    * * SQL Data Type: nvarchar(200)
    * * Description: Display name of the connection (e.g. Amith / Microsoft 365).
    */
    get Name(): string {
        return this.Get('Name');
    }
    set Name(value: string) {
        this.Set('Name', value);
    }

    /**
    * * Field Name: Provider
    * * Display Name: Provider
    * * SQL Data Type: nvarchar(40)
    * * Value List Type: List
    * * Possible Values 
    *   * Generic
    *   * Gmail
    *   * Microsoft365
    *   * Zoom
    * * Description: DEPRECATED — use ActivitySyncProviderTypeID. Retained nullable so a published host keeps working; removed in the next major.
    */
    get Provider(): 'Generic' | 'Gmail' | 'Microsoft365' | 'Zoom' | null {
        return this.Get('Provider');
    }
    set Provider(value: 'Generic' | 'Gmail' | 'Microsoft365' | 'Zoom' | null) {
        this.Set('Provider', value);
    }

    /**
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
    * * Description: Active, Paused, Error, or Disabled.
    */
    get Status(): 'Active' | 'Disabled' | 'Error' | 'Paused' {
        return this.Get('Status');
    }
    set Status(value: 'Active' | 'Disabled' | 'Error' | 'Paused') {
        this.Set('Status', value);
    }

    /**
    * * Field Name: Direction
    * * Display Name: Direction
    * * SQL Data Type: nvarchar(20)
    * * Default Value: Inbound
    * * Value List Type: List
    * * Possible Values 
    *   * Bidirectional
    *   * Inbound
    *   * Outbound
    * * Description: Inbound (pull into CRM), Outbound, or Bidirectional.
    */
    get Direction(): 'Bidirectional' | 'Inbound' | 'Outbound' {
        return this.Get('Direction');
    }
    set Direction(value: 'Bidirectional' | 'Inbound' | 'Outbound') {
        this.Set('Direction', value);
    }

    /**
    * * Field Name: OwnerUserID
    * * Display Name: Owner User ID
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ: Users (vwUsers.ID)
    */
    get OwnerUserID(): string {
        return this.Get('OwnerUserID');
    }
    set OwnerUserID(value: string) {
        this.Set('OwnerUserID', value);
    }

    /**
    * * Field Name: CredentialsRef
    * * Display Name: Credentials Reference
    * * SQL Data Type: nvarchar(200)
    * * Description: MJ Credentials engine key. NEVER a secret value at rest.
    */
    get CredentialsRef(): string | null {
        return this.Get('CredentialsRef');
    }
    set CredentialsRef(value: string | null) {
        this.Set('CredentialsRef', value);
    }

    /**
    * * Field Name: Mailbox
    * * Display Name: Mailbox
    * * SQL Data Type: nvarchar(320)
    * * Description: Mailbox address this connection reads (jane@acme.com).
    */
    get Mailbox(): string | null {
        return this.Get('Mailbox');
    }
    set Mailbox(value: string | null) {
        this.Set('Mailbox', value);
    }

    /**
    * * Field Name: LastSyncAt
    * * Display Name: Last Sync At
    * * SQL Data Type: datetimeoffset
    * * Description: When the engine last completed a sync for this connection.
    */
    get LastSyncAt(): Date | null {
        return this.Get('LastSyncAt');
    }
    set LastSyncAt(value: Date | null) {
        this.Set('LastSyncAt', value);
    }

    /**
    * * Field Name: LastError
    * * Display Name: Last Error
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Most recent sync error, if Status is Error.
    */
    get LastError(): string | null {
        return this.Get('LastError');
    }
    set LastError(value: string | null) {
        this.Set('LastError', value);
    }

    /**
    * * Field Name: Settings
    * * Display Name: Settings
    * * SQL Data Type: nvarchar(MAX)
    * * Description: JSON provider extras (TenantID, MailboxFolder, CalendarID, IncludeCalendar, IncludeMail). See ActivitySyncConnectionSettings.
    */
    get Settings(): string | null {
        return this.Get('Settings');
    }
    set Settings(value: string | null) {
        this.Set('Settings', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: ActivitySyncProviderTypeID
    * * Display Name: Provider Type
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Provider Types (vwActivitySyncProviderTypes.ID)
    * * Description: The provider type this connection reads. Supersedes the Provider string column, whose CHECK constraint made every new source a migration to Common.
    */
    get ActivitySyncProviderTypeID(): string | null {
        return this.Get('ActivitySyncProviderTypeID');
    }
    set ActivitySyncProviderTypeID(value: string | null) {
        this.Set('ActivitySyncProviderTypeID', value);
    }

    /**
    * * Field Name: StartAt
    * * Display Name: Start At
    * * SQL Data Type: datetimeoffset
    * * Description: Activation window. Combines with Status: a connection syncs only when Status = Active AND now is within [StartAt, EndAt], treating either bound as open when null. Lets a mailbox be provisioned ahead of time, or retired on a date, without anyone remembering to flip a switch.
    */
    get StartAt(): Date | null {
        return this.Get('StartAt');
    }
    set StartAt(value: Date | null) {
        this.Set('StartAt', value);
    }

    /**
    * * Field Name: EndAt
    * * Display Name: End At
    * * SQL Data Type: datetimeoffset
    * * Description: End of the activation window; see StartAt. Null means open-ended.
    */
    get EndAt(): Date | null {
        return this.Get('EndAt');
    }
    set EndAt(value: Date | null) {
        this.Set('EndAt', value);
    }

    /**
    * * Field Name: SkippedContentPolicy
    * * Display Name: Skipped Content Policy
    * * SQL Data Type: nvarchar(20)
    * * Value List Type: List
    * * Possible Values 
    *   * FullEncrypted
    *   * None
    *   * SubjectEncrypted
    * * Description: Per-connection override of the provider type's DefaultSkippedContentPolicy. Null inherits. This is the knob for "this one mailbox is sensitive" without changing the estate.
    */
    get SkippedContentPolicy(): 'FullEncrypted' | 'None' | 'SubjectEncrypted' | null {
        return this.Get('SkippedContentPolicy');
    }
    set SkippedContentPolicy(value: 'FullEncrypted' | 'None' | 'SubjectEncrypted' | null) {
        this.Set('SkippedContentPolicy', value);
    }

    /**
    * * Field Name: EncryptionKeyID
    * * Display Name: Encryption Key ID
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ: Encryption Keys (vwEncryptionKeys.ID)
    */
    get EncryptionKeyID(): string | null {
        return this.Get('EncryptionKeyID');
    }
    set EncryptionKeyID(value: string | null) {
        this.Set('EncryptionKeyID', value);
    }

    /**
    * * Field Name: StorageProviderID
    * * Display Name: Storage Provider ID
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ: File Storage Providers (vwFileStorageProviders.ID)
    */
    get StorageProviderID(): string | null {
        return this.Get('StorageProviderID');
    }
    set StorageProviderID(value: string | null) {
        this.Set('StorageProviderID', value);
    }

    /**
    * * Field Name: MaxAttachmentBytes
    * * Display Name: Max Attachment Bytes
    * * SQL Data Type: bigint
    */
    get MaxAttachmentBytes(): number | null {
        return this.Get('MaxAttachmentBytes');
    }
    set MaxAttachmentBytes(value: number | null) {
        this.Set('MaxAttachmentBytes', value);
    }

    /**
    * * Field Name: OwnerUser
    * * Display Name: Owner User
    * * SQL Data Type: nvarchar(100)
    */
    get OwnerUser(): string {
        return this.Get('OwnerUser');
    }

    /**
    * * Field Name: ActivitySyncProviderType
    * * Display Name: Provider Type Name
    * * SQL Data Type: nvarchar(100)
    */
    get ActivitySyncProviderType(): string | null {
        return this.Get('ActivitySyncProviderType');
    }

    /**
    * * Field Name: EncryptionKey
    * * Display Name: Encryption Key
    * * SQL Data Type: nvarchar(100)
    */
    get EncryptionKey(): string | null {
        return this.Get('EncryptionKey');
    }

    /**
    * * Field Name: StorageProvider
    * * Display Name: Storage Provider
    * * SQL Data Type: nvarchar(50)
    */
    get StorageProvider(): string | null {
        return this.Get('StorageProvider');
    }
}


/**
 * MJ_BizApps_Common: Activity Sync Exclusions - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: ActivitySyncExclusion
 * * Base View: vwActivitySyncExclusions
 * * @description Never-ingest list, by identity: an email address, a phone number, a social handle, or a whole domain. Rows rather than a delimited string because an exclusion that cannot be queried cannot be audited, and this is precisely what a legal hold, an HR matter or an opt-out has to be able to prove. Scoped to a rule set, or global when ActivitySyncRuleSetID is null.
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Activity Sync Exclusions')
export class mjBizAppsCommonActivitySyncExclusionEntity extends BaseEntity<mjBizAppsCommonActivitySyncExclusionEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Activity Sync Exclusions record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Activity Sync Exclusions record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonActivitySyncExclusionEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: ActivitySyncRuleSetID
    * * Display Name: Activity Sync Rule Set
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Rule Sets (vwActivitySyncRuleSets.ID)
    * * Description: Optional rule set this exclusion belongs to. Null means global — the identity is never ingested on any connection. A legal hold or opt-out is usually global; a mailbox-specific mute is not.
    */
    get ActivitySyncRuleSetID(): string | null {
        return this.Get('ActivitySyncRuleSetID');
    }
    set ActivitySyncRuleSetID(value: string | null) {
        this.Set('ActivitySyncRuleSetID', value);
    }

    /**
    * * Field Name: IdentityKind
    * * Display Name: Identity Kind
    * * SQL Data Type: nvarchar(20)
    * * Value List Type: List
    * * Possible Values 
    *   * Domain
    *   * Email
    *   * Handle
    *   * Phone
    */
    get IdentityKind(): 'Domain' | 'Email' | 'Handle' | 'Phone' {
        return this.Get('IdentityKind');
    }
    set IdentityKind(value: 'Domain' | 'Email' | 'Handle' | 'Phone') {
        this.Set('IdentityKind', value);
    }

    /**
    * * Field Name: IdentityValue
    * * Display Name: Identity Value
    * * SQL Data Type: nvarchar(320)
    */
    get IdentityValue(): string {
        return this.Get('IdentityValue');
    }
    set IdentityValue(value: string) {
        this.Set('IdentityValue', value);
    }

    /**
    * * Field Name: PersonID
    * * Display Name: Person
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: People (vwPeople.ID)
    * * Description: Optional link to the Person this identity belongs to. Optional because an address is often excluded before anyone knows whose it is, and because a Person has several ContactMethods — the identity is the durable key here, not the record.
    */
    get PersonID(): string | null {
        return this.Get('PersonID');
    }
    set PersonID(value: string | null) {
        this.Set('PersonID', value);
    }

    /**
    * * Field Name: Reason
    * * Display Name: Reason
    * * SQL Data Type: nvarchar(MAX)
    */
    get Reason(): string | null {
        return this.Get('Reason');
    }
    set Reason(value: string | null) {
        this.Set('Reason', value);
    }

    /**
    * * Field Name: EffectiveFrom
    * * Display Name: Effective From
    * * SQL Data Type: datetimeoffset
    */
    get EffectiveFrom(): Date | null {
        return this.Get('EffectiveFrom');
    }
    set EffectiveFrom(value: Date | null) {
        this.Set('EffectiveFrom', value);
    }

    /**
    * * Field Name: EffectiveTo
    * * Display Name: Effective To
    * * SQL Data Type: datetimeoffset
    */
    get EffectiveTo(): Date | null {
        return this.Get('EffectiveTo');
    }
    set EffectiveTo(value: Date | null) {
        this.Set('EffectiveTo', value);
    }

    /**
    * * Field Name: IsEnabled
    * * Display Name: Is Enabled
    * * SQL Data Type: bit
    * * Default Value: 1
    */
    get IsEnabled(): boolean {
        return this.Get('IsEnabled');
    }
    set IsEnabled(value: boolean) {
        this.Set('IsEnabled', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: ActivitySyncRuleSet
    * * Display Name: Rule Set Name
    * * SQL Data Type: nvarchar(200)
    */
    get ActivitySyncRuleSet(): string | null {
        return this.Get('ActivitySyncRuleSet');
    }

    /**
    * * Field Name: Person
    * * Display Name: Person Name
    * * SQL Data Type: nvarchar(201)
    */
    get Person(): string | null {
        return this.Get('Person');
    }
}


/**
 * MJ_BizApps_Common: Activity Sync Extensions - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: ActivitySyncExtension
 * * Base View: vwActivitySyncExtensions
 * * @description Registration of an in-process enrichment plugin that runs inside the Activity write transaction. Common ships this table; each consumer app ships its own rows, so a downstream app adds links (a deal, a campaign) without Common knowing it exists. Extensions ENRICH — they never veto an activity, because qualification has already run and capture must not depend on which apps are installed.
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Activity Sync Extensions')
export class mjBizAppsCommonActivitySyncExtensionEntity extends BaseEntity<mjBizAppsCommonActivitySyncExtensionEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Activity Sync Extensions record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Activity Sync Extensions record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonActivitySyncExtensionEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: Name
    * * Display Name: Name
    * * SQL Data Type: nvarchar(200)
    */
    get Name(): string {
        return this.Get('Name');
    }
    set Name(value: string) {
        this.Set('Name', value);
    }

    /**
    * * Field Name: Description
    * * Display Name: Description
    * * SQL Data Type: nvarchar(MAX)
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: DriverClass
    * * Display Name: Driver Class
    * * SQL Data Type: nvarchar(200)
    */
    get DriverClass(): string {
        return this.Get('DriverClass');
    }
    set DriverClass(value: string) {
        this.Set('DriverClass', value);
    }

    /**
    * * Field Name: ActivitySyncConnectionID
    * * Display Name: Activity Sync Connection
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Connections (vwActivitySyncConnections.ID)
    */
    get ActivitySyncConnectionID(): string | null {
        return this.Get('ActivitySyncConnectionID');
    }
    set ActivitySyncConnectionID(value: string | null) {
        this.Set('ActivitySyncConnectionID', value);
    }

    /**
    * * Field Name: ActivitySyncProviderTypeID
    * * Display Name: Activity Sync Provider Type
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Provider Types (vwActivitySyncProviderTypes.ID)
    */
    get ActivitySyncProviderTypeID(): string | null {
        return this.Get('ActivitySyncProviderTypeID');
    }
    set ActivitySyncProviderTypeID(value: string | null) {
        this.Set('ActivitySyncProviderTypeID', value);
    }

    /**
    * * Field Name: Sequence
    * * Display Name: Sequence
    * * SQL Data Type: int
    * * Default Value: 0
    * * Description: Ascending run order. REQUIRED rather than incidental: two extensions both adding links must not depend on registration order, which varies with package load order and is not reproducible.
    */
    get Sequence(): number {
        return this.Get('Sequence');
    }
    set Sequence(value: number) {
        this.Set('Sequence', value);
    }

    /**
    * * Field Name: FailurePolicy
    * * Display Name: Failure Policy
    * * SQL Data Type: nvarchar(20)
    * * Default Value: Skip
    * * Value List Type: List
    * * Possible Values 
    *   * Abort
    *   * Skip
    * * Description: What happens when this extension throws. Skip (the default) records the error and commits the activity without the enrichment; Abort rolls the whole write back. Skip is the default because the activity is worth more than the enrichment, and one buggy consumer app must not be able to halt ingestion for every other app on the host.
    */
    get FailurePolicy(): 'Abort' | 'Skip' {
        return this.Get('FailurePolicy');
    }
    set FailurePolicy(value: 'Abort' | 'Skip') {
        this.Set('FailurePolicy', value);
    }

    /**
    * * Field Name: TimeoutMS
    * * Display Name: Timeout (ms)
    * * SQL Data Type: int
    * * Default Value: 5000
    */
    get TimeoutMS(): number {
        return this.Get('TimeoutMS');
    }
    set TimeoutMS(value: number) {
        this.Set('TimeoutMS', value);
    }

    /**
    * * Field Name: IsEnabled
    * * Display Name: Is Enabled
    * * SQL Data Type: bit
    * * Default Value: 1
    */
    get IsEnabled(): boolean {
        return this.Get('IsEnabled');
    }
    set IsEnabled(value: boolean) {
        this.Set('IsEnabled', value);
    }

    /**
    * * Field Name: LastRunAt
    * * Display Name: Last Run At
    * * SQL Data Type: datetimeoffset
    */
    get LastRunAt(): Date | null {
        return this.Get('LastRunAt');
    }
    set LastRunAt(value: Date | null) {
        this.Set('LastRunAt', value);
    }

    /**
    * * Field Name: LastError
    * * Display Name: Last Error
    * * SQL Data Type: nvarchar(MAX)
    */
    get LastError(): string | null {
        return this.Get('LastError');
    }
    set LastError(value: string | null) {
        this.Set('LastError', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: ActivitySyncConnection
    * * Display Name: Activity Sync Connection (Name)
    * * SQL Data Type: nvarchar(200)
    */
    get ActivitySyncConnection(): string | null {
        return this.Get('ActivitySyncConnection');
    }

    /**
    * * Field Name: ActivitySyncProviderType
    * * Display Name: Activity Sync Provider Type (Name)
    * * SQL Data Type: nvarchar(100)
    */
    get ActivitySyncProviderType(): string | null {
        return this.Get('ActivitySyncProviderType');
    }
}


/**
 * MJ_BizApps_Common: Activity Sync Provider Types - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: ActivitySyncProviderType
 * * Base View: vwActivitySyncProviderTypes
 * * @description A kind of activity source (Microsoft365, Gmail, Twilio SMS, LinkedIn, …). Provider identity is DATA, not a CHECK constraint, so a new source is a new plugin package plus a metadata row — never a migration to Common. Also carries the DEFAULTS an operator should set once per provider rather than per mailbox: storage, encryption key, attachment cap, and what an undecided qualification verdict means.
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Activity Sync Provider Types')
export class mjBizAppsCommonActivitySyncProviderTypeEntity extends BaseEntity<mjBizAppsCommonActivitySyncProviderTypeEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Activity Sync Provider Types record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Activity Sync Provider Types record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonActivitySyncProviderTypeEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: Code
    * * Display Name: Code
    * * SQL Data Type: nvarchar(60)
    */
    get Code(): string {
        return this.Get('Code');
    }
    set Code(value: string) {
        this.Set('Code', value);
    }

    /**
    * * Field Name: Name
    * * Display Name: Name
    * * SQL Data Type: nvarchar(100)
    */
    get Name(): string {
        return this.Get('Name');
    }
    set Name(value: string) {
        this.Set('Name', value);
    }

    /**
    * * Field Name: Description
    * * Display Name: Description
    * * SQL Data Type: nvarchar(MAX)
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: DriverClass
    * * Display Name: Driver Class
    * * SQL Data Type: nvarchar(200)
    */
    get DriverClass(): string | null {
        return this.Get('DriverClass');
    }
    set DriverClass(value: string | null) {
        this.Set('DriverClass', value);
    }

    /**
    * * Field Name: IconClass
    * * Display Name: Icon Class
    * * SQL Data Type: nvarchar(100)
    */
    get IconClass(): string | null {
        return this.Get('IconClass');
    }
    set IconClass(value: string | null) {
        this.Set('IconClass', value);
    }

    /**
    * * Field Name: SupportedKinds
    * * Display Name: Supported Kinds
    * * SQL Data Type: nvarchar(MAX)
    */
    get SupportedKinds(): string | null {
        return this.Get('SupportedKinds');
    }
    set SupportedKinds(value: string | null) {
        this.Set('SupportedKinds', value);
    }

    /**
    * * Field Name: DefaultQualificationPolicy
    * * Display Name: Default Qualification Policy
    * * SQL Data Type: nvarchar(20)
    * * Default Value: Exclude
    * * Value List Type: List
    * * Possible Values 
    *   * Exclude
    *   * Include
    * * Description: What an Undecided qualification verdict means for this provider once every rule stage has abstained. Exclude (the default) fails CLOSED — correct for anything mailbox-shaped, where capturing a private message is worse than missing a business one.
    */
    get DefaultQualificationPolicy(): 'Exclude' | 'Include' {
        return this.Get('DefaultQualificationPolicy');
    }
    set DefaultQualificationPolicy(value: 'Exclude' | 'Include') {
        this.Set('DefaultQualificationPolicy', value);
    }

    /**
    * * Field Name: DefaultSkippedContentPolicy
    * * Display Name: Default Skipped Content Policy
    * * SQL Data Type: nvarchar(20)
    * * Default Value: None
    * * Value List Type: List
    * * Possible Values 
    *   * FullEncrypted
    *   * None
    *   * SubjectEncrypted
    * * Description: Whether a SKIPPED message may have content retained for audit, and how much. None keeps only the opaque external id and the decision. SubjectEncrypted and FullEncrypted additionally keep ciphertext, and are only valid with DefaultEncryptionKeyID set — enforced by CK_ActivitySyncProviderType_KeyRequired. Overridable per connection.
    */
    get DefaultSkippedContentPolicy(): 'FullEncrypted' | 'None' | 'SubjectEncrypted' {
        return this.Get('DefaultSkippedContentPolicy');
    }
    set DefaultSkippedContentPolicy(value: 'FullEncrypted' | 'None' | 'SubjectEncrypted') {
        this.Set('DefaultSkippedContentPolicy', value);
    }

    /**
    * * Field Name: DefaultEncryptionKeyID
    * * Display Name: Default Encryption Key ID
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ: Encryption Keys (vwEncryptionKeys.ID)
    */
    get DefaultEncryptionKeyID(): string | null {
        return this.Get('DefaultEncryptionKeyID');
    }
    set DefaultEncryptionKeyID(value: string | null) {
        this.Set('DefaultEncryptionKeyID', value);
    }

    /**
    * * Field Name: DefaultStorageProviderID
    * * Display Name: Default Storage Provider ID
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ: File Storage Providers (vwFileStorageProviders.ID)
    */
    get DefaultStorageProviderID(): string | null {
        return this.Get('DefaultStorageProviderID');
    }
    set DefaultStorageProviderID(value: string | null) {
        this.Set('DefaultStorageProviderID', value);
    }

    /**
    * * Field Name: DefaultMaxAttachmentBytes
    * * Display Name: Default Max Attachment Bytes
    * * SQL Data Type: bigint
    */
    get DefaultMaxAttachmentBytes(): number | null {
        return this.Get('DefaultMaxAttachmentBytes');
    }
    set DefaultMaxAttachmentBytes(value: number | null) {
        this.Set('DefaultMaxAttachmentBytes', value);
    }

    /**
    * * Field Name: Sequence
    * * Display Name: Sequence
    * * SQL Data Type: int
    * * Default Value: 0
    */
    get Sequence(): number {
        return this.Get('Sequence');
    }
    set Sequence(value: number) {
        this.Set('Sequence', value);
    }

    /**
    * * Field Name: IsSystem
    * * Display Name: Is System
    * * SQL Data Type: bit
    * * Default Value: 0
    */
    get IsSystem(): boolean {
        return this.Get('IsSystem');
    }
    set IsSystem(value: boolean) {
        this.Set('IsSystem', value);
    }

    /**
    * * Field Name: IsActive
    * * Display Name: Is Active
    * * SQL Data Type: bit
    * * Default Value: 1
    */
    get IsActive(): boolean {
        return this.Get('IsActive');
    }
    set IsActive(value: boolean) {
        this.Set('IsActive', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: DefaultEncryptionKey
    * * Display Name: Default Encryption Key
    * * SQL Data Type: nvarchar(100)
    */
    get DefaultEncryptionKey(): string | null {
        return this.Get('DefaultEncryptionKey');
    }

    /**
    * * Field Name: DefaultStorageProvider
    * * Display Name: Default Storage Provider
    * * SQL Data Type: nvarchar(50)
    */
    get DefaultStorageProvider(): string | null {
        return this.Get('DefaultStorageProvider');
    }
}


/**
 * MJ_BizApps_Common: Activity Sync Rule Sets - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: ActivitySyncRuleSet
 * * Base View: vwActivitySyncRuleSets
 * * @description A NAMED, REUSABLE set of rules bound to many connections. Rules used to hang off a single connection, so an org-wide prohibition had to be retyped for every mailbox and a new mailbox started with none — governance by copy-paste. A rule set is authored once and bound wherever it applies.
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Activity Sync Rule Sets')
export class mjBizAppsCommonActivitySyncRuleSetEntity extends BaseEntity<mjBizAppsCommonActivitySyncRuleSetEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Activity Sync Rule Sets record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Activity Sync Rule Sets record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonActivitySyncRuleSetEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: Name
    * * Display Name: Name
    * * SQL Data Type: nvarchar(200)
    */
    get Name(): string {
        return this.Get('Name');
    }
    set Name(value: string) {
        this.Set('Name', value);
    }

    /**
    * * Field Name: Description
    * * Display Name: Description
    * * SQL Data Type: nvarchar(MAX)
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: ActivitySyncProviderTypeID
    * * Display Name: Activity Sync Provider Type ID
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Provider Types (vwActivitySyncProviderTypes.ID)
    */
    get ActivitySyncProviderTypeID(): string | null {
        return this.Get('ActivitySyncProviderTypeID');
    }
    set ActivitySyncProviderTypeID(value: string | null) {
        this.Set('ActivitySyncProviderTypeID', value);
    }

    /**
    * * Field Name: InternalDomains
    * * Display Name: Internal Domains
    * * SQL Data Type: nvarchar(MAX)
    * * Description: JSON array of the domains this deployment considers INTERNAL, e.g. ["bluecypress.io"]. Required for any rule using ParticipantScope: "internal" is a property of the deployment, not of a message. Held on the rule set so one definition serves every mailbox bound to it.
    */
    get InternalDomains(): string | null {
        return this.Get('InternalDomains');
    }
    set InternalDomains(value: string | null) {
        this.Set('InternalDomains', value);
    }

    /**
    * * Field Name: Sequence
    * * Display Name: Sequence
    * * SQL Data Type: int
    * * Default Value: 0
    */
    get Sequence(): number {
        return this.Get('Sequence');
    }
    set Sequence(value: number) {
        this.Set('Sequence', value);
    }

    /**
    * * Field Name: IsEnabled
    * * Display Name: Is Enabled
    * * SQL Data Type: bit
    * * Default Value: 1
    */
    get IsEnabled(): boolean {
        return this.Get('IsEnabled');
    }
    set IsEnabled(value: boolean) {
        this.Set('IsEnabled', value);
    }

    /**
    * * Field Name: IsSystem
    * * Display Name: Is System
    * * SQL Data Type: bit
    * * Default Value: 0
    */
    get IsSystem(): boolean {
        return this.Get('IsSystem');
    }
    set IsSystem(value: boolean) {
        this.Set('IsSystem', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: ActivitySyncProviderType
    * * Display Name: Activity Sync Provider Type
    * * SQL Data Type: nvarchar(100)
    */
    get ActivitySyncProviderType(): string | null {
        return this.Get('ActivitySyncProviderType');
    }
}


/**
 * MJ_BizApps_Common: Activity Sync Rules - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: ActivitySyncRule
 * * Base View: vwActivitySyncRules
 * * @description Include/exclude rule for an ActivitySyncConnection: type, direction, date window, attachments, plus a JSON Filter (folders, domains, participant-must-match-ContactMethod).
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Activity Sync Rules')
export class mjBizAppsCommonActivitySyncRuleEntity extends BaseEntity<mjBizAppsCommonActivitySyncRuleEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Activity Sync Rules record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Activity Sync Rules record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonActivitySyncRuleEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: ActivitySyncConnectionID
    * * Display Name: Sync Connection
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Connections (vwActivitySyncConnections.ID)
    */
    get ActivitySyncConnectionID(): string | null {
        return this.Get('ActivitySyncConnectionID');
    }
    set ActivitySyncConnectionID(value: string | null) {
        this.Set('ActivitySyncConnectionID', value);
    }

    /**
    * * Field Name: Name
    * * Display Name: Rule Name
    * * SQL Data Type: nvarchar(200)
    * * Description: Display name of the rule.
    */
    get Name(): string {
        return this.Get('Name');
    }
    set Name(value: string) {
        this.Set('Name', value);
    }

    /**
    * * Field Name: IsEnabled
    * * Display Name: Is Enabled
    * * SQL Data Type: bit
    * * Default Value: 1
    * * Description: 0 skips the rule without deleting it.
    */
    get IsEnabled(): boolean {
        return this.Get('IsEnabled');
    }
    set IsEnabled(value: boolean) {
        this.Set('IsEnabled', value);
    }

    /**
    * * Field Name: Sequence
    * * Display Name: Sequence
    * * SQL Data Type: int
    * * Default Value: 0
    * * Description: Evaluation order within the connection. Lower first.
    */
    get Sequence(): number {
        return this.Get('Sequence');
    }
    set Sequence(value: number) {
        this.Set('Sequence', value);
    }

    /**
    * * Field Name: Action
    * * Display Name: Action
    * * SQL Data Type: nvarchar(20)
    * * Default Value: Include
    * * Value List Type: List
    * * Possible Values 
    *   * Exclude
    *   * Include
    * * Description: Include or Exclude matching items. With no rules, the engine syncs everything the connection can see.
    */
    get Action(): 'Exclude' | 'Include' {
        return this.Get('Action');
    }
    set Action(value: 'Exclude' | 'Include') {
        this.Set('Action', value);
    }

    /**
    * * Field Name: ActivityTypeID
    * * Display Name: Activity Type
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Types (vwActivityTypes.ID)
    */
    get ActivityTypeID(): string | null {
        return this.Get('ActivityTypeID');
    }
    set ActivityTypeID(value: string | null) {
        this.Set('ActivityTypeID', value);
    }

    /**
    * * Field Name: Direction
    * * Display Name: Direction
    * * SQL Data Type: nvarchar(20)
    * * Value List Type: List
    * * Possible Values 
    *   * Inbound
    *   * Internal
    *   * Outbound
    * * Description: Optional direction filter (Inbound / Outbound / Internal). Null = any.
    */
    get Direction(): 'Inbound' | 'Internal' | 'Outbound' | null {
        return this.Get('Direction');
    }
    set Direction(value: 'Inbound' | 'Internal' | 'Outbound' | null) {
        this.Set('Direction', value);
    }

    /**
    * * Field Name: DateFrom
    * * Display Name: Sync From
    * * SQL Data Type: datetimeoffset
    * * Description: Inclusive lower bound of the sync window. Null = no lower bound.
    */
    get DateFrom(): Date | null {
        return this.Get('DateFrom');
    }
    set DateFrom(value: Date | null) {
        this.Set('DateFrom', value);
    }

    /**
    * * Field Name: DateTo
    * * Display Name: Sync To
    * * SQL Data Type: datetimeoffset
    * * Description: Inclusive upper bound of the sync window. Null = no upper bound.
    */
    get DateTo(): Date | null {
        return this.Get('DateTo');
    }
    set DateTo(value: Date | null) {
        this.Set('DateTo', value);
    }

    /**
    * * Field Name: IncludeAttachments
    * * Display Name: Include Attachments
    * * SQL Data Type: bit
    * * Default Value: 0
    * * Description: 1 = also pull attachments into ActivityFile rows.
    */
    get IncludeAttachments(): boolean {
        return this.Get('IncludeAttachments');
    }
    set IncludeAttachments(value: boolean) {
        this.Set('IncludeAttachments', value);
    }

    /**
    * * Field Name: Filter
    * * Display Name: Filter Rules
    * * SQL Data Type: nvarchar(MAX)
    * * Description: JSON match extras: Folders, ExcludeFolders, Domains, ExcludeDomains, ParticipantMustMatchContactMethod, SubjectContains, SubjectExcludes. See ActivitySyncRuleFilter.
    */
    get Filter(): string | null {
        return this.Get('Filter');
    }
    set Filter(value: string | null) {
        this.Set('Filter', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: ActivitySyncRuleSetID
    * * Display Name: Sync Rule Set
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Rule Sets (vwActivitySyncRuleSets.ID)
    * * Description: The rule set this rule belongs to. Exactly one of ActivitySyncRuleSetID and ActivitySyncConnectionID is set (CK_ActivitySyncRule_Owner) — the connection form is the deprecated original and remains only so existing rows stay valid.
    */
    get ActivitySyncRuleSetID(): string | null {
        return this.Get('ActivitySyncRuleSetID');
    }
    set ActivitySyncRuleSetID(value: string | null) {
        this.Set('ActivitySyncRuleSetID', value);
    }

    /**
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
    * * Description: Which participants must be present for this rule to apply — the internal/external control. AllInternal excludes purely internal chatter; HasExternal catches a thread with any outside party on it; Mixed is the case an all-or-nothing rule gets wrong. Requires the rule set to define InternalDomains. Null means the rule does not test participants.
    */
    get ParticipantScope(): 'AllExternal' | 'AllInternal' | 'Any' | 'HasExternal' | 'HasInternal' | 'Mixed' | null {
        return this.Get('ParticipantScope');
    }
    set ParticipantScope(value: 'AllExternal' | 'AllInternal' | 'Any' | 'HasExternal' | 'HasInternal' | 'Mixed' | null) {
        this.Set('ParticipantScope', value);
    }

    /**
    * * Field Name: MaxAttachmentBytes
    * * Display Name: Max Attachment Size (Bytes)
    * * SQL Data Type: bigint
    */
    get MaxAttachmentBytes(): number | null {
        return this.Get('MaxAttachmentBytes');
    }
    set MaxAttachmentBytes(value: number | null) {
        this.Set('MaxAttachmentBytes', value);
    }

    /**
    * * Field Name: ActivitySyncConnection
    * * Display Name: Sync Connection Name
    * * SQL Data Type: nvarchar(200)
    */
    get ActivitySyncConnection(): string | null {
        return this.Get('ActivitySyncConnection');
    }

    /**
    * * Field Name: ActivityType
    * * Display Name: Activity Type Name
    * * SQL Data Type: nvarchar(100)
    */
    get ActivityType(): string | null {
        return this.Get('ActivityType');
    }

    /**
    * * Field Name: ActivitySyncRuleSet
    * * Display Name: Sync Rule Set Name
    * * SQL Data Type: nvarchar(200)
    */
    get ActivitySyncRuleSet(): string | null {
        return this.Get('ActivitySyncRuleSet');
    }
}


/**
 * MJ_BizApps_Common: Activity Sync Run Details - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: ActivitySyncRunDetail
 * * Base View: vwActivitySyncRunDetails
 * * @description The decision made about ONE message, written for every item considered INCLUDING every skip — which is what makes "why did my email not appear" answerable. ExternalID and the decision are always safe to keep: an opaque provider id and the name of a rule, not content. CapturedContent is different in kind and is governed by the effective SkippedContentPolicy. Give this entity permissions DISTINCT from Activity: it can hold fragments of messages that were deliberately not ingested.
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Activity Sync Run Details')
export class mjBizAppsCommonActivitySyncRunDetailEntity extends BaseEntity<mjBizAppsCommonActivitySyncRunDetailEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Activity Sync Run Details record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Activity Sync Run Details record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonActivitySyncRunDetailEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: ActivitySyncRunID
    * * Display Name: Activity Sync Run
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Runs (vwActivitySyncRuns.ID)
    */
    get ActivitySyncRunID(): string {
        return this.Get('ActivitySyncRunID');
    }
    set ActivitySyncRunID(value: string) {
        this.Set('ActivitySyncRunID', value);
    }

    /**
    * * Field Name: ExternalID
    * * Display Name: External ID
    * * SQL Data Type: nvarchar(400)
    */
    get ExternalID(): string {
        return this.Get('ExternalID');
    }
    set ExternalID(value: string) {
        this.Set('ExternalID', value);
    }

    /**
    * * Field Name: ExternalThreadID
    * * Display Name: External Thread ID
    * * SQL Data Type: nvarchar(400)
    */
    get ExternalThreadID(): string | null {
        return this.Get('ExternalThreadID');
    }
    set ExternalThreadID(value: string | null) {
        this.Set('ExternalThreadID', value);
    }

    /**
    * * Field Name: OccurredAt
    * * Display Name: Occurred At
    * * SQL Data Type: datetimeoffset
    */
    get OccurredAt(): Date | null {
        return this.Get('OccurredAt');
    }
    set OccurredAt(value: Date | null) {
        this.Set('OccurredAt', value);
    }

    /**
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
    *   * WouldInclude
    */
    get Decision(): 'Duplicate' | 'Excluded' | 'Failed' | 'Included' | 'WouldExclude' | 'WouldInclude' {
        return this.Get('Decision');
    }
    set Decision(value: 'Duplicate' | 'Excluded' | 'Failed' | 'Included' | 'WouldExclude' | 'WouldInclude') {
        this.Set('Decision', value);
    }

    /**
    * * Field Name: DecidedByStage
    * * Display Name: Decided By Stage
    * * SQL Data Type: nvarchar(100)
    * * Description: Which stage of the qualification cascade decided — a rule set name, KnownParticipant, Inference, or DefaultPolicy. Paired with Reason it explains an outcome without retaining the message that produced it.
    */
    get DecidedByStage(): string | null {
        return this.Get('DecidedByStage');
    }
    set DecidedByStage(value: string | null) {
        this.Set('DecidedByStage', value);
    }

    /**
    * * Field Name: ActivitySyncRuleID
    * * Display Name: Activity Sync Rule
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Rules (vwActivitySyncRules.ID)
    */
    get ActivitySyncRuleID(): string | null {
        return this.Get('ActivitySyncRuleID');
    }
    set ActivitySyncRuleID(value: string | null) {
        this.Set('ActivitySyncRuleID', value);
    }

    /**
    * * Field Name: ActivitySyncExclusionID
    * * Display Name: Activity Sync Exclusion
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Exclusions (vwActivitySyncExclusions.ID)
    */
    get ActivitySyncExclusionID(): string | null {
        return this.Get('ActivitySyncExclusionID');
    }
    set ActivitySyncExclusionID(value: string | null) {
        this.Set('ActivitySyncExclusionID', value);
    }

    /**
    * * Field Name: Reason
    * * Display Name: Reason
    * * SQL Data Type: nvarchar(MAX)
    */
    get Reason(): string | null {
        return this.Get('Reason');
    }
    set Reason(value: string | null) {
        this.Set('Reason', value);
    }

    /**
    * * Field Name: Confidence
    * * Display Name: Confidence
    * * SQL Data Type: decimal(5, 4)
    */
    get Confidence(): number | null {
        return this.Get('Confidence');
    }
    set Confidence(value: number | null) {
        this.Set('Confidence', value);
    }

    /**
    * * Field Name: AIPromptRunID
    * * Display Name: AI Prompt Run
    * * SQL Data Type: uniqueidentifier
    * * Description: The MJ: AI Prompt Run behind an inference-stage verdict. Non-null only when a model actually decided this item, which is the audit trail for every automated judgement the engine makes.
    */
    get AIPromptRunID(): string | null {
        return this.Get('AIPromptRunID');
    }
    set AIPromptRunID(value: string | null) {
        this.Set('AIPromptRunID', value);
    }

    /**
    * * Field Name: ActivityID
    * * Display Name: Activity
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activities (vwActivities.ID)
    */
    get ActivityID(): string | null {
        return this.Get('ActivityID');
    }
    set ActivityID(value: string | null) {
        this.Set('ActivityID', value);
    }

    /**
    * * Field Name: CapturedContent
    * * Display Name: Captured Content
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Ciphertext, always — never plaintext, whatever the policy. Present only when the effective SkippedContentPolicy allows retention, and always paired with the EncryptionKeyID that opens it (CK_ActivitySyncRunDetail_ContentKey). Encrypted through MJ's EncryptionEngine against an MJ: Encryption Keys row; this app never implements its own crypto.
    */
    get CapturedContent(): string | null {
        return this.Get('CapturedContent');
    }
    set CapturedContent(value: string | null) {
        this.Set('CapturedContent', value);
    }

    /**
    * * Field Name: EncryptionKeyID
    * * Display Name: Encryption Key
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ: Encryption Keys (vwEncryptionKeys.ID)
    */
    get EncryptionKeyID(): string | null {
        return this.Get('EncryptionKeyID');
    }
    set EncryptionKeyID(value: string | null) {
        this.Set('EncryptionKeyID', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: ActivitySyncRule
    * * Display Name: Activity Sync Rule Name
    * * SQL Data Type: nvarchar(200)
    */
    get ActivitySyncRule(): string | null {
        return this.Get('ActivitySyncRule');
    }

    /**
    * * Field Name: Activity
    * * Display Name: Activity Reference
    * * SQL Data Type: nvarchar(500)
    */
    get Activity(): string | null {
        return this.Get('Activity');
    }

    /**
    * * Field Name: EncryptionKey
    * * Display Name: Encryption Key Name
    * * SQL Data Type: nvarchar(100)
    */
    get EncryptionKey(): string | null {
        return this.Get('EncryptionKey');
    }
}


/**
 * MJ_BizApps_Common: Activity Sync Runs - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: ActivitySyncRun
 * * Base View: vwActivitySyncRuns
 * * @description One sync pass over one connection: what it fetched, what it decided, and whether it earned the right to move the watermark. A dry run is a real row with IsDryRun set — it evaluates and reports without writing an Activity or advancing the connection.
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Activity Sync Runs')
export class mjBizAppsCommonActivitySyncRunEntity extends BaseEntity<mjBizAppsCommonActivitySyncRunEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Activity Sync Runs record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Activity Sync Runs record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonActivitySyncRunEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: ActivitySyncConnectionID
    * * Display Name: Connection ID
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Connections (vwActivitySyncConnections.ID)
    */
    get ActivitySyncConnectionID(): string {
        return this.Get('ActivitySyncConnectionID');
    }
    set ActivitySyncConnectionID(value: string) {
        this.Set('ActivitySyncConnectionID', value);
    }

    /**
    * * Field Name: StartedAt
    * * Display Name: Started At
    * * SQL Data Type: datetimeoffset
    * * Default Value: sysdatetimeoffset()
    */
    get StartedAt(): Date {
        return this.Get('StartedAt');
    }
    set StartedAt(value: Date) {
        this.Set('StartedAt', value);
    }

    /**
    * * Field Name: EndedAt
    * * Display Name: Ended At
    * * SQL Data Type: datetimeoffset
    */
    get EndedAt(): Date | null {
        return this.Get('EndedAt');
    }
    set EndedAt(value: Date | null) {
        this.Set('EndedAt', value);
    }

    /**
    * * Field Name: Status
    * * Display Name: Status
    * * SQL Data Type: nvarchar(20)
    * * Default Value: Running
    * * Value List Type: List
    * * Possible Values 
    *   * Cancelled
    *   * Completed
    *   * Failed
    *   * Running
    */
    get Status(): 'Cancelled' | 'Completed' | 'Failed' | 'Running' {
        return this.Get('Status');
    }
    set Status(value: 'Cancelled' | 'Completed' | 'Failed' | 'Running') {
        this.Set('Status', value);
    }

    /**
    * * Field Name: TriggerType
    * * Display Name: Trigger Type
    * * SQL Data Type: nvarchar(20)
    * * Default Value: Scheduled
    * * Value List Type: List
    * * Possible Values 
    *   * Backfill
    *   * Manual
    *   * Scheduled
    *   * Webhook
    */
    get TriggerType(): 'Backfill' | 'Manual' | 'Scheduled' | 'Webhook' {
        return this.Get('TriggerType');
    }
    set TriggerType(value: 'Backfill' | 'Manual' | 'Scheduled' | 'Webhook') {
        this.Set('TriggerType', value);
    }

    /**
    * * Field Name: IsDryRun
    * * Display Name: Is Dry Run
    * * SQL Data Type: bit
    * * Default Value: 0
    */
    get IsDryRun(): boolean {
        return this.Get('IsDryRun');
    }
    set IsDryRun(value: boolean) {
        this.Set('IsDryRun', value);
    }

    /**
    * * Field Name: Fetched
    * * Display Name: Fetched Count
    * * SQL Data Type: int
    * * Default Value: 0
    */
    get Fetched(): number {
        return this.Get('Fetched');
    }
    set Fetched(value: number) {
        this.Set('Fetched', value);
    }

    /**
    * * Field Name: Included
    * * Display Name: Included Count
    * * SQL Data Type: int
    * * Default Value: 0
    */
    get Included(): number {
        return this.Get('Included');
    }
    set Included(value: number) {
        this.Set('Included', value);
    }

    /**
    * * Field Name: Excluded
    * * Display Name: Excluded Count
    * * SQL Data Type: int
    * * Default Value: 0
    */
    get Excluded(): number {
        return this.Get('Excluded');
    }
    set Excluded(value: number) {
        this.Set('Excluded', value);
    }

    /**
    * * Field Name: Duplicates
    * * Display Name: Duplicate Count
    * * SQL Data Type: int
    * * Default Value: 0
    */
    get Duplicates(): number {
        return this.Get('Duplicates');
    }
    set Duplicates(value: number) {
        this.Set('Duplicates', value);
    }

    /**
    * * Field Name: Failed
    * * Display Name: Failed Count
    * * SQL Data Type: int
    * * Default Value: 0
    */
    get Failed(): number {
        return this.Get('Failed');
    }
    set Failed(value: number) {
        this.Set('Failed', value);
    }

    /**
    * * Field Name: ExtensionErrors
    * * Display Name: Extension Errors
    * * SQL Data Type: int
    * * Default Value: 0
    */
    get ExtensionErrors(): number {
        return this.Get('ExtensionErrors');
    }
    set ExtensionErrors(value: number) {
        this.Set('ExtensionErrors', value);
    }

    /**
    * * Field Name: WatermarkBefore
    * * Display Name: Watermark Before
    * * SQL Data Type: datetimeoffset
    */
    get WatermarkBefore(): Date | null {
        return this.Get('WatermarkBefore');
    }
    set WatermarkBefore(value: Date | null) {
        this.Set('WatermarkBefore', value);
    }

    /**
    * * Field Name: WatermarkAfter
    * * Display Name: Watermark After
    * * SQL Data Type: datetimeoffset
    */
    get WatermarkAfter(): Date | null {
        return this.Get('WatermarkAfter');
    }
    set WatermarkAfter(value: Date | null) {
        this.Set('WatermarkAfter', value);
    }

    /**
    * * Field Name: ErrorMessage
    * * Display Name: Error Message
    * * SQL Data Type: nvarchar(MAX)
    */
    get ErrorMessage(): string | null {
        return this.Get('ErrorMessage');
    }
    set ErrorMessage(value: string | null) {
        this.Set('ErrorMessage', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: ActivitySyncConnection
    * * Display Name: Connection Name
    * * SQL Data Type: nvarchar(200)
    */
    get ActivitySyncConnection(): string {
        return this.Get('ActivitySyncConnection');
    }
}


/**
 * MJ_BizApps_Common: Activity Types - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: ActivityType
 * * Base View: vwActivityTypes
 * * @description Lookup of interaction channels (Email, Call, Meeting, Note, SMS, Chat). Hierarchy is picker-only; direction lives on Activity. Code is the stable key — sync and code target Code, never Name.
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Activity Types')
export class mjBizAppsCommonActivityTypeEntity extends BaseEntity<mjBizAppsCommonActivityTypeEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Activity Types record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Activity Types record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonActivityTypeEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: Code
    * * Display Name: Code
    * * SQL Data Type: nvarchar(50)
    * * Description: Stable key targeted by sync and code (Email, Call, Meeting, Note, SMS, Chat). Unique. Names can be renamed; codes cannot.
    */
    get Code(): string {
        return this.Get('Code');
    }
    set Code(value: string) {
        this.Set('Code', value);
    }

    /**
    * * Field Name: Name
    * * Display Name: Name
    * * SQL Data Type: nvarchar(100)
    * * Description: Display name for the picker and timeline.
    */
    get Name(): string {
        return this.Get('Name');
    }
    set Name(value: string) {
        this.Set('Name', value);
    }

    /**
    * * Field Name: Description
    * * Display Name: Description
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Optional longer description of the type.
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: ParentID
    * * Display Name: Parent ID
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Types (vwActivityTypes.ID)
    */
    get ParentID(): string | null {
        return this.Get('ParentID');
    }
    set ParentID(value: string | null) {
        this.Set('ParentID', value);
    }

    /**
    * * Field Name: IconClass
    * * Display Name: Icon Class
    * * SQL Data Type: nvarchar(100)
    * * Description: Font Awesome class for timeline chrome (e.g. fa-solid fa-envelope).
    */
    get IconClass(): string | null {
        return this.Get('IconClass');
    }
    set IconClass(value: string | null) {
        this.Set('IconClass', value);
    }

    /**
    * * Field Name: Color
    * * Display Name: Color
    * * SQL Data Type: nvarchar(30)
    * * Description: Optional categorical color for timeline chrome. Not a design-token — this is stored per type.
    */
    get Color(): string | null {
        return this.Get('Color');
    }
    set Color(value: string | null) {
        this.Set('Color', value);
    }

    /**
    * * Field Name: Sequence
    * * Display Name: Sequence
    * * SQL Data Type: int
    * * Default Value: 0
    * * Description: Picker sort order. Lower first.
    */
    get Sequence(): number {
        return this.Get('Sequence');
    }
    set Sequence(value: number) {
        this.Set('Sequence', value);
    }

    /**
    * * Field Name: IsSystem
    * * Display Name: Is System
    * * SQL Data Type: bit
    * * Default Value: 0
    * * Description: 1 = seeded system type the sync engine may assume (Email, Call, Meeting, Note, SMS, Chat). Clients add children with IsSystem = 0.
    */
    get IsSystem(): boolean {
        return this.Get('IsSystem');
    }
    set IsSystem(value: boolean) {
        this.Set('IsSystem', value);
    }

    /**
    * * Field Name: IsActive
    * * Display Name: Is Active
    * * SQL Data Type: bit
    * * Default Value: 1
    * * Description: 0 hides the type from the picker without deleting historical activities.
    */
    get IsActive(): boolean {
        return this.Get('IsActive');
    }
    set IsActive(value: boolean) {
        this.Set('IsActive', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: Parent
    * * Display Name: Parent
    * * SQL Data Type: nvarchar(100)
    */
    get Parent(): string | null {
        return this.Get('Parent');
    }

    /**
    * * Field Name: RootParentID
    * * Display Name: Root Parent ID
    * * SQL Data Type: uniqueidentifier
    */
    get RootParentID(): string | null {
        return this.Get('RootParentID');
    }

    /**
    * * Field Name: ParentIDDepth
    * * Display Name: Parent ID Depth
    * * SQL Data Type: int
    */
    get ParentIDDepth(): number | null {
        return this.Get('ParentIDDepth');
    }

    /**
    * * Field Name: ParentIDPath
    * * Display Name: Parent ID Path
    * * SQL Data Type: nvarchar(MAX)
    */
    get ParentIDPath(): string | null {
        return this.Get('ParentIDPath');
    }

    /**
    * * Field Name: ParentIDIsLeaf
    * * Display Name: Parent ID Is Leaf
    * * SQL Data Type: bit
    */
    get ParentIDIsLeaf(): boolean | null {
        return this.Get('ParentIDIsLeaf');
    }

    /**
    * * Field Name: ParentIDChildCount
    * * Display Name: Parent ID Child Count
    * * SQL Data Type: int
    */
    get ParentIDChildCount(): number | null {
        return this.Get('ParentIDChildCount');
    }
}


/**
 * MJ_BizApps_Common: Address Links - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: AddressLink
 * * Base View: vwAddressLinks
 * * @description Polymorphic link table connecting Address records to any entity record in the system via EntityID and RecordID
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Address Links')
export class mjBizAppsCommonAddressLinkEntity extends BaseEntity<mjBizAppsCommonAddressLinkEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Address Links record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Address Links record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonAddressLinkEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: AddressID
    * * Display Name: Address
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Addresses (vwAddresses.ID)
    */
    get AddressID(): string {
        return this.Get('AddressID');
    }
    set AddressID(value: string) {
        this.Set('AddressID', value);
    }

    /**
    * * Field Name: EntityID
    * * Display Name: Entity
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ: Entities (vwEntities.ID)
    */
    get EntityID(): string {
        return this.Get('EntityID');
    }
    set EntityID(value: string) {
        this.Set('EntityID', value);
    }

    /**
    * * Field Name: RecordID
    * * Display Name: Record ID
    * * SQL Data Type: nvarchar(700)
    * * Description: Primary key value(s) of the linked record. NVARCHAR(700) to support concatenated composite keys for entities without single-valued primary keys
    */
    get RecordID(): string {
        return this.Get('RecordID');
    }
    set RecordID(value: string) {
        this.Set('RecordID', value);
    }

    /**
    * * Field Name: AddressTypeID
    * * Display Name: Address Type
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Address Types (vwAddressTypes.ID)
    */
    get AddressTypeID(): string {
        return this.Get('AddressTypeID');
    }
    set AddressTypeID(value: string) {
        this.Set('AddressTypeID', value);
    }

    /**
    * * Field Name: IsPrimary
    * * Display Name: Is Primary
    * * SQL Data Type: bit
    * * Default Value: 0
    * * Description: Whether this is the primary address for the linked record. Only one address per entity record should be marked primary
    */
    get IsPrimary(): boolean {
        return this.Get('IsPrimary');
    }
    set IsPrimary(value: boolean) {
        this.Set('IsPrimary', value);
    }

    /**
    * * Field Name: Rank
    * * Display Name: Rank
    * * SQL Data Type: int
    * * Description: Sort order override for this specific link. When NULL, falls back to AddressType.DefaultRank. Lower values appear first
    */
    get Rank(): number | null {
        return this.Get('Rank');
    }
    set Rank(value: number | null) {
        this.Set('Rank', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: Address
    * * Display Name: Address
    * * SQL Data Type: nvarchar(255)
    */
    get Address(): string {
        return this.Get('Address');
    }

    /**
    * * Field Name: Entity
    * * Display Name: Entity Name
    * * SQL Data Type: nvarchar(255)
    */
    get Entity(): string {
        return this.Get('Entity');
    }

    /**
    * * Field Name: AddressType
    * * Display Name: Address Type Name
    * * SQL Data Type: nvarchar(100)
    */
    get AddressType(): string {
        return this.Get('AddressType');
    }
}


/**
 * MJ_BizApps_Common: Address Types - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: AddressType
 * * Base View: vwAddressTypes
 * * @description Categories of addresses such as Home, Work, Mailing, Billing
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Address Types')
export class mjBizAppsCommonAddressTypeEntity extends BaseEntity<mjBizAppsCommonAddressTypeEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Address Types record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Address Types record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonAddressTypeEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: Name
    * * Display Name: Name
    * * SQL Data Type: nvarchar(100)
    * * Description: Display name for the address type
    */
    get Name(): string {
        return this.Get('Name');
    }
    set Name(value: string) {
        this.Set('Name', value);
    }

    /**
    * * Field Name: Description
    * * Display Name: Description
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Detailed description of this address type
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: IconClass
    * * Display Name: Icon Class
    * * SQL Data Type: nvarchar(100)
    * * Description: Font Awesome icon class for UI display
    */
    get IconClass(): string | null {
        return this.Get('IconClass');
    }
    set IconClass(value: string | null) {
        this.Set('IconClass', value);
    }

    /**
    * * Field Name: DefaultRank
    * * Display Name: Default Rank
    * * SQL Data Type: int
    * * Default Value: 100
    * * Description: Default sort order for this address type in dropdown lists. Lower values appear first. Can be overridden per-record via AddressLink.Rank
    */
    get DefaultRank(): number {
        return this.Get('DefaultRank');
    }
    set DefaultRank(value: number) {
        this.Set('DefaultRank', value);
    }

    /**
    * * Field Name: IsActive
    * * Display Name: Active
    * * SQL Data Type: bit
    * * Default Value: 1
    * * Description: Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records
    */
    get IsActive(): boolean {
        return this.Get('IsActive');
    }
    set IsActive(value: boolean) {
        this.Set('IsActive', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }
}


/**
 * MJ_BizApps_Common: Addresses - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: Address
 * * Base View: vwAddresses
 * * @description Standalone physical address records linked to entities via AddressLink for sharing across people and organizations
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Addresses')
export class mjBizAppsCommonAddressEntity extends BaseEntity<mjBizAppsCommonAddressEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Addresses record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Addresses record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonAddressEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: Line1
    * * Display Name: Address Line 1
    * * SQL Data Type: nvarchar(255)
    * * Description: Street address line 1
    */
    get Line1(): string {
        return this.Get('Line1');
    }
    set Line1(value: string) {
        this.Set('Line1', value);
    }

    /**
    * * Field Name: Line2
    * * Display Name: Address Line 2
    * * SQL Data Type: nvarchar(255)
    * * Description: Street address line 2 (suite, apt, etc.)
    */
    get Line2(): string | null {
        return this.Get('Line2');
    }
    set Line2(value: string | null) {
        this.Set('Line2', value);
    }

    /**
    * * Field Name: Line3
    * * Display Name: Address Line 3
    * * SQL Data Type: nvarchar(255)
    * * Description: Street address line 3 (additional detail)
    */
    get Line3(): string | null {
        return this.Get('Line3');
    }
    set Line3(value: string | null) {
        this.Set('Line3', value);
    }

    /**
    * * Field Name: City
    * * Display Name: City
    * * SQL Data Type: nvarchar(100)
    * * Description: City or locality name
    */
    get City(): string {
        return this.Get('City');
    }
    set City(value: string) {
        this.Set('City', value);
    }

    /**
    * * Field Name: StateProvince
    * * Display Name: State / Province
    * * SQL Data Type: nvarchar(100)
    * * Description: State, province, or region
    */
    get StateProvince(): string | null {
        return this.Get('StateProvince');
    }
    set StateProvince(value: string | null) {
        this.Set('StateProvince', value);
    }

    /**
    * * Field Name: PostalCode
    * * Display Name: Postal Code
    * * SQL Data Type: nvarchar(20)
    * * Description: Postal or ZIP code
    */
    get PostalCode(): string | null {
        return this.Get('PostalCode');
    }
    set PostalCode(value: string | null) {
        this.Set('PostalCode', value);
    }

    /**
    * * Field Name: Country
    * * Display Name: Country
    * * SQL Data Type: nvarchar(100)
    * * Default Value: US
    * * Description: Country code or name, defaults to US
    */
    get Country(): string {
        return this.Get('Country');
    }
    set Country(value: string) {
        this.Set('Country', value);
    }

    /**
    * * Field Name: Latitude
    * * Display Name: Latitude
    * * SQL Data Type: decimal(9, 6)
    * * Description: Geographic latitude for mapping
    */
    get Latitude(): number | null {
        return this.Get('Latitude');
    }
    set Latitude(value: number | null) {
        this.Set('Latitude', value);
    }

    /**
    * * Field Name: Longitude
    * * Display Name: Longitude
    * * SQL Data Type: decimal(9, 6)
    * * Description: Geographic longitude for mapping
    */
    get Longitude(): number | null {
        return this.Get('Longitude');
    }
    set Longitude(value: number | null) {
        this.Set('Longitude', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }
}


/**
 * MJ_BizApps_Common: Contact Methods - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: ContactMethod
 * * Base View: vwContactMethods
 * * @description Additional contact methods for people and organizations beyond the primary email and phone fields
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Contact Methods')
export class mjBizAppsCommonContactMethodEntity extends BaseEntity<mjBizAppsCommonContactMethodEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Contact Methods record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Contact Methods record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonContactMethodEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * Validate() method override for MJ_BizApps_Common: Contact Methods entity. This is an auto-generated method that invokes the generated validators for this entity for the following fields:
    * * Table-Level: Each record must be linked to either a person or an organization. This ensures that contact information is correctly attributed to exactly one entity and prevents data ambiguity caused by having both or neither assigned.
    * @public
    * @method
    * @override
    */
    public override Validate(): ValidationResult {
        const result = super.Validate();
        this.ValidatePersonIDOrOrganizationIDExclusivity(result);
        result.Success = result.Success && (result.Errors.length === 0);

        return result;
    }

    /**
    * Each record must be linked to either a person or an organization. This ensures that contact information is correctly attributed to exactly one entity and prevents data ambiguity caused by having both or neither assigned.
    * @param result - the ValidationResult object to add any errors or warnings to
    * @public
    * @method
    */
    public ValidatePersonIDOrOrganizationIDExclusivity(result: ValidationResult) {
    	// Check if both fields are null or if both fields are populated
    	const hasPerson = this.PersonID != null;
    	const hasOrganization = this.OrganizationID != null;
    
    	if (hasPerson === hasOrganization) {
    		const errorMessage = "Each record must be associated with either a person or an organization, but not both.";
    		result.Errors.push(new ValidationErrorInfo(
    			"PersonID",
    			errorMessage,
    			this.PersonID,
    			ValidationErrorType.Failure
    		));
    		result.Errors.push(new ValidationErrorInfo(
    			"OrganizationID",
    			errorMessage,
    			this.OrganizationID,
    			ValidationErrorType.Failure
    		));
    	}
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: PersonID
    * * Display Name: Person
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: People (vwPeople.ID)
    */
    get PersonID(): string | null {
        return this.Get('PersonID');
    }
    set PersonID(value: string | null) {
        this.Set('PersonID', value);
    }

    /**
    * * Field Name: OrganizationID
    * * Display Name: Organization
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Organizations (vwOrganizations.ID)
    */
    get OrganizationID(): string | null {
        return this.Get('OrganizationID');
    }
    set OrganizationID(value: string | null) {
        this.Set('OrganizationID', value);
    }

    /**
    * * Field Name: ContactTypeID
    * * Display Name: Contact Type
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Contact Types (vwContactTypes.ID)
    */
    get ContactTypeID(): string {
        return this.Get('ContactTypeID');
    }
    set ContactTypeID(value: string) {
        this.Set('ContactTypeID', value);
    }

    /**
    * * Field Name: Value
    * * Display Name: Contact Value
    * * SQL Data Type: nvarchar(500)
    * * Description: The contact value: phone number, email address, URL, social media handle, etc.
    */
    get Value(): string {
        return this.Get('Value');
    }
    set Value(value: string) {
        this.Set('Value', value);
    }

    /**
    * * Field Name: Label
    * * Display Name: Label
    * * SQL Data Type: nvarchar(100)
    * * Description: Descriptive label such as Work cell, Personal Gmail, Corporate LinkedIn
    */
    get Label(): string | null {
        return this.Get('Label');
    }
    set Label(value: string | null) {
        this.Set('Label', value);
    }

    /**
    * * Field Name: IsPrimary
    * * Display Name: Is Primary
    * * SQL Data Type: bit
    * * Default Value: 0
    * * Description: Whether this is the primary contact method of its type for the linked person or organization
    */
    get IsPrimary(): boolean {
        return this.Get('IsPrimary');
    }
    set IsPrimary(value: boolean) {
        this.Set('IsPrimary', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: Person
    * * Display Name: Person
    * * SQL Data Type: nvarchar(201)
    */
    get Person(): string | null {
        return this.Get('Person');
    }

    /**
    * * Field Name: Organization
    * * Display Name: Organization Name
    * * SQL Data Type: nvarchar(255)
    */
    get Organization(): string | null {
        return this.Get('Organization');
    }

    /**
    * * Field Name: ContactType
    * * Display Name: Contact Type Name
    * * SQL Data Type: nvarchar(100)
    */
    get ContactType(): string {
        return this.Get('ContactType');
    }
}


/**
 * MJ_BizApps_Common: Contact Types - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: ContactType
 * * Base View: vwContactTypes
 * * @description Categories of contact methods such as Phone, Mobile, Email, LinkedIn, Website
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Contact Types')
export class mjBizAppsCommonContactTypeEntity extends BaseEntity<mjBizAppsCommonContactTypeEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Contact Types record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Contact Types record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonContactTypeEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: Name
    * * Display Name: Name
    * * SQL Data Type: nvarchar(100)
    * * Description: Display name for the contact type
    */
    get Name(): string {
        return this.Get('Name');
    }
    set Name(value: string) {
        this.Set('Name', value);
    }

    /**
    * * Field Name: Description
    * * Display Name: Description
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Detailed description of this contact type
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: IconClass
    * * Display Name: Icon Class
    * * SQL Data Type: nvarchar(100)
    * * Description: Font Awesome icon class for UI display
    */
    get IconClass(): string | null {
        return this.Get('IconClass');
    }
    set IconClass(value: string | null) {
        this.Set('IconClass', value);
    }

    /**
    * * Field Name: DisplayRank
    * * Display Name: Display Rank
    * * SQL Data Type: int
    * * Default Value: 100
    * * Description: Sort order in dropdown lists. Lower values appear first
    */
    get DisplayRank(): number {
        return this.Get('DisplayRank');
    }
    set DisplayRank(value: number) {
        this.Set('DisplayRank', value);
    }

    /**
    * * Field Name: IsActive
    * * Display Name: Is Active
    * * SQL Data Type: bit
    * * Default Value: 1
    * * Description: Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records
    */
    get IsActive(): boolean {
        return this.Get('IsActive');
    }
    set IsActive(value: boolean) {
        this.Set('IsActive', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }
}


/**
 * MJ_BizApps_Common: Organization Types - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: OrganizationType
 * * Base View: vwOrganizationTypes
 * * @description Categories of organizations such as Company, Non-Profit, Association, Government
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Organization Types')
export class mjBizAppsCommonOrganizationTypeEntity extends BaseEntity<mjBizAppsCommonOrganizationTypeEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Organization Types record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Organization Types record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonOrganizationTypeEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: Name
    * * Display Name: Name
    * * SQL Data Type: nvarchar(100)
    * * Description: Display name for the organization type
    */
    get Name(): string {
        return this.Get('Name');
    }
    set Name(value: string) {
        this.Set('Name', value);
    }

    /**
    * * Field Name: Description
    * * Display Name: Description
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Detailed description of this organization type
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: IconClass
    * * Display Name: Icon Class
    * * SQL Data Type: nvarchar(100)
    * * Description: Font Awesome icon class for UI display
    */
    get IconClass(): string | null {
        return this.Get('IconClass');
    }
    set IconClass(value: string | null) {
        this.Set('IconClass', value);
    }

    /**
    * * Field Name: DisplayRank
    * * Display Name: Display Rank
    * * SQL Data Type: int
    * * Default Value: 100
    * * Description: Sort order in dropdown lists. Lower values appear first
    */
    get DisplayRank(): number {
        return this.Get('DisplayRank');
    }
    set DisplayRank(value: number) {
        this.Set('DisplayRank', value);
    }

    /**
    * * Field Name: IsActive
    * * Display Name: Active
    * * SQL Data Type: bit
    * * Default Value: 1
    * * Description: Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records
    */
    get IsActive(): boolean {
        return this.Get('IsActive');
    }
    set IsActive(value: boolean) {
        this.Set('IsActive', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }
}


/**
 * MJ_BizApps_Common: Organizations - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: Organization
 * * Base View: vwOrganizations
 * * @description Companies, associations, government bodies, and other organizations with hierarchy support
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Organizations')
export class mjBizAppsCommonOrganizationEntity extends BaseEntity<mjBizAppsCommonOrganizationEntityType> {

  /**
  * Related records: MJ_BizApps_Common: Organizations
  *
  * Loads, validates and persists as one unit with this MJ_BizApps_Common: Organizations record — see
  * guides/TRANSACTIONS_AND_BATCHING_GUIDE.md. Declared by the RelatedRecordCollection metadata on
  * the 'MJ_BizApps_Common: Organizations → MJ_BizApps_Common: Organizations' relationship; edit that row, not this file.
  *
  */
  public readonly ChildOrganizations = this.DeclareRelatedRecords<mjBizAppsCommonOrganizationEntity>({
      Name: 'ChildOrganizations',
        RelatedEntity: 'MJ_BizApps_Common: Organizations',
        RelatedEntityJoinField: 'ParentID',
        Load: 'explicit',
        OnRemove: 'orphan',
  });


  /**
  * Related records: MJ_BizApps_Common: Contact Methods
  *
  * Loads, validates and persists as one unit with this MJ_BizApps_Common: Organizations record — see
  * guides/TRANSACTIONS_AND_BATCHING_GUIDE.md. Declared by the RelatedRecordCollection metadata on
  * the 'MJ_BizApps_Common: Organizations → MJ_BizApps_Common: Contact Methods' relationship; edit that row, not this file.
  *
  */
  public readonly ContactMethods = this.DeclareRelatedRecords<mjBizAppsCommonContactMethodEntity>({
      Name: 'ContactMethods',
        RelatedEntity: 'MJ_BizApps_Common: Contact Methods',
        RelatedEntityJoinField: 'OrganizationID',
        Load: 'explicit',
        OnRemove: 'delete',
  });


  /**
  * Related records: MJ_BizApps_Common: Relationships
  *
  * Loads, validates and persists as one unit with this MJ_BizApps_Common: Organizations record — see
  * guides/TRANSACTIONS_AND_BATCHING_GUIDE.md. Declared by the RelatedRecordCollection metadata on
  * the 'MJ_BizApps_Common: Organizations → MJ_BizApps_Common: Relationships' relationship; edit that row, not this file.
  *
  */
  public readonly OutgoingRelationships = this.DeclareRelatedRecords<mjBizAppsCommonRelationshipEntity>({
      Name: 'OutgoingRelationships',
        RelatedEntity: 'MJ_BizApps_Common: Relationships',
        RelatedEntityJoinField: 'FromOrganizationID',
        Load: 'explicit',
        OnRemove: 'delete',
  });

    /**
    * Loads the MJ_BizApps_Common: Organizations record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Organizations record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonOrganizationEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: Name
    * * Display Name: Name
    * * SQL Data Type: nvarchar(255)
    * * Description: Common or display name of the organization
    */
    get Name(): string {
        return this.Get('Name');
    }
    set Name(value: string) {
        this.Set('Name', value);
    }

    /**
    * * Field Name: LegalName
    * * Display Name: Legal Name
    * * SQL Data Type: nvarchar(255)
    * * Description: Full legal name if different from display name
    */
    get LegalName(): string | null {
        return this.Get('LegalName');
    }
    set LegalName(value: string | null) {
        this.Set('LegalName', value);
    }

    /**
    * * Field Name: OrganizationTypeID
    * * Display Name: Organization Type
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Organization Types (vwOrganizationTypes.ID)
    */
    get OrganizationTypeID(): string | null {
        return this.Get('OrganizationTypeID');
    }
    set OrganizationTypeID(value: string | null) {
        this.Set('OrganizationTypeID', value);
    }

    /**
    * * Field Name: ParentID
    * * Display Name: Parent Organization
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Organizations (vwOrganizations.ID)
    */
    get ParentID(): string | null {
        return this.Get('ParentID');
    }
    set ParentID(value: string | null) {
        this.Set('ParentID', value);
    }

    /**
    * * Field Name: Website
    * * Display Name: Website
    * * SQL Data Type: nvarchar(1000)
    * * Description: Primary website URL
    */
    get Website(): string | null {
        return this.Get('Website');
    }
    set Website(value: string | null) {
        this.Set('Website', value);
    }

    /**
    * * Field Name: LogoURL
    * * Display Name: Logo URL
    * * SQL Data Type: nvarchar(1000)
    * * Description: URL to organization logo image
    */
    get LogoURL(): string | null {
        return this.Get('LogoURL');
    }
    set LogoURL(value: string | null) {
        this.Set('LogoURL', value);
    }

    /**
    * * Field Name: Description
    * * Display Name: Description
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Description of the organization purpose and scope
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: Email
    * * Display Name: Email
    * * SQL Data Type: nvarchar(255)
    * * Description: Primary contact email address
    */
    get Email(): string | null {
        return this.Get('Email');
    }
    set Email(value: string | null) {
        this.Set('Email', value);
    }

    /**
    * * Field Name: Phone
    * * Display Name: Phone
    * * SQL Data Type: nvarchar(50)
    * * Description: Primary phone number
    */
    get Phone(): string | null {
        return this.Get('Phone');
    }
    set Phone(value: string | null) {
        this.Set('Phone', value);
    }

    /**
    * * Field Name: FoundedDate
    * * Display Name: Founded Date
    * * SQL Data Type: date
    * * Description: Date the organization was founded or incorporated
    */
    get FoundedDate(): Date | null {
        return this.Get('FoundedDate');
    }
    set FoundedDate(value: Date | null) {
        this.Set('FoundedDate', value);
    }

    /**
    * * Field Name: TaxID
    * * Display Name: Tax ID
    * * SQL Data Type: nvarchar(50)
    * * Description: Tax identification number such as EIN
    */
    get TaxID(): string | null {
        return this.Get('TaxID');
    }
    set TaxID(value: string | null) {
        this.Set('TaxID', value);
    }

    /**
    * * Field Name: Status
    * * Display Name: Status
    * * SQL Data Type: nvarchar(50)
    * * Default Value: Active
    * * Value List Type: List
    * * Possible Values 
    *   * Active
    *   * Dissolved
    *   * Inactive
    * * Description: Current status: Active, Inactive, or Dissolved
    */
    get Status(): 'Active' | 'Dissolved' | 'Inactive' {
        return this.Get('Status');
    }
    set Status(value: 'Active' | 'Dissolved' | 'Inactive') {
        this.Set('Status', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: OrganizationType
    * * Display Name: Organization Type Name
    * * SQL Data Type: nvarchar(100)
    */
    get OrganizationType(): string | null {
        return this.Get('OrganizationType');
    }

    /**
    * * Field Name: Parent
    * * Display Name: Parent Name
    * * SQL Data Type: nvarchar(255)
    */
    get Parent(): string | null {
        return this.Get('Parent');
    }

    /**
    * * Field Name: __mj_Latitude
    * * Display Name: Latitude
    * * SQL Data Type: decimal(10, 6)
    */
    get __mj_Latitude(): number | null {
        return this.Get('__mj_Latitude');
    }

    /**
    * * Field Name: __mj_Longitude
    * * Display Name: Longitude
    * * SQL Data Type: decimal(10, 6)
    */
    get __mj_Longitude(): number | null {
        return this.Get('__mj_Longitude');
    }

    /**
    * * Field Name: RootParentID
    * * Display Name: Root Parent
    * * SQL Data Type: uniqueidentifier
    */
    get RootParentID(): string | null {
        return this.Get('RootParentID');
    }

    /**
    * * Field Name: ParentIDDepth
    * * Display Name: Hierarchy Depth
    * * SQL Data Type: int
    */
    get ParentIDDepth(): number | null {
        return this.Get('ParentIDDepth');
    }

    /**
    * * Field Name: ParentIDPath
    * * Display Name: Hierarchy Path
    * * SQL Data Type: nvarchar(MAX)
    */
    get ParentIDPath(): string | null {
        return this.Get('ParentIDPath');
    }

    /**
    * * Field Name: ParentIDIsLeaf
    * * Display Name: Is Leaf Node
    * * SQL Data Type: bit
    */
    get ParentIDIsLeaf(): boolean | null {
        return this.Get('ParentIDIsLeaf');
    }

    /**
    * * Field Name: ParentIDChildCount
    * * Display Name: Child Count
    * * SQL Data Type: int
    */
    get ParentIDChildCount(): number | null {
        return this.Get('ParentIDChildCount');
    }

    /**
    * * Field Name: PrimaryAddressLine1
    * * Display Name: Address Line 1
    * * SQL Data Type: nvarchar(255)
    */
    get PrimaryAddressLine1(): string | null {
        return this.Get('PrimaryAddressLine1');
    }

    /**
    * * Field Name: PrimaryAddressLine2
    * * Display Name: Address Line 2
    * * SQL Data Type: nvarchar(255)
    */
    get PrimaryAddressLine2(): string | null {
        return this.Get('PrimaryAddressLine2');
    }

    /**
    * * Field Name: PrimaryAddressCity
    * * Display Name: City
    * * SQL Data Type: nvarchar(100)
    */
    get PrimaryAddressCity(): string | null {
        return this.Get('PrimaryAddressCity');
    }

    /**
    * * Field Name: PrimaryAddressState
    * * Display Name: State/Province
    * * SQL Data Type: nvarchar(100)
    */
    get PrimaryAddressState(): string | null {
        return this.Get('PrimaryAddressState');
    }

    /**
    * * Field Name: PrimaryAddressPostalCode
    * * Display Name: Postal Code
    * * SQL Data Type: nvarchar(20)
    */
    get PrimaryAddressPostalCode(): string | null {
        return this.Get('PrimaryAddressPostalCode');
    }

    /**
    * * Field Name: PrimaryAddressCountry
    * * Display Name: Country
    * * SQL Data Type: nvarchar(100)
    */
    get PrimaryAddressCountry(): string | null {
        return this.Get('PrimaryAddressCountry');
    }

    /**
    * * Field Name: PrimaryAddressType
    * * Display Name: Address Type
    * * SQL Data Type: nvarchar(100)
    */
    get PrimaryAddressType(): string | null {
        return this.Get('PrimaryAddressType');
    }

    /**
    * * Field Name: PrimaryEmail
    * * Display Name: Primary Email
    * * SQL Data Type: nvarchar(500)
    */
    get PrimaryEmail(): string | null {
        return this.Get('PrimaryEmail');
    }

    /**
    * * Field Name: PrimaryPhone
    * * Display Name: Primary Phone
    * * SQL Data Type: nvarchar(500)
    */
    get PrimaryPhone(): string | null {
        return this.Get('PrimaryPhone');
    }

    /**
    * * Field Name: ActivePersonCount
    * * Display Name: Active Staff Count
    * * SQL Data Type: int
    */
    get ActivePersonCount(): number | null {
        return this.Get('ActivePersonCount');
    }

    /**
    * * Field Name: ChildOrgCount
    * * Display Name: Total Child Organizations
    * * SQL Data Type: int
    */
    get ChildOrgCount(): number | null {
        return this.Get('ChildOrgCount');
    }
}


/**
 * MJ_BizApps_Common: People - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: Person
 * * Base View: vwPeople
 * * @description Individual people, optionally linked to MJ system user accounts
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: People')
export class mjBizAppsCommonPersonEntity extends BaseEntity<mjBizAppsCommonPersonEntityType> {

  /**
  * Related records: MJ_BizApps_Common: Contact Methods
  *
  * Loads, validates and persists as one unit with this MJ_BizApps_Common: People record — see
  * guides/TRANSACTIONS_AND_BATCHING_GUIDE.md. Declared by the RelatedRecordCollection metadata on
  * the 'MJ_BizApps_Common: People → MJ_BizApps_Common: Contact Methods' relationship; edit that row, not this file.
  *
  */
  public readonly ContactMethods = this.DeclareRelatedRecords<mjBizAppsCommonContactMethodEntity>({
      Name: 'ContactMethods',
        RelatedEntity: 'MJ_BizApps_Common: Contact Methods',
        RelatedEntityJoinField: 'PersonID',
        Load: 'explicit',
        OnRemove: 'delete',
  });


  /**
  * Related records: MJ_BizApps_Common: Relationships
  *
  * Loads, validates and persists as one unit with this MJ_BizApps_Common: People record — see
  * guides/TRANSACTIONS_AND_BATCHING_GUIDE.md. Declared by the RelatedRecordCollection metadata on
  * the 'MJ_BizApps_Common: People → MJ_BizApps_Common: Relationships' relationship; edit that row, not this file.
  *
  */
  public readonly OutgoingRelationships = this.DeclareRelatedRecords<mjBizAppsCommonRelationshipEntity>({
      Name: 'OutgoingRelationships',
        RelatedEntity: 'MJ_BizApps_Common: Relationships',
        RelatedEntityJoinField: 'FromPersonID',
        Load: 'explicit',
        OnRemove: 'delete',
  });

    /**
    * Loads the MJ_BizApps_Common: People record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: People record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonPersonEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: FirstName
    * * Display Name: First Name
    * * SQL Data Type: nvarchar(100)
    * * Description: First (given) name
    */
    get FirstName(): string {
        return this.Get('FirstName');
    }
    set FirstName(value: string) {
        this.Set('FirstName', value);
    }

    /**
    * * Field Name: LastName
    * * Display Name: Last Name
    * * SQL Data Type: nvarchar(100)
    * * Description: Last (family) name
    */
    get LastName(): string {
        return this.Get('LastName');
    }
    set LastName(value: string) {
        this.Set('LastName', value);
    }

    /**
    * * Field Name: MiddleName
    * * Display Name: Middle Name
    * * SQL Data Type: nvarchar(100)
    * * Description: Middle name or initial
    */
    get MiddleName(): string | null {
        return this.Get('MiddleName');
    }
    set MiddleName(value: string | null) {
        this.Set('MiddleName', value);
    }

    /**
    * * Field Name: Prefix
    * * Display Name: Prefix
    * * SQL Data Type: nvarchar(20)
    * * Description: Name prefix such as Dr., Mr., Ms., Rev.
    */
    get Prefix(): string | null {
        return this.Get('Prefix');
    }
    set Prefix(value: string | null) {
        this.Set('Prefix', value);
    }

    /**
    * * Field Name: Suffix
    * * Display Name: Suffix
    * * SQL Data Type: nvarchar(20)
    * * Description: Name suffix such as Jr., III, PhD, Esq.
    */
    get Suffix(): string | null {
        return this.Get('Suffix');
    }
    set Suffix(value: string | null) {
        this.Set('Suffix', value);
    }

    /**
    * * Field Name: PreferredName
    * * Display Name: Preferred Name
    * * SQL Data Type: nvarchar(100)
    * * Description: Nickname or preferred name the person goes by
    */
    get PreferredName(): string | null {
        return this.Get('PreferredName');
    }
    set PreferredName(value: string | null) {
        this.Set('PreferredName', value);
    }

    /**
    * * Field Name: Title
    * * Display Name: Title
    * * SQL Data Type: nvarchar(200)
    * * Description: Professional or job title, e.g. VP of Engineering, Board Director
    */
    get Title(): string | null {
        return this.Get('Title');
    }
    set Title(value: string | null) {
        this.Set('Title', value);
    }

    /**
    * * Field Name: Email
    * * Display Name: Email
    * * SQL Data Type: nvarchar(255)
    * * Description: Primary email address for this person
    */
    get Email(): string | null {
        return this.Get('Email');
    }
    set Email(value: string | null) {
        this.Set('Email', value);
    }

    /**
    * * Field Name: Phone
    * * Display Name: Phone
    * * SQL Data Type: nvarchar(50)
    * * Description: Primary phone number for this person
    */
    get Phone(): string | null {
        return this.Get('Phone');
    }
    set Phone(value: string | null) {
        this.Set('Phone', value);
    }

    /**
    * * Field Name: DateOfBirth
    * * Display Name: Date of Birth
    * * SQL Data Type: date
    * * Description: Date of birth
    */
    get DateOfBirth(): Date | null {
        return this.Get('DateOfBirth');
    }
    set DateOfBirth(value: Date | null) {
        this.Set('DateOfBirth', value);
    }

    /**
    * * Field Name: Gender
    * * Display Name: Gender
    * * SQL Data Type: nvarchar(50)
    * * Description: Gender identity
    */
    get Gender(): string | null {
        return this.Get('Gender');
    }
    set Gender(value: string | null) {
        this.Set('Gender', value);
    }

    /**
    * * Field Name: PhotoURL
    * * Display Name: Photo URL
    * * SQL Data Type: nvarchar(1000)
    * * Description: URL to profile photo or avatar image
    */
    get PhotoURL(): string | null {
        return this.Get('PhotoURL');
    }
    set PhotoURL(value: string | null) {
        this.Set('PhotoURL', value);
    }

    /**
    * * Field Name: Bio
    * * Display Name: Bio
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Biographical text or notes about this person
    */
    get Bio(): string | null {
        return this.Get('Bio');
    }
    set Bio(value: string | null) {
        this.Set('Bio', value);
    }

    /**
    * * Field Name: LinkedUserID
    * * Display Name: Linked User ID
    * * 
    * * @deprecated This field is deprecated and will be removed in a future version. Using it will result in console warnings.SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ: Users (vwUsers.ID)
    * * Description: DEPRECATED: Do not use. bizapps-common no longer reads or writes this column; person-to-MJ-User bindings are owned by platform-layer IS-A subtypes of Person (e.g., BCSaaS 'BC: People'). Retained only for backward compatibility and scheduled for removal in the next major release.
    */
    get LinkedUserID(): string | null {
        return this.Get('LinkedUserID');
    }
    set LinkedUserID(value: string | null) {
        this.Set('LinkedUserID', value);
    }

    /**
    * * Field Name: Status
    * * Display Name: Status
    * * SQL Data Type: nvarchar(50)
    * * Default Value: Active
    * * Value List Type: List
    * * Possible Values 
    *   * Active
    *   * Deceased
    *   * Inactive
    * * Description: Current status: Active, Inactive, or Deceased
    */
    get Status(): 'Active' | 'Deceased' | 'Inactive' {
        return this.Get('Status');
    }
    set Status(value: 'Active' | 'Deceased' | 'Inactive') {
        this.Set('Status', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: DisplayName
    * * Display Name: Display Name
    * * SQL Data Type: nvarchar(201)
    */
    get DisplayName(): string {
        return this.Get('DisplayName');
    }

    /**
    * * Field Name: LinkedUser
    * * Display Name: Linked User
    * * SQL Data Type: nvarchar(100)
    */
    get LinkedUser(): string | null {
        return this.Get('LinkedUser');
    }

    /**
    * * Field Name: __mj_Latitude
    * * Display Name: Mj Latitude
    * * SQL Data Type: decimal(10, 6)
    */
    get __mj_Latitude(): number | null {
        return this.Get('__mj_Latitude');
    }

    /**
    * * Field Name: __mj_Longitude
    * * Display Name: Mj Longitude
    * * SQL Data Type: decimal(10, 6)
    */
    get __mj_Longitude(): number | null {
        return this.Get('__mj_Longitude');
    }

    /**
    * * Field Name: PrimaryAddressLine1
    * * Display Name: Primary Address Line 1
    * * SQL Data Type: nvarchar(255)
    */
    get PrimaryAddressLine1(): string | null {
        return this.Get('PrimaryAddressLine1');
    }

    /**
    * * Field Name: PrimaryAddressLine2
    * * Display Name: Primary Address Line 2
    * * SQL Data Type: nvarchar(255)
    */
    get PrimaryAddressLine2(): string | null {
        return this.Get('PrimaryAddressLine2');
    }

    /**
    * * Field Name: PrimaryAddressCity
    * * Display Name: Primary Address City
    * * SQL Data Type: nvarchar(100)
    */
    get PrimaryAddressCity(): string | null {
        return this.Get('PrimaryAddressCity');
    }

    /**
    * * Field Name: PrimaryAddressState
    * * Display Name: Primary Address State
    * * SQL Data Type: nvarchar(100)
    */
    get PrimaryAddressState(): string | null {
        return this.Get('PrimaryAddressState');
    }

    /**
    * * Field Name: PrimaryAddressPostalCode
    * * Display Name: Primary Address Postal Code
    * * SQL Data Type: nvarchar(20)
    */
    get PrimaryAddressPostalCode(): string | null {
        return this.Get('PrimaryAddressPostalCode');
    }

    /**
    * * Field Name: PrimaryAddressCountry
    * * Display Name: Primary Address Country
    * * SQL Data Type: nvarchar(100)
    */
    get PrimaryAddressCountry(): string | null {
        return this.Get('PrimaryAddressCountry');
    }

    /**
    * * Field Name: PrimaryAddressLatitude
    * * Display Name: Primary Address Latitude
    * * SQL Data Type: decimal(9, 6)
    */
    get PrimaryAddressLatitude(): number | null {
        return this.Get('PrimaryAddressLatitude');
    }

    /**
    * * Field Name: PrimaryAddressLongitude
    * * Display Name: Primary Address Longitude
    * * SQL Data Type: decimal(9, 6)
    */
    get PrimaryAddressLongitude(): number | null {
        return this.Get('PrimaryAddressLongitude');
    }

    /**
    * * Field Name: PrimaryAddressType
    * * Display Name: Primary Address Type
    * * SQL Data Type: nvarchar(100)
    */
    get PrimaryAddressType(): string | null {
        return this.Get('PrimaryAddressType');
    }

    /**
    * * Field Name: PrimaryEmail
    * * Display Name: Primary Email
    * * SQL Data Type: nvarchar(500)
    */
    get PrimaryEmail(): string | null {
        return this.Get('PrimaryEmail');
    }

    /**
    * * Field Name: PrimaryPhone
    * * Display Name: Primary Phone
    * * SQL Data Type: nvarchar(500)
    */
    get PrimaryPhone(): string | null {
        return this.Get('PrimaryPhone');
    }

    /**
    * * Field Name: CurrentOrganizationID
    * * Display Name: Current Organization ID
    * * SQL Data Type: uniqueidentifier
    */
    get CurrentOrganizationID(): string | null {
        return this.Get('CurrentOrganizationID');
    }

    /**
    * * Field Name: CurrentOrganizationName
    * * Display Name: Current Organization Name
    * * SQL Data Type: nvarchar(255)
    */
    get CurrentOrganizationName(): string | null {
        return this.Get('CurrentOrganizationName');
    }

    /**
    * * Field Name: CurrentJobTitle
    * * Display Name: Current Job Title
    * * SQL Data Type: nvarchar(255)
    */
    get CurrentJobTitle(): string | null {
        return this.Get('CurrentJobTitle');
    }
}


/**
 * MJ_BizApps_Common: Relationship Types - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: RelationshipType
 * * Base View: vwRelationshipTypes
 * * @description Defines types of relationships between people and organizations with directionality and labeling
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Relationship Types')
export class mjBizAppsCommonRelationshipTypeEntity extends BaseEntity<mjBizAppsCommonRelationshipTypeEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Relationship Types record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Relationship Types record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonRelationshipTypeEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: Name
    * * Display Name: Name
    * * SQL Data Type: nvarchar(100)
    * * Description: Display name for the relationship type, e.g. Employee, Spouse, Partner
    */
    get Name(): string {
        return this.Get('Name');
    }
    set Name(value: string) {
        this.Set('Name', value);
    }

    /**
    * * Field Name: Description
    * * Display Name: Description
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Detailed description of this relationship type
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: Category
    * * Display Name: Category
    * * SQL Data Type: nvarchar(50)
    * * Value List Type: List
    * * Possible Values 
    *   * OrganizationToOrganization
    *   * PersonToOrganization
    *   * PersonToPerson
    * * Description: Which entity types this relationship connects: PersonToPerson, PersonToOrganization, or OrganizationToOrganization
    */
    get Category(): 'OrganizationToOrganization' | 'PersonToOrganization' | 'PersonToPerson' {
        return this.Get('Category');
    }
    set Category(value: 'OrganizationToOrganization' | 'PersonToOrganization' | 'PersonToPerson') {
        this.Set('Category', value);
    }

    /**
    * * Field Name: IsDirectional
    * * Display Name: Is Directional
    * * SQL Data Type: bit
    * * Default Value: 1
    * * Description: Whether the relationship has a direction. False for symmetric relationships like Spouse or Partner
    */
    get IsDirectional(): boolean {
        return this.Get('IsDirectional');
    }
    set IsDirectional(value: boolean) {
        this.Set('IsDirectional', value);
    }

    /**
    * * Field Name: ForwardLabel
    * * Display Name: Forward Label
    * * SQL Data Type: nvarchar(100)
    * * Description: Label describing the From-to-To direction, e.g. is employee of, is parent of
    */
    get ForwardLabel(): string | null {
        return this.Get('ForwardLabel');
    }
    set ForwardLabel(value: string | null) {
        this.Set('ForwardLabel', value);
    }

    /**
    * * Field Name: ReverseLabel
    * * Display Name: Reverse Label
    * * SQL Data Type: nvarchar(100)
    * * Description: Label describing the To-to-From direction, e.g. employs, is child of
    */
    get ReverseLabel(): string | null {
        return this.Get('ReverseLabel');
    }
    set ReverseLabel(value: string | null) {
        this.Set('ReverseLabel', value);
    }

    /**
    * * Field Name: IsActive
    * * Display Name: Active
    * * SQL Data Type: bit
    * * Default Value: 1
    * * Description: Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records
    */
    get IsActive(): boolean {
        return this.Get('IsActive');
    }
    set IsActive(value: boolean) {
        this.Set('IsActive', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }
}


/**
 * MJ_BizApps_Common: Relationships - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: Relationship
 * * Base View: vwRelationships
 * * @description Typed, directional links between people and organizations supporting Person-to-Person, Person-to-Organization, and Organization-to-Organization relationships
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Relationships')
export class mjBizAppsCommonRelationshipEntity extends BaseEntity<mjBizAppsCommonRelationshipEntityType> {
    /**
    * Loads the MJ_BizApps_Common: Relationships record from the database
    * @param ID: string - primary key value to load the MJ_BizApps_Common: Relationships record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof mjBizAppsCommonRelationshipEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * Validate() method override for MJ_BizApps_Common: Relationships entity. This is an auto-generated method that invokes the generated validators for this entity for the following fields:
    * * Table-Level: A relationship must be linked to exactly one source: either a person or an organization. This ensures that the origin of the relationship is clearly defined and prevents data where both or neither are specified.
    * * Table-Level: A relationship must be linked to exactly one target: either a person or an organization. This ensures that the destination of the relationship is clearly defined and prevents ambiguous or missing links.
    * @public
    * @method
    * @override
    */
    public override Validate(): ValidationResult {
        const result = super.Validate();
        this.ValidateFromPersonOrFromOrganizationExclusivity(result);
        this.ValidateToPersonOrToOrganizationExclusivity(result);
        result.Success = result.Success && (result.Errors.length === 0);

        return result;
    }

    /**
    * A relationship must be linked to exactly one source: either a person or an organization. This ensures that the origin of the relationship is clearly defined and prevents data where both or neither are specified.
    * @param result - the ValidationResult object to add any errors or warnings to
    * @public
    * @method
    */
    public ValidateFromPersonOrFromOrganizationExclusivity(result: ValidationResult) {
    	const hasPerson = this.FromPersonID != null;
    	const hasOrg = this.FromOrganizationID != null;
    
    	if ((hasPerson && hasOrg) || (!hasPerson && !hasOrg)) {
    		result.Errors.push(new ValidationErrorInfo(
    			"FromPersonID",
    			"You must specify either a Person or an Organization as the source, but not both and not neither.",
    			this.FromPersonID,
    			ValidationErrorType.Failure
    		));
    	}
    }

    /**
    * A relationship must be linked to exactly one target: either a person or an organization. This ensures that the destination of the relationship is clearly defined and prevents ambiguous or missing links.
    * @param result - the ValidationResult object to add any errors or warnings to
    * @public
    * @method
    */
    public ValidateToPersonOrToOrganizationExclusivity(result: ValidationResult) {
    	// Ensure that exactly one of ToPersonID or ToOrganizationID is populated
    	const hasPerson = this.ToPersonID != null;
    	const hasOrganization = this.ToOrganizationID != null;
    
    	if ((hasPerson && hasOrganization) || (!hasPerson && !hasOrganization)) {
    		result.Errors.push(new ValidationErrorInfo(
    			"ToPersonID",
    			"A relationship must be associated with either a person or an organization, but not both and not neither.",
    			this.ToPersonID,
    			ValidationErrorType.Failure
    		));
    	}
    }

    /**
    * * Field Name: ID
    * * Display Name: ID
    * * SQL Data Type: uniqueidentifier
    * * Default Value: newsequentialid()
    */
    get ID(): string {
        return this.Get('ID');
    }
    set ID(value: string) {
        this.Set('ID', value);
    }

    /**
    * * Field Name: RelationshipTypeID
    * * Display Name: Relationship Type ID
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Relationship Types (vwRelationshipTypes.ID)
    */
    get RelationshipTypeID(): string {
        return this.Get('RelationshipTypeID');
    }
    set RelationshipTypeID(value: string) {
        this.Set('RelationshipTypeID', value);
    }

    /**
    * * Field Name: FromPersonID
    * * Display Name: From Person
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: People (vwPeople.ID)
    */
    get FromPersonID(): string | null {
        return this.Get('FromPersonID');
    }
    set FromPersonID(value: string | null) {
        this.Set('FromPersonID', value);
    }

    /**
    * * Field Name: FromOrganizationID
    * * Display Name: From Organization
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Organizations (vwOrganizations.ID)
    */
    get FromOrganizationID(): string | null {
        return this.Get('FromOrganizationID');
    }
    set FromOrganizationID(value: string | null) {
        this.Set('FromOrganizationID', value);
    }

    /**
    * * Field Name: ToPersonID
    * * Display Name: To Person
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: People (vwPeople.ID)
    */
    get ToPersonID(): string | null {
        return this.Get('ToPersonID');
    }
    set ToPersonID(value: string | null) {
        this.Set('ToPersonID', value);
    }

    /**
    * * Field Name: ToOrganizationID
    * * Display Name: To Organization
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ_BizApps_Common: Organizations (vwOrganizations.ID)
    */
    get ToOrganizationID(): string | null {
        return this.Get('ToOrganizationID');
    }
    set ToOrganizationID(value: string | null) {
        this.Set('ToOrganizationID', value);
    }

    /**
    * * Field Name: Title
    * * Display Name: Title
    * * SQL Data Type: nvarchar(255)
    * * Description: Contextual title for this specific relationship, e.g. CEO, Primary Contact, Founding Member
    */
    get Title(): string | null {
        return this.Get('Title');
    }
    set Title(value: string | null) {
        this.Set('Title', value);
    }

    /**
    * * Field Name: StartDate
    * * Display Name: Start Date
    * * SQL Data Type: date
    * * Description: Date the relationship began
    */
    get StartDate(): Date | null {
        return this.Get('StartDate');
    }
    set StartDate(value: Date | null) {
        this.Set('StartDate', value);
    }

    /**
    * * Field Name: EndDate
    * * Display Name: End Date
    * * SQL Data Type: date
    * * Description: Date the relationship ended, if applicable
    */
    get EndDate(): Date | null {
        return this.Get('EndDate');
    }
    set EndDate(value: Date | null) {
        this.Set('EndDate', value);
    }

    /**
    * * Field Name: Status
    * * Display Name: Status
    * * SQL Data Type: nvarchar(50)
    * * Default Value: Active
    * * Value List Type: List
    * * Possible Values 
    *   * Active
    *   * Ended
    *   * Inactive
    * * Description: Current status: Active, Inactive, or Ended
    */
    get Status(): 'Active' | 'Ended' | 'Inactive' {
        return this.Get('Status');
    }
    set Status(value: 'Active' | 'Ended' | 'Inactive') {
        this.Set('Status', value);
    }

    /**
    * * Field Name: Notes
    * * Display Name: Notes
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Additional notes about this relationship
    */
    get Notes(): string | null {
        return this.Get('Notes');
    }
    set Notes(value: string | null) {
        this.Set('Notes', value);
    }

    /**
    * * Field Name: __mj_CreatedAt
    * * Display Name: Created At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_CreatedAt(): Date {
        return this.Get('__mj_CreatedAt');
    }

    /**
    * * Field Name: __mj_UpdatedAt
    * * Display Name: Updated At
    * * SQL Data Type: datetimeoffset
    * * Default Value: getutcdate()
    */
    get __mj_UpdatedAt(): Date {
        return this.Get('__mj_UpdatedAt');
    }

    /**
    * * Field Name: RelationshipType
    * * Display Name: Relationship Type
    * * SQL Data Type: nvarchar(100)
    */
    get RelationshipType(): string {
        return this.Get('RelationshipType');
    }

    /**
    * * Field Name: FromPerson
    * * Display Name: From Person
    * * SQL Data Type: nvarchar(201)
    */
    get FromPerson(): string | null {
        return this.Get('FromPerson');
    }

    /**
    * * Field Name: FromOrganization
    * * Display Name: From Organization Name
    * * SQL Data Type: nvarchar(255)
    */
    get FromOrganization(): string | null {
        return this.Get('FromOrganization');
    }

    /**
    * * Field Name: ToPerson
    * * Display Name: To Person
    * * SQL Data Type: nvarchar(201)
    */
    get ToPerson(): string | null {
        return this.Get('ToPerson');
    }

    /**
    * * Field Name: ToOrganization
    * * Display Name: To Organization Name
    * * SQL Data Type: nvarchar(255)
    */
    get ToOrganization(): string | null {
        return this.Get('ToOrganization');
    }
}
