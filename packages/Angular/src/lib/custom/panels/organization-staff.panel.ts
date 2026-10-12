import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CompositeKey, Metadata } from '@memberjunction/core';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel, BaseFormsModule } from '@memberjunction/ng-base-forms';
import type { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';
import { StatTileComponent } from '../../components/stat-tile/stat-tile.component';
import { StatRowComponent } from '../../components/stat-tile/stat-row.component';
import { COMMON_ENTITIES } from '../../data/entity-names';
import {
    CommonStaffFigures,
    DiscoverOrganizationStaffContributors,
    LoadOrganizationStaff,
    RunStaffContributors,
    type OrganizationStaffMember,
    type StaffCell,
    type StaffContributorResult,
    type StaffFigure,
} from '../../data/organization-staff';

/** A contributed column, namespaced by contributor so two apps can both use Key 'status'. */
interface StaffTableColumn {
    Id: string;
    ContributorKey: string;
    Key: string;
    Header: string;
}

/**
 * Organization form **Staff** section: the organization's active employees, rolled up into headline
 * figures and a staff table. Other apps add figures and columns through
 * `OrganizationStaffContributor` (see `data/organization-staff.ts`); this section never names them.
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:Organizations:staff',
    metadata: {
        entity: 'MJ_BizApps_Common: Organizations',
        slot: 'after-fields',
        sortKey: 80,
        contributionKey: 'staff',
    },
})
@Component({
    selector: 'bizapps-organization-staff-panel',
    standalone: true,
    imports: [CommonModule, BaseFormsModule, StatTileComponent, StatRowComponent],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <mj-collapsible-panel
            SectionKey="staff"
            SectionName="Staff"
            Icon="fa-solid fa-id-badge"
            [Form]="FormComponent"
            [FormContext]="FormContext"
            [BadgeCount]="Staff.length"
            [DefaultExpanded]="true">
            @if (!Record.IsSaved) {
                <p class="bizapps-staff-empty">Save the organization to see its staff.</p>
            } @else if (IsLoading) {
                <div class="bizapps-staff-empty">Loading staff…</div>
            } @else if (LoadError) {
                <p class="bizapps-staff-error" role="status">{{ LoadError }}</p>
            } @else if (Staff.length === 0) {
                <p class="bizapps-staff-empty">No active staff on file. Staff are people with an active Employee relationship to this organization.</p>
            } @else {
                <bizapps-stat-row [Error]="ContributorError">
                    @for (figure of Figures; track $index) {
                        <bizapps-stat-tile
                            [Label]="figure.Label"
                            [Icon]="figure.Icon ?? null"
                            [Value]="figure.Value"
                            [Detail]="figure.Detail ?? null"
                            [Tone]="figure.Tone ?? 'none'"
                            [Clickable]="false" />
                    }
                </bizapps-stat-row>
                <div class="bizapps-staff-table-wrap">
                    <table class="bizapps-staff-table">
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Title</th>
                                <th>Since</th>
                                @for (col of Columns; track col.Id) {
                                    <th>{{ col.Header }}</th>
                                }
                            </tr>
                        </thead>
                        <tbody>
                            @for (member of Staff; track member.PersonID) {
                                <tr>
                                    <td>
                                        <button type="button" class="bizapps-staff-link" (click)="OpenPerson(member)">{{ member.Name }}</button>
                                    </td>
                                    <td>{{ member.Title || '—' }}</td>
                                    <td>{{ member.StartDate ? (member.StartDate | date: 'MMM y' : 'UTC') : '—' }}</td>
                                    @for (col of Columns; track col.Id) {
                                        @let cell = CellFor(member, col);
                                        <td [class]="'bizapps-staff-cell bizapps-staff-cell--' + (cell?.Tone ?? 'none')" [attr.title]="cell?.Title ?? null">{{ cell?.Text ?? '—' }}</td>
                                    }
                                </tr>
                            }
                        </tbody>
                    </table>
                </div>
            }
        </mj-collapsible-panel>
    `,
    styles: [`
        :host { display: block; width: 100%; }
        .bizapps-staff-empty { color: var(--mj-text-muted); font-size: 13px; margin: 0; padding: 8px 0; }
        .bizapps-staff-error { color: var(--mj-status-error-text); font-size: 13px; margin: 0; padding: 8px 0; }
        .bizapps-staff-table-wrap { margin-top: 12px; max-height: 420px; overflow: auto; border: 1px solid var(--mj-border-default); border-radius: var(--mj-radius-md, 8px); }
        .bizapps-staff-table { width: 100%; border-collapse: collapse; font-size: 13px; }
        .bizapps-staff-table th { position: sticky; top: 0; background: var(--mj-bg-surface-sunken, var(--mj-bg-surface)); color: var(--mj-text-secondary); font-weight: 600; text-align: left; padding: 8px 10px; border-bottom: 1px solid var(--mj-border-default); white-space: nowrap; }
        .bizapps-staff-table td { padding: 7px 10px; border-bottom: 1px solid var(--mj-border-subtle, var(--mj-border-default)); color: var(--mj-text-primary); }
        .bizapps-staff-table tr:last-child td { border-bottom: none; }
        .bizapps-staff-link { background: none; border: none; padding: 0; font: inherit; color: var(--mj-brand-primary); cursor: pointer; text-align: left; }
        .bizapps-staff-link:hover { text-decoration: underline; }
        .bizapps-staff-cell--success { color: var(--mj-status-success-text); font-weight: 600; }
        .bizapps-staff-cell--warn { color: var(--mj-status-warning-text); font-weight: 600; }
        .bizapps-staff-cell--error { color: var(--mj-status-error-text); font-weight: 600; }
        .bizapps-staff-cell--muted { color: var(--mj-text-muted); }
    `],
})
export class OrganizationStaffPanel extends BaseFormPanel<mjBizAppsCommonOrganizationEntity> implements OnInit {
    private readonly cdr = inject(ChangeDetectorRef);

    public Staff: OrganizationStaffMember[] = [];
    public Figures: StaffFigure[] = [];
    public Columns: StaffTableColumn[] = [];
    public IsLoading = false;
    public LoadError: string | null = null;
    /** One line naming the contributors that failed; their figures and columns are absent. */
    public ContributorError: string | null = null;
    private results: StaffContributorResult[] = [];

    public async ngOnInit(): Promise<void> {
        if (this.Record?.IsSaved) {
            await this.load();
        }
    }

    /** The cell a contributor supplied for this person and column, if any. */
    public CellFor(member: OrganizationStaffMember, col: StaffTableColumn): StaffCell | null {
        const result = this.results.find(r => r.Contributor.Key === col.ContributorKey);
        return result?.Contribution?.Cells.get(member.PersonID.toUpperCase())?.[col.Key] ?? null;
    }

    public OpenPerson(member: OrganizationStaffMember): void {
        this.FormComponent.OnFormNavigate({
            Kind: 'record',
            EntityName: COMMON_ENTITIES.Person,
            PrimaryKey: CompositeKey.FromID(member.PersonID),
        });
    }

    private async load(): Promise<void> {
        this.IsLoading = true;
        this.cdr.detectChanges();
        try {
            const provider = Metadata.Provider;
            this.Staff = await LoadOrganizationStaff(this.Record.ID, provider);
            if (this.Staff.length > 0) {
                const request = { OrganizationID: this.Record.ID, Staff: this.Staff, Provider: provider };
                this.results = await RunStaffContributors(DiscoverOrganizationStaffContributors(), request);
            }
            this.applyResults();
        } catch (e) {
            this.LoadError = e instanceof Error ? e.message : 'Could not load the organization\'s staff.';
        } finally {
            this.IsLoading = false;
            this.cdr.detectChanges();
        }
    }

    private applyResults(): void {
        const ok = this.results.filter(r => r.Contribution);
        this.Figures = [...CommonStaffFigures(this.Staff), ...ok.flatMap(r => r.Contribution!.Figures)];
        this.Columns = ok.flatMap(r => r.Contribution!.Columns.map(c => ({
            Id: `${r.Contributor.Key}:${c.Key}`,
            ContributorKey: r.Contributor.Key,
            Key: c.Key,
            Header: c.Header,
        })));
        const failed = this.results.filter(r => r.Error).map(r => r.Contributor.Label);
        this.ContributorError = failed.length > 0
            ? `Could not load: ${failed.join(', ')}. Those figures and columns are not shown.`
            : null;
    }
}
