/**
 * Named User Views for Directory grids. `mj-entity-viewer` reads columns from
 * `UserView.GridState`. PhotoURL / LogoURL are first so the viewer can render
 * thumbnails (entity-viewer image cells). Until metadata is pushed, we fall
 * back to an in-memory view with the same GridState.
 */
import { Metadata, RunView, type EntityInfo, type RunViewParams } from '@memberjunction/core';
import type { MJUserViewEntityExtended } from '@memberjunction/core-entities';
import { COMMON_ENTITIES } from './entity-names';
import { EscapeFilterValue } from './directory-stats';

export const DIRECTORY_VIEW_NAMES = {
    People: 'Common: People directory',
    LatestPeople: 'Common: Latest people',
    Organizations: 'Common: Organizations directory',
    Relationships: 'Common: Relationships',
    LatestRelationships: 'Common: Latest relationships',
} as const;

type GridCol = {
    Name: string;
    DisplayName: string;
    orderIndex: number;
    width: number;
    pinned?: 'left' | 'right' | null;
    format?: Record<string, unknown>;
};

function grid(sortField: string, dir: 'asc' | 'desc', columns: GridCol[]) {
    return { sortSettings: [{ field: sortField, dir }], columnSettings: columns };
}

export function PeopleDirectoryGridState() {
    return grid('DisplayName', 'asc', [
        { Name: 'PhotoURL', DisplayName: 'Photo', orderIndex: 0, width: 72, format: { type: 'image' } },
        { Name: 'DisplayName', DisplayName: 'Name', orderIndex: 1, width: 220, pinned: 'left' },
        { Name: 'Title', DisplayName: 'Title', orderIndex: 2, width: 160 },
        { Name: 'CurrentOrganizationName', DisplayName: 'Organization', orderIndex: 3, width: 200 },
        { Name: 'PrimaryEmail', DisplayName: 'Email', orderIndex: 4, width: 200 },
        { Name: 'PrimaryPhone', DisplayName: 'Phone', orderIndex: 5, width: 140 },
        { Name: 'Status', DisplayName: 'Status', orderIndex: 6, width: 110 },
    ]);
}

export function LatestPeopleGridState() {
    return grid('__mj_CreatedAt', 'desc', [
        { Name: 'PhotoURL', DisplayName: 'Photo', orderIndex: 0, width: 72, format: { type: 'image' } },
        { Name: 'DisplayName', DisplayName: 'Name', orderIndex: 1, width: 220, pinned: 'left' },
        { Name: 'CurrentOrganizationName', DisplayName: 'Organization', orderIndex: 2, width: 200 },
        { Name: 'PrimaryEmail', DisplayName: 'Email', orderIndex: 3, width: 200 },
        { Name: '__mj_CreatedAt', DisplayName: 'Added', orderIndex: 4, width: 140, format: { type: 'date', dateFormat: 'medium' } },
    ]);
}

export function OrganizationsDirectoryGridState() {
    return grid('Name', 'asc', [
        { Name: 'LogoURL', DisplayName: 'Logo', orderIndex: 0, width: 72, format: { type: 'image' } },
        { Name: 'Name', DisplayName: 'Organization', orderIndex: 1, width: 240, pinned: 'left' },
        { Name: 'OrganizationType', DisplayName: 'Type', orderIndex: 2, width: 140 },
        { Name: 'Website', DisplayName: 'Website', orderIndex: 3, width: 200 },
        { Name: 'PrimaryAddressCity', DisplayName: 'City', orderIndex: 4, width: 140 },
        { Name: 'Status', DisplayName: 'Status', orderIndex: 5, width: 110 },
    ]);
}

export function RelationshipsGridState() {
    return grid('__mj_CreatedAt', 'desc', [
        { Name: 'RelationshipType', DisplayName: 'Type', orderIndex: 0, width: 140 },
        { Name: 'Title', DisplayName: 'Title', orderIndex: 1, width: 200 },
        { Name: 'FromPerson', DisplayName: 'From person', orderIndex: 2, width: 180 },
        { Name: 'FromOrganization', DisplayName: 'From org', orderIndex: 3, width: 180 },
        { Name: 'ToPerson', DisplayName: 'To person', orderIndex: 4, width: 180 },
        { Name: 'ToOrganization', DisplayName: 'To org', orderIndex: 5, width: 180 },
        { Name: 'Status', DisplayName: 'Status', orderIndex: 6, width: 110 },
    ]);
}

async function loadViewByName(name: string): Promise<MJUserViewEntityExtended | null> {
    const rv = RunView.FromMetadataProvider(Metadata.Provider);
    const found = await rv.RunView<MJUserViewEntityExtended>({
        EntityName: 'MJ: User Views',
        ExtraFilter: `Name = '${EscapeFilterValue(name)}'`,
        MaxRows: 1,
        ResultType: 'entity_object',
    });
    return found.Success ? (found.Results?.[0] ?? null) : null;
}

