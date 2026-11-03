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
    mjBizAppsCommonContactMethodConsentEntity,
    mjBizAppsCommonContactMethodEntity,
    mjBizAppsCommonContactTypeEntity,
} from './generated/entity_subclasses';
import { ContactConsentSource, ContactConsentStatus, ContactMethodConsentEntity } from './contact-method-consent-entity.js';

/** A channel Comms can ask about. Each is the `Type` key of a row MJ core seeds in `MJ: Communication Base Message Types`. */
export type ContactChannel = (typeof ContactPreferenceEngine.Channels)[number];

/** The columns of a Contact Types row the engine reads, typed from the generated entity. */
export type ContactTypeChannelRow = Pick<mjBizAppsCommonContactTypeEntity, 'ID' | 'Name' | 'IsActive' | 'CommunicationBaseMessageTypeID'>;

/** The columns of a Consent Purposes row the engine reads. */
export type ConsentPurposeRow = Pick<mjBizAppsCommonConsentPurposeEntity, 'ID' | 'Name' | 'IsActive' | 'Sequence'>;

/** The columns of a consent row that scoping and decisions need. */
export type ConsentRow = Pick<mjBizAppsCommonContactMethodConsentEntity, 'ContactMethodID' | 'ConsentPurposeID' | 'RequestingOrganizationID' | 'ConsentStatus'>;

/**
 * The two columns of an `MJ: Communication Base Message Types` row the engine reads. Declared here
 * because this package depends on `@memberjunction/core` only, not on the core entity classes.
 */
export interface MessageTypeRow {
    ID: string;
    Type: string;
}

/** Whose contact methods a decision is about. Exactly one of the two: the owner of the addresses. */
export interface ContactSubject {
    PersonID?: string;
    OrganizationID?: string;
}

/** What a consent is for and who is asking, by name. */
export interface ConsentScope {
    /** The Consent Purpose by name, for example "Marketing"; null / omitted means the general answer for the address. */
    Purpose?: string | null;
    /** The organization asking, or null / omitted for the installation-wide answer. */
    RequestingOrganizationID?: string | null;
}

/** The same question, resolved to IDs, as the scope ladder reads it. */
export interface ConsentScopeKey {
    /** The Consent Purpose ID, or null / omitted for the general answer ("anything"). */
    PurposeID?: string | null;
    /** The organization asking, or null / omitted for the installation-wide answer. */
    RequestingOrganizationID?: string | null;
}

export interface SetConsentArgs extends ConsentScope {
    ContactMethodID: string;
    Status: ContactConsentStatus;
    /** Where the change came from. Omitted means the column default, Staff. */
    Source?: ContactConsentSource;
    /** Specifics, such as which system an import came from, a form ID, or what Other was. */
    Details?: string | null;
    /** When it took effect in the real world. Defaults to now. */
    At?: Date;
}

/** Why a channel decision came out the way it did. */
export type ContactDecisionStatus =
    /** Opted In: a method on the channel is opted in. Opted Out: every method is. Not Specified: nothing opted in and something unrecorded. */
    | ContactConsentStatus
    /** The person or organization has no contact method on that channel at all. */
    | 'No Contact Method'
    /** The caller named a purpose the installation does not have. Refused rather than answered from the general consent. */
    | 'Unknown Purpose';

export interface ContactDecision {
    /** Whether a message may be sent on the channel. */
    Allowed: boolean;
    Status: ContactDecisionStatus;
    /** A short sentence for the send log, so a skipped recipient says why. */
    Reason: string;
}

export interface ContactDecisionPolicy {
    /**
     * When true, only an explicit opt-in allows contact; Not Specified is treated like an opt-out.
     * Off by default, because every contact method predating this feature has no consent recorded
     * and a strict default would silently stop all sends on upgrade.
     */
    RequireOptIn?: boolean;
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
    /** Of those, how many had their current status moved to Opted Out. */
    Changed: number;
    Errors: string[];
}

export class ContactPreferenceEngine extends BaseEngine<ContactPreferenceEngine> {
    /**
     * The channels Comms can ask about. The engine resolves a channel to its core message type's ID
     * and matches contact types on that foreign key, never on a name.
     */
    public static readonly Channels = ['Email', 'Phone', 'SMS'] as const;

