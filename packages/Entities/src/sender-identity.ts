/**
 * Company sender identities: which From addresses a Company may send mail as.
 *
 * This module is pure (no I/O, no database) so verticals, the entity subclass and the Angular
 * widget share one definition of "normalised" and "allowed". Every comparison lower-cases and
 * trims both sides, so a stored row and a caller-supplied address meet on the same form.
 *
 * `SenderDomain` differs on purpose from Caliber's helper of the same name: when the input has no
 * `@` it returns null instead of echoing the whole string. A bare domain such as `acme.com` is not
 * a sender address, and echoing it would let a Mailbox row or Domain row wrongly authorise it.
 *
 * `CompanyID` values are compared with `UUIDsEqual`: SQL Server returns upper-case UUIDs and
 * PostgreSQL lower-case, so a plain `===` breaks when the database changes.
 */

import { UUIDsEqual } from '@memberjunction/global';

export type SenderIdentityKind = 'Mailbox' | 'Domain';

export interface CompanySenderIdentityRow {
    readonly CompanyID: string;
    readonly Kind: SenderIdentityKind;
    readonly Address: string;
    readonly DisplayName: string | null;
    readonly IsDefault: boolean;
}

export interface SenderFrom {
    readonly from: string;
    readonly fromName: string | null;
}

/** Result of `NormalizeSenderIdentity`. `errors` is empty when the value is acceptable. */
export interface NormalizedSenderIdentity {
    readonly address: string;
    readonly displayName: string | null;
    /** Every error, address and display-name alike. */
    readonly errors: readonly string[];
    /** The subset of `errors` caused by the display name, so a form can mark the right field. */
    readonly displayNameErrors: readonly string[];
}

/** The one place an address is trimmed and lower-cased. */
function normalizeAddress(raw: string): string {
    return raw.trim().toLowerCase();
}

/** At least one `.`, non-empty labels on both sides of every dot, no whitespace. */
function isDottedDomain(domain: string): boolean {
    if (/\s/.test(domain)) return false;
    const labels = domain.split('.');
    return labels.length >= 2 && labels.every((label) => label.length > 0);
}

/** The lower-cased part after the last `@`, or null when the address has no `@`. */
export function SenderDomain(address: string): string | null {
    const normalized = normalizeAddress(address);
    const at = normalized.lastIndexOf('@');
    return at < 0 ? null : normalized.slice(at + 1);
}

/**
 * True when `address` matches a Mailbox row exactly, or its domain equals a Domain row exactly
 * (a subdomain does not match), among the rows of `companyId`. A bare domain or a malformed address
 * (empty local part, whitespace, undotted domain) is never allowed.
 */
export function IsSenderAllowedForCompany(
    companyId: string,
    address: string,
    identities: readonly CompanySenderIdentityRow[],
): boolean {
    const normalized = normalizeAddress(address);
    const domain = SenderDomain(normalized);
    if (domain === null || addressErrors('Mailbox', normalized, address).length > 0) return false;
    return identities.some((row) => {
        if (!UUIDsEqual(row.CompanyID, companyId)) return false;
        const stored = normalizeAddress(row.Address);
        return row.Kind === 'Mailbox' ? stored === normalized : stored === domain;
    });
}

/** The company's default Mailbox as a From pair, or null when it has none (a default Domain row does not count). */
export function DefaultSenderForCompany(
    companyId: string,
    identities: readonly CompanySenderIdentityRow[],
): SenderFrom | null {
    const row = identities.find((r) => UUIDsEqual(r.CompanyID, companyId) && r.Kind === 'Mailbox' && r.IsDefault);
    if (!row) return null;
    return { from: normalizeAddress(row.Address), fromName: row.DisplayName };
}

function addressErrors(kind: SenderIdentityKind, address: string, raw: string): string[] {
    if (address.length === 0) return [`${kind} address is empty (got "${raw}")`];
    if (kind === 'Domain') {
        if (address.includes('@')) return [`Domain "${address}" must not contain "@"`];
        return isDottedDomain(address) ? [] : [`Domain "${address}" must be a dotted domain such as example.com`];
    }
    const parts = address.split('@');
    const valid = parts.length === 2 && parts[0].length > 0 && !/\s/.test(parts[0]) && isDottedDomain(parts[1]);
    return valid ? [] : [`Mailbox "${address}" must look like name@example.com`];
}

/** Trim + lower-case the address and check its shape for the kind. Every error names the offending value. */
export function NormalizeSenderIdentity(
    kind: SenderIdentityKind,
    address: string,
    displayName: string | null,
): NormalizedSenderIdentity {
    const normalized = normalizeAddress(address);
    const name = displayName?.trim() ? displayName.trim() : null;
    const addressProblems = addressErrors(kind, normalized, address);
    const displayNameProblems =
        kind === 'Domain' && name !== null ? [`Domain "${normalized}" must not have a display name ("${name}")`] : [];
    return {
        address: normalized,
        displayName: name,
        errors: [...addressProblems, ...displayNameProblems],
        displayNameErrors: displayNameProblems,
    };
}
