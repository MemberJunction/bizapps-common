import { beforeEach, describe, expect, it, vi } from 'vitest';

// The process-global provider and the independent instance SyncActivities must run on instead (#200).
const H = vi.hoisted(() => {
    const own = {
        BeginEntityTransaction: vi.fn(async () => ({ Commit: async () => undefined, Rollback: async () => undefined })),
        ReleaseIndependentInstance: vi.fn(async () => undefined),
    };
    const shared = {
        BeginEntityTransaction: vi.fn(async () => ({ Commit: async () => undefined, Rollback: async () => undefined })),
        CreateIndependentInstance: vi.fn(async () => own),
    };
    return { own, shared, provider: shared as object };
});

vi.mock('@memberjunction/core', async (importOriginal) => ({
    ...(await importOriginal<object>()),
    Metadata: {
        get Provider() {
            return H.provider;
        },
    },
}));

vi.mock('@memberjunction/actions', () => ({ BaseAction: class {} }));

import type { IMetadataProvider } from '@memberjunction/core';
import type { ActionResultSimple, RunActionParams } from '@memberjunction/actions-base';
import { ActivitySyncEngine, IsDatabaseProvider, type FleetRunResult } from '@mj-biz-apps/common-activity-sync';
import { ReadConnectionIDs, ReadDryRun, SyncActivitiesAction } from '../custom/sync-activities.action';

class TestableAction extends SyncActivitiesAction {
    public Run(params: RunActionParams): Promise<ActionResultSimple> {
        return this.InternalRunAction(params);
    }
}

function params(
    userOverrides: Record<string, unknown> = { Type: 'Owner' },
    inputs: Array<{ Name: string; Value: unknown }> = [],
): RunActionParams {
    return {
        Params: inputs,
        ContextUser: { ID: 'user-1', ...userOverrides },
    } as unknown as RunActionParams;
}

function emptyFleet(): FleetRunResult {
    return { Success: true, ConnectionsAttempted: 0, Results: [], Issues: [] };
}

/** Stands in for the engine: opens a transaction on the provider it was handed, as the writer does per item. */
async function writeOnHandedProvider(_options: unknown, provider: IMetadataProvider): Promise<FleetRunResult> {
    if (IsDatabaseProvider(provider)) {
        await provider.BeginEntityTransaction();
    }
    return emptyFleet();
}

