/**
 * AC15 equivalent — the seeded ScheduledJob points at the seeded Action, hourly, Skip/RunOnce.
 *
 * Metadata integrity, not behaviour. MJ ActionEngine resolves a driver from the Action row;
 * a @RegisterClass key no row references has no invocation path. This check is the one that
 * would have caught Common.SyncActivities shipping as a class only.
 *
 * JSON on disk is the PR artifact. The release Metadata_Sync is the build engineer's job.
 */
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const REPO = join(dirname(fileURLToPath(import.meta.url)), '../../../..');

interface MetaRecord {
    fields?: Record<string, unknown>;
    primaryKey?: { ID?: string };
    relatedEntities?: Record<string, Array<{ fields?: Record<string, unknown>; primaryKey?: { ID?: string } }>>;
}

function load(rel: string): MetaRecord[] {
    return JSON.parse(readFileSync(join(REPO, rel), 'utf8')) as MetaRecord[];
}

describe('Common.SyncActivities trigger metadata (AC15)', () => {
    const actions = load('metadata/actions/.common-actions.json');
    const jobs = load('metadata/scheduled-jobs/.common-scheduled-jobs.json');
    const action = actions[0];
    const job = jobs[0];

    it('seeds an Active Action whose DriverClass is Common.SyncActivities', () => {
        expect(action?.fields?.DriverClass).toBe('Common.SyncActivities');
        expect(action?.fields?.Status).toBe('Active');
        expect(action?.fields?.Type).toBe('Custom');
        expect(action?.primaryKey?.ID).toMatch(
            /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/,
        );
    });

    it('seeds a Limit input param on that Action', () => {
        const params = action?.relatedEntities?.['MJ: Action Params'] ?? [];
        const limit = params.find((p) => p.fields?.Name === 'Limit');
        expect(limit).toBeTruthy();
        expect(limit?.fields?.Type).toBe('Input');
        expect(limit?.fields?.IsRequired).toBe(false);
        expect(limit?.fields?.DefaultValue).toBe('100');
    });

    it('seeds result codes the Action actually returns', () => {
        const codes = (action?.relatedEntities?.['MJ: Action Result Codes'] ?? []).map(
            (r) => r.fields?.ResultCode,
        );
        expect(codes.sort()).toEqual(['ERROR', 'NO_CONNECTIONS', 'PARTIAL', 'SUCCESS'].sort());
    });

    it('seeds an hourly Active job pointing at that Action, Skip / RunOnce', () => {
        expect(job?.fields?.CronExpression).toBe('0 0 * * * *');
        expect(job?.fields?.Status).toBe('Active');
        expect(job?.fields?.ConcurrencyMode).toBe('Skip');
        expect(job?.fields?.MissedRunPolicy).toBe('RunOnce');
        const config = job?.fields?.Configuration as { ActionID?: string } | undefined;
        expect(config?.ActionID).toBe(action?.primaryKey?.ID);
    });
});
