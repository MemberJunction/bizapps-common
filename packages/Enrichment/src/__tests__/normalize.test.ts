import { describe, expect, it } from 'vitest';
import { DomainFromWebsite, NormalizeDegree, NormalizeEmails, NormalizeLinkedInURL, NormalizeName, YearOf } from '../normalize.js';

describe('NormalizeName', () => {
    it('lower-cases, trims, collapses whitespace, strips punctuation and drops a leading "the"', () => {
        expect(NormalizeName('  The Harvard   Kennedy School. ')).toBe('harvard kennedy school');
        expect(NormalizeName('M.I.T.')).toBe('mit');
        expect(NormalizeName('Harvard-Kennedy / School')).toBe('harvard kennedy school');
        expect(NormalizeName('Theodore Inc')).toBe('theodore inc');
    });
    it('maps null and blank to the empty string', () => {
        expect(NormalizeName(null)).toBe('');
        expect(NormalizeName('   ')).toBe('');
    });
    it('keeps letters from any script and digits', () => {
        expect(NormalizeName('École 42')).toBe('école 42');
    });
});

describe('NormalizeDegree', () => {
    it('treats punctuation variants as the same degree', () => {
        expect(NormalizeDegree('M.P.P.')).toBe(NormalizeDegree('MPP'));
        expect(NormalizeDegree('M. P. P.')).toBe('mpp');
        expect(NormalizeDegree('Master of Public Policy')).toBe('masterofpublicpolicy');
    });
});

describe('YearOf', () => {
    it('reads the year of a day or ISO string and of a Date', () => {
        expect(YearOf('2012-05-31')).toBe('2012');
        expect(YearOf('2012-05-31T00:00:00Z')).toBe('2012');
        expect(YearOf(new Date(Date.UTC(1999, 0, 1)))).toBe('1999');
    });
    it('is empty when absent or unparseable', () => {
        expect(YearOf(null)).toBe('');
        expect(YearOf('May 2012')).toBe('');
    });
});

describe('DomainFromWebsite', () => {
    it('reduces a URL to a bare host', () => {
        expect(DomainFromWebsite('https://www.Acme.com/about?x=1')).toBe('acme.com');
        expect(DomainFromWebsite('acme.com/')).toBe('acme.com');
        expect(DomainFromWebsite('http://sub.acme.co.uk:8080/path')).toBe('sub.acme.co.uk');
    });
    it('is null for nothing', () => {
        expect(DomainFromWebsite(null)).toBeNull();
        expect(DomainFromWebsite('https://')).toBeNull();
    });
});

describe('NormalizeLinkedInURL', () => {
    it('lower-cases the host and strips scheme, www, trailing slash and query', () => {
        expect(NormalizeLinkedInURL('https://WWW.LinkedIn.com/in/Jane-Doe/?trk=x')).toBe('linkedin.com/in/Jane-Doe');
        expect(NormalizeLinkedInURL('linkedin.com/in/jane-doe')).toBe('linkedin.com/in/jane-doe');
    });
    it('is null when blank', () => {
        expect(NormalizeLinkedInURL('  ')).toBeNull();
    });
});

describe('NormalizeEmails', () => {
    it('lower-cases, trims, drops blanks and duplicates, keeps first-seen order', () => {
        expect(NormalizeEmails([' Jane@Example.com ', null, 'jane@example.com', '', 'x@y.z'])).toEqual(['jane@example.com', 'x@y.z']);
    });
});
