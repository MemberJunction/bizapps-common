import type { mjBizAppsCommonOrganizationEntity, mjBizAppsCommonPersonEntity, mjBizAppsCommonRelationshipEntity } from '@mj-biz-apps/common-entities';

/** Read-only person row the dashboard and people list bind to. */
export type DirectoryPersonRow = Pick<
    mjBizAppsCommonPersonEntity,
    | 'ID'
    | 'DisplayName'
    | 'FirstName'
    | 'LastName'
    | 'Email'
    | 'PrimaryEmail'
    | 'Phone'
    | 'PrimaryPhone'
    | 'Status'
    | 'Title'
    | 'CurrentOrganizationName'
    | 'CurrentOrganizationID'
    | 'PrimaryAddressCity'
    | '__mj_CreatedAt'
>;

/** Read-only organization row the dashboard and org list bind to. */
export type DirectoryOrganizationRow = Pick<
    mjBizAppsCommonOrganizationEntity,
    | 'ID'
    | 'Name'
    | 'LegalName'
    | 'Status'
    | 'OrganizationType'
    | 'OrganizationTypeID'
    | 'Website'
    | 'Email'
    | 'Phone'
    | 'Parent'
    | 'PrimaryAddressCity'
    | '__mj_CreatedAt'
>;

/** Read-only relationship row used for mix + recent. */
export type DirectoryRelationshipRow = Pick<
    mjBizAppsCommonRelationshipEntity,
    | 'ID'
    | 'RelationshipType'
    | 'Title'
    | 'Status'
    | 'FromPerson'
    | 'FromOrganization'
    | 'ToPerson'
    | 'ToOrganization'
    | 'FromPersonID'
    | 'ToPersonID'
    | 'FromOrganizationID'
    | 'ToOrganizationID'
    | '__mj_CreatedAt'
>;

export interface DirectoryDayBar {
    Label: string;
    Value: number;
    Current: boolean;
}

export interface DirectoryBarRow {
    Label: string;
    Value: number;
}

export interface DirectoryQueue {
    Label: string;
    Note?: string;
    Count: number;
    Icon: string;
    Tone: 'neutral' | 'info' | 'warning' | 'error' | 'success';
    PageId: string;
}

export interface DirectoryAttentionItem {
    Kind: 'person' | 'organization';
    RecordID: string;
    Tone: 'info' | 'warning' | 'error';
    Icon: string;
    Headline: string;
    Detail: string;
}

/**
 * The four headline counts of the directory dashboard, in the shape `bizapps-stat-tile` takes them.
 *
 * The counts are `number | null` rather than `number` on purpose. They all come from one query, so
 * they are one atomic read: either every number is true or none of them is. `null` is the tile's
 * "could not be read" value and renders an em dash; `0` is a real answer and renders "0". Defaulting
 * an unread count to `0` tells the reader the directory is empty when it is only unreadable, which is
 * the one thing a dashboard must not say.
 */
export interface DirectoryHeadline {
    ActivePeopleCount: number | null;
    ActiveOrganizationCount: number | null;
    RelationshipCount: number | null;
    GapCount: number | null;
    /**
     * How the gap count should read. `warn` only on a gap count that was actually read and is above
     * zero: an unknown count is an em dash, and colouring it amber would turn "we could not check"
     * into "there is something to fix". Matches `StatTileTone`, kept as a literal union so the data
     * layer does not depend on the component layer.
     */
    GapTone: 'none' | 'warn';
    /** Footnote under the people count, or `null` when there is no count to qualify. */
    PeopleDetail: string | null;
    /** Footnote under the organization count, or `null` when there is no count to qualify. */
    OrganizationDetail: string | null;
    /** One sentence for `bizapps-stat-row`'s error line, or `null` when everything read. */
    Error: string | null;
}
