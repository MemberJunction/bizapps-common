/**
 * The Graph transport seam — what reaches the network, and what happens when it cannot.
 *
 * WHY THIS FILE MATTERS MORE THAN ITS SIZE SUGGESTS. `MSGraphActivitySyncProvider` used to return
 * `Payloads: []` from both of its branches. Every test passed, and the fact that no credential was
 * configured anywhere went unnoticed for weeks, because nothing exercised the path that needs one.
 * These tests are written so that a return to that state FAILS: several of them assert that the
 * provider throws or refuses, which an implementation returning a cheerful empty batch cannot do.
 *
 * The distinction being defended throughout is between "looked, found nothing" — an empty batch,
 * a successful sync — and "could not look", which must surface as a failure and preserve the
 * watermark. Collapsing those two is the recurring defect this package keeps designing against.
 */
import { afterEach, describe, expect, it, vi } from 'vitest';

import {
    GraphCommunicationTransport,
    GRAPH_COMMUNICATION_PROVIDER,
    GRAPH_CREDENTIAL_TYPE,
    MJGraphTransportDeps,
    type GraphMessageReader,
    type GraphServicePrincipal,
} from '../providers/GraphCommunicationTransport.js';
import {
    HostActivityTransportFactory,
    RegisterActivityTransportFactory,
} from '../providers/MessageTransport.js';
import { RecordedMessageTransport } from '../providers/RecordedMessageTransport.js';
import {
    LIVE_GRAPH_REFUSAL,
    MSGraphActivitySyncProvider,
    NO_CREDENTIAL_REF_REFUSAL,
    NO_TRANSPORT_REFUSAL,
} from '../providers/MSGraphActivitySyncProvider.js';
import type { UserInfo } from '@memberjunction/core';

import type { ActivitySourceQuery } from '../types.js';

const CREDENTIAL: GraphServicePrincipal = {
    tenantId: 'tenant-1',
    clientId: 'client-1',
    clientSecret: 'secret-1',
};

const QUERY: ActivitySourceQuery = { Mailbox: 'rep@example.com', Since: null, Limit: 50 };

/** One real-shaped Graph message. Fields are the ones GraphMessageMapper actually reads. */
const GRAPH_MESSAGE = {
    id: 'AAMkAG',
    conversationId: 'conv-1',
    subject: 'Renewal terms',
    bodyPreview: 'As discussed',
    receivedDateTime: '2026-08-30T09:00:00Z',
    sentDateTime: '2026-08-30T09:00:00Z',
    from: { emailAddress: { name: 'Customer', address: 'buyer@customer.com' } },
    toRecipients: [{ emailAddress: { address: 'rep@example.com' } }],
};

function readerReturning(result: Record<string, unknown>): GraphMessageReader {
    return { GetMessages: vi.fn().mockResolvedValue(result) } as unknown as GraphMessageReader;
}

function liveTransport(reader: GraphMessageReader, credential: GraphServicePrincipal = CREDENTIAL) {
    return new GraphCommunicationTransport({
        ResolveCredential: async () => credential,
        ResolveProvider: async () => reader,
    });
}

