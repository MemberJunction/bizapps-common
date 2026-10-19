/**
 * Contact preferences: the one place to read and set consent on contact methods.
 *
 * `CanContact` is what Comms' send-time hook calls: for a person or organization, a channel (Email,
 * Phone, SMS), optionally a purpose (Marketing, Transactional, ...) and optionally the organization
 * asking, it rolls the consent of every contact method on that channel into one decision with a
 * reason. Each method answers with its most specific consent, down to its general row.
 * `SetConsent` and `OptOutByValue` write a history row and the current status together, through
 * the consent's `History` collection, so the two can never disagree. A change that arrives with an
 * older date than the latest change is kept in history and leaves the current status alone.
 *
 * The engine caches Contact Types (which carry the link from a type to its channel), MJ core's
 * message types (the channels themselves) and Consent Purposes, so a decision costs one batched
 * read. Call `await ContactPreferenceEngine.Instance.Config(false, user, provider)` where the other
 * engines are configured; the read methods configure lazily if nobody did.
 */
import { BaseEngine, BaseEnginePropertyConfig, IMetadataProvider, RunView, UserInfo } from '@memberjunction/core';
import { EscapeSQLString, UUIDsEqual } from '@memberjunction/global';
import {
    mjBizAppsCommonConsentPurposeEntity,
    mjBizAppsCommonContactConsentEntity,
    mjBizAppsCommonContactMethodEntity,
    mjBizAppsCommonContactTypeEntity,
} from './generated/entity_subclasses';
import {
    ContactChannel,
    ContactConsentStatus,
    ContactDecision,
    ContactDecisionPolicy,
    DecideContact,
    IsLatestConsentChange,
    ResolveConsentForScope,
} from './contact-consent.js';
import { ContactConsentEntity } from './contact-consent-entity.js';

export const CONTACT_TYPES_ENTITY = 'MJ_BizApps_Common: Contact Types';
export const CONTACT_METHODS_ENTITY = 'MJ_BizApps_Common: Contact Methods';
export const CONTACT_CONSENTS_ENTITY = 'MJ_BizApps_Common: Contact Consents';
export const CONSENT_PURPOSES_ENTITY = 'MJ_BizApps_Common: Consent Purposes';
/** MJ core's channel table. Its `Type` column is the key Comms routes on (Email, Phone, SMS). */
export const MESSAGE_TYPES_ENTITY = 'MJ: Communication Base Message Types';

/** The columns of a Contact Types row the engine reads, typed from the generated entity. */
export type ContactTypeChannelRow = Pick<mjBizAppsCommonContactTypeEntity, 'ID' | 'Name' | 'IsActive' | 'CommunicationBaseMessageTypeID'>;

/** The columns of a Consent Purposes row the engine reads. */
export type ConsentPurposeRow = Pick<mjBizAppsCommonConsentPurposeEntity, 'ID' | 'Name' | 'IsActive' | 'DisplayRank'>;

/**
 * The two columns of an `MJ: Communication Base Message Types` row the engine reads. Declared here
 * because this package depends on `@memberjunction/core` only, not on the core entity classes.
 */
export interface MessageTypeRow {
    ID: string;
    Type: string;
}

/** Whose contact methods a decision is about. Exactly one of the two. */
export interface ContactSubject {
    PersonID?: string;
    OrganizationID?: string;
}

/** What a consent is for and who is asking. */
export interface ConsentScope {
    /** The Consent Purpose by name, for example "Marketing"; null / omitted means the general answer for the address. */
    Purpose?: string | null;
    /** The organization asking, or null / omitted for the installation-wide answer. */
    OrganizationID?: string | null;
}

export interface SetConsentArgs extends ConsentScope {
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

type ConsentStatusRow = Pick<mjBizAppsCommonContactConsentEntity, 'ContactMethodID' | 'ConsentPurposeID' | 'OrganizationID' | 'ConsentStatus'>;

export class ContactPreferenceEngine extends BaseEngine<ContactPreferenceEngine> {
    private _contactTypes: ContactTypeChannelRow[] = [];
    private _messageTypes: MessageTypeRow[] = [];
    private _purposes: ConsentPurposeRow[] = [];

    public static get Instance(): ContactPreferenceEngine {
        return super.getInstance<ContactPreferenceEngine>();
    }

    public async Config(forceRefresh?: boolean, contextUser?: UserInfo, provider?: IMetadataProvider): Promise<unknown> {
        const params: Array<Partial<BaseEnginePropertyConfig>> = [
            { PropertyName: '_contactTypes', EntityName: CONTACT_TYPES_ENTITY, ResultType: 'simple' },
            { PropertyName: '_messageTypes', EntityName: MESSAGE_TYPES_ENTITY, ResultType: 'simple' },
            { PropertyName: '_purposes', EntityName: CONSENT_PURPOSES_ENTITY, ResultType: 'simple' },
        ];
        return await this.Load(params, provider as IMetadataProvider, forceRefresh ?? false, contextUser);
    }

