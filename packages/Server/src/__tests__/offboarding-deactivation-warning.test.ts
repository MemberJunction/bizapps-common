import { beforeEach, describe, expect, it, vi } from 'vitest';

const H = vi.hoisted(() => ({
    actions: [] as { ID: string; Name: string; DriverClass: string; Category: string; Status: string }[],
    runAction: vi.fn(),
    runView: vi.fn(),
    saved: [] as { UserID: string; Title: string; Message: string }[],
    systemUser: { ID: 'SYS' } as { ID: string } | null,
}));

vi.mock('@memberjunction/actions', () => ({
    ActionEngineServer: {
        Instance: {
            Config: vi.fn(async () => undefined),
            get Actions() {
                return H.actions;
            },
            RunAction: H.runAction,
        },
    },
}));

vi.mock('@memberjunction/core', async (importOriginal) => ({
    ...(await importOriginal<object>()),
    RunView: class {
        public RunView = H.runView;
    },
    WellKnownUserSource: { Instance: { GetSystemUser: vi.fn(async () => H.systemUser) } },
}));

import type { BaseEntityEvent, IMetadataProvider } from '@memberjunction/core';
import { MJEmployeeEntity, MJUserEntity } from '@memberjunction/core-entities';
import {
    ACCOUNTING_COMPANY_PROFILES_ENTITY,
    BuildOffboardingWarning,
    DetectOffboardingDeactivation,
    OffboardingDeactivationWarning,
    OffboardingWarningRecipients,
} from '../custom/offboarding-deactivation-warning';

/** An instance of the entity class with only the fields the detector reads. */
function fake<T extends object>(cls: abstract new (...args: never[]) => T, fields: Record<string, unknown>): T {
    return Object.assign(Object.create(cls.prototype) as T, fields);
}

function saveEvent(entity: object, changed: string[], subType: 'create' | 'update' = 'update'): BaseEntityEvent {
    return { type: 'save', saveSubType: subType, baseEntity: entity, ChangedFieldNames: changed, payload: null } as unknown as BaseEntityEvent;
}

/** Shadows the generated getters, which read field state a bare prototype instance does not have. */
function employee(fields: Record<string, unknown>): MJEmployeeEntity {
    const e = fake(MJEmployeeEntity, {});
    for (const [k, v] of Object.entries(fields)) Object.defineProperty(e, k, { value: v });
    return e;
}
function user(fields: Record<string, unknown>): MJUserEntity {
    const u = fake(MJUserEntity, {});
    for (const [k, v] of Object.entries(fields)) Object.defineProperty(u, k, { value: v });
    return u;
}

describe('DetectOffboardingDeactivation', () => {
    it('reports an Employee whose Active flag was just cleared', () => {
        const e = employee({ ID: 'E1', Active: false, FirstName: 'Alex', LastName: 'Sample', Email: 'alex@example.com' });
        expect(DetectOffboardingDeactivation(saveEvent(e, ['Active']))).toEqual({ LeaverUserID: null, LeaverEmployeeID: 'E1', DisplayName: 'Alex Sample' });
    });

    it('reports a User whose IsActive flag was just cleared, carrying the linked Employee', () => {
        const u = user({ ID: 'U1', IsActive: false, EmployeeID: 'E1', Name: 'Alex Sample', Email: 'alex@example.com' });
        expect(DetectOffboardingDeactivation(saveEvent(u, ['IsActive']))).toEqual({ LeaverUserID: 'U1', LeaverEmployeeID: 'E1', DisplayName: 'Alex Sample' });
    });

    it('ignores reactivation, other field changes, creates and other event types', () => {
        expect(DetectOffboardingDeactivation(saveEvent(employee({ ID: 'E1', Active: true }), ['Active']))).toBeNull();
        expect(DetectOffboardingDeactivation(saveEvent(employee({ ID: 'E1', Active: false }), ['Title']))).toBeNull();
        expect(DetectOffboardingDeactivation(saveEvent(employee({ ID: 'E1', Active: false }), ['Active'], 'create'))).toBeNull();
        expect(DetectOffboardingDeactivation({ type: 'delete', baseEntity: employee({ ID: 'E1', Active: false }) } as unknown as BaseEntityEvent)).toBeNull();
        expect(DetectOffboardingDeactivation(saveEvent({}, ['Active']))).toBeNull();
    });
});

describe('OffboardingWarningRecipients', () => {
    it('dedupes across case, drops nulls and never notifies the leaver', () => {
        expect(OffboardingWarningRecipients(['sup-1'], ['SUP-1', null, 'cfo-1', 'u-leaver'], 'U-LEAVER')).toEqual(['sup-1', 'cfo-1']);
    });
});

describe('BuildOffboardingWarning', () => {
    it('names the leaver, counts per domain and says nothing moved', () => {
        const text = BuildOffboardingWarning({ LeaverUserID: 'U1', LeaverEmployeeID: null, DisplayName: 'Alex Sample' }, [
            { App: 'Sales', Domain: 'Sales', Kind: 'DEAL_OWNER', KindLabel: 'Deal owner', EntityName: 'Deals', RecordID: 'D1', Label: 'Secret deal', CanReassign: false, Note: null },
        ]);
        expect(text.Title).toContain('Alex Sample');
        expect(text.Message).toContain('Sales: 1 item');
        expect(text.Message).toContain('Nothing has been moved yet');
        expect(text.Message).not.toContain('Secret deal');
    });
});

