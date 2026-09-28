/**
 * release-prep.yml's "Refuse to cut a release that is not ready" step, run for real.
 *
 * It refused when `release/v<this version>` already existed, but not when a DIFFERENT release PR was
 * still open: a stronger changeset landing between two dispatches computes a new version, a new
 * branch name, and a second release PR into main beside the first. Only one release can merge
 * cleanly, so any open `release/*` PR into main blocks the next cut.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, chmodSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { readWorkflow, stepBody } from './workflow-step.mjs';

const STEP = 'Refuse to cut a release that is not ready';
const BODY = stepBody(readWorkflow('release-prep.yml'), STEP);

/** Runs the guard in a clone of a local origin, with `gh pr list` answering `openReleasePrs`. */
function guard({ openReleasePrs = '', ready = 'true' } = {}) {
    const root = mkdtempSync(join(tmpdir(), 'release-prep-guard-'));
    try {
        const git = (cwd, ...a) => execFileSync('git', ['-c', 'user.email=t@t', '-c', 'user.name=t', ...a], { cwd, encoding: 'utf8' });
        git(root, 'init', '-q', '--bare', '-b', 'next', join(root, 'origin.git'));
        git(root, 'clone', '-q', join(root, 'origin.git'), join(root, 'work'));
        writeFileSync(join(root, 'work', 'f'), 'x\n');
        git(join(root, 'work'), 'add', '-A'); git(join(root, 'work'), 'commit', '-qm', 'x'); git(join(root, 'work'), 'push', '-q', 'origin', 'next');
        mkdirSync(join(root, 'bin'));
        writeFileSync(join(root, 'bin', 'gh'), `#!/usr/bin/env bash\n[ "$1 $2" = "pr list" ] && printf '%s' "$GH_STUB_OPEN"\nexit 0\n`);
        chmodSync(join(root, 'bin', 'gh'), 0o755);
        writeFileSync(join(root, 'guard.sh'), BODY);
        const r = spawnSync('bash', ['-e', join(root, 'guard.sh')], {
            cwd: join(root, 'work'),
            encoding: 'utf8',
            env: { PATH: `${join(root, 'bin')}:${process.env.PATH}`, HOME: root, GITHUB_REPOSITORY: 'o/r', GH_TOKEN: 't',
                READY: ready, VERSION: '5.48.0', BRANCH: 'release/v5.48.0', GH_STUB_OPEN: openReleasePrs },
        });
        return { status: r.status, out: `${r.stdout}${r.stderr}` };
    } finally {
        rmSync(root, { recursive: true, force: true });
    }
}

test('a ready release with no other release PR open passes the guard', () => {
    const r = guard();
    assert.equal(r.status, 0, r.out);
});

test('an open release PR for another version refuses, naming it', () => {
    const r = guard({ openReleasePrs: 'https://github.com/o/r/pull/300' });
    assert.equal(r.status, 1, r.out);
    assert.match(r.out, /pull\/300/);
});

test('the step can read pull requests', () => {
    const workflow = readWorkflow('release-prep.yml');
    assert.match(workflow, /^permissions:\n(?:  .+\n)*  pull-requests: read$/m);
    const step = workflow.slice(workflow.indexOf(`- name: ${STEP}`), workflow.indexOf('run: |', workflow.indexOf(`- name: ${STEP}`)));
    assert.match(step, /GH_TOKEN: \$\{\{ github\.token \}\}/);
});
