#!/bin/sh
# Wrapper for logical replica containers: fix PGDATA ownership before postgres starts.
# Run as root (user: root in compose); then exec original entrypoint which drops to postgres.
set -e
PGDATA="${PGDATA:-/var/lib/postgresql/data}"
chown -R postgres:postgres "$PGDATA" 2>/dev/null || true
exec /usr/local/bin/docker-entrypoint.sh "$@"