describe('GraphCommunicationTransport — the live path', () => {
    it('asks MJ for the mailbox named in the query, bounded by the query limit', async () => {
        const reader = readerReturning({ Success: true, SourceData: [GRAPH_MESSAGE] });
        await liveTransport(reader).Fetch(QUERY);

        const [params, credentials] = (reader.GetMessages as ReturnType<typeof vi.fn>).mock.calls[0];
        expect(params.Identifier).toBe('rep@example.com');
        expect(params.NumMessages).toBe(50);
        // The credential is PASSED, never held. If this ever stops being forwarded, MJ silently
        // falls back to environment variables and reads whatever mailbox those point at.
        expect(credentials).toEqual({
            ...CREDENTIAL,
            accountEmail: 'rep@example.com',
            disableEnvironmentFallback: true,
        });
        // MJ's MSGraphProvider validates accountEmail alongside the three service-principal
        // fields before it makes any request. It must be the mailbox from the QUERY: dropping it
        // fails every live call on a host without AZURE_ACCOUNT_EMAIL, and any fixed value would
        // be wrong for every connection but one.
        expect(credentials.accountEmail).toBe(QUERY.Mailbox);
        // And the host's AZURE_* variables must never be able to fill a gap in the credential —
        // that is the difference between "fails on the missing field" and "reads someone else's
        // mailbox".
        expect(credentials.disableEnvironmentFallback).toBe(true);
    });

    it('returns Graph’s own payloads, not MJ’s normalized Messages', async () => {
        // GetMessages sets `To` from replyTo[0], which is right for replying and wrong for recording
        // who a message was addressed to. Taking Messages here would quietly corrupt participants.
        const reader = readerReturning({
            Success: true,
            SourceData: [GRAPH_MESSAGE],
            Messages: [{ From: 'x', To: 'wrong@example.com', Body: 'lossy' }],
        });
        const batch = await liveTransport(reader).Fetch(QUERY);
        expect(batch.Payloads).toEqual([GRAPH_MESSAGE]);
    });

    it('treats a missing SourceData as an empty batch rather than throwing', async () => {
        const batch = await liveTransport(readerReturning({ Success: true })).Fetch(QUERY);
        expect(batch.Payloads).toEqual([]);
        expect(batch.Issues).toEqual([]);
    });

    describe('failures surface as failures', () => {
        it('THROWS when Graph reports failure, rather than returning an empty batch', async () => {
            // The distinction this package exists to preserve: an empty batch means "the mailbox had
            // nothing", which would clear LastError and advance the watermark past mail we never saw.
            const reader = readerReturning({ Success: false, ErrorMessage: 'Forbidden' });
            await expect(liveTransport(reader).Fetch(QUERY)).rejects.toThrow(/Forbidden/);
        });

        it('throws with the mailbox named when Graph gives no reason at all', async () => {
            const reader = readerReturning({ Success: false });
            await expect(liveTransport(reader).Fetch(QUERY)).rejects.toThrow(/rep@example\.com/);
        });

        it('refuses an incomplete credential and NAMES the missing fields', async () => {
            const reader = readerReturning({ Success: true, SourceData: [] });
            const partial = { tenantId: 'tenant-1', clientId: '', clientSecret: '   ' } as GraphServicePrincipal;
            await expect(liveTransport(reader, partial).Fetch(QUERY)).rejects.toThrow(/clientId, clientSecret/);
        });

        it('never puts a credential VALUE in the error it throws', async () => {
            const reader = readerReturning({ Success: true, SourceData: [] });
            const partial = { tenantId: 'tenant-1', clientId: '', clientSecret: '' } as GraphServicePrincipal;
            const error = await liveTransport(reader, partial)
                .Fetch(QUERY)
                .catch((e: Error) => e);
            expect((error as Error).message).toContain(GRAPH_CREDENTIAL_TYPE);
            expect((error as Error).message).not.toContain('tenant-1');
        });

        it('does not call Graph at all when the credential is incomplete', async () => {
            const reader = readerReturning({ Success: true, SourceData: [] });
            const partial = { tenantId: '', clientId: '', clientSecret: '' } as GraphServicePrincipal;
            await liveTransport(reader, partial).Fetch(QUERY).catch(() => undefined);
            expect(reader.GetMessages).not.toHaveBeenCalled();
        });
    });

    it('warns when a capped read may have left mail behind', async () => {
        // Limit is the only bound available until MJ#4123 publishes a date filter. Hitting it while
        // a watermark is set means the pass is incomplete, and saying so is the whole point.
        const payloads = Array.from({ length: 5 }, (_, i) => ({ ...GRAPH_MESSAGE, id: `m-${i}` }));
        const reader = readerReturning({ Success: true, SourceData: payloads });
        const batch = await liveTransport(reader).Fetch({ ...QUERY, Since: new Date('2026-08-01'), Limit: 5 });
        expect(batch.Issues.join(' ')).toMatch(/may remain unread/i);
    });

    it('stays quiet when the read was not capped', async () => {
        const reader = readerReturning({ Success: true, SourceData: [GRAPH_MESSAGE] });
        const batch = await liveTransport(reader).Fetch({ ...QUERY, Since: new Date('2026-08-01'), Limit: 50 });
        expect(batch.Issues).toEqual([]);
    });
});

