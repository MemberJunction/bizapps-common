import type { EnrichmentContext, EnrichmentFacet, PersonEnrichmentRequest, PersonEnrichmentResult } from './types.js';
import { EnrichmentConfigurationError } from './errors.js';

/**
 * The contract every vendor plugin implements. A provider looks people up and returns what it found.
 * It never writes: the engine owns every write, so the rules ("never overwrite manual data", "end only
 * rows we own") live once. Register subclasses with
 * `@RegisterClass(BaseEnrichmentProvider, '<EnrichmentProvider.DriverClass>')`.
 */
export abstract class BaseEnrichmentProvider {
    /** Must equal the EnrichmentProvider.Code this class is registered for. */
    public abstract get Code(): string;

    /** False for fixtures. The engine refuses to write Source='Enrichment' rows from a non-live provider unless told to. */
    public abstract get IsLive(): boolean;

    /** What this provider can supply. The engine drops requested facets the provider lacks. */
    public abstract get SupportedFacets(): EnrichmentFacet[];

    /** A hard ceiling on people per call (Apollo: 10). The engine applies min(ProviderRow.MaxBatchSize, this). */
    public get MaxBatchSizeCeiling(): number | null {
        return null;
    }

    /**
     * Credits the vendor reported for this run so far, or null when the vendor does not report them.
     * Providers add to it from EnrichPeople; the engine reads it at the end of the run.
     */
    public get CreditsConsumed(): number | null {
        return this.creditsConsumed;
    }

    private creditsConsumed: number | null = null;

    /** Called once per run before the first batch. Resolve credentials here; throw EnrichmentConfigurationError if none. */
    public abstract Initialize(context: EnrichmentContext): Promise<void>;

    /**
     * Look up a batch of people. MUST NOT write anything.
     * Returns exactly one result per request, matched by PersonID, in any order.
     * Throws EnrichmentRateLimitError when the vendor rate-limits and EnrichmentQuotaExhaustedError when
     * the account is out of credits; the engine stops the run cleanly in both cases.
     */
    public abstract EnrichPeople(requests: PersonEnrichmentRequest[], context: EnrichmentContext): Promise<PersonEnrichmentResult[]>;

    protected addCreditsConsumed(credits: number): void {
        this.creditsConsumed = (this.creditsConsumed ?? 0) + credits;
    }

    protected noSearch(): EnrichmentConfigurationError {
        return new EnrichmentConfigurationError(`${this.Code} does not support cohort search`);
    }
}
