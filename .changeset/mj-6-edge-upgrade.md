---
"@mj-biz-apps/common-entities": patch
---

Upgrade to MemberJunction 6.1.0-edge.0. All `@memberjunction/*` dependencies and peer ranges now require the 6.x line, and the Open App manifest's `mjVersionRange` is `>=6.1.0 <7.0.0` — consumers must be on a MemberJunction 6.x environment. No source changes were required: the MJ 6.x breaking-change surface (integration connectors, ActionExecutionLog.Params, AIEngine similarity APIs, system-catalog SQL, HS256 JWTs, negation-form RLS filters) does not touch this codebase.
