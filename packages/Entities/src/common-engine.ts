/**
 * @fileoverview Shared metadata & bounded party lookup engine for `@mj-biz-apps/common-entities`.
 *
 * `CommonEngine` extends `BaseEngine<CommonEngine>` (`BaseSingleton`) to:
 * 1. Cache all bounded Common reference/taxonomy entities (`Activity Types`, `Address Types`,
 *    `Consent Purposes`, `Contact Types`, `Job Functions`, `Organization Types`,
 *    `Relationship Types`, `Seniority Levels`, `Activity Sync Provider Types`) via
 *    `BaseEnginePropertyConfig` (`AutoRefresh: true`, `CacheLocal: false`) with O(1) lookup
 *    maps rebuilt on every reload in `AdditionalLoading`.
 * 2. Enforce multi-provider & impersonation safety: `ProviderToUse` follows the provider passed
 *    to `Config()` or `Metadata.Provider`; switching provider or `userId` auto-evicts per-user
 *    bounded caches and refreshes permission-gated configs; every entity load is gated on
 *    `EntityInfo.GetUserPermisions(user)?.CanRead`.
 * 3. Provide incremental, bounded ID-keyed batching for `People` and `Organizations`
 *    (`GetPeopleByIDs`, `GetOrganizationsByIDs`) with `BaseEntity` save/delete event
 *    invalidation, explicit `Invalidate*()` helpers, and persona-switch eviction — never
 *    caching unbounded transactional tables globally or arbitrary `ExtraFilter` list queries.
 */
import {
    BaseEntity,
    BaseEntityEvent,
    BaseEngine,
    BaseEnginePropertyConfig,
    EntityInfo,
    IMetadataProvider,
    LogError,
    Metadata,
    RunView,
    RunViewParams,
    UserInfo,
} from '@memberjunction/core';
import { EscapeSQLString, IsValidUUID, NormalizeUUID, UUIDsEqual } from '@memberjunction/global';
import {
    mjBizAppsCommonActivitySyncProviderTypeEntity,
    mjBizAppsCommonActivityTypeEntity,
    mjBizAppsCommonAddressTypeEntity,
    mjBizAppsCommonConsentPurposeEntity,
    mjBizAppsCommonContactTypeEntity,
    mjBizAppsCommonJobFunctionEntity,
    mjBizAppsCommonOrganizationEntity,
    mjBizAppsCommonOrganizationTypeEntity,
    mjBizAppsCommonPersonEntity,
    mjBizAppsCommonRelationshipEntity,
    mjBizAppsCommonRelationshipTypeEntity,
    mjBizAppsCommonSeniorityLevelEntity,
} from './generated/entity_subclasses';

/** Canonical entity names managed or looked up by {@link CommonEngine}. */
export const COMMON_ENGINE_ENTITIES = {
    ActivityTypes: 'MJ_BizApps_Common: Activity Types',
    AddressTypes: 'MJ_BizApps_Common: Address Types',
    ConsentPurposes: 'MJ_BizApps_Common: Consent Purposes',
    ContactTypes: 'MJ_BizApps_Common: Contact Types',
    JobFunctions: 'MJ_BizApps_Common: Job Functions',
    OrganizationTypes: 'MJ_BizApps_Common: Organization Types',
    RelationshipTypes: 'MJ_BizApps_Common: Relationship Types',
    SeniorityLevels: 'MJ_BizApps_Common: Seniority Levels',
    ActivitySyncProviderTypes: 'MJ_BizApps_Common: Activity Sync Provider Types',
    People: 'MJ_BizApps_Common: People',
    Organizations: 'MJ_BizApps_Common: Organizations',
    Relationships: 'MJ_BizApps_Common: Relationships',
} as const;

/** Narrow summary projection returned by incremental Person ID batching. */
export type CommonPersonSummary = Pick<
    mjBizAppsCommonPersonEntity,
    | 'ID'
    | 'DisplayName'
    | 'FirstName'
    | 'LastName'
    | 'Title'
    | 'Email'
    | 'PrimaryEmail'
    | 'Phone'
    | 'PrimaryPhone'
    | 'PhotoURL'
    | 'Status'
    | 'CurrentOrganizationID'
    | 'CurrentOrganizationName'
    | 'CurrentJobTitle'
    | 'SupervisorPersonID'
    | 'SeniorityLevelID'
    | 'PrimaryJobFunctionID'
>;

/** Narrow summary projection returned by incremental Organization ID batching. */
export type CommonOrganizationSummary = Pick<
    mjBizAppsCommonOrganizationEntity,
    | 'ID'
    | 'Name'
    | 'LegalName'
    | 'OrganizationTypeID'
    | 'OrganizationType'
    | 'ParentID'
    | 'RootParentID'
    | 'Website'
    | 'LogoURL'
    | 'Email'
    | 'Phone'
    | 'Status'
    | 'LinkedCompanyID'
>;

