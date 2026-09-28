import { beforeEach, describe, expect, it, vi } from 'vitest';

// The process-global provider and the independent instance LogActivity must write on instead (#195).
const H = vi.hoisted(() => {
    const own = {
        BeginEntityTransaction: () => undefined,
        ReleaseIndependentInstance: vi.fn(async () => undefined),
    };
    const shared = {
        BeginEntityTransaction: () => undefined,
        CreateIndependentInstance: vi.fn(async () => own),
    };
    return { own, shared, provider: shared as object, logError: vi.fn() };
});

vi.mock('@memberjunction/core', async (importOriginal) => ({
    ...(await importOriginal<object>()),
    Metadata: {
        get Provider() {
            return H.provider;
        },
    },
    LogError: H.logError,
}));

vi.mock('@memberjunction/actions', () => ({ BaseAction: class {} }));

import type { ActionParam, ActionResultSimple, RunActionParams } from '@memberjunction/actions-base';
import { ActivityWriter, type WriteActivityResult } from '@mj-biz-apps/common-activity-sync';
import { LogActivityAction } from '../custom/log-activity.action';

const PERSON_ID = 'aaaaaaaa-1111-2222-3333-444444444444';

class TestableAction extends LogActivityAction {
    public Run(params: RunActionParams): Promise<ActionResultSimple> {
        return this.InternalRunAction(params);
    }
}

function paramsFor(values: Record<string, unknown>): RunActionParams {
    const Params = Object.entries(values).map(([Name, Value]) => ({ Name, Value, Type: 'Input' }) as ActionParam);
    return { Params, ContextUser: { ID: 'user-1' } } as unknown as RunActionParams;
}

const VALID = {
    TypeCode: 'SystemEvent',
    Title: 'Person created',
    EntityName: 'MJ_BizApps_Common: People',
    RecordID: PERSON_ID,
};

function written(): WriteActivityResult {
    return { Success: true, ActivityID: 'act-1', AlreadyPresent: false, Links: [], Issues: [] } as WriteActivityResult;
}

describe('LogActivityAction', () => {
    beforeEach(() => {
        vi.restoreAllMocks();
        H.provider = H.shared;
        H.shared.CreateIndependentInstance.mockClear();
        H.own.ReleaseIndependentInstance.mockClear();
        H.logError.mockClear();
    });

    it('writes on its own independent instance and releases it (never the process-global provider)', async () => {
        const write = vi.spyOn(ActivityWriter.prototype, 'WriteManual').mockResolvedValue(written());

        const result = await new TestableAction().Run(paramsFor(VALID));

        expect(result.Success).toBe(true);
        expect(H.shared.CreateIndependentInstance).toHaveBeenCalledTimes(1);
        expect(write.mock.calls[0][1]).toBe(H.own);
        expect(write.mock.calls[0][1]).not.toBe(H.shared);
        expect(H.own.ReleaseIndependentInstance).toHaveBeenCalledTimes(1);
    });

    it('releases the independent instance when the write throws, and logs with context', async () => {
        vi.spyOn(ActivityWriter.prototype, 'WriteManual').mockRejectedValue(new Error('pool exhausted'));

        const result = await new TestableAction().Run(paramsFor(VALID));

        expect(result.Success).toBe(false);
        expect(result.Message).toMatch(/pool exhausted/);
        expect(H.own.ReleaseIndependentInstance).toHaveBeenCalledTimes(1);
        const logged = String(H.logError.mock.calls[0]?.[0]);
        expect(logged).toMatch(/\[Common\.LogActivity\]/);
        expect(logged).toMatch(/pool exhausted/);
        expect(logged).toContain(PERSON_ID);
        expect(logged).toContain('user-1');
    });

    it('logs invalid input with context and never opens an instance', async () => {
        const result = await new TestableAction().Run(paramsFor({ EntityName: VALID.EntityName, RecordID: PERSON_ID }));

        expect(result.ResultCode).toBe('VALIDATION_ERROR');
        expect(H.shared.CreateIndependentInstance).not.toHaveBeenCalled();
        const logged = String(H.logError.mock.calls[0]?.[0]);
        expect(logged).toMatch(/TypeCode is required/);
        expect(logged).toContain(VALID.EntityName);
        expect(logged).toContain(PERSON_ID);
    });

    it('logs a write that reports issues', async () => {
        vi.spyOn(ActivityWriter.prototype, 'WriteManual').mockResolvedValue({
            ...written(),
            Success: false,
            ActivityID: undefined,
            Issues: ["No ActivityType with Code 'SystemEvent' is seeded."],
        } as WriteActivityResult);

        const result = await new TestableAction().Run(paramsFor(VALID));

        expect(result.Success).toBe(false);
        expect(String(H.logError.mock.calls[0]?.[0])).toMatch(/is seeded/);
    });

    it('fails with a descriptive error when the global provider cannot open transactions', async () => {
        H.provider = {};
        const result = await new TestableAction().Run(paramsFor(VALID));

        expect(result.Success).toBe(false);
        expect(result.Message).toMatch(/server-only/);
    });
});
