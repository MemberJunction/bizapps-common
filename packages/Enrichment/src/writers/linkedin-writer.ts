import type { mjBizAppsCommonContactMethodEntity } from '@mj-biz-apps/common-entities';
import { ENRICHMENT_ENTITIES } from '../entity-names.js';
import { NormalizeLinkedInURL } from '../normalize.js';
import type { ApplyContext } from './identity-writer.js';

export interface LinkedInPlan {
    /** The URL to insert, or null when the person already has a LinkedIn contact method (or the vendor sent none). */
    Insert: string | null;
}

/** Insert only when the person has no LinkedIn contact method. Never overwrite or add a second one. */
export function PlanLinkedIn(vendorURL: string | null, existingLinkedInValue: string | null): LinkedInPlan {
    const normalized = NormalizeLinkedInURL(vendorURL);
    if (!normalized) return { Insert: null };
    if (existingLinkedInValue != null && existingLinkedInValue.trim() !== '') return { Insert: null };
    return { Insert: vendorURL?.trim() ?? null };
}

export async function ApplyLinkedIn(
    plan: LinkedInPlan,
    personID: string,
    linkedInContactTypeID: string,
    context: ApplyContext,
): Promise<{ Added: number; Message: string | null }> {
    if (!plan.Insert) return { Added: 0, Message: null };
    const row = await context.MetadataProvider.GetEntityObject<mjBizAppsCommonContactMethodEntity>(ENRICHMENT_ENTITIES.ContactMethods, context.ContextUser);
    row.NewRecord();
    row.PersonID = personID;
    row.ContactTypeID = linkedInContactTypeID;
    row.Value = plan.Insert;
    row.IsPrimary = true;
    const saved = await row.Save();
    return { Added: saved ? 1 : 0, Message: saved ? null : row.LatestResult?.CompleteMessage ?? 'Contact method insert failed' };
}
