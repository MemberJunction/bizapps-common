---
"@mj-biz-apps/common-activity-sync": patch
---

Keep ActivitySync's host registries — transport factory, file sink, content cipher and live-mailbox
attestation — in MJ's global object store instead of module-scoped variables, so every copy of the
package loaded in one process shares them. A host that resolved two copies could previously register
into one and have the engine read the other. The `Register*` / `Host*` functions and
`AllowLiveMailboxFetch` keep their signatures.
