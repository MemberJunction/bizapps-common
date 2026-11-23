/**
 * Copyright (c) MemberJunction.com
 * SPDX-License-Identifier: BUSL-1.1
 */
import {
    BaseEntity,
    BaseEntityResult,
    BaseRemotableOperation,
    CompositeKey,
    EntitySaveOptions,
    IMetadataProvider,
    LogError,
    RunView,
    UserInfo,
} from '@memberjunction/core';
import { MJCompanyEntity } from '@memberjunction/core-entities';
import { IsValidUUID, RegisterClass, UUIDsEqual, ValidationErrorInfo } from '@memberjunction/global';
import {
    BuildOrganizationMirrorLookupFilter,
    COMPANY_ORG_SYNC_OP_KEY,
    CompanyMirrorError,
    CompanyMirrorErrorDetails,
    CompanyMirrorResult,
    CompanyOrganizationMatchStrategy,
    CompanyOrganizationSyncItem,
    ExtractCompanyMatchKeys,
    FormatCompanyMirrorError,
    NormalizeMirrorErrorCause,
    NormalizeMirrorOptionalString,
    OrganizationLookupCandidate,
    OrganizationMirrorStatus,
    SelectOrganizationMirrorCandidate,
    SyncCompaniesToOrganizationsInput,
    SyncCompaniesToOrganizationsOperation,
    SyncCompaniesToOrganizationsOutput,
    mjBizAppsCommonOrganizationEntity,
} from '@mj-biz-apps/common-entities';
import { MetadataOf } from './entity-guards.js';

const ORGANIZATION_ENTITY_NAME = 'MJ_BizApps_Common: Organizations';
const COMPANY_ENTITY_NAME = 'MJ: Companies';
const ORGANIZATION_LOOKUP_FIELDS: string[] = [
    'ID',
    'Name',
    'LegalName',
    'Website',
    'WebsiteDomain',
    'LinkedCompanyID',
    'Status',
];
const MAX_LOOKUP_CANDIDATES = 25;

/**
 * Minimal field projection of an `MJ: Companies` record mirrored into
 * `MJ_BizApps_Common: Organizations`.
 */
export interface CompanyMirrorSource {
    /** Primary key (`__mj.Company.ID`). Must be a valid UUID. */
    ID: string;
    /** Legal or operating company name mirrored to `Organization.Name`. */
    Name: string;
    /** Optional description mirrored to `Organization.Description`. */
    Description: string | null;
    /** Optional website URL mirrored to `Organization.Website`. */
    Website: string | null;
    /** Optional logo URL mirrored to `Organization.LogoURL`. */
    LogoURL: string | null;
    /** Optional primary email/web domain (`__mj.Company.Domain`) used during duplicate-org detection. */
    Domain?: string | null;
}

interface NormalizedMirrorFields {
    readonly Name: string;
    readonly Description: string | null;
    readonly Website: string | null;
    readonly LogoURL: string | null;
}

/**
 * Non-throwing mirror synchronization helper returning a strongly typed {@link CompanyMirrorResult}.
 *
 * - Detects an existing linked (`LinkedCompanyID`) or pre-existing unlinked internal Organization via
 *   `RunView` (`ResultType: 'simple'`) before creating a new Organization record.
 * - Surfaces deterministic structured {@link CompanyMirrorErrorDetails} instead of swallowing failures.
 */
export async function TryMirrorCompanyToOrganization(
    company: CompanyMirrorSource,
    provider: IMetadataProvider,
    contextUser: UserInfo | undefined,
): Promise<CompanyMirrorResult> {
    try {
        const item = await executeMirrorSync(company, provider, contextUser);
        return { Success: true, Item: item };
    } catch (err) {
        if (err instanceof CompanyMirrorError) {
            return { Success: false, Error: err.ToDetails() };
        }
        const cause = NormalizeMirrorErrorCause(
            err instanceof Error ? err : typeof err === 'string' ? err : 'Unknown mirror failure',
        );
        return {
            Success: false,
            Error: {
                Code: 'UNEXPECTED_MIRROR_ERROR',
                Context: {
                    CompanyID: company.ID,
                    CompanyName: company.Name,
                    Operation: 'link',
                },
                DiagnosticMessage: cause?.Message ?? 'Unexpected error during Company mirror synchronization',
                Cause: cause,
            },
        };
    }
}

