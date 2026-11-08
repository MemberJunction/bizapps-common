---
"@mj-biz-apps/common-ng": minor
---

feat(forms): tailor Person / Organization / Activity forms with section counts and hide-when-empty (needs the MJ core `whenEmpty` / `showCount` support).

- Hub defaults: People, Organizations and Addresses set `UI.Form.RelatedWhenEmpty: 'more'`, so an empty related section from any installed app moves into More instead of taking a rail slot. An app that wants its section always visible sets `whenEmpty: 'show'` on its relationship.
- Contact Methods and Addresses are explicitly `'show'` — the first row is created there.
- Relationships (outgoing) and Child Organizations demote to More when empty; the inverse Relationships views and Address → Activities hide when empty.
- Contributions: Relationships, Job Functions and Activity Files demote to More when empty; hierarchy trees opt out of counting (`count: false`) because they show lineage, not just children. `sectionKey` added where a panel's section key differs from its contribution key.
