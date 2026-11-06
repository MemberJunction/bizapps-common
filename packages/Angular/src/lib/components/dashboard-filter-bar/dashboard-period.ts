/**
 * @fileoverview Reporting-period windows for BizApps dashboards: "this quarter", "last year", a custom
 * range, all as inclusive calendar-day bounds.
 *
 * Pure, so every boundary claim can be tested without a provider or a browser. A quarter that starts
 * a day late still renders a plausible number, so the edges are where this module is tested.
 *
 * ── THE FISCAL YEAR START IS SUPPLIED BY THE CALLER ─────────────────────────────────────────────
 *
 * Common does not know where an app keeps its fiscal year. The app reads its own per-company starts
 * and hands them to {@link ResolveFiscalYearStart}, which decides what they amount to; everything
 * below is arithmetic over the answer. A fiscal year is labelled by the calendar year it STARTS in.
 *
 * ── EVERYTHING IS A CALENDAR DAY ────────────────────────────────────────────────────────────────
 *
 * `YYYY-MM-DD` throughout, built from UTC parts, because the columns these bound are SQL DATEs and a
 * local-time boundary moves the first and last day of every period for anyone west of Greenwich.
 * Lexical comparison on this format is chronological, so no `Date` survives past construction.
 * "Today" is the one zone-dependent input, and it defaults to the business day
 * (`BusinessTimeZoneEngine`).
 *
 * @module @mj-biz-apps/common-ng
 */
import { AddDays, BusinessTimeZoneEngine, IsCalendarDay, ToCalendarDay } from '@mj-biz-apps/common-entities';

/**
 * The windows a dashboard offers. `alltime` is unbounded, not a very wide bound. `custom` takes its
 * bounds from two date pickers (see {@link ResolvePeriod}).
 */
export type PeriodKey = 'quarter' | 'lastquarter' | 'nextquarter' | 'year' | 'lastyear' | 'alltime' | 'custom';

/** A fiscal year start. Month is 1-12, day 1-31. */
export interface FiscalYearStart {
    Month: number;
    Day: number;
}

/** 1 January: the fallback when no single fiscal start can be established. */
export const CALENDAR_YEAR_START: FiscalYearStart = { Month: 1, Day: 1 };

/**
 * Why a dashboard is using the fiscal start it is using. The period control shows it, because a
 * period whose boundaries are invisible reads as settled while meaning something else.
 */
export type FiscalBasis =
    /** Nothing has been read yet. {@link ResolveFiscalYearStart} never returns it; a caller holding a pre-load value does. */
    | 'pending'
    /** Every company read agreed, and this is what they said. */
    | 'profile'
    /** This host has no source of fiscal year starts. */
    | 'unavailable'
    /** A source exists, but no company has set a fiscal year yet. */
    | 'no-profiles'
    /** The starts could not be read, most often for lack of permission. */
    | 'unreadable'
    /** Two or more companies name different fiscal starts, so there is no single answer. */
    | 'mixed';

export interface FiscalYearStartResolution {
    Start: FiscalYearStart;
    Basis: FiscalBasis;
}

/** The state before an app has read its fiscal starts. */
export const PENDING_FISCAL_BASIS: FiscalYearStartResolution = { Start: CALENDAR_YEAR_START, Basis: 'pending' };

/**
 * An inclusive date window, or an unbounded one. `null` means no bound on that side, not "unknown".
 */
export interface PeriodWindow {
    Key: PeriodKey;
    /** The selector's own label, e.g. "This quarter". */
    Label: string;
    /** Inclusive `YYYY-MM-DD`, or null for no lower bound. */
    Start: string | null;
    /** Inclusive `YYYY-MM-DD`, or null for no upper bound. */
    End: string | null;
}

/** The selector's options, in display order. The first is the default. */
export const PERIOD_OPTIONS: readonly { Key: PeriodKey; Label: string }[] = [
    { Key: 'quarter', Label: 'This quarter' },
    { Key: 'lastquarter', Label: 'Last quarter' },
    { Key: 'nextquarter', Label: 'Next quarter' },
    { Key: 'year', Label: 'This year' },
    { Key: 'lastyear', Label: 'Last year' },
    { Key: 'alltime', Label: 'All time' },
    { Key: 'custom', Label: 'Custom range' },
];

/** The period a dashboard opens on. */
export const DEFAULT_PERIOD: PeriodKey = PERIOD_OPTIONS[0].Key;

/** The two dates a custom range is picked with, `YYYY-MM-DD`; either may be empty. */
export interface CustomRange {
    Start: string | null;
    End: string | null;
}

/** `value` when it is a `YYYY-MM-DD` day that exists, otherwise null. URLs and date pickers hand back strings. */
export function IsoDay(value: string | null | undefined): string | null {
    return IsCalendarDay(value) ? value : null;
}

/** The period key `value` names, or null for anything else. */
export function PeriodKeyOf(value: string | null | undefined): PeriodKey | null {
    return PERIOD_OPTIONS.find((o) => o.Key === value)?.Key ?? null;
}

