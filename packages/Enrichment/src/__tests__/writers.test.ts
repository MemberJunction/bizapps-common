import { describe, expect, it } from 'vitest';
import type { EnrichedEducation, EnrichedEmployment, PersonEnrichmentResult } from '../types.js';
import { EducationKey, PlanEducation } from '../writers/education-writer.js';
import { PlanEmployment } from '../writers/employment-writer.js';
import { PlanIdentity } from '../writers/identity-writer.js';
import { PlanLinkedIn } from '../writers/linkedin-writer.js';
import type { EducationRow, EmploymentRow, IdentityRow } from '../writers/plan-types.js';

const now = new Date('2026-10-12T12:00:00Z');
const earlier = new Date('2026-01-01T00:00:00Z');

function result(overrides: Partial<PersonEnrichmentResult>): PersonEnrichmentResult {
    return { PersonID: 'P1', Status: 'Matched', ExternalID: 'ext-1', MatchedBy: null, MatchConfidence: 0.9, LinkedInURL: null, Education: [], Employment: [], ErrorMessage: null, ...overrides };
}

function identity(overrides: Partial<IdentityRow>): IdentityRow {
    return { ID: 'I1', PersonID: 'P1', SourceSystem: 'Fixture', ExternalID: 'ext-old', MatchStatus: 'Matched', MatchedBy: 'Email', MatchConfidence: 0.8, LastCheckedAt: earlier, LastMatchedAt: earlier, ...overrides };
}

describe('PlanIdentity', () => {
    it('marks Ambiguous and clears the ExternalID when another person holds the vendor ID', () => {
        const plan = PlanIdentity({ Result: result({}), Existing: null, HeldByAnotherPerson: true, InferredMatchedBy: 'Email', Now: now });
        expect(plan).toMatchObject({ Action: 'Ambiguous', ExternalID: null, MatchedBy: null, MatchConfidence: null, LastCheckedAt: now, LastMatchedAt: null });
    });
    it('upserts a clean match with the inferred MatchedBy when the provider reports none', () => {
        const plan = PlanIdentity({ Result: result({ MatchConfidence: 1.7 }), Existing: null, HeldByAnotherPerson: false, InferredMatchedBy: 'LinkedIn', Now: now });
        expect(plan).toMatchObject({ Action: 'Matched', ExternalID: 'ext-1', MatchedBy: 'LinkedIn', MatchConfidence: 1, LastCheckedAt: now, LastMatchedAt: now });
    });
    it('prefers the provider-reported MatchedBy', () => {
        const plan = PlanIdentity({ Result: result({ MatchedBy: 'ExternalID' }), Existing: null, HeldByAnotherPerson: false, InferredMatchedBy: 'Email', Now: now });
        expect(plan.MatchedBy).toBe('ExternalID');
    });
    it('keeps a previously known ExternalID on NotFound', () => {
        const plan = PlanIdentity({ Result: result({ Status: 'NotFound', ExternalID: null }), Existing: identity({}), HeldByAnotherPerson: false, InferredMatchedBy: 'Email', Now: now });
        expect(plan).toMatchObject({ Action: 'NotFound', ExternalID: 'ext-old', MatchedBy: 'Email', MatchConfidence: 0.8, LastCheckedAt: now, LastMatchedAt: earlier });
    });
    it('writes nothing on Error', () => {
        expect(PlanIdentity({ Result: result({ Status: 'Error', ErrorMessage: 'boom' }), Existing: identity({}), HeldByAnotherPerson: false, InferredMatchedBy: 'Email', Now: now }).Action).toBe('None');
    });
    it('treats a Matched result without an ExternalID as NotFound', () => {
        const plan = PlanIdentity({ Result: result({ ExternalID: '  ' }), Existing: identity({}), HeldByAnotherPerson: false, InferredMatchedBy: 'Email', Now: now });
        expect(plan.Action).toBe('NotFound');
        expect(plan.ExternalID).toBe('ext-old');
    });
});

const hks: EnrichedEducation = { InstitutionName: 'Harvard Kennedy School', InstitutionExternalID: null, Degree: 'MPP', FieldOfStudy: 'Public Policy', StartDate: '2010-09-01', EndDate: '2012-05-31' };

function education(overrides: Partial<EducationRow>): EducationRow {
    return { ID: 'E1', PersonID: 'P1', OrganizationID: null, InstitutionName: 'The Harvard Kennedy School', Degree: 'M.P.P.', FieldOfStudy: null, StartDate: null, EndDate: '2012-06-15', Source: 'Enrichment', SourceSystem: 'Fixture', ...overrides };
}

