/**
 * @mj-biz-apps/common-activity-sync
 *
 * Contracts for the Activity Sync Engine: the provider plugin base class, the qualification
 * cascade, and the in-process extension contract downstream apps implement to enrich an Activity
 * inside its own write transaction.
 *
 * Design: plans/activity-sync-engine.md
 */
export * from './types.js';
export * from './watermark.js';
export * from './qualification.js';
export * from './BaseActivitySyncProvider.js';
export * from './BaseActivitySyncExtension.js';
