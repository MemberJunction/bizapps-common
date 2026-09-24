import '@angular/compiler';
import { describe, expect, it } from 'vitest';
import type { mjBizAppsCommonAddressEntity } from '@mj-biz-apps/common-entities';
import { AddressEditorComponent } from '../address-editor.component';

const format1 = (a: Partial<mjBizAppsCommonAddressEntity>) =>
    AddressEditorComponent.prototype.formatAddressLine1.call(null, a as mjBizAppsCommonAddressEntity);
const format2 = (a: Partial<mjBizAppsCommonAddressEntity>) =>
    AddressEditorComponent.prototype.formatAddressLine2.call(null, a as mjBizAppsCommonAddressEntity);

describe('AddressEditorComponent.formatAddressLine1', () => {
    it('joins Line1 and Line2', () => {
        expect(format1({ Line1: '123 Main St', Line2: 'Suite 200' })).toBe('123 Main St, Suite 200');
    });

    it('returns Line1 alone when Line2 is empty', () => {
        expect(format1({ Line1: '123 Main St', Line2: null })).toBe('123 Main St');
    });

    it('returns Line2 without a leading separator when Line1 is empty', () => {
        expect(format1({ Line2: 'Suite 200' })).toBe('Suite 200');
    });

    it('returns an empty string for a location-only address', () => {
        expect(format1({ Line1: '', Line2: null })).toBe('');
    });
});

describe('AddressEditorComponent.formatAddressLine2', () => {
    it('joins city, region, postal code and country', () => {
        expect(format2({ City: 'Austin', StateProvince: 'TX', PostalCode: '78701', Country: 'US' })).toBe('Austin, TX, 78701, US');
    });

    it('returns country without a leading separator when it is the only part', () => {
        expect(format2({ Country: 'US' })).toBe('US');
    });

    it('skips missing parts', () => {
        expect(format2({ PostalCode: '78701', Country: 'US' })).toBe('78701, US');
    });

    it('returns an empty string when no location parts are set', () => {
        expect(format2({})).toBe('');
    });
});
