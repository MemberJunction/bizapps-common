import { describe, expect, it } from 'vitest';

import { ExclusionsExtraFilter, FromRunView, RulesExtraFilter } from '../load.js';

const SET = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';
const CONN = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

describe('FromRunView', () => {
    it('does not convert a failed read into an empty list', () => {
        const failed = FromRunView(false, [], 'ActivitySyncExclusion');
        expect(failed).toEqual({ Failed: true, Issue: 'ActivitySyncExclusion lookup failed.' });
        const emptyOk = FromRunView(true, [], 'ActivitySyncExclusion');
        expect(emptyOk).toEqual({ Failed: false, Rows: [] });
        const nullOk = FromRunView<{ ID: string }>(true, null, 'ActivitySyncExclusion');
        expect(nullOk).toEqual({ Failed: false, Rows: [] });
    });
});

describe('ExclusionsExtraFilter', () => {
    it('loads globals only when no rule sets are bound', () => {
        expect(ExclusionsExtraFilter([])).toBe('ActivitySyncRuleSetID IS NULL');
    });

    it('loads globals plus the bound sets', () => {
        expect(ExclusionsExtraFilter([SET])).toBe(
            `(ActivitySyncRuleSetID IS NULL OR ActivitySyncRuleSetID IN ('${SET}'))`,
        );
    });
});

describe('RulesExtraFilter', () => {
    it('uses bound sets when present and the deprecated connection owner only when none are', () => {
        expect(RulesExtraFilter([SET], CONN)).toBe(`ActivitySyncRuleSetID IN ('${SET}')`);
        expect(RulesExtraFilter([], CONN)).toBe(`ActivitySyncConnectionID = '${CONN}'`);
    });
});
