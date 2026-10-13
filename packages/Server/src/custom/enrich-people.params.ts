import type { CreateOrganizationsPolicy, EnrichmentFacet, EnrichmentRunMode } from '@mj-biz-apps/common-enrichment';
import { AllEnrichmentFacets, DefaultRunOptions, MAX_PEOPLE_LIMIT } from '@mj-biz-apps/common-enrichment';

/** The action's inputs after parsing: every optional has its documented default. */
export interface EnrichPeopleInput {
    ProviderCode: string;
    PersonFilter: string | null;
    MaxPeople: number;
    Facets: EnrichmentFacet[];
    Mode: EnrichmentRunMode;
    CompanyID: string | null;
    RefreshMatchedDays: number;
    RetryNotFoundDays: number;
    CreateOrganizations: CreateOrganizationsPolicy;
    TimeBudgetMinutes: number;
    /** Test and demo hosts only: lets a non-live provider such as the fixture run. */
    AllowNonLiveProvider: boolean;
}

export interface ParsedEnrichPeopleParams {
    Input: EnrichPeopleInput | null;
    Errors: string[];
}

const POLICIES: CreateOrganizationsPolicy[] = ['Never', 'CurrentEmployerOnly', 'AllEmployers'];
const MODES: EnrichmentRunMode[] = ['Run', 'Preview'];

/** Pure: raw action params (any casing, strings or numbers) to typed input, or the list of problems. */
export function ParseEnrichPeopleParams(raw: Record<string, unknown>): ParsedEnrichPeopleParams {
    const errors: string[] = [];
    const providerCode = Text(raw, 'ProviderCode');
    if (!providerCode) errors.push('ProviderCode is required.');
    const maxPeople = Integer(raw, 'MaxPeople', DefaultRunOptions.MaxPeople, 1, MAX_PEOPLE_LIMIT, errors);
    const refresh = Integer(raw, 'RefreshMatchedDays', DefaultRunOptions.RefreshMatchedDays, 1, 36500, errors);
    const retry = Integer(raw, 'RetryNotFoundDays', DefaultRunOptions.RetryNotFoundDays, 1, 36500, errors);
    const budget = Integer(raw, 'TimeBudgetMinutes', DefaultRunOptions.TimeBudgetMinutes, 1, 24 * 60, errors);
    const facets = Facets(raw, errors);
    const mode = OneOf(raw, 'Mode', MODES, DefaultRunOptions.Mode, errors);
    const policy = OneOf(raw, 'CreateOrganizations', POLICIES, DefaultRunOptions.CreateOrganizations, errors);
    if (errors.length > 0) return { Input: null, Errors: errors };
    return {
        Input: { ProviderCode: providerCode as string, PersonFilter: Text(raw, 'PersonFilter'), MaxPeople: maxPeople, Facets: facets, Mode: mode, CompanyID: Text(raw, 'CompanyID'), RefreshMatchedDays: refresh, RetryNotFoundDays: retry, CreateOrganizations: policy, TimeBudgetMinutes: budget, AllowNonLiveProvider: Flag(raw, 'AllowNonLiveProvider') },
        Errors: [],
    };
}

function Lookup(raw: Record<string, unknown>, name: string): unknown {
    const key = Object.keys(raw).find((candidate) => candidate.toLowerCase() === name.toLowerCase());
    return key === undefined ? undefined : raw[key];
}

function Text(raw: Record<string, unknown>, name: string): string | null {
    const value = Lookup(raw, name);
    if (value === undefined || value === null) return null;
    const text = String(value).trim();
    return text === '' ? null : text;
}

function Integer(raw: Record<string, unknown>, name: string, fallback: number, min: number, max: number, errors: string[]): number {
    const text = Text(raw, name);
    if (text === null) return fallback;
    const parsed = Number(text);
    if (!Number.isInteger(parsed) || parsed < min || parsed > max) {
        errors.push(`${name} must be an integer from ${min} to ${max}.`);
        return fallback;
    }
    return parsed;
}

function OneOf<T extends string>(raw: Record<string, unknown>, name: string, allowed: T[], fallback: T, errors: string[]): T {
    const text = Text(raw, name);
    if (text === null) return fallback;
    const match = allowed.find((candidate) => candidate.toLowerCase() === text.toLowerCase());
    if (!match) errors.push(`${name} must be one of ${allowed.join(', ')}.`);
    return match ?? fallback;
}

function Facets(raw: Record<string, unknown>, errors: string[]): EnrichmentFacet[] {
    const value = Lookup(raw, 'Facets');
    const list = Array.isArray(value) ? value.map(String) : Text(raw, 'Facets')?.split(',') ?? [...AllEnrichmentFacets];
    const facets: EnrichmentFacet[] = [];
    for (const item of list) {
        const match = AllEnrichmentFacets.find((facet) => facet.toLowerCase() === item.trim().toLowerCase());
        if (!match) errors.push(`Facets contains '${item.trim()}'; allowed: ${AllEnrichmentFacets.join(', ')}.`);
        else if (!facets.includes(match)) facets.push(match);
    }
    if (facets.length === 0 && errors.length === 0) errors.push('Facets must name at least one facet.');
    return facets;
}

/** A boolean param arrives as true/false, 'true'/'false', 1/0 or '1'/'0'; anything else is false. */
function Flag(raw: Record<string, unknown>, name: string): boolean {
    const value = Lookup(raw, name);
    if (typeof value === 'boolean') return value;
    if (typeof value === 'number') return value === 1;
    const text = Text(raw, name);
    return text !== null && ['true', '1', 'yes'].includes(text.toLowerCase());
}
