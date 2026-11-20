/**
 * The engine's half of standing consent: resolving `Settings.Consent.Sources`, asking them once per run,
 * and what happens when one is unknown, throws, or has something to report.
 *
 * The failures that matter: a mistyped source key that quietly leaves the connection tag-only (or worse,
 * reads the mailbox first), and a source whose read failed being taken for "this owner has no accounts".
 */
import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { IMetadataProvider, UserInfo } from '@memberjunction/core';
import { MJGlobal } from '@memberjunction/global';

const CONN = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';
const TYPE = '9a1f8c22-51de-4f0a-9e77-2b6d0a4c1f31';
const OWNER = '7c9e6679-7425-40de-944b-e07fc1f90ae7';

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
import { BaseActivityConsentSource, type StandingConsent, type StandingConsentRequest } from '../BaseActivityConsentSource.js';
import { PROP_MESSAGE_CLASS, type StandingDomains } from '../consent.js';
import type { ConsentIntake, GatherResult, WithdrawResult } from '../consent-intake.js';
import type { IdentityResolver, IdentityResolution } from '../identity.js';
import { FixtureActivitySyncProvider } from '../providers/FixtureActivitySyncProvider.js';
import type { NormalizedItem } from '../types.js';
import type { ActivityWriter } from '../writer.js';

const requests: StandingConsentRequest[] = [];
let answer: () => Promise<StandingConsent> = async () => ({ Domains: [], Issues: [] });

class TestSource extends BaseActivityConsentSource {
    public async StandingConsent(request: StandingConsentRequest): Promise<StandingConsent> {
        requests.push(request);
        return answer();
    }
}
MJGlobal.Instance.ClassFactory.Register(BaseActivityConsentSource, TestSource, 'Test.Owned');

function mail(id: string, from: string, categories: string[] = []): NormalizedItem {
    return {
        ExternalID: id,
        ExternalThreadID: null,
        TypeCode: 'Email',
        Subject: 'Quote',
        Body: null,
        StartedAt: new Date('2026-11-05T10:00:00Z'),
        EndedAt: null,
        Participants: [
            { Address: from, Name: null, Role: 'From', IdentityKind: 'Email' },
            { Address: 'rep@tenant.test', Name: null, Role: 'To', IdentityKind: 'Email' },
        ],
        HasAttachments: false,
        Location: null,
        Direction: 'Inbound',
        Cancelled: false,
        Raw: { internetMessageId: id, categories, singleValueExtendedProperties: [{ id: PROP_MESSAGE_CLASS, value: 'IPM.Note' }] },
    };
}

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

async function run(consent: Record<string, unknown>, items: NormalizedItem[], connection: Record<string, unknown> = {}) {
    saved.length = 0;
    connectionRow = {
        ID: CONN, Status: 'Active', Provider: 'Microsoft365', Mailbox: 'rep@tenant.test', OwnerUserID: OWNER,
        StartAt: null, EndAt: null, LastSyncAt: null, ActivitySyncProviderTypeID: TYPE,
        SkippedContentPolicy: null, EncryptionKeyID: null, Settings: JSON.stringify({ Consent: consent }),
        ...connection,
    };
    typeRow = {
        ID: TYPE, Code: 'Microsoft365', DriverClass: 'Microsoft365', DefaultQualificationPolicy: 'Exclude',
        CalendarDriverClass: null, IsActive: true, DefaultSkippedContentPolicy: null, DefaultEncryptionKeyID: null,
    };
    const resolution: IdentityResolution = { LookupFailed: false, Resolved: [], Unresolved: [], Known: new Map() };
    const resolver = { Resolve: async () => resolution } as unknown as IdentityResolver;
    const written: string[] = [];
    const writer = {
        Write: async (input: { Item: NormalizedItem }) => { written.push(input.Item.ExternalID); return { Success: true, AlreadyPresent: false, ActivityID: 'act-1', Issues: [] }; },
    } as unknown as ActivityWriter;
    const withdrawStanding: StandingDomains[] = [];
    const intake = {
        Gather: async (_p: unknown, _q: unknown, batch: readonly NormalizedItem[]): Promise<GatherResult> =>
            ({ Items: [...batch], Prior: new Map(), Issues: [], SweptThrough: null }),
        Withdraw: async (...args: unknown[]): Promise<WithdrawResult> => {
            withdrawStanding.push(args[7] as StandingDomains);
            return { Withdrawn: 0, Unknown: 0, Issues: [], Revoked: [] };
        },
    } as unknown as ConsentIntake;
    const provider = { Entities: [], GetEntityObject: async () => recordingEntity(saved) } as unknown as IMetadataProvider;
    const plugin = new FixtureActivitySyncProvider(items, 'Message');
    const engine = new ActivitySyncEngine(resolver, writer, undefined, null, null, intake);
    const result = await engine.Run(CONN, { DryRun: false, TriggerType: 'Manual', Limit: 10 }, provider, { ID: 'user-1' } as UserInfo, plugin);
    const details = saved.filter((r) => 'Decision' in r);
    const runRow = saved.find((r) => 'Fetched' in r);
    return { result, written, details, runRow, plugin, withdrawStanding };
}

const SOURCES = { Mode: 'Tagged', Tag: 'AIDP', SkipTag: 'No AIDP', Sources: ['Test.Owned'] };

