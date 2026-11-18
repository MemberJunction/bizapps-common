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
 * lockfile now, and asks npm only for a name the lockfile does not carry.
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
import { execFileSync } from 'node:child_process';
import {
    existsSync,
    lstatSync,
    mkdirSync,
    readFileSync,
    readdirSync,
    realpathSync,
    rmSync,
    symlinkSync,
    writeFileSync,
} from 'node:fs';
import { dirname, join, parse as parsePath, relative, resolve } from 'node:path';
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

const LOCK = readLockfile();

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

/**
 * Populate `<cacheDir>/node_modules` with symlinks to third-party (non-`@memberjunction/*`)
 * packages from `<ancestor>/node_modules/.pnpm/node_modules` and `<ancestor>/node_modules`.
 *
 * Unpacked tarballs live under `<cacheDir>/<pkg>/<version>/package`. When TypeScript resolves a
 * transitive third-party import from a published `.d.ts` or source-typed package (such as
 * `@memberjunction/server` whose `"types"` points at `./src/index.ts`), Node module resolution
 * walks up to `<cacheDir>/node_modules`. Linking non-MJ packages there lets those imports resolve
 * without exposing the workspace's local `@memberjunction/*` symlinks (#315).
 */
export function ensurePublishedTarballs(cacheDir = CACHE, searchRoots = [REPO]) {
    const nmRoot = join(cacheDir, 'node_modules');
    mkdirSync(nmRoot, { recursive: true });

    const candidateNodeModules = [];
    for (const start of searchRoots) {
        let cur = resolve(start);
        const { root } = parsePath(cur);
        while (true) {
            const pnpmVirtual = join(cur, 'node_modules', '.pnpm', 'node_modules');
            const directNm = join(cur, 'node_modules');
            if (existsSync(pnpmVirtual)) candidateNodeModules.push(pnpmVirtual);
            if (existsSync(directNm)) candidateNodeModules.push(directNm);
            if (cur === root) break;
            const parent = dirname(cur);
            if (parent === cur) break;
            cur = parent;
        }
    }

    const linkEntry = (srcDir, destPath) => {
        try {
            lstatSync(destPath);
            return; // already linked or present
        } catch {
            // does not exist yet
        }
        try {
            symlinkSync(srcDir, destPath, WIN ? 'junction' : 'dir');
        } catch {
            // ignore race or unsupported symlink error
        }
    };

    for (const srcNm of candidateNodeModules) {
        let entries = [];
        try {
            entries = readdirSync(srcNm);
        } catch {
            continue;
        }
        for (const entry of entries) {
            if (
                entry.startsWith('.') ||
                entry === '@memberjunction' ||
                entry === 'node_modules'
            ) {
                continue;
            }
            const srcEntry = join(srcNm, entry);
            if (entry.startsWith('@')) {
                let scopedEntries = [];
                try {
                    scopedEntries = readdirSync(srcEntry);
                } catch {
                    continue;
                }
                const destScope = join(nmRoot, entry);
                mkdirSync(destScope, { recursive: true });
                for (const child of scopedEntries) {
                    if (child.startsWith('.')) continue;
                    linkEntry(join(srcEntry, child), join(destScope, child));
                }
            } else {
                linkEntry(srcEntry, join(nmRoot, entry));
            }
        }
    }

    return nmRoot;
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
 * Filter raw `tsc` output down to diagnostics belonging to this package's own source, separating:
 * - `mine`: all diagnostics in the package's own files (excluding `node_modules` and `.cache`)
 * - `unbuilt`: `TS2307` diagnostics for sibling `@mj-biz-apps/*` packages whose `dist` is not built
 * - `sourceTypedBroken`: diagnostics inside `.cache` for a `sourceTyped` dependency whose own `.ts`
 *   source failed to resolve a third-party module (`TS2307`)
 * - `ownErrors`: diagnostics in this package's own files that are NOT merely cascades from an
 *   unresolved third-party module inside a `sourceTyped` dependency (#315)
 */
export function classifyDiagnostics(rawErrors, sourceTyped = []) {
    const lines = String(rawErrors ?? '')
        .split(/\r?\n/)
        .filter((l) => /error TS\d+:/.test(l));

    const cacheLines = lines.filter((l) => l.includes('node_modules') || l.includes('.cache'));
    const mine = lines.filter((l) => !l.includes('node_modules') && !l.includes('.cache'));
    const unbuilt = mine.filter((l) => /TS2307/.test(l) && /@mj-biz-apps\//.test(l));

    // Identify which source-typed packages (e.g. `@memberjunction/server`) actually failed to
    // resolve their own third-party imports inside `.cache`. If `<cacheDir>/node_modules` satisfied
    // all of their imports, `brokenSourceTypedPkgs` is empty and no error in `mine` is excused.
    const brokenSourceTypedPkgs = new Set();
    for (const entry of sourceTyped) {
        const pkgName = entry.replace(/\s*\(.*$/, '').trim();
        const slug = pkgName.replace('/', '__');
        const hasCacheMissingModule = cacheLines.some(
            (l) => /TS2307/.test(l) && (l.includes(pkgName) || l.includes(slug)),
        );
        if (hasCacheMissingModule) brokenSourceTypedPkgs.add(pkgName);
    }

    const sourceTypedCascade = [];
    const ownErrors = [];
    for (const line of mine) {
        const isCascadeFromBrokenSourceTyped =
            brokenSourceTypedPkgs.size > 0 &&
            /TS230[57]/.test(line) &&
            [...brokenSourceTypedPkgs].some((pkgName) => line.includes(`"${pkgName}"`) || line.includes(`'${pkgName}'`));
        if (isCascadeFromBrokenSourceTyped) {
            sourceTypedCascade.push(line);
        } else {
            ownErrors.push(line);
        }
    }

    return { mine, unbuilt, sourceTypedCascade, ownErrors };
}

/**
 * Compute the package verdict from classified diagnostics and resolution report (#315).
 *
 * Crucially, `report.sourceTyped.length > 0` does NOT short-circuit to `'inconclusive'` when
 * `ownErrors` is empty (the package compiled cleanly!) or when `ownErrors` contains genuine
 * type errors in this repo's own files.
 */
export function judgePackage({ mine = [], unbuilt = [], sourceTypedCascade = [], ownErrors = [] }, report) {
    if (!report.fetched?.length) {
        return 'cannot-check';
    }
    if (mine.length && unbuilt.length) {
        return 'inconclusive';
    }
    if (ownErrors.length > 0) {
        return 'failed';
    }
    if (sourceTypedCascade.length > 0 && report.sourceTyped?.length) {
        return 'inconclusive';
    }
    if (report.unresolvable?.length) {
        return 'inconclusive';
    }
    return 'ok';
}

function checkPackage(dir) {
    const name = relative(REPO, dir).replace(/\\/g, '/');
    const pkg = readJSON(join(dir, 'package.json'));
    const report = { fetched: [], unresolvable: [], sourceTyped: [], fromLock: 0, fromNpm: [] };

    process.stdout.write(`\n${name}\n`);
    ensurePublishedTarballs(CACHE, [dir, REPO]);
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
        return 'cannot-check';
    }

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

    const classified = classifyDiagnostics(errors, report.sourceTyped);
    const verdict = judgePackage(classified, report);

    if (verdict === 'inconclusive' && classified.unbuilt.length) {
        console.log(`  CANNOT CHECK: ${classified.unbuilt.length} error(s) are missing WORKSPACE packages, not MemberJunction:`);
        for (const line of classified.unbuilt.slice(0, 3)) console.log(`      ${line.trim()}`);
        console.log('  Those are this repo\'s own packages, read from their `dist`, so the tree is not');
        console.log('  built. Run `pnpm build` and re-run. Nothing downstream of those imports has been');
        console.log('  checked against MemberJunction at all.');
    } else if (verdict === 'inconclusive' && classified.sourceTypedCascade.length) {
        console.log('  INCONCLUSIVE - a dependency publishes TypeScript SOURCE as its types entry:');
        for (const st of report.sourceTyped) console.log(`      ${st}`);
        console.log('  Checking it means compiling ITS source, whose own third-party imports are not in');
        console.log('  the unpacked tarball, so the errors below are about that and not about this repo.');
        console.log('  Reported, not failed. CI installs the real dependency tree and does resolve them.');
        for (const line of classified.sourceTypedCascade.slice(0, 5)) console.log(`      ${line.trim()}`);
    } else if (verdict === 'failed') {
        process.stdout.write(`  ${classified.ownErrors.length} error(s) against PUBLISHED MemberJunction:\n`);
        for (const line of classified.ownErrors.slice(0, 20)) process.stdout.write(`    ${line.trim()}\n`);
        if (classified.ownErrors.length > 20) process.stdout.write(`    ... and ${classified.ownErrors.length - 20} more\n`);
    } else if (verdict === 'inconclusive' && report.unresolvable.length) {
        console.log('  INCONCLUSIVE - it compiles, but these resolved through the workspace link, not npm:');
        for (const miss of report.unresolvable) console.log(`      ${miss}`);
        console.log('  Whatever they declare is being read from the local build, so this run does not');
        console.log('  cover anything that goes through them.');
    } else {
        process.stdout.write(`  OK - compiles against published MemberJunction\n`);
    }
    return verdict;
}

function main() {
    if (!LOCK.present || !LOCK.everywhere.size) {
        console.log(
            LOCK.present
                ? 'WARNING: pnpm-lock.yaml carries no MemberJunction version this script could read.'
                : 'WARNING: no pnpm-lock.yaml here.',
        );
        console.log('Versions will come from `npm view`, which answers "newest in range" - NOT the version');
        console.log('CI installs. A pass from this run is unproven.');
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

    const checked = dirs.length - inconclusive;
    console.log(`${checked} of ${dirs.length} package(s) compile against published MemberJunction.`);
    if (inconclusive) {
        console.log(
            `${inconclusive} INCONCLUSIVE - not checked at all, for the reason given above. This run`
                + ` proves nothing about ${inconclusive === 1 ? 'that package' : 'those packages'}.`,
        );
    }
}

if (process.argv[1] && realpathSync(process.argv[1]) === realpathSync(fileURLToPath(import.meta.url))) {
    main();
}
