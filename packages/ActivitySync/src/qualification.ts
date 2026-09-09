/**
 * @fileoverview The qualification cascade — ordered stages, each deciding or deferring.
 *
 * ── THE ORDERING IS A PRIVACY GUARANTEE, SO IT IS ENFORCED, NOT DOCUMENTED ──────────────────────
 *
 * A stage that calls a model must never run before the deterministic stages. A message whose
 * participants match no known contact is discarded having been read only by a string comparison;
 * putting inference first would send the contents of every message in a mailbox — including the
 * private ones — to a third party.
 *
 * {@link RunQualificationCascade} therefore REJECTS a stage list where a local stage follows an
 * inference stage, rather than trusting the caller to order it correctly. A comment could be
 * ignored by the next person to add a stage; a thrown error cannot.
 *
 * ── AND ABSTENTION IS FIRST-CLASS ────────────────────────────────────────────────────
 *
 * A stage that is not confident returns `Undecided` instead of guessing. When every stage abstains,
 * the provider type's default policy decides — and for anything mailbox-shaped that default is
 * `Exclude`. Capturing a private message is worse than missing a business one, so the cascade fails
 * CLOSED.
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import { NormalizedItem } from './types.js';

export type QualificationDecision = 'Include' | 'Exclude' | 'Undecided';

/** What an `Undecided` chain resolves to. Mirrors `ActivitySyncProviderType.DefaultQualificationPolicy`. */
export type QualificationPolicy = 'Include' | 'Exclude';

/**
 * The cascade's fail-closed default.
 *
 * `ActivitySyncProviderTypeID` is nullable, and a host install currently ships
 * zero provider-type rows until a release-engineer Metadata_Sync. Whatever the
 * engine passes as `RunQualificationCascade`'s last argument *is* the real
 * default — `ResolvePolicy`'s first parameter is required, so a missing type
 * cannot silently fall through.
 *
 * Only an explicit `'Include'` on the type row opts in. Null, missing, empty,
 * or any other value is `'Exclude'`. A `?? 'Include'` at the engine call site
 * would defeat the cascade while every test still passed.
 */
export function DefaultPolicyFromProviderType(
    policy: string | null | undefined,
): QualificationPolicy {
    return policy === 'Include' ? 'Include' : 'Exclude';
}

/** One stage's answer. `Reason` is always populated — including on `Include`, so a capture is explicable. */
export interface QualificationVerdict {
    Decision: QualificationDecision;
    Reason: string;
    StageName: string;
    /** 0–1 where a stage can express one. Absent for deterministic stages, which are certain or abstain. */
    Confidence?: number;
    /** Set when the verdict came from an AI Prompt, for trace. */
    AIPromptRunID?: string;
    /**
     * The rule or exclusion that decided, when one did.
     *
     * Carried on the verdict rather than reconstructed by the caller, because these are what
     * `ActivitySyncRunDetail` records — and "which rule ate my message" is the question the run log
     * exists to answer. A verdict that cannot name its cause makes the log a narrative instead of
     * evidence.
     */
    ActivitySyncRuleID?: string;
    ActivitySyncExclusionID?: string;
}

/** Whatever a stage needs beyond the item itself — known addresses, the connection's rules, and so on. */
export interface QualificationContext {
    ConnectionID: string;
    /** Provider type `Code`, for stages that behave differently per source. */
    ProviderTypeCode: string;
}

export interface IQualificationStage {
    readonly Name: string;
    /**
     * True when this stage sends item content to a model.
     *
     * Load-bearing: the cascade uses it to enforce that inference never precedes deterministic work.
     */
    readonly RequiresInference: boolean;
    Evaluate(item: NormalizedItem, context: QualificationContext): Promise<QualificationVerdict>;
}

/**
 * Runs stages in order and returns the first decisive verdict.
 *
 * @throws if a non-inference stage follows an inference stage — see the file header.
 */
export async function RunQualificationCascade(
    stages: readonly IQualificationStage[],
    item: NormalizedItem,
    context: QualificationContext,
    defaultPolicy: QualificationPolicy,
): Promise<QualificationVerdict> {
    AssertInferenceRunsLast(stages);

    for (const stage of stages) {
        const verdict = await stage.Evaluate(item, context);
        if (verdict.Decision !== 'Undecided') {
            return verdict;
        }
    }
    return AbstainedVerdict(stages, defaultPolicy);
}

/**
 * Guards the one ordering that cannot be left to convention.
 *
 * Keyed on the CAUSE (an inference stage exists and something local follows it) rather than on a
 * position or a count, so it still holds when someone adds a fourth stage years from now.
 */
export function AssertInferenceRunsLast(stages: readonly IQualificationStage[]): void {
    let seenInference: IQualificationStage | null = null;
    for (const stage of stages) {
        if (stage.RequiresInference) {
            seenInference = stage;
            continue;
        }
        if (seenInference !== null) {
            throw new Error(
                `Qualification stage "${stage.Name}" is deterministic but is ordered AFTER the ` +
                    `inference stage "${seenInference.Name}". Inference must run last: a deterministic ` +
                    `stage placed after it would let unfiltered content reach a model first.`,
            );
        }
    }
}

/** The verdict when every stage abstained. Names the policy so an operator can see why. */
function AbstainedVerdict(
    stages: readonly IQualificationStage[],
    defaultPolicy: QualificationPolicy,
): QualificationVerdict {
    const stageNames = stages.length > 0 ? stages.map((s) => s.Name).join(', ') : '(none)';
    return {
        Decision: defaultPolicy,
        StageName: 'DefaultPolicy',
        Reason:
            `No stage reached a decision (${stageNames}); the provider type's ` +
            `DefaultQualificationPolicy of "${defaultPolicy}" applied.`,
    };
}
