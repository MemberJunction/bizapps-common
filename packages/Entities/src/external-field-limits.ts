/**
 * Field-length limits of the external systems BizApps writes to, read from integration metadata.
 *
 * A value longer than the external field is rejected by that system when it syncs, days after it
 * was typed, so apps check it on save and again before each send. The limits are the `Length` MJ
 * already stores on `MJ: Integration Object Fields`, seeded from each connector's own metadata —
 * one place, maintained by the connector, never a number copied into an app.
 *
 * Apps say which external fields a value feeds; the smallest of their lengths is the limit. A
 * value over it is reported, never truncated: a truncated name no longer matches across systems.
 *
 * Fail loud. A target this instance has no length for is an error, not a pass, because a
 * silently skipped check is the failure this exists to prevent. Apps decide whether a target
 * applies (for example, only when the record is sent to that system) before asking.
 */
import { BaseEngine, BaseEnginePropertyConfig, IMetadataProvider, UserInfo } from '@memberjunction/core';

export const INTEGRATION_OBJECTS_ENTITY = 'MJ: Integration Objects';
export const INTEGRATION_OBJECT_FIELDS_ENTITY = 'MJ: Integration Object Fields';

/** One field of an external system, named as its connector's metadata names it. */
export interface ExternalFieldTarget {
    /** `MJ: Integrations` Name, e.g. `business-central` or `Bill.com`. */
    Integration: string;
    /** `MJ: Integration Objects` Name, e.g. `journalLines`. */
    Object: string;
    /** `MJ: Integration Object Fields` Name, e.g. `accountNumber`. */
    Field: string;
}

export interface IntegrationObjectRow {
    ID: string;
    Name: string;
    Integration: string;
}

export interface IntegrationObjectFieldRow {
    IntegrationObjectID: string;
    Name: string;
    Length: number | null;
}

/** The limit for a value, and the target that sets it. */
export interface ExternalFieldLimit {
    Length: number;
    Target: ExternalFieldTarget;
}

export type ExternalFieldLimitResult = { Limit: ExternalFieldLimit; Missing?: undefined } | { Limit?: undefined; Missing: ExternalFieldTarget[] };

function describeTarget(target: ExternalFieldTarget): string {
    return `${target.Integration} ${target.Object}.${target.Field}`;
}

function sameName(a: string, b: string): boolean {
    return a.trim().toLowerCase() === b.trim().toLowerCase();
}

function lengthOf(target: ExternalFieldTarget, objects: ReadonlyArray<IntegrationObjectRow>, fields: ReadonlyArray<IntegrationObjectFieldRow>): number | null {
    const obj = objects.find((o) => sameName(o.Integration, target.Integration) && sameName(o.Name, target.Object));
    if (!obj) return null;
    const field = fields.find((f) => f.IntegrationObjectID.toLowerCase() === obj.ID.toLowerCase() && sameName(f.Name, target.Field));
    return field?.Length && field.Length > 0 ? field.Length : null;
}

/**
 * The smallest length across `targets`, or the targets this metadata has no length for. Pure, for
 * tests; the engine calls it with its cached rows.
 */
export function ResolveExternalFieldLimit(
    targets: ReadonlyArray<ExternalFieldTarget>,
    objects: ReadonlyArray<IntegrationObjectRow>,
    fields: ReadonlyArray<IntegrationObjectFieldRow>,
): ExternalFieldLimitResult {
    if (targets.length === 0) throw new Error('ResolveExternalFieldLimit needs at least one target');
    const missing: ExternalFieldTarget[] = [];
    let limit: ExternalFieldLimit | undefined;
    for (const target of targets) {
        const length = lengthOf(target, objects, fields);
        if (length === null) missing.push(target);
        else if (!limit || length < limit.Length) limit = { Length: length, Target: target };
    }
    return missing.length > 0 || !limit ? { Missing: missing } : { Limit: limit };
}

/**
 * The message for `value` against `targets`, or null when it fits. `label` is the field's display
 * name. Blank values fit; whether a field is required is the entity's own rule.
 */