/** Options accepted by incremental `People` / `Organizations` ID lookup methods. */
export interface CommonLookupOptions {
    /** Bypass the bounded ID cache and re-read the requested IDs from the provider. */
    forceRefresh?: boolean;
    /** Calling user context (required on server providers; used for persona-switch isolation). */
    contextUser?: UserInfo;
    /** Optional metadata/RunView provider override (defaults to `CommonEngine.ProviderToUse`). */
    provider?: IMetadataProvider;
}

const PERSON_SUMMARY_FIELDS: ReadonlyArray<keyof CommonPersonSummary> = [
    'ID',
    'DisplayName',
    'FirstName',
    'LastName',
    'Title',
    'Email',
    'PrimaryEmail',
    'Phone',
    'PrimaryPhone',
    'PhotoURL',
    'Status',
    'CurrentOrganizationID',
    'CurrentOrganizationName',
    'CurrentJobTitle',
    'SupervisorPersonID',
    'SeniorityLevelID',
    'PrimaryJobFunctionID',
];

const ORGANIZATION_SUMMARY_FIELDS: ReadonlyArray<keyof CommonOrganizationSummary> = [
    'ID',
    'Name',
    'LegalName',
    'OrganizationTypeID',
    'OrganizationType',
    'ParentID',
    'RootParentID',
    'Website',
    'LogoURL',
    'Email',
    'Phone',
    'Status',
    'LinkedCompanyID',
];

/** Maximum number of Person or Organization summary records retained in the bounded ID cache. */
const MAX_BOUNDED_PARTY_CACHE_SIZE = 500;
/** Maximum IDs per SQL `IN (...)` predicate chunk inside a single `RunViews` batch. */
const ID_BATCH_CHUNK_SIZE = 200;

interface TaxonomyConfigSpec {
    PropertyName: string;
    EntityName: string;
    OrderBy: string;
}

const TAXONOMY_CONFIGS: ReadonlyArray<TaxonomyConfigSpec> = [
    { PropertyName: '_activityTypes', EntityName: COMMON_ENGINE_ENTITIES.ActivityTypes, OrderBy: 'Sequence ASC, Name ASC' },
    { PropertyName: '_addressTypes', EntityName: COMMON_ENGINE_ENTITIES.AddressTypes, OrderBy: 'DefaultRank ASC, Name ASC' },
    { PropertyName: '_consentPurposes', EntityName: COMMON_ENGINE_ENTITIES.ConsentPurposes, OrderBy: 'Sequence ASC, Name ASC' },
    { PropertyName: '_contactTypes', EntityName: COMMON_ENGINE_ENTITIES.ContactTypes, OrderBy: 'DisplayRank ASC, Name ASC' },
    { PropertyName: '_jobFunctions', EntityName: COMMON_ENGINE_ENTITIES.JobFunctions, OrderBy: 'Sequence ASC, Name ASC' },
    { PropertyName: '_organizationTypes', EntityName: COMMON_ENGINE_ENTITIES.OrganizationTypes, OrderBy: 'DisplayRank ASC, Name ASC' },
    { PropertyName: '_relationshipTypes', EntityName: COMMON_ENGINE_ENTITIES.RelationshipTypes, OrderBy: 'Name ASC' },
    { PropertyName: '_seniorityLevels', EntityName: COMMON_ENGINE_ENTITIES.SeniorityLevels, OrderBy: 'Sequence ASC, Name ASC' },
    { PropertyName: '_activitySyncProviderTypes', EntityName: COMMON_ENGINE_ENTITIES.ActivitySyncProviderTypes, OrderBy: 'Sequence ASC, Name ASC' },
];

function normalizeKey(value: string | null | undefined): string {
    return (value ?? '').trim().toLowerCase();
}

function chunkList<T>(items: readonly T[], size: number): T[][] {
    const chunks: T[][] = [];
    for (let i = 0; i < items.length; i += size) {
        chunks.push(items.slice(i, i + size));
    }
    return chunks;
}

function extractPrimaryKeyID(entity: BaseEntity | null | undefined): string | null {
    const pairs = entity?.PrimaryKey?.KeyValuePairs;
    if (!pairs || pairs.length === 0) {
        return null;
    }
    const idPair = pairs.find((pair) => pair.FieldName.toLowerCase() === 'id') ?? pairs[0];
    const value = idPair?.Value;
    return typeof value === 'string' && value.trim().length > 0 ? value : null;
}

function canUserReadEntity(
    provider: IMetadataProvider | null | undefined,
    entityName: string,
    user: UserInfo | undefined,
): boolean {
    if (!provider || typeof provider.EntityByName !== 'function') {
        return true;
    }
    const entityInfo: EntityInfo | undefined = provider.EntityByName(entityName);
    if (!entityInfo) {
        return false;
    }
    if (!user || typeof entityInfo.GetUserPermisions !== 'function') {
        return true;
    }
    return entityInfo.GetUserPermisions(user)?.CanRead !== false;
}

