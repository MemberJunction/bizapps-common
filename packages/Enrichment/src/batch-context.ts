import type {
    mjBizAppsCommonContactMethodEntity,
    mjBizAppsCommonPersonEducationEntity,
    mjBizAppsCommonPersonExternalIdentityEntity,
    mjBizAppsCommonRelationshipEntity,
} from '@mj-biz-apps/common-entities';
import { RunView, type IMetadataProvider, type RunViewParams, type UserInfo } from '@memberjunction/core';
import { EscapeSQLString } from '@memberjunction/global';
import { EMAIL_CONTACT_TYPE, EMPLOYEE_RELATIONSHIP_TYPE, ENRICHMENT_ENTITIES, LINKEDIN_CONTACT_TYPE } from './entity-names.js';
import type { PersonSnapshot } from './request-builder.js';

/** Looked up once per run: the IDs and names the batch loader and the writers need. */
export interface RunLookups {
    EmployeeTypeID: string;
    EmailContactTypeID: string;
    LinkedInContactTypeID: string;
}

export interface PersonRow {
    ID: string;
    FirstName: string;
    LastName: string;
    Email: string | null;
    Status: string;
}

export interface OrganizationRow {
    ID: string;
    Name: string;
    Website: string | null;
}

/** Everything one batch needs, loaded in one RunViews call (plus one for current employers' websites). */
export interface BatchContext {
    People: Map<string, PersonRow>;
    ContactMethods: Map<string, mjBizAppsCommonContactMethodEntity[]>;
    EmployeeRelationships: Map<string, mjBizAppsCommonRelationshipEntity[]>;
    Educations: Map<string, mjBizAppsCommonPersonEducationEntity[]>;
    /** This provider's identity row per person. */
    Identities: Map<string, mjBizAppsCommonPersonExternalIdentityEntity>;
    /** Current employers' Organizations, for the request's domain. */
    Organizations: Map<string, OrganizationRow>;
}

export async function LoadRunLookups(provider: IMetadataProvider, contextUser: UserInfo): Promise<RunLookups> {
    const view = RunView.FromMetadataProvider(provider);
    const [types, contactTypes] = await view.RunViews<{ ID: string; Name: string }>([
        { EntityName: ENRICHMENT_ENTITIES.RelationshipTypes, ExtraFilter: `Name = '${EMPLOYEE_RELATIONSHIP_TYPE}'`, ResultType: 'simple', Fields: ['ID', 'Name'] },
        { EntityName: ENRICHMENT_ENTITIES.ContactTypes, ExtraFilter: `Name IN ('${EMAIL_CONTACT_TYPE}','${LINKEDIN_CONTACT_TYPE}')`, ResultType: 'simple', Fields: ['ID', 'Name'] },
    ], contextUser);
    const employee = Require(types, EMPLOYEE_RELATIONSHIP_TYPE, 'relationship type');
    const email = Require(contactTypes, EMAIL_CONTACT_TYPE, 'contact type');
    const linkedIn = Require(contactTypes, LINKEDIN_CONTACT_TYPE, 'contact type');
    return { EmployeeTypeID: employee, EmailContactTypeID: email, LinkedInContactTypeID: linkedIn };
}

function Require(result: { Success: boolean; ErrorMessage?: string; Results: { ID: string; Name: string }[] }, name: string, what: string): string {
    if (!result.Success) throw new Error(`Lookup of ${what} '${name}' failed: ${result.ErrorMessage}`);
    const row = result.Results.find((candidate) => candidate.Name === name);
    if (!row) throw new Error(`The ${what} '${name}' is not seeded.`);
    return row.ID;
}

export async function LoadBatchContext(
    personIDs: string[],
    providerCode: string,
    lookups: RunLookups,
    provider: IMetadataProvider,
    contextUser: UserInfo,
): Promise<BatchContext> {
    const ids = IdList(personIDs);
    const view = RunView.FromMetadataProvider(provider);
    const params: RunViewParams[] = [
        { EntityName: ENRICHMENT_ENTITIES.People, ExtraFilter: `ID IN (${ids})`, ResultType: 'simple', Fields: ['ID', 'FirstName', 'LastName', 'Email', 'Status'] },
        { EntityName: ENRICHMENT_ENTITIES.ContactMethods, ExtraFilter: `PersonID IN (${ids})`, ResultType: 'entity_object' },
        { EntityName: ENRICHMENT_ENTITIES.Relationships, ExtraFilter: `FromPersonID IN (${ids}) AND RelationshipTypeID = '${lookups.EmployeeTypeID}'`, ResultType: 'entity_object' },
        { EntityName: ENRICHMENT_ENTITIES.PersonEducations, ExtraFilter: `PersonID IN (${ids})`, ResultType: 'entity_object' },
        { EntityName: ENRICHMENT_ENTITIES.PersonExternalIdentities, ExtraFilter: `PersonID IN (${ids}) AND SourceSystem = '${EscapeSQLString(providerCode)}'`, ResultType: 'entity_object' },
    ];
    const [people, contacts, relationships, educations, identities] = await view.RunViews(params, contextUser);
    for (const [index, result] of [people, contacts, relationships, educations, identities].entries()) {
        if (!result.Success) throw new Error(`Batch context query ${index + 1} failed: ${result.ErrorMessage}`);
    }
    const context: BatchContext = {
        People: new Map((people.Results as PersonRow[]).map((row) => [row.ID.toLowerCase(), row])),
        ContactMethods: GroupBy(contacts.Results as mjBizAppsCommonContactMethodEntity[], (row) => row.PersonID),
        EmployeeRelationships: GroupBy(relationships.Results as mjBizAppsCommonRelationshipEntity[], (row) => row.FromPersonID),
        Educations: GroupBy(educations.Results as mjBizAppsCommonPersonEducationEntity[], (row) => row.PersonID),
        Identities: new Map((identities.Results as mjBizAppsCommonPersonExternalIdentityEntity[]).map((row) => [row.PersonID.toLowerCase(), row])),
        Organizations: new Map(),
    };
    context.Organizations = await LoadCurrentEmployers(context, provider, contextUser);
    return context;
}

