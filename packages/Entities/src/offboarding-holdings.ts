/**
 * The Offboarding Holdings contract — how an app tells Common what a departed person still holds.
 *
 * When someone leaves, their open deals, accounts, task assignments and approval duties have to
 * move to a successor. Common cannot see the sales, tasks or accounting schemas, so each app ships
 * MJ Actions in the `Offboarding Holdings` action category:
 *
 *   `<App>: List Offboarding Holdings`      DriverClass `<App>.ListOffboardingHoldings`
 *     in:  LeaverUserID?, LeaverEmployeeID?  (at least one)
 *     out: Holdings  JSON array of {@link OffboardingHolding}
 *   `<App>: Reassign Offboarding Holdings`  DriverClass `<App>.ReassignOffboardingHoldings`
 *     in:  LeaverUserID?, LeaverEmployeeID?, SuccessorUserID, Kinds? (JSON array), RecordIDs? (JSON array)
 *     out: Moved (number), Skipped  JSON array of {@link OffboardingSkip}
 *
 * The category is the registry: the Offboarding screen and the deactivation warning run every
 * active action in it, so no app imports another and a host with no app actions sees an empty
 * list rather than an error. Each Reassign action re-checks permission per record on the server
 * and saves as the caller; `CanReassign` on a holding is advice for the screen, never a grant.
 *
 * This module is the contract plus the pure helpers the screen and the server share. It has no
 * MJ dependency, so it can be tested without a database, a provider or Angular.
 */

export const OFFBOARDING_HOLDINGS_CATEGORY = 'Offboarding Holdings';

/** DriverClass suffixes that mark an action's role in the contract. */
export const OFFBOARDING_LIST_DRIVER_SUFFIX = '.ListOffboardingHoldings';
export const OFFBOARDING_REASSIGN_DRIVER_SUFFIX = '.ReassignOffboardingHoldings';

/** The responsibility areas a holding belongs to; each gets one successor on the screen. */
export const OFFBOARDING_DOMAINS = ['Sales', 'Finance', 'Tasks'] as const;
export type OffboardingDomain = (typeof OFFBOARDING_DOMAINS)[number];

/** One open responsibility the leaver holds, as a List action reports it. */
export interface OffboardingHolding {
    App: string;
    Domain: OffboardingDomain;
    Kind: string;
    KindLabel: string;
    EntityName: string;
    RecordID: string;
    Label: string;
    /** Whether THIS caller may move it. Advisory: the Reassign action re-checks. */
    CanReassign: boolean;
    Note: string | null;
}

/** One record a Reassign action did not move, and why. */
export interface OffboardingSkip {
    Kind: string;
    EntityName: string;
    RecordID: string;
    Reason: string;
}

/** The minimum of an `MJ: Actions` row the pairing needs. */
export interface OffboardingActionRow {
    ID: string;
    Name: string;
    DriverClass: string | null;
}

/** One app's pair of actions, keyed by the DriverClass prefix (`Sales`, `Tasks`, ...). */
export interface OffboardingAppActions {
    App: string;
    ListActionID: string | null;
    ReassignActionID: string | null;
    ListActionName: string | null;
    ReassignActionName: string | null;
}

/** The leaver's identity as the actions take it. At least one is set. */
export interface OffboardingLeaver {
    LeaverUserID: string | null;
    LeaverEmployeeID: string | null;
}

/**
 * Groups the category's actions by app. The app key is the DriverClass text before the contract
 * suffix, so `Sales.ListOffboardingHoldings` and `Sales.ReassignOffboardingHoldings` pair up.
 * An action whose DriverClass carries neither suffix is ignored: it is not part of the contract.
 */
export function PairOffboardingActions(rows: readonly OffboardingActionRow[]): OffboardingAppActions[] {
    const byApp = new Map<string, OffboardingAppActions>();
    for (const row of rows) {
        const role = actionRole(row.DriverClass);
        if (!role) {
            continue;
        }
        const entry = byApp.get(role.App) ?? emptyApp(role.App);
        if (role.Kind === 'list') {
            entry.ListActionID = row.ID;
            entry.ListActionName = row.Name;
        } else {
            entry.ReassignActionID = row.ID;
            entry.ReassignActionName = row.Name;
        }
        byApp.set(role.App, entry);
    }
    return [...byApp.values()].sort((a, b) => a.App.localeCompare(b.App));
}

function actionRole(driverClass: string | null): { App: string; Kind: 'list' | 'reassign' } | null {
    const value = driverClass?.trim() ?? '';
    for (const [suffix, kind] of [
        [OFFBOARDING_LIST_DRIVER_SUFFIX, 'list'],
        [OFFBOARDING_REASSIGN_DRIVER_SUFFIX, 'reassign'],
    ] as const) {
        if (value.length > suffix.length && value.toLowerCase().endsWith(suffix.toLowerCase())) {
            return { App: value.slice(0, value.length - suffix.length), Kind: kind };
        }
    }
    return null;
}

