/**
 * Calendar days, and the business zone that decides which one it is.
 *
 * A SQL `date` column is a calendar day with no zone; the driver hands it back as UTC midnight, so
 * the UTC parts are the honest reading and the local parts are wrong for everyone west of Greenwich.
 * "Today", by contrast, genuinely needs a zone: at 9 PM in New York it is already tomorrow in UTC,
 * and an order dated by `new Date().toISOString()` files a day late. These tests give every zone
 * explicitly, so they mean the same thing on a UTC CI runner as on a laptop in Chicago.
 */
import { describe, expect, it } from 'vitest';
import {
    AddDays,
    CalendarDayIn,
    CompareDays,
    DayEndUtc,
    DayStartUtc,
    FirstDayOfMonth,
    FromCalendarDay,
    IsBeforeDay,
    IsCalendarDay,
    IsKnownTimeZone,
    LastDayOfPriorMonth,
    ToCalendarDay,
    TodayIn,
} from '../business-day.js';

const CENTRAL = 'America/Chicago';
const KOLKATA = 'Asia/Kolkata';
const SANTIAGO = 'America/Santiago';

describe('ToCalendarDay reads a stored date as the day the driver meant', () => {
    it('takes the UTC parts of a Date, so a date column does not slip a day west of Greenwich', () => {
        expect(ToCalendarDay(new Date('2026-01-01T00:00:00.000Z'))).toBe('2026-01-01');
    });
    it('takes the leading day of a string as written, never re-basing an offset', () => {
        expect(ToCalendarDay('2026-09-30T23:00:00-05:00')).toBe('2026-09-30');
        expect(ToCalendarDay('2026-07-30')).toBe('2026-07-30');
    });
    it('is null for absent or unreadable values rather than "Invalid Date"', () => {
        expect(ToCalendarDay(null)).toBeNull();
        expect(ToCalendarDay('')).toBeNull();
        expect(ToCalendarDay('not-a-date')).toBeNull();
        expect(ToCalendarDay(new Date('nonsense'))).toBeNull();
        expect(ToCalendarDay('2026-9-3')).toBeNull();
    });
});

describe('FromCalendarDay is UTC midnight, the shape a date column round-trips as', () => {
    it('pins the instant to 00:00:00.000Z', () => {
        expect(FromCalendarDay('2026-11-20').toISOString()).toBe('2026-11-20T00:00:00.000Z');
    });
    it('round-trips through ToCalendarDay', () => {
        expect(ToCalendarDay(FromCalendarDay('2026-02-28'))).toBe('2026-02-28');
    });
});

describe('CalendarDayIn and TodayIn answer in the given zone', () => {
    it('9 PM Central on 27 August is still 27 August in Central and already the 28th in UTC', () => {
        const instant = new Date('2026-08-28T02:00:00.000Z');
        expect(CalendarDayIn(instant, CENTRAL)).toBe('2026-08-27');
        expect(CalendarDayIn(instant, 'UTC')).toBe('2026-08-28');
    });
    it('8 AM in Pune is still the previous day in Chicago', () => {
        const instant = new Date('2026-09-15T02:30:00.000Z'); // 08:00 IST, 21:30 CDT the day before
        expect(CalendarDayIn(instant, KOLKATA)).toBe('2026-09-15');
        expect(CalendarDayIn(instant, CENTRAL)).toBe('2026-09-14');
    });
    it('TodayIn takes an explicit now, so the clock never leaks into a test', () => {
        expect(TodayIn(CENTRAL, new Date('2026-12-31T23:30:00.000Z'))).toBe('2026-12-31');
        expect(TodayIn(CENTRAL, new Date('2027-01-01T05:30:00.000Z'))).toBe('2026-12-31');
        expect(TodayIn(CENTRAL, new Date('2027-01-01T06:30:00.000Z'))).toBe('2027-01-01');
    });
});

