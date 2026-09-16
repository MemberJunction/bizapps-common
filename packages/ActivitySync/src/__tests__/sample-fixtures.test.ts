/**
 * The demo fixtures, run through the real mappers.
 *
 * WHY A FIXTURE NEEDS A TEST. `demo/graph-sample-messages.json` had none: it was loaded only by
 * `run-demo.mjs`, so the only thing standing behind it was that a script printed plausible output.
 * A fixture nobody asserts against drifts silently — a mapper change quietly stops reading a field,
 * and the demo keeps producing a green wall of text with one column now empty.
 *
 * These pin what each sample is FOR. The calendar set in particular was built to exercise decisions
 * rather than to look tidy: a recurring occurrence, a cancellation, an internal-only meeting, and one
 * event whose timezone genuinely does not determine an instant. If someone later "fixes" the mapper
 * to guess at that timezone, this fails — which is the point.
 */
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

import { MapGraphMessages } from '../providers/GraphMessageMapper.js';
import { MapGraphEvent, type GraphEventLike } from '../providers/MSGraphCalendarSyncProvider.js';

const DEMO = join(dirname(fileURLToPath(import.meta.url)), '..', '..', 'demo');
const load = (name: string) => JSON.parse(readFileSync(join(DEMO, name), 'utf8')) as {
    mailbox: string;
    value: Record<string, unknown>[];
};

const events = load('graph-sample-events.json');
const messages = load('graph-sample-messages.json');

/** Map one sample by id, so a failure names the sample rather than an index. */
function mapEvent(id: string, issues: string[] = []) {
    const raw = events.value.find((e) => e.id === id);
    expect(raw, `no sample event with id ${id}`).toBeTruthy();
    return { item: MapGraphEvent(raw as GraphEventLike, issues), issues };
}

describe('the calendar fixture maps as intended', () => {
    it('has the six samples the $comment describes', () => {
        expect(events.value.map((e) => e.id)).toEqual([
            'evt-ext-1',
            'evt-occ-2',
            'evt-cancel-3',
            'evt-int-4',
            'evt-tz-5',
            'evt-att-6',
        ]);
    });

    it('maps an ordinary external meeting', () => {
        const { item } = mapEvent('evt-ext-1');
        expect(item).toMatchObject({
            TypeCode: 'Meeting',
            Subject: 'Renewal terms — walkthrough',
            Location: 'Microsoft Teams Meeting',
            Cancelled: false,
            HasAttachments: false,
        });
        expect(item!.StartedAt).toEqual(new Date('2026-08-28T15:00:00Z'));
        expect(item!.EndedAt).toEqual(new Date('2026-08-28T16:00:00Z'));
    });

    it('gives the organizer and attendees their roles, organizer first', () => {
        const { item } = mapEvent('evt-ext-1');
        expect(item!.Participants[0]).toMatchObject({ Address: 'rep@example.com', Role: 'Organizer' });
        expect(item!.Participants.slice(1).map((p) => p.Address)).toEqual([
            'dana.whitfield@customer.example.org',
            'priya.nair@customer.example.org',
        ]);
        expect(item!.Participants.slice(1).every((p) => p.Role === 'Attendee')).toBe(true);
    });

    /**
     * The occurrence carries its OWN start, not the series'. That is the whole reason the transport
     * sends a bounded window — without one Graph returns the master and this date would be July.
     */
    it('threads a recurring occurrence to its series and keeps the occurrence start', () => {
        const { item } = mapEvent('evt-occ-2');
        expect(item!.ExternalThreadID).toBe('evt-series-master-2');
        expect(item!.StartedAt).toEqual(new Date('2026-08-31T09:30:00Z'));
    });

    it('carries a cancellation through rather than dropping the event', () => {
        const { item } = mapEvent('evt-cancel-3');
        expect(item).toBeTruthy();
        expect(item!.Cancelled).toBe(true);
    });

    /** The ParticipantScope=HasExternal case: every participant is on example.com. */
    it('has an internal-only meeting, for the participant-scope path', () => {
        const { item } = mapEvent('evt-int-4');
        const domains = new Set(item!.Participants.map((p) => p.Address.split('@')[1]));
        expect([...domains]).toEqual(['example.com']);
    });

    /**
     * THE LOAD-BEARING ONE. Graph sends naive local time plus a separate named zone. Without a tz
     * database that does not determine an instant, and guessing files the meeting hours from when it
     * actually happened. The mapper must skip and say so.
     */
    it('skips the event whose timezone determines no instant, and reports it', () => {
        const { item, issues } = mapEvent('evt-tz-5');
        expect(item).toBeNull();
        expect(issues.join(' ')).toMatch(/evt-tz-5/);
        expect(issues.join(' ')).toMatch(/start time/i);
    });

    it('marks the one event that carries attachments', () => {
        expect(mapEvent('evt-att-6').item!.HasAttachments).toBe(true);
        const others = ['evt-ext-1', 'evt-occ-2', 'evt-cancel-3', 'evt-int-4'];
        expect(others.every((id) => mapEvent(id).item!.HasAttachments === false)).toBe(true);
    });

    it('preserves the whole payload on Raw, including fields the mapper never reads', () => {
        const { item } = mapEvent('evt-ext-1');
        const raw = item!.Raw as Record<string, unknown>;
        for (const untouched of ['categories', 'showAs', 'responseStatus', 'webLink', 'importance']) {
            expect(raw, `Raw lost ${untouched}`).toHaveProperty(untouched);
        }
    });

    /** Five of six map; the sixth is the timezone refusal. Stated so a drop is noticed. */
    it('yields five items from six samples', () => {
        const issues: string[] = [];
        const mapped = events.value.map((e) => MapGraphEvent(e as GraphEventLike, issues)).filter(Boolean);
        expect(mapped).toHaveLength(5);
        expect(issues).toHaveLength(1);
    });
});

describe('the message fixture still maps as the demo assumes', () => {
    it('yields five items', () => {
        expect(MapGraphMessages(messages, messages.mailbox).Items).toHaveLength(5);
    });

    it('marks exactly the one message that carries attachments', () => {
        const withAttachments = MapGraphMessages(messages, messages.mailbox).Items.filter((m) => m.HasAttachments);
        expect(withAttachments).toHaveLength(1);
    });

    /**
     * The unusable Cc is deliberate sample data, not an oversight: Graph really does return the
     * literal `undisclosed-recipients` in place of an address, and the mapper is supposed to drop it
     * with an issue rather than file it as a participant.
     */
    it('keeps the unusable Cc that exercises the drop path', () => {
        const result = MapGraphMessages(messages, messages.mailbox);
        expect(result.Issues.join(' ')).toMatch(/undisclosed-recipients/);
    });

    /**
     * RFC 2606 reserves these precisely so sample data cannot reach a real mailbox. The one
     * exception is the placeholder above, which is not an address at all — it has no `@`.
     */
    it('addresses nobody real, in either fixture', () => {
        const text = readFileSync(join(DEMO, 'graph-sample-events.json'), 'utf8')
            + readFileSync(join(DEMO, 'graph-sample-messages.json'), 'utf8');
        const addresses = [...text.matchAll(/"address":\s*"([^"]+)"/g)].map((m) => m[1]);
        expect(addresses.length).toBeGreaterThan(0);
        const escaped = addresses
            .filter((a) => a.includes('@'))
            .filter((a) => !/@([\w-]+\.)*example\.(com|org|net)$/.test(a));
        expect(escaped, `these could reach a real mailbox: ${escaped.join(', ')}`).toEqual([]);
    });
});
