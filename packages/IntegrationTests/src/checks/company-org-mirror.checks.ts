import { MJCompanyEntity } from '@memberjunction/core-entities';
import {
    Assert,
    AssertEqual,
    IntegrationCheckRegistry,
    type NamedCheck,
} from '@memberjunction/testing-integration/registry';
import {
    SyncCompaniesToOrganizationsOperation,
    mjBizAppsCommonOrganizationEntity,
} from '@mj-biz-apps/common-entities';
import { COMMON_ENTITIES } from '../entity-names.js';
import { FindRows, LoadById, RequireSave, SameID } from '../wire.js';

/**
 * GraphQL-wire integration checks for `MJ: Companies` -> `MJ_BizApps_Common: Organizations`
 * mirroring (`Organization.LinkedCompanyID`) and `BizAppsCommon.SyncCompaniesToOrganizations`.
 *
 * Every create, update, RunView, and Remotable Operation flows through MJAPI over GraphQL.
 */
const checks: NamedCheck[] = [
    {
        Id: 'company-org-mirror.CM1',
        Name: 'CM1 — creating MJ: Companies automatically mirrors an Active Organization with LinkedCompanyID',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const stamp = Date.now();
            const company = await ctx.Provider.GetEntityObject<MJCompanyEntity>(COMMON_ENTITIES.Company, ctx.User);
            company.NewRecord();
            company.Name = `IT Mirror Co ${stamp}`;
            company.Description = `Auto-mirrored integration test company ${stamp}`;
            company.Website = `https://mirror-${stamp}.example.com`;
            await RequireSave(company, 'create test Company');

            let mirroredOrgID: string | null = null;
            try {
                const orgs = await FindRows<{
                    ID: string;
                    Name: string;
                    Description: string | null;
                    Website: string | null;
                    LinkedCompanyID: string | null;
                    Status: string;
                }>(
                    ctx,
                    COMMON_ENTITIES.Organization,
                    `LinkedCompanyID = '${company.ID}'`,
                    ['ID', 'Name', 'Description', 'Website', 'LinkedCompanyID', 'Status'],
                );

                AssertEqual(orgs.length, 1, 'exactly one Organization mirrored for Company');
                mirroredOrgID = orgs[0].ID;
                Assert(SameID(orgs[0].LinkedCompanyID, company.ID), 'LinkedCompanyID matches Company.ID');
                AssertEqual(orgs[0].Name, company.Name, 'mirrored Name matches');
                AssertEqual(orgs[0].Description ?? '', company.Description ?? '', 'mirrored Description matches');
                AssertEqual(orgs[0].Website ?? '', company.Website ?? '', 'mirrored Website matches');
                AssertEqual(orgs[0].Status, 'Active', 'mirrored Organization is Active');
            } finally {
                if (mirroredOrgID) {
                    const org = await ctx.Provider.GetEntityObject<mjBizAppsCommonOrganizationEntity>(
                        COMMON_ENTITIES.Organization,
                        ctx.User,
                    );
                    await LoadById(org, mirroredOrgID);
                    await org.Delete();
                }
                await company.Delete();
            }
        },
    },
    {
        Id: 'company-org-mirror.CM2',
        Name: 'CM2 — updating MJ: Companies propagates Name, Description, and Website to the mirrored Organization',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const stamp = Date.now();
            const company = await ctx.Provider.GetEntityObject<MJCompanyEntity>(COMMON_ENTITIES.Company, ctx.User);
            company.NewRecord();
            company.Name = `IT Mirror Update Initial ${stamp}`;
            company.Description = 'Initial description';
            company.Website = 'https://initial.example.com';
            await RequireSave(company, 'create company for update test');

            let mirroredOrgID: string | null = null;
            try {
                const initialOrgs = await FindRows<{ ID: string }>(
                    ctx,
                    COMMON_ENTITIES.Organization,
                    `LinkedCompanyID = '${company.ID}'`,
                    ['ID'],
                );
                AssertEqual(initialOrgs.length, 1, 'initial mirrored Organization exists');
                mirroredOrgID = initialOrgs[0].ID;

                company.Name = `IT Mirror Update Renamed ${stamp}`;
                company.Description = 'Updated close-automation description';
                company.Website = 'https://updated.example.com';
                await RequireSave(company, 'update company');

                const updatedOrg = await ctx.Provider.GetEntityObject<mjBizAppsCommonOrganizationEntity>(
                    COMMON_ENTITIES.Organization,
                    ctx.User,
                );
                await LoadById(updatedOrg, mirroredOrgID);
                AssertEqual(updatedOrg.Name, company.Name, 'updated Name propagated');
                AssertEqual(updatedOrg.Description ?? '', company.Description ?? '', 'updated Description propagated');
                AssertEqual(updatedOrg.Website ?? '', company.Website ?? '', 'updated Website propagated');
            } finally {
                if (mirroredOrgID) {
                    const org = await ctx.Provider.GetEntityObject<mjBizAppsCommonOrganizationEntity>(
                        COMMON_ENTITIES.Organization,
                        ctx.User,
                    );
                    await LoadById(org, mirroredOrgID);
                    await org.Delete();
                }
                await company.Delete();
            }
        },
    },
    {
        Id: 'company-org-mirror.CM3',
        Name: 'CM3 — BizAppsCommon.SyncCompaniesToOrganizations Remotable Operation is idempotent and reconciles drift',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const stamp = Date.now();
            const company = await ctx.Provider.GetEntityObject<MJCompanyEntity>(COMMON_ENTITIES.Company, ctx.User);
            company.NewRecord();
            company.Name = `IT Sync RPC Co ${stamp}`;
            company.Description = 'Canonical company description';
            await RequireSave(company, 'create company for RPC sync test');

            let mirroredOrgID: string | null = null;
            try {
                const initial = await FindRows<{ ID: string }>(
                    ctx,
                    COMMON_ENTITIES.Organization,
                    `LinkedCompanyID = '${company.ID}'`,
                    ['ID'],
                );
                AssertEqual(initial.length, 1, 'auto-mirrored Organization exists');
                mirroredOrgID = initial[0].ID;

                // 1. Idempotent run reports unchanged
                const op = new SyncCompaniesToOrganizationsOperation();
                const noop = await op.Execute({ CompanyID: company.ID }, { provider: ctx.Provider, user: ctx.User });
                Assert(noop.Success, `SyncCompaniesToOrganizations failed: ${noop.ErrorMessage ?? 'unknown'}`);
                AssertEqual(noop.Output?.TotalCompanies, 1, 'scoped sync scanned 1 company');
                AssertEqual(noop.Output?.UnchangedCount, 1, 'already-synced company is unchanged');

                // 2. Introduce manual drift on the Organization and reconcile via RPC
                const org = await ctx.Provider.GetEntityObject<mjBizAppsCommonOrganizationEntity>(
                    COMMON_ENTITIES.Organization,
                    ctx.User,
                );
                await LoadById(org, mirroredOrgID);
                org.Description = 'Drifted description';
                await RequireSave(org, 'introduce drift on mirrored Organization');

                const repaired = await op.Execute({ CompanyID: company.ID }, { provider: ctx.Provider, user: ctx.User });
                Assert(repaired.Success, `reconciliation RPC failed: ${repaired.ErrorMessage ?? 'unknown'}`);
                AssertEqual(repaired.Output?.UpdatedCount, 1, 'reconciliation updated 1 drifted mirror');

                const reloaded = await ctx.Provider.GetEntityObject<mjBizAppsCommonOrganizationEntity>(
                    COMMON_ENTITIES.Organization,
                    ctx.User,
                );
                await LoadById(reloaded, mirroredOrgID);
                AssertEqual(
                    reloaded.Description ?? '',
                    'Canonical company description',
                    'RPC reconciled Description back to canonical MJ: Company',
                );
            } finally {
                if (mirroredOrgID) {
                    const org = await ctx.Provider.GetEntityObject<mjBizAppsCommonOrganizationEntity>(
                        COMMON_ENTITIES.Organization,
                        ctx.User,
                    );
                    await LoadById(org, mirroredOrgID);
                    await org.Delete();
                }
                await company.Delete();
            }
        },
    },
    {
        Id: 'company-org-mirror.CM4',
        Name: 'CM4 — UQ_Organization_LinkedCompanyID refuses duplicate Company links while allowing multiple external Organizations',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const stamp = Date.now();
            const company = await ctx.Provider.GetEntityObject<MJCompanyEntity>(COMMON_ENTITIES.Company, ctx.User);
            company.NewRecord();
            company.Name = `IT Unique Mirror Co ${stamp}`;
            company.Description = 'Uniqueness integration test company';
            await RequireSave(company, 'create company for uniqueness test');

            const externalA = await ctx.Provider.GetEntityObject<mjBizAppsCommonOrganizationEntity>(
                COMMON_ENTITIES.Organization,
                ctx.User,
            );
            const externalB = await ctx.Provider.GetEntityObject<mjBizAppsCommonOrganizationEntity>(
                COMMON_ENTITIES.Organization,
                ctx.User,
            );
            let mirroredOrgID: string | null = null;

            try {
                const mirrors = await FindRows<{ ID: string }>(
                    ctx,
                    COMMON_ENTITIES.Organization,
                    `LinkedCompanyID = '${company.ID}'`,
                    ['ID'],
                );
                AssertEqual(mirrors.length, 1, 'first mirrored Organization exists');
                mirroredOrgID = mirrors[0].ID;

                // Attempt to create a second Organization pointing to the same LinkedCompanyID -> must fail
                const duplicate = await ctx.Provider.GetEntityObject<mjBizAppsCommonOrganizationEntity>(
                    COMMON_ENTITIES.Organization,
                    ctx.User,
                );
                duplicate.NewRecord();
                duplicate.Name = `IT Duplicate Mirror ${stamp}`;
                duplicate.LinkedCompanyID = company.ID;
                duplicate.Status = 'Active';
                const dupSaved = await duplicate.Save();
                Assert(!dupSaved, 'UQ_Organization_LinkedCompanyID must refuse a second Organization for the same Company');

                // Multiple external Organizations with LinkedCompanyID = null coexist cleanly
                externalA.NewRecord();
                externalA.Name = `IT External Client A ${stamp}`;
                externalA.LinkedCompanyID = null;
                externalA.Status = 'Active';
                await RequireSave(externalA, 'save external org A');

                externalB.NewRecord();
                externalB.Name = `IT External Client B ${stamp}`;
                externalB.LinkedCompanyID = null;
                externalB.Status = 'Active';
                await RequireSave(externalB, 'save external org B');
            } finally {
                if (externalB.IsSaved) await externalB.Delete();
                if (externalA.IsSaved) await externalA.Delete();
                if (mirroredOrgID) {
                    const org = await ctx.Provider.GetEntityObject<mjBizAppsCommonOrganizationEntity>(
                        COMMON_ENTITIES.Organization,
                        ctx.User,
                    );
                    await LoadById(org, mirroredOrgID);
                    await org.Delete();
                }
                await company.Delete();
            }
        },
    },
];

for (const check of checks) {
    IntegrationCheckRegistry.Instance.Register(check);
}

IntegrationCheckRegistry.Instance.RegisterLifecycle('company-org-mirror', {
    Setup: async () => {},
    Teardown: async () => {},
});
