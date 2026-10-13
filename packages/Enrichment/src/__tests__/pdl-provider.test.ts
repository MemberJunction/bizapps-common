import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { PDLPersonClient } from '@memberjunction/actions-peopledatalabs';
import { EnrichmentConfigurationError, EnrichmentQuotaExhaustedError, EnrichmentRateLimitError } from '../errors.js';
import { BulkOptions, PDLEnrichmentProvider, ParsePDLConfiguration, ToPersonInput } from '../providers/PDLEnrichmentProvider.js';
import type { EnrichmentContext, PersonEnrichmentRequest } from '../types.js';

interface Fixture { headers: Record<string, string>; body: unknown }
const bulk: Fixture = JSON.parse(readFileSync(fileURLToPath(new URL('./fixtures/pdl-person-bulk.redacted.json', import.meta.url)), 'utf8'));
interface Reply { status?: number; body?: unknown; headers?: Record<string, string> }
interface Call { url: string; body: Record<string, unknown> }

/** A fake fetch: tests must never reach api.peopledatalabs.com. */
function fakeFetch(replies: Reply[]): { fetchImpl: typeof fetch; calls: Call[] } {
    const calls: Call[] = [];
    const fetchImpl = (async (url: string, init: RequestInit) => {
        calls.push({ url, body: JSON.parse(String(init.body)) as Record<string, unknown> });
        const reply = replies[calls.length - 1];
        const status = reply.status ?? 200;
        const text = JSON.stringify(reply.body ?? null);
        return { ok: status < 300, status, headers: new Headers(reply.headers ?? {}), text: async () => text, json: async () => JSON.parse(text) };
    }) as unknown as typeof fetch;
    return { fetchImpl, calls };
}

class TestPDLProvider extends PDLEnrichmentProvider {
    constructor(private readonly testClient: PDLPersonClient | null) { super(); }
    protected override async CreateClient(): Promise<PDLPersonClient | null> { return this.testClient; }
}
function contextWith(configuration: string | null): EnrichmentContext {
    return { CompanyID: null, ProviderRow: { Configuration: configuration } } as unknown as EnrichmentContext;
}
function request(over: Partial<PersonEnrichmentRequest>): PersonEnrichmentRequest {
    return { PersonID: over.PersonID ?? 'p', FirstName: '', LastName: '', Emails: [], LinkedInURL: null, OrganizationDomain: null, OrganizationName: null, ExternalID: null, ...over };
}
/** The six people of the Phase 0 fixture, in its order: match, miss, match, miss, miss, miss. */
const requests = [
    request({ PersonID: 'hks-1', FirstName: 'A', LastName: 'B', OrganizationName: 'United Nations' }),
    request({ PersonID: 'hks-2', FirstName: 'C', LastName: 'D', OrganizationDomain: 'gov.test' }),
    request({ PersonID: 'exec-1', LinkedInURL: 'https://www.linkedin.com/in/x' }),
    request({ PersonID: 'exec-2', LinkedInURL: 'https://www.linkedin.com/in/y' }),
    request({ PersonID: 'exec-3', Emails: ['e3@example.com'] }),
    request({ PersonID: 'exec-4', Emails: ['e4@example.com'], ExternalID: 'pdl-known' }),
];
async function provider(replies: Reply[], configuration: string | null = null) {
    const { fetchImpl, calls } = fakeFetch(replies);
    const p = new TestPDLProvider(new PDLPersonClient('key-1', { FetchImpl: fetchImpl }));
    await p.Initialize(contextWith(configuration));
    return { p, calls };
}

