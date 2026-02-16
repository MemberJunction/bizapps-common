import { BaseEntity, EntitySaveOptions, EntityDeleteOptions, CompositeKey, ValidationResult, ValidationErrorInfo, ValidationErrorType, Metadata, ProviderType, DatabaseProviderBase } from "@memberjunction/core";
import { RegisterClass } from "@memberjunction/global";
import { z } from "zod";

export const loadModule = () => {
  // no-op, only used to ensure this file is a valid module and to allow easy loading
}

     
 
/**
 * zod schema definition for the entity Committees: Action Items
 */
export const ActionItemSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    CommitteeID: z.string().describe(`
        * * Field Name: CommitteeID
        * * Display Name: Committee
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Committees (vwCommittees.ID)`),
    MeetingID: z.string().nullable().describe(`
        * * Field Name: MeetingID
        * * Display Name: Meeting
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Meetings (vwMeetings.ID)`),
    AgendaItemID: z.string().nullable().describe(`
        * * Field Name: AgendaItemID
        * * Display Name: Agenda Item
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Agenda Items (vwAgendaItems.ID)`),
    Title: z.string().describe(`
        * * Field Name: Title
        * * Display Name: Title
        * * SQL Data Type: nvarchar(255)
        * * Description: Title of the action item`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Detailed description of what needs to be done`),
    AssignedToPersonID: z.string().describe(`
        * * Field Name: AssignedToPersonID
        * * Display Name: Assignee
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Common: People (vwPeople.ID)`),
    AssignedByPersonID: z.string().nullable().describe(`
        * * Field Name: AssignedByPersonID
        * * Display Name: Assigned By
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Common: People (vwPeople.ID)`),
    DueDate: z.date().nullable().describe(`
        * * Field Name: DueDate
        * * Display Name: Due Date
        * * SQL Data Type: date
        * * Description: Due date for completion`),
    Priority: z.union([z.literal('Critical'), z.literal('High'), z.literal('Low'), z.literal('Medium')]).describe(`
        * * Field Name: Priority
        * * Display Name: Priority
        * * SQL Data Type: nvarchar(20)
        * * Default Value: Medium
    * * Value List Type: List
    * * Possible Values 
    *   * Critical
    *   * High
    *   * Low
    *   * Medium
        * * Description: Priority level: Low, Medium, High, Critical`),
    Status: z.union([z.literal('Blocked'), z.literal('Cancelled'), z.literal('Completed'), z.literal('InProgress'), z.literal('Open')]).describe(`
        * * Field Name: Status
        * * Display Name: Status
        * * SQL Data Type: nvarchar(50)
        * * Default Value: Open
    * * Value List Type: List
    * * Possible Values 
    *   * Blocked
    *   * Cancelled
    *   * Completed
    *   * InProgress
    *   * Open
        * * Description: Current status: Open, InProgress, Blocked, Completed, Cancelled`),
    CompletedAt: z.date().nullable().describe(`
        * * Field Name: CompletedAt
        * * Display Name: Completed At
        * * SQL Data Type: datetimeoffset
        * * Description: Timestamp when the action item was completed`),
    CompletionNotes: z.string().nullable().describe(`
        * * Field Name: CompletionNotes
        * * Display Name: Completion Notes
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Notes about how the item was completed`),
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
    Committee: z.string().describe(`
        * * Field Name: Committee
        * * Display Name: Committee Name
        * * SQL Data Type: nvarchar(255)`),
});

export type ActionItemEntityType = z.infer<typeof ActionItemSchema>;

/**
 * zod schema definition for the entity Committees: Agenda Items
 */
export const AgendaItemSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    MeetingID: z.string().describe(`
        * * Field Name: MeetingID
        * * Display Name: Meeting
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Meetings (vwMeetings.ID)`),
    ParentAgendaItemID: z.string().nullable().describe(`
        * * Field Name: ParentAgendaItemID
        * * Display Name: Parent Agenda Item
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Agenda Items (vwAgendaItems.ID)`),
    Sequence: z.number().describe(`
        * * Field Name: Sequence
        * * Display Name: Sequence
        * * SQL Data Type: int
        * * Description: Display order within the meeting agenda`),
    Title: z.string().describe(`
        * * Field Name: Title
        * * Display Name: Title
        * * SQL Data Type: nvarchar(255)
        * * Description: Title of the agenda item`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Detailed description of the agenda item`),
    PresenterPersonID: z.string().nullable().describe(`
        * * Field Name: PresenterPersonID
        * * Display Name: Presenter
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Common: People (vwPeople.ID)`),
    DurationMinutes: z.number().nullable().describe(`
        * * Field Name: DurationMinutes
        * * Display Name: Duration (Minutes)
        * * SQL Data Type: int
        * * Description: Estimated duration in minutes`),
    ItemType: z.union([z.literal('Action'), z.literal('Discussion'), z.literal('Information'), z.literal('Other'), z.literal('Report'), z.literal('Vote')]).describe(`
        * * Field Name: ItemType
        * * Display Name: Item Type
        * * SQL Data Type: nvarchar(50)
        * * Default Value: Discussion
    * * Value List Type: List
    * * Possible Values 
    *   * Action
    *   * Discussion
    *   * Information
    *   * Other
    *   * Report
    *   * Vote
        * * Description: Type of item: Information, Discussion, Action, Vote, Report, Other`),
    RelatedDocumentURL: z.string().nullable().describe(`
        * * Field Name: RelatedDocumentURL
        * * Display Name: Related Document URL
        * * SQL Data Type: nvarchar(1000)
        * * Description: URL to related document for this item`),
    Status: z.union([z.literal('Completed'), z.literal('Discussed'), z.literal('Pending'), z.literal('Skipped'), z.literal('Tabled')]).describe(`
        * * Field Name: Status
        * * Display Name: Status
        * * SQL Data Type: nvarchar(50)
        * * Default Value: Pending
    * * Value List Type: List
    * * Possible Values 
    *   * Completed
    *   * Discussed
    *   * Pending
    *   * Skipped
    *   * Tabled
        * * Description: Current status: Pending, Discussed, Tabled, Completed, Skipped`),
    Notes: z.string().nullable().describe(`
        * * Field Name: Notes
        * * Display Name: Notes
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Discussion notes and outcomes captured during the meeting`),
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
    RootParentAgendaItemID: z.string().nullable().describe(`
        * * Field Name: RootParentAgendaItemID
        * * Display Name: Root Parent Agenda Item
        * * SQL Data Type: uniqueidentifier`),
});

export type AgendaItemEntityType = z.infer<typeof AgendaItemSchema>;

/**
 * zod schema definition for the entity Committees: Artifact Types
 */
export const ArtifactTypeSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Display name for the artifact type`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Detailed description of this artifact type`),
    ExtendedEntityID: z.string().nullable().describe(`
        * * Field Name: ExtendedEntityID
        * * Display Name: Extended Entity ID
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Entities (vwEntities.ID)
        * * Description: Optional reference to an MJ Entity that provides additional fields for this artifact type via a 1:1 extension table`),
    IconClass: z.string().nullable().describe(`
        * * Field Name: IconClass
        * * Display Name: Icon Class
        * * SQL Data Type: nvarchar(100)
        * * Description: Font Awesome icon class for UI display`),
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
    ExtendedEntity: z.string().nullable().describe(`
        * * Field Name: ExtendedEntity
        * * Display Name: Extended Entity
        * * SQL Data Type: nvarchar(255)`),
});

export type ArtifactTypeEntityType = z.infer<typeof ArtifactTypeSchema>;

/**
 * zod schema definition for the entity Committees: Artifacts
 */
