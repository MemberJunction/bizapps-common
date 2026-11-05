import { RunView, type IMetadataProvider } from '@memberjunction/core';
import { MJGlobal } from '@memberjunction/global';
import type { StatTileTone } from '../components/stat-tile/stat-tile.component';
import { COMMON_ENTITIES } from './entity-names';
import { EscapeFilterValue } from './directory-stats';

/**
 * The Organization form's **Staff** section: the people who work at an organization, rolled up.
 *
 * Common owns the section and the staff list (active `Employee` relationships). Other apps add their
 * own totals and per-person columns by registering an {@link OrganizationStaffContributor} (e.g. order
 * figures, membership status), so several apps can extend the one section at once. Common never names
 * or imports a contributor; apps depend on Common, not the reverse. (Replacing the whole section is still possible through the form-panel
 * `contributionKey: 'staff'` + `priority`, but then only one app's version shows.)
 */

/** One active employee of the organization, from Common's `Employee` relationships. */
export interface OrganizationStaffMember {
    PersonID: string;
    Name: string;
    Title: string | null;
    /** The browser provider hands dates back as Date objects; tests and the server use ISO strings. */
    StartDate: Date | string | null;
}

/** One headline number in the section's stat row. `Value: null` renders an em dash (unknown), never 0. */
export interface StaffFigure {
    Label: string;
    Value: number | string | null;
    Detail?: string;
    Icon?: string;
    Tone?: StatTileTone;
}

/** A column a contributor adds to the staff table. `Key` must be unique within that contributor. */
export interface StaffColumn {
    Key: string;
    Header: string;
}

/** One cell in a contributed column. `Tone` colours the text only. */
export interface StaffCell {
    Text: string;
    Tone?: 'success' | 'warn' | 'error' | 'muted';
    Title?: string;
}

/** What one contributor adds to the section. `Cells` is keyed by upper-cased PersonID, then by column Key. */
export interface StaffContribution {
    Figures: StaffFigure[];
    Columns: StaffColumn[];
    Cells: Map<string, Record<string, StaffCell>>;
}

/** Everything a contributor is given. Staff is never empty when a contributor is called. */
export interface OrganizationStaffRequest {
    OrganizationID: string;
    Staff: OrganizationStaffMember[];
    Provider?: IMetadataProvider;
}

/**
 * Plug-in point for the Staff section. Register a subclass with
 * `@RegisterClass(OrganizationStaffContributor, '<unique key>')`; the highest-priority registration
 * wins per key (so an implementation can replace one app's contributor without touching the others).
 * Contributors are ClassFactory-instantiated (no Angular DI) and should be stateless.
 */
export abstract class OrganizationStaffContributor {
    /** Stable identifier; also the registration key. */
    public abstract readonly Key: string;
    /** Shown in the error line when this contributor fails, e.g. "Order figures". */
    public abstract readonly Label: string;
    /** Higher renders first. Common's own figures always come before every contributor. */
    public readonly Priority: number = 0;

    /** Load this contributor's figures and columns for the given staff. Throwing is allowed; the section reports it. */
    public abstract Load(request: OrganizationStaffRequest): Promise<StaffContribution>;
}

type ContributorConstructor = new () => OrganizationStaffContributor;

/** One instance per registered subclass, keyed by its constructor. */
const contributorCache = new Map<ContributorConstructor, OrganizationStaffContributor>();

/**
 * Every registered contributor — the winning registration per key — sorted by Priority (desc) then Key.
 * Returns [] when no app registers one.
 */
