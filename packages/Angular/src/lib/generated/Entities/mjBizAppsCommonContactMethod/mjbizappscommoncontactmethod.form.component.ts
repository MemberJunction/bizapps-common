import { Component } from '@angular/core';
import { mjBizAppsCommonContactMethodEntity } from '@memberjunction/bizapps-common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

@RegisterClass(BaseFormComponent, 'Common: Contact Methods') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommoncontactmethod-form',
    templateUrl: './mjbizappscommoncontactmethod.form.component.html'
})
export class mjBizAppsCommonContactMethodFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonContactMethodEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'linkedRecords', sectionName: 'Linked Records', isExpanded: true },
            { sectionKey: 'contactDetails', sectionName: 'Contact Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false }
        ]);
    }
}

