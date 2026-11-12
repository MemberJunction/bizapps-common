/**
 * The period windows, asserted at their BOUNDARIES.
 *
 * Every defect this module can carry is an off-by-one at an edge, and an off-by-one at an edge is
 * invisible on screen. So each case asserts the first and last day in, and the day either side out,
 * rather than a date in the middle, which passes for any window wide enough to contain it.
 *
 * The off-calendar starts exercise the code paths that exist because the start is configurable:
 * month normalisation past December, day clamping on a short month, and a quarter index that cannot
 * be derived by dividing a month difference by three.
 */
import { describe, expect, it } from 'vitest';

import {
    CALENDAR_YEAR_START,
    DayLabel,
    DescribeFiscalBasis,
    FiscalQuarterOf,
    FiscalYearOf,
    FormatWindow,
    IsoDay,
    PERIOD_OPTIONS,
    PeriodKeyOf,
    PeriodParameters,
    PeriodPhrase,
    PeriodSqlFilter,
    ResolveFiscalYearStart,
    ResolvePeriod,
    WithinWindow,
    type FiscalYearStart,
} from '../dashboard-period';

const JANUARY: FiscalYearStart = { Month: 1, Day: 1 };
const JULY: FiscalYearStart = { Month: 7, Day: 1 };
/** The UK tax year. A non-first day, which is where month arithmetic stops being enough. */
const APRIL_6: FiscalYearStart = { Month: 4, Day: 6 };
/** Starts on a 31st, so two of its four quarter boundaries land on months that have no 31st. */
const JANUARY_31: FiscalYearStart = { Month: 1, Day: 31 };

describe('ResolveFiscalYearStart', () => {
    it('reports a calendar fallback and its cause, so the failure modes stay distinguishable', () => {
        expect(ResolveFiscalYearStart(null)).toEqual({ Start: CALENDAR_YEAR_START, Basis: 'unavailable' });
        expect(ResolveFiscalYearStart([])).toEqual({ Start: CALENDAR_YEAR_START, Basis: 'no-profiles' });
    });

    it('agreement is about the value, not the row count', () => {
        expect(ResolveFiscalYearStart([JANUARY, { Month: 1, Day: 1 }, { Month: 1, Day: 1 }])).toEqual({
            Start: { Month: 1, Day: 1 },
            Basis: 'profile',
        });
    });

    it('takes the configured start when every company agrees', () => {
        expect(ResolveFiscalYearStart([JULY, { Month: 7, Day: 1 }])).toEqual({ Start: { Month: 7, Day: 1 }, Basis: 'profile' });
    });

    it('refuses to pick when companies disagree, and falls back to the calendar', () => {
        const resolution = ResolveFiscalYearStart([JULY, APRIL_6]);
        expect(resolution.Basis).toBe('mixed');
        expect(resolution.Start).toEqual(CALENDAR_YEAR_START);
    });

    it('a disagreement only on the day is still a disagreement', () => {
        expect(ResolveFiscalYearStart([{ Month: 4, Day: 1 }, { Month: 4, Day: 6 }]).Basis).toBe('mixed');
    });

    it('every basis describes itself without naming an internal state', () => {
        for (const rows of [null, [], [JULY], [JULY, APRIL_6]]) {
            const text = DescribeFiscalBasis(ResolveFiscalYearStart(rows));
            expect(text.length).toBeGreaterThan(0);
            expect(text).not.toMatch(/unavailable|no-profiles|undefined/);
        }
        expect(DescribeFiscalBasis(ResolveFiscalYearStart([APRIL_6]))).toBe('fiscal year starts Apr 6');
    });

    it('pending is describable and does not claim the source is absent', () => {
        const text = DescribeFiscalBasis({ Start: CALENDAR_YEAR_START, Basis: 'pending' });
        expect(text.length).toBeGreaterThan(0);
        expect(text).not.toMatch(/no company|different fiscal years|could not be read/i);
    });

    it('is never itself the pending basis', () => {
        for (const rows of [null, [], [JULY], [JULY, APRIL_6]]) {
            expect(ResolveFiscalYearStart(rows).Basis).not.toBe('pending');
        }
    });
});

