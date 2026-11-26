import { beforeEach, describe, expect, it, vi } from 'vitest';
import type {
    BaseEntity,
    BaseEntityEvent,
    BaseEnginePropertyConfig,
    EntityInfo,
    IMetadataProvider,
    RunViewParams,
    UserInfo,
} from '@memberjunction/core';
import { NormalizeUUID } from '@memberjunction/global';

const H = vi.hoisted(() => ({
    runViewsCalls: [] as Array<{ requests: RunViewParams[]; user?: UserInfo }>,
    runViewsHandler: vi.fn(),
    ambientProvider: null as IMetadataProvider | null,
}));

vi.mock('@memberjunction/core', async (importOriginal) => {
    const actual = await importOriginal<typeof import('@memberjunction/core')>();

    class MockMetadata {
        public static get Provider(): IMetadataProvider {
            return H.ambientProvider as IMetadataProvider;
        }
        public static set Provider(value: IMetadataProvider) {
            H.ambientProvider = value;
        }
    }

    class MockRunView {
        public static FromMetadataProvider(_provider: IMetadataProvider): MockRunView {
            return new MockRunView();
        }
        public async RunViews(requests: RunViewParams[], user?: UserInfo) {
            H.runViewsCalls.push({ requests, user });
            return H.runViewsHandler(requests, user);
        }
    }

    return {
        ...actual,
        Metadata: MockMetadata,
        RunView: MockRunView,
    };
});

import {
    COMMON_ENGINE_ENTITIES,
    CommonEngine,
    type CommonOrganizationSummary,
    type CommonPersonSummary,
} from '../common-engine.js';

const USER_A = { ID: '11111111-1111-1111-1111-111111111111', Name: 'Alice' } as UserInfo;
const USER_B = { ID: '22222222-2222-2222-2222-222222222222', Name: 'Bob' } as UserInfo;

const PERSON_1_ID = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1';
const PERSON_2_ID = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2';
const PERSON_3_ID = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3';
const ORG_1_ID = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1';
const ORG_2_ID = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb2';

const ACT_TYPE_ID = 'cccccccc-cccc-cccc-cccc-ccccccccccc1';
const ADDR_TYPE_ID = 'cccccccc-cccc-cccc-cccc-ccccccccccc2';
const CONSENT_ID = 'cccccccc-cccc-cccc-cccc-ccccccccccc3';
const CONTACT_TYPE_ID = 'cccccccc-cccc-cccc-cccc-ccccccccccc4';
const JOB_FUNC_ID = 'cccccccc-cccc-cccc-cccc-ccccccccccc5';
const ORG_TYPE_ID = 'cccccccc-cccc-cccc-cccc-ccccccccccc6';
const REL_TYPE_ID = 'cccccccc-cccc-cccc-cccc-ccccccccccc7';
const SENIORITY_ID = 'cccccccc-cccc-cccc-cccc-ccccccccccc8';
const PROVIDER_TYPE_ID = 'cccccccc-cccc-cccc-cccc-ccccccccccc9';

function makeProvider(options: {
    user?: UserInfo;
    deniedEntities?: string[];
    missingEntities?: string[];
}): IMetadataProvider {
    const denied = new Set((options.deniedEntities ?? []).map((n) => n.toLowerCase()));
    const missing = new Set((options.missingEntities ?? []).map((n) => n.toLowerCase()));
    return {
        CurrentUser: options.user ?? USER_A,
        EntityByName: (name: string) => {
            if (missing.has(name.toLowerCase())) {
                return undefined;
            }
            return {
                Name: name,
                GetUserPermisions: (_u: UserInfo) => ({
                    CanRead: !denied.has(name.toLowerCase()),
                }),
            } as unknown as EntityInfo;
        },
    } as unknown as IMetadataProvider;
}

interface LoadSpyRecord {
    configs: Array<Partial<BaseEnginePropertyConfig>>;
    provider: IMetadataProvider;
    forceRefresh: boolean;
    contextUser?: UserInfo;
}