    /** The cached Contact Types, each with the ID of the channel it maps to (null for types like LinkedIn). */
    public get ContactTypes(): ContactTypeChannelRow[] {
        return this.GetConfigData<ContactTypeChannelRow>('_contactTypes');
    }

    /** The cached core message types; a channel name resolves to one of these rows' IDs. */
    public get MessageTypes(): MessageTypeRow[] {
        return this.GetConfigData<MessageTypeRow>('_messageTypes');
    }

    /** The cached Consent Purposes, active ones first by display rank. */
    public get Purposes(): ConsentPurposeRow[] {
        return this.GetConfigData<ConsentPurposeRow>('_purposes');
    }

    /** The ID of the core message type whose `Type` key is the channel, or null when core has no such row. */
    public MessageTypeIDForChannel(channel: ContactChannel): string | null {
        return this.MessageTypes.find((m) => m.Type === channel)?.ID ?? null;
    }

    /** IDs of the active contact types linked to the channel's message type, matched on the foreign key. */
    public ContactTypeIDsForChannel(channel: ContactChannel): string[] {
        const messageTypeID = this.MessageTypeIDForChannel(channel);
        if (!messageTypeID) {
            return [];
        }
        return this.ContactTypes
            .filter((t) => t.IsActive && t.CommunicationBaseMessageTypeID != null && UUIDsEqual(t.CommunicationBaseMessageTypeID, messageTypeID))
            .map((t) => t.ID);
    }

    /** The ID of the purpose with this name, or null when the installation has no such purpose. */
    public PurposeIDByName(name: string): string | null {
        const wanted = name.trim().toLowerCase();
        return this.Purposes.find((p) => p.Name.trim().toLowerCase() === wanted)?.ID ?? null;
    }

    /**
     * Whether a person or organization may be contacted on a channel for a purpose, and why.
     *
     * One batched read: the subject's contact methods on that channel, and the consents those
     * methods hold for the purpose. Each method answers with its most specific consent (the asking
     * organization's row, else the installation-wide row, else nothing recorded); the roll-up across
     * methods is {@link DecideContact}.
     */
    public async CanContact(
        subject: ContactSubject,
        channel: ContactChannel,
        scope: ConsentScope,
        policy: ContactDecisionPolicy = {},
        contextUser?: UserInfo,
    ): Promise<ContactDecision> {
        await this.EnsureLoaded(contextUser);
        const typeIDs = this.ContactTypeIDsForChannel(channel);
        if (typeIDs.length === 0) {
            return DecideContact([], channel, policy);
        }
        const purposeID = this.resolvePurposeID(scope);
        const statuses = await this.loadConsentStatuses(subject, typeIDs, purposeID, scope.OrganizationID ?? null, contextUser);
        return DecideContact(statuses, channel, policy);
    }

    /**
     * Records a consent change for one contact method, purpose and (optional) organization: the
     * consent row is created if the method has none for that scope, a history row is always added,
     * and the current status moves when the change is the latest one. Saved together.
     */
    public async SetConsent(args: SetConsentArgs, contextUser?: UserInfo): Promise<ConsentChangeResult> {
        await this.EnsureLoaded(contextUser);
        if (args.Purpose && !this.PurposeIDByName(args.Purpose)) {
            return { Success: false, StatusChanged: false, ErrorMessage: `No consent purpose named '${args.Purpose}'` };
        }
        const consent = await this.findOrCreateConsent(args.ContactMethodID, this.resolvePurposeID(args), args.OrganizationID ?? null, contextUser);
        const at = args.At ?? new Date();
        const isLatest = IsLatestConsentChange(consent.History.Items, at);
        if (isLatest) {
            consent.ConsentStatus = args.Status;
        }
        const row = await consent.RecordConsentChange(args.Source, at, args.Notes ?? null);
        row.NewConsentStatus = args.Status;
        const saved = await consent.Save();
        return {
            Success: saved,
            StatusChanged: saved && isLatest,
            ErrorMessage: saved ? undefined : consent.LatestResult?.CompleteMessage,
        };
    }

    /**
     * Opts out every contact method whose value is the given email or phone, for one purpose (or in
     * general) and (optional) organization, across people and organizations. This is what an unsubscribe link or
     * a bounce handler calls, since it knows the address and not the record. The scope is explicit
     * so an unsubscribe from one organization never opts a person out of another.
     */
    public async OptOutByValue(
        value: string,
        scope: ConsentScope,
        source: string,
        at: Date = new Date(),
        notes: string | null = null,
        contextUser?: UserInfo,
    ): Promise<OptOutByValueResult> {
        const ids = await this.findContactMethodIDsByValue(value, contextUser);
        const result: OptOutByValueResult = { Matched: ids.length, Changed: 0, Errors: [] };
        for (const id of ids) {
            const change = await this.SetConsent({ ...scope, ContactMethodID: id, Status: 'OptedOut', Source: source, At: at, Notes: notes }, contextUser);
            if (!change.Success) {
                result.Errors.push(`${id}: ${change.ErrorMessage ?? 'unknown error'}`);
            } else if (change.StatusChanged) {
                result.Changed++;
            }
        }
        return result;
    }