function emptyApp(app: string): OffboardingAppActions {
    return { App: app, ListActionID: null, ReassignActionID: null, ListActionName: null, ReassignActionName: null };
}

/**
 * Reads a `Holdings` output value into typed rows. The value crosses an action boundary as a JSON
 * string (or an already-parsed array); anything malformed yields the rows that are well formed and
 * drops the rest, so one bad row from one app cannot hide every other app's holdings.
 */
export function ParseOffboardingHoldings(value: unknown): OffboardingHolding[] {
    return parseArray(value).flatMap((row) => {
        const holding = toHolding(row);
        return holding ? [holding] : [];
    });
}

/** Reads a `Skipped` output value the same way. */
export function ParseOffboardingSkips(value: unknown): OffboardingSkip[] {
    return parseArray(value).flatMap((row) => {
        if (!isRecord(row) || !hasText(row['RecordID'])) {
            return [];
        }
        return [{
            Kind: textOf(row['Kind']),
            EntityName: textOf(row['EntityName']),
            RecordID: textOf(row['RecordID']),
            Reason: textOf(row['Reason']),
        }];
    });
}

function parseArray(value: unknown): unknown[] {
    if (Array.isArray(value)) {
        return value;
    }
    if (typeof value !== 'string' || value.trim().length === 0) {
        return [];
    }
    try {
        const parsed: unknown = JSON.parse(value);
        return Array.isArray(parsed) ? parsed : [];
    } catch {
        return [];
    }
}

function toHolding(row: unknown): OffboardingHolding | null {
    if (!isRecord(row) || !hasText(row['RecordID']) || !hasText(row['Kind']) || !isDomain(row['Domain'])) {
        return null;
    }
    return {
        App: textOf(row['App']),
        Domain: row['Domain'],
        Kind: textOf(row['Kind']),
        KindLabel: hasText(row['KindLabel']) ? textOf(row['KindLabel']) : textOf(row['Kind']),
        EntityName: textOf(row['EntityName']),
        RecordID: textOf(row['RecordID']),
        Label: hasText(row['Label']) ? textOf(row['Label']) : textOf(row['RecordID']),
        CanReassign: row['CanReassign'] === true,
        Note: hasText(row['Note']) ? textOf(row['Note']) : null,
    };
}

function isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function hasText(value: unknown): boolean {
    return (typeof value === 'string' && value.trim().length > 0) || typeof value === 'number';
}

function textOf(value: unknown): string {
    return typeof value === 'string' ? value : typeof value === 'number' ? String(value) : '';
}

function isDomain(value: unknown): value is OffboardingDomain {
    return typeof value === 'string' && (OFFBOARDING_DOMAINS as readonly string[]).includes(value);
}

/** One domain's holdings, in the order the screen shows them. */
export interface OffboardingDomainGroup {
    Domain: OffboardingDomain;
    Holdings: OffboardingHolding[];
    ReassignableCount: number;
}

/** Groups holdings by domain in {@link OFFBOARDING_DOMAINS} order, leaving out empty domains. */
export function GroupOffboardingHoldings(holdings: readonly OffboardingHolding[]): OffboardingDomainGroup[] {
    return OFFBOARDING_DOMAINS.flatMap((domain) => {
        const inDomain = holdings
            .filter((h) => h.Domain === domain)
            .sort((a, b) => a.KindLabel.localeCompare(b.KindLabel) || a.Label.localeCompare(b.Label));
        if (inDomain.length === 0) {
            return [];
        }
        return [{ Domain: domain, Holdings: inDomain, ReassignableCount: inDomain.filter((h) => h.CanReassign).length }];
    });
}

/** One Reassign call the screen makes: an app's reassignable kinds within one domain. */
export interface OffboardingReassignPlan {
    App: string;
    Domain: OffboardingDomain;
    Kinds: string[];
}

/**
 * The Reassign calls for one domain: one per app that holds reassignable items there, restricted
 * to that app's kinds in that domain. Kinds with no reassignable item are left out, so a domain
 * that only lists notes (the CFO approver setting) makes no call at all.
 */
export function PlanOffboardingReassign(
    domain: OffboardingDomain,
    holdings: readonly OffboardingHolding[],
): OffboardingReassignPlan[] {
    const kindsByApp = new Map<string, Set<string>>();
    for (const holding of holdings) {
        if (holding.Domain !== domain || !holding.CanReassign) {
            continue;
        }
        const kinds = kindsByApp.get(holding.App) ?? new Set<string>();
        kinds.add(holding.Kind);
        kindsByApp.set(holding.App, kinds);
    }
    return [...kindsByApp.entries()]
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([app, kinds]) => ({ App: app, Domain: domain, Kinds: [...kinds].sort() }));
}

/** Counts holdings per domain, for a one-line summary such as the deactivation warning's. */
export function SummarizeOffboardingHoldings(holdings: readonly OffboardingHolding[]): string {
    return GroupOffboardingHoldings(holdings)
        .map((group) => `${group.Domain}: ${group.Holdings.length} item${group.Holdings.length === 1 ? '' : 's'}`)
        .join(', ');
}
