import { describe, expect, it, vi } from 'vitest';
import type { IMetadataProvider, UserInfo } from '@memberjunction/core';

vi.mock('@memberjunction/core', () => ({
    RunView: class {
        public async RunView(params: { EntityName?: string }) {
            const name = params.EntityName ?? '';
            if (name === 'MJ_BizApps_Common: Activity Sync Connections') {
                return {
                    Success: true,
                    Results: [
                        {
                            ID: '3f2504e0-4f89-41d3-9a0c-0305e82c3301',
                            Status: 'Active',
                            Provider: 'Microsoft365',
                            Mailbox: 'box@tenant.test',
                            StartAt: null,
                            EndAt: null,
                            LastSyncAt: null,
                            ActivitySyncProviderTypeID: null,
                            SkippedContentPolicy: null,
                            Settings: null,
                        },
                    ],
                };
            }
            return { Success: true, Results: [] };
        }
    },
    LogError: () => undefined,
}));

import { ActivitySyncEngine } from '../ActivitySyncEngine.js';
import { FixtureActivitySyncProvider } from '../providers/FixtureActivitySyncProvider.js';
import type { IdentityResolver, IdentityResolution } from '../identity.js';
import type { ActivityWriter, WriteActivityInput } from '../writer.js';
import type { NormalizedItem } from '../types.js';

const ITEM: NormalizedItem = {
    ExternalID: 'msg-1',
    ExternalThreadID: null,
    TypeCode: 'Email',
    Subject: 'Q3 renewal',
    Body: 'body',
    StartedAt: new Date('2026-08-05T10:00:00Z'),
    EndedAt: null,
    Location: null,
    Direction: 'Inbound',
    Participants: [{ Address: 'alice@customer.com', Name: 'Alice', Role: 'From', IdentityKind: 'Email' }],
    Cancelled: false,
    Raw: {},
};

const CONN = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';

describe('ActivitySyncEngine.Run with a fixture source', () => {
    it('fetches the fixture item, qualifies it as known, and writes it', async () => {
        const writes: WriteActivityInput[] = [];
        const known: IdentityResolution = {
            LookupFailed: false,
            Resolved: [{ Kind: 'Person', RecordID: 'person-1', Role: 'From' }],
            Unresolved: [],
            Known: new Map([
                [
                    'alice@customer.com',
                    { Address: 'alice@customer.com', PersonID: 'person-1', OrganizationID: null },
                ],
            ]),
        };
        const resolver = { Resolve: async () => known } as unknown as IdentityResolver;
        const writer = {
            Write: async (input: WriteActivityInput) => {
                writes.push(input);
                return {
                    Success: true,
                    ActivityID: 'act-1',
                    AlreadyPresent: false,
                    Links: [],
                    Activity: { ID: 'act-1' },
                    Issues: [],
                };
            },
        } as unknown as ActivityWriter;

        const entity = () => ({
            NewRecord: () => undefined,
            Load: async () => true,
            Save: async () => true,
            LatestResult: {},
        });
        const provider = {
            Entities: [],
            GetEntityObject: async () => entity(),
        } as unknown as IMetadataProvider;

        const engine = new ActivitySyncEngine(resolver, writer);
        const source = new FixtureActivitySyncProvider([ITEM], 'Message');
        const result = await engine.Run(
            CONN,
            { DryRun: false, TriggerType: 'Manual', Limit: 10 },
            provider,
            { ID: 'user-1' } as UserInfo,
            source,
        );

        expect(result.Fetched).toBe(1);
        expect(result.Included).toBe(1);
        expect(result.Failed).toBe(0);
        expect(result.Success).toBe(true);
        expect(writes).toHaveLength(1);
        expect(writes[0].Item.ExternalID).toBe('msg-1');
        expect(writes[0].Resolved).toEqual([{ Kind: 'Person', RecordID: 'person-1', Role: 'From' }]);
        expect(source.Calls).toHaveLength(1);
        expect(source.Calls[0].Since).toBeNull();
    });
});
