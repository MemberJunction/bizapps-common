/**
 * Data access for the Offboarding screen: who can be picked as a leaver or successor, which apps
 * registered offboarding actions, and the List / Reassign calls themselves.
 *
 * Everything that decides (pairing actions, grouping, planning a reassign) lives in
 * `@mj-biz-apps/common-entities` so the server warning shares it. This file only moves data.
 */
import { RunView, type IMetadataProvider, type IRunViewProvider } from '@memberjunction/core';
import type { ActionParam } from '@memberjunction/actions-base';
import { GraphQLActionClient, type GraphQLDataProvider } from '@memberjunction/graphql-dataprovider';
import { EscapeSQLString, UUIDMap, UUIDSet } from '@memberjunction/global';
import {
    OFFBOARDING_HOLDINGS_CATEGORY,
    PairOffboardingActions,
    ParseOffboardingHoldings,
    ParseOffboardingSkips,
    type OffboardingActionRow,
    type OffboardingAppActions,
    type OffboardingDomain,
    type OffboardingHolding,
    type OffboardingLeaver,
    type OffboardingSkip,
} from '@mj-biz-apps/common-entities';

/** A person who can be picked: a User, an Employee, or both when they are linked. */
export interface OffboardingPerson {
    Key: string;
    UserID: string | null;
    EmployeeID: string | null;
    Name: string;
    Email: string | null;
    Active: boolean;
}

export interface OffboardingUserRow {
    ID: string;
    Name: string;
    Email: string | null;
    IsActive: boolean;
    EmployeeID: string | null;
}

export interface OffboardingEmployeeRow {
    ID: string;
    FirstName: string | null;
    LastName: string | null;
    Email: string | null;
    Active: boolean;
}

/**
 * One row per User (carrying its Employee when linked) plus one per Employee no User points at.
 * A linked person is active only when both records are. Inactive people sort first: they are the
 * likely leavers.
 */
export function MergeOffboardingPeople(users: readonly OffboardingUserRow[], employees: readonly OffboardingEmployeeRow[]): OffboardingPerson[] {
    const employeesByID = new UUIDMap<OffboardingEmployeeRow>();
    employees.forEach((employee) => employeesByID.Set(employee.ID, employee));
    const linked = new UUIDSet();
    const people: OffboardingPerson[] = users.map((user) => {
        const employee = user.EmployeeID ? employeesByID.Get(user.EmployeeID) : undefined;
        if (employee) {
            linked.Add(employee.ID);
        }
        return {
            Key: `user:${user.ID}`,
            UserID: user.ID,
            EmployeeID: user.EmployeeID,
            Name: user.Name,
            Email: user.Email,
            Active: user.IsActive && (employee ? employee.Active : true),
        };
    });
    for (const employee of employees) {
        if (!linked.Has(employee.ID)) {
            people.push(employeePerson(employee));
        }
    }
    return people.sort((a, b) => Number(a.Active) - Number(b.Active) || a.Name.localeCompare(b.Name));
}

function employeePerson(employee: OffboardingEmployeeRow): OffboardingPerson {
    const name = `${employee.FirstName ?? ''} ${employee.LastName ?? ''}`.trim();
    return {
        Key: `employee:${employee.ID}`,
        UserID: null,
        EmployeeID: employee.ID,
        Name: name || employee.Email || employee.ID,
        Email: employee.Email,
        Active: employee.Active,
    };
}

/** Case-insensitive match on name or email; an empty term matches everyone. */
export function FilterOffboardingPeople(people: readonly OffboardingPerson[], term: string): OffboardingPerson[] {
    const needle = term.trim().toLowerCase();
    if (!needle) {
        return [...people];
    }
    return people.filter((p) => p.Name.toLowerCase().includes(needle) || (p.Email ?? '').toLowerCase().includes(needle));
}

/** The leaver identity the actions take. */
export function LeaverOf(person: OffboardingPerson): OffboardingLeaver {
    return { LeaverUserID: person.UserID, LeaverEmployeeID: person.EmployeeID };
}

