#!/usr/bin/env node
/**
 * Refuse any push to a ruleset-protected branch from the release path.
 *
 * Required status checks are evaluated against the check runs present on the SHA being introduced.
 * On a direct push that SHA does not exist on the remote until the push lands, so no check run can
 * exist for it yet — a direct push to a ref carrying `required_status_checks` is unsatisfiable by
 * construction, for any commit, with or without `[skip ci]`. It is not a race that a retry wins.
 *
 * Ported from bizapps-forms (MemberJunction/bizapps-forms#177): `ci/commit_push.mjs` pushed the
 * version-bump commit straight to `main` and `ci/merge_main_and_update_lock.mjs` pushed straight to
 * `next`, and once MemberJunction/bizapps-forms#173 added required status checks to both of that
 * repo's rulesets, every release there stopped at the version-bump step with GH013. The fix was to
 * stop pushing; that gate is what keeps it fixed there, because reintroducing such a push breaks
 * nothing until the next release — months later, in someone else's pull request.
 *
 * bizapps-common is ported ahead of hitting that failure itself, not after it. CLAUDE.md's
 * "Branching Model" already says "Never commit directly to `main`. Always go through `next` first",
 * and this gate is what enforces that for the release automation's own pushes — independent of
 * which of this repo's rulesets carry required status checks on any given day.
 *
 * Plain Node, stdlib only, matching `check-release-seed-coverage.mjs`: a gate that guards the
 * release must be runnable in CI without installing anything.
 */
