---
'@mj-biz-apps/common-entities': patch
---

Move to MJ `6.1.0-edge.5`, and drop the two exact `ng-*` pins.

All 41 `@memberjunction/*` dependencies now use `^6.1.0-edge.5`. They were spread across three
versions — `^6.1.0-edge.2` (2), `^6.1.0-edge.3` (37), and an **exact** `6.1.0-edge.3` on
`ng-graph-view` and `ng-hierarchy-tree` (2).

Those two exact pins are the shape bizapps-orders removed for cause: an exact `ng-hierarchy-tree` pin
*"forced two MJ copies into consumers' Explorer trees and split the ClassFactory registry"*. Caret,
never exact.

This also matters to consumers rather than just to this repo: `common-entities@5.37.0` publishes with
`@memberjunction/*` at `^6.1.0-edge.3`, so anything installing bizapps-common alongside an
edge.5 app resolves two MJ trees. bizapps-sales hit exactly that.

Verified after a clean install: a single `@memberjunction/core` at `6.1.0-edge.5`, zero packages left
at edge.2 or edge.3, and build 7/7.
