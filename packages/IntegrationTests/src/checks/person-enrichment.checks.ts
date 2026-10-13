/**
 * person-enrichment — PE1–PE7: the enrichment engine end to end with the fixture provider.
 *
 * The engine runs in this process over the GraphQL provider, exactly as the harness does for every
 * other check, so every RunView and Save goes through MJAPI. Nothing here is rolled back: Setup
 * creates its own people (@fixture.test) and a Fixture provider row, Teardown removes what it made.
 */
import type { ActionParam } from '@memberjunction/actions-base';
import type { IMetadataProvider } from '@memberjunction/core';
import type { GraphQLDataProvider } from '@memberjunction/graphql-dataprovider';
import { RegisterClass } from '@memberjunction/global';
import { Assert, AssertEqual, IntegrationCheckRegistry, type IntegrationCheckContext, type NamedCheck } from '@memberjunction/testing-integration/registry';
import type {
    mjBizAppsCommonContactMethodEntity,
    mjBizAppsCommonEnrichmentProviderEntity,
    mjBizAppsCommonEnrichmentProviderRateEntity,
    mjBizAppsCommonPersonEducationEntity,
    mjBizAppsCommonPersonEntity,
    mjBizAppsCommonPersonExternalIdentityEntity,
    mjBizAppsCommonRelationshipEntity,
} from '@mj-biz-apps/common-entities';
import {
    BaseEnrichmentProvider,
    FIXTURE_PROVIDER_CODE,
    FixtureEnrichmentProvider,
    LoadCommonEnrichment,
    PersonEnrichmentEngine,
    type PersonEnrichmentRunOptions,
    type PersonEnrichmentRunResult,
} from '@mj-biz-apps/common-enrichment';
import { COMMON_ENTITIES } from '../entity-names.js';
import { FindId, FindRows, LoadById, Quote, RequireSave } from '../wire.js';

LoadCommonEnrichment();

const SECOND_CODE = 'Fixture2';

/** A second fixture vendor, so PE7 can prove two providers share one education row. */
@RegisterClass(BaseEnrichmentProvider, SECOND_CODE)
export class SecondFixtureEnrichmentProvider extends FixtureEnrichmentProvider {
    public override get Code(): string { return SECOND_CODE; }
}

const EMAIL_DOMAIN = 'fixture.test';
const PEOPLE = {
    alum: `alum@${EMAIL_DOMAIN}`,
    duplicate: `duplicate@${EMAIL_DOMAIN}`,
    manual: `manual@${EMAIL_DOMAIN}`,
    both: `both@${EMAIL_DOMAIN}`,
    /** A built-in fixture scenario: MJAPI's copy of the fixture cannot see this process's Scripted map. */
    action: `matched-action@${EMAIL_DOMAIN}`,
} as const;
const FILTER = `Email LIKE '%@${EMAIL_DOMAIN}'`;

interface State {
    PersonIDs: Record<keyof typeof PEOPLE, string>;
    ProviderIDs: string[];
    ManualEducationID: string | null;
    FirstRun: PersonEnrichmentRunResult | null;
}
const state: State = { PersonIDs: { alum: '', duplicate: '', manual: '', both: '', action: '' }, ProviderIDs: [], ManualEducationID: null, FirstRun: null };

function engineOptions(ctx: IntegrationCheckContext, code: string, overrides: Partial<PersonEnrichmentRunOptions> = {}): PersonEnrichmentRunOptions {
    return {
        ProviderCode: code,
        PersonFilter: FILTER,
        MaxPeople: 50,
        Facets: ['Education', 'Employment', 'LinkedIn'],
        Mode: 'Run',
        CompanyID: null,
        RefreshMatchedDays: 180,
        RetryNotFoundDays: 90,
        CreateOrganizations: 'CurrentEmployerOnly',
        TimeBudgetMinutes: 10,
        AllowNonLiveProvider: true,
        ContextUser: ctx.User,
        MetadataProvider: ctx.Provider as IMetadataProvider,
        ...overrides,
    };
}

