import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import type { EntityInfo } from '@memberjunction/core';
import type { MJUserViewEntityExtended } from '@memberjunction/core-entities';
import { EntityViewerModule, type RecordOpenedEvent } from '@memberjunction/ng-entity-viewer';
import { MJButtonDirective } from '@memberjunction/ng-ui-components';
import { COMMON_ENTITIES } from '../data/entity-names';
import { LoadPeopleDirectoryView } from '../data/directory-views';
import { OpenCommonRecord, OpenNewCommonRecord } from '../open-record';

@Component({
    selector: 'bizapps-common-people-page',
    standalone: true,
    imports: [CommonModule, FormsModule, MJButtonDirective, EntityViewerModule],
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
                    (ngModelChange)="Search = $event" />
            </div>
            <div class="mjc-viewer-host">
                @if (EntityInfo && View) {
                    <mj-entity-viewer
                        [Entity]="EntityInfo"
                        [ViewEntity]="View"
                        [FilterText]="Search"
                        [ShowRecycleBin]="false"
                        (RecordOpened)="OnOpened($event)">
                    </mj-entity-viewer>
                } @else {
                    <p class="mjc-list__muted">{{ EmptyText }}</p>
                }
            </div>
        </div>
    `,
    styles: [
        `
            :host { display: block; height: 100%; overflow: hidden; }
            .mjc-list { padding: var(--mj-space-6); display: flex; flex-direction: column; gap: var(--mj-space-4); height: 100%; box-sizing: border-box; }
            .mjc-list__head { display: flex; justify-content: space-between; gap: var(--mj-space-3); align-items: flex-start; flex-wrap: wrap; flex: none; }
            .mjc-list__head h1 { margin: 0; font-size: 1.25rem; }
            .mjc-list__head p { margin: 4px 0 0; color: var(--mj-text-muted); font-size: 0.8125rem; }
            .mjc-list__toolbar { display: flex; gap: var(--mj-space-3); align-items: center; flex: none; }
            .mjc-list__toolbar input { flex: 1; min-width: 0; }
            .mjc-list__muted { color: var(--mj-text-muted); font-size: 0.75rem; }
            .mjc-viewer-host { flex: 1; min-height: 0; }
        `,
    ],
})
export class CommonPeoplePageComponent implements OnInit {
    private readonly cdr = inject(ChangeDetectorRef);

    public Search = '';
    public EntityInfo: EntityInfo | null = null;
    public View: MJUserViewEntityExtended | null = null;
    public EmptyText = 'Loading people…';

    public async ngOnInit(): Promise<void> {
        const loaded = await LoadPeopleDirectoryView();
        this.EntityInfo = loaded.entity;
        this.View = loaded.view;
        this.EmptyText = loaded.entity ? 'No people yet.' : 'People entity metadata is not loaded.';
        this.cdr.detectChanges();
    }

    public OnOpened(event: RecordOpenedEvent): void {
        const id = (event.compositeKey?.GetValueByFieldName('ID') ?? event.record?.['ID']) as string | undefined;
        OpenCommonRecord(COMMON_ENTITIES.Person, id);
    }

    public NewPerson(): void {
        OpenNewCommonRecord(COMMON_ENTITIES.Person);
    }
}
