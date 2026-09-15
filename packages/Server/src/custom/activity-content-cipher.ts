/**
 * The cipher this host protects captured content with.
 *
 * WHAT IT IS FOR. `ActivitySyncRunDetail.CapturedContent` holds content from messages the engine
 * deliberately declined to ingest, kept so an auditor asking "what was in the message you did not
 * file?" has an answer. Its own description settles how: *"Ciphertext, always — never plaintext,
 * whatever the policy... Encrypted through MJ's EncryptionEngine against an MJ: Encryption Keys row;
 * this app never implements its own crypto."*
 *
 * WHY IT LIVES HERE. `common-activity-sync` holds to the second half of that sentence by taking no
 * runtime dependency on the Encryption engine and asking a host for a cipher instead. This package
 * already depends on MJ's engines, already runs at MJAPI startup, and already fills the other two
 * seams the same way — so it fills this one too.
 *
 * That last part is the whole point. A seam nothing implements is the defect this subsystem keeps
 * being cleaned of: `ActivityFileSink` is exported, documented and registered, and its `Store()` has
 * no caller on any real path. This interface ships WITH its implementation so it never reaches that
 * state.
 *
 * @module @mj-biz-apps/common-server
 */
import { EncryptionEngine } from '@memberjunction/encryption';
import { RegisterActivityContentCipher, type ActivityContentCipher } from '@mj-biz-apps/common-activity-sync';

/**
 * Encrypts through MJ, and does nothing else.
 *
 * NO DECRYPTION, deliberately. `ActivityContentCipher` has one method because the sync engine never
 * needs to read captured content back — that is an audit action performed by a person holding the
 * key. An engine that cannot decrypt cannot leak, and keeping the interface to one direction means
 * the capability is not sitting there to be misused later.
 */
export class MJActivityContentCipher implements ActivityContentCipher {
    /**
     * @throws whatever `EncryptionEngine` throws for a missing or unusable key. Throwing is correct:
     *         the engine records the failure as a run issue and saves the decision without content.
     *         The alternative — returning the plaintext, or an empty string — would put unprotected
     *         content in a column whose contract is "ciphertext, always".
     */
    public async Encrypt(plaintext: string, encryptionKeyID: string): Promise<string> {
        return EncryptionEngine.Instance.Encrypt(plaintext, encryptionKeyID);
    }
}

/**
 * Register it. Called from `LoadBizAppsCommonServer` at MJAPI startup.
 *
 * Unconditional, and cheap to be so: registering a cipher does not turn retention on. Retention is
 * off unless a provider type or connection sets `SkippedContentPolicy` above `None`, and the engine
 * refuses to run at all if a policy asks for capture that this host cannot encrypt. Registering
 * always means that refusal is about the POLICY being wrong, never about the host being half-wired.
 */
export function LoadActivityContentCipher(): void {
    RegisterActivityContentCipher(new MJActivityContentCipher());
}
