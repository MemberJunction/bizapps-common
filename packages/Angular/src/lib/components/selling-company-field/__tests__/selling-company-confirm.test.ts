import { describe, expect, it } from 'vitest';

import { SellingCompanyConfirm } from '../selling-company-confirm';

describe('SellingCompanyConfirm', () => {
    it('writes the default without asking', () => {
        const confirm = new SellingCompanyConfirm('default-id');
        expect(confirm.Propose('default-id')).toEqual({ Write: 'default-id', Ask: null });
        expect(confirm.Pending).toBeNull();
    });

    it('treats the default as the same company whatever case the ID arrives in', () => {
        const confirm = new SellingCompanyConfirm('AbC-123');
        expect(confirm.Propose('abc-123')).toEqual({ Write: 'abc-123', Ask: null });
    });

    it('holds any other company for confirmation instead of writing it', () => {
        const confirm = new SellingCompanyConfirm('default-id');
        expect(confirm.Propose('other-id')).toEqual({ Write: null, Ask: 'other-id' });
        expect(confirm.Pending).toBe('other-id');
    });

    it('writes the held value on confirm and clears the pending state', () => {
        const confirm = new SellingCompanyConfirm('default-id');
        confirm.Propose('other-id');
        expect(confirm.Confirm()).toBe('other-id');
        expect(confirm.Pending).toBeNull();
    });

    it('restores the caller-supplied previous value on revert', () => {
        const confirm = new SellingCompanyConfirm('default-id');
        confirm.Propose('other-id');
        expect(confirm.Revert('previous-id')).toBe('previous-id');
        expect(confirm.Pending).toBeNull();
    });

    it('replaces an unanswered question rather than stacking two', () => {
        const confirm = new SellingCompanyConfirm('default-id');
        confirm.Propose('first-id');
        expect(confirm.Propose('second-id').Ask).toBe('second-id');
        expect(confirm.Confirm()).toBe('second-id');
    });

    it('clears a pending question when the user goes back to the default', () => {
        const confirm = new SellingCompanyConfirm('default-id');
        confirm.Propose('other-id');
        expect(confirm.Propose('default-id')).toEqual({ Write: 'default-id', Ask: null });
        expect(confirm.Pending).toBeNull();
    });

    it('always allows clearing the field, since an empty value books nothing', () => {
        const confirm = new SellingCompanyConfirm('default-id');
        expect(confirm.Propose(null)).toEqual({ Write: null, Ask: null });
        expect(confirm.Propose('')).toEqual({ Write: '', Ask: null });
    });

    it('never asks when the instance has no default configured', () => {
        const confirm = new SellingCompanyConfirm(null);
        expect(confirm.Propose('anything')).toEqual({ Write: 'anything', Ask: null });
        expect(confirm.Pending).toBeNull();
    });
});
