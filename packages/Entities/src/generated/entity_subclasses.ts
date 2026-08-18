import { BaseEntity, EntitySaveOptions, EntityDeleteOptions, CompositeKey, ValidationResult, ValidationErrorInfo, ValidationErrorType, Metadata, ProviderType, DatabaseProviderBase, RunView } from "@memberjunction/core";
import { RegisterClass } from "@memberjunction/global";
import { z } from "zod";

export const loadModule = () => {
  // no-op, only used to ensure this file is a valid module and to allow easy loading
}

     
 
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
        * * Display Name: Logged By User Name
        * * SQL Data Type: nvarchar(100)`),
    Address: z.string().nullable().describe(`
        * * Field Name: Address
        * * Display Name: Address Text
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
        * * Display Name: Parent Depth
        * * SQL Data Type: int`),
    ParentActivityIDPath: z.string().nullable().describe(`
        * * Field Name: ParentActivityIDPath
        * * Display Name: Parent Path
        * * SQL Data Type: nvarchar(MAX)`),
    ParentActivityIDIsLeaf: z.boolean().nullable().describe(`
        * * Field Name: ParentActivityIDIsLeaf
        * * Display Name: Is Leaf Node
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
    Entity: z.string().nullable().describe(`
        * * Field Name: Entity
        * * Display Name: Entity
        * * SQL Data Type: nvarchar(255)`),
});

export type mjBizAppsCommonActivityLinkEntityType = z.infer<typeof mjBizAppsCommonActivityLinkSchema>;

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
    Provider: z.union([z.literal('Generic'), z.literal('Gmail'), z.literal('Microsoft365'), z.literal('Zoom')]).describe(`
        * * Field Name: Provider
        * * Display Name: Provider
        * * SQL Data Type: nvarchar(40)
    * * Value List Type: List
    * * Possible Values 
    *   * Generic
    *   * Gmail
    *   * Microsoft365
    *   * Zoom
        * * Description: Microsoft365, Gmail, Zoom, or Generic. Widen the CHECK when a new first-class provider lands.`),
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
        * * Display Name: Credentials Ref
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
    OwnerUser: z.string().describe(`
        * * Field Name: OwnerUser
        * * Display Name: Owner User
        * * SQL Data Type: nvarchar(100)`),
});

export type mjBizAppsCommonActivitySyncConnectionEntityType = z.infer<typeof mjBizAppsCommonActivitySyncConnectionSchema>;

/**
 * zod schema definition for the entity MJ_BizApps_Common: Activity Sync Rules
 */
export const mjBizAppsCommonActivitySyncRuleSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    ActivitySyncConnectionID: z.string().describe(`
        * * Field Name: ActivitySyncConnectionID
        * * Display Name: Activity Sync Connection ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Activity Sync Connections (vwActivitySyncConnections.ID)`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
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
        * * Display Name: Activity Type ID
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
        * * Display Name: Date From
        * * SQL Data Type: datetimeoffset
        * * Description: Inclusive lower bound of the sync window. Null = no lower bound.`),
    DateTo: z.date().nullable().describe(`
        * * Field Name: DateTo
        * * Display Name: Date To
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
        * * Display Name: Filter
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
    ActivitySyncConnection: z.string().describe(`
        * * Field Name: ActivitySyncConnection
        * * Display Name: Activity Sync Connection
        * * SQL Data Type: nvarchar(200)`),
    ActivityType: z.string().nullable().describe(`
        * * Field Name: ActivityType
        * * Display Name: Activity Type
        * * SQL Data Type: nvarchar(100)`),
});

