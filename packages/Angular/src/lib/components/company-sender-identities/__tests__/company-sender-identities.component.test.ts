import '@angular/compiler';
import { ChangeDetectorRef, Injector, runInInjectionContext } from '@angular/core';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { IMetadataProvider } from '@memberjunction/core';
import { MJConfirmService } from '@memberjunction/ng-ui-components';
import type { CompanySenderIdentityEntity } from '@mj-biz-apps/common-entities';

const H = vi.hoisted(() => ({
    runView: vi.fn(),
}));

vi.mock('@memberjunction/core', async (importOriginal) => {
    const actual = await importOriginal<object>();
    return {
        ...actual,
        RunView: { FromMetadataProvider: () => ({ RunView: H.runView }) },
    };
});

import { CompanySenderIdentitiesComponent } from '../company-sender-identities.component';

/** The fields and methods of a sender-identity row the widget touches. */
interface FakeRow {
    ID: string;
    CompanyID: string;
    Kind: CompanySenderIdentityEntity['Kind'];
    Address: string;
    DisplayName: string | null;
    IsDefault: boolean;
    LatestResult: { Message: string; CompleteMessage: string } | null;
    Save: ReturnType<typeof vi.fn>;
    Delete: ReturnType<typeof vi.fn>;
}

function row(id: string, address: string, isDefault: boolean, kind: CompanySenderIdentityEntity['Kind'] = 'Mailbox'): FakeRow {
    return {
        ID: id,
        CompanyID: 'co-1',
        Kind: kind,
        Address: address,
        DisplayName: null,
        IsDefault: isDefault,
        LatestResult: null,
        Save: vi.fn(async () => true),
        Delete: vi.fn(async () => true),
    };
}

function asEntity(r: FakeRow): CompanySenderIdentityEntity {
    return r as unknown as CompanySenderIdentityEntity;
}

interface Harness {
    component: CompanySenderIdentitiesComponent;
    getEntityObject: ReturnType<typeof vi.fn>;
    confirmDelete: ReturnType<typeof vi.fn>;
}

/**
 * `inject()` needs an injection context; a small injector gives it one without TestBed.
 * These are unit tests of the load/add/default/remove logic, not of rendering.
 */
function build(rows: FakeRow[], newRow?: FakeRow): Harness {
    H.runView.mockResolvedValue({ Success: true, Results: rows });
    const getEntityObject = vi.fn(async () => newRow);
    const confirmDelete = vi.fn(async () => true);
    const injector = Injector.create({
        providers: [
            { provide: ChangeDetectorRef, useValue: { detectChanges: () => undefined } },
            { provide: MJConfirmService, useValue: { ConfirmDelete: confirmDelete } },
        ],
    });
    const component = runInInjectionContext(injector, () => new CompanySenderIdentitiesComponent());
    component.CompanyID = 'co-1';
    component.Provider = { CurrentUser: { ID: 'u1' }, GetEntityObject: getEntityObject } as unknown as IMetadataProvider;
    return { component, getEntityObject, confirmDelete };
}

