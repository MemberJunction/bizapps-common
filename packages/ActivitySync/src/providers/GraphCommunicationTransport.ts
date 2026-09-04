/**
 * The live transport: MJ's Communication MS Graph provider, with credentials from MJ's Credentials
 * engine.
 *
 * WRAPS, DOES NOT REIMPLEMENT. `BaseActivitySyncProvider` already states the rule — "Providers WRAP
 * existing plumbing rather than reinventing transport: MJ Communication providers for Gmail and
 * Microsoft Graph" — and this is that rule finally being followed. MJ's `MSGraphProvider` already
 * owns token acquisition (`ClientSecretCredential`), the client cache, paging and `$filter`
 * construction. Rebuilding any of it here would fork behaviour MJ maintains.
 *
 * WHY IT READS SourceData RATHER THAN Messages. `GetMessagesResult.Messages` is MJ's normalized
 * shape, and it is lossy for this purpose: `GetMessages` sets `To` from `replyTo[0]`, which is right
 * for replying and wrong for recording who a message was addressed to. `SourceData` carries Graph's
 * own payload verbatim, which is what `GraphMessageMapper` is written against and what
 * `NormalizedItem.Raw` is meant to preserve.
 *
 * THE CREDENTIAL IS NEVER HELD. It is resolved per fetch and passed straight into the call.
 * `clientSecret` is flagged `isSecret` on the "Azure Service Principal" credential type, so MJ
 * decrypts it at load and it lives only for the duration of the request. It is never logged, never
 * cached on this object, and never interpolated into an issue string.
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import type { BaseCommunicationProvider } from '@memberjunction/communication-types';
import type { UserInfo } from '@memberjunction/core';

import type { ActivitySourceQuery, RawBatch } from '../types.js';
import type { ActivityMessageTransport } from './MessageTransport.js';

/**
 * The credential type used, BY NAME. "Azure Service Principal" rather than "OAuth2 Client
 * Credentials": both are seeded, but only this one carries `tenantId`, and MJ's `MSGraphProvider`
 * needs a tenant to build its authority URL.
 */
export const GRAPH_CREDENTIAL_TYPE = 'Azure Service Principal';

/** The name MJ registers its Graph communication provider under. Must match its `@RegisterClass`. */
export const GRAPH_COMMUNICATION_PROVIDER = 'Microsoft Graph';

/** What this transport needs from MJ's Credentials engine. */
export interface GraphServicePrincipal {
    tenantId: string;
    clientId: string;
    clientSecret: string;
}

/** The slice of MJ's communication provider this uses. Structural, to avoid a hard runtime import. */
export interface GraphMessageReader {
    GetMessages(
        params: {
            Identifier?: string;
            NumMessages: number;
            UnreadOnly?: boolean;
            ContextData?: Record<string, unknown>;
        },
        credentials?: unknown,
    ): Promise<{
        Success: boolean;
        Messages?: unknown[];
        SourceData?: unknown[];
        ErrorMessage?: string;
        AppliedFilters?: unknown;
    }>;
}

/**
 * COMPILE-TIME PROOF THAT THE STRUCTURAL TYPE ABOVE IS NOT FICTION.
 *
 * `GraphMessageReader` is declared structurally so this package takes no runtime dependency on the
 * Communication provider. The cost of that choice is that nothing checked the shape against MJ: the
 * only value ever assigned to it is a test stub, and that stub is cast with `as unknown as`, which
 * bypasses checking entirely. A drift in MJ's `GetMessages` would therefore have surfaced on the
 * FIRST LIVE CALL and nowhere earlier — the exact class of silent failure this package keeps being
 * designed against.
 *
 * So the compiler is made to check it instead. `@memberjunction/communication-types` is already a
 * declared peer and this is a TYPE-only import, so no runtime dependency is added and these lines
 * emit no JavaScript. If MJ changes the signature, the BUILD breaks here rather than a live sync.
 */
type AssertTrue<T extends true> = T;
export type GraphMessageReaderMatchesMJ = AssertTrue<
    BaseCommunicationProvider extends GraphMessageReader ? true : false
>;

/**
 * How the two collaborators are obtained.
 *
 * Injected rather than imported so this package takes no hard RUNTIME dependency on the
 * Communication or Credentials engines — a host that syncs only fixtures should not have to install
 * either. Both are peer dependencies, for their types.
 */
export interface GraphTransportDeps {
    ResolveCredential(): Promise<GraphServicePrincipal>;
    ResolveProvider(): Promise<GraphMessageReader>;
    ContextUser?: UserInfo;
}

export class GraphCommunicationTransport implements ActivityMessageTransport {
    public readonly Describe = 'Microsoft Graph (live, via MJ Communication)';
    public readonly IsLive = true;

    public constructor(private readonly Deps: GraphTransportDeps) {}

