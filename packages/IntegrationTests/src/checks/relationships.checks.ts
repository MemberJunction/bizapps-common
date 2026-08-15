import {
    Assert,
    AssertEqual,
    IntegrationCheckRegistry,
    type NamedCheck,
} from '@memberjunction/testing-integration/registry';
import { mjBizAppsCommonRelationshipEntity } from '@mj-biz-apps/common-entities';
import { COMMON_ENTITIES, WORLD_EMAIL_DOMAIN } from '../entity-names.js';
import { FindRows, Quote, RequireSave } from '../wire.js';
import { GetOrLoadWorld } from '../world/load-world.js';

const checks: NamedCheck[] = [
    {
        Id: 'relationships.R1',
        Name: 'R1 — employment rows from COM-WORLD are queryable',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const world = await GetOrLoadWorld(ctx);
            const nora = world.People[`nora.calhoun@${WORLD_EMAIL_DOMAIN}`];
            const rows = await FindRows<{ ID: string; FromPersonID: string; ToOrganizationID: string }>(
                ctx,
                COMMON_ENTITIES.Relationship,
                `FromPersonID = '${nora.ID}' AND ToOrganizationID = '${world.Organizations.RIV.ID}'`,
                ['ID', 'FromPersonID', 'ToOrganizationID'],
            );
            AssertEqual(rows.length, 1, 'Nora works at Riverside');
        },
    },
    {
        Id: 'relationships.R2',
        Name: 'R2 — exclusivity: from-person XOR from-organization',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const world = await GetOrLoadWorld(ctx);
            const nora = world.People[`nora.calhoun@${WORLD_EMAIL_DOMAIN}`];
            const rel = await ctx.Provider.GetEntityObject<mjBizAppsCommonRelationshipEntity>(
                COMMON_ENTITIES.Relationship,
                ctx.User,
            );
            rel.NewRecord();
            rel.RelationshipTypeID = world.RelationshipTypeIDs['Employee'];
            rel.FromPersonID = nora.ID;
            rel.FromOrganizationID = world.Organizations.RIV.ID;
            rel.ToOrganizationID = world.Organizations.BCP.ID;
            rel.Status = 'Active';
            const saved = await rel.Save();
            Assert(!saved, 'relationship with both FromPerson and FromOrg must refuse');
        },
    },
    {
        Id: 'relationships.R3',
        Name: 'R3 — person-to-person relationship (independent contractor)',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const world = await GetOrLoadWorld(ctx);
            const jordan = world.People[`jordan.blake@${WORLD_EMAIL_DOMAIN}`];
            const ada = world.People[`ada.lovelace@${WORLD_EMAIL_DOMAIN}`];
            const typeID = world.RelationshipTypeIDs['Consultant'] ?? world.RelationshipTypeIDs['Friend'];
            const rel = await ctx.Provider.GetEntityObject<mjBizAppsCommonRelationshipEntity>(
                COMMON_ENTITIES.Relationship,
                ctx.User,
            );
            rel.NewRecord();
            rel.RelationshipTypeID = typeID;
            rel.FromPersonID = jordan.ID;
            rel.ToPersonID = ada.ID;
            rel.Title = 'Freelance editor';
            rel.Status = 'Active';
            await RequireSave(rel, 'R3 consultant');
            const rows = await FindRows<{ ID: string }>(
                ctx,
                COMMON_ENTITIES.Relationship,
                `FromPersonID = '${jordan.ID}' AND ToPersonID = '${ada.ID}'`,
                ['ID'],
            );
            Assert(rows.length >= 1, 'consultant link visible');
            Assert(await rel.Delete(), 'cleanup R3');
        },
    },
    {
        Id: 'relationships.R4',
        Name: 'R4 — ending a relationship sets Status Ended',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const world = await GetOrLoadWorld(ctx);
            const marcus = world.People[`marcus.webb@${WORLD_EMAIL_DOMAIN}`];
            const rows = await FindRows<{ ID: string }>(
                ctx,
                COMMON_ENTITIES.Relationship,
                `FromPersonID = '${marcus.ID}' AND ToOrganizationID = '${world.Organizations.ATL.ID}'`,
                ['ID'],
            );
            Assert(rows.length >= 1, 'Marcus employment exists');
            const rel = await ctx.Provider.GetEntityObject<mjBizAppsCommonRelationshipEntity>(
                COMMON_ENTITIES.Relationship,
                ctx.User,
            );
            Assert(await rel.Load(rows[0].ID), 'load Marcus employment');
            rel.Status = 'Ended';
            rel.EndDate = new Date();
            await RequireSave(rel, 'end Marcus employment');
            const again = await ctx.Provider.GetEntityObject<mjBizAppsCommonRelationshipEntity>(
                COMMON_ENTITIES.Relationship,
                ctx.User,
            );
            Assert(await again.Load(rows[0].ID), 'reload');
            AssertEqual(again.Status, 'Ended', 'status persisted over the wire');
            again.Status = 'Active';
            again.EndDate = null;
            await RequireSave(again, 'restore Marcus employment');
        },
    },
];

for (const check of checks) {
    IntegrationCheckRegistry.Instance.Register(check);
}

IntegrationCheckRegistry.Instance.RegisterLifecycle('relationships', {
    Setup: async () => {},
    Teardown: async () => {},
});

void Quote;
