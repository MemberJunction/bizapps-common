/**
 * @mj-biz-apps/common-integration-tests — GraphQL-wire checks for the party directory.
 *
 * Importing this module registers every bundle on IntegrationCheckRegistry.
 * The standalone runner (`test-harnesses/integration.mjs`) and `mj test`
 * both load this package after `bootstrapIntegrationClient`, so every
 * Save / RunView / Load goes through MJAPI.
 *
 * BUNDLES
 *   common-world         CW1       commit COM-WORLD (people, orgs, addresses, contacts, relationships)
 *   people               P1–P5     person CRUD, filters, RunViews batch, entity_object
 *   organizations        O1–O3     hierarchy, every shipped type, denormalized type filter
 *   contacts-addresses   CA1–CA3   address links, contact exclusivity, primary email
 *   relationships        R1–R4     employment, exclusivity, person-to-person, status
 *   activities           A1–A5     types, regarding/xor/unresolved links, ExternalID, sync
 */
import { LoadGeneratedEntities } from '@mj-biz-apps/common-entities';

LoadGeneratedEntities();

export * from './entity-names.js';
export * from './wire.js';
export * from './world/world.js';
export * from './world/load-world.js';
export * from './checks/common-world.checks.js';
export * from './checks/people.checks.js';
export * from './checks/organizations.checks.js';
export * from './checks/contacts-addresses.checks.js';
export * from './checks/relationships.checks.js';
export * from './checks/activities.checks.js';

export function LoadCommonIntegrationTests(): void {
    // side-effect import is the registration
}
