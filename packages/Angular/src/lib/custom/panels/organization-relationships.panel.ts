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
        background: var(--mj-bg-surface-sunken, #0b1220);
        border: 1px solid var(--mj-border-default, #223254);
        border-radius: 8px;
        box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.25);
    }

    .bizapps-view-segment-btn {
        display: inline-flex;
        align-items: center;
        gap: 7px;
        padding: 5px 14px;
        border: none;
        border-radius: 6px;
        background: transparent;
        color: var(--mj-text-secondary, #94a3b8);
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
        color: var(--mj-text-primary, #f1f5f9);
        background: rgba(255, 255, 255, 0.05);
    }

    .bizapps-view-segment-btn.active {
        background: var(--mj-brand-primary, #0284c7);
        color: #ffffff;
        font-weight: 600;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.35), 0 0 8px rgba(2, 132, 199, 0.3);
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
