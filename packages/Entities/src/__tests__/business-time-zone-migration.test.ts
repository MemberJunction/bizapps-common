/**
 * The migration that every app's "today" view joins. Its shape is a contract: the function name, its
 * two columns, the config row's key and fixed ID, and the fallback to UTC for a zone SQL Server does
 * not know. The PostgreSQL twin's contract: a safe JSON parser that degrades malformed config to UTC
 * instead of raising into every view. Read from the files so a rename or contract break fails before
 * a host runs it.
 */
import { readdirSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const MIGRATIONS_DIR = fileURLToPath(new URL('../../../../migrations/', import.meta.url));
const file = readdirSync(MIGRATIONS_DIR).filter((f) => /__Business_Time_Zone\.sql$/.test(f)).sort().pop();
if (!file) throw new Error('No Business_Time_Zone migration found');
const sql = readFileSync(MIGRATIONS_DIR + file, 'utf8');
const flat = sql.replace(/\s+/g, ' ');

const MIGRATIONS_PG_DIR = fileURLToPath(new URL('../../../../migrations-pg/', import.meta.url));
const pgFile = readdirSync(MIGRATIONS_PG_DIR).filter((f) => /__Business_Time_Zone\.pgonly\.sql$/.test(f)).sort().pop();
if (!pgFile) throw new Error('No Business_Time_Zone PostgreSQL migration found');
const pgSql = readFileSync(MIGRATIONS_PG_DIR + pgFile, 'utf8');
const pgFlat = pgSql.replace(/\s+/g, ' ');

describe('the business time zone migration', () => {
    it('seeds the BizApps.BusinessTimeZone row with its fixed ID, idempotently, through the MJ procedure', () => {
        expect(flat).toContain("'B12A9C15-0168-4C0E-9D3A-4B7E2F1C6A08'");
        expect(flat).toContain("N'BizApps.BusinessTimeZone'");
        expect(flat).toContain('[${mjSchema}].[spCreateInstanceConfiguration]');
        expect(flat).toMatch(/IF NOT EXISTS \(SELECT 1 FROM \[\$\{mjSchema\}\]\.\[InstanceConfiguration\]/);
        expect(flat).toContain(`N'{"iana":"UTC","sql":"UTC"}'`);
    });

    it('defines fnBusinessToday as an inline table-valued function with Today and SqlZone', () => {
        expect(flat).toContain('CREATE OR ALTER FUNCTION [${flyway:defaultSchema}].[fnBusinessToday]()');
        expect(flat).toContain('RETURNS TABLE');
        expect(flat).toContain('AS [Today]');
        expect(flat).toContain('AS [SqlZone]');
        expect(flat).toContain("[FeatureKey] IN (N'Business.TimeZone', N'BizApps.BusinessTimeZone')");
    });

    it('falls back to UTC for a zone name SQL Server does not know, rather than breaking every view', () => {
        expect(flat).toContain('sys.time_zone_info');
        expect(flat).toContain("ELSE N'UTC' END");
    });

    it('grants the function to the roles that read the views', () => {
        expect(flat).toContain('GRANT SELECT ON [${flyway:defaultSchema}].[fnBusinessToday] TO [cdp_UI], [cdp_Developer], [cdp_Integration]');
    });

    it('the PostgreSQL twin degrades an unreadable value to UTC instead of raising into every view', () => {
        expect(pgFlat).toContain('CREATE OR REPLACE FUNCTION __mj_bizappscommon."fnBusinessZoneIana"(p_value text)');
        expect(pgFlat).toContain('EXCEPTION WHEN OTHERS THEN RETURN NULL;');
        expect(pgFlat).toContain('__mj_bizappscommon."fnBusinessZoneIana"(c."Value")');
        expect(pgFlat).not.toMatch(/"__mj_[A-Za-z]*[A-Z]/); // a quoted mixed-case schema does not exist on PG
        expect(pgFlat).not.toMatch(/"Value"\)?,? ?''\)::jsonb|c\."Value"::jsonb|c\."DefaultValue"::jsonb/);
    });
});
