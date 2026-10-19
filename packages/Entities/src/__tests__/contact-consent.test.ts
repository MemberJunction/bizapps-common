import { describe, expect, it } from 'vitest';
import {
    ConsentHistoryEntry,
    DecideContact,
    IsContactConsentStatus,
    IsLatestConsentChange,
    ResolveCurrentConsent,
} from '../contact-consent.js';

const at = (iso: string): Date => new Date(iso);

const entry = (status: ConsentHistoryEntry['NewConsentStatus'], iso: string): ConsentHistoryEntry => ({
    NewConsentStatus: status,
    ConsentStatusAt: at(iso),
});

describe('ResolveCurrentConsent', () => {
    it('is NotSpecified when nothing was ever recorded', () => {
        expect(ResolveCurrentConsent([])).toBe('NotSpecified');
    });

    it('is the entry with the latest ConsentStatusAt, whatever order the rows arrive in', () => {
        const history = [
            entry('OptedOut', '2026-10-12T00:00:00Z'),
            entry('NotSpecified', '2019-06-18T00:00:00Z'),
            entry('OptedIn', '2025-03-03T00:00:00Z'),
        ];
        expect(ResolveCurrentConsent(history)).toBe('OptedOut');
        expect(ResolveCurrentConsent([...history].reverse())).toBe('OptedOut');
    });

    it('resolves two changes at the same instant to the one recorded later', () => {
        const history = [entry('OptedIn', '2026-01-01T00:00:00Z'), entry('OptedOut', '2026-01-01T00:00:00Z')];
        expect(ResolveCurrentConsent(history)).toBe('OptedOut');
    });
});

describe('IsLatestConsentChange', () => {
    const history = [entry('OptedIn', '2025-03-03T00:00:00Z'), entry('OptedOut', '2026-10-12T00:00:00Z')];

    it('is true for a change newer than everything recorded, and for an empty history', () => {
        expect(IsLatestConsentChange(history, at('2026-10-13T00:00:00Z'))).toBe(true);
        expect(IsLatestConsentChange([], at('2000-01-01T00:00:00Z'))).toBe(true);
    });

    it('is false for a late-arriving import with an older date, so it is kept but does not move the status', () => {
        expect(IsLatestConsentChange(history, at('2019-06-18T00:00:00Z'))).toBe(false);
    });

    it('is true at exactly the latest instant, matching ResolveCurrentConsent on ties', () => {
        expect(IsLatestConsentChange(history, at('2026-10-12T00:00:00Z'))).toBe(true);
    });
});

describe('DecideContact', () => {
    it('refuses when there is no contact method on the channel', () => {
        const d = DecideContact([], 'SMS');
        expect(d).toMatchObject({ Allowed: false, Status: 'NoContactMethod' });
        expect(d.Reason).toContain('SMS');
    });

    it('allows when any method on the channel is opted in, even beside an opt-out', () => {
        expect(DecideContact(['OptedOut', 'OptedIn'], 'Email')).toMatchObject({ Allowed: true, Status: 'OptedIn' });
    });

    it('refuses when every method on the channel is opted out', () => {
        expect(DecideContact(['OptedOut', 'OptedOut'], 'Phone')).toMatchObject({ Allowed: false, Status: 'OptedOut' });
    });

    it('allows an unspecified status by default, because every pre-existing method is unspecified', () => {
        expect(DecideContact(['OptedOut', 'NotSpecified'], 'Email')).toMatchObject({ Allowed: true, Status: 'NotSpecified' });
    });

    it('refuses an unspecified status when the policy requires an explicit opt-in', () => {
        const d = DecideContact(['NotSpecified'], 'Email', { RequireOptIn: true });
        expect(d).toMatchObject({ Allowed: false, Status: 'NotSpecified' });
        expect(d.Reason).toContain('required');
    });
});

describe('IsContactConsentStatus', () => {
    it('accepts the three statuses and nothing else', () => {
        expect(IsContactConsentStatus('OptedIn')).toBe(true);
        expect(IsContactConsentStatus('OptedOut')).toBe(true);
        expect(IsContactConsentStatus('NotSpecified')).toBe(true);
        expect(IsContactConsentStatus('optedin')).toBe(false);
        expect(IsContactConsentStatus(null)).toBe(false);
        expect(IsContactConsentStatus(1)).toBe(false);
    });
});