export type mjBizAppsCommonActivitySyncRuleEntityType = z.infer<typeof mjBizAppsCommonActivitySyncRuleSchema>;

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
        * * Display Name: Parent
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
        * * Display Name: Parent Name
        * * SQL Data Type: nvarchar(100)`),
    RootParentID: z.string().nullable().describe(`
        * * Field Name: RootParentID
        * * Display Name: Root Parent
        * * SQL Data Type: uniqueidentifier`),
    ParentIDDepth: z.number().nullable().describe(`
        * * Field Name: ParentIDDepth
        * * Display Name: Depth
        * * SQL Data Type: int`),
    ParentIDPath: z.string().nullable().describe(`
        * * Field Name: ParentIDPath
        * * Display Name: Path
        * * SQL Data Type: nvarchar(MAX)`),
    ParentIDIsLeaf: z.boolean().nullable().describe(`
        * * Field Name: ParentIDIsLeaf
        * * Display Name: Is Leaf
        * * SQL Data Type: bit`),
    ParentIDChildCount: z.number().nullable().describe(`
        * * Field Name: ParentIDChildCount
        * * Display Name: Child Count
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
        * * Display Name: Organization ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Organizations (vwOrganizations.ID)`),
    ContactTypeID: z.string().describe(`
        * * Field Name: ContactTypeID
        * * Display Name: Contact Type ID
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
        * * Display Name: Person Name
        * * SQL Data Type: nvarchar(201)`),
    Organization: z.string().nullable().describe(`
        * * Field Name: Organization
        * * Display Name: Organization Name
        * * SQL Data Type: nvarchar(255)`),
    ContactType: z.string().describe(`
        * * Field Name: ContactType
        * * Display Name: Contact Type
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
        * * Display Name: Organization Type ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: MJ_BizApps_Common: Organization Types (vwOrganizationTypes.ID)`),
    ParentID: z.string().nullable().describe(`
        * * Field Name: ParentID
        * * Display Name: Parent
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
        * * Display Name: Organization Type
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
        * * Display Name: State
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
        * * Display Name: Active Person Count
        * * SQL Data Type: int`),
    ChildOrgCount: z.number().nullable().describe(`
        * * Field Name: ChildOrgCount
        * * Display Name: Child Organization Count
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
        * * Related Entity/Foreign Key: MJ: Users (vwUsers.ID)`),
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
        * * Display Name: State
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
        * * Display Name: Latitude
        * * SQL Data Type: decimal(9, 6)`),
    PrimaryAddressLongitude: z.number().nullable().describe(`
        * * Field Name: PrimaryAddressLongitude
        * * Display Name: Longitude
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
        * * Display Name: From Person Name
        * * SQL Data Type: nvarchar(201)`),
    FromOrganization: z.string().nullable().describe(`
        * * Field Name: FromOrganization
        * * Display Name: From Organization Name
        * * SQL Data Type: nvarchar(255)`),
    ToPerson: z.string().nullable().describe(`
        * * Field Name: ToPerson
        * * Display Name: To Person Name
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
    * Validate() method override for MJ_BizApps_Common: Activities entity. This is an auto-generated method that invokes the generated validators for this entity for the following fields:
    * * Table-Level: The end date and time of an activity must be after or equal to its start date and time.
    * * Table-Level: External ID and Source System must either both be provided together or both be left empty. You cannot specify one without the other.
    * @public
    * @method
    * @override
    */
    public override Validate(): ValidationResult {
        const result = super.Validate();
        this.ValidateEndedAtAfterStartedAt(result);
        this.ValidateExternalIDAndSourceSystemCoexistence(result);
        result.Success = result.Success && (result.Errors.length === 0);

        return result;
    }

    /**
    * The end date and time of an activity must be after or equal to its start date and time.
    * @param result - the ValidationResult object to add any errors or warnings to
    * @public
    * @method
    */
    public ValidateEndedAtAfterStartedAt(result: ValidationResult) {
    	if (this.EndedAt != null && this.StartedAt != null) {
    		const endedTime = new Date(this.EndedAt).getTime();
    		const startedTime = new Date(this.StartedAt).getTime();
    		if (endedTime < startedTime) {
    			result.Errors.push(new ValidationErrorInfo(
    				"EndedAt",
    				"The end date and time must be after or equal to the start date and time.",
    				this.EndedAt,
    				ValidationErrorType.Failure
    			));
    		}
    	}
    }

    /**
    * External ID and Source System must either both be provided together or both be left empty. You cannot specify one without the other.
    * @param result - the ValidationResult object to add any errors or warnings to
    * @public
    * @method
    */
    public ValidateExternalIDAndSourceSystemCoexistence(result: ValidationResult) {
        const hasExternalID = this.ExternalID != null && this.ExternalID !== "";
        const hasSourceSystem = this.SourceSystem != null && this.SourceSystem !== "";
    
        if (hasExternalID !== hasSourceSystem) {
            result.Errors.push(new ValidationErrorInfo(
                "ExternalID",
                "External ID and Source System must either both be provided or both be left blank.",
                this.ExternalID,
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
    * * Display Name: Logged By User Name
    * * SQL Data Type: nvarchar(100)
    */
    get LoggedByUser(): string {
        return this.Get('LoggedByUser');
    }

    /**
    * * Field Name: Address
    * * Display Name: Address Text
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
    * * Display Name: Parent Depth
    * * SQL Data Type: int
    */
    get ParentActivityIDDepth(): number | null {
        return this.Get('ParentActivityIDDepth');
    }

    /**
    * * Field Name: ParentActivityIDPath
    * * Display Name: Parent Path
    * * SQL Data Type: nvarchar(MAX)
    */
    get ParentActivityIDPath(): string | null {
        return this.Get('ParentActivityIDPath');
    }

    /**
    * * Field Name: ParentActivityIDIsLeaf
    * * Display Name: Is Leaf Node
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
    * Validate() method override for MJ_BizApps_Common: Activity Links entity. This is an auto-generated method that invokes the generated validators for this entity for the following fields:
    * * Table-Level: The record must be identified either by an Entity ID and Record ID pair, or by an Identity Kind and Identity Value pair. It cannot have both pairs specified, nor can it have a partial combination of these fields.
    * @public
    * @method
    * @override
    */
    public override Validate(): ValidationResult {
        const result = super.Validate();
        this.ValidateEntityOrIdentityPair(result);
        result.Success = result.Success && (result.Errors.length === 0);

        return result;
    }

    /**
    * The record must be identified either by an Entity ID and Record ID pair, or by an Identity Kind and Identity Value pair. It cannot have both pairs specified, nor can it have a partial combination of these fields.
    * @param result - the ValidationResult object to add any errors or warnings to
    * @public
    * @method
    */
    public ValidateEntityOrIdentityPair(result: ValidationResult) {
    	const hasEntity = this.EntityID != null;
    	const hasRecord = this.RecordID != null;
    	const hasIdentityKind = this.IdentityKind != null;
    	const hasIdentityValue = this.IdentityValue != null;
    
    	const isValidEntityPair = hasEntity && hasRecord && !hasIdentityKind && !hasIdentityValue;
    	const isValidIdentityPair = !hasEntity && !hasRecord && hasIdentityKind && hasIdentityValue;
    
    	if (!isValidEntityPair && !isValidIdentityPair) {
    		result.Errors.push(new ValidationErrorInfo(
    			"EntityID",
    			"You must provide either both EntityID and RecordID, or both IdentityKind and IdentityValue, but not both pairs or a partial mix.",
    			this.EntityID,
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
    * * Field Name: Entity
    * * Display Name: Entity
    * * SQL Data Type: nvarchar(255)
    */
    get Entity(): string | null {
        return this.Get('Entity');
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
    * * Description: Microsoft365, Gmail, Zoom, or Generic. Widen the CHECK when a new first-class provider lands.
    */
    get Provider(): 'Generic' | 'Gmail' | 'Microsoft365' | 'Zoom' {
        return this.Get('Provider');
    }
    set Provider(value: 'Generic' | 'Gmail' | 'Microsoft365' | 'Zoom') {
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
    * * Display Name: Credentials Ref
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
    * * Field Name: OwnerUser
    * * Display Name: Owner User
    * * SQL Data Type: nvarchar(100)
    */
    get OwnerUser(): string {
        return this.Get('OwnerUser');
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
    * Validate() method override for MJ_BizApps_Common: Activity Sync Rules entity. This is an auto-generated method that invokes the generated validators for this entity for the following fields:
    * * Table-Level: The end date (DateTo) must be on or after the start date (DateFrom) when both dates are specified.
    * @public
    * @method
    * @override
    */
    public override Validate(): ValidationResult {
        const result = super.Validate();
        this.ValidateDateToAfterOrEqualDateFrom(result);
        result.Success = result.Success && (result.Errors.length === 0);

        return result;
    }

    /**
    * The end date (DateTo) must be on or after the start date (DateFrom) when both dates are specified.
    * @param result - the ValidationResult object to add any errors or warnings to
    * @public
    * @method
    */
    public ValidateDateToAfterOrEqualDateFrom(result: ValidationResult) {
    	if (this.DateFrom != null && this.DateTo != null) {
    		if (this.DateTo < this.DateFrom) {
    			result.Errors.push(new ValidationErrorInfo(
    				"DateTo",
    				"The end date (DateTo) must be on or after the start date (DateFrom).",
    				this.DateTo,
    				ValidationErrorType.Failure
    			));
    		}
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
    * * Field Name: ActivitySyncConnectionID
    * * Display Name: Activity Sync Connection ID
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
    * * Field Name: Name
    * * Display Name: Name
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
    * * Display Name: Activity Type ID
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
    * * Display Name: Date From
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
    * * Display Name: Date To
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
    * * Display Name: Filter
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
    * * Field Name: ActivitySyncConnection
    * * Display Name: Activity Sync Connection
    * * SQL Data Type: nvarchar(200)
    */
    get ActivitySyncConnection(): string {
        return this.Get('ActivitySyncConnection');
    }

    /**
    * * Field Name: ActivityType
    * * Display Name: Activity Type
    * * SQL Data Type: nvarchar(100)
    */
    get ActivityType(): string | null {
        return this.Get('ActivityType');
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
    * * Display Name: Parent
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
    * * Display Name: Parent Name
    * * SQL Data Type: nvarchar(100)
    */
    get Parent(): string | null {
        return this.Get('Parent');
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
    * * Display Name: Depth
    * * SQL Data Type: int
    */
    get ParentIDDepth(): number | null {
        return this.Get('ParentIDDepth');
    }

    /**
    * * Field Name: ParentIDPath
    * * Display Name: Path
    * * SQL Data Type: nvarchar(MAX)
    */
    get ParentIDPath(): string | null {
        return this.Get('ParentIDPath');
    }

    /**
    * * Field Name: ParentIDIsLeaf
    * * Display Name: Is Leaf
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
    * * Display Name: Organization ID
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
    * * Display Name: Contact Type ID
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
    * * Display Name: Person Name
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
    * * Display Name: Contact Type
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
    * MJ_BizApps_Common: Organizations - Delete method override to wrap in transaction since CascadeDeletes is true.
    * Wrapping in a transaction ensures that all cascade delete operations are handled atomically.
    * @public
    * @method
    * @override
    * @memberof mjBizAppsCommonOrganizationEntity
    * @returns {Promise<boolean>} - true if successful, false otherwise
    */
    public override async Delete(options?: EntityDeleteOptions): Promise<boolean> {
        if (Metadata.Provider.ProviderType === ProviderType.Database) { // global-provider-ok: codegen runs offline against a single provider
            // For database providers, use the transaction methods directly
            const provider = Metadata.Provider as DatabaseProviderBase; // global-provider-ok: codegen runs offline against a single provider
            
            try {
                await provider.BeginTransaction();
                const result = await super.Delete(options);
                
                if (result) {
                    await provider.CommitTransaction();
                    return true;
                } else {
                    await provider.RollbackTransaction();
                    return false;
                }
            } catch (error) {
                await provider.RollbackTransaction();
                throw error;
            }
        } else {
            // For network providers, cascading deletes are handled server-side
            return super.Delete(options);
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
    * * Display Name: Organization Type ID
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
    * * Display Name: Parent
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
    * * Display Name: Organization Type
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
    * * Display Name: State
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
    * * Display Name: Active Person Count
    * * SQL Data Type: int
    */
    get ActivePersonCount(): number | null {
        return this.Get('ActivePersonCount');
    }

    /**
    * * Field Name: ChildOrgCount
    * * Display Name: Child Organization Count
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
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: MJ: Users (vwUsers.ID)
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
    * * Display Name: State
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
    * * Field Name: PrimaryAddressLatitude
    * * Display Name: Latitude
    * * SQL Data Type: decimal(9, 6)
    */
    get PrimaryAddressLatitude(): number | null {
        return this.Get('PrimaryAddressLatitude');
    }

    /**
    * * Field Name: PrimaryAddressLongitude
    * * Display Name: Longitude
    * * SQL Data Type: decimal(9, 6)
    */
    get PrimaryAddressLongitude(): number | null {
        return this.Get('PrimaryAddressLongitude');
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
    * * Display Name: From Person Name
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
    * * Display Name: To Person Name
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
