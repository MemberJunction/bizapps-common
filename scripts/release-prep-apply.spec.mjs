/**
 * `release-prep.mjs --apply`, the local half of cutting a release, with the commands it runs
 * recorded instead of executed.
 *
 * Every other release-prep spec covers the decision; nothing covered the mutation, so deleting the
 * relock (`pnpm install --lockfile-only`) left all of them green — and a release commit without it
 * breaks `pnpm install --frozen-lockfile` on the release branch, because the bumped internal pins are
 * not in the lockfile. The runner is the one seam: a stub that records each command and, for
 * `pnpm run version`, performs the bump on a fixture checkout, so the real postconditions run on real
 * files.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, copyFileSync, rmSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { applyRelease } from './release-prep.mjs';

const SCRIPTS = dirname(fileURLToPath(import.meta.url));

/** A checkout at 5.46.3 with one pending changeset; returns its root. */
function checkout() {
    const root = mkdtempSync(join(tmpdir(), 'release-apply-'));
    const pkg = (dir, name, extra = {}) => {
        mkdirSync(join(root, 'packages', dir), { recursive: true });
        writeFileSync(join(root, 'packages', dir, 'package.json'), JSON.stringify({ name, version: '5.46.3', ...extra }, null, 2));
    };
    pkg('Entities', '@mj-biz-apps/common-entities', { peerDependencies: { '@memberjunction/core': '^6.1.0-edge.6' } });
    pkg('Server', '@mj-biz-apps/common-server');
    mkdirSync(join(root, '.changeset'));
    writeFileSync(join(root, '.changeset', 'brave-fox.md'), '---\n"@mj-biz-apps/common-entities": minor\n---\nfeature\n');
    writeFileSync(join(root, '.changeset', 'README.md'), '# changesets\n');
    writeFileSync(join(root, 'mj-app.json'), JSON.stringify({ version: '5.46.3', mjVersionRange: '>=6.1.0-edge.6 <7.0.0' }, null, 2) + '\n');
    mkdirSync(join(root, 'scripts'));
    copyFileSync(join(SCRIPTS, 'sync-app-version.mjs'), join(root, 'scripts', 'sync-app-version.mjs'));
    return root;
}

/** A runner that records commands; `pnpm run version` bumps every package to `to`. */
function recordingRunner(to = '5.47.0') {
    const calls = [];
    const run = (root, command, args) => {
        calls.push([command, ...args].join(' '));
        if (command === 'pnpm' && args.join(' ') === 'run version') {
            for (const dir of ['Entities', 'Server']) {
                const path = join(root, 'packages', dir, 'package.json');
                writeFileSync(path, JSON.stringify({ ...JSON.parse(readFileSync(path, 'utf8')), version: to }, null, 2));
            }
            rmSync(join(root, '.changeset', 'brave-fox.md'));
            const app = JSON.parse(readFileSync(join(root, 'mj-app.json'), 'utf8'));
            writeFileSync(join(root, 'mj-app.json'), JSON.stringify({ ...app, version: to }, null, 2) + '\n');
        }
    };
    return { run, calls };
}

test('apply bumps, relocks, then commits — the relock is in the release commit', () => {
    const root = checkout();
    try {
        const { run, calls } = recordingRunner();
        applyRelease(root, { version: '5.47.0' }, run);
        assert.deepEqual(calls, ['pnpm run version', 'pnpm install --lockfile-only', 'git add -A', 'git commit -m Release v5.47.0']);
    } finally {
        rmSync(root, { recursive: true, force: true });
    }
});

test('a bump that misses the prediction throws before anything is committed', () => {
    const root = checkout();
    try {
        const { run, calls } = recordingRunner('5.46.4');
        assert.throws(() => applyRelease(root, { version: '5.47.0' }, run), /changeset version produced 5\.46\.4, but this run predicted 5\.47\.0/);
        assert.ok(!calls.some((c) => c.startsWith('git ')), `committed anyway: ${calls.join(' | ')}`);
    } finally {
        rmSync(root, { recursive: true, force: true });
    }
});
