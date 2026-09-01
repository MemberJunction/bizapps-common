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
import { describe, expect, it, vi } from 'vitest';

import {
    GraphCommunicationTransport,
    GRAPH_COMMUNICATION_PROVIDER,
    GRAPH_CREDENTIAL_TYPE,
    MJGraphTransportDeps,
    type GraphMessageReader,
    type GraphServicePrincipal,
} from '../providers/GraphCommunicationTransport.js';
import { RecordedMessageTransport } from '../providers/RecordedMessageTransport.js';
import {
    LIVE_GRAPH_REFUSAL,
    MSGraphActivitySyncProvider,
    NO_TRANSPORT_REFUSAL,
} from '../providers/MSGraphActivitySyncProvider.js';
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
        expect(credentials).toEqual(CREDENTIAL);
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
            GetCredentialEngine: () => ({ getCredential: async () => ({ values: CREDENTIAL }) }),
            GetCommunicationProvider: () => null,
        });
        await expect(deps.ResolveProvider()).rejects.toThrow(new RegExp(GRAPH_COMMUNICATION_PROVIDER));
        await expect(deps.ResolveProvider()).rejects.toThrow(/not registered/i);
    });

    it('asks for the provider by the name MJ registers it under', async () => {
        const get = vi.fn().mockReturnValue(readerReturning({ Success: true }));
        const deps = MJGraphTransportDeps({
            CredentialName: 'Graph',
            GetCredentialEngine: () => ({ getCredential: async () => ({ values: CREDENTIAL }) }),
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
