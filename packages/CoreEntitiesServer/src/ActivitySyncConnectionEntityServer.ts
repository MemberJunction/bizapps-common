import { BaseEntity, type EntitySaveOptions } from '@memberjunction/core';
import { RegisterClass } from '@memberjunction/global';
import { mjBizAppsCommonActivitySyncConnectionEntity } from '@mj-biz-apps/common-entities';
import { ChangedRoutingFields, CONNECTION_ROUTING_FIELDS } from './activity-sync-connection-routing.js';
import { IsOwnerUser, IsSystemUser, ReadOwnStoredRow, RefuseSave, type StoredValues } from './entity-guards.js';

/**
 * Server-side Activity Sync Connection (#392).
 *
 * Only an administrator (an Owner-type user) or the System user may create a connection or change
 * the columns that decide whose mail it reads: `Mailbox`, `CredentialsRef`, `Provider`,
 * `ActivitySyncProviderTypeID`, `OwnerUserID`, and `Settings` apart from the calendar watermark.
 * Everyone else who may update a connection (the Developer and Integration roles by default, and
 * the sync engine as whatever user the scheduled job runs as) keeps the operational writes:
 * status, last error, last sync time, the calendar watermark, the capture policy and the window.
 *
 * The rule compares the values about to be saved with the stored row, read as the saving user,
 * so a client that hydrates the update from its own old values cannot hide a change. A failed read
 * refuses the save.
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Activity Sync Connections')
export class ActivitySyncConnectionEntityServer extends mjBizAppsCommonActivitySyncConnectionEntity {
    private static readonly CREATE_REFUSED =
        'Only an administrator (Owner-type user) may create an Activity Sync Connection, because a connection decides which mailbox the sync reads.';

    public override async Save(options?: EntitySaveOptions): Promise<boolean> {
        const refusal = await this.routingRefusal();
        if (refusal) return RefuseSave(this, refusal);
        return super.Save(options);
    }

    /** Why the saving user may not save this connection, or null when they may. */
    private async routingRefusal(): Promise<string | null> {
        const user = this.ActiveUser;
        if (IsOwnerUser(user) || IsSystemUser(user)) return null;
        if (!user) return 'An Activity Sync Connection can only be saved with a known user.';
        if (!this.IsSaved) return ActivitySyncConnectionEntityServer.CREATE_REFUSED;

        const stored = await ReadOwnStoredRow(this, CONNECTION_ROUTING_FIELDS, user);
        if (!stored) {
            return 'The stored Activity Sync Connection could not be read, so the save was refused.';
        }
        const changed = ChangedRoutingFields(this.currentRoutingValues(), stored);
        if (changed.length === 0) return null;
        return (
            `Only an administrator (Owner-type user) may change ${changed.join(', ')} on an Activity Sync ` +
            'Connection, because these decide which mailbox the sync reads and who owns what it ingests.'
        );
    }

    private currentRoutingValues(): StoredValues {
        return {
            Mailbox: this.Mailbox,
            CredentialsRef: this.CredentialsRef,
            Provider: this.Provider,
            OwnerUserID: this.OwnerUserID,
            ActivitySyncProviderTypeID: this.ActivitySyncProviderTypeID,
            Settings: this.Settings,
        };
    }
}
