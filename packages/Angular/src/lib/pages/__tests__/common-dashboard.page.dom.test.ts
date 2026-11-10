import { beforeEach, describe, expect, it, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';

const { loadSummaryMock, loadLatestPeopleViewMock, loadLatestRelationshipsViewMock } = vi.hoisted(() => ({
    loadSummaryMock: vi.fn(),
    loadLatestPeopleViewMock: vi.fn(),
    loadLatestRelationshipsViewMock: vi.fn(),
}));

vi.mock('../../data/directory-queries', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../data/directory-queries')>();
    return {
        ...actual,
        LoadDirectoryDashboardSummary: loadSummaryMock,
    };
});

vi.mock('../../data/directory-views', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../data/directory-views')>();
    return {
        ...actual,
        LoadLatestPeopleView: loadLatestPeopleViewMock,
        LoadLatestRelationshipsView: loadLatestRelationshipsViewMock,
    };
});

import { CommonDashboardPageComponent } from '../common-dashboard.page';

describe('CommonDashboardPageComponent DOM rendering (#304)', () => {
    beforeEach(() => {
        loadSummaryMock.mockReset();
        loadLatestPeopleViewMock.mockReset().mockResolvedValue({ entity: null, view: null });
        loadLatestRelationshipsViewMock.mockReset().mockResolvedValue({ entity: null, view: null });
    });

    it('renders the error banner, em-dash stat tiles, and "Could not be read" across all 4 breakdown panels when LoadDirectoryDashboardSummary resolves to null', async () => {
        loadSummaryMock.mockResolvedValue(null);

        const fixture = TestBed.createComponent(CommonDashboardPageComponent);
        await fixture.componentInstance.ngOnInit();
        fixture.detectChanges();

        const host: HTMLElement = fixture.nativeElement;
        const text = host.textContent ?? '';

        // 1. Error banner is rendered in the DOM
        const errorBanner = host.querySelector('.bizapps-stat-row__error');
        expect(errorBanner).not.toBeNull();
        expect(errorBanner?.textContent).toContain('The directory counts could not be read just now.');

        // 2. All 4 stat tiles render '—' rather than '0'
        const statValues = Array.from(host.querySelectorAll('.bizapps-stat__value')).map(el =>
            el.textContent?.trim()
        );
        expect(statValues).toEqual(['—', '—', '—', '—']);

        // 3. All 4 breakdown panels render 'Could not be read' instead of 'Nothing is waiting' / 'No organizations yet.' / 'Nothing is asking for attention'
        const readFailedOccurrences = text.match(/Could not be read/g) ?? [];
        expect(readFailedOccurrences.length).toBeGreaterThanOrEqual(4);
        expect(text).not.toContain('Nothing is waiting');
        expect(text).not.toContain('No organizations yet.');
        expect(text).not.toContain('Nothing is asking for attention');
    });
});
