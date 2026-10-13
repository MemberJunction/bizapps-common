import type { mjBizAppsCommonPersonExternalIdentityEntity } from '@mj-biz-apps/common-entities';
import type { IMetadataProvider, UserInfo } from '@memberjunction/core';
import { ENRICHMENT_ENTITIES } from '../entity-names.js';
import type { PersonEnrichmentResult, PersonMatchedBy } from '../types.js';
import type { IdentityRow } from './plan-types.js';

export type IdentityAction = 'Ambiguous' | 'Matched' | 'NotFound' | 'None';

export interface IdentityPlan {
    Action: IdentityAction;
    ExternalID: string | null;
    MatchedBy: PersonMatchedBy | null;
    MatchConfidence: number | null;
    LastCheckedAt: Date;
    LastMatchedAt: Date | null;
}

export interface IdentityPlanInput {
    Result: PersonEnrichmentResult;
    /** This person's row for this provider, if any. */
    Existing: IdentityRow | null;
    /** True when the returned ExternalID is already held by a different person. */
    HeldByAnotherPerson: boolean;
    /** MatchedBy to use when the provider did not report one. */
    InferredMatchedBy: PersonMatchedBy | null;
    Now: Date;
}

/**
 * The identity table of §7.7: Ambiguous when the vendor ID belongs to someone else, Matched on a
 * clean match, NotFound keeps a previously known ID, and an Error writes nothing.
 */
export function PlanIdentity(input: IdentityPlanInput): IdentityPlan {
    const { Result: result, Existing: existing, Now: now } = input;
    const matchedBy = result.MatchedBy ?? input.InferredMatchedBy;
    if (result.Status === 'Error') return Nothing(now);
    if (result.Status === 'NotFound') {
        return { Action: 'NotFound', ExternalID: existing?.ExternalID ?? null, MatchedBy: existing?.MatchedBy === 'Manual' ? null : existing?.MatchedBy ?? null, MatchConfidence: existing?.MatchConfidence ?? null, LastCheckedAt: now, LastMatchedAt: existing?.LastMatchedAt ?? null };
    }
    if (result.ExternalID == null || result.ExternalID.trim() === '') {
        return { ...Nothing(now), Action: 'NotFound', ExternalID: existing?.ExternalID ?? null };
    }
    if (input.HeldByAnotherPerson) {
        return { Action: 'Ambiguous', ExternalID: null, MatchedBy: null, MatchConfidence: null, LastCheckedAt: now, LastMatchedAt: existing?.LastMatchedAt ?? null };
    }
    return { Action: 'Matched', ExternalID: result.ExternalID, MatchedBy: matchedBy, MatchConfidence: ClampConfidence(result.MatchConfidence), LastCheckedAt: now, LastMatchedAt: now };
}

function Nothing(now: Date): IdentityPlan {
    return { Action: 'None', ExternalID: null, MatchedBy: null, MatchConfidence: null, LastCheckedAt: now, LastMatchedAt: null };
}

function ClampConfidence(value: number | null): number | null {
    if (value == null || Number.isNaN(value)) return null;
    return Math.min(1, Math.max(0, value));
}

export interface ApplyContext {
    MetadataProvider: IMetadataProvider;
    ContextUser: UserInfo;
    ProviderCode: string;
}

/** Upserts this person's identity row for the provider. Returns false, with the message, when the save failed. */
export async function ApplyIdentity(
    plan: IdentityPlan,
    personID: string,
    existing: mjBizAppsCommonPersonExternalIdentityEntity | null,
    context: ApplyContext,
): Promise<{ Saved: boolean; Message: string | null }> {
    if (plan.Action === 'None') return { Saved: true, Message: null };
    const row = existing ?? (await NewIdentityRow(personID, context));
    row.MatchStatus = plan.Action;
    row.ExternalID = plan.ExternalID;
    row.MatchedBy = plan.MatchedBy;
    row.MatchConfidence = plan.MatchConfidence;
    row.LastCheckedAt = plan.LastCheckedAt;
    row.LastMatchedAt = plan.LastMatchedAt;
    const saved = await row.Save();
    return { Saved: saved, Message: saved ? null : row.LatestResult?.CompleteMessage ?? 'Save failed' };
}

async function NewIdentityRow(personID: string, context: ApplyContext): Promise<mjBizAppsCommonPersonExternalIdentityEntity> {
    const row = await context.MetadataProvider.GetEntityObject<mjBizAppsCommonPersonExternalIdentityEntity>(
        ENRICHMENT_ENTITIES.PersonExternalIdentities,
        context.ContextUser,
    );
    row.NewRecord();
    row.PersonID = personID;
    row.SourceSystem = context.ProviderCode;
    return row;
}
