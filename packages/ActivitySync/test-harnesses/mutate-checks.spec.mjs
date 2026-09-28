import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { cpSync, existsSync, mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const HARNESS = path.join(HERE, 'mutate-checks.mjs');
const PKG_ROOT = path.join(HERE, '..');

// ── pkg-1: an unrecognized ID or flag must fail loudly, not report a vacuous pass ──────────────
//
// Fails until mutate-checks.mjs validates `wanted` against PRODUCT's known ids instead of
// silently filtering `selected` down to zero entries and printing "0 mutant(s) proved their
// checks can fail." with exit 0. Arg validation happens before any mutation, so these never touch
// vitest or the real source tree.

test('an unrecognized mutant ID fails non-zero and names it', () => {
    const result = spawnSync(process.execPath, [HARNESS, 'BOGUS-ID-TYPO'], { encoding: 'utf8' });
    assert.notEqual(result.status, 0, `expected non-zero exit; got ${result.status}. stdout: ${result.stdout}`);
    assert.match(result.stderr, /BOGUS-ID-TYPO/);
});

test('an unrecognized flag fails non-zero and names it', () => {
    const result = spawnSync(process.execPath, [HARNESS, '--help'], { encoding: 'utf8' });
    assert.notEqual(result.status, 0, `expected non-zero exit; got ${result.status}. stdout: ${result.stdout}`);
    assert.match(result.stderr, /--help/);
});

test('zero selected mutants never exits 0 -- a fully bogus arg list must fail', () => {
    const result = spawnSync(process.execPath, [HARNESS, 'BOGUS-1', 'BOGUS-2'], { encoding: 'utf8' });
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /BOGUS-1/);
    assert.match(result.stderr, /BOGUS-2/);
});

test('a real mutant ID mixed with a bogus one is still rejected and names only the bogus one', () => {
    const result = spawnSync(process.execPath, [HARNESS, 'M-AC11', 'BOGUS-ID-TYPO'], { encoding: 'utf8' });
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /BOGUS-ID-TYPO/);
    assert.doesNotMatch(result.stderr, /^M-AC11 /m);
});

test('--list and --check-anchors are unaffected by the new validation', () => {
    const list = spawnSync(process.execPath, [HARNESS, '--list'], { encoding: 'utf8' });
    assert.equal(list.status, 0, list.stderr);
    assert.match(list.stdout, /M-AC11/);

    const anchors = spawnSync(process.execPath, [HARNESS, '--check-anchors'], { encoding: 'utf8' });
    assert.equal(anchors.status, 0, anchors.stderr);
});

// ── pkg-2: a SIGINT/SIGTERM mid-run must restore the mutated file before the process dies ──────
//
// Runs entirely against a temp COPY of the package (src/ + test-harnesses/ only -- no
// node_modules, no dist), so it never touches this worktree's real source and never needs
// vitest. MUTATE_CHECKS_TEST_COMMAND is the seam: it swaps the real `pnpm exec vitest run` for a
// plain `node` sleep long enough to reliably land a signal mid-mutation.
//
// Fails until mutate-checks.mjs (a) runs the suite as an interruptible child process instead of
// execSync's blocking wait, which starves the event loop so a SIGINT/SIGTERM handler can't run
// until the child exits on its own, and (b) registers SIGINT/SIGTERM handlers that restore the
// mutated file (and forward/kill the child) before exiting.

function makeTempPackageCopy() {
    const root = mkdtempSync(path.join(tmpdir(), 'mutate-checks-activitysync-'));
    cpSync(path.join(PKG_ROOT, 'src'), path.join(root, 'src'), { recursive: true });
    cpSync(path.join(PKG_ROOT, 'test-harnesses'), path.join(root, 'test-harnesses'), { recursive: true });
    return root;
}

function makeSleepCommand(root) {
    const sleepScript = path.join(root, 'sleep.mjs');
    writeFileSync(sleepScript, 'await new Promise((resolve) => setTimeout(resolve, 10000));\n');
    return `${process.execPath} ${JSON.stringify(sleepScript)}`;
}

async function waitForFileToChange(filePath, original, timeoutMs) {
    const deadline = Date.now() + timeoutMs;
    while (Date.now() < deadline) {
        if (readFileSync(filePath, 'utf8') !== original) return true;
        await new Promise((resolve) => setTimeout(resolve, 10));
    }
    return false;
}

async function waitForExit(child, timeoutMs) {
    return Promise.race([
        new Promise((resolve) => child.once('exit', (code, signal) => resolve({ code, signal }))),
        new Promise((_, reject) => setTimeout(() => reject(new Error('harness did not exit in time')), timeoutMs)),
    ]);
}

test('SIGINT mid-run restores the mutated file before the harness exits', async () => {
    const root = makeTempPackageCopy();
    try {
        const target = path.join(root, 'src/writer.ts');
        const original = readFileSync(target, 'utf8');

        const child = spawn(process.execPath, [path.join(root, 'test-harnesses/mutate-checks.mjs'), 'M-AC18'], {
            env: { ...process.env, MUTATE_CHECKS_TEST_COMMAND: makeSleepCommand(root) },
            stdio: ['ignore', 'pipe', 'pipe'],
        });

        const changed = await waitForFileToChange(target, original, 5000);
        assert.ok(changed, 'expected the harness to mutate the target file before the child was signaled');

        child.kill('SIGINT');
        const { code, signal } = await waitForExit(child, 5000);
        assert.ok(code === 130 || signal === 'SIGINT', `expected exit 130 or SIGINT; got code=${code} signal=${signal}`);

        const restored = readFileSync(target, 'utf8');
        assert.equal(restored, original, 'mutated source must be restored after SIGINT');
    } finally {
        rmSync(root, { recursive: true, force: true });
    }
});

