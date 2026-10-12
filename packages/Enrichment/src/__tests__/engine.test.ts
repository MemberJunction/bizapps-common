import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { IMetadataProvider, UserInfo } from '@memberjunction/core';
import { MJGlobal } from '@memberjunction/global';
import { BaseEnrichmentProvider } from '../BaseEnrichmentProvider.js';
import { EnrichmentRefusedError } from '../errors.js';
import type { EnrichmentContext, EnrichmentFacet, PersonEnrichmentRequest, PersonEnrichmentResult, PersonEnrichmentRunOptions } from '../types.js';

const runView = vi.fn();
const runViews = vi.fn();
const process = vi.fn();
const loadLookups = vi.fn();

vi.mock('@memberjunction/core', async (importOriginal) => {
    const actual = await importOriginal<typeof import('@memberjunction/core')>();
    class FakeRunView {
        public RunView = runView;
        public RunViews = runViews;
        public static FromMetadataProvider(): FakeRunView { return new FakeRunView(); }
    }
    return { ...actual, RunView: FakeRunView, LogStatus: () => undefined, LogError: () => undefined };
});
vi.mock('@memberjunction/record-set-processor', () => ({ RecordSetProcessor: { Instance: { Process: process } } }));
vi.mock('@memberjunction/record-set-processor-base', () => ({ KeysetSource: class { constructor(public entity: string, public filter: string) {} } }));
vi.mock('../batch-context.js', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../batch-context.js')>();
    return { ...actual, LoadRunLookups: loadLookups };
});

const { PersonEnrichmentEngine, StoppedReasonOf } = await import('../PersonEnrichmentEngine.js');

class TestProvider extends BaseEnrichmentProvider {
    public static Live = true;
    public static Calls = 0;
    public get Code(): string { return 'Test'; }
    public get IsLive(): boolean { return TestProvider.Live; }
    public get SupportedFacets(): EnrichmentFacet[] { return ['Education', 'Employment', 'LinkedIn']; }
    public async Initialize(_context: EnrichmentContext): Promise<void> {}
    public async EnrichPeople(requests: PersonEnrichmentRequest[]): Promise<PersonEnrichmentResult[]> {
        TestProvider.Calls += 1;
        return requests.map((request) => ({ PersonID: request.PersonID, Status: 'NotFound', ExternalID: null, MatchedBy: null, MatchConfidence: null, LinkedInURL: null, Education: [], Employment: [], ErrorMessage: null }));
    }
}
MJGlobal.Instance.ClassFactory.Register(BaseEnrichmentProvider, TestProvider, 'TestDriver');

const providerRow = { ID: 'PROV-1', Code: 'Test', DriverClass: 'TestDriver', IsActive: true, MaxBatchSize: 10, RequestsPerMinute: null, CreditPrice: 0.5, CreditCurrency: 'USD' };
const entityInfo = (name: string) => ({ Name: name, SchemaName: 'App_Common', BaseView: `vw${name.split(': ')[1].replace(/\s/g, '')}` });
const metadataProvider = { EntityByName: (name: string) => entityInfo(name), GetEntityObject: vi.fn() } as unknown as IMetadataProvider;
const user = { ID: 'U1', Name: 'tester' } as unknown as UserInfo;

function options(overrides: Partial<PersonEnrichmentRunOptions> = {}): PersonEnrichmentRunOptions {
    return { ProviderCode: 'Test', PersonFilter: null, MaxPeople: 500, Facets: ['Education', 'Employment', 'LinkedIn'], Mode: 'Run', CompanyID: null, RefreshMatchedDays: 180, RetryNotFoundDays: 90, CreateOrganizations: 'CurrentEmployerOnly', TimeBudgetMinutes: 45, AllowNonLiveProvider: false, ContextUser: user, MetadataProvider: metadataProvider, ...overrides };
}

