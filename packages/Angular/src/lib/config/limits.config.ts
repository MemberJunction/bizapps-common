import { InjectionToken } from '@angular/core';

/**
 * Strongly-typed, browser-safe limits configuration resolver for `@mj-biz-apps/common-ng`.
 *
 * Centralizes all Angular `ResourceGuard`, `Tuning`, and configurable `UX` bounds with
 * finite/integer bounds validation, upper policy-ceiling clamping, Angular DI overrides
 * ({@link COMMON_ANGULAR_LIMITS_CONFIG}), and process-wide runtime registration
 * ({@link RegisterCommonAngularLimits}).
 *
 * Pure and browser-safe: zero `process.env` access, zero `any`, zero `unknown`.
 */

/** Hard inclusive lower and upper bounds enforced for a numeric limit key. */
export interface CommonAngularLimitBounds {
    readonly Min: number;
    readonly Max: number;
    readonly Integer: boolean;
}

/**
 * RunawayGuard schema anchor for `@mj-biz-apps/common-ng`.
 * `bizapps-common` contains 0 RunawayGuard sites repo-wide (no agent/workflow loop executors).
 */
export interface CommonAngularRunawayGuardsConfig {
    readonly ZeroHitsConfirmed: true;
    readonly ActiveGuardCount: 0;
}

/** Bounded query and timeout guards protecting client and database resources. */
export interface CommonAngularResourceGuardsConfig {
    /** Timeout in milliseconds before a party lookup search is reported as timed out. */
    PartySearchTimeoutMs: number;
    /** Maximum company rows loaded into the selling-company picker dropdown. */
    SellingCompanyListLimit: number;
    /** Maximum people rows fetched for the directory snapshot fallback. */
    DirectorySnapshotPeopleMaxRows: number;
    /** Maximum organization rows fetched for the directory snapshot fallback. */
    DirectorySnapshotOrganizationsMaxRows: number;
    /** Maximum relationship rows fetched for the directory snapshot fallback. */
    DirectorySnapshotRelationshipsMaxRows: number;
}

/** Operational tuning defaults for graph neighborhood queries, search caps, and dashboards. */
export interface CommonAngularTuningConfig {
    /** Maximum relationship edges loaded on initial relationship graph render. */
    RelationshipGraphInitialMaxRows: number;
    /** Maximum relationship edges loaded per incremental graph hop expansion. */
    RelationshipGraphHopMaxRows: number;
    /** Maximum people rows returned by directory search. */
    DirectorySearchPeopleMaxRows: number;
    /** Maximum organization rows returned by directory search. */
    DirectorySearchOrganizationsMaxRows: number;
    /** Maximum recent activity rows loaded on the activities dashboard. */
    ActivitiesDashboardMaxRows: number;
}

/** Configurable UX thresholds for search input and directory summary cards. */
export interface CommonAngularUxConfig {
    /** Typeahead search input debounce interval in milliseconds. */
    PartySearchDebounceMs: number;
    /** Minimum non-wildcard character count before querying party lookup. */
    PartyLookupMinTermLength: number;
    /** Default recent records slice size for the WorthALook directory card. */
    DirectoryLatestTakeCount: number;
}

/** Complete resolved limits configuration for `@mj-biz-apps/common-ng`. */
export interface CommonAngularLimitsConfig {
    readonly RunawayGuards: CommonAngularRunawayGuardsConfig;
    readonly ResourceGuards: CommonAngularResourceGuardsConfig;
    readonly Tuning: CommonAngularTuningConfig;
    readonly Ux: CommonAngularUxConfig;
}

/** Partial runtime or Angular DI override accepted by {@link ResolveCommonAngularLimits}. */
export interface CommonAngularLimitsOverride {
    readonly ResourceGuards?: Partial<CommonAngularResourceGuardsConfig>;
    readonly Tuning?: Partial<CommonAngularTuningConfig>;
    readonly Ux?: Partial<CommonAngularUxConfig>;
}

/** Dot-separated limit key paths tracked by {@link ResolveCommonAngularLimitsWithProvenance}. */
export type CommonAngularLimitKeyPath =
    | `ResourceGuards.${keyof CommonAngularResourceGuardsConfig}`
    | `Tuning.${keyof CommonAngularTuningConfig}`
    | `Ux.${keyof CommonAngularUxConfig}`;

