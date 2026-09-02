/**
 * @fileoverview The run vocabulary: activation, dry run, per-message decisions, and the
 * provider→connection→rule policy chain.
 *
 * Everything here is pure. That is deliberate — these are the decisions a reviewer most needs to be
 * able to reason about without a database, and the ones a dry run exists to preview.
 *
 * @module @mj-biz-apps/common-activity-sync
 */

/** Mirrors `CK_ActivitySyncConnection_Status`. */
export type ConnectionStatus = 'Active' | 'Paused' | 'Error' | 'Disabled';

/** Mirrors `CK_ActivitySyncRun_TriggerType`. */
export type SyncTriggerType = 'Scheduled' | 'Manual' | 'Webhook' | 'Backfill';

/** Mirrors `CK_ActivitySyncRunDetail_Decision`. */
export type SyncDecision =
    | 'Included'
    | 'Excluded'
    | 'Duplicate'
    | 'Failed'
    /** Dry-run outcomes. Nothing was written; this is what WOULD have happened. */
    | 'WouldInclude'
    | 'WouldExclude';

/** Mirrors the `SkippedContentPolicy` CHECKs on both the provider type and the connection. */
export type SkippedContentPolicy = 'None' | 'SubjectEncrypted' | 'FullEncrypted';

export interface SyncRunOptions {
    /**
     * Evaluate and report without writing.
     *
     * A dry run fetches, qualifies and resolves exactly as a real run does, then writes only the
     * `ActivitySyncRun` and its details — never an `Activity`, never an `ActivityLink`, never an
     * attachment, and it never advances the watermark. It is the only safe way to see what a rule
     * set would do to a real mailbox before pointing it at one, and `CK_ActivitySyncRun_DryRunNoWatermark`
     * enforces the watermark half at the database rather than trusting the engine.
     */
    DryRun: boolean;
    TriggerType: SyncTriggerType;
    /** Hard cap on items fetched this pass. */
    Limit: number;
}

/**
 * Whether a connection should sync right now.
 *
 * `Status` is the master switch; `StartAt`/`EndAt` are an activation WINDOW, so a mailbox can be
 * provisioned in advance or retired on a date without anyone remembering to flip a switch. Both
 * bounds are open when null, and the window only ever narrows what `Status` already allows.
 */
export function IsConnectionActive(
    status: ConnectionStatus,
    startAt: Date | null,
    endAt: Date | null,
    now: Date,
): boolean {
    /**
     * `Error` retries. `Paused` and `Disabled` are a person deciding the mailbox
     * is off and must be honoured. `Error` is a record of the last run and says
     * nothing about whether the next one will work — refusing it latches a
     * throttle into a permanent stop.
     */
    if (status !== 'Active' && status !== 'Error') {
        return false;
    }
    if (startAt !== null && now.getTime() < startAt.getTime()) {
        return false;
    }
    if (endAt !== null && now.getTime() > endAt.getTime()) {
        return false;
    }
    return true;
}

/**
 * Resolve a policy down the chain, most specific wins, `null` meaning "inherit".
 *
 * The chain is always provider type → connection → (where it applies) rule. An operator configures
 * storage, encryption and caps ONCE per provider; a connection overrides only when that mailbox is
 * genuinely different. That is the difference between configuring a fleet and configuring a mailbox
 * at a time.
 */
export function ResolvePolicy<T>(providerDefault: T, ...overrides: (T | null | undefined)[]): T {
    for (let i = overrides.length - 1; i >= 0; i--) {
        const candidate = overrides[i];
        if (candidate !== null && candidate !== undefined) {
            return candidate;
        }
    }
    return providerDefault;
}

/**
 * Whether captured content may be retained for a message the engine declined to ingest.
 *
 * Retention is only ever permissible ENCRYPTED, so a policy above `None` without a key is not a
 * configuration to honour — it is a misconfiguration to refuse. The database enforces the same pair
 * on both ends (`CK_ActivitySyncProviderType_KeyRequired`, `CK_ActivitySyncRunDetail_ContentKey`);
 * this is the runtime half, so the engine fails loudly rather than silently writing plaintext or
 * silently writing nothing.
 */
export function ResolveCapturePlan(
    policy: SkippedContentPolicy,
    encryptionKeyID: string | null,
): { Capture: 'None' | 'Subject' | 'Full'; EncryptionKeyID: string | null } {
    if (policy === 'None') {
        return { Capture: 'None', EncryptionKeyID: null };
    }
    if (encryptionKeyID === null) {
        throw new Error(
            `SkippedContentPolicy is "${policy}" but no encryption key is configured. Retaining ` +
                `content from a message that was deliberately not ingested is only permissible ` +
                `encrypted — set an encryption key on the provider type or the connection, or set ` +
                `the policy to "None".`,
        );
    }
    return { Capture: policy === 'SubjectEncrypted' ? 'Subject' : 'Full', EncryptionKeyID: encryptionKeyID };
}

/** The dry-run counterpart of a decision, so a preview never claims to have written anything. */
export function AsDryRunDecision(decision: SyncDecision): SyncDecision {
    switch (decision) {
        case 'Included':
            return 'WouldInclude';
        case 'Excluded':
            return 'WouldExclude';
        default:
            return decision;
    }
}
