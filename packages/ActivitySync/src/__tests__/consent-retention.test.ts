import { describe, expect, it, vi } from 'vitest';
import type { IMetadataProvider, UserInfo } from '@memberjunction/core';

/**
 * REPRO F11: a Tagged connection keeps encrypted content of UNTAGGED (non-consented) mail.
 *
 * consent-stages.ts says untagged items are excluded "so the weekly count needs no content stored",
 * but persistRun captures for every `Excluded` detail whenever SkippedContentPolicy > None.
 */

const CONN = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';
const TYPE = '9a1f8c22-51de-4f0a-9e77-2b6d0a4c1f31';
const KEY = 'c0ffee00-0000-4000-8000-000000000001';

const saved: Array<Record<string, unknown>> = [];
let connectionRow: Record<string, unknown> = {};
let typeRow: Record<string, unknown> = {};

vi.mock('@memberjunction/core', () => ({
    RunView: class {
        public async RunView(params: { EntityName?: string }) {
            const name = params.EntityName ?? '';
            if (name === 'MJ_BizApps_Common: Activity Sync Connections') return { Success: true, Results: [connectionRow] };
            if (name === 'MJ_BizApps_Common: Activity Sync Provider Types') return { Success: true, Results: [typeRow] };
            return { Success: true, Results: [] };
        }
    },
    LogError: () => undefined,
}));

import { ActivitySyncEngine } from '../ActivitySyncEngine.js';
import { FixtureActivitySyncProvider } from '../providers/FixtureActivitySyncProvider.js';
import type { ActivityContentCipher } from '../content-capture.js';
import type { ConsentIntake, GatherResult, WithdrawResult } from '../consent-intake.js';
import type { IdentityResolver, IdentityResolution } from '../identity.js';
import type { ActivityWriter } from '../writer.js';
import type { NormalizedItem } from '../types.js';

/** Personal mail: no AIDP category, no reply headers, so no consent can be granted. */
const PERSONAL: NormalizedItem = {
    ExternalID: 'msg-personal',
    ExternalThreadID: null,
    TypeCode: 'Email',
    Subject: 'Doctor appointment results',
    Body: 'Private medical details.',
    StartedAt: new Date('2026-11-05T10:00:00Z'),
    EndedAt: null,
    Participants: [{ Address: 'friend@gmail.com', Name: null, Role: 'From', IdentityKind: 'Email' }],
    HasAttachments: false,
    Location: null,
    Direction: 'Inbound',
    Cancelled: false,
    Raw: { categories: [] },
};

function recordingEntity(sink: Array<Record<string, unknown>>) {
    const row: Record<string, unknown> = {};
    return new Proxy(row, {
        get(target, prop: string) {
            if (prop === 'NewRecord') return () => undefined;
            if (prop === 'Load') return async () => true;
            if (prop === 'Save') return async () => { sink.push({ ...target }); return true; };
            if (prop === 'LatestResult') return {};
            if (prop === 'ID') return 'row-1';
            return target[prop];
        },
        set(target, prop: string, value) { target[prop] = value; return true; },
    });
}

const cipherCalls: string[] = [];
const SPY_CIPHER: ActivityContentCipher = {
    Encrypt: async (plaintext: string, keyID: string) => { cipherCalls.push(plaintext); return `enc(${keyID}):${plaintext}`; },
};

async function runTagged(policy: { connection: string | null; type: string | null }) {
    saved.length = 0;
    cipherCalls.length = 0;
    connectionRow = {
        ID: CONN, Status: 'Active', Provider: 'Microsoft365', Mailbox: 'rep@tenant.test',
        StartAt: null, EndAt: null, LastSyncAt: null, ActivitySyncProviderTypeID: TYPE,
        SkippedContentPolicy: policy.connection, EncryptionKeyID: KEY,
        Settings: '{"Consent":{"Mode":"Tagged","Tag":"AIDP"}}',
    };
    typeRow = {
        ID: TYPE, Code: 'Microsoft365', DriverClass: 'Microsoft365', DefaultQualificationPolicy: 'Exclude',
        CalendarDriverClass: null, IsActive: true, DefaultSkippedContentPolicy: policy.type, DefaultEncryptionKeyID: null,
    };
    const resolution: IdentityResolution = {
        LookupFailed: false, Resolved: [], Unresolved: [{ Kind: 'Email', Value: 'friend@gmail.com', Role: 'From' }], Known: new Map(),
    };
    const resolver = { Resolve: async () => resolution } as unknown as IdentityResolver;
    const writer = { Write: async () => { throw new Error('nothing should be written'); } } as unknown as ActivityWriter;
    const intake = {
        Gather: async (_p: unknown, _q: unknown, items: readonly NormalizedItem[]): Promise<GatherResult> =>
            ({ Items: [...items], Prior: new Map(), Issues: [], SweptThrough: null }),
        Withdraw: async (): Promise<WithdrawResult> => ({ Withdrawn: 0, Unknown: 0, Issues: [], Revoked: [] }),
    } as unknown as ConsentIntake;
    const provider = { Entities: [], GetEntityObject: async () => recordingEntity(saved) } as unknown as IMetadataProvider;

    const engine = new ActivitySyncEngine(resolver, writer, undefined, null, SPY_CIPHER, intake);
    const result = await engine.Run(
        CONN, { DryRun: false, TriggerType: 'Manual', Limit: 10 }, provider, { ID: 'user-1' } as UserInfo,
        new FixtureActivitySyncProvider([PERSONAL], 'Message'),
    );
    return { result, detail: saved.find((r) => 'Decision' in r) };
}

describe('F11: a Tagged connection never retains content of items excluded for lack of consent', () => {
    it.each([
        ['connection SubjectEncrypted', { connection: 'SubjectEncrypted', type: null }],
        ['connection FullEncrypted', { connection: 'FullEncrypted', type: null }],
        ['provider-type default FullEncrypted', { connection: null, type: 'FullEncrypted' }],
    ])('F11: untagged personal mail stores no CapturedContent (%s)', async (_label, policy) => {
        const { result, detail } = await runTagged(policy);
        expect(result.Success, result.Issues.join(' | ')).toBe(true);
        expect(detail?.Decision).toBe('Excluded');
        expect(detail?.DecidedByStage).toBe('Consent');
        expect(cipherCalls, 'the cipher must never see non-consented content').toEqual([]);
        expect(detail?.CapturedContent).toBeUndefined();
        expect(detail?.EncryptionKeyID).toBeUndefined();
    });
});
