import {
    ChangeDetectorRef,
    Component,
    EventEmitter,
    Input,
    OnInit,
    Output,
    inject,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { IMetadataProvider, Metadata, RunView } from '@memberjunction/core';
import { EscapeSQLString, UUIDsEqual } from '@memberjunction/global';
import { MJButtonDirective, MJConfirmService } from '@memberjunction/ng-ui-components';
import { SharedGenericModule } from '@memberjunction/ng-shared-generic';
import {
    CompanySenderIdentityEntity,
    NormalizeSenderIdentity,
    SenderIdentityKind,
} from '@mj-biz-apps/common-entities';

const ENTITY_NAME = 'MJ_BizApps_Common: Company Sender Identities';

/** Shown after a successful add. The panel never calls the mail provider (spec §8). */
export const SENDER_VERIFICATION_REMINDER = 'Make sure this sender is verified in your mail provider before using it.';

/**
 * What a write did. `Saved` is the caller's answer; `Changed` says whether the database moved,
 * which is what decides the reload and DataChanged. They differ when a two-step write half-fails.
 */
interface WriteOutcome {
    readonly Saved: boolean;
    readonly Changed: boolean;
}
const SAVED: WriteOutcome = { Saved: true, Changed: true };
const NOT_SAVED: WriteOutcome = { Saved: false, Changed: false };

/**
 * Lists and edits the From addresses a Company may send mail as: Mailbox rows (one address) and
 * Domain rows (any address at that domain). One Mailbox may be the company's default sender.
 *
 * Every user-facing error names the address it is about, and every failure lands in `Error`
 * (rendered in the template), never only in the console.
 */
@Component({
    selector: 'bizapps-company-sender-identities',
    standalone: true,
    imports: [FormsModule, MJButtonDirective, SharedGenericModule],
    templateUrl: './company-sender-identities.component.html',
    styleUrls: ['./company-sender-identities.component.css'],
})
export class CompanySenderIdentitiesComponent implements OnInit {
    private readonly cdr = inject(ChangeDetectorRef);
    private readonly confirm = inject(MJConfirmService);
    private _companyID: string | null = null;
    private initialized = false;

    /**
     * The host form reuses this component when it moves to another Company, so a new value resets
     * the previous company's rows, messages and add-form draft and reloads.
     */
    @Input()
    public set CompanyID(value: string | null) {
        if (sameCompany(value, this._companyID)) return;
        this._companyID = value;
        if (!this.initialized) return;
        this.resetForCompany();
        void this.loadAll();
    }
    public get CompanyID(): string | null {
        return this._companyID;
    }

    @Input() EditMode = true;
    @Input() Provider?: IMetadataProvider;

    @Output() DataChanged = new EventEmitter<void>();

    public Rows: CompanySenderIdentityEntity[] = [];
    public Loading = false;
    public Saving = false;
    public Error: string | null = null;
    /** One-line confirmation after an add (the verification reminder). */
    public Notice: string | null = null;

    public ShowAddForm = false;
    public NewKind: SenderIdentityKind = 'Mailbox';
    public NewAddress = '';
    public NewDisplayName = '';

    /** The provider actually used: the one passed in, or the ambient one. */
    public get ProviderToUse(): IMetadataProvider {
        return this.Provider ?? Metadata.Provider;
    }

    public async ngOnInit(): Promise<void> {
        this.initialized = true;
        await this.loadAll();
    }

    /** Set default is offered only on a Mailbox row that is not already the default. */
    public canSetDefault(row: CompanySenderIdentityEntity): boolean {
        return row.Kind === 'Mailbox' && !row.IsDefault;
    }

    /**
     * Reload the company's rows (one RunView). A load that finishes after the input moved to
     * another company is dropped, so a slow answer for the old company never overwrites the new one.
     */
    public async loadAll(): Promise<void> {
        const companyId = this.CompanyID;
        this.Loading = true;
        this.Error = null;
        this.cdr.detectChanges();
        try {
            const rows = await this.queryRows(companyId);
            if (sameCompany(companyId, this.CompanyID)) this.Rows = rows;
        } catch (err) {
            if (!sameCompany(companyId, this.CompanyID)) return;
            this.Error = `Could not load email senders for company ${companyId}: ${err instanceof Error ? err.message : String(err)}`;
            console.error('[CompanySenderIdentities]', this.Error, err);
        } finally {
            if (sameCompany(companyId, this.CompanyID)) {
                this.Loading = false;
                this.cdr.detectChanges();
            }
        }
    }

    /** Add a Mailbox or Domain row. Refuses a malformed address before anything is saved. */
    public async addRow(kind: SenderIdentityKind, address: string, displayName: string | null): Promise<boolean> {
        const normalized = NormalizeSenderIdentity(kind, address, displayName);
        // The unique index on (CompanyID, Address) is the real guard; this check only spares the
        // operator the server's raw SQL error text for the common case of re-adding a listed address.
        const problems = this.Rows.some((r) => r.Address === normalized.address)
            ? [...normalized.errors, `"${normalized.address}" is already in this company's senders`]
            : normalized.errors;
        if (problems.length > 0) {
            this.Error = problems.join('; ');
            this.Notice = null;
            this.cdr.detectChanges();
            return false;
        }
        return this.runMutation(`adding "${normalized.address}"`, async () => {
            const p = this.ProviderToUse;
            const entity = await p.GetEntityObject<CompanySenderIdentityEntity>(ENTITY_NAME, p.CurrentUser);
            entity.CompanyID = this.requireCompanyID();
            entity.Kind = kind;
            entity.Address = normalized.address;
            entity.DisplayName = normalized.displayName;
            entity.IsDefault = false;
            if (!(await entity.Save())) {
                this.Error = failureText(`Could not add "${normalized.address}"`, entity);
                return NOT_SAVED;
            }
            this.resetAddForm();
            this.Notice = SENDER_VERIFICATION_REMINDER;
            return SAVED;
        });
    }

    /**
     * Make `row` the company's default Mailbox. The current default is demoted first and saved,
     * then `row` is promoted: the database allows one default per company, so the order matters.
     */
    public async setDefault(row: CompanySenderIdentityEntity): Promise<boolean> {
        if (!this.canSetDefault(row)) {
            return false;
        }
        return this.runMutation(`making "${row.Address}" the default`, async () => {
            const current = this.Rows.find((r) => r.IsDefault && !UUIDsEqual(r.ID, row.ID));
            if (current && !(await this.saveIsDefault(current, false))) {
                this.Error = failureText(`Could not remove the default from "${current.Address}"`, current);
                return NOT_SAVED;
            }
            if (!(await this.saveIsDefault(row, true))) {
                const lost = current ? `; "${current.Address}" is no longer the default` : '';
                this.Error = failureText(`Could not make "${row.Address}" the default`, row) + lost;
                // The demote already committed, so the list is re-read and the host told.
                return { Saved: false, Changed: current !== undefined };
            }
            return SAVED;
        });
    }

    /** Delete `row` after the user confirms. */
    public async removeRow(row: CompanySenderIdentityEntity): Promise<boolean> {
        const confirmed = await this.confirm.ConfirmDelete({
            title: 'Remove sender',
            message: `Remove "${row.Address}" from this company's email senders?`,
            confirmText: 'Remove',
        });
        if (!confirmed) {
            return false;
        }
        return this.runMutation(`removing "${row.Address}"`, async () => {
            const address = row.Address;
            if (!(await row.Delete())) {
                this.Error = failureText(`Could not remove "${address}"`, row);
                return NOT_SAVED;
            }
            // Drop it now: BaseEntity resets a deleted object's fields, and a row still in the list
            // until the reload lands would re-render with changed values (NG0100 in dev mode).
            this.Rows = this.Rows.filter((r) => !UUIDsEqual(r.ID, row.ID));
            return SAVED;
        });
    }

    /** Template handler for the add form's Add button. */
    public async onAdd(): Promise<void> {
        const displayName = this.NewKind === 'Mailbox' ? this.NewDisplayName : null;
        await this.addRow(this.NewKind, this.NewAddress, displayName);
    }

    public openAddForm(kind: SenderIdentityKind): void {
        this.resetAddForm();
        this.NewKind = kind;
        this.ShowAddForm = true;
        this.Notice = null;
        this.cdr.detectChanges();
    }

    /** Close the add form. Its validation error goes with it, so a stale message never lingers. */
    public cancelAdd(): void {
        this.resetAddForm();
        this.Error = null;
        this.cdr.detectChanges();
    }

    /**
     * Shared wrapper for every write: one write at a time, a fresh error/notice, and a reload plus
     * DataChanged whenever the database changed (even when the write as a whole did not succeed).
     * `work` sets `Error` itself on an expected failure; an unexpected throw is reported with
     * `context` (which names the address).
     */
    private async runMutation(context: string, work: () => Promise<WriteOutcome>): Promise<boolean> {
        if (this.Saving) {
            return false;
        }
        this.Saving = true;
        this.Error = null;
        this.Notice = null;
        this.cdr.detectChanges();
        try {
            const outcome = await work();
            if (outcome.Changed) {
                await this.reloadAfterWrite(context);
                this.DataChanged.emit();
            }
            return outcome.Saved;
        } catch (err) {
            this.Error = `Failed while ${context}: ${err instanceof Error ? err.message : String(err)}`;
            console.error('[CompanySenderIdentities]', this.Error, err);
            return false;
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }

    /** The write already succeeded, so a failed reload is reported as such rather than as a failed write. */
    private async reloadAfterWrite(context: string): Promise<void> {
        const companyId = this.CompanyID;
        try {
            const rows = await this.queryRows(companyId);
            if (sameCompany(companyId, this.CompanyID)) this.Rows = rows;
        } catch (err) {
            this.Error = `Saved while ${context}, but the list could not be reloaded: ${err instanceof Error ? err.message : String(err)}`;
            console.error('[CompanySenderIdentities]', this.Error, err);
        }
    }

    /** The company's rows. Throws (with context) when the RunView fails, so callers report it. */
    private async queryRows(companyId: string | null): Promise<CompanySenderIdentityEntity[]> {
        if (!companyId) return [];
        const p = this.ProviderToUse;
        const result = await RunView.FromMetadataProvider(p).RunView<CompanySenderIdentityEntity>(
            {
                EntityName: ENTITY_NAME,
                ExtraFilter: `CompanyID = '${EscapeSQLString(companyId)}'`,
                OrderBy: 'Address ASC',
                ResultType: 'entity_object',
                // BypassCache also keeps this read out of the client's RunView coalescer, which
                // merges concurrent RunViews from every component on the page into one batch and
                // rejects ALL callers if any one query fails. On MJ 6.1.x the Company form's own
                // overview panel queries the unprefixed 'Employees' entity (fixed in 6.2.0-edge.3),
                // so a coalesced load here always failed with "Entity Employees not found".
                // The list is a handful of rows, so skipping the cache costs nothing.
                BypassCache: true,
            },
            p.CurrentUser,
        );
        if (!result.Success) {
            throw new Error(result.ErrorMessage || 'RunView returned no error message');
        }
        return result.Results ?? [];
    }

    /** Sets IsDefault and saves; on failure restores the local value so the list matches the database. */
    private async saveIsDefault(row: CompanySenderIdentityEntity, value: boolean): Promise<boolean> {
        row.IsDefault = value;
        const saved = await row.Save();
        if (!saved) {
            row.IsDefault = !value;
        }
        return saved;
    }

    private requireCompanyID(): string {
        if (!this.CompanyID) {
            throw new Error('no CompanyID is set on the widget');
        }
        return this.CompanyID;
    }

    /** Forget everything that belonged to the previous company. */
    private resetForCompany(): void {
        this.Rows = [];
        this.Error = null;
        this.Notice = null;
        this.resetAddForm();
    }

    private resetAddForm(): void {
        this.ShowAddForm = false;
        this.NewKind = 'Mailbox';
        this.NewAddress = '';
        this.NewDisplayName = '';
    }
}

/** `prefix` names the address; the entity's own message is appended when it has one. */
function failureText(prefix: string, entity: CompanySenderIdentityEntity): string {
    const detail = entity.LatestResult?.CompleteMessage || entity.LatestResult?.Message;
    return detail ? `${prefix}: ${detail}` : prefix;
}

/** Company IDs compare with UUIDsEqual (SQL Server and PostgreSQL differ in case); null only equals null. */
function sameCompany(a: string | null, b: string | null): boolean {
    return a !== null && b !== null ? UUIDsEqual(a, b) : a === b;
}
