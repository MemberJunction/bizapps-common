import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { ApolloPeopleClient } from '@memberjunction/actions-apollo';
import { EnrichmentConfigurationError, EnrichmentRateLimitError } from '../errors.js';
import { ApolloEnrichmentProvider, ToMatchInput } from '../providers/ApolloEnrichmentProvider.js';
import type { EnrichmentContext, PersonEnrichmentRequest } from '../types.js';

interface Fixture { headers: Record<string, string>; body: unknown }
const bulk: Fixture = JSON.parse(readFileSync(fileURLToPath(new URL('./fixtures/apollo-bulk-match.redacted.json', import.meta.url)), 'utf8'));
interface Reply { status?: number; body?: unknown; headers?: Record<string, string> }
interface Call { url: string; body: Record<string, unknown> }

/** A fake fetch: tests must never reach api.apollo.io. */
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

class TestApolloProvider extends ApolloEnrichmentProvider {
    constructor(private readonly testClient: ApolloPeopleClient | null) { super(); }
    protected override async CreateClient(): Promise<ApolloPeopleClient | null> { return this.testClient; }
}
const context = { CompanyID: null } as EnrichmentContext;
function request(over: Partial<PersonEnrichmentRequest>): PersonEnrichmentRequest {
    return { PersonID: over.PersonID ?? 'p', FirstName: '', LastName: '', Emails: [], LinkedInURL: null, OrganizationDomain: null, OrganizationName: null, ExternalID: null, ...over };
}
/** The six people of the Phase 0 fixture, in its order: match, miss, then four matches. */
const requests = [
    request({ PersonID: 'hks-1', FirstName: 'A', LastName: 'B', OrganizationDomain: 'un.org' }),
    request({ PersonID: 'hks-2', FirstName: 'C', LastName: 'D', OrganizationName: 'Gov' }),
    request({ PersonID: 'exec-1', LinkedInURL: 'https://www.linkedin.com/in/x' }),
    request({ PersonID: 'exec-2', LinkedInURL: 'https://www.linkedin.com/in/y' }),
    request({ PersonID: 'exec-3', Emails: ['e3@example.com', 'alt@example.com'] }),
    request({ PersonID: 'exec-4', ExternalID: 'apollo-id', Emails: ['e4@example.com'] }),
];
async function provider(replies: Reply[]) {
    const { fetchImpl, calls } = fakeFetch(replies);
    const p = new TestApolloProvider(new ApolloPeopleClient('key-1', { FetchImpl: fetchImpl, SleepImpl: async () => undefined }));
    await p.Initialize(context);
    return { p, calls };
}

describe('ApolloEnrichmentProvider', () => {
    it('declares Apollo, live, employment + LinkedIn, and a ceiling of 10', () => {
        const p = new TestApolloProvider(null);
        expect([p.Code, p.IsLive, p.SupportedFacets, p.MaxBatchSizeCeiling]).toEqual(['Apollo', true, ['Employment', 'LinkedIn'], 10]);
    });
    it('refuses to initialize without a key, as a configuration error', async () => {
        await expect(new TestApolloProvider(null).Initialize(context)).rejects.toBeInstanceOf(EnrichmentConfigurationError);
    });
    it('sends one bulk_match keyed by PersonID without revealing personal emails, and maps the fixture', async () => {
        const { p, calls } = await provider([{ body: bulk.body, headers: bulk.headers }]);
        const results = await p.EnrichPeople(requests, context);
        expect(calls).toHaveLength(1);
        expect(calls[0].body).toMatchObject({ reveal_personal_emails: false, reveal_phone_number: false });
        const details = calls[0].body.details as Record<string, string>[];
        expect(details[0]).toEqual({ first_name: 'A', last_name: 'B', domain: 'un.org' });
        expect(details[4]).toEqual({ email: 'e3@example.com' });
        expect(details[5]).toEqual({ id: 'apollo-id', email: 'e4@example.com' });
        expect(results.map((r) => [r.PersonID, r.Status])).toEqual([['hks-1', 'Matched'], ['hks-2', 'NotFound'], ['exec-1', 'Matched'], ['exec-2', 'Matched'], ['exec-3', 'Matched'], ['exec-4', 'Matched']]);
        expect(results[0].MatchedBy).toBe('NameAndDomain');
        expect(results[2].MatchedBy).toBe('LinkedIn');
        expect(results[4].MatchedBy).toBe('Email');
        expect(results[5].MatchedBy).toBe('ExternalID');
        expect(results[0].ExternalID).toEqual(expect.any(String));
        expect(results[0].LinkedInURL).toContain('linkedin.com/in/');
        expect(results[0].Employment[0]).toMatchObject({ OrganizationName: 'United Nations', Title: 'Secretary General', StartDate: '2007-01-01', EndDate: null, IsCurrent: true });
        expect(results.every((r) => r.Education.length === 0)).toBe(true);
        expect(p.CreditsConsumed).toBe(5);
        expect(JSON.stringify(results)).not.toMatch(/@|phone/i);
    });
    it('turns an hourly 429 into EnrichmentRateLimitError and a 401 into EnrichmentConfigurationError', async () => {
        const limited = await provider([{ status: 429, body: { error: 'Hourly rate limit exceeded' }, headers: { 'retry-after': '1800' } }]);
        const error = await limited.p.EnrichPeople(requests.slice(0, 1), context).catch((e: unknown) => e);
        expect(error).toBeInstanceOf(EnrichmentRateLimitError);
        expect((error as EnrichmentRateLimitError).RetryAfterSeconds).toBe(1800);
        const rejected = await provider([{ status: 401, body: { error: 'Invalid API key' } }]);
        await expect(rejected.p.EnrichPeople(requests.slice(0, 1), context)).rejects.toBeInstanceOf(EnrichmentConfigurationError);
    });
    it('ToMatchInput sends the first email, the vendor id when held, and the organization for a name match', () => {
        expect(ToMatchInput(requests[5])).toMatchObject({ Key: 'exec-4', ApolloPersonID: 'apollo-id', Email: 'e4@example.com' });
        expect(ToMatchInput(requests[1])).toMatchObject({ FirstName: 'C', LastName: 'D', OrganizationName: 'Gov' });
    });
});
