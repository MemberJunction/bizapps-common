/**
 * @fileoverview The guard that would have caught bizapps-contracts PR #59, for this repo's views.
 *
 * `vwPeople` and `vwOrganizations` are the highest-blast-radius layered views in the family and had
 * no guard at all. `vwPeople` is read ACROSS APP BOUNDARIES — bizapps-sales' `vwSalesContacts`
 * selects `DisplayName` and `PrimaryEmail` straight out of `[__mj_BizAppsCommon].[vwPeople]` — so a
 * predicate lost here surfaces as wrong data in another repo's pickers, where nobody will think to
 * look at a common migration. `vwOrganizations` has already been re-typed by hand once
 * (V202609071200 added two coordinate columns to a 100-line view), which is the exact manoeuvre
 * that lost #59 its predicates.
 *
 * ---------------------------------------------------------------------------------------------
 * WHAT A CURATED PREDICATE IS ALLOWED TO BE. Adversarial review found the previous list failing in
 * BOTH directions, which is the worst place a guard can be: it passed semantics-breaking rewrites
 * and failed semantics-preserving ones.
 *
 * So only two kinds of thing are curated here, because only two kinds survive a legitimate rewrite:
 *
 *   - A STRING LITERAL. `'MJ_BizApps_Common: People'` is the same text however the SQL around it is
 *     formatted, and it cannot be reformatted away. If it is gone, the meaning changed.
 *   - A REFERENCED OBJECT NAME, matched through `references()` — the selector's own name matcher, so
 *     bracketed, bare and `${...}`-qualified spellings are all the same name, because to the
 *     database they are.
 *
 * Everything that was SYNTAX is gone, each entry for a measured reason:
 *
 *   - The `al.[EntityID] = (SELECT [ID] FROM [__mj].[Entity] WHERE …)` pattern spelled out a
 *     subquery, two bracketed columns, a keyword order and BOTH accepted spellings of the MJ schema.
 *     Every one of those is reformattable; the entity NAME inside it is not, and that name is the
 *     whole narrowing. So the literal stays and the scaffolding goes.
 *   - `cm_email.[IsPrimary] = 1`, `cm_phone.[IsPrimary] = 1`, `al.[IsPrimary] = 1`, `rt.[Name] =`,
 *     `r.[Status] =`, `child.[Status] =`, `rt.[Category] =` all pinned ALIASES. Renaming
 *     `cm_email` to `email` is a no-op to the database and was a red build here.
 *   - `SELECT TOP 1 [\s\S]*? ORDER BY r.[StartDate] DESC` bridged two clauses with a wildcard. That
 *     kind of pattern is how a false GREEN happens too: the wildcard spans whatever sits between,
 *     so it goes on matching across edits that broke the pairing it was written to protect.
 *   - `FROM \[\$\{flyway:defaultSchema\}\]\.\[vwPeopleGenerated\]` pinned one spelling of a name
 *     this repo writes both ways — `[${mjSchema}]` 2044 times and a literal `[__mj]` 553 times, and
 *     CodeGen emits the placeholder.
 *
 * WHAT THIS DELIBERATELY NO LONGER CATCHES, so nobody is surprised: a rewrite that keeps every
 * literal and every object name but changes a join's CARDINALITY — turning an outer join inner,
 * dropping `IsPrimary = 1` so the address join fans out, dropping `TOP 1`'s `ORDER BY` — passes
 * here. That is not an oversight, it is the price of a list that never fails correct work.
 * `producedColumns` covers the "a column vanished" half; the row-count half belongs to a test with
 * a database behind it, not to a regex over DDL.
 *
 * Four assertions per view, and they fail for different reasons on purpose.
 *
 * 1. THE NEWEST DEFINER IS THE ONE WE THINK IT IS. `newestViewDefiner` matches any DDL naming the
 *    view and throws if a later migration carries view DDL naming it without matching. The previous
 *    generation of these guards matched only `CREATE OR ALTER VIEW`, so a `DROP VIEW` +
 *    `CREATE VIEW` definer was filtered out and the selector fell back to older SQL while
 *    reporting success. Both views here are defined with `DROP` + `CREATE`, so under the old
 *    selector a guard over them would have resolved NOTHING.
 *
 * 2. THE LOAD-BEARING LITERALS AND NAMES SURVIVE. Curated by hand, because only a person knows
 *    which ones carry meaning. Every entry below is the identity of something the view looks up;
 *    drop one and the column keeps its name, keeps its type, and starts answering a different
 *    question. That is the half a diff does not show and a column check cannot reach.
 *
 * 3. A FRAGMENT KNOWN TO FAIL SILENTLY NEVER COMES BACK.
 *
 * 4. A RE-CREATION MAY ADD COLUMNS BUT NEVER DROP ONE. Cheap and needs no curation. Both sides of
 *    the comparison are read through `producedColumns`, so the columns inherited through `g.*` from
 *    the generated inner view are protected too — an alias-only BEFORE left every one of them free
 *    to disappear the moment a re-creation spelled the star out as an explicit list.
 *
 * There is no business-day assertion here: neither view joins `fnBusinessToday()`, and an
 * assertion about a predicate a view does not have would pass forever without reading anything.
 */
