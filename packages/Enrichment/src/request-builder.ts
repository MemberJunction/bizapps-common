import { DomainFromWebsite, NormalizeEmails, NormalizeLinkedInURL } from './normalize.js';
import type { PersonEnrichmentRequest, PersonMatchedBy } from './types.js';

/** What the batch context knows about one person, flattened so the builder stays pure and testable. */
export interface PersonSnapshot {
    ID: string;
    FirstName: string;
    LastName: string;
    Email: string | null;
    /** Values of the person's Email contact methods. */
    ContactEmails: string[];
    /** Value of the person's LinkedIn contact method, if any. */
    LinkedInURL: string | null;
    /** The current Employee relationship's Organization, if any. */
    CurrentEmployer: { Name: string | null; Website: string | null } | null;
    /** This provider's identity row's ExternalID, when that row is Matched. */
    MatchedExternalID: string | null;
}

/** One request per person, or null when nothing identifies them (they should not have passed the filter). */
export function BuildRequest(person: PersonSnapshot): PersonEnrichmentRequest | null {
    const request: PersonEnrichmentRequest = {
        PersonID: person.ID,
        FirstName: person.FirstName,
        LastName: person.LastName,
        Emails: NormalizeEmails([person.Email, ...person.ContactEmails]),
        LinkedInURL: NormalizeLinkedInURL(person.LinkedInURL),
        OrganizationDomain: DomainFromWebsite(person.CurrentEmployer?.Website),
        OrganizationName: NullIfBlank(person.CurrentEmployer?.Name),
        ExternalID: NullIfBlank(person.MatchedExternalID),
    };
    return InferMatchedBy(request) ? request : null;
}

export interface BuiltRequests {
    Requests: PersonEnrichmentRequest[];
    /** People with nothing to identify them by. */
    SkippedPersonIDs: string[];
}

export function BuildRequests(people: PersonSnapshot[]): BuiltRequests {
    const out: BuiltRequests = { Requests: [], SkippedPersonIDs: [] };
    for (const person of people) {
        const request = BuildRequest(person);
        if (request) out.Requests.push(request);
        else out.SkippedPersonIDs.push(person.ID);
    }
    return out;
}

/**
 * The identity priority: external ID, then email, then LinkedIn, then name plus the current
 * employer's domain or name. Sets MatchedBy when the provider does not report it.
 */
export function InferMatchedBy(request: PersonEnrichmentRequest): PersonMatchedBy | null {
    if (request.ExternalID) return 'ExternalID';
    if (request.Emails.length > 0) return 'Email';
    if (request.LinkedInURL) return 'LinkedIn';
    const hasName = request.FirstName.trim() !== '' && request.LastName.trim() !== '';
    if (hasName && (request.OrganizationDomain || request.OrganizationName)) return 'NameAndDomain';
    return null;
}

function NullIfBlank(value: string | null | undefined): string | null {
    if (value == null) return null;
    const trimmed = value.trim();
    return trimmed === '' ? null : trimmed;
}
