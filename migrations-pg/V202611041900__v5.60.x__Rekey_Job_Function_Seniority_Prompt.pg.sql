-- =============================================================================
-- Migration: V202611041900__v5.60.x__Rekey_Job_Function_Seniority_Prompt.pg.sql
-- PostgreSQL counterpart of migrations/V202611041900__v5.60.x__Rekey_Job_Function_Seniority_Prompt.sql.
-- Hand-written: the T-SQL builds its statements from the catalog, which `mj migrate convert`
-- cannot translate. Same behavior, read from pg_catalog instead of sys.*.
--
-- Move common's AI Prompt "Job Function and Seniority Derivation" from
-- 7C46041F-0412-4C2E-9B9E-3ED61D32210C to 19736B1D-923B-4BB7-AAE8-9A98D9B25C1E, so MJ 6.2's
-- metadata sync creates and later deletes only its own copy of 7C46041F (bizapps-common#408,
-- MemberJunction/MJ#4939). On PostgreSQL the unique key on AIPromptModel does not collide (a NULL
-- ConfigurationID is distinct), so without this MJ's V202610022141 silently deletes common's prompt.
--
-- The PostgreSQL chain never seeded 7C46041F (there is no 5.47 Metadata_Sync twin), so on most
-- PostgreSQL hosts it does not exist and every statement below touches no rows. Where it exists,
-- `mj sync push` loaded common's earlier metadata, and it is common's. Every foreign key to AIPrompt
-- is NO ACTION, so the final DELETE fails, and the migration rolls back, if any reference was missed.
-- =============================================================================
DO $$
DECLARE
    v_old_id     UUID := '7C46041F-0412-4C2E-9B9E-3ED61D32210C';
    v_new_id     UUID := '19736B1D-923B-4BB7-AAE8-9A98D9B25C1E';
    v_process_id UUID := '7E030001-A101-4B01-8C01-000000000001';
    v_schema     TEXT := '${mjSchema}';
    v_prompt     REGCLASS;
    v_columns    TEXT;
    v_ref        RECORD;
BEGIN
    v_prompt := format('%I.%I', v_schema, 'AIPrompt')::REGCLASS;

    -- 1. Copy the prompt row to the new ID. Every stored column except ID and the __mj_ timestamps
    --    is copied, so the copy is exact on any MJ schema version.
    SELECT string_agg(quote_ident(a.attname), ', ' ORDER BY a.attnum)
      INTO v_columns
      FROM pg_attribute a
     WHERE a.attrelid = v_prompt
       AND a.attnum > 0
       AND NOT a.attisdropped
       AND a.attgenerated = ''
       AND a.attname <> 'ID'
       AND a.attname NOT LIKE '\_\_mj\_%';

    EXECUTE format('INSERT INTO %s ("ID", %s) SELECT $1, %s FROM %s WHERE "ID" = $2',
                   v_prompt, v_columns, v_columns, v_prompt)
      USING v_new_id, v_old_id;

    -- 2. Repoint every foreign-key column that references AIPrompt.
    FOR v_ref IN
        SELECT c.conrelid::REGCLASS AS ref_table, a.attname AS ref_column
          FROM pg_constraint c
          JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey)
         WHERE c.contype = 'f'
           AND c.confrelid = v_prompt
    LOOP
        EXECUTE format('UPDATE %s SET %I = $1 WHERE %I = $2', v_ref.ref_table, v_ref.ref_column, v_ref.ref_column)
          USING v_new_id, v_old_id;
    END LOOP;

    -- 3. The job-function pipeline also carries the prompt ID inside its Configuration JSON. Matched
    --    case-insensitively, because a PostgreSQL host may have written the GUID in lower case.
    EXECUTE format(
        'UPDATE %I.%I SET "Configuration" = regexp_replace("Configuration", $1, $2, ''gi'') WHERE "ID" = $3',
        v_schema, 'RecordProcess')
      USING '"PromptID":"7C46041F-0412-4C2E-9B9E-3ED61D32210C"',
            '"PromptID":"19736B1D-923B-4BB7-AAE8-9A98D9B25C1E"',
            v_process_id;

    -- 4. Remove the old row. A plain DELETE, not the prompt delete function: that cascades into the
    --    prompt's models and runs, which now belong to the new ID.
    EXECUTE format('DELETE FROM %s WHERE "ID" = $1', v_prompt) USING v_old_id;
END
$$;
