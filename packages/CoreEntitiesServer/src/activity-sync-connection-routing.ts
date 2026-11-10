/**
 * Which Activity Sync Connection columns decide whose mail and calendar the sync reads (#392).
 *
 * The Microsoft 365 credential behind a connection is usually an app-only grant that can read
 * every mailbox in the tenant, and the `Mailbox` column only narrows what the sync ASKS for. So
 * whoever may change these columns can point the hourly sync at any mailbox, or make themselves
 * the connection owner and read the Private activities it ingests. These are the columns only an
 * administrator may set.
 *
 * Pure functions, so the rule is unit-tested without a database.
 *
 * @module @mj-biz-apps/common-core-entities-server
 */
import { UUIDsEqual } from '@memberjunction/global';
import type { mjBizAppsCommonActivitySyncConnectionEntityType } from '@mj-biz-apps/common-entities';
import { NormalizeStored, type StoredValues } from './entity-guards.js';

type ConnectionField = keyof mjBizAppsCommonActivitySyncConnectionEntityType;

/** Text columns that route the sync: compared as trimmed text. */
const ROUTING_TEXT_FIELDS: readonly ConnectionField[] = ['Mailbox', 'CredentialsRef', 'Provider'];

/** Foreign keys that route the sync or decide who owns what it ingests: compared as UUIDs. */
const ROUTING_ID_FIELDS: readonly ConnectionField[] = ['OwnerUserID', 'ActivitySyncProviderTypeID'];

/** Every column the routing rule reads, for the stored-row query. */
export const CONNECTION_ROUTING_FIELDS: readonly ConnectionField[] = [
    ...ROUTING_TEXT_FIELDS,
    ...ROUTING_ID_FIELDS,
    'Settings',
];

/**
 * The calendar watermark the sync engine writes into `Settings` after each calendar run
 * (`CALENDAR_WATERMARK_SETTING` in `@mj-biz-apps/common-activity-sync`). It is the only part of
 * `Settings` an ordinary save may change. Repeated here rather than imported because this package
 * does not depend on Activity Sync; a unit test pins the two together.
 */
export const CALENDAR_WATERMARK_KEY = 'CalendarLastSyncAt';

/** `Settings` with the calendar watermark removed, as stable text for comparison. */
export function SettingsWithoutWatermark(settings: unknown): string | null {
    const text = NormalizeStored(settings);
    if (text === null) return null;
    let parsed: unknown;
    try {
        parsed = JSON.parse(text);
    } catch {
        // Not JSON: compare the raw text, so any edit to it counts as a change.
        return text;
    }
    if (parsed === null || typeof parsed !== 'object' || Array.isArray(parsed)) return text;
    const bag: Record<string, unknown> = { ...(parsed as Record<string, unknown>) };
    delete bag[CALENDAR_WATERMARK_KEY];
    const keys = Object.keys(bag).sort();
    return keys.length === 0 ? null : JSON.stringify(bag, keys);
}

function sameID(a: unknown, b: unknown): boolean {
    const left = NormalizeStored(a);
    const right = NormalizeStored(b);
    if (left === null || right === null) return left === right;
    return UUIDsEqual(left, right);
}

/**
 * The routing columns whose value about to be saved differs from the stored row. `current` and
 * `stored` are keyed by field name. An empty list means the save leaves routing alone.
 */
export function ChangedRoutingFields(current: StoredValues, stored: StoredValues): string[] {
    const changed: string[] = [];
    for (const field of ROUTING_TEXT_FIELDS) {
        if (NormalizeStored(current[field]) !== NormalizeStored(stored[field])) changed.push(field);
    }
    for (const field of ROUTING_ID_FIELDS) {
        if (!sameID(current[field], stored[field])) changed.push(field);
    }
    if (SettingsWithoutWatermark(current.Settings) !== SettingsWithoutWatermark(stored.Settings)) {
        changed.push('Settings');
    }
    return changed;
}
