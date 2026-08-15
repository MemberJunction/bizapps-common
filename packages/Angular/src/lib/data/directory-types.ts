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
