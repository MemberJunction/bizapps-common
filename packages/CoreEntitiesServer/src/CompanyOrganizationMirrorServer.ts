import {
    BaseEntity,
    BaseRemotableOperation,
    CompositeKey,
    EntitySaveOptions,
    IMetadataProvider,
    LogError,
    RunView,
    UserInfo,
} from '@memberjunction/core';
import { MJCompanyEntity } from '@memberjunction/core-entities';
import { RegisterClass } from '@memberjunction/global';
import {
    COMPANY_ORG_SYNC_OP_KEY,
    CompanyOrganizationSyncItem,
    SyncCompaniesToOrganizationsInput,
    SyncCompaniesToOrganizationsOperation,
    SyncCompaniesToOrganizationsOutput,
    mjBizAppsCommonOrganizationEntity,
} from '@mj-biz-apps/common-entities';
import { MetadataOf } from './entity-guards.js';

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

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
}

function normalizeOptionalString(val: string | null | undefined): string | null {
    const trimmed = val?.trim();
    return trimmed && trimmed.length > 0 ? trimmed : null;
}

/**
 * Ensures a single `MJ: Companies` record has an up-to-date mirrored row in
 * `MJ_BizApps_Common: Organizations` (`LinkedCompanyID = company.ID`).
 *
 * Idempotent:
 * - Creates a new `Active` Organization if no row currently references `company.ID`.
 * - Updates mirrored fields (`Name`, `Website`, `LogoURL`, `Description`) only when drifted.
 * - Skips redundant database writes (`Action: 'unchanged'`) when all fields match.
 *
 * @param company Source `MJ: Companies` projection.
 * @param provider Active server-side MJ metadata/entity data provider.
 * @param contextUser Authenticated user context for MJ entity reads/writes.
 * @returns Per-company sync result containing the canonical `OrganizationID` and action taken.
 * @throws When `company.ID` is not a valid UUID or an entity read/save fails.
 */
export async function MirrorCompanyToOrganization(
    company: CompanyMirrorSource,
    provider: IMetadataProvider,
    contextUser: UserInfo | undefined,
): Promise<CompanyOrganizationSyncItem> {
    if (!UUID_PATTERN.test(company.ID)) {
        throw new Error(`Invalid Company ID '${company.ID}'`);
    }

    const rv = RunView.FromMetadataProvider(provider);
    const existingRes = await rv.RunView<{ ID: string }>({
        EntityName: 'MJ_BizApps_Common: Organizations',
        ExtraFilter: `LinkedCompanyID = '${company.ID}'`,
        Fields: ['ID'],
        MaxRows: 1,
        ResultType: 'simple',
    }, contextUser);

    if (!existingRes.Success) {
        throw new Error(`Failed querying mirrored Organization for Company ${company.ID}: ${existingRes.ErrorMessage}`);
    }

    const existingId = existingRes.Results?.[0]?.ID;
    const org = await provider.GetEntityObject<mjBizAppsCommonOrganizationEntity>(
        'MJ_BizApps_Common: Organizations',
        contextUser,
    );

    const nextName = company.Name.trim();
    const nextWebsite = normalizeOptionalString(company.Website);
    const nextLogoURL = normalizeOptionalString(company.LogoURL);
    const nextDescription = normalizeOptionalString(company.Description);

    if (existingId) {
        const loaded = await org.InnerLoad(CompositeKey.FromID(existingId));
        if (!loaded) {
            throw new Error(`Could not load mirrored Organization ${existingId} for Company ${company.ID}`);
        }
        const changed =
            org.Name !== nextName ||
            normalizeOptionalString(org.Website) !== nextWebsite ||
            normalizeOptionalString(org.LogoURL) !== nextLogoURL ||
            normalizeOptionalString(org.Description) !== nextDescription;

        if (!changed) {
            return {
                CompanyID: company.ID,
                OrganizationID: org.ID,
                CompanyName: nextName,
                Action: 'unchanged',
            };
        }

        org.Name = nextName;
        org.Website = nextWebsite;
        org.LogoURL = nextLogoURL;
        org.Description = nextDescription;
        const saved = await org.Save();
        if (!saved) {
            throw new Error(`Failed updating mirrored Organization ${org.ID}: ${org.LatestResult?.CompleteMessage ?? 'unknown error'}`);
        }
        return {
            CompanyID: company.ID,
            OrganizationID: org.ID,
            CompanyName: nextName,
            Action: 'updated',
        };
    }

    org.NewRecord();
    org.Name = nextName;
    org.Website = nextWebsite;
    org.LogoURL = nextLogoURL;
    org.Description = nextDescription;
    org.LinkedCompanyID = company.ID;
    org.Status = 'Active';

    const saved = await org.Save();
    if (!saved) {
        throw new Error(`Failed creating mirrored Organization for Company ${company.ID}: ${org.LatestResult?.CompleteMessage ?? 'unknown error'}`);
    }
    return {
        CompanyID: company.ID,
        OrganizationID: org.ID,
        CompanyName: nextName,
        Action: 'created',
    };
}

/**
 * Server-side subclass of `MJ: Companies` that automatically mirrors creates and
 * updates to `MJ_BizApps_Common: Organizations` (`LinkedCompanyID = Company.ID`).
 *
 * Keeps internal legal entities from `__mj.Company` and external organizations
 * unified inside `Organization` across BizApps (Tasks, Close Automation, CRM, etc.).
 */
@RegisterClass(BaseEntity, 'MJ: Companies')
export class CompanyOrganizationMirrorEntityServer extends MJCompanyEntity {
    public override async Save(options?: EntitySaveOptions): Promise<boolean> {
        const saved = await super.Save(options);
        if (!saved) {
            return false;
        }

        const provider = MetadataOf(this);
        if (!provider) {
            return true;
        }
        try {
            await MirrorCompanyToOrganization(
                {
                    ID: this.ID,
                    Name: this.Name,
                    Description: this.Description,
                    Website: this.Website,
                    LogoURL: this.LogoURL,
                },
                provider,
                this.ContextCurrentUser,
            );
        } catch (err) {
            // Do not fail the core MJ: Companies write if Organization mirroring hits a transient error;
            // callers can also run BizAppsCommon.SyncCompaniesToOrganizations to reconcile.
            LogError(`CompanyOrganizationMirrorEntityServer: failed to mirror Company ${this.ID} to Organization`, undefined, err);
        }

        return true;
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
        const extraFilter = input?.CompanyID
            ? (() => {
                  if (!UUID_PATTERN.test(input.CompanyID)) {
                      throw new Error(`Invalid CompanyID '${input.CompanyID}'`);
                  }
                  return `ID = '${input.CompanyID}'`;
              })()
            : '';

        const rv = RunView.FromMetadataProvider(provider);
        const companiesRes = await rv.RunView<CompanyMirrorSource>({
            EntityName: 'MJ: Companies',
            ExtraFilter: extraFilter,
            Fields: ['ID', 'Name', 'Description', 'Website', 'LogoURL'],
            OrderBy: 'Name ASC',
            ResultType: 'simple',
        }, user);

        if (!companiesRes.Success) {
            throw new Error(`Failed loading MJ: Companies: ${companiesRes.ErrorMessage}`);
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