test('SIGTERM mid-run restores the mutated file before the harness exits', async () => {
    const root = makeTempPackageCopy();
    try {
        const target = path.join(root, 'src/watermark.ts');
        const original = readFileSync(target, 'utf8');

        const child = spawn(process.execPath, [path.join(root, 'test-harnesses/mutate-checks.mjs'), 'M-AC19'], {
            env: { ...process.env, MUTATE_CHECKS_TEST_COMMAND: makeSleepCommand(root) },
            stdio: ['ignore', 'pipe', 'pipe'],
        });

        const changed = await waitForFileToChange(target, original, 5000);
        assert.ok(changed, 'expected the harness to mutate the target file before the child was signaled');

        child.kill('SIGTERM');
        const { code, signal } = await waitForExit(child, 5000);
        assert.ok(code === 143 || signal === 'SIGTERM', `expected exit 143 or SIGTERM; got code=${code} signal=${signal}`);

        const restored = readFileSync(target, 'utf8');
        assert.equal(restored, original, 'mutated source must be restored after SIGTERM');
    } finally {
        rmSync(root, { recursive: true, force: true });
    }
});

// ── round 2 (reviewer findings) ─────────────────────────────────────────────────────────────────

async function waitForFileToExist(filePath, timeoutMs) {
    const deadline = Date.now() + timeoutMs;
    while (Date.now() < deadline) {
        if (existsSync(filePath)) return true;
        await new Promise((resolve) => setTimeout(resolve, 10));
    }
    return false;
}

function isProcessAlive(pid) {
    try {
        process.kill(pid, 0);
        return true;
    } catch {
        return false;
    }
}

function listMutTempDirs(mutantId) {
    return new Set(readdirSync(tmpdir()).filter((name) => name.startsWith(`mut-${mutantId}-`)));
}

// A fixture "suite" that itself spawns a further child (mimicking `pnpm exec vitest run` spawning
// its own vitest process) and writes that grandchild's pid to a marker file, so the test can check
// whether the grandchild is still alive after the harness is signaled.
function makeGrandchildCommand(root) {
    const script = path.join(root, 'suite-with-grandchild.mjs');
    const marker = path.join(root, 'grandchild.pid');
    writeFileSync(
        script,
        [
            "import { spawn } from 'node:child_process';",
            "import { writeFileSync } from 'node:fs';",
            "const child = spawn(process.execPath, ['-e', 'setInterval(() => {}, 1000);'], { stdio: 'ignore' });",
            `writeFileSync(${JSON.stringify(marker)}, String(child.pid));`,
            'setInterval(() => {}, 1000);',
        ].join('\n'),
    );
    return { command: `${process.execPath} ${JSON.stringify(script)}`, marker };
}

// Fails until mutate-checks.mjs spawns the test command detached and kills its whole process group
// (`process.kill(-pid, signal)`) instead of `activeChild.kill(signal)`, which reaches only the
// direct child -- with `shell: true`, the child a real `pnpm exec vitest run` starts is an orphan
// a plain kill never touches. Also covers the sibling leak the reviewer named in the same finding:
// the harness's own mkdtemp backup dir for the in-flight mutant, which the signal path never
// removed.
test('SIGTERM kills the whole process group (no orphaned grandchild) and removes the temp dir', async () => {
    const root = makeTempPackageCopy();
    const mutantId = 'M-AC18';
    const before = listMutTempDirs(mutantId);
    let grandchildPid = null;
    try {
        const target = path.join(root, 'src/writer.ts');
        const original = readFileSync(target, 'utf8');
        const { command, marker } = makeGrandchildCommand(root);

        const child = spawn(process.execPath, [path.join(root, 'test-harnesses/mutate-checks.mjs'), mutantId], {
            env: { ...process.env, MUTATE_CHECKS_TEST_COMMAND: command },
            stdio: ['ignore', 'pipe', 'pipe'],
        });

        const changed = await waitForFileToChange(target, original, 5000);
        assert.ok(changed, 'expected the harness to mutate the target file before the child was signaled');

        const markerWritten = await waitForFileToExist(marker, 5000);
        assert.ok(markerWritten, 'expected the fixture suite to record its grandchild pid');
        grandchildPid = Number(readFileSync(marker, 'utf8'));

        child.kill('SIGTERM');
        await waitForExit(child, 5000);

        assert.ok(!isProcessAlive(grandchildPid), 'the grandchild process must not survive the harness');
        grandchildPid = null;

        const leaked = [...listMutTempDirs(mutantId)].filter((name) => !before.has(name));
        assert.deepEqual(leaked, [], `mkdtemp backup dir(s) leaked after SIGTERM: ${leaked.join(', ')}`);
    } finally {
        // Best-effort: a RED run leaves the grandchild alive, and this must not leak a real
        // sleeping process into the dev machine even when the assertion above already failed.
        if (grandchildPid !== null && isProcessAlive(grandchildPid)) {
            try {
                process.kill(grandchildPid, 'SIGKILL');
            } catch {
                // Already gone between the aliveness check and this kill -- nothing left to do.
            }
        }
        for (const name of listMutTempDirs(mutantId)) {
            if (!before.has(name)) rmSync(path.join(tmpdir(), name), { recursive: true, force: true });
        }
        rmSync(root, { recursive: true, force: true });
    }
});
