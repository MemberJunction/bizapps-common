/**
 * changes.yml's two back-merge guards, run for real against a local bare "origin".
 *
 * - A PR into `main` must contain main's tip. Otherwise merging it reverts main's commits, a
 *   released version bump among them: a `next -> main` PR opened while v5.50.0's back-merge was
 *   outstanding would have set main back from 5.50.0 to 5.49.0, and GitHub would not have stopped it.
 * - A PR into `next` fails while a back-merge is outstanding, naming the problem while it is still
 *   cheap, instead of leaving it for release-prep.mjs to find when the next release is cut.
 *
 * Each step's `run:` body is read out of the workflow and executed under `bash -e` (as Actions
 * does), in a clone of the fixture origin. Plain Node, stdlib only, plus `git` and `bash`.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { readWorkflow, stepBody, stepCondition } from './workflow-step.mjs';

const CHANGES = readWorkflow('changes.yml');
const INTO_MAIN = 'A pull request into main must contain main';
const INTO_NEXT = 'No back-merge outstanding on a pull request into next';

/**
 * v5.49.0 released and back-merged, then v5.50.0 released on main and NOT back-merged, then a
 * feature merged into next. Returns SHAs for every branch a PR could come from.
 */
function releasedWithoutBackMerge() {
    const root = mkdtempSync(join(tmpdir(), 'backmerge-guards-'));
    const origin = join(root, 'origin.git');
    const seed = join(root, 'seed');
    const git = (cwd, ...args) => execFileSync('git', ['-c', 'user.email=t@t', '-c', 'user.name=t', ...args], { cwd, encoding: 'utf8' }).trim();
    const commit = (file, body, msg) => { writeFileSync(join(seed, file), body); git(seed, 'add', '-A'); git(seed, 'commit', '-qm', msg); return git(seed, 'rev-parse', 'HEAD'); };

    git(root, 'init', '-q', '--bare', '-b', 'next', origin);
    mkdirSync(seed);
    git(seed, 'init', '-q', '-b', 'main');
    commit('version', '5.49.0\n', 'release v5.49.0');
    git(seed, 'branch', 'next');
    commit('version', '5.50.0\n', 'release v5.50.0');                 // on main only
    const backmergeSha = git(seed, 'rev-parse', 'HEAD');               // the back-merge branch is main's tip
    git(seed, 'switch', '-q', 'next');
    const staleNextSha = commit('feature', 'x\n', 'feature merged into next');
    git(seed, 'switch', '-q', '-c', 'feature/y');
    const featureSha = commit('feature-y', 'y\n', 'another feature');
    git(seed, 'push', '-q', origin, 'main', 'next');
    const work = join(root, 'work');
    git(root, 'clone', '-q', `file://${origin}`, work);
    // The PR heads live only in the clone, as they would after actions/checkout of the PR.
    git(work, 'fetch', '-q', seed, 'feature/y');
    return { root, origin, work, git, backmergeSha, staleNextSha, featureSha };
}

function runStep(fx, name, headSha) {
    const script = join(fx.root, `step-${Date.now()}.sh`);
    writeFileSync(script, stepBody(CHANGES, name));
    const r = spawnSync('bash', ['-e', script], { cwd: fx.work, encoding: 'utf8', env: { ...process.env, HEAD_SHA: headSha } });
    return { status: r.status, out: `${r.stdout}${r.stderr}` };
}

/** Back-merges main into next on the origin, as merging the chore/backmerge-* PR would. */
function backMerge(fx) {
    const tmp = join(fx.root, 'merge');
    fx.git(fx.root, 'clone', '-q', '-b', 'next', fx.origin, tmp);
    fx.git(tmp, 'merge', '-q', '--no-ff', '-m', 'back-merge v5.50.0', 'origin/main');
    fx.git(tmp, 'push', '-q', 'origin', 'next');
    fx.git(fx.work, 'fetch', '-q', 'origin');
    return fx.git(tmp, 'rev-parse', 'HEAD');
}

const withFixture = (fn) => () => {
    const fx = releasedWithoutBackMerge();
    try { fn(fx); } finally { rmSync(fx.root, { recursive: true, force: true }); }
};

test('each guard runs only for its own base branch', () => {
    assert.equal(stepCondition(CHANGES, INTO_MAIN), "github.base_ref == 'main'");
    assert.equal(stepCondition(CHANGES, INTO_NEXT), "github.base_ref == 'next'");
});

