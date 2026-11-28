# Common Directory & Activity Skill

**BizApps Common** is installed in this environment. It is the shared foundation for people, organizations, relationships, contact methods, addresses, communication consent, and the unified cross-app activity timeline.

Use this skill whenever the user asks about a person, organization, contact details, reporting/organizational relationships, communication consent, recent touchpoints/activities, or which organizations/people are active customers across installed apps — or asks you to log a call, note, meeting, or touchpoint on the timeline.

## Core Data Access & RLS Rules

- **Always read through `RunView` or the bound typed actions — never raw SQL.** Row-Level Security (RLS) and entity/query permissions evaluate under the calling user's `ContextUser` identity.
- **Respect activity privacy and connection ownership:**
  - `MJ_BizApps_Common: Activities` has `Visibility` (`'Internal'` | `'Private'`) and `LoggedByUserID`. Never expose `'Private'` activities belonging to another user.
  - `MJ_BizApps_Common: Activity Sync Connections` is scoped to `OwnerUserID`.
  - `Common.GetPartySignals` runs every `Party Signals` query as the calling user; queries the user lacks permission to read return in `Warnings` and contribute zero rows.
- **Never infer missing records as non-existent globally** — if a query returns empty or a warning, explain that no accessible records matched for the caller.

## Main Entities & Key Fields

| Entity | Purpose | Key Fields & Statuses |
| --- | --- | --- |
| `MJ_BizApps_Common: People` | Individual people (internal employees, contacts, partners, members) | `FirstName`, `LastName`, `DisplayName`, `PreferredName`, `Title`, `Email`, `EmailDomain`, `Phone`, `LinkedUserID`, `SupervisorPersonID`, `Status` (`'Active'` \| `'Inactive'` \| `'Deceased'`) |
| `MJ_BizApps_Common: Organizations` | Companies, accounts, institutions, and legal entities | `Name`, `LegalName`, `Acronym`, `OrganizationTypeID`, `ParentID`, `Website`, `WebsiteDomain`, `Email`, `Phone`, `LinkedCompanyID`, `Status` (`'Active'` \| `'Inactive'` \| `'Dissolved'`) |
| `MJ_BizApps_Common: Relationships` | Typed links between people and/or organizations (employment, board, vendor, household) | `RelationshipTypeID`, `FromPersonID`, `FromOrganizationID`, `ToPersonID`, `ToOrganizationID`, `Title`, `StartDate`, `EndDate`, `Status` (`'Active'` \| `'Inactive'` \| `'Ended'`), `JobFunctionID`, `SeniorityLevelID` |
| `MJ_BizApps_Common: Contact Methods` | Emails, phones, social/messaging handles attached to a person or organization | `PersonID`, `OrganizationID`, `ContactTypeID`, `Value`, `Label`, `IsPrimary` |
| `MJ_BizApps_Common: Contact Method Consents` | Opt-in / opt-out communication consent per purpose and requesting org | `ContactMethodID`, `ConsentPurposeID`, `RequestingOrganizationID`, `ConsentStatus` (`'Opted In'` \| `'Opted Out'` \| `'Not Specified'`) |
| `MJ_BizApps_Common: Addresses` & `MJ_BizApps_Common: Address Links` | Physical and billing/shipping addresses linked to parties | `Line1`, `City`, `StateProvince`, `PostalCode`, `Country`, `DisplayName` |
| `MJ_BizApps_Common: Activities` | Unified interaction timeline (emails, calls, meetings, notes, system events) | `ActivityTypeID`, `StartedAt`, `EndedAt`, `Title`, `Description`, `Direction` (`'Inbound'` \| `'Outbound'` \| `'Internal'`), `Status` (`'Logged'` \| `'Completed'` \| `'Scheduled'` \| `'Cancelled'` \| `'Failed'`), `Outcome`, `Visibility` (`'Internal'` \| `'Private'`), `Source` (`'Manual'` \| `'Integration'` \| `'System'`), `LoggedByUserID`, `ArtifactID` |
| `MJ_BizApps_Common: Activity Links` | Polymorphic links connecting an activity to people, organizations, or downstream records (deals, orders, tickets) | `ActivityID`, `Role` (`'Regarding'` \| `'Participant'` \| `'From'` \| `'To'` \| `'Cc'` \| `'Bcc'` \| `'Organizer'` \| `'Attendee'` \| `'LoggedFor'`), `EntityID`, `RecordID`, `IdentityKind`, `IdentityValue` |
| `MJ_BizApps_Common: Activity Sync Connections` | Per-user mailbox/calendar sync configurations | `Name`, `Provider` (`'Microsoft365'` \| `'Gmail'` \| `'Zoom'` \| `'Generic'`), `Status` (`'Active'` \| `'Paused'` \| `'Disabled'` \| `'Error'`), `OwnerUserID`, `Mailbox`, `LastSyncAt`, `LastError` |

## Bound Typed Actions

1. **`Common.GetPartySignals`** (read-only): Returns the merged roster of organizations and people that installed apps recognize as customers or active parties (e.g., orders, won deals), strictly filtered by the caller's query permissions. Inspect `Warnings` if any signal source was unavailable to the caller.
2. **`Common.LogActivity`** (write — confirm before logging unless the user explicitly asked to log it): Writes one `MJ_BizApps_Common: Activities` row and its `MJ_BizApps_Common: Activity Links` atomically via `ActivityWriter`. Always pass accurate `TypeCode`, `Title`, `EntityName`, `RecordID`, and `Visibility`.

## Common Chief of Staff Workflows

1. **"Who is [person/org] and what is our latest touchpoint?"**
   - Query `MJ_BizApps_Common: People` or `MJ_BizApps_Common: Organizations` (`Status = 'Active'` first), follow `MJ_BizApps_Common: Relationships` for role/affiliation and `MJ_BizApps_Common: Contact Methods` for primary channels.
   - Join recent `MJ_BizApps_Common: Activity Links` (matching `RecordID`) to `MJ_BizApps_Common: Activities` ordered by `StartedAt DESC` to summarize the latest touchpoints.
2. **"Can we contact [person] for [purpose]?"**
   - Check `MJ_BizApps_Common: Contact Methods` and `MJ_BizApps_Common: Contact Method Consents` before drafting or suggesting outreach; honor `'Opted Out'` strictly.
3. **"Which organizations are active customers?"**
   - Call `Common.GetPartySignals` rather than hard-coding one downstream app's definition, then enrich top matches from `MJ_BizApps_Common: Organizations` / `MJ_BizApps_Common: People`.
4. **"Log a call/note with [person/org]"**
   - Resolve the exact `Person` or `Organization` `ID` first, confirm ambiguity if multiple matches exist, then call `Common.LogActivity`.
5. **Mailbox sync diagnostics:** Inspect `MJ_BizApps_Common: Activity Sync Connections` and `MJ_BizApps_Common: Activity Sync Runs` via `RunView` to surface `Status = 'Error'` or stale `LastSyncAt` on the caller's own connections; do not trigger global `Sync Activities` without explicit admin intent.
