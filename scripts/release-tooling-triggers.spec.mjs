/**
 * build.yml's `paths:` filter decides whether the `release-tooling` job runs at all, so every file
 * that job CHECKS must be in it — not only the directories its scripts live in. A PR that touches
 * nothing in the list starts no build.yml run and creates no check: the gate is simply absent.
 *
 * Two inputs were missing when the job was added: `ci/` (a directory check-release-pushes.mjs keeps
 * scanning as a tripwire for the push scripts it replaced) and `mj-app.json` (what the
 * sync-app-version spec checks on "every PR"). A PR re-adding `ci/commit_push.mjs`, or hand-editing
 * `mj-app.json`, ran nothing.
 *
 * Plain Node, stdlib only: the filter is read as text, the way GitHub reads it — one `- '<glob>'`
 * item per line under `paths:`.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { SCANNED_DIRS } from './check-release-pushes.mjs';

const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

/** The `paths:` globs under `on.<event>` in build.yml. */
function triggerPaths(event) {
    const lines = readFileSync(join(REPO_ROOT, '.github', 'workflows', 'build.yml'), 'utf8').split('\n');
    const at = lines.findIndex((line) => line === `  ${event}:`);
    assert.ok(at >= 0, `build.yml has no on.${event}`);
    const globs = [];
    let inPaths = false;
    for (const line of lines.slice(at + 1)) {
        if (/^ {0,2}\S/.test(line)) break; // the next event, or the end of `on:`
        if (/^ {4}paths:\s*$/.test(line)) { inPaths = true; continue; }
        if (/^ {4}\S/.test(line)) { inPaths = false; continue; }
        const item = /^ {6}- '([^']+)'/.exec(line);
        if (inPaths && item) globs.push(item[1]);
    }
    assert.ok(globs.length > 0, `found no paths under on.${event} — the reader no longer matches build.yml`);
    return globs;
}

/** GitHub's `dir/**` and exact-file forms — the only two this filter uses. */
function covers(glob, file) {
    return glob.endsWith('/**') ? file.startsWith(glob.slice(0, -2)) : glob === file;
}

/** One representative file per input the release-tooling job checks. */
const CHECKED_INPUTS = [
    ...SCANNED_DIRS.map((dir) => `${dir}/any.mjs`),
    'mj-app.json',
    'packages/Entities/package.json',
    'test-harnesses/integration.spec.mjs',
];

for (const event of ['pull_request', 'push']) {
    test(`build.yml on.${event} paths cover every input release-tooling checks`, () => {
        const globs = triggerPaths(event);
        const uncovered = CHECKED_INPUTS.filter((file) => !globs.some((glob) => covers(glob, file)));
        assert.deepEqual(uncovered, [], `a change to these runs no release-tooling job on ${event}`);
    });
}
