/**
 * ID comparisons ignore UUID casing (#314). SQL Server returns UUIDs upper-cased and PostgreSQL
 * lower-cased, and an ID from a route or an input binding can be spelled either way. Each test
 * feeds one record's ID in two casings and fails if the component compares them with ===.
 */
import '@angular/compiler';
import { ChangeDetectorRef, Injector, runInInjectionContext } from '@angular/core';
import { describe, expect, it, vi } from 'vitest';

vi.mock('@memberjunction/ng-base-forms', () => ({ BaseFormsModule: class {} }));
vi.mock('@memberjunction/ng-graph-view', () => ({ GraphViewComponent: class {} }));
// The address editor prewarms the action cache in its constructor; there is no provider here.
vi.mock('@memberjunction/actions-base', () => ({ ActionEngineBase: { Instance: { Config: () => Promise.resolve() } } }));

import { ContactMethodListComponent } from '../contact-method-list/contact-method-list.component';
import { AddressEditorComponent } from '../address-editor/address-editor.component';
import { CommonRelationshipGraphComponent } from '../relationship-graph/common-relationship-graph.component';
import type { DirectoryRelationshipRow } from '../../data/directory-types';

const UPPER = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
const LOWER = UPPER.toLowerCase();
const OTHER = '0F0E0D0C-0B0A-0908-0706-050403020100';

function create<T>(ctor: new () => T): T {
    const injector = Injector.create({
        providers: [{ provide: ChangeDetectorRef, useValue: { detectChanges: () => undefined, markForCheck: () => undefined } }],
    });
    return runInInjectionContext(injector, () => new ctor());
}

describe('ContactMethodListComponent', () => {
    type ContactType = ContactMethodListComponent['ContactTypes'][number];
    type ContactMethod = ContactMethodListComponent['ContactMethods'][number];

    it('finds the contact type icon when the type ID casing differs', () => {
        const component = create(ContactMethodListComponent);
        component.ContactTypes = [{ ID: UPPER, IconClass: 'fa-solid fa-envelope' } as unknown as ContactType];

        expect(component.getContactTypeIcon(LOWER)).toBe('fa-solid fa-envelope');
    });

    it('marks the row being edited and opens the form on the option ID spelling', () => {
        const component = create(ContactMethodListComponent);
        component.ContactTypes = [{ ID: UPPER } as unknown as ContactType];
        const cm = { ID: UPPER, ContactTypeID: LOWER, Value: 'a@b.test', Label: null, IsPrimary: false } as unknown as ContactMethod;

        component.onEdit(cm);
        component.EditingId = LOWER;

        expect(component.IsEditing(cm)).toBe(true);
        expect(component.EditForm.TypeID).toBe(UPPER);
    });
});

describe('AddressEditorComponent', () => {
    type AddressType = AddressEditorComponent['AddressTypes'][number];

    it('finds the address type icon when the type ID casing differs', () => {
        const component = create(AddressEditorComponent);
        component.AddressTypes = [{ ID: UPPER, IconClass: 'fa-solid fa-building' } as unknown as AddressType];

        expect(component.getAddressTypeIcon(LOWER)).toBe('fa-solid fa-building');
    });
});

describe('CommonRelationshipGraphComponent', () => {
    it('draws the focal person once when the input and the rows spell the ID differently', () => {
        const component = create(CommonRelationshipGraphComponent);
        component.PersonID = LOWER;
        component.FocalNodeID = `person:${LOWER}`;
        const row = {
            ID: OTHER,
            FromPersonID: UPPER,
            FromPerson: 'Pat Example',
            ToOrganizationID: OTHER,
            ToOrganization: 'Example Co',
            RelationshipType: 'Employee',
        } as unknown as DirectoryRelationshipRow;

        (component as unknown as { BuildGraphFromRelationships(rows: DirectoryRelationshipRow[]): void })
            .BuildGraphFromRelationships([row]);

        const people = component.Nodes.filter((n) => n.Category === 'person');
        expect(people).toHaveLength(1);
        expect(people[0].Label).toBe('Pat Example');
        expect(component.Edges[0].SourceID).toBe(people[0].ID);
    });
});