describe('MJGraphTransportDeps — resolving the two collaborators', () => {
    it('names the REGISTRATION as the problem when the provider is absent', async () => {
        // Not a credential problem. Saying which keeps an operator from hunting for a secret that is
        // present and correct.
        const deps = MJGraphTransportDeps({
            CredentialName: 'Graph',
            GetCredentialEngine: () => ({ getCredential: async <T>() => ({ values: CREDENTIAL as unknown as T }) }),
            GetCommunicationProvider: () => null,
        });
        await expect(deps.ResolveProvider()).rejects.toThrow(new RegExp(GRAPH_COMMUNICATION_PROVIDER));
        await expect(deps.ResolveProvider()).rejects.toThrow(/not registered/i);
    });

    it('asks for the provider by the name MJ registers it under', async () => {
        const get = vi.fn().mockReturnValue(readerReturning({ Success: true }));
        const deps = MJGraphTransportDeps({
            CredentialName: 'Graph',
            GetCredentialEngine: () => ({ getCredential: async <T>() => ({ values: CREDENTIAL as unknown as T }) }),
            GetCommunicationProvider: get,
        });
        await deps.ResolveProvider();
        expect(get).toHaveBeenCalledWith('Microsoft Graph');
    });

    it('passes the credential NAME through to the engine', async () => {
        const getCredential = vi.fn().mockResolvedValue({ values: CREDENTIAL });
        const deps = MJGraphTransportDeps({
            CredentialName: 'BizApps Graph Reader',
            GetCredentialEngine: () => ({ getCredential }),
            GetCommunicationProvider: () => readerReturning({ Success: true }),
        });
        await deps.ResolveCredential();
        expect(getCredential).toHaveBeenCalledWith('BizApps Graph Reader', expect.anything());
    });

    it('throws rather than returning undefined values', async () => {
        const deps = MJGraphTransportDeps({
            CredentialName: 'Graph',
            GetCredentialEngine: () => ({ getCredential: async () => ({ values: undefined }) }) as never,
            GetCommunicationProvider: () => readerReturning({ Success: true }),
        });
        await expect(deps.ResolveCredential()).rejects.toThrow(/no values/i);
    });
});

describe('RecordedMessageTransport — the replay path', () => {
    const recorded = new RecordedMessageTransport([
        { Mailbox: 'Rep@Example.com', Payloads: [GRAPH_MESSAGE], Provenance: 'captured 2026-08-30' },
    ]);

    it('is NEVER live, so a replayed run cannot be written as Integration-sourced', () => {
        // The engine's guard rests on this. If a recording could claim to be live, a demo run would
        // be indistinguishable from a real sync in the database afterwards.
        expect(recorded.IsLive).toBe(false);
    });

    it('matches the mailbox case-insensitively', async () => {
        const batch = await recorded.Fetch(QUERY);
        expect(batch.Payloads).toEqual([GRAPH_MESSAGE]);
    });

    it('always says, in the issues, that nothing was read from Microsoft 365', async () => {
        const batch = await recorded.Fetch(QUERY);
        expect(batch.Issues.join(' ')).toMatch(/REPLAYED, NOT LIVE/);
        expect(batch.Issues.join(' ')).toContain('captured 2026-08-30');
    });

    it('THROWS for an unrecorded mailbox instead of reporting an empty success', async () => {
        // An empty batch would report a successful sync of a mailbox that was never recorded.
        await expect(recorded.Fetch({ ...QUERY, Mailbox: 'nobody@example.com' })).rejects.toThrow(
            /No recorded payloads/i,
        );
    });

    it('names the mailboxes it does have, so the error is actionable', async () => {
        await expect(recorded.Fetch({ ...QUERY, Mailbox: 'nobody@example.com' })).rejects.toThrow(
            /rep@example\.com/,
        );
    });

    it('honours Limit and says how many it withheld', async () => {
        const many = new RecordedMessageTransport([
            {
                Mailbox: 'rep@example.com',
                Payloads: Array.from({ length: 4 }, (_, i) => ({ ...GRAPH_MESSAGE, id: `m-${i}` })),
                Provenance: 'captured',
            },
        ]);
        const batch = await many.Fetch({ ...QUERY, Limit: 2 });
        expect(batch.Payloads).toHaveLength(2);
        expect(batch.Issues.join(' ')).toMatch(/2 were not returned/);
    });
});

