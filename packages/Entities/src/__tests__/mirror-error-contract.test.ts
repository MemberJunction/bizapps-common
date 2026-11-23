/**
 * Copyright (c) MemberJunction.com
 * SPDX-License-Identifier: BUSL-1.1
 */
import { describe, expect, it } from 'vitest';
import { RemoteOperationError } from '@memberjunction/core';
import {
    CompanyMirrorError,
    FormatCompanyMirrorError,
    NormalizeMirrorErrorCause,
    type CompanyMirrorErrorDetails,
    type OrganizationMirrorStatus,
} from '../company-organization-mirror.js';

const COMPANY_ID = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const ORG_ID = '11111111-1111-4111-8111-111111111111';

describe('Structured Company <-> Organization mirror error contract', () => {
    it('constructs CompanyMirrorError as a RemoteOperationError with structured context and details', () => {
        const cause = NormalizeMirrorErrorCause(new Error('SQL timeout'));
        const details: CompanyMirrorErrorDetails = {
            Code: 'ORGANIZATION_SAVE_FAILED',
            Context: {
                CompanyID: COMPANY_ID,
                CompanyName: 'Acme Corp',
                OrganizationID: ORG_ID,
                Operation: 'link',
            },
            DiagnosticMessage: 'Could not save linked Organization',
            Cause: cause,
        };

        const err = new CompanyMirrorError(details);
        expect(err).toBeInstanceOf(Error);
        expect(err).toBeInstanceOf(RemoteOperationError);
        expect(err.name).toBe('CompanyMirrorError');
        expect(err.Code).toBe('ORGANIZATION_SAVE_FAILED');
        expect(err.ResultCode).toBe('ORGANIZATION_SAVE_FAILED');
        expect(err.Context).toEqual(details.Context);
        expect(err.DiagnosticMessage).toBe('Could not save linked Organization');
        expect(err.Cause?.Message).toBe('SQL timeout');
        expect(err.ToDetails()).toEqual(details);
        expect(FormatCompanyMirrorError(err.ToDetails())).toBe(
            '[ORGANIZATION_SAVE_FAILED] Could not save linked Organization',
        );
    });

    it('normalizes string and undefined error causes cleanly without untyped casts', () => {
        expect(NormalizeMirrorErrorCause(undefined)).toBeUndefined();
        expect(NormalizeMirrorErrorCause('raw string failure')).toEqual({
            Name: 'Error',
            Message: 'raw string failure',
        });

        const typeErr = new TypeError('bad field');
        const normalized = NormalizeMirrorErrorCause(typeErr);
        expect(normalized?.Name).toBe('TypeError');
        expect(normalized?.Message).toBe('bad field');
    });

    it('derives OrganizationMirrorStatus directly from generated entity Status values', () => {
        const validStatuses: OrganizationMirrorStatus[] = ['Active', 'Dissolved', 'Inactive'];
        expect(validStatuses).toHaveLength(3);
    });
});
