/**
 * #311 — the Activity hero's "Thread / Parent" link gated on the virtual `ParentActivity` name field,
 * which V202609112330 removes on hosts whose `vwActivities` lacks the column. There it always reads
 * null, so an activity with a parent showed no link. The hero now gates on `ParentActivityID` and
 * reads the parent's Title itself.
 */
import '@angular/compiler';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { beforeEach, describe, expect, it, vi } from 'vitest';

const H = vi.hoisted(() => ({ runView: vi.fn() }));

vi.mock('@memberjunction/core', async (importOriginal) => {
    const actual = await importOriginal<object>();
    class MockRunView {
        public RunView = H.runView;
    }
    return { ...actual, RunView: MockRunView, LogError: () => undefined };
});

import { UserInfoEngine } from '@memberjunction/core-entities';
import type { mjBizAppsCommonActivityEntity } from '@mj-biz-apps/common-entities';
import { ActivityIdentityComponent } from '../activity-identity.component';

const TEMPLATE = readFileSync(fileURLToPath(new URL('../activity-identity.component.html', import.meta.url)), 'utf8');
const PARENT_ID = 'A1B2C3D4-0000-0000-0000-000000000001';

function build(parentID: string | null): ActivityIdentityComponent {
    const component = new ActivityIdentityComponent();
    component.Record = { ParentActivityID: parentID, RunViewProviderToUse: {} } as unknown as mjBizAppsCommonActivityEntity;
    return component;
}

describe('ActivityIdentityComponent parent link (#311)', () => {
    beforeEach(() => {
        vi.spyOn(UserInfoEngine.Instance, 'GetSetting').mockReturnValue(undefined);
        H.runView.mockReset();
        H.runView.mockResolvedValue({ Success: true, Results: [{ Title: 'Kickoff call' }] });
    });

    it('gates the link on ParentActivityID, not on the virtual ParentActivity field', () => {
        expect(TEMPLATE).toContain('@if (Record.ParentActivityID) {');
        expect(TEMPLATE).not.toMatch(/Record\.ParentActivity\b(?!ID)/);
    });

    it("labels the link with the parent's Title", async () => {
        const component = build(PARENT_ID);
        component.ngOnInit();

        await vi.waitFor(() => expect(component.ParentActivityLabel).toBe('Kickoff call'));
        const params = H.runView.mock.calls[0][0] as { EntityName: string; ExtraFilter: string };
        expect(params.EntityName).toBe('MJ_BizApps_Common: Activities');
        expect(params.ExtraFilter).toBe(`ID = '${PARENT_ID}'`);
    });

    it('matches the loaded parent regardless of UUID case', async () => {
        const component = build(PARENT_ID);
        component.ngOnInit();
        await vi.waitFor(() => expect(component.ParentActivityLabel).toBe('Kickoff call'));

        component.Record.ParentActivityID = PARENT_ID.toLowerCase();
        expect(component.ParentActivityLabel).toBe('Kickoff call');
    });

    it('falls back to a generic label when the parent cannot be read, or the parent changed', async () => {
        H.runView.mockResolvedValue({ Success: false, ErrorMessage: 'denied', Results: [] });
        const failed = build(PARENT_ID);
        failed.ngOnInit();
        await vi.waitFor(() => expect(H.runView).toHaveBeenCalled());
        expect(failed.ParentActivityLabel).toBe('Parent activity');

        H.runView.mockResolvedValue({ Success: true, Results: [{ Title: 'Kickoff call' }] });
        const moved = build(PARENT_ID);
        moved.ngOnInit();
        await vi.waitFor(() => expect(moved.ParentActivityLabel).toBe('Kickoff call'));
        moved.Record.ParentActivityID = 'A1B2C3D4-0000-0000-0000-000000000002';
        expect(moved.ParentActivityLabel).toBe('Parent activity');
    });

    it('queries nothing for an activity with no parent', () => {
        build(null).ngOnInit();
        expect(H.runView).not.toHaveBeenCalled();
    });
});
