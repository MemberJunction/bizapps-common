---
"@mj-biz-apps/common-enrichment": minor
---

Person enrichment, Phase 4: the two live providers and their nightly jobs. `ApolloEnrichmentProvider`
(`Apollo`, employment + LinkedIn through `@memberjunction/actions-apollo`'s `ApolloPeopleClient`) and
`PDLEnrichmentProvider` (`PDL`, education + employment + LinkedIn through
`@memberjunction/actions-peopledatalabs`'s `PDLPersonClient`, with a typed, validated `Configuration`)
register with the engine; both are read-only vendors that translate rate limits, exhausted credits and
rejected keys into the engine's clean stops. Seed metadata adds the `Apollo` and `People Data Labs`
rows to Enrichment Providers with the rate rows Phase 0 confirmed (CreditPrice left for the admin) and
two Disabled nightly `Common.EnrichPeople` jobs (Apollo 07:00 UTC, PDL 08:30 UTC). The two vendor client
packages are peers of `common-enrichment`.
