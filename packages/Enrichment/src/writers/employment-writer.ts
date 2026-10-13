import type { mjBizAppsCommonRelationshipEntity } from '@mj-biz-apps/common-entities';
import { ENRICHMENT_ENTITIES } from '../entity-names.js';
import { NormalizeName } from '../normalize.js';
import type { CreateOrganizationsPolicy, EnrichedEmployment } from '../types.js';
import { ToDate } from './education-writer.js';
import type { ApplyContext } from './identity-writer.js';
import type { EmploymentRow, OrganizationRef } from './plan-types.js';

export interface EmploymentInsert {
    Organization: OrganizationRef;
    Title: string | null;
    StartDate: string | null;
    EndDate: string | null;
    Status: 'Active' | 'Ended';
}

export interface EmploymentUpdate {
    ID: string;
    Title: string | null;
    StartDate: string | null;
    EndDate: string | null;
    Status: 'Active' | 'Ended';
}

export interface EmploymentPlan {
    Inserts: EmploymentInsert[];
    Updates: EmploymentUpdate[];
    /** Active rows of ours whose Organization the vendor no longer lists as current. */
    Ends: { ID: string; EndDate: string }[];
    SkippedManual: number;
    SkippedOtherSystem: number;
    /** Entries whose Organization could not be resolved and may not be created. */
    SkippedUnresolved: number;
}

export interface EmploymentPlanInput {
    Employment: EnrichedEmployment[];
    /** The person's existing Employee relationships. */
    Existing: EmploymentRow[];
    /** Resolution by employment entry index: a ref with an ID, a ref without one (creatable), or null (ambiguous). */
    Resolved: ReadonlyArray<OrganizationRef | null>;
    Policy: CreateOrganizationsPolicy;
    ProviderCode: string;
    /** 'YYYY-MM-DD' */
    Today: string;
}

/** The employment table of §7.7 plus the ending rule. */
export function PlanEmployment(input: EmploymentPlanInput): EmploymentPlan {
    const plan: EmploymentPlan = { Inserts: [], Updates: [], Ends: [], SkippedManual: 0, SkippedOtherSystem: 0, SkippedUnresolved: 0 };
    const currentOrganizationIDs = new Set<string>();
    input.Employment.forEach((entry, index) => {
        const organization = ResolveForPolicy(input.Resolved[index] ?? null, entry.IsCurrent, input.Policy);
        if (!organization) {
            plan.SkippedUnresolved += 1;
            return;
        }
        if (organization.ID && entry.IsCurrent) currentOrganizationIDs.add(organization.ID.toLowerCase());
        PlanOneEmployment(plan, entry, organization, input);
    });
    PlanEndings(plan, input, currentOrganizationIDs);
    return plan;
}

function ResolveForPolicy(ref: OrganizationRef | null, isCurrent: boolean, policy: CreateOrganizationsPolicy): OrganizationRef | null {
    if (!ref) return null;
    if (ref.ID) return ref;
    if (policy === 'AllEmployers') return ref;
    if (policy === 'CurrentEmployerOnly' && isCurrent) return ref;
    return null;
}

function PlanOneEmployment(plan: EmploymentPlan, entry: EnrichedEmployment, organization: OrganizationRef, input: EmploymentPlanInput): void {
    const status: 'Active' | 'Ended' = entry.IsCurrent ? 'Active' : 'Ended';
    const existing = organization.ID ? FindMatch(input.Existing, organization.ID, entry) : null;
    if (!existing) {
        plan.Inserts.push({ Organization: organization, Title: entry.Title, StartDate: entry.StartDate, EndDate: entry.EndDate, Status: status });
        return;
    }
    if (existing.Source !== 'Enrichment') {
        plan.SkippedManual += 1;
        return;
    }
    if (existing.SourceSystem !== input.ProviderCode) {
        plan.SkippedOtherSystem += 1;
        return;
    }
    const endDate = status === 'Ended' ? entry.EndDate ?? existing.EndDate ?? input.Today : entry.EndDate;
    plan.Updates.push({ ID: existing.ID, Title: entry.Title ?? existing.Title, StartDate: entry.StartDate ?? existing.StartDate, EndDate: endDate, Status: status });
}

/** Same Organization, and either the same normalized Title or the same StartDate. */
function FindMatch(existing: EmploymentRow[], organizationID: string, entry: EnrichedEmployment): EmploymentRow | null {
    const title = NormalizeName(entry.Title ?? '');
    for (const row of existing) {
        if (row.ToOrganizationID?.toLowerCase() !== organizationID.toLowerCase()) continue;
        if (title !== '' && NormalizeName(row.Title ?? '') === title) return row;
        if (entry.StartDate && row.StartDate === entry.StartDate) return row;
    }
    return null;
}

