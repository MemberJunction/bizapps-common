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

import { execSync } from 'node:child_process';
import { readdirSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

const isSelfTest = process.argv.includes('--self-test');
const dir = process.argv.find((_, i, arr) => arr[i - 1] === '--dir') || './migrations';
const defaultSchema = process.argv.find((_, i, arr) => arr[i - 1] === '--schema') || '__mj_BizAppsCommon';
const mjSchema = process.argv.find((_, i, arr) => arr[i - 1] === '--core-schema') || '__mj';

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
                execute: (sql) => {
                    execSync(`"${c}" -S "${host},${port}" -U "${user}" -P "${password}" -C -b`, {
                        input: sql,
                        stdio: ['pipe', 'pipe', 'pipe'],
                    });
                }
            };
        } catch {
            // try next
        }
    }

    // Try finding running docker container for mssql
    try {
        const out = execSync('docker ps -q --filter ancestor=mcr.microsoft.com/mssql/server:2022-latest', {
            stdio: ['ignore', 'pipe', 'ignore'],
        }).toString().trim();
        const containerId = out.split('\n')[0];
        if (containerId) {
            return {
                type: 'docker',
                execute: (sql) => {
                    execSync(`docker exec -i ${containerId} /opt/mssql-tools18/bin/sqlcmd -S localhost -U "${user}" -P "${password}" -C -b`, {
                        input: sql,
                        stdio: ['pipe', 'pipe', 'pipe'],
                    });
                }
            };
        }
    } catch {
        // docker not available
    }

    return null;
}

const runner = findExecutionMethod();
if (!runner) {
    console.error('::error::Neither sqlcmd nor mssql docker container was found to parse migrations.');
    process.exit(1);
}

if (isSelfTest) {
    console.log(`Running parse-migrations self-test (via ${runner.type})...`);
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
    } catch {
        failedAsExpected = true;
    }
    if (!failedAsExpected) {
        console.error('Self-test failed: syntax error was not caught!');
        process.exit(1);
    }

    console.log('✓ parse-migrations self-test passed');
    process.exit(0);
}

const absDir = resolve(dir);
const files = readdirSync(absDir).filter(f => f.endsWith('.sql')).sort();

if (files.length === 0) {
    console.error(`::error::No migration files found in ${dir} to parse!`);
    process.exit(1);
}

console.log(`Checking ${files.length} migration files in ${dir} with SQL Server SET PARSEONLY ON (via ${runner.type})...`);

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
