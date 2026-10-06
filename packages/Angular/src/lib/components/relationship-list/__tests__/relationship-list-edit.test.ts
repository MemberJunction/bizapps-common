/**
 * The relationship list's own call sites for StartDate/EndDate, driven through the component under a
 * machine zone west of UTC (golive #168). relationship-dates.test.ts pins the helpers; these pin that
 * the component uses them: the Edit form opens on the stored day, saving an untouched form stores the
 * same instant, the row's date range shows the stored months, and a new relationship stores the day
 * typed. A local getter or a local-midnight parse at any of them passes the helper tests and fails here.
 */
import '@angular/compiler';
import { ChangeDetectorRef, Injector, runInInjectionContext } from '@angular/core';
import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { FromCalendarDay } from '@mj-biz-apps/common-entities';

vi.mock('@memberjunction/ng-base-forms', () => ({ BaseFormsModule: class {} }));

import { RelationshipListComponent } from '../relationship-list.component';

type Relationship = Parameters<RelationshipListComponent['onEdit']>[0];
type Collection = NonNullable<RelationshipListComponent['Collection']>;

interface FakeRelationship {
    ID: string;
    RelationshipTypeID: string;
    Title: string | null;
    Status: string;
    StartDate: Date | null;
    EndDate: Date | null;
    JobFunctionID: string | null;
    SeniorityLevelID: string | null;
    FromPersonID: string | null;
    ToOrganizationID: string | null;
    ToOrganization: string | null;
    Save: ReturnType<typeof vi.fn>;
}

const CENTRAL = 'America/Chicago';
let savedTZ: string | undefined;

beforeAll(() => {
    savedTZ = process.env.TZ;
    process.env.TZ = CENTRAL;
});

afterAll(() => {
    if (savedTZ === undefined) delete process.env.TZ;
    else process.env.TZ = savedTZ;
});

function relationship(start: string, end: string | null, status = 'Active'): FakeRelationship {
    return {
        ID: 'r1',
        RelationshipTypeID: 't1',
        Title: 'Engineer',
        Status: status,
        StartDate: FromCalendarDay(start),
        EndDate: end ? FromCalendarDay(end) : null,
        JobFunctionID: null,
        SeniorityLevelID: null,
        FromPersonID: 'p1',
        ToOrganizationID: 'o1',
        ToOrganization: 'Acme',
        Save: vi.fn().mockResolvedValue(true),
    };
}

/** A component whose relationships come from a parent's collection, so a save rebuilds the rows. */
function build(rel: FakeRelationship): RelationshipListComponent {
    const injector = Injector.create({
        providers: [{ provide: ChangeDetectorRef, useValue: { detectChanges: () => undefined } }],
    });
    const component = runInInjectionContext(injector, () => new RelationshipListComponent());
    // Loading reads the database; these tests start from rows already on screen.
    vi.spyOn(component as unknown as { loadData: () => Promise<void> }, 'loadData').mockResolvedValue();
    component.Collection = { Items: [rel], IsLoaded: true } as unknown as Collection;
    component.GroupedRelationships = [
        { Category: 'Unknown', Label: 'Unknown', Icon: '', IconClass: '', Items: [{ Relationship: rel as unknown as Relationship, DirectionLabel: '', TargetName: '', TargetEntityName: '', TargetID: '', DateDisplay: '' }] },
    ];
    return component;
}

describe('machine zone', () => {
    it('is west of UTC for these tests', () => {
        expect(new Date('2026-01-01T00:00:00.000Z').getDate()).toBe(31);
    });
});

describe('RelationshipListComponent date call sites', () => {
    it('opens the Edit form on the stored days, not the previous local days', () => {
        const rel = relationship('2026-01-01', '2026-03-15', 'Ended');
        const component = build(rel);

        component.onEdit(rel as unknown as Relationship);

        expect(component.EditForm.StartDate).toBe('2026-01-01');
        expect(component.EditForm.EndDate).toBe('2026-03-15');
    });

    it('saves an untouched Edit form without moving either date', async () => {
        const rel = relationship('2026-01-01', '2026-03-15', 'Ended');
        const start = rel.StartDate!.getTime();
        const end = rel.EndDate!.getTime();
        const component = build(rel);

        component.onEdit(rel as unknown as Relationship);
        await component.onSaveEdit();

        expect(rel.StartDate?.getTime()).toBe(start);
        expect(rel.EndDate?.getTime()).toBe(end);
    });

    it('shows the row date range by the stored months', async () => {
        const rel = relationship('2026-01-01', null);
        const component = build(rel);

        component.onEdit(rel as unknown as Relationship);
        await component.onSaveEdit();

        expect(component.GroupedRelationships[0].Items[0].DateDisplay).toBe('Jan 2026 - Present');
    });

    it('stores the day typed into the Add form as that day, not the local midnight before it', async () => {
        const rel = relationship('2024-07-01', null);
        const component = build(rel);
        const draft: FakeRelationship = { ...relationship('2024-07-01', null), StartDate: null };
        component.RelationshipTypes = [{ ID: 't1', Category: 'PersonToOrganization' }] as unknown as RelationshipListComponent['RelationshipTypes'];
        component.DraftRelationship = draft as unknown as Relationship;
        component.AddForm = { ...component.AddForm, TypeID: 't1', StartDate: '2026-01-01', EndDate: '2026-03-15' };

        await component.onSaveAdd();

        expect(draft.StartDate?.toISOString()).toBe('2026-01-01T00:00:00.000Z');
        expect(draft.EndDate?.toISOString()).toBe('2026-03-15T00:00:00.000Z');
    });
});
