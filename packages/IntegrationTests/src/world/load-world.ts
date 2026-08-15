/**
 * COM-WORLD — committed party directory over the GraphQL wire.
 *
 * Types (Organization Type, Address Type, Contact Type, Relationship Type) are
 * LOOKED UP from shipped metadata. Missing types fail loudly.
 *
 * People, organizations, addresses, contact methods and relationships are
 * upserted through typed entity subclasses via ctx.Provider.
 */
import type { IntegrationCheckContext } from '@memberjunction/testing-integration/registry';
import { Assert } from '@memberjunction/testing-integration/registry';
import {
    mjBizAppsCommonAddressEntity,
    mjBizAppsCommonAddressLinkEntity,
    mjBizAppsCommonContactMethodEntity,
    mjBizAppsCommonOrganizationEntity,
    mjBizAppsCommonPersonEntity,
    mjBizAppsCommonRelationshipEntity,
} from '@mj-biz-apps/common-entities';
import { COMMON_ENTITIES, WORLD_EMAIL_DOMAIN } from '../entity-names.js';
import { FindId, FindRows, Quote, RequireSave } from '../wire.js';
import { SetWorld, type WorldPerson, type WorldState } from './world.js';

export async function LoadWorld(ctx: IntegrationCheckContext): Promise<WorldState> {
    const world: WorldState = {
        OrganizationTypeIDs: await nameMap(ctx, COMMON_ENTITIES.OrganizationType),
        AddressTypeIDs: await nameMap(ctx, COMMON_ENTITIES.AddressType),
        ContactTypeIDs: await nameMap(ctx, COMMON_ENTITIES.ContactType),
        RelationshipTypeIDs: await nameMap(ctx, COMMON_ENTITIES.RelationshipType),
        Organizations: {},
        People: {},
        Addresses: {},
    };

    for (const needed of ['Corporation', 'LLC', 'Non-Profit', 'Educational Institution']) {
        Assert(!!world.OrganizationTypeIDs[needed], `Organization Type '${needed}' missing — push metadata/organization-types`);
    }
    Assert(!!world.AddressTypeIDs['Work'] || !!world.AddressTypeIDs['Business'] || Object.keys(world.AddressTypeIDs).length > 0, 'no address types');
    Assert(Object.keys(world.ContactTypeIDs).length > 0, 'no contact types — push metadata/contact-types');
    Assert(Object.keys(world.RelationshipTypeIDs).length > 0, 'no relationship types — push metadata/relationship-types');

    await loadOrganizations(ctx, world);
    await loadPeople(ctx, world);
    await loadAddresses(ctx, world);
    await loadContacts(ctx, world);
    await loadRelationships(ctx, world);

    SetWorld(world);
    return world;
}

export async function GetOrLoadWorld(ctx: IntegrationCheckContext): Promise<WorldState> {
    const { GetWorld } = await import('./world.js');
    return GetWorld() ?? LoadWorld(ctx);
}

async function nameMap(ctx: IntegrationCheckContext, entityName: string): Promise<Record<string, string>> {
    const rows = await FindRows<{ ID: string; Name: string }>(ctx, entityName, '', ['ID', 'Name']);
    const map: Record<string, string> = {};
    for (const row of rows) {
        map[row.Name] = row.ID;
    }
    return map;
}

async function loadOrganizations(ctx: IntegrationCheckContext, world: WorldState): Promise<void> {
    const defs: Array<{ Code: string; Name: string; Type: string; Email: string; Parent?: string }> = [
        { Code: 'RIV', Name: 'Riverside Library', Type: 'Non-Profit', Email: `hello@riverside.${WORLD_EMAIL_DOMAIN}` },
        { Code: 'BCP', Name: 'Blue Cypress Press', Type: 'Corporation', Email: `hello@bcp.${WORLD_EMAIL_DOMAIN}` },
        { Code: 'HH', Name: 'Harbor House', Type: 'LLC', Email: `desk@harbor.${WORLD_EMAIL_DOMAIN}` },
        { Code: 'NGS', Name: 'Northgate Schools', Type: 'Educational Institution', Email: `office@ngs.${WORLD_EMAIL_DOMAIN}` },
        { Code: 'SUM', Name: 'Summit University', Type: 'Educational Institution', Email: `hello@summit.${WORLD_EMAIL_DOMAIN}` },
        { Code: 'ATL', Name: 'Atlas Athletics', Type: 'LLC', Email: `desk@atlas.${WORLD_EMAIL_DOMAIN}` },
        { Code: 'IMP', Name: 'Blue Cypress Imprint', Type: 'Corporation', Email: `imprint@bcp.${WORLD_EMAIL_DOMAIN}`, Parent: 'BCP' },
    ];

    for (const def of defs) {
        const typeID = world.OrganizationTypeIDs[def.Type];
        Assert(!!typeID, `org type ${def.Type} missing`);
        const existing = await FindId(ctx, COMMON_ENTITIES.Organization, `Email = '${Quote(def.Email)}'`);
        const org = await ctx.Provider.GetEntityObject<mjBizAppsCommonOrganizationEntity>(COMMON_ENTITIES.Organization, ctx.User);
        if (existing) {
            const key = org.PrimaryKey;
            key.KeyValuePairs = [{ FieldName: 'ID', Value: existing }];
            await org.InnerLoad(key);
        } else {
            org.NewRecord();
        }
        org.Name = def.Name;
        org.Email = def.Email;
        org.OrganizationTypeID = typeID;
        org.Status = 'Active';
        org.Website = `https://${def.Code.toLowerCase()}.${WORLD_EMAIL_DOMAIN}`;
        if (def.Parent && world.Organizations[def.Parent]) {
            org.ParentID = world.Organizations[def.Parent].ID;
        }
        await RequireSave(org, `Organization ${def.Code}`);
        world.Organizations[def.Code] = { ID: org.ID, Code: def.Code, Name: def.Name };
    }
}

