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
            Assert(Object.keys(world.People).length >= 10, `expected ≥10 people, got ${Object.keys(world.People).length}`);
            Assert(!!world.People[`nora.calhoun@${WORLD_EMAIL_DOMAIN}`], 'Nora Calhoun missing');
            Assert(!!world.People[`jordan.blake@${WORLD_EMAIL_DOMAIN}`], 'Jordan Blake missing');
            Assert(!!world.Addresses['BCP-HQ'], 'BCP HQ address missing');
            Assert(!!world.OrganizationTypeIDs['Non-Profit'], 'Non-Profit type missing');
            Assert(!!world.RelationshipTypeIDs['Employee'], 'Employee relationship type missing');
            World();
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