async function ensureProvider(ctx: IntegrationCheckContext, code: string): Promise<string> {
    const existing = await FindRows<{ ID: string }>(ctx, COMMON_ENTITIES.EnrichmentProvider, `Code = '${Quote(code)}'`, ['ID']);
    if (existing[0]) return existing[0].ID;
    const row = await ctx.Provider.GetEntityObject<mjBizAppsCommonEnrichmentProviderEntity>(COMMON_ENTITIES.EnrichmentProvider, ctx.User);
    row.NewRecord();
    row.Code = code;
    row.Name = `${code} (integration)`;
    row.DriverClass = code;
    row.MaxBatchSize = 10;
    row.IsActive = true;
    row.CreditPrice = 0.5;
    row.CreditCurrency = 'USD';
    row.Description = 'Created by person-enrichment integration checks. Safe to delete.';
    await RequireSave(row, `provider ${code}`);
    return row.ID;
}

/** Two credits per matched person, so Preview has a rate to price with. */
async function ensureRate(ctx: IntegrationCheckContext, providerID: string): Promise<void> {
    const existing = await FindRows<{ ID: string }>(ctx, COMMON_ENTITIES.EnrichmentProviderRate, `EnrichmentProviderID = '${providerID}' AND Operation = 'Enrich'`, ['ID']);
    if (existing[0]) return;
    const row = await ctx.Provider.GetEntityObject<mjBizAppsCommonEnrichmentProviderRateEntity>(COMMON_ENTITIES.EnrichmentProviderRate, ctx.User);
    row.NewRecord();
    row.EnrichmentProviderID = providerID;
    row.Operation = 'Enrich';
    row.Unit = 'MatchedPerson';
    row.CreditsPerUnit = 2;
    await RequireSave(row, 'fixture rate');
}

async function ensurePerson(ctx: IntegrationCheckContext, email: string, first: string, last: string): Promise<string> {
    const existing = await FindRows<{ ID: string }>(ctx, COMMON_ENTITIES.Person, `Email = '${Quote(email)}'`, ['ID']);
    if (existing[0]) return existing[0].ID;
    const person = await ctx.Provider.GetEntityObject<mjBizAppsCommonPersonEntity>(COMMON_ENTITIES.Person, ctx.User);
    person.NewRecord();
    person.FirstName = first;
    person.LastName = last;
    person.Email = email;
    person.Status = 'Active';
    await RequireSave(person, `person ${email}`);
    return person.ID;
}

async function manualEducation(ctx: IntegrationCheckContext, personID: string): Promise<string> {
    const row = await ctx.Provider.GetEntityObject<mjBizAppsCommonPersonEducationEntity>(COMMON_ENTITIES.PersonEducation, ctx.User);
    row.NewRecord();
    row.PersonID = personID;
    row.InstitutionName = 'The Harvard Kennedy School';
    row.Degree = 'M.P.P.';
    row.FieldOfStudy = 'Entered by hand';
    row.EndDate = new Date(Date.UTC(2012, 5, 15));
    row.Source = 'Manual';
    await RequireSave(row, 'manual education');
    return row.ID;
}

/** alum already holds the vendor ID from a check 400 days ago: still eligible, re-matches to their own ID, and anyone else returning it is Ambiguous regardless of batch order. */
async function seedAlumIdentity(ctx: IntegrationCheckContext, personID: string): Promise<void> {
    const row = await ctx.Provider.GetEntityObject<mjBizAppsCommonPersonExternalIdentityEntity>(COMMON_ENTITIES.PersonExternalIdentity, ctx.User);
    row.NewRecord();
    row.PersonID = personID;
    row.SourceSystem = FIXTURE_PROVIDER_CODE;
    row.ExternalID = 'fixture-alum';
    row.MatchStatus = 'Matched';
    row.MatchedBy = 'Email';
    row.MatchConfidence = 0.9;
    row.LastCheckedAt = new Date(Date.now() - 400 * 24 * 60 * 60 * 1000);
    row.LastMatchedAt = row.LastCheckedAt;
    await RequireSave(row, 'seed alum identity');
}

async function deleteWhere(ctx: IntegrationCheckContext, entity: string, filter: string): Promise<void> {
    const rows = await FindRows<{ ID: string }>(ctx, entity, filter, ['ID']);
    for (const row of rows) {
        const obj = await ctx.Provider.GetEntityObject<mjBizAppsCommonPersonEntity>(entity, ctx.User);
        await LoadById(obj, row.ID);
        await obj.Delete();
    }
}

/** Activity Links name the linked record by EntityID and RecordID; the record ID may be stored bare or as a key segment. */
function LinksTo(recordID: string): string {
    return `RecordID IN ('${Quote(recordID)}','ID|${Quote(recordID)}')`;
}

