/**
 * Microsoft Graph calendar. Written, typechecked, and refused until an Exchange
 * Application Access Policy scopes app-only Calendars.Read. Same tenant-wide
 * grant as Mail.Read; fixture is how the engine is exercised.
 */
import { LogError } from '@memberjunction/core';
import { RegisterClass } from '@memberjunction/global';

import { BaseActivitySyncProvider } from '../BaseActivitySyncProvider.js';
import type { ActivitySourceQuery, ItemParticipant, NormalizedItem, RawBatch } from '../types.js';

export const LIVE_GRAPH_CALENDAR_REFUSAL =
    'Live Graph calendar fetch is disabled. App-only auth makes Calendars.Read tenant-wide, ' +
    'so it reads EVERY calendar until an Exchange Application Access Policy scopes the app ' +
    'registration to a security group — the same policy Mail.Read needs. Confirm it exists ' +
    'before enabling this, and use FixtureActivitySyncProvider until then.';

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

export interface GraphEventFetcher {
    GetEvents(params: {
        Mailbox: string;
        Since: Date | null;
        Top: number;
    }): Promise<{ Success?: boolean; ErrorMessage?: string; Events?: GraphEventLike[] }>;
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
    public readonly IsLive = true;

    public constructor(
        private readonly AllowLiveFetch: boolean = false,
        private readonly fetcher?: GraphEventFetcher,
    ) {
        super();
    }

    protected async FetchRaw(query: ActivitySourceQuery): Promise<RawBatch> {
        if (!this.AllowLiveFetch) {
            return { Payloads: [], Issues: [LIVE_GRAPH_CALENDAR_REFUSAL] };
        }
        if (!this.fetcher) {
            LogError(`MSGraphCalendarSyncProvider.FetchRaw was enabled for ${query.Mailbox} — no transport is wired.`);
            return {
                Payloads: [],
                Issues: [
                    'Live Graph calendar fetch was opted in but no mailbox transport is wired in this package. ' +
                        'Keep AllowLiveFetch false and use FixtureActivitySyncProvider.',
                ],
            };
        }
        try {
            const response = await this.fetcher.GetEvents({
                Mailbox: query.Mailbox,
                Since: query.Since,
                Top: query.Limit,
            });
            if (response?.Success === false) {
                return {
                    Payloads: [],
                    Issues: [`Graph refused the calendar read: ${response.ErrorMessage ?? 'no reason given'}`],
                };
            }
            return {
                Payloads: (response?.Events ?? []) as Record<string, unknown>[],
                Issues: [],
            };
        } catch (err) {
            return { Payloads: [], Issues: [`Graph calendar read failed: ${String(err)}`] };
        }
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
