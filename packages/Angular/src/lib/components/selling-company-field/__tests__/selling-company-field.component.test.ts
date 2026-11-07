import '@angular/compiler';
import { ChangeDetectorRef, ElementRef, Injector, SimpleChange, runInInjectionContext } from '@angular/core';
import { MJEventType, MJGlobal } from '@memberjunction/global';
import { beforeEach, describe, expect, it, vi } from 'vitest';

const H = vi.hoisted(() => ({
    settingValue: 'default-co' as string | null,
    employeeID: null as string | null,
    companies: [
        { ID: 'default-co', Name: 'Default Selling Co' },
        { ID: 'other-co', Name: 'Other Co' },
        { ID: 'employee-co', Name: 'Employee Co' },
    ],
    employeeRows: [] as { CompanyID: string }[],
    runView: vi.fn(),
}));

vi.mock('@memberjunction/core', async (importOriginal) => {
    const actual = await importOriginal<object>();
    class MockMetadata {
        public static Provider = {};
        public get CurrentUser() {
            return { ID: 'u1', EmployeeID: H.employeeID };
        }
        public get Applications() {
            return [{ ID: 'app-common', Name: 'Common' }];
        }
    }
    return {
        ...actual,
        Metadata: MockMetadata,
        RunView: { FromMetadataProvider: () => ({ RunView: H.runView }) },
    };
});

vi.mock('@memberjunction/core-entities', async (importOriginal) => ({
    ...(await importOriginal<object>()),
    ApplicationSettingEngine: {
        Instance: {
            Config: async () => undefined,
            GetSetting: (name: string) => (name === 'DefaultSellingCompanyID' ? H.settingValue : undefined),
        },
    },
}));

vi.mock('@memberjunction/ng-base-forms', () => ({ BaseFormsModule: class {} }));

import { SellingCompanyFieldComponent } from '../selling-company-field.component';

interface FakeRecord {
    IsSaved: boolean;
    values: Record<string, unknown>;
    Get(field: string): unknown;
    Set(field: string, value: unknown): void;
    RegisterEventHandler(callback: (event: { type: string }) => void): { unsubscribe(): void };
    /** Raises a BaseEntity event to every registered handler, as BaseEntity.Save() does. */
    raise(type: string): void;
}

function record(isSaved: boolean, companyID: string | null = null): FakeRecord {
    const values: Record<string, unknown> = { CompanyID: companyID };
    const handlers: ((event: { type: string }) => void)[] = [];
    return {
        IsSaved: isSaved,
        values,
        Get: (field: string) => values[field],
        Set: (field: string, value: unknown) => {
            values[field] = value;
        },
        RegisterEventHandler: (callback) => {
            handlers.push(callback);
            return { unsubscribe: () => handlers.splice(handlers.indexOf(callback), 1) };
        },
        raise: (type: string) => handlers.forEach((h) => h({ type })),
    };
}

/**
 * The component resolves ChangeDetectorRef with `inject()`, which needs an injection context.
 * A one-provider injector gives it one without standing up TestBed — these are unit tests of the
 * default-and-confirm behaviour, not of rendering.
 */
/** Stands in for the field's host element; a fake form element "contains" it. */
const FIELD_HOST = { tag: 'bizapps-selling-company-field' };

async function build(rec: FakeRecord): Promise<SellingCompanyFieldComponent> {
    const injector = Injector.create({
        providers: [
            { provide: ChangeDetectorRef, useValue: { markForCheck: () => undefined } },
            { provide: ElementRef, useValue: new ElementRef(FIELD_HOST) },
        ],
    });
    const component = runInInjectionContext(injector, () => new SellingCompanyFieldComponent());
    component.Record = rec as unknown as SellingCompanyFieldComponent['Record'];
    await component.ngOnInit();
    return component;
}

