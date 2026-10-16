/**
 * Typecheck this repo against the MemberJunction packages that are actually PUBLISHED, rather than
 * whatever the local workspace happens to be linked to.
 *
 * WHY THIS EXISTS. A build here can see three different MemberJunctions, and only one of them is what
 * CI and real consumers get:
 *
 *   1. MJ's `src`      - whatever is committed in the sibling checkout
 *   2. MJ's `dist`     - what the workspace symlink actually exposes, whose freshness is arbitrary:
 *                        it is only as new as the last time someone ran a build over there
 *   3. npm, PINNED     - the version `pnpm-lock.yaml` names, which is what CI installs
 *   4. npm, NEWEST     - the newest release the range in package.json admits
 *
 * `pnpm build` locally resolves (2). CI installs with `--frozen-lockfile`, so CI resolves (3).
 *
 * (3) and (4) are not the same version, and the gap is not academic. Every MemberJunction entry in
 * this lockfile is pinned at 6.1.0-edge.6, while the declared `^6.1.0-edge.6` admits 6.1.3 - four
 * releases apart, and 6.1.3 exports names edge.6 does not, `WellKnownUserSource` among them. An
 * earlier version of this script asked npm for (4). That meant it would pass a file using an API CI
 * cannot see: the exact failure it exists to prevent, reintroduced one level down. It reads the
 * lockfile now, and asks npm only for a name the lockfile does not carry. A run that had to fall
 * back to npm for any name reports INCONCLUSIVE rather than OK: newest-in-range is not what CI
 * installs, so a pass built on it would assert more than the run established.
 *
 * This script answers the only question that matters before pushing: does the source compile against
 * what is on npm today?
 *
 *   node scripts/check-against-published-mj.mjs                 # every workspace package
 *   node scripts/check-against-published-mj.mjs packages/Angular
 *   node scripts/check-against-published-mj.mjs --refresh       # ignore the cache
 *
 * Build the workspace first. This compiles each package's `src`, and that source imports its sibling
 * `@mj-biz-apps/*` packages, which resolve through their own `dist`. On an unbuilt tree those
 * imports fail, and the errors have nothing to do with MemberJunction - the run detects that case
 * and says so rather than filing it under unpublished API.
 *
 * Read-only with respect to the repo: published tarballs are cached under node_modules/.cache, the
 * generated tsconfig lives there too, and nothing in node_modules is relinked or mutated.
 */
