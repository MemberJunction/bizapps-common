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

const markedIDs = jsonFiles(join(REPO, 'metadata')).flatMap((file) => {
    const data = JSON.parse(readFileSync(file, 'utf8')) as MetadataRecord | MetadataRecord[];
    return nestedDeletes(Array.isArray(data) ? data : [data], false);
});

const deletingMigrations = readdirSync(join(REPO, 'migrations'))
    .filter((name) => name.endsWith('.sql'))
    .map((name) => readFileSync(join(REPO, 'migrations', name), 'utf8').toUpperCase())
    .filter((sql) => /\bDELETE\b/.test(sql)); // any form: DELETE FROM t, DELETE alias FROM t JOIN ...

describe('nested metadata deletes are carried by a migration', () => {
    it('finds the nested deletes it guards (never passes on nothing)', () => {
        expect(markedIDs.length).toBeGreaterThan(0);
    });

    for (const id of markedIDs) {
        it(`${id} is removed by a migration`, () => {
            expect(deletingMigrations.some((sql) => sql.includes(id.toUpperCase()))).toBe(true);
        });
    }
});