export function DiscoverOrganizationStaffContributors(): OrganizationStaffContributor[] {
    const factory = MJGlobal.Instance.ClassFactory;
    const registrations = factory.GetAllRegistrations(OrganizationStaffContributor) ?? [];
    const seen = new Set<string>();
    const contributors: OrganizationStaffContributor[] = [];
    for (const registration of registrations) {
        const key = registration.Key?.trim().toLowerCase();
        if (!key || seen.has(key)) {
            continue;
        }
        seen.add(key);
        const winner = factory.GetRegistration(OrganizationStaffContributor, registration.Key);
        if (!winner?.SubClass) {
            continue;
        }
        const Ctor = winner.SubClass as ContributorConstructor;
        let instance = contributorCache.get(Ctor);
        if (!instance) {
            instance = new Ctor();
            contributorCache.set(Ctor, instance);
        }
        contributors.push(instance);
    }
    return contributors.sort((a, b) => (b.Priority - a.Priority) || a.Key.localeCompare(b.Key));
}

/** A contributor's result: its contribution, or the reason it failed. */
export interface StaffContributorResult {
    Contributor: OrganizationStaffContributor;
    Contribution: StaffContribution | null;
    Error: string | null;
}

/** Runs every contributor concurrently. One failing contributor never hides the others. */
export async function RunStaffContributors(
    contributors: OrganizationStaffContributor[],
    request: OrganizationStaffRequest,
): Promise<StaffContributorResult[]> {
    const settled = await Promise.allSettled(contributors.map(c => c.Load(request)));
    return settled.map((outcome, i) => outcome.status === 'fulfilled'
        ? { Contributor: contributors[i], Contribution: outcome.value, Error: null }
        : {
            Contributor: contributors[i],
            Contribution: null,
            Error: outcome.reason instanceof Error ? outcome.reason.message : String(outcome.reason),
        });
}

/** Common's own headline figures for the staff list. `today` is injectable for tests. */
export function CommonStaffFigures(staff: OrganizationStaffMember[], today: Date = new Date()): StaffFigure[] {
    const yearAgo = new Date(Date.UTC(today.getUTCFullYear() - 1, today.getUTCMonth(), today.getUTCDate()));
    const recent = staff.filter(s => {
        if (!s.StartDate) return false;
        const start = new Date(s.StartDate);
        return !isNaN(start.getTime()) && start >= yearAgo;
    }).length;
    const titles = new Set(staff.map(s => s.Title?.trim()).filter((t): t is string => !!t));
    return [
        { Label: 'Staff', Value: staff.length, Icon: 'fa-solid fa-users', Detail: titles.size > 0 ? `${titles.size} role${titles.size === 1 ? '' : 's'}` : undefined },
        { Label: 'Joined in 12 months', Value: recent, Icon: 'fa-solid fa-user-plus' },
    ];
}

interface StaffRelationshipRow {
    FromPersonID: string;
    FromPerson: string | null;
    Title: string | null;
    StartDate: Date | string | null;
}

/** SQL date literal for today (UTC), for the active-relationship filter. */
function TodayLiteral(today: Date): string {
    return today.toISOString().slice(0, 10);
}

/**
 * Active staff of an organization: `Employee` relationships from a person to this organization whose
 * Status is Active and that have not ended. Sorted by name.
 */
export async function LoadOrganizationStaff(organizationID: string, provider?: IMetadataProvider, today: Date = new Date()): Promise<OrganizationStaffMember[]> {
    const rv = provider ? RunView.FromMetadataProvider(provider) : new RunView();
    const id = EscapeFilterValue(organizationID);
    const result = await rv.RunView<StaffRelationshipRow>({
        EntityName: COMMON_ENTITIES.Relationship,
        ExtraFilter: `ToOrganizationID='${id}' AND FromPersonID IS NOT NULL AND RelationshipType='Employee' AND Status='Active' AND (EndDate IS NULL OR EndDate >= '${TodayLiteral(today)}')`,
        Fields: ['FromPersonID', 'FromPerson', 'Title', 'StartDate'],
        OrderBy: 'FromPerson',
        ResultType: 'simple',
    });
    if (!result.Success) {
        throw new Error(result.ErrorMessage || 'Could not load the organization\'s staff.');
    }
    return (result.Results ?? []).map(r => ({
        PersonID: r.FromPersonID,
        Name: r.FromPerson ?? 'Unnamed person',
        Title: r.Title,
        StartDate: r.StartDate,
    }));
}
