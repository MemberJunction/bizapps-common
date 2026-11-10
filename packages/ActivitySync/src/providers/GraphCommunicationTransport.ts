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

/**
 * How many requests one mail pass may make while it looks for a date window that fits `Limit`.
 *
 * Each request is one `GetMessages` call of at most `Limit` messages. Halving a window that holds
 * too much converges in about log2(span / fitting width) requests, so this covers a span of decades
 * down to a window of minutes; a pass that runs out says so rather than looping.
 */
export const DEFAULT_MAX_MAIL_REQUESTS = 16;

/** A window narrower than this that still overflows a page is reported, not narrowed further. */
const MIN_MAIL_WINDOW_MS = 1_000;

/** The slice of MJ's communication provider this uses. Structural, to avoid a hard runtime import. */
export interface GraphMessageReader {
    GetMessages(
        params: {
            Identifier?: string;
            NumMessages: number;
            UnreadOnly?: boolean;
            ReceivedAfter?: Date;
            ReceivedBefore?: Date;
            ContextData?: Record<string, unknown>;
        },
        credentials?: unknown,
    ): Promise<{
        Success: boolean;
        Messages?: unknown[];
        SourceData?: unknown[];
        ErrorMessage?: string;
        AppliedFilters?: { ReceivedAfter?: boolean; ReceivedBefore?: boolean };
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

    public constructor(
        private readonly Deps: GraphTransportDeps,
        private readonly MaxRequests: number = DEFAULT_MAX_MAIL_REQUESTS,
        /** Injectable so a test can pin the end of the window without freezing global time. */
        private readonly Now: () => Date = () => new Date(),
    ) {}

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
        const drain = await this.drain(provider, credential, query);
        return this.toBatch(drain, query, issues);
    }

    /**
     * Read the mailbox OLDEST WINDOW FIRST, so a backlog larger than one page still drains (#308).
     *
     * WHY NOT ONE REQUEST. MJ's `GetMessages` sends `$top` with no `$orderby` and no paging, so one
     * request of `Limit` returns the newest `Limit` messages. When more than that arrived since the
     * watermark, the watermark was withheld and the next run sent the same request and got the same
     * page back: the older mail was never read on any run.
     *
     * HOW. `ReceivedAfter`/`ReceivedBefore` (inclusive, Graph `ge`/`le`) bound a window starting at
     * the watermark. A window whose page comes back SHORT holds nothing more, so everything received
     * up to its end has been read and the next window starts there, twice as wide. A FULL page says
     * only that the window holds too much, whatever order Graph returned it in, so the window is
     * narrowed and read again. Progress is kept across runs through the watermark itself: a pass that
     * stops before reaching now reports `ReadThrough`, the end of the last window it drained.
     *
     * Messages from a full page are not kept. Drained windows are kept only while their total stays
     * within `Limit`, so a pass never returns more than one page's worth.
     */
    private async drain(
        provider: GraphMessageReader,
        credential: GraphServicePrincipal,
        query: ActivitySourceQuery,
    ): Promise<MailDrain> {
        const now = this.Now();
        const state: MailDrain = { Drained: [], FirstPage: [], ReadThrough: null, Requests: 0, Stop: 'Budget' };
        const seen = new Set<string>();
        let cursor = query.Since ?? new Date(0);
        let width = Math.max(now.getTime() - cursor.getTime(), MIN_MAIL_WINDOW_MS);
        while (state.Requests < this.MaxRequests) {
            const hi = new Date(cursor.getTime() + width);
            const open = hi.getTime() >= now.getTime();
            const after = cursor.getTime() > 0 ? cursor : undefined;
            const page = await this.readPage(provider, credential, query, after, open ? undefined : hi);
            state.Requests++;
            if (state.Requests === 1) state.FirstPage = page.Payloads;
            const full = page.Payloads.length >= query.Limit;
            if (!full && (open || page.Bounded)) {
                // Drained: everything in this window is on this page. Taken only while the pass stays
                // within Limit; past that the window is left for the next run, which starts here.
                const merged = keepNew(state.Drained, page.Payloads, seen);
                if (merged.length > query.Limit) return state;
                state.Drained = merged;
                if (open) return { ...state, Stop: 'CaughtUp' };
                state.ReadThrough = hi;
                cursor = hi;
                width *= 2;
                continue;
            }
            if (!page.Bounded) return { ...state, Stop: 'Unbounded' };
            width = narrowedWidth(cursor, open ? now : hi, page.Payloads);
            if (width < MIN_MAIL_WINDOW_MS) return { ...state, Stop: 'Crowded', CrowdedAt: cursor };
        }
        return state;
    }

