/**
 * Day handling for Relationship StartDate/EndDate.
 *
 * Both are SQL `date` columns: a calendar day with no time and no zone. The driver hands them back as
 * a Date at UTC midnight, so the stored day is the Date's UTC parts; its local parts are the previous
 * day for anyone west of Greenwich. "Today" is the business day, which needs a zone.
 */
import { FromCalendarDay, ToCalendarDay, TodayIn } from '@mj-biz-apps/common-entities';

/** The `YYYY-MM-DD` an `<input type="date">` shows for a stored day; empty for none. */
export function RelationshipDateInputValue(value: Date | null): string {
    return ToCalendarDay(value) ?? '';
}

/**
 * The end date for a relationship ended now: today in the business zone, as UTC midnight. A raw
 * `new Date()` is an instant, and a `date` column keeps its UTC day — tomorrow, for an American
 * evening.
 */
export function RelationshipEndDateFor(zone: string, now: Date = new Date()): Date {
    return FromCalendarDay(TodayIn(zone, now));
}

/** Month and year of a stored day, by its UTC parts: a Jan 1 start is January everywhere. */
function formatMonthYear(value: Date): string {
    return new Date(value).toLocaleDateString('en-US', { month: 'short', year: 'numeric', timeZone: 'UTC' });
}

/** A compact `Jan 2026 - Present` range for the list; an open end reads `Present` while active. */
export function FormatRelationshipDateRange(start: Date | null, end: Date | null, status: string): string {
    if (!start && !end) return '';

    const startStr = start ? formatMonthYear(start) : '';
    const endStr = end ? formatMonthYear(end) : (status === 'Active' ? 'Present' : '');

    if (startStr && endStr) return `${startStr} - ${endStr}`;
    if (startStr) return `${startStr} -`;
    return '';
}
