import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(HERE, '..', '..', '..', '..');
const SWEEP_CSV_PATH = resolve(REPO_ROOT, '.mj', 'specs', 'epic-1b-limits-sweep-bizapps-common.csv');
const SWEEP_MD_PATH = resolve(REPO_ROOT, '.mj', 'specs', 'epic-1b-limits-sweep-bizapps-common.md');
const CI_WORKFLOW_PATH = resolve(REPO_ROOT, '.github', 'workflows', 'ci.yml');

const EXPECTED_HEADER = ['File', 'Line', 'Literal', 'SymbolOrContext', 'Category', 'ActionRequired', 'Notes'] as const;
const VALID_CATEGORIES = new Set(['RunawayGuard', 'ResourceGuard', 'ProtocolLimit', 'UX', 'Tuning']);

interface SweepRow {
    File: string;
    Line: number;
    Literal: string;
    SymbolOrContext: string;
    Category: string;
    ActionRequired: string;
    Notes: string;
}

/**
 * Parses an RFC-4180 CSV document into header and data rows without weak typing.
 */
function parseCsvLines(csvText: string): string[][] {
    const rows: string[][] = [];
    let currentRow: string[] = [];
    let currentField = '';
    let inQuotes = false;

    for (let i = 0; i < csvText.length; i++) {
        const ch = csvText[i];
        if (inQuotes) {
            if (ch === '"' && csvText[i + 1] === '"') {
                currentField += '"';
                i++;
            } else if (ch === '"') {
                inQuotes = false;
            } else {
                currentField += ch;
            }
            continue;
        }

        if (ch === '"') {
            inQuotes = true;
        } else if (ch === ',') {
            currentRow.push(currentField);
            currentField = '';
        } else if (ch === '\r') {
            // Normalize CRLF line endings
        } else if (ch === '\n') {
            currentRow.push(currentField);
            if (currentRow.some((cell) => cell.length > 0)) {
                rows.push(currentRow);
            }
            currentRow = [];
            currentField = '';
        } else {
            currentField += ch;
        }
    }

    if (currentField.length > 0 || currentRow.length > 0) {
        currentRow.push(currentField);
        if (currentRow.some((cell) => cell.length > 0)) {
            rows.push(currentRow);
        }
    }

    return rows;
}

function loadSweepRows(): { header: string[]; rows: SweepRow[] } {
    const raw = readFileSync(SWEEP_CSV_PATH, 'utf8');
    const parsed = parseCsvLines(raw);
    const header = parsed[0] ?? [];
    const rows: SweepRow[] = parsed.slice(1).map((cols) => ({
        File: cols[0] ?? '',
        Line: Number(cols[1] ?? ''),
        Literal: cols[2] ?? '',
        SymbolOrContext: cols[3] ?? '',
        Category: cols[4] ?? '',
        ActionRequired: cols[5] ?? '',
        Notes: cols[6] ?? '',
    }));
    return { header, rows };
}

