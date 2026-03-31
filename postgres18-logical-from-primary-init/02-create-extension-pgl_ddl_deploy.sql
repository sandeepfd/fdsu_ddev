-- pgl_ddl_deploy and its dependency pg_background (for DDL replication from primary; see POC doc §11).
CREATE EXTENSION IF NOT EXISTS pg_background;
CREATE EXTENSION IF NOT EXISTS pgl_ddl_deploy;
