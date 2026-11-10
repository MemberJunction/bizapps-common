import { ActionParam, ActionResultSimple, RunActionParams } from '@memberjunction/actions-base';
import { BaseAction } from '@memberjunction/actions';
import {
    DatabaseProviderBase,
    EntityInfo,
    IMetadataProvider,
    LogError,
    Metadata,
    RunView,
    UserInfo,
} from '@memberjunction/core';
import { RegisterClass, UUIDsEqual } from '@memberjunction/global';
import {
    AddressesMatch,
    FindMatchingLinkedAddress,
    HasMinimumAddressContent,
    LinksToDemoteFromPrimary,
    NormalizeAddressFields,
    ResolveAddressType,
    ResolveDefaultIsPrimary,
    mjBizAppsCommonAddressEntity,
    mjBizAppsCommonAddressLinkEntity,
    mjBizAppsCommonAddressTypeEntity,
    type LinkedAddressPair,
} from '@mj-biz-apps/common-entities';

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const CANONICAL_PEOPLE_ENTITY = 'MJ_BizApps_Common: People';
const CANONICAL_ORGANIZATIONS_ENTITY = 'MJ_BizApps_Common: Organizations';
const ADDRESSES_ENTITY = 'MJ_BizApps_Common: Addresses';
const ADDRESS_LINKS_ENTITY = 'MJ_BizApps_Common: Address Links';
const ADDRESS_TYPES_ENTITY = 'MJ_BizApps_Common: Address Types';

type SupportedTargetEntity = typeof CANONICAL_PEOPLE_ENTITY | typeof CANONICAL_ORGANIZATIONS_ENTITY;

function isIndependentDatabaseProvider(
    provider: IMetadataProvider | null | undefined,
): provider is DatabaseProviderBase {
    return (
        Boolean(provider) &&
        'BeginEntityTransaction' in (provider as DatabaseProviderBase) &&
        typeof (provider as DatabaseProviderBase).BeginEntityTransaction === 'function' &&
        'CreateIndependentInstance' in (provider as DatabaseProviderBase) &&
        typeof (provider as DatabaseProviderBase).CreateIndependentInstance === 'function'
    );
}

function resolveTargetEntityName(raw: string | null): SupportedTargetEntity | null {
    if (!raw) return null;
    const trimmed = raw.trim();
    switch (trimmed) {
        case 'People':
        case CANONICAL_PEOPLE_ENTITY:
        case 'MJ.BizApps.Common: People':
            return CANONICAL_PEOPLE_ENTITY;
        case 'Organizations':
        case CANONICAL_ORGANIZATIONS_ENTITY:
        case 'MJ.BizApps.Common: Organizations':
            return CANONICAL_ORGANIZATIONS_ENTITY;
        default:
            return null;
    }
}

/**
 * Attaches a physical or mailing address (`MJ_BizApps_Common: Addresses` +
 * `MJ_BizApps_Common: Address Links`) to a Person or Organization record in a
 * single transaction on an isolated provider instance.
 *
 * Implements the rules in `@mj-biz-apps/common-entities` (`address-link-rules.ts`):
 * - Trims and normalizes address fields (`Country` defaults to `'US'`).
 * - Requires at least one of `Line1`, `City`, or `PostalCode`.
 * - Resolves `AddressTypeID` to an active `AddressType` (falling back to the active type with the
 *   lowest `DefaultRank` when omitted).
 * - Deduplicates against addresses already linked to the same `(EntityID, RecordID)` so existing
 *   links are reused rather than creating duplicate `Address` or `AddressLink` rows.
 * - Defaults `IsPrimary = true` only when the record has no existing links at all, and demotes any
 *   prior primary link on the same `(EntityID, RecordID)` when the new/updated link is primary.
 */
@RegisterClass(BaseAction, 'Common.AttachAddress')
export class AttachAddressAction extends BaseAction {
    public static readonly AuthorizesCaller = true;

