/** Types for build-fixtures.mjs, so the fixture test and the checks import its case table typed. */
export interface SandboxGraphItem {
    id: string;
    [field: string]: unknown;
}

export interface SandboxCase {
    /** The decision under the baseline rule set: Included, Excluded, or Skipped (never mapped). */
    Expected: 'Included' | 'Excluded' | 'Skipped';
    Why: string;
    item: SandboxGraphItem;
}

export const MAILBOX: string;
export const MAIL_CASES: SandboxCase[];
export const NEWER_MAIL_CASE: SandboxCase;
export const CALENDAR_CASES: SandboxCase[];