import { createRequire } from 'node:module';
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, symlinkSync, writeFileSync } from 'node:fs';
import { dirname, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const CACHE = join(REPO, 'node_modules', '.cache', 'published-mj');
const SCOPE = '@memberjunction/';

const args = process.argv.slice(2);
const REFRESH = args.includes('--refresh');
const targets = args.filter((a) => !a.startsWith('--'));

const WIN = process.platform === 'win32';

/**
 * Windows needs `shell: true` for `.cmd` shims - Node refuses to spawn them directly (EINVAL) since
 * the CVE-2024-27980 fix. That means cmd.exe then parses the arguments, where `^` is an escape
 * character and every dependency range here begins with one, so each argument is quoted.
 */
function run(bin, cmdArgs, cwd) {
    const file = WIN ? `${bin}.cmd` : bin;
    const args = WIN ? cmdArgs.map((a) => `"${a}"`) : cmdArgs;
    return execFileSync(file, args, {
        cwd,
        encoding: 'utf8',
        shell: WIN,
        stdio: ['ignore', 'pipe', 'pipe'],
        maxBuffer: 64 * 1024 * 1024,
    }).trim();
}

const npm = (cmdArgs, cwd) => run('npm', cmdArgs, cwd);

function readJSON(path) {
    return JSON.parse(readFileSync(path, 'utf8'));
}

/** Workspace packages that declare at least one MemberJunction dependency. */
function packagesToCheck() {
    if (targets.length) {
        return targets.map((t) => {
            const dir = resolve(REPO, t);
            if (!existsSync(join(dir, 'package.json'))) {
                console.error(`No such package: ${t} (missing ${join(dir, 'package.json')})`);
                process.exit(1);
            }
            return dir;
        });
    }
    const root = join(REPO, 'packages');
    return readdirSync(root)
        .map((d) => join(root, d))
        .filter((d) => existsSync(join(d, 'package.json')) && existsSync(join(d, 'tsconfig.json')))
        .filter((d) => Object.keys(allDeps(readJSON(join(d, 'package.json')))).some((k) => k.startsWith(SCOPE)));
}

/** What WE install: dev included, because our own build uses them. */
const allDeps = (pkg) => ({ ...pkg.dependencies, ...pkg.devDependencies, ...pkg.peerDependencies });

/**
 * What a CONSUMER of a published package installs. npm never installs a dependency's
 * devDependencies, so walking them invents transitive work and reports misses that can never
 * affect anyone - `@memberjunction/ng-test-utils`, published only as a 0.0.1 placeholder, is a
 * devDependency of a dozen MJ packages and would otherwise be reported as missing every run.
 */
const runtimeDeps = (pkg) => ({ ...pkg.dependencies, ...pkg.peerDependencies });

/**
 * WHAT CI INSTALLS, read from pnpm-lock.yaml.
 *
 * `npm view <name>@<range> version` answers "the newest release the range admits", and nobody
 * installs that. CI runs `--frozen-lockfile`, so CI installs the version the lockfile names.
 *
 * The lockfile is YAML and this repo has no YAML parser, so this reads only the three shapes pnpm v9
 * writes a resolved version in, each confined to the section it appears in:
 *
 *   importers:   '@memberjunction/core':               a key, then `version:` on a later line
 *                  specifier: ^6.1.0-edge.6
 *                  version: 6.1.0-edge.6
 *   packages:    '@memberjunction/core@6.1.0-edge.6':            the version is inside the key
 *   snapshots:   '@memberjunction/core': 6.1.0-edge.6            inline, under a dependencies map
 *
 * A value that is not a concrete version is skipped, so the `^6.1.0-edge.6` sitting in `overrides`,
 * and any `link:` or `workspace:`, are never mistaken for a pin.
 */
function readLockfile() {
    const path = join(REPO, 'pnpm-lock.yaml');
    const byImporter = new Map(); // 'packages/Angular' -> Map<name, version>
    const everywhere = new Map(); // name -> Set<version>
    if (!existsSync(path)) return { byImporter, everywhere, present: false };

    const add = (importerMap, name, raw) => {
        // `6.1.0-edge.6(typescript@5.4.5)` - the peer suffix is not part of the version
        const version = raw.trim().replace(/\(.*$/, '').replace(/^['"]|['"]$/g, '').trim();
        if (!/^\d/.test(version)) return; // a range, link:, workspace:, file: - not a pin
        if (importerMap) importerMap.set(name, version);
        if (!everywhere.has(name)) everywhere.set(name, new Set());
        everywhere.get(name).add(version);
    };

    let section = null;  // the top-level block we are inside
    let importer = null; // the Map for the importer block we are inside, if any
    let pending = null;  // a dependency name awaiting its `version:` line
    for (const line of readFileSync(path, 'utf8').split(/\r?\n/)) {
        if (/^\S/.test(line)) {
            section = line.replace(/:.*$/, '').trim();
            importer = null;
            pending = null;
            continue;
        }

        // `  packages/Angular:` - only inside `importers:`, so that a `packages:` key which happens
        // to look like a path cannot open a phantom importer and collect other packages' versions.
        if (section === 'importers') {
            const imp = line.match(/^ {2}(\S[^:]*):\s*$/);
            if (imp) {
                importer = new Map();
                byImporter.set(imp[1].trim(), importer);
                pending = null;
                continue;
            }
        }

        if (section === 'packages' || section === 'snapshots') {
            const keyed = line.match(/^ {2}'?(@memberjunction\/[^@'\s]+)@([^'\s]+?)'?:\s*$/);
            if (keyed) {
                add(null, keyed[1], keyed[2]);
                pending = null;
                continue;
            }
        }

        if (section !== 'importers' && section !== 'snapshots') continue;

        const inline = line.match(/^\s+'?(@memberjunction\/[^@'\s]+)'?:\s+(\S.*)$/);
        if (inline) {
            add(importer, inline[1], inline[2]);
            pending = null;
            continue;
        }
        const bare = line.match(/^\s+'?(@memberjunction\/[^@'\s]+)'?:\s*$/);
        if (bare) {
            pending = bare[1];
            continue;
        }
        if (pending) {
            const version = line.match(/^\s+version:\s*(\S.*)$/);
            if (version) {
                add(importer, pending, version[1]);
                pending = null;
                continue;
            }
            if (!/^\s+specifier:/.test(line)) pending = null;
        }
    }
    return { byImporter, everywhere, present: true };
}

const STORE = linkStoreIntoCache();
if (!STORE.ok) {
    // Two different failures, because they send the reader to two different places.
    if (STORE.store) {
        console.log(`WARNING: found a pnpm store at ${STORE.store}`);
        console.log('but could not link it into the cache:');
        console.log(`  ${STORE.why}`);
    } else {
        console.log('WARNING: no pnpm store found in this repo or any parent.');
    }
    console.log('Third-party types inside the published declarations will not resolve, and');
    console.log('skipLibCheck will hide that. The report below names what went unreachable.');
}

const LOCK = readLockfile();
if (!LOCK.present || !LOCK.everywhere.size) {
    console.log(
        LOCK.present
            ? 'WARNING: pnpm-lock.yaml carries no MemberJunction version this script could read.'
            : 'WARNING: no pnpm-lock.yaml here.',
    );
    console.log('Versions will come from `npm view`, which answers "newest in range" - NOT the version');
    console.log('CI installs. A pass from this run is unproven.');
}

/**
 * The version the lockfile pins for `name`, or null when it does not carry exactly one.
 *
 * The importer's own map wins: that is literally the line CI installs for this package. The
 * repo-wide map serves the transitive walk, where the edge is one published package's dependency on
 * another and no importer has an opinion. A name the lockfile resolves two ways is NOT guessed at -
 * a bad guess here is a check that passes against a version this package never sees, which is the
 * whole defect being fixed.
 */
function lockedVersion(name, importerKey) {
    const mine = importerKey && LOCK.byImporter.get(importerKey)?.get(name);
    if (mine) return mine;
    const all = LOCK.everywhere.get(name);
    if (!all || all.size !== 1) return null;
    return [...all][0];
}

/** Newest-in-range, asked of npm. Only for a name the lockfile does not carry. */
const newest = new Map();
function npmNewest(name, range) {
    const key = `${name}@${range}`;
    if (newest.has(key)) return newest.get(key);
    let version = null;
    try {
        version = JSON.parse(npm(['view', `${name}@${range}`, 'version', '--json'], REPO));
        if (Array.isArray(version)) version = version[version.length - 1];
    } catch {
        version = null; // unpublished, or a range npm cannot satisfy - reported by the caller
    }
    newest.set(key, version);
    return version;
}

/** Download and unpack one published package, cached by its concrete version. */
const unpacked = new Map();
function unpack(name, version) {
    const key = `${name}@${version}`;
    if (unpacked.has(key)) return unpacked.get(key);
    const dest = join(CACHE, name.replace('/', '__'), version);
    if (REFRESH && existsSync(dest)) rmSync(dest, { recursive: true, force: true });
    if (!existsSync(join(dest, 'package', 'package.json'))) {
        mkdirSync(dest, { recursive: true });
        const tarball = npm(['pack', `${name}@${version}`, '--silent', '--pack-destination', dest], REPO)
            .split(/\r?\n/)
            .pop()
            .trim();
        execFileSync('tar', ['-xzf', tarball], { cwd: dest, stdio: 'ignore' });
    }
    const dir = join(dest, 'package');
    unpacked.set(key, dir);
    return dir;
}

/** Resolve one dependency to an unpacked published copy: lockfile first, npm only as a fallback. */
function fetchPublished(name, range, importerKey, report) {
    let version = lockedVersion(name, importerKey);
    const pinned = Boolean(version);
    if (!pinned) {
        if (LOCK.everywhere.has(name)) {
            report.unresolvable.push(
                `${name} - pnpm-lock.yaml resolves it ${LOCK.everywhere.get(name).size} different ways`
                    + ` and this package's importer does not say which; not guessed at`,
            );
            return null;
        }
        version = npmNewest(name, range);
        if (!version) {
            report.unresolvable.push(`${name}@${range} - not in pnpm-lock.yaml, and npm cannot satisfy the range`);
            return null;
        }
    }

    try {
        const dir = unpack(name, version);
        if (pinned) report.fromLock++;
        else report.fromNpm.push(`${name}@${version}`);
        return { version, dir };
    } catch {
        report.unresolvable.push(
            pinned
                ? `${name}@${version} - pinned by pnpm-lock.yaml, but npm will not serve it`
                : `${name}@${version} - npm will not serve it`,
        );
        return null;
    }
}

/**
 * The published tree, walked transitively: a published `.d.ts` imports its own MemberJunction
 * dependencies, and those must resolve to published copies too or TypeScript falls back to the
 * workspace link and the whole check quietly tests nothing.
 */
function collectPublished(entryDeps, report, importerKey) {
    const paths = {};
    const queue = Object.entries(entryDeps).filter(([n]) => n.startsWith(SCOPE));
    const seen = new Set();

    while (queue.length) {
        const [name, range] = queue.shift();
        if (seen.has(name)) continue;
        seen.add(name);

        const got = fetchPublished(name, range, importerKey, report);
        if (!got) continue; // fetchPublished has already recorded precisely why
        report.fetched.push(`${name}@${got.version}`);
        const typesEntry = readJSON(join(got.dir, 'package.json')).types ?? readJSON(join(got.dir, 'package.json')).typings ?? '';
        if (typesEntry && !/\.d\.[cm]?ts$/.test(typesEntry)) report.sourceTyped.push(`${name} (types: ${typesEntry})`);
        paths[name] = [got.dir];
        paths[`${name}/*`] = [join(got.dir, '*')];

        const pkg = readJSON(join(got.dir, 'package.json'));
        for (const [n, r] of Object.entries(runtimeDeps(pkg))) {
            if (n.startsWith(SCOPE) && !seen.has(n)) queue.push([n, r]);
        }
    }
    return paths;
}

/**
 * THIRD-PARTY IMPORTS INSIDE THE CACHED .d.ts FILES, which `skipLibCheck` hides.
 *
 * A published MJ declaration says `import { Observable } from 'rxjs'`. The tarball is unpacked under
 * `node_modules/.cache/published-mj/...`, and Node resolves a bare specifier by walking ANCESTOR
 * directories looking for `node_modules` -- which from there reaches this repo's own `node_modules`
 * and nothing else. Under pnpm's isolated layout that directory holds only DIRECT dependencies, so
 * anything MJ pulls in transitively is invisible from the cache.
 *
 * `skipLibCheck: true` is what keeps those from becoming errors, and it is still the right setting:
 * the published packages' own type errors are not this repo's problem. The cost is that it silences
 * these too, so a signature typed through `Observable<T>` quietly degrades to `any` and the run
 * reports OK. MJ-to-MJ imports are unaffected -- those have explicit `paths` overrides -- so missing
 * exports and changed MJ signatures are still caught. This is about the edges typed in someone
 * else's vocabulary.
 *
 * Two outcomes, because the modules fall into two groups. `@angular/core` IS installed here and just
 * has no path override; `rxjs` is not installed at all, so no mapping can conjure it. The first is
 * fixed, the second is reported rather than left to be discovered.
 */
/**
 * Give the unpacked tarballs a `node_modules` to resolve THIRD-PARTY imports through.
 *
 * A published MJ declaration says `import { Observable } from 'rxjs'`. Node resolves that by walking
 * ancestor directories for `node_modules`, and from inside the cache the only one it reaches holds
 * this repo's DIRECT dependencies -- so every transitive one is invisible and `skipLibCheck` silences
 * the lookup. An MJ signature typed through `Observable<T>` then degrades to `any` while the run
 * reports OK.
 *
 * pnpm already keeps a directory with every package in the tree: `.pnpm/node_modules`. Linking the
 * cache root at it puts one `node_modules` on the walk that has them all.
 *
 * IT IS NOT ALWAYS IN THIS REPO. bizapps-common installs against a workspace root one level up, so
 * `<repo>/node_modules/.pnpm` does not exist at all here and `<workspace>/node_modules/.pnpm` is the
 * real store. Searching upward is what makes this work in both layouts; looking only in the repo is
 * what made it look impossible.
 */
function linkStoreIntoCache() {
    let dir = REPO;
    for (let i = 0; i < 6; i++) {
        const candidate = join(dir, 'node_modules', '.pnpm', 'node_modules');
        if (existsSync(candidate)) {
            const link = join(CACHE, 'node_modules');
            try {
                // `existsSync` follows the link, so this is true only when it resolves.
                if (existsSync(link)) return { store: candidate, ok: true };
                mkdirSync(CACHE, { recursive: true });
                /**
                 * A LINK LEFT BY A STORE THAT HAS SINCE MOVED still occupies this path while
                 * resolving to nothing, and `symlinkSync` would fail EEXIST on it. Measured before
                 * fixing: the run then reported "no pnpm store found to link into the cache" while
                 * a perfectly good store sat one directory up, left the broken link in place, and
                 * degraded every third-party type to `any` on every subsequent run. Wrong about the
                 * reason and unable to recover, which is the pair this script exists to avoid.
                 */
                rmSync(link, { force: true });
                symlinkSync(candidate, link, 'junction');
                return { store: candidate, ok: true };
            } catch (err) {
                return { store: candidate, ok: false, why: err?.message ?? String(err) };
            }
        }
        const up = dirname(dir);
        if (up === dir) break;
        dir = up;
    }
    return { store: null, ok: false };
}

const BARE_IMPORT =
    /^\s*(?:import|export)\b[^;'"]*?from\s*['"]([^'"]+)['"]|^\s*import\s*\(?\s*['"]([^'"]+)['"]/gm;

/** `@scope/name/sub` -> `@scope/name`; `name/sub` -> `name`. Node builtins are dropped. */
function packageOf(specifier) {
    // Relative and absolute specifiers resolve inside the tarball; only bare ones are at issue.
    if (specifier.startsWith('.') || specifier.startsWith('/')) return null;
    if (specifier.startsWith('node:')) return null;
    const parts = specifier.split('/');
    const name = specifier.startsWith('@') ? parts.slice(0, 2).join('/') : parts[0];
    return name || null;
}

/**
 * Scan the declaration files of every cached package this run uses, and split what they import into
 * what this repo can serve and what it cannot.
 *
 * Reads files rather than running a second `tsc` without `skipLibCheck`: the answer is the same and
 * it costs milliseconds instead of a second full typecheck.
 */
function thirdPartyImports(paths, dir) {
    const wanted = new Set();
    for (const [name, [target]] of Object.entries(paths)) {
        if (name.endsWith('/*')) continue;
        for (const file of declarationFiles(target)) {
            let text;
            try {
                text = readFileSync(file, 'utf8');
            } catch {
                continue;
            }
            for (const m of text.matchAll(BARE_IMPORT)) {
                const pkg = packageOf(m[1] ?? m[2]);
                if (pkg && !pkg.startsWith(SCOPE)) wanted.add(pkg);
            }
        }
    }

    /**
     * Resolved FROM THE CACHE, because that is where the declarations sit and the only place the
     * answer means anything. Resolving from the package under test asks a different question and
     * gets a different answer: it says `rxjs` is unavailable when the store has it and the link
     * above just made it reachable.
     */
    const probe = createRequire(join(CACHE, 'probe.js'));
    const reachable = [];
    const missing = [];
    for (const name of [...wanted].sort()) {
        let ok = false;
        try {
            probe.resolve(`${name}/package.json`);
            ok = true;
        } catch {
            try {
                probe.resolve(name);
                ok = true;
            } catch {
                ok = false;
            }
        }
        (ok ? reachable : missing).push(name);
    }
    return { reachable, missing };
}

/** Every `.d.ts` under a cached package, depth-limited because tarballs are shallow. */
function declarationFiles(root, depth = 0, acc = []) {
    if (depth > 6) return acc;
    let entries;
    try {
        entries = readdirSync(root, { withFileTypes: true });
    } catch {
        return acc;
    }
    for (const e of entries) {
        const full = join(root, e.name);
        if (e.isDirectory()) declarationFiles(full, depth + 1, acc);
        else if (e.name.endsWith('.d.ts')) acc.push(full);
    }
    return acc;
}

function checkPackage(dir) {
    const name = relative(REPO, dir).replace(/\\/g, '/');
    const pkg = readJSON(join(dir, 'package.json'));
    const report = { fetched: [], unresolvable: [], sourceTyped: [], fromLock: 0, fromNpm: [] };

    process.stdout.write(`\n${name}\n`);
    // `name` doubles as the importer key: pnpm-lock.yaml names importers by workspace-relative path.
    const paths = collectPublished(allDeps(pkg), report, name);

    // Say where each version came from. "Resolved from npm" was true of the old behaviour and is
    // the thing that was wrong with it, so the run should not be able to claim it without showing it.
    const parts = [`${report.fromLock} pinned by pnpm-lock.yaml`];
    if (report.fromNpm.length) parts.push(`${report.fromNpm.length} newest-in-range from npm`);
    process.stdout.write(`  resolved ${report.fetched.length} published package(s): ${parts.join(', ')}\n`);
    for (const guess of report.fromNpm) {
        process.stdout.write(`  NOT IN LOCKFILE, using newest in range: ${guess}\n`);
    }
    for (const miss of report.unresolvable) {
        process.stdout.write(`  UNRESOLVED: ${miss}\n`);
    }

    if (!report.fetched.length) {
        console.log('  CANNOT CHECK: not one MemberJunction dependency resolved.');
        console.log('  Reporting success here would be a lie: with no path overrides TypeScript falls');
        console.log('  back to the workspace links, which is exactly what this exists to look past.');
        /**
         * THIS RETURNED `false`, AND THE RUN EXITED 0.
         *
         * `false` is neither 'failed' nor 'inconclusive', so the tally at the bottom counted it as
         * neither and `checked = dirs.length - inconclusive` counted it as a pass. A total
         * resolution failure printed the three lines above and then "1 of 1 package(s) compile",
         * and exited 0. The paragraph said reporting success would be a lie while the exit code went
         * on to report success - the same defect this script exists to catch, in the script itself.
         *
         * It exits non-zero now. Not as 'failed' though: "your code uses an unpublished API" and
         * "this guard could not run" are different messages for the reader, and the summary at the
         * bottom used to print the first one for the second.
         */
        return 'cannot-check';
    }

    // What the cached declarations import from outside MemberJunction, and whether the store link
    // above actually reaches it. No `paths` entries: the link is what resolves these, and a path
    // override per name would only re-answer the question in a second, less reliable way.
    const thirdParty = thirdPartyImports(paths, dir);

    const out = join(CACHE, '_tsconfig', name.replace(/[\\/]/g, '__'));
    mkdirSync(out, { recursive: true });
    const configPath = join(out, 'tsconfig.published.json');
    writeFileSync(
        configPath,
        JSON.stringify(
            {
                extends: join(dir, 'tsconfig.json').replace(/\\/g, '/'),
                compilerOptions: {
                    noEmit: true,
                    baseUrl: dir.replace(/\\/g, '/'),
                    paths,
                    // The published copies are consumed as declarations only; their own build errors
                    // are not this repo's problem and would drown the signal.
                    skipLibCheck: true,
                },
                include: [join(dir, 'src/**/*').replace(/\\/g, '/')],
            },
            null,
            2,
        ),
    );

    let errors = '';
    try {
        run('npx', ['tsc', '-p', configPath], dir);
    } catch (err) {
        errors = `${err.stdout ?? ''}${err.stderr ?? ''}`;
    }

    // Errors inside the published packages themselves are noise; only this repo's source counts.
    const mine = errors
        .split(/\r?\n/)
        .filter((l) => /error TS/.test(l))
        .filter((l) => !l.includes('node_modules') && !l.includes('.cache'));

    /**
     * `Cannot find module '@mj-biz-apps/...'` is one of OUR packages, not MemberJunction's. It
     * resolves through that package's own `dist`, so this means the workspace is not built - and
     * printing it under a "MemberJunction API not published" header blames the wrong thing and sends
     * the reader to npm to look for a package that was never going to be there.
     */
    const unbuilt = mine.filter((l) => /TS2307/.test(l) && /@mj-biz-apps\//.test(l));

    /**
     * Decided before anything is printed. Downgrading after the fact made the run print
     * `OK - compiles against published MemberJunction` and then, three lines later, that it had
     * not checked the package - two verdicts on one package, the reassuring one first.
     */
    let verdict;
    if (mine.length && unbuilt.length) {
        console.log(`  CANNOT CHECK: ${unbuilt.length} error(s) are missing WORKSPACE packages, not MemberJunction:`);
        for (const line of unbuilt.slice(0, 3)) console.log(`      ${line.trim()}`);
        console.log('  Those are this repo\'s own packages, read from their `dist`, so the tree is not');
        console.log('  built. Run `pnpm build` and re-run. Nothing downstream of those imports has been');
        console.log('  checked against MemberJunction at all.');
        verdict = 'inconclusive';
    } else if (mine.length && report.sourceTyped.length) {
        console.log('  INCONCLUSIVE - a dependency publishes TypeScript SOURCE as its types entry:');
        for (const st of report.sourceTyped) console.log(`      ${st}`);
        console.log('  Checking it means compiling ITS source, whose own third-party imports are not in');
        console.log('  the unpacked tarball, so the errors below are about that and not about this repo.');
        console.log('  Reported, not failed. CI installs the real dependency tree and does resolve them.');
        for (const line of mine.slice(0, 5)) console.log(`      ${line.trim()}`);
        verdict = 'inconclusive';
    } else if (mine.length) {
        process.stdout.write(`  ${mine.length} error(s) against PUBLISHED MemberJunction:\n`);
        for (const line of mine.slice(0, 20)) process.stdout.write(`    ${line.trim()}\n`);
        if (mine.length > 20) process.stdout.write(`    ... and ${mine.length - 20} more\n`);
        verdict = 'failed';
    } else if (report.unresolvable.length) {
        /**
         * ONE UNRESOLVED DEPENDENCY IS NOT A PASS WITH A FOOTNOTE.
         *
         * TypeScript has no path override for a name that did not resolve, so it resolves that one
         * through the workspace link - the local `dist` this whole script exists to look past - and
         * every import reached through it is checked against the wrong copy. The package compiles
         * clean and used to print OK. It is not OK, it is unknown, and unknown outranks the pass.
         */
        console.log('  INCONCLUSIVE - it compiles, but these resolved through the workspace link, not npm:');
        for (const miss of report.unresolvable) console.log(`      ${miss}`);
        console.log('  Whatever they declare is being read from the local build, so this run does not');
        console.log('  cover anything that goes through them.');
        verdict = 'inconclusive';
    } else if (report.fromNpm.length) {
        /**
         * NEWEST-IN-RANGE IS NOT WHAT CI INSTALLS EITHER.
         *
         * The whole point of reading pnpm-lock.yaml is that `npm view <name>@<range> version` answers
         * a question nobody acts on. When the lockfile does not carry a name, this falls back to that
         * answer -- which is the right thing to do, because checking against something beats checking
         * against nothing. It is NOT a basis for reporting a pass.
         *
         * The banner at the top already says a run without a lockfile is unproven. It said so and then
         * printed OK and exited 0, which is the same shape as the two defects the review caught: the
         * paragraph disclaims what the verdict then asserts. The disclaimer is not the verdict.
         */
        console.log('  INCONCLUSIVE - it compiles, but these versions came from `npm view`, not the lockfile:');
        for (const guess of report.fromNpm) console.log(`      ${guess}`);
        console.log('  That is the newest release the range admits, which is not what CI installs. This');
        console.log('  run says nothing about the version that will actually be there.');
        verdict = 'inconclusive';
    } else {
        process.stdout.write(`  OK - compiles against published MemberJunction\n`);
        verdict = 'ok';
    }

    /**
     * Said whatever the verdict, because it qualifies a pass as much as a failure: these are the
     * places where the check ran but could not see what it was checking against.
     */
    const reach = thirdParty.reachable.length;
    if (reach || thirdParty.missing.length) {
        const parts = [`${reach} resolved`];
        if (thirdParty.missing.length) parts.push(`${thirdParty.missing.length} UNREACHABLE`);
        console.log(`  third-party types in the published declarations: ${parts.join(', ')}`);
    }
    if (thirdParty.missing.length) {
        console.log('  Unreachable from the cache, so every MJ signature typed through one of these');
        console.log('  degrades to `any` for this run (skipLibCheck hides the lookup):');
        console.log(`      ${thirdParty.missing.slice(0, 12).join(', ')}`);
        if (thirdParty.missing.length > 12) {
            console.log(`      ... and ${thirdParty.missing.length - 12} more`);
        }
    }
    return verdict;
}


const dirs = packagesToCheck();
if (!dirs.length) {
    console.log('No workspace package declares a MemberJunction dependency.');
    process.exit(0);
}

let failed = 0;
let unresolved = 0;
let inconclusive = 0;
for (const dir of dirs) {
    const verdict = checkPackage(dir);
    if (verdict === 'failed') failed++;
    else if (verdict === 'cannot-check') unresolved++;
    else if (verdict === 'inconclusive') inconclusive++;
}

console.log('');
/**
 * Two ways to exit non-zero, because they mean different things to whoever reads this. `failed` is
 * "your code uses an API CI will not have". `unresolved` is "this guard could not run", which is not
 * a verdict on the code at all - and the single message here used to report it as one.
 */
if (unresolved) {
    console.log(`${unresolved} package(s) COULD NOT BE CHECKED: no MemberJunction dependency resolved.`);
    console.log('That is a verdict on this run, not on the code. Check access to the npm registry and re-run.');
}
if (failed) {
    console.log(`${failed} package(s) use MemberJunction API that is not published yet.`);
    console.log('CI installs the version pnpm-lock.yaml pins, so this is what CI will see regardless of how');
    console.log('the local workspace is linked.');
}
if (failed || unresolved) process.exit(1);

/**
 * COUNT WHAT WAS CHECKED, NOT WHAT WAS VISITED.
 *
 * This said `${dirs.length} package(s) compile`, which counted the INCONCLUSIVE ones too - and for
 * those this guard verified NOTHING, as the block above says in full. A summary line that reads
 * better than the run it summarises is the exact shape of defect this script exists to catch, so it
 * should not be the last thing the script prints about itself.
 */
const checked = dirs.length - inconclusive;
console.log(`${checked} of ${dirs.length} package(s) compile against published MemberJunction.`);
if (inconclusive) {
    console.log(
        `${inconclusive} INCONCLUSIVE - not checked at all, for the reason given above. This run`
            + ` proves nothing about ${inconclusive === 1 ? 'that package' : 'those packages'}.`,
    );
}