    /**
     * One `GetMessages` request, and whether Graph applied the bounds it was sent.
     *
     * `accountEmail` IS REQUIRED BY MJ. `MSGraphProvider.resolveCredentials` validates four fields —
     * tenantId, clientId, clientSecret AND accountEmail — before it does anything, and the "Azure
     * Service Principal" credential carries only the first three. The request path already targets
     * `Identifier`, so the value here only satisfies validation, and the mailbox named in the query
     * is the one correct value per connection, where a host-wide environment variable could never be.
     *
     * `disableEnvironmentFallback` MAKES THE HEADER'S PROMISE ENFORCED. MJ resolves each field as
     * "the value passed, else the AZURE_* environment variable". Without this flag a credential with
     * a blank field would silently borrow the host's, and read whatever mailbox THAT points at.
     *
     * A BOUND GRAPH IGNORED IS NOT A BOUND. MJ documents that a provider unable to filter by date
     * returns unfiltered results rather than failing; `AppliedFilters` is how that is told apart.
     */
    private async readPage(
        provider: GraphMessageReader,
        credential: GraphServicePrincipal,
        query: ActivitySourceQuery,
        after: Date | undefined,
        before: Date | undefined,
    ): Promise<{ Payloads: Record<string, unknown>[]; Bounded: boolean }> {
        const result = await provider.GetMessages(
            { Identifier: query.Mailbox, NumMessages: query.Limit, ReceivedAfter: after, ReceivedBefore: before },
            { ...credential, accountEmail: query.Mailbox, disableEnvironmentFallback: true },
        );
        if (!result?.Success) {
            throw new Error(result?.ErrorMessage?.trim() || `Graph returned no result for mailbox "${query.Mailbox}".`);
        }
        const applied = result.AppliedFilters;
        const bounded =
            (!after || applied?.ReceivedAfter === true) && (!before || applied?.ReceivedBefore === true);
        return { Payloads: (result.SourceData ?? []) as Record<string, unknown>[], Bounded: bounded };
    }

    /**
     * What the drain read, as a batch the provider base understands.
     *
     * Caught up: the drained mail, and the watermark comes from its newest item as before. Drained
     * part of the way: the drained mail, NOT capped, with `ReadThrough` so the watermark moves to the
     * end of the last drained window and the next run starts there. Drained nothing: the first page,
     * CAPPED, so the watermark is withheld — the old behaviour, now reached only when the date bound
     * cannot help, and saying why.
     */
    private toBatch(drain: MailDrain, query: ActivitySourceQuery, issues: string[]): RawBatch {
        if (drain.Stop === 'CaughtUp') {
            return { Payloads: drain.Drained, Issues: issues };
        }
        const reason = stopReason(drain, query);
        if (drain.ReadThrough) {
            issues.push(
                `Read mail for "${query.Mailbox}" received through ${drain.ReadThrough.toISOString()} in ` +
                    `${drain.Requests} request(s); newer mail remains and the next run continues from there. ${reason}`.trim(),
            );
            return { Payloads: drain.Drained, Issues: issues, ReadThrough: drain.ReadThrough };
        }
        // `Capped` is what actually protects the mail; the issue only TELLS someone. Without it the
        // watermark would advance to the newest item in a truncated batch and the rest never be read.
        const context = query.Since
            ? 'while a watermark was set, so older items may remain unread'
            : 'on a FIRST run with no watermark, so anything older than this page has not been read';
        issues.push(
            `Fetched the maximum of ${query.Limit} message(s) for "${query.Mailbox}" ${context}. ` +
                `The watermark is being withheld so nothing is skipped. ${reason}`.trim(),
        );
        return { Payloads: drain.FirstPage, Issues: issues, Capped: true };
    }
}

/** Where a drain stopped, and what it had when it did. */
interface MailDrain {
    /** Every message from windows that came back short, de-duplicated by Graph id. At most `Limit`. */
    Drained: Record<string, unknown>[];
    /** The first request's page, returned when nothing could be drained. */
    FirstPage: Record<string, unknown>[];
    /** End of the last drained window; null when none was. */
    ReadThrough: Date | null;
    Requests: number;
    Stop: 'CaughtUp' | 'Budget' | 'Unbounded' | 'Crowded';
    /** For `Crowded`: the instant more than one page of mail arrived within a second of. */
    CrowdedAt?: Date;
}

function stopReason(drain: MailDrain, query: ActivitySourceQuery): string {
    switch (drain.Stop) {
        case 'Unbounded':
            return 'Graph did not apply the received-date bound, so a re-run reads this same page; raise the limit.';
        case 'Crowded':
            return (
                `More than ${query.Limit} message(s) were received within one second of ` +
                `${drain.CrowdedAt?.toISOString()}; raise the limit.`
            );
        case 'Budget':
            return drain.ReadThrough
                ? ''
                : `No date window narrow enough to fit the limit was found in ${drain.Requests} request(s); raise the limit.`;
        default:
            return '';
    }
}

/**
 * The width of the next window to try after `[from, to]` overflowed a page: half of it, or less when
 * the page itself shows that everything it returned arrived later than that. Graph returns newest
 * first in practice, so the oldest message on a full page is usually where the unread mail begins;
 * nothing relies on that, it only lets the window shrink faster.
 *
 * Zero when every message on the page was received AT `from`: no narrower window can hold fewer.
 */
function narrowedWidth(from: Date, to: Date, page: readonly Record<string, unknown>[]): number {
    let width = Math.floor((to.getTime() - from.getTime()) / 2);
    let allAtStart = page.length > 0;
    for (const message of page) {
        const raw = message.receivedDateTime;
        const at = typeof raw === 'string' ? new Date(raw).getTime() : NaN;
        if (Number.isNaN(at) || at > from.getTime()) allAtStart = false;
        if (!Number.isNaN(at) && at > from.getTime()) width = Math.min(width, at - from.getTime());
    }
    return allAtStart ? 0 : width;
}

/** `kept` plus whatever in `page` it does not already hold by Graph id. Windows share their boundary instant. */
function keepNew(
    kept: Record<string, unknown>[],
    page: readonly Record<string, unknown>[],
    seen: Set<string>,
): Record<string, unknown>[] {
    const out = [...kept];
    for (const message of page) {
        const id = typeof message.id === 'string' ? message.id : '';
        if (id && seen.has(id)) continue;
        if (id) seen.add(id);
        out.push(message);
    }
    return out;
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
