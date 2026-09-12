---
'@mj-biz-apps/common-ng': patch
---

Security hardening: guard all `ExtraFilter` interpolation in the published Angular components. IDs bound via `@Input()` are now shape-validated with `RequireUUID`/`SafeUUID` before they reach a filter, free text goes through the existing NUL-stripping escapers, `SearchPeople`/`SearchOrganizations` take a search term instead of a raw SQL filter fragment, and externally-synced meeting URLs only render when they are http(s).
