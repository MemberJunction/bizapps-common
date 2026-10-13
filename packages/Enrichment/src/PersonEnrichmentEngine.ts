import type { mjBizAppsCommonEnrichmentProviderEntity, mjBizAppsCommonEnrichmentProviderRateEntity } from '@mj-biz-apps/common-entities';
import { LogStatus, RunInEntityTransaction, RunView, type EntityInfo, type IMetadataProvider } from '@memberjunction/core';
import { EscapeSQLString, MJGlobal, SQLExpressionValidator } from '@memberjunction/global';
import { RecordSetProcessor } from '@memberjunction/record-set-processor';
import { KeysetSource, type ProcessRunResult, type RecordRef, type RecordSetProcessOptions } from '@memberjunction/record-set-processor-base';
import { BaseEnrichmentProvider } from './BaseEnrichmentProvider.js';
import { LoadRunLookups, type RunLookups } from './batch-context.js';
import { EstimateCost, type CostRate } from './cost-estimator.js';
import { EnrichmentBatchProcessor, type BatchDeps } from './EnrichmentBatchProcessor.js';
import { ENRICHMENT_ENTITIES } from './entity-names.js';
import { EnrichmentConfigurationError, EnrichmentRefusedError } from './errors.js';
import { BuildEligibilityFilter } from './selection.js';
import { AllEnrichmentFacets, EmptyWriteCounts, type EnrichmentContext, type EnrichmentFacet, type EnrichmentStoppedReason, type PersonEnrichmentRunOptions, type PersonEnrichmentRunResult } from './types.js';

export const MAX_PEOPLE_LIMIT = 5000;
export const ERROR_THRESHOLD_PERCENT = 20;

export const DefaultRunOptions = {
    MaxPeople: 500,
    RefreshMatchedDays: 180,
    RetryNotFoundDays: 90,
    TimeBudgetMinutes: 45,
    CreateOrganizations: 'CurrentEmployerOnly',
    Mode: 'Run',
} as const;

/** One run of the enrichment engine: select, batch, call the provider, write. Instantiate per run; there is no singleton. */
export class PersonEnrichmentEngine {
    private readonly now: () => Date;

    constructor(now: () => Date = () => new Date()) {
        this.now = now;
    }

    public async Run(options: PersonEnrichmentRunOptions): Promise<PersonEnrichmentRunResult> {
        this.validateOptions(options);
        const row = await this.loadProviderRow(options);
        const plugin = this.resolvePlugin(row, options);
        const facets = options.Facets.filter((facet) => plugin.SupportedFacets.includes(facet));
        const context: EnrichmentContext = { ContextUser: options.ContextUser, MetadataProvider: options.MetadataProvider, ProviderRow: row, CompanyID: options.CompanyID, Facets: facets };
        await this.initialize(plugin, context);
        const filter = this.buildFilter(options, row);
        if (options.Mode === 'Preview') return this.preview(options, row, filter);
        const lookups = await LoadRunLookups(options.MetadataProvider, options.ContextUser);
        return this.runBatches(options, row, plugin, context, lookups, filter);
    }

    private validateOptions(options: PersonEnrichmentRunOptions): void {
        const problems: string[] = [];
        if (!Number.isInteger(options.MaxPeople) || options.MaxPeople < 1 || options.MaxPeople > MAX_PEOPLE_LIMIT) problems.push(`MaxPeople must be an integer from 1 to ${MAX_PEOPLE_LIMIT}.`);
        if (options.Facets.length === 0 || options.Facets.some((facet) => !AllEnrichmentFacets.includes(facet))) problems.push(`Facets must be a non-empty subset of ${AllEnrichmentFacets.join(', ')}.`);
        if (!(options.RefreshMatchedDays > 0)) problems.push('RefreshMatchedDays must be greater than zero.');
        if (!(options.RetryNotFoundDays > 0)) problems.push('RetryNotFoundDays must be greater than zero.');
        if (!(options.TimeBudgetMinutes > 0)) problems.push('TimeBudgetMinutes must be greater than zero.');
        if (!options.ProviderCode || options.ProviderCode.trim() === '') problems.push('ProviderCode is required.');
        if (options.PersonFilter && options.PersonFilter.trim() !== '') {
            const verdict = SQLExpressionValidator.Instance.validate(options.PersonFilter, { context: 'where_clause' });
            if (!verdict.valid) problems.push(`PersonFilter was rejected: ${verdict.error ?? 'invalid expression'}.`);
        }
        if (problems.length > 0) throw new EnrichmentRefusedError('VALIDATION_ERROR', problems.join(' '));
    }

