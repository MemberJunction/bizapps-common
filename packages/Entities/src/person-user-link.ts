import { RunView, type EntityInfo, type IMetadataProvider, type UserInfo } from '@memberjunction/core';
import { IsValidUUID } from '@memberjunction/global';

/** bizapps-common's People entity. */
export const PEOPLE_ENTITY = 'MJ_BizApps_Common: People';
const USERS_ENTITY = 'MJ: Users';

/**
 * Resolves an MJ user to a bizapps-common Person and back.
 *
 * bizapps-common deprecated `People.LinkedUserID` in 5.33.0. A platform binds a user to a Person
 * through an IS-A subtype of People and records the binding on the user: `LinkedEntityID` names
 * People or a subtype, and `LinkedEntityRecordID` holds the Person ID (an IS-A subtype shares its
 * parent's primary key). Such a platform can leave `LinkedUserID` empty, so the user's own link is
 * read first and `LinkedUserID` is only a fallback for users without one.
 */

/**
 * The user fields this module reads. `UserInfo` and the `MJ: Users` entity both fit; `UserInfo`
 * types the two link fields as numbers although they hold UUIDs.
 */
export interface PersonLinkedUser {
    ID: string;
    LinkedEntityID?: string | number | null;
    LinkedEntityRecordID?: string | number | null;
}

/** True when the entity is People or an IS-A subtype of it, at any depth. */
export function IsPeopleEntity(entity: EntityInfo | null | undefined): boolean {
    if (!entity) return false;
    return entity.Name === PEOPLE_ENTITY || (entity.ParentChain ?? []).some((parent) => parent.Name === PEOPLE_ENTITY);
}

/** The Person ID the user record links to, or null when it links to no People record. */
export function LinkedPersonRecordID(user: PersonLinkedUser, provider: IMetadataProvider): string | null {
    const entityID = user.LinkedEntityID != null ? String(user.LinkedEntityID) : '';
    const recordID = user.LinkedEntityRecordID != null ? String(user.LinkedEntityRecordID) : '';
    if (!IsValidUUID(entityID) || !IsValidUUID(recordID)) return null;
    return IsPeopleEntity(provider.EntityByID(entityID)) ? recordID : null;
}

/**
 * The Person a user is bound to: the user's own People link first, else the Person whose
 * deprecated `LinkedUserID` names the user.
 *
 * @param options.ActiveOnly only return a Person whose Status is Active.
 * @returns the Person ID, or null when the user has no (active) Person.
 * @throws when the lookup fails, so a caller can tell an error from a missing link.
 */
export async function ResolvePersonIDForUser(
    user: PersonLinkedUser | null | undefined,
    provider: IMetadataProvider,
    contextUser?: UserInfo,
    options: { ActiveOnly?: boolean } = {},
): Promise<string | null> {
    if (!user || !IsValidUUID(user.ID)) return null;
    const linked = LinkedPersonRecordID(user, provider);
    const match = linked ? `ID = '${linked}'` : `LinkedUserID = '${user.ID}'`;
    const result = await RunView.FromMetadataProvider(provider).RunView<{ ID: string }>({
        EntityName: PEOPLE_ENTITY,
        ExtraFilter: options.ActiveOnly ? `${match} AND Status = 'Active'` : match,
        Fields: ['ID'],
        MaxRows: 1,
        ResultType: 'simple',
        BypassCache: true,
    }, contextUser);
    if (!result?.Success) throw new Error(`Person lookup failed: ${result?.ErrorMessage ?? 'no result'}`);
    return result.Results?.[0]?.ID ?? null;
}

/**
 * The Person each user is bound to, for many users at once, by the same rule as
 * {@link ResolvePersonIDForUser}: a user's own People link first, else `LinkedUserID`.
 *
 * @param options.ActiveOnly only return Persons whose Status is Active.
 * @returns a map from lower-cased user ID to Person ID; users with no (active) Person are absent.
 * @throws when a lookup fails.
 */
