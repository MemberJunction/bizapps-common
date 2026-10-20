import '@angular/compiler';
import { describe, expect, it } from 'vitest';

import { DashboardFilterBarComponent } from '../dashboard-filter-bar.component';
import type { DashboardPeriodState } from '../dashboard-period-state';

/**
 * Class-level tests: what the bar emits and what it shows, without rendering. This package has no
 * DOM test setup; consuming apps render it in their own DOM specs.
 */
const COMPANIES = [
    { ID: 'C2', Name: 'Birch' },
    { ID: 'C1', Name: 'Acme' },
];

function bar(): { bar: DashboardFilterBarComponent; companies: string[][]; periods: DashboardPeriodState[] } {
    const component = new DashboardFilterBarComponent();
    component.CompanyOptions = COMPANIES;
    component.Today = '2026-08-15';
    const companies: string[][] = [];
    const periods: DashboardPeriodState[] = [];
    component.SelectedCompanyIDsChange.subscribe((ids) => companies.push(ids));
    component.PeriodStateChange.subscribe((state) => periods.push(state));
    return { bar: component, companies, periods };
}

describe('DashboardFilterBarComponent: companies', () => {
    it('lists the options by name and labels the picker "All" with nothing picked', () => {
        const { bar: b } = bar();
        expect(b.Options.map((o) => o.Name)).toEqual(['Acme', 'Birch']);
        expect(b.CompanyButtonLabel).toBe('Company: All');
    });

    it('emits the whole new list on each toggle, and labels what is picked', () => {
        const { bar: b, companies } = bar();
        b.ToggleCompany('C1');
        b.ToggleCompany('C2');
        expect(companies).toEqual([['C1'], ['C1', 'C2']]);
        expect(b.CompanyButtonLabel).toBe('Company: Acme +1');
        b.ToggleCompany('c1');
        expect(companies[2]).toEqual(['C2']);
    });

    it('clear all goes back to every company, and clearing an empty list emits nothing', () => {
        const { bar: b, companies } = bar();
        b.ClearCompanies();
        expect(companies).toEqual([]);
        b.SelectedCompanyIDs = ['C1'];
        b.ClearCompanies();
        expect(companies).toEqual([[]]);
    });

    it('takes the selection from its input without emitting it back', () => {
        const { bar: b, companies } = bar();
        b.SelectedCompanyIDs = ['C2', 'c2', ''];
        expect(b.SelectedCompanyIDs).toEqual(['C2']);
        expect(b.IsCompanySelected('c2')).toBe(true);
        expect(companies).toEqual([]);
    });
});

describe('DashboardFilterBarComponent: period', () => {
    it('opens on this quarter and spells out its bounds', () => {
        const { bar: b } = bar();
        expect(b.PeriodState.Period).toBe('quarter');
        expect(b.WindowLabel).toBe('Jul 1, 2026 – Sep 30, 2026');
    });

    it('counts quarters from the fiscal start it is given, and names the basis in the tooltip', () => {
        const { bar: b } = bar();
        b.FiscalBasis = { Start: { Month: 4, Day: 6 }, Basis: 'profile' };
        expect(b.WindowLabel).toBe('Jul 6, 2026 – Oct 5, 2026');
        expect(b.PeriodTooltip).toBe('Fiscal year starts Apr 6. Jul 6, 2026 – Oct 5, 2026.');
    });

    it('says the fiscal start is still being read before the app has resolved it', () => {
        const { bar: b } = bar();
        expect(b.PeriodTooltip).toMatch(/^Reading fiscal year start/);
    });

    it('emits a period change once, and ignores an unknown key or the same key', () => {
        const { bar: b, periods } = bar();
        b.SetPeriod('lastyear');
        b.SetPeriod('lastyear');
        b.SetPeriod('decade');
        expect(periods).toEqual([{ Period: 'lastyear', CustomStart: null, CustomEnd: null }]);
        expect(b.WindowLabel).toBe('Jan 1, 2025 – Dec 31, 2025');
    });

    it('a custom range emits its dates, and an emptied input is no bound', () => {
        const { bar: b, periods } = bar();
        b.SetPeriod('custom');
        b.SetCustomRange('2026-02-01', '');
        expect(periods[1]).toEqual({ Period: 'custom', CustomStart: '2026-02-01', CustomEnd: null });
        expect(b.WindowLabel).toBe('from Feb 1, 2026');
    });

    it('normalises a period handed in with stale dates', () => {
        const { bar: b } = bar();
        b.PeriodState = { Period: 'alltime', CustomStart: '2026-01-01', CustomEnd: null };
        expect(b.PeriodState).toEqual({ Period: 'alltime', CustomStart: null, CustomEnd: null });
        expect(b.WindowLabel).toBe('all time');
    });
});
