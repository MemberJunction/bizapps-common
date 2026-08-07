import { BaseEntity, UserInfo } from '@memberjunction/core';
import { RegisterClass, UUIDsEqual } from '@memberjunction/global';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';
import { UserCache } from '@memberjunction/sqlserver-dataprovider';

/**
 * Server-side subclass of the BAC Person entity.
 *
 * ## v5.33.0 — MJ User decoupling
 *
 * Prior to v5.33.0 this class auto-provisioned MJ User accounts: saving a
 * Person with an email created (or linked) an active `MJ: Users` record,
 * granted it the default `'UI'` role, synced name/email changes to the User,
 * wrote the User→Person back-pointer, and deactivated the User on delete.
 *
 * That behavior was wrong for a generic CRM layer — people recorded here
 * (job applicants, CRM contacts, message senders) must not implicitly gain
 * platform access. See https://github.com/MemberJunction/bizapps-common/issues/36.
 *
 * As of v5.33.0, saving or deleting a Person has **no MJ User side effects**.
 * Platform layers that bind people to MJ Users (e.g., BCSaaS) do so through
 * their own IS-A subtype of this entity (BCSaaS `BC: People`), where
 * all provisioning/sync lifecycle behavior now lives. `Person.LinkedUserID`
 * is deprecated (EntityField Status='Deprecated') and no longer read or
 * written by bizapps-common.
 *
 * @deprecated This class is retained only so existing downstream subclasses
 * (e.g., BCSaaS ≤1.7 `BCSaaSPersonEntityServer`) continue to load against
 * BAC 5.33.x. It adds no behavior over the generated entity and will be
 * removed in the next major release — extend `mjBizAppsCommonPersonEntity`
 * directly instead.
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: People')
export class PersonEntityServer extends mjBizAppsCommonPersonEntity {

    /**
     * Find an existing MJ User by email using the cached UserCache.
     * Retained as a helper for downstream subclasses; not called by this class.
     */
    protected findCachedUserByEmail(email: string): UserInfo | undefined {
        const normalizedEmail = email.toLowerCase();
        return UserCache.Users.find(
            u => u.Email.toLowerCase() === normalizedEmail
        );
    }

    /**
     * Build a display-friendly full name from Person fields.
     * Retained as a helper for downstream subclasses; not called by this class.
     */
    protected buildFullName(): string {
        const parts: string[] = [];
        if (this.FirstName) parts.push(this.FirstName);
        if (this.LastName) parts.push(this.LastName);
        return parts.length > 0 ? parts.join(' ') : (this.Email ?? 'Unknown');
    }

    /**
     * Check if the given user ID is the MJ system user.
     * The system user is a special internal record that must never be modified
     * by person-related lifecycle code — doing so corrupts the MJ environment.
     */
    protected isSystemUser(userID: string): boolean {
        const systemUserID = UserCache.Instance.SYSTEM_USER_ID;
        return UUIDsEqual(userID, systemUserID);
    }
}
