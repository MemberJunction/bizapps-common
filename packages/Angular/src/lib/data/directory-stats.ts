import type {
    DirectoryAttentionItem,
    DirectoryBarRow,
    DirectoryDayBar,
    DirectoryOrganizationRow,
    DirectoryPersonRow,
    DirectoryQueue,
    DirectoryRelationshipRow,
} from './directory-types';

export function PersonEmail(person: DirectoryPersonRow): string | null {
    return person.PrimaryEmail || person.Email || null;
}

export function PersonPhone(person: DirectoryPersonRow): string | null {
    return person.PrimaryPhone || person.Phone || null;
}

export function LocalDayKey(value: Date | string): string {
    const date = value instanceof Date ? value : new Date(value);
    if (Number.isNaN(date.getTime())) return '';
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}

export function ActivePeople(people: readonly DirectoryPersonRow[]): DirectoryPersonRow[] {
    return people.filter((person) => person.Status === 'Active');
}

export function ActiveOrganizations(orgs: readonly DirectoryOrganizationRow[]): DirectoryOrganizationRow[] {
    return orgs.filter((org) => org.Status === 'Active');
}

export function PeopleMissingEmail(people: readonly DirectoryPersonRow[]): DirectoryPersonRow[] {
    return ActivePeople(people).filter((person) => !PersonEmail(person));
}

export function PeopleMissingOrganization(people: readonly DirectoryPersonRow[]): DirectoryPersonRow[] {
    return ActivePeople(people).filter((person) => !person.CurrentOrganizationID);
}

export function OrganizationsMissingType(orgs: readonly DirectoryOrganizationRow[]): DirectoryOrganizationRow[] {
    return ActiveOrganizations(orgs).filter((org) => !org.OrganizationTypeID);
}

export function OrganizationsMissingWebsite(orgs: readonly DirectoryOrganizationRow[]): DirectoryOrganizationRow[] {
    return ActiveOrganizations(orgs).filter((org) => !org.Website);
}

export function CountByDay(rows: readonly { __mj_CreatedAt: Date | string }[], days = 7): DirectoryDayBar[] {
    const today = new Date();
    const bars: DirectoryDayBar[] = [];
    for (let back = days - 1; back >= 0; back--) {
        const day = new Date(today);
        day.setDate(today.getDate() - back);
        const key = LocalDayKey(day);
        bars.push({
            Label: day.toLocaleDateString('en-US', { weekday: 'short' }),
            Value: rows.filter((row) => LocalDayKey(row.__mj_CreatedAt) === key).length,
            Current: back === 0,
        });
    }
    return bars;
}

export function CountByLabel(rows: readonly { Label: string }[]): DirectoryBarRow[] {
    const counts = new Map<string, number>();
    for (const row of rows) {
        const label = row.Label || 'Unspecified';
        counts.set(label, (counts.get(label) ?? 0) + 1);
    }
    return [...counts.entries()]
        .map(([Label, Value]) => ({ Label, Value }))
        .sort((a, b) => b.Value - a.Value);
}

export function LatestByCreated<T extends { __mj_CreatedAt: Date | string }>(rows: readonly T[], take = 7): T[] {
    return [...rows]
        .sort((a, b) => String(b.__mj_CreatedAt).localeCompare(String(a.__mj_CreatedAt)))
        .slice(0, take);
}

export function BuildDirectoryQueues(
    people: readonly DirectoryPersonRow[],
    orgs: readonly DirectoryOrganizationRow[],
): DirectoryQueue[] {
    const queues: DirectoryQueue[] = [
        {
            Label: 'People without email',
            Note: 'Hard to reach, and every other app asks for it',
            Count: PeopleMissingEmail(people).length,
            Icon: 'fa-solid fa-envelope',
            Tone: 'warning',
            PageId: 'people',
        },
        {
            Label: 'People without an organization',
            Note: 'Not linked to a current employer or member org',
            Count: PeopleMissingOrganization(people).length,
            Icon: 'fa-solid fa-building-user',
            Tone: 'info',
            PageId: 'people',
        },
        {
            Label: 'Organizations without a type',
            Note: 'Company, chapter, vendor — the directory cannot sort them',
            Count: OrganizationsMissingType(orgs).length,
            Icon: 'fa-solid fa-tags',
            Tone: 'warning',
            PageId: 'organizations',
        },
        {
            Label: 'Organizations without a website',
            Note: 'The first thing a person looks up',
            Count: OrganizationsMissingWebsite(orgs).length,
            Icon: 'fa-solid fa-globe',
            Tone: 'neutral',
            PageId: 'organizations',
        },
    ];
    return queues.filter((queue) => queue.Count > 0);
}

export function BuildAttentionItems(
    people: readonly DirectoryPersonRow[],
    orgs: readonly DirectoryOrganizationRow[],
): DirectoryAttentionItem[] {
    const items: DirectoryAttentionItem[] = [];
    const missingEmail = PeopleMissingEmail(people)[0];
    if (missingEmail) {
        items.push({
            Kind: 'person',
            RecordID: missingEmail.ID,
            Tone: 'warning',
            Icon: 'fa-solid fa-envelope',
            Headline: `${missingEmail.DisplayName} has no email.`,
            Detail: missingEmail.CurrentOrganizationName
                ? `Active at ${missingEmail.CurrentOrganizationName}.`
                : 'No organization on file either.',
        });
    }

    const missingType = OrganizationsMissingType(orgs)[0];
    if (missingType) {
        items.push({
            Kind: 'organization',
            RecordID: missingType.ID,
            Tone: 'warning',
            Icon: 'fa-solid fa-tags',
            Headline: `${missingType.Name} has no organization type.`,
            Detail: missingType.Website ? missingType.Website : 'No website on file either.',
        });
    }

    return items;
}

export function RelationshipParty(row: DirectoryRelationshipRow): string {
    const from = row.FromPerson || row.FromOrganization || '—';
    const to = row.ToPerson || row.ToOrganization || '—';
    return `${from} → ${to}`;
}

export function EscapeFilterValue(value: string): string {
    return value.replace(/'/g, "''");
}