/** Precedence tier supplying the winning value for a limit key. */
export type CommonAngularLimitsSourceTier = 'CodeFallback' | 'RuntimeRegistry' | 'CallOverride';

/** Per-key resolution metadata returned by {@link ResolveCommonAngularLimitsWithProvenance}. */
export interface CommonAngularLimitProvenance {
    readonly Key: CommonAngularLimitKeyPath;
    readonly Value: number;
    readonly SourceTier: CommonAngularLimitsSourceTier;
    readonly WasClamped: boolean;
    readonly UsedFallbackDueToInvalidOverride: boolean;
}

/** Full resolution result including resolved config and per-key provenance. */
export interface CommonAngularLimitsResolutionResult {
    readonly Limits: CommonAngularLimitsConfig;
    readonly Provenance: Readonly<Record<CommonAngularLimitKeyPath, CommonAngularLimitProvenance>>;
}

/**
 * Angular DI token for overriding `@mj-biz-apps/common-ng` limits at the application or
 * component injector level.
 */
export const COMMON_ANGULAR_LIMITS_CONFIG = new InjectionToken<CommonAngularLimitsOverride>(
    'COMMON_ANGULAR_LIMITS_CONFIG',
);

/** Canonical browser-safe fallback defaults for `@mj-biz-apps/common-ng`. */
export const DEFAULT_COMMON_ANGULAR_LIMITS: Readonly<CommonAngularLimitsConfig> = {
    RunawayGuards: {
        ZeroHitsConfirmed: true,
        ActiveGuardCount: 0,
    },
    ResourceGuards: {
        // ResourceGuard: Client search query timeout guard in milliseconds.
        PartySearchTimeoutMs: 20_000,
        // ResourceGuard: Maximum company rows loaded into selling company dropdown.
        SellingCompanyListLimit: 1000,
        // ResourceGuard: Maximum people rows fetched for directory snapshot fallback.
        DirectorySnapshotPeopleMaxRows: 1000,
        // ResourceGuard: Maximum organization rows fetched for directory snapshot fallback.
        DirectorySnapshotOrganizationsMaxRows: 1000,
        // ResourceGuard: Maximum relationship rows fetched for directory snapshot fallback.
        DirectorySnapshotRelationshipsMaxRows: 1000,
    },
    Tuning: {
        // Tuning: Maximum relationship edges loaded on initial graph render.
        RelationshipGraphInitialMaxRows: 60,
        // Tuning: Maximum relationship edges loaded per incremental graph hop expansion.
        RelationshipGraphHopMaxRows: 30,
        // Tuning: Maximum people rows returned by directory search.
        DirectorySearchPeopleMaxRows: 200,
        // Tuning: Maximum organization rows returned by directory search.
        DirectorySearchOrganizationsMaxRows: 200,
        // Tuning: Maximum recent activity rows loaded on activities dashboard.
        ActivitiesDashboardMaxRows: 250,
    },
    Ux: {
        // UX: Typeahead search input debounce interval in milliseconds.
        PartySearchDebounceMs: 250,
        // UX: Minimum non-wildcard character count before querying party lookup.
        PartyLookupMinTermLength: 2,
        // UX: Default recent records slice size for WorthALook directory card.
        DirectoryLatestTakeCount: 7,
    },
};

/** Inclusive safety bounds enforced on every override for `@mj-biz-apps/common-ng`. */
export const COMMON_ANGULAR_LIMITS_BOUNDS: Readonly<{
    ResourceGuards: Readonly<Record<keyof CommonAngularResourceGuardsConfig, CommonAngularLimitBounds>>;
    Tuning: Readonly<Record<keyof CommonAngularTuningConfig, CommonAngularLimitBounds>>;
    Ux: Readonly<Record<keyof CommonAngularUxConfig, CommonAngularLimitBounds>>;
}> = {
    ResourceGuards: {
        PartySearchTimeoutMs: { Min: 500, Max: 120_000, Integer: true },
        SellingCompanyListLimit: { Min: 10, Max: 10_000, Integer: true },
        DirectorySnapshotPeopleMaxRows: { Min: 10, Max: 10_000, Integer: true },
        DirectorySnapshotOrganizationsMaxRows: { Min: 10, Max: 10_000, Integer: true },
        DirectorySnapshotRelationshipsMaxRows: { Min: 10, Max: 10_000, Integer: true },
    },
    Tuning: {
        RelationshipGraphInitialMaxRows: { Min: 1, Max: 1_000, Integer: true },
        RelationshipGraphHopMaxRows: { Min: 1, Max: 500, Integer: true },
        DirectorySearchPeopleMaxRows: { Min: 1, Max: 2_000, Integer: true },
        DirectorySearchOrganizationsMaxRows: { Min: 1, Max: 2_000, Integer: true },
        ActivitiesDashboardMaxRows: { Min: 1, Max: 5_000, Integer: true },
    },
    Ux: {
        PartySearchDebounceMs: { Min: 0, Max: 5_000, Integer: true },
        PartyLookupMinTermLength: { Min: 1, Max: 20, Integer: true },
        DirectoryLatestTakeCount: { Min: 1, Max: 100, Integer: true },
    },
};

