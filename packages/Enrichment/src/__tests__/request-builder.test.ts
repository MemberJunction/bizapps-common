import { describe, expect, it } from 'vitest';
import { BuildRequest, BuildRequests, InferMatchedBy, type PersonSnapshot } from '../request-builder.js';

const person: PersonSnapshot = {
    ID: 'P1',
    FirstName: 'Ada',
    LastName: 'Lovelace',
    Email: 'Ada@Example.com',
    ContactEmails: ['ada@example.com', 'ada.lovelace@work.example'],
    LinkedInURL: 'https://www.linkedin.com/in/ada/',
    CurrentEmployer: { Name: 'Analytical Engines', Website: 'https://www.analytical.example/' },
    MatchedExternalID: null,
};

describe('BuildRequest', () => {
    it('de-duplicates and lower-cases emails, normalizes the LinkedIn URL and the employer domain', () => {
        const request = BuildRequest(person);
        expect(request?.Emails).toEqual(['ada@example.com', 'ada.lovelace@work.example']);
        expect(request?.LinkedInURL).toBe('linkedin.com/in/ada');
        expect(request?.OrganizationDomain).toBe('analytical.example');
        expect(request?.OrganizationName).toBe('Analytical Engines');
        expect(request?.ExternalID).toBeNull();
    });
    it('returns null when nothing identifies the person', () => {
        expect(BuildRequest({ ...person, Email: null, ContactEmails: [], LinkedInURL: null, CurrentEmployer: null })).toBeNull();
        expect(BuildRequest({ ...person, FirstName: '', Email: null, ContactEmails: [], LinkedInURL: null })).toBeNull();
    });
});

describe('InferMatchedBy', () => {
    it('follows the identity priority', () => {
        const full = BuildRequest({ ...person, MatchedExternalID: 'ext-1' });
        expect(full && InferMatchedBy(full)).toBe('ExternalID');
        expect(InferMatchedBy(BuildRequest(person)!)).toBe('Email');
        expect(InferMatchedBy(BuildRequest({ ...person, Email: null, ContactEmails: [] })!)).toBe('LinkedIn');
        expect(InferMatchedBy(BuildRequest({ ...person, Email: null, ContactEmails: [], LinkedInURL: null })!)).toBe('NameAndDomain');
    });
});

describe('BuildRequests', () => {
    it('separates requests from people it had to skip', () => {
        const built = BuildRequests([person, { ...person, ID: 'P2', Email: null, ContactEmails: [], LinkedInURL: null, CurrentEmployer: null }]);
        expect(built.Requests.map((request) => request.PersonID)).toEqual(['P1']);
        expect(built.SkippedPersonIDs).toEqual(['P2']);
    });
});
