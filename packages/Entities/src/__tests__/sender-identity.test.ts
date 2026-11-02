import { describe, it, expect } from 'vitest';
import { DefaultSenderForCompany, IsSenderAllowedForCompany, NormalizeSenderIdentity, SenderDomain, type CompanySenderIdentityRow } from '../sender-identity.js';

const ACME = 'A0000000-0000-4000-8000-00000000000A';
const BOLT = 'B0000000-0000-4000-8000-00000000000B';
const rows: CompanySenderIdentityRow[] = [
    { CompanyID: ACME, Kind: 'Mailbox', Address: 'hr@acme.com', DisplayName: 'Acme HR', IsDefault: true },
    { CompanyID: ACME, Kind: 'Domain', Address: 'acme-jobs.com', DisplayName: null, IsDefault: false },
    { CompanyID: BOLT, Kind: 'Mailbox', Address: 'jobs@bolt.io', DisplayName: null, IsDefault: true },
];

describe('SenderDomain', () => {
    it('returns the lower-cased part after the last @', () => expect(SenderDomain('A@B@Acme.COM')).toBe('acme.com'));
    it('returns null when there is no @', () => expect(SenderDomain('acme.com')).toBeNull());
});

describe('IsSenderAllowedForCompany', () => {
    it('matches a Mailbox row case- and space-insensitively', () => expect(IsSenderAllowedForCompany(ACME, '  HR@Acme.com ', rows)).toBe(true));
    it('matches a Domain row by exact domain', () => expect(IsSenderAllowedForCompany(ACME, 'anyone@acme-jobs.com', rows)).toBe(true));
    it('does not match a subdomain of a Domain row', () => expect(IsSenderAllowedForCompany(ACME, 'x@mail.acme-jobs.com', rows)).toBe(false));
    it("ignores another company's rows", () => expect(IsSenderAllowedForCompany(ACME, 'jobs@bolt.io', rows)).toBe(false));
    it('is false with no rows', () => expect(IsSenderAllowedForCompany(ACME, 'hr@acme.com', [])).toBe(false));
    it('matches CompanyID regardless of case', () => expect(IsSenderAllowedForCompany(ACME.toLowerCase(), 'hr@acme.com', rows)).toBe(true));
    it.each(['@acme.com', 'h r@acme.com'])('is false for the malformed address "%s" even with a Domain row for acme.com', (bad) => {
        const domainRows = [{ CompanyID: ACME, Kind: 'Domain', Address: 'acme.com', DisplayName: null, IsDefault: false }] as const;
        expect(IsSenderAllowedForCompany(ACME, bad, domainRows)).toBe(false);
    });
    it('is false for a bare domain even when a Mailbox row shares it', () => expect(IsSenderAllowedForCompany(ACME, 'acme.com', rows)).toBe(false));
});

describe('DefaultSenderForCompany', () => {
    it('returns the default Mailbox as a From pair', () => expect(DefaultSenderForCompany(ACME, rows)).toEqual({ from: 'hr@acme.com', fromName: 'Acme HR' }));
    it('matches CompanyID regardless of case', () => expect(DefaultSenderForCompany(ACME.toLowerCase(), rows)).toEqual({ from: 'hr@acme.com', fromName: 'Acme HR' }));
    it("ignores another company's default Mailbox", () => expect(DefaultSenderForCompany(BOLT, rows.slice(0, 2))).toBeNull());
    it('returns null with no rows', () => expect(DefaultSenderForCompany(ACME, [])).toBeNull());
    it('returns null when the default is a Domain row', () => {
        const only = [{ CompanyID: ACME, Kind: 'Domain', Address: 'acme.com', DisplayName: null, IsDefault: true }] as const;
        expect(DefaultSenderForCompany(ACME, only)).toBeNull();
    });
});

describe('NormalizeSenderIdentity', () => {
    it('trims and lower-cases a Mailbox', () => expect(NormalizeSenderIdentity('Mailbox', '  HR@Acme.com ', 'Acme HR')).toEqual({ address: 'hr@acme.com', displayName: 'Acme HR', errors: [], displayNameErrors: [] }));
    it('rejects a Mailbox without @ or without a dotted domain', () => {
        expect(NormalizeSenderIdentity('Mailbox', 'acme.com', null).errors).toHaveLength(1);
        expect(NormalizeSenderIdentity('Mailbox', 'hr@acme', null).errors).toHaveLength(1);
        expect(NormalizeSenderIdentity('Mailbox', 'a@b@acme.com', null).errors).toHaveLength(1);
    });
    it('rejects a Domain with @ or without a dot', () => {
        expect(NormalizeSenderIdentity('Domain', 'hr@acme.com', null).errors).toHaveLength(1);
        expect(NormalizeSenderIdentity('Domain', 'localhost', null).errors).toHaveLength(1);
    });
    it('rejects a DisplayName on a Domain row', () => expect(NormalizeSenderIdentity('Domain', 'acme.com', 'Acme').errors).toHaveLength(1));
    it('reports a Domain display name as a display-name error only', () => {
        const result = NormalizeSenderIdentity('Domain', 'acme.com', 'Acme');
        expect(result.displayNameErrors).toEqual(result.errors);
        expect(NormalizeSenderIdentity('Domain', 'hr@acme.com', null).displayNameErrors).toEqual([]);
    });
    it('rejects an empty address', () => expect(NormalizeSenderIdentity('Mailbox', '   ', null).errors).toHaveLength(1));
    it('empty-address error names the raw input', () => expect(NormalizeSenderIdentity('Mailbox', '   ', null).errors[0]).toContain('"   "'));
    it('every error names the value', () => expect(NormalizeSenderIdentity('Domain', 'hr@acme.com', null).errors[0]).toContain('hr@acme.com'));
});
