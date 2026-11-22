/**
 * Strongly-typed limits configuration resolver for `@mj-biz-apps/common-server`.
 *
 * Centralizes server action operational tuning defaults with finite/integer bounds validation
 * and runtime override support (zero `any`, zero `unknown`).
 */

/** Hard inclusive lower and upper bounds enforced for a numeric limit key. */
export interface ServerLimitBounds {
    readonly Min: number;
    readonly Max: number;
    readonly Integer: boolean;
}

/**
 * RunawayGuard schema anchor for `@mj-biz-apps/common-server`.
 * `bizapps-common` contains 0 RunawayGuard sites repo-wide (no agent/workflow loop executors).
 */
export interface ServerRunawayGuardsConfig {
    readonly ZeroHitsConfirmed: true;
}

/** Operational tuning defaults for `@mj-biz-apps/common-server` actions. */
export interface ServerTuningConfig {
    /** Default item fetch limit when `Common.SyncActivities` `Limit` parameter is omitted. */
    SyncActivitiesDefaultLimit: number;
}

/** Complete resolved limits configuration for `@mj-biz-apps/common-server`. */
export interface ServerLimitsConfig {
    readonly RunawayGuards: ServerRunawayGuardsConfig;
    readonly Tuning: ServerTuningConfig;
}

/** Partial runtime override accepted by {@link ResolveServerLimits}. */
export interface ServerLimitsOverride {
    readonly Tuning?: Partial<ServerTuningConfig>;
}

/** Canonical default limits for `@mj-biz-apps/common-server`. */
export const DEFAULT_SERVER_LIMITS: Readonly<ServerLimitsConfig> = {
    RunawayGuards: {
        ZeroHitsConfirmed: true,
    },
    Tuning: {
        // Tuning: Default item fetch limit when Common.SyncActivities Limit parameter is omitted.
        SyncActivitiesDefaultLimit: 100,
    },
};

/** Inclusive safety bounds enforced on every override for `@mj-biz-apps/common-server`. */
export const SERVER_LIMITS_BOUNDS: Readonly<{
    Tuning: Readonly<Record<keyof ServerTuningConfig, ServerLimitBounds>>;
}> = {
    Tuning: {
        SyncActivitiesDefaultLimit: { Min: 1, Max: 5_000, Integer: true },
    },
};

let registeredServerLimitsOverride: ServerLimitsOverride | null = null;

function sanitizeBoundedNumber(
    candidate: number | undefined,
    fallback: number,
    bounds: ServerLimitBounds,
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
 * Registers runtime overrides for `@mj-biz-apps/common-server`.
 * Pass `null` to clear any previously registered override.
 */
export function RegisterServerLimits(override: ServerLimitsOverride | null): void {
    registeredServerLimitsOverride = override
        ? {
              Tuning: override.Tuning ? { ...override.Tuning } : undefined,
          }
        : null;
}

/** Clears registered runtime overrides for `@mj-biz-apps/common-server`. */
export function ResetServerLimits(): void {
    registeredServerLimitsOverride = null;
}

/** Returns the currently registered runtime override, or `null` when unset. */
export function GetRegisteredServerLimits(): ServerLimitsOverride | null {
    return registeredServerLimitsOverride;
}

/**
 * Resolves `@mj-biz-apps/common-server` limits by merging code fallback defaults, registered
 * runtime overrides, and an optional call-site override.
 */
export function ResolveServerLimits(override?: ServerLimitsOverride | null): ServerLimitsConfig {
    const base = DEFAULT_SERVER_LIMITS;
    const reg = registeredServerLimitsOverride;
    const rawLimit = override?.Tuning?.SyncActivitiesDefaultLimit ?? reg?.Tuning?.SyncActivitiesDefaultLimit;

    return {
        RunawayGuards: { ZeroHitsConfirmed: true },
        Tuning: {
            SyncActivitiesDefaultLimit: sanitizeBoundedNumber(
                rawLimit,
                base.Tuning.SyncActivitiesDefaultLimit,
                SERVER_LIMITS_BOUNDS.Tuning.SyncActivitiesDefaultLimit,
            ),
        },
    };
}
