/**
 * The offboarding deactivation warning.
 *
 * When HR marks an `MJ: Employees` record inactive, or an admin marks an `MJ: Users` record
 * inactive, this runs every active List action in the `Offboarding Holdings` category for that
 * person. If anything is still held, it sends an MJ user notification to the leaver's supervisor
 * and to every accounting CFO approver, telling them to open Common > Offboarding.
 *
 * It never blocks the save. It listens to MJ's global entity `save` event, which fires after the
 * record is written, and runs detached from the request; every failure is logged and swallowed.
 *
 * Why an event listener and not entity subclasses: MJ already registers `MJUserEntityServer` for
 * `MJ: Users`, and it carries the user table's privilege-elevation guards. A Common subclass would
 * have to extend it, take a dependency on MJ's server entity package, and would silently lose to
 * (or silently replace) any other app's subclass, since the ClassFactory picks one. Listening
 * leaves both entities' class registrations alone, so the same code covers Users and Employees.
 *
 * Why the system user: the warning has to see every app's holdings whatever the saving user may
 * read (HR rarely reads deals), and it acts for the platform, not for that user. What it sends on
 * is a count per domain, never a record label, so no field the recipient could not read leaves it.
 */
import { ActionEngineServer } from '@memberjunction/actions';
import type { ActionParam } from '@memberjunction/actions-base';
import {
    BaseEntity,
    BaseEntityEvent,
    LogError,
    Metadata,
    RunView,
    type IMetadataProvider,
    type IRunViewProvider,
    type UserInfo,
    WellKnownUserSource,
} from '@memberjunction/core';
import {
    MJEmployeeEntity,
    MJUserEntity,
    type MJActionEntity,
    type MJUserNotificationEntity,
} from '@memberjunction/core-entities';
import { BaseSingleton, EscapeSQLString, MJEventType, MJGlobal, UUIDSet, UUIDsEqual, type MJEvent } from '@memberjunction/global';
import {
    OFFBOARDING_HOLDINGS_CATEGORY,
    PairOffboardingActions,
    ParseOffboardingHoldings,
    SummarizeOffboardingHoldings,
    type OffboardingHolding,
} from '@mj-biz-apps/common-entities';

/** The accounting entity whose `ApprovalCFOUserID` names a company's CFO approver. Optional. */
export const ACCOUNTING_COMPANY_PROFILES_ENTITY = 'MJ_BizApps_Accounting: Accounting Company Profiles';

/** A deactivation the save event reported. */
export interface OffboardingDeactivation {
    LeaverUserID: string | null;
    LeaverEmployeeID: string | null;
    DisplayName: string;
}

/** How long a leaver is remembered, so deactivating the User and the Employee warns once. */
const RECENT_WINDOW_MS = 10 * 60 * 1000;

/**
 * Reads a global entity event and returns the deactivation it reports, or null. A deactivation is
 * an UPDATE whose written fields include the active flag and whose flag is now false: the flag is
 * a non-null bit, so "changed and now false" means it went from active to inactive.
 */
export function DetectOffboardingDeactivation(event: BaseEntityEvent): OffboardingDeactivation | null {
    if (event.type !== 'save' || event.saveSubType !== 'update' || !event.baseEntity) {
        return null;
    }
    const changed = event.ChangedFieldNames ?? [];
    const entity = event.baseEntity;
    if (entity instanceof MJEmployeeEntity && changedField(changed, 'Active') && entity.Active === false) {
        const name = `${entity.FirstName ?? ''} ${entity.LastName ?? ''}`.trim();
        return { LeaverUserID: null, LeaverEmployeeID: entity.ID, DisplayName: name || entity.Email || 'An employee' };
    }
    if (entity instanceof MJUserEntity && changedField(changed, 'IsActive') && entity.IsActive === false) {
        return { LeaverUserID: entity.ID, LeaverEmployeeID: entity.EmployeeID, DisplayName: entity.Name || entity.Email || 'A user' };
    }
    return null;
}

function changedField(changed: readonly string[], field: string): boolean {
    return changed.some((name) => name.trim().toLowerCase() === field.toLowerCase());
}

/** The notification text: who left, what they hold per domain, and where to act. */
export function BuildOffboardingWarning(leaver: OffboardingDeactivation, holdings: readonly OffboardingHolding[]): { Title: string; Message: string } {
    return {
        Title: `${leaver.DisplayName} was deactivated and still holds open items`,
        Message:
            `${leaver.DisplayName} was marked inactive but still holds ${holdings.length} open item${holdings.length === 1 ? '' : 's'} ` +
            `(${SummarizeOffboardingHoldings(holdings)}). Open the Common app, Offboarding tab, pick ${leaver.DisplayName} ` +
            'and reassign them to a successor. Nothing has been moved yet.',
    };
}

