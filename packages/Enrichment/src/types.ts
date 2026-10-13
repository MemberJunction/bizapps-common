import type { IMetadataProvider, UserInfo } from '@memberjunction/core';
import type { mjBizAppsCommonEnrichmentProviderEntity } from '@mj-biz-apps/common-entities';

/** What the engine can ask a provider for. A provider declares the subset it supports. */
export type EnrichmentFacet = 'Education' | 'Employment' | 'LinkedIn';

export const AllEnrichmentFacets: readonly EnrichmentFacet[] = ['Education', 'Employment', 'LinkedIn'];

/** One person, as the engine hands them to a provider. Built from the batch context (request-builder.ts). */
export interface PersonEnrichmentRequest {
    PersonID: string;
    FirstName: string;
    LastName: string;
    /** Person.Email first, then ContactMethod emails; de-duplicated and lower-cased. */
    Emails: string[];
    LinkedInURL: string | null;
    /** From the current Employee relationship's Organization website, as a bare host. */
    OrganizationDomain: string | null;
    OrganizationName: string | null;
    /** From this provider's PersonExternalIdentity row, when it is Matched. */
    ExternalID: string | null;
}

export interface EnrichedEducation {
    InstitutionName: string;
    /** The vendor's school ID (PDL school.id), kept for the alias follow-up. Not stored in v1. */
    InstitutionExternalID: string | null;
    Degree: string | null;
    FieldOfStudy: string | null;
    /** 'YYYY-MM-DD' */
    StartDate: string | null;
    EndDate: string | null;
}

export interface EnrichedEmployment {
    OrganizationName: string;
    OrganizationDomain: string | null;
    Title: string | null;
    StartDate: string | null;
    EndDate: string | null;
    IsCurrent: boolean;
}

export type PersonMatchStatus = 'Matched' | 'NotFound' | 'Error';

export type PersonMatchedBy = 'ExternalID' | 'Email' | 'LinkedIn' | 'NameAndDomain';

export interface PersonEnrichmentResult {
    PersonID: string;
    Status: PersonMatchStatus;
    ExternalID: string | null;
    MatchedBy: PersonMatchedBy | null;
    /** 0..1 */
    MatchConfidence: number | null;
    LinkedInURL: string | null;
    Education: EnrichedEducation[];
    Employment: EnrichedEmployment[];
    /** Status === 'Error' only. Never persisted to PersonExternalIdentity. */
    ErrorMessage: string | null;
}

export interface EnrichmentContext {
    ContextUser: UserInfo;
    /** The request's provider, never `new Metadata()`. */
    MetadataProvider: IMetadataProvider;
    ProviderRow: mjBizAppsCommonEnrichmentProviderEntity;
    CompanyID: string | null;
    Facets: EnrichmentFacet[];
}

export type CreateOrganizationsPolicy = 'Never' | 'CurrentEmployerOnly' | 'AllEmployers';

export type EnrichmentRunMode = 'Run' | 'Preview';

export interface PersonEnrichmentRunOptions {
    ProviderCode: string;
    /** Optional extra predicate on vwPeople, validated before use. */
    PersonFilter: string | null;
    /** Default 500, max 5000. */
    MaxPeople: number;
    /** Default all three. */
    Facets: EnrichmentFacet[];
    /** Preview: count eligible people, call no vendor, write nothing. */
    Mode: EnrichmentRunMode;
    CompanyID: string | null;
    /** Default 180. */
    RefreshMatchedDays: number;
    /** Default 90. */
    RetryNotFoundDays: number;
    /** Default CurrentEmployerOnly. */
    CreateOrganizations: CreateOrganizationsPolicy;
    /** Default 45. Must stay under the job's MaxRuntimeMinutes. */
    TimeBudgetMinutes: number;
    /** Default false; integration tests set true for the fixture provider. */
    AllowNonLiveProvider: boolean;
    ContextUser: UserInfo;
    MetadataProvider: IMetadataProvider;
}

export type EnrichmentStoppedReason =
    | 'Completed'
    | 'MaxPeople'
    | 'TimeBudget'
    | 'RateLimited'
    | 'QuotaExhausted'
    | 'ErrorThreshold';

export interface EnrichmentWriteCounts {
    EducationCreated: number;
    EducationUpdated: number;
    RelationshipsCreated: number;
    RelationshipsUpdated: number;
    RelationshipsEnded: number;
    OrganizationsCreated: number;
    LinkedInAdded: number;
}

export interface PersonEnrichmentRunResult extends EnrichmentWriteCounts {
    ProcessRunID: string | null;
    /** Preview only. */
    Eligible: number | null;
    /** Preview only; an upper bound when misses are free. */
    EstimatedCredits: number | null;
    /** Preview only; null when the provider is unpriced. */
    EstimatedCost: number | null;
    Processed: number;
    Matched: number;
    NotFound: number;
    Ambiguous: number;
    Errored: number;
    /** When the provider reports it. */
    CreditsConsumed: number | null;
    /** CreditsConsumed x CreditPrice at run start; null when unpriced. */
    Cost: number | null;
    CostCurrency: string | null;
    StoppedReason: EnrichmentStoppedReason;
}

export function EmptyWriteCounts(): EnrichmentWriteCounts {
    return {
        EducationCreated: 0,
        EducationUpdated: 0,
        RelationshipsCreated: 0,
        RelationshipsUpdated: 0,
        RelationshipsEnded: 0,
        OrganizationsCreated: 0,
        LinkedInAdded: 0,
    };
}

export function AddWriteCounts(target: EnrichmentWriteCounts, delta: Partial<EnrichmentWriteCounts>): void {
    target.EducationCreated += delta.EducationCreated ?? 0;
    target.EducationUpdated += delta.EducationUpdated ?? 0;
    target.RelationshipsCreated += delta.RelationshipsCreated ?? 0;
    target.RelationshipsUpdated += delta.RelationshipsUpdated ?? 0;
    target.RelationshipsEnded += delta.RelationshipsEnded ?? 0;
    target.OrganizationsCreated += delta.OrganizationsCreated ?? 0;
    target.LinkedInAdded += delta.LinkedInAdded ?? 0;
}
