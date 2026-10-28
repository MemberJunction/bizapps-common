/**
 * The Add form's target person and organization use the fast party picker, not the stock FK field,
 * which lists rows on focus and scans `LIKE '%q%'` over the whole party file (golive #372).
 */
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';

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

    it('leaves no stock mj-form-field on the target fields', () => {
        expect(html).not.toMatch(/<mj-form-field[^>]*FieldName="To(Person|Organization)ID"/s);
    });

    it('imports PartyFieldComponent into the standalone component', () => {
        expect(ts).toMatch(/imports:\s*\[[^\]]*PartyFieldComponent[^\]]*\]/);
    });
});
