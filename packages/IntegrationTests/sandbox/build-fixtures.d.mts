/** Types for build-fixtures.mjs, so the fixture test and the checks import its case table typed. */
export interface SandboxGraphItem {
    id: string;
    [field: string]: unknown;
}

export interface SandboxCase {
    /** The decision under the baseline rule set: Included, Excluded, or Skipped (never mapped). */
    Expected: 'Included' | 'Excluded' | 'Skipped' | 'Withdrawn';
    Why: string;
    item: SandboxGraphItem;
}

export const MAILBOX: string;
export const MAIL_CASES: SandboxCase[];
export const NEWER_MAIL_CASE: SandboxCase;
export const CALENDAR_CASES: SandboxCase[];
export const CONSENT_MAIL_CASES: SandboxCase[];
export const CONSENT_LATE_MAIL_CASES: SandboxCase[];
export const CONSENT_CALENDAR_CASES: SandboxCase[];
export const CONSENT_LATE_CALENDAR_CASES: SandboxCase[];
export const STANDING_MAIL_CASES: SandboxCase[];
export const STANDING_LATE_MAIL_CASES: SandboxCase[];
export const STANDING_NOEXPAND_MAIL_CASES: SandboxCase[];
export const STANDING_CALENDAR_CASES: SandboxCase[];
export const STANDING_LATE_CALENDAR_CASES: SandboxCase[];
/** What a sandbox consent source answers: the shape of `StandingConsent`, plus a comment. */
export interface SandboxSourceFile {
    $comment: string[];
    Domains: Array<{ Domain: string; Label: string }>;
    Issues: string[];
}
export const OWNED_ACCOUNTS_SOURCE: SandboxSourceFile;
export const NO_EMPLOYEE_SOURCE: SandboxSourceFile;