export const ArtifactSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    CommitteeID: z.string().nullable().describe(`
        * * Field Name: CommitteeID
        * * Display Name: Committee
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Committees (vwCommittees.ID)`),
    MeetingID: z.string().nullable().describe(`
        * * Field Name: MeetingID
        * * Display Name: Meeting
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Meetings (vwMeetings.ID)`),
    AgendaItemID: z.string().nullable().describe(`
        * * Field Name: AgendaItemID
        * * Display Name: Agenda Item
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Agenda Items (vwAgendaItems.ID)`),
    ActionItemID: z.string().nullable().describe(`
        * * Field Name: ActionItemID
        * * Display Name: Action Item
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Action Items (vwActionItems.ID)`),
    Title: z.string().describe(`
        * * Field Name: Title
        * * Display Name: Title
        * * SQL Data Type: nvarchar(255)
        * * Description: Display title for the artifact`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Description of the artifact contents`),
    ArtifactTypeID: z.string().describe(`
        * * Field Name: ArtifactTypeID
        * * Display Name: Artifact Type
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Artifact Types (vwArtifactTypes.ID)`),
    Provider: z.union([z.literal('Box'), z.literal('Dropbox'), z.literal('GoogleDrive'), z.literal('OneDrive'), z.literal('SharePoint'), z.literal('URL')]).describe(`
        * * Field Name: Provider
        * * Display Name: Provider
        * * SQL Data Type: nvarchar(50)
    * * Value List Type: List
    * * Possible Values 
    *   * Box
    *   * Dropbox
    *   * GoogleDrive
    *   * OneDrive
    *   * SharePoint
    *   * URL
        * * Description: Storage provider: GoogleDrive, SharePoint, Box, OneDrive, Dropbox, URL`),
    ExternalID: z.string().nullable().describe(`
        * * Field Name: ExternalID
        * * Display Name: External ID
        * * SQL Data Type: nvarchar(500)
        * * Description: Provider-specific document or file ID`),
    URL: z.string().describe(`
        * * Field Name: URL
        * * Display Name: URL
        * * SQL Data Type: nvarchar(2000)
        * * Description: Direct URL to access the artifact`),
    MimeType: z.string().nullable().describe(`
        * * Field Name: MimeType
        * * Display Name: MIME Type
        * * SQL Data Type: nvarchar(100)
        * * Description: MIME type of the file`),
    FileSize: z.number().nullable().describe(`
        * * Field Name: FileSize
        * * Display Name: File Size
        * * SQL Data Type: bigint
        * * Description: File size in bytes`),
    UploadedByPersonID: z.string().nullable().describe(`
        * * Field Name: UploadedByPersonID
        * * Display Name: Uploaded By
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Common: People (vwPeople.ID)`),
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
    Committee: z.string().nullable().describe(`
        * * Field Name: Committee
        * * Display Name: Committee Name
        * * SQL Data Type: nvarchar(255)`),
    ArtifactType: z.string().describe(`
        * * Field Name: ArtifactType
        * * Display Name: Artifact Type Name
        * * SQL Data Type: nvarchar(100)`),
});

export type ArtifactEntityType = z.infer<typeof ArtifactSchema>;

/**
 * zod schema definition for the entity Committees: Attendances
 */
export const AttendanceSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    MeetingID: z.string().describe(`
        * * Field Name: MeetingID
        * * Display Name: Meeting
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Meetings (vwMeetings.ID)`),
    PersonID: z.string().describe(`
        * * Field Name: PersonID
        * * Display Name: Attendee
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Common: People (vwPeople.ID)`),
    AttendanceStatus: z.union([z.literal('Absent'), z.literal('Excused'), z.literal('Expected'), z.literal('Partial'), z.literal('Present')]).describe(`
        * * Field Name: AttendanceStatus
        * * Display Name: Attendance Status
        * * SQL Data Type: nvarchar(50)
        * * Default Value: Expected
    * * Value List Type: List
    * * Possible Values 
    *   * Absent
    *   * Excused
    *   * Expected
    *   * Partial
    *   * Present
        * * Description: Attendance status: Expected, Present, Absent, Excused, Partial`),
    JoinedAt: z.date().nullable().describe(`
        * * Field Name: JoinedAt
        * * Display Name: Joined At
        * * SQL Data Type: datetimeoffset
        * * Description: Timestamp when the attendee joined the meeting`),
    LeftAt: z.date().nullable().describe(`
        * * Field Name: LeftAt
        * * Display Name: Left At
        * * SQL Data Type: datetimeoffset
        * * Description: Timestamp when the attendee left the meeting`),
    Notes: z.string().nullable().describe(`
        * * Field Name: Notes
        * * Display Name: Notes
        * * SQL Data Type: nvarchar(500)
        * * Description: Additional notes about attendance`),
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

export type AttendanceEntityType = z.infer<typeof AttendanceSchema>;

/**
 * zod schema definition for the entity Committees: Committees
 */
export const CommitteeSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(255)
        * * Description: Official name of the committee`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Detailed description of the committee purpose and scope`),
    TypeID: z.string().describe(`
        * * Field Name: TypeID
        * * Display Name: Type
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Types (vwTypes.ID)`),
    ParentCommitteeID: z.string().nullable().describe(`
        * * Field Name: ParentCommitteeID
        * * Display Name: Parent Committee
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Committees (vwCommittees.ID)`),
    OrganizationID: z.string().nullable().describe(`
        * * Field Name: OrganizationID
        * * Display Name: Organization
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Common: Organizations (vwOrganizations.ID)`),
    CharterDocumentURL: z.string().nullable().describe(`
        * * Field Name: CharterDocumentURL
        * * Display Name: Charter Document URL
        * * SQL Data Type: nvarchar(1000)
        * * Description: URL to the committee charter document`),
    MissionStatement: z.string().nullable().describe(`
        * * Field Name: MissionStatement
        * * Display Name: Mission Statement
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Brief statement of the committee mission`),
    Status: z.union([z.literal('Active'), z.literal('Dissolved'), z.literal('Inactive'), z.literal('Pending')]).describe(`
        * * Field Name: Status
        * * Display Name: Status
        * * SQL Data Type: nvarchar(50)
        * * Default Value: Active
    * * Value List Type: List
    * * Possible Values 
    *   * Active
    *   * Dissolved
    *   * Inactive
    *   * Pending
        * * Description: Current status: Active, Inactive, Pending, or Dissolved`),
    IsPublic: z.boolean().describe(`
        * * Field Name: IsPublic
        * * Display Name: Public
        * * SQL Data Type: bit
        * * Default Value: 1
        * * Description: Whether the committee is visible to all users`),
    FormationDate: z.date().nullable().describe(`
        * * Field Name: FormationDate
        * * Display Name: Formation Date
        * * SQL Data Type: date
        * * Description: Date the committee was formed`),
    DissolutionDate: z.date().nullable().describe(`
        * * Field Name: DissolutionDate
        * * Display Name: Dissolution Date
        * * SQL Data Type: date
        * * Description: Date the committee was dissolved, if applicable`),
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
    Type: z.string().describe(`
        * * Field Name: Type
        * * Display Name: Type
        * * SQL Data Type: nvarchar(100)`),
    ParentCommittee: z.string().nullable().describe(`
        * * Field Name: ParentCommittee
        * * Display Name: Parent Committee
        * * SQL Data Type: nvarchar(255)`),
    Organization: z.string().nullable().describe(`
        * * Field Name: Organization
        * * Display Name: Organization
        * * SQL Data Type: nvarchar(255)`),
    RootParentCommitteeID: z.string().nullable().describe(`
        * * Field Name: RootParentCommitteeID
        * * Display Name: Root Parent Committee
        * * SQL Data Type: uniqueidentifier`),
});

export type CommitteeEntityType = z.infer<typeof CommitteeSchema>;

/**
 * zod schema definition for the entity Committees: Meetings
 */
export const MeetingSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    CommitteeID: z.string().describe(`
        * * Field Name: CommitteeID
        * * Display Name: Committee
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Committees (vwCommittees.ID)`),
    Title: z.string().describe(`
        * * Field Name: Title
        * * Display Name: Title
        * * SQL Data Type: nvarchar(255)
        * * Description: Title of the meeting`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Detailed description or purpose of the meeting`),
    StartDateTime: z.date().describe(`
        * * Field Name: StartDateTime
        * * Display Name: Start Date & Time
        * * SQL Data Type: datetimeoffset
        * * Description: Scheduled start date and time with timezone offset`),
    EndDateTime: z.date().nullable().describe(`
        * * Field Name: EndDateTime
        * * Display Name: End Date & Time
        * * SQL Data Type: datetimeoffset
        * * Description: Scheduled end date and time with timezone offset`),
    TimeZone: z.string().describe(`
        * * Field Name: TimeZone
        * * Display Name: Time Zone
        * * SQL Data Type: nvarchar(50)
        * * Default Value: America/New_York
        * * Description: IANA timezone identifier for the meeting`),
    LocationType: z.union([z.literal('Hybrid'), z.literal('InPerson'), z.literal('Virtual')]).describe(`
        * * Field Name: LocationType
        * * Display Name: Location Type
        * * SQL Data Type: nvarchar(50)
        * * Default Value: Virtual
    * * Value List Type: List
    * * Possible Values 
    *   * Hybrid
    *   * InPerson
    *   * Virtual
        * * Description: Meeting format: Virtual, InPerson, or Hybrid`),
    LocationText: z.string().nullable().describe(`
        * * Field Name: LocationText
        * * Display Name: Location Details
        * * SQL Data Type: nvarchar(500)
        * * Description: Physical address or room name for in-person meetings`),
    VideoProvider: z.string().nullable().describe(`
        * * Field Name: VideoProvider
        * * Display Name: Video Provider
        * * SQL Data Type: nvarchar(50)
        * * Description: Video conferencing provider: Zoom, Teams, Meet, etc.`),
    VideoMeetingID: z.string().nullable().describe(`
        * * Field Name: VideoMeetingID
        * * Display Name: Video Meeting ID
        * * SQL Data Type: nvarchar(255)
        * * Description: External meeting ID from the video provider`),
    VideoJoinURL: z.string().nullable().describe(`
        * * Field Name: VideoJoinURL
        * * Display Name: Video Join URL
        * * SQL Data Type: nvarchar(1000)
        * * Description: URL to join the video meeting`),
    VideoRecordingURL: z.string().nullable().describe(`
        * * Field Name: VideoRecordingURL
        * * Display Name: Video Recording URL
        * * SQL Data Type: nvarchar(1000)
        * * Description: URL to the meeting recording after completion`),
    TranscriptURL: z.string().nullable().describe(`
        * * Field Name: TranscriptURL
        * * Display Name: Transcript URL
        * * SQL Data Type: nvarchar(1000)
        * * Description: URL to the meeting transcript`),
    Status: z.union([z.literal('Cancelled'), z.literal('Completed'), z.literal('Draft'), z.literal('InProgress'), z.literal('Postponed'), z.literal('Scheduled')]).describe(`
        * * Field Name: Status
        * * Display Name: Status
        * * SQL Data Type: nvarchar(50)
        * * Default Value: Scheduled
    * * Value List Type: List
    * * Possible Values 
    *   * Cancelled
    *   * Completed
    *   * Draft
    *   * InProgress
    *   * Postponed
    *   * Scheduled
        * * Description: Current status: Draft, Scheduled, InProgress, Completed, Cancelled, Postponed`),
    CalendarEventID: z.string().nullable().describe(`
        * * Field Name: CalendarEventID
        * * Display Name: Calendar Event ID
        * * SQL Data Type: nvarchar(255)
        * * Description: External calendar event ID for sync purposes`),
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
    Committee: z.string().describe(`
        * * Field Name: Committee
        * * Display Name: Committee Name
        * * SQL Data Type: nvarchar(255)`),
});

export type MeetingEntityType = z.infer<typeof MeetingSchema>;

/**
 * zod schema definition for the entity Committees: Memberships
 */
export const MembershipSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    CommitteeID: z.string().describe(`
        * * Field Name: CommitteeID
        * * Display Name: Committee
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Committees (vwCommittees.ID)`),
    PersonID: z.string().describe(`
        * * Field Name: PersonID
        * * Display Name: Person
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Common: People (vwPeople.ID)`),
    RoleID: z.string().describe(`
        * * Field Name: RoleID
        * * Display Name: Role
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Roles (vwRoles.ID)`),
    TermID: z.string().nullable().describe(`
        * * Field Name: TermID
        * * Display Name: Term
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Terms (vwTerms.ID)`),
    StartDate: z.date().describe(`
        * * Field Name: StartDate
        * * Display Name: Start Date
        * * SQL Data Type: date
        * * Description: Date the membership started`),
    EndDate: z.date().nullable().describe(`
        * * Field Name: EndDate
        * * Display Name: End Date
        * * SQL Data Type: date
        * * Description: Date the membership ended, if applicable`),
    Status: z.union([z.literal('Active'), z.literal('Ended'), z.literal('Pending'), z.literal('Suspended')]).describe(`
        * * Field Name: Status
        * * Display Name: Status
        * * SQL Data Type: nvarchar(50)
        * * Default Value: Active
    * * Value List Type: List
    * * Possible Values 
    *   * Active
    *   * Ended
    *   * Pending
    *   * Suspended
        * * Description: Current status: Active, Pending, Ended, or Suspended`),
    EndReason: z.string().nullable().describe(`
        * * Field Name: EndReason
        * * Display Name: End Reason
        * * SQL Data Type: nvarchar(100)
        * * Description: Reason the membership ended: Term ended, Resigned, Removed, etc.`),
    Notes: z.string().nullable().describe(`
        * * Field Name: Notes
        * * Display Name: Notes
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Additional notes about this membership`),
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
    Committee: z.string().describe(`
        * * Field Name: Committee
        * * Display Name: Committee Name
        * * SQL Data Type: nvarchar(255)`),
    Role: z.string().describe(`
        * * Field Name: Role
        * * Display Name: Role Name
        * * SQL Data Type: nvarchar(100)`),
    Term: z.string().nullable().describe(`
        * * Field Name: Term
        * * Display Name: Term Name
        * * SQL Data Type: nvarchar(100)`),
});

export type MembershipEntityType = z.infer<typeof MembershipSchema>;

/**
 * zod schema definition for the entity Committees: Minutes
 */
export const MinuteSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    ArtifactID: z.string().describe(`
        * * Field Name: ArtifactID
        * * Display Name: Artifact
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Artifacts (vwArtifacts.ID)`),
    ApprovalStatus: z.union([z.literal('Approved'), z.literal('Draft'), z.literal('PendingApproval'), z.literal('Rejected')]).describe(`
        * * Field Name: ApprovalStatus
        * * Display Name: Approval Status
        * * SQL Data Type: nvarchar(50)
        * * Default Value: Draft
    * * Value List Type: List
    * * Possible Values 
    *   * Approved
    *   * Draft
    *   * PendingApproval
    *   * Rejected
        * * Description: Current approval status: Draft, PendingApproval, Approved, Rejected`),
    ApprovedAt: z.date().nullable().describe(`
        * * Field Name: ApprovedAt
        * * Display Name: Approved At
        * * SQL Data Type: datetimeoffset
        * * Description: Timestamp when the minutes were approved`),
    ApprovedByMeetingID: z.string().nullable().describe(`
        * * Field Name: ApprovedByMeetingID
        * * Display Name: Approved By Meeting
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Meetings (vwMeetings.ID)
        * * Description: Reference to the meeting at which these minutes were approved (typically the next meeting)`),
    Notes: z.string().nullable().describe(`
        * * Field Name: Notes
        * * Display Name: Notes
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Additional notes about the minutes`),
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

export type MinuteEntityType = z.infer<typeof MinuteSchema>;

/**
 * zod schema definition for the entity Committees: Motions
 */