function idList(): string {
    return Object.values(state.PersonIDs).filter(Boolean).map((id) => `'${id}'`).join(',') || `'00000000-0000-0000-0000-000000000000'`;
}

const checks: NamedCheck[] = [
    {
        Id: 'person-enrichment.PE0',
        Name: 'PE0 — Preview counts the eligible people, prices an upper bound from the rate rows, calls no vendor and writes nothing',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const before = await FindRows<{ ID: string }>(ctx, COMMON_ENTITIES.PersonEducation, `PersonID IN (${idList()})`, ['ID']);
            const preview = await new PersonEnrichmentEngine().Run(engineOptions(ctx, FIXTURE_PROVIDER_CODE, { Mode: 'Preview', MaxPeople: 3 }));
            AssertEqual(preview.Eligible, 4, 'four fixture people are eligible (alum was last checked 400 days ago)');
            AssertEqual(preview.EstimatedCredits, 6, 'min(4, MaxPeople 3) x 2 credits');
            AssertEqual(preview.EstimatedCost, 3, '6 credits x 0.5');
            AssertEqual(preview.CostCurrency, 'USD', 'currency from the provider row');
            AssertEqual(preview.Processed, 0, 'nothing processed');
            AssertEqual(preview.StoppedReason, 'Completed', 'preview completes');
            const after = await FindRows<{ ID: string }>(ctx, COMMON_ENTITIES.PersonEducation, `PersonID IN (${idList()})`, ['ID']);
            AssertEqual(after.length, before.length, 'preview wrote nothing');
            const identities = await FindRows<{ ID: string; PersonID: string }>(ctx, COMMON_ENTITIES.PersonExternalIdentity, `PersonID IN (${idList()}) AND SourceSystem = '${FIXTURE_PROVIDER_CODE}'`, ['ID', 'PersonID']);
            AssertEqual(identities.length, 1, 'only the seeded identity row exists');
        },
    },
    {
        Id: 'person-enrichment.PE1',
        Name: 'PE1 — first run writes education, employment, LinkedIn and the identity',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const startedAt = new Date();
            const result = await new PersonEnrichmentEngine().Run(engineOptions(ctx, FIXTURE_PROVIDER_CODE));
            state.FirstRun = result;
            Assert(result.Matched >= 3, `expected alum, manual and both to match; got ${JSON.stringify(result)}`);
            AssertEqual(result.Ambiguous, 1, 'duplicate is ambiguous');
            const alum = state.PersonIDs.alum;
            const education = await FindRows<{ InstitutionName: string; Source: string; SourceSystem: string }>(ctx, COMMON_ENTITIES.PersonEducation, `PersonID = '${alum}'`, ['InstitutionName', 'Source', 'SourceSystem']);
            AssertEqual(education.length, 1, 'one education row for alum');
            AssertEqual(education[0].InstitutionName, 'Harvard Kennedy School', 'institution as returned');
            AssertEqual(education[0].Source, 'Enrichment', 'education source');
            const jobs = await FindRows<{ ID: string; ToOrganization: string; Status: string; Source: string }>(ctx, COMMON_ENTITIES.Relationship, `FromPersonID = '${alum}' AND Source = 'Enrichment'`, ['ID', 'ToOrganization', 'Status', 'Source']);
            AssertEqual(jobs.length, 1, 'one employment row for alum');
            AssertEqual(jobs[0].ToOrganization, 'Fixture Labs', 'employer created and linked');
            AssertEqual(jobs[0].Status, 'Active', 'current job is Active');
            const linkedIn = await FindRows<{ Value: string }>(ctx, COMMON_ENTITIES.ContactMethod, `PersonID = '${alum}' AND ContactType = 'LinkedIn'`, ['Value']);
            AssertEqual(linkedIn.length, 1, 'LinkedIn contact method added once');
            const identity = await FindRows<{ MatchStatus: string; ExternalID: string }>(ctx, COMMON_ENTITIES.PersonExternalIdentity, `PersonID = '${alum}' AND SourceSystem = '${FIXTURE_PROVIDER_CODE}'`, ['MatchStatus', 'ExternalID']);
            AssertEqual(identity[0]?.MatchStatus, 'Matched', 'identity Matched');
            AssertEqual(identity[0]?.ExternalID, 'fixture-alum', 'vendor ID stored');
            const firstTimeJobs = await FindRows<{ ID: string }>(ctx, COMMON_ENTITIES.Relationship, `FromPersonID = '${state.PersonIDs.both}' AND Source = 'Enrichment'`, ['ID']);
            AssertEqual(firstTimeJobs.length, 1, 'first-time person got an employment row');
            // Not asserted here: that a first-time backfill logs no Activity. The engine saves those rows with
            // SkipEntityActions, which the GraphQL provider does not forward on Save (it forwards it only on
            // Delete; MJ/packages/GraphQLDataProvider/src/graphQLDataProvider.ts), so over this wire the
            // Relationship entity action fires anyway. In MJAPI the engine saves in-process and the option holds;
            // the batch-processor unit test pins that SkipEntityActions is set on first-time saves.
            void startedAt;
        },
    },
    {
        Id: 'person-enrichment.PE2',
        Name: 'PE2 — a second run immediately afterwards selects nobody',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const result = await new PersonEnrichmentEngine().Run(engineOptions(ctx, FIXTURE_PROVIDER_CODE));
            AssertEqual(result.Processed, 0, 'refresh window excludes everyone just checked');
            const preview = await new PersonEnrichmentEngine().Run(engineOptions(ctx, FIXTURE_PROVIDER_CODE, { Mode: 'Preview' }));
            AssertEqual(preview.Eligible, 0, 'preview agrees');
        },
    },
    {
        Id: 'person-enrichment.PE3',
        Name: 'PE3 — a Manual education row with the same key is untouched and not duplicated',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const rows = await FindRows<{ ID: string; Source: string; FieldOfStudy: string | null; InstitutionName: string; Degree: string | null; EndDate: unknown; SourceSystem: string | null }>(ctx, COMMON_ENTITIES.PersonEducation, `PersonID = '${state.PersonIDs.manual}'`, ['ID', 'Source', 'FieldOfStudy', 'InstitutionName', 'Degree', 'EndDate', 'SourceSystem']);
            AssertEqual(rows.length, 1, `still exactly one education row; rows: ${JSON.stringify(rows)}`);
            AssertEqual(rows[0].ID, state.ManualEducationID, 'it is the manual row');
            AssertEqual(rows[0].Source, 'Manual', 'source untouched');
            AssertEqual(rows[0].FieldOfStudy, 'Entered by hand', 'field untouched');
        },
    },
    {
        Id: 'person-enrichment.PE4',
        Name: 'PE4 — a vendor ID already held by another person yields Ambiguous and nothing else',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const duplicate = state.PersonIDs.duplicate;
            const identity = await FindRows<{ MatchStatus: string; ExternalID: string | null }>(ctx, COMMON_ENTITIES.PersonExternalIdentity, `PersonID = '${duplicate}' AND SourceSystem = '${FIXTURE_PROVIDER_CODE}'`, ['MatchStatus', 'ExternalID']);
            AssertEqual(identity[0]?.MatchStatus, 'Ambiguous', 'ambiguous identity');
            AssertEqual(identity[0]?.ExternalID, null, 'no vendor ID stored');
            const education = await FindRows<{ ID: string }>(ctx, COMMON_ENTITIES.PersonEducation, `PersonID = '${duplicate}'`, ['ID']);
            const jobs = await FindRows<{ ID: string }>(ctx, COMMON_ENTITIES.Relationship, `FromPersonID = '${duplicate}'`, ['ID']);
            AssertEqual(education.length + jobs.length, 0, 'nothing else written for the ambiguous person');
        },
    },
    {
        Id: 'person-enrichment.PE5',
        Name: 'PE5 — a later run that finds a new employer ends the old row, adds the new one, and logs an Activity',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const alum = state.PersonIDs.alum;
            const identity = await ctx.Provider.GetEntityObject<mjBizAppsCommonPersonExternalIdentityEntity>(COMMON_ENTITIES.PersonExternalIdentity, ctx.User);
            const identityID = (await FindRows<{ ID: string }>(ctx, COMMON_ENTITIES.PersonExternalIdentity, `PersonID = '${alum}' AND SourceSystem = '${FIXTURE_PROVIDER_CODE}'`, ['ID']))[0].ID;
            await LoadById(identity, identityID);
            identity.LastCheckedAt = new Date(Date.now() - 400 * 24 * 60 * 60 * 1000);
            await RequireSave(identity, 'age the identity row');
            FixtureEnrichmentProvider.Scripted.set(PEOPLE.alum, (request) => changedEmployer(request.PersonID));
            const startedAt = new Date();
            try {
                const result = await new PersonEnrichmentEngine().Run(engineOptions(ctx, FIXTURE_PROVIDER_CODE, { PersonFilter: `${FILTER} AND ID = '${alum}'` }));
                AssertEqual(result.Matched, 1, 'alum re-matched');
                AssertEqual(result.RelationshipsEnded, 1, 'old job ended');
                AssertEqual(result.RelationshipsCreated, 1, 'new job created');
            } finally {
                FixtureEnrichmentProvider.Scripted.delete(PEOPLE.alum);
            }
            const jobs = await FindRows<{ ID: string; ToOrganization: string; Status: string }>(ctx, COMMON_ENTITIES.Relationship, `FromPersonID = '${alum}' AND Source = 'Enrichment'`, ['ID', 'ToOrganization', 'Status']);
            AssertEqual(jobs.find((job) => job.ToOrganization === 'Fixture Labs')?.Status, 'Ended', 'Fixture Labs ended');
            const industries = jobs.find((job) => job.ToOrganization === 'Fixture Industries');
            AssertEqual(industries?.Status, 'Active', 'Fixture Industries active');
            const activities = await FindRows<{ ID: string }>(ctx, COMMON_ENTITIES.ActivityLink, `${LinksTo(industries?.ID ?? '')} AND __mj_CreatedAt >= '${startedAt.toISOString()}'`, ['ID']);
            Assert(activities.length >= 1, 'a job change on a later run logs a timeline Activity');
        },
    },
    {
        Id: 'person-enrichment.PE7',
        Name: 'PE7 — a second provider corroborates the same school: one education row, two identities, one employment row',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const both = state.PersonIDs.both;
            const result = await new PersonEnrichmentEngine().Run(engineOptions(ctx, SECOND_CODE, { PersonFilter: `${FILTER} AND ID = '${both}'` }));
            AssertEqual(result.Matched, 1, 'second provider matched');
            AssertEqual(result.EducationCreated, 0, 'no second education row');
            AssertEqual(result.RelationshipsCreated, 0, 'no second employment row');
            const education = await FindRows<{ ID: string }>(ctx, COMMON_ENTITIES.PersonEducation, `PersonID = '${both}'`, ['ID']);
            AssertEqual(education.length, 1, 'one education row');
            const identities = await FindRows<{ SourceSystem: string }>(ctx, COMMON_ENTITIES.PersonExternalIdentity, `PersonID = '${both}'`, ['SourceSystem']);
            AssertEqual(identities.length, 2, 'two identity rows');
            const jobs = await FindRows<{ SourceSystem: string }>(ctx, COMMON_ENTITIES.Relationship, `FromPersonID = '${both}' AND Source = 'Enrichment'`, ['SourceSystem']);
            AssertEqual(jobs.length, 1, 'one employment row');
            AssertEqual(jobs[0].SourceSystem, FIXTURE_PROVIDER_CODE, 'the first provider still owns it');
        },
    },
    {
        Id: 'person-enrichment.PE6',
        Name: 'PE6 — deleting a Person removes their education and identity rows',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const alum = state.PersonIDs.alum;
            await deleteWhere(ctx, COMMON_ENTITIES.Relationship, `FromPersonID = '${alum}'`);
            await deleteWhere(ctx, COMMON_ENTITIES.ContactMethod, `PersonID = '${alum}'`);
            const person = await ctx.Provider.GetEntityObject<mjBizAppsCommonPersonEntity>(COMMON_ENTITIES.Person, ctx.User);
            await LoadById(person, alum);
            Assert(await person.Delete(), `delete alum: ${person.LatestResult?.CompleteMessage ?? ''}`);
            state.PersonIDs.alum = '';
            const education = await FindRows<{ ID: string }>(ctx, COMMON_ENTITIES.PersonEducation, `PersonID = '${alum}'`, ['ID']);
            const identities = await FindRows<{ ID: string }>(ctx, COMMON_ENTITIES.PersonExternalIdentity, `PersonID = '${alum}'`, ['ID']);
            AssertEqual(education.length + identities.length, 0, 'cascade removed education and identity rows');
        },
    },
    {
        Id: 'person-enrichment.PE8',
        Name: 'PE8 — Common.EnrichPeople runs through MJAPI: Preview prices, Run enriches, and a first-time backfill logs no Activity',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const actionID = await FindId(ctx, 'MJ: Actions', `Name = 'Common.EnrichPeople'`);
            Assert(!!actionID, 'Common.EnrichPeople is in MJ: Actions (push metadata/actions first)');
            const person = await ensurePerson(ctx, PEOPLE.action, 'Action', 'Fixture');
            state.PersonIDs.action = person;
            const filter = `${FILTER} AND ID = '${person}'`;
            const preview = await runAction(ctx, actionID as string, { ProviderCode: FIXTURE_PROVIDER_CODE, PersonFilter: filter, Mode: 'Preview', AllowNonLiveProvider: 'true' });
            Assert(preview.Success, `preview succeeded: ${preview.Message}`);
            AssertEqual(preview.ResultCode, 'SUCCESS', 'preview result code');
            AssertEqual(preview.Outputs.Eligible, 1, `preview output Eligible; raw: ${JSON.stringify(preview.Raw)}`);
            AssertEqual(preview.Outputs.EstimatedCredits, 2, 'preview output EstimatedCredits');
            const refused = await runAction(ctx, actionID as string, { ProviderCode: FIXTURE_PROVIDER_CODE, PersonFilter: filter, Mode: 'Run' });
            AssertEqual(refused.ResultCode, 'VALIDATION_ERROR', 'a non-live provider is refused unless AllowNonLiveProvider is set');
            const startedAt = new Date();
            const run = await runAction(ctx, actionID as string, { ProviderCode: FIXTURE_PROVIDER_CODE, PersonFilter: filter, Mode: 'Run', AllowNonLiveProvider: 'true' });
            Assert(run.Success, `run succeeded: ${run.Message}`);
            AssertEqual(run.ResultCode, 'SUCCESS', 'run result code');
            AssertEqual(run.Outputs.Matched, 1, 'run output Matched');
            AssertEqual(run.Outputs.RelationshipsCreated, 1, 'run output RelationshipsCreated');
            AssertEqual(run.Outputs.StoppedReason, 'Completed', 'run output StoppedReason');
            const jobs = await FindRows<{ ID: string; Source: string }>(ctx, COMMON_ENTITIES.Relationship, `FromPersonID = '${person}' AND Source = 'Enrichment'`, ['ID', 'Source']);
            AssertEqual(jobs.length, 1, 'the action wrote the employment row');
            const activities = await FindRows<{ ID: string }>(ctx, COMMON_ENTITIES.ActivityLink, `${LinksTo(jobs[0].ID)} AND __mj_CreatedAt >= '${startedAt.toISOString()}'`, ['ID']);
            AssertEqual(activities.length, 0, 'in-process saves honour SkipEntityActions: a first-time backfill logs no Activity');
        },
    },
];