function labelFor(key: PeriodKey): string {
    return PERIOD_OPTIONS.find((o) => o.Key === key)?.Label ?? PERIOD_OPTIONS[0].Label;
}

/**
 * What a set of company fiscal starts amounts to, as one answer or none.
 *
 * Disagreement falls back to the calendar rather than picking one: if two companies start their year
 * in different months, "this quarter" has no single correct answer, and a silent pick would be right
 * for one company's figures and wrong for the other's. Rows are compared by (Month, Day), so five
 * companies that all start in January agree.
 *
 * @param rows the starts of the companies in view; `null` when the host has no source for them.
 */
export function ResolveFiscalYearStart(rows: readonly FiscalYearStart[] | null): FiscalYearStartResolution {
    if (rows === null) {
        return { Start: CALENDAR_YEAR_START, Basis: 'unavailable' };
    }
    if (!rows.length) {
        return { Start: CALENDAR_YEAR_START, Basis: 'no-profiles' };
    }
    const distinct = new Set(rows.map((r) => `${r.Month}-${r.Day}`));
    if (distinct.size > 1) {
        return { Start: CALENDAR_YEAR_START, Basis: 'mixed' };
    }
    return { Start: { Month: rows[0].Month, Day: rows[0].Day }, Basis: 'profile' };
}

/** One line naming the boundary in force and how it was arrived at. */
export function DescribeFiscalBasis(resolution: FiscalYearStartResolution): string {
    switch (resolution.Basis) {
        case 'pending':
            return 'reading fiscal year start…';
        case 'profile':
            return `fiscal year starts ${MonthDayLabel(resolution.Start)}`;
        case 'unavailable':
            return 'calendar year';
        case 'no-profiles':
            return 'calendar year (no company sets a fiscal year)';
        case 'unreadable':
            return 'calendar year (fiscal year start could not be read)';
        case 'mixed':
            return 'calendar year (companies use different fiscal years)';
    }
}

const MONTH_ABBREVIATIONS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/** "Jul 1, 2026" from a stored day, read from its UTC parts. Anything that is not a day is ''. */
export function DayLabel(value: string | Date | null | undefined): string {
    const day = ToCalendarDay(value);
    if (!day) {
        return '';
    }
    const [y, m, d] = day.split('-').map(Number);
    return `${MONTH_ABBREVIATIONS[m - 1]} ${d}, ${y}`;
}

/** "Jul 1": a day without its year, in the same shape as {@link DayLabel}. */
export function MonthDayText(month: number, day: number): string {
    return `${MONTH_ABBREVIATIONS[Math.min(Math.max(month, 1), 12) - 1]} ${day}`;
}

/** "Apr 6": the fiscal start as a reader states it. */
export function MonthDayLabel(start: FiscalYearStart): string {
    return MonthDayText(start.Month, start.Day);
}

function daysInMonth(year: number, monthIndex: number): number {
    return new Date(Date.UTC(year, monthIndex + 1, 0)).getUTCDate();
}

