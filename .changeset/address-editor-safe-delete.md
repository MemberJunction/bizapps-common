---
"@mj-biz-apps/common-ng": patch
---

Removing an address in the address editor now deletes the Address row only when nothing else
references it, such as another party's link or an order. When it does delete the row, the link and
the Address are deleted in one transaction. If a delete is refused, the editor shows the reason
instead of reloading as though it had worked. If the editor cannot check the references, it deletes
only the link and keeps the Address row.
