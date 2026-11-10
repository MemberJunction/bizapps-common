#!/usr/bin/env node
/**
 * check-fk-indexes.mjs
 *
 * Verifies that every FOREIGN KEY column declared across migrations in `migrations/`
 * has its corresponding CodeGen-standard `IDX_AUTO_MJ_FKEY_{Table}_{Column}` index
 * (truncated to 128 chars), matching MemberJunction's MC4 schema consistency check.
 *
 * Usage:
 *   node .github/scripts/check-fk-indexes.mjs                  # check ./migrations
 *   node .github/scripts/check-fk-indexes.mjs --dir <path>     # check a custom migrations dir
 *   node .github/scripts/check-fk-indexes.mjs --self-test      # verify the detector fires on missing indexes
 */

import { readdirSync, readFileSync, realpathSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { stripSqlComments } from './strip-sql-comments.mjs';

/**
 * Expected CodeGen FK index name (`IDX_AUTO_MJ_FKEY_{Table}_{Column}`, truncated to 128 chars).
 */
export function expectedFkIndexName(table, column) {
    const raw = `IDX_AUTO_MJ_FKEY_${table}_${column}`;
    return raw.length > 128 ? raw.slice(0, 128) : raw;
}

/**
 * Extract balanced parenthesized body starting at `openParenIndex` (where `text[openParenIndex] === '('`).
 */
function extractParenBody(text, openParenIndex) {
    let depth = 0;
    for (let i = openParenIndex; i < text.length; i++) {
        const ch = text[i];
        if (ch === '(') depth++;
        else if (ch === ')') {
            depth--;
            if (depth === 0) {
                return text.slice(openParenIndex + 1, i);
            }
        }
    }
    return text.slice(openParenIndex + 1);
}

/**
 * Scan an ordered array of `{ file, sql }` migration entries and return:
 * - `foreignKeys`: Map of `table.column` (lowercased) -> `{ table, column, file }`
 * - `indexes`: Set of `table.indexName` (lowercased)
 * - `missing`: Array of `{ table, column, expectedIndex, file }` for any FK without its `IDX_AUTO_MJ_FKEY_*` index
 */
export function scanMigrationFkIndexes(migrations) {
    const foreignKeys = new Map();
    const indexes = new Set();

    const schemaPrefix = String.raw`(?:\[[^\]]+\]|\$\{flyway:defaultSchema\}|[A-Za-z0-9_]+)`;
    const createTableRe = new RegExp(
        String.raw`\bCREATE\s+TABLE\s+${schemaPrefix}\.\[?([A-Za-z0-9_]+)\]?\s*\(`,
        'gi',
    );
    const tableFkRe = /\bFOREIGN\s+KEY\s*\(\s*\[?([A-Za-z0-9_]+)\]?\s*\)\s*REFERENCES\b/gi;
    const alterFkRe = new RegExp(
        String.raw`\bALTER\s+TABLE\s+${schemaPrefix}\.\[?([A-Za-z0-9_]+)\]?\s+(?:WITH\s+(?:CHECK|NOCHECK)\s+)?ADD\s+(?:CONSTRAINT\s+\[?[A-Za-z0-9_]+\]?\s+)?FOREIGN\s+KEY\s*\(\s*\[?([A-Za-z0-9_]+)\]?\s*\)\s*REFERENCES\b`,
        'gi',
    );
    const dropColumnRe = new RegExp(
        String.raw`\bALTER\s+TABLE\s+${schemaPrefix}\.\[?([A-Za-z0-9_]+)\]?\s+DROP\s+COLUMN\s+(?:IF\s+EXISTS\s+)?\[?([A-Za-z0-9_]+)\]?`,
        'gi',
    );
    const createIndexRe = new RegExp(
        String.raw`\bCREATE\s+(?:UNIQUE\s+)?(?:NONCLUSTERED\s+|CLUSTERED\s+)?INDEX\s+\[?([A-Za-z0-9_]+)\]?\s+ON\s+${schemaPrefix}\.\[?([A-Za-z0-9_]+)\]?\s*\(`,
        'gi',
    );

    for (const { file, sql } of migrations) {
        const masked = stripSqlComments(sql);

        let match;
        createTableRe.lastIndex = 0;
        while ((match = createTableRe.exec(masked)) !== null) {
            const table = match[1];
            const openParen = match.index + match[0].length - 1;
            const body = extractParenBody(masked, openParen);
            let fkMatch;
            tableFkRe.lastIndex = 0;
            while ((fkMatch = tableFkRe.exec(body)) !== null) {
                const column = fkMatch[1];
                const key = `${table}.${column}`.toLowerCase();
                if (!foreignKeys.has(key)) {
                    foreignKeys.set(key, { table, column, file });
                }
            }
        }

        alterFkRe.lastIndex = 0;
        while ((match = alterFkRe.exec(masked)) !== null) {
            const table = match[1];
            const column = match[2];
            const key = `${table}.${column}`.toLowerCase();
            if (!foreignKeys.has(key)) {
                foreignKeys.set(key, { table, column, file });
            }
        }

        dropColumnRe.lastIndex = 0;
        while ((match = dropColumnRe.exec(masked)) !== null) {
            const table = match[1];
            const column = match[2];
            foreignKeys.delete(`${table}.${column}`.toLowerCase());
        }

        createIndexRe.lastIndex = 0;
        while ((match = createIndexRe.exec(masked)) !== null) {
            const indexName = match[1];
            const table = match[2];
            indexes.add(`${table}.${indexName}`.toLowerCase());
        }
    }

    const missing = [];
    for (const { table, column, file } of foreignKeys.values()) {
        const expectedIndex = expectedFkIndexName(table, column);
        if (!indexes.has(`${table}.${expectedIndex}`.toLowerCase())) {
            missing.push({ table, column, expectedIndex, file });
        }
    }

    missing.sort((a, b) =>
        `${a.table}.${a.column}`.localeCompare(`${b.table}.${b.column}`),
    );

    return { foreignKeys, indexes, missing };
}

function runSelfTest() {
    const dirtyMigrations = [
        {
            file: 'V202601010001__init.sql',
            sql: `
                CREATE TABLE [\${flyway:defaultSchema}].[Parent] (
                    ID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY
                );
                CREATE TABLE [\${flyway:defaultSchema}].[Child] (
                    ID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
                    ParentID UNIQUEIDENTIFIER NOT NULL,
                    OtherID UNIQUEIDENTIFIER NULL,
                    CONSTRAINT FK_Child_Parent FOREIGN KEY (ParentID) REFERENCES [\${flyway:defaultSchema}].[Parent](ID),
                    CONSTRAINT FK_Child_Other FOREIGN KEY ([OtherID]) REFERENCES [\${flyway:defaultSchema}].[Parent]([ID])
                );
                CREATE NONCLUSTERED INDEX IDX_AUTO_MJ_FKEY_Child_ParentID
                    ON [\${flyway:defaultSchema}].[Child] ([ParentID]);
            `,
        },
    ];

    const dirtyResult = scanMigrationFkIndexes(dirtyMigrations);
    if (
        dirtyResult.missing.length !== 1 ||
        dirtyResult.missing[0].table !== 'Child' ||
        dirtyResult.missing[0].column !== 'OtherID' ||
        dirtyResult.missing[0].expectedIndex !== 'IDX_AUTO_MJ_FKEY_Child_OtherID'
    ) {
        console.error('::error::check-fk-indexes self-test failed: expected Child.OtherID to be reported missing.');
        process.exit(1);
    }

    const repairedMigrations = [
        ...dirtyMigrations,
        {
            file: 'V202601010002__add_index.sql',
            sql: `
                CREATE NONCLUSTERED INDEX IDX_AUTO_MJ_FKEY_Child_OtherID
                    ON [\${flyway:defaultSchema}].[Child] ([OtherID]);
            `,
        },
    ];
    const cleanResult = scanMigrationFkIndexes(repairedMigrations);
    if (cleanResult.missing.length !== 0) {
        console.error('::error::check-fk-indexes self-test failed: expected repaired migrations to have 0 missing FK indexes.');
        process.exit(1);
    }

    console.log('✓ check-fk-indexes self-test passed');
}

function main() {
    if (process.argv.includes('--self-test')) {
        runSelfTest();
        return;
    }

    const dirArg = process.argv.find((_, i, arr) => arr[i - 1] === '--dir') || './migrations';
    const absDir = resolve(dirArg);
    let files;
    try {
        files = readdirSync(absDir)
            .filter((f) => /^[VB][0-9]{12}__.*\.sql$/i.test(f))
            .sort();
    } catch (err) {
        console.error(`::error::Could not read migration directory '${dirArg}' (${absDir}): ${err.message}`);
        process.exit(1);
    }

    if (files.length === 0) {
        console.error(`::error::No migration files found in '${dirArg}'`);
        process.exit(1);
    }

    const migrations = files.map((file) => ({
        file,
        sql: readFileSync(join(absDir, file), 'utf8'),
    }));

    const { foreignKeys, missing } = scanMigrationFkIndexes(migrations);

    if (missing.length > 0) {
        for (const m of missing) {
            console.error(
                `::error file=${join(dirArg, m.file)}::Foreign key ${m.table}.${m.column} (introduced in ${m.file}) is missing its CodeGen index ${m.expectedIndex}`,
            );
        }
        console.error(
            `\n✗ ${missing.length} of ${foreignKeys.size} foreign key column(s) lack an IDX_AUTO_MJ_FKEY_* index.`,
        );
        process.exit(1);
    }

    console.log(
        `✓ All ${foreignKeys.size} foreign key column(s) across ${files.length} migration files have IDX_AUTO_MJ_FKEY_* indexes.`,
    );
}

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
