/**
 * @mj-biz-apps/common-core-entities-server
 *
 * Server-side entity subclasses for BizApps Common entities.
 * These classes override Save() and Delete() to add lifecycle hooks
 * (User auto-linking, default role assignment, etc.) that only run on the server.
 *
 * Import this package from your server bootstrap to ensure @RegisterClass
 * decorators fire at startup.
 */

export { PersonEntityServer } from './PersonEntityServer.js';
