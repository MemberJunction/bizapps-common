import { LogError, RunQuery, RunView } from '@memberjunction/core';
import { COMMON_ENTITIES } from './entity-names';
import { EscapeLikeValue } from './directory-stats';
import type {
    DirectoryAttentionItem,
    DirectoryBarRow,
    DirectoryDayBar,
    DirectoryOrganizationRow,
    DirectoryPersonRow,
    DirectoryQueue,
    DirectoryRelationshipRow,
} from './directory-types';

const DIRECTORY_SUMMARY_QUERY = 'Common: Directory Dashboard Summary';
const DIRECTORY_SUMMARY_CATEGORY = 'Common';

export interface DirectoryDashboardSummary {
    ActivePeopleCount: number;
    TotalPeopleCount: number;
    ActiveOrganizationCount: number;
    TotalOrganizationCount: number;
    RelationshipCount: number;
    PeopleMissingEmail: number;
    PeopleMissingOrganization: number;
    OrganizationsMissingType: number;
    OrganizationsMissingWebsite: number;
    PeoplePerDay: DirectoryDayBar[];
    OrganizationTypeMix: DirectoryBarRow[];
    WorthALook: DirectoryAttentionItem[];
    Queues: DirectoryQueue[];
}

function num(v: unknown): number {
    return v === null || v === undefined || v === '' ? 0 : Number(v);
}

function str(v: unknown): string | null {
    if (v === null || v === undefined) return null;
    const s = String(v).trim();
    return s.length ? s : null;
}

function weekdayUtc(daysAgo: number): string {
    const d = new Date();
    d.setUTCDate(d.getUTCDate() - daysAgo);
    return d.toLocaleDateString('en-US', { weekday: 'short', timeZone: 'UTC' });
}

export async function LoadDirectoryDashboardSummary(): Promise<DirectoryDashboardSummary | null> {
    const result = await new RunQuery().RunQuery({
        QueryName: DIRECTORY_SUMMARY_QUERY,
        CategoryPath: DIRECTORY_SUMMARY_CATEGORY,
    });
    if (!result?.Success) {
        LogError(`Common: Directory Dashboard Summary failed — ${result?.ErrorMessage ?? 'unknown error'}`);
        return null;
    }
    const row = (result.Results ?? [])[0] as Record<string, unknown> | undefined;
    if (!row) {
        return null;
    }

    const queues: DirectoryQueue[] = [
        {
            Label: 'People without email',
            Note: 'Hard to reach, and every other app asks for it',
            Count: num(row['PeopleMissingEmail']),
            Icon: 'fa-solid fa-envelope',
            Tone: 'warning',
            PageId: 'people',
        },
        {
            Label: 'People without an organization',
            Note: 'Not linked to a current employer or member org',
            Count: num(row['PeopleMissingOrganization']),
            Icon: 'fa-solid fa-building-user',
            Tone: 'info',
            PageId: 'people',
        },
        {
            Label: 'Organizations without a type',
            Note: 'Company, chapter, vendor — the directory cannot sort them',
            Count: num(row['OrganizationsMissingType']),
            Icon: 'fa-solid fa-tags',
            Tone: 'warning',
            PageId: 'organizations',
        },
        {
            Label: 'Organizations without a website',
            Note: 'The first thing a person looks up',
            Count: num(row['OrganizationsMissingWebsite']),
            Icon: 'fa-solid fa-globe',
            Tone: 'neutral',
            PageId: 'organizations',
        },
    ];

    const mixRaw = str(row['OrgTypeMixJson']);
    let mix: DirectoryBarRow[] = [];
    if (mixRaw) {
        try {
            const parsed = JSON.parse(mixRaw) as Array<{ Label?: string; Value?: number }>;
            mix = parsed
                .map((item) => ({ Label: item.Label || 'Unspecified', Value: num(item.Value) }))
                .sort((a, b) => b.Value - a.Value);
        } catch (e) {
            LogError(`Common: Directory Dashboard Summary OrgTypeMixJson parse failed — ${e}`);
        }
    }

    const worth: DirectoryAttentionItem[] = [];
    const emailId = str(row['AttentionEmailPersonID']);
    if (emailId && num(row['PeopleMissingEmail']) > 0) {
        const name = str(row['AttentionEmailName']) || 'Someone';
        const org = str(row['AttentionEmailOrg']);
        worth.push({
            Kind: 'person',
            RecordID: emailId,
            Tone: 'warning',
            Icon: 'fa-solid fa-envelope',
            Headline: `${name} has no email.`,
            Detail: org ? `Active at ${org}.` : 'No organization on file either.',
        });
    }
    const typeId = str(row['AttentionTypeOrgID']);
    if (typeId && num(row['OrganizationsMissingType']) > 0) {
        const name = str(row['AttentionTypeOrgName']) || 'An organization';
        const site = str(row['AttentionTypeWebsite']);
        worth.push({
            Kind: 'organization',
            RecordID: typeId,
            Tone: 'warning',
            Icon: 'fa-solid fa-tags',
            Headline: `${name} has no organization type.`,
            Detail: site ? site : 'No website on file either.',
        });
    }

    return {
        ActivePeopleCount: num(row['ActivePeople']),
        TotalPeopleCount: num(row['TotalPeople']),
        ActiveOrganizationCount: num(row['ActiveOrganizations']),
        TotalOrganizationCount: num(row['TotalOrganizations']),
        RelationshipCount: num(row['RelationshipCount']),
        PeopleMissingEmail: num(row['PeopleMissingEmail']),
        PeopleMissingOrganization: num(row['PeopleMissingOrganization']),
        OrganizationsMissingType: num(row['OrganizationsMissingType']),
        OrganizationsMissingWebsite: num(row['OrganizationsMissingWebsite']),
        PeoplePerDay: [6, 5, 4, 3, 2, 1, 0].map((ago) => ({
            Label: weekdayUtc(ago),
            Value: num(row[`PeopleAddedD${ago}`]),
            Current: ago === 0,
        })),
        OrganizationTypeMix: mix,
        WorthALook: worth,
        Queues: queues.filter((q) => q.Count > 0),
    };
}