    protected override async InternalRunAction(params: RunActionParams): Promise<ActionResultSimple> {
        const contextUser = params.ContextUser;
        if (!contextUser) {
            return this.fail('VALIDATION_ERROR', 'Common.AttachAddress requires a ContextUser.');
        }

        const rawEntityName = this.readStringParam(params, 'EntityName');
        const canonicalEntityName = resolveTargetEntityName(rawEntityName);
        if (!canonicalEntityName) {
            return this.fail(
                'VALIDATION_ERROR',
                `EntityName is required and must be 'People', 'Organizations', '${CANONICAL_PEOPLE_ENTITY}', or '${CANONICAL_ORGANIZATIONS_ENTITY}'.`,
            );
        }

        const recordID = this.readStringParam(params, 'RecordID');
        if (!recordID || !UUID_PATTERN.test(recordID)) {
            return this.fail('VALIDATION_ERROR', 'RecordID is required and must be a valid UUID.');
        }

        const normalized = NormalizeAddressFields({
            Line1: this.readStringParam(params, 'Line1'),
            Line2: this.readStringParam(params, 'Line2'),
            Line3: this.readStringParam(params, 'Line3'),
            City: this.readStringParam(params, 'City'),
            StateProvince: this.readStringParam(params, 'StateProvince'),
            PostalCode: this.readStringParam(params, 'PostalCode'),
            Country: this.readStringParam(params, 'Country'),
        });

        if (!HasMinimumAddressContent(normalized)) {
            return this.fail(
                'VALIDATION_ERROR',
                'At least one of Line1, City, or PostalCode must be non-empty.',
            );
        }

        const latitude = this.readNumberParam(params, 'Latitude');
        if (latitude.Invalid || (latitude.Value !== null && (latitude.Value < -90 || latitude.Value > 90))) {
            return this.fail('VALIDATION_ERROR', 'Latitude must be a finite number between -90 and 90.');
        }

        const longitude = this.readNumberParam(params, 'Longitude');
        if (longitude.Invalid || (longitude.Value !== null && (longitude.Value < -180 || longitude.Value > 180))) {
            return this.fail('VALIDATION_ERROR', 'Longitude must be a finite number between -180 and 180.');
        }

        const rank = this.readNumberParam(params, 'Rank');
        if (rank.Invalid || (rank.Value !== null && (!Number.isInteger(rank.Value) || rank.Value < 0))) {
            return this.fail('VALIDATION_ERROR', 'Rank must be a non-negative integer when provided.');
        }

        const explicitIsPrimary = this.readBooleanParam(params, 'IsPrimary');
        if (explicitIsPrimary.Invalid) {
            return this.fail('VALIDATION_ERROR', 'IsPrimary must be a boolean when provided.');
        }

        const explicitAddressType =
            this.readStringParam(params, 'AddressTypeID') ?? this.readStringParam(params, 'AddressType');

        const shared = Metadata.Provider;
        if (!isIndependentDatabaseProvider(shared)) {
            const message =
                'Common.AttachAddress requires a database provider that supports independent instances and transactions.';
            LogError(`[Common.AttachAddress] ${message}`);
            return { Success: false, ResultCode: 'ERROR', Message: message };
        }

        const own = await shared.CreateIndependentInstance();
        try {
            return await this.attachOnProvider(own, contextUser, params, {
                canonicalEntityName,
                recordID,
                normalized,
                latitude: latitude.Value,
                longitude: longitude.Value,
                rank: rank.Value,
                explicitIsPrimary: explicitIsPrimary.Value,
                explicitAddressType,
            });
        } catch (err) {
            const detail = err instanceof Error ? err.message : String(err);
            LogError(
                `[Common.AttachAddress] Unexpected error attaching address to ${canonicalEntityName}/${recordID}: ${detail}`,
            );
            return { Success: false, ResultCode: 'ERROR', Message: `AttachAddress failed: ${detail}` };
        } finally {
            await own.ReleaseIndependentInstance();
        }
    }

