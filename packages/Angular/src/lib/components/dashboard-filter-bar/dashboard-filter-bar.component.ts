import { ChangeDetectionStrategy, Component, EventEmitter, Input, Output } from '@angular/core';
import { MJFilterPopoverComponent } from '@memberjunction/ng-ui-components';
import { CleanIDs, HasID, SameIDs, SelectionLabel, SortedOptions, ToggleID, type FilterOption } from './dashboard-id-lists';
import {
    BusinessToday,
    DescribeFiscalBasis,
    FormatWindow,
    PENDING_FISCAL_BASIS,
    PERIOD_OPTIONS,
    PeriodKeyOf,
    type FiscalYearStartResolution,
    type PeriodWindow,
} from './dashboard-period';
import {
    DEFAULT_PERIOD_STATE,
    NormalizePeriodState,
    PeriodWindowOf,
    SamePeriodState,
    type DashboardPeriodState,
} from './dashboard-period-state';

/**
 * `bizapps-dashboard-filter-bar` — the period and company filters a BizApps dashboard opens with.
 *
 * A period dropdown (this/last/next quarter, this/last year, all time, a custom range picked with
 * native date inputs) whose tooltip names the fiscal year basis and the dates in force, and a
 * multi-select company picker. Empty company selection is "All".
 *
 * The bar holds no data and runs no query. The app supplies the company options, the selection, the
 * period and the fiscal basis, and applies what the bar emits to its own reads, so the same bar works
 * whatever an app's companies and fiscal year come from. Both values support two-way binding:
 * `[(SelectedCompanyIDs)]` and `[(PeriodState)]`.
 *
 * App-specific filters (owner, pipeline, …) are projected between the tags and render after the
 * company picker.
 *
 * ```html
 * <bizapps-dashboard-filter-bar
 *   [CompanyOptions]="Companies"
 *   [(SelectedCompanyIDs)]="CompanyIDs"
 *   [(PeriodState)]="Period"
 *   [FiscalBasis]="Fiscal"
 *   (SelectedCompanyIDsChange)="Reload()"
 *   (PeriodStateChange)="Reload()">
 *   <my-owner-filter></my-owner-filter>
 * </bizapps-dashboard-filter-bar>
 * ```
 */