    /** The purpose ID a scope names, or null for the general answer. Unknown names resolve to null too. */
    private resolvePurposeID(scope: ConsentScope): string | null {
        return scope.Purpose ? this.PurposeIDByName(scope.Purpose) : null;
    }

    private async loadConsentStatuses(
        subject: ContactSubject,
        typeIDs: string[],
        purposeID: string | null,
        organizationID: string | null,
        contextUser?: UserInfo,
    ): Promise<ContactConsentStatus[]> {
        const rv = new RunView(this.RunViewProviderToUse);
        const typeList = typeIDs.map((id) => `'${EscapeSQLString(id)}'`).join(',');
        const methodFilter = `${this.subjectFilter(subject)} AND ContactTypeID IN (${typeList})`;
        const [methods, consents] = await rv.RunViews(
            [
                { EntityName: CONTACT_METHODS_ENTITY, ExtraFilter: methodFilter, Fields: ['ID'], ResultType: 'simple' },
                {
                    EntityName: CONTACT_CONSENTS_ENTITY,
                    ExtraFilter: `${this.purposeFilter(purposeID)} AND ContactMethodID IN (SELECT ID FROM [${this.contactMethodsView()}] WHERE ${methodFilter})`,
                    Fields: ['ContactMethodID', 'ConsentPurposeID', 'OrganizationID', 'ConsentStatus'],
                    ResultType: 'simple',
                },
            ],
            contextUser,
        );
        if (!methods.Success || !consents.Success) {
            throw new Error(`ContactPreferenceEngine: could not read consents: ${methods.ErrorMessage ?? consents.ErrorMessage}`);
        }
        const methodRows = methods.Results as Pick<mjBizAppsCommonContactMethodEntity, 'ID'>[];
        const consentRows = consents.Results as ConsentStatusRow[];
        return methodRows.map((m) => {
            const mine = consentRows.filter((c) => UUIDsEqual(c.ContactMethodID, m.ID));
            return ResolveConsentForScope(mine, { PurposeID: purposeID, OrganizationID: organizationID })?.ConsentStatus ?? 'NotSpecified';
        });
    }

    /** The rows that can answer for a purpose: that purpose's rows and the general (no purpose) rows. */
    private purposeFilter(purposeID: string | null): string {
        return purposeID ? `(ConsentPurposeID='${EscapeSQLString(purposeID)}' OR ConsentPurposeID IS NULL)` : 'ConsentPurposeID IS NULL';
    }

    /** The schema-qualified base view of contact methods, for the subquery in a consent filter. */
    private contactMethodsView(): string {
        const entity = this.ProviderToUse.EntityByName(CONTACT_METHODS_ENTITY);
        if (!entity) {
            throw new Error(`ContactPreferenceEngine: entity '${CONTACT_METHODS_ENTITY}' is not in metadata`);
        }
        return `${entity.SchemaName}].[${entity.BaseView}`;
    }

    private async findOrCreateConsent(
        contactMethodID: string,
        purposeID: string | null,
        organizationID: string | null,
        contextUser?: UserInfo,
    ): Promise<ContactConsentEntity> {
        const rv = new RunView(this.RunViewProviderToUse);
        const purposeFilter = purposeID ? `ConsentPurposeID='${EscapeSQLString(purposeID)}'` : 'ConsentPurposeID IS NULL';
        const orgFilter = organizationID ? `OrganizationID='${EscapeSQLString(organizationID)}'` : 'OrganizationID IS NULL';
        const existing = await rv.RunView<ContactConsentEntity>(
            {
                EntityName: CONTACT_CONSENTS_ENTITY,
                ExtraFilter: `ContactMethodID='${EscapeSQLString(contactMethodID)}' AND ${purposeFilter} AND ${orgFilter}`,
                ResultType: 'entity_object',
            },
            contextUser,
        );
        if (!existing.Success) {
            throw new Error(`ContactPreferenceEngine: could not read consents: ${existing.ErrorMessage}`);
        }
        if (existing.Results.length > 0) {
            const consent = existing.Results[0];
            await consent.History.Load();
            return consent;
        }
        const consent = await this.ProviderToUse.GetEntityObject<ContactConsentEntity>(CONTACT_CONSENTS_ENTITY, contextUser);
        consent.NewRecord();
        consent.ContactMethodID = contactMethodID;
        consent.ConsentPurposeID = purposeID;
        consent.OrganizationID = organizationID;
        return consent;
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