describe('FiscalYearOf: labelled by the year it starts in', () => {
    it('is the calendar year when the year starts in January', () => {
        expect(FiscalYearOf('2026-01-01', JANUARY)).toBe(2026);
        expect(FiscalYearOf('2026-12-31', JANUARY)).toBe(2026);
    });

    it('a July-start year spanning two calendar years takes the earlier label', () => {
        expect(FiscalYearOf('2026-06-30', JULY)).toBe(2025);
        expect(FiscalYearOf('2026-07-01', JULY)).toBe(2026);
        expect(FiscalYearOf('2027-06-30', JULY)).toBe(2026);
    });

    it('rolls over on the start day, not on the first of the start month', () => {
        expect(FiscalYearOf('2026-04-05', APRIL_6)).toBe(2025);
        expect(FiscalYearOf('2026-04-06', APRIL_6)).toBe(2026);
    });

    it('clamps an impossible start day, and the selected window still contains the date', () => {
        const FEB_29: FiscalYearStart = { Month: 2, Day: 29 };
        expect(FiscalYearOf('2027-02-28', FEB_29)).toBe(2027);
        expect(FiscalYearOf('2027-02-27', FEB_29)).toBe(2026);
        const w = ResolvePeriod('quarter', FEB_29, '2027-02-28');
        expect(w.Start! <= '2027-02-28').toBe(true);
        expect(w.End! >= '2027-02-28').toBe(true);
    });
});

describe('ResolvePeriod: a January start reproduces calendar quarters', () => {
    it('Q1 runs 1 Jan to 31 Mar', () => {
        expect(ResolvePeriod('quarter', JANUARY, '2026-02-14')).toMatchObject({ Start: '2026-01-01', End: '2026-03-31' });
    });

    it('Q4 runs 1 Oct to 31 Dec, and does not bleed into January', () => {
        expect(ResolvePeriod('quarter', JANUARY, '2026-12-31')).toMatchObject({ Start: '2026-10-01', End: '2026-12-31' });
    });

    it('the fiscal year is the whole calendar year', () => {
        expect(ResolvePeriod('year', JANUARY, '2026-08-09')).toMatchObject({ Start: '2026-01-01', End: '2026-12-31' });
    });
});

describe('ResolvePeriod: an off-calendar (July) start', () => {
    it('Q1 begins on the fiscal start, not in January', () => {
        expect(ResolvePeriod('quarter', JULY, '2026-08-15')).toMatchObject({ Start: '2026-07-01', End: '2026-09-30' });
    });

    it('Q3 crosses the calendar new year without a special case', () => {
        expect(ResolvePeriod('quarter', JULY, '2027-02-10')).toMatchObject({ Start: '2027-01-01', End: '2027-03-31' });
    });

    it('the fiscal year spans two calendar years', () => {
        expect(ResolvePeriod('year', JULY, '2027-02-10')).toMatchObject({ Start: '2026-07-01', End: '2027-06-30' });
    });

    it('the last day of one fiscal year and the first of the next are adjacent, never overlapping', () => {
        expect(ResolvePeriod('year', JULY, '2027-06-30').End).toBe('2027-06-30');
        expect(ResolvePeriod('year', JULY, '2027-07-01').Start).toBe('2027-07-01');
    });
});

describe('ResolvePeriod: a start day that is not the 1st (6 April)', () => {
    it('quarters run from the 6th to the 5th', () => {
        expect(ResolvePeriod('quarter', APRIL_6, '2026-05-01')).toMatchObject({ Start: '2026-04-06', End: '2026-07-05' });
    });

    it('3 July is still Q1, the case a month-difference calculation gets wrong', () => {
        expect(FiscalQuarterOf('2026-07-03', 2026, APRIL_6)).toBe(0);
        expect(FiscalQuarterOf('2026-07-06', 2026, APRIL_6)).toBe(1);
    });

    it('the last day of one quarter is the day before the next begins', () => {
        expect(ResolvePeriod('quarter', APRIL_6, '2026-07-05').End).toBe('2026-07-05');
        expect(ResolvePeriod('quarter', APRIL_6, '2026-07-06').Start).toBe('2026-07-06');
    });
});

describe('ResolvePeriod: a 31st start clamps rather than rolling into the next month', () => {
    it('Q2 of a 31 January year starts 30 April, not 1 May', () => {
        expect(ResolvePeriod('quarter', JANUARY_31, '2026-05-15')).toMatchObject({ Start: '2026-04-30', End: '2026-07-30' });
    });

    it('the fiscal year still closes the day before the next one opens', () => {
        expect(ResolvePeriod('year', JANUARY_31, '2026-06-01')).toMatchObject({ Start: '2026-01-31', End: '2027-01-30' });
    });
});

