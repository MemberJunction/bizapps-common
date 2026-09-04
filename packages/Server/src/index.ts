/**
 * BizApps Common Server Bootstrap
 *
 * Server-side bootstrap package for the BizApps Common Open App.
 * Ensures all entity subclasses, action subclasses, and GraphQL resolvers
 * are registered with the MJ class factory.
 */

// Import entity and action packages to trigger @RegisterClass decorators
import '@mj-biz-apps/common-entities';
import '@mj-biz-apps/common-actions';

// Server-side entity subclasses — must come after common-entities so
// @RegisterClass auto-increment gives these higher priority
import '@mj-biz-apps/common-core-entities-server';
import { LoadActivitySyncEngine } from '@mj-biz-apps/common-core-entities-server';
import { LoadSyncActivitiesAction } from './custom/sync-activities.action.js';
import { LoadLogActivityAction } from './custom/log-activity.action.js';
import { LoadGraphTransportFactory } from './custom/graph-transport-factory.js';
import { LoadLiveMailboxPolicyFromEnv } from './custom/live-mailbox-policy.js';

// Import generated GraphQL resolvers
import './generated/generated.js';

// Import generated class registrations manifest
import { CLASS_REGISTRATIONS } from './generated/class-registrations-manifest.js';

// Re-export the manifest for consumers
export { CLASS_REGISTRATIONS } from './generated/class-registrations-manifest.js';

import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

const __dirname = fileURLToPath(new URL('.', import.meta.url));

/** Absolute paths to the generated resolver files, for use with createMJServer() */
export const RESOLVER_PATHS = [resolve(__dirname, 'generated/generated.{js,ts}')];

/**
 * Bootstrap function called by DynamicPackageLoader during MJAPI startup.
 * The static imports above handle all registration; this function ensures
 * the module is fully evaluated.
 */
export function LoadBizAppsCommonServer(): void {
    // Static imports above ensure all classes are registered.
    // This function exists as the startupExport entry point for DynamicPackageLoader.
    LoadActivitySyncEngine();
    LoadSyncActivitiesAction();
    LoadLogActivityAction();
    // Registers the seam that turns a connection's CredentialsRef into a live Graph transport.
    // Nothing about this enables a live read on its own — the provider still refuses until this
    // host attests that its app registration is scoped.
    LoadGraphTransportFactory();
    // And that attestation, when this deployment has one. Absent, every live read stays refused;
    // partially configured, this THROWS during bootstrap rather than leaving a misleading refusal.
    LoadLiveMailboxPolicyFromEnv();
}

export { SyncActivitiesAction, LoadSyncActivitiesAction } from './custom/sync-activities.action.js';
export { LogActivityAction, LoadLogActivityAction } from './custom/log-activity.action.js';
export { GraphTransportFactory, LoadGraphTransportFactory } from './custom/graph-transport-factory.js';
export {
    LoadLiveMailboxPolicyFromEnv,
    ENV_GROUP,
    ENV_CONFIRMED_BY,
    ENV_CONFIRMED_AT,
} from './custom/live-mailbox-policy.js';
