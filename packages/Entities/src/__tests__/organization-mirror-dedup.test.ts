/**
 * Copyright (c) MemberJunction.com
 * SPDX-License-Identifier: BUSL-1.1
 */
import { describe, expect, it } from 'vitest';
import {
    BuildOrganizationMirrorLookupFilter,
    ChunkLookupValues,
    CompanyMirrorError,
    ExtractCompanyMatchKeys,
    NormalizeMirrorOptionalString,
    NormalizeMirrorWebsiteDomain,
    SelectOrganizationMirrorCandidate,
    type OrganizationLookupCandidate,
} from '../company-organization-mirror.js';

const COMPANY_ID = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const OTHER_COMPANY_ID = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const ORG_A = '11111111-1111-4111-8111-111111111111';
const ORG_B = '22222222-2222-4222-8222-222222222222';

describe('Company -> Organization mirror deduplication helpers', () => {
    it('normalizes optional strings and website domains consistently with Organization.WebsiteDomain', () => {
        expect(NormalizeMirrorOptionalString(undefined)).toBeNull();
        expect(NormalizeMirrorOptionalString('   ')).toBeNull();
        expect(NormalizeMirrorOptionalString('  Acme Corp  ')).toBe('Acme Corp');

        expect(NormalizeMirrorWebsiteDomain('HTTPS://WWW.Acme.com/about?ref=1')).toBe('acme.com');
        expect(NormalizeMirrorWebsiteDomain('http://portal.acme.com/login')).toBe('portal.acme.com');
        expect(NormalizeMirrorWebsiteDomain('www.acme.co.uk')).toBe('acme.co.uk');
        expect(NormalizeMirrorWebsiteDomain('not a domain')).toBeNull();
        expect(NormalizeMirrorWebsiteDomain('')).toBeNull();
    });

    it('extracts normalized match keys from Website and Domain and rejects invalid UUIDs or empty names', () => {
        const keys = ExtractCompanyMatchKeys({
            ID: COMPANY_ID,
            Name: '  Acme Holdings LLC  ',
            Website: 'https://www.acme.com/home',
            Domain: 'acme-corp.io',
        });

        expect(keys).toEqual({
            CompanyID: COMPANY_ID,
            NormalizedName: 'acme holdings llc',
            CandidateDomains: ['acme.com', 'acme-corp.io'],
        });

        expect(() =>
            ExtractCompanyMatchKeys({
                ID: 'not-a-uuid',
                Name: 'Acme',
            }),
        ).toThrowError(CompanyMirrorError);

        try {
            ExtractCompanyMatchKeys({
                ID: COMPANY_ID,
                Name: '   ',
            });
            expect.fail('Expected INVALID_COMPANY_DATA error');
        } catch (err) {
            expect(err).toBeInstanceOf(CompanyMirrorError);
            const mirrorErr = err as CompanyMirrorError;
            expect(mirrorErr.Code).toBe('INVALID_COMPANY_DATA');
            expect(mirrorErr.Context.CompanyID).toBe(COMPANY_ID);
        }
    });

    it('builds dual-dialect-safe ExtraFilter predicates without bracketed identifiers or proprietary functions', () => {
        const keys = ExtractCompanyMatchKeys({
            ID: COMPANY_ID,
            Name: "O'Reilly Media",
            Website: 'https://www.oreilly.com/catalog',
        });
        const filter = BuildOrganizationMirrorLookupFilter(keys);

        expect(filter).toContain(`LinkedCompanyID = '${COMPANY_ID}'`);
        expect(filter).toContain('LinkedCompanyID IS NULL');
        expect(filter).toContain("LOWER(Name) = 'o''reilly media'");
        expect(filter).toContain("LOWER(LegalName) = 'o''reilly media'");
        expect(filter).toContain("WebsiteDomain = 'oreilly.com'");
        expect(filter).not.toMatch(/[\[\]"]/);
        expect(filter).not.toMatch(/\b(ISNULL|CHARINDEX|ILIKE|TOP)\b/i);
    });

    it('rejects invalid CompanyID in BuildOrganizationMirrorLookupFilter with CompanyMirrorError', () => {
        expect(() =>
            BuildOrganizationMirrorLookupFilter({
                CompanyID: 'not-a-uuid',
                NormalizedName: 'acme corp',
                CandidateDomains: [],
            }),
        ).toThrowError(CompanyMirrorError);

        try {
            BuildOrganizationMirrorLookupFilter({
                CompanyID: "bad' OR '1'='1",
                NormalizedName: 'acme corp',
                CandidateDomains: [],
            });
            expect.fail('Expected INVALID_COMPANY_ID error');
        } catch (err) {
            expect(err).toBeInstanceOf(CompanyMirrorError);
            const mirrorErr = err as CompanyMirrorError;
            expect(mirrorErr.Code).toBe('INVALID_COMPANY_ID');
            expect(mirrorErr.Context.CompanyID).toBe("bad' OR '1'='1");
            expect(mirrorErr.Context.Operation).toBe('lookup');
        }
    });

    it('chunks large lookup value arrays into bounded batches', () => {
        expect(ChunkLookupValues(['a', 'b', 'c', 'd', 'e'], 2)).toEqual([['a', 'b'], ['c', 'd'], ['e']]);
        expect(ChunkLookupValues([], 10)).toEqual([]);
        expect(ChunkLookupValues(['only'], 0)).toEqual([['only']]);
    });

    it('prioritizes LinkedCompanyID matches over unlinked candidates for idempotent re-sync', () => {
        const keys = ExtractCompanyMatchKeys({
            ID: COMPANY_ID,
            Name: 'Acme Corp',
            Website: 'https://acme.com',
        });

        const candidates: OrganizationLookupCandidate[] = [
            {
                ID: ORG_A,
                Name: 'Acme Corp',
                WebsiteDomain: 'acme.com',
                LinkedCompanyID: null,
                Status: 'Active',
            },
            {
                ID: ORG_B,
                Name: 'Acme Holdings',
                WebsiteDomain: 'acme.com',
                LinkedCompanyID: COMPANY_ID.toUpperCase(),
                Status: 'Active',
            },
        ];

        const selected = SelectOrganizationMirrorCandidate(candidates, keys);
        expect(selected).toEqual({
            Candidate: candidates[1],
            Strategy: 'linked_company_id',
        });
    });

    it('selects a single pre-existing unlinked Organization by normalized name, legal name, or domain', () => {
        const keys = ExtractCompanyMatchKeys({
            ID: COMPANY_ID,
            Name: 'Acme Corp',
            Website: 'https://acme.com',
        });

        const byLegalName: OrganizationLookupCandidate[] = [
            {
                ID: ORG_A,
                Name: 'Acme',
                LegalName: '  acme corp  ',
                LinkedCompanyID: null,
                Status: 'Active',
            },
        ];
        expect(SelectOrganizationMirrorCandidate(byLegalName, keys)?.Strategy).toBe('legal_name');

        const byDomain: OrganizationLookupCandidate[] = [
            {
                ID: ORG_A,
                Name: 'Acme International',
                LegalName: null,
                WebsiteDomain: 'acme.com',
                LinkedCompanyID: null,
                Status: 'Active',
            },
        ];
        expect(SelectOrganizationMirrorCandidate(byDomain, keys)?.Strategy).toBe('website_domain');

        // Ignores candidates linked to a different Company
        const foreignLinked: OrganizationLookupCandidate[] = [
            {
                ID: ORG_A,
                Name: 'Acme Corp',
                LinkedCompanyID: OTHER_COMPANY_ID,
                Status: 'Active',
            },
        ];
        expect(SelectOrganizationMirrorCandidate(foreignLinked, keys)).toBeNull();
    });

    it('disambiguates shared-domain candidates by unique normalized Name and throws AMBIGUOUS_ORGANIZATION_MATCH on ties', () => {
        const keys = ExtractCompanyMatchKeys({
            ID: COMPANY_ID,
            Name: 'Acme Corp',
            Website: 'https://acme.com',
        });

        const sharedDomainDistinctName: OrganizationLookupCandidate[] = [
            { ID: ORG_A, Name: 'Acme Corp', WebsiteDomain: 'acme.com', LinkedCompanyID: null },
            { ID: ORG_B, Name: 'Acme Labs', WebsiteDomain: 'acme.com', LinkedCompanyID: null },
        ];
        const disambiguated = SelectOrganizationMirrorCandidate(sharedDomainDistinctName, keys);
        expect(disambiguated?.Candidate.ID).toBe(ORG_A);
        expect(disambiguated?.Strategy).toBe('normalized_name');

        const tiedDuplicates: OrganizationLookupCandidate[] = [
            { ID: ORG_A, Name: 'Acme Corp', LinkedCompanyID: null },
            { ID: ORG_B, Name: 'acme corp', LinkedCompanyID: null },
        ];
        expect(() => SelectOrganizationMirrorCandidate(tiedDuplicates, keys)).toThrowError(CompanyMirrorError);

        try {
            SelectOrganizationMirrorCandidate(tiedDuplicates, keys);
            expect.fail('Expected AMBIGUOUS_ORGANIZATION_MATCH');
        } catch (err) {
            const mirrorErr = err as CompanyMirrorError;
            expect(mirrorErr.Code).toBe('AMBIGUOUS_ORGANIZATION_MATCH');
            expect(mirrorErr.Context.CandidateOrganizationIDs).toEqual([ORG_A, ORG_B]);
        }
    });
});