/** Query 7: the relationship view carries the Organization name but not its website. */
async function LoadCurrentEmployers(context: BatchContext, provider: IMetadataProvider, contextUser: UserInfo): Promise<Map<string, OrganizationRow>> {
    const organizationIDs = new Set<string>();
    for (const rows of context.EmployeeRelationships.values()) {
        for (const row of rows) if (row.Status === 'Active' && row.ToOrganizationID) organizationIDs.add(row.ToOrganizationID);
    }
    if (organizationIDs.size === 0) return new Map();
    const view = RunView.FromMetadataProvider(provider);
    const result = await view.RunView<OrganizationRow>({
        EntityName: ENRICHMENT_ENTITIES.Organizations,
        ExtraFilter: `ID IN (${IdList([...organizationIDs])})`,
        ResultType: 'simple',
        Fields: ['ID', 'Name', 'Website'],
    }, contextUser);
    if (!result.Success) throw new Error(`Batch context query 7 failed: ${result.ErrorMessage}`);
    return new Map(result.Results.map((row) => [row.ID.toLowerCase(), row]));
}

/** Query 6, after the provider call: who else already holds the external IDs the vendor returned. */
export async function LoadIdentityHolders(
    externalIDs: string[],
    providerCode: string,
    provider: IMetadataProvider,
    contextUser: UserInfo,
): Promise<Map<string, string>> {
    const distinct = [...new Set(externalIDs.filter((id) => id.trim() !== ''))];
    if (distinct.length === 0) return new Map();
    const list = distinct.map((id) => `'${EscapeSQLString(id)}'`).join(',');
    const view = RunView.FromMetadataProvider(provider);
    const result = await view.RunView<{ PersonID: string; ExternalID: string }>({
        EntityName: ENRICHMENT_ENTITIES.PersonExternalIdentities,
        ExtraFilter: `SourceSystem = '${EscapeSQLString(providerCode)}' AND ExternalID IN (${list})`,
        ResultType: 'simple',
        Fields: ['PersonID', 'ExternalID'],
    }, contextUser);
    if (!result.Success) throw new Error(`Batch context query 6 failed: ${result.ErrorMessage}`);
    return new Map(result.Results.map((row) => [row.ExternalID, row.PersonID]));
}

/** The request builder's flat view of one person. */
export function SnapshotPerson(personID: string, context: BatchContext, lookups: RunLookups): PersonSnapshot | null {
    const person = context.People.get(personID.toLowerCase());
    if (!person) return null;
    const contacts = context.ContactMethods.get(personID.toLowerCase()) ?? [];
    const current = (context.EmployeeRelationships.get(personID.toLowerCase()) ?? []).find((row) => row.Status === 'Active' && row.ToOrganizationID);
    const employer = current?.ToOrganizationID ? context.Organizations.get(current.ToOrganizationID.toLowerCase()) ?? null : null;
    const identity = context.Identities.get(personID.toLowerCase()) ?? null;
    return {
        ID: person.ID,
        FirstName: person.FirstName,
        LastName: person.LastName,
        Email: person.Email,
        ContactEmails: contacts.filter((row) => SameID(row.ContactTypeID, lookups.EmailContactTypeID)).map((row) => row.Value),
        LinkedInURL: contacts.find((row) => SameID(row.ContactTypeID, lookups.LinkedInContactTypeID))?.Value ?? null,
        CurrentEmployer: employer ? { Name: employer.Name, Website: employer.Website } : current ? { Name: current.ToOrganization, Website: null } : null,
        MatchedExternalID: identity?.MatchStatus === 'Matched' ? identity.ExternalID : null,
    };
}

export function SameID(a: string | null | undefined, b: string | null | undefined): boolean {
    return a != null && b != null && a.toLowerCase() === b.toLowerCase();
}

function IdList(ids: string[]): string {
    if (ids.length === 0) return `'00000000-0000-0000-0000-000000000000'`;
    return ids.map((id) => `'${EscapeSQLString(id)}'`).join(',');
}

function GroupBy<T>(rows: T[], key: (row: T) => string | null): Map<string, T[]> {
    const out = new Map<string, T[]>();
    for (const row of rows) {
        const k = key(row);
        if (k == null) continue;
        const list = out.get(k.toLowerCase()) ?? [];
        list.push(row);
        out.set(k.toLowerCase(), list);
    }
    return out;
}
