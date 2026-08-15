import {
    Assert,
    AssertEqual,
    IntegrationCheckRegistry,
    type NamedCheck,
} from '@memberjunction/testing-integration/registry';
import {
    mjBizAppsCommonAddressEntity,
    mjBizAppsCommonAddressLinkEntity,
    mjBizAppsCommonContactMethodEntity,
} from '@mj-biz-apps/common-entities';
import { COMMON_ENTITIES, WORLD_EMAIL_DOMAIN } from '../entity-names.js';
import { FindRows, Quote, RequireSave } from '../wire.js';
import { GetOrLoadWorld } from '../world/load-world.js';

const checks: NamedCheck[] = [
    {
        Id: 'contacts-addresses.CA1',
        Name: 'CA1 — address + address-link attach to an organization over GraphQL',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const world = await GetOrLoadWorld(ctx);
            const orgEntity = ctx.Provider.EntityByName(COMMON_ENTITIES.Organization);
            Assert(!!orgEntity, 'Organizations entity');
            const address = await ctx.Provider.GetEntityObject<mjBizAppsCommonAddressEntity>(COMMON_ENTITIES.Address, ctx.User);
            address.NewRecord();
            address.Line1 = `${Date.now()} Wire Street`;
            address.City = 'Austin';
            address.StateProvince = 'TX';
            address.PostalCode = '78701';
            address.Country = 'US';
            await RequireSave(address, 'CA1 address');

            const link = await ctx.Provider.GetEntityObject<mjBizAppsCommonAddressLinkEntity>(COMMON_ENTITIES.AddressLink, ctx.User);
            link.NewRecord();
            link.AddressID = address.ID;
            link.EntityID = orgEntity!.ID;
            link.RecordID = world.Organizations.ATL.ID;
            link.AddressTypeID = world.AddressTypeIDs['Work'] ?? Object.values(world.AddressTypeIDs)[0];
            link.IsPrimary = false;
            await RequireSave(link, 'CA1 link');

            const rows = await FindRows<{ ID: string }>(
                ctx,
                COMMON_ENTITIES.AddressLink,
                `AddressID = '${address.ID}' AND RecordID = '${world.Organizations.ATL.ID}'`,
                ['ID'],
            );
            AssertEqual(rows.length, 1, 'link visible via RunView');
            Assert(await link.Delete(), 'cleanup link');
            Assert(await address.Delete(), 'cleanup address');
        },
    },
    {
        Id: 'contacts-addresses.CA2',
        Name: 'CA2 — contact method exclusivity: person XOR organization',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const world = await GetOrLoadWorld(ctx);
            const nora = world.People[`nora.calhoun@${WORLD_EMAIL_DOMAIN}`];
            const method = await ctx.Provider.GetEntityObject<mjBizAppsCommonContactMethodEntity>(
                COMMON_ENTITIES.ContactMethod,
                ctx.User,
            );
            method.NewRecord();
            method.PersonID = nora.ID;
            method.OrganizationID = world.Organizations.RIV.ID;
            method.ContactTypeID = world.ContactTypeIDs['Email'];
            method.Value = `both.${Date.now()}@${WORLD_EMAIL_DOMAIN}`;
            const saved = await method.Save();
            Assert(!saved, 'contact method with both Person and Org must refuse');
        },
    },
    {
        Id: 'contacts-addresses.CA3',
        Name: 'CA3 — world people have a primary email contact method',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const world = await GetOrLoadWorld(ctx);
            const nora = world.People[`nora.calhoun@${WORLD_EMAIL_DOMAIN}`];
            const rows = await FindRows<{ ID: string; Value: string; IsPrimary: boolean }>(
                ctx,
                COMMON_ENTITIES.ContactMethod,
                `PersonID = '${nora.ID}'`,
                ['ID', 'Value', 'IsPrimary'],
            );
            Assert(rows.some((r) => r.IsPrimary && r.Value === nora.Email), 'Nora has a primary email method');
        },
    },
];

for (const check of checks) {
    IntegrationCheckRegistry.Instance.Register(check);
}

IntegrationCheckRegistry.Instance.RegisterLifecycle('contacts-addresses', {
    Setup: async () => {},
    Teardown: async () => {},
});
