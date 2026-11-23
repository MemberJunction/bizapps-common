/**
 * Copyright (c) MemberJunction.com
 * SPDX-License-Identifier: BUSL-1.1
 */
import { describe, expect, it, vi } from 'vitest';
import {
    BaseEntity,
    BaseEntityResult,
    IMetadataProvider,
    LogError,
    ProviderBase,
    RunView,
    RunViewResult,
    UserInfo,
} from '@memberjunction/core';
import {
    COMPANY_ORG_SYNC_OP_KEY,
    SyncCompaniesToOrganizationsOperation,
} from '@mj-biz-apps/common-entities';
import {
    CompanyOrganizationMirrorEntityServer,
    MirrorCompanyToOrganization,
    SyncCompaniesToOrganizationsServerOperation,
} from '@mj-biz-apps/common-core-entities-server';

interface FakeOrgRecord {
    ID: string;
    Name: string;
    Website: string | null;
    LogoURL: string | null;
    Description: string | null;
    LinkedCompanyID: string | null;
    Status: string;
    LatestResult?: { CompleteMessage?: string };
    NewRecord: ReturnType<typeof vi.fn>;
    InnerLoad: ReturnType<typeof vi.fn>;
    Save: ReturnType<typeof vi.fn>;
}

function makeFakeOrg(initial?: Partial<FakeOrgRecord>): FakeOrgRecord {
    const rec: FakeOrgRecord = {
        ID: initial?.ID ?? '11111111-1111-4111-8111-111111111111',
        Name: initial?.Name ?? '',
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
    return rec;
}

function makeMockProvider(orgFactory: FakeOrgRecord | (() => FakeOrgRecord)): IMetadataProvider {
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

function makeMockRunView(runViewFn: (...args: never[]) => Promise<Partial<RunViewResult>>): RunView {
    const rv = Object.create(RunView.prototype) as RunView;
    Object.defineProperty(rv, 'RunView', { value: runViewFn, configurable: true });
    return rv;
}

describe('Company -> Organization mirroring & SyncCompaniesToOrganizationsOperation', () => {
    const companyID = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    const companyID2 = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
    const companyID3 = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
    const user = new UserInfo(undefined, {
        ID: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        Name: 'Tester',
        Email: 'test@example.com',
    });

    it('declares stable remotable operation key, authorized entity, and agent/MCP tool metadata', () => {
        const op = new SyncCompaniesToOrganizationsOperation();
        expect(op.OperationKey).toBe(COMPANY_ORG_SYNC_OP_KEY);
        expect(op.OperationKey).toBe('BizAppsCommon.SyncCompaniesToOrganizations');
        expect(op.AuthorizedWriteEntities).toEqual(['MJ_BizApps_Common: Organizations']);
        expect(op.ExposeAsAgentTool).toBe(true);
        expect(op.ExposeAsMCPTool).toBe(true);
        expect(op.ToolDescription).toContain('LinkedCompanyID');
    });

    it('creates a new mirrored Active Organization with normalized fields when none exists for CompanyID', async () => {
        const fakeOrg = makeFakeOrg();
        const provider = makeMockProvider(fakeOrg);
        const runViewSpy = vi.spyOn(RunView, 'FromMetadataProvider').mockReturnValue(
            makeMockRunView(vi.fn().mockResolvedValue({ Success: true, Results: [] })),
        );

        try {
            const res = await MirrorCompanyToOrganization(
                {
                    ID: companyID,
                    Name: '  Meridian US LLC  ',
                    Description: '  Primary US operating entity  ',
                    Website: '  https://meridian.example  ',
                    LogoURL: '   ',
                },
                provider,
                user,
            );

            expect(res.Action).toBe('created');
            expect(res.CompanyID).toBe(companyID);
            expect(res.OrganizationID).toBe(fakeOrg.ID);
            expect(res.CompanyName).toBe('Meridian US LLC');
            expect(fakeOrg.NewRecord).toHaveBeenCalledTimes(1);
            expect(fakeOrg.LinkedCompanyID).toBe(companyID);
            expect(fakeOrg.Name).toBe('Meridian US LLC');
            expect(fakeOrg.Description).toBe('Primary US operating entity');
            expect(fakeOrg.Website).toBe('https://meridian.example');
            expect(fakeOrg.LogoURL).toBeNull();
            expect(fakeOrg.Status).toBe('Active');
            expect(fakeOrg.Save).toHaveBeenCalledTimes(1);
        } finally {
            runViewSpy.mockRestore();
        }
    });

    it('updates an existing mirrored Organization only when mirrored fields drifted and skips no-op writes', async () => {
        const fakeOrg = makeFakeOrg({
            ID: '22222222-2222-4222-8222-222222222222',
            Name: 'Old Legal Name',
            Website: 'https://meridian.example',
            Description: 'Primary US operating entity',
            LogoURL: null,
            LinkedCompanyID: companyID,
        });
        const provider = makeMockProvider(fakeOrg);
        const runViewSpy = vi.spyOn(RunView, 'FromMetadataProvider').mockReturnValue(
            makeMockRunView(vi.fn().mockResolvedValue({ Success: true, Results: [{ ID: fakeOrg.ID }] })),
        );

        try {
            const res = await MirrorCompanyToOrganization(
                {
                    ID: companyID,
                    Name: 'Meridian US Holdings LLC',
                    Description: 'Primary US operating entity',
                    Website: 'https://meridian.example',
                    LogoURL: 'https://cdn.meridian.example/logo.png',
                },
                provider,
                user,
            );

            expect(res.Action).toBe('updated');
            expect(fakeOrg.Name).toBe('Meridian US Holdings LLC');
            expect(fakeOrg.LogoURL).toBe('https://cdn.meridian.example/logo.png');
            expect(fakeOrg.Save).toHaveBeenCalledTimes(1);

            // Second call with identical data (and trailing whitespace) is a no-op
            fakeOrg.Save.mockClear();
            const res2 = await MirrorCompanyToOrganization(
                {
                    ID: companyID,
                    Name: '  Meridian US Holdings LLC ',
                    Description: 'Primary US operating entity',
                    Website: 'https://meridian.example',
                    LogoURL: 'https://cdn.meridian.example/logo.png',
                },
                provider,
                user,
            );
            expect(res2.Action).toBe('unchanged');
            expect(fakeOrg.Save).not.toHaveBeenCalled();
        } finally {
            runViewSpy.mockRestore();
        }
    });

    it('rejects non-UUID Company IDs before building SQL filters', async () => {
        const provider = makeMockProvider(makeFakeOrg());
        await expect(
            MirrorCompanyToOrganization(
                {
                    ID: "not-a-uuid' OR 1=1 --",
                    Name: 'Injected',
                    Description: null,
                    Website: null,
                    LogoURL: null,
                },
                provider,
                user,
            ),
        ).rejects.toThrow(/Invalid Company ID/);
    });

    it('throws descriptive errors when RunView lookup, InnerLoad, or Save fails', async () => {
        const fakeOrg = makeFakeOrg({ LatestResult: { CompleteMessage: 'unique index violation' } });
        const provider = makeMockProvider(fakeOrg);

        // 1. RunView failure
        let runViewSpy = vi.spyOn(RunView, 'FromMetadataProvider').mockReturnValue(
            makeMockRunView(vi.fn().mockResolvedValue({ Success: false, ErrorMessage: 'db offline' })),
        );
        try {
            await expect(
                MirrorCompanyToOrganization(
                    { ID: companyID, Name: 'Acme', Description: null, Website: null, LogoURL: null },
                    provider,
                    user,
                ),
            ).rejects.toThrow(/db offline/);
        } finally {
            runViewSpy.mockRestore();
        }

        // 2. InnerLoad failure on existing mirror
        fakeOrg.InnerLoad.mockResolvedValueOnce(false);
        runViewSpy = vi.spyOn(RunView, 'FromMetadataProvider').mockReturnValue(
            makeMockRunView(vi.fn().mockResolvedValue({ Success: true, Results: [{ ID: fakeOrg.ID }] })),
        );
        try {
            await expect(
                MirrorCompanyToOrganization(
                    { ID: companyID, Name: 'Acme', Description: null, Website: null, LogoURL: null },
                    provider,
                    user,
                ),
            ).rejects.toThrow(/Could not load mirrored Organization/);
        } finally {
            runViewSpy.mockRestore();
        }

        // 3. Save failure on create
        fakeOrg.Save.mockResolvedValueOnce(false);
        runViewSpy = vi.spyOn(RunView, 'FromMetadataProvider').mockReturnValue(
            makeMockRunView(vi.fn().mockResolvedValue({ Success: true, Results: [] })),
        );
        try {
            await expect(
                MirrorCompanyToOrganization(
                    { ID: companyID, Name: 'Acme', Description: null, Website: null, LogoURL: null },
                    provider,
                    user,
                ),
            ).rejects.toThrow(/unique index violation/);
        } finally {
            runViewSpy.mockRestore();
        }
    });

    it('SyncCompaniesToOrganizationsServerOperation aggregates created, updated, and unchanged counts across multiple companies', async () => {
        const orgCreated = makeFakeOrg({ ID: '11111111-1111-4111-8111-111111111101' });
        const orgUpdated = makeFakeOrg({
            ID: '11111111-1111-4111-8111-111111111102',
            Name: 'Old UK Ltd',
            Description: 'UK subsidiary',
            Website: 'https://meridian-uk.example',
            LinkedCompanyID: companyID2,
        });
        const orgUnchanged = makeFakeOrg({
            ID: '11111111-1111-4111-8111-111111111103',
            Name: 'Meridian CA Inc',
            Description: 'Canada entity',
            Website: null,
            LinkedCompanyID: companyID3,
        });

        const queue = [orgCreated, orgUpdated, orgUnchanged];
        const provider = makeMockProvider(() => queue.shift()!);

        const runViewMock = vi
            .fn()
            // 1. Load MJ: Companies
            .mockResolvedValueOnce({
                Success: true,
                Results: [
                    { ID: companyID, Name: 'Meridian US LLC', Description: 'US', Website: 'https://us.meridian.example', LogoURL: null },
                    { ID: companyID2, Name: 'Meridian UK Ltd', Description: 'UK subsidiary', Website: 'https://meridian-uk.example', LogoURL: null },
                    { ID: companyID3, Name: 'Meridian CA Inc', Description: 'Canada entity', Website: null, LogoURL: null },
                ],
            })
            // 2. Lookup for company 1 -> none (create)
            .mockResolvedValueOnce({ Success: true, Results: [] })
            // 3. Lookup for company 2 -> exists with stale Name (update)
            .mockResolvedValueOnce({ Success: true, Results: [{ ID: orgUpdated.ID }] })
            // 4. Lookup for company 3 -> exists identical (unchanged)
            .mockResolvedValueOnce({ Success: true, Results: [{ ID: orgUnchanged.ID }] });

        const runViewSpy = vi.spyOn(RunView, 'FromMetadataProvider').mockReturnValue(
            makeMockRunView(runViewMock),
        );

        try {
            const serverOp = new SyncCompaniesToOrganizationsServerOperation();
            const out = await serverOp.ExecuteServer({}, { provider, user, emitProgress: () => {} });

            expect(out.Success).toBe(true);
            expect(out.Output?.TotalCompanies).toBe(3);
            expect(out.Output?.CreatedCount).toBe(1);
            expect(out.Output?.UpdatedCount).toBe(1);
            expect(out.Output?.UnchangedCount).toBe(1);
            expect(out.Output?.Items.map((i) => i.Action)).toEqual(['created', 'updated', 'unchanged']);
            expect(orgCreated.Save).toHaveBeenCalledTimes(1);
            expect(orgUpdated.Save).toHaveBeenCalledTimes(1);
            expect(orgUnchanged.Save).not.toHaveBeenCalled();
        } finally {
            runViewSpy.mockRestore();
        }
    });

    it('SyncCompaniesToOrganizationsServerOperation filters by CompanyID when provided and rejects invalid UUIDs', async () => {
        const fakeOrg = makeFakeOrg();
        const provider = makeMockProvider(fakeOrg);
        const runViewMock = vi
            .fn()
            .mockResolvedValueOnce({
                Success: true,
                Results: [{ ID: companyID, Name: 'Scoped Co', Description: null, Website: null, LogoURL: null }],
            })
            .mockResolvedValueOnce({ Success: true, Results: [] });

        const runViewSpy = vi.spyOn(RunView, 'FromMetadataProvider').mockReturnValue(
            makeMockRunView(runViewMock),
        );

        try {
            const serverOp = new SyncCompaniesToOrganizationsServerOperation();
            const scoped = await serverOp.ExecuteServer(
                { CompanyID: companyID },
                { provider, user, emitProgress: () => {} },
            );
            expect(scoped.Success).toBe(true);
            expect(scoped.Output?.TotalCompanies).toBe(1);
            expect(runViewMock.mock.calls[0][0].ExtraFilter).toBe(`ID = '${companyID}'`);

            // Invalid UUID fails cleanly
            const bad = await serverOp.ExecuteServer(
                { CompanyID: "bad'uuid" },
                { provider, user, emitProgress: () => {} },
            );
            expect(bad.Success).toBe(false);
            expect(bad.ErrorMessage).toContain('Invalid CompanyID');
        } finally {
            runViewSpy.mockRestore();
        }
    });

    it('SyncCompaniesToOrganizationsServerOperation succeeds with zeros when MJ: Companies is empty', async () => {
        const provider = makeMockProvider(makeFakeOrg());
        const runViewSpy = vi.spyOn(RunView, 'FromMetadataProvider').mockReturnValue(
            makeMockRunView(vi.fn().mockResolvedValue({ Success: true, Results: [] })),
        );

        try {
            const serverOp = new SyncCompaniesToOrganizationsServerOperation();
            const out = await serverOp.ExecuteServer({}, { provider, user, emitProgress: () => {} });
            expect(out.Success).toBe(true);
            expect(out.Output).toEqual({
                TotalCompanies: 0,
                CreatedCount: 0,
                UpdatedCount: 0,
                UnchangedCount: 0,
                Items: [],
            });
        } finally {
            runViewSpy.mockRestore();
        }
    });

    it('CompanyOrganizationMirrorEntityServer.Save() skips mirroring if super.Save() fails and surfaces structured mirror failure', async () => {
        const fakeOrg = makeFakeOrg();
        const provider = makeMockProvider(fakeOrg);
        const superSaveSpy = vi.spyOn(BaseEntity.prototype, 'Save');
        const runViewSpy = vi.spyOn(RunView, 'FromMetadataProvider');

        try {
            // Case 1: super.Save returns false -> mirror is never invoked
            superSaveSpy.mockResolvedValueOnce(false);
            const entity = Object.create(CompanyOrganizationMirrorEntityServer.prototype) as CompanyOrganizationMirrorEntityServer;
            Object.defineProperty(entity, '_resultHistory', { value: [] as BaseEntityResult[], writable: true, configurable: true });
            Object.defineProperty(entity, 'ProviderToUse', { value: provider, configurable: true });
            Object.defineProperty(entity, 'ContextCurrentUser', { value: user, configurable: true });
            Object.defineProperty(entity, 'ID', { value: companyID, configurable: true });
            Object.defineProperty(entity, 'Name', { value: 'Failing Save Co', configurable: true });

            const r1 = await entity.Save();
            expect(r1).toBe(false);
            expect(runViewSpy).not.toHaveBeenCalled();

            // Case 2: super.Save returns true, mirror fails -> Company.Save returns false and records structured LastMirrorError + LatestResult
            superSaveSpy.mockResolvedValueOnce(true);
            runViewSpy.mockReturnValue(
                makeMockRunView(vi.fn().mockResolvedValue({ Success: false, ErrorMessage: 'transient mirror error' })),
            );
            Object.defineProperty(entity, 'Description', { value: null, configurable: true });
            Object.defineProperty(entity, 'Website', { value: null, configurable: true });
            Object.defineProperty(entity, 'LogoURL', { value: null, configurable: true });

            const r2 = await entity.Save();
            expect(r2).toBe(false);
            expect(entity.LastMirrorError?.Code).toBe('ORGANIZATION_LOOKUP_FAILED');
            expect(entity.LastMirrorError?.DiagnosticMessage).toContain('transient mirror error');
            expect(entity.LatestResult?.Success).toBe(false);
            expect(typeof LogError).toBe('function');
        } finally {
            superSaveSpy.mockRestore();
            runViewSpy.mockRestore();
        }
    });
});