function dayFromParts(year: number, monthIndex: number, day: number): string {
    return `${String(year).padStart(4, '0')}-${String(monthIndex + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
}

/**
 * The fiscal anchor for a year and month offset, CLAMPED to the month's length.
 *
 * `monthIndex` may exceed 11 or go negative; `Date.UTC` normalises it into the neighbouring year, so
 * "the quarter after the one starting in November" needs no special case.
 *
 * The clamp matters: a year starting 31 January puts its second quarter on "31 April", which
 * `Date.UTC` would roll to 1 May, making every Q2 boundary a day late. Clamping to 30 April keeps
 * each quarter inside the month its start names.
 */
function anchor(year: number, monthIndex: number, day: number): string {
    const normalised = new Date(Date.UTC(year, monthIndex, 1));
    const y = normalised.getUTCFullYear();
    const m = normalised.getUTCMonth();
    return dayFromParts(y, m, Math.min(day, daysInMonth(y, m)));
}

/**
 * The fiscal year containing `today`, labelled by the calendar year it starts in.
 *
 * The rollover compares against the clamped anchor. For a start that does not exist in its own month
 * (29 February, 31 April) that differs by a few days from a rule that compares the stored day raw;
 * the clamp is kept because every quarter boundary derives from the same anchors, and a rollover on
 * the raw day would select a window that does not contain the date that selected it.
 */
export function FiscalYearOf(today: string, start: FiscalYearStart): number {
    const calendarYear = Number(today.slice(0, 4));
    return today >= anchor(calendarYear, start.Month - 1, start.Day) ? calendarYear : calendarYear - 1;
}

/** Start of quarter `index` of `fiscalYear`. Index -1 and 4 reach into the neighbouring years. */
function quarterStart(fiscalYear: number, index: number, start: FiscalYearStart): string {
    return anchor(fiscalYear, start.Month - 1 + index * 3, start.Day);
}

/**
 * Which quarter of its fiscal year `today` falls in, 0-3.
 *
 * Walks down from Q4 to the first quarter that has begun, rather than dividing a month difference by
 * three: on a 6 April year, 3 July is still Q1 and the division puts it in Q2.
 */
export function FiscalQuarterOf(today: string, fiscalYear: number, start: FiscalYearStart): number {
    for (let index = 3; index > 0; index--) {
        if (today >= quarterStart(fiscalYear, index, start)) {
            return index;
        }
    }
    return 0;
}

/** Today in the business time zone. The default `today` for every window. */
export function BusinessToday(): string {
    return BusinessTimeZoneEngine.Instance.Today();
}

function customWindow(label: string, custom: CustomRange | null): PeriodWindow {
    // An empty picker is no bound on that side. Two dates picked the wrong way round are read as the
    // range they describe, not as a window that matches nothing.
    let from = IsoDay(custom?.Start);
    let to = IsoDay(custom?.End);
    if (from && to && from > to) {
        [from, to] = [to, from];
    }
    return { Key: 'custom', Label: label, Start: from, End: to };
}

/**
 * The window a period key selects, as inclusive `YYYY-MM-DD` bounds.
 *
 * `alltime` returns nulls rather than a very wide pair of dates: a wide bound still excludes a row
 * with a NULL date, and no bound is what "all time" asks.
 */
export function ResolvePeriod(
    key: PeriodKey,
    start: FiscalYearStart = CALENDAR_YEAR_START,
    today: string = BusinessToday(),
    custom: CustomRange | null = null,
): PeriodWindow {
    const Label = labelFor(key);
    if (key === 'alltime') {
        return { Key: key, Label, Start: null, End: null };
    }
    if (key === 'custom') {
        return customWindow(Label, custom);
    }
    const fiscalYear = FiscalYearOf(today, start);
    if (key === 'year' || key === 'lastyear') {
        const year = key === 'year' ? fiscalYear : fiscalYear - 1;
        // Index 4 is the next fiscal year's Q1, so the year end needs no case of its own.
        return { Key: key, Label, Start: quarterStart(year, 0, start), End: AddDays(quarterStart(year, 4, start), -1) };
    }
    const current = FiscalQuarterOf(today, fiscalYear, start);
    const index = key === 'lastquarter' ? current - 1 : key === 'nextquarter' ? current + 1 : current;
    return {
        Key: key,
        Label,
        Start: quarterStart(fiscalYear, index, start),
        End: AddDays(quarterStart(fiscalYear, index + 1, start), -1),
    };
}

/**
 * The window as query parameters (`PeriodStart`, `PeriodEnd`), or `undefined` when unbounded. An
 * open side is an omitted parameter, never an empty string.
 */
export function PeriodParameters(window?: PeriodWindow): Record<string, string> | undefined {
    if (!window) {
        return undefined;
    }
    const parameters: Record<string, string> = {};
    if (window.Start !== null) {
        parameters['PeriodStart'] = window.Start;
    }
    if (window.End !== null) {
        parameters['PeriodEnd'] = window.End;
    }
    return Object.keys(parameters).length ? parameters : undefined;
}

/**
 * The window as a RunView `ExtraFilter` clause over a DATE column, or null when unbounded. Bounds are
 * inclusive and written as ISO date strings, which the column compares as days.
 *
 * @param column the DATE column to bound. A trusted identifier from the caller, never user input.
 */
export function PeriodSqlFilter(column: string, window: PeriodWindow): string | null {
    const parts: string[] = [];
    if (window.Start !== null && IsCalendarDay(window.Start)) {
        parts.push(`${column} >= '${window.Start}'`);
    }
    if (window.End !== null && IsCalendarDay(window.End)) {
        parts.push(`${column} <= '${window.End}'`);
    }
    return parts.length ? parts.join(' AND ') : null;
}

/** True when an inclusive window contains `date`. A null bound is no bound, never a failed match. */
export function WithinWindow(date: string, window: PeriodWindow): boolean {
    if (window.Start !== null && date < window.Start) {
        return false;
    }
    return !(window.End !== null && date > window.End);
}

/** "Jul 1, 2026 – Sep 30, 2026", or "all time" when unbounded. For display, never for a filter. */
export function FormatWindow(window: PeriodWindow): string {
    if (window.Start === null && window.End === null) {
        return 'all time';
    }
    if (window.Start === null) {
        return `up to ${DayLabel(window.End)}`;
    }
    if (window.End === null) {
        return `from ${DayLabel(window.Start)}`;
    }
    return `${DayLabel(window.Start)} – ${DayLabel(window.End)}`;
}

/** The period in a sentence: "this quarter", "all time", or the dates of a custom range. */
export function PeriodPhrase(window: PeriodWindow): string {
    if (window.Key === 'alltime') {
        return 'all time';
    }
    if (window.Key === 'custom') {
        return FormatWindow(window);
    }
    return window.Label.toLowerCase();
}
