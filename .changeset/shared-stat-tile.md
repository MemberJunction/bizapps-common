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

Two behaviours the tile guarantees: a `null` value renders an em dash rather than `0`, so an
unreadable count can never read as an empty queue; and the tile is focusable, announced as a
button and keyboard-activatable only when something subscribes to `Clicked`.
