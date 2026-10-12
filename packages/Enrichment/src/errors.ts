/**
 * Errors a provider throws to tell the engine why a batch could not be served. The engine turns each
 * into a clean stop with a StoppedReason instead of a failed run.
 */

/** The vendor rate-limited us. Clears by itself; the next run continues normally. */
export class EnrichmentRateLimitError extends Error {
    public readonly RetryAfterSeconds: number | null;

    constructor(message: string, retryAfterSeconds: number | null = null) {
        super(message);
        this.name = 'EnrichmentRateLimitError';
        this.RetryAfterSeconds = retryAfterSeconds;
    }
}

/** The vendor account is out of credits. Nothing more happens until someone tops it up. */
export class EnrichmentQuotaExhaustedError extends Error {
    constructor(message: string) {
        super(message);
        this.name = 'EnrichmentQuotaExhaustedError';
    }
}

/** The provider cannot run: no credential, bad configuration, unsupported operation. */
export class EnrichmentConfigurationError extends Error {
    constructor(message: string) {
        super(message);
        this.name = 'EnrichmentConfigurationError';
    }
}

export type EnrichmentRefusalCode =
    | 'PROVIDER_NOT_FOUND'
    | 'PROVIDER_INACTIVE'
    | 'CREDENTIALS_NOT_FOUND'
    | 'VALIDATION_ERROR';

/** The engine refused to start the run. The action maps Code straight onto its result code. */
export class EnrichmentRefusedError extends Error {
    public readonly Code: EnrichmentRefusalCode;

    constructor(code: EnrichmentRefusalCode, message: string) {
        super(message);
        this.name = 'EnrichmentRefusedError';
        this.Code = code;
    }
}
