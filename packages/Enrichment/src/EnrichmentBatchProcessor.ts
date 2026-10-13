import { LogError, RunInEntityTransaction } from '@memberjunction/core';
import type { IRecordProcessor, RecordProcessorContext, RecordRef, RecordResult } from '@memberjunction/record-set-processor-base';
import type { BaseEnrichmentProvider } from './BaseEnrichmentProvider.js';
import { LoadBatchContext, LoadIdentityHolders, SameID, SnapshotPerson, type BatchContext, type RunLookups } from './batch-context.js';
import { EnrichmentQuotaExhaustedError, EnrichmentRateLimitError } from './errors.js';
import { ToCalendarDay } from '@mj-biz-apps/common-entities';
import { CreateOrganizations, LoadOrganizationCandidates, MatchOrganizations, PolicyAllowsCreate, type OrganizationCandidate } from './organization-resolver.js';
import { BuildRequests, InferMatchedBy } from './request-builder.js';
import { TransactionProvider } from './PersonEnrichmentEngine.js';
import { AddWriteCounts, EmptyWriteCounts, type CreateOrganizationsPolicy, type EnrichmentContext, type EnrichmentStoppedReason, type EnrichmentWriteCounts, type PersonEnrichmentRequest, type PersonEnrichmentResult } from './types.js';
import { ApplyEducation, PlanEducation, ToDay } from './writers/education-writer.js';
import { ApplyEmployment, PlanEmployment } from './writers/employment-writer.js';
import { ApplyIdentity, PlanIdentity, type ApplyContext } from './writers/identity-writer.js';
import { ApplyLinkedIn, PlanLinkedIn } from './writers/linkedin-writer.js';
import type { EducationRow, EmploymentRow, IdentityRow, OrganizationRef } from './writers/plan-types.js';

export interface BatchDeps {
    Plugin: BaseEnrichmentProvider;
    Context: EnrichmentContext;
    Lookups: RunLookups;
    Policy: CreateOrganizationsPolicy;
    Now: () => Date;
}

export interface MatchCounts {
    Matched: number;
    NotFound: number;
    Ambiguous: number;
    Errored: number;
}

/**
 * One vendor call per batch, then one entity transaction per person. Rate limits and exhausted
 * credits report every record as Skipped (they stay eligible, and the circuit breaker is not tripped
 * by a vendor quota) and set StopReason so the engine's onAfterBatch ends the run.
 */
export class EnrichmentBatchProcessor implements IRecordProcessor {
    public StopReason: EnrichmentStoppedReason | null = null;
    public readonly Counts: MatchCounts = { Matched: 0, NotFound: 0, Ambiguous: 0, Errored: 0 };
    public readonly WriteCounts: EnrichmentWriteCounts = EmptyWriteCounts();

    constructor(private readonly deps: BatchDeps) {}

    public async ProcessRecord(): Promise<RecordResult> {
        throw new Error('EnrichmentBatchProcessor processes whole batches; ProcessRecord is never called.');
    }

    public async ProcessBatch(records: RecordRef[], _context: RecordProcessorContext): Promise<Map<string, RecordResult>> {
        const ids = records.map((record) => record.RecordID);
        const out = new Map<string, RecordResult>();
        if (this.StopReason) return SkipAll(ids, out, `Run stopped: ${this.StopReason}`);
        const batch = await LoadBatchContext(ids, this.code, this.deps.Lookups, this.provider, this.user);
        const built = BuildRequests(ids.map((id) => SnapshotPerson(id, batch, this.deps.Lookups)).filter((snapshot): snapshot is NonNullable<typeof snapshot> => snapshot !== null));
        for (const id of built.SkippedPersonIDs) out.set(id, { Status: 'Skipped', ErrorMessage: 'Nothing identifies this person to a vendor.' });
        for (const id of ids) if (!batch.People.has(id.toLowerCase())) out.set(id, { Status: 'Skipped', ErrorMessage: 'Person not found when the batch loaded.' });
        const results = await this.callProvider(built.Requests);
        if (!results) return SkipAll(built.Requests.map((request) => request.PersonID), out, `Run stopped: ${this.StopReason}`);
        await this.writeBatch(built.Requests, results, batch, out);
        return out;
    }

    private get code(): string { return this.deps.Context.ProviderRow.Code; }
    private get provider() { return this.deps.Context.MetadataProvider; }
    private get user() { return this.deps.Context.ContextUser; }

    /** Returns null when the vendor stopped us; the batch is then skipped, not failed. */
    private async callProvider(requests: PersonEnrichmentRequest[]): Promise<PersonEnrichmentResult[] | null> {
        if (requests.length === 0) return [];
        try {
            return await this.deps.Plugin.EnrichPeople(requests, this.deps.Context);
        } catch (error) {
            if (error instanceof EnrichmentRateLimitError) this.StopReason = 'RateLimited';
            else if (error instanceof EnrichmentQuotaExhaustedError) this.StopReason = 'QuotaExhausted';
            else throw error;
            LogError(`[PersonEnrichmentEngine] ${this.code}: ${error.message}`);
            return null;
        }
    }

