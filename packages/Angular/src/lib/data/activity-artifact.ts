/**
 * @fileoverview Optional linked MJ Doc (`MJ: Artifacts`) helpers for Common Activities.
 *
 * Implements the Category B Hybrid Spine rules for `MJ_BizApps_Common: Activities`:
 * - Fast path (<2s quick capture): Activities persist directly with `ArtifactID = null`,
 *   storing quick notes in `Description` / `Details` and NEVER auto-creating an `MJ: Artifacts` row.
 * - Batched hydration: visible timeline rows with non-null `ArtifactID` are hydrated in a single
 *   batched `RunView` (`ResultType: 'simple'`, minimal display `Fields`, deduplicated UUIDs),
 *   short-circuiting completely with zero `RunView` calls when zero items have a non-null `ArtifactID`.
 * - Graceful degradation: missing, deleted, or restricted Artifacts return an `'unavailable'`
 *   badge state with zero console errors.
 * - Opt-in link, expand (atomic `TransactionGroup` or compensating rollback), unlink (preserving
 *   `Description` and `Details`), and `NavigationService` navigation.
 */
import {
    CompositeKey,
    IMetadataProvider,
    Metadata,
    RunView,
    RunViewParams,
    TransactionGroupBase,
    TransactionVariable,
    UserInfo,
} from '@memberjunction/core';
import {
    ArtifactMetadataEngine,
    MJArtifactEntity,
    MJArtifactVersionEntity,
} from '@memberjunction/core-entities';
import { EscapeSQLString, IsValidUUID, NormalizeUUID } from '@memberjunction/global';
import type { FormNavigationEvent } from '@memberjunction/ng-base-forms';
import type { NavigationService } from '@memberjunction/ng-shared';
import type { mjBizAppsCommonActivityEntity } from '@mj-biz-apps/common-entities';
import { COMMON_ENTITIES } from './entity-names';
import { OpenCommonRecord } from '../open-record';

/** Canonical MJ core entity names used for optional Activity -> MJ Doc links. */
export const MJ_ARTIFACT_ENTITIES = {
    Artifact: 'MJ: Artifacts',
    ArtifactVersion: 'MJ: Artifact Versions',
    ArtifactType: 'MJ: Artifact Types',
} as const;

/** Minimal display columns hydrated for timeline/card MJ Doc badges. */
export const ARTIFACT_BADGE_FIELDS: ReadonlyArray<'ID' | 'Name' | 'Type'> = ['ID', 'Name', 'Type'];

/** Columns queried when searching existing MJ Docs in the opt-in link picker. */
export const ARTIFACT_PICKER_FIELDS: ReadonlyArray<'ID' | 'Name' | 'Type' | 'Description' | '__mj_UpdatedAt'> = [
    'ID',
    'Name',
    'Type',
    'Description',
    '__mj_UpdatedAt',
];

/** Default `MJ: Artifact Types.Name` used when expanding an Activity into an MJ Doc. */
export const DEFAULT_ACTIVITY_ARTIFACT_TYPE_NAME = 'Markdown Document';

/** Default SQL `IN (...)` batch chunk size for Artifact badge hydration. */
const ARTIFACT_BATCH_CHUNK_SIZE = 100;

/** Minimal projection of an `MJ: Artifacts` record used for badges and link pickers. */
export interface ActivityArtifactSummary {
    ID: string;
    Name: string;
    Type?: string | null;
    Description?: string | null;
    __mj_UpdatedAt?: string | Date | null;
}

/** Resolved UI badge state for an Activity's optional `ArtifactID`. */
export type ActivityArtifactBadgeState =
    | { Status: 'none' }
    | { Status: 'resolved'; ArtifactID: string; Name: string; TypeLabel: string | null }
    | { Status: 'unavailable'; ArtifactID: string; FallbackLabel: string };

