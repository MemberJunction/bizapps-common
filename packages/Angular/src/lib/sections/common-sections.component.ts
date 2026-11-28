import { ChangeDetectionStrategy, ChangeDetectorRef, Component, inject } from '@angular/core';
import { RegisterClass } from '@memberjunction/global';
import { BaseResourceComponent, NavigationService } from '@memberjunction/ng-shared';
import { MJPageLayoutComponent } from '@memberjunction/ng-ui-components';
import type { ResourceData } from '@memberjunction/core-entities';
import type { FormNavigationEvent } from '@memberjunction/ng-base-forms';
import { CommonDashboardPageComponent } from '../pages/common-dashboard.page';
import { CommonPeoplePageComponent } from '../pages/people-list.page';
import { CommonOrganizationsPageComponent } from '../pages/organizations-list.page';
import { CommonRelationshipGraphComponent } from '../components/relationship-graph/common-relationship-graph.component';
import { CommonActivitiesPageComponent } from '../pages/activities-dashboard.page';
import { CommonOffboardingPageComponent } from '../pages/offboarding.page';

@Component({
    selector: 'bizapps-common-directory-resource',
    standalone: true,
    imports: [MJPageLayoutComponent, CommonDashboardPageComponent],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <mj-page-layout>
            <bizapps-common-dashboard-page></bizapps-common-dashboard-page>
        </mj-page-layout>
    `,
    styles: [`:host { display: block; width: 100%; height: 100%; }`],
})
@RegisterClass(BaseResourceComponent, 'CommonDirectoryResource')
export class CommonDirectoryResource extends BaseResourceComponent {
    protected readonly navService = inject(NavigationService, { optional: true });

    override ngOnInit(): void {
        super.ngOnInit();
        queueMicrotask(() => {
            this.NotifyLoadStarted();
            this.NotifyLoadComplete();
        });
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
    imports: [MJPageLayoutComponent, CommonPeoplePageComponent],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <mj-page-layout>
            <bizapps-common-people-page></bizapps-common-people-page>
        </mj-page-layout>
    `,
    styles: [`:host { display: block; width: 100%; height: 100%; }`],
})
@RegisterClass(BaseResourceComponent, 'CommonPeopleResource')
export class CommonPeopleResource extends BaseResourceComponent {
    protected readonly navService = inject(NavigationService, { optional: true });

    override ngOnInit(): void {
        super.ngOnInit();
        queueMicrotask(() => {
            this.NotifyLoadStarted();
            this.NotifyLoadComplete();
        });
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
    imports: [MJPageLayoutComponent, CommonOrganizationsPageComponent],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <mj-page-layout>
            <bizapps-common-organizations-page></bizapps-common-organizations-page>
        </mj-page-layout>
    `,
    styles: [`:host { display: block; width: 100%; height: 100%; }`],
})
@RegisterClass(BaseResourceComponent, 'CommonOrganizationsResource')
export class CommonOrganizationsResource extends BaseResourceComponent {
    protected readonly navService = inject(NavigationService, { optional: true });

    override ngOnInit(): void {
        super.ngOnInit();
        queueMicrotask(() => {
            this.NotifyLoadStarted();
            this.NotifyLoadComplete();
        });
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
    imports: [MJPageLayoutComponent, CommonRelationshipGraphComponent],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <mj-page-layout>
            <div class="mjc-graph-shell">
                <bizapps-relationship-graph [Height]="'100%'" (Navigate)="onNavigate($event)"></bizapps-relationship-graph>
            </div>
        </mj-page-layout>
    `,
    styles: [`
        :host { display: block; width: 100%; height: 100%; }
        .mjc-graph-shell { padding: var(--mj-space-6, 24px); width: 100%; height: 100%; box-sizing: border-box; }
    `],
})
@RegisterClass(BaseResourceComponent, 'CommonRelationshipGraphResource')
export class CommonRelationshipGraphResource extends BaseResourceComponent {
    private navService = inject(NavigationService, { optional: true });

    override ngOnInit(): void {
        super.ngOnInit();
        queueMicrotask(() => {
            this.NotifyLoadStarted();
            this.NotifyLoadComplete();
        });
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
    imports: [MJPageLayoutComponent, CommonActivitiesPageComponent],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <mj-page-layout>
            <bizapps-common-activities-page></bizapps-common-activities-page>
        </mj-page-layout>
    `,
    styles: [`:host { display: block; width: 100%; height: 100%; }`],
})
@RegisterClass(BaseResourceComponent, 'CommonActivitiesResource')
export class CommonActivitiesResource extends BaseResourceComponent {
    protected readonly navService = inject(NavigationService, { optional: true });

    override ngOnInit(): void {
        super.ngOnInit();
        queueMicrotask(() => {
            this.NotifyLoadStarted();
            this.NotifyLoadComplete();
        });
    }

    async GetResourceDisplayName(_data: ResourceData): Promise<string> {
        return 'Activities';
    }

    async GetResourceIconClass(_data: ResourceData): Promise<string> {
        return 'fa-solid fa-bolt';
    }
}

/**
 * Offboarding: a departed person's open items across every app, and bulk reassignment. The picked
 * leaver round-trips through the tab's query params (`leaver=user:<id>` or `leaver=employee:<id>`),
 * so a refreshed or shared tab reopens on the same person.
 */
@Component({
    selector: 'bizapps-common-offboarding-resource',
    standalone: true,
    imports: [CommonOffboardingPageComponent],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `<bizapps-common-offboarding-page [LeaverKey]="LeaverKey" (LeaverKeyChange)="OnLeaverChanged($event)"></bizapps-common-offboarding-page>`,
    styles: [`:host { display: block; width: 100%; height: 100%; }`],
})
@RegisterClass(BaseResourceComponent, 'CommonOffboardingResource')
export class CommonOffboardingResource extends BaseResourceComponent {
    private readonly cdr = inject(ChangeDetectorRef);
    public LeaverKey: string | null = null;

    override ngOnInit(): void {
        super.ngOnInit();
        this.NotifyLoadComplete();
    }

    protected override OnQueryParamsChanged(params: Record<string, string>, _source: 'popstate' | 'deeplink'): void {
        this.LeaverKey = params['leaver'] ?? null;
        this.cdr.markForCheck();
    }

    public OnLeaverChanged(key: string | null): void {
        this.LeaverKey = key;
        this.UpdateQueryParams({ leaver: key });
    }

    async GetResourceDisplayName(_data: ResourceData): Promise<string> {
        return 'Offboarding';
    }

    async GetResourceIconClass(_data: ResourceData): Promise<string> {
        return 'fa-solid fa-user-minus';
    }
}

export function LoadCommonSectionResources(): void {
    // Referencing the classes keeps @RegisterClass visible to the bundler.
    void CommonDirectoryResource;
    void CommonPeopleResource;
    void CommonOrganizationsResource;
    void CommonRelationshipGraphResource;
    void CommonActivitiesResource;
    void CommonOffboardingResource;
}
