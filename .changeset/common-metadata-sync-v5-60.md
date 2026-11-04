---
'@mj-biz-apps/common-entities': minor
---

The 5.60 Metadata_Sync ships the re-keyed "Job Function and Seniority Derivation" AI Prompt, its prompt model and the job-function Record Process, all under the prompt's new ID (#408). The re-key migration that runs before it has already moved those rows, so the seed re-asserts their metadata values and changes nothing on a host that ran it. It has a Postgres counterpart. Field-level security for People stays held back, as in every release since 5.48.
