import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type {
    EntityFieldState,
    EntityInfo,
    EntitySaveOptions,
    EntityTransactionScope,
    IEntityDataProvider,
    IRunViewProvider,
    RunViewParams,
    RunViewResult,
    UserInfo,
} from '@memberjunction/core';
import { MJGlobal, RegisterClass } from '@memberjunction/global';
import { REPORTS_TO_RELATIONSHIP_TYPE_ID } from '../reporting-chain.js';

type FieldPrimitive = string | number | boolean | Date | null;

interface StoredPersonRow {
    ID: string;
    FirstName: string;
    LastName: string;
    SupervisorPersonID: string | null;
}

interface StoredRelationshipRow {
    ID: string;
    RelationshipTypeID: string;
    FromPersonID: string | null;
    FromOrganizationID: string | null;
    ToPersonID: string | null;
    ToOrganizationID: string | null;
    StartDate: Date | null;
    EndDate: Date | null;
    Status: 'Active' | 'Ended' | 'Inactive';
    Notes: string | null;
}

interface StoreSnapshot {
    people: Map<string, StoredPersonRow>;
    relationships: Map<string, StoredRelationshipRow>;
}

const UUID_A = 'AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA';
const UUID_B = 'BBBBBBBB-BBBB-4BBB-8BBB-BBBBBBBBBBBB';
const UUID_C = 'CCCCCCCC-CCCC-4CCC-8CCC-CCCCCCCCCCCC';
const UUID_D = 'DDDDDDDD-DDDD-4DDD-8DDD-DDDDDDDDDDDD';
const UUID_NEW = 'EEEEEEEE-EEEE-4EEE-8EEE-EEEEEEEEEEEE';

const PEOPLE_ENTITY_NAME = 'MJ_BizApps_Common: People';
const RELATIONSHIPS_ENTITY_NAME = 'MJ_BizApps_Common: Relationships';

class FakeEntityField {
    public readonly Name: string;
    public readonly CodeName: string;
    public OldValue: FieldPrimitive = null;
    public Value: FieldPrimitive = null;
    public NotLoaded = false;

    constructor(name: string, initial: FieldPrimitive = null) {
        this.Name = name;
        this.CodeName = name;
        this.OldValue = initial;
        this.Value = initial;
    }

    public get Dirty(): boolean {
        return this.Value !== this.OldValue;
    }

    public GetState(): EntityFieldState {
        return {
            Value: this.Value,
            OldValue: this.OldValue,
            NeverSet: false,
            NotLoaded: this.NotLoaded,
            WrittenAfterNotLoaded: false,
        };
    }

    public RestoreState(state: EntityFieldState): void {
        this.Value = state.Value as FieldPrimitive;
        this.OldValue = state.OldValue as FieldPrimitive;
        this.NotLoaded = state.NotLoaded;
    }

    public RestoreOldValue(value: FieldPrimitive): void {
        this.OldValue = value;
    }
}

interface EntityRecordLike {
    EntityInfo: EntityInfo;
}

interface TestProvider extends IEntityDataProvider, IRunViewProvider {
    SupportsEntityTransactions: boolean;
    ProviderType: ProviderType;
    CurrentUser?: UserInfo;
    BeginEntityTransaction?: () => Promise<EntityTransactionScope>;
    ExecuteInTransaction?: <T>(work: () => Promise<T>) => Promise<T>;
    CreateTransactionGroup?: () => Promise<TransactionGroupBase>;
    GetEntityObject<T>(entityName: string, contextUser?: UserInfo): Promise<T>;
    SaveEntityRecord(entity: EntityRecordLike): Promise<boolean>;
    DeleteEntityRecord(entity: EntityRecordLike): Promise<boolean>;
    RunView<T>(params: RunViewParams, contextUser?: UserInfo): Promise<RunViewResult<T>>;
}

const hoisted = vi.hoisted(() => ({
    nextIdCounter: 1,
}));