/**
 * Ensures a single `MJ: Companies` record has an up-to-date mirrored row in
 * `MJ_BizApps_Common: Organizations` (`LinkedCompanyID = company.ID`).
 *
 * Idempotent:
 * - Links a matching pre-existing internal Organization before creating a new row.
 * - Creates a new `Active` Organization only when no matching row exists.
 * - Updates `LinkedCompanyID` and mirrored fields (`Name`, `Website`, `LogoURL`, `Description`) only when drifted.
 * - Skips redundant database writes (`Action: 'unchanged'`) when already linked and all fields match.
 *
 * @throws {@link CompanyMirrorError} When validation, lookup, load, or save fails.
 */
export async function MirrorCompanyToOrganization(
    company: CompanyMirrorSource,
    provider: IMetadataProvider,
    contextUser: UserInfo | undefined,
): Promise<CompanyOrganizationSyncItem> {
    const result = await TryMirrorCompanyToOrganization(company, provider, contextUser);
    if (!result.Success && 'Error' in result) {
        throw new CompanyMirrorError(result.Error);
    }
    return result.Item;
}

async function executeMirrorSync(
    company: CompanyMirrorSource,
    provider: IMetadataProvider,
    contextUser: UserInfo | undefined,
): Promise<CompanyOrganizationSyncItem> {
    const keys = ExtractCompanyMatchKeys(company);
    const nextFields: NormalizedMirrorFields = {
        Name: company.Name.trim(),
        Website: NormalizeMirrorOptionalString(company.Website),
        LogoURL: NormalizeMirrorOptionalString(company.LogoURL),
        Description: NormalizeMirrorOptionalString(company.Description),
    };

    const rv = RunView.FromMetadataProvider(provider);
    const existingRes = await rv.RunView<OrganizationLookupCandidate>(
        {
            EntityName: ORGANIZATION_ENTITY_NAME,
            ExtraFilter: BuildOrganizationMirrorLookupFilter(keys),
            Fields: ORGANIZATION_LOOKUP_FIELDS,
            MaxRows: MAX_LOOKUP_CANDIDATES,
            ResultType: 'simple',
        },
        contextUser,
    );

    if (!existingRes.Success) {
        throw new CompanyMirrorError({
            Code: 'ORGANIZATION_LOOKUP_FAILED',
            Context: {
                CompanyID: company.ID,
                CompanyName: nextFields.Name,
                Operation: 'lookup',
            },
            DiagnosticMessage: `Failed querying mirrored Organization for Company ${company.ID}: ${existingRes.ErrorMessage}`,
        });
    }

    const selection = SelectOrganizationMirrorCandidate(existingRes.Results ?? [], keys);
    const org = await provider.GetEntityObject<mjBizAppsCommonOrganizationEntity>(
        ORGANIZATION_ENTITY_NAME,
        contextUser,
    );

    if (selection) {
        return syncExistingOrganization(org, company.ID, nextFields, selection.Candidate.ID, selection.Strategy);
    }

    return createMirroredOrganization(org, company.ID, nextFields);
}

