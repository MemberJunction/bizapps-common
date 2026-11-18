import { CompositeKey, KeyValuePair, RecordDependency } from '@memberjunction/core';
import { UUIDsEqual } from '@memberjunction/global';

/** Entity name of the link table that ties an Address to a party record. */
export const ADDRESS_LINK_ENTITY = 'MJ_BizApps_Common: Address Links';

/**
 * A {@link RecordDependency} as it arrives on either side of the wire. Server-side providers put
 * the dependent record's key in `PrimaryKey`; the GraphQL resolver returns the same key under
 * `CompositeKey`, which the client provider passes through unchanged.
 */
export type AddressReference = Pick<RecordDependency, 'RelatedEntityName' | 'FieldName'> & {
    PrimaryKey?: CompositeKey;
    CompositeKey?: { KeyValuePairs: KeyValuePair[] };
};

/**
 * Returns the references to an Address other than the AddressLink being removed.
 *
 * An Address row can be linked to several parties and referenced directly by other apps
 * (order bill-to/ship-to, activity locations), so removing one link does not make it an
 * orphan. When this returns an empty list, the Address can be deleted with the link.
 *
 * Only relationships declared in metadata are reported; a column with no foreign key or
 * soft-link declaration is invisible to `GetRecordDependencies`.
 *
 * @param references - Result of `GetRecordDependencies` for the Address
 * @param removedLinkID - ID of the AddressLink being deleted
 */
export function otherAddressReferences(references: AddressReference[], removedLinkID: string): AddressReference[] {
    return references.filter(ref => !isRemovedLink(ref, removedLinkID));
}

function isRemovedLink(ref: AddressReference, removedLinkID: string): boolean {
    if (ref.RelatedEntityName?.trim().toLowerCase() !== ADDRESS_LINK_ENTITY.toLowerCase()) return false;
    const pairs = (ref.PrimaryKey ?? ref.CompositeKey)?.KeyValuePairs ?? [];
    const id = pairs.find(p => p.FieldName.toLowerCase() === 'id')?.Value;
    return id != null && UUIDsEqual(String(id), removedLinkID);
}
