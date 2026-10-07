/**
 * publish.yml's back-merge steps, run for real: each step's `run:` body is read out of the workflow
 * and executed under `bash -e` (as Actions does) against a local bare "origin", with `gh` replaced by
 * a stub that records what it was asked to do. Nothing reaches GitHub.
 *
 * Why run the YAML rather than read it: the failure these cases pin is a sequence, not a line. A
 * release's back-merge PR merges and leaves `chore/backmerge-v<version>` behind (this repository has
 * `delete_branch_on_merge` off), then any later merge into `main` — a docs fix, a hotfix — needs a
 * back-merge of its own while the version is unchanged. Keyed on the version alone, the step found
 * the old branch at the old SHA with no open PR, refused, and turned the publish run red with "v… is
 * published and tagged, but … could not be opened".
 *
 * Plain Node, stdlib only, plus `git` and `bash` — both are on every runner that runs this.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, rmSync, existsSync, chmodSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { readWorkflow, stepBody as stepBodyOf } from './workflow-step.mjs';

const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const WORKFLOW = readWorkflow('publish.yml');
const REPO = 'MemberJunction/bizapps-common';
const TOKEN = 'ghs_TEST';

/** The `run: |` body of the step named `name` in publish.yml. */
const stepBody = (name) => stepBodyOf(WORKFLOW, name);

/**
 * A released v5.47.0 whose back-merge PR has merged (its branch left behind at the release merge),
 * followed by one more merge into main. Returns paths and SHAs; `gh` is a stub under `bin/`.
 */
function releasedThenDocsMerge() {
    const root = mkdtempSync(join(tmpdir(), 'publish-backmerge-'));
    const origin = join(root, 'origin.git');
    const seed = join(root, 'seed');
    const git = (cwd, ...args) => execFileSync('git', ['-c', 'user.email=t@t', '-c', 'user.name=t', ...args], { cwd, encoding: 'utf8' }).trim();
    git(root, 'init', '-q', '--bare', '-b', 'main', origin);
    mkdirSync(seed);
    git(seed, 'init', '-q', '-b', 'main');
    writeFileSync(join(seed, 'f'), 'base\n');
    git(seed, 'add', '-A'); git(seed, 'commit', '-qm', 'base'); git(seed, 'branch', 'next');
    writeFileSync(join(seed, 'version'), '5.47.0\n');
    git(seed, 'add', '-A'); git(seed, 'commit', '-qm', 'release v5.47.0');
    const releaseSha = git(seed, 'rev-parse', 'HEAD');
    git(seed, 'branch', 'chore/backmerge-v5.47.0', releaseSha);
    git(seed, 'switch', '-q', 'next');
    git(seed, 'merge', '-q', '--no-ff', '-m', 'back-merge v5.47.0', 'chore/backmerge-v5.47.0');
    git(seed, 'switch', '-q', 'main');
    writeFileSync(join(seed, 'README.md'), 'docs\n');
    git(seed, 'add', '-A'); git(seed, 'commit', '-qm', 'docs fix merged into main');
    const mainSha = git(seed, 'rev-parse', 'HEAD');
    git(seed, 'push', '-q', origin, 'main', 'next', 'chore/backmerge-v5.47.0');
    const work = join(root, 'work');
    git(root, 'clone', '-q', origin, work);

    // The App-token URL the step builds is rewritten to the local origin, so the step body runs as is.
    const gitconfig = join(root, 'gitconfig');
    writeFileSync(gitconfig, `[url "${origin}"]\n\tinsteadOf = https://x-access-token:${TOKEN}@github.com/${REPO}\n`);
    const bin = join(root, 'bin');
    mkdirSync(bin);
    const ghLog = join(root, 'gh.log');
    writeFileSync(join(bin, 'gh'), [
        '#!/usr/bin/env bash',
        `printf '%s\\n' "$*" >> "${ghLog}"`,
        'case "$1 $2" in',
        '  "pr list") printf "%s" "${GH_STUB_OPEN_PR:-}" ;;',
        '  "pr create") echo "https://github.com/o/r/pull/77" ;;',
        'esac',
    ].join('\n'));
    chmodSync(join(bin, 'gh'), 0o755);
    return { root, origin, work, gitconfig, bin, ghLog, releaseSha, mainSha, git };
}

