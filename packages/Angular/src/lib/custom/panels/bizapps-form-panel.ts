import { ChangeDetectorRef, Directive, inject } from '@angular/core';
import { BaseEntity } from '@memberjunction/core';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';

/**
 * Shared helpers for BizApps widget panels that sit on generated forms.
 * Reloads the host record after related-widget mutations so virtual fields
 * (PrimaryAddress*, PrimaryEmail, CurrentOrganization*, etc.) stay current.
 */
@Directive()
export abstract class BizAppsFormPanel<TRecord extends BaseEntity = BaseEntity> extends BaseFormPanel<TRecord> {
    private readonly cdr = inject(ChangeDetectorRef);

    /**
     * Reload the host record after a widget mutation, but only when the form
     * has no pending edits of its own.
     */
    public async OnWidgetDataChanged(): Promise<void> {
        if (this.Record.Dirty) {
            return;
        }
        await this.Record.InnerLoad(this.Record.PrimaryKey);
        this.FormComponent.cdr.detectChanges();
        this.cdr.detectChanges();
    }
}