describe('PlanEducation', () => {
    it('keys on normalized institution, normalized degree and end year', () => {
        expect(EducationKey('The Harvard Kennedy School', 'M.P.P.', '2012-06-15')).toBe(EducationKey('Harvard Kennedy School', 'MPP', '2012-05-31'));
        expect(EducationKey('HKS', 'MPP', '2012-05-31')).not.toBe(EducationKey('HKS', 'MPA', '2012-05-31'));
    });
    it('inserts when nothing matches, with the resolved school Organization', () => {
        const plan = PlanEducation({ Education: [hks], Existing: [], ProviderCode: 'Fixture', OrganizationIDs: new Map([['harvard kennedy school', 'ORG-HKS']]) });
        expect(plan.Inserts).toEqual([{ InstitutionName: 'Harvard Kennedy School', OrganizationID: 'ORG-HKS', Degree: 'MPP', FieldOfStudy: 'Public Policy', StartDate: '2010-09-01', EndDate: '2012-05-31' }]);
    });
    it('never edits a Manual row', () => {
        const plan = PlanEducation({ Education: [hks], Existing: [education({ Source: 'Manual' })], ProviderCode: 'Fixture', OrganizationIDs: new Map() });
        expect(plan.Inserts).toHaveLength(0);
        expect(plan.Updates).toHaveLength(0);
        expect(plan.SkippedManual).toBe(1);
    });
    it('updates its own row and fills OrganizationID only when it was NULL', () => {
        const plan = PlanEducation({ Education: [hks], Existing: [education({})], ProviderCode: 'Fixture', OrganizationIDs: new Map([['harvard kennedy school', 'ORG-HKS']]) });
        expect(plan.Updates).toEqual([{ ID: 'E1', FieldOfStudy: 'Public Policy', StartDate: '2010-09-01', EndDate: '2012-05-31', OrganizationID: 'ORG-HKS' }]);
        const kept = PlanEducation({ Education: [hks], Existing: [education({ OrganizationID: 'ORG-OLD' })], ProviderCode: 'Fixture', OrganizationIDs: new Map([['harvard kennedy school', 'ORG-HKS']]) });
        expect(kept.Updates[0].OrganizationID).toBe('ORG-OLD');
    });
    it('corroborates another system\'s or an Import row without duplicating it', () => {
        const other = PlanEducation({ Education: [hks], Existing: [education({ SourceSystem: 'PDL' })], ProviderCode: 'Fixture', OrganizationIDs: new Map() });
        const imported = PlanEducation({ Education: [hks], Existing: [education({ Source: 'Import', SourceSystem: 'CSV' })], ProviderCode: 'Fixture', OrganizationIDs: new Map() });
        expect(other).toMatchObject({ Corroborated: 1, Inserts: [], Updates: [] });
        expect(imported).toMatchObject({ Corroborated: 1, Inserts: [], Updates: [] });
    });
    it('collapses duplicate entries from the vendor and ignores blank institutions', () => {
        const plan = PlanEducation({ Education: [hks, { ...hks, Degree: 'M.P.P.' }, { ...hks, InstitutionName: ' ' }], Existing: [], ProviderCode: 'Fixture', OrganizationIDs: new Map() });
        expect(plan.Inserts).toHaveLength(1);
    });
});

const labs: EnrichedEmployment = { OrganizationName: 'Fixture Labs', OrganizationDomain: 'fixturelabs.test', Title: 'Policy Analyst', StartDate: '2012-07-01', EndDate: null, IsCurrent: true };
const industries: EnrichedEmployment = { OrganizationName: 'Fixture Industries', OrganizationDomain: null, Title: 'Director', StartDate: '2020-02-01', EndDate: null, IsCurrent: true };

function employment(overrides: Partial<EmploymentRow>): EmploymentRow {
    return { ID: 'R1', FromPersonID: 'P1', ToOrganizationID: 'ORG-LABS', Title: 'policy analyst', StartDate: '2012-07-01', EndDate: null, Status: 'Active', Source: 'Enrichment', SourceSystem: 'Fixture', ...overrides };
}

