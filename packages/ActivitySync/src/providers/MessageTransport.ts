/**
 * The seam between this engine and however messages actually arrive.
 *
 * WHY THIS EXISTS AS A SEAM. `MSGraphActivitySyncProvider` had no transport at all — both of its
 * `FetchRaw` returns handed back `Payloads: []`, so every live path was a refusal and the only thing
 * that ever produced data was `FixtureActivitySyncProvider`, a DIFFERENT provider that bypasses the
 * Graph mapping entirely. That is why the credential gap went unnoticed: nothing exercised the code
 * that would have needed a credential.
 *
 * Splitting the transport out fixes that specific failure. The provider, the Graph mapping, the
 * participant resolution, the watermark and the writes are the same code on every path; only the
 * outermost call — the one that reaches the network — is substitutable. A run against recorded
 * payloads therefore proves everything except the network hop, which is a far stronger claim than a
 * fixture that proves only the engine.
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import type { UserInfo } from '@memberjunction/core';

import type { ActivitySourceQuery, RawBatch } from '../types.js';

/**
 * Fetch raw provider payloads for one mailbox.
 *
 * Returns `RawBatch` rather than throwing on a partial failure: a batch that arrived with some
 * issues is still worth filing, and `BaseActivitySyncProvider.Fetch` distinguishes "looked and found
 * nothing" from "could not look" by whether this throws.
 */
export interface ActivityMessageTransport {
    /** Human-readable, for issue text. Names WHERE the messages came from, so a run is attributable. */
    readonly Describe: string;

    /**
     * True only when this transport reached the real service. The engine refuses to write
     * `Source: 'Integration'` rows from a non-live provider without being told to, and that guard is
     * worthless if a recorded transport can claim to be live.
     */
    readonly IsLive: boolean;

    Fetch(query: ActivitySourceQuery): Promise<RawBatch>;
}

/**
 * What a connection knows about itself that a transport needs.
 *
 * `CredentialsRef` is the column's whole purpose — its own description says "MJ Credentials engine
 * key. NEVER a secret value at rest" — and until now nothing read it. A connection could name the
 * credential it wanted and be ignored, which is worse than having no column at all: the
 * configuration looked complete.
 */
export interface ActivityTransportContext {
    /** `ActivitySyncConnection.CredentialsRef` — a KEY into MJ's Credentials engine, never a secret. */
    CredentialsRef: string | null;
    /** `ActivitySyncConnection.Mailbox`, so a factory can scope or validate what it builds. */
    Mailbox: string | null;
    /** The plugin key this connection resolved to, for a factory serving more than one provider. */
    DriverClass: string;
    /**
     * Who the run is acting as.
     *
     * MJ's Credentials engine documents `contextUser` as REQUIRED server-side, so a factory that
     * resolves a credential cannot do its job without it. It is optional here because a factory that
     * serves recordings needs no user at all, and requiring one would make the safe path the awkward
     * one.
     */
    ContextUser?: UserInfo;
}

/**
 * How a HOST supplies a transport for a connection.
 *
 * Providers are constructed by `MJGlobal.ClassFactory` with no arguments, so nothing can be injected
 * at construction. A factory is the seam that respects that: the host owns the Communication and
 * Credentials engines, and hands back a transport for a given connection or null if it cannot serve
 * one. Returning null is not an error — a host that syncs only fixtures legitimately has none.
 */
export type ActivityTransportFactory = (context: ActivityTransportContext) => ActivityMessageTransport | null;

/**
 * THE HOST REGISTRY, and why a constructor parameter was not enough.
 *
 * `ActivityTransportFactory` was declared as "how a HOST supplies a transport" and reachable only as
 * the third constructor argument — which `MJGlobal.ClassFactory` never passes, because it builds
 * plugins with no arguments. So through the engine, the only path that matters in production, no
 * factory could ever arrive. The seam was described, exported, and unreachable.
 *
 * A module-level registry is the shape that fits the constraint rather than fighting it: the host
 * owns the Communication and Credentials engines and registers once at bootstrap, and the provider
 * asks for one at Configure time.
 *
 * A transport or factory passed to the CONSTRUCTOR still wins. Tests and the demo supply their own,
 * and a process-wide registration must not be able to reach in and replace it.
 */
