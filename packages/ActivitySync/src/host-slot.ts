/**
 * @fileoverview One process-wide slot for a host registration.
 *
 * The registries in this package — transport factory, file sink, content cipher, live-mailbox
 * attestation — used to hold their value in a module-scoped `let`. That is per COPY of this package,
 * not per process. A host that resolves two copies (two consumers disagreeing on a version, npm
 * nesting one under the other) would register into one copy and read from the other, and the engine
 * would see nothing registered. None has fragmented yet only because every consumer takes a caret
 * range, which dedupes; one exact pin anywhere would recreate it (bc-aidp-next-golive#258).
 *
 * The slot lives in MJ's global object store, so every copy reads and writes the same one. Same
 * shape as MJ's own field-transform registry, which is kept there for the same reason.
 *
 * @module @mj-biz-apps/common-activity-sync
 */

import { GetGlobalObjectStore } from '@memberjunction/global';

export interface HostSlot<T> {
    Get(): T | null;
    Set(value: T | null): void;
}

/**
 * A slot keyed on `key` in the global object store.
 *
 * The key is the identity: two copies of this package agree on it and nothing else, so it must never
 * change between versions a host could load side by side.
 */
export function HostSlot<T>(key: string): HostSlot<T> {
    const store = () => (GetGlobalObjectStore() ?? globalThis) as unknown as Record<string, unknown>;
    return {
        Get: () => (store()[key] as T | null | undefined) ?? null,
        Set: (value) => {
            store()[key] = value;
        },
    };
}