interface ActionRun {
    Success: boolean;
    Message: string | null;
    ResultCode: string | null;
    /** Output params by name, as the server serialized them. */
    Outputs: Record<string, unknown>;
    /** The mutation payload as received, for diagnostics. */
    Raw: unknown;
}

const RUN_ACTION = `mutation RunAction($input: RunActionInput!) {
    RunAction(input: $input) { Success Message ResultCode ResultData }
}`;

/** The RunAction mutation itself: the client helper in graphql-dataprovider drops ResultCode and the output params. */
async function runAction(ctx: IntegrationCheckContext, actionID: string, values: Record<string, string>): Promise<ActionRun> {
    const params: ActionParam[] = Object.entries(values).map(([Name, Value]) => ({ Name, Value, Type: 'Input' }));
    const provider = ctx.Provider as GraphQLDataProvider;
    const raw = (await provider.ExecuteGQL(RUN_ACTION, { input: { ActionID: actionID, Params: params, SkipActionLog: false } })) as { RunAction: { Success: boolean; Message?: string; ResultCode?: string; ResultData?: string } };
    const outputs: Record<string, unknown> = {};
    const parsed: unknown = raw.RunAction.ResultData ? JSON.parse(raw.RunAction.ResultData) : [];
    // The server serializes the output params; accept either a list of {Name, Value} or a name-keyed object.
    // ActionResolver passes the output params through CopyScalarsAndArrays, which turns the array into a
    // numerically keyed object of {Name, Value, Type}; a plain array is accepted too.
    const items = Array.isArray(parsed) ? (parsed as unknown[]) : Object.values((parsed ?? {}) as Record<string, unknown>);
    for (const item of items) {
        if (item && typeof item === 'object' && 'Name' in item) outputs[String((item as { Name: unknown }).Name)] = (item as { Value?: unknown }).Value;
    }
    return { Success: raw.RunAction.Success, Message: raw.RunAction.Message ?? null, ResultCode: raw.RunAction.ResultCode ?? null, Outputs: outputs, Raw: raw.RunAction };
}

