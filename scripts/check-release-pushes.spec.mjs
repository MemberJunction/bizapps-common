import { test } from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { mkdtempSync, mkdirSync, writeFileSync, copyFileSync, rmSync, realpathSync, symlinkSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { PROTECTED_BRANCHES, SCANNED_DIRS, EXCLUDED_FILES, findProtectedPushes, runCheck } from './check-release-pushes.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.join(HERE, '..');

// ── What the gate must catch ────────────────────────────────────────────────────────────────────

test('a shell push to main is a violation', () => {
    const found = findProtectedPushes('git push origin HEAD:main\n');
    assert.equal(found.length, 1);
    assert.equal(found[0].ref, 'main');
});

test('a shell push to next is a violation', () => {
    assert.equal(findProtectedPushes('git push origin HEAD:next\n').length, 1);
});

test('a bare branch push is a violation', () => {
    assert.equal(findProtectedPushes('git push origin main\n').length, 1);
});

test('a fully-qualified ref is a violation', () => {
    assert.equal(findProtectedPushes('git push origin HEAD:refs/heads/next\n').length, 1);
});

test('a force push is still a push', () => {
    assert.equal(findProtectedPushes('git push --force origin HEAD:main\n').length, 1);
});

// simple-git spells the same operation as a method call, which is how both of
// MemberJunction/bizapps-forms#177's pushes were written. A gate that only reads shell would have
// seen neither.
test('the simple-git form is a violation', () => {
    assert.equal(findProtectedPushes("await git.push('origin', 'HEAD:main');\n").length, 1);
});

test('the simple-git form with double quotes is a violation', () => {
    assert.equal(findProtectedPushes('await git.push("origin", "HEAD:next");\n').length, 1);
});

test('the reported line number is the offending line', () => {
    const found = findProtectedPushes('a\nb\ngit push origin HEAD:main\n');
    assert.equal(found[0].line, 3);
});

// ── Spellings a reintroduced push would plausibly take ──────────────────────────────────────────
//
// Each of these was a MISS until bizapps-forms' MemberJunction/bizapps-forms#187 review. They are
// not hypotheticals: the sibling gate in that repo, .claude/hooks/require-green-before-git.mjs,
// records the same two under-inclusiveness bugs in its own docstring — git GLOBAL OPTIONS between
// `git` and the subcommand are "otherwise a straight bypass", and `&&`, `;`, `|` and newlines "all
// count as command starts". This gate was written after that lesson and had inherited neither.

test('a git global option between `git` and `push` does not hide the push', () => {
    // `git -c user.email=… push` is ordinary CI, and this very workflow already runs a separate
    // `git config --global user.email` step that an author could fold into the push exactly that way.
    assert.equal(findProtectedPushes('git -c user.email=x@y push origin main\n').length, 1);
    assert.equal(findProtectedPushes('git -C . push origin main\n').length, 1);
    assert.equal(findProtectedPushes('git --git-dir=.git push origin HEAD:next\n').length, 1);
    assert.equal(findProtectedPushes('git --no-pager push origin HEAD:main\n').length, 1);
});

test('a push that is not the first command on its line is still a push', () => {
    // The likeliest reintroduction shape of all: BOTH of MemberJunction/bizapps-forms#177's pushes
    // lived in Node scripts, and the deleted ci/merge_main_and_update_lock.mjs already shelled out
    // through execSync.
    assert.equal(findProtectedPushes("execSync('git push origin HEAD:main')\n").length, 1);
    assert.equal(findProtectedPushes('git checkout next && git push origin next\n').length, 1);
    assert.equal(findProtectedPushes('git config user.name x; git push origin main\n').length, 1);
    assert.equal(findProtectedPushes('if [ -n "$V" ]; then git push origin main; fi\n').length, 1);
});

test('a quoted refspec is a push, with or without a colon in it', () => {
    // `git push origin "HEAD:main"` already matched, but only by accident: the optional `(?:\S*:)?`
    // group absorbed the opening quote on its way to the colon. A BARE branch name has no colon, so
    // that group matches empty and the quote lands where the branch name has to start. The colon
    // form working is what hid the bare form failing.
    assert.equal(findProtectedPushes('git push origin "main"\n').length, 1);
    assert.equal(findProtectedPushes("git push -u origin 'next'\n").length, 1);
    assert.equal(findProtectedPushes('git push origin `next`\n').length, 1);
    assert.equal(findProtectedPushes('git push origin "refs/heads/main"\n').length, 1);
    assert.equal(findProtectedPushes('git push origin refs/heads/"main"\n').length, 1);
});

test('the force-push refspec shorthand is a push', () => {
    // `+main` is the ordinary spelling of a force push to a branch.
    assert.equal(findProtectedPushes('git push origin +main\n').length, 1);
    assert.equal(findProtectedPushes('git push origin "+next"\n').length, 1);
});

test("simple-git's array refspec form is a violation", () => {
    assert.equal(findProtectedPushes("await git.push(['origin', 'HEAD:main']);\n").length, 1);
});

test('a push spelled with a capital G still invokes git on a case-insensitive volume', () => {
    // macOS and Windows both mount case-insensitively, so `Git push` really does run git here.
    assert.equal(findProtectedPushes('Git push origin HEAD:main\n').length, 1);
});

// ── `gh api` REST ref updates: the same branch mutation, without ever calling `git push` ───────────
//
// Required status checks are evaluated against `git push`'s introduced SHA (this file's header) —
// but a `gh api` PATCH/POST to `.../git/refs/heads/<branch>` updates the SAME ref through the REST
// API, never through `git push`, so GH013 never triggers on it. Invisible to SHELL_PUSH/METHOD_PUSH,
// which only recognise `git push` and simple-git's `.push(...)`.

test('a `gh api` PATCH to git/refs/heads/main, shelled via execFileSync, is a violation', () => {
    // The exact shape confirmed live in the smoke hunt: a fixture script that updates the ref
    // directly, bypassing the push gate entirely (`runCheck` returned 0 violations before this fix).
    const line = "execFileSync('gh', ['api', '-X', 'PATCH', 'repos/OWNER/REPO/git/refs/heads/main', '-f', `sha=${sha}`]);\n";
    assert.equal(findProtectedPushes(line).length, 1);
});

test('a `gh api` POST to refs/heads/next (no `git/` prefix) is a violation', () => {
    assert.equal(findProtectedPushes("gh api -X POST repos/OWNER/REPO/refs/heads/next -f sha=$SHA\n").length, 1);
});

test('a `gh api` call that merely mentions an unrelated field named main is not a violation', () => {
    // `gh` and `api` alone are not enough — the ref target itself must be present, or this becomes a
    // keyword match on any gh api call in the release path.
    assert.deepEqual(findProtectedPushes('gh api repos/OWNER/REPO/pulls -f base=main\n'), []);
});

test('a `gh api` call naming an unprotected branch ref is not a violation', () => {
    assert.deepEqual(findProtectedPushes('gh api -X PATCH repos/OWNER/REPO/git/refs/heads/chore/thing -f sha=$SHA\n'), []);
});

// ── A `git push` split across lines with a shell `\` continuation ──────────────────────────────────
//
// `findProtectedPushes` scanned line-by-line, and SHELL_PUSH requires the whole `git push … main` on
// ONE physical line — so a `run: |` block that continues the command with a trailing backslash was
// invisible, even though the file's own header docstring calls this exact spelling ("BOTH of
// MemberJunction/bizapps-forms#177's pushes lived in Node scripts... that is the likeliest spelling a
// reintroduction would take") the kind of thing this gate must not miss.

test('a `git push` split across two lines with a trailing `\\` is a violation', () => {
    const text = ['- run: |', '    git push origin \\', '      HEAD:main', ''].join('\n');
    const found = findProtectedPushes(text);
    assert.equal(found.length, 1);
    assert.equal(found[0].ref, 'main');
});

test('the reported line is the FIRST line of the continuation, not the last', () => {
    const text = ['a', '    git push origin \\', '      HEAD:main', 'b'].join('\n');
    const found = findProtectedPushes(text);
    assert.equal(found[0].line, 2);
});

test('a three-line continuation still joins into one logical line', () => {
    const text = ['git push \\', '  origin \\', '  HEAD:next', ''].join('\n');
    const found = findProtectedPushes(text);
    assert.equal(found.length, 1);
    assert.equal(found[0].ref, 'next');
});

test('line numbers after a continuation are unaffected — they count physical lines, not logical ones', () => {
    const text = ['git push origin \\', '  HEAD:main', 'git push origin HEAD:next', ''].join('\n');
    const found = findProtectedPushes(text);
    assert.equal(found.length, 2);
    assert.equal(found[0].line, 1);
    assert.equal(found[1].line, 3);
});

test('a commented-out continuation start is still exempt, even when joined', () => {
    const text = ['# git push origin \\', '  HEAD:main', ''].join('\n');
    assert.deepEqual(findProtectedPushes(text), []);
});

// ── Allow-cases: what stops "deny everything" from passing as a fix ─────────────────────────────

test('pushing a tag is allowed — both rulesets are target: branch', () => {
    assert.deepEqual(findProtectedPushes('git push origin refs/tags/v1.2.3\n'), []);
    assert.deepEqual(findProtectedPushes("await git.push('origin', `refs/tags/${version}`);\n"), []);
});

test('pushing an unprotected branch is allowed', () => {
    assert.deepEqual(findProtectedPushes('git push origin HEAD:chore/sync-main-into-next\n'), []);
});

test('a branch whose name merely starts with a protected name is allowed', () => {
    assert.deepEqual(findProtectedPushes('git push origin HEAD:mainline\n'), []);
    assert.deepEqual(findProtectedPushes('git push origin HEAD:next-steps\n'), []);
});

test('prose mentioning the push is not a violation', () => {
    assert.deepEqual(findProtectedPushes('# the pipeline used to git push origin HEAD:main here\n'), []);
    assert.deepEqual(findProtectedPushes('  // git push origin HEAD:next was removed here\n'), []);
});

test('fetching or merging a protected branch is allowed', () => {
    assert.deepEqual(findProtectedPushes("await git.fetch('origin', 'main');\n"), []);
    assert.deepEqual(findProtectedPushes('git merge --ff-only origin/next\n'), []);
});

test('a remote positional is a remote, not a branch — `git push main` pushes to a remote named main', () => {
    // `git push [<repository> [<refspec>…]]`: the first positional is the REPOSITORY. Pinned so a
    // future widening cannot start flagging it, which would be a false positive on every repo that
    // happens to have a remote called `main`.
    assert.deepEqual(findProtectedPushes('git push main\n'), []);
    assert.deepEqual(findProtectedPushes('git push\n'), []);
});

test('prose is still excluded once the command no longer has to start the line', () => {
    assert.deepEqual(findProtectedPushes('  # we used to run: git checkout next && git push origin next\n'), []);
    assert.deepEqual(findProtectedPushes(' * history: execSync("git push origin HEAD:main") lived here\n'), []);
    assert.deepEqual(findProtectedPushes('<!-- git push origin main -->\n'), []);
});

test('quoting does not make a non-protected target protected', () => {
    assert.deepEqual(findProtectedPushes('git push origin "mainline"\n'), []);
    assert.deepEqual(findProtectedPushes("git push origin 'next-steps'\n"), []);
    assert.deepEqual(findProtectedPushes('git push origin "refs/tags/v1.2.3"\n'), []);
    assert.deepEqual(findProtectedPushes('git push origin "+refs/tags/v1.2.3"\n'), []);
});

// ── Where the gate looks ────────────────────────────────────────────────────────────────────────
//
// bizapps-forms' MemberJunction/bizapps-forms#187 review: the list named `ci/`, which this change
// deletes, and omitted `scripts/`, which this change is what moves release automation INTO —
// `scripts/sync-app-version.mjs` is invoked by publish.yml and by the root `version` script. The
// pattern recognised a push planted there; the file was simply never opened, so the gate printed
// "passed".

function fixtureRoot(files) {
    const root = mkdtempSync(path.join(tmpdir(), 'release-pushes-'));
    for (const [rel, body] of Object.entries(files)) {
        const full = path.join(root, rel);
        mkdirSync(path.dirname(full), { recursive: true });
        writeFileSync(full, body);
    }
    return root;
}

test('a push in scripts/ is found — that is where release automation lives now', () => {
    const root = fixtureRoot({ 'scripts/release-helper.mjs': "execSync('git push origin HEAD:main');\n" });
    const violations = runCheck(root);
    assert.equal(violations.length, 1, 'scripts/ must be scanned: publish.yml runs node scripts/*.mjs');
    assert.match(violations[0], /scripts\/release-helper\.mjs/);
});

// The literal spelling a reintroduction would most plausibly take if someone copied it back into a
// workflow step: a bare `git push origin main`, not the `HEAD:main` refspec form exercised above.
// Pinned separately per Review Focus 4 ("re-adding a `git push origin main` line to any scanned
// file must fail it") — the runCheck path (directory walk + exemption set), not just the regex.
test('a bare `git push origin main` reintroduced into any scanned file is found by runCheck', () => {
    const root = fixtureRoot({ '.github/workflows/release.yml': 'run: git push origin main\n' });
    const violations = runCheck(root);
    assert.equal(violations.length, 1);
    assert.match(violations[0], /\.github\/workflows\/release\.yml/);
    assert.match(violations[0], /main/);
});

test('the scanned list covers every directory the release path actually runs from', () => {
    assert.ok(SCANNED_DIRS.includes('scripts'), 'publish.yml runs `node scripts/sync-app-version.mjs`');
    assert.ok(SCANNED_DIRS.includes('.github/workflows'));
    assert.ok(SCANNED_DIRS.includes('.github/scripts'));
    assert.ok(SCANNED_DIRS.includes('ci'), 'kept as a tripwire for a directory that must not come back');
});

// The gate's own spec is the one file in the repository that must contain protected-branch push
// strings, because they are the fixtures that prove the recogniser works. It is excluded BY NAME
// rather than by a `*.spec.mjs` rule: a class rule would let a real push hide in any spec, which is
// exactly the bypass this gate exists to close, and a named file fails loudly if it is renamed.
test('the gate does not fail on its own fixtures, and that exemption is exactly one file', () => {
    assert.deepEqual([...EXCLUDED_FILES], ['scripts/check-release-pushes.spec.mjs']);
});

test('the exemption does not extend to other specs under scripts/', () => {
    const root = fixtureRoot({ 'scripts/something-else.spec.mjs': "git push origin HEAD:next\n" });
    assert.equal(runCheck(root).length, 1, 'only the gate\'s OWN spec is exempt');
});

// ── The list itself ─────────────────────────────────────────────────────────────────────────────

test('the protected-branch list is main and next', () => {
    assert.deepEqual([...PROTECTED_BRANCHES].sort(), ['main', 'next']);
});

test('the repository has no protected-branch push in its release path', () => {
    const violations = runCheck(REPO_ROOT);
    assert.deepEqual(violations, [], violations.join('\n'));
});

// ── The entry-point guard must survive a symlinked invocation path ─────────────────────────────────
//
// `process.argv[1] === fileURLToPath(import.meta.url)` compares the UNRESOLVED invoked path against
// the RESOLVED module path, so invoking via a symlink makes the guard permanently false, main() never
// runs, and the process exits 0 with zero output — "Release-push gate passed" never prints, and
// neither does a violation list, either way silently. check-release-seed-cadence.mjs already carries
// the realpath fix for this; this pins the same fix here.
test('main() still runs when the script is invoked through a symlink', () => {
    const fixture = realpathSync(mkdtempSync(path.join(tmpdir(), 'check-release-pushes-symlink-')));
    try {
        mkdirSync(path.join(fixture, 'scripts'), { recursive: true });
        copyFileSync(path.join(REPO_ROOT, 'scripts', 'check-release-pushes.mjs'), path.join(fixture, 'scripts', 'check-release-pushes.mjs'));
        const symlinkPath = path.join(fixture, 'invoke-via-symlink.mjs');
        symlinkSync(path.join(fixture, 'scripts', 'check-release-pushes.mjs'), symlinkPath);
        const result = spawnSync(process.execPath, [symlinkPath], { encoding: 'utf8' });
        assert.equal(result.status, 0, `main() did not run as expected:\n${result.stdout}${result.stderr}`);
        assert.match(result.stdout, /Release-push gate passed/, 'a silent, empty exit 0 is the bug this pins against');
    } finally {
        rmSync(fixture, { recursive: true, force: true });
    }
});
