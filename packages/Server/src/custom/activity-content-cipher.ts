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
import type { UserInfo } from '@memberjunction/core';
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
     * THE USER IS NOT OPTIONAL HERE, although the engine's signature makes it look that way.
     *
     * `Encrypt` lazily calls `Config(false, contextUser)` when the engine has not been configured,
     * and `BaseEngine.Load` throws `'For server-side use of all engine classes, you must provide the
     * contextUser parameter'` on a database provider when it is absent.
     *
     * MJAPI normally configures this engine at startup — `StartupManager.Startup()` runs
     * `EncryptionStartupValidator` with a system user — and when that succeeds the lazy path never runs
     * and the missing argument would never have shown. It is the FAILURE case that matters: that
     * validator fails on any host whose key is missing or unusable (`MJ_BASE_ENCRYPTION_KEY` unset is
     * the common one), the engine stays unloaded, and the first capture then configures it lazily.
     *
     * Without the user, that reports `'you must provide the contextUser parameter'` — naming the wrong
     * fault entirely, on the one path where an operator most needs to be told their KEY is wrong. With
     * it, the engine configures and fails on the real problem. Either way the row is saved without
     * content, so the difference is entirely in whether the run issue is true.
     *
     * MJ's own `ResolverBase` passes the user at both of its call sites.
     *
     * @throws whatever `EncryptionEngine` throws for a missing or unusable key. Throwing is correct:
     *         the engine records the failure as a run issue and saves the decision without content.
     *         The alternative — returning the plaintext, or an empty string — would put unprotected
     *         content in a column whose contract is "ciphertext, always".
     */
    public async Encrypt(plaintext: string, encryptionKeyID: string, contextUser: UserInfo): Promise<string> {
        return EncryptionEngine.Instance.Encrypt(plaintext, encryptionKeyID, contextUser);
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
