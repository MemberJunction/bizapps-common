import { describe, expect, it } from 'vitest';
import { PARTY_LOOKUP_QUERIES, PartyLookupParamsFor } from '../party-lookup-term';

describe('PartyLookupParamsFor', () => {
    it('sends nothing under two non-blank characters', () => {
        expect(PartyLookupParamsFor('Person', ' d ')).toBeNull();
        expect(PartyLookupParamsFor('Organization', '')).toBeNull();
    });

    it('sends a trimmed name term with no domain', () => {
        expect(PartyLookupParamsFor('Person', ' da ')).toEqual({ Term: 'da', Domain: null });
        expect(PartyLookupParamsFor('Organization', 'acme')).toEqual({ Term: 'acme', Domain: null });
    });

    it('treats a person term with @ or . as an email domain, without the leading @', () => {
        expect(PartyLookupParamsFor('Person', '@AQHA.com')).toEqual({ Term: '@AQHA.com', Domain: 'aqha.com' });
        expect(PartyLookupParamsFor('Person', 'dave.smith')).toEqual({ Term: 'dave.smith', Domain: 'dave.smith' });
    });

    it('normalizes an organization URL the way the WebsiteDomain column does', () => {
        expect(PartyLookupParamsFor('Organization', 'https://www.Acme.com/about')).toEqual({
            Term: 'https://www.Acme.com/about',
            Domain: 'acme.com',
        });
        expect(PartyLookupParamsFor('Organization', 'HTTP://acme.com')?.Domain).toBe('acme.com');
        expect(PartyLookupParamsFor('Organization', 'www.acme.com:8080')?.Domain).toBe('acme.com:8080');
    });

    it('only strips scheme, www and path from an organization term', () => {
        expect(PartyLookupParamsFor('Organization', 'acme@x.com')?.Domain).toBe('acme@x.com');
    });

    it('sends no domain when normalization leaves fewer than two characters', () => {
        expect(PartyLookupParamsFor('Organization', 'https://')).toEqual({ Term: 'https://', Domain: null });
        expect(PartyLookupParamsFor('Person', '@.')).toEqual({ Term: '@.', Domain: null });
    });

    it('names the common query for each kind', () => {
        expect(PARTY_LOOKUP_QUERIES.Person).toEqual({ QueryName: 'Common: Party Lookup People', CategoryPath: 'Common' });
        expect(PARTY_LOOKUP_QUERIES.Organization).toEqual({ QueryName: 'Common: Party Lookup Organizations', CategoryPath: 'Common' });
    });
});
