/**
 * @fileoverview The qualification cascade for a `Tagged` connection.
 *
 * ORDER, AND WHY:
 * 1. `ConsentBlock` — drafts, meeting invitations sent as mail, automatic replies. Nothing makes
 *    these business correspondence, so no consent reaches them.
 * 2. `Exclusions` — the never-log list. A tag does not outrank it: the list exists for addresses
 *    that must never be filed, however a rep labels the mail.
 * 3. `Rules`, EXCLUDE-ONLY — internal-only threads, date windows. An Include rule is read as
 *    "undecided" here, because an Include rule is a broad match and the point of this mode is that
 *    a broad match is not consent.
 * 4. `Consent` — the owner's tag, or a proven reply to / ancestor of a tagged message. Anything else
 *    is EXCLUDED here, explicitly, with a reason that says whether a known contact was on it, so the
 *    weekly "untagged mail with your contacts" count needs no content stored.
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import { BlockReason, IsSensitive, type ConsentGrant } from './consent.js';
import type { IQualificationStage, QualificationContext, QualificationVerdict } from './qualification.js';
import { ExclusionStage, RulesStage, type EngineQualificationContext } from './stages.js';
import type { ActivitySourceKind, NormalizedItem } from './types.js';

export interface ConsentQualificationContext extends EngineQualificationContext {
    /** Keyed by the item's (stable) ExternalID. */
    Consent: ReadonlyMap<string, ConsentGrant>;
    Kind: ActivitySourceKind;
    Tag: string;
}

/** The reason prefixes the withdrawal pass reads back from ActivitySyncRunDetail. */
export const REASON_TAGGED = 'Tagged';
export const REASON_PROVEN = 'Proven';
export const REASON_UNTAGGED_KNOWN = 'Not tagged; a known contact is on it';
export const REASON_UNTAGGED = 'Not tagged';

export class ConsentBlockStage implements IQualificationStage {
    public readonly Name = 'ConsentBlock';
    public readonly RequiresInference = false;

    public async Evaluate(item: NormalizedItem, context: QualificationContext): Promise<QualificationVerdict> {
        const ctx = context as ConsentQualificationContext;
        const reason = BlockReason(item.Raw, ctx.Kind);
        return reason
            ? { Decision: 'Exclude', Reason: `Never captured: ${reason}`, StageName: this.Name }
            : { Decision: 'Undecided', Reason: 'Not blocked', StageName: this.Name };
    }
}

/** RulesStage, with Include read as Undecided. See the module comment. */
export class ExcludeOnlyRulesStage implements IQualificationStage {
    public readonly Name = 'Rules';
    public readonly RequiresInference = false;
    private readonly inner = new RulesStage();

    public async Evaluate(item: NormalizedItem, context: QualificationContext): Promise<QualificationVerdict> {
        const verdict = await this.inner.Evaluate(item, context);
        if (verdict.Decision !== 'Include') return verdict;
        return {
            Decision: 'Undecided',
            Reason: `Rule ${verdict.ActivitySyncRuleID} would include, but a Tagged connection needs the owner's tag`,
            StageName: this.Name,
        };
    }
}

export class ConsentStage implements IQualificationStage {
    public readonly Name = 'Consent';
    public readonly RequiresInference = false;

    public async Evaluate(item: NormalizedItem, context: QualificationContext): Promise<QualificationVerdict> {
        const ctx = context as ConsentQualificationContext;
        const grant = ctx.Consent.get(item.ExternalID); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
        if (grant?.Kind === 'Tag') {
            return { Decision: 'Include', Reason: `${REASON_TAGGED} "${ctx.Tag}" by the mailbox owner`, StageName: this.Name };
        }
        if (grant) {
            // Only continuation is checked for sensitivity. A tag is the owner's explicit choice about
            // this item; a continuation is an inference about it, and a Private mark overrides that.
            if (IsSensitive(item.Raw, ctx.Kind)) {
                return { Decision: 'Exclude', Reason: 'In a tagged thread, but marked Personal/Private/Confidential', StageName: this.Name };
            }
            const relation = grant.Kind === 'Reply' ? 'reply to' : 'earlier message in the chain of';
            return { Decision: 'Include', Reason: `${REASON_PROVEN} ${relation} ${grant.Via}`, StageName: this.Name };
        }
        const known = item.Participants.some((p) => ctx.KnownAddresses?.has(p.Address.trim().toLowerCase()));
        return { Decision: 'Exclude', Reason: known ? REASON_UNTAGGED_KNOWN : REASON_UNTAGGED, StageName: this.Name };
    }
}

export function ConsentStages(): IQualificationStage[] {
    return [new ConsentBlockStage(), new ExclusionStage(), new ExcludeOnlyRulesStage(), new ConsentStage()];
}
