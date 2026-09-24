---
"@mj-biz-apps/common-ng": patch
---

The address editor's row headline now joins only the street lines that are present, so an address
with just Line2 no longer shows a leading `, `. A location-only address with no street lines shows
its city/region/postal/country line as the headline instead of an empty one.
