/**
 * In-stream extension dispatch — Sequence order, timeout, Skip vs Abort.
 *
 * Runs inside the Activity write transaction. Skip records the error and lets
 * the activity commit; Abort sets `Aborted` so the writer can roll the write
 * back. Stamps are always returned so LastError survives an Abort rollback.
 */
import { RequireUUID } from './sql.js';
import {
    type ActivityWriteContext,
    type BaseActivitySyncExtension,
} from './BaseActivitySyncExtension.js';

export interface ExtensionRegistration {
    ID: string;
    DriverClass: string;
    Sequence: number;
    FailurePolicy: 'Skip' | 'Abort';
    TimeoutMS: number;
    ActivitySyncConnectionID: string | null;
    ActivitySyncProviderTypeID: string | null;
}

export interface ExtensionStamp {
    ID: string;
    LastError: string | null;
}

export interface ExtensionRunResult {
    Aborted: boolean;
    Errors: number;
    Stamps: ExtensionStamp[];
}

/** Enabled rows that apply to this connection / provider type (null = global). */
export function ExtensionsExtraFilter(connectionID: string, providerTypeID: string | null): string {
    const conn = RequireUUID(connectionID, 'ActivitySyncConnectionID');
    const connClause = `(ActivitySyncConnectionID IS NULL OR ActivitySyncConnectionID = '${conn}')`;
    const typeClause = providerTypeID
        ? `(ActivitySyncProviderTypeID IS NULL OR ActivitySyncProviderTypeID = '${RequireUUID(providerTypeID, 'ActivitySyncProviderTypeID')}')`
        : 'ActivitySyncProviderTypeID IS NULL';
    return `IsEnabled = 1 AND ${connClause} AND ${typeClause}`;
}

/**
 * Race `work` against TimeoutMS. This REJECTS THE WAITER; it does not cancel `work`.
 *
 * Pass an AbortController so Enrich can see `context.Signal.aborted` and stop. Work that
 * ignores the signal keeps running inside the open write transaction.
 */
export async function WithTimeout<T>(
    work: Promise<T>,
    timeoutMS: number,
    label: string,
    controller?: AbortController,
): Promise<T> {
    let timer: ReturnType<typeof setTimeout> | undefined;
    const timeout = new Promise<never>((_, reject) => {
        timer = setTimeout(() => {
            controller?.abort();
            reject(new Error(`${label} timed out after ${timeoutMS}ms`));
        }, timeoutMS);
    });
    try {
        return await Promise.race([work, timeout]);
    } finally {
        if (timer) clearTimeout(timer);
    }
}

/**
 * Run registered extensions in Sequence order.
 *
 * A missing DriverClass is a failure of that row, not a skip of the rest.
 * Stamps are returned so LastError / LastRunAt persist OUTSIDE the activity
 * transaction — an Abort rollback must not also erase the error that caused it.
 */
export async function RunRegisteredExtensions(
    context: ActivityWriteContext,
    rows: readonly ExtensionRegistration[],
    create: (driverClass: string) => BaseActivitySyncExtension | null,
): Promise<ExtensionRunResult> {
    const ordered = [...rows].sort((a, b) => a.Sequence - b.Sequence);
    const result: ExtensionRunResult = { Aborted: false, Errors: 0, Stamps: [] };

    for (const row of ordered) {
        const instance = create(row.DriverClass);
        if (!instance) {
            const message = `No BaseActivitySyncExtension registered for DriverClass '${row.DriverClass}'.`;
            result.Errors++;
            result.Stamps.push({ ID: row.ID, LastError: message });
            if (row.FailurePolicy === 'Abort') {
                result.Aborted = true;
                return result;
            }
            continue;
        }

        const controller = new AbortController();
        const timed: ActivityWriteContext = { ...context, Signal: controller.signal };
        try {
            await WithTimeout(instance.Enrich(timed), row.TimeoutMS, row.DriverClass, controller);
            result.Stamps.push({ ID: row.ID, LastError: null });
        } catch (err) {
            const message = err instanceof Error ? err.message : String(err);
            result.Errors++;
            result.Stamps.push({ ID: row.ID, LastError: message });
            if (row.FailurePolicy === 'Abort') {
                result.Aborted = true;
                return result;
            }
        }
    }

    return result;
}
