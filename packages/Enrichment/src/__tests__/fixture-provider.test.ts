import { describe, expect, it } from 'vitest';
import { EnrichmentQuotaExhaustedError, EnrichmentRateLimitError } from '../errors.js';
import { FixtureEnrichmentProvider } from '../providers/FixtureEnrichmentProvider.js';
import type { EnrichmentContext, PersonEnrichmentRequest } from '../types.js';

function request(email: string): PersonEnrichmentRequest {
    return { PersonID: email, FirstName: 'F', LastName: 'L', Emails: [email], LinkedInURL: null, OrganizationDomain: null, OrganizationName: null, ExternalID: null };
}
const context = {} as EnrichmentContext;

describe('FixtureEnrichmentProvider', () => {
    it('answers the built-in scenarios by the local part of a fixture.test email', async () => {
        const provider = new FixtureEnrichmentProvider();
        const results = await provider.EnrichPeople([request('alum@fixture.test'), request('notfound@fixture.test'), request('matched-x@fixture.test'), request('someone@example.com')], context);
        expect(results.map((r) => r.Status)).toEqual(['Matched', 'NotFound', 'Matched', 'NotFound']);
        expect(results[0].ExternalID).toBe('fixture-alum');
        expect(results[2].ExternalID).toBe('fixture-matched-x');
        expect(results[0].Education[0].InstitutionName).toBe('Harvard Kennedy School');
        expect(provider.CreditsConsumed).toBe(2);
    });
    it('throws the typed vendor errors for the ratelimit and quota scenarios', async () => {
        await expect(new FixtureEnrichmentProvider().EnrichPeople([request('ratelimit@fixture.test')], context)).rejects.toBeInstanceOf(EnrichmentRateLimitError);
        await expect(new FixtureEnrichmentProvider().EnrichPeople([request('quota@fixture.test')], context)).rejects.toBeInstanceOf(EnrichmentQuotaExhaustedError);
    });
    it('lets a test script any email, taking precedence over the scenarios', async () => {
        FixtureEnrichmentProvider.Scripted.set('alum@fixture.test', (r) => ({ PersonID: r.PersonID, Status: 'Error', ExternalID: null, MatchedBy: null, MatchConfidence: null, LinkedInURL: null, Education: [], Employment: [], ErrorMessage: 'scripted' }));
        try {
            const [result] = await new FixtureEnrichmentProvider().EnrichPeople([request('alum@fixture.test')], context);
            expect(result.Status).toBe('Error');
        } finally {
            FixtureEnrichmentProvider.Scripted.clear();
        }
    });
});
