import { Component } from '@angular/core';
import { mjBizAppsCommonAddressLinkEntity } from '@memberjunction/bizapps-common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

@RegisterClass(BaseFormComponent, 'Common: Address Links') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonaddresslink-form',
    templateUrl: './mjbizappscommonaddresslink.form.component.html'
})
export class mjBizAppsCommonAddressLinkFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonAddressLinkEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'addressAssignment', sectionName: 'Address Assignment', isExpanded: true },
            { sectionKey: 'linkedRecordDetails', sectionName: 'Linked Record Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false }
        ]);
    }
}

