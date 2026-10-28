import {
    ChangeDetectionStrategy,
    ChangeDetectorRef,
    Component,
    DoCheck,
    EventEmitter,
    Input,
    OnDestroy,
    OnInit,
    Output,
    ViewChild,
    inject,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { BaseEntity, LogError, Metadata, RunQuery, RunView } from '@memberjunction/core';
import { EscapeSQLString } from '@memberjunction/global';
import { BaseFormsModule, type FormContext, type FormNavigationEvent } from '@memberjunction/ng-base-forms';
import { MJComboboxComponent } from '@memberjunction/ng-ui-components';
import { Subject, Subscription, debounceTime, from, switchMap } from 'rxjs';

import { PARTY_LOOKUP_QUERIES, PartyLookupParamsFor, type PartyKind, type PartyLookupParams } from './party-lookup-term';

/** One row of a party lookup query: the contract every app's lookup query honours. */
export interface PartyOption {
    ID: string;
    Name: string;
    Detail: string | null;
}

const DEBOUNCE_MS = 250;
/** How long a search may run before the field says it took too long. */
const DEFAULT_SEARCH_TIMEOUT_MS = 20_000;

/** Why the last search showed no rows: it failed, or it ran past `SearchTimeoutMs`. */
export type PartySearchError = 'failed' | 'timeout';

/** Thrown by `optionsFor` when a search runs past its deadline. */
class PartySearchTimeoutError extends Error {}

/**
 * `bizapps-party-field` — a Person or Organization foreign key that searches as you type.
 *
 * The stock form field lists rows on focus, matches `LIKE '%q%'` on one view column and counts
 * every full page, which takes seconds on a party file of a million people. This one lists nothing
 * until two characters are typed, then runs one parameterized query (prefix match on indexed base
 * columns, TOP 20, no count). People match last name, display name, email or email domain;
 * organizations match name, legal name or website domain.
 *
 * Read mode is the stock `mj-form-field`, so labels, links and navigation stay the platform's.
 * An app whose foreign key points at a subtype (Sales Contacts, Sales Accounts) passes its own
 * `QueryName` with the same result contract (ID, Name, Detail; parameters Term, Domain).
 */
@Component({
    selector: 'bizapps-party-field',
    standalone: true,
    imports: [BaseFormsModule, MJComboboxComponent, FormsModule],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        @if (EditMode) {
            <div class="bizapps-party-field" (focusout)="OnFocusOut()">
                @if (ShowLabel) {
                    <label class="bizapps-party-field-label">{{ Label }}</label>
                }
                <mj-combobox
                    [Data]="Options"
                    TextField="Name"
                    ValueField="ID"
                    [ValuePrimitive]="true"
                    [Filterable]="false"
                    Placeholder="Type 2+ characters to search"
                    [ngModel]="CurrentID"
                    (FilterChange)="OnFilterChange($event)"
                    (ValueChange)="OnSelect($event)"
                >
                    <ng-template #mjComboboxItem let-item>
                        <div class="bizapps-party-option">
                            <span>{{ item.Name }}</span>
                            @if (item.Detail) {
                                <span class="bizapps-party-option-detail">{{ item.Detail }}</span>
                            }
                        </div>
                    </ng-template>
                </mj-combobox>
                @if (SearchError === 'failed') {
                    <div class="bizapps-party-field-hint">Search failed. Try again.</div>
                } @else if (SearchError === 'timeout') {
                    <div class="bizapps-party-field-hint">The search took too long. Keep typing to try again.</div>
                }
            </div>
        } @else {
            <mj-form-field
                [Record]="Record"
                [ShowLabel]="ShowLabel"
                [FieldName]="FieldName"
                Type="textbox"
                LinkType="Record"
                [EditMode]="false"
                [FormContext]="FormContext"
                (Navigate)="Navigate.emit($event)"
            ></mj-form-field>
        }
    `,
    styles: [
        `
            .bizapps-party-field {
                display: flex;
                flex-direction: column;
                gap: var(--mj-space-1);
            }
            .bizapps-party-field-label {
                font-size: var(--mj-text-sm);
                font-weight: var(--mj-font-medium);
                color: var(--mj-text-secondary);
            }
            .bizapps-party-option {
                display: flex;
                flex-direction: column;
                min-width: 0;
            }
            .bizapps-party-option-detail {
                font-size: var(--mj-text-xs);
                color: var(--mj-text-muted);
            }
            .bizapps-party-field-hint {
                font-size: var(--mj-text-xs);
                color: var(--mj-status-error);
            }
        `,
    ],
})
export class PartyFieldComponent implements OnInit, DoCheck, OnDestroy {
    private readonly cdr = inject(ChangeDetectorRef);

    @Input({ required: true }) Record!: BaseEntity;
    @Input({ required: true }) FieldName!: string;
    @Input({ required: true }) Kind!: PartyKind;
    /** Overrides the Kind's default query; pair with CategoryPath. */
    @Input() QueryName?: string;
    @Input() CategoryPath?: string;
    @Input() EditMode = false;
    @Input() ShowLabel = true;
    @Input() FormContext?: FormContext;
    /** Milliseconds before a search is reported as too slow; zero or less waits indefinitely. */
    @Input() SearchTimeoutMs = DEFAULT_SEARCH_TIMEOUT_MS;
    /** The shape mj-form-field emits, so handlers written for it keep working. */
    @Output() ValueChange = new EventEmitter<{ FieldName: string; OldValue: unknown; NewValue: unknown }>();
    @Output() Navigate = new EventEmitter<FormNavigationEvent>();

    /** What the dropdown lists: search results, or just the current value when not searching. */
    public Options: PartyOption[] = [];
    public SearchError: PartySearchError | null = null;

    public get SearchFailed(): boolean {
        return this.SearchError !== null;
    }

    /** The current value as a one-item list (empty when unset): what the list goes back to. */
    private current: PartyOption[] = [];
    private readonly terms = new Subject<string>();
    private subscription?: Subscription;

    @ViewChild(MJComboboxComponent) private combobox?: MJComboboxComponent;

    public ngOnInit(): void {
        this.seedCurrent();
        this.subscription = this.terms
            .pipe(
                debounceTime(DEBOUNCE_MS),
                switchMap((term) => from(this.optionsFor(term))),
            )
            .subscribe((options) => {
                this.SearchError = Array.isArray(options) ? null : options;
                this.Options = Array.isArray(options) ? options : [];
                this.cdr.markForCheck();
            });
    }

    /**
     * Code can change the value after load (Deal's FillContactsFromAccount, a cancelled edit
     * reverting the record). Re-seed when the record no longer holds the value this field shows.
     */
    public ngDoCheck(): void {
        const shown = this.current[0]?.ID ?? null;
        if (this.subscription && this.CurrentID?.toLowerCase() !== shown?.toLowerCase()) {
            this.seedCurrent();
            this.RefreshComboboxText();
        }
    }

    public ngOnDestroy(): void {
        this.subscription?.unsubscribe();
    }

    /** The same label read mode shows: the related name field's ("Person"), not the key's ("Person ID"). */
    public get Label(): string {
        const nameFieldMap = this.fieldInfo()?.RelatedEntityNameFieldMap;
        const nameField = nameFieldMap ? this.Record?.EntityInfo?.Fields.find((field) => field.Name === nameFieldMap) : undefined;
        return nameField?.DisplayNameOrName ?? this.fieldInfo()?.DisplayNameOrName ?? this.FieldName;
    }

    public get CurrentID(): string | null {
        const value = this.Record?.Get(this.FieldName);
        return value ? String(value) : null;
    }

    public OnFilterChange(text: string): void {
        this.terms.next(text);
    }

    /** Picked (an ID) or cleared (null). */
    public OnSelect(value: unknown): void {
        const oldValue = this.Record.Get(this.FieldName);
        const newValue = value ? String(value) : null;
        const picked = this.Options.find((option) => option.ID === newValue);
        this.Record.Set(this.FieldName, newValue);
        this.current = picked ? [picked] : [];
        this.Options = this.current;
        this.ValueChange.emit({ FieldName: this.FieldName, OldValue: oldValue, NewValue: newValue });
        this.cdr.markForCheck();
    }

    /**
     * Leaving the field mid-search puts the current value back in the list, so the combobox can
     * show its name rather than a raw ID, and cancels any search still pending.
     */
    public OnFocusOut(): void {
        this.terms.next('');
        this.Options = this.current;
        this.cdr.markForCheck();
    }

    /** The RunQuery call. Throws on failure; a test seam. */
    protected async runSearch(params: PartyLookupParams): Promise<PartyOption[]> {
        const query = this.QueryName
            ? { QueryName: this.QueryName, CategoryPath: this.CategoryPath }
            : PARTY_LOOKUP_QUERIES[this.Kind];
        const parameters: Record<string, string> = { Term: params.Term };
        if (params.Domain) {
            parameters['Domain'] = params.Domain;
        }
        const result = await new RunQuery().RunQuery({ ...query, Parameters: parameters });
        if (!result.Success) {
            throw new Error(`${query.QueryName} failed: ${result.ErrorMessage ?? 'unknown error'}`);
        }
        return (result.Results as PartyOption[]).map((row) => ({ ID: row.ID, Name: row.Name, Detail: row.Detail ?? null }));
    }

    /**
     * mj-combobox re-reads its text from Data only while the text is empty, so a name that arrives
     * after the ID was shown has to be pushed: Data first, then the value. A test seam.
     */
    protected RefreshComboboxText(): void {
        if (this.combobox) {
            this.combobox.Data = this.Options;
            this.combobox.writeValue(this.CurrentID);
        }
        this.cdr.markForCheck();
    }

    private seedCurrent(): void {
        this.current = this.currentOption();
        this.Options = this.current;
        if (this.needsNameLookup()) {
            void this.resolveCurrentName();
        }
    }

    /** The options to list, or why there are none (logged). */
    private async optionsFor(term: string): Promise<PartyOption[] | PartySearchError> {
        const params = PartyLookupParamsFor(this.Kind, term);
        if (!params) {
            return term ? [] : this.current;
        }
        try {
            return await this.withTimeout(this.runSearch(params));
        } catch (error) {
            LogError(`bizapps-party-field: ${error instanceof Error ? error.message : String(error)}`);
            return error instanceof PartySearchTimeoutError ? 'timeout' : 'failed';
        }
    }

    /**
     * Rejects when the search runs past `SearchTimeoutMs`. The request is not cancelled; its late
     * answer is ignored, and the next keystroke starts a new search.
     */
    private withTimeout<T>(search: Promise<T>): Promise<T> {
        const ms = this.SearchTimeoutMs;
        if (!(ms > 0)) {
            return search;
        }
        let timer: ReturnType<typeof setTimeout> | undefined;
        const deadline = new Promise<never>((_, reject) => {
            timer = setTimeout(() => reject(new PartySearchTimeoutError(`search took longer than ${ms} ms`)), ms);
        });
        return Promise.race([search, deadline]).finally(() => clearTimeout(timer));
    }

    /**
     * The current value as an option, named from the record's related-name view column. That
     * column is empty, or stale, when code set the foreign key after load (Deal's
     * FillContactsFromAccount); the ID stands in until resolveCurrentName replaces it.
     */
    private currentOption(): PartyOption[] {
        const id = this.CurrentID;
        if (!id) {
            return [];
        }
        const name = this.needsNameLookup() ? null : this.recordName();
        return [{ ID: id, Name: name ?? id, Detail: null }];
    }

    private recordName(): string | null {
        const nameField = this.fieldInfo()?.RelatedEntityNameFieldMap;
        const name = nameField ? this.Record.Get(nameField) : null;
        return name ? String(name) : null;
    }

    private needsNameLookup(): boolean {
        if (!this.CurrentID) {
            return false;
        }
        return !this.recordName() || this.Record.GetFieldByName(this.FieldName)?.Dirty === true;
    }

    /** One read of the related record's name field. A failure is logged and the ID stays as the label. */
    private async resolveCurrentName(): Promise<void> {
        const id = this.CurrentID;
        const field = this.fieldInfo();
        const nameField = field ? Metadata.Provider.EntityByName(field.RelatedEntity)?.NameField?.Name : undefined;
        if (!id || !field || !nameField) {
            return;
        }
        const result = await RunView.FromMetadataProvider(Metadata.Provider).RunView<Record<string, unknown>>({
            EntityName: field.RelatedEntity,
            ExtraFilter: `${field.RelatedEntityFieldName}='${EscapeSQLString(id)}'`,
            Fields: [field.RelatedEntityFieldName, nameField],
            ResultType: 'simple',
            MaxRows: 1,
        });
        const name = result.Success ? result.Results[0]?.[nameField] : null;
        if (!result.Success) {
            LogError(`bizapps-party-field: could not read the name of ${field.RelatedEntity} ${id}: ${result.ErrorMessage}`);
        }
        if (name && this.CurrentID === id) {
            this.current = [{ ID: id, Name: String(name), Detail: null }];
            this.Options = this.current;
            this.RefreshComboboxText();
        }
    }

    private fieldInfo() {
        return this.Record?.EntityInfo?.Fields.find((field) => field.Name === this.FieldName);
    }
}
