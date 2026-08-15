import {
    Assert,
    AssertEqual,
    IntegrationCheckRegistry,
    type IntegrationCheckContext,
    type NamedCheck,
} from '@memberjunction/testing-integration/registry';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';
import { COMMON_ENTITIES, WORLD_EMAIL_DOMAIN } from '../entity-names.js';
import { FindRows, Quote, RequireSave, SameID, View } from '../wire.js';
import { GetOrLoadWorld } from '../world/load-world.js';

const TAG = `it-person@${WORLD_EMAIL_DOMAIN}`;

const checks: NamedCheck[] = [
    {
        Id: 'people.P1',
        Name: 'P1 — create, reload, and update a person over GraphQL',
        RequiresMutation: true,
        Fn: async (ctx) => {
            await GetOrLoadWorld(ctx);
            const email = `p1.${Date.now()}@${WORLD_EMAIL_DOMAIN}`;
            const person = await ctx.Provider.GetEntityObject<mjBizAppsCommonPersonEntity>(COMMON_ENTITIES.Person, ctx.User);
            person.NewRecord();
            person.FirstName = 'P1';
            person.LastName = 'Wire';
            person.Email = email;
            person.Status = 'Active';
            await RequireSave(person, 'P1 create');
            const id = person.ID;

            const reloaded = await ctx.Provider.GetEntityObject<mjBizAppsCommonPersonEntity>(COMMON_ENTITIES.Person, ctx.User);
            Assert(await reloaded.Load(id), 'P1 reload');
            AssertEqual(reloaded.Email, email, 'email survived the wire');
            Assert(reloaded.DisplayName.includes('Wire'), `DisplayName should include last name, got ${reloaded.DisplayName}`);

            reloaded.Title = 'Wire Tester';
            await RequireSave(reloaded, 'P1 update');
            const again = await ctx.Provider.GetEntityObject<mjBizAppsCommonPersonEntity>(COMMON_ENTITIES.Person, ctx.User);
            Assert(await again.Load(id), 'P1 reload after update');
            AssertEqual(again.Title, 'Wire Tester', 'title update');

            Assert(await again.Delete(), 'P1 delete');
        },
    },
    {
        Id: 'people.P2',
        Name: 'P2 — RunView filter by email domain returns the world people',
        RequiresMutation: true,
        Fn: async (ctx) => {
            await GetOrLoadWorld(ctx);
            const rows = await FindRows<{ ID: string; Email: string; Status: string }>(
                ctx,
                COMMON_ENTITIES.Person,
                `Email LIKE '%@${Quote(WORLD_EMAIL_DOMAIN)}'`,
                ['ID', 'Email', 'Status'],
            );
            Assert(rows.length >= 10, `expected ≥10 world people, got ${rows.length}`);
            Assert(rows.every((r) => r.Email.endsWith(WORLD_EMAIL_DOMAIN)), 'every row is COM-WORLD');
        },
    },
    {
        Id: 'people.P3',
        Name: 'P3 — RunViews batches people and organizations in one round trip',
        RequiresMutation: true,
        Fn: async (ctx) => {
            await GetOrLoadWorld(ctx);
            const [people, orgs] = await View(ctx).RunViews(
                [
                    {
                        EntityName: COMMON_ENTITIES.Person,
                        ExtraFilter: `Email LIKE '%@${Quote(WORLD_EMAIL_DOMAIN)}'`,
                        Fields: ['ID', 'Email'],
                        ResultType: 'simple',
                    },
                    {
                        EntityName: COMMON_ENTITIES.Organization,
                        ExtraFilter: `Email LIKE '%${Quote(WORLD_EMAIL_DOMAIN)}%'`,
                        Fields: ['ID', 'Name', 'Email'],
                        ResultType: 'simple',
                    },
                ],
                ctx.User,
            );
            Assert(people.Success, `people batch failed: ${people.ErrorMessage ?? ''}`);
            Assert(orgs.Success, `orgs batch failed: ${orgs.ErrorMessage ?? ''}`);
            Assert((people.Results?.length ?? 0) >= 10, 'people batch count');
            Assert((orgs.Results?.length ?? 0) >= 7, 'org batch count');
        },
    },
    {
        Id: 'people.P4',
        Name: 'P4 — status Inactive is stored and filtered',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const email = `p4.${Date.now()}@${WORLD_EMAIL_DOMAIN}`;
            const person = await ctx.Provider.GetEntityObject<mjBizAppsCommonPersonEntity>(COMMON_ENTITIES.Person, ctx.User);
            person.NewRecord();
            person.FirstName = 'P4';
            person.LastName = 'Inactive';
            person.Email = email;
            person.Status = 'Inactive';
            await RequireSave(person, 'P4 create');
            const rows = await FindRows<{ ID: string }>(
                ctx,
                COMMON_ENTITIES.Person,
                `Email = '${Quote(email)}' AND Status = 'Inactive'`,
                ['ID'],
            );
            AssertEqual(rows.length, 1, 'inactive person visible through GraphQL filter');
            Assert(SameID(rows[0].ID, person.ID), 'same id');
            Assert(await person.Delete(), 'P4 delete');
        },
    },
    {
        Id: 'people.P5',
        Name: 'P5 — entity_object ResultType returns a Person we can mutate',
        RequiresMutation: true,
        Fn: async (ctx) => {
            await GetOrLoadWorld(ctx);
            const res = await View(ctx).RunView<mjBizAppsCommonPersonEntity>(
                {
                    EntityName: COMMON_ENTITIES.Person,
                    ExtraFilter: `Email = 'nora.calhoun@${Quote(WORLD_EMAIL_DOMAIN)}'`,
                    ResultType: 'entity_object',
                    MaxRows: 1,
                },
                ctx.User,
            );
            Assert(res.Success, res.ErrorMessage ?? 'entity_object failed');
            const nora = res.Results?.[0];
            Assert(!!nora, 'Nora as entity_object');
            AssertEqual(nora!.FirstName, 'Nora', 'typed FirstName');
            nora!.PreferredName = 'Nor';
            await RequireSave(nora!, 'Nora preferred name');
        },
    },
];

for (const check of checks) {
    IntegrationCheckRegistry.Instance.Register(check);
}

IntegrationCheckRegistry.Instance.RegisterLifecycle('people', {
    Setup: async () => {},
    Teardown: async () => {},
});

void TAG;
