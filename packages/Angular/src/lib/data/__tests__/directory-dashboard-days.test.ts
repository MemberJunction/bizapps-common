/**
 * The directory dashboard's "people added" bars are business days (golive #168): the per-day query
 * buckets __mj_CreatedAt by fnBusinessDayOf against fnBusinessToday(), and the labels name the same
 * days by the business zone. Bucketing or labelling by UTC put Thursday evening in Chicago under "Fri".
 *
 * The bars come from their own query, apart from the summary, because fnBusinessDayOf cannot be
 * inlined and makes any statement that calls it single-threaded.
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

const SQL_DIR = '../../../../../../metadata/queries/SQL/';
const SUMMARY_SQL = fileURLToPath(new URL(`${SQL_DIR}directory-dashboard-summary.sql`, import.meta.url));
const PER_DAY_SQL = fileURLToPath(new URL(`${SQL_DIR}directory-people-per-day.sql`, import.meta.url));

const SUMMARY_QUERY = 'Common: Directory Dashboard Summary';
const PER_DAY_QUERY = 'Common: Directory People Per Day';

/** RunQuery answers by query name, so a test can fail one query and not the other. */
function answer(byName: Record<string, () => unknown>): void {
    runQuery.mockImplementation(async (params: { QueryName: string }) => byName[params.QueryName]());
}

describe('LoadDirectoryDashboardSummary day labels', () => {
    beforeEach(() => {
        vi.useFakeTimers();
        // Thursday 8:30 PM in Chicago is already Friday in UTC.
        vi.setSystemTime(new Date('2026-10-02T01:30:00.000Z'));
        vi.spyOn(BusinessTimeZoneEngine.Instance, 'Resolve').mockReturnValue('America/Chicago');
        answer({
            [SUMMARY_QUERY]: () => ({ Success: true, Results: [{ ActivePeople: 10, TotalPeople: 12 }] }),
            [PER_DAY_QUERY]: () => ({ Success: true, Results: [{ PeopleAddedD0: 4, PeopleAddedD1: 1 }] }),
        });
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

describe('LoadDirectoryDashboardSummary failures', () => {
    afterEach(() => {
        vi.restoreAllMocks();
    });

    it('returns the counts without bars when only the per-day query fails', async () => {
        answer({
            [SUMMARY_QUERY]: () => ({ Success: true, Results: [{ ActivePeople: 10 }] }),
            [PER_DAY_QUERY]: () => ({ Success: false, ErrorMessage: 'timeout' }),
        });

        const summary = await LoadDirectoryDashboardSummary();

        expect(summary!.ActivePeopleCount).toBe(10);
        expect(summary!.PeoplePerDay).toEqual([]);
    });

    it('returns null, rather than throwing, when the summary query throws', async () => {
        answer({
            [SUMMARY_QUERY]: () => {
                throw new Error('network down');
            },
            [PER_DAY_QUERY]: () => ({ Success: true, Results: [{ PeopleAddedD0: 1 }] }),
        });

        await expect(LoadDirectoryDashboardSummary()).resolves.toBeNull();
    });
});

const stripComments = (path: string) => readFileSync(path, 'utf8').replace(/^\s*--.*$/gm, '');

describe('the directory people-per-day query', () => {
    const sql = stripComments(PER_DAY_SQL);

    it('buckets people by business day, against the business today', () => {
        expect(sql).toContain('FROM [__mj_BizAppsCommon].[fnBusinessToday]() AS bt');
        expect(sql).toContain('SELECT [__mj_BizAppsCommon].[fnBusinessDayOf](x.__mj_CreatedAt) AS CreatedDay');
        for (let ago = 0; ago <= 6; ago++) {
            const day = ago === 0 ? 'bt.Today' : `DATEADD(DAY, -${ago}, bt.Today)`;
            expect(sql).toContain(`WHEN d.CreatedDay = ${day} THEN 1 ELSE 0 END), 0) AS PeopleAddedD${ago}`);
        }
    });

    it('calls fnBusinessDayOf only for rows from the last eight days', () => {
        expect(sql).toContain('WHERE x.__mj_CreatedAt >= DATEADD(DAY, -8, SYSDATETIMEOFFSET())');
    });

    it('reads no UTC day and writes no AT TIME ZONE, which MJ\'s SQL parser cannot read', () => {
        expect(sql).not.toMatch(/SYSUTCDATETIME|GETUTCDATE|AT TIME ZONE/i);
    });
});

describe('the directory dashboard summary query', () => {
    const sql = stripComments(SUMMARY_SQL);

    it('calls no scalar business-day function, which would make the whole statement single-threaded', () => {
        expect(sql).not.toContain('fnBusinessDayOf');
    });

    it('counts people without an organization without reading vwPeople.CurrentOrganizationID', () => {
        expect(sql).not.toContain('CurrentOrganizationID');
        expect(sql).toContain('AS PeopleMissingOrganization');
    });
});
