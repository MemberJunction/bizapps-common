import { MJCompanyEntity } from '@memberjunction/core-entities';
import { Assert, IntegrationCheckRegistry, type IntegrationCheckContext, type NamedCheck } from '@memberjunction/testing-integration/registry';
import { CompanySenderIdentityEntity } from '@mj-biz-apps/common-entities';
import { COMMON_ENTITIES } from '../entity-names.js';
import { FindRows, Quote, RequireSave } from '../wire.js';

/**
 * Company sender identities over the wire. Each check owns a throwaway `MJ: Companies` row
 * (COM-WORLD Sender Co <random>) and deletes it and every register row it made, whatever happened.
 * It never touches an existing company. Lower-case suffix keeps the `.test` addresses valid.
 */
interface IdentityRow {
    ID: string;
    Address: string;
    IsDefault: boolean;
}

interface Fixture {
    company: MJCompanyEntity;
    suffix: string;
    made: CompanySenderIdentityEntity[];
}

function newSuffix(): string {
    return `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`.toLowerCase();
}

async function createCompany(ctx: IntegrationCheckContext, suffix: string): Promise<MJCompanyEntity> {
    const name = `COM-WORLD Sender Co ${suffix}`;
    const company = await ctx.Provider.GetEntityObject<MJCompanyEntity>(COMMON_ENTITIES.Company, ctx.User);
    company.NewRecord();
    company.Name = name;
    company.Description = 'Throwaway fixture for sender-identities integration checks';
    const saved = await company.Save();
    Assert(
        saved,
        `integration user could not create an MJ: Companies fixture "${name}": ${company.LatestResult?.CompleteMessage ?? 'unknown server message'}`,
    );
    return company;
}

async function addIdentity(
    ctx: IntegrationCheckContext,
    fixture: Fixture,
    address: string,
    isDefault = false,
): Promise<CompanySenderIdentityEntity> {
    const row = await newIdentity(ctx, fixture, address, isDefault);
    await RequireSave(row, `sender identity ${address} for ${fixture.company.Name}`);
    fixture.made.push(row);
    return row;
}

async function newIdentity(
    ctx: IntegrationCheckContext,
    fixture: Fixture,
    address: string,
    isDefault: boolean,
): Promise<CompanySenderIdentityEntity> {
    const row = await ctx.Provider.GetEntityObject<CompanySenderIdentityEntity>(COMMON_ENTITIES.CompanySenderIdentity, ctx.User);
    row.NewRecord();
    row.CompanyID = fixture.company.ID;
    row.Kind = 'Mailbox';
    row.Address = address;
    row.IsDefault = isDefault;
    return row;
}

async function listIdentities(ctx: IntegrationCheckContext, fixture: Fixture): Promise<IdentityRow[]> {
    return FindRows<IdentityRow>(ctx, COMMON_ENTITIES.CompanySenderIdentity, `CompanyID='${Quote(fixture.company.ID)}'`, ['ID', 'Address', 'IsDefault']);
}

/** Deletes register rows by company (catches rows a failed Save may have left), then the company. */
async function cleanup(ctx: IntegrationCheckContext, fixture: Fixture): Promise<string[]> {
    const problems: string[] = [];
    const name = fixture.company.Name;
    try {
        const ids = (await listIdentities(ctx, fixture)).map((r) => r.ID.toLowerCase());
        const known = new Map(fixture.made.map((r) => [r.ID.toLowerCase(), r]));
        for (const id of ids) {
            const row = known.get(id) ?? (await loadIdentity(ctx, id));
            if (!(await row.Delete())) problems.push(`delete sender identity ${row.Address} of ${name}: ${row.LatestResult?.CompleteMessage ?? 'unknown'}`);
        }
    } catch (err) {
        problems.push(`clean register rows of ${name}: ${err instanceof Error ? err.message : String(err)}`);
    }
    if (!(await fixture.company.Delete())) problems.push(`delete company ${name}: ${fixture.company.LatestResult?.CompleteMessage ?? 'unknown'}`);
    return problems;
}

async function loadIdentity(ctx: IntegrationCheckContext, id: string): Promise<CompanySenderIdentityEntity> {
    const row = await ctx.Provider.GetEntityObject<CompanySenderIdentityEntity>(COMMON_ENTITIES.CompanySenderIdentity, ctx.User);
    const loaded = await row.Load(id);
    Assert(loaded, `could not load sender identity ${id} for cleanup`);
    return row;
}

