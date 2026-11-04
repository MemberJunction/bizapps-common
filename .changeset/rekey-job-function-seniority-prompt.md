---
'@mj-biz-apps/common-entities': minor
---

Re-key the "Job Function and Seniority Derivation" AI Prompt from `7C46041F-0412-4C2E-9B9E-3ED61D32210C` to `19736B1D-923B-4BB7-AAE8-9A98D9B25C1E`, so a host with common installed on MJ 6.1.x can migrate MJ to 6.2.0 (#408, MemberJunction/MJ#4939).

- Migration `V202611041900` (SQL Server and PostgreSQL): when `7C46041F` is common's prompt (template `B8221E1A…` or prompt model `FE550867…`), copy it to the new ID, repoint every foreign key and the job-function Record Process `Configuration`, and delete the old row. On any other host it does nothing.
- Metadata: the prompt and its Record Process now use the fixed new ID.
- Host order: install this release while still on MJ 6.1.x, then migrate MJ to 6.2.0 with the 6.2.0 CLI.
