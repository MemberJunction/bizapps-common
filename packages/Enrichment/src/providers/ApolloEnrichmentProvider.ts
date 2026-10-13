import { ApolloAuthError, ApolloPeopleClient, ApolloRateLimitError } from '@memberjunction/actions-apollo';
import type { ApolloPersonMatch, ApolloPersonMatchInput } from '@memberjunction/actions-apollo';
import { RegisterClass } from '@memberjunction/global';
import { BaseEnrichmentProvider } from '../BaseEnrichmentProvider.js';
import { EnrichmentConfigurationError, EnrichmentRateLimitError } from '../errors.js';
import { InferMatchedBy } from '../request-builder.js';
import type { EnrichmentContext, EnrichmentFacet, PersonEnrichmentRequest, PersonEnrichmentResult } from '../types.js';
import { NotFoundResult } from './provider-results.js';

export const APOLLO_PROVIDER_CODE = 'Apollo';

/**
 * Apollo.io through `ApolloPeopleClient.BulkMatch` (ten people per call, one credit per match, misses
 * free). Apollo supplies employment and a LinkedIn URL; Phase 0 saw no education on any record, so the
 * facet is not advertised, though a degree entry the client's split rule does yield is passed through.
 * Personal emails are never requested. The provider reads the vendor and returns; the engine writes.
 */
@RegisterClass(BaseEnrichmentProvider, APOLLO_PROVIDER_CODE)
export class ApolloEnrichmentProvider extends BaseEnrichmentProvider {
    private client: ApolloPeopleClient | null = null;

    public get Code(): string { return APOLLO_PROVIDER_CODE; }
    public get IsLive(): boolean { return true; }
    public get SupportedFacets(): EnrichmentFacet[] { return ['Employment', 'LinkedIn']; }
    public override get MaxBatchSizeCeiling(): number { return ApolloPeopleClient.MaxBatchSize; }

    public async Initialize(context: EnrichmentContext): Promise<void> {
        const client = await this.CreateClient(context);
        if (!client) throw new EnrichmentConfigurationError(`${APOLLO_PROVIDER_CODE}: no API key resolved (no Apollo credential for the company and no APOLLO_API_KEY)`);
        this.client = client;
    }

    public async EnrichPeople(requests: PersonEnrichmentRequest[], _context: EnrichmentContext): Promise<PersonEnrichmentResult[]> {
        if (!this.client) throw new EnrichmentConfigurationError(`${APOLLO_PROVIDER_CODE}: Initialize must run before EnrichPeople`);
        if (requests.length === 0) return [];
        const inputs = requests.map(ToMatchInput);
        let matches: ApolloPersonMatch[];
        try {
            const result = await this.client.BulkMatch(inputs, { RevealPersonalEmails: false });
            matches = result.Matches;
            this.addCreditsConsumed(result.CreditsConsumed);
        } catch (error) {
            throw TranslateApolloError(error);
        }
        return matches.map((match, index) => ApolloMatchToResult(match, requests[index]));
    }

    /**
     * The client for this run: the company's Apollo credential, then APOLLO_API_KEY. A protected seam
     * so tests substitute a client with a fake fetch; nothing in a test may reach api.apollo.io.
     */
    protected async CreateClient(context: EnrichmentContext): Promise<ApolloPeopleClient | null> {
        const resolved = await ApolloPeopleClient.ForCompany(context.CompanyID, context.ContextUser);
        return resolved ? resolved.Client : null;
    }
}

/** Everything the engine knows about the person, keyed by PersonID so the match comes back correlated. */
export function ToMatchInput(request: PersonEnrichmentRequest): ApolloPersonMatchInput {
    return {
        Key: request.PersonID,
        ApolloPersonID: request.ExternalID ?? undefined,
        Email: request.Emails[0],
        LinkedInURL: request.LinkedInURL ?? undefined,
        FirstName: request.FirstName,
        LastName: request.LastName,
        OrganizationDomain: request.OrganizationDomain ?? undefined,
        OrganizationName: request.OrganizationName ?? undefined,
    };
}

/** Apollo does not say which identifier matched; the strongest one sent is reported (request-builder priority). */
export function ApolloMatchToResult(match: ApolloPersonMatch, request: PersonEnrichmentRequest): PersonEnrichmentResult {
    if (!match.Matched) return NotFoundResult(request);
    return {
        PersonID: request.PersonID,
        Status: 'Matched',
        ExternalID: match.ApolloPersonID,
        MatchedBy: InferMatchedBy(request),
        MatchConfidence: null,
        LinkedInURL: match.LinkedInURL,
        Education: match.Education.map((entry) => ({
            InstitutionName: entry.InstitutionName,
            InstitutionExternalID: entry.ApolloOrganizationID,
            Degree: entry.Degree,
            FieldOfStudy: entry.FieldOfStudy,
            StartDate: entry.StartDate,
            EndDate: entry.EndDate,
        })),
        Employment: match.Employment.map((entry) => ({
            OrganizationName: entry.OrganizationName,
            OrganizationDomain: entry.OrganizationDomain,
            Title: entry.Title,
            StartDate: entry.StartDate,
            EndDate: entry.EndDate,
            IsCurrent: entry.IsCurrent,
        })),
        ErrorMessage: null,
    };
}

/** Rate limits stop the run cleanly; a rejected key is a configuration problem; anything else is a batch error. */
export function TranslateApolloError(error: unknown): Error {
    if (error instanceof ApolloRateLimitError) return new EnrichmentRateLimitError(`${APOLLO_PROVIDER_CODE}: ${error.message}`, error.RetryAfterSeconds);
    if (error instanceof ApolloAuthError) return new EnrichmentConfigurationError(`${APOLLO_PROVIDER_CODE}: ${error.message}`);
    return error instanceof Error ? error : new Error(String(error));
}