const PERSON_FIELDS = [
    'ID',
    'DisplayName',
    'FirstName',
    'LastName',
    'Email',
    'PrimaryEmail',
    'Phone',
    'PrimaryPhone',
    'Status',
    'Title',
    'CurrentOrganizationName',
    'CurrentOrganizationID',
    'PrimaryAddressCity',
    '__mj_CreatedAt',
] as const;

const ORGANIZATION_FIELDS = [
    'ID',
    'Name',
    'LegalName',
    'Status',
    'OrganizationType',
    'OrganizationTypeID',
    'Website',
    'Email',
    'Phone',
    'Parent',
    'PrimaryAddressCity',
    '__mj_CreatedAt',
] as const;

const RELATIONSHIP_FIELDS = [
    'ID',
    'RelationshipType',
    'Title',
    'Status',
    'FromPerson',
    'FromOrganization',
    'ToPerson',
    'ToOrganization',
    'FromPersonID',
    'ToPersonID',
    'FromOrganizationID',
    'ToOrganizationID',
    '__mj_CreatedAt',
] as const;

/** Cheap directory load — one round trip, no aggregates. */
export async function LoadDirectorySnapshot(): Promise<{
    People: DirectoryPersonRow[];
    Organizations: DirectoryOrganizationRow[];
    Relationships: DirectoryRelationshipRow[];
}> {
    const rv = new RunView();
    const [people, orgs, relationships] = await rv.RunViews([
        {
            EntityName: COMMON_ENTITIES.Person,
            Fields: [...PERSON_FIELDS],
            OrderBy: '__mj_CreatedAt DESC',
            MaxRows: 1000,
            ResultType: 'simple',
        },
        {
            EntityName: COMMON_ENTITIES.Organization,
            Fields: [...ORGANIZATION_FIELDS],
            OrderBy: '__mj_CreatedAt DESC',
            MaxRows: 1000,
            ResultType: 'simple',
        },
        {
            EntityName: COMMON_ENTITIES.Relationship,
            Fields: [...RELATIONSHIP_FIELDS],
            OrderBy: '__mj_CreatedAt DESC',
            MaxRows: 1000,
            ResultType: 'simple',
        },
    ]);

    return {
        People: (people.Success ? people.Results : []) as DirectoryPersonRow[],
        Organizations: (orgs.Success ? orgs.Results : []) as DirectoryOrganizationRow[],
        Relationships: (relationships.Success ? relationships.Results : []) as DirectoryRelationshipRow[],
    };
}

/**
 * Search people by free text. Takes a raw search TERM (never a SQL fragment) and
 * builds the escaped LIKE filter internally, so callers cannot concatenate
 * unescaped user input into `ExtraFilter`.
 */
export async function SearchPeople(searchTerm: string | undefined): Promise<DirectoryPersonRow[]> {
    const term = searchTerm?.trim();
    const like = term ? EscapeLikeValue(term) : undefined;
    const rv = new RunView();
    const result = await rv.RunView<DirectoryPersonRow>({
        EntityName: COMMON_ENTITIES.Person,
        Fields: [...PERSON_FIELDS],
        ExtraFilter: like
            ? `(DisplayName LIKE '%${like}%' OR Email LIKE '%${like}%' OR PrimaryEmail LIKE '%${like}%')`
            : undefined,
        OrderBy: 'LastName, FirstName',
        MaxRows: 200,
        ResultType: 'simple',
    });
    return result.Success ? result.Results : [];
}

/** Search organizations by free text — same term-not-filter contract as `SearchPeople`. */
export async function SearchOrganizations(searchTerm: string | undefined): Promise<DirectoryOrganizationRow[]> {
    const term = searchTerm?.trim();
    const like = term ? EscapeLikeValue(term) : undefined;
    const rv = new RunView();
    const result = await rv.RunView<DirectoryOrganizationRow>({
        EntityName: COMMON_ENTITIES.Organization,
        Fields: [...ORGANIZATION_FIELDS],
        ExtraFilter: like
            ? `(Name LIKE '%${like}%' OR LegalName LIKE '%${like}%' OR Email LIKE '%${like}%')`
            : undefined,
        OrderBy: 'Name',
        MaxRows: 200,
        ResultType: 'simple',
    });
    return result.Success ? result.Results : [];
}