    private async attachOnProvider(
        own: DatabaseProviderBase,
        contextUser: UserInfo,
        params: RunActionParams,
        input: {
            canonicalEntityName: SupportedTargetEntity;
            recordID: string;
            normalized: ReturnType<typeof NormalizeAddressFields>;
            latitude: number | null;
            longitude: number | null;
            rank: number | null;
            explicitIsPrimary: boolean | null;
            explicitAddressType: string | null;
        },
    ): Promise<ActionResultSimple> {
        const targetEntity: EntityInfo | undefined = own.Entities?.find(
            (e) => e.Name === input.canonicalEntityName,
        );
        if (!targetEntity) {
            return this.fail(
                'VALIDATION_ERROR',
                `Entity '${input.canonicalEntityName}' was not found in metadata.`,
            );
        }

        const perms = targetEntity.GetUserPermisions(contextUser);
        if (!perms?.CanUpdate) {
            return {
                Success: false,
                ResultCode: 'PERMISSION_DENIED',
                Message: `User does not have permission to update ${input.canonicalEntityName}.`,
            };
        }

        const rv = new RunView(own);

        // Verify target record exists and is accessible to contextUser.
        const targetCheck = await rv.RunView<{ ID: string }>(
            {
                EntityName: input.canonicalEntityName,
                ExtraFilter: `ID = '${input.recordID}'`,
                MaxRows: 1,
                ResultType: 'simple',
            },
            contextUser,
        );
        if (!targetCheck.Success) {
            return {
                Success: false,
                ResultCode: 'ERROR',
                Message: targetCheck.ErrorMessage || `Failed to verify ${input.canonicalEntityName} record.`,
            };
        }
        if (!targetCheck.Results || targetCheck.Results.length === 0) {
            return {
                Success: false,
                ResultCode: 'NOT_FOUND',
                Message: `${input.canonicalEntityName} record '${input.recordID}' was not found.`,
            };
        }

        // Load active AddressTypes and resolve AddressTypeID.
        const typesResult = await rv.RunView<mjBizAppsCommonAddressTypeEntity>(
            {
                EntityName: ADDRESS_TYPES_ENTITY,
                ExtraFilter: 'IsActive = 1',
                OrderBy: 'DefaultRank ASC, Name ASC',
                ResultType: 'simple',
            },
            contextUser,
        );
        if (!typesResult.Success) {
            return {
                Success: false,
                ResultCode: 'ERROR',
                Message: typesResult.ErrorMessage || 'Failed to load active Address Types.',
            };
        }

        const resolvedType = ResolveAddressType(typesResult.Results ?? [], input.explicitAddressType);
        if (!resolvedType) {
            return this.fail(
                'VALIDATION_ERROR',
                input.explicitAddressType
                    ? `AddressType '${input.explicitAddressType}' is not a valid active AddressType.`
                    : 'No active AddressType rows are configured.',
            );
        }

        // Load existing AddressLinks and their Addresses for this (EntityID, RecordID).
        const linksResult = await rv.RunView<mjBizAppsCommonAddressLinkEntity>(
            {
                EntityName: ADDRESS_LINKS_ENTITY,
                ExtraFilter: `EntityID = '${targetEntity.ID}' AND RecordID = '${input.recordID}'`,
                OrderBy: 'Rank ASC, __mj_CreatedAt ASC',
                ResultType: 'entity_object',
            },
            contextUser,
        );
        if (!linksResult.Success) {
            return {
                Success: false,
                ResultCode: 'ERROR',
                Message: linksResult.ErrorMessage || 'Failed to load existing Address Links.',
            };
        }

        const existingLinks = linksResult.Results ?? [];
        const existingAddressesByID = new Map<string, mjBizAppsCommonAddressEntity>();

        if (existingLinks.length > 0) {
            const uniqueAddressIDs = Array.from(
                new Set(
                    existingLinks
                        .map((l) => l.AddressID)
                        .filter((id): id is string => Boolean(id) && UUID_PATTERN.test(id)),
                ),
            );
            if (uniqueAddressIDs.length > 0) {
                const inClause = uniqueAddressIDs.map((id) => `'${id}'`).join(', ');
                const addrResult = await rv.RunView<mjBizAppsCommonAddressEntity>(
                    {
                        EntityName: ADDRESSES_ENTITY,
                        ExtraFilter: `ID IN (${inClause})`,
                        ResultType: 'entity_object',
                    },
                    contextUser,
                );
                if (!addrResult.Success) {
                    return {
                        Success: false,
                        ResultCode: 'ERROR',
                        Message: addrResult.ErrorMessage || 'Failed to load linked Addresses.',
                    };
                }
                for (const addr of addrResult.Results ?? []) {
                    existingAddressesByID.set(addr.ID.toLowerCase(), addr);
                }
            }
        }

        const existingPairs: LinkedAddressPair<mjBizAppsCommonAddressLinkEntity, mjBizAppsCommonAddressEntity>[] = [];
        for (const link of existingLinks) {
            const addr = existingAddressesByID.get(link.AddressID.toLowerCase());
            if (addr) {
                existingPairs.push({ Link: link, Address: addr });
            }
        }

        const scope = await own.BeginEntityTransaction();
        try {
            const matchedPair = FindMatchingLinkedAddress(existingPairs, input.normalized);
            let address: mjBizAppsCommonAddressEntity;
            let createdNewAddress = false;

            if (matchedPair) {
                address = matchedPair.Address;
                let coordsUpdated = false;
                if (input.latitude !== null && address.Latitude === null) {
                    address.Latitude = input.latitude;
                    coordsUpdated = true;
                }
                if (input.longitude !== null && address.Longitude === null) {
                    address.Longitude = input.longitude;
                    coordsUpdated = true;
                }
                if (coordsUpdated && !(await address.Save())) {
                    await scope.Rollback();
                    return {
                        Success: false,
                        ResultCode: 'ERROR',
                        Message: address.LatestResult?.CompleteMessage || 'Failed to update matched Address.',
                    };
                }
            } else {
                address = await own.GetEntityObject<mjBizAppsCommonAddressEntity>(
                    ADDRESSES_ENTITY,
                    contextUser,
                );
                address.NewRecord();
                address.Line1 = input.normalized.Line1;
                address.Line2 = input.normalized.Line2;
                address.Line3 = input.normalized.Line3;
                address.City = input.normalized.City;
                address.StateProvince = input.normalized.StateProvince;
                address.PostalCode = input.normalized.PostalCode;
                address.Country = input.normalized.Country;
                if (input.latitude !== null) {
                    address.Latitude = input.latitude;
                }
                if (input.longitude !== null) {
                    address.Longitude = input.longitude;
                }
                if (!(await address.Save())) {
                    await scope.Rollback();
                    return {
                        Success: false,
                        ResultCode: 'ERROR',
                        Message: address.LatestResult?.CompleteMessage || 'Failed to save new Address.',
                    };
                }
                createdNewAddress = true;
            }

            const existingSameTypeLink = existingLinks.find(
                (l) =>
                    (UUIDsEqual(l.AddressID, address.ID) ||
                        (existingAddressesByID.get(l.AddressID.toLowerCase()) !== undefined &&
                            AddressesMatch(
                                existingAddressesByID.get(l.AddressID.toLowerCase())!,
                                input.normalized,
                            ))) &&
                    UUIDsEqual(l.AddressTypeID, resolvedType.ID),
            );

            let link: mjBizAppsCommonAddressLinkEntity;
            let createdNewLink = false;

            if (existingSameTypeLink) {
                link = existingSameTypeLink;
                let linkUpdated = false;
                if (input.explicitIsPrimary !== null && link.IsPrimary !== input.explicitIsPrimary) {
                    link.IsPrimary = input.explicitIsPrimary;
                    linkUpdated = true;
                }
                if (input.rank !== null && link.Rank !== input.rank) {
                    link.Rank = input.rank;
                    linkUpdated = true;
                }
                if (linkUpdated && !(await link.Save())) {
                    await scope.Rollback();
                    return {
                        Success: false,
                        ResultCode: 'ERROR',
                        Message: link.LatestResult?.CompleteMessage || 'Failed to update existing AddressLink.',
                    };
                }
            } else {
                const effectiveIsPrimary = ResolveDefaultIsPrimary(
                    existingLinks,
                    resolvedType.ID,
                    input.explicitIsPrimary,
                );
                link = await own.GetEntityObject<mjBizAppsCommonAddressLinkEntity>(
                    ADDRESS_LINKS_ENTITY,
                    contextUser,
                );
                link.NewRecord();
                link.AddressID = address.ID;
                link.EntityID = targetEntity.ID;
                link.RecordID = input.recordID;
                link.AddressTypeID = resolvedType.ID;
                link.IsPrimary = effectiveIsPrimary;
                if (input.rank !== null) {
                    link.Rank = input.rank;
                }
                if (!(await link.Save())) {
                    await scope.Rollback();
                    return {
                        Success: false,
                        ResultCode: 'ERROR',
                        Message: link.LatestResult?.CompleteMessage || 'Failed to save new AddressLink.',
                    };
                }
                createdNewLink = true;
            }

            if (link.IsPrimary) {
                const toDemote = LinksToDemoteFromPrimary(existingLinks, link.ID);
                for (const demoteSummary of toDemote) {
                    const otherLink = existingLinks.find((l) => UUIDsEqual(l.ID, demoteSummary.ID));
                    if (!otherLink) continue;
                    otherLink.IsPrimary = false;
                    if (!(await otherLink.Save())) {
                        await scope.Rollback();
                        return {
                            Success: false,
                            ResultCode: 'ERROR',
                            Message:
                                otherLink.LatestResult?.CompleteMessage ||
                                'Failed to demote previous primary AddressLink.',
                        };
                    }
                }
            }

            await scope.Commit();

            this.setOutputParam(params, 'AddressID', address.ID);
            this.setOutputParam(params, 'AddressLinkID', link.ID);
            this.setOutputParam(params, 'CreatedNewAddress', createdNewAddress);
            this.setOutputParam(params, 'CreatedNewLink', createdNewLink);

            return {
                Success: true,
                ResultCode: 'SUCCESS',
                Message: createdNewAddress
                    ? 'Created new Address and AddressLink.'
                    : createdNewLink
                      ? 'Reused existing Address and created new AddressLink.'
                      : 'Matched existing Address and AddressLink.',
                Params: params.Params,
            };
        } catch (txErr) {
            try {
                await scope.Rollback();
            } catch (rollbackErr) {
                LogError(`[Common.AttachAddress] Rollback failed after "${txErr}": ${rollbackErr}`);
            }
            throw txErr;
        }
    }

