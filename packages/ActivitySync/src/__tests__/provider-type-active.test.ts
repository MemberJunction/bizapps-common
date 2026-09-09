/**
 * A provider type switched off must actually stop syncing.
 *
 * THE DEFECT. `ActivitySyncProviderType.IsActive` existed, defaulted to 1, and had no reader anywhere:
 * not in the row type, not in `loadProviderType`'s `Fields` list, not in the run path. An administrator
 * deactivating a connector type changed nothing — every connection pointing at it kept fetching mail and
 * kept reporting success.
 *
 * WHY REFUSE RATHER THAN SKIP QUIETLY. A connection that stops syncing while still showing green is the
 * exact failure this subsystem exists to make impossible, so the refusal is an Issue on the result and
 * lands in the connection's health stamp. It follows the shape already set by "Connection X is not in
 * its Active window" a few lines above it.
 */
import { describe, expect, it, vi } from 'vitest';
import type { IMetadataProvider, UserInfo } from '@memberjunction/core';

const CONN = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';
const TYPE = '7b1d4f60-2a35-4c88-9d11-55e0c1a7b402';

// Hoisted so the mock factory can read it — `vi.mock` is lifted above the imports.
const state = vi.hoisted(() => ({ IsActive: true as boolean | undefined }));

vi.mock('@memberjunction/core', () => ({
    RunView: class {
        public async RunView(params: { EntityName?: string }) {
            switch (params.EntityName ?? '') {
                case 'MJ_BizApps_Common: Activity Sync Connections':
                    return {
                        Success: true,
                        Results: [{
                            ID: CONN,
                            Status: 'Active',
                            Provider: 'Microsoft365',
                            Mailbox: 'box@tenant.test',
                            CredentialsRef: null,
                            StartAt: null,
                            EndAt: null,
                            LastSyncAt: null,
                            ActivitySyncProviderTypeID: TYPE,
                            SkippedContentPolicy: null,
                            Settings: null,
                        }],
                    };
                case 'MJ_BizApps_Common: Activity Sync Provider Types':
                    return {
                        Success: true,
                        Results: [{
                            ID: TYPE,
                            Code: 'Microsoft365',
                            DriverClass: 'MSGraphActivitySyncProvider',
                            DefaultQualificationPolicy: 'Exclude',
                            CalendarDriverClass: null,
                            IsActive: state.IsActive,
                        }],
                    };
                default:
                    return { Success: true, Results: [] };
            }
        }
    },
    LogError: () => undefined,
}));

import { ActivitySyncEngine } from '../ActivitySyncEngine.js';
import { FixtureActivitySyncProvider } from '../providers/FixtureActivitySyncProvider.js';
import type { IdentityResolver } from '../identity.js';
import type { ActivityWriter } from '../writer.js';
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

async function run(isActive: boolean | undefined) {
    state.IsActive = isActive;

    const resolver = {
        Resolve: async () => ({ LookupFailed: false, Resolved: [], Unresolved: [], Known: new Map() }),
    } as unknown as IdentityResolver;

    const writes: unknown[] = [];
    const writer = {
        Write: async (input: unknown) => {
            writes.push(input);
            return { Success: true, ActivityID: 'act-1', AlreadyPresent: false, Links: [], Activity: { ID: 'act-1' }, Issues: [] };
        },
    } as unknown as ActivityWriter;

    const provider = {
        Entities: [],
        GetEntityObject: async () => ({ NewRecord: () => undefined, Load: async () => true, Save: async () => true, LatestResult: {} }),
    } as unknown as IMetadataProvider;

    // A source is injected deliberately: the refusal must not be reachable only through a failure to
    // resolve a driver. It is a decision about configuration, taken before any provider is chosen.
    const source = new FixtureActivitySyncProvider([ITEM], 'Message');
    const result = await new ActivitySyncEngine(resolver, writer).Run(
        CONN,
        { DryRun: false, TriggerType: 'Manual', Limit: 10 },
        provider,
        { ID: 'user-1' } as UserInfo,
        source,
    );
    return { result, source, writes };
}

describe('ActivitySyncProviderType.IsActive', () => {
    it('refuses the run, naming the type, when the type is switched off', async () => {
        const { result } = await run(false);
        expect(result.Success).toBe(false);
        expect(result.Issues).toContain("Provider type 'Microsoft365' is not active.");
    });

    /** Refusing is worth nothing if the mailbox was already read by the time it happened. */
    it('refuses before fetching anything and writes nothing', async () => {
        const { result, source, writes } = await run(false);
        expect(source.Calls).toHaveLength(0);
        expect(result.Fetched).toBe(0);
        expect(writes).toHaveLength(0);
    });

    it('runs normally when the type is active', async () => {
        const { result, source } = await run(true);
        expect(result.Issues).not.toContain("Provider type 'Microsoft365' is not active.");
        expect(source.Calls).toHaveLength(1);
        expect(result.Fetched).toBe(1);
    });

    /**
     * A row that does not carry the field keeps running. The alternative — treating absence as "off" —
     * turns one trimmed `Fields` list into a silent, total halt of every sync, which is a far worse
     * failure than the one being guarded against.
     */
    it('keeps running when the row carries no IsActive at all', async () => {
        const { result, source } = await run(undefined);
        expect(result.Issues).not.toContain("Provider type 'Microsoft365' is not active.");
        expect(source.Calls).toHaveLength(1);
    });
});
