import { describe, expect, it, vi } from 'vitest';

const capture = vi.hoisted(() => ({ filter: '' }));

vi.mock('@memberjunction/core', () => ({
    RunView: class {
        public async RunView(params: { ExtraFilter?: string }) {
            capture.filter = params.ExtraFilter ?? '';
            return { Success: true, Results: [] };
        }
    },
    LogError: () => undefined,
}));

import { IdentityResolver } from '../identity.js';
import type { UserInfo } from '@memberjunction/core';

describe('IdentityResolver', () => {
    it('matches by sargable Value IN, with literals already lowercased, narrowed to the kind', async () => {
        const resolver = new IdentityResolver();
        await resolver.Resolve(
            [{ Address: 'Alex@Customer.COM', Name: null, Role: 'From', IdentityKind: 'Email' }],
            { ID: 'user' } as UserInfo,
        );
        expect(capture.filter).toBe("(Value IN ('alex@customer.com') AND ContactType IN ('Email'))");
        expect(capture.filter).not.toMatch(/LOWER\s*\(\s*Value\s*\)/i);
    });

    it('narrows each IdentityKind to its own ContactType names, leaving ExternalUser unrestricted', async () => {
        const resolver = new IdentityResolver();
        await resolver.Resolve(
            [
                { Address: 'alex@customer.com', Name: null, Role: 'From', IdentityKind: 'Email' },
                { Address: '+15551234567', Name: null, Role: 'To', IdentityKind: 'Phone' },
                { Address: 'teams-user-9', Name: null, Role: 'To', IdentityKind: 'ExternalUser' },
            ],
            { ID: 'user' } as UserInfo,
        );
        expect(capture.filter).toBe(
            "(Value IN ('alex@customer.com') AND ContactType IN ('Email')) OR " +
                "(Value IN ('+15551234567') AND ContactType IN ('Mobile Phone','Work Phone','Home Phone','Fax')) OR " +
                "Value IN ('teams-user-9')",
        );
    });

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

    it('doubles quotes in an inbound address before it reaches ExtraFilter', async () => {
        const resolver = new IdentityResolver();
        await resolver.Resolve(
            [
                {
                    Address: "x@y.test' or '1'='1",
                    Name: null,
                    Role: 'From',
                    IdentityKind: 'Email',
                },
            ],
            { ID: 'user' } as UserInfo,
        );
        expect(capture.filter).toBe("(Value IN ('x@y.test'' or ''1''=''1') AND ContactType IN ('Email'))");
    });
});

