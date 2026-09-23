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
    HasAttachments: false,
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

    /**
     * WHAT LANDS ON THE ROW, which is the only version an operator ever reads.
     *
     * Three writes in this engine capped free text against NVARCHAR(MAX) columns, and the docblock on
     * `run.ErrorMessage` already called that an inherited habit. Two of them are reached from here.
     *
     * `healthErrorFromResults` stopped truncating in this change and a unit test pinned it — but
     * `stampConnectionHealth` sliced the same string back to 4000 on its way to `LastError`, so the fix
     * was real in one function and invisible everywhere else. Testing the pure function could not tell
     * those two states apart. This can, because it asserts the value the engine actually writes.
     *
     * The broadly-failing run is the case that matters for both: the text grows with the number of
     * failures, so the run that most needs its diagnosis read in full is the one that used to lose the
     * tail of it.
     */
    async function failingRun(providerIssues: string[], writerIssue: string) {
        // An item nobody recognises is EXCLUDED before the writer is reached, and an excluded item
        // does not fail a run — so this is the same known-participant resolution as the test above.
        const resolver = {
            Resolve: async (): Promise<IdentityResolution> => ({
                LookupFailed: false,
                Resolved: [{ Kind: 'Person', RecordID: 'person-1', Role: 'From' }],
                Unresolved: [],
                Known: new Map([
                    [
                        'alice@customer.com',
                        { Address: 'alice@customer.com', PersonID: 'person-1', OrganizationID: null },
                    ],
                ]),
            }),
        } as unknown as IdentityResolver;
        // The failed write is what makes the run unsuccessful AND what fills the detail's Reason; the
        // provider's issues are what make the connection-level diagnosis long.
        const writer = {
            Write: async () => ({
                Success: false,
                ActivityID: null,
                AlreadyPresent: false,
                Links: [],
                Activity: null,
                Issues: [writerIssue],
            }),
        } as unknown as ActivityWriter;

        const lastErrors: Array<string | null> = [];
        const reasons: Array<string | null> = [];
        const provider = {
            Entities: [],
            GetEntityObject: async (name: string) => ({
                NewRecord: () => undefined,
                Load: async () => true,
                Save: async () => true,
                LatestResult: {},
                set LastError(v: string | null) {
                    if (name === 'MJ_BizApps_Common: Activity Sync Connections') lastErrors.push(v);
                },
                get LastError() {
                    return null;
                },
                set Reason(v: string | null) {
                    if (name === 'MJ_BizApps_Common: Activity Sync Run Details') reasons.push(v);
                },
                get Reason() {
                    return null;
                },
            }),
        } as unknown as IMetadataProvider;

        const result = await new ActivitySyncEngine(resolver, writer).Run(
            CONN,
            { DryRun: false, TriggerType: 'Manual', Limit: 10 },
            provider,
            { ID: 'user-1' } as UserInfo,
            new FixtureActivitySyncProvider([ITEM], 'Message', providerIssues),
        );
        return { result, lastErrors, reasons };
    }

    it('writes the WHOLE diagnosis to LastError on a broadly failing run', async () => {
        const many = Array.from(
            { length: 60 },
            (_, i) => `surface issue ${i + 1}: the mailbox read returned nothing usable for this batch`,
        );
        const { result, lastErrors } = await failingRun(many, 'the activity could not be written');

        expect(result.Success, 'the run has to fail or nothing is stamped').toBe(false);
        expect(many.join(' | ').length, 'the fixture must clear the old cap or this proves nothing')
            .toBeGreaterThan(4000);
        const written = lastErrors[lastErrors.length - 1];
        expect(written?.length, 'LastError is NVARCHAR(MAX) and must not be truncated')
            .toBeGreaterThan(4000);
        expect(written, 'the tail is exactly what the cap used to eat').toContain('surface issue 60');
    });

    it('writes the WHOLE reason on a failed run detail, beside any captured content', async () => {
        // A `Failed` detail is the one this feature captures content for, so its Reason is the
        // explanation sitting next to that content. `Reason` is NVARCHAR(MAX); it was sliced at 500.
        const long = `the activity could not be written: ${'the target record was locked, '.repeat(30)}end`;
        const { result, reasons } = await failingRun([], long);

        expect(result.Failed, 'the item must reach the writer and fail there').toBe(1);
        expect(long.length, 'the fixture must clear the old cap or this proves nothing').toBeGreaterThan(500);
        expect(reasons, 'one detail row was written').toHaveLength(1);
        expect(reasons[0]?.length, 'Reason is NVARCHAR(MAX) and must not be truncated').toBe(long.length);
        expect(reasons[0], 'the tail is exactly what the cap used to eat').toContain('end');
    });
});
