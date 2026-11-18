/**
 * A `deleteRecord` marker on a NESTED metadata record (one under `relatedEntities`) is not applied by
 * `mj sync push`: its deletion pre-scan looks only at each file's top-level records, so the push reports
 * "No deletion operations found" and the row stays in the database — and in the Metadata_Sync migration
 * a release generates from that push. Until MJ applies nested deletes, every such marker needs a
 * migration here that removes the row by its id; this guards that pairing.
 */
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

interface MetadataRecord {
    primaryKey?: { ID?: string };
    deleteRecord?: { delete?: boolean };
    relatedEntities?: Record<string, MetadataRecord[]>;
}

const REPO = fileURLToPath(new URL('../../../../', import.meta.url));

function jsonFiles(dir: string): string[] {
    return readdirSync(dir).flatMap((name) => {
        const path = join(dir, name);
        if (statSync(path).isDirectory()) return jsonFiles(path);
        return name.endsWith('.json') && !name.startsWith('.mj-') ? [path] : [];
    });
}

function nestedDeletes(records: MetadataRecord[], nested: boolean): string[] {
    return records.flatMap((r) => [
        ...(nested && r.deleteRecord?.delete === true && r.primaryKey?.ID ? [r.primaryKey.ID] : []),
        ...Object.values(r.relatedEntities ?? {}).flatMap((children) => nestedDeletes(children, true)),
    ]);
}

/**
 * Strips SQL line comments (`-- ...`) and block comments (`/* ... *\/`) while preserving
 * single-quoted string literals (`'...'`, including escaped `''`) so commented-out UUIDs
 * cannot satisfy the delete check while quoted UUID literals inside SQL statements remain intact.
 */
export function stripSqlCommentsPreservingLiterals(sql: string): string {
    let out = '';
    let i = 0;
    const len = sql.length;

    while (i < len) {
        const ch = sql[i];
        const next = sql[i + 1];

        // Single-quoted string literal (handle '' escape)
        if (ch === "'") {
            out += ch;
            i++;
            while (i < len) {
                const c = sql[i];
                out += c;
                i++;
                if (c === "'") {
                    if (sql[i] === "'") {
                        out += sql[i];
                        i++;
                    } else {
                        break;
                    }
                }
            }
            continue;
        }

        // Single-line comment: -- ... \n
        if (ch === '-' && next === '-') {
            i += 2;
            while (i < len && sql[i] !== '\n') {
                i++;
            }
            continue;
        }

        // Block comment: /* ... */
        if (ch === '/' && next === '*') {
            i += 2;
            while (i < len && !(sql[i] === '*' && sql[i + 1] === '/')) {
                if (sql[i] === '\n') out += '\n';
                i++;
            }
            if (i < len) i += 2;
            continue;
        }

        out += ch;
        i++;
    }

    return out;
}

/**
 * Returns true when `rawSql` (after stripping SQL comments) removes `id` via either:
 * 1. A direct `DELETE ... WHERE ...` statement whose predicate contains `id`, OR
 * 2. An `INSERT INTO @<tableVar> ... VALUES (...id...)` statement paired with a
 *    `DELETE ... JOIN @<tableVar>` statement in the same migration.
 */
export function migrationDeletesId(rawSql: string, id: string): boolean {
    const stripped = stripSqlCommentsPreservingLiterals(rawSql).toUpperCase();
    const targetId = id.trim().toUpperCase();
    if (!targetId || !stripped.includes(targetId)) {
        return false;
    }

    // Split on statement terminators (`;` or T-SQL batch separator `GO` on its own line)
    const statements = stripped
        .split(/;|^\s*GO\s*$/im)
        .map((s) => s.trim())
        .filter(Boolean);

    // Pattern 1: Direct DELETE ... WHERE ... referencing targetId
    for (const stmt of statements) {
        if (/\bDELETE\b[\s\S]*\bWHERE\b/.test(stmt)) {
            const whereIdx = stmt.search(/\bWHERE\b/);
            if (whereIdx !== -1 && stmt.slice(whereIdx).includes(targetId)) {
                return true;
            }
        }
    }

    // Pattern 2: INSERT INTO @TableVar ... VALUES (...targetId...) joined by DELETE ... JOIN @TableVar
    const tableVarsWithId = new Set<string>();
    const insertTableVarRe = /\bINSERT\s+INTO\s+(@[A-Z0-9_]+)\b[\s\S]*?\bVALUES\b([\s\S]*)/i;
    for (const stmt of statements) {
        const match = insertTableVarRe.exec(stmt);
        if (match && match[2].includes(targetId)) {
            tableVarsWithId.add(match[1].toUpperCase());
        }
    }

    if (tableVarsWithId.size > 0) {
        for (const stmt of statements) {
            if (!/\bDELETE\b/.test(stmt)) continue;
            for (const tableVar of tableVarsWithId) {
                const escapedVar = tableVar.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
                const joinRe = new RegExp(`\\bJOIN\\s+${escapedVar}\\b`, 'i');
                const fromWhereRe = new RegExp(`\\bFROM\\s+${escapedVar}\\b`, 'i');
                if (joinRe.test(stmt) || fromWhereRe.test(stmt)) {
                    return true;
                }
            }
        }
    }

    return false;
}

