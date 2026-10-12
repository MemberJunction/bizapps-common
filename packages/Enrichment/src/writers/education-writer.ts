import type { mjBizAppsCommonPersonEducationEntity } from '@mj-biz-apps/common-entities';
import { FromCalendarDay, ToCalendarDay } from '@mj-biz-apps/common-entities';
import { ENRICHMENT_ENTITIES } from '../entity-names.js';
import { NormalizeDegree, NormalizeName, YearOf } from '../normalize.js';
import type { EnrichedEducation } from '../types.js';
import type { ApplyContext } from './identity-writer.js';
import type { EducationRow } from './plan-types.js';

export interface EducationInsert {
    InstitutionName: string;
    OrganizationID: string | null;
    Degree: string | null;
    FieldOfStudy: string | null;
    StartDate: string | null;
    EndDate: string | null;
}

export interface EducationUpdate {
    ID: string;
    FieldOfStudy: string | null;
    StartDate: string | null;
    EndDate: string | null;
    /** Set only when the row's OrganizationID is NULL. */
    OrganizationID: string | null;
}

export interface EducationPlan {
    Inserts: EducationInsert[];
    Updates: EducationUpdate[];
    /** Rows another source already holds: left alone, no duplicate. */
    Corroborated: number;
    /** Manual rows with the same key: never edited. */
    SkippedManual: number;
}

export interface EducationPlanInput {
    Education: EnrichedEducation[];
    Existing: EducationRow[];
    ProviderCode: string;
    /** Resolved school Organization IDs by normalized institution name. Schools are never created. */
    OrganizationIDs: ReadonlyMap<string, string>;
}

/** Dedupe key: person + normalized institution + normalized degree + end year. */
export function EducationKey(institution: string, degree: string | null, endDate: string | null): string {
    return `${NormalizeName(institution)}|${NormalizeDegree(degree ?? '')}|${YearOf(endDate)}`;
}

export function PlanEducation(input: EducationPlanInput): EducationPlan {
    const plan: EducationPlan = { Inserts: [], Updates: [], Corroborated: 0, SkippedManual: 0 };
    const existingByKey = new Map<string, EducationRow>();
    for (const row of input.Existing) existingByKey.set(EducationKey(row.InstitutionName, row.Degree, row.EndDate), row);
    const seen = new Set<string>();
    for (const entry of input.Education) {
        if (entry.InstitutionName.trim() === '') continue;
        const key = EducationKey(entry.InstitutionName, entry.Degree, entry.EndDate);
        if (seen.has(key)) continue;
        seen.add(key);
        PlanOneEducation(plan, entry, existingByKey.get(key) ?? null, input);
    }
    return plan;
}

function PlanOneEducation(plan: EducationPlan, entry: EnrichedEducation, existing: EducationRow | null, input: EducationPlanInput): void {
    const organizationID = input.OrganizationIDs.get(NormalizeName(entry.InstitutionName)) ?? null;
    if (!existing) {
        plan.Inserts.push({ InstitutionName: entry.InstitutionName, OrganizationID: organizationID, Degree: entry.Degree, FieldOfStudy: entry.FieldOfStudy, StartDate: entry.StartDate, EndDate: entry.EndDate });
        return;
    }
    if (existing.Source === 'Manual') {
        plan.SkippedManual += 1;
        return;
    }
    if (existing.Source === 'Enrichment' && existing.SourceSystem === input.ProviderCode) {
        plan.Updates.push({ ID: existing.ID, FieldOfStudy: entry.FieldOfStudy, StartDate: entry.StartDate, EndDate: entry.EndDate, OrganizationID: existing.OrganizationID ?? organizationID });
        return;
    }
    plan.Corroborated += 1;
}

export interface EducationApplyResult {
    Created: number;
    Updated: number;
    Message: string | null;
}

/** Saves what the plan says. Stops at the first failed save and reports it. */
export async function ApplyEducation(
    plan: EducationPlan,
    personID: string,
    existing: ReadonlyMap<string, mjBizAppsCommonPersonEducationEntity>,
    now: Date,
    context: ApplyContext,
): Promise<EducationApplyResult> {
    const out: EducationApplyResult = { Created: 0, Updated: 0, Message: null };
    for (const insert of plan.Inserts) {
        const row = await context.MetadataProvider.GetEntityObject<mjBizAppsCommonPersonEducationEntity>(ENRICHMENT_ENTITIES.PersonEducations, context.ContextUser);
        row.NewRecord();
        row.PersonID = personID;
        row.Source = 'Enrichment';
        row.SourceSystem = context.ProviderCode;
        row.InstitutionName = insert.InstitutionName;
        row.OrganizationID = insert.OrganizationID;
        row.Degree = insert.Degree;
        row.FieldOfStudy = insert.FieldOfStudy;
        row.StartDate = ToDate(insert.StartDate);
        row.EndDate = ToDate(insert.EndDate);
        row.LastVerifiedAt = now;
        if (!(await row.Save())) return { ...out, Message: row.LatestResult?.CompleteMessage ?? 'Education insert failed' };
        out.Created += 1;
    }
    for (const update of plan.Updates) {
        const row = existing.get(update.ID);
        if (!row) continue;
        row.FieldOfStudy = update.FieldOfStudy;
        row.StartDate = ToDate(update.StartDate);
        row.EndDate = ToDate(update.EndDate);
        if (row.OrganizationID == null) row.OrganizationID = update.OrganizationID;
        row.LastVerifiedAt = now;
        if (!(await row.Save())) return { ...out, Message: row.LatestResult?.CompleteMessage ?? 'Education update failed' };
        out.Updated += 1;
    }
    return out;
}

export function ToDate(day: string | null): Date | null {
    const calendarDay = ToCalendarDay(day);
    return calendarDay ? FromCalendarDay(calendarDay) : null;
}

export function ToDay(value: Date | string | null | undefined): string | null {
    return ToCalendarDay(value);
}
