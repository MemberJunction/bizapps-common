import { describe, expect, it, vi } from 'vitest';
import type { IMetadataProvider } from '@memberjunction/core';
import { RegisterClass } from '@memberjunction/global';
import {
    CommonStaffFigures,
    DiscoverOrganizationStaffContributors,
    LoadOrganizationStaff,
    OrganizationStaffContributor,
    RunStaffContributors,
    type OrganizationStaffMember,
    type OrganizationStaffRequest,
    type StaffContribution,
} from '../organization-staff';

const TODAY = new Date(Date.UTC(2026, 9, 7)); // 2026-10-07

function member(id: string, title: string | null, start: string | null): OrganizationStaffMember {
    return { PersonID: id, Name: `Person ${id}`, Title: title, StartDate: start };
}

function contribution(label: string): StaffContribution {
    return { Figures: [{ Label: label, Value: 1 }], Columns: [], Cells: new Map() };
}

describe('CommonStaffFigures', () => {
    it('counts staff, distinct roles, and people who joined in the last 12 months (inclusive)', () => {
        const staff = [
            member('A', 'Cheesemaker', '2026-10-07T00:00:00.000Z'), // today
            member('B', 'Cheesemaker', '2025-10-07T00:00:00.000Z'), // exactly 12 months ago: counts
            member('C', 'Quality Manager', '2025-10-06T00:00:00.000Z'), // one day too old
            member('D', null, null),
            { PersonID: 'E', Name: 'Person E', Title: 'Affineur', StartDate: new Date('2026-01-15T00:00:00.000Z') }, // Date object, as the browser provider sends
        ];
        const figures = CommonStaffFigures(staff, TODAY);
        expect(figures).toEqual([
            { Label: 'Staff', Value: 5, Icon: 'fa-solid fa-users', Detail: '3 roles' },
            { Label: 'Joined in 12 months', Value: 3, Icon: 'fa-solid fa-user-plus' },
        ]);
    });

    it('omits the roles detail when nobody has a title, and says "1 role" for one', () => {
        expect(CommonStaffFigures([member('A', null, null)], TODAY)[0].Detail).toBeUndefined();
        expect(CommonStaffFigures([member('A', 'Affineur', null), member('B', ' Affineur ', null)], TODAY)[0].Detail).toBe('1 role');
    });
});

describe('RunStaffContributors', () => {
    class Ok extends OrganizationStaffContributor {
        public readonly Key = 'ok';
        public readonly Label = 'Good figures';
        public async Load(): Promise<StaffContribution> { return contribution('Good'); }
    }
    class Broken extends OrganizationStaffContributor {
        public readonly Key = 'broken';
        public readonly Label = 'Broken figures';
        public async Load(): Promise<StaffContribution> { throw new Error('query not found'); }
    }
    const request: OrganizationStaffRequest = { OrganizationID: 'ORG', Staff: [member('A', null, null)] };

    it('keeps a working contributor when another one throws, and reports the failure', async () => {
        const results = await RunStaffContributors([new Ok(), new Broken()], request);
        expect(results[0].Contribution?.Figures[0].Label).toBe('Good');
        expect(results[0].Error).toBeNull();
        expect(results[1].Contribution).toBeNull();
        expect(results[1].Error).toBe('query not found');
        expect(results[1].Contributor.Label).toBe('Broken figures');
    });

    it('passes the same request to every contributor', async () => {
        const c = new Ok();
        const spy = vi.spyOn(c, 'Load');
        await RunStaffContributors([c], request);
        expect(spy).toHaveBeenCalledWith(request);
    });
});

describe('DiscoverOrganizationStaffContributors', () => {
    @RegisterClass(OrganizationStaffContributor, 'test-staff-low')
    class LowPriority extends OrganizationStaffContributor {
        public readonly Key = 'test-staff-low';
        public readonly Label = 'Low';
        public async Load(): Promise<StaffContribution> { return contribution('low'); }
    }
    @RegisterClass(OrganizationStaffContributor, 'test-staff-high')
    class HighPriority extends OrganizationStaffContributor {
        public readonly Key = 'test-staff-high';
        public readonly Label = 'High';
        public override readonly Priority = 50;
        public async Load(): Promise<StaffContribution> { return contribution('high'); }
    }
    // An implementation replacing one app's contributor: same key, higher registration priority.
    @RegisterClass(OrganizationStaffContributor, 'test-staff-low', 10)
    class LowReplacement extends OrganizationStaffContributor {
        public readonly Key = 'test-staff-low';
        public readonly Label = 'Low (replaced)';
        public async Load(): Promise<StaffContribution> { return contribution('replaced'); }
    }

    it('returns one instance per key, the highest-priority registration wins, sorted by Priority', () => {
        void LowPriority; void HighPriority; void LowReplacement;
        const found = DiscoverOrganizationStaffContributors().filter(c => c.Key.startsWith('test-staff-'));
        expect(found.map(c => c.Label)).toEqual(['High', 'Low (replaced)']);
    });

    it('reuses the same instance across calls', () => {
        const a = DiscoverOrganizationStaffContributors().find(c => c.Key === 'test-staff-high');
        const b = DiscoverOrganizationStaffContributors().find(c => c.Key === 'test-staff-high');
        expect(a).toBe(b);
    });
});

describe('LoadOrganizationStaff', () => {
    it('reads active, not-ended Employee relationships to the organization, sorted by name', async () => {
        const runView = vi.fn().mockResolvedValue({
            Success: true,
            Results: [{ FromPersonID: 'P1', FromPerson: 'Nia Ferraro', Title: 'Cheesemaker', StartDate: '2025-11-12' }],
        });
        const provider = { RunView: runView } as unknown as IMetadataProvider;
        const staff = await LoadOrganizationStaff("ORG'1", provider, TODAY);
        expect(staff).toEqual([{ PersonID: 'P1', Name: 'Nia Ferraro', Title: 'Cheesemaker', StartDate: '2025-11-12' }]);
        const params = runView.mock.calls[0][0];
        expect(params.EntityName).toBe('MJ_BizApps_Common: Relationships');
        expect(params.ExtraFilter).toBe(
            "ToOrganizationID='ORG''1' AND FromPersonID IS NOT NULL AND RelationshipType='Employee' AND Status='Active' AND (EndDate IS NULL OR EndDate >= '2026-10-07')",
        );
        expect(params.OrderBy).toBe('FromPerson');
        expect(params.ResultType).toBe('simple');
    });

    it('throws with the view error so the section can show it', async () => {
        const provider = { RunView: vi.fn().mockResolvedValue({ Success: false, ErrorMessage: 'boom', Results: [] }) } as unknown as IMetadataProvider;
        await expect(LoadOrganizationStaff('ORG', provider, TODAY)).rejects.toThrow('boom');
    });
});
