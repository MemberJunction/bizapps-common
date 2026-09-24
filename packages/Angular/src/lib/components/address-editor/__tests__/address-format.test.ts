import '@angular/compiler';
import { describe, expect, it } from 'vitest';
import type { mjBizAppsCommonAddressEntity } from '@mj-biz-apps/common-entities';
import { AddressEditorComponent } from '../address-editor.component';

const format1 = (a: Partial<mjBizAppsCommonAddressEntity>) =>
    AddressEditorComponent.prototype.formatAddressLine1.call(null, a as mjBizAppsCommonAddressEntity);

describe('AddressEditorComponent.formatAddressLine1', () => {
    it('joins Line1 and Line2', () => {
        expect(format1({ Line1: '123 Main St', Line2: 'Suite 200' })).toBe('123 Main St, Suite 200');
    });

    it('returns Line1 alone when Line2 is empty', () => {
        expect(format1({ Line1: '123 Main St', Line2: null })).toBe('123 Main St');
    });

    it('returns Line2 without a leading separator when Line1 is empty', () => {
        expect(format1({ Line1: null, Line2: 'Suite 200' } as never)).toBe('Suite 200');
    });

    it('returns an empty string for a location-only address', () => {
        expect(format1({ Line1: '', Line2: null })).toBe('');
    });
});
