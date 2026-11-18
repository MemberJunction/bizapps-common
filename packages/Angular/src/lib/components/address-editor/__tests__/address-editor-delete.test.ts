import { beforeEach, describe, expect, it, vi } from 'vitest';

const { getRecordDependenciesMock, createTransactionGroupMock } = vi.hoisted(() => ({
    getRecordDependenciesMock: vi.fn(),
    createTransactionGroupMock: vi.fn(),
}));

vi.mock('@angular/core', () => ({
    Component: () => (t: unknown) => t,
    Input: () => () => undefined,
    Output: () => () => undefined,
    EventEmitter: class {
        private listeners: Array<() => void> = [];
        subscribe(fn: () => void): void {
            this.listeners.push(fn);
        }
        emit(): void {
            for (const fn of this.listeners) fn();
        }
    },
    inject: () => ({ detectChanges: vi.fn(), markForCheck: vi.fn() }),
    ChangeDetectorRef: class {},
}));
vi.mock('@angular/common', () => ({ CommonModule: class {} }));
vi.mock('@angular/forms', () => ({ FormsModule: class {} }));
vi.mock('@memberjunction/graphql-dataprovider', () => ({
    GraphQLDataProvider: class {},
    GraphQLActionClient: class {},
}));
vi.mock('@memberjunction/actions-base', () => ({
    ActionParam: class {},
    ActionEngineBase: {
        Instance: {
            Config: vi.fn().mockResolvedValue(undefined),
        },
    },
}));

vi.mock('@memberjunction/core', async (importOriginal) => {
    const actual = await importOriginal<typeof import('@memberjunction/core')>();
    return {
        ...actual,
        Metadata: class {
            Entities: Array<{ ID: string; Name: string }> = [];
            EntityByName = vi.fn().mockReturnValue(null);
            GetRecordDependencies = getRecordDependenciesMock;
            CreateTransactionGroup = createTransactionGroupMock;
        },
        RunView: class {
            RunViews = vi.fn().mockResolvedValue([
                { Success: true, Results: [] },
                { Success: true, Results: [] },
            ]);
            RunView = vi.fn().mockResolvedValue({ Success: true, Results: [] });
        },
    };
});

import type {
    mjBizAppsCommonAddressEntity,
    mjBizAppsCommonAddressLinkEntity,
} from '@mj-biz-apps/common-entities';
import { AddressEditorComponent } from '../address-editor.component';

interface StubEntityResult {
    Success: boolean;
    Message?: string;
    CompleteMessage?: string;
}

function makeStubLink(
    deleteFn: () => Promise<boolean>,
    latestResult: StubEntityResult | null = null
): mjBizAppsCommonAddressLinkEntity {
    return {
        ID: 'link-1',
        AddressID: 'addr-1',
        AddressTypeID: 'type-1',
        IsPrimary: true,
        TransactionGroup: null,
        LatestResult: latestResult,
        Delete: deleteFn,
    } as unknown as mjBizAppsCommonAddressLinkEntity;
}

function makeStubAddress(
    deleteFn: () => Promise<boolean> = () => Promise.resolve(true),
    latestResult: StubEntityResult | null = null
): mjBizAppsCommonAddressEntity {
    return {
        ID: 'addr-1',
        PrimaryKey: { KeyValuePairs: [{ FieldName: 'ID', Value: 'addr-1' }] },
        Line1: '100 Main St',
        City: 'Austin',
        TransactionGroup: null,
        LatestResult: latestResult,
        Delete: deleteFn,
    } as unknown as mjBizAppsCommonAddressEntity;
}