/** End our own Active rows whose Organization is not in the vendor's current employment. Never another source's row. */
function PlanEndings(plan: EmploymentPlan, input: EmploymentPlanInput, currentOrganizationIDs: Set<string>): void {
    const touched = new Set(plan.Updates.map((update) => update.ID));
    for (const row of input.Existing) {
        if (row.Status !== 'Active' || row.Source !== 'Enrichment' || row.SourceSystem !== input.ProviderCode) continue;
        if (touched.has(row.ID)) continue;
        if (row.ToOrganizationID && currentOrganizationIDs.has(row.ToOrganizationID.toLowerCase())) continue;
        plan.Ends.push({ ID: row.ID, EndDate: input.Today });
    }
}

export interface EmploymentApplyResult {
    Created: number;
    Updated: number;
    Ended: number;
    Message: string | null;
}

export interface EmploymentApplyInput {
    Plan: EmploymentPlan;
    PersonID: string;
    EmployeeTypeID: string;
    Existing: ReadonlyMap<string, mjBizAppsCommonRelationshipEntity>;
    /** Organization IDs for inserts whose ref had none, created by the organization resolver before this call. */
    CreatedOrganizationIDs: ReadonlyMap<string, string>;
    /** First-time enrichment saves with SkipEntityActions so a backfill logs no timeline Activity. */
    SkipEntityActions: boolean;
}

export async function ApplyEmployment(input: EmploymentApplyInput, context: ApplyContext): Promise<EmploymentApplyResult> {
    const out: EmploymentApplyResult = { Created: 0, Updated: 0, Ended: 0, Message: null };
    for (const insert of input.Plan.Inserts) {
        const organizationID = insert.Organization.ID ?? input.CreatedOrganizationIDs.get(NormalizeName(insert.Organization.Name)) ?? null;
        if (!organizationID) continue;
        const row = await NewEmployeeRow(input, organizationID, context);
        row.Title = insert.Title;
        row.StartDate = ToDate(insert.StartDate);
        row.EndDate = ToDate(insert.EndDate);
        row.Status = insert.Status;
        if (!(await row.Save({ SkipEntityActions: input.SkipEntityActions, IgnoreDirtyState: false }))) return { ...out, Message: row.LatestResult?.CompleteMessage ?? 'Relationship insert failed' };
        out.Created += 1;
    }
    const updated = await ApplyUpdatesAndEnds(input, out, context);
    if (updated) return updated;
    return out;
}

async function ApplyUpdatesAndEnds(input: EmploymentApplyInput, out: EmploymentApplyResult, context: ApplyContext): Promise<EmploymentApplyResult | null> {
    for (const update of input.Plan.Updates) {
        const row = input.Existing.get(update.ID);
        if (!row) continue;
        const ending = row.Status === 'Active' && update.Status === 'Ended';
        row.Title = update.Title;
        row.StartDate = ToDate(update.StartDate);
        row.EndDate = ToDate(update.EndDate);
        row.Status = update.Status;
        if (!(await row.Save({ SkipEntityActions: input.SkipEntityActions, IgnoreDirtyState: false }))) return { ...out, Message: row.LatestResult?.CompleteMessage ?? 'Relationship update failed' };
        if (ending) out.Ended += 1;
        else out.Updated += 1;
    }
    for (const end of input.Plan.Ends) {
        const row = input.Existing.get(end.ID);
        if (!row) continue;
        row.Status = 'Ended';
        row.EndDate = ToDate(end.EndDate);
        if (!(await row.Save({ SkipEntityActions: input.SkipEntityActions, IgnoreDirtyState: false }))) return { ...out, Message: row.LatestResult?.CompleteMessage ?? 'Relationship end failed' };
        out.Ended += 1;
    }
    void context;
    return null;
}

async function NewEmployeeRow(input: EmploymentApplyInput, organizationID: string, context: ApplyContext): Promise<mjBizAppsCommonRelationshipEntity> {
    const row = await context.MetadataProvider.GetEntityObject<mjBizAppsCommonRelationshipEntity>(ENRICHMENT_ENTITIES.Relationships, context.ContextUser);
    row.NewRecord();
    row.RelationshipTypeID = input.EmployeeTypeID;
    row.FromPersonID = input.PersonID;
    row.ToOrganizationID = organizationID;
    row.Source = 'Enrichment';
    row.SourceSystem = context.ProviderCode;
    return row;
}
