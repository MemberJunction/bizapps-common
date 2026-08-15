import { RunView } from '@memberjunction/core';
import { COMMON_ENTITIES } from './entity-names';
import type { DirectoryOrganizationRow, DirectoryPersonRow, DirectoryRelationshipRow } from './directory-types';

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

export async function SearchPeople(filter: string | undefined): Promise<DirectoryPersonRow[]> {
    const rv = new RunView();
    const result = await rv.RunView<DirectoryPersonRow>({
        EntityName: COMMON_ENTITIES.Person,
        Fields: [...PERSON_FIELDS],
        ExtraFilter: filter,
        OrderBy: 'LastName, FirstName',
        MaxRows: 200,
        ResultType: 'simple',
    });
    return result.Success ? result.Results : [];
}

export async function SearchOrganizations(filter: string | undefined): Promise<DirectoryOrganizationRow[]> {
    const rv = new RunView();
    const result = await rv.RunView<DirectoryOrganizationRow>({
        EntityName: COMMON_ENTITIES.Organization,
        Fields: [...ORGANIZATION_FIELDS],
        ExtraFilter: filter,
        OrderBy: 'Name',
        MaxRows: 200,
        ResultType: 'simple',
    });
    return result.Success ? result.Results : [];
}
