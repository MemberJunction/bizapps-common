import {
    BaseEntity,
    BaseEntityResult,
    EntitySaveOptions,
    Metadata,
    ProviderType,
    RunView,
    UserInfo,
    ValidationResult,
    type EntityField,
    type EntityFieldState,
    type EntityTransactionScope,
    type IEntityDataProvider,
} from '@memberjunction/core';
import {
    EscapeSQLString,
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

interface SupervisorChainRow {
    ID: string;
    SupervisorPersonID: string | null;
}

interface EntityObjectFactory {
    GetEntityObject<T extends BaseEntity>(entityName: string, contextUser?: UserInfo): Promise<T>;
}

interface FieldStateSnapshot {
    field: EntityField;
    state: EntityFieldState;
}

interface AppliedRelationshipClosure {
    relationship: mjBizAppsCommonRelationshipEntity;
    previousEndDate: Date | null;
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
 *    before any database write occurs (self-supervisor `A -> A`, 2-node `A -> B -> A`, and
 *    multi-hop `A -> B -> C -> A` cycles via `RunView` with `ResultType: 'simple'`).
 * 2. Atomic dated `'Reports To'` synchronization in `MJ_BizApps_Common: Relationships`
 *    whenever `SupervisorPersonID` is set, changed, or cleared:
 *    - On transactional database providers (`SupportsEntityTransactions === true`), both the
 *      `Person` save and `'Reports To'` `Relationship` updates execute inside one shared
 *      `EntityTransactionScope`, rolling back all writes and restoring in-memory field state
 *      on any failure.
 *    - On network client providers (`ProviderType.Network`), pre-flight cycle validation runs
 *      locally while server-side `PersonEntityServer` (which extends this class) performs the
 *      transactional `Person` + `'Reports To'` synchronization in one database transaction.
 *    - On non-transactional providers without `BeginEntityTransaction`, failures trigger
 *      compensating rollback so `People.SupervisorPersonID` and active `'Reports To'` rows
 *      never diverge.
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
     * Synchronous validation: delegates to base field/schema validators and rejects
     * direct self-supervision (`UUIDsEqual(SupervisorPersonID, ID)`).
     */
    public override Validate(): ValidationResult {
        const result = super.Validate();
        this.appendSelfSupervisorError(result);
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
     * is set, changed, or cleared.
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
            return this.saveBaseWithoutDuplicateCycleCheck(options);
        }

        if (this.canUseEntityTransactions()) {
            return this.saveWithTransactionScope(options, plan);
        }
        return this.saveWithCompensation(options, plan);
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
                break;
            }
            currentId = normalizeId(row.SupervisorPersonID);
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
            return this.saveWithCompensation(options, plan);
        }

        let scope: EntityTransactionScope | null = null;
        try {
            scope = await provider.BeginEntityTransaction();
            const personSaved = await this.saveBaseWithoutDuplicateCycleCheck(options);
            if (!personSaved) {
                await this.safeRollbackScope(scope);
                return false;
            }

            await this.syncReportsToRelationship(plan.targetSupervisorId, utcTodayDate());
            await scope.Commit();
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

    private async saveWithCompensation(
        options: EntitySaveOptions | undefined,
        plan: SupervisorSyncPlan,
    ): Promise<boolean> {
        const personSaved = await this.saveBaseWithoutDuplicateCycleCheck(options);
        if (!personSaved) {
            return false;
        }

        const appliedClosures: AppliedRelationshipClosure[] = [];
        try {
            await this.syncReportsToRelationship(
                plan.targetSupervisorId,
                utcTodayDate(),
                appliedClosures,
            );
            return true;
        } catch (err) {
            await this.compensateAfterSyncFailure(options, plan, appliedClosures);
            this.restoreInMemoryState(plan);
            const detail = err instanceof Error ? err.message : String(err);
            this.recordFailureResult(
                `Failed to synchronize 'Reports To' relationship; changes reverted: ${detail}`,
                [],
            );
            return false;
        }
    }

    private async syncReportsToRelationship(
        targetSupervisorId: string | null,
        syncDate: Date,
        appliedClosures?: AppliedRelationshipClosure[],
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
            const previousEndDate = rel.EndDate ?? null;
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
            appliedClosures?.push({ relationship: rel, previousEndDate });
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

    private async compensateAfterSyncFailure(
        options: EntitySaveOptions | undefined,
        plan: SupervisorSyncPlan,
        appliedClosures: AppliedRelationshipClosure[],
    ): Promise<void> {
        for (let i = appliedClosures.length - 1; i >= 0; i--) {
            const entry = appliedClosures[i];
            try {
                entry.relationship.Status = 'Active';
                entry.relationship.EndDate = entry.previousEndDate;
                await entry.relationship.Save();
            } catch {
                // Best-effort compensation; original error will still be surfaced.
            }
        }

        try {
            if (!plan.wasSaved) {
                if (typeof this.Delete === 'function') {
                    await this.Delete();
                }
                return;
            }
            this.SupervisorPersonID = plan.previousSupervisorId;
            await this.saveBaseWithoutDuplicateCycleCheck(options);
        } catch {
            // Best-effort compensation; original error will still be surfaced.
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

    private isNetworkProvider(): boolean {
        return asRuntimeProvider(this.ProviderToUse)?.ProviderType === ProviderType.Network;
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