export class CommonEngine extends BaseEngine<CommonEngine> {
    // Backing properties populated by BaseEngine.Load
    private _activityTypes: mjBizAppsCommonActivityTypeEntity[] = [];
    private _addressTypes: mjBizAppsCommonAddressTypeEntity[] = [];
    private _consentPurposes: mjBizAppsCommonConsentPurposeEntity[] = [];
    private _contactTypes: mjBizAppsCommonContactTypeEntity[] = [];
    private _jobFunctions: mjBizAppsCommonJobFunctionEntity[] = [];
    private _organizationTypes: mjBizAppsCommonOrganizationTypeEntity[] = [];
    private _relationshipTypes: mjBizAppsCommonRelationshipTypeEntity[] = [];
    private _seniorityLevels: mjBizAppsCommonSeniorityLevelEntity[] = [];
    private _activitySyncProviderTypes: mjBizAppsCommonActivitySyncProviderTypeEntity[] = [];

    // O(1) taxonomy lookup maps rebuilt on every reload in AdditionalLoading
    private _activityTypesByID = new Map<string, mjBizAppsCommonActivityTypeEntity>();
    private _activityTypesByCode = new Map<string, mjBizAppsCommonActivityTypeEntity>();
    private _activityTypesByName = new Map<string, mjBizAppsCommonActivityTypeEntity>();
    private _addressTypesByID = new Map<string, mjBizAppsCommonAddressTypeEntity>();
    private _addressTypesByName = new Map<string, mjBizAppsCommonAddressTypeEntity>();
    private _consentPurposesByID = new Map<string, mjBizAppsCommonConsentPurposeEntity>();
    private _consentPurposesByName = new Map<string, mjBizAppsCommonConsentPurposeEntity>();
    private _contactTypesByID = new Map<string, mjBizAppsCommonContactTypeEntity>();
    private _contactTypesByName = new Map<string, mjBizAppsCommonContactTypeEntity>();
    private _jobFunctionsByID = new Map<string, mjBizAppsCommonJobFunctionEntity>();
    private _jobFunctionsByName = new Map<string, mjBizAppsCommonJobFunctionEntity>();
    private _organizationTypesByID = new Map<string, mjBizAppsCommonOrganizationTypeEntity>();
    private _organizationTypesByName = new Map<string, mjBizAppsCommonOrganizationTypeEntity>();
    private _relationshipTypesByID = new Map<string, mjBizAppsCommonRelationshipTypeEntity>();
    private _relationshipTypesByName = new Map<string, mjBizAppsCommonRelationshipTypeEntity>();
    private _seniorityLevelsByID = new Map<string, mjBizAppsCommonSeniorityLevelEntity>();
    private _seniorityLevelsByName = new Map<string, mjBizAppsCommonSeniorityLevelEntity>();
    private _activitySyncProviderTypesByID = new Map<string, mjBizAppsCommonActivitySyncProviderTypeEntity>();
    private _activitySyncProviderTypesByCode = new Map<string, mjBizAppsCommonActivitySyncProviderTypeEntity>();

    // Bounded incremental ID-keyed caches (NEVER global unbounded list caches)
    private _peopleByID = new Map<string, CommonPersonSummary>();
    private _organizationsByID = new Map<string, CommonOrganizationSummary>();

    // Multi-provider & impersonation tracking
    private _explicitProvider: IMetadataProvider | null = null;
    private _configuredProvider: IMetadataProvider | null = null;
    private _configuredUserID: string | null = null;
    private _partyCacheProvider: IMetadataProvider | null = null;
    private _partyCacheUserID: string | null = null;

    public static get Instance(): CommonEngine {
        return super.getInstance<CommonEngine>();
    }

    /**
     * Active provider follows an explicitly passed provider when configured with one,
     * otherwise tracks the current ambient `Metadata.Provider`.
     */
    public override get ProviderToUse(): IMetadataProvider {
        return this._explicitProvider ?? Metadata.Provider ?? super.ProviderToUse;
    }

    /**
     * Loads all readable bounded Common taxonomy tables in a single batched `BaseEngine.Load`.
     * Automatically detects provider switches and `userId` (impersonation) switches, evicting
     * per-user bounded caches and refreshing permission-gated configs.
     */
    public async Config(forceRefresh?: boolean, contextUser?: UserInfo, provider?: IMetadataProvider): Promise<void> {
        const targetProvider = provider ?? Metadata.Provider;
        const targetUser = contextUser ?? targetProvider?.CurrentUser;
        const targetUserID = targetUser?.ID ? NormalizeUUID(targetUser.ID) : null;

        const hasPriorConfig = this._configuredProvider !== null;
        const providerChanged = hasPriorConfig && targetProvider !== this._configuredProvider;
        const userChanged = hasPriorConfig && !UUIDsEqual(this._configuredUserID, targetUserID);

        if (providerChanged || userChanged) {
            this.InvalidateAllPartyCaches();
        }

        this._explicitProvider = provider ?? null;
        const shouldForceRefresh = Boolean(forceRefresh) || providerChanged || userChanged;
        const configs = this.buildReadableTaxonomyConfigs(targetProvider, targetUser);

        // Reset backing arrays for any taxonomy entity the current persona cannot read
        this.clearUnreadTaxonomyProperties(configs);

        await this.Load(configs, targetProvider, shouldForceRefresh, targetUser);

        this._configuredProvider = targetProvider ?? null;
        this._configuredUserID = targetUserID;
    }

