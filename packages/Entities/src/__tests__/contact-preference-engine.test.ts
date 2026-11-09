import { describe, expect, it } from 'vitest';
import { ConsentRow, ContactPreferenceEngine } from '../contact-preference-engine.js';

const METHOD = '11111111-1111-1111-1111-111111111111';
const PURPOSE = '22222222-2222-2222-2222-222222222222';
const ORG_A = '33333333-3333-3333-3333-333333333333';
const ORG_B = '44444444-4444-4444-4444-444444444444';

const consent = (status: ConsentRow['ConsentStatus'], purposeID: string | null, requestingOrganizationID: string | null): ConsentRow => ({
    ContactMethodID: METHOD,
    ConsentPurposeID: purposeID,
    RequestingOrganizationID: requestingOrganizationID,
    ConsentStatus: status,
});

describe('ContactPreferenceEngine.ResolveConsentForScope', () => {
    const rows = [
        consent('Opted In', null, null),       // general, anyone
        consent('Opted Out', PURPOSE, null),   // Marketing, anyone
        consent('Opted In', PURPOSE, ORG_A),   // Marketing, asked by org A
        consent('Opted Out', null, ORG_B),     // general, asked by org B
    ];
    const resolve = ContactPreferenceEngine.ResolveConsentForScope;

    it('rung 1: this purpose asked by this organization wins over everything', () => {
        expect(resolve(rows, { PurposeID: PURPOSE, RequestingOrganizationID: ORG_A })?.ConsentStatus).toBe('Opted In');
        expect(resolve(rows, { PurposeID: PURPOSE, RequestingOrganizationID: ORG_A.toLowerCase() })?.ConsentStatus).toBe('Opted In');
    });

    it('rung 2: this purpose from anyone beats the organization-wide general row', () => {
        expect(
            resolve(
                [consent('Opted In', PURPOSE, null), consent('Opted Out', null, ORG_B)],
                { PurposeID: PURPOSE, RequestingOrganizationID: ORG_B },
            )?.ConsentStatus,
        ).toBe('Opted In');
        expect(resolve(rows, { PurposeID: PURPOSE, RequestingOrganizationID: ORG_B })?.ConsentStatus).toBe('Opted Out');
    });

    it('general never means default: a general opt-in loses to a Marketing opt-out for a Marketing question', () => {
        expect(resolve(rows, { PurposeID: PURPOSE })?.ConsentStatus).toBe('Opted Out');
    });

    it("rung 3: a question with no purpose uses the organization's general row", () => {
        expect(resolve(rows, { RequestingOrganizationID: ORG_B })?.ConsentStatus).toBe('Opted Out');
    });

    it('rung 4: the general row from anyone answers everything else', () => {
        expect(resolve(rows, {})?.ConsentStatus).toBe('Opted In');
        expect(resolve(rows, { RequestingOrganizationID: ORG_A })?.ConsentStatus).toBe('Opted In');
        const other = '55555555-5555-5555-5555-555555555555';
        expect(resolve(rows, { PurposeID: other, RequestingOrganizationID: ORG_A })?.ConsentStatus).toBe('Opted In');
    });

    it('rung 5: nothing recorded', () => {
        expect(resolve([], { PurposeID: PURPOSE })).toBeNull();
        expect(resolve([consent('Opted Out', PURPOSE, ORG_A)], {})).toBeNull();
    });
});

describe('ContactPreferenceEngine.DecideContact', () => {
    const decide = ContactPreferenceEngine.DecideContact;

    it('refuses when there is no contact method on the channel', () => {
        const d = decide([], 'SMS');
        expect(d).toMatchObject({ Allowed: false, Status: 'No Contact Method' });
        expect(d.Reason).toContain('SMS');
    });

    it('allows when any method on the channel is opted in, even beside an opt-out', () => {
        expect(decide(['Opted Out', 'Opted In'], 'Email')).toMatchObject({ Allowed: true, Status: 'Opted In' });
    });

    it('refuses when every method on the channel is opted out', () => {
        expect(decide(['Opted Out', 'Opted Out'], 'Phone')).toMatchObject({ Allowed: false, Status: 'Opted Out' });
    });

    it('allows an unspecified status by default, because every pre-existing method has nothing recorded', () => {
        expect(decide(['Opted Out', 'Not Specified'], 'Email')).toMatchObject({ Allowed: true, Status: 'Not Specified' });
    });

    it('refuses an unspecified status when the policy requires an explicit opt-in', () => {
        const d = decide(['Not Specified'], 'Email', { RequireOptIn: true });
        expect(d).toMatchObject({ Allowed: false, Status: 'Not Specified' });
        expect(d.Reason).toContain('required');
    });
});

describe('ContactPreferenceEngine.CanContact with an unknown purpose', () => {
    it('refuses with Unknown Purpose instead of answering from the general consent', async () => {
        const engine = Object.create(ContactPreferenceEngine.prototype) as ContactPreferenceEngine;
        Object.defineProperty(engine, 'Purposes', { value: [{ ID: PURPOSE, Name: 'Marketing', IsActive: true, Sequence: 10 }] });
        Object.defineProperty(engine, 'EnsureLoaded', { value: async () => undefined });
        const d = await engine.CanContact({ PersonID: METHOD }, 'Email', { Purpose: 'Markting' });
        expect(d).toMatchObject({ Allowed: false, Status: 'Unknown Purpose' });
        expect(d.Reason).toContain('Markting');
    });
});

describe('ContactPreferenceEngine.Channels', () => {
    it('lists the three core message types Comms routes on', () => {
        expect([...ContactPreferenceEngine.Channels]).toEqual(['Email', 'Phone', 'SMS']);
    });
});
