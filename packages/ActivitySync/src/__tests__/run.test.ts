import { describe, expect, it } from 'vitest';

import {
    AsDryRunDecision,
    IsConnectionActive,
    ResolveCapturePlan,
    RunnableConnectionFilter,
    RunnableStatuses,
    ResolvePolicy,
    type SkippedContentPolicy,
} from '../run.js';
import { NotRunConnectionIssues } from '../ActivitySyncEngine.js';
import { InvalidFilterInputError } from '../sql.js';

const NOW = new Date('2026-08-29T12:00:00Z');
const EARLIER = new Date('2026-08-01T00:00:00Z');
const LATER = new Date('2026-09-30T00:00:00Z');

describe('IsConnectionActive', () => {
    it('Paused and Disabled stay off regardless of the window; Error retries', () => {
        for (const status of ['Paused', 'Disabled'] as const) {
            expect(IsConnectionActive(status, null, null, NOW)).toBe(false);
            expect(IsConnectionActive(status, EARLIER, LATER, NOW)).toBe(false);
        }
        expect(IsConnectionActive('Error', null, null, NOW)).toBe(true);
        expect(IsConnectionActive('Error', EARLIER, LATER, NOW)).toBe(true);
        expect(IsConnectionActive('Error', LATER, null, NOW)).toBe(false);
    });

    it('is active with no window at all', () => {
        expect(IsConnectionActive('Active', null, null, NOW)).toBe(true);
    });

    it('is inactive before StartAt — provisioned ahead of time', () => {
        expect(IsConnectionActive('Active', LATER, null, NOW)).toBe(false);
    });

    it('is inactive after EndAt — retired on a date, with nobody flipping a switch', () => {
        expect(IsConnectionActive('Active', null, EARLIER, NOW)).toBe(false);
    });

    it('is active inside the window', () => {
        expect(IsConnectionActive('Active', EARLIER, LATER, NOW)).toBe(true);
    });

    it('treats the bounds as inclusive', () => {
        expect(IsConnectionActive('Active', NOW, null, NOW)).toBe(true);
        expect(IsConnectionActive('Active', null, NOW, NOW)).toBe(true);
    });

    it('honours an open-ended start or end', () => {
        expect(IsConnectionActive('Active', EARLIER, null, NOW)).toBe(true);
        expect(IsConnectionActive('Active', null, LATER, NOW)).toBe(true);
    });
});

describe('ResolvePolicy', () => {
    it('falls back to the provider default when nothing overrides', () => {
        expect(ResolvePolicy('provider', null, null)).toBe('provider');
        expect(ResolvePolicy('provider', undefined)).toBe('provider');
    });

    it('lets the most specific override win', () => {
        // provider ← connection ← rule; the rule is last and therefore most specific.
        expect(ResolvePolicy('provider', 'connection', 'rule')).toBe('rule');
        expect(ResolvePolicy('provider', 'connection', null)).toBe('connection');
    });

    it('does not treat 0 or empty string as "inherit"', () => {
        // Only null/undefined mean inherit. A deliberate 0 is a value.
        expect(ResolvePolicy(100, 0)).toBe(0);
        expect(ResolvePolicy('a', '')).toBe('');
    });
});

describe('ResolveCapturePlan', () => {
    it('captures nothing under the None policy, key or not', () => {
        expect(ResolveCapturePlan('None', null)).toEqual({ Capture: 'None', EncryptionKeyID: null });
        expect(ResolveCapturePlan('None', 'key-1')).toEqual({ Capture: 'None', EncryptionKeyID: null });
    });

    it('maps the two retaining policies to their capture scope', () => {
        expect(ResolveCapturePlan('SubjectEncrypted', 'key-1')).toEqual({
            Capture: 'Subject',
            EncryptionKeyID: 'key-1',
        });
        expect(ResolveCapturePlan('FullEncrypted', 'key-1')).toEqual({
            Capture: 'Full',
            EncryptionKeyID: 'key-1',
        });
    });

    it('REFUSES to retain content without a key rather than degrading quietly', () => {
        // The two failure modes this rules out: silently writing plaintext, and silently
        // writing nothing while the operator believes retention is on.
        for (const policy of ['SubjectEncrypted', 'FullEncrypted'] as SkippedContentPolicy[]) {
            expect(() => ResolveCapturePlan(policy, null)).toThrow(/only permissible.*encrypted/is);
        }
    });
});

describe('AsDryRunDecision', () => {
    it('rewrites write outcomes as hypotheticals', () => {
        expect(AsDryRunDecision('Included')).toBe('WouldInclude');
        expect(AsDryRunDecision('Excluded')).toBe('WouldExclude');
    });

    it('leaves outcomes that describe the source alone', () => {
        // A duplicate is a duplicate and a failure is a failure whether or not we would have
        // written — those describe the item, not our action.
        expect(AsDryRunDecision('Duplicate')).toBe('Duplicate');
        expect(AsDryRunDecision('Failed')).toBe('Failed');
    });
});

describe('dry run previews a Paused connection', () => {
    const A = '6A1F3E2C-0B1D-4C7E-9F00-1A2B3C4D5E6F';
    const B = '7B2F3E2C-0B1D-4C7E-9F00-1A2B3C4D5E6F';

    it('a live run honours Paused; a dry run may read it; Disabled is never run', () => {
        expect(IsConnectionActive('Paused', null, null, NOW, false)).toBe(false);
        expect(IsConnectionActive('Paused', null, null, NOW, true)).toBe(true);
        expect(IsConnectionActive('Disabled', null, null, NOW, true)).toBe(false);
        expect(RunnableStatuses(true)).not.toContain('Disabled');
    });

    it('the window still applies to a dry run', () => {
        expect(IsConnectionActive('Paused', LATER, null, NOW, true)).toBe(false);
    });

    it('the fleet filter adds Paused only for a dry run', () => {
        expect(RunnableConnectionFilter({ DryRun: false })).toBe(`Status IN ('Active', 'Error')`);
        expect(RunnableConnectionFilter({ DryRun: true })).toBe(`Status IN ('Active', 'Error', 'Paused')`);
    });

    it('narrows to the named connections, and an empty list means all of them', () => {
        expect(RunnableConnectionFilter({ DryRun: true, ConnectionIDs: [A, B] })).toBe(
            `Status IN ('Active', 'Error', 'Paused') AND ID IN ('${A}','${B}')`,
        );
        expect(RunnableConnectionFilter({ DryRun: true, ConnectionIDs: [] })).toBe(
            `Status IN ('Active', 'Error', 'Paused')`,
        );
    });

    it('refuses an id that is not a UUID rather than widening the query', () => {
        expect(() => RunnableConnectionFilter({ DryRun: true, ConnectionIDs: [`x' OR 1=1 --`] })).toThrow(
            InvalidFilterInputError,
        );
    });

    it('reports each named connection the query did not return, matching ids case-insensitively', () => {
        const issues = NotRunConnectionIssues({ DryRun: false, ConnectionIDs: [A, B] }, [{ ID: A.toLowerCase() }]);
        expect(issues).toEqual([`Connection ${B} was not run: it does not exist, is Disabled, or is Paused.`]);
        expect(NotRunConnectionIssues({ DryRun: true }, [])).toEqual([]);
    });
});
