import { beforeEach, describe, expect, it, vi } from 'vitest';

const H = vi.hoisted(() => {
    const commit = vi.fn(async () => undefined);
    const rollback = vi.fn(async () => undefined);
    const release = vi.fn(async () => undefined);
    const runView = vi.fn();
    const getEntityObject = vi.fn();
    const beginEntityTransaction = vi.fn(async () => ({ Commit: commit, Rollback: rollback }));

    const targetPeopleEntity = {
        ID: 'E0000000-0000-0000-0000-000000000001',
        Name: 'MJ_BizApps_Common: People',
        GetUserPermisions: vi.fn(() => ({ CanUpdate: true })),
    };
    const targetOrgsEntity = {
        ID: 'E0000000-0000-0000-0000-000000000002',
        Name: 'MJ_BizApps_Common: Organizations',
        GetUserPermisions: vi.fn(() => ({ CanUpdate: true })),
    };

    const own = {
        Entities: [targetPeopleEntity, targetOrgsEntity],
        BeginEntityTransaction: beginEntityTransaction,
        GetEntityObject: getEntityObject,
        ReleaseIndependentInstance: release,
    };

    const shared = {
        BeginEntityTransaction: vi.fn(),
        CreateIndependentInstance: vi.fn(async () => own),
    };

    return {
        commit,
        rollback,
        release,
        runView,
        getEntityObject,
        beginEntityTransaction,
        targetPeopleEntity,
        targetOrgsEntity,
        own,
        shared,
        provider: shared as object,
        logError: vi.fn(),
    };
});

vi.mock('@memberjunction/core', async (importOriginal) => ({
    ...(await importOriginal<object>()),
    Metadata: {
        get Provider() {
            return H.provider;
        },
    },
    RunView: class {
        public RunView = H.runView;
    },
    LogError: H.logError,
}));

vi.mock('@memberjunction/actions', () => ({ BaseAction: class {} }));

import type { ActionParam, ActionResultSimple, RunActionParams } from '@memberjunction/actions-base';
import { AttachAddressAction } from '../custom/attach-address.action';

const PERSON_ID = '11111111-2222-3333-4444-555555555555';
const TYPE_WORK_ID = 'A0000000-0000-0000-0000-000000000001';
const TYPE_HOME_ID = 'A0000000-0000-0000-0000-000000000002';

class TestableAction extends AttachAddressAction {
    public Run(params: RunActionParams): Promise<ActionResultSimple> {
        return this.InternalRunAction(params);
    }
}

function makeParams(values: Record<string, unknown>, contextUser: unknown = { ID: 'u1' }): RunActionParams {
    const Params: ActionParam[] = Object.entries(values).map(([Name, Value]) => ({
        Name,
        Value,
        Type: 'Input',
    }));
    return { Params, ContextUser: contextUser } as unknown as RunActionParams;
}

function outputOf(params: RunActionParams, name: string): unknown {
    return params.Params.find((p) => p.Name.toLowerCase() === name.toLowerCase())?.Value;
}