beforeEach(() => {
    runView.mockReset();
    runViews.mockReset();
    process.mockReset();
    loadLookups.mockReset();
    TestProvider.Live = true;
    TestProvider.Calls = 0;
    runView.mockResolvedValue({ Success: true, Results: [providerRow], TotalRowCount: 1 });
    loadLookups.mockResolvedValue({ EmployeeTypeID: 'RT-EMP', EmailContactTypeID: 'CT-EMAIL', LinkedInContactTypeID: 'CT-LI' });
    process.mockResolvedValue({ Status: 'Completed', Processed: 3, Success: 3, Error: 0, Skipped: 0, Total: 3, ProcessRunID: 'RUN-1' });
});

async function refusal(run: Promise<unknown>): Promise<EnrichmentRefusedError> {
    try {
        await run;
    } catch (error) {
        if (error instanceof EnrichmentRefusedError) return error;
        throw error;
    }
    throw new Error('expected a refusal');
}

describe('PersonEnrichmentEngine.Run refusals', () => {
    it('rejects bad options before touching the database', async () => {
        const error = await refusal(new PersonEnrichmentEngine().Run(options({ MaxPeople: 0, RetryNotFoundDays: 0 })));
        expect(error.Code).toBe('VALIDATION_ERROR');
        expect(error.message).toContain('MaxPeople');
        expect(error.message).toContain('RetryNotFoundDays');
        expect(runView).not.toHaveBeenCalled();
    });
    it('rejects a PersonFilter that fails SQL validation', async () => {
        const error = await refusal(new PersonEnrichmentEngine().Run(options({ PersonFilter: "Email = 'x'; DROP TABLE People" })));
        expect(error.Code).toBe('VALIDATION_ERROR');
        expect(error.message).toContain('PersonFilter');
    });
    it('reports a missing provider row, an inactive one, and an unregistered driver class', async () => {
        runView.mockResolvedValueOnce({ Success: true, Results: [] });
        expect((await refusal(new PersonEnrichmentEngine().Run(options()))).Code).toBe('PROVIDER_NOT_FOUND');
        runView.mockResolvedValueOnce({ Success: true, Results: [{ ...providerRow, IsActive: false }] });
        expect((await refusal(new PersonEnrichmentEngine().Run(options()))).Code).toBe('PROVIDER_INACTIVE');
        runView.mockResolvedValueOnce({ Success: true, Results: [{ ...providerRow, DriverClass: 'NoSuchDriver' }] });
        const missing = await refusal(new PersonEnrichmentEngine().Run(options()));
        expect(missing.Code).toBe('PROVIDER_NOT_FOUND');
        expect(missing.message).toContain('NoSuchDriver');
    });
    it('refuses a non-live provider unless AllowNonLiveProvider is set', async () => {
        TestProvider.Live = false;
        expect((await refusal(new PersonEnrichmentEngine().Run(options()))).Code).toBe('VALIDATION_ERROR');
        const result = await new PersonEnrichmentEngine().Run(options({ AllowNonLiveProvider: true }));
        expect(result.StoppedReason).toBe('Completed');
    });
});

describe('PersonEnrichmentEngine.Run preview', () => {
    it('counts eligible people, prices an upper bound, and calls no vendor', async () => {
        runViews.mockResolvedValueOnce([
            { Success: true, Results: [], TotalRowCount: 1234 },
            { Success: true, Results: [{ Operation: 'Enrich', Unit: 'MatchedPerson', CreditsPerUnit: 2 }] },
        ]);
        const result = await new PersonEnrichmentEngine().Run(options({ Mode: 'Preview', MaxPeople: 200 }));
        expect(result.Eligible).toBe(1234);
        expect(result.EstimatedCredits).toBe(400);
        expect(result.EstimatedCost).toBe(200);
        expect(result.CostCurrency).toBe('USD');
        expect(result.Processed).toBe(0);
        expect(TestProvider.Calls).toBe(0);
        expect(process).not.toHaveBeenCalled();
        const [countParams] = runViews.mock.calls[0][0];
        expect(countParams.ResultType).toBe('count_only');
        expect(countParams.ExtraFilter).toContain("pei.SourceSystem = 'Test'");
    });
});

