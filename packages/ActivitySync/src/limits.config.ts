/**
 * Strongly-typed limits configuration resolver for `@mj-biz-apps/common-activity-sync`.
 *
 * Centralizes all `ResourceGuard` and `Tuning` bounds across the sync engine, consent intake,
 * Graph calendar/mail transports, and activity writer with safe fallback defaults, upper policy
 * ceilings, and runtime override registration (zero `any`, zero `unknown`).
 */

/** Hard inclusive lower and upper bounds enforced for a numeric limit key. */
export interface ActivitySyncLimitBounds {
    readonly Min: number;
    readonly Max: number;
    readonly Integer: boolean;
}

/**
 * RunawayGuard schema anchor for `@mj-biz-apps/common-activity-sync`.
 * `bizapps-common` contains 0 RunawayGuard sites repo-wide (no agent/workflow loop executors).
 */
export interface ActivitySyncRunawayGuardsConfig {
    readonly ZeroHitsConfirmed: true;
}

/** Bounded resource, API-cost, and request-count guard ceilings for activity sync. */
export interface ActivitySyncResourceGuardsConfig {
    /** Hard cap on runnable connections queried per fleet sync pass. */
    MaxRunnableConnections: number;
    /** Maximum HTTP requests per late-tag consent sweep. */
    MaxSweepRequests: number;
    /** Maximum consented items re-checked per run to bound API cost. */
    MaxWithdrawChecks: number;
    /** Maximum RFC 5322 References Message-IDs traversed per tagged thread. */
    MaxAncestorReferences: number;
    /** Maximum paged calendar requests per sync pass. */
    MaxCalendarPages: number;
    /** Maximum windowed mail requests per pass when bisecting dense ranges. */
    MaxMailRequests: number;
}

/** Operational tuning defaults for activity sync windows, batching, and body snippets. */
export interface ActivitySyncTuningConfig {
    /** Clock-skew overlap window in milliseconds for incremental consent sweeps. */
    SweepOverlapMs: number;
    /** Message-ID batch size per consent re-read lookup request. */
    RereadBatchSize: number;
    /** Default lookback window in days when checking for withdrawn consent tags. */
    WithdrawWindowDays: number;
    /** Default calendar lookback horizon in days on initial sync. */
    FirstRunLookbackDays: number;
    /** Default calendar forward horizon in days for scheduled meetings. */
    ForwardHorizonDays: number;
    /** Maximum Message-IDs combined in a single OData filter batch. */
    MessageIdBatchSize: number;
    /** Maximum characters persisted when StoreBody policy is `Snippet`. */
    BodySnippetChars: number;
}

/** Complete resolved limits configuration for `@mj-biz-apps/common-activity-sync`. */
export interface ActivitySyncLimitsConfig {
    readonly RunawayGuards: ActivitySyncRunawayGuardsConfig;
    readonly ResourceGuards: ActivitySyncResourceGuardsConfig;
    readonly Tuning: ActivitySyncTuningConfig;
}

/** Partial runtime override accepted by {@link ResolveActivitySyncLimits}. */
export interface ActivitySyncLimitsOverride {
    readonly ResourceGuards?: Partial<ActivitySyncResourceGuardsConfig>;
    readonly Tuning?: Partial<ActivitySyncTuningConfig>;
}

/** Canonical default limits for `@mj-biz-apps/common-activity-sync`. */
export const DEFAULT_ACTIVITY_SYNC_LIMITS: Readonly<ActivitySyncLimitsConfig> = {
    RunawayGuards: {
        ZeroHitsConfirmed: true,
    },
    ResourceGuards: {
        // ResourceGuard: Hard cap on runnable connections queried per fleet sync pass.
        MaxRunnableConnections: 500,
        // ResourceGuard: Maximum HTTP requests per late-tag consent sweep.
        MaxSweepRequests: 48,
        // ResourceGuard: Maximum consented items re-checked per run to bound API cost.
        MaxWithdrawChecks: 500,
        // ResourceGuard: Maximum RFC 5322 References Message-IDs traversed per tagged thread.
        MaxAncestorReferences: 20,
        // ResourceGuard: Maximum paged calendar requests per sync pass.
        MaxCalendarPages: 10,
        // ResourceGuard: Maximum windowed mail requests per pass when bisecting dense ranges.
        MaxMailRequests: 16,
    },
    Tuning: {
        // Tuning: Clock-skew overlap window (10 min = 600_000 ms) for incremental consent sweeps.
        SweepOverlapMs: 600_000,
        // Tuning: Message-ID batch size per re-read lookup request.
        RereadBatchSize: 10,
        // Tuning: Default lookback window in days when checking for withdrawn consent tags.
        WithdrawWindowDays: 30,
        // Tuning: Default calendar lookback horizon in days on initial sync.
        FirstRunLookbackDays: 30,
        // Tuning: Default calendar forward horizon in days for scheduled meetings.
        ForwardHorizonDays: 30,
        // Tuning: Maximum Message-IDs combined in a single OData filter batch.
        MessageIdBatchSize: 10,
        // Tuning: Maximum characters persisted when StoreBody policy is Snippet.
        BodySnippetChars: 500,
    },
};

