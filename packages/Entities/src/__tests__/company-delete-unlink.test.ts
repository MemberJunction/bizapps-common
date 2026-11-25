/**
 * Copyright (c) MemberJunction.com
 * SPDX-License-Identifier: BUSL-1.1
 */
import { afterEach, describe, expect, it } from 'vitest';
import {
    BuildOrganizationLinkedCompanyFilter,
    CompanyMirrorError,
    DEFAULT_COMPANY_DELETE_ARCHIVE_STATUS,
    DEFAULT_COMPANY_MIRROR_DELETE_POLICY,
    GetCompanyMirrorDeletePolicy,
    RegisterCompanyMirrorDeletePolicy,
    ResetCompanyMirrorDeletePolicy,
    ResolveOrganizationUnlinkStatus,
    SelectLinkedOrganizationsForUnlink,
    type OrganizationLookupCandidate,
    type OrganizationMirrorStatus,
} from '../company-organization-mirror.js';

const COMPANY_ID = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const OTHER_COMPANY_ID = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const ORG_A = '11111111-1111-4111-8111-111111111111';
const ORG_B = '22222222-2222-4222-8222-222222222222';
const ORG_C = '33333333-3333-4333-8333-333333333333';

describe('Company delete unlink/archive pure policy & filter helpers', () => {
    afterEach(() => {
        ResetCompanyMirrorDeletePolicy();
    });

    it('builds dual-dialect-safe ANSI SQL LinkedCompanyID filter and rejects invalid UUIDs', () => {
        const filter = BuildOrganizationLinkedCompanyFilter(COMPANY_ID);
        expect(filter).toBe(`LinkedCompanyID = '${COMPANY_ID}'`);
        expect(filter).not.toMatch(/[\[\]"]/);
        expect(filter).not.toMatch(/\b(ISNULL|CHARINDEX|ILIKE|TOP)\b/i);

        try {
            BuildOrganizationLinkedCompanyFilter("bad' OR 1=1 --");
            expect.fail('Expected INVALID_COMPANY_ID error');
        } catch (err) {
            expect(err).toBeInstanceOf(CompanyMirrorError);
            const mirrorErr = err as CompanyMirrorError;
            expect(mirrorErr.Code).toBe('INVALID_COMPANY_ID');
            expect(mirrorErr.Context.Operation).toBe('unlink');
            expect(mirrorErr.Context.CompanyID).toBe("bad' OR 1=1 --");
        }
    });

    it('selects only Organizations linked to the deleted Company, deduplicates, and sorts deterministically', () => {
        const candidates: OrganizationLookupCandidate[] = [
            { ID: ORG_B.toUpperCase(), Name: 'Northwind Subsidiary', LinkedCompanyID: COMPANY_ID.toUpperCase(), Status: 'Active' },
            { ID: ORG_C, Name: 'Foreign Client', LinkedCompanyID: OTHER_COMPANY_ID, Status: 'Active' },
            { ID: ORG_A, Name: 'External Unlinked', LinkedCompanyID: null, Status: 'Active' },
            { ID: ORG_A, Name: 'Northwind Primary', LinkedCompanyID: COMPANY_ID, Status: 'Active' },
            { ID: ORG_B.toLowerCase(), Name: 'Northwind Subsidiary Dup', LinkedCompanyID: COMPANY_ID, Status: 'Active' },
        ];

        const selected = SelectLinkedOrganizationsForUnlink(candidates, COMPANY_ID);
        expect(selected.map((row) => row.ID.toLowerCase())).toEqual([ORG_A, ORG_B]);
    });

    it('resolves safe unlink/archive status without regressing Dissolved or Inactive records', () => {
        expect(DEFAULT_COMPANY_DELETE_ARCHIVE_STATUS).toBe('Inactive');
        expect(DEFAULT_COMPANY_MIRROR_DELETE_POLICY).toEqual({ ArchiveStatus: 'Inactive' });

        expect(ResolveOrganizationUnlinkStatus('Active')).toBe('Inactive');
        expect(ResolveOrganizationUnlinkStatus('Inactive')).toBe('Inactive');
        expect(ResolveOrganizationUnlinkStatus('Dissolved')).toBe('Dissolved');
        expect(ResolveOrganizationUnlinkStatus('Active', 'Dissolved')).toBe('Dissolved');
        expect(ResolveOrganizationUnlinkStatus('Active', null)).toBe('Active');
        expect(ResolveOrganizationUnlinkStatus(null, 'Inactive')).toBe('Inactive');
        expect(ResolveOrganizationUnlinkStatus(null, null)).toBeNull();
    });

    it('supports runtime delete-unlink policy registration, per-call overrides, and clean resets', () => {
        expect(GetCompanyMirrorDeletePolicy()).toEqual({ ArchiveStatus: 'Inactive' });

        const dissolvedStatus: OrganizationMirrorStatus = 'Dissolved';
        RegisterCompanyMirrorDeletePolicy({ ArchiveStatus: dissolvedStatus });
        expect(GetCompanyMirrorDeletePolicy()).toEqual({ ArchiveStatus: 'Dissolved' });
        expect(GetCompanyMirrorDeletePolicy({ ArchiveStatus: null })).toEqual({ ArchiveStatus: null });

        ResetCompanyMirrorDeletePolicy();
        expect(GetCompanyMirrorDeletePolicy()).toEqual({ ArchiveStatus: 'Inactive' });
    });
});
