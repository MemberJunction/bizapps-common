import { describe, expect, it } from 'vitest';

import {
    CanAdvanceWatermark,
    MergeCalendarWatermark,
    NextWatermark,
    ResolveHighWatermark,
    SurfaceWatermark,
    type RunOutcome,
} from '../watermark.js';
import type { NormalizedItem } from '../types.js';

function item(startedAt: string): NormalizedItem {
    return {
        ExternalID: `id-${startedAt}`,
        ExternalThreadID: null,
        TypeCode: 'Email',
        Subject: 'subject',
        Body: null,
        StartedAt: new Date(startedAt),
        EndedAt: null,
        Location: null,
        HasAttachments: false,
        Direction: 'Inbound',
        Participants: [],
        Cancelled: false,
        Raw: {},
    };
}

const clean: RunOutcome = { Settled: 3, Discarded: 1, Failed: 0 };
const withFailure: RunOutcome = { Settled: 3, Discarded: 1, Failed: 1 };

describe('ResolveHighWatermark', () => {
    it('uses the newest item time for a message surface', () => {
        const items = [item('2026-08-01T10:00:00Z'), item('2026-08-03T10:00:00Z'), item('2026-08-02T10:00:00Z')];
        expect(ResolveHighWatermark('Message', items, new Date('2026-08-10T00:00:00Z'))).toEqual(
            new Date('2026-08-03T10:00:00Z'),
        );
    });

    it('uses OBSERVATION time for a calendar surface, never the item time', () => {
        // The trap: a December meeting fetched in August. max(StartedAt) would pin the watermark
        // four months into the future and the calendar would silently stop ingesting.
        const observedAt = new Date('2026-08-10T00:00:00Z');
        const items = [item('2026-12-01T09:00:00Z')];

        const result = ResolveHighWatermark('Calendar', items, observedAt);

        expect(result).toEqual(observedAt);
        expect(result!.getTime()).toBeLessThan(new Date('2026-12-01T09:00:00Z').getTime());
    });

    it('returns null for an empty batch on either basis', () => {
        const observedAt = new Date('2026-08-10T00:00:00Z');
        expect(ResolveHighWatermark('Message', [], observedAt)).toBeNull();
        expect(ResolveHighWatermark('Calendar', [], observedAt)).toBeNull();
    });

    it('treats Social and Chat as item-timed', () => {
        const items = [item('2026-08-05T10:00:00Z')];
        const observedAt = new Date('2026-08-10T00:00:00Z');
        expect(ResolveHighWatermark('Social', items, observedAt)).toEqual(new Date('2026-08-05T10:00:00Z'));
        expect(ResolveHighWatermark('Chat', items, observedAt)).toEqual(new Date('2026-08-05T10:00:00Z'));
    });
});

describe('CanAdvanceWatermark', () => {
    it('allows an advance when nothing failed', () => {
        expect(CanAdvanceWatermark(clean)).toBe(true);
    });

    it('withholds the advance on ANY failure — one is enough', () => {
        expect(CanAdvanceWatermark(withFailure)).toBe(false);
        expect(CanAdvanceWatermark({ Settled: 0, Discarded: 0, Failed: 1 })).toBe(false);
    });

    it('allows an advance over discards — a discard has been seen to a conclusion', () => {
        expect(CanAdvanceWatermark({ Settled: 0, Discarded: 50, Failed: 0 })).toBe(true);
    });
});

describe('NextWatermark', () => {
    it('advances on a clean run', () => {
        const current = new Date('2026-08-01T00:00:00Z');
        const candidate = new Date('2026-08-05T00:00:00Z');
        expect(NextWatermark(current, candidate, clean)).toEqual(candidate);
    });

    it('holds position when the run had a failure', () => {
        const current = new Date('2026-08-01T00:00:00Z');
        const candidate = new Date('2026-08-05T00:00:00Z');
        expect(NextWatermark(current, candidate, withFailure)).toEqual(current);
    });

    it('never moves backwards, even on a clean run', () => {
        // Two runs racing: the later-starting one finishes first with an older batch.
        const current = new Date('2026-08-05T00:00:00Z');
        const candidate = new Date('2026-08-02T00:00:00Z');
        expect(NextWatermark(current, candidate, clean)).toEqual(current);
    });

    it('holds position when there is no candidate', () => {
        const current = new Date('2026-08-05T00:00:00Z');
        expect(NextWatermark(current, null, clean)).toEqual(current);
    });

    it('accepts the first watermark from null', () => {
        const candidate = new Date('2026-08-05T00:00:00Z');
        expect(NextWatermark(null, candidate, clean)).toEqual(candidate);
    });
});

describe('SurfaceWatermark', () => {
    const at = new Date('2026-08-19T18:00:00.000Z');

    it('reads LastSyncAt for messages and ignores Settings', () => {
        expect(SurfaceWatermark('Message', at, '{"CalendarLastSyncAt":"2026-01-01T00:00:00.000Z"}')).toEqual(at);
        expect(SurfaceWatermark('Message', null, '{"CalendarLastSyncAt":"2026-01-01T00:00:00.000Z"}')).toBeNull();
    });

    it('reads Settings.CalendarLastSyncAt for calendar, never LastSyncAt', () => {
        expect(SurfaceWatermark('Calendar', at, '{"CalendarLastSyncAt":"2026-08-19T09:00:00.000Z"}')).toEqual(
            new Date('2026-08-19T09:00:00.000Z'),
        );
        expect(SurfaceWatermark('Calendar', at, null)).toBeNull();
        expect(SurfaceWatermark('Calendar', at, '{')).toBeNull();
    });

    it('merges the calendar watermark without dropping other Settings keys', () => {
        const merged = MergeCalendarWatermark('{"StoreBody":"Full"}', at);
        expect(JSON.parse(merged)).toEqual({ StoreBody: 'Full', CalendarLastSyncAt: at.toISOString() });
    });
});