    private async writeBatch(requests: PersonEnrichmentRequest[], results: PersonEnrichmentResult[], batch: BatchContext, out: Map<string, RecordResult>): Promise<void> {
        const byPerson = new Map(results.map((result) => [result.PersonID.toLowerCase(), result]));
        /** Who already holds each returned vendor ID; people written earlier in this batch are added as they go, so a vendor ID shared within one batch is Ambiguous for everyone after the first. */
        const holders = await LoadIdentityHolders(results.map((result) => result.ExternalID ?? ''), this.code, this.provider, this.user);
        const candidates = await LoadOrganizationCandidates(results.flatMap((result) => result.Employment), this.provider, this.user);
        for (const request of requests) {
            const result = byPerson.get(request.PersonID.toLowerCase()) ?? MissingResult(request.PersonID);
            out.set(request.PersonID, await this.writePerson(request, result, batch, holders, candidates));
        }
    }

    private async writePerson(request: PersonEnrichmentRequest, result: PersonEnrichmentResult, batch: BatchContext, holders: Map<string, string>, candidates: OrganizationCandidate[]): Promise<RecordResult> {
        const existingIdentity = batch.Identities.get(request.PersonID.toLowerCase()) ?? null;
        const holder = result.ExternalID ? holders.get(result.ExternalID) : undefined;
        const identityPlan = PlanIdentity({ Result: result, Existing: existingIdentity ? AsIdentityRow(existingIdentity) : null, HeldByAnotherPerson: holder != null && !SameID(holder, request.PersonID), InferredMatchedBy: InferMatchedBy(request), Now: this.deps.Now() });
        const action = identityPlan.Action;
        if (action === 'None') {
            this.Counts.Errored += 1;
            return { Status: 'Failed', ErrorMessage: result.ErrorMessage ?? 'The provider reported an error for this person.' };
        }
        const apply: ApplyContext = { MetadataProvider: this.provider, ContextUser: this.user, ProviderCode: this.code };
        try {
            const delta = await RunInEntityTransaction(TransactionProvider(this.provider), async () => {
                const written = await this.writeInsideTransaction(request, result, action, batch, candidates, apply, existingIdentity == null);
                await ApplyIdentityOrThrow(identityPlan, request.PersonID, existingIdentity, apply);
                return written;
            });
            AddWriteCounts(this.WriteCounts, delta);
            this.countIdentity(action, request.PersonID, result.ExternalID, holder);
            if (action === 'Matched' && result.ExternalID) holders.set(result.ExternalID, request.PersonID);
            return { Status: 'Succeeded', ResultPayload: { Status: action, ...delta } };
        } catch (error) {
            this.Counts.Errored += 1;
            const message = error instanceof Error ? error.message : String(error);
            LogError(`[PersonEnrichmentEngine] ${this.code}: writes for Person ${request.PersonID} rolled back: ${message}`);
            return { Status: 'Failed', ErrorMessage: message };
        }
    }

    private countIdentity(action: 'Ambiguous' | 'Matched' | 'NotFound', personID: string, externalID: string | null, holder: string | undefined): void {
        if (action === 'Matched') this.Counts.Matched += 1;
        else if (action === 'NotFound') this.Counts.NotFound += 1;
        else {
            this.Counts.Ambiguous += 1;
            LogError(`[PersonEnrichmentEngine] ${this.code}: ExternalID '${externalID}' is held by Person ${holder}; Person ${personID} marked Ambiguous.`);
        }
    }

    /** Education, employment and LinkedIn for a Matched person. The caller writes the identity row last in the same transaction, so a failure anywhere rolls the person back and leaves them eligible. */
    private async writeInsideTransaction(request: PersonEnrichmentRequest, result: PersonEnrichmentResult, action: 'Ambiguous' | 'Matched' | 'NotFound', batch: BatchContext, candidates: OrganizationCandidate[], apply: ApplyContext, firstTime: boolean): Promise<Partial<EnrichmentWriteCounts>> {
        const delta: Partial<EnrichmentWriteCounts> = {};
        if (action !== 'Matched') return delta;
        const facets = this.deps.Context.Facets;
        if (facets.includes('Education')) Object.assign(delta, await this.writeEducation(request.PersonID, result, batch, apply));
        if (facets.includes('Employment')) Object.assign(delta, await this.writeEmployment(request.PersonID, result, batch, candidates, apply, firstTime));
        if (facets.includes('LinkedIn')) Object.assign(delta, await this.writeLinkedIn(request, result, apply));
        return delta;
    }

    private async writeEducation(personID: string, result: PersonEnrichmentResult, batch: BatchContext, apply: ApplyContext): Promise<Partial<EnrichmentWriteCounts>> {
        const existing = batch.Educations.get(personID.toLowerCase()) ?? [];
        const plan = PlanEducation({ Education: result.Education, Existing: existing.map(AsEducationRow), ProviderCode: this.code, OrganizationIDs: new Map() });
        const applied = await ApplyEducation(plan, personID, new Map(existing.map((row) => [row.ID, row])), this.deps.Now(), apply);
        if (applied.Message) throw new Error(applied.Message);
        return { EducationCreated: applied.Created, EducationUpdated: applied.Updated };
    }