    /**
     * Rebuilds all O(1) lookup maps from the loaded taxonomy arrays on initial load and
     * after every `BaseEngine` refresh.
     */
    protected override async AdditionalLoading(_contextUser?: UserInfo): Promise<void> {
        this.rebuildLookupMaps();
    }

    /**
     * Invalidates bounded `People` / `Organizations` ID cache entries immediately when matching
     * `BaseEntity` save/delete/remote-invalidate events occur, then delegates to `BaseEngine`
     * for taxonomy `AutoRefresh`.
     */
    protected override async HandleIndividualBaseEntityEvent(event: BaseEntityEvent): Promise<boolean> {
        this.handlePartyInvalidationEvent(event);
        return super.HandleIndividualBaseEntityEvent(event);
    }

    // -------------------------------------------------------------------------
    // Taxonomy collections (all records & active-only helpers)
    // -------------------------------------------------------------------------

    public get ActivityTypes(): mjBizAppsCommonActivityTypeEntity[] {
        return this.readConfigArray<mjBizAppsCommonActivityTypeEntity>('_activityTypes', this._activityTypes);
    }

    public get ActiveActivityTypes(): mjBizAppsCommonActivityTypeEntity[] {
        return this.ActivityTypes.filter((t) => t.IsActive);
    }

    public get AddressTypes(): mjBizAppsCommonAddressTypeEntity[] {
        return this.readConfigArray<mjBizAppsCommonAddressTypeEntity>('_addressTypes', this._addressTypes);
    }

    public get ActiveAddressTypes(): mjBizAppsCommonAddressTypeEntity[] {
        return this.AddressTypes.filter((t) => t.IsActive);
    }

    public get ConsentPurposes(): mjBizAppsCommonConsentPurposeEntity[] {
        return this.readConfigArray<mjBizAppsCommonConsentPurposeEntity>('_consentPurposes', this._consentPurposes);
    }

    public get ActiveConsentPurposes(): mjBizAppsCommonConsentPurposeEntity[] {
        return this.ConsentPurposes.filter((p) => p.IsActive);
    }

    public get ContactTypes(): mjBizAppsCommonContactTypeEntity[] {
        return this.readConfigArray<mjBizAppsCommonContactTypeEntity>('_contactTypes', this._contactTypes);
    }

    public get ActiveContactTypes(): mjBizAppsCommonContactTypeEntity[] {
        return this.ContactTypes.filter((t) => t.IsActive);
    }

    public get JobFunctions(): mjBizAppsCommonJobFunctionEntity[] {
        return this.readConfigArray<mjBizAppsCommonJobFunctionEntity>('_jobFunctions', this._jobFunctions);
    }

    public get ActiveJobFunctions(): mjBizAppsCommonJobFunctionEntity[] {
        return this.JobFunctions.filter((f) => f.Status === 'Active');
    }

    public get OrganizationTypes(): mjBizAppsCommonOrganizationTypeEntity[] {
        return this.readConfigArray<mjBizAppsCommonOrganizationTypeEntity>('_organizationTypes', this._organizationTypes);
    }

    public get ActiveOrganizationTypes(): mjBizAppsCommonOrganizationTypeEntity[] {
        return this.OrganizationTypes.filter((t) => t.IsActive);
    }

    public get RelationshipTypes(): mjBizAppsCommonRelationshipTypeEntity[] {
        return this.readConfigArray<mjBizAppsCommonRelationshipTypeEntity>('_relationshipTypes', this._relationshipTypes);
    }

    public get ActiveRelationshipTypes(): mjBizAppsCommonRelationshipTypeEntity[] {
        return this.RelationshipTypes.filter((t) => t.IsActive);
    }

    public get SeniorityLevels(): mjBizAppsCommonSeniorityLevelEntity[] {
        return this.readConfigArray<mjBizAppsCommonSeniorityLevelEntity>('_seniorityLevels', this._seniorityLevels);
    }

    public get ActiveSeniorityLevels(): mjBizAppsCommonSeniorityLevelEntity[] {
        return this.SeniorityLevels.filter((s) => s.Status === 'Active');
    }

    public get ActivitySyncProviderTypes(): mjBizAppsCommonActivitySyncProviderTypeEntity[] {
        return this.readConfigArray<mjBizAppsCommonActivitySyncProviderTypeEntity>(
            '_activitySyncProviderTypes',
            this._activitySyncProviderTypes,
        );
    }

    public get ActiveActivitySyncProviderTypes(): mjBizAppsCommonActivitySyncProviderTypeEntity[] {
        return this.ActivitySyncProviderTypes.filter((t) => t.IsActive);
    }

    // -------------------------------------------------------------------------
    // O(1) Taxonomy lookup methods
    // -------------------------------------------------------------------------

