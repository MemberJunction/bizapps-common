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
