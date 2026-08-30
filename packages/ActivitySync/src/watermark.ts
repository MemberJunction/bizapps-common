/**
 * @fileoverview The two watermark rules, as enforced behaviour rather than advice.
 *
 * These live in the engine (and are consumed by {@link BaseActivitySyncProvider}) rather than being
 * exported as helpers a provider may forget to call. Both failure modes are SILENT and PERMANENT,
 * which is exactly the class of rule that must not be optional.
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import { ActivitySourceKind, NormalizedItem, WatermarkBasisForKind } from './types.js';

/** The per-item tallies a run produces, and the only input to whether the watermark may move. */
export interface RunOutcome {
    /** Passed qualification and was written (or was a duplicate — a duplicate has been seen). */
    Settled: number;
    /** Qualification said no. SEEN to a conclusion, so the watermark may pass it. */
    Discarded: number;
    /**
     * Errored before reaching a conclusion. NOT seen.
     *
     * The distinction is the whole rule. Where a transport has no date filter, anything the
     * watermark passes can never be re-fetched, so advancing over a failure loses the item
     * permanently.
     */
    Failed: number;
}

/**
 * The newest point this batch can honestly claim to have seen.
 *
 * @param kind        the surface — selects the basis (see {@link WatermarkBasisForKind})
 * @param items       the batch's normalized items
 * @param observedAt  when the provider looked; used by future-dated surfaces
 * @returns the candidate watermark, or null when there is nothing to claim
 */
export function ResolveHighWatermark(
    kind: ActivitySourceKind,
    items: readonly NormalizedItem[],
    observedAt: Date,
): Date | null {
    if (WatermarkBasisForKind(kind) === 'ObservationTime') {
        // A future-dated surface reports when it LOOKED, not when its items happen.
        return items.length > 0 ? observedAt : null;
    }
    return newestStartedAt(items);
}

/** The latest `StartedAt` across the batch, or null when the batch is empty. */
function newestStartedAt(items: readonly NormalizedItem[]): Date | null {
    let newest: Date | null = null;
    for (const item of items) {
        if (newest === null || item.StartedAt.getTime() > newest.getTime()) {
            newest = item.StartedAt;
        }
    }
    return newest;
}

/**
 * Whether the run earned the right to move the watermark forward.
 *
 * Any failure withholds it. The cost of not advancing is re-fetching items the next run will
 * recognise as duplicates; the cost of advancing wrongly is losing them for good. Those are not
 * comparable, so this is deliberately not a threshold.
 */
export function CanAdvanceWatermark(outcome: RunOutcome): boolean {
    return outcome.Failed === 0;
}

/**
 * The watermark to persist after a run — the current value unless the run both earned an advance
 * and actually moved forward.
 *
 * Never moves BACKWARDS. Two runs racing (a scheduled job whose `ConcurrencyMode` is not `Skip`)
 * can otherwise leave the watermark behind where the earlier run reached, which silently re-reads
 * a window on every subsequent pass.
 */
/** Calendar watermark lives in ActivitySyncConnection.Settings so it cannot hide behind LastSyncAt. */
export const CALENDAR_WATERMARK_SETTING = 'CalendarLastSyncAt';

export function ParseConnectionSettings(settings: string | null | undefined): Record<string, unknown> {
    if (!settings) return {};
    try {
        const parsed: unknown = JSON.parse(settings);
        if (parsed !== null && typeof parsed === 'object' && !Array.isArray(parsed)) {
            return parsed as Record<string, unknown>;
        }
    } catch {
        /* hand-edited JSON is treated as empty — re-read the window, let dedupe absorb it */
    }
    return {};
}

function asDate(value: Date | string | null | undefined): Date | null {
    if (value == null || value === '') return null;
    const d = value instanceof Date ? value : new Date(value);
    return Number.isNaN(d.getTime()) ? null : d;
}

/**
 * One watermark per surface. Messages use LastSyncAt; calendar uses Settings.
 * A shared column takes the max of both, so a meeting older than the newest
 * email is judged already-seen and skipped forever.
 */
export function SurfaceWatermark(
    kind: ActivitySourceKind,
    lastSyncAt: Date | string | null | undefined,
    settings: string | null | undefined,
): Date | null {
    if (kind === 'Calendar') {
        const raw = ParseConnectionSettings(settings)[CALENDAR_WATERMARK_SETTING];
        return typeof raw === 'string' ? asDate(raw) : null;
    }
    return asDate(lastSyncAt);
}

/** Merge the calendar watermark into Settings without dropping other keys. */
export function MergeCalendarWatermark(settings: string | null | undefined, at: Date): string {
    const bag = ParseConnectionSettings(settings);
    bag[CALENDAR_WATERMARK_SETTING] = at.toISOString();
    return JSON.stringify(bag);
}

export function NextWatermark(current: Date | null, candidate: Date | null, outcome: RunOutcome): Date | null {
    if (!CanAdvanceWatermark(outcome) || candidate === null) {
        return current;
    }
    if (current !== null && candidate.getTime() <= current.getTime()) {
        return current;
    }
    return candidate;
}
