import {
    Assert,
    AssertEqual,
    IntegrationCheckRegistry,
    type NamedCheck,
} from '@memberjunction/testing-integration/registry';
import { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';
import { COMMON_ENTITIES, WORLD_EMAIL_DOMAIN } from '../entity-names.js';
import { FindRows, Quote, RequireSave } from '../wire.js';
import { GetOrLoadWorld } from '../world/load-world.js';

const checks: NamedCheck[] = [
    {
        Id: 'organizations.O1',
        Name: 'O1 — parent/child hierarchy is visible over GraphQL',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const world = await GetOrLoadWorld(ctx);
            const imprint = await ctx.Provider.GetEntityObject<mjBizAppsCommonOrganizationEntity>(
                COMMON_ENTITIES.Organization,
                ctx.User,
            );
            Assert(await imprint.Load(world.Organizations.IMP.ID), 'load imprint');
            AssertEqual(imprint.ParentID ?? '', world.Organizations.BCP.ID, 'imprint parent is BCP');

            const children = await FindRows<{ ID: string; Name: string }>(
                ctx,
                COMMON_ENTITIES.Organization,
                `ParentID = '${world.Organizations.BCP.ID}'`,
                ['ID', 'Name'],
            );
            Assert(children.some((c) => c.Name === 'Blue Cypress Imprint'), 'child query finds imprint');
        },
    },
    {
        Id: 'organizations.O2',
        Name: 'O2 — create an org of each shipped type',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const world = await GetOrLoadWorld(ctx);
            const stamp = Date.now();
            const created: mjBizAppsCommonOrganizationEntity[] = [];
            for (const [typeName, typeID] of Object.entries(world.OrganizationTypeIDs)) {
                const org = await ctx.Provider.GetEntityObject<mjBizAppsCommonOrganizationEntity>(
                    COMMON_ENTITIES.Organization,
                    ctx.User,
                );
                org.NewRecord();
                org.Name = `IT ${typeName} ${stamp}`;
                org.Email = `o2.${typeName.replace(/\s+/g, '-').toLowerCase()}.${stamp}@${WORLD_EMAIL_DOMAIN}`;
                org.OrganizationTypeID = typeID;
                org.Status = 'Active';
                await RequireSave(org, `org type ${typeName}`);
                created.push(org);
            }
            Assert(created.length >= 6, `expected a row per shipped type, got ${created.length}`);
            for (const org of created) {
                Assert(await org.Delete(), `cleanup ${org.Name}`);
            }
        },
    },
    {
        Id: 'organizations.O3',
        Name: 'O3 — RunView by type name (denormalized OrganizationType)',
        RequiresMutation: true,
        Fn: async (ctx) => {
            await GetOrLoadWorld(ctx);
            const rows = await FindRows<{ ID: string; Name: string; OrganizationType: string }>(
                ctx,
                COMMON_ENTITIES.Organization,
                `OrganizationType = 'Educational Institution' AND Email LIKE '%${Quote(WORLD_EMAIL_DOMAIN)}%'`,
                ['ID', 'Name', 'OrganizationType'],
            );
            Assert(rows.length >= 2, 'NGS and SUM are educational');
        },
    },
];

for (const check of checks) {
    IntegrationCheckRegistry.Instance.Register(check);
}

IntegrationCheckRegistry.Instance.RegisterLifecycle('organizations', {
    Setup: async () => {},
    Teardown: async () => {},
});
