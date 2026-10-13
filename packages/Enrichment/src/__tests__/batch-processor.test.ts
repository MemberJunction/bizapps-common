import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { IMetadataProvider, UserInfo } from '@memberjunction/core';
import type { mjBizAppsCommonEnrichmentProviderEntity } from '@mj-biz-apps/common-entities';
import { BaseEnrichmentProvider } from '../BaseEnrichmentProvider.js';
import { EnrichmentQuotaExhaustedError, EnrichmentRateLimitError } from '../errors.js';
import type { BatchContext } from '../batch-context.js';
import type { EnrichmentContext, EnrichmentFacet, PersonEnrichmentRequest, PersonEnrichmentResult } from '../types.js';

const loadBatchContext = vi.fn();
const loadIdentityHolders = vi.fn();
const loadCandidates = vi.fn();
const createOrganizations = vi.fn();
const applyIdentity = vi.fn();
const applyEducation = vi.fn();
const applyEmployment = vi.fn();
const applyLinkedIn = vi.fn();

vi.mock('@memberjunction/core', async (importOriginal) => {
    const actual = await importOriginal<typeof import('@memberjunction/core')>();
    return { ...actual, RunInEntityTransaction: async (_provider: unknown, work: () => Promise<unknown>) => work(), LogError: () => undefined, LogStatus: () => undefined };
});
vi.mock('@memberjunction/record-set-processor', () => ({ RecordSetProcessor: { Instance: { Process: vi.fn() } } }));
vi.mock('@memberjunction/record-set-processor-base', () => ({ KeysetSource: class {} }));
vi.mock('../batch-context.js', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../batch-context.js')>();
    return { ...actual, LoadBatchContext: loadBatchContext, LoadIdentityHolders: loadIdentityHolders };
});
vi.mock('../organization-resolver.js', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../organization-resolver.js')>();
    return { ...actual, LoadOrganizationCandidates: loadCandidates, CreateOrganizations: createOrganizations };
});
vi.mock('../writers/identity-writer.js', async (importOriginal) => ({ ...(await importOriginal<typeof import('../writers/identity-writer.js')>()), ApplyIdentity: applyIdentity }));
vi.mock('../writers/education-writer.js', async (importOriginal) => ({ ...(await importOriginal<typeof import('../writers/education-writer.js')>()), ApplyEducation: applyEducation }));
vi.mock('../writers/employment-writer.js', async (importOriginal) => ({ ...(await importOriginal<typeof import('../writers/employment-writer.js')>()), ApplyEmployment: applyEmployment }));
vi.mock('../writers/linkedin-writer.js', async (importOriginal) => ({ ...(await importOriginal<typeof import('../writers/linkedin-writer.js')>()), ApplyLinkedIn: applyLinkedIn }));

const { EnrichmentBatchProcessor } = await import('../EnrichmentBatchProcessor.js');

type Outcome = PersonEnrichmentResult | Error;

class ScriptedProvider extends BaseEnrichmentProvider {
    public Script = new Map<string, Outcome>();
    public Requests: PersonEnrichmentRequest[][] = [];
    public get Code(): string { return 'Fixture'; }
    public get IsLive(): boolean { return false; }
    public get SupportedFacets(): EnrichmentFacet[] { return ['Education', 'Employment', 'LinkedIn']; }
    public async Initialize(): Promise<void> {}
    public async EnrichPeople(requests: PersonEnrichmentRequest[]): Promise<PersonEnrichmentResult[]> {
        this.Requests.push(requests);
        const out: PersonEnrichmentResult[] = [];
        for (const request of requests) {
            const outcome = this.Script.get(request.PersonID) ?? notFound(request.PersonID);
            if (outcome instanceof Error) throw outcome;
            out.push(outcome);
        }
        return out;
    }
}

function notFound(personID: string): PersonEnrichmentResult {
    return { PersonID: personID, Status: 'NotFound', ExternalID: null, MatchedBy: null, MatchConfidence: null, LinkedInURL: null, Education: [], Employment: [], ErrorMessage: null };
}

function matched(personID: string, externalID: string): PersonEnrichmentResult {
    return {
        ...notFound(personID),
        Status: 'Matched',
        ExternalID: externalID,
        MatchConfidence: 0.9,
        LinkedInURL: 'https://linkedin.com/in/x',
        Education: [{ InstitutionName: 'HKS', InstitutionExternalID: null, Degree: 'MPP', FieldOfStudy: null, StartDate: null, EndDate: '2012-05-31' }],
        Employment: [{ OrganizationName: 'Fixture Labs', OrganizationDomain: 'fixturelabs.test', Title: 'Analyst', StartDate: '2012-07-01', EndDate: null, IsCurrent: true }],
    };
}

