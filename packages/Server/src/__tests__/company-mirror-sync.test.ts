/**
 * Copyright (c) MemberJunction.com
 * SPDX-License-Identifier: BUSL-1.1
 */
import { describe, expect, it, vi } from 'vitest';
import {
    BaseEntity,
    BaseEntityResult,
    IMetadataProvider,
    ProviderBase,
    RunView,
    RunViewParams,
    RunViewResult,
    UserInfo,
} from '@memberjunction/core';
import {
    CompanyMirrorError,
    type OrganizationLookupCandidate,
    type OrganizationMirrorStatus,
} from '@mj-biz-apps/common-entities';
import {
    CompanyOrganizationMirrorEntityServer,
    MirrorCompanyToOrganization,
    SyncCompaniesToOrganizationsServerOperation,
    TryMirrorCompanyToOrganization,
} from '@mj-biz-apps/common-core-entities-server';

interface FakeOrganizationEntity {
    ID: string;
    Name: string;
    LegalName: string | null;
    Website: string | null;
    LogoURL: string | null;
    Description: string | null;
    LinkedCompanyID: string | null;
    Status: OrganizationMirrorStatus;
    LatestResult?: { CompleteMessage?: string };
    NewRecord: ReturnType<typeof vi.fn>;
    InnerLoad: ReturnType<typeof vi.fn>;
    Save: ReturnType<typeof vi.fn>;
}

function makeFakeOrganization(initial?: Partial<FakeOrganizationEntity>): FakeOrganizationEntity {
    return {
        ID: initial?.ID ?? '11111111-1111-4111-8111-111111111111',
        Name: initial?.Name ?? '',
        LegalName: initial?.LegalName ?? null,
        Website: initial?.Website ?? null,
        LogoURL: initial?.LogoURL ?? null,
        Description: initial?.Description ?? null,
        LinkedCompanyID: initial?.LinkedCompanyID ?? null,
        Status: initial?.Status ?? 'Active',
        LatestResult: initial?.LatestResult,
        NewRecord: vi.fn(),
        InnerLoad: vi.fn().mockResolvedValue(true),
        Save: vi.fn().mockResolvedValue(true),
    };
}

function makeTypedProvider(orgFactory: FakeOrganizationEntity | (() => FakeOrganizationEntity)): IMetadataProvider {
    const provider = Object.create(ProviderBase.prototype) as IMetadataProvider;
    Object.defineProperty(provider, 'Entities', { value: [], enumerable: true, configurable: true });
    Object.defineProperty(provider, 'GetEntityObject', {
        value: vi.fn().mockImplementation(async () =>
            typeof orgFactory === 'function' ? orgFactory() : orgFactory,
        ),
        configurable: true,
    });
    return provider;
}

