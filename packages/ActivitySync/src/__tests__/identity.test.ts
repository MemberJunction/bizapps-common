import { describe, expect, it, vi } from 'vitest';

vi.mock('@memberjunction/core', () => ({
    RunView: class {
        public async RunView() {
            return { Success: true, Results: [] };
        }
    },
    LogError: () => undefined,
}));

import { IdentityResolver } from '../identity.js';
import type { UserInfo } from '@memberjunction/core';

describe('IdentityResolver', () => {
    it('records an unmatched address as unresolved and never invents a Person', async () => {
        const resolver = new IdentityResolver();
        const result = await resolver.Resolve(
            [{ Address: 'stranger@nowhere.test', Name: null, Role: 'From', IdentityKind: 'Email' }],
            { ID: 'user' } as UserInfo,
        );
        expect(result.LookupFailed).toBe(false);
        expect(result.Resolved).toEqual([]);
        expect(result.Unresolved).toEqual([
            { Kind: 'Email', Value: 'stranger@nowhere.test', Role: 'From' },
        ]);
    });
});
