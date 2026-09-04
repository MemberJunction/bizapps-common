/**
 * The calendar transport, and the gate in front of it.
 *
 * WHAT WAS BROKEN. `MSGraphCalendarSyncProvider` declared a `GraphEventFetcher` seam that NOTHING
 * implemented, reachable only as the second constructor argument — and `MJGlobal.ClassFactory` builds
 * plugins with no arguments. Through the engine, every calendar fetch returned `Payloads: []` and
 * logged "no transport is wired". Exported, documented, unreachable: the same defect the message
 * provider had, one surface over.
 *
 * Two properties have to hold at once, and most of what follows pins the second:
 *   1. a scoped host CAN read a calendar through the path that ships, and
 *   2. an unconfigured one still refuses — app-only `Calendars.Read` reads EVERY calendar in the
 *      tenant, so "on by default" would hand out the whole organisation's diary.
 */
import { afterEach, describe, expect, it, vi } from 'vitest';

import {
    DEFAULT_FIRST_RUN_LOOKBACK_DAYS,
    GraphCalendarTransport,
    MJGraphCalendarTransportDeps,
    type GraphEventReader,
} from '../providers/GraphCalendarTransport.js';
import type { GraphServicePrincipal } from '../providers/GraphCommunicationTransport.js';
import {
    AllowLiveMailboxFetch,
    RegisterActivityTransportFactory,
    type ActivityMessageTransport,
    type LiveMailboxPolicyAttestation,
} from '../providers/MessageTransport.js';
import {
    LIVE_GRAPH_CALENDAR_REFUSAL,
    MSGraphCalendarSyncProvider,
    NO_CALENDAR_CREDENTIAL_REF_REFUSAL,
} from '../providers/MSGraphCalendarSyncProvider.js';
import { RecordedMessageTransport } from '../providers/RecordedMessageTransport.js';
import type { ActivitySourceQuery } from '../types.js';

const CREDENTIAL: GraphServicePrincipal = { tenantId: 't', clientId: 'c', clientSecret: 's' };
const QUERY: ActivitySourceQuery = { Mailbox: 'rep@example.com', Since: null, Limit: 50 };
const NOW = new Date('2026-09-04T12:00:00Z');

const EVENT = {
    id: 'evt-1',
    subject: 'Renewal review',
    start: { dateTime: '2026-09-02T14:00:00.0000000', timeZone: 'UTC' },
    end: { dateTime: '2026-09-02T15:00:00.0000000', timeZone: 'UTC' },
    organizer: { emailAddress: { address: 'rep@example.com' } },
    attendees: [{ emailAddress: { address: 'buyer@customer.com' } }],
};

function readerReturning(result: Record<string, unknown>) {
    return { GetEvents: vi.fn().mockResolvedValue(result) } as unknown as GraphEventReader;
}

function transport(reader: GraphEventReader, credential: Partial<GraphServicePrincipal> = CREDENTIAL) {
    return new GraphCalendarTransport(
        {
            ResolveCredential: async () => credential as GraphServicePrincipal,
            ResolveProvider: async () => reader,
        },
        DEFAULT_FIRST_RUN_LOOKBACK_DAYS,
        30,
        () => NOW,
    );
}

const ATTESTATION: LiveMailboxPolicyAttestation = {
    Confirmed: true,
    ScopedToGroup: 'activity-sync@bluecypress.io',
    ConfirmedBy: 'Josue Garcia',
    ConfirmedAt: NOW,
};

afterEach(() => {
    AllowLiveMailboxFetch(null);
    RegisterActivityTransportFactory(null);
});

describe('what the transport asks Graph for', () => {
    it('sends BOTH bounds, which is what makes Graph expand recurring series', async () => {
        const reader = readerReturning({ Success: true, SourceData: [EVENT], RecurrenceExpanded: true });
        await transport(reader).Fetch({ ...QUERY, Since: new Date('2026-09-01T00:00:00Z') });

        const params = (reader.GetEvents as ReturnType<typeof vi.fn>).mock.calls[0][0];
        expect(params.StartDateTime).toEqual(new Date('2026-09-01T00:00:00Z'));
        expect(params.EndDateTime).toBeInstanceOf(Date);
    });

    it('passes the credential through to the call rather than holding it', async () => {
        const reader = readerReturning({ Success: true, SourceData: [] });
        await transport(reader).Fetch(QUERY);
        expect((reader.GetEvents as ReturnType<typeof vi.fn>).mock.calls[0][1]).toEqual(CREDENTIAL);
    });

    /**
     * A cancelled meeting is a thing that happened to somebody's day, and `MapGraphEvent` already
     * carries `Cancelled` through. Dropping them at the transport would make that field dead code.
     */
    it('asks for cancelled events, because the mapper models them', async () => {
        const reader = readerReturning({ Success: true, SourceData: [] });
        await transport(reader).Fetch(QUERY);
        expect((reader.GetEvents as ReturnType<typeof vi.fn>).mock.calls[0][0].IncludeCancelled).toBe(true);
    });

    it('reads SourceData, not the normalized Events', async () => {
        const reader = readerReturning({ Success: true, SourceData: [EVENT], Events: [{ ExternalSystemRecordID: 'x' }] });
        const batch = await transport(reader).Fetch(QUERY);
        expect(batch.Payloads).toEqual([EVENT]);
    });
});