function createTestEngine(dataset: Record<string, unknown[]> = {}): {
    engine: CommonEngine;
    loads: LoadSpyRecord[];
    invokeBaseEntityEvent: (event: BaseEntityEvent) => Promise<boolean>;
} {
    const engine = Object.create(CommonEngine.prototype) as CommonEngine;
    const store = new Map<string, unknown[]>();
    const loads: LoadSpyRecord[] = [];

    // Initialize internal fields cleanly on the isolated instance
    const internal = engine as unknown as Record<string, unknown>;
    internal['_activityTypes'] = [];
    internal['_addressTypes'] = [];
    internal['_consentPurposes'] = [];
    internal['_contactTypes'] = [];
    internal['_jobFunctions'] = [];
    internal['_organizationTypes'] = [];
    internal['_relationshipTypes'] = [];
    internal['_seniorityLevels'] = [];
    internal['_activitySyncProviderTypes'] = [];
    internal['_activityTypesByID'] = new Map();
    internal['_activityTypesByCode'] = new Map();
    internal['_activityTypesByName'] = new Map();
    internal['_addressTypesByID'] = new Map();
    internal['_addressTypesByName'] = new Map();
    internal['_consentPurposesByID'] = new Map();
    internal['_consentPurposesByName'] = new Map();
    internal['_contactTypesByID'] = new Map();
    internal['_contactTypesByName'] = new Map();
    internal['_jobFunctionsByID'] = new Map();
    internal['_jobFunctionsByName'] = new Map();
    internal['_organizationTypesByID'] = new Map();
    internal['_organizationTypesByName'] = new Map();
    internal['_relationshipTypesByID'] = new Map();
    internal['_relationshipTypesByName'] = new Map();
    internal['_seniorityLevelsByID'] = new Map();
    internal['_seniorityLevelsByName'] = new Map();
    internal['_activitySyncProviderTypesByID'] = new Map();
    internal['_activitySyncProviderTypesByCode'] = new Map();
    internal['_peopleByID'] = new Map();
    internal['_organizationsByID'] = new Map();
    internal['_explicitProvider'] = null;
    internal['_configuredProvider'] = null;
    internal['_configuredUserID'] = null;
    internal['_partyCacheProvider'] = null;
    internal['_partyCacheUserID'] = null;

    internal['SetupGlobalEventListener'] = async () => true;
    internal['GetConfigData'] = <T>(prop: string): T[] => (store.get(prop) ?? []) as T[];
    internal['Load'] = async (
        configs: Array<Partial<BaseEnginePropertyConfig>>,
        provider: IMetadataProvider,
        forceRefresh: boolean,
        contextUser?: UserInfo,
    ) => {
        loads.push({ configs, provider, forceRefresh, contextUser });
        store.clear();
        for (const cfg of configs) {
            if (cfg.PropertyName) {
                const rows = dataset[cfg.EntityName ?? ''] ?? [];
                store.set(cfg.PropertyName, rows);
                internal[cfg.PropertyName] = rows;
            }
        }
        await (engine as unknown as { AdditionalLoading(u?: UserInfo): Promise<void> }).AdditionalLoading(contextUser);
    };

    const invokeBaseEntityEvent = async (event: BaseEntityEvent): Promise<boolean> => {
        (engine as unknown as { handlePartyInvalidationEvent(e: BaseEntityEvent): void }).handlePartyInvalidationEvent(event);
        return true;
    };

    return { engine, loads, invokeBaseEntityEvent };
}