describe('AddressEditorComponent.onDelete (#305)', () => {
    beforeEach(() => {
        getRecordDependenciesMock.mockReset();
        createTransactionGroupMock.mockReset();
    });

    it('does not call Link.Delete() and leaves AddressItems unchanged when confirmDelete returns false', async () => {
        const component = new AddressEditorComponent();
        const linkDelete = vi.fn().mockResolvedValue(true);
        const addrDelete = vi.fn().mockResolvedValue(true);
        const item = {
            Link: makeStubLink(linkDelete),
            Address: makeStubAddress(addrDelete),
        };
        component.AddressItems = [item];

        const confirmSpy = vi
            .spyOn(
                component as unknown as { confirmDelete: () => boolean },
                'confirmDelete'
            )
            .mockReturnValue(false);
        const changedSpy = vi.fn();
        component.DataChanged.subscribe(changedSpy);

        await component.onDelete(0);

        expect(confirmSpy).toHaveBeenCalledOnce();
        expect(linkDelete).not.toHaveBeenCalled();
        expect(addrDelete).not.toHaveBeenCalled();
        expect(component.AddressItems).toHaveLength(1);
        expect(changedSpy).not.toHaveBeenCalled();
        expect(component.ActionError).toBeNull();
    });

    it('deletes only the Link, removes the row, emits DataChanged, and keeps ActionError null when reference check throws or succeeds', async () => {
        getRecordDependenciesMock.mockRejectedValueOnce(new Error('Read-only connection unavailable'));
        const component = new AddressEditorComponent();
        const linkDelete = vi.fn().mockResolvedValue(true);
        const addrDelete = vi.fn().mockResolvedValue(true);
        const item = {
            Link: makeStubLink(linkDelete),
            Address: makeStubAddress(addrDelete),
        };
        component.AddressItems = [item];

        const changedSpy = vi.fn();
        component.DataChanged.subscribe(changedSpy);

        await component.onDelete(0);

        expect(linkDelete).toHaveBeenCalledOnce();
        expect(addrDelete).not.toHaveBeenCalled();
        expect(component.AddressItems).toHaveLength(0);
        expect(changedSpy).toHaveBeenCalledOnce();
        expect(component.ActionError).toBeNull();
        expect(component.Saving).toBe(false);
    });

    it('sets ActionError from LatestResult, resets Saving to false, does not emit DataChanged, and keeps the row when Link.Delete() returns false', async () => {
        getRecordDependenciesMock.mockRejectedValueOnce(new Error('No RO pool'));
        const component = new AddressEditorComponent();
        const linkDelete = vi.fn().mockResolvedValue(false);
        const item = {
            Link: makeStubLink(linkDelete, {
                Success: false,
                Message: 'Permission denied on AddressLink',
                CompleteMessage: 'Permission denied on AddressLink',
            }),
            Address: makeStubAddress(),
        };
        component.AddressItems = [item];

        const changedSpy = vi.fn();
        component.DataChanged.subscribe(changedSpy);

        await component.onDelete(0);

        expect(linkDelete).toHaveBeenCalledOnce();
        expect(component.ActionError).toContain('Permission denied on AddressLink');
        expect(component.Saving).toBe(false);
        expect(changedSpy).not.toHaveBeenCalled();
        expect(component.AddressItems).toHaveLength(1);
    });

    it('sets ActionError, resets Saving to false, does not emit DataChanged, and reloads when TransactionGroup.Submit() returns false', async () => {
        getRecordDependenciesMock.mockResolvedValueOnce([]);
        const submitMock = vi.fn().mockResolvedValue(false);
        createTransactionGroupMock.mockResolvedValueOnce({ Submit: submitMock });

        const component = new AddressEditorComponent();
        const linkDelete = vi.fn().mockResolvedValue(true);
        const addrDelete = vi.fn().mockResolvedValue(true);
        const item = {
            Link: makeStubLink(linkDelete, { Success: true }),
            Address: makeStubAddress(addrDelete, {
                Success: false,
                CompleteMessage: 'FK constraint on Address',
            }),
        };
        component.AddressItems = [item];

        const changedSpy = vi.fn();
        component.DataChanged.subscribe(changedSpy);

        await component.onDelete(0);

        expect(submitMock).toHaveBeenCalledOnce();
        expect(component.ActionError).toContain('FK constraint on Address');
        expect(component.Saving).toBe(false);
        expect(changedSpy).not.toHaveBeenCalled();
        expect(component.AddressItems).toHaveLength(1);
    });
});
