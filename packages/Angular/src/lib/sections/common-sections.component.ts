import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RegisterClass } from '@memberjunction/global';
import { BaseResourceComponent, NavigationService } from '@memberjunction/ng-shared';
import type { ResourceData } from '@memberjunction/core-entities';
import type { FormNavigationEvent } from '@memberjunction/ng-base-forms';
import { CommonDashboardPageComponent } from '../pages/common-dashboard.page';
import { CommonPeoplePageComponent } from '../pages/people-list.page';
import { CommonOrganizationsPageComponent } from '../pages/organizations-list.page';
import { CommonRelationshipGraphComponent } from '../components/relationship-graph/common-relationship-graph.component';
import { CommonActivitiesPageComponent } from '../pages/activities-dashboard.page';

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

@Component({
    selector: 'bizapps-common-relationship-graph-resource',
    standalone: true,
    imports: [CommonRelationshipGraphComponent],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <div style="padding: 24px; width: 100%; height: 100%; box-sizing: border-box;">
            <bizapps-relationship-graph [Height]="'100%'" (Navigate)="onNavigate($event)"></bizapps-relationship-graph>
        </div>
    `,
    styles: [`:host { display: block; width: 100%; height: 100%; }`],
})
@RegisterClass(BaseResourceComponent, 'CommonRelationshipGraphResource')
export class CommonRelationshipGraphResource extends BaseResourceComponent {
    private navService = inject(NavigationService, { optional: true });

    override ngOnInit(): void {
        super.ngOnInit();
        this.NotifyLoadComplete();
    }

    public onNavigate(event: FormNavigationEvent): void {
        if (!this.navService) return;
        if (event.Kind === 'record' && event.EntityName && event.PrimaryKey) {
            this.navService.OpenEntityRecord(event.EntityName, event.PrimaryKey);
        }
    }

    async GetResourceDisplayName(_data: ResourceData): Promise<string> {
        return 'Relationships';
    }

    async GetResourceIconClass(_data: ResourceData): Promise<string> {
        return 'fa-solid fa-circle-nodes';
    }
}

@Component({
    selector: 'bizapps-common-activities-resource',
    standalone: true,
    imports: [CommonActivitiesPageComponent],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `<bizapps-common-activities-page></bizapps-common-activities-page>`,
    styles: [`:host { display: block; width: 100%; height: 100%; }`],
})
@RegisterClass(BaseResourceComponent, 'CommonActivitiesResource')
export class CommonActivitiesResource extends BaseResourceComponent {
    override ngOnInit(): void {
        super.ngOnInit();
        this.NotifyLoadComplete();
    }

    async GetResourceDisplayName(_data: ResourceData): Promise<string> {
        return 'Activities';
    }

    async GetResourceIconClass(_data: ResourceData): Promise<string> {
        return 'fa-solid fa-bolt';
    }
}

export function LoadCommonSectionResources(): void {
    // Referencing the classes keeps @RegisterClass visible to the bundler.
    void CommonDirectoryResource;
    void CommonPeopleResource;
    void CommonOrganizationsResource;
    void CommonRelationshipGraphResource;
    void CommonActivitiesResource;
}
