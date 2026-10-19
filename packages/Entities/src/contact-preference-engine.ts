/**
 * Contact preferences: the one place to read and set consent on contact methods.
 *
 * `CanContact` is what Comms' send-time hook calls: for a person or organization and a channel
 * (Email, Phone, SMS) it rolls the consent of every contact method on that channel into one
 * decision with a reason. `SetConsent` and `OptOutByValue` write a history row and the current
 * status together, through the contact method's `ConsentHistory` collection, so the two can never
 * disagree. A change that arrives with an older date than the latest change is kept in history
 * and leaves the current status alone.
 *
 * The engine caches Contact Types, which carry the link from a type to its channel, so a decision
 * costs one RunView. Call `await ContactPreferenceEngine.Instance.Config(false, user, provider)`
 * where the other engines are configured; the read methods configure lazily if nobody did.
 */
import { BaseEngine, BaseEnginePropertyConfig, IMetadataProvider, RunView, UserInfo } from '@memberjunction/core';
import { EscapeSQLString } from '@memberjunction/global';
import { mjBizAppsCommonContactMethodEntity, mjBizAppsCommonContactTypeEntity } from './generated/entity_subclasses';
import {
    ContactChannel,
    ContactConsentStatus,
    ContactDecision,
    ContactDecisionPolicy,
    DecideContact,
    IsLatestConsentChange,
} from './contact-consent.js';
import { ContactMethodEntity } from './contact-method-entity.js';

export const CONTACT_TYPES_ENTITY = 'MJ_BizApps_Common: Contact Types';
export const CONTACT_METHODS_ENTITY = 'MJ_BizApps_Common: Contact Methods';

/** The columns of a Contact Types row the engine reads, typed from the generated entity. */
export type ContactTypeChannelRow = Pick<
    mjBizAppsCommonContactTypeEntity,
    'ID' | 'Name' | 'IsActive' | 'CommunicationBaseMessageTypeID' | 'CommunicationBaseMessageType'
>;

/** Whose contact methods a decision is about. Exactly one of the two. */
export interface ContactSubject {
    PersonID?: string;
    OrganizationID?: string;
}

export interface SetConsentArgs {
    ContactMethodID: string;
    Status: ContactConsentStatus;
    /** Where the change came from, for example "Web signup", "Unsubscribe link", "Import: CRM". */
    Source: string;
    /** When it took effect in the real world. Defaults to now. */
    At?: Date;
    Notes?: string | null;
}

export interface ConsentChangeResult {
    Success: boolean;
    /** False when the change was older than the latest one and so only went into history. */
    StatusChanged: boolean;
    ErrorMessage?: string;
}

export interface OptOutByValueResult {
    /** Contact methods whose value matched. */
    Matched: number;
    /** Of those, how many had their current status moved to OptedOut. */
    Changed: number;
    Errors: string[];
}

export class ContactPreferenceEngine extends BaseEngine<ContactPreferenceEngine> {
    private _contactTypes: ContactTypeChannelRow[] = [];

    public static get Instance(): ContactPreferenceEngine {
        return super.getInstance<ContactPreferenceEngine>();
    }

    public async Config(forceRefresh?: boolean, contextUser?: UserInfo, provider?: IMetadataProvider): Promise<unknown> {
        const params: Array<Partial<BaseEnginePropertyConfig>> = [
            {
                PropertyName: '_contactTypes',
                EntityName: CONTACT_TYPES_ENTITY,
                ResultType: 'simple',
            },
        ];
        return await this.Load(params, provider as IMetadataProvider, forceRefresh ?? false, contextUser);
    }

    /** The cached Contact Types, each with the channel it maps to (or null for types like LinkedIn). */
    public get ContactTypes(): ContactTypeChannelRow[] {
        return this.GetConfigData<ContactTypeChannelRow>('_contactTypes');
    }

    /** IDs of the active contact types that carry the given channel. */
    public ContactTypeIDsForChannel(channel: ContactChannel): string[] {
        return this.ContactTypes.filter((t) => t.IsActive && t.CommunicationBaseMessageType === channel).map((t) => t.ID);
    }

    /**
     * Whether a person or organization may be contacted on a channel, and why.
     *
     * One read: the consent status of every contact method the subject has on that channel. The
     * roll-up rule is {@link DecideContact}.
     */
    public async CanContact(
        subject: ContactSubject,
        channel: ContactChannel,
        policy: ContactDecisionPolicy = {},
        contextUser?: UserInfo,
    ): Promise<ContactDecision> {
        await this.EnsureLoaded(contextUser);
        const typeIDs = this.ContactTypeIDsForChannel(channel);
        if (typeIDs.length === 0) {
            return DecideContact([], channel, policy);
        }
        const statuses = await this.loadConsentStatuses(subject, typeIDs, contextUser);
        return DecideContact(statuses, channel, policy);
    }