export const MotionSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    MeetingID: z.string().describe(`
        * * Field Name: MeetingID
        * * Display Name: Meeting
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Meetings (vwMeetings.ID)`),
    AgendaItemID: z.string().nullable().describe(`
        * * Field Name: AgendaItemID
        * * Display Name: Agenda Item
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Agenda Items (vwAgendaItems.ID)`),
    Sequence: z.number().describe(`
        * * Field Name: Sequence
        * * Display Name: Sequence
        * * SQL Data Type: int
        * * Default Value: 1
        * * Description: Display order when multiple motions exist for the same agenda item`),
    Title: z.string().describe(`
        * * Field Name: Title
        * * Display Name: Title
        * * SQL Data Type: nvarchar(255)
        * * Description: Title of the motion`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Full text or description of the motion`),
    MovedByMembershipID: z.string().nullable().describe(`
        * * Field Name: MovedByMembershipID
        * * Display Name: Moved By
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Memberships (vwMemberships.ID)
        * * Description: The committee member who made the motion`),
    SecondedByMembershipID: z.string().nullable().describe(`
        * * Field Name: SecondedByMembershipID
        * * Display Name: Seconded By
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Memberships (vwMemberships.ID)
        * * Description: The committee member who seconded the motion`),
    Result: z.union([z.literal('Failed'), z.literal('Passed'), z.literal('Pending'), z.literal('Tabled'), z.literal('Withdrawn')]).describe(`
        * * Field Name: Result
        * * Display Name: Result
        * * SQL Data Type: nvarchar(50)
        * * Default Value: Pending
    * * Value List Type: List
    * * Possible Values 
    *   * Failed
    *   * Passed
    *   * Pending
    *   * Tabled
    *   * Withdrawn
        * * Description: Outcome of the vote: Pending, Passed, Failed, Tabled, Withdrawn`),
    ResultSummary: z.string().nullable().describe(`
        * * Field Name: ResultSummary
        * * Display Name: Result Summary
        * * SQL Data Type: nvarchar(255)
        * * Description: Human-readable vote tally, e.g. 7-2-1 or Passed unanimously`),
    YesCount: z.number().nullable().describe(`
        * * Field Name: YesCount
        * * Display Name: Yes Count
        * * SQL Data Type: int
        * * Description: Number of Yes votes`),
    NoCount: z.number().nullable().describe(`
        * * Field Name: NoCount
        * * Display Name: No Count
        * * SQL Data Type: int
        * * Description: Number of No votes`),
    AbstainCount: z.number().nullable().describe(`
        * * Field Name: AbstainCount
        * * Display Name: Abstain Count
        * * SQL Data Type: int
        * * Description: Number of Abstain votes`),
    Notes: z.string().nullable().describe(`
        * * Field Name: Notes
        * * Display Name: Notes
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Additional notes about the motion or vote`),
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

export type MotionEntityType = z.infer<typeof MotionSchema>;

/**
 * zod schema definition for the entity Committees: Roles
 */
export const RoleSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Display name for the role`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Detailed description of role responsibilities`),
    IsOfficer: z.boolean().describe(`
        * * Field Name: IsOfficer
        * * Display Name: Officer Role
        * * SQL Data Type: bit
        * * Default Value: 0
        * * Description: Whether this is an officer role like Chair or Secretary`),
    IsVotingRole: z.boolean().describe(`
        * * Field Name: IsVotingRole
        * * Display Name: Voting Role
        * * SQL Data Type: bit
        * * Default Value: 1
        * * Description: Whether members in this role can vote`),
    DefaultPermissionsJSON: z.string().nullable().describe(`
        * * Field Name: DefaultPermissionsJSON
        * * Display Name: Default Permissions
        * * SQL Data Type: nvarchar(MAX)
        * * Description: JSON object defining default permissions for this role`),
    Sequence: z.number().describe(`
        * * Field Name: Sequence
        * * Display Name: Sequence
        * * SQL Data Type: int
        * * Default Value: 100
        * * Description: Display order for sorting roles`),
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

export type RoleEntityType = z.infer<typeof RoleSchema>;

/**
 * zod schema definition for the entity Committees: Terms
 */
export const TermSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    CommitteeID: z.string().describe(`
        * * Field Name: CommitteeID
        * * Display Name: Committee
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Committees (vwCommittees.ID)`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Term Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Display name for the term, e.g. 2025-2026`),
    StartDate: z.date().describe(`
        * * Field Name: StartDate
        * * Display Name: Start Date
        * * SQL Data Type: date
        * * Description: Start date of the term`),
    EndDate: z.date().nullable().describe(`
        * * Field Name: EndDate
        * * Display Name: End Date
        * * SQL Data Type: date
        * * Description: End date of the term`),
    Status: z.union([z.literal('Active'), z.literal('Completed'), z.literal('Upcoming')]).describe(`
        * * Field Name: Status
        * * Display Name: Status
        * * SQL Data Type: nvarchar(50)
        * * Default Value: Active
    * * Value List Type: List
    * * Possible Values 
    *   * Active
    *   * Completed
    *   * Upcoming
        * * Description: Current status: Active, Upcoming, or Completed`),
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
    Committee: z.string().describe(`
        * * Field Name: Committee
        * * Display Name: Committee Name
        * * SQL Data Type: nvarchar(255)`),
});

export type TermEntityType = z.infer<typeof TermSchema>;

/**
 * zod schema definition for the entity Committees: Types
 */
export const TypeSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    Name: z.string().describe(`
        * * Field Name: Name
        * * Display Name: Name
        * * SQL Data Type: nvarchar(100)
        * * Description: Display name for the committee type`),
    Description: z.string().nullable().describe(`
        * * Field Name: Description
        * * Display Name: Description
        * * SQL Data Type: nvarchar(MAX)
        * * Description: Detailed description of this committee type`),
    IsStandards: z.boolean().describe(`
        * * Field Name: IsStandards
        * * Display Name: Standards Committee
        * * SQL Data Type: bit
        * * Default Value: 0
        * * Description: Whether this type is for standards development committees`),
    DefaultTermMonths: z.number().nullable().describe(`
        * * Field Name: DefaultTermMonths
        * * Display Name: Default Term (Months)
        * * SQL Data Type: int
        * * Description: Default term length in months for committees of this type`),
    IconClass: z.string().nullable().describe(`
        * * Field Name: IconClass
        * * Display Name: Icon Class
        * * SQL Data Type: nvarchar(100)
        * * Description: Font Awesome icon class for UI display`),
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

export type TypeEntityType = z.infer<typeof TypeSchema>;

/**
 * zod schema definition for the entity Committees: Votes
 */
export const VoteSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    MotionID: z.string().describe(`
        * * Field Name: MotionID
        * * Display Name: Motion
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Motions (vwMotions.ID)`),
    MembershipID: z.string().describe(`
        * * Field Name: MembershipID
        * * Display Name: Member
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Committees: Memberships (vwMemberships.ID)`),
    VoteValue: z.union([z.literal('Absent'), z.literal('Abstain'), z.literal('No'), z.literal('Yes')]).describe(`
        * * Field Name: VoteValue
        * * Display Name: Vote
        * * SQL Data Type: nvarchar(20)
    * * Value List Type: List
    * * Possible Values 
    *   * Absent
    *   * Abstain
    *   * No
    *   * Yes
        * * Description: The vote cast: Yes, No, Abstain, or Absent`),
    Notes: z.string().nullable().describe(`
        * * Field Name: Notes
        * * Display Name: Notes
        * * SQL Data Type: nvarchar(500)
        * * Description: Optional notes explaining the vote`),
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

export type VoteEntityType = z.infer<typeof VoteSchema>;

/**
 * zod schema definition for the entity Common: Address Links
 */
export const AddressLinkSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    AddressID: z.string().describe(`
        * * Field Name: AddressID
        * * Display Name: Address
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Common: Addresses (vwAddresses.ID)`),
    EntityID: z.string().describe(`
        * * Field Name: EntityID
        * * Display Name: Entity
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Entities (vwEntities.ID)`),
    RecordID: z.string().describe(`
        * * Field Name: RecordID
        * * Display Name: Record ID
        * * SQL Data Type: nvarchar(700)
        * * Description: Primary key value(s) of the linked record. NVARCHAR(700) to support concatenated composite keys for entities without single-valued primary keys`),
    AddressTypeID: z.string().describe(`
        * * Field Name: AddressTypeID
        * * Display Name: Address Type
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Common: Address Types (vwAddressTypes.ID)`),
    IsPrimary: z.boolean().describe(`
        * * Field Name: IsPrimary
        * * Display Name: Primary
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
    Entity: z.string().describe(`
        * * Field Name: Entity
        * * Display Name: Entity Name
        * * SQL Data Type: nvarchar(255)`),
    AddressType: z.string().describe(`
        * * Field Name: AddressType
        * * Display Name: Address Type
        * * SQL Data Type: nvarchar(100)`),
});

export type AddressLinkEntityType = z.infer<typeof AddressLinkSchema>;

/**
 * zod schema definition for the entity Common: Address Types
 */
export const AddressTypeSchema = z.object({
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
    DefaultRank: z.number().describe(`
        * * Field Name: DefaultRank
        * * Display Name: Default Rank
        * * SQL Data Type: int
        * * Default Value: 100
        * * Description: Default sort order for this address type in dropdown lists. Lower values appear first. Can be overridden per-record via AddressLink.Rank`),
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

export type AddressTypeEntityType = z.infer<typeof AddressTypeSchema>;

/**
 * zod schema definition for the entity Common: Addresses
 */
export const AddressSchema = z.object({
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

export type AddressEntityType = z.infer<typeof AddressSchema>;

/**
 * zod schema definition for the entity Common: Contact Methods
 */
export const ContactMethodSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    PersonID: z.string().nullable().describe(`
        * * Field Name: PersonID
        * * Display Name: Person
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Common: People (vwPeople.ID)`),
    OrganizationID: z.string().nullable().describe(`
        * * Field Name: OrganizationID
        * * Display Name: Organization
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Common: Organizations (vwOrganizations.ID)`),
    ContactTypeID: z.string().describe(`
        * * Field Name: ContactTypeID
        * * Display Name: Contact Type
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Common: Contact Types (vwContactTypes.ID)`),
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
        * * Display Name: Primary
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
    Organization: z.string().nullable().describe(`
        * * Field Name: Organization
        * * Display Name: Organization
        * * SQL Data Type: nvarchar(255)`),
    ContactType: z.string().describe(`
        * * Field Name: ContactType
        * * Display Name: Contact Type
        * * SQL Data Type: nvarchar(100)`),
});

export type ContactMethodEntityType = z.infer<typeof ContactMethodSchema>;

/**
 * zod schema definition for the entity Common: Contact Types
 */
export const ContactTypeSchema = z.object({
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

export type ContactTypeEntityType = z.infer<typeof ContactTypeSchema>;

/**
 * zod schema definition for the entity Common: Organization Types
 */
export const OrganizationTypeSchema = z.object({
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

export type OrganizationTypeEntityType = z.infer<typeof OrganizationTypeSchema>;

/**
 * zod schema definition for the entity Common: Organizations
 */
export const OrganizationSchema = z.object({
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
        * * Related Entity/Foreign Key: Common: Organization Types (vwOrganizationTypes.ID)`),
    ParentID: z.string().nullable().describe(`
        * * Field Name: ParentID
        * * Display Name: Parent
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Common: Organizations (vwOrganizations.ID)`),
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
        * * Display Name: Parent
        * * SQL Data Type: nvarchar(255)`),
    RootParentID: z.string().nullable().describe(`
        * * Field Name: RootParentID
        * * Display Name: Root Parent
        * * SQL Data Type: uniqueidentifier`),
});

export type OrganizationEntityType = z.infer<typeof OrganizationSchema>;

/**
 * zod schema definition for the entity Common: People
 */
export const PersonSchema = z.object({
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
        * * Display Name: Linked User
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Users (vwUsers.ID)`),
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
    LinkedUser: z.string().nullable().describe(`
        * * Field Name: LinkedUser
        * * Display Name: Linked User
        * * SQL Data Type: nvarchar(100)`),
});

