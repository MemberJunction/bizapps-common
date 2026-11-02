/**
 * @fileoverview Shared subclass of the generated Company Sender Identity entity.
 *
 * It lives in this package, not in `Server`, so the browser form and the server save path run the
 * same normaliser: an address typed as `  HR@Acme.com ` is stored as `hr@acme.com` on both sides,
 * and the rule is never copied into a second place.
 *
 * `Validate()` is the only refusal point. The base `Save` also validates, but a normalised value
 * must be written to the fields first, so `Save` here normalises, validates, and records a failed
 * result itself the way `BaseEntity` records one (a `BaseEntityResult` on the result history).
 */
import { BaseEntity, BaseEntityResult, EntitySaveOptions, ValidationResult } from '@memberjunction/core';
import { RegisterClass, ValidationErrorInfo } from '@memberjunction/global';
import { mjBizAppsCommonCompanySenderIdentityEntity } from './generated/entity_subclasses';
import { NormalizeSenderIdentity, NormalizedSenderIdentity } from './sender-identity.js';

@RegisterClass(BaseEntity, 'MJ_BizApps_Common: Company Sender Identities')
export class CompanySenderIdentityEntity extends mjBizAppsCommonCompanySenderIdentityEntity {
    /**
     * Adds one error per normaliser complaint. A row with a `Kind` outside Mailbox/Domain is left
     * to the base validator (the generated value-list check), which already reports it.
     */
    public override Validate(): ValidationResult {
        const result = super.Validate();
        this.validateDefaultIsMailbox(result);
        const normalized = this.normalize();
        if (normalized === null) return result;
        const displayNameErrors = new Set(normalized.displayNameErrors);
        for (const message of normalized.errors) {
            const source = displayNameErrors.has(message) ? 'DisplayName' : 'Address';
            const value = source === 'DisplayName' ? this.DisplayName : this.Address;
            result.Errors.push(new ValidationErrorInfo(source, message, value));
        }
        if (normalized.errors.length > 0) result.Success = false;
        return result;
    }

    /** A default must be a Mailbox row: a Domain has no local part to send from (spec section 7). */
    private validateDefaultIsMailbox(result: ValidationResult): void {
        if (!this.IsDefault || this.Kind !== 'Domain') return;
        const message = `"${this.Address}" is a Domain row and cannot be the default sender; only a Mailbox row can be the default`;
        result.Errors.push(new ValidationErrorInfo('IsDefault', message, this.IsDefault));
        result.Success = false;
    }

    /** Writes the normalised Address/DisplayName, then saves; refuses (returns false) when invalid. */
    public override async Save(options?: EntitySaveOptions): Promise<boolean> {
        const normalized = this.normalize();
        if (normalized !== null) {
            this.Address = normalized.address;
            this.DisplayName = normalized.displayName;
        }
        // Refuse before the base ReplayOnly / not-dirty short-circuits on purpose: an invalid row is
        // never worth saving, even when it is unchanged.
        const validation = this.Validate();
        if (!validation.Success) {
            this.recordValidationFailure(validation);
            return false;
        }
        return super.Save(options);
    }

    /** Null when `Kind` is not one of the two known kinds; `Validate` reports that case. */
    private normalize(): NormalizedSenderIdentity | null {
        if (this.Kind !== 'Mailbox' && this.Kind !== 'Domain') return null;
        return NormalizeSenderIdentity(this.Kind, this.Address ?? '', this.DisplayName);
    }

    private recordValidationFailure(validation: ValidationResult): void {
        const result = new BaseEntityResult();
        result.Success = false;
        result.Type = this.IsSaved ? 'update' : 'create';
        result.Message = `Company Sender Identity "${this.Address}" for company ${this.CompanyID} refused: ${validation.Errors.map((e) => e.Message).join('; ')}`;
        result.Errors = validation.Errors;
        result.MessageIncludesErrors = true;
        result.EndedAt = new Date();
        this.RegisterResultHistoryEntry(result);
    }
}
