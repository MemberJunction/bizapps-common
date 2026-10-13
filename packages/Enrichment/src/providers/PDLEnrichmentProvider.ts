import { PDLAuthError, PDLCreditsExhaustedError, PDLPersonClient, PDLRateLimitError } from '@memberjunction/actions-peopledatalabs';
import type { PDLBulkOptions, PDLPersonInput, PDLPersonMatch } from '@memberjunction/actions-peopledatalabs';
import { RegisterClass } from '@memberjunction/global';
import { BaseEnrichmentProvider } from '../BaseEnrichmentProvider.js';
import { EnrichmentConfigurationError, EnrichmentQuotaExhaustedError, EnrichmentRateLimitError } from '../errors.js';
import { InferMatchedBy } from '../request-builder.js';
import type { EnrichmentContext, EnrichmentFacet, PersonEnrichmentRequest, PersonEnrichmentResult } from '../types.js';
import { ErrorResult, JoinOrNull, NotFoundResult } from './provider-results.js';

export const PDL_PROVIDER_CODE = 'PDL';
export const DEFAULT_MIN_LIKELIHOOD = 6;

/** The JSON an admin may put in the PDL provider row's `Configuration`. */
export interface PDLProviderConfiguration {
    /** PDL match-likelihood floor, an integer from 1 to 10. Default 6. */
    MinLikelihood: number;
    /** PDL `required` expression, passed only when set. */
    Required: string | null;
    /** PDL `data_include` fields, passed only when set. */
    DataInclude: string[] | null;
}

/**
 * People Data Labs through `PDLPersonClient.BulkEnrich` (a hundred people per call, one credit per
 * match, misses free). PDL carries education, employment and a LinkedIn URL. One PDL education entry
 * becomes one education row: its degrees and majors are joined with "; ". The provider reads the
 * vendor and returns; the engine writes.
 */
@RegisterClass(BaseEnrichmentProvider, PDL_PROVIDER_CODE)
export class PDLEnrichmentProvider extends BaseEnrichmentProvider {
    private client: PDLPersonClient | null = null;
    private configuration: PDLProviderConfiguration = { MinLikelihood: DEFAULT_MIN_LIKELIHOOD, Required: null, DataInclude: null };

    public get Code(): string { return PDL_PROVIDER_CODE; }
    public get IsLive(): boolean { return true; }
    public get SupportedFacets(): EnrichmentFacet[] { return ['Education', 'Employment', 'LinkedIn']; }
    public override get MaxBatchSizeCeiling(): number { return PDLPersonClient.MaxBatchSize; }

    public async Initialize(context: EnrichmentContext): Promise<void> {
        this.configuration = ParsePDLConfiguration(context.ProviderRow.Configuration);
        const client = await this.CreateClient(context);
        if (!client) throw new EnrichmentConfigurationError(`${PDL_PROVIDER_CODE}: no API key resolved (no People Data Labs credential for the company and no PDL_API_KEY)`);
        this.client = client;
    }

    public async EnrichPeople(requests: PersonEnrichmentRequest[], _context: EnrichmentContext): Promise<PersonEnrichmentResult[]> {
        if (!this.client) throw new EnrichmentConfigurationError(`${PDL_PROVIDER_CODE}: Initialize must run before EnrichPeople`);
        if (requests.length === 0) return [];
        const inputs = requests.map(ToPersonInput);
        let matches: PDLPersonMatch[];
        try {
            const result = await this.client.BulkEnrich(inputs, BulkOptions(this.configuration));
            matches = result.Matches;
            this.addCreditsConsumed(result.CreditsConsumed);
        } catch (error) {
            throw TranslatePDLError(error);
        }
        return matches.map((match, index) => PDLMatchToResult(match, requests[index]));
    }

    /**
     * The client for this run: the company's People Data Labs credential, then PDL_API_KEY. A protected
     * seam so tests substitute a client with a fake fetch; nothing in a test may reach api.peopledatalabs.com.
     */
    protected async CreateClient(context: EnrichmentContext): Promise<PDLPersonClient | null> {
        const resolved = await PDLPersonClient.ForCompany(context.CompanyID, context.ContextUser);
        return resolved ? resolved.Client : null;
    }
}

/**
 * The provider row's `Configuration` as a typed, validated object. Bad JSON or a bad value throws
 * rather than silently running with defaults, so a typo never changes what a run spends.
 */