vi.mock('@memberjunction/core', async (importOriginal) => {
    const actual = await importOriginal<typeof import('@memberjunction/core')>();

    class FakeBaseEntity {
        public EntityInfo: EntityInfo;
        public Fields: FakeEntityField[] = [];
        public IsSaved = false;
        public TransactionGroup: InstanceType<typeof actual.TransactionGroupBase> | null = null;
        public readonly ResultHistory: InstanceType<typeof actual.BaseEntityResult>[] = [];
        public ProviderToUse: TestProvider | null = null;
        public RunViewProviderToUse: IRunViewProvider | null = null;
        public ContextCurrentUser: UserInfo | undefined = undefined;
        public readonly ISAParentEntity: FakeBaseEntity | null = null;

        constructor(entityInfo?: EntityInfo, provider?: TestProvider | null) {
            this.EntityInfo = entityInfo ?? ({ Name: 'FakeEntity' } as EntityInfo);
            if (provider) {
                this.ProviderToUse = provider;
                this.RunViewProviderToUse = provider;
            }
        }

        protected DeclareRelatedRecords<T>(_opts: object): { Items: T[] } {
            return { Items: [] };
        }

        public get Dirty(): boolean {
            return this.Fields.some((f) => f.Dirty);
        }

        public get LatestResult(): InstanceType<typeof actual.BaseEntityResult> | undefined {
            return this.ResultHistory[this.ResultHistory.length - 1];
        }

        public get ActiveUser(): UserInfo | undefined {
            return this.ContextCurrentUser ?? this.ProviderToUse?.CurrentUser;
        }

        public GetFieldByName(name: string): FakeEntityField | undefined {
            return this.Fields.find((f) => f.Name === name);
        }

        protected Get(name: string): FieldPrimitive {
            return this.GetFieldByName(name)?.Value ?? null;
        }

        protected Set(name: string, value: FieldPrimitive): void {
            let field = this.GetFieldByName(name);
            if (!field) {
                field = new FakeEntityField(name, null);
                this.Fields.push(field);
            }
            field.Value = value;
        }

        public NewRecord(): boolean {
            this.IsSaved = false;
            for (const f of this.Fields) {
                f.Value = null;
                f.OldValue = null;
            }
            return true;
        }

        public async LoadFromData(
            values: Record<string, FieldPrimitive>,
            replaceOldValues = false,
        ): Promise<boolean> {
            this.Fields = Object.entries(values).map(([k, v]) => new FakeEntityField(k, v));
            if (replaceOldValues) {
                this.IsSaved = true;
            }
            return true;
        }

        public RegisterResultHistoryEntry(result: InstanceType<typeof actual.BaseEntityResult>): void {
            this.ResultHistory.push(result);
        }

        public Validate(): InstanceType<typeof actual.ValidationResult> {
            const result = new actual.ValidationResult();
            result.Success = true;
            return result;
        }

        public async ValidateAsync(): Promise<InstanceType<typeof actual.ValidationResult>> {
            const result = new actual.ValidationResult();
            result.Success = true;
            return result;
        }

        public async Save(options?: EntitySaveOptions): Promise<boolean> {
            if (!options?.ReplayOnly) {
                const syncVal = this.Validate();
                if (!syncVal.Success) {
                    const fail = new actual.BaseEntityResult();
                    fail.Success = false;
                    fail.Errors = syncVal.Errors;
                    fail.Message = syncVal.Errors.map((e) => e.Message).join('; ');
                    this.RegisterResultHistoryEntry(fail);
                    return false;
                }
                if (!options?.SkipAsyncValidation) {
                    const asyncVal = await this.ValidateAsync();
                    if (!asyncVal.Success) {
                        const fail = new actual.BaseEntityResult();
                        fail.Success = false;
                        fail.Errors = asyncVal.Errors;
                        fail.Message = asyncVal.Errors.map((e) => e.Message).join('; ');
                        this.RegisterResultHistoryEntry(fail);
                        return false;
                    }
                }
            }
            if (this.TransactionGroup) {
                const tg = this.TransactionGroup;
                if ('EnqueueEntitySave' in tg && typeof tg.EnqueueEntitySave === 'function') {
                    tg.EnqueueEntitySave(this, (success: boolean) => {
                        if (success) {
                            this.IsSaved = true;
                            for (const f of this.Fields) {
                                f.OldValue = f.Value;
                            }
                        }
                    });
                }
                return true;
            }
            if (!this.ProviderToUse) {
                return true;
            }
            const ok = await this.ProviderToUse.SaveEntityRecord(this);
            if (ok) {
                this.IsSaved = true;
                for (const f of this.Fields) {
                    f.OldValue = f.Value;
                }
            }
            return ok;
        }

        public async Delete(): Promise<boolean> {
            if (!this.ProviderToUse) {
                return true;
            }
            const ok = await this.ProviderToUse.DeleteEntityRecord(this);
            if (ok) {
                this.IsSaved = false;
            }
            return ok;
        }
    }

    class FakeRunView {
        private readonly provider: IRunViewProvider | null;
        constructor(provider?: IRunViewProvider | null) {
            this.provider = provider ?? null;
        }
        public async RunView<T>(params: RunViewParams, contextUser?: UserInfo): Promise<RunViewResult<T>> {
            if (!this.provider) {
                throw new Error('No RunView provider configured in test');
            }
            return this.provider.RunView<T>(params, contextUser);
        }
    }

    return {
        ...actual,
        BaseEntity: FakeBaseEntity,
        RunView: FakeRunView,
    };
});

import { BaseEntity, ProviderType, TransactionGroupBase, TransactionItem, TransactionResult } from '@memberjunction/core';
import { PersonEntity } from '../PersonEntity.js';
import { mjBizAppsCommonRelationshipEntity } from '../generated/entity_subclasses.js';
import { LoadGeneratedEntities } from '../index.js';

interface QueuedSaveEntry {
    entity: EntityRecordLike & { ID?: string };
    onSuccess: (success: boolean) => void;
}

class InMemoryTransactionGroup extends TransactionGroupBase {
    private readonly store: InMemoryHierarchyStore;
    private readonly provider: TestProvider;
    private readonly queuedSaves: QueuedSaveEntry[] = [];

    constructor(store: InMemoryHierarchyStore, provider: TestProvider) {
        super();
        this.store = store;
        this.provider = provider;
    }

    public EnqueueEntitySave(
        entity: EntityRecordLike & { ID?: string },
        onSuccess: (success: boolean) => void,
    ): void {
        this.queuedSaves.push({ entity, onSuccess });
    }

    public override async Submit(): Promise<boolean> {
        try {
            await this.HandleSubmit();
            return true;
        } catch {
            return false;
        }
    }

    protected override async HandleSubmit(): Promise<TransactionResult[]> {
        const snapshot = this.store.CaptureSnapshot();
        const results: TransactionResult[] = [];
        try {
            for (const entry of this.queuedSaves) {
                const entity = entry.entity;
                if (!entity.ID && this.Variables.length > 0) {
                    for (const v of this.Variables) {
                        if (v.Type === 'Use' && v.EntityObject === entity) {
                            const definer = this.Variables.find((d) => d.Type === 'Define' && d.Name === v.Name);
                            if (definer && v.FieldName === 'FromPersonID' && definer.FieldName === 'ID') {
                                const rel = entity as mjBizAppsCommonRelationshipEntity;
                                rel.FromPersonID = (definer.EntityObject as PersonEntity).ID;
                            }
                        }
                    }
                }
                const ok = await this.provider.SaveEntityRecord(entity);
                if (!ok) {
                    throw new Error(`TransactionGroup item failed for ${entity.EntityInfo?.Name ?? 'unknown'}`);
                }
                entry.onSuccess(true);
            }
            this.store.CommitCount++;
            return results;
        } catch (err) {
            this.store.RestoreSnapshot(snapshot);
            this.store.RollbackCount++;
            throw err;
        }
    }
}

@RegisterClass(BaseEntity, RELATIONSHIPS_ENTITY_NAME)
class TestRelationshipEntity extends mjBizAppsCommonRelationshipEntity {}

interface StoreFaultConfig {
    failPersonLookup?: boolean;
    failRelationshipLookup?: boolean;
    failRelationshipCloseSave?: boolean;
    throwOnRelationshipCloseSave?: boolean;
    failRelationshipCreateSave?: boolean;
    throwOnRelationshipCreateSave?: boolean;
}

class InMemoryHierarchyStore {
    public readonly People = new Map<string, StoredPersonRow>();
    public readonly Relationships = new Map<string, StoredRelationshipRow>();
    public readonly RunViewCalls: RunViewParams[] = [];
    public readonly PersonSaveCalls: StoredPersonRow[] = [];
    public readonly BeginTxCalls: number[] = [];
    public CommitCount = 0;
    public RollbackCount = 0;
    public Faults: StoreFaultConfig = {};

    private activeTxSnapshot: StoreSnapshot | null = null;
    private txDepth = 0;

    public SeedPerson(row: StoredPersonRow): void {
        this.People.set(row.ID.toLowerCase(), { ...row });
    }

    public SeedRelationship(row: StoredRelationshipRow): void {
        this.Relationships.set(row.ID.toLowerCase(), { ...row });
    }