    private async loadProviderRow(options: PersonEnrichmentRunOptions): Promise<mjBizAppsCommonEnrichmentProviderEntity> {
        const view = RunView.FromMetadataProvider(options.MetadataProvider);
        const result = await view.RunView<mjBizAppsCommonEnrichmentProviderEntity>({
            EntityName: ENRICHMENT_ENTITIES.EnrichmentProviders,
            ExtraFilter: `Code = '${EscapeSQLString(options.ProviderCode)}'`,
            ResultType: 'entity_object',
        }, options.ContextUser);
        if (!result.Success) throw new Error(`Loading the enrichment provider failed: ${result.ErrorMessage}`);
        const row = result.Results[0];
        if (!row) throw new EnrichmentRefusedError('PROVIDER_NOT_FOUND', `No Enrichment Provider has Code '${options.ProviderCode}'.`);
        if (!row.IsActive) throw new EnrichmentRefusedError('PROVIDER_INACTIVE', `Enrichment Provider '${row.Code}' is inactive.`);
        return row;
    }

    private resolvePlugin(row: mjBizAppsCommonEnrichmentProviderEntity, options: PersonEnrichmentRunOptions): BaseEnrichmentProvider {
        const created = MJGlobal.Instance.ClassFactory.TryCreateInstance<BaseEnrichmentProvider>(BaseEnrichmentProvider, row.DriverClass);
        if (!created.Resolved || !created.Instance) throw new EnrichmentRefusedError('PROVIDER_NOT_FOUND', `No BaseEnrichmentProvider is registered for DriverClass '${row.DriverClass}'.`);
        const plugin = created.Instance;
        if (plugin.Code !== row.Code) throw new EnrichmentRefusedError('VALIDATION_ERROR', `DriverClass '${row.DriverClass}' reports Code '${plugin.Code}', but the row's Code is '${row.Code}'.`);
        if (!plugin.IsLive && !options.AllowNonLiveProvider) throw new EnrichmentRefusedError('VALIDATION_ERROR', `Provider '${row.Code}' is not live; pass AllowNonLiveProvider to run it.`);
        return plugin;
    }

    private async initialize(plugin: BaseEnrichmentProvider, context: EnrichmentContext): Promise<void> {
        try {
            await plugin.Initialize(context);
        } catch (error) {
            if (error instanceof EnrichmentConfigurationError) throw new EnrichmentRefusedError('CREDENTIALS_NOT_FOUND', error.message);
            throw error;
        }
    }

    private buildFilter(options: PersonEnrichmentRunOptions, row: mjBizAppsCommonEnrichmentProviderEntity): string {
        const people = this.entity(options.MetadataProvider, ENRICHMENT_ENTITIES.People);
        const contacts = this.entity(options.MetadataProvider, ENRICHMENT_ENTITIES.ContactMethods);
        const identities = this.entity(options.MetadataProvider, ENRICHMENT_ENTITIES.PersonExternalIdentities);
        return BuildEligibilityFilter({
            SchemaName: people.SchemaName,
            PeopleView: people.BaseView,
            ContactMethodsView: contacts.BaseView,
            IdentitiesView: identities.BaseView,
            ProviderCode: row.Code,
            Now: this.now(),
            RefreshMatchedDays: options.RefreshMatchedDays,
            RetryNotFoundDays: options.RetryNotFoundDays,
            PersonFilter: options.PersonFilter,
        });
    }

