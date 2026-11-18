import { UUIDsEqual } from '@memberjunction/global';

/**
 * Raw address fields accepted by the address editor and the `Common.AttachAddress` action.
 */
export interface AddressFieldsInput {
    Line1?: string | null;
    Line2?: string | null;
    Line3?: string | null;
    City?: string | null;
    StateProvince?: string | null;
    PostalCode?: string | null;
    Country?: string | null;
    Latitude?: number | null;
    Longitude?: number | null;
}

/**
 * Trimmed, storage-ready address fields (`Country` defaults to `'US'`, optional blank strings become `null`).
 */
export interface NormalizedAddressFields {
    Line1: string | null;
    Line2: string | null;
    Line3: string | null;
    City: string | null;
    StateProvince: string | null;
    PostalCode: string | null;
    Country: string;
    Latitude: number | null;
    Longitude: number | null;
}

export interface LinkedAddressPair<
    TLink extends { ID: string; AddressID: string; AddressTypeID: string; IsPrimary: boolean } = {
        ID: string;
        AddressID: string;
        AddressTypeID: string;
        IsPrimary: boolean;
    },
    TAddress extends AddressFieldsInput = AddressFieldsInput,
> {
    Link: TLink;
    Address: TAddress;
}

export interface AddressTypeCandidate {
    ID: string;
    Name: string;
    DefaultRank?: number | null;
    IsActive?: boolean | null;
}

function cleanText(value: string | null | undefined): string | null {
    if (typeof value !== 'string') return null;
    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed : null;
}

function cleanCoord(value: number | null | undefined): number | null {
    return typeof value === 'number' && Number.isFinite(value) ? value : null;
}

function foldCase(value: string | null): string {
    return (value ?? '').toLowerCase();
}

/**
 * Normalizes raw address fields for storage and deduplication.
 * Blank strings become `null`, and `Country` defaults to `'US'` when omitted or blank.
 */
export function NormalizeAddressFields(input: AddressFieldsInput): NormalizedAddressFields {
    return {
        Line1: cleanText(input.Line1),
        Line2: cleanText(input.Line2),
        Line3: cleanText(input.Line3),
        City: cleanText(input.City),
        StateProvince: cleanText(input.StateProvince),
        PostalCode: cleanText(input.PostalCode),
        Country: cleanText(input.Country) ?? 'US',
        Latitude: cleanCoord(input.Latitude),
        Longitude: cleanCoord(input.Longitude),
    };
}

/**
 * Returns `true` when the address has at least one meaningful location field
 * (`Line1`, `City`, `StateProvince`, `PostalCode`) or a complete `(Latitude, Longitude)` coordinate pair.
 */
export function HasMinimumAddressContent(input: AddressFieldsInput): boolean {
    const norm = NormalizeAddressFields(input);
    if (norm.Line1 || norm.City || norm.StateProvince || norm.PostalCode) {
        return true;
    }
    return norm.Latitude !== null && norm.Longitude !== null;
}

/**
 * Case-insensitively compares two addresses after trimming whitespace and applying the `'US'` country default.
 */
export function AddressesMatch(a: AddressFieldsInput, b: AddressFieldsInput): boolean {
    const left = NormalizeAddressFields(a);
    const right = NormalizeAddressFields(b);
    return (
        foldCase(left.Line1) === foldCase(right.Line1) &&
        foldCase(left.Line2) === foldCase(right.Line2) &&
        foldCase(left.Line3) === foldCase(right.Line3) &&
        foldCase(left.City) === foldCase(right.City) &&
        foldCase(left.StateProvince) === foldCase(right.StateProvince) &&
        foldCase(left.PostalCode) === foldCase(right.PostalCode) &&
        foldCase(left.Country) === foldCase(right.Country)
    );
}

/**
 * Finds an existing `(Link, Address)` pair on the same record whose normalized address fields match `candidate`.
 */
export function FindMatchingLinkedAddress<
    TLink extends { ID: string; AddressID: string; AddressTypeID: string; IsPrimary: boolean },
    TAddress extends AddressFieldsInput,
>(
    existing: readonly LinkedAddressPair<TLink, TAddress>[],
    candidate: AddressFieldsInput,
): LinkedAddressPair<TLink, TAddress> | null {
    for (const pair of existing) {
        if (AddressesMatch(pair.Address, candidate)) {
            return pair;
        }
    }
    return null;
}

/**
 * Resolves an `AddressType` from active types ordered by `DefaultRank ASC`.
 *
 * - When `requested` is omitted or blank, returns the lowest-rank active type.
 * - When `requested` is provided, matches by `ID` (`UUIDsEqual`) or case-insensitive `Name`.
 * - Returns `null` when an explicit `requested` value matches no active type, or when `types` has no active entries.
 */
export function ResolveAddressType<T extends AddressTypeCandidate>(
    types: readonly T[],
    requested?: string | null,
): T | null {
    const active = types
        .filter((t) => t.IsActive !== false)
        .slice()
        .sort((a, b) => (a.DefaultRank ?? Number.MAX_SAFE_INTEGER) - (b.DefaultRank ?? Number.MAX_SAFE_INTEGER));
    if (active.length === 0) {
        return null;
    }
    const trimmed = cleanText(requested);
    if (!trimmed) {
        return active[0];
    }
    const byId = active.find((t) => UUIDsEqual(t.ID, trimmed));
    if (byId) {
        return byId;
    }
    const lower = trimmed.toLowerCase();
    return active.find((t) => t.Name.trim().toLowerCase() === lower) ?? null;
}

/**
 * Determines whether a link should be marked `IsPrimary`.
 *
 * - Explicit boolean `explicitIsPrimary` wins when provided.
 * - Otherwise, returns `true` when the record has no existing links or no existing link of `addressTypeID`.
 */
export function ResolveDefaultIsPrimary(
    existingLinks: readonly { AddressTypeID: string; IsPrimary: boolean }[],
    addressTypeID: string,
    explicitIsPrimary?: boolean | null,
): boolean {
    if (typeof explicitIsPrimary === 'boolean') {
        return explicitIsPrimary;
    }
    if (existingLinks.length === 0) {
        return true;
    }
    const hasSameType = existingLinks.some((link) => UUIDsEqual(link.AddressTypeID, addressTypeID));
    return !hasSameType;
}

/**
 * Returns every link in `existingLinks` that is currently marked `IsPrimary` except `keepPrimaryLinkID`.
 */
export function LinksToDemoteFromPrimary<T extends { ID: string; IsPrimary: boolean }>(
    existingLinks: readonly T[],
    keepPrimaryLinkID: string | null,
): T[] {
    return existingLinks.filter(
        (link) => link.IsPrimary && (keepPrimaryLinkID === null || !UUIDsEqual(link.ID, keepPrimaryLinkID)),
    );
}