let registeredAngularLimitsOverride: CommonAngularLimitsOverride | null = null;

interface ResolvedNumericField {
    readonly Value: number;
    readonly SourceTier: CommonAngularLimitsSourceTier;
    readonly WasClamped: boolean;
    readonly UsedFallbackDueToInvalidOverride: boolean;
}

function resolveNumericField(
    callCandidate: number | undefined,
    registryCandidate: number | undefined,
    fallback: number,
    bounds: CommonAngularLimitBounds,
): ResolvedNumericField {
    const hasCall = callCandidate !== undefined;
    const hasReg = registryCandidate !== undefined;
    const candidate = hasCall ? callCandidate : registryCandidate;
    const sourceTier: CommonAngularLimitsSourceTier = hasCall
        ? 'CallOverride'
        : hasReg
          ? 'RuntimeRegistry'
          : 'CodeFallback';

    if (candidate === undefined) {
        return {
            Value: fallback,
            SourceTier: 'CodeFallback',
            WasClamped: false,
            UsedFallbackDueToInvalidOverride: false,
        };
    }

    const minimumAccepted = bounds.Min === 0 ? 0 : 1;
    if (typeof candidate !== 'number' || !Number.isFinite(candidate) || candidate < minimumAccepted) {
        return {
            Value: fallback,
            SourceTier: 'CodeFallback',
            WasClamped: false,
            UsedFallbackDueToInvalidOverride: true,
        };
    }

    const normalized = bounds.Integer ? Math.trunc(candidate) : candidate;
    if (normalized < bounds.Min) {
        return {
            Value: bounds.Min,
            SourceTier: sourceTier,
            WasClamped: true,
            UsedFallbackDueToInvalidOverride: false,
        };
    }
    if (normalized > bounds.Max) {
        return {
            Value: bounds.Max,
            SourceTier: sourceTier,
            WasClamped: true,
            UsedFallbackDueToInvalidOverride: false,
        };
    }
    return {
        Value: normalized,
        SourceTier: sourceTier,
        WasClamped: false,
        UsedFallbackDueToInvalidOverride: false,
    };
}

/**
 * Registers runtime overrides for `@mj-biz-apps/common-ng`.
 * Pass `null` to clear any previously registered override.
 */
export function RegisterCommonAngularLimits(override: CommonAngularLimitsOverride | null): void {
    registeredAngularLimitsOverride = override
        ? {
              ResourceGuards: override.ResourceGuards ? { ...override.ResourceGuards } : undefined,
              Tuning: override.Tuning ? { ...override.Tuning } : undefined,
              Ux: override.Ux ? { ...override.Ux } : undefined,
          }
        : null;
}

/** Clears registered runtime overrides for `@mj-biz-apps/common-ng` (for test isolation). */
export function ResetCommonAngularLimits(): void {
    registeredAngularLimitsOverride = null;
}

/** Returns the currently registered runtime override, or `null` when unset. */
export function GetRegisteredCommonAngularLimits(): CommonAngularLimitsOverride | null {
    return registeredAngularLimitsOverride;
}

/**
 * Resolves `@mj-biz-apps/common-ng` limits across `CodeFallback` -> `RuntimeRegistry` ->
 * `CallOverride` with full per-key provenance and safety clamping.
 */