import { readdirSync, readFileSync, statSync, realpathSync } from 'node:fs';
import { join, relative, dirname, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

/**
 * The two branches this repository's release flow must never be pushed to directly (see CLAUDE.md's
 * "Branching Model": `main` is the release branch, `next` is the integration branch). Pinned in the
 * spec, because the gate is exactly as good as this list.
 */
export const PROTECTED_BRANCHES = Object.freeze(['main', 'next']);

/**
 * Where release automation lives. Deliberately whole directories rather than the files that happen
 * to be guilty today — the point is that a *new* file cannot reintroduce the push.
 *
 * `scripts/` earns its place from this change itself: this port deletes `ci/` and moves the release
 * derivation into `scripts/sync-app-version.mjs`, which `publish.yml` runs with `--check` and which
 * the root `version` script runs on the release pull request. A list that omitted it would have
 * guarded the directory release automation just LEFT while ignoring the one it moved to — exactly
 * the gap bizapps-forms' own review found (MemberJunction/bizapps-forms#187) after making the same
 * move there.
 *
 * `ci/` stays although the directory is gone. `filesUnder` returns [] for ENOENT, so an absent path
 * is inert, and the entry is a tripwire for a directory that must fail this gate if it comes back.
 */
export const SCANNED_DIRS = Object.freeze(['.github/workflows', '.github/scripts', 'scripts', 'ci']);

/**
 * The one file allowed to contain protected-branch push strings: this gate's own spec, where they
 * are the fixtures that prove the recogniser works.
 *
 * Excluded BY NAME, not by a `*.spec.mjs` rule. A class rule would let a real push hide in any spec
 * file — precisely the bypass this gate exists to close — whereas a named file fails loudly if it is
 * ever renamed, which is the failure direction to prefer. It is deliberately a list of one; a second
 * entry should have to justify itself here.
 */
export const EXCLUDED_FILES = Object.freeze(['scripts/check-release-pushes.spec.mjs']);

const PROTECTED_ALTERNATION = PROTECTED_BRANCHES.join('|');

/**
 * A refspec target naming a protected branch, and nothing else.
 *
 * The trailing boundary is load-bearing twice over: `mainline` and `next-steps` are ordinary
 * feature branches, and a name that merely begins with a protected one is not that branch.
 *
 * The quote class after `refs/heads/` is for the shell's other concatenation point: a refspec can
 * be quoted as a whole (`"refs/heads/main"`, handled by `REFSPEC_PREFIX`) or only in part
 * (`refs/heads/"main"`). Over-inclusiveness costs nothing here — a needless match is one line a
 * human reads — while under-inclusiveness is the entire bug this gate exists to prevent.
 */
const PROTECTED_TARGET = String.raw`(?:refs\/heads\/['"\`]*)?(${PROTECTED_ALTERNATION})(?![\w./-])`;

/**
 * Where a command can BEGIN. Line start, or any character that ends the command before it.
 *
 * This deliberately does not anchor to the start of the line. An earlier version did — allowing
 * only leading whitespace, a YAML list dash and a `run: ` prefix — which meant a push was invisible
 * unless it was the first token on its line, so `git checkout next && git push origin next`,
 * `git config user.name x; git push origin main` and `execSync('git push origin HEAD:main')` all
 * walked past. The last one matters most: BOTH of MemberJunction/bizapps-forms#177's pushes lived in
 * Node scripts, and the deleted `ci/merge_main_and_update_lock.mjs` already shelled out through
 * `execSync`, so that is the likeliest spelling a reintroduction would take.
 *
 * Keeping prose and commented-out history out — of which this repo has a great deal, on purpose —
 * was the anchor's stated job, but `isCommentary` already does it and is the only thing that needs
 * to. Quotes are command starts because a shelled-out command is a string literal.
 */
const COMMAND_START = String.raw`(?:^|[\s;&|(\`'"])\s*`;

/**
 * git's GLOBAL OPTIONS, between `git` and the subcommand. Without this segment they are a straight
 * bypass: `git -c user.email=x push origin main` is ordinary CI, and this repository's publish
 * workflow already runs a separate `git config --global user.email` step that an author could fold
 * into the push exactly that way.
 *
 * Lifted verbatim in shape from bizapps-forms' `.claude/hooks/require-green-before-git.mjs` (this
 * repository has no such hook), which found and fixed this same under-inclusiveness first; its
 * docstring is the reasoning. Two arms, because `-C <dir>` and friends put their value in a
 * SEPARATE word and would otherwise break the chain, while the general `-\S+\s+` arm means an
 * unknown option can never cause a miss. The flat form is also deliberate: the obvious
 * `(?:-\S+(?:\s+\S+)?\s+)*` backtracks exponentially on non-matching input.
 */
const GIT_GLOBAL_OPTS =
    String.raw`(?:(?:-[Cc]|--(?:git-dir|work-tree|exec-path|namespace|config-env|attr-source))[=\s]\S+\s+|-\S+\s+)*`;

/**
 * `git push … <protected>` in shell, with or without a `HEAD:` / `<local>:` prefix and any flags.
 *
 * `\s+\S+\s+` between `push` and the target is the REMOTE, and requiring it is what keeps
 * `git push main` — which pushes to a remote *named* main — and a bare `git push` out. Neither
 * names a protected branch; a bare push's destination is its upstream, which no static reader can
 * know. Case-insensitive because macOS and Windows both mount case-insensitively, so `Git push`
 * really does invoke git here.
 *
 * `REFSPEC_PREFIX` is what a refspec may carry before the branch name. Quotes are the reason it
 * exists: `git push origin "HEAD:main"` used to match, but only by accident — the `(?:\S*:)?` group
 * exists to skip a `<local>:` prefix, and on its way to the colon it happened to swallow the
 * opening quote too. A BARE quoted branch has no colon, so that group matched empty and the quote
 * landed exactly where the branch name had to start. The colon form working is precisely what hid
 * the bare form failing, and quoting a refspec argument is ordinary git usage, not a signal that
 * only a careful author would write it that way. `\+` is the ordinary force-push shorthand,
 * `git push origin +main`.
 */
const REFSPEC_PREFIX = String.raw`['"\`]*\+?(?:\S*:)?`;

const SHELL_PUSH = new RegExp(
    COMMAND_START + String.raw`git\s+` + GIT_GLOBAL_OPTS +
        String.raw`push\b(?:\s+-{1,2}[\w-]+)*\s+\S+\s+` + REFSPEC_PREFIX + PROTECTED_TARGET,
    'i',
);

/**
 * simple-git's spelling of the same operation: `git.push('origin', 'HEAD:main')`.
 *
 * The optional `[` covers simple-git's array form, `git.push(['origin', 'HEAD:main'])`, which it
 * accepts identically.
 */
const METHOD_PUSH = new RegExp(
    String.raw`\.push\(\s*\[?\s*['"\`][^'"\`]+['"\`]\s*,\s*['"\`]\+?(?:\S*:)?` + PROTECTED_TARGET + String.raw`['"\`]`,
);

/**
 * A `git/refs/heads/<protected>` (or bare `refs/heads/<protected>`) REST ref target — the resource
 * `gh api` mutates when it updates a branch directly.
 *
 * Requires the `refs/heads/` segment, unlike PROTECTED_TARGET's use inside a push refspec above: a
 * bare branch name is unambiguous there because everything up to that point can only be a push
 * destination. Here the ref path is the ONLY signal that a `gh api` call touches a branch ref at
 * all, so a bare `main` — e.g. `-f base=main` on an unrelated pulls call — must not match.
 */
const GH_API_REF_TARGET = new RegExp(String.raw`(?:git\/)?refs\/heads\/${PROTECTED_TARGET}`, 'i');

/**
 * `gh api` calls that update a protected branch's ref directly — REST's equivalent of `git push`,
 * and invisible to SHELL_PUSH/METHOD_PUSH above because it is not a `git push` (or simple-git call)
 * at all. Required status checks are evaluated against the SHA `git push` is introducing (this
 * file's header); a `gh api` PATCH/POST to `.../git/refs/heads/<branch>` mutates the same ref through
 * the REST API, which carries no such constraint, so GH013 never triggers on it.
 *
 * `gh` and `api` are matched as independent word-bounded tokens rather than `gh\s+api`, because the
 * likeliest reintroduction — `execFileSync('gh', ['api', …])`, mirroring the Node-script spelling
 * MemberJunction/bizapps-forms#177's own pushes used — puts them in separate array elements, not
 * adjacent shell words. Neither flag is anchored to `-X PATCH`/`-X POST`: `gh api` defaults to POST
 * once any `-f`/`-F`/`--input` field is present, so a script relying on that default carries no `-X`
 * at all, and a GET on the same path is over-matched too. That is the trade-off PROTECTED_TARGET's
 * own comment already states for this file: a needless match costs a human one line to read, and
 * under-matching is the entire bug this gate exists to prevent.
 */
function findGhApiRefUpdate(line) {
    if (!/\bgh\b/i.test(line) || !/\bapi\b/i.test(line)) {
        return null;
    }
    return GH_API_REF_TARGET.exec(line);
}

/** True when the line is commented out — history and prose, not an instruction. */
function isCommentary(line) {
    return /^\s*(?:#|\/\/|\*|<!--)/.test(line);
}

/**
 * Backslash-continued shell lines joined into one logical line, as `{ line, text }` — `line` is the
 * FIRST physical line of the continuation, which is where a reader looking for "where is this
 * command" will look.
 *
 * A `run: |` block's shell `\` continuation is otherwise invisible to line-by-line scanning:
 * `git push origin \` and `  HEAD:main` are two lines, and this file's own "single-line by nature"
 * assumption for a push (see the comment above `findProtectedPushes`) covers only the refspec
 * argument, not the shell line it is written on.
 */
function joinContinuedLines(text) {
    const rawLines = text.split('\n');
    const logical = [];
    let buffer = null;
    let firstLine = 0;
    for (let i = 0; i < rawLines.length; i++) {
        const raw = rawLines[i];
        const continues = /\\\s*$/.test(raw);
        // The trailing `\` (and any whitespace after it) becomes a single space, mirroring the
        // shell's own line-join — the next line's content follows immediately after.
        const stripped = continues ? raw.replace(/\\\s*$/, ' ') : raw;
        if (buffer === null) {
            firstLine = i + 1;
            buffer = stripped;
        } else {
            buffer += stripped;
        }
        if (!continues) {
            logical.push({ line: firstLine, text: buffer });
            buffer = null;
        }
    }
    if (buffer !== null) {
        // A trailing `\` on the file's LAST line has nothing left to join with — the file ends
        // mid-command. Reported as-is rather than dropped, so a malformed file is still scanned
        // instead of silently losing its last line.
        logical.push({ line: firstLine, text: buffer });
    }
    return logical;
}

/**
 * Every push to a protected branch in `text`, as `{ line, ref, snippet }`.
 *
 * Line-by-line (after joining `\`-continuations) rather than whole-file, so a violation can be
 * reported at a line number a reader can go to. The refspec argument itself does not wrap; the shell
 * LINE it is written on can, via `\`, which is what joining exists to undo before matching.
 */
export function findProtectedPushes(text) {
    const found = [];
    for (const { line, text: joined } of joinContinuedLines(text)) {
        if (isCommentary(joined)) {
            continue;
        }
        const match = SHELL_PUSH.exec(joined) ?? METHOD_PUSH.exec(joined) ?? findGhApiRefUpdate(joined);
        if (match) {
            found.push({ line, ref: match[1], snippet: joined.trim() });
        }
    }
    return found;
}

/** Every file under `dir`, recursively. Returns [] for a directory that does not exist. */
function filesUnder(dir) {
    let entries;
    try {
        entries = readdirSync(dir, { withFileTypes: true });
    } catch (error) {
        // ENOENT is the expected, correct answer for `ci/`, which this port deletes. Anything else —
        // a permission error, a file where a directory was — is a gate that cannot see what it is
        // guarding, and must not pass silently.
        if (error.code === 'ENOENT') {
            return [];
        }
        throw new Error(`check-release-pushes cannot read ${dir}: ${error.message}`, { cause: error });
    }
    return entries.flatMap((entry) => {
        const full = join(dir, entry.name);
        return entry.isDirectory() ? filesUnder(full) : statSync(full).isFile() ? [full] : [];
    });
}

/** Violations across the whole release path, as printable strings. */
export function runCheck(root) {
    const violations = [];
    const exempt = new Set(EXCLUDED_FILES);
    for (const dir of SCANNED_DIRS) {
        for (const file of filesUnder(join(root, dir))) {
            if (exempt.has(relative(root, file).split(sep).join('/'))) {
                continue;
            }
            for (const hit of findProtectedPushes(readFileSync(file, 'utf8'))) {
                violations.push(
                    `${relative(root, file)}:${hit.line}: pushes directly to '${hit.ref}', bypassing the pull ` +
                        `request this repository's release flow requires (CLAUDE.md's "Branching Model"). Once a ` +
                        `branch's ruleset carries required status checks — as bizapps-forms' did — such a push ` +
                        `is rejected permanently (GH013): the SHA it introduces has never been seen by the remote, ` +
                        `so no check run can exist for it yet. See MemberJunction/bizapps-forms#177. Route the ` +
                        `change through a pull request, or push a tag instead.\n      ${hit.snippet}`,
                );
            }
        }
    }
    return violations;
}

/** CLI entry point. */
function main() {
    const violations = runCheck(REPO_ROOT);
    if (violations.length > 0) {
        console.error('Release-push gate FAILED:\n');
        for (const v of violations) {
            console.error(`  ✗ ${v}\n`);
        }
        console.error(`${violations.length} violation(s).`);
        process.exit(1);
    }
    console.log(`Release-push gate passed (${SCANNED_DIRS.join(', ')}).`);
}

// Compared through realpath, not as a `file://` string: that string is never equal under a path with
// spaces (percent-encoded in the URL) or a symlink, and the gate would then silently exit 0.
if (process.argv[1] && realpathSync(process.argv[1]) === realpathSync(fileURLToPath(import.meta.url))) {
    main();
}