/** Run one step body; returns `{ status, output, stdout, summary }`. */
function runStep(fx, name, env) {
    const out = join(fx.root, `out-${name.replace(/\W+/g, '-')}-${Date.now()}`);
    mkdirSync(out, { recursive: true });
    const files = { GITHUB_OUTPUT: join(out, 'output'), GITHUB_STEP_SUMMARY: join(out, 'summary'), RUNNER_TEMP: out };
    writeFileSync(files.GITHUB_OUTPUT, ''); writeFileSync(files.GITHUB_STEP_SUMMARY, '');
    const script = join(out, 'body.sh');
    writeFileSync(script, stepBody(name));
    const result = spawnSync('bash', ['-e', script], {
        cwd: fx.work,
        encoding: 'utf8',
        env: { PATH: `${fx.bin}:${process.env.PATH}`, HOME: fx.root, GIT_CONFIG_GLOBAL: fx.gitconfig, GITHUB_REPOSITORY: REPO, ...files, ...env },
    });
    const output = Object.fromEntries(readFileSync(files.GITHUB_OUTPUT, 'utf8').split('\n').filter(Boolean).map((l) => [l.slice(0, l.indexOf('=')), l.slice(l.indexOf('=') + 1)]));
    return { status: result.status, stdout: `${result.stdout}${result.stderr}`, output, summary: readFileSync(files.GITHUB_STEP_SUMMARY, 'utf8'), out };
}

const remoteBranches = (fx) => fx.git(fx.root, '--git-dir', fx.origin, 'for-each-ref', '--format=%(refname:short) %(objectname)', 'refs/heads/chore/').split('\n').filter(Boolean);

const prEnv = (fx, extra = {}) => ({ APP_TOKEN: TOKEN, GH_TOKEN: TOKEN, VERSION: '5.47.0', MAIN_SHA: fx.mainSha, WORK: 'false', ...extra });

test('a merge into main after a released version opens its own back-merge instead of failing on the old branch', () => {
    const fx = releasedThenDocsMerge();
    try {
        const r = runStep(fx, 'Open the back-merge pull request', prEnv(fx));
        assert.equal(r.status, 0, r.stdout);
        assert.equal(r.output.pr_url, 'https://github.com/o/r/pull/77');
        const pushed = remoteBranches(fx).find((line) => line.endsWith(fx.mainSha));
        assert.ok(pushed, `no back-merge branch at main's tip:\n${remoteBranches(fx).join('\n')}`);
        assert.ok(pushed.startsWith(`chore/backmerge-v5.47.0-${fx.mainSha.slice(0, 10)} `), pushed);
        assert.ok(remoteBranches(fx).includes(`chore/backmerge-v5.47.0 ${fx.releaseSha}`), 'the merged release back-merge branch is left alone');
    } finally {
        rmSync(fx.root, { recursive: true, force: true });
    }
});

test('a re-run on the same main tip reuses the branch it already pushed', () => {
    const fx = releasedThenDocsMerge();
    try {
        assert.equal(runStep(fx, 'Open the back-merge pull request', prEnv(fx)).status, 0);
        const before = remoteBranches(fx);
        const again = runStep(fx, 'Open the back-merge pull request', prEnv(fx));
        assert.equal(again.status, 0, again.stdout);
        assert.deepEqual(remoteBranches(fx), before, 'a re-run must not stack a second branch');
    } finally {
        rmSync(fx.root, { recursive: true, force: true });
    }
});

test('an open back-merge PR for this main tip ends the step without pushing', () => {
    const fx = releasedThenDocsMerge();
    try {
        const before = remoteBranches(fx);
        const r = runStep(fx, 'Open the back-merge pull request', prEnv(fx, { GH_STUB_OPEN_PR: 'https://github.com/o/r/pull/5' }));
        assert.equal(r.status, 0, r.stdout);
        assert.equal(r.output.pr_url, 'https://github.com/o/r/pull/5');
        assert.deepEqual(remoteBranches(fx), before);
    } finally {
        rmSync(fx.root, { recursive: true, force: true });
    }
});

test('the back-merge PR and the summary say nothing was published when this run published nothing', () => {
    const fx = releasedThenDocsMerge();
    try {
        const pr = runStep(fx, 'Open the back-merge pull request', prEnv(fx));
        const body = readFileSync(join(pr.out, 'backmerge-body.md'), 'utf8');
        assert.doesNotMatch(body, /after publishing|The release itself is finished/, body);
        assert.match(body, /published nothing/, body);
        const summary = runStep(fx, 'Summarise the back-merge', { VERSION: '5.47.0', WORK: 'false', NOTHING: 'false', BRANCH: pr.output.branch, PR_URL: pr.output.pr_url });
        assert.equal(summary.status, 0, summary.stdout);
        assert.doesNotMatch(summary.summary, /published successfully/, summary.summary);
    } finally {
        rmSync(fx.root, { recursive: true, force: true });
    }
});

