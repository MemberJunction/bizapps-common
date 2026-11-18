import '@angular/compiler';
import { describe, it, expect } from 'vitest';
import '../../../../public-api';
import { MJGlobal } from '@memberjunction/global';
import { BaseFormPanel, FormPanelRegistrationMetadata, ResolveFormContributions } from '@memberjunction/ng-base-forms';
import { CompanySenderIdentitiesPanel } from '../company-sender-identities.panel';

const ENTITY = 'MJ_BizApps_Common: Company Sender Identities';

function registration(): { Priority: number; Metadata: FormPanelRegistrationMetadata } {
    const reg = MJGlobal.Instance.ClassFactory.GetAllRegistrations(BaseFormPanel).find((r) => r.SubClass === CompanySenderIdentitiesPanel);
    if (!reg) throw new Error('CompanySenderIdentitiesPanel is not registered on BaseFormPanel');
    return { Priority: reg.Priority ?? 0, Metadata: reg.Metadata as FormPanelRegistrationMetadata };
}

describe('CompanySenderIdentitiesPanel registration', () => {
    // The migration's EntityRelationship (MJ: Companies -> Company Sender Identities, DisplayInForm = 1)
    // makes MJ mount a stock related-entity grid unless a panel claims it.
    it('claims the Company -> Company Sender Identities relationship, so MJ mounts no duplicate stock grid', () => {
        const result = ResolveFormContributions({
            EntityName: 'MJ: Companies',
            RelatedEntities: [{ RelatedEntity: ENTITY, RelatedEntityID: 'rel-1', RelatedEntityJoinField: 'CompanyID', DisplayInForm: true }],
            IsaChildEntityIDs: [],
            Registrations: [registration()],
            BakedSectionKeys: [],
            ShowRelatedEntities: true,
        });

        expect(result.StockGrids.filter((w) => w.RelatedEntity === ENTITY)).toEqual([]);
    });

    // MJ derives the left-nav rail key from contributionKey when present; only the derived key
    // ('companySenderIdentities') matches the template's SectionKey, so contributionKey must be absent.
    it('declares relatedEntity/relatedJoinField and no contributionKey', () => {
        const meta = registration().Metadata;
        expect(meta.relatedEntity).toBe(ENTITY);
        expect(meta.relatedJoinField).toBe('CompanyID');
        expect(meta.contributionKey).toBeUndefined();
    });

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
