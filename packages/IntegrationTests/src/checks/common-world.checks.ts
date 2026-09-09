import {
    Assert,
    AssertEqual,
    IntegrationCheckRegistry,
    type IntegrationCheckContext,
    type NamedCheck,
} from '@memberjunction/testing-integration/registry';
import { WORLD_EMAIL_DOMAIN } from '../entity-names.js';
import { LoadWorld } from '../world/load-world.js';
import { World } from '../world/world.js';

const checks: NamedCheck[] = [
    {
        Id: 'common-world.CW1',
        Name: 'CW1 — COM-WORLD loads over GraphQL and is referentially intact',
        RequiresMutation: true,
        Fn: async (ctx: IntegrationCheckContext) => {
            const world = await LoadWorld(ctx);
            Assert(!!world.Organizations.RIV, 'Riverside Library missing');
            Assert(!!world.Organizations.BCP, 'Blue Cypress Press missing');
            Assert(!!world.Organizations.IMP, 'Blue Cypress Imprint missing');
            AssertEqual(world.Organizations.IMP.Name, 'Blue Cypress Imprint', 'imprint name');
            Assert(Object.keys(world.People).length >= 30, `expected ≥30 people, got ${Object.keys(world.People).length}`);
            Assert(!!world.People[`nora.calhoun@${WORLD_EMAIL_DOMAIN}`], 'Nora Calhoun missing');
            Assert(!!world.People[`jordan.blake@${WORLD_EMAIL_DOMAIN}`], 'Jordan Blake missing');
            Assert(!!world.People[`elena.voss@${WORLD_EMAIL_DOMAIN}`], 'Elena Voss missing');
            Assert(!!world.People[`ruth.adeleke@${WORLD_EMAIL_DOMAIN}`], 'Ruth Adeleke missing');
            Assert(!!world.Addresses['BCP-HQ'], 'BCP HQ address missing');
            Assert(!!world.OrganizationTypeIDs['Non-Profit'], 'Non-Profit type missing');
            Assert(!!world.RelationshipTypeIDs['Employee'], 'Employee relationship type missing');
            World();
        },
    },
    {
        Id: 'common-world.CW2',
        Name: 'CW2 — COM-WORLD people have CC0 DiceBear PhotoURLs',
        RequiresMutation: true,
        Fn: async (ctx: IntegrationCheckContext) => {
            const world = await LoadWorld(ctx);
            const { FindRows } = await import('../wire.js');
            const { COMMON_ENTITIES, WorldAvatarURL } = await import('../entity-names.js');
            const emails = Object.keys(world.People);
            const rows = await FindRows<{ Email: string; PhotoURL: string | null }>(
                ctx,
                COMMON_ENTITIES.Person,
                `Email IN (${emails.map((e) => `'${e.replace(/'/g, "''")}'`).join(',')})`,
                ['ID', 'Email', 'PhotoURL'],
            );
            Assert(rows.length >= 30, `people rows ${rows.length}`);
            const withPhoto = rows.filter((r) => (r.PhotoURL ?? '').startsWith('https://api.dicebear.com/'));
            Assert(withPhoto.length >= 25, `PhotoURL on ${withPhoto.length} people; expected most of the directory`);
            const elena = rows.find((r) => r.Email === `elena.voss@${WORLD_EMAIL_DOMAIN}`);
            Assert(!!elena?.PhotoURL, 'Elena PhotoURL missing');
            Assert(elena!.PhotoURL === WorldAvatarURL(elena!.Email), 'Elena PhotoURL should be the CC0 lorelei avatar');
        },
    },
];

for (const check of checks) {
    IntegrationCheckRegistry.Instance.Register(check);
}

IntegrationCheckRegistry.Instance.RegisterLifecycle('common-world', {
    Setup: async () => {},
    Teardown: async () => {},
});
