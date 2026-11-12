/**
 * @fileoverview The selected period as a value an app can keep: in a tab's query params, in a user
 * setting, or in component state. The filter bar reads and emits it.
 *
 * Every reader validates. A hand-edited link or an old setting falls back to the default for the
 * field it got wrong rather than selecting something that does not exist, and custom-range dates are
 * kept only while the period is `custom`.
 *
 * @module @mj-biz-apps/common-ng
 */
import {
    BusinessToday,
    CALENDAR_YEAR_START,
    DEFAULT_PERIOD,
    IsoDay,
    PeriodKeyOf,
    ResolvePeriod,
    type FiscalYearStart,
    type PeriodKey,
    type PeriodWindow,
} from './dashboard-period';

/** A period selection. `CustomStart` / `CustomEnd` are `YYYY-MM-DD` and mean something only for `custom`. */
export interface DashboardPeriodState {
    Period: PeriodKey;
    CustomStart: string | null;
    CustomEnd: string | null;
}

/** The selection a dashboard opens on. */
export const DEFAULT_PERIOD_STATE: DashboardPeriodState = { Period: DEFAULT_PERIOD, CustomStart: null, CustomEnd: null };

/** The query param each field is written to. */
export const PERIOD_PARAM = { Period: 'period', CustomStart: 'from', CustomEnd: 'to' } as const;

/**
 * A valid state from loosely-typed input: an unknown period becomes the default, a day that does not
 * exist becomes no bound, and dates on a non-custom period are dropped as stale.
 */
export function NormalizePeriodState(value: {
    Period?: string | null;
    CustomStart?: string | null;
    CustomEnd?: string | null;
} | null | undefined): DashboardPeriodState {
    const period = PeriodKeyOf(value?.Period) ?? DEFAULT_PERIOD;
    const custom = period === 'custom';
    return {
        Period: period,
        CustomStart: custom ? IsoDay(value?.CustomStart) : null,
        CustomEnd: custom ? IsoDay(value?.CustomEnd) : null,
    };
}

/** Reads the state from query params (`period`, `from`, `to`). */
export function ParsePeriodParams(params: Readonly<Record<string, string | undefined>>): DashboardPeriodState {
    return NormalizePeriodState({
        Period: params[PERIOD_PARAM.Period],
        CustomStart: params[PERIOD_PARAM.CustomStart],
        CustomEnd: params[PERIOD_PARAM.CustomEnd],
    });
}

/** The params to write. Every key is present; null removes it, so a default leaves a clean address. */
export function PeriodStateParams(state: DashboardPeriodState): Record<string, string | null> {
    const clean = NormalizePeriodState(state);
    return {
        [PERIOD_PARAM.Period]: clean.Period === DEFAULT_PERIOD ? null : clean.Period,
        [PERIOD_PARAM.CustomStart]: clean.CustomStart,
        [PERIOD_PARAM.CustomEnd]: clean.CustomEnd,
    };
}

/** Reads a state stored as JSON (a user setting). Anything unreadable is the default. */
export function ParsePeriodStateJSON(raw: string | null | undefined): DashboardPeriodState {
    if (!raw) {
        return DEFAULT_PERIOD_STATE;
    }
    try {
        const parsed: { Period?: string; CustomStart?: string; CustomEnd?: string } | null = JSON.parse(raw);
        return NormalizePeriodState(parsed && typeof parsed === 'object' ? parsed : null);
    } catch {
        return DEFAULT_PERIOD_STATE;
    }
}

/** True when two states select the same window. */
export function SamePeriodState(a: DashboardPeriodState, b: DashboardPeriodState): boolean {
    const x = NormalizePeriodState(a);
    const y = NormalizePeriodState(b);
    return x.Period === y.Period && x.CustomStart === y.CustomStart && x.CustomEnd === y.CustomEnd;
}

/** The window a state selects. `today` defaults to the business day. */
export function PeriodWindowOf(
    state: DashboardPeriodState,
    start: FiscalYearStart = CALENDAR_YEAR_START,
    today: string = BusinessToday(),
): PeriodWindow {
    return ResolvePeriod(state.Period, start, today, { Start: state.CustomStart, End: state.CustomEnd });
}