test('a run that did publish still says so', () => {
    const fx = releasedThenDocsMerge();
    try {
        const pr = runStep(fx, 'Open the back-merge pull request', prEnv(fx, { WORK: 'true' }));
        assert.match(readFileSync(join(pr.out, 'backmerge-body.md'), 'utf8'), /after publishing \*\*v5\.47\.0\*\*/);
        const summary = runStep(fx, 'Summarise the back-merge', { VERSION: '5.47.0', WORK: 'true', NOTHING: 'false', BRANCH: pr.output.branch, PR_URL: pr.output.pr_url });
        assert.match(summary.summary, /v5\.47\.0 published successfully/);
        const failed = runStep(fx, 'Summarise the back-merge', { VERSION: '5.47.0', WORK: 'true', NOTHING: 'false', BRANCH: pr.output.branch, PR_URL: '' });
        assert.match(failed.summary, /published successfully, but the back-merge PR could not be opened/);
    } finally {
        rmSync(fx.root, { recursive: true, force: true });
    }
});

test('the steps receive WORK from release_check, so their wording can depend on it', () => {
    for (const name of ['Open the back-merge pull request', 'Summarise the back-merge', 'The back-merge pull request could not be opened']) {
        const at = WORKFLOW.indexOf(`- name: ${name}`);
        const step = WORKFLOW.slice(at, WORKFLOW.indexOf('run: |', at));
        assert.match(step, /WORK: \$\{\{ steps\.release_check\.outputs\.work \}\}/, `"${name}" env`);
    }
});

// ---------------------------------------------------------------------------------------------
// Merging the back-merge PR. The step is pure `gh` (no git), so these cases need no origin: a stub
// answers `gh pr view` from fixture JSON, applying the step's own `--jq` expression through `jq` so
// the classification logic under test is the real one, and records any `gh pr merge`.
// ---------------------------------------------------------------------------------------------

const MERGE_STEP = 'Merge the back-merge pull request once its checks pass';
const PR_URL = 'https://github.com/o/r/pull/77';
const MAIN_SHA = 'a'.repeat(40);
const RUN_ID = '4242';

/** A check-run as statusCheckRollup reports it; `run` picks the workflow run it belongs to. */
const check = (name, status, conclusion, run = '1') => ({
    __typename: 'CheckRun', name, status, conclusion, detailsUrl: `https://github.com/o/r/actions/runs/${run}/job/9`,
});
const GREEN = [check('build-only', 'COMPLETED', 'SUCCESS'), check('Mutants', 'COMPLETED', 'SKIPPED')];

function mergeFixture() {
    const root = mkdtempSync(join(tmpdir(), 'publish-backmerge-merge-'));
    const bin = join(root, 'bin');
    mkdirSync(bin);
    const ghLog = join(root, 'gh.log');
    writeFileSync(join(bin, 'gh'), [
        '#!/usr/bin/env bash',
        `printf '%s\\n' "$*" >> "${ghLog}"`,
        'if [ "$1 $2" = "pr merge" ]; then exit "${GH_STUB_MERGE_RC:-0}"; fi',
        'if [ "$1 $2" = "pr view" ]; then',
        '  field=""; expr="."',
        '  while [ $# -gt 0 ]; do case "$1" in --json) field="$2"; shift ;; --jq) expr="$2"; shift ;; esac; shift; done',
        '  case "$field" in',
        '    headRefOid) json="{\\"headRefOid\\":\\"$GH_STUB_HEAD\\"}" ;;',
        '    statusCheckRollup) json="$GH_STUB_ROLLUP" ;;',
        '    mergeable) json="{\\"mergeable\\":\\"$GH_STUB_MERGEABLE\\"}" ;;',
        '  esac',
        '  printf "%s" "$json" | jq -r "$expr"',
        'fi',
    ].join('\n'));
    chmodSync(join(bin, 'gh'), 0o755);
    return { root, work: root, bin, gitconfig: join(root, 'gitconfig'), ghLog };
}

/** Runs the merge step; `checks` is the rollup, the rest override the stub's answers. */
function runMerge(fx, { checks = GREEN, head = MAIN_SHA, mergeable = 'MERGEABLE', mergeRc = 0, waitSeconds = 30 } = {}) {
    writeFileSync(fx.gitconfig, '');
    writeFileSync(fx.ghLog, '');
    return runStep(fx, MERGE_STEP, {
        GH_TOKEN: TOKEN, PR_URL, MAIN_SHA, GITHUB_RUN_ID: RUN_ID,
        WAIT_SECONDS: String(waitSeconds), POLL_SECONDS: '0',
        GH_STUB_HEAD: head, GH_STUB_ROLLUP: JSON.stringify({ statusCheckRollup: checks }),
        GH_STUB_MERGEABLE: mergeable, GH_STUB_MERGE_RC: String(mergeRc),
    });
}
const mergeCalls = (fx) => readFileSync(fx.ghLog, 'utf8').split('\n').filter((l) => l.startsWith('pr merge'));