async function withFixture(ctx: IntegrationCheckContext, body: (fixture: Fixture) => Promise<void>): Promise<void> {
    const suffix = newSuffix();
    const fixture: Fixture = { company: await createCompany(ctx, suffix), suffix, made: [] };
    let bodyError: Error | null = null;
    try {
        await body(fixture);
    } catch (err) {
        bodyError = err instanceof Error ? err : new Error(String(err));
    }
    const problems = await cleanup(ctx, fixture);
    if (bodyError && problems.length > 0) throw new Error(`${bodyError.message} | cleanup also failed: ${problems.join('; ')}`);
    if (bodyError) throw bodyError;
    Assert(problems.length === 0, `cleanup failed: ${problems.join('; ')}`);
}

const checks: NamedCheck[] = [
    {
        Id: 'sender-identities.SI1',
        Name: 'SI1 — a padded, mixed-case mailbox is stored trimmed and lower-case, not default',
        RequiresMutation: true,
        Fn: (ctx) =>
            withFixture(ctx, async (fx) => {
                const expected = `hr@${fx.suffix}.test`;
                await addIdentity(ctx, fx, `  HR@${fx.suffix}.test `);
                const rows = await listIdentities(ctx, fx);
                Assert(rows.length === 1, `${fx.company.Name}: expected 1 identity, found ${rows.length}`);
                Assert(rows[0].Address === expected, `${fx.company.Name}: address stored as "${rows[0].Address}", expected "${expected}"`);
                Assert(rows[0].IsDefault === false, `${expected} of ${fx.company.Name} must not be default`);
            }),
    },
    {
        Id: 'sender-identities.SI2',
        Name: 'SI2 — the same address in another case is refused after normalisation',
        RequiresMutation: true,
        Fn: (ctx) =>
            withFixture(ctx, async (fx) => {
                const address = `hr@${fx.suffix}.test`;
                await addIdentity(ctx, fx, address);
                const duplicate = await newIdentity(ctx, fx, `HR@${fx.suffix}.test`, false);
                const saved = await duplicate.Save();
                if (saved) fx.made.push(duplicate);
                Assert(!saved, `${fx.company.Name}: duplicate of ${address} was saved`);
                const message = duplicate.LatestResult?.CompleteMessage ?? duplicate.LatestResult?.Message ?? '';
                Assert(message.toLowerCase().includes(address), `${fx.company.Name}: refusal message should name ${address}, got "${message}"`);
                const rows = await listIdentities(ctx, fx);
                Assert(rows.length === 1, `${fx.company.Name}: expected 1 identity after refused duplicate, found ${rows.length}`);
            }),
    },
    {
        Id: 'sender-identities.SI3',
        Name: 'SI3 — one default per company: demote-then-promote works, promoting alone is refused',
        RequiresMutation: true,
        Fn: (ctx) =>
            withFixture(ctx, async (fx) => {
                const a = await addIdentity(ctx, fx, `a@${fx.suffix}.test`);
                const b = await addIdentity(ctx, fx, `b@${fx.suffix}.test`);
                a.IsDefault = true;
                await RequireSave(a, `promote ${a.Address} of ${fx.company.Name}`);

                b.IsDefault = true;
                const refused = await b.Save();
                Assert(!refused, `${fx.company.Name}: promoting ${b.Address} while ${a.Address} is default must be refused`);
                b.IsDefault = false;

                a.IsDefault = false;
                await RequireSave(a, `demote ${a.Address} of ${fx.company.Name}`);
                b.IsDefault = true;
                await RequireSave(b, `promote ${b.Address} of ${fx.company.Name}`);

                const defaults = (await listIdentities(ctx, fx)).filter((r) => r.IsDefault);
                Assert(defaults.length === 1, `${fx.company.Name}: expected exactly 1 default, found ${defaults.length}`);
                Assert(defaults[0].Address === b.Address, `${fx.company.Name}: default should be ${b.Address}, is ${defaults[0].Address}`);
            }),
    },
];

for (const check of checks) {
    IntegrationCheckRegistry.Instance.Register(check);
}