describe('MSGraphActivitySyncProvider — the gate around the transport', () => {
    /** FetchRaw and Normalize are protected; the public entry point is Fetch. */
    const fetchVia = (provider: MSGraphActivitySyncProvider, query: ActivitySourceQuery = QUERY) => provider.Fetch(query);

    it('refuses with the tenant-wide warning when live fetch is not opted in', async () => {
        const provider = new MSGraphActivitySyncProvider(false, liveTransport(readerReturning({ Success: true, SourceData: [GRAPH_MESSAGE] })));
        const batch = await fetchVia(provider);
        expect(batch.Items).toEqual([]);
        expect(batch.Issues.join(' ')).toBe(LIVE_GRAPH_REFUSAL);
    });

    it('does not call the transport at all while refused', async () => {
        const reader = readerReturning({ Success: true, SourceData: [GRAPH_MESSAGE] });
        await fetchVia(new MSGraphActivitySyncProvider(false, liveTransport(reader)));
        expect(reader.GetMessages).not.toHaveBeenCalled();
    });

    it('refuses distinctly when live fetch IS opted in but no transport was supplied', async () => {
        const batch = await fetchVia(new MSGraphActivitySyncProvider(true));
        expect(batch.Issues.join(' ')).toBe(NO_TRANSPORT_REFUSAL);
    });

    it('prefers the tenant-wide warning in the DEFAULT construction', async () => {
        // No transport and no opt-in is what someone gets by writing `new MSGraphActivitySyncProvider()`.
        // The useful thing to say there is why live fetch is off, not that a transport is absent.
        const batch = await fetchVia(new MSGraphActivitySyncProvider());
        expect(batch.Issues.join(' ')).toBe(LIVE_GRAPH_REFUSAL);
    });

    describe('a single message must not vanish', () => {
        /**
         * THE REGRESSION. Normalize used to unwrap a one-element Payloads array and hand
         * MapGraphMessages a bare message object, which matches neither shape it accepts — so a
         * mailbox with exactly one new message normalized to nothing and reported a clean, empty,
         * successful sync. One message is the single most likely size of a real incremental pass.
         */
        it('maps exactly ONE payload rather than silently dropping it', async () => {
            const batch = await fetchVia(new MSGraphActivitySyncProvider(false, recordedTransport()));
            expect(batch.Items).toHaveLength(1);
        });

        it('maps two payloads as well, so the fix did not just move the boundary', async () => {
            const two = new RecordedMessageTransport([
                {
                    Mailbox: 'rep@example.com',
                    Payloads: [GRAPH_MESSAGE, { ...GRAPH_MESSAGE, id: 'AAMkAG2', conversationId: 'conv-2' }],
                    Provenance: 'captured',
                },
            ]);
            const batch = await fetchVia(new MSGraphActivitySyncProvider(false, two));
            expect(batch.Items.map((i) => i.ExternalID)).toEqual(['AAMkAG', 'AAMkAG2']);
        });

        it('still accepts a raw Graph response envelope, detected by shape not by length', async () => {
            const enveloped = new RecordedMessageTransport([
                { Mailbox: 'rep@example.com', Payloads: [{ value: [GRAPH_MESSAGE] }], Provenance: 'captured' },
            ]);
            const batch = await fetchVia(new MSGraphActivitySyncProvider(false, enveloped));
            expect(batch.Items).toHaveLength(1);
            expect(batch.Items[0].ExternalID).toBe('AAMkAG');
        });
    });

    it('LETS A RECORDING THROUGH without the live opt-in, because it reaches no mailbox', async () => {
        // The refusal guards against reading mailboxes we are not scoped to. Gating the replay too
        // would make the safe path as awkward as the dangerous one.
        const provider = new MSGraphActivitySyncProvider(false, recordedTransport());
        const batch = await fetchVia(provider);
        expect(batch.Items).toHaveLength(1);
        expect(batch.Items[0].Subject).toBe('Renewal terms');
    });

    it('reports IsLive from the transport, not from the class', () => {
        expect(new MSGraphActivitySyncProvider(true, recordedTransport()).IsLive).toBe(false);
        expect(new MSGraphActivitySyncProvider(true, liveTransport(readerReturning({ Success: true }))).IsLive).toBe(true);
    });

    it('maps a replayed payload through the REAL Graph mapper', async () => {
        // The whole claim of the recorded path: everything but the network hop is the live code.
        const batch = await fetchVia(new MSGraphActivitySyncProvider(false, recordedTransport()));
        const item = batch.Items[0];
        expect(item.ExternalID).toBe('AAMkAG');
        expect(item.ExternalThreadID).toBe('conv-1');
        // Inbound: the mailbox is a recipient, not the sender.
        expect(item.Direction).toBe('Inbound');
        expect(item.Participants.map((p) => p.Address)).toContain('buyer@customer.com');
    });

    it('surfaces a transport throw as a FAILED batch, not an empty one', async () => {
        const reader = readerReturning({ Success: false, ErrorMessage: 'Forbidden' });
        const provider = new MSGraphActivitySyncProvider(true, liveTransport(reader));
        const batch = await fetchVia(provider);
        expect(batch.Failed).toBe(true);
        expect(batch.HighWatermark).toBeNull();
        expect(batch.Issues.join(' ')).toMatch(/Forbidden/);
    });

    function recordedTransport() {
        return new RecordedMessageTransport([
            { Mailbox: 'rep@example.com', Payloads: [GRAPH_MESSAGE], Provenance: 'captured 2026-08-30' },
        ]);
    }
});

