/**
 * The host's answer to "where does a live transport come from?".
 *
 * WHY THIS FILE HAD TO EXIST. `ActivityTransportFactory` was declared in the ActivitySync package as
 * "how a HOST supplies a transport", exported, documented — and NOTHING ANYWHERE BUILT ONE. A
 * connection could name a credential, the column could be set correctly, and the provider would
 * still refuse, because the seam that turns a credential name into a transport had no
 * implementation. That is the last link in the chain between a configured credential and live mail.
 *
 * WHY IT LIVES IN THE SERVER PACKAGE. ActivitySync takes MJ's Communication and Credentials engines
 * as PEER dependencies and injects them deliberately, so a host that syncs only fixtures need
 * install neither. Building the transport there would have made that impossible. The host is the
 * layer that legitimately owns both engines, so the wiring belongs here and the seam stays clean.
 *
 * @module @mj-biz-apps/common-server
 */
import { BaseCommunicationProvider } from '@memberjunction/communication-types';
import { CredentialEngine } from '@memberjunction/credentials';
import type { UserInfo } from '@memberjunction/core';
import { MJGlobal } from '@memberjunction/global';
import {
    GRAPH_COMMUNICATION_PROVIDER,
    GraphCommunicationTransport,
    MJGraphTransportDeps,
    RegisterActivityTransportFactory,
    type ActivityMessageTransport,
    type ActivityTransportContext,
    type GraphMessageReader,
} from '@mj-biz-apps/common-activity-sync';

/** The `ActivitySyncProviderType.DriverClass` this factory serves. It serves exactly one. */
const MICROSOFT_365 = 'Microsoft365';

/**
 * Build a live Graph transport for one connection, or null when this factory cannot serve it.
 *
 * NULL IS NOT AN ERROR, and the two cases below are deliberately silent rather than throwing:
 *
 *   - a DIFFERENT driver — a fixture or calendar connection is not this factory's business, and
 *     throwing would break every connection this host runs rather than the one it cannot serve;
 *   - NO CredentialsRef — the provider already has a specific, better-worded refusal for that
 *     (`NO_CREDENTIAL_REF_REFUSAL`), and pre-empting it here would replace a precise message with
 *     a vaguer one.
 *
 * Anything else is a wiring fault and is left to throw.
 */
export function GraphTransportFactory(context: ActivityTransportContext): ActivityMessageTransport | null {
    if (context.DriverClass !== MICROSOFT_365) {
        return null;
    }
    const credentialName = (context.CredentialsRef ?? '').trim();
    if (!credentialName) {
        return null;
    }

    return new GraphCommunicationTransport(
        MJGraphTransportDeps({
            CredentialName: credentialName,
            ContextUser: context.ContextUser,
            GetCredentialEngine: () => CredentialLoader(context.ContextUser),
            GetCommunicationProvider: ResolveCommunicationProvider,
        }),
    );
}

/**
 * The Credentials engine, loaded on first use rather than assumed loaded.
 *
 * `getCredential` throws "Metadata not loaded" if the engine has not been configured, and this
 * factory runs from a scheduled Action that may fire before or after anything else touches
 * credentials. `EnsureLoaded` is idempotent and joins an in-flight load rather than starting a
 * second, so paying it per resolution costs nothing after the first.
 */
function CredentialLoader(contextUser?: UserInfo) {
    return {
        async getCredential<T>(name: string, options?: Record<string, unknown>): Promise<{ values: T }> {
            const user = (options?.contextUser as UserInfo | undefined) ?? contextUser;
            await CredentialEngine.Instance.EnsureLoaded(user);
            return CredentialEngine.Instance.getCredential(name, {
                contextUser: user,
                subsystem: 'BizApps Common ActivitySync',
            }) as unknown as Promise<{ values: T }>;
        },
    };
}

/**
 * MJ's registered communication provider, by name.
 *
 * THE BASE-CLASS CHECK IS LOAD-BEARING and is copied from `CommunicationEngine.GetProvider`:
 * `ClassFactory.CreateInstance` returns an instance of the BASE class when no registration matches,
 * so a missing provider comes back as a truthy object that answers no calls usefully. Without this
 * the transport would be built, reach `GetMessages`, and fail somewhere far less informative than
 * the registration message the provider already carries.
 *
 * WHY NOT CALL `CommunicationEngine.GetProvider` ITSELF. It is this exact resolution and nothing
 * more — it consults no provider metadata and no Status — but it throws unless the engine's
 * `Config()` has loaded its five metadata entities first. That is a sending-side prerequisite this
 * read-only path has no use for, so the two lines are mirrored here rather than paying the load.
 */
function ResolveCommunicationProvider(name: string): GraphMessageReader | null {
    const instance = MJGlobal.Instance.ClassFactory.CreateInstance<BaseCommunicationProvider>(
        BaseCommunicationProvider,
        name,
    );
    if (!instance || instance.constructor.name === 'BaseCommunicationProvider') {
        return null;
    }
    return instance as unknown as GraphMessageReader;
}

/**
 * Register this host's factory. Called once from the package bootstrap.
 *
 * Registration alone changes NO behaviour on its own: `AllowLiveFetch` still defaults false, so the
 * provider still refuses a live read until someone who has confirmed the Exchange Application Access
 * Policy opts in. What this ends is the state where a correctly configured credential could not be
 * resolved at all.
 */
export function LoadGraphTransportFactory(): void {
    RegisterActivityTransportFactory(GraphTransportFactory);
}

/** Exported for tests and for a host that wants the default provider name. */
export { GRAPH_COMMUNICATION_PROVIDER };
