import { beforeEach, describe, expect, it, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { RunView, type IMetadataProvider } from '@memberjunction/core';
import type { FormNavigationEvent } from '@memberjunction/ng-base-forms';
import { RelatedChipsComponent } from '../related-chips.component';

const TEST_PROVIDER = {
    Entities: [
        {
            Name: 'MJ_BizApps_Orders: Order Headers',
            BaseTableDisplayName: 'Order',
            NameField: { Name: 'OrderNumber' },
            PrimaryKeys: [{ Name: 'ID' }],
        },
    ],
} as unknown as IMetadataProvider;

function flushMicrotasks(): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, 0));
}

describe('RelatedChipsComponent DOM & async lifecycle (#303, #318)', () => {
    beforeEach(() => {
        vi.restoreAllMocks();
    });

    it('renders a static <span> without bizapps-chip--clickable when (Navigate) has no subscribers (#318)', async () => {
        vi.spyOn(RunView, 'FromMetadataProvider').mockReturnValue({
            RunView: vi.fn().mockResolvedValue({
                Success: true,
                Results: [{ ID: 'ord-1', OrderNumber: 'ORD-100' }],
            }),
        } as unknown as RunView);

        const fixture = TestBed.createComponent(RelatedChipsComponent);
        const component = fixture.componentInstance;
        component.Provider = TEST_PROVIDER;
        component.Links = [
            {
                Key: 'order',
                EntityName: 'MJ_BizApps_Orders: Order Headers',
                RecordID: 'ord-1',
                Label: 'Order',
            },
        ];

        await flushMicrotasks();
        fixture.detectChanges();

        const host: HTMLElement = fixture.nativeElement;
        expect(host.querySelector('button.bizapps-related__chip')).toBeNull();
        const spanChip = host.querySelector('span.bizapps-related__chip');
        expect(spanChip).not.toBeNull();
        expect(spanChip?.classList.contains('bizapps-chip--clickable')).toBe(false);
        expect(spanChip?.textContent).toContain('ORD-100');
    });

    it('renders an interactive <button type="button"> with bizapps-chip--clickable when (Navigate) is observed and emits on click (#318)', async () => {
        vi.spyOn(RunView, 'FromMetadataProvider').mockReturnValue({
            RunView: vi.fn().mockResolvedValue({
                Success: true,
                Results: [{ ID: 'ord-1', OrderNumber: 'ORD-100' }],
            }),
        } as unknown as RunView);

        const fixture = TestBed.createComponent(RelatedChipsComponent);
        const component = fixture.componentInstance;
        const events: FormNavigationEvent[] = [];
        component.Navigate.subscribe((e) => events.push(e));
        component.Provider = TEST_PROVIDER;
        component.Links = [
            {
                Key: 'order',
                EntityName: 'MJ_BizApps_Orders: Order Headers',
                RecordID: 'ord-1',
                Label: 'Order',
            },
        ];

        await flushMicrotasks();
        fixture.detectChanges();

        const host: HTMLElement = fixture.nativeElement;
        const button = host.querySelector<HTMLButtonElement>('button.bizapps-related__chip');
        expect(button).not.toBeNull();
        expect(button?.type).toBe('button');
        expect(button?.classList.contains('bizapps-chip--clickable')).toBe(true);

        button?.click();
        expect(events).toHaveLength(1);
        expect(events[0].Kind).toBe('record');
    });

    it('discards a slower stale read when Links changes before the first read finishes (#303)', async () => {
        let resolveFirst!: (val: { Success: boolean; Results: Record<string, unknown>[] }) => void;
        const firstPromise = new Promise<{ Success: boolean; Results: Record<string, unknown>[] }>((res) => {
            resolveFirst = res;
        });

        const runViewSpy = vi.fn().mockImplementation(({ ExtraFilter }: { ExtraFilter: string }) => {
            if (ExtraFilter.includes('ord-slow')) {
                return firstPromise;
            }
            return Promise.resolve({
                Success: true,
                Results: [{ ID: 'ord-fast', OrderNumber: 'ORD-FAST' }],
            });
        });
        vi.spyOn(RunView, 'FromMetadataProvider').mockReturnValue({
            RunView: runViewSpy,
        } as unknown as RunView);

        const fixture = TestBed.createComponent(RelatedChipsComponent);
        const component = fixture.componentInstance;
        component.Provider = TEST_PROVIDER;

        // First set of links (slow)
        component.Links = [
            {
                Key: 'order',
                EntityName: 'MJ_BizApps_Orders: Order Headers',
                RecordID: 'ord-slow',
                Label: 'Order',
            },
        ];
        await flushMicrotasks();

        // Second set of links (fast) supersedes the first
        component.Links = [
            {
                Key: 'order',
                EntityName: 'MJ_BizApps_Orders: Order Headers',
                RecordID: 'ord-fast',
                Label: 'Order',
            },
        ];
        await flushMicrotasks();
        fixture.detectChanges();

        // Now resolve the slow first read and ensure it does not overwrite ORD-FAST
        resolveFirst({
            Success: true,
            Results: [{ ID: 'ord-slow', OrderNumber: 'ORD-SLOW' }],
        });
        await flushMicrotasks();
        fixture.detectChanges();

        expect(component.Chips.map((c) => c.Name)).toEqual(['ORD-FAST']);
    });
});
