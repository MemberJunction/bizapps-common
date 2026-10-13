import type { PersonEnrichmentRequest, PersonEnrichmentResult } from '../types.js';

/** The result for a person the vendor did not find. */
export function NotFoundResult(request: PersonEnrichmentRequest): PersonEnrichmentResult {
    return { PersonID: request.PersonID, Status: 'NotFound', ExternalID: null, MatchedBy: null, MatchConfidence: null, LinkedInURL: null, Education: [], Employment: [], ErrorMessage: null };
}

/** The result for a person whose lookup failed on the vendor's side; never persisted as an identity. */
export function ErrorResult(request: PersonEnrichmentRequest, message: string): PersonEnrichmentResult {
    return { ...NotFoundResult(request), Status: 'Error', ErrorMessage: message };
}

/** `['MPP', 'MPA']` → `'MPP; MPA'`; an empty list → null. */
export function JoinOrNull(values: readonly string[]): string | null {
    const cleaned = values.map((value) => value.trim()).filter((value) => value.length > 0);
    return cleaned.length === 0 ? null : cleaned.join('; ');
}
