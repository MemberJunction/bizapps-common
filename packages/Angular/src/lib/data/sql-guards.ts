/**
 * Guards for values interpolated into RunView `ExtraFilter` strings.
 *
 * `ExtraFilter` is raw SQL appended to the server's WHERE clause — not a
 * parameterized query — so every interpolated value must be shape-validated
 * (identifiers) or escaped (free text; see `EscapeFilterValue` /
 * `EscapeLikeValue` in `directory-stats.ts`). These components ship in a
 * published library, so an `@Input()` ID may be bound by a consuming app to a
 * route or query parameter: a malformed id must fail closed, never widen the
 * result set.
 *
 * Mirrors the server-side guards in `packages/ActivitySync/src/sql.ts`
 * (duplicated rather than imported — no cross-package re-exports).
 */

const UUID =
    /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

export class InvalidFilterInputError extends Error {
    constructor(message: string) {
        super(message);
        this.name = 'InvalidFilterInputError';
    }
}

/** Throwing guard: use inside load paths that already fail closed via try/catch. */
export function RequireUUID(value: string | null | undefined, field: string): string {
    if (typeof value !== 'string' || !UUID.test(value)) {
        throw new InvalidFilterInputError(`${field} must be a UUID.`);
    }
    return value;
}

/** Non-throwing guard: use in getters/templates where a throw would break rendering. */
export function SafeUUID(value: string | null | undefined): string | null {
    return typeof value === 'string' && UUID.test(value) ? value : null;
}