describe('Company <-> Organization mirror duplicate guard & structured error surfacing', () => {
    const companyID = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    const existingOrgID = '22222222-2222-4222-8222-222222222222';
    const duplicateOrgID = '33333333-3333-4333-8333-333333333333';
    const user = new UserInfo(undefined, {
        ID: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        Name: 'Mirror Tester',
        Email: 'mirror-tester@example.com',
    });

    it('detects and links a pre-existing unlinked internal Organization via RunView simple lookup with zero duplicates created', async () => {
        const preExistingOrg = makeFakeOrganization({
            ID: existingOrgID,
            Name: 'Northwind Operations',
            Website: 'https://northwind.example.com',
            Description: 'Pre-existing internal organization',
            LinkedCompanyID: null,
            Status: 'Active',
        });
        const provider = makeTypedProvider(preExistingOrg);
        const capturedParams: RunViewParams[] = [];

        const runViewSpy = vi.spyOn(RunView.prototype, 'RunView').mockImplementation(async (params: RunViewParams) => {
            capturedParams.push(params);
            const result: RunViewResult<OrganizationLookupCandidate> = {
                Success: true,
                Results: [
                    {
                        ID: existingOrgID,
                        Name: 'Northwind Operations',
                        LegalName: null,
                        Website: 'https://northwind.example.com',
                        WebsiteDomain: 'northwind.example.com',
                        LinkedCompanyID: null,
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

        try {
            const result = await TryMirrorCompanyToOrganization(
                {
                    ID: companyID,
                    Name: 'Northwind Operations',
                    Description: 'Pre-existing internal organization',
                    Website: 'https://northwind.example.com',
                    LogoURL: null,
                    Domain: 'northwind.example.com',
                },
                provider,
                user,
            );

            expect(result.Success).toBe(true);
            if (!result.Success || !('Item' in result)) return;

            expect(result.Item.Action).toBe('updated');
            expect(result.Item.OrganizationID).toBe(existingOrgID);
            expect(result.Item.LinkedExistingOrganization).toBe(true);
            expect(result.Item.MatchStrategy).toBe('normalized_name');
            expect(preExistingOrg.NewRecord).not.toHaveBeenCalled();
            expect(preExistingOrg.InnerLoad).toHaveBeenCalledTimes(1);
            expect(preExistingOrg.LinkedCompanyID).toBe(companyID);
            expect(preExistingOrg.Save).toHaveBeenCalledTimes(1);

            expect(capturedParams).toHaveLength(1);
            expect(capturedParams[0].ResultType).toBe('simple');
            expect(capturedParams[0].Fields).toEqual([
                'ID',
                'Name',
                'LegalName',
                'Website',
                'WebsiteDomain',
                'LinkedCompanyID',
                'Status',
            ]);
            expect(capturedParams[0].ExtraFilter).toContain(`LinkedCompanyID = '${companyID}'`);
            expect(capturedParams[0].ExtraFilter).toContain('LinkedCompanyID IS NULL');
            expect(capturedParams[0].ExtraFilter).toContain("WebsiteDomain = 'northwind.example.com'");
        } finally {
            runViewSpy.mockRestore();
        }
    });

    it('performs idempotent re-sync when already linked even if another unlinked Organization shares the domain', async () => {
        const linkedOrg = makeFakeOrganization({
            ID: existingOrgID,
            Name: 'Northwind Operations',
            Website: 'https://northwind.example.com',
            Description: 'Canonical description',
            LogoURL: null,
            LinkedCompanyID: companyID.toUpperCase(),
            Status: 'Active',
        });
        const provider = makeTypedProvider(linkedOrg);

        const runViewSpy = vi.spyOn(RunView.prototype, 'RunView').mockImplementation(async () => {
            const result: RunViewResult<OrganizationLookupCandidate> = {
                Success: true,
                Results: [
                    {
                        ID: duplicateOrgID,
                        Name: 'Northwind Subsidiary',
                        WebsiteDomain: 'northwind.example.com',
                        LinkedCompanyID: null,
                        Status: 'Active',
                    },
                    {
                        ID: existingOrgID,
                        Name: 'Northwind Operations',
                        WebsiteDomain: 'northwind.example.com',
                        LinkedCompanyID: companyID,
                        Status: 'Active',
                    },
                ],
                RowCount: 2,
                TotalRowCount: 2,
                ExecutionTime: 1,
                ErrorMessage: '',
            };
            return result as RunViewResult<never>;
        });

        try {
            const item = await MirrorCompanyToOrganization(
                {
                    ID: companyID,
                    Name: '  Northwind Operations  ',
                    Description: 'Canonical description',
                    Website: 'https://northwind.example.com',
                    LogoURL: null,
                },
                provider,
                user,
            );

            expect(item.Action).toBe('unchanged');
            expect(item.OrganizationID).toBe(existingOrgID);
            expect(item.LinkedExistingOrganization).toBe(false);
            expect(item.MatchStrategy).toBe('linked_company_id');
            expect(linkedOrg.NewRecord).not.toHaveBeenCalled();
            expect(linkedOrg.Save).not.toHaveBeenCalled();
        } finally {
            runViewSpy.mockRestore();
        }
    });

    it('surfaces structured AMBIGUOUS_ORGANIZATION_MATCH and ORGANIZATION_SAVE_FAILED errors without throwing from TryMirrorCompanyToOrganization', async () => {
        const fakeOrg = makeFakeOrganization({
            LatestResult: { CompleteMessage: 'FK constraint failure' },
        });
        const provider = makeTypedProvider(fakeOrg);

        // 1. Ambiguous match
        let runViewSpy = vi.spyOn(RunView.prototype, 'RunView').mockImplementation(async () => {
            const result: RunViewResult<OrganizationLookupCandidate> = {
                Success: true,
                Results: [
                    { ID: existingOrgID, Name: 'Ambiguous Co', LinkedCompanyID: null },
                    { ID: duplicateOrgID, Name: 'Ambiguous Co', LinkedCompanyID: null },
                ],
                RowCount: 2,
                TotalRowCount: 2,
                ExecutionTime: 1,
                ErrorMessage: '',
            };
            return result as RunViewResult<never>;
        });

        try {
            const ambiguousResult = await TryMirrorCompanyToOrganization(
                { ID: companyID, Name: 'Ambiguous Co', Description: null, Website: null, LogoURL: null },
                provider,
                user,
            );
            expect(ambiguousResult.Success).toBe(false);
            if (!ambiguousResult.Success && 'Error' in ambiguousResult) {
                expect(ambiguousResult.Error.Code).toBe('AMBIGUOUS_ORGANIZATION_MATCH');
                expect(ambiguousResult.Error.Context.CompanyID).toBe(companyID);
                expect(ambiguousResult.Error.Context.CandidateOrganizationIDs).toEqual([existingOrgID, duplicateOrgID]);
            }

            const serverOp = new SyncCompaniesToOrganizationsServerOperation();
            runViewSpy.mockRestore();
            runViewSpy = vi
                .spyOn(RunView.prototype, 'RunView')
                .mockResolvedValueOnce({
                    Success: true,
                    Results: [{ ID: companyID, Name: 'Ambiguous Co', Description: null, Website: null, LogoURL: null }],
                    RowCount: 1,
                    TotalRowCount: 1,
                    ExecutionTime: 1,
                    ErrorMessage: '',
                } as RunViewResult<never>)
                .mockResolvedValueOnce({
                    Success: true,
                    Results: [
                        { ID: existingOrgID, Name: 'Ambiguous Co', LinkedCompanyID: null },
                        { ID: duplicateOrgID, Name: 'Ambiguous Co', LinkedCompanyID: null },
                    ],
                    RowCount: 2,
                    TotalRowCount: 2,
                    ExecutionTime: 1,
                    ErrorMessage: '',
                } as RunViewResult<never>);

            const opResult = await serverOp.ExecuteServer(
                { CompanyID: companyID },
                { provider, user, emitProgress: () => {} },
            );
            expect(opResult.Success).toBe(false);
            expect(opResult.ResultCode).toBe('AMBIGUOUS_ORGANIZATION_MATCH');
            expect(opResult.ErrorMessage).toContain(existingOrgID);
        } finally {
            runViewSpy.mockRestore();
        }

        // 2. Save failure
        fakeOrg.Save.mockResolvedValueOnce(false).mockResolvedValueOnce(false);
        runViewSpy = vi.spyOn(RunView.prototype, 'RunView').mockResolvedValue({
            Success: true,
            Results: [],
            RowCount: 0,
            TotalRowCount: 0,
            ExecutionTime: 1,
            ErrorMessage: '',
        } as RunViewResult<never>);

        try {
            const saveFailure = await TryMirrorCompanyToOrganization(
                { ID: companyID, Name: 'Acme', Description: null, Website: null, LogoURL: null },
                provider,
                user,
            );
            expect(saveFailure.Success).toBe(false);
            if (!saveFailure.Success && 'Error' in saveFailure) {
                expect(saveFailure.Error.Code).toBe('ORGANIZATION_SAVE_FAILED');
                expect(saveFailure.Error.Context.Operation).toBe('create');
                expect(saveFailure.Error.DiagnosticMessage).toContain('FK constraint failure');
            }

            await expect(
                MirrorCompanyToOrganization(
                    { ID: companyID, Name: 'Acme', Description: null, Website: null, LogoURL: null },
                    provider,
                    user,
                ),
            ).rejects.toBeInstanceOf(CompanyMirrorError);
        } finally {
            runViewSpy.mockRestore();
        }
    });

    it('CompanyOrganizationMirrorEntityServer.Save() propagates structured error into LastMirrorError and LatestResult and clears on subsequent success', async () => {
        const fakeOrg = makeFakeOrganization({
            ID: existingOrgID,
            Name: 'Old Name',
            LinkedCompanyID: null,
        });
        const provider = makeTypedProvider(fakeOrg);
        const superSaveSpy = vi.spyOn(BaseEntity.prototype, 'Save');
        const runViewSpy = vi.spyOn(RunView.prototype, 'RunView');

        const entity = Object.create(CompanyOrganizationMirrorEntityServer.prototype) as CompanyOrganizationMirrorEntityServer;
        const resultHistory: BaseEntityResult[] = [];
        Object.defineProperty(entity, '_resultHistory', { value: resultHistory, writable: true, configurable: true });
        Object.defineProperty(entity, 'ProviderToUse', { value: provider, configurable: true });
        Object.defineProperty(entity, 'ContextCurrentUser', { value: user, configurable: true });
        Object.defineProperty(entity, 'ID', { value: companyID, configurable: true });
        Object.defineProperty(entity, 'Name', { value: 'Northwind Operations', configurable: true });
        Object.defineProperty(entity, 'Description', { value: null, configurable: true });
        Object.defineProperty(entity, 'Website', { value: null, configurable: true });
        Object.defineProperty(entity, 'LogoURL', { value: null, configurable: true });
        Object.defineProperty(entity, 'Domain', { value: null, configurable: true });

        try {
            // Failure case: mirror persistence fails -> Save returns false, populates LastMirrorError and LatestResult
            superSaveSpy.mockResolvedValueOnce(true);
            fakeOrg.Save.mockResolvedValueOnce(false);
            fakeOrg.LatestResult = { CompleteMessage: 'permission denied' };
            runViewSpy.mockResolvedValueOnce({
                Success: true,
                Results: [{ ID: existingOrgID, Name: 'Old Name', LinkedCompanyID: null }],
                RowCount: 1,
                TotalRowCount: 1,
                ExecutionTime: 1,
                ErrorMessage: '',
            } as RunViewResult<never>);

            const failedSave = await entity.Save();
            expect(failedSave).toBe(false);
            expect(entity.LastMirrorError?.Code).toBe('ORGANIZATION_SAVE_FAILED');
            expect(entity.LastMirrorError?.Context.CompanyID).toBe(companyID);
            expect(entity.LastMirrorError?.Context.OrganizationID).toBe(existingOrgID);
            expect(entity.LatestResult?.Success).toBe(false);
            expect(entity.LatestResult?.Message).toContain('[ORGANIZATION_SAVE_FAILED]');
            expect(entity.LatestResult?.Message).toContain('permission denied');

            // Subsequent clean save clears LastMirrorError
            superSaveSpy.mockResolvedValueOnce(true);
            runViewSpy.mockResolvedValueOnce({
                Success: true,
                Results: [{ ID: existingOrgID, Name: 'Northwind Operations', LinkedCompanyID: companyID }],
                RowCount: 1,
                TotalRowCount: 1,
                ExecutionTime: 1,
                ErrorMessage: '',
            } as RunViewResult<never>);

            const cleanSave = await entity.Save();
            expect(cleanSave).toBe(true);
            expect(entity.LastMirrorError).toBeNull();
        } finally {
            superSaveSpy.mockRestore();
            runViewSpy.mockRestore();
        }
    });
});
