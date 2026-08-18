/**
 * JSON payloads stored on Activity / ActivitySync* nvarchar(MAX) columns.
 *
 * These are the contract the sync engine and UI write. CodeGen can later
 * bind them as EntityField.JSONType so the generated getters are typed;
 * until then callers import the interfaces from this file.
 */

/** Activity.Details — extras that are not query predicates. */
export interface ActivityDetails {
    MessageID?: string;
    InReplyTo?: string;
    MeetingURL?: string;
    Mailbox?: string;
    Folder?: string;
    CalendarEventID?: string;
}

/** ActivitySyncConnection.Settings — provider extras. */
export interface ActivitySyncConnectionSettings {
    TenantID?: string;
    MailboxFolder?: string;
    CalendarID?: string;
    IncludeCalendar?: boolean;
    IncludeMail?: boolean;
}

/** ActivitySyncRule.Filter — include/exclude match extras. */
export interface ActivitySyncRuleFilter {
    Folders?: string[];
    ExcludeFolders?: string[];
    Domains?: string[];
    ExcludeDomains?: string[];
    ParticipantMustMatchContactMethod?: boolean;
    SubjectContains?: string[];
    SubjectExcludes?: string[];
}