const markedIDs = jsonFiles(join(REPO, 'metadata')).flatMap((file) => {
    const data = JSON.parse(readFileSync(file, 'utf8')) as MetadataRecord | MetadataRecord[];
    return nestedDeletes(Array.isArray(data) ? data : [data], false);
});

const migrationFiles = readdirSync(join(REPO, 'migrations'))
    .filter((name) => name.endsWith('.sql'))
    .map((name) => readFileSync(join(REPO, 'migrations', name), 'utf8'));

describe('nested metadata deletes are carried by a migration', () => {
    it('finds the nested deletes it guards (never passes on nothing)', () => {
        expect(markedIDs.length).toBeGreaterThan(0);
    });

    for (const id of markedIDs) {
        it(`${id} is removed by a migration`, () => {
            expect(migrationFiles.some((sql) => migrationDeletesId(sql, id))).toBe(true);
        });
    }

    describe('migrationDeletesId statement-level guard (#328)', () => {
        const SAMPLE_ID = '01F9747B-6F07-4671-A44E-953113442878';
        const OTHER_ID = '99999999-9999-9999-9999-999999999999';

        it('rejects a UUID that appears only inside a line or block comment', () => {
            const lineCommentSql = `
                DELETE FROM [__mj].[EntityActionParam] WHERE [ID] = '${OTHER_ID}';
                -- DELETE FROM [__mj].[EntityActionParam] WHERE [ID] = '${SAMPLE_ID}';
            `;
            const blockCommentSql = `
                DELETE FROM [__mj].[EntityActionParam] WHERE [ID] = '${OTHER_ID}';
                /* DELETE FROM [__mj].[EntityActionParam] WHERE [ID] = '${SAMPLE_ID}'; */
            `;
            expect(migrationDeletesId(lineCommentSql, SAMPLE_ID)).toBe(false);
            expect(migrationDeletesId(blockCommentSql, SAMPLE_ID)).toBe(false);
        });

        it('rejects a UUID that appears only in SELECT, UPDATE, or non-table-variable INSERT alongside an unrelated DELETE', () => {
            const sql = `
                DELETE FROM [__mj].[EntityActionParam] WHERE [ID] = '${OTHER_ID}';
                UPDATE [__mj].[EntityActionParam] SET [Value] = 'x' WHERE [ID] = '${SAMPLE_ID}';
                SELECT * FROM [__mj].[EntityActionParam] WHERE [ID] = '${SAMPLE_ID}';
            `;
            expect(migrationDeletesId(sql, SAMPLE_ID)).toBe(false);
        });

        it('accepts a direct DELETE ... WHERE statement referencing the UUID', () => {
            const sql = `
                DELETE FROM [\${mjSchema}].[EntityActionParam]
                 WHERE [ID] IN ('${SAMPLE_ID}', '${OTHER_ID}');
            `;
            expect(migrationDeletesId(sql, SAMPLE_ID)).toBe(true);
        });

        it('accepts a table-variable INSERT INTO @Target ... VALUES (...) joined by a DELETE in the same migration', () => {
            const sql = `
                DECLARE @Target TABLE (ID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY);
                INSERT INTO @Target (ID) VALUES ('${SAMPLE_ID}');
                DELETE eap
                FROM [\${mjSchema}].[EntityActionParam] eap
                JOIN @Target t ON t.ID = eap.ID;
            `;
            expect(migrationDeletesId(sql, SAMPLE_ID)).toBe(true);
        });

        it('rejects a table-variable INSERT INTO @Target when no DELETE joins @Target', () => {
            const sql = `
                DECLARE @Target TABLE (ID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY);
                INSERT INTO @Target (ID) VALUES ('${SAMPLE_ID}');
                DELETE FROM [\${mjSchema}].[EntityActionParam] WHERE [ID] = '${OTHER_ID}';
            `;
            expect(migrationDeletesId(sql, SAMPLE_ID)).toBe(false);
        });
    });
});
