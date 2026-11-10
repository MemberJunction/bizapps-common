/**
 * The Add form's target person and organization use the fast party picker, not the stock FK field,
 * which lists rows on focus and scans `LIKE '%q%'` over the whole party file (golive #372).
 */
import '@angular/compiler';
import { ChangeDetectorRef, Injector, runInInjectionContext } from '@angular/core';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it, vi } from 'vitest';

vi.mock('@memberjunction/ng-base-forms', () => ({ BaseFormsModule: class {} }));

import { RelationshipListComponent } from '../relationship-list.component';

const html = readFileSync(join(__dirname, '..', 'relationship-list.component.html'), 'utf8');
const ts = readFileSync(join(__dirname, '..', 'relationship-list.component.ts'), 'utf8');

function tagFor(fieldName: string): string {
    const match = html.match(new RegExp(`<([a-z-]+)[^>]*FieldName="${fieldName}"[^>]*>`, 's'));
    expect(match, `no tag binds ${fieldName}`).not.toBeNull();
    return match![0];
}

describe('relationship list target pickers', () => {
    it.each([
        ['ToPersonID', 'Person'],
        ['ToOrganizationID', 'Organization'],
    ])('%s uses bizapps-party-field with Kind %s on the draft relationship', (fieldName, kind) => {
        const tag = tagFor(fieldName);
        expect(tag.startsWith('<bizapps-party-field')).toBe(true);
        expect(tag).toContain(`Kind="${kind}"`);
        expect(tag).toContain('[Record]="DraftRelationship"');
        expect(tag).toContain('[EditMode]="true"');
    });

    it.each(['ToPersonID', 'ToOrganizationID'])('%s forwards Navigate, so "create new" reaches the host form', (fieldName) => {
        expect(tagFor(fieldName)).toContain('(Navigate)="Navigate.emit($event)"');
    });

    it('leaves no stock mj-form-field on the target fields', () => {
        expect(html).not.toMatch(/<mj-form-field[^>]*FieldName="To(Person|Organization)ID"/s);
    });

    it('clears the pickers\' search when the relationship type changes', () => {
        const handler = ts.match(/onAddTypeChange\(\): void \{[\s\S]*?\n    \}/);
        expect(handler?.[0]).toContain('ClearSearch()');
    });

    it('imports PartyFieldComponent into the standalone component', () => {
        expect(ts).toMatch(/imports:\s*\[[^\]]*PartyFieldComponent[^\]]*\]/);
    });

    it('clears cached ToPerson and ToOrganization names alongside IDs in onAddTypeChange', () => {
        const injector = Injector.create({
            providers: [{ provide: ChangeDetectorRef, useValue: { detectChanges: () => undefined } }],
        });
        const component = runInInjectionContext(injector, () => new RelationshipListComponent());
        const draft = {
            ToPersonID: 'p-1',
            ToOrganizationID: 'o-1',
            ToPerson: 'Sample Person',
            ToOrganization: 'Sample Org',
        };
        component.DraftRelationship = draft as unknown as typeof component.DraftRelationship;

        component.onAddTypeChange();

        expect(draft.ToPersonID).toBeNull();
        expect(draft.ToOrganizationID).toBeNull();
        expect(draft.ToPerson).toBeNull();
        expect(draft.ToOrganization).toBeNull();
    });

    it('ignores stale ToPerson / FromPerson view names when the corresponding ID is null', () => {
        const injector = Injector.create({
            providers: [{ provide: ChangeDetectorRef, useValue: { detectChanges: () => undefined } }],
        });
        const component = runInInjectionContext(injector, () => new RelationshipListComponent());
        const helpers = component as unknown as {
            getToSideName: (rel: Record<string, unknown>) => string;
            getFromSideName: (rel: Record<string, unknown>) => string;
        };

        expect(
            helpers.getToSideName({
                ToPersonID: null,
                ToPerson: 'Stale Person',
                ToOrganizationID: 'o-1',
                ToOrganization: 'Active Org',
            }),
        ).toBe('Active Org');

        expect(
            helpers.getFromSideName({
                FromPersonID: null,
                FromPerson: 'Stale Person',
                FromOrganizationID: 'o-1',
                FromOrganization: 'Active Org',
            }),
        ).toBe('Active Org');
    });
});
