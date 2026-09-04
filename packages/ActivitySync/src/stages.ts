/**
 * Deterministic qualification stages. Exclusions run first and are absolute.
 */
import { ClassifyParticipants, DomainOf, MatchesParticipantScope, type ParticipantScope } from './participants.js';
import type {
    IQualificationStage,
    QualificationContext,
    QualificationVerdict,
} from './qualification.js';
import type { NormalizedItem } from './types.js';

export interface ExclusionRow {
    ID: string;
    IdentityKind: string | null;
    IdentityValue: string;
    ActivitySyncRuleSetID: string | null;
}

export interface RuleRow {
    ID: string;
    Sequence: number;
    IsEnabled: boolean;
    Action: 'Include' | 'Exclude';
    Direction: 'Inbound' | 'Outbound' | 'Internal' | null;
    DateFrom: Date | string | null;
    DateTo: Date | string | null;
    ParticipantScope: ParticipantScope | null;
    ActivitySyncRuleSetID: string | null;
    /**
     * `1 = also pull attachments into ActivityFile rows` — the column's own description.
     *
     * On the RULE rather than the connection because it is a per-decision choice: a rule that files
     * customer threads may well want the contract attached, while one filing internal chatter does
     * not. It is read at WRITE time from the rule that decided, not at fetch time, because rules run
     * after the fetch.
     */
    IncludeAttachments: boolean;
    /** Attachments larger than this are skipped and REPORTED. Null means no cap. */
    MaxAttachmentBytes: number | null;
}

export interface KnownAddressHit {
    Address: string;
}

export interface EngineQualificationContext extends QualificationContext {
    Exclusions: ExclusionRow[];
    Rules: RuleRow[];
    InternalDomains: string[];
    KnownAddresses: Map<string, KnownAddressHit>;
}

function asDate(value: Date | string | null | undefined): Date | null {
    if (value == null) return null;
    const d = value instanceof Date ? value : new Date(value);
    return Number.isNaN(d.getTime()) ? null : d;
}

/** Stage 0. An exclusion is not a rule a later Include can outrank. */
export class ExclusionStage implements IQualificationStage {
    public readonly Name = 'Exclusions';
    public readonly RequiresInference = false;

    public async Evaluate(item: NormalizedItem, context: QualificationContext): Promise<QualificationVerdict> {
        const ctx = context as EngineQualificationContext;
        const addresses = item.Participants.map((p) => p.Address.trim().toLowerCase()).filter(Boolean);
        for (const exclusion of ctx.Exclusions ?? []) {
            const needle = exclusion.IdentityValue.trim().toLowerCase().replace(/^@/, '');
            if (!needle) continue;
            for (const address of addresses) {
                const domain = DomainOf(address);
                const identityHit = address === needle || address.endsWith('@' + needle);
                const domainHit = domain === needle;
                if (identityHit || domainHit) {
                    return {
                        Decision: 'Exclude',
                        Reason: `Exclusion ${exclusion.ID} matched ${address}`,
                        StageName: this.Name,
                        ActivitySyncExclusionID: exclusion.ID,
                    };
                }
            }
        }
        return { Decision: 'Undecided', Reason: 'No exclusion matched', StageName: this.Name };
    }
}

/** Stage 1. Bound rule sets, in sequence. */
export class RulesStage implements IQualificationStage {
    public readonly Name = 'Rules';
    public readonly RequiresInference = false;

    public async Evaluate(item: NormalizedItem, context: QualificationContext): Promise<QualificationVerdict> {
        const ctx = context as EngineQualificationContext;
        const rules = [...(ctx.Rules ?? [])]
            .filter((r) => r.IsEnabled)
            .sort((a, b) => a.Sequence - b.Sequence);
        for (const rule of rules) {
            if (rule.Direction && rule.Direction !== item.Direction) continue;
            const from = asDate(rule.DateFrom);
            const to = asDate(rule.DateTo);
            if (from && item.StartedAt.getTime() < from.getTime()) continue;
            if (to && item.StartedAt.getTime() > to.getTime()) continue;
            if (rule.ParticipantScope && rule.ParticipantScope !== 'Any') {
                const composition = ClassifyParticipants(item.Participants, ctx.InternalDomains ?? []);
                if (!MatchesParticipantScope(rule.ParticipantScope, composition)) {
                    continue;
                }
            }
            return {
                Decision: rule.Action,
                Reason: `Rule ${rule.ID} ${rule.Action}`,
                StageName: this.Name,
                ActivitySyncRuleID: rule.ID,
            };
        }
        return { Decision: 'Undecided', Reason: 'No rule matched', StageName: this.Name };
    }
}

/**
 * Stage 2. Exact ContactMethod address match — never a domain match.
 * A hit Includes; no hit abstains so the provider-type default (Exclude for mailboxes) decides.
 */
export class KnownParticipantStage implements IQualificationStage {
    public readonly Name = 'KnownParticipant';
    public readonly RequiresInference = false;

    public async Evaluate(item: NormalizedItem, context: QualificationContext): Promise<QualificationVerdict> {
        const ctx = context as EngineQualificationContext;
        const known = ctx.KnownAddresses ?? new Map();
        for (const participant of item.Participants) {
            const address = participant.Address.trim().toLowerCase();
            if (address && known.has(address)) {
                return {
                    Decision: 'Include',
                    Reason: `Known contact method ${address}`,
                    StageName: this.Name,
                };
            }
        }
        return {
            Decision: 'Undecided',
            Reason: 'No participant matched a stored ContactMethod',
            StageName: this.Name,
        };
    }
}

export function DefaultDeterministicStages(): IQualificationStage[] {
    return [new ExclusionStage(), new RulesStage(), new KnownParticipantStage()];
}
