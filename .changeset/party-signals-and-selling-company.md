---
'@mj-biz-apps/common-entities': minor
'@mj-biz-apps/common-ng': minor
'@mj-biz-apps/common-server': minor
---

Party Signals: a shared answer to "which organizations and people are our customers", plus a
selling-company field that defaults and confirms.

Common owns Organizations and People but cannot see the orders, contracts or sales schemas, and
neither party carries a customer flag or a last-activity date. So nothing that renders a party —
a foreign-key picker above all — has ever been able to tell a customer from any other row in a
directory that can run to hundreds of thousands. It offers the first twenty rows that contain the
typed letters, in no particular order.

**The contract.** An app declares its own customers by shipping ONE query in the new `Party Signals`
query category, returning `PartyKind` (`'organization'` | `'person'`), `PartyID`, `Count` and
`LastActivityAt`, and carrying a `[signal: noun|nouns]` marker in its own `Description` so a caller
can label "4 orders" without knowing what an order is. The category is the registry: Common never
imports an app, and an app joins the answer by shipping metadata, with no code change here.

`@mj-biz-apps/common-entities` exports the contract and the pure union — `PARTY_SIGNALS_CATEGORY`,
the row and roster types, `MergePartySignalRows`, `ParseSignalNouns`, `ChipText`. Party IDs are
matched case-insensitively, because GUIDs arrive in whichever case the provider produced and two
spellings of one organization would otherwise read as two customers.

**Two readers, one definition.** `PartySignalStore` (common-ng) discovers the category through
metadata and runs each query once per session, for Explorer. `Common.GetPartySignals`
(common-server) does the same union server-side for everything that is not Angular — agents, MCP,
reports, scripts. Both run every query as the calling user, so the roster is permission-filtered; a
query the caller cannot read contributes nothing and is named in warnings rather than failing the
call, so a missing signal weakens ranking instead of breaking the field.

**`bizapps-selling-company-field`.** The company on an order or a contract decides which legal
entity books the revenue, and the picker behind it lists every company row the instance has. Apps
have defaulted it by whichever company sorted first alphabetically, or by the first product on the
order — rules nobody wrote down. This field defaults to the current user's own company when they
have one and it is a company the instance knows, otherwise to the new Common `DefaultSellingCompanyID`
setting, otherwise to nothing. Anything else is held, named back to the user against the default,
and written only on confirm; an unanswered question reverts, because it must not decide where
revenue lands. It wraps `mj-form-field`, so the dropdown, keyboard behaviour and link rendering
stay the platform's.

**Metadata.** `AllowMultipleSubtypes` is now set on Organizations and People, because both are
extended as IsA children and the disjoint default mis-chains silently. `AllowRecordMerge` is not:
`CK_Entity_AllowRecordMerge` requires `AllowDeleteAPI = 1` and `DeleteType = 'Soft'`, and both
parties are hard-delete, so enabling merge is a schema change rather than a flag and belongs in its
own release. `Organizations.Website` and
`People.Title` join user search, with `BeginsWith` predicates and `AutoUpdate` pins so CodeGen
cannot flip them back; the other identifying fields were already flagged.

The party lookup strategy that consumes all of this is a separate release: it needs the platform
foreign-key lookup-strategy seam, which nothing here waits on.
