/**
 * The directory dashboard's "people added" bars are business days (golive #168): the query buckets
 * __mj_CreatedAt by fnBusinessDayOf against fnBusinessToday(), and the labels name the same days by
 * the business zone. Bucketing or labelling by UTC put Thursday evening in Chicago under "Fri".
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { BusinessTimeZoneEngine } from '@mj-biz-apps/common-entities';

const runQuery = vi.fn();
vi.mock('@memberjunction/core', async (importOriginal) => {
    const actual = await importOriginal<typeof import('@memberjunction/core')>();
    return { ...actual, RunQuery: class { RunQuery = runQuery; } };
});

import { LoadDirectoryDashboardSummary } from '../directory-queries';

const SUMMARY_SQL = fileURLToPath(new URL('../../../../../../metadata/queries/SQL/directory-dashboard-summary.sql', import.meta.url));

describe('LoadDirectoryDashboardSummary day labels', () => {
    beforeEach(() => {
        vi.useFakeTimers();
        // Thursday 8:30 PM in Chicago is already Friday in UTC.
        vi.setSystemTime(new Date('2026-10-02T01:30:00.000Z'));
        vi.spyOn(BusinessTimeZoneEngine.Instance, 'Resolve').mockReturnValue('America/Chicago');
        runQuery.mockResolvedValue({ Success: true, Results: [{ PeopleAddedD0: 4, PeopleAddedD1: 1 }] });
    });

    afterEach(() => {
        vi.useRealTimers();
        vi.restoreAllMocks();
    });

    it('labels the current bar with the business weekday, not the UTC one', async () => {
        const summary = await LoadDirectoryDashboardSummary();
        const current = summary!.PeoplePerDay[6];

        expect(current).toEqual({ Label: 'Thu', Value: 4, Current: true });
    });

    it('labels the week back from the business day', async () => {
        const summary = await LoadDirectoryDashboardSummary();

        expect(summary!.PeoplePerDay.map((bar) => bar.Label)).toEqual(['Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu']);
    });
});

describe('the directory dashboard summary query', () => {
    const sql = readFileSync(SUMMARY_SQL, 'utf8').replace(/^\s*--.*$/gm, '');

    it('buckets people by business day, against the business today', () => {
        expect(sql).toContain('CROSS JOIN [__mj_BizAppsCommon].[fnBusinessToday]() AS bt');
        for (let ago = 0; ago <= 6; ago++) {
            const day = ago === 0 ? 'bt.Today' : `DATEADD(DAY, -${ago}, bt.Today)`;
            expect(sql).toContain(`WHEN [__mj_BizAppsCommon].[fnBusinessDayOf](__mj_CreatedAt) = ${day} THEN 1 ELSE 0 END), 0) AS PeopleAddedD${ago},`);
        }
    });

    it('reads no UTC day and writes no AT TIME ZONE, which MJ\'s SQL parser cannot read', () => {
        expect(sql).not.toMatch(/SYSUTCDATETIME|GETUTCDATE|AT TIME ZONE/i);
    });
});
