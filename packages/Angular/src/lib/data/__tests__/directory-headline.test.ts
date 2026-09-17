import { describe, expect, it } from 'vitest';
import { BuildDirectoryHeadline, DIRECTORY_HEADLINE_UNREADABLE, type DirectorySummaryCounts } from '../directory-stats';
import type { DirectoryQueue } from '../directory-types';

/**
 * These pin the one rule the directory dashboard cannot get wrong: a count nobody could read is NOT
 * zero. `LoadDirectoryDashboardSummary` returns `null` when the query fails or comes back empty, and
 * the headline it produces must reach the tiles as nulls — which render an em dash — with the row's
 * error line set, never as four zeros claiming an empty party file.
 */

function queue(count: number, label = `queue-${count}`): DirectoryQueue {
    return { Label: label, Count: count, Icon: 'fa-solid fa-flag', Tone: 'warning', PageId: 'people' };
}

function summary(partial: Partial<DirectorySummaryCounts> = {}): DirectorySummaryCounts {
    return {
        ActivePeopleCount: 120,
        TotalPeopleCount: 120,
        ActiveOrganizationCount: 30,
        TotalOrganizationCount: 30,
        RelationshipCount: 88,
        Queues: [],
        ...partial,
    };
}

describe('BuildDirectoryHeadline', () => {
    describe('a failed read', () => {
        it('leaves every count null rather than zero — zero is a claim the directory is empty', () => {
            const headline = BuildDirectoryHeadline(null);
            expect(headline.ActivePeopleCount).toBeNull();
            expect(headline.ActiveOrganizationCount).toBeNull();
            expect(headline.RelationshipCount).toBeNull();
            expect(headline.GapCount).toBeNull();
        });

        it('says so once, on the row', () => {
            expect(BuildDirectoryHeadline(null).Error).toBe(DIRECTORY_HEADLINE_UNREADABLE);
        });

        it('flags the read as failed, so no section reports itself empty', () => {
            expect(BuildDirectoryHeadline(null).ReadFailed).toBe(true);
        });

        it('drops the footnotes, which have no count left to qualify', () => {
            const headline = BuildDirectoryHeadline(null);
            expect(headline.PeopleDetail).toBeNull();
            expect(headline.OrganizationDetail).toBeNull();
        });

        it('treats undefined the same as null, the shape an unset property arrives as', () => {
            expect(BuildDirectoryHeadline(undefined).ActivePeopleCount).toBeNull();
            expect(BuildDirectoryHeadline(undefined).Error).toBe(DIRECTORY_HEADLINE_UNREADABLE);
        });
    });

    describe('a successful read', () => {
        it('carries the counts through and reports no error', () => {
            const headline = BuildDirectoryHeadline(summary());
            expect(headline.ActivePeopleCount).toBe(120);
            expect(headline.ActiveOrganizationCount).toBe(30);
            expect(headline.RelationshipCount).toBe(88);
            expect(headline.Error).toBeNull();
            expect(headline.ReadFailed).toBe(false);
        });

        it('leaves ReadFailed false for a genuinely empty directory, so the sections still read empty', () => {
            const headline = BuildDirectoryHeadline(
                summary({ ActivePeopleCount: 0, TotalPeopleCount: 0, ActiveOrganizationCount: 0, TotalOrganizationCount: 0, RelationshipCount: 0 }),
            );
            expect(headline.ReadFailed).toBe(false);
        });

        it('keeps a real zero as zero — nothing on file is a legitimate answer, unlike an unread count', () => {
            const headline = BuildDirectoryHeadline(
                summary({ ActivePeopleCount: 0, TotalPeopleCount: 0, RelationshipCount: 0 }),
            );
            expect(headline.ActivePeopleCount).toBe(0);
            expect(headline.RelationshipCount).toBe(0);
            expect(headline.GapCount).toBe(0);
            expect(headline.Error).toBeNull();
        });

        it('sums the queues into the gap count', () => {
            const headline = BuildDirectoryHeadline(summary({ Queues: [queue(3), queue(4), queue(10)] }));
            expect(headline.GapCount).toBe(17);
        });
    });

    describe('the gap tone', () => {
        it('warns on gaps that were actually counted', () => {
            expect(BuildDirectoryHeadline(summary({ Queues: [queue(1)] })).GapTone).toBe('warn');
        });

        it('stays quiet when the count read as zero', () => {
            expect(BuildDirectoryHeadline(summary({ Queues: [] })).GapTone).toBe('none');
        });

        it('stays quiet on an unread count — "could not check" is not "something to fix"', () => {
            expect(BuildDirectoryHeadline(null).GapTone).toBe('none');
        });
    });

    describe('the footnotes', () => {
        it('reads "everyone on file" when active equals total', () => {
            const headline = BuildDirectoryHeadline(summary({ ActivePeopleCount: 120, TotalPeopleCount: 120 }));
            expect(headline.PeopleDetail).toBe('Everyone currently on file');
            expect(headline.OrganizationDetail).toBe('Active organizations');
        });

        it('names the total when inactive records exist', () => {
            const headline = BuildDirectoryHeadline(
                summary({
                    ActivePeopleCount: 120,
                    TotalPeopleCount: 145,
                    ActiveOrganizationCount: 30,
                    TotalOrganizationCount: 41,
                }),
            );
            expect(headline.PeopleDetail).toBe('145 total, including inactive');
            expect(headline.OrganizationDetail).toBe('41 total, including inactive');
        });
    });
});
