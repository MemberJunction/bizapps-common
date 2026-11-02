import {
    ChangeDetectorRef,
    Component,
    EventEmitter,
    Input,
    OnChanges,
    OnInit,
    Output,
    SimpleChanges,
    inject,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { IMetadataProvider, Metadata, RunView } from '@memberjunction/core';
import { UUIDsEqual } from '@memberjunction/global';
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
export class CompanySenderIdentitiesComponent implements OnInit, OnChanges {
    private readonly cdr = inject(ChangeDetectorRef);
    private readonly confirm = inject(MJConfirmService);

    @Input() CompanyID: string | null = null;
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
        await this.loadAll();
    }

    public async ngOnChanges(changes: SimpleChanges): Promise<void> {
        if (changes['CompanyID'] && !changes['CompanyID'].firstChange) {
            await this.loadAll();
        }
    }

    /** Set default is offered only on a Mailbox row that is not already the default. */
    public canSetDefault(row: CompanySenderIdentityEntity): boolean {
        return row.Kind === 'Mailbox' && !row.IsDefault;
    }

    /** Reload the company's rows (one RunView). */
    public async loadAll(): Promise<void> {
        this.Loading = true;
        this.Error = null;
        this.cdr.detectChanges();
        try {
            await this.fetchRows();
        } catch (err) {
            this.Error = `Could not load email senders for company ${this.CompanyID}: ${err instanceof Error ? err.message : String(err)}`;
            console.error('[CompanySenderIdentities]', this.Error, err);
        } finally {
            this.Loading = false;
            this.cdr.detectChanges();
        }
    }

    /** Add a Mailbox or Domain row. Refuses a malformed address before anything is saved. */
    public async addRow(kind: SenderIdentityKind, address: string, displayName: string | null): Promise<boolean> {
        const normalized = NormalizeSenderIdentity(kind, address, displayName);
        if (normalized.errors.length > 0) {
            this.Error = normalized.errors.join('; ');
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
                return false;
            }
            this.resetAddForm();
            this.Notice = SENDER_VERIFICATION_REMINDER;
            return true;
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
                return false;
            }
            if (!(await this.saveIsDefault(row, true))) {
                const lost = current ? `; "${current.Address}" is no longer the default` : '';
                this.Error = failureText(`Could not make "${row.Address}" the default`, row) + lost;
                return false;
            }
            return true;
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
            if (!(await row.Delete())) {
                this.Error = failureText(`Could not remove "${row.Address}"`, row);
                return false;
            }
            return true;
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

    public cancelAdd(): void {
        this.resetAddForm();
        this.cdr.detectChanges();
    }

    /**
     * Shared wrapper for every write: one write at a time, a fresh error/notice, a reload and
     * DataChanged on success. `work` sets `Error` itself on an expected failure and returns false;
     * an unexpected throw is reported with `context` (which names the address).
     */
    private async runMutation(context: string, work: () => Promise<boolean>): Promise<boolean> {
        if (this.Saving) {
            return false;
        }
        this.Saving = true;
        this.Error = null;
        this.Notice = null;
        this.cdr.detectChanges();
        try {
            const ok = await work();
            if (ok) {
                await this.reloadAfterWrite(context);
                this.DataChanged.emit();
            }
            return ok;
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
        try {
            await this.fetchRows();
        } catch (err) {
            this.Error = `Saved while ${context}, but the list could not be reloaded: ${err instanceof Error ? err.message : String(err)}`;
            console.error('[CompanySenderIdentities]', this.Error, err);
        }
    }

    /** Throws (with context) when the RunView fails, so callers report it. */
    private async fetchRows(): Promise<void> {
        if (!this.CompanyID) {
            this.Rows = [];
            return;
        }
        const p = this.ProviderToUse;
        const result = await RunView.FromMetadataProvider(p).RunView<CompanySenderIdentityEntity>(
            {
                EntityName: ENTITY_NAME,
                ExtraFilter: `CompanyID = '${this.CompanyID}'`,
                OrderBy: 'Address ASC',
                ResultType: 'entity_object',
            },
            p.CurrentUser,
        );
        if (!result.Success) {
            throw new Error(result.ErrorMessage || 'RunView returned no error message');
        }
        this.Rows = result.Results ?? [];
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