import { describe, expect, it } from 'vitest';
import { fileURLToPath } from 'node:url';
import {
    newestViewDefiner,
    producedColumns,
    references,
    viewBody,
} from './helpers/view-definer';

const MIGRATIONS = fileURLToPath(new URL('../../../../migrations', import.meta.url));

/**
 * Literals and object names that must survive every re-creation, per view. Matched against the
 * view's own body with comments stripped, so a copied comment block cannot satisfy one.
 *
 * String literals are matched CASE-SENSITIVELY: under a case-sensitive collation `'active'` and
 * `'Active'` are different values, so a guard that accepted either would be lying about which.
 */
const REQUIRED: Record<string, RegExp[]> = {
    vwPeople: [
        // The outer view must read the CodeGen base view, never the Person table. Reaching past it
        // is how the archived vwPeopleExtended had to restate the FK-denormalisation block, and how
        // a foreign key added later silently lost its display column.
        references('vwPeopleGenerated'),
        // THE POLYMORPHIC ADDRESSLINK NARROWING, and the single most dangerous line in the file.
        // AddressLink rows for every entity share one table, so without this entity name the join
        // matches another entity's addresses. The prefix is UNDERSCORED; the dotted spelling
        // returns NULL, `al.EntityID = NULL` matches nothing, and every primary-address column
        // comes back NULL — indistinguishable from "this person has no address".
        /'MJ_BizApps_Common: People'/,
        // PrimaryEmail / PrimaryPhone are ContactMethod rows selected BY TYPE NAME. Lose either
        // name and the column returns whichever contact method happens to sort first — a phone
        // number in the email column is the failure mode.
        /'Email'/,
        /'Mobile Phone'/,
        // CURRENT EMPLOYER is two identities wearing one column name. `'Employee'` is what makes it
        // employment rather than any relationship at all, and `'Active'` is what makes it current.
        /'Employee'/,
        /'Active'/,
    ],
    vwOrganizations: [
        references('vwOrganizationsGenerated'),
        // Same polymorphic narrowing, same underscored-prefix trap, same silent all-NULL result.
        /'MJ_BizApps_Common: Organizations'/,
        /'Email'/,
        /'Mobile Phone'/,
        // ActivePersonCount counts PEOPLE. This category is the only thing separating a
        // person-to-organization row from an organization-to-organization one, and both live in the
        // same table pointing at the same ToOrganizationID. Drop it and a holding company's
        // subsidiaries start counting as staff — a number that stays plausible.
        /'PersonToOrganization'/,
        // Both counts are of ACTIVE rows: without it, relationships ended years ago and
        // organizations merged away years ago keep inflating them.
        /'Active'/,
    ],
};