    private static readonly CONTACT_TYPES_ENTITY = 'MJ_BizApps_Common: Contact Types';
    private static readonly CONTACT_METHODS_ENTITY = 'MJ_BizApps_Common: Contact Methods';
    private static readonly CONSENTS_ENTITY = 'MJ_BizApps_Common: Contact Method Consents';
    private static readonly PURPOSES_ENTITY = 'MJ_BizApps_Common: Consent Purposes';
    /** MJ core's channel table. Its `Type` column is the key Comms routes on (Email, Phone, SMS). */
    private static readonly MESSAGE_TYPES_ENTITY = 'MJ: Communication Base Message Types';

    private _contactTypes: ContactTypeChannelRow[] = [];
    private _messageTypes: MessageTypeRow[] = [];
    private _purposes: ConsentPurposeRow[] = [];

    public static get Instance(): ContactPreferenceEngine {
        return super.getInstance<ContactPreferenceEngine>();
    }

    /**
     * Of one contact method's consent rows, the row that answers a question, most specific first:
     *
     * 1. this purpose, this organization;
     * 2. this purpose, any organization;
     * 3. any purpose, this organization;
     * 4. any purpose, any organization (the general row);
     * 5. nothing, when none of those exist.
     *
     * A question with no purpose starts at rung 3; one with no organization skips rungs 1 and 3.
     * General never means default: a general opt-in loses to a Marketing opt-out for a Marketing send.
     */
    public static ResolveConsentForScope<T extends ConsentRow>(rows: ReadonlyArray<T>, scope: ConsentScopeKey): T | null {
        const purposeID = scope.PurposeID ?? null;
        const organizationID = scope.RequestingOrganizationID ?? null;
        const find = (p: string | null, o: string | null): T | null =>
            rows.find((r) => UUIDsEqual(r.ConsentPurposeID, p) && UUIDsEqual(r.RequestingOrganizationID, o)) ?? null;
        if (purposeID) {
            const exact = organizationID ? find(purposeID, organizationID) : null;
            if (exact) return exact;
            const anyOrg = find(purposeID, null);
            if (anyOrg) return anyOrg;
        }
        const generalForOrg = organizationID ? find(null, organizationID) : null;
        return generalForOrg ?? find(null, null);
    }

    /**
     * Rolls the statuses of every contact method on one channel into one decision.
     *
     * An opt-in anywhere wins, because the person said yes on at least one address. With nothing
     * opted in, an unspecified status allows contact unless the policy requires an explicit opt-in.
     * Opt-outs only block when nothing else is available.
     */
    public static DecideContact(
        statuses: ReadonlyArray<ContactConsentStatus>,
        channel: ContactChannel,
        policy: ContactDecisionPolicy = {},
    ): ContactDecision {
        if (statuses.length === 0) {
            return { Allowed: false, Status: 'No Contact Method', Reason: `No ${channel} contact method on record.` };
        }
        if (statuses.includes('Opted In')) {
            return { Allowed: true, Status: 'Opted In', Reason: `Opted in on ${channel}.` };
        }
        if (statuses.includes('Not Specified')) {
            const allowed = policy.RequireOptIn !== true;
            return {
                Allowed: allowed,
                Status: 'Not Specified',
                Reason: allowed
                    ? `No consent recorded on ${channel}; allowed because an explicit opt-in is not required.`
                    : `No consent recorded on ${channel}; an explicit opt-in is required.`,
            };
        }
        return { Allowed: false, Status: 'Opted Out', Reason: `Opted out on ${channel}.` };
    }