/** Input payload for fast-path Activity creation (<2s quick capture). */
export interface ActivityQuickCaptureInput {
    ActivityTypeID: string;
    Title: string;
    Description: string | null;
    Details?: string | null;
    Direction: mjBizAppsCommonActivityEntity['Direction'];
    Status?: mjBizAppsCommonActivityEntity['Status'];
    Outcome?: mjBizAppsCommonActivityEntity['Outcome'];
    Location?: string | null;
    StartedAt?: Date;
    /** Opt-in linked MJ Doc ID; strictly defaults to `null` for quick capture. */
    ArtifactID?: string | null;
}

/** Result of fast-path Activity quick capture. */
export interface ActivityQuickCaptureResult {
    Success: boolean;
    Activity?: mjBizAppsCommonActivityEntity;
    ErrorMessage?: string;
}

/** Result of opt-in link, expand, or unlink operations on an Activity. */
export interface ActivityArtifactActionResult {
    Success: boolean;
    ArtifactID: string | null;
    ArtifactName?: string | null;
    ErrorMessage?: string;
    RolledBack?: boolean;
}

/** Options controlling opt-in expansion of an Activity into a linked MJ Doc. */
export interface ExpandActivityToArtifactOptions {
    /** Optional title override for the new MJ Doc (defaults to `activity.Title`). */
    Title?: string;
    /** Optional Markdown body override (defaults to `activity.Description ?? ''`). */
    MarkdownContent?: string;
    /** Optional Artifact Type name (defaults to `'Markdown Document'`). */
    ArtifactTypeName?: string;
    /** Optional provider override (defaults to `Metadata.Provider`). */
    Provider?: IMetadataProvider;
    /** Optional user context override (defaults to `provider.CurrentUser`). */
    ContextUser?: UserInfo;
}

interface ArtifactTypeIdRow {
    ID: string;
    Name: string;
}

/**
 * Strips raw Markdown syntax (`### Heading`, `**bold**`, fenced code blocks, links, inline code)
 * into clean plain text so Activity feed cards and previews never leak raw Markdown tokens.
 */
