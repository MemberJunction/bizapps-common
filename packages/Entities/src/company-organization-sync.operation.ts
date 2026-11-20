import { BaseRemotableOperation } from '@memberjunction/core';

/**
 * Stable registry key for syncing `MJ: Companies` records into mirrored
 * `MJ_BizApps_Common: Organizations` records (via `Organization.LinkedCompanyID`).
 */
export const COMPANY_ORG_SYNC_OP_KEY = 'BizAppsCommon.SyncCompaniesToOrganizations';

/**
 * Input payload for `BizAppsCommon.SyncCompaniesToOrganizations`.
 */
export interface SyncCompaniesToOrganizationsInput {
    /**
     * Optional specific `MJ: Companies.ID` (UUID) to mirror.
     * When omitted or `null`, every row in `MJ: Companies` is reconciled idempotently.
     */
    CompanyID?: string | null;
}

/**
 * Per-company outcome emitted by `BizAppsCommon.SyncCompaniesToOrganizations`.
 */
export interface CompanyOrganizationSyncItem {
    /** Primary key of the source `MJ: Companies` record. */
    CompanyID: string;
    /** Primary key of the canonical mirrored `MJ_BizApps_Common: Organizations` record. */
    OrganizationID: string;
    /** Trimmed canonical `Company.Name` applied to the mirrored Organization. */
    CompanyName: string;
    /** Whether the mirror row was newly created, updated for drift, or already in sync. */
    Action: 'created' | 'updated' | 'unchanged';
}

/**
 * Aggregate reconciliation summary returned by `BizAppsCommon.SyncCompaniesToOrganizations`.
 */
export interface SyncCompaniesToOrganizationsOutput {
    /** Total `MJ: Companies` rows scanned during this invocation. */
    TotalCompanies: number;
    /** Number of new mirrored Organizations created. */
    CreatedCount: number;
    /** Number of existing mirrored Organizations updated due to field drift. */
    UpdatedCount: number;
    /** Number of existing mirrored Organizations already matching `MJ: Companies`. */
    UnchangedCount: number;
    /** Per-company mirror results in alphabetical `Company.Name` order. */
    Items: CompanyOrganizationSyncItem[];
}

/**
 * Typed Remotable Operation shell — callable identically from browser or server:
 *
 * ```ts
 * const res = await new SyncCompaniesToOrganizationsOperation().Execute({});
 * ```
 *
 * Server implementation is registered by `@mj-biz-apps/common-core-entities-server`
 * under `COMPANY_ORG_SYNC_OP_KEY`.
 */
export class SyncCompaniesToOrganizationsOperation extends BaseRemotableOperation<
    SyncCompaniesToOrganizationsInput,
    SyncCompaniesToOrganizationsOutput
> {
    public readonly OperationKey = COMPANY_ORG_SYNC_OP_KEY;
    public readonly AuthorizedWriteEntities = ['MJ_BizApps_Common: Organizations'] as const;
    public readonly ExposeAsAgentTool = true;
    public readonly ExposeAsMCPTool = true;
    public readonly ToolDescription =
        'Mirror MJ: Companies records into MJ_BizApps_Common: Organizations (linked via Organization.LinkedCompanyID).';
}