export async function ResolvePersonIDsForUsers(
    userIDs: readonly string[],
    provider: IMetadataProvider,
    contextUser?: UserInfo,
    options: { ActiveOnly?: boolean } = {},
): Promise<Map<string, string>> {
    const wanted = uniqueUUIDs(userIDs);
    if (wanted.length === 0) return new Map<string, string>();
    const view = RunView.FromMetadataProvider(provider);
    const linkedPerson = await readLinkedPersonIDs(view, wanted, provider, contextUser);
    const unlinked = wanted.filter((id) => !linkedPerson.has(id));
    const rows = await readPeopleForUsers(view, [...new Set(linkedPerson.values())], unlinked, options, contextUser);
    return matchUsersToPeople(rows, linkedPerson, unlinked);
}

/** The Person each user's own People link names, keyed by lower-cased user ID. */
async function readLinkedPersonIDs(
    view: RunView,
    userIDs: readonly string[],
    provider: IMetadataProvider,
    contextUser?: UserInfo,
): Promise<Map<string, string>> {
    const users = await view.RunView<{ ID: string; LinkedEntityID: string | null; LinkedEntityRecordID: string | null }>({
        EntityName: USERS_ENTITY,
        ExtraFilter: `ID IN (${quoteList(userIDs)})`,
        Fields: ['ID', 'LinkedEntityID', 'LinkedEntityRecordID'],
        ResultType: 'simple',
        BypassCache: true,
    }, contextUser);
    if (!users?.Success) throw new Error(`User lookup failed: ${users?.ErrorMessage ?? 'no result'}`);
    const linkedPerson = new Map<string, string>();
    for (const row of users.Results ?? []) {
        const personID = LinkedPersonRecordID(row, provider);
        if (personID) linkedPerson.set(row.ID.toLowerCase(), personID.toLowerCase());
    }
    return linkedPerson;
}

/** One read of the People rows: those the user links name, plus those whose LinkedUserID is an unlinked user. */
async function readPeopleForUsers(
    view: RunView,
    linkedPersonIDs: readonly string[],
    unlinkedUserIDs: readonly string[],
    options: { ActiveOnly?: boolean },
    contextUser?: UserInfo,
): Promise<{ ID: string; LinkedUserID: string | null }[]> {
    const clauses: string[] = [];
    if (linkedPersonIDs.length > 0) clauses.push(`ID IN (${quoteList(linkedPersonIDs)})`);
    if (unlinkedUserIDs.length > 0) clauses.push(`LinkedUserID IN (${quoteList(unlinkedUserIDs)})`);
    const match = `(${clauses.join(' OR ')})`;
    const people = await view.RunView<{ ID: string; LinkedUserID: string | null }>({
        EntityName: PEOPLE_ENTITY,
        ExtraFilter: options.ActiveOnly ? `${match} AND Status = 'Active'` : match,
        Fields: ['ID', 'LinkedUserID'],
        OrderBy: '__mj_CreatedAt ASC',
        ResultType: 'simple',
        BypassCache: true,
    }, contextUser);
    if (!people?.Success) throw new Error(`Person lookup failed: ${people?.ErrorMessage ?? 'no result'}`);
    return people.Results ?? [];
}

/**
 * Pairs users with the People rows read for them. A linked user only matches the Person its link
 * names; an unlinked user matches the oldest Person whose LinkedUserID names it.
 */
function matchUsersToPeople(
    rows: readonly { ID: string; LinkedUserID: string | null }[],
    linkedPerson: ReadonlyMap<string, string>,
    unlinkedUserIDs: readonly string[],
): Map<string, string> {
    const found = new Map<string, string>();
    const byID = new Map(rows.map((row) => [row.ID.toLowerCase(), row.ID]));
    for (const [userID, personID] of linkedPerson) {
        const person = byID.get(personID);
        if (person) found.set(userID, person);
    }
    for (const row of rows) {
        const userID = row.LinkedUserID?.toLowerCase();
        if (userID && unlinkedUserIDs.includes(userID) && !found.has(userID)) found.set(userID, row.ID);
    }
    return found;
}

/**
 * The user bound to each Person: a user whose `LinkedEntityID` is People or a subtype and whose
 * `LinkedEntityRecordID` is the Person ID, else the Person's deprecated `LinkedUserID`.
 * When several users link one Person, an active user is taken first.
 *
 * @returns a map from lower-cased Person ID to user ID; Persons with no user are absent.
 * @throws when a lookup fails.
 */
