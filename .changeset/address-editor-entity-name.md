---
"@mj-biz-apps/common-ng": patch
---

Fix address editor: adding an address failed with a SQL uniqueidentifier conversion error.

`person-form` and `organization-form` passed the address editor a DOTTED entity name
(`MJ.BizApps.Common: People`). The authoritative prefix is UNDERSCORED —
`MJ_BizApps_Common: `, as declared in this repo's own `metadata/schema-info/.schema-info.json`
— so the lookup missed and `loadData()` returned early, leaving both `resolvedEntityID` and
`AddressTypes` empty. The editor still rendered an editable form, so saving sent empty strings
into `AddressLink.EntityID` and `AddressLink.AddressTypeID` (both NOT NULL uniqueidentifier),
and the insert died at the database with "Conversion failed when converting from a character
string to uniqueidentifier". This is the same dots-vs-underscores mistake that took down ORDER
CONFIRM in bizapps-orders (corrected there 2026-08-03); these two templates were the last live
instances in the estate.

Also hardens the component so a bad `EntityName` can no longer reach the database:

- resolve via `Metadata.EntityByName()` rather than `Entities.find(e => e.Name === …)` — the
  MJ-documented lookup, case- and whitespace-insensitive and O(1); the strict equality check is
  what turned a near-miss into a total miss
- a new `LoadError` state renders the misconfiguration in the UI instead of console-only
- `onSave()` refuses to save when the entity or the address type is unresolved, naming which
