import { RunQuery } from '@memberjunction/core';
import {
    Assert,
    IntegrationCheckRegistry,
    type IntegrationCheckContext,
    type NamedCheck,
} from '@memberjunction/testing-integration/registry';
import { mjBizAppsCommonOrganizationEntity, mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';
import { COMMON_ENTITIES } from '../entity-names.js';
import { RequireSave, SameID } from '../wire.js';

/**
 * The party lookup queries behind bizapps-party-field, run by name the way the picker runs them.
 * Fixtures make contains-vs-prefix diverge ("Acme Quillmark" contains the term, does not start with
 * it) and carry a per-run stamp so stray rows from an earlier run never match. RunQuery uses the
 * global provider, which the integration bootstrap points at MJAPI, as the picker in the browser does.
 */
interface LookupRow {
    ID: string;
    Name: string;
    Detail: string | null;
}

async function lookup(ctx: IntegrationCheckContext, queryName: string, term: string, domain?: string): Promise<LookupRow[]> {
    const parameters: Record<string, string> = { Term: term };
    if (domain) {
        parameters['Domain'] = domain;
    }
    const result = await new RunQuery().RunQuery(
        { QueryName: queryName, CategoryPath: 'Common', Parameters: parameters },
        ctx.User,
    );
    Assert(result.Success, `${queryName} (${term}) failed: ${result.ErrorMessage ?? 'unknown'}`);
    return (result.Results ?? []) as LookupRow[];
}

function has(rows: LookupRow[], id: string): boolean {
    return rows.some((row) => SameID(row.ID, id));
}

async function newPerson(ctx: IntegrationCheckContext, first: string, last: string, email: string): Promise<mjBizAppsCommonPersonEntity> {
    const person = await ctx.Provider.GetEntityObject<mjBizAppsCommonPersonEntity>(COMMON_ENTITIES.Person, ctx.User);
    person.NewRecord();
    person.FirstName = first;
    person.LastName = last;
    person.Email = email;
    person.Status = 'Active';
    await RequireSave(person, `person ${first} ${last}`);
    return person;
}

async function newOrganization(
    ctx: IntegrationCheckContext,
    name: string,
    website: string | null,
    acronym: string | null = null,
): Promise<mjBizAppsCommonOrganizationEntity> {
    const org = await ctx.Provider.GetEntityObject<mjBizAppsCommonOrganizationEntity>(COMMON_ENTITIES.Organization, ctx.User);
    org.NewRecord();
    org.Name = name;
    org.Website = website;
    org.Acronym = acronym;
    org.Status = 'Active';
    await RequireSave(org, `organization ${name}`);
    return org;
}

const PEOPLE = 'Common: Party Lookup People';
const ORGANIZATIONS = 'Common: Party Lookup Organizations';

const checks: NamedCheck[] = [
    {
        Id: 'party-lookup.PL1',
        Name: 'PL1 — people by last-name prefix, email prefix and email domain',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const stamp = Date.now();
            const zed = await newPerson(ctx, 'Zed', `Quill${stamp}`, `zq${stamp}@aqha${stamp}.com`);
            const ann = await newPerson(ctx, 'Ann', `Zedson${stamp}`, `ann${stamp}@other${stamp}.org`);
            try {
                const byLast = await lookup(ctx, PEOPLE, `quill${stamp}`);
                Assert(has(byLast, zed.ID) && !has(byLast, ann.ID), 'last-name prefix finds Zed only');

                const byEmail = await lookup(ctx, PEOPLE, `zq${stamp}@`);
                Assert(has(byEmail, zed.ID), 'email prefix finds Zed');

                const byDomain = await lookup(ctx, PEOPLE, `aqha${stamp}.com`, `aqha${stamp}.com`);
                Assert(has(byDomain, zed.ID) && !has(byDomain, ann.ID), 'email domain finds Zed only');
                Assert(byDomain.find((row) => SameID(row.ID, zed.ID))?.Detail === zed.Email, 'Detail is the email');
            } finally {
                Assert(await zed.Delete(), 'cleanup Zed');
                Assert(await ann.Delete(), 'cleanup Ann');
            }
        },
    },
    {
        Id: 'party-lookup.PL2',
        Name: 'PL2 — organizations by name prefix (not contains) and website domain',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const stamp = Date.now();
            const mark = await newOrganization(ctx, `Quillmark ${stamp} Ltd`, `https://www.quillmark${stamp}.com/x`);
            const acme = await newOrganization(ctx, `Acme Quillmark ${stamp}`, null);
            try {
                const byName = await lookup(ctx, ORGANIZATIONS, `quillmark ${stamp}`);
                Assert(has(byName, mark.ID), 'name prefix finds Quillmark');
                Assert(!has(byName, acme.ID), 'a name that only contains the term is not a match');

                const byDomain = await lookup(ctx, ORGANIZATIONS, `quillmark${stamp}.com`, `quillmark${stamp}.com`);
                Assert(has(byDomain, mark.ID), 'website domain finds Quillmark');
                Assert(byDomain.find((row) => SameID(row.ID, mark.ID))?.Detail === `quillmark${stamp}.com`, 'Detail is the domain');
            } finally {
                Assert(await mark.Delete(), 'cleanup Quillmark');
                Assert(await acme.Delete(), 'cleanup Acme');
            }
        },
    },
    {
        Id: 'party-lookup.PL4',
        Name: 'PL4 — organizations by acronym prefix; Detail joins acronym and domain',
        RequiresMutation: true,
        Fn: async (ctx) => {
            // Acronym is nvarchar(20): a 13-digit stamp plus a 3-letter prefix fits.
            const acronym = `QZ${Date.now()}X`;
            const withSite = await newOrganization(ctx, `Zephyr Guild ${acronym}`, `https://${acronym.toLowerCase()}.org`, acronym);
            const noSite = await newOrganization(ctx, `Quartz Union ${acronym}`, null, acronym);
            try {
                const byAcronym = await lookup(ctx, ORGANIZATIONS, acronym.slice(0, 10).toLowerCase());
                Assert(has(byAcronym, withSite.ID) && has(byAcronym, noSite.ID), 'acronym prefix finds both, case-insensitively');
                const detailOf = (id: string): string | null | undefined => byAcronym.find((row) => SameID(row.ID, id))?.Detail;
                Assert(detailOf(withSite.ID) === `${acronym} · ${acronym.toLowerCase()}.org`, 'Detail is acronym · domain');
                Assert(detailOf(noSite.ID) === acronym, 'Detail is the acronym alone when there is no website');
            } finally {
                Assert(await withSite.Delete(), 'cleanup Zephyr');
                Assert(await noSite.Delete(), 'cleanup Quartz');
            }
        },
    },
    {
        Id: 'party-lookup.PL3',
        Name: 'PL3 — quote, underscore and percent in the term match literally and never error',
        RequiresMutation: false,
        Fn: async (ctx) => {
            for (const term of [`o'brien`, 'a_b', '50%', '[x']) {
                await lookup(ctx, PEOPLE, term, term);
                await lookup(ctx, ORGANIZATIONS, term, term);
            }
        },
    },
];

for (const check of checks) {
    IntegrationCheckRegistry.Instance.Register(check);
}
