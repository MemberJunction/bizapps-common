import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MJButtonDirective } from '@memberjunction/ng-ui-components';
import { EntityViewerModule, type RecordOpenedEvent } from '@memberjunction/ng-entity-viewer';
import { Metadata, type EntityInfo } from '@memberjunction/core';
import { COMMON_ENTITIES } from '../data/entity-names';
import { OpenCommonRecord, OpenNewCommonRecord } from '../open-record';

@Component({
    selector: 'bizapps-common-people-page',
    standalone: true,
    imports: [CommonModule, FormsModule, MJButtonDirective, EntityViewerModule],
    template: `
        <div class="mjc-people-page">
            <header class="mjc-people-page__head">
                <div>
                    <h1>People Directory</h1>
                    <p>Search, filter, and view people across your organization using the MemberJunction Entity Viewer.</p>
                </div>
                <button mjButton variant="primary" size="sm" type="button" (click)="NewPerson()">
                    <i class="fa-solid fa-user-plus" aria-hidden="true"></i> New person
                </button>
            </header>

            <div class="mjc-viewer-container">
                @if (PersonEntityInfo) {
                    <mj-entity-viewer
                        [Entity]="PersonEntityInfo"
                        (RecordOpened)="OnRecordOpened($event)">
                    </mj-entity-viewer>
                } @else {
                    <div class="small muted" style="padding: 24px;">Loading directory metadata...</div>
                }
            </div>
        </div>
    `,
    styles: [
        `
            :host {
                display: block;
                height: 100%;
                overflow: hidden;
            }
            .mjc-people-page {
                height: 100%;
                display: flex;
                flex-direction: column;
                padding: var(--mj-space-6);
                gap: var(--mj-space-4);
                box-sizing: border-box;
            }
            .mjc-people-page__head {
                display: flex;
                justify-content: space-between;
                gap: var(--mj-space-3);
                align-items: flex-start;
                flex-wrap: wrap;
                flex: none;
            }
            .mjc-people-page__head h1 {
                margin: 0;
                font-size: 1.25rem;
            }
            .mjc-people-page__head p {
                margin: 4px 0 0;
                color: var(--mj-text-muted);
                font-size: 0.8125rem;
            }
            .mjc-viewer-container {
                flex: 1;
                min-height: 0;
                background: var(--mj-bg-surface);
                border: 1px solid var(--mj-border-default);
                border-radius: var(--mj-radius-md);
                overflow: hidden;
            }
            @media (max-width: 760px) {
                .mjc-people-page {
                    padding: var(--mj-space-4);
                }
            }
        `,
    ],
})
export class CommonPeoplePageComponent implements OnInit {
    private readonly cdr = inject(ChangeDetectorRef);

    public PersonEntityInfo: EntityInfo | null = null;

    public ngOnInit(): void {
        const md = new Metadata();
        this.PersonEntityInfo = md.Entities.find(e => e.Name === COMMON_ENTITIES.Person) || null;
        this.cdr.detectChanges();
    }

    public OnRecordOpened(event: RecordOpenedEvent): void {
        const id = (event.compositeKey?.GetValueByFieldName('ID') ?? event.record?.['ID']) as string | undefined;
        if (id) {
            OpenCommonRecord(COMMON_ENTITIES.Person, id);
        }
    }

    public NewPerson(): void {
        OpenNewCommonRecord(COMMON_ENTITIES.Person);
    }
}
