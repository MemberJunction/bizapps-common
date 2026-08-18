---
"@mj-biz-apps/common-ng": patch
---

feat(common-ng): add interactive visual org chart to OrgHierarchyTree with UserInfoEngine persistence

- Upgrades `OrgHierarchyTreeComponent` to support switching between an interactive **Visual Org Chart Canvas** (powered by `@memberjunction/ng-hierarchy-tree`) and the classic Outline list.
- Integrates user preference persistence via `UserInfoEngine` (`'mj.orgHierarchy.viewMode'`).
- Supports smooth pan, zoom, auto-fit, and direct navigation to parent/subsidiary organization records.
