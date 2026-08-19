import '@angular/compiler';
import { describe, it, expect } from 'vitest';
import '../../../../public-api';
import { MJGlobal } from '@memberjunction/global';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';
import type { mjBizAppsCommonActivityEntity } from '@mj-biz-apps/common-entities';
import { ActivityIdentityComponent } from '../../../components/identity-header/activity-identity.component';
import { ActivityHeaderPanel } from '../activity-header.panel';
import { ActivityLinksPanel } from '../activity-links.panel';
import { ActivityFilesPanel } from '../activity-files.panel';
import { ActivityContentPanel } from '../activity-content.panel';

describe('ActivityIdentityComponent and Panel Contributions', () => {
    it('resolves dynamic icon and color by ActivityType', () => {
        const comp = new ActivityIdentityComponent();

        comp.Record = { ActivityType: 'Email' } as mjBizAppsCommonActivityEntity;
        expect(comp.TypeIcon).toBe('fa-solid fa-envelope');
        expect(comp.TypeStyle.color).toBe('#2563eb');

        comp.Record = { ActivityType: 'Call' } as mjBizAppsCommonActivityEntity;
        expect(comp.TypeIcon).toBe('fa-solid fa-phone');
        expect(comp.TypeStyle.color).toBe('#059669');

        comp.Record = { ActivityType: 'Meeting' } as mjBizAppsCommonActivityEntity;
        expect(comp.TypeIcon).toBe('fa-solid fa-calendar-days');
        expect(comp.TypeStyle.color).toBe('#4f46e5');

        comp.Record = { ActivityType: 'Note' } as mjBizAppsCommonActivityEntity;
        expect(comp.TypeIcon).toBe('fa-solid fa-note-sticky');

        comp.Record = { ActivityType: 'Custom' } as mjBizAppsCommonActivityEntity;
        expect(comp.TypeIcon).toBe('fa-solid fa-bolt');
    });

    it('resolves directional icons accurately', () => {
        const comp = new ActivityIdentityComponent();

        comp.Record = { Direction: 'Inbound' } as mjBizAppsCommonActivityEntity;
        expect(comp.DirectionIcon).toBe('fa-solid fa-arrow-down-left');

        comp.Record = { Direction: 'Outbound' } as mjBizAppsCommonActivityEntity;
        expect(comp.DirectionIcon).toBe('fa-solid fa-arrow-up-right');

        comp.Record = { Direction: 'Internal' } as mjBizAppsCommonActivityEntity;
        expect(comp.DirectionIcon).toBe('fa-solid fa-arrows-left-right');
    });

    it('computes status tones accurately', () => {
        const comp = new ActivityIdentityComponent();

        comp.Record = { Status: 'Completed' } as mjBizAppsCommonActivityEntity;
        expect(comp.StatusTone).toBe('success');

        comp.Record = { Status: 'Scheduled' } as mjBizAppsCommonActivityEntity;
        expect(comp.StatusTone).toBe('warning');

        comp.Record = { Status: 'Cancelled' } as mjBizAppsCommonActivityEntity;
        expect(comp.StatusTone).toBe('danger');

        comp.Record = { Status: 'Logged' } as mjBizAppsCommonActivityEntity;
        expect(comp.StatusTone).toBe('info');
    });

    it('computes duration text correctly across various elapsed times', () => {
        const comp = new ActivityIdentityComponent();

        // No end time -> null
        comp.Record = { StartedAt: new Date('2026-08-19T14:00:00Z'), EndedAt: null } as mjBizAppsCommonActivityEntity;
        expect(comp.DurationText).toBeNull();

        // 45 minutes
        comp.Record = {
            StartedAt: new Date('2026-08-19T14:00:00Z'),
            EndedAt: new Date('2026-08-19T14:45:00Z'),
        } as mjBizAppsCommonActivityEntity;
        expect(comp.DurationText).toBe('45m');

        // 1 hour 30 minutes
        comp.Record = {
            StartedAt: new Date('2026-08-19T14:00:00Z'),
            EndedAt: new Date('2026-08-19T15:30:00Z'),
        } as mjBizAppsCommonActivityEntity;
        expect(comp.DurationText).toBe('1h 30m');

        // Exactly 2 hours
        comp.Record = {
            StartedAt: new Date('2026-08-19T14:00:00Z'),
            EndedAt: new Date('2026-08-19T16:00:00Z'),
        } as mjBizAppsCommonActivityEntity;
        expect(comp.DurationText).toBe('2h');
    });

    it('extracts video meeting URL from JSON details', () => {
        const comp = new ActivityIdentityComponent();

        comp.Record = {
            Details: JSON.stringify({ MeetingURL: 'https://zoom.us/j/123456789' }),
        } as mjBizAppsCommonActivityEntity;
        expect(comp.MeetingURL).toBe('https://zoom.us/j/123456789');

        comp.Record = {
            Details: JSON.stringify({ JoinURL: 'https://teams.microsoft.com/l/meetup-join/xyz' }),
        } as mjBizAppsCommonActivityEntity;
        expect(comp.MeetingURL).toBe('https://teams.microsoft.com/l/meetup-join/xyz');

        comp.Record = { Details: null } as mjBizAppsCommonActivityEntity;
        expect(comp.MeetingURL).toBeNull();
    });

    it('formats source display properly', () => {
        const comp = new ActivityIdentityComponent();

        comp.Record = { SourceSystem: 'Microsoft365' } as mjBizAppsCommonActivityEntity;
        expect(comp.SourceDisplay).toBe('Synced from Microsoft365');

        comp.Record = { SourceSystem: null, Source: 'Integration' } as mjBizAppsCommonActivityEntity;
        expect(comp.SourceDisplay).toBe('Synced (Integration)');

        comp.Record = { SourceSystem: null, Source: 'Manual' } as mjBizAppsCommonActivityEntity;
        expect(comp.SourceDisplay).toBe('Manual');
    });

    it('registers ActivityHeaderPanel as a form panel contribution', () => {
        const regs = MJGlobal.Instance.ClassFactory.GetAllRegistrations(BaseFormPanel);
        expect(regs.some(r => r.SubClass === ActivityHeaderPanel)).toBe(true);
    });

    it('registers ActivityLinksPanel as a form panel contribution', () => {
        const regs = MJGlobal.Instance.ClassFactory.GetAllRegistrations(BaseFormPanel);
        expect(regs.some(r => r.SubClass === ActivityLinksPanel)).toBe(true);
    });

    it('registers ActivityFilesPanel as a form panel contribution', () => {
        const regs = MJGlobal.Instance.ClassFactory.GetAllRegistrations(BaseFormPanel);
        expect(regs.some(r => r.SubClass === ActivityFilesPanel)).toBe(true);
    });

    it('registers ActivityContentPanel as a form panel contribution', () => {
        const regs = MJGlobal.Instance.ClassFactory.GetAllRegistrations(BaseFormPanel);
        expect(regs.some(r => r.SubClass === ActivityContentPanel)).toBe(true);
    });

    it('computes word count, char count, and long content detection in ActivityContentPanel', () => {
        const comp = new ActivityContentPanel();
        comp.Record = {
            Description: 'Discussed quarterly roadmap, product launch timelines, and hiring goals for Q3.',
        } as mjBizAppsCommonActivityEntity;

        expect(comp.HasContent).toBe(true);
        expect(comp.WordCount).toBe(11);
        expect(comp.CharacterCount).toBe(79);
        expect(comp.IsLongContent).toBe(false);

        comp.Record.Description = 'A '.repeat(200);
        expect(comp.IsLongContent).toBe(true);
    });
});
