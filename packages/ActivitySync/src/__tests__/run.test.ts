import { describe, expect, it } from 'vitest';

import {
    AsDryRunDecision,
    IsConnectionActive,
    ResolveCapturePlan,
    ResolvePolicy,
    type SkippedContentPolicy,
} from '../run.js';

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