    private async writeEmployment(personID: string, result: PersonEnrichmentResult, batch: BatchContext, candidates: OrganizationCandidate[], apply: ApplyContext, firstTime: boolean): Promise<Partial<EnrichmentWriteCounts>> {
        const existing = batch.EmployeeRelationships.get(personID.toLowerCase()) ?? [];
        const resolved = MatchOrganizations(result.Employment, candidates);
        const today = ToCalendarDay(this.deps.Now()) ?? '';
        const plan = PlanEmployment({ Employment: result.Employment, Existing: existing.map(AsEmploymentRow), Resolved: resolved.ByEntry, Policy: this.deps.Policy, ProviderCode: this.code, Today: today });
        const creatable = plan.Inserts.map((insert) => insert.Organization).filter((ref) => ref.ID == null);
        const created = await CreateOrganizations(creatable, (ref: OrganizationRef) => PolicyAllowsCreate(this.deps.Policy, IsCurrentEmployer(result, ref)), this.provider, this.user);
        if (created.Message) throw new Error(created.Message);
        for (const [key, id] of created.IDs) candidates.push({ ID: id, Name: key, LegalName: null, Website: null });
        const applied = await ApplyEmployment({ Plan: plan, PersonID: personID, EmployeeTypeID: this.deps.Lookups.EmployeeTypeID, Existing: new Map(existing.map((row) => [row.ID, row])), CreatedOrganizationIDs: created.IDs, SkipEntityActions: firstTime }, apply);
        if (applied.Message) throw new Error(applied.Message);
        return { RelationshipsCreated: applied.Created, RelationshipsUpdated: applied.Updated, RelationshipsEnded: applied.Ended, OrganizationsCreated: created.Created };
    }

    private async writeLinkedIn(request: PersonEnrichmentRequest, result: PersonEnrichmentResult, apply: ApplyContext): Promise<Partial<EnrichmentWriteCounts>> {
        const plan = PlanLinkedIn(result.LinkedInURL, request.LinkedInURL);
        const applied = await ApplyLinkedIn(plan, request.PersonID, this.deps.Lookups.LinkedInContactTypeID, apply);
        if (applied.Message) throw new Error(applied.Message);
        return { LinkedInAdded: applied.Added };
    }
}

async function ApplyIdentityOrThrow(plan: ReturnType<typeof PlanIdentity>, personID: string, existing: BatchContext['Identities'] extends Map<string, infer T> ? T | null : never, apply: ApplyContext): Promise<void> {
    const saved = await ApplyIdentity(plan, personID, existing, apply);
    if (!saved.Saved) throw new Error(saved.Message ?? 'Identity save failed');
}

function SkipAll(ids: string[], out: Map<string, RecordResult>, message: string): Map<string, RecordResult> {
    for (const id of ids) if (!out.has(id)) out.set(id, { Status: 'Skipped', ErrorMessage: message });
    return out;
}

function MissingResult(personID: string): PersonEnrichmentResult {
    return { PersonID: personID, Status: 'Error', ExternalID: null, MatchedBy: null, MatchConfidence: null, LinkedInURL: null, Education: [], Employment: [], ErrorMessage: 'The provider returned no result for this person.' };
}

function IsCurrentEmployer(result: PersonEnrichmentResult, ref: OrganizationRef): boolean {
    return result.Employment.some((entry) => entry.IsCurrent && entry.OrganizationName.trim().toLowerCase() === ref.Name.trim().toLowerCase());
}

function AsIdentityRow(row: BatchContext['Identities'] extends Map<string, infer T> ? T : never): IdentityRow {
    return { ID: row.ID, PersonID: row.PersonID, SourceSystem: row.SourceSystem, ExternalID: row.ExternalID, MatchStatus: row.MatchStatus, MatchedBy: row.MatchedBy, MatchConfidence: row.MatchConfidence, LastCheckedAt: row.LastCheckedAt, LastMatchedAt: row.LastMatchedAt };
}

function AsEducationRow(row: BatchContext['Educations'] extends Map<string, (infer T)[]> ? T : never): EducationRow {
    return { ID: row.ID, PersonID: row.PersonID, OrganizationID: row.OrganizationID, InstitutionName: row.InstitutionName, Degree: row.Degree, FieldOfStudy: row.FieldOfStudy, StartDate: ToDay(row.StartDate), EndDate: ToDay(row.EndDate), Source: row.Source, SourceSystem: row.SourceSystem };
}

function AsEmploymentRow(row: BatchContext['EmployeeRelationships'] extends Map<string, (infer T)[]> ? T : never): EmploymentRow {
    return { ID: row.ID, FromPersonID: row.FromPersonID ?? '', ToOrganizationID: row.ToOrganizationID, Title: row.Title, StartDate: ToDay(row.StartDate), EndDate: ToDay(row.EndDate), Status: row.Status, Source: row.Source, SourceSystem: row.SourceSystem };
}
