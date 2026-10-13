import { EscapeSQLString } from '@memberjunction/global';
import { EMAIL_CONTACT_TYPE, LINKEDIN_CONTACT_TYPE } from './entity-names.js';

/**
 * Everything the eligibility filter needs, resolved by the engine from entity metadata so that no
 * schema or view name is ever written literally.
 */
export interface EligibilityFilterInput {
    SchemaName: string;
    PeopleView: string;
    ContactMethodsView: string;
    IdentitiesView: string;
    ProviderCode: string;
    /** The clock. Cutoffs are computed here as UTC ISO strings, so the SQL stays dialect-neutral. */
    Now: Date;
    RefreshMatchedDays: number;
    RetryNotFoundDays: number;
    /** An extra predicate on the people view, already validated. */
    PersonFilter: string | null;
}

/** The ExtraFilter on `MJ_BizApps_Common: People` that selects who a run may send to the vendor. */
export function BuildEligibilityFilter(input: EligibilityFilterInput): string {
    const people = Qualified(input.SchemaName, input.PeopleView);
    const contacts = Qualified(input.SchemaName, input.ContactMethodsView);
    const identities = Qualified(input.SchemaName, input.IdentitiesView);
    const code = EscapeSQLString(input.ProviderCode);
    const matchedCutoff = CutoffIso(input.Now, input.RefreshMatchedDays);
    const notFoundCutoff = CutoffIso(input.Now, input.RetryNotFoundDays);
    const parts = [
        `Status = 'Active'`,
        `(Email IS NOT NULL OR EXISTS (SELECT 1 FROM ${contacts} cm WHERE cm.PersonID = ${people}.ID AND cm.ContactType IN ('${EMAIL_CONTACT_TYPE}','${LINKEDIN_CONTACT_TYPE}')))`,
        `NOT EXISTS (SELECT 1 FROM ${identities} pei WHERE pei.PersonID = ${people}.ID AND pei.SourceSystem = '${code}' AND (pei.MatchStatus = 'Ambiguous' OR (pei.MatchStatus = 'Matched' AND pei.LastCheckedAt > '${matchedCutoff}') OR (pei.MatchStatus = 'NotFound' AND pei.LastCheckedAt > '${notFoundCutoff}')))`,
    ];
    if (input.PersonFilter && input.PersonFilter.trim() !== '') parts.push(`(${input.PersonFilter.trim()})`);
    return parts.join(' AND ');
}

function Qualified(schema: string, view: string): string {
    return `[${schema}].[${view}]`;
}

/** `now - days`, as an ISO string without milliseconds, which every dialect parses. */
export function CutoffIso(now: Date, days: number): string {
    const cutoff = new Date(now.getTime() - days * 24 * 60 * 60 * 1000);
    return cutoff.toISOString().replace(/\.\d{3}Z$/, 'Z');
}
