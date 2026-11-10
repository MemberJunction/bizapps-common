import { Component, OnInit } from '@angular/core';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';
import { UserInfoEngine } from '@memberjunction/core-entities';
import { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';
import { BizAppsFormPanel } from './bizapps-form-panel';

const VIEW_SWITCHER_STYLES = `
    .bizapps-view-switcher-bar {
        display: flex;
        justify-content: flex-end;
        align-items: center;
        margin-bottom: 14px;
    }

    .bizapps-view-segmented-group {
        display: inline-flex;
        align-items: center;
        gap: 3px;
        padding: 3px;
        background: var(--mj-bg-surface-sunken);
        border: 1px solid var(--mj-border-default);
        border-radius: 8px;
        box-shadow: var(--mj-shadow-sm);
    }

    .bizapps-view-segment-btn {
        display: inline-flex;
        align-items: center;
        gap: 7px;
        padding: 5px 14px;
        border: none;
        border-radius: 6px;
        background: transparent;
        color: var(--mj-text-secondary);
        font-size: 12px;
        font-weight: 500;
        cursor: pointer;
        transition: all 0.18s cubic-bezier(0.4, 0, 0.2, 1);
        user-select: none;
        line-height: 1.4;
    }

    .bizapps-view-segment-btn i {
        font-size: 12px;
        opacity: 0.85;
    }

    .bizapps-view-segment-btn:hover:not(.active) {
        color: var(--mj-text-primary);
        background: var(--mj-bg-surface-hover);
    }

    .bizapps-view-segment-btn.active {
        background: var(--mj-brand-primary);
        color: var(--mj-text-inverse);
        font-weight: 600;
        box-shadow: var(--mj-shadow-sm);
    }

    .bizapps-view-segment-btn.active i {
        opacity: 1;
    }
`;

/**
 * Organizations form contribution that replaces both FromOrganizationID and
 * ToOrganizationID relationship grids with a directional relationship widget and interactive graph.
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:Organizations:relationships',
    metadata: {
        entity: 'MJ_BizApps_Common: Organizations',
        slot: 'after-fields',
        sortKey: 70,
        contributionKey: 'relationships',
        whenEmpty: 'more',
        relatedEntity: 'MJ_BizApps_Common: Relationships',
    },
})
@Component({
    standalone: false,
    selector: 'bizapps-organization-relationships-panel',
    templateUrl: './organization-relationships.panel.html',
    styles: [VIEW_SWITCHER_STYLES]
})
export class OrganizationRelationshipsPanel extends BizAppsFormPanel<mjBizAppsCommonOrganizationEntity> implements OnInit {
    private static readonly PREF_KEY = 'mj.bizapps.common.organization.relationshipViewMode';
    public ViewMode: 'list' | 'graph' = 'list';

    public ngOnInit(): void {
        const saved = UserInfoEngine.Instance.GetSetting(OrganizationRelationshipsPanel.PREF_KEY);
        if (saved === 'list' || saved === 'graph') {
            this.ViewMode = saved;
        }
    }

    public SetViewMode(mode: 'list' | 'graph'): void {
        this.ViewMode = mode;
        UserInfoEngine.Instance.SetSettingDebounced(OrganizationRelationshipsPanel.PREF_KEY, mode);
    }
}
