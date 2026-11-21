import {
    BaseEntity,
    BaseEntityResult,
    EntitySaveOptions,
    Metadata,
    ProviderType,
    RunView,
    TransactionGroupBase,
    TransactionVariable,
    UserInfo,
    ValidationResult,
    type EntityField,
    type EntityFieldState,
    type EntityTransactionScope,
    type IEntityDataProvider,
} from '@memberjunction/core';
import {
    EscapeSQLString,
    NormalizeUUID,
    RegisterClass,
    UUIDSet,
    UUIDsEqual,
    ValidationErrorInfo,
    ValidationErrorType,
} from '@memberjunction/global';
import {
    mjBizAppsCommonPersonEntity,
    mjBizAppsCommonRelationshipEntity,
} from './generated/entity_subclasses';
import { REPORTS_TO_RELATIONSHIP_TYPE_ID } from './reporting-chain.js';

const PEOPLE_ENTITY_NAME = 'MJ_BizApps_Common: People' as const;
const RELATIONSHIPS_ENTITY_NAME = 'MJ_BizApps_Common: Relationships' as const;
const MAX_REPORTING_CHAIN_DEPTH = 100;
const DEFAULT_PROVIDER_CACHE_KEY: object = {};

/**
 * Per-provider synchronous snapshot of known `Person.ID -> SupervisorPersonID` edges.
 * Populated automatically when `PersonEntity` records load/save or when `detectTransitiveCycle`
 * queries live rows via `RunView`, allowing synchronous `Validate()` to reject known 2-node and
 * multi-hop reporting cycles in addition to self-supervision.
 */
const hierarchyCacheByProvider = new WeakMap<object, Map<string, string | null>>();

function getProviderHierarchyCache(provider: object | null | undefined): Map<string, string | null> {
    const key = provider ?? DEFAULT_PROVIDER_CACHE_KEY;
    let map = hierarchyCacheByProvider.get(key);
    if (!map) {
        map = new Map<string, string | null>();
        hierarchyCacheByProvider.set(key, map);
    }
    return map;
}

interface SupervisorChainRow {
    ID: string;
    SupervisorPersonID: string | null;
}

interface EntityObjectFactory {
    GetEntityObject<T extends BaseEntity>(entityName: string, contextUser?: UserInfo): Promise<T>;
}

interface ExecuteInTransactionProvider {
    ExecuteInTransaction<T>(work: () => Promise<T>): Promise<T>;
}

interface TransactionGroupProvider {
    CreateTransactionGroup(): Promise<TransactionGroupBase>;
}

interface FieldStateSnapshot {
    field: EntityField;
    state: EntityFieldState;
}

interface SupervisorSyncPlan {
    shouldSync: boolean;
    targetSupervisorId: string | null;
    previousSupervisorId: string | null;
    wasSaved: boolean;
    fieldSnapshots: FieldStateSnapshot[];
}

function hasNonEmptyId(value: string | null | undefined): value is string {
    return typeof value === 'string' && value.trim().length > 0;
}

function normalizeId(value: string | null | undefined): string | null {
    return hasNonEmptyId(value) ? value.trim() : null;
}

function sameNullableId(a: string | null, b: string | null): boolean {
    if (a === null && b === null) return true;
    if (a === null || b === null) return false;
    return UUIDsEqual(a, b);
}

interface ProviderWithRuntimeInfo {
    readonly ProviderType?: ProviderType;
    readonly CurrentUser?: UserInfo;
}

function hasGetEntityObject(
    provider: IEntityDataProvider | EntityObjectFactory | null | undefined,
): provider is IEntityDataProvider & EntityObjectFactory {
    return (
        provider != null &&
        'GetEntityObject' in provider &&
        typeof provider.GetEntityObject === 'function'
    );
}

function hasExecuteInTransaction(
    provider: IEntityDataProvider | ExecuteInTransactionProvider | null | undefined,
): provider is IEntityDataProvider & ExecuteInTransactionProvider {
    return (
        provider != null &&
        'ExecuteInTransaction' in provider &&
        typeof provider.ExecuteInTransaction === 'function'
    );
}