describe('PersonEnrichmentEngine.Run processing', () => {
    it('hands the processor the row\'s batch size, MaxPeople and the eligibility filter', async () => {
        await new PersonEnrichmentEngine().Run(options({ MaxPeople: 42 }));
        const passed = process.mock.calls[0][0];
        expect(passed.batchSize).toBe(10);
        expect(passed.maxRecords).toBe(42);
        expect(passed.errorThresholdPercent).toBe(20);
        expect(passed.triggeredBy).toBe('Manual');
        expect(passed.source.entity).toBe('MJ_BizApps_Common: People');
        expect(passed.source.filter).toContain("Status = 'Active'");
    });
    it('stops at MaxPeople, maps the vendor stop reasons, and prices consumed credits', async () => {
        process.mockResolvedValueOnce({ Status: 'Completed', Processed: 42, Success: 42, Error: 0, Skipped: 0, Total: null, ProcessRunID: 'RUN-2' });
        const result = await new PersonEnrichmentEngine().Run(options({ MaxPeople: 42 }));
        expect(result.StoppedReason).toBe('MaxPeople');
        expect(result.ProcessRunID).toBe('RUN-2');
        expect(result.CreditsConsumed).toBeNull();
    });
    it('turns a rate limit the processor reported into RateLimited through onAfterBatch', async () => {
        process.mockImplementationOnce(async (passed) => {
            passed.processor.StopReason = 'RateLimited';
            const verdict = await passed.onAfterBatch([], 5);
            expect(verdict).toEqual({ continue: false, reason: 'RateLimited' });
            return { Status: 'Paused', Processed: 5, Success: 0, Error: 0, Skipped: 5, Total: null, ProcessRunID: 'RUN-3' };
        });
        expect((await new PersonEnrichmentEngine().Run(options())).StoppedReason).toBe('RateLimited');
    });
    it('stops on the time budget', async () => {
        let tick = 0;
        const clock = () => new Date(Date.UTC(2026, 9, 12, 12, tick++ * 30));
        process.mockImplementationOnce(async (passed) => {
            const verdict = await passed.onAfterBatch([], 5);
            expect(verdict).toEqual({ continue: false, reason: 'TimeBudget' });
            return { Status: 'Paused', Processed: 5, Success: 5, Error: 0, Skipped: 0, Total: null, ProcessRunID: 'RUN-4' };
        });
        expect((await new PersonEnrichmentEngine(clock).Run(options({ TimeBudgetMinutes: 20 }))).StoppedReason).toBe('TimeBudget');
    });
    it('reports the circuit breaker as ErrorThreshold and rethrows any other processor failure', async () => {
        process.mockResolvedValueOnce({ Status: 'Failed', Processed: 10, Success: 5, Error: 5, Skipped: 0, Total: null, ErrorMessage: 'Error threshold exceeded' });
        expect((await new PersonEnrichmentEngine().Run(options())).StoppedReason).toBe('ErrorThreshold');
    });
});

describe('StoppedReasonOf', () => {
    it('prefers the processor\'s stop reason, then Failed, then MaxPeople, then Completed', () => {
        const run = (status: 'Completed' | 'Failed' | 'Paused', processed: number) => ({ Status: status, Processed: processed, Success: 0, Error: 0, Skipped: 0, Total: null });
        expect(StoppedReasonOf(run('Paused', 1), { StopReason: 'QuotaExhausted' }, 10)).toBe('QuotaExhausted');
        expect(StoppedReasonOf(run('Failed', 1), { StopReason: null }, 10)).toBe('ErrorThreshold');
        expect(StoppedReasonOf(run('Completed', 10), { StopReason: null }, 10)).toBe('MaxPeople');
        expect(StoppedReasonOf(run('Completed', 3), { StopReason: null }, 10)).toBe('Completed');
    });
});
