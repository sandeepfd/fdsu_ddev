# PostgreSQL 14 ↔ 18 switch (DDEV host commands)

This guide describes how to use the host commands under `.ddev/commands/host/` to back up PostgreSQL 14, load data into the PostgreSQL 18 sidecar, validate, and point the app at PG14 or PG18 via local config files.

## Prerequisites

- DDEV is installed and the project starts successfully (`ddev start`).
- The **PostgreSQL 18** service is enabled (for example via `.ddev/docker-compose.postgres18.yaml`) so that PG18 listens on **host port `5433`** (mapped to `5432` in the `postgres18` container). The main DDEV database remains **PostgreSQL 14 on port `5432`** unless you change the project database image.
- You have created the **versioned local config files** described below (they are not generated automatically).

## Configuration files you must create manually

The command `ddev switch-pg-version` does not edit connection strings inline. It expects **pairs** of version-specific files under **`site/config/`** (paths are relative to the **project root**, parent of `.ddev`).

For each **base name** below, you need **two** files: one for PG14 and one for PG18. The command copies the chosen file onto the active `*-local.php` name the app already uses.

| Base name | Active file (used by the app) | PG14 source | PG18 source |
|-----------|-------------------------------|-------------|-------------|
| `db_write` | `site/config/db_write-local.php` | `site/config/db_write-local-pg14.php` | `site/config/db_write-local-pg18.php` |
| `db_read` | `site/config/db_read-local.php` | `site/config/db_read-local-pg14.php` | `site/config/db_read-local-pg18.php` |
| `db_read_report` | `site/config/db_read_report-local.php` | `site/config/db_read_report-local-pg14.php` | `site/config/db_read_report-local-pg18.php` |
| `common` | `site/config/common-local.php` | `site/config/common-local-pg14.php` | `site/config/common-local-pg18.php` |

**What to put in each file**

- **`db_write-local-pg14.php`**, **`db_read-local-pg14.php`**, **`db_read_report-local-pg14.php`**: same connection settings you use today for the **main** DDEV database (**host** `db` or `127.0.0.1` from the host as appropriate for your stack, **port `5432`**, user/password/database as in your current setup).
- **`db_write-local-pg18.php`**, **`db_read-local-pg18.php`**, **`db_read_report-local-pg18.php`**: point reads/writes to the **PG18 sidecar** from the app’s perspective. Typically from **inside the web container** you use host **`postgres18`** (Docker network alias) and port **`5432`**; from the **host** for CLI tools, use **`127.0.0.1`** and port **`5433`**. Adjust user, password, and database name to match `.ddev/docker-compose.postgres18.yaml` (defaults are often `db` / `db` / `db`).
- **`common-local-pg14.php`** / **`common-local-pg18.php`**: mirror whatever you keep in `common-local.php` today (cache, queues, etc.), with only the differences required for each database version if any.

**Minimum checklist:** all **eight** versioned files must exist (`*-local-pg14.php` and `*-local-pg18.php` for the four bases). If either file in a pair is missing, `switch-pg-version` prints a warning and skips that base safely.

**Tip:** Copy your current working `*-local.php` files to `*-local-pg14.php`, then duplicate and edit copies to `*-local-pg18.php` with PG18 host/port/credentials.

---

## Suggested sequence (first-time migration PG14 → PG18)

Follow this order once you are ready to load PG18 and switch the app.

### 1. Stay on PostgreSQL 14 in the app

Ensure `switch-pg-version` has not been run to PG18 yet, or run:

```bash
ddev switch-pg-version 14
```

Confirm the app still uses PG14 (`*-local.php` content should match PG14 sources after a successful switch).

### 2. Back up the PG14 database

With DDEV running and PG14 reachable on **`localhost:5432`**:

```bash
ddev backup-pg14
```

Optional: pass a path for the dump file:

```bash
ddev backup-pg14 ~/backups/my_project_pg14.dump
```

This produces a **custom-format** `pg_dump` (`.dump`), not plain SQL.

### 3. Ensure PostgreSQL 18 is running

Start the stack so the `postgres18` service is up and **`127.0.0.1:5433`** accepts connections (see your `docker-compose.postgres18.yaml`).

### 4. Restore the backup into PostgreSQL 18

Because the backup from step 2 is **custom format**, restore with **`pg_restore`**, not `ddev import-db18`.

Example from the **host** (adjust path and options to match your dump):

```bash
pg_restore -h 127.0.0.1 -p 5433 -U db -d db --no-owner --no-acl --verbose /path/to/your_backup.dump
```

You may need to drop/recreate the target database or use `--clean` depending on whether `db` is empty; follow your usual migration practice.

**`ddev import-db18`** is for **plain SQL** (optionally **`.gz`**). Use it when you have a `.sql` or `.sql.gz` file, for example:

```bash
ddev import-db18 ~/exports/dump.sql
ddev import-db18 ~/exports/dump.sql.gz
```

### 5. Validate PG14 vs PG18 (optional but recommended)

With **both** PG14 (`5432`) and PG18 (`5433`) running:

```bash
ddev validate-pg18-migration
```

Review extensions, schema/table counts, and any warnings (for example `pg_trgm` reindex reminders).

### 6. Point the application at PostgreSQL 18

```bash
ddev switch-pg-version 18
```

### 7. Clear cache and restart

As printed by the switch command:

```bash
ddev exec 'rm -rf site/runtime/cache/*'
ddev restart
```

Then verify the application against PG18.

---

## Switching back to PostgreSQL 14

When the eight versioned files exist and PG14 is still available:

```bash
ddev switch-pg-version 14
ddev exec 'rm -rf site/runtime/cache/*'
ddev restart
```

---

## Command reference

| Command | Purpose |
|---------|---------|
| `ddev backup-pg14 [file]` | Custom-format `pg_dump` of PG14 database `db` on `localhost:5432`. |
| `ddev import-db18 <file>` | Import **plain SQL** (or **gzip** SQL) into PG18 on `127.0.0.1:5433`. |
| `ddev validate-pg18-migration` | Compare PG14 and PG18 (connections, versions, extensions, rough counts). |
| `ddev switch-pg-version 14\|18` | Copy `*-local-pg14.php` or `*-local-pg18.php` into `*-local.php` for `db_write`, `db_read`, `db_read_report`, and `common`. |

---

## Troubleshooting

- **`switch-pg-version` warns about missing files:** create the missing `site/config/*-local-pg14.php` or `*-local-pg18.php` files (see table above).
- **Cannot connect to PG18:** confirm `postgres18` is running, port **`5433`** is not blocked, and PG18 credentials in your `*-local-pg18.php` files match the compose file.
- **Restore errors after `backup-pg14`:** use `pg_restore` for `.dump` files; `import-db18` does not read custom-format dumps.
