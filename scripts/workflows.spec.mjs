import { test } from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { readFileSync, readdirSync, existsSync } from 'node:fs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.join(HERE, '..');

function readRepoFile(relPath) {
    return readFileSync(path.join(REPO_ROOT, relPath), 'utf8');
}

// ── mutants.yml: which PR files start a mutation run (issue #330) ───────────────────────────────

/** The `grep -qE '<pattern>'` the select job pipes the PR's file list through, as a RegExp. */
function mutantsSelector() {
    const match = readRepoFile('.github/workflows/mutants.yml').match(/\|\s*grep -qE '([^']+)'/);
    assert.ok(match, 'mutants.yml no longer selects PR files with grep -qE; update this spec');
    return new RegExp(match[1]);
}

/** Every package mutation harness, plus each repo file those harnesses import by relative path. */
function mutationHarnessFiles() {
    const files = new Set();
    for (const pkg of readdirSync(path.join(REPO_ROOT, 'packages'))) {
        const dir = path.join('packages', pkg, 'test-harnesses');
        if (!existsSync(path.join(REPO_ROOT, dir))) continue;
        for (const name of readdirSync(path.join(REPO_ROOT, dir)).filter((f) => f.endsWith('.mjs'))) {
            const file = path.join(dir, name);
            files.add(file);
            for (const [, spec] of readRepoFile(file).matchAll(/from '(\.{1,2}\/[^']+)'/g)) {
                files.add(path.relative(REPO_ROOT, path.resolve(REPO_ROOT, dir, spec)));
            }
        }
    }
    return [...files].map((f) => f.split(path.sep).join('/'));
}

test('a PR touching any mutation harness or a module it imports starts a mutation run', () => {
    const selector = mutantsSelector();
    const files = mutationHarnessFiles();
    assert.ok(files.includes('test-harnesses/mutation-suite.mjs'), 'expected the shared suite module among the imports');
    for (const file of [...files, '.github/workflows/mutants.yml']) {
        assert.match(file, selector, `${file} changes what the mutants do but does not start a run`);
    }
});

test('a PR touching only ordinary source or the integration harness does not start a mutation run', () => {
    const selector = mutantsSelector();
    for (const file of ['packages/Server/src/index.ts', 'test-harnesses/integration.mjs', '.github/workflows/build.yml']) {
        assert.doesNotMatch(file, selector, file);
    }
});

// ── sqlcmd install steps: fail loudly, and the same in both workflows (issue #320) ──────────────

const SQLCMD_INSTALL_WORKFLOWS = ['.github/workflows/changes.yml', '.github/workflows/clean-room-gate.yml'];

/** The command lines of a workflow's `Install sqlcmd` step that do the installing. */
function sqlcmdInstallCommands(workflow) {
    const match = readRepoFile(workflow).match(/- name: Install sqlcmd[^\n]*\n\s+run: \|\n((?:[ \t]+[^\n]*\n)+?)\s*\n/);
    assert.ok(match, `${workflow} has no "Install sqlcmd" step; update this spec`);
    return match[1]
        .split('\n')
        .map((line) => line.trim())
        .filter((line) => /\b(curl|gpg|apt-get|tee)\b/.test(line));
}

test('no sqlcmd install command hides its failure', () => {
    for (const workflow of SQLCMD_INSTALL_WORKFLOWS) {
        const commands = sqlcmdInstallCommands(workflow);
        assert.equal(commands.length, 4, `${workflow}: expected key, sources list, update and install`);
        for (const command of commands) {
            assert.doesNotMatch(command, /\|\|\s*true|2>\s*\/dev\/null/, `${workflow}: ${command}`);
        }
        assert.ok(
            commands.some((c) => c.includes('gpg --batch --yes --dearmor')),
            `${workflow}: gpg needs --batch --yes to overwrite a keyring the runner already has`,
        );
    }
});

test('changes.yml and clean-room-gate.yml install sqlcmd with the same commands', () => {
    const [first, second] = SQLCMD_INSTALL_WORKFLOWS.map(sqlcmdInstallCommands);
    assert.deepEqual(first, second);
});