export async function ResolveUserIDsForPeople(
    personIDs: readonly string[],
    provider: IMetadataProvider,
    contextUser?: UserInfo,
): Promise<Map<string, string>> {
    const wanted = uniqueUUIDs(personIDs);
    if (wanted.length === 0) return new Map<string, string>();
    const view = RunView.FromMetadataProvider(provider);
    const found = await readUsersLinkedToPeople(view, wanted, provider, contextUser);
    const rest = wanted.filter((id) => !found.has(id));
    if (rest.length > 0) {
        for (const [personID, userID] of await readPeopleLinkedUserIDs(view, rest, contextUser)) found.set(personID, userID);
    }
    return found;
}

/** The user whose own People link names each Person, active users first, keyed by lower-cased Person ID. */
async function readUsersLinkedToPeople(
    view: RunView,
    personIDs: readonly string[],
    provider: IMetadataProvider,
    contextUser?: UserInfo,
): Promise<Map<string, string>> {
    const found = new Map<string, string>();
    const peopleEntityIDs = provider.Entities.filter((entity) => IsPeopleEntity(entity)).map((entity) => entity.ID);
    if (peopleEntityIDs.length === 0) return found;
    const users = await view.RunView<{ ID: string; LinkedEntityRecordID: string }>({
        EntityName: USERS_ENTITY,
        // LinkedEntityRecordID is text, so match either case of each ID.
        ExtraFilter: `LinkedEntityID IN (${quoteList(peopleEntityIDs)}) AND LinkedEntityRecordID IN (${quoteList(bothCases(personIDs))})`,
        Fields: ['ID', 'LinkedEntityRecordID'],
        OrderBy: 'IsActive DESC, __mj_CreatedAt ASC',
        ResultType: 'simple',
        BypassCache: true,
    }, contextUser);
    if (!users?.Success) throw new Error(`User lookup failed: ${users?.ErrorMessage ?? 'no result'}`);
    for (const row of users.Results ?? []) {
        const personID = row.LinkedEntityRecordID?.toLowerCase();
        if (personID && !found.has(personID)) found.set(personID, row.ID);
    }
    return found;
}

/** The deprecated LinkedUserID of each Person that has one, keyed by lower-cased Person ID. */
async function readPeopleLinkedUserIDs(view: RunView, personIDs: readonly string[], contextUser?: UserInfo): Promise<Map<string, string>> {
    const people = await view.RunView<{ ID: string; LinkedUserID: string | null }>({
        EntityName: PEOPLE_ENTITY,
        ExtraFilter: `ID IN (${quoteList(personIDs)}) AND LinkedUserID IS NOT NULL`,
        Fields: ['ID', 'LinkedUserID'],
        ResultType: 'simple',
        BypassCache: true,
    }, contextUser);
    if (!people?.Success) throw new Error(`Person lookup failed: ${people?.ErrorMessage ?? 'no result'}`);
    const found = new Map<string, string>();
    for (const row of people.Results ?? []) {
        if (row.LinkedUserID) found.set(row.ID.toLowerCase(), row.LinkedUserID);
    }
    return found;
}

/** The user bound to one Person, or null. See {@link ResolveUserIDsForPeople}. */
export async function ResolveUserIDForPerson(personID: string, provider: IMetadataProvider, contextUser?: UserInfo): Promise<string | null> {
    if (!IsValidUUID(personID)) return null;
    const found = await ResolveUserIDsForPeople([personID], provider, contextUser);
    return found.get(personID.toLowerCase()) ?? null;
}

/** Valid UUIDs only, lower-cased and de-duplicated, so nothing else reaches a filter. */
function uniqueUUIDs(ids: readonly string[]): string[] {
    return [...new Set(ids.filter((id) => IsValidUUID(id)).map((id) => id.toLowerCase()))];
}

function bothCases(ids: readonly string[]): string[] {
    return [...new Set(ids.flatMap((id) => [id.toLowerCase(), id.toUpperCase()]))];
}

/** IDs reach here only through uniqueUUIDs or IsValidUUID; the assertion keeps a future caller honest. */
function quoteList(ids: readonly string[]): string {
    const invalid = ids.find((id) => !IsValidUUID(id));
    if (invalid !== undefined) {
        throw new Error(`quoteList received a non-UUID value: '${invalid}'. Validate IDs before building the filter.`);
    }
    return ids.map((id) => `'${id}'`).join(', ');
}
