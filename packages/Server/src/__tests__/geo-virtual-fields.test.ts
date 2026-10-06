/**
 * MJ's geo virtual columns (`__mj_Latitude`, `__mj_Longitude`, and the embedded
 * `__mj_Latitude_{FK}` form) must be on this package's GraphQL output types, and nullable.
 *
 * The GraphQL client builds a single-record query from the host's EntityField metadata, not from
 * this package. A geo EntityField the output type lacks fails the whole load:
 * `Cannot query field "_mj__Latitude" on type "mjBizAppsCommonAddress_"`. That shipped in
 * common-server 5.47.0 (MemberJunction/bc-aidp-next-golive#295): V202609101800 registered the two
 * Address fields after the generated code was last regenerated for Address, and nothing compared
 * the two.
 *
 * Declared non-null, the field fails the other way. The columns are NULL for every record that has
 * not been geocoded, and GraphQL rejects a null on a non-null field. MJ 6.1.x's generator emits
 * `__mj_` fields non-null whatever `AllowsNull` says (fixed on MJ `next` in #4635), which is how
 * accounting-server 0.16.0 shipped them. A regeneration on that generator must not reach here.
 *
 * Host truth comes from the migrations: every EntityField row this repo's chain inserts for a geo
 * virtual column, mapped to its entity through the `'<id>', -- Entity: <name>` comments CodeGen
 * emits. A later migration that removes one with
 * `DELETE FROM [...].[EntityField] WHERE EntityID = '<id>' AND Name IN ('__mj_Latitude', ...)` takes it
 * back out, in chain order, so the test stops demanding a field the host no longer has (#215).
 */
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

interface OutputField {
    Name: string;
    Decorator: string;
    Optional: boolean;
    TypeScriptType: string;
}

interface OutputType {
    ClassName: string;
    EntityName: string;
    Fields: OutputField[];
}

interface GeoEntityField {
    EntityID: string;
    FieldName: string;
}

const REPO = fileURLToPath(new URL('../../../../', import.meta.url));
const SERVER_SCHEMA = join(REPO, 'packages/Server/src/generated/graphql-schemas/__mj_BizAppsCommon.ts');
const MIGRATIONS = join(REPO, 'migrations');

/** `__mj_Latitude`, `__mj_Longitude`, `__mj_Latitude_ShipToAddressID`, in either schema spelling. */
const GEO_FIELD = String.raw`(?:__mj|\$\{mjSchema\})_(?:Latitude|Longitude)(?:_\w+)?`;
const GEO_GRAPHQL_FIELD = /^_mj__(?:Latitude|Longitude)(?:_\w+)?$/;

/** The generator's rule: GraphQL names cannot start with `__`, so `__mj…` becomes `_mj_` + the rest. */
function graphQLName(entityFieldName: string): string {
    const codeName = entityFieldName.replace(/^\$\{mjSchema\}/, '__mj');
    return codeName.startsWith('__mj') ? `_mj_${codeName.substring(4)}` : codeName;
}

function readMigrations(): string[] {
    return readdirSync(MIGRATIONS)
        .filter((name) => name.endsWith('.sql'))
        .sort()
        .map((name) => readFileSync(join(MIGRATIONS, name), 'utf8'));
}

/** Entity ID (upper case) to entity name, from the comment CodeGen puts beside every EntityID value. */
function entityNamesByID(migrations: string[]): Map<string, string> {
    const names = new Map<string, string>();
    const pattern = /'([0-9A-Fa-f-]{36})'\s*,\s*--\s*Entity:\s*(MJ_BizApps_Common:[^\r\n]*)/g;
    for (const sql of migrations) {
        for (const m of sql.matchAll(pattern)) names.set(m[1].toUpperCase(), m[2].trim());
    }
    return names;
}

const INSERTED_GEO_FIELD = new RegExp(
    String.raw`IF\s+NOT\s+EXISTS\s*\(\s*SELECT\s+1\s+FROM\s+\[[^\]]+\]\.\[?EntityField\]?\s+WHERE\s+ID\s*=\s*'[^']+'\s+OR\s+\(\s*EntityID\s*=\s*'([0-9A-Fa-f-]{36})'\s+AND\s+Name\s*=\s*'(${GEO_FIELD})'\s*\)`,
    'g',
);
const DELETED_GEO_FIELDS = new RegExp(
    String.raw`DELETE\s+FROM\s+\[[^\]]+\]\.\[?EntityField\]?\s+WHERE\s+EntityID\s*=\s*'([0-9A-Fa-f-]{36})'\s+AND\s+Name\s+IN\s*\(([^)]*)\)`,
    'g',
);

function geoFieldKey(entityID: string, fieldName: string): string {
    return `${entityID.toUpperCase()}|${graphQLName(fieldName)}`;
}

/**
 * Geo EntityField rows the chain leaves in place: inserted with the `IF NOT EXISTS` guard both CodeGen
 * and the heals use, minus those a later migration deletes. Each migration is applied in chain order.
 */
function geoEntityFields(migrations: string[]): GeoEntityField[] {
    const found = new Map<string, GeoEntityField>();
    for (const sql of migrations) {
        for (const m of sql.matchAll(INSERTED_GEO_FIELD)) {
            found.set(geoFieldKey(m[1], m[2]), { EntityID: m[1].toUpperCase(), FieldName: graphQLName(m[2]) });
        }
        for (const m of sql.matchAll(DELETED_GEO_FIELDS)) {
            for (const name of m[2].matchAll(/'([^']+)'/g)) found.delete(geoFieldKey(m[1], name[1]));
        }
    }
    return [...found.values()];
}

