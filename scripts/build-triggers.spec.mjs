/**
 * build.yml must always REPORT, so either of its jobs can be a required check on `next`.
 *
 * A workflow skipped by `on: paths:` creates no check run at all, and a required check that never
 * reports blocks the pull request forever — so a path filter on `on:` makes `build-only` and
 * `release-tooling` impossible to require. (Merged PRs here that touched only `tsconfig.angular.json`
 * or `README.md` show no build-only check run.) bizapps-forms hit this first and moved the path list
 * into an always-reporting `scope` job; this pins the same shape:
 *
 *   - `on:` carries no `paths:` for push or pull_request;
 *   - `release-tooling` (stdlib only, seconds) runs on every event: no `needs`, no `if:`;
 *   - `build-only` depends on `scope`, and runs unless scope says, with certainty, that nothing it
 *     reads changed. A job skipped by `if:` reports `skipped`, which a required check counts as
 *     passing — so the list scope decides over is pinned below, entry by entry, with the reason each
 *     entry is a build-only input. Shortening it fails here instead of quietly skipping a build.
 *
 * Plain Node, stdlib only: the workflow is read as text.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { pathsTouched } from './check-paths-touched.mjs';

const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const BUILD_YML = readFileSync(join(REPO_ROOT, '.github', 'workflows', 'build.yml'), 'utf8');

/** The text of one top-level `on:` event, or of one job, up to the next sibling key. */
function block(indent, key) {
    const lines = BUILD_YML.split('\n');
    const at = lines.findIndex((line) => line === `${' '.repeat(indent)}${key}:`);
    assert.ok(at >= 0, `build.yml has no ${key}: at indent ${indent}`);
    const out = [];
    for (const line of lines.slice(at + 1)) {
        if (line.trim() !== '' && !line.trim().startsWith('#') && line.search(/\S/) <= indent) break;
        out.push(line);
    }
    return out.join('\n');
}

/** The patterns build.yml passes to check-paths-touched.mjs, read from the workflow itself. */
function scopeList() {
    const start = BUILD_YML.indexOf('check-paths-touched.mjs "$BASE_SHA" "$HEAD_SHA"');
    assert.notEqual(start, -1, 'build.yml no longer invokes check-paths-touched.mjs as expected');
    const end = BUILD_YML.indexOf(')', start);
    return BUILD_YML.slice(BUILD_YML.indexOf('\\', start) + 1, end)
        .split('\n')
        .map((line) => line.replace(/\\\s*$/, '').trim())
        .filter(Boolean);
}

test('on: has no paths filter, so the workflow always creates its checks', () => {
    for (const event of ['push', 'pull_request']) {
        assert.doesNotMatch(block(2, event), /^\s+paths:/m, `on.${event} carries a paths: filter`);
    }
});

test('release-tooling runs on every event — it checks inputs spread across the whole tree', () => {
    const job = block(2, 'release-tooling');
    assert.doesNotMatch(job, /^ {4}needs:/m, 'release-tooling must not wait on scope');
    assert.doesNotMatch(job, /^ {4}if:/m, 'release-tooling must not be skippable');
});

test('build-only waits on scope and builds whenever scope could not say no', () => {
    const job = block(2, 'build-only');
    assert.match(job, /^ {4}needs: scope$/m);
    const condition = /^ {4}if: (.+)$/m.exec(job)?.[1] ?? '';
    // Fail open one level up: a job `if:` is ANDed with success() of its needs, so without this half
    // a failing scope job (a broken decider) would skip the build and report it as passing.
    assert.match(condition, /needs\.scope\.result != 'success'/, condition);
    assert.match(condition, /needs\.scope\.outputs\.relevant == 'true'/, condition);
    assert.match(condition, /!cancelled\(\)/, condition);
});

test('scope runs the decider self-test before trusting it', () => {
    assert.match(block(2, 'scope'), /run: node --test scripts\/check-paths-touched\.spec\.mjs/);
});

// Every entry, with why build-only reads it. A new build-only input goes here AND in build.yml.
const EXPECTED_SCOPE = {
    'pnpm-lock.yaml': 'the resolved dependency graph pnpm install --frozen-lockfile installs',
    'pnpm-workspace.yaml': 'workspace members and linkWorkspacePackages',
    '.npmrc': 'auto-install-peers and strict-peer-dependencies decide what installs at all',
    'turbo.json': 'the build task graph and its cache keys',
    'package.json': 'the root scripts build-only runs (build:packages, test:mutants:anchors)',
    'tsconfig.angular.json': 'extends target of packages/Angular',
    'tsconfig.server.json': 'extends target of every other package',
    'packages/': 'the product code, its tests and the mutation-anchor harnesses',
    'migrations/': 'business-time-zone-migration.test.ts reads these files under pnpm -r test',
    'migrations-pg/': 'the same test reads the PostgreSQL twins',
    'metadata/': 'sync-trigger-metadata, log-activity-durable-bindings and person-lifecycle-agent-binding tests read metadata/*.json',
    '.github/scripts/': 'validate-package-repository.sh and the package-lock case test run in build-only',
    '.github/workflows/build.yml': 'a change to this workflow must run it',
};

test('build.yml scope list is exactly the pinned build-only inputs', () => {
    assert.deepEqual([...scopeList()].sort(), Object.keys(EXPECTED_SCOPE).sort(),
        "build.yml's scope list and this spec have diverged — add the entry here with its reason, or explain the removal.");
});

for (const [file, why] of Object.entries({
    'tsconfig.angular.json': 'root build input (merged PR #177 touched only this and got no build)',
    'turbo.json': 'root build input',
    'pnpm-workspace.yaml': 'root build input',
    'migrations/V299901010000__v9.9.x__Anything.sql': 'read by a package test',
    '.github/workflows/build.yml': 'the workflow itself',
    'metadata/actions/.common-actions.json': 'read by package tests; the old on: paths: filter skipped them for a metadata-only PR',
})) {
    test(`build-only runs when only ${file} changes (${why})`, () => {
        assert.equal(pathsTouched({ changed: [file], patterns: scopeList() }), true);
    });
}

test('documentation-only changes still skip the build (and report skipped, which passes)', () => {
    for (const doc of ['README.md', 'CLAUDE.md', 'docs/release.md', 'mj-app.json']) {
        assert.equal(pathsTouched({ changed: [doc], patterns: scopeList() }), false, `${doc} should not force a build`);
    }
});

// A release PR and a hotfix PR target `main`. Without `main` here they ran no build and no
// release-tooling before merging, so a broken build first showed up in publish.yml, after the merge.
test('pull requests into main run build.yml too', () => {
    assert.match(block(2, 'pull_request'), /^ {4}branches: \[next, main\]$/m);
});