test('a green, mergeable back-merge PR is merged with a merge commit pinned to main\'s tip', () => {
    const fx = mergeFixture();
    try {
        const r = runMerge(fx);
        assert.equal(r.status, 0, r.stdout);
        assert.equal(r.output.merged, 'true');
        assert.deepEqual(mergeCalls(fx), [`pr merge ${PR_URL} --merge --match-head-commit ${MAIN_SHA}`]);
    } finally {
        rmSync(fx.root, { recursive: true, force: true });
    }
});

test('this publish run\'s own in-progress job is not waited on', () => {
    // The PR's head is main's tip, the commit this run executes on, so the run's own job is on the
    // PR as an in-progress check. Waiting on it would deadlock until the timeout.
    const fx = mergeFixture();
    try {
        const r = runMerge(fx, { checks: [...GREEN, check('build-and-publish', 'IN_PROGRESS', null, RUN_ID)], waitSeconds: 1 });
        assert.equal(r.output.merged, 'true', r.stdout);
    } finally {
        rmSync(fx.root, { recursive: true, force: true });
    }
});

test('a failing check leaves the PR open without failing the run', () => {
    const fx = mergeFixture();
    try {
        const r = runMerge(fx, { checks: [...GREEN, check('changes_and_migrations', 'COMPLETED', 'FAILURE')] });
        assert.equal(r.status, 0, r.stdout);
        assert.equal(r.output.merged, 'false');
        assert.match(r.output.reason, /a check failed/);
        assert.deepEqual(mergeCalls(fx), []);
    } finally {
        rmSync(fx.root, { recursive: true, force: true });
    }
});

test('a conflicting PR is left open', () => {
    const fx = mergeFixture();
    try {
        const r = runMerge(fx, { mergeable: 'CONFLICTING' });
        assert.equal(r.status, 0, r.stdout);
        assert.match(r.output.reason, /conflicts with next/);
        assert.deepEqual(mergeCalls(fx), []);
    } finally {
        rmSync(fx.root, { recursive: true, force: true });
    }
});

test('commits added to the back-merge branch are never merged unreviewed', () => {
    const fx = mergeFixture();
    try {
        const r = runMerge(fx, { head: 'b'.repeat(40) });
        assert.equal(r.status, 0, r.stdout);
        assert.match(r.output.reason, /no longer main's tip/);
        assert.deepEqual(mergeCalls(fx), []);
    } finally {
        rmSync(fx.root, { recursive: true, force: true });
    }
});

test('checks that never report, or never finish, time out and leave the PR open', () => {
    const fx = mergeFixture();
    try {
        for (const checks of [[], [check('build-only', 'QUEUED', null)]]) {
            const r = runMerge(fx, { checks, waitSeconds: 0 });
            assert.equal(r.status, 0, r.stdout);
            assert.match(r.output.reason, /did not all pass within/);
            assert.deepEqual(mergeCalls(fx), []);
        }
    } finally {
        rmSync(fx.root, { recursive: true, force: true });
    }
});

test('a merge call that errors fails the step, so the run goes red', () => {
    const fx = mergeFixture();
    try {
        const r = runMerge(fx, { mergeRc: 1 });
        assert.notEqual(r.status, 0, r.stdout);
        assert.notEqual(r.output.merged, 'true');
    } finally {
        rmSync(fx.root, { recursive: true, force: true });
    }
});

test('the summary reports an automatic merge, and the reason when there was none', () => {
    const fx = mergeFixture();
    try {
        const base = { VERSION: '5.47.0', WORK: 'true', NOTHING: 'false', BRANCH: 'chore/backmerge-v5.47.0-aaaaaaaaaa', PR_URL };
        const merged = runStep(fx, 'Summarise the back-merge', { ...base, MERGED: 'true' });
        assert.match(merged.summary, /### Back-merged/);
        assert.doesNotMatch(merged.summary, /outstanding/);
        const open = runStep(fx, 'Summarise the back-merge', { ...base, MERGED: 'false', REASON: 'it conflicts with next' });
        assert.match(open.summary, /### The back-merge is outstanding/);
        assert.match(open.summary, /not merged automatically because it conflicts with next/);
    } finally {
        rmSync(fx.root, { recursive: true, force: true });
    }
});

test('the reader found real step bodies', () => {
    assert.ok(existsSync(join(REPO_ROOT, '.github', 'workflows', 'publish.yml')));
    assert.match(stepBody('Open the back-merge pull request'), /gh pr create/);
    assert.match(stepBody(MERGE_STEP), /gh pr merge/);
    assert.match(stepBody('Summarise the back-merge'), /GITHUB_STEP_SUMMARY/);
});
