import { beforeEach, describe, expect, it, vi } from 'vitest';

const H = vi.hoisted(() => {
    const release = vi.fn(async () => undefined);
    const runView = vi.fn();
    const config = vi.fn(async () => undefined);
    const decrypt = vi.fn(async () => 'decrypted body text');

    const own = {
        ReleaseIndependentInstance: release,
    };
    const shared = {
        CreateIndependentInstance: vi.fn(async () => own),
    };

    return {
        release,
        runView,
        config,
        decrypt,
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

vi.mock('@memberjunction/encryption', () => ({
    EncryptionEngine: {
        Instance: {
            Config: H.config,
            Decrypt: H.decrypt,
        },
    },
}));

vi.mock('@memberjunction/actions', () => ({ BaseAction: class {} }));

import type { ActionParam, ActionResultSimple, RunActionParams } from '@memberjunction/actions-base';
import { ReadSkippedContentAction } from '../custom/read-skipped-content.action';

const DETAIL_ID = '22222222-3333-4444-5555-666666666666';

class TestableAction extends ReadSkippedContentAction {
    public Run(params: RunActionParams): Promise<ActionResultSimple> {
        return this.InternalRunAction(params);
    }
}

function makeParams(
    values: Record<string, unknown>,
    contextUser: unknown = { ID: 'u-owner', Type: 'Owner' },
): RunActionParams {
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

describe('ReadSkippedContentAction', () => {
    beforeEach(() => {
        vi.clearAllMocks();
        H.provider = H.shared;
    });

    it('declares AuthorizesCaller = true', () => {
        expect(ReadSkippedContentAction.AuthorizesCaller).toBe(true);
    });

    it('rejects missing ContextUser with VALIDATION_ERROR', async () => {
        const res = await new TestableAction().Run(makeParams({ RunDetailID: DETAIL_ID }, null));
        expect(res.Success).toBe(false);
        expect(res.ResultCode).toBe('VALIDATION_ERROR');
    });

    it('rejects non-Owner / non-Developer callers with PERMISSION_DENIED', async () => {
        const res = await new TestableAction().Run(
            makeParams(
                { RunDetailID: DETAIL_ID },
                {
                    ID: 'u-ui',
                    Type: 'User',
                    UserRoles: [
                        { RoleID: 'E0AFCCEC-6A37-EF11-86D4-000D3A4E707E', Role: 'UI' },
                        { RoleID: 'DFAFCCEC-6A37-EF11-86D4-000D3A4E707E', Role: 'Integration' },
                    ],
                },
            ),
        );
        expect(res.Success).toBe(false);
        expect(res.ResultCode).toBe('PERMISSION_DENIED');
        expect(H.shared.CreateIndependentInstance).not.toHaveBeenCalled();
    });

    it('rejects invalid RunDetailID with VALIDATION_ERROR', async () => {
        const res = await new TestableAction().Run(makeParams({ RunDetailID: 'not-a-uuid' }));
        expect(res.Success).toBe(false);
        expect(res.ResultCode).toBe('VALIDATION_ERROR');
    });

    it('returns NOT_FOUND when the RunDetail row does not exist', async () => {
        H.runView.mockResolvedValueOnce({ Success: true, Results: [] });
        const res = await new TestableAction().Run(makeParams({ RunDetailID: DETAIL_ID }));
        expect(res.Success).toBe(false);
        expect(res.ResultCode).toBe('NOT_FOUND');
        expect(H.release).toHaveBeenCalledTimes(1);
    });

    it('decrypts CapturedContent for an Owner caller and populates output params', async () => {
        H.runView.mockResolvedValueOnce({
            Success: true,
            Results: [
                {
                    ID: DETAIL_ID,
                    CapturedContent: '$ENC$key$AES-256-GCM$iv$ct$tag',
                    SubjectPreview: 'Quarterly review',
                },
            ],
        });

        const params = makeParams({ RunDetailID: DETAIL_ID, Reason: 'Rule debugging' });
        const res = await new TestableAction().Run(params);

        expect(res.Success).toBe(true);
        expect(res.ResultCode).toBe('SUCCESS');
        expect(H.config).toHaveBeenCalledTimes(1);
        expect(H.decrypt).toHaveBeenCalledWith(
            '$ENC$key$AES-256-GCM$iv$ct$tag',
            expect.objectContaining({ ID: 'u-owner' }),
        );
        expect(outputOf(params, 'Plaintext')).toBe('decrypted body text');
        expect(outputOf(params, 'RunDetailID')).toBe(DETAIL_ID);
        expect(outputOf(params, 'SubjectPreview')).toBe('Quarterly review');
        expect(H.release).toHaveBeenCalledTimes(1);
    });

    it('allows a Developer-role caller and returns null Plaintext when CapturedContent is null', async () => {
        H.runView.mockResolvedValueOnce({
            Success: true,
            Results: [{ ID: DETAIL_ID, CapturedContent: null, SubjectPreview: null }],
        });

        const params = makeParams(
            { RunDetailID: DETAIL_ID },
            {
                ID: 'u-dev',
                Type: 'User',
                UserRoles: [{ RoleID: 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E', Role: 'Developer' }],
            },
        );
        const res = await new TestableAction().Run(params);

        expect(res.Success).toBe(true);
        expect(H.decrypt).not.toHaveBeenCalled();
        expect(outputOf(params, 'Plaintext')).toBeNull();
        expect(outputOf(params, 'RunDetailID')).toBe(DETAIL_ID);
        expect(H.release).toHaveBeenCalledTimes(1);
    });
});