describe('PDLEnrichmentProvider', () => {
    it('declares PDL, live, all three facets, and a ceiling of 100', () => {
        const p = new TestPDLProvider(null);
        expect([p.Code, p.IsLive, p.SupportedFacets, p.MaxBatchSizeCeiling]).toEqual(['PDL', true, ['Education', 'Employment', 'LinkedIn'], 100]);
    });
    it('refuses to initialize without a key', async () => {
        await expect(new TestPDLProvider(null).Initialize(contextWith(null))).rejects.toBeInstanceOf(EnrichmentConfigurationError);
    });
    it('maps the fixture: degrees and majors joined per school, school.id kept, likelihood 10 → 1.0, misses NotFound', async () => {
        const { p, calls } = await provider([{ body: bulk.body, headers: bulk.headers }]);
        const results = await p.EnrichPeople(requests, contextWith(null));
        expect(calls).toHaveLength(1);
        const sent = calls[0].body.requests as { params: Record<string, unknown>; metadata: { key: string } }[];
        expect(sent).toHaveLength(6);
        expect(sent[0].metadata.key).toBe('hks-1');
        expect(sent[0].params).toMatchObject({ min_likelihood: 6 });
        expect(results.map((r) => r.Status)).toEqual(['Matched', 'NotFound', 'Matched', 'NotFound', 'NotFound', 'NotFound']);
        const first = results[0];
        expect(first.ExternalID).toBe('pdl-fixture-1');
        expect(first.MatchConfidence).toBe(0.6);
        expect(first.MatchedBy).toBe('NameAndDomain');
        expect(first.Education).toHaveLength(2);
        expect(first.Education[0]).toMatchObject({ InstitutionName: 'harvard university', InstitutionExternalID: '5Ic6qaBcxe2DlWHRIVFnZg_0000', Degree: 'masters', StartDate: '1985-01-01', EndDate: '1985-12-01' });
        expect(first.Education[0].FieldOfStudy).toMatch(/^public a/);
        expect(first.Employment[0]).toMatchObject({ OrganizationName: 'united nations', OrganizationDomain: 'un.org' });
        expect(results[2].MatchConfidence).toBe(1);
        expect(results[2].Education.length + results[2].Employment.length).toBe(7);
        expect(p.CreditsConsumed).toBe(2);
        expect(JSON.stringify(results)).not.toMatch(/@|phone|"email/i);
    });
    it('a per-item error becomes Status Error without failing the batch', async () => {
        const body = [{ status: 200, likelihood: 7, data: { id: 'x', linkedin_url: null, education: [], experience: [] } }, { status: 429, error: { type: 'rate_limit', message: 'slow down' } }];
        const { p } = await provider([{ body, headers: { 'x-call-credits-spent': '1' } }]);
        const results = await p.EnrichPeople(requests.slice(0, 2), contextWith(null));
        expect(results[0].Status).toBe('Matched');
        expect(results[1].Status).toBe('Error');
        expect(results[1].ErrorMessage).toContain('slow down');
    });
    it('translates a 429 to EnrichmentRateLimitError, a 402 to EnrichmentQuotaExhaustedError, a 401 to EnrichmentConfigurationError', async () => {
        const limited = await provider([{ status: 429, body: { error: { type: 'rate_limit_error', message: 'Rate limit' } }, headers: { 'retry-after': '30' } }]);
        await expect(limited.p.EnrichPeople(requests.slice(0, 1), contextWith(null))).rejects.toBeInstanceOf(EnrichmentRateLimitError);
        const exhausted = await provider([{ status: 402, body: { error: { type: 'payment_required', message: 'No credits' } } }]);
        await expect(exhausted.p.EnrichPeople(requests.slice(0, 1), contextWith(null))).rejects.toBeInstanceOf(EnrichmentQuotaExhaustedError);
        const rejected = await provider([{ status: 401, body: { error: { type: 'authentication_error', message: 'bad key' } } }]);
        await expect(rejected.p.EnrichPeople(requests.slice(0, 1), contextWith(null))).rejects.toBeInstanceOf(EnrichmentConfigurationError);
    });
    it('honours Configuration: MinLikelihood, Required and DataInclude; rejects bad JSON and a bad likelihood', async () => {
        const { p, calls } = await provider([{ body: bulk.body, headers: bulk.headers }], '{"MinLikelihood": 8, "Required": "linkedin_url", "DataInclude": ["education"]}');
        await p.EnrichPeople(requests, contextWith(null));
        const sent = calls[0].body.requests as { params: Record<string, unknown> }[];
        expect(sent[0].params).toMatchObject({ min_likelihood: 8, required: 'linkedin_url', data_include: 'education' });
        expect(ParsePDLConfiguration(null)).toEqual({ MinLikelihood: 6, Required: null, DataInclude: null });
        expect(() => ParsePDLConfiguration('{not json')).toThrow(EnrichmentConfigurationError);
        expect(() => ParsePDLConfiguration('{"MinLikelihood": 11}')).toThrow(EnrichmentConfigurationError);
        expect(() => ParsePDLConfiguration('{"MinLikelihood": 2.5}')).toThrow(EnrichmentConfigurationError);
        expect(BulkOptions({ MinLikelihood: 6, Required: null, DataInclude: null })).toEqual({ MinLikelihood: 6 });
    });
    it('ToPersonInput prefers the domain over the organization name and carries the held PDL id', () => {
        expect(ToPersonInput(request({ PersonID: 'a', OrganizationDomain: 'un.org', OrganizationName: 'UN' })).Company).toBe('un.org');
        expect(ToPersonInput(request({ PersonID: 'b', OrganizationName: 'UN' })).Company).toBe('UN');
        expect(ToPersonInput(requests[5])).toMatchObject({ Key: 'exec-4', PDLID: 'pdl-known', Email: 'e4@example.com' });
    });
});
