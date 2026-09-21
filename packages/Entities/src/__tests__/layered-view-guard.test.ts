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
 * Three assertions per view, and they fail for different reasons on purpose.
 *
 * 1. THE NEWEST DEFINER IS THE ONE WE THINK IT IS. `newestViewDefiner` matches any DDL naming the
 *    view and throws if a later migration carries view DDL naming it without matching. The previous
 *    generation of these guards matched only `CREATE OR ALTER VIEW`, so a `DROP VIEW` +
 *    `CREATE VIEW` definer was filtered out and the selector fell back to older SQL while
 *    reporting success. Both views here are defined with `DROP` + `CREATE`, so under the old
 *    selector a guard over them would have resolved NOTHING.
 *
 * 2. THE LOAD-BEARING PREDICATES SURVIVE. Curated by hand, because only a person knows which
 *    predicates carry meaning. Every entry below narrows a join or a subquery; drop one and the
 *    column keeps its name, keeps its type, and starts answering a different question. That is the
 *    half a diff does not show and a column check cannot reach.
 *
 * 3. A RE-CREATION MAY ADD COLUMNS BUT NEVER DROP ONE. Cheap and needs no curation. Both sides of the comparison are read
 *    through `producedColumns`, so the columns inherited through `g.*` from the generated
 *    inner view are protected too — an alias-only BEFORE left every one of them free to
 *    disappear the moment a re-creation spelled the star out as an explicit list.
 *
 * There is no business-day assertion here: neither view joins `fnBusinessToday()`, and an
 * assertion about a predicate a view does not have would pass forever without reading anything.
 */
import { describe, expect, it } from 'vitest';
import { fileURLToPath } from 'node:url';
import {
    newestViewDefiner,
    producedColumns,
    viewBody,
} from './helpers/view-definer';

const MIGRATIONS = fileURLToPath(new URL('../../../../migrations', import.meta.url));

/**
 * Predicates that must survive every re-creation, per view. Matched against the view's own body
 * with comments stripped, so a copied comment block cannot satisfy one.
 */
const REQUIRED: Record<string, RegExp[]> = {
    vwPeople: [
        // The outer view must read the CodeGen base view, never the Person table. Reaching past it
        // is how the archived vwPeopleExtended had to restate the FK-denormalisation block, and how
        // a foreign key added later silently lost its display column.
        /FROM\s+\[\$\{flyway:defaultSchema\}\]\.\[vwPeopleGenerated\]/i,
        // THE POLYMORPHIC ADDRESSLINK NARROWING, and the single most dangerous line in the file.
        // BOTH SPELLINGS OF THE MJ SCHEMA ARE ACCEPTED. This repo's migrations write it as
        // `[${mjSchema}]` 2044 times and as a literal `[__mj]` 553 times, and CodeGen emits the
        // placeholder — so pinning the literal failed the guard on correct SQL the moment anyone
        // re-created the view the way the generator writes it.
        // AddressLink rows for every entity share one table, so without this subquery the join
        // matches another entity's addresses. The prefix is UNDERSCORED; the dotted spelling
        // returns NULL, `al.EntityID = NULL` matches nothing, and every primary-address column
        // comes back NULL — indistinguishable from "this person has no address".
        /al\.\[EntityID\]\s*=\s*\(\s*SELECT\s+\[ID\]\s+FROM\s+(?:\[__mj\]|\[\$\{mjSchema\}\])\.\[Entity\]\s+WHERE\s+\[Name\]\s*=\s*'MJ_BizApps_Common: People'\s*\)/i,
        // Without IsPrimary the address join fans out over every linked address and the row
        // duplicates — silently, since each copy looks plausible on its own.
        /al\.\[IsPrimary\]\s*=\s*1/i,
        // PrimaryEmail / PrimaryPhone are ContactMethod rows selected BY TYPE. Lose either
        // subquery and the column returns whichever contact method happens to sort first — a phone
        // number in the email column is the failure mode.
        /\[ContactType\]\s*WHERE\s+\[Name\]\s*=\s*'Email'/i,
        /\[ContactType\]\s*WHERE\s+\[Name\]\s*=\s*'Mobile Phone'/i,
        /cm_email\.\[IsPrimary\]\s*=\s*1/i,
        /cm_phone\.\[IsPrimary\]\s*=\s*1/i,
        // CURRENT EMPLOYER is three predicates wearing one name. `rt.Name = 'Employee'` is what
        // makes it employment rather than any relationship at all; `Status = 'Active'` is what
        // makes it current; TOP 1 with ORDER BY StartDate DESC is what makes it the latest. Drop
        // the ORDER BY and TOP 1 returns an arbitrary row that is right most of the time.
        /rt\.\[Name\]\s*=\s*'Employee'/i,
        /r\.\[Status\]\s*=\s*'Active'/i,
        /SELECT\s+TOP\s+1\b[\s\S]*?ORDER\s+BY\s+r\.\[StartDate\]\s+DESC/i,
    ],
    vwOrganizations: [
        /FROM\s+\[\$\{flyway:defaultSchema\}\]\.\[vwOrganizationsGenerated\]/i,
        // Same polymorphic narrowing, same underscored-prefix trap, same silent all-NULL result.
        /al\.\[EntityID\]\s*=\s*\(\s*SELECT\s+\[ID\]\s+FROM\s+(?:\[__mj\]|\[\$\{mjSchema\}\])\.\[Entity\]\s+WHERE\s+\[Name\]\s*=\s*'MJ_BizApps_Common: Organizations'\s*\)/i,
        /al\.\[IsPrimary\]\s*=\s*1/i,
        /\[ContactType\]\s*WHERE\s+\[Name\]\s*=\s*'Email'/i,
        /\[ContactType\]\s*WHERE\s+\[Name\]\s*=\s*'Mobile Phone'/i,
        /cm_email\.\[IsPrimary\]\s*=\s*1/i,
        /cm_phone\.\[IsPrimary\]\s*=\s*1/i,
        // ActivePersonCount counts PEOPLE. RelationshipType.Category is the only thing separating
        // a person-to-organization row from an organization-to-organization one, and both live in
        // the same table pointing at the same ToOrganizationID. Drop the category and a holding
        // company's subsidiaries start counting as staff — a number that stays plausible.
        /rt\.\[Category\]\s*=\s*'PersonToOrganization'/i,
        /r\.\[Status\]\s*=\s*'Active'/i,
        // ChildOrgCount is a COUNT of active children. Without the status filter, organizations
        // merged away years ago keep inflating it.
        /child\.\[Status\]\s*=\s*'Active'/i,
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

            it('never reintroduces a fragment known to fail silently', () => {
                const { code, file } = newestViewDefiner(MIGRATIONS, view);
                const body = viewBody(code, view);
                for (const forbidden of FORBIDDEN[view] ?? []) {
                    expect(body, `${file} reintroduced ${forbidden}`).not.toMatch(forbidden);
                }
            });

            it('drops no column a previous definer produced', () => {
                const { chain } = newestViewDefiner(MIGRATIONS, view);
                if (chain.length < 2) return;
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
