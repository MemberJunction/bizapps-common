/**
 * Copyright (c) MemberJunction.com
 * SPDX-License-Identifier: BUSL-1.1
 */
import { afterEach, describe, expect, it, vi } from 'vitest';
import {
    BaseEntity,
    BaseEntityResult,
    EntityTransactionScope,
    IMetadataProvider,
    ProviderBase,
    RunView,
    RunViewParams,
    RunViewResult,
    TransactionGroupBase,
    UserInfo,
} from '@memberjunction/core';
import {
    CompanyMirrorError,
    RegisterCompanyMirrorDeletePolicy,
    ResetCompanyMirrorDeletePolicy,
    type OrganizationLookupCandidate,
    type OrganizationMirrorStatus,
} from '@mj-biz-apps/common-entities';
import {
    CompanyOrganizationMirrorEntityServer,
    TryUnlinkOrganizationForDeletedCompany,
    UnlinkOrganizationForDeletedCompany,
} from '@mj-biz-apps/common-core-entities-server';

interface FakeOrganizationEntity {
    ID: string;
    Name: string;
    LinkedCompanyID: string | null;
    Status: OrganizationMirrorStatus;
    TransactionGroup: TransactionGroupBase | null;
    LatestResult?: { CompleteMessage?: string };
    InnerLoad: ReturnType<typeof vi.fn>;
    Save: ReturnType<typeof vi.fn>;
    Delete: ReturnType<typeof vi.fn>;
}

function makeFakeOrganization(initial?: Partial<FakeOrganizationEntity>): FakeOrganizationEntity {
    return {
        ID: initial?.ID ?? '11111111-1111-4111-8111-111111111111',
        Name: initial?.Name ?? 'Northwind Operations',
        LinkedCompanyID: initial?.LinkedCompanyID ?? null,
        Status: initial?.Status ?? 'Active',
        TransactionGroup: initial?.TransactionGroup ?? null,
        LatestResult: initial?.LatestResult,
        InnerLoad: vi.fn().mockResolvedValue(true),
        Save: vi.fn().mockResolvedValue(true),
        Delete: vi.fn().mockResolvedValue(true),
    };
}

interface TransactionMockControls {
    readonly Commit: ReturnType<typeof vi.fn>;
    readonly Rollback: ReturnType<typeof vi.fn>;
    readonly BeginEntityTransaction: ReturnType<typeof vi.fn>;
}

function makeProvider(
    orgFactory: FakeOrganizationEntity | (() => FakeOrganizationEntity),
    withTransactions: boolean = false,
): { provider: IMetadataProvider; tx: TransactionMockControls } {
    const provider = Object.create(ProviderBase.prototype) as IMetadataProvider;
    const commitMock = vi.fn().mockResolvedValue(undefined);
    const rollbackMock = vi.fn().mockResolvedValue(undefined);
    const beginMock = vi.fn().mockImplementation(async (): Promise<EntityTransactionScope> => ({
        IsNested: false,
        Commit: commitMock,
        Rollback: rollbackMock,
    }));

    Object.defineProperty(provider, 'Entities', { value: [], enumerable: true, configurable: true });
    Object.defineProperty(provider, 'GetEntityObject', {
        value: vi.fn().mockImplementation(async () =>
            typeof orgFactory === 'function' ? orgFactory() : orgFactory,
        ),
        configurable: true,
    });
    Object.defineProperty(provider, 'SupportsEntityTransactions', {
        value: withTransactions,
        configurable: true,
    });
    if (withTransactions) {
        Object.defineProperty(provider, 'BeginEntityTransaction', {
            value: beginMock,
            configurable: true,
        });
    }

    return {
        provider,
        tx: {
            Commit: commitMock,
            Rollback: rollbackMock,
            BeginEntityTransaction: beginMock,
        },
    };
}

