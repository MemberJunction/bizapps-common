import { BaseEntity, EntitySaveOptions, LogError, Metadata, UserInfo } from '@memberjunction/core';
import { RegisterClass } from '@memberjunction/global';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';
import { MJUserEntity, MJUserRoleEntity } from '@memberjunction/core-entities';
import { UserCache } from '@memberjunction/sqlserver-dataprovider';

/**
 * The standard MJ "UI" role name — assigned as a default when creating
 * a new User linked to a Person. Downstream layers (e.g., BCSaaS) override
 * this with more specific roles.
 */
const DEFAULT_MJ_ROLE_NAME = 'UI';

/**
 * Server-side subclass of the BAC Person entity.
 *
 * Lifecycle hooks:
 * - **Save (pre):** Auto-links to an MJ User record (creates one if needed)
 * - **Save (post):** Syncs name/email changes to the linked User; assigns default "UI" UserRole
 * - **Delete:** Deactivates the linked User (does not delete — preserves audit history)
 */
@RegisterClass(BaseEntity, 'MJ_BizApps_Common: People')
export class PersonEntityServer extends mjBizAppsCommonPersonEntity {

    override async Save(options?: EntitySaveOptions): Promise<boolean> {
        const isNewRecord = !this.IsSaved;
        const emailField = this.GetFieldByName('Email');
        const emailChanged = emailField?.Dirty === true;
        const needsUserLink = isNewRecord || emailChanged;

        // Pre-save: auto-link to MJ User
        if (needsUserLink && this.Email && !this.LinkedUserID) {
            await this.autoLinkUser();
        }

        const saved = await super.Save(options);
        if (!saved) {
            return false;
        }

        // Post-save: sync person changes to linked User
        if (this.LinkedUserID) {
            await this.syncUserRecord(isNewRecord, emailChanged);
        }

        return true;
    }

    override async Delete(options?: EntitySaveOptions): Promise<boolean> {
        // Pre-delete: deactivate linked User (don't delete — audit history)
        if (this.LinkedUserID) {
            await this.deactivateLinkedUser();
        }

        return super.Delete(options);
    }

    /**
     * Find an existing MJ User by email, or create a new one.
     * Sets LinkedUserID on the Person entity (pre-save, so it's persisted atomically).
     */
    private async autoLinkUser(): Promise<void> {
        try {
            const existingUser = this.findCachedUserByEmail(this.Email!);

            if (existingUser) {
                this.LinkedUserID = existingUser.ID;
            } else {
                const newUserID = await this.createUser();
                if (newUserID) {
                    this.LinkedUserID = newUserID;
                }
            }
        } catch (error: unknown) {
            LogError(`PersonEntityServer: Failed to auto-link User for email ${this.Email}: ${error}`);
            // Don't block save — User linking is best-effort
        }
    }

    /**
     * Find an existing MJ User by email using the cached UserCache.
     * UserCache is populated at server startup and refreshed periodically.
     */
    private findCachedUserByEmail(email: string): UserInfo | undefined {
        const normalizedEmail = email.toLowerCase();
        return UserCache.Users.find(
            u => u.Email.toLowerCase() === normalizedEmail
        );
    }

    /**
     * Create a new MJ User record from the Person's details.
     * Returns the new User ID, or null on failure.
     */
    private async createUser(): Promise<string | null> {
        try {
            const md = new Metadata();
            const user = await md.GetEntityObject<MJUserEntity>('MJ: Users', this.ContextCurrentUser);
            user.NewRecord();

            const fullName = this.buildFullName();
            user.Name = fullName;
            user.FirstName = this.FirstName;
            user.LastName = this.LastName;
            user.Email = this.Email!;
            user.Type = 'User';
            user.IsActive = true;

            const saved = await user.Save();
            if (!saved) {
                LogError(`PersonEntityServer: Failed to save new User for ${this.Email}`);
                return null;
            }

            // Assign default "UI" role to the new user
            await this.assignDefaultUserRole(user.ID);

            return user.ID;
        } catch (error: unknown) {
            LogError(`PersonEntityServer: Error creating User for ${this.Email}: ${error}`);
            return null;
        }
    }