    public GetActivityTypeByID(id: string | null | undefined): mjBizAppsCommonActivityTypeEntity | undefined {
        return id ? this._activityTypesByID.get(NormalizeUUID(id)) : undefined;
    }

    public GetActivityTypeByCode(code: string | null | undefined): mjBizAppsCommonActivityTypeEntity | undefined {
        return code ? this._activityTypesByCode.get(normalizeKey(code)) : undefined;
    }

    public GetActivityTypeByName(name: string | null | undefined): mjBizAppsCommonActivityTypeEntity | undefined {
        return name ? this._activityTypesByName.get(normalizeKey(name)) : undefined;
    }

    public GetAddressTypeByID(id: string | null | undefined): mjBizAppsCommonAddressTypeEntity | undefined {
        return id ? this._addressTypesByID.get(NormalizeUUID(id)) : undefined;
    }

    public GetAddressTypeByName(name: string | null | undefined): mjBizAppsCommonAddressTypeEntity | undefined {
        return name ? this._addressTypesByName.get(normalizeKey(name)) : undefined;
    }

    public GetConsentPurposeByID(id: string | null | undefined): mjBizAppsCommonConsentPurposeEntity | undefined {
        return id ? this._consentPurposesByID.get(NormalizeUUID(id)) : undefined;
    }

    public GetConsentPurposeByName(name: string | null | undefined): mjBizAppsCommonConsentPurposeEntity | undefined {
        return name ? this._consentPurposesByName.get(normalizeKey(name)) : undefined;
    }

    public GetContactTypeByID(id: string | null | undefined): mjBizAppsCommonContactTypeEntity | undefined {
        return id ? this._contactTypesByID.get(NormalizeUUID(id)) : undefined;
    }

    public GetContactTypeByName(name: string | null | undefined): mjBizAppsCommonContactTypeEntity | undefined {
        return name ? this._contactTypesByName.get(normalizeKey(name)) : undefined;
    }

    public GetJobFunctionByID(id: string | null | undefined): mjBizAppsCommonJobFunctionEntity | undefined {
        return id ? this._jobFunctionsByID.get(NormalizeUUID(id)) : undefined;
    }

    public GetJobFunctionByName(name: string | null | undefined): mjBizAppsCommonJobFunctionEntity | undefined {
        return name ? this._jobFunctionsByName.get(normalizeKey(name)) : undefined;
    }

    public GetOrganizationTypeByID(id: string | null | undefined): mjBizAppsCommonOrganizationTypeEntity | undefined {
        return id ? this._organizationTypesByID.get(NormalizeUUID(id)) : undefined;
    }

    public GetOrganizationTypeByName(name: string | null | undefined): mjBizAppsCommonOrganizationTypeEntity | undefined {
        return name ? this._organizationTypesByName.get(normalizeKey(name)) : undefined;
    }

    public GetRelationshipTypeByID(id: string | null | undefined): mjBizAppsCommonRelationshipTypeEntity | undefined {
        return id ? this._relationshipTypesByID.get(NormalizeUUID(id)) : undefined;
    }

    public GetRelationshipTypeByName(name: string | null | undefined): mjBizAppsCommonRelationshipTypeEntity | undefined {
        return name ? this._relationshipTypesByName.get(normalizeKey(name)) : undefined;
    }

    public GetSeniorityLevelByID(id: string | null | undefined): mjBizAppsCommonSeniorityLevelEntity | undefined {
        return id ? this._seniorityLevelsByID.get(NormalizeUUID(id)) : undefined;
    }

    public GetSeniorityLevelByName(name: string | null | undefined): mjBizAppsCommonSeniorityLevelEntity | undefined {
        return name ? this._seniorityLevelsByName.get(normalizeKey(name)) : undefined;
    }

    public GetActivitySyncProviderTypeByID(id: string | null | undefined): mjBizAppsCommonActivitySyncProviderTypeEntity | undefined {
        return id ? this._activitySyncProviderTypesByID.get(NormalizeUUID(id)) : undefined;
    }

    public GetActivitySyncProviderTypeByCode(code: string | null | undefined): mjBizAppsCommonActivitySyncProviderTypeEntity | undefined {
        return code ? this._activitySyncProviderTypesByCode.get(normalizeKey(code)) : undefined;
    }

    // -------------------------------------------------------------------------
    // Incremental bounded ID-keyed batching for People & Organizations
    // -------------------------------------------------------------------------