    public GetPerson(id: string): StoredPersonRow | undefined {
        return this.People.get(id.toLowerCase());
    }

    public GetActiveReportsToFor(personId: string): StoredRelationshipRow[] {
        const lower = personId.toLowerCase();
        return [...this.Relationships.values()].filter(
            (r) =>
                r.FromPersonID?.toLowerCase() === lower &&
                r.RelationshipTypeID.toLowerCase() === REPORTS_TO_RELATIONSHIP_TYPE_ID.toLowerCase() &&
                r.Status === 'Active',
        );
    }

    public GetAllReportsToFor(personId: string): StoredRelationshipRow[] {
        const lower = personId.toLowerCase();
        return [...this.Relationships.values()].filter(
            (r) =>
                r.FromPersonID?.toLowerCase() === lower &&
                r.RelationshipTypeID.toLowerCase() === REPORTS_TO_RELATIONSHIP_TYPE_ID.toLowerCase(),
        );
    }

    public CreateProvider(options: {
        transactional?: boolean;
        executeInTransaction?: boolean;
        transactionGroup?: boolean;
        network?: boolean;
    } = {}): TestProvider {
        const transactional = options.transactional ?? true;
        const executeInTransaction = options.executeInTransaction ?? false;
        const transactionGroup = options.transactionGroup ?? false;
        const network = options.network ?? false;
        const store = this;

        const provider: TestProvider = {
            SupportsEntityTransactions: transactional && !network,
            ProviderType: network ? ProviderType.Network : ProviderType.Database,
            CurrentUser: { ID: '99999999-9999-4999-8999-999999999999' } as UserInfo,
            Config: async () => true,
            Load: async () => ({}),
            Save: async () => ({}),
            Delete: async () => true,
            GetRecordChanges: async () => [],
            RunViews: async () => [],
            FullTextSearch: async () => ({ Success: true, Results: [], TotalCount: 0, EntitiesSearched: 0, ElapsedMs: 0 }),
            SearchEntity: async () => [],
            SearchEntities: async () => [],
            ...(transactional && !network
                ? {
                      BeginEntityTransaction: async (): Promise<EntityTransactionScope> => {
                          store.txDepth++;
                          store.BeginTxCalls.push(store.txDepth);
                          const isNested = store.txDepth > 1;
                          if (!isNested) {
                              store.activeTxSnapshot = store.cloneSnapshot();
                          }
                          let settled = false;
                          return {
                              IsNested: isNested,
                              Commit: async () => {
                                  if (settled) return;
                                  settled = true;
                                  store.txDepth--;
                                  if (store.txDepth === 0) {
                                      store.activeTxSnapshot = null;
                                      store.CommitCount++;
                                  }
                              },
                              Rollback: async () => {
                                  if (settled) return;
                                  settled = true;
                                  store.txDepth--;
                                  if (store.txDepth === 0 && store.activeTxSnapshot) {
                                      store.restoreSnapshot(store.activeTxSnapshot);
                                      store.activeTxSnapshot = null;
                                      store.RollbackCount++;
                                  }
                              },
                          };
                      },
                  }
                : {}),
            ...(executeInTransaction && !network
                ? {
                      ExecuteInTransaction: async <T>(work: () => Promise<T>): Promise<T> => {
                          store.BeginTxCalls.push(1);
                          const snap = store.cloneSnapshot();
                          try {
                              const out = await work();
                              store.CommitCount++;
                              return out;
                          } catch (err) {
                              store.restoreSnapshot(snap);
                              store.RollbackCount++;
                              throw err;
                          }
                      },
                  }
                : {}),
            ...(transactionGroup && !network
                ? {
                      CreateTransactionGroup: async (): Promise<TransactionGroupBase> =>
                          new InMemoryTransactionGroup(store, provider),
                  }
                : {}),
            GetEntityObject: async <T>(entityName: string): Promise<T> => {
                if (entityName === RELATIONSHIPS_ENTITY_NAME) {
                    const rel = new TestRelationshipEntity({ Name: RELATIONSHIPS_ENTITY_NAME } as EntityInfo);
                    Object.assign(rel, {
                        ProviderToUse: provider,
                        RunViewProviderToUse: provider,
                    });
                    return rel as T;
                }
                const person = new PersonEntity({ Name: PEOPLE_ENTITY_NAME } as EntityInfo);
                Object.assign(person, {
                    ProviderToUse: provider,
                    RunViewProviderToUse: provider,
                });
                return person as T;
            },
            SaveEntityRecord: async (entity): Promise<boolean> => {
                const name = entity.EntityInfo?.Name;
                if (name === PEOPLE_ENTITY_NAME) {
                    const p = entity as PersonEntity;
                    if (!p.ID) {
                        p.ID = `00000000-0000-4000-8000-${String(hoisted.nextIdCounter++).padStart(12, '0')}`;
                    }
                    const row: StoredPersonRow = {
                        ID: p.ID,
                        FirstName: p.FirstName ?? '',
                        LastName: p.LastName ?? '',
                        SupervisorPersonID: p.SupervisorPersonID ?? null,
                    };
                    store.PersonSaveCalls.push({ ...row });
                    store.People.set(row.ID.toLowerCase(), row);
                    return true;
                }

                if (name === RELATIONSHIPS_ENTITY_NAME) {
                    const r = entity as TestRelationshipEntity;
                    if (r.IsSaved) {
                        if (store.Faults.throwOnRelationshipCloseSave) {
                            throw new Error('Simulated DB error while closing prior Reports To relationship');
                        }
                        if (store.Faults.failRelationshipCloseSave) {
                            return false;
                        }
                    } else {
                        if (store.Faults.throwOnRelationshipCreateSave) {
                            throw new Error('Simulated DB error while creating new Reports To relationship');
                        }
                        if (store.Faults.failRelationshipCreateSave) {
                            return false;
                        }
                        if (!r.ID) {
                            r.ID = `10000000-0000-4000-8000-${String(hoisted.nextIdCounter++).padStart(12, '0')}`;
                        }
                    }

                    const row: StoredRelationshipRow = {
                        ID: r.ID,
                        RelationshipTypeID: r.RelationshipTypeID,
                        FromPersonID: r.FromPersonID ?? null,
                        FromOrganizationID: r.FromOrganizationID ?? null,
                        ToPersonID: r.ToPersonID ?? null,
                        ToOrganizationID: r.ToOrganizationID ?? null,
                        StartDate: r.StartDate ?? null,
                        EndDate: r.EndDate ?? null,
                        Status: r.Status ?? 'Active',
                        Notes: r.Notes ?? null,
                    };
                    store.Relationships.set(row.ID.toLowerCase(), row);
                    return true;
                }
                return true;
            },
            DeleteEntityRecord: async (entity): Promise<boolean> => {
                if (entity.EntityInfo?.Name === PEOPLE_ENTITY_NAME) {
                    const p = entity as PersonEntity;
                    if (p.ID) {
                        store.People.delete(p.ID.toLowerCase());
                    }
                }
                return true;
            },
            RunView: async <T>(params: RunViewParams): Promise<RunViewResult<T>> => {
                store.RunViewCalls.push(params);
                if (params.EntityName === PEOPLE_ENTITY_NAME) {
                    if (store.Faults.failPersonLookup) {
                        return {
                            Success: false,
                            Results: [],
                            RowCount: 0,
                            TotalRowCount: 0,
                            ExecutionTime: 0,
                            ErrorMessage: 'Simulated People RunView failure',
                        };
                    }
                    const idMatch = String(params.ExtraFilter ?? '').match(/ID\s*=\s*'([^']+)'/i);
                    const targetId = idMatch?.[1]?.toLowerCase();
                    const matched = targetId
                        ? [...store.People.values()].filter((p) => p.ID.toLowerCase() === targetId)
                        : [...store.People.values()];
                    return {
                        Success: true,
                        Results: matched.map((p) => ({ ID: p.ID, SupervisorPersonID: p.SupervisorPersonID })) as T[],
                        RowCount: matched.length,
                        TotalRowCount: matched.length,
                        ExecutionTime: 0,
                        ErrorMessage: '',
                    };
                }

                if (params.EntityName === RELATIONSHIPS_ENTITY_NAME) {
                    if (store.Faults.failRelationshipLookup) {
                        return {
                            Success: false,
                            Results: [],
                            RowCount: 0,
                            TotalRowCount: 0,
                            ExecutionTime: 0,
                            ErrorMessage: 'Simulated Relationships RunView failure',
                        };
                    }
                    const fromMatch = String(params.ExtraFilter ?? '').match(/FromPersonID\s*=\s*'([^']+)'/i);
                    const fromId = fromMatch?.[1]?.toLowerCase();
                    const activeRows = [...store.Relationships.values()].filter(
                        (r) =>
                            (!fromId || r.FromPersonID?.toLowerCase() === fromId) &&
                            r.RelationshipTypeID.toLowerCase() === REPORTS_TO_RELATIONSHIP_TYPE_ID.toLowerCase() &&
                            r.Status === 'Active',
                    );
                    const entities: TestRelationshipEntity[] = [];
                    for (const row of activeRows) {
                        const rel = new TestRelationshipEntity({ Name: RELATIONSHIPS_ENTITY_NAME } as EntityInfo);
                        Object.assign(rel, {
                            ProviderToUse: provider,
                            RunViewProviderToUse: provider,
                        });
                        await rel.LoadFromData({
                            ID: row.ID,
                            RelationshipTypeID: row.RelationshipTypeID,
                            FromPersonID: row.FromPersonID,
                            FromOrganizationID: row.FromOrganizationID,
                            ToPersonID: row.ToPersonID,
                            ToOrganizationID: row.ToOrganizationID,
                            StartDate: row.StartDate,
                            EndDate: row.EndDate,
                            Status: row.Status,
                            Notes: row.Notes,
                        }, true);
                        entities.push(rel);
                    }
                    return {
                        Success: true,
                        Results: entities as T[],
                        RowCount: entities.length,
                        TotalRowCount: entities.length,
                        ExecutionTime: 0,
                        ErrorMessage: '',
                    };
                }

                return {
                    Success: true,
                    Results: [],
                    RowCount: 0,
                    TotalRowCount: 0,
                    ExecutionTime: 0,
                    ErrorMessage: '',
                };
            },
        };

        return provider;
    }

    public CaptureSnapshot(): StoreSnapshot {
        return this.cloneSnapshot();
    }

    public RestoreSnapshot(snap: StoreSnapshot): void {
        this.restoreSnapshot(snap);
    }

    private cloneSnapshot(): StoreSnapshot {
        const people = new Map<string, StoredPersonRow>();
        for (const [k, v] of this.People) people.set(k, { ...v });
        const relationships = new Map<string, StoredRelationshipRow>();
        for (const [k, v] of this.Relationships) relationships.set(k, { ...v });
        return { people, relationships };
    }

    private restoreSnapshot(snap: StoreSnapshot): void {
        this.People.clear();
        for (const [k, v] of snap.people) this.People.set(k, { ...v });
        this.Relationships.clear();
        for (const [k, v] of snap.relationships) this.Relationships.set(k, { ...v });
    }
}

