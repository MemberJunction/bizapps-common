/**
 * Shared helpers for the write guards on the server-side entity subclasses.
 *
 * WHY THE GUARDS COMPARE AGAINST THE STORED ROW. A GraphQL update can be hydrated from the
 * client's own `OldValues___` instead of the database (MJ's `ResolverBase.UpdateRecord` does that
 * for an entity that tracks no record changes and has no field-level security). A client can then
 * make a changed column look unchanged, so a rule that asks "is this field dirty?" can be walked
 * past. A guard that reads the stored value and compares it with the value about to be written
 * does not depend on how the entity was hydrated.
 *
 * WHY `Save()` AND NOT `ValidateAsync()`. A caller can pass `SkipAsyncValidation` or `ReplayOnly`,
 * and both skip validation. The guards run in `Save()` before the base save, so no save option
 * reaches the database without them.
 */
import {
    BaseEntity,
    BaseEntityResult,
    CompositeKey,
    RunView,
    type EntityInfo,
    type IEntityDataProvider,
    type IMetadataProvider,
    type UserInfo,
} from '@memberjunction/core';
import { UUIDsEqual } from '@memberjunction/global';

/** The MJ System user. Server-internal work runs as this user; no person signs in as it. */
export const SYSTEM_USER_ID = 'ECAFCCEC-6A37-EF11-86D4-000D3A4E707E';

/** True for an Owner-type user, MJ's administrator. */
export function IsOwnerUser(user: UserInfo | null | undefined): boolean {
    return user?.Type?.trim().toLowerCase() === 'owner';
}

/** True for the MJ System user. */
export function IsSystemUser(user: UserInfo | null | undefined): boolean {
    return !!user && UUIDsEqual(user.ID, SYSTEM_USER_ID);
}

/**
 * Records a refused save on the entity's result history, so `LatestResult.CompleteMessage` (what
 * the GraphQL resolver hands the client) carries the reason, and returns false.
 */
export function RefuseSave(entity: BaseEntity, message: string): boolean {
    const result = new BaseEntityResult();
    result.Success = false;
    result.Type = entity.IsSaved ? 'update' : 'create';
    result.Message = message;
    result.StartedAt = new Date();
    result.EndedAt = new Date();
    entity.RegisterResultHistoryEntry(result);
    return false;
}

/** Narrows the entity's data provider to the metadata provider it also is on the server. */
function isMetadataProvider(provider: IEntityDataProvider | IMetadataProvider): provider is IMetadataProvider {
    return 'Entities' in provider && Array.isArray(provider.Entities);
}

/** The metadata of the provider this entity saves through, or null when it carries none. */
export function MetadataOf(entity: BaseEntity): IMetadataProvider | null {
    const provider = entity.ProviderToUse;
    return provider && isMetadataProvider(provider) ? provider : null;
}

/** One row read back as plain values, keyed by field name. */
export type StoredValues = Record<string, unknown>;

/**
 * Reads the stored values of `fields` for the row a key names, as `user`, through the entity's own
 * provider (so a save inside an entity transaction reads inside it). Returns null when the row is
 * missing, the user cannot read it, or the read fails: every caller treats that as a refusal.
 */
export async function ReadStoredRow(
    entity: BaseEntity,
    entityInfo: EntityInfo,
    key: CompositeKey,
    fields: readonly string[],
    user: UserInfo,
): Promise<StoredValues | null> {
    const rv = new RunView(entity.RunViewProviderToUse);
    const result = await rv.RunView<StoredValues>(
        {
            EntityName: entityInfo.Name,
            ExtraFilter: key.ToWhereClause(),
            Fields: [...fields],
            MaxRows: 1,
            ResultType: 'simple',
        },
        user,
    );
    if (!result.Success || result.Results.length !== 1) return null;
    return result.Results[0];
}

/** Reads this entity's own stored row (see {@link ReadStoredRow}). */
export function ReadOwnStoredRow(
    entity: BaseEntity,
    fields: readonly string[],
    user: UserInfo,
): Promise<StoredValues | null> {
    return ReadStoredRow(entity, entity.EntityInfo, entity.PrimaryKey, fields, user);
}

/** Null, undefined and blank strings are the same "no value". */
export function NormalizeStored(value: unknown): string | null {
    if (value === null || value === undefined) return null;
    if (value instanceof Date) return value.toISOString();
    const text = String(value).trim();
    return text === '' ? null : text;
}
