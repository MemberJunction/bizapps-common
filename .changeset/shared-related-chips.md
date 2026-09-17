---
'@mj-biz-apps/common-ng': minor
---

Add the shared BizApps "Related records" chip row: `bizapps-related-chips`.

A tester walking Deal → Order → Contract found no consistent way to get from a record to the
records linked to it. The Contract header linked its source Deal, the Deal form buried its Order
in a panel, the Order form pointed at nothing, and where a link did exist it sometimes rendered a
GUID instead of a name. Each app had solved a slice of it differently; this is the one they
collapse into.

A caller passes link descriptors naming an entity and either the id it holds (`RecordID`) or a
filter that finds the record holding the id (`Filter`, for a reverse link such as Order → Deal).
The component resolves the entity, reads the record's name, and decides whether the chip may be
drawn at all.

Three behaviours it guarantees, and the reason each is behaviour rather than styling. **A chip
never shows a raw id** — the name comes from the entity's name field, and an entity with no name
field produces no chip rather than a GUID wearing a label. **A chip that cannot navigate is not
rendered** — an entity missing from the catalog (the app is not installed here, or this user may
not read it, which are deliberately one outcome) and a read that succeeded while matching zero
rows both produce nothing, because a link that goes nowhere is worse than an absent one. **A read
that threw is not a record that is absent** — a throw keeps the chip when the link already carried
the id to open, since the record may exist and merely be unreadable this moment.

Clicking a chip emits a `record` navigation event; ctrl or cmd-click sets `OpenInNewTab`. The
component never touches `NavigationService` — a host form wires `Navigate` to its own
`OnFormNavigate`, which keeps it usable from a `BaseFormPanel` hero and a form component override
alike.

Styles are the component's own, design tokens only, under a `bizapps-related` class prefix that
collides with none of the app kits, which are global under `ViewEncapsulation.None`.

The resolve-and-hide rules live in `related-links.ts` rather than in the component, so they can be
tested without standing up Angular DI: `ResolveRelatedChip`, `FilterForRelatedLink`,
`LabelForRelatedLink` and `RelatedChipNavigation` are exported alongside the component.
