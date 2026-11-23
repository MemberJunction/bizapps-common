/**
 * Copyright (c) MemberJunction.com
 * SPDX-License-Identifier: BUSL-1.1
 */
import { RemoteOperationError } from '@memberjunction/core';
import { EscapeSQLString, IsValidUUID, NormalizeUUID, UUIDsEqual } from '@memberjunction/global';
import type { mjBizAppsCommonOrganizationEntity } from './generated/entity_subclasses';

/** Status union derived directly from the generated `MJ_BizApps_Common: Organizations` entity. */
export type OrganizationMirrorStatus = mjBizAppsCommonOrganizationEntity['Status'];

/** Valid status values derived from {@link OrganizationMirrorStatus}. */
const VALID_ORGANIZATION_MIRROR_STATUSES: ReadonlySet<OrganizationMirrorStatus> = new Set<OrganizationMirrorStatus>([
    'Active',
    'Dissolved',
    'Inactive',
]);

/** Default archive status applied to an active mirrored Organization when its linked Company is deleted. */
export const DEFAULT_COMPANY_DELETE_ARCHIVE_STATUS: OrganizationMirrorStatus = 'Inactive';

/**
 * Configures how deleting a mirrored `MJ: Companies` record transitions the linked
 * `MJ_BizApps_Common: Organizations` row after clearing `LinkedCompanyID`.
 */
export interface CompanyDeleteUnlinkOptions {
    /**
     * Target `Status` applied when the linked Organization is currently `'Active'`.
     * Defaults to `'Inactive'`. Pass `null` to clear `LinkedCompanyID` without changing `Status`.
     */
    readonly ArchiveStatus?: OrganizationMirrorStatus | null;
}

/** Resolved runtime policy for safe Company delete unlink/archive transitions. */
export interface CompanyMirrorDeletePolicy {
    readonly ArchiveStatus: OrganizationMirrorStatus | null;
}

/** Canonical default delete-unlink policy (`ArchiveStatus: 'Inactive'`). */
export const DEFAULT_COMPANY_MIRROR_DELETE_POLICY: Readonly<CompanyMirrorDeletePolicy> = {
    ArchiveStatus: DEFAULT_COMPANY_DELETE_ARCHIVE_STATUS,
};

let registeredDeletePolicy: CompanyMirrorDeletePolicy | null = null;

/** Machine-readable error codes emitted by Company <-> Organization mirror synchronization. */
export type CompanyMirrorErrorCode =
    | 'INVALID_COMPANY_ID'
    | 'INVALID_COMPANY_DATA'
    | 'ORGANIZATION_LOOKUP_FAILED'
    | 'AMBIGUOUS_ORGANIZATION_MATCH'
    | 'ORGANIZATION_LOAD_FAILED'
    | 'ORGANIZATION_SAVE_FAILED'
    | 'COMPANIES_LOAD_FAILED'
    | 'UNEXPECTED_MIRROR_ERROR';

/** Lifecycle phase in which a Company <-> Organization mirror operation failed. */
export type CompanyMirrorOperationPhase = 'lookup' | 'load' | 'create' | 'update' | 'link' | 'unlink' | 'batch_sync';

/** Strategy that matched or created the target `MJ_BizApps_Common: Organizations` record. */
export type CompanyOrganizationMatchStrategy =
    | 'linked_company_id'
    | 'normalized_name'
    | 'legal_name'
    | 'website_domain'
    | 'created';

/** Item shape emitted by a single Company <-> Organization mirror sync. */
export interface CompanyOrganizationMirrorOutcomeItem {
    readonly CompanyID: string;
    readonly OrganizationID: string;
    readonly CompanyName: string;
    readonly Action: 'created' | 'updated' | 'unchanged';
    readonly LinkedExistingOrganization?: boolean;
    readonly MatchStrategy?: CompanyOrganizationMatchStrategy;
}

/** Discriminated result union returned by non-throwing mirror sync helpers. */
export type CompanyMirrorResult =
    | { readonly Success: true; readonly Item: CompanyOrganizationMirrorOutcomeItem }
    | { readonly Success: false; readonly Error: CompanyMirrorErrorDetails };

