/**
 * The live calendar transport: MJ's Communication MS Graph provider, with credentials from MJ's
 * Credentials engine.
 *
 * WRAPS, DOES NOT REIMPLEMENT — and until recently there was nothing to wrap. `MSGraphProvider` could
 * send, read, reply, forward, draft, move, archive, search and subscribe, and had no calendar API at
 * all, while the piece that would have made one possible (`getGraphClient`, which owns token
 * acquisition and the credential-keyed client cache) is private. Building a client here would have
 * forked exactly the behaviour `BaseActivitySyncProvider` says to wrap. So calendar retrieval was
 * added to MJ first and this wraps it.
 *
 * WHY IT READS SourceData RATHER THAN Events. `GetEventsResult.Events` is MJ's normalized shape and
 * is deliberately thin; `MapGraphEvent` in this package is written against Graph's own `event`
 * resource and reads fields the normalized form drops (`iCalUId`, attendee `type`, `bodyPreview`
 * nuances). `SourceData` carries the payload verbatim, which is what `NormalizedItem.Raw` is meant to
 * preserve. Same choice, for the same reason, as the message transport.
 *
 * THE CREDENTIAL IS NEVER HELD. Resolved per fetch and passed straight into the call. `clientSecret`
 * is flagged `isSecret` on the "Azure Service Principal" credential type, so MJ decrypts it at load
 * and it lives only for the duration of the request. Never logged, never cached on this object,
 * never interpolated into an issue string.
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import type { BaseCommunicationProvider } from '@memberjunction/communication-types';
import type { UserInfo } from '@memberjunction/core';

import type { ActivitySourceQuery, RawBatch } from '../types.js';
import type { ActivityMessageTransport } from './MessageTransport.js';
// Reused, not redeclared: mail and calendar reach the SAME MJ provider under the same registration
// name and resolve the SAME credential type. Two copies could drift into naming different things.
import {
    GRAPH_COMMUNICATION_PROVIDER,
    GRAPH_CREDENTIAL_TYPE,
    type GraphServicePrincipal,
} from './GraphCommunicationTransport.js';

/**
 * How far back a FIRST run reaches when the connection has no calendar watermark.
 *
 * A bound is required rather than optional: `/calendarView` refuses a request without one, and the
 * alternative endpoint returns series masters instead of occurrences. Thirty days is a starting
 * point, not a rule — it is a constructor argument, and a run that falls back to it says so in its
 * issues rather than letting an operator believe the whole calendar was read.
 */
export const DEFAULT_FIRST_RUN_LOOKBACK_DAYS = 30;

/**
 * How far FORWARD a read reaches.
 *
 * Not zero, deliberately. `Activity.Status` includes `Scheduled`, so a meeting that has not happened
 * yet is a thing this schema models, and a calendar sync that only ever looked backwards could not
 * produce one.
 */
export const DEFAULT_FORWARD_HORIZON_DAYS = 30;

/** The slice of MJ's communication provider this uses. Structural, to avoid a hard runtime import. */
export interface GraphEventReader {
    GetEvents(
        params: {
            Identifier?: string;
            NumEvents: number;
            StartDateTime?: Date;
            EndDateTime?: Date;
            IncludeCancelled?: boolean;
            ContextData?: Record<string, unknown>;
        },
        credentials?: unknown,
    ): Promise<{
        Success: boolean;
        Events?: unknown[];
        SourceData?: unknown[];
        ErrorMessage?: string;
        RecurrenceExpanded?: boolean;
    }>;
}

/**
 * COMPILE-TIME PROOF THAT THE STRUCTURAL TYPE ABOVE IS NOT FICTION.
 *
 * Declared structurally so this package takes no runtime dependency on the Communication engine. The
 * cost of that is that nothing checks the shape against MJ: the only value ever assigned to it in
 * tests is a stub, and a stub cast with `as unknown as` bypasses checking entirely. Drift in MJ's
 * `GetEvents` would then surface on the FIRST LIVE CALL and nowhere earlier.
 *
 * So the compiler checks it instead. `@memberjunction/communication-types` is already a declared peer
 * and this is a TYPE-only import, so no runtime dependency is added and these lines emit no
 * JavaScript. If MJ changes the signature, the BUILD breaks here rather than a live sync.
 */
