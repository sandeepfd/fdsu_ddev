-- Replication role for POC: physical standby and (via standby) logical replica
-- See brainstorming/PG18_REPLICATION_POC.md

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'repl') THEN
        CREATE ROLE repl WITH REPLICATION LOGIN PASSWORD 'repl';
    END IF;
END
$$;
