import { describe, expect, it, vi } from 'vitest';
import type { IMetadataProvider, UserInfo } from '@memberjunction/core';

vi.mock('@memberjunction/core', () => ({
    RunView: class {
        public async RunView(params: { ExtraFilter?: string }) {
            if (params.ExtraFilter?.startsWith('Code =')) {
                return { Success: true, Results: [{ ID: 'type-1' }] };
            }
            return { Success: true, Results: [] };
        }
    },
    LogError: () => undefined,
}));

import { ActivityWriter } from '../writer.js';
import type { NormalizedItem } from '../types.js';

const ITEM: NormalizedItem = {
    ExternalID: 'msg-1',
    ExternalThreadID: null,
    TypeCode: 'Email',
    Subject: 'hello',
    Body: 'body',
    StartedAt: new Date('2026-08-05T10:00:00Z'),
    EndedAt: null,
    Location: null,
    Direction: 'Inbound',
    Participants: [],
    Cancelled: false,
    Raw: {},
};

describe('ActivityWriter', () => {
    it('refuses a provider that cannot open a transaction, without asserting it can', async () => {
        const writer = new ActivityWriter();
        const provider = {
            GetEntityObject: async () => {
                throw new Error('should not write');
            },
        } as IMetadataProvider;
        const result = await writer.Write(
            {
                Item: ITEM,
                ConnectionID: '3f2504e0-4f89-41d3-9a0c-0305e82c3301',
                SourceSystem: 'Microsoft365',
                Source: 'Integration',
                Resolved: [],
                Unresolved: [],
            },
            provider,
            { ID: 'user' } as UserInfo,
        );
        expect(result.Success).toBe(false);
        expect(result.Issues[0]).toMatch(/cannot open a transaction/);
    });
});
