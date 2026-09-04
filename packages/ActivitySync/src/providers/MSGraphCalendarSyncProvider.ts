/**
 * Microsoft Graph calendar.
 *
 * WHAT CHANGED. This class declared a `GraphEventFetcher` seam that NOTHING IMPLEMENTED, reachable
 * only as the second constructor argument — which `MJGlobal.ClassFactory` never passes, because it
 * builds plugins with no arguments. So through the engine every calendar fetch returned
 * `Payloads: []` and logged "no transport is wired". Written, typechecked, exported and refused:
 * the same defect `MSGraphActivitySyncProvider` had before its transport landed, one surface over.
 *
 * It now uses the same `ActivityMessageTransport` seam as mail, served by the same host factory,
 * which dispatches on `DriverClass`. `GraphCalendarTransport` wraps MJ's `GetEvents`; a recorded
 * transport replays captured payloads through the same mapper.
 *
 * THE TENANT-WIDE READ IS STILL REFUSED BY DEFAULT, and for the same reason as mail: app-only
 * `Calendars.Read` reads EVERY calendar in the tenant until an Exchange policy scopes the app
 * registration. It is the SAME policy and the SAME attestation — a host that has confirmed it for
 * mail has confirmed it for calendar, so this reads `AllowLiveMailboxFetch` rather than inventing a
 * second switch someone could set to only half the truth.
 */
import { RegisterClass } from '@memberjunction/global';

import { BaseActivitySyncProvider } from '../BaseActivitySyncProvider.js';
import type { ActivitySourceQuery, ItemParticipant, NormalizedItem, RawBatch } from '../types.js';
import { HostActivityTransportFactory, HostAllowsLiveMailboxFetch } from './MessageTransport.js';
import type {
    ActivityMessageTransport,
    ActivityTransportContext,
    ActivityTransportFactory,
} from './MessageTransport.js';

export const LIVE_GRAPH_CALENDAR_REFUSAL =
    'Live Graph calendar fetch is disabled. App-only auth makes Calendars.Read tenant-wide, ' +
    'so it reads EVERY calendar until an Exchange Application Access Policy scopes the app ' +
    'registration to a security group — the same policy Mail.Read needs. Confirm it exists ' +
    'before enabling this, and use FixtureActivitySyncProvider until then. Once confirmed, call ' +
    'AllowLiveMailboxFetch() at host bootstrap with the group the policy names.';

export const NO_CALENDAR_TRANSPORT_REFUSAL =
    'No calendar transport was supplied. Construct this provider with a GraphCalendarTransport ' +
    '(live) or a RecordedMessageTransport (replay).';

export const NO_CALENDAR_CREDENTIAL_REF_REFUSAL =
    'This ActivitySyncConnection names no credential. Set its CredentialsRef to the NAME of an ' +
    '"Azure Service Principal" credential in MJ — that column holds a Credentials engine key, ' +
    'never a secret value.';

export interface GraphAttendeeLike {
    type?: string;
    emailAddress?: { address?: string; name?: string };
}

export interface GraphEventLike {
    id?: string;
    iCalUId?: string;
    subject?: string;
    bodyPreview?: string;
    start?: { dateTime?: string; timeZone?: string };
    end?: { dateTime?: string; timeZone?: string };
    location?: { displayName?: string };
    organizer?: { emailAddress?: { address?: string; name?: string } };
    attendees?: GraphAttendeeLike[];
    isCancelled?: boolean;
    seriesMasterId?: string;
}

function normalize(value: string | null | undefined): string | null {
    const trimmed = value?.trim().toLowerCase();
    return trimmed ? trimmed : null;
}

function graphDate(slot: { dateTime?: string; timeZone?: string } | undefined): Date | null {
    const raw = slot?.dateTime?.trim();
    if (!raw) return null;
    const zone = (slot?.timeZone ?? 'UTC').trim().toUpperCase();
    if (zone !== 'UTC' && !/[Zz]|[+-]\d{2}:?\d{2}$/.test(raw)) return null;
    const stamped = /[Zz]|[+-]\d{2}:?\d{2}$/.test(raw) ? raw : `${raw}Z`;
    const parsed = new Date(stamped);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
}

/** Map one Graph event. Exported so a check can prove the mapping without a mailbox. */
export function MapGraphEvent(event: GraphEventLike, issues: string[]): NormalizedItem | null {
    const externalID = event.id?.trim();
    if (!externalID) {
        issues.push('An event carried no id and was skipped — it cannot be deduped.');
        return null;
    }
    const startedAt = graphDate(event.start);
    if (!startedAt) {
        issues.push(`Event ${externalID} had no usable start time and was skipped.`);
        return null;
    }

    const participants: ItemParticipant[] = [];
    const organizer = normalize(event.organizer?.emailAddress?.address);
    if (organizer) {
        participants.push({
            Address: organizer,
            Name: event.organizer?.emailAddress?.name ?? null,
            Role: 'Organizer',
            IdentityKind: 'Email',
        });
    }
    for (const attendee of event.attendees ?? []) {
        const address = normalize(attendee.emailAddress?.address);
        if (!address || address === organizer) continue;
        participants.push({
            Address: address,
            Name: attendee.emailAddress?.name ?? null,
            Role: 'Attendee',
            IdentityKind: 'Email',
        });
    }

    const endedAt = graphDate(event.end);
    return {
        ExternalID: externalID,
        ExternalThreadID: event.seriesMasterId?.trim() || null,
        TypeCode: 'Meeting',
        Subject: event.subject?.trim() || '(no subject)',
        Body: event.bodyPreview ?? null,
        StartedAt: startedAt,
        EndedAt: endedAt && endedAt.getTime() >= startedAt.getTime() ? endedAt : null,
        Location: event.location?.displayName?.trim() || null,
        Direction: 'Internal',
        Participants: participants,
        Cancelled: event.isCancelled === true,
        Raw: { ...event, iCalUId: event.iCalUId ?? null },
    };
}