    /**
     * Records a consent change on one contact method: a history row always, and the current status
     * when the change is the latest one. Saved together.
     */
    public async SetConsent(args: SetConsentArgs, contextUser?: UserInfo): Promise<ConsentChangeResult> {
        const cm = await this.ProviderToUse.GetEntityObject<ContactMethodEntity>(CONTACT_METHODS_ENTITY, contextUser);
        if (!(await cm.Load(args.ContactMethodID))) {
            return { Success: false, StatusChanged: false, ErrorMessage: `Contact method ${args.ContactMethodID} not found` };
        }
        await cm.ConsentHistory.Load();
        const at = args.At ?? new Date();
        const isLatest = IsLatestConsentChange(cm.ConsentHistory.Items, at);
        if (isLatest) {
            cm.ConsentStatus = args.Status;
        }
        const row = await cm.RecordConsentChange(args.Source, at, args.Notes ?? null);
        row.NewConsentStatus = args.Status;
        const saved = await cm.Save();
        return {
            Success: saved,
            StatusChanged: saved && isLatest,
            ErrorMessage: saved ? undefined : cm.LatestResult?.CompleteMessage,
        };
    }

    /**
     * Opts out every contact method whose value is the given email or phone, across people and
     * organizations. This is what an unsubscribe link or a bounce handler calls, since it knows the
     * address and not the record.
     */
    public async OptOutByValue(
        value: string,
        source: string,
        at: Date = new Date(),
        notes: string | null = null,
        contextUser?: UserInfo,
    ): Promise<OptOutByValueResult> {
        const ids = await this.findContactMethodIDsByValue(value, contextUser);
        const result: OptOutByValueResult = { Matched: ids.length, Changed: 0, Errors: [] };
        for (const id of ids) {
            const change = await this.SetConsent({ ContactMethodID: id, Status: 'OptedOut', Source: source, At: at, Notes: notes }, contextUser);
            if (!change.Success) {
                result.Errors.push(`${id}: ${change.ErrorMessage ?? 'unknown error'}`);
            } else if (change.StatusChanged) {
                result.Changed++;
            }
        }
        return result;
    }

    private async loadConsentStatuses(subject: ContactSubject, typeIDs: string[], contextUser?: UserInfo): Promise<ContactConsentStatus[]> {
        const rv = new RunView(this.RunViewProviderToUse);
        const typeList = typeIDs.map((id) => `'${EscapeSQLString(id)}'`).join(',');
        const result = await rv.RunView<Pick<mjBizAppsCommonContactMethodEntity, 'ID' | 'ConsentStatus'>>(
            {
                EntityName: CONTACT_METHODS_ENTITY,
                ExtraFilter: `${this.subjectFilter(subject)} AND ContactTypeID IN (${typeList})`,
                Fields: ['ID', 'ConsentStatus'],
                ResultType: 'simple',
            },
            contextUser,
        );
        if (!result.Success) {
            throw new Error(`ContactPreferenceEngine: could not read contact methods: ${result.ErrorMessage}`);
        }
        return result.Results.map((row) => row.ConsentStatus);
    }

    private async findContactMethodIDsByValue(value: string, contextUser?: UserInfo): Promise<string[]> {
        const trimmed = value.trim();
        if (trimmed.length === 0) {
            return [];
        }
        const rv = new RunView(this.RunViewProviderToUse);
        const result = await rv.RunView<Pick<mjBizAppsCommonContactMethodEntity, 'ID'>>(
            {
                EntityName: CONTACT_METHODS_ENTITY,
                ExtraFilter: `Value = '${EscapeSQLString(trimmed)}'`,
                Fields: ['ID'],
                ResultType: 'simple',
            },
            contextUser,
        );
        if (!result.Success) {
            throw new Error(`ContactPreferenceEngine: could not read contact methods: ${result.ErrorMessage}`);
        }
        return result.Results.map((row) => row.ID);
    }

    private subjectFilter(subject: ContactSubject): string {
        if (subject.PersonID) {
            return `PersonID = '${EscapeSQLString(subject.PersonID)}'`;
        }
        if (subject.OrganizationID) {
            return `OrganizationID = '${EscapeSQLString(subject.OrganizationID)}'`;
        }
        throw new Error('ContactPreferenceEngine: a PersonID or an OrganizationID is required');
    }
}
