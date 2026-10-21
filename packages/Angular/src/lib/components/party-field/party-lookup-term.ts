export type PartyKind = 'Person' | 'Organization';

/** Template parameters of every party lookup query. `Domain` is omitted from the call when null. */
export interface PartyLookupParams {
    Term: string;
    Domain: string | null;
}

/**
 * The query each kind searches by default. An app that stores a subtype ID (Sales Contacts,
 * Sales Accounts) passes its own query honouring the same contract: columns ID, Name, Detail;
 * parameters Term and Domain.
 */
export const PARTY_LOOKUP_QUERIES: Record<PartyKind, { QueryName: string; CategoryPath: string }> = {
    Person: { QueryName: 'Common: Party Lookup People', CategoryPath: 'Common' },
    Organization: { QueryName: 'Common: Party Lookup Organizations', CategoryPath: 'Common' },
};

const MIN_TERM_LENGTH = 2;

/**
 * What to search for, or null under two non-blank characters (the picker then shows nothing and
 * sends nothing). No escaping here: the query's `sqlLikeBegins` filter escapes.
 */
export function PartyLookupParamsFor(kind: PartyKind, raw: string): PartyLookupParams | null {
    const term = raw.trim();
    if (term.length < MIN_TERM_LENGTH) {
        return null;
    }
    const domain = kind === 'Person' ? emailDomainOf(term) : websiteDomainOf(term);
    return { Term: term, Domain: domain && domain.length >= MIN_TERM_LENGTH ? domain : null };
}

/** `@aqha.com` → `aqha.com`. Only a term that looks like part of an address gets a domain. */
function emailDomainOf(term: string): string | null {
    if (!term.includes('@') && !term.includes('.')) {
        return null;
    }
    return term.replace(/^@/, '').toLowerCase();
}

/** Same steps as the Organization.WebsiteDomain column: lower-case, drop scheme and `www.`, cut at `/`. */
function websiteDomainOf(term: string): string | null {
    if (!term.includes('.')) {
        return null;
    }
    const host = term.toLowerCase().replace(/^https?:\/\//, '').replace(/^www\./, '');
    return host.split('/')[0];
}