describe('SellingCompanyFieldComponent', () => {
    beforeEach(() => {
        H.settingValue = 'default-co';
        H.employeeID = null;
        H.employeeRows = [];
        H.runView.mockImplementation(async (params: { EntityName: string }) =>
            params.EntityName === 'MJ: Employees'
                ? { Success: true, Results: H.employeeRows }
                : { Success: true, Results: H.companies },
        );
    });

    it('defaults a new record to the configured company', async () => {
        const rec = record(false);
        await build(rec);
        expect(rec.values['CompanyID']).toBe('default-co');
    });

    it('prefers the user own company over the configured setting', async () => {
        H.employeeID = 'emp-1';
        H.employeeRows = [{ CompanyID: 'employee-co' }];
        const rec = record(false);
        const component = await build(rec);
        expect(rec.values['CompanyID']).toBe('employee-co');
        expect(component.DefaultName).toBe('Employee Co');
    });

    it('ignores an employee company this instance does not know', async () => {
        H.employeeID = 'emp-1';
        H.employeeRows = [{ CompanyID: 'some-unknown-co' }];
        const rec = record(false);
        await build(rec);
        expect(rec.values['CompanyID']).toBe('default-co');
    });

    it('never overwrites a company already on the record', async () => {
        const rec = record(false, 'other-co');
        await build(rec);
        expect(rec.values['CompanyID']).toBe('other-co');
    });

    it('leaves a saved record alone', async () => {
        const rec = record(true);
        await build(rec);
        expect(rec.values['CompanyID']).toBeNull();
    });

    it('writes nothing and asks nothing when the instance configured no default', async () => {
        H.settingValue = null;
        const rec = record(false);
        const component = await build(rec);
        expect(rec.values['CompanyID']).toBeNull();

        rec.Set('CompanyID', 'other-co');
        component.OnValueChange('other-co');
        expect(component.AskName).toBeNull();
        expect(rec.values['CompanyID']).toBe('other-co');
    });

    it('holds another company, restoring the previous value while the question is open', async () => {
        const rec = record(false);
        const component = await build(rec);

        rec.Set('CompanyID', 'other-co'); // mj-form-field writes before it emits
        component.OnValueChange('other-co');

        expect(component.AskName).toBe('Other Co');
        expect(component.DefaultName).toBe('Default Selling Co');
        expect(rec.values['CompanyID']).toBe('default-co');
    });

    it('writes the held company on confirm', async () => {
        const rec = record(false);
        const component = await build(rec);
        rec.Set('CompanyID', 'other-co');
        component.OnValueChange('other-co');

        component.OnConfirm();
        expect(rec.values['CompanyID']).toBe('other-co');
        expect(component.AskName).toBeNull();
    });

    it('keeps the previous company on revert', async () => {
        const rec = record(false);
        const component = await build(rec);
        rec.Set('CompanyID', 'other-co');
        component.OnValueChange('other-co');

        component.OnRevert();
        expect(rec.values['CompanyID']).toBe('default-co');
        expect(component.AskName).toBeNull();
    });

    it('asks again after a confirmed choice, using the confirmed value as what to revert to', async () => {
        const rec = record(false);
        const component = await build(rec);
        rec.Set('CompanyID', 'other-co');
        component.OnValueChange('other-co');
        component.OnConfirm();

        rec.Set('CompanyID', 'employee-co');
        component.OnValueChange('employee-co');
        expect(component.AskName).toBe('Employee Co');

        component.OnRevert();
        expect(rec.values['CompanyID']).toBe('other-co');
    });

    it('names a company by ID rather than hiding the question when the company list cannot be read', async () => {
        H.runView.mockImplementation(async () => ({ Success: false, ErrorMessage: 'denied', Results: [] }));
        const rec = record(false);
        const component = await build(rec);

        rec.Set('CompanyID', 'other-co');
        component.OnValueChange('other-co');
        expect(component.AskName).toBe('other-co');
    });

    describe('a save or leaving edit mode with the question open (#344)', () => {
        async function pending(): Promise<{ rec: FakeRecord; component: SellingCompanyFieldComponent }> {
            const rec = record(false);
            const component = await build(rec);
            component.EditMode = true;
            rec.Set('CompanyID', 'other-co');
            component.OnValueChange('other-co');
            return { rec, component };
        }

        it('closes the question on save and says the pick was not applied', async () => {
            const { rec, component } = await pending();

            rec.raise('save_started');

            expect(rec.values['CompanyID']).toBe('default-co');
            expect(component.AskName).toBeNull();
            expect(component.NotAppliedName).toBe('Other Co');
            expect(component.KeptName).toBe('Default Selling Co');
        });

        it('a confirm after the save does not book the dropped pick', async () => {
            const { rec, component } = await pending();
            rec.raise('save_started');

            component.OnConfirm();
            expect(rec.values['CompanyID']).toBe('default-co');
        });

        it('closes the question when the form leaves edit mode', async () => {
            const { rec, component } = await pending();

            component.EditMode = false;

            expect(rec.values['CompanyID']).toBe('default-co');
            expect(component.AskName).toBeNull();
            expect(component.NotAppliedName).toBe('Other Co');
        });

        /** What BaseFormComponent.SaveRecord() raises before it saves, dirty record or not. */
        function formSaving(containsField: boolean): void {
            MJGlobal.Instance.RaiseEvent({
                event: MJEventType.ComponentEvent,
                component: {},
                eventCode: 'BaseFormComponent_Event',
                args: {
                    subEventCode: 'EDITING_COMPLETE',
                    elementRef: { nativeElement: { contains: (el: unknown) => containsField && el === FIELD_HOST } },
                },
            });
        }

        it('closes the question when the form saves a record left clean by the held pick', async () => {
            // The pick was put back, so the record is clean and BaseEntity.Save() raises no save_started.
            const { rec, component } = await pending();

            formSaving(true);

            expect(rec.values['CompanyID']).toBe('default-co');
            expect(component.AskName).toBeNull();
            expect(component.NotAppliedName).toBe('Other Co');
            component.ngOnDestroy();
        });

        it('ignores a save on another form', async () => {
            const { component } = await pending();

            formSaving(false);

            expect(component.AskName).toBe('Other Co');
            component.ngOnDestroy();
        });

        it('moves its save handler to a rebound record and drops the old question', async () => {
            const { rec, component } = await pending();
            const next = record(true, 'employee-co');
            component.Record = next as unknown as SellingCompanyFieldComponent['Record'];
            component.ngOnChanges({ Record: new SimpleChange(rec, next, false) });
            expect(component.AskName).toBeNull();

            next.Set('CompanyID', 'other-co');
            component.OnValueChange('other-co');
            expect(next.values['CompanyID']).toBe('employee-co');

            rec.raise('save_started');
            expect(component.AskName).toBe('Other Co');
            next.raise('save_started');
            expect(component.AskName).toBeNull();
            expect(component.KeptName).toBe('Employee Co');
            component.ngOnDestroy();
        });

        it('says nothing when no question was open', async () => {
            const rec = record(false);
            const component = await build(rec);
            component.EditMode = true;

            rec.raise('save_started');
            component.EditMode = false;

            expect(component.NotAppliedName).toBeNull();
        });

        it('clears the notice on the next pick, and stops listening once destroyed', async () => {
            const { rec, component } = await pending();
            rec.raise('save_started');

            rec.Set('CompanyID', 'default-co');
            component.OnValueChange('default-co');
            expect(component.NotAppliedName).toBeNull();

            rec.Set('CompanyID', 'other-co');
            component.OnValueChange('other-co');
            component.ngOnDestroy();
            rec.raise('save_started');
            expect(component.AskName).toBe('Other Co');
        });
    });
});
