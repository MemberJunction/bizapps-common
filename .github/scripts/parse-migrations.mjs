#!/usr/bin/env node
/**
 * parse-migrations.mjs
 *
 * Verifies that all T-SQL migrations in migrations/ are syntactically valid
 * by compiling them on SQL Server with SET PARSEONLY ON.
 *
 * Catches unclosed quotation marks (e.g. unescaped single quotes like "item's"),
 * invalid keyword placement, unbalanced parentheses, and malformed T-SQL batches
 * that textual lints cannot detect.
 *
 * SET PARSEONLY ON checks syntax without object name resolution (unlike SET NOEXEC ON,
 * which compiles batches and fails when views/SPs reference tables created in earlier batches).
 */

import { execFileSync, execSync } from 'node:child_process';
import { readdirSync, readFileSync, writeFileSync, unlinkSync, realpathSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join, resolve } from 'node:path';
import { tmpdir } from 'node:os';

const host = process.env.DB_HOST || 'localhost';
const port = process.env.DB_PORT || '1433';
const user = process.env.DB_USERNAME || 'sa';
const password = process.env.DB_PASSWORD || 'KRiUffvIjuP5GoLtxYvVkWIQ1BxHQEEMO7j4T684oPR7';

function findExecutionMethod() {
    const candidates = [
        'sqlcmd',
        '/opt/mssql-tools18/bin/sqlcmd',
        '/opt/mssql-tools/bin/sqlcmd',
        '/usr/local/bin/sqlcmd',
    ];
    for (const c of candidates) {
        try {
            execSync(`${c} -?`, { stdio: 'ignore' });
            return {
                type: 'local',
                cmd: c,
                execute: (sql) => {
                    const tempFile = join(tmpdir(), `parse_${Date.now()}_${Math.random().toString(36).slice(2)}.sql`);
                    try {
                        writeFileSync(tempFile, sql, 'utf8');
                        execFileSync(c, [
                            '-S', `${host},${port}`,
                            '-U', user,
                            '-P', password,
                            '-C',
                            '-b',
                            '-i', tempFile
                        ], { stdio: 'pipe' });
                    } finally {
                        try { unlinkSync(tempFile); } catch {}
                    }
                }
            };
        } catch {
            // try next
        }
    }

    return null;
}

/**
 * gh-3: Migration filenames in `absDir`, sorted. Throws a descriptive Error naming the --dir
 * value (never a raw ENOENT) when the directory can't be read, so a missing/mistyped --dir (or
 * running from the wrong cwd, so the default ./migrations doesn't exist) is diagnosable.
 */
export function listMigrationFiles(absDir, dirArg) {
    let entries;
    try {
        entries = readdirSync(absDir);
    } catch (err) {
        throw new Error(`Could not read migration directory '${dirArg}' (resolved to '${absDir}'): ${err.message}`);
    }
    return entries.filter((f) => f.endsWith('.sql')).sort();
}

function main() {
    const isSelfTest = process.argv.includes('--self-test');
    const dir = process.argv.find((_, i, arr) => arr[i - 1] === '--dir') || './migrations';
    const defaultSchema = process.argv.find((_, i, arr) => arr[i - 1] === '--schema') || '__mj_BizAppsCommon';
    const mjSchema = process.argv.find((_, i, arr) => arr[i - 1] === '--core-schema') || '__mj';

    const runner = findExecutionMethod();
    if (!runner) {
        console.error('::error::sqlcmd utility was not found in PATH or standard locations.');
        process.exit(1);
    }

    if (isSelfTest) {
        console.log(`Running parse-migrations self-test (via ${runner.cmd})...`);
        // Valid batch test
        try {
            runner.execute('SET PARSEONLY ON;\nGO\nSELECT 1 AS [Test];\nGO\n');
        } catch (e) {
            console.error('Self-test failed on valid SQL:', e.message);
            process.exit(1);
        }

        // Invalid batch test
        let failedAsExpected = false;
        try {
            runner.execute("SET PARSEONLY ON;\nGO\nPRINT 'item's';\nGO\n");
        } catch (err) {
            failedAsExpected = true;
            const msg = err.stdout?.toString() || err.stderr?.toString() || err.message;
            console.log('✓ Self-test caught invalid syntax as expected:\n  ' + msg.trim().split('\n')[0]);
        }
        if (!failedAsExpected) {
            console.error('Self-test failed: syntax error was not caught!');
            process.exit(1);
        }

        console.log('✓ parse-migrations self-test passed');
        return;
    }

    const absDir = resolve(dir);
    let files;
    try {
        files = listMigrationFiles(absDir, dir);
    } catch (err) {
        console.error(`::error::${err.message}`);
        process.exit(1);
    }

    if (files.length === 0) {
        console.error(`::error::No migration files found in ${dir} to parse!`);
        process.exit(1);
    }

    console.log(`Checking ${files.length} migration files in ${dir} with SQL Server SET PARSEONLY ON (via ${runner.cmd})...`);

    let parsedCount = 0;
    for (const file of files) {
        const filePath = join(absDir, file);
        let sql = readFileSync(filePath, 'utf8');

        // Substitute Flyway placeholders
        sql = sql.replace(/\$\{flyway:defaultSchema\}/g, defaultSchema);
        sql = sql.replace(/\$\{mjSchema\}/g, mjSchema);

        // Prepend SET PARSEONLY ON in its own batch, followed by migration content
        const wrapped = `SET PARSEONLY ON;\nGO\n${sql}\nGO\n`;

        try {
            runner.execute(wrapped);
            parsedCount++;
        } catch (err) {
            const output = err.stdout?.toString() || err.stderr?.toString() || err.message;
            console.error(`\n::error file=migrations/${file}::Syntax error parsing ${file}:\n${output.trim()}\n`);
            process.exit(1);
        }
    }

    console.log(`✓ All ${parsedCount} migration files parsed cleanly by SQL Server (no syntax errors)`);
}

/** True when this module is the process entry point, so importing it (e.g. from a test) never
 *  runs the CLI -- no self-test, no runner detection, no sqlcmd invocation as a side effect. */
function isEntryPoint() {
    if (!process.argv[1]) return false;
    try {
        return realpathSync(fileURLToPath(import.meta.url)) === realpathSync(process.argv[1]);
    } catch {
        return false;
    }
}

if (isEntryPoint()) {
    main();
}