describe('Configure — reading CredentialsRef off the connection', () => {
    /**
     * THE COLUMN THAT NOTHING READ. `ActivitySyncConnection.CredentialsRef` describes itself as an
     * MJ Credentials engine key, and no code consumed it — so a connection could name the credential
     * it wanted and be ignored. These assert that it is now read, and that each way of failing to
     * resolve it says something DIFFERENT, because they have different fixes.
     */
    const ctx = (over = {}) => ({
        CredentialsRef: 'BizApps Graph Reader',
        Mailbox: 'rep@example.com',
        DriverClass: 'Microsoft365',
        ...over,
    });

    /**
     * These opt IN to live fetch deliberately. The tenant-wide refusal is checked FIRST and is the
     * right answer when it applies, so a configuration refusal is only reachable once that gate is
     * past. Testing them with the gate shut would assert the gate, not the configuration.
     */
    const fetchIssue = async (p: MSGraphActivitySyncProvider) =>
        (await p.Fetch({ ...QUERY, Since: null })).Issues.join(' ');

    it('builds a transport from the factory, passing it the connection context', async () => {
        const factory = vi.fn().mockReturnValue(recorded());
        const provider = new MSGraphActivitySyncProvider(false, undefined, factory);
        provider.Configure(ctx());

        expect(factory).toHaveBeenCalledWith(
            expect.objectContaining({ CredentialsRef: 'BizApps Graph Reader', Mailbox: 'rep@example.com' }),
        );
        const batch = await provider.Fetch({ ...QUERY, Since: null });
        expect(batch.Items).toHaveLength(1);
    });

    it('refuses with a CredentialsRef-specific message when the connection names none', async () => {
        // The real state of our own connection row today: Status Active, CredentialsRef NULL.
        const provider = new MSGraphActivitySyncProvider(true, undefined, () => recorded());
        provider.Configure(ctx({ CredentialsRef: null }));
        expect(await fetchIssue(provider)).toBe(NO_CREDENTIAL_REF_REFUSAL);
    });

    it('treats a whitespace-only CredentialsRef as absent', async () => {
        const provider = new MSGraphActivitySyncProvider(true, undefined, () => recorded());
        provider.Configure(ctx({ CredentialsRef: '   ' }));
        expect(await fetchIssue(provider)).toBe(NO_CREDENTIAL_REF_REFUSAL);
    });

    it('does not call the factory when there is no CredentialsRef to resolve', async () => {
        const factory = vi.fn().mockReturnValue(recorded());
        new MSGraphActivitySyncProvider(false, undefined, factory).Configure(ctx({ CredentialsRef: null }));
        expect(factory).not.toHaveBeenCalled();
    });

    it('names the MISSING FACTORY distinctly — a different fix from a missing CredentialsRef', async () => {
        const provider = new MSGraphActivitySyncProvider(true);
        provider.Configure(ctx());
        const issue = await fetchIssue(provider);
        expect(issue).toMatch(/no transport factory is registered/i);
        expect(issue).toContain('BizApps Graph Reader');
        expect(issue).not.toBe(NO_CREDENTIAL_REF_REFUSAL);
    });

    it('names a factory that served nothing, rather than reporting a missing transport', async () => {
        const provider = new MSGraphActivitySyncProvider(true, undefined, () => null);
        provider.Configure(ctx());
        expect(await fetchIssue(provider)).toMatch(/served no transport/i);
    });

    it('NEVER replaces a transport given to the constructor', async () => {
        // A database row must not be able to reach in and swap what a caller supplied.
        const factory = vi.fn().mockReturnValue(recorded());
        const provider = new MSGraphActivitySyncProvider(false, recorded(), factory);
        provider.Configure(ctx());
        expect(factory).not.toHaveBeenCalled();
    });

    it('lets a provider that was never configured keep its old refusal', async () => {
        expect(await fetchIssue(new MSGraphActivitySyncProvider(true))).toBe(NO_TRANSPORT_REFUSAL);
    });

    it('is a NO-OP on the base class, so existing providers are untouched', () => {
        const fixture = new RecordedMessageTransport([]);
        expect(() => new MSGraphActivitySyncProvider(false, fixture).Configure(ctx())).not.toThrow();
    });

    function recorded() {
        return new RecordedMessageTransport([
            { Mailbox: 'rep@example.com', Payloads: [GRAPH_MESSAGE], Provenance: 'captured' },
        ]);
    }
});