describe('AttachAddressAction', () => {
    beforeEach(() => {
        vi.clearAllMocks();
        H.provider = H.shared;
        H.targetPeopleEntity.GetUserPermisions.mockReturnValue({ CanUpdate: true });
        H.targetOrgsEntity.GetUserPermisions.mockReturnValue({ CanUpdate: true });
    });

    it('declares AuthorizesCaller = true', () => {
        expect(AttachAddressAction.AuthorizesCaller).toBe(true);
    });

    it('rejects missing ContextUser with VALIDATION_ERROR', async () => {
        const res = await new TestableAction().Run(
            makeParams({ EntityName: 'People', RecordID: PERSON_ID, Line1: '100 Main St' }, null),
        );
        expect(res.Success).toBe(false);
        expect(res.ResultCode).toBe('VALIDATION_ERROR');
        expect(H.shared.CreateIndependentInstance).not.toHaveBeenCalled();
    });

    it('rejects unsupported EntityName, invalid RecordID, or empty address content with VALIDATION_ERROR', async () => {
        const badEntity = await new TestableAction().Run(
            makeParams({ EntityName: 'Activities', RecordID: PERSON_ID, Line1: '100 Main St' }),
        );
        expect(badEntity.ResultCode).toBe('VALIDATION_ERROR');

        const badId = await new TestableAction().Run(
            makeParams({ EntityName: 'People', RecordID: 'not-a-uuid', Line1: '100 Main St' }),
        );
        expect(badId.ResultCode).toBe('VALIDATION_ERROR');

        const emptyAddress = await new TestableAction().Run(
            makeParams({ EntityName: 'People', RecordID: PERSON_ID, Line2: 'Suite 100', Country: 'US' }),
        );
        expect(emptyAddress.ResultCode).toBe('VALIDATION_ERROR');
    });

    it('rejects when caller lacks CanUpdate permission on the target entity', async () => {
        H.targetPeopleEntity.GetUserPermisions.mockReturnValue({ CanUpdate: false });
        const res = await new TestableAction().Run(
            makeParams({ EntityName: 'People', RecordID: PERSON_ID, Line1: '100 Main St' }),
        );
        expect(res.Success).toBe(false);
        expect(res.ResultCode).toBe('PERMISSION_DENIED');
        expect(H.release).toHaveBeenCalledTimes(1);
    });

    it('returns NOT_FOUND when the target Person/Organization record does not exist', async () => {
        H.runView.mockResolvedValueOnce({ Success: true, Results: [] });
        const res = await new TestableAction().Run(
            makeParams({ EntityName: 'People', RecordID: PERSON_ID, Line1: '100 Main St' }),
        );
        expect(res.Success).toBe(false);
        expect(res.ResultCode).toBe('NOT_FOUND');
        expect(H.release).toHaveBeenCalledTimes(1);
    });

    it('creates a new Address and primary AddressLink when the record has no existing links', async () => {
        H.runView
            .mockResolvedValueOnce({ Success: true, Results: [{ ID: PERSON_ID }] }) // target check
            .mockResolvedValueOnce({
                Success: true,
                Results: [
                    { ID: TYPE_WORK_ID, Name: 'Work', DefaultRank: 1, IsActive: true },
                    { ID: TYPE_HOME_ID, Name: 'Home', DefaultRank: 2, IsActive: true },
                ],
            }) // active types
            .mockResolvedValueOnce({ Success: true, Results: [] }); // existing links

        const savedAddress = {
            ID: 'ADDR-NEW-1',
            Line1: null as string | null,
            Line2: null as string | null,
            Line3: null as string | null,
            City: null as string | null,
            StateProvince: null as string | null,
            PostalCode: null as string | null,
            Country: null as string | null,
            Latitude: null as number | null,
            Longitude: null as number | null,
            NewRecord: vi.fn(),
            Save: vi.fn(async () => true),
        };
        const savedLink = {
            ID: 'LINK-NEW-1',
            AddressID: '',
            EntityID: '',
            RecordID: '',
            AddressTypeID: '',
            IsPrimary: false,
            Rank: null as number | null,
            NewRecord: vi.fn(),
            Save: vi.fn(async () => true),
        };

        H.getEntityObject.mockImplementation(async (entityName: string) => {
            if (entityName === 'MJ_BizApps_Common: Addresses') return savedAddress;
            return savedLink;
        });

        const params = makeParams({
            EntityName: 'People',
            RecordID: PERSON_ID,
            Line1: '  100 Main St ',
            City: ' Austin ',
            StateProvince: ' TX ',
            PostalCode: ' 78701 ',
        });
        const res = await new TestableAction().Run(params);

        expect(res.Success).toBe(true);
        expect(res.ResultCode).toBe('SUCCESS');
        expect(savedAddress.Line1).toBe('100 Main St');
        expect(savedAddress.Country).toBe('US');
        expect(savedLink.AddressTypeID).toBe(TYPE_WORK_ID);
        expect(savedLink.IsPrimary).toBe(true);
        expect(outputOf(params, 'AddressID')).toBe('ADDR-NEW-1');
        expect(outputOf(params, 'AddressLinkID')).toBe('LINK-NEW-1');
        expect(outputOf(params, 'CreatedNewAddress')).toBe(true);
        expect(outputOf(params, 'CreatedNewLink')).toBe(true);
        expect(H.commit).toHaveBeenCalledTimes(1);
        expect(H.release).toHaveBeenCalledTimes(1);
    });

    it('reuses a matching linked Address and existing same-type link, and demotes prior primary when promoted', async () => {
        const existingPrimaryLink = {
            ID: 'c0000000-0000-0000-0000-000000000001',
            AddressID: 'b0000000-0000-0000-0000-000000000001',
            AddressTypeID: TYPE_WORK_ID,
            IsPrimary: true,
            Rank: 1,
            Save: vi.fn(async () => true),
        };
        const existingHomeLink = {
            ID: 'c0000000-0000-0000-0000-000000000002',
            AddressID: 'b0000000-0000-0000-0000-000000000002',
            AddressTypeID: TYPE_HOME_ID,
            IsPrimary: false,
            Rank: 2,
            Save: vi.fn(async () => true),
        };
        const existingWorkAddr = {
            ID: 'b0000000-0000-0000-0000-000000000001',
            Line1: '100 Main St',
            Line2: null,
            Line3: null,
            City: 'Austin',
            StateProvince: 'TX',
            PostalCode: '78701',
            Country: 'US',
            Latitude: null,
            Longitude: null,
            Save: vi.fn(async () => true),
        };
        const existingHomeAddr = {
            ID: 'b0000000-0000-0000-0000-000000000002',
            Line1: '200 Oak Ave',
            Line2: null,
            Line3: null,
            City: 'Austin',
            StateProvince: 'TX',
            PostalCode: '78702',
            Country: 'US',
            Latitude: null,
            Longitude: null,
            Save: vi.fn(async () => true),
        };

        H.runView
            .mockResolvedValueOnce({ Success: true, Results: [{ ID: PERSON_ID }] })
            .mockResolvedValueOnce({
                Success: true,
                Results: [
                    { ID: TYPE_WORK_ID, Name: 'Work', DefaultRank: 1, IsActive: true },
                    { ID: TYPE_HOME_ID, Name: 'Home', DefaultRank: 2, IsActive: true },
                ],
            })
            .mockResolvedValueOnce({
                Success: true,
                Results: [existingPrimaryLink, existingHomeLink],
            })
            .mockResolvedValueOnce({
                Success: true,
                Results: [existingWorkAddr, existingHomeAddr],
            });

        const params = makeParams({
            EntityName: 'People',
            RecordID: PERSON_ID,
            Line1: '200 oak ave',
            City: 'austin',
            StateProvince: 'tx',
            PostalCode: '78702',
            AddressTypeID: 'Home',
            IsPrimary: true,
        });
        const res = await new TestableAction().Run(params);

        expect(res.Success).toBe(true);
        expect(outputOf(params, 'CreatedNewAddress')).toBe(false);
        expect(outputOf(params, 'CreatedNewLink')).toBe(false);
        expect(existingHomeLink.IsPrimary).toBe(true);
        expect(existingHomeLink.Save).toHaveBeenCalledTimes(1);
        expect(existingPrimaryLink.IsPrimary).toBe(false);
        expect(existingPrimaryLink.Save).toHaveBeenCalledTimes(1);
        expect(H.commit).toHaveBeenCalledTimes(1);
    });

    it('rolls back the transaction when saving the link fails', async () => {
        H.runView
            .mockResolvedValueOnce({ Success: true, Results: [{ ID: PERSON_ID }] })
            .mockResolvedValueOnce({
                Success: true,
                Results: [{ ID: TYPE_WORK_ID, Name: 'Work', DefaultRank: 1, IsActive: true }],
            })
            .mockResolvedValueOnce({ Success: true, Results: [] });

        const savedAddress = {
            ID: 'ADDR-NEW-1',
            NewRecord: vi.fn(),
            Save: vi.fn(async () => true),
        };
        const failingLink = {
            ID: 'LINK-FAIL',
            NewRecord: vi.fn(),
            Save: vi.fn(async () => false),
            LatestResult: { CompleteMessage: 'FK constraint error' },
        };

        H.getEntityObject.mockImplementation(async (entityName: string) => {
            if (entityName === 'MJ_BizApps_Common: Addresses') return savedAddress;
            return failingLink;
        });

        const res = await new TestableAction().Run(
            makeParams({ EntityName: 'People', RecordID: PERSON_ID, Line1: '100 Main St' }),
        );

        expect(res.Success).toBe(false);
        expect(res.ResultCode).toBe('ERROR');
        expect(res.Message).toContain('FK constraint error');
        expect(H.rollback).toHaveBeenCalledTimes(1);
        expect(H.commit).not.toHaveBeenCalled();
        expect(H.release).toHaveBeenCalledTimes(1);
    });
});
