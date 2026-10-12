import { RegisterClass } from '@memberjunction/global';
import { BaseEnrichmentProvider } from '../BaseEnrichmentProvider.js';
import { EnrichmentQuotaExhaustedError, EnrichmentRateLimitError } from '../errors.js';
import type { EnrichmentContext, EnrichmentFacet, PersonEnrichmentRequest, PersonEnrichmentResult } from '../types.js';

export const FIXTURE_PROVIDER_CODE = 'Fixture';
export const FIXTURE_EMAIL_DOMAIN = 'fixture.test';

/**
 * Deterministic results keyed on the person's email, so integration tests and demo hosts can run the
 * whole engine without a vendor. The local part of an `@fixture.test` address picks the scenario:
 *
 * | local part   | result |
 * |---|---|
 * | `alum`       | Matched: an HKS MPP, a current job at Fixture Labs, a LinkedIn URL |
 * | `changed`    | Matched: the same person later, now at Fixture Industries |
 * | `duplicate`  | Matched with alum's ExternalID, so the engine marks it Ambiguous |
 * | `notfound`   | NotFound |
 * | `error`      | Error |
 * | `ratelimit`  | throws EnrichmentRateLimitError |
 * | `quota`      | throws EnrichmentQuotaExhaustedError |
 * | `matched-*`  | Matched with ExternalID `fixture-<local part>`, the HKS MPP and a current job at Fixture Labs; for callers in another process, where `Scripted` cannot reach |
 * | anything else | NotFound |
 *
 * Tests can override any email with `FixtureEnrichmentProvider.Scripted`.
 */
@RegisterClass(BaseEnrichmentProvider, FIXTURE_PROVIDER_CODE)
export class FixtureEnrichmentProvider extends BaseEnrichmentProvider {
    /** Email (lower-case) to a scripted result or error, consulted before the built-in scenarios. */
    public static readonly Scripted = new Map<string, (request: PersonEnrichmentRequest) => PersonEnrichmentResult | Error>();

    public get Code(): string { return FIXTURE_PROVIDER_CODE; }
    public get IsLive(): boolean { return false; }
    public get SupportedFacets(): EnrichmentFacet[] { return ['Education', 'Employment', 'LinkedIn']; }

    public async Initialize(_context: EnrichmentContext): Promise<void> {
        // No credential: the fixture never calls out.
    }

    public async EnrichPeople(requests: PersonEnrichmentRequest[], _context: EnrichmentContext): Promise<PersonEnrichmentResult[]> {
        const results: PersonEnrichmentResult[] = [];
        for (const request of requests) {
            const outcome = Scenario(request);
            if (outcome instanceof Error) throw outcome;
            results.push(outcome);
        }
        this.addCreditsConsumed(results.filter((result) => result.Status === 'Matched').length);
        return results;
    }
}

function Scenario(request: PersonEnrichmentRequest): PersonEnrichmentResult | Error {
    for (const email of request.Emails) {
        const scripted = FixtureEnrichmentProvider.Scripted.get(email);
        if (scripted) return scripted(request);
    }
    const local = request.Emails.map((email) => email.split('@')).find(([, domain]) => domain === FIXTURE_EMAIL_DOMAIN)?.[0] ?? '';
    if (local.startsWith('matched-')) return Matched(request, `fixture-${local}`, FixtureLabs(true));
    switch (local) {
        case 'alum': return Matched(request, 'fixture-alum', FixtureLabs(true));
        case 'changed': return Matched(request, 'fixture-alum', FixtureIndustries());
        case 'duplicate': return Matched(request, 'fixture-alum', FixtureLabs(true));
        case 'error': return { ...NotFound(request), Status: 'Error', ErrorMessage: 'Fixture: scripted error' };
        case 'ratelimit': return new EnrichmentRateLimitError('Fixture: scripted rate limit', 60);
        case 'quota': return new EnrichmentQuotaExhaustedError('Fixture: scripted quota exhaustion');
        default: return NotFound(request);
    }
}

function Matched(request: PersonEnrichmentRequest, externalID: string, employment: PersonEnrichmentResult['Employment']): PersonEnrichmentResult {
    return {
        PersonID: request.PersonID,
        Status: 'Matched',
        ExternalID: externalID,
        MatchedBy: request.ExternalID ? 'ExternalID' : 'Email',
        MatchConfidence: 0.95,
        LinkedInURL: 'https://www.linkedin.com/in/fixture-alum/',
        Education: [
            { InstitutionName: 'Harvard Kennedy School', InstitutionExternalID: 'fixture-school-hks', Degree: 'MPP', FieldOfStudy: 'Public Policy', StartDate: '2010-09-01', EndDate: '2012-05-31' },
        ],
        Employment: employment,
        ErrorMessage: null,
    };
}

function NotFound(request: PersonEnrichmentRequest): PersonEnrichmentResult {
    return { PersonID: request.PersonID, Status: 'NotFound', ExternalID: null, MatchedBy: null, MatchConfidence: null, LinkedInURL: null, Education: [], Employment: [], ErrorMessage: null };
}

function FixtureLabs(isCurrent: boolean): PersonEnrichmentResult['Employment'] {
    return [{ OrganizationName: 'Fixture Labs', OrganizationDomain: 'fixturelabs.test', Title: 'Policy Analyst', StartDate: '2012-07-01', EndDate: isCurrent ? null : '2020-01-31', IsCurrent: isCurrent }];
}

function FixtureIndustries(): PersonEnrichmentResult['Employment'] {
    return [
        ...FixtureLabs(false),
        { OrganizationName: 'Fixture Industries', OrganizationDomain: 'fixtureindustries.test', Title: 'Director of Policy', StartDate: '2020-02-01', EndDate: null, IsCurrent: true },
    ];
}
