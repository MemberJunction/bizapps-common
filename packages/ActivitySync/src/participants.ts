/**
 * @fileoverview Internal vs external participants — the Outlook-rules control.
 *
 * "Internal" is not a property of a message. It is a property of the DEPLOYMENT, which is why the
 * domain list lives on `ActivitySyncRuleSet.InternalDomains` and is passed in here rather than
 * inferred. A rule that says "exclude internal-only chatter" is meaningless until someone has said
 * which domains are ours.
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import type { ItemParticipant } from './types.js';

/**
 * Which participants must be present for a rule to apply.
 *
 * Mirrors `CK_ActivitySyncRule_ParticipantScope`. `Mixed` exists because it is the case an
 * all-or-nothing rule gets wrong: a thread with three colleagues and one customer on it is neither
 * internal chatter nor an external conversation, and which of those it counts as is a decision a
 * deployment should make explicitly.
 */
export type ParticipantScope =
    | 'Any'
    | 'AllInternal'
    | 'AllExternal'
    | 'HasExternal'
    | 'HasInternal'
    | 'Mixed';

/** How a message's participants break down against the deployment's own domains. */
export interface ParticipantComposition {
    Internal: number;
    External: number;
    /** Addresses with no parseable domain. Never counted as internal — see below. */
    Unknown: number;
}

/**
 * Split participants into internal and external by domain.
 *
 * **An unclassifiable address is never treated as internal.** A malformed or domain-less address is
 * counted separately and, for every predicate below, sides with `External`. The alternative —
 * assuming an unparseable party is one of us — would let a single bad address turn a mixed thread
 * into "internal only", and an internal-only *exclusion* rule would then silently drop a real
 * customer conversation. Erring the other way costs an extra captured message, which is recoverable;
 * a silent drop is not.
 */
export function ClassifyParticipants(
    participants: readonly ItemParticipant[],
    internalDomains: readonly string[],
): ParticipantComposition {
    const domains = new Set(internalDomains.map((d) => d.trim().toLowerCase().replace(/^@/, '')));
    const composition: ParticipantComposition = { Internal: 0, External: 0, Unknown: 0 };

    for (const participant of participants) {
        const domain = DomainOf(participant.Address);
        if (domain === null) {
            composition.Unknown++;
        } else if (domains.has(domain)) {
            composition.Internal++;
        } else {
            composition.External++;
        }
    }
    return composition;
}

/** The domain part of an address, lower-cased, or null when there isn't one. */
export function DomainOf(address: string): string | null {
    const at = address.lastIndexOf('@');
    if (at < 0 || at === address.length - 1) {
        return null;
    }
    const domain = address.slice(at + 1).trim().toLowerCase();
    return domain.length > 0 ? domain : null;
}

/**
 * Whether a composition satisfies a rule's required scope.
 *
 * `Unknown` sides with external throughout, per the reasoning on {@link ClassifyParticipants}.
 */
export function MatchesParticipantScope(scope: ParticipantScope, c: ParticipantComposition): boolean {
    const external = c.External + c.Unknown;
    switch (scope) {
        case 'Any':
            return true;
        case 'AllInternal':
            return c.Internal > 0 && external === 0;
        case 'AllExternal':
            return external > 0 && c.Internal === 0;
        case 'HasExternal':
            return external > 0;
        case 'HasInternal':
            return c.Internal > 0;
        case 'Mixed':
            return c.Internal > 0 && external > 0;
    }
}

/**
 * What `ActivitySyncRuleSet.InternalDomains` holds, parsed.
 *
 * The column documents itself as "Required for any rule using ParticipantScope" and stores a JSON
 * array, e.g. `["bluecypress.io"]`. Nothing read it until now — the engine passed a hard-coded empty
 * list — so every participant classified as External and every participant rule silently inverted.
 *
 * A parse failure is NOT degraded to an empty list. Empty is the dangerous value here: it makes
 * `HasExternal` match the purely internal chatter it exists to exclude. "Internal" is a property of
 * the deployment, so guessing it is worse than refusing to run.
 */
export type InternalDomainsParse = { Ok: true; Domains: string[] } | { Ok: false; Issue: string };

/** Parse one rule set's `InternalDomains`. Blank and null are legitimately "none declared". */
export function ParseInternalDomains(raw: string | null | undefined, ruleSetName: string): InternalDomainsParse {
    const text = (raw ?? '').trim();
    if (!text) return { Ok: true, Domains: [] };

    let parsed: unknown;
    try {
        parsed = JSON.parse(text);
    } catch {
        return {
            Ok: false,
            Issue: `Rule set "${ruleSetName}" has InternalDomains that is not valid JSON. Expected an array like ["bluecypress.io"].`,
        };
    }
    if (!Array.isArray(parsed)) {
        return {
            Ok: false,
            Issue: `Rule set "${ruleSetName}" has InternalDomains that is not a JSON array. Expected e.g. ["bluecypress.io"].`,
        };
    }
    const domains: string[] = [];
    for (const entry of parsed) {
        // Normalised exactly as ClassifyParticipants normalises what it compares against, so a list
        // written "@Bluecypress.IO" still matches an address at bluecypress.io.
        const d = String(entry ?? '').trim().toLowerCase().replace(/^@/, '');
        if (d && !domains.includes(d)) domains.push(d);
    }
    return { Ok: true, Domains: domains };
}

/**
 * The warning for rules that test participants when no domain list exists.
 *
 * Returns null when there is nothing to say. This is a WARNING rather than a refusal because the run
 * is still meaningful — the rules simply do not filter the way they read, and saying so is the
 * difference between a surprising sync and an inexplicable one.
 */
export function ParticipantScopeWarning(
    rules: readonly { ParticipantScope?: string | null }[],
    internalDomains: readonly string[],
): string | null {
    if (internalDomains.length > 0) return null;
    const scoped = rules.filter((r) => r.ParticipantScope && r.ParticipantScope !== 'Any');
    if (scoped.length === 0) return null;
    return (
        `${scoped.length} rule(s) test ParticipantScope, but no bound rule set defines InternalDomains. ` +
        'Every participant therefore counts as External, so those rules do not filter what they appear ' +
        'to. Set InternalDomains on the rule set.'
    );
}
