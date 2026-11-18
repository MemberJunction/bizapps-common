import { describe, expect, it } from 'vitest';
import {
    AddressesMatch,
    FindMatchingLinkedAddress,
    HasMinimumAddressContent,
    LinksToDemoteFromPrimary,
    NormalizeAddressFields,
    ResolveAddressType,
    ResolveDefaultIsPrimary,
    type AddressTypeCandidate,
    type LinkedAddressPair,
} from '../address-link-rules.js';

describe('NormalizeAddressFields', () => {
    it('trims text fields, converts blank strings to null, and defaults Country to US', () => {
        expect(
            NormalizeAddressFields({
                Line1: '  100 Main St  ',
                Line2: '   ',
                Line3: undefined,
                City: ' Austin ',
                StateProvince: ' TX ',
                PostalCode: ' 78701 ',
                Country: '  ',
                Latitude: 30.2672,
                Longitude: -97.7431,
            }),
        ).toEqual({
            Line1: '100 Main St',
            Line2: null,
            Line3: null,
            City: 'Austin',
            StateProvince: 'TX',
            PostalCode: '78701',
            Country: 'US',
            Latitude: 30.2672,
            Longitude: -97.7431,
        });
    });

    it('preserves an explicit non-blank Country and filters out non-finite coordinates', () => {
        expect(
            NormalizeAddressFields({
                Line1: '10 Downing St',
                City: 'London',
                Country: ' GB ',
                Latitude: Number.NaN,
                Longitude: Number.POSITIVE_INFINITY,
            }),
        ).toEqual({
            Line1: '10 Downing St',
            Line2: null,
            Line3: null,
            City: 'London',
            StateProvince: null,
            PostalCode: null,
            Country: 'GB',
            Latitude: null,
            Longitude: null,
        });
    });
});

describe('HasMinimumAddressContent', () => {
    it('returns true when any of Line1, City, StateProvince, or PostalCode is non-blank', () => {
        expect(HasMinimumAddressContent({ Line1: '100 Main St' })).toBe(true);
        expect(HasMinimumAddressContent({ City: 'Austin' })).toBe(true);
        expect(HasMinimumAddressContent({ StateProvince: 'TX' })).toBe(true);
        expect(HasMinimumAddressContent({ PostalCode: '78701' })).toBe(true);
    });

    it('returns true when both Latitude and Longitude are finite numbers', () => {
        expect(HasMinimumAddressContent({ Latitude: 0, Longitude: 0 })).toBe(true);
        expect(HasMinimumAddressContent({ Latitude: 30.2672, Longitude: null })).toBe(false);
        expect(HasMinimumAddressContent({ Latitude: null, Longitude: -97.7431 })).toBe(false);
    });

    it('returns false when only Country, Line2, or whitespace is supplied', () => {
        expect(HasMinimumAddressContent({})).toBe(false);
        expect(HasMinimumAddressContent({ Line1: '   ', City: '', Country: 'CA' })).toBe(false);
        expect(HasMinimumAddressContent({ Line2: 'Suite 200' })).toBe(false);
    });
});

describe('AddressesMatch and FindMatchingLinkedAddress', () => {
    it('matches addresses case-insensitively after trimming and applying default Country', () => {
        expect(
            AddressesMatch(
                { Line1: '100 Main St', Line2: null, City: 'Austin', StateProvince: 'TX', PostalCode: '78701' },
                { Line1: ' 100 MAIN ST ', Line2: '  ', City: 'austin', StateProvince: 'tx', PostalCode: '78701', Country: 'us' },
            ),
        ).toBe(true);
    });

    it('distinguishes addresses that differ on any normalized field', () => {
        expect(
            AddressesMatch(
                { Line1: '100 Main St', Line2: 'Apt 1', City: 'Austin', StateProvince: 'TX', PostalCode: '78701' },
                { Line1: '100 Main St', Line2: 'Apt 2', City: 'Austin', StateProvince: 'TX', PostalCode: '78701' },
            ),
        ).toBe(false);
    });

    it('finds the first matching linked address pair on the same record, or null when none match', () => {
        const pairs: LinkedAddressPair[] = [
            {
                Link: { ID: 'link-1', AddressID: 'addr-1', AddressTypeID: 'type-home', IsPrimary: true },
                Address: { Line1: '100 Main St', City: 'Austin', StateProvince: 'TX', PostalCode: '78701', Country: 'US' },
            },
            {
                Link: { ID: 'link-2', AddressID: 'addr-2', AddressTypeID: 'type-work', IsPrimary: true },
                Address: { Line1: '200 Congress Ave', City: 'Austin', StateProvince: 'TX', PostalCode: '78701', Country: 'US' },
            },
        ];

        const hit = FindMatchingLinkedAddress(pairs, {
            Line1: '200 congress ave',
            City: 'Austin',
            StateProvince: 'TX',
            PostalCode: '78701',
        });
        expect(hit?.Link.ID).toBe('link-2');
        expect(hit?.Address).toBe(pairs[1].Address);

        const miss = FindMatchingLinkedAddress(pairs, {
            Line1: '300 Lavaca St',
            City: 'Austin',
            StateProvince: 'TX',
            PostalCode: '78701',
        });
        expect(miss).toBeNull();
    });
});

