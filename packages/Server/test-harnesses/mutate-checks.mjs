/**
 * Mutation driver for @mj-biz-apps/common-server.
 *
 * WHY THIS FILE EXISTS. `LoadLiveMailboxPolicyFromEnv` is the single most consequential function in
 * this package: it is what turns on reading real mailboxes, and app-only `Mail.Read` reads EVERY
 * mailbox in the tenant. It had 40 tests and no permanent mutation check, so nothing said whether
 * those tests could fail. They could not, for two of its guards — deleting the mutual-exclusion
 * check and deleting the neither-decision check both left all 40 green.
 *
 * That is the same shape as everything else this branch was opened to remove: a check that documents
 * its own purpose and has no reader. A suite that cannot fail is not evidence, and the gate is
 * exactly where being wrong about that is worst.
 *
 * Restores from a copy, not git, so a dirty tree is safe.
 *
 *   node test-harnesses/mutate-checks.mjs
 *   node test-harnesses/mutate-checks.mjs M-LMP3
 *   node test-harnesses/mutate-checks.mjs --check-anchors
 *
 * `--check-anchors` only asserts every anchor matches exactly once, without mutating or running
 * vitest. It takes well under a second, so build.yml runs it on every PR: a stale anchor is how
 * mutation harnesses in this repo have rotted before, and a SKIP should fail the change that caused
 * it. The full run is in mutants.yml.
 */
