import { describe, expect, it } from 'vitest';
import {
    BuildDirectoryQueues,
    CountByDay,
    CountByLabel,
    EscapeFilterValue,
    EscapeLikeValue,
    PeopleMissingEmail,
    PersonEmail,
} from '../directory-stats';
import type { DirectoryOrganizationRow, DirectoryPersonRow } from '../directory-types';
import { COMMON_ENTITIES } from '../entity-names';

function person(partial: Partial<DirectoryPersonRow> & Pick<DirectoryPersonRow, 'ID' | 'DisplayName'>): DirectoryPersonRow {
    return {
        FirstName: 'Ada',
        LastName: 'Lovelace',
        Email: null,
        PrimaryEmail: null,
        Phone: null,
        PrimaryPhone: null,
        Status: 'Active',
        Title: null,
        CurrentOrganizationName: null,
        CurrentOrganizationID: null,
        PrimaryAddressCity: null,
        __mj_CreatedAt: new Date('2026-08-01T12:00:00Z'),
        ...partial,
    };
}

function org(partial: Partial<DirectoryOrganizationRow> & Pick<DirectoryOrganizationRow, 'ID' | 'Name'>): DirectoryOrganizationRow {
    return {
        LegalName: null,
        Status: 'Active',
        OrganizationType: null,
        OrganizationTypeID: null,
        Website: null,
        Email: null,
        Phone: null,
        Parent: null,
        PrimaryAddressCity: null,
        __mj_CreatedAt: new Date('2026-08-01T12:00:00Z'),
        ...partial,
    };
}

describe('COMMON_ENTITIES', () => {
    it('uses the generated entity names (dots, not underscores, in Common)', () => {
        expect(COMMON_ENTITIES.Person).toBe('MJ_BizApps_Common: People');
        expect(COMMON_ENTITIES.Organization).toBe('MJ_BizApps_Common: Organizations');
        expect(COMMON_ENTITIES.Relationship).toBe('MJ_BizApps_Common: Relationships');
    });
});

describe('directory-stats', () => {
    it('prefers PrimaryEmail over Email', () => {
        const row = person({ ID: '1', DisplayName: 'Ada', Email: 'old@x.com', PrimaryEmail: 'ada@x.com' });
        expect(PersonEmail(row)).toBe('ada@x.com');
    });

    it('queues only the gaps that exist', () => {
        const people = [
            person({ ID: '1', DisplayName: 'No Mail' }),
            person({ ID: '2', DisplayName: 'Has Mail', PrimaryEmail: 'a@b.com', CurrentOrganizationID: 'org-1' }),
        ];
        const orgs = [org({ ID: 'org-1', Name: 'Untyped Co' })];
        const queues = BuildDirectoryQueues(people, orgs);
        expect(queues.map((q) => q.Label)).toEqual([
            'People without email',
            'People without an organization',
            'Organizations without a type',
            'Organizations without a website',
        ]);
        expect(PeopleMissingEmail(people)).toHaveLength(1);
    });

    it('counts rows per local day', () => {
        const today = new Date();
        const bars = CountByDay([{ __mj_CreatedAt: today }, { __mj_CreatedAt: today }]);
        expect(bars).toHaveLength(7);
        expect(bars[6].Current).toBe(true);
        expect(bars[6].Value).toBe(2);
    });

    it('groups mix labels and sorts by count', () => {
        const rows = CountByLabel([{ Label: 'Company' }, { Label: 'Company' }, { Label: 'Chapter' }]);
        expect(rows[0]).toEqual({ Label: 'Company', Value: 2 });
        expect(rows[1]).toEqual({ Label: 'Chapter', Value: 1 });
    });

    it('escapes quotes and drops NULs for ExtraFilter', () => {
        expect(EscapeFilterValue("O'Brien")).toBe("O''Brien");
        expect(EscapeFilterValue('a\0b')).toBe('ab');
    });

    it('bracket-escapes LIKE wildcards in EscapeLikeValue', () => {
        expect(EscapeLikeValue('100%')).toBe('100[%]');
        expect(EscapeLikeValue('a_b')).toBe('a[_]b');
        expect(EscapeLikeValue('[x]')).toBe('[[]x]');
        expect(EscapeLikeValue("O'Brien\0")).toBe("O''Brien");
    });
});