@RegisterClass(BaseActivitySyncProvider, 'Microsoft365.Calendar')
export class MSGraphCalendarSyncProvider extends BaseActivitySyncProvider {
    public readonly Kind = 'Calendar' as const;
    public readonly ProviderTypeCode = 'Microsoft365';

    /**
     * Reflects the TRANSPORT rather than being hard-coded true.
     *
     * The engine refuses to write `Source: 'Integration'` rows from a non-live provider. While this
     * class always claimed `IsLive = true`, a replayed calendar run would have been indistinguishable
     * from a real one in the database afterwards — the exact confusion the flag exists to prevent.
     * Defaults to true with no transport, so an unconfigured provider is treated as the stricter case.
     */
    public get IsLive(): boolean {
        return this.Transport?.IsLive ?? true;
    }

    public constructor(
        /**
         * Defaults to the HOST'S ATTESTATION, and to the same one mail uses.
         *
         * A bare `false` made this unreachable in the only way that ships — `ClassFactory` passes no
         * arguments — so live calendar fetch could be enabled by tests and nothing else. It is the
         * same Exchange Application Access Policy that scopes `Mail.Read` and `Calendars.Read`, so a
         * host that has attested for one has attested for both; a second switch would let someone
         * record half a decision.
         */
        private readonly AllowLiveFetch: boolean = HostAllowsLiveMailboxFetch(),
        /** Where events come from. Without one this provider refuses rather than pretending. */
        private Transport?: ActivityMessageTransport,
        /** How a host builds a transport for a connection. See {@link Configure}. */
        private readonly Factory?: ActivityTransportFactory,
    ) {
        super();
    }

    /** Why this provider cannot fetch, decided at Configure time and reported at fetch time. */
    private ConfigurationRefusal: string | null = null;

    /**
     * Reads `ActivitySyncConnection.CredentialsRef` and builds this connection's transport from it.
     *
     * Identical in shape to the message provider's, and deliberately so: a connection configures ONE
     * credential, and both of its surfaces resolve through it. A calendar-specific path would let the
     * two disagree about which credential a connection uses.
     *
     * A transport passed to the CONSTRUCTOR wins and is never replaced — a database row must not be
     * able to reach in and swap it.
     */
    public override Configure(context: ActivityTransportContext): void {
        if (this.Transport) {
            return;
        }
        const ref = (context.CredentialsRef ?? '').trim();
        if (!ref) {
            this.ConfigurationRefusal = NO_CALENDAR_CREDENTIAL_REF_REFUSAL;
            return;
        }
        const factory = this.Factory ?? HostActivityTransportFactory();
        if (!factory) {
            this.ConfigurationRefusal =
                `This connection names credential "${ref}", but no transport factory is registered in ` +
                'this host, so the credential cannot be resolved.';
            return;
        }
        // NOT caught. A factory that throws is a host wiring fault, and swallowing it here would
        // recreate the silent misconfiguration this change exists to end.
        const built = factory(context);
        if (!built) {
            this.ConfigurationRefusal =
                `The transport factory served no transport for credential "${ref}" on driver ` +
                `"${context.DriverClass}".`;
            return;
        }
        this.Transport = built;
        this.ConfigurationRefusal = null;
    }

    protected async FetchRaw(query: ActivitySourceQuery): Promise<RawBatch> {
        // THE TENANT-WIDE REFUSAL IS CHECKED FIRST, matching the message provider. With no transport
        // and no attestation — the default construction — the useful thing to say is WHY live fetch
        // is off, not that a transport is missing. A recorded transport is exempt: the refusal exists
        // to prevent reading calendars we are not scoped to, and a replay reads none.
        if ((this.Transport?.IsLive ?? true) && !this.AllowLiveFetch) {
            const issues = [LIVE_GRAPH_CALENDAR_REFUSAL];
            if (!this.Transport && this.ConfigurationRefusal) {
                // ALSO true, and with a DIFFERENT fix. Reporting only the first sends an operator to
                // chase an Exchange policy when what is missing is a CredentialsRef or a factory.
                issues.push(this.ConfigurationRefusal);
            }
            return { Payloads: [], Issues: issues };
        }

        if (!this.Transport) {
            return { Payloads: [], Issues: [this.ConfigurationRefusal ?? NO_CALENDAR_TRANSPORT_REFUSAL] };
        }

        // Deliberately NOT caught. `BaseActivitySyncProvider.Fetch` already distinguishes a throw
        // ("could not look" — Failed, watermark preserved) from an empty batch ("looked, found
        // nothing"). Swallowing a transport failure into an empty batch would report a successful
        // sync of a calendar we never reached, and advance the watermark past it.
        return await this.Transport.Fetch(query);
    }

    protected Normalize(raw: RawBatch): NormalizedItem[] {
        const items: NormalizedItem[] = [];
        for (const payload of raw.Payloads) {
            const mapped = MapGraphEvent(payload as GraphEventLike, raw.Issues);
            if (mapped) items.push(mapped);
        }
        return items;
    }
}
