/**
 * Values that reach ExtraFilter. ExtraFilter is a string, not parameters.
 *
 * IDs: reject anything that is not a UUID. Addresses and other free text:
 * coerce, drop NULs, double single quotes. A malformed id must not become a
 * widened result set.
 */

const UUID =
    /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

export class InvalidFilterInputError extends Error {
    constructor(message: string) {
        super(message);
        this.name = 'InvalidFilterInputError';
    }
}

export function RequireUUID(value: string, field: string): string {
    if (typeof value !== 'string' || !UUID.test(value)) {
        throw new InvalidFilterInputError(`${field} must be a UUID.`);
    }
    return value;
}

export function RequireUUIDs(values: readonly unknown[] | null | undefined, field: string): string[] {
    if (!values?.length) return [];
    return values.map((v) => {
        if (typeof v !== 'string') {
            throw new InvalidFilterInputError(`${field} must be a UUID.`);
        }
        return RequireUUID(v, field);
    });
}

/** Free text for a SQL string literal (addresses, type codes, external ids). */
export function EscapeText(value: unknown): string {
    return String(value ?? '')
        .replace(/\0/g, '')
        .replace(/'/g, "''");
}

export function InList(values: readonly unknown[]): string {
    if (values.length === 0) {
        return `'00000000-0000-0000-0000-000000000000'`;
    }
    return values.map((v) => `'${EscapeText(v)}'`).join(',');
}

export function UuidInList(values: readonly unknown[], field: string): string {
    const ids = RequireUUIDs(values, field);
    if (ids.length === 0) {
        return `'00000000-0000-0000-0000-000000000000'`;
    }
    return ids.map((id) => `'${id}'`).join(',');
}
