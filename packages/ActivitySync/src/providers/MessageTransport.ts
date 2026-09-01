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