function makeCompanyServerEntity(
    companyID: string,
    provider: IMetadataProvider,
    user: UserInfo,
    transactionGroup: TransactionGroupBase | null = null,
): CompanyOrganizationMirrorEntityServer {
    const entity = Object.create(CompanyOrganizationMirrorEntityServer.prototype) as CompanyOrganizationMirrorEntityServer;
    const resultHistory: BaseEntityResult[] = [];
    Object.defineProperty(entity, '_resultHistory', { value: resultHistory, writable: true, configurable: true });
    Object.defineProperty(entity, 'ProviderToUse', { value: provider, configurable: true });
    Object.defineProperty(entity, 'ContextCurrentUser', { value: user, configurable: true });
    Object.defineProperty(entity, 'ID', { value: companyID, configurable: true });
    Object.defineProperty(entity, 'Name', { value: 'Northwind Operations', configurable: true });
    Object.defineProperty(entity, 'TransactionGroup', { value: transactionGroup, writable: true, configurable: true });
    return entity;
}

describe('Deterministic Company delete unlink/archive lifecycle', () => {
    const companyID = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    const otherCompanyID = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
    const orgID1 = '11111111-1111-4111-8111-111111111111';
    const orgID2 = '22222222-2222-4222-8222-222222222222';
    const orgID3 = '33333333-3333-4333-8333-333333333333';
    const user = new UserInfo(undefined, {
        ID: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        Name: 'Delete Lifecycle Tester',
        Email: 'delete-tester@example.com',
    });

    afterEach(() => {
        ResetCompanyMirrorDeletePolicy();
        vi.restoreAllMocks();
    });

    it('unlinks LinkedCompanyID and archives Active Organization to Inactive before super.Delete() without deleting the Organization', async () => {
        const linkedOrg = makeFakeOrganization({
            ID: orgID1,
            Name: 'Northwind Internal Org',
            LinkedCompanyID: companyID.toUpperCase(),
            Status: 'Active',
        });
        const { provider, tx } = makeProvider(linkedOrg, true);
        const callOrder: string[] = [];
        linkedOrg.Save.mockImplementation(async () => {
            callOrder.push('org.Save');
            return true;
        });

        const capturedParams: RunViewParams[] = [];
        vi.spyOn(RunView.prototype, 'RunView').mockImplementation(async (params: RunViewParams) => {
            capturedParams.push(params);
            const result: RunViewResult<OrganizationLookupCandidate> = {
                Success: true,
                Results: [
                    {
                        ID: orgID1,
                        Name: 'Northwind Internal Org',
                        LinkedCompanyID: companyID.toUpperCase(),
                        Status: 'Active',
                    },
                ],
                RowCount: 1,
                TotalRowCount: 1,
                ExecutionTime: 1,
                ErrorMessage: '',
            };
            return result as RunViewResult<never>;
        });

        const superDeleteSpy = vi.spyOn(BaseEntity.prototype, 'Delete').mockImplementation(async () => {
            callOrder.push('company.superDelete');
            return true;
        });

        const company = makeCompanyServerEntity(companyID, provider, user);
        const deleted = await company.Delete();

        expect(deleted).toBe(true);
        expect(company.LastMirrorError).toBeNull();
        expect(callOrder).toEqual(['org.Save', 'company.superDelete']);
        expect(linkedOrg.LinkedCompanyID).toBeNull();
        expect(linkedOrg.Status).toBe('Inactive');
        expect(linkedOrg.Delete).not.toHaveBeenCalled();
        expect(tx.BeginEntityTransaction).toHaveBeenCalledTimes(1);
        expect(tx.Commit).toHaveBeenCalledTimes(1);
        expect(tx.Rollback).not.toHaveBeenCalled();
        expect(superDeleteSpy).toHaveBeenCalledTimes(1);

        expect(capturedParams).toHaveLength(1);
        expect(capturedParams[0].ResultType).toBe('simple');
        expect(capturedParams[0].Fields).toEqual(['ID', 'Name', 'LinkedCompanyID', 'Status']);
        expect(capturedParams[0].ExtraFilter).toBe(`LinkedCompanyID = '${companyID}'`);
        expect(capturedParams[0].ExtraFilter).not.toMatch(/[\[\]"]/);
    });

    it('is idempotent when the Company has zero linked Organizations or is already unlinked', async () => {
        const unlinkedOrg = makeFakeOrganization({
            ID: orgID1,
            LinkedCompanyID: null,
            Status: 'Inactive',
        });
        const { provider } = makeProvider(unlinkedOrg);

        const runViewSpy = vi.spyOn(RunView.prototype, 'RunView').mockImplementation(async () => {
            const result: RunViewResult<OrganizationLookupCandidate> = {
                Success: true,
                Results: [],
                RowCount: 0,
                TotalRowCount: 0,
                ExecutionTime: 1,
                ErrorMessage: '',
            };
            return result as RunViewResult<never>;
        });
        const superDeleteSpy = vi.spyOn(BaseEntity.prototype, 'Delete').mockResolvedValue(true);

        const unlinkOutcome = await UnlinkOrganizationForDeletedCompany(companyID, provider, user);
        expect(unlinkOutcome).toEqual({
            CompanyID: companyID,
            OrganizationID: null,
            UnlinkedCount: 0,
            UnlinkedOrganizationIDs: [],
            Action: 'not_linked',
            AppliedStatus: null,
        });
        expect(unlinkedOrg.Save).not.toHaveBeenCalled();
        expect(unlinkedOrg.Delete).not.toHaveBeenCalled();

        // Also handles stale RunView row whose loaded entity was already unlinked and archived concurrently
        runViewSpy.mockResolvedValueOnce({
            Success: true,
            Results: [{ ID: orgID1, Name: 'Already Unlinked', LinkedCompanyID: companyID, Status: 'Inactive' }],
            RowCount: 1,
            TotalRowCount: 1,
            ExecutionTime: 1,
            ErrorMessage: '',
        } as RunViewResult<never>);

        const concurrentOutcome = await UnlinkOrganizationForDeletedCompany(companyID, provider, user);
        expect(concurrentOutcome).toEqual({
            CompanyID: companyID,
            OrganizationID: orgID1,
            UnlinkedCount: 0,
            UnlinkedOrganizationIDs: [],
            Action: 'unchanged',
            AppliedStatus: 'Inactive',
        });
        expect(unlinkedOrg.Save).not.toHaveBeenCalled();

        const company = makeCompanyServerEntity(companyID, provider, user);
        const deleted = await company.Delete();
        expect(deleted).toBe(true);
        expect(superDeleteSpy).toHaveBeenCalledTimes(1);
    });

    it('preserves Dissolved Organization status and supports unlink-only policy configuration', async () => {
        const dissolvedOrg = makeFakeOrganization({
            ID: orgID1,
            LinkedCompanyID: companyID,
            Status: 'Dissolved',
        });
        const { provider: dissolvedProvider } = makeProvider(dissolvedOrg);

        vi.spyOn(RunView.prototype, 'RunView').mockResolvedValueOnce({
            Success: true,
            Results: [{ ID: orgID1, Name: 'Dissolved Internal Org', LinkedCompanyID: companyID, Status: 'Dissolved' }],
            RowCount: 1,
            TotalRowCount: 1,
            ExecutionTime: 1,
            ErrorMessage: '',
        } as RunViewResult<never>);

        const dissolvedOutcome = await UnlinkOrganizationForDeletedCompany(companyID, dissolvedProvider, user);
        expect(dissolvedOutcome.Action).toBe('unlinked');
        expect(dissolvedOutcome.AppliedStatus).toBe('Dissolved');
        expect(dissolvedOrg.LinkedCompanyID).toBeNull();
        expect(dissolvedOrg.Status).toBe('Dissolved');
        expect(dissolvedOrg.Save).toHaveBeenCalledTimes(1);
        expect(dissolvedOrg.Delete).not.toHaveBeenCalled();

        // Configured unlink-only policy preserves Active status
        RegisterCompanyMirrorDeletePolicy({ ArchiveStatus: null });
        const activeOrg = makeFakeOrganization({
            ID: orgID2,
            LinkedCompanyID: companyID,
            Status: 'Active',
        });
        const { provider: activeProvider } = makeProvider(activeOrg);
        vi.spyOn(RunView.prototype, 'RunView').mockResolvedValueOnce({
            Success: true,
            Results: [{ ID: orgID2, Name: 'Retained Active Org', LinkedCompanyID: companyID, Status: 'Active' }],
            RowCount: 1,
            TotalRowCount: 1,
            ExecutionTime: 1,
            ErrorMessage: '',
        } as RunViewResult<never>);

        const company = makeCompanyServerEntity(companyID, activeProvider, user);
        vi.spyOn(BaseEntity.prototype, 'Delete').mockResolvedValueOnce(true);
        const deleted = await company.Delete();
        expect(deleted).toBe(true);
        expect(activeOrg.LinkedCompanyID).toBeNull();
        expect(activeOrg.Status).toBe('Active');
        expect(activeOrg.Delete).not.toHaveBeenCalled();
    });

    it('safely unlinks multiple Organizations linked to the deleted Company without touching unrelated Organizations', async () => {
        const orgA = makeFakeOrganization({
            ID: orgID1,
            Name: 'Primary Linked Org',
            LinkedCompanyID: companyID,
            Status: 'Active',
        });
        const orgB = makeFakeOrganization({
            ID: orgID2,
            Name: 'Secondary Linked Org',
            LinkedCompanyID: companyID.toUpperCase(),
            Status: 'Active',
        });
        const foreignOrg = makeFakeOrganization({
            ID: orgID3,
            Name: 'Foreign Company Org',
            LinkedCompanyID: otherCompanyID,
            Status: 'Active',
        });

        const orgsByOrder = [orgA, orgB];
        const { provider } = makeProvider(() => orgsByOrder.shift() ?? foreignOrg);

        vi.spyOn(RunView.prototype, 'RunView').mockResolvedValueOnce({
            Success: true,
            Results: [
                { ID: orgID2, Name: 'Secondary Linked Org', LinkedCompanyID: companyID.toUpperCase(), Status: 'Active' },
                { ID: orgID3, Name: 'Foreign Company Org', LinkedCompanyID: otherCompanyID, Status: 'Active' },
                { ID: orgID1, Name: 'Primary Linked Org', LinkedCompanyID: companyID, Status: 'Active' },
                { ID: orgID3, Name: 'External Org', LinkedCompanyID: null, Status: 'Active' },
            ],
            RowCount: 4,
            TotalRowCount: 4,
            ExecutionTime: 1,
            ErrorMessage: '',
        } as RunViewResult<never>);

        const outcome = await UnlinkOrganizationForDeletedCompany(companyID, provider, user);
        expect(outcome).toEqual({
            CompanyID: companyID,
            OrganizationID: orgID1,
            UnlinkedCount: 2,
            UnlinkedOrganizationIDs: [orgID1, orgID2],
            Action: 'unlinked',
            AppliedStatus: 'Inactive',
        });
        expect(orgA.LinkedCompanyID).toBeNull();
        expect(orgA.Status).toBe('Inactive');
        expect(orgB.LinkedCompanyID).toBeNull();
        expect(orgB.Status).toBe('Inactive');
        expect(foreignOrg.LinkedCompanyID).toBe(otherCompanyID);
        expect(foreignOrg.Status).toBe('Active');
        expect(orgA.Delete).not.toHaveBeenCalled();
        expect(orgB.Delete).not.toHaveBeenCalled();
    });

    it('aborts super.Delete(), rolls back transaction, and surfaces structured errors when lookup or unlink save fails', async () => {
        const failingOrg = makeFakeOrganization({
            ID: orgID1,
            LinkedCompanyID: companyID,
            Status: 'Active',
            LatestResult: { CompleteMessage: 'read-only database' },
        });
        failingOrg.Save.mockResolvedValueOnce(false);
        const { provider, tx } = makeProvider(failingOrg, true);

        const runViewSpy = vi.spyOn(RunView.prototype, 'RunView').mockResolvedValueOnce({
            Success: true,
            Results: [{ ID: orgID1, Name: 'Locked Org', LinkedCompanyID: companyID, Status: 'Active' }],
            RowCount: 1,
            TotalRowCount: 1,
            ExecutionTime: 1,
            ErrorMessage: '',
        } as RunViewResult<never>);
        const superDeleteSpy = vi.spyOn(BaseEntity.prototype, 'Delete').mockResolvedValue(true);

        const company = makeCompanyServerEntity(companyID, provider, user);
        const failedDelete = await company.Delete();

        expect(failedDelete).toBe(false);
        expect(superDeleteSpy).not.toHaveBeenCalled();
        expect(tx.Rollback).toHaveBeenCalledTimes(1);
        expect(tx.Commit).not.toHaveBeenCalled();
        expect(company.LastMirrorError?.Code).toBe('ORGANIZATION_SAVE_FAILED');
        expect(company.LastMirrorError?.Context.CompanyID).toBe(companyID);
        expect(company.LastMirrorError?.Context.OrganizationID).toBe(orgID1);
        expect(company.LastMirrorError?.Context.Operation).toBe('unlink');
        expect(company.LastMirrorError?.DiagnosticMessage).toContain('read-only database');
        expect(company.LatestResult?.Success).toBe(false);
        expect(company.LatestResult?.Type).toBe('delete');
        expect(company.LatestResult?.Message).toContain('[ORGANIZATION_SAVE_FAILED]');

        // Lookup failure also aborts cleanly and surfaces ORGANIZATION_LOOKUP_FAILED
        runViewSpy.mockResolvedValueOnce({
            Success: false,
            Results: [],
            RowCount: 0,
            TotalRowCount: 0,
            ExecutionTime: 1,
            ErrorMessage: 'connection reset',
        } as RunViewResult<never>);

        const lookupFailResult = await TryUnlinkOrganizationForDeletedCompany(companyID, provider, user);
        expect(lookupFailResult.Success).toBe(false);
        if (!lookupFailResult.Success && 'Error' in lookupFailResult) {
            expect(lookupFailResult.Error.Code).toBe('ORGANIZATION_LOOKUP_FAILED');
            expect(lookupFailResult.Error.Context.Operation).toBe('unlink');
            expect(lookupFailResult.Error.DiagnosticMessage).toContain('connection reset');
        }

        // UnlinkOrganizationForDeletedCompany throws typed CompanyMirrorError on invalid CompanyID
        await expect(UnlinkOrganizationForDeletedCompany('not-a-uuid', provider, user)).rejects.toBeInstanceOf(
            CompanyMirrorError,
        );
    });

    it('rolls back transactional Organization unlink when super.Delete() returns false and propagates TransactionGroup', async () => {
        const linkedOrg = makeFakeOrganization({
            ID: orgID1,
            LinkedCompanyID: companyID,
            Status: 'Active',
        });
        const { provider, tx } = makeProvider(linkedOrg, true);

        vi.spyOn(RunView.prototype, 'RunView').mockResolvedValue({
            Success: true,
            Results: [{ ID: orgID1, Name: 'Northwind Org', LinkedCompanyID: companyID, Status: 'Active' }],
            RowCount: 1,
            TotalRowCount: 1,
            ExecutionTime: 1,
            ErrorMessage: '',
        } as RunViewResult<never>);

        const superDeleteSpy = vi.spyOn(BaseEntity.prototype, 'Delete').mockResolvedValueOnce(false);
        const company = makeCompanyServerEntity(companyID, provider, user);
        const failedSuperDelete = await company.Delete();

        expect(failedSuperDelete).toBe(false);
        expect(tx.Rollback).toHaveBeenCalledTimes(1);
        expect(tx.Commit).not.toHaveBeenCalled();

        // When TransactionGroup is attached, org.Save() joins the same TransactionGroup
        const mockGroup = Object.create(TransactionGroupBase.prototype) as TransactionGroupBase;
        const groupedOrg = makeFakeOrganization({
            ID: orgID2,
            LinkedCompanyID: companyID,
            Status: 'Active',
        });
        const { provider: groupedProvider } = makeProvider(groupedOrg, false);
        superDeleteSpy.mockResolvedValueOnce(true);

        const groupedCompany = makeCompanyServerEntity(companyID, groupedProvider, user, mockGroup);
        const groupedDeleted = await groupedCompany.Delete();
        expect(groupedDeleted).toBe(true);
        expect(groupedOrg.TransactionGroup).toBe(mockGroup);
        expect(groupedOrg.Save).toHaveBeenCalledTimes(1);
    });
});
