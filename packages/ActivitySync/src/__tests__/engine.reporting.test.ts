import { describe, expect, it, vi } from 'vitest';
import type { IMetadataProvider, UserInfo } from '@memberjunction/core';

/**
 * A run that SUCCEEDS still has things to say, and none of them were kept.
 *
 * `persistRun` wrote no issue text at all, the fleet collected issues only from surfaces that failed,
 * and `healthErrorFromResults` filters to `!r.Success`. So every deliberate report raised on a
 * completed run existed in an in-memory array and nowhere else: the attachment gap a rule asked for
 * and no sink could fill, the participant-scope warning, the capped-read notice, and the calendar's
 * first-run lookback bound. Each was written to be seen; none could be.
 *
 * That is the delivery mechanism for the whole "reports rather than failing silently" claim, so it is
 * pinned here at the row that records it.
 */

const CONN = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';

/** A report raised by a surface that completes successfully. */
const WARNING = 'attachment-gap: a rule asked for attachments and no sink is registered';

/** Every run row the engine saves, so the test can read what was persisted rather than inferred. */
const savedRuns: Array<Record<string, unknown>> = [];

vi.mock('@memberjunction/core', () => ({
    RunView: class {
        public async RunView(params: { EntityName?: string }) {
            const name = params.EntityName ?? '';
            if (name === 'MJ_BizApps_Common: Activity Sync Connections') {
                return {
                    Success: true,
                    Results: [
                        {
                            ID: CONN,
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
import { RegisterActivityFileSink, HostActivityFileSink, type ActivityFileSink } from '../attachments.js';
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
    Participants: [{ Address: 'alice@customer.com', Name: null, Role: 'From', IdentityKind: 'Email' }],
    HasAttachments: false,
    Location: null,
    Direction: 'Inbound',
    Cancelled: false,
    Raw: {},
};

/** Captures whatever the engine sets on the run row before saving it. */
function recordingEntity() {
    const row: Record<string, unknown> = {};
    return new Proxy(row, {
        get(target, prop: string) {
            if (prop === 'NewRecord') return () => undefined;
            if (prop === 'Load') return async () => true;
            if (prop === 'Save') {
                return async () => {
                    savedRuns.push({ ...target });
                    return true;
                };
            }
            if (prop === 'LatestResult') return {};
            if (prop === 'ID') return 'run-1';
            return target[prop];
        },
        set(target, prop: string, value) {
            target[prop] = value;
            return true;
        },
    });
}

async function runOnce() {
    savedRuns.length = 0;
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
    const provider = {
        Entities: [],
        GetEntityObject: async () => recordingEntity(),
    } as unknown as IMetadataProvider;

    const engine = new ActivitySyncEngine(resolver, writer);
    const result = await engine.Run(
        CONN,
        { DryRun: false, TriggerType: 'Manual', Limit: 10 },
        provider,
        { ID: 'user-1' } as UserInfo,
        // The third argument is the batch's Issues — a surface that SUCCEEDS while still having
        // something to report, which is the exact case that used to vanish.
        new FixtureActivitySyncProvider([ITEM], 'Message', [WARNING]),
    );
    return result;
}

describe('a successful run still records what it had to say', () => {
    it('writes its issues to the run row, not just to memory', async () => {
        const result = await runOnce();

        expect(result.Success, 'this run must succeed — that is the whole point').toBe(true);
        expect(result.Issues.length, 'and it must have something to report').toBeGreaterThan(0);

        const run = savedRuns.find((r) => 'Fetched' in r);
        expect(run, 'a run row must have been saved').toBeDefined();
        // THE ASSERTION THAT WAS MISSING. Before this, ErrorMessage was never set at all and every
        // issue on a completed run was discarded.
        expect(String(run?.ErrorMessage ?? '')).toContain('attachment-gap');
    });

    it('marks the run Completed even though it carries warnings', async () => {
        // Recording a warning must not make a healthy run look failed — `Status` keys on Failed, and
        // connection health keys on failure too. Only the free-text column changes.
        await runOnce();
        const run = savedRuns.find((r) => 'Fetched' in r);
        expect(run?.Status).toBe('Completed');
    });
});

describe('a host can actually supply a file sink', () => {
    /**
     * `ActivitySyncEngine`'s only production construction is `new ActivitySyncEngine()` inside an
     * Action, so the constructor parameter was unreachable: a host could implement the interface
     * exactly as documented and `Store()` would still have no caller. That is the same shape as the
     * defects this package was fixed for — a seam described, exported, and reachable only through a
     * door nothing opens.
     */
    it('defaults to the registered sink when none is passed', () => {
        const sink: ActivityFileSink = { Store: async () => ({ FileID: 'file-1' }) };
        RegisterActivityFileSink(sink);
        try {
            expect(HostActivityFileSink()).toBe(sink);
            const engine = new ActivitySyncEngine();
            expect((engine as unknown as { fileSink: ActivityFileSink | null }).fileSink).toBe(sink);
        } finally {
            RegisterActivityFileSink(null);
        }
    });

    it('lets a constructor argument win over the registration', () => {
        // Same rule the transport factory follows: tests and the demo supply their own, and a
        // process-wide registration must not reach in and replace it.
        const registered: ActivityFileSink = { Store: async () => ({ FileID: 'registered' }) };
        const injected: ActivityFileSink = { Store: async () => ({ FileID: 'injected' }) };
        RegisterActivityFileSink(registered);
        try {
            const engine = new ActivitySyncEngine(undefined, undefined, undefined, injected);
            expect((engine as unknown as { fileSink: ActivityFileSink | null }).fileSink).toBe(injected);
        } finally {
            RegisterActivityFileSink(null);
        }
    });

    it('is null on a host that registered none', () => {
        RegisterActivityFileSink(null);
        expect(HostActivityFileSink()).toBeNull();
        const engine = new ActivitySyncEngine();
        expect((engine as unknown as { fileSink: ActivityFileSink | null }).fileSink).toBeNull();
    });
});