@Component({
    selector: 'bizapps-dashboard-filter-bar',
    standalone: true,
    imports: [MJFilterPopoverComponent],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <div class="bizapps-filterbar" role="group" aria-label="Dashboard filters">
            <label class="bizapps-filterbar__period" [title]="PeriodTooltip">
                <span class="bizapps-filterbar__label">Period</span>
                <select
                    #periodSelect
                    class="bizapps-filterbar__select"
                    data-testid="dashboard-period"
                    aria-label="Reporting period"
                    (change)="SetPeriod(periodSelect.value)">
                    @for (option of PeriodOptions; track option.Key) {
                        <option [value]="option.Key" [selected]="option.Key === PeriodState.Period">{{ option.Label }}</option>
                    }
                </select>
            </label>
            <span class="bizapps-filterbar__window" data-testid="dashboard-period-window">{{ WindowLabel }}</span>
            @if (PeriodState.Period === 'custom') {
                <span class="bizapps-filterbar__range">
                    <input
                        #rangeFrom
                        type="date"
                        class="bizapps-filterbar__date"
                        aria-label="From"
                        data-testid="dashboard-period-from"
                        [value]="PeriodState.CustomStart ?? ''"
                        (change)="SetCustomRange(rangeFrom.value, rangeTo.value)" />
                    <span class="bizapps-filterbar__muted">to</span>
                    <input
                        #rangeTo
                        type="date"
                        class="bizapps-filterbar__date"
                        aria-label="To"
                        data-testid="dashboard-period-to"
                        [value]="PeriodState.CustomEnd ?? ''"
                        (change)="SetCustomRange(rangeFrom.value, rangeTo.value)" />
                </span>
            }
            @if (ShowCompanies) {
                <mj-filter-popover
                    data-testid="dashboard-filter-company"
                    [Label]="CompanyButtonLabel"
                    [ActiveCount]="SelectedCompanyIDs.length"
                    [ShowClearAll]="SelectedCompanyIDs.length !== 0"
                    (ClearAllRequested)="ClearCompanies()">
                    <div class="bizapps-filterlist" role="group" [attr.aria-label]="CompanyLabel">
                        @if (!Options.length) {
                            <span class="bizapps-filterbar__muted">Nothing to choose from yet.</span>
                        }
                        @for (option of Options; track option.ID) {
                            <label class="bizapps-filterlist__item">
                                <input type="checkbox" [checked]="IsCompanySelected(option.ID)" (change)="ToggleCompany(option.ID)" />
                                <span>{{ option.Name }}</span>
                            </label>
                        }
                    </div>
                </mj-filter-popover>
            }
            <ng-content />
        </div>
    `,
    styles: [
        `
            .bizapps-filterbar {
                display: flex;
                flex-wrap: wrap;
                align-items: center;
                gap: var(--mj-space-2);
            }
            .bizapps-filterbar__period {
                display: inline-flex;
                align-items: center;
                gap: var(--mj-space-2);
            }
            .bizapps-filterbar__label {
                font-size: var(--mj-text-sm);
                color: var(--mj-text-secondary);
            }
            .bizapps-filterbar__select,
            .bizapps-filterbar__date {
                padding: var(--mj-space-1) var(--mj-space-2);
                border: 1px solid var(--mj-border-default);
                border-radius: var(--mj-radius-md);
                background: var(--mj-bg-surface);
                color: var(--mj-text-primary);
                font: inherit;
                font-size: var(--mj-text-sm);
            }
            .bizapps-filterbar__window,
            .bizapps-filterbar__muted {
                font-size: var(--mj-text-xs);
                color: var(--mj-text-muted);
            }
            .bizapps-filterbar__range {
                display: inline-flex;
                align-items: center;
                gap: var(--mj-space-1);
            }
            .bizapps-filterlist {
                display: flex;
                flex-direction: column;
                gap: var(--mj-space-1);
                max-height: 18rem;
                min-width: 14rem;
                overflow-y: auto;
            }
            .bizapps-filterlist__item {
                display: flex;
                align-items: center;
                gap: var(--mj-space-2);
                font-size: var(--mj-text-sm);
                cursor: pointer;
            }
        `,
    ],
})
export class DashboardFilterBarComponent {
    public readonly PeriodOptions = PERIOD_OPTIONS;

    private _companyOptions: FilterOption[] = [];
    private _selectedCompanyIDs: string[] = [];
    private _periodState: DashboardPeriodState = DEFAULT_PERIOD_STATE;

    /** The companies the picker offers. De-duplicated and sorted by name for display. */
    @Input()
    public set CompanyOptions(value: readonly FilterOption[] | null | undefined) {
        this._companyOptions = SortedOptions(value ?? []);
    }
    public get CompanyOptions(): FilterOption[] {
        return this._companyOptions;
    }

    /** The selected company IDs. Empty is every company. */
    @Input()
    public set SelectedCompanyIDs(value: readonly string[] | null | undefined) {
        this._selectedCompanyIDs = CleanIDs(value ?? []);
    }
    public get SelectedCompanyIDs(): string[] {
        return this._selectedCompanyIDs;
    }

    /** The selected period. Invalid fields fall back to their defaults. */
    @Input()
    public set PeriodState(value: DashboardPeriodState | null | undefined) {
        this._periodState = NormalizePeriodState(value);
    }
    public get PeriodState(): DashboardPeriodState {
        return this._periodState;
    }

    /** The fiscal year start in force and how it was arrived at. The app resolves it; the bar shows it. */
    @Input() FiscalBasis: FiscalYearStartResolution = PENDING_FISCAL_BASIS;

    /** The company picker's name, e.g. "Company" or "Selling company". */
    @Input() CompanyLabel = 'Company';

    /** False hides the company picker, for a dashboard whose figures are not per company. */
    @Input() ShowCompanies = true;

    /** The day the relative periods are counted from, `YYYY-MM-DD`. Null is the business day. */
    @Input() Today: string | null = null;

    /** The company selection changed. Emits the whole new list; empty is every company. */
    @Output() SelectedCompanyIDsChange = new EventEmitter<string[]>();

    /** The period or a custom-range date changed. */
    @Output() PeriodStateChange = new EventEmitter<DashboardPeriodState>();

    /** The options in display order. */
    public get Options(): FilterOption[] {
        return this._companyOptions;
    }

    /** The bounds the selected period resolves to. */
    public get Window(): PeriodWindow {
        return PeriodWindowOf(this._periodState, this.FiscalBasis.Start, this.Today ?? BusinessToday());
    }

    /** "Jul 1, 2026 – Sep 30, 2026": the bounds spelled out beside the dropdown. */
    public get WindowLabel(): string {
        return FormatWindow(this.Window);
    }

    /** The Period dropdown's tooltip: the fiscal basis, then the dates in force. */
    public get PeriodTooltip(): string {
        const basis = DescribeFiscalBasis(this.FiscalBasis);
        return `${basis.charAt(0).toUpperCase()}${basis.slice(1)}. ${this.WindowLabel}.`;
    }

    /** "Company: Acme +1", or "Company: All". */
    public get CompanyButtonLabel(): string {
        return `${this.CompanyLabel}: ${SelectionLabel(this._selectedCompanyIDs, this._companyOptions)}`;
    }

    public IsCompanySelected(id: string): boolean {
        return HasID(this._selectedCompanyIDs, id);
    }

    /** A company checkbox changed. */
    public ToggleCompany(id: string): void {
        this.setCompanies(ToggleID(this._selectedCompanyIDs, id));
    }

    /** The picker's Clear all: back to every company. */
    public ClearCompanies(): void {
        this.setCompanies([]);
    }

    /** The Period dropdown changed. An unknown key is ignored. */
    public SetPeriod(key: string): void {
        const period = PeriodKeyOf(key);
        if (!period) {
            return;
        }
        this.setPeriod({ ...this._periodState, Period: period });
    }

    /** A custom-range date input changed. An empty input is no bound on that side. */
    public SetCustomRange(start: string, end: string): void {
        this.setPeriod({ Period: 'custom', CustomStart: start || null, CustomEnd: end || null });
    }

    private setCompanies(ids: string[]): void {
        if (SameIDs(ids, this._selectedCompanyIDs)) {
            return;
        }
        this._selectedCompanyIDs = CleanIDs(ids);
        this.SelectedCompanyIDsChange.emit([...this._selectedCompanyIDs]);
    }

    private setPeriod(next: DashboardPeriodState): void {
        const state = NormalizePeriodState(next);
        if (SamePeriodState(state, this._periodState)) {
            return;
        }
        this._periodState = state;
        this.PeriodStateChange.emit(state);
    }
}