async function loadPeople(ctx: IntegrationCheckContext, world: WorldState): Promise<void> {
    const defs: Array<{ Email: string; First: string; Last: string; Title: string; Org?: string }> = [
        { Email: `nora.calhoun@${WORLD_EMAIL_DOMAIN}`, First: 'Nora', Last: 'Calhoun', Title: 'Director', Org: 'RIV' },
        { Email: `james.whitaker@${WORLD_EMAIL_DOMAIN}`, First: 'James', Last: 'Whitaker', Title: 'Acquisitions Librarian', Org: 'RIV' },
        { Email: `elena.voss@${WORLD_EMAIL_DOMAIN}`, First: 'Elena', Last: 'Voss', Title: "Children's Librarian", Org: 'RIV' },
        { Email: `ada.lovelace@${WORLD_EMAIL_DOMAIN}`, First: 'Ada', Last: 'Lovelace', Title: 'Editor in Chief', Org: 'BCP' },
        { Email: `charles.babbage@${WORLD_EMAIL_DOMAIN}`, First: 'Charles', Last: 'Babbage', Title: 'Publisher', Org: 'BCP' },
        { Email: `grace.hopper@${WORLD_EMAIL_DOMAIN}`, First: 'Grace', Last: 'Hopper', Title: 'Counsel', Org: 'HH' },
        { Email: `alan.turing@${WORLD_EMAIL_DOMAIN}`, First: 'Alan', Last: 'Turing', Title: 'Faculty', Org: 'SUM' },
        { Email: `jordan.blake@${WORLD_EMAIL_DOMAIN}`, First: 'Jordan', Last: 'Blake', Title: 'Independent' },
        { Email: `marcus.webb@${WORLD_EMAIL_DOMAIN}`, First: 'Marcus', Last: 'Webb', Title: 'Coach', Org: 'ATL' },
        { Email: `priya.shah@${WORLD_EMAIL_DOMAIN}`, First: 'Priya', Last: 'Shah', Title: 'Principal', Org: 'NGS' },
    ];

    for (const def of defs) {
        const existing = await FindId(ctx, COMMON_ENTITIES.Person, `Email = '${Quote(def.Email)}'`);
        const person = await ctx.Provider.GetEntityObject<mjBizAppsCommonPersonEntity>(COMMON_ENTITIES.Person, ctx.User);
        if (existing) {
            const key = person.PrimaryKey;
            key.KeyValuePairs = [{ FieldName: 'ID', Value: existing }];
            await person.InnerLoad(key);
        } else {
            person.NewRecord();
        }
        person.FirstName = def.First;
        person.LastName = def.Last;
        person.Email = def.Email;
        person.Title = def.Title;
        person.Status = 'Active';
        await RequireSave(person, `Person ${def.Email}`);
        const row: WorldPerson = { ID: person.ID, Email: def.Email, FirstName: def.First, LastName: def.Last };
        world.People[def.Email] = row;
    }
}

