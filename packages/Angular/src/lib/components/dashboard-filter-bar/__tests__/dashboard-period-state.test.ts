/**
 * The period selection as a kept value. Every reader validates: a stale link or an old setting
 * falls back field by field instead of selecting something that does not exist.
 */
import { describe, expect, it } from 'vitest';

import {
    DEFAULT_PERIOD_STATE,
    NormalizePeriodState,
    ParsePeriodParams,
    ParsePeriodStateJSON,
    PeriodStateParams,
    PeriodWindowOf,
    SamePeriodState,
} from '../dashboard-period-state';

describe('NormalizePeriodState', () => {
    it('falls back to this quarter for an unknown or missing period', () => {
        expect(NormalizePeriodState({ Period: 'decade' })).toEqual(DEFAULT_PERIOD_STATE);
        expect(NormalizePeriodState(null)).toEqual(DEFAULT_PERIOD_STATE);
    });

    it('keeps custom dates only on a custom range, and only days that exist', () => {
        expect(NormalizePeriodState({ Period: 'year', CustomStart: '2026-01-01', CustomEnd: '2026-02-01' })).toEqual({
            Period: 'year',
            CustomStart: null,
            CustomEnd: null,
        });
        expect(NormalizePeriodState({ Period: 'custom', CustomStart: '2026-02-30', CustomEnd: '2026-03-01' })).toEqual({
            Period: 'custom',
            CustomStart: null,
            CustomEnd: '2026-03-01',
        });
    });
});

describe('query params', () => {
    it('round-trip a custom range', () => {
        const state = { Period: 'custom' as const, CustomStart: '2026-02-01', CustomEnd: '2026-03-15' };
        const params = PeriodStateParams(state);
        expect(params).toEqual({ period: 'custom', from: '2026-02-01', to: '2026-03-15' });
        expect(ParsePeriodParams({ period: params['period'] ?? undefined, from: params['from'] ?? undefined, to: params['to'] ?? undefined })).toEqual(state);
    });

    it('leave the default out of the address', () => {
        expect(PeriodStateParams(DEFAULT_PERIOD_STATE)).toEqual({ period: null, from: null, to: null });
    });

    it('drop dates a non-custom period carries', () => {
        expect(ParsePeriodParams({ period: 'lastyear', from: '2026-02-01' })).toEqual({ Period: 'lastyear', CustomStart: null, CustomEnd: null });
    });
});

describe('ParsePeriodStateJSON', () => {
    it('reads a stored state', () => {
        expect(ParsePeriodStateJSON('{"Period":"lastquarter"}')).toEqual({ Period: 'lastquarter', CustomStart: null, CustomEnd: null });
    });

    it('reads anything unreadable as the default', () => {
        expect(ParsePeriodStateJSON(undefined)).toEqual(DEFAULT_PERIOD_STATE);
        expect(ParsePeriodStateJSON('not json')).toEqual(DEFAULT_PERIOD_STATE);
        expect(ParsePeriodStateJSON('42')).toEqual(DEFAULT_PERIOD_STATE);
        expect(ParsePeriodStateJSON('null')).toEqual(DEFAULT_PERIOD_STATE);
    });
});

describe('SamePeriodState and PeriodWindowOf', () => {
    it('compare after normalising', () => {
        expect(SamePeriodState({ Period: 'year', CustomStart: '2026-01-01', CustomEnd: null }, { Period: 'year', CustomStart: null, CustomEnd: null })).toBe(true);
        expect(SamePeriodState(DEFAULT_PERIOD_STATE, { Period: 'year', CustomStart: null, CustomEnd: null })).toBe(false);
    });

    it('resolve the window a state selects', () => {
        expect(PeriodWindowOf({ Period: 'quarter', CustomStart: null, CustomEnd: null }, { Month: 7, Day: 1 }, '2026-08-15')).toMatchObject({
            Start: '2026-07-01',
            End: '2026-09-30',
        });
        expect(PeriodWindowOf({ Period: 'custom', CustomStart: '2026-02-01', CustomEnd: null }, undefined, '2026-08-15')).toMatchObject({
            Start: '2026-02-01',
            End: null,
        });
    });
});
