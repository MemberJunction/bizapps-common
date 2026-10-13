import { describe, expect, it } from 'vitest';
import { ResultCodeFor } from '../custom/enrich-people.action.js';
import { ParseEnrichPeopleParams } from '../custom/enrich-people.params.js';

describe('ParseEnrichPeopleParams', () => {
    it('applies the documented defaults', () => {
        const parsed = ParseEnrichPeopleParams({ ProviderCode: 'Apollo' });
        expect(parsed.Errors).toEqual([]);
        expect(parsed.Input).toEqual({
            ProviderCode: 'Apollo', PersonFilter: null, MaxPeople: 500, Facets: ['Education', 'Employment', 'LinkedIn'], Mode: 'Run', CompanyID: null,
            RefreshMatchedDays: 180, RetryNotFoundDays: 90, CreateOrganizations: 'CurrentEmployerOnly', TimeBudgetMinutes: 45, AllowNonLiveProvider: false,
        });
    });
    it('reads params case-insensitively, as strings or numbers, and trims', () => {
        const parsed = ParseEnrichPeopleParams({ providercode: ' PDL ', maxpeople: '25', facets: 'education, linkedin', mode: 'preview', createorganizations: 'never', TimeBudgetMinutes: 10, personfilter: ' Email IS NOT NULL ' });
        expect(parsed.Input).toMatchObject({ ProviderCode: 'PDL', MaxPeople: 25, Facets: ['Education', 'LinkedIn'], Mode: 'Preview', CreateOrganizations: 'Never', TimeBudgetMinutes: 10, PersonFilter: 'Email IS NOT NULL' });
    });
    it('reads AllowNonLiveProvider as a flag', () => {
        expect(ParseEnrichPeopleParams({ ProviderCode: 'X', AllowNonLiveProvider: 'true' }).Input?.AllowNonLiveProvider).toBe(true);
        expect(ParseEnrichPeopleParams({ ProviderCode: 'X', allownonliveprovider: 1 }).Input?.AllowNonLiveProvider).toBe(true);
        expect(ParseEnrichPeopleParams({ ProviderCode: 'X', AllowNonLiveProvider: 'no' }).Input?.AllowNonLiveProvider).toBe(false);
    });
    it('accepts Facets as an array and de-duplicates', () => {
        expect(ParseEnrichPeopleParams({ ProviderCode: 'X', Facets: ['Education', 'education'] }).Input?.Facets).toEqual(['Education']);
    });
    it('lists every problem at once', () => {
        const parsed = ParseEnrichPeopleParams({ MaxPeople: '0', Facets: 'Photos', Mode: 'Dry', CreateOrganizations: 'Some', RetryNotFoundDays: '1.5' });
        expect(parsed.Input).toBeNull();
        expect(parsed.Errors).toHaveLength(6);
        expect(parsed.Errors.join(' ')).toContain('ProviderCode is required.');
        expect(parsed.Errors.join(' ')).toContain('MaxPeople must be an integer from 1 to 5000.');
        expect(parsed.Errors.join(' ')).toContain("Facets contains 'Photos'");
        expect(parsed.Errors.join(' ')).toContain('Mode must be one of Run, Preview.');
    });
});

describe('ResultCodeFor', () => {
    it('maps every stop reason to its code and success flag', () => {
        expect(ResultCodeFor('Completed')).toEqual({ Code: 'SUCCESS', Success: true });
        expect(ResultCodeFor('MaxPeople')).toEqual({ Code: 'SUCCESS', Success: true });
        expect(ResultCodeFor('TimeBudget')).toEqual({ Code: 'PARTIAL', Success: true });
        expect(ResultCodeFor('RateLimited')).toEqual({ Code: 'PARTIAL', Success: true });
        expect(ResultCodeFor('QuotaExhausted')).toEqual({ Code: 'QUOTA_EXHAUSTED', Success: false });
        expect(ResultCodeFor('ErrorThreshold')).toEqual({ Code: 'ERROR_THRESHOLD', Success: false });
    });
});
