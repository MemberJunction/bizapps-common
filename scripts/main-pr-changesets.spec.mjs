/**
 * A pull request into `main` must not carry pending changesets.
 *
 * publish.yml refuses to publish while `.changeset/*.md` remain, because their presence means the
 * version was never bumped. That refusal comes AFTER the merge. The release PR arrives with its
 * changesets consumed, and a hotfix into main must carry its own bump, so a PR into main that still
 * has one is a mistake best caught before merging: changes.yml runs on PRs into main, and this pins
 * its step by running it.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { readWorkflow, stepBody, stepCondition } from './workflow-step.mjs';

const STEP = 'No pending changesets on a pull request into main';
const CHANGES = readWorkflow('changes.yml');

function runWith(files) {
    const root = mkdtempSync(join(tmpdir(), 'main-pr-changesets-'));
    try {
        mkdirSync(join(root, '.changeset'));
        for (const [name, body] of Object.entries(files)) writeFileSync(join(root, '.changeset', name), body);
        const script = join(root, 'step.sh');
        writeFileSync(script, stepBody(CHANGES, STEP));
        const r = spawnSync('bash', ['-e', script], { cwd: root, encoding: 'utf8' });
        return { status: r.status, out: `${r.stdout}${r.stderr}` };
    } finally {
        rmSync(root, { recursive: true, force: true });
    }
}

test('runs only for pull requests into main', () => {
    assert.equal(stepCondition(CHANGES, STEP), "github.base_ref == 'main'");
});

test('a pending changeset fails the PR and names it', () => {
    const r = runWith({ 'config.json': '{}', 'README.md': '# x', 'brave-fox.md': '---\n"@mj-biz-apps/common-entities": patch\n---\nfix\n' });
    assert.equal(r.status, 1, r.out);
    assert.match(r.out, /brave-fox\.md/);
});

test('only config.json and README.md is what main should look like', () => {
    const r = runWith({ 'config.json': '{}', 'README.md': '# x' });
    assert.equal(r.status, 0, r.out);
});