    private entity(provider: IMetadataProvider, name: string): EntityInfo {
        const info = provider.EntityByName(name);
        if (!info) throw new Error(`Entity '${name}' is not in metadata.`);
        return info;
    }

    private async preview(options: PersonEnrichmentRunOptions, row: mjBizAppsCommonEnrichmentProviderEntity, filter: string): Promise<PersonEnrichmentRunResult> {
        const view = RunView.FromMetadataProvider(options.MetadataProvider);
        const [count, rates] = await view.RunViews([
            { EntityName: ENRICHMENT_ENTITIES.People, ExtraFilter: filter, ResultType: 'count_only' },
            { EntityName: ENRICHMENT_ENTITIES.EnrichmentProviderRates, ExtraFilter: `EnrichmentProviderID = '${row.ID}'`, ResultType: 'simple', Fields: ['Operation', 'Unit', 'CreditsPerUnit'] },
        ], options.ContextUser);
        if (!count.Success) throw new Error(`Counting eligible people failed: ${count.ErrorMessage}`);
        if (!rates.Success) throw new Error(`Loading provider rates failed: ${rates.ErrorMessage}`);
        const eligible = count.TotalRowCount;
        const estimate = EstimateCost({
            Rates: (rates.Results as Pick<mjBizAppsCommonEnrichmentProviderRateEntity, 'Operation' | 'Unit' | 'CreditsPerUnit'>[]).map((rate): CostRate => ({ Operation: rate.Operation, Unit: rate.Unit, CreditsPerUnit: rate.CreditsPerUnit })),
            CreditPrice: row.CreditPrice,
            CreditCurrency: row.CreditCurrency,
            Lines: [{ Operation: 'Enrich', Units: Math.min(eligible, options.MaxPeople), IsUpperBound: true }],
        });
        return { ...EmptyRunResult('Completed'), Eligible: eligible, EstimatedCredits: estimate.Credits, EstimatedCost: estimate.Cost, CostCurrency: estimate.Currency };
    }

    private async runBatches(
        options: PersonEnrichmentRunOptions,
        row: mjBizAppsCommonEnrichmentProviderEntity,
        plugin: BaseEnrichmentProvider,
        context: EnrichmentContext,
        lookups: RunLookups,
        filter: string,
    ): Promise<PersonEnrichmentRunResult> {
        const deps: BatchDeps = { Plugin: plugin, Context: context, Lookups: lookups, Policy: options.CreateOrganizations, Now: this.now };
        const processor = new EnrichmentBatchProcessor(deps);
        const startedAt = this.now().getTime();
        const budgetMs = options.TimeBudgetMinutes * 60 * 1000;
        const processOptions: RecordSetProcessOptions = {
            source: new KeysetSource(ENRICHMENT_ENTITIES.People, filter),
            processor,
            contextUser: options.ContextUser,
            provider: options.MetadataProvider,
            batchSize: BatchSize(row, plugin),
            maxConcurrency: 1,
            maxRecords: options.MaxPeople,
            rateLimit: row.RequestsPerMinute ? { requestsPerMinute: row.RequestsPerMinute } : undefined,
            errorThresholdPercent: ERROR_THRESHOLD_PERCENT,
            triggeredBy: 'Manual',
            resume: false,
            configuration: RunConfiguration(options, row, context.Facets),
            onAfterBatch: async (_batch: RecordRef[]) => {
                if (processor.StopReason) return { continue: false, reason: processor.StopReason };
                if (this.now().getTime() - startedAt >= budgetMs) {
                    processor.StopReason = 'TimeBudget';
                    return { continue: false, reason: 'TimeBudget' };
                }
                return null;
            },
        };
        const run = await RecordSetProcessor.Instance.Process(processOptions);
        return this.summarize(run, processor, options, row, plugin);
    }

