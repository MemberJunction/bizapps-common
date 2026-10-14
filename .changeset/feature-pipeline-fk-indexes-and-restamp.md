---
'@mj-biz-apps/common-entities': minor
---

Adds the foreign-key indexes that were missing on `ActivityFile`, `ActivityLink`, `Person` and `PersonJobFunction`, and re-marks the job-function rows the job-title Feature Pipeline wrote earlier as `Derived`, so re-runs reconcile them instead of treating them as entered by a person. The shipped migration `V202609282100` is also repaired in place so it installs on databases that still hold MJ core's referenced copy of the job-title prompt (`7C46041F`): it adopts that row with this package's values instead of failing on a duplicate key, replaces MJ core's model bindings with this package's own (a credential on MJ core's equivalent binding moves to it; MJ core's Vertex AI binding stays only while a credential uses it), and removes MJ core's former template when nothing references it.