describe('the first run, where there is no watermark', () => {
    /**
     * `/calendarView` refuses a request with no window, so a bound is invented — and an invented
     * bound that nobody mentions reads as "we synced your calendar" when it means "we synced a month
     * of it".
     */
    it('falls back to a lookback and says so', async () => {
        const reader = readerReturning({ Success: true, SourceData: [] });
        const batch = await transport(reader).Fetch({ ...QUERY, Since: null });
        expect(batch.Issues.join(' ')).toMatch(/no watermark/);
        expect(batch.Issues.join(' ')).toMatch(new RegExp(`${DEFAULT_FIRST_RUN_LOOKBACK_DAYS} days back`));
    });

    it('starts the window exactly that far back', async () => {
        const reader = readerReturning({ Success: true, SourceData: [] });
        await transport(reader).Fetch({ ...QUERY, Since: null });
        const params = (reader.GetEvents as ReturnType<typeof vi.fn>).mock.calls[0][0];
        const expected = new Date(NOW.getTime() - DEFAULT_FIRST_RUN_LOOKBACK_DAYS * 86_400_000);
        expect(params.StartDateTime).toEqual(expected);
    });

    it('says nothing about a lookback when a watermark exists', async () => {
        const reader = readerReturning({ Success: true, SourceData: [] });
        const batch = await transport(reader).Fetch({ ...QUERY, Since: new Date('2026-09-01T00:00:00Z') });
        expect(batch.Issues.join(' ')).not.toMatch(/no watermark/);
    });

    /** `Activity.Status` includes `Scheduled`, so a calendar sync that only looked back could not produce one. */
    it('reaches forward as well as back', async () => {
        const reader = readerReturning({ Success: true, SourceData: [] });
        await transport(reader).Fetch(QUERY);
        const params = (reader.GetEvents as ReturnType<typeof vi.fn>).mock.calls[0][0];
        expect(params.EndDateTime.getTime()).toBeGreaterThan(NOW.getTime());
    });
});

describe('reporting what would otherwise pass silently', () => {
    /**
     * The subtle one. A series master and a single occurrence are indistinguishable by inspection,
     * so if Graph did not expand, a weekly meeting is filed once at whatever date the series began
     * and every downstream check still passes.
     */
    it('warns when recurrence was not expanded despite a bounded window', async () => {
        const reader = readerReturning({ Success: true, SourceData: [EVENT], RecurrenceExpanded: false });
        const batch = await transport(reader).Fetch(QUERY);
        expect(batch.Issues.join(' ')).toMatch(/did not expand recurring series/);
    });

    it('stays quiet when it did expand', async () => {
        const reader = readerReturning({ Success: true, SourceData: [EVENT], RecurrenceExpanded: true });
        const batch = await transport(reader).Fetch(QUERY);
        expect(batch.Issues.join(' ')).not.toMatch(/did not expand/);
    });

    it('flags a capped read, which may have left events behind', async () => {
        const many = Array.from({ length: 5 }, (_, i) => ({ ...EVENT, id: `evt-${i}` }));
        const reader = readerReturning({ Success: true, SourceData: many, RecurrenceExpanded: true });
        const batch = await transport(reader).Fetch({ ...QUERY, Limit: 5 });
        expect(batch.Capped).toBe(true);
        expect(batch.Issues.join(' ')).toMatch(/hit its limit/);
    });

    /**
     * THROWS rather than returning an empty batch. `BaseActivitySyncProvider.Fetch` distinguishes
     * "could not look" from "looked, found nothing", and only the second may advance a watermark.
     */
    it('throws when Graph refuses, instead of reporting an empty calendar', async () => {
        const reader = readerReturning({ Success: false, ErrorMessage: 'Forbidden' });
        await expect(transport(reader).Fetch(QUERY)).rejects.toThrow(/Forbidden/);
    });

    it('refuses an incomplete credential by FIELD NAME, never by value', async () => {
        const reader = readerReturning({ Success: true, SourceData: [] });
        const t = transport(reader, { tenantId: 't', clientId: 'c', clientSecret: '  ' });
        await expect(t.Fetch(QUERY)).rejects.toThrow(/clientSecret/);
        // the value must not appear anywhere in the message
        await expect(t.Fetch(QUERY)).rejects.not.toThrow(/'t'|'c'/);
        expect(reader.GetEvents).not.toHaveBeenCalled();
    });
});

