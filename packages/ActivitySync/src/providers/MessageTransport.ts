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
