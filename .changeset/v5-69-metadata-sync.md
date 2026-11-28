---
"@mj-biz-apps/common-entities": minor
---

Installed databases now get organization search by website domain (V202611281800 Metadata_Sync). The Organizations.WebsiteDomain field becomes a user-search field with a starts-with match, pinned so CodeGen keeps it. The update skips a host that pinned the field's search settings itself.
