import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, ViewEncapsulation, inject } from '@angular/core';
import { BaseEntity, Metadata, RunView } from '@memberjunction/core';
import { BaseFormsModule, type FormContext, type FormNavigationEvent } from '@memberjunction/ng-base-forms';

import { CommonSettings } from '../../data/common-settings';
import { SellingCompanyConfirm } from './selling-company-confirm';

const COMPANIES_ENTITY = 'MJ: Companies';
const EMPLOYEES_ENTITY = 'MJ: Employees';

/**
 * `bizapps-selling-company-field` — the company foreign key on an order or a contract, with a
 * default and a confirmation.
 *
 * This field decides which legal entity books the revenue, and the picker behind it lists every
 * company row the instance has. Two failure modes follow from that, and this component exists for
 * both.
 *
 * **A default nobody chose is worse than no default.** Apps have defaulted this field by whichever
 * company sorted first alphabetically, or by the first product on the order — rules nobody wrote
 * down and nobody can see. The default here is the current user's own company when they have one
 * and it is a company this instance sells from, otherwise the value the instance configured in the
 * Common `DefaultSellingCompanyID` setting, otherwise nothing. An instance that configures nothing
 * gets a blank field, which is the pre-existing behaviour rather than a guess.
 *
 * **Departing from the default must be deliberate.** Companies can differ by a single word, and an
 * order booked to the wrong entity looks perfectly correct afterwards — nothing on screen says
 * otherwise. So anything other than the default is held, named back to the user against the
 * default, and written only when they confirm. The value is restored if they move on without
 * answering: an unanswered question must not decide where revenue lands.
 *
 * It wraps `mj-form-field` rather than replacing it, so the dropdown, keyboard behaviour and
 * link rendering stay the platform's. It owns only the default and the confirmation, which is why
 * it does not wait on the platform lookup-strategy seam.
 */
@Component({
    selector: 'bizapps-selling-company-field',
    standalone: true,
    imports: [BaseFormsModule],
    encapsulation: ViewEncapsulation.None,
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <mj-form-field
            [Record]="Record"
            [ShowLabel]="ShowLabel"
            [FieldName]="FieldName"
            Type="textbox"
            LinkType="Record"
            [EditMode]="EditMode"
            [FormContext]="FormContext"
            (ValueChange)="OnValueChange($event.NewValue)"
            (Navigate)="Navigate.emit($event)"
        ></mj-form-field>
        @if (AskName) {
            <div class="bizapps-selling-confirm" role="alertdialog" aria-live="polite">
                <span>
                    Book to <strong>{{ AskName }}</strong>
                    @if (DefaultName) {
                        rather than {{ DefaultName }}
                    }
                    ?
                </span>
                <button type="button" class="bizapps-selling-confirm-yes" (click)="OnConfirm()">Confirm</button>
                <button type="button" class="bizapps-selling-confirm-no" (click)="OnRevert()">Revert</button>
            </div>
        }
    `,
    styles: [
        `
            .bizapps-selling-confirm {
                display: flex;
                flex-wrap: wrap;
                gap: var(--mj-space-2);
                align-items: center;
                margin-top: var(--mj-space-1);
                padding: var(--mj-space-2) var(--mj-space-3);
                border: 1px solid var(--mj-status-warning);
                border-radius: var(--mj-radius-md);
                background: var(--mj-bg-surface-sunken);
                font-size: var(--mj-text-sm);
            }
        `,
    ],
})
export class SellingCompanyFieldComponent implements OnInit {
    private readonly cdr = inject(ChangeDetectorRef);

    @Input({ required: true }) Record!: BaseEntity;
    @Input() FieldName = 'CompanyID';
    @Input() EditMode = false;
    @Input() ShowLabel = true;
    @Input() FormContext?: FormContext;
    @Output() Navigate = new EventEmitter<FormNavigationEvent>();

    /** The company being asked about, by name, or null when nothing is pending. */
    public AskName: string | null = null;
    /** The resolved default's name, for the question. Empty when the instance configured none. */
    public DefaultName = '';

    private confirm = new SellingCompanyConfirm(null);
    private previous: string | null = null;
    private readonly names = new Map<string, string>();

    public async ngOnInit(): Promise<void> {
        const metadata = new Metadata();
        await CommonSettings.Load(Metadata.Provider, metadata.CurrentUser);
        await this.loadCompanyNames();

        const defaultID = (await this.employeeCompanyID(metadata)) ?? CommonSettings.DefaultSellingCompanyID;
        this.confirm = new SellingCompanyConfirm(defaultID);
        this.DefaultName = defaultID ? this.nameOf(defaultID) : '';
        this.applyDefault(defaultID);
        this.previous = this.current();
        this.cdr.markForCheck();
    }

    public OnValueChange(newValue: unknown): void {
        const proposed = newValue ? String(newValue) : null;
        const outcome = this.confirm.Propose(proposed);
        if (outcome.Ask) {
            // mj-form-field writes the record before it emits, so put the old value back while the
            // question is open. Nothing is booked to a company the user has not agreed to.
            this.Record.Set(this.FieldName, this.previous);
            this.AskName = this.nameOf(outcome.Ask);
        } else {
            this.AskName = null;
            this.previous = outcome.Write;
        }
        this.cdr.markForCheck();
    }

    public OnConfirm(): void {
        const confirmed = this.confirm.Confirm();
        this.Record.Set(this.FieldName, confirmed);
        this.previous = confirmed;
        this.AskName = null;
        this.cdr.markForCheck();
    }

    public OnRevert(): void {
        this.Record.Set(this.FieldName, this.confirm.Revert(this.previous));
        this.AskName = null;
        this.cdr.markForCheck();
    }

    /** Only on a new record with the field still empty; never overwrite what is already booked. */
    private applyDefault(defaultID: string | null): void {
        if (defaultID && !this.Record.IsSaved && !this.Record.Get(this.FieldName)) {
            this.Record.Set(this.FieldName, defaultID);
        }
    }

    private current(): string | null {
        const value = this.Record.Get(this.FieldName);
        return value ? String(value) : null;
    }

    private nameOf(id: string): string {
        return this.names.get(id.trim().toLowerCase()) ?? id;
    }

    private async loadCompanyNames(): Promise<void> {
        const result = await RunView.FromMetadataProvider(Metadata.Provider).RunView<{ ID: string; Name: string }>({
            EntityName: COMPANIES_ENTITY,
            Fields: ['ID', 'Name'],
            ResultType: 'simple',
            OrderBy: 'Name',
        });
        if (!result.Success) {
            return; // The question falls back to naming companies by ID rather than not appearing.
        }
        for (const company of result.Results) {
            this.names.set(company.ID.trim().toLowerCase(), company.Name);
        }
    }

    /**
     * The user's own company, when they are linked to an employee record and that employee's
     * company is one this instance knows. An employee of a company that is not in the list is not
     * a signal about where to book.
     */
    private async employeeCompanyID(metadata: Metadata): Promise<string | null> {
        const employeeID = metadata.CurrentUser?.EmployeeID;
        if (!employeeID) {
            return null;
        }
        const result = await RunView.FromMetadataProvider(Metadata.Provider).RunView<{ CompanyID: string }>({
            EntityName: EMPLOYEES_ENTITY,
            ExtraFilter: `ID = '${String(employeeID).replace(/'/g, "''")}'`,
            Fields: ['CompanyID'],
            ResultType: 'simple',
            MaxRows: 1,
        });
        const companyID = result.Success ? result.Results[0]?.CompanyID : null;
        return companyID && this.names.has(companyID.trim().toLowerCase()) ? companyID : null;
    }
}
