/**
 * Plain row shapes the pure Plan* functions work on. The Apply* functions map generated entities onto
 * these, so almost all write logic is testable without a database.
 */

export type RowSource = 'Enrichment' | 'Import' | 'Manual';

export interface IdentityRow {
    ID: string;
    PersonID: string;
    SourceSystem: string;
    ExternalID: string | null;
    MatchStatus: 'Ambiguous' | 'Matched' | 'NotFound';
    MatchedBy: 'Email' | 'ExternalID' | 'LinkedIn' | 'Manual' | 'NameAndDomain' | null;
    MatchConfidence: number | null;
    LastCheckedAt: Date | null;
    LastMatchedAt: Date | null;
}

export interface EducationRow {
    ID: string;
    PersonID: string;
    OrganizationID: string | null;
    InstitutionName: string;
    Degree: string | null;
    FieldOfStudy: string | null;
    /** 'YYYY-MM-DD' or null. */
    StartDate: string | null;
    EndDate: string | null;
    Source: RowSource;
    SourceSystem: string | null;
}

export interface EmploymentRow {
    ID: string;
    FromPersonID: string;
    ToOrganizationID: string | null;
    Title: string | null;
    StartDate: string | null;
    EndDate: string | null;
    Status: 'Active' | 'Ended' | 'Inactive';
    Source: RowSource;
    SourceSystem: string | null;
}

/** A resolved Organization, or one the engine may create. */
export interface OrganizationRef {
    ID: string | null;
    Name: string;
    Website: string | null;
}