describe('PlanEmployment', () => {
    const base = { ProviderCode: 'Fixture', Today: '2026-10-12', Policy: 'CurrentEmployerOnly' as const };
    it('inserts against a resolved Organization', () => {
        const plan = PlanEmployment({ ...base, Employment: [labs], Existing: [], Resolved: [{ ID: 'ORG-LABS', Name: 'Fixture Labs', Website: null }] });
        expect(plan.Inserts).toEqual([{ Organization: { ID: 'ORG-LABS', Name: 'Fixture Labs', Website: null }, Title: 'Policy Analyst', StartDate: '2012-07-01', EndDate: null, Status: 'Active' }]);
    });
    it('matches an existing row by normalized title or by start date, and skips Manual rows', () => {
        const byTitle = PlanEmployment({ ...base, Employment: [labs], Existing: [employment({ Source: 'Manual', StartDate: null })], Resolved: [{ ID: 'ORG-LABS', Name: 'Fixture Labs', Website: null }] });
        expect(byTitle).toMatchObject({ Inserts: [], SkippedManual: 1 });
        const byDate = PlanEmployment({ ...base, Employment: [{ ...labs, Title: 'Analyst II' }], Existing: [employment({ Source: 'Import' })], Resolved: [{ ID: 'ORG-LABS', Name: 'Fixture Labs', Website: null }] });
        expect(byDate.SkippedManual).toBe(1);
    });
    it('leaves another vendor\'s row alone', () => {
        const plan = PlanEmployment({ ...base, Employment: [labs], Existing: [employment({ SourceSystem: 'PDL' })], Resolved: [{ ID: 'ORG-LABS', Name: 'Fixture Labs', Website: null }] });
        expect(plan).toMatchObject({ Inserts: [], Updates: [], SkippedOtherSystem: 1 });
    });
    it('updates its own row, ending it when the vendor says not current', () => {
        const plan = PlanEmployment({ ...base, Employment: [{ ...labs, IsCurrent: false, EndDate: null }], Existing: [employment({})], Resolved: [{ ID: 'ORG-LABS', Name: 'Fixture Labs', Website: null }] });
        expect(plan.Updates).toEqual([{ ID: 'R1', Title: 'Policy Analyst', StartDate: '2012-07-01', EndDate: '2026-10-12', Status: 'Ended' }]);
    });
    it('ends only its own Active rows whose Organization the vendor no longer lists as current', () => {
        const plan = PlanEmployment({ ...base, Employment: [industries], Existing: [employment({}), employment({ ID: 'R2', ToOrganizationID: 'ORG-X', Source: 'Manual' }), employment({ ID: 'R3', ToOrganizationID: 'ORG-Y', SourceSystem: 'PDL' })], Resolved: [{ ID: null, Name: 'Fixture Industries', Website: null }] });
        expect(plan.Ends).toEqual([{ ID: 'R1', EndDate: '2026-10-12' }]);
    });
    it('applies the create policy matrix', () => {
        const past = { ...labs, IsCurrent: false };
        const creatable = { ID: null, Name: 'Fixture Labs', Website: null };
        expect(PlanEmployment({ ...base, Policy: 'Never', Employment: [labs], Existing: [], Resolved: [creatable] })).toMatchObject({ Inserts: [], SkippedUnresolved: 1 });
        expect(PlanEmployment({ ...base, Policy: 'CurrentEmployerOnly', Employment: [labs, past], Existing: [], Resolved: [creatable, creatable] })).toMatchObject({ SkippedUnresolved: 1 });
        expect(PlanEmployment({ ...base, Policy: 'CurrentEmployerOnly', Employment: [labs, past], Existing: [], Resolved: [creatable, creatable] }).Inserts).toHaveLength(1);
        expect(PlanEmployment({ ...base, Policy: 'AllEmployers', Employment: [labs, past], Existing: [], Resolved: [creatable, creatable] }).Inserts).toHaveLength(2);
    });
    it('counts an ambiguous Organization as unresolved', () => {
        expect(PlanEmployment({ ...base, Employment: [labs], Existing: [], Resolved: [null] }).SkippedUnresolved).toBe(1);
    });
});

describe('PlanLinkedIn', () => {
    it('inserts only when the person has none', () => {
        expect(PlanLinkedIn('https://www.linkedin.com/in/ada/', null)).toEqual({ Insert: 'https://www.linkedin.com/in/ada/' });
        expect(PlanLinkedIn('https://www.linkedin.com/in/ada/', 'linkedin.com/in/other')).toEqual({ Insert: null });
        expect(PlanLinkedIn(null, null)).toEqual({ Insert: null });
        expect(PlanLinkedIn('   ', null)).toEqual({ Insert: null });
    });
});
