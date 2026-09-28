-- =============================================================================
-- Remove the RecordData params from the durable People·AfterCreate and
-- Organizations·AfterUpdate Common.LogActivity bindings (#197).
-- =============================================================================
--
-- WHAT THIS REMOVES. Two `EntityActionParam` rows that bind `RecordData` on
-- DURABLE bindings. MJ's param redaction always strips whole-record values from
-- a durable task's payload, so the action never saw them; the bindings now pass
-- `RecordID` (Entity Field `ID`) instead. The metadata marks both rows
-- `deleteRecord`.
--
-- WHY A MIGRATION AND NOT THE METADATA MARKER ALONE. Both rows are NESTED under
-- their Entity Action in metadata/entity-actions/. `mj sync push` does not apply
-- a nested `deleteRecord`: its deletion pre-scan checks only each file's
-- top-level records, reports "No deletion operations found", and skips the
-- delete - so the Metadata_Sync migration a release generates carries no
-- DELETE either, and every host would keep both rows. Measured on a clone:
-- push summary "Deleted 0", both rows still present afterwards. This file is
-- what actually removes them; the marker stays so a later push never recreates
-- them. packages/Server/src/__tests__/metadata-nested-deletes.test.ts fails
-- when a nested marker has no migration like this one.
--
-- WHICH ROWS, DEFINED ONCE. @Target names each row by the identity it shipped
-- with: its id, the Entity Action it hangs off, and the RecordData param. The
-- DELETE and the closing check both read @Target, so they cannot disagree.
-- ValueType is deliberately NOT part of the identity: whatever a host changed it
-- to, a RecordData binding on these durable actions is stripped from the
-- payload, so it goes too. A row whose id was re-used on a different Entity
-- Action or for a different param does not match and is left alone. The ids
-- are fixed - they ship in this repo's metadata, not minted per host by CodeGen.
-- Idempotent: re-running finds nothing.
-- =============================================================================

DECLARE @Target TABLE (ID UNIQUEIDENTIFIER, EntityActionID UNIQUEIDENTIFIER, ActionParamID UNIQUEIDENTIFIER);
INSERT INTO @Target (ID, EntityActionID, ActionParamID) VALUES
    -- People·AfterCreate Common.LogActivity, RecordData
    ('991FB3F3-8101-49BE-B27A-16AF3F77BF10', 'DC862BD2-6529-42F6-BBA3-D9602FA76450', 'D067FFE0-70B2-4A28-9C31-066BB536E637'),
    -- Organizations·AfterUpdate Common.LogActivity, RecordData
    ('7376D962-3CC7-4F57-B3D5-17023621A405', 'D7497F2F-DFC6-4B46-B3A5-D677A99A71DB', 'D067FFE0-70B2-4A28-9C31-066BB536E637');

DELETE eap
FROM [${mjSchema}].[EntityActionParam] eap
JOIN @Target t ON t.ID = eap.ID AND t.EntityActionID = eap.EntityActionID AND t.ActionParamID = eap.ActionParamID;

PRINT CONCAT('Removed ', @@ROWCOUNT, ' durable RecordData binding param(s).');

-- Prove it with the same identity: none of the target rows may remain.
IF EXISTS (
    SELECT 1
    FROM [${mjSchema}].[EntityActionParam] eap
    JOIN @Target t ON t.ID = eap.ID AND t.EntityActionID = eap.EntityActionID AND t.ActionParamID = eap.ActionParamID
)
    THROW 50197, 'A durable RecordData binding param is still present after its removal.', 1;
GO
