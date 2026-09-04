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

/** The mail-enabled security group the Exchange Application Access Policy names. */
export const ENV_GROUP = 'ACTIVITY_SYNC_MAILBOX_POLICY_GROUP';
/** Who verified the policy exists. A person — the decision needs an owner. */
export const ENV_CONFIRMED_BY = 'ACTIVITY_SYNC_MAILBOX_POLICY_CONFIRMED_BY';
/** When they verified it, as an ISO-8601 date. Policies get deleted; staleness should be visible. */
export const ENV_CONFIRMED_AT = 'ACTIVITY_SYNC_MAILBOX_POLICY_CONFIRMED_AT';

const ALL = [ENV_GROUP, ENV_CONFIRMED_BY, ENV_CONFIRMED_AT] as const;

/**
 * Read the attestation from the environment and register it, if this host has one.
 *
 * Returns true when live fetch was enabled, false when the host is not configured for it. Throws
 * only on a configuration that is present but wrong — see "set all three or none" above.
 *
 * @param env the environment to read; injected so this is testable without mutating process.env.
 */
export function LoadLiveMailboxPolicyFromEnv(env: NodeJS.ProcessEnv = process.env): boolean {
    const present = ALL.filter((k) => (env[k] ?? '').trim().length > 0);

    if (present.length === 0) {
        // The ordinary case for every host that has not opted in. Not an error, and not logged as
        // one — the provider's own refusal already explains what is off and how to turn it on.
        return false;
    }
    if (present.length < ALL.length) {
        const missing = ALL.filter((k) => !present.includes(k));
        throw new Error(
            `Live mailbox fetch is partially configured: ${present.join(', ')} set, but ` +
                `${missing.join(', ')} missing. Set all three or none — a partial opt-in stays OFF, ` +
                'and silently doing so would send you looking for an Exchange fault that is not there.',
        );
    }

    const confirmedAt = new Date((env[ENV_CONFIRMED_AT] as string).trim());
    if (Number.isNaN(confirmedAt.getTime())) {
        throw new Error(`${ENV_CONFIRMED_AT} is not a valid date: "${env[ENV_CONFIRMED_AT]}". Use ISO-8601.`);
    }

    // AllowLiveMailboxFetch does its own blank checks; reaching it with blanks is impossible here,
    // but it stays the single place those rules live rather than being restated.
    AllowLiveMailboxFetch({
        Confirmed: true,
        ScopedToGroup: (env[ENV_GROUP] as string).trim(),
        ConfirmedBy: (env[ENV_CONFIRMED_BY] as string).trim(),
        ConfirmedAt: confirmedAt,
    });
    return true;
}