/** Summary emitted after safely unlinking/archiving Organizations for a deleted `MJ: Companies` row. */
export interface CompanyOrganizationUnlinkOutcomeItem {
    readonly CompanyID: string;
    readonly OrganizationID: string | null;
    readonly UnlinkedCount: number;
    readonly UnlinkedOrganizationIDs: readonly string[];
    readonly Action: 'unlinked' | 'unchanged' | 'not_linked';
    readonly AppliedStatus: OrganizationMirrorStatus | null;
}

/** Discriminated result union returned by non-throwing delete-unlink helpers. */
export type CompanyUnlinkResult =
    | { readonly Success: true; readonly Item: CompanyOrganizationUnlinkOutcomeItem }
    | { readonly Success: false; readonly Error: CompanyMirrorErrorDetails };

/** Entity & operation metadata attached to every {@link CompanyMirrorErrorDetails}. */
export interface CompanyMirrorEntityContext {
    /** Source `MJ: Companies.ID` (or raw input string when validation failed). */
    readonly CompanyID: string;
    /** Optional trimmed source `Company.Name`. */
    readonly CompanyName?: string;
    /** Target `MJ_BizApps_Common: Organizations.ID`, when known. */
    readonly OrganizationID?: string | null;
    /** Mirror lifecycle phase that failed. */
    readonly Operation: CompanyMirrorOperationPhase;
    /** Candidate Organization IDs when ambiguity prevented deterministic linking. */
    readonly CandidateOrganizationIDs?: readonly string[];
}

/** Normalized underlying cause details without exposing untyped `any`/`unknown` values. */
export interface CompanyMirrorErrorCause {
    readonly Name: string;
    readonly Message: string;
    readonly Stack?: string;
}

/** Serializable structured mirror error payload surfaced to callers and `BaseEntity.LatestResult`. */
export interface CompanyMirrorErrorDetails {
    readonly Code: CompanyMirrorErrorCode;
    readonly Context: CompanyMirrorEntityContext;
    readonly DiagnosticMessage: string;
    readonly Cause?: CompanyMirrorErrorCause;
}

/**
 * Strongly typed mirror error that integrates with both `Error` handling and
 * `BaseRemotableOperation.ExecuteServer` (`RemoteOperationError.ResultCode`).
 */
export class CompanyMirrorError extends RemoteOperationError {
    public readonly Code: CompanyMirrorErrorCode;
    public readonly Context: CompanyMirrorEntityContext;
    public readonly DiagnosticMessage: string;
    public readonly Cause?: CompanyMirrorErrorCause;

    constructor(details: CompanyMirrorErrorDetails) {
        super(details.Code, details.DiagnosticMessage);
        this.name = 'CompanyMirrorError';
        this.Code = details.Code;
        this.Context = details.Context;
        this.DiagnosticMessage = details.DiagnosticMessage;
        this.Cause = details.Cause;
    }

    /** Returns a plain, JSON-serializable snapshot of this error. */
    public ToDetails(): CompanyMirrorErrorDetails {
        return {
            Code: this.Code,
            Context: this.Context,
            DiagnosticMessage: this.DiagnosticMessage,
            ...(this.Cause ? { Cause: this.Cause } : {}),
        };
    }
}

/** Plain `RunView` (`ResultType: 'simple'`) projection for Organization deduplication lookup. */
export interface OrganizationLookupCandidate {
    readonly ID: string;
    readonly Name?: string | null;
    readonly LegalName?: string | null;
    readonly Website?: string | null;
    readonly WebsiteDomain?: string | null;
    readonly LinkedCompanyID?: string | null;
    readonly Status?: OrganizationMirrorStatus | null;
}

/** Normalized Company identity keys used to detect an existing Organization before creating a duplicate. */
export interface CompanyMatchKeys {
    readonly CompanyID: string;
    readonly NormalizedName: string;
    readonly CandidateDomains: readonly string[];
}

/** Deterministic candidate selection result returned by {@link SelectOrganizationMirrorCandidate}. */
export interface SelectedOrganizationCandidate {
    readonly Candidate: OrganizationLookupCandidate;
    readonly Strategy: Exclude<CompanyOrganizationMatchStrategy, 'created'>;
}

const DEFAULT_LOOKUP_BATCH_SIZE = 100;

/** Formats a {@link CompanyMirrorErrorDetails} payload into a deterministic diagnostic string. */
export function FormatCompanyMirrorError(details: CompanyMirrorErrorDetails): string {
    return `[${details.Code}] ${details.DiagnosticMessage}`;
}

