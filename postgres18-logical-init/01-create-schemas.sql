-- Minimal schemas for logical replica so published tables can be created here
-- (Logical replication creates tables on initial sync if they don't exist; schemas must exist.)
CREATE SCHEMA IF NOT EXISTS app;
CREATE SCHEMA IF NOT EXISTS rrule;
