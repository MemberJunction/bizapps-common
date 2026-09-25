---
"@mj-biz-apps/common-ng": patch
---

The address editor's row lines now join only the parts that are present, so an address with just
Line2, or with a country and no city, region or postal code, no longer shows a leading `, `. A location-only address with no street lines shows
its city/region/postal/country line as the headline instead of an empty one.
