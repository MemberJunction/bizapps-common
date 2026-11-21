/**
 * Schema constants and strongly-typed row projections for the Person
 * supervisor hierarchy (`Person.SupervisorPersonID`), recursive reporting view
 * (`vwPersonReportingChain`), and employee-to-person sync routine
 * (`SyncEmployeesToPeople`).
 */

/** Database view exposing flattened reporting chains `(PersonID, SupervisorPersonID, Depth)`. */
export const PERSON_REPORTING_CHAIN_VIEW = 'vwPersonReportingChain' as const;

/** Canonical `RelationshipType.Name` used to record supervisor links in `Relationship`. */
export const REPORTS_TO_RELATIONSHIP_TYPE = 'Reports To' as const;

/** Seeded `RelationshipType.ID` for `'Reports To'`. */
export const REPORTS_TO_RELATIONSHIP_TYPE_ID = 'F1449971-6488-49E3-8F5B-823EB3E8CB11' as const;

/** Database routine that synchronizes `MJ: Employees` supervisor hierarchies into `People` and `Relationships`. */
export const SYNC_EMPLOYEES_TO_PEOPLE_PROCEDURE = 'SyncEmployeesToPeople' as const;

/**
 * Strongly-typed projection of a row returned by `[__mj_BizAppsCommon].[vwPersonReportingChain]`.
 *
 * `Depth = 1` represents the direct supervisor (`Person.SupervisorPersonID`);
 * `Depth = 2+` represents skip-level and higher ancestors.
 */
export interface PersonReportingChainRow {
    /** Subordinate `MJ_BizApps_Common: People.ID`. */
    PersonID: string;
    /** Direct (`Depth = 1`) or transitive (`Depth >= 2`) supervisor `MJ_BizApps_Common: People.ID`. */
    SupervisorPersonID: string;
    /** 1-based reporting hop distance from `PersonID` up to `SupervisorPersonID`. */
    Depth: number;
}
