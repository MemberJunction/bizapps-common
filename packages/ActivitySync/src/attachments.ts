/**
 * Which attachments an included activity should keep.
 *
 * WHY THIS EXISTS. `ActivitySyncRule.IncludeAttachments` describes itself as "1 = also pull
 * attachments into ActivityFile rows", `MaxAttachmentBytes` sits beside it, and the `ActivityFile`
 * table with its `Kind` value list (Body / Attachment / Ics) is migrated and in metadata — and
 * nothing anywhere read any of it. A rule that asked for attachments got none, silently. That is the
 * same shape as the `CredentialsRef` and `InternalDomains` gaps: schema and documentation written
 * ahead of the wiring, with every test passing because nothing exercised the unwired path.
 *
 * DECIDED AT WRITE TIME, FROM THE RULE THAT DECIDED. Rules are evaluated after the fetch, so the
 * question "does this item want its attachments?" cannot be answered while fetching. The item
 * carries only the cheap `HasAttachments` flag; this turns that plus the winning rule into an
 * instruction, and the expensive per-message attachment call is paid only for items that were
 * actually included by a rule that asked.
 *
 * @module @mj-biz-apps/common-activity-sync
 */

/** The rule fields this consults. Structural, so a caller need not carry a whole RuleRow. */
export interface AttachmentRuleFields {
    IncludeAttachments?: boolean | null;
    MaxAttachmentBytes?: number | null;
}

/** What an attachment looks like before it is stored. Mirrors MJ's `MessageAttachment`. */
export interface AttachmentCandidate {
    ID: string;
    Filename: string;
    ContentType: string;
    Size: number;
    IsInline?: boolean;
    ContentID?: string;
}

export interface AttachmentPolicy {
    /** Whether to go and get the attachment list at all. */
    Fetch: boolean;
    /** Skip anything larger. Null means no cap. */
    MaxBytes: number | null;
}

/** Why a candidate was not kept. Reported, never silent — see {@link SelectAttachments}. */
export type AttachmentSkipReason = 'inline' | 'too-large' | 'no-size';

export interface AttachmentSelection {
    Keep: AttachmentCandidate[];
    Skipped: { Filename: string; Size: number; Reason: AttachmentSkipReason }[];
}

/**
 * Turn the deciding rule plus the item's flag into an instruction.
 *
 * NO RULE MEANS NO ATTACHMENTS. An item can be included by the KnownParticipant stage or by a
 * provider-type default policy rather than by a rule, and neither expresses an attachment choice.
 * Defaulting to "fetch" there would pull every attachment in a mailbox on the strength of a decision
 * nobody made about attachments — the expensive, surprising direction to be wrong in.
 */
export function AttachmentPolicyFor(
    rule: AttachmentRuleFields | null | undefined,
    item: { HasAttachments?: boolean },
): AttachmentPolicy {
    const wanted = rule?.IncludeAttachments === true;
    // No point paying for a list when the source already said there is nothing to list.
    const fetch = wanted && item?.HasAttachments === true;
    const cap = rule?.MaxAttachmentBytes;
    return {
        Fetch: fetch,
        // 0 and negative are treated as "no cap" rather than "keep nothing": a cap of zero is far
        // more likely to be an unset column than a deliberate instruction to discard everything.
        MaxBytes: typeof cap === 'number' && cap > 0 ? cap : null,
    };
}

/**
 * Choose which candidates to keep, and record why the rest were dropped.
 *
 * EVERY EXCLUSION IS REPORTED. Silently dropping a 30MB signed contract because it exceeded a cap is
 * the failure this whole package keeps being written against: the sync reports success, the activity
 * is filed, and the thing someone actually wanted is missing with nothing to show it ever existed.
 *
 * INLINE ATTACHMENTS ARE DROPPED BY DEFAULT. They are body furniture — signature logos, tracking
 * pixels, embedded screenshots already visible in the body text — and `ActivityFile.Kind` has a
 * separate `Body` for the body itself. Keeping them would fill file storage with corporate logos,
 * one copy per email. They are still reported, so a deployment that wants them can see what it is
 * missing rather than wonder.
 */
export function SelectAttachments(
    candidates: readonly AttachmentCandidate[],
    policy: AttachmentPolicy,
): AttachmentSelection {
    const selection: AttachmentSelection = { Keep: [], Skipped: [] };
    if (!policy.Fetch) return selection;

    for (const candidate of candidates) {
        if (candidate.IsInline === true) {
            selection.Skipped.push({ Filename: candidate.Filename, Size: candidate.Size, Reason: 'inline' });
            continue;
        }
        // A missing or nonsensical size with a cap in force cannot be checked. Keeping it would let
        // exactly the oversize file the cap exists to stop through the one gap in the check.
        if (policy.MaxBytes !== null && !(typeof candidate.Size === 'number' && candidate.Size >= 0)) {
            selection.Skipped.push({ Filename: candidate.Filename, Size: -1, Reason: 'no-size' });
            continue;
        }
        if (policy.MaxBytes !== null && candidate.Size > policy.MaxBytes) {
            selection.Skipped.push({ Filename: candidate.Filename, Size: candidate.Size, Reason: 'too-large' });
            continue;
        }
        selection.Keep.push(candidate);
    }
    return selection;
}

/**
 * The human-readable account of what was dropped, or null when nothing was.
 *
 * One line per reason rather than per file: a message with forty inline logos should not produce
 * forty issues and bury the one that says a contract was too large.
 */
export function AttachmentSkipReport(
    externalID: string,
    selection: AttachmentSelection,
): string | null {
    if (selection.Skipped.length === 0) return null;

    const byReason = new Map<AttachmentSkipReason, string[]>();
    for (const s of selection.Skipped) {
        const list = byReason.get(s.Reason) ?? [];
        list.push(s.Filename);
        byReason.set(s.Reason, list);
    }

    const phrases: string[] = [];
    const inline = byReason.get('inline');
    if (inline) phrases.push(`${inline.length} inline (body images, not filed as attachments)`);
    const large = byReason.get('too-large');
    if (large) phrases.push(`${large.length} over the size cap: ${large.join(', ')}`);
    const noSize = byReason.get('no-size');
    if (noSize) phrases.push(`${noSize.length} of unknown size, skipped because a cap is in force: ${noSize.join(', ')}`);

    return `Message ${externalID}: attachments not stored — ${phrases.join('; ')}.`;
}

/**
 * Where attachment bytes go.
 *
 * A SEAM, NOT AN IMPLEMENTATION, and for the same reason the transport is one: storing a file means
 * MJ's `FileStorageEngine` plus a configured `FileStorageAccount`, and a host that syncs only
 * metadata should need neither. The host that has them registers a sink; one that has not gets a
 * reported refusal rather than activities quietly filed without the attachments their rule asked for.
 *
 * `ActivityFile` holds a `FileID` — a foreign key into `__mj.File` — not the bytes. So an
 * implementation's job is to put the bytes wherever this deployment keeps files, create the `File`
 * row, and hand back its id for linking.
 */
export interface ActivityFileSink {
    /**
     * Store one attachment and return the `__mj.File` id to link, or null when it could not be
     * stored. Null rather than a throw: one unstorable attachment should not lose the activity and
     * every other attachment on it, and the caller reports what did not land.
     */
    Store(input: {
        Attachment: AttachmentCandidate;
        /** The activity being written, for naming and for the link that follows. */
        ActivityID: string;
        /** The source item, so a sink can fetch bytes it was not handed. */
        ExternalID: string;
    }): Promise<{ FileID: string } | null>;
}
