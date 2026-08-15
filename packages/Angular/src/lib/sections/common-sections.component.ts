import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RegisterClass } from '@memberjunction/global';
import { BaseResourceComponent } from '@memberjunction/ng-shared';
import type { ResourceData } from '@memberjunction/core-entities';
import { CommonDashboardPageComponent } from '../pages/common-dashboard.page';
import { CommonPeoplePageComponent } from '../pages/people-list.page';
import { CommonOrganizationsPageComponent } from '../pages/organizations-list.page';

@Component({
    selector: 'bizapps-common-directory-resource',
    standalone: true,
    imports: [CommonDashboardPageComponent],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `<bizapps-common-dashboard-page></bizapps-common-dashboard-page>`,
    styles: [`:host { display: block; width: 100%; height: 100%; }`],
})
@RegisterClass(BaseResourceComponent, 'CommonDirectoryResource')
export class CommonDirectoryResource extends BaseResourceComponent {
    override ngOnInit(): void {
        super.ngOnInit();
        this.NotifyLoadComplete();
    }

    async GetResourceDisplayName(_data: ResourceData): Promise<string> {
        return 'Directory';
    }

    async GetResourceIconClass(_data: ResourceData): Promise<string> {
        return 'fa-solid fa-gauge-high';
    }
}

@Component({
    selector: 'bizapps-common-people-resource',
    standalone: true,
    imports: [CommonPeoplePageComponent],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `<bizapps-common-people-page></bizapps-common-people-page>`,
    styles: [`:host { display: block; width: 100%; height: 100%; }`],
})
@RegisterClass(BaseResourceComponent, 'CommonPeopleResource')
export class CommonPeopleResource extends BaseResourceComponent {
    override ngOnInit(): void {
        super.ngOnInit();
        this.NotifyLoadComplete();
    }

    async GetResourceDisplayName(_data: ResourceData): Promise<string> {
        return 'People';
    }

    async GetResourceIconClass(_data: ResourceData): Promise<string> {
        return 'fa-solid fa-user';
    }
}

@Component({
    selector: 'bizapps-common-organizations-resource',
    standalone: true,
    imports: [CommonOrganizationsPageComponent],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `<bizapps-common-organizations-page></bizapps-common-organizations-page>`,
    styles: [`:host { display: block; width: 100%; height: 100%; }`],
})
@RegisterClass(BaseResourceComponent, 'CommonOrganizationsResource')
export class CommonOrganizationsResource extends BaseResourceComponent {
    override ngOnInit(): void {
        super.ngOnInit();
        this.NotifyLoadComplete();
    }

    async GetResourceDisplayName(_data: ResourceData): Promise<string> {
        return 'Organizations';
    }

    async GetResourceIconClass(_data: ResourceData): Promise<string> {
        return 'fa-solid fa-building';
    }
}

export function LoadCommonSectionResources(): void {
    // Referencing the classes keeps @RegisterClass visible to the bundler.
    void CommonDirectoryResource;
    void CommonPeopleResource;
    void CommonOrganizationsResource;
}