async function loadAddresses(ctx: IntegrationCheckContext, world: WorldState): Promise<void> {
    const typeID = world.AddressTypeIDs['Work'] ?? world.AddressTypeIDs['Business'] ?? Object.values(world.AddressTypeIDs)[0];
    const defs: Array<{ Key: string; Line1: string; City: string; State: string; Postal: string; Org: string }> = [
        { Key: 'RIV-HQ', Line1: '100 River Walk', City: 'Riverside', State: 'CA', Postal: '92501', Org: 'RIV' },
        { Key: 'BCP-HQ', Line1: '44 Cypress Lane', City: 'Santa Clara', State: 'CA', Postal: '95050', Org: 'BCP' },
        { Key: 'HH-HQ', Line1: '12 Harbor Way', City: 'Oakland', State: 'CA', Postal: '94607', Org: 'HH' },
    ];

    const md = ctx.Provider;
    const orgEntity = md.EntityByName(COMMON_ENTITIES.Organization);
    Assert(!!orgEntity, 'Organizations entity missing');

    for (const def of defs) {
        const org = world.Organizations[def.Org];
        const existing = await FindId(ctx, COMMON_ENTITIES.Address, `Line1 = '${Quote(def.Line1)}' AND City = '${Quote(def.City)}'`);
        const address = await ctx.Provider.GetEntityObject<mjBizAppsCommonAddressEntity>(COMMON_ENTITIES.Address, ctx.User);
        if (existing) {
            const key = address.PrimaryKey;
            key.KeyValuePairs = [{ FieldName: 'ID', Value: existing }];
            await address.InnerLoad(key);
        } else {
            address.NewRecord();
        }
        address.Line1 = def.Line1;
        address.City = def.City;
        address.StateProvince = def.State;
        address.PostalCode = def.Postal;
        address.Country = 'US';
        await RequireSave(address, `Address ${def.Key}`);
        world.Addresses[def.Key] = address.ID;

        const linkFilter = `AddressID = '${address.ID}' AND RecordID = '${org.ID}'`;
        const existingLink = await FindId(ctx, COMMON_ENTITIES.AddressLink, linkFilter);
        if (!existingLink) {
            const link = await ctx.Provider.GetEntityObject<mjBizAppsCommonAddressLinkEntity>(COMMON_ENTITIES.AddressLink, ctx.User);
            link.NewRecord();
            link.AddressID = address.ID;
            link.EntityID = orgEntity!.ID;
            link.RecordID = org.ID;
            link.AddressTypeID = typeID;
            link.IsPrimary = true;
            await RequireSave(link, `AddressLink ${def.Key}`);
        }
    }
}

async function loadContacts(ctx: IntegrationCheckContext, world: WorldState): Promise<void> {
    const emailType = world.ContactTypeIDs['Email'] ?? world.ContactTypeIDs['Work Email'] ?? Object.values(world.ContactTypeIDs)[0];
    for (const person of Object.values(world.People)) {
        const existing = await FindId(
            ctx,
            COMMON_ENTITIES.ContactMethod,
            `PersonID = '${person.ID}' AND Value = '${Quote(person.Email)}'`,
        );
        if (existing) continue;
        const method = await ctx.Provider.GetEntityObject<mjBizAppsCommonContactMethodEntity>(COMMON_ENTITIES.ContactMethod, ctx.User);
        method.NewRecord();
        method.PersonID = person.ID;
        method.ContactTypeID = emailType;
        method.Value = person.Email;
        method.IsPrimary = true;
        await RequireSave(method, `ContactMethod ${person.Email}`);
    }
}

async function loadRelationships(ctx: IntegrationCheckContext, world: WorldState): Promise<void> {
    const employeeType =
        world.RelationshipTypeIDs['Employee'] ??
        world.RelationshipTypeIDs['Employment'] ??
        Object.values(world.RelationshipTypeIDs)[0];

    const jobs: Array<{ Email: string; Org: string }> = [
        { Email: `nora.calhoun@${WORLD_EMAIL_DOMAIN}`, Org: 'RIV' },
        { Email: `ada.lovelace@${WORLD_EMAIL_DOMAIN}`, Org: 'BCP' },
        { Email: `grace.hopper@${WORLD_EMAIL_DOMAIN}`, Org: 'HH' },
        { Email: `alan.turing@${WORLD_EMAIL_DOMAIN}`, Org: 'SUM' },
        { Email: `priya.shah@${WORLD_EMAIL_DOMAIN}`, Org: 'NGS' },
        { Email: `marcus.webb@${WORLD_EMAIL_DOMAIN}`, Org: 'ATL' },
    ];

    for (const job of jobs) {
        const person = world.People[job.Email];
        const org = world.Organizations[job.Org];
        const existing = await FindId(
            ctx,
            COMMON_ENTITIES.Relationship,
            `FromPersonID = '${person.ID}' AND ToOrganizationID = '${org.ID}'`,
        );
        if (existing) continue;
        const rel = await ctx.Provider.GetEntityObject<mjBizAppsCommonRelationshipEntity>(COMMON_ENTITIES.Relationship, ctx.User);
        rel.NewRecord();
        rel.RelationshipTypeID = employeeType;
        rel.FromPersonID = person.ID;
        rel.ToOrganizationID = org.ID;
        rel.Title = person.FirstName === 'Nora' ? 'Director' : 'Staff';
        rel.Status = 'Active';
        await RequireSave(rel, `Relationship ${job.Email} → ${job.Org}`);
    }
}


