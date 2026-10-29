---
"@mj-biz-apps/common-ng": patch
---

`bizapps-party-field`: a search that runs past `SearchTimeoutMs` (default 20 s; zero or less waits indefinitely) now says "The search took too long" instead of leaving an empty list with no message. Its late answer is ignored and the next keystroke searches again. The new `SearchError` property says whether the last search failed or timed out; `SearchFailed` stays as a getter over it. (bc-aidp-next-golive#343)