describe('CompanySenderIdentitiesComponent', () => {
    beforeEach(() => {
        H.runView.mockReset();
    });

    it('loadAll runs one RunView filtered by CompanyID and exposes the rows', async () => {
        const rows = [row('r1', 'hr@acme.com', true), row('r2', 'acme.com', false, 'Domain')];
        const { component } = build(rows);

        await component.loadAll();

        expect(H.runView).toHaveBeenCalledTimes(1);
        const params = H.runView.mock.calls[0][0] as { EntityName: string; ExtraFilter: string; OrderBy: string; BypassCache?: boolean };
        expect(params.EntityName).toBe('MJ_BizApps_Common: Company Sender Identities');
        expect(params.ExtraFilter).toContain("CompanyID = 'co-1'");
        // Keeps the read out of the client coalescer, where another component's failing query rejects it.
        expect(params.BypassCache).toBe(true);
        expect(params.OrderBy).toContain('Address');
        expect(component.Rows.map((r) => r.ID)).toEqual(['r1', 'r2']);
        expect(component.Loading).toBe(false);
        expect(component.Error).toBeNull();
    });

    it('loadAll escapes the company ID in the filter', async () => {
        const { component } = build([]);
        component.CompanyID = "co-1' OR 1=1 --";

        await component.loadAll();

        const params = H.runView.mock.calls[0][0] as { ExtraFilter: string };
        expect(params.ExtraFilter).toBe("CompanyID = 'co-1'' OR 1=1 --'");
    });

    it('addRow refuses a malformed address before any save and shows the error', async () => {
        const { component, getEntityObject } = build([]);

        const added = await component.addRow('Mailbox', 'not-an-address', null);

        expect(added).toBe(false);
        expect(getEntityObject).not.toHaveBeenCalled();
        expect(component.Error).toContain('not-an-address');
    });

    it('addRow refuses an address already listed, in any case, before any save', async () => {
        const { component, getEntityObject } = build([row('r1', 'hr@acme.com', false)]);
        await component.loadAll();

        const added = await component.addRow('Mailbox', ' HR@ACME.com ', null);

        expect(added).toBe(false);
        expect(getEntityObject).not.toHaveBeenCalled();
        expect(component.Error).toContain('"hr@acme.com" is already in this company\'s senders');
    });

    it('cancelAdd closes the form and clears its validation error', async () => {
        const { component } = build([]);
        component.openAddForm('Mailbox');
        await component.addRow('Mailbox', 'not-an-address', null);
        expect(component.Error).not.toBeNull();

        component.cancelAdd();

        expect(component.ShowAddForm).toBe(false);
        expect(component.Error).toBeNull();
    });

    it('addRow saves a valid sender, shows the verification reminder and emits DataChanged', async () => {
        const created = row('new', '', false);
        const { component } = build([], created);
        const emitted = vi.fn();
        component.DataChanged.subscribe(emitted);

        const added = await component.addRow('Mailbox', ' HR@Acme.com ', 'Acme HR');

        expect(added).toBe(true);
        expect(created.Kind).toBe('Mailbox');
        expect(created.Address).toBe('hr@acme.com');
        expect(created.DisplayName).toBe('Acme HR');
        expect(created.CompanyID).toBe('co-1');
        expect(created.Save).toHaveBeenCalledTimes(1);
        expect(component.Notice).toBe('Make sure this sender is verified in your mail provider before using it.');
        expect(emitted).toHaveBeenCalledTimes(1);
    });

    it('addRow reports a saved row whose list reload failed, and still emits DataChanged', async () => {
        const created = row('new', '', false);
        const { component } = build([], created);
        H.runView.mockResolvedValue({ Success: false, ErrorMessage: 'connection reset', Results: [] });
        const emitted = vi.fn();
        component.DataChanged.subscribe(emitted);
        const errorLog = vi.spyOn(console, 'error').mockImplementation(() => undefined);

        const added = await component.addRow('Mailbox', 'hr@acme.com', null);

        expect(added).toBe(true);
        expect(created.Save).toHaveBeenCalledTimes(1);
        expect(component.Error).toContain('Saved');
        expect(component.Error).toContain('hr@acme.com');
        expect(component.Error).toContain('could not be reloaded');
        expect(emitted).toHaveBeenCalledTimes(1);
        expect(errorLog).toHaveBeenCalledWith('[CompanySenderIdentities]', component.Error, expect.any(Error));
        errorLog.mockRestore();
    });

    it('addRow reports a failed save with the address', async () => {
        const created = row('new', '', false);
        created.Save.mockResolvedValue(false);
        created.LatestResult = { Message: 'duplicate key', CompleteMessage: 'duplicate key' };
        const { component } = build([], created);

        const added = await component.addRow('Mailbox', 'hr@acme.com', null);

        expect(added).toBe(false);
        expect(component.Error).toContain('hr@acme.com');
        expect(component.Error).toContain('duplicate key');
        expect(component.Notice).toBeNull();
    });

    it('setDefault demotes the current default before promoting the chosen row', async () => {
        const current = row('r1', 'old@acme.com', true);
        const chosen = row('r2', 'new@acme.com', false);
        const saves: string[] = [];
        current.Save.mockImplementation(async () => {
            saves.push(`${current.Address}:${current.IsDefault}`);
            return true;
        });
        chosen.Save.mockImplementation(async () => {
            saves.push(`${chosen.Address}:${chosen.IsDefault}`);
            return true;
        });
        const { component } = build([current, chosen]);
        await component.loadAll();
        const emitted = vi.fn();
        component.DataChanged.subscribe(emitted);

        const ok = await component.setDefault(asEntity(chosen));

        expect(ok).toBe(true);
        expect(saves).toEqual(['old@acme.com:false', 'new@acme.com:true']);
        expect(emitted).toHaveBeenCalledTimes(1);
    });

    it('setDefault reports a failed demote with the address and stops', async () => {
        const current = row('r1', 'old@acme.com', true);
        current.Save.mockResolvedValue(false);
        current.LatestResult = { Message: 'locked', CompleteMessage: 'locked' };
        const chosen = row('r2', 'new@acme.com', false);
        const { component } = build([current, chosen]);
        await component.loadAll();

        const ok = await component.setDefault(asEntity(chosen));

        expect(ok).toBe(false);
        expect(component.Error).toContain('old@acme.com');
        expect(chosen.Save).not.toHaveBeenCalled();
        expect(current.IsDefault).toBe(true);
    });

    it('setDefault reports a failed promote with the chosen address', async () => {
        const current = row('r1', 'old@acme.com', true);
        const chosen = row('r2', 'new@acme.com', false);
        chosen.Save.mockResolvedValue(false);
        chosen.LatestResult = { Message: 'boom', CompleteMessage: 'boom' };
        const { component } = build([current, chosen]);
        await component.loadAll();

        const ok = await component.setDefault(asEntity(chosen));

        expect(ok).toBe(false);
        expect(component.Error).toContain('new@acme.com');
        expect(chosen.IsDefault).toBe(false);
    });

    it('setDefault refuses a Domain row without saving', async () => {
        const domain = row('r1', 'acme.com', false, 'Domain');
        const { component } = build([domain]);
        await component.loadAll();

        expect(await component.setDefault(asEntity(domain))).toBe(false);
        expect(domain.Save).not.toHaveBeenCalled();
    });

    it('removeRow deletes and emits DataChanged', async () => {
        const target = row('r1', 'hr@acme.com', false);
        const { component, confirmDelete } = build([target]);
        await component.loadAll();
        const emitted = vi.fn();
        component.DataChanged.subscribe(emitted);

        const removed = await component.removeRow(asEntity(target));

        expect(removed).toBe(true);
        expect(confirmDelete).toHaveBeenCalledTimes(1);
        expect(target.Delete).toHaveBeenCalledTimes(1);
        expect(emitted).toHaveBeenCalledTimes(1);
    });

    // BaseEntity resets a deleted object's fields, so a row left in the list until the reload
    // finishes re-renders with a changed value (Angular NG0100 in dev mode).
    it('removeRow drops the deleted row from the list even when the reload after it fails', async () => {
        const keep = row('r1', 'keep@acme.com', false);
        const target = row('r2', 'gone@acme.com', false);
        const { component } = build([keep, target]);
        await component.loadAll();
        H.runView.mockRejectedValueOnce(new Error('connection reset'));
        const errorLog = vi.spyOn(console, 'error').mockImplementation(() => undefined);

        expect(await component.removeRow(asEntity(target))).toBe(true);

        expect(component.Rows.map((r) => r.ID)).toEqual(['r1']);
        errorLog.mockRestore();
    });

    it('removeRow does nothing when the user cancels the confirmation', async () => {
        const target = row('r1', 'hr@acme.com', false);
        const { component, confirmDelete } = build([target]);
        confirmDelete.mockResolvedValue(false);
        await component.loadAll();

        expect(await component.removeRow(asEntity(target))).toBe(false);
        expect(target.Delete).not.toHaveBeenCalled();
    });

    it('removeRow reports a failed delete with the address', async () => {
        const target = row('r1', 'hr@acme.com', false);
        target.Delete.mockResolvedValue(false);
        target.LatestResult = { Message: 'in use', CompleteMessage: 'in use' };
        const { component } = build([target]);
        await component.loadAll();

        expect(await component.removeRow(asEntity(target))).toBe(false);
        expect(component.Error).toContain('hr@acme.com');
        expect(component.Error).toContain('in use');
    });

    describe('switching to another company', () => {
        // The host form reuses this component when it navigates from one Company to the next.
        it('discards a slow load for the previous company that resolves after the switch', async () => {
            const stale: { resolve: (v: { Success: boolean; Results: FakeRow[] }) => void } = { resolve: () => undefined };
            const { component } = build([]);
            H.runView.mockReturnValueOnce(new Promise((resolve) => (stale.resolve = resolve)));
            const pendingFirst = component.ngOnInit(); // co-1's load stays pending

            H.runView.mockResolvedValueOnce({ Success: true, Results: [row('b1', 'jobs@bolt.io', false)] });
            component.CompanyID = 'co-2';
            await vi.waitFor(() => expect(component.Rows.map((r) => r.ID)).toEqual(['b1']));

            stale.resolve({ Success: true, Results: [row('a1', 'hr@acme.com', false)] });
            await pendingFirst;

            expect(component.Rows.map((r) => r.ID)).toEqual(['b1']);
            expect(component.Loading).toBe(false);
        });

        it('reloads for the new company through the CompanyID input', async () => {
            const { component } = build([]);
            await component.ngOnInit();
            H.runView.mockClear();

            component.CompanyID = 'co-2';

            await vi.waitFor(() => expect(H.runView).toHaveBeenCalledTimes(1));
            const params = H.runView.mock.calls[0][0] as { ExtraFilter: string };
            expect(params.ExtraFilter).toContain("CompanyID = 'co-2'");
        });

        it("clears the previous company's notice, error and add-form draft", async () => {
            const { component } = build([], row('new', '', false));
            await component.ngOnInit();
            component.openAddForm('Domain');
            component.NewAddress = 'half-typed.com';
            component.Notice = 'Make sure this sender is verified';
            component.Error = 'old error';

            component.CompanyID = 'co-2';

            expect(component.Notice).toBeNull();
            expect(component.Error).toBeNull();
            expect(component.ShowAddForm).toBe(false);
            expect(component.NewAddress).toBe('');
            expect(component.NewKind).toBe('Mailbox');
        });
    });

    it('setDefault reloads and emits DataChanged when the demote saved but the promote failed', async () => {
        const current = row('r1', 'old@acme.com', true);
        const chosen = row('r2', 'new@acme.com', false);
        chosen.Save.mockResolvedValue(false);
        const { component } = build([current, chosen]);
        await component.loadAll();
        H.runView.mockClear();
        H.runView.mockResolvedValue({ Success: true, Results: [current, chosen] });
        const emitted = vi.fn();
        component.DataChanged.subscribe(emitted);

        const ok = await component.setDefault(asEntity(chosen));

        expect(ok).toBe(false);
        expect(H.runView).toHaveBeenCalledTimes(1); // the list is re-read: the database changed
        expect(emitted).toHaveBeenCalledTimes(1);
        expect(component.Error).toContain('"old@acme.com" is no longer the default');
    });
});
