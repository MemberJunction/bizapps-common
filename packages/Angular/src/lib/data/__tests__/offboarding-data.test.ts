import { beforeEach, describe, expect, it, vi } from 'vitest';

const H = vi.hoisted(() => ({
    runAction: vi.fn(),
}));

vi.mock('@memberjunction/graphql-dataprovider', () => ({
    GraphQLActionClient: class {
        public RunAction = H.runAction;
    },
}));

import type { IMetadataProvider } from '@memberjunction/core';
import {
    FilterOffboardingPeople,
    LeaverOf,
    MergeOffboardingPeople,
    OutputParamValue,
    RunOffboardingList,
    RunOffboardingReassign,
} from '../offboarding-data';

const provider = {} as IMetadataProvider;
const salesApp = { App: 'Sales', ListActionID: 'L1', ReassignActionID: 'R1', ListActionName: 'Sales: List', ReassignActionName: 'Sales: Reassign' };

describe('MergeOffboardingPeople', () => {
    it('merges linked users and employees, keeps unlinked employees, and lists inactive people first', () => {
        const people = MergeOffboardingPeople(
            [
                { ID: 'U1', Name: 'Alex Sample', Email: 'alex@example.com', IsActive: true, EmployeeID: 'E1' },
                { ID: 'U2', Name: 'Blake Sample', Email: 'blake@example.com', IsActive: true, EmployeeID: null },
            ],
            [
                { ID: 'E1', FirstName: 'Alex', LastName: 'Sample', Email: 'alex@example.com', Active: false },
                { ID: 'E2', FirstName: 'Casey', LastName: 'Sample', Email: null, Active: false },
            ],
        );
        expect(people.map((p) => [p.Key, p.Active])).toEqual([
            ['user:U1', false],
            ['employee:E2', false],
            ['user:U2', true],
        ]);
        expect(LeaverOf(people[0])).toEqual({ LeaverUserID: 'U1', LeaverEmployeeID: 'E1' });
        expect(LeaverOf(people[1])).toEqual({ LeaverUserID: null, LeaverEmployeeID: 'E2' });
    });

    it('matches linked IDs whatever their case', () => {
        const people = MergeOffboardingPeople(
            [{ ID: 'U1', Name: 'Alex', Email: null, IsActive: true, EmployeeID: 'abc' }],
            [{ ID: 'ABC', FirstName: 'Alex', LastName: null, Email: null, Active: true }],
        );
        expect(people).toHaveLength(1);
    });
});

describe('FilterOffboardingPeople', () => {
    const people = MergeOffboardingPeople(
        [{ ID: 'U1', Name: 'Alex Sample', Email: 'alex@example.com', IsActive: true, EmployeeID: null }],
        [{ ID: 'E2', FirstName: 'Casey', LastName: 'Other', Email: 'casey@example.org', Active: false }],
    );

    it('matches name or email, case-insensitively', () => {
        expect(FilterOffboardingPeople(people, 'ALEX').map((p) => p.Key)).toEqual(['user:U1']);
        expect(FilterOffboardingPeople(people, 'example.org').map((p) => p.Key)).toEqual(['employee:E2']);
        expect(FilterOffboardingPeople(people, '  ')).toHaveLength(2);
    });
});

describe('OutputParamValue', () => {
    it('reads an output row by name and ignores anything that is not a row list', () => {
        expect(OutputParamValue([{ Name: 'Moved', Value: 3 }], 'moved')).toBe(3);
        expect(OutputParamValue([{ Name: 'Other', Value: 3 }], 'Moved')).toBeUndefined();
        expect(OutputParamValue(null, 'Moved')).toBeUndefined();
        expect(OutputParamValue({ Name: 'Moved' }, 'Moved')).toBeUndefined();
    });
});

describe('RunOffboardingList', () => {
    beforeEach(() => H.runAction.mockReset());

    it('passes both leaver IDs and parses the Holdings output', async () => {
        H.runAction.mockResolvedValue({
            Success: true,
            Result: [{ Name: 'Holdings', Value: JSON.stringify([{ App: 'Sales', Domain: 'Sales', Kind: 'DEAL_OWNER', RecordID: 'D1', CanReassign: true }]) }],
        });
        const result = await RunOffboardingList(provider, salesApp, { LeaverUserID: 'U1', LeaverEmployeeID: 'E1' });
        expect(H.runAction).toHaveBeenCalledWith('L1', [
            { Name: 'LeaverUserID', Value: 'U1', Type: 'Input' },
            { Name: 'LeaverEmployeeID', Value: 'E1', Type: 'Input' },
        ]);
        expect(result.Error).toBeNull();
        expect(result.Holdings.map((h) => h.RecordID)).toEqual(['D1']);
    });

    it('reports a failing app instead of throwing', async () => {
        H.runAction.mockResolvedValue({ Success: false, Message: 'Not authorized to run action', Result: null });
        const result = await RunOffboardingList(provider, salesApp, { LeaverUserID: 'U1', LeaverEmployeeID: null });
        expect(result).toEqual({ App: 'Sales', Holdings: [], Error: 'Not authorized to run action' });
    });
});

describe('RunOffboardingReassign', () => {
    beforeEach(() => H.runAction.mockReset());

    it('sends the successor and the domain kinds, and reads Moved and Skipped', async () => {
        H.runAction.mockResolvedValue({
            Success: true,
            Result: [
                { Name: 'Moved', Value: 2 },
                { Name: 'Skipped', Value: JSON.stringify([{ Kind: 'DEAL_OWNER', EntityName: 'Deals', RecordID: 'D3', Reason: 'Not permitted' }]) },
            ],
        });
        const result = await RunOffboardingReassign(provider, salesApp, 'Sales', ['DEAL_OWNER'], { LeaverUserID: 'U1', LeaverEmployeeID: null }, 'U9');
        const sent = H.runAction.mock.calls[0][1] as { Name: string; Value: unknown }[];
        expect(sent.find((p) => p.Name === 'SuccessorUserID')?.Value).toBe('U9');
        expect(sent.find((p) => p.Name === 'Kinds')?.Value).toBe('["DEAL_OWNER"]');
        expect(result.Moved).toBe(2);
        expect(result.Skipped.map((s) => s.RecordID)).toEqual(['D3']);
        expect(result.Error).toBeNull();
    });

    it('surfaces NOT_AUTHORIZED as an error with nothing moved', async () => {
        H.runAction.mockResolvedValue({ Success: false, Message: 'You may not move any of these items.', Result: [{ Name: 'Moved', Value: 0 }] });
        const result = await RunOffboardingReassign(provider, salesApp, 'Sales', ['DEAL_OWNER'], { LeaverUserID: 'U1', LeaverEmployeeID: null }, 'U9');
        expect(result.Moved).toBe(0);
        expect(result.Error).toBe('You may not move any of these items.');
    });

    it('does not call an app that ships no reassign action', async () => {
        const listOnly = { ...salesApp, App: 'Accounting', ReassignActionID: null };
        const result = await RunOffboardingReassign(provider, listOnly, 'Finance', ['CFO_APPROVER'], { LeaverUserID: 'U1', LeaverEmployeeID: null }, 'U9');
        expect(H.runAction).not.toHaveBeenCalled();
        expect(result.Error).toContain('no reassign action');
    });
});
