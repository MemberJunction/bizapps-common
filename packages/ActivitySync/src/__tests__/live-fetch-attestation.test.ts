/**
 * The live-fetch gate, and whether it can be reached at all.
 *
 * THE DEFECT THIS FILE EXISTS FOR. `AllowLiveFetch` was the FIRST constructor argument, defaulting
 * to `false`, and `MJGlobal.ClassFactory` builds plugins with NO arguments. So through
 * `ActivitySyncEngine` — the only path production uses — live fetch was permanently off and could be
 * turned on by tests and the demo alone. Every test passed. The parameter was documented, exported
 * and unreachable, which is precisely the failure the transport factory had one layer down.
 *
 * The fix must hold TWO properties at once, and most of the tests below exist to pin the second:
 *
 *   1. a scoped host CAN enable live fetch through the path that ships, and
 *   2. an unconfigured host still refuses, and nothing reachable from a database row can change that.
 *
 * A fix that only satisfies (1) is worse than the bug. App-only `Mail.Read` reads every mailbox in
 * the tenant, so "on by default" or "on because a row said so" would hand tenant-wide mail access to
 * anyone who can edit a connection.
 */
import { afterEach, describe, expect, it, vi } from 'vitest';

import {
    AllowLiveMailboxFetch,
    HostAllowsLiveMailboxFetch,
    HostLiveMailboxPolicy,
    RegisterActivityTransportFactory,
    type ActivityMessageTransport,
    type LiveMailboxPolicyAttestation,
} from '../providers/MessageTransport.js';
import { RecordedMessageTransport } from '../providers/RecordedMessageTransport.js';
import { LIVE_GRAPH_REFUSAL, MSGraphActivitySyncProvider } from '../providers/MSGraphActivitySyncProvider.js';

import type { ActivitySourceQuery } from '../types.js';

const QUERY: ActivitySourceQuery = { Mailbox: 'rep@example.com', Since: null, Limit: 50 };

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

/** A transport that CLAIMS to be live. What it returns is irrelevant; only the gate is under test. */
const liveTransport = (): ActivityMessageTransport => ({
    Describe: 'stub (claims live)',
    IsLive: true,
    Fetch: vi.fn().mockResolvedValue({ Payloads: [GRAPH_MESSAGE], Issues: [] }),
});

const recordedTransport = () =>
    new RecordedMessageTransport([{ Mailbox: 'rep@example.com', Payloads: [GRAPH_MESSAGE], Provenance: 'captured' }]);

const ATTESTATION: LiveMailboxPolicyAttestation = {
    Confirmed: true,
    Scope: 'RestrictedToGroup',
    ScopedToGroup: 'activity-sync-mailboxes@bluecypress.io',
    ConfirmedBy: 'Josue Garcia',
    ConfirmedAt: new Date('2026-09-04T00:00:00Z'),
};

const ctx = () => ({ CredentialsRef: 'Graph Reader', Mailbox: 'rep@example.com', DriverClass: 'Microsoft365' });

/** Build one the way ClassFactory does — no arguments — and let the host registry supply transport. */
function providerAsShipped(transport: ActivityMessageTransport) {
    RegisterActivityTransportFactory(() => transport);
    const provider = new MSGraphActivitySyncProvider();
    provider.Configure(ctx());
    return provider;
}

afterEach(() => {
    // Both registries are process-wide. Leaking either between tests would let one test's opt-in
    // silently satisfy another's refusal assertion — which is the exact bug shape under test.
    AllowLiveMailboxFetch(null);
    RegisterActivityTransportFactory(null);
});