/** One `@Field(...)` decorator plus the property it decorates. */
function parseField(chunk: string): OutputField | undefined {
    const declarations = [...chunk.matchAll(/\n\s*(\w+)(\?)?:\s*([^;\n]+);/g)];
    const last = declarations.at(-1);
    if (!last || last.index === undefined) return undefined;
    return {
        Name: last[1],
        Decorator: chunk.substring(0, last.index),
        Optional: last[2] === '?',
        TypeScriptType: last[3].trim(),
    };
}

function parseFields(body: string): OutputField[] {
    return body
        .split('@Field(')
        .slice(1)
        .map(parseField)
        .filter((f): f is OutputField => f !== undefined);
}

/** The entity output types, each introduced by CodeGen's `// ENTITY CLASS for <entity>` banner. */
function parseOutputTypes(source: string): OutputType[] {
    const banners = [...source.matchAll(/\/\/ ENTITY CLASS for ([^\r\n]+)/g)];
    return banners.map((banner) => {
        const from = banner.index ?? 0;
        const header = /export class (\w+) \{/.exec(source.substring(from));
        if (!header || header.index === undefined) throw new Error(`No class after the banner for ${banner[1]}`);
        const bodyStart = from + header.index + header[0].length;
        const bodyEnd = source.indexOf('\n}', bodyStart);
        return {
            ClassName: header[1],
            EntityName: banner[1].trim(),
            Fields: parseFields(source.substring(bodyStart, bodyEnd)),
        };
    });
}

function isNullableFloat(field: OutputField): boolean {
    return (
        /^\s*\(\)\s*=>\s*Float\b/.test(field.Decorator) &&
        /\bnullable:\s*true\b/.test(field.Decorator) &&
        field.Optional &&
        field.TypeScriptType === 'number'
    );
}

const migrations = readMigrations();
const entityNames = entityNamesByID(migrations);
const geoFields = geoEntityFields(migrations);
const outputTypes = parseOutputTypes(readFileSync(SERVER_SCHEMA, 'utf8'));

function entityIDFor(entity: string): string | undefined {
    return [...entityNames].find(([, name]) => name === `MJ_BizApps_Common: ${entity}`)?.[0];
}

function outputTypeFor(entityName: string): OutputType | undefined {
    return outputTypes.find((t) => t.EntityName === entityName);
}

describe('MJ geo virtual fields on the GraphQL output types', () => {
    it('parses what it guards (never passes on nothing)', () => {
        expect(outputTypes.length).toBeGreaterThan(20);
        expect(outputTypeFor('MJ_BizApps_Common: Activities')?.Fields.length).toBeGreaterThan(10);
        expect(geoFields.length).toBeGreaterThanOrEqual(4);
        const addressID = entityIDFor('Addresses');
        expect(addressID).toBeDefined();
        expect(geoFields.filter((f) => f.EntityID === addressID).map((f) => f.FieldName).sort()).toEqual([
            '_mj__Latitude',
            '_mj__Longitude',
        ]);
    });

    it('People and Organizations carry no geo virtual fields once V202610062130 deletes them (#215)', () => {
        for (const entity of ['People', 'Organizations']) {
            const id = entityIDFor(entity);
            expect(id, `no migration names ${entity}`).toBeDefined();
            expect(geoFields.filter((f) => f.EntityID === id)).toEqual([]);
        }
    });

    it('mjBizAppsCommonAddress_ declares nullable _mj__Latitude and _mj__Longitude (bc-aidp-next-golive#295)', () => {
        const address = outputTypes.find((t) => t.ClassName === 'mjBizAppsCommonAddress_');
        expect(address).toBeDefined();
        for (const name of ['_mj__Latitude', '_mj__Longitude']) {
            const field = address?.Fields.find((f) => f.Name === name);
            expect(field, `${name} is missing from mjBizAppsCommonAddress_`).toBeDefined();
            expect(field && isNullableFloat(field), `${name} must be @Field(() => Float, {nullable: true}) ${name}?: number`).toBe(true);
        }
    });

    for (const geo of geoFields) {
        const entityName = entityNames.get(geo.EntityID) ?? geo.EntityID;
        it(`${entityName} declares its migration-registered ${geo.FieldName}, nullable`, () => {
            expect(entityNames.has(geo.EntityID), `no migration names entity ${geo.EntityID}`).toBe(true);
            const type = outputTypeFor(entityName);
            expect(type, `no output type for ${entityName}`).toBeDefined();
            const field = type?.Fields.find((f) => f.Name === geo.FieldName);
            expect(field, `${type?.ClassName} lacks ${geo.FieldName}, so every single-record load fails`).toBeDefined();
            expect(field && isNullableFloat(field), `${type?.ClassName}.${geo.FieldName} must be a nullable Float`).toBe(true);
        });
    }

    it('no output type declares a geo virtual field non-null', () => {
        const nonNull = outputTypes.flatMap((t) =>
            t.Fields.filter((f) => GEO_GRAPHQL_FIELD.test(f.Name) && !isNullableFloat(f)).map((f) => `${t.ClassName}.${f.Name}`),
        );
        expect(nonNull).toEqual([]);
    });
});
