import { BaseEntity, CompositeKey, type EntitySaveOptions } from '@memberjunction/core';
import { RegisterClass, UUIDsEqual } from '@memberjunction/global';
import { mjBizAppsCommonActivityLinkEntity } from '@mj-biz-apps/common-entities';
import { MetadataOf, NormalizeStored, ReadOwnStoredRow, ReadStoredRow, RefuseSave } from './entity-guards.js';

/** The record an Activity Link points at, or null for a link with no resolved target yet. */
interface LinkTarget {
    EntityID: string;
    RecordID: string;
}

/**
 * True when `key` names exactly the primary key columns `pkNames`, each once, with a value.
 * Exported for tests.
 */
export function KeyMatchesPrimaryKeys(key: CompositeKey, pkNames: readonly string[]): boolean {
    const expected = new Set(pkNames.map((n) => n.trim().toLowerCase()));
    const seen = new Set<string>();
    for (const pair of key.KeyValuePairs) {
        const name = String(pair.FieldName ?? '').trim().toLowerCase();
        if (!expected.has(name) || seen.has(name) || NormalizeStored(pair.Value) === null) return false;
        seen.add(name);
    }
    return seen.size === expected.size;
}

/**
 * Server-side Activity Link (#396).
 *
 * A link with a target (`EntityID` + `RecordID`) puts its activity on that record's timeline, and
 * an Internal activity is readable by anyone who can read a record it is Regarding. So a link may
 * be saved only by a user who can read its target: the save reads the target as the saving user
 * and is refused when it does not come back (missing, outside the user's row-level security, or
 * an entity the user cannot read). A link with no target yet, an unresolved email or phone
 * identity, is not checked.
 *
 * Checked on every save that carries a target, create or update, so no hydration path can skip it.
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Activity Links')
export class ActivityLinkEntityServer extends mjBizAppsCommonActivityLinkEntity {
    private static readonly TARGET_REFUSED =
        'The linked record does not exist or you do not have access to it, so the activity cannot be linked to it.';

    public override async Save(options?: EntitySaveOptions): Promise<boolean> {
        const refusal = await this.targetRefusal();
        if (refusal) return RefuseSave(this, refusal);
        return super.Save(options);
    }

    /** Why the saving user may not save this link, or null when they may. */
    private async targetRefusal(): Promise<string | null> {
        const user = this.ActiveUser;
        if (!user) return 'An Activity Link can only be saved with a known user.';
        const target = await this.targetToCheck();
        if (target === 'unreadable') return 'The stored Activity Link could not be read, so the save was refused.';
        if (target === null) return null;
        return (await this.canReadTarget(target)) ? null : ActivityLinkEntityServer.TARGET_REFUSED;
    }

    /**
     * The target this save will store. An update that did not load `EntityID` or `RecordID` keeps
     * the stored values, so those are read back first.
     */
    private async targetToCheck(): Promise<LinkTarget | null | 'unreadable'> {
        let entityID = NormalizeStored(this.EntityID);
        let recordID = NormalizeStored(this.RecordID);
        const notLoaded = ['EntityID', 'RecordID'].some((name) => this.GetFieldByName(name)?.NotLoaded === true);
        if (this.IsSaved && notLoaded) {
            const stored = await ReadOwnStoredRow(this, ['EntityID', 'RecordID'], this.ActiveUser);
            if (!stored) return 'unreadable';
            entityID = NormalizeStored(stored.EntityID);
            recordID = NormalizeStored(stored.RecordID);
        }
        return entityID && recordID ? { EntityID: entityID, RecordID: recordID } : null;
    }

    /** True when the saving user can read the target record. Fails closed. */
    private async canReadTarget(target: LinkTarget): Promise<boolean> {
        const md = MetadataOf(this);
        const entityInfo = md?.Entities.find((e) => UUIDsEqual(e.ID, target.EntityID));
        if (!entityInfo || entityInfo.PrimaryKeys.length === 0) return false;
        const key = CompositeKey.FromURLSegment(entityInfo, target.RecordID);
        const fields = entityInfo.PrimaryKeys.map((pk) => pk.Name);
        // A delimited RecordID carries its own field names, which go into the filter unquoted, so
        // each must be one of the entity's primary key columns.
        if (!KeyMatchesPrimaryKeys(key, fields)) return false;
        const row = await ReadStoredRow(this, entityInfo, key, fields, this.ActiveUser);
        return row !== null;
    }
}