async function syncExistingOrganization(
    org: mjBizAppsCommonOrganizationEntity,
    companyId: string,
    nextFields: NormalizedMirrorFields,
    organizationId: string,
    strategy: Exclude<CompanyOrganizationMatchStrategy, 'created'>,
): Promise<CompanyOrganizationSyncItem> {
    const loaded = await org.InnerLoad(CompositeKey.FromID(organizationId));
    if (!loaded) {
        throw new CompanyMirrorError({
            Code: 'ORGANIZATION_LOAD_FAILED',
            Context: {
                CompanyID: companyId,
                CompanyName: nextFields.Name,
                OrganizationID: organizationId,
                Operation: 'load',
            },
            DiagnosticMessage: `Could not load mirrored Organization ${organizationId} for Company ${companyId}`,
        });
    }

    const needsLink = !UUIDsEqual(org.LinkedCompanyID, companyId);
    const changed =
        needsLink ||
        org.Name !== nextFields.Name ||
        NormalizeMirrorOptionalString(org.Website) !== nextFields.Website ||
        NormalizeMirrorOptionalString(org.LogoURL) !== nextFields.LogoURL ||
        NormalizeMirrorOptionalString(org.Description) !== nextFields.Description;

    if (!changed) {
        return {
            CompanyID: companyId,
            OrganizationID: org.ID,
            CompanyName: nextFields.Name,
            Action: 'unchanged',
            LinkedExistingOrganization: false,
            MatchStrategy: strategy,
        };
    }

    if (needsLink) {
        org.LinkedCompanyID = companyId;
    }
    org.Name = nextFields.Name;
    org.Website = nextFields.Website;
    org.LogoURL = nextFields.LogoURL;
    org.Description = nextFields.Description;

    const saved = await org.Save();
    if (!saved) {
        const message = org.LatestResult?.CompleteMessage ?? 'unknown error';
        throw new CompanyMirrorError({
            Code: 'ORGANIZATION_SAVE_FAILED',
            Context: {
                CompanyID: companyId,
                CompanyName: nextFields.Name,
                OrganizationID: org.ID,
                Operation: needsLink ? 'link' : 'update',
            },
            DiagnosticMessage: `Failed updating mirrored Organization ${org.ID}: ${message}`,
        });
    }

    return {
        CompanyID: companyId,
        OrganizationID: org.ID,
        CompanyName: nextFields.Name,
        Action: 'updated',
        LinkedExistingOrganization: needsLink,
        MatchStrategy: strategy,
    };
}

async function createMirroredOrganization(
    org: mjBizAppsCommonOrganizationEntity,
    companyId: string,
    nextFields: NormalizedMirrorFields,
): Promise<CompanyOrganizationSyncItem> {
    const activeStatus: OrganizationMirrorStatus = 'Active';
    org.NewRecord();
    org.Name = nextFields.Name;
    org.Website = nextFields.Website;
    org.LogoURL = nextFields.LogoURL;
    org.Description = nextFields.Description;
    org.LinkedCompanyID = companyId;
    org.Status = activeStatus;

    const saved = await org.Save();
    if (!saved) {
        const message = org.LatestResult?.CompleteMessage ?? 'unknown error';
        throw new CompanyMirrorError({
            Code: 'ORGANIZATION_SAVE_FAILED',
            Context: {
                CompanyID: companyId,
                CompanyName: nextFields.Name,
                Operation: 'create',
            },
            DiagnosticMessage: `Failed creating mirrored Organization for Company ${companyId}: ${message}`,
        });
    }

    return {
        CompanyID: companyId,
        OrganizationID: org.ID,
        CompanyName: nextFields.Name,
        Action: 'created',
        LinkedExistingOrganization: false,
        MatchStrategy: 'created',
    };
}

/**
 * Server-side subclass of `MJ: Companies` that automatically mirrors creates and
 * updates to `MJ_BizApps_Common: Organizations` (`LinkedCompanyID = Company.ID`).
 *
 * Surfaces structured mirror errors deterministically via {@link LastMirrorError} and
 * `BaseEntity.LatestResult` while returning `false` if mirror synchronization fails.
 */
@RegisterClass(BaseEntity, 'MJ: Companies')
export class CompanyOrganizationMirrorEntityServer extends MJCompanyEntity {
    private lastMirrorError: CompanyMirrorErrorDetails | null = null;

    /** Most recent structured mirror error recorded during `Save()`, or `null` when clean. */
    public get LastMirrorError(): CompanyMirrorErrorDetails | null {
        return this.lastMirrorError;
    }

