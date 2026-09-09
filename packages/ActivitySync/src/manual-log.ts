/**
 * Parameter parsing for `Common.LogActivity` — the declarative entry point to the unified timeline.
 *
 * Everything here takes PLAIN, SERIALIZABLE values, because the action's inputs may cross a queue,
 * a durable task or an agent boundary before they arrive. That is why an Entity Action binding must
 * feed `RecordData` with ValueType `'Entity Object Data'` and never `'Entity Object'`: a
 * `BaseEntity` serializes to `{}` (its fields are getters, not enumerable own properties) —
 * silently, with no error (plans/mj-entity-action-workflow-adoption.md §3.3).
 *
 * Pure functions, no I/O — the `Common.LogActivity` action in `@mj-biz-apps/common-server` is a
 * thin shell over `ParseLogActivityParams` + `ActivityWriter.WriteManual`.
 */
import { ACTIVITY_IDENTITY_KINDS, ACTIVITY_LINK_ROLES } from './types.js';
import type { ActivityDirection, ActivityIdentityKind, ActivityLinkRole } from './types.js';
import type {
    ActivityLinkSpec,
    ActivitySourceValue,
    ActivityStatusValue,
    ActivityVisibilityValue,
    WriteManualActivityInput,
} from './writer.js';

/** The SourceSystem stamped on idempotent declarative writes when a binding sets EventKey alone. */
export const LOG_ACTIVITY_DEFAULT_SOURCE_SYSTEM = 'EntityAction';

const DIRECTIONS: readonly ActivityDirection[] = ['Inbound', 'Outbound', 'Internal'];
const STATUSES: readonly ActivityStatusValue[] = ['Logged', 'Scheduled', 'Completed', 'Cancelled', 'Failed'];
const VISIBILITIES: readonly ActivityVisibilityValue[] = ['Internal', 'Private'];
const SOURCES: readonly Exclude<ActivitySourceValue, 'Integration'>[] = ['Manual', 'System'];

/**
 * Declarative "link the activity to whatever this record points at": read `Field` from
 * `RecordData` and, when it holds a value, link that record with `Role`. This is what makes
 * timeline population configuration — a binding on any entity can route the activity to the
 * People / Organizations rows the record references, with no code in the consuming app.
 */
export interface LogActivityLinkFieldSpec {
    Field: string;
    EntityName: string;
    Role: ActivityLinkRole;
}

export interface LogActivityParseResult {
    Input: WriteManualActivityInput | null;
    Errors: string[];
}

class ParamReader {
    private readonly byName = new Map<string, unknown>();
    public readonly errors: string[] = [];

    public constructor(values: Record<string, unknown>) {
        for (const [name, value] of Object.entries(values)) {
            this.byName.set(name.toLowerCase(), value);
        }
    }

    public raw(name: string): unknown {
        const value = this.byName.get(name.toLowerCase());
        return value === null || value === undefined || value === '' ? undefined : value;
    }

    public string(name: string): string | undefined {
        const value = this.raw(name);
        if (value === undefined) return undefined;
        if (typeof value !== 'string') {
            this.errors.push(`${name} must be a string.`);
            return undefined;
        }
        const trimmed = value.trim();
        return trimmed.length > 0 ? trimmed : undefined;
    }

    public date(name: string): Date | undefined {
        const value = this.raw(name);
        if (value === undefined) return undefined;
        const parsed = value instanceof Date ? value : typeof value === 'string' ? new Date(value) : undefined;
        if (!parsed || Number.isNaN(parsed.getTime())) {
            this.errors.push(`${name} must be a date or an ISO date string.`);
            return undefined;
        }
        return parsed;
    }

    public oneOf<T extends string>(name: string, allowed: readonly T[]): T | undefined {
        const value = this.string(name);
        if (value === undefined) return undefined;
        const match = allowed.find((candidate) => candidate.toLowerCase() === value.toLowerCase());
        if (!match) {
            this.errors.push(`${name} must be one of: ${allowed.join(', ')}.`);
            return undefined;
        }
        return match;
    }

    /** An object param that may arrive as a real object or as a JSON string. */
    public object(name: string): unknown {
        const value = this.raw(name);
        if (value === undefined) return undefined;
        if (typeof value === 'object') return value;
        if (typeof value === 'string') {
            try {
                return JSON.parse(value) as unknown;
            } catch {
                this.errors.push(`${name} must be an object or valid JSON.`);
                return undefined;
            }
        }
        this.errors.push(`${name} must be an object or valid JSON.`);
        return undefined;
    }
}

