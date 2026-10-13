import { describe, expect, it } from 'vitest';
import { BuildEligibilityFilter, CutoffIso } from '../selection.js';

const base = {
    SchemaName: 'App_Common',
    PeopleView: 'vwPeople',
    ContactMethodsView: 'vwContactMethods',
    IdentitiesView: 'vwPersonExternalIdentities',
    ProviderCode: 'Apollo',
    Now: new Date('2026-10-12T12:00:00.000Z'),
    RefreshMatchedDays: 180,
    RetryNotFoundDays: 90,
    PersonFilter: null,
};

describe('BuildEligibilityFilter', () => {
    it('produces the exact filter for a fixed clock', () => {
        expect(BuildEligibilityFilter(base)).toBe(
            `Status = 'Active' AND (Email IS NOT NULL OR EXISTS (SELECT 1 FROM [App_Common].[vwContactMethods] cm WHERE cm.PersonID = [App_Common].[vwPeople].ID AND cm.ContactType IN ('Email','LinkedIn'))) AND NOT EXISTS (SELECT 1 FROM [App_Common].[vwPersonExternalIdentities] pei WHERE pei.PersonID = [App_Common].[vwPeople].ID AND pei.SourceSystem = 'Apollo' AND (pei.MatchStatus = 'Ambiguous' OR (pei.MatchStatus = 'Matched' AND pei.LastCheckedAt > '2026-04-15T12:00:00Z') OR (pei.MatchStatus = 'NotFound' AND pei.LastCheckedAt > '2026-07-14T12:00:00Z')))`,
        );
    });
    it('appends a supplied person filter in parentheses', () => {
        expect(BuildEligibilityFilter({ ...base, PersonFilter: " Email LIKE '%@example.org' " })).toMatch(/ AND \(Email LIKE '%@example.org'\)$/);
        expect(BuildEligibilityFilter({ ...base, PersonFilter: '   ' })).not.toMatch(/\(\s*\)$/);
    });
    it('escapes a provider code containing a quote', () => {
        expect(BuildEligibilityFilter({ ...base, ProviderCode: "O'Hare" })).toContain(`pei.SourceSystem = 'O''Hare'`);
    });
    it('moves the cutoffs with the windows', () => {
        const wide = BuildEligibilityFilter({ ...base, RefreshMatchedDays: 1, RetryNotFoundDays: 2 });
        expect(wide).toContain(`'2026-10-11T12:00:00Z'`);
        expect(wide).toContain(`'2026-10-10T12:00:00Z'`);
    });
});

describe('CutoffIso', () => {
    it('subtracts days and drops milliseconds', () => {
        expect(CutoffIso(new Date('2026-03-01T00:00:00.123Z'), 1)).toBe('2026-02-28T00:00:00Z');
    });
});