    /**
     * Fetches `People` summaries by ID using an incremental bounded cache.
     * Only IDs absent from the cache (or all IDs when `forceRefresh: true`) are queried,
     * in a single batched `RunViews` request with `ResultType: 'simple'`, narrow `Fields`,
     * and `CacheLocal: false`. Automatically evicts on provider or `userId` change.
     */
    public async GetPeopleByIDs(
        ids: readonly string[],
        options: CommonLookupOptions = {},
    ): Promise<Map<string, CommonPersonSummary>> {
        const provider = options.provider ?? this.ProviderToUse;
        const user = options.contextUser ?? provider?.CurrentUser;
        this.ensurePartyCacheContext(provider, user);
        await this.SetupGlobalEventListener();

        const normalizedIDs = this.normalizeValidIDs(ids);
        const result = new Map<string, CommonPersonSummary>();
        if (normalizedIDs.length === 0) {
            return result;
        }
        if (!canUserReadEntity(provider, COMMON_ENGINE_ENTITIES.People, user)) {
            return result;
        }

        const missing: string[] = [];
        for (const key of normalizedIDs) {
            const cached = options.forceRefresh ? undefined : this._peopleByID.get(key);
            if (cached) {
                result.set(key, cached);
            } else {
                missing.push(key);
            }
        }

        if (missing.length > 0) {
            const fetched = await this.fetchByIDChunks<CommonPersonSummary>(
                COMMON_ENGINE_ENTITIES.People,
                missing,
                PERSON_SUMMARY_FIELDS,
                provider,
                user,
            );
            for (const row of fetched) {
                const key = NormalizeUUID(row.ID);
                this.setBoundedCacheEntry(this._peopleByID, key, row);
                result.set(key, row);
            }
        }

        return result;
    }

    /** Convenience single-record lookup backed by {@link GetPeopleByIDs}. */
    public async GetPersonByID(
        id: string,
        options: CommonLookupOptions = {},
    ): Promise<CommonPersonSummary | null> {
        if (!IsValidUUID(id)) {
            return null;
        }
        const map = await this.GetPeopleByIDs([id], options);
        return map.get(NormalizeUUID(id)) ?? null;
    }

    /** Synchronous peek at the bounded Person ID cache without triggering a network read. */
    public GetCachedPersonByID(id: string | null | undefined): CommonPersonSummary | null {
        return id ? (this._peopleByID.get(NormalizeUUID(id)) ?? null) : null;
    }

    /**
     * Fetches `Organizations` summaries by ID using an incremental bounded cache.
     * Only IDs absent from the cache (or all IDs when `forceRefresh: true`) are queried,
     * in a single batched `RunViews` request with `ResultType: 'simple'`, narrow `Fields`,
     * and `CacheLocal: false`. Automatically evicts on provider or `userId` change.
     */
    public async GetOrganizationsByIDs(
        ids: readonly string[],
        options: CommonLookupOptions = {},
    ): Promise<Map<string, CommonOrganizationSummary>> {
        const provider = options.provider ?? this.ProviderToUse;
        const user = options.contextUser ?? provider?.CurrentUser;
        this.ensurePartyCacheContext(provider, user);
        await this.SetupGlobalEventListener();

        const normalizedIDs = this.normalizeValidIDs(ids);
        const result = new Map<string, CommonOrganizationSummary>();
        if (normalizedIDs.length === 0) {
            return result;
        }
        if (!canUserReadEntity(provider, COMMON_ENGINE_ENTITIES.Organizations, user)) {
            return result;
        }

        const missing: string[] = [];
        for (const key of normalizedIDs) {
            const cached = options.forceRefresh ? undefined : this._organizationsByID.get(key);
            if (cached) {
                result.set(key, cached);
            } else {
                missing.push(key);
            }
        }

        if (missing.length > 0) {
            const fetched = await this.fetchByIDChunks<CommonOrganizationSummary>(
                COMMON_ENGINE_ENTITIES.Organizations,
                missing,
                ORGANIZATION_SUMMARY_FIELDS,
                provider,
                user,
            );
            for (const row of fetched) {
                const key = NormalizeUUID(row.ID);
                this.setBoundedCacheEntry(this._organizationsByID, key, row);
                result.set(key, row);
            }
        }

        return result;
    }

    /** Convenience single-record lookup backed by {@link GetOrganizationsByIDs}. */
    public async GetOrganizationByID(
        id: string,
        options: CommonLookupOptions = {},
    ): Promise<CommonOrganizationSummary | null> {
        if (!IsValidUUID(id)) {
            return null;
        }
        const map = await this.GetOrganizationsByIDs([id], options);
        return map.get(NormalizeUUID(id)) ?? null;
    }

    /** Synchronous peek at the bounded Organization ID cache without triggering a network read. */
    public GetCachedOrganizationByID(id: string | null | undefined): CommonOrganizationSummary | null {
        return id ? (this._organizationsByID.get(NormalizeUUID(id)) ?? null) : null;
    }

    // -------------------------------------------------------------------------
    // Explicit cache invalidation helpers
    // -------------------------------------------------------------------------

    /** Removes a single person from the bounded Person ID cache. */
    public InvalidatePerson(personID: string): void {
        if (personID) {
            this._peopleByID.delete(NormalizeUUID(personID));
        }
    }

    /** Removes the given people (or all cached people when omitted) from the bounded cache. */
    public InvalidatePeople(personIDs?: readonly string[]): void {
        if (!personIDs) {
            this._peopleByID.clear();
            return;
        }
        for (const id of personIDs) {
            this.InvalidatePerson(id);
        }
    }

