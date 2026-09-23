import {
    ChangeDetectionStrategy,
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
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { IMetadataProvider, Metadata, RunView } from '@memberjunction/core';
import { UUIDsEqual } from '@memberjunction/global';
import { MJButtonDirective } from '@memberjunction/ng-ui-components';
import {
    mjBizAppsCommonJobFunctionEntity,
    mjBizAppsCommonPersonJobFunctionEntity,
} from '@mj-biz-apps/common-entities';

/**
 * Visual editor and manager for a Person's assigned Job Functions.
 * Displays functions in sequence order with primary badge, confidence metrics,
 * inline sequence reordering (Move Up / Down), set-as-primary, delete, and quick-add.
 */
@Component({
    selector: 'bizapps-person-job-functions',
    standalone: true,
    changeDetection: ChangeDetectionStrategy.OnPush,
    imports: [CommonModule, FormsModule, MJButtonDirective],
    templateUrl: './person-job-functions.component.html',
    styleUrls: ['./person-job-functions.component.css'],
})
export class PersonJobFunctionsComponent implements OnInit, OnChanges {
    private cdr = inject(ChangeDetectorRef);

    @Input() PersonID: string | null = null;
    @Input() EditMode = true;
    @Input() Provider?: IMetadataProvider;

    @Output() DataChanged = new EventEmitter<void>();

    /** The provider actually used — the one passed in, or the ambient one. */
    public get ProviderToUse(): IMetadataProvider {
        return this.Provider ?? Metadata.Provider;
    }

    public Items: mjBizAppsCommonPersonJobFunctionEntity[] = [];
    public AvailableFunctions: mjBizAppsCommonJobFunctionEntity[] = [];
    public Loading = false;
    public Saving = false;
    public ErrorMessage: string | null = null;
    public SelectedFunctionIDToAdd = '';
    public ShowAddPicker = false;

    public async ngOnInit(): Promise<void> {
        await this.loadAll();
    }

    public async ngOnChanges(changes: SimpleChanges): Promise<void> {
        if (changes['PersonID'] && !changes['PersonID'].firstChange) {
            await this.loadAll();
        }
    }

    /** Unassigned job functions available for quick assignment. */
    public get unassignedFunctions(): mjBizAppsCommonJobFunctionEntity[] {
        return this.AvailableFunctions.filter(
            (f) => !this.Items.some((item) => UUIDsEqual(item.JobFunctionID, f.ID))
        );
    }

    /** Reload both available functions catalog and assigned person functions. */
    public async loadAll(): Promise<void> {
        if (!this.PersonID) {
            this.Items = [];
            this.cdr.markForCheck();
            return;
        }

        this.Loading = true;
        this.ErrorMessage = null;
        this.cdr.markForCheck();

        try {
            const p = this.ProviderToUse;
            const rv = new RunView();

            const [catalogRes, assignedRes] = await Promise.all([
                rv.RunView<mjBizAppsCommonJobFunctionEntity>(
                    {
                        EntityName: 'MJ_BizApps_Common: Job Functions',
                        ExtraFilter: "Status = 'Active'",
                        OrderBy: 'Name ASC',
                        ResultType: 'entity_object',
                    },
                    p.CurrentUser
                ),
                rv.RunView<mjBizAppsCommonPersonJobFunctionEntity>(
                    {
                        EntityName: 'MJ_BizApps_Common: Person Job Functions',
                        ExtraFilter: `PersonID = '${this.PersonID}'`,
                        OrderBy: 'Sequence ASC, __mj_CreatedAt ASC',
                        ResultType: 'entity_object',
                    },
                    p.CurrentUser
                ),
            ]);

            if (catalogRes.Success && catalogRes.Results) {
                this.AvailableFunctions = catalogRes.Results;
            } else if (!catalogRes.Success) {
                this.ErrorMessage = catalogRes.ErrorMessage || 'Failed to load job function catalog';
            }

            if (assignedRes.Success && assignedRes.Results) {
                this.Items = [...assignedRes.Results].sort((a, b) => (a.Sequence || 0) - (b.Sequence || 0));
            } else if (!assignedRes.Success) {
                this.ErrorMessage = assignedRes.ErrorMessage || 'Failed to load assigned job functions';
            }
        } catch (err) {
            console.error('[PersonJobFunctions] Failed to load job functions:', err);
            this.ErrorMessage = err instanceof Error ? err.message : String(err);
        } finally {
            this.Loading = false;
            this.cdr.markForCheck();
        }
    }

    /** Add a selected job function to the person. */
    public async onAddFunction(): Promise<void> {
        if (!this.PersonID || !this.SelectedFunctionIDToAdd || this.Saving) return;

        this.Saving = true;
        this.ErrorMessage = null;
        this.cdr.markForCheck();

        try {
            const p = this.ProviderToUse;
            const newRecord = await p.GetEntityObject<mjBizAppsCommonPersonJobFunctionEntity>(
                'MJ_BizApps_Common: Person Job Functions',
                p.CurrentUser
            );

            const nextSeq = this.Items.length > 0
                ? Math.max(...this.Items.map((i) => i.Sequence || 0)) + 1
                : 1;

            newRecord.PersonID = this.PersonID;
            newRecord.JobFunctionID = this.SelectedFunctionIDToAdd;
            newRecord.Sequence = nextSeq;
            newRecord.Source = 'Manual';

            const saved = await newRecord.Save();
            if (!saved) {
                throw new Error(newRecord.LatestResult?.CompleteMessage || 'Failed to save job function');
            }

            this.SelectedFunctionIDToAdd = '';
            this.ShowAddPicker = false;
            await this.loadAll();
            this.DataChanged.emit();
        } catch (err) {
            console.error('[PersonJobFunctions] Add function failed:', err);
            this.ErrorMessage = err instanceof Error ? err.message : String(err);
        } finally {
            this.Saving = false;
            this.cdr.markForCheck();
        }
    }

    /** Remove an assigned job function. */
    public async onRemove(item: mjBizAppsCommonPersonJobFunctionEntity): Promise<void> {
        if (this.Saving) return;

        this.Saving = true;
        this.ErrorMessage = null;
        this.cdr.markForCheck();

        try {
            const deleted = await item.Delete();
            if (!deleted) {
                throw new Error(item.LatestResult?.CompleteMessage || 'Failed to remove job function');
            }

            // Renumber remaining items to ensure sequential 1..N order
            const remaining = this.Items.filter((i) => !UUIDsEqual(i.ID, item.ID));
            await this.normalizeSequences(remaining);

            await this.loadAll();
            this.DataChanged.emit();
        } catch (err) {
            console.error('[PersonJobFunctions] Remove function failed:', err);
            this.ErrorMessage = err instanceof Error ? err.message : String(err);
        } finally {
            this.Saving = false;
            this.cdr.markForCheck();
        }
    }

    /** Move a function up one position. */
    public async onMoveUp(index: number): Promise<void> {
        if (index <= 0 || this.Saving) return;
        await this.swapPositions(index, index - 1);
    }

    /** Move a function down one position. */
    public async onMoveDown(index: number): Promise<void> {
        if (index >= this.Items.length - 1 || this.Saving) return;
        await this.swapPositions(index, index + 1);
    }

    /** Promote any function directly to #1 (Primary). */
    public async onSetPrimary(index: number): Promise<void> {
        if (index === 0 || this.Saving) return;

        this.Saving = true;
        this.ErrorMessage = null;
        this.cdr.markForCheck();

        try {
            const target = this.Items[index];
            const reordered = [target, ...this.Items.filter((_, i) => i !== index)];
            await this.normalizeSequences(reordered);

            await this.loadAll();
            this.DataChanged.emit();
        } catch (err) {
            console.error('[PersonJobFunctions] Set primary failed:', err);
            this.ErrorMessage = err instanceof Error ? err.message : String(err);
        } finally {
            this.Saving = false;
            this.cdr.markForCheck();
        }
    }

    private async swapPositions(idxA: number, idxB: number): Promise<void> {
        this.Saving = true;
        this.ErrorMessage = null;
        this.cdr.markForCheck();

        try {
            const copy = [...this.Items];
            const temp = copy[idxA];
            copy[idxA] = copy[idxB];
            copy[idxB] = temp;

            await this.normalizeSequences(copy);

            await this.loadAll();
            this.DataChanged.emit();
        } catch (err) {
            console.error('[PersonJobFunctions] Swap positions failed:', err);
            this.ErrorMessage = err instanceof Error ? err.message : String(err);
        } finally {
            this.Saving = false;
            this.cdr.markForCheck();
        }
    }

    /** Assign consecutive sequence numbers 1..N and persist changes. */
    private async normalizeSequences(items: mjBizAppsCommonPersonJobFunctionEntity[]): Promise<void> {
        for (let i = 0; i < items.length; i++) {
            const expectedSeq = i + 1;
            if (items[i].Sequence !== expectedSeq) {
                items[i].Sequence = expectedSeq;
                const saved = await items[i].Save();
                if (!saved) {
                    throw new Error(items[i].LatestResult?.CompleteMessage || `Failed to update sequence for job function ${items[i].JobFunction}`);
                }
            }
        }
    }

    /** Format confidence score as a percentage. */
    public formatConfidence(score: number | null | undefined): string {
        if (score == null) return '';
        return `${Math.round(score * 100)}%`;
    }
}
