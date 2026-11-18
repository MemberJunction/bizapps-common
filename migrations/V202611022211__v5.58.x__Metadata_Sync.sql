-- =============================================================================================
-- BizApps Common v5.58.x -- Metadata_Sync (one per release)
-- =============================================================================================
-- Generation: `mj sync push --dir metadata --ci` (MJ CLI 6.1.6) against a database built from
-- migrations ONLY: MJ core 6.1.6, then this app's migrations at `next` (b20cf97). Push result:
-- 0 created, 2 updated, 353 unchanged, 0 errors. Neither update ships:
--   * MJ_BizApps_Common: People -- field-level security, held back below.
--   * "Common: Party Lookup Organizations" -- a sync-block checksum refresh only; the push wrote no
--     SQL for it.
--
-- SHIPS (written by hand, because the push had nothing left to emit):
--   * metadata/entities/.display-names.json (#397): DisplayName 'Company Sender Identities' on
--     MJ_BizApps_Common: Company Sender Identities (64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13).
--     V202611021520__v5.58.x__Company_Sender_Identity's CodeGen section already inserts the entity
--     with that DisplayName, which is why the push found nothing to change. This statement makes
--     the release seed carry the record that metadata/ declares, as `rr: metadata shipped` and
--     `check:seed-cadence` require. It is a no-op on any database that ran V202611021520, and it
--     restores the declared value if anything there changed it. It updates by pinned ID only.
--
-- HELD BACK, as in 5.48 and every release since -- field-level security for People (#186): the
-- push's spUpdateEntity on MJ_BizApps_Common: People (turns on EnableFieldLevelSecurity) and the 108
-- Entity Field Permission rows MJ's reconcile then created from this build database's own roles.
-- Hosts upgrade by migration only, so shipping those rows would apply this database's snapshot,
-- not each host's; and with the flag on, a field with no row is denied to every user.
-- =============================================================================================
UPDATE [${mjSchema}].[Entity]
   SET [DisplayName] = N'Company Sender Identities'
 WHERE [ID] = '64C02581-1AE6-4E8D-A4F2-0D9BED1A9B13'
   AND ([DisplayName] IS NULL OR [DisplayName] <> N'Company Sender Identities');