describe('ResolvePeriod: last and next quarter', () => {
    it('last quarter is the preceding quarter within the same fiscal year', () => {
        expect(ResolvePeriod('lastquarter', JANUARY, '2026-08-09')).toMatchObject({ Start: '2026-04-01', End: '2026-06-30' });
    });

    it('rolls back across the fiscal year boundary from Q1, not across the calendar one', () => {
        expect(ResolvePeriod('lastquarter', JULY, '2026-08-15')).toMatchObject({ Start: '2026-04-01', End: '2026-06-30' });
    });

    it('from Q1 of a January year it is the previous calendar year Q4', () => {
        expect(ResolvePeriod('lastquarter', JANUARY, '2026-01-01')).toMatchObject({ Start: '2025-10-01', End: '2025-12-31' });
    });

    it('never overlaps the current quarter', () => {
        const last = ResolvePeriod('lastquarter', APRIL_6, '2026-08-20');
        const now = ResolvePeriod('quarter', APRIL_6, '2026-08-20');
        expect(last.End! < now.Start!).toBe(true);
    });

    it('next quarter follows this one, across the fiscal year end', () => {
        expect(ResolvePeriod('nextquarter', JULY, '2026-08-15')).toMatchObject({ Start: '2026-10-01', End: '2026-12-31' });
        expect(ResolvePeriod('nextquarter', JULY, '2027-05-10')).toMatchObject({ Start: '2027-07-01', End: '2027-09-30' });
    });

    it('last year is the fiscal year before the one today is in', () => {
        expect(ResolvePeriod('lastyear', JULY, '2027-02-10')).toMatchObject({ Start: '2025-07-01', End: '2026-06-30' });
        expect(ResolvePeriod('lastyear', JANUARY, '2026-08-09')).toMatchObject({ Start: '2025-01-01', End: '2025-12-31' });
    });
});

describe('ResolvePeriod: leap years', () => {
    it('a February quarter ends on the 29th in a leap year and the 28th otherwise', () => {
        expect(ResolvePeriod('quarter', { Month: 12, Day: 1 }, '2028-01-15')).toMatchObject({ Start: '2027-12-01', End: '2028-02-29' });
        expect(ResolvePeriod('quarter', { Month: 12, Day: 1 }, '2027-01-15').End).toBe('2027-02-28');
    });

    it('29 February resolves without throwing', () => {
        expect(ResolvePeriod('quarter', JANUARY, '2028-02-29').End).toBe('2028-03-31');
    });
});

describe('ResolvePeriod: custom range', () => {
    it('takes its two dates, either of which may be open', () => {
        expect(ResolvePeriod('custom', JULY, '2026-08-15', { Start: '2026-02-01', End: '2026-03-15' })).toMatchObject({
            Key: 'custom',
            Label: 'Custom range',
            Start: '2026-02-01',
            End: '2026-03-15',
        });
        expect(ResolvePeriod('custom', JULY, '2026-08-15', { Start: '2026-02-01', End: null })).toMatchObject({ Start: '2026-02-01', End: null });
        expect(ResolvePeriod('custom', JULY, '2026-08-15', null)).toMatchObject({ Start: null, End: null });
    });

    it('reads dates picked the wrong way round as the range they describe, and drops a day that does not exist', () => {
        expect(ResolvePeriod('custom', JULY, '2026-08-15', { Start: '2026-03-15', End: '2026-02-01' })).toMatchObject({
            Start: '2026-02-01',
            End: '2026-03-15',
        });
        expect(ResolvePeriod('custom', JULY, '2026-08-15', { Start: '2026-02-30', End: 'soon' })).toMatchObject({ Start: null, End: null });
    });
});

describe('alltime', () => {
    it('is unbounded, not a very wide window', () => {
        expect(ResolvePeriod('alltime', JULY, '2026-08-15')).toMatchObject({ Start: null, End: null });
    });

    it('contains every date', () => {
        const w = ResolvePeriod('alltime', JULY, '2026-08-15');
        expect(WithinWindow('1999-01-01', w)).toBe(true);
        expect(WithinWindow('2099-12-31', w)).toBe(true);
    });
});