    private fail(resultCode: string, message: string): ActionResultSimple {
        LogError(`[Common.AttachAddress] ${message}`);
        return { Success: false, ResultCode: resultCode, Message: message };
    }

    private findParam(params: RunActionParams, name: string): ActionParam | undefined {
        const lower = name.toLowerCase();
        return params.Params?.find((p) => p.Name.trim().toLowerCase() === lower);
    }

    private readStringParam(params: RunActionParams, name: string): string | null {
        const found = this.findParam(params, name);
        if (found?.Value === undefined || found.Value === null) return null;
        const trimmed = String(found.Value).trim();
        return trimmed.length > 0 ? trimmed : null;
    }

    private readNumberParam(
        params: RunActionParams,
        name: string,
    ): { Value: number | null; Invalid: boolean } {
        const found = this.findParam(params, name);
        if (found?.Value === undefined || found.Value === null || String(found.Value).trim() === '') {
            return { Value: null, Invalid: false };
        }
        const num = typeof found.Value === 'number' ? found.Value : Number(String(found.Value).trim());
        if (!Number.isFinite(num)) {
            return { Value: null, Invalid: true };
        }
        return { Value: num, Invalid: false };
    }

    private readBooleanParam(
        params: RunActionParams,
        name: string,
    ): { Value: boolean | null; Invalid: boolean } {
        const found = this.findParam(params, name);
        if (found?.Value === undefined || found.Value === null || String(found.Value).trim() === '') {
            return { Value: null, Invalid: false };
        }
        if (typeof found.Value === 'boolean') {
            return { Value: found.Value, Invalid: false };
        }
        const normalized = String(found.Value).trim().toLowerCase();
        if (normalized === 'true' || normalized === '1') {
            return { Value: true, Invalid: false };
        }
        if (normalized === 'false' || normalized === '0') {
            return { Value: false, Invalid: false };
        }
        return { Value: null, Invalid: true };
    }

    private setOutputParam(params: RunActionParams, name: string, value: string | boolean): void {
        if (!params.Params) {
            params.Params = [];
        }
        const lower = name.toLowerCase();
        const existing = params.Params.find((p) => p.Name.trim().toLowerCase() === lower);
        if (existing) {
            existing.Value = value;
            existing.Type = 'Output';
        } else {
            params.Params.push({ Name: name, Value: value, Type: 'Output' });
        }
    }
}

export function LoadAttachAddressAction(): void {
    // Prevents tree-shaking of @RegisterClass decorator
}
