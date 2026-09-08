---
"@mj-biz-apps/common-entities": minor
---

Address is the geo write source (`SupportsGeoCoding=1`, Latitude/Longitude tagged GeoLatitude/GeoLongitude). Organizations layered view bubbles PrimaryAddressLatitude/Longitude (virtual display fields) like People. GeoCodeSyncService does not run on Person/Org (no writable Geo*).