    public async Fetch(query: ActivitySourceQuery): Promise<RawBatch> {
        const issues: string[] = [];

        const credential = await this.Deps.ResolveCredential();
        const missing = (['tenantId', 'clientId', 'clientSecret'] as const).filter(
            (k) => !String(credential?.[k] ?? '').trim(),
        );
        if (missing.length > 0) {
            // Field NAMES are reported, never values. The names are what an operator needs in order
            // to fix it, and one of the values is a secret.
            throw new Error(
                `The "${GRAPH_CREDENTIAL_TYPE}" credential is missing required field(s): ${missing.join(', ')}. ` +
                    'Complete it in MJ before enabling live fetch.',
            );
        }

        const provider = await this.Deps.ResolveProvider();

        // NO DATE BOUND IS SENT YET, DELIBERATELY. `GetMessages` has no date parameter, and the
        // one operation that does — `SearchMessages`, whose FromDate/ToDate become a plain
        // `receivedDateTime` $filter — returns only MJ's normalized Messages with no SourceData,
        // which this transport cannot use (see the module header). Expressing "since the
        // watermark" on GetMessages today would mean ContextData.Filter — a provider-specific
        // escape hatch that ALSO silently discarded any other clause. MemberJunction/MJ#4123 adds
        // ReceivedAfter to GetMessages and fixes that overwrite. Until it publishes, the window is
        // applied downstream in Normalize, which already filters on query.Since. The cost is
        // over-fetching rather than a correctness gap — EXCEPT that Limit bounds the read, so a
        // mailbox holding more than Limit messages newer than the watermark will not drain in one
        // pass. Hence the issue recorded below rather than silence.
        //
        // `accountEmail` IS REQUIRED BY MJ. `MSGraphProvider.resolveCredentials` validates four
        // fields — tenantId, clientId, clientSecret AND accountEmail — before it does anything, and
        // the "Azure Service Principal" credential carries only the first three. Without this the
        // very first live call fails with "Missing required credentials: accountEmail" on any host
        // that does not happen to export AZURE_ACCOUNT_EMAIL, which is exactly the machine-specific
        // failure this transport exists to end. The request path already targets `Identifier`, so
        // the value here only satisfies validation — and the mailbox named in the query is the one
        // correct value per connection, where a host-wide environment variable could never be.
        //
        // `disableEnvironmentFallback` MAKES THE HEADER'S PROMISE ENFORCED. MJ resolves each field as
        // "the value passed, else the AZURE_* environment variable". Without this flag a credential
        // with a blank field would silently borrow the host's, and read whatever mailbox THAT points
        // at. With it, an incomplete credential fails loudly on the field name instead.
        const result = await provider.GetMessages(
            { Identifier: query.Mailbox, NumMessages: query.Limit },
            { ...credential, accountEmail: query.Mailbox, disableEnvironmentFallback: true },
        );

        if (!result?.Success) {
            throw new Error(result?.ErrorMessage?.trim() || `Graph returned no result for mailbox "${query.Mailbox}".`);
        }

        const payloads = (result.SourceData ?? []) as Record<string, unknown>[];

        // A FULL PAGE MEANS THERE MAY BE MORE, WATERMARK OR NOT.
        //
        // This used to require `query.Since`, which left the FIRST run — the one most likely to
        // overflow a page — unprotected. No date bound is sent, so Graph returns the newest `Limit`
        // messages; `BaseActivitySyncProvider` then computes a high watermark from them and the next
        // run asks for everything AFTER the newest. Every message older than that first page is
        // skipped permanently, and the run reports Success with no issue. A mailbox with more history
        // than one page silently loses all of it.
        //
        // `Capped` also withholds the watermark upstream, which is what actually prevents the loss;
        // the issue below is how anyone finds out a re-run is needed.
        const capped = payloads.length >= query.Limit;
        if (capped) {
            const context = query.Since
                ? 'while a watermark was set, so older items may remain unread'
                : 'on a FIRST run with no watermark, so anything older than this page has not been read';
            issues.push(
                `Fetched the maximum of ${query.Limit} message(s) for "${query.Mailbox}" ${context}. ` +
                    'The watermark is being withheld so nothing is skipped — re-run to continue, or raise ' +
                    'the limit. A server-side date bound (MemberJunction/MJ#4123) removes this entirely.',
            );
        }

        // `Capped` is what actually protects the mail; the issue above only TELLS someone. Without
        // it the watermark advanced to the newest item in a truncated batch and the remainder was
        // never read again.
        return { Payloads: payloads, Issues: issues, Capped: capped };
    }
}

/**
 * Build the deps from MJ's engines, resolving both lazily.
 *
 * Separate from the class so the class stays testable with neither engine loaded — the tests inject
 * their own deps, which is also how the recorded path avoids dragging the Credentials engine into a
 * demo that has no credential to resolve.
 */
export function MJGraphTransportDeps(args: {
    CredentialName: string;
    ContextUser?: UserInfo;
    GetCredentialEngine: () => {
        getCredential<T>(name: string, options?: Record<string, unknown>): Promise<{ values: T }>;
    };
    GetCommunicationProvider: (name: string) => GraphMessageReader | null | undefined;
}): GraphTransportDeps {
    return {
        ContextUser: args.ContextUser,
        async ResolveCredential(): Promise<GraphServicePrincipal> {
            const resolved = await args
                .GetCredentialEngine()
                .getCredential<GraphServicePrincipal>(args.CredentialName, { contextUser: args.ContextUser });
            if (!resolved?.values) {
                throw new Error(`Credential "${args.CredentialName}" resolved with no values.`);
            }
            return resolved.values;
        },
        async ResolveProvider(): Promise<GraphMessageReader> {
            const provider = args.GetCommunicationProvider(GRAPH_COMMUNICATION_PROVIDER);
            if (!provider) {
                // A REGISTRATION problem, not a credential one. Saying which keeps an operator from
                // hunting for a secret that is present and correct.
                throw new Error(
                    `MJ communication provider "${GRAPH_COMMUNICATION_PROVIDER}" is not registered. ` +
                        'Ensure @memberjunction/communication-ms-graph is loaded in this host.',
                );
            }
            return provider;
        },
    };
}
