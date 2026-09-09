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
