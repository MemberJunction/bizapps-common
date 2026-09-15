/**
 * Retaining content from a message the engine deliberately did NOT ingest.
 *
 * ── WHAT THIS IS FOR ────────────────────────────────────────────────────────────────────────────
 *
 * `ActivitySyncRunDetail` records that a message was seen and excluded. For some deployments the
 * decision alone is not enough: an auditor asking "what was in the message you declined to file?"
 * needs an answer, and "we no longer have it" is a bad one. `SkippedContentPolicy` is that switch,
 * and `CapturedContent` is where the answer goes.
 *
 * ── WHY IT WAS WRITTEN AND NEVER WIRED ──────────────────────────────────────────────────────────
 *
 * Every piece of this existed before this change and none of it was reachable.
 * `DefaultSkippedContentPolicy` and `DefaultEncryptionKeyID` on the provider type, their overrides
 * on the connection, `CapturedContent` and `EncryptionKeyID` on the run detail, two CHECK
 * constraints enforcing that ciphertext and key travel together, and `ResolveCapturePlan` — written,
 * documented and unit-tested — with zero callers.
 *
 * So an operator could set `SkippedContentPolicy` to `SubjectEncrypted`, point it at a key, watch
 * runs complete successfully, and retain nothing. The misconfiguration `ResolveCapturePlan` exists to
 * refuse — a policy above `None` with no key — never fired either, because nothing called it.
 *
 * ── WHY A SEAM RATHER THAN AN IMPORT ────────────────────────────────────────────────────────────
 *
 * `CapturedContent` is documented as "Ciphertext, always — never plaintext, whatever the policy...
 * Encrypted through MJ's EncryptionEngine against an MJ: Encryption Keys row; this app never
 * implements its own crypto." This package holds to the second half of that: it takes no runtime
 * dependency on the Encryption engine, and asks a host for a cipher the same way it asks for a
 * transport factory.
 *
 * The difference from `ActivityFileSink`, and the reason this one is not the same defect again:
 * `common-server` FILLS this seam at bootstrap, beside the transport factory and the mailbox policy.
 * A seam nothing implements is exactly what this package keeps being fixed for, so the implementation
 * ships with the interface.
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import type { NormalizedItem } from './types.js';

/**
 * Turns plaintext into the ciphertext stored in `ActivitySyncRunDetail.CapturedContent`.
 *
 * Deliberately narrow: one method, strings in and out, no key management and no decryption. Reading
 * captured content back is an audit action performed by a person with the key, not something the
 * sync engine ever needs to do, and an engine that cannot decrypt cannot leak.
 */
export interface ActivityContentCipher {
    /**
     * @param plaintext what to protect.
     * @param encryptionKeyID the `MJ: Encryption Keys` row to encrypt against.
     * @returns the ciphertext to store. Throwing is correct when the key is missing or unusable —
     *          the caller records the failure as a run issue rather than storing plaintext.
     */
    Encrypt(plaintext: string, encryptionKeyID: string): Promise<string>;
}

let hostCipher: ActivityContentCipher | null = null;

/**
 * Register the cipher this host protects captured content with. Pass null to clear it.
 *
 * Idempotent and last-call-wins, matching the transport factory and the file sink: a host that boots
 * twice in one process must not end up with two.
 */
export function RegisterActivityContentCipher(cipher: ActivityContentCipher | null): void {
    hostCipher = cipher;
}

/** The registered cipher, or null on a host that cannot encrypt. */
export function HostActivityContentCipher(): ActivityContentCipher | null {
    return hostCipher;
}

/**
 * The plaintext a capture plan calls for, or null when it calls for nothing.
 *
 * `Subject` keeps the one line that identifies the message to a human. `Full` adds the body, which is
 * the whole point of the stronger setting — an auditor asking what was in a declined message is
 * asking about the body.
 *
 * A subject-only capture of a message with no subject still returns the placeholder rather than null:
 * "(no subject)" is a fact about the message, and returning null here would make an empty capture
 * indistinguishable from a policy that captured nothing.
 */
export function ContentToCapture(capture: 'None' | 'Subject' | 'Full', item: NormalizedItem): string | null {
    if (capture === 'None') return null;
    const subject = item.Subject?.trim() || '(no subject)';
    if (capture === 'Subject') return subject;
    const body = item.Body?.trim();
    return body ? `${subject}\n\n${body}` : subject;
}
