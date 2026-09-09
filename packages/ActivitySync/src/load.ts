/**
 * RunView results. A failed read is not an empty list — those two look the same
 * and only one may advance a watermark or decide an exclusion.
 */
import { RequireUUID, UuidInList } from './sql.js';

export type ViewLoad<T> = { Failed: true; Issue: string } | { Failed: false; Rows: T[] };

export function FromRunView<T>(
    success: boolean,
    results: readonly T[] | null | undefined,
    what: string,
): ViewLoad<T> {
    if (!success) return { Failed: true, Issue: `${what} lookup failed.` };
    return { Failed: false, Rows: [...(results ?? [])] };
}

/** Global exclusions plus those bound to the connection's rule sets. */
export function ExclusionsExtraFilter(setIds: readonly string[]): string {
    const global = 'ActivitySyncRuleSetID IS NULL';
    if (setIds.length === 0) return global;
    return `(${global} OR ActivitySyncRuleSetID IN (${UuidInList(setIds, 'ActivitySyncRuleSetID')}))`;
}

/**
 * Bound rule-set ids on success. Empty ids fall through to the deprecated
 * connection-owned rules. A failed binding read must not take that fallthrough —
 * that would load the wrong rules.
 */
export function RulesExtraFilter(setIds: readonly string[], connectionID: string): string {
    if (setIds.length > 0) {
        return `ActivitySyncRuleSetID IN (${UuidInList(setIds, 'ActivitySyncRuleSetID')})`;
    }
    return `ActivitySyncConnectionID = '${RequireUUID(connectionID, 'ActivitySyncConnectionID')}'`;
}
