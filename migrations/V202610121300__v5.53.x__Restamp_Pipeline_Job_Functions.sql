-- =============================================================================
-- Migration: V202610121300__v5.53.x__Restamp_Pipeline_Job_Functions.sql
-- Description: One-time data fix. Restamp the PersonJobFunction rows that the
--              "Job Function and Seniority Derivation" Feature Pipeline wrote
--              before its output mapping stamped its own rows Source = 'Derived'.
--
-- Until this release the pipeline's child mapping set no Source, so every row it
-- wrote took the column default 'Manual'. The pipeline now reconciles its rows
-- and treats any row whose Source is not 'Derived' as human-owned: it never
-- updates or deletes one. Left alone, every row the old pipeline wrote would be
-- frozen as if a person had entered it: a re-run would neither refresh its
-- Confidence or Sequence nor delete it when the model no longer proposes it.
--
-- The pipeline always set Confidence; the Person Job Functions form does not,
-- so rows people entered have none and keep 'Manual'. A row a person entered
-- and then gave a Confidence by hand is indistinguishable from a pipeline row
-- and is restamped too.
--
-- Data only: no DDL, so no CodeGen output follows and the file carries no banner.
-- Idempotent: a second run matches no row.
-- =============================================================================

-- Restamp job-function rows the job-title Feature Pipeline wrote before it stamped its own rows (F-FP-3).
-- The pipeline always set Confidence; rows entered by people have none.
UPDATE [${flyway:defaultSchema}].[PersonJobFunction]
   SET [Source] = N'Derived'
 WHERE [Source] = N'Manual' AND [Confidence] IS NOT NULL;
