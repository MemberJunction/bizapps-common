import { describe, expect, it } from 'vitest';
import { CandidateFilter, MatchOrganizations, PolicyAllowsCreate, type OrganizationCandidate } from '../organization-resolver.js';
import type { EnrichedEmployment } from '../types.js';

const candidates: OrganizationCandidate[] = [
    { ID: 'A', Name: 'Acme Corporation', LegalName: 'Acme Corp.', Website: 'https://www.acme.com/' },
    { ID: 'B', Name: 'Acme Holdings', LegalName: null, Website: 'http://acme.com/holdings' },
    { ID: 'C', Name: 'The Globex Company', LegalName: null, Website: null },
];

function job(name: string, domain: string | null): EnrichedEmployment {
    return { OrganizationName: name, OrganizationDomain: domain, Title: null, StartDate: null, EndDate: null, IsCurrent: true };
}

describe('MatchOrganizations', () => {
    it('matches by exact normalized name or legal name when there is no domain', () => {
        const resolved = MatchOrganizations([job('globex company', null), job('ACME CORP', null)], candidates);
        expect(resolved.ByEntry[0]).toMatchObject({ ID: 'C' });
        expect(resolved.ByEntry[1]).toMatchObject({ ID: 'A' });
    });
    it('treats more than one match as unresolved, never a random pick', () => {
        const resolved = MatchOrganizations([job('Acme', 'acme.com')], candidates);
        expect(resolved.ByEntry[0]).toBeNull();
        expect(resolved.Ambiguous).toBe(1);
    });
    it('returns a creatable ref when nothing matches', () => {
        const resolved = MatchOrganizations([job('Initech', 'initech.example')], candidates);
        expect(resolved.ByEntry[0]).toEqual({ ID: null, Name: 'Initech', Website: 'https://initech.example' });
    });
    it('prefers the domain over the name', () => {
        const only = [candidates[0], candidates[2]];
        expect(MatchOrganizations([job('Something Else', 'ACME.com')], only).ByEntry[0]).toMatchObject({ ID: 'A' });
    });
});

describe('CandidateFilter', () => {
    it('escapes names and searches domains inside Website', () => {
        expect(CandidateFilter([job("O'Reilly", 'oreilly.com'), job('', null)])).toBe(`Name IN ('O''Reilly') OR LegalName IN ('O''Reilly') OR Website LIKE '%oreilly.com%'`);
        expect(CandidateFilter([job(' ', null)])).toBeNull();
    });
});

describe('PolicyAllowsCreate', () => {
    it('follows the matrix', () => {
        expect(PolicyAllowsCreate('Never', true)).toBe(false);
        expect(PolicyAllowsCreate('CurrentEmployerOnly', true)).toBe(true);
        expect(PolicyAllowsCreate('CurrentEmployerOnly', false)).toBe(false);
        expect(PolicyAllowsCreate('AllEmployers', false)).toBe(true);
    });
});