    /**
     * Assign the default MJ "UI" role to a User via the UserRole entity.
     * Uses Metadata.Roles (cached) for role lookup instead of a DB query.
     */
    private async assignDefaultUserRole(userID: string): Promise<void> {
        try {
            const md = new Metadata();
            const role = md.Roles.find(
                r => r.Name.toLowerCase() === DEFAULT_MJ_ROLE_NAME.toLowerCase()
            );
            if (!role) {
                LogError(`PersonEntityServer: MJ Role '${DEFAULT_MJ_ROLE_NAME}' not found in Metadata.Roles — cannot assign default UserRole`);
                return;
            }

            // Check if the user already has this role via UserCache
            const cachedUser = UserCache.Users.find(u => u.ID === userID);
            if (cachedUser?.UserRoles?.find(ur => ur.RoleID === role.ID)) {
                return; // Already has this role
            }

            const userRole = await md.GetEntityObject<MJUserRoleEntity>('MJ: User Roles', this.ContextCurrentUser);
            userRole.NewRecord();
            userRole.UserID = userID;
            userRole.RoleID = role.ID;

            const saved = await userRole.Save();
            if (!saved) {
                LogError(`PersonEntityServer: Failed to assign '${DEFAULT_MJ_ROLE_NAME}' role to User ${userID}`);
            }
        } catch (error: unknown) {
            LogError(`PersonEntityServer: Error assigning default UserRole: ${error}`);
        }
    }

    /**
     * Sync Person name/email changes to the linked MJ User record.
     * Called post-save — only updates if fields actually changed.
     */
    private async syncUserRecord(isNewRecord: boolean, emailChanged: boolean): Promise<void> {
        // On new records, the User was just created with current values — no sync needed
        if (isNewRecord) {
            return;
        }

        const nameFields = ['FirstName', 'LastName', 'MiddleName', 'Prefix', 'Suffix'];
        const nameChanged = nameFields.some(f => this.GetFieldByName(f)?.Dirty === true);

        if (!nameChanged && !emailChanged) {
            return;
        }

        try {
            const md = new Metadata();
            const user = await md.GetEntityObject<MJUserEntity>('MJ: Users', this.ContextCurrentUser);
            const loaded = await user.Load(this.LinkedUserID!);
            if (!loaded) {
                LogError(`PersonEntityServer: Could not load linked User ${this.LinkedUserID} for sync`);
                return;
            }

            if (nameChanged) {
                user.Name = this.buildFullName();
                user.FirstName = this.FirstName;
                user.LastName = this.LastName;
            }

            if (emailChanged && this.Email) {
                user.Email = this.Email;
            }

            const saved = await user.Save();
            if (!saved) {
                LogError(`PersonEntityServer: Failed to sync User ${this.LinkedUserID} after Person update`);
            }
        } catch (error: unknown) {
            LogError(`PersonEntityServer: Error syncing User record: ${error}`);
            // Don't block — sync is best-effort
        }
    }

    /**
     * Deactivate the linked User on Person deletion.
     * Sets IsActive=false rather than deleting, to preserve audit history.
     */
    private async deactivateLinkedUser(): Promise<void> {
        try {
            const md = new Metadata();
            const user = await md.GetEntityObject<MJUserEntity>('MJ: Users', this.ContextCurrentUser);
            const loaded = await user.Load(this.LinkedUserID!);
            if (!loaded) {
                return;
            }

            if (user.IsActive) {
                user.IsActive = false;
                const saved = await user.Save();
                if (!saved) {
                    LogError(`PersonEntityServer: Failed to deactivate User ${this.LinkedUserID}`);
                }
            }
        } catch (error: unknown) {
            LogError(`PersonEntityServer: Error deactivating linked User: ${error}`);
        }
    }

    /**
     * Build a display-friendly full name from Person fields.
     */
    private buildFullName(): string {
        const parts: string[] = [];
        if (this.FirstName) parts.push(this.FirstName);
        if (this.LastName) parts.push(this.LastName);
        return parts.length > 0 ? parts.join(' ') : (this.Email ?? 'Unknown');
    }
}