export function StripActivityMarkdownExcerpt(raw: string | null | undefined, maxLength = 220): string {
    if (!raw) {
        return '';
    }
    const cleaned = raw
        .replace(/```[\s\S]*?```/g, ' ')
        .replace(/~~~[\s\S]*?~~~/g, ' ')
        .replace(/!\[([^\]]*)\]\([^)]*\)/g, '$1')
        .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
        .replace(/^#{1,6}\s+/gm, '')
        .replace(/^\s*[-*+]\s+/gm, '')
        .replace(/^\s*>\s+/gm, '')
        .replace(/(\*\*|__|\*|_|~~|`)/g, '')
        .replace(/\s+/g, ' ')
        .trim();

    if (cleaned.length <= maxLength) {
        return cleaned;
    }
    return `${cleaned.slice(0, Math.max(0, maxLength - 1)).trimEnd()}…`;
}

/** Deduplicates valid UUID strings case-insensitively while preserving normalized IDs. */
export function CollectDistinctValidArtifactIDs(artifactIDs: ReadonlyArray<string | null | undefined>): string[] {
    const seen = new Set<string>();
    const distinct: string[] = [];
    for (const raw of artifactIDs) {
        if (!raw) {
            continue;
        }
        const trimmed = raw.trim();
        if (!IsValidUUID(trimmed)) {
            continue;
        }
        const normalized = NormalizeUUID(trimmed);
        if (seen.has(normalized)) {
            continue;
        }
        seen.add(normalized);
        distinct.push(trimmed);
    }
    return distinct;
}

function chunkStringArray(items: ReadonlyArray<string>, size: number): string[][] {
    const chunks: string[][] = [];
    for (let i = 0; i < items.length; i += size) {
        chunks.push(items.slice(i, i + size));
    }
    return chunks;
}

function canReadEntity(provider: IMetadataProvider | null | undefined, entityName: string, user?: UserInfo): boolean {
    if (!provider || typeof provider.EntityByName !== 'function') {
        return true;
    }
    const entityInfo = provider.EntityByName(entityName);
    if (!entityInfo) {
        return true;
    }
    if (!user || typeof entityInfo.GetUserPermisions !== 'function') {
        return true;
    }
    return entityInfo.GetUserPermisions(user)?.CanRead !== false;
}

/**
 * Hydrates minimal display summaries (`ID`, `Name`, `Type`) for distinct non-null `ArtifactID`s
 * using a single batched `RunView` (`rv.RunViews([...])`, `ResultType: 'simple'`, `CacheLocal: false`).
 *
 * Short-circuits immediately with zero `RunView` calls when zero valid non-null `ArtifactID`s exist.
 * Degrades gracefully (returns an empty/partial map with zero console errors) if `RunView` fails
 * or returns no row for restricted/deleted Artifacts.
 */
export async function LoadActivityArtifactsByIDs(
    artifactIDs: ReadonlyArray<string | null | undefined>,
    provider?: IMetadataProvider,
    contextUser?: UserInfo,
): Promise<Map<string, ActivityArtifactSummary>> {
    const result = new Map<string, ActivityArtifactSummary>();
    const distinctIDs = CollectDistinctValidArtifactIDs(artifactIDs);
    if (distinctIDs.length === 0) {
        return result;
    }

    const activeProvider = provider ?? Metadata.Provider;
    const activeUser = contextUser ?? activeProvider?.CurrentUser;
    if (!canReadEntity(activeProvider, MJ_ARTIFACT_ENTITIES.Artifact, activeUser)) {
        return result;
    }

    const chunks = chunkStringArray(distinctIDs, ARTIFACT_BATCH_CHUNK_SIZE);
    const paramsList: RunViewParams[] = chunks.map((chunk) => ({
        EntityName: MJ_ARTIFACT_ENTITIES.Artifact,
        ExtraFilter: `ID IN (${chunk.map((id) => `'${EscapeSQLString(id)}'`).join(',')})`,
        Fields: [...ARTIFACT_BADGE_FIELDS],
        ResultType: 'simple',
        CacheLocal: false,
    }));

    try {
        const rv = RunView.FromMetadataProvider(activeProvider);
        const batchResults = await rv.RunViews<ActivityArtifactSummary>(paramsList, activeUser);
        for (const res of batchResults) {
            if (!res?.Success || !Array.isArray(res.Results)) {
                continue;
            }
            for (const row of res.Results) {
                if (row?.ID) {
                    result.set(NormalizeUUID(row.ID), row);
                }
            }
        }
    } catch {
        // Degrade gracefully without emitting console errors; callers render the fallback badge state.
    }

    return result;
}

/**
 * Resolves the UI badge state for a single Activity's `ArtifactID` against the hydrated Artifact map.
 * When `ArtifactID` is non-null and missing from `hydratedMap` (e.g., deleted or restricted),
 * returns an `'unavailable'` fallback state rather than throwing.
 */
export function ResolveActivityArtifactBadge(
    artifactID: string | null | undefined,
    hydratedMap: ReadonlyMap<string, ActivityArtifactSummary>,
    options?: { hydrationComplete?: boolean; virtualName?: string | null },
): ActivityArtifactBadgeState {
    const trimmed = artifactID?.trim();
    if (!trimmed) {
        return { Status: 'none' };
    }

    const hit = hydratedMap.get(NormalizeUUID(trimmed));
    if (hit) {
        return {
            Status: 'resolved',
            ArtifactID: trimmed,
            Name: hit.Name || 'Untitled MJ Doc',
            TypeLabel: hit.Type ?? null,
        };
    }

    if (options?.hydrationComplete === false && options.virtualName?.trim()) {
        return {
            Status: 'resolved',
            ArtifactID: trimmed,
            Name: options.virtualName.trim(),
            TypeLabel: null,
        };
    }

    return {
        Status: 'unavailable',
        ArtifactID: trimmed,
        FallbackLabel: 'Linked MJ Doc (Unavailable)',
    };
}

/**
 * Searches visible `MJ: Artifacts` records for opt-in linking to an Activity.
 * Uses `ResultType: 'simple'` and narrow display `Fields` with `CacheLocal: false`.
 */
export async function SearchLinkableArtifacts(
    searchTerm: string,
    provider?: IMetadataProvider,
    maxRows = 20,
    contextUser?: UserInfo,
): Promise<ActivityArtifactSummary[]> {
    const activeProvider = provider ?? Metadata.Provider;
    const activeUser = contextUser ?? activeProvider?.CurrentUser;
    if (!canReadEntity(activeProvider, MJ_ARTIFACT_ENTITIES.Artifact, activeUser)) {
        return [];
    }

    const trimmed = searchTerm.trim();
    const filter = trimmed
        ? `Visibility = 'Always' AND (Name LIKE '%${EscapeSQLString(trimmed)}%' OR Description LIKE '%${EscapeSQLString(trimmed)}%')`
        : `Visibility = 'Always'`;

    try {
        const rv = RunView.FromMetadataProvider(activeProvider);
        const res = await rv.RunView<ActivityArtifactSummary>(
            {
                EntityName: MJ_ARTIFACT_ENTITIES.Artifact,
                ExtraFilter: filter,
                Fields: [...ARTIFACT_PICKER_FIELDS],
                OrderBy: '__mj_UpdatedAt DESC',
                MaxRows: maxRows,
                ResultType: 'simple',
                CacheLocal: false,
            },
            activeUser,
        );
        return res.Success && Array.isArray(res.Results) ? res.Results : [];
    } catch {
        return [];
    }
}

/**
 * Persists a fast-path Activity (`Note`, `Call`, `Meeting`, `Email`) with `ArtifactID = null`
 * by default. Never creates an `MJ: Artifacts` record automatically.
 */
export async function SaveQuickActivity(
    input: ActivityQuickCaptureInput,
    provider?: IMetadataProvider,
    contextUser?: UserInfo,
): Promise<ActivityQuickCaptureResult> {
    const title = input.Title.trim();
    if (!title) {
        return { Success: false, ErrorMessage: 'Activity title is required.' };
    }
    if (!input.ActivityTypeID.trim()) {
        return { Success: false, ErrorMessage: 'Activity type is required.' };
    }

    const activeProvider = provider ?? Metadata.Provider;
    const activeUser = contextUser ?? activeProvider?.CurrentUser;

    try {
        const activity = await activeProvider.GetEntityObject<mjBizAppsCommonActivityEntity>(
            COMMON_ENTITIES.Activity,
            activeUser,
        );
        activity.NewRecord();
        activity.ActivityTypeID = input.ActivityTypeID.trim();
        activity.Title = title;
        activity.Description = input.Description ?? null;
        if (input.Details !== undefined) {
            activity.Details = input.Details;
        }
        activity.Direction = input.Direction;
        activity.Status = input.Status ?? 'Logged';
        activity.Outcome = input.Outcome ?? null;
        activity.Location = input.Location ?? null;
        activity.StartedAt = input.StartedAt ?? new Date();
        activity.Source = 'Manual';
        // Fast path: default ArtifactID to null unless the user explicitly opted into linking an existing MJ Doc.
        activity.ArtifactID = input.ArtifactID && IsValidUUID(input.ArtifactID) ? input.ArtifactID.trim() : null;

        const saved = await activity.Save();
        if (!saved) {
            return {
                Success: false,
                ErrorMessage: activity.LatestResult?.CompleteMessage ?? 'Failed to save activity.',
            };
        }
        return { Success: true, Activity: activity };
    } catch (err) {
        return {
            Success: false,
            ErrorMessage: err instanceof Error ? err.message : String(err),
        };
    }
}

/**
 * Links an existing `MJ: Artifacts` record to an Activity while preserving `Description` and `Details`.
 * Reverts `activity.ArtifactID` if saving fails.
 */
export async function LinkExistingArtifactToActivity(
    activity: mjBizAppsCommonActivityEntity,
    artifactID: string,
    options?: { saveNow?: boolean; artifactName?: string | null },
): Promise<ActivityArtifactActionResult> {
    const trimmedID = artifactID.trim();
    if (!IsValidUUID(trimmedID)) {
        return {
            Success: false,
            ArtifactID: activity.ArtifactID,
            ErrorMessage: 'A valid MJ Doc Artifact ID is required.',
        };
    }

    const previousArtifactID = activity.ArtifactID;
    activity.ArtifactID = trimmedID;

    if (options?.saveNow === false) {
        return {
            Success: true,
            ArtifactID: trimmedID,
            ArtifactName: options.artifactName ?? null,
        };
    }

    try {
        const saved = await activity.Save();
        if (!saved) {
            activity.ArtifactID = previousArtifactID;
            return {
                Success: false,
                ArtifactID: previousArtifactID,
                ErrorMessage: activity.LatestResult?.CompleteMessage ?? 'Failed to link MJ Doc to activity.',
                RolledBack: true,
            };
        }
        return {
            Success: true,
            ArtifactID: trimmedID,
            ArtifactName: options?.artifactName ?? null,
        };
    } catch (err) {
        activity.ArtifactID = previousArtifactID;
        return {
            Success: false,
            ArtifactID: previousArtifactID,
            ErrorMessage: err instanceof Error ? err.message : String(err),
            RolledBack: true,
        };
    }
}

/**
 * Unlinks an `MJ: Artifacts` record from an Activity by setting `ArtifactID = null` while
 * strictly preserving `Description` and `Details`. Reverts `ArtifactID` if saving fails.
 */
export async function UnlinkArtifactFromActivity(
    activity: mjBizAppsCommonActivityEntity,
    options?: { saveNow?: boolean },
): Promise<ActivityArtifactActionResult> {
    const previousArtifactID = activity.ArtifactID;
    activity.ArtifactID = null;

    if (options?.saveNow === false) {
        return { Success: true, ArtifactID: null };
    }

    try {
        const saved = await activity.Save();
        if (!saved) {
            activity.ArtifactID = previousArtifactID;
            return {
                Success: false,
                ArtifactID: previousArtifactID,
                ErrorMessage: activity.LatestResult?.CompleteMessage ?? 'Failed to unlink MJ Doc from activity.',
                RolledBack: true,
            };
        }
        return { Success: true, ArtifactID: null };
    } catch (err) {
        activity.ArtifactID = previousArtifactID;
        return {
            Success: false,
            ArtifactID: previousArtifactID,
            ErrorMessage: err instanceof Error ? err.message : String(err),
            RolledBack: true,
        };
    }
}

async function resolveArtifactTypeId(
    provider: IMetadataProvider,
    artifactTypeName: string,
    contextUser?: UserInfo,
): Promise<string | null> {
    try {
        const cached = ArtifactMetadataEngine.Instance.FindArtifactType(artifactTypeName);
        if (cached?.ID) {
            return cached.ID;
        }
    } catch {
        // Engine may not be initialized in lightweight test environments; fall back to RunView.
    }

    try {
        const rv = RunView.FromMetadataProvider(provider);
        const res = await rv.RunView<ArtifactTypeIdRow>(
            {
                EntityName: MJ_ARTIFACT_ENTITIES.ArtifactType,
                ExtraFilter: `Name = '${EscapeSQLString(artifactTypeName)}'`,
                Fields: ['ID', 'Name'],
                MaxRows: 1,
                ResultType: 'simple',
                CacheLocal: false,
            },
            contextUser,
        );
        if (res.Success && res.Results.length > 0 && res.Results[0].ID) {
            return res.Results[0].ID;
        }
    } catch {
        // Fall through to null.
    }
    return null;
}

async function deleteQuietly(entity: MJArtifactEntity | MJArtifactVersionEntity): Promise<void> {
    try {
        await entity.Delete();
    } catch {
        // Best-effort compensating cleanup; never mask the primary save failure.
    }
}

function clearTransactionGroups(
    artifact: MJArtifactEntity,
    version: MJArtifactVersionEntity,
    activity: mjBizAppsCommonActivityEntity,
): void {
    artifact.TransactionGroup = null;
    version.TransactionGroup = null;
    activity.TransactionGroup = null;
}

/**
 * Opt-in expansion of an Activity into a linked MJ Doc (`MJ: Artifacts` + initial `v1`
 * `MJ: Artifact Versions`), setting `activity.ArtifactID` while preserving `Description` and `Details`.
 *
 * Uses `provider.CreateTransactionGroup()` with `TransactionVariable` when available so Artifact
 * creation, v1 version creation, and Activity update commit or roll back atomically. When a provider
 * does not support `TransactionGroup`, executes compensating rollback deletes on any failure so no
 * orphaned `MJ: Artifacts` record is ever left behind.
 */
export async function ExpandActivityToArtifact(
    activity: mjBizAppsCommonActivityEntity,
    options?: ExpandActivityToArtifactOptions,
): Promise<ActivityArtifactActionResult> {
    const activeProvider = options?.Provider ?? Metadata.Provider;
    const activeUser = options?.ContextUser ?? activeProvider?.CurrentUser;
    const title = (options?.Title ?? activity.Title ?? '').trim();
    if (!title) {
        return {
            Success: false,
            ArtifactID: activity.ArtifactID,
            ErrorMessage: 'A title is required to expand an activity into an MJ Doc.',
        };
    }

    const artifactTypeName = (options?.ArtifactTypeName ?? '').trim() || DEFAULT_ACTIVITY_ARTIFACT_TYPE_NAME;
    const artifactTypeID = await resolveArtifactTypeId(activeProvider, artifactTypeName, activeUser);
    if (!artifactTypeID) {
        return {
            Success: false,
            ArtifactID: activity.ArtifactID,
            ErrorMessage: `Artifact type '${artifactTypeName}' was not found.`,
        };
    }

    const markdownContent = options?.MarkdownContent ?? activity.Description ?? '';
    const previousArtifactID = activity.ArtifactID;

    try {
        const artifact = await activeProvider.GetEntityObject<MJArtifactEntity>(
            MJ_ARTIFACT_ENTITIES.Artifact,
            activeUser,
        );
        artifact.NewRecord();
        artifact.Name = title;
        artifact.TypeID = artifactTypeID;
        artifact.Visibility = 'Always';
        artifact.Description = StripActivityMarkdownExcerpt(markdownContent, 240) || null;
        if (activeUser?.ID) {
            artifact.UserID = activeUser.ID;
        }

        const version = await activeProvider.GetEntityObject<MJArtifactVersionEntity>(
            MJ_ARTIFACT_ENTITIES.ArtifactVersion,
            activeUser,
        );
        version.NewRecord();
        version.VersionNumber = 1;
        version.Name = title;
        version.Content = markdownContent;
        version.ContentMode = 'Text';
        if (activeUser?.ID) {
            version.UserID = activeUser.ID;
        }

        // Prefer atomic TransactionGroup when the provider supports it.
        if (typeof activeProvider.CreateTransactionGroup === 'function') {
            let tg: TransactionGroupBase | null = null;
            try {
                tg = await activeProvider.CreateTransactionGroup();
            } catch {
                tg = null;
            }
            if (tg) {
                artifact.TransactionGroup = tg;
                version.TransactionGroup = tg;
                activity.TransactionGroup = tg;
                tg.AddVariable(new TransactionVariable('ExpandedActivityArtifactID', artifact, 'ID', 'Define'));
                tg.AddVariable(new TransactionVariable('ExpandedActivityArtifactID', version, 'ArtifactID', 'Use'));
                tg.AddVariable(new TransactionVariable('ExpandedActivityArtifactID', activity, 'ArtifactID', 'Use'));

                await artifact.Save();
                await version.Save();
                await activity.Save();
                const committed = await tg.Submit();
                clearTransactionGroups(artifact, version, activity);

                if (!committed || !artifact.ID) {
                    activity.ArtifactID = previousArtifactID;
                    return {
                        Success: false,
                        ArtifactID: previousArtifactID,
                        ErrorMessage:
                            activity.LatestResult?.CompleteMessage ??
                            artifact.LatestResult?.CompleteMessage ??
                            'Transaction failed while expanding activity into an MJ Doc.',
                        RolledBack: true,
                    };
                }

                activity.ArtifactID = artifact.ID;
                return {
                    Success: true,
                    ArtifactID: artifact.ID,
                    ArtifactName: artifact.Name,
                };
            }
        }

        // Fallback when TransactionGroup is unavailable: sequential saves with compensating rollback.
        const artifactSaved = await artifact.Save();
        if (!artifactSaved || !artifact.ID) {
            return {
                Success: false,
                ArtifactID: previousArtifactID,
                ErrorMessage: artifact.LatestResult?.CompleteMessage ?? 'Failed to create MJ Doc artifact.',
            };
        }

        version.ArtifactID = artifact.ID;
        const versionSaved = await version.Save();
        if (!versionSaved) {
            await deleteQuietly(artifact);
            return {
                Success: false,
                ArtifactID: previousArtifactID,
                ErrorMessage: version.LatestResult?.CompleteMessage ?? 'Failed to save initial MJ Doc version.',
                RolledBack: true,
            };
        }

        activity.ArtifactID = artifact.ID;
        const activitySaved = await activity.Save();
        if (!activitySaved) {
            activity.ArtifactID = previousArtifactID;
            await deleteQuietly(version);
            await deleteQuietly(artifact);
            return {
                Success: false,
                ArtifactID: previousArtifactID,
                ErrorMessage: activity.LatestResult?.CompleteMessage ?? 'Failed to link created MJ Doc to activity.',
                RolledBack: true,
            };
        }

        return {
            Success: true,
            ArtifactID: artifact.ID,
            ArtifactName: artifact.Name,
        };
    } catch (err) {
        activity.ArtifactID = previousArtifactID;
        return {
            Success: false,
            ArtifactID: previousArtifactID,
            ErrorMessage: err instanceof Error ? err.message : String(err),
            RolledBack: true,
        };
    }
}

/**
 * Navigates to a linked MJ Doc (`MJ: Artifacts`) via `NavigationService.OpenArtifact(...)`
 * (or `OpenEntityRecord` / `FormComponent.OnFormNavigate` fallback when `NavigationService` is absent).
 */
export function OpenLinkedArtifact(
    artifactID: string | null | undefined,
    artifactName: string | null | undefined,
    navService?: NavigationService | null,
    onFormNavigate?: (event: FormNavigationEvent) => void,
): boolean {
    const trimmed = artifactID?.trim();
    if (!trimmed) {
        return false;
    }

    if (navService) {
        if (typeof navService.OpenArtifact === 'function') {
            navService.OpenArtifact(trimmed, artifactName ?? undefined);
            return true;
        }
        if (typeof navService.OpenEntityRecord === 'function') {
            navService.OpenEntityRecord(MJ_ARTIFACT_ENTITIES.Artifact, CompositeKey.FromID(trimmed));
            return true;
        }
    }

    if (onFormNavigate) {
        onFormNavigate({
            Kind: 'record',
            EntityName: MJ_ARTIFACT_ENTITIES.Artifact,
            PrimaryKey: CompositeKey.FromID(trimmed),
        });
        return true;
    }

    OpenCommonRecord(MJ_ARTIFACT_ENTITIES.Artifact, trimmed);
    return true;
}