    public async Config(forceRefresh?: boolean, contextUser?: UserInfo, provider?: IMetadataProvider): Promise<unknown> {
        const params: Array<Partial<BaseEnginePropertyConfig>> = [
            { PropertyName: '_contactTypes', EntityName: ContactPreferenceEngine.CONTACT_TYPES_ENTITY, ResultType: 'simple' },
            { PropertyName: '_messageTypes', EntityName: ContactPreferenceEngine.MESSAGE_TYPES_ENTITY, ResultType: 'simple' },
            { PropertyName: '_purposes', EntityName: ContactPreferenceEngine.PURPOSES_ENTITY, ResultType: 'simple' },
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

    /** The cached Consent Purposes. */
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
            .filter((t) => t.IsActive && UUIDsEqual(t.CommunicationBaseMessageTypeID, messageTypeID))
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
     * A purpose name the installation does not have is refused with status Unknown Purpose, never
     * answered from the general consent, so a misspelt purpose cannot read a general opt-in as
     * permission. Otherwise one batched read: the subject's contact methods on that channel and
     * the consents that can answer; each method answers with {@link ResolveConsentForScope}, and the
     * roll-up across methods is {@link DecideContact}.
     */
    public async CanContact(
        subject: ContactSubject,
        channel: ContactChannel,
        scope: ConsentScope,
        policy: ContactDecisionPolicy = {},
        contextUser?: UserInfo,
    ): Promise<ContactDecision> {
        await this.EnsureLoaded(contextUser);
        if (this.isUnknownPurpose(scope)) {
            return { Allowed: false, Status: 'Unknown Purpose', Reason: `No consent purpose named '${scope.Purpose}'.` };
        }
        const typeIDs = this.ContactTypeIDsForChannel(channel);
        if (typeIDs.length === 0) {
            return ContactPreferenceEngine.DecideContact([], channel, policy);
        }
        const key: ConsentScopeKey = { PurposeID: this.resolvePurposeID(scope), RequestingOrganizationID: scope.RequestingOrganizationID ?? null };
        const statuses = await this.loadConsentStatuses(subject, typeIDs, key, contextUser);
        return ContactPreferenceEngine.DecideContact(statuses, channel, policy);
    }

    /**
     * Records a consent change for one contact method, purpose and (optional) organization: the
     * consent row is created if the method has none for that scope, a history row is always added,
     * and the current status moves when the change is the latest one. Saved together.
     */
    public async SetConsent(args: SetConsentArgs, contextUser?: UserInfo): Promise<ConsentChangeResult> {
        await this.EnsureLoaded(contextUser);
        if (this.isUnknownPurpose(args)) {
            return { Success: false, StatusChanged: false, ErrorMessage: `No consent purpose named '${args.Purpose}'` };
        }
        const consent = await this.findOrCreateConsent(args.ContactMethodID, this.resolvePurposeID(args), args.RequestingOrganizationID ?? null, contextUser);
        const at = args.At ?? new Date();
        const isLatest = consent.IsLatestChange(at);
        if (isLatest) {
            consent.ConsentStatus = args.Status;
        }
        const row = await consent.RecordConsentChange(args.Source ?? null, at, args.Details ?? null);
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
     * general) and (optional) organization, across people and organizations. This is what an
     * unsubscribe link or a bounce handler calls, since it knows the address and not the record.
     * The scope is explicit so an unsubscribe from one organization never opts a person out of another.
     */
    public async OptOutByValue(
        value: string,
        scope: ConsentScope,
        source: ContactConsentSource,
        at: Date = new Date(),
        details: string | null = null,
        contextUser?: UserInfo,
    ): Promise<OptOutByValueResult> {
        const ids = await this.findContactMethodIDsByValue(value, contextUser);
        const result: OptOutByValueResult = { Matched: ids.length, Changed: 0, Errors: [] };
        for (const id of ids) {
            const change = await this.SetConsent(
                { ...scope, ContactMethodID: id, Status: 'Opted Out', Source: source, Details: details, At: at },
                contextUser,
            );
            if (!change.Success) {
                result.Errors.push(`${id}: ${change.ErrorMessage ?? 'unknown error'}`);
            } else if (change.StatusChanged) {
                result.Changed++;
            }
        }
        return result;
    }

    /** True when a scope names a purpose the installation does not have. */
    private isUnknownPurpose(scope: ConsentScope): boolean {
        return !!scope.Purpose && !this.PurposeIDByName(scope.Purpose);
    }

    /** The purpose ID a scope names, or null for the general answer. Call {@link isUnknownPurpose} first. */
    private resolvePurposeID(scope: ConsentScope): string | null {
        return scope.Purpose ? this.PurposeIDByName(scope.Purpose) : null;
    }

    private async loadConsentStatuses(
        subject: ContactSubject,
        typeIDs: string[],
        key: ConsentScopeKey,
        contextUser?: UserInfo,
    ): Promise<ContactConsentStatus[]> {
        const rv = new RunView(this.RunViewProviderToUse);
        const typeList = typeIDs.map((id) => `'${EscapeSQLString(id)}'`).join(',');
        const methodFilter = `${this.subjectFilter(subject)} AND ContactTypeID IN (${typeList})`;
        const [methods, consents] = await rv.RunViews(
            [
                { EntityName: ContactPreferenceEngine.CONTACT_METHODS_ENTITY, ExtraFilter: methodFilter, Fields: ['ID'], ResultType: 'simple' },
                {
                    EntityName: ContactPreferenceEngine.CONSENTS_ENTITY,
                    ExtraFilter: `${this.purposeFilter(key.PurposeID ?? null)} AND ContactMethodID IN (SELECT ID FROM [${this.contactMethodsView()}] WHERE ${methodFilter})`,
                    Fields: ['ContactMethodID', 'ConsentPurposeID', 'RequestingOrganizationID', 'ConsentStatus'],
                    ResultType: 'simple',
                },
            ],
            contextUser,
        );
        if (!methods.Success || !consents.Success) {
            throw new Error(`ContactPreferenceEngine: could not read consents: ${methods.ErrorMessage ?? consents.ErrorMessage}`);
        }
        const methodRows = methods.Results as Pick<mjBizAppsCommonContactMethodEntity, 'ID'>[];
        const consentRows = consents.Results as ConsentRow[];
        return methodRows.map((m) => {
            const mine = consentRows.filter((c) => UUIDsEqual(c.ContactMethodID, m.ID));
            return ContactPreferenceEngine.ResolveConsentForScope(mine, key)?.ConsentStatus ?? ContactMethodConsentEntity.UnspecifiedStatus;
        });
    }

    /** The rows that can answer for a purpose: that purpose's rows and the general (no purpose) rows. */
    private purposeFilter(purposeID: string | null): string {
        return purposeID ? `(ConsentPurposeID='${EscapeSQLString(purposeID)}' OR ConsentPurposeID IS NULL)` : 'ConsentPurposeID IS NULL';
    }

    /** The schema-qualified base view of contact methods, for the subquery in a consent filter. */
    private contactMethodsView(): string {
        const entity = this.ProviderToUse.EntityByName(ContactPreferenceEngine.CONTACT_METHODS_ENTITY);
        if (!entity) {
            throw new Error(`ContactPreferenceEngine: entity '${ContactPreferenceEngine.CONTACT_METHODS_ENTITY}' is not in metadata`);
        }
        return `${entity.SchemaName}].[${entity.BaseView}`;
    }

    private async findOrCreateConsent(
        contactMethodID: string,
        purposeID: string | null,
        requestingOrganizationID: string | null,
        contextUser?: UserInfo,
    ): Promise<ContactMethodConsentEntity> {
        const rv = new RunView(this.RunViewProviderToUse);
        const purposeFilter = purposeID ? `ConsentPurposeID='${EscapeSQLString(purposeID)}'` : 'ConsentPurposeID IS NULL';
        const orgFilter = requestingOrganizationID
            ? `RequestingOrganizationID='${EscapeSQLString(requestingOrganizationID)}'`
            : 'RequestingOrganizationID IS NULL';
        const existing = await rv.RunView<ContactMethodConsentEntity>(
            {
                EntityName: ContactPreferenceEngine.CONSENTS_ENTITY,
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
        const consent = await this.ProviderToUse.GetEntityObject<ContactMethodConsentEntity>(ContactPreferenceEngine.CONSENTS_ENTITY, contextUser);
        consent.NewRecord();
        consent.ContactMethodID = contactMethodID;
        consent.ConsentPurposeID = purposeID;
        consent.RequestingOrganizationID = requestingOrganizationID;
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
                EntityName: ContactPreferenceEngine.CONTACT_METHODS_ENTITY,
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

    /** Filters contact methods by their owner: the person or organization the addresses belong to. */
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
