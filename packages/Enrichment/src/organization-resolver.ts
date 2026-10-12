import type { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';
import { RunView, type IMetadataProvider, type UserInfo } from '@memberjunction/core';
import { EscapeSQLString } from '@memberjunction/global';
import { ENRICHMENT_ENTITIES } from './entity-names.js';
import { DomainFromWebsite, NormalizeName } from './normalize.js';
import type { CreateOrganizationsPolicy, EnrichedEmployment } from './types.js';
import type { OrganizationRef } from './writers/plan-types.js';

/** A candidate Organization row, flattened so matching is pure and testable. */
export interface OrganizationCandidate {
    ID: string;
    Name: string;
    LegalName: string | null;
    Website: string | null;
}

export interface ResolvedOrganizations {
    /** By employment entry index: an existing ref, a creatable ref (ID null), or null when ambiguous. */
    ByEntry: (OrganizationRef | null)[];
    Ambiguous: number;
}

/**
 * Matching order: domain (employers only), then exact normalized name or legal name. More than one
 * match is unresolved, never a random pick. Schools are never created, so this is employment only.
 */
export function MatchOrganizations(employment: EnrichedEmployment[], candidates: OrganizationCandidate[]): ResolvedOrganizations {
    const out: ResolvedOrganizations = { ByEntry: [], Ambiguous: 0 };
    for (const entry of employment) {
        const matches = MatchOne(entry, candidates);
        if (matches.length > 1) {
            out.Ambiguous += 1;
            out.ByEntry.push(null);
        } else if (matches.length === 1) {
            out.ByEntry.push({ ID: matches[0].ID, Name: matches[0].Name, Website: matches[0].Website });
        } else {
            out.ByEntry.push({ ID: null, Name: entry.OrganizationName, Website: entry.OrganizationDomain ? `https://${entry.OrganizationDomain}` : null });
        }
    }
    return out;
}

function MatchOne(entry: EnrichedEmployment, candidates: OrganizationCandidate[]): OrganizationCandidate[] {
    const domain = DomainFromWebsite(entry.OrganizationDomain);
    if (domain) {
        const byDomain = candidates.filter((candidate) => DomainFromWebsite(candidate.Website) === domain);
        if (byDomain.length > 0) return Distinct(byDomain);
    }
    const name = NormalizeName(entry.OrganizationName);
    if (name === '') return [];
    return Distinct(candidates.filter((candidate) => NormalizeName(candidate.Name) === name || NormalizeName(candidate.LegalName) === name));
}

function Distinct(rows: OrganizationCandidate[]): OrganizationCandidate[] {
    const seen = new Set<string>();
    return rows.filter((row) => {
        const key = row.ID.toLowerCase();
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
    });
}

/** One RunView per batch for every distinct name and domain the batch's employment mentions. */
export async function LoadOrganizationCandidates(
    employment: EnrichedEmployment[],
    provider: IMetadataProvider,
    contextUser: UserInfo,
): Promise<OrganizationCandidate[]> {
    const filter = CandidateFilter(employment);
    if (!filter) return [];
    const view = RunView.FromMetadataProvider(provider);
    const result = await view.RunView<OrganizationCandidate>({
        EntityName: ENRICHMENT_ENTITIES.Organizations,
        ExtraFilter: filter,
        ResultType: 'simple',
        Fields: ['ID', 'Name', 'LegalName', 'Website'],
    }, contextUser);
    if (!result.Success) throw new Error(`Organization lookup failed: ${result.ErrorMessage}`);
    return result.Results ?? [];
}

/** Names match exactly (the database collation decides case); domains match anywhere in Website, then the resolver normalizes. */
export function CandidateFilter(employment: EnrichedEmployment[]): string | null {
    const names = new Set<string>();
    const domains = new Set<string>();
    for (const entry of employment) {
        const name = entry.OrganizationName.trim();
        if (name !== '') names.add(EscapeSQLString(name));
        const domain = DomainFromWebsite(entry.OrganizationDomain);
        if (domain) domains.add(EscapeSQLString(domain));
    }
    const clauses: string[] = [];
    if (names.size > 0) {
        const list = [...names].map((name) => `'${name}'`).join(',');
        clauses.push(`Name IN (${list}) OR LegalName IN (${list})`);
    }
    for (const domain of domains) clauses.push(`Website LIKE '%${domain}%'`);
    return clauses.length === 0 ? null : clauses.join(' OR ');
}

export interface CreatedOrganizations {
    /** By normalized vendor name. */
    IDs: Map<string, string>;
    Created: number;
    Message: string | null;
}

/** Creates the Organizations the plan allows (ID null refs that the policy admits). Never schools. */
export async function CreateOrganizations(
    refs: OrganizationRef[],
    policyAllows: (ref: OrganizationRef) => boolean,
    provider: IMetadataProvider,
    contextUser: UserInfo,
): Promise<CreatedOrganizations> {
    const out: CreatedOrganizations = { IDs: new Map(), Created: 0, Message: null };
    for (const ref of refs) {
        if (ref.ID || !policyAllows(ref)) continue;
        const key = NormalizeName(ref.Name);
        if (key === '' || out.IDs.has(key)) continue;
        const row = await provider.GetEntityObject<mjBizAppsCommonOrganizationEntity>(ENRICHMENT_ENTITIES.Organizations, contextUser);
        row.NewRecord();
        row.Name = ref.Name;
        row.Website = ref.Website;
        row.Status = 'Active';
        if (!(await row.Save())) return { ...out, Message: row.LatestResult?.CompleteMessage ?? 'Organization insert failed' };
        out.IDs.set(key, row.ID);
        out.Created += 1;
    }
    return out;
}

/** The create-policy matrix of §7.8, for employers only. */
export function PolicyAllowsCreate(policy: CreateOrganizationsPolicy, isCurrent: boolean): boolean {
    if (policy === 'Never') return false;
    if (policy === 'AllEmployers') return true;
    return isCurrent;
}
