import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MJButtonDirective } from '@memberjunction/ng-ui-components';
import { COMMON_ENTITIES } from '../data/entity-names';
import { SearchPeople } from '../data/directory-queries';
import { EscapeLikeValue, PersonEmail, PersonPhone } from '../data/directory-stats';
import type { DirectoryPersonRow } from '../data/directory-types';
import { OpenCommonRecord, OpenNewCommonRecord } from '../open-record';

@Component({
    selector: 'bizapps-common-people-page',
    standalone: true,
    imports: [CommonModule, FormsModule, MJButtonDirective],
    template: `
        <div class="mjc-list">
            <header class="mjc-list__head">
                <div>
                    <h1>People</h1>
                    <p>Everyone in the directory. Click a row to open the person.</p>
                </div>
                <button mjButton variant="primary" size="sm" type="button" (click)="NewPerson()">
                    <i class="fa-solid fa-user-plus" aria-hidden="true"></i> New person
                </button>
            </header>
            <div class="mjc-list__toolbar">
                <input
                    class="mj-input"
                    type="search"
                    placeholder="Search name, email, or organization"
                    [ngModel]="Search"
                    (ngModelChange)="OnSearch($event)" />
                <span class="mjc-list__count">{{ People.length }} shown</span>
            </div>
            <div class="mjc-table-wrap">
                <table class="mjc-table">
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th>Organization</th>
                            <th>Email</th>
                            <th>Phone</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        @for (person of People; track person.ID) {
                            <tr (click)="Open(person.ID)">
                                <td>
                                    <strong>{{ person.DisplayName }}</strong>
                                    @if (person.Title) {
                                        <div class="mjc-list__muted">{{ person.Title }}</div>
                                    }
                                </td>
                                <td>{{ person.CurrentOrganizationName || '—' }}</td>
                                <td>{{ emailOf(person) || '—' }}</td>
                                <td>{{ phoneOf(person) || '—' }}</td>
                                <td><span class="mjc-chip" [attr.data-status]="person.Status">{{ person.Status }}</span></td>
                            </tr>
                        } @empty {
                            <tr><td colspan="5" class="mjc-list__muted">{{ EmptyText }}</td></tr>
                        }
                    </tbody>
                </table>
            </div>
        </div>
    `,
    styles: [
        `
            :host { display: block; height: 100%; overflow: auto; }
            .mjc-list { padding: var(--mj-space-6); display: flex; flex-direction: column; gap: var(--mj-space-4); }
            .mjc-list__head { display: flex; justify-content: space-between; gap: var(--mj-space-3); align-items: flex-start; flex-wrap: wrap; }
            .mjc-list__head h1 { margin: 0; font-size: 1.25rem; }
            .mjc-list__head p { margin: 4px 0 0; color: var(--mj-text-muted); font-size: 0.8125rem; }
            .mjc-list__toolbar { display: flex; gap: var(--mj-space-3); align-items: center; }
            .mjc-list__toolbar input { flex: 1; min-width: 0; }
            .mjc-list__count { color: var(--mj-text-muted); font-size: 0.8125rem; white-space: nowrap; }
            .mjc-list__muted { color: var(--mj-text-muted); font-size: 0.75rem; }
            .mjc-table-wrap { overflow: auto; background: var(--mj-bg-surface); border: 1px solid var(--mj-border-default); border-radius: var(--mj-radius-md); }
            .mjc-table { width: 100%; border-collapse: collapse; font-size: 0.875rem; }
            .mjc-table th, .mjc-table td { padding: var(--mj-space-3) var(--mj-space-4); text-align: left; border-bottom: 1px solid var(--mj-border-subtle); }
            .mjc-table th { font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.04em; color: var(--mj-text-muted); }
            .mjc-table tbody tr { cursor: pointer; }
            .mjc-table tbody tr:hover { background: var(--mj-bg-surface-hover); }
            .mjc-chip { font-size: 0.75rem; padding: 2px 8px; border-radius: var(--mj-radius-pill, 999px); background: var(--mj-bg-surface-sunken); }
            .mjc-chip[data-status='Active'] { background: color-mix(in srgb, var(--mj-status-success) 16%, var(--mj-bg-surface)); color: var(--mj-status-success-text); }
            .mjc-chip[data-status='Inactive'] { background: var(--mj-bg-surface-sunken); color: var(--mj-text-muted); }
        `,
    ],
})
export class CommonPeoplePageComponent implements OnInit {
    private readonly cdr = inject(ChangeDetectorRef);
    private searchTimer: ReturnType<typeof setTimeout> | undefined;

    public Search = '';
    public People: DirectoryPersonRow[] = [];
    public EmptyText = 'No people yet.';

    public async ngOnInit(): Promise<void> {
        await this.reload();
    }

    public OnSearch(value: string): void {
        this.Search = value;
        clearTimeout(this.searchTimer);
        this.searchTimer = setTimeout(() => void this.reload(), 250);
    }

    public emailOf(person: DirectoryPersonRow): string | null {
        return PersonEmail(person);
    }

    public phoneOf(person: DirectoryPersonRow): string | null {
        return PersonPhone(person);
    }

    public Open(id: string): void {
        OpenCommonRecord(COMMON_ENTITIES.Person, id);
    }

    public NewPerson(): void {
        OpenNewCommonRecord(COMMON_ENTITIES.Person);
    }

    private async reload(): Promise<void> {
        const term = this.Search.trim();
        const filter = term ? this.buildFilter(term) : undefined;
        this.People = await SearchPeople(filter);
        this.EmptyText = term ? `No people match “${term}”.` : 'No people yet.';
        this.cdr.detectChanges();
    }

    private buildFilter(term: string): string {
        const escaped = EscapeLikeValue(term);
        return `(DisplayName LIKE '%${escaped}%' OR Email LIKE '%${escaped}%' OR PrimaryEmail LIKE '%${escaped}%' OR CurrentOrganizationName LIKE '%${escaped}%')`;
    }
}
