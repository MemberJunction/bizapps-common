/**
 * #343 — the Organization and Person heroes claim the generated identity sections
 * (`replacesSectionKey`), and a claim hides the generated section outright: rail item and Manage
 * Sections entry included. So the hero is the only place those fields can be edited. The heroes
 * rendered a subset of them (Organizations lost Type, Description, Founded date, Tax ID and Status;
 * People lost Middle name and Display name), and put even that subset behind the collapse toggle.
 *
 * Both are structural, so these tests read the structures: the registration's claim, the generated
 * section's field list, and the hero template.
 */
import '@angular/compiler';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { MJGlobal } from '@memberjunction/global';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';
import { OrganizationHeaderPanel } from '../../../custom/panels/organization-header.panel';
import { PersonHeaderPanel } from '../../../custom/panels/person-header.panel';

function ReadRepoFile(relativeToThisFile: string): string {
    return readFileSync(fileURLToPath(new URL(relativeToThisFile, import.meta.url)), 'utf8');
}

function FieldNames(markup: string): string[] {
    return [...markup.matchAll(/FieldName="([^"]+)"/g)].map((m) => m[1]);
}

/** Field names declared inside one generated `<mj-collapsible-panel SectionKey="...">` block. */
function GeneratedSectionFields(generatedHtml: string, sectionKey: string): string[] {
    const start = generatedHtml.indexOf(`SectionKey="${sectionKey}"`);
    expect(start, `generated section ${sectionKey} not found`).toBeGreaterThan(-1);
    const end = generatedHtml.indexOf('</mj-collapsible-panel>', start);
    expect(end, `generated section ${sectionKey} is unterminated`).toBeGreaterThan(start);
    return FieldNames(generatedHtml.slice(start, end));
}

/** The hero's edit block: from its `@if (EditMode)` to the end of the template. */
function EditBlock(heroHtml: string): string {
    const start = heroHtml.indexOf('<div class="biz-hero__edit">');
    expect(start, 'hero has no edit block').toBeGreaterThan(-1);
    return heroHtml.slice(start);
}

/** True when `index` sits inside the `@if (!Collapsed) { ... }` block. Braces in a template balance. */
function InsideCollapsedBlock(heroHtml: string, index: number): boolean {
    const open = heroHtml.indexOf('@if (!Collapsed) {');
    if (open === -1 || open > index) {
        return false;
    }
    let depth = 0;
    for (let i = open; i < index; i++) {
        if (heroHtml[i] === '{') {
            depth++;
        } else if (heroHtml[i] === '}' && --depth === 0) {
            return false; // the collapsed block closed before `index`
        }
    }
    return true;
}

function ClaimedSectionKey(panel: unknown): unknown {
    const registration = MJGlobal.Instance.ClassFactory.GetAllRegistrations(BaseFormPanel).find((r) => r.SubClass === panel);
    return (registration?.Metadata as Record<string, unknown> | undefined)?.['replacesSectionKey'];
}

const HEROES = [
    {
        name: 'Organization',
        panel: OrganizationHeaderPanel,
        sectionKey: 'organizationIdentity',
        hero: '../organization-identity.component.html',
        generated: '../../../generated/Entities/mjBizAppsCommonOrganization/mjbizappscommonorganization.form.component.html',
    },
    {
        name: 'Person',
        panel: PersonHeaderPanel,
        sectionKey: 'personalIdentity',
        hero: '../person-identity.component.html',
        generated: '../../../generated/Entities/mjBizAppsCommonPerson/mjbizappscommonperson.form.component.html',
    },
];

describe.each(HEROES)('the $name hero owns the fields of the section it claims', ({ panel, sectionKey, hero, generated }) => {
    const heroHtml = ReadRepoFile(hero);

    it(`claims the generated ${sectionKey} section`, () => {
        expect(ClaimedSectionKey(panel)).toBe(sectionKey);
    });

    it('renders every field of that section as an input in edit mode', () => {
        const claimed = GeneratedSectionFields(ReadRepoFile(generated), sectionKey);
        expect(claimed.length).toBeGreaterThan(0);

        const rendered = FieldNames(EditBlock(heroHtml));
        const lost = claimed.filter((field) => !rendered.includes(field));
        expect(lost, 'claiming a generated section must not drop its fields').toEqual([]);
        expect(EditBlock(heroHtml)).toContain('[EditMode]="EditMode"');
    });

    it('keeps the inputs when the header is collapsed', () => {
        const editIndex = heroHtml.indexOf('<div class="biz-hero__edit">');
        expect(InsideCollapsedBlock(heroHtml, editIndex)).toBe(false);
    });
});
