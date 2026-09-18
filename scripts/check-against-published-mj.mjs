/**
 * Typecheck this repo against the MemberJunction packages that are actually PUBLISHED, rather than
 * whatever the local workspace happens to be linked to.
 *
 * WHY THIS EXISTS. A build here can see three different MemberJunctions, and only one of them is what
 * CI and real consumers get:
 *
 *   1. MJ's `src`      — whatever is committed in the sibling checkout
 *   2. MJ's `dist`     — what the workspace symlink actually exposes, whose freshness is arbitrary:
 *                        it is only as new as the last time someone ran a build over there
 *   3. npm             — the published version matching the range in package.json
 *
 * `pnpm build` locally resolves (2). CI resolves (3). So code written against a freshly built MJ
 * compiles on its author's machine and fails in CI, while code written against a stale one produces
 * errors that look like the repo's fault. Both have happened here in the same week: `chrome` on
 * `EntityViewerConfig`, which broke every build of `next` for a day, and `GetEvents` on
 * `BaseCommunicationProvider` in the calendar transport.
 *
 * This script answers the only question that matters before pushing: does the source compile against
 * what is on npm today?
 *
 *   node scripts/check-against-published-mj.mjs                 # every workspace package
 *   node scripts/check-against-published-mj.mjs packages/Angular
 *   node scripts/check-against-published-mj.mjs --refresh       # ignore the cache
 *
 * Read-only with respect to the repo: published tarballs are cached under node_modules/.cache, the
 * generated tsconfig lives there too, and nothing in node_modules is relinked or mutated.
 */
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
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
 * Windows needs `shell: true` for `.cmd` shims — Node refuses to spawn them directly (EINVAL) since
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
    if (targets.length) return targets.map((t) => resolve(REPO, t));
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
 * affect anyone — `@memberjunction/ng-test-utils`, published only as a 0.0.1 placeholder, is a
 * devDependency of a dozen MJ packages and would otherwise be reported as missing every run.
 */
const runtimeDeps = (pkg) => ({ ...pkg.dependencies, ...pkg.peerDependencies });

/**
 * Download and unpack one published package, cached by the CONCRETE version the range resolves to —
 * so a moving range like `^6.1.0-edge.5` re-fetches when npm gets a newer match.
 */
const resolved = new Map();
function fetchPublished(name, range) {
    const key = `${name}@${range}`;
    if (resolved.has(key)) return resolved.get(key);

    let version;
    try {
        version = npm(['view', `${name}@${range}`, 'version', '--json'], REPO);
        version = JSON.parse(version);
        if (Array.isArray(version)) version = version[version.length - 1];
    } catch {
        resolved.set(key, null);
        return null; // unpublished, or a range npm cannot satisfy — reported by the caller
    }

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
    const info = { version, dir: join(dest, 'package') };
    resolved.set(key, info);
    return info;
}

/**
 * The published tree, walked transitively: a published `.d.ts` imports its own MemberJunction
 * dependencies, and those must resolve to published copies too or TypeScript falls back to the
 * workspace link and the whole check quietly tests nothing.
 */
function collectPublished(entryDeps, report) {
    const paths = {};
    const queue = Object.entries(entryDeps).filter(([n]) => n.startsWith(SCOPE));
    const seen = new Set();

    while (queue.length) {
        const [name, range] = queue.shift();
        if (seen.has(name)) continue;
        seen.add(name);

        const got = fetchPublished(name, range);
        if (!got) {
            report.unresolvable.push(`${name}@${range}`);
            continue;
        }
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

function checkPackage(dir) {
    const name = relative(REPO, dir).replace(/\\/g, '/');
    const pkg = readJSON(join(dir, 'package.json'));
    const report = { fetched: [], unresolvable: [], sourceTyped: [] };

    process.stdout.write(`\n${name}\n`);
    const paths = collectPublished(allDeps(pkg), report);
    process.stdout.write(`  resolved ${report.fetched.length} published package(s) from npm\n`);
    for (const miss of report.unresolvable) {
        process.stdout.write(`  NOT ON NPM: ${miss}\n`);
    }

    if (!report.fetched.length) {
        console.log('  CANNOT CHECK: not one MemberJunction dependency resolved from npm.');
        console.log('  Reporting success here would be a lie: with no path overrides TypeScript falls');
        console.log('  back to the workspace links, which is exactly what this exists to look past.');
        return false;
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

    // Errors inside the published packages themselves are noise; only this repo's source counts.
    const mine = errors
        .split(/\r?\n/)
        .filter((l) => /error TS/.test(l))
        .filter((l) => !l.includes('node_modules') && !l.includes('.cache'));

    if (!mine.length) {
        process.stdout.write(`  OK — compiles against published MemberJunction\n`);
        return true;
    }
    if (report.sourceTyped.length) {
        console.log('  INCONCLUSIVE — a dependency publishes TypeScript SOURCE as its types entry:');
        for (const st of report.sourceTyped) console.log(`      ${st}`);
        console.log('  Checking it means compiling ITS source, whose own third-party imports are not in');
        console.log('  the unpacked tarball, so the errors below are about that and not about this repo.');
        console.log('  Reported, not failed. CI installs the real dependency tree and does resolve them.');
        for (const line of mine.slice(0, 5)) console.log(`      ${line.trim()}`);
        return true;
    }
    process.stdout.write(`  ${mine.length} error(s) against PUBLISHED MemberJunction:\n`);
    for (const line of mine.slice(0, 20)) process.stdout.write(`    ${line.trim()}\n`);
    if (mine.length > 20) process.stdout.write(`    ... and ${mine.length - 20} more\n`);
    return false;
}

const dirs = packagesToCheck();
if (!dirs.length) {
    console.log('No workspace package declares a MemberJunction dependency.');
    process.exit(0);
}

let failed = 0;
for (const dir of dirs) if (!checkPackage(dir)) failed++;

console.log('');
if (failed) {
    console.log(`${failed} package(s) use MemberJunction API that is not published yet.`);
    console.log('CI installs from npm, so this is what CI will see regardless of how the local workspace is linked.');
    process.exit(1);
}
console.log(`${dirs.length} package(s) compile against published MemberJunction.`);
