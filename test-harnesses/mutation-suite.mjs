/**
 * The part of a package's `test-harnesses/mutate-checks.mjs` that is not about its mutants: running
 * the suite against one mutant at a time, and never leaving a mutant on disk however the run ends.
 * Both harnesses (packages/Server, packages/ActivitySync) import it, so a fix to it lands in both;
 * they carried byte-identical copies before, which is how the next fix would have drifted.
 *
 * What it guarantees, each pinned by the harnesses' own specs:
 *   - the suite is a real, killable child process in its own process group, so SIGINT/SIGTERM reach
 *     vitest's grandchild and not only the shell;
 *   - on SIGINT/SIGTERM the mutated file is restored before exit (130 / 143);
 *   - a suite that cannot start is reported with the command named, never read as a felled mutant;
 *   - output is read on 'close', not 'exit', so it is never truncated;
 *   - MUTATE_CHECKS_TEST_COMMAND (the specs' seam) prints a warning whenever it is set;
 *   - an argument that is neither a flag nor a known mutant ID fails the run instead of selecting
 *     nothing and reporting a vacuous pass.
 */
import { spawn } from 'node:child_process';

/**
 * Validates the harness's arguments against its mutant IDs, before --list / --check-anchors take
 * their early exits (those used to run first, so `--check-anchors BOGUS` passed silently). Returns
 * the mutant IDs asked for; exits 1 naming anything unrecognised.
 */
export function requireKnownMutants(argv, mutants) {
    const wanted = argv.filter((a) => a !== '--list' && a !== '--check-anchors');
    const knownIds = new Set(mutants.map((m) => m.id));
    const unknown = wanted.filter((arg) => !knownIds.has(arg));
    if (unknown.length) {
        console.error(`Unrecognized argument(s): ${unknown.join(', ')}. Expected --list, --check-anchors, or a mutant ID from --list.`);
        process.exit(1);
    }
    return wanted;
}

/**
 * Sets up the suite runner for the package at `pkgDir` and installs the signal handlers. Call once,
 * before anything else runs, so the override warning is the first thing printed.
 */
export function createSuiteRunner(pkgDir) {
    const command = process.env.MUTATE_CHECKS_TEST_COMMAND ?? 'pnpm exec vitest run';
    if (process.env.MUTATE_CHECKS_TEST_COMMAND) {
        // A stray value left set (or a command crafted to echo an `expect` string and exit nonzero)
        // reports a full, silent fake pass -- mutants aren't being checked against the real suite.
        console.error(`WARNING: MUTATE_CHECKS_TEST_COMMAND is set to "${command}" -- mutants are NOT being checked against the real suite.`);
    }

    // The mutant on disk and its suite's child, so the signal handlers -- which live outside the loop
    // that owns them -- can still restore the file and kill the child.
    let activeChild = null;
    let activeRestore = null;

    /** The suite as a killable child in its own process group; resolves on any exit code. */
    function runSuite() {
        return new Promise((resolve, reject) => {
            const child = spawn(command, { cwd: pkgDir, shell: true, stdio: ['ignore', 'pipe', 'pipe'], detached: true });
            activeChild = child;
            let output = '';
            child.stdout.on('data', (chunk) => { output += chunk; });
            child.stderr.on('data', (chunk) => { output += chunk; });
            child.on('error', (err) => {
                activeChild = null;
                reject(err);
            });
            // 'close', not 'exit': stdio can still be open when 'exit' fires, so 'exit' can race the
            // last 'data' events and resolve with a truncated `output`.
            child.on('close', (code) => {
                activeChild = null;
                resolve({ threw: code !== 0, output });
            });
        });
    }

    // `detached: true` makes child.pid the process-group id, so the negative pid reaches vitest's own
    // child too. ESRCH (already exited) is expected; anything else is surfaced, not swallowed.
    function killChildGroup(signal) {
        if (!activeChild) return;
        try {
            process.kill(-activeChild.pid, signal);
        } catch (err) {
            if (err.code !== 'ESRCH') {
                console.error(`Failed to signal the test command's process group: ${err.message}`);
            }
        }
    }

    // Without these the default SIGINT/SIGTERM disposition kills the process instantly, leaving the
    // mutant on disk where the loop wrote it.
    const shutdown = (signal, exitCode) => () => {
        killChildGroup(signal);
        if (activeRestore) activeRestore();
        process.exit(exitCode);
    };
    process.on('SIGINT', shutdown('SIGINT', 130));
    process.on('SIGTERM', shutdown('SIGTERM', 143));

    return {
        command,
        /**
         * Runs the suite against the mutant already on disk, and runs `restore` afterwards on every
         * path: normal exit, a suite that could not start, or a signal mid-run. Returns
         * `{ threw, output }`; a suite that could not start is `threw: true` with the command named.
         */
        async runAgainstMutant(restore) {
            activeRestore = restore;
            try {
                return await runSuite();
            } catch (err) {
                return { threw: true, output: `could not run "${command}": ${err.message ?? err}` };
            } finally {
                activeRestore = null;
                restore();
            }
        },
    };
}
