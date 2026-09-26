import { describe, expect, it } from 'vitest';
import { CompositeKey } from '@memberjunction/core';
import { AddressReference, otherAddressReferences } from '../address-references';

const LINK_ID = '7F3A2C1E-0000-4000-8000-000000000001';
const OTHER_LINK_ID = '7F3A2C1E-0000-4000-8000-000000000002';

/** Server-provider shape: the dependent record's key is a CompositeKey in `PrimaryKey`. */
const serverRef = (entity: string, field: string, id: string): AddressReference => ({
    RelatedEntityName: entity,
    FieldName: field,
    PrimaryKey: new CompositeKey([{ FieldName: 'ID', Value: id }]),
});

/** GraphQL-client shape: the same key arrives as a plain object under `CompositeKey`. */
const clientRef = (entity: string, field: string, id: string): AddressReference => ({
    RelatedEntityName: entity,
    FieldName: field,
    CompositeKey: { KeyValuePairs: [{ FieldName: 'ID', Value: id }] },
});

describe('otherAddressReferences', () => {
    it('is empty when the only reference is the link being removed', () => {
        expect(otherAddressReferences([serverRef('MJ_BizApps_Common: Address Links', 'AddressID', LINK_ID)], LINK_ID)).toEqual([]);
    });

    it('recognises the removed link in the GraphQL client shape', () => {
        expect(otherAddressReferences([clientRef('MJ_BizApps_Common: Address Links', 'AddressID', LINK_ID)], LINK_ID)).toEqual([]);
    });

    it('matches the link ID regardless of GUID casing', () => {
        expect(otherAddressReferences([clientRef('MJ_BizApps_Common: Address Links', 'AddressID', LINK_ID.toLowerCase())], LINK_ID)).toEqual([]);
    });

    it('keeps another party\'s link to the same address', () => {
        const other = clientRef('MJ_BizApps_Common: Address Links', 'AddressID', OTHER_LINK_ID);
        const refs = [clientRef('MJ_BizApps_Common: Address Links', 'AddressID', LINK_ID), other];
        expect(otherAddressReferences(refs, LINK_ID)).toEqual([other]);
    });

    it('keeps a direct reference from another entity, even when its ID equals the link ID', () => {
        const order = clientRef('MJ_BizApps_Orders: Order Headers', 'ShipToAddressID', LINK_ID);
        expect(otherAddressReferences([order], LINK_ID)).toEqual([order]);
    });

    it('is empty when there are no references', () => {
        expect(otherAddressReferences([], LINK_ID)).toEqual([]);
    });
});
