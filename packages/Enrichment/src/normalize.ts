/**
 * Pure key builders shared by the writers, the organization resolver and the request builder.
 * Every comparison the engine makes between a vendor value and a stored value goes through one of
 * these, so "Harvard Kennedy School" and "the harvard kennedy school." dedupe to the same row.
 */

const LEADING_THE = /^the\s+/;
/** Punctuation that joins letters: "M.I.T." is "mit", "O'Hare" is "ohare". */
const JOINING_PUNCTUATION = /[.'’,]/g;
/** Everything else non-alphanumeric separates words: "Harvard-Kennedy" is "harvard kennedy". */
const SEPARATING_PUNCTUATION = /[^\p{L}\p{N}\s]/gu;
const WHITESPACE = /\s+/g;

/** Lower-case, trim, collapse whitespace, strip punctuation, drop a leading "the ". */
export function NormalizeName(value: string | null | undefined): string {
    if (value == null) return '';
    const lowered = value.toLowerCase().replace(JOINING_PUNCTUATION, '').replace(SEPARATING_PUNCTUATION, ' ').replace(WHITESPACE, ' ').trim();
    return lowered.replace(LEADING_THE, '').trim();
}

/** A degree key: the name rules, then no whitespace at all, so "M. P. P.", "M.P.P." and "MPP" are one degree. */
export function NormalizeDegree(value: string | null | undefined): string {
    return NormalizeName(value).replace(WHITESPACE, '');
}

/** The year of a 'YYYY-MM-DD' (or ISO) date string, or '' when absent or unparseable. */
export function YearOf(date: string | Date | null | undefined): string {
    if (date == null) return '';
    const text = date instanceof Date ? date.toISOString() : date;
    const match = /^(\d{4})/.exec(text.trim());
    return match ? match[1] : '';
}

/** `https://www.Acme.com/about?x=1` -> `acme.com`. Returns null when nothing host-like remains. */
export function DomainFromWebsite(value: string | null | undefined): string | null {
    if (value == null) return null;
    let host = value.trim().toLowerCase();
    if (host === '') return null;
    host = host.replace(/^[a-z][a-z0-9+.-]*:\/\//, '');
    host = host.replace(/^www\./, '');
    host = host.split(/[/?#]/)[0];
    host = host.replace(/:\d+$/, '');
    host = host.replace(/\.$/, '');
    return host === '' ? null : host;
}

/** Lower-case host, no scheme, no `www.`, no trailing slash, no query or fragment. */
export function NormalizeLinkedInURL(value: string | null | undefined): string | null {
    if (value == null) return null;
    const trimmed = value.trim();
    if (trimmed === '') return null;
    const withoutScheme = trimmed.replace(/^[a-z][a-z0-9+.-]*:\/\//i, '');
    const [hostAndPath] = withoutScheme.split(/[?#]/);
    const slash = hostAndPath.indexOf('/');
    const host = (slash < 0 ? hostAndPath : hostAndPath.slice(0, slash)).toLowerCase().replace(/^www\./, '');
    const path = slash < 0 ? '' : hostAndPath.slice(slash).replace(/\/+$/, '');
    return `${host}${path}`;
}

/** Lower-cased, trimmed, de-duplicated, blanks dropped; order of first appearance kept. */
export function NormalizeEmails(values: ReadonlyArray<string | null | undefined>): string[] {
    const seen = new Set<string>();
    const out: string[] = [];
    for (const value of values) {
        const email = (value ?? '').trim().toLowerCase();
        if (email === '' || seen.has(email)) continue;
        seen.add(email);
        out.push(email);
    }
    return out;
}