describe('Epic 1b limits sweep report integrity', () => {
    it('ships the CSV and Markdown spec artifacts', () => {
        expect(existsSync(SWEEP_CSV_PATH)).toBe(true);
        expect(existsSync(SWEEP_MD_PATH)).toBe(true);
    });

    it('parses cleanly with the exact canonical columns and valid Epic 1 categories', () => {
        const raw = readFileSync(SWEEP_CSV_PATH, 'utf8');
        const parsed = parseCsvLines(raw);
        expect(parsed.length).toBeGreaterThan(1);

        const { header, rows } = loadSweepRows();
        expect(header).toEqual([...EXPECTED_HEADER]);

        for (let idx = 0; idx < parsed.length - 1; idx++) {
            expect(parsed[idx + 1]).toHaveLength(EXPECTED_HEADER.length);
            const row = rows[idx];
            expect(row.File.length).toBeGreaterThan(0);
            expect(Number.isInteger(row.Line) && row.Line > 0).toBe(true);
            expect(row.Literal.length).toBeGreaterThan(0);
            expect(row.SymbolOrContext.length).toBeGreaterThan(0);
            expect(VALID_CATEGORIES.has(row.Category)).toBe(true);
            expect(row.ActionRequired.length).toBeGreaterThan(0);
            expect(row.Notes.length).toBeGreaterThan(0);
        }
    });

    it('references real files, valid line numbers, and matching literals in the repository', () => {
        const { rows } = loadSweepRows();
        const fileLineCache = new Map<string, string[]>();

        for (const row of rows) {
            const absPath = resolve(REPO_ROOT, row.File);
            expect(existsSync(absPath), `Missing file referenced in CSV: ${row.File}`).toBe(true);

            let lines = fileLineCache.get(row.File);
            if (!lines) {
                lines = readFileSync(absPath, 'utf8').split(/\r?\n/);
                fileLineCache.set(row.File, lines);
            }

            expect(row.Line, `Line ${row.Line} out of range for ${row.File}`).toBeGreaterThanOrEqual(1);
            expect(row.Line, `Line ${row.Line} out of range for ${row.File}`).toBeLessThanOrEqual(lines.length);

            const lineText = lines[row.Line - 1];
            expect(
                lineText.includes(row.Literal),
                `Expected ${row.File}:${row.Line} ("${lineText.trim()}") to contain literal "${row.Literal}"`,
            ).toBe(true);
        }
    });

    it('covers all key Angular bounding literals, resolver wiring, and zero-hit category documentation', () => {
        const { rows } = loadSweepRows();
        const angularRows = rows.filter((row) => row.File.startsWith('packages/Angular/'));
        const angularFiles = new Set(angularRows.map((row) => row.File));

        expect(angularFiles.has('packages/Angular/src/lib/config/limits.config.ts')).toBe(true);
        expect(angularFiles.has('packages/Angular/src/lib/components/party-field/party-field.component.ts')).toBe(true);
        expect(angularFiles.has('packages/Angular/src/lib/components/selling-company-field/selling-company-field.component.ts')).toBe(true);
        expect(angularFiles.has('packages/Angular/src/lib/components/relationship-graph/common-relationship-graph.component.ts')).toBe(true);
        expect(angularFiles.has('packages/Angular/src/lib/data/directory-queries.ts')).toBe(true);

        const resolvedInAngular = angularRows.filter((row) => row.ActionRequired === 'ResolvedInResolver');
        expect(resolvedInAngular.length).toBe(13);
        expect(resolvedInAngular.every((row) => row.File === 'packages/Angular/src/lib/config/limits.config.ts')).toBe(true);

        const protocolLimits = rows.filter((row) => row.Category === 'ProtocolLimit');
        expect(protocolLimits.length).toBe(5);
        expect(protocolLimits.every((row) => row.ActionRequired === 'AnnotatedProtocolLimit')).toBe(true);

        const md = readFileSync(SWEEP_MD_PATH, 'utf8');
        for (const category of VALID_CATEGORIES) {
            expect(md).toContain(category);
        }
        expect(md).toContain('`RunawayGuard` (`0` hits repo-wide)');
        expect(md).toContain('`ProtocolLimit` (`0` hits in `packages/Angular`, `5` hits in `packages/ActivitySync`)');

        // Pin exact per-bucket & per-category CSV counts so CSV and Markdown summary cannot drift.
        const countByCategory = (subset: SweepRow[]) => {
            const counts: Record<string, number> = {
                RunawayGuard: 0,
                ResourceGuard: 0,
                ProtocolLimit: 0,
                UX: 0,
                Tuning: 0,
            };
            for (const row of subset) {
                counts[row.Category] = (counts[row.Category] ?? 0) + 1;
            }
            return counts;
        };

        const otherRows = rows.filter((row) => !row.File.startsWith('packages/Angular/'));
        const angularCounts = countByCategory(angularRows);
        const otherCounts = countByCategory(otherRows);
        const totalCounts = countByCategory(rows);

        expect(angularRows.length).toBe(37);
        expect(angularCounts).toEqual({
            RunawayGuard: 0,
            ResourceGuard: 5,
            ProtocolLimit: 0,
            UX: 27,
            Tuning: 5,
        });

        expect(otherRows.length).toBe(33);
        expect(otherCounts).toEqual({
            RunawayGuard: 0,
            ResourceGuard: 11,
            ProtocolLimit: 5,
            UX: 1,
            Tuning: 16,
        });

        expect(rows.length).toBe(70);
        expect(totalCounts).toEqual({
            RunawayGuard: 0,
            ResourceGuard: 16,
            ProtocolLimit: 5,
            UX: 28,
            Tuning: 21,
        });

        // Verify the Markdown Section 3 summary table matches the exact CSV counts.
        const stripMd = (cell: string) => cell.replace(/\*\*/g, '').replace(/`/g, '').trim();
        const tableRows = md
            .split(/\r?\n/)
            .filter((line) => line.startsWith('|'))
            .map((line) => line.split('|').slice(1, -1).map(stripMd));

        const expectedTableRows: Array<[string, number, number, number]> = [
            ['RunawayGuard', angularCounts.RunawayGuard, otherCounts.RunawayGuard, totalCounts.RunawayGuard],
            ['ResourceGuard', angularCounts.ResourceGuard, otherCounts.ResourceGuard, totalCounts.ResourceGuard],
            ['ProtocolLimit', angularCounts.ProtocolLimit, otherCounts.ProtocolLimit, totalCounts.ProtocolLimit],
            ['UX', angularCounts.UX, otherCounts.UX, totalCounts.UX],
            ['Tuning', angularCounts.Tuning, otherCounts.Tuning, totalCounts.Tuning],
            ['Total', angularRows.length, otherRows.length, rows.length],
        ];
        for (const [label, ang, oth, tot] of expectedTableRows) {
            const matched = tableRows.find((cols) => cols[0] === label);
            expect(matched, `Missing Markdown Section 3 table row for "${label}"`).toBeDefined();
            expect(Number(matched![1])).toBe(ang);
            expect(Number(matched![2])).toBe(oth);
            expect(Number(matched![3])).toBe(tot);
        }
    });

    it('verifies an active GitHub Actions CI workflow targeting branch next exists', () => {
        expect(existsSync(CI_WORKFLOW_PATH)).toBe(true);
        const ciYml = readFileSync(CI_WORKFLOW_PATH, 'utf8');
        expect(ciYml).toContain('branches: [next]');
        expect(ciYml).toContain('timeout-minutes:');
        expect(ciYml).toContain('concurrency:');
        expect(ciYml).toContain('pnpm run build:packages');
        expect(ciYml).toContain('pnpm run test');
    });
});
