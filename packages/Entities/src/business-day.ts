/**
 * Calendar days, and the business zone that decides which one it is today.
 *
 * A SQL `date` column is a calendar day with no time and no zone. The driver hands it back as a Date
 * at UTC midnight, so its UTC parts are the stored day and its local parts are the previous day for
 * anyone west of Greenwich. Reading and writing a stored day therefore never involves a zone.
 *
 * "Today" is the one thing that does. `new Date().toISOString().slice(0, 10)` is the UTC day, which is
 * already tomorrow for the whole American evening; the browser's local day is wherever the user sits,
 * not where the business books. These helpers take the zone explicitly; `BusinessTimeZoneEngine`
 * supplies it from the instance configuration.
 *
 * No library. `Intl.DateTimeFormat` with a `timeZone` option is what every supported runtime ships,
 * and the two things needed from it — the wall-clock parts at an instant, and the offset between wall
 * clock and instant — are enough to go both ways.
 */

export type CalendarDay = string;

export const UTC_ZONE = 'UTC';

const CALENDAR_DAY = /^\d{4}-\d{2}-\d{2}$/;
const LEADING_DAY = /^\d{4}-\d{2}-\d{2}/;

interface WallClock {
    year: number;
    month: number;
    day: number;
    hour: number;
    minute: number;
    second: number;
}

const formatters = new Map<string, Intl.DateTimeFormat>();

function formatterFor(zone: string): Intl.DateTimeFormat {
    let formatter = formatters.get(zone);
    if (!formatter) {
        formatter = new Intl.DateTimeFormat('en-US', {
            timeZone: zone,
            hourCycle: 'h23',
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
        });
        formatters.set(zone, formatter);
    }
    return formatter;
}

function wallClock(instant: Date, zone: string): WallClock {
    const parts = formatterFor(zone).formatToParts(instant);
    const read = (type: Intl.DateTimeFormatPartTypes): number => Number(parts.find((p) => p.type === type)?.value ?? '0');
    return { year: read('year'), month: read('month'), day: read('day'), hour: read('hour'), minute: read('minute'), second: read('second') };
}

function pad(value: number, width: number): string {
    return String(value).padStart(width, '0');
}

function dayOf(year: number, month: number, day: number): CalendarDay {
    return `${pad(year, 4)}-${pad(month, 2)}-${pad(day, 2)}`;
}

/** Whether a value is a zero-padded `YYYY-MM-DD` and nothing more. */
export function IsCalendarDay(value: unknown): value is CalendarDay {
    return typeof value === 'string' && CALENDAR_DAY.test(value);
}

/**
 * The calendar day a stored value names, or null.
 *
 * A Date is read from its UTC parts. A string is taken as written when it begins with a day, never
 * parsed and re-based: `2026-09-30T23:00:00-05:00` is the 30th as stored. Anything else is null rather
 * than `Invalid Date`, which would print literally and destroy the evidence of what was held.
 */
export function ToCalendarDay(value: unknown): CalendarDay | null {
    if (value === null || value === undefined || value === '') return null;
    if (value instanceof Date) {
        if (Number.isNaN(value.getTime())) return null;
        return dayOf(value.getUTCFullYear(), value.getUTCMonth() + 1, value.getUTCDate());
    }
    if (typeof value === 'string') {
        return LEADING_DAY.test(value) ? value.slice(0, 10) : null;
    }
    return null;
}

/** UTC midnight of the day: the shape a `date` column round-trips as, safe to assign to a date field. */
export function FromCalendarDay(day: CalendarDay): Date {
    return new Date(`${day}T00:00:00.000Z`);
}

/** The calendar day it is in `zone` at the given instant. */
export function CalendarDayIn(instant: Date, zone: string): CalendarDay {
    const clock = wallClock(instant, zone);
    return dayOf(clock.year, clock.month, clock.day);
}

/** Today in `zone`. `now` is a parameter so tests never read the clock. */
export function TodayIn(zone: string, now: Date = new Date()): CalendarDay {
    return CalendarDayIn(now, zone);
}

export function AddDays(day: CalendarDay, days: number): CalendarDay {
    const start = FromCalendarDay(day);
    start.setUTCDate(start.getUTCDate() + days);
    const moved = ToCalendarDay(start);
    if (moved === null) throw new RangeError(`Not a calendar day: ${day}`);
    return moved;
}

/** Fixed-width ISO days sort lexically in chronological order, so a string compare is exact. */
export function CompareDays(a: CalendarDay, b: CalendarDay): number {
    return a < b ? -1 : a > b ? 1 : 0;
}

export function IsBeforeDay(a: CalendarDay, b: CalendarDay): boolean {
    return CompareDays(a, b) < 0;
}

export function FirstDayOfMonth(day: CalendarDay): CalendarDay {
    return `${day.slice(0, 7)}-01`;
}

export function LastDayOfPriorMonth(day: CalendarDay): CalendarDay {
    return AddDays(FirstDayOfMonth(day), -1);
}

/** Wall clock in `zone` at `instant`, expressed as if it were UTC, minus the instant: the zone's offset. */
function offsetMs(instant: Date, zone: string): number {
    const clock = wallClock(instant, zone);
    const asUtc = Date.UTC(clock.year, clock.month - 1, clock.day, clock.hour, clock.minute, clock.second);
    return asUtc - Math.floor(instant.getTime() / 1000) * 1000;
}

/**
 * The instant a calendar day begins in `zone`.
 *
 * Two passes: the offset at the UTC-midnight guess, then the offset at the corrected instant, so a
 * day whose midnight sits on the other side of a DST change still lands on local midnight.
 */
export function DayStartUtc(day: CalendarDay, zone: string): Date {
    const guess = FromCalendarDay(day).getTime();
    const first = guess - offsetMs(new Date(guess), zone);
    const second = guess - offsetMs(new Date(first), zone);
    return new Date(second);
}

/** The last millisecond of a calendar day in `zone`: an end date covers its whole day. */
export function DayEndUtc(day: CalendarDay, zone: string): Date {
    return new Date(DayStartUtc(AddDays(day, 1), zone).getTime() - 1);
}

/** Whether the runtime knows the zone. `Intl` throws a RangeError for a name it cannot resolve. */
export function IsKnownTimeZone(zone: string): boolean {
    if (!zone) return false;
    try {
        formatterFor(zone);
        return true;
    } catch {
        return false;
    }
}
