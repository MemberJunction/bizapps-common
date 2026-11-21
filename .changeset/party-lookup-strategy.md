---
'@mj-biz-apps/common-ng': minor
---

The party picker: every foreign key pointing at an organization or a person now offers customers
first.

Such a field has had no way to tell a customer from any other row in a directory that runs to
hundreds of thousands. It offered the first rows containing the letters typed, in no particular
order, with nothing on screen to separate two similar names — so an acronym could return four
organizations that merely contain those letters, and picking the wrong one left a record that
looked entirely correct afterwards.

`PartyLookupStrategy` registers against `MJ_BizApps_Common: Organizations` and `People`, so it
attaches to every such foreign key at once — no consuming app imports it or knows it exists.

- **Customers first**, from the `Party Signals` roster, behind a Customers / All toggle.
- **Ranked** by `RankPartyMatches`: prefix before contains, then customers before strangers, then
  most recent activity, then alphabetical. The prefix tier deliberately stays above the customer
  rule — someone typing a prefix is naming a record, not asking for their customer list.
- **A second line** of city, state and website or email, which is what actually separates two
  same-named parties.
- **A chip per app** — "4 orders", "1 contract" — from each signal query's declared nouns.
- **People at the chosen organization first**, from active Employee relationships with an open
  date window, when the host passes `ScopeField`.
- **Inactive parties hidden** unless the host passes `IncludeInactive`.

The wide scope goes through the platform's own search path with `SearchMode: 'hybrid'` set
unconditionally: MJ falls back to an escaped LIKE when the search API returns nothing, so asking
for hybrid before any vectors exist costs a no-op and starts working the moment they do, with no
second change here.

Everything not party-specific is inherited — the dropdown, keyboard handling, the column plan,
recent picks, the create-new footer, and all the querying. Requires `@memberjunction/ng-base-forms`
with the `FKLookupStrategy` seam.