type AssertTrue<T extends true> = T;
export type GraphEventReaderMatchesMJ = AssertTrue<
    BaseCommunicationProvider extends GraphEventReader ? true : false
>;

/** How the two collaborators are obtained. Injected, so neither engine is a runtime dependency. */
export interface GraphCalendarTransportDeps {
    ResolveCredential(): Promise<GraphServicePrincipal>;
    ResolveProvider(): Promise<GraphEventReader>;
    ContextUser?: UserInfo;
}

export class GraphCalendarTransport implements ActivityMessageTransport {
    public readonly Describe = 'Microsoft Graph calendar (live, via MJ Communication)';
    public readonly IsLive = true;

    public constructor(
        private readonly Deps: GraphCalendarTransportDeps,
        private readonly LookbackDays: number = DEFAULT_FIRST_RUN_LOOKBACK_DAYS,
        private readonly ForwardDays: number = DEFAULT_FORWARD_HORIZON_DAYS,
        /** Injectable so a test can pin the window without freezing global time. */
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

        const now = this.Now();
        const start = query.Since ?? new Date(now.getTime() - this.LookbackDays * 86_400_000);
        const end = new Date(now.getTime() + this.ForwardDays * 86_400_000);

        if (!query.Since) {
            // Said out loud, because "no watermark" reads as "read everything" and this is not that.
            issues.push(
                `First calendar run for ${query.Mailbox}: no watermark, so the window starts ` +
                    `${this.LookbackDays} days back (${start.toISOString()}). Anything older was not read.`,
            );
        }

        const provider = await this.Deps.ResolveProvider();
        const result = await provider.GetEvents(
            {
                Identifier: query.Mailbox,
                NumEvents: query.Limit,
                StartDateTime: start,
                EndDateTime: end,
                // A cancellation is a real thing that happened to a meeting somebody attended, and
                // `MapGraphEvent` already carries `Cancelled` through to the Activity.
                IncludeCancelled: true,
            },
            credential,
        );

        if (!result?.Success) {
            throw new Error(
                result?.ErrorMessage?.trim() || `Graph returned no calendar result for mailbox "${query.Mailbox}".`,
            );
        }

        // BOTH BOUNDS WERE SENT, so MJ should have expanded recurrence. If it says otherwise the
        // payloads are series MASTERS, and one row would be filed for a weekly meeting at whatever
        // date the series began. That is wrong in a way no downstream check would catch, because a
        // master and an occurrence look alike.
        if (result.RecurrenceExpanded === false) {
            issues.push(
                'Graph did not expand recurring series despite a bounded window, so repeating meetings ' +
                    'are represented by their series master rather than by occurrences. Times for those ' +
                    'will be the start of the series.',
            );
        }

        const payloads = (result.SourceData ?? []) as Record<string, unknown>[];

        const capped = payloads.length >= query.Limit;
        if (capped) {
            issues.push(
                `The calendar read hit its limit of ${query.Limit} events for ${query.Mailbox}; ` +
                    'the window may hold more than this pass returned.',
            );
        }

        return { Payloads: payloads, Issues: issues, Capped: capped };
    }
}

/**
 * Build the deps from MJ's engines, resolving both lazily.
 *
 * Separate from the class so the class stays testable with neither engine loaded — the tests inject
 * their own deps, which is also how a recorded run avoids dragging the Credentials engine into a
 * replay that has no credential to resolve.
 */
export function MJGraphCalendarTransportDeps(args: {
    CredentialName: string;
    ContextUser?: UserInfo;
    GetCredentialEngine: () => {
        getCredential<T>(name: string, options?: Record<string, unknown>): Promise<{ values: T }>;
    };
    GetCommunicationProvider: (name: string) => GraphEventReader | null | undefined;
}): GraphCalendarTransportDeps {
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
        async ResolveProvider(): Promise<GraphEventReader> {
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