describe('SyncActivitiesAction', () => {
    beforeEach(() => {
        vi.restoreAllMocks();
        H.provider = H.shared;
        H.shared.CreateIndependentInstance.mockClear();
        H.shared.BeginEntityTransaction.mockClear();
        H.own.BeginEntityTransaction.mockClear();
        H.own.ReleaseIndependentInstance.mockClear();
    });

    it('runs on its own independent instance and releases it (never the process-global provider)', async () => {
        const run = vi.spyOn(ActivitySyncEngine.prototype, 'RunConnections').mockImplementation(writeOnHandedProvider);

        const result = await new TestableAction().Run(params());

        expect(result.Success).toBe(true);
        expect(H.shared.CreateIndependentInstance).toHaveBeenCalledTimes(1);
        expect(run.mock.calls[0][1]).toBe(H.own);
        expect(H.own.BeginEntityTransaction).toHaveBeenCalledTimes(1);
        expect(H.shared.BeginEntityTransaction).not.toHaveBeenCalled();
        expect(H.own.ReleaseIndependentInstance).toHaveBeenCalledTimes(1);
    });

    it('releases the independent instance when the run throws', async () => {
        vi.spyOn(ActivitySyncEngine.prototype, 'RunConnections').mockRejectedValue(new Error('pool exhausted'));

        const result = await new TestableAction().Run(params());

        expect(result.Success).toBe(false);
        expect(result.Message).toMatch(/pool exhausted/);
        expect(H.own.ReleaseIndependentInstance).toHaveBeenCalledTimes(1);
    });

    it('fails with a descriptive error when the global provider cannot open transactions', async () => {
        const run = vi.spyOn(ActivitySyncEngine.prototype, 'RunConnections');
        H.provider = {};

        const result = await new TestableAction().Run(params());

        expect(result.Success).toBe(false);
        expect(result.ResultCode).toBe('ERROR');
        expect(result.Message).toMatch(/server-only/);
        expect(run).not.toHaveBeenCalled();
    });

    it('declares AuthorizesCaller = true', () => {
        expect(SyncActivitiesAction.AuthorizesCaller).toBe(true);
    });

    it('rejects missing ContextUser with VALIDATION_ERROR', async () => {
        const run = vi.spyOn(ActivitySyncEngine.prototype, 'RunConnections');
        const result = await new TestableAction().Run({ Params: [], ContextUser: undefined } as unknown as RunActionParams);
        expect(result.Success).toBe(false);
        expect(result.ResultCode).toBe('VALIDATION_ERROR');
        expect(run).not.toHaveBeenCalled();
    });

    it('rejects a standard UI user with PERMISSION_DENIED', async () => {
        const run = vi.spyOn(ActivitySyncEngine.prototype, 'RunConnections');
        const result = await new TestableAction().Run(
            params({
                Type: 'User',
                UserRoles: [{ RoleID: 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', Role: 'UI' }],
            }),
        );
        expect(result.Success).toBe(false);
        expect(result.ResultCode).toBe('PERMISSION_DENIED');
        expect(run).not.toHaveBeenCalled();
    });

    it.each([
        ['Owner user', { Type: 'Owner', UserRoles: [] }],
        ['System user by ID', { ID: 'ecafccec-6a37-ef11-86d4-000d3a4e707e', Type: 'User', UserRoles: [] }],
        [
            'Developer role by RoleID',
            {
                Type: 'User',
                UserRoles: [{ RoleID: 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', Role: 'Custom' }],
            },
        ],
        [
            'Integration role by RoleID',
            {
                Type: 'User',
                UserRoles: [{ RoleID: 'dfafccec-6a37-ef11-86d4-000d3a4e707e', Role: 'Custom' }],
            },
        ],
        [
            'Developer role by Role name',
            {
                Type: 'User',
                UserRoles: [{ RoleID: '00000000-0000-0000-0000-000000000001', Role: 'Developer' }],
            },
        ],
        [
            'Integration role by Role name',
            {
                Type: 'User',
                UserRoles: [{ RoleID: '00000000-0000-0000-0000-000000000002', Role: 'Integration' }],
            },
        ],
    ])('authorizes %s', async (_label, userOverrides) => {
        vi.spyOn(ActivitySyncEngine.prototype, 'RunConnections').mockImplementation(writeOnHandedProvider);
        const result = await new TestableAction().Run(params(userOverrides));
        expect(result.Success).toBe(true);
    });

    it('runs live and Scheduled when no DryRun is passed, which is what the hourly job does', async () => {
        const run = vi.spyOn(ActivitySyncEngine.prototype, 'RunConnections').mockResolvedValue(emptyFleet());

        await new TestableAction().Run(params());

        expect(run.mock.calls[0][0]).toMatchObject({ DryRun: false, TriggerType: 'Scheduled', ConnectionIDs: [] });
    });

    it('passes a dry run and the named connections to the engine, and reports DryRun back', async () => {
        const run = vi.spyOn(ActivitySyncEngine.prototype, 'RunConnections').mockResolvedValue(emptyFleet());
        const p = params(undefined, [
            { Name: 'DryRun', Value: 'true' },
            { Name: 'ConnectionIDs', Value: ' id-1 , id-2 ,' },
        ]);

        await new TestableAction().Run(p);

        expect(run.mock.calls[0][0]).toMatchObject({
            DryRun: true,
            TriggerType: 'Manual',
            ConnectionIDs: ['id-1', 'id-2'],
        });
        expect(p.Params?.find((x) => x.Name === 'DryRun')?.Value).toBe(true);
    });
});

describe('reading the dry-run inputs', () => {
    it('treats only true, "true" and "1" as a dry run', () => {
        expect(ReadDryRun(true)).toBe(true);
        expect(ReadDryRun(' TRUE ')).toBe(true);
        expect(ReadDryRun('1')).toBe(true);
        for (const live of [undefined, null, '', 'false', '0', 'yes', false]) {
            expect(ReadDryRun(live)).toBe(false);
        }
    });

    it('accepts an array or a comma-separated string and drops blanks', () => {
        expect(ReadConnectionIDs(['a', ' b ', ''])).toEqual(['a', 'b']);
        expect(ReadConnectionIDs('a,,b')).toEqual(['a', 'b']);
        expect(ReadConnectionIDs(undefined)).toEqual([]);
    });
});