export function ResolveCommonAngularLimitsWithProvenance(
    override?: CommonAngularLimitsOverride | null,
): CommonAngularLimitsResolutionResult {
    const base = DEFAULT_COMMON_ANGULAR_LIMITS;
    const reg = registeredAngularLimitsOverride;
    const bounds = COMMON_ANGULAR_LIMITS_BOUNDS;
    const provenanceEntries: Array<[CommonAngularLimitKeyPath, CommonAngularLimitProvenance]> = [];

    const resolveResourceGuard = <K extends keyof CommonAngularResourceGuardsConfig>(key: K): number => {
        const res = resolveNumericField(
            override?.ResourceGuards?.[key],
            reg?.ResourceGuards?.[key],
            base.ResourceGuards[key],
            bounds.ResourceGuards[key],
        );
        const path: CommonAngularLimitKeyPath = `ResourceGuards.${key}`;
        provenanceEntries.push([
            path,
            {
                Key: path,
                Value: res.Value,
                SourceTier: res.SourceTier,
                WasClamped: res.WasClamped,
                UsedFallbackDueToInvalidOverride: res.UsedFallbackDueToInvalidOverride,
            },
        ]);
        return res.Value;
    };

    const resolveTuning = <K extends keyof CommonAngularTuningConfig>(key: K): number => {
        const res = resolveNumericField(
            override?.Tuning?.[key],
            reg?.Tuning?.[key],
            base.Tuning[key],
            bounds.Tuning[key],
        );
        const path: CommonAngularLimitKeyPath = `Tuning.${key}`;
        provenanceEntries.push([
            path,
            {
                Key: path,
                Value: res.Value,
                SourceTier: res.SourceTier,
                WasClamped: res.WasClamped,
                UsedFallbackDueToInvalidOverride: res.UsedFallbackDueToInvalidOverride,
            },
        ]);
        return res.Value;
    };

    const resolveUx = <K extends keyof CommonAngularUxConfig>(key: K): number => {
        const res = resolveNumericField(
            override?.Ux?.[key],
            reg?.Ux?.[key],
            base.Ux[key],
            bounds.Ux[key],
        );
        const path: CommonAngularLimitKeyPath = `Ux.${key}`;
        provenanceEntries.push([
            path,
            {
                Key: path,
                Value: res.Value,
                SourceTier: res.SourceTier,
                WasClamped: res.WasClamped,
                UsedFallbackDueToInvalidOverride: res.UsedFallbackDueToInvalidOverride,
            },
        ]);
        return res.Value;
    };

    const limits: CommonAngularLimitsConfig = {
        RunawayGuards: {
            ZeroHitsConfirmed: true,
            ActiveGuardCount: 0,
        },
        ResourceGuards: {
            PartySearchTimeoutMs: resolveResourceGuard('PartySearchTimeoutMs'),
            SellingCompanyListLimit: resolveResourceGuard('SellingCompanyListLimit'),
            DirectorySnapshotPeopleMaxRows: resolveResourceGuard('DirectorySnapshotPeopleMaxRows'),
            DirectorySnapshotOrganizationsMaxRows: resolveResourceGuard('DirectorySnapshotOrganizationsMaxRows'),
            DirectorySnapshotRelationshipsMaxRows: resolveResourceGuard('DirectorySnapshotRelationshipsMaxRows'),
        },
        Tuning: {
            RelationshipGraphInitialMaxRows: resolveTuning('RelationshipGraphInitialMaxRows'),
            RelationshipGraphHopMaxRows: resolveTuning('RelationshipGraphHopMaxRows'),
            DirectorySearchPeopleMaxRows: resolveTuning('DirectorySearchPeopleMaxRows'),
            DirectorySearchOrganizationsMaxRows: resolveTuning('DirectorySearchOrganizationsMaxRows'),
            ActivitiesDashboardMaxRows: resolveTuning('ActivitiesDashboardMaxRows'),
        },
        Ux: {
            PartySearchDebounceMs: resolveUx('PartySearchDebounceMs'),
            PartyLookupMinTermLength: resolveUx('PartyLookupMinTermLength'),
            DirectoryLatestTakeCount: resolveUx('DirectoryLatestTakeCount'),
        },
    };

    const provenance = Object.fromEntries(provenanceEntries) as Record<
        CommonAngularLimitKeyPath,
        CommonAngularLimitProvenance
    >;

    return { Limits: limits, Provenance: provenance };
}

/**
 * Resolves `@mj-biz-apps/common-ng` limits by merging defaults, registered runtime overrides,
 * and an optional call-site or Angular DI override.
 */
export function ResolveCommonAngularLimits(
    override?: CommonAngularLimitsOverride | null,
): CommonAngularLimitsConfig {
    return ResolveCommonAngularLimitsWithProvenance(override).Limits;
}
