---
'@mj-biz-apps/common-actions': patch
---

Declare `@mj-biz-apps/common-actions` as a server package in `mj-app.json`, not a shared one.

It imports `BaseAction` and `ActionEngineServer` from `@memberjunction/actions` and peers on `@memberjunction/core-entities-server` and `@memberjunction/aiengine`, so it cannot load in a browser. Listed under `shared`, `mj app install` also wrote it into the host's `dynamicPackages.client`, which the client bootstrap imports. It is now a `server` entry with the `actions` role. Server registration is unchanged: `@mj-biz-apps/common-server` already imports it.

On an existing host, `mj app upgrade` removes the stale `dynamicPackages.client` entry: since MJ 6.1.0 (this app's `mjVersionRange` floor) the upgrade prunes each array against what the manifest now declares for it, and the client keep-set is built from `client` and `shared` only.