/** Recipients: the supervisor's user and every CFO approver, once each, never the leaver. */
export function OffboardingWarningRecipients(
    supervisorUserIDs: readonly string[],
    cfoUserIDs: readonly (string | null)[],
    leaverUserID: string | null,
): string[] {
    const seen = new UUIDSet();
    const recipients: string[] = [];
    for (const id of [...supervisorUserIDs, ...cfoUserIDs]) {
        if (id && !seen.Has(id) && !(leaverUserID && UUIDsEqual(id, leaverUserID))) {
            seen.Add(id);
            recipients.push(id);
        }
    }
    return recipients;
}

interface EmployeeRow { ID: string; SupervisorID: string | null }
interface UserRow { ID: string; EmployeeID: string | null; IsActive: boolean }
interface CompanyProfileRow { ApprovalCFOUserID: string | null }

export class OffboardingDeactivationWarning extends BaseSingleton<OffboardingDeactivationWarning> {
    private started = false;
    private readonly recent = new Map<string, number>();

    public static get Instance(): OffboardingDeactivationWarning {
        return super.getInstance<OffboardingDeactivationWarning>();
    }

    /** Subscribes to MJ's global entity events once per process. */
    public Start(): void {
        if (this.started) {
            return;
        }
        this.started = true;
        MJGlobal.Instance.GetEventListener(false).subscribe((event: MJEvent) => this.onEvent(event));
    }

    private onEvent(event: MJEvent): void {
        if (event.event !== MJEventType.ComponentEvent || event.eventCode !== BaseEntity.BaseEventCode) {
            return;
        }
        const entityEvent = event.args as BaseEntityEvent;
        const leaver = DetectOffboardingDeactivation(entityEvent);
        if (!leaver || this.seenRecently(leaver)) {
            return;
        }
        const provider = entityEvent.provider ?? entityEvent.baseEntity?.ProviderToUse as unknown as IMetadataProvider | undefined;
        void this.Warn(leaver, provider).catch((error: unknown) =>
            LogError(`Offboarding warning for ${leaver.DisplayName} failed: ${error instanceof Error ? error.message : String(error)}`));
    }

    /** True when this leaver (by either ID) was handled inside the window; records it otherwise. */
    private seenRecently(leaver: OffboardingDeactivation): boolean {
        const now = Date.now();
        for (const [key, at] of this.recent) {
            if (now - at > RECENT_WINDOW_MS) {
                this.recent.delete(key);
            }
        }
        const keys = [leaver.LeaverUserID, leaver.LeaverEmployeeID].filter((id): id is string => !!id).map((id) => id.toLowerCase());
        if (keys.some((key) => this.recent.has(key))) {
            return true;
        }
        keys.forEach((key) => this.recent.set(key, now));
        return false;
    }

    /** Lists the leaver's holdings and, if there are any, notifies the people who can move them. */
    public async Warn(leaver: OffboardingDeactivation, provider?: IMetadataProvider): Promise<number> {
        const md = provider ?? Metadata.Provider;
        const systemUser = await WellKnownUserSource.Instance.GetSystemUser(md);
        if (!systemUser) {
            LogError('Offboarding warning skipped: no system user is available.');
            return 0;
        }
        const holdings = await this.ListHoldings(leaver, systemUser);
        if (holdings.length === 0) {
            return 0;
        }
        const recipients = await this.ResolveRecipients(leaver, md, systemUser);
        return this.SendNotifications(recipients, BuildOffboardingWarning(leaver, holdings), md, systemUser);
    }

    /** Runs every active List action in the category. A failing app contributes nothing. */
    protected async ListHoldings(leaver: OffboardingDeactivation, user: UserInfo): Promise<OffboardingHolding[]> {
        await ActionEngineServer.Instance.Config(false, user);
        const inCategory = ActionEngineServer.Instance.Actions.filter(
            (action) => action.Category === OFFBOARDING_HOLDINGS_CATEGORY && action.Status === 'Active');
        const listIDs = PairOffboardingActions(inCategory).flatMap((app) => (app.ListActionID ? [app.ListActionID] : []));
        const lists = inCategory.filter((action) => listIDs.some((id) => UUIDsEqual(id, action.ID)));
        const results = await Promise.all(lists.map((action) => this.runList(action, leaver, user)));
        return results.flat();
    }

