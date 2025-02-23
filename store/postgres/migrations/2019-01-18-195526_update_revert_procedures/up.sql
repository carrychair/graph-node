/**************************************************************
* UPDATE REVERT BLOCKS PROCESS
*
* History trigger functions have been updated to store the row
* level operation type (insert, update, or delete). Now it
* is stored in the entity_history table (moved from event_meta_data).
*
* Several of the revert functions have been updated to reflect the data
* restructuring: revert transaction, revert_transaction_group, and rerun_entity.
**************************************************************/

/**************************************************************
* REVERT TRANSACTION
*
* Get all row level events associated with a SQL transaction
* For each row level event call revert_entity_event()
* Parameters: event_id
**************************************************************/
CREATE OR REPLACE FUNCTION revert_transaction(event_id_to_revert INTEGER)
    RETURNS VOID AS
$$
DECLARE
    entity_history_row RECORD;
BEGIN
    -- Loop through each record change event
    FOR entity_history_row IN
        -- Get all entity changes driven by given event
        SELECT
            id,
            op_id
        FROM entity_history
        WHERE (
            subgraph <> 'subgraphs' AND
            event_id = event_id_to_revert)
        ORDER BY id DESC
    -- Iterate over entity changes and revert each
    LOOP
        PERFORM revert_entity_event(entity_history_row.id, entity_history_row.op_id);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

/**************************************************************
* REVERT TRANSACTION GROUP
*
* Get all row level events associated with a set of SQL transactions
* For each row level event call revert_entity_event()
* Parameters: array of event_id's
**************************************************************/
CREATE OR REPLACE FUNCTION revert_transaction_group(event_ids_to_revert INTEGER[])
    RETURNS VOID AS
$$
DECLARE
    entity_history_row RECORD;
BEGIN
    FOR entity_history_row IN
        SELECT
            id,
            op_id
        FROM entity_history
        WHERE (
          subgraph <> 'subgraphs' AND
          event_id = ANY(event_id_to_revert) )
        ORDER BY id DESC
    LOOP
        PERFORM revert_entity_event(row.id, row.op_id);
    END LOOP;
END;
$$ LANGUAGE plpgsql;


/**************************************************************
* RERUN ENTITY
*
* Rerun all events for a specific entity
* avoiding any revert or uncled events
* Parameters: entity pkey -> (entity_id, subgraph, entity)
              event_id of revert event
**************************************************************/
CREATE OR REPLACE FUNCTION rerun_entity(
    event_id_to_rerun INTEGER, subgraph_to_rerun VARCHAR, entity_to_rerun VARCHAR, entity_id_to_rerun VARCHAR)
    RETURNS VOID AS
$$
DECLARE
    entity_history_event RECORD;
BEGIN
     FOR entity_history_event IN
        -- Get all events that effect given entity and come after given event
        SELECT
            id,
            op_id
        FROM entity_history
        WHERE (
            entity = entity_to_rerun AND
            entity_id = entity_id_to_rerun AND
            subgraph = subgraph_to_rerun AND
            event_id > event_i_to_rerund AND
            reversion = FALSE )
        ORDER BY id ASC
    LOOP
        -- For each event rerun the operation
        PERFORM rerun_entity_history_event(entity_history_event.id, entity_history_event.op_id);
    END LOOP;
END;
$$ LANGUAGE plpgsql;
