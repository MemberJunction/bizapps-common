-- =============================================================================
-- Layered base view for Relationships — PART 2 of 2 (the wrapper)
-- =============================================================================
--
-- Pairs with V202610141449, which flips Relationships to a layered base view and carries
-- the CodeGen output that CREATES vwRelationshipsGenerated. Run that first; timestamp
-- ordering guarantees it.
--
-- This wrapper owns only what CodeGen cannot produce: DisplayName, the entity's name
-- field. Everything else — base columns and every FK display column, including any added
-- later — comes from g.*, so the wrapper exposes a SUPERSET of the generated view.
--
-- DisplayName = "<From> → <To> (<Type>)", e.g. "Jane Smith → Acme (Employee)".
--   * From/To: the person's DisplayName or the organization's Name (CK_Relationship_
--     FromOwner / ToOwner guarantee exactly one is set on each side).
--   * Type: the RelationshipType Name already on the generated view. Not ForwardLabel:
--     a sentence ("Jane Smith is employee of Acme") depends on every label's grammar and
--     fixes English word order. The arrow and parentheses carry no language, so a host
--     localizes the label by renaming its RelationshipTypes. Names lead, so pickers sort
--     and search by party.
--   * The arrow is NCHAR(8594) so the view does not depend on how the file is decoded.
--   * Every part is NULLIF(TRIM(x), N''): CONCAT_WS skips a blank party, and a blank
--     type drops the whole " (...)" suffix (N' (' + NULL is NULL, which CONCAT skips).
--
-- CREATE OR ALTER (not DROP + CREATE) keeps the grants already on vwRelationships.
--
-- NO CODEGEN SECTION HERE. The EntityField row for DisplayName ships in PART 1's
-- CodeGen output.
-- =============================================================================

CREATE OR ALTER VIEW [${flyway:defaultSchema}].[vwRelationships]
AS
SELECT
    -- Everything CodeGen generates: base columns and every FK display column.
    g.*,

    CAST(
        CONCAT(
            CONCAT_WS(N' ' + NCHAR(8594) + N' ',
                NULLIF(TRIM(COALESCE(g.[FromPerson], g.[FromOrganization])), N''),
                NULLIF(TRIM(COALESCE(g.[ToPerson], g.[ToOrganization])), N'')),
            N' (' + NULLIF(TRIM(g.[RelationshipType]), N'') + N')')
        AS NVARCHAR(1000)) AS [DisplayName]

FROM
    [${flyway:defaultSchema}].[vwRelationshipsGenerated] AS g;
GO

GRANT SELECT ON [${flyway:defaultSchema}].[vwRelationships] TO [cdp_UI], [cdp_Developer], [cdp_Integration];
GO
