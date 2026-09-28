/**
 * Ported from bizapps-forms (MemberJunction/bizapps-forms#177), schema and package names adjusted
 * for bizapps-common.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, copyFileSync, rmSync, realpathSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { deriveAppFields, syncAppVersion } from './sync-app-version.mjs';

const REPO_ROOT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');

test('the app version is the entities package version', () => {
    const { version } = deriveAppFields({ version: '0.11.0', dependencies: { '@memberjunction/core': '6.1.0-edge.5' } });
    assert.equal(version, '0.11.0');
});

// The range is ">= the pinned MJ version, < the next MJ major" — the pinning model in CLAUDE.md.
test('the MJ range spans from the pin to the next MJ major', () => {
    const { mjVersionRange } = deriveAppFields({ version: '0.11.0', dependencies: { '@memberjunction/core': '6.1.0-edge.5' } });
    assert.equal(mjVersionRange, '>=6.1.0-edge.5 <7.0.0');
});

test('a caret peer dependency is read when there is no direct dependency', () => {
    const { mjVersionRange } = deriveAppFields({ version: '1.0.0', peerDependencies: { '@memberjunction/core': '^6.1.0' } });
    assert.equal(mjVersionRange, '>=6.1.0 <7.0.0');
});

// Guard clause, not a silent skip: an entities package with no MJ dependency at all means the
// derivation has lost its input, and writing a stale range would be worse than stopping.
test('an entities package with no MJ dependency throws', () => {
    assert.throws(() => deriveAppFields({ version: '1.0.0' }), /@memberjunction\/core/);
});

test('a package with no version throws', () => {
    assert.throws(() => deriveAppFields({ dependencies: { '@memberjunction/core': '6.1.0' } }), /version/);
});

function scratchRepo({ entitiesVersion, mjPin, app }) {
    const root = mkdtempSync(path.join(tmpdir(), 'sync-app-version-'));
    mkdirSync(path.join(root, 'packages', 'Entities'), { recursive: true });
    writeFileSync(
        path.join(root, 'packages', 'Entities', 'package.json'),
        JSON.stringify({ version: entitiesVersion, dependencies: { '@memberjunction/core': mjPin } }, null, 2),
    );
    writeFileSync(path.join(root, 'mj-app.json'), JSON.stringify(app, null, 2) + '\n');
    return root;
}

test('check reports a stale app version', () => {
    const root = scratchRepo({
        entitiesVersion: '0.11.0',
        mjPin: '6.1.0-edge.5',
        app: { version: '0.10.0', mjVersionRange: '>=6.1.0-edge.5 <7.0.0' },
    });
    const mismatches = syncAppVersion({ root, check: true });
    assert.equal(mismatches.length, 1);
    assert.match(mismatches[0], /version/);
});

test('check reports a stale MJ range', () => {
    const root = scratchRepo({
        entitiesVersion: '0.11.0',
        mjPin: '6.1.0-edge.5',
        app: { version: '0.11.0', mjVersionRange: '>=5.0.0 <6.0.0' },
    });
    assert.equal(syncAppVersion({ root, check: true }).length, 1);
});

// The half that matters most: `--check` must not quietly repair what it was asked to inspect.
test('check never writes', () => {
    const root = scratchRepo({
        entitiesVersion: '0.11.0',
        mjPin: '6.1.0-edge.5',
        app: { version: '0.10.0', mjVersionRange: '>=5.0.0 <6.0.0' },
    });
    const before = readFileSync(path.join(root, 'mj-app.json'), 'utf8');
    syncAppVersion({ root, check: true });
    assert.equal(readFileSync(path.join(root, 'mj-app.json'), 'utf8'), before);
});

test('check passes on a synced tree', () => {
    const root = scratchRepo({
        entitiesVersion: '0.11.0',
        mjPin: '6.1.0-edge.5',
        app: { version: '0.11.0', mjVersionRange: '>=6.1.0-edge.5 <7.0.0' },
    });
    assert.deepEqual(syncAppVersion({ root, check: true }), []);
});

test('writing makes a stale tree pass its own check, and preserves other keys', () => {
    const root = scratchRepo({
        entitiesVersion: '0.11.0',
        mjPin: '6.1.0-edge.5',
        app: { name: 'bizapps-common', version: '0.10.0', mjVersionRange: '>=5.0.0 <6.0.0', dependencies: ['other-app'] },
    });
    assert.deepEqual(syncAppVersion({ root, check: false }), []);
    assert.deepEqual(syncAppVersion({ root, check: true }), []);
    const written = JSON.parse(readFileSync(path.join(root, 'mj-app.json'), 'utf8'));
    assert.equal(written.name, 'bizapps-common');
    assert.deepEqual(written.dependencies, ['other-app']);
});

// The repository itself must be synced, or the release PR ships an mj-app.json that disagrees
// with the packages it installs.
test('this repository is in sync', () => {
    const mismatches = syncAppVersion({ root: REPO_ROOT, check: true });
    assert.deepEqual(mismatches, [], mismatches.join('\n'));
});

// ── CLI argument validation ─────────────────────────────────────────────────────────────────────
//
// A copy of the script in its own fixture, so the CLI's own REPO_ROOT (derived from
// import.meta.url, not cwd) points at a throwaway tree rather than this repository's real
// mj-app.json. Only `[]` and `['--check']` are valid; everything else — a typo, `--help`, an extra
// flag — must refuse rather than falling through to write mode, which is what main()'s own
// `process.argv.includes('--check')` did.
function cliFixture({ entitiesVersion, mjPin, app }) {
    // realpath'd: macOS's own /tmp -> /private/tmp (and /var -> /private/var, which os.tmpdir()
    // resolves under) is exactly the class of symlinked path release-5 exists for. Resolving it here
    // keeps THIS test about argv validation rather than accidentally depending on that fix too.
    const root = realpathSync(mkdtempSync(path.join(tmpdir(), 'sync-app-version-cli-')));
    mkdirSync(path.join(root, 'scripts'), { recursive: true });
    mkdirSync(path.join(root, 'packages', 'Entities'), { recursive: true });
    copyFileSync(
        path.join(REPO_ROOT, 'scripts', 'sync-app-version.mjs'),
        path.join(root, 'scripts', 'sync-app-version.mjs'),
    );
    writeFileSync(
        path.join(root, 'packages', 'Entities', 'package.json'),
        JSON.stringify({ version: entitiesVersion, dependencies: { '@memberjunction/core': mjPin } }, null, 2),
    );
    writeFileSync(path.join(root, 'mj-app.json'), JSON.stringify(app, null, 2) + '\n');
    return root;
}

function runCli(root, args) {
    return spawnSync(process.execPath, [path.join(root, 'scripts', 'sync-app-version.mjs'), ...args], {
        encoding: 'utf8',
    });
}

// A typo'd flag is not `--check` — main()'s `.includes('--check')` read it as false, the WRITE-mode
// branch, and silently overwrote mj-app.json. The production change that makes this fail: replacing
// `parseArgs`'s validation back with `process.argv.includes('--check')`.
test('an unrecognised flag is rejected rather than silently running write mode', () => {
    const fixture = cliFixture({
        entitiesVersion: '0.11.0',
        mjPin: '6.1.0-edge.5',
        app: { version: '0.10.0', mjVersionRange: '>=5.0.0 <6.0.0' },
    });
    try {
        const before = readFileSync(path.join(fixture, 'mj-app.json'), 'utf8');
        const result = runCli(fixture, ['--chekc']);
        assert.equal(result.status, 2, `expected exit 2, got ${result.status}\n${result.stderr}`);
        assert.match(result.stderr, /usage/i);
        assert.equal(readFileSync(path.join(fixture, 'mj-app.json'), 'utf8'), before, 'must not write on a rejected arg set');
    } finally {
        rmSync(fixture, { recursive: true, force: true });
    }
});

// A second, unrelated arg alongside the real one — `--check` is still present, but the set is not
// EXACTLY `['--check']`, and the brief is explicit that only that exact set (or []) is valid.
test('--check plus an extra argument is rejected, not treated as --check', () => {
    const fixture = cliFixture({
        entitiesVersion: '0.11.0',
        mjPin: '6.1.0-edge.5',
        app: { version: '0.10.0', mjVersionRange: '>=5.0.0 <6.0.0' },
    });
    try {
        const before = readFileSync(path.join(fixture, 'mj-app.json'), 'utf8');
        const result = runCli(fixture, ['--check', '--verbose']);
        assert.equal(result.status, 2, `expected exit 2, got ${result.status}\n${result.stderr}`);
        assert.equal(readFileSync(path.join(fixture, 'mj-app.json'), 'utf8'), before);
    } finally {
        rmSync(fixture, { recursive: true, force: true });
    }
});

// `--help` must not print the WRITE-mode success message, which is what main()'s
// `process.argv.includes('--check')` did on the real repo (confirmed live in the smoke hunt).
test('--help is rejected rather than falling through to write mode', () => {
    const fixture = cliFixture({
        entitiesVersion: '0.11.0',
        mjPin: '6.1.0-edge.5',
        app: { version: '0.11.0', mjVersionRange: '>=6.1.0-edge.5 <7.0.0' },
    });
    try {
        const result = runCli(fixture, ['--help']);
        assert.equal(result.status, 2);
        assert.doesNotMatch(result.stdout, /synced/);
    } finally {
        rmSync(fixture, { recursive: true, force: true });
    }
});

test('the exact valid argument sets still work: [] writes, [\'--check\'] only checks', () => {
    const fixture = cliFixture({
        entitiesVersion: '0.11.0',
        mjPin: '6.1.0-edge.5',
        app: { version: '0.10.0', mjVersionRange: '>=5.0.0 <6.0.0' },
    });
    try {
        const checkResult = runCli(fixture, ['--check']);
        assert.equal(checkResult.status, 1, 'a stale tree fails --check');
        assert.equal(
            readFileSync(path.join(fixture, 'mj-app.json'), 'utf8'),
            JSON.stringify({ version: '0.10.0', mjVersionRange: '>=5.0.0 <6.0.0' }, null, 2) + '\n',
            '--check must not write',
        );

        const writeResult = runCli(fixture, []);
        assert.equal(writeResult.status, 0);
        const written = JSON.parse(readFileSync(path.join(fixture, 'mj-app.json'), 'utf8'));
        assert.equal(written.version, '0.11.0');
    } finally {
        rmSync(fixture, { recursive: true, force: true });
    }
});
