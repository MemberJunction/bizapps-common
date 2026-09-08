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
    /**
     * Whether this exclusion is switched on. Rules honoured their `IsEnabled` from the start;
     * exclusions did not, so switching one off left it excluding.
     */
    IsEnabled: boolean;
    /**
     * The window of ITEMS this exclusion covers — matched against `item.StartedAt`, exactly as
     * `RuleRow.DateFrom`/`DateTo` are. Null on either end is unbounded.
     *
     * ITEM TIME, NOT RUN TIME, and the choice is not free. Two date windows sit in one cascade; if an
     * exclusion's window meant "while this record is in force" and a rule's meant "which items it
     * covers", the same two dates would mean different things one stage apart. It also keeps a re-run
     * reproducible: `ActivitySyncRunDetail` exists to answer "which rule ate my message", and an answer
     * that changes with the wall clock is a narrative rather than evidence.
     */
    EffectiveFrom: Date | string | null;
    EffectiveTo: Date | string | null;
}

/**
 * Whether an exclusion applies to an item that occurred at `occurredAt`.
 *
 * Pure and exported so the three ways an exclusion can fail to apply — switched off, too early, too
 * late — can be pinned without standing up a cascade.
 */
export function ExclusionAppliesTo(
    exclusion: Pick<ExclusionRow, 'IsEnabled' | 'EffectiveFrom' | 'EffectiveTo'>,
    occurredAt: Date,
): boolean {
    if (exclusion.IsEnabled === false) return false;
    const from = asDate(exclusion.EffectiveFrom);
    if (from && occurredAt.getTime() < from.getTime()) return false;
    const to = asDate(exclusion.EffectiveTo);
    if (to && occurredAt.getTime() > to.getTime()) return false;
    return true;
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

/**
 * A date bound, or nothing. `RunView` hands back a `Date` or the string it came as, depending on how
 * the row was loaded, so both are accepted.
 *
 * The `NaN` guard looks removable and is not. Every caller today only ever compares the result with
 * `<` or `>`, and those are false against `NaN` in both directions, so an Invalid Date happens to fall
 * through exactly like `null` — dropping the guard changes no current behaviour, which is why no test
 * can catch its removal. It stays because it is what makes the return type honest: the next caller to
 * do anything else with a bound (`toISOString()` throws a `RangeError` on an Invalid Date) inherits a
 * value that is either a usable date or `null`, rather than a third case nobody thought about.
 */
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
            // Switched off, or outside the window of items it covers. Neither was checked before, so a
            // disabled exclusion kept excluding and one set to lapse never lapsed.
            if (!ExclusionAppliesTo(exclusion, item.StartedAt)) continue;
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