describe('CommonEngine', () => {
    beforeEach(() => {
        H.runViewsCalls.length = 0;
        H.runViewsHandler.mockReset();
        H.ambientProvider = makeProvider({ user: USER_A });
    });

    it('caches all 9 bounded taxonomy entities with AutoRefresh: true, CacheLocal: false, and O(1) lookup maps rebuilt on reload', async () => {
        const dataset: Record<string, unknown[]> = {
            [COMMON_ENGINE_ENTITIES.ActivityTypes]: [
                { ID: ACT_TYPE_ID.toUpperCase(), Code: 'Email', Name: 'Email', IsActive: true },
                { ID: 'cccccccc-cccc-cccc-cccc-cccccccccc11', Code: 'Legacy', Name: 'Legacy', IsActive: false },
            ],
            [COMMON_ENGINE_ENTITIES.AddressTypes]: [
                { ID: ADDR_TYPE_ID, Name: 'Work', IsActive: true, DefaultRank: 1 },
            ],
            [COMMON_ENGINE_ENTITIES.ConsentPurposes]: [
                { ID: CONSENT_ID, Name: 'Marketing', IsActive: true, Sequence: 1 },
            ],
            [COMMON_ENGINE_ENTITIES.ContactTypes]: [
                { ID: CONTACT_TYPE_ID, Name: 'Work Email', IsActive: true, DisplayRank: 1 },
            ],
            [COMMON_ENGINE_ENTITIES.JobFunctions]: [
                { ID: JOB_FUNC_ID, Name: 'Engineering', Status: 'Active', Sequence: 1 },
                { ID: 'cccccccc-cccc-cccc-cccc-cccccccccc12', Name: 'Archived', Status: 'Disabled', Sequence: 2 },
            ],
            [COMMON_ENGINE_ENTITIES.OrganizationTypes]: [
                { ID: ORG_TYPE_ID, Name: 'Customer', IsActive: true, DisplayRank: 1 },
            ],
            [COMMON_ENGINE_ENTITIES.RelationshipTypes]: [
                { ID: REL_TYPE_ID, Name: 'Employee', IsActive: true, Category: 'PersonToOrganization' },
            ],
            [COMMON_ENGINE_ENTITIES.SeniorityLevels]: [
                { ID: SENIORITY_ID, Name: 'Executive', Status: 'Active', Sequence: 1 },
            ],
            [COMMON_ENGINE_ENTITIES.ActivitySyncProviderTypes]: [
                { ID: PROVIDER_TYPE_ID, Code: 'Microsoft365', Name: 'Microsoft 365', IsActive: true },
            ],
        };

        const provider = makeProvider({ user: USER_A });
        const { engine, loads } = createTestEngine(dataset);

        await engine.Config(false, USER_A, provider);

        expect(loads).toHaveLength(1);
        expect(loads[0].configs).toHaveLength(9);
        for (const cfg of loads[0].configs) {
            expect(cfg.AutoRefresh).toBe(true);
            expect(cfg.CacheLocal).toBe(false);
        }

        // Active-only filters and O(1) lookup maps (including case-insensitive UUID & code/name)
        expect(engine.ActivityTypes).toHaveLength(2);
        expect(engine.ActiveActivityTypes).toHaveLength(1);
        expect(engine.GetActivityTypeByID(ACT_TYPE_ID.toLowerCase())?.Code).toBe('Email');
        expect(engine.GetActivityTypeByCode('email')?.ID).toBe(ACT_TYPE_ID.toUpperCase());
        expect(engine.GetActivityTypeByName('EMAIL')?.Code).toBe('Email');
        expect(engine.GetAddressTypeByName('work')?.ID).toBe(ADDR_TYPE_ID);
        expect(engine.GetConsentPurposeByID(CONSENT_ID)?.Name).toBe('Marketing');
        expect(engine.GetContactTypeByName('work email')?.ID).toBe(CONTACT_TYPE_ID);
        expect(engine.ActiveJobFunctions).toHaveLength(1);
        expect(engine.GetJobFunctionByID(JOB_FUNC_ID)?.Name).toBe('Engineering');
        expect(engine.GetOrganizationTypeByName('customer')?.ID).toBe(ORG_TYPE_ID);
        expect(engine.GetRelationshipTypeByName('employee')?.ID).toBe(REL_TYPE_ID);
        expect(engine.GetSeniorityLevelByName('executive')?.ID).toBe(SENIORITY_ID);
        expect(engine.GetActivitySyncProviderTypeByCode('microsoft365')?.ID).toBe(PROVIDER_TYPE_ID);

        // Reload rebuilds lookup maps cleanly when underlying rows change
        dataset[COMMON_ENGINE_ENTITIES.AddressTypes] = [];
        await engine.Config(true, USER_A, provider);
        expect(engine.GetAddressTypeByName('work')).toBeUndefined();
    });

    it('gates taxonomy configs and party lookups on EntityInfo.GetUserPermisions(user)?.CanRead', async () => {
        const provider = makeProvider({
            user: USER_A,
            deniedEntities: [
                COMMON_ENGINE_ENTITIES.ActivitySyncProviderTypes,
                COMMON_ENGINE_ENTITIES.People,
            ],
            missingEntities: [COMMON_ENGINE_ENTITIES.ConsentPurposes],
        });
        const { engine, loads } = createTestEngine();

        await engine.Config(false, USER_A, provider);

        const loadedEntities = loads[0].configs.map((c) => c.EntityName);
        expect(loadedEntities).not.toContain(COMMON_ENGINE_ENTITIES.ActivitySyncProviderTypes);
        expect(loadedEntities).not.toContain(COMMON_ENGINE_ENTITIES.ConsentPurposes);
        expect(loadedEntities).toHaveLength(7);

        // Denied People entity returns empty Map without calling RunViews
        const people = await engine.GetPeopleByIDs([PERSON_1_ID], { provider, contextUser: USER_A });
        expect(people.size).toBe(0);
        expect(H.runViewsCalls).toHaveLength(0);
    });

    it('follows active ProviderToUse and auto-evicts caches + forces refresh on provider or userId (impersonation) switch', async () => {
        const providerA = makeProvider({ user: USER_A });
        const providerB = makeProvider({ user: USER_B });
        H.ambientProvider = providerA;

        const { engine, loads } = createTestEngine();
        // Without explicit provider, follows Metadata.Provider dynamically
        await engine.Config(false, USER_A);
        expect(engine.ProviderToUse).toBe(providerA);

        H.ambientProvider = providerB;
        expect(engine.ProviderToUse).toBe(providerB);

        // Seed bounded cache for USER_A on providerA
        H.runViewsHandler.mockResolvedValue([
            {
                Success: true,
                Results: [{ ID: PERSON_1_ID, DisplayName: 'Alice Person' } as CommonPersonSummary],
            },
        ]);
        await engine.Config(false, USER_A, providerA);
        expect(engine.ProviderToUse).toBe(providerA);

        const p1 = await engine.GetPersonByID(PERSON_1_ID, { provider: providerA, contextUser: USER_A });
        expect(p1?.DisplayName).toBe('Alice Person');
        expect(engine.GetCachedPersonByID(PERSON_1_ID)).not.toBeNull();

        // Impersonation switch: USER_B on same provider auto-evicts party cache and forces Config reload
        await engine.Config(false, USER_B, providerA);
        expect(engine.GetCachedPersonByID(PERSON_1_ID)).toBeNull();
        expect(loads[loads.length - 1].forceRefresh).toBe(true);

        // Provider switch: providerB auto-evicts party cache and switches ProviderToUse
        await engine.GetPersonByID(PERSON_1_ID, { provider: providerA, contextUser: USER_B });
        expect(engine.GetCachedPersonByID(PERSON_1_ID)).not.toBeNull();

        await engine.Config(false, USER_B, providerB);
        expect(engine.ProviderToUse).toBe(providerB);
        expect(engine.GetCachedPersonByID(PERSON_1_ID)).toBeNull();
        expect(loads[loads.length - 1].forceRefresh).toBe(true);
    });

    it('performs incremental ID batching for People & Organizations and evicts on persona switch, BaseEntity events, and Invalidate*', async () => {
        const provider = makeProvider({ user: USER_A });
        const { engine, invokeBaseEntityEvent } = createTestEngine();

        H.runViewsHandler
            .mockResolvedValueOnce([
                {
                    Success: true,
                    Results: [
                        { ID: PERSON_1_ID.toUpperCase(), DisplayName: 'Person One' } as CommonPersonSummary,
                        { ID: PERSON_2_ID, DisplayName: 'Person Two' } as CommonPersonSummary,
                    ],
                },
            ])
            .mockResolvedValueOnce([
                {
                    Success: true,
                    Results: [{ ID: PERSON_3_ID, DisplayName: 'Person Three' } as CommonPersonSummary],
                },
            ])
            .mockResolvedValueOnce([
                {
                    Success: true,
                    Results: [
                        { ID: ORG_1_ID, Name: 'Acme Corp' } as CommonOrganizationSummary,
                        { ID: ORG_2_ID, Name: 'Beta LLC' } as CommonOrganizationSummary,
                    ],
                },
            ])
            .mockResolvedValueOnce([
                {
                    Success: true,
                    Results: [{ ID: PERSON_1_ID, DisplayName: 'Person One (Bob view)' } as CommonPersonSummary],
                },
            ]);

        // Call 1: fetches P1 + P2 in one single RunViews batch with narrow Fields and CacheLocal: false
        const batch1 = await engine.GetPeopleByIDs([PERSON_1_ID, PERSON_2_ID, 'not-a-uuid'], {
            provider,
            contextUser: USER_A,
        });
        expect(batch1.size).toBe(2);
        expect(batch1.get(NormalizeUUID(PERSON_1_ID))?.DisplayName).toBe('Person One');
        expect(H.runViewsCalls).toHaveLength(1);
        expect(H.runViewsCalls[0].requests).toHaveLength(1);
        expect(H.runViewsCalls[0].requests[0].ResultType).toBe('simple');
        expect(H.runViewsCalls[0].requests[0].CacheLocal).toBe(false);
        expect(H.runViewsCalls[0].requests[0].Fields).toContain('DisplayName');

        // Call 2: P2 is cached (even with uppercase spelling), only P3 is fetched!
        const batch2 = await engine.GetPeopleByIDs([PERSON_2_ID.toUpperCase(), PERSON_3_ID], {
            provider,
            contextUser: USER_A,
        });
        expect(batch2.size).toBe(2);
        expect(H.runViewsCalls).toHaveLength(2);
        expect(H.runViewsCalls[1].requests[0].ExtraFilter).toContain(PERSON_3_ID);
        expect(H.runViewsCalls[1].requests[0].ExtraFilter).not.toContain(PERSON_2_ID);

        // Call 3: All cached -> 0 network calls!
        const batch3 = await engine.GetPeopleByIDs([PERSON_1_ID, PERSON_3_ID], {
            provider,
            contextUser: USER_A,
        });
        expect(batch3.size).toBe(2);
        expect(H.runViewsCalls).toHaveLength(2);

        // Organizations batching
        const orgs = await engine.GetOrganizationsByIDs([ORG_1_ID, ORG_2_ID], {
            provider,
            contextUser: USER_A,
        });
        expect(orgs.size).toBe(2);
        expect(orgs.get(NormalizeUUID(ORG_1_ID))?.Name).toBe('Acme Corp');
        expect(H.runViewsCalls).toHaveLength(3);

        // BaseEntity save event invalidates only the saved record
        await invokeBaseEntityEvent({
            type: 'save',
            baseEntity: {
                EntityInfo: { Name: COMMON_ENGINE_ENTITIES.People },
                PrimaryKey: { KeyValuePairs: [{ FieldName: 'ID', Value: PERSON_2_ID.toUpperCase() }] },
            } as unknown as BaseEntity,
        });
        expect(engine.GetCachedPersonByID(PERSON_2_ID)).toBeNull();
        expect(engine.GetCachedPersonByID(PERSON_1_ID)).not.toBeNull();

        // Explicit invalidation
        engine.InvalidateOrganization(ORG_1_ID);
        expect(engine.GetCachedOrganizationByID(ORG_1_ID)).toBeNull();
        expect(engine.GetCachedOrganizationByID(ORG_2_ID)).not.toBeNull();

        // Persona switch directly on GetPeopleByIDs auto-evicts USER_A cache and queries as USER_B
        const bobView = await engine.GetPeopleByIDs([PERSON_1_ID], {
            provider,
            contextUser: USER_B,
        });
        expect(bobView.get(NormalizeUUID(PERSON_1_ID))?.DisplayName).toBe('Person One (Bob view)');
        expect(engine.GetCachedOrganizationByID(ORG_2_ID)).toBeNull();
        expect(H.runViewsCalls).toHaveLength(4);
    });
});