    private async runList(action: MJActionEntity, leaver: OffboardingDeactivation, user: UserInfo): Promise<OffboardingHolding[]> {
        const params: ActionParam[] = [
            { Name: 'LeaverUserID', Value: leaver.LeaverUserID, Type: 'Input' },
            { Name: 'LeaverEmployeeID', Value: leaver.LeaverEmployeeID, Type: 'Input' },
        ];
        const result = await ActionEngineServer.Instance.RunAction({ Action: action, ContextUser: user, Params: params, Filters: [] });
        if (!result.Success) {
            LogError(`Offboarding warning: ${action.Name} failed: ${result.Message ?? 'no message'}`);
            return [];
        }
        const output = (result.Params ?? params).find((p) => p.Name?.toLowerCase() === 'holdings');
        return ParseOffboardingHoldings(output?.Value);
    }

    /** The supervisor's user (through the leaver's Employee) and every CFO approver. */
    protected async ResolveRecipients(leaver: OffboardingDeactivation, md: IMetadataProvider, user: UserInfo): Promise<string[]> {
        const employeeID = leaver.LeaverEmployeeID ?? await this.employeeOfUser(leaver.LeaverUserID, md, user);
        const supervisorID = employeeID ? await this.supervisorOf(employeeID, md, user) : null;
        const supervisorUsers = supervisorID ? await this.activeUsersOfEmployee(supervisorID, md, user) : [];
        const cfoUsers = await this.cfoApprovers(md, user);
        return OffboardingWarningRecipients(supervisorUsers, cfoUsers, leaver.LeaverUserID);
    }

    private async employeeOfUser(userID: string | null, md: IMetadataProvider, user: UserInfo): Promise<string | null> {
        if (!userID) {
            return null;
        }
        const rows = await this.simpleRows<UserRow>(md, user, 'MJ: Users', ['ID', 'EmployeeID', 'IsActive'], `ID='${EscapeSQLString(userID)}'`);
        return rows[0]?.EmployeeID ?? null;
    }

    private async supervisorOf(employeeID: string, md: IMetadataProvider, user: UserInfo): Promise<string | null> {
        const rows = await this.simpleRows<EmployeeRow>(md, user, 'MJ: Employees', ['ID', 'SupervisorID'], `ID='${EscapeSQLString(employeeID)}'`);
        return rows[0]?.SupervisorID ?? null;
    }

    private async activeUsersOfEmployee(employeeID: string, md: IMetadataProvider, user: UserInfo): Promise<string[]> {
        const rows = await this.simpleRows<UserRow>(md, user, 'MJ: Users', ['ID', 'EmployeeID', 'IsActive'],
            `EmployeeID='${EscapeSQLString(employeeID)}' AND IsActive=1`);
        return rows.map((row) => row.ID);
    }

    /** CFO approvers from accounting company profiles; none when accounting is not installed. */
    private async cfoApprovers(md: IMetadataProvider, user: UserInfo): Promise<(string | null)[]> {
        if (!md.EntityByName(ACCOUNTING_COMPANY_PROFILES_ENTITY)) {
            return [];
        }
        const rows = await this.simpleRows<CompanyProfileRow>(md, user, ACCOUNTING_COMPANY_PROFILES_ENTITY, ['ApprovalCFOUserID'],
            'ApprovalCFOUserID IS NOT NULL');
        return rows.map((row) => row.ApprovalCFOUserID);
    }

    private async simpleRows<T>(md: IMetadataProvider, user: UserInfo, entityName: string, fields: string[], filter: string): Promise<T[]> {
        const result = await new RunView(md as unknown as IRunViewProvider).RunView<T>(
            { EntityName: entityName, Fields: fields, ExtraFilter: filter, ResultType: 'simple' }, user);
        if (!result.Success) {
            LogError(`Offboarding warning: reading ${entityName} failed: ${result.ErrorMessage}`);
            return [];
        }
        return result.Results ?? [];
    }

    /** One notification per recipient; returns how many were saved. */
    protected async SendNotifications(
        recipients: readonly string[],
        text: { Title: string; Message: string },
        md: IMetadataProvider,
        user: UserInfo,
    ): Promise<number> {
        let sent = 0;
        for (const recipient of recipients) {
            const notification = await md.GetEntityObject<MJUserNotificationEntity>('MJ: User Notifications', user);
            notification.NewRecord();
            notification.UserID = recipient;
            notification.Title = text.Title;
            notification.Message = text.Message;
            notification.Unread = true;
            if (await notification.Save()) {
                sent++;
            } else {
                LogError(`Offboarding warning: notification to ${recipient} failed: ${notification.LatestResult?.CompleteMessage ?? 'unknown error'}`);
            }
        }
        return sent;
    }
}

/** Starts the listener; called from the server bootstrap. */
export function LoadOffboardingDeactivationWarning(): void {
    OffboardingDeactivationWarning.Instance.Start();
}
