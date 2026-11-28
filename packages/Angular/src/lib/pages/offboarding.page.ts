import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Metadata, type IMetadataProvider } from '@memberjunction/core';
import { UUIDsEqual } from '@memberjunction/global';
import { SharedGenericModule } from '@memberjunction/ng-shared-generic';
import { MJButtonDirective } from '@memberjunction/ng-ui-components';
import {
    GroupOffboardingHoldings,
    PlanOffboardingReassign,
    type OffboardingAppActions,
    type OffboardingDomain,
    type OffboardingDomainGroup,
    type OffboardingHolding,
} from '@mj-biz-apps/common-entities';
import {
    FilterOffboardingPeople,
    LeaverOf,
    LoadOffboardingSetup,
    RunOffboardingList,
    RunOffboardingReassign,
    type OffboardingPerson,
    type OffboardingReassignResult,
} from '../data/offboarding-data';

/** How many people the picker lists at once; the search narrows the rest. */
const PICKER_LIMIT = 100;

/**
 * Offboarding: pick a leaver, see everything they still hold across every app that registered an
 * action in the `Offboarding Holdings` category, name a successor per domain, and move it.
 *
 * Works with any number of registered apps, zero included. Permission is decided by each app's
 * actions: `CanReassign` greys rows out here, and the Reassign action re-checks every record.
 */