describe('Configure — reachable in the configuration the ENGINE actually uses', () => {
    /**
     * THE TESTS ABOVE OPT IN TO LIVE FETCH. That is a legitimate way to isolate the configuration
     * refusals, but it leaves the production path unasserted: `ActivitySyncEngine` resolves this
     * provider through `ClassFactory`, which constructs it with NO ARGUMENTS, so `AllowLiveFetch`
     * is false and no factory is ever injected. With the tenant gate returning early, every
     * Configure-time message was unreachable there — the operator was told the Exchange policy was
     * the problem when the real problem was a missing CredentialsRef or a missing factory.
     *
     * These construct the provider the way the engine does and assert BOTH messages surface. They
     * fail against an implementation that returns only the tenant refusal.
     */
    const engineBuilt = () => new MSGraphActivitySyncProvider();
    const ctx = (over = {}) => ({
        CredentialsRef: 'BizApps Graph Reader',
        Mailbox: 'rep@example.com',
        DriverClass: 'Microsoft365',
        ...over,
    });

    it('still reports the tenant-wide refusal FIRST — the security message keeps precedence', async () => {
        const p = engineBuilt();
        p.Configure(ctx({ CredentialsRef: null }));
        const batch = await p.Fetch({ ...QUERY, Since: null });
        expect(batch.Issues[0]).toBe(LIVE_GRAPH_REFUSAL);
    });

    it('ALSO names the missing CredentialsRef, which the tenant refusal does not mention', async () => {
        const p = engineBuilt();
        p.Configure(ctx({ CredentialsRef: null }));
        const batch = await p.Fetch({ ...QUERY, Since: null });
        expect(batch.Issues).toHaveLength(2);
        expect(batch.Issues[1]).toBe(NO_CREDENTIAL_REF_REFUSAL);
    });

    it('ALSO names the missing factory when the connection DOES name a credential', async () => {
        // Setting CredentialsRef in the database and changing nothing else lands here. Without the
        // second issue an operator sees only 'confirm the Application Access Policy', which is the
        // wrong hunt: the policy could be perfect and this would still refuse.
        const p = engineBuilt();
        p.Configure(ctx());
        const batch = await p.Fetch({ ...QUERY, Since: null });
        expect(batch.Issues).toHaveLength(2);
        expect(batch.Issues[1]).toContain('no transport factory is registered');
        expect(batch.Issues[1]).toContain('BizApps Graph Reader');
    });

    it('adds NOTHING for a recorded transport — the demo path stays a single provenance note', async () => {
        const p = new MSGraphActivitySyncProvider(false, new RecordedMessageTransport([
            { Mailbox: 'rep@example.com', Payloads: [GRAPH_MESSAGE], Provenance: 'captured' },
        ]));
        p.Configure(ctx({ CredentialsRef: null }));
        const batch = await p.Fetch({ ...QUERY, Since: null });
        expect(batch.Issues).toHaveLength(1);
        expect(batch.Issues[0]).not.toBe(LIVE_GRAPH_REFUSAL);
        expect(batch.Items).toHaveLength(1);
    });
});