    private summarize(run: ProcessRunResult, processor: EnrichmentBatchProcessor, options: PersonEnrichmentRunOptions, row: mjBizAppsCommonEnrichmentProviderEntity, plugin: BaseEnrichmentProvider): PersonEnrichmentRunResult {
        const stoppedReason = StoppedReasonOf(run, processor, options.MaxPeople);
        if (run.Status === 'Failed' && stoppedReason !== 'ErrorThreshold') throw new Error(run.ErrorMessage ?? 'The record-set processor failed the run.');
        const credits = plugin.CreditsConsumed;
        const priced = credits != null && row.CreditPrice != null;
        LogStatus(`[PersonEnrichmentEngine] ${row.Code}: processed ${run.Processed}, matched ${processor.Counts.Matched}, stopped: ${stoppedReason}`);
        return {
            ...processor.WriteCounts,
            ProcessRunID: run.ProcessRunID ?? null,
            Eligible: null,
            EstimatedCredits: null,
            EstimatedCost: null,
            Processed: run.Processed,
            Matched: processor.Counts.Matched,
            NotFound: processor.Counts.NotFound,
            Ambiguous: processor.Counts.Ambiguous,
            Errored: processor.Counts.Errored,
            CreditsConsumed: credits,
            Cost: priced ? (credits as number) * (row.CreditPrice as number) : null,
            CostCurrency: priced ? row.CreditCurrency : null,
            StoppedReason: stoppedReason,
        };
    }
}

export function StoppedReasonOf(run: ProcessRunResult, processor: { StopReason: EnrichmentStoppedReason | null }, maxPeople: number): EnrichmentStoppedReason {
    if (processor.StopReason) return processor.StopReason;
    if (run.Status === 'Failed') return 'ErrorThreshold';
    if (run.Processed >= maxPeople) return 'MaxPeople';
    return 'Completed';
}

function BatchSize(row: mjBizAppsCommonEnrichmentProviderEntity, plugin: BaseEnrichmentProvider): number {
    const ceiling = plugin.MaxBatchSizeCeiling ?? Number.POSITIVE_INFINITY;
    return Math.max(1, Math.min(row.MaxBatchSize, ceiling));
}

function RunConfiguration(options: PersonEnrichmentRunOptions, row: mjBizAppsCommonEnrichmentProviderEntity, facets: EnrichmentFacet[]): Record<string, unknown> {
    return {
        ProviderCode: row.Code,
        DriverClass: row.DriverClass,
        Facets: facets,
        MaxPeople: options.MaxPeople,
        RefreshMatchedDays: options.RefreshMatchedDays,
        RetryNotFoundDays: options.RetryNotFoundDays,
        CreateOrganizations: options.CreateOrganizations,
        TimeBudgetMinutes: options.TimeBudgetMinutes,
        PersonFilter: options.PersonFilter,
        CompanyID: options.CompanyID,
        TriggeredBy: 'Manual',
    };
}

export function EmptyRunResult(stoppedReason: EnrichmentStoppedReason): PersonEnrichmentRunResult {
    return {
        ...EmptyWriteCounts(),
        ProcessRunID: null,
        Eligible: null,
        EstimatedCredits: null,
        EstimatedCost: null,
        Processed: 0,
        Matched: 0,
        NotFound: 0,
        Ambiguous: 0,
        Errored: 0,
        CreditsConsumed: null,
        Cost: null,
        CostCurrency: null,
        StoppedReason: stoppedReason,
    };
}

/** Exported so the action and the tests share the exact transaction helper the engine uses. */
export function TransactionProvider(provider: IMetadataProvider): Parameters<typeof RunInEntityTransaction>[0] {
    return provider as unknown as Parameters<typeof RunInEntityTransaction>[0];
}

