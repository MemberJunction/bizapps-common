/**
 * How THIS host says it is scoped to read real mailboxes.
 *
 * WHAT IT IS PROTECTING. `MSGraphProvider` authenticates app-only, so the `Mail.Read` APPLICATION
 * permission is granted against the tenant, not against a mailbox: it reads EVERY mailbox in the
 * organisation. The `Mailbox` column on a connection narrows what we ASK for, not what we are
 * ALLOWED to read. Only an Exchange Application Access Policy, binding the app registration to a
 * mail-enabled security group, narrows the grant itself.
 *
 * WHY ENVIRONMENT AND NOT A DATABASE ROW. `ActivitySyncConnection` is an ordinary editable entity.
 * If the opt-in lived there, anyone who could edit a row could turn on tenant-wide mail reading from
 * a form. Deployment configuration is the right altitude: changing it needs access to the host, and
 * it is reviewed and deployed rather than typed. This is the same reasoning the package already
 * applies to the transport itself — "a database row should not be able to reach in and swap it".
 *
 * SET ALL THREE OR NONE. A partial configuration THROWS rather than quietly staying off. Silently
 * ignoring a half-filled opt-in is the failure this codebase keeps being written against: an
 * operator who set two of three variables would see refusals, believe the policy was wrong, and go
 * looking in Exchange for a fault that is in their .env.
 *
 * @module @mj-biz-apps/common-server
 */
import { AllowLiveMailboxFetch } from '@mj-biz-apps/common-activity-sync';

/**
 * The mail-enabled security group the Exchange assignment names — when the app IS restricted.
 *
 * Set this OR `ACTIVITY_SYNC_MAILBOX_POLICY_ACCEPTED_RISK`, never both. They record the two decisions
 * an organisation actually makes, and claiming both would say the app is simultaneously restricted
 * and knowingly unrestricted.
 */
export const ENV_GROUP = 'ACTIVITY_SYNC_MAILBOX_POLICY_GROUP';

/**
 * A sentence saying what is being accepted — when the tenant-wide grant is accepted as-is.
 *
 * Adding an API permission in Entra and creating an Exchange RBAC assignment are different jobs owned
 * by different people, and plenty of deployments will do the first and not the second. That is a
 * legitimate outcome; refusing to model it would leave those deployments inventing a group name or
 * bypassing the gate, and both destroy the record this exists to keep.
 */
export const ENV_ACCEPTED_RISK = 'ACTIVITY_SYNC_MAILBOX_POLICY_ACCEPTED_RISK';
/** Who verified the policy exists. A person — the decision needs an owner. */
export const ENV_CONFIRMED_BY = 'ACTIVITY_SYNC_MAILBOX_POLICY_CONFIRMED_BY';
/** When they verified it, as an ISO-8601 date. Policies get deleted; staleness should be visible. */
export const ENV_CONFIRMED_AT = 'ACTIVITY_SYNC_MAILBOX_POLICY_CONFIRMED_AT';

/** Required whichever decision was made. */
const ALWAYS = [ENV_CONFIRMED_BY, ENV_CONFIRMED_AT] as const;
/** Exactly one of these says WHICH decision it was. */
const EITHER = [ENV_GROUP, ENV_ACCEPTED_RISK] as const;

/**
 * Read the attestation from the environment and register it, if this host has one.
 *
 * Returns true when live fetch was enabled, false when the host is not configured for it. Throws
 * only on a configuration that is present but wrong — see "set all three or none" above.
 *
 * @param env the environment to read; injected so this is testable without mutating process.env.
 */
export function LoadLiveMailboxPolicyFromEnv(env: NodeJS.ProcessEnv = process.env): boolean {
    const set = (k: string) => (env[k] ?? '').trim();
    const present = [...ALWAYS, ...EITHER].filter((k) => set(k).length > 0);

    if (present.length === 0) {
        // The ordinary case for every host that has not opted in. Not an error, and not logged as
        // one — the provider's own refusal already explains what is off and how to turn it on.
        return false;
    }

    const missingAlways = ALWAYS.filter((k) => !set(k));
    if (missingAlways.length > 0) {
        throw new Error(
            `Live mailbox fetch is partially configured: ${missingAlways.join(', ')} missing. Whichever ` +
                'decision was made, it needs a name and a date — a partial opt-in stays OFF, and silently ' +
                'doing so would send you looking for an Exchange fault that is not there.',
        );
    }

    const group = set(ENV_GROUP);
    const acceptedRisk = set(ENV_ACCEPTED_RISK);

    // EXACTLY ONE. Both would claim the app is restricted AND knowingly unrestricted; neither leaves
    // the decision unstated while the other variables imply one was made.
    if (group && acceptedRisk) {
        throw new Error(
            `Set ${ENV_GROUP} or ${ENV_ACCEPTED_RISK}, not both. The first says the app is restricted to ` +
                'a group; the second says the tenant-wide grant was accepted as-is. They cannot both be true.',
        );
    }
    if (!group && !acceptedRisk) {
        throw new Error(
            `Set ${ENV_GROUP} when an Exchange assignment restricts the app to a security group, or ` +
                `${ENV_ACCEPTED_RISK} to record that the tenant-wide grant was accepted and why. Live fetch ` +
                'stays off until one of them says which.',
        );
    }

    const confirmedAt = new Date(set(ENV_CONFIRMED_AT));
    if (Number.isNaN(confirmedAt.getTime())) {
        throw new Error(`${ENV_CONFIRMED_AT} is not a valid date: "${env[ENV_CONFIRMED_AT]}". Use ISO-8601.`);
    }

    const common = { Confirmed: true as const, ConfirmedBy: set(ENV_CONFIRMED_BY), ConfirmedAt: confirmedAt };
    AllowLiveMailboxFetch(
        group
            ? { ...common, Scope: 'RestrictedToGroup', ScopedToGroup: group }
            : { ...common, Scope: 'TenantWideAccepted', AcceptedRisk: acceptedRisk },
    );
    return true;
}