describe('the provider in front of it', () => {
    const ctx = () => ({
        CredentialsRef: 'Graph Reader',
        Mailbox: 'rep@example.com',
        DriverClass: 'Microsoft365.Calendar',
    });
    const live = (): ActivityMessageTransport => ({
        Describe: 'stub (claims live)',
        IsLive: true,
        Fetch: vi.fn().mockResolvedValue({ Payloads: [EVENT], Issues: [] }),
    });
    const recorded = () =>
        new RecordedMessageTransport([{ Mailbox: 'rep@example.com', Payloads: [EVENT], Provenance: 'captured' }]);

    function asShipped(t: ActivityMessageTransport) {
        RegisterActivityTransportFactory(() => t);
        const p = new MSGraphCalendarSyncProvider(); // no arguments, exactly like ClassFactory
        p.Configure(ctx());
        return p;
    }

    it('refuses a live calendar read when no policy has been attested', async () => {
        const t = live();
        const batch = await asShipped(t).Fetch(QUERY);
        expect(batch.Issues[0]).toBe(LIVE_GRAPH_CALENDAR_REFUSAL);
        expect(t.Fetch).not.toHaveBeenCalled();
    });

    /** The other half — before this change there was no argument-free way to reach `true` at all. */
    it('reads once the host has attested, through the shipping path', async () => {
        AllowLiveMailboxFetch(ATTESTATION);
        const t = live();
        const batch = await asShipped(t).Fetch(QUERY);
        expect(t.Fetch).toHaveBeenCalledOnce();
        expect(batch.Items).toHaveLength(1);
        expect(batch.Items[0].TypeCode).toBe('Meeting');
    });

    /**
     * ONE attestation for both surfaces. The same Exchange policy scopes Mail.Read and
     * Calendars.Read, so a second switch would let someone record half a decision.
     */
    it('uses the same attestation mail uses, not a second one', async () => {
        AllowLiveMailboxFetch(ATTESTATION);
        const batch = await asShipped(live()).Fetch(QUERY);
        expect(batch.Issues.join(' ')).not.toContain('Live Graph calendar fetch is disabled');
    });

    it('lets a RECORDED transport through without any attestation', async () => {
        const batch = await asShipped(recorded()).Fetch(QUERY);
        expect(batch.Issues.join(' ')).not.toContain('Live Graph calendar fetch is disabled');
        expect(batch.Items).toHaveLength(1);
    });

    /** IsLive must follow the transport, or a replayed run is indistinguishable from a real one. */
    it('reports IsLive from the transport rather than claiming true', async () => {
        const p = asShipped(recorded());
        expect(p.IsLive).toBe(false);
        expect(new MSGraphCalendarSyncProvider().IsLive).toBe(true);
    });

    it('names the missing CredentialsRef rather than blaming the policy alone', async () => {
        RegisterActivityTransportFactory(() => live());
        const p = new MSGraphCalendarSyncProvider();
        p.Configure({ ...ctx(), CredentialsRef: null });
        const batch = await p.Fetch(QUERY);
        expect(batch.Issues).toContain(NO_CALENDAR_CREDENTIAL_REF_REFUSAL);
    });

    it('passes the calendar driver to the factory, so one factory can serve both surfaces', () => {
        const factory = vi.fn().mockReturnValue(recorded());
        RegisterActivityTransportFactory(factory);
        new MSGraphCalendarSyncProvider().Configure(ctx());
        expect(factory).toHaveBeenCalledWith(
            expect.objectContaining({ DriverClass: 'Microsoft365.Calendar', CredentialsRef: 'Graph Reader' }),
        );
    });
});

describe('MJGraphCalendarTransportDeps', () => {
    it('resolves the credential by name through the engine', async () => {
        const getCredential = vi.fn().mockResolvedValue({ values: CREDENTIAL });
        const deps = MJGraphCalendarTransportDeps({
            CredentialName: 'Graph Reader',
            GetCredentialEngine: () => ({ getCredential }),
            GetCommunicationProvider: () => readerReturning({ Success: true }),
        });
        await expect(deps.ResolveCredential()).resolves.toEqual(CREDENTIAL);
        expect(getCredential).toHaveBeenCalledWith('Graph Reader', expect.anything());
    });

    /** A registration fault and a credential fault need different fixes, so they read differently. */
    it('says the provider is unregistered rather than blaming the credential', async () => {
        const deps = MJGraphCalendarTransportDeps({
            CredentialName: 'Graph Reader',
            GetCredentialEngine: () => ({ getCredential: vi.fn() }),
            GetCommunicationProvider: () => null,
        });
        await expect(deps.ResolveProvider()).rejects.toThrow(/is not registered/);
    });

    it('refuses a credential that resolved with no values', async () => {
        const deps = MJGraphCalendarTransportDeps({
            CredentialName: 'Graph Reader',
            GetCredentialEngine: () => ({ getCredential: vi.fn().mockResolvedValue({}) }),
            GetCommunicationProvider: () => readerReturning({ Success: true }),
        });
        await expect(deps.ResolveCredential()).rejects.toThrow(/resolved with no values/);
    });
});
