#!/bin/bash
# Allow replication connections for POC (Primary -> Physical -> Logical).
# Runs on first init of primary. For existing primary, run setup-pg18-replication-poc
# which appends this line and reloads. Using trust for POC; use scram-sha-256 in production.
set -e
printf 'host\treplication\trepl\t0.0.0.0/0\ttrust\n' >> /var/lib/postgresql/data/pg_hba.conf
