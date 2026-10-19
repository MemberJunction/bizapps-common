/**
 * Contact consent, the pure part: the status values, how a current status is resolved from a
 * history, and how a channel decision is made from the statuses of a person's contact methods.
 *
 * Consent is recorded per contact method (each email, each phone), never per person, because a
 * person can be opted in on a home email and opted out on a work email. The current status lives
 * on `ContactMethod.ConsentStatus`; every change is a `ContactConsentHistory` row, and the status
 * always equals the row with the latest `ConsentStatusAt`. These functions hold that rule so the
 * entity subclass, the engine and the tests all agree on it.
 */
import type { mjBizAppsCommonContactConsentHistoryEntity, mjBizAppsCommonContactMethodEntity } from './generated/entity_subclasses';

/**
 * The consent states a contact method can be in. Derived from the generated entity, so it follows
 * `CK_ContactMethod_ConsentStatus` whenever CodeGen regenerates.
 */
export type ContactConsentStatus = mjBizAppsCommonContactMethodEntity['ConsentStatus'];

/**
 * The same values as a runtime list, in the order the CHECK constraint names them, for dropdowns.
 * A type cannot produce a list, so this is written out; {@link CONSENT_STATUS_LIST_COMPLETE} fails
 * the build if the generated union ever has a value this list lacks.
 */
export const CONTACT_CONSENT_STATUSES = ['NotSpecified', 'OptedIn', 'OptedOut'] as const satisfies readonly ContactConsentStatus[];

type StatusListIsComplete = [Exclude<ContactConsentStatus, (typeof CONTACT_CONSENT_STATUSES)[number]>] extends [never]
    ? true
    : 'CONTACT_CONSENT_STATUSES is missing a value the ConsentStatus CHECK constraint allows';

/** Compile-time proof that {@link CONTACT_CONSENT_STATUSES} covers the generated union. */
export const CONSENT_STATUS_LIST_COMPLETE: StatusListIsComplete = true;

/** The source recorded when a staff member changes consent in a form rather than through an import or a link. */
export const CONSENT_SOURCE_STAFF = 'Staff';

/**
 * The channels Comms can ask about. Each is the `Type` key of a row MJ core seeds in
 * `MJ: Communication Base Message Types`; `ContactPreferenceEngine` resolves a channel to that
 * row's ID and matches contact types on the foreign key, never on a name.
 */
export const CONTACT_CHANNELS = ['Email', 'Phone', 'SMS'] as const;

export type ContactChannel = (typeof CONTACT_CHANNELS)[number];

/** The two columns of a history row that resolution needs. */
export type ConsentHistoryEntry = Pick<mjBizAppsCommonContactConsentHistoryEntity, 'NewConsentStatus' | 'ConsentStatusAt'>;

/** True when `value` is one of the consent statuses. */
export function IsContactConsentStatus(value: unknown): value is ContactConsentStatus {
    return typeof value === 'string' && (CONTACT_CONSENT_STATUSES as readonly string[]).includes(value);
}

/**
 * The current status implied by a history: the entry with the latest `ConsentStatusAt`.
 *
 * An empty history means nothing was ever recorded, so `NotSpecified`. Two entries at the same
 * instant resolve to the later one in the array, which is the one recorded later.
 */
export function ResolveCurrentConsent(history: ReadonlyArray<ConsentHistoryEntry>): ContactConsentStatus {
    let latest: ConsentHistoryEntry | null = null;
    for (const entry of history) {
        if (!latest || entry.ConsentStatusAt.getTime() >= latest.ConsentStatusAt.getTime()) {
            latest = entry;
        }
    }
    return latest?.NewConsentStatus ?? 'NotSpecified';
}

/**
 * Whether a change that took effect at `at` is the newest one, given the history so far.
 *
 * A change that is not the newest is still recorded, but it does not move the current status. That
 * is how a late-arriving import with an older date is kept without overwriting a newer opt-out.
 */
export function IsLatestConsentChange(history: ReadonlyArray<ConsentHistoryEntry>, at: Date): boolean {
    return history.every((entry) => entry.ConsentStatusAt.getTime() <= at.getTime());
}

/** Why a channel decision came out the way it did. */
export type ContactDecisionStatus =
    /** At least one contact method on the channel is opted in. */
    | 'OptedIn'
    /** Every contact method on the channel is opted out. */
    | 'OptedOut'
    /** Nothing on the channel is opted in and at least one method has no recorded consent. */
    | 'NotSpecified'
    /** The person or organization has no contact method on that channel at all. */
    | 'NoContactMethod';

export interface ContactDecision {
    /** Whether a message may be sent on the channel. */
    Allowed: boolean;
    Status: ContactDecisionStatus;
    /** A short sentence for the send log, so a skipped recipient says why. */
    Reason: string;
}

export interface ContactDecisionPolicy {
    /**
     * When true, only an explicit opt-in allows contact; `NotSpecified` is treated like an opt-out.
     * Off by default, because every contact method predating this feature is `NotSpecified` and a
     * strict default would silently stop all sends on upgrade.
     */
    RequireOptIn?: boolean;
}

/**
 * Rolls the statuses of every contact method on one channel into one decision.
 *
 * An opt-in anywhere wins, because the person said yes on at least one address. With nothing opted
 * in, an unspecified status allows contact unless the policy requires an explicit opt-in. Opt-outs
 * only block when nothing else is available.
 */
export function DecideContact(
    statuses: ReadonlyArray<ContactConsentStatus>,
    channel: ContactChannel,
    policy: ContactDecisionPolicy = {},
): ContactDecision {
    if (statuses.length === 0) {
        return { Allowed: false, Status: 'NoContactMethod', Reason: `No ${channel} contact method on record.` };
    }
    if (statuses.includes('OptedIn')) {
        return { Allowed: true, Status: 'OptedIn', Reason: `Opted in on ${channel}.` };
    }
    if (statuses.includes('NotSpecified')) {
        const allowed = policy.RequireOptIn !== true;
        return {
            Allowed: allowed,
            Status: 'NotSpecified',
            Reason: allowed
                ? `No consent recorded on ${channel}; allowed because an explicit opt-in is not required.`
                : `No consent recorded on ${channel}; an explicit opt-in is required.`,
        };
    }
    return { Allowed: false, Status: 'OptedOut', Reason: `Opted out on ${channel}.` };
}