    public override async Save(options?: EntitySaveOptions): Promise<boolean> {
        this.lastMirrorError = null;
        const saved = await super.Save(options);
        if (!saved) {
            return false;
        }

        const provider = MetadataOf(this);
        if (!provider) {
            return true;
        }

        const mirrorResult = await TryMirrorCompanyToOrganization(
            {
                ID: this.ID,
                Name: this.Name,
                Description: this.Description,
                Website: this.Website,
                LogoURL: this.LogoURL,
                Domain: this.safeReadDomain(),
            },
            provider,
            this.ContextCurrentUser,
        );

        if (!mirrorResult.Success && 'Error' in mirrorResult) {
            this.recordMirrorFailure(mirrorResult.Error);
            return false;
        }

        return true;
    }

    private safeReadDomain(): string | null {
        if (Object.prototype.hasOwnProperty.call(this, 'Domain') || Array.isArray(this.Fields)) {
            return this.Domain;
        }
        return null;
    }

    private recordMirrorFailure(error: CompanyMirrorErrorDetails): void {
        this.lastMirrorError = error;
        const formatted = FormatCompanyMirrorError(error);
        LogError(`CompanyOrganizationMirrorEntityServer: ${formatted}`, undefined, error);

        if (Array.isArray(this.ResultHistory)) {
            const result = new BaseEntityResult();
            result.Success = false;
            result.Type = this.IsSaved ? 'update' : 'create';
            result.Message = formatted;
            result.Errors = [new ValidationErrorInfo('LinkedCompanyID', formatted, this.ID)];
            result.MessageIncludesErrors = true;
            result.StartedAt = new Date();
            result.EndedAt = new Date();
            this.RegisterResultHistoryEntry(result);
        }
    }
}

/**
 * Server implementation of `BizAppsCommon.SyncCompaniesToOrganizations`.
 * Backfills or reconciles all `MJ: Companies` rows (or one specific `CompanyID`)
 * into `MJ_BizApps_Common: Organizations`.
 */
@RegisterClass(BaseRemotableOperation, COMPANY_ORG_SYNC_OP_KEY)
export class SyncCompaniesToOrganizationsServerOperation extends SyncCompaniesToOrganizationsOperation {
    protected override async InternalExecute(
        input: SyncCompaniesToOrganizationsInput,
        provider: IMetadataProvider,
        user: UserInfo,
    ): Promise<SyncCompaniesToOrganizationsOutput> {
        const extraFilter = buildCompanyExtraFilter(input?.CompanyID);
        const rv = RunView.FromMetadataProvider(provider);
        const companiesRes = await rv.RunView<CompanyMirrorSource>(
            {
                EntityName: COMPANY_ENTITY_NAME,
                ExtraFilter: extraFilter,
                Fields: ['ID', 'Name', 'Description', 'Website', 'LogoURL', 'Domain'],
                OrderBy: 'Name ASC',
                ResultType: 'simple',
            },
            user,
        );

        if (!companiesRes.Success) {
            throw new CompanyMirrorError({
                Code: 'COMPANIES_LOAD_FAILED',
                Context: {
                    CompanyID: input?.CompanyID ?? '',
                    Operation: 'batch_sync',
                },
                DiagnosticMessage: `Failed loading MJ: Companies: ${companiesRes.ErrorMessage}`,
            });
        }

        const companies = companiesRes.Results ?? [];
        const items: CompanyOrganizationSyncItem[] = [];
        let createdCount = 0;
        let updatedCount = 0;
        let unchangedCount = 0;

        for (const company of companies) {
            const item = await MirrorCompanyToOrganization(company, provider, user);
            items.push(item);
            if (item.Action === 'created') createdCount++;
            else if (item.Action === 'updated') updatedCount++;
            else unchangedCount++;
        }

        return {
            TotalCompanies: companies.length,
            CreatedCount: createdCount,
            UpdatedCount: updatedCount,
            UnchangedCount: unchangedCount,
            Items: items,
        };
    }
}

function buildCompanyExtraFilter(companyId: string | null | undefined): string {
    if (!companyId) {
        return '';
    }
    if (!IsValidUUID(companyId)) {
        throw new CompanyMirrorError({
            Code: 'INVALID_COMPANY_ID',
            Context: {
                CompanyID: companyId,
                Operation: 'batch_sync',
            },
            DiagnosticMessage: `Invalid CompanyID '${companyId}'`,
        });
    }
    return `ID = '${companyId}'`;
}