describe('an unconfigured host refuses, exactly as before', () => {
    it('attests to nothing until a host says otherwise', () => {
        expect(HostAllowsLiveMailboxFetch()).toBe(false);
        expect(HostLiveMailboxPolicy()).toBeNull();
    });

    /**
     * THE REGRESSION TEST FOR THE WHOLE CHANGE. Making the gate reachable must not make it open.
     * This is the configuration a host has on the day it installs the package.
     */
    it('refuses a live transport when no policy has been attested', async () => {
        const batch = await providerAsShipped(liveTransport()).Fetch(QUERY);
        expect(batch.Issues[0]).toBe(LIVE_GRAPH_REFUSAL);
        expect(batch.Items).toHaveLength(0);
    });

    it('never reaches the transport it refused', async () => {
        const transport = liveTransport();
        await providerAsShipped(transport).Fetch(QUERY);
        expect(transport.Fetch).not.toHaveBeenCalled();
    });

    /**
     * The safe path must stay the easy one. If replaying recordings also demanded an attestation,
     * people would attest in order to demo — which is how the dangerous flag gets set for the wrong
     * reason.
     */
    it('still allows a RECORDED transport, which reaches no mailbox', async () => {
        const batch = await providerAsShipped(recordedTransport()).Fetch(QUERY);
        expect(batch.Issues.join(' ')).not.toContain('Live Graph fetch is disabled');
        expect(batch.Items).toHaveLength(1);
    });
});

describe('a scoped host can enable it through the path that actually ships', () => {
    /**
     * The other half. Before this change there was NO argument-free way to reach `true`, so this
     * assertion could not have been written at all.
     */
    it('a no-argument provider fetches once the host has attested', async () => {
        AllowLiveMailboxFetch(ATTESTATION);
        const transport = liveTransport();

        const batch = await providerAsShipped(transport).Fetch(QUERY);

        expect(transport.Fetch).toHaveBeenCalledOnce();
        expect(batch.Issues.join(' ')).not.toContain('Live Graph fetch is disabled');
        expect(batch.Items).toHaveLength(1);
    });

    it('keeps the attestation readable, so an audit can ask who allowed this', () => {
        AllowLiveMailboxFetch(ATTESTATION);
        expect(HostLiveMailboxPolicy()).toEqual(ATTESTATION);
        expect(HostAllowsLiveMailboxFetch()).toBe(true);
    });

    it('revoking restores the refusal rather than leaving a stale allow', async () => {
        AllowLiveMailboxFetch(ATTESTATION);
        AllowLiveMailboxFetch(null);

        expect(HostAllowsLiveMailboxFetch()).toBe(false);
        const batch = await providerAsShipped(liveTransport()).Fetch(QUERY);
        expect(batch.Issues[0]).toBe(LIVE_GRAPH_REFUSAL);
    });

    /**
     * Default parameters apply only to `undefined`, so an explicit `false` must still win. A caller
     * that deliberately builds a refusing provider — the demo does — must not be overridden by a
     * host-wide opt-in registered elsewhere in the process.
     */
    it('an explicit false in the constructor still wins over a host attestation', async () => {
        AllowLiveMailboxFetch(ATTESTATION);
        const transport = liveTransport();

        const provider = new MSGraphActivitySyncProvider(false, transport);
        const batch = await provider.Fetch(QUERY);

        expect(batch.Issues[0]).toBe(LIVE_GRAPH_REFUSAL);
        expect(transport.Fetch).not.toHaveBeenCalled();
    });
});