describe('a capped read must not advance the watermark past mail it never fetched', () => {
    /**
     * THE SILENT LOSS THIS PREVENTS. Graph returns newest-first, so when a read hits NumMessages
     * the batch holds the NEWEST N — and its newest item is the newest in the mailbox. Advancing
     * the watermark to it steps over everything between the previous watermark and the OLDEST item
     * returned. That mail is then permanently below the watermark and is never read again, and the
     * run reports success. Re-reading a window costs a de-duplicated pass; losing mail costs the
     * mail. `watermark.ts` already states those are not comparable — this enforces it.
     */
    const SINCE = new Date('2026-08-01T00:00:00Z');
    const msg = (id: string, when: string) => ({ ...GRAPH_MESSAGE, id, receivedDateTime: when, sentDateTime: when });
    const TWO = [msg('m-old', '2026-08-20T09:00:00Z'), msg('m-new', '2026-08-30T09:00:00Z')];

    it('flags the batch as capped when the limit binds and a watermark was in play', async () => {
        const t = liveTransport(readerReturning({ Success: true, SourceData: TWO }));
        const batch = await t.Fetch({ ...QUERY, Since: SINCE, Limit: 2 });
        expect(batch.Capped).toBe(true);
    });

    it('does NOT flag a first sync, which has no watermark to strand mail behind', async () => {
        const t = liveTransport(readerReturning({ Success: true, SourceData: TWO }));
        const batch = await t.Fetch({ ...QUERY, Since: null, Limit: 2 });
        expect(batch.Capped).toBeFalsy();
    });

    it('WITHHOLDS the watermark on a capped batch, so the next pass re-reads the window', async () => {
        const t = liveTransport(readerReturning({ Success: true, SourceData: TWO }));
        const provider = new MSGraphActivitySyncProvider(true, t);
        const batch = await provider.Fetch({ ...QUERY, Since: SINCE, Limit: 2 });
        // Without this the watermark becomes 2026-08-30 and anything between 08-01 and 08-20 that
        // did not fit in the batch is stranded below it forever.
        expect(batch.HighWatermark).toBeNull();
    });

    it('still RETURNS the items it did fetch — only the claim is withheld, not the data', async () => {
        const t = liveTransport(readerReturning({ Success: true, SourceData: TWO }));
        const provider = new MSGraphActivitySyncProvider(true, t);
        const batch = await provider.Fetch({ ...QUERY, Since: SINCE, Limit: 2 });
        expect(batch.Items).toHaveLength(2);
        expect(batch.Failed).toBeFalsy();
    });

    it('advances normally when the read was NOT capped', async () => {
        const t = liveTransport(readerReturning({ Success: true, SourceData: TWO }));
        const provider = new MSGraphActivitySyncProvider(true, t);
        const batch = await provider.Fetch({ ...QUERY, Since: SINCE, Limit: 50 });
        expect(batch.HighWatermark).toEqual(new Date('2026-08-30T09:00:00Z'));
    });
});

