import '@angular/compiler';
import { describe, it, expect } from 'vitest';
import '../../../../public-api';
import { MJGlobal } from '@memberjunction/global';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';
import { CompanySenderIdentitiesPanel } from '../company-sender-identities.panel';

describe('CompanySenderIdentitiesPanel registration', () => {
    it('is registered on BaseFormPanel for the Company form, after the related sections', () => {
        const regs = MJGlobal.Instance.ClassFactory.GetAllRegistrations(BaseFormPanel);
        const reg = regs.find((r) => r.Key === 'form-panel:Companies:sender-identities');
        const metadata = reg?.Metadata as Record<string, unknown> | undefined;

        expect(reg?.SubClass).toBe(CompanySenderIdentitiesPanel);
        expect(metadata?.['entity']).toBe('MJ: Companies');
        expect(metadata?.['slot']).toBe('after-related');
        expect(metadata?.['replacesSectionKey']).toBeUndefined();
    });
});