describe('the two decisions an organisation actually makes', () => {
    /**
     * WHY THIS VARIANT EXISTS. The first version of the attestation demanded `ScopedToGroup`, which
     * assumed every deployment would create an Exchange RBAC assignment. Most will not: adding an API
     * permission in Entra is one team's five-minute job, and Exchange RBAC for Applications is a
     * different system that often nobody owns. A gate that only accepts "scoped" leaves everyone else
     * choosing between inventing a group name and bypassing the gate — and both destroy the record it
     * exists to keep. Accepting a tenant-wide grant knowingly is a real decision, so it is modelled.
     */
    const ACCEPTED: LiveMailboxPolicyAttestation = {
        Confirmed: true,
        Scope: 'TenantWideAccepted',
        AcceptedRisk: 'No Exchange assignment exists; the app can read every mailbox and we accept that for now.',
        ConfirmedBy: 'A Person',
        ConfirmedAt: new Date('2026-09-04T00:00:00Z'),
    };

    it('accepts a knowingly tenant-wide deployment', () => {
        AllowLiveMailboxFetch(ACCEPTED);
        expect(HostAllowsLiveMailboxFetch()).toBe(true);
    });

    it('records WHAT was accepted, not merely that something was', () => {
        AllowLiveMailboxFetch(ACCEPTED);
        const held = HostLiveMailboxPolicy();
        expect(held?.Scope).toBe('TenantWideAccepted');
        expect(held && 'AcceptedRisk' in held && held.AcceptedRisk).toMatch(/every mailbox/);
    });

    /**
     * A tick-box records that somebody clicked; a sentence records that somebody understood. This is
     * the whole difference between this variant and simply removing the gate.
     */
    it('refuses a tenant-wide claim with no stated reason', () => {
        expect(() =>
            AllowLiveMailboxFetch({ ...ACCEPTED, AcceptedRisk: '   ' }),
        ).toThrow(/AcceptedRisk/);
        expect(HostAllowsLiveMailboxFetch()).toBe(false);
    });

    it('still refuses a scoped claim that names no group', () => {
        expect(() =>
            AllowLiveMailboxFetch({ ...ATTESTATION, ScopedToGroup: '' }),
        ).toThrow(/ScopedToGroup/);
        expect(HostAllowsLiveMailboxFetch()).toBe(false);
    });

    /** Neither variant can be satisfied without an owner. "Nobody looked" stays impossible. */
    it('requires a person on either decision', () => {
        expect(() => AllowLiveMailboxFetch({ ...ACCEPTED, ConfirmedBy: ' ' })).toThrow(/ConfirmedBy/);
        expect(() => AllowLiveMailboxFetch({ ...ATTESTATION, ConfirmedBy: ' ' })).toThrow(/ConfirmedBy/);
    });

    it('a tenant-wide attestation opens the gate exactly as a scoped one does', async () => {
        AllowLiveMailboxFetch(ACCEPTED);
        const transport = liveTransport();
        const batch = await providerAsShipped(transport).Fetch(QUERY);
        expect(transport.Fetch).toHaveBeenCalledOnce();
        expect(batch.Issues[0]).not.toBe(LIVE_GRAPH_REFUSAL);
    });
});

describe('the attestation has to actually say something', () => {
    /**
     * These are not defensive noise. The whole reason this is a record rather than a boolean is that
     * someone must look up which group the Exchange policy names. Accepting a blank one would turn
     * it straight back into a boolean with extra steps, and the refusal would be honoured by a
     * caller who checked nothing.
     */
    it('rejects an attestation naming no security group', () => {
        expect(() => AllowLiveMailboxFetch({ ...ATTESTATION, ScopedToGroup: '' })).toThrow(/ScopedToGroup/);
        expect(HostAllowsLiveMailboxFetch()).toBe(false);
    });

    it('rejects a group that is only whitespace', () => {
        expect(() => AllowLiveMailboxFetch({ ...ATTESTATION, ScopedToGroup: '   ' })).toThrow(/ScopedToGroup/);
        expect(HostAllowsLiveMailboxFetch()).toBe(false);
    });

    it('rejects an attestation with nobody answerable for it', () => {
        expect(() => AllowLiveMailboxFetch({ ...ATTESTATION, ConfirmedBy: '  ' })).toThrow(/ConfirmedBy/);
        expect(HostAllowsLiveMailboxFetch()).toBe(false);
    });

    /** A rejected attestation must not partially apply — no half-open gate. */
    it('leaves a previously valid attestation intact when a later one is rejected', () => {
        AllowLiveMailboxFetch(ATTESTATION);
        expect(() => AllowLiveMailboxFetch({ ...ATTESTATION, ScopedToGroup: '' })).toThrow();
        expect(HostLiveMailboxPolicy()).toEqual(ATTESTATION);
    });
});