@Component({
    selector: 'bizapps-common-offboarding-page',
    standalone: true,
    imports: [CommonModule, FormsModule, MJButtonDirective, SharedGenericModule],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <div class="mjo">
            <header class="mjo-head">
                <div class="mjo-head__mark"><i class="fa-solid fa-user-minus" aria-hidden="true"></i></div>
                <div>
                    <h1 class="mjo-head__title">Offboarding</h1>
                    <p class="mjo-head__sub">
                        What a departed user or employee still holds, and who takes it over. Only open items move;
                        history (who created, approved or closed something) stays as it was.
                    </p>
                </div>
            </header>

            @if (LoadingSetup) {
                <mj-loading Text="Loading people and offboarding actions..."></mj-loading>
            } @else {
                @if (SetupError) {
                    <div class="mjo-banner mjo-banner--error"><i class="fa-solid fa-triangle-exclamation"></i> {{ SetupError }}</div>
                }
                @if (Apps.length === 0) {
                    <div class="mjo-empty">
                        <i class="fa-solid fa-plug-circle-xmark" aria-hidden="true"></i>
                        <h3>No app has registered offboarding actions</h3>
                        <p>Apps that hold responsibility (deals, tasks, approvals) add actions to the
                           Offboarding Holdings category. None are installed here yet, so there is nothing to list.</p>
                    </div>
                } @else {
                    <div class="mjo-split">
                        <section class="mjo-card mjo-picker">
                            <h2 class="mjo-card__title">Leaver</h2>
                            <input class="mj-input" type="search" placeholder="Search name or email"
                                   [ngModel]="Search" (ngModelChange)="OnSearch($event)" />
                            <ul class="mjo-people">
                                @for (person of VisiblePeople; track person.Key) {
                                    <li>
                                        <button type="button" class="mjo-person" [class.mjo-person--selected]="IsSelected(person)" (click)="SelectLeaver(person)">
                                            <span class="mjo-person__name">{{ person.Name }}</span>
                                            @if (!person.Active) { <span class="mjo-pill mjo-pill--muted">Inactive</span> }
                                            @if (person.Email) { <span class="mjo-person__email">{{ person.Email }}</span> }
                                        </button>
                                    </li>
                                } @empty {
                                    <li class="mjo-muted">No one matches.</li>
                                }
                            </ul>
                            @if (HiddenCount > 0) { <p class="mjo-muted">{{ HiddenCount }} more; search to narrow.</p> }
                        </section>

                        <section class="mjo-holdings">
                            @if (!Leaver) {
                                <div class="mjo-empty mjo-empty--inline">
                                    <i class="fa-solid fa-hand-pointer" aria-hidden="true"></i>
                                    <p>Pick a person to see what they still hold. Inactive people are listed first.</p>
                                </div>
                            } @else if (LoadingHoldings) {
                                <mj-loading Text="Asking each app what {{ Leaver.Name }} holds..."></mj-loading>
                            } @else {
                                <div class="mjo-leaver">
                                    <h2>{{ Leaver.Name }}</h2>
                                    <span class="mjo-muted">{{ TotalHoldings }} open item{{ TotalHoldings === 1 ? '' : 's' }} across {{ Apps.length }} app{{ Apps.length === 1 ? '' : 's' }}</span>
                                </div>
                                @for (error of ListErrors; track error) {
                                    <div class="mjo-banner mjo-banner--error"><i class="fa-solid fa-triangle-exclamation"></i> {{ error }}</div>
                                }
                                @for (result of LastResults; track result.App + result.Domain) {
                                    <div class="mjo-banner" [class.mjo-banner--error]="!!result.Error" [class.mjo-banner--ok]="!result.Error">
                                        <strong>{{ result.App }} ({{ result.Domain }}):</strong>
                                        moved {{ result.Moved }}@if (result.Skipped.length > 0) {, skipped {{ result.Skipped.length }}}.
                                        @if (result.Error) { {{ result.Error }} }
                                        @if (result.Skipped.length > 0) {
                                            <ul class="mjo-skips">
                                                @for (skip of result.Skipped; track skip.RecordID + skip.Kind) {
                                                    <li>{{ skip.Kind }} {{ skip.RecordID }}: {{ skip.Reason }}</li>
                                                }
                                            </ul>
                                        }
                                    </div>
                                }
                                @if (Groups.length === 0 && ListErrors.length === 0) {
                                    <div class="mjo-empty mjo-empty--inline">
                                        <i class="fa-solid fa-circle-check" aria-hidden="true"></i>
                                        <p>{{ Leaver.Name }} holds nothing open. Nothing to reassign.</p>
                                    </div>
                                }
                                @for (group of Groups; track group.Domain) {
                                    <article class="mjo-card mjo-domain">
                                        <header class="mjo-domain__head">
                                            <h3 class="mjo-card__title">{{ group.Domain }} <span class="mjo-muted">{{ group.Holdings.length }}</span></h3>
                                            <div class="mjo-domain__apply">
                                                <button mjButton variant="primary" size="sm" type="button"
                                                        [disabled]="!CanApply(group)" (click)="Apply(group)">
                                                    <i class="fa-solid fa-right-left" aria-hidden="true"></i>
                                                    Reassign {{ group.ReassignableCount }}
                                                </button>
                                                <select class="mj-input" [ngModel]="SuccessorFor(group.Domain)" (ngModelChange)="SetSuccessor(group.Domain, $event)"
                                                        [disabled]="group.ReassignableCount === 0 || Applying" [attr.aria-label]="'Successor for ' + group.Domain">
                                                    <option value="">Choose a successor...</option>
                                                    @for (person of Successors; track person.Key) {
                                                        <option [value]="person.UserID">{{ person.Name }}</option>
                                                    }
                                                </select>
                                            </div>
                                        </header>
                                        <table class="mjo-table">
                                            <thead><tr><th>What</th><th>Record</th><th>App</th><th>Status</th></tr></thead>
                                            <tbody>
                                                @for (holding of group.Holdings; track holding.App + holding.Kind + holding.RecordID) {
                                                    <tr [class.mjo-row--locked]="!holding.CanReassign">
                                                        <td>{{ holding.KindLabel }}</td>
                                                        <td>{{ holding.Label }}</td>
                                                        <td>{{ holding.App }}</td>
                                                        <td>
                                                            @if (holding.CanReassign) {
                                                                <span class="mjo-pill mjo-pill--ok">Can move</span>
                                                            } @else {
                                                                <span class="mjo-pill mjo-pill--muted">Not by you</span>
                                                            }
                                                            @if (holding.Note) { <div class="mjo-note">{{ holding.Note }}</div> }
                                                        </td>
                                                    </tr>
                                                }
                                            </tbody>
                                        </table>
                                    </article>
                                }
                                @if (Applying) { <mj-loading Text="Reassigning..." Size="small"></mj-loading> }
                            }
                        </section>
                    </div>
                }
            }
        </div>
    `,
    styles: [
        `
            :host { display: block; height: 100%; overflow: auto; }
            .mjo { display: flex; flex-direction: column; gap: var(--mj-space-5); padding: var(--mj-space-6); box-sizing: border-box; min-width: 0; }
            .mjo-head { display: flex; gap: var(--mj-space-3); align-items: center; }
            .mjo-head__mark { width: 48px; height: 48px; border-radius: var(--mj-radius-md); background: var(--mj-brand-primary); color: var(--mj-text-inverse);
                display: flex; align-items: center; justify-content: center; font-size: 20px; flex-shrink: 0; }
            .mjo-head__title { margin: 0; font-size: 1.25rem; font-weight: 700; color: var(--mj-text-primary); }
            .mjo-head__sub { margin: 4px 0 0; font-size: 0.8125rem; color: var(--mj-text-muted); max-width: 72ch; }
            .mjo-split { display: grid; grid-template-columns: minmax(240px, 320px) minmax(0, 1fr); gap: var(--mj-space-4); align-items: start; }
            @media (max-width: 900px) { .mjo-split { grid-template-columns: minmax(0, 1fr); } }
            .mjo-card { background: var(--mj-bg-surface); border: 1px solid var(--mj-border-default); border-radius: var(--mj-radius-md); padding: var(--mj-space-4); }
            .mjo-card__title { margin: 0; font-size: 0.9375rem; font-weight: 600; color: var(--mj-text-primary); }
            .mjo-picker { display: flex; flex-direction: column; gap: var(--mj-space-3); }
            .mjo-people { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 2px; max-height: 60vh; overflow: auto; }
            .mjo-person { width: 100%; text-align: left; background: transparent; border: 1px solid transparent; border-radius: var(--mj-radius-sm);
                padding: var(--mj-space-2); cursor: pointer; display: flex; flex-wrap: wrap; gap: 4px var(--mj-space-2); align-items: center; color: var(--mj-text-primary); }
            .mjo-person:hover { background: var(--mj-bg-surface-hover); }
            .mjo-person--selected { border-color: var(--mj-brand-primary); background: var(--mj-bg-surface-active); }
            .mjo-person__name { font-weight: 600; font-size: 0.875rem; }
            .mjo-person__email { width: 100%; font-size: 0.75rem; color: var(--mj-text-muted); }
            .mjo-holdings { display: flex; flex-direction: column; gap: var(--mj-space-4); min-width: 0; }
            .mjo-leaver { display: flex; align-items: baseline; gap: var(--mj-space-3); flex-wrap: wrap; }
            .mjo-leaver h2 { margin: 0; font-size: 1.125rem; color: var(--mj-text-primary); }
            .mjo-domain { display: flex; flex-direction: column; gap: var(--mj-space-3); }
            .mjo-domain__head { display: flex; justify-content: space-between; align-items: center; gap: var(--mj-space-3); flex-wrap: wrap; }
            .mjo-domain__apply { display: flex; gap: var(--mj-space-2); align-items: center; flex-wrap: wrap; }
            .mjo-domain__apply select { min-width: 220px; }
            .mjo-table { width: 100%; border-collapse: collapse; font-size: 0.8125rem; }
            .mjo-table th { text-align: left; color: var(--mj-text-muted); font-weight: 600; padding: var(--mj-space-2); border-bottom: 1px solid var(--mj-border-default); }
            .mjo-table td { padding: var(--mj-space-2); border-bottom: 1px solid var(--mj-border-subtle); color: var(--mj-text-primary); vertical-align: top; }
            .mjo-row--locked td { color: var(--mj-text-muted); }
            .mjo-note { margin-top: 4px; font-size: 0.75rem; color: var(--mj-text-secondary); }
            .mjo-pill { display: inline-block; padding: 1px 8px; border-radius: 999px; font-size: 0.6875rem; font-weight: 600; }
            .mjo-pill--ok { background: color-mix(in srgb, var(--mj-status-success) 15%, transparent); color: var(--mj-status-success); }
            .mjo-pill--muted { background: var(--mj-bg-surface-sunken); color: var(--mj-text-muted); }
            .mjo-banner { border-radius: var(--mj-radius-sm); padding: var(--mj-space-2) var(--mj-space-3); font-size: 0.8125rem;
                border: 1px solid var(--mj-border-default); color: var(--mj-text-primary); }
            .mjo-banner--error { border-color: var(--mj-status-error); background: color-mix(in srgb, var(--mj-status-error) 8%, transparent); }
            .mjo-banner--ok { border-color: var(--mj-status-success); background: color-mix(in srgb, var(--mj-status-success) 8%, transparent); }
            .mjo-skips { margin: 4px 0 0; padding-left: 18px; }
            .mjo-empty { display: flex; flex-direction: column; align-items: center; text-align: center; gap: var(--mj-space-2);
                padding: var(--mj-space-8) var(--mj-space-4); color: var(--mj-text-muted); }
            .mjo-empty i { font-size: 28px; }
            .mjo-empty h3 { margin: 0; color: var(--mj-text-primary); }
            .mjo-empty p { margin: 0; max-width: 60ch; }
            .mjo-empty--inline { padding: var(--mj-space-6) var(--mj-space-4); border: 1px dashed var(--mj-border-default); border-radius: var(--mj-radius-md); }
            .mjo-muted { color: var(--mj-text-muted); font-size: 0.8125rem; }
        `,
    ],
})
export class CommonOffboardingPageComponent implements OnInit {
    private readonly cdr = inject(ChangeDetectorRef);
    private _provider: IMetadataProvider | null = null;
    private _leaverKey: string | null = null;
    private people: OffboardingPerson[] = [];
    private holdings: OffboardingHolding[] = [];
    private readonly successors = new Map<OffboardingDomain, string>();

    /** The provider to run views and actions against; the default provider when unset. */
    @Input() set Provider(value: IMetadataProvider | null) { this._provider = value; }
    get Provider(): IMetadataProvider | null { return this._provider; }

    /** A person key (`user:<id>` or `employee:<id>`) to select on load, from the tab's query params. */
    @Input() set LeaverKey(value: string | null) {
        this._leaverKey = value;
        this.selectByKey(value);
    }
    get LeaverKey(): string | null { return this._leaverKey; }

    /** Raised when the user picks a leaver, so the resource can keep it in the tab's URL. */
    @Output() LeaverKeyChange = new EventEmitter<string | null>();

    public LoadingSetup = true;
    public SetupError: string | null = null;
    public Apps: OffboardingAppActions[] = [];
    public Search = '';
    public VisiblePeople: OffboardingPerson[] = [];
    public HiddenCount = 0;
    public Successors: OffboardingPerson[] = [];
    public Leaver: OffboardingPerson | null = null;
    public LoadingHoldings = false;
    public Groups: OffboardingDomainGroup[] = [];
    public ListErrors: string[] = [];
    public LastResults: OffboardingReassignResult[] = [];
    public Applying = false;

    public get TotalHoldings(): number {
        return this.holdings.length;
    }

    private get providerToUse(): IMetadataProvider {
        return this._provider ?? Metadata.Provider;
    }

    async ngOnInit(): Promise<void> {
        const setup = await LoadOffboardingSetup(this.providerToUse);
        this.people = setup.People;
        this.Apps = setup.Apps;
        this.SetupError = setup.Error;
        this.LoadingSetup = false;
        this.applyFilter();
        this.cdr.detectChanges();
        this.selectByKey(this._leaverKey);
    }

    public OnSearch(term: string): void {
        this.Search = term;
        this.applyFilter();
        this.cdr.detectChanges();
    }

    private applyFilter(): void {
        const matches = FilterOffboardingPeople(this.people, this.Search);
        this.VisiblePeople = matches.slice(0, PICKER_LIMIT);
        this.HiddenCount = Math.max(0, matches.length - PICKER_LIMIT);
    }

    public IsSelected(person: OffboardingPerson): boolean {
        return this.Leaver?.Key === person.Key;
    }

    private selectByKey(key: string | null): void {
        if (!key || this.LoadingSetup || this.Leaver?.Key === key) {
            return;
        }
        const person = this.people.find((p) => p.Key.toLowerCase() === key.toLowerCase());
        if (person) {
            void this.SelectLeaver(person, false);
        }
    }

    public async SelectLeaver(person: OffboardingPerson, emit = true): Promise<void> {
        this.Leaver = person;
        this.successors.clear();
        this.LastResults = [];
        this.Successors = this.people.filter((p) => p.Active && p.UserID && !(person.UserID && UUIDsEqual(p.UserID, person.UserID)));
        if (emit) {
            this.LeaverKeyChange.emit(person.Key);
        }
        await this.loadHoldings();
    }

    /** Runs every app's List action in parallel; one failing app does not hide the others. */
    private async loadHoldings(): Promise<void> {
        const leaver = this.Leaver;
        if (!leaver) {
            return;
        }
        this.LoadingHoldings = true;
        this.cdr.detectChanges();
        const results = await Promise.all(this.Apps.map((app) => RunOffboardingList(this.providerToUse, app, LeaverOf(leaver))));
        if (this.Leaver?.Key !== leaver.Key) {
            return; // a different leaver was picked while this one loaded
        }
        this.holdings = results.flatMap((r) => r.Holdings);
        this.ListErrors = results.flatMap((r) => (r.Error ? [`${r.App}: ${r.Error}`] : []));
        this.Groups = GroupOffboardingHoldings(this.holdings);
        this.LoadingHoldings = false;
        this.cdr.detectChanges();
    }

    public SuccessorFor(domain: OffboardingDomain): string {
        return this.successors.get(domain) ?? '';
    }

    public SetSuccessor(domain: OffboardingDomain, userID: string): void {
        if (userID) {
            this.successors.set(domain, userID);
        } else {
            this.successors.delete(domain);
        }
        this.cdr.detectChanges();
    }

    public CanApply(group: OffboardingDomainGroup): boolean {
        return !this.Applying && group.ReassignableCount > 0 && !!this.successors.get(group.Domain);
    }

    /** Runs each app's Reassign action for this domain's kinds, then lists again. */
    public async Apply(group: OffboardingDomainGroup): Promise<void> {
        const successor = this.successors.get(group.Domain);
        const leaver = this.Leaver;
        if (!successor || !leaver || !this.CanApply(group)) {
            return;
        }
        this.Applying = true;
        this.cdr.detectChanges();
        const plans = PlanOffboardingReassign(group.Domain, this.holdings);
        this.LastResults = await Promise.all(plans.map((plan) => {
            const app = this.Apps.find((a) => a.App === plan.App) ?? { App: plan.App, ListActionID: null, ReassignActionID: null, ListActionName: null, ReassignActionName: null };
            return RunOffboardingReassign(this.providerToUse, app, plan.Domain, plan.Kinds, LeaverOf(leaver), successor);
        }));
        this.Applying = false;
        await this.loadHoldings();
    }
}
