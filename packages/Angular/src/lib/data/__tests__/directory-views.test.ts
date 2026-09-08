import { describe, expect, it } from 'vitest';
import {
    DIRECTORY_VIEW_NAMES,
    LatestPeopleGridState,
    OrganizationsDirectoryGridState,
    PeopleDirectoryGridState,
    RelationshipsGridState,
} from '../directory-views';

describe('directory views', () => {
    it('puts PhotoURL first on people grids so the viewer can render a thumbnail', () => {
        expect(PeopleDirectoryGridState().columnSettings[0].Name).toBe('PhotoURL');
        expect(LatestPeopleGridState().columnSettings[0].Name).toBe('PhotoURL');
        expect(PeopleDirectoryGridState().columnSettings[0].format).toEqual({ type: 'image' });
    });

    it('puts LogoURL first on the organizations grid', () => {
        expect(OrganizationsDirectoryGridState().columnSettings[0].Name).toBe('LogoURL');
        expect(OrganizationsDirectoryGridState().columnSettings[0].format).toEqual({ type: 'image' });
    });

    it('keeps relationship columns as names, not photos', () => {
        const names = RelationshipsGridState().columnSettings.map((c) => c.Name);
        expect(names).toContain('FromPerson');
        expect(names).toContain('ToOrganization');
        expect(names.some((n) => /photo|logo/i.test(n))).toBe(false);
    });

    it('uses stable view names for metadata lookup', () => {
        expect(DIRECTORY_VIEW_NAMES.People).toBe('Common: People directory');
        expect(DIRECTORY_VIEW_NAMES.LatestPeople).toBe('Common: Latest people');
        expect(DIRECTORY_VIEW_NAMES.Organizations).toBe('Common: Organizations directory');
        expect(DIRECTORY_VIEW_NAMES.LatestRelationships).toBe('Common: Latest relationships');
    });
});