let hostFactory: ActivityTransportFactory | null = null;

/**
 * Register the factory this host serves transports from. Pass null to clear it.
 *
 * Idempotent and last-call-wins, deliberately: a host that boots twice in one process (tests, a
 * reload) must not end up with two, and there is no sensible way to merge them.
 */
export function RegisterActivityTransportFactory(factory: ActivityTransportFactory | null): void {
    hostFactory = factory;
}

/** The registered factory, or null when this host serves none. */
export function HostActivityTransportFactory(): ActivityTransportFactory | null {
    return hostFactory;
}

/**
 * WHAT A HOST MUST WRITE DOWN BEFORE IT MAY READ A REAL MAILBOX.
 *
 * `MSGraphProvider` authenticates app-only, so the `Mail.Read` APPLICATION permission is granted
 * against the tenant and not against a mailbox: it reads EVERY mailbox in the organisation. The
 * `Mailbox` on a connection narrows what we ASK for, not what we are ALLOWED to read. The only thing
 * that narrows the grant is an Exchange Application Access Policy binding the app registration to a
 * mail-enabled security group.
 *
 * So the opt-in is not a boolean. A boolean records that somebody wanted live fetch; this records
 * that somebody CHECKED, which group they found, and who is answerable for it — the things an audit
 * actually asks for, and the things a person is forced to look up rather than guess. `Confirmed` is
 * the literal `true` rather than `boolean` deliberately: a variable that happens to be false will
 * not type-check, so the attestation cannot be satisfied by passing a flag through.
 */
export interface LiveMailboxPolicyAttestation {
    /** Literal `true`. See above — a `boolean` variable is rejected by the compiler. */
    Confirmed: true;
    /** The mail-enabled security group the Exchange policy scopes the app registration to. */
    ScopedToGroup: string;
    /** Who verified it. A person, so the decision has an owner. */
    ConfirmedBy: string;
    /** When they verified it. Policies get deleted; a stale attestation should be visible as stale. */
    ConfirmedAt: Date;
}

let hostLivePolicy: LiveMailboxPolicyAttestation | null = null;

/**
 * Record that this host is scoped, and may therefore read real mailboxes. Pass null to revoke.
 *
 * DELIBERATELY NOT DRIVEN BY DATA. `ActivitySyncConnection` is an ordinary editable entity, and
 * anyone who can edit a row could otherwise turn on tenant-wide mail reading by typing in a form.
 * The same reasoning already applies to the transport itself — "a database row should not be able to
 * reach in and swap it" — and it applies with more force here. This is a bootstrap-time decision in
 * code, made by whoever deploys the host.
 *
 * The blank checks are the point rather than defensive noise: an attestation with an empty group or
 * no name records nothing, and silently accepting one would turn this back into a boolean.
 */
export function AllowLiveMailboxFetch(attestation: LiveMailboxPolicyAttestation | null): void {
    if (attestation === null) {
        hostLivePolicy = null;
        return;
    }
    if (!attestation.ScopedToGroup?.trim()) {
        throw new Error(
            'AllowLiveMailboxFetch requires ScopedToGroup — the mail-enabled security group the ' +
                'Exchange Application Access Policy binds the app registration to. Run ' +
                'Get-ApplicationAccessPolicy to find it.',
        );
    }
    if (!attestation.ConfirmedBy?.trim()) {
        throw new Error('AllowLiveMailboxFetch requires ConfirmedBy — who verified the policy.');
    }
    hostLivePolicy = attestation;
}

/** The recorded attestation, or null when this host has not opted in. */
export function HostLiveMailboxPolicy(): LiveMailboxPolicyAttestation | null {
    return hostLivePolicy;
}

/** Whether this host has attested that its app registration is scoped. */
export function HostAllowsLiveMailboxFetch(): boolean {
    return hostLivePolicy !== null;
}