function changedEmployer(personID: string) {
    return {
        PersonID: personID,
        Status: 'Matched' as const,
        ExternalID: 'fixture-alum',
        MatchedBy: 'ExternalID' as const,
        MatchConfidence: 0.95,
        LinkedInURL: 'https://www.linkedin.com/in/fixture-alum/',
        Education: [{ InstitutionName: 'Harvard Kennedy School', InstitutionExternalID: 'fixture-school-hks', Degree: 'MPP', FieldOfStudy: 'Public Policy', StartDate: '2010-09-01', EndDate: '2012-05-31' }],
        Employment: [
            { OrganizationName: 'Fixture Labs', OrganizationDomain: 'fixturelabs.test', Title: 'Policy Analyst', StartDate: '2012-07-01', EndDate: '2020-01-31', IsCurrent: false },
            { OrganizationName: 'Fixture Industries', OrganizationDomain: 'fixtureindustries.test', Title: 'Director of Policy', StartDate: '2020-02-01', EndDate: null, IsCurrent: true },
        ],
        ErrorMessage: null,
    };
}

for (const check of checks) IntegrationCheckRegistry.Instance.Register(check);

IntegrationCheckRegistry.Instance.RegisterLifecycle('person-enrichment', {
    Setup: async (ctx) => {
        state.ProviderIDs = [await ensureProvider(ctx, FIXTURE_PROVIDER_CODE), await ensureProvider(ctx, SECOND_CODE)];
        state.PersonIDs.alum = await ensurePerson(ctx, PEOPLE.alum, 'Alum', 'Fixture');
        state.PersonIDs.duplicate = await ensurePerson(ctx, PEOPLE.duplicate, 'Duplicate', 'Fixture');
        state.PersonIDs.manual = await ensurePerson(ctx, PEOPLE.manual, 'Manual', 'Fixture');
        state.PersonIDs.both = await ensurePerson(ctx, PEOPLE.both, 'Both', 'Fixture');
        await ensureRate(ctx, state.ProviderIDs[0]);
        state.ManualEducationID = await manualEducation(ctx, state.PersonIDs.manual);
        await seedAlumIdentity(ctx, state.PersonIDs.alum);
        FixtureEnrichmentProvider.Scripted.set(PEOPLE.manual, (request) => ({ ...changedEmployer(request.PersonID), ExternalID: 'fixture-manual', Employment: [] }));
        FixtureEnrichmentProvider.Scripted.set(PEOPLE.both, (request) => ({ ...changedEmployer(request.PersonID), ExternalID: 'fixture-both', Employment: changedEmployer(request.PersonID).Employment.slice(1) }));
    },
    Teardown: async (ctx) => {
        FixtureEnrichmentProvider.Scripted.clear();
        const people = idList();
        await deleteWhere(ctx, COMMON_ENTITIES.Relationship, `FromPersonID IN (${people})`);
        await deleteWhere(ctx, COMMON_ENTITIES.ContactMethod, `PersonID IN (${people})`);
        await deleteWhere(ctx, COMMON_ENTITIES.PersonEducation, `PersonID IN (${people})`);
        await deleteWhere(ctx, COMMON_ENTITIES.PersonExternalIdentity, `PersonID IN (${people})`);
        await deleteWhere(ctx, COMMON_ENTITIES.Person, `Email LIKE '%@${EMAIL_DOMAIN}'`);
        await deleteWhere(ctx, COMMON_ENTITIES.Organization, `Name IN ('Fixture Labs','Fixture Industries')`);
        await deleteWhere(ctx, COMMON_ENTITIES.EnrichmentProviderRate, `EnrichmentProvider IN ('${FIXTURE_PROVIDER_CODE} (integration)','${SECOND_CODE} (integration)')`);
        await deleteWhere(ctx, COMMON_ENTITIES.EnrichmentProvider, `Code IN ('${FIXTURE_PROVIDER_CODE}','${SECOND_CODE}')`);
    },
});