function context(ids: string[], identities: Record<string, { ID: string; ExternalID: string | null; MatchStatus: 'Matched' | 'NotFound' | 'Ambiguous' }> = {}): BatchContext {
    const people = new Map(ids.map((id) => [id.toLowerCase(), { ID: id, FirstName: 'First', LastName: id, Email: `${id.toLowerCase()}@fixture.test`, Status: 'Active' }]));
    const identityRows = new Map(Object.entries(identities).map(([personID, row]) => [personID.toLowerCase(), { ...row, PersonID: personID, SourceSystem: 'Fixture', MatchedBy: null, MatchConfidence: null, LastCheckedAt: new Date(), LastMatchedAt: null }]));
    return { People: people, ContactMethods: new Map(), EmployeeRelationships: new Map(), Educations: new Map(), Identities: identityRows as unknown as BatchContext['Identities'], Organizations: new Map() };
}

const lookups = { EmployeeTypeID: 'RT-EMP', EmailContactTypeID: 'CT-EMAIL', LinkedInContactTypeID: 'CT-LI' };
const providerRow = { Code: 'Fixture', MaxBatchSize: 10 } as unknown as mjBizAppsCommonEnrichmentProviderEntity;

function processor(provider: ScriptedProvider, facets: EnrichmentFacet[] = ['Education', 'Employment', 'LinkedIn']) {
    const enrichment: EnrichmentContext = { ContextUser: {} as UserInfo, MetadataProvider: {} as IMetadataProvider, ProviderRow: providerRow, CompanyID: null, Facets: facets };
    return new EnrichmentBatchProcessor({ Plugin: provider, Context: enrichment, Lookups: lookups, Policy: 'CurrentEmployerOnly', Now: () => new Date('2026-10-12T12:00:00Z') });
}

const refs = (ids: string[]) => ids.map((id) => ({ EntityID: 'E', RecordID: id }));
const rspContext = { contextUser: {} as UserInfo, provider: {} as IMetadataProvider };

beforeEach(() => {
    vi.clearAllMocks();
    loadIdentityHolders.mockResolvedValue(new Map());
    loadCandidates.mockResolvedValue([]);
    createOrganizations.mockResolvedValue({ IDs: new Map(), Created: 0, Message: null });
    applyIdentity.mockResolvedValue({ Saved: true, Message: null });
    applyEducation.mockResolvedValue({ Created: 1, Updated: 0, Message: null });
    applyEmployment.mockResolvedValue({ Created: 1, Updated: 0, Ended: 0, Message: null });
    applyLinkedIn.mockResolvedValue({ Added: 1, Message: null });
});

