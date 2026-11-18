import { beforeEach, describe, expect, it, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { ActionEngineBase } from '@memberjunction/actions-base';
import type {
    mjBizAppsCommonAddressEntity,
    mjBizAppsCommonAddressLinkEntity,
} from '@mj-biz-apps/common-entities';
import { AddressEditorComponent } from '../address-editor.component';

function stubAddress(fields: Partial<mjBizAppsCommonAddressEntity>): mjBizAppsCommonAddressEntity {
    return {
        ID: 'addr-1',
        Line1: null,
        Line2: null,
        City: null,
        StateProvince: null,
        PostalCode: null,
        Country: null,
        ...fields,
    } as unknown as mjBizAppsCommonAddressEntity;
}

function stubLink(fields: Partial<mjBizAppsCommonAddressLinkEntity> = {}): mjBizAppsCommonAddressLinkEntity {
    return {
        ID: 'link-1',
        AddressID: 'addr-1',
        AddressTypeID: 'type-1',
        AddressType: 'Headquarters',
        IsPrimary: true,
        ...fields,
    } as unknown as mjBizAppsCommonAddressLinkEntity;
}

describe('AddressEditorComponent DOM rendering (#302)', () => {
    beforeEach(() => {
        vi.spyOn(ActionEngineBase.Instance, 'Config').mockResolvedValue(undefined);
    });

    it('renders both street headline and locality subline when Line1 is present', () => {
        const fixture = TestBed.createComponent(AddressEditorComponent);
        const component = fixture.componentInstance;

        component.AddressItems = [
            {
                Link: stubLink(),
                Address: stubAddress({
                    Line1: '100 Main St',
                    City: 'Austin',
                    StateProvince: 'TX',
                }),
            },
        ];
        fixture.detectChanges();

        const host: HTMLElement = fixture.nativeElement;
        const line1 = host.querySelector('.bizapps-addr-card__line1');
        const locality = host.querySelector('.bizapps-addr-card__locality');

        expect(line1).not.toBeNull();
        expect(line1?.textContent?.trim()).toBe('100 Main St');
        expect(locality).not.toBeNull();
        expect(locality?.textContent?.trim()).toBe('Austin, TX');
    });

    it('promotes the locality line to headline and omits the subline when Line1 is null', () => {
        const fixture = TestBed.createComponent(AddressEditorComponent);
        const component = fixture.componentInstance;

        component.AddressItems = [
            {
                Link: stubLink(),
                Address: stubAddress({
                    Line1: null,
                    Line2: null,
                    City: 'Austin',
                    StateProvince: 'TX',
                }),
            },
        ];
        fixture.detectChanges();

        const host: HTMLElement = fixture.nativeElement;
        const line1 = host.querySelector('.bizapps-addr-card__line1');
        const locality = host.querySelector('.bizapps-addr-card__locality');

        expect(line1).not.toBeNull();
        expect(line1?.textContent?.trim()).toBe('Austin, TX');
        expect(locality).toBeNull();
    });
});
