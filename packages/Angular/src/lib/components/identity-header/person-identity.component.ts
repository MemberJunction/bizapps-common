import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CompositeKey } from '@memberjunction/core';
import { BaseFormsModule, FormContext, FormNavigationEvent } from '@memberjunction/ng-base-forms';
import { LinkDirectivesModule } from '@memberjunction/ng-link-directives';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';

/**
 * Presentational Person identity strip. Used by Common's header contribution
 * and composed by verticals (Orders) that last-win the same `header` key.
 */
@Component({
    standalone: true,
    selector: 'bizapps-person-identity',
    imports: [CommonModule, BaseFormsModule, LinkDirectivesModule],
    templateUrl: './person-identity.component.html',
    styleUrls: ['./identity-header.css'],
})
export class PersonIdentityComponent {
    @Input({ required: true }) Record!: mjBizAppsCommonPersonEntity;
    @Input() EditMode = false;
    @Input() FormContext?: FormContext;
    @Output() Navigate = new EventEmitter<FormNavigationEvent>();

    public get DisplayTitle(): string {
        return this.Record.CurrentJobTitle || this.Record.Title || '';
    }

    public get Initials(): string {
        const first = (this.Record.FirstName || '').trim();
        const last = (this.Record.LastName || '').trim();
        if (first && last) {
            return (first.charAt(0) + last.charAt(0)).toUpperCase();
        }
        const name = (this.Record.DisplayName || `${first} ${last}`).trim();
        const parts = name.split(/\s+/).filter(Boolean);
        if (parts.length === 0) {
            return '?';
        }
        if (parts.length === 1) {
            return parts[0].slice(0, 2).toUpperCase();
        }
        return (parts[0].charAt(0) + parts[parts.length - 1].charAt(0)).toUpperCase();
    }

    public get StatusTone(): 'success' | 'warning' | 'muted' {
        switch (this.Record.Status) {
            case 'Active':
                return 'success';
            case 'Deceased':
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

    public get PreferredDiffers(): boolean {
        const preferred = (this.Record.PreferredName || '').trim();
        if (!preferred) {
            return false;
        }
        return preferred.toLowerCase() !== (this.Record.FirstName || '').trim().toLowerCase();
    }

    public OnOrgClick(event: MouseEvent): void {
        const id = this.Record.CurrentOrganizationID;
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

    public OnPhotoError(event: Event): void {
        const img = event.target;
        if (img instanceof HTMLImageElement) {
            img.style.display = 'none';
        }
    }
}