function isRecord(value: unknown): value is Record<string, unknown> {
    return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function parseLinkSpecs(reader: ParamReader): ActivityLinkSpec[] {
    const value = reader.object('Links');
    if (value === undefined) return [];
    if (!Array.isArray(value)) {
        reader.errors.push('Links must be an array of link specs.');
        return [];
    }
    const links: ActivityLinkSpec[] = [];
    for (const [index, item] of value.entries()) {
        const link = parseOneLinkSpec(item, index, reader.errors);
        if (link) links.push(link);
    }
    return links;
}

function parseOneLinkSpec(item: unknown, index: number, errors: string[]): ActivityLinkSpec | null {
    if (!isRecord(item)) {
        errors.push(`Links[${index}] must be an object.`);
        return null;
    }
    const role = item.Role;
    if (typeof role !== 'string' || !ACTIVITY_LINK_ROLES.includes(role as ActivityLinkRole)) {
        errors.push(`Links[${index}].Role must be one of: ${ACTIVITY_LINK_ROLES.join(', ')}.`);
        return null;
    }
    const kind = item.IdentityKind;
    if (kind !== undefined && (typeof kind !== 'string' || !ACTIVITY_IDENTITY_KINDS.includes(kind as ActivityIdentityKind))) {
        errors.push(`Links[${index}].IdentityKind must be one of: ${ACTIVITY_IDENTITY_KINDS.join(', ')}.`);
        return null;
    }
    return {
        Role: role as ActivityLinkRole,
        EntityName: typeof item.EntityName === 'string' ? item.EntityName : undefined,
        RecordID: typeof item.RecordID === 'string' ? item.RecordID : undefined,
        IdentityKind: kind as ActivityIdentityKind | undefined,
        IdentityValue: typeof item.IdentityValue === 'string' ? item.IdentityValue : undefined,
    };
}

function parseLinkFields(
    reader: ParamReader,
    recordData: Record<string, unknown> | undefined,
): ActivityLinkSpec[] {
    const value = reader.object('LinkFields');
    if (value === undefined) return [];
    if (!Array.isArray(value)) {
        reader.errors.push('LinkFields must be an array of { Field, EntityName, Role } specs.');
        return [];
    }
    if (!recordData) {
        reader.errors.push('LinkFields requires RecordData to read the fields from.');
        return [];
    }
    const links: ActivityLinkSpec[] = [];
    for (const [index, item] of value.entries()) {
        if (!isRecord(item) || typeof item.Field !== 'string' || typeof item.EntityName !== 'string') {
            reader.errors.push(`LinkFields[${index}] must carry Field, EntityName and Role.`);
            continue;
        }
        const role = item.Role;
        if (typeof role !== 'string' || !ACTIVITY_LINK_ROLES.includes(role as ActivityLinkRole)) {
            reader.errors.push(`LinkFields[${index}].Role must be one of: ${ACTIVITY_LINK_ROLES.join(', ')}.`);
            continue;
        }
        const target = recordData[item.Field];
        if (typeof target === 'string' && target.trim().length > 0) {
            links.push({ Role: role as ActivityLinkRole, EntityName: item.EntityName, RecordID: target });
        }
        // A null / absent FK is not an error — the record simply does not point at anything.
    }
    return links;
}

/**
 * Parse the flat parameter set of `Common.LogActivity` into a `WriteManualActivityInput`.
 *
 * Conveniences for declarative bindings:
 * - `EntityName` + `RecordID` (or `RecordData.ID`) become a leading `Regarding` link — the record
 *   the activity is about.
 * - `LinkFields` routes the activity to records the subject points at (see the type's doc).
 * - `EventKey` makes a binding idempotent per record: with `EntityName` and a record id present,
 *   `ExternalID` becomes `EntityName|RecordID|EventKey` and `SourceSystem` defaults to
 *   'EntityAction', so a durable retry cannot double-log. Use it for one-per-record events
 *   (AfterCreate); leave it off when every firing should log (a status that changes repeatedly).
 */
export function ParseLogActivityParams(values: Record<string, unknown>): LogActivityParseResult {
    const reader = new ParamReader(values);

    const typeCode = reader.string('TypeCode');
    const title = reader.string('Title');
    const startedAt = reader.date('StartedAt') ?? new Date();
    const endedAt = reader.date('EndedAt');
    const detailsValue = reader.object('Details');
    if (detailsValue !== undefined && !isRecord(detailsValue)) {
        reader.errors.push('Details must be a JSON object.');
    }

    const recordDataValue = reader.object('RecordData');
    if (recordDataValue !== undefined && !isRecord(recordDataValue)) {
        reader.errors.push('RecordData must be a JSON object (Entity Object Data).');
    }
    const recordData = isRecord(recordDataValue) ? recordDataValue : undefined;

    const entityName = reader.string('EntityName');
    const recordID =
        reader.string('RecordID') ?? (typeof recordData?.ID === 'string' ? recordData.ID : undefined);

    const links: ActivityLinkSpec[] = [];
    if (entityName && recordID) {
        links.push({ Role: 'Regarding', EntityName: entityName, RecordID: recordID });
    } else if ((entityName && !recordID) || (!entityName && recordID)) {
        reader.errors.push('EntityName and RecordID (or RecordData.ID) must be provided together.');
    }
    links.push(...parseLinkFields(reader, recordData));
    links.push(...parseLinkSpecs(reader));

    let sourceSystem = reader.string('SourceSystem');
    let externalID = reader.string('ExternalID');
    const eventKey = reader.string('EventKey');
    if (eventKey && !externalID) {
        if (entityName && recordID) {
            sourceSystem = sourceSystem ?? LOG_ACTIVITY_DEFAULT_SOURCE_SYSTEM;
            externalID = `${entityName}|${recordID}|${eventKey}`;
        } else {
            reader.errors.push('EventKey requires EntityName and a record id to derive an idempotency key.');
        }
    }

    const input: WriteManualActivityInput = {
        TypeCode: typeCode ?? '',
        Title: title ?? '',
        StartedAt: startedAt,
        EndedAt: endedAt ?? null,
        Description: reader.string('Description') ?? null,
        Direction: reader.oneOf('Direction', DIRECTIONS),
        Status: reader.oneOf('Status', STATUSES),
        Visibility: reader.oneOf('Visibility', VISIBILITIES),
        Source: reader.oneOf('Source', SOURCES),
        Location: reader.string('Location') ?? null,
        Details: isRecord(detailsValue) ? detailsValue : null,
        SourceSystem: sourceSystem ?? null,
        ExternalID: externalID ?? null,
        Links: links,
    };

    if (!typeCode) reader.errors.push('TypeCode is required.');
    if (!title) reader.errors.push('Title is required.');

    return reader.errors.length > 0 ? { Input: null, Errors: reader.errors } : { Input: input, Errors: [] };
}
