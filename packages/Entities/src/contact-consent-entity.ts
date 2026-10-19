/**
 * ContactConsent with the consent rule built in: `ConsentStatus` never changes without a
 * `ContactConsentHistory` row saying when it took effect, where it came from and who recorded it.
 *
 * The history is the `History` related-record collection CodeGen declares from metadata, so the
 * status and its row save as one unit of work on either tier. `Save` adds the row itself when the
 * status was changed directly (a form edit, a plain `Save()` from code) and nothing has queued one,
 * with source `Staff`. `ContactPreferenceEngine.SetConsent` queues the row first, with the caller's
 * source and date, so this override sees it pending and adds nothing.
 *
 * Shared by client and server: the browser's contact method list and the server's send-time hook
 * both get the same guarantee. Registered after the generated class, so the ClassFactory hands
 * this subclass out for `MJ_BizApps_Common: Contact Consents`.
 */
import { BaseEntity, EntitySaveOptions } from '@memberjunction/core';
import { RegisterClass } from '@memberjunction/global';
import { mjBizAppsCommonContactConsentEntity, mjBizAppsCommonContactConsentHistoryEntity } from './generated/entity_subclasses';
import { CONSENT_SOURCE_STAFF } from './contact-consent.js';

@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Contact Consents')
export class ContactConsentEntity extends mjBizAppsCommonContactConsentEntity {
    /**
     * The source recorded on the history row `Save` adds for a direct status change. A caller that
     * knows better than `Staff` (an import, an unsubscribe link) sets it before saving, or queues
     * the row itself with {@link RecordConsentChange}.
     */
    public PendingConsentSource: string = CONSENT_SOURCE_STAFF;

    /** Evidence to put on that row, such as a form ID or an email's message ID. */
    public PendingConsentNotes: string | null = null;

    /** True when the status differs from what was loaded, or a new record starts off specified. */
    public get ConsentStatusChanged(): boolean {
        const field = this.GetFieldByName('ConsentStatus');
        if (!field) return false;
        if (!this.IsSaved) return this.ConsentStatus !== 'NotSpecified';
        return field.Dirty;
    }

    /** True when an unsaved history row already carries the current status, so `Save` will not add one. */
    public get HasPendingConsentChange(): boolean {
        return this.History.Items.some((row) => !row.IsSaved && row.NewConsentStatus === this.ConsentStatus);
    }

    /**
     * Queues the history row for the current `ConsentStatus`, to be saved with this record.
     *
     * @param source - Where the change came from, for example "Web signup" or "Import: CRM".
     * @param at - When it took effect in the real world. Defaults to now.
     * @param notes - Evidence for the change.
     * @returns The queued row, so a caller can set anything else on it before saving.
     */
    public async RecordConsentChange(
        source: string,
        at: Date = new Date(),
        notes: string | null = null,
    ): Promise<mjBizAppsCommonContactConsentHistoryEntity> {
        const row = await this.History.Create();
        row.NewConsentStatus = this.ConsentStatus;
        row.ConsentStatusAt = at;
        row.ConsentSource = source;
        row.RecordedByUserID = this.ContextCurrentUser?.ID ?? null;
        row.Notes = notes;
        return row;
    }

    public override async Save(options?: EntitySaveOptions): Promise<boolean> {
        if (this.ConsentStatusChanged && !this.HasPendingConsentChange) {
            await this.RecordConsentChange(this.PendingConsentSource, new Date(), this.PendingConsentNotes);
        }
        return super.Save(options);
    }
}
