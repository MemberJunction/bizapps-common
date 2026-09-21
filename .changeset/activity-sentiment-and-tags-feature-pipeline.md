---
'@mj-biz-apps/common-entities': minor
'@mj-biz-apps/common-ng': minor
---

Add Activity Tagging & Sentiment feature pipeline (FP-7 / P2-1).

- Database schema and migration:
  - `Activity.SentimentScore`: Bounded decimal column `DECIMAL(4,3)` (-1.000 to +1.000) for activity sentiment.
  - Recreates `vwActivities` to include `SentimentScore`.
  - Updates `spCreateActivity` and `spUpdateActivity` with `@SentimentScore` parameter.
  - Appends `EntityField` for `SentimentScore` on `MJ_BizApps_Common: Activities`.
- Metadata:
  - `Common: Activity With Contact History` query retrieving target activity and linked contact's historical baseline.
  - `Activity Tagging and Sentiment Derivation` prompt with contact baseline analysis.
  - `Sentiment` taxonomy root tag with child tags (`Positive`, `Neutral`, `Negative`, `EscalationRisk`, `Urgent`).
  - `Activity Tagging and Sentiment` Feature Pipeline Record Process (`WorkType: 'Infer'`, `Cacheable: false`, `Watermark: 'Checksum'`).
