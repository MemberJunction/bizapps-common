---
'@mj-biz-apps/common-ng': patch
---

Angular — `ng-graph-view` and `ng-hierarchy-tree` were regular dependencies, so every consumer got a second copy of MJ.

`@mj-biz-apps/common-ng` declared `@memberjunction/ng-graph-view` and `@memberjunction/ng-hierarchy-tree` under
`dependencies`. Every other MJ package this library consumes — eleven of them, including `ng-base-forms`,
`ng-entity-viewer` and `core-entities` — is a peer. These two were the exception, and `ng-graph-view` was in fact
listed in *both* sections.

**A published Angular library must not depend on MJ directly.** A peer says "the host supplies this"; a dependency
says "install your own." For MJ that difference is not cosmetic: a second physical copy of an MJ package means a
second `MJGlobal` class registry and a second set of Angular component/DI tokens, so `@RegisterClass` lookups and
`instanceof` checks silently resolve against the wrong copy. The failure surfaces far from the cause — a component
that renders blank, or a registration that "already exists" — which is exactly the class of bug the peer convention
across the other eleven packages exists to prevent.

**This was reachable, not theoretical.** Both packages are imported at runtime: `ng-graph-view` by
`common-relationship-graph.component.ts`, and `ng-hierarchy-tree` by `org-hierarchy-tree.component.ts`,
`activity-hierarchy.panel.ts` and `activity-type-hierarchy.panel.ts`. A host on a different 6.1.x patch than the one
npm resolved for the nested copy would get two, and npm is free to nest rather than dedupe whenever the host's
resolved version differs from the declared range.

`ng-hierarchy-tree` is added to `peerDependencies` at the same `^6.1.0-edge.6` range the rest of the package already
uses; `ng-graph-view` simply loses its duplicate `dependencies` entry and keeps the peer it already had. The
internal `@mj-biz-apps/common-entities` pin stays a real dependency — it is a sibling released in lockstep, not a
host-supplied package.

**No version ranges were changed.** `^6.1.0-edge.6` already admits 6.1.2 (`semver.satisfies('6.1.2',
'^6.1.0-edge.6')` is `true`), and `ci/sync-mj-app-version.mjs` documents the retained `-edge.N` suffix as
deliberate — it states the floor the code actually needs, since the package imports `MJCard*` components that first
appeared in `6.1.0-edge.3`. Stripping it is recorded there as a previously-reverted mistake, so it is left alone.

Verified by building `@mj-biz-apps/common-ng` before and after the change against an identical tree: three
pre-existing `TS2345` errors in both runs, none of them new. Those three are a local-environment artifact — the
globally linked `@memberjunction/cli` symlink resolves a second `@memberjunction/*` tree out of the MJ checkout, so
`FormNavigationEvent` has two declarations. That duplication is itself the same hazard this change removes from the
published manifest.