describe('day arithmetic never touches a zone', () => {
    it('AddDays crosses month and year ends', () => {
        expect(AddDays('2026-08-31', 1)).toBe('2026-09-01');
        expect(AddDays('2026-01-01', -1)).toBe('2025-12-31');
        expect(AddDays('2028-02-28', 1)).toBe('2028-02-29');
    });
    it('CompareDays and IsBeforeDay order fixed-width days', () => {
        expect(CompareDays('2026-08-10', '2026-08-11')).toBe(-1);
        expect(CompareDays('2026-08-11', '2026-08-11')).toBe(0);
        expect(IsBeforeDay('2026-08-10', '2026-08-11')).toBe(true);
        expect(IsBeforeDay('2026-08-11', '2026-08-11')).toBe(false);
    });
    it('FirstDayOfMonth and LastDayOfPriorMonth', () => {
        expect(FirstDayOfMonth('2026-08-31')).toBe('2026-08-01');
        expect(LastDayOfPriorMonth('2026-03-01')).toBe('2026-02-28');
        expect(LastDayOfPriorMonth('2026-01-15')).toBe('2025-12-31');
    });
    it('AddDays throws on a malformed day rather than silently returning it unchanged', () => {
        expect(() => AddDays('2026-9-3', 1)).toThrow(RangeError);
    });
    it('IsCalendarDay accepts only zero-padded YYYY-MM-DD', () => {
        expect(IsCalendarDay('2026-08-10')).toBe(true);
        expect(IsCalendarDay('2026-8-10')).toBe(false);
        expect(IsCalendarDay('2026-08-10T00:00:00Z')).toBe(false);
        expect(IsCalendarDay(20260810)).toBe(false);
    });
    it('rejects a day that cannot exist, not just one that is the wrong shape', () => {
        expect(IsCalendarDay('2026-02-30')).toBe(false);
        expect(IsCalendarDay('2026-99-99')).toBe(false);
        expect(ToCalendarDay('2026-02-30T00:00:00Z')).toBeNull();
        expect(() => FromCalendarDay('2026-02-30')).toThrow(RangeError);
    });
});

describe('DayStartUtc and DayEndUtc are the instants a day covers in a zone', () => {
    it('Central standard time: midnight is 06:00Z', () => {
        expect(DayStartUtc('2026-12-31', CENTRAL).toISOString()).toBe('2026-12-31T06:00:00.000Z');
        expect(DayEndUtc('2026-12-31', CENTRAL).toISOString()).toBe('2027-01-01T05:59:59.999Z');
    });
    it('Central daylight time: midnight is 05:00Z', () => {
        expect(DayStartUtc('2026-08-27', CENTRAL).toISOString()).toBe('2026-08-27T05:00:00.000Z');
    });
    it('the day the clocks spring forward still starts at local midnight', () => {
        // 2026-03-08: CST until 02:00, then CDT. Midnight is still CST (-06:00).
        expect(DayStartUtc('2026-03-08', CENTRAL).toISOString()).toBe('2026-03-08T06:00:00.000Z');
        expect(DayStartUtc('2026-03-09', CENTRAL).toISOString()).toBe('2026-03-09T05:00:00.000Z');
    });
    it('UTC is the identity', () => {
        expect(DayStartUtc('2026-08-27', 'UTC').toISOString()).toBe('2026-08-27T00:00:00.000Z');
    });
    it('the day the clocks fall back is 25 hours long and still starts at local midnight', () => {
        // 2026-11-01: CDT until 02:00, then CST. Midnight is CDT (-05:00); the next midnight is CST (-06:00).
        expect(DayStartUtc('2026-11-01', CENTRAL).toISOString()).toBe('2026-11-01T05:00:00.000Z');
        expect(DayEndUtc('2026-11-01', CENTRAL).toISOString()).toBe('2026-11-02T05:59:59.999Z');
    });
    it('a day whose clocks spring forward AT midnight starts at the first instant it exists', () => {
        // Santiago 2026-09-06 has no 00:00: the clock jumps 23:59:59 (-04) to 01:00 (-03).
        const start = DayStartUtc('2026-09-06', SANTIAGO);
        expect(start.toISOString()).toBe('2026-09-06T04:00:00.000Z');
        expect(CalendarDayIn(start, SANTIAGO)).toBe('2026-09-06');
    });
    it('and the day before it still ends the moment that day begins', () => {
        expect(DayEndUtc('2026-09-05', SANTIAGO).toISOString()).toBe('2026-09-06T03:59:59.999Z');
    });
    it('never returns an instant that falls on a different day than the one asked for', () => {
        for (const zone of [CENTRAL, KOLKATA, SANTIAGO, 'America/Havana', 'Australia/Lord_Howe', 'UTC']) {
            for (const day of ['2026-03-08', '2026-09-06', '2026-11-01', '2026-10-04', '2026-01-01']) {
                expect(CalendarDayIn(DayStartUtc(day, zone), zone), `${zone} ${day}`).toBe(day);
            }
        }
    });
});

describe('IsKnownTimeZone', () => {
    it('accepts IANA names and UTC, rejects Windows names and typos', () => {
        expect(IsKnownTimeZone('America/Chicago')).toBe(true);
        expect(IsKnownTimeZone('UTC')).toBe(true);
        expect(IsKnownTimeZone('Central Standard Time')).toBe(false);
        expect(IsKnownTimeZone('America/Chicagoo')).toBe(false);
        expect(IsKnownTimeZone('')).toBe(false);
    });
});
