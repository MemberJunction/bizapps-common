---
'@mj-biz-apps/common-entities': minor
'@mj-biz-apps/common-ng': minor
---

Add Job Function & Seniority people model and feature pipeline integration (FP-6).

- Database schema and migration:
  - `JobFunction`: Type table (`MJ_BizApps_Common: Job Functions`) with seed data in `metadata/job-functions/`.
  - `SeniorityLevel`: Type table (`MJ_BizApps_Common: Seniority Levels`) with seed data in `metadata/seniority-levels/` carrying rank order (IC -> Manager -> Director -> VP -> C-Level).
  - `PersonJobFunction`: 1:M bridge (`MJ_BizApps_Common: Person Job Functions`) with `Source` ('Manual' | 'Derived') and `Confidence`.
  - `Person.SeniorityLevelID` foreign key to `SeniorityLevel`.
  - `Relationship.JobFunctionID` and `Relationship.SeniorityLevelID` foreign keys for per-company role classification.
  - `vwPeople`: Virtual view columns `PrimaryJobFunctionID` and `PrimaryJobFunction` derived from the lowest Sequence `PersonJobFunction` row.
  - `metadata/record-processes/`: Dogfood RecordProcess feature pipeline configuration for Job Function and Seniority classification.
- Progressive disclosure UX:
  - `PersonIdentityComponent`: Compact chips for `PrimaryJobFunction` and `SeniorityLevel` in the identity header badges, with interactive disclosure for multiple job functions, and `SeniorityLevelID` in EditMode.
  - `RelationshipListComponent`: Displays `JobFunction` and `SeniorityLevel` badges on timeline items when set; provides progressive disclosure section in Add and Edit forms so role classification is invisible until expanded or set.
