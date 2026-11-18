import { describe, expect, it } from 'vitest';

import {
    GroupOffboardingHoldings,
    PairOffboardingActions,
    ParseOffboardingHoldings,
    ParseOffboardingSkips,
    PlanOffboardingReassign,
    SummarizeOffboardingHoldings,
    type OffboardingHolding,
} from '../offboarding-holdings.js';

function holding(overrides: Partial<OffboardingHolding>): OffboardingHolding {
    return {
        App: 'Sales',
        Domain: 'Sales',
        Kind: 'DEAL_OWNER',
        KindLabel: 'Deal owner',
        EntityName: 'Deals',
        RecordID: 'R1',
        Label: 'Sample deal',
        CanReassign: true,
        Note: null,
        ...overrides,
    };
}

describe('PairOffboardingActions', () => {
    it('pairs list and reassign actions by DriverClass prefix', () => {
        const apps = PairOffboardingActions([
            { ID: 'A1', Name: 'Sales: List Offboarding Holdings', DriverClass: 'Sales.ListOffboardingHoldings' },
            { ID: 'A2', Name: 'Sales: Reassign Offboarding Holdings', DriverClass: 'Sales.ReassignOffboardingHoldings' },
            { ID: 'A3', Name: 'Accounting: List Offboarding Holdings', DriverClass: 'Accounting.ListOffboardingHoldings' },
        ]);
        expect(apps).toEqual([
            { App: 'Accounting', ListActionID: 'A3', ReassignActionID: null, ListActionName: 'Accounting: List Offboarding Holdings', ReassignActionName: null },
            { App: 'Sales', ListActionID: 'A1', ReassignActionID: 'A2', ListActionName: 'Sales: List Offboarding Holdings', ReassignActionName: 'Sales: Reassign Offboarding Holdings' },
        ]);
    });

    it('ignores actions outside the contract and returns nothing for an empty category', () => {
        expect(PairOffboardingActions([{ ID: 'X', Name: 'Other', DriverClass: 'Sales.SomethingElse' }])).toEqual([]);
        expect(PairOffboardingActions([{ ID: 'X', Name: 'Bare', DriverClass: '.ListOffboardingHoldings' }])).toEqual([]);
        expect(PairOffboardingActions([{ ID: 'X', Name: 'Null', DriverClass: null }])).toEqual([]);
        expect(PairOffboardingActions([])).toEqual([]);
    });
});

describe('ParseOffboardingHoldings', () => {
    it('reads a JSON string and an already-parsed array', () => {
        const row = holding({});
        expect(ParseOffboardingHoldings(JSON.stringify([row]))).toEqual([row]);
        expect(ParseOffboardingHoldings([row])).toEqual([row]);
    });

    it('keeps well-formed rows and drops malformed ones', () => {
        const good = holding({ RecordID: 'R2' });
        const parsed = ParseOffboardingHoldings(JSON.stringify([
            good,
            { ...good, Domain: 'Marketing' },
            { ...good, RecordID: '' },
            'not a row',
            null,
        ]));
        expect(parsed).toEqual([good]);
    });

    it('treats a missing CanReassign as false and fills empty labels', () => {
        const [parsed] = ParseOffboardingHoldings([{ App: 'Tasks', Domain: 'Tasks', Kind: 'TASK_ASSIGNMENT', RecordID: 'T1' }]);
        expect(parsed.CanReassign).toBe(false);
        expect(parsed.KindLabel).toBe('TASK_ASSIGNMENT');
        expect(parsed.Label).toBe('T1');
        expect(parsed.Note).toBeNull();
    });

    it('returns an empty list for garbage', () => {
        expect(ParseOffboardingHoldings('not json')).toEqual([]);
        expect(ParseOffboardingHoldings('{"a":1}')).toEqual([]);
        expect(ParseOffboardingHoldings(undefined)).toEqual([]);
        expect(ParseOffboardingHoldings(42)).toEqual([]);
    });
});

describe('ParseOffboardingSkips', () => {
    it('reads skip rows and drops rows without a record', () => {
        const skips = ParseOffboardingSkips(JSON.stringify([
            { Kind: 'TASK_ASSIGNMENT', EntityName: 'Task Assignments', RecordID: 'T1', Reason: 'Successor has no Person record' },
            { Kind: 'TASK_ASSIGNMENT' },
        ]));
        expect(skips).toEqual([{ Kind: 'TASK_ASSIGNMENT', EntityName: 'Task Assignments', RecordID: 'T1', Reason: 'Successor has no Person record' }]);
    });
});

describe('GroupOffboardingHoldings', () => {
    it('groups in Sales, Finance, Tasks order and counts reassignable rows', () => {
        const groups = GroupOffboardingHoldings([
            holding({ Domain: 'Tasks', App: 'Tasks', Kind: 'TASK_ASSIGNMENT', KindLabel: 'Task', RecordID: 'T1' }),
            holding({ Domain: 'Finance', App: 'Accounting', Kind: 'CFO_APPROVER', KindLabel: 'CFO approver', RecordID: 'C1', CanReassign: false }),
            holding({ RecordID: 'D2', Label: 'B deal' }),
            holding({ RecordID: 'D1', Label: 'A deal' }),
        ]);
        expect(groups.map((g) => g.Domain)).toEqual(['Sales', 'Finance', 'Tasks']);
        expect(groups[0].Holdings.map((h) => h.RecordID)).toEqual(['D1', 'D2']);
        expect(groups[1].ReassignableCount).toBe(0);
        expect(groups[2].ReassignableCount).toBe(1);
    });

    it('returns no groups when nothing is held', () => {
        expect(GroupOffboardingHoldings([])).toEqual([]);
    });
});

describe('PlanOffboardingReassign', () => {
    it('plans one call per app with that app\'s reassignable kinds in the domain', () => {
        const plan = PlanOffboardingReassign('Tasks', [
            holding({ App: 'Tasks', Domain: 'Tasks', Kind: 'TASK_ASSIGNMENT' }),
            holding({ App: 'Tasks', Domain: 'Tasks', Kind: 'APPROVAL_ASSIGNMENT' }),
            holding({ App: 'Tasks', Domain: 'Tasks', Kind: 'TASK_ASSIGNMENT', RecordID: 'R2' }),
            holding({ App: 'Sales', Domain: 'Sales', Kind: 'DEAL_OWNER' }),
        ]);
        expect(plan).toEqual([{ App: 'Tasks', Domain: 'Tasks', Kinds: ['APPROVAL_ASSIGNMENT', 'TASK_ASSIGNMENT'] }]);
    });

    it('leaves out kinds the caller may not move', () => {
        expect(PlanOffboardingReassign('Finance', [
            holding({ App: 'Accounting', Domain: 'Finance', Kind: 'CFO_APPROVER', CanReassign: false }),
        ])).toEqual([]);
    });
});

describe('SummarizeOffboardingHoldings', () => {
    it('counts per domain', () => {
        expect(SummarizeOffboardingHoldings([
            holding({}),
            holding({ RecordID: 'R2' }),
            holding({ Domain: 'Tasks', App: 'Tasks', Kind: 'TASK_ASSIGNMENT' }),
        ])).toBe('Sales: 2 items, Tasks: 1 item');
    });
});
