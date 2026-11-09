/**
 * A relationship row is labelled with the name that goes with whichever key is set, and a type change
 * in the Add form clears the target's name as well as its key (bizapps-common#387).
 *
 * In collection mode the row is built from the draft itself, whose virtual name fields the party picker
 * wrote. Picking a person, switching to an organization type and picking an organization used to leave
 * the person's name on the draft, and `ToPerson || ToOrganization` then labelled the organization with it.
 */
import '@angular/compiler';
import { ChangeDetectorRef, Injector, runInInjectionContext } from '@angular/core';
import { describe, expect, it, vi } from 'vitest';

vi.mock('@memberjunction/ng-base-forms', () => ({ BaseFormsModule: class {} }));

import { RelationshipListComponent } from '../relationship-list.component';

interface FakeRelationship {
    FromPersonID: string | null;
    FromOrganizationID: string | null;
    FromPerson: string | null;
    FromOrganization: string | null;
    ToPersonID: string | null;
    ToOrganizationID: string | null;
    ToPerson: string | null;
    ToOrganization: string | null;
    Set(field: string, value: unknown): void;
}

/** The private name helpers under test. */
interface NameHelpers {
    getToSideName(rel: FakeRelationship): string;
    getFromSideName(rel: FakeRelationship): string;
}

function relationship(values: Partial<Omit<FakeRelationship, 'Set'>>): FakeRelationship {
    const rel: FakeRelationship = {
        FromPersonID: null,
        FromOrganizationID: null,
        FromPerson: null,
        FromOrganization: null,
        ToPersonID: null,
        ToOrganizationID: null,
        ToPerson: null,
        ToOrganization: null,
        ...values,
        Set(field: string, value: unknown): void {
            (rel as unknown as Record<string, unknown>)[field] = value;
        },
    };
    return rel;
}

function build(): RelationshipListComponent {
    const injector = Injector.create({
        providers: [{ provide: ChangeDetectorRef, useValue: { detectChanges: () => undefined } }],
    });
    return runInInjectionContext(injector, () => new RelationshipListComponent());
}

function names(component: RelationshipListComponent): NameHelpers {
    return component as unknown as NameHelpers;
}

describe('relationship row names', () => {
    it('labels an organization target with the organization, even with a stale person name left on the row', () => {
        const rel = relationship({ ToOrganizationID: 'o-1', ToOrganization: 'Acme', ToPerson: 'Pat Person' });
        expect(names(build()).getToSideName(rel)).toBe('Acme');
    });

    it('labels a person target with the person, even with a stale organization name left on the row', () => {
        const rel = relationship({ ToPersonID: 'p-1', ToPerson: 'Pat Person', ToOrganization: 'Acme' });
        expect(names(build()).getToSideName(rel)).toBe('Pat Person');
    });

    it('keys the From side off its key the same way', () => {
        expect(names(build()).getFromSideName(relationship({ FromOrganizationID: 'o-1', FromOrganization: 'Acme', FromPerson: 'Pat Person' }))).toBe('Acme');
        expect(names(build()).getFromSideName(relationship({ FromPersonID: 'p-1', FromPerson: 'Pat Person', FromOrganization: 'Acme' }))).toBe('Pat Person');
    });

    it('says Unknown when no key is set, whatever names are left', () => {
        expect(names(build()).getToSideName(relationship({ ToPerson: 'Pat Person' }))).toBe('Unknown');
        expect(names(build()).getFromSideName(relationship({ FromOrganization: 'Acme' }))).toBe('Unknown');
    });
});

describe('RelationshipListComponent.onAddTypeChange', () => {
    it('clears the target names as well as the keys', () => {
        const component = build();
        const draft = relationship({ ToPersonID: 'p-1', ToPerson: 'Pat Person' });
        component.DraftRelationship = draft as unknown as RelationshipListComponent['DraftRelationship'];
        component.onAddTypeChange();
        expect(draft).toMatchObject({ ToPersonID: null, ToOrganizationID: null, ToPerson: null, ToOrganization: null });
    });
});
