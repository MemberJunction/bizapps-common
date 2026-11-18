import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { IMetadataProvider, UserInfo } from '@memberjunction/core';

// Every RunView the writer builds records the provider it was built on, and the lookups can be told
// to fail — so the tests can prove the writer's reads stay on the provider it was handed (#195) and
// that a failed read is reported as a failure, not as "nothing found".
const H = vi.hoisted(() => ({
    runViewProviders: [] as unknown[],
    failTypeLookup: false,
    failDedupeLookup: false,
    logError: vi.fn(),
}));

vi.mock('@memberjunction/core', () => ({
    RunView: class {
        public constructor(provider: unknown = null) {
            H.runViewProviders.push(provider);
        }
        public async RunView(params: { ExtraFilter?: string }) {
            if (params.ExtraFilter?.startsWith('Code =')) {
                return H.failTypeLookup
                    ? { Success: false, ErrorMessage: 'connection reset', Results: [] }
                    : { Success: true, Results: [{ ID: 'type-1' }] };
            }
            if (H.failDedupeLookup) {
                return { Success: false, ErrorMessage: 'deadlock victim', Results: [] };
            }
            return { Success: true, Results: [] };
        }
    },
    LogError: H.logError,
}));

import { ActivityWriter, IsDatabaseProvider, type WriteManualActivityInput } from '../writer.js';

const USER = { ID: 'user-1' } as UserInfo;

function input(overrides: Partial<WriteManualActivityInput> = {}): WriteManualActivityInput {
    return {
        TypeCode: 'SystemEvent',
        Title: 'Person created',
        StartedAt: new Date('2026-08-30T10:00:00Z'),
        Links: [],
        ...overrides,
    };
}

function fakeProvider(options: { rollbackThrows?: boolean; saveFails?: boolean } = {}) {
    const state = { rolledBack: false, saved: 0 };
    const provider = {
        Entities: [],
        BeginEntityTransaction: async () => ({
            Commit: async () => undefined,
            Rollback: async () => {
                state.rolledBack = true;
                if (options.rollbackThrows) throw new Error('rollback exploded');
            },
        }),
        GetEntityObject: async () => ({
            NewRecord: () => undefined,
            Save: async () => {
                if (options.saveFails) throw new Error('save exploded');
                state.saved++;
                return true;
            },
        }),
    } as unknown as IMetadataProvider;
    return { provider, state };
}

describe('ActivityWriter — provider discipline and read failures', () => {
    beforeEach(() => {
        H.runViewProviders.length = 0;
        H.failTypeLookup = false;
        H.failDedupeLookup = false;
        H.logError.mockClear();
    });

    it('runs its lookups on the provider it was handed, never the global one', async () => {
        const { provider } = fakeProvider();
        const result = await new ActivityWriter().WriteManual(
            input({ SourceSystem: 'EntityAction', ExternalID: 'k-1' }),
            provider,
            USER,
        );
        expect(result.Success).toBe(true);
        expect(H.runViewProviders).toHaveLength(2); // type lookup + dedupe lookup
        expect(H.runViewProviders.every((p) => p === provider)).toBe(true);
    });

    it('reports a failed type lookup as a failure, not as an unseeded type', async () => {
        H.failTypeLookup = true;
        const { provider, state } = fakeProvider();
        const result = await new ActivityWriter().WriteManual(input(), provider, USER);
        expect(result.Success).toBe(false);
        expect(result.Issues.join(' ')).toMatch(/SystemEvent/);
        expect(result.Issues.join(' ')).toMatch(/connection reset/);
        expect(result.Issues.join(' ')).not.toMatch(/is seeded/);
        expect(state.saved).toBe(0);
    });

    it('reports a failed dedupe lookup instead of writing a possible duplicate', async () => {
        H.failDedupeLookup = true;
        const { provider, state } = fakeProvider();
        const result = await new ActivityWriter().WriteManual(
            input({ SourceSystem: 'EntityAction', ExternalID: 'k-1' }),
            provider,
            USER,
        );
        expect(result.Success).toBe(false);
        expect(result.Issues.join(' ')).toMatch(/EntityAction/);
        expect(result.Issues.join(' ')).toMatch(/deadlock victim/);
        expect(state.saved).toBe(0);
    });

    it('logs a rollback that fails after a write error, instead of swallowing it', async () => {
        const { provider, state } = fakeProvider({ saveFails: true, rollbackThrows: true });
        const result = await new ActivityWriter().WriteManual(input(), provider, USER);
        expect(result.Success).toBe(false);
        expect(state.rolledBack).toBe(true);
        const messages = H.logError.mock.calls.map((call) => String(call[0]));
        expect(messages.some((m) => /rollback/i.test(m) && /rollback exploded/.test(m))).toBe(true);
    });
});

describe('IsDatabaseProvider', () => {
    it('accepts a provider that can open a transaction and rejects one that cannot', () => {
        expect(IsDatabaseProvider(fakeProvider().provider)).toBe(true);
        expect(IsDatabaseProvider({} as IMetadataProvider)).toBe(false);
    });
});