/** Users, Employees and the category's actions, in one round trip. */
export async function LoadOffboardingSetup(provider: IMetadataProvider): Promise<{ People: OffboardingPerson[]; Apps: OffboardingAppActions[]; Error: string | null }> {
    const [users, employees, actions] = await new RunView(provider as unknown as IRunViewProvider).RunViews([
        { EntityName: 'MJ: Users', Fields: ['ID', 'Name', 'Email', 'IsActive', 'EmployeeID'], ResultType: 'simple' },
        { EntityName: 'MJ: Employees', Fields: ['ID', 'FirstName', 'LastName', 'Email', 'Active'], ResultType: 'simple' },
        {
            EntityName: 'MJ: Actions',
            Fields: ['ID', 'Name', 'DriverClass'],
            ExtraFilter: `Category='${EscapeSQLString(OFFBOARDING_HOLDINGS_CATEGORY)}' AND Status='Active'`,
            ResultType: 'simple',
        },
    ]);
    const error = [users, employees, actions].find((r) => !r.Success)?.ErrorMessage ?? null;
    return {
        People: MergeOffboardingPeople((users.Results ?? []) as OffboardingUserRow[], (employees.Results ?? []) as OffboardingEmployeeRow[]),
        Apps: PairOffboardingActions((actions.Results ?? []) as OffboardingActionRow[]),
        Error: error,
    };
}

/** One app's List result. */
export interface OffboardingListResult {
    App: string;
    Holdings: OffboardingHolding[];
    Error: string | null;
}

/** One app's Reassign result for one domain. */
export interface OffboardingReassignResult {
    App: string;
    Domain: OffboardingDomain;
    Moved: number;
    Skipped: OffboardingSkip[];
    Error: string | null;
}

/**
 * Reads an output parameter from a client action result. The GraphQL action client puts the
 * server's output parameters, parsed from JSON, in `Result` as `{ Name, Value }` rows; that field
 * is typed for the server-side result-code entity, so it is read here as the wire value it is.
 */
export function OutputParamValue(result: unknown, name: string): unknown {
    if (!Array.isArray(result)) {
        return undefined;
    }
    const lower = name.toLowerCase();
    for (const row of result) {
        if (typeof row === 'object' && row !== null && 'Name' in row && String(row.Name).toLowerCase() === lower) {
            return 'Value' in row ? row.Value : undefined;
        }
    }
    return undefined;
}

function leaverParams(leaver: OffboardingLeaver): ActionParam[] {
    return [
        { Name: 'LeaverUserID', Value: leaver.LeaverUserID, Type: 'Input' },
        { Name: 'LeaverEmployeeID', Value: leaver.LeaverEmployeeID, Type: 'Input' },
    ];
}

/** Runs one app's List action. A failure is reported, never thrown. */
export async function RunOffboardingList(provider: IMetadataProvider, app: OffboardingAppActions, leaver: OffboardingLeaver): Promise<OffboardingListResult> {
    if (!app.ListActionID) {
        return { App: app.App, Holdings: [], Error: null };
    }
    const client = new GraphQLActionClient(provider as GraphQLDataProvider);
    const result = await client.RunAction(app.ListActionID, leaverParams(leaver));
    if (!result.Success) {
        return { App: app.App, Holdings: [], Error: result.Message || 'The list action failed.' };
    }
    return { App: app.App, Holdings: ParseOffboardingHoldings(OutputParamValue(result.Result, 'Holdings')), Error: null };
}

/** Runs one app's Reassign action for one domain's kinds. A failure is reported, never thrown. */
export async function RunOffboardingReassign(
    provider: IMetadataProvider,
    app: OffboardingAppActions,
    domain: OffboardingDomain,
    kinds: readonly string[],
    leaver: OffboardingLeaver,
    successorUserID: string,
): Promise<OffboardingReassignResult> {
    const empty = { App: app.App, Domain: domain, Moved: 0, Skipped: [] as OffboardingSkip[] };
    if (!app.ReassignActionID) {
        return { ...empty, Error: `${app.App} has no reassign action; move these items in ${app.App}.` };
    }
    const client = new GraphQLActionClient(provider as GraphQLDataProvider);
    const result = await client.RunAction(app.ReassignActionID, [
        ...leaverParams(leaver),
        { Name: 'SuccessorUserID', Value: successorUserID, Type: 'Input' },
        { Name: 'Kinds', Value: JSON.stringify(kinds), Type: 'Input' },
    ]);
    const moved = Number(OutputParamValue(result.Result, 'Moved') ?? 0);
    const skipped = ParseOffboardingSkips(OutputParamValue(result.Result, 'Skipped'));
    return {
        ...empty,
        Moved: Number.isFinite(moved) ? moved : 0,
        Skipped: skipped,
        Error: result.Success ? null : result.Message || 'The reassign action failed.',
    };
}