describe('ActivitySyncEngine: standing consent from a named source', () => {
    beforeEach(() => {
        requests.length = 0;
        answer = async () => ({ Domains: [{ Domain: 'acme.test', Label: 'Acme Corp' }], Issues: [] });
    });

    it('captures untagged mail on an owned-account domain, and the run detail says why', async () => {
        const { result, written, details } = await run(SOURCES, [mail('<m1@x>', 'buyer@acme.test'), mail('<m2@x>', 'office@school.test')]);
        expect(result.Success, result.Issues.join(' | ')).toBe(true);
        expect(written).toEqual(['<m1@x>']);
        expect(details.find((d) => d.ExternalID === '<m1@x>')).toMatchObject({ Decision: 'Included', DecidedByStage: 'Consent', Reason: 'Standing consent: acme.test (Acme Corp)' });
        expect(details.find((d) => d.ExternalID === '<m2@x>')).toMatchObject({ Decision: 'Excluded', DecidedByStage: 'Consent' });
    });

    it('asks the source once, for this connection and its owner, through the run\'s provider', async () => {
        await run(SOURCES, [mail('<m1@x>', 'buyer@acme.test')]);
        expect(requests).toHaveLength(1);
        expect(requests[0]).toMatchObject({ ConnectionID: CONN, OwnerUserID: OWNER, Mailbox: 'rep@tenant.test', ContextUser: { ID: 'user-1' } });
        expect(requests[0].Provider).toBeDefined();
    });

    it('hands the cleaned standing domains to withdrawal', async () => {
        const { withdrawStanding } = await run(SOURCES, []);
        expect([...withdrawStanding[0]]).toEqual([['acme.test', 'Acme Corp']]);
    });

    it('a connection with no Sources never resolves or asks a source, and decides as before', async () => {
        const { result, written } = await run({ Mode: 'Tagged', Tag: 'AIDP' }, [mail('<m1@x>', 'buyer@acme.test'), mail('<m2@x>', 'pat@other.test', ['AIDP'])]);
        expect(result.Success).toBe(true);
        expect(requests).toHaveLength(0);
        expect(written).toEqual(['<m2@x>']);
    });

    it('an unknown source key stops the run before the mailbox is read', async () => {
        const { result, plugin, runRow } = await run({ ...SOURCES, Sources: ['Sales.OwnedAcounts'] }, [mail('<m1@x>', 'buyer@acme.test')]);
        expect(result.Success).toBe(false);
        expect(result.Issues.join(' ')).toMatch(/Sales\.OwnedAcounts/);
        expect(plugin.Calls).toHaveLength(0);
        expect(runRow).toBeUndefined();
    });

    it('a source that throws fails the run: nothing is read, no tag is processed, the watermark stays', async () => {
        answer = async () => { throw new Error('Sales Accounts read failed: timeout'); };
        const { result, plugin, written, runRow } = await run(SOURCES, [mail('<m1@x>', 'pat@other.test', ['AIDP'])]);
        expect(result.Success).toBe(false);
        expect(result.WatermarkAdvancedTo).toBeNull();
        expect(result.Issues.join(' ')).toMatch(/Test\.Owned.*3f2504e0.*7c9e6679.*Sales Accounts read failed: timeout/);
        expect(plugin.Calls).toHaveLength(0);
        expect(written).toEqual([]);
        expect(runRow, 'the failed run is recorded').toBeDefined();
    });

    it('issues from a source are reported and the run continues: the tag still works', async () => {
        answer = async () => ({ Domains: [], Issues: ['user 7c9e is not linked to an employee'] });
        const { result, written } = await run(SOURCES, [mail('<m1@x>', 'buyer@acme.test'), mail('<m2@x>', 'pat@other.test', ['AIDP'])]);
        expect(result.Success, result.Issues.join(' | ')).toBe(true);
        expect(result.Issues.join(' ')).toMatch(/Test\.Owned.*not linked to an employee/);
        expect(written).toEqual(['<m2@x>']);
    });

    it('a free-mail domain and the mailbox\'s own domain are dropped and reported; neither grants', async () => {
        answer = async () => ({ Domains: [{ Domain: 'gmail.com', Label: 'Jo Sole Trader' }, { Domain: 'tenant.test', Label: 'Us' }], Issues: [] });
        const { result, written } = await run(SOURCES, [mail('<m1@x>', 'friend@gmail.com'), mail('<m2@x>', 'colleague@tenant.test')]);
        expect(result.Success).toBe(true);
        expect(written).toEqual([]);
        expect(result.Issues.join(' ')).toMatch(/gmail\.com.*free-mail/);
        expect(result.Issues.join(' ')).toMatch(/tenant\.test.*own domains/);
    });

    it('a connection with no owner cannot have standing consent: reported, tag-only', async () => {
        const { result, written } = await run(SOURCES, [mail('<m1@x>', 'buyer@acme.test'), mail('<m2@x>', 'pat@other.test', ['AIDP'])], { OwnerUserID: null });
        expect(result.Success).toBe(true);
        expect(requests).toHaveLength(0);
        expect(written).toEqual(['<m2@x>']);
        expect(result.Issues.join(' ')).toMatch(/no OwnerUserID/);
    });

    it('a skip-tagged item on an owned-account domain is never written', async () => {
        const { written, details } = await run(SOURCES, [mail('<m1@x>', 'buyer@acme.test', ['No AIDP'])]);
        expect(written).toEqual([]);
        expect(details[0]).toMatchObject({ Decision: 'Excluded', DecidedByStage: 'ConsentBlock' });
    });
});