describe('ResolveAddressType', () => {
    const types: AddressTypeCandidate[] = [
        { ID: '11111111-1111-1111-1111-111111111111', Name: 'Work', DefaultRank: 20, IsActive: true },
        { ID: '22222222-2222-2222-2222-222222222222', Name: 'Home', DefaultRank: 10, IsActive: true },
        { ID: '33333333-3333-3333-3333-333333333333', Name: 'Archived', DefaultRank: 1, IsActive: false },
    ];

    it('defaults to the lowest-rank active type when requested is omitted or blank', () => {
        expect(ResolveAddressType(types)?.Name).toBe('Home');
        expect(ResolveAddressType(types, '   ')?.Name).toBe('Home');
    });

    it('matches an explicit active type by UUID (case-insensitively) or Name', () => {
        expect(ResolveAddressType(types, '11111111-1111-1111-1111-111111111111')?.Name).toBe('Work');
        expect(ResolveAddressType(types, '  work ')?.ID).toBe('11111111-1111-1111-1111-111111111111');
    });

    it('returns null when requested does not match an active type or no active types exist', () => {
        expect(ResolveAddressType(types, '33333333-3333-3333-3333-333333333333')).toBeNull();
        expect(ResolveAddressType(types, 'Billing')).toBeNull();
        expect(ResolveAddressType([{ ID: 'x', Name: 'Inactive', IsActive: false }])).toBeNull();
    });
});

describe('ResolveDefaultIsPrimary and LinksToDemoteFromPrimary', () => {
    const TYPE_HOME = '22222222-2222-2222-2222-222222222222';
    const TYPE_WORK = '11111111-1111-1111-1111-111111111111';

    it('marks the first link on a record or the first link of a given type as primary by default', () => {
        expect(ResolveDefaultIsPrimary([], TYPE_HOME)).toBe(true);
        expect(
            ResolveDefaultIsPrimary([{ AddressTypeID: TYPE_HOME, IsPrimary: true }], TYPE_WORK),
        ).toBe(true);
        expect(
            ResolveDefaultIsPrimary([{ AddressTypeID: TYPE_HOME, IsPrimary: true }], TYPE_HOME),
        ).toBe(false);
    });

    it('honors an explicit boolean IsPrimary override in either direction', () => {
        expect(ResolveDefaultIsPrimary([], TYPE_HOME, false)).toBe(false);
        expect(
            ResolveDefaultIsPrimary([{ AddressTypeID: TYPE_HOME, IsPrimary: true }], TYPE_HOME, true),
        ).toBe(true);
    });

    it('returns all other primary links to demote when a link becomes primary', () => {
        const existing = [
            { ID: 'AAAA0000-0000-0000-0000-000000000001', IsPrimary: true },
            { ID: 'AAAA0000-0000-0000-0000-000000000002', IsPrimary: false },
            { ID: 'AAAA0000-0000-0000-0000-000000000003', IsPrimary: true },
        ];
        expect(
            LinksToDemoteFromPrimary(existing, 'aaaa0000-0000-0000-0000-000000000001').map((l) => l.ID),
        ).toEqual(['AAAA0000-0000-0000-0000-000000000003']);
        expect(LinksToDemoteFromPrimary(existing, null).map((l) => l.ID)).toEqual([
            'AAAA0000-0000-0000-0000-000000000001',
            'AAAA0000-0000-0000-0000-000000000003',
        ]);
    });
});
