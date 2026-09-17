---
'@mj-biz-apps/common-ng': patch
---

Directory dashboard now renders the shared `bizapps-stat-tile` instead of its own tiles.

The page carried a fifth near-copy of the dashboard tile — same label/value/detail structure, same
tokens, same hover rule as the shared component, and living in the same package that exports the
replacement, which made it the copy most likely to drift.

Two things were not a mechanical swap:

`Clickable` is now passed explicitly on every tile. Two of the four were real buttons and two were
inert `div`s, and the component's default inference — "is anything listening to `Clicked`" — cannot
tell them apart, because a template binding counts as a subscriber whatever its handler does. The
two inert tiles pass `[Clickable]="false"` and stay unfocusable, with no `role` and no pointer.

The Gaps tile's whole-tile alert is now `Tone="warn"` on the value. The shared component colours the
number only, so the tinted background and amber border are gone. Note that in dark theme
`--mj-status-warning-text` resolves to `--mj-color-warning-100` (`#fef3c7`), which sits very close to
the primary text colour on `--mj-bg-surface` — the warn tone reads clearly in light theme but is
faint in dark. That is a property of the status token ramp, not of this page.

Responsive behaviour changes below 1200px: the page's own breakpoints dropped the row to 2 columns
and then 1, while the shared row keeps 4 columns down to 808px and reflows from there. Desktop width
is unchanged.
