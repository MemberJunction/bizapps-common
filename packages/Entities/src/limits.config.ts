/**
 * Strongly-typed limits configuration resolver for `@mj-biz-apps/common-entities`.
 *
 * Pure and browser-safe (no `process.env` or Node-only imports): exposes safe code fallback
 * defaults, finite/integer bounds validation, upper policy-ceiling clamping, and runtime
 * override registration without `any` or `unknown`.
 */

/** Hard inclusive lower and upper bounds enforced for a numeric limit key. */
export interface CommonEntitiesLimitBounds {
    readonly Min: number;
    readonly Max: number;
    readonly Integer: boolean;
}

/**
 * RunawayGuard schema anchor for `@mj-biz-apps/common-entities`.
 * `bizapps-common` contains 0 RunawayGuard sites repo-wide (no agent/workflow loop executors).
 */
export interface CommonEntitiesRunawayGuardsConfig {
    readonly ZeroHitsConfirmed: true;
}

/** ResourceGuard ceilings for `@mj-biz-apps/common-entities`. */
export interface CommonEntitiesResourceGuardsConfig {
    /** Maximum supervisor ancestor hops traversed during cycle validation in `PersonEntity`. */
    MaxReportingChainDepth: number;
}

/** Partial override accepted for {@link CommonEntitiesResourceGuardsConfig}. */
export type CommonEntitiesResourceGuardsOverride = Partial<CommonEntitiesResourceGuardsConfig>;

/** Complete resolved limits configuration for `@mj-biz-apps/common-entities`. */
export interface CommonEntitiesLimitsConfig {
    readonly RunawayGuards: CommonEntitiesRunawayGuardsConfig;
    readonly ResourceGuards: CommonEntitiesResourceGuardsConfig;
}

/** Partial runtime override accepted by {@link ResolveCommonEntitiesLimits}. */
export interface CommonEntitiesLimitsOverride {
    readonly ResourceGuards?: CommonEntitiesResourceGuardsOverride;
}

/** Canonical default limits for `@mj-biz-apps/common-entities`. */
export const DEFAULT_COMMON_ENTITIES_LIMITS: Readonly<CommonEntitiesLimitsConfig> = {
    RunawayGuards: {
        ZeroHitsConfirmed: true,
    },
    ResourceGuards: {
        // ResourceGuard: Caps supervisor reporting-chain recursion/traversal depth in PersonEntity.
        MaxReportingChainDepth: 100,
    },
};

/** Inclusive safety bounds enforced on every override for `@mj-biz-apps/common-entities`. */
export const COMMON_ENTITIES_LIMITS_BOUNDS: Readonly<{
    ResourceGuards: Readonly<Record<keyof CommonEntitiesResourceGuardsConfig, CommonEntitiesLimitBounds>>;
}> = {
    ResourceGuards: {
        MaxReportingChainDepth: { Min: 1, Max: 1_000, Integer: true },
    },
};

let registeredEntitiesLimitsOverride: CommonEntitiesLimitsOverride | null = null;

function sanitizeBoundedNumber(
    candidate: number | undefined,
    fallback: number,
    bounds: CommonEntitiesLimitBounds,
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
 * Registers process-wide runtime overrides for `@mj-biz-apps/common-entities` limits.
 * Pass `null` to clear any previously registered override.
 */
export function RegisterCommonEntitiesLimits(override: CommonEntitiesLimitsOverride | null): void {
    registeredEntitiesLimitsOverride = override
        ? {
              ResourceGuards: override.ResourceGuards ? { ...override.ResourceGuards } : undefined,
          }
        : null;
}

/** Clears registered runtime overrides for `@mj-biz-apps/common-entities` (for test isolation). */
export function ResetCommonEntitiesLimits(): void {
    registeredEntitiesLimitsOverride = null;
}

/** Returns the currently registered runtime override, or `null` when unset. */
export function GetRegisteredCommonEntitiesLimits(): CommonEntitiesLimitsOverride | null {
    return registeredEntitiesLimitsOverride;
}

/**
 * Resolves `@mj-biz-apps/common-entities` limits by merging code fallback defaults, registered
 * runtime overrides, and an optional call-site override, enforcing finite bounds and upper ceilings.
 */
export function ResolveCommonEntitiesLimits(
    override?: CommonEntitiesLimitsOverride | null,
): CommonEntitiesLimitsConfig {
    const base = DEFAULT_COMMON_ENTITIES_LIMITS;
    const reg = registeredEntitiesLimitsOverride;
    const rawDepth = override?.ResourceGuards?.MaxReportingChainDepth ?? reg?.ResourceGuards?.MaxReportingChainDepth;

    return {
        RunawayGuards: { ZeroHitsConfirmed: true },
        ResourceGuards: {
            MaxReportingChainDepth: sanitizeBoundedNumber(
                rawDepth,
                base.ResourceGuards.MaxReportingChainDepth,
                COMMON_ENTITIES_LIMITS_BOUNDS.ResourceGuards.MaxReportingChainDepth,
            ),
        },
    };
}