    /** Removes a single organization from the bounded Organization ID cache. */
    public InvalidateOrganization(organizationID: string): void {
        if (organizationID) {
            this._organizationsByID.delete(NormalizeUUID(organizationID));
        }
    }

    /** Removes the given organizations (or all cached organizations when omitted) from the bounded cache. */
    public InvalidateOrganizations(organizationIDs?: readonly string[]): void {
        if (!organizationIDs) {
            this._organizationsByID.clear();
            return;
        }
        for (const id of organizationIDs) {
            this.InvalidateOrganization(id);
        }
    }

    /** Clears all bounded per-user party caches (`People` and `Organizations`). */
    public InvalidateAllPartyCaches(): void {
        this._peopleByID.clear();
        this._organizationsByID.clear();
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    private buildReadableTaxonomyConfigs(
        provider: IMetadataProvider | null | undefined,
        user: UserInfo | undefined,
    ): Array<Partial<BaseEnginePropertyConfig>> {
        const configs: Array<Partial<BaseEnginePropertyConfig>> = [];
        for (const spec of TAXONOMY_CONFIGS) {
            if (!canUserReadEntity(provider, spec.EntityName, user)) {
                continue;
            }
            configs.push({
                PropertyName: spec.PropertyName,
                EntityName: spec.EntityName,
                OrderBy: spec.OrderBy,
                AutoRefresh: true,
                CacheLocal: false,
            });
        }
        return configs;
    }

    private clearUnreadTaxonomyProperties(activeConfigs: ReadonlyArray<Partial<BaseEnginePropertyConfig>>): void {
        const activeNames = new Set(activeConfigs.map((c) => c.PropertyName));
        if (!activeNames.has('_activityTypes')) this._activityTypes = [];
        if (!activeNames.has('_addressTypes')) this._addressTypes = [];
        if (!activeNames.has('_consentPurposes')) this._consentPurposes = [];
        if (!activeNames.has('_contactTypes')) this._contactTypes = [];
        if (!activeNames.has('_jobFunctions')) this._jobFunctions = [];
        if (!activeNames.has('_organizationTypes')) this._organizationTypes = [];
        if (!activeNames.has('_relationshipTypes')) this._relationshipTypes = [];
        if (!activeNames.has('_seniorityLevels')) this._seniorityLevels = [];
        if (!activeNames.has('_activitySyncProviderTypes')) this._activitySyncProviderTypes = [];
    }

    private readConfigArray<T>(propertyName: string, fallback: T[]): T[] {
        try {
            const data = this.GetConfigData<T>(propertyName);
            return Array.isArray(data) ? data : fallback;
        } catch {
            return fallback;
        }
    }

    private rebuildLookupMaps(): void {
        this._activityTypesByID.clear();
        this._activityTypesByCode.clear();
        this._activityTypesByName.clear();
        for (const row of this.ActivityTypes) {
            this._activityTypesByID.set(NormalizeUUID(row.ID), row);
            if (row.Code) this._activityTypesByCode.set(normalizeKey(row.Code), row);
            if (row.Name) this._activityTypesByName.set(normalizeKey(row.Name), row);
        }

        this._addressTypesByID.clear();
        this._addressTypesByName.clear();
        for (const row of this.AddressTypes) {
            this._addressTypesByID.set(NormalizeUUID(row.ID), row);
            if (row.Name) this._addressTypesByName.set(normalizeKey(row.Name), row);
        }

        this._consentPurposesByID.clear();
        this._consentPurposesByName.clear();
        for (const row of this.ConsentPurposes) {
            this._consentPurposesByID.set(NormalizeUUID(row.ID), row);
            if (row.Name) this._consentPurposesByName.set(normalizeKey(row.Name), row);
        }

        this._contactTypesByID.clear();
        this._contactTypesByName.clear();
        for (const row of this.ContactTypes) {
            this._contactTypesByID.set(NormalizeUUID(row.ID), row);
            if (row.Name) this._contactTypesByName.set(normalizeKey(row.Name), row);
        }

        this._jobFunctionsByID.clear();
        this._jobFunctionsByName.clear();
        for (const row of this.JobFunctions) {
            this._jobFunctionsByID.set(NormalizeUUID(row.ID), row);
            if (row.Name) this._jobFunctionsByName.set(normalizeKey(row.Name), row);
        }

        this._organizationTypesByID.clear();
        this._organizationTypesByName.clear();
        for (const row of this.OrganizationTypes) {
            this._organizationTypesByID.set(NormalizeUUID(row.ID), row);
            if (row.Name) this._organizationTypesByName.set(normalizeKey(row.Name), row);
        }

        this._relationshipTypesByID.clear();
        this._relationshipTypesByName.clear();
        for (const row of this.RelationshipTypes) {
            this._relationshipTypesByID.set(NormalizeUUID(row.ID), row);
            if (row.Name) this._relationshipTypesByName.set(normalizeKey(row.Name), row);
        }

        this._seniorityLevelsByID.clear();
        this._seniorityLevelsByName.clear();
        for (const row of this.SeniorityLevels) {
            this._seniorityLevelsByID.set(NormalizeUUID(row.ID), row);
            if (row.Name) this._seniorityLevelsByName.set(normalizeKey(row.Name), row);
        }

        this._activitySyncProviderTypesByID.clear();
        this._activitySyncProviderTypesByCode.clear();
        for (const row of this.ActivitySyncProviderTypes) {
            this._activitySyncProviderTypesByID.set(NormalizeUUID(row.ID), row);
            if (row.Code) this._activitySyncProviderTypesByCode.set(normalizeKey(row.Code), row);
        }
    }

    private ensurePartyCacheContext(
        provider: IMetadataProvider | null | undefined,
        user: UserInfo | undefined,
    ): void {
        const nextProvider = provider ?? null;
        const nextUserID = user?.ID ? NormalizeUUID(user.ID) : null;
        const hasPriorContext = this._partyCacheProvider !== null || this._partyCacheUserID !== null;
        const providerChanged = this._partyCacheProvider !== null && nextProvider !== this._partyCacheProvider;
        const userChanged = hasPriorContext && !UUIDsEqual(this._partyCacheUserID, nextUserID);

        if (providerChanged || userChanged) {
            this.InvalidateAllPartyCaches();
        }
        this._partyCacheProvider = nextProvider;
        this._partyCacheUserID = nextUserID;
    }

    private normalizeValidIDs(ids: readonly string[]): string[] {
        const seen = new Set<string>();
        const normalized: string[] = [];
        for (const id of ids) {
            if (!id || !IsValidUUID(id)) {
                continue;
            }
            const key = NormalizeUUID(id);
            if (!seen.has(key)) {
                seen.add(key);
                normalized.push(key);
            }
        }
        return normalized;
    }

    private async fetchByIDChunks<T>(
        entityName: string,
        normalizedIDs: readonly string[],
        fields: ReadonlyArray<string>,
        provider: IMetadataProvider,
        user: UserInfo | undefined,
    ): Promise<T[]> {
        const chunks = chunkList(normalizedIDs, ID_BATCH_CHUNK_SIZE);
        const requests: RunViewParams[] = chunks.map((chunk) => ({
            EntityName: entityName,
            ExtraFilter: `ID IN (${chunk.map((id) => `'${EscapeSQLString(id)}'`).join(',')})`,
            Fields: [...fields],
            ResultType: 'simple',
            CacheLocal: false,
        }));

        const rv = RunView.FromMetadataProvider(provider);
        const results = await rv.RunViews(requests, user);
        const rows: T[] = [];
        for (const res of results) {
            if (!res?.Success) {
                LogError(`CommonEngine: batch lookup for '${entityName}' failed: ${res?.ErrorMessage ?? 'unknown error'}`);
                continue;
            }
            if (Array.isArray(res.Results)) {
                rows.push(...(res.Results as T[]));
            }
        }
        return rows;
    }

    private setBoundedCacheEntry<T>(cache: Map<string, T>, normalizedKey: string, value: T): void {
        // Refresh insertion order for FIFO/LRU-style eviction
        if (cache.has(normalizedKey)) {
            cache.delete(normalizedKey);
        }
        cache.set(normalizedKey, value);
        while (cache.size > MAX_BOUNDED_PARTY_CACHE_SIZE) {
            const oldestKey = cache.keys().next().value;
            if (oldestKey === undefined) {
                break;
            }
            cache.delete(oldestKey);
        }
    }

    private handlePartyInvalidationEvent(event: BaseEntityEvent): void {
        if (event.type !== 'save' && event.type !== 'delete' && event.type !== 'remote-invalidate') {
            return;
        }
        const entityName = normalizeKey(event.baseEntity?.EntityInfo?.Name);
        if (!entityName) {
            return;
        }

        if (entityName === normalizeKey(COMMON_ENGINE_ENTITIES.People)) {
            const id = extractPrimaryKeyID(event.baseEntity);
            if (id) {
                this.InvalidatePerson(id);
            } else {
                this.InvalidatePeople();
            }
            return;
        }

        if (entityName === normalizeKey(COMMON_ENGINE_ENTITIES.Organizations)) {
            const id = extractPrimaryKeyID(event.baseEntity);
            if (id) {
                this.InvalidateOrganization(id);
            } else {
                this.InvalidateOrganizations();
            }
            return;
        }

        if (entityName === normalizeKey(COMMON_ENGINE_ENTITIES.Relationships)) {
            if (event.baseEntity instanceof mjBizAppsCommonRelationshipEntity) {
                if (event.baseEntity.FromPersonID) this.InvalidatePerson(event.baseEntity.FromPersonID);
                if (event.baseEntity.ToPersonID) this.InvalidatePerson(event.baseEntity.ToPersonID);
            } else {
                // Unknown relationship payload shape — evict people cache safely
                this.InvalidatePeople();
            }
        }
    }
}
