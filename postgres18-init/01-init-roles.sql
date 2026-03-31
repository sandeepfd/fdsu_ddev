-- Initialize roles and database structure to match PostgreSQL 14
-- This script runs automatically on first database initialization

-- Create 'fdsu' role if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'fdsu') THEN
        CREATE ROLE fdsu WITH LOGIN;
    ELSE
        -- If role exists, ensure it can login
        ALTER ROLE fdsu WITH LOGIN;
    END IF;
END
$$;

-- Ensure 'db' database exists (should already exist from POSTGRES_DB, but ensure ownership)
ALTER DATABASE db OWNER TO db;

-- Grant necessary privileges
GRANT ALL PRIVILEGES ON DATABASE db TO db;
GRANT ALL PRIVILEGES ON DATABASE db TO fdsu;

-- Create en_natural collation for natural sorting (numeric-aware sorting)
-- This collation is used extensively in the codebase for sorting names, codes, etc.
-- It uses ICU provider with 'en-US-u-kn-true' locale (kn=true enables numeric sorting)
DO $$
BEGIN
    -- Check if en_natural collation exists in app schema
    IF NOT EXISTS (
        SELECT 1 FROM pg_collation c
        JOIN pg_namespace n ON c.collnamespace = n.oid
        WHERE c.collname = 'en_natural'
        AND n.nspname = 'app'
        AND c.collprovider = 'i'  -- ICU provider
    ) THEN
        -- Create in app schema (matching PostgreSQL 14 schema)
        CREATE COLLATION app.en_natural (
            LOCALE = 'en-US-u-kn-true',
            PROVIDER = icu
        );
    END IF;
END
$$;

