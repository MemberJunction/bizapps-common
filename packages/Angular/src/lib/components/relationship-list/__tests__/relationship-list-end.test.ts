/**
 * Ending a relationship stores today's business day in EndDate, a SQL `date` column that keeps the
 * UTC day of whatever Date it is given. A raw `new Date()` on an American evening is already
 * tomorrow in UTC (golive #168); the component stores `BusinessTimeZoneEngine.TodayAsDate()`.
 */
import '@angular/compiler';
import { ChangeDetectorRef, Injector, runInInjectionContext } from '@angular/core';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { BusinessTimeZoneEngine } from '@mj-biz-apps/common-entities';

vi.mock('@memberjunction/ng-base-forms', () => ({ BaseFormsModule: class {} }));

import { RelationshipListComponent } from '../relationship-list.component';

interface FakeRelationship {
    ID: string;
    Status: string;
    EndDate: Date | null;
    Save: ReturnType<typeof vi.fn>;
}

function build(): RelationshipListComponent {
    const injector = Injector.create({
        providers: [{ provide: ChangeDetectorRef, useValue: { detectChanges: () => undefined } }],
    });
    const component = runInInjectionContext(injector, () => new RelationshipListComponent());
    // Standalone mode reloads after the save; the reload is not under test.
    vi.spyOn(component as unknown as { loadData: () => Promise<void> }, 'loadData').mockResolvedValue();
    return component;
}

describe('RelationshipListComponent.onEndRelationship', () => {
    beforeEach(() => {
        vi.useFakeTimers();
        // 8:30 PM Central on Sept 30 is already Oct 1 in UTC.
        vi.setSystemTime(new Date('2026-10-01T01:30:00.000Z'));
        vi.spyOn(BusinessTimeZoneEngine.Instance, 'Resolve').mockReturnValue('America/Chicago');
    });

    afterEach(() => {
        vi.useRealTimers();
        vi.restoreAllMocks();
    });

    it('stores the business day as UTC midnight, not the UTC instant', async () => {
        const rel: FakeRelationship = { ID: 'r1', Status: 'Active', EndDate: null, Save: vi.fn().mockResolvedValue(true) };

        await build().onEndRelationship(rel as unknown as Parameters<RelationshipListComponent['onEndRelationship']>[0]);

        expect(rel.Status).toBe('Ended');
        expect(rel.EndDate?.toISOString()).toBe('2026-09-30T00:00:00.000Z');
        expect(rel.Save).toHaveBeenCalledOnce();
    });
});