describe('EnrichmentBatchProcessor.ProcessBatch', () => {
    it('skips the whole batch and sets StopReason on a rate limit, then keeps skipping', async () => {
        const provider = new ScriptedProvider();
        provider.Script.set('P1', new EnrichmentRateLimitError('429'));
        loadBatchContext.mockResolvedValue(context(['P1', 'P2']));
        const p = processor(provider);
        const results = await p.ProcessBatch(refs(['P1', 'P2']), rspContext);
        expect(p.StopReason).toBe('RateLimited');
        expect([...results.values()].map((r) => r.Status)).toEqual(['Skipped', 'Skipped']);
        expect(applyIdentity).not.toHaveBeenCalled();
        const again = await p.ProcessBatch(refs(['P3']), rspContext);
        expect(again.get('P3')?.Status).toBe('Skipped');
        expect(provider.Requests).toHaveLength(1);
    });
    it('maps exhausted credits to QuotaExhausted with skipped records', async () => {
        const provider = new ScriptedProvider();
        provider.Script.set('P1', new EnrichmentQuotaExhaustedError('402'));
        loadBatchContext.mockResolvedValue(context(['P1']));
        const p = processor(provider);
        await p.ProcessBatch(refs(['P1']), rspContext);
        expect(p.StopReason).toBe('QuotaExhausted');
    });
    it('writes a matched person: history first, identity last, with SkipEntityActions on first-time enrichment', async () => {
        const provider = new ScriptedProvider();
        provider.Script.set('P1', matched('P1', 'ext-1'));
        loadBatchContext.mockResolvedValue(context(['P1']));
        const p = processor(provider);
        const results = await p.ProcessBatch(refs(['P1']), rspContext);
        expect(results.get('P1')?.Status).toBe('Succeeded');
        expect(p.Counts).toEqual({ Matched: 1, NotFound: 0, Ambiguous: 0, Errored: 0 });
        expect(p.WriteCounts).toMatchObject({ EducationCreated: 1, RelationshipsCreated: 1, LinkedInAdded: 1 });
        expect(applyEmployment.mock.calls[0][0].SkipEntityActions).toBe(true);
        expect(applyIdentity.mock.invocationCallOrder[0]).toBeGreaterThan(applyLinkedIn.mock.invocationCallOrder[0]);
        expect(applyIdentity.mock.calls[0][0]).toMatchObject({ Action: 'Matched', ExternalID: 'ext-1', MatchedBy: 'Email' });
    });
    it('saves relationships normally once the person has an identity row', async () => {
        const provider = new ScriptedProvider();
        provider.Script.set('P1', matched('P1', 'ext-1'));
        loadBatchContext.mockResolvedValue(context(['P1'], { P1: { ID: 'I1', ExternalID: 'ext-1', MatchStatus: 'Matched' } }));
        await processor(provider).ProcessBatch(refs(['P1']), rspContext);
        expect(applyEmployment.mock.calls[0][0].SkipEntityActions).toBe(false);
    });
    it('marks Ambiguous and writes nothing else when another person holds the vendor ID', async () => {
        const provider = new ScriptedProvider();
        provider.Script.set('P1', matched('P1', 'ext-shared'));
        loadBatchContext.mockResolvedValue(context(['P1']));
        loadIdentityHolders.mockResolvedValue(new Map([['ext-shared', 'P-OTHER']]));
        const p = processor(provider);
        const results = await p.ProcessBatch(refs(['P1']), rspContext);
        expect(results.get('P1')?.Status).toBe('Succeeded');
        expect(p.Counts.Ambiguous).toBe(1);
        expect(applyEducation).not.toHaveBeenCalled();
        expect(applyEmployment).not.toHaveBeenCalled();
        expect(applyIdentity.mock.calls[0][0]).toMatchObject({ Action: 'Ambiguous', ExternalID: null });
    });
    it('treats the person\'s own existing row as not a conflict', async () => {
        const provider = new ScriptedProvider();
        provider.Script.set('P1', matched('P1', 'ext-1'));
        loadBatchContext.mockResolvedValue(context(['P1']));
        loadIdentityHolders.mockResolvedValue(new Map([['ext-1', 'p1']]));
        const p = processor(provider);
        await p.ProcessBatch(refs(['P1']), rspContext);
        expect(p.Counts.Matched).toBe(1);
    });
    it('fails a provider Error and a failed save so the person is retried, and rolls the person back', async () => {
        const provider = new ScriptedProvider();
        provider.Script.set('P1', { ...notFound('P1'), Status: 'Error', ErrorMessage: 'vendor 500' });
        provider.Script.set('P2', matched('P2', 'ext-2'));
        applyEducation.mockResolvedValueOnce({ Created: 0, Updated: 0, Message: 'constraint violated' });
        loadBatchContext.mockResolvedValue(context(['P1', 'P2']));
        const p = processor(provider);
        const results = await p.ProcessBatch(refs(['P1', 'P2']), rspContext);
        expect(results.get('P1')).toMatchObject({ Status: 'Failed', ErrorMessage: 'vendor 500' });
        expect(results.get('P2')).toMatchObject({ Status: 'Failed', ErrorMessage: 'constraint violated' });
        expect(p.Counts.Errored).toBe(2);
        expect(applyIdentity).not.toHaveBeenCalled();
    });
    it('writes only the requested facets', async () => {
        const provider = new ScriptedProvider();
        provider.Script.set('P1', matched('P1', 'ext-1'));
        loadBatchContext.mockResolvedValue(context(['P1']));
        await processor(provider, ['Education']).ProcessBatch(refs(['P1']), rspContext);
        expect(applyEducation).toHaveBeenCalledTimes(1);
        expect(applyEmployment).not.toHaveBeenCalled();
        expect(applyLinkedIn).not.toHaveBeenCalled();
    });
    it('skips people nothing identifies and people the batch could not load', async () => {
        const provider = new ScriptedProvider();
        const ctx = context(['P1']);
        ctx.People.get('p1')!.Email = null;
        loadBatchContext.mockResolvedValue(ctx);
        const results = await processor(provider).ProcessBatch(refs(['P1', 'P-MISSING']), rspContext);
        expect(results.get('P1')?.Status).toBe('Skipped');
        expect(results.get('P-MISSING')?.Status).toBe('Skipped');
        expect(provider.Requests).toEqual([]);
    });
    it('fails a person the provider forgot to answer', async () => {
        const provider = new ScriptedProvider();
        provider.EnrichPeople = async () => [];
        loadBatchContext.mockResolvedValue(context(['P1']));
        const results = await processor(provider).ProcessBatch(refs(['P1']), rspContext);
        expect(results.get('P1')).toMatchObject({ Status: 'Failed' });
    });
});
