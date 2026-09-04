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
export * from './participants.js';
export * from './attachments.js';
export * from './run.js';
export * from './BaseActivitySyncProvider.js';
export * from './BaseActivitySyncExtension.js';
export * from './entity-names.js';
export * from './identity.js';
export * from './writer.js';
export * from './manual-log.js';
export * from './stages.js';
export * from './ActivitySyncEngine.js';
export * from './action-result.js';
export * from './extensions.js';
export * from './providers/FixtureActivitySyncProvider.js';
export * from './providers/MSGraphActivitySyncProvider.js';
export * from './providers/MSGraphCalendarSyncProvider.js';
export * from './providers/GraphMessageMapper.js';
export * from './providers/MessageTransport.js';
export * from './providers/GraphCommunicationTransport.js';
export * from './providers/GraphCalendarTransport.js';
export * from './providers/RecordedMessageTransport.js';
