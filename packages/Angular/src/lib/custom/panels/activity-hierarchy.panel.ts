import { Component, ChangeDetectionStrategy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel, BaseFormsModule, FormNavigationEvent } from '@memberjunction/ng-base-forms';
import { HierarchyTreeComponent, HierarchyTreeConfig } from '@memberjunction/ng-hierarchy-tree';
import { UserInfoEngine } from '@memberjunction/core-entities';
import { mjBizAppsCommonActivityEntity } from '@mj-biz-apps/common-entities';

/**
 * Visual Activity Hierarchy & Sub-activity Tree Panel.
 *
 * Attaches to `MJ_BizApps_Common: Activities` and renders an interactive
 * nested activity lineage tree powered by `@memberjunction/ng-hierarchy-tree`.
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:Activities:hierarchy',
    metadata: {
        entity: 'MJ_BizApps_Common: Activities',
        slot: 'after-related',
        sortKey: 40,
        relatedEntity: 'MJ_BizApps_Common: Activities',
        relatedJoinField: 'ParentActivityID'
    }
})
@Component({
    selector: 'bizapps-activity-hierarchy-panel',
    standalone: true,
    imports: [CommonModule, BaseFormsModule, HierarchyTreeComponent],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <mj-collapsible-panel
            SectionKey="activityHierarchy"
            SectionName="Hierarchy"
            Icon="fa-solid fa-tasks"
            Variant="related-entity"
            [Form]="FormComponent"
            [FormContext]="FormContext"
            [DefaultExpanded]="true">
            @if (Record.IsSaved) {
                <mj-hierarchy-tree
                    [Config]="treeConfig"
                    [ZoomLevel]="persistedZoomLevel"
                    (ZoomChange)="onZoomChange($event)"
                    (Navigate)="onNavigate($event)">
                </mj-hierarchy-tree>
            }
        </mj-collapsible-panel>
    `,
    styles: [`
        :host {
            display: flex;
            flex-direction: column;
            width: 100%;
            height: 100%;
            min-height: 640px;
            min-height: calc(100vh - 280px);
            flex: 1;
            margin-bottom: 20px;
        }
    `]
})
export class ActivityHierarchyPanel extends BaseFormPanel<mjBizAppsCommonActivityEntity> {
    private readonly SETTING_KEY = 'mj.hierarchyTree.zoom.activities';
    private _treeConfig: HierarchyTreeConfig | null = null;
    private _cachedRecordId: string | null = null;

    public get persistedZoomLevel(): number | undefined {
        const raw = UserInfoEngine.Instance.GetSetting(this.SETTING_KEY);
        return raw ? parseFloat(raw) : undefined;
    }

    public onZoomChange(zoom: number): void {
        UserInfoEngine.Instance.SetSettingDebounced(this.SETTING_KEY, zoom.toFixed(2));
    }

    public onNavigate(event: FormNavigationEvent): void {
        if (this.FormComponent?.OnFormNavigate) {
            this.FormComponent.OnFormNavigate(event);
        }
    }

    public get treeConfig(): HierarchyTreeConfig {
        const recId = this.Record?.ID || null;
        if (!this._treeConfig || this._cachedRecordId !== recId) {
            this._cachedRecordId = recId;
            this._treeConfig = {
                EntityName: 'MJ_BizApps_Common: Activities',
                ParentField: 'ParentActivityID',
                NameField: 'Subject',
                SubtitleField: 'ActivityType',
                DefaultIcon: 'fa-solid fa-tasks',
                DefaultColor: '#ec4899',
                ActiveRecordID: recId || undefined,
                Height: '100%',
                MinHeight: '640px',
                ShowSearch: true,
                ShowToolbar: true,
                Orientation: 'top-to-bottom'
            };
        }
        return this._treeConfig;
    }
}
