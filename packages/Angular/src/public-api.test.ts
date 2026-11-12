import '@angular/compiler';
import { describe, expect, it } from 'vitest';
import { mjBizAppsCommonAddressLinkFormComponent } from './public-api';
import { mjBizAppsCommonAddressLinkFormComponent as DirectComponent } from './lib/generated/Entities/mjBizAppsCommonAddressLink/mjbizappscommonaddresslink.form.component';

describe('Angular public-api', () => {
    it('exports mjBizAppsCommonAddressLinkFormComponent', () => {
        expect(mjBizAppsCommonAddressLinkFormComponent).toBeDefined();
        expect(mjBizAppsCommonAddressLinkFormComponent).toBe(DirectComponent);
    });
});
