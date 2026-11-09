/**
 * ContactMethodConsent with the consent rules built in: `ConsentStatus` never changes without a
 * `ContactMethodConsentHistory` row saying when it took effect, where it came from and who recorded
 * it, and the current status is always the one set by the latest change.
 *
 * The history is the `History` related-record collection CodeGen declares from metadata, so the
 * status and its row save as one unit of work on either tier. `Save` adds the row itself when the
 * status was changed directly (a form edit, a plain `Save()` from code) and nothing has queued one.
 * That row takes the column's default source (Staff) unless a caller set another.
 * `ContactPreferenceEngine.SetConsent` queues the row first, with the caller's source and date, so
 * this override sees it pending and adds nothing.
 *
 * Shared by client and server: the browser's contact method list and the server's send-time hook
 * both get the same guarantee. Registered after the generated class, so the ClassFactory hands
 * this subclass out for `MJ_BizApps_Common: Contact Method Consents`.
 */
import { BaseEntity, EntitySaveOptions } from '@memberjunction/core';
import { RegisterClass } from '@memberjunction/global';
import {
    mjBizAppsCommonContactMethodConsentEntity,
    mjBizAppsCommonContactMethodConsentHistoryEntity,
} from './generated/entity_subclasses';

/**
 * The consent states a contact method can be in. Derived from the generated entity, so it follows
 * `CK_ContactMethodConsent_ConsentStatus` whenever CodeGen regenerates.
 */
export type ContactConsentStatus = mjBizAppsCommonContactMethodConsentEntity['ConsentStatus'];

/** Where a consent change came from. Derived from `CK_ContactMethodConsentHistory_ConsentSource`. */
export type ContactConsentSource = mjBizAppsCommonContactMethodConsentHistoryEntity['ConsentSource'];

/** The two columns of a history row that the history rules need. */
export type ConsentHistoryEntry = Pick<mjBizAppsCommonContactMethodConsentHistoryEntity, 'NewConsentStatus' | 'ConsentStatusAt'>;

type StatusListIsComplete = [Exclude<ContactConsentStatus, (typeof ContactMethodConsentEntity.Statuses)[number]>] extends [never]
    ? true
    : 'ContactMethodConsentEntity.Statuses is missing a value the ConsentStatus CHECK constraint allows';

@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Contact Method Consents')
export class ContactMethodConsentEntity extends mjBizAppsCommonContactMethodConsentEntity {
    /**
     * The consent states as a runtime list, in the order the CHECK constraint names them, for
     * dropdowns. A type cannot produce a list, so this is written out; {@link StatusListComplete}
     * fails the build if the generated union ever has a value this list lacks.
     */
    public static readonly Statuses = ['Not Specified', 'Opted In', 'Opted Out'] as const satisfies readonly ContactConsentStatus[];

    /** Compile-time proof that {@link Statuses} covers the generated union. */
    public static readonly StatusListComplete: StatusListIsComplete = true;

    /** The status a contact method has when nothing was ever recorded. Matches the column default. */
    public static readonly UnspecifiedStatus: ContactConsentStatus = 'Not Specified';

    /**
     * The current status implied by a history: the entry with the latest `ConsentStatusAt`.
     *
     * An empty history means nothing was ever recorded. Two entries at the same instant resolve to
     * the later one in the array, which is the one recorded later.
     */
    public static ResolveCurrentStatus(history: ReadonlyArray<ConsentHistoryEntry>): ContactConsentStatus {
        let latest: ConsentHistoryEntry | null = null;
        for (const entry of history) {
            if (!latest || entry.ConsentStatusAt.getTime() >= latest.ConsentStatusAt.getTime()) {
                latest = entry;
            }
        }
        return latest?.NewConsentStatus ?? ContactMethodConsentEntity.UnspecifiedStatus;
    }

    /**
     * Whether a change that took effect at `at` is the newest one, given the history so far.
     *
     * A change that is not the newest is still recorded, but it does not move the current status.
     * That is how a late-arriving import with an older date is kept without overwriting a newer
     * opt-out.
     */
    public static IsLatestChange(history: ReadonlyArray<ConsentHistoryEntry>, at: Date): boolean {
        return history.every((entry) => entry.ConsentStatusAt.getTime() <= at.getTime());
    }

    /**
     * The source recorded on the history row `Save` adds for a direct status change. Null leaves the
     * column's default, Staff. A caller that knows better (an import, an unsubscribe link) sets it
     * before saving, or queues the row itself with {@link RecordConsentChange}.
     */
    public PendingConsentSource: ContactConsentSource | null = null;

    /** Specifics for that row, such as which system an import came from or a form ID. */
    public PendingConsentDetails: string | null = null;

    /** True when the status differs from what was loaded, or a new record starts off specified. */
    public get ConsentStatusChanged(): boolean {
        const field = this.GetFieldByName('ConsentStatus');
        if (!field) return false;
        if (!this.IsSaved) return this.ConsentStatus !== ContactMethodConsentEntity.UnspecifiedStatus;
        return field.Dirty;
    }

    /** True when an unsaved history row already carries the current status, so `Save` will not add one. */
    public get HasPendingConsentChange(): boolean {
        return this.History.Items.some((row) => !row.IsSaved && row.NewConsentStatus === this.ConsentStatus);
    }

    /** Whether a change dated `at` would be the newest in this consent's loaded history. */
    public IsLatestChange(at: Date): boolean {
        return ContactMethodConsentEntity.IsLatestChange(this.History.Items, at);
    }

    /**
     * Queues the history row for the current `ConsentStatus`, to be saved with this record.
     *
     * The row records who made the change: the request's user on the server, or the logged-in user
     * in the browser, where no request context exists.
     *
     * @param source - Where the change came from. Null keeps the column default, Staff.
     * @param at - When it took effect in the real world. Defaults to now.
     * @param details - Specifics, such as which system an import came from or what Other was.
     * @returns The queued row, so a caller can set anything else on it before saving.
     */
    public async RecordConsentChange(
        source: ContactConsentSource | null = null,
        at: Date = new Date(),
        details: string | null = null,
    ): Promise<mjBizAppsCommonContactMethodConsentHistoryEntity> {
        const row = await this.History.Create();
        row.NewConsentStatus = this.ConsentStatus;
        row.ConsentStatusAt = at;
        if (source) {
            row.ConsentSource = source;
        }
        row.ConsentDetails = details;
        row.RecordedByUserID = this.ActiveUser?.ID ?? null;
        return row;
    }

    public override async Save(options?: EntitySaveOptions): Promise<boolean> {
        if (this.ConsentStatusChanged && !this.HasPendingConsentChange) {
            await this.RecordConsentChange(this.PendingConsentSource, new Date(), this.PendingConsentDetails);
        }
        return super.Save(options);
    }
}
