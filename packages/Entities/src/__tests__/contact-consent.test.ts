import { describe, expect, it } from 'vitest';
import {
    ConsentHistoryEntry,
    ConsentRow,
    DecideContact,
    IsContactConsentStatus,
    IsLatestConsentChange,
    PickConsentForOrganization,
    ResolveCurrentConsent,
} from '../contact-consent.js';

const at = (iso: string): Date => new Date(iso);

const entry = (status: ConsentHistoryEntry['NewConsentStatus'], iso: string): ConsentHistoryEntry => ({
    NewConsentStatus: status,
    ConsentStatusAt: at(iso),
});

const METHOD = '11111111-1111-1111-1111-111111111111';
const PURPOSE = '22222222-2222-2222-2222-222222222222';
const ORG_A = '33333333-3333-3333-3333-333333333333';
const ORG_B = '44444444-4444-4444-4444-444444444444';

const consent = (status: ConsentRow['ConsentStatus'], organizationID: string | null): ConsentRow => ({
    ContactMethodID: METHOD,
    ConsentPurposeID: PURPOSE,
    OrganizationID: organizationID,
    ConsentStatus: status,
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

describe('PickConsentForOrganization', () => {
    const rows = [consent('OptedIn', null), consent('OptedOut', ORG_A)];

    it("uses the asking organization's own row when it has one", () => {
        expect(PickConsentForOrganization(rows, ORG_A)?.ConsentStatus).toBe('OptedOut');
        expect(PickConsentForOrganization(rows, ORG_A.toLowerCase())?.ConsentStatus).toBe('OptedOut');
    });

    it('falls back to the installation-wide row for an organization with no row of its own', () => {
        expect(PickConsentForOrganization(rows, ORG_B)?.ConsentStatus).toBe('OptedIn');
    });

    it('returns only the installation-wide row when no organization is asking, never a scoped one', () => {
        expect(PickConsentForOrganization(rows, null)?.ConsentStatus).toBe('OptedIn');
        expect(PickConsentForOrganization([consent('OptedOut', ORG_A)], undefined)).toBeNull();
    });

    it('returns null when the method has no consent at all', () => {
        expect(PickConsentForOrganization([], ORG_A)).toBeNull();
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

    it('allows an unspecified status by default, because every pre-existing method has nothing recorded', () => {
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