function hasCreateTransactionGroup(
    provider: IEntityDataProvider | TransactionGroupProvider | null | undefined,
): provider is IEntityDataProvider & TransactionGroupProvider {
    return (
        provider != null &&
        'CreateTransactionGroup' in provider &&
        typeof provider.CreateTransactionGroup === 'function'
    );
}

function asRuntimeProvider(
    provider: IEntityDataProvider | ProviderWithRuntimeInfo | null | undefined,
): ProviderWithRuntimeInfo | null {
    if (!provider) return null;
    if ('ProviderType' in provider) {
        return provider;
    }
    if ('CurrentUser' in provider) {
        return provider;
    }
    return null;
}

function utcTodayDate(): Date {
    const now = new Date();
    return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
}

function formatCaughtError(err: Error | object | string | number | boolean | null | undefined): string {
    if (err instanceof Error) return err.message;
    return String(err);
}

/**
 * Shared subclass of `MJ_BizApps_Common: People` (`mjBizAppsCommonPersonEntity`).
 *
 * Enforces:
 * 1. Reporting-hierarchy cycle detection in `Validate()`, `ValidateAsync()`, and `Save()`
 *    before any database write occurs:
 *    - `Validate()` checks self-supervision (`UUIDsEqual(SupervisorPersonID, ID)`) and walks
 *      any known/cached ancestor edges for this provider to reject 2-node and multi-hop cycles
 *      synchronously.
 *    - `ValidateAsync()` and `Save()` traverse the live database ancestor chain via `RunView`
 *      (`ResultType: 'simple'`, `BypassCache: true`) and fail closed if `RunView` fails or if
 *      a non-null ancestor lookup returns 0 rows (missing or hidden by row-level permissions).
 * 2. Atomic dated `'Reports To'` synchronization in `MJ_BizApps_Common: Relationships`
 *    whenever `SupervisorPersonID` is set, changed, or cleared:
 *    - On transactional database providers (`SupportsEntityTransactions === true` with
 *      `BeginEntityTransaction`, or `ExecuteInTransaction`), or providers supporting
 *      `TransactionGroup` (`this.TransactionGroup` / `CreateTransactionGroup()`), both the
 *      `Person` save and `'Reports To'` `Relationship` updates execute inside one shared
 *      atomic transaction, rolling back all writes and restoring in-memory field state on
 *      any failure.
 *    - On network client providers (`ProviderType.Network`), pre-flight cycle validation runs
 *      locally while server-side `PersonEntityServer` (which extends this class) performs the
 *      transactional `Person` + `'Reports To'` synchronization in one database transaction.
 *    - On non-network providers lacking both shared entity transactions and `TransactionGroup`,
 *      `Save()` fails closed BEFORE writing `Person` or `Relationships` so they never diverge.
 *
 * Concurrency guarantees:
 * - Same-row concurrent edits on a `Person` record are protected by MJ's field-level
 *   `ConcurrencyCheck` (`'enforce'` on GraphQL mutations) and `BaseEntity`'s per-instance
 *   `_pendingSave$` debounce.
 * - Cross-row simultaneous opposite-edge writes (`A -> B` and `B -> A` in parallel
 *   transactions) pass pre-write ancestor reads against the prior committed state under
 *   `READ COMMITTED`; `vwPersonReportingChain` remains cycle-safe via `VisitedPath` and
 *   `Depth < 100`.
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: People')
export class PersonEntity extends mjBizAppsCommonPersonEntity {
    private skipCycleCheckInNextValidateAsync = false;

    /**
     * Seeds or updates the synchronous per-provider ancestor cache (`personId -> supervisorPersonId`)
     * used by synchronous `Validate()`. Primarily used internally on load/save/lookup and in tests.
     */
    public static CacheHierarchyLinks(
        provider: object | null | undefined,
        links: ReadonlyArray<{ ID: string; SupervisorPersonID: string | null }>,
    ): void {
        const cache = getProviderHierarchyCache(provider);
        for (const entry of links) {
            if (hasNonEmptyId(entry.ID)) {
                const key = NormalizeUUID(entry.ID);
                const sup = normalizeId(entry.SupervisorPersonID);
                cache.set(key, sup ? NormalizeUUID(sup) : null);
            }
        }
    }

    /**
     * Clears the synchronous ancestor cache for a given provider (or the default no-provider key).
     */
    public static ClearHierarchyCache(provider?: object | null): void {
        getProviderHierarchyCache(provider).clear();
    }

    public override async Load(ID: string, EntityRelationshipsToLoad?: string[]): Promise<boolean> {
        const loaded = await super.Load(ID, EntityRelationshipsToLoad);
        if (loaded) {
            this.recordCommittedHierarchyState();
        }
        return loaded;
    }

    public override async LoadFromData(data: object, replaceOldValues = false): Promise<boolean> {
        const loaded = await super.LoadFromData(data, replaceOldValues);
        if (loaded) {
            this.recordCommittedHierarchyState();
        }
        return loaded;
    }

    /**
     * Synchronous validation: delegates to base field/schema validators, rejects direct
     * self-supervision (`UUIDsEqual(SupervisorPersonID, ID)`), and rejects 2-node or
     * multi-hop cycles detectable from known/cached ancestor edges for this provider.
     */
    public override Validate(): ValidationResult {
        const result = super.Validate();
        if (this.appendSelfSupervisorError(result)) {
            return result;
        }
        this.appendCachedCycleError(result);
        return result;
    }

    /**
     * Asynchronous validation: checks direct self-supervision and traverses the ancestor
     * reporting chain using `RunView` (`ResultType: 'simple'`) to reject 2-node and
     * multi-hop reporting cycles before any database write.
     */
    public override async ValidateAsync(): Promise<ValidationResult> {
        const result = await super.ValidateAsync();
        if (this.skipCycleCheckInNextValidateAsync) {
            return result;
        }
        await this.appendHierarchyCycleError(result, true);
        return result;
    }

    /**
     * Saves this `Person` record after rejecting any reporting cycle, and atomically
     * synchronizes dated `'Reports To'` `Relationships` whenever `SupervisorPersonID`
     * is set, changed, or cleared. Requires a shared transaction (`BeginEntityTransaction`,
     * `ExecuteInTransaction`, or `TransactionGroup`) on non-network providers whenever
     * supervisor synchronization is needed; fails closed before any write otherwise.
     */
    public override async Save(options?: EntitySaveOptions): Promise<boolean> {
        const preflight = await this.runPreflightValidation();
        if (!preflight.Success) {
            this.recordFailureResult(
                `Person save refused: ${preflight.Errors.map((e) => e.Message).join('; ')}`,
                preflight.Errors,
            );
            return false;
        }

        const plan = this.buildSupervisorSyncPlan(options);
        if (!plan.shouldSync || this.isNetworkProvider()) {
            const ok = await this.saveBaseWithoutDuplicateCycleCheck(options);
            if (ok) {
                this.recordHierarchyCacheEntry(this.ID, normalizeId(this.SupervisorPersonID));
            }
            return ok;
        }

        if (this.canUseEntityTransactions()) {
            return this.saveWithTransactionScope(options, plan);
        }
        if (this.canUseExecuteInTransaction()) {
            return this.saveWithExecuteInTransaction(options, plan);
        }
        if (this.canUseTransactionGroup()) {
            return this.saveWithTransactionGroup(options, plan);
        }

        this.recordFailureResult(
            `Cannot save Person supervisor change without a transactional provider (BeginEntityTransaction/ExecuteInTransaction or TransactionGroup); aborted before writing Person or Reports To relationships.`,
            [],
        );
        return false;
    }

    private appendSelfSupervisorError(result: ValidationResult): boolean {
        const supervisorId = normalizeId(this.SupervisorPersonID);
        const selfId = normalizeId(this.ID);
        if (!supervisorId || !selfId || !UUIDsEqual(supervisorId, selfId)) {
            return false;
        }
        result.Errors.push(
            new ValidationErrorInfo(
                'SupervisorPersonID',
                'A person cannot be assigned as their own supervisor.',
                this.SupervisorPersonID,
                ValidationErrorType.Failure,
            ),
        );
        result.Success = false;
        return true;
    }

    private appendCachedCycleError(result: ValidationResult): void {
        const supervisorId = normalizeId(this.SupervisorPersonID);
        if (!supervisorId) {
            return;
        }
        const cycleMessage = this.detectCachedTransitiveCycle(supervisorId);
        if (cycleMessage) {
            result.Errors.push(
                new ValidationErrorInfo(
                    'SupervisorPersonID',
                    cycleMessage,
                    this.SupervisorPersonID,
                    ValidationErrorType.Failure,
                ),
            );
            result.Success = false;
        }
    }

    private detectCachedTransitiveCycle(initialSupervisorId: string): string | null {
        const selfId = normalizeId(this.ID);
        const cache = getProviderHierarchyCache(this.ProviderToUse);
        const visited = new UUIDSet();
        if (selfId) {
            visited.Add(selfId);
        }

        let currentId: string | null = initialSupervisorId;
        let depth = 0;

        while (currentId) {
            if (depth >= MAX_REPORTING_CHAIN_DEPTH) {
                return `Supervisor reporting chain exceeds the maximum supported depth of ${MAX_REPORTING_CHAIN_DEPTH}.`;
            }
            if (visited.Has(currentId)) {
                if (selfId && UUIDsEqual(currentId, selfId)) {
                    return `Assigning supervisor '${initialSupervisorId}' would create a reporting cycle back to this person.`;
                }
                return `Supervisor '${initialSupervisorId}' is part of an existing reporting cycle.`;
            }
            visited.Add(currentId);

            const key = NormalizeUUID(currentId);
            if (!cache.has(key)) {
                // Ancestor edge is not yet cached synchronously; ValidateAsync()/Save() will verify via RunView.
                return null;
            }
            currentId = cache.get(key) ?? null;
            depth++;
        }
        return null;
    }

    private async appendHierarchyCycleError(
        result: ValidationResult,
        includeSelfCheck: boolean,
    ): Promise<void> {
        if (includeSelfCheck && this.appendSelfSupervisorError(result)) {
            return;
        }
        const supervisorId = normalizeId(this.SupervisorPersonID);
        if (!supervisorId) {
            return;
        }
        try {
            const cycleMessage = await this.detectTransitiveCycle(supervisorId);
            if (cycleMessage) {
                result.Errors.push(
                    new ValidationErrorInfo(
                        'SupervisorPersonID',
                        cycleMessage,
                        this.SupervisorPersonID,
                        ValidationErrorType.Failure,
                    ),
                );
                result.Success = false;
            }
        } catch (err) {
            const msg = err instanceof Error ? err.message : formatCaughtError(err as Error | string);
            result.Errors.push(
                new ValidationErrorInfo(
                    'SupervisorPersonID',
                    msg,
                    this.SupervisorPersonID,
                    ValidationErrorType.Failure,
                ),
            );
            result.Success = false;
        }
    }

    private async runPreflightValidation(): Promise<ValidationResult> {
        const syncResult = this.Validate();
        if (!syncResult.Success) {
            return syncResult;
        }
        await this.appendHierarchyCycleError(syncResult, false);
        return syncResult;
    }

    private async detectTransitiveCycle(initialSupervisorId: string): Promise<string | null> {
        const selfId = normalizeId(this.ID);
        const visited = new UUIDSet();
        if (selfId) {
            visited.Add(selfId);
        }

        let currentId: string | null = initialSupervisorId;
        let depth = 0;
        const rv = this.createRunView();
        const user = this.activeUserOrUndefined();

        while (currentId) {
            if (depth >= MAX_REPORTING_CHAIN_DEPTH) {
                return `Supervisor reporting chain exceeds the maximum supported depth of ${MAX_REPORTING_CHAIN_DEPTH}.`;
            }
            if (visited.Has(currentId)) {
                if (selfId && UUIDsEqual(currentId, selfId)) {
                    return `Assigning supervisor '${initialSupervisorId}' would create a reporting cycle back to this person.`;
                }
                return `Supervisor '${initialSupervisorId}' is part of an existing reporting cycle.`;
            }
            visited.Add(currentId);

            const lookup = await rv.RunView<SupervisorChainRow>(
                {
                    EntityName: PEOPLE_ENTITY_NAME,
                    Fields: ['ID', 'SupervisorPersonID'],
                    ExtraFilter: `ID = '${EscapeSQLString(currentId)}'`,
                    MaxRows: 1,
                    ResultType: 'simple',
                    BypassCache: true,
                },
                user,
            );
            if (!lookup?.Success) {
                throw new Error(
                    `Failed to validate supervisor hierarchy for '${currentId}': ${lookup?.ErrorMessage ?? 'RunView returned no result'}`,
                );
            }
            const row = lookup.Results?.[0];
            if (!row) {
                throw new Error(
                    `Cannot verify supervisor hierarchy: ancestor Person '${currentId}' was not found or is not accessible.`,
                );
            }
            const nextSupervisorId = normalizeId(row.SupervisorPersonID);
            this.recordHierarchyCacheEntry(row.ID, nextSupervisorId);
            currentId = nextSupervisorId;
            depth++;
        }
        return null;
    }

    private buildSupervisorSyncPlan(options?: EntitySaveOptions): SupervisorSyncPlan {
        const wasSaved = Boolean(this.IsSaved);
        const targetSupervisorId = normalizeId(this.SupervisorPersonID);
        const supField = this.getSupervisorField();
        const oldRaw = supField?.OldValue;
        const previousSupervisorId = typeof oldRaw === 'string' ? normalizeId(oldRaw) : null;
        const fieldSnapshots = this.captureFieldSnapshots();

        if (!wasSaved) {
            return {
                shouldSync: targetSupervisorId !== null,
                targetSupervisorId,
                previousSupervisorId: null,
                wasSaved,
                fieldSnapshots,
            };
        }

        if (!supField) {
            return {
                shouldSync: true,
                targetSupervisorId,
                previousSupervisorId: null,
                wasSaved,
                fieldSnapshots,
            };
        }

        const changed =
            supField.Dirty &&
            (!sameNullableId(previousSupervisorId, targetSupervisorId) ||
                (targetSupervisorId === null && previousSupervisorId === null));
        const forced = Boolean(options?.IgnoreDirtyState) && targetSupervisorId !== null;

        return {
            shouldSync: changed || forced,
            targetSupervisorId,
            previousSupervisorId,
            wasSaved,
            fieldSnapshots,
        };
    }

    private async saveWithTransactionScope(
        options: EntitySaveOptions | undefined,
        plan: SupervisorSyncPlan,
    ): Promise<boolean> {
        const provider = this.ProviderToUse;
        if (!provider?.BeginEntityTransaction) {
            this.recordFailureResult(
                `Cannot save Person supervisor change without BeginEntityTransaction support; aborted before writing.`,
                [],
            );
            return false;
        }

        let scope: EntityTransactionScope | null = null;
        try {
            scope = await provider.BeginEntityTransaction();
            const personSaved = await this.saveBaseWithoutDuplicateCycleCheck(options);
            if (!personSaved) {
                await this.safeRollbackScope(scope);
                this.restoreInMemoryState(plan);
                return false;
            }

            await this.syncReportsToRelationship(plan.targetSupervisorId, utcTodayDate());
            await scope.Commit();
            this.recordHierarchyCacheEntry(this.ID, plan.targetSupervisorId);
            return true;
        } catch (err) {
            await this.safeRollbackScope(scope);
            this.restoreInMemoryState(plan);
            const detail = err instanceof Error ? err.message : String(err);
            this.recordFailureResult(
                `Failed to synchronize 'Reports To' relationship; transaction rolled back: ${detail}`,
                [],
            );
            return false;
        }
    }

    private async saveWithExecuteInTransaction(
        options: EntitySaveOptions | undefined,
        plan: SupervisorSyncPlan,
    ): Promise<boolean> {
        const provider = this.ProviderToUse;
        if (!hasExecuteInTransaction(provider)) {
            this.recordFailureResult(
                `Cannot save Person supervisor change without ExecuteInTransaction support; aborted before writing.`,
                [],
            );
            return false;
        }

        try {
            const committed = await provider.ExecuteInTransaction(async () => {
                const personSaved = await this.saveBaseWithoutDuplicateCycleCheck(options);
                if (!personSaved) {
                    throw new Error(
                        this.LatestResult?.CompleteMessage ??
                            this.LatestResult?.Message ??
                            'Failed saving Person record.',
                    );
                }
                await this.syncReportsToRelationship(plan.targetSupervisorId, utcTodayDate());
                return true;
            });
            if (committed) {
                this.recordHierarchyCacheEntry(this.ID, plan.targetSupervisorId);
            }
            return committed;
        } catch (err) {
            this.restoreInMemoryState(plan);
            const detail = err instanceof Error ? err.message : String(err);
            this.recordFailureResult(
                `Failed to synchronize 'Reports To' relationship; transaction rolled back: ${detail}`,
                [],
            );
            return false;
        }
    }

    private async saveWithTransactionGroup(
        options: EntitySaveOptions | undefined,
        plan: SupervisorSyncPlan,
    ): Promise<boolean> {
        const externalGroup = this.TransactionGroup ?? null;
        const provider = this.ProviderToUse;
        let tg: TransactionGroupBase;

        if (externalGroup) {
            tg = externalGroup;
        } else if (hasCreateTransactionGroup(provider)) {
            tg = await provider.CreateTransactionGroup();
        } else {
            this.recordFailureResult(
                `Cannot save Person supervisor change without TransactionGroup support; aborted before writing.`,
                [],
            );
            return false;
        }

        const ownedGroup = !externalGroup;
        const syncDate = utcTodayDate();
        if (ownedGroup) {
            this.TransactionGroup = tg;
        }
        try {
            const personQueued = await this.saveBaseWithoutDuplicateCycleCheck(options);
            if (!personQueued) {
                this.restoreInMemoryState(plan);
                return false;
            }

            await this.enqueueReportsToRelationshipInGroup(
                tg,
                plan.targetSupervisorId,
                syncDate,
            );

            if (!ownedGroup) {
                return true;
            }

            const submitted = await tg.Submit();
            if (!submitted) {
                this.restoreInMemoryState(plan);
                const detail =
                    this.LatestResult?.CompleteMessage ??
                    this.LatestResult?.Message ??
                    'TransactionGroup.Submit() returned false';
                this.recordFailureResult(
                    `Failed to synchronize 'Reports To' relationship; TransactionGroup rolled back: ${detail}`,
                    [],
                );
                return false;
            }
            this.recordHierarchyCacheEntry(this.ID, plan.targetSupervisorId);
            return true;
        } catch (err) {
            this.restoreInMemoryState(plan);
            const detail = err instanceof Error ? err.message : String(err);
            this.recordFailureResult(
                `Failed to synchronize 'Reports To' relationship; TransactionGroup aborted: ${detail}`,
                [],
            );
            return false;
        } finally {
            if (ownedGroup) {
                this.TransactionGroup = null;
            }
        }
    }

    private async syncReportsToRelationship(
        targetSupervisorId: string | null,
        syncDate: Date,
    ): Promise<void> {
        const personId = normalizeId(this.ID);
        if (!personId) {
            throw new Error('Cannot synchronize Reports To relationship without a saved Person ID.');
        }

        const rv = this.createRunView();
        const user = this.activeUserOrUndefined();
        const activeResult = await rv.RunView<mjBizAppsCommonRelationshipEntity>(
            {
                EntityName: RELATIONSHIPS_ENTITY_NAME,
                ExtraFilter:
                    `FromPersonID = '${EscapeSQLString(personId)}' ` +
                    `AND RelationshipTypeID = '${REPORTS_TO_RELATIONSHIP_TYPE_ID}' ` +
                    `AND Status = 'Active'`,
                ResultType: 'entity_object',
                BypassCache: true,
            },
            user,
        );
        if (!activeResult?.Success) {
            throw new Error(
                `Failed loading active 'Reports To' relationships for Person '${personId}': ${activeResult?.ErrorMessage ?? 'RunView failed'}`,
            );
        }

        let hasMatchingActive = false;
        for (const rel of activeResult.Results ?? []) {
            if (targetSupervisorId && !hasMatchingActive && sameNullableId(normalizeId(rel.ToPersonID), targetSupervisorId)) {
                hasMatchingActive = true;
                continue;
            }
            rel.Status = 'Ended';
            if (!rel.EndDate) {
                rel.EndDate = syncDate;
            }
            const closed = await rel.Save();
            if (!closed) {
                throw new Error(
                    `Failed closing prior 'Reports To' relationship '${rel.ID}': ${rel.LatestResult?.CompleteMessage ?? 'Save returned false'}`,
                );
            }
        }

        if (targetSupervisorId && !hasMatchingActive) {
            const newRel = await this.createRelationshipEntity(user);
            newRel.NewRecord();
            newRel.RelationshipTypeID = REPORTS_TO_RELATIONSHIP_TYPE_ID;
            newRel.FromPersonID = personId;
            newRel.FromOrganizationID = null;
            newRel.ToPersonID = targetSupervisorId;
            newRel.ToOrganizationID = null;
            newRel.StartDate = syncDate;
            newRel.EndDate = null;
            newRel.Status = 'Active';
            newRel.Notes = null;
            const created = await newRel.Save();
            if (!created) {
                throw new Error(
                    `Failed creating 'Reports To' relationship '${personId}' -> '${targetSupervisorId}': ${newRel.LatestResult?.CompleteMessage ?? 'Save returned false'}`,
                );
            }
        }
    }

    private async enqueueReportsToRelationshipInGroup(
        tg: TransactionGroupBase,
        targetSupervisorId: string | null,
        syncDate: Date,
    ): Promise<void> {
        const personId = normalizeId(this.ID);
        const user = this.activeUserOrUndefined();
        let hasMatchingActive = false;

        if (personId) {
            const rv = this.createRunView();
            const activeResult = await rv.RunView<mjBizAppsCommonRelationshipEntity>(
                {
                    EntityName: RELATIONSHIPS_ENTITY_NAME,
                    ExtraFilter:
                        `FromPersonID = '${EscapeSQLString(personId)}' ` +
                        `AND RelationshipTypeID = '${REPORTS_TO_RELATIONSHIP_TYPE_ID}' ` +
                        `AND Status = 'Active'`,
                    ResultType: 'entity_object',
                    BypassCache: true,
                },
                user,
            );
            if (!activeResult?.Success) {
                throw new Error(
                    `Failed loading active 'Reports To' relationships for Person '${personId}': ${activeResult?.ErrorMessage ?? 'RunView failed'}`,
                );
            }

            for (const rel of activeResult.Results ?? []) {
                if (targetSupervisorId && !hasMatchingActive && sameNullableId(normalizeId(rel.ToPersonID), targetSupervisorId)) {
                    hasMatchingActive = true;
                    continue;
                }
                rel.Status = 'Ended';
                if (!rel.EndDate) {
                    rel.EndDate = syncDate;
                }
                rel.TransactionGroup = tg;
                const queuedClose = await rel.Save();
                if (!queuedClose) {
                    throw new Error(
                        `Failed enqueueing closure of prior 'Reports To' relationship '${rel.ID}': ${rel.LatestResult?.CompleteMessage ?? 'Save returned false'}`,
                    );
                }
            }
        }

        if (targetSupervisorId && !hasMatchingActive) {
            const newRel = await this.createRelationshipEntity(user);
            newRel.NewRecord();
            newRel.RelationshipTypeID = REPORTS_TO_RELATIONSHIP_TYPE_ID;
            if (personId) {
                newRel.FromPersonID = personId;
            } else {
                const varName = 'SupervisorSyncPersonID';
                tg.AddVariable(new TransactionVariable(varName, this, 'ID', 'Define'));
                tg.AddVariable(new TransactionVariable(varName, newRel, 'FromPersonID', 'Use'));
            }
            newRel.FromOrganizationID = null;
            newRel.ToPersonID = targetSupervisorId;
            newRel.ToOrganizationID = null;
            newRel.StartDate = syncDate;
            newRel.EndDate = null;
            newRel.Status = 'Active';
            newRel.Notes = null;
            newRel.TransactionGroup = tg;
            const queuedCreate = await newRel.Save();
            if (!queuedCreate) {
                throw new Error(
                    `Failed enqueueing 'Reports To' relationship '${personId ?? '<new>'}' -> '${targetSupervisorId}': ${newRel.LatestResult?.CompleteMessage ?? 'Save returned false'}`,
                );
            }
        }
    }

    private async saveBaseWithoutDuplicateCycleCheck(
        options?: EntitySaveOptions,
    ): Promise<boolean> {
        this.skipCycleCheckInNextValidateAsync = true;
        try {
            return await super.Save(options);
        } finally {
            this.skipCycleCheckInNextValidateAsync = false;
        }
    }

    private async createRelationshipEntity(
        user: UserInfo | undefined,
    ): Promise<mjBizAppsCommonRelationshipEntity> {
        const provider = this.ProviderToUse;
        if (hasGetEntityObject(provider)) {
            return provider.GetEntityObject<mjBizAppsCommonRelationshipEntity>(
                RELATIONSHIPS_ENTITY_NAME,
                user,
            );
        }
        return Metadata.Provider.GetEntityObject<mjBizAppsCommonRelationshipEntity>(
            RELATIONSHIPS_ENTITY_NAME,
            user,
        );
    }

    private canUseEntityTransactions(): boolean {
        const provider = this.ProviderToUse;
        return (
            provider?.SupportsEntityTransactions === true &&
            typeof provider.BeginEntityTransaction === 'function'
        );
    }

    private canUseExecuteInTransaction(): boolean {
        return hasExecuteInTransaction(this.ProviderToUse);
    }

    private canUseTransactionGroup(): boolean {
        return Boolean(this.TransactionGroup) || hasCreateTransactionGroup(this.ProviderToUse);
    }

    private isNetworkProvider(): boolean {
        return asRuntimeProvider(this.ProviderToUse)?.ProviderType === ProviderType.Network;
    }

    private recordCommittedHierarchyState(): void {
        const selfId = normalizeId(this.ID);
        if (!selfId) {
            return;
        }
        const supField = this.getSupervisorField();
        const committedSup =
            supField && typeof supField.OldValue === 'string'
                ? normalizeId(supField.OldValue)
                : supField?.OldValue === null
                  ? null
                  : normalizeId(this.SupervisorPersonID);
        this.recordHierarchyCacheEntry(selfId, committedSup);
    }

    private recordHierarchyCacheEntry(
        personId: string | null | undefined,
        supervisorPersonId: string | null,
    ): void {
        const normalizedPerson = normalizeId(personId);
        if (!normalizedPerson) {
            return;
        }
        const cache = getProviderHierarchyCache(this.ProviderToUse);
        const key = NormalizeUUID(normalizedPerson);
        cache.set(key, supervisorPersonId ? NormalizeUUID(supervisorPersonId) : null);
    }

    private createRunView(): RunView {
        const rvProvider = this.RunViewProviderToUse;
        return rvProvider ? new RunView(rvProvider) : new RunView();
    }

    private activeUserOrUndefined(): UserInfo | undefined {
        try {
            const runtimeUser = asRuntimeProvider(this.ProviderToUse)?.CurrentUser;
            return this.ContextCurrentUser ?? runtimeUser ?? this.ActiveUser ?? undefined;
        } catch {
            return undefined;
        }
    }

    private getSupervisorField(): EntityField | undefined {
        if (typeof this.GetFieldByName !== 'function') {
            return undefined;
        }
        return this.GetFieldByName('SupervisorPersonID') ?? undefined;
    }

    private captureFieldSnapshots(): FieldStateSnapshot[] {
        if (!Array.isArray(this.Fields)) {
            return [];
        }
        const snapshots: FieldStateSnapshot[] = [];
        for (const field of this.Fields) {
            if (typeof field.GetState === 'function') {
                snapshots.push({ field, state: field.GetState() });
            }
        }
        return snapshots;
    }

    private restoreInMemoryState(plan: SupervisorSyncPlan): void {
        if (!plan.wasSaved && !this.ISAParentEntity && typeof this.NewRecord === 'function') {
            this.NewRecord();
        }
        for (const snap of plan.fieldSnapshots) {
            if (typeof snap.field.RestoreState === 'function') {
                snap.field.RestoreState(snap.state);
            }
        }
        if (plan.fieldSnapshots.length === 0) {
            this.SupervisorPersonID = plan.previousSupervisorId;
        }
    }

    private async safeRollbackScope(scope: EntityTransactionScope | null): Promise<void> {
        if (!scope) return;
        try {
            await scope.Rollback();
        } catch {
            // Preserve the original failure reason; scope rollback is best-effort on failure path.
        }
    }

    private recordFailureResult(message: string, errors: ValidationErrorInfo[]): void {
        const result = new BaseEntityResult();
        result.Success = false;
        result.Type = this.IsSaved ? 'update' : 'create';
        result.Message = message;
        result.Errors = errors;
        result.MessageIncludesErrors = errors.length > 0;
        result.StartedAt = new Date();
        result.EndedAt = new Date();
        if (typeof this.RegisterResultHistoryEntry === 'function') {
            this.RegisterResultHistoryEntry(result);
        }
    }
}