import { spawn } from 'node:child_process';
import { copyFileSync, readFileSync, writeFileSync, rmSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const PKG = join(dirname(fileURLToPath(import.meta.url)), '..');

const POLICY = 'src/custom/live-mailbox-policy.ts';
// The calendar changeset enumerated "refusing to serve the calendar driver" among mutations that
// are "all caught", and nothing was registered for this file. It is the seam that decides WHICH
// transport a surface gets, and getting it wrong reports a successful, empty calendar.
const FACTORY = 'src/custom/graph-transport-factory.ts';
// The wiring. Both loaders had thorough unit tests and nothing checked that anything CALLS them;
// commenting out either line left all 43 tests green.
const BOOTSTRAP = 'src/index.ts';

const PRODUCT = [
    /**
     * NOT OPTED IN IS SILENT; PARTIALLY OPTED IN IS NOT. Collapsing the two in either direction is a
     * real failure: a noisy no-op on every unconfigured host, or a half-written opt-in that stays off
     * and sends an operator hunting through Exchange for a fault that is in their .env.
     */
    {
        id: 'M-LMP1',
        file: POLICY,
        expect: ['stays refused on an empty environment, without complaining'],
        from: '    if (present.length === 0) {',
        to: '    if (false) {',
    },
    {
        id: 'M-LMP2',
        file: POLICY,
        expect: ['throws when'],
        from: '    if (missingAlways.length > 0) {',
        to: '    if (false) {',
    },
    /**
     * THE TWO DECISIONS. Both of these survived before the tests beside them existed, which is how
     * they came to be written.
     */
    {
        id: 'M-LMP3',
        file: POLICY,
        expect: ['refuses a host that claims BOTH a group and an accepted tenant-wide risk'],
        from: '    if (group && acceptedRisk) {',
        to: '    if (false) {',
    },
    {
        id: 'M-LMP4',
        file: POLICY,
        expect: ['refuses a host that names a person and a date but neither decision'],
        from: '    if (!group && !acceptedRisk) {',
        to: '    if (false) {',
    },
    /**
     * The DISCRIMINANT, not the value. An earlier version of this mutant rewrote the true branch to
     * `group || acceptedRisk`, which is inert inside a `group ? ...` ternary -- it survived by being
     * a no-op rather than by escaping a check. This one files a knowingly-unrestricted tenant as a
     * restricted one, which is the way round that actually matters: it would make an audit read
     * "scoped to a group" where nobody scoped anything.
     */
    {
        id: 'M-LMP5',
        file: POLICY,
        expect: ['records an accepted tenant-wide grant as tenant-wide'],
        from: "            : { ...common, Scope: 'TenantWideAccepted', AcceptedRisk: acceptedRisk },",
        to: "            : { ...common, Scope: 'RestrictedToGroup', ScopedToGroup: acceptedRisk },",
    },
    /** A date nobody can read is not a date. `ConfirmedAt` exists so staleness is visible. */
    {
        id: 'M-LMP6',
        file: POLICY,
        expect: ['rejects a confirmation date that is not a date'],
        from: '    if (Number.isNaN(confirmedAt.getTime())) {',
        to: '    if (false) {',
    },
    /** Blank is not "set". An empty var in a .env template must never read as an opt-in. */
    {
        id: 'M-LMP7',
        file: POLICY,
        expect: ['treats blank and whitespace-only variables as absent'],
        from: "    const set = (k: string) => (env[k] ?? '').trim();",
        to: "    const set = (k: string) => env[k] ?? '';",
    },
    /**
     * SAYING IT OUT LOUD IS PART OF THE FEATURE. Without the bootstrap line the attestation is
     * written and read by nothing, which is the defect this whole branch is about.
     */
    {
        id: 'M-LMP8',
        file: POLICY,
        expect: ['enabling live fetch is announced at bootstrap'],
        from: '    LogStatus(',
        to: '    (() => undefined)(',
    },
    /**
     * MJAPI STARTUP. `DynamicPackageLoader` calls `LoadBizAppsCommonServer`, and these two lines are
     * the only thing that makes either registry in this branch reachable on a real host. Neither
     * omission is loud: without the policy load a correctly configured host is refused and told to
     * set the variables it already set; without the factory no connection ever gets a transport.
     */
    {
        id: 'M-BOOT1',
        file: BOOTSTRAP,
        expect: ['reads this host attestation from the environment'],
        from: '    LoadLiveMailboxPolicyFromEnv();',
        to: '    void LoadLiveMailboxPolicyFromEnv;',
    },
    {
        id: 'M-BOOT2',
        file: BOOTSTRAP,
        expect: ['registers the Graph transport factory'],
        from: '    LoadGraphTransportFactory();',
        to: '    void LoadGraphTransportFactory;',
    },
    /**
     * The registration that keeps the content cipher from being another `ActivityFileSink` — a seam
     * exported, documented and filled by nobody. That is the whole argument for shipping the interface
     * with an implementation, so the test making it true needs a mutant like every other claim here.
     */
    {
        id: 'M-BOOT3',
        file: BOOTSTRAP,
        expect: ['registers the content cipher'],
        from: '    LoadActivityContentCipher();',
        to: '    void LoadActivityContentCipher;',
    },
    /**
     * THE SURFACE DISPATCH. One connection drives two surfaces from the same type row, and this
     * is what decides which transport each gets. Handing the calendar pass a MAIL transport fed
     * message payloads to the event mapper and dropped every one for having no start time --
     * reported as a successful, EMPTY calendar, which is indistinguishable from a real one.
     */
{
        id: 'M-GTF1',
        file: FACTORY,
        expect: ['serves the calendar driver, not just the message one'],
        from: '    const isCalendar = context.DriverClass === MICROSOFT_365_CALENDAR;',
        to: '    const isCalendar = false;',
    },
    {
        id: 'M-GTF2',
        file: FACTORY,
        expect: ['builds the message transport for the message driver'],
        from: '    if (isCalendar) {',
        to: '    if (isMail || isCalendar) {',
    },
    {
        id: 'M-GTF3',
        file: FACTORY,
        expect: ['returns null for a driver it does not serve'],
        from: '    if (!isMail && !isCalendar) {',
        to: '    if (false) {',
    },
    {
        id: 'M-GTF4',
        file: FACTORY,
        expect: ['still needs a credential for the calendar surface too'],
        from: '    if (!credentialName) {',
        to: '    if (false) {',
    },
    {
        id: 'M-GTF5',
        file: FACTORY,
        expect: ['trims the credential name before resolving it'],
        from: "    const credentialName = (context.CredentialsRef ?? '').trim();",
        to: "    const credentialName = context.CredentialsRef ?? '';",
    },
];

// Overridable so this harness's own tests can swap `pnpm exec vitest run` for something fast and
// signal-safe (e.g. a `node` sleep) without ever invoking a real vitest run.
const TEST_COMMAND = process.env.MUTATE_CHECKS_TEST_COMMAND ?? 'pnpm exec vitest run';
if (process.env.MUTATE_CHECKS_TEST_COMMAND) {
    // A stray value left set (or a command crafted to echo an `expect` string and exit nonzero)
    // reports a full, silent fake pass -- mutants aren't being checked against the real suite at
    // all. Unconditional and printed before anything else runs, so it can't be missed regardless
    // of which mode (--list, --check-anchors, or a real run) this invocation takes.
    console.error(`WARNING: MUTATE_CHECKS_TEST_COMMAND is set to "${TEST_COMMAND}" -- mutants are NOT being checked against the real suite.`);
}

// Tracks the mutant currently on disk and its suite's child process, so the SIGINT/SIGTERM
// handlers below -- which live outside the loop that owns these -- can still restore the file and
// forward/kill the child.
let activeChild = null;
let activeRestore = null;

/**
 * Runs the suite as a real, killable child process instead of execSync's blocking wait. A blocking
 * wait can't be interrupted: SIGINT/SIGTERM couldn't reach this script's JS until the child exited
 * on its own, which is how a mutated file used to survive a Ctrl-C. Resolves (never rejects) on a
 * failing suite -- a nonzero exit IS the expected "felled" case -- matching how the loop reads it.
 */
function runTestCommand() {
    return new Promise((resolve, reject) => {
        // `detached: true` makes this child (the shell wrapping TEST_COMMAND) the leader of its
        // own process group, so a real `pnpm exec vitest run`'s own child inherits that group
        // instead of the harness's. killChildGroup below relies on that to reach it.
        const child = spawn(TEST_COMMAND, { cwd: PKG, shell: true, stdio: ['ignore', 'pipe', 'pipe'], detached: true });
        activeChild = child;
        let output = '';
        child.stdout.on('data', (chunk) => { output += chunk; });
        child.stderr.on('data', (chunk) => { output += chunk; });
        child.on('error', (err) => {
            activeChild = null;
            reject(err);
        });
        // 'close', not 'exit': stdio can still be open when 'exit' fires (Node docs), so 'exit'
        // can race the last 'data' events and resolve with a truncated `output`. 'close' fires
        // once the streams are actually done.
        child.on('close', (code) => {
            activeChild = null;
            resolve({ threw: code !== 0, output });
        });
    });
}

// A plain `child.kill(signal)` reaches only the direct child -- with `shell: true`, a real
// `pnpm exec vitest run` spawns its own vitest process as a grandchild, which a single-pid kill
// orphans instead of stopping. `detached: true` above makes `child.pid` the process group id too,
// so the negative-pid form signals the whole group. ESRCH (already exited) is expected and quiet;
// anything else is surfaced rather than swallowed, since we're already mid-shutdown and cannot
// retry.
function killChildGroup(child, signal) {
    if (!child) return;
    try {
        process.kill(-child.pid, signal);
    } catch (err) {
        if (err.code !== 'ESRCH') {
            console.error(`Failed to signal the test command's process group: ${err.message}`);
        }
    }
}

// The file's own doc comment promises a dirty tree is safe no matter how the run ends. Without
// these, the default disposition for SIGINT/SIGTERM kills the process instantly -- no listener, no
// finally -- leaving whatever mutant is on disk right where the mutation loop wrote it.
function shutdown(signal, exitCode) {
    return () => {
        killChildGroup(activeChild, signal);
        if (activeRestore) activeRestore();
        process.exit(exitCode);
    };
}
process.on('SIGINT', shutdown('SIGINT', 130));
process.on('SIGTERM', shutdown('SIGTERM', 143));

const wanted = process.argv.slice(2).filter((a) => a !== '--list' && a !== '--check-anchors');

// A caller asking for a specific mutant (or passing an unsupported flag) that doesn't exist is a
// typo, not "nothing to do" -- filtering it to an empty selection used to report a vacuous, silent
// pass (`0 mutant(s) proved their checks can fail.`, exit 0). Name what wasn't recognized and fail.
// Checked before --list/--check-anchors's own early exits below: those used to run first, so a
// bogus extra arg alongside either flag (e.g. `--check-anchors BOGUS`) passed silently.
const knownIds = new Set(PRODUCT.map((m) => m.id));
const unknown = wanted.filter((arg) => !knownIds.has(arg));
if (unknown.length) {
    console.error(`Unrecognized argument(s): ${unknown.join(', ')}. Expected --list, --check-anchors, or a mutant ID from --list.`);
    process.exit(1);
}

if (process.argv.includes('--list')) {
    for (const m of PRODUCT) console.log(`${m.id}  ${m.file}  expect: ${m.expect.join(', ')}`);
    process.exit(0);
}
if (process.argv.includes('--check-anchors')) {
    let stale = 0;
    for (const m of PRODUCT) {
        // Matched exactly as the mutation loop below does, so the two cannot disagree.
        const count = readFileSync(join(PKG, m.file), 'utf8').split(m.from).length - 1;
        if (count !== 1) {
            console.error(`SKIP ${m.id}: anchor matched ${count} times in ${m.file}`);
            stale++;
        }
    }
    if (stale > 0) {
        console.error(`\n${stale} of ${PRODUCT.length} anchor(s) do not match exactly once.`);
        process.exit(1);
    }
    console.log(`${PRODUCT.length} anchor(s) match exactly once.`);
    process.exit(0);
}

const selected = wanted.length ? PRODUCT.filter((m) => wanted.includes(m.id)) : PRODUCT;
let failed = 0;

for (const m of selected) {
    const dir = mkdtempSync(join(tmpdir(), `mut-${m.id}-`));
    const backup = join(dir, 'backup');
    const full = join(PKG, m.file);
    copyFileSync(full, backup);
    const original = readFileSync(full, 'utf8');
    const count = original.split(m.from).length - 1;
    if (count !== 1) {
        copyFileSync(backup, full);
        rmSync(dir, { recursive: true, force: true });
        console.error(`SKIP ${m.id}: anchor matched ${count} times in ${m.file}`);
        failed++;
        continue;
    }
    writeFileSync(full, original.replace(m.from, m.to));
    // Bundles both cleanups the signal handlers must also be able to run: restoring the source
    // AND removing this mutant's mkdtemp backup dir -- previously only the restore happened on
    // the signal path, leaking the temp dir every time a run was interrupted.
    activeRestore = () => {
        copyFileSync(backup, full);
        rmSync(dir, { recursive: true, force: true });
    };
    let result;
    try {
        result = await runTestCommand();
    } catch (err) {
        // The child never started at all (bad cwd, resource limits, ...) rather than a felled or
        // surviving mutant -- surfaced the same way a failing suite is (via `output`, printed
        // below whenever `expect` isn't found in it), with the command named since `err.message`
        // alone usually doesn't mention what we tried to run.
        result = { threw: true, output: `could not run "${TEST_COMMAND}": ${err.message ?? err}` };
    } finally {
        activeRestore();
        activeRestore = null;
    }

    const restored = readFileSync(full, 'utf8');
    if (restored !== original) {
        writeFileSync(full, original);
        console.error(`FAIL ${m.id}: restore did not match the copy`);
        failed++;
        continue;
    }

    if (!result.threw) {
        console.error(`FAIL ${m.id}: suite stayed green`);
        failed++;
        continue;
    }
    const missing = m.expect.filter((name) => !result.output.includes(name));
    if (missing.length) {
        console.error(`FAIL ${m.id}: failed but did not name ${missing.join(', ')}`);
        // Previously discarded: `result.output` is compared against `expect` above but was never
        // itself printed, so a broken command (or a suite failing for an unrelated reason) read
        // as an unhelpful "did not name X" with no clue why.
        if (result.output.trim()) console.error(result.output.trim());
        failed++;
        continue;
    }
    console.log(`OK   ${m.id}: felled ${m.expect.join(', ')}`);
}

if (failed > 0) {
    console.error(`\n${failed} mutant(s) did not prove their check.`);
    process.exit(1);
}
console.log(`\n${selected.length} mutant(s) proved their checks can fail.`);