function synthetic(
    entity: EntityInfo,
    name: string,
    gridState: ReturnType<typeof grid>,
    orderBy: string,
): MJUserViewEntityExtended {
    return {
        EntityID: entity.ID,
        Entity: entity.Name,
        Name: name,
        WhereClause: '',
        GridState: JSON.stringify(gridState),
        GridStateObject: gridState,
        OrderByClause: orderBy,
    } as unknown as MJUserViewEntityExtended;
}

export async function LoadDirectoryView(
    entityName: string,
    viewName: string,
    gridState: ReturnType<typeof grid>,
    orderBy: string,
): Promise<{ entity: EntityInfo | null; view: MJUserViewEntityExtended | null }> {
    const md = new Metadata();
    const entity = md.EntityByName(entityName) ?? null;
    if (!entity) return { entity: null, view: null };
    const named = await loadViewByName(viewName);
    if (named) return { entity, view: named };
    return { entity, view: synthetic(entity, viewName, gridState, orderBy) };
}

/**
 * Loads the Latest People and Latest Relationships views in a single batched `RunViews` round trip,
 * falling back to synthetic grid views if either named view has not yet been seeded.
 */
export async function LoadLatestDirectoryViews(): Promise<{
    people: { entity: EntityInfo | null; view: MJUserViewEntityExtended | null };
    relationships: { entity: EntityInfo | null; view: MJUserViewEntityExtended | null };
}> {
    const md = new Metadata();
    const peopleEntity = md.EntityByName(COMMON_ENTITIES.Person) ?? null;
    const relEntity = md.EntityByName(COMMON_ENTITIES.Relationship) ?? null;

    const rv = RunView.FromMetadataProvider(Metadata.Provider);
    const requests: RunViewParams[] = [
        ...(peopleEntity
            ? [
                  {
                      EntityName: 'MJ: User Views',
                      ExtraFilter: `Name = '${EscapeFilterValue(DIRECTORY_VIEW_NAMES.LatestPeople)}'`,
                      MaxRows: 1,
                      ResultType: 'entity_object' as const,
                  },
              ]
            : []),
        ...(relEntity
            ? [
                  {
                      EntityName: 'MJ: User Views',
                      ExtraFilter: `Name = '${EscapeFilterValue(DIRECTORY_VIEW_NAMES.LatestRelationships)}'`,
                      MaxRows: 1,
                      ResultType: 'entity_object' as const,
                  },
              ]
            : []),
    ];

    const results = requests.length > 0 ? await rv.RunViews(requests) : [];
    let idx = 0;

    let peopleView: MJUserViewEntityExtended | null = null;
    if (peopleEntity) {
        const res = results[idx++];
        const named = res?.Success ? ((res.Results as MJUserViewEntityExtended[])?.[0] ?? null) : null;
        peopleView = named ?? synthetic(peopleEntity, DIRECTORY_VIEW_NAMES.LatestPeople, LatestPeopleGridState(), '__mj_CreatedAt DESC');
    }

    let relView: MJUserViewEntityExtended | null = null;
    if (relEntity) {
        const res = results[idx++];
        const named = res?.Success ? ((res.Results as MJUserViewEntityExtended[])?.[0] ?? null) : null;
        relView = named ?? synthetic(relEntity, DIRECTORY_VIEW_NAMES.LatestRelationships, RelationshipsGridState(), '__mj_CreatedAt DESC');
    }

    return {
        people: { entity: peopleEntity, view: peopleView },
        relationships: { entity: relEntity, view: relView },
    };
}

export async function LoadPeopleDirectoryView() {
    return LoadDirectoryView(COMMON_ENTITIES.Person, DIRECTORY_VIEW_NAMES.People, PeopleDirectoryGridState(), 'DisplayName ASC');
}

export async function LoadLatestPeopleView() {
    return LoadDirectoryView(COMMON_ENTITIES.Person, DIRECTORY_VIEW_NAMES.LatestPeople, LatestPeopleGridState(), '__mj_CreatedAt DESC');
}

export async function LoadOrganizationsDirectoryView() {
    return LoadDirectoryView(COMMON_ENTITIES.Organization, DIRECTORY_VIEW_NAMES.Organizations, OrganizationsDirectoryGridState(), 'Name ASC');
}

export async function LoadLatestRelationshipsView() {
    return LoadDirectoryView(COMMON_ENTITIES.Relationship, DIRECTORY_VIEW_NAMES.LatestRelationships, RelationshipsGridState(), '__mj_CreatedAt DESC');
}

export { COMMON_ENTITIES };