export function CheckExternalFieldLength(
    label: string,
    value: string | null | undefined,
    targets: ReadonlyArray<ExternalFieldTarget>,
    objects: ReadonlyArray<IntegrationObjectRow>,
    fields: ReadonlyArray<IntegrationObjectFieldRow>,
): string | null {
    const resolved = ResolveExternalFieldLimit(targets, objects, fields);
    if (resolved.Missing) {
        return `${label} cannot be checked: no field length is recorded for ${resolved.Missing.map(describeTarget).join(', ')}.`;
    }
    const length = value?.length ?? 0;
    if (length <= resolved.Limit.Length) return null;
    return `${label} is ${length} characters; ${describeTarget(resolved.Limit.Target)} allows ${resolved.Limit.Length}. Shorten it.`;
}

/** Why a check could not run when the configuring user cannot read integration metadata. */
export const INTEGRATION_METADATA_UNREADABLE =
    `the user this server checks limits with cannot read ${INTEGRATION_OBJECTS_ENTITY} and ${INTEGRATION_OBJECT_FIELDS_ENTITY}`;

/**
 * The cached integration field lengths, one per process.
 *
 * Configure it with a user who can read `MJ: Integration Objects` and `MJ: Integration Object
 * Fields` — on a server, the system user, not the user whose save is being checked. The lengths
 * are catalog data; the saving user's permissions should not decide whether they can be read.
 *
 * A user without read access loads nothing. MJ still marks the engine loaded, so the next
 * `Config` here reloads rather than keeping the empty lists, and until a reload succeeds every
 * check reports that it could not run instead of throwing out of a save.
 *
 * Installed metadata changes reach a running server only when MJ's `LocalCacheManager` is
 * initialized; otherwise they apply after a restart or `Config(true)`.
 */
export class ExternalFieldLimitEngine extends BaseEngine<ExternalFieldLimitEngine> {
    private _objects: IntegrationObjectRow[] = [];
    private _fields: IntegrationObjectFieldRow[] = [];

    public static get Instance(): ExternalFieldLimitEngine {
        return super.getInstance<ExternalFieldLimitEngine>();
    }

    public async Config(forceRefresh?: boolean, contextUser?: UserInfo, provider?: IMetadataProvider): Promise<unknown> {
        const params: Array<Partial<BaseEnginePropertyConfig>> = [
            { PropertyName: '_objects', EntityName: INTEGRATION_OBJECTS_ENTITY, ResultType: 'simple' },
            { PropertyName: '_fields', EntityName: INTEGRATION_OBJECT_FIELDS_ENTITY, Filter: 'Length > 0', ResultType: 'simple' },
        ];
        // A load that was skipped for lack of permission is retried, not kept: one limited user must
        // not leave the check unable to run for every user in the process.
        return await this.Load(params, provider as IMetadataProvider, (forceRefresh ?? false) || this.IsPermissionConstrained, contextUser);
    }

    /** The limit for `targets`; throws when the engine is not configured, cannot read metadata, or a target has no length. */
    public GetLimit(targets: ReadonlyArray<ExternalFieldTarget>): ExternalFieldLimit {
        this.assertLoaded();
        if (this.IsPermissionConstrained) throw new Error(`Field lengths cannot be read: ${INTEGRATION_METADATA_UNREADABLE}`);
        const resolved = ResolveExternalFieldLimit(targets, this.objects, this.fields);
        if (resolved.Missing) throw new Error(`No field length is recorded for ${resolved.Missing.map(describeTarget).join(', ')}`);
        return resolved.Limit;
    }

    /** The message for `value` against `targets`, or null when it fits. See {@link CheckExternalFieldLength}. */
    public Check(label: string, value: string | null | undefined, targets: ReadonlyArray<ExternalFieldTarget>): string | null {
        this.assertLoaded();
        if (this.IsPermissionConstrained) return `${label} cannot be checked: ${INTEGRATION_METADATA_UNREADABLE}.`;
        return CheckExternalFieldLength(label, value, targets, this.objects, this.fields);
    }

    private get objects(): IntegrationObjectRow[] {
        this.assertLoaded();
        return this.GetConfigData<IntegrationObjectRow>('_objects');
    }

    private get fields(): IntegrationObjectFieldRow[] {
        this.assertLoaded();
        return this.GetConfigData<IntegrationObjectFieldRow>('_fields');
    }

    private assertLoaded(): void {
        if (!this.Loaded) throw new Error('ExternalFieldLimitEngine is not configured — await ExternalFieldLimitEngine.Instance.Config(false, contextUser) first');
    }
}