test('a next -> main PR built on a stale next fails, naming the commit it would revert', withFixture((fx) => {
    const r = runStep(fx, INTO_MAIN, fx.staleNextSha);
    assert.equal(r.status, 1, r.out);
    assert.match(r.out, /release v5\.50\.0/);
    assert.match(r.out, /would revert/);
}));

test('a release branch cut after the back-merge contains main and passes', withFixture((fx) => {
    const nextAfter = backMerge(fx);
    const r = runStep(fx, INTO_MAIN, nextAfter);
    assert.equal(r.status, 0, r.out);
}));

test('a PR into next fails while the back-merge is outstanding', withFixture((fx) => {
    const r = runStep(fx, INTO_NEXT, fx.featureSha);
    assert.equal(r.status, 1, r.out);
    assert.match(r.out, /back-merge is outstanding/);
    assert.match(r.out, /release v5\.50\.0/);
}));

test('the back-merge PR itself passes, because it carries main', withFixture((fx) => {
    const r = runStep(fx, INTO_NEXT, fx.backmergeSha);
    assert.equal(r.status, 0, r.out);
    assert.match(r.out, /carries main/);
}));

test('once the back-merge has landed, a PR into next passes', withFixture((fx) => {
    backMerge(fx);
    const r = runStep(fx, INTO_NEXT, fx.featureSha);
    assert.equal(r.status, 0, r.out);
    assert.match(r.out, /already in next/);
}));

/** What changes.yml's "Resolve current base branch tip" step does before the guards run. */
const shallowBaseFetch = (fx) => fx.git(fx.work, 'fetch', '-q', '--no-tags', '--depth=1', 'origin', 'next');

test('the depth-1 base fetch earlier in the job does not make a landed back-merge read as missing', withFixture((fx) => {
    // A shallow boundary at next's tip hides its parents, main's tip among them, so without
    // un-shallowing, every PR into next stayed red after the back-merge merged.
    backMerge(fx);
    shallowBaseFetch(fx);
    assert.equal(fx.git(fx.work, 'rev-parse', '--is-shallow-repository'), 'true', 'fixture must reproduce the shallow clone');
    const r = runStep(fx, INTO_NEXT, fx.featureSha);
    assert.equal(r.status, 0, r.out);
    assert.match(r.out, /already in next/);
    const intoMain = runStep(fx, INTO_MAIN, fx.git(fx.work, 'rev-parse', 'origin/next'));
    assert.equal(intoMain.status, 0, intoMain.out);
}));

test('no guard pipes git into head, which under pipefail exits 141 before the error prints', () => {
    // The behavioural case below cannot reproduce the SIGPIPE locally: a short log fits in the pipe
    // buffer, so git exits before head closes it. On GitHub the list was long enough. Pinned here.
    for (const name of [INTO_MAIN, INTO_NEXT]) assert.doesNotMatch(stepBody(CHANGES, name), /\|\s*head\b/, name);
});

test('more than twenty missing commits still fail with the error', withFixture((fx) => {
    const tmp = join(fx.root, 'many');
    fx.git(fx.root, 'clone', '-q', '-b', 'main', fx.origin, tmp);
    for (let i = 0; i < 25; i++) { writeFileSync(join(tmp, `hotfix-${i}`), `${i}\n`); fx.git(tmp, 'add', '-A'); fx.git(tmp, 'commit', '-qm', `hotfix ${i}`); }
    fx.git(tmp, 'push', '-q', 'origin', 'main');
    for (const [name, head, message] of [[INTO_NEXT, fx.featureSha, /back-merge is outstanding/], [INTO_MAIN, fx.staleNextSha, /would revert/]]) {
        const r = runStep(fx, name, head);
        assert.equal(r.status, 1, `${name}: ${r.out}`);
        assert.match(r.out, message);
    }
}));

test('the guards test the PR head, never the merge preview commit', () => {
    // github.sha on a pull_request event is the merge preview, which contains the base by
    // construction; a guard reading it would pass every time.
    for (const name of [INTO_MAIN, INTO_NEXT]) {
        const at = CHANGES.indexOf(`- name: ${name}`);
        const step = CHANGES.slice(at, CHANGES.indexOf('run: |', at));
        assert.match(step, /HEAD_SHA: \$\{\{ github\.event\.pull_request\.head\.sha \}\}/, name);
        assert.doesNotMatch(stepBody(CHANGES, name), /github\.sha/, name);
    }
});