describe('OffboardingDeactivationWarning.Warn', () => {
    const saveSpy = vi.fn();
    const md = {
        EntityByName: (name: string) => (name === ACCOUNTING_COMPANY_PROFILES_ENTITY ? { Name: name } : undefined),
        GetEntityObject: vi.fn(async () => {
            const n: Record<string, unknown> = { NewRecord: () => undefined, LatestResult: null };
            n.Save = async () => {
                H.saved.push({ UserID: n.UserID as string, Title: n.Title as string, Message: n.Message as string });
                saveSpy();
                return true;
            };
            return n;
        }),
    } as unknown as IMetadataProvider;

    beforeEach(() => {
        H.saved = [];
        H.systemUser = { ID: 'SYS' };
        H.runAction.mockReset();
        H.runView.mockReset();
        H.actions = [
            { ID: 'L1', Name: 'Sales: List Offboarding Holdings', DriverClass: 'Sales.ListOffboardingHoldings', Category: 'Offboarding Holdings', Status: 'Active' },
            { ID: 'R1', Name: 'Sales: Reassign Offboarding Holdings', DriverClass: 'Sales.ReassignOffboardingHoldings', Category: 'Offboarding Holdings', Status: 'Active' },
            { ID: 'L2', Name: 'Tasks: List Offboarding Holdings', DriverClass: 'Tasks.ListOffboardingHoldings', Category: 'Offboarding Holdings', Status: 'Disabled' },
            { ID: 'X', Name: 'Unrelated', DriverClass: 'Other.ListOffboardingHoldings', Category: 'Common', Status: 'Active' },
        ];
        H.runView.mockImplementation(async (params: { EntityName: string; ExtraFilter: string }) => {
            if (params.EntityName === 'MJ: Employees') return { Success: true, Results: [{ ID: 'E1', SupervisorID: 'E-SUP' }] };
            if (params.EntityName === 'MJ: Users') return { Success: true, Results: [{ ID: 'U-SUP', EmployeeID: 'E-SUP', IsActive: true }] };
            if (params.EntityName === ACCOUNTING_COMPANY_PROFILES_ENTITY) return { Success: true, Results: [{ ApprovalCFOUserID: 'U-CFO' }] };
            return { Success: false, ErrorMessage: 'unexpected', Results: [] };
        });
    });

    it('runs only active List actions in the category, as the system user', async () => {
        H.runAction.mockResolvedValue({ Success: true, Params: [{ Name: 'Holdings', Value: '[]', Type: 'Output' }] });
        await OffboardingDeactivationWarning.Instance.Warn({ LeaverUserID: null, LeaverEmployeeID: 'E1', DisplayName: 'Alex Sample' }, md);
        expect(H.runAction).toHaveBeenCalledTimes(1);
        const call = H.runAction.mock.calls[0][0] as { Action: { ID: string }; ContextUser: { ID: string } };
        expect(call.Action.ID).toBe('L1');
        expect(call.ContextUser.ID).toBe('SYS');
    });

    it('sends nothing when nothing is held', async () => {
        H.runAction.mockResolvedValue({ Success: true, Params: [{ Name: 'Holdings', Value: '[]', Type: 'Output' }] });
        const sent = await OffboardingDeactivationWarning.Instance.Warn({ LeaverUserID: null, LeaverEmployeeID: 'E1', DisplayName: 'Alex Sample' }, md);
        expect(sent).toBe(0);
        expect(H.saved).toEqual([]);
    });

    it('notifies the supervisor and the CFO approver when something is held', async () => {
        H.runAction.mockResolvedValue({
            Success: true,
            Params: [{ Name: 'Holdings', Type: 'Output', Value: JSON.stringify([{ App: 'Sales', Domain: 'Sales', Kind: 'DEAL_OWNER', RecordID: 'D1', CanReassign: true }]) }],
        });
        const sent = await OffboardingDeactivationWarning.Instance.Warn({ LeaverUserID: null, LeaverEmployeeID: 'E1', DisplayName: 'Alex Sample' }, md);
        expect(sent).toBe(2);
        expect(H.saved.map((n) => n.UserID)).toEqual(['U-SUP', 'U-CFO']);
    });

    it('skips the CFO lookup when accounting is not installed, and survives a failing app', async () => {
        H.runAction.mockResolvedValue({ Success: false, Message: 'boom' });
        const noAccounting = { ...md, EntityByName: () => undefined } as unknown as IMetadataProvider;
        const sent = await OffboardingDeactivationWarning.Instance.Warn({ LeaverUserID: 'U1', LeaverEmployeeID: 'E1', DisplayName: 'Alex' }, noAccounting);
        expect(sent).toBe(0);
        expect(H.runView.mock.calls.some((c) => (c[0] as { EntityName: string }).EntityName === ACCOUNTING_COMPANY_PROFILES_ENTITY)).toBe(false);
    });

    it('does nothing without a system user', async () => {
        H.systemUser = null;
        const sent = await OffboardingDeactivationWarning.Instance.Warn({ LeaverUserID: 'U1', LeaverEmployeeID: null, DisplayName: 'Alex' }, md);
        expect(sent).toBe(0);
        expect(H.runAction).not.toHaveBeenCalled();
    });
});
