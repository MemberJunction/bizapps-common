/**
 * The two ends of the attachment gap, both of which must SAY something.
 *
 * `ActivitySyncRule.IncludeAttachments` used to have no reader: a rule asking for attachments got
 * none and reported nothing. The engine now reads it — but attachment transfer is still not built,
 * so there are two ways for a run to end up with no files, and a host can only act on the first:
 *
 *   no sink registered  -> the HOST can fix it, by registering one
 *   sink registered     -> the host has done everything right and Activity Sync still stores nothing
 *
 * The second is the more misleading of the two and was silent until now, which is the same shape as
 * the defects this work exists to remove. Both are pinned here because an issue nobody asserts on is
 * how the first one came to be missing.
 */
import { describe, expect, it, vi } from 'vitest';
import type { IMetadataProvider, UserInfo } from '@memberjunction/core';

const CONN = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';
const RULE_ID = '7c9e6679-7425-40de-944b-e07fc1f90ae7';

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
            if (name === 'MJ_BizApps_Common: Activity Sync Rules') {
                return {
                    Success: true,
                    Results: [
                        {
                            ID: '7c9e6679-7425-40de-944b-e07fc1f90ae7',
                            Sequence: 1,
                            IsEnabled: true,
                            Action: 'Include',
                            Direction: null,
                            DateFrom: null,
                            DateTo: null,
                            ParticipantScope: null,
                            ActivitySyncRuleSetID: null,
                            // The whole point of the fixture: this rule ASKS for attachments.
                            IncludeAttachments: true,
                            MaxAttachmentBytes: null,
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
import type { ActivityFileSink } from '../attachments.js';
import type { IdentityResolver, IdentityResolution } from '../identity.js';
import type { ActivityWriter, WriteActivityInput } from '../writer.js';
import type { NormalizedItem } from '../types.js';

/** `HasAttachments` matters: the policy does not pay for a list the source says is empty. */
const ITEM_WITH_ATTACHMENTS: NormalizedItem = {
    ExternalID: 'msg-with-files',
    ExternalThreadID: null,
    TypeCode: 'Email',
    Subject: 'Signed contract',
    Body: 'attached',
    StartedAt: new Date('2026-08-05T10:00:00Z'),
    EndedAt: null,
    Location: null,
    HasAttachments: true,
    Direction: 'Inbound',
    Participants: [{ Address: 'alice@customer.com', Name: 'Alice', Role: 'From', IdentityKind: 'Email' }],
    Cancelled: false,
    Raw: {},
};

function harness() {
    const known: IdentityResolution = {
        LookupFailed: false,
        Resolved: [{ Kind: 'Person', RecordID: 'person-1', Role: 'From' }],
        Unresolved: [],
        Known: new Map([
            ['alice@customer.com', { Address: 'alice@customer.com', PersonID: 'person-1', OrganizationID: null }],
        ]),
    };
    const resolver = { Resolve: async () => known } as unknown as IdentityResolver;
    const writer = {
        Write: async (_input: WriteActivityInput) => ({
            Success: true,
            ActivityID: 'act-1',
            AlreadyPresent: false,
            Links: [],
            Activity: { ID: 'act-1' },
            Issues: [],
        }),
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
    return { resolver, writer, provider };
}

async function runWith(sink?: ActivityFileSink) {
    const { resolver, writer, provider } = harness();
    const engine = new ActivitySyncEngine(resolver, writer, undefined, sink);
    return engine.Run(
        CONN,
        { DryRun: false, TriggerType: 'Manual', Limit: 10 },
        provider,
        { ID: 'user-1' } as UserInfo,
        new FixtureActivitySyncProvider([ITEM_WITH_ATTACHMENTS], 'Message'),
    );
}

describe('a rule that asks for attachments always reports what happened to them', () => {
    it('names the item and the fix when no sink is registered', async () => {
        const result = await runWith(undefined);

        const issue = result.Issues.find((i) => i.includes('msg-with-files'));
        expect(issue, `expected an attachment issue, got: ${JSON.stringify(result.Issues)}`).toBeDefined();
        expect(issue).toMatch(/no ActivityFile sink is registered/);
        // The fix belongs to the host here, so the message has to say both ways out.
        expect(issue).toMatch(/Register one at bootstrap/);
        expect(issue).toMatch(/IncludeAttachments off/);
    });

    it('says the gap is ours, not the configuration, when a sink IS registered', async () => {
        const store = vi.fn();
        const sink = { Store: store } as unknown as ActivityFileSink;

        const result = await runWith(sink);

        const issue = result.Issues.find((i) => i.includes('msg-with-files'));
        expect(issue, `expected an attachment issue, got: ${JSON.stringify(result.Issues)}`).toBeDefined();
        expect(issue).toMatch(/a sink is registered/);
        expect(issue).toMatch(/not implemented yet/);
        // Blaming the host for a gap in this package is the specific wrong answer here.
        expect(issue).not.toMatch(/no ActivityFile sink is registered/);
        expect(issue).toMatch(/gap in Activity Sync, not in the host configuration/);

        // And it must not pretend to have tried: Store has no caller yet, so claiming otherwise in
        // the message would be the same lie in the other direction.
        expect(store).not.toHaveBeenCalled();
    });

    it('stays quiet when the rule does not ask for attachments', async () => {
        const { resolver, writer, provider } = harness();
        const engine = new ActivitySyncEngine(resolver, writer);
        const result = await engine.Run(
            CONN,
            { DryRun: false, TriggerType: 'Manual', Limit: 10 },
            provider,
            { ID: 'user-1' } as UserInfo,
            // Same rule, but an item the source says carries nothing to fetch.
            new FixtureActivitySyncProvider([{ ...ITEM_WITH_ATTACHMENTS, HasAttachments: false }], 'Message'),
        );

        expect(result.Issues.filter((i) => /attachment/i.test(i))).toEqual([]);
    });
});
