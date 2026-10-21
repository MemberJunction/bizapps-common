import { describe, expect, it } from 'vitest';
import {
    ConsentHistoryEntry,
    ConsentRow,
    DecideContact,
    IsContactConsentStatus,
    IsLatestConsentChange,
    ResolveConsentForScope,
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

const consent = (status: ConsentRow['ConsentStatus'], purposeID: string | null, organizationID: string | null): ConsentRow => ({
    ContactMethodID: METHOD,
    ConsentPurposeID: purposeID,
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

describe('ResolveConsentForScope', () => {
    const rows = [
        consent('OptedIn', null, null),          // general, installation-wide
        consent('OptedOut', PURPOSE, null),      // Marketing, installation-wide
        consent('OptedIn', PURPOSE, ORG_A),      // Marketing, from org A
        consent('OptedOut', null, ORG_B),        // general, from org B
    ];

    it('rung 1: this purpose from this organization wins over everything', () => {
        expect(ResolveConsentForScope(rows, { PurposeID: PURPOSE, OrganizationID: ORG_A })?.ConsentStatus).toBe('OptedIn');
        expect(ResolveConsentForScope(rows, { PurposeID: PURPOSE, OrganizationID: ORG_A.toLowerCase() })?.ConsentStatus).toBe('OptedIn');
    });

    it('rung 2: this purpose from anyone, when the organization has no row for the purpose', () => {
        expect(ResolveConsentForScope(rows, { PurposeID: PURPOSE, OrganizationID: ORG_B })?.ConsentStatus).toBe('OptedOut');
    });

    it('general never means default: a general opt-in loses to a Marketing opt-out for a Marketing question', () => {
        expect(ResolveConsentForScope(rows, { PurposeID: PURPOSE })?.ConsentStatus).toBe('OptedOut');
    });

    it('rung 3: a question with no purpose uses the organization\'s general row', () => {
        expect(ResolveConsentForScope(rows, { OrganizationID: ORG_B })?.ConsentStatus).toBe('OptedOut');
    });

    it('rung 4: the general installation-wide row answers everything else', () => {
        expect(ResolveConsentForScope(rows, {})?.ConsentStatus).toBe('OptedIn');
        expect(ResolveConsentForScope(rows, { OrganizationID: ORG_A })?.ConsentStatus).toBe('OptedIn');
        const other = '55555555-5555-5555-5555-555555555555';
        expect(ResolveConsentForScope(rows, { PurposeID: other, OrganizationID: ORG_A })?.ConsentStatus).toBe('OptedIn');
    });

    it('rung 5: nothing recorded', () => {
        expect(ResolveConsentForScope([], { PurposeID: PURPOSE })).toBeNull();
        expect(ResolveConsentForScope([consent('OptedOut', PURPOSE, ORG_A)], {})).toBeNull();
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
