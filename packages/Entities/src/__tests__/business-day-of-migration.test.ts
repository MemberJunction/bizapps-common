/**
 * fnBusinessDayOf is a contract other apps' queries call by name (bizapps-sales buckets orders with
 * it), so its shape is pinned here: the name, the one DATETIMEOFFSET argument, DATE out, NULL in →
 * NULL out, the grants, and — the point of it — zone resolution read from fnBusinessToday() instead
 * of a second copy that could drift. The PostgreSQL twin is held to the same shape. Read from the
 * files so a rename or contract break fails before a host runs it.
 */
import { readdirSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const MIGRATIONS_DIR = fileURLToPath(new URL('../../../../migrations/', import.meta.url));
const MIGRATIONS_PG_DIR = fileURLToPath(new URL('../../../../migrations-pg/', import.meta.url));

function newest(dir: string, pattern: RegExp): string {
    const file = readdirSync(dir).filter((f) => pattern.test(f)).sort().pop();
    if (!file) throw new Error(`No migration matching ${pattern} in ${dir}`);
    return file;
}

const file = newest(MIGRATIONS_DIR, /__Business_Day_Of\.sql$/);
const flat = readFileSync(MIGRATIONS_DIR + file, 'utf8').replace(/\s+/g, ' ');
const pgFile = newest(MIGRATIONS_PG_DIR, /__Business_Day_Of\.pg\.sql$/);
const pgFlat = readFileSync(MIGRATIONS_PG_DIR + pgFile, 'utf8').replace(/\s+/g, ' ');

describe('the fnBusinessDayOf migration', () => {
    it('ships a PostgreSQL twin at the same version, named .pg.sql so the converter skips it', () => {
        expect(pgFile.replace(/\.pg\.sql$/, '.sql')).toBe(file);
    });

    it('defines fnBusinessDayOf(@At DATETIMEOFFSET) RETURNS DATE, NULL in → NULL out', () => {
        expect(flat).toContain('CREATE OR ALTER FUNCTION [${flyway:defaultSchema}].[fnBusinessDayOf](@At DATETIMEOFFSET) RETURNS DATE WITH RETURNS NULL ON NULL INPUT');
    });

    it("reads the zone from fnBusinessToday() and converts with it, never a second copy of the config read", () => {
        expect(flat).toContain('CAST(@At AT TIME ZONE bt.SqlZone AS date)');
        expect(flat).toContain('FROM [${flyway:defaultSchema}].[fnBusinessToday]() AS bt');
        expect(flat).not.toContain('InstanceConfiguration');
    });

    it('grants EXECUTE to the roles that read the views', () => {
        expect(flat).toContain('GRANT EXECUTE ON [${flyway:defaultSchema}].[fnBusinessDayOf] TO [cdp_UI], [cdp_Developer], [cdp_Integration]');
    });

    it('the PostgreSQL twin has the same contract against the twin of fnBusinessToday()', () => {
        expect(pgFlat).toContain('CREATE OR REPLACE FUNCTION __mj_bizappscommon."fnBusinessDayOf"("at" timestamptz) RETURNS date LANGUAGE sql STABLE STRICT');
        expect(pgFlat).toContain('("at" AT TIME ZONE bt."SqlZone")::date');
        expect(pgFlat).toContain('FROM __mj_bizappscommon."fnBusinessToday"() bt');
        expect(pgFlat).not.toContain('InstanceConfiguration');
        expect(pgFlat).toContain('GRANT EXECUTE ON FUNCTION __mj_bizappscommon."fnBusinessDayOf" TO "cdp_UI", "cdp_Developer", "cdp_Integration"');
        expect(pgFlat).not.toMatch(/"__mj_[A-Za-z]*[A-Z]/); // a quoted mixed-case schema does not exist on PG
    });
});