export function ParsePDLConfiguration(raw: string | null | undefined): PDLProviderConfiguration {
    const defaults: PDLProviderConfiguration = { MinLikelihood: DEFAULT_MIN_LIKELIHOOD, Required: null, DataInclude: null };
    if (raw == null || raw.trim() === '') return defaults;
    let parsed: unknown;
    try {
        parsed = JSON.parse(raw);
    } catch (error) {
        throw new EnrichmentConfigurationError(`${PDL_PROVIDER_CODE}: Configuration is not valid JSON (${error instanceof Error ? error.message : String(error)})`);
    }
    if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) throw new EnrichmentConfigurationError(`${PDL_PROVIDER_CODE}: Configuration must be a JSON object`);
    const record = parsed as Record<string, unknown>;
    return {
        MinLikelihood: LikelihoodOf(record.MinLikelihood),
        Required: OptionalString(record.Required, 'Required'),
        DataInclude: OptionalStringList(record.DataInclude, 'DataInclude'),
    };
}

function LikelihoodOf(value: unknown): number {
    if (value === undefined || value === null) return DEFAULT_MIN_LIKELIHOOD;
    if (typeof value !== 'number' || !Number.isInteger(value) || value < 1 || value > 10) {
        throw new EnrichmentConfigurationError(`${PDL_PROVIDER_CODE}: Configuration.MinLikelihood must be an integer from 1 to 10`);
    }
    return value;
}

function OptionalString(value: unknown, name: string): string | null {
    if (value === undefined || value === null) return null;
    if (typeof value !== 'string') throw new EnrichmentConfigurationError(`${PDL_PROVIDER_CODE}: Configuration.${name} must be a string`);
    return value.trim() === '' ? null : value;
}

function OptionalStringList(value: unknown, name: string): string[] | null {
    if (value === undefined || value === null) return null;
    if (!Array.isArray(value) || value.some((item) => typeof item !== 'string')) throw new EnrichmentConfigurationError(`${PDL_PROVIDER_CODE}: Configuration.${name} must be an array of strings`);
    return value.length === 0 ? null : (value as string[]);
}

/** `Required` and `DataInclude` go only when the row sets them; the client's own field mapping is the minimization. */
export function BulkOptions(configuration: PDLProviderConfiguration): PDLBulkOptions {
    const options: PDLBulkOptions = { MinLikelihood: configuration.MinLikelihood };
    if (configuration.Required) options.Required = configuration.Required;
    if (configuration.DataInclude) options.DataInclude = configuration.DataInclude;
    return options;
}

/** Keyed by PersonID; the PDL id when we already hold one; the domain before the organization name for Company. */
export function ToPersonInput(request: PersonEnrichmentRequest): PDLPersonInput {
    return {
        Key: request.PersonID,
        PDLID: request.ExternalID ?? undefined,
        Email: request.Emails[0],
        LinkedInURL: request.LinkedInURL ?? undefined,
        FirstName: request.FirstName,
        LastName: request.LastName,
        Company: request.OrganizationDomain ?? request.OrganizationName ?? undefined,
    };
}

/**
 * PDL does not say which identifier produced a match, so MatchedBy is the strongest identifier that
 * was sent, in the request builder's priority order (ExternalID, Email, LinkedIn, name + organization).
 */
export function PDLMatchToResult(match: PDLPersonMatch, request: PersonEnrichmentRequest): PersonEnrichmentResult {
    if (match.ErrorMessage) return ErrorResult(request, match.ErrorMessage);
    if (!match.Matched) return NotFoundResult(request);
    return {
        PersonID: request.PersonID,
        Status: 'Matched',
        ExternalID: match.PDLID,
        MatchedBy: InferMatchedBy(request),
        MatchConfidence: match.Likelihood == null ? null : Math.max(0, Math.min(1, match.Likelihood / 10)),
        LinkedInURL: match.LinkedInURL,
        Education: match.Education.map((entry) => ({
            InstitutionName: entry.SchoolName,
            InstitutionExternalID: entry.SchoolID,
            Degree: JoinOrNull(entry.Degrees),
            FieldOfStudy: JoinOrNull(entry.Majors),
            StartDate: entry.StartDate,
            EndDate: entry.EndDate,
        })),
        Employment: match.Experience.map((entry) => ({
            OrganizationName: entry.CompanyName,
            OrganizationDomain: entry.CompanyDomain,
            Title: entry.Title,
            StartDate: entry.StartDate,
            EndDate: entry.EndDate,
            IsCurrent: entry.IsCurrent,
        })),
        ErrorMessage: null,
    };
}

/** Rate limits and exhausted credits stop the run cleanly; a rejected key is a configuration problem. */
export function TranslatePDLError(error: unknown): Error {
    if (error instanceof PDLRateLimitError) return new EnrichmentRateLimitError(`${PDL_PROVIDER_CODE}: ${error.message}`, error.RetryAfterSeconds);
    if (error instanceof PDLCreditsExhaustedError) return new EnrichmentQuotaExhaustedError(`${PDL_PROVIDER_CODE}: ${error.message}`);
    if (error instanceof PDLAuthError) return new EnrichmentConfigurationError(`${PDL_PROVIDER_CODE}: ${error.message}`);
    return error instanceof Error ? error : new Error(String(error));
}