describe('the host transport registry — making the seam reachable at all', () => {
    /**
     * WHAT THIS COVERS THAT NOTHING DID. `ActivityTransportFactory` was reachable only as the THIRD
     * constructor argument, and `MJGlobal.ClassFactory` builds plugins with NO arguments. So through
     * `ActivitySyncEngine` — the only path production uses — a factory could never arrive, and every
     * test that exercised one passed it directly to the constructor, which production never does.
     * A seam that is exported, documented and unreachable is the same defect this package keeps
     * being written against, one layer up.
     */
    afterEach(() => {
        RegisterActivityTransportFactory(null); // process-wide state — never leak it between tests
    });

    const ctx = (over = {}) => ({
        CredentialsRef: 'BizApps Graph Reader',
        Mailbox: 'rep@example.com',
        DriverClass: 'Microsoft365',
        ...over,
    });
    const recorded = () =>
        new RecordedMessageTransport([
            { Mailbox: 'rep@example.com', Payloads: [GRAPH_MESSAGE], Provenance: 'captured' },
        ]);

    it('serves no factory until a host registers one', () => {
        expect(HostActivityTransportFactory()).toBeNull();
    });

    it('a provider built the way ClassFactory builds it USES the registered factory', async () => {
        const factory = vi.fn().mockReturnValue(recorded());
        RegisterActivityTransportFactory(factory);

        const provider = new MSGraphActivitySyncProvider(); // no arguments, exactly like the engine
        provider.Configure(ctx());

        expect(factory).toHaveBeenCalledWith(
            expect.objectContaining({ CredentialsRef: 'BizApps Graph Reader', DriverClass: 'Microsoft365' }),
        );
        const batch = await provider.Fetch({ ...QUERY, Since: null });
        expect(batch.Items).toHaveLength(1);
    });

    it('a CONSTRUCTOR factory still wins over a registered one', async () => {
        const registered = vi.fn().mockReturnValue(recorded());
        const explicit = vi.fn().mockReturnValue(recorded());
        RegisterActivityTransportFactory(registered);

        new MSGraphActivitySyncProvider(false, undefined, explicit).Configure(ctx());

        expect(explicit).toHaveBeenCalled();
        expect(registered).not.toHaveBeenCalled();
    });

    it('a CONSTRUCTOR transport is never replaced by a registered factory', async () => {
        const registered = vi.fn().mockReturnValue(recorded());
        RegisterActivityTransportFactory(registered);

        const fixture = recorded();
        new MSGraphActivitySyncProvider(false, fixture).Configure(ctx());

        expect(registered).not.toHaveBeenCalled();
    });

    it('clearing the registry restores the no-factory refusal rather than leaving a stale one', async () => {
        RegisterActivityTransportFactory(vi.fn().mockReturnValue(recorded()));
        RegisterActivityTransportFactory(null);

        const provider = new MSGraphActivitySyncProvider(true);
        provider.Configure(ctx());
        const batch = await provider.Fetch({ ...QUERY, Since: null });
        expect(batch.Issues.join(' ')).toContain('no transport factory is registered');
    });

    it('passes the ContextUser through, which the Credentials engine requires server-side', () => {
        const factory = vi.fn().mockReturnValue(recorded());
        RegisterActivityTransportFactory(factory);
        const user = { ID: 'u-1', Name: 'Rep' } as unknown as UserInfo;

        new MSGraphActivitySyncProvider().Configure(ctx({ ContextUser: user }));

        expect(factory).toHaveBeenCalledWith(expect.objectContaining({ ContextUser: user }));
    });
});

describe('a capped REPLAY withholds the watermark too', () => {
    /**
     * The live path was fixed first, and fixing only it left the seam inconsistent. A replay
     * truncates with `slice(0, Limit)` — the FIRST N — so a recording ordered oldest-first produces
     * a batch contiguous with the watermark, and advancing happens to be safe. That safety is an
     * accident of FILE ORDER. A recording captured newest-first, or re-sorted by an editor, becomes
     * the live data-loss bug with no code change anywhere and nothing to notice it.
     */
    const SINCE = new Date('2026-08-01T00:00:00Z');
    const msg = (id: string, when: string) => ({ ...GRAPH_MESSAGE, id, receivedDateTime: when, sentDateTime: when });
    const THREE = [
        msg('r-1', '2026-08-20T09:00:00Z'),
        msg('r-2', '2026-08-25T09:00:00Z'),
        msg('r-3', '2026-08-30T09:00:00Z'),
    ];
    const recorded = (payloads: Record<string, unknown>[]) =>
        new RecordedMessageTransport([{ Mailbox: 'rep@example.com', Payloads: payloads, Provenance: 'captured' }]);

    it('flags a truncated replay as capped when a watermark is in play', async () => {
        const batch = await recorded(THREE).Fetch({ ...QUERY, Since: SINCE, Limit: 2 });
        expect(batch.Capped).toBe(true);
    });

    it('does NOT flag a first sync — there is no watermark to strand anything behind', async () => {
        const batch = await recorded(THREE).Fetch({ ...QUERY, Since: null, Limit: 2 });
        expect(batch.Capped).toBeFalsy();
    });

    it('does NOT flag a replay that fitted', async () => {
        const batch = await recorded(THREE).Fetch({ ...QUERY, Since: SINCE, Limit: 50 });
        expect(batch.Capped).toBeFalsy();
    });

    it('withholds the watermark through the provider, exactly as the live path does', async () => {
        const provider = new MSGraphActivitySyncProvider(false, recorded(THREE));
        const batch = await provider.Fetch({ ...QUERY, Since: SINCE, Limit: 2 });
        expect(batch.HighWatermark, 'a capped replay must not claim to have seen past its newest item').toBeNull();
        expect(batch.Items.length, 'the items it DID read are still returned').toBeGreaterThan(0);
    });
});
