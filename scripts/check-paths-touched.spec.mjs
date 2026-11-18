/**
 * The decider build.yml's `scope` job asks before `build-only` runs. Ported unchanged in logic from
 * bizapps-forms (its origin/next scripts/check-paths-touched.spec.mjs); the half of that spec that pins
 * build.yml's own path list lives in build-triggers.spec.mjs here, beside the rest of build.yml's wiring.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { join, dirname } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { pathsTouched, resolveDecision } from './check-paths-touched.mjs';

const ZERO = '0'.repeat(40);

test('a trailing slash matches by prefix', () => {
    assert.equal(pathsTouched({ changed: ['packages/Angular/src/a.ts'], patterns: ['packages/'] }), true);
});

test('a prefix pattern does not match a sibling with the same first letters', () => {
    assert.equal(pathsTouched({ changed: ['packages-old/a.ts'], patterns: ['packages/'] }), false);
});

test('a pattern without a trailing slash must match exactly', () => {
    assert.equal(pathsTouched({ changed: ['turbo.json'], patterns: ['turbo.json'] }), true);
    assert.equal(pathsTouched({ changed: ['a/turbo.json'], patterns: ['turbo.json'] }), false);
});

test('an exact pattern does not match a path that merely starts with it', () => {
    assert.equal(pathsTouched({ changed: ['package.json.bak'], patterns: ['package.json'] }), false);
});

test('any one matching path is enough', () => {
    assert.equal(pathsTouched({ changed: ['README.md', 'apps/MJAPI/x.mjs'], patterns: ['packages/', 'apps/'] }), true);
});

test('no changed paths means nothing was touched', () => {
    assert.equal(pathsTouched({ changed: [], patterns: ['packages/'] }), false);
});

// The asymmetry that matters: a wrong "false" skips the job, and a skipped job reports SUCCESS.
test('an unreadable diff fails open', () => {
    assert.equal(resolveDecision({ baseSha: 'a1', headSha: 'b2', changedOrNull: null, patterns: ['packages/'] }), true);
});

test('an all-zeroes base sha fails open', () => {
    assert.equal(resolveDecision({ baseSha: ZERO, headSha: 'b2', changedOrNull: [], patterns: ['packages/'] }), true);
});

test('a missing base sha fails open', () => {
    assert.equal(resolveDecision({ baseSha: '', headSha: 'b2', changedOrNull: [], patterns: ['packages/'] }), true);
});

test('a missing head sha fails open', () => {
    assert.equal(resolveDecision({ baseSha: 'a1', headSha: '', changedOrNull: [], patterns: ['packages/'] }), true);
});

test('an all-zeroes head sha fails open', () => {
    assert.equal(resolveDecision({ baseSha: 'a1', headSha: ZERO, changedOrNull: [], patterns: ['packages/'] }), true);
});

test('a readable diff that misses every pattern is the one case that returns false', () => {
    assert.equal(resolveDecision({ baseSha: 'a1', headSha: 'b2', changedOrNull: ['README.md'], patterns: ['packages/'] }), false);
});

test('a readable diff that hits a pattern returns true', () => {
    assert.equal(resolveDecision({ baseSha: 'a1', headSha: 'b2', changedOrNull: ['packages/x.ts'], patterns: ['packages/'] }), true);
});

test('no patterns at all fails open rather than skipping everything', () => {
    assert.equal(resolveDecision({ baseSha: 'a1', headSha: 'b2', changedOrNull: ['README.md'], patterns: [] }), true);
});


// The CLI is what build.yml runs: `node scripts/check-paths-touched.mjs <base> <head> <patterns…>`
// prints `true` or `false`. Pinned end to end, in a real git repository, because the pure functions
// above cannot tell whether the entry point runs at all — an entry guard that never fires prints
// nothing, and the workflow would read an empty answer.
test('the CLI prints the decision for a real diff', () => {
    const script = join(dirname(fileURLToPath(import.meta.url)), 'check-paths-touched.mjs');
    const root = mkdtempSync(join(tmpdir(), 'paths-touched-'));
    try {
        const git = (...a) => execFileSync('git', ['-c', 'user.email=t@t', '-c', 'user.name=t', ...a], { cwd: root, encoding: 'utf8' }).trim();
        git('init', '-q');
        writeFileSync(join(root, 'README.md'), 'a\n'); git('add', '-A'); git('commit', '-qm', 'base');
        const base = git('rev-parse', 'HEAD');
        writeFileSync(join(root, 'README.md'), 'b\n'); git('add', '-A'); git('commit', '-qm', 'docs');
        const head = git('rev-parse', 'HEAD');
        const run = (...patterns) => execFileSync(process.execPath, [script, base, head, ...patterns], { cwd: root, encoding: 'utf8' });
        assert.equal(run('packages/', 'turbo.json'), 'false');
        assert.equal(run('README.md'), 'true');
    } finally {
        rmSync(root, { recursive: true, force: true });
    }
});
