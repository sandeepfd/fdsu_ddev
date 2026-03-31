# PostGIS 18 + pglogical for POC (primary and logical nodes).
# Built by Docker Compose when DDEV starts (docker-compose.postgres18.yaml build:).
# No separate build step: same containerization toolchain as DDEV.
FROM postgis/postgis:18-3.6

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    git \
    libkrb5-dev \
    liblz4-dev \
    libpam0g-dev \
    libselinux1-dev \
    libxslt1-dev \
    libzstd-dev \
    postgresql-server-dev-18 \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Build and install pglogical extension + pglogical_output plugin (REL2_x_STABLE has compat18 for PostgreSQL 18).
# pglogical_create_subscriber fails to link (libpgcommon/libpgport not in postgis image); -k so we keep the .so and install it.
# MODULES = pglogical_output in Makefile produces pglogical_output.so — required on provider for replication slots.
ENV PATH="/usr/lib/postgresql/18/bin:${PATH}"
RUN git clone --depth 1 --branch REL2_x_STABLE https://github.com/2ndQuadrant/pglogical.git /tmp/pglogical \
    && cd /tmp/pglogical \
    && make clean \
    && make -k all || true \
    && test -f pglogical.so \
    && test -f pglogical_output.so \
    && cp pglogical.so pglogical_output.so "$(pg_config --pkglibdir)/" \
    && cp pglogical.control pglogical--*.sql "$(pg_config --sharedir)/extension/" \
    && cp pglogical_origin.control pglogical_origin--*.sql "$(pg_config --sharedir)/extension/" \
    && cd / \
    && rm -rf /tmp/pglogical

# pg_background: required by pgl_ddl_deploy for async execution.
RUN git clone --depth 1 https://github.com/vibhorkum/pg_background.git /tmp/pg_background \
    && cd /tmp/pg_background \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/pg_background

# pg_cron: cron-based job scheduler (PG18 supported in 1.6.6+).
RUN git clone --depth 1 --branch v1.6.7 https://github.com/citusdata/pg_cron.git /tmp/pg_cron \
    && cd /tmp/pg_cron \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/pg_cron

# pgl_ddl_deploy: transparent DDL replication for native logical replication (and pglogical).
# Build may fail on PG18 (extension may not yet support it); allow layer to succeed so image builds.
RUN git clone --depth 1 https://github.com/enova/pgl_ddl_deploy.git /tmp/pgl_ddl_deploy \
    && cd /tmp/pgl_ddl_deploy \
    && (make -k all && make install) || true \
    && cd / \
    && rm -rf /tmp/pgl_ddl_deploy

USER postgres