/**
 * Fragments that must NEVER appear, per view. The dotted entity prefix is a bug that has already
 * shipped twice in this family — it broke ORDER CONFIRM in bizapps-orders and the address editor
 * here — and it is asserted as a negative because the dotted form fails by returning NULL rather
 * than by erroring, so nothing else would notice it coming back.
 */
const FORBIDDEN: Record<string, RegExp[]> = {
    vwPeople: [/MJ\.BizApps\.Common:\s*People/i],
    vwOrganizations: [/MJ\.BizApps\.Common:\s*Organizations/i],
};

describe('layered views: the newest definer is resolvable and loses nothing', () => {
    /**
     * A forbidden entry that names a view nobody guards, or that is present but empty, asserts
     * nothing while looking like it does. Both are caught here rather than by a silently empty loop.
     */
    it('curates no forbidden list for a view this file does not guard', () => {
        for (const [view, forbidden] of Object.entries(FORBIDDEN)) {
            expect(REQUIRED[view], `FORBIDDEN names ${view}, which is not a guarded view`).toBeDefined();
            expect(forbidden, `FORBIDDEN[${view}] is empty — remove it or fill it in`).not.toEqual([]);
        }
    });

    for (const view of Object.keys(REQUIRED)) {
        describe(view, () => {
            it('resolves a newest definer, and nothing later redefines it unseen', () => {
                const definer = newestViewDefiner(MIGRATIONS, view);
                expect(definer.file).toBeTruthy();
                expect(definer.chain.length).toBeGreaterThan(0);
            });

            it('keeps every predicate that must survive a re-creation', () => {
                const { code, file } = newestViewDefiner(MIGRATIONS, view);
                const body = viewBody(code, view);
                expect(body, `${file} has no CREATE VIEW body for ${view}`).toBeTruthy();
                for (const required of REQUIRED[view]) {
                    expect(body, `${file} lost ${required}`).toMatch(required);
                }
            });

            it('never reintroduces a fragment known to fail silently', (context) => {
                const forbidden = FORBIDDEN[view];
                // NOT `?? []`. A view with no forbidden entry used to run this test with an empty
                // loop and report a PASS — a green tick standing for zero assertions, which on a
                // results page is indistinguishable from a check that actually ran.
                if (forbidden === undefined) {
                    context.skip(`nothing is forbidden for ${view}, so this asserts nothing`);
                    return;
                }
                const { code, file } = newestViewDefiner(MIGRATIONS, view);
                const body = viewBody(code, view);
                expect(body, `${file} has no CREATE VIEW body for ${view}`).toBeTruthy();
                for (const pattern of forbidden) {
                    expect(body, `${file} reintroduced ${pattern}`).not.toMatch(pattern);
                }
            });

            it('drops no column a previous definer produced', (context) => {
                const { chain } = newestViewDefiner(MIGRATIONS, view);
                // A view with a single definer has no BEFORE to compare a re-creation against. This
                // used to `return` quietly and report a pass, so the day someone consolidated the
                // history into one migration the column guard would have switched itself off with
                // nothing in the output to say so.
                if (chain.length < 2) {
                    context.skip(`${view} has one definer (${chain[0]}) — there is no BEFORE to compare`);
                    return;
                }
                const previous = chain[chain.length - 2];
                // BOTH SIDES ARE READ THE SAME WAY: own columns plus the ones inherited through
                // `g.*`, each measured as of the migration it belongs to. Comparing an alias-only
                // BEFORE against an inheritance-aware NOW left every inherited column unprotected —
                // a re-creation that replaced `g.*` with an explicit list minus one column passed.
                const before = producedColumns(MIGRATIONS, view, previous);
                expect(before, `${previous} produced no readable columns — this check is vacuous`).not.toEqual([]);
                const now = producedColumns(MIGRATIONS, view);
                const lost = before.filter((column) => !now.includes(column));
                expect(lost, `columns ${previous} produced and the newest definer does not`).toEqual([]);
            });
        });
    }
});
