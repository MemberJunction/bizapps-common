---
'@mj-biz-apps/common-ng': minor
---

Add the shared BizApps dashboard stat tile: `bizapps-stat-tile` and `bizapps-stat-row`.

Orders grew the first version of this tile and the other apps each grew a near-copy; this is
the one they collapse into. It is a rewrite rather than a move — Orders' version rendered
`class="mj-stat"` with every rule living in `orders-kit.css`, so copied into another app it
rendered as three unstyled spans. Styles are now the component's own, design tokens only, under
a `bizapps-stat` prefix that collides with neither `.mj-stat` (orders-kit) nor `.mjc-stat`
(contracts-kit).

Two behaviours the tile guarantees. A `null` or `undefined` value renders an em dash rather
than `0`, so an unreadable count can never read as an empty queue — a real `0` still renders
as `0`. And a tile that does nothing is not focusable, not announced as a button and not
keyboard-activatable: the `Clickable` input decides, and when it is unset the tile falls back
to whether anything subscribes to `Clicked`. Passing `Clickable` overrides that inference in
both directions, which a row mixing live and inert tiles needs — Angular subscribes to an
output whenever a template binds it, whatever the handler expression later evaluates to.

`bizapps-stat-tile` takes `Label`, `Icon`, `Value`, `Detail`, `Tone` and `Clickable`, and emits
`Clicked`. `bizapps-stat-row` takes `Error` and renders the row's one shared error line.
