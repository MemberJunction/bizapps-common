---
'@mj-biz-apps/common-entities': patch
---

Pins the remaining 15 CHECK-constraint validators as `GeneratedCode` rows in `metadata/generated-codes/`, copied unchanged from the generated entity classes, so regenerating from migrations reuses every validator instead of asking the AI again. No generated code changes. The next release seed carries the rows to hosts.