async function makeSavedPerson(row: StoredPersonRow, provider: TestProvider): Promise<PersonEntity> {
    const person = new PersonEntity({ Name: PEOPLE_ENTITY_NAME } as EntityInfo);
    Object.assign(person, {
        ProviderToUse: provider,
        RunViewProviderToUse: provider,
    });
    await person.LoadFromData({
        ID: row.ID,
        FirstName: row.FirstName,
        LastName: row.LastName,
        SupervisorPersonID: row.SupervisorPersonID,
    }, true);
    return person;
}

function makeNewPerson(id: string | null, firstName: string, lastName: string, provider: TestProvider): PersonEntity {
    const person = new PersonEntity({ Name: PEOPLE_ENTITY_NAME } as EntityInfo);
    Object.assign(person, {
        ProviderToUse: provider,
        RunViewProviderToUse: provider,
    });
    person.NewRecord();
    if (id) {
        person.ID = id;
    }
    person.FirstName = firstName;
    person.LastName = lastName;
    return person;
}

describe('PersonEntity supervisor hierarchy, cycle detection, and atomic Reports To sync', () => {
    let store: InMemoryHierarchyStore;
    let provider: TestProvider;

    beforeEach(() => {
        hoisted.nextIdCounter = 1;
        store = new InMemoryHierarchyStore();
        provider = store.CreateProvider({ transactional: true });
    });

    afterEach(() => {
        vi.restoreAllMocks();
    });

    it('registers PersonEntity in MJ ClassFactory for MJ_BizApps_Common: People', () => {
        LoadGeneratedEntities();
        const reg = MJGlobal.Instance.ClassFactory.GetRegistration(BaseEntity, PEOPLE_ENTITY_NAME);
        expect(reg).toBeDefined();
        expect(reg?.SubClass).toBe(PersonEntity);
    });

    describe('S2-AC-1: Cycle detection in Validate(), ValidateAsync(), and Save()', () => {
        it('rejects self-supervisor (A -> A) synchronously in Validate() and in Save() before any DB write', async () => {
            store.SeedPerson({ ID: UUID_A, FirstName: 'Alice', LastName: 'A', SupervisorPersonID: null });
            const alice = await makeSavedPerson(store.GetPerson(UUID_A)!, provider);
            alice.SupervisorPersonID = UUID_A;

            const syncResult = alice.Validate();
            expect(syncResult.Success).toBe(false);
            expect(syncResult.Errors.some((e) => e.Source === 'SupervisorPersonID')).toBe(true);

            const asyncResult = await alice.ValidateAsync();
            expect(asyncResult.Success).toBe(false);
            expect(asyncResult.Errors.some((e) => e.Source === 'SupervisorPersonID')).toBe(true);

            const saved = await alice.Save();
            expect(saved).toBe(false);
            expect(store.PersonSaveCalls).toHaveLength(0);
            expect(alice.LatestResult?.Success).toBe(false);
            expect(alice.LatestResult?.Errors?.some((e) => e.Source === 'SupervisorPersonID')).toBe(true);
        });

        it('rejects self-supervisor case-insensitively across UUID casing differences', async () => {
            store.SeedPerson({ ID: UUID_A.toUpperCase(), FirstName: 'Alice', LastName: 'A', SupervisorPersonID: null });
            const alice = await makeSavedPerson(store.GetPerson(UUID_A)!, provider);
            alice.SupervisorPersonID = UUID_A.toLowerCase();

            const syncResult = alice.Validate();
            expect(syncResult.Success).toBe(false);
            expect(syncResult.Errors[0].Source).toBe('SupervisorPersonID');
        });

        it('rejects a 2-node reporting cycle (A -> B -> A) in ValidateAsync() and Save() using ResultType simple without DB writes', async () => {
            store.SeedPerson({ ID: UUID_A, FirstName: 'Alice', LastName: 'A', SupervisorPersonID: null });
            store.SeedPerson({ ID: UUID_B, FirstName: 'Bob', LastName: 'B', SupervisorPersonID: UUID_A });

            const alice = await makeSavedPerson(store.GetPerson(UUID_A)!, provider);
            alice.SupervisorPersonID = UUID_B;

            const asyncResult = await alice.ValidateAsync();
            expect(asyncResult.Success).toBe(false);
            expect(asyncResult.Errors.some((e) => e.Source === 'SupervisorPersonID' && /cycle/i.test(e.Message))).toBe(true);

            const peopleLookups = store.RunViewCalls.filter((c) => c.EntityName === PEOPLE_ENTITY_NAME);
            expect(peopleLookups.length).toBeGreaterThan(0);
            for (const call of peopleLookups) {
                expect(call.ResultType).toBe('simple');
                expect(call.Fields).toEqual(['ID', 'SupervisorPersonID']);
            }

            const saved = await alice.Save();
            expect(saved).toBe(false);
            expect(store.PersonSaveCalls).toHaveLength(0);
            expect(store.GetPerson(UUID_A)?.SupervisorPersonID).toBeNull();
        });

        it('rejects a multi-hop reporting cycle (A -> B -> C -> A and 4-hop A -> B -> C -> D -> A) before any DB write', async () => {
            store.SeedPerson({ ID: UUID_A, FirstName: 'Alice', LastName: 'A', SupervisorPersonID: null });
            store.SeedPerson({ ID: UUID_B, FirstName: 'Bob', LastName: 'B', SupervisorPersonID: UUID_C });
            store.SeedPerson({ ID: UUID_C, FirstName: 'Carol', LastName: 'C', SupervisorPersonID: UUID_D });
            store.SeedPerson({ ID: UUID_D, FirstName: 'Dan', LastName: 'D', SupervisorPersonID: UUID_A });

            const alice = await makeSavedPerson(store.GetPerson(UUID_A)!, provider);
            alice.SupervisorPersonID = UUID_B;

            const asyncResult = await alice.ValidateAsync();
            expect(asyncResult.Success).toBe(false);
            expect(asyncResult.Errors[0].Source).toBe('SupervisorPersonID');

            const saved = await alice.Save();
            expect(saved).toBe(false);
            expect(store.PersonSaveCalls).toHaveLength(0);
            expect(alice.LatestResult?.Success).toBe(false);
        });

        it('rejects a pre-existing cycle in the selected supervisor chain (A -> B -> C -> B) without infinite looping', async () => {
            store.SeedPerson({ ID: UUID_A, FirstName: 'Alice', LastName: 'A', SupervisorPersonID: null });
            store.SeedPerson({ ID: UUID_B, FirstName: 'Bob', LastName: 'B', SupervisorPersonID: UUID_C });
            store.SeedPerson({ ID: UUID_C, FirstName: 'Carol', LastName: 'C', SupervisorPersonID: UUID_B });

            const alice = await makeSavedPerson(store.GetPerson(UUID_A)!, provider);
            alice.SupervisorPersonID = UUID_B;

            const saved = await alice.Save();
            expect(saved).toBe(false);
            expect(store.PersonSaveCalls).toHaveLength(0);
            expect(alice.LatestResult?.Message).toMatch(/reporting cycle/i);
        });

        it('fails closed when the RunView hierarchy lookup fails', async () => {
            store.SeedPerson({ ID: UUID_A, FirstName: 'Alice', LastName: 'A', SupervisorPersonID: null });
            store.Faults.failPersonLookup = true;

            const alice = await makeSavedPerson(store.GetPerson(UUID_A)!, provider);
            alice.SupervisorPersonID = UUID_B;

            const saved = await alice.Save();
            expect(saved).toBe(false);
            expect(store.PersonSaveCalls).toHaveLength(0);
        });

        it('fails closed when RunView returns Success: true with empty Results ([]) for a non-null ancestor (missing or RLS-hidden)', async () => {
            store.SeedPerson({ ID: UUID_A, FirstName: 'Alice', LastName: 'A', SupervisorPersonID: null });
            store.SeedPerson({ ID: UUID_B, FirstName: 'Bob', LastName: 'B', SupervisorPersonID: UUID_C });
            // UUID_C is deliberately missing / hidden by RLS: RunView for UUID_C returns Success: true, Results: []

            const alice = await makeSavedPerson(store.GetPerson(UUID_A)!, provider);
            alice.SupervisorPersonID = UUID_B;

            const asyncResult = await alice.ValidateAsync();
            expect(asyncResult.Success).toBe(false);
            expect(asyncResult.Errors.some((e) => e.Source === 'SupervisorPersonID' && /not found|accessible/i.test(e.Message))).toBe(true);

            const saved = await alice.Save();
            expect(saved).toBe(false);
            expect(store.PersonSaveCalls).toHaveLength(0);
            expect(store.GetPerson(UUID_A)?.SupervisorPersonID).toBeNull();
        });

        it('rejects 2-node and multi-hop cycles synchronously in Validate() when hierarchy state is loaded or cached', async () => {
            store.SeedPerson({ ID: UUID_A, FirstName: 'Alice', LastName: 'A', SupervisorPersonID: null });
            store.SeedPerson({ ID: UUID_B, FirstName: 'Bob', LastName: 'B', SupervisorPersonID: UUID_A });
            store.SeedPerson({ ID: UUID_C, FirstName: 'Carol', LastName: 'C', SupervisorPersonID: UUID_B });
            store.SeedPerson({ ID: UUID_D, FirstName: 'Dan', LastName: 'D', SupervisorPersonID: UUID_C });

            // Loading entities populates the synchronous per-provider hierarchy snapshot
            const alice = await makeSavedPerson(store.GetPerson(UUID_A)!, provider);
            await makeSavedPerson(store.GetPerson(UUID_B)!, provider);
            await makeSavedPerson(store.GetPerson(UUID_C)!, provider);
            await makeSavedPerson(store.GetPerson(UUID_D)!, provider);

            // 2-node cycle A -> B -> A rejected synchronously in Validate()
            alice.SupervisorPersonID = UUID_B;
            const twoNodeSync = alice.Validate();
            expect(twoNodeSync.Success).toBe(false);
            expect(twoNodeSync.Errors.some((e) => e.Source === 'SupervisorPersonID' && /cycle/i.test(e.Message))).toBe(true);

            // Multi-hop 4-node cycle A -> D -> C -> B -> A rejected synchronously in Validate()
            alice.SupervisorPersonID = UUID_D;
            const multiHopSync = alice.Validate();
            expect(multiHopSync.Success).toBe(false);
            expect(multiHopSync.Errors.some((e) => e.Source === 'SupervisorPersonID' && /cycle/i.test(e.Message))).toBe(true);

            // ValidateAsync()-populated cache also powers synchronous Validate() without instantiating ancestor entities
            PersonEntity.ClearHierarchyCache(provider);
            expect(alice.Validate().Success).toBe(true);
            await alice.ValidateAsync();
            const postAsyncSync = alice.Validate();
            expect(postAsyncSync.Success).toBe(false);
            expect(postAsyncSync.Errors.some((e) => e.Source === 'SupervisorPersonID' && /cycle/i.test(e.Message))).toBe(true);
        });
    });

    describe('S2-AC-2: Dated Reports To relationship synchronization', () => {
        it('creates an active dated Reports To relationship when creating a new Person with SupervisorPersonID', async () => {
            store.SeedPerson({ ID: UUID_B, FirstName: 'Bob', LastName: 'B', SupervisorPersonID: null });

            const newPerson = makeNewPerson(UUID_NEW, 'Eve', 'E', provider);
            newPerson.SupervisorPersonID = UUID_B;

            const saved = await newPerson.Save();
            expect(saved).toBe(true);
            expect(store.CommitCount).toBe(1);
            expect(store.RollbackCount).toBe(0);

            const active = store.GetActiveReportsToFor(UUID_NEW);
            expect(active).toHaveLength(1);
            expect(active[0].FromPersonID).toBe(UUID_NEW);
            expect(active[0].ToPersonID).toBe(UUID_B);
            expect(active[0].RelationshipTypeID).toBe(REPORTS_TO_RELATIONSHIP_TYPE_ID);
            expect(active[0].StartDate).toBeInstanceOf(Date);
            expect(active[0].EndDate).toBeNull();
            expect(active[0].Status).toBe('Active');
        });

        it('closes prior active Reports To relationship with EndDate and creates a new active row when supervisor changes', async () => {
            store.SeedPerson({ ID: UUID_A, FirstName: 'Alice', LastName: 'A', SupervisorPersonID: UUID_B });
            store.SeedPerson({ ID: UUID_B, FirstName: 'Bob', LastName: 'B', SupervisorPersonID: null });
            store.SeedPerson({ ID: UUID_C, FirstName: 'Carol', LastName: 'C', SupervisorPersonID: null });
            store.SeedRelationship({
                ID: '20000000-0000-4000-8000-000000000001',
                RelationshipTypeID: REPORTS_TO_RELATIONSHIP_TYPE_ID,
                FromPersonID: UUID_A,
                FromOrganizationID: null,
                ToPersonID: UUID_B,
                ToOrganizationID: null,
                StartDate: new Date('2026-01-01T00:00:00.000Z'),
                EndDate: null,
                Status: 'Active',
                Notes: null,
            });

            const alice = await makeSavedPerson(store.GetPerson(UUID_A)!, provider);
            alice.SupervisorPersonID = UUID_C;

            const saved = await alice.Save();
            expect(saved).toBe(true);
            expect(store.CommitCount).toBe(1);

            const all = store.GetAllReportsToFor(UUID_A);
            expect(all).toHaveLength(2);
            const prior = all.find((r) => r.ToPersonID === UUID_B);
            const current = all.find((r) => r.ToPersonID === UUID_C);

            expect(prior?.Status).toBe('Ended');
            expect(prior?.EndDate).toBeInstanceOf(Date);
            expect(current?.Status).toBe('Active');
            expect(current?.StartDate).toBeInstanceOf(Date);
            expect(current?.EndDate).toBeNull();
        });

        it('closes active Reports To relationship without creating a new row when SupervisorPersonID is cleared', async () => {
            store.SeedPerson({ ID: UUID_A, FirstName: 'Alice', LastName: 'A', SupervisorPersonID: UUID_B });
            store.SeedPerson({ ID: UUID_B, FirstName: 'Bob', LastName: 'B', SupervisorPersonID: null });
            store.SeedRelationship({
                ID: '20000000-0000-4000-8000-000000000001',
                RelationshipTypeID: REPORTS_TO_RELATIONSHIP_TYPE_ID,
                FromPersonID: UUID_A,
                FromOrganizationID: null,
                ToPersonID: UUID_B,
                ToOrganizationID: null,
                StartDate: new Date('2026-01-01T00:00:00.000Z'),
                EndDate: null,
                Status: 'Active',
                Notes: null,
            });

            const alice = await makeSavedPerson(store.GetPerson(UUID_A)!, provider);
            alice.SupervisorPersonID = null;

            const saved = await alice.Save();
            expect(saved).toBe(true);
            expect(store.GetActiveReportsToFor(UUID_A)).toHaveLength(0);
            const all = store.GetAllReportsToFor(UUID_A);
            expect(all).toHaveLength(1);
            expect(all[0].Status).toBe('Ended');
            expect(all[0].EndDate).toBeInstanceOf(Date);
        });

        it('skips relationship sync when updating unrelated Person fields without changing SupervisorPersonID', async () => {
            store.SeedPerson({ ID: UUID_A, FirstName: 'Alice', LastName: 'A', SupervisorPersonID: UUID_B });
            store.SeedPerson({ ID: UUID_B, FirstName: 'Bob', LastName: 'B', SupervisorPersonID: null });

            const alice = await makeSavedPerson(store.GetPerson(UUID_A)!, provider);
            alice.FirstName = 'Alicia';

            const saved = await alice.Save();
            expect(saved).toBe(true);
            expect(store.BeginTxCalls).toHaveLength(0);
            expect(store.RunViewCalls.filter((c) => c.EntityName === RELATIONSHIPS_ENTITY_NAME)).toHaveLength(0);
        });
    });

    describe('S2-AC-3: Transactional atomicity and failure-path rollback', () => {
        it('rolls back Person.SupervisorPersonID when querying active Reports To relationships fails', async () => {
            store.SeedPerson({ ID: UUID_A, FirstName: 'Alice', LastName: 'A', SupervisorPersonID: null });
            store.SeedPerson({ ID: UUID_B, FirstName: 'Bob', LastName: 'B', SupervisorPersonID: null });
            store.Faults.failRelationshipLookup = true;

            const alice = await makeSavedPerson(store.GetPerson(UUID_A)!, provider);
            alice.SupervisorPersonID = UUID_B;

            const saved = await alice.Save();
            expect(saved).toBe(false);
            expect(store.RollbackCount).toBe(1);
            expect(store.CommitCount).toBe(0);
            // Persisted store remains at pre-save state
            expect(store.GetPerson(UUID_A)?.SupervisorPersonID).toBeNull();
            expect(store.GetActiveReportsToFor(UUID_A)).toHaveLength(0);
            // In-memory dirty tracking is restored so OldValue still reflects rolled-back DB state
            expect(alice.GetFieldByName('SupervisorPersonID')?.OldValue).toBeNull();
            expect(alice.LatestResult?.Success).toBe(false);
            expect(alice.LatestResult?.Message).toMatch(/rolled back/i);
        });

        it('rolls back both Person and prior relationship closure when creating the new Reports To row fails', async () => {
            store.SeedPerson({ ID: UUID_A, FirstName: 'Alice', LastName: 'A', SupervisorPersonID: UUID_B });
            store.SeedPerson({ ID: UUID_B, FirstName: 'Bob', LastName: 'B', SupervisorPersonID: null });
            store.SeedPerson({ ID: UUID_C, FirstName: 'Carol', LastName: 'C', SupervisorPersonID: null });
            store.SeedRelationship({
                ID: '20000000-0000-4000-8000-000000000001',
                RelationshipTypeID: REPORTS_TO_RELATIONSHIP_TYPE_ID,
                FromPersonID: UUID_A,
                FromOrganizationID: null,
                ToPersonID: UUID_B,
                ToOrganizationID: null,
                StartDate: new Date('2026-01-01T00:00:00.000Z'),
                EndDate: null,
                Status: 'Active',
                Notes: null,
            });
            store.Faults.failRelationshipCreateSave = true;

            const alice = await makeSavedPerson(store.GetPerson(UUID_A)!, provider);
            alice.SupervisorPersonID = UUID_C;

            const saved = await alice.Save();
            expect(saved).toBe(false);
            expect(store.RollbackCount).toBe(1);
            expect(store.CommitCount).toBe(0);

            // Both Person.SupervisorPersonID and the active Reports To row must remain pointing to Bob
            expect(store.GetPerson(UUID_A)?.SupervisorPersonID).toBe(UUID_B);
            const active = store.GetActiveReportsToFor(UUID_A);
            expect(active).toHaveLength(1);
            expect(active[0].ToPersonID).toBe(UUID_B);
            expect(active[0].Status).toBe('Active');
            expect(active[0].EndDate).toBeNull();
        });

        it('rolls back Person.SupervisorPersonID when closing the prior Reports To row throws', async () => {
            store.SeedPerson({ ID: UUID_A, FirstName: 'Alice', LastName: 'A', SupervisorPersonID: UUID_B });
            store.SeedPerson({ ID: UUID_B, FirstName: 'Bob', LastName: 'B', SupervisorPersonID: null });
            store.SeedRelationship({
                ID: '20000000-0000-4000-8000-000000000001',
                RelationshipTypeID: REPORTS_TO_RELATIONSHIP_TYPE_ID,
                FromPersonID: UUID_A,
                FromOrganizationID: null,
                ToPersonID: UUID_B,
                ToOrganizationID: null,
                StartDate: new Date('2026-01-01T00:00:00.000Z'),
                EndDate: null,
                Status: 'Active',
                Notes: null,
            });
            store.Faults.throwOnRelationshipCloseSave = true;

            const alice = await makeSavedPerson(store.GetPerson(UUID_A)!, provider);
            alice.SupervisorPersonID = null;

            const saved = await alice.Save();
            expect(saved).toBe(false);
            expect(store.RollbackCount).toBe(1);
            expect(store.GetPerson(UUID_A)?.SupervisorPersonID).toBe(UUID_B);
            expect(store.GetActiveReportsToFor(UUID_A)).toHaveLength(1);
        });

        it('aborts cleanly before any DB write on non-transactional providers lacking BeginEntityTransaction, ExecuteInTransaction, and TransactionGroup', async () => {
            const nonTxProvider = store.CreateProvider({
                transactional: false,
                executeInTransaction: false,
                transactionGroup: false,
            });
            store.SeedPerson({ ID: UUID_A, FirstName: 'Alice', LastName: 'A', SupervisorPersonID: UUID_B });
            store.SeedPerson({ ID: UUID_B, FirstName: 'Bob', LastName: 'B', SupervisorPersonID: null });
            store.SeedPerson({ ID: UUID_C, FirstName: 'Carol', LastName: 'C', SupervisorPersonID: null });
            store.SeedRelationship({
                ID: '20000000-0000-4000-8000-000000000001',
                RelationshipTypeID: REPORTS_TO_RELATIONSHIP_TYPE_ID,
                FromPersonID: UUID_A,
                FromOrganizationID: null,
                ToPersonID: UUID_B,
                ToOrganizationID: null,
                StartDate: new Date('2026-01-01T00:00:00.000Z'),
                EndDate: null,
                Status: 'Active',
                Notes: null,
            });

            const alice = await makeSavedPerson(store.GetPerson(UUID_A)!, nonTxProvider);
            alice.SupervisorPersonID = UUID_C;

            const saved = await alice.Save();
            expect(saved).toBe(false);
            // Fail closed BEFORE writing Person or Relationships
            expect(store.PersonSaveCalls).toHaveLength(0);
            expect(store.GetPerson(UUID_A)?.SupervisorPersonID).toBe(UUID_B);
            const active = store.GetActiveReportsToFor(UUID_A);
            expect(active).toHaveLength(1);
            expect(active[0].ToPersonID).toBe(UUID_B);
            expect(active[0].EndDate).toBeNull();
            expect(alice.LatestResult?.Success).toBe(false);
            expect(alice.LatestResult?.Message).toMatch(/transactional provider/i);
        });

        it('commits and rolls back atomically when provider uses ExecuteInTransaction', async () => {
            const execProvider = store.CreateProvider({
                transactional: false,
                executeInTransaction: true,
            });
            store.SeedPerson({ ID: UUID_A, FirstName: 'Alice', LastName: 'A', SupervisorPersonID: UUID_B });
            store.SeedPerson({ ID: UUID_B, FirstName: 'Bob', LastName: 'B', SupervisorPersonID: null });
            store.SeedPerson({ ID: UUID_C, FirstName: 'Carol', LastName: 'C', SupervisorPersonID: null });
            store.SeedRelationship({
                ID: '20000000-0000-4000-8000-000000000001',
                RelationshipTypeID: REPORTS_TO_RELATIONSHIP_TYPE_ID,
                FromPersonID: UUID_A,
                FromOrganizationID: null,
                ToPersonID: UUID_B,
                ToOrganizationID: null,
                StartDate: new Date('2026-01-01T00:00:00.000Z'),
                EndDate: null,
                Status: 'Active',
                Notes: null,
            });

            const alice = await makeSavedPerson(store.GetPerson(UUID_A)!, execProvider);
            store.Faults.failRelationshipCreateSave = true;
            alice.SupervisorPersonID = UUID_C;

            expect(await alice.Save()).toBe(false);
            expect(store.RollbackCount).toBe(1);
            expect(store.GetPerson(UUID_A)?.SupervisorPersonID).toBe(UUID_B);
            expect(store.GetActiveReportsToFor(UUID_A)[0].ToPersonID).toBe(UUID_B);

            store.Faults.failRelationshipCreateSave = false;
            alice.SupervisorPersonID = UUID_C;
            expect(await alice.Save()).toBe(true);
            expect(store.CommitCount).toBe(1);
            expect(store.GetPerson(UUID_A)?.SupervisorPersonID).toBe(UUID_C);
            expect(store.GetActiveReportsToFor(UUID_A)[0].ToPersonID).toBe(UUID_C);
        });

        it('commits and rolls back atomically when provider uses TransactionGroup', async () => {
            const tgProvider = store.CreateProvider({
                transactional: false,
                transactionGroup: true,
            });
            store.SeedPerson({ ID: UUID_A, FirstName: 'Alice', LastName: 'A', SupervisorPersonID: UUID_B });
            store.SeedPerson({ ID: UUID_B, FirstName: 'Bob', LastName: 'B', SupervisorPersonID: null });
            store.SeedPerson({ ID: UUID_C, FirstName: 'Carol', LastName: 'C', SupervisorPersonID: null });
            store.SeedRelationship({
                ID: '20000000-0000-4000-8000-000000000001',
                RelationshipTypeID: REPORTS_TO_RELATIONSHIP_TYPE_ID,
                FromPersonID: UUID_A,
                FromOrganizationID: null,
                ToPersonID: UUID_B,
                ToOrganizationID: null,
                StartDate: new Date('2026-01-01T00:00:00.000Z'),
                EndDate: null,
                Status: 'Active',
                Notes: null,
            });

            const alice = await makeSavedPerson(store.GetPerson(UUID_A)!, tgProvider);
            store.Faults.throwOnRelationshipCreateSave = true;
            alice.SupervisorPersonID = UUID_C;

            expect(await alice.Save()).toBe(false);
            expect(store.RollbackCount).toBe(1);
            expect(store.CommitCount).toBe(0);
            expect(store.GetPerson(UUID_A)?.SupervisorPersonID).toBe(UUID_B);
            expect(store.GetActiveReportsToFor(UUID_A)).toHaveLength(1);
            expect(store.GetActiveReportsToFor(UUID_A)[0].ToPersonID).toBe(UUID_B);
            expect(alice.GetFieldByName('SupervisorPersonID')?.OldValue).toBe(UUID_B);

            store.Faults.throwOnRelationshipCreateSave = false;
            alice.SupervisorPersonID = UUID_C;
            expect(await alice.Save()).toBe(true);
            expect(store.CommitCount).toBe(1);
            expect(store.GetPerson(UUID_A)?.SupervisorPersonID).toBe(UUID_C);
            expect(store.GetActiveReportsToFor(UUID_A)).toHaveLength(1);
            expect(store.GetActiveReportsToFor(UUID_A)[0].ToPersonID).toBe(UUID_C);
        });

        it('runs pre-flight cycle checks on network client providers while delegating atomic sync to server-side PersonEntityServer', async () => {
            const networkProvider = store.CreateProvider({ network: true });
            store.SeedPerson({ ID: UUID_A, FirstName: 'Alice', LastName: 'A', SupervisorPersonID: null });
            store.SeedPerson({ ID: UUID_B, FirstName: 'Bob', LastName: 'B', SupervisorPersonID: UUID_A });

            const alice = await makeSavedPerson(store.GetPerson(UUID_A)!, networkProvider);
            alice.SupervisorPersonID = UUID_B;

            // Cycle rejected locally before GraphQL round-trip
            expect(await alice.Save()).toBe(false);
            expect(store.PersonSaveCalls).toHaveLength(0);

            // Valid change sends only the Person save over the network (server handles atomic Relationship sync)
            store.SeedPerson({ ID: UUID_B, FirstName: 'Bob', LastName: 'B', SupervisorPersonID: null });
            PersonEntity.CacheHierarchyLinks(networkProvider, [{ ID: UUID_B, SupervisorPersonID: null }]);
            alice.SupervisorPersonID = UUID_B;
            expect(await alice.Save()).toBe(true);
            expect(store.PersonSaveCalls).toHaveLength(1);
            expect(store.RunViewCalls.filter((c) => c.EntityName === RELATIONSHIPS_ENTITY_NAME)).toHaveLength(0);
        });
    });
});