/** Converts an `Error` or string into a structured {@link CompanyMirrorErrorCause}. */
export function NormalizeMirrorErrorCause(err: Error | string | undefined): CompanyMirrorErrorCause | undefined {
    if (err === undefined) {
        return undefined;
    }
    if (typeof err === 'string') {
        return { Name: 'Error', Message: err };
    }
    return {
        Name: err.name || 'Error',
        Message: err.message,
        ...(err.stack ? { Stack: err.stack } : {}),
    };
}

/** Trims an optional string and collapses blank values to `null`. */
export function NormalizeMirrorOptionalString(val: string | null | undefined): string | null {
    const trimmed = val?.trim();
    return trimmed && trimmed.length > 0 ? trimmed : null;
}

/**
 * Normalizes a website URL or bare domain using the exact same rules as the computed
 * `Organization.WebsiteDomain` column: lowercased host without `http(s)://`, leading `www.`,
 * path, query, or fragment.
 */
export function NormalizeMirrorWebsiteDomain(raw: string | null | undefined): string | null {
    const trimmed = raw?.trim().toLowerCase();
    if (!trimmed) {
        return null;
    }
    const withoutScheme = trimmed.replace(/^https?:\/\//, '').replace(/^www\./, '');
    const host = withoutScheme.split(/[/?#]/)[0]?.trim() ?? '';
    if (!host || !host.includes('.') || /\s/.test(host)) {
        return null;
    }
    return host;
}

/** Validates Company identity fields and extracts normalized lookup keys for mirror matching. */
export function ExtractCompanyMatchKeys(company: {
    readonly ID: string;
    readonly Name: string;
    readonly Website?: string | null;
    readonly Domain?: string | null;
}): CompanyMatchKeys {
    if (!IsValidUUID(company.ID)) {
        throw new CompanyMirrorError({
            Code: 'INVALID_COMPANY_ID',
            Context: { CompanyID: company.ID, Operation: 'lookup' },
            DiagnosticMessage: `Invalid Company ID '${company.ID}'`,
        });
    }

    const trimmedName = company.Name.trim();
    if (!trimmedName) {
        throw new CompanyMirrorError({
            Code: 'INVALID_COMPANY_DATA',
            Context: { CompanyID: company.ID, CompanyName: company.Name, Operation: 'lookup' },
            DiagnosticMessage: `Company ${company.ID} must have a non-empty Name to mirror into Organization`,
        });
    }

    const domains = new Set<string>();
    const websiteDomain = NormalizeMirrorWebsiteDomain(company.Website);
    if (websiteDomain) {
        domains.add(websiteDomain);
    }
    const companyDomain = NormalizeMirrorWebsiteDomain(company.Domain);
    if (companyDomain) {
        domains.add(companyDomain);
    }

    return {
        CompanyID: company.ID,
        NormalizedName: trimmedName.toLowerCase(),
        CandidateDomains: [...domains],
    };
}

/**
 * Builds a dual-dialect-safe ANSI SQL `ExtraFilter` (no dialect brackets, quotes, or proprietary
 * functions) that matches either the already-linked Organization (`LinkedCompanyID`) or an
 * unlinked pre-existing Organization (`LinkedCompanyID IS NULL`) sharing normalized identity keys.
 */
export function BuildOrganizationMirrorLookupFilter(keys: CompanyMatchKeys): string {
    const escapedName = EscapeSQLString(keys.NormalizedName);
    const unlinkedClauses: string[] = [
        `LOWER(Name) = '${escapedName}'`,
        `LOWER(LegalName) = '${escapedName}'`,
    ];
    for (const domain of keys.CandidateDomains) {
        unlinkedClauses.push(`WebsiteDomain = '${EscapeSQLString(domain)}'`);
    }
    return `LinkedCompanyID = '${keys.CompanyID}' OR (LinkedCompanyID IS NULL AND (${unlinkedClauses.join(' OR ')}))`;
}

/** Splits a list of lookup values into bounded batches to respect SQL expression/parameter limits. */
export function ChunkLookupValues<T>(values: readonly T[], chunkSize: number = DEFAULT_LOOKUP_BATCH_SIZE): T[][] {
    const size = Math.max(1, Math.floor(chunkSize));
    const chunks: T[][] = [];
    for (let i = 0; i < values.length; i += size) {
        chunks.push(values.slice(i, i + size));
    }
    return chunks;
}

/**
 * Deterministically selects the existing Organization candidate for a Company, prioritizing
 * `LinkedCompanyID` first (idempotent re-sync) and falling back to unlinked candidates.
 * Throws a structured `AMBIGUOUS_ORGANIZATION_MATCH` error instead of guessing when multiple
 * candidates tie.
 */
export function SelectOrganizationMirrorCandidate(
    candidates: readonly OrganizationLookupCandidate[],
    keys: CompanyMatchKeys,
): SelectedOrganizationCandidate | null {
    if (candidates.length === 0) {
        return null;
    }

    const linkedMatches = candidates.filter(
        (c) => c.LinkedCompanyID != null && UUIDsEqual(c.LinkedCompanyID, keys.CompanyID),
    );
    if (linkedMatches.length === 1) {
        return { Candidate: linkedMatches[0], Strategy: 'linked_company_id' };
    }
    if (linkedMatches.length > 1) {
        throw buildAmbiguousMatchError(keys, linkedMatches, 'Multiple Organizations share LinkedCompanyID');
    }

    const unlinked = candidates.filter((c) => c.LinkedCompanyID == null);
    if (unlinked.length === 0) {
        return null;
    }
    if (unlinked.length === 1) {
        return { Candidate: unlinked[0], Strategy: inferMatchStrategy(unlinked[0], keys) };
    }

    return disambiguateUnlinkedCandidates(unlinked, keys);
}

function disambiguateUnlinkedCandidates(
    unlinked: readonly OrganizationLookupCandidate[],
    keys: CompanyMatchKeys,
): SelectedOrganizationCandidate {
    const nameMatches = unlinked.filter((c) => c.Name?.trim().toLowerCase() === keys.NormalizedName);
    if (nameMatches.length === 1) {
        return { Candidate: nameMatches[0], Strategy: 'normalized_name' };
    }
    if (nameMatches.length > 1) {
        throw buildAmbiguousMatchError(keys, nameMatches, 'Multiple unlinked Organizations match normalized Name');
    }

    const legalNameMatches = unlinked.filter((c) => c.LegalName?.trim().toLowerCase() === keys.NormalizedName);
    if (legalNameMatches.length === 1) {
        return { Candidate: legalNameMatches[0], Strategy: 'legal_name' };
    }
    if (legalNameMatches.length > 1) {
        throw buildAmbiguousMatchError(keys, legalNameMatches, 'Multiple unlinked Organizations match normalized LegalName');
    }

    throw buildAmbiguousMatchError(keys, unlinked, 'Multiple unlinked Organizations match Company identity');
}

function inferMatchStrategy(
    candidate: OrganizationLookupCandidate,
    keys: CompanyMatchKeys,
): Exclude<CompanyOrganizationMatchStrategy, 'created'> {
    if (candidate.Name?.trim().toLowerCase() === keys.NormalizedName) {
        return 'normalized_name';
    }
    if (candidate.LegalName?.trim().toLowerCase() === keys.NormalizedName) {
        return 'legal_name';
    }
    const candidateDomain =
        NormalizeMirrorWebsiteDomain(candidate.WebsiteDomain) ?? NormalizeMirrorWebsiteDomain(candidate.Website);
    if (candidateDomain && keys.CandidateDomains.includes(candidateDomain)) {
        return 'website_domain';
    }
    return 'linked_company_id';
}

function buildAmbiguousMatchError(
    keys: CompanyMatchKeys,
    candidates: readonly OrganizationLookupCandidate[],
    reason: string,
): CompanyMirrorError {
    const candidateIds = candidates.map((c) => c.ID);
    return new CompanyMirrorError({
        Code: 'AMBIGUOUS_ORGANIZATION_MATCH',
        Context: {
            CompanyID: keys.CompanyID,
            Operation: 'lookup',
            CandidateOrganizationIDs: candidateIds,
        },
        DiagnosticMessage: `${reason} for Company ${keys.CompanyID}: candidates [${candidateIds.join(', ')}]`,
    });
}

function sanitizeArchiveStatus(
    status: OrganizationMirrorStatus | null | undefined,
    fallback: OrganizationMirrorStatus | null,
): OrganizationMirrorStatus | null {
    if (status === undefined) {
        return fallback;
    }
    if (status === null) {
        return null;
    }
    return VALID_ORGANIZATION_MIRROR_STATUSES.has(status) ? status : fallback;
}

/**
 * Registers a process-wide default delete-unlink policy for `CompanyOrganizationMirrorEntityServer`.
 * Pass `null` to restore {@link DEFAULT_COMPANY_MIRROR_DELETE_POLICY}.
 */
export function RegisterCompanyMirrorDeletePolicy(policy: CompanyDeleteUnlinkOptions | null): void {
    if (!policy) {
        registeredDeletePolicy = null;
        return;
    }
    registeredDeletePolicy = {
        ArchiveStatus: sanitizeArchiveStatus(policy.ArchiveStatus, DEFAULT_COMPANY_DELETE_ARCHIVE_STATUS),
    };
}

/** Clears any registered delete-unlink policy override (for test isolation). */
export function ResetCompanyMirrorDeletePolicy(): void {
    registeredDeletePolicy = null;
}

/** Resolves the effective delete-unlink policy from defaults, registered policy, and optional call override. */
export function GetCompanyMirrorDeletePolicy(override?: CompanyDeleteUnlinkOptions): CompanyMirrorDeletePolicy {
    const base = registeredDeletePolicy ?? DEFAULT_COMPANY_MIRROR_DELETE_POLICY;
    if (!override || override.ArchiveStatus === undefined) {
        return { ArchiveStatus: base.ArchiveStatus };
    }
    return {
        ArchiveStatus: sanitizeArchiveStatus(override.ArchiveStatus, base.ArchiveStatus),
    };
}

/**
 * Builds a dual-dialect-safe ANSI SQL `ExtraFilter` (no dialect brackets, quotes, or proprietary
 * functions) matching Organizations currently linked to `companyId` via `LinkedCompanyID`.
 */
export function BuildOrganizationLinkedCompanyFilter(companyId: string): string {
    if (!IsValidUUID(companyId)) {
        throw new CompanyMirrorError({
            Code: 'INVALID_COMPANY_ID',
            Context: { CompanyID: companyId, Operation: 'unlink' },
            DiagnosticMessage: `Invalid Company ID '${companyId}'`,
        });
    }
    return `LinkedCompanyID = '${companyId}'`;
}

/**
 * Filters and deterministically orders `OrganizationLookupCandidate` rows that actually carry
 * `LinkedCompanyID` matching `companyId` (defending against unlinked or foreign-linked rows).
 */
export function SelectLinkedOrganizationsForUnlink(
    candidates: readonly OrganizationLookupCandidate[],
    companyId: string,
): OrganizationLookupCandidate[] {
    if (!IsValidUUID(companyId)) {
        throw new CompanyMirrorError({
            Code: 'INVALID_COMPANY_ID',
            Context: { CompanyID: companyId, Operation: 'unlink' },
            DiagnosticMessage: `Invalid Company ID '${companyId}'`,
        });
    }

    const seenIds = new Set<string>();
    const matched: OrganizationLookupCandidate[] = [];
    for (const candidate of candidates) {
        if (candidate.LinkedCompanyID == null || !UUIDsEqual(candidate.LinkedCompanyID, companyId)) {
            continue;
        }
        const normalizedId = NormalizeUUID(candidate.ID);
        if (seenIds.has(normalizedId)) {
            continue;
        }
        seenIds.add(normalizedId);
        matched.push(candidate);
    }

    return matched.sort((a, b) => NormalizeUUID(a.ID).localeCompare(NormalizeUUID(b.ID)));
}

/**
 * Resolves the safe Organization `Status` after unlinking a deleted Company.
 * Preserves `'Dissolved'` and `'Inactive'` states without regression, and transitions `'Active'`
 * organizations to `archiveStatus` (default `'Inactive'`) unless `archiveStatus === null`.
 */
export function ResolveOrganizationUnlinkStatus(
    currentStatus: OrganizationMirrorStatus | null | undefined,
    archiveStatus: OrganizationMirrorStatus | null | undefined = DEFAULT_COMPANY_DELETE_ARCHIVE_STATUS,
): OrganizationMirrorStatus | null {
    const resolvedTarget = sanitizeArchiveStatus(archiveStatus, DEFAULT_COMPANY_DELETE_ARCHIVE_STATUS);
    if (resolvedTarget === null) {
        return currentStatus ?? null;
    }
    if (currentStatus === 'Dissolved' || currentStatus === 'Inactive') {
        return currentStatus;
    }
    return resolvedTarget;
}
