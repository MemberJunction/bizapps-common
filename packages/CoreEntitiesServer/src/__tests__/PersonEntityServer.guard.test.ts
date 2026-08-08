import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, it, expect } from 'vitest';
import { PersonEntityServer } from '../PersonEntityServer.js';

/**
 * Regression guard for https://github.com/MemberJunction/bizapps-common/issues/36.
 *
 * Until v5.33.0, saving a Person with an email provisioned an active `MJ: Users`
 * record and granted it the `'UI'` role. That made every job applicant who
 * submitted an intake form an authenticated user with product read access.
 *
 * The fix removed the lifecycle hooks entirely rather than adding an opt-out, so
 * there is no longer any code here to unit-test behaviorally — the protection IS
 * the absence. These assertions exist to make that absence load-bearing: if
 * someone restores the provisioning, this file fails.
 *
 * Both checks are deliberate. The prototype check catches the exact shape the
 * defect had (a `Save`/`Delete` override); the source scan catches provisioning
 * reintroduced anywhere else in the class, including inside a helper the
 * override-shaped check would miss.
 */
describe('PersonEntityServer — no MJ User provisioning (issue #36)', () => {

    describe('declares no lifecycle override', () => {
        // The defect lived in Save() (mint on create/email-change) and Delete()
        // (deactivate the linked User). Own-property checks, not `in`/truthiness:
        // both methods exist on the inherited BaseEntity prototype chain and must
        // keep working — what must never come back is THIS class overriding them.
        it.each(['Save', 'Delete'])('does not override %s()', methodName => {
            const own = Object.getOwnPropertyDescriptor(PersonEntityServer.prototype, methodName);

            expect(
                own,
                `PersonEntityServer.prototype.${methodName} is defined again. Saving or ` +
                `deleting a Person must have no MJ User side effects — see issue #36.`
            ).toBeUndefined();
        });

        it('inherits Save/Delete from the entity base class', () => {
            // Postcondition on the check above: proves the assertions are meaningful
            // (the methods genuinely exist to be overridden) rather than passing
            // because the names were renamed out from under this test.
            expect(typeof PersonEntityServer.prototype.Save).toBe('function');
            expect(typeof PersonEntityServer.prototype.Delete).toBe('function');
        });
    });

    describe('contains no MJ User writes', () => {
        const SOURCE_PATH = resolve(dirname(fileURLToPath(import.meta.url)), '../PersonEntityServer.ts');

        /**
         * Strip comments before scanning. The class doc-comment describes the removed
         * behavior verbatim ("created (or linked) an active `MJ: Users` record") and
         * that history is worth keeping — but it would otherwise trip every pattern
         * below. Only executable code is scanned.
         */
        const strippedSource = (): string =>
            readFileSync(SOURCE_PATH, 'utf-8')
                .replace(/\/\*[\s\S]*?\*\//g, '')
                .replace(/\/\/.*$/gm, '');

        // Each entry is a distinct step of the original mint path, so a partial
        // restoration fails on the specific piece that came back.
        const FORBIDDEN: ReadonlyArray<{ pattern: RegExp; why: string }> = [
            { pattern: /['"`]MJ: Users['"`]/, why: 'creating or loading an MJ User record' },
            { pattern: /['"`]MJ: User Roles['"`]/, why: 'granting a UserRole' },
            { pattern: /MJUserEntity/, why: 'the MJ User entity type' },
            { pattern: /MJUserRoleEntity/, why: 'the MJ UserRole entity type' },
            { pattern: /['"`]UI['"`]/, why: "the 'UI' role that grants product read access" },
            { pattern: /LinkedUserID/, why: 'the deprecated Person-to-User binding' },
        ];

        it.each(FORBIDDEN)('does not reference $why', ({ pattern, why }) => {
            expect(
                strippedSource(),
                `PersonEntityServer references ${why}. A generic CRM layer must not bind ` +
                `people to platform accounts — that binding belongs to the platform layer's ` +
                `own IS-A subtype (see issue #36).`
            ).not.toMatch(pattern);
        });

        it('scans source that actually exists', () => {
            // Guards the guard: a moved or renamed file would otherwise make every
            // assertion above pass against an empty string.
            expect(strippedSource()).toMatch(/class PersonEntityServer/);
        });
    });
});
