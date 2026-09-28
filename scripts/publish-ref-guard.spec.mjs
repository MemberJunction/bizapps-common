/**
 * publish.yml may be dispatched from any ref, and its header promises that a dispatch off `main`
 * "publishes nothing". Publish and Tag were gated on `github.ref`, but the back-merge block was not:
 * dispatched from `release/v9.9.9` while a back-merge was outstanding, it pushed
 * `chore/backmerge-v9.9.9` and opened a PR saying "v9.9.9 published successfully … on npm … tagged"
 * — about a version nothing had published. Every step that writes to the remote, and the step that
 * opens the back-merge path, must carry the same guard.
 *
 * Plain Node, stdlib only: steps are read as text (`- name:` blocks and their `if:` line).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const MAIN_ONLY = "github.ref == 'refs/heads/main'";

/** `{ name: if-expression-or-null }` for every step in publish.yml. */
function stepConditions() {
    const text = readFileSync(join(REPO_ROOT, '.github', 'workflows', 'publish.yml'), 'utf8');
    const conditions = {};
    for (const block of text.split(/\n(?= {6}- )/).slice(1)) {
        const name = /^ {6}- name: (.+)$/m.exec(block)?.[1];
        if (name) conditions[name.trim()] = /^ {8}if: (.+)$/m.exec(block)?.[1] ?? null;
    }
    assert.ok(Object.keys(conditions).length > 10, 'read too few steps — the reader no longer matches publish.yml');
    return conditions;
}

for (const step of ['Publish to npm', 'Tag the release', 'Is there anything to back-merge?']) {
    test(`"${step}" runs only for refs/heads/main`, () => {
        const condition = stepConditions()[step];
        assert.ok(condition !== undefined, `publish.yml has no step named "${step}"`);
        assert.ok(condition?.includes(MAIN_ONLY), `"${step}" if: ${condition}`);
    });
}