describe('WithinWindow', () => {
    const w = ResolvePeriod('quarter', JULY, '2026-08-15');

    it('includes both endpoints', () => {
        expect(WithinWindow('2026-07-01', w)).toBe(true);
        expect(WithinWindow('2026-09-30', w)).toBe(true);
    });

    it('excludes the day either side', () => {
        expect(WithinWindow('2026-06-30', w)).toBe(false);
        expect(WithinWindow('2026-10-01', w)).toBe(false);
    });
});

describe('query forms', () => {
    const q = ResolvePeriod('quarter', JULY, '2026-08-15');

    it('PeriodSqlFilter bounds a DATE column inclusively on both sides', () => {
        expect(PeriodSqlFilter('EffectiveDate', q)).toBe("EffectiveDate >= '2026-07-01' AND EffectiveDate <= '2026-09-30'");
    });

    it('PeriodSqlFilter writes one side for a half-open range and nothing for all time', () => {
        const from = ResolvePeriod('custom', JULY, '2026-08-15', { Start: '2026-02-01', End: null });
        expect(PeriodSqlFilter('PostingDate', from)).toBe("PostingDate >= '2026-02-01'");
        expect(PeriodSqlFilter('PostingDate', ResolvePeriod('alltime', JULY, '2026-08-15'))).toBeNull();
    });

    it('PeriodSqlFilter never writes a bound that is not a calendar day', () => {
        expect(PeriodSqlFilter('PostingDate', { Key: 'custom', Label: 'x', Start: "2026-01-01' OR 1=1 --", End: null })).toBeNull();
    });

    it('PeriodParameters omits an open side rather than sending an empty string', () => {
        expect(PeriodParameters(q)).toEqual({ PeriodStart: '2026-07-01', PeriodEnd: '2026-09-30' });
        expect(PeriodParameters(ResolvePeriod('alltime', JULY, '2026-08-15'))).toBeUndefined();
        expect(PeriodParameters(undefined)).toBeUndefined();
    });
});

describe('presentation', () => {
    it('defaults to this quarter and offers the periods in order', () => {
        expect(PERIOD_OPTIONS[0].Key).toBe('quarter');
        expect(PERIOD_OPTIONS.map((o) => o.Key)).toEqual(['quarter', 'lastquarter', 'nextquarter', 'year', 'lastyear', 'alltime', 'custom']);
    });

    it('states the bounds a reader would otherwise have to guess at', () => {
        expect(FormatWindow(ResolvePeriod('quarter', JULY, '2026-08-15'))).toBe('Jul 1, 2026 – Sep 30, 2026');
        expect(FormatWindow(ResolvePeriod('alltime', JULY, '2026-08-15'))).toBe('all time');
        expect(FormatWindow({ Key: 'custom', Label: 'Custom range', Start: null, End: '2026-03-15' })).toBe('up to Mar 15, 2026');
        expect(FormatWindow({ Key: 'custom', Label: 'Custom range', Start: '2026-02-01', End: null })).toBe('from Feb 1, 2026');
    });

    it('phrases a period for a sentence', () => {
        expect(PeriodPhrase(ResolvePeriod('lastquarter', JULY, '2026-08-15'))).toBe('last quarter');
        expect(PeriodPhrase(ResolvePeriod('alltime', JULY, '2026-08-15'))).toBe('all time');
        expect(PeriodPhrase(ResolvePeriod('custom', JULY, '2026-08-15', { Start: '2026-02-01', End: '2026-02-28' }))).toBe('Feb 1, 2026 – Feb 28, 2026');
    });

    it('reads a stored day from its UTC parts, whatever the machine zone', () => {
        expect(DayLabel(new Date('2026-10-01T00:00:00.000Z'))).toBe('Oct 1, 2026');
        expect(DayLabel('2026-10-01')).toBe('Oct 1, 2026');
        expect(DayLabel(null)).toBe('');
        expect(DayLabel('soon')).toBe('');
    });

    it('accepts only days that exist and keys it offers', () => {
        expect(IsoDay('2028-02-29')).toBe('2028-02-29');
        expect(IsoDay('2027-02-29')).toBeNull();
        expect(IsoDay('')).toBeNull();
        expect(PeriodKeyOf('lastyear')).toBe('lastyear');
        expect(PeriodKeyOf('decade')).toBeNull();
    });
});
