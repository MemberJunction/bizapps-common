import { BaseEntity, type EntitySaveOptions } from '@memberjunction/core';
import { RegisterClass, UUIDsEqual } from '@memberjunction/global';
import { mjBizAppsCommonActivityEntity } from '@mj-biz-apps/common-entities';
import { NormalizeStored, ReadOwnStoredRow, RefuseSave } from './entity-guards.js';

/**
 * Server-side Activity (#395).
 *
 * `LoggedByUserID` says who logged an activity, and the row-level security on Private activities
 * shows them to that user. So it is never taken from the caller: a create stamps the saving user,
 * whatever value was sent, and an update may not change it. Both writers in Activity Sync already
 * stamp the saving user, so they behave the same as before; a direct API save now does too.
 *
 * The update check compares with the stored row, read as the saving user, so a client that
 * hydrates the update from its own old values cannot hide a change.
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Activities')
export class ActivityEntityServer extends mjBizAppsCommonActivityEntity {
    public override async Save(options?: EntitySaveOptions): Promise<boolean> {
        const refusal = await this.stampLogger();
        if (refusal) return RefuseSave(this, refusal);
        return super.Save(options);
    }

    /** Stamps the logger on a create; on an update, returns why the save is refused, if it is. */
    private async stampLogger(): Promise<string | null> {
        const user = this.ActiveUser;
        if (!user) return 'An Activity can only be saved with a known user, who is recorded as its logger.';
        if (!this.IsSaved) {
            this.LoggedByUserID = user.ID;
            return null;
        }
        const stored = await ReadOwnStoredRow(this, ['LoggedByUserID'], user);
        const storedLogger = stored ? NormalizeStored(stored.LoggedByUserID) : null;
        if (storedLogger === null) {
            return 'The stored Activity could not be read, so the save was refused.';
        }
        if (!UUIDsEqual(storedLogger, this.LoggedByUserID)) {
            return 'LoggedByUserID cannot be changed: it records the user who logged the activity.';
        }
        return null;
    }
}