/** Inclusive safety bounds enforced on every override for `@mj-biz-apps/common-activity-sync`. */
export const ACTIVITY_SYNC_LIMITS_BOUNDS: Readonly<{
    ResourceGuards: Readonly<Record<keyof ActivitySyncResourceGuardsConfig, ActivitySyncLimitBounds>>;
    Tuning: Readonly<Record<keyof ActivitySyncTuningConfig, ActivitySyncLimitBounds>>;
}> = {
    ResourceGuards: {
        MaxRunnableConnections: { Min: 1, Max: 5_000, Integer: true },
        MaxSweepRequests: { Min: 1, Max: 500, Integer: true },
        MaxWithdrawChecks: { Min: 1, Max: 10_000, Integer: true },
        MaxAncestorReferences: { Min: 1, Max: 200, Integer: true },
        MaxCalendarPages: { Min: 1, Max: 200, Integer: true },
        MaxMailRequests: { Min: 1, Max: 200, Integer: true },
    },
    Tuning: {
        SweepOverlapMs: { Min: 1_000, Max: 3_600_000, Integer: true },
        RereadBatchSize: { Min: 1, Max: 100, Integer: true },
        WithdrawWindowDays: { Min: 1, Max: 365, Integer: true },
        FirstRunLookbackDays: { Min: 1, Max: 365, Integer: true },
        ForwardHorizonDays: { Min: 1, Max: 365, Integer: true },
        MessageIdBatchSize: { Min: 1, Max: 50, Integer: true },
        BodySnippetChars: { Min: 50, Max: 10_000, Integer: true },
    },
};

let registeredActivitySyncLimitsOverride: ActivitySyncLimitsOverride | null = null;

function sanitizeBoundedNumber(
    candidate: number | undefined,
    fallback: number,
    bounds: ActivitySyncLimitBounds,
): number {
    if (typeof candidate !== 'number' || !Number.isFinite(candidate) || candidate <= 0) {
        return fallback;
    }
    const normalized = bounds.Integer ? Math.trunc(candidate) : candidate;
    if (normalized < bounds.Min) {
        return bounds.Min;
    }
    if (normalized > bounds.Max) {
        return bounds.Max;
    }
    return normalized;
}

/**
 * Registers runtime overrides for `@mj-biz-apps/common-activity-sync`.
 * Pass `null` to clear any previously registered override.
 */
export function RegisterActivitySyncLimits(override: ActivitySyncLimitsOverride | null): void {
    registeredActivitySyncLimitsOverride = override
        ? {
              ResourceGuards: override.ResourceGuards ? { ...override.ResourceGuards } : undefined,
              Tuning: override.Tuning ? { ...override.Tuning } : undefined,
          }
        : null;
}

/** Clears registered runtime overrides for `@mj-biz-apps/common-activity-sync`. */
export function ResetActivitySyncLimits(): void {
    registeredActivitySyncLimitsOverride = null;
}

/** Returns the currently registered runtime override, or `null` when unset. */
export function GetRegisteredActivitySyncLimits(): ActivitySyncLimitsOverride | null {
    return registeredActivitySyncLimitsOverride;
}

/**
 * Resolves `@mj-biz-apps/common-activity-sync` limits by merging code fallback defaults,
 * registered runtime overrides, and an optional call-site override.
 */
export function ResolveActivitySyncLimits(
    override?: ActivitySyncLimitsOverride | null,
): ActivitySyncLimitsConfig {
    const base = DEFAULT_ACTIVITY_SYNC_LIMITS;
    const reg = registeredActivitySyncLimitsOverride;
    const bounds = ACTIVITY_SYNC_LIMITS_BOUNDS;

    const pickResourceGuard = <K extends keyof ActivitySyncResourceGuardsConfig>(key: K): number => {
        const candidate = override?.ResourceGuards?.[key] ?? reg?.ResourceGuards?.[key];
        return sanitizeBoundedNumber(candidate, base.ResourceGuards[key], bounds.ResourceGuards[key]);
    };

    const pickTuning = <K extends keyof ActivitySyncTuningConfig>(key: K): number => {
        const candidate = override?.Tuning?.[key] ?? reg?.Tuning?.[key];
        return sanitizeBoundedNumber(candidate, base.Tuning[key], bounds.Tuning[key]);
    };

    return {
        RunawayGuards: { ZeroHitsConfirmed: true },
        ResourceGuards: {
            MaxRunnableConnections: pickResourceGuard('MaxRunnableConnections'),
            MaxSweepRequests: pickResourceGuard('MaxSweepRequests'),
            MaxWithdrawChecks: pickResourceGuard('MaxWithdrawChecks'),
            MaxAncestorReferences: pickResourceGuard('MaxAncestorReferences'),
            MaxCalendarPages: pickResourceGuard('MaxCalendarPages'),
            MaxMailRequests: pickResourceGuard('MaxMailRequests'),
        },
        Tuning: {
            SweepOverlapMs: pickTuning('SweepOverlapMs'),
            RereadBatchSize: pickTuning('RereadBatchSize'),
            WithdrawWindowDays: pickTuning('WithdrawWindowDays'),
            FirstRunLookbackDays: pickTuning('FirstRunLookbackDays'),
            ForwardHorizonDays: pickTuning('ForwardHorizonDays'),
            MessageIdBatchSize: pickTuning('MessageIdBatchSize'),
            BodySnippetChars: pickTuning('BodySnippetChars'),
        },
    };
}
