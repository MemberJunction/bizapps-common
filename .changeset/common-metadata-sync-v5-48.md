---
'@mj-biz-apps/common-entities': minor
---

The 5.48 Metadata_Sync takes People `PrimaryEmail` and Organization `Website` out of user search (#199), so the new lookup indexes can answer Bill To Person and Bill To Organization lookups in milliseconds. Two matches go away: a person's primary contact-method email that differs from `Person.Email`, and Organization website search. Field-level security for People (#186) is declared in metadata but not shipped yet. It needs an MJ 6.1.4 floor and host-side permission rows, so People access on hosts is unchanged.
