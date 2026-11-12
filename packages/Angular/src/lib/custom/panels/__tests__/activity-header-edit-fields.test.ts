import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

/**
 * ActivityHeaderPanel replaces the generated `activityDetails` section, so a field that section
 * carries is editable only if the hero (or another contributed panel) edits it. This test re-checks
 * that claim against the generated form every run: when CodeGen adds a field to Activity Details,
 * it fails until the hero carries that field too (bc-aidp-next-golive#430).
 */
const here = dirname(fileURLToPath(import.meta.url));
const lib = resolve(here, '../../..');

function read(relativeToLib: string): string {
    return readFileSync(resolve(lib, relativeToLib), 'utf8');
}

/** The FieldName of every mj-form-field inside the named collapsible section of a generated form. */
function sectionFieldNames(formHtml: string, sectionKey: string): string[] {
    const start = formHtml.indexOf(`SectionKey="${sectionKey}"`);
    expect(start, `section ${sectionKey} exists in the generated form`).toBeGreaterThan(-1);
    const end = formHtml.indexOf('</mj-collapsible-panel>', start);
    return fieldNames(formHtml.slice(start, end));
}

function fieldNames(html: string): string[] {
    return [...html.matchAll(/FieldName="([A-Za-z0-9_]+)"/g)].map((m) => m[1]);
}

describe('ActivityHeaderPanel edit mode', () => {
    const generated = read('generated/Entities/mjBizAppsCommonActivity/mjbizappscommonactivity.form.component.html');
    const hero = read('components/identity-header/activity-identity.component.html');
    const notesPanel = read('custom/panels/activity-content.panel.ts');

    it('replaces the activityDetails section', () => {
        const panel = read('custom/panels/activity-header.panel.ts');
        expect(panel).toContain("replacesSectionKey: 'activityDetails'");
    });

    it('edits every field the replaced section carried, Description through the Notes panel', () => {
        const replaced = sectionFieldNames(generated, 'activityDetails');
        expect(replaced).toContain('ActivityTypeID');
        const heroFields = fieldNames(hero);
        for (const field of replaced) {
            if (field === 'Description') {
                expect(notesPanel).toContain('Record.Description = ');
            } else {
                expect(heroFields, `hero edits ${field}`).toContain(field);
            }
        }
    });

    it('offers the Activity Type as a record link so the FK search renders in edit mode', () => {
        const typeField = hero.match(/<mj-form-field[^>]*FieldName="ActivityTypeID"[^>]*>/s)?.[0] ?? '';
        expect(typeField).toContain('LinkType="Record"');
        expect(typeField).toContain('[EditMode]="EditMode"');
    });

    it('shows the edit fields whether or not the hero is collapsed', () => {
        const editStart = hero.indexOf('@if (EditMode)');
        const collapsedStart = hero.indexOf('@if (!Collapsed)');
        expect(editStart).toBeGreaterThan(-1);
        expect(collapsedStart).toBeGreaterThan(-1);
        // The collapsed block closes before the edit block opens.
        const collapsedEnd = closingBraceOf(hero, collapsedStart);
        expect(editStart).toBeGreaterThan(collapsedEnd);
    });
});

/** Index of the `}` that closes the `{` after the control-flow block starting at `start`. */
function closingBraceOf(html: string, start: number): number {
    let depth = 0;
    for (let i = html.indexOf('{', start); i < html.length; i++) {
        if (html[i] === '{') depth++;
        if (html[i] === '}' && --depth === 0) return i;
    }
    return -1;
}
