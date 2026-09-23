/**
 * The host registries survive this package being loaded twice.
 *
 * A host that resolves two copies of `common-activity-sync` runs each module twice. With module-scoped
 * registries, a host would register into one copy and the engine would read the other and find
 * nothing (bc-aidp-next-golive#258). `vi.resetModules()` between imports gives each its own module
 * instance and top-level scope — what a nested second copy has.
 */
import { afterEach, describe, expect, it, vi } from 'vitest';
import type { ActivityFileSink } from '../attachments.js';
import type { ActivityContentCipher } from '../content-capture.js';
import type { ActivityTransportFactory, LiveMailboxPolicyAttestation } from '../providers/MessageTransport.js';

type Attachments = typeof import('../attachments.js');
type ContentCapture = typeof import('../content-capture.js');
type Transport = typeof import('../providers/MessageTransport.js');

async function twice<T>(load: () => Promise<T>): Promise<[T, T]> {
    vi.resetModules();
    const first = await load();
    vi.resetModules();
    const second = await load();
    return [first, second];
}

const sink = {} as ActivityFileSink;
const cipher = {} as ActivityContentCipher;
const factory = {} as ActivityTransportFactory;
const attestation: LiveMailboxPolicyAttestation = {
    Scope: 'RestrictedToGroup',
    ScopedToGroup: 'activity-sync-mailboxes',
    Confirmed: true,
    ConfirmedBy: 'test',
    ConfirmedAt: new Date('2026-01-01'),
};

let clear: Array<() => void> = [];
afterEach(() => {
    for (const c of clear) c();
    clear = [];
});

describe('two copies of the package share one registry', () => {
    it('are genuinely separate module instances', async () => {
        // Without this every test below would pass vacuously on one shared instance.
        const [a, b] = await twice<Attachments>(() => import('../attachments.js'));
        expect(a.RegisterActivityFileSink).not.toBe(b.RegisterActivityFileSink);
    });

    it('file sink', async () => {
        const [a, b] = await twice<Attachments>(() => import('../attachments.js'));
        clear.push(() => a.RegisterActivityFileSink(null));
        a.RegisterActivityFileSink(sink);
        expect(b.HostActivityFileSink()).toBe(sink);
        b.RegisterActivityFileSink(null);
        expect(a.HostActivityFileSink()).toBeNull();
    });

    it('content cipher', async () => {
        const [a, b] = await twice<ContentCapture>(() => import('../content-capture.js'));
        clear.push(() => a.RegisterActivityContentCipher(null));
        a.RegisterActivityContentCipher(cipher);
        expect(b.HostActivityContentCipher()).toBe(cipher);
        b.RegisterActivityContentCipher(null);
        expect(a.HostActivityContentCipher()).toBeNull();
    });

    it('transport factory', async () => {
        const [a, b] = await twice<Transport>(() => import('../providers/MessageTransport.js'));
        clear.push(() => a.RegisterActivityTransportFactory(null));
        a.RegisterActivityTransportFactory(factory);
        expect(b.HostActivityTransportFactory()).toBe(factory);
        b.RegisterActivityTransportFactory(null);
        expect(a.HostActivityTransportFactory()).toBeNull();
    });

    it('live-mailbox attestation, including revocation', async () => {
        // Revocation through one copy must close the gate in the other: a copy that still reads an
        // attestation after the host revoked it would keep reading real mailboxes.
        const [a, b] = await twice<Transport>(() => import('../providers/MessageTransport.js'));
        clear.push(() => a.AllowLiveMailboxFetch(null));
        a.AllowLiveMailboxFetch(attestation);
        expect(b.HostLiveMailboxPolicy()).toBe(attestation);
        expect(b.HostAllowsLiveMailboxFetch()).toBe(true);
        b.AllowLiveMailboxFetch(null);
        expect(a.HostAllowsLiveMailboxFetch()).toBe(false);
    });
});
