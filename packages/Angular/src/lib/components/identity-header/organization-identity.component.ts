import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CompositeKey } from '@memberjunction/core';
import { BaseFormsModule, FormContext, FormNavigationEvent } from '@memberjunction/ng-base-forms';
import { LinkDirectivesModule } from '@memberjunction/ng-link-directives';
import { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';

/**
 * Presentational Organization identity strip. Used by Common's header
 * contribution and composed by verticals that last-win the `header` key.
 */
@Component({
    standalone: true,
    selector: 'bizapps-organization-identity',
    imports: [CommonModule, BaseFormsModule, LinkDirectivesModule],
    templateUrl: './organization-identity.component.html',
    styleUrls: ['./identity-header.css'],
})
export class OrganizationIdentityComponent {
    @Input({ required: true }) Record!: mjBizAppsCommonOrganizationEntity;
    @Input() EditMode = false;
    @Input() FormContext?: FormContext;
    @Output() Navigate = new EventEmitter<FormNavigationEvent>();

    public get Initials(): string {
        const name = (this.Record.Name || '').trim();
        const parts = name.split(/\s+/).filter(Boolean);
        if (parts.length === 0) {
            return '?';
        }
        if (parts.length === 1) {
            return parts[0].slice(0, 2).toUpperCase();
        }
        return (parts[0].charAt(0) + parts[1].charAt(0)).toUpperCase();
    }

    public get StatusTone(): 'success' | 'warning' | 'muted' {
        switch (this.Record.Status) {
            case 'Active':
                return 'success';
            case 'Dissolved':
                return 'warning';
            default:
                return 'muted';
        }
    }

    public get LocationLine(): string {
        const bits = [
            this.Record.PrimaryAddressCity,
            this.Record.PrimaryAddressState,
            this.Record.PrimaryAddressCountry,
        ].filter((v): v is string => !!v && v.trim().length > 0);
        return bits.join(', ');
    }

    public get LegalDiffers(): boolean {
        const legal = (this.Record.LegalName || '').trim();
        if (!legal) {
            return false;
        }
        return legal.toLowerCase() !== (this.Record.Name || '').trim().toLowerCase();
    }

    public OnParentClick(event: MouseEvent): void {
        const id = this.Record.ParentID;
        if (!id) {
            return;
        }
        event.preventDefault();
        this.Navigate.emit({
            Kind: 'record',
            EntityName: 'MJ_BizApps_Common: Organizations',
            PrimaryKey: CompositeKey.FromKeyValuePair('ID', id),
            OpenInNewTab: event.ctrlKey || event.metaKey,
        });
    }

    public OnLogoError(event: Event): void {
        const img = event.target;
        if (img instanceof HTMLImageElement) {
            img.style.display = 'none';
        }
    }
}