export type PersonEntityType = z.infer<typeof PersonSchema>;

/**
 * zod schema definition for the entity Common: Relationship Types
 */
export const RelationshipTypeSchema = z.object({
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

export type RelationshipTypeEntityType = z.infer<typeof RelationshipTypeSchema>;

/**
 * zod schema definition for the entity Common: Relationships
 */
export const RelationshipSchema = z.object({
    ID: z.string().describe(`
        * * Field Name: ID
        * * Display Name: ID
        * * SQL Data Type: uniqueidentifier
        * * Default Value: newsequentialid()`),
    RelationshipTypeID: z.string().describe(`
        * * Field Name: RelationshipTypeID
        * * Display Name: Relationship Type
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Common: Relationship Types (vwRelationshipTypes.ID)`),
    FromPersonID: z.string().nullable().describe(`
        * * Field Name: FromPersonID
        * * Display Name: From Person
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Common: People (vwPeople.ID)`),
    FromOrganizationID: z.string().nullable().describe(`
        * * Field Name: FromOrganizationID
        * * Display Name: From Organization
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Common: Organizations (vwOrganizations.ID)`),
    ToPersonID: z.string().nullable().describe(`
        * * Field Name: ToPersonID
        * * Display Name: To Person
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Common: People (vwPeople.ID)`),
    ToOrganizationID: z.string().nullable().describe(`
        * * Field Name: ToOrganizationID
        * * Display Name: To Organization
        * * SQL Data Type: uniqueidentifier
        * * Related Entity/Foreign Key: Common: Organizations (vwOrganizations.ID)`),
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
    FromOrganization: z.string().nullable().describe(`
        * * Field Name: FromOrganization
        * * Display Name: From Organization Name
        * * SQL Data Type: nvarchar(255)`),
    ToOrganization: z.string().nullable().describe(`
        * * Field Name: ToOrganization
        * * Display Name: To Organization Name
        * * SQL Data Type: nvarchar(255)`),
});

export type RelationshipEntityType = z.infer<typeof RelationshipSchema>;
 
 

/**
 * Committees: Action Items - strongly typed entity sub-class
 * * Schema: __mj_Committees
 * * Base Table: ActionItem
 * * Base View: vwActionItems
 * * @description Tasks and action items assigned from committees or meetings
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Committees: Action Items')
export class ActionItemEntity extends BaseEntity<ActionItemEntityType> {
    /**
    * Loads the Committees: Action Items record from the database
    * @param ID: string - primary key value to load the Committees: Action Items record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof ActionItemEntity
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
    * * Field Name: CommitteeID
    * * Display Name: Committee
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Committees (vwCommittees.ID)
    */
    get CommitteeID(): string {
        return this.Get('CommitteeID');
    }
    set CommitteeID(value: string) {
        this.Set('CommitteeID', value);
    }

    /**
    * * Field Name: MeetingID
    * * Display Name: Meeting
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Meetings (vwMeetings.ID)
    */
    get MeetingID(): string | null {
        return this.Get('MeetingID');
    }
    set MeetingID(value: string | null) {
        this.Set('MeetingID', value);
    }

    /**
    * * Field Name: AgendaItemID
    * * Display Name: Agenda Item
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Agenda Items (vwAgendaItems.ID)
    */
    get AgendaItemID(): string | null {
        return this.Get('AgendaItemID');
    }
    set AgendaItemID(value: string | null) {
        this.Set('AgendaItemID', value);
    }

    /**
    * * Field Name: Title
    * * Display Name: Title
    * * SQL Data Type: nvarchar(255)
    * * Description: Title of the action item
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
    * * Description: Detailed description of what needs to be done
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: AssignedToPersonID
    * * Display Name: Assignee
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Common: People (vwPeople.ID)
    */
    get AssignedToPersonID(): string {
        return this.Get('AssignedToPersonID');
    }
    set AssignedToPersonID(value: string) {
        this.Set('AssignedToPersonID', value);
    }

    /**
    * * Field Name: AssignedByPersonID
    * * Display Name: Assigned By
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Common: People (vwPeople.ID)
    */
    get AssignedByPersonID(): string | null {
        return this.Get('AssignedByPersonID');
    }
    set AssignedByPersonID(value: string | null) {
        this.Set('AssignedByPersonID', value);
    }

    /**
    * * Field Name: DueDate
    * * Display Name: Due Date
    * * SQL Data Type: date
    * * Description: Due date for completion
    */
    get DueDate(): Date | null {
        return this.Get('DueDate');
    }
    set DueDate(value: Date | null) {
        this.Set('DueDate', value);
    }

    /**
    * * Field Name: Priority
    * * Display Name: Priority
    * * SQL Data Type: nvarchar(20)
    * * Default Value: Medium
    * * Value List Type: List
    * * Possible Values 
    *   * Critical
    *   * High
    *   * Low
    *   * Medium
    * * Description: Priority level: Low, Medium, High, Critical
    */
    get Priority(): 'Critical' | 'High' | 'Low' | 'Medium' {
        return this.Get('Priority');
    }
    set Priority(value: 'Critical' | 'High' | 'Low' | 'Medium') {
        this.Set('Priority', value);
    }

    /**
    * * Field Name: Status
    * * Display Name: Status
    * * SQL Data Type: nvarchar(50)
    * * Default Value: Open
    * * Value List Type: List
    * * Possible Values 
    *   * Blocked
    *   * Cancelled
    *   * Completed
    *   * InProgress
    *   * Open
    * * Description: Current status: Open, InProgress, Blocked, Completed, Cancelled
    */
    get Status(): 'Blocked' | 'Cancelled' | 'Completed' | 'InProgress' | 'Open' {
        return this.Get('Status');
    }
    set Status(value: 'Blocked' | 'Cancelled' | 'Completed' | 'InProgress' | 'Open') {
        this.Set('Status', value);
    }

    /**
    * * Field Name: CompletedAt
    * * Display Name: Completed At
    * * SQL Data Type: datetimeoffset
    * * Description: Timestamp when the action item was completed
    */
    get CompletedAt(): Date | null {
        return this.Get('CompletedAt');
    }
    set CompletedAt(value: Date | null) {
        this.Set('CompletedAt', value);
    }

    /**
    * * Field Name: CompletionNotes
    * * Display Name: Completion Notes
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Notes about how the item was completed
    */
    get CompletionNotes(): string | null {
        return this.Get('CompletionNotes');
    }
    set CompletionNotes(value: string | null) {
        this.Set('CompletionNotes', value);
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
    * * Field Name: Committee
    * * Display Name: Committee Name
    * * SQL Data Type: nvarchar(255)
    */
    get Committee(): string {
        return this.Get('Committee');
    }
}


/**
 * Committees: Agenda Items - strongly typed entity sub-class
 * * Schema: __mj_Committees
 * * Base Table: AgendaItem
 * * Base View: vwAgendaItems
 * * @description Structured agenda items for meetings with hierarchy support
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Committees: Agenda Items')
export class AgendaItemEntity extends BaseEntity<AgendaItemEntityType> {
    /**
    * Loads the Committees: Agenda Items record from the database
    * @param ID: string - primary key value to load the Committees: Agenda Items record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof AgendaItemEntity
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
    * * Field Name: MeetingID
    * * Display Name: Meeting
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Meetings (vwMeetings.ID)
    */
    get MeetingID(): string {
        return this.Get('MeetingID');
    }
    set MeetingID(value: string) {
        this.Set('MeetingID', value);
    }

    /**
    * * Field Name: ParentAgendaItemID
    * * Display Name: Parent Agenda Item
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Agenda Items (vwAgendaItems.ID)
    */
    get ParentAgendaItemID(): string | null {
        return this.Get('ParentAgendaItemID');
    }
    set ParentAgendaItemID(value: string | null) {
        this.Set('ParentAgendaItemID', value);
    }

    /**
    * * Field Name: Sequence
    * * Display Name: Sequence
    * * SQL Data Type: int
    * * Description: Display order within the meeting agenda
    */
    get Sequence(): number {
        return this.Get('Sequence');
    }
    set Sequence(value: number) {
        this.Set('Sequence', value);
    }

    /**
    * * Field Name: Title
    * * Display Name: Title
    * * SQL Data Type: nvarchar(255)
    * * Description: Title of the agenda item
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
    * * Description: Detailed description of the agenda item
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: PresenterPersonID
    * * Display Name: Presenter
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Common: People (vwPeople.ID)
    */
    get PresenterPersonID(): string | null {
        return this.Get('PresenterPersonID');
    }
    set PresenterPersonID(value: string | null) {
        this.Set('PresenterPersonID', value);
    }

    /**
    * * Field Name: DurationMinutes
    * * Display Name: Duration (Minutes)
    * * SQL Data Type: int
    * * Description: Estimated duration in minutes
    */
    get DurationMinutes(): number | null {
        return this.Get('DurationMinutes');
    }
    set DurationMinutes(value: number | null) {
        this.Set('DurationMinutes', value);
    }

    /**
    * * Field Name: ItemType
    * * Display Name: Item Type
    * * SQL Data Type: nvarchar(50)
    * * Default Value: Discussion
    * * Value List Type: List
    * * Possible Values 
    *   * Action
    *   * Discussion
    *   * Information
    *   * Other
    *   * Report
    *   * Vote
    * * Description: Type of item: Information, Discussion, Action, Vote, Report, Other
    */
    get ItemType(): 'Action' | 'Discussion' | 'Information' | 'Other' | 'Report' | 'Vote' {
        return this.Get('ItemType');
    }
    set ItemType(value: 'Action' | 'Discussion' | 'Information' | 'Other' | 'Report' | 'Vote') {
        this.Set('ItemType', value);
    }

    /**
    * * Field Name: RelatedDocumentURL
    * * Display Name: Related Document URL
    * * SQL Data Type: nvarchar(1000)
    * * Description: URL to related document for this item
    */
    get RelatedDocumentURL(): string | null {
        return this.Get('RelatedDocumentURL');
    }
    set RelatedDocumentURL(value: string | null) {
        this.Set('RelatedDocumentURL', value);
    }

    /**
    * * Field Name: Status
    * * Display Name: Status
    * * SQL Data Type: nvarchar(50)
    * * Default Value: Pending
    * * Value List Type: List
    * * Possible Values 
    *   * Completed
    *   * Discussed
    *   * Pending
    *   * Skipped
    *   * Tabled
    * * Description: Current status: Pending, Discussed, Tabled, Completed, Skipped
    */
    get Status(): 'Completed' | 'Discussed' | 'Pending' | 'Skipped' | 'Tabled' {
        return this.Get('Status');
    }
    set Status(value: 'Completed' | 'Discussed' | 'Pending' | 'Skipped' | 'Tabled') {
        this.Set('Status', value);
    }

    /**
    * * Field Name: Notes
    * * Display Name: Notes
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Discussion notes and outcomes captured during the meeting
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
    * * Field Name: RootParentAgendaItemID
    * * Display Name: Root Parent Agenda Item
    * * SQL Data Type: uniqueidentifier
    */
    get RootParentAgendaItemID(): string | null {
        return this.Get('RootParentAgendaItemID');
    }
}


/**
 * Committees: Artifact Types - strongly typed entity sub-class
 * * Schema: __mj_Committees
 * * Base Table: ArtifactType
 * * Base View: vwArtifactTypes
 * * @description Categories of committee artifacts with optional extension entity for type-specific fields
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Committees: Artifact Types')
export class ArtifactTypeEntity extends BaseEntity<ArtifactTypeEntityType> {
    /**
    * Loads the Committees: Artifact Types record from the database
    * @param ID: string - primary key value to load the Committees: Artifact Types record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof ArtifactTypeEntity
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
    * * Description: Display name for the artifact type
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
    * * Description: Detailed description of this artifact type
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: ExtendedEntityID
    * * Display Name: Extended Entity ID
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Entities (vwEntities.ID)
    * * Description: Optional reference to an MJ Entity that provides additional fields for this artifact type via a 1:1 extension table
    */
    get ExtendedEntityID(): string | null {
        return this.Get('ExtendedEntityID');
    }
    set ExtendedEntityID(value: string | null) {
        this.Set('ExtendedEntityID', value);
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
    * * Field Name: ExtendedEntity
    * * Display Name: Extended Entity
    * * SQL Data Type: nvarchar(255)
    */
    get ExtendedEntity(): string | null {
        return this.Get('ExtendedEntity');
    }
}


/**
 * Committees: Artifacts - strongly typed entity sub-class
 * * Schema: __mj_Committees
 * * Base Table: Artifact
 * * Base View: vwArtifacts
 * * @description Links to external documents and files from various providers
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Committees: Artifacts')
export class ArtifactEntity extends BaseEntity<ArtifactEntityType> {
    /**
    * Loads the Committees: Artifacts record from the database
    * @param ID: string - primary key value to load the Committees: Artifacts record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof ArtifactEntity
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
    * * Field Name: CommitteeID
    * * Display Name: Committee
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Committees (vwCommittees.ID)
    */
    get CommitteeID(): string | null {
        return this.Get('CommitteeID');
    }
    set CommitteeID(value: string | null) {
        this.Set('CommitteeID', value);
    }

    /**
    * * Field Name: MeetingID
    * * Display Name: Meeting
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Meetings (vwMeetings.ID)
    */
    get MeetingID(): string | null {
        return this.Get('MeetingID');
    }
    set MeetingID(value: string | null) {
        this.Set('MeetingID', value);
    }

    /**
    * * Field Name: AgendaItemID
    * * Display Name: Agenda Item
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Agenda Items (vwAgendaItems.ID)
    */
    get AgendaItemID(): string | null {
        return this.Get('AgendaItemID');
    }
    set AgendaItemID(value: string | null) {
        this.Set('AgendaItemID', value);
    }

    /**
    * * Field Name: ActionItemID
    * * Display Name: Action Item
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Action Items (vwActionItems.ID)
    */
    get ActionItemID(): string | null {
        return this.Get('ActionItemID');
    }
    set ActionItemID(value: string | null) {
        this.Set('ActionItemID', value);
    }

    /**
    * * Field Name: Title
    * * Display Name: Title
    * * SQL Data Type: nvarchar(255)
    * * Description: Display title for the artifact
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
    * * Description: Description of the artifact contents
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: ArtifactTypeID
    * * Display Name: Artifact Type
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Artifact Types (vwArtifactTypes.ID)
    */
    get ArtifactTypeID(): string {
        return this.Get('ArtifactTypeID');
    }
    set ArtifactTypeID(value: string) {
        this.Set('ArtifactTypeID', value);
    }

    /**
    * * Field Name: Provider
    * * Display Name: Provider
    * * SQL Data Type: nvarchar(50)
    * * Value List Type: List
    * * Possible Values 
    *   * Box
    *   * Dropbox
    *   * GoogleDrive
    *   * OneDrive
    *   * SharePoint
    *   * URL
    * * Description: Storage provider: GoogleDrive, SharePoint, Box, OneDrive, Dropbox, URL
    */
    get Provider(): 'Box' | 'Dropbox' | 'GoogleDrive' | 'OneDrive' | 'SharePoint' | 'URL' {
        return this.Get('Provider');
    }
    set Provider(value: 'Box' | 'Dropbox' | 'GoogleDrive' | 'OneDrive' | 'SharePoint' | 'URL') {
        this.Set('Provider', value);
    }

    /**
    * * Field Name: ExternalID
    * * Display Name: External ID
    * * SQL Data Type: nvarchar(500)
    * * Description: Provider-specific document or file ID
    */
    get ExternalID(): string | null {
        return this.Get('ExternalID');
    }
    set ExternalID(value: string | null) {
        this.Set('ExternalID', value);
    }

    /**
    * * Field Name: URL
    * * Display Name: URL
    * * SQL Data Type: nvarchar(2000)
    * * Description: Direct URL to access the artifact
    */
    get URL(): string {
        return this.Get('URL');
    }
    set URL(value: string) {
        this.Set('URL', value);
    }

    /**
    * * Field Name: MimeType
    * * Display Name: MIME Type
    * * SQL Data Type: nvarchar(100)
    * * Description: MIME type of the file
    */
    get MimeType(): string | null {
        return this.Get('MimeType');
    }
    set MimeType(value: string | null) {
        this.Set('MimeType', value);
    }

    /**
    * * Field Name: FileSize
    * * Display Name: File Size
    * * SQL Data Type: bigint
    * * Description: File size in bytes
    */
    get FileSize(): number | null {
        return this.Get('FileSize');
    }
    set FileSize(value: number | null) {
        this.Set('FileSize', value);
    }

    /**
    * * Field Name: UploadedByPersonID
    * * Display Name: Uploaded By
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Common: People (vwPeople.ID)
    */
    get UploadedByPersonID(): string | null {
        return this.Get('UploadedByPersonID');
    }
    set UploadedByPersonID(value: string | null) {
        this.Set('UploadedByPersonID', value);
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
    * * Field Name: Committee
    * * Display Name: Committee Name
    * * SQL Data Type: nvarchar(255)
    */
    get Committee(): string | null {
        return this.Get('Committee');
    }

    /**
    * * Field Name: ArtifactType
    * * Display Name: Artifact Type Name
    * * SQL Data Type: nvarchar(100)
    */
    get ArtifactType(): string {
        return this.Get('ArtifactType');
    }
}


/**
 * Committees: Attendances - strongly typed entity sub-class
 * * Schema: __mj_Committees
 * * Base Table: Attendance
 * * Base View: vwAttendances
 * * @description Meeting attendance records for committee members
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Committees: Attendances')
export class AttendanceEntity extends BaseEntity<AttendanceEntityType> {
    /**
    * Loads the Committees: Attendances record from the database
    * @param ID: string - primary key value to load the Committees: Attendances record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof AttendanceEntity
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
    * * Field Name: MeetingID
    * * Display Name: Meeting
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Meetings (vwMeetings.ID)
    */
    get MeetingID(): string {
        return this.Get('MeetingID');
    }
    set MeetingID(value: string) {
        this.Set('MeetingID', value);
    }

    /**
    * * Field Name: PersonID
    * * Display Name: Attendee
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Common: People (vwPeople.ID)
    */
    get PersonID(): string {
        return this.Get('PersonID');
    }
    set PersonID(value: string) {
        this.Set('PersonID', value);
    }

    /**
    * * Field Name: AttendanceStatus
    * * Display Name: Attendance Status
    * * SQL Data Type: nvarchar(50)
    * * Default Value: Expected
    * * Value List Type: List
    * * Possible Values 
    *   * Absent
    *   * Excused
    *   * Expected
    *   * Partial
    *   * Present
    * * Description: Attendance status: Expected, Present, Absent, Excused, Partial
    */
    get AttendanceStatus(): 'Absent' | 'Excused' | 'Expected' | 'Partial' | 'Present' {
        return this.Get('AttendanceStatus');
    }
    set AttendanceStatus(value: 'Absent' | 'Excused' | 'Expected' | 'Partial' | 'Present') {
        this.Set('AttendanceStatus', value);
    }

    /**
    * * Field Name: JoinedAt
    * * Display Name: Joined At
    * * SQL Data Type: datetimeoffset
    * * Description: Timestamp when the attendee joined the meeting
    */
    get JoinedAt(): Date | null {
        return this.Get('JoinedAt');
    }
    set JoinedAt(value: Date | null) {
        this.Set('JoinedAt', value);
    }

    /**
    * * Field Name: LeftAt
    * * Display Name: Left At
    * * SQL Data Type: datetimeoffset
    * * Description: Timestamp when the attendee left the meeting
    */
    get LeftAt(): Date | null {
        return this.Get('LeftAt');
    }
    set LeftAt(value: Date | null) {
        this.Set('LeftAt', value);
    }

    /**
    * * Field Name: Notes
    * * Display Name: Notes
    * * SQL Data Type: nvarchar(500)
    * * Description: Additional notes about attendance
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
}


/**
 * Committees: Committees - strongly typed entity sub-class
 * * Schema: __mj_Committees
 * * Base Table: Committee
 * * Base View: vwCommittees
 * * @description Core committee records with hierarchy support
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Committees: Committees')
export class CommitteeEntity extends BaseEntity<CommitteeEntityType> {
    /**
    * Loads the Committees: Committees record from the database
    * @param ID: string - primary key value to load the Committees: Committees record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof CommitteeEntity
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
    * * Description: Official name of the committee
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
    * * Description: Detailed description of the committee purpose and scope
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: TypeID
    * * Display Name: Type
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Types (vwTypes.ID)
    */
    get TypeID(): string {
        return this.Get('TypeID');
    }
    set TypeID(value: string) {
        this.Set('TypeID', value);
    }

    /**
    * * Field Name: ParentCommitteeID
    * * Display Name: Parent Committee
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Committees (vwCommittees.ID)
    */
    get ParentCommitteeID(): string | null {
        return this.Get('ParentCommitteeID');
    }
    set ParentCommitteeID(value: string | null) {
        this.Set('ParentCommitteeID', value);
    }

    /**
    * * Field Name: OrganizationID
    * * Display Name: Organization
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Common: Organizations (vwOrganizations.ID)
    */
    get OrganizationID(): string | null {
        return this.Get('OrganizationID');
    }
    set OrganizationID(value: string | null) {
        this.Set('OrganizationID', value);
    }

    /**
    * * Field Name: CharterDocumentURL
    * * Display Name: Charter Document URL
    * * SQL Data Type: nvarchar(1000)
    * * Description: URL to the committee charter document
    */
    get CharterDocumentURL(): string | null {
        return this.Get('CharterDocumentURL');
    }
    set CharterDocumentURL(value: string | null) {
        this.Set('CharterDocumentURL', value);
    }

    /**
    * * Field Name: MissionStatement
    * * Display Name: Mission Statement
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Brief statement of the committee mission
    */
    get MissionStatement(): string | null {
        return this.Get('MissionStatement');
    }
    set MissionStatement(value: string | null) {
        this.Set('MissionStatement', value);
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
    *   * Pending
    * * Description: Current status: Active, Inactive, Pending, or Dissolved
    */
    get Status(): 'Active' | 'Dissolved' | 'Inactive' | 'Pending' {
        return this.Get('Status');
    }
    set Status(value: 'Active' | 'Dissolved' | 'Inactive' | 'Pending') {
        this.Set('Status', value);
    }

    /**
    * * Field Name: IsPublic
    * * Display Name: Public
    * * SQL Data Type: bit
    * * Default Value: 1
    * * Description: Whether the committee is visible to all users
    */
    get IsPublic(): boolean {
        return this.Get('IsPublic');
    }
    set IsPublic(value: boolean) {
        this.Set('IsPublic', value);
    }

    /**
    * * Field Name: FormationDate
    * * Display Name: Formation Date
    * * SQL Data Type: date
    * * Description: Date the committee was formed
    */
    get FormationDate(): Date | null {
        return this.Get('FormationDate');
    }
    set FormationDate(value: Date | null) {
        this.Set('FormationDate', value);
    }

    /**
    * * Field Name: DissolutionDate
    * * Display Name: Dissolution Date
    * * SQL Data Type: date
    * * Description: Date the committee was dissolved, if applicable
    */
    get DissolutionDate(): Date | null {
        return this.Get('DissolutionDate');
    }
    set DissolutionDate(value: Date | null) {
        this.Set('DissolutionDate', value);
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
    * * Field Name: Type
    * * Display Name: Type
    * * SQL Data Type: nvarchar(100)
    */
    get Type(): string {
        return this.Get('Type');
    }

    /**
    * * Field Name: ParentCommittee
    * * Display Name: Parent Committee
    * * SQL Data Type: nvarchar(255)
    */
    get ParentCommittee(): string | null {
        return this.Get('ParentCommittee');
    }

    /**
    * * Field Name: Organization
    * * Display Name: Organization
    * * SQL Data Type: nvarchar(255)
    */
    get Organization(): string | null {
        return this.Get('Organization');
    }

    /**
    * * Field Name: RootParentCommitteeID
    * * Display Name: Root Parent Committee
    * * SQL Data Type: uniqueidentifier
    */
    get RootParentCommitteeID(): string | null {
        return this.Get('RootParentCommitteeID');
    }
}


/**
 * Committees: Meetings - strongly typed entity sub-class
 * * Schema: __mj_Committees
 * * Base Table: Meeting
 * * Base View: vwMeetings
 * * @description Committee meeting records with scheduling and video conferencing info
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Committees: Meetings')
export class MeetingEntity extends BaseEntity<MeetingEntityType> {
    /**
    * Loads the Committees: Meetings record from the database
    * @param ID: string - primary key value to load the Committees: Meetings record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof MeetingEntity
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
    * * Field Name: CommitteeID
    * * Display Name: Committee
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Committees (vwCommittees.ID)
    */
    get CommitteeID(): string {
        return this.Get('CommitteeID');
    }
    set CommitteeID(value: string) {
        this.Set('CommitteeID', value);
    }

    /**
    * * Field Name: Title
    * * Display Name: Title
    * * SQL Data Type: nvarchar(255)
    * * Description: Title of the meeting
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
    * * Description: Detailed description or purpose of the meeting
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: StartDateTime
    * * Display Name: Start Date & Time
    * * SQL Data Type: datetimeoffset
    * * Description: Scheduled start date and time with timezone offset
    */
    get StartDateTime(): Date {
        return this.Get('StartDateTime');
    }
    set StartDateTime(value: Date) {
        this.Set('StartDateTime', value);
    }

    /**
    * * Field Name: EndDateTime
    * * Display Name: End Date & Time
    * * SQL Data Type: datetimeoffset
    * * Description: Scheduled end date and time with timezone offset
    */
    get EndDateTime(): Date | null {
        return this.Get('EndDateTime');
    }
    set EndDateTime(value: Date | null) {
        this.Set('EndDateTime', value);
    }

    /**
    * * Field Name: TimeZone
    * * Display Name: Time Zone
    * * SQL Data Type: nvarchar(50)
    * * Default Value: America/New_York
    * * Description: IANA timezone identifier for the meeting
    */
    get TimeZone(): string {
        return this.Get('TimeZone');
    }
    set TimeZone(value: string) {
        this.Set('TimeZone', value);
    }

    /**
    * * Field Name: LocationType
    * * Display Name: Location Type
    * * SQL Data Type: nvarchar(50)
    * * Default Value: Virtual
    * * Value List Type: List
    * * Possible Values 
    *   * Hybrid
    *   * InPerson
    *   * Virtual
    * * Description: Meeting format: Virtual, InPerson, or Hybrid
    */
    get LocationType(): 'Hybrid' | 'InPerson' | 'Virtual' {
        return this.Get('LocationType');
    }
    set LocationType(value: 'Hybrid' | 'InPerson' | 'Virtual') {
        this.Set('LocationType', value);
    }

    /**
    * * Field Name: LocationText
    * * Display Name: Location Details
    * * SQL Data Type: nvarchar(500)
    * * Description: Physical address or room name for in-person meetings
    */
    get LocationText(): string | null {
        return this.Get('LocationText');
    }
    set LocationText(value: string | null) {
        this.Set('LocationText', value);
    }

    /**
    * * Field Name: VideoProvider
    * * Display Name: Video Provider
    * * SQL Data Type: nvarchar(50)
    * * Description: Video conferencing provider: Zoom, Teams, Meet, etc.
    */
    get VideoProvider(): string | null {
        return this.Get('VideoProvider');
    }
    set VideoProvider(value: string | null) {
        this.Set('VideoProvider', value);
    }

    /**
    * * Field Name: VideoMeetingID
    * * Display Name: Video Meeting ID
    * * SQL Data Type: nvarchar(255)
    * * Description: External meeting ID from the video provider
    */
    get VideoMeetingID(): string | null {
        return this.Get('VideoMeetingID');
    }
    set VideoMeetingID(value: string | null) {
        this.Set('VideoMeetingID', value);
    }

    /**
    * * Field Name: VideoJoinURL
    * * Display Name: Video Join URL
    * * SQL Data Type: nvarchar(1000)
    * * Description: URL to join the video meeting
    */
    get VideoJoinURL(): string | null {
        return this.Get('VideoJoinURL');
    }
    set VideoJoinURL(value: string | null) {
        this.Set('VideoJoinURL', value);
    }

    /**
    * * Field Name: VideoRecordingURL
    * * Display Name: Video Recording URL
    * * SQL Data Type: nvarchar(1000)
    * * Description: URL to the meeting recording after completion
    */
    get VideoRecordingURL(): string | null {
        return this.Get('VideoRecordingURL');
    }
    set VideoRecordingURL(value: string | null) {
        this.Set('VideoRecordingURL', value);
    }

    /**
    * * Field Name: TranscriptURL
    * * Display Name: Transcript URL
    * * SQL Data Type: nvarchar(1000)
    * * Description: URL to the meeting transcript
    */
    get TranscriptURL(): string | null {
        return this.Get('TranscriptURL');
    }
    set TranscriptURL(value: string | null) {
        this.Set('TranscriptURL', value);
    }

    /**
    * * Field Name: Status
    * * Display Name: Status
    * * SQL Data Type: nvarchar(50)
    * * Default Value: Scheduled
    * * Value List Type: List
    * * Possible Values 
    *   * Cancelled
    *   * Completed
    *   * Draft
    *   * InProgress
    *   * Postponed
    *   * Scheduled
    * * Description: Current status: Draft, Scheduled, InProgress, Completed, Cancelled, Postponed
    */
    get Status(): 'Cancelled' | 'Completed' | 'Draft' | 'InProgress' | 'Postponed' | 'Scheduled' {
        return this.Get('Status');
    }
    set Status(value: 'Cancelled' | 'Completed' | 'Draft' | 'InProgress' | 'Postponed' | 'Scheduled') {
        this.Set('Status', value);
    }

    /**
    * * Field Name: CalendarEventID
    * * Display Name: Calendar Event ID
    * * SQL Data Type: nvarchar(255)
    * * Description: External calendar event ID for sync purposes
    */
    get CalendarEventID(): string | null {
        return this.Get('CalendarEventID');
    }
    set CalendarEventID(value: string | null) {
        this.Set('CalendarEventID', value);
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
    * * Field Name: Committee
    * * Display Name: Committee Name
    * * SQL Data Type: nvarchar(255)
    */
    get Committee(): string {
        return this.Get('Committee');
    }
}


/**
 * Committees: Memberships - strongly typed entity sub-class
 * * Schema: __mj_Committees
 * * Base Table: Membership
 * * Base View: vwMemberships
 * * @description Person assignments to committees with roles and terms
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Committees: Memberships')
export class MembershipEntity extends BaseEntity<MembershipEntityType> {
    /**
    * Loads the Committees: Memberships record from the database
    * @param ID: string - primary key value to load the Committees: Memberships record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof MembershipEntity
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
    * * Field Name: CommitteeID
    * * Display Name: Committee
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Committees (vwCommittees.ID)
    */
    get CommitteeID(): string {
        return this.Get('CommitteeID');
    }
    set CommitteeID(value: string) {
        this.Set('CommitteeID', value);
    }

    /**
    * * Field Name: PersonID
    * * Display Name: Person
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Common: People (vwPeople.ID)
    */
    get PersonID(): string {
        return this.Get('PersonID');
    }
    set PersonID(value: string) {
        this.Set('PersonID', value);
    }

    /**
    * * Field Name: RoleID
    * * Display Name: Role
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Roles (vwRoles.ID)
    */
    get RoleID(): string {
        return this.Get('RoleID');
    }
    set RoleID(value: string) {
        this.Set('RoleID', value);
    }

    /**
    * * Field Name: TermID
    * * Display Name: Term
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Terms (vwTerms.ID)
    */
    get TermID(): string | null {
        return this.Get('TermID');
    }
    set TermID(value: string | null) {
        this.Set('TermID', value);
    }

    /**
    * * Field Name: StartDate
    * * Display Name: Start Date
    * * SQL Data Type: date
    * * Description: Date the membership started
    */
    get StartDate(): Date {
        return this.Get('StartDate');
    }
    set StartDate(value: Date) {
        this.Set('StartDate', value);
    }

    /**
    * * Field Name: EndDate
    * * Display Name: End Date
    * * SQL Data Type: date
    * * Description: Date the membership ended, if applicable
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
    *   * Pending
    *   * Suspended
    * * Description: Current status: Active, Pending, Ended, or Suspended
    */
    get Status(): 'Active' | 'Ended' | 'Pending' | 'Suspended' {
        return this.Get('Status');
    }
    set Status(value: 'Active' | 'Ended' | 'Pending' | 'Suspended') {
        this.Set('Status', value);
    }

    /**
    * * Field Name: EndReason
    * * Display Name: End Reason
    * * SQL Data Type: nvarchar(100)
    * * Description: Reason the membership ended: Term ended, Resigned, Removed, etc.
    */
    get EndReason(): string | null {
        return this.Get('EndReason');
    }
    set EndReason(value: string | null) {
        this.Set('EndReason', value);
    }

    /**
    * * Field Name: Notes
    * * Display Name: Notes
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Additional notes about this membership
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
    * * Field Name: Committee
    * * Display Name: Committee Name
    * * SQL Data Type: nvarchar(255)
    */
    get Committee(): string {
        return this.Get('Committee');
    }

    /**
    * * Field Name: Role
    * * Display Name: Role Name
    * * SQL Data Type: nvarchar(100)
    */
    get Role(): string {
        return this.Get('Role');
    }

    /**
    * * Field Name: Term
    * * Display Name: Term Name
    * * SQL Data Type: nvarchar(100)
    */
    get Term(): string | null {
        return this.Get('Term');
    }
}


/**
 * Committees: Minutes - strongly typed entity sub-class
 * * Schema: __mj_Committees
 * * Base Table: Minute
 * * Base View: vwMinutes
 * * @description Extension entity for Minutes artifacts with approval tracking
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Committees: Minutes')
export class MinuteEntity extends BaseEntity<MinuteEntityType> {
    /**
    * Loads the Committees: Minutes record from the database
    * @param ID: string - primary key value to load the Committees: Minutes record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof MinuteEntity
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
    * * Field Name: ArtifactID
    * * Display Name: Artifact
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Artifacts (vwArtifacts.ID)
    */
    get ArtifactID(): string {
        return this.Get('ArtifactID');
    }
    set ArtifactID(value: string) {
        this.Set('ArtifactID', value);
    }

    /**
    * * Field Name: ApprovalStatus
    * * Display Name: Approval Status
    * * SQL Data Type: nvarchar(50)
    * * Default Value: Draft
    * * Value List Type: List
    * * Possible Values 
    *   * Approved
    *   * Draft
    *   * PendingApproval
    *   * Rejected
    * * Description: Current approval status: Draft, PendingApproval, Approved, Rejected
    */
    get ApprovalStatus(): 'Approved' | 'Draft' | 'PendingApproval' | 'Rejected' {
        return this.Get('ApprovalStatus');
    }
    set ApprovalStatus(value: 'Approved' | 'Draft' | 'PendingApproval' | 'Rejected') {
        this.Set('ApprovalStatus', value);
    }

    /**
    * * Field Name: ApprovedAt
    * * Display Name: Approved At
    * * SQL Data Type: datetimeoffset
    * * Description: Timestamp when the minutes were approved
    */
    get ApprovedAt(): Date | null {
        return this.Get('ApprovedAt');
    }
    set ApprovedAt(value: Date | null) {
        this.Set('ApprovedAt', value);
    }

    /**
    * * Field Name: ApprovedByMeetingID
    * * Display Name: Approved By Meeting
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Meetings (vwMeetings.ID)
    * * Description: Reference to the meeting at which these minutes were approved (typically the next meeting)
    */
    get ApprovedByMeetingID(): string | null {
        return this.Get('ApprovedByMeetingID');
    }
    set ApprovedByMeetingID(value: string | null) {
        this.Set('ApprovedByMeetingID', value);
    }

    /**
    * * Field Name: Notes
    * * Display Name: Notes
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Additional notes about the minutes
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
}


/**
 * Committees: Motions - strongly typed entity sub-class
 * * Schema: __mj_Committees
 * * Base Table: Motion
 * * Base View: vwMotions
 * * @description Formal motions put to vote during committee meetings
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Committees: Motions')
export class MotionEntity extends BaseEntity<MotionEntityType> {
    /**
    * Loads the Committees: Motions record from the database
    * @param ID: string - primary key value to load the Committees: Motions record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof MotionEntity
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
    * * Field Name: MeetingID
    * * Display Name: Meeting
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Meetings (vwMeetings.ID)
    */
    get MeetingID(): string {
        return this.Get('MeetingID');
    }
    set MeetingID(value: string) {
        this.Set('MeetingID', value);
    }

    /**
    * * Field Name: AgendaItemID
    * * Display Name: Agenda Item
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Agenda Items (vwAgendaItems.ID)
    */
    get AgendaItemID(): string | null {
        return this.Get('AgendaItemID');
    }
    set AgendaItemID(value: string | null) {
        this.Set('AgendaItemID', value);
    }

    /**
    * * Field Name: Sequence
    * * Display Name: Sequence
    * * SQL Data Type: int
    * * Default Value: 1
    * * Description: Display order when multiple motions exist for the same agenda item
    */
    get Sequence(): number {
        return this.Get('Sequence');
    }
    set Sequence(value: number) {
        this.Set('Sequence', value);
    }

    /**
    * * Field Name: Title
    * * Display Name: Title
    * * SQL Data Type: nvarchar(255)
    * * Description: Title of the motion
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
    * * Description: Full text or description of the motion
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: MovedByMembershipID
    * * Display Name: Moved By
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Memberships (vwMemberships.ID)
    * * Description: The committee member who made the motion
    */
    get MovedByMembershipID(): string | null {
        return this.Get('MovedByMembershipID');
    }
    set MovedByMembershipID(value: string | null) {
        this.Set('MovedByMembershipID', value);
    }

    /**
    * * Field Name: SecondedByMembershipID
    * * Display Name: Seconded By
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Memberships (vwMemberships.ID)
    * * Description: The committee member who seconded the motion
    */
    get SecondedByMembershipID(): string | null {
        return this.Get('SecondedByMembershipID');
    }
    set SecondedByMembershipID(value: string | null) {
        this.Set('SecondedByMembershipID', value);
    }

    /**
    * * Field Name: Result
    * * Display Name: Result
    * * SQL Data Type: nvarchar(50)
    * * Default Value: Pending
    * * Value List Type: List
    * * Possible Values 
    *   * Failed
    *   * Passed
    *   * Pending
    *   * Tabled
    *   * Withdrawn
    * * Description: Outcome of the vote: Pending, Passed, Failed, Tabled, Withdrawn
    */
    get Result(): 'Failed' | 'Passed' | 'Pending' | 'Tabled' | 'Withdrawn' {
        return this.Get('Result');
    }
    set Result(value: 'Failed' | 'Passed' | 'Pending' | 'Tabled' | 'Withdrawn') {
        this.Set('Result', value);
    }

    /**
    * * Field Name: ResultSummary
    * * Display Name: Result Summary
    * * SQL Data Type: nvarchar(255)
    * * Description: Human-readable vote tally, e.g. 7-2-1 or Passed unanimously
    */
    get ResultSummary(): string | null {
        return this.Get('ResultSummary');
    }
    set ResultSummary(value: string | null) {
        this.Set('ResultSummary', value);
    }

    /**
    * * Field Name: YesCount
    * * Display Name: Yes Count
    * * SQL Data Type: int
    * * Description: Number of Yes votes
    */
    get YesCount(): number | null {
        return this.Get('YesCount');
    }
    set YesCount(value: number | null) {
        this.Set('YesCount', value);
    }

    /**
    * * Field Name: NoCount
    * * Display Name: No Count
    * * SQL Data Type: int
    * * Description: Number of No votes
    */
    get NoCount(): number | null {
        return this.Get('NoCount');
    }
    set NoCount(value: number | null) {
        this.Set('NoCount', value);
    }

    /**
    * * Field Name: AbstainCount
    * * Display Name: Abstain Count
    * * SQL Data Type: int
    * * Description: Number of Abstain votes
    */
    get AbstainCount(): number | null {
        return this.Get('AbstainCount');
    }
    set AbstainCount(value: number | null) {
        this.Set('AbstainCount', value);
    }

    /**
    * * Field Name: Notes
    * * Display Name: Notes
    * * SQL Data Type: nvarchar(MAX)
    * * Description: Additional notes about the motion or vote
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
}


/**
 * Committees: Roles - strongly typed entity sub-class
 * * Schema: __mj_Committees
 * * Base Table: Role
 * * Base View: vwRoles
 * * @description Roles that members can hold on committees
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Committees: Roles')
export class RoleEntity extends BaseEntity<RoleEntityType> {
    /**
    * Loads the Committees: Roles record from the database
    * @param ID: string - primary key value to load the Committees: Roles record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof RoleEntity
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
    * * Description: Display name for the role
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
    * * Description: Detailed description of role responsibilities
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: IsOfficer
    * * Display Name: Officer Role
    * * SQL Data Type: bit
    * * Default Value: 0
    * * Description: Whether this is an officer role like Chair or Secretary
    */
    get IsOfficer(): boolean {
        return this.Get('IsOfficer');
    }
    set IsOfficer(value: boolean) {
        this.Set('IsOfficer', value);
    }

    /**
    * * Field Name: IsVotingRole
    * * Display Name: Voting Role
    * * SQL Data Type: bit
    * * Default Value: 1
    * * Description: Whether members in this role can vote
    */
    get IsVotingRole(): boolean {
        return this.Get('IsVotingRole');
    }
    set IsVotingRole(value: boolean) {
        this.Set('IsVotingRole', value);
    }

    /**
    * * Field Name: DefaultPermissionsJSON
    * * Display Name: Default Permissions
    * * SQL Data Type: nvarchar(MAX)
    * * Description: JSON object defining default permissions for this role
    */
    get DefaultPermissionsJSON(): string | null {
        return this.Get('DefaultPermissionsJSON');
    }
    set DefaultPermissionsJSON(value: string | null) {
        this.Set('DefaultPermissionsJSON', value);
    }

    /**
    * * Field Name: Sequence
    * * Display Name: Sequence
    * * SQL Data Type: int
    * * Default Value: 100
    * * Description: Display order for sorting roles
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
}


/**
 * Committees: Terms - strongly typed entity sub-class
 * * Schema: __mj_Committees
 * * Base Table: Term
 * * Base View: vwTerms
 * * @description Time periods for committee membership cycles
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Committees: Terms')
export class TermEntity extends BaseEntity<TermEntityType> {
    /**
    * Loads the Committees: Terms record from the database
    * @param ID: string - primary key value to load the Committees: Terms record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof TermEntity
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
    * * Field Name: CommitteeID
    * * Display Name: Committee
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Committees (vwCommittees.ID)
    */
    get CommitteeID(): string {
        return this.Get('CommitteeID');
    }
    set CommitteeID(value: string) {
        this.Set('CommitteeID', value);
    }

    /**
    * * Field Name: Name
    * * Display Name: Term Name
    * * SQL Data Type: nvarchar(100)
    * * Description: Display name for the term, e.g. 2025-2026
    */
    get Name(): string {
        return this.Get('Name');
    }
    set Name(value: string) {
        this.Set('Name', value);
    }

    /**
    * * Field Name: StartDate
    * * Display Name: Start Date
    * * SQL Data Type: date
    * * Description: Start date of the term
    */
    get StartDate(): Date {
        return this.Get('StartDate');
    }
    set StartDate(value: Date) {
        this.Set('StartDate', value);
    }

    /**
    * * Field Name: EndDate
    * * Display Name: End Date
    * * SQL Data Type: date
    * * Description: End date of the term
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
    *   * Completed
    *   * Upcoming
    * * Description: Current status: Active, Upcoming, or Completed
    */
    get Status(): 'Active' | 'Completed' | 'Upcoming' {
        return this.Get('Status');
    }
    set Status(value: 'Active' | 'Completed' | 'Upcoming') {
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
    * * Field Name: Committee
    * * Display Name: Committee Name
    * * SQL Data Type: nvarchar(255)
    */
    get Committee(): string {
        return this.Get('Committee');
    }
}


/**
 * Committees: Types - strongly typed entity sub-class
 * * Schema: __mj_Committees
 * * Base Table: Type
 * * Base View: vwTypes
 * * @description Categories of committees such as Board, Standing, Ad Hoc, Workgroup
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Committees: Types')
export class TypeEntity extends BaseEntity<TypeEntityType> {
    /**
    * Loads the Committees: Types record from the database
    * @param ID: string - primary key value to load the Committees: Types record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof TypeEntity
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
    * * Description: Display name for the committee type
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
    * * Description: Detailed description of this committee type
    */
    get Description(): string | null {
        return this.Get('Description');
    }
    set Description(value: string | null) {
        this.Set('Description', value);
    }

    /**
    * * Field Name: IsStandards
    * * Display Name: Standards Committee
    * * SQL Data Type: bit
    * * Default Value: 0
    * * Description: Whether this type is for standards development committees
    */
    get IsStandards(): boolean {
        return this.Get('IsStandards');
    }
    set IsStandards(value: boolean) {
        this.Set('IsStandards', value);
    }

    /**
    * * Field Name: DefaultTermMonths
    * * Display Name: Default Term (Months)
    * * SQL Data Type: int
    * * Description: Default term length in months for committees of this type
    */
    get DefaultTermMonths(): number | null {
        return this.Get('DefaultTermMonths');
    }
    set DefaultTermMonths(value: number | null) {
        this.Set('DefaultTermMonths', value);
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
 * Committees: Votes - strongly typed entity sub-class
 * * Schema: __mj_Committees
 * * Base Table: Vote
 * * Base View: vwVotes
 * * @description Individual vote records for committee motions
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Committees: Votes')
export class VoteEntity extends BaseEntity<VoteEntityType> {
    /**
    * Loads the Committees: Votes record from the database
    * @param ID: string - primary key value to load the Committees: Votes record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof VoteEntity
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
    * * Field Name: MotionID
    * * Display Name: Motion
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Motions (vwMotions.ID)
    */
    get MotionID(): string {
        return this.Get('MotionID');
    }
    set MotionID(value: string) {
        this.Set('MotionID', value);
    }

    /**
    * * Field Name: MembershipID
    * * Display Name: Member
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Committees: Memberships (vwMemberships.ID)
    */
    get MembershipID(): string {
        return this.Get('MembershipID');
    }
    set MembershipID(value: string) {
        this.Set('MembershipID', value);
    }

    /**
    * * Field Name: VoteValue
    * * Display Name: Vote
    * * SQL Data Type: nvarchar(20)
    * * Value List Type: List
    * * Possible Values 
    *   * Absent
    *   * Abstain
    *   * No
    *   * Yes
    * * Description: The vote cast: Yes, No, Abstain, or Absent
    */
    get VoteValue(): 'Absent' | 'Abstain' | 'No' | 'Yes' {
        return this.Get('VoteValue');
    }
    set VoteValue(value: 'Absent' | 'Abstain' | 'No' | 'Yes') {
        this.Set('VoteValue', value);
    }

    /**
    * * Field Name: Notes
    * * Display Name: Notes
    * * SQL Data Type: nvarchar(500)
    * * Description: Optional notes explaining the vote
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
}


/**
 * Common: Address Links - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: AddressLink
 * * Base View: vwAddressLinks
 * * @description Polymorphic link table connecting Address records to any entity record in the system via EntityID and RecordID
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Common: Address Links')
export class AddressLinkEntity extends BaseEntity<AddressLinkEntityType> {
    /**
    * Loads the Common: Address Links record from the database
    * @param ID: string - primary key value to load the Common: Address Links record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof AddressLinkEntity
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
    * * Related Entity/Foreign Key: Common: Addresses (vwAddresses.ID)
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
    * * Related Entity/Foreign Key: Entities (vwEntities.ID)
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
    * * Related Entity/Foreign Key: Common: Address Types (vwAddressTypes.ID)
    */
    get AddressTypeID(): string {
        return this.Get('AddressTypeID');
    }
    set AddressTypeID(value: string) {
        this.Set('AddressTypeID', value);
    }

    /**
    * * Field Name: IsPrimary
    * * Display Name: Primary
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
    * * Field Name: Entity
    * * Display Name: Entity Name
    * * SQL Data Type: nvarchar(255)
    */
    get Entity(): string {
        return this.Get('Entity');
    }

    /**
    * * Field Name: AddressType
    * * Display Name: Address Type
    * * SQL Data Type: nvarchar(100)
    */
    get AddressType(): string {
        return this.Get('AddressType');
    }
}


/**
 * Common: Address Types - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: AddressType
 * * Base View: vwAddressTypes
 * * @description Categories of addresses such as Home, Work, Mailing, Billing
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Common: Address Types')
export class AddressTypeEntity extends BaseEntity<AddressTypeEntityType> {
    /**
    * Loads the Common: Address Types record from the database
    * @param ID: string - primary key value to load the Common: Address Types record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof AddressTypeEntity
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
 * Common: Addresses - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: Address
 * * Base View: vwAddresses
 * * @description Standalone physical address records linked to entities via AddressLink for sharing across people and organizations
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Common: Addresses')
export class AddressEntity extends BaseEntity<AddressEntityType> {
    /**
    * Loads the Common: Addresses record from the database
    * @param ID: string - primary key value to load the Common: Addresses record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof AddressEntity
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
 * Common: Contact Methods - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: ContactMethod
 * * Base View: vwContactMethods
 * * @description Additional contact methods for people and organizations beyond the primary email and phone fields
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Common: Contact Methods')
export class ContactMethodEntity extends BaseEntity<ContactMethodEntityType> {
    /**
    * Loads the Common: Contact Methods record from the database
    * @param ID: string - primary key value to load the Common: Contact Methods record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof ContactMethodEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * Validate() method override for Common: Contact Methods entity. This is an auto-generated method that invokes the generated validators for this entity for the following fields:
    * * Table-Level: A contact record must be linked to either a person or an organization. One (or both) of the PersonID or OrganizationID fields must contain a value, otherwise the record is incomplete.
    * @public
    * @method
    * @override
    */
    public override Validate(): ValidationResult {
        const result = super.Validate();
        this.ValidatePersonOrOrganizationPresence(result);
        result.Success = result.Success && (result.Errors.length === 0);

        return result;
    }

    /**
    * A contact record must be linked to either a person or an organization. One (or both) of the PersonID or OrganizationID fields must contain a value, otherwise the record is incomplete.
    * @param result - the ValidationResult object to add any errors or warnings to
    * @public
    * @method
    */
    public ValidatePersonOrOrganizationPresence(result: ValidationResult) {
    	t// Ensure at least one of the two nullable foreign keys is set
    	if (this.PersonID == null && this.OrganizationID == null) {
    		result.Errors.push(new ValidationErrorInfo(
    			"PersonID / OrganizationID",
    			"Either PersonID or OrganizationID must be provided.",
    			this.PersonID,
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
    * * Related Entity/Foreign Key: Common: People (vwPeople.ID)
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
    * * Related Entity/Foreign Key: Common: Organizations (vwOrganizations.ID)
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
    * * Related Entity/Foreign Key: Common: Contact Types (vwContactTypes.ID)
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
    * * Display Name: Primary
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
    * * Field Name: Organization
    * * Display Name: Organization
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
 * Common: Contact Types - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: ContactType
 * * Base View: vwContactTypes
 * * @description Categories of contact methods such as Phone, Mobile, Email, LinkedIn, Website
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Common: Contact Types')
export class ContactTypeEntity extends BaseEntity<ContactTypeEntityType> {
    /**
    * Loads the Common: Contact Types record from the database
    * @param ID: string - primary key value to load the Common: Contact Types record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof ContactTypeEntity
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
 * Common: Organization Types - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: OrganizationType
 * * Base View: vwOrganizationTypes
 * * @description Categories of organizations such as Company, Non-Profit, Association, Government
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Common: Organization Types')
export class OrganizationTypeEntity extends BaseEntity<OrganizationTypeEntityType> {
    /**
    * Loads the Common: Organization Types record from the database
    * @param ID: string - primary key value to load the Common: Organization Types record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof OrganizationTypeEntity
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
 * Common: Organizations - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: Organization
 * * Base View: vwOrganizations
 * * @description Companies, associations, government bodies, and other organizations with hierarchy support
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Common: Organizations')
export class OrganizationEntity extends BaseEntity<OrganizationEntityType> {
    /**
    * Loads the Common: Organizations record from the database
    * @param ID: string - primary key value to load the Common: Organizations record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof OrganizationEntity
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
    * * Related Entity/Foreign Key: Common: Organization Types (vwOrganizationTypes.ID)
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
    * * Related Entity/Foreign Key: Common: Organizations (vwOrganizations.ID)
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
    * * Display Name: Parent
    * * SQL Data Type: nvarchar(255)
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
}


/**
 * Common: People - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: Person
 * * Base View: vwPeople
 * * @description Individual people, optionally linked to MJ system user accounts
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Common: People')
export class PersonEntity extends BaseEntity<PersonEntityType> {
    /**
    * Loads the Common: People record from the database
    * @param ID: string - primary key value to load the Common: People record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof PersonEntity
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
    * * Display Name: Linked User
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Users (vwUsers.ID)
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
    * * Field Name: LinkedUser
    * * Display Name: Linked User
    * * SQL Data Type: nvarchar(100)
    */
    get LinkedUser(): string | null {
        return this.Get('LinkedUser');
    }
}


/**
 * Common: Relationship Types - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: RelationshipType
 * * Base View: vwRelationshipTypes
 * * @description Defines types of relationships between people and organizations with directionality and labeling
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Common: Relationship Types')
export class RelationshipTypeEntity extends BaseEntity<RelationshipTypeEntityType> {
    /**
    * Loads the Common: Relationship Types record from the database
    * @param ID: string - primary key value to load the Common: Relationship Types record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof RelationshipTypeEntity
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
 * Common: Relationships - strongly typed entity sub-class
 * * Schema: __mj_BizAppsCommon
 * * Base Table: Relationship
 * * Base View: vwRelationships
 * * @description Typed, directional links between people and organizations supporting Person-to-Person, Person-to-Organization, and Organization-to-Organization relationships
 * * Primary Key: ID
 * @extends {BaseEntity}
 * @class
 * @public
 */
@RegisterClass(BaseEntity, 'Common: Relationships')
export class RelationshipEntity extends BaseEntity<RelationshipEntityType> {
    /**
    * Loads the Common: Relationships record from the database
    * @param ID: string - primary key value to load the Common: Relationships record.
    * @param EntityRelationshipsToLoad - (optional) the relationships to load
    * @returns {Promise<boolean>} - true if successful, false otherwise
    * @public
    * @async
    * @memberof RelationshipEntity
    * @method
    * @override
    */
    public async Load(ID: string, EntityRelationshipsToLoad?: string[]) : Promise<boolean> {
        const compositeKey: CompositeKey = new CompositeKey();
        compositeKey.KeyValuePairs.push({ FieldName: 'ID', Value: ID });
        return await super.InnerLoad(compositeKey, EntityRelationshipsToLoad);
    }

    /**
    * Validate() method override for Common: Relationships entity. This is an auto-generated method that invokes the generated validators for this entity for the following fields:
    * * Table-Level: A relationship must originate from either a person or an organization – one of the two IDs must be provided, but never both and never neither.
    * * Table-Level: Each relationship must point to exactly one target – either a person or an organization. You cannot leave both target fields empty, and you cannot specify both a person and an organization at the same time.
    * @public
    * @method
    * @override
    */
    public override Validate(): ValidationResult {
        const result = super.Validate();
        this.ValidateFromPersonOrOrganizationExclusive(result);
        this.ValidateToPersonOrOrganizationExclusivity(result);
        result.Success = result.Success && (result.Errors.length === 0);

        return result;
    }

    /**
    * A relationship must originate from either a person or an organization – one of the two IDs must be provided, but never both and never neither.
    * @param result - the ValidationResult object to add any errors or warnings to
    * @public
    * @method
    */
    public ValidateFromPersonOrOrganizationExclusive(result: ValidationResult) {
    	// Ensure exactly one of FromPersonID or FromOrganizationID is set
    	const personProvided = this.FromPersonID != null;
    	const orgProvided = this.FromOrganizationID != null;
    	if ((personProvided && orgProvided) || (!personProvided && !orgProvided)) {
    		result.Errors.push(new ValidationErrorInfo(
    			"FromPersonID",
    			"A relationship must originate from either a person or an organization, but not both and not neither.",
    			this.FromPersonID,
    			ValidationErrorType.Failure
    		));
    	}
    }

    /**
    * Each relationship must point to exactly one target – either a person or an organization. You cannot leave both target fields empty, and you cannot specify both a person and an organization at the same time.
    * @param result - the ValidationResult object to add any errors or warnings to
    * @public
    * @method
    */
    public ValidateToPersonOrOrganizationExclusivity(result: ValidationResult) {
    	// Exactly one of ToPersonID or ToOrganizationID must be provided
    	if ((this.ToPersonID == null && this.ToOrganizationID == null) ||
    		(this.ToPersonID != null && this.ToOrganizationID != null)) {
    		result.Errors.push(new ValidationErrorInfo(
    			"ToPersonID/ToOrganizationID",
    			"Either a person or an organization must be specified as the target, but not both.",
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
    * * Display Name: Relationship Type
    * * SQL Data Type: uniqueidentifier
    * * Related Entity/Foreign Key: Common: Relationship Types (vwRelationshipTypes.ID)
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
    * * Related Entity/Foreign Key: Common: People (vwPeople.ID)
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
    * * Related Entity/Foreign Key: Common: Organizations (vwOrganizations.ID)
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
    * * Related Entity/Foreign Key: Common: People (vwPeople.ID)
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
    * * Related Entity/Foreign Key: Common: Organizations (vwOrganizations.ID)
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
    * * Field Name: FromOrganization
    * * Display Name: From Organization Name
    * * SQL Data Type: nvarchar(255)
    */
    get FromOrganization(): string | null {
        return this.Get('FromOrganization');
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
